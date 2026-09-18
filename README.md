# Trackest

Classic tracker (64 rows × 4 channels) for Android with an embedded Csound synth.

- Spec: `docs/superpowers/specs/2026-09-17-trackest-v1-design.md`
- Plan: `docs/superpowers/plans/2026-09-17-trackest-v1.md`

## Build

`flutter build apk --release --target-platform android-arm64` → `build/app/outputs/flutter-apk/app-release.apk`.

Tests: `flutter test`. Host-side orchestra check: dump `OrchestraBuilder.build(...)` to a file and run `csound --syntax-check-only`.

### Building on an arm64 Linux host (Termux / proot on the phone itself)

Google ships no linux-arm64 host build of `gen_snapshot` (the Dart AOT compiler) or of the NDK, so a release build on this host needs these one-time workarounds (a `--debug` build needs none of them, since it does not use `gen_snapshot`):

1. **Android SDK** at `~/android-sdk`: platform-35 and build-tools 35.0.0 with the native tools (`aapt2`, `zipalign`, `aidl`, …) swapped for aarch64 builds from [lzhiyong/android-sdk-tools](https://github.com/lzhiyong/android-sdk-tools). `android/gradle.properties` points `android.aapt2FromMavenOverride` at that `aapt2`; adjust the path for your machine.
2. **JDK**: `flutter config --jdk-dir <path to an arm64 JDK 21>`.
3. **gen_snapshot via qemu**. The official `android-arm64-release/linux-x64/gen_snapshot` (an x86-64 binary that targets Android arm64) is run under user-mode emulation. Without root, extract the Debian packages into your home dir:

   ```sh
   mkdir -p ~/x64tools/sysroot
   dpkg-deb -x qemu-user_<ver>_arm64.deb ~/x64tools/qemu        # static qemu-x86_64
   dpkg-deb -x libc6_<ver>_amd64.deb   ~/x64tools/sysroot       # amd64 glibc
   ln -s usr/lib64 ~/x64tools/sysroot/lib64; ln -s usr/lib ~/x64tools/sysroot/lib
   ```

   Then replace `$FLUTTER/bin/cache/artifacts/engine/android-arm64-release/linux-arm64/gen_snapshot` with:

   ```sh
   #!/bin/sh
   exec ~/x64tools/qemu/usr/bin/qemu-x86_64 -L ~/x64tools/sysroot \
     "$(dirname "$0")/../linux-x64/gen_snapshot" "$@"
   ```

   Do **not** substitute the host Dart SDK's `gen_snapshot`: it emits a snapshot tagged `arm64 linux no-compressed-pointers`, the Android engine requires `arm64 android compressed-pointers`, and the app aborts at launch. Verify a build with `unzip -p app-release.apk lib/arm64-v8a/libapp.so | strings | grep 'arm64 android'`. The emulated AOT step takes ~10 minutes; after changing `gen_snapshot`, `rm -rf .dart_tool/flutter_build` or the cached `libapp.so` is reused.
4. **No NDK**: comment out `forceNdkDownload(...)` in `$FLUTTER/packages/flutter_tools/gradle/src/main/kotlin/FlutterPlugin.kt`, and give AGP a stub at `~/android-sdk/ndk/26.3.11579264/` containing `source.properties` plus `toolchains/llvm/prebuilt/linux-x86_64/bin/{llvm-strip,llvm-objcopy}` symlinked to the host's LLVM tools.

`flutter upgrade` wipes the engine cache and the tools patch, so steps 3 and 4 must be redone afterwards.

## Layout

- `lib/model` — immutable Project / Pattern / Cell / Instrument
- `lib/engine` — `OrchestraBuilder` (Csound orc text), `CsoundBindings` (dart:ffi), `CsoundEngine` / `FakeEngine`
- `lib/state` — Riverpod `ProjectNotifier`, mirrors every edit into the engine
- `lib/ui` — transport bar, pattern grid, note pad, instrument sheet
- `android/app/src/main/jniLibs/arm64-v8a` — Csound 6.18.0 Android libs

## Audio path

Csound runs in non-async OpenSL mode: the OpenSL callback thread drives `csoundPerformBuffer`; Dart only writes f-tables / control channels and polls the `row` channel. If a device is silent, the fallback is async mode (`newAndroidCsound(async: true)` plus a `performKsmps` loop in an isolate).
