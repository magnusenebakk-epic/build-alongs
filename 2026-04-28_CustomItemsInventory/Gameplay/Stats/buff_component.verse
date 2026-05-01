using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }

# Entity-as-buff. Usually parented to the entity holding stats_component.

buff_component<public> := class<final_super>(component):

    @editable
    Modifiers<public>:[]stat_modifier = array{}

    # false = infinite (until externally removed). option{N} = auto-detach after N seconds.
    @editable
    Duration<public>:?float = false

    OnAddedToScene<override>():void =
        (super:)OnAddedToScene()
        if (StatsComponent := FindStatsComponent[]):
            for (M : Modifiers):
                StatsComponent.AddModifier(M, Entity)

    OnRemovingFromScene<override>():void =
        (super:)OnRemovingFromScene()
        if (StatsComponent := FindStatsComponent[]):
            StatsComponent.RemoveModifiersFrom(Entity)

    OnSimulate<override>()<suspends>:void =
        if (D := Duration?):
            Sleep(D)
            Entity.RemoveFromParent()

    FindStatsComponent<private>()<transacts><decides>:stats_component =
        Parent := Entity.GetParent[]
        Parent.GetComponent[stats_component]
