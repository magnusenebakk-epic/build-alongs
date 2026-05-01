using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Itemization }


grid_crafter_inventory_component<public> := class<final>(crafter_inventory_component):

    @editable
    Width<public>:int = 3

    @editable
    Height<public>:int = 3
