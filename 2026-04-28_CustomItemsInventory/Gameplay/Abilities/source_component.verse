using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }


# Records the agent that "owns" a spawned entity
source_component<public> := class<final_super>(component):

    var Source<public>:?agent = false
