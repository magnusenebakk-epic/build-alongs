
using { /Verse.org/SceneGraph }
using { /UnrealEngine.com/Itemization }
using { /Verse.org/Simulation }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { Gameplay.Abilities }
using { Gameplay.Stats }

<#> Global Aliases
LUF := import(/Verse.org/SpatialMath)
XYZ := import(/UnrealEngine.com/Temporary/SpatialMath)


<#> Language
p_interface<public> := interface{}

NullCallback<public>(:any):void = {}


<#> Concurrency
RecursiveSync<public>(Expressions:[](type{_()<suspends>:t}) where t:type)<suspends>:[]t=
    if:
        Mid := Floor(Expressions.Length / 2)
        RightExprs := Expressions.Slice[0, Mid]
        LeftExprs := Expressions.Slice[Mid]
    then:
        Res := sync:
            RecursiveSync(RightExprs)
            RecursiveSync(LeftExprs)
        Res(0) + Res(1)
    
    # E1 exists, but Slice 1 fails -> 1 element left
    else if (E1 := Expressions[0]):
        array{E1()}
    else:
        array{}

RecursiveRace<public>(Expressions:[](type{_()<suspends>:t}) where t:type)<suspends>:t=
    if:
        Mid := Floor(Expressions.Length / 2)
        RightExprs := Expressions.Slice[0, Mid]
        LeftExprs := Expressions.Slice[Mid]
    then:
        race:
            RecursiveRace(RightExprs)
            RecursiveRace(LeftExprs)
    
    # E1 exists, but Slice fails -> 1 element left
    else if (E1 := Expressions[0]):
        E1()
    else:
        Err()


<#> Generators
(Generator:generator(t) where t:type).First<public>()<transacts><decides>:t=
    for (Item : Generator) { Item } [0]


<#> Collections
# Removes an element from the given map and returns a new map without that element.
(Map:[keytype]valuetype where keytype:subtype(comparable), valuetype:type).RemoveKey<public>(ElementToRemove:keytype):[keytype]valuetype=
    var NewMap:[keytype]valuetype = map{}
    for (Key -> Value : Map, Key <> ElementToRemove):
        set NewMap = ConcatenateMaps(NewMap, map{Key => Value})
    return NewMap


<#> Scene Graph
using { /Verse.org/SceneGraph }

default_prefab := class(entity){}

(Entity:entity).GetComponentsWithInterface(iface:castable_subtype(p_interface))<reads>:[]iface=
    for (Component : Entity.GetComponents(), IFace := iface[Component]):
        IFace

(Entity:entity).GetDescendantComponentsWithInterface(iface:castable_subtype(p_interface))<transacts>:[]iface=
    for (Component : Entity.FindDescendantComponents(component), IFace := iface[Component]):
        IFace

(InEntity:entity).GetFirstDescendantComponent(component_type:castable_subtype(component))<transacts><decides>:component_type=
    (for (I : InEntity.FindDescendantComponents(component_type)){ I })[0]

(InEntity:entity).GetFirstAncestor(entity_type:castable_subtype(entity))<transacts><decides>:entity_type=
    (for (I : InEntity.FindAncestorEntities(entity_type)){ I }) [0]

(Agent:agent).GetStatsHolderEntity()<transacts><decides>:entity=
    P := player[Agent]
    Data := P.GetPlayerData[]
    Data.StateEntity

(FortPlaySpace:fort_playspace).AwaitParticipantRemoved(Participant:agent)<suspends>:void=
    loop:
        LeavingAgent := FortPlaySpace.ParticipantRemovedEvent().Await()
        if (Participant = LeavingAgent):
            break

(Agent:agent).GetInventoryRoot()<transacts><decides>:inventory_component =
    for (Child : Agent.GetEntities(), InventoryComponent := Child.GetComponent[inventory_component]){InventoryComponent}[0]

(Inv:inventory_component).GetOwningPlayer()<transacts><decides>:player =
    if (P := player[Inv.Entity]). P
    else:
        (for (A : Inv.Entity.FindAncestorEntities(entity), P := player[A]) { P })[0]


<#> Source tracking on spawned entities
(Entity:entity).GetSource()<transacts><decides>:agent =
    if (OnSelf := Entity.GetComponent[source_component]):
        OnSelf.Source?
    else:
        Anc := Entity.FindAncestorComponents(source_component).First[]
        Anc.Source?

(Entity:entity).GetSourceStat(StatType:subtype(stat_value), DefaultIfMissing:float)<transacts>:float =
    if:
        Source := Entity.GetSource[]
        Holder := Source.GetStatsHolderEntity[]
        Stats  := Holder.GetComponent[stats_component]
        Stat   := Stats.GetStat[StatType]
    then:
        Stat.GetCurrent()
    else:
        DefaultIfMissing
