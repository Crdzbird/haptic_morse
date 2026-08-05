import 'dart:convert';

import 'package:haptic_morse/haptic_morse.dart';
import 'package:test/test.dart';

void main() {
  const morse = HapticMorse();

  const sample = HapticModel(
    text: 'A',
    morseCode: '.-',
    events: [HapticDot(100), HapticSymbolGap(100), HapticDash(300)],
  );

  group('construction', () {
    test('defaults to empty', () {
      const model = HapticModel();

      expect(model.text, '');
      expect(model.morseCode, '');
      expect(model.events, isEmpty);
      expect(model.totalDuration, 0);
      expect(model.toVibrationPattern(), isEmpty);
    });

    test('carries the values it was given', () {
      expect(sample.text, 'A');
      expect(sample.morseCode, '.-');
      expect(sample.events, hasLength(3));
      expect(sample.totalDuration, 500);
    });
  });

  group('value equality', () {
    test('runtime instances with equal fields are equal', () {
      final a = morse.convertTextToModel('SOS');
      final b = morse.convertTextToModel('SOS');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('differs when any field differs', () {
      expect(sample, isNot(equals(sample.copyWith(text: 'B'))));
      expect(sample, isNot(equals(sample.copyWith(morseCode: '-...'))));
      expect(
        sample,
        isNot(equals(sample.copyWith(events: const [HapticDot(100)]))),
      );
    });

    test('events are compared element-wise, not by identity', () {
      final a = HapticModel(
        events: [const HapticDot(100), const HapticDash(300)],
      );
      final b = HapticModel(
        events: [const HapticDot(100), const HapticDash(300)].toList(),
      );

      expect(a, equals(b));
    });

    test('works as a Set key', () {
      final set = {
        morse.convertTextToModel('A'),
        morse.convertTextToModel('A'),
        morse.convertTextToModel('B'),
      };

      expect(set, hasLength(2));
    });

    test('toString summarizes without dumping every event', () {
      expect(sample.toString(), contains('A'));
      expect(sample.toString(), contains('.-'));
      expect(sample.toString(), contains('500'));
    });
  });

  group('events is unmodifiable', () {
    test('add throws', () {
      final model = morse.convertTextToModel('A');

      expect(
        () => model.events.add(const HapticDot(1)),
        throwsUnsupportedError,
      );
      expect(model.events, hasLength(3));
    });

    test('clear throws', () {
      expect(sample.events.clear, throwsUnsupportedError);
    });
  });

  group('copyWith', () {
    test('with no arguments produces an equal but distinct instance', () {
      final copy = sample.copyWith();

      expect(identical(copy, sample), isFalse);
      expect(copy, equals(sample));
    });

    test('updates only what it is given', () {
      final copy = sample.copyWith(text: 'B');

      expect(copy.text, 'B');
      expect(copy.morseCode, sample.morseCode);
      expect(copy.events, sample.events);
    });

    test('updates every field', () {
      final copy = sample.copyWith(
        text: 'E',
        morseCode: '.',
        events: const [HapticDot(100)],
      );

      expect(
        copy,
        const HapticModel(
          text: 'E',
          morseCode: '.',
          events: [HapticDot(100)],
        ),
      );
    });
  });

  group('JSON', () {
    test('toJson has the documented shape', () {
      expect(sample.toJson(), {
        'text': 'A',
        'morseCode': '.-',
        'events': [
          {'type': 'dot', 'duration': 100},
          {'type': 'symbolGap', 'duration': 100},
          {'type': 'dash', 'duration': 300},
        ],
      });
    });

    test('round-trips through encode and fromJson', () {
      final original = morse.convertTextToModel('HELLO WORLD');

      expect(HapticModel.fromJson(original.encode()), equals(original));
    });

    test('round-trips through toJson and fromMap', () {
      expect(HapticModel.fromMap(sample.toJson()), equals(sample));
    });

    test('encode produces valid JSON', () {
      final decoded = json.decode(sample.encode()) as Map<String, dynamic>;

      expect(decoded['text'], 'A');
      expect(decoded['morseCode'], '.-');
      expect(decoded['events'], hasLength(3));
    });

    test('fromJson accepts an already-decoded map', () {
      expect(HapticModel.fromJson(sample.toJson()), equals(sample));
    });

    test('fromJson treats null and empty as an empty model', () {
      expect(HapticModel.fromJson(null), const HapticModel());
      expect(HapticModel.fromJson(''), const HapticModel());
      expect(HapticModel.fromMap(null), const HapticModel());
    });

    test('fromMap tolerates missing keys', () {
      expect(HapticModel.fromMap(const {}), const HapticModel());
      expect(
        HapticModel.fromMap(const {'text': 'A'}),
        const HapticModel(text: 'A'),
      );
    });

    test('fromJson rejects unsupported input types', () {
      expect(() => HapticModel.fromJson(42), throwsArgumentError);
      expect(() => HapticModel.fromJson(true), throwsArgumentError);
      expect(() => HapticModel.fromJson(<int>[1, 2]), throwsArgumentError);
    });

    test('fromMap rejects a malformed event', () {
      expect(
        () => HapticModel.fromMap({
          'events': [
            {'type': 'wobble', 'duration': 1},
          ],
        }),
        throwsArgumentError,
      );
    });
  });

  group('vibration pattern', () {
    test('matches the sequence it was built from', () {
      final model = morse.convertTextToModel('SOS');

      expect(model.toVibrationPattern(), model.events.toVibrationPattern());
      expect(model.toVibrationPattern().first, 0);
    });
  });
}
