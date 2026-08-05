// A self-verifying example. Every claim below is checked at runtime, and the
// program exits non-zero if any check fails. Run it with:
//
//   dart run example/haptic_morse_example.dart
//
// It is pure Dart, so it needs no Flutter and no device. CI runs it on every
// push, and test/readme_test.dart checks that the block quoted in README.md
// still matches what this prints.
//
// An example is a script; print is its output channel.
// ignore_for_file: avoid_print

import 'dart:math';

import 'package:haptic_morse/haptic_morse.dart';

void main() {
  final report = buildReport();
  report.lines.forEach(print);

  final failed = report.checks.entries.where((e) => !e.value).toList();
  if (failed.isNotEmpty) {
    throw StateError('failed: ${failed.map((e) => e.key).join(', ')}');
  }
}

/// Builds the full report without printing it.
///
/// Returned rather than printed so that tests can assert on the same lines the
/// example shows, instead of re-deriving them and drifting apart.
({List<String> lines, Map<String, bool> checks}) buildReport() {
  final report = _Report()
    ..line('haptic_morse - self-verifying example')
    ..line('=' * 60);

  _provePatternCarriesMessage(report);
  _proveLeadingZeroMatters(report);
  _proveTimingIsConformant(report);
  _proveSequenceIsWellFormed(report);
  _proveRoundTrips(report);
  _showFarnsworth(report);

  final passed = report.checks.values.where((v) => v).length;
  report
    ..blank()
    ..line('=' * 60)
    ..line('$passed/${report.checks.length} checks passed');

  return (lines: report.lines, checks: report.checks);
}

/// The strongest proof available without a motor: take the raw list of
/// integers handed to the platform, reinterpret it using only the documented
/// convention, and recover the original text from it.
void _provePatternCarriesMessage(_Report report) {
  const input = 'SOS';
  const morse = HapticMorse();

  final code = morse.convertTextToMorseString(input)!;
  final pattern = input.toVibrationPattern();
  final recoveredCode = readMorseFromPattern(pattern);
  final recoveredText = morse.decodeMorseString(recoveredCode);

  report
    ..section('1. The pattern actually carries the message')
    ..field('text', '"$input"')
    ..field('morse', code)
    ..field('pattern', '$pattern')
    ..blank()
    ..line('   Read back using only the platform rule (even index = motor')
    ..line('   off, odd index = motor on), with no reference to this package:')
    ..blank()
    ..field('timeline', timeline(pattern))
    ..field('recovered morse', recoveredCode)
    ..field('recovered text', '"$recoveredText"')
    ..check(
      'pattern decodes to the original morse',
      passed: recoveredCode == code,
    )
    ..check(
      'pattern decodes to the original text',
      passed: recoveredText == input,
    );
}

/// The bug that made 2.0.0 a breaking release, demonstrated rather than
/// described.
void _proveLeadingZeroMatters(_Report report) {
  const input = 'SOS';
  const morse = HapticMorse();

  final correct = input.toVibrationPattern();
  // Version 1.x emitted exactly this: the same durations with no leading off
  // delay, so the platform played every symbol in a silence slot.
  final legacy = correct.sublist(1);
  final legacyCode = readMorseFromPattern(legacy);
  final legacyText = morse.decodeMorseString(legacyCode) ?? '(undecodable)';

  report
    ..section('2. Why the leading zero matters')
    ..field('1.x pattern', '$legacy')
    ..field('1.x timeline', timeline(legacy))
    ..field('plays as morse', legacyCode)
    ..field('plays as text', '"$legacyText"')
    ..field('expected', '"$input"')
    ..check(
      'the 1.x pattern played as something else',
      passed: legacyText != input,
    )
    ..check(
      'the 2.0.0 pattern starts with an off delay',
      passed: correct.first == 0,
    );
}

/// ITU-R M.1677-1 defines Morse speed by the word PARIS, which measures
/// exactly 50 units. If that holds, every element and gap ratio is correct.
void _proveTimingIsConformant(_Report report) {
  const morse = HapticMorse();
  const unit = 100; // the default dot duration

  final word = morse.convertTextToModel('PARIS').totalDuration;
  final pair = morse.convertTextToModel('PARIS PARIS').totalDuration;
  final wordSpace = pair - 2 * word;
  final units = (word + wordSpace) ~/ unit;
  final wpm = 60000 / (word + wordSpace);

  report
    ..section('3. Timing matches the international standard')
    ..field('dot / dash', '$unit ms / ${3 * unit} ms   (spec ratio 1:3)')
    ..field('PARIS + space', '$units units   (spec 50)')
    ..field('speed', '${wpm.toStringAsFixed(1)} WPM   (spec 1200/dot = 12)')
    ..check('PARIS measures 50 units', passed: units == 50)
    ..check('speed matches 1200/dot', passed: wpm == 1200 / unit);
}

