import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_flutter/main.dart';

void main() {
  const channel = MethodChannel('vibration');
  final log = <MethodCall>[];

  /// Whether the fake device claims it can play a custom waveform.
  var supportsPatterns = true;

  void mockChannel() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          log.add(methodCall);
          return switch (methodCall.method) {
            'hasVibrator' ||
            'hasCustomVibrationsSupport' ||
            'hasAmplitudeControl' => supportsPatterns,
            _ => null,
          };
        });
  }

  setUp(() {
    supportsPatterns = true;
    mockChannel();
  });

  tearDown(log.clear);

  /// Only the calls that actually drive the motor.
  Iterable<MethodCall> vibrateCalls() =>
      log.where((call) => call.method == 'vibrate');

  testWidgets('encodes the message and plays it', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Nothing encoded until Play is tapped.
    expect(find.text('—'), findsOneWidget);

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    // HOLA
    expect(find.text('.... --- .-.. .-'), findsOneWidget);

    final pattern = List<int>.from(
      (vibrateCalls().single.arguments as Map)['pattern'] as List<dynamic>,
    );

    // Index 0 must be the off delay the platform expects.
    expect(pattern.first, 0);
  });

  testWidgets('an unencodable message never touches the motor', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '!!!');
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    expect(vibrateCalls(), isEmpty);
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('a device without waveform support shows the code instead', (
    tester,
  ) async {
    supportsPatterns = false;
    mockChannel();

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    // The message stays readable even though nothing can be played.
    expect(find.text('.... --- .-.. .-'), findsOneWidget);
    expect(vibrateCalls(), isEmpty);
    expect(find.textContaining('haptics unavailable'), findsOneWidget);
  });
}
