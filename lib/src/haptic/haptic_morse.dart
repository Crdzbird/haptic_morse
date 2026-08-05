import 'package:characters/characters.dart';
import 'package:meta/meta.dart';

import '../model/haptic_event.dart';
import '../model/haptic_model.dart';

/// Converts text to Morse code and to haptic sequences, and back again.
///
/// Use the const default for standard International Morse Code — letters,
/// digits, and ITU punctuation:
///
/// ```dart
/// const morse = HapticMorse();
/// morse.convertTextToMorseString('SOS'); // "... --- ..."
/// ```
///
/// Use [HapticMorse.atSpeed] to work in words per minute, or
/// [HapticMorse.custom] for full control. Both validate their arguments and
/// throw [ArgumentError] on an inconsistent configuration.
///
/// Text is segmented into user-perceived characters (grapheme clusters), so
/// characters outside the Basic Multilingual Plane — including emoji with
/// variation selectors or zero-width joiners — work in a custom alphabet.
@immutable
final class HapticMorse {
  /// Creates an encoder for standard International Morse Code with standard
  /// timing ratios of 1/3/1/3/7 units, giving 12 words per minute.
  ///
  /// Covers A-Z, 0-9, and the punctuation of ITU-R M.1677-1. Accented letters
  /// are not included; pass [accentedLetters] to [HapticMorse.custom] for
  /// those.
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

  /// Creates an encoder at a given Morse speed in words per minute.
  ///
  /// Speed is defined by the standard word `PARIS`, which measures 50 units:
  /// one unit is `1200 / wordsPerMinute` milliseconds.
  ///
  /// ```dart
  /// final morse = HapticMorse.atSpeed(wordsPerMinute: 20);
  /// ```
  ///
  /// Pass [effectiveWordsPerMinute] for **Farnsworth timing**: symbols are
  /// sent at [wordsPerMinute] while the gaps between letters and words are
  /// stretched so the message overall reads at the slower speed. This is the
  /// standard way to make Morse learnable — and, for haptics, readable —
  /// without distorting the shape of each character.
  ///
  /// ```dart
  /// // Crisp 20 WPM characters delivered at an overall 8 WPM.
  /// final morse = HapticMorse.atSpeed(
  ///   wordsPerMinute: 20,
  ///   effectiveWordsPerMinute: 8,
  /// );
  /// ```
  ///
  /// Alphabet arguments behave exactly as in [HapticMorse.custom].
  ///
  /// Throws [ArgumentError] if either speed is not positive, if
  /// [effectiveWordsPerMinute] exceeds [wordsPerMinute], or if the resulting
  /// durations round down to zero.
  factory HapticMorse.atSpeed({
    required int wordsPerMinute,
    int? effectiveWordsPerMinute,
    List<String>? charMap,
    String? charReference,
    List<String>? numericMap,
    String? numericReference,
    Map<String, String>? additionalSymbols,
    String? symbolReference,
    String? dashReference,
  }) {
    if (wordsPerMinute <= 0) {
      throw ArgumentError.value(
        wordsPerMinute,
        'wordsPerMinute',
        'must be greater than zero',
      );
    }

    final overall = effectiveWordsPerMinute ?? wordsPerMinute;
    if (overall <= 0) {
      throw ArgumentError.value(
        overall,
        'effectiveWordsPerMinute',
        'must be greater than zero',
      );
    }
    if (overall > wordsPerMinute) {
      throw ArgumentError.value(
        overall,
        'effectiveWordsPerMinute',
        'must not exceed wordsPerMinute ($wordsPerMinute); Farnsworth timing '
            'slows a message down, it cannot speed it up',
      );
    }

    // One unit at the character speed.
    final unit = 1200 / wordsPerMinute;

    // Standard Farnsworth distribution. PARIS is 50 units: 31 of symbols and
    // 19 of spacing (four 3-unit letter gaps plus one 7-unit word gap). `ta`
    // is the total spacing time per word needed to hit the overall speed;
    // it is then split 3:7 across the two gap kinds.
    //
    // Reduces exactly to the standard 3/7 ratios when overall == character
    // speed, which `morse_conformance_test.dart` verifies at several speeds.
    final ta =
        (60 * wordsPerMinute - 37.2 * overall) / (overall * wordsPerMinute);
    final letterGap = (3 * ta * 1000 / 19).round();
    final wordGap = (7 * ta * 1000 / 19).round();

    return HapticMorse.custom(
      dotDuration: unit.round(),
      dashDuration: (3 * unit).round(),
      gapSymbolDuration: unit.round(),
      gapLetterDuration: letterGap,
      gapWordDuration: wordGap,
      charMap: charMap,
      charReference: charReference,
      numericMap: numericMap,
      numericReference: numericReference,
      additionalSymbols: additionalSymbols,
      symbolReference: symbolReference,
      dashReference: dashReference,
    );
  }

