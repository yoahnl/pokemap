import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

const _canonicalMapRelativePaths = <String, String>{
  'map_bourg_selbrume': 'maps/map_bourg_selbrume.json',
  'map_port_brisants': 'maps/map_port_brisants.json',
  'map_bois_chaise_brume': 'maps/map_bois_chaise_brume.json',
  'map_marais_salants': 'maps/map_marais_salants.json',
  'map_passage_dames': 'maps/map_passage_dames.json',
  'map_phare_exterieur': 'maps/map_phare_exterieur.json',
  'map_phare_interieur': 'maps/map_phare_interieur.json',
  'map_sommet_phare': 'maps/map_sommet_phare.json',
  'map_cabane_gardien': 'maps/map_cabane_gardien.json',
  'map_maison_joueur': 'maps/map_maison_joueur.json',
};

final _fixtureRelativePaths = <String>[
  'project.json',
  ..._canonicalMapRelativePaths.values,
];

void main() {
  group('Selbrume editor file repositories round-trip', () {
    test(
      'loads, saves, and reloads the canonical manifest and all ten maps '
      'without semantic drift',
      () async {
        final sourceRoot = _resolveSelbrumeSourceRoot();
        final sourceSnapshot = await _snapshotFixtureFiles(sourceRoot);
        final fixture = await _copyRepositoryFixture(sourceRoot);
        _protectSourceAndDeleteFixtureAfterTest(
          sourceRoot: sourceRoot,
          sourceSnapshot: sourceSnapshot,
          fixture: fixture,
        );

        final projectRepository = FileProjectRepository();
        final mapRepository = FileMapRepository();
        final manifestPath = p.join(fixture.root.path, 'project.json');

        final loadedManifest =
            await projectRepository.loadProject(manifestPath);
        expect(
          {
            for (final entry in loadedManifest.maps)
              entry.id: entry.relativePath,
          },
          _canonicalMapRelativePaths,
        );

        final loadedMaps = await _loadCanonicalMaps(
          repository: mapRepository,
          fixtureRoot: fixture.root,
          manifest: loadedManifest,
        );
        expect(loadedMaps, hasLength(_canonicalMapRelativePaths.length));

        // Saving through the real repositories is the editor persistence
        // boundary Task 18 needs to prove. Assets are deliberately not copied:
        // these repositories own JSON validation/serialization and never read
        // referenced raster files while loading or saving a manifest or map.
        for (final entry in loadedManifest.maps) {
          await mapRepository.saveMap(
            loadedMaps[entry.id]!,
            p.join(fixture.root.path, entry.relativePath),
            projectDialogueContext: loadedManifest,
          );
        }
        await projectRepository.saveProject(loadedManifest, manifestPath);

        final reloadedManifest =
            await projectRepository.loadProject(manifestPath);
        final reloadedMaps = await _loadCanonicalMaps(
          repository: mapRepository,
          fixtureRoot: fixture.root,
          manifest: reloadedManifest,
        );

        // Freezed value equality compares the complete typed object graph, so
        // formatting-only JSON changes remain allowed while semantic loss is
        // rejected for both the manifest and every MapData instance.
        expect(reloadedManifest, loadedManifest);
        expect(reloadedMaps, loadedMaps);
        expect(await _snapshotFixtureFiles(sourceRoot), sourceSnapshot);
      },
    );

    test(
      'writes edited values only inside the disposable copy and leaves the '
      'workspace source byte-identical',
      () async {
        final sourceRoot = _resolveSelbrumeSourceRoot();
        final sourceSnapshot = await _snapshotFixtureFiles(sourceRoot);
        final fixture = await _copyRepositoryFixture(sourceRoot);
        _protectSourceAndDeleteFixtureAfterTest(
          sourceRoot: sourceRoot,
          sourceSnapshot: sourceSnapshot,
          fixture: fixture,
        );

        final projectRepository = FileProjectRepository();
        final mapRepository = FileMapRepository();
        final manifestPath = p.join(fixture.root.path, 'project.json');
        final manifest = await projectRepository.loadProject(manifestPath);
        final firstEntry = manifest.maps.singleWhere(
          (entry) => entry.id == 'map_bourg_selbrume',
        );
        final mapPath = p.join(fixture.root.path, firstEntry.relativePath);
        final map = await mapRepository.loadMap(mapPath);

        const temporaryProjectName = 'Selbrume - copie de test uniquement';
        const temporaryMapName = 'Bourg - copie de test uniquement';
        final editedManifest = manifest.copyWith(name: temporaryProjectName);
        final editedMap = map.copyWith(name: temporaryMapName);

        await projectRepository.saveProject(editedManifest, manifestPath);
        await mapRepository.saveMap(
          editedMap,
          mapPath,
          projectDialogueContext: editedManifest,
        );

        expect(
          (await projectRepository.loadProject(manifestPath)).name,
          temporaryProjectName,
        );
        expect((await mapRepository.loadMap(mapPath)).name, temporaryMapName);

        // This guard catches a future path-resolution regression that would
        // redirect editor saves from the fixture back into workspace Selbrume.
        expect(await _snapshotFixtureFiles(sourceRoot), sourceSnapshot);
        expect(
          (await projectRepository.loadProject(
            p.join(sourceRoot.path, 'project.json'),
          ))
              .name,
          isNot(temporaryProjectName),
        );
        expect(
          (await mapRepository.loadMap(
            p.join(sourceRoot.path, firstEntry.relativePath),
          ))
              .name,
          isNot(temporaryMapName),
        );
      },
    );
  });
}

