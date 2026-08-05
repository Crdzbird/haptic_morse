import 'package:haptic_morse/haptic_morse.dart';
import 'package:test/test.dart';

void main() {
  group('phase', () {
    test('dots and dashes vibrate; gaps do not', () {
      expect(const HapticDot(100).isVibration, isTrue);
      expect(const HapticDash(300).isVibration, isTrue);
      expect(const HapticSymbolGap(100).isVibration, isFalse);
      expect(const HapticLetterGap(300).isVibration, isFalse);
      expect(const HapticWordGap(700).isVibration, isFalse);
    });
  });

  group('value semantics', () {
    test('same type and duration are equal', () {
      expect(const HapticDot(100), equals(const HapticDot(100)));
      expect(const HapticDot(100).hashCode, const HapticDot(100).hashCode);
    });

    test('different durations differ', () {
      expect(const HapticDot(100), isNot(equals(const HapticDot(200))));
    });

    test('different types with the same duration differ', () {
      // Both are 100ms and both are gaps, but they mean different things.
      expect(
        const HapticSymbolGap(100),
        isNot(equals(const HapticLetterGap(100))),
      );
      expect(const HapticDot(300), isNot(equals(const HapticDash(300))));
    });

    test('toString names the type and duration', () {
      expect(const HapticDot(100).toString(), contains('100'));
      expect(const HapticDot(100).toString(), contains('dot'));
    });
  });

  group('JSON', () {
    test('every variant round-trips', () {
      const events = <HapticEvent>[
        HapticDot(100),
        HapticDash(300),
        HapticSymbolGap(100),
        HapticLetterGap(300),
        HapticWordGap(700),
      ];

      for (final event in events) {
        expect(HapticEvent.fromJson(event.toJson()), equals(event));
      }
    });

    test('accepts a duration encoded as a double', () {
      expect(
        HapticEvent.fromJson({'type': 'dot', 'duration': 100.0}),
        const HapticDot(100),
      );
    });

    test('rejects an unknown type', () {
      expect(
        () => HapticEvent.fromJson({'type': 'wobble', 'duration': 100}),
        throwsArgumentError,
      );
    });

    test('rejects a missing or non-numeric duration', () {
      expect(
        () => HapticEvent.fromJson({'type': 'dot'}),
        throwsArgumentError,
      );
      expect(
        () => HapticEvent.fromJson({'type': 'dot', 'duration': 'soon'}),
        throwsArgumentError,
      );
    });
  });

  group('toVibrationPattern', () {
    test('emits a leading zero so index 0 is the off slot', () {
      // Android's createWaveform and the iOS side of package:vibration both
      // treat even indices as off and odd indices as on.
      expect(const [HapticDot(100)].toVibrationPattern(), [0, 100]);
    });

    test('odd indices are vibrations, even indices are silence', () {
      final events = 'SOS'.toHapticEvents();
      final pattern = events.toVibrationPattern();

      expect(pattern.first, 0);
      expect(pattern, hasLength(events.length + 1));

      for (var i = 0; i < events.length; i++) {
        expect(
          events[i].isVibration,
          (i + 1).isOdd,
          reason: 'event $i landed in the wrong slot of $pattern',
        );
        expect(pattern[i + 1], events[i].duration);
      }
    });

    test('empty in, empty out', () {
      expect(const <HapticEvent>[].toVibrationPattern(), isEmpty);
    });

    test('the result is unmodifiable', () {
      expect(
        () => const [HapticDot(100)].toVibrationPattern().add(1),
        throwsUnsupportedError,
      );
    });

    test('merges adjacent same-phase events instead of flipping the phase', () {
      // The generator never emits these, but a hand-built list must not be
      // able to invert every symbol that follows it.
      const events = <HapticEvent>[
        HapticDot(100),
        HapticSymbolGap(100),
        HapticLetterGap(300),
        HapticDash(300),
      ];

      expect(events.toVibrationPattern(), [0, 100, 400, 300]);
    });

    test('a leading gap becomes the initial off delay', () {
      const events = <HapticEvent>[HapticWordGap(700), HapticDot(100)];

      expect(events.toVibrationPattern(), [700, 100]);
    });
  });

  group('perceptibility', () {
    test('standard timings are comfortably above the floor', () {
      expect('SOS'.toHapticEvents().isLikelyPerceptible, isTrue);
      expect('SOS'.toHapticEvents().imperceptibleEvents, isEmpty);
    });

    test('flags vibrations shorter than the floor', () {
      final tooFast = HapticMorse.custom(dotDuration: 5, dashDuration: 15);
      final events = 'A'.toHapticEvents(tooFast);

      expect(events.isLikelyPerceptible, isFalse);
      // Both the dot and the dash are under 20ms.
      expect(events.imperceptibleEvents, hasLength(2));
    });

    test('ignores short gaps, which are a legibility issue not a haptic one',
        () {
      final morse = HapticMorse.custom(
        dotDuration: 100,
        dashDuration: 300,
        gapSymbolDuration: 1,
        gapLetterDuration: 1,
        gapWordDuration: 1,
      );

      expect('A B'.toHapticEvents(morse).isLikelyPerceptible, isTrue);
      expect('A B'.toHapticEvents(morse).imperceptibleEvents, isEmpty);
    });

    test('the floor sits around 60 WPM', () {
      // 1200/60 = 20ms, exactly the threshold.
      expect(
        'SOS'
            .toHapticEvents(HapticMorse.atSpeed(wordsPerMinute: 60))
            .isLikelyPerceptible,
        isTrue,
      );
      expect(
        'SOS'
            .toHapticEvents(HapticMorse.atSpeed(wordsPerMinute: 70))
            .isLikelyPerceptible,
        isFalse,
      );
    });

    test('an empty sequence is trivially perceptible', () {
      expect(const <HapticEvent>[].isLikelyPerceptible, isTrue);
    });

    test('the threshold is exclusive', () {
      const threshold = HapticEvent.minimumPerceptibleMilliseconds;

      expect(
        [const HapticDot(threshold)].isLikelyPerceptible,
        isTrue,
      );
      expect(
        [const HapticDot(threshold - 1)].isLikelyPerceptible,
        isFalse,
      );
    });
  });

  group('totalDuration', () {
    test('sums every event', () {
      expect(const <HapticEvent>[].totalDuration, 0);
      expect(
        const [HapticDot(100), HapticSymbolGap(100), HapticDash(300)]
            .totalDuration,
        500,
      );
    });

    test('excludes the synthetic leading zero of the pattern', () {
      final events = 'SOS'.toHapticEvents();

      expect(
        events.totalDuration,
        events.toVibrationPattern().reduce((a, b) => a + b),
      );
    });
  });
}
