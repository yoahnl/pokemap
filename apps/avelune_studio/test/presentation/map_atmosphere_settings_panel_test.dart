import 'package:avelune_studio/features/map_workspace/application/map_atmosphere_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_atmosphere_editing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';
import 'map_atmosphere_settings_panel_fakes.dart';

void main() {
  for (final kind in ['water', 'window', 'halo', 'firefly']) {
    test(
      'removing a $kind source preserves other settings and supports undo',
      () async {
        final port = AtmospherePanelPort();
        final controller = await MapAtmosphereController.open(
          atmosphereSession,
          'river',
          port,
        );
        addTearDown(controller.dispose);
        final editing = MapAtmosphereEditing(
          controller,
          spatialEnvironmentMap(),
          spatialEnvironmentProject(),
        );
        final before = controller.current;
        final remove = switch (kind) {
          'water' => editing.removeWater,
          'window' => editing.removeWindow,
          'halo' => editing.removeHalo,
          _ => editing.removeFireflyZone,
        };
        for (final invalid in [-1, 1]) {
          expect(remove(invalid), isFalse);
        }
        expect(controller.current, same(before));
        expect(controller.canUndo, isFalse);
        expect(remove(0), isTrue);
        final after = controller.current;
        expect(
          after.waterTargets,
          kind == 'water' ? isEmpty : before.waterTargets,
        );
        expect(after.windows, kind == 'window' ? isEmpty : before.windows);
        expect(after.halos, kind == 'halo' ? isEmpty : before.halos);
        expect(
          after.fireflyZones,
          kind == 'firefly' ? isEmpty : before.fireflyZones,
        );
        expect(
          after.copyWith(
            waterTargets: before.waterTargets,
            windows: before.windows,
            halos: before.halos,
            fireflyZones: before.fireflyZones,
          ),
          before,
        );
        expect(port.writes, 0);
        controller.undo();
        expect(controller.current, before);
        controller.redo();
        expect(controller.current, after);
        expect(await controller.save(), isTrue);
        expect(port.writes, 1);
        expect(controller.dirty, isFalse);
      },
    );
  }

  test(
    'zones enforce map bounds and ordering while preserving count and seed',
    () async {
      final controller = await MapAtmosphereController.open(
        atmosphereSession,
        'river',
        AtmospherePanelPort(),
      );
      addTearDown(controller.dispose);
      final map = spatialEnvironmentMap();
      final editing = MapAtmosphereEditing(controller, map, null);
      final original = controller.current.fireflyZones.single;
      expect(editing.zone(0, 'x', 'max', '3,5'), isTrue);
      expect(controller.current.fireflyZones.single.bounds.max.x, 3.5);
      expect(controller.current.fireflyZones.single.count, original.count);
      expect(controller.current.fireflyZones.single.seed, original.seed);
      final before = controller.current;
      for (final invalid in ['-1', '1000', 'NaN', '0']) {
        expect(editing.zone(0, 'x', 'max', invalid), isFalse);
      }
      expect(controller.current, same(before));
      controller.edit(controller.current.copyWith(fireflyZones: []));
      editing.addFireflyZone();
      expect(
        controller.current.fireflyZones.single.bounds.max,
        Model3dVector3(
          x: map.size.width.toDouble(),
          y: 2.2,
          z: map.size.height.toDouble(),
        ),
      );
    },
  );

  test(
    'halo coordinates preserve source shape and reject invalid positions',
    () async {
      final controller = await MapAtmosphereController.open(
        atmosphereSession,
        'river',
        AtmospherePanelPort(),
      );
      addTearDown(controller.dispose);
      final editing = MapAtmosphereEditing(
        controller,
        spatialEnvironmentMap(),
        spatialEnvironmentProject(),
      );
      final original = controller.current.halos.single;
      expect(editing.haloPosition(0, 'x', '-2,5'), isTrue);
      expect(controller.current.halos.single.localPosition.x, -2.5);
      editing.haloWindow(0, true);
      final changed = controller.current.halos.single;
      expect(changed.window, isTrue);
      expect(changed.radiusX, original.radiusX);
      expect(changed.radiusY, original.radiusY);
      expect(changed.opacity, original.opacity);
      expect(changed.colorRgb, original.colorRgb);
      final before = controller.current;
      for (final invalid in ['NaN', '100001', 'wrong']) {
        expect(editing.haloPosition(0, 'z', invalid), isFalse);
      }
      expect(controller.current, same(before));
      expect(editing.addHalo('missing'), isNull);
      expect(controller.current, same(before));
    },
  );

  test(
    'material targets deduplicate without replacing existing window masks',
    () async {
      final controller = await MapAtmosphereController.open(
        atmosphereSession,
        'river',
        AtmospherePanelPort(),
      );
      addTearDown(controller.dispose);
      final sourceMap = spatialEnvironmentMap();
      final map = sourceMap.copyWith(
        spatialScene: sourceMap.spatialScene!.copyWith(
          instances: [
            SpatialModelInstance(
              id: 'oak-instance',
              modelId: 'oak',
              position: Model3dVector3(x: 2.5, y: 0, z: 3.5),
            ),
          ],
        ),
      );
      final editing = MapAtmosphereEditing(
        controller,
        map,
        spatialEnvironmentProject(),
      );
      final before = controller.current;
      editing.addWater(before.waterTargets.single);
      editing.addWindow(before.windows.single.target);
      expect(controller.current, same(before));
      final target = SpatialAtmosphereMaterialTarget(
        instanceId: 'new-window',
        materialName: 'glass',
      );
      editing.addWindow(target);
      expect(controller.current.windows.first, before.windows.first);
      expect(
        controller.current.windows.last.uvRects.single.toJson(),
        SpatialAtmosphereUvRect(left: 0, top: 0, right: 1, bottom: 1).toJson(),
      );
      final source = editing.haloChoices.entries.first;
      final index = editing.addHalo(source.key);
      expect(index, before.halos.length);
      expect(controller.current.halos.last.localPosition, source.value.$2);
      controller.edit(
        controller.current.copyWith(
          halos: List.generate(
            32,
            (_) => SpatialAtmosphereHalo(
              instanceId: source.key,
              localPosition: source.value.$2,
            ),
          ),
        ),
      );
      expect(editing.addHalo(source.key), isNull);
      expect(controller.error, contains('32 halos'));
    },
  );
}
