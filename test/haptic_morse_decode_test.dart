import 'package:haptic_morse/haptic_morse.dart';
import 'package:test/test.dart';

void main() {
  const morse = HapticMorse();

  group('decodeMorseString', () {
    test('decodes letters, digits, and punctuation', () {
      expect(morse.decodeMorseString('... --- ...'), 'SOS');
      expect(morse.decodeMorseString('.---- ..--- ...--'), '123');
      expect(morse.decodeMorseString('..--..'), '?');
    });

    test('decodes words', () {
      expect(
        morse.decodeMorseString('.... . .-.. .-.. --- / .-- --- .-. .-.. -..'),
        'HELLO WORLD',
      );
    });

    test('is the inverse of convertTextToMorseString', () {
      const samples = [
        'SOS',
        'HELLO WORLD',
        'PARIS',
        'THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG',
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        '0123456789',
        'HELLO, WORLD!',
        'E=MC2',
        'A/B (C) D',
        r'COST: $5.00',
        'USER@EXAMPLE.COM',
      ];

      for (final sample in samples) {
        expect(
          morse.decodeMorseString(morse.convertTextToMorseString(sample)),
          sample,
          reason: 'round trip failed for "$sample"',
        );
      }
    });

    test('normalizes case, because Morse does not carry it', () {
      expect(morse.decodeMorseString('hello'.toMorseString()), 'HELLO');
    });

    test('collapses whitespace the way encoding does', () {
      expect(morse.decodeMorseString('...   ---   ...'), 'SOS');
      expect(morse.decodeMorseString('  ... --- ...  '), 'SOS');
    });

    test('skips patterns it does not recognize', () {
      // '........' is not a valid code; the rest still decodes.
      expect(morse.decodeMorseString('... ........ ...'), 'SS');
    });

    test('returns null when nothing can be decoded', () {
      expect(morse.decodeMorseString(null), isNull);
      expect(morse.decodeMorseString(''), isNull);
      expect(morse.decodeMorseString('   '), isNull);
      expect(morse.decodeMorseString('........'), isNull);
    });

    test("uses the encoder's own alphabet", () {
      final binary = HapticMorse.custom(
        symbolReference: '0',
        dashReference: '1',
      );

      expect(binary.decodeMorseString('000 111 000'), 'SOS');
      // The standard spelling is meaningless to this encoder.
      expect(binary.decodeMorseString('... --- ...'), isNull);
    });

    test('decodes a custom alphabet', () {
      final custom = HapticMorse.custom(
        charMap: const ['.-', '--'],
        charReference: '💧🔥',
      );

      expect(custom.decodeMorseString('.- --'), '💧🔥');
    });
  });

  group('decodeEvents', () {
    test('round-trips through the haptic sequence', () {
      const samples = [
        'SOS',
        'HELLO WORLD',
        'THE QUICK BROWN FOX',
        '0123456789',
        'HELLO, WORLD!',
      ];

      for (final sample in samples) {
        expect(
          morse.decodeEvents(morse.convertTextToHapticEvents(sample)),
          sample,
          reason: 'round trip failed for "$sample"',
        );
      }
    });

    test('needs no threshold guessing — the events are already typed', () {
      // Durations are deliberately absurd; the event *types* carry the
      // structure, so decoding is exact regardless.
      const events = <HapticEvent>[
        HapticDot(1),
        HapticSymbolGap(9999),
        HapticDash(2),
        HapticLetterGap(1),
        HapticDot(5000),
      ];

      expect(morse.decodeEvents(events), 'AE');
    });

    test('word gaps become spaces', () {
      expect(morse.decodeEvents('E E'.toHapticEvents()), 'E E');
    });

    test('returns null for an empty sequence', () {
      expect(morse.decodeEvents(const []), isNull);
    });

    test('agrees with decodeMorseString', () {
      const input = 'HELLO WORLD 123';
      final model = morse.convertTextToModel(input);

      expect(morse.decodeEvents(model.events), input);
      expect(morse.decodeMorseString(model.morseCode), input);
    });
  });

  group('lossy cases are documented', () {
    test('a shared pattern decodes to the first character', () {
      final accented = HapticMorse.custom(
        additionalSymbols: HapticMorse.accentedLetters,
      );

      // À and Å share '.--.-'; encoding both works, decoding picks one.
      expect(accented.convertTextToMorseString('À'), '.--.-');
      expect(accented.convertTextToMorseString('Å'), '.--.-');
      expect(accented.decodeMorseString('.--.-'), 'À');
    });
  });
}
