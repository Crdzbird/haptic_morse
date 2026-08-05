
# 🌟 HapticMorse 💥

[![pub package](https://img.shields.io/pub/v/haptic_morse.svg)](https://pub.dev/packages/haptic_morse)
[![pub points](https://img.shields.io/pub/points/haptic_morse.svg)](https://pub.dev/packages/haptic_morse/score)

*Your Words, in Vibes & Dashes*

[![coverage](https://img.shields.io/badge/coverage-99%25-brightgreen.svg)](#-test-coverage)
[![Dart](https://img.shields.io/badge/Dart-Stable-blue.svg)](https://dart.dev)
[![Vibration-Powered](https://img.shields.io/badge/Powered_By-Haptics-ff69b4.svg)](#-vibrate-module)

---

## 🚀 Introduction

**HapticMorse** turns text into Morse code — not just as symbols, but as
vibration you can feel. It gives you:

✨ **Readable Morse code**
📳 **Haptic sequences** that play correctly on Android and iOS
🔠 **Custom alphabets** — any script, and emoji

The encoder is **pure Dart**, so it runs in a CLI, on a server, in `dart test`,
and in Flutter. The motor-driving half lives in a separate library you only
import when you need it.

---

## 📦 Installation

```yaml
dependencies:
  haptic_morse: ^2.0.0
```

Two entry points:

```dart
// Pure Dart. Encoding, patterns, models. Works everywhere.
import 'package:haptic_morse/haptic_morse.dart';

// Flutter + package:vibration. Android and iOS only.
import 'package:haptic_morse/haptic_morse_vibration.dart';
```

---

## 🛠️ Usage

### ✅ Encoding

```dart
const morse = HapticMorse();

print(morse.convertTextToMorseString('SOS')); // ... --- ...
print('HELLO WORLD'.toMorseString());
// .... . .-.. .-.. --- / .-- --- .-. .-.. -..
```

`convertTextToMorseString` returns `null` when there is nothing to encode —
null, empty, whitespace only, or entirely unmapped characters.

### 📳 Playing it

```dart
const haptics = HapticVibration();

await haptics.vibrateText('SOS');           // encode and play
await haptics.vibrateEvents(events);        // play a sequence you already have
await haptics.cancel();
```

### 🎵 The sequence

`toHapticEvents` returns a list of sealed `HapticEvent`s, so you can render,
animate, or analyse the sequence rather than guessing what a bare integer meant:

```dart
for (final event in 'SOS'.toHapticEvents()) {
  final label = switch (event) {
    HapticDot()       => 'dot',
    HapticDash()      => 'dash',
    HapticSymbolGap() => 'symbol gap',
    HapticLetterGap() => 'letter gap',
    HapticWordGap()   => 'word gap',
  };
  print('$label — ${event.duration}ms');
}
```

**The sequence contract:** it strictly alternates vibration and silence, starts
and ends with a vibration, and never contains two adjacent gaps.

### 🔌 Raw patterns

To drive `package:vibration` (or any waveform API) yourself:

```dart
final pattern = 'SOS'.toVibrationPattern(); // [0, 100, 100, 100, ...]
await Vibration.vibrate(pattern: pattern);
```

Index `0` is an **off** delay and the list alternates off/on from there — the
convention shared by Android's `VibrationEffect.createWaveform` and the iOS
side of `package:vibration`. `toVibrationPattern()` emits the leading `0` for
you.

### ⛓️ String extensions

```dart
'SOS'.toMorseString();       // String?
'SOS'.toHapticEvents();      // List<HapticEvent>
'SOS'.toMorseModel();        // HapticModel
'SOS'.toVibrationPattern();  // List<int>
```

Each takes an optional `HapticMorse` to override the defaults:

```dart
final fast = HapticMorse.custom(dotDuration: 80, dashDuration: 240);
'SOS'.toVibrationPattern(fast);
```

### 🔧 Custom timings and alphabets

```dart
final morse = HapticMorse.custom(
  dotDuration: 80,
  dashDuration: 240,
  gapSymbolDuration: 80,
  gapLetterDuration: 240,
  gapWordDuration: 560,
);
```

`HapticMorse.custom` **validates its arguments** and throws `ArgumentError` if
a map and its reference disagree in length, a reference repeats a character, a
pattern is empty or uses characters other than the configured dot and dash, or
a duration is not positive. Misconfiguration fails at construction instead of
silently dropping letters.

---

## 🌍 International & emoji support

Text is segmented into **grapheme clusters**, so any character your users can
type counts as one character — including emoji made of surrogate pairs,
variation selectors, or zero-width joiners.

```dart
final morse = HapticMorse.custom(
  charMap: ['.-', '-...', '..--', '.-.-'],
  charReference: 'AB日水',
);
print(morse.convertTextToMorseString('AB日水')); // .- -... ..-- .-.-
```

```dart
final emoji = HapticMorse.custom(
  charMap: ['.-', '--'],
  charReference: '💧🔥',
);
print(emoji.convertTextToMorseString('💧🔥')); // .- --
```

You can even change the symbols the patterns are spelled with:

```dart
final binary = HapticMorse.custom(symbolReference: '0', dashReference: '1');
print(binary.convertTextToMorseString('SOS')); // 000 111 000
```

---

## ♿ Accessibility & conformance

### Morse timing is standards-conformant

The defaults implement the ITU-R M.1677-1 unit ratios, and the test suite
checks them rather than trusting them:

| Element | Units | Default |
| --- | --- | --- |
| dot (dit) | 1 | 100ms |
| dash (dah) | 3 | 300ms |
| gap between symbols | 1 | 100ms |
| gap between letters | 3 | 300ms |
| gap between words | 7 | 700ms |

The strongest single check is the standard word **PARIS**, which is defined to
be exactly 50 units — if that holds, every ratio is simultaneously correct.
`'PARIS'.toMorseModel()` plus one word space measures 5000ms at the defaults,
giving **12 WPM**, matching the standard `WPM = 1200 / dotDurationMs`.

To pick a speed, set the dot duration and scale the rest:

```dart
const wpm = 20;
const unit = 1200 ~/ wpm; // 60ms
final morse = HapticMorse.custom(
  dotDuration: unit,
  dashDuration: 3 * unit,
  gapSymbolDuration: unit,
  gapLetterDuration: 3 * unit,
  gapWordDuration: 7 * unit,
);
```

### Always provide a non-haptic path

A haptic-only message is unreadable on a device that cannot reproduce the
timing. Check before you rely on it:

```dart
if (await haptics.hasCustomVibrationsSupport()) {
  await haptics.vibrateText(message);
} else {
  showText(message.toMorseString()); // or the plain text
}
```

`hasCustomVibrationsSupport()` is the check that matters for Morse — it asks
the platform directly. `hasVibrator()` resolves from device info instead and
returns `false` on **emulators and simulators**, so don't gate development
builds on it.

### Known limitations

- **12 WPM is fast for a beginner reading through skin.** Consider a slower
  unit, or Farnsworth-style timing (standard characters, stretched gaps), which
  you can build today by passing large gap durations with small symbol
  durations.
- **Very short units may not be perceptible.** Durations are validated as
  positive, not as perceptible; eccentric-rotating-mass motors need tens of
  milliseconds to spin up, so a dot below roughly 20–30ms may not be felt at
  all on some hardware. Test on target devices.
- **Every vibration is sent with Android's `USAGE_ALARM`.** That is hardcoded
  in `package:vibration`, not chosen here, and it means playback is categorized
  as an alarm rather than as accessibility or notification output. If that
  matters for your app, drive the platform APIs directly with
  `toVibrationPattern()`.
- **Punctuation and accented letters are not in the default table** (A-Z and
  0-9 only). Supply them via `HapticMorse.custom`.

---

## 📚 API Overview

### `HapticMorse`

| Member | Returns | Description |
| --- | --- | --- |
| `const HapticMorse()` | — | Standard International Morse Code |
| `HapticMorse.custom({...})` | — | Custom timings/alphabet; validates and throws |
| `convertTextToMorseString(String?)` | `String?` | Dots and dashes, words split by `" / "` |
| `convertTextToHapticEvents(String?)` | `List<HapticEvent>` | The haptic sequence |
| `convertTextToModel(String?)` | `HapticModel` | All three, tokenized once |

### `HapticEvent`

Sealed: `HapticDot`, `HapticDash`, `HapticSymbolGap`, `HapticLetterGap`,
`HapticWordGap`. Each has `duration`, `isVibration`, `toJson()`, and value
equality. On `List<HapticEvent>`: `toVibrationPattern()` and `totalDuration`.

### `HapticModel`

`text`, `morseCode`, `events` (unmodifiable), `totalDuration`,
`toVibrationPattern()`, `copyWith`, `toJson`, `encode`, `fromMap`, `fromJson`,
plus `==`/`hashCode`.

### `HapticVibration`

`vibrateText`, `vibrateEvents`, `vibrate`, `cancel`, plus the capability checks
`hasCustomVibrationsSupport`, `hasVibrator`, and `hasAmplitudeControl`.
Android and iOS only.

---

## ⬆️ Migrating from 1.x

**1.x haptic patterns were played inverted.** `package:vibration` treats index
0 as an off delay, but 1.x emitted a vibration there, so every dot and dash was
played as silence and every gap as a buzz. Patterns also broke at leading
spaces, doubled spaces, and trailing unsupported characters. Fixing this
required changing the output, hence 2.0.0.

| 1.x | 2.0.0 |
| --- | --- |
| `convertTextToHapticPattern(text)` | `convertTextToHapticEvents(text)`, or `toVibrationPattern()` for `List<int>` |
| `convertTextToMorseMap(text)` | `convertTextToModel(text)` |
| `model.hapticDurations` | `model.events`, or `model.toVibrationPattern()` |
| `'x'.toMorseMap()` | `'x'.toMorseModel()` |
| `'x'.toHapticPattern()` | `'x'.toHapticEvents()` / `'x'.toVibrationPattern()` |
| `'x'.toMorseString(dotDuration: 80, ...)` | `'x'.toMorseString(HapticMorse.custom(dotDuration: 80))` |
| `HapticMorse(charMap: ..., ...)` | `HapticMorse.custom(charMap: ..., ...)` |
| `import '...haptic_morse.dart'` for `HapticVibration` | `import '...haptic_morse_vibration.dart'` |

Also note:

- `convertTextToMorseString` now returns `null` (not `''`) when the input holds
  no mappable characters.
- `HapticMorse.custom` throws `ArgumentError` on configurations 1.x accepted
  silently. A `charMap` shorter than its `charReference` is the common one.
- `package:vibration` is no longer re-exported. Import it directly if you use
  its API.
- If you applied the 1.0.6 `[0, ...pattern]` workaround, **remove it** —
  `toVibrationPattern()` now emits the leading zero itself.

---

## 🧪 Test Coverage

✅ **213 of 215 lines (99.1%)**, verified in CI.

```bash
flutter test --coverage
```

The two uncovered lines are the message of an `assert` guarding an invariant
that `HapticMorse.custom` makes unreachable — it can only evaluate if the
validation is bypassed.

The core suite also runs on the plain Dart SDK
(`dart test --exclude-tags flutter`), which is what keeps `haptic_morse.dart`
free of Flutter and `dart:ui`.

---

## 💡 Use Cases

* 🔔 Silent alerts & accessibility tools
* 🎮 Hidden messages in games
* 🧏 Support for the hearing impaired
* 💬 Secret Morse-coded chat apps
* 🧠 Educational tools
* 🌐 Multi-lingual & emoji Morse messages

---

## 📚 Resources

* [International Morse Code](https://en.wikipedia.org/wiki/Morse_code)
* [package:vibration](https://pub.dev/packages/vibration)

---

## 👏 Contribute

Got a new idea or feedback? PRs and issues are always welcome!
Let’s make text **feel** awesome! 💥

---

## 📜 License

MIT License. Vibrate responsibly. 😎
