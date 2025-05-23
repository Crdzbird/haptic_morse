import 'package:haptic_morse/src/extension/string_morse_extension.dart';
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
      expect(map, isA<Map<String, dynamic>>());
      expect(map.containsKey('hapticDurations'), true);
      expect(map.containsKey('hapticCount'), true);
      expect(map.containsKey('morseString'), true);
      expect(map['morseString'], '.');
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
      expect(map['morseString'], '.---- ..--- ...--');
      expect(map['hapticDurations'], isA<List<int>>());
      expect(map['hapticCount'], isA<int>());
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
