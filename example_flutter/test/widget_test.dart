import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_flutter/main.dart';

void main() {
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

  testWidgets('encodes the message and plays it', (tester) async {
    await tester.pumpWidget(const MyApp());

    // Nothing encoded until Play is tapped.
    expect(find.text('—'), findsOneWidget);

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    // HOLA
    expect(find.text('.... --- .-.. .-'), findsOneWidget);

    final call = log.singleWhere((c) => c.method == 'vibrate');
    final pattern = List<int>.from(
      (call.arguments as Map)['pattern'] as List<dynamic>,
    );

    // Index 0 must be the off delay the platform expects.
    expect(pattern.first, 0);
  });

  testWidgets('an unencodable message never touches the motor', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.enterText(find.byType(TextField), '!!!');
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    expect(log, isEmpty);
    expect(find.text('—'), findsOneWidget);
  });
}
