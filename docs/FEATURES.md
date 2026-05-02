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
