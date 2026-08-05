// ignore_for_file: avoid_print

import 'package:haptic_morse/haptic_morse.dart';

void main() {
  // 1. Standard International Morse Code.
  final morse = HapticMorse();

  final model = morse.convertTextToMorseMap('HELLO WORLD');
  print(model.text); // HELLO WORLD
  print(model.morseCode); // .... . .-.. .-.. --- / .-- --- .-. .-.. -..
  print(model.hapticDurations); // [100, 100, 100, ...]

  // 2. The same thing straight off a String.
  print('SOS'.toMorseString()); // ... --- ...
  print('SOS'.toHapticPattern()); // [100, 100, 100, ...]

  // 3. Custom timings — a faster "fist".
  final fast = HapticMorse.custom(
    dotDuration: 80,
    dashDuration: 240,
    gapSymbolDuration: 80,
    gapLetterDuration: 240,
    gapWordDuration: 560,
  );
  print(fast.convertTextToHapticPattern('SOS'));

  // 4. Custom character mappings.
  //
  // Every character in charReference must be a single UTF-16 code unit.
  // Kanji qualify; emoji outside the Basic Multilingual Plane do not.
  final custom = HapticMorse.custom(
    charMap: ['.-', '-...', '..--', '.-.-'],
    charReference: 'AB日水',
  );
  print(custom.convertTextToMorseString('AB日水')); // .- -... ..-- .-.-

  // 5. HapticModel is a value type: equal content compares equal.
  print(morse.convertTextToMorseMap('SOS') == 'SOS'.toMorseMap()); // true

  // 6. To actually vibrate (Android/iOS only), hand the pattern to
  //    HapticVibration. See the README for the leading-zero caveat that
  //    version 2.0.0 will fix.
  //
  //    const haptics = HapticVibration();
  //    await haptics.vibrate(pattern: [0, ...'SOS'.toHapticPattern()]);
}
