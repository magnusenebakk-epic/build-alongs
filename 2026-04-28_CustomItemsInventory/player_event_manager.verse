using { /Verse.org/Concurrency }
using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }


player_event_manager_tag<public> := class(tag){}


(InEntity:entity).GetPlayerEventManager()<transacts><decides>:player_event_manager =
    Sim := InEntity.GetSimulationEntity[]
    MgrEntity := Sim.FindDescendantEntitiesWithTag(player_event_manager_tag).First[]
    MgrEntity.GetComponent[player_event_manager]


player_event_manager<public> := class<final_super>(component):

    @editable
    var PlayerSpawners<public>:[]team_settings_and_inventory_device = array{}

    PlayerFirstSpawnEvent<public>:Concurrency.subscribable_event(player) =
        Concurrency.subscribable_event(player){}

    PlayerRespawnedEvent<public>:Concurrency.subscribable_event(player) =
        Concurrency.subscribable_event(player){}

    var<private> HasSpawned<private>:[]player = array{}
    var<private> Subscriptions<private>:[]cancelable = array{}

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        if (Playspace := Entity.GetPlayspaceForEntity[]):
            set Subscriptions += array{
                Playspace.PlayerRemovedEvent().Subscribe(OnPlayerLeft)
            }
        for (Spawner : PlayerSpawners):
            set Subscriptions += array{Spawner.TeamMemberSpawnedEvent.Subscribe(OnAgentSpawned)}

    OnEndSimulation<override>():void =
        (super:)OnEndSimulation()
        for (C : Subscriptions):
            C.Cancel()
        set Subscriptions = array{}
        set HasSpawned = array{}

    OnPlayerLeft<private>(Player:player):void =
        set HasSpawned = HasSpawned.RemoveAllElements(Player)

    OnAgentSpawned<private>(Agent:agent):void =
        if (Player := player[Agent]):
            PlayerRespawnedEvent.Signal(Player)
            if (not HasSpawned.Find[Player]):
                set HasSpawned += array{Player}
                PlayerFirstSpawnEvent.Signal(Player)
