using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }


# Logs proposal changes to Print.
log_placement_highlight<public> := class<concrete>(placement_highlight):
    var<private> LastMsg<private>:string = ""

    ShowPreview<override>(Query:placement_query, Proposal:placement_proposal, IsValid:logic):void =
        ValidStr := if (IsValid?) then "ok" else "blocked"
        Msg := "{ToString(Proposal.Transform)} [{ValidStr}]"
        if (Msg <> LastMsg):
            Print("placement preview @ {Msg}")
            set LastMsg = Msg

    HidePreview<override>():void =
        if (LastMsg <> ""):
            Print("placement preview hidden")
            set LastMsg = ""


# Implement on highlight prefab descendants to react to validity changes.
# such as changing a material parameter on invalid
placement_highlight_reactive<public> := interface<castable>(p_interface):
    OnPlacementValidChanged<public>(IsValid:logic):void


# spawns HighlightPrefab on first show, retransforms each tick, despawns on hide.
prefab_highlight<public> := class<concrete>(placement_highlight):

    @editable
    HighlightPrefab<public>:?concrete_subtype(entity) = false

    var<private> Spawned<private>:?entity = false
    # ?logic so first ShowPreview always notifies
    var<private> LastValid<private>:?logic = false

    ShowPreview<override>(Query:placement_query, Proposal:placement_proposal, IsValid:logic):void =
        Active := GetHighlight(Query)
        Active.SetGlobalTransform(Proposal.Transform)
        if (LastValid <> option{IsValid}):
            NotifyValidChanged(Active, IsValid)
            set LastValid = option{IsValid}

    HidePreview<override>():void =
        if (E := Spawned?):
            E.RemoveFromParent()
            set Spawned = false
            set LastValid = false

    GetHighlight<private>(Query:placement_query):entity =
        Spawned? or SpawnNew(Query)

    SpawnNew<private>(Query:placement_query):entity =
        NewHighlight := if:
            P := HighlightPrefab?
            Sim := Query.PlacableEntity.GetSimulationEntity[]
        then:
            New := P{}
            Sim.AddEntities(array{New})
            New
        else:
            entity{} # TODO: make this better default

        set Spawned = option{NewHighlight}
        NewHighlight

    NotifyValidChanged<private>(HighlightEntity:entity, IsValid:logic):void =
        for (R : HighlightEntity.GetDescendantComponentsWithInterface(placement_highlight_reactive)):
            R.OnPlacementValidChanged(IsValid)
