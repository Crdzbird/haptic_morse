import 'package:haptic_morse/haptic_morse.dart';
import 'package:test/test.dart';

void main() {
  group('StringMorseExtension', () {
    test('toMorseString returns correct Morse code for "SOS"', () {
      final morse = 'SOS'.toMorseString();
      expect(morse, '... --- ...');
    });

    test('toMorseString returns correct Morse code for "HELLO WORLD"', () {
      final morse = 'HELLO WORLD'.toMorseString();
      expect(morse, '.... . .-.. .-.. --- / .-- --- .-. .-.. -..');
    });

    test('toHapticPattern returns a non-empty list for "A"', () {
      final pattern = 'A'.toHapticPattern();
      expect(pattern, isA<List<int>>());
      expect(pattern.isNotEmpty, true);
    });

    test('toMorseMap returns correct map structure for "E"', () {
      final map = 'E'.toMorseMap();
      expect(map, isA<HapticModel>());
      expect(map.hapticDurations, isNotEmpty);
      expect(map.morseCode, isNotEmpty);
      expect(map.text, isNotEmpty);
    });

    test('toMorseString returns null for empty string', () {
      final morse = ''.toMorseString();
      expect(morse, isNull);
    });

    test('toHapticPattern returns empty list for empty string', () {
      final pattern = ''.toHapticPattern();
      expect(pattern, isEmpty);
    });

    test('toMorseMap returns expected values for "123"', () {
      final map = '123'.toMorseMap();
      expect(map.text, isNotEmpty);
      expect(map.hapticDurations, isNotEmpty);
      expect(map.morseCode, isNotEmpty);
    });

    test('Custom parameters are passed through', () {
      final morse = 'A'.toMorseString(
        symbolReference: '*',
        charMap: ['*-'],
      );
      // Should use '*' for dot and '_' for dash
      expect(morse, '*-');
    });
  });
}
