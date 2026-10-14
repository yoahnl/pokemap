import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;
import 'package:meta/meta.dart' show immutable;

const currentMapInstanceRetentionPolicySchemaVersion = 1;
const _collectionEquality = DeepCollectionEquality();
const _maximumInteger = 2147483647;

@immutable
final class MapInstanceRetentionPolicy {
  MapInstanceRetentionPolicy({
    required int viewportWidthTiles,
    required int viewportHeightTiles,
    required int marginTiles,
    Iterable<String> clampViewportToMapIds = const [],
  }) : viewportWidthTiles = _integer(
         viewportWidthTiles,
         'viewportWidthTiles',
         1,
       ),
       viewportHeightTiles = _integer(
         viewportHeightTiles,
         'viewportHeightTiles',
         1,
       ),
       marginTiles = _integer(marginTiles, 'marginTiles', 0),
       clampViewportToMapIds = Set.unmodifiable(
         clampViewportToMapIds.map(_identity),
       );

  final int viewportWidthTiles;
  final int viewportHeightTiles;
  final int marginTiles;
  final Set<String> clampViewportToMapIds;

  factory MapInstanceRetentionPolicy.fromJson(Map<String, dynamic> json) {
    const keys = {
      'schemaVersion',
      'viewportWidthTiles',
      'viewportHeightTiles',
      'marginTiles',
      'clampViewportToMapIds',
    };
    if (json.length != keys.length || !json.keys.every(keys.contains)) {
      throw const FormatException(
        'Invalid map instance retention policy keys.',
      );
    }
    if (json['schemaVersion'] is! int ||
        json['schemaVersion'] !=
            currentMapInstanceRetentionPolicySchemaVersion) {
      throw const FormatException('Unsupported map instance retention policy.');
    }
    final mapIds = json['clampViewportToMapIds'];
    if (mapIds is! List || mapIds.any((value) => value is! String)) {
      throw const FormatException(
        'clampViewportToMapIds must be a string list.',
      );
    }
    if (mapIds.toSet().length != mapIds.length) {
      throw const FormatException('clampViewportToMapIds contains duplicates.');
    }
    try {
      return MapInstanceRetentionPolicy(
        viewportWidthTiles: _jsonInteger(json['viewportWidthTiles']),
        viewportHeightTiles: _jsonInteger(json['viewportHeightTiles']),
        marginTiles: _jsonInteger(json['marginTiles']),
        clampViewportToMapIds: mapIds.cast<String>(),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message?.toString() ?? 'Invalid policy.');
    }
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': currentMapInstanceRetentionPolicySchemaVersion,
    'viewportWidthTiles': viewportWidthTiles,
    'viewportHeightTiles': viewportHeightTiles,
    'marginTiles': marginTiles,
    'clampViewportToMapIds': clampViewportToMapIds.toList()..sort(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapInstanceRetentionPolicy &&
          other.viewportWidthTiles == viewportWidthTiles &&
          other.viewportHeightTiles == viewportHeightTiles &&
          other.marginTiles == marginTiles &&
          _collectionEquality.equals(
            other.clampViewportToMapIds,
            clampViewportToMapIds,
          );

  @override
  int get hashCode => Object.hash(
    viewportWidthTiles,
    viewportHeightTiles,
    marginTiles,
    _collectionEquality.hash(clampViewportToMapIds),
  );
}

int _integer(int value, String field, int minimum) {
  if (value < minimum || value > _maximumInteger) {
    throw ArgumentError.value(
      value,
      field,
      'must be in $minimum..$_maximumInteger',
    );
  }
  return value;
}

int _jsonInteger(Object? value) {
  if (value is! int) {
    throw const FormatException('Policy sizes must be integers.');
  }
  return value;
}

String _identity(String value) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, 'mapId', 'must be a canonical identity');
  }
  return value;
}
