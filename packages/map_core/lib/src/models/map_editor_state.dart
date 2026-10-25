import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;

final class MapEditorState {
  MapEditorState({
    Set<String> lockedElements = const {},
    Set<String> lockedFamilies = const {},
    Set<String> hiddenElements = const {},
    Set<String> hiddenFamilies = const {},
  }) : lockedElements = Set.unmodifiable(lockedElements),
       lockedFamilies = Set.unmodifiable(lockedFamilies),
       hiddenElements = Set.unmodifiable(hiddenElements),
       hiddenFamilies = Set.unmodifiable(hiddenFamilies) {
    if (lockedElements.length > 4096 ||
        lockedFamilies.length > 128 ||
        hiddenElements.length > 4096 ||
        hiddenFamilies.length > 128) {
      throw const FormatException('Map editor collection exceeds its limit.');
    }
    for (final elements in [lockedElements, hiddenElements]) {
      for (final key in elements) {
        final separator = key.indexOf(':');
        if (separator < 1 ||
            separator == key.length - 1 ||
            !elementKinds.contains(key.substring(0, separator))) {
          throw const FormatException('Invalid map editor element key.');
        }
        _name(key, 384);
      }
    }
    for (final families in [lockedFamilies, hiddenFamilies]) {
      for (final family in families) {
        if (!elementKinds.contains(family)) {
          throw const FormatException('Unknown map editor family.');
        }
        _name(family, 128);
      }
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
  final Set<String> hiddenElements;
  final Set<String> hiddenFamilies;

  bool isLocked(String kind, String id) =>
      lockedElements.contains('$kind:$id') || lockedFamilies.contains(kind);

  bool isHidden(String kind, String id) =>
      hiddenElements.contains('$kind:$id') || hiddenFamilies.contains(kind);

  MapEditorState copyWith({
    Set<String>? lockedElements,
    Set<String>? lockedFamilies,
    Set<String>? hiddenElements,
    Set<String>? hiddenFamilies,
  }) => MapEditorState(
    lockedElements: lockedElements ?? this.lockedElements,
    lockedFamilies: lockedFamilies ?? this.lockedFamilies,
    hiddenElements: hiddenElements ?? this.hiddenElements,
    hiddenFamilies: hiddenFamilies ?? this.hiddenFamilies,
  );

  factory MapEditorState.fromJson(Map<String, dynamic> json) {
    if (json.keys.any((key) => !_stateFields.contains(key))) {
      throw const FormatException('Unknown map editor state property.');
    }
    return MapEditorState(
      lockedElements: _strings(json['lockedElements'], 4096),
      lockedFamilies: _strings(json['lockedFamilies'], 128),
      hiddenElements: _strings(json['hiddenElements'], 4096),
      hiddenFamilies: _strings(json['hiddenFamilies'], 128),
    );
  }

  Map<String, dynamic> toJson() => {
    'lockedElements': lockedElements.toList()..sort(),
    'lockedFamilies': lockedFamilies.toList()..sort(),
    'hiddenElements': hiddenElements.toList()..sort(),
    'hiddenFamilies': hiddenFamilies.toList()..sort(),
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
          ) &&
          const DeepCollectionEquality().equals(
            hiddenElements,
            other.hiddenElements,
          ) &&
          const DeepCollectionEquality().equals(
            hiddenFamilies,
            other.hiddenFamilies,
          );

  @override
  int get hashCode => Object.hash(
    const DeepCollectionEquality().hash(lockedElements),
    const DeepCollectionEquality().hash(lockedFamilies),
    const DeepCollectionEquality().hash(hiddenElements),
    const DeepCollectionEquality().hash(hiddenFamilies),
  );
}

final class MapEditorDocument {
  MapEditorDocument({required String mapId, required this.state})
    : mapId = _mapId(mapId);

  static const schemaVersion = 2;
  static const maxBytes = 65536;
  final String mapId;
  final MapEditorState state;

  static String relativePathForMap(String mapId) =>
      'maps/${_mapId(mapId)}.editor.json';

  factory MapEditorDocument.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    if (json.keys.any(
          (key) => !const {'schemaVersion', 'mapId', 'state'}.contains(key),
        ) ||
        (version != 1 && (version is! int || version != schemaVersion)) ||
        json['mapId'] is! String ||
        json['state'] is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid or unsupported map editor document.',
      );
    }
    final state = json['state'] as Map<String, dynamic>;
    if (version == 1) {
      if (state.keys.any(
        (key) => !const {'lockedElements', 'lockedFamilies'}.contains(key),
      )) {
        throw const FormatException('Invalid version one map editor state.');
      }
    } else if (state.length != _stateFields.length ||
        _stateFields.any((field) => state[field] is! List)) {
      throw const FormatException('Invalid version two map editor state.');
    }
    return MapEditorDocument(
      mapId: json['mapId'] as String,
      state: MapEditorState.fromJson(state),
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'mapId': mapId,
    'state': state.toJson(),
  };
}

const _stateFields = {
  'lockedElements',
  'lockedFamilies',
  'hiddenElements',
  'hiddenFamilies',
};

Set<String> _strings(Object? value, int maximum) {
  if (value == null) return {};
  if (value is! List ||
      value.length > maximum ||
      value.any((entry) => entry is! String)) {
    throw const FormatException('Invalid map editor collection.');
  }
  final result = value.cast<String>().toSet();
  if (result.length != value.length) {
    throw const FormatException('Duplicate map editor state key.');
  }
  return result;
}

void _name(String value, int maximum) {
  if (value.trim().isEmpty ||
      value.length > maximum ||
      value.contains('\u0000')) {
    throw const FormatException('Invalid map editor state identity.');
  }
}

String _mapId(String value) {
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$').hasMatch(value) ||
      value.contains('..')) {
    throw const FormatException('Invalid map editor map identity.');
  }
  return value;
}
