import 'package:avelune_studio/features/cinematics/application/cinematic_preview_transport.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_map_model.dart';
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
