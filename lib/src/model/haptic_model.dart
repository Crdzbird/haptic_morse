import 'dart:collection';
import 'dart:convert';

/// Haptic Model for storing text, Morse code, and haptic durations.
final class HapticModel {
  /// The original text input.
  final String text;

  /// The Morse code representation of the text.
  final String morseCode;

  /// Backing store for [hapticDurations].
  ///
  /// Kept private so the list cannot be mutated through the public getter.
  final List<int> _hapticDurations;

  /// Creates a new [HapticModel].
  const HapticModel({
    this.text = '',
    this.morseCode = '',
    List<int> hapticDurations = const [],
  }) : _hapticDurations = hapticDurations;

  /// The durations for each haptic feedback event.
  ///
  /// This is an unmodifiable view: adding to or removing from the returned
  /// list throws [UnsupportedError]. Pass a new list to [copyWith] to change
  /// the durations.
  List<int> get hapticDurations => UnmodifiableListView(_hapticDurations);

  /// Creates a [HapticModel] from a [Map<String, dynamic>].
  ///
  /// Entries in `hapticDurations` are accepted as any [num] and truncated to
  /// [int], so JSON payloads that encode durations as doubles
  /// (`[100.0, 300.0]`) round-trip instead of throwing.
  factory HapticModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const HapticModel();
    return HapticModel(
      text: map['text'] as String? ?? '',
      morseCode: map['morseCode'] as String? ?? '',
      hapticDurations: (map['hapticDurations'] as List<dynamic>? ?? const [])
          .map((e) => (e as num).toInt())
          .toList(growable: false),
    );
  }

  /// Creates a [HapticModel] from JSON string or map.
  factory HapticModel.fromJson(dynamic data) {
    if (data == null || '$data'.isEmpty) return const HapticModel();
    if (data is String) {
      return HapticModel.fromMap(json.decode(data) as Map<String, dynamic>);
    }
    if (data is Map<String, dynamic>) return HapticModel.fromMap(data);
    throw ArgumentError('Invalid data type for HapticModel: $data');
  }

  /// Converts this object into a JSON-encodable map.
  Map<String, dynamic> toJson() => {
        'text': text,
        'morseCode': morseCode,
        'hapticDurations': List<int>.of(_hapticDurations),
      };

  /// Converts this object into a JSON string.
  String encode() => json.encode(toJson());

  /// Creates a copy of this [HapticModel] with optional overrides.
  HapticModel copyWith({
    String? text,
    String? morseCode,
    List<int>? hapticDurations,
  }) {
    return HapticModel(
      text: text ?? this.text,
      morseCode: morseCode ?? this.morseCode,
      hapticDurations: hapticDurations ?? _hapticDurations,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HapticModel &&
          other.text == text &&
          other.morseCode == morseCode &&
          _durationsEqual(other._hapticDurations, _hapticDurations);

  @override
  int get hashCode =>
      Object.hash(text, morseCode, Object.hashAll(_hapticDurations));

  @override
  String toString() => 'HapticModel(text: $text, morseCode: $morseCode, '
      'hapticDurations: $_hapticDurations)';

  /// Element-wise list comparison.
  ///
  /// Implemented locally rather than depending on `package:collection` or
  /// `flutter/foundation.dart`, so this file stays dependency-free.
  static bool _durationsEqual(List<int> a, List<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
