using { /Verse.org/Simulation }
using { /Verse.org/SceneGraph }
using { Gameplay.Stats }
using { Gameplay.Abilities }


print_stat_action<public> := class(ability_action):

    @editable
    StatType<public>:subtype(stat_value) = stat_value

    Execute<override>(InteractComponent:active_ability_component, Activator:agent):void =
        if:
            Holder := Activator.GetStatsHolderEntity[]
            StatsComp := Holder.GetComponent[stats_component]
            Cur := StatsComp.GetStat[StatType]
        then:
            Print("Current {Cur.Name}: {Cur.GetCurrent()}")
