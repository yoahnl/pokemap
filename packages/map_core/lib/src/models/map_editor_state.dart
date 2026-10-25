import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;

final class MapEditorState {
  MapEditorState({
    Set<String> lockedElements = const {},
    Set<String> lockedFamilies = const {},
  }) : lockedElements = Set.unmodifiable(lockedElements),
       lockedFamilies = Set.unmodifiable(lockedFamilies) {
    if (lockedElements.length > 4096 || lockedFamilies.length > 128) {
      throw const FormatException(
        'Map editor lock collection exceeds its limit.',
      );
    }
    for (final key in lockedElements) {
      final separator = key.indexOf(':');
      if (separator < 1 ||
          separator == key.length - 1 ||
          !elementKinds.contains(key.substring(0, separator))) {
        throw const FormatException('Invalid map editor element key.');
      }
      _name(key, 384);
    }
    for (final family in lockedFamilies) {
      if (!elementKinds.contains(family)) {
        throw const FormatException('Unknown map editor lock family.');
      }
      _name(family, 128);
    }
  }

  static const elementKinds = {
    'layer',
    'decor',
    'model',
    'entity',
    'warp',
    'zone',
    'trigger',
    'effect',
  };
  final Set<String> lockedElements;
  final Set<String> lockedFamilies;

  bool isLocked(String kind, String id) =>
      lockedElements.contains('$kind:$id') ||
      lockedFamilies.contains(kind);

  MapEditorState copyWith({
    Set<String>? lockedElements,
    Set<String>? lockedFamilies,
  }) => MapEditorState(
    lockedElements: lockedElements ?? this.lockedElements,
    lockedFamilies: lockedFamilies ?? this.lockedFamilies,
  );

  factory MapEditorState.fromJson(Map<String, dynamic> json) {
    if (json.keys.any(
      (key) => !const {'lockedElements', 'lockedFamilies'}.contains(key),
    )) {
      throw const FormatException('Unknown map editor state property.');
    }
    return MapEditorState(
      lockedElements: _strings(json['lockedElements'], 4096),
      lockedFamilies: _strings(json['lockedFamilies'], 128),
    );
  }

  Map<String, dynamic> toJson() => {
    'lockedElements': lockedElements.toList()..sort(),
    'lockedFamilies': lockedFamilies.toList()..sort(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapEditorState &&
          const DeepCollectionEquality().equals(
            lockedElements,
            other.lockedElements,
          ) &&
          const DeepCollectionEquality().equals(
            lockedFamilies,
            other.lockedFamilies,
          );

  @override
  int get hashCode => Object.hash(
    const DeepCollectionEquality().hash(lockedElements),
    const DeepCollectionEquality().hash(lockedFamilies),
  );
}

final class MapEditorDocument {
  MapEditorDocument({required String mapId, required this.state})
    : mapId = _mapId(mapId);

  static const schemaVersion = 1;
  static const maxBytes = 65536;
  final String mapId;
  final MapEditorState state;

  static String relativePathForMap(String mapId) =>
      'maps/${_mapId(mapId)}.editor.json';

  factory MapEditorDocument.fromJson(Map<String, dynamic> json) {
    if (json.keys.any(
          (key) => !const {'schemaVersion', 'mapId', 'state'}.contains(key),
        ) ||
        json['schemaVersion'] != schemaVersion ||
        json['mapId'] is! String ||
        json['state'] is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid or unsupported map editor document.',
      );
    }
    return MapEditorDocument(
      mapId: json['mapId'] as String,
      state: MapEditorState.fromJson(json['state'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'mapId': mapId,
    'state': state.toJson(),
  };
}

Set<String> _strings(Object? value, int maximum) {
  if (value == null) return {};
  if (value is! List ||
      value.length > maximum ||
      value.any((entry) => entry is! String)) {
    throw const FormatException('Invalid map editor lock collection.');
  }
  final result = value.cast<String>().toSet();
  if (result.length != value.length) {
    throw const FormatException('Duplicate map editor lock.');
  }
  return result;
}

void _name(String value, int maximum) {
  if (value.trim().isEmpty ||
      value.length > maximum ||
      value.contains('\u0000')) {
    throw const FormatException('Invalid map editor lock identity.');
  }
}

String _mapId(String value) {
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$').hasMatch(value) ||
      value.contains('..')) {
    throw const FormatException('Invalid map editor map identity.');
  }
  return value;
}
