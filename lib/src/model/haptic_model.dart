import 'dart:convert';

/// Haptic Model for storing text, Morse code, and haptic durations.
final class HapticModel {
  /// The original text input.
  final String text;

  /// The Morse code representation of the text.
  final String morseCode;

  /// The durations for each haptic feedback event.
  final List<int> hapticDurations;

  /// Creates a new [HapticModel].
  const HapticModel({
    this.text = '',
    this.morseCode = '',
    this.hapticDurations = const [],
  });

  /// Creates a [HapticModel] from a [Map<String, dynamic>].
  factory HapticModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return HapticModel();
    return HapticModel(
      text: map['text'] as String? ?? '',
      morseCode: map['morseCode'] as String? ?? '',
      hapticDurations: List<int>.from(
        (map['hapticDurations'] as List<dynamic>? ?? []).map((e) => e as int),
      ),
    );
  }

  /// Creates a [HapticModel] from JSON string or map.
  factory HapticModel.fromJson(dynamic data) {
    if (data == null || '$data'.isEmpty) return HapticModel();
    if (data is String) {
      return HapticModel.fromMap(json.decode(data) as Map<String, dynamic>);
    }
    if (data is Map<String, dynamic>) return HapticModel.fromMap(data);
    throw ArgumentError('Invalid data type for HapticModel: $data');
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'morseCode': morseCode,
        'hapticDurations': hapticDurations,
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
      hapticDurations: hapticDurations ?? this.hapticDurations,
    );
  }
}
