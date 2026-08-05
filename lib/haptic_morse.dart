/// Convert text to Morse code and to haptic vibration sequences.
///
/// This library is pure Dart — it does not import Flutter — so it runs in a
/// CLI, on a server, and in `dart test`. To drive the device motor, import
/// `package:haptic_morse/haptic_morse_vibration.dart` as well.
///
/// ```dart
/// import 'package:haptic_morse/haptic_morse.dart';
///
/// void main() {
///   print('SOS'.toMorseString());        // ... --- ...
///   print('SOS'.toVibrationPattern());   // [0, 100, 100, 100, ...]
/// }
/// ```
library;

export 'src/extension/string_morse_extension.dart';
export 'src/haptic/haptic_morse.dart';
export 'src/model/haptic_event.dart';
export 'src/model/haptic_model.dart';
