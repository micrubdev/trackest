# Trackest

Classic tracker (64 rows × 4 channels) for Android with an embedded Csound synth.

- Spec: `docs/superpowers/specs/2026-09-17-trackest-v1-design.md`
- Plan: `docs/superpowers/plans/2026-09-17-trackest-v1.md`

## Build

`flutter build apk --release --target-platform android-arm64` → `build/app/outputs/flutter-apk/app-release.apk`.

Tests: `flutter test`. Host-side orchestra check: dump `OrchestraBuilder.build(...)` to a file and run `csound --syntax-check-only`.

## Layout

- `lib/model` — immutable Project / Pattern / Cell / Instrument
- `lib/engine` — `OrchestraBuilder` (Csound orc text), `CsoundBindings` (dart:ffi), `CsoundEngine` / `FakeEngine`
- `lib/state` — Riverpod `ProjectNotifier`, mirrors every edit into the engine
- `lib/ui` — transport bar, pattern grid, note pad, instrument sheet
- `android/app/src/main/jniLibs/arm64-v8a` — Csound 6.18.0 Android libs

## Audio path

Csound runs in non-async OpenSL mode: the OpenSL callback thread drives `csoundPerformBuffer`; Dart only writes f-tables / control channels and polls the `row` channel. If a device is silent, the fallback is async mode (`newAndroidCsound(async: true)` plus a `performKsmps` loop in an isolate).
