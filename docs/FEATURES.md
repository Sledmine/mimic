# Mimic Passive Features

Mimic includes a set of passive features that expand the game functionality in a standard way that
all maps can get advantages from. These features are designed to be simple to use and integrate
into any map, providing a consistent experience across different environments almost as if it was
part of the base game engine.

**NOTE:** Most of these features rely on tags having paths legible by the engine, such as `characters/cyborg/cyborg.biped`.
If the tag paths are obfuscated, Mimic will not be able to find the tags and swap the elements.

## Features

- FP Swapping based on current player biped
- HUD elements swapping based on current player biped

### FP Swapping

This feature allows the first person view models to swap based on the current player biped.

For example, it will look for `characters/cyborg/fp/fp.gbxmodel` as the first person model, and if it exists, it will be used instead of the default one.

Here is the list of tags list that Mimic will look for and which tag element will be swapped with:

| Tag Path Suffix  | Swapped Element                                            | Description        |
|------------------|------------------------------------------------------------|--------------------|
| `fp/fp.gbxmodel` | globals["first_person_interface"][0]["first_person_hands"] | First Person Model |


### HUD Elements Swapping

This feature allows the HUD elements to be swapped based on the current player biped.

For example, if player currently has biped `characters/cyborg/cyborg_mp.biped` and referenced
HUD interface targets to `characters/cyborg/hud/unit.unit_hud_interface` Mimimc will look for HUD
elements relative to this HUD interface, and if those exists, they will be used instead of the
default ones.

This allows map makers to create custom HUD elements for different bipeds that are not normally able
to change at playtime as these are globally shared regardless of the current biped by default,
without the need to create custom scripts or events for each biped and HUD element, making it easier
to create maps with a variety of bipeds and custom HUD elements as well as resharing HUD elements.

Here is the list of tags list that Mimic will look for and which tag element will be swapped with:

| Tag Path Suffix                                  | Swapped Element                                                    | Description                  |
|--------------------------------------------------|--------------------------------------------------------------------|------------------------------|
| `hud/unit.unit_hud_interface`                    | <biped_tag>["unit_hud_interface"]                                  | Unit HUD Interface           |
| `hud/frag.grenade_hud_interface`                 | globals["grenades"][0]["grenade_hud_interface"]                    | Grenade HUD Interface        |
| `hud/plasma.grenade_hud_interface`               | globals["grenades"][1]["grenade_hud_interface"]                    | Plasma Grenade HUD Interface |
| `hud/globals.hud_globals`                        | globals["interface_bitmaps"][0]["hud_globals"]                     | HUD Globals                  |
| `hud/digits.hud_number`                          | globals["interface_bitmaps"][0]["hud_digits_definition"]           | HUD Numbers                  |
| `hud/sensor_sweep.bitmap`                        | globals["interface_bitmaps"][0]["motion_sensor_sweep_bitmap"]      | HUD Sensor Sweep Bitmap      |
| `hud/sensor_sweep_mask.bitmap`                   | globals["interface_bitmaps"][0]["motion_sensor_sweep_bitmap_mask"] | HUD Sensor Mask Bitmap       |
| `hud/sensor_blip.bitmap`                         | globals["interface_bitmaps"][0]["motion_sensor_blip_bitmap"]       | HUD Sensor Blip Bitmap       |
| `hud/multiplayer.bitmap`                         | globals["interface_bitmaps"][0]["multiplayer_hud_bitmap"]          | HUD Ally Multiplayer Bitmap  |
| `hud/weapons/<weapon_name>.weapon_hud_interface` | <weapon_tag>["weapon_hud_interface"]                               | Weapon HUD Interface         |
| `hud/weapons/empty.weapon_hud_interface`         | hud_globals["hud_globals"]["default_weapon_hud"]                   | Empty Weapon HUD Interface   |

TODO SWAP HUD GLOBALS:
- Damage Indicator
- Navpoints
- Message Colors
- Icons (?)
- Icons Colors
- HUD Help Text Colors
- Timer Colors

### Items Sync Override

When an item is spawned on the server, it will be assigned a "collection delay" time, during which the item will exist for the players, but the server will not consider it as "collectable" until this time has passed, if no interaction from the player has happened to it, the server will collect the item and delete it. This affects both items placed in the map dynamically and items dropped by the AI or even players.

Usuallly this is not a problem for normal multiplayer maps as these use the "item collection" system, meant to spawn and control the time of life of
items in the map, but singleplayer-like maps (such as Coop Evolved) that rely on the same way the singleplayer campaign creates objects and
expects them to exist there for an almost infinite time, can lead to problems with items disappearing too early, as the server collects them after the "collection delay" time has passed. This affects the play experience in these cases erasing key items for the playthrough or balance.

This feature allows to override the network control of "usable" items such as weapons and equipment, making them similar to how singleplayer works, but adding a more flexible and complex "collection" logic to allow players to interact with these items without worrying about server collecting these too early after spawning them.

It considers aspects such as:

- Maximum item budget count is exceeded (item will only be deleted if there is no player nearby, otherwise items will attempt to keep existing until a stronger criteria from below is met)
- Is item still inside the playable bsp area, erasing those outside of the current bsp
- Weapon current ammo, if it is empty, will be deleted (only works with "bullet" based weapons as of now)

This feature also includes a beta functionality to implement a custom item spawning system that makes the scenario defined
weapons block usable, allowing for singleplayer-like weapon placements work in multiplayer maps, but this is still in early testing and may be too
aggressive in creating items, by now it prioritizes spawning items near to the player to ensure they do not run out of ammo through their play session if they are nearby to the item spawn point. This still needs tweaking and can lead to item duplication if the previous item still exists when
a player gets close enough without us realizing there is still the same item existing there already.

**NOTE:** This items feature also applies to items dropped by the AI or players, it will only be passively enabled if Mimic detects there are any AI encounter in the scenario, otherwise it will be disabled to avoid interfering with weapon placements in normal multiplayer oriented maps.

