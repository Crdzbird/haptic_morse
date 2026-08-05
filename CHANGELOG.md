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
