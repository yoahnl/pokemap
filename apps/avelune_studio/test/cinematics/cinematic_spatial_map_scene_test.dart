import 'package:avelune_studio/features/cinematics/application/cinematic_preview_transport.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_map_model.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_map_scene.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_spatial_map_scene.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../support/spatial_narrative_fixture.dart';

void main() {
  CinematicMapModel model() => CinematicMapModel(
    spatialNarrativeCinematic(),
    spatialNarrativeProject(),
    spatialNarrativeMap(),
  );

  test(
    '3D actor origin uses feet while authored stage points remain unchanged',
    () {
      final spatial = model();
      final npc = spatial.actors.actorById('chief')!.position;
      expect((npc.x, npc.y), (13.5, 7.5));
      final hero = spatial.actors.actorById('hero')!.position;
      expect((hero.x, hero.y), (8.5, 9.5));
      final twoD = CinematicMapModel(
        spatial.asset,
        spatial.project,
        spatial.map.copyWith(spatialScene: null),
      );
      expect(twoD.actors.actorById('chief')!.position.y, 7);
      expect(spatial.map.entities.single.pos, const GridPos(x: 13, y: 7));
      final fromTarget = CinematicMapModel(
        spatial.asset.copyWith(
          stageContext: CinematicStageContext(
            backdropMode: spatial.asset.stageContext!.backdropMode,
            actorBindings: spatial.asset.stageContext!.actorBindings,
            movementTargetBindings:
                spatial.asset.stageContext!.movementTargetBindings,
            stagePoints: spatial.asset.stageContext!.stagePoints,
            manualPaths: spatial.asset.stageContext!.manualPaths,
            initialPlacements: [
              CinematicActorInitialPlacement(
                actorId: 'hero',
                kind: CinematicActorInitialPlacementKind.fromMovementTarget,
                targetId: 'arrival',
              ),
              spatial.asset.stageContext!.initialPlacements.last,
            ],
          ),
        ),
        spatial.project,
        spatial.map,
      );
      final targetOrigin = fromTarget.actors.actorById('hero')!.position;
      expect((targetOrigin.x, targetOrigin.y), (13.5, 9.5));
    },
  );

  test(
    'authored path previews every terrain cell from start to destination',
    () {
      final source = model();
      final color = studioTheme().colorScheme.primary;
      final cells = cinematicSpatialOverlays(
        source,
        color,
      ).map((overlay) => overlay.cell).toSet();
      expect(cells, {(8, 9), (9, 9), (10, 9), (11, 9), (12, 9), (13, 9)});
      final original = source.map.toJson();
      cinematicSpatialOverlays(source, color);
      expect(source.map.toJson(), original);
    },
  );

  test('sprite preview timing respects authored frame durations and loop', () {
    const frames = [
      CharacterAnimationFrame(
        source: TilesetSourceRect(x: 0, y: 0, width: 16, height: 16),
        durationMs: 100,
      ),
      CharacterAnimationFrame(
        source: TilesetSourceRect(x: 16, y: 0, width: 16, height: 16),
        durationMs: 200,
      ),
    ];
    expect(studioCinematicCharacterFrame(frames, 100, loop: true), frames[1]);
    expect(studioCinematicCharacterFrame(frames, 300, loop: true), frames[0]);
    expect(studioCinematicCharacterFrame(frames, 900, loop: false), frames[1]);
  });

  testWidgets(
    '3D cinematic keeps existing point commands, preview and Escape cancellation',
    (tester) async {
      final source = model(),
          view = CinematicViewState()..mode = CinematicMapMode.path;
      final transport = CinematicPreviewTransport();
      final visuals = SpatialNarrativeVisuals();
      final chosen = <Offset>[], moved = <Offset>[];
      transport.install(
        buildCinematicPreviewPlaybackPlan(
          cinematic: source.asset,
          actorDisplayPreviewModel: source.actors,
          stageBounds: source.bounds,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => CinematicMapScene(
                model: source,
                visuals: visuals,
                view: view,
                transport: transport,
                changed: () => setState(() {}),
                onPoint: chosen.add,
                onPointMove: (_, point) => moved.add(point),
                beforeSelect: () => true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      SpatialSceneView canvas() => tester.widget(find.byType(SpatialSceneView));
      expect(find.byType(CinematicSpatialMapScene), findsOneWidget);
      canvas().onCell(10, 9);
      expect(chosen.single, const Offset(10.5, 9.5));
      expect(source.asset.stageContext!.stagePoints.first.x, 8.5);
      view.mode = CinematicMapMode.select;
      await tester.pump();
      expect(canvas().onDragStart!(8, 9, null), isTrue);
      canvas().onDragUpdate!((10, 9));
      await tester.pump();
      expect(moved, isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      canvas().onDragEnd!();
      expect(moved, isEmpty);
      expect(canvas().onDragStart!(8, 9, null), isTrue);
      canvas().onDragUpdate!((9, 9));
      canvas().onDragEnd!();
      expect(moved.single, const Offset(9.5, 9.5));
      canvas().controller.panBy(2, 1);
      canvas().controller.dolly(220);
      final editingZoom = canvas().controller.zoom;
      transport.seek(500);
      await tester.pump();
      expect(canvas().cellOverlays, isEmpty);
      final camera = canvas().cameraPose!()!;
      expect(camera.x + canvas().controller.pan.dx, 8.5);
      expect(camera.z + canvas().controller.pan.dy, 9.5);
      expect(camera.y, source.map.spatialScene!.worldHeightAt(8.5, 9.5));
      expect(camera.zoom / editingZoom, 1);
      expect(canvas().onDragStart!(8, 9, null), isFalse);
      transport.pause();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(transport.previewActive, isFalse);
      expect(canvas().cellOverlays, isNotEmpty);
      expect(canvas().cameraPose!(), isNull);
      expect(canvas().controller.pan, const Offset(2, 1));
      expect(canvas().controller.zoom, editingZoom);
      await tester.pumpWidget(const SizedBox());
      expect(visuals.previewsDisposed, 1);
      view.dispose();
      transport.dispose();
      await visuals.dispose();
      expect(tester.takeException(), isNull);
    },
  );
}
