import 'package:meta/meta.dart';

/// Selects the visual-composition semantics of one map.
///
/// The version deliberately stays independent from `MapData.version`: the
/// latter versions the project schema, while this value versions the
/// perceptible paint contract shared by the editor and runtime.
@immutable
final class MapVisualStackConfig {
  MapVisualStackConfig({
    required this.semanticsVersion,
  }) {
    if (semanticsVersion <= 0) {
      throw ArgumentError.value(
        semanticsVersion,
        'semanticsVersion',
        'must be a positive integer',
      );
    }
  }

  static const int canonicalSemanticsVersion = 1;
  static const MapVisualStackConfig canonicalV1 = MapVisualStackConfig._(
    semanticsVersion: canonicalSemanticsVersion,
  );

  const MapVisualStackConfig._({
    required this.semanticsVersion,
  });

  final int semanticsVersion;

  bool get isSupported => semanticsVersion == canonicalSemanticsVersion;

  factory MapVisualStackConfig.fromJson(Map<String, dynamic> json) {
    final value = json['semanticsVersion'];
    if (value is! int) {
      throw const FormatException(
        r'$.visualStack.semanticsVersion: expected a positive integer',
      );
    }
    if (value <= 0) {
      throw const FormatException(
        r'$.visualStack.semanticsVersion: expected a positive integer',
      );
    }
    return MapVisualStackConfig(semanticsVersion: value);
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'semanticsVersion': semanticsVersion,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapVisualStackConfig &&
          semanticsVersion == other.semanticsVersion;

  @override
  int get hashCode => semanticsVersion.hashCode;

  @override
  String toString() =>
      'MapVisualStackConfig(semanticsVersion: $semanticsVersion)';
}
