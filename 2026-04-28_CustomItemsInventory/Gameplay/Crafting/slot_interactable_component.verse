using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Itemization }


slot_interactable_component<public> := class<final_super>(basic_interactable_component):

    var<private> SucceededSubscription<private>:?cancelable = false

    OnAddedToScene<override>():void =
        (super:)OnAddedToScene()
        Enable()

    OnRemovingFromScene<override>():void =
        (super:)OnRemovingFromScene()
        Disable()

    Enable<override>():void =
        (super:)Enable()
        if (not SucceededSubscription?):
            set SucceededSubscription = option{SucceededEvent.Subscribe(OnInteractionSucceeded)}

    Disable<override>():void =
        (super:)Disable()
        if (SucceededSubscription?.Cancel()):
            set SucceededSubscription = false

    OnInteractionSucceeded<protected>(Agent:agent):void =
        if (Slot := Entity.GetComponent[craft_slot_component]):
            if (Slot.HasItem[]):
                if (Slot.Withdraw[Agent]) {}
            else:
                if (Slot.Deposit[Agent]) {}
