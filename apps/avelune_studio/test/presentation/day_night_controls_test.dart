import 'dart:io';
import 'dart:ui' show Rect;

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_spatial_settings_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/resources/application/model_light_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../support/spatial_environment_fixture.dart';

void main() {
  test(
    'atmosphere preview toggles update only their session without disk access',
    () async {
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
                min: Model3dVector3.zero,
                max: Model3dVector3(x: 2, y: 2, z: 2),
              ),
            ),
          ],
        );
      addTearDown(preview.dispose);
      expect(preview.atmosphereAvailability.water, isTrue);
      expect(preview.atmosphereAvailability.windows, isTrue);
      expect(preview.atmosphereAvailability.fireflies, isTrue);
      var notifications = 0;
      preview.addListener(() => notifications++);
      var diskAccesses = 0;
      await IOOverrides.runZoned(
        () async {
          preview.waterAnimated = true;
          expect(
            (preview.waterAnimated, preview.windowsLit, preview.fireflies),
            (true, false, false),
          );
          preview.windowsLit = true;
          expect(
            (preview.waterAnimated, preview.windowsLit, preview.fireflies),
            (true, true, false),
          );
          preview.fireflies = true;
          expect(
            (preview.waterAnimated, preview.windowsLit, preview.fireflies),
            (true, true, true),
          );
          expect(notifications, 3);
          preview.windowsLit = false;
          preview.waterAnimated = false;
          preview.fireflies = false;
        },
        createFile: (path) {
          diskAccesses++;
          throw StateError(path);
        },
        createDirectory: (path) {
          diskAccesses++;
          throw StateError(path);
        },
        createLink: (path) {
          diskAccesses++;
          throw StateError(path);
        },
      );
      expect(diskAccesses, 0);
      expect(notifications, 6);
      expect(document.current, same(map));
      expect(document.dirty, isFalse);
      expect(document.undoCount, 0);
      final second = SpatialSceneController();
      addTearDown(second.dispose);
      expect(
        (second.waterAnimated, second.windowsLit, second.fireflies),
        (false, false, false),
      );
    },
  );

  test(
    'atmosphere preview exposes missing targets without editing the map',
    () {
      final map = spatialEnvironmentMap();
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: map.id, revision: 'atmosphere'),
      );
      final preview = SpatialSceneController();
      addTearDown(preview.dispose);
      expect(preview.atmosphereAvailability.water, isFalse);
      expect(preview.atmosphereAvailability.windows, isFalse);
      expect(preview.atmosphereAvailability.fireflies, isFalse);
      expect(document.current, same(map));
      expect(document.dirty, isFalse);
      expect(document.undoCount, 0);
    },
  );

  test(
    'canonical lamp values reject invalid radius and preserve the source model',
    () {
      final model = spatialEnvironmentProject().models3d.single;
      final before = model.toJson();
      final light = Model3dPointLight(
        localPosition: Model3dVector3.zero,
        radius: 5.5,
      );
      for (final invalid in [-1, 0, .1, 64.1]) {
        expect(
          () => ProjectModel3dEntry.fromJson({
            ...before,
            'light': {...light.toJson(), 'radius': invalid},
          }),
          throwsFormatException,
        );
      }
      final updated = ProjectModel3dEntry.fromJson({
        ...before,
        'light': light.toJson(),
      });
      expect(updated.light!.radius, 5.5);
      expect(ProjectModel3dEntry.fromJson(updated.toJson()), updated);
      expect(model.toJson(), before);
    },
  );

  test('a light draft saves and removes a local emitter', () async {
    Model3dPointLight? saved;
    var saves = 0;
    final draft = ModelLightDraft(spatialEnvironmentProject().models3d.single);
    addTearDown(draft.dispose);
    expect(draft.enabled, isFalse);
    draft.enabled = true;
    draft.values[3] = '5.5';
    Future<void> publish(Model3dPointLight? value) async {
      saved = value;
      saves++;
    }

    expect(await draft.save(publish, canSave: () => true), isTrue);
    expect(saves, 1);
    expect(saved!.radius, 5.5);
    expect(saved!.nightOnly, isTrue);
    expect(saved!.colorRgb, 0xffd59a);
    draft.enabled = false;
    expect(await draft.save(publish, canSave: () => true), isTrue);
    expect(saves, 2);
    expect(saved, isNull);
  });

  test('cycle editing is undoable while preview leaves the map unchanged', () {
    final map = spatialEnvironmentMap();
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'cycle'),
    );
    final preview = SpatialSceneController();
    addTearDown(preview.dispose);
    final commands = MapSpatialSettingsCommands(document);
    expect(document.current.spatialScene!.dayNightCycle, isNull);
    expect(commands.dayNight(SpatialDayNightCycle()), isTrue);
    expect(document.undoCount, 1);
    final saved = document.current;
    preview.previewMinuteOfDay = 1320;
    expect(preview.previewMinuteOfDay, 1320);
    expect(document.current, same(saved));
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(document.current.spatialScene!.dayNightCycle, isNull);
    document.restore(redo: true);
    expect(document.current.spatialScene!.dayNightCycle, isNotNull);
  });
}
