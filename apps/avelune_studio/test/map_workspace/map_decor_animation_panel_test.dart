import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_decor_animation_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets(
    'idle image selects a terminal frame with undo and native reopen',
    (tester) async {
      final fixture = await _idleFixture(tester, [83, 84, 83, 83]);
      final document = fixture.$1;
      final before = document.current;
      expect(find.text('Image d’attente'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('decor-idle-frame')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Image 4').last);
      await tester.pumpAndSettle();
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
      expect(
        find.byKey(const ValueKey('decor-idle-frame-preview')),
        findsOneWidget,
      );
      expect(fixture.$3.previewed!.frames.single.source.x, 6);
      expect(find.text('native-frame-6'), findsOneWidget);
      document.restore(redo: false);
      expect(document.current, before);
    },
  );

  testWidgets(
    'idle image uses normalized durations and preserves speed mode and triggers',
    (tester) async {
      final fixture = await _idleFixture(
        tester,
        [100, 0, null],
        animation: const MapPlacedElementAnimation(
          enabled: true,
          mode: MapPlacedElementAnimationMode.pingPong,
          speed: 2.5,
          randomStart: true,
        ),
      );
      final document = fixture.$1;
      final behaviors = document.selected!.behaviors;
      expect(find.text('Image d’attente'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('decor-idle-frame')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Image 3').last);
      await tester.pumpAndSettle();
      final animation = document.selected!.animation!;
      expect(animation.startOffsetMs, 300);
      expect(animation.speed, 2.5);
      expect(animation.mode, MapPlacedElementAnimationMode.pingPong);
      expect(animation.autoplay, isFalse);
      expect(animation.randomStart, isFalse);
      expect(document.selected!.behaviors, behaviors);
    },
  );

  testWidgets('random departure clears a fixed waiting image', (tester) async {
    final fixture = await _idleFixture(
      tester,
      [100, 250, 150],
      animation: const MapPlacedElementAnimation(
        enabled: true,
        mode: MapPlacedElementAnimationMode.loop,
        autoplay: false,
        startOffsetMs: 350,
      ),
    );
    expect(find.text('native-frame-4'), findsOneWidget);
    await tester.tap(find.text('Départ aléatoire'));
    await tester.pump();
    expect(fixture.$1.selected!.animation!.randomStart, isTrue);
    expect(fixture.$1.selected!.animation!.startOffsetMs, isNull);
  });

  testWidgets(
    'single frame decor keeps its ordinary panel and no idle selector',
    (tester) async {
      final fixture = await _idleFixture(tester, [100]);
      expect(find.text('Image d’attente'), findsNothing);
      expect(fixture.$1.canUndo, isFalse);
      expect(fixture.$1.selected!.animation, isNull);
    },
  );

  testWidgets('animated decor configures runtime triggers and survives JSON', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(700, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final project = workspaceProject.copyWith(
      elements: [
        workspaceElement.copyWith(
          frames: [
            ...workspaceElement.frames,
            const TilesetVisualFrame(
              source: TilesetSourceRect(x: 2, y: 0, width: 2, height: 2),
            ),
          ],
        ),
      ],
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(
        map: workspaceMap('a').copyWith(
          placedElements: const [
            MapPlacedElement(
              id: 'tree-1',
              layerId: 'ground',
              elementId: 'tree',
              pos: GridPos(x: 2, y: 2),
            ),
          ],
        ),
        revision: 'r0',
        mapId: 'a',
      ),
    )..selectedId = 'tree-1';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: MapDecorAnimationPanel(
              document: document,
              project: project,
              visuals: WorkspaceTestVisuals(),
              onChanged: () {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Animation active'));
    await tester.pump();
    expect(document.selected!.animation!.enabled, isTrue);
    expect(
      document.selected!.animation!.mode,
      MapPlacedElementAnimationMode.loop,
    );
    await tester.tap(find.text('Aller-retour'));
    await tester.pump();
    expect(
      document.selected!.animation!.mode,
      MapPlacedElementAnimationMode.pingPong,
    );
    await tester.scrollUntilVisible(
      find.text('Ajouter le déclencheur'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Ajouter le déclencheur'));
    await tester.pump();
    expect(
      document.selected!.behaviors.single.effect.type,
      MapPlacedElementEffectType.playAnimationOnce,
    );
    final reopened = MapData.fromJson(document.current.toJson());
    expect(reopened.placedElements.single.animation!.enabled, isTrue);
    expect(
      reopened.placedElements.single.animation!.mode,
      MapPlacedElementAnimationMode.pingPong,
    );
    expect(reopened.placedElements.single.behaviors, hasLength(1));
  });
}

Future<(EditableMapDocument, ProjectManifest, _IdleVisuals)> _idleFixture(
  WidgetTester tester,
  List<int?> durations, {
  MapPlacedElementAnimation? animation,
}) async {
  tester.view.physicalSize = const Size(700, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final project = workspaceProject.copyWith(
    elements: [
      workspaceElement.copyWith(
        frames: [
          for (var i = 0; i < durations.length; i++)
            TilesetVisualFrame(
              source: TilesetSourceRect(x: i * 2, y: 0, width: 2, height: 2),
              durationMs: durations[i],
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
            behaviors: const [
              MapPlacedElementBehavior(
                trigger: MapPlacedElementTriggerType.onAction,
                effect: MapPlacedElementEffect(
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
  final visuals = _IdleVisuals();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 320,
          child: StatefulBuilder(
            builder: (context, refresh) => MapDecorAnimationPanel(
              document: document,
              project: project,
              visuals: visuals,
              onChanged: () => refresh(() {}),
            ),
          ),
        ),
      ),
    ),
  );
  return (document, project, visuals);
}

class _IdleVisuals extends WorkspaceTestVisuals {
  ProjectElementEntry? previewed;
  @override
  Widget thumbnail(ProjectElementEntry element, {double size = 48}) {
    previewed = element;
    return Text('native-frame-${element.frames.single.source.x}');
  }
}
