using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }


placement_query<public> := class:
    Player<public>:player
    PlacableEntity<public>:entity


# Method output
placement_proposal<public> := class:
    Transform<public>:transform
    HitNormal<public>:?vector3 = false
    HitEntity<public>:?entity = false


# Fails when there's no valid proposal this tick
placement_method<public> := class<abstract>:
    ComputeProposal<public>(Query:placement_query)<transacts><decides>:placement_proposal


# Predicate over a sweep_hit
hit_filter<public> := class<abstract>:
    Accepts<public>(Hit:sweep_hit)<transacts><decides>:void


hit_aware_placement_method<public> := class<abstract>(placement_method):
    @editable
    var HitFilters<public>:[]hit_filter = array{}

    # First hit that passes all HitFilters and fails if none.
    FirstAcceptedHit<protected>(Hits:generator(sweep_hit))<transacts><decides>:sweep_hit =
        (for (H : Hits, AcceptsAll[H]) { H })[0]

    AcceptsAll<private>(Hit:sweep_hit)<transacts><decides>:void =
        for (F : HitFilters) { F.Accepts[Hit] }


# restriction predicate
placement_restriction<public> := class<abstract>:
    CanPlaceAt<public>(Query:placement_query, Proposal:placement_proposal)<transacts><decides>:void


# Per-tick visual preview. ShowPreview is called every tick while a proposal exists.
placement_highlight<public> := interface:
    ShowPreview<public>(Query:placement_query, Proposal:placement_proposal, IsValid:logic):void
    HidePreview<public>():void
