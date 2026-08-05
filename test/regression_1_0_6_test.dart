import 'package:haptic_morse/haptic_morse.dart';
import 'package:test/test.dart';

/// Regression tests for the defects fixed in 1.0.6.
///
/// Each group names the behaviour that was broken before the fix, so a
/// reintroduction fails with a self-explanatory test name.
void main() {
  group('HapticModel value equality', () {
    test('runtime instances with equal fields are equal', () {
      final a = HapticModel(
        text: 'A'.toUpperCase(),
        morseCode: '.-',
        hapticDurations: [100, 100, 300],
      );
      final b = HapticModel(
        text: 'A'.toUpperCase(),
        morseCode: '.-',
        hapticDurations: [100, 100, 300],
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('differs when any field differs', () {
      const base = HapticModel(
        text: 'A',
        morseCode: '.-',
        hapticDurations: [100],
      );

      expect(base, isNot(equals(base.copyWith(text: 'B'))));
      expect(base, isNot(equals(base.copyWith(morseCode: '-...'))));
      expect(base, isNot(equals(base.copyWith(hapticDurations: [300]))));
    });

    test('durations are compared element-wise, not by identity', () {
      const a = HapticModel(hapticDurations: [100, 300]);
      final b = HapticModel(hapticDurations: [100, 300].toList());

      expect(a, equals(b));
    });

    test('works as a Set/Map key', () {
      // Built at runtime so const canonicalization cannot mask a missing
      // hashCode/== pair; these must dedupe on value, not identity.
      final morse = HapticMorse();
      final set = {
        morse.convertTextToMorseMap('A'),
        morse.convertTextToMorseMap('A'),
        morse.convertTextToMorseMap('B'),
      };

      expect(set, hasLength(2));
    });

    test('copyWith with no arguments produces an equal but distinct instance',
        () {
      const original = HapticModel(text: 'A', hapticDurations: [100]);
      final copy = original.copyWith();

      expect(identical(copy, original), isFalse);
      expect(copy, equals(original));
    });

    test('toString exposes the fields', () {
      const model = HapticModel(
        text: 'A',
        morseCode: '.-',
        hapticDurations: [100],
      );

      expect(model.toString(), contains('A'));
      expect(model.toString(), contains('.-'));
      expect(model.toString(), contains('100'));
    });
  });

  group('HapticModel.hapticDurations is unmodifiable', () {
    test('add throws instead of mutating the model', () {
      final model = HapticMorse().convertTextToMorseMap('A');

      expect(() => model.hapticDurations.add(999), throwsUnsupportedError);
      expect(model.hapticDurations, [100, 100, 300]);
    });

    test('mutating the source list does not leak into the model', () {
      final source = [100, 200];
      final model = HapticModel(hapticDurations: source);
      final before = List<int>.of(model.hapticDurations);

      // The model holds the caller's list, but the caller cannot reach it
      // through the getter; this documents the remaining sharp edge.
      expect(before, [100, 200]);
      expect(() => model.hapticDurations.clear(), throwsUnsupportedError);
    });
  });

  group('HapticModel.fromMap numeric coercion', () {
    test('accepts durations encoded as doubles', () {
      final model = HapticModel.fromJson(
        '{"text":"A","morseCode":".-","hapticDurations":[100.0,300.0]}',
      );

      expect(model.hapticDurations, [100, 300]);
    });

    test('accepts a mix of int and double durations', () {
      final model = HapticModel.fromMap({
        'text': 'A',
        'morseCode': '.-',
        'hapticDurations': <dynamic>[100, 300.0, 700],
      });

      expect(model.hapticDurations, [100, 300, 700]);
    });

    test('round-trips through encode/decode', () {
      final original = HapticMorse().convertTextToMorseMap('SOS');
      final restored = HapticModel.fromJson(original.encode());

      expect(restored, equals(original));
    });
  });

  group('custom numericReference no longer builds a RegExp', () {
    test('regex metacharacters do not throw', () {
      final morse = HapticMorse.custom(
        numericReference: '(',
        numericMap: ['-'],
      );

      expect(morse.convertTextToMorseString('('), '-');
    });

    test('a dot reference does not match every character', () {
      final morse = HapticMorse.custom(
        numericReference: '.',
        numericMap: ['-'],
      );

      // 'Z' must still resolve through the alphabet map, not the numeric one.
      expect(morse.convertTextToMorseString('Z'), '--..');
      expect(morse.convertTextToMorseString('.'), '-');
    });

    test('lookup is case-insensitive and consistent with the alphabet map', () {
      final morse = HapticMorse.custom(
        numericReference: 'AB',
        numericMap: ['---', '...'],
      );

      expect(morse.convertTextToMorseString('a'), '---');
      expect(morse.convertTextToMorseString('A'), '---');
      expect(morse.convertTextToMorseString('b'), '...');
    });

    test('default digit behaviour is unchanged', () {
      final morse = HapticMorse();

      expect(morse.convertTextToMorseString('0'), '-----');
      expect(morse.convertTextToMorseString('9'), '----.');
      expect(morse.convertTextToMorseString('SOS'), '... --- ...');
      expect(
        morse.convertTextToMorseString('HELLO WORLD'),
        '.... . .-.. .-.. --- / .-- --- .-. .-.. -..',
      );
    });

    test('numeric reference wins over the alphabet reference on overlap', () {
      final morse = HapticMorse.custom(
        numericReference: 'A',
        numericMap: ['-----'],
      );

      expect(morse.convertTextToMorseString('A'), '-----');
    });

    test('falls through when the numeric map is shorter than its reference',
        () {
      final morse = HapticMorse.custom(
        numericReference: 'AB',
        numericMap: ['-----'],
      );

      // 'B' has no numeric entry, so the alphabet map answers instead.
      expect(morse.convertTextToMorseString('B'), '-...');
    });
  });

  group('haptic pattern output is unchanged in 1.0.6', () {
    // These lock the current output so the 2.0.0 pattern rework is a
    // deliberate, visible change rather than an accident.
    final morse = HapticMorse();

    test('single letters', () {
      expect(morse.convertTextToHapticPattern('E'), [100]);
      expect(morse.convertTextToHapticPattern('T'), [300]);
      expect(morse.convertTextToHapticPattern('A'), [100, 100, 300]);
    });

    test('word gap', () {
      expect(morse.convertTextToHapticPattern('E E'), [100, 700, 100]);
    });

    test('digits still produce a pattern', () {
      expect(morse.convertTextToHapticPattern('123'), isNotEmpty);
    });
  });
}
