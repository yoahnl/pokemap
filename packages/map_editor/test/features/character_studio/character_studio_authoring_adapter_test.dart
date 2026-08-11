import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/character_studio_authoring_gateway.dart';
import 'package:map_editor/src/application/authoring_api/editor_receipt_presenter.dart';
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

    test('CHS-057 certifies every identity and portrait action', () async {
      final fixture = await _CharacterStudioFixture.create();
      addTearDown(fixture.dispose);
      var project = fixture.project;
      final observedActionIds = <String>{};
      var sequence = 0;

      Future<void> apply(
        String actionId,
        Map<String, Object?> parameters, {
        bool requiresConfirmation = false,
      }) async {
        project = await fixture.gateway.apply(
          projectRootPath: fixture.root.path,
          expectedProject: project,
          actionId: actionId,
          parameters: parameters,
          operationLabel: 'chs057_${sequence++}',
          requiresConfirmation: requiresConfirmation,
        );
        expect(fixture.mutations.lastAppliedReceipt?.actionId, actionId);
        observedActionIds.add(actionId);
      }

      Future<EditorAuthoringMutationPlan> preview(
        String actionId,
        Map<String, Object?> parameters,
      ) async {
        final plan = await fixture.gateway.preview(
          projectRootPath: fixture.root.path,
          expectedProject: project,
          actionId: actionId,
          parameters: parameters,
          operationLabel: 'chs057_preview_${sequence++}',
        );
        expect(plan.receipt.actionId, actionId);
        observedActionIds.add(actionId);
        return plan;
      }

      await apply(
        'characterStudio.portraitState.create',
        const <String, Object?>{'displayName': 'Joyeux'},
      );
      await apply(
        'characterStudio.portraitState.update',
        const <String, Object?>{'id': 'joyeux', 'displayName': 'Heureux'},
      );
      await apply(
        'characterStudio.portraitState.reorder',
        const <String, Object?>{
          'orderedIds': <String>['joyeux', 'neutral'],
        },
      );
      await apply('characterStudio.character.create', const <String, Object?>{
        'name': 'Élia',
        'tilesetId': 'characters',
        'frameWidth': 4,
        'frameHeight': 8,
      });
      await apply('characterStudio.character.update', const <String, Object?>{
        'characterId': 'elia',
        'name': 'Élia la Rouge',
        'tags': <String>['heroine'],
      });
      await apply(
        'characterStudio.character.setDefault',
        const <String, Object?>{'characterId': 'elia'},
      );
      await apply(
        'characterStudio.character.portrait.assign',
        const <String, Object?>{
          'characterId': 'elia',
          'portraitStateId': 'neutral',
          'assetId': 'elia-neutral',
          'fitMode': 'cover',
        },
      );
      await apply(
        'characterStudio.character.portrait.clear',
        const <String, Object?>{
          'characterId': 'elia',
          'portraitStateId': 'neutral',
        },
      );
      await apply(
        'characterStudio.character.portrait.assign',
        const <String, Object?>{
          'characterId': 'elia',
          'portraitStateId': 'neutral',
          'assetId': 'elia-neutral',
        },
      );
      final portraitDeletePlan = await preview(
        'characterStudio.portraitState.deletePlan',
        const <String, Object?>{'id': 'neutral'},
      );
      expect(portraitDeletePlan.preview['requiresResolution'], isTrue);
      await apply(
        'characterStudio.portraitState.delete',
        const <String, Object?>{
          'id': 'neutral',
          'resolution': 'replace',
          'replacementId': 'joyeux',
        },
        requiresConfirmation: true,
      );
      final characterDeletePlan = await preview(
        'characterStudio.character.deletePlan',
        const <String, Object?>{'characterId': 'elia'},
      );
      expect(characterDeletePlan.preview['requiresResolution'], isTrue);
      await apply('characterStudio.character.delete', const <String, Object?>{
        'characterId': 'elia',
        'resolution': 'clear',
      }, requiresConfirmation: true);

      expect(observedActionIds, _identityPortraitActionIds);
      final durable = await FileProjectRepository().loadProject(
        p.join(fixture.root.path, 'project.json'),
      );
      expect(durable.characters, isEmpty);
      expect(durable.settings.defaultPlayerCharacterId, isNull);
      expect(
        durable.characterStudioCatalog.portraitStates.single.displayName,
        'Heureux',
      );
    });

    test('CHS-058 certifies every animation frame and asset action', () async {
      final fixture = await _CharacterStudioFixture.create();
      addTearDown(fixture.dispose);
      final source = File(p.join(fixture.root.path, 'elia-sheet.png'));
      final replacement = File(
        p.join(fixture.root.path, 'elia-sheet-replacement.png'),
      );
      await source.writeAsBytes(_png(width: 64, height: 64));
      await replacement.writeAsBytes(_png(width: 32, height: 32, marker: 7));
      final stagedSource = await fixture.mutations.stageArtifact(
        fixture.root.path,
        sourcePath: source.path,
        declaredMediaType: 'image/png',
      );
      final stagedReplacement = await fixture.mutations.stageArtifact(
        fixture.root.path,
        sourcePath: replacement.path,
        declaredMediaType: 'image/png',
      );
      var project = fixture.project;
      final observedActionIds = <String>{};
      var sequence = 0;

      Future<void> apply(
        String actionId,
        Map<String, Object?> parameters, {
        bool requiresConfirmation = false,
        bool counted = true,
      }) async {
        project = await fixture.gateway.apply(
          projectRootPath: fixture.root.path,
          expectedProject: project,
          actionId: actionId,
          parameters: parameters,
          operationLabel: 'chs058_${sequence++}',
          requiresConfirmation: requiresConfirmation,
        );
        expect(fixture.mutations.lastAppliedReceipt?.actionId, actionId);
        if (counted) observedActionIds.add(actionId);
      }

      Future<EditorAuthoringMutationPlan> preview(
        String actionId,
        Map<String, Object?> parameters, {
        bool counted = true,
      }) async {
        final plan = await fixture.gateway.preview(
          projectRootPath: fixture.root.path,
          expectedProject: project,
          actionId: actionId,
          parameters: parameters,
          operationLabel: 'chs058_preview_${sequence++}',
        );
        expect(plan.receipt.actionId, actionId);
        if (counted) observedActionIds.add(actionId);
        return plan;
      }

      Future<void> expectFailure(
        String actionId,
        Map<String, Object?> parameters,
        String code,
      ) async {
        await expectLater(
          fixture.gateway.preview(
            projectRootPath: fixture.root.path,
            expectedProject: project,
            actionId: actionId,
            parameters: parameters,
            operationLabel: 'chs058_failure_${sequence++}',
          ),
          throwsA(
            isA<EditorAuthoringMutationFailure>().having(
              (failure) => failure.code,
              'code',
              code,
            ),
          ),
        );
        expect(
          await FileProjectRepository().loadProject(
            p.join(fixture.root.path, 'project.json'),
          ),
          project,
        );
      }

      await apply('characterStudio.character.create', const <String, Object?>{
        'name': 'Élia',
        'tilesetId': 'characters',
        'frameWidth': 8,
        'frameHeight': 8,
      }, counted: false);
      await apply('characterStudio.asset.import', <String, Object?>{
        'artifactHandle': stagedSource.reference.handle,
        'assetId': 'elia-sheet',
        'logicalPath': 'assets/characters/elia/sheet.png',
        'mediaKind': 'spriteSheet',
      });
      for (final definition in <Map<String, Object?>>[
        const <String, Object?>{'displayName': 'Saluer', 'mode': 'directional'},
        const <String, Object?>{'displayName': 'Cligner', 'mode': 'single'},
        const <String, Object?>{
          'displayName': 'Acclamer',
          'mode': 'directional',
        },
      ]) {
        await apply('characterStudio.animationDefinition.create', definition);
      }
      await apply(
        'characterStudio.animationDefinition.update',
        const <String, Object?>{'id': 'cligner', 'displayName': 'Cligner vite'},
      );
      await apply(
        'characterStudio.animationDefinition.reorder',
        const <String, Object?>{
          'orderedIds': <String>['cligner', 'acclamer', 'saluer'],
        },
      );
      await expectFailure(
        'characterStudio.animationClip.upsert',
        const <String, Object?>{
          'characterId': 'elia',
          'kind': 'custom',
          'definitionId': 'saluer',
          'sourceAssetId': 'elia-sheet',
        },
        'character_studio.animation.direction_required',
      );
      await apply(
        'characterStudio.animationClip.upsert',
        const <String, Object?>{
          'characterId': 'elia',
          'kind': 'custom',
          'definitionId': 'saluer',
          'direction': 'south',
          'sourceAssetId': 'elia-sheet',
          'loop': false,
          'frames': <Object?>[
            <String, Object?>{
              'source': <String, Object?>{
                'x': 0,
                'y': 0,
                'width': 8,
                'height': 8,
              },
              'durationMs': 100,
            },
            <String, Object?>{
              'source': <String, Object?>{
                'x': 8,
                'y': 0,
                'width': 8,
                'height': 8,
              },
              'durationMs': 110,
            },
          ],
        },
      );
      await apply(
        'characterStudio.animationClip.upsert',
        const <String, Object?>{
          'characterId': 'elia',
          'kind': 'custom',
          'definitionId': 'cligner',
          'sourceAssetId': 'elia-sheet',
          'frames': <Object?>[
            <String, Object?>{
              'source': <String, Object?>{
                'x': 0,
                'y': 8,
                'width': 8,
                'height': 8,
              },
              'durationMs': 90,
            },
          ],
        },
      );
      await expectFailure(
        'characterStudio.asset.replace',
        <String, Object?>{
          'artifactHandle': stagedReplacement.reference.handle,
          'assetId': 'elia-sheet',
          'sourceRect': <String, Object?>{
            'x': 0,
            'y': 0,
            'width': 33,
            'height': 32,
          },
        },
        'character_studio.asset.source_rect_out_of_bounds',
      );
      await apply('characterStudio.asset.replace', <String, Object?>{
        'artifactHandle': stagedReplacement.reference.handle,
        'assetId': 'elia-sheet',
      });
      await apply(
        'characterStudio.animationFrame.insert',
        const <String, Object?>{
          'characterId': 'elia',
          'kind': 'custom',
          'definitionId': 'saluer',
          'direction': 'south',
          'frameIndex': 1,
          'frame': <String, Object?>{
            'source': <String, Object?>{
              'x': 16,
              'y': 0,
              'width': 8,
              'height': 8,
            },
            'durationMs': 120,
          },
        },
      );
      await apply(
        'characterStudio.animationFrame.update',
        const <String, Object?>{
          'characterId': 'elia',
          'kind': 'custom',
          'definitionId': 'saluer',
          'direction': 'south',
          'frameIndex': 1,
          'frame': <String, Object?>{
            'source': <String, Object?>{
              'x': 16,
              'y': 0,
              'width': 8,
              'height': 8,
            },
            'durationMs': 130,
          },
        },
      );
      await apply(
        'characterStudio.animationFrame.reorder',
        const <String, Object?>{
          'characterId': 'elia',
          'kind': 'custom',
          'definitionId': 'saluer',
          'direction': 'south',
          'fromIndex': 1,
          'toIndex': 2,
        },
      );
      await expectFailure(
        'characterStudio.animationFrame.update',
        const <String, Object?>{
          'characterId': 'elia',
          'kind': 'custom',
          'definitionId': 'saluer',
          'direction': 'south',
          'frameIndex': 9,
          'frame': <String, Object?>{
            'source': <String, Object?>{
              'x': 0,
              'y': 0,
              'width': 8,
              'height': 8,
            },
            'durationMs': 100,
          },
        },
        'character_studio.animation.frame_index_invalid',
      );
      await apply(
        'characterStudio.animationFrame.delete',
        const <String, Object?>{
          'characterId': 'elia',
          'kind': 'custom',
          'definitionId': 'saluer',
          'direction': 'south',
          'frameIndex': 0,
        },
      );
      await apply(
        'characterStudio.animationClip.delete',
        const <String, Object?>{
          'characterId': 'elia',
          'kind': 'custom',
          'definitionId': 'cligner',
        },
      );
      final deletePlan = await preview(
        'characterStudio.animationDefinition.deletePlan',
        const <String, Object?>{'id': 'saluer'},
      );
      expect(deletePlan.preview['requiresResolution'], isTrue);
      await apply(
        'characterStudio.animationDefinition.delete',
        const <String, Object?>{
          'id': 'saluer',
          'resolution': 'replace',
          'replacementId': 'acclamer',
        },
        requiresConfirmation: true,
      );

      expect(observedActionIds, _animationActionIds);
      final durable = await FileProjectRepository().loadProject(
        p.join(fixture.root.path, 'project.json'),
      );
      final clip = durable.characters.single.customAnimations.single;
      expect(clip.definitionId, 'acclamer');
      expect(clip.direction, EntityFacing.south);
      expect(clip.frames, hasLength(2));
      final serializedProject = await File(
        p.join(fixture.root.path, 'project.json'),
      ).readAsString();
      final serializedAssets = await File(
        p.join(fixture.root.path, assetCatalogStorageKey),
      ).readAsString();
      expect(serializedProject, isNot(contains(fixture.root.path)));
      expect(serializedAssets, isNot(contains(fixture.root.path)));
    });
  });
}

