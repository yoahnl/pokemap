import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/dialogue_portrait_resolver.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/runtime_project_catalog.dart';

void main() {
  for (final partitioned in [false, true]) {
    test(
      'hydrates off-map portrait speakers, partitioned=$partitioned',
      () async {
        final fixture = await _PortraitFixture.create();
        addTearDown(fixture.dispose);
        final project = fixture.manifest.copyWith(
          tilesets: const [
            ProjectTilesetEntry(
              id: 'elia-overworld',
              name: 'Missing overworld image',
              relativePath: 'never-open.png',
            ),
          ],
        );
        final projectFile = File('${fixture.root.path}/project.json');
        if (partitioned) {
          final publication = PortableCatalogPublication.encodeProject(project);
          await projectFile.writeAsString(jsonEncode(publication.descriptor));
          for (final object in publication.storage.objects.entries) {
            final file = File(
              '${fixture.root.path}/catalog/objects/${object.key}.json',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(object.value);
          }
        } else {
          await projectFile.writeAsString(jsonEncode(project.toJson()));
        }
        final catalog = await RuntimeProjectCatalog.open(projectFile.path);
        addTearDown(catalog.dispose);
        final view = await catalog.manifestForMap(
          MapData(
            id: 'empty',
            name: 'Empty',
            size: const GridSize(width: 1, height: 1),
          ),
        );
        expect(view.characters, isEmpty);
        final diagnostics = <DialoguePortraitResolutionDiagnostic>[];
        final resolver = DialoguePortraitResolver(
          manifest: view,
          projectRootDirectory: fixture.root.path,
          preloadLimit: 0,
          onDiagnostic: diagnostics.add,
        );
        await resolver.preload(
          DialogueSession.start([
            YarnNode(
              title: 'Start',
              steps: [
                YarnStepLine(
                  'Élia: Surprise.',
                  characterId: 'elia',
                  portraitStateId: 'surprised',
                ),
                YarnStepLine(
                  'Ghost: Bouh.',
                  characterId: 'unknown',
                  portraitStateId: 'surprised',
                ),
              ],
            ),
          ], 'Start')!,
        );
        expect(
          resolver
              .resolve(characterId: 'elia', portraitStateId: 'surprised')
              ?.absoluteFilePath,
          fixture.blob.path,
        );
        expect(
          resolver.resolve(
            characterId: 'unknown',
            portraitStateId: 'surprised',
          ),
          isNull,
        );
        expect(
          diagnostics.single.code,
          DialoguePortraitResolutionCode.characterUnknown,
        );
        final battleResolver = DialoguePortraitResolver(
          manifest: view,
          projectRootDirectory: fixture.root.path,
        );
        await battleResolver.ensureCatalogLoaded(characterIds: ['elia']);
        expect(
          battleResolver.resolve(
            characterId: 'elia',
            portraitStateId: 'surprised',
          ),
          isNotNull,
        );
        expect(
          await File('${fixture.root.path}/never-open.png').exists(),
          isFalse,
        );
        if (partitioned) {
          final broken = PortableCatalogPublication.encodeProject(
            project.copyWith(tilesets: const []),
          );
          await projectFile.writeAsString(jsonEncode(broken.descriptor));
          for (final object in broken.storage.objects.entries) {
            final file = File(
              '${fixture.root.path}/catalog/objects/${object.key}.json',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(object.value);
          }
          final brokenCatalog = await RuntimeProjectCatalog.open(
            projectFile.path,
          );
          addTearDown(brokenCatalog.dispose);
          final brokenResolver = DialoguePortraitResolver(
            manifest: brokenCatalog.projectMetadata,
            projectRootDirectory: fixture.root.path,
          );
          await expectLater(
            brokenResolver.ensureCatalogLoaded(characterIds: ['elia']),
            throwsA(
              isA<RuntimeCatalogDefinitionMissingException>().having(
                (error) => error.key,
                'key',
                CatalogDefinitionKey(
                  CatalogDefinitionKind.tileset,
                  'elia-overworld',
                ),
              ),
            ),
          );
        }
      },
    );
  }

  test(
    'hydrated definitions are bounded and reset with the dialogue',
    () async {
      final fixture = await _PortraitFixture.create();
      addTearDown(fixture.dispose);
      final project = fixture.manifest.copyWith(
        tilesets: const [
          ProjectTilesetEntry(
            id: 'elia-overworld',
            name: 'Overworld',
            relativePath: 'never-open.png',
          ),
        ],
        characters: [
          for (var i = 0; i < 65; i++)
            fixture.manifest.characters.single.copyWith(id: 'speaker-$i'),
        ],
      );
      final file = File('${fixture.root.path}/project.json');
      await file.writeAsString(jsonEncode(project.toJson()));
      final catalog = await RuntimeProjectCatalog.open(file.path);
      addTearDown(catalog.dispose);
      var injectedLoads = 0;
      final resolver = DialoguePortraitResolver(
        manifest: catalog.projectMetadata,
        projectRootDirectory: fixture.root.path,
        loadCatalog: (_) async {
          injectedLoads++;
          return catalog.loadAssetCatalog();
        },
      );
      await resolver.ensureCatalogLoaded(
        characterIds: List.generate(65, (i) => 'speaker-$i'),
      );
      expect(injectedLoads, 1);
      expect(
        resolver.resolve(
          characterId: 'speaker-0',
          portraitStateId: 'surprised',
        ),
        isNull,
      );
      expect(
        resolver.resolve(
          characterId: 'speaker-64',
          portraitStateId: 'surprised',
        ),
        isNotNull,
      );
      await resolver.preload(
        DialogueSession.start([
          YarnNode(title: 'Start', steps: [YarnStepLine('Hello')]),
        ], 'Start')!,
      );
      expect(
        resolver.resolve(
          characterId: 'speaker-64',
          portraitStateId: 'surprised',
        ),
        isNull,
      );
    },
  );

  test('resolves one authored portrait through the portable asset store',
      () async {
    final fixture = await _PortraitFixture.create();
    addTearDown(fixture.dispose);
    final diagnostics = <DialoguePortraitResolutionDiagnostic>[];
    final resolver = DialoguePortraitResolver(
      manifest: fixture.manifest,
      projectRootDirectory: fixture.root.path,
      onDiagnostic: diagnostics.add,
    );
    final session = DialogueSession.start(
      <YarnNode>[
        YarnNode(
          title: 'Start',
          steps: <YarnStep>[
            YarnStepLine(
              'Élia: Attends… tu as vu ça ?',
              characterId: 'elia',
              portraitStateId: 'surprised',
            ),
          ],
        ),
      ],
      'Start',
    )!;

    await resolver.preload(session);
    final portrait = resolver.resolve(
      characterId: 'elia',
      portraitStateId: 'surprised',
    );

    expect(portrait, isNotNull);
    expect(portrait!.characterName, 'Élia');
    expect(portrait.portraitStateName, 'Surprise');
    expect(portrait.assetId, 'portrait.elia.surprised');
    expect(portrait.fitMode, CharacterPortraitFitMode.cover);
    expect(portrait.absoluteFilePath, fixture.blob.path);
    expect(diagnostics, isEmpty);
  });

  test(
      'BETA-BAT-029 : ensureCatalogLoaded ouvre la résolution SANS dialogue '
      'préalable', () async {
    // La mise en scène du dresseur en combat résout un portrait, et ce
    // chemin n'est précédé d'aucun preload de dialogue : sans cette entrée,
    // resolve() rendait null et le repli portrait ne se voyait jamais.
    final fixture = await _PortraitFixture.create();
    addTearDown(fixture.dispose);
    final resolver = DialoguePortraitResolver(
      manifest: fixture.manifest,
      projectRootDirectory: fixture.root.path,
    );

    expect(
      resolver.resolve(characterId: 'elia', portraitStateId: 'surprised'),
      isNull,
      reason: 'catalogue non chargé : rien à résoudre',
    );

    await resolver.ensureCatalogLoaded();

    final portrait = resolver.resolve(
      characterId: 'elia',
      portraitStateId: 'surprised',
    );
    expect(portrait, isNotNull);
    expect(portrait!.absoluteFilePath, fixture.blob.path);
  });

  test('missing and dangling references diagnose then fall back to text',
      () async {
    final fixture = await _PortraitFixture.create(writeBlob: false);
    addTearDown(fixture.dispose);
    final diagnostics = <DialoguePortraitResolutionDiagnostic>[];
    final resolver = DialoguePortraitResolver(
      manifest: fixture.manifest,
      projectRootDirectory: fixture.root.path,
      onDiagnostic: diagnostics.add,
    );
    final session = DialogueSession.start(
      <YarnNode>[
        YarnNode(
          title: 'Start',
          steps: <YarnStep>[
            YarnStepLine(
              'Élia: Surprise.',
              characterId: 'elia',
              portraitStateId: 'surprised',
            ),
            YarnStepLine(
              'Fantôme: Bouh.',
              characterId: 'unknown',
              portraitStateId: 'surprised',
            ),
          ],
        ),
      ],
      'Start',
    )!;

    await resolver.preload(session);

    expect(
      resolver.resolve(
        characterId: 'elia',
        portraitStateId: 'surprised',
      ),
      isNull,
    );
    expect(
      resolver.resolve(
        characterId: 'unknown',
        portraitStateId: 'surprised',
      ),
      isNull,
    );
    expect(
      diagnostics.map((diagnostic) => diagnostic.code),
      containsAll(<DialoguePortraitResolutionCode>[
        DialoguePortraitResolutionCode.assetMissing,
        DialoguePortraitResolutionCode.characterUnknown,
      ]),
    );
  });

  test('cache stays bounded and avoids resolving the same file twice',
      () async {
    final fixture = await _PortraitFixture.create();
    addTearDown(fixture.dispose);
    var fileChecks = 0;
    final resolver = DialoguePortraitResolver(
      manifest: fixture.manifest,
      projectRootDirectory: fixture.root.path,
      cacheCapacity: 1,
      fileExists: (path) {
        fileChecks++;
        return File(path).existsSync();
      },
    );
    final session = DialogueSession.start(
      <YarnNode>[
        YarnNode(
          title: 'Start',
          steps: <YarnStep>[
            YarnStepLine(
              'Élia: Surprise.',
              characterId: 'elia',
              portraitStateId: 'surprised',
            ),
          ],
        ),
      ],
      'Start',
    )!;

    await resolver.preload(session);
    resolver.resolve(characterId: 'elia', portraitStateId: 'surprised');
    resolver.resolve(characterId: 'elia', portraitStateId: 'surprised');

    expect(fileChecks, 1);
    expect(resolver.cachedResolutionCount, 1);
  });

  test('legacy sessions do not load or diagnose a portrait catalog', () async {
    var catalogLoads = 0;
    final diagnostics = <DialoguePortraitResolutionDiagnostic>[];
    final resolver = DialoguePortraitResolver(
      manifest: const ProjectManifest(
        name: 'Legacy dialogue fixture',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      ),
      projectRootDirectory: Directory.systemTemp.path,
      loadCatalog: (_) async {
        catalogLoads++;
        return null;
      },
      onDiagnostic: diagnostics.add,
    );
    final session = DialogueSession.start(
      <YarnNode>[
        YarnNode(
          title: 'Start',
          steps: <YarnStep>[YarnStepLine('Guide: Bienvenue.')],
        ),
      ],
      'Start',
    )!;

    await resolver.preload(session);

    expect(catalogLoads, 0);
    expect(diagnostics, isEmpty);
  });
}

final class _PortraitFixture {
  const _PortraitFixture({
    required this.root,
    required this.blob,
    required this.manifest,
  });

  final Directory root;
  final File blob;
  final ProjectManifest manifest;

  static Future<_PortraitFixture> create({bool writeBlob = true}) async {
    final root = await Directory.systemTemp.createTemp('pokemap_portrait_');
    final artifact = ContentArtifactRef.fromBytes(
      const <int>[0x89, 0x50, 0x4e, 0x47],
      mediaType: 'image/png',
    );
    final record = AssetRecord(
      id: 'portrait.elia.surprised',
      logicalPath: 'assets/portraits/elia-surprised.png',
      artifact: artifact,
      tags: const <String>[
        'character-studio',
        'character-studio:portrait',
      ],
    );
    final catalog = AssetCatalog(records: <AssetRecord>[record]);
    final catalogFile = File('${root.path}/$assetCatalogStorageKey');
    await catalogFile.parent.create(recursive: true);
    await catalogFile.writeAsString(jsonEncode(catalog.toJson()));
    final blob = File('${root.path}/${assetBlobStorageKey(artifact)}');
    if (writeBlob) {
      await blob.parent.create(recursive: true);
      await blob.writeAsBytes(const <int>[0x89, 0x50, 0x4e, 0x47]);
    }
    return _PortraitFixture(
      root: root,
      blob: blob,
      manifest: const ProjectManifest(
        name: 'Portrait runtime fixture',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        characterStudioCatalog: ProjectCharacterStudioCatalog(
          portraitStates: <CharacterPortraitStateDefinition>[
            CharacterPortraitStateDefinition(
              id: 'surprised',
              displayName: 'Surprise',
            ),
          ],
        ),
        characters: <ProjectCharacterEntry>[
          ProjectCharacterEntry(
            id: 'elia',
            name: 'Élia',
            tilesetId: 'elia-overworld',
            portraits: <CharacterPortraitVariant>[
              CharacterPortraitVariant(
                portraitStateId: 'surprised',
                assetId: 'portrait.elia.surprised',
                fitMode: CharacterPortraitFitMode.cover,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> dispose() => root.delete(recursive: true);
}
