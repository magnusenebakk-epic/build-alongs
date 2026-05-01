using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }

using { Stats }


source_stat_multiplier_damage_calc<public> := class<concrete>(damage_calc):

    @editable
    Stat<public>:subtype(stat_value) = stat_value

    @editable
    DefaultMultiplier<public>:float = 1.0

    Compute<override>(Outgoing:float, Target:agent, Source:?agent):float =
        if:
            S := Source?
            Holder := S.GetStatsHolderEntity[]
            StatsComponent := Holder.GetComponent[stats_component]
            Mul := StatsComponent.GetCurrent[Stat]
        then:
            Outgoing * Mul
        else:
            Outgoing * DefaultMultiplier


source_flat_bonus_damage_calc<public> := class<concrete>(damage_calc):

    @editable
    Stat<public>:subtype(stat_value) = stat_value

    @editable
    DefaultBonus<public>:float = 0.0

    Compute<override>(Outgoing:float, Target:agent, Source:?agent):float =
        if:
            S := Source?
            Holder := S.GetStatsHolderEntity[]
            StatsComponent := Holder.GetComponent[stats_component]
            Bonus := StatsComponent.GetCurrent[Stat]
        then:
            Outgoing + Bonus
        else:
            Outgoing + DefaultBonus
