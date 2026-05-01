using { /Verse.org/Assets }
using { /Verse.org/Concurrency }
using { /Verse.org/Input }
using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }
using { /UnrealEngine.com/Itemization }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/SpatialMath }


# Sits next to an item_component.
placable_component<public> := class<final_super>(component):

    @editable
    var Method<public>:placement_method

    @editable
    var Restrictions<public>:[]placement_restriction = array{}

    @editable
    var Highlight<public>:placement_highlight

    @editable
    var ConfirmAction<public>:?input_action(logic) = false

    @editable
    var Provider<public>:placement_target_provider

    @editable
    var Enabled<public>:logic = true

    var<private> LatestValidProposal<private>:?placement_proposal = false
    EnabledChangedEvent<private>:Concurrency.subscribable_event(logic) = Concurrency.subscribable_event(logic){}

    Enable<public>():void =
        if (not Enabled?):
            set Enabled = true
            EnabledChangedEvent.Signal(true)

    Disable<public>():void =
        if (Enabled?):
            set Enabled = false
            EnabledChangedEvent.Signal(false)

    OnSimulate<override>()<suspends>:void =
        if (ItemComp := Entity.GetComponent[item_component]):
            loop:
                if:
                    Enabled?
                    ItemComp.IsEquipped[]
                    Owner := FindOwningPlayer[ItemComp]
                then:
                    PlacementLoop(Owner, ItemComp)
                else:
                    race:
                        ItemComp.ChangeEquippedEvent.Await()
                        EnabledChangedEvent.Await()


    PlacementLoop<private>(Owner:player, ItemComp:item_component)<suspends>:void =
        defer:
            Highlight.HidePreview()
        set LatestValidProposal = false
        Query := placement_query{ Player := Owner, PlacableEntity := Entity }
        race:
            TickArm(Query)
            ConfirmArm(Owner, ItemComp)
            WaitForUnequip(ItemComp)
            WaitForDisable()

    WaitForDisable<private>()<suspends>:void =
        loop:
            EnabledChangedEvent.Await()
            if (not Enabled?):
                break

    TickArm<private>(Query:placement_query)<suspends>:void =
        loop:
            if (Proposal := Method.ComputeProposal[Query]):
                Valid := logic{CheckAllRestrictions[Query, Proposal]}
                set LatestValidProposal = if (Valid?) then option{Proposal} else false
                Highlight.ShowPreview(Query, Proposal, Valid)
            else:
                set LatestValidProposal = false
                Highlight.HidePreview()
            Sleep(0.0)

    ConfirmArm<private>(Owner:player, ItemComp:item_component)<suspends>:void =
        if:
            CA := ConfirmAction?
            Input := GetPlayerInput[Owner]
        then:
            ConfirmEvents := Input.GetInputEvents(CA)
            ConfirmEvents.TriggerActivationEvent.Subscribe(NullCallback) # NOTE: Workaround for input events not working with .Await
            loop:
                ConfirmEvents.TriggerActivationEvent.Await()
                if:
                    Proposal := LatestValidProposal?
                    ItemComp.Unequip().GetSuccess[]
                    Inv := ItemComp.GetParentInventory[]
                    SimEntity := Owner.GetFortCharacter[].GetEntity[].GetSimulationEntity[]
                    Inv.RemoveItem(Entity).GetSuccess[]
                then:
                    NewEntity := Provider.ProvideTarget(Self)
                    SimEntity.AddEntities(array{NewEntity})
                    NewEntity.SetGlobalTransform(Proposal.Transform)
                    break
        else:
            Sleep(Inf)

    WaitForUnequip<private>(ItemComp:item_component)<suspends>:void =
        loop:
            Result := ItemComp.ChangeEquippedEvent.Await()
            if (not Result.IsItemEquipped?):
                break

    # castable bug with agent: look ancestors instead.
    FindOwningPlayer<private>(ItemComp:item_component)<transacts><decides>:player =
        Inv := ItemComp.GetParentInventory[]
        if (P := player[Inv.Entity]). P # first check if inventory parent is player
        else: # find player in ancestor hierarchy
            Players := for (Ancestor : Inv.Entity.FindAncestorEntities(entity), P := player[Ancestor]) { P }
            Players[0]

    CheckAllRestrictions<private>(Query:placement_query, Proposal:placement_proposal)<transacts><decides>:void =
        for (R:Restrictions):
            R.CanPlaceAt[Query, Proposal]