  /// Creates an encoder with custom mappings and/or timings.
  ///
  /// Any omitted argument falls back to its standard value, so
  /// `HapticMorse.custom(dotDuration: 80)` keeps the standard alphabet.
  ///
  /// - [charMap] / [charReference]: Morse patterns and the characters they
  ///   encode, in matching order. Supply both or neither.
  /// - [numericMap] / [numericReference]: the same for digits. Entries here
  ///   take precedence over [charReference] on overlap. Supply both or
  ///   neither.
  /// - [additionalSymbols]: extra character-to-pattern entries merged on top
  ///   of everything else. Pass [accentedLetters] to add É, Ñ, Ü and friends.
  /// - [symbolReference] / [dashReference]: the single characters used to
  ///   spell the patterns in the maps. Default `.` and `-`.
  /// - Durations are in milliseconds and must be positive.
  ///
  /// Throws [ArgumentError] if a map is supplied without its reference, a map
  /// and its reference differ in length, a reference repeats a character, a
  /// pattern is empty or contains anything other than [symbolReference] and
  /// [dashReference], or a duration is not positive.
  factory HapticMorse.custom({
    List<String>? charMap,
    String? charReference,
    List<String>? numericMap,
    String? numericReference,
    Map<String, String>? additionalSymbols,
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
        _resolveTable(
          patterns: charMap,
          reference: charReference,
          fallback: _defaultCharacters,
          mapName: 'charMap',
          referenceName: 'charReference',
          dot: dot,
          dash: dash,
        ),
      )
      ..addAll(
        _resolveTable(
          patterns: numericMap,
          reference: numericReference,
          fallback: _defaultDigits,
          mapName: 'numericMap',
          referenceName: 'numericReference',
          dot: dot,
          dash: dash,
        ),
      );

    if (additionalSymbols != null) {
      symbols.addAll(
        _validateTable(
          table: additionalSymbols,
          mapName: 'additionalSymbols',
          dot: dot,
          dash: dash,
        ),
      );
    }

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

  /// The characters this encoder can represent, upper-cased.
  Iterable<String> get supportedCharacters => _symbols.keys;

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
    if (words.isEmpty) return HapticModel.empty;
    return HapticModel(
      text: input ?? '',
      morseCode: _buildMorseString(words),
      events: _buildEvents(words),
    );
  }

  /// Decodes a Morse string produced by [convertTextToMorseString].
  ///
  /// Expects symbols separated by spaces and words separated by `" / "`.
  /// Decoded text is upper-case, because Morse does not carry case.
  ///
  /// Patterns with no entry in this encoder's table are skipped, mirroring how
  /// encoding skips unmapped characters. Returns `null` when nothing could be
  /// decoded.
  ///
  /// ```dart
  /// const morse = HapticMorse();
  /// morse.decodeMorseString('... --- ...'); // "SOS"
  /// ```
  String? decodeMorseString(String? morseCode) {
    if (morseCode == null || morseCode.trim().isEmpty) return null;

    final inverse = _inverseSymbols();
    final words = <String>[];

    for (final word in morseCode.split('/')) {
      final letters = word
          .split(' ')
          .where((pattern) => pattern.isNotEmpty)
          .map((pattern) => inverse[pattern])
          .whereType<String>()
          .join();
      if (letters.isNotEmpty) words.add(letters);
    }

    if (words.isEmpty) return null;
    return words.join(' ');
  }

