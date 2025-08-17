
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

You’re not limited to just English! Add **custom mappings** for other languages, symbols, or even **emoji-based Morse** (yes, that's a thing now).

```dart
final morse = HapticMorse.custom(
  charMap: ['.-', '-...', '☀️-', '💧💧'], // Your custom Morse patterns
  charReference: 'AB日水', // Must match the map's order
  numericMap: ['...', '...-', '💎', '🌙'],
  numericReference: '0123', // Also in order
);
```

Now this works:

```dart
final output = morse.convertTextToMorseString("AB日水");
print(output); // .- -... ☀️- 💧💧
```

🎉 Boom — custom Morse for **Japanese Kanji, emoji, or anything** your heart desires.

---

## 🛠️ Usage

### ✅ Default Usage

```dart
final morse = HapticMorse();

final text = "HELLO WORLD";
final result = morse.convertTextToMorseMap(text);

print(result['morseString']); // ".... . .-.. .-.. --- / .-- --- .-. .-.. -.."
print(result['hapticDurations']); // [100, 100, 100, 300, ...]
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
final morse = 'HELLO WORLD'.toMorseString({
  List<String>? charMap,
  String? charReference,
  List<String>? numericMap,
  String? numericReference,
  int? dotDuration,
  int? dashDuration,
  int? gapSymbolDuration,
  int? gapLetterDuration,
  int? gapWordDuration,
  String? symbolReference,
});
final morse2 = 'HELLO WORLD'.toMorseMap({
  List<String>? charMap,
  String? charReference,
  List<String>? numericMap,
  String? numericReference,
  int? dotDuration,
  int? dashDuration,
  int? gapSymbolDuration,
  int? gapLetterDuration,
  int? gapWordDuration,
  String? symbolReference,
});
final morse3 = 'HELLO WORLD'.toHapticPattern({
  List<String>? charMap,
  String? charReference,
  List<String>? numericMap,
  String? numericReference,
  int? dotDuration,
  int? dashDuration,
  int? gapSymbolDuration,
  int? gapLetterDuration,
  int? gapWordDuration,
  String? symbolReference,
});
```

---

## Vibrate Module

Call `HapticVibration` to integrate vibration functionality.
---


## 📦 API Overview

### 🧩 `convertTextToMorseString(String?) → String?`

Returns a Morse code string using dots (`.`) and dashes (`-`), separating words with `/`.

### 🎵 `convertTextToHapticPattern(String?) → List<int>`

Returns a list of vibration durations for:

* 🔹 Dot
* 🔸 Dash
* ⏱ Symbol/letter/word gaps

### 🔄 `convertTextToMorseMap(String?) → Map<String, dynamic>`

Returns a rich object with:

* `morseString`
* `hapticDurations`
* `hapticCount`

---

## 🧪 Test Coverage

✅ **100% Test Coverage**
This library is thoroughly tested — every line, every case, every buzz! 🧪
You're in safe, vibrating hands. 💯

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
