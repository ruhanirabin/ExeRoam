# Changelog

All notable changes to ExeRoam will be documented in this file.

The project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned

- Add applications from the tray menu with duplicate-path detection.

## [0.3.1] - 2026-07-19

### Fixed

- Arrow-key navigation no longer returns to the first application after focus moves from search to the application list.

## [0.3.0] - 2026-07-19

### Added

- Tray actions to add ExeRoam to Windows Startup and show application details.

### Changed

- The launcher now starts with version reading from .exe file metadata.
- Compiler directives are now added to the source file before compilation.

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
