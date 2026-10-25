import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';

import 'dart:collection';

import 'package:avelune_studio/features/map_workspace/application/map_atmosphere_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_atmosphere_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_atmosphere_settings_panel.dart';
import 'package:flutter/material.dart';
import 'package:avelune_design_system/avelune_design_system.dart'
    show StudioAccent, StudioToggleRow;
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_toolbar.dart';

import '../support/map_workspace_fixture.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../support/spatial_environment_fixture.dart';

void main() {
  testWidgets(
    'first and repeated depth of field UI saves use only the atmosphere sidecar',
    (tester) async {
      final root = await tester.runAsync(() async {
        final temporary = await Directory.systemTemp.createTemp('studio_dof_');
        final root = Directory(await temporary.resolveSymbolicLinks());
        await Directory('${root.path}/maps').create();
        final project = ProjectManifest(
          name: 'DOF',
          version: ProjectVersion.v9,
          settings: const ProjectSettings(dimension: ProjectDimension.threeD),
          maps: [
            const ProjectMapEntry(
              id: 'a',
              name: 'A',
              relativePath: 'maps/a.json',
            ),
          ],
          tilesets: [],
        );
        await File('${root.path}/project.json')
            .writeAsString(jsonEncode(project.toJson()));
        await File('${root.path}/maps/a.json')
            .writeAsString(jsonEncode(spatialEnvironmentMap().toJson()));
        for (final relative in [
          'maps/unrelated.json',
          '.pokemap/authoring/history.jsonl',
        ]) {
          final file = File('${root.path}/$relative');
          await file.parent.create(recursive: true);
          await file.writeAsString('x' * 2000000);
        }
        return root;
      });
      addTearDown(() => root!.delete(recursive: true));
      final session = ProjectSession(
        sessionId: root!.path,
        name: 'DOF',
        directoryPath: root.path,
      );
      final adapter = LocalMapWorkspaceAdapter();
      final controller = await tester.runAsync(() async {
        final project = await adapter.loadProject(session);
        await adapter.loadMap(session, project.maps.single);
        return MapAtmosphereController.open(session, 'a', adapter);
      });
      addTearDown(controller!.dispose);
      await tester.binding.setSurfaceSize(const Size(900, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MapAtmosphereSettingsPanel(
                controller: controller,
                map: spatialEnvironmentMap(),
              ),
            ),
          ),
        ),
      );
      final outside = Zone.current;
      final denied = <String>[];
      await IOOverrides.runZoned(
        () async {
          for (final enabled in [true, false]) {
            final toggle = find.byKey(const ValueKey('atmosphere-dof-enabled'));
            await tester.ensureVisible(toggle);
            await tester.tap(toggle);
            await tester.pump(const Duration(milliseconds: 16));
            expect(controller.current.depthOfFieldEnabled, enabled);
            expect(controller.dirty, isTrue);
            expect(await tester.runAsync(controller.save), isTrue);
            await tester.pump();
            expect(controller.dirty, isFalse);
            final persisted = await tester.runAsync(
              () => adapter.loadAtmosphere(session, 'a'),
            );
            expect(persisted!.settings.depthOfFieldEnabled, enabled);
            expect(persisted.settings.depthOfFieldStrength, .35);
            expect(persisted.settings.depthOfFieldFocusRange, 12);
          }
        },
        createFile: (path) {
          final file = outside.run(() => File(path));
          final relative = path.startsWith('${root.path}/')
              ? path.substring(root.path.length + 1)
              : '';
          return [
                'project.json',
                'maps/a.json',
                'maps/unrelated.json',
                '.pokemap/authoring/history.jsonl',
              ].contains(relative)
              ? _GuardedStoredFile(file, denied)
              : file;
        },
      );
      expect(denied, isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'depth of field edits locally and saves the selected atmosphere once',
    (tester) async {
      final port = _Port();
      final controller = await MapAtmosphereController.open(
        _session,
        'river',
        port,
      );
      addTearDown(controller.dispose);
      await tester.binding.setSurfaceSize(const Size(900, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final unrelated = _GuardList<ProjectTilesetEntry>(
        spatialEnvironmentProject().tilesets,
      );
      unrelated.forbidden = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MapAtmosphereSettingsPanel(
                controller: controller,
                map: spatialEnvironmentMap(),
                project: spatialEnvironmentProject().copyWith(
                  tilesets: unrelated,
                ),
              ),
            ),
          ),
        ),
      );
      final toggle = find.byKey(const ValueKey('atmosphere-dof-enabled'));
      expect(toggle, findsOneWidget);
      await IOOverrides.runZoned(
        () async {
          await tester.ensureVisible(toggle);
          await tester.tap(toggle);
          await tester.pump(const Duration(milliseconds: 16));
          expect(controller.current.toJson()['depthOfFieldEnabled'], isTrue);
          for (final (id, text) in [
            ('dof-strength', '65'),
            ('dof-focus-range', '18'),
          ]) {
            final field = find.descendant(
              of: find.byKey(ValueKey('atmosphere-$id')),
              matching: find.byType(TextField),
            );
            await tester.ensureVisible(field);
            await tester.enterText(field, text);
            await tester.testTextInput.receiveAction(TextInputAction.done);
            await tester.pump(const Duration(milliseconds: 16));
          }
        },
        createFile: (path) => throw StateError('Unexpected disk: $path'),
        createDirectory: (path) => throw StateError('Unexpected disk: $path'),
      );
      expect(controller.current.toJson()['depthOfFieldStrength'], .65);
      expect(controller.current.toJson()['depthOfFieldFocusRange'], 18);
      final focusField = find.descendant(
        of: find.byKey(const ValueKey('atmosphere-dof-focus-range')),
        matching: find.byType(TextField),
      );
      await tester.enterText(focusField, '1');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(controller.current.depthOfFieldFocusRange, 18);
      expect(controller.error, contains('2.0 et 40.0'));
      expect(port.writes, 0);
      expect(unrelated.reads, 0);
      await tester.ensureVisible(find.byKey(const ValueKey('atmosphere-save')));
      await tester.tap(find.byKey(const ValueKey('atmosphere-save')));
      await tester.pump();
      expect(port.writes, 1);
      expect(controller.dirty, isFalse);
      controller.undo();
      expect(controller.current.toJson()['depthOfFieldFocusRange'], 12);
      controller.redo();
      expect(controller.current.toJson()['depthOfFieldFocusRange'], 18);
    },
  );

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
      unrelated.forbidden = true;
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
      final accents = <StudioAccent>{};
      for (final id in ['water', 'windows', 'fireflies', 'halos', 'fog']) {
        final toggle = tester.widget<StudioToggleRow>(
          find.byKey(ValueKey('atmosphere-$id-enabled')),
        );
        expect(toggle.icon, isNotNull);
        accents.add(toggle.accent!);
      }
      expect(accents.length, 5);
      expect(unrelated.reads, 0);
      unrelated.forbidden = true;
      await IOOverrides.runZoned(
        () async {
          for (final id in ['water', 'windows', 'fireflies', 'halos', 'fog']) {
            await tester.ensureVisible(
              find.byKey(ValueKey('atmosphere-$id-enabled')),
            );
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
      expect(preview.halosEnabled, isTrue);
      expect(preview.depthFogEnabled, isTrue);
      expect(controller.dirty, isTrue);
      expect(port.writes, 0);
      await tester.ensureVisible(find.byKey(const ValueKey('atmosphere-save')));
      await tester.tap(find.byKey(const ValueKey('atmosphere-save')));
      await tester.pump();
      expect(port.writes, 1);
      expect(controller.dirty, isFalse);
      expect(find.text('Ambiance enregistrée'), findsOneWidget);
      controller.undo();
      await tester.pump();
      expect(preview.depthFogEnabled, isFalse);
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
      halos: [
        SpatialAtmosphereHalo(
          instanceId: 'lamp',
          localPosition: Model3dVector3(x: 0, y: 2, z: 0),
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

class _GuardedStoredFile implements File {
  _GuardedStoredFile(this.file, this.denied);
  final File file;
  final List<String> denied;
  Never reject() {
    denied.add(file.path);
    throw StateError('Unrelated document IO: ${file.path}');
  }

  @override
  String get path => file.path;
  @override
  Future<bool> exists() => file.exists();
  @override
  Future<FileStat> stat() => file.stat();
  @override
  Future<String> resolveSymbolicLinks() => file.resolveSymbolicLinks();
  @override
  Future<Uint8List> readAsBytes() async => reject();
  @override
  Future<String> readAsString({Encoding encoding = utf8}) async => reject();
  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) async =>
      reject();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
