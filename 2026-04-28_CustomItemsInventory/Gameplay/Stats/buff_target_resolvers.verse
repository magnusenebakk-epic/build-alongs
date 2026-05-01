using { /Verse.org/Concurrency }
using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Itemization }


# Strategy for "where should the buff entity live, and when?".
buff_target_resolver<public> := class<abstract>:
    GetTarget<public>(BuffComponent:passive_buff_component)<decides><transacts>:entity
    AwaitNextChange<public>(BuffComponent:passive_buff_component)<suspends>:void


# Active while the item is equipped.
while_equipped_resolver<public> := class<concrete>(buff_target_resolver):

    var<private> Equipped<private>:logic = false

    GetTarget<override>(BC:passive_buff_component)<transacts><decides>:entity =
        Equipped?
        ItemComp := BC.Entity.GetComponent[item_component]
        Inv := ItemComp.GetParentInventory[]
        P := Inv.GetOwningPlayer[]
        P.GetStatsHolderEntity[]

    AwaitNextChange<override>(BC:passive_buff_component)<suspends>:void =
        if (ItemComp := BC.Entity.GetComponent[item_component]):
            Result := ItemComp.ChangeEquippedEvent.Await()
            set Equipped = Result.IsItemEquipped


# Active whenever the item is in any inventory.
while_in_inventory_resolver<public> := class<concrete>(buff_target_resolver):

    GetTarget<override>(BC:passive_buff_component)<transacts><decides>:entity =
        ItemComp := BC.Entity.GetComponent[item_component]
        Inv := ItemComp.GetParentInventory[]
        P := Inv.GetOwningPlayer[]
        P.GetStatsHolderEntity[]


    AwaitNextChange<override>(BC:passive_buff_component)<suspends>:void =
        if (ItemComp := BC.Entity.GetComponent[item_component]):
            ItemComp.ChangeEquippedEvent.Await()


while_equipped_on_character_resolver<public> := class<concrete>(buff_target_resolver):

    var<private> Equipped<private>:logic = false

    GetTarget<override>(BC:passive_buff_component)<transacts><decides>:entity =
        Equipped?
        ItemComp := BC.Entity.GetComponent[item_component]
        Inv := ItemComp.GetParentInventory[]
        P := Inv.GetOwningPlayer[]
        Char := P.GetFortCharacter[]
        CharE := Char.GetEntity[]


    AwaitNextChange<override>(BC:passive_buff_component)<suspends>:void =
        if (ItemComp := BC.Entity.GetComponent[item_component]):
            race:
                AwaitEquipChange(ItemComp)
                AwaitCharSwap(BC)

    AwaitEquipChange<private>(ItemComp:item_component)<suspends>:void =
        Result := ItemComp.ChangeEquippedEvent.Await()
        set Equipped = Result.IsItemEquipped

    AwaitCharSwap<private>(BC:passive_buff_component)<suspends>:void =
        if:
            ItemComp := BC.Entity.GetComponent[item_component]
            Inv := ItemComp.GetParentInventory[]
            OwningPlayer := Inv.GetOwningPlayer[]
            PEM := BC.Entity.GetPlayerEventManager[]
        then:
            loop:
                Signaled := PEM.PlayerRespawnedEvent.Await()
                if (Signaled = OwningPlayer):
                    return
        else:
            Sleep(Inf)
