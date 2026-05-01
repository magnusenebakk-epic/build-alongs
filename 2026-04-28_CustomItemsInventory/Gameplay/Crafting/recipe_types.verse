using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Itemization }


# Stackables contribute StackSize toward Count; non-stackables 1.
recipe_ingredient<public> := class:

    @editable
    ItemType<public>:subtype(item_component)

    @editable
    Count<public>:int = 1


# Position-agnostic; sums stack sizes across descendants.
unordered_recipe<public> := class(recipe):

    @editable
    Ingredients<public>:[]recipe_ingredient

    @editable
    Strict<public>:logic = false

    Available<override>(Inv:inventory_component)<transacts><decides>:void =
        for (I : Ingredients):
            Have := CountInInventory(Inv, I.ItemType)
            if (Strict?):
                Have = I.Count
            else:
                Have >= I.Count
        if (Strict?):
            NoForeignItems[Inv]

    Consume<override>(Inv:inventory_component)<transacts><decides>:void =
        for (I : Ingredients):
            ConsumeFromInventory[Inv, I.ItemType, I.Count]

    CountInInventory<private>(Inv:inventory_component, ItemType:castable_subtype(item_component))<transacts>:int =
        var Total:int = 0
        for (Item : Inv.FindItems(ItemType)):
            set Total = Total + Item.GetComponent[stackable_component].StackSize or 1
        Total

    NoForeignItems<private>(Inv:inventory_component)<transacts><decides>:void =
        Items := for (Item : Inv.FindItems()) { Item }
        AllAccountedFor[Items, ItemMatchesIngredient]

    ItemMatchesIngredient<private>(Item:entity)<transacts><decides>:void =
        Matches := for (I : Ingredients, Item.GetComponent[I.ItemType]) { I }
        Matches.Length > 0

    GetMissingTypes<override>(Inv:inventory_component)<transacts>:[]subtype(item_component) =
        for (I : Ingredients, CountInInventory(Inv, I.ItemType) < I.Count) { I.ItemType }

    ConsumeFromInventory<private>(Inv:inventory_component, ItemType:castable_subtype(item_component), Amount:int)<transacts><decides>:void =
        var Remaining:int = Amount
        for:
            Item : Inv.FindItems(ItemType)
            Remaining > 0
        do:
            if (Stack := Item.GetComponent[stackable_component]):
                StackSize := Stack.StackSize
                if (StackSize <= Remaining):
                    Inv.RemoveItem(Item).GetSuccess[]
                    set Remaining = Remaining - StackSize
                else:
                    Stack.SetStackSize(StackSize - Remaining)
                    set Remaining = 0
            else:
                Inv.RemoveItem(Item).GetSuccess[]
                set Remaining = Remaining - 1


ordered_slot_requirement<public> := class:

    @editable
    SlotIndex<public>:int

    @editable
    ItemType<public>:subtype(item_component)

    @editable
    Count<public>:int


# Slot N must hold ItemType with count >= Count.
ordered_recipe<public> := class(recipe):

    @editable
    Slots<public>:[]ordered_slot_requirement

    @editable
    Strict<public>:logic = false

    Available<override>(Inv:inventory_component)<transacts><decides>:void =
        Crafter := crafter_inventory_component[Inv]
        for (S : Slots):
            Item := Crafter.GetItemInSlot[S.SlotIndex]
            Item.GetComponent[S.ItemType]
            Have := if (Stack := Item.GetComponent[stackable_component]) then Stack.StackSize else 1
            if (Strict?):
                Have = S.Count
            else:
                Have >= S.Count
        if (Strict?):
            NoUnspecifiedSlotsOccupied[Crafter]

    Consume<override>(Inv:inventory_component)<transacts><decides>:void =
        Crafter := crafter_inventory_component[Inv]
        for:
            S : Slots
            Item := Crafter.GetItemInSlot[S.SlotIndex]
        do:
            if (Stack := Item.GetComponent[stackable_component]):
                if (Stack.StackSize <= S.Count):
                    Inv.RemoveItem(Item).GetSuccess[]
                else:
                    Stack.SetStackSize(Stack.StackSize - S.Count)
            else:
                Inv.RemoveItem(Item).GetSuccess[]

    NoUnspecifiedSlotsOccupied<private>(Crafter:crafter_inventory_component)<transacts><decides>:void =
        Indices := for (Idx -> Slot : Crafter.GetSlotItems()) { Idx }
        AllAccountedFor[Indices, IndexInSlots]

    IndexInSlots<private>(Idx:int)<transacts><decides>:void =
        Matches := for (S : Slots, S.SlotIndex = Idx) { S }
        Matches.Length > 0

    GetMissingTypes<override>(Inv:inventory_component)<transacts>:[]subtype(item_component) =
        if (Crafter := crafter_inventory_component[Inv]):
            for (S : Slots, not OrderedSlotSatisfied[Crafter, S]) { S.ItemType }
        else:
            array{}

    OrderedSlotSatisfied<private>(Crafter:crafter_inventory_component, S:ordered_slot_requirement)<transacts><decides>:void =
        Item := Crafter.GetItemInSlot[S.SlotIndex]
        Item.GetComponent[S.ItemType]
        Have := if (Stack := Item.GetComponent[stackable_component]) then Stack.StackSize else 1
        Have >= S.Count


# RequiredType:false = cell must be empty.
shape_cell<public> := class<concrete>:

    @editable
    RequiredType<public>:?subtype(item_component) = false

    @editable
    Count<public>:int = 1


shape_row<public> := class<concrete>:

    @editable
    Cells<public>:[]shape_cell = array{}


# 2D pattern, translation-invariant. Cells outside the bbox must be empty.
shape_recipe<public> := class(recipe):

    @editable
    Pattern<public>:[]shape_row

    Available<override>(Inv:inventory_component)<transacts><decides>:void =
        Grid := grid_crafter_inventory_component[Inv]
        PatH := Pattern.Length
        PatH > 0
        FirstRow := Pattern[0]
        PatW := FirstRow.Cells.Length
        PatW > 0
        Grid.Height >= PatH
        Grid.Width >= PatW
        Origins := for:
            R := 0..(Grid.Height - PatH)
            C := 0..(Grid.Width - PatW)
            MatchesAt[Grid, R, C, PatH, PatW]
        do:
            (R, C)
        Origins[0]

    Consume<override>(Inv:inventory_component)<transacts><decides>:void =
        Grid := grid_crafter_inventory_component[Inv]
        PatH := Pattern.Length
        FirstRow := Pattern[0]
        PatW := FirstRow.Cells.Length
        Origins := for:
            R := 0..(Grid.Height - PatH)
            C := 0..(Grid.Width - PatW)
            MatchesAt[Grid, R, C, PatH, PatW]
        do:
            (R, C)
        Origin := Origins[0]
        for (I -> Row : Pattern, J -> Cell : Row.Cells, T := Cell.RequiredType?):
            ConsumeCell[Inv, Grid, Origin(0) + I, Origin(1) + J, Cell.Count]

    # Per-cell check
    GetMissingTypes<override>(Inv:inventory_component)<transacts>:[]subtype(item_component) =
        if (Grid := grid_crafter_inventory_component[Inv]):
            for:
                Row : Pattern
                Cell : Row.Cells
                T := Cell.RequiredType?
                CountInGrid(Grid, T) < Cell.Count
            do:
                T
        else:
            array{}

    CountInGrid<private>(Grid:grid_crafter_inventory_component, T:castable_subtype(item_component))<transacts>:int =
        var Total:int = 0
        for (Item : Grid.FindItems(T)):
            set Total = Total + Item.GetComponent[stackable_component].StackSize or 1
        Total

    MatchesAt<private>(Grid:grid_crafter_inventory_component, OriginRow:int, OriginCol:int, PatH:int, PatW:int)<transacts><decides>:void =
        Total := Grid.Width * Grid.Height
        Matched := for:
            GR := 0..(Grid.Height - 1)
            GC := 0..(Grid.Width - 1)
            CellOk[Grid, GR, GC, OriginRow, OriginCol, PatH, PatW]
        do:
            true
        Matched.Length = Total

    CellOk<private>(Grid:grid_crafter_inventory_component, GR:int, GC:int, OriginRow:int, OriginCol:int, PatH:int, PatW:int)<transacts><decides>:void =
        InRow := GR - OriginRow
        InCol := GC - OriginCol
        Inside:logic = logic{InRow >= 0 and InRow < PatH and InCol >= 0 and InCol < PatW}
        if (Inside?):
            Cell := Pattern[InRow].Cells[InCol]
            PatternCellMatches[Grid, GR, GC, Cell]
        else:
            GridCellEmpty[Grid, GR, GC]

    PatternCellMatches<private>(Grid:grid_crafter_inventory_component, GR:int, GC:int, Cell:shape_cell)<transacts><decides>:void =
        SlotIdx := GR * Grid.Width + GC
        if (T := Cell.RequiredType?):
            Item := Grid.GetItemInSlot[SlotIdx]
            Item.GetComponent[T]
            Have := if (Stack := Item.GetComponent[stackable_component]) then Stack.StackSize else 1
            Have >= Cell.Count
        else:
            not Grid.GetItemInSlot[SlotIdx]

    GridCellEmpty<private>(Grid:grid_crafter_inventory_component, GR:int, GC:int)<transacts><decides>:void =
        SlotIdx := GR * Grid.Width + GC
        not Grid.GetItemInSlot[SlotIdx]

    ConsumeCell<private>(Inv:inventory_component, Grid:grid_crafter_inventory_component, GR:int, GC:int, Count:int)<transacts><decides>:void =
        SlotIdx := GR * Grid.Width + GC
        Item := Grid.GetItemInSlot[SlotIdx]
        if (Stack := Item.GetComponent[stackable_component]):
            if (Stack.StackSize <= Count):
                Inv.RemoveItem(Item).GetSuccess[]
            else:
                Stack.SetStackSize(Stack.StackSize - Count)
        else:
            Inv.RemoveItem(Item).GetSuccess[]