Future<Map<String, MapData>> _loadCanonicalMaps({
  required FileMapRepository repository,
  required Directory fixtureRoot,
  required ProjectManifest manifest,
}) async {
  final maps = <String, MapData>{};
  for (final entry in manifest.maps) {
    final expectedRelativePath = _canonicalMapRelativePaths[entry.id];
    expect(expectedRelativePath, isNotNull,
        reason: 'Unexpected map ${entry.id}');
    expect(entry.relativePath, expectedRelativePath);

    final map = await repository.loadMap(
      p.join(fixtureRoot.path, entry.relativePath),
    );
    expect(map.id, entry.id);
    maps[entry.id] = map;
  }
  return maps;
}

Future<_SelbrumeFixture> _copyRepositoryFixture(Directory sourceRoot) async {
  final temporaryParent = await Directory.systemTemp.createTemp(
    'selbrume_editor_repository_roundtrip_',
  );
  final fixtureRoot = Directory(p.join(temporaryParent.path, 'selbrume'));

  // Copy only the files consumed by FileProjectRepository/FileMapRepository.
  // Keeping this fixture minimal makes the test fast without replacing the
  // production repositories with mocks or weakening the ten-map contract.
  for (final relativePath in _fixtureRelativePaths) {
    final source = File(p.join(sourceRoot.path, relativePath));
    if (!await source.exists()) {
      throw StateError('Missing Selbrume fixture file: ${source.path}');
    }
    final destination = File(p.join(fixtureRoot.path, relativePath));
    await destination.parent.create(recursive: true);
    await source.copy(destination.path);
  }

  return _SelbrumeFixture(
    root: fixtureRoot,
    temporaryParent: temporaryParent,
  );
}

void _protectSourceAndDeleteFixtureAfterTest({
  required Directory sourceRoot,
  required Map<String, List<int>> sourceSnapshot,
  required _SelbrumeFixture fixture,
}) {
  addTearDown(() async {
    // Run the source-integrity assertion even when an earlier expectation
    // fails, so a regression can never hide a write to workspace content.
    try {
      expect(await _snapshotFixtureFiles(sourceRoot), sourceSnapshot);
    } finally {
      if (await fixture.temporaryParent.exists()) {
        await fixture.temporaryParent.delete(recursive: true);
      }
    }
  });
}

Future<Map<String, List<int>>> _snapshotFixtureFiles(Directory root) async {
  return <String, List<int>>{
    for (final relativePath in _fixtureRelativePaths)
      relativePath: await File(p.join(root.path, relativePath)).readAsBytes(),
  };
}

Directory _resolveSelbrumeSourceRoot() {
  var candidate = Directory.current.absolute;
  while (true) {
    final projectFile =
        File(p.join(candidate.path, 'selbrume', 'project.json'));
    final editorPubspec =
        File(p.join(candidate.path, 'packages', 'map_editor', 'pubspec.yaml'));
    if (projectFile.existsSync() && editorPubspec.existsSync()) {
      return Directory(p.join(candidate.path, 'selbrume'));
    }

    final parent = candidate.parent;
    if (parent.path == candidate.path) {
      throw StateError(
        'Could not resolve repository root from ${Directory.current.path}',
      );
    }
    candidate = parent;
  }
}

final class _SelbrumeFixture {
  const _SelbrumeFixture({
    required this.root,
    required this.temporaryParent,
  });

  final Directory root;
  final Directory temporaryParent;
}
