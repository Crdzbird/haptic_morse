# 2.0.0

A breaking release. **1.x haptic patterns were played inverted**, and fixing
that required changing the output. See *Migrating* in the README for a table of
every renamed member.

### Fixed

- **Haptic patterns are no longer phase-inverted.** `package:vibration` treats
  index 0 of `pattern` as an *off* delay and alternates off/on from there — the
  convention shared by Android's `VibrationEffect.createWaveform` and the iOS
  implementation. 1.x emitted a vibration at index 0, so every dot and dash was
  played as silence and every gap as a buzz. `toVibrationPattern()` now emits
  the leading `0`.
- **Sequences are well formed at every boundary.** Leading whitespace no longer
  emits a spurious word gap, a trailing unsupported character no longer emits a
  dangling letter gap, and consecutive spaces no longer emit adjacent gaps
  (which inverted the phase of everything after them). A word made entirely of
  unmapped characters no longer produces a second word gap. Gaps are now
  emitted only *between* two elements that both exist, so none of these can
  recur.
- **Characters outside the Basic Multilingual Plane work.** Text is segmented
  into grapheme clusters, so emoji built from surrogate pairs, variation
  selectors, or zero-width joiners count as one character. Previously `💧` was
  split into two surrogate halves and resolved as two separate letters.
- **The core no longer depends on Flutter.** `package:haptic_morse/haptic_morse.dart`
  is pure Dart and runs under `dart run` and `dart test`; 1.x pulled in
  `dart:ui` through the barrel, so even the shipped example could not run.

### Added

- `HapticEvent`, a sealed type with `HapticDot`, `HapticDash`,
  `HapticSymbolGap`, `HapticLetterGap`, and `HapticWordGap`. Each carries a
  `duration`, an `isVibration` phase, value equality, and JSON support, so a
  sequence can be rendered or analysed instead of being an opaque `List<int>`.
- `List<HapticEvent>.toVibrationPattern()` and `.totalDuration`.
- `HapticVibration.vibrateText` and `.vibrateEvents`, which connect encoding to
  playback. Nothing in 1.x linked the two halves, so the inversion bug shipped
  silently.
- `dashReference`, alongside `symbolReference`, so custom patterns are
  unambiguous and can be validated.
- `String.toVibrationPattern()`.
- Argument validation on `HapticMorse.custom` — see *Changed*.
- `HapticVibration.hasVibrator`, `.hasCustomVibrationsSupport`, and
  `.hasAmplitudeControl`, so an app can fall back to showing the Morse code on
  a device that cannot reproduce the timing. Nothing in 1.x exposed a
  capability check, so a haptic-only message was simply unreadable there.
- **Punctuation in the default table.** `. , : ? ' - / ( ) " = + @` from
  ITU-R M.1677-1, plus the conventional `& ! ; _ $`. These were previously
  skipped as unmapped characters.
- **`HapticMorse.accentedLetters`**, an opt-in map of À Å Ä Ç È É Ñ Ö Ü for the
  new `additionalSymbols` argument. Kept opt-in because they are regional
  convention rather than ITU-normative.
- **`additionalSymbols`** on `HapticMorse.custom` and `HapticMorse.atSpeed`,
  merging extra character-to-pattern entries on top of the resolved table.
- **Decoding: `decodeMorseString` and `decodeEvents`.** `decodeEvents` needs no
  threshold guessing, since the events are already typed — symbol and word
  boundaries are exact.
- **`HapticMorse.atSpeed`**, expressing timing in words per minute
  (`unit = 1200 / wpm`), with **Farnsworth timing** via
  `effectiveWordsPerMinute`: symbols keep their character-speed shape while the
  letter and word gaps stretch, which is what makes Morse readable through skin
  without distorting each character.
- `supportedCharacters`, listing everything an encoder can represent.
- A conformance suite checking the output against ITU-R M.1677-1: the
  1/3/1/3/7 unit ratios, the standard `PARIS` word measuring exactly 50 units,
  the `1200/dot` words-per-minute formula, the full ITU code table, and an
  encode/decode round trip using an independent table.

### Changed

- **Library split.** `HapticVibration` moved to
  `package:haptic_morse/haptic_morse_vibration.dart`. `package:vibration` is no
  longer re-exported, so its releases are no longer implicitly breaking changes
  for this package.
- **Renames:** `convertTextToHapticPattern` → `convertTextToHapticEvents`,
  `convertTextToMorseMap` → `convertTextToModel`, `String.toMorseMap` →
  `toMorseModel`, `String.toHapticPattern` → `toHapticEvents`.
