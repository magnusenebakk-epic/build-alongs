using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }


# RateStat: rate comes from a stat (mana_regen_rate, etc.) so buffs modify
# it via the standard stat_modifier system. RatePerSec is the fallback
regen_entry<public> := class<concrete>:

    @editable
    var StatType<public>:subtype(stat_value) = stat_value

    @editable
    var RateStat<public>:?subtype(stat_value) = false

    @editable
    var RatePerSec<public>:float = 0.0

    @editable
    var Cap<public>:?float = false


# Ticks each entry, restores up to headroom.
stat_regen_component<public> := class<final_super>(component):

    @editable
    var Entries<public>:[]regen_entry = array{}

    @editable
    var TickInterval<public>:float = 0.1

    OnSimulate<override>()<suspends>:void =
        loop:
            Sleep(TickInterval)
            Tick()

    Tick<private>():void =
        if (StatsComponent := Entity.GetComponent[stats_component]):
            for (Entry : Entries):
                ApplyEntry(StatsComponent, Entry)

    ApplyEntry<private>(StatsComponent:stats_component, Entry:regen_entry):void =
        if:
            Stat := StatsComponent.GetStat[Entry.StatType]
            EffectiveCap := if (C := Entry.Cap?) then C else Stat.MaxVal.Get()
            Headroom := EffectiveCap - Stat.GetCurrent()
            Headroom > 0.0
        then:
            Rate := EffectiveRate(StatsComponent, Entry)
            ToRestore := Min(Rate * TickInterval, Headroom)
            Stat.Restore(ToRestore)

    EffectiveRate<private>(StatsComponent:stats_component, Entry:regen_entry):float =
        if (RS := Entry.RateStat?, RateStatVal := StatsComponent.GetStat[RS]):
            RateStatVal.GetCurrent()
        else:
            Entry.RatePerSec
