import 'package:characters/characters.dart';

import '../model/haptic_event.dart';
import '../model/haptic_model.dart';

/// Converts text to Morse code and to haptic sequences.
///
/// Use the const default for standard International Morse Code:
///
/// ```dart
/// const morse = HapticMorse();
/// morse.convertTextToMorseString('SOS'); // "... --- ..."
/// ```
///
/// Use [HapticMorse.custom] to change timings or supply your own alphabet.
/// Unlike the default constructor it validates its arguments and throws
/// [ArgumentError] on an inconsistent configuration.
///
/// Text is segmented into user-perceived characters (grapheme clusters), so
/// characters outside the Basic Multilingual Plane — including emoji with
/// variation selectors or zero-width joiners — work in a custom alphabet.
final class HapticMorse {
  /// Creates an encoder for standard International Morse Code (A-Z, 0-9)
  /// with standard timing ratios of 1/3/1/3/7 units.
  ///
  /// This configuration is always valid, so it is a `const` constructor and
  /// performs no validation.
  const HapticMorse()
      : _symbols = _defaultSymbols,
        _dotDuration = 100,
        _dashDuration = 300,
        _gapSymbolDuration = 100,
        _gapLetterDuration = 300,
        _gapWordDuration = 700,
        _dotSymbol = '.',
        _dashSymbol = '-';

