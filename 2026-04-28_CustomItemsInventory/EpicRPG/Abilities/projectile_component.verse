using { /Verse.org/SceneGraph }
using { /Verse.org/SceneGraph/KeyframedMovement }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }
using { /Verse.org/Concurrency }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/SpatialMath }

using { Gameplay.Abilities }


# Flies forward, deals damage on first agent hit, despawns.
projectile_component<public> := class<final_super>(component):

    @editable
    var Speed<public>:float = 1500.0

    @editable
    var MaxLifetime<public>:float = 5.0

    @editable
    var (projectile_component:)Damage<public>:float = 25.0

    @editable
    var PassThroughNonAgents<public>:logic = true

    @editable
    var AttributeToInstigator<public>:logic = false

    @editable
    var DamageApplier<public>:damage_applier

    var<private> SourceCharEntity<private>:?entity = false
    var<private> HitEvent<private>:event() = event(){}

    OnSimulate<override>()<suspends>:void =
        Sleep(0.0)
        if (E := ResolveSourceCharEntity[]):
            set SourceCharEntity = option{E}

        if (Movement := Entity.GetComponent[keyframed_movement_component]):
            ConfigureMovement(Movement)
            Movement.Play()
            race:
                HitListenLoop()
                HitEvent.Await()
                Movement.FinishedEvent.Await()
        else:
            race:
                HitListenLoop()
                HitEvent.Await()
                Sleep(MaxLifetime)

        Entity.RemoveFromParent()

    ConfigureMovement<private>(Movement:keyframed_movement_component):void =
        Forward := Entity.GetGlobalTransform().Rotation.GetForwardAxis()
        Delta := keyframed_movement_delta{
            Transform := (LUF:)transform{
                Translation := Forward * Speed * MaxLifetime,
                Rotation    := (LUF:)IdentityRotation(),
                Scale       := (LUF:)vector3{}
            },
            Duration := MaxLifetime,
            Easing   := linear_easing_function{}
        }
        Movement.SetKeyframes(array{Delta}, oneshot_keyframed_movement_playback_mode{})

    HitListenLoop<private>()<suspends>:void =
        if (Mesh := Entity.GetComponent[mesh_component]):
            loop:
                HitEntity:entity = Mesh.EntityEnteredEvent.Await()
                if:
                    Char := FindFortCharacterAt[HitEntity]
                    Target := Char.GetAgent[]
                    TargetCharEntity := Char.GetEntity[]
                    NotSource[TargetCharEntity]
                then:
                    ApplyDamage(Target, Char)
                    HitEvent.Signal()
                    break
                else if (not PassThroughNonAgents?):
                    HitEvent.Signal()
                    break
        else:
            Sleep(Inf)

    # The hit entity may be a child of the entity actually carrying
    # fort_character, so walk self + ancestors.
    FindFortCharacterAt<private>(E:entity)<transacts><decides>:fort_character =
        Containers := array{E} + (for (A : E.FindAncestorEntities(entity)) { A })
        Found := for:
            C : Containers
            Comp : C.GetComponents()
            FC := fort_character[Comp]
        do:
            FC
        Found[0]

    NotSource<private>(TargetCharEntity:entity)<reads><decides>:void =
        if (S := SourceCharEntity?):
            not (S = TargetCharEntity)

    ApplyDamage<private>(Target:agent, Char:fort_character):void =
        Source := SourceOpt()
        Instigator:?game_action_instigator = if (AttributeToInstigator?) then option{SourceInstigator[]} else false
        DamageApplier.Apply(Source, Target, Char, Self.Damage, Instigator)

    SourceOpt<private>():?agent =
        if (S := Entity.GetSource[]) then option{S} else false

    SourceInstigator<private>()<decides><transacts>:game_action_instigator =
        Entity.GetSource[].GetInstigator()

    ResolveSourceCharEntity<private>()<transacts><decides>:entity =
        Source := Entity.GetSource[]
        Char := Source.GetFortCharacter[]
        Char.GetEntity[]
