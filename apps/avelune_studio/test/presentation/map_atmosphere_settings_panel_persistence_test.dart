import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:collection';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_atmosphere_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_atmosphere_editing.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';
import 'map_atmosphere_settings_panel_fakes.dart';

void main() {
  test(
    'first and repeated depth of field saves use only atmosphere sidecar',
    () async {
      final qa = Directory(
        '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109/t01-map-retirement',
      );
      await qa.create(recursive: true);
      final root = await qa.createTemp('atmosphere-');
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
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
      final session = ProjectSession(
        sessionId: root.path,
        name: 'DOF',
        directoryPath: root.path,
      );
      final adapter = LocalMapWorkspaceAdapter();
      final loaded = await adapter.loadProject(session);
      await adapter.loadMap(session, loaded.maps.single);
      final controller = await MapAtmosphereController.open(
        session,
        'a',
        adapter,
      );
      addTearDown(controller.dispose);
      final outside = Zone.current;
      final denied = <String>[];
      await IOOverrides.runZoned(
        () async {
          for (final enabled in [true, false]) {
            controller.edit(
              controller.current.copyWith(depthOfFieldEnabled: enabled),
            );
            expect(controller.dirty, isTrue);
            expect(await controller.save(), isTrue);
            expect(controller.dirty, isFalse);
            final persisted = await adapter.loadAtmosphere(session, 'a');
            expect(persisted.settings.depthOfFieldEnabled, enabled);
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
    },
  );

  test(
    'number edits stay local and never traverse unrelated materials',
    () async {
      final port = AtmospherePanelPort();
      final controller = await MapAtmosphereController.open(
        atmosphereSession,
        'river',
        port,
      );
      addTearDown(controller.dispose);
      final unrelated = _GuardList<ProjectTilesetEntry>(
        spatialEnvironmentProject().tilesets,
      )..forbidden = true;
      final editing = MapAtmosphereEditing(
        controller,
        spatialEnvironmentMap(),
        spatialEnvironmentProject().copyWith(tilesets: unrelated),
      );
      await IOOverrides.runZoned(
        () async {
          controller.edit(
            controller.current.copyWith(depthOfFieldEnabled: true),
          );
          expect(
            editing.number(
              'dof-strength',
              '65',
              0,
              100,
              (value) => controller.current.copyWith(
                depthOfFieldStrength: value / 100,
              ),
            ),
            isTrue,
          );
          expect(
            editing.number(
              'dof-focus-range',
              '18',
              2,
              40,
              (value) =>
                  controller.current.copyWith(depthOfFieldFocusRange: value),
            ),
            isTrue,
          );
        },
        createFile: (path) => throw StateError('Unexpected disk: $path'),
        createDirectory: (path) => throw StateError('Unexpected disk: $path'),
      );
      expect(controller.current.depthOfFieldEnabled, isTrue);
      expect(controller.current.depthOfFieldStrength, .65);
      expect(controller.current.depthOfFieldFocusRange, 18);
      final before = controller.current;
      for (final invalid in ['1', '41', 'NaN', 'Infinity', 'wrong']) {
        expect(
          editing.number(
            'dof-focus-range',
            invalid,
            2,
            40,
            (value) =>
                controller.current.copyWith(depthOfFieldFocusRange: value),
          ),
          isFalse,
        );
      }
      expect(controller.current, same(before));
      expect(port.writes, 0);
      expect(unrelated.reads, 0);
      expect(await controller.save(), isTrue);
      expect(port.writes, 1);
      expect(controller.dirty, isFalse);
      controller.undo();
      expect(controller.current.depthOfFieldFocusRange, 12);
      controller.redo();
      expect(controller.current.depthOfFieldFocusRange, 18);
    },
  );
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
