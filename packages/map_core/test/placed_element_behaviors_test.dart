import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MapPlacedElement behavior migration', () {
    test('legacy interaction message migrates to behavior', () {
      final decoded = MapPlacedElement.fromJson({
        'id': 'layer::1::1',
        'layerId': 'layer',
        'elementId': 'tree',
        'pos': {'x': 1, 'y': 1},
        'interaction': {
          'enabled': true,
          'mode': 'message',
          'message': 'Bonjour',
        },
      });

      expect(decoded.behaviors, hasLength(1));
      final behavior = decoded.behaviors.first;
      expect(behavior.id.trim(), isNotEmpty);
      expect(behavior.enabled, isTrue);
      expect(behavior.trigger, MapPlacedElementTriggerType.onAction);
      expect(behavior.effect.type, MapPlacedElementEffectType.showMessage);
      expect(behavior.effect.message, 'Bonjour');
    });

    test('legacy behavior list without ids receives stable non-empty ids', () {
      final decoded = MapPlacedElement.fromJson({
        'id': 'layer::1::1',
        'layerId': 'layer',
        'elementId': 'tree',
        'pos': {'x': 1, 'y': 1},
        'behaviors': [
          {
            'enabled': true,
            'trigger': 'on_action',
            'effect': {'type': 'show_message', 'message': 'A'},
          },
          {
            'enabled': true,
            'trigger': 'on_enter',
            'effect': {'type': 'show_message', 'message': 'B'},
          },
        ],
      });
      expect(decoded.behaviors, hasLength(2));
      expect(decoded.behaviors[0].id.trim(), isNotEmpty);
      expect(decoded.behaviors[1].id.trim(), isNotEmpty);
      expect(decoded.behaviors[0].id, isNot(decoded.behaviors[1].id));
    });

    test('parses onExit and onNear triggers from json', () {
      final exitBehavior = MapPlacedElementBehavior.fromJson({
        'enabled': true,
        'trigger': 'on_exit',
        'effect': {
          'type': 'show_message',
          'message': 'bye',
        },
      });
      final nearBehavior = MapPlacedElementBehavior.fromJson({
        'enabled': true,
        'trigger': 'on_near',
        'effect': {
          'type': 'show_message',
          'message': 'near',
        },
      });

      expect(exitBehavior.trigger, MapPlacedElementTriggerType.onExit);
      expect(nearBehavior.trigger, MapPlacedElementTriggerType.onNear);
      expect(exitBehavior.toJson()['trigger'], 'on_exit');
      expect(nearBehavior.toJson()['trigger'], 'on_near');
    });

    test('serializes and deserializes optional cooldownMs', () {
      final behavior = MapPlacedElementBehavior.fromJson({
        'id': 'b1',
        'enabled': true,
        'triggerScope': 'facing_only',
        'cooldownMs': 750,
        'trigger': 'on_action',
        'effect': {
          'type': 'show_message',
          'message': 'hello',
        },
      });

      expect(behavior.cooldownMs, 750);
      expect(behavior.triggerScope, MapPlacedElementTriggerScope.facingOnly);
      expect(behavior.toJson()['cooldownMs'], 750);
      expect(behavior.toJson()['triggerScope'], 'facing_only');
    });

    test('legacy behavior json without cooldownMs/triggerScope keeps defaults',
        () {
      final behavior = MapPlacedElementBehavior.fromJson({
        'id': 'b1',
        'enabled': true,
        'trigger': 'on_action',
        'effect': {
          'type': 'show_message',
          'message': 'hello',
        },
      });

      expect(behavior.cooldownMs, isNull);
      expect(
        behavior.triggerScope,
        MapPlacedElementTriggerScope.defaultScope,
      );
      expect(behavior.toJson().containsKey('cooldownMs'), isTrue);
      expect(behavior.toJson()['cooldownMs'], isNull);
      expect(behavior.toJson()['triggerScope'], 'default');
    });
  });

  group('MapPlacedElement behavior validation', () {
    test('rejects behavior with empty id', () {
      final map = _baseMap(
        behavior: const MapPlacedElementBehavior(
          id: '',
          enabled: true,
          trigger: MapPlacedElementTriggerType.onAction,
          effect: MapPlacedElementEffect(
            type: MapPlacedElementEffectType.showMessage,
            message: 'hello',
          ),
        ),
      );

      expect(
        () => MapValidator.validate(map, projectDialogueContext: _project()),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects showMessage without text', () {
      final map = _baseMap(
        behavior: const MapPlacedElementBehavior(
          id: 'b1',
          enabled: true,
          trigger: MapPlacedElementTriggerType.onAction,
          effect: MapPlacedElementEffect(
            type: MapPlacedElementEffectType.showMessage,
            message: '',
          ),
        ),
      );

      expect(
        () => MapValidator.validate(map, projectDialogueContext: _project()),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects openDialogue without dialogue ref', () {
      final map = _baseMap(
        behavior: const MapPlacedElementBehavior(
          id: 'b1',
          enabled: true,
          trigger: MapPlacedElementTriggerType.onAction,
          effect: MapPlacedElementEffect(
            type: MapPlacedElementEffectType.openDialogue,
          ),
        ),
      );

      expect(
        () => MapValidator.validate(map, projectDialogueContext: _project()),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects setAnimationEnabled without value', () {
      final map = _baseMap(
        behavior: const MapPlacedElementBehavior(
          id: 'b1',
          enabled: true,
          trigger: MapPlacedElementTriggerType.onAction,
          effect: MapPlacedElementEffect(
            type: MapPlacedElementEffectType.setAnimationEnabled,
          ),
        ),
      );

      expect(
        () => MapValidator.validate(map, projectDialogueContext: _project()),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects duplicate behavior ids in same instance', () {
      final map = _baseMap().copyWith(
        placedElements: [
          _baseMap().placedElements.first.copyWith(
            behaviors: const [
              MapPlacedElementBehavior(
                id: 'dup',
                enabled: true,
                trigger: MapPlacedElementTriggerType.onAction,
                effect: MapPlacedElementEffect(
                  type: MapPlacedElementEffectType.showMessage,
                  message: 'A',
                ),
              ),
              MapPlacedElementBehavior(
                id: 'dup',
                enabled: true,
                trigger: MapPlacedElementTriggerType.onEnter,
                effect: MapPlacedElementEffect(
                  type: MapPlacedElementEffectType.showMessage,
                  message: 'B',
                ),
              ),
            ],
          ),
        ],
      );

      expect(
        () => MapValidator.validate(map, projectDialogueContext: _project()),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects behavior with negative cooldownMs', () {
      final map = _baseMap(
        behavior: const MapPlacedElementBehavior(
          id: 'b1',
          enabled: true,
          cooldownMs: -1,
          trigger: MapPlacedElementTriggerType.onAction,
          effect: MapPlacedElementEffect(
            type: MapPlacedElementEffectType.showMessage,
            message: 'hello',
          ),
        ),
      );

      expect(
        () => MapValidator.validate(map, projectDialogueContext: _project()),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects behavior with excessive cooldownMs', () {
      final map = _baseMap(
        behavior: const MapPlacedElementBehavior(
          id: 'b1',
          enabled: true,
          cooldownMs: 600001,
          trigger: MapPlacedElementTriggerType.onAction,
          effect: MapPlacedElementEffect(
            type: MapPlacedElementEffectType.showMessage,
            message: 'hello',
          ),
        ),
      );

      expect(
        () => MapValidator.validate(map, projectDialogueContext: _project()),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects facingOnly scope on unsupported trigger', () {
      final map = _baseMap(
        behavior: const MapPlacedElementBehavior(
          id: 'b1',
          enabled: true,
          triggerScope: MapPlacedElementTriggerScope.facingOnly,
          trigger: MapPlacedElementTriggerType.onExit,
          effect: MapPlacedElementEffect(
            type: MapPlacedElementEffectType.showMessage,
            message: 'hello',
          ),
        ),
      );

      expect(
        () => MapValidator.validate(map, projectDialogueContext: _project()),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects nearCardinalOnly scope on unsupported trigger', () {
      final map = _baseMap(
        behavior: const MapPlacedElementBehavior(
          id: 'b1',
          enabled: true,
          triggerScope: MapPlacedElementTriggerScope.nearCardinalOnly,
          trigger: MapPlacedElementTriggerType.onAction,
          effect: MapPlacedElementEffect(
            type: MapPlacedElementEffectType.showMessage,
            message: 'hello',
          ),
        ),
      );

      expect(
        () => MapValidator.validate(map, projectDialogueContext: _project()),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('MapPlacedElement behavior operations', () {
    test('add/update/remove behavior by index', () {
      final map = _baseMap();
      final added = addMapPlacedElementBehavior(
        map,
        instanceId: 'layer::1::1',
        behavior: const MapPlacedElementBehavior(
          enabled: true,
          trigger: MapPlacedElementTriggerType.onAction,
          effect: MapPlacedElementEffect(
            type: MapPlacedElementEffectType.showMessage,
            message: 'A',
          ),
        ),
      );
      expect(added.placedElements.first.behaviors, hasLength(1));
      final addedBehaviorId = added.placedElements.first.behaviors.first.id;
      expect(addedBehaviorId.trim(), isNotEmpty);

      final updated = updateMapPlacedElementBehaviorAt(
        added,
        instanceId: 'layer::1::1',
        behaviorIndex: 0,
        behavior: const MapPlacedElementBehavior(
          enabled: true,
          triggerScope: MapPlacedElementTriggerScope.oncePerEnter,
          cooldownMs: 500,
          trigger: MapPlacedElementTriggerType.onEnter,
          effect: MapPlacedElementEffect(
            type: MapPlacedElementEffectType.showMessage,
            message: 'B',
          ),
        ),
      );
      expect(
        updated.placedElements.first.behaviors.first.trigger,
        MapPlacedElementTriggerType.onEnter,
      );
      expect(updated.placedElements.first.behaviors.first.id, addedBehaviorId);
      expect(updated.placedElements.first.behaviors.first.effect.message, 'B');
      expect(
        updated.placedElements.first.behaviors.first.triggerScope,
        MapPlacedElementTriggerScope.oncePerEnter,
      );
      expect(updated.placedElements.first.behaviors.first.cooldownMs, 500);

      final toggled = setMapPlacedElementBehaviorEnabledAt(
        updated,
        instanceId: 'layer::1::1',
        behaviorIndex: 0,
        enabled: false,
      );
      expect(toggled.placedElements.first.behaviors.first.enabled, isFalse);

      final removed = removeMapPlacedElementBehaviorAt(
        toggled,
        instanceId: 'layer::1::1',
        behaviorIndex: 0,
      );
      expect(removed.placedElements.first.behaviors, isEmpty);
    });
  });
}

MapData _baseMap({
  MapPlacedElementBehavior? behavior,
}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 4, height: 4),
    layers: const [
      MapLayer.tile(
        id: 'layer',
        name: 'Layer',
        tilesetId: 'ts',
        tiles: [
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
        ],
      ),
    ],
    placedElements: [
      MapPlacedElement(
        id: 'layer::1::1',
        layerId: 'layer',
        elementId: 'tree',
        pos: const GridPos(x: 1, y: 1),
        behaviors: behavior == null ? const [] : [behavior],
      ),
    ],
  );
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'project',
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(id: 'ts', name: 'ts', relativePath: 'ts.png'),
    ],
    elementCategories: const [
      ProjectElementCategory(id: 'decor', name: 'decor'),
    ],
    dialogues: const [
      ProjectDialogueEntry(
        id: 'intro',
        name: 'Intro',
        relativePath: 'dialogues/intro.yarn',
      ),
    ],
    elements: const [
      ProjectElementEntry(
        id: 'tree',
        name: 'Tree',
        tilesetId: 'ts',
        categoryId: 'decor',
        frames: [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
          ),
        ],
      ),
    ],
        surfaceCatalog: ProjectSurfaceCatalog(),);
}
