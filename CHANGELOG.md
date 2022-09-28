# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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