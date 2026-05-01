using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Itemization }


# TODO: when a hashing API exists, swap the linear Recipes scan for a hash
# lookup. Doable for unordered/shape; ordered would need its own hashing strategy or opt out.

# TODO: Matching order. If the set of items required in an unordered recipe that precedes an ordered recipe
# it will craft the unordered recipe before the ordered one, even if you have all items in the ordered one.

crafting_component<public> := class<final_super>(component):

    @editable
    var Recipes<public>:[]recipe = array{}

    CanCraft<public>(R:recipe, InputInv:inventory_component)<transacts><decides>:void =
        R.Available[InputInv]

    Craft<public>(R:recipe, InputInv:inventory_component, OutputInv:inventory_component)<transacts>:result(craft_success, craft_error) =
        if (not R.Available[InputInv]):
            return MakeError(inputs_unavailable_craft_error{
                MissingItemTypes := R.GetMissingTypes(InputInv)
            })
        if (R.Outputs.Length = 0):
            return MakeError(no_outputs_craft_error{})

        NewItems := for (Out : R.Outputs) { Out{} }

        for (N : NewItems):
            if (not OutputInv.CanAddItemDistribute(N).GetSuccess[]):
                return MakeError(no_capacity_craft_error{})

        if (R.Consume[InputInv]) {} else:
            return MakeError(consume_failed_craft_error{})

        for (N : NewItems):
            if (OutputInv.AddItemDistribute(N, ?AllowMergeItems := true).GetSuccess[]) {}
        MakeSuccess(craft_success{NewItems := NewItems})
