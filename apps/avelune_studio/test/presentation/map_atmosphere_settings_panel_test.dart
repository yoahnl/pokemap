import 'dart:io';
import 'dart:collection';

import 'package:avelune_studio/features/map_workspace/application/map_atmosphere_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_atmosphere_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_atmosphere_settings_panel.dart';
import 'package:flutter/material.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_toolbar.dart';

import '../support/map_workspace_fixture.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../support/spatial_environment_fixture.dart';

void main() {
  testWidgets(
    'toolbar updates only the atmosphere status without traversing map catalog',
    (tester) async {
      final atmosphere = await MapAtmosphereController.open(
        _session,
        'a',
        _Port(),
      );
      final workspace = MapWorkspaceController(_session, WorkspaceMemoryPort());
      addTearDown(workspace.dispose);
      await workspace.initialize();
      workspace.active!.atmosphere = atmosphere;
      final entries = _GuardList<ProjectMapEntry>(workspace.project!.maps);
      workspace.project = workspace.project!.copyWith(maps: entries);
      await tester.binding.setSurfaceSize(const Size(1200, 400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapWorkspaceToolbar(
              controller: workspace,
              view: null,
              onChanged: () {},
              onActivate: (_) {},
              onSave: () {},
              onTest: () {},
              onClose: () {},
              onPalette: () {},
              onInspector: () {},
              onNavigator: () {},
              paletteVisible: true,
              inspectorVisible: true,
              navigatorVisible: true,
            ),
          ),
        ),
      );
      expect(find.text('Enregistré'), findsOneWidget);
      entries.forbidden = true;
      atmosphere.edit(atmosphere.current.copyWith(waterAnimated: true));
      await tester.pump();
      expect(find.text('Non enregistré'), findsOneWidget);
      await atmosphere.save();
      await tester.pump();
      expect(find.text('Enregistré'), findsOneWidget);
    },
  );

  testWidgets(
    'durable effects preview in one frame without IO then save once',
    (tester) async {
      final port = _Port();
      final controller = await MapAtmosphereController.open(
        _session,
        'river',
        port,
      );
      final preview = SpatialSceneController();
      addTearDown(controller.dispose);
      addTearDown(preview.dispose);
      await tester.binding.setSurfaceSize(const Size(900, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final unrelated = _GuardList<ProjectTilesetEntry>(
        List.generate(
          240,
          (i) => ProjectTilesetEntry(
            id: 'unrelated-$i',
            name: 'Unrelated $i',
            relativePath: '$i.png',
          ),
        ),
      );
      final project = spatialEnvironmentProject().copyWith(tilesets: unrelated);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MapAtmosphereSettingsPanel(
                controller: controller,
                preview: preview,
                map: spatialEnvironmentMap(),
                project: project,
              ),
            ),
          ),
        ),
      );
      expect(unrelated.reads, greaterThan(0));
      unrelated.forbidden = true;
      await IOOverrides.runZoned(
        () async {
          for (final id in ['water', 'windows', 'fireflies']) {
            await tester.tap(find.byKey(ValueKey('atmosphere-$id-enabled')));
            await tester.pump(const Duration(milliseconds: 16));
          }
        },
        createFile: (path) => throw StateError('Unexpected disk: $path'),
        createDirectory: (path) => throw StateError('Unexpected disk: $path'),
      );
      expect(preview.waterAnimated, isTrue);
      expect(preview.windowsLit, isTrue);
      expect(preview.fireflies, isTrue);
      expect(controller.dirty, isTrue);
      expect(port.writes, 0);
      await tester.tap(find.byKey(const ValueKey('atmosphere-save')));
      await tester.pump();
      expect(port.writes, 1);
      expect(controller.dirty, isFalse);
      expect(find.text('Ambiance enregistrée'), findsOneWidget);
      controller.undo();
      await tester.pump();
      expect(preview.fireflies, isFalse);
    },
  );
}

const _session = ProjectSession(
  sessionId: 's',
  name: 'Copy',
  directoryPath: '/copy',
);

class _Port implements MapAtmospherePort {
  var writes = 0;
  @override
  Future<MapAtmosphereState> loadAtmosphere(
    ProjectSession session,
    String mapId,
  ) async => MapAtmosphereState(
    revision: 'r0',
    settings: SpatialAtmosphereSettings(
      waterTargets: [
        SpatialAtmosphereMaterialTarget(
          instanceId: 'river',
          materialName: 'water',
        ),
      ],
      windows: [
        SpatialAtmosphereWindow(
          target: SpatialAtmosphereMaterialTarget(
            instanceId: 'house',
            materialName: 'glass',
          ),
          uvRects: [
            SpatialAtmosphereUvRect(left: 0, top: 0, right: 1, bottom: 1),
          ],
        ),
      ],
      fireflyZones: [
        SpatialAtmosphereFireflyZone(
          bounds: Model3dBounds(
            min: Model3dVector3(x: 0, y: 0, z: 0),
            max: Model3dVector3(x: 2, y: 2, z: 2),
          ),
        ),
      ],
    ),
  );
  @override
  Future<MapAtmosphereState> saveAtmosphere(
    ProjectSession session,
    String mapId,
    SpatialAtmosphereSettings settings,
    String expectedRevision,
  ) async {
    writes++;
    return MapAtmosphereState(settings: settings, revision: 'r$writes');
  }
}

class _GuardList<T> extends ListBase<T> {
  _GuardList(this.values);
  final List<T> values;
  bool forbidden = false;
  int reads = 0;
  @override
  int get length {
    if (forbidden) {
      throw StateError('Unrelated library traversed during local edit');
    }
    reads++;
    return values.length;
  }

  @override
  set length(int value) => throw UnsupportedError('Read-only');
  @override
  T operator [](int index) {
    if (forbidden) {
      throw StateError('Unrelated library decoded during local edit');
    }
    reads++;
    return values[index];
  }

  @override
  void operator []=(int index, T value) => throw UnsupportedError('Read-only');
}
