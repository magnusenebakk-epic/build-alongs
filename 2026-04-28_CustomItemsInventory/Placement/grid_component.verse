using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }


grid_component<public> := class<final_super>(component):

    @editable
    var CellSize<public>:float = 100.0

    @editable
    var CellsForward<public>:int = 10

    @editable
    var CellsLeft<public>:int = 10

    @editable
    var OriginOffset<public>:(LUF:)vector3 = (LUF:)vector3{Forward := 0.0, Left := 0.0, Up := 0.0}

    # Snaps a world position to the nearest cell on the grid plane
    Snap<public>(WorldPos:vector3)<transacts><decides>:vector3 =
        Origin := Entity.GetGlobalTransform().Translation + OriginOffset
        Local := WorldPos - Origin

        IndexF := Round[Local.Forward / CellSize]
        IndexL := Round[Local.Left / CellSize]

        IndexF >= 0
        IndexF <= CellsForward
        IndexL >= 0
        IndexL <= CellsLeft

        Origin + (LUF:)vector3{
            Forward := IndexF * CellSize,
            Left    := IndexL * CellSize,
            Up      := 0.0
        }


FindGridComponent<public>(E:entity)<transacts><decides>:grid_component =
    E.GetComponent[grid_component] or E.FindAncestorComponents(grid_component).First[]
