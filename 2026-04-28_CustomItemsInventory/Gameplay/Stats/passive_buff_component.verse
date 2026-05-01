using { /Verse.org/Concurrency }
using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }


# One Buffs entry = one prefab + resolver + active-instance tracker. branch
# isn't allowed in loops, so per-entry reconcilers spawn and individually race against
# ComponentCancel for shutdown.
passive_buff_entry<public> := class<concrete>:

    @editable
    BuffPrefab<public>:?concrete_subtype(buff_base) = false

    @editable
    var Resolver<public>:buff_target_resolver = while_equipped_resolver{}

    # Local-space offset applied after parenting.
    @editable
    var LocalOffset<public>:vector3 = vector3{}

    var<private> ActiveBuff<private>:?entity = false

    Reconcile<public>(Target:entity):void =
        if (Active := ActiveBuff?):
            ShouldKeep:logic = if (P := Active.GetParent[], P = Target) then true else false
            if (not ShouldKeep?):
                Active.RemoveFromParent()
                set ActiveBuff = false
        if (not ActiveBuff?, BP := BuffPrefab?):
            New := BP{}
            Target.AddEntities(array{New})
            New.SetLocalTransform(transform{
                Translation := LocalOffset,
                Rotation := IdentityRotation(),
                Scale := vector3{Forward := 1.0, Left := 1.0, Up := 1.0}
            })
            set ActiveBuff = option{New}

    Cleanup<public>():void =
        if (B := ActiveBuff?):
            B.RemoveFromParent()
            set ActiveBuff = false


passive_buff_component<public> := class<final_super>(component):

    @editable
    Buffs<public>:[]passive_buff_entry = array{}

    var<private> ComponentCancel<private>:event() = event(){}

    OnSimulate<override>()<suspends>:void =
        for (Entry : Buffs):
            spawn { ManageEntry(Entry) }
        Sleep(Inf)

    OnRemovingFromScene<override>():void =
        (super:)OnRemovingFromScene()
        ComponentCancel.Signal()
        for (Entry : Buffs):
            Entry.Cleanup()

    ManageEntry<private>(Entry:passive_buff_entry)<suspends>:void =
        race:
            ComponentCancel.Await()
            ReconcileLoop(Entry)

    ReconcileLoop<private>(Entry:passive_buff_entry)<suspends>:void =
        loop:
            if (Target := Entry.Resolver.GetTarget[Self]):
                Entry.Reconcile(Target)
            else:
                Entry.Cleanup()
            Entry.Resolver.AwaitNextChange(Self)
