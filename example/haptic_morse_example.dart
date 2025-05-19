import 'package:haptic_morse/haptic_morse.dart';

void main() {
  var hapticMorse = HapticMorse();
  var morseCode = hapticMorse.convertTextToMorseString("SOS 123");
  print(
    morseCode,
  ); // Output: [100, 300, 100, 100, 300, 700, 100, 300, 100, 100, 300]
}
