import 'package:haptic_morse/haptic_morse.dart';
import 'package:test/test.dart';

void main() {
  const morse = HapticMorse();

  group('defaults to standard International Morse Code', () {
    test('toMorseString', () {
      expect('SOS'.toMorseString(), '... --- ...');
      expect(
        'HELLO WORLD'.toMorseString(),
        '.... . .-.. .-.. --- / .-- --- .-. .-.. -..',
      );
    });

    test('toHapticEvents', () {
      expect('E'.toHapticEvents(), [const HapticDot(100)]);
    });

    test('toMorseModel', () {
      expect('SOS'.toMorseModel(), morse.convertTextToModel('SOS'));
    });

    test('toVibrationPattern', () {
      expect('E'.toVibrationPattern(), [0, 100]);
    });
  });

  group('delegates to the instance it is given', () {
    final fast = HapticMorse.custom(dotDuration: 10, dashDuration: 20);

    test('toMorseString', () {
      expect('A'.toMorseString(fast), morse.convertTextToMorseString('A'));
    });

    test('toHapticEvents honours custom timings', () {
      expect('E'.toHapticEvents(fast), [const HapticDot(10)]);
      expect('T'.toHapticEvents(fast), [const HapticDash(20)]);
    });

    test('toMorseModel honours custom timings', () {
      expect('E'.toMorseModel(fast).totalDuration, 10);
    });

    test('toVibrationPattern honours custom timings', () {
      expect('E'.toVibrationPattern(fast), [0, 10]);
    });

    test('a custom alphabet resolves through the extension', () {
      final custom = HapticMorse.custom(
        charMap: const ['.-', '--'],
        charReference: '💧🔥',
      );

      expect('💧🔥'.toMorseString(custom), '.- --');
    });
  });

  group('empty input', () {
    test('toMorseString returns null', () {
      expect(''.toMorseString(), isNull);
      expect('   '.toMorseString(), isNull);
      expect('🙂🙂🙂'.toMorseString(), isNull);
    });

    test('the sequence forms are empty', () {
      expect(''.toHapticEvents(), isEmpty);
      expect(''.toVibrationPattern(), isEmpty);
      expect(''.toMorseModel(), HapticModel.empty);
    });
  });

  test('each form agrees with the others', () {
    const input = 'HELLO WORLD';
    final model = input.toMorseModel();

    expect(model.text, input);
    expect(model.morseCode, input.toMorseString());
    expect(model.events, input.toHapticEvents());
    expect(model.toVibrationPattern(), input.toVibrationPattern());
  });
}
