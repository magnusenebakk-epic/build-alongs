using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Itemization }


crafter_inventory_component<public> := class(inventory_component):

    GetItemInSlot<public>(SlotIndex:int)<transacts><decides>:entity =
        Slot := for (S : Entity.FindDescendantComponents(craft_slot_component), S.SlotIndex = SlotIndex) { S }[0]
        Slot.GetItems()[0]

    GetSlotItems<public>()<transacts>:[int]entity =
        var Result:[int]entity = map{}
        for (S : Entity.FindDescendantComponents(craft_slot_component), Item := S.GetItems()[0]):
            if (set Result[S.SlotIndex] = Item) {}
        Result
