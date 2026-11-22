# Changelog

All notable changes to this project are documented in this file.

## 2026-11-22

- Commit: Added backend Docker/Kiri, .NET integration E2E, Flutter Linux E2E, and CI jobs.
  - Flutter integration_test on Linux, app CI E2E step, and refreshed linux host for desktop tests.
- Commit: Use material_ui in integration_test to fix Flutter analyze deprecation.
  - Replaced legacy material.dart imports in integration tests for current Flutter stable analyze.

## 2026-11-14

- Commit: Updated toolchain to Dart SDK ^3.14.0, Gradle 9.5.0, Android Gradle Plugin 9.3.1 and Kotlin 2.4.20.
  - Migrated Material imports to material_ui and upgraded dependencies to their latest major versions.

## 2026-11-07

- Commit: Added url_launcher and a GitHub button to the About dialog.
  - Added the url_launcher ^6.3.3 dependency and a GitHub button inside the About dialog that opens https://github.com/william-franco.

## 2026-11-01

- Commit: Updated Dart SDK to ^3.13.7 and documented Gradle 9.3.1.
  - Aligned the Dart SDK constraint with the test_version reference and updated the README stack table with the Gradle version.

## 2026-10-10

- Commit: Updated Flutter SDK and dependencies.
  - Refreshed dependency versions and related build configuration to keep the project current.

## 2026-09-27

- Commit: Updated project documentation.
  - Improved the project documentation and clarified how the project is used or maintained.

## 2026-09-26

- Commit: Renamed the application folder to taskle-app and updated the README and CI configuration.
  - Improved the project documentation and clarified how the project is used or maintained.
- Commit: Added the Taskle full-stack implementation with an /api/v1 API, CORS support, and aligned user experience.
  - Expanded the application capabilities across its frontend and backend layers and aligned the related integration points.
- Commit: Updated the project architecture.
  - Refined the project structure and responsibilities to improve maintainability and extensibility.

## 2021-07-28

- Commit: Initial commit.
  - Established the initial project structure and baseline implementation.