- `HapticModel.hapticDurations` is replaced by `events`, with
  `toVibrationPattern()` and `totalDuration` alongside it. The JSON shape
  changed accordingly: `hapticDurations: [100, 300]` becomes
  `events: [{"type": "dot", "duration": 100}, ...]`.
- **`HapticMorse()` is now parameterless** and `const`; it is always valid, so
  it needs no validation. All customization moved to `HapticMorse.custom`,
  which throws `ArgumentError` when a map and its reference differ in length, a
  reference repeats a character, a pattern is empty or uses characters other
  than the configured dot and dash, or a duration is not positive. 1.x accepted
  all of these and silently dropped letters from the output.
- Choosing custom dot/dash symbols now re-spells whichever built-in map you did
  not override, so `HapticMorse.custom(symbolReference: '0')` keeps the
  standard alphabet rather than rejecting it.
- **The string extensions take an optional `HapticMorse`** instead of repeating
  eleven parameters on each method:
  `'SOS'.toMorseString(HapticMorse.custom(dotDuration: 80))`.
- `convertTextToMorseString` returns `null` — not `''` — when the input holds
  no mappable characters, making its contract consistent.
- Character lookup uses a map built once at construction rather than scanning
  reference strings per character.
- Added `characters` as a dependency.
- CI runs the core test suite on the plain Dart SDK
  (`dart test --exclude-tags flutter`), which fails if anything in the core
  starts importing Flutter.
- Supplying `charMap` without `charReference` (or either numeric counterpart)
  now throws instead of silently pairing the custom map against the default
  reference and encoding the wrong characters.

# 1.0.6

Correctness and tooling release. **Haptic pattern output is unchanged** — the
pattern rework is deliberately deferred to 2.0.0 (see *Known issues*).

### Fixed

- `HapticModel` now implements `==`, `hashCode`, and `toString`. Instances with
  equal fields previously compared unequal, which broke `expect`, set/map
  membership, and `BlocBuilder`/`distinct()` deduplication.
- `HapticModel.fromMap` accepts durations encoded as any `num` instead of
  throwing a `TypeError` when JSON supplies doubles (`[100.0, 300.0]`).
- `HapticModel.hapticDurations` returns an unmodifiable view. Callers could
  previously mutate the model's internal list in place.
- A custom `numericReference` containing a regex metacharacter (for example
  `(`) no longer throws a `FormatException`. Character lookup no longer builds
  a `RegExp` at all.
- Custom numeric lookups are now consistently case-insensitive. The old code
  upper-cased the generated pattern but tested the raw character against it,
  so a custom reference such as `'AB'` never matched lowercase input.
- CI now runs on the Flutter SDK. The previous `dart test` step could not load
  any test file, so every push since 1.0.3 was merged unverified. Formatting
  and `--fatal-infos` analysis are enforced.

### Changed

- `platforms:` now declares **android** and **ios** only. `package:vibration`
  ships plugin implementations for those two platforms, so the previous
  macos/linux/windows entries advertised support that could not work.
- Character lookup no longer compiles a `RegExp` per character.
- README corrected: the default-usage and extension examples did not compile,
  `convertTextToMorseMap` was documented as returning a `Map` with a
  `hapticCount` key that has never existed, and the emoji-mapping section
  described behaviour the package does not have.
- Generated `doc/api` output is no longer tracked or published. It shipped in
  the tarball and documented a private member removed by this release; pub.dev
  builds its own API docs.
- `example_flutter/` is excluded from the published archive via `.pubignore`.
  pub.dev only renders `example/`, so the demo app shipped to every consumer
  without ever being displayed. It remains in the repository.
- The published archive is now 14 KB, down from roughly 800 KB in 1.0.5.
- `coverage/` is now git-ignored.

### Known issues (fixed in 2.0.0)

- **Haptic patterns are phase-inverted.** `vibration` treats index `0` of
  `pattern` as an *off* delay; generated patterns start with an *on* duration,
  so symbols and gaps play swapped. Workaround: prepend `0`.
- Consecutive spaces emit adjacent gap values, breaking off/on alternation for
  the remainder of the pattern.
- A leading space emits a spurious word gap; a trailing unsupported character
  emits a dangling letter gap.
- Characters outside the Basic Multilingual Plane (most emoji) cannot be used
  in `charReference`.
- The package cannot be used from plain Dart, because the top-level export
  pulls in `package:vibration` and therefore `dart:ui`.

# 1.0.5

- Integrated HapticModel to facilitate interaction

## 1.0.4

- Updated dependencies.

## 1.0.3

- String extension class to facilitate accessibility and string manipulation directly.

## 1.0.2

- Integrated custom symbol reference.

## 1.0.1

- Custom numeric regex validation

## 1.0.0

- HapticMorse release.
