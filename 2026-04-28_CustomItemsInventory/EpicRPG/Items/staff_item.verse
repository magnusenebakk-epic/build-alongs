using { /UnrealEngine.com/Itemization }
using { /Verse.org/SceneGraph }
using { /Verse.org/Colors }


MagicRarity<public> : rarity = rarity:
    Color<override> := color{R := 0.984, G := 0.168, B := 0.921}

staff_item_component<public> := class<final_super>(item_component){}