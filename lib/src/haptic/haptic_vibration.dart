import 'package:haptic_morse/haptic_morse.dart' show HapticModel;
import 'package:haptic_morse/src/model/haptic_model.dart' show HapticModel;
import 'package:meta/meta.dart';
import 'package:vibration/vibration.dart';

import '../model/haptic_event.dart';
import 'haptic_morse.dart';

/// Plays haptic Morse sequences on the device motor.
///
/// This is the only part of the package that depends on Flutter and on
/// `package:vibration`; it lives in a separate library so the encoder stays
/// usable from plain Dart:
///
/// ```dart
/// import 'package:haptic_morse/haptic_morse_vibration.dart';
///
/// const haptics = HapticVibration();
/// await haptics.vibrateText('SOS');
/// ```
///
/// Supported on Android and iOS only.
@immutable
final class HapticVibration {
  /// Creates a vibration controller.
  const HapticVibration();

  /// Whether the device has a vibration motor at all.
  ///
  /// Check this before offering haptic output as a user-facing feature, and
  /// provide a visual or audible alternative when it is `false` — a haptic-only
  /// message is unreadable on a device that cannot vibrate.
  ///
  /// **Returns `false` on emulators, simulators, and any non-mobile host.**
  /// `package:vibration` resolves this from the device info rather than the
  /// motor, and treats every non-physical device as having none. Do not gate
  /// development builds on it or you will only ever see the fallback path.
  /// Prefer [hasCustomVibrationsSupport] for deciding whether Morse can play.
  Future<bool> hasVibrator() => Vibration.hasVibrator();

  /// Whether the device can play a custom waveform.
  ///
  /// This is the check that matters for Morse: when it is `false` the motor can
  /// only be switched on for a fixed duration, so the timing that carries the
  /// message cannot be reproduced. Fall back to showing
  /// [HapticModel.morseCode] rather than playing something illegible.
  ///
  /// Unlike [hasVibrator] this asks the platform directly, so it is meaningful
  /// on emulators. It may return `true` on a device with no motor.
  Future<bool> hasCustomVibrationsSupport() =>
      Vibration.hasCustomVibrationsSupport();

  /// Whether the device can vary vibration strength.
  ///
  /// Only relevant if you pass a non-default `amplitude`; timing-based Morse
  /// does not need it. Carries the same non-physical-device caveat as
  /// [hasVibrator].
  Future<bool> hasAmplitudeControl() => Vibration.hasAmplitudeControl();

  /// Converts [text] to Morse and plays it.
  ///
  /// Pass [morse] to override the timings or alphabet. Returns without
  /// touching the motor when [text] contains nothing encodable.
  ///
  /// [amplitude] is the motor strength from 1 to 255 where supported, or -1
  /// for the device default. [sharpness] is iOS only.
  Future<void> vibrateText(
    String text, {
    HapticMorse morse = const HapticMorse(),
    int amplitude = -1,
    double sharpness = 0.5,
  }) =>
      vibrateEvents(
        morse.convertTextToHapticEvents(text),
        amplitude: amplitude,
        sharpness: sharpness,
      );

  /// Plays an existing haptic sequence.
  ///
  /// The sequence is converted with
  /// [HapticEventPattern.toVibrationPattern], which inserts the leading off
  /// delay the platform expects. Returns without touching the motor when
  /// [events] is empty.
  Future<void> vibrateEvents(
    List<HapticEvent> events, {
    int amplitude = -1,
    double sharpness = 0.5,
  }) async {
    if (events.isEmpty) return;
    await vibrate(
      pattern: events.toVibrationPattern(),
      amplitude: amplitude,
      sharpness: sharpness,
    );
  }

  /// Vibrate with the given parameters.
  ///
  /// A thin pass-through to `Vibration.vibrate` for callers that already have
  /// a pattern. Note that index 0 of [pattern] is an *off* delay and the list
  /// alternates off/on from there; prefer [vibrateEvents], which handles that
  /// convention for you.
  ///
  /// [duration] The duration of the vibration in milliseconds.
  /// [pattern] The vibration pattern as a list of durations.
  /// [repeat] The index to repeat from, or -1 for no repeat.
  /// [intensities] The intensity levels for each vibration segment.
  /// [amplitude] The amplitude of the vibration (1-255, or -1 for default).
  /// [sharpness] The sharpness of the vibration (0.0-1.0). iOS only.
  Future<void> vibrate({
    int duration = 500,
    List<int> pattern = const [],
    int repeat = -1,
    List<int> intensities = const [],
    int amplitude = -1,
    double sharpness = 0.5,
  }) =>
      Vibration.vibrate(
        duration: duration,
        pattern: pattern,
        repeat: repeat,
        intensities: intensities,
        amplitude: amplitude,
        sharpness: sharpness,
      );

  /// Cancel any ongoing vibration.
  Future<void> cancel() => Vibration.cancel();
}
