import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_morse/haptic_morse.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('vibration');
  final List<MethodCall> log = <MethodCall>[];

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) {
      log.add(methodCall);
      return null;
    });
  });

  tearDown(() {
    log.clear();
  });

  test(
    'Vibrate',
    () async {
      await HapticVibration().vibrate(
        amplitude: 1,
        duration: 500,
        intensities: [500],
        pattern: [100, 200, 300],
        repeat: 0,
        sharpness: 0.5,
      );
      expect(
          log,
          contains(isMethodCall('vibrate', arguments: {
            'duration': 500,
            'pattern': [100, 200, 300],
            'repeat': 0,
            'intensities': [500],
            'amplitude': 1,
            'sharpness': 0.5
          })));
    },
  );

  test(
    'cancel vibration',
    () async {
      await HapticVibration().cancel();
      expect(
        log,
        <Matcher>[isMethodCall('cancel', arguments: null)],
      );
    },
  );
}
