# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.0.0] - 2025-12-09
### Added
- Add support for syncing HSC functions and events with new transpiler event layer
- Add HSC transpiler script and hs thread module bridge for scripting integration support (more of a dev feature, check README for more info)

### Fixed
- Incremental Memory leak when syncing large number of bipeds over time
- Units will now sync animation tag handle as well as animation index, preventing wrong animations being played on client side
- Bipeds considered as dead will no longer enter a seizure state and loop animations, still can not fake dead, will stay dead until garbage collected

### Changed
- Vehicle parent object handle is not synced anymore, due to game not being able to dettach parent objects in multiplayer games, will fix later

## [3.0.6] - 2024-06-18
### Fixed
- Most recent damager player value being modified following an old coop evolved logic
- Server side sending information to sync vehicles entering other vehicles (will be properly fixed later)

## [3.0.5] - 2024-03-15
### Fixed
- Dedicated server logic being executed in single player mode
- Revert experimental network timeout patch (now fixed with Balltze)

### Changed
- Improved game cinematic detection

## [3.0.4] - 2024-02-02
### Fixed
- Server side projectiles being always synced to the client, now sync will be toggled on if any AI encounter is detected in the scenario

## [3.0.3] - 2023-12-06
### Fixed
- Performance drop when syncing bipeds that are not inside current bsp in client side

### Changed
- New command `mimic_collision` to enable or disable biped collision (for testing purposes only)
- Lua function `tonumber` is now memoized in client for better performance (experimental)

## [3.0.2] - 2023-12-06
### Fixed
- Unnecessary debug messages being printed regardless of debug mode

## [3.0.1] - 2023-12-06
### Fixed
- Debug mode was not disabled by default

## [3.0.0] - 2023-12-03
### Changed
- Sync messages use a different identifier for better classification (breaking change)
- AI and units in general can now enter other vehicles
- Support for syncing biped weapons (raw implementation)
- Unit properties such as color, invisibility, permutations and more are now synced
- Support to sync vehicles that are driven by AI (raw implementation)

### Fixed
- Sync performance has been improved by a lot
- Memory leak that will reduce performance as AI bipeds appear

## [2.1.5] - 2022-09-28
### Added
- Mimic version printing on the server script
### Fixed
- Local AI bipeds not being erased while syncing
- Error message about not being able to find a FP tag for Coop Evolved in other maps

## [2.1.4] - 2022-09-23
### Changed
- Sync now takes player perspective to determine which bipeds should be updated, improving performance
- Biped clean up and collection time for client and server side, improves stability
### Fixed
- Sync issues with some bipeds faking dead like floods
- Packets being sent unnecessary often to the player when a biped dies on the server side

## [2.1.3] - 0000-00-00
### Changed
- Fix debug messages appearing when they should not

## [2.1.2] - 0000-00-00
### Changed
- Add intro camera for Coop Evolved d40
- Fix some coop evolved maps not displaying an intro camera for biped selection
- Fix some cinematics and events not syncing correctly due to missing command escaping

## [2.1.1] - 0000-00-00
### Changed
- Fix for player respawn when outside bsp

## [2.1.0] - 0000-00-00
### Changed
- Add support for special migrated AI bipeds on a50
- Use client bipeds when possible based on biped server coordinates
- Add better AI state detection, split biped update and biped death functions

## [2.0.0] - 0000-00-00
### Changed
- Add first person swap and extra features for Coop Evolved
- Multiple stability fixes
- Add color and invisibility support for bipeds
- Performance improvements
- Add device machines state synchronization
- Add device machines power synchronization

# [1.0.2] - 0000-00-00
### Changed
- Fix cinematic issues by allowing the camera to see any object animation
- Add feature flag to turn on and on off biped collision