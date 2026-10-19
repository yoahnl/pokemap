import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_ramp_editor.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_ramp_fixture.dart';

Finder field(String key) => find.descendant(
  of: find.byKey(ValueKey('spatial-ramp-$key')),
  matching: find.byType(TextField),
);

void main() {
  testWidgets(
    'fractional stair endpoints display edit preview apply and undo without snapping',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final ramp = SpatialRamp.fromJson({
        'id': 'stairs',
        'x': 2,
        'z': 2,
        'width': 1,
        'depth': 2,
        'lowLevel': 0,
        'highLevel': 1.12542724609375,
        'direction': 'north',
        'surfaceInstanceId': 'stairs',
      });
      final map = MapData(
        id: 'map',
        name: 'Fractional stairs',
        version: ProjectVersion.v9,
        size: const GridSize(width: 8, height: 8),
        spatialScene: MapSpatialScene(
          width: 8,
          depth: 8,
          navigation: SpatialNavigationProfile(ramps: [ramp]),
          instances: [
            SpatialModelInstance(
              id: 'stairs',
              modelId: 'model',
              position: Model3dVector3(x: 2, y: 0, z: 2),
              blocksMovement: false,
            ),
          ],
        ),
      );
      final document = rampDocument(map);
      final view = MapWorkspaceViewState();
      addTearDown(view.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, refresh) => SingleChildScrollView(
                child: SpatialRampEditor(
                  document: document,
                  view: view,
                  onChanged: () => refresh(() {}),
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.widget<TextField>(field('high-level')).controller!.text,
        '1.12542724609375',
      );
      await tester.enterText(field('high-level'), '1,5');
      await tester.tap(find.byKey(const ValueKey('spatial-ramp-preview')));
      await tester.pump();
      expect(view.rampPreview!.updatedRamp.highLevel, 1.5);
      expect(document.current, map);
      await tester.tap(find.byKey(const ValueKey('spatial-ramp-apply')));
      await tester.pump();
      expect(
        document.current.spatialScene!.navigation.ramps.single.highLevel,
        1.5,
      );
      expect(
        document.current.spatialScene!.heightLevels,
        map.spatialScene!.heightLevels,
      );
      final applied = document.current;
      await tester.enterText(field('high-level'), 'NaN');
      await tester.tap(find.byKey(const ValueKey('spatial-ramp-preview')));
      await tester.pump();
      expect(view.rampPreview, isNull);
      expect(document.current, applied);
      expect(find.textContaining('nombre fini'), findsOneWidget);
      document.restore(redo: false);
      expect(document.current, map);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}
