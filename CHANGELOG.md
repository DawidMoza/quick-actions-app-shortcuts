# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-08-03

Initial public release.

### Added

- Editor export plugin for Godot **4.7+** (no runtime GDScript / scene node required)
- Static **Send feedback** home-screen shortcut on Android (App Shortcuts) and iOS (Quick Actions)
- Config file `res://quick_actions_app_shortcuts.cfg` (recipient, title, icon, subject/body templates)
- Locale overlays via `[feedback.<locale>]` sections
- Android trampoline activity that opens `mailto:` without starting Godot
- iOS native handler that opens Mail from cold and warm quick actions
- Demo project with runnable Android and iOS export presets
- GitHub Actions release workflow that builds AAR + xcframework zip on `v*` tags

[Unreleased]: https://github.com/DawidMoza/quick-actions-app-shortcuts/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/DawidMoza/quick-actions-app-shortcuts/releases/tag/v0.1.0
