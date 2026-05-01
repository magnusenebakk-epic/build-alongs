using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }

using { Gameplay.Abilities }


raw_damage_applier<public> := class(damage_applier):
    Apply<override>(Source:?agent, Target:agent, Char:fort_character, BaseAmount:float, Instigator:?game_action_instigator):void =
        Char.Damage(damage_args{
            Amount     := BaseAmount,
            Instigator := Instigator
        })


pipeline_damage_applier<public> := class(damage_applier):
    Apply<override>(Source:?agent, Target:agent, Char:fort_character, BaseAmount:float, Instigator:?game_action_instigator):void =
        Payload := damage_payload{
            Amount := BaseAmount,
            Source := Source,
            Target := Target
        }
        RunOutgoing(Payload)
        Char.Damage(damage_args{
            Amount     := Payload.Amount,
            Instigator := Instigator
        })
        RunAfter(Payload)

    RunOutgoing<private>(Payload:damage_payload):void =
        if:
            S := Payload.Source?
            Holder := S.GetStatsHolderEntity[]
        then:
            if (Pipeline := Holder.GetComponent[damage_pipeline_component] or Holder.FindAncestorComponents(damage_pipeline_component).First[]):
                set Payload.Amount = Pipeline.OutgoingDamageCalc.Compute(Payload.Amount, Payload.Target, option{S})
            for (H : Holder.GetDescendantComponentsWithInterface(damage_dealing_handler)):
                H.OnDealingDamage(Payload)

    RunAfter<private>(Payload:damage_payload):void =
        if:
            S := Payload.Source?
            Holder := S.GetStatsHolderEntity[]
        then:
            for (H : Holder.GetDescendantComponentsWithInterface(after_damage_dealing_handler)):
                H.AfterDealingDamage(Payload)
