using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }


# Accepts hits whose target entity or any ancestor carries a grid_component.
grid_component_hit_filter<public> := class<concrete>(hit_filter):
    Accepts<override>(Hit:sweep_hit)<transacts><decides>:void =
        FindGridComponent[Hit.TargetComponent.Entity]
