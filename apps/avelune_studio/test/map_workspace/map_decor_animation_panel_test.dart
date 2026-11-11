import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_decor_animation_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test('decor order context retains animation data without the retired order widget', () {
    final commands = _fixture(
      [100, 150],
      behaviorId: 'tree-1::behavior::0',
      animation: const MapPlacedElementAnimation(
        enabled: true,
        mode: MapPlacedElementAnimationMode.pingPong,
        speed: 2.5,
        autoplay: false,
        startOffsetMs: 100,
      ),
    );
    final document = commands.document;
    final before = document.current;
    expect(
      before.placedElements.single.behaviors.single.id,
      'tree-1::behavior::0',
    );
    final order = MapEditingCommands(
      document,
      commands.project,
    ).decorOrderContext()!;
    expect(order.target, same(document.selected));
    expect(order.position, document.selected!.pos);
    expect(order.reorderable.single.id, 'tree-1');
    expect(order.rank, 0);
    expect(order.forwardProblem, isNotNull);
    expect(order.backwardProblem, isNotNull);
    expect(order.target!.animation, before.placedElements.single.animation);
    expect(order.target!.behaviors, before.placedElements.single.behaviors);
    expect(document.current, same(before));
    expect(document.selectedId, 'tree-1');
    expect(document.canUndo, isFalse);
    final reopened = MapData.fromJson(document.current.toJson());
    expect(
      reopened.placedElements.single.animation,
      before.placedElements.single.animation,
    );
    expect(
      reopened.placedElements.single.behaviors,
      before.placedElements.single.behaviors,
    );
    expect(
      reopened.placedElements.single.behaviors.single.id,
      'tree-1::behavior::0',
    );
  });

  test('idle image selects terminal frame with undo and native reopen', () {
    final commands = _fixture([83, 84, 83, 83]);
    final document = commands.document;
    final before = document.current;
    expect(commands.idleImage(3), isTrue);
    final animation = document.selected!.animation!;
    expect(animation.startOffsetMs, 250);
    expect(animation.enabled, isTrue);
    expect(animation.autoplay, isFalse);
    expect(animation.randomStart, isFalse);
    expect(animation.mode, MapPlacedElementAnimationMode.loop);
    expect(
      MapData.fromJson(document.current.toJson())
          .placedElements
          .single
          .animation,
      animation,
    );
    expect(
      resolvePlacedElementAnimationFrameIndex(
        frameDurationsMs: const [83, 84, 83, 83],
        elapsedMs: 10000,
        animation: animation,
      ),
      3,
    );
    expect(commands.idleFrame, 3);
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(document.current, before);
  });

  test(
    'idle image normalizes durations and preserves speed mode and triggers',
    () {
      final commands = _fixture(
        [100, 0, null],
        animation: const MapPlacedElementAnimation(
          enabled: true,
          mode: MapPlacedElementAnimationMode.pingPong,
          speed: 2.5,
          randomStart: true,
        ),
      );
      final behaviors = commands.document.selected!.behaviors;
      expect(commands.idleImage(2), isTrue);
      final animation = commands.document.selected!.animation!;
      expect(animation.startOffsetMs, 300);
      expect(animation.speed, 2.5);
      expect(animation.mode, MapPlacedElementAnimationMode.pingPong);
      expect(animation.autoplay, isFalse);
      expect(animation.randomStart, isFalse);
      expect(commands.document.selected!.behaviors, behaviors);
    },
  );

  test('random departure clears a fixed waiting image', () {
    final commands = _fixture(
      [100, 250, 150],
      animation: const MapPlacedElementAnimation(
        enabled: true,
        mode: MapPlacedElementAnimationMode.loop,
        autoplay: false,
        startOffsetMs: 350,
      ),
    );
    expect(commands.idleFrame, 2);
    final animation = commands.document.selected!.animation!;
    commands.animation(
      animation.copyWith(randomStart: true, startOffsetMs: null),
    );
    expect(commands.document.selected!.animation!.randomStart, isTrue);
    expect(commands.document.selected!.animation!.startOffsetMs, isNull);
  });

  test('invalid speed and frame leave map and history intact', () {
    final commands = _fixture([100]);
    final before = commands.document.current;
    for (final invalid in ['NaN', 'Infinity', '0', '-1', 'wrong']) {
      expect(commands.speed(invalid), isFalse);
    }
    expect(commands.idleImage(-1), isFalse);
    expect(commands.idleImage(1), isFalse);
    expect(commands.document.current, same(before));
    expect(commands.document.canUndo, isFalse);
    expect(commands.document.selected!.animation, isNull);
    expect(commands.speed('2,5'), isTrue);
    expect(commands.document.selected!.animation!.speed, 2.5);
  });

  test(
    'animation triggers retain indices of unrelated behaviors and survive JSON',
    () {
      final commands = _fixture([100, 100]);
      final document = commands.document;
      expect(
        commands.animation(
          const MapPlacedElementAnimation(
            enabled: true,
            mode: MapPlacedElementAnimationMode.pingPong,
          ),
        ),
        isTrue,
      );
      expect(
        commands.addBehavior(MapPlacedElementTriggerType.onNear, 'start'),
        isTrue,
      );
      expect(
        commands.addBehavior(MapPlacedElementTriggerType.onExit, 'stop'),
        isTrue,
      );
      expect(commands.behaviors.map((entry) => entry.$1), [0, 1, 2]);
      expect(commands.setBehaviorEnabled(1, false), isTrue);
      expect(document.selected!.behaviors[1].enabled, isFalse);
      expect(commands.removeBehavior(0), isTrue);
      final reopened = MapData.fromJson(document.current.toJson())
          .placedElements
          .single;
      expect(reopened.animation!.mode, MapPlacedElementAnimationMode.pingPong);
      expect(reopened.behaviors.map((value) => value.trigger), [
        MapPlacedElementTriggerType.onNear,
        MapPlacedElementTriggerType.onExit,
      ]);
      expect(reopened.behaviors.map((value) => value.effect.animationEnabled), [
        true,
        false,
      ]);
    },
  );

  test('missing selection does not mutate another placement', () {
    final commands = _fixture([100, 100]);
    final before = commands.document.current;
    commands.document.selectedId = null;
    expect(commands.animation(const MapPlacedElementAnimation()), isFalse);
    expect(
      commands.addBehavior(MapPlacedElementTriggerType.onAction, 'once'),
      isFalse,
    );
    expect(commands.speed('2'), isFalse);
    expect(commands.document.current, same(before));
    expect(commands.document.canUndo, isFalse);
  });
}

