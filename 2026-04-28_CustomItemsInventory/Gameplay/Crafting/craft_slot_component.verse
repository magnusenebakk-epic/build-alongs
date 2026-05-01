using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Itemization }


# Single-item inventory for one bench slot. Add an
# inventory_display_component as a sibling for visuals.
craft_slot_component<public> := class<final>(inventory_component):

    @editable
    var SlotIndex<public>:int = 0

    @editable
    var Filter<public>:slot_filter = tag_slot_filter{}

    HasItem<public>()<reads><decides>:void =
        GetItems()[0]

    Deposit<public>(Agent:agent)<decides><transacts>:void =
        AgentInv := Agent.GetInventoryRoot[]
        
        Eligible := for:
            I : AgentInv.FindItems()
            Comp := I.GetComponent[item_component]
            Comp.IsEquipped[]
            Filter.Accepts[I]
        do:
            I

        Item := Eligible[0]
        AgentInv.RemoveItem(Item).GetSuccess[]
        AddItem(Item).GetSuccess[]
        

    Withdraw<public>(Agent:agent)<decides><transacts>:void =
        AgentInv := Agent.GetInventoryRoot[]
        Item := GetItems()[0]
        RemoveItem(Item).GetSuccess[]
        AgentInv.AddItemDistribute(Item, ?AllowMergeItems := true).GetSuccess[]
