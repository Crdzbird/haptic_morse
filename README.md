# HapticMorse

[![pub package](https://img.shields.io/pub/v/haptic_morse.svg)](https://pub.dev/packages/haptic_morse)
[![pub points](https://img.shields.io/pub/points/haptic_morse.svg)](https://pub.dev/packages/haptic_morse/score)
[![coverage](https://img.shields.io/badge/coverage-100%25-brightgreen.svg)](#test-coverage)
[![Dart](https://img.shields.io/badge/Dart-Stable-blue.svg)](https://dart.dev)

Convert text to Morse code and to haptic vibration patterns.

## Introduction

HapticMorse turns text into Morse code, both as symbols and as vibration you
can feel. It provides:

- Readable Morse code, including punctuation
- Haptic sequences that play correctly on Android and iOS
- Decoding, back from either representation
- Speed in words per minute, with Farnsworth timing
- Custom alphabets, for any script

The encoder is pure Dart, so it runs in a CLI, on a server, in `dart test`, and
in Flutter. The motor-driving half lives in a separate library you import only
when you need it.

## Installation

```yaml
dependencies:
  haptic_morse: ^2.0.0
```

There are two entry points:

```dart
// Pure Dart. Encoding, decoding, patterns, models. Works everywhere.
import 'package:haptic_morse/haptic_morse.dart';

// Flutter plus package:vibration. Android and iOS only.
import 'package:haptic_morse/haptic_morse_vibration.dart';
```

## Usage

### Encoding

```dart
const morse = HapticMorse();

print(morse.convertTextToMorseString('SOS')); // ... --- ...
print('HELLO WORLD'.toMorseString());
// .... . .-.. .-.. --- / .-- --- .-. .-.. -..
```

`convertTextToMorseString` returns `null` when there is nothing to encode:
null, empty, whitespace only, or entirely unmapped characters.

### Playing it

```dart
const haptics = HapticVibration();

await haptics.vibrateText('SOS');    // encode and play
await haptics.vibrateEvents(events); // play a sequence you already have
await haptics.cancel();
```

### The sequence

`toHapticEvents` returns a list of sealed `HapticEvent` values, so you can
render, animate, or analyse the sequence instead of guessing what a bare
integer meant:

```dart
for (final event in 'SOS'.toHapticEvents()) {
  final label = switch (event) {
    HapticDot()       => 'dot',
    HapticDash()      => 'dash',
    HapticSymbolGap() => 'symbol gap',
    HapticLetterGap() => 'letter gap',
    HapticWordGap()   => 'word gap',
  };
  print('$label, ${event.duration}ms');
}
```

The sequence contract: it strictly alternates vibration and silence, starts and
ends with a vibration, and never contains two adjacent gaps.

### Raw patterns

To drive `package:vibration`, or any waveform API, yourself:

```dart
final pattern = 'SOS'.toVibrationPattern(); // [0, 100, 100, 100, ...]
await Vibration.vibrate(pattern: pattern);
```

Index 0 is an off delay and the list alternates off and on from there. That is
the convention shared by Android's `VibrationEffect.createWaveform` and the iOS
side of `package:vibration`. `toVibrationPattern()` emits the leading zero for
you.

### String extensions

```dart
'SOS'.toMorseString();      // String?
'SOS'.toHapticEvents();     // List<HapticEvent>
'SOS'.toMorseModel();       // HapticModel
'SOS'.toVibrationPattern(); // List<int>
```

Each takes an optional `HapticMorse` to override the defaults:

```dart
final fast = HapticMorse.custom(dotDuration: 80, dashDuration: 240);
'SOS'.toVibrationPattern(fast);
```

### Decoding

Morse goes back to text, from either representation:

```dart
morse.decodeMorseString('... --- ...');       // "SOS"
morse.decodeEvents('HELLO'.toHapticEvents()); // "HELLO"
```

`decodeEvents` needs no threshold guessing, because the events are already
typed, so symbol and word boundaries are exact. Decoded text is upper case,
because Morse does not carry case. Unrecognized patterns are skipped, mirroring
how encoding skips unmapped characters.

### Speed in words per minute

```dart
final morse = HapticMorse.atSpeed(wordsPerMinute: 20);
```

One unit is `1200 / wordsPerMinute` milliseconds, the standard definition.

For Farnsworth timing, which delivers crisp characters slowly and is the
setting that matters most for reading through skin, give an overall speed as
well:

```dart
final morse = HapticMorse.atSpeed(
  wordsPerMinute: 20,         // each character is sent at 20 WPM
  effectiveWordsPerMinute: 8, // the message overall reads at 8 WPM
);
```

Symbols keep their 20 WPM shape while the letter and word gaps stretch, so the
rhythm of each character stays recognizable instead of turning into slow mush.

### Custom timings and alphabets

```dart
final morse = HapticMorse.custom(
  dotDuration: 80,
  dashDuration: 240,
  gapSymbolDuration: 80,
  gapLetterDuration: 240,
  gapWordDuration: 560,
);
```

`HapticMorse.custom` validates its arguments and throws `ArgumentError` if a
map and its reference disagree in length, a reference repeats a character, a
pattern is empty or uses characters other than the configured dot and dash, or
a duration is not positive. Misconfiguration fails at construction instead of
silently dropping letters.

## International and custom alphabets

The default table covers A-Z, 0-9, and punctuation. The ITU-R M.1677-1 set is
`. , : ? ' - / ( ) " = + @`, plus the conventional `& ! ; _ $`.

Accented letters are opt-in, since they are regional convention rather than
ITU-normative:

```dart
final morse = HapticMorse.custom(
  additionalSymbols: HapticMorse.accentedLetters, // A-grave and friends
);
print(morse.convertTextToMorseString('MANANA'));
```

Text is segmented into grapheme clusters, so any character your users can type
counts as one character, including emoji built from surrogate pairs, variation
selectors, or zero-width joiners.

```dart
final morse = HapticMorse.custom(
  charMap: ['.-', '-...', '..--', '.-.-'],
  charReference: 'AB', // plus any two further characters
);
```

You can even change the characters the patterns are spelled with:

```dart
final binary = HapticMorse.custom(symbolReference: '0', dashReference: '1');
print(binary.convertTextToMorseString('SOS')); // 000 111 000
```

## Accessibility and conformance

### Timing follows the international standard

The defaults implement the ITU-R M.1677-1 unit ratios, and the test suite
checks them rather than trusting them:

| Element             | Units | Default |
| ------------------- | ----- | ------- |
| dot                 | 1     | 100ms   |
| dash                | 3     | 300ms   |
| gap between symbols | 1     | 100ms   |
| gap between letters | 3     | 300ms   |
| gap between words   | 7     | 700ms   |

The strongest single check is the standard word PARIS, which is defined to be
exactly 50 units. If that holds, every ratio is simultaneously correct. At the
defaults, PARIS plus one word space measures 5000ms, giving 12 WPM, which
matches the standard formula `WPM = 1200 / dotDurationMs`.

Use `HapticMorse.atSpeed` rather than scaling the five durations by hand. The
conformance suite measures the resulting speed at 5, 12, 13, 20, 25, and 40
WPM, and measures Farnsworth output at five character and overall pairs, so the
timing model is checked rather than assumed.

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

`hasCustomVibrationsSupport()` is the check that matters for Morse, because it
asks the platform directly. `hasVibrator()` resolves from device info instead
and returns `false` on emulators and simulators, so do not gate development
builds on it.

### Known limitations

- 12 WPM is fast for a beginner reading through skin. Use
  `HapticMorse.atSpeed` with an `effectiveWordsPerMinute` below the character
  speed. Farnsworth timing keeps each character's rhythm recognizable while
  slowing the message down.
- Very short units may not be perceptible. Durations are validated as positive,
  not as perceptible. Check with `events.isLikelyPerceptible`, which flags
  vibrations under `HapticEvent.minimumPerceptibleMilliseconds` (20ms, roughly
  60 WPM). It is a heuristic rather than a specification, since an
  eccentric-rotating-mass motor needs tens of milliseconds to spin up while an
  LRA responds faster, so nothing is rejected on its basis. Test on target
  devices.
- Every vibration is sent with Android's `USAGE_ALARM`. That is hardcoded in
  `package:vibration`, not chosen here, and it means playback is categorized as
  an alarm rather than as accessibility or notification output. If that matters
  for your app, drive the platform APIs directly with `toVibrationPattern()`.
- Named prosigns such as `<SK>` and `<KN>` are not supported. Table keys are
  single characters, so multi-character tokens cannot be expressed. The
  prosigns that have punctuation equivalents (`+` for AR, `=` for BT, `@` for
  AC, `&` for AS) are in the default table.

## Proof it works

The [example](example/haptic_morse_example.dart) is self-verifying, runs on
plain Dart with no device, and executes in CI on every push:

```bash
dart run example/haptic_morse_example.dart
```

It does not just print values. It takes the raw `List<int>` handed to the
platform and reconstructs the message from it using only the documented off and
on convention, with no reference to this package's types. It also demonstrates
the 1.x bug rather than describing it: the same durations without the leading
zero decode to a different message entirely.

<!-- example-output:begin -->
```text
1. The pattern actually carries the message
   text            : "SOS"
   morse           : ... --- ...
   pattern         : [0, 100, 100, 100, 100, 100, 300, 300, 100, 300, 100, 300, 300, 100, 100, 100, 100, 100]
   timeline        : #_#_#___###_###_###___#_#_#
   recovered morse : ... --- ...
   recovered text  : "SOS"
   [ok]   pattern decodes to the original morse
   [ok]   pattern decodes to the original text
2. Why the leading zero matters
   1.x pattern     : [100, 100, 100, 100, 100, 300, 300, 100, 300, 100, 300, 300, 100, 100, 100, 100, 100]
   1.x timeline    : _#_#_###___#___#___###_#_#_
   plays as morse  : ..- . . -..
   plays as text   : "UEED"
   expected        : "SOS"
   [ok]   the 1.x pattern played as something else
   [ok]   the 2.0.0 pattern starts with an off delay
```
<!-- example-output:end -->

The block above is checked by `test/readme_test.dart`, which rebuilds the
report and fails if any quoted line is no longer printed. It also checks the
ITU timing ratios, the sequence contract at six awkward edges, and round trips
over punctuation and digits: eight assertions in total, and the program exits
non-zero if any fails.

## API overview

### HapticMorse

| Member                               | Returns             | Description                                |
| ------------------------------------ | ------------------- | ------------------------------------------ |
| `const HapticMorse()`                |                     | A-Z, 0-9, punctuation, 12 WPM              |
| `HapticMorse.atSpeed({...})`         |                     | Timing in WPM, optional Farnsworth         |
| `HapticMorse.custom({...})`          |                     | Custom timings and alphabet, validated     |
| `convertTextToMorseString(String?)`  | `String?`           | Dots and dashes, words split by `" / "`    |
| `convertTextToHapticEvents(String?)` | `List<HapticEvent>` | The haptic sequence                        |
| `convertTextToModel(String?)`        | `HapticModel`       | All three, tokenized once                  |
| `decodeMorseString(String?)`         | `String?`           | Morse back to upper-case text              |
| `decodeEvents(List<HapticEvent>)`    | `String?`           | A sequence back to text                    |
| `supportedCharacters`                | `Iterable<String>`  | Everything this encoder can represent      |
| `HapticMorse.accentedLetters`        | `Map<String,String>`| Opt-in accented letters                    |

### HapticEvent

Sealed: `HapticDot`, `HapticDash`, `HapticSymbolGap`, `HapticLetterGap`,
`HapticWordGap`. Each has `duration`, `isVibration`, `toJson()`, and value
equality. On `List<HapticEvent>`: `toVibrationPattern()`, `totalDuration`,
`imperceptibleEvents`, and `isLikelyPerceptible`.

### HapticModel

`text`, `morseCode`, `events` (unmodifiable), `totalDuration`,
`toVibrationPattern()`, `copyWith`, `toJson`, `encode`, `fromMap`, `fromJson`,
plus `==` and `hashCode`. `HapticModel.empty` is the constant empty instance.
The main constructor copies its `events` list and so is not `const`.

### HapticVibration

`vibrateText`, `vibrateEvents`, `vibrate`, `cancel`, plus the capability checks
`hasCustomVibrationsSupport`, `hasVibrator`, and `hasAmplitudeControl`. Android
and iOS only.

## Migrating from 1.x

1.x haptic patterns were played inverted. `package:vibration` treats index 0 as
an off delay, but 1.x emitted a vibration there, so every dot and dash was
played as silence and every gap as a buzz. Patterns also broke at leading
spaces, doubled spaces, and trailing unsupported characters. Fixing this
required changing the output, hence 2.0.0.

| 1.x                                        | 2.0.0                                                          |
| ------------------------------------------ | -------------------------------------------------------------- |
| `convertTextToHapticPattern(text)`         | `convertTextToHapticEvents(text)`, or `toVibrationPattern()`    |
| `convertTextToMorseMap(text)`              | `convertTextToModel(text)`                                      |
| `model.hapticDurations`                    | `model.events`, or `model.toVibrationPattern()`                 |
| `'x'.toMorseMap()`                         | `'x'.toMorseModel()`                                            |
| `'x'.toHapticPattern()`                    | `'x'.toHapticEvents()` or `'x'.toVibrationPattern()`            |
| `'x'.toMorseString(dotDuration: 80)`       | `'x'.toMorseString(HapticMorse.custom(dotDuration: 80))`        |
| `HapticMorse(charMap: ...)`                | `HapticMorse.custom(charMap: ...)`                              |
| `HapticVibration` from the main import     | import `package:haptic_morse/haptic_morse_vibration.dart`       |

Also note:

- `convertTextToMorseString` now returns `null`, not `''`, when the input holds
  no mappable characters.
- `HapticMorse.custom` throws `ArgumentError` on configurations 1.x accepted
  silently. A `charMap` shorter than its `charReference` is the common one.
- Punctuation is now encoded rather than skipped, so input containing `.` or
  `,` produces more output than it did in 1.x.
- `package:vibration` is no longer re-exported. Import it directly if you use
  its API.
- If you applied the 1.0.6 `[0, ...pattern]` workaround, remove it.
  `toVibrationPattern()` now emits the leading zero itself.

## Test coverage

100% line coverage (290 of 290), enforced in CI. The build fails below it.

```bash
flutter test --coverage
```

No lines are excluded and no checks were removed to get there. One subtlety is
worth knowing if you add an `assert`: an interpolated failure message is itself
executable code that only runs when the assert fails, so it can never be
covered. Keep such messages constant.

The core suite also runs on the plain Dart SDK
(`dart test --exclude-tags flutter`), which is what keeps `haptic_morse.dart`
free of Flutter and `dart:ui`.

## Use cases

- Silent alerts and accessibility tools
- Hidden messages in games
- Support for people who are deaf or hard of hearing
- Morse-coded chat
- Educational tools
- Multi-lingual Morse messages

## Resources

- [International Morse Code](https://en.wikipedia.org/wiki/Morse_code)
- [package:vibration](https://pub.dev/packages/vibration)

## Contributing

Issues and pull requests are welcome.

## License

MIT License.
