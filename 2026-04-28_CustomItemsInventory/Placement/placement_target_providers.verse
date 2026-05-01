using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }


placement_target_provider<public> := class<abstract>:
    ProvideTarget<public>(InteractComponent:placable_component):entity


direct_placement_target_provider<public> := class<concrete>(placement_target_provider):
    ProvideTarget<override>(InteractComponent:placable_component):entity =
        InteractComponent.Entity


prefab_placement_target_provider<public> := class(placement_target_provider):

    @editable
    WorldPrefab<public>:concrete_subtype(entity)

    ProvideTarget<override>(InteractComponent:placable_component):entity =
        WorldPrefab{}
