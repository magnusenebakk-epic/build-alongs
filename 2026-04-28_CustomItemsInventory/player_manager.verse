using { /Verse.org/Concurrency }
using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
using { /Fortnite.com/Game }
using { /Fortnite.com/Playspaces }


player_data<public> := class:
    Player<public>:player
    StateEntity<public>:entity
var PlayerDataCache<internal>:weak_map(session, [player]player_data) = map{}


(Player:player).GetPlayerData()<transacts><decides>:player_data =
    PlayerDataCache[GetSession()][Player]

player_manager_tag<public> := class(tag){}

(InEntity:entity).GetPlayerManager()<transacts><decides>:player_manager =
    Sim := InEntity.GetSimulationEntity[]
    MgrEntity := Sim.FindDescendantEntitiesWithTag(player_manager_tag).First[]
    MgrEntity.GetComponent[player_manager]


# Spawns one StateEntityPrefab per player
player_manager<public> := class<final_super>(component):

    @editable
    var StateEntityPrefab<public>:?concrete_subtype(entity) = false

    PlayerReadyEvent<public>:Concurrency.subscribable_event(player) =
        Concurrency.subscribable_event(player){}

    PlayerLeavingEvent<public>:Concurrency.subscribable_event(player) =
        Concurrency.subscribable_event(player){}

    var<private> RoundSubscriptions<private>:[]cancelable = array{}
    var<private> PlayerSubscriptions<private>:[]cancelable = array{}

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        if (RM := Entity.GetFortRoundManager[]):
            set RoundSubscriptions += array{
                RM.SubscribeRoundStarted(OnRoundStarted),
                RM.SubscribeRoundEnded(OnRoundEnded)
            }

    OnEndSimulation<override>():void =
        (super:)OnEndSimulation()
        for (C : RoundSubscriptions):
            C.Cancel()
        set RoundSubscriptions = array{}
        TeardownRound()

    OnRoundStarted<private>()<suspends>:void =
        if (Playspace := Entity.GetPlayspaceForEntity[]):
            for (P : Playspace.GetPlayers()):
                OnPlayerAdded(P)
            set PlayerSubscriptions += array{
                Playspace.PlayerAddedEvent().Subscribe(OnPlayerAdded),
                Playspace.PlayerRemovedEvent().Subscribe(OnPlayerRemoved)
            }

    OnRoundEnded<private>():void =
        TeardownRound()

    TeardownRound<private>():void =
        for (C : PlayerSubscriptions):
            C.Cancel()
        set PlayerSubscriptions = array{}
        if (Playspace := Entity.GetPlayspaceForEntity[]):
            for (P : Playspace.GetPlayers()):
                OnPlayerRemoved(P)

    OnPlayerAdded<private>(Player:player):void =
        if (Existing := Player.GetPlayerData[]):
            return

        if (Prefab := StateEntityPrefab?):
            StateEntity := Prefab{}
            Entity.AddEntities(array{StateEntity})

            Data := player_data{Player := Player, StateEntity := StateEntity}
            Session := GetSession()
            if (not PlayerDataCache[Session]):
                if (set PlayerDataCache[Session] = map{}) {}
            if (set PlayerDataCache[Session][Player] = Data) {}
            PlayerReadyEvent.Signal(Player)

    OnPlayerRemoved<private>(Player:player):void =
        if (Data := Player.GetPlayerData[]):
            PlayerLeavingEvent.Signal(Player)
            Data.StateEntity.RemoveFromParent()
            Session := GetSession()
            if (Cache := PlayerDataCache[Session]):
                NewCache := Cache.RemoveKey(Player)
                if (set PlayerDataCache[Session] = NewCache) {}
