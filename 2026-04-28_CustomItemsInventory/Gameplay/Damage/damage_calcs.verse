using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }

using { Gameplay.Stats }


damage_calc<public> := class<abstract>:
    Compute<public>(Incoming:float, Target:agent, Source:?agent):float

armor_damage_calc<public> := class<concrete>(damage_calc):

    @editable
    ArmorStat<public>:subtype(stat_value) = stat_value

    @editable
    HalvingArmor<public>:float = 100.0

    Compute<override>(Incoming:float, Target:agent, Source:?agent):float =
        if:
            Holder := Target.GetStatsHolderEntity[]
            StatsComponent := Holder.GetComponent[stats_component]
            Armor := StatsComponent.GetCurrent[ArmorStat]
            Armor > 0.0
        then:
            Incoming * HalvingArmor / (HalvingArmor + Armor)
        else:
            Incoming


stat_multiplier_damage_calc<public> := class<concrete>(damage_calc):

    @editable
    Stat<public>:subtype(stat_value) = stat_value

    @editable
    DefaultMultiplier<public>:float = 1.0

    Compute<override>(Incoming:float, Target:agent, Source:?agent):float =
        if:
            Holder := Target.GetStatsHolderEntity[]
            StatsComponent := Holder.GetComponent[stats_component]
            Mul := StatsComponent.GetCurrent[Stat]
        then:
            Incoming * Mul
        else:
            Incoming * DefaultMultiplier


min_damage_calc<public> := class<concrete>(damage_calc):

    @editable
    Minimum<public>:float = 1.0

    Compute<override>(Incoming:float, Target:agent, Source:?agent):float =
        if (Incoming < Minimum) then Minimum else Incoming


chain_damage_calc<public> := class<concrete>(damage_calc):

    @editable
    Steps<public>:[]damage_calc = array{}

    Compute<override>(Incoming:float, Target:agent, Source:?agent):float =
        var V:float = Incoming
        for (S : Steps):
            set V = S.Compute(V, Target, Source)
        V
