@Tags(['flutter'])
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_morse/haptic_morse.dart';
import 'package:haptic_morse/haptic_morse_vibration.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('vibration');
  final log = <MethodCall>[];

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      return null;
    });
  });

  tearDown(log.clear);

  /// The `pattern` argument of the single logged `vibrate` call.
  List<int> loggedPattern() {
    final call = log.singleWhere((c) => c.method == 'vibrate');
    return List<int>.from(
      (call.arguments as Map)['pattern'] as List<dynamic>,
    );
  }

  group('vibrate', () {
    test('passes arguments through unchanged', () async {
      await const HapticVibration().vibrate(
        amplitude: 1,
        duration: 500,
        intensities: [500],
        pattern: [100, 200, 300],
        repeat: 0,
        sharpness: 0.5,
      );

      expect(
        log,
        contains(
          isMethodCall('vibrate', arguments: {
            'duration': 500,
            'pattern': [100, 200, 300],
            'repeat': 0,
            'intensities': [500],
            'amplitude': 1,
            'sharpness': 0.5,
          }),
        ),
      );
    });
  });

  group('vibrateEvents', () {
    test('sends a pattern whose index 0 is the off delay', () async {
      await const HapticVibration().vibrateEvents('E'.toHapticEvents());

      // Not [100]: the platform would have played that as 100ms of silence.
      expect(loggedPattern(), [0, 100]);
    });

    test('never touches the motor for an empty sequence', () async {
      await const HapticVibration().vibrateEvents(const []);

      expect(log, isEmpty);
    });

    test('forwards amplitude and sharpness', () async {
      await const HapticVibration().vibrateEvents(
        'E'.toHapticEvents(),
        amplitude: 128,
        sharpness: 0.25,
      );

      final call = log.single;
      expect((call.arguments as Map)['amplitude'], 128);
      expect((call.arguments as Map)['sharpness'], 0.25);
    });
  });

  group('vibrateText', () {
    test('encodes and plays in one call', () async {
      await const HapticVibration().vibrateText('SOS');

      expect(loggedPattern(), 'SOS'.toVibrationPattern());
      expect(loggedPattern().first, 0);
    });

    test('honours a custom encoder', () async {
      await const HapticVibration().vibrateText(
        'E',
        morse: HapticMorse.custom(dotDuration: 42),
      );

      expect(loggedPattern(), [0, 42]);
    });

    test('never touches the motor when nothing is encodable', () async {
      await const HapticVibration().vibrateText('!!!');

      expect(log, isEmpty);
    });
  });

  group('capability checks', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        return true;
      });
    });

    test('hasCustomVibrationsSupport asks the platform directly', () async {
      expect(
        await const HapticVibration().hasCustomVibrationsSupport(),
        isTrue,
      );
      expect(log.single.method, 'hasCustomVibrationsSupport');
    });

    test('hasVibrator resolves without touching the vibration channel',
        () async {
      // package:vibration answers this from device_info_plus and a
      // Platform.isAndroid/isIOS check, not from the motor, so on this host it
      // is false no matter what the channel would say. Asserting `isFalse`
      // here would bake in host behaviour; asserting the absence of a channel
      // call is what is actually true and portable.
      expect(await const HapticVibration().hasVibrator(), isA<bool>());
      expect(log.where((c) => c.method == 'hasVibrator'), isEmpty);
    });

    test('hasAmplitudeControl resolves without throwing', () async {
      // Same device-info path as hasVibrator on a non-physical device.
      expect(await const HapticVibration().hasAmplitudeControl(), isA<bool>());
    });
  });

  group('cancel', () {
    test('forwards to the platform', () async {
      await const HapticVibration().cancel();

      expect(log, [isMethodCall('cancel', arguments: null)]);
    });
  });
}
