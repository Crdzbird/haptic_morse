import 'package:haptic_morse/haptic_morse.dart';
import 'package:test/test.dart';

/// Asserts the sequence contract documented on [HapticEvent].
///
/// Every boundary bug fixed in 2.0.0 was a violation of one of these clauses,
/// so this runs over every generated sequence in the suite.
void expectWellFormed(List<HapticEvent> events, {String? reason}) {
  final because = reason == null ? '' : ' ($reason)';
  if (events.isEmpty) return;

  expect(
    events.first.isVibration,
    isTrue,
    reason: 'sequence must start with a vibration$because',
  );
  expect(
    events.last.isVibration,
    isTrue,
    reason: 'sequence must end with a vibration$because',
  );

  for (var i = 1; i < events.length; i++) {
    expect(
      events[i].isVibration,
      isNot(events[i - 1].isVibration),
      reason: 'events $i and ${i - 1} share a phase$because: $events',
    );
  }

  for (final event in events) {
    expect(
      event.duration,
      greaterThan(0),
      reason: 'every event must have a positive duration$because',
    );
  }
}

void main() {
  const morse = HapticMorse();

  group('convertTextToMorseString', () {
    test('encodes single letters, case-insensitively', () {
      expect(morse.convertTextToMorseString('A'), '.-');
      expect(morse.convertTextToMorseString('b'), '-...');
      expect(morse.convertTextToMorseString('Z'), '--..');
    });

    test('encodes digits', () {
      expect(morse.convertTextToMorseString('0'), '-----');
      expect(morse.convertTextToMorseString('1'), '.----');
      expect(morse.convertTextToMorseString('9'), '----.');
    });

    test('encodes words and separates them with " / "', () {
      expect(morse.convertTextToMorseString('AB'), '.- -...');
      expect(morse.convertTextToMorseString('A B'), '.- / -...');
      expect(morse.convertTextToMorseString('SOS'), '... --- ...');
      expect(
        morse.convertTextToMorseString('HELLO WORLD'),
        '.... . .-.. .-.. --- / .-- --- .-. .-.. -..',
      );
    });

    test('skips unsupported characters', () {
      expect(morse.convertTextToMorseString('A!B'), '.- -...');
      expect(morse.convertTextToMorseString('A@B'), '.- -...');
    });

    test('collapses whitespace runs into a single word separator', () {
      expect(morse.convertTextToMorseString('A  B'), '.- / -...');
      expect(morse.convertTextToMorseString('A\t\nB'), '.- / -...');
      expect(morse.convertTextToMorseString('  A B  '), '.- / -...');
    });

    test('drops words made entirely of unsupported characters', () {
      expect(morse.convertTextToMorseString('A !! B'), '.- / -...');
    });

    test('returns null when there is nothing to encode', () {
      expect(morse.convertTextToMorseString(null), isNull);
      expect(morse.convertTextToMorseString(''), isNull);
      expect(morse.convertTextToMorseString('   '), isNull);
      expect(morse.convertTextToMorseString('!!!'), isNull);
    });
  });

  group('convertTextToHapticEvents', () {
    test('single letters', () {
      expect(morse.convertTextToHapticEvents('E'), [const HapticDot(100)]);
      expect(morse.convertTextToHapticEvents('T'), [const HapticDash(300)]);
      expect(morse.convertTextToHapticEvents('A'), [
        const HapticDot(100),
        const HapticSymbolGap(100),
        const HapticDash(300),
      ]);
    });

    test('letters within a word are separated by a letter gap', () {
      expect(morse.convertTextToHapticEvents('EE'), [
        const HapticDot(100),
        const HapticLetterGap(300),
        const HapticDot(100),
      ]);
    });

    test('words are separated by a word gap', () {
      expect(morse.convertTextToHapticEvents('E E'), [
        const HapticDot(100),
        const HapticWordGap(700),
        const HapticDot(100),
      ]);
    });

    test('returns empty when there is nothing to encode', () {
      expect(morse.convertTextToHapticEvents(null), isEmpty);
      expect(morse.convertTextToHapticEvents(''), isEmpty);
      expect(morse.convertTextToHapticEvents('   '), isEmpty);
      expect(morse.convertTextToHapticEvents('!!!'), isEmpty);
    });

    test('the result is unmodifiable', () {
      expect(
        () => morse.convertTextToHapticEvents('E').add(const HapticDot(1)),
        throwsUnsupportedError,
      );
    });

    group('sequence stays well formed at every boundary', () {
      // Each of these produced a malformed sequence before 2.0.0.
      const cases = <String, String>{
        'E': 'single symbol',
        'SOS': 'multi-letter word',
        'HELLO WORLD': 'multiple words',
        'AB!': 'trailing unsupported character',
        '!AB': 'leading unsupported character',
        '  AB': 'leading whitespace',
        'AB  ': 'trailing whitespace',
        'A  B': 'doubled space',
        'A   B': 'tripled space',
        'A!B': 'interior unsupported character',
        'A !! B': 'word of only unsupported characters',
        ' A ! B ': 'whitespace and unsupported characters combined',
        '123': 'digits',
      };

      cases.forEach((input, description) {
        test('"$input" — $description', () {
          expectWellFormed(
            morse.convertTextToHapticEvents(input),
            reason: description,
          );
        });
      });
    });

    test('a trailing unsupported character adds no dangling gap', () {
      expect(
        morse.convertTextToHapticEvents('AB!'),
        morse.convertTextToHapticEvents('AB'),
      );
    });

    test('leading whitespace adds no spurious word gap', () {
      expect(
        morse.convertTextToHapticEvents('  AB'),
        morse.convertTextToHapticEvents('AB'),
      );
    });

    test('doubled spaces produce exactly one word gap', () {
      final single = morse.convertTextToHapticEvents('A B');
      expect(morse.convertTextToHapticEvents('A  B'), single);
      expect(morse.convertTextToHapticEvents('A   B'), single);
      expect(single.whereType<HapticWordGap>(), hasLength(1));
    });

    test('an all-unsupported word does not add a second word gap', () {
      expect(
        morse.convertTextToHapticEvents('A !! B'),
        morse.convertTextToHapticEvents('A B'),
      );
    });
  });

  group('convertTextToModel', () {
    test('carries text, morse, and events together', () {
      final model = morse.convertTextToModel('SOS');

      expect(model.text, 'SOS');
      expect(model.morseCode, '... --- ...');
      expect(model.events, morse.convertTextToHapticEvents('SOS'));
      expect(model.toVibrationPattern(), 'SOS'.toVibrationPattern());
    });

    test('returns an empty model when there is nothing to encode', () {
      expect(morse.convertTextToModel(null), const HapticModel());
      expect(morse.convertTextToModel(''), const HapticModel());
      expect(morse.convertTextToModel('!!!'), const HapticModel());
    });

    test('totalDuration sums every event', () {
      final model = morse.convertTextToModel('A');

      // dot + symbol gap + dash
      expect(model.totalDuration, 100 + 100 + 300);
    });
  });

  group('custom configuration', () {
    test('custom timings', () {
      final custom = HapticMorse.custom(
        dotDuration: 1,
        dashDuration: 2,
        gapSymbolDuration: 3,
        gapLetterDuration: 4,
        gapWordDuration: 5,
      );

      expect(custom.convertTextToHapticEvents('E E'), [
        const HapticDot(1),
        const HapticWordGap(5),
        const HapticDot(1),
      ]);
      expectWellFormed(custom.convertTextToHapticEvents('HELLO WORLD'));
    });

    test('partial customization keeps the standard alphabet', () {
      final custom = HapticMorse.custom(dotDuration: 80);

      expect(custom.convertTextToMorseString('SOS'), '... --- ...');
    });

    test('custom numeric map', () {
      final custom = HapticMorse.custom(
        numericMap: ['-----', '.----', '..---', '...--', '....-', '.....'],
        numericReference: '012345',
      );

      expect(custom.convertTextToMorseString('123'), '.---- ..--- ...--');
    });

    test('numeric reference takes precedence over the alphabet on overlap', () {
      final custom = HapticMorse.custom(
        numericReference: 'A',
        numericMap: ['-----'],
      );

      expect(custom.convertTextToMorseString('A'), '-----');
    });

    test('custom lookups are case-insensitive', () {
      final custom = HapticMorse.custom(
        numericReference: 'ab',
        numericMap: ['---', '...'],
      );

      expect(custom.convertTextToMorseString('a'), '---');
      expect(custom.convertTextToMorseString('A'), '---');
      expect(custom.convertTextToMorseString('B'), '...');
    });

    test('a reference character that is a regex metacharacter is literal', () {
      final custom = HapticMorse.custom(
        numericReference: r'.$',
        numericMap: ['-', '..'],
      );

      expect(custom.convertTextToMorseString(r'.'), '-');
      expect(custom.convertTextToMorseString(r'$'), '..');
      // Must not match every character the way an unescaped '.' pattern did.
      expect(custom.convertTextToMorseString('Z'), '--..');
    });

    test('custom dot and dash symbols', () {
      final custom = HapticMorse.custom(
        symbolReference: '0',
        dashReference: '1',
        charMap: ['01', '1000'],
        charReference: 'AB',
      );

      expect(custom.convertTextToMorseString('AB'), '01 1000');
      expect(custom.convertTextToHapticEvents('A'), [
        const HapticDot(100),
        const HapticSymbolGap(100),
        const HapticDash(300),
      ]);
    });
  });

  group('grapheme handling', () {
    test('non-BMP characters work in a reference', () {
      final custom = HapticMorse.custom(
        charMap: ['.-', '--'],
        charReference: '💧🔥',
      );

      // Previously each emoji was split into two surrogate halves and
      // resolved as two separate letters.
      expect(custom.convertTextToMorseString('💧'), '.-');
      expect(custom.convertTextToMorseString('🔥'), '--');
      expect(custom.convertTextToMorseString('💧🔥'), '.- --');
      expect(custom.convertTextToHapticEvents('💧'), [
        const HapticDot(100),
        const HapticSymbolGap(100),
        const HapticDash(300),
      ]);
    });

    test('emoji with a variation selector count as one character', () {
      final custom = HapticMorse.custom(
        charMap: ['.-'],
        charReference: '☀️',
      );

      expect(custom.convertTextToMorseString('☀️'), '.-');
    });

    test('zero-width-joiner sequences count as one character', () {
      final custom = HapticMorse.custom(
        charMap: ['-.-'],
        charReference: '👩‍👩‍👧',
      );

      expect(custom.convertTextToMorseString('👩‍👩‍👧'), '-.-');
    });

    test('BMP scripts keep working', () {
      final custom = HapticMorse.custom(
        charMap: ['.-', '-...', '..--', '.-.-'],
        charReference: 'AB日水',
      );

      expect(custom.convertTextToMorseString('AB日水'), '.- -... ..-- .-.-');
    });
  });
}
