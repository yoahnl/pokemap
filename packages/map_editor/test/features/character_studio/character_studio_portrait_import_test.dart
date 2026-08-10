import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/character_studio/application/character_studio_portrait_import_service.dart';

void main() {
  test(
    'portrait import stages, imports and assigns through canonical actions',
    () async {
      final gateway = _FakePortraitAssetGateway(
        staged: ContentArtifactRef.fromBytes(const <int>[
          1,
          2,
          3,
        ], mediaType: 'image/png'),
      );
      final project = _project();

      final result =
          await CharacterStudioPortraitImportService(gateway: gateway).import(
            projectRootPath: '/project',
            project: project,
            characterId: 'elia',
            portraitStateId: 'neutral',
            sourcePath: '/outside/elia.png',
            fitMode: CharacterPortraitFitMode.cover,
          );

      expect(gateway.stagedPath, '/outside/elia.png');
      expect(gateway.actions.map((entry) => entry.$1), <String>[
        'characterStudio.asset.import',
        'characterStudio.character.portrait.assign',
      ]);
      final assetParameters = gateway.actions.first.$2;
      final assignParameters = gateway.actions.last.$2;
      expect(assetParameters['artifactHandle'], gateway.staged.handle);
      expect(assetParameters['mediaKind'], 'portrait');
      expect(assignParameters['assetId'], assetParameters['assetId']);
      expect(assignParameters['fitMode'], 'cover');
      expect(result.characters.single.portraits.single.assetId, isNotEmpty);
    },
  );

  test('portrait replacement preserves its portable asset identity', () async {
    final gateway = _FakePortraitAssetGateway(
      staged: ContentArtifactRef.fromBytes(const <int>[
        4,
        5,
        6,
      ], mediaType: 'image/png'),
    );
    final project = _project(withPortrait: true);

    await CharacterStudioPortraitImportService(gateway: gateway).import(
      projectRootPath: '/project',
      project: project,
      characterId: 'elia',
      portraitStateId: 'neutral',
      sourcePath: '/outside/replacement.png',
      fitMode: CharacterPortraitFitMode.contain,
    );

    expect(gateway.actions.first.$1, 'characterStudio.asset.replace');
    expect(gateway.actions.first.$2['assetId'], 'elia-neutral');
    expect(gateway.actions.last.$2['assetId'], 'elia-neutral');
  });

  test('non PNG source is rejected before any project mutation', () async {
    final gateway = _FakePortraitAssetGateway(
      staged: ContentArtifactRef.fromBytes(const <int>[
        7,
        8,
        9,
      ], mediaType: 'text/plain'),
    );

    await expectLater(
      CharacterStudioPortraitImportService(gateway: gateway).import(
        projectRootPath: '/project',
        project: _project(),
        characterId: 'elia',
        portraitStateId: 'neutral',
        sourcePath: '/outside/not-png.txt',
        fitMode: CharacterPortraitFitMode.contain,
      ),
      throwsA(
        isA<CharacterStudioPortraitImportException>().having(
          (error) => error.code,
          'code',
          'character_studio.portrait_source_not_png',
        ),
      ),
    );
    expect(gateway.actions, isEmpty);
  });
}

final class _FakePortraitAssetGateway
    implements CharacterStudioPortraitAssetGateway {
  _FakePortraitAssetGateway({required this.staged});

  final ContentArtifactRef staged;
  final List<(String, Map<String, Object?>)> actions = [];
  String? stagedPath;

  @override
  Future<ContentArtifactRef> stageExactFile({
    required String projectRootPath,
    required String sourcePath,
  }) async {
    stagedPath = sourcePath;
    return staged;
  }

  @override
  Future<ProjectManifest> apply({
    required String projectRootPath,
    required ProjectManifest expectedProject,
    required String actionId,
    required Map<String, Object?> parameters,
    required String operationLabel,
  }) async {
    actions.add((actionId, parameters));
    if (actionId != 'characterStudio.character.portrait.assign') {
      return expectedProject;
    }
    final character = expectedProject.characters.single;
    return expectedProject.copyWith(
      characters: <ProjectCharacterEntry>[
        character.copyWith(
          portraits: <CharacterPortraitVariant>[
            CharacterPortraitVariant(
              portraitStateId: parameters['portraitStateId']! as String,
              assetId: parameters['assetId']! as String,
              fitMode: parameters['fitMode'] == 'cover'
                  ? CharacterPortraitFitMode.cover
                  : CharacterPortraitFitMode.contain,
            ),
          ],
        ),
      ],
    );
  }
}

ProjectManifest _project({bool withPortrait = false}) {
  return ProjectManifest(
    name: 'Portrait import',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    characterStudioCatalog: const ProjectCharacterStudioCatalog(
      portraitStates: <CharacterPortraitStateDefinition>[
        CharacterPortraitStateDefinition(id: 'neutral', displayName: 'Neutre'),
      ],
    ),
    characters: <ProjectCharacterEntry>[
      ProjectCharacterEntry(
        id: 'elia',
        name: 'Élia',
        tilesetId: 'elia',
        portraits: <CharacterPortraitVariant>[
          if (withPortrait)
            const CharacterPortraitVariant(
              portraitStateId: 'neutral',
              assetId: 'elia-neutral',
            ),
        ],
      ),
    ],
  );
}
