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
      expect(behavior.enabled, isTrue);
      expect(behavior.trigger, MapPlacedElementTriggerType.onAction);
      expect(behavior.effect.type, MapPlacedElementEffectType.showMessage);
      expect(behavior.effect.message, 'Bonjour');
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
  });

  group('MapPlacedElement behavior validation', () {
    test('rejects showMessage without text', () {
      final map = _baseMap(
        behavior: const MapPlacedElementBehavior(
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

      final updated = updateMapPlacedElementBehaviorAt(
        added,
        instanceId: 'layer::1::1',
        behaviorIndex: 0,
        behavior: const MapPlacedElementBehavior(
          enabled: true,
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
      expect(updated.placedElements.first.behaviors.first.effect.message, 'B');

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
  );
}
