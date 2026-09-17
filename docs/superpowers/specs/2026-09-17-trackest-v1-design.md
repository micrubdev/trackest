# Trackest v1 — Design

Classic tracker (FastTracker/Renoise-style pattern grid) for Android, built in Flutter,
with playback and synthesis provided by an embedded Csound engine.

## Scope (v1)

In: one pattern (64 rows × 4 channels), play/stop looping that pattern, cell editing
(note / instrument / volume), 4 instrument templates with knob-editable parameters,
live parameter changes while playing.

Out (later): song arrangement, effect commands, save/load, WAV export, more patterns.

## Decisions

- Paradigm: classic vertical tracker grid.
- Platform: Android (arm64-v8a first). Engine interface is platform-neutral so a
  Linux desktop build can follow.
- Instruments: preset templates + macro knobs; Csound source hidden.
- Csound: official prebuilt Csound for Android (`libcsoundandroid.so`), bound via
  `dart:ffi`. Fallback if pure FFI produces no audio: thin Kotlin platform channel
  over the official `CsoundObj`; only the two lowest layers change.
- Clock: **Csound is the clock**. Pattern data lives in Csound f-tables; a Csound
  sequencer instrument fires notes sample-accurately. Dart only writes tables and
  control channels and reads the current row back.

## 1. Data model (Dart)

```
Project     { name, bpm, linesPerBeat, pattern, instruments[16] }
Pattern     { rows=64, channels=4, cells: List<Cell> (row-major) }
Cell        { note: int, instrument: int, volume: int }   // immutable
Instrument  { id 0..15, name, template, params: Map<String,double> }
Template    { subtractive | fm | sampler | noise }
```

Encodings: `note` = MIDI 0..119, `-1` empty, `-2` note-off. `instrument` `-1` = keep
last used on that channel. `volume` 0..64, `-1` = instrument default.

State: `ProjectNotifier` (Riverpod `Notifier<Project>`) is the single source of
truth. Every mutation returns a new value and forwards the change to the engine
(`setCell`, `setParam`, `setBpm`).

## 2. Csound orchestra

- `sr=44100, ksmps=32, nchnls=2, 0dbfs=1`.
- Tables `giNote`, `giInst`, `giVol`: size `rows*channels`, index `row*channels+ch`,
  initialised to -1.
- Control channels: `bpm`, `lpb`, `playing` (0/1), `row` (out), and
  `i<id>.<param>` per instrument parameter.
- `instr 1` (sequencer, started at time 0, infinite): each k-cycle computes
  `kRowRate = bpm/60*lpb`; `kTick metro kRowRate`. When `playing==1` and `kTick==1`:
  for each channel read the cell; `note>=0` → `turnoff2` the channel's current voice
  then `event "i", 10+inst+ch/10 …` with p4 note, p5 vol; `note==-2` → `turnoff2`
  only. Then `chnset kRow,"row"` and `kRow = (kRow+1) % rows`. When `playing` goes
  1→0, `kRow=0` and all voices are released.
- `instr 10..25`: one per instrument slot; body chosen by the slot's template.
  Parameters read with `chnget` every k-cycle so knob changes are audible immediately.
  Fractional instr number `10+id+ch/10` makes voices per-channel addressable.
- Templates (v1 parameter set):
  - subtractive: `wave` (saw/square), `cutoff`, `res`, `attack`, `decay`, `sustain`,
    `release`
  - fm: `ratio`, `index`, `attack`, `decay`, `sustain`, `release`
  - sampler: bundled asset wav, `pitch`, `attack`, `release` (one drum sample in v1)
  - noise: `cutoff`, `decay`

The full orchestra is generated once from the project's instrument list by
`OrchestraBuilder` (pure Dart, unit-tested) and compiled at engine start. Changing a
slot's *template* recompiles; changing a *parameter* is a channel write.

## 3. Engine / FFI layer

1. `csound_bindings.dart` — `dart:ffi` symbol lookups only (`csoundCreate`,
   `csoundSetOption`, `csoundCompileOrc`, `csoundStart`, `csoundPerformKsmps`,
   `csoundTableSet`, `csoundSetControlChannel`, `csoundGetControlChannel`,
   `csoundStop`, `csoundDestroy`, `csoundGetMessageCnt/FirstMessage` for errors).
2. `csound_isolate.dart` — one Isolate owns the instance; loop
   `while (!stop && performKsmps()==0)`; drains a command port between calls;
   posts `row` to the main isolate every ~30 ms when it changes.
3. `engine.dart` — abstract `Engine` (`start(orc)`, `setCell`, `setParam`,
   `setBpm`, `play`, `stop`, `Stream<int> row`, `dispose`). `CsoundEngine`
   implements it; `FakeEngine` records calls for widget tests and desktop runs.

Errors: compile failure → `start` throws `EngineException(csoundMessages)`;
perform loop exits unexpectedly → `Engine.state` becomes `stopped` and the UI shows
a snackbar.

## 4. UI (Flutter)

Single screen, three regions:

- **Transport bar** (top): Play/Stop toggle, BPM stepper, current instrument
  selector (0–15), octave stepper.
- **Pattern grid** (centre): 64 rows × 4 channels, each cell `C-4 01 40` in
  monospace. Custom `CustomPainter` in a vertically scrolling viewport (rows are
  fixed-height, so paint only visible rows). Cursor = tapped cell; current playback
  row highlighted; grid auto-scrolls to keep playback row visible while playing.
- **Input pad** (bottom): two-octave piano keys + `OFF` + `DEL` keys. Pressing a key
  writes `(note, currentInstrument, -1)` into the cursor cell and advances the
  cursor by `editStep` (default 1). Long-press a cell opens a volume slider.
- **Instrument sheet**: swipe-up/bottom-sheet showing the selected slot's template
  dropdown and one slider per parameter. Slider changes call `setParam` live.

## 5. Testing

- Pure Dart unit tests: `Pattern`/`Cell` encoding, `ProjectNotifier` edits,
  `OrchestraBuilder` output (golden orchestra strings per template, table sizes,
  channel names).
- Engine contract tests run against `FakeEngine` to verify the notifier forwards the
  right calls.
- Widget tests: entering notes via the pad moves the cursor and updates the grid
  text; play toggles transport state.
- On-device manual check (the only place audio is verified): spike APK plays a sine;
  v1 APK plays an entered pattern and reacts to knob changes.

## 6. Build constraints

Development host is aarch64 Linux (proot) with no root and no Android Studio.
Android SDK is installed user-space using aarch64 builds of platform-tools and
build-tools (Lzhiyong android-sdk-tools), Gradle via the wrapper, Java 21 from the
host. `android.aapt2FromMavenOverride` points at the aarch64 `aapt2`. Output:
`build/app/outputs/flutter-apk/app-release.apk` (arm64-v8a only).
