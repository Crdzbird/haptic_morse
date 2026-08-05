import 'package:haptic_morse/haptic_morse.dart';

/// A class that converts text to Morse code and haptic patterns.
///
/// This class provides functionality to:
/// - Convert text to Morse code string representation (dots and dashes)
/// - Generate haptic duration sequences for vibration feedback
/// - Support custom character sets and Morse code mappings
final class HapticMorse {
  /// Creates a HapticMorse instance with custom mappings and timing parameters.
  ///
  /// [charMap] - List of Morse code patterns for characters (e.g., [".-", "-...", etc.])
  /// [charReference] - String containing characters corresponding to charMap indices, remember to keep it in the same order as charMap
  /// [numericMap] - List of Morse code patterns for numeric digits
  /// [numericReference] - String containing digits corresponding to numericMap indices
  /// [dotDuration] - Duration in milliseconds for a dot vibration
  /// [dashDuration] - Duration in milliseconds for a dash vibration
  /// [gapSymbolDuration] - Duration in milliseconds between symbols in the same character
  /// [gapLetterDuration] - Duration in milliseconds between letters
  /// [gapWordDuration] - Duration in milliseconds between words
  factory HapticMorse.custom({
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
  }) {
    return HapticMorse._(
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
    );
  }

  /// Creates a HapticMorse instance with default or custom settings.
  ///
  /// By default, uses standard International Morse Code for Latin alphabet (A-Z)
  /// and numerals (0-9) with standard timing ratios.
  const HapticMorse({
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
  }) : this._(
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
        );

  /// Private constructor with defaulted values
  const HapticMorse._({
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
  })  : _charMap = charMap ?? _defaultCharMap,
        _charReference = charReference ?? _defaultCharReference,
        _numericMap = numericMap ?? _defaultNumericMap,
        _numericReference = numericReference ?? _defaultNumericReference,
        _dotDuration = dotDuration ?? 100,
        _dashDuration = dashDuration ?? 300,
        _gapSymbolDuration = gapSymbolDuration ?? 100,
        _gapLetterDuration = gapLetterDuration ?? 300,
        _gapWordDuration = gapWordDuration ?? 700,
        _symbolReference = symbolReference ?? '.';

  // Default character Morse code map (A-Z)
  static const List<String> _defaultCharMap = [
    ".-", "-...", "-.-.", "-..", ".", // A-E
    "..-.", "--.", "....", "..", ".---", // F-J
    "-.-", ".-..", "--", "-.", "---", // K-O
    ".--.", "--.-", ".-.", "...", "-", // P-T
    "..-", "...-", ".--", "-..-", "-.--", // U-Y
    "--..", // Z
  ];

  // Default numeric Morse code map (0-9)
  static const List<String> _defaultNumericMap = [
    "-----", ".----", "..---", "...--", "....-", ".....", // 0-5
    "-....", "--...", "---..", "----.", // 6-9
  ];

  // Default character reference for Latin alphabet
  static const String _defaultCharReference = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

  // Default numeric reference
  static const String _defaultNumericReference = "0123456789";

  // Timing durations in milliseconds
  final int _dotDuration;
  final int _dashDuration;
  final int _gapSymbolDuration; // Gap between symbols within same letter
  final int _gapLetterDuration; // Gap between letters
  final int _gapWordDuration; // Gap between words

  // Character and Morse code maps
  final List<String> _charMap;
  final List<String> _numericMap;
  final String _charReference; // Reference string for characters
  final String _numericReference; // Reference string for digits
  final String _symbolReference; // Reference for dot symbol

