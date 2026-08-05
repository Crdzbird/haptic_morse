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

  // 8. To actually vibrate (Android/iOS only):
  //
  //   import 'package:haptic_morse/haptic_morse_vibration.dart';
  //
  //   const haptics = HapticVibration();
  //   await haptics.vibrateText('SOS');
}
