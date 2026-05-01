using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Itemization }


recipe<public> := class<abstract>:

    @editable
    Outputs<public>:[]concrete_subtype(entity)

    Available<public>(Inv:inventory_component)<transacts><decides>:void
    Consume<public>(Inv:inventory_component)<transacts><decides>:void
    GetMissingTypes<public>(Inv:inventory_component)<transacts>:[]subtype(item_component) = array{}


AllAccountedFor<internal>(Elements:[]t, Predicate:type{_(:t)<transacts><decides>:void} where t:type)<transacts><decides>:void =
    for (E : Elements) { Predicate[E] }
