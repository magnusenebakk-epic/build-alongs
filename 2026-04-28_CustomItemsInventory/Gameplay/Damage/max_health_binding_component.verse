using { /Verse.org/Concurrency }
using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Playspaces }

using { Gameplay.Stats }


# Pushes a stat to fort_character.SetMaxHealth on change and on respawn.
max_health_binding_component<public> := class<final_super>(component):

    @editable
    StatType<public>:subtype(stat_value) = stat_value

    var<private> ManagerSubscriptions<private>:[]Concurrency.subscription_task(player) = array{}
    var<private> Watchers<private>:[player]max_health_watcher = map{}

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        if (Mgr := Entity.GetPlayerManager[]):
            set ManagerSubscriptions += array{
                Mgr.PlayerReadyEvent.Subscribe(AttachToPlayer),
                Mgr.PlayerLeavingEvent.Subscribe(DetachFromPlayer)
            }
            # Catch-up — manager may have already signalled.
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
            Stat := StatsComp.GetStat[StatType]
        then:
            W := max_health_watcher{Player := Player, Stat := Stat}
            W.Start()
            if (set Watchers[Player] = W) {}

    DetachFromPlayer<private>(Player:player):void =
        if (W := Watchers[Player]):
            W.Stop()


# Polls for fort_character swaps. TODO: switch to player_event_manager like damage_pipeline_component.
max_health_watcher<internal> := class:
    Player:player
    Stat:stat_value

    var<private> Subscription<private>:?Concurrency.subscription_task(stat_change) = false
    var<private> Stopped<private>:logic = false
    var<private> LastChar<private>:?fort_character = false

    Start():void =
        Task := Stat.StatChangedEvent.Subscribe(OnStatChanged)
        set Subscription = option{Task}
        Push(Stat.GetCurrent())
        spawn { RespawnPollLoop() }

    Stop():void =
        set Stopped = true
        if (S := Subscription?):
            S.Cancel()
            set Subscription = false

    OnStatChanged<private>(Change:stat_change):void =
        Push(Change.NewValue)

    Push<private>(NewMax:float):void =
        if (Char := Player.GetFortCharacter[]):
            Char.SetMaxHealth(NewMax)

    RespawnPollLoop<private>()<suspends>:void =
        loop:
            if (Stopped?). break
            if:
                Char := Player.GetFortCharacter[]
                IsNew := if (L := LastChar?) then logic{not (L = Char)} else true
                IsNew?
            then:
                set LastChar = option{Char}
                Push(Stat.GetCurrent())
            Sleep(1.0)
