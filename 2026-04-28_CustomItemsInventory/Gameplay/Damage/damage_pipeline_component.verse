using { /Verse.org/Concurrency }
using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Game }

using { Gameplay.Stats }


# Health stat is canonical; pushes to SetHealth on change. Engine damage
# heals back, runs the pipeline, drains the stat.
#
# PREREQUISITE: disable shields in the playspace.
damage_pipeline_component<public> := class<final_super>(component):

    @editable
    var HealthStat<public>:subtype(stat_value)

    @editable
    var IncomingDamageCalc<public>:damage_calc

    # Read by damage-dealers (e.g. projectile_component) before calling
    # Damage. Source-side; see outgoing_damage_calcs.verse.
    @editable
    var OutgoingDamageCalc<public>:damage_calc

    var<private> ManagerSubscriptions<private>:[]Concurrency.subscription_task(player) = array{}
    var<private> Watchers<private>:[player]health_pipeline_watcher = map{}

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        if (Mgr := Entity.GetPlayerManager[]):
            set ManagerSubscriptions += array{
                Mgr.PlayerReadyEvent.Subscribe(AttachToPlayer),
                Mgr.PlayerLeavingEvent.Subscribe(DetachFromPlayer)
            }
            if (Playspace := Entity.GetPlayspaceForEntity[]):
                for (P : Playspace.GetPlayers(), Data := P.GetPlayerData[]):
                    AttachToPlayer(P)

    OnEndSimulation<override>():void =
        (super:)OnEndSimulation()
        for (S : ManagerSubscriptions):
            S.Cancel()
        set ManagerSubscriptions = array{}
        for (P -> W : Watchers):
            W.Stop()
        set Watchers = map{}

    AttachToPlayer<private>(Player:player):void =
        if (Existing := Watchers[Player]):
            return
        if:
            Holder := Player.GetStatsHolderEntity[]
            StatsComp := Holder.GetComponent[stats_component]
            Stat := StatsComp.GetStat[HealthStat]
        then:
            W := health_pipeline_watcher{Pipeline := Self, Player := Player, Stat := Stat}
            W.Start()
            if (set Watchers[Player] = W) {}

    DetachFromPlayer<private>(Player:player):void =
        if (W := Watchers[Player]):
            W.Stop()


health_pipeline_watcher<internal> := class:
    Pipeline:damage_pipeline_component
    Player:player
    Stat:stat_value

    var<private> StatSub<private>:?Concurrency.subscription_task(stat_change) = false
    var<private> DamageSub<private>:?cancelable = false
    var<private> RespawnSub<private>:?Concurrency.subscription_task(player) = false
    var<private> CurrentChar<private>:?fort_character = false

    Start<public>():void =
        Task := Stat.StatChangedEvent.Subscribe(OnStatChanged)
        set StatSub = option{Task}
        if (PEM := Pipeline.Entity.GetPlayerEventManager[]):
            RTask := PEM.PlayerRespawnedEvent.Subscribe(OnRespawn)
            set RespawnSub = option{RTask}
        AttachIfNew()

    Stop<public>():void =
        if (S := StatSub?):
            S.Cancel()
            set StatSub = false
        if (DamageSub?.Cancel()):
            set DamageSub = false
        if (R := RespawnSub?):
            R.Cancel()
            set RespawnSub = false

    # SetHealth doesn't fire DamagedEvent, so no re-entry.
    OnStatChanged<private>(Change:stat_change):void =
        if (Char := Player.GetFortCharacter[]):
            Char.SetHealth(Change.NewValue)

    OnDamaged<private>(Result:damage_result):void =
        if (Char := CurrentChar?):
            Source:?agent = if:
                I := Result.Instigator?
                A := I.GetInstigatorAgent[]
            then:
                option{A}
            else:
                false

            Payload := damage_payload{
                Amount := Result.Amount,
                Source := Source,
                Target := Player
            }

            set Payload.Amount = Pipeline.IncomingDamageCalc.Compute(Payload.Amount, Player, Source)

            if (Holder := Player.GetStatsHolderEntity[]):
                for (H : Holder.GetDescendantComponentsWithInterface(damage_taking_handler)):
                    H.OnTakingDamage(Payload)

            # Heal back. Lands before elimination commits in practice.
            Char.SetHealth(Char.GetHealth() + Result.Amount)

            # Clamp so overkill ends at 0 — player dies via SetHealth(0).
            Available := Stat.GetCurrent()
            ToDrain := if (Payload.Amount > Available) then Available else Payload.Amount
            if (ToDrain > 0.0):
                SpendResult := Stat.TrySpend(ToDrain)

            if (Holder := Player.GetStatsHolderEntity[]):
                for (H : Holder.GetDescendantComponentsWithInterface(after_damage_taking_handler)):
                    H.AfterTakingDamage(Payload)

    OnRespawn<private>(Signaled:player):void =
        if (Signaled = Player):
            AttachIfNew()

    AttachIfNew<private>():void =
        if:
            Char := Player.GetFortCharacter[]
            IsNew := if (L := CurrentChar?) then logic{not (L = Char)} else true
            IsNew?
        then:
            set CurrentChar = option{Char}
            if (DamageSub?.Cancel()) { set DamageSub = false }
            Task := Char.DamagedEvent().Subscribe(OnDamaged)
            set DamageSub = option{Task}
            Char.SetHealth(Stat.GetCurrent())
