import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;

import '../collision/pixel_rect.dart';
import 'geometry.dart';

enum MovingPropState { closed, open }

final class MovingPropDefinition {
  MovingPropDefinition({
    required String id,
    required String placedElementId,
    required this.closedPositionPx,
    required this.openPositionPx,
    required this.collisionRect,
    this.initialState = MovingPropState.closed,
  }) : id = _identity(id),
       placedElementId = _identity(placedElementId) {
    final dx = (openPositionPx.x - closedPositionPx.x).abs();
    final dy = (openPositionPx.y - closedPositionPx.y).abs();
    if (!_validPosition(closedPositionPx) ||
        !_validPosition(openPositionPx) ||
        (dx == 0) == (dy == 0) ||
        dx + dy > 1024 ||
        collisionRect.leftPx < 0 ||
        collisionRect.topPx < 0 ||
        collisionRect.widthPx <= 0 ||
        collisionRect.heightPx <= 0 ||
        collisionRect.leftPx > 1024 ||
        collisionRect.topPx > 1024 ||
        collisionRect.widthPx > 1024 ||
        collisionRect.heightPx > 1024 ||
        collisionRect.leftPx + collisionRect.widthPx > 1024 ||
        collisionRect.topPx + collisionRect.heightPx > 1024) {
      throw const FormatException('Invalid moving prop geometry.');
    }
  }

  final String id;
  final String placedElementId;
  final PixelOffset closedPositionPx;
  final PixelOffset openPositionPx;
  final PixelRect collisionRect;
  final MovingPropState initialState;

  factory MovingPropDefinition.fromJson(Map<String, dynamic> json) {
    _keys(json, {
      'id',
      'placedElementId',
      'closedPositionPx',
      'openPositionPx',
      'collisionRect',
      if (json.containsKey('initialState')) 'initialState',
    });
    final rect = _object(json['collisionRect']);
    _keys(rect, {'leftPx', 'topPx', 'widthPx', 'heightPx'});
    return MovingPropDefinition(
      id: _identity(json['id']),
      placedElementId: _identity(json['placedElementId']),
      closedPositionPx: _position(json['closedPositionPx']),
      openPositionPx: _position(json['openPositionPx']),
      collisionRect: PixelRect(
        leftPx: _integer(rect['leftPx']),
        topPx: _integer(rect['topPx']),
        widthPx: _integer(rect['widthPx']),
        heightPx: _integer(rect['heightPx']),
      ),
      initialState: json.containsKey('initialState')
          ? _state(json['initialState'])
          : MovingPropState.closed,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'placedElementId': placedElementId,
    'closedPositionPx': closedPositionPx.toJson(),
    'openPositionPx': openPositionPx.toJson(),
    'collisionRect': {
      'leftPx': collisionRect.leftPx,
      'topPx': collisionRect.topPx,
      'widthPx': collisionRect.widthPx,
      'heightPx': collisionRect.heightPx,
    },
    'initialState': initialState.name,
  };

  @override
  bool operator ==(Object other) =>
      other is MovingPropDefinition &&
      other.id == id &&
      other.placedElementId == placedElementId &&
      other.closedPositionPx == closedPositionPx &&
      other.openPositionPx == openPositionPx &&
      other.collisionRect.leftPx == collisionRect.leftPx &&
      other.collisionRect.topPx == collisionRect.topPx &&
      other.collisionRect.widthPx == collisionRect.widthPx &&
      other.collisionRect.heightPx == collisionRect.heightPx &&
      other.initialState == initialState;

  @override
  int get hashCode => Object.hash(
    id,
    placedElementId,
    closedPositionPx,
    openPositionPx,
    collisionRect.leftPx,
    collisionRect.topPx,
    collisionRect.widthPx,
    collisionRect.heightPx,
    initialState,
  );
}

final class MovingPropWorldState {
  const MovingPropWorldState.empty() : propsByMap = const {};

  MovingPropWorldState({
    required Map<String, Map<String, MovingPropState>> propsByMap,
  }) : propsByMap = Map.unmodifiable({
         for (final entry in propsByMap.entries)
           _identity(entry.key): Map<String, MovingPropState>.unmodifiable({
             for (final prop in entry.value.entries)
               _identity(prop.key): prop.value,
           }),
       });

  final Map<String, Map<String, MovingPropState>> propsByMap;

  MovingPropState? prop(String mapId, String propId) =>
      propsByMap[mapId]?[propId];

  MovingPropWorldState withProp({
    required String mapId,
    required String propId,
    required MovingPropState state,
  }) => MovingPropWorldState(
    propsByMap: {
      ...propsByMap,
      mapId: {...?propsByMap[mapId], propId: state},
    },
  );

  factory MovingPropWorldState.fromJson(Map<String, dynamic> json) {
    _keys(json, {'schemaVersion', 'propsByMap'});
    if (_integer(json['schemaVersion']) != 1) {
      throw const FormatException('Unsupported moving prop state schema.');
    }
    return MovingPropWorldState(
      propsByMap: _object(json['propsByMap']).map(
        (mapId, props) => MapEntry(
          mapId,
          _object(
            props,
          ).map((propId, state) => MapEntry(propId, _state(state))),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'propsByMap': propsByMap.map(
      (mapId, props) => MapEntry(
        mapId,
        props.map((propId, state) => MapEntry(propId, state.name)),
      ),
    ),
  };

  @override
  bool operator ==(Object other) =>
      other is MovingPropWorldState &&
      const DeepCollectionEquality().equals(propsByMap, other.propsByMap);

  @override
  int get hashCode => const DeepCollectionEquality().hash(propsByMap);
}

void _keys(Map<String, dynamic> json, Set<String> keys) {
  if (json.keys.toSet().difference(keys).isNotEmpty ||
      keys.difference(json.keys.toSet()).isNotEmpty) {
    throw const FormatException('Invalid moving prop fields.');
  }
}

String _identity(Object? value) {
  if (value is! String || value.isEmpty || value.trim() != value) {
    throw const FormatException('Invalid moving prop identity.');
  }
  return value;
}

int _integer(Object? value) {
  if (value is! int || value.abs() > 9007199254740991) {
    throw const FormatException(
      'Moving prop geometry requires exact integers.',
    );
  }
  return value;
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Expected moving prop object.');
  }
  return value;
}

PixelOffset _position(Object? value) {
  final json = _object(value);
  _keys(json, {'x', 'y'});
  return PixelOffset(x: _integer(json['x']), y: _integer(json['y']));
}

bool _validPosition(PixelOffset position) =>
    position.x >= 0 &&
    position.y >= 0 &&
    position.x <= 9007199254740991 &&
    position.y <= 9007199254740991;

MovingPropState _state(Object? value) => switch (value) {
  'closed' => MovingPropState.closed,
  'open' => MovingPropState.open,
  _ => throw const FormatException('Invalid settled moving prop state.'),
};