  /// Finds the index of a character in the appropriate reference map.
  ///
  /// Returns a tuple with:
  /// - isInt: `true` when matched against [_numericReference], `false` when
  ///   matched against [_charReference]
  /// - Index: Position in the corresponding Morse code map
  ///
  /// The numeric reference is consulted first, so an entry appearing in both
  /// references resolves to the numeric map. Lookups are case-insensitive:
  /// the input is upper-cased and compared against the references as given.
  ///
  /// Returns null if the character is not found in any reference map.
  (bool isInt, int)? _findCharacterIndex(String character) {
    final char = character.toUpperCase();

    // Try to find in numeric reference map.
    //
    // This previously went through a RegExp built by interpolating
    // _numericReference, which (a) recompiled the pattern on every character,
    // (b) threw a FormatException when the reference held a regex metacharacter
    // such as '(', and (c) tested the raw character against an upper-cased
    // pattern while looking up the upper-cased character. A direct indexOf is
    // equivalent for the default digit reference and consistent with how the
    // alphabet reference below is already resolved.
    final numIndex = _numericReference.indexOf(char);
    if (numIndex >= 0 && numIndex < _numericMap.length) {
      return (true, numIndex);
    }

    // Try to find in alphabet reference map
    final alphaIndex = _charReference.indexOf(char);
    if (alphaIndex >= 0 && alphaIndex < _charMap.length) {
      return (false, alphaIndex);
    }

    // Character not supported
    return null;
  }

  /// Converts text to a sequence of haptic durations in milliseconds.
  ///
  /// The list interleaves symbol durations (dot/dash) with gap durations,
  /// starting with a symbol. Unsupported characters are skipped.
  ///
  /// Returns an empty list if input is null or empty.
  List<int> convertTextToHapticPattern(String? input) {
    if (input == null || input.isEmpty) return [];

    final hapticPattern = <int>[];
    var isFirstWord = true;

    for (var i = 0; i < input.length; i++) {
      final char = input[i].toUpperCase();

      // Handle space character
      if (char == ' ') {
        if (!isFirstWord) hapticPattern.add(_gapWordDuration);
        isFirstWord = false;
        continue;
      }

      final charIndex = _findCharacterIndex(char);
      if (charIndex == null) continue; // Skip unsupported characters

      isFirstWord = false;

      // Get the morse code pattern for this character
      final morsePattern = charIndex.$1 == false
          ? _charMap[charIndex.$2]
          : _numericMap[charIndex.$2];

      // Add haptic durations for each symbol (dot/dash)
      for (var j = 0; j < morsePattern.length; j++) {
        hapticPattern.add(
          morsePattern[j] == _symbolReference ? _dotDuration : _dashDuration,
        );

        // Add gap between symbols (except after the last symbol)
        if (j < morsePattern.length - 1) {
          hapticPattern.add(_gapSymbolDuration);
        }
      }

      // Add letter gap after each character (except the last one or before a space)
      if (i < input.length - 1 && input[i + 1] != ' ') {
        hapticPattern.add(_gapLetterDuration);
      }
    }

    return hapticPattern;
  }

  /// Converts text to readable Morse code string representation.
  ///
  /// Format: ".- -... -.-."  (dots and dashes separated by spaces)
  /// Words are separated by " / "
  ///
  /// Returns null if input is null or empty.
  String? convertTextToMorseString(String? input) {
    if (input == null || input.isEmpty) return null;

    final morseText = StringBuffer();
    var isFirstCharacter = true;

    for (var i = 0; i < input.length; i++) {
      final char = input[i].toUpperCase();

      // Handle space character
      if (char == ' ') {
        if (!isFirstCharacter) {
          morseText.write(' / ');
          isFirstCharacter = true;
        }
        continue;
      }

      final charIndex = _findCharacterIndex(char);
      if (charIndex == null) continue; // Skip unsupported characters

      // Add space between characters
      if (!isFirstCharacter) morseText.write(' ');

      // Get the morse code for this character
      final morse = charIndex.$1 == false
          ? _charMap[charIndex.$2]
          : _numericMap[charIndex.$2];

      morseText.write(morse);
      isFirstCharacter = false;
    }

    return morseText.toString();
  }

  /// Converts text to both haptic pattern and Morse code string.
  ///
  /// Returns a [HapticModel] whose fields are:
  /// - [HapticModel.text]: the original input
  /// - [HapticModel.morseCode]: the dot/dash representation
  /// - [HapticModel.hapticDurations]: the vibration durations
  ///
  /// Returns a default-constructed [HapticModel] if input is null or empty.
  HapticModel convertTextToMorseMap(String? input) {
    if (input == null || input.isEmpty) return HapticModel();
    final hapticDurations = convertTextToHapticPattern(input);
    final morseString = convertTextToMorseString(input);
    return HapticModel(
      text: input,
      morseCode: morseString ?? '',
      hapticDurations: hapticDurations,
    );
  }
}
