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

  // 8. Punctuation is part of the standard table.
  print('HELLO, WORLD!'.toMorseString());

  // 9. Accented letters are opt-in.
  final accented = HapticMorse.custom(
    additionalSymbols: HapticMorse.accentedLetters,
  );
  print(accented.convertTextToMorseString('MAÑANA')); // ends with --.-- for Ñ

  // 10. Decoding, from either representation.
  print(morse.decodeMorseString('... --- ...')); // SOS
  print(morse.decodeEvents('HELLO, WORLD!'.toHapticEvents()));

  // 11. Speed in words per minute. One unit is 1200/WPM milliseconds, so the
  //     standard word "PARIS" plus a word space measures exactly 50 units.
  final fast20 = HapticMorse.atSpeed(wordsPerMinute: 20);
  print(
      '20 WPM dot = ${fast20.convertTextToHapticEvents('E').single.duration}ms');

  // 12. Farnsworth timing: crisp characters, stretched gaps. This is how you
  //     make Morse readable through skin without distorting each character.
  final learner = HapticMorse.atSpeed(
    wordsPerMinute: 20, // character speed
    effectiveWordsPerMinute: 8, // overall speed
  );
  final plainGap = fast20.convertTextToHapticEvents('EE')[1].duration;
  final learnerGap = learner.convertTextToHapticEvents('EE')[1].duration;
  print('letter gap: ${plainGap}ms standard vs ${learnerGap}ms Farnsworth');

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
