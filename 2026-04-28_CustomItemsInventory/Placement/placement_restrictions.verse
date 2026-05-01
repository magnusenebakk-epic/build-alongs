using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }


# Fails when the hit surface isn't up-aligned enough
surface_orientation_restriction<public> := class<concrete>(placement_restriction):

    @editable
    var MinUpDot<public>:float = 0.866

    CanPlaceAt<override>(Query:placement_query, Proposal:placement_proposal)<transacts><decides>:void =
        if (Normal := Proposal.HitNormal?):
            Normal.Up >= MinUpDot


# Fails when HitEntity has a tag_acceptor_component and the item carries none of its accepted tags.
hit_entity_accepts_tag_restriction<public> := class<concrete>(placement_restriction):

    CanPlaceAt<override>(Query:placement_query, Proposal:placement_proposal)<transacts><decides>:void =
        if:
            HitEnt   := Proposal.HitEntity?
            Acceptor := HitEnt.GetComponent[tag_acceptor_component]
        then:
            Query.PlacableEntity.ContainsAnyTag[Acceptor.AcceptedTags]
