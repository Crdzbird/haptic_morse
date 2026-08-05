// A self-verifying example: every claim below is checked at runtime, and the
// program throws if any check fails. Run it with:
//
//   dart run example/haptic_morse_example.dart
//
// It is pure Dart — no Flutter, no device — and CI runs it on every push.
//
// An example is a script; print is its output channel.
// ignore_for_file: avoid_print

import 'dart:math';

import 'package:haptic_morse/haptic_morse.dart';

void main() {
  final checks = <String, bool>{};

  print('haptic_morse — self-verifying example');
  print('=' * 60);

  _proveThePatternCarriesTheMessage(checks);
  _proveTheLeadingZeroMatters(checks);
  _proveTimingIsStandardsConformant(checks);
  _proveTheSequenceIsWellFormed(checks);
  _proveRoundTrips(checks);
  _showFarnsworth();

  print('');
  print('=' * 60);
  final failed = checks.entries.where((e) => !e.value).toList();
  print('${checks.length - failed.length}/${checks.length} checks passed');
  if (failed.isNotEmpty) {
    throw StateError('failed: ${failed.map((e) => e.key).join(', ')}');
  }
}

/// The strongest proof available without a motor: take the raw `List<int>`
/// that is handed to the platform, reinterpret it using only the documented
/// convention, and recover the original text from it.
void _proveThePatternCarriesTheMessage(Map<String, bool> checks) {
  const input = 'SOS';
  const morse = HapticMorse();

  final code = morse.convertTextToMorseString(input)!;
  final pattern = input.toVibrationPattern();

  _section('1. The pattern actually carries the message');
  print('   text            : "$input"');
  print('   morse           : $code');
  print('   pattern         : $pattern');
  print('');
  print('   Read back using only the platform rule — even index = motor');
  print('   off, odd index = motor on — with no reference to this package:');
  print('');
  print('   ${_timeline(pattern)}');
  print('');

  final recoveredCode = _readMorseFromPattern(pattern);
  final recoveredText = morse.decodeMorseString(recoveredCode);

  print('   recovered morse : $recoveredCode');
  print('   recovered text  : "$recoveredText"');

  _check(
    checks,
    'pattern decodes to the original morse',
    recoveredCode == code,
  );
  _check(
    checks,
    'pattern decodes to the original text',
    recoveredText == input,
  );
}

/// The bug that made 2.0.0 a breaking release, demonstrated rather than
/// described.
void _proveTheLeadingZeroMatters(Map<String, bool> checks) {
  const input = 'SOS';
  const morse = HapticMorse();

  final correct = input.toVibrationPattern();
  // Version 1.x emitted exactly this: the same durations with no leading off
  // delay, so the platform played every symbol in a silence slot.
  final legacy = correct.sublist(1);

  final legacyCode = _readMorseFromPattern(legacy);
  final legacyText = morse.decodeMorseString(legacyCode) ?? '(undecodable)';

  _section('2. Why the leading zero matters');
  print('   1.x pattern     : $legacy');
  print('');
  print('   ${_timeline(legacy)}');
  print('');
  print('   plays as morse  : $legacyCode');
  print('   plays as text   : "$legacyText"');
  print('   expected        : "$input"');

  _check(
    checks,
    'the 1.x pattern really did play as something else',
    legacyText != input,
  );
  _check(
    checks,
    'the 2.0.0 pattern starts with an off delay',
    correct.first == 0,
  );
}

/// ITU-R M.1677-1 defines Morse speed by the word `PARIS`, which measures
/// exactly 50 units. If that holds, every element and gap ratio is correct.
void _proveTimingIsStandardsConformant(Map<String, bool> checks) {
  const morse = HapticMorse();
  const unit = 100; // the default dot duration

  final word = morse.convertTextToModel('PARIS').totalDuration;
  final pair = morse.convertTextToModel('PARIS PARIS').totalDuration;
  final wordSpace = pair - 2 * word;
  final units = (word + wordSpace) ~/ unit;
  final wpm = 60000 / (word + wordSpace);

  _section('3. Timing matches the international standard');
  print('   dot / dash      : $unit ms / ${3 * unit} ms      (spec 1 : 3)');
  print('   PARIS + space   : $units units          (spec 50)');
  print('   speed           : ${wpm.toStringAsFixed(1)} WPM'
      '            (spec 1200/dot = ${1200 ~/ unit})');

  _check(checks, 'PARIS measures 50 units', units == 50);
  _check(checks, 'speed matches 1200/dot', wpm == 1200 / unit);
}

