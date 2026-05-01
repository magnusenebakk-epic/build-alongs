using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Itemization }
using { /Verse.org/SpatialMath }


# finds the first matching recipe and runs Craft.
craft_button_interactable_component<public> := class<final_super>(basic_interactable_component):

    OnAddedToScene<override>():void =
        (super:)OnAddedToScene()
        Enable()

    OnRemovingFromScene<override>():void =
        (super:)OnRemovingFromScene()
        Disable()

    var<private> SucceededSubscription<private>:?cancelable = false

    Enable<override>():void =
        (super:)Enable()
        if (not SucceededSubscription?):
            set SucceededSubscription = option{SucceededEvent.Subscribe(OnInteractionSucceeded)}

    Disable<override>():void =
        (super:)Disable()
        if (SucceededSubscription?.Cancel()):
            set SucceededSubscription = false

    OnInteractionSucceeded<protected>(Agent:agent):void =
        if:
            CraftingComponent := Entity.FindAncestorComponents(crafting_component).First[]
            BenchInv := CraftingComponent.Entity.GetComponent[inventory_component]
            AgentInv := Agent.GetInventoryRoot[]
            Match := (for (R : CraftingComponent.Recipes, CraftingComponent.CanCraft[R, BenchInv]) { R })[0]
        then:
            Outcome := CraftingComponent.Craft(Match, BenchInv, AgentInv)
            if (Success := Outcome.GetSuccess[]):
                Print("Crafted {Success.NewItems.Length} item(s)")
            else if (CraftError := Outcome.GetError[]):
                if      (no_capacity_craft_error[CraftError])             { Print("Inventory full") }
                else if (no_outputs_craft_error[CraftError])              { Print("Recipe has no outputs") }
                else if (E := inputs_unavailable_craft_error[CraftError]) { Print("Missing {E.MissingItemTypes.Length} ingredient type(s)") }
                else if (consume_failed_craft_error[CraftError])          { Print("Failed to consume inputs") }
                else                                                      { Print("Craft failed") }
        else:
            Print("No matching recipe")
