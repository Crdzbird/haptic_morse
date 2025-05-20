import 'package:haptic_morse/haptic_morse.dart';

void main() {
  final morse = HapticMorse.custom(
    charMap: ['.-', '-...', '☀️-', '💧💧'], // Your custom Morse patterns
    charReference: 'AB日水', // Must match the map's order
    numericMap: ['...', '...-', '💎', '🌙'],
    numericReference: '0123', // Also in order
  );
  final output = morse.convertTextToMorseString("AB日水");
  print(output);
}