  /// Decodes a haptic sequence back to text.
  ///
  /// Unlike [decodeMorseString] this needs no threshold guessing: the events
  /// are already typed, so the symbol and word boundaries are exact.
  ///
  /// Returns `null` when nothing could be decoded.
  String? decodeEvents(List<HapticEvent> events) {
    if (events.isEmpty) return null;

    final inverse = _inverseSymbols();
    final words = <String>[];
    final letters = StringBuffer();
    final pattern = StringBuffer();

    void endLetter() {
      if (pattern.isEmpty) return;
      final decoded = inverse[pattern.toString()];
      if (decoded != null) letters.write(decoded);
      pattern.clear();
    }

    void endWord() {
      endLetter();
      if (letters.isNotEmpty) words.add(letters.toString());
      letters.clear();
    }

    for (final event in events) {
      switch (event) {
        case HapticDot():
          pattern.write(_dotSymbol);
        case HapticDash():
          pattern.write(_dashSymbol);
        case HapticSymbolGap():
          break;
        case HapticLetterGap():
          endLetter();
        case HapticWordGap():
          endWord();
      }
    }
    endWord();

    if (words.isEmpty) return null;
    return words.join(' ');
  }

  /// Pattern to character, derived from [_symbols].
  ///
  /// Built per call rather than cached, so the class stays const-constructible.
  /// Decoding is not a hot path; the map has a few dozen entries.
  ///
  /// Where two characters share a pattern — `À` and `Å` in [accentedLetters],
  /// for instance — the first wins and decoding is therefore lossy for that
  /// pair. Encoding is unaffected.
  Map<String, String> _inverseSymbols() {
    final inverse = <String, String>{};
    for (final entry in _symbols.entries) {
      inverse.putIfAbsent(entry.value, () => entry.key);
    }
    return inverse;
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
          //
          // The message is deliberately a constant with no interpolation. An
          // interpolated message is itself executable code that only runs when
          // the assert fails, so it can never be covered — keeping it constant
          // is what lets this file reach 100% without excluding anything or
          // dropping the check.
          assert(
            symbol == _dotSymbol || symbol == _dashSymbol,
            'pattern contains a symbol that is neither the dot nor the dash '
            'reference',
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

  /// Resolves one map/reference pair, falling back to a built-in table.
  ///
  /// Supplying one of the pair without the other is rejected: pairing a custom
  /// map against the default reference would either throw a confusing length
  /// error or silently encode the wrong characters.
  static Map<String, String> _resolveTable({
    required List<String>? patterns,
    required String? reference,
    required Map<String, String> fallback,
    required String mapName,
    required String referenceName,
    required String dot,
    required String dash,
  }) {
    if (patterns == null && reference == null) {
      return _respellTable(fallback, dot, dash);
    }
    if (patterns == null || reference == null) {
      throw ArgumentError(
        '$mapName and $referenceName must be supplied together; '
        'got ${patterns == null ? referenceName : mapName} alone.',
      );
    }
    return _buildSymbols(
      patterns: patterns,
      reference: reference,
      mapName: mapName,
      referenceName: referenceName,
      dot: dot,
      dash: dash,
    );
  }

  /// Rewrites built-in `.`/`-` patterns using custom symbols.
  ///
  /// Without this, choosing custom symbols would make whichever default table
  /// the caller did *not* override fail validation — asking for
  /// `symbolReference: '0'` would reject the standard digits it kept.
  static Map<String, String> _respellTable(
    Map<String, String> table,
    String dot,
    String dash,
  ) {
    if (dot == '.' && dash == '-') return table;
    return table.map(
      (character, pattern) => MapEntry(
        character,
        pattern.characters.map((s) => s == '.' ? dot : dash).join(),
      ),
    );
  }

  /// Validates an explicit character-to-pattern table.
  static Map<String, String> _validateTable({
    required Map<String, String> table,
    required String mapName,
    required String dot,
    required String dash,
  }) {
    final validated = <String, String>{};
    table.forEach((character, pattern) {
      _requireSingleGrapheme(character, '$mapName key');
      _requirePattern(pattern, '$mapName["$character"]', dot, dash);
      validated[character.toUpperCase()] = pattern;
    });
    return validated;
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

      _requirePattern(patterns[i], '$mapName[$i]', dot, dash);
      symbols[key] = patterns[i];
    }

    return symbols;
  }

  static void _requirePattern(
    String pattern,
    String name,
    String dot,
    String dash,
  ) {
    if (pattern.isEmpty) {
      throw ArgumentError.value(pattern, name, 'must not be empty');
    }
    for (final symbol in pattern.characters) {
      if (symbol != dot && symbol != dash) {
        throw ArgumentError.value(
          pattern,
          name,
          'contains "$symbol", which is neither symbolReference ("$dot") '
          'nor dashReference ("$dash")',
        );
      }
    }
  }

  static void _requireSingleGrapheme(String value, String name) {
    if (value.characters.length != 1) {
      throw ArgumentError.value(value, name, 'must be exactly one character');
    }
  }

  static void _requirePositive(int value, String name) {
    if (value <= 0) {
      throw ArgumentError.value(value, name, 'must be greater than zero');
    }
  }

  /// Accented and non-English letters, for [HapticMorse.custom]'s
  /// `additionalSymbols`.
  ///
  /// ```dart
  /// final morse = HapticMorse.custom(
  ///   additionalSymbols: HapticMorse.accentedLetters,
  /// );
  /// morse.convertTextToMorseString('MAÑANA');
  /// ```
  ///
  /// These are long-standing regional conventions rather than part of
  /// ITU-R M.1677-1, which is why they are opt-in. `À` and `Å` share a
  /// pattern, so decoding that pattern yields `À`.
  // VERIFY: the regional conventions below are widely published but are not
  // ITU-normative; confirm against the convention your users expect before
  // relying on them. `morse_conformance_test.dart` asserts they collide with
  // nothing in the default table.
  static const Map<String, String> accentedLetters = {
    'À': '.--.-',
    'Å': '.--.-',
    'Ä': '.-.-',
    'Ç': '-.-..',
    'È': '.-..-',
    'É': '..-..',
    'Ñ': '--.--',
    'Ö': '---.',
    'Ü': '..--',
  };

  // Latin letters, ITU-R M.1677-1.
  static const Map<String, String> _letters = {
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
  };

  // Punctuation. The first block is ITU-R M.1677-1; the second is
  // long-standing convention outside it.
  static const Map<String, String> _punctuation = {
    '.': '.-.-.-', // full stop
    ',': '--..--', // comma
    ':': '---...', // colon
    '?': '..--..', // question mark
    "'": '.----.', // apostrophe
    '-': '-....-', // hyphen
    '/': '-..-.', // fraction bar
    '(': '-.--.', // left parenthesis
    ')': '-.--.-', // right parenthesis
    '"': '.-..-.', // inverted commas
    '=': '-...-', // double hyphen (prosign BT)
    '+': '.-.-.', // cross (prosign AR)
    '@': '.--.-.', // commercial at (prosign AC)
    '&': '.-...', // ampersand (prosign AS) — conventional
    '!': '-.-.--', // exclamation mark — conventional
    ';': '-.-.-.', // semicolon — conventional
    '_': '..--.-', // underscore — conventional
    r'$': '...-..-', // dollar — conventional
  };

  // Digits, ITU-R M.1677-1.
  static const Map<String, String> _digits = {
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

  // Everything the default constructor understands. Single source of truth:
  // HapticMorse.custom falls back to the same tables.
  static const Map<String, String> _defaultCharacters = {
    ..._letters,
    ..._punctuation,
  };

  static const Map<String, String> _defaultDigits = _digits;

  static const Map<String, String> _defaultSymbols = {
    ..._defaultCharacters,
    ..._defaultDigits,
  };
}
