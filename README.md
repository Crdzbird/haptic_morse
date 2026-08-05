
# 🌟 HapticMorse 💥

[![pub package](https://img.shields.io/pub/v/haptic_morse.svg)](https://pub.dev/packages/haptic_morse)
[![pub points](https://img.shields.io/pub/points/haptic_morse.svg)](https://pub.dev/packages/haptic_morse/score)



*Your Words, in Vibes & Dashes*

[![codecov](https://img.shields.io/badge/coverage-100%25-brightgreen.svg)](#)
[![Dart](https://img.shields.io/badge/Dart-Stable-blue.svg)](https://dart.dev)
[![Vibration-Powered](https://img.shields.io/badge/Powered_By-Haptics-ff69b4.svg)](#)

---

## 🚀 Introduction

**HapticMorse** is a powerful, customizable Dart library that brings **Morse code** to life — not just in symbols, but in **vibrations**. Whether you're building accessibility tools, games, messaging apps, or just love Morse code (who doesn’t?), this package translates any text input into:

✨ **Readable Morse Code**
📳 **Haptic Feedback Patterns**
🔠 **Custom Symbol Mappings** — including **non-Latin** characters!

All wrapped in a single elegant, performant class.

---

## 🎯 Features

* 🔠 Convert text (`A-Z`, `0-9`) to **Morse code** strings (`.-- --- .-. -.. ...`)
* 📳 Generate **haptic patterns** for dots, dashes, and all gaps
* 🧩 Fully **customizable character & digit mappings** — even for **non-Latin** alphabets!
* ⚙️ Custom **timing control** (dot, dash, gaps) for complete UX freedom
* 🧠 Smart parsing & fallback for unsupported characters
* ✅ **100% Test Coverage** — we've tested every buzz 💯

---

## 🌍 International & Custom Support

You’re not limited to just English! Add **custom mappings** for other languages and symbols.

```dart
final morse = HapticMorse.custom(
  charMap: ['.-', '-...', '..--', '.-.-'], // Your custom Morse patterns
  charReference: 'AB日水', // Must match the map's order
  numericMap: ['-----', '.----', '..---', '...--'],
  numericReference: '0123', // Also in order
);

final output = morse.convertTextToMorseString('AB日水');
print(output); // .- -... ..-- .-.-
```

> **Character support:** references are matched by UTF-16 code unit, so every
> character in `charReference` / `numericReference` must be a single code unit.
> Most scripts qualify — including Japanese Kanji such as `日水` — but characters
> outside the Basic Multilingual Plane (most emoji, e.g. `💧`) are surrogate
> pairs and will **not** match correctly. Emoji in `charMap` values are likewise
> read as several symbols rather than one. Full rune support is planned for
> 2.0.0.

---

## 🛠️ Usage

### ✅ Default Usage

`convertTextToMorseMap` returns a [`HapticModel`](#-api-overview) — a value type
with `==`, `hashCode`, `copyWith`, and JSON support.

```dart
final morse = HapticMorse();

final result = morse.convertTextToMorseMap('HELLO WORLD');

print(result.text);            // "HELLO WORLD"
print(result.morseCode);       // ".... . .-.. .-.. --- / .-- --- .-. .-.. -.."
print(result.hapticDurations); // [100, 100, 100, 100, 100, 100, 100, 300, ...]
```

Need just one of the two? Use the focused methods:

```dart
final code = morse.convertTextToMorseString('SOS');  // "... --- ..."
final pattern = morse.convertTextToHapticPattern('SOS');
```

### 🔧 With Custom Timings

```dart
final morse = HapticMorse.custom(
  dotDuration: 80,
  dashDuration: 240,
  gapSymbolDuration: 80,
  gapLetterDuration: 240,
  gapWordDuration: 600,
);
```

### ⛓️ Extended from String Directly

```dart
final code    = 'HELLO WORLD'.toMorseString();    // String?
final model   = 'HELLO WORLD'.toMorseMap();       // HapticModel
final pattern = 'HELLO WORLD'.toHapticPattern();  // List<int>
```

Every extension method takes the same optional parameters as
`HapticMorse.custom`, so you can override any of them inline:

```dart
final pattern = 'SOS'.toHapticPattern(
  dotDuration: 80,
  dashDuration: 240,
  gapWordDuration: 600,
);
```

---

## 📳 Vibrate Module

`HapticVibration` wraps [`package:vibration`](https://pub.dev/packages/vibration)
so you can play a generated pattern:

```dart
const haptics = HapticVibration();

await haptics.vibrate(pattern: 'SOS'.toHapticPattern());
await haptics.cancel();
```

> ⚠️ **Known issue (fixed in 2.0.0).** `vibration` treats index `0` of `pattern`
> as an **off** delay and alternates off/on from there. The patterns produced by
> this version start with an **on** duration, so dots/dashes and gaps play
> inverted. Until 2.0.0 lands, prepend a zero yourself:
>
> ```dart
> await haptics.vibrate(pattern: [0, ...'SOS'.toHapticPattern()]);
> ```
>
> Note this workaround is still imperfect for input containing consecutive
> spaces. See the changelog for details.

Vibration is supported on **Android and iOS** only.

---


## 📦 API Overview

### 🧩 `convertTextToMorseString(String?) → String?`

Returns a Morse code string using dots (`.`) and dashes (`-`), separating words with `/`.

### 🎵 `convertTextToHapticPattern(String?) → List<int>`

Returns a list of vibration durations for:

* 🔹 Dot
* 🔸 Dash
* ⏱ Symbol/letter/word gaps

### 🔄 `convertTextToMorseMap(String?) → HapticModel`

Returns a `HapticModel` with:

| Field | Type | Description |
| --- | --- | --- |
| `text` | `String` | The original input |
| `morseCode` | `String` | Dot/dash representation |
| `hapticDurations` | `List<int>` | Vibration durations (unmodifiable view) |

`HapticModel` supports `==` / `hashCode`, `copyWith`, `toJson`, `encode`,
`fromMap`, and `fromJson`.

---

## 🧪 Test Coverage

✅ **100% line coverage**, verified with `flutter test --coverage`.

Run it yourself:

```bash
flutter test --coverage
```

---

## 💡 Use Cases

* 🔔 Silent alerts & accessibility tools
* 🎮 Hidden messages in games
* 🧏 Support for the hearing impaired
* 💬 Secret Morse-coded chat apps
* 🧠 Educational tools
* 🌐 **Multi-lingual & emoji Morse messages!**

---

## 📚 Resources

* [International Morse Code](https://en.wikipedia.org/wiki/Morse_code)
* [Vibration API](https://developer.mozilla.org/en-US/docs/Web/API/Vibration_API)

---

## 👏 Contribute

Got a new idea or feedback? PRs and issues are always welcome!
Let’s make text **feel** awesome! 💥

---

## 📜 License

MIT License. Vibrate responsibly. 😎