  /// Creates an encoder with custom mappings and/or timings.
  ///
  /// Any omitted argument falls back to its standard value, so
  /// `HapticMorse.custom(dotDuration: 80)` keeps the standard alphabet.
  ///
  /// - [charMap] / [charReference]: Morse patterns and the characters they
  ///   encode, in matching order.
  /// - [numericMap] / [numericReference]: the same for digits. Entries here
  ///   take precedence over [charReference] on overlap.
  /// - [symbolReference] / [dashReference]: the single characters used to
  ///   spell the patterns in the maps. Default `.` and `-`.
  /// - Durations are in milliseconds and must be positive.
  ///
  /// Throws [ArgumentError] if a map and its reference differ in length, a
  /// reference repeats a character, a pattern is empty or contains anything
  /// other than [symbolReference] and [dashReference], or a duration is not
  /// positive.
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
    String? dashReference,
  }) {
    final dot = symbolReference ?? '.';
    final dash = dashReference ?? '-';

    _requireSingleGrapheme(dot, 'symbolReference');
    _requireSingleGrapheme(dash, 'dashReference');
    if (dot == dash) {
      throw ArgumentError.value(
        dash,
        'dashReference',
        'must differ from symbolReference ("$dot")',
      );
    }

    final resolvedDot = dotDuration ?? 100;
    final resolvedDash = dashDuration ?? 300;
    final resolvedSymbolGap = gapSymbolDuration ?? 100;
    final resolvedLetterGap = gapLetterDuration ?? 300;
    final resolvedWordGap = gapWordDuration ?? 700;

    _requirePositive(resolvedDot, 'dotDuration');
    _requirePositive(resolvedDash, 'dashDuration');
    _requirePositive(resolvedSymbolGap, 'gapSymbolDuration');
    _requirePositive(resolvedLetterGap, 'gapLetterDuration');
    _requirePositive(resolvedWordGap, 'gapWordDuration');

    // Characters first, then digits, so digits win where the two overlap.
    // This preserves the precedence the numeric lookup had in 1.x.
    final symbols = <String, String>{}
      ..addAll(
        _buildSymbols(
          patterns: charMap ?? _respell(_defaultCharMap, dot, dash),
          reference: charReference ?? _defaultCharReference,
          mapName: 'charMap',
          referenceName: 'charReference',
          dot: dot,
          dash: dash,
        ),
      )
      ..addAll(
        _buildSymbols(
          patterns: numericMap ?? _respell(_defaultNumericMap, dot, dash),
          reference: numericReference ?? _defaultNumericReference,
          mapName: 'numericMap',
          referenceName: 'numericReference',
          dot: dot,
          dash: dash,
        ),
      );

    return HapticMorse._(
      symbols: Map<String, String>.unmodifiable(symbols),
      dotDuration: resolvedDot,
      dashDuration: resolvedDash,
      gapSymbolDuration: resolvedSymbolGap,
      gapLetterDuration: resolvedLetterGap,
      gapWordDuration: resolvedWordGap,
      dotSymbol: dot,
      dashSymbol: dash,
    );
  }

  const HapticMorse._({
    required Map<String, String> symbols,
    required int dotDuration,
    required int dashDuration,
    required int gapSymbolDuration,
    required int gapLetterDuration,
    required int gapWordDuration,
    required String dotSymbol,
    required String dashSymbol,
  })  : _symbols = symbols,
        _dotDuration = dotDuration,
        _dashDuration = dashDuration,
        _gapSymbolDuration = gapSymbolDuration,
        _gapLetterDuration = gapLetterDuration,
        _gapWordDuration = gapWordDuration,
        _dotSymbol = dotSymbol,
        _dashSymbol = dashSymbol;

  /// Upper-cased grapheme to Morse pattern. Built once, queried per character.
  final Map<String, String> _symbols;

  final int _dotDuration;
  final int _dashDuration;
  final int _gapSymbolDuration;
  final int _gapLetterDuration;
  final int _gapWordDuration;
  final String _dotSymbol;
  final String _dashSymbol;

  /// Converts text to its Morse code representation.
  ///
  /// Letters are separated by a space and words by `" / "`. Characters with no
  /// mapping are skipped.
  ///
  /// Returns `null` when there is nothing to encode — that is, when [input] is
  /// null, empty, whitespace only, or made entirely of unmapped characters.
  String? convertTextToMorseString(String? input) {
    final words = _tokenize(input);
    if (words.isEmpty) return null;
    return _buildMorseString(words);
  }

  /// Converts text to the haptic sequence that plays it.
  ///
  /// The result strictly alternates vibration and gap events, starts and ends
  /// with a vibration, and never contains two adjacent gaps. Pass it to
  /// [HapticEventPattern.toVibrationPattern] to drive `package:vibration`.
  ///
  /// Returns an empty list when there is nothing to encode.
  List<HapticEvent> convertTextToHapticEvents(String? input) {
    final words = _tokenize(input);
    if (words.isEmpty) return const [];
    return _buildEvents(words);
  }

  /// Converts text to a [HapticModel] carrying the text, its Morse code, and
  /// its haptic sequence.
  ///
  /// Returns a default-constructed [HapticModel] when there is nothing to
  /// encode. This tokenizes once rather than repeating the work for each of
  /// the two representations.
  HapticModel convertTextToModel(String? input) {
    final words = _tokenize(input);
    if (words.isEmpty) return const HapticModel();
    return HapticModel(
      text: input ?? '',
      morseCode: _buildMorseString(words),
      events: _buildEvents(words),
    );
  }

  /// Splits [input] into words, each word a list of Morse patterns.
  ///
  /// Whitespace runs separate words, and words that contain no mapped
  /// character are dropped entirely. That is what keeps the event sequence
  /// well formed: no leading, trailing, doubled, or orphaned gaps can survive
  /// into the output, because a gap is only ever emitted *between* two
  /// elements that both exist.
  List<List<String>> _tokenize(String? input) {
    if (input == null || input.isEmpty) return const [];

    final words = <List<String>>[];
    var current = <String>[];

    for (final grapheme in input.characters) {
      if (grapheme.trim().isEmpty) {
        if (current.isNotEmpty) {
          words.add(current);
          current = <String>[];
        }
        continue;
      }
      final pattern = _symbols[grapheme.toUpperCase()];
      if (pattern != null) current.add(pattern);
    }

    if (current.isNotEmpty) words.add(current);
    return words;
  }

  String _buildMorseString(List<List<String>> words) =>
      words.map((letters) => letters.join(' ')).join(' / ');

  List<HapticEvent> _buildEvents(List<List<String>> words) {
    final events = <HapticEvent>[];

    for (var w = 0; w < words.length; w++) {
      if (w > 0) events.add(HapticWordGap(_gapWordDuration));

      final letters = words[w];
      for (var l = 0; l < letters.length; l++) {
        if (l > 0) events.add(HapticLetterGap(_gapLetterDuration));

        final symbols = letters[l].characters.toList(growable: false);
        for (var s = 0; s < symbols.length; s++) {
          if (s > 0) events.add(HapticSymbolGap(_gapSymbolDuration));

          final symbol = symbols[s];
          // INVARIANT: HapticMorse.custom rejects any pattern containing a
          // character other than these two, and the built-in table only uses
          // '.' and '-'. Anything else here means the invariant was bypassed.
          assert(
            symbol == _dotSymbol || symbol == _dashSymbol,
            'pattern contains "$symbol"; expected "$_dotSymbol" or '
            '"$_dashSymbol"',
          );
          events.add(
            symbol == _dotSymbol
                ? HapticDot(_dotDuration)
                : HapticDash(_dashDuration),
          );
        }
      }
    }

    return List<HapticEvent>.unmodifiable(events);
  }

  /// Rewrites the built-in `.`/`-` patterns using custom symbols.
  ///
  /// Without this, choosing custom symbols would make whichever default map
  /// the caller did *not* override fail validation — asking for
  /// `symbolReference: '0'` would reject the standard digits it kept.
  static List<String> _respell(
    List<String> patterns,
    String dot,
    String dash,
  ) {
    if (dot == '.' && dash == '-') return patterns;
    return patterns
        .map(
          (pattern) => pattern.characters
              .map((symbol) => symbol == '.' ? dot : dash)
              .join(),
        )
        .toList(growable: false);
  }

  /// Validates one map/reference pair and returns its lookup entries.
  static Map<String, String> _buildSymbols({
    required List<String> patterns,
    required String reference,
    required String mapName,
    required String referenceName,
    required String dot,
    required String dash,
  }) {
    final keys = reference.characters.toList(growable: false);

    if (keys.length != patterns.length) {
      throw ArgumentError(
        '$mapName has ${patterns.length} entries but $referenceName has '
        '${keys.length} characters; they must match one to one.',
      );
    }

    final symbols = <String, String>{};
    for (var i = 0; i < keys.length; i++) {
      final key = keys[i].toUpperCase();
      if (symbols.containsKey(key)) {
        throw ArgumentError.value(
          keys[i],
          referenceName,
          'appears more than once (comparison is case-insensitive)',
        );
      }

      final pattern = patterns[i];
      if (pattern.isEmpty) {
        throw ArgumentError.value(
          pattern,
          '$mapName[$i]',
          'must not be empty',
        );
      }
      for (final symbol in pattern.characters) {
        if (symbol != dot && symbol != dash) {
          throw ArgumentError.value(
            pattern,
            '$mapName[$i]',
            'contains "$symbol", which is neither symbolReference ("$dot") '
                'nor dashReference ("$dash")',
          );
        }
      }

      symbols[key] = pattern;
    }

    return symbols;
  }

  static void _requireSingleGrapheme(String value, String name) {
    if (value.characters.length != 1) {
      throw ArgumentError.value(
        value,
        name,
        'must be exactly one character',
      );
    }
  }

  static void _requirePositive(int value, String name) {
    if (value <= 0) {
      throw ArgumentError.value(value, name, 'must be greater than zero');
    }
  }

  // Standard International Morse Code, used by the const default constructor.
  static const Map<String, String> _defaultSymbols = {
    'A': '.-',
    'B': '-...',
    'C': '-.-.',
    'D': '-..',
    'E': '.',
    'F': '..-.',
    'G': '--.',
    'H': '....',
    'I': '..',
    'J': '.---',
    'K': '-.-',
    'L': '.-..',
    'M': '--',
    'N': '-.',
    'O': '---',
    'P': '.--.',
    'Q': '--.-',
    'R': '.-.',
    'S': '...',
    'T': '-',
    'U': '..-',
    'V': '...-',
    'W': '.--',
    'X': '-..-',
    'Y': '-.--',
    'Z': '--..',
    '0': '-----',
    '1': '.----',
    '2': '..---',
    '3': '...--',
    '4': '....-',
    '5': '.....',
    '6': '-....',
    '7': '--...',
    '8': '---..',
    '9': '----.',
  };

  // Default character Morse code map (A-Z)
  static const List<String> _defaultCharMap = [
    '.-', '-...', '-.-.', '-..', '.', // A-E
    '..-.', '--.', '....', '..', '.---', // F-J
    '-.-', '.-..', '--', '-.', '---', // K-O
    '.--.', '--.-', '.-.', '...', '-', // P-T
    '..-', '...-', '.--', '-..-', '-.--', // U-Y
    '--..', // Z
  ];

  // Default numeric Morse code map (0-9)
  static const List<String> _defaultNumericMap = [
    '-----', '.----', '..---', '...--', '....-', '.....', // 0-5
    '-....', '--...', '---..', '----.', // 6-9
  ];

  // Default character reference for Latin alphabet
  static const String _defaultCharReference = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  // Default numeric reference
  static const String _defaultNumericReference = '0123456789';
}
