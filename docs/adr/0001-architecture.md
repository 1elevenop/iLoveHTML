# ADR 0001: Modular monolith with a shared Dart core

Status: accepted (2026-10-21)

## Context

The converter ships on Windows and Android from one codebase, compiles user
apps locally, and must keep the project system independent of how each
platform builds. The Flutter UI and the generated Android app are separate
products with separate build processes.

## Decision

```
android_template/            Native Kotlin WebView wrapper (Gradle project). Maintained, versioned.
packages/html2apk_core/      Pure Dart, no Flutter dependency. Unit-tested with `dart test`.
  project_core/              Manifest model, schema migration, validation, ProjectStore
  project_importer/          Safe ZIP extraction, entry discovery, missing-asset scan
  security/                  Path normalization, URL policy (private-network block)
  android_generator/         Template copy + structured file generation
  build_orchestrator/        AndroidBuildAdapter interface, Gradle adapter, toolchain
                             discovery, artifact inspection, log redaction
  bin/html2apk.dart          CLI driver used for the Phase 1 end-to-end test
app/ (next milestone)        Flutter UI for Windows + Android, depends on html2apk_core
```

Remaining modules from the product plan (template_library, web_preview,
app_configuration UI, signing_manager, SQLite metadata) are added inside
this structure in later phases.

Key rules:

- **Generation without text substitution.** Kotlin sources and Gradle scripts
  are copied unchanged. Per-project data is written as complete files:
  `AndroidManifest.xml` (built in code with XML escaping), `app_strings.xml`
  (aapt2 escaping), `assets/app_config.json` (read by the Kotlin runtime),
  `wrapper.properties` (applicationId/version, read by `app/build.gradle.kts`),
  `local.properties`.
- **Fixed namespace, variable applicationId.** Kotlin code lives in
  `com.html2apk.runtime`; the user's package ID is only the applicationId.
- **Runtime features are configuration, not code.** Every WebView feature
  is compiled into the wrapper and toggled by `app_config.json`. This keeps
  generated projects free of user code and is what makes the Android
  on-device engine (ADR 0002) possible.
- **Build engines behind `AndroidBuildAdapter`.** Windows uses
  `GradleProcessBuildAdapter` (runs the pinned Gradle wrapper as a child
  process). The Android engine implements the same interface.
- **Projects are plain directories** (`project.json`, `source/`,
  `branding/`, `exports/`) and portable: imported paths are normalized to
  POSIX and names invalid on Windows are rejected.
- **No signing secrets in `project.json`**, ever. Signing (Phase 3) will use
  OS-protected storage.

## Consequences

- Core logic is testable without Flutter, a device, or Windows desktop
  tooling.
- Adding a WebView feature means changing the template and the config
  schema together; `app_config.json` carries its own `schemaVersion`.
