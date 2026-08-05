// ignore_for_file: avoid_print

// This example is pure Dart — run it with `dart run`:
//
//   dart run example/haptic_morse_example.dart
//
// Driving the motor needs the companion library and a device; see the
// commented section at the end.
import 'package:haptic_morse/haptic_morse.dart';

void main() {
  // 1. Standard International Morse Code.
  const morse = HapticMorse();

  final model = morse.convertTextToModel('HELLO WORLD');
  print(model.text); // HELLO WORLD
  print(model.morseCode); // .... . .-.. .-.. --- / .-- --- .-. .-.. -..
  print('${model.events.length} events, ${model.totalDuration}ms');

  // 2. The same thing straight off a String.
  print('SOS'.toMorseString()); // ... --- ...

  // 3. The vibration pattern.
  //
  // Index 0 is an *off* delay and the list alternates off/on from there,
  // which is what Android's createWaveform and iOS both expect. Hand this
  // straight to Vibration.vibrate(pattern: ...).
  print('SOS'.toVibrationPattern()); // [0, 100, 100, 100, ...]

  // 4. Inspect the sequence symbolically.
  for (final event in 'SO'.toHapticEvents()) {
    final label = switch (event) {
      HapticDot() => 'dot',
      HapticDash() => 'dash',
      HapticSymbolGap() => 'symbol gap',
      HapticLetterGap() => 'letter gap',
      HapticWordGap() => 'word gap',
    };
    print('  $label — ${event.duration}ms');
  }

  // 5. Custom timings — a faster "fist".
  final fast = HapticMorse.custom(
    dotDuration: 80,
    dashDuration: 240,
    gapSymbolDuration: 80,
    gapLetterDuration: 240,
    gapWordDuration: 560,
  );
  print('SOS'.toVibrationPattern(fast));

  // 6. Custom alphabets, including emoji.
  //
  // Text is segmented into grapheme clusters, so multi-code-unit characters
  // count as one.
  final emoji = HapticMorse.custom(
    charMap: ['.-', '--'],
    charReference: '💧🔥',
  );
  print(emoji.convertTextToMorseString('💧🔥')); // .- --

  // 7. Misconfiguration fails loudly instead of silently dropping letters.
  try {
    HapticMorse.custom(charMap: ['.-'], charReference: 'ABC');
  } on ArgumentError catch (e) {
    print('rejected: ${e.message}');
  }

  // 8. Morse timing is defined in units, not milliseconds. The defaults are
  //    the ITU-R M.1677-1 ratios of 1/3/1/3/7, which put the standard word
  //    "PARIS" at exactly 50 units.
  const unit = 100; // the default dot duration
  final paris = 'PARIS'.toMorseModel().totalDuration;
  final twice = 'PARIS PARIS'.toMorseModel().totalDuration;
  final wordSpace = twice - 2 * paris;
  print('PARIS + space = ${(paris + wordSpace) ~/ unit} units'); // 50
  print('speed         = ${1200 ~/ unit} WPM'); // 12

  // 9. To actually vibrate (Android/iOS only):
  //
  //   import 'package:haptic_morse/haptic_morse_vibration.dart';
  //
  //   const haptics = HapticVibration();
  //
  //   // Check first: a haptic-only message is unreadable on a device that
  //   // cannot reproduce the timing. Fall back to the printed Morse.
  //   if (await haptics.hasCustomVibrationsSupport()) {
  //     await haptics.vibrateText('SOS');
  //   } else {
  //     print('SOS'.toMorseString());
  //   }
}
