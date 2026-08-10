import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/dialogue_portrait_resolver.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';

void main() {
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