/// The sequence contract: strictly alternating, starting and ending with a
/// vibration, with no two adjacent gaps. Checked against inputs whose edges
/// used to break it.
void _proveTheSequenceIsWellFormed(Map<String, bool> checks) {
  const morse = HapticMorse();
  const awkward = [
    'SOS',
    '  leading space',
    'trailing space  ',
    'double  space',
    'trailing emoji 🙂',
    '🙂 leading emoji',
    'a 🙂🙂 word of only emoji',
  ];

  _section('4. The sequence stays well formed at every edge');

  var allWellFormed = true;
  for (final input in awkward) {
    final events = morse.convertTextToHapticEvents(input);
    final wellFormed = _isWellFormed(events);
    allWellFormed &= wellFormed;
    print('   ${wellFormed ? '✓' : '✗'} ${events.length.toString().padLeft(3)} '
        'events  "$input"');
  }

  _check(checks, 'every edge case is well formed', allWellFormed);
}

void _proveRoundTrips(Map<String, bool> checks) {
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

  _section('5. Encoding round-trips, punctuation included');

  var allRoundTrip = true;
  for (final sample in samples) {
    final viaCode =
        morse.decodeMorseString(morse.convertTextToMorseString(sample));
    final viaEvents =
        morse.decodeEvents(morse.convertTextToHapticEvents(sample));
    final ok = viaCode == sample && viaEvents == sample;
    allRoundTrip &= ok;
    print('   ${ok ? '✓' : '✗'} "$sample"');
  }

  _check(checks, 'every sample round-trips', allRoundTrip);
}

/// Farnsworth timing keeps each character crisp while slowing the message —
/// the setting that matters most for reading Morse through skin.
void _showFarnsworth() {
  final plain = HapticMorse.atSpeed(wordsPerMinute: 20);
  final learner = HapticMorse.atSpeed(
    wordsPerMinute: 20,
    effectiveWordsPerMinute: 8,
  );

  _section('6. Farnsworth timing, for readable haptics');
  print('                     symbol   letter gap   word gap');
  for (final (label, morse) in [('20 WPM', plain), ('20/8 WPM', learner)]) {
    final dot = morse.convertTextToHapticEvents('E').single.duration;
    final letter = morse.convertTextToHapticEvents('EE')[1].duration;
    final word = morse.convertTextToHapticEvents('E E')[1].duration;
    print('   ${label.padRight(14)}${'$dot ms'.padLeft(8)}'
        '${'$letter ms'.padLeft(13)}${'$word ms'.padLeft(11)}');
  }
  print('   Characters keep their shape; only the silences stretch.');
}

// ---------------------------------------------------------------------------
// Helpers that deliberately know nothing about HapticEvent. They work from the
// raw List<int> and the platform convention alone, which is what makes the
// checks above independent evidence rather than a restatement.
// ---------------------------------------------------------------------------

/// Splits a vibration pattern into (motor on?, milliseconds) segments.
///
/// Index 0 is an off delay and the list alternates from there — the rule
/// shared by Android's `VibrationEffect.createWaveform` and iOS.
List<({bool on, int ms})> _segments(List<int> pattern) => [
      for (var i = 0; i < pattern.length; i++) (on: i.isOdd, ms: pattern[i]),
    ];

/// Reconstructs dots and dashes from a raw pattern.
///
/// Classifies by duration relative to the shortest vibration, the way a person
/// reading the waveform would.
String _readMorseFromPattern(List<int> pattern) {
  final segments = _segments(pattern).where((s) => s.ms > 0).toList();
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
String _timeline(List<int> pattern) {
  final segments = _segments(pattern).where((s) => s.ms > 0).toList();
  final unit = segments.where((s) => s.on).map((s) => s.ms).reduce(min);

  final buffer = StringBuffer();
  for (final segment in segments) {
    buffer.write((segment.on ? '█' : '·') * (segment.ms ~/ unit));
  }
  return buffer.toString();
}

bool _isWellFormed(List<HapticEvent> events) {
  if (events.isEmpty) return true;
  if (!events.first.isVibration || !events.last.isVibration) return false;
  for (var i = 1; i < events.length; i++) {
    if (events[i].isVibration == events[i - 1].isVibration) return false;
  }
  return events.every((e) => e.duration > 0);
}

void _section(String title) {
  print('');
  print(title);
}

void _check(Map<String, bool> checks, String name, bool passed) {
  checks[name] = passed;
  print('   ${passed ? '✓' : '✗'} $name');
}
