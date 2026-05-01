import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';

void main() {
  group('EditorNotifier project dirty state', () {
    test('isProjectDirty vaut false par défaut', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(editorNotifierProvider).isProjectDirty, isFalse);
    });

    test('applyInMemoryProjectManifest passe isProjectDirty à true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state =
          notifier.state.copyWith(project: _manifest(name: 'Demo'));

      notifier.applyInMemoryProjectManifest(_manifest(name: 'Demo updated'));

      expect(notifier.state.isProjectDirty, isTrue);
    });

    test('saveProjectManifest réussi repasse isProjectDirty à false', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('project_dirty_ok_');
      addTearDown(() async => tempDir.delete(recursive: true));
      final manifestPath = '${tempDir.path}/project.json';
      await File(manifestPath).writeAsString(jsonEncode(_manifest().toJson()));

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      await notifier.loadProject(manifestPath);

      notifier.applyInMemoryProjectManifest(_manifest(name: 'Dirty'));
      expect(notifier.state.isProjectDirty, isTrue);

      final saved = await notifier.saveProjectManifest();

      expect(saved, isTrue);
      expect(notifier.state.isProjectDirty, isFalse);
    });

    test('saveProjectManifest échoué conserve isProjectDirty à true', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state =
          notifier.state.copyWith(project: _manifest(name: 'Demo'));
      notifier.applyInMemoryProjectManifest(_manifest(name: 'Dirty'));

      final saved = await notifier.saveProjectManifest();

      expect(saved, isFalse);
      expect(notifier.state.isProjectDirty, isTrue);
    });

    test('chargement projet initialise isProjectDirty à false', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('project_dirty_load_');
      addTearDown(() async => tempDir.delete(recursive: true));
      final manifestPath = '${tempDir.path}/project.json';
      await File(manifestPath).writeAsString(jsonEncode(_manifest().toJson()));

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = notifier.state.copyWith(isProjectDirty: true);

      await notifier.loadProject(manifestPath);

      expect(notifier.state.isProjectDirty, isFalse);
    });

    test(
        'apply -> project dirty -> open map -> still dirty -> save project -> clean',
        () async {
      final tempDir =
          await Directory.systemTemp.createTemp('project_dirty_open_map_');
      addTearDown(() async => tempDir.delete(recursive: true));
      final manifestPath = '${tempDir.path}/project.json';
      final mapsDir = Directory('${tempDir.path}/maps');
      await mapsDir.create(recursive: true);
      await File('${mapsDir.path}/town.json')
          .writeAsString(jsonEncode(_mapData(id: 'town').toJson()));
      await File(manifestPath)
          .writeAsString(jsonEncode(_manifestWithMap().toJson()));

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);

      await notifier.loadProject(manifestPath);
      notifier.applyInMemoryProjectManifest(_manifestWithMap(name: 'Dirty'));
      expect(notifier.state.isProjectDirty, isTrue);

      await notifier.loadMap('maps/town.json');
      expect(notifier.state.isProjectDirty, isTrue);

      final saved = await notifier.saveProjectManifest();
      expect(saved, isTrue);
      expect(notifier.state.isProjectDirty, isFalse);
    });
  });
}

ProjectManifest _manifest({String name = 'Demo'}) {
  return ProjectManifest(
    name: name,
    maps: const [],
    tilesets: const [],
    pathPresets: const [],
    pathPatternPresets: const [],
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectManifest _manifestWithMap({String name = 'Demo'}) {
  return ProjectManifest(
    name: name,
    maps: const [
      ProjectMapEntry(
        id: 'town',
        name: 'Town',
        relativePath: 'maps/town.json',
      ),
    ],
    tilesets: const [],
    pathPresets: const [],
    pathPatternPresets: const [],
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

MapData _mapData({required String id}) {
  return MapData(
    id: id,
    name: 'Town',
    size: const GridSize(width: 8, height: 8),
    layers: const [],
  );
}