/// The sequence contract: strictly alternating, starting and ending with a
/// vibration, with no two adjacent gaps. Checked against inputs whose edges
/// used to break it.
void _proveSequenceIsWellFormed(_Report report) {
  const morse = HapticMorse();
  const awkward = [
    'SOS',
    '  leading space',
    'trailing space  ',
    'double  space',
    'unmapped tail ¥',
    'a ¥¥ word of unmapped characters',
  ];

  report.section('4. The sequence stays well formed at every edge');

  var all = true;
  for (final input in awkward) {
    final events = morse.convertTextToHapticEvents(input);
    final ok = isWellFormed(events);
    all &= ok;
    report.line('   ${ok ? '[ok]  ' : '[FAIL]'} '
        '${events.length.toString().padLeft(3)} events  "$input"');
  }

  report.check('every edge case is well formed', passed: all);
}

void _proveRoundTrips(_Report report) {
  const morse = HapticMorse();
  const samples = [
    'SOS',
    'HELLO WORLD',
    'THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG',
    'HELLO, WORLD!',
    r'COST: $5.00',
    'USER@EXAMPLE.COM',
    '0123456789',
  ];

  report.section('5. Encoding round-trips, punctuation included');

  var all = true;
  for (final sample in samples) {
    final viaCode =
        morse.decodeMorseString(morse.convertTextToMorseString(sample));
    final viaEvents =
        morse.decodeEvents(morse.convertTextToHapticEvents(sample));
    final ok = viaCode == sample && viaEvents == sample;
    all &= ok;
    report.line('   ${ok ? '[ok]  ' : '[FAIL]'} "$sample"');
  }

  report.check('every sample round-trips', passed: all);
}

/// Farnsworth timing keeps each character crisp while slowing the message,
/// the setting that matters most for reading Morse through skin.
void _showFarnsworth(_Report report) {
  final plain = HapticMorse.atSpeed(wordsPerMinute: 20);
  final learner = HapticMorse.atSpeed(
    wordsPerMinute: 20,
    effectiveWordsPerMinute: 8,
  );

  report
    ..section('6. Farnsworth timing, for readable haptics')
    ..line('                     symbol   letter gap   word gap');

  for (final (label, morse) in [('20 WPM', plain), ('20/8 WPM', learner)]) {
    final dot = morse.convertTextToHapticEvents('E').single.duration;
    final letter = morse.convertTextToHapticEvents('EE')[1].duration;
    final word = morse.convertTextToHapticEvents('E E')[1].duration;
    report.line('   ${label.padRight(14)}${'$dot ms'.padLeft(8)}'
        '${'$letter ms'.padLeft(13)}${'$word ms'.padLeft(11)}');
  }

  report.line('   Characters keep their shape; only the silences stretch.');
}

// ---------------------------------------------------------------------------
// Helpers that deliberately know nothing about HapticEvent. They work from the
// raw list of integers and the platform convention alone, which is what makes
// the checks above independent evidence rather than a restatement.
// ---------------------------------------------------------------------------

/// Splits a vibration pattern into (motor on?, milliseconds) segments.
///
/// Index 0 is an off delay and the list alternates from there, the rule shared
/// by Android's VibrationEffect.createWaveform and iOS.
List<({bool on, int ms})> segmentsOf(List<int> pattern) => [
      for (var i = 0; i < pattern.length; i++) (on: i.isOdd, ms: pattern[i]),
    ];

/// Reconstructs dots and dashes from a raw pattern.
///
/// Classifies by duration relative to the shortest vibration, the way someone
/// reading the waveform on a scope would.
String readMorseFromPattern(List<int> pattern) {
  final segments = segmentsOf(pattern).where((s) => s.ms > 0).toList();
  final unit = segments.where((s) => s.on).map((s) => s.ms).reduce(min);

  final buffer = StringBuffer();
  for (final segment in segments) {
    if (segment.on) {
      buffer.write(segment.ms >= 2 * unit ? '-' : '.');
    } else if (segment.ms >= 5 * unit) {
      buffer.write(' / ');
    } else if (segment.ms >= 2 * unit) {
      buffer.write(' ');
    }
  }
  return buffer.toString();
}

/// Renders a pattern as an on/off strip, one cell per unit.
String timeline(List<int> pattern) {
  final segments = segmentsOf(pattern).where((s) => s.ms > 0).toList();
  final unit = segments.where((s) => s.on).map((s) => s.ms).reduce(min);

  final buffer = StringBuffer();
  for (final segment in segments) {
    buffer.write((segment.on ? '#' : '_') * (segment.ms ~/ unit));
  }
  return buffer.toString();
}

/// Whether a sequence satisfies the contract documented on HapticEvent.
bool isWellFormed(List<HapticEvent> events) {
  if (events.isEmpty) return true;
  if (!events.first.isVibration || !events.last.isVibration) return false;
  for (var i = 1; i < events.length; i++) {
    if (events[i].isVibration == events[i - 1].isVibration) return false;
  }
  return events.every((e) => e.duration > 0);
}

/// Accumulates report lines and check results.
class _Report {
  final List<String> lines = [];
  final Map<String, bool> checks = {};

  void line(String text) => lines.add(text);

  void blank() => lines.add('');

  void section(String title) {
    blank();
    line(title);
  }

  /// A label/value row, padded so the values line up.
  void field(String label, String value) =>
      line('   ${label.padRight(16)}: $value');

  void check(String name, {required bool passed}) {
    checks[name] = passed;
    line('   ${passed ? '[ok]  ' : '[FAIL]'} $name');
  }
}
