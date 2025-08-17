import 'package:haptic_morse/haptic_morse.dart';

/// Extension on [String] to convert to Morse code and haptic patterns.
extension StringMorseExtension on String {
  /// Returns the haptic-duration pattern for this string,
  /// using either the default or any custom params you pass.
  List<int> toHapticPattern({
    List<String>? charMap,
    String? charReference,
    List<String>? numericMap,
    String? numericReference,
    int? dotDuration,
    int? dashDuration,
    int? gapSymbolDuration,
    int? gapLetterDuration,
    int? gapWordDuration,
    String? symbolReference,
  }) =>
      HapticMorse.custom(
        charMap: charMap,
        charReference: charReference,
        numericMap: numericMap,
        numericReference: numericReference,
        dotDuration: dotDuration,
        dashDuration: dashDuration,
        gapSymbolDuration: gapSymbolDuration,
        gapLetterDuration: gapLetterDuration,
        gapWordDuration: gapWordDuration,
        symbolReference: symbolReference,
      ).convertTextToHapticPattern(this);

  /// Returns the “.- -...” style Morse string for this string.
  String? toMorseString({
    List<String>? charMap,
    String? charReference,
    List<String>? numericMap,
    String? numericReference,
    int? dotDuration,
    int? dashDuration,
    int? gapSymbolDuration,
    int? gapLetterDuration,
    int? gapWordDuration,
    String? symbolReference,
  }) =>
      HapticMorse.custom(
        charMap: charMap,
        charReference: charReference,
        numericMap: numericMap,
        numericReference: numericReference,
        dotDuration: dotDuration,
        dashDuration: dashDuration,
        gapSymbolDuration: gapSymbolDuration,
        gapLetterDuration: gapLetterDuration,
        gapWordDuration: gapWordDuration,
        symbolReference: symbolReference,
      ).convertTextToMorseString(this);

  /// Returns the full map `{ hapticDurations, hapticCount, morseString }`.
  Map<String, dynamic> toMorseMap({
    List<String>? charMap,
    String? charReference,
    List<String>? numericMap,
    String? numericReference,
    int? dotDuration,
    int? dashDuration,
    int? gapSymbolDuration,
    int? gapLetterDuration,
    int? gapWordDuration,
    String? symbolReference,
  }) =>
      HapticMorse.custom(
        charMap: charMap,
        charReference: charReference,
        numericMap: numericMap,
        numericReference: numericReference,
        dotDuration: dotDuration,
        dashDuration: dashDuration,
        gapSymbolDuration: gapSymbolDuration,
        gapLetterDuration: gapLetterDuration,
        gapWordDuration: gapWordDuration,
        symbolReference: symbolReference,
      ).convertTextToMorseMap(this);
}
