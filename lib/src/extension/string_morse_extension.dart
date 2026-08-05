import '../haptic/haptic_morse.dart';
import '../model/haptic_event.dart';
import '../model/haptic_model.dart';

/// Morse conversions directly on [String].
///
/// Each method takes an optional [HapticMorse]; omit it for standard
/// International Morse Code, or pass a configured instance to override the
/// timings or the alphabet:
///
/// ```dart
/// 'SOS'.toMorseString(); // "... --- ..."
/// 'SOS'.toMorseString(HapticMorse.custom(dotDuration: 80));
/// ```
extension StringMorseExtension on String {
  /// The Morse code for this string, or `null` if nothing could be encoded.
  ///
  /// See [HapticMorse.convertTextToMorseString].
  String? toMorseString([HapticMorse morse = const HapticMorse()]) =>
      morse.convertTextToMorseString(this);

  /// The haptic sequence for this string.
  ///
  /// See [HapticMorse.convertTextToHapticEvents].
  List<HapticEvent> toHapticEvents([
    HapticMorse morse = const HapticMorse(),
  ]) =>
      morse.convertTextToHapticEvents(this);

  /// A [HapticModel] describing this string.
  ///
  /// See [HapticMorse.convertTextToModel].
  HapticModel toMorseModel([HapticMorse morse = const HapticMorse()]) =>
      morse.convertTextToModel(this);

  /// The vibration pattern for this string, ready for `Vibration.vibrate`.
  ///
  /// Shorthand for `toHapticEvents(morse).toVibrationPattern()`.
  List<int> toVibrationPattern([
    HapticMorse morse = const HapticMorse(),
  ]) =>
      morse.convertTextToHapticEvents(this).toVibrationPattern();
}
