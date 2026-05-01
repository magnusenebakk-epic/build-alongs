using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }

# Filters which items can be placed on the host entity by tag..
tag_acceptor_component<public> := class<final_super>(component):

    @editable
    var AcceptedTags<public>:[]subtype(tag) = array{}
