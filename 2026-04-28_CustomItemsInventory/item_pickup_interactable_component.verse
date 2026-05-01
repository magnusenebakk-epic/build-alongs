
using { /Verse.org/Simulation }
using { /Verse.org/SceneGraph }
using { /UnrealEngine.com/Itemization }


# Item Pickup interactable.
item_pickup_interactable_component<public> := class<final_super>(basic_interactable_component):

    @editable
    var Provider<public>:pickup_target_provider = direct_pickup_target_provider{}

    OnAddedToScene<override>():void =
        (super:)OnAddedToScene()
        Enable()

    OnRemovingFromScene<override>():void =
        (super:)OnRemovingFromScene()
        Disable()

    var SucceededSubscription<private>:?cancelable = false

    Enable<override>():void =
        (super:)Enable()
        if (not SucceededSubscription?):
            set SucceededSubscription = option{SucceededEvent.Subscribe(OnInteractionSucceeded)}

    Disable<override>():void =
        (super:)Disable()
        if (SucceededSubscription?.Cancel()):
            set SucceededSubscription = false

    OnInteractionSucceeded<protected>(Agent:agent):void =
        if (PickupInventory := Agent.GetFirstDescendantComponent[inventory_component]):
            NewItem := Provider.ProvideTarget(Self)
            AddResult := PickupInventory.AddItemDistribute(NewItem)
            if (Success := AddResult.GetSuccess[]):
                Provider.AfterPickup(Self)
            else if (Errors := AddResult.GetError[]):
                for (E : Errors):
                    Print(ToDiagnostic(E))
