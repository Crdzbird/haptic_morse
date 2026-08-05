import 'dart:collection';
import 'dart:convert';

import 'haptic_event.dart';

/// The result of converting text to Morse code: the original text, its dot
/// and dash representation, and the haptic sequence that plays it.
final class HapticModel {
  /// The original text input.
  final String text;

  /// The Morse code representation of the text.
  final String morseCode;

  /// Backing store for [events].
  ///
  /// Kept private so the list cannot be mutated through the public getter.
  final List<HapticEvent> _events;

  /// Creates a new [HapticModel].
  const HapticModel({
    this.text = '',
    this.morseCode = '',
    List<HapticEvent> events = const [],
  }) : _events = events;

  /// The haptic sequence for [text].
  ///
  /// This is an unmodifiable view: adding to or removing from the returned
  /// list throws [UnsupportedError]. Pass a new list to [copyWith] instead.
  List<HapticEvent> get events => UnmodifiableListView(_events);

  /// The sequence as a pattern for `Vibration.vibrate`.
  ///
  /// See [HapticEventPattern.toVibrationPattern] for the exact convention.
  List<int> toVibrationPattern() => _events.toVibrationPattern();

  /// How long the full sequence takes to play, in milliseconds.
  int get totalDuration => _events.totalDuration;

  /// Creates a [HapticModel] from a [Map<String, dynamic>].
  ///
  /// Expects `events` to be a list of maps in the shape produced by
  /// [HapticEvent.toJson]. Throws [ArgumentError] on an unrecognized event.
  factory HapticModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const HapticModel();
    return HapticModel(
      text: map['text'] as String? ?? '',
      morseCode: map['morseCode'] as String? ?? '',
      events: (map['events'] as List<dynamic>? ?? const [])
          .map((e) => HapticEvent.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  /// Creates a [HapticModel] from a JSON string or an already-decoded map.
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
        'events': _events.map((e) => e.toJson()).toList(growable: false),
      };

  /// Converts this object into a JSON string.
  String encode() => json.encode(toJson());

  /// Creates a copy of this [HapticModel] with optional overrides.
  HapticModel copyWith({
    String? text,
    String? morseCode,
    List<HapticEvent>? events,
  }) {
    return HapticModel(
      text: text ?? this.text,
      morseCode: morseCode ?? this.morseCode,
      events: events ?? _events,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HapticModel &&
          other.text == text &&
          other.morseCode == morseCode &&
          _eventsEqual(other._events, _events);

  @override
  int get hashCode => Object.hash(text, morseCode, Object.hashAll(_events));

  @override
  String toString() => 'HapticModel(text: $text, morseCode: $morseCode, '
      'events: ${_events.length}, totalDuration: ${totalDuration}ms)';

  /// Element-wise list comparison.
  ///
  /// Implemented locally rather than depending on `package:collection`, so the
  /// core of this package stays free of non-essential dependencies.
  static bool _eventsEqual(List<HapticEvent> a, List<HapticEvent> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
