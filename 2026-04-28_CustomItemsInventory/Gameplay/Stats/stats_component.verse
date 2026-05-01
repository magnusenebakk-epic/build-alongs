using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }


stats_component<public> := class<final_super>(component):

    @editable
    var StatDefs<public>:[]stat_value = array{}

    var<private> DependencySubs<private>:[]Concurrency.subscription_task(stat_change) = array{}

    OnAddedToScene<override>():void =
        (super:)OnAddedToScene()
        for (Owner : StatDefs):
            ResolveBound(Owner, Owner.MinVal)
            ResolveBound(Owner, Owner.MaxVal)
        for (S : StatDefs):
            S.Init()
        
        for (S : StatDefs):
            S.Recompute()

    OnRemovingFromScene<override>():void =
        (super:)OnRemovingFromScene()
        for (S : DependencySubs):
            S.Cancel()
        set DependencySubs = array{}

    ResolveBound<private>(Owner:stat_value, B:stat_bound):void =
        if:
            R := stat_ref_stat_bound[B]
            Source := GetStat[R.StatType]
        then:
            R.SetResolved(Source)
            Task := Source.StatChangedEvent.Subscribe(Owner.OnDependencyChanged)
            set DependencySubs += array{Task}

    GetStat<public>(stat_type:castable_subtype(stat_value))<reads><decides>:stat_type =
        for (S : StatDefs, T := stat_type[S]) { T }[0]

    GetCurrent<public>(StatType:castable_subtype(stat_value))<reads><decides>:float =
        GetStat[StatType].GetCurrent()

    AddModifier<public>(Modifier:stat_modifier, Source:entity):void =
        if (S := GetStat[Modifier.Stat]):
            S.AddModifier(Modifier, Source)

    RemoveModifiersFrom<public>(Source:entity):void =
        for (S : StatDefs):
            S.RemoveModifiersFrom(Source)

    # stat_type passed explicitly
    AddStat<public>(stat_type:castable_subtype(stat_value), NewStat:stat_type)<transacts><decides>:stat_type =
        not GetStat[stat_type]
        NewStat.Init()
        set StatDefs += array{NewStat}
        NewStat

    RemoveStat<public>(stat_type:castable_subtype(stat_value))<transacts><decides>:void =
        GetStat[stat_type]
        set StatDefs = for (S : StatDefs, not stat_type[S]) { S }
