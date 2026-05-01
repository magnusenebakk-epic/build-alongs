using { /Verse.org/Assets }
using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/SpatialMath }


ability_action<public> := class<abstract>:
    Execute<public>(InteractComponent:active_ability_component, Activator:agent):void


# Spawns Prefab a fixed distance ahead of the activator
spawn_prefab_action<public> := class(ability_action):

    @editable
    Prefab<public>:concrete_subtype(entity)

    @editable
    DistanceAhead<public>:float = 200.0

    Execute<override>(InteractComponent:active_ability_component, Activator:agent):void =
        if:
            P := player[Activator]
            Char := P.GetFortCharacter[]
            CharXform := FromTransform(Char.GetTransform())
            Sim := InteractComponent.Entity.GetSimulationEntity[]
        then:
            CharViewRotation := Char.GetViewRotation()

            Forward := CharXform.Rotation.GetForwardAxis()
            FlatForward := (LUF:)vector3{
                Forward := Forward.Forward,
                Left := Forward.Left,
                Up := 0.0
            }.MakeUnitVector()
            SpawnPos := CharXform.Translation + FlatForward * DistanceAhead
            New := Prefab{}
            Sim.AddEntities(array{New})
            New.SetGlobalTransform((LUF:)transform{
                Translation := SpawnPos,
                Rotation := FromRotation(CharViewRotation),
                Scale := (LUF:)vector3{Forward := 1.0, Left := 1.0, Up := 1.0}
            })

            SrcComp := source_component { Entity := New, Source := option{Activator} }
            New.AddComponents(array{SrcComp})
            if (Stored := New.GetComponent[source_component]):
                set Stored.Source = option{Activator}


print_action<public> := class<concrete>(ability_action):

    @editable
    Message<public>:string = "HI"

    Execute<override>(InteractComponent:active_ability_component, Activator:agent):void =
        Print(Message)


# Spawns BuffPrefab parented to the activator's stats holder.
apply_buff_action<public> := class(ability_action):

    @editable
    BuffPrefab<public>:concrete_subtype(entity)

    Execute<override>(InteractComponent:active_ability_component, Activator:agent):void =
        if:
            Holder := Activator.GetStatsHolderEntity[]
        then:
            New := BuffPrefab{}
            Holder.AddEntities(array{New})


composite_action<public> := class<concrete>(ability_action):

    @editable
    Actions<public>:[]ability_action = array{}

    Execute<override>(InteractComponent:active_ability_component, Activator:agent):void =
        for (A : Actions):
            A.Execute(InteractComponent, Activator)
