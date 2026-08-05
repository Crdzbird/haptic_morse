import 'dart:io';

import 'package:test/test.dart';

import '../example/haptic_morse_example.dart';

/// Keeps README.md honest.
///
/// The README quotes output from the example. Nothing stops that quote from
/// drifting once a default changes, so this rebuilds the report and checks
/// that every quoted line still appears in it.
///
/// The README marks the quoted region with the HTML comments below, so the
/// prose around it can be edited freely without touching this test.
void main() {
  const beginMarker = '<!-- example-output:begin -->';
  const endMarker = '<!-- example-output:end -->';

  late List<String> readme;
  late List<String> reportLines;

  setUpAll(() {
    // Tests run with the package root as the working directory.
    final file = File('README.md');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'README.md not found; run tests from the package root',
    );
    readme = file.readAsLinesSync();
    reportLines = buildReport().lines;
  });

  /// The lines between the two markers, excluding the code fences.
  List<String> quotedLines() {
    final begin = readme.indexOf(beginMarker);
    final end = readme.indexOf(endMarker);

    expect(begin, isNonNegative, reason: 'missing $beginMarker in README.md');
    expect(end, greaterThan(begin), reason: 'missing $endMarker in README.md');

    return readme
        .sublist(begin + 1, end)
        .where((line) => !line.trimLeft().startsWith('```'))
        .where((line) => line.trim().isNotEmpty)
        .toList();
  }

  test('the README quotes a non-trivial block', () {
    expect(
      quotedLines().length,
      greaterThanOrEqualTo(5),
      reason: 'the quoted block looks empty; the markers may be misplaced',
    );
  });

  test('every line quoted in the README is really printed', () {
    final actual = reportLines.map((line) => line.trimRight()).toSet();

    for (final quoted in quotedLines()) {
      expect(
        actual,
        contains(quoted.trimRight()),
        reason: 'README.md quotes a line the example does not print:\n'
            '  $quoted\n'
            'Run `dart run example/haptic_morse_example.dart` and update the '
            'block between $beginMarker and $endMarker.',
      );
    }
  });

  test('the quoted block preserves the order of the real output', () {
    final quoted = quotedLines().map((l) => l.trimRight()).toList();
    final actual = reportLines.map((l) => l.trimRight()).toList();

    var searchFrom = 0;
    for (final line in quoted) {
      final index = actual.indexOf(line, searchFrom);
      expect(
        index,
        isNonNegative,
        reason: 'README.md quotes "$line" out of order',
      );
      searchFrom = index + 1;
    }
  });

  test('the example itself passes every one of its checks', () {
    final report = buildReport();
    final failed =
        report.checks.entries.where((e) => !e.value).map((e) => e.key).toList();

    expect(failed, isEmpty, reason: 'example checks failed: $failed');
    expect(report.checks, isNotEmpty);
  });

  test('the README states the coverage figure the CI gate enforces', () {
    // CI fails below 100%, so the README must not advertise anything else.
    expect(
      readme.any((line) => line.contains('100% line coverage')),
      isTrue,
      reason: 'README.md should state the enforced coverage level',
    );
  });
}
