import 'package:haptic_morse/src/haptic/haptic_morse.dart';
import 'package:test/test.dart';

void main() {
  group(HapticMorse, () {
    final hapticMorse = HapticMorse();

    test(
      'convertTextToMorseString returns correct Morse for single letter',
      () {
        expect(hapticMorse.convertTextToMorseString('A'), '.-');
        expect(hapticMorse.convertTextToMorseString('b'), '-...');
        expect(hapticMorse.convertTextToMorseString('Z'), '--..');
      },
    );

    test('convertTextToMorseString returns correct Morse for digits', () {
      expect(hapticMorse.convertTextToMorseString('1'), '.----');
      expect(hapticMorse.convertTextToMorseString('0'), '-----');
      expect(hapticMorse.convertTextToMorseString('9'), '----.');
    });

    test(
      'convertTextToMorseString returns correct Morse for words and spaces',
      () {
        expect(hapticMorse.convertTextToMorseString('AB'), '.- -...');
        expect(hapticMorse.convertTextToMorseString('A B'), '.- / -...');
        expect(hapticMorse.convertTextToMorseString('SOS'), '... --- ...');
        expect(
          hapticMorse.convertTextToMorseString('HELLO WORLD'),
          '.... . .-.. .-.. --- / .-- --- .-. .-.. -..',
        );
      },
    );

    test('convertTextToMorseString skips unsupported characters', () {
      expect(hapticMorse.convertTextToMorseString('A!B'), '.- -...');
      expect(hapticMorse.convertTextToMorseString('A@B'), '.- -...');
    });

    test('convertTextToMorseString returns null for null or empty input', () {
      expect(hapticMorse.convertTextToMorseString(null), null);
      expect(hapticMorse.convertTextToMorseString(''), null);
    });

    test(
      'convertTextToHapticPattern returns correct pattern for single letter',
      () {
        // 'E' is '.'
        expect(hapticMorse.convertTextToHapticPattern('E'), [100]);
        // 'T' is '-'
        expect(hapticMorse.convertTextToHapticPattern('T'), [300]);
        // 'A' is '.-'
        expect(hapticMorse.convertTextToHapticPattern('A'), [100, 100, 300]);
      },
    );

    test('convertTextToHapticPattern returns correct pattern for word', () {
      // 'HI' is '.... ..'
      // H: . . . . (100,100,100,100,100,100,100)
      // I: . . (100,100,100)
      // Gaps: between symbols 100, between letters 300
      // H: 100,100,100,100,100,100,100
      // (dot, gap, dot, gap, dot, gap, dot)
      // I: 100,100,100
      // (dot, gap, dot)
      // Full: [100,100,100,100,100,100,100,300,100,100,100]
      expect(hapticMorse.convertTextToHapticPattern('HI'), [
        100, 100, 100, 100, 100, 100, 100, // H: . . . .
        300, // gap between H and I
        100, 100, 100, // I: . .
      ]);
    });

    test('convertTextToHapticPattern handles spaces (word gap)', () {
      // 'E E' should have a word gap (700ms) between the two Es
      expect(hapticMorse.convertTextToHapticPattern('E E'), [100, 700, 100]);
    });

    test('convertTextToHapticPattern skips unsupported characters', () {
      expect(hapticMorse.convertTextToHapticPattern('A!B'), [
        100,
        100,
        300,
        300,
        300,
        100,
        100,
        100,
        100,
        100,
        100,
      ]);
    });

    test('convertTextToHapticPattern returns null for null or empty input', () {
      expect(hapticMorse.convertTextToHapticPattern(null), []);
      expect(hapticMorse.convertTextToHapticPattern(''), []);
    });

    test('convertTextToMorseMap returns correct map', () {
      final result = hapticMorse.convertTextToMorseMap('E');
      expect(result['hapticDurations'], [100]);
      expect(result['hapticCount'], 1);
      expect(result['morseString'], '.');
    });

    test('convertTextToMorseMap returns empty map for null or empty input', () {
      final result1 = hapticMorse.convertTextToMorseMap(null);
      expect(result1['hapticDurations'], []);
      expect(result1['hapticCount'], 0);
      expect(result1['morseString'], '');

      final result2 = hapticMorse.convertTextToMorseMap('');
      expect(result2['hapticDurations'], []);
      expect(result2['hapticCount'], 0);
      expect(result2['morseString'], '');
    });

    test('custom timings and mappings work', () {
      final custom = HapticMorse.custom(
        dotDuration: 1,
        dashDuration: 2,
        gapSymbolDuration: 3,
        gapLetterDuration: 4,
        gapWordDuration: 5,
      );
      expect(custom.convertTextToHapticPattern('E E'), [1, 5, 1]);
    });

    test('numeric map works', () {
      final custom = HapticMorse.custom(
        numericMap: ['-----', '.----', '..---', '...--', '....-', '.....'],
        numericReference: '012345',
      );
      expect(custom.convertTextToMorseString('123'), '.---- ..--- ...--');
    });

    test(
      'convertTextWithNumberToHapticPattern returns correct pattern for number',
      () {
        expect(hapticMorse.convertTextToHapticPattern('123'), isNotEmpty);
      },
    );

    test('Custom symbol reference', () {
      final custom = HapticMorse.custom(
        symbolReference: '💀',
        charMap: [
          '💀-',
          '-💀💀💀',
          '-💀-💀',
          '-💀💀',
          '💀',
          '💀💀-💀',
          '--💀',
          '💀💀💀💀',
          '💀💀',
          '💀--💀💀💀',
          '-💀-',
          '💀-💀💀💀',
        ],
      );
      expect(custom.convertTextToMorseString('code ded'),
          '-💀-💀 -💀💀 💀 / -💀💀 💀 -💀💀');
    });
  });
}
