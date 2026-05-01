using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Itemization }


craft_success<public> := class:
    NewItems<public>:[]entity


craft_error<public> := class<computes>:


inputs_unavailable_craft_error<public> := class<computes>(craft_error):
    MissingItemTypes<public>:[]subtype(item_component)


no_outputs_craft_error<public> := class<concrete><computes>(craft_error){}


no_capacity_craft_error<public> := class<concrete><computes>(craft_error){}


consume_failed_craft_error<public> := class<concrete><computes>(craft_error){}
