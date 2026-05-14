import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest shadow catalog operations', () {
    test('shadowCatalogForProject returns the manifest catalog', () {
      final catalog = _catalog('tree_large');
      final manifest = _manifest(shadowCatalog: catalog);

      expect(identical(shadowCatalogForProject(manifest), catalog), isTrue);
    });

    test('projectHasShadowProfiles reflects catalog emptiness', () {
      expect(projectHasShadowProfiles(_manifest()), isFalse);
      expect(
        projectHasShadowProfiles(
          _manifest(shadowCatalog: _catalog('tree_large')),
        ),
        isTrue,
      );
    });

    test('replaceProjectShadowCatalog replaces only shadowCatalog', () {
      final base = _manifest(
        name: 'KeepName',
        shadowCatalog: ProjectShadowCatalog(),
        elements: [_element(id: 'tree')],
        settings: const ProjectSettings(tileWidth: 99, tileHeight: 11),
        pokemon: const ProjectPokemonConfig(enabled: false),
      );
      final catalog = _catalog('tree_large');

      final updated = replaceProjectShadowCatalog(base, catalog);

      expect(updated.shadowCatalog, catalog);
      expect(updated.name, base.name);
      expect(updated.maps, base.maps);
      expect(updated.tilesets, base.tilesets);
      expect(updated.elements, base.elements);
      expect(updated.surfaceCatalog, base.surfaceCatalog);
      expect(updated.settings.tileWidth, 99);
      expect(updated.settings.tileHeight, 11);
      expect(updated.pokemon.enabled, isFalse);
    });

    test('updateProjectShadowCatalog receives current catalog once', () {
      final current = _catalog('tree_large');
      final replacement = _catalog('rock_small');
      ProjectShadowCatalog? received;
      var callCount = 0;

      final updated = updateProjectShadowCatalog(
        _manifest(shadowCatalog: current),
        (catalog) {
          callCount += 1;
          received = catalog;
          return replacement;
        },
      );

      expect(received, current);
      expect(callCount, 1);
      expect(updated.shadowCatalog, replacement);
    });

    test('updateProjectShadowCatalog propagates exceptions', () {
      expect(
        () => updateProjectShadowCatalog(
          _manifest(),
          (_) => throw StateError('boom'),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('clearProjectShadowCatalog yields an empty catalog', () {
      final cleared = clearProjectShadowCatalog(
        _manifest(shadowCatalog: _catalog('tree_large')),
      );

      expect(cleared.shadowCatalog.isEmpty, isTrue);
      expect(cleared.shadowCatalog, ProjectShadowCatalog());
    });

    test('operations preserve JSON roundtrip contract', () {
      final updated = replaceProjectShadowCatalog(
        _manifest(),
        _catalog('tree_large'),
      );

      final decoded = ProjectManifest.fromJson(
        jsonDecode(jsonEncode(updated.toJson())) as Map<String, dynamic>,
      );

      expect(decoded, updated);
    });

    test('adding shadowCatalog does not modify element collision data', () {
      const mask = ElementCollisionPixelMask(widthPx: 1, heightPx: 1);
      const collisionProfile = ElementCollisionProfile(
        visualMask: mask,
        collisionMask: mask,
        occlusionMask: mask,
        cells: <GridPos>[GridPos(x: 1, y: 2)],
      );
      final element = _element(
        id: 'tree',
        collisionProfile: collisionProfile,
      );
      final manifest = _manifest(elements: [element]);

      final updated = replaceProjectShadowCatalog(
        manifest,
        _catalog('tree_large'),
      );

      expect(updated.elements, manifest.elements);
      expect(updated.elements.single.collisionProfile, same(collisionProfile));
      expect(updated.elements.single.collisionProfile!.visualMask, same(mask));
      expect(
        updated.elements.single.collisionProfile!.collisionMask,
        same(mask),
      );
      expect(
        updated.elements.single.collisionProfile!.occlusionMask,
        same(mask),
      );
      expect(
        updated.elements.single.collisionProfile!.cells,
        const <GridPos>[GridPos(x: 1, y: 2)],
      );
    });
  });
}

ProjectManifest _manifest({
  String name = 'Project',
  ProjectShadowCatalog? shadowCatalog,
  List<ProjectElementEntry> elements = const [],
  ProjectSettings settings = const ProjectSettings(),
  ProjectPokemonConfig pokemon = const ProjectPokemonConfig(),
}) {
  return ProjectManifest(
    name: name,
    maps: const [],
    tilesets: const [],
    elements: elements,
    settings: settings,
    pokemon: pokemon,
    surfaceCatalog: ProjectSurfaceCatalog(),
    shadowCatalog: shadowCatalog ?? ProjectShadowCatalog(),
  );
}

ProjectShadowCatalog _catalog(String id) {
  return ProjectShadowCatalog(
    profiles: [
      ProjectShadowProfile(
        id: id,
        name: '$id shadow',
        mode: ShadowCasterMode.ellipse,
        renderPass: ShadowRenderPass.groundStatic,
      ),
    ],
  );
}

ProjectElementEntry _element({
  required String id,
  ElementCollisionProfile? collisionProfile,
}) {
  return ProjectElementEntry(
    id: id,
    name: id,
    tilesetId: 'tileset',
    categoryId: 'nature',
    frames: const [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0),
      ),
    ],
    collisionProfile: collisionProfile,
  );
}
