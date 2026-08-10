import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/character_studio_authoring_gateway.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/use_cases/character_use_cases.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Character Studio canonical editor adapter', () {
    test(
      'legacy editor use cases persist only through semantic actions',
      () async {
        final fixture = await _CharacterStudioFixture.create();
        addTearDown(fixture.dispose);

        final created = await CreateCharacterUseCase(fixture.gateway).execute(
          fixture.workspace,
          fixture.project,
          name: 'Élia',
          tilesetId: 'characters',
          frameWidth: 4,
          frameHeight: 8,
        );
        expect(
          fixture.mutations.lastAppliedReceipt?.actionId,
          'characterStudio.character.create',
        );
        expect(created.characters.single.id, 'elia');

        final playable = await SetPlayerCharacterUseCase(
          fixture.gateway,
        ).execute(fixture.workspace, created, characterId: 'elia');
        expect(
          fixture.mutations.lastAppliedReceipt?.actionId,
          'characterStudio.character.setDefault',
        );
        expect(playable.settings.defaultPlayerCharacterId, 'elia');

        final animated = await UpsertCharacterAnimationUseCase(fixture.gateway)
            .execute(
              fixture.workspace,
              playable,
              characterId: 'elia',
              animState: CharacterAnimationState.idle,
              direction: EntityFacing.south,
              frames: const <CharacterAnimationFrame>[
                CharacterAnimationFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 4, height: 8),
                  durationMs: 120,
                ),
                CharacterAnimationFrame(
                  source: TilesetSourceRect(x: 4, y: 0, width: 4, height: 8),
                  durationMs: 90,
                ),
              ],
            );
        expect(
          fixture.mutations.lastAppliedReceipt?.actionId,
          'characterStudio.animationClip.upsert',
        );
        expect(
          animated.characters.single.animations.single.frames,
          hasLength(2),
        );

        final renamed = await UpdateCharacterUseCase(fixture.gateway).execute(
          fixture.workspace,
          animated,
          characterId: 'elia',
          name: 'Élia la Rouge',
          tags: const <String>['heroine'],
        );
        expect(renamed.characters.single.name, 'Élia la Rouge');
        expect(
          renamed.characters.single.animations.single.frames,
          hasLength(2),
        );

        final deletePlan = await PreviewDeleteCharacterUseCase(
          fixture.gateway,
        ).execute(fixture.workspace, renamed, characterId: 'elia');
        expect(deletePlan.requiresResolution, isTrue);
        expect(deletePlan.dependencies, isNotEmpty);

        final deleted = await DeleteCharacterUseCase(
          fixture.gateway,
        ).execute(fixture.workspace, renamed, characterId: 'elia');
        expect(
          fixture.mutations.lastAppliedReceipt?.actionId,
          'characterStudio.character.delete',
        );
        expect(deleted.characters, isEmpty);
        expect(deleted.settings.defaultPlayerCharacterId, isNull);

        final durable = await FileProjectRepository().loadProject(
          p.join(fixture.root.path, 'project.json'),
        );
        expect(durable, deleted);
      },
    );

    test('rejects a stale editor project without overwriting disk', () async {
      final fixture = await _CharacterStudioFixture.create();
      addTearDown(fixture.dispose);
      final external = fixture.project.copyWith(name: 'External edit');
      await FileProjectRepository().saveProject(
        external,
        p.join(fixture.root.path, 'project.json'),
      );

      await expectLater(
        CreateCharacterUseCase(fixture.gateway).execute(
          fixture.workspace,
          fixture.project,
          name: 'Élia',
          tilesetId: 'characters',
        ),
        throwsA(isA<EditorConflictException>()),
      );

      final durable = await FileProjectRepository().loadProject(
        p.join(fixture.root.path, 'project.json'),
      );
      expect(durable.name, 'External edit');
      expect(durable.characters, isEmpty);
    });
  });
}

final class _CharacterStudioFixture {
  _CharacterStudioFixture({
    required this.root,
    required this.project,
    required this.workspace,
    required this.queries,
    required this.mutations,
    required this.gateway,
  });

  static Future<_CharacterStudioFixture> create() async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_character_studio_editor_',
    );
    final project = ProjectManifest(
      name: 'Character Studio editor fixture',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'characters',
          name: 'Characters',
          relativePath: 'assets/characters.png',
        ),
      ],
      characterStudioCatalog: const ProjectCharacterStudioCatalog(
        portraitStates: <CharacterPortraitStateDefinition>[
          CharacterPortraitStateDefinition(
            id: 'neutral',
            displayName: 'Neutre',
          ),
        ],
      ),
    );
    await FileProjectRepository().saveProject(
      project,
      p.join(root.path, 'project.json'),
    );
    const reader = EditorProjectFileReader();
    final queries = AuthoringQueryAdapter(fileReader: reader);
    final mutations = AuthoringMutationAdapter(
      fileReader: reader,
      queries: queries,
      projectRoots: reader,
    );
    final gateway = CanonicalCharacterStudioAuthoringGateway(
      mutations: mutations,
      queries: queries,
    );
    return _CharacterStudioFixture(
      root: root,
      project: project,
      workspace: ProjectFileSystem(root.path),
      queries: queries,
      mutations: mutations,
      gateway: gateway,
    );
  }

  final Directory root;
  final ProjectManifest project;
  final ProjectFileSystem workspace;
  final AuthoringQueryAdapter queries;
  final AuthoringMutationAdapter mutations;
  final CanonicalCharacterStudioAuthoringGateway gateway;

  Future<void> dispose() async {
    await mutations.closeAll();
    await queries.closeAll();
    if (await root.exists()) await root.delete(recursive: true);
  }
}
