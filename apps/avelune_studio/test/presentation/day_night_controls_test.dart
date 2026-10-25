import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_day_night_panel.dart';
import 'package:avelune_studio/presentation/features/resources/model_light_controls.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_toggle_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../support/spatial_environment_fixture.dart';

void main() {
  testWidgets('atmosphere toggles update only their session in one frame', (
    tester,
  ) async {
    final map = spatialEnvironmentMap();
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'atmosphere'),
    );
    final preview = SpatialSceneController()
      ..atmosphereProfile = SpatialAtmosphereProfile(
        waterTargets: const [
          SpatialAtmosphereTarget(instanceId: 'river', materialName: 'water'),
        ],
        windows: [
          SpatialWindowGlow(
            target: const SpatialAtmosphereTarget(
              instanceId: 'house',
              materialName: 'glass',
            ),
            uvRects: const [Rect.fromLTWH(0, 0, 1, 1)],
          ),
        ],
        fireflyZones: [
          SpatialFireflyZone(
            bounds: Model3dBounds(
              min: Model3dVector3(x: 0, y: 0, z: 0),
              max: Model3dVector3(x: 2, y: 2, z: 2),
            ),
          ),
        ],
      );
    addTearDown(preview.dispose);
    var changes = 0;
    var notifications = 0;
    preview.addListener(() => notifications++);
    await tester.binding.setSurfaceSize(const Size(800, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapDayNightPanel(
            document: document,
            controller: preview,
            onChanged: () => changes++,
          ),
        ),
      ),
    );
    var diskAccesses = 0;
    await IOOverrides.runZoned(
      () async {
        for (final (id, enabled) in [
          ('water', (true, false, false)),
          ('windows', (true, true, false)),
          ('fireflies', (true, true, true)),
        ]) {
          await tester.tap(find.byKey(ValueKey('atmosphere-preview-$id')));
          await tester.pump(const Duration(milliseconds: 16));
          expect((
            preview.waterAnimated,
            preview.windowsLit,
            preview.fireflies,
          ), enabled);
          expect(document.current, same(map));
          expect(document.dirty, isFalse);
          expect(document.undoCount, 0);
          expect(changes, 0);
        }
        expect(notifications, 3);
        for (final (id, enabled) in [
          ('windows', (true, false, true)),
          ('water', (false, false, true)),
          ('fireflies', (false, false, false)),
        ]) {
          await tester.tap(find.byKey(ValueKey('atmosphere-preview-$id')));
          await tester.pump(const Duration(milliseconds: 16));
          expect(
            tester
                .widget<StudioToggleRow>(
                  find.byKey(ValueKey('atmosphere-preview-$id')),
                )
                .value,
            isFalse,
          );
          expect((
            preview.waterAnimated,
            preview.windowsLit,
            preview.fireflies,
          ), enabled);
        }
      },
      createFile: (path) {
        diskAccesses++;
        throw StateError('Unexpected preview file access: $path');
      },
      createDirectory: (path) {
        diskAccesses++;
        throw StateError('Unexpected preview directory access: $path');
      },
      createLink: (path) {
        diskAccesses++;
        throw StateError('Unexpected preview link access: $path');
      },
    );
    expect(diskAccesses, 0);
    expect(notifications, 6);
    expect(document.current, same(map));
    expect(document.dirty, isFalse);
    expect(document.undoCount, 0);
    expect(changes, 0);
    final secondSession = SpatialSceneController();
    expect(secondSession.waterAnimated, isFalse);
    expect(secondSession.windowsLit, isFalse);
    expect(secondSession.fireflies, isFalse);
    secondSession.dispose();
  });

  testWidgets('atmosphere preview explains unavailable targets without edits', (
    tester,
  ) async {
    final map = spatialEnvironmentMap();
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'atmosphere'),
    );
    final preview = SpatialSceneController();
    addTearDown(preview.dispose);
    var changes = 0;
    await tester.binding.setSurfaceSize(const Size(800, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapDayNightPanel(
            document: document,
            controller: preview,
            onChanged: () => changes++,
          ),
        ),
      ),
    );
    for (final id in ['water', 'windows', 'fireflies']) {
      final control = find.byKey(ValueKey('atmosphere-preview-$id'));
      expect(control, findsOneWidget);
      expect(tester.widget<StudioToggleRow>(control).onChanged, isNull);
      expect(tester.widget<StudioToggleRow>(control).description, isNotEmpty);
    }
    expect(document.current, same(map));
    expect(document.dirty, isFalse);
    expect(document.undoCount, 0);
    expect(changes, 0);
  });

  testWidgets('lamp settings validate radius and save a local emitter', (
    tester,
  ) async {
    Model3dPointLight? saved;
    var saves = 0;
    await tester.binding.setSurfaceSize(const Size(900, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModelLightControls(
            model: spatialEnvironmentProject().models3d.single,
            onSave: (light) async {
              saved = light;
              saves++;
            },
          ),
        ),
      ),
    );
    final enabled = find.byKey(const ValueKey('model-light-enabled'));
    expect(tester.widget<StudioToggleRow>(enabled).value, isFalse);
    await tester.tap(enabled);
    await tester.pump();
    final radius = find.descendant(
      of: find.byKey(const ValueKey('model-light-radius')),
      matching: find.byType(TextField),
    );
    await tester.enterText(radius, '-1');
    await tester.tap(find.byKey(const ValueKey('model-light-save')));
    await tester.pump();
    expect(saves, 0);
    expect(find.textContaining('portée'), findsWidgets);
    await tester.enterText(radius, '5,5');
    await tester.tap(find.byKey(const ValueKey('model-light-save')));
    await tester.pump();
    expect(saves, 1);
    expect(saved!.radius, 5.5);
    expect(saved!.nightOnly, isTrue);
    expect(saved!.colorRgb, 0xffd59a);
    await tester.tap(enabled);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('model-light-save')));
    await tester.pump();
    expect(saves, 2);
    expect(saved, isNull);
  });

  testWidgets(
    'cycle editing is undoable while preview leaves the map unchanged',
    (tester) async {
      final map = spatialEnvironmentMap();
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: map.id, revision: 'cycle'),
      );
      final preview = SpatialSceneController();
      addTearDown(preview.dispose);
      await tester.binding.setSurfaceSize(const Size(800, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, refresh) => MapDayNightPanel(
                document: document,
                controller: preview,
                onChanged: () => refresh(() {}),
              ),
            ),
          ),
        ),
      );
      expect(document.current.spatialScene!.dayNightCycle, isNull);
      await tester.tap(find.byKey(const ValueKey('map-day-night-enabled')));
      await tester.pump();
      expect(document.current.spatialScene!.dayNightCycle, isNotNull);
      expect(document.undoCount, 1);
      final saved = document.current;
      await tester.tap(find.byKey(const ValueKey('day-night-preview-night')));
      await tester.pump();
      expect(preview.previewMinuteOfDay, 1320);
      expect(document.current, same(saved));
      expect(document.undoCount, 1);
      document.restore(redo: false);
      expect(document.current.spatialScene!.dayNightCycle, isNull);
      document.restore(redo: true);
      expect(document.current.spatialScene!.dayNightCycle, isNotNull);
    },
  );
}
