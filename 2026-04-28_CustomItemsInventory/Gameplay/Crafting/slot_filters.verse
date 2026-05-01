using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
using { /UnrealEngine.com/Itemization }


slot_filter<public> := class<abstract>:
    Accepts<public>(Item:entity)<transacts><decides>:void


tag_slot_filter<public> := class<concrete>(slot_filter):

    @editable
    Tag<public>:subtype(tag) = crafting_resource

    Accepts<override>(Item:entity)<transacts><decides>:void =
        Item.ContainsTag[Tag]


class_slot_filter<public> := class<concrete>(slot_filter):

    @editable
    ItemType<public>:subtype(item_component) = item_component

    Accepts<override>(Item:entity)<transacts><decides>:void =
        Item.GetComponent[ItemType]


# AND-composes children
composite_slot_filter<public> := class<concrete>(slot_filter):

    @editable
    Filters<public>:[]slot_filter = array{}

    Accepts<override>(Item:entity)<transacts><decides>:void =
        for (F : Filters) { F.Accepts[Item] }
