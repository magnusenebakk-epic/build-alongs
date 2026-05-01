using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }


# Threaded through handler stages; handlers mutate Amount.
damage_payload<public> := class:
    var Amount<public>:float = 0.0
    Source<public>:?agent
    Target<public>:agent


damage_dealing_handler<public> := interface<castable>(p_interface):
    OnDealingDamage<public>(Payload:damage_payload):void


after_damage_dealing_handler<public> := interface<castable>(p_interface):
    AfterDealingDamage<public>(Payload:damage_payload):void


damage_taking_handler<public> := interface<castable>(p_interface):
    OnTakingDamage<public>(Payload:damage_payload):void


after_damage_taking_handler<public> := interface<castable>(p_interface):
    AfterTakingDamage<public>(Payload:damage_payload):void
