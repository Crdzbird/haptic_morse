/// Plays haptic Morse sequences on the device motor.
///
/// This library depends on Flutter and on `package:vibration`, and works on
/// Android and iOS only. Import it alongside
/// `package:haptic_morse/haptic_morse.dart`:
///
/// ```dart
/// import 'package:haptic_morse/haptic_morse.dart';
/// import 'package:haptic_morse/haptic_morse_vibration.dart';
///
/// const haptics = HapticVibration();
/// await haptics.vibrateText('SOS');
/// ```
///
/// `package:vibration` is intentionally not re-exported: import it directly if
/// you need its API, so that its releases are not silently breaking changes
/// for this package.
library;

export 'src/haptic/haptic_vibration.dart';
