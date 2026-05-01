using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Itemization }

# Strategy for "what entity goes into inventory on pickup"
pickup_target_provider<public> := class<abstract>:
    ProvideTarget<public>(InteractComponent:item_pickup_interactable_component):entity
    AfterPickup<public>(InteractComponent:item_pickup_interactable_component):void = {}


# Single-entity pickup: AddItemDistribute moves the entity itself, no cleanup needed.
direct_pickup_target_provider<public> := class<concrete>(pickup_target_provider):

    @editable
    Target<public>:?entity = false

    ProvideTarget<override>(InteractComponent:item_pickup_interactable_component):entity =
        Target? or InteractComponent.Entity


# Two-prefab pickup: spawn a ItemPrefab for the inventory, remove the world entity.
prefab_pickup_target_provider<public> := class<concrete>(pickup_target_provider):

    @editable
    ItemPrefab<public>:concrete_subtype(entity) = entity

    @editable
    WorldEntity<public>:?entity = false

    ProvideTarget<override>(InteractComponent:item_pickup_interactable_component):entity =
        ItemPrefab{}

    AfterPickup<override>(InteractComponent:item_pickup_interactable_component):void =
        Target := WorldEntity? or InteractComponent.Entity
        Target.RemoveFromParent()