const Set<String> _identityPortraitActionIds = <String>{
  'characterStudio.character.create',
  'characterStudio.character.update',
  'characterStudio.character.delete',
  'characterStudio.character.deletePlan',
  'characterStudio.character.setDefault',
  'characterStudio.character.portrait.assign',
  'characterStudio.character.portrait.clear',
  'characterStudio.portraitState.create',
  'characterStudio.portraitState.update',
  'characterStudio.portraitState.reorder',
  'characterStudio.portraitState.delete',
  'characterStudio.portraitState.deletePlan',
};

const Set<String> _animationActionIds = <String>{
  'characterStudio.animationDefinition.create',
  'characterStudio.animationDefinition.update',
  'characterStudio.animationDefinition.reorder',
  'characterStudio.animationDefinition.delete',
  'characterStudio.animationDefinition.deletePlan',
  'characterStudio.animationClip.upsert',
  'characterStudio.animationClip.delete',
  'characterStudio.animationFrame.insert',
  'characterStudio.animationFrame.update',
  'characterStudio.animationFrame.reorder',
  'characterStudio.animationFrame.delete',
  'characterStudio.asset.import',
  'characterStudio.asset.replace',
};

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

List<int> _png({required int width, required int height, int marker = 0}) {
  final bytes = List<int>.filled(24, 0);
  bytes.setRange(0, 8, const <int>[137, 80, 78, 71, 13, 10, 26, 10]);
  bytes[8] = marker;
  bytes.setRange(12, 16, const <int>[73, 72, 68, 82]);
  bytes.setRange(16, 20, _uint32(width));
  bytes.setRange(20, 24, _uint32(height));
  return bytes;
}

List<int> _uint32(int value) => <int>[
  (value >> 24) & 0xff,
  (value >> 16) & 0xff,
  (value >> 8) & 0xff,
  value & 0xff,
];
