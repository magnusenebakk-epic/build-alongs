using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { Gameplay.Stats }
using { Gameplay.Abilities }


stat_resource<public> := class(ability_resource):

    @editable
    StatType<public>:subtype(stat_value) = stat_value

    TryConsume<override>(Activator:agent, Amount:float):logic =
        if:
            Holder := Activator.GetStatsHolderEntity[]
            StatsComp := Holder.GetComponent[stats_component]
            Stat := StatsComp.GetStat[StatType]
        then:
            Stat.TrySpend(Amount)
        else:
            false
