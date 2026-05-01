using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Itemization }


# Viewmodel binding for inventory_component.
inventory_display<public> := interface:
    OnAttached<public>(Inv:inventory_component):void
    OnItemAdded<public>(Inv:inventory_component, Result:add_item_result):void
    OnItemRemoved<public>(Inv:inventory_component, Result:remove_item_result):void
    OnItemEquipped<public>(Inv:inventory_component, Result:equip_item_result):void
    OnItemUnequipped<public>(Inv:inventory_component, Result:unequip_item_result):void
    OnDetached<public>(Inv:inventory_component):void


inventory_display_base<public> := class<abstract>(inventory_display):
    OnAttached<override>(Inv:inventory_component):void = {}
    OnItemAdded<override>(Inv:inventory_component, Result:add_item_result):void = {}
    OnItemRemoved<override>(Inv:inventory_component, Result:remove_item_result):void = {}
    OnItemEquipped<override>(Inv:inventory_component, Result:equip_item_result):void = {}
    OnItemUnequipped<override>(Inv:inventory_component, Result:unequip_item_result):void = {}
    OnDetached<override>(Inv:inventory_component):void = {}


no_op_inventory_display<public> := class<concrete>(inventory_display_base){}


# Subscribes to a sibling inventory_component and dispatches its events to Display.
inventory_display_component<public> := class<final_super>(component):

    @editable
    var Display<public>:inventory_display = no_op_inventory_display{}

    var<private> AddSub<private>:?cancelable = false
    var<private> RemoveSub<private>:?cancelable = false
    var<private> EquipSub<private>:?cancelable = false
    var<private> UnequipSub<private>:?cancelable = false

    OnAddedToScene<override>():void =
        (super:)OnAddedToScene()
        if (Inv := Entity.GetComponent[inventory_component]):
            Display.OnAttached(Inv)
            set AddSub = option{Inv.AddItemEvent.Subscribe(OnAdd)}
            set RemoveSub = option{Inv.RemoveItemEvent.Subscribe(OnRemove)}
            set EquipSub = option{Inv.EquipItemEvent.Subscribe(OnEquip)}
            set UnequipSub = option{Inv.UnequipItemEvent.Subscribe(OnUnequip)}

    OnRemovingFromScene<override>():void =
        (super:)OnRemovingFromScene()
        if (AddSub?.Cancel()) { set AddSub = false }
        if (RemoveSub?.Cancel()) { set RemoveSub = false }
        if (EquipSub?.Cancel()) { set EquipSub = false }
        if (UnequipSub?.Cancel()) { set UnequipSub = false }
        if (Inv := Entity.GetComponent[inventory_component]):
            Display.OnDetached(Inv)

    OnAdd<private>(Result:add_item_result):void =
        if (Inv := Entity.GetComponent[inventory_component]):
            Display.OnItemAdded(Inv, Result)

    OnRemove<private>(Result:remove_item_result):void =
        if (Inv := Entity.GetComponent[inventory_component]):
            Display.OnItemRemoved(Inv, Result)

    OnEquip<private>(Result:equip_item_result):void =
        if (Inv := Entity.GetComponent[inventory_component]):
            Display.OnItemEquipped(Inv, Result)

    OnUnequip<private>(Result:unequip_item_result):void =
        if (Inv := Entity.GetComponent[inventory_component]):
            Display.OnItemUnequipped(Inv, Result)
