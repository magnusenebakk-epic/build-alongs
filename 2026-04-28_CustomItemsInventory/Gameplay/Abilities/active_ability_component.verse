using { /Verse.org/Assets }
using { /Verse.org/Concurrency }
using { /Verse.org/Input }
using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Itemization }


# Each entry = one Trigger + Action.
active_ability_entry<public> := class:

    @editable
    var Trigger<public>:?input_action(logic) = false

    @editable
    var Action<public>:ability_action

    @editable
    var OptCooldown<public>:?float = false

    @editable
    var OptCost<public>:?ability_cost = false

    var<private> OnCooldown<private>:logic = false

    # Prevent on cooldown, consume cost, run action.
    TryFire<public>(C:active_ability_component, Activator:agent):result(ability_fire_success, ability_fire_error) =
        if (OnCooldown?) { return MakeError(ability_on_cooldown_error{}) }
        CostOk := if (Cost := OptCost?) then Cost.TryConsume(Activator) else true
        if (not CostOk?) { return MakeError(ability_cost_failed_error{}) }
        Action.Execute(C, Activator)
        if (Cooldown := OptCooldown?):
            set OnCooldown = true
            spawn { CooldownTimer(Cooldown) }
        MakeSuccess(ability_fire_success{})

    CooldownTimer<private>(Duration:float)<suspends>:void =
        Sleep(Duration)
        set OnCooldown = false


active_ability_component<public> := class<final_super>(component):

    @editable
    (active_ability_component:)Abilities<public>:[]active_ability_entry = array{}

    var<private> ComponentCancel<private>:event() = event(){}

    OnSimulate<override>()<suspends>:void =
        if (ItemComp := Entity.GetComponent[item_component]):
            loop:
                Result := ItemComp.ChangeEquippedEvent.Await()
                if:
                    Result.IsItemEquipped?
                    Inv := ItemComp.GetParentInventory[]
                    Owner := Inv.GetOwningPlayer[]
                then:
                    EquippedSession(Owner, ItemComp)

    OnRemovingFromScene<override>():void =
        (super:)OnRemovingFromScene()
        ComponentCancel.Signal()

    EquippedSession<private>(Owner:player, ItemComp:item_component)<suspends>:void =
        SessionCancel := event(){}
        for (Entry : (active_ability_component:)Abilities):
            spawn { ListenForActivation(Entry, Owner, SessionCancel) }
        race:
            WaitForUnequip(ItemComp)
            ComponentCancel.Await()
        SessionCancel.Signal()

    ListenForActivation<private>(Entry:active_ability_entry, Owner:player, SessionCancel:event())<suspends>:void =
        race:
            SessionCancel.Await()
            ComponentCancel.Await()
            FireLoop(Entry, Owner)

    FireLoop<private>(Entry:active_ability_entry, Owner:player)<suspends>:void =
        if:
            T := Entry.Trigger?
            Input := GetPlayerInput[Owner]
        then:
            Events := Input.GetInputEvents(T)
            Events.TriggerActivationEvent.Subscribe(NullCallback)
            loop:
                Sleep(-1.0)
                Events.TriggerActivationEvent.Await()
                Result := Entry.TryFire(Self, Owner)

    WaitForUnequip<private>(ItemComp:item_component)<suspends>:void =
        loop:
            Result := ItemComp.ChangeEquippedEvent.Await()
            if (not Result.IsItemEquipped?):
                break
