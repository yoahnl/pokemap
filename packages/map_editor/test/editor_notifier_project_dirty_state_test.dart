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

    test('ensureDefaultShadowProfiles ajoute les defaults et marque dirty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final element = ProjectElementEntry(
        id: 'tree',
        name: 'Tree',
        tilesetId: 'tileset',
        categoryId: 'decor',
        frames: const [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
        shadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'missing',
        ),
      );
      notifier.state = notifier.state.copyWith(
        project: _manifest(name: 'Demo').copyWith(elements: [element]),
      );

      notifier.ensureDefaultShadowProfiles();

      expect(notifier.state.isProjectDirty, isTrue);
      expect(
        notifier.state.project!.shadowCatalog.profiles.map(
          (profile) => profile.id,
        ),
        [
          'default-ground-soft-ellipse',
          'default-ground-wide-ellipse',
          'default-ground-contact-blob',
        ],
      );
      expect(notifier.state.project!.elements, [element]);
      expect(
          notifier.state.project!.elements.single.shadow, same(element.shadow));
    });

    test('ensureDefaultShadowProfiles ne duplique pas à plusieurs appels', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state =
          notifier.state.copyWith(project: _manifest(name: 'Demo'));

      notifier.ensureDefaultShadowProfiles();
      notifier.ensureDefaultShadowProfiles();

      expect(notifier.state.project!.shadowCatalog.profileCount, 3);
      expect(
        notifier.state.project!.shadowCatalog.profiles.map(
          (profile) => profile.id,
        ),
        [
          'default-ground-soft-ellipse',
          'default-ground-wide-ellipse',
          'default-ground-contact-blob',
        ],
      );
    });

    test('applyElementAutoShadowSuggestions applique et sauvegarde', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('project_auto_shadow_apply_');
      addTearDown(() async => tempDir.delete(recursive: true));
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = notifier.state.copyWith(
        projectRootPath: tempDir.path,
        project: _manifestWithElements(
          elements: [
            _element(id: 'lamp', name: 'Lamp', width: 1, height: 4),
          ],
          shadowCatalog: _defaultShadowCatalog(),
        ),
      );

      await notifier.applyElementAutoShadowSuggestions();

      final updated = notifier.state.project!;
      expect(updated.elements.single.shadow, isNotNull);
      expect(
        updated.elements.single.shadow!.shadowProfileId,
        'default-ground-contact-blob',
      );
      expect(
        updated.elements.single.shadow!.footprint!.footprintWidthRatio,
        0.18,
      );
      expect(
        notifier.state.statusMessage,
        'Ombres automatiques mises à jour : 1 appliquée(s), 0 retirée(s).',
      );
      expect(notifier.state.errorMessage, isNull);
      final saved = ProjectManifest.fromJson(
        jsonDecode(
          await File('${tempDir.path}/project.json').readAsString(),
        ) as Map<String, dynamic>,
      );
      expect(saved.elements.single.shadow, updated.elements.single.shadow);
    });

    test('applyElementAutoShadowSuggestions annonce un no-op', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('project_auto_shadow_noop_');
      addTearDown(() async => tempDir.delete(recursive: true));
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final manualShadow = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'custom-ground-shadow',
      );
      final project = _manifestWithElements(
        elements: [
          _element(
            id: 'manual',
            name: 'Manual',
            width: 2,
            height: 2,
            shadow: manualShadow,
          ),
        ],
        shadowCatalog: ProjectShadowCatalog(
          profiles: [
            ...createDefaultGroundStaticShadowProfiles(),
            ProjectShadowProfile(
              id: 'custom-ground-shadow',
              name: 'Custom ground shadow',
              mode: ShadowCasterMode.ellipse,
              renderPass: ShadowRenderPass.groundStatic,
            ),
          ],
        ),
      );
      notifier.state = notifier.state.copyWith(
        projectRootPath: tempDir.path,
        project: project,
      );

      await notifier.applyElementAutoShadowSuggestions();

      expect(notifier.state.project, project);
      expect(
        notifier.state.statusMessage,
        'Aucune ombre automatique à appliquer.',
      );
      expect(notifier.state.errorMessage, isNull);
      expect(await File('${tempDir.path}/project.json').exists(), isFalse);
    });

    test('applyElementAutoShadowSuggestions annonce les nettoyages', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('project_auto_shadow_clear_');
      addTearDown(() async => tempDir.delete(recursive: true));
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = notifier.state.copyWith(
        projectRootPath: tempDir.path,
        project: _manifestWithElements(
          elements: [
            _element(
              id: 'small',
              name: 'Small',
              width: 2,
              height: 2,
              shadow: _oldAutoSmallSquareShadow(),
            ),
          ],
          shadowCatalog: _defaultShadowCatalog(),
        ),
      );

      await notifier.applyElementAutoShadowSuggestions();

      expect(notifier.state.project!.elements.single.shadow, isNull);
      expect(
        notifier.state.statusMessage,
        'Ombres automatiques mises à jour : 0 appliquée(s), 1 retirée(s).',
      );
      expect(notifier.state.errorMessage, isNull);
      final saved = ProjectManifest.fromJson(
        jsonDecode(
          await File('${tempDir.path}/project.json').readAsString(),
        ) as Map<String, dynamic>,
      );
      expect(saved.elements.single.shadow, isNull);
    });

    test('applyElementAutoShadowSuggestions ajoute les profils par défaut',
        () async {
      final tempDir = await Directory.systemTemp
          .createTemp('project_auto_shadow_defaults_');
      addTearDown(() async => tempDir.delete(recursive: true));
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = notifier.state.copyWith(
        projectRootPath: tempDir.path,
        project: _manifestWithElements(
          elements: [
            _element(id: 'lamp', name: 'Lamp', width: 1, height: 4),
          ],
          shadowCatalog: const ProjectShadowCatalog.empty(),
        ),
      );

      await notifier.applyElementAutoShadowSuggestions();

      expect(
        notifier.state.project!.shadowCatalog.profiles.map(
          (profile) => profile.id,
        ),
        [
          'default-ground-soft-ellipse',
          'default-ground-wide-ellipse',
          'default-ground-contact-blob',
        ],
      );
      expect(
        notifier.state.project!.elements.single.shadow!.shadowProfileId,
        'default-ground-contact-blob',
      );
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
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
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
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
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

ProjectManifest _manifestWithElements({
  required List<ProjectElementEntry> elements,
  required ProjectShadowCatalog shadowCatalog,
}) {
  return _manifest().copyWith(
    tilesets: const [
      ProjectTilesetEntry(
        id: 'tileset',
        name: 'Tileset',
        relativePath: 'tilesets/main.png',
      ),
    ],
    elementCategories: const [
      ProjectElementCategory(id: 'decor', name: 'Decor'),
    ],
    elements: elements,
    shadowCatalog: shadowCatalog,
  );
}

ProjectShadowCatalog _defaultShadowCatalog() {
  return ProjectShadowCatalog(
    profiles: createDefaultGroundStaticShadowProfiles(),
  );
}

ProjectElementEntry _element({
  required String id,
  required String name,
  required int width,
  required int height,
  ProjectElementShadowConfig? shadow,
}) {
  return ProjectElementEntry(
    id: id,
    name: name,
    tilesetId: 'tileset',
    categoryId: 'decor',
    frames: [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0, width: width, height: height),
      ),
    ],
    shadow: shadow,
  );
}

ProjectElementShadowConfig _oldAutoSmallSquareShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-contact-blob',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.78,
    scaleY: 0.70,
    opacity: 0.26,
    family: StaticShadowFamily.compactProp,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.96,
      footprintWidthRatio: 0.46,
      footprintHeightRatio: 0.10,
    ),
  );
}
