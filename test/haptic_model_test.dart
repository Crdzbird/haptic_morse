import 'dart:convert';
import 'package:haptic_morse/haptic_morse.dart';
import 'package:test/test.dart';

void main() {
  group(HapticModel, () {
    const testHapticModel = HapticModel(
      text: 'Hello',
      morseCode: '.... . .-.. .-.. ---',
      hapticDurations: [100, 100, 100, 100, 100, 300, 100, 100, 100, 100, 100],
    );

    group('constructor', () {
      test('creates instance with default values', () {
        const hapticModel = HapticModel();
        expect(hapticModel.text, '');
        expect(hapticModel.morseCode, '');
        expect(hapticModel.hapticDurations, []);
      });

      test('creates instance with provided values', () {
        expect(testHapticModel.text, 'Hello');
        expect(testHapticModel.morseCode, '.... . .-.. .-.. ---');
        expect(testHapticModel.hapticDurations,
            [100, 100, 100, 100, 100, 300, 100, 100, 100, 100, 100]);
      });

      test('creates instance with provided values', () {
        expect(testHapticModel.text, 'Hello');
        expect(testHapticModel.morseCode, '.... . .-.. .-.. ---');
        expect(testHapticModel.hapticDurations,
            [100, 100, 100, 100, 100, 300, 100, 100, 100, 100, 100]);
      });
    });

    group('fromMap', () {
      test('creates instance from null map', () {
        final hapticModel = HapticModel.fromMap(null);
        expect(hapticModel, isNotNull);
      });

      test('creates instance from empty map', () {
        final hapticModel = HapticModel.fromMap(const <String, dynamic>{});
        expect(hapticModel, isNotNull);
      });

      test('creates instance from complete map', () {
        final map = <String, dynamic>{
          'text': 'Hello',
          'morseCode': '.... . .-.. .-.. ---',
          'hapticDurations': [
            100,
            100,
            100,
            100,
            100,
            300,
            100,
            100,
            100,
            100,
            100
          ],
        };

        final hapticModel = HapticModel.fromMap(map);
        expect(hapticModel.text, 'Hello');
        expect(hapticModel.morseCode, '.... . .-.. .-.. ---');
        expect(hapticModel.hapticDurations,
            [100, 100, 100, 100, 100, 300, 100, 100, 100, 100, 100]);
      });

      test('handles null values in map', () {
        final map = <String, dynamic>{
          'text': null,
          'morseCode': null,
          'hapticDurations': null,
        };

        final hapticModel = HapticModel.fromMap(map);
        expect(hapticModel, isNotNull);
      });

      test('handles partial map', () {
        final map = <String, dynamic>{
          'text': 'Advanced Programming',
          'morseCode': '',
          'hapticDurations': [],
        };

        final hapticModel = HapticModel.fromMap(map);
        expect(hapticModel.text, 'Advanced Programming');
        expect(hapticModel.morseCode, '');
        expect(hapticModel.hapticDurations, []);
      });

      test('handles text', () {
        final map = <String, dynamic>{
          'text': 'Hello',
        };

        final hapticModel = HapticModel.fromMap(map);
        expect(hapticModel.text, 'Hello');
      });

      test('handles morseCode', () {
        final map = <String, dynamic>{
          'morseCode': '.... . .-.. .-.. ---',
        };

        final hapticModel = HapticModel.fromMap(map);
        expect(hapticModel.morseCode, '.... . .-.. .-.. ---');
      });

      test('handles hapticDurations', () {
        final map = <String, dynamic>{
          'hapticDurations': [100, 200, 300],
        };

        final hapticModel = HapticModel.fromMap(map);
        expect(hapticModel.hapticDurations, [100, 200, 300]);
      });
    });

    group('fromJson', () {
      test('creates instance from null', () {
        final hapticModel = HapticModel.fromJson(null);
        expect(hapticModel, isNotNull);
      });

      test('creates instance from empty string', () {
        final hapticModel = HapticModel.fromJson('');
        expect(hapticModel, isNotNull);
      });

      test('creates instance from JSON string', () {
        final jsonString = json.encode({
          'text': 'Hello',
          'morseCode': '.... . .-.. .-.. ---',
          'hapticDurations': [
            100,
            100,
            100,
            100,
            100,
            300,
            100,
            100,
            100,
            100,
            100
          ],
        });

        final hapticModel = HapticModel.fromJson(jsonString);
        expect(hapticModel.hapticDurations, testHapticModel.hapticDurations);
        expect(hapticModel.text, testHapticModel.text);
        expect(hapticModel.morseCode, testHapticModel.morseCode);
      });

      test('creates instance from Map<String, dynamic>', () {
        final map = <String, dynamic>{
          'text': 'Hello',
          'morseCode': '.... . .-.. .-.. ---',
          'hapticDurations': [
            100,
            100,
            100,
            100,
            100,
            300,
            100,
            100,
            100,
            100,
            100
          ],
        };

        final hapticModel = HapticModel.fromJson(map);
        expect(hapticModel.text, 'Hello');
        expect(hapticModel.morseCode, '.... . .-.. .-.. ---');
        expect(hapticModel.hapticDurations,
            [100, 100, 100, 100, 100, 300, 100, 100, 100, 100, 100]);
      });

      test('throws ArgumentError for invalid data type', () {
        expect(
          () => HapticModel.fromJson(123),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for list data type', () {
        expect(
          () => HapticModel.fromJson(const [1, 2, 3]),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for boolean data type', () {
        expect(
          () => HapticModel.fromJson(true),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('toJson', () {
      test('converts to JSON map correctly', () {
        final json = testHapticModel.toJson();
        final expectedJson = <String, dynamic>{
          'text': 'Hello',
          'morseCode': '.... . .-.. .-.. ---',
          'hapticDurations': [
            100,
            100,
            100,
            100,
            100,
            300,
            100,
            100,
            100,
            100,
            100
          ],
        };

        expect(json, expectedJson);
      });

      test('converts empty course list to JSON map', () {
        const hapticModel = HapticModel();
        final json = hapticModel.toJson();
        final expectedJson = <String, dynamic>{
          'text': '',
          'morseCode': '',
          'hapticDurations': [],
        };

        expect(json, expectedJson);
      });
    });

    group('encode', () {
      test('encodes to JSON string correctly', () {
        final jsonString = testHapticModel.encode();
        final decodedMap = json.decode(jsonString) as Map<String, dynamic>;

        expect(decodedMap['text'], 'Hello');
        expect(decodedMap['morseCode'], '.... . .-.. .-.. ---');
        expect(decodedMap['hapticDurations'],
            [100, 100, 100, 100, 100, 300, 100, 100, 100, 100, 100]);
      });

      test('encodes empty course list to JSON string', () {
        const hapticModel = HapticModel();
        final jsonString = hapticModel.encode();
        final decodedMap = json.decode(jsonString) as Map<String, dynamic>;

        expect(decodedMap['text'], '');
        expect(decodedMap['morseCode'], '');
        expect(decodedMap['hapticDurations'], []);
      });
    });

    group('copyWith', () {
      test('returns same instance when no parameters provided', () {
        final copied = testHapticModel.copyWith();
        expect(identical(copied, testHapticModel), false);
      });

      test('updates only specified parameters', () {
        final copied = testHapticModel.copyWith(
          text: 'Advanced Haptic Feedback',
          morseCode: '.... . .-.. .-.. ---',
          hapticDurations: [
            100,
            100,
            100,
            100,
            100,
            300,
            100,
            100,
            100,
            100,
            100
          ],
        );

        expect(copied.text, 'Advanced Haptic Feedback');
        expect(copied.morseCode, '.... . .-.. .-.. ---');
        expect(copied.hapticDurations,
            [100, 100, 100, 100, 100, 300, 100, 100, 100, 100, 100]);
      });

      test('updates all parameters', () {
        final copied = testHapticModel.copyWith(
          text: 'Data Science Fundamentals',
          morseCode: '.... . .-.. .-.. ---',
          hapticDurations: [
            100,
            100,
            100,
            100,
            100,
            300,
            100,
            100,
            100,
            100,
            100
          ],
        );

        expect(copied.text, 'Data Science Fundamentals');
        expect(copied.morseCode, '.... . .-.. .-.. ---');
        expect(copied.hapticDurations,
            [100, 100, 100, 100, 100, 300, 100, 100, 100, 100, 100]);
      });

      test('no update parameter', () {
        final copied = testHapticModel.copyWith();

        expect(copied.text, testHapticModel.text);
        expect(copied.morseCode, testHapticModel.morseCode);
        expect(copied.hapticDurations, testHapticModel.hapticDurations);
      });
    });
  });
}
