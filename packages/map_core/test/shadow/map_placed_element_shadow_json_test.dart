import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MapPlacedElement shadowOverride JSON', () {
    test('decodes legacy placed element JSON without shadowOverride as null',
        () {
      final element = MapPlacedElement.fromJson(_placedElementJson());

      expect(element.shadowOverride, isNull);
    });

    test('decodes null, inherit, disabled, and custom overrides', () {
      expect(
        MapPlacedElement.fromJson(
          _placedElementJson(shadowOverride: null),
        ).shadowOverride,
        isNull,
      );
      expect(
        MapPlacedElement.fromJson(
          _placedElementJson(
            shadowOverride: <String, Object?>{'mode': 'inherit'},
          ),
        ).shadowOverride,
        MapPlacedElementShadowOverride(),
      );
      expect(
        MapPlacedElement.fromJson(
          _placedElementJson(
            shadowOverride: <String, Object?>{'mode': 'disabled'},
          ),
        ).shadowOverride,
        MapPlacedElementShadowOverride(mode: ShadowOverrideMode.disabled),
      );
      expect(
        MapPlacedElement.fromJson(
          _placedElementJson(
            shadowOverride: <String, Object?>{
              'mode': 'custom',
              'shadowProfileId': 'tree_short',
              'offsetX': 2,
              'offsetY': 8,
              'scaleX': 0.8,
              'scaleY': 0.35,
              'opacity': 0.25,
            },
          ),
        ).shadowOverride,
        _customOverride(),
      );
    });

    test('encodes non-null and null shadowOverride using existing style', () {
      expect(
        _placedElement(shadowOverride: _customOverride())
            .toJson()['shadowOverride'],
        <String, Object?>{
          'mode': 'custom',
          'shadowProfileId': 'tree_short',
          'offsetX': 2.0,
          'offsetY': 8.0,
          'scaleX': 0.8,
          'scaleY': 0.35,
          'opacity': 0.25,
        },
      );
      expect(_placedElement().toJson(), containsPair('shadowOverride', null));
    });

    test('copyWith modifies and preserves shadowOverride', () {
      final override = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.disabled,
      );
      final updated = _placedElement().copyWith(shadowOverride: override);

      expect(updated.shadowOverride, override);
      expect(updated.copyWith(opacity: 0.5).shadowOverride, override);
    });

    test('legacy MapData JSON decodes placed element without shadowOverride',
        () {
      final map = MapData.fromJson(<String, Object?>{
        'id': 'map',
        'name': 'Map',
        'size': <String, Object?>{'width': 10, 'height': 8},
        'placedElements': <Object?>[_placedElementJson()],
      });

      expect(map.placedElements.single.shadowOverride, isNull);
    });

    test('MapData JSON preserves placed element shadowOverride', () {
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 10, height: 8),
        placedElements: [
          _placedElement(shadowOverride: _customOverride()),
        ],
      );

      final encodedElement = (map.toJson()['placedElements'] as List<Object?>)
          .single as Map<String, Object?>;

      expect(encodedElement['shadowOverride'], <String, Object?>{
        'mode': 'custom',
        'shadowProfileId': 'tree_short',
        'offsetX': 2.0,
        'offsetY': 8.0,
        'scaleX': 0.8,
        'scaleY': 0.35,
        'opacity': 0.25,
      });

      final decoded = MapData.fromJson(map.toJson());
      expect(decoded.placedElements.single.shadowOverride, _customOverride());
    });

    test('adding shadowOverride does not modify gameplay or authoring fields',
        () {
      const behavior = MapPlacedElementBehavior(
        id: 'behavior',
        trigger: MapPlacedElementTriggerType.onAction,
        effect: MapPlacedElementEffect(
          type: MapPlacedElementEffectType.showMessage,
          message: 'Hello',
        ),
      );
      const animation = MapPlacedElementAnimation(
        enabled: true,
        speed: 1.5,
        startOffsetMs: 120,
      );
      final element = _placedElement(
        applyCollision: false,
        opacity: 0.4,
        animation: animation,
        behaviors: const [behavior],
        properties: const {'purpose': 'authoring'},
      );

      final updated = element.copyWith(shadowOverride: _customOverride());

      expect(updated.applyCollision, element.applyCollision);
      expect(updated.opacity, element.opacity);
      expect(updated.animation, same(animation));
      expect(updated.behaviors, element.behaviors);
      expect(updated.properties, element.properties);
    });
  });
}

const _shadowOverrideAbsent = Object();

Map<String, Object?> _placedElementJson({
  Object? shadowOverride = _shadowOverrideAbsent,
}) {
  return <String, Object?>{
    'id': 'tree_instance',
    'layerId': 'objects',
    'elementId': 'tree',
    'pos': <String, Object?>{'x': 1, 'y': 2},
    if (!identical(shadowOverride, _shadowOverrideAbsent))
      'shadowOverride': shadowOverride,
  };
}

MapPlacedElement _placedElement({
  MapPlacedElementShadowOverride? shadowOverride,
  bool applyCollision = true,
  double opacity = 1,
  MapPlacedElementAnimation? animation,
  List<MapPlacedElementBehavior> behaviors = const [],
  Map<String, String> properties = const {},
}) {
  return MapPlacedElement(
    id: 'tree_instance',
    layerId: 'objects',
    elementId: 'tree',
    pos: const GridPos(x: 1, y: 2),
    applyCollision: applyCollision,
    opacity: opacity,
    animation: animation,
    behaviors: behaviors,
    properties: properties,
    shadowOverride: shadowOverride,
  );
}

MapPlacedElementShadowOverride _customOverride() {
  return MapPlacedElementShadowOverride(
    mode: ShadowOverrideMode.custom,
    shadowProfileId: 'tree_short',
    offsetX: 2,
    offsetY: 8,
    scaleX: 0.8,
    scaleY: 0.35,
    opacity: 0.25,
  );
}
