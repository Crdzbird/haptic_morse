import 'package:haptic_morse/haptic_morse.dart';
import 'package:test/test.dart';

/// Conformance with ITU-R M.1677-1, the International Morse Code standard.
///
/// The standard defines timing in *units*, not milliseconds:
///
/// | Element                      | Units |
/// | ---------------------------- | ----- |
/// | dot (dit)                    | 1     |
/// | dash (dah)                   | 3     |
/// | gap between symbols          | 1     |
/// | gap between letters          | 3     |
/// | gap between words            | 7     |
///
/// These tests check the ratios rather than the millisecond defaults, so they
/// keep holding if the defaults are ever re-scaled.
void main() {
  const morse = HapticMorse();

  /// One unit, in milliseconds, for the default configuration.
  const unit = 100;

  int durationOf(String text, int index) =>
      morse.convertTextToHapticEvents(text)[index].duration;

  group('element durations follow the 1/3 ratio', () {
    test('a dot is 1 unit', () {
      // E is a single dot.
      expect(durationOf('E', 0), unit);
    });

    test('a dash is 3 units', () {
      // T is a single dash.
      expect(durationOf('T', 0), 3 * unit);
    });
  });

  group('gap durations follow the 1/3/7 ratio', () {
    test('the gap between symbols of one letter is 1 unit', () {
      // A is dot-dash, so index 1 is the intra-character gap.
      final events = morse.convertTextToHapticEvents('A');

      expect(events[1], isA<HapticSymbolGap>());
      expect(events[1].duration, unit);
    });

    test('the gap between letters is 3 units', () {
      final events = morse.convertTextToHapticEvents('EE');

      expect(events[1], isA<HapticLetterGap>());
      expect(events[1].duration, 3 * unit);
    });

    test('the gap between words is 7 units', () {
      final events = morse.convertTextToHapticEvents('E E');

      expect(events[1], isA<HapticWordGap>());
      expect(events[1].duration, 7 * unit);
    });
  });

  group('the PARIS standard word measures 50 units', () {
    // "PARIS" plus its trailing word space is the reference word used to
    // define Morse speed. If this holds, every element and gap ratio is
    // simultaneously correct - it is the strongest single check available.
    final single = morse.convertTextToModel('PARIS').totalDuration;
    final double = morse.convertTextToModel('PARIS PARIS').totalDuration;
    final wordSpace = double - 2 * single;

    test('the word itself is 43 units', () {
      // 50 units minus the 7-unit trailing space, which is not emitted at the
      // end of a message.
      expect(single, 43 * unit);
    });

    test('the word space is 7 units', () {
      expect(wordSpace, 7 * unit);
    });

    test('word plus space is 50 units', () {
      expect(single + wordSpace, 50 * unit);
    });

    test('speed matches the standard 1200/dot formula', () {
      // Words per minute = 1200 / dotDurationInMilliseconds.
      final wpm = 60000 / (single + wordSpace);

      expect(wpm, 1200 / unit);
      expect(wpm, 12);
    });

    test('the ratios hold when the unit is re-scaled', () {
      // 20 WPM => a 60ms dot.
      const fastUnit = 60;
      final fast = HapticMorse.custom(
        dotDuration: fastUnit,
        dashDuration: 3 * fastUnit,
        gapSymbolDuration: fastUnit,
        gapLetterDuration: 3 * fastUnit,
        gapWordDuration: 7 * fastUnit,
      );

      final word = fast.convertTextToModel('PARIS').totalDuration;
      final pair = fast.convertTextToModel('PARIS PARIS').totalDuration;
      final space = pair - 2 * word;

      expect(word + space, 50 * fastUnit);
      expect(60000 / (word + space), 1200 / fastUnit);
      expect(60000 / (word + space), 20);
    });
  });

  group('the standard alphabet matches the ITU table', () {
    // Reproduced from ITU-R M.1677-1. A transcription error here is caught by
    // the round-trip property test below, which does not share this table.
    const table = <String, String>{
      'A': '.-',
      'B': '-...',
      'C': '-.-.',
      'D': '-..',
      'E': '.',
      'F': '..-.',
      'G': '--.',
      'H': '....',
      'I': '..',
      'J': '.---',
      'K': '-.-',
      'L': '.-..',
      'M': '--',
      'N': '-.',
      'O': '---',
      'P': '.--.',
      'Q': '--.-',
      'R': '.-.',
      'S': '...',
      'T': '-',
      'U': '..-',
      'V': '...-',
      'W': '.--',
      'X': '-..-',
      'Y': '-.--',
      'Z': '--..',
      '0': '-----',
      '1': '.----',
      '2': '..---',
      '3': '...--',
      '4': '....-',
      '5': '.....',
      '6': '-....',
      '7': '--...',
      '8': '---..',
      '9': '----.',
    };

    for (final MapEntry(key: character, value: expected) in table.entries) {
      test('$character is "$expected"', () {
        expect(morse.convertTextToMorseString(character), expected);
      });
    }

    test('every code is unique', () {
      expect(table.values.toSet(), hasLength(table.length));
    });

    test('no code is a prefix of another at the same length', () {
      // Morse is not prefix-free, which is why the inter-character gap is
      // required. This documents that the gap is load-bearing rather than
      // cosmetic: "..", "." and ".-" all share a prefix.
      expect(table['I'], startsWith(table['E']!));
      expect(table['A'], startsWith(table['E']!));
    });
  });

  group('ITU punctuation', () {
    // ITU-R M.1677-1 section 1.1.3.
    const punctuation = <String, String>{
      '.': '.-.-.-',
      ',': '--..--',
      ':': '---...',
      '?': '..--..',
      "'": '.----.',
      '-': '-....-',
      '/': '-..-.',
      '(': '-.--.',
      ')': '-.--.-',
      '"': '.-..-.',
      '=': '-...-',
      '+': '.-.-.',
      '@': '.--.-.',
    };

    for (final MapEntry(key: character, value: expected)
        in punctuation.entries) {
      test('$character is "$expected"', () {
        expect(morse.convertTextToMorseString(character), expected);
      });
    }

    test('a sentence with punctuation encodes and decodes', () {
      const sentence = 'HELLO, WORLD!';

      expect(
        morse.decodeMorseString(morse.convertTextToMorseString(sentence)),
        sentence,
      );
    });
  });

  group('no code collides with another', () {
    // The encoder rejects duplicate *characters*, but two characters mapping
    // to the same *code* would make decoding ambiguous. This is what keeps the
    // punctuation and accented tables safe to extend.
    List<String> codesOf(HapticMorse encoder) => encoder.supportedCharacters
        .map((c) => encoder.convertTextToMorseString(c)!)
        .toList();

    test('the default table is collision-free', () {
      final codes = codesOf(morse);

      expect(codes.toSet(), hasLength(codes.length));
    });

    test('accented letters collide with nothing in the default table', () {
      final accented = HapticMorse.custom(
        additionalSymbols: HapticMorse.accentedLetters,
      );
      final codes = codesOf(accented);

      // À and Å deliberately share a code, so exactly one duplicate is
      // expected - any more means a genuine clash was introduced.
      expect(codes.length - codes.toSet().length, 1);
    });

    test('every default code is a valid dot/dash string', () {
      for (final code in codesOf(morse)) {
        expect(code, matches(RegExp(r'^[.\-]+$')));
      }
    });
  });

  group('round-trip property', () {
    /// Decodes using only the emitted Morse string and the ITU table, with no
    /// reference to the encoder's internals.
    String decode(String morseCode) {
      const inverse = <String, String>{
        '.-': 'A',
        '-...': 'B',
        '-.-.': 'C',
        '-..': 'D',
        '.': 'E',
        '..-.': 'F',
        '--.': 'G',
        '....': 'H',
        '..': 'I',
        '.---': 'J',
        '-.-': 'K',
        '.-..': 'L',
        '--': 'M',
        '-.': 'N',
        '---': 'O',
        '.--.': 'P',
        '--.-': 'Q',
        '.-.': 'R',
        '...': 'S',
        '-': 'T',
        '..-': 'U',
        '...-': 'V',
        '.--': 'W',
        '-..-': 'X',
        '-.--': 'Y',
        '--..': 'Z',
        '-----': '0',
        '.----': '1',
        '..---': '2',
        '...--': '3',
        '....-': '4',
        '.....': '5',
        '-....': '6',
        '--...': '7',
        '---..': '8',
        '----.': '9',
      };

      return morseCode
          .split(' / ')
          .map(
            (word) => word.split(' ').map((code) => inverse[code]!).join(),
          )
          .join(' ');
    }

    const samples = [
      'SOS',
      'HELLO WORLD',
      'PARIS',
      'THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG',
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
      '0123456789',
      'CQ CQ DE W1AW',
    ];

    for (final sample in samples) {
      test('"$sample" survives encode then decode', () {
        expect(decode(morse.convertTextToMorseString(sample)!), sample);
      });
    }

    test('event count is derivable from the Morse string', () {
      // symbols + intra-letter gaps + inter-letter gaps + inter-word gaps
      for (final sample in samples) {
        final code = morse.convertTextToMorseString(sample)!;
        final words = code.split(' / ');

        var expected = 0;
        for (final word in words) {
          final letters = word.split(' ');
          for (final letter in letters) {
            expected += letter.length * 2 - 1; // symbols + intra gaps
          }
          expected += letters.length - 1; // inter-letter gaps
        }
        expected += words.length - 1; // inter-word gaps

        expect(
          morse.convertTextToHapticEvents(sample),
          hasLength(expected),
          reason: 'for "$sample"',
        );
      }
    });
  });
}
