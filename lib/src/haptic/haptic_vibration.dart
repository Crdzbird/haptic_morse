import 'package:vibration/vibration.dart';

/// Vibration utility for haptic feedback.
final class HapticVibration {
  /// Constructor to prevent instantiation.
  const HapticVibration();

  /// Vibrate with the given parameters.
  /// [duration] The duration of the vibration in milliseconds.
  /// [pattern] The vibration pattern as a list of durations.
  /// [repeat] The number of times to repeat the pattern.
  /// [intensities] The intensity levels for each vibration segment.
  /// [amplitude] The amplitude of the vibration (0-255).
  /// [sharpness] The sharpness of the vibration (0.0-1.0).
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