MapDecorAnimationCommands _fixture(
  List<int?> frameTimes, {
  MapPlacedElementAnimation? animation,
  String behaviorId = '',
}) {
  final project = workspaceProject.copyWith(
    elements: [
      workspaceElement.copyWith(
        frames: [
          for (var i = 0; i < frameTimes.length; i++)
            TilesetVisualFrame(
              source: TilesetSourceRect(x: i * 2, y: 0, width: 2, height: 2),
              durationMs: frameTimes[i],
            ),
        ],
      ),
    ],
  );
  final document = EditableMapDocument(
    MapWorkspaceDocument(
      map: workspaceMap('a').copyWith(
        placedElements: [
          MapPlacedElement(
            id: 'tree-1',
            layerId: 'ground',
            elementId: 'tree',
            pos: const GridPos(x: 2, y: 2),
            animation: animation,
            behaviors: [
              MapPlacedElementBehavior(
                id: behaviorId,
                trigger: MapPlacedElementTriggerType.onAction,
                effect: const MapPlacedElementEffect(
                  type: MapPlacedElementEffectType.playAnimationOnce,
                ),
              ),
            ],
          ),
        ],
      ),
      revision: 'r0',
      mapId: 'a',
    ),
  )..selectedId = 'tree-1';
  return MapDecorAnimationCommands(document, project);
}
