using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Itemization }


# Translates Add/Remove into "current item changed". Assumes capacity 1.
single_item_display<public> := class<abstract>(inventory_display_base):
    OnItemChanged<public>(Inv:inventory_component, Item:?entity):void

    OnItemAdded<override>(Inv:inventory_component, Result:add_item_result):void =
        if (Item := Result.AddedItems[0]):
            OnItemChanged(Inv, option{Item})

    OnItemRemoved<override>(Inv:inventory_component, Result:remove_item_result):void =
        OnItemChanged(Inv, false)

    OnDetached<override>(Inv:inventory_component):void =
        OnItemChanged(Inv, false)


# Snaps the current item to the inventory entity's transform
snap_item_inventory_display<public> := class<concrete>(single_item_display):
    OnItemChanged<override>(Inv:inventory_component, Item:?entity):void =
        if (I := Item?):
            I.SetGlobalTransform(Inv.Entity.GetGlobalTransform())


# Spawns Prefab while occupied.
spawn_prefab_inventory_display<public> := class<concrete>(single_item_display):

    @editable
    Prefab<public>:?concrete_subtype(entity) = false

    var<private> ActiveVisual<private>:?entity = false

    OnItemChanged<override>(Inv:inventory_component, Item:?entity):void =
        DespawnVisual()
        if:
            Item?
            P := Prefab?
            Sim := Inv.Entity.GetSimulationEntity[]
        then:
            New := P{}
            Sim.AddEntities(array{New})
            New.SetGlobalTransform(Inv.Entity.GetGlobalTransform())
            set ActiveVisual = option{New}

    DespawnVisual<private>():void =
        if (V := ActiveVisual?):
            V.RemoveFromParent()
            set ActiveVisual = false
