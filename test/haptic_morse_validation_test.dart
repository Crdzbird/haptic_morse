import 'package:haptic_morse/haptic_morse.dart';
import 'package:test/test.dart';

/// `HapticMorse.custom` rejects inconsistent configuration at construction.
///
/// Before 2.0.0 every one of these either produced silently wrong output or
/// threw much later, from inside a conversion call.
void main() {
  group('map and reference must line up', () {
    test('charMap shorter than charReference', () {
      // Previously 'C' was silently dropped from all output.
      expect(
        () => HapticMorse.custom(charMap: ['.-'], charReference: 'ABC'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            allOf(contains('charMap'), contains('charReference')),
          ),
        ),
      );
    });

    test('charMap longer than charReference', () {
      expect(
        () => HapticMorse.custom(
          charMap: ['.-', '-...', '-.-.'],
          charReference: 'AB',
        ),
        throwsArgumentError,
      );
    });

    test('numericMap and numericReference must match too', () {
      expect(
        () => HapticMorse.custom(
          numericMap: ['-----'],
          numericReference: '01',
        ),
        throwsArgumentError,
      );
    });

    test('a reference counts graphemes, not code units', () {
      // '💧🔥' is two characters but four UTF-16 code units; a two-entry map
      // must be accepted.
      expect(
        () => HapticMorse.custom(
          charMap: ['.-', '--'],
          charReference: '💧🔥',
        ),
        returnsNormally,
      );
    });
  });

  group('references must not repeat a character', () {
    test('duplicate character', () {
      expect(
        () => HapticMorse.custom(charMap: ['.-', '--'], charReference: 'AA'),
        throwsArgumentError,
      );
    });

    test('duplicate differing only in case', () {
      expect(
        () => HapticMorse.custom(charMap: ['.-', '--'], charReference: 'aA'),
        throwsArgumentError,
      );
    });
  });

  group('patterns must be spelled with the dot and dash symbols', () {
    test('rejects a stray character', () {
      expect(
        () => HapticMorse.custom(charMap: ['.x'], charReference: 'A'),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.message, 'message', contains('x')),
        ),
      );
    });

    test('rejects emoji in a pattern when they are not the configured symbols',
        () {
      // Previously '💧💧' silently became four dashes.
      expect(
        () => HapticMorse.custom(charMap: ['💧💧'], charReference: 'A'),
        throwsArgumentError,
      );
    });

    test('accepts emoji when they are the configured symbols', () {
      final custom = HapticMorse.custom(
        symbolReference: '💧',
        dashReference: '🔥',
        charMap: ['💧🔥'],
        charReference: 'A',
      );

      expect(custom.convertTextToHapticEvents('A'), [
        const HapticDot(100),
        const HapticSymbolGap(100),
        const HapticDash(300),
      ]);
    });

    test('rejects an empty pattern', () {
      expect(
        () => HapticMorse.custom(charMap: [''], charReference: 'A'),
        throwsArgumentError,
      );
    });
  });

  group('symbol and dash references', () {
    test('must be a single character', () {
      expect(
        () => HapticMorse.custom(symbolReference: '..'),
        throwsArgumentError,
      );
      expect(
        () => HapticMorse.custom(dashReference: '--'),
        throwsArgumentError,
      );
      expect(
        () => HapticMorse.custom(symbolReference: ''),
        throwsArgumentError,
      );
    });

    test('a single emoji is one character', () {
      expect(
        () => HapticMorse.custom(
          symbolReference: '💧',
          charMap: ['💧'],
          charReference: 'A',
        ),
        returnsNormally,
      );
    });

    test('must differ from each other', () {
      expect(
        () => HapticMorse.custom(symbolReference: '.', dashReference: '.'),
        throwsArgumentError,
      );
    });
  });

  group('durations must be positive', () {
    test('zero is rejected', () {
      expect(
        () => HapticMorse.custom(dotDuration: 0),
        throwsArgumentError,
      );
    });

    test('negative is rejected', () {
      for (final build in <HapticMorse Function()>[
        () => HapticMorse.custom(dotDuration: -1),
        () => HapticMorse.custom(dashDuration: -1),
        () => HapticMorse.custom(gapSymbolDuration: -1),
        () => HapticMorse.custom(gapLetterDuration: -1),
        () => HapticMorse.custom(gapWordDuration: -1),
      ]) {
        expect(build, throwsArgumentError);
      }
    });
  });

  test('the default constructor is const and needs no validation', () {
    const a = HapticMorse();
    const b = HapticMorse();

    expect(identical(a, b), isTrue);
    expect(a.convertTextToMorseString('SOS'), '... --- ...');
  });
}
