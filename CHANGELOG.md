# Changelog

All notable changes to ExeRoam will be documented in this file.

The project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned

- Add applications from the tray menu with duplicate-path detection.

## [0.2.9] - 2026-07-17

### Added

- Tray actions to add ExeRoam to Windows Startup and show application details.

### Changed

- The launcher now starts without a version label when `VERSION` is missing.

## [0.2.2] - 2026-07-16

### Added

- Optional launcher centering on the monitor containing the mouse pointer.
- Non-intrusive shortcuts window available from the footer or with F1.
- Adjusted grid column widths for better readability.

## [0.1.0] - 2026-07-15

### Added

- Portable executable discovery across configurable roots.
- Search, favourites, usage history, elevation, and path validation.
- Portable `{ROOTn}` and `{SCRIPT}` path placeholders.
- AutoHotkey v2 x64 compilation support.

### Changed

- Standardized the project name as ExeRoam.
- Renamed the configuration file to `exeroam.ini`.
- Added semantic version display using the `VERSION` file.
