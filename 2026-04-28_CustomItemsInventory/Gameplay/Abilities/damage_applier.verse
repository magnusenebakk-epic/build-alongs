using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }


damage_applier<public> := class<abstract>:
    Apply<public>(Source:?agent, Target:agent, Char:fort_character, BaseAmount:float, Instigator:?game_action_instigator):void
