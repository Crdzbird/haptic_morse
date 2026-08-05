import 'package:meta/meta.dart';

/// A single element of a haptic Morse sequence.
///
/// A sequence produced by `HapticMorse` strictly alternates between vibration
/// events ([HapticDot], [HapticDash]) and silent gap events
/// ([HapticSymbolGap], [HapticLetterGap], [HapticWordGap]). It always starts
/// and ends with a vibration event, and never contains two adjacent events of
/// the same phase.
///
/// Switch over the sealed hierarchy to react to each element:
///
/// ```dart
/// for (final event in 'SOS'.toHapticEvents()) {
///   final label = switch (event) {
///     HapticDot() => 'dot',
///     HapticDash() => 'dash',
///     HapticSymbolGap() => 'symbol gap',
///     HapticLetterGap() => 'letter gap',
///     HapticWordGap() => 'word gap',
///   };
///   print('$label for ${event.duration}ms');
/// }
/// ```
@immutable
sealed class HapticEvent {
  /// Creates an event lasting [duration] milliseconds.
  const HapticEvent(this.duration);

  /// Vibrations shorter than this are unlikely to be felt.
  ///
  /// This is a **heuristic, not a specification**. An eccentric-rotating-mass
  /// motor needs tens of milliseconds to spin up and down, so a very short
  /// pulse never reaches a perceptible amplitude; linear resonant actuators
  /// and Taptic-style hardware respond faster. The real floor is device
  /// specific, which is why nothing in this package rejects a shorter
  /// duration - a sequence may legitimately be rendered, analysed, or sent
  /// somewhere other than a motor.
  ///
  /// Use it as an advisory check on timings you did not choose yourself:
  ///
  /// ```dart
  /// final events = text.toHapticEvents(morse);
  /// if (!events.isLikelyPerceptible) {
  ///   // Too fast for this hardware; slow down or show the code instead.
  /// }
  /// ```
  ///
  /// At the standard `1200 / wpm` unit this corresponds to roughly 60 words
  /// per minute, well above conversational Morse and far above anything
  /// readable through skin.
  static const int minimumPerceptibleMilliseconds = 20;

  /// How long this event lasts, in milliseconds. Always positive.
  final int duration;

  /// Whether the motor is running for the length of this event.
  ///
  /// `true` for [HapticDot] and [HapticDash]; `false` for every gap.
  bool get isVibration;

  /// Stable discriminator used by [toJson].
  ///
  /// CONTRACT: these strings are part of the serialized format. Changing one
  /// breaks stored payloads.
  String get type;

  /// Converts this event into a JSON-encodable map.
  Map<String, dynamic> toJson() => {'type': type, 'duration': duration};

  /// Recreates an event from a map produced by [toJson].
  ///
  /// Throws [ArgumentError] if `type` is missing or unrecognized, or if
  /// `duration` is absent or not a number.
  static HapticEvent fromJson(Map<String, dynamic> json) {
    final duration = json['duration'];
    if (duration is! num) {
      throw ArgumentError.value(
        json['duration'],
        'duration',
        'HapticEvent requires a numeric duration',
      );
    }
    final ms = duration.toInt();
    return switch (json['type']) {
      'dot' => HapticDot(ms),
      'dash' => HapticDash(ms),
      'symbolGap' => HapticSymbolGap(ms),
      'letterGap' => HapticLetterGap(ms),
      'wordGap' => HapticWordGap(ms),
      final unknown => throw ArgumentError.value(
          unknown,
          'type',
          'Unknown HapticEvent type',
        ),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HapticEvent &&
          other.runtimeType == runtimeType &&
          other.duration == duration;

  @override
  int get hashCode => Object.hash(runtimeType, duration);

  @override
  String toString() => 'HapticEvent($type, ${duration}ms)';
}

/// A short vibration - the `.` of Morse code.
final class HapticDot extends HapticEvent {
  /// Creates a dot lasting [duration] milliseconds.
  const HapticDot(super.duration);

  @override
  bool get isVibration => true;

  @override
  String get type => 'dot';
}

/// A long vibration - the `-` of Morse code.
final class HapticDash extends HapticEvent {
  /// Creates a dash lasting [duration] milliseconds.
  const HapticDash(super.duration);

  @override
  bool get isVibration => true;

  @override
  String get type => 'dash';
}

/// The silence between two symbols of the same letter.
final class HapticSymbolGap extends HapticEvent {
  /// Creates a symbol gap lasting [duration] milliseconds.
  const HapticSymbolGap(super.duration);

  @override
  bool get isVibration => false;

  @override
  String get type => 'symbolGap';
}

/// The silence between two letters of the same word.
final class HapticLetterGap extends HapticEvent {
  /// Creates a letter gap lasting [duration] milliseconds.
  const HapticLetterGap(super.duration);

  @override
  bool get isVibration => false;

  @override
  String get type => 'letterGap';
}

/// The silence between two words.
final class HapticWordGap extends HapticEvent {
  /// Creates a word gap lasting [duration] milliseconds.
  const HapticWordGap(super.duration);

  @override
  bool get isVibration => false;

  @override
  String get type => 'wordGap';
}

/// Conversion helpers for a sequence of [HapticEvent]s.
extension HapticEventPattern on List<HapticEvent> {
  /// Converts this sequence into a pattern for `Vibration.vibrate`.
  ///
  /// The returned list follows the platform convention shared by Android's
  /// `VibrationEffect.createWaveform` and the iOS side of
  /// `package:vibration`: **index 0 is an off delay**, and the list alternates
  /// off/on from there. A leading `0` is therefore always emitted so that the
  /// first real element is a vibration.
  ///
  /// ```dart
  /// 'E'.toHapticEvents().toVibrationPattern(); // [0, 100]
  /// ```
  ///
  /// Adjacent events of the same phase are merged into a single entry. Well
  /// formed sequences never contain any, so this only guards hand-assembled
  /// lists; without it a single stray pair would invert every symbol that
  /// follows it.
  List<int> toVibrationPattern() {
    if (isEmpty) return const [];

    final pattern = <int>[];
    // The platform starts in the off phase, so an initial 0 lines the first
    // vibration event up with an on slot.
    var expectingVibration = true;
    pattern.add(0);

    for (final event in this) {
      if (event.isVibration == expectingVibration) {
        pattern.add(event.duration);
        expectingVibration = !expectingVibration;
      } else {
        // Same phase as the previous entry: extend it rather than emitting a
        // new slot, which would flip the phase of everything after it.
        pattern[pattern.length - 1] += event.duration;
      }
    }

    return List<int>.unmodifiable(pattern);
  }

  /// The total duration of this sequence in milliseconds.
  int get totalDuration => fold(0, (sum, event) => sum + event.duration);

  /// Vibrations in this sequence too short to be reliably felt.
  ///
  /// Gaps are ignored: a gap that is too short makes two symbols run together,
  /// which is a legibility problem rather than a perceptibility one, and it is
  /// already prevented by the standard timing ratios.
  ///
  /// See [HapticEvent.minimumPerceptibleMilliseconds] for what this does and
  /// does not promise.
  Iterable<HapticEvent> get imperceptibleEvents => where(
        (event) =>
            event.isVibration &&
            event.duration < HapticEvent.minimumPerceptibleMilliseconds,
      );

  /// Whether every vibration in this sequence is long enough to be felt.
  ///
  /// A heuristic - see [HapticEvent.minimumPerceptibleMilliseconds].
  bool get isLikelyPerceptible => imperceptibleEvents.isEmpty;
}
