import 'package:haptic_morse/haptic_morse.dart';
import 'package:test/test.dart';

/// `HapticMorse.atSpeed` expresses timing in words per minute.
///
/// Speed is defined by the standard word `PARIS` plus one word space, which
/// measures 50 units. Every test here measures that duration rather than
/// inspecting individual durations, so it verifies the property callers
/// actually care about.
void main() {
  /// Milliseconds for one `PARIS` plus the following word space.
  int wordDuration(HapticMorse morse) {
    final single = morse.convertTextToModel('PARIS').totalDuration;
    final pair = morse.convertTextToModel('PARIS PARIS').totalDuration;
    return pair - single; // one word plus one word space
  }

  /// Measured words per minute.
  double speedOf(HapticMorse morse) => 60000 / wordDuration(morse);

  group('standard timing', () {
    for (final wpm in [5, 12, 13, 20, 25, 40]) {
      test('$wpm WPM produces a 50-unit standard word', () {
        final morse = HapticMorse.atSpeed(wordsPerMinute: wpm);

        expect(
          speedOf(morse),
          closeTo(wpm, 0.35),
          reason: 'measured speed should match the requested speed',
        );
      });
    }

    test('matches the 1200/dot rule', () {
      final morse = HapticMorse.atSpeed(wordsPerMinute: 20);

      // A 20 WPM dot is 60ms.
      expect(morse.convertTextToHapticEvents('E').single.duration, 60);
    });

    test('keeps the standard 1/3/1/3/7 ratios', () {
      final morse = HapticMorse.atSpeed(wordsPerMinute: 20);
      const unit = 60;

      expect(morse.convertTextToHapticEvents('E').single.duration, unit);
      expect(morse.convertTextToHapticEvents('T').single.duration, 3 * unit);
      expect(morse.convertTextToHapticEvents('A')[1].duration, unit);
      expect(morse.convertTextToHapticEvents('EE')[1].duration, 3 * unit);
      expect(morse.convertTextToHapticEvents('E E')[1].duration, 7 * unit);
    });

    test('the default constructor is 12 WPM', () {
      expect(speedOf(const HapticMorse()), closeTo(12, 0.01));
      expect(
        wordDuration(const HapticMorse()),
        wordDuration(HapticMorse.atSpeed(wordsPerMinute: 12)),
      );
    });
  });

  group('Farnsworth timing', () {
    test('symbols stay at the character speed', () {
      final morse = HapticMorse.atSpeed(
        wordsPerMinute: 20,
        effectiveWordsPerMinute: 8,
      );

      // Dot and dash are unchanged from plain 20 WPM.
      expect(morse.convertTextToHapticEvents('E').single.duration, 60);
      expect(morse.convertTextToHapticEvents('T').single.duration, 180);
      expect(morse.convertTextToHapticEvents('A')[1].duration, 60);
    });

    test('only the letter and word gaps stretch', () {
      final plain = HapticMorse.atSpeed(wordsPerMinute: 20);
      final farnsworth = HapticMorse.atSpeed(
        wordsPerMinute: 20,
        effectiveWordsPerMinute: 8,
      );

      expect(
        farnsworth.convertTextToHapticEvents('EE')[1].duration,
        greaterThan(plain.convertTextToHapticEvents('EE')[1].duration),
      );
      expect(
        farnsworth.convertTextToHapticEvents('E E')[1].duration,
        greaterThan(plain.convertTextToHapticEvents('E E')[1].duration),
      );
    });

    test('overall speed matches the effective speed', () {
      for (final (character, effective) in [
        (20, 8),
        (20, 10),
        (18, 5),
        (25, 15),
        (13, 5),
      ]) {
        final morse = HapticMorse.atSpeed(
          wordsPerMinute: character,
          effectiveWordsPerMinute: effective,
        );

        expect(
          speedOf(morse),
          closeTo(effective, 0.35),
          reason: 'character $character WPM, effective $effective WPM',
        );
      }
    });

    test('the letter:word gap ratio stays 3:7', () {
      final morse = HapticMorse.atSpeed(
        wordsPerMinute: 20,
        effectiveWordsPerMinute: 8,
      );

      final letterGap = morse.convertTextToHapticEvents('EE')[1].duration;
      final wordGap = morse.convertTextToHapticEvents('E E')[1].duration;

      expect(wordGap / letterGap, closeTo(7 / 3, 0.01));
    });

    test('an effective speed equal to the character speed is standard timing',
        () {
      final farnsworth = HapticMorse.atSpeed(
        wordsPerMinute: 20,
        effectiveWordsPerMinute: 20,
      );
      final plain = HapticMorse.atSpeed(wordsPerMinute: 20);

      expect(
        farnsworth.convertTextToHapticEvents('HELLO WORLD'),
        plain.convertTextToHapticEvents('HELLO WORLD'),
      );
    });
  });

  group('validation', () {
    test('rejects a non-positive speed', () {
      expect(
        () => HapticMorse.atSpeed(wordsPerMinute: 0),
        throwsArgumentError,
      );
      expect(
        () => HapticMorse.atSpeed(wordsPerMinute: -5),
        throwsArgumentError,
      );
      expect(
        () => HapticMorse.atSpeed(
          wordsPerMinute: 20,
          effectiveWordsPerMinute: 0,
        ),
        throwsArgumentError,
      );
    });

    test('rejects an effective speed above the character speed', () {
      expect(
        () => HapticMorse.atSpeed(
          wordsPerMinute: 10,
          effectiveWordsPerMinute: 20,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('cannot speed it up'),
          ),
        ),
      );
    });

    test('rejects a speed so high the unit rounds to zero', () {
      // 1200/wpm must round to at least 1ms.
      expect(
        () => HapticMorse.atSpeed(wordsPerMinute: 100000),
        throwsArgumentError,
      );
    });
  });

  group('alphabet arguments pass through', () {
    test('accepts additionalSymbols', () {
      final morse = HapticMorse.atSpeed(
        wordsPerMinute: 20,
        additionalSymbols: HapticMorse.accentedLetters,
      );

      expect(morse.convertTextToMorseString('Ñ'), '--.--');
    });

    test('accepts a custom alphabet', () {
      final morse = HapticMorse.atSpeed(
        wordsPerMinute: 20,
        charMap: ['.-', '--'],
        charReference: '💧🔥',
      );

      expect(morse.convertTextToMorseString('💧🔥'), '.- --');
    });
  });
}
