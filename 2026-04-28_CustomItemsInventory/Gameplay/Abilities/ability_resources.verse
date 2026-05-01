using { /Verse.org/Simulation }


# Pluggable cost source for active abilities.
ability_resource<public> := class<abstract>:
    TryConsume<public>(Activator:agent, Amount:float):logic



ability_cost<public> := class:

    @editable
    Resource<public>:ability_resource

    @editable
    Amount<public>:float = 0.0

    TryConsume<public>(Activator:agent):logic =
        Resource.TryConsume(Activator, Amount)
