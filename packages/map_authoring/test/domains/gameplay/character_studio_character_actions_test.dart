import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_source_fixture.dart' show sourcePng;

void main() {
  group('Character Studio character actions', () {
    test('deletion contracts expose disjoint strict schemas', () {
      final descriptors = CharacterStudioCharacterActions.descriptors;
      for (final id in ['deletePlan', 'delete']) {
        final descriptor =
            descriptors.singleWhere((value) => value.id.endsWith('.$id'));
        final schema = descriptor.extensions['inputSchema'] as Map?;
        expect(schema, isNotNull);
        expect(schema!['additionalProperties'], false);
        expect((schema['properties'] as Map).containsKey('resolution'),
            id == 'delete');
      }
    });

    test('inspection refuses missing maps instead of claiming no dependencies',
        () {
      expect(
          () => const CharacterStudioCharacterActions().build(_context(
                snapshot: characterActionSnapshot(missingMap: true),
                actionId: 'characterStudio.character.deletePlan',
                parameters: {'characterId': 'elia'},
                dryRun: true,
              )),
          throwsA(isA<CharacterStudioActionException>().having((e) => e.code,
              'code', 'character_studio.map_resource_unavailable')));
    });

    test('inspection refuses a missing required Yarn source', () {
      expect(
          () => const CharacterStudioCharacterActions().build(_context(
                snapshot: characterActionSnapshot(
                    dialogueSource: 'title: Start\n---\n===',
                    missingDialogue: true),
                actionId: 'characterStudio.character.deletePlan',
                parameters: {'characterId': 'elia'},
                dryRun: true,
              )),
          throwsA(isA<CharacterStudioActionException>().having((e) => e.code,
              'code', 'character_studio.dialogue_resource_unavailable')));
    });

    test('replacement refuses missing portrait used by a Yarn directive', () {
      expect(
          () => const CharacterStudioCharacterActions().build(_context(
                snapshot: characterActionSnapshot(
                    dialogueSource:
                        'title: Start\n---\n<<portrait elia neutral>>\nBonjour.\n===',
                    incompatibleReplacement: true),
                actionId: 'characterStudio.character.delete',
                parameters: {
                  'characterId': 'elia',
                  'resolution': 'replace',
                  'replacementId': 'nox'
                },
              )),
          throwsA(isA<CharacterStudioActionException>().having((e) => e.code,
              'code', 'character_studio.character.replacement_incompatible')));
    });

    test('clear refuses removal of configured playable default and last avatar',
        () {
      expect(
          () => const CharacterStudioCharacterActions().build(_context(
                snapshot: characterActionSnapshot(
                    withReferences: true, configuredPlayer: true),
                actionId: 'characterStudio.character.delete',
                parameters: {'characterId': 'elia', 'resolution': 'clear'},
              )),
          throwsA(isA<CharacterStudioActionException>().having((e) => e.code,
              'code', 'character_studio.character.player_required')));
    });

    test('inspection refuses invalid UTF-8 sources without loss', () {
      expect(
          () => const CharacterStudioCharacterActions().build(_context(
                snapshot: characterActionSnapshot(
                    dialogueSource: 'invalid', invalidDialogue: true),
                actionId: 'characterStudio.character.deletePlan',
                parameters: {'characterId': 'elia'},
                dryRun: true,
              )),
          throwsA(isA<CharacterStudioActionException>().having((e) => e.code,
              'code', 'character_studio.dialogue_source_not_utf8')));
    });

    test('replacement qualifies all configured player base directions', () {
      expect(
          () => const CharacterStudioCharacterActions().build(_context(
                snapshot: characterActionSnapshot(
                    withReferences: true, configuredPlayer: true),
                actionId: 'characterStudio.character.delete',
                parameters: {
                  'characterId': 'elia',
                  'resolution': 'replace',
                  'replacementId': 'nox'
                },
              )),
          throwsA(isA<CharacterStudioActionException>().having((e) => e.code,
              'code', 'character_studio.character.replacement_incompatible')));
      final draft = const CharacterStudioCharacterActions().build(_context(
        snapshot: characterActionSnapshot(
            withReferences: true,
            configuredPlayer: true,
            compatiblePlayer: true),
        actionId: 'characterStudio.character.delete',
        parameters: {
          'characterId': 'elia',
          'resolution': 'replace',
          'replacementId': 'nox'
        },
      ));
      expect(
          _projectedManifest(draft).settings.defaultPlayerCharacterId, 'nox');
      expect(
          _projectedManifest(draft).newGame.playerAvatarCharacterIds, ['nox']);
    });

    test('deletion preserves unknown nested project and map metadata', () {
      final snapshot =
          characterActionSnapshot(withReferences: true, rawMetadata: true);
      final draft = const CharacterStudioCharacterActions().build(_context(
        snapshot: snapshot,
        actionId: 'characterStudio.character.delete',
        parameters: {
          'characterId': 'elia',
          'resolution': 'replace',
          'replacementId': 'nox'
        },
      ));
      final project = jsonDecode(utf8.decode(draft.changeSet.changes
          .singleWhere((c) => c.resource.kind == 'project')
          .afterBytes!)) as Map;
      expect((project['characters'] as List).single['foreign'], {
        'keep': [1, 'été']
      });
      expect((project['tilesets'] as List).first['extensionData'],
          {'nested': true});
      final map = jsonDecode(utf8.decode(draft.changeSet.changes
          .singleWhere((c) => c.resource.kind == 'map')
          .afterBytes!)) as Map;
      expect(map['foreign'], {'root': true});
      expect((map['entities'] as List).first['foreign'], {'keep': 'unchanged'});
      expect((map['entities'] as List).first['npc']['foreign'],
          {'also': 'unchanged'});
    });

    test('replacement qualifies the custom clip used by a cinematic appearance',
        () {
      expect(
          () => const CharacterStudioCharacterActions().build(_context(
                snapshot: characterActionSnapshot(
                    withReferences: true, cinematicCommand: true),
                actionId: 'characterStudio.character.delete',
                parameters: {
                  'characterId': 'elia',
                  'resolution': 'replace',
                  'replacementId': 'nox'
                },
              )),
          throwsA(isA<CharacterStudioActionException>().having((e) => e.code,
              'code', 'character_studio.character.replacement_incompatible')));
      final draft = const CharacterStudioCharacterActions().build(_context(
        snapshot: characterActionSnapshot(
            withReferences: true, cinematicCommand: true, compatibleClip: true),
        actionId: 'characterStudio.character.delete',
        parameters: {
          'characterId': 'elia',
          'resolution': 'replace',
          'replacementId': 'nox'
        },
      ));
      expect(
          _projectedManifest(draft)
              .cinematics
              .single
              .stageContext!
              .actorAppearanceBindings
              .single
              .characterId,
          'nox');
    });

    test('clear refuses orphaning a required cinematic character animation',
        () {
      expect(
          () => const CharacterStudioCharacterActions().build(_context(
                snapshot: characterActionSnapshot(
                    withReferences: true, cinematicCommand: true),
                actionId: 'characterStudio.character.delete',
                parameters: {'characterId': 'elia', 'resolution': 'clear'},
              )),
          throwsA(isA<CharacterStudioActionException>().having((e) => e.code,
              'code', 'character_studio.character.clear_incompatible')));
    });

    test(
        'inspection refuses malformed portrait Yarn instead of claiming no usages',
        () {
      expect(
          () => const CharacterStudioCharacterActions().build(_context(
                snapshot: characterActionSnapshot(
                    dialogueSource:
                        'title: Start\n---\n<<portrait elia>>\nBonjour.\n==='),
                actionId: 'characterStudio.character.deletePlan',
                parameters: {'characterId': 'elia'},
                dryRun: true,
              )),
          throwsA(isA<CharacterStudioActionException>().having((e) => e.code,
              'code', 'character_studio.dialogue_compile_failed')));
    });

    test(
        'speaker directives are real character references and are resolved without changing text',
        () {
      final snapshot = characterActionSnapshot(
          dialogueSource:
              'title: Start\n---\n<<speaker elia>>\nelia reste du texte.\n===\n');
      final inspected = const CharacterStudioCharacterActions().build(_context(
          snapshot: snapshot,
          actionId: 'characterStudio.character.deletePlan',
          parameters: {'characterId': 'elia'},
          dryRun: true));
      expect(inspected.preview['dependencies'], hasLength(1));
      final replaced = const CharacterStudioCharacterActions().build(_context(
          snapshot: snapshot,
          actionId: 'characterStudio.character.delete',
          parameters: {
            'characterId': 'elia',
            'resolution': 'replace',
            'replacementId': 'nox'
          }));
      expect(_dialogueAfter(replaced), contains('<<speaker nox>>'));
      expect(_dialogueAfter(replaced), contains('elia reste du texte.'));
      final cleared = const CharacterStudioCharacterActions().build(_context(
          snapshot: snapshot,
          actionId: 'characterStudio.character.delete',
          parameters: {'characterId': 'elia', 'resolution': 'clear'}));
      expect(_dialogueAfter(cleared), isNot(contains('<<speaker')));
      expect(_dialogueAfter(cleared), contains('elia reste du texte.'));
    });

    test('registers every specialized character and portrait action', () {
      final ids = AuthoringMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();

      expect(
        ids,
        containsAll(<String>{
          'characterStudio.character.create',
          'characterStudio.character.update',
          'characterStudio.character.setDefault',
          'characterStudio.character.portrait.assign',
          'characterStudio.character.portrait.clear',
          'characterStudio.character.deletePlan',
          'characterStudio.character.delete',
        }),
      );
    });

    test('creates a unique identity with bounded dimensions and role tags', () {
      final draft = const CharacterStudioCharacterActions().build(
        _context(
          snapshot: characterActionSnapshot(),
          actionId: 'characterStudio.character.create',
          parameters: const <String, Object?>{
            'name': 'Élia',
            'tilesetId': 'characters',
            'frameWidth': 2,
            'frameHeight': 3,
            'tags': <String>['heroine', 'playable'],
          },
        ),
      );
      final created = _projectedManifest(draft).characters.last;

      expect(created.id, 'elia-2');
      expect(created.name, 'Élia');
      expect(created.frameWidth, 2);
      expect(created.frameHeight, 3);
      expect(created.tags, <String>['heroine', 'playable']);
      expect(draft.preview['characterId'], 'elia-2');
    });

    test('updates identity fields without rebuilding authored media slots', () {
      final before = characterActionSnapshot();
      final draft = const CharacterStudioCharacterActions().build(
        _context(
          snapshot: before,
          actionId: 'characterStudio.character.update',
          parameters: const <String, Object?>{
            'characterId': 'elia',
            'name': 'Élia de Bourg-Palette',
            'tags': <String>['heroine'],
          },
        ),
      );
      final character = _projectedManifest(draft).characters.firstWhere(
            (character) => character.id == 'elia',
          );
      final beforeCharacter = before.manifest.characters.firstWhere(
        (character) => character.id == 'elia',
      );

      expect(character.name, 'Élia de Bourg-Palette');
      expect(character.tags, <String>['heroine']);
      expect(character.portraits, beforeCharacter.portraits);
      expect(character.animations, beforeCharacter.animations);
      expect(character.customAnimations, beforeCharacter.customAnimations);
    });

    test('sets and clears the default player through a semantic slot', () {
      final setDraft = const CharacterStudioCharacterActions().build(
        _context(
          snapshot: characterActionSnapshot(),
          actionId: 'characterStudio.character.setDefault',
          parameters: const <String, Object?>{'characterId': 'elia'},
        ),
      );
      expect(
        _projectedManifest(setDraft).settings.defaultPlayerCharacterId,
        'elia',
      );

      final clearDraft = const CharacterStudioCharacterActions().build(
        _context(
          snapshot: characterActionSnapshot(defaultPlayerCharacterId: 'elia'),
          actionId: 'characterStudio.character.setDefault',
          parameters: const <String, Object?>{'characterId': null},
        ),
      );
      expect(
        _projectedManifest(clearDraft).settings.defaultPlayerCharacterId,
        isNull,
      );
    });

    test('assigns, replaces, and clears one portrait slot only', () {
      final assignDraft = const CharacterStudioCharacterActions().build(
        _context(
          snapshot: characterActionSnapshot(),
          actionId: 'characterStudio.character.portrait.assign',
          parameters: const <String, Object?>{
            'characterId': 'elia',
            'portraitStateId': 'sad',
            'assetId': 'elia-sad',
            'fitMode': 'cover',
          },
        ),
      );
      final assigned = _projectedManifest(assignDraft).characters.firstWhere(
            (character) => character.id == 'elia',
          );
      expect(assigned.portraits, hasLength(2));
      expect(assigned.portraits.last.assetId, 'elia-sad');
      expect(assigned.portraits.last.fitMode, CharacterPortraitFitMode.cover);

      final replaceDraft = const CharacterStudioCharacterActions().build(
        _context(
          snapshot: characterActionSnapshot(),
          actionId: 'characterStudio.character.portrait.assign',
          parameters: const <String, Object?>{
            'characterId': 'elia',
            'portraitStateId': 'neutral',
            'assetId': 'elia-neutral-v2',
          },
        ),
      );
      expect(
        _projectedManifest(replaceDraft)
            .characters
            .firstWhere((character) => character.id == 'elia')
            .portraits
            .single
            .assetId,
        'elia-neutral-v2',
      );

      final clearDraft = const CharacterStudioCharacterActions().build(
        _context(
          snapshot: characterActionSnapshot(),
          actionId: 'characterStudio.character.portrait.clear',
          parameters: const <String, Object?>{
            'characterId': 'elia',
            'portraitStateId': 'neutral',
          },
        ),
      );
      expect(
        _projectedManifest(clearDraft)
            .characters
            .firstWhere((character) => character.id == 'elia')
            .portraits,
        isEmpty,
      );
    });

    test('delete plan reports project and map dependencies in dry-run', () {
      final draft = const CharacterStudioCharacterActions().build(
        _context(
          snapshot: characterActionSnapshot(withReferences: true),
          actionId: 'characterStudio.character.deletePlan',
          parameters: const <String, Object?>{'characterId': 'elia'},
          dryRun: true,
        ),
      );
      final dependencies = draft.preview['dependencies']! as List<Object?>;
      final sourceKinds = dependencies
          .cast<Map<Object?, Object?>>()
          .map((dependency) => dependency['sourceKind'])
          .toSet();

      expect(draft.preview['requiresResolution'], isTrue);
      expect(draft.preview['choices'], <Object?>['replace', 'clear', 'cancel']);
      expect(
        sourceKinds,
        containsAll(<Object?>{
          'defaultPlayer',
          'newGameAvatar',
          'trainer',
          'cinematicAppearance',
          'mapNpc',
        }),
      );
      expect(draft.changeSet.changes, hasLength(1));
    });

    test('delete plan reports dialogue portrait dependencies', () {
      final draft = const CharacterStudioCharacterActions().build(
        _context(
          snapshot: characterActionSnapshot(
            dialogueSource: '''title: Start
---
<<portrait elia neutral>>
Élia: Bonjour.
===
''',
          ),
          actionId: 'characterStudio.character.deletePlan',
          parameters: const <String, Object?>{'characterId': 'elia'},
          dryRun: true,
        ),
      );
      final dependencies = draft.preview['dependencies']! as List<Object?>;

      expect(draft.preview['requiresResolution'], isTrue);
      expect(dependencies, hasLength(1));
      expect((dependencies.single! as Map)['sourceKind'], 'dialogue');
      expect((dependencies.single! as Map)['sourceId'], 'intro');
    });

    test('referenced deletion requires an explicit resolution', () {
      expect(
        () => const CharacterStudioCharacterActions().build(
          _context(
            snapshot: characterActionSnapshot(withReferences: true),
            actionId: 'characterStudio.character.delete',
            parameters: const <String, Object?>{'characterId': 'elia'},
          ),
        ),
        throwsA(
          isA<CharacterStudioActionException>().having(
            (error) => error.code,
            'code',
            'character_studio.character.resolution_required',
          ),
        ),
      );
    });

    test('clear deletion resolves every project and map reference atomically',
        () {
      final snapshot = characterActionSnapshot(withReferences: true);
      final draft = const CharacterStudioCharacterActions().build(
        _context(
          snapshot: snapshot,
          actionId: 'characterStudio.character.delete',
          parameters: const <String, Object?>{
            'characterId': 'elia',
            'resolution': 'clear',
          },
        ),
      );
      final manifest = _projectedManifest(draft);
      final map = _projectedMap(draft, 'village');

      expect(manifest.characters.map((character) => character.id), ['nox']);
      expect(manifest.settings.defaultPlayerCharacterId, isNull);
      expect(manifest.newGame.playerAvatarCharacterIds, isEmpty);
      expect(manifest.trainers.single.characterId, isNull);
      expect(
        manifest.cinematics.single.stageContext!.actorAppearanceBindings,
        isEmpty,
      );
      expect(map.entities.single.npc!.characterId, isNull);
      expect(draft.changeSet.changes, hasLength(2));
      expect(
        draft.changeSet.changes
            .singleWhere((change) => change.resource.kind == 'map')
            .beforeBytes,
        snapshot.resourceBytes('map:village'),
      );
    });

    test('replace deletion rewrites every dependency to another character', () {
      final draft = const CharacterStudioCharacterActions().build(
        _context(
          snapshot: characterActionSnapshot(withReferences: true),
          actionId: 'characterStudio.character.delete',
          parameters: const <String, Object?>{
            'characterId': 'elia',
            'resolution': 'replace',
            'replacementId': 'nox',
          },
        ),
      );
      final manifest = _projectedManifest(draft);
      final map = _projectedMap(draft, 'village');

      expect(manifest.settings.defaultPlayerCharacterId, 'nox');
      expect(manifest.newGame.playerAvatarCharacterIds, ['nox']);
      expect(manifest.trainers.single.characterId, 'nox');
      expect(
        manifest.cinematics.single.stageContext!.actorAppearanceBindings.single
            .characterId,
        'nox',
      );
      expect(map.entities.single.npc!.characterId, 'nox');
    });

    test('clear deletion removes dialogue portrait directives', () {
      final draft = const CharacterStudioCharacterActions().build(
        _context(
          snapshot: characterActionSnapshot(
            dialogueSource: '''title: Start
---
<<portrait elia neutral>>
Élia: Bonjour.
===
''',
          ),
          actionId: 'characterStudio.character.delete',
          parameters: const <String, Object?>{
            'characterId': 'elia',
            'resolution': 'clear',
          },
        ),
      );

      expect(
        _dialogueAfter(draft),
        '''title: Start
---
Élia: Bonjour.
===
''',
      );
    });

    test('replace deletion rewrites dialogue portrait character IDs', () {
      final draft = const CharacterStudioCharacterActions().build(
        _context(
          snapshot: characterActionSnapshot(
            dialogueSource: '''title: Start
---
<<portrait elia neutral>>
Élia: Bonjour.
===
''',
          ),
          actionId: 'characterStudio.character.delete',
          parameters: const <String, Object?>{
            'characterId': 'elia',
            'resolution': 'replace',
            'replacementId': 'nox',
          },
        ),
      );

      expect(_dialogueAfter(draft), contains('<<portrait nox neutral>>'));
      expect(_dialogueAfter(draft), contains('Élia: Bonjour.'));
    });
  });
}

AuthoringPlanningContext _context({
  required ProjectSnapshot snapshot,
  required String actionId,
  required Map<String, Object?> parameters,
  bool dryRun = false,
}) {
  return AuthoringPlanningContext(
    snapshot: snapshot,
    request: AuthoringRequest(
      requestId: 'request-character',
      actionId: actionId,
      actionVersion: 1,
      workspaceHandle: 'workspace-character-studio',
      parameters: parameters,
      expectedRevision: snapshot.revision,
      idempotencyKey: 'idem-character',
      dryRun: dryRun,
    ),
    planId: 'plan-character',
    seed: 1,
  );
}

ProjectSnapshot characterActionSnapshot({
  bool withReferences = false,
  String? defaultPlayerCharacterId,
  String? dialogueSource,
  bool missingMap = false,
  bool missingDialogue = false,
  bool configuredPlayer = false,
  bool incompatibleReplacement = false,
  bool invalidDialogue = false,
  bool compatiblePlayer = false,
  bool rawMetadata = false,
  bool cinematicCommand = false,
  bool compatibleClip = false,
}) {
  final manifest = ProjectManifest(
    name: 'Character action fixture',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'village',
        name: 'Village',
        relativePath: 'maps/village.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'characters',
        name: 'Characters',
        relativePath: 'assets/characters.png',
      ),
    ],
    characterStudioCatalog: ProjectCharacterStudioCatalog(
      customAnimationDefinitions: [
        if (cinematicCommand)
          const CharacterCustomAnimationDefinition(
              id: 'wave',
              displayName: 'Saluer',
              mode: CharacterCustomAnimationMode.single)
      ],
      portraitStates: <CharacterPortraitStateDefinition>[
        CharacterPortraitStateDefinition(
          id: 'neutral',
          displayName: 'Neutre',
        ),
        CharacterPortraitStateDefinition(
          id: 'sad',
          displayName: 'Triste',
          sortOrder: 1,
        ),
      ],
    ),
    characters: <ProjectCharacterEntry>[
      ProjectCharacterEntry(
        id: 'elia',
        name: 'Élia',
        tilesetId: 'characters',
        portraits: <CharacterPortraitVariant>[
          CharacterPortraitVariant(
            portraitStateId: 'neutral',
            assetId: 'elia-neutral',
          ),
        ],
        animations: <CharacterAnimation>[
          CharacterAnimation(
            state: CharacterAnimationState.idle,
            direction: EntityFacing.south,
          ),
        ],
      ),
      ProjectCharacterEntry(
        id: 'nox',
        name: 'Nox',
        tilesetId: 'characters',
        sortOrder: 1,
        customAnimations: [
          if (compatibleClip)
            const CharacterCustomAnimationClip(
                definitionId: 'wave',
                sourceAssetId: 'elia-neutral',
                frames: [
                  CharacterAnimationFrame(
                      source:
                          TilesetSourceRect(x: 0, y: 0, width: 32, height: 64))
                ])
        ],
        animations: [
          if (compatiblePlayer)
            for (final facing in EntityFacing.values)
              CharacterAnimation(
                  state: CharacterAnimationState.idle,
                  direction: facing,
                  sourceAssetId: 'elia-neutral',
                  frames: const [
                    CharacterAnimationFrame(
                        source: TilesetSourceRect(
                            x: 0, y: 0, width: 32, height: 64))
                  ])
        ],
        portraits: incompatibleReplacement
            ? const []
            : const [
                CharacterPortraitVariant(
                    portraitStateId: 'neutral', assetId: 'elia-neutral')
              ],
      ),
    ],
    settings: ProjectSettings(
      defaultPlayerCharacterId:
          withReferences ? 'elia' : defaultPlayerCharacterId,
    ),
    newGame: ProjectNewGameConfig(
      startMapId: configuredPlayer ? 'village' : '',
      playerAvatarCharacterIds:
          withReferences ? const <String>['elia'] : const <String>[],
    ),
    trainers: withReferences
        ? const <ProjectTrainerEntry>[
            ProjectTrainerEntry(
              id: 'trainer-elia',
              name: 'Élia',
              trainerClass: 'Héroïne',
              characterId: 'elia',
            ),
          ]
        : const <ProjectTrainerEntry>[],
    cinematics: withReferences
        ? <CinematicAsset>[
            CinematicAsset(
              id: 'intro',
              title: 'Intro',
              stageContext: CinematicStageContext(
                actorAppearanceBindings: <CinematicActorAppearanceBinding>[
                  CinematicActorAppearanceBinding(
                    actorId: 'hero',
                    characterId: 'elia',
                  ),
                ],
              ),
              timeline: CinematicTimeline(steps: [
                if (cinematicCommand)
                  buildCinematicCharacterCustomAnimationStep(
                      id: 'greeting',
                      command: CharacterCustomAnimationRuntimeCommand(
                          actorId: 'hero', definitionId: 'wave'))
              ]),
            ),
          ]
        : const <CinematicAsset>[],
    dialogues: <ProjectDialogueEntry>[
      if (dialogueSource != null)
        const ProjectDialogueEntry(
          id: 'intro',
          name: 'Introduction',
          relativePath: 'dialogues/intro.yarn',
        ),
    ],
  );
  final map = MapData(
    id: 'village',
    name: 'Village',
    size: const GridSize(width: 8, height: 8),
    entities: <MapEntity>[
      MapEntity(
        id: 'elia_npc',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 2, y: 3),
        npc: MapEntityNpcData(
          characterId: withReferences ? 'elia' : null,
        ),
      ),
    ],
  );
  final projectRaw = manifest.toJson();
  final mapRaw = map.toJson();
  if (rawMetadata) {
    (projectRaw['characters'] as List).last['foreign'] = {
      'keep': [1, 'été']
    };
    (projectRaw['tilesets'] as List).first['extensionData'] = {'nested': true};
    (mapRaw['entities'] as List).first['foreign'] = {'keep': 'unchanged'};
    ((mapRaw['entities'] as List).first['npc'] as Map)['foreign'] = {
      'also': 'unchanged'
    };
    mapRaw['foreign'] = {'root': true};
  }
  final projectBytes = utf8.encode(jsonEncode(projectRaw));
  final mapBytes = utf8.encode(jsonEncode(mapRaw));
  final dialogueBytes = dialogueSource == null
      ? null
      : invalidDialogue
          ? <int>[0xff]
          : utf8.encode(dialogueSource);
  final portraitBytes = sourcePng(width: 64, height: 128);
  final artifact =
      ContentArtifactRef.fromBytes(portraitBytes, mediaType: 'image/png');
  final assets = AssetCatalog(records: [
    AssetRecord(
        id: 'elia-neutral',
        logicalPath: 'assets/portrait.png',
        artifact: artifact)
  ]);
  final catalogBytes = utf8.encode(jsonEncode(assets.toJson()));
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('character_action_project'),
    revision:
        'sha256:abababababababababababababababababababababababababababababababab',
    manifest: manifest,
    maps: <MapData>[if (!missingMap) map],
    resourceFingerprints: <String, String>{
      assetCatalogResourceIdentity: computeAuthoringBytesFingerprint(
          catalogBytes,
          logicalName: assetCatalogStorageKey),
      assetBlobResourceIdentity(artifact.digest):
          computeAuthoringBytesFingerprint(portraitBytes,
              logicalName: assetBlobStorageKey(artifact)),
      'project': computeAuthoringBytesFingerprint(
        projectBytes,
        logicalName: 'project.json',
      ),
      'map:village': computeAuthoringBytesFingerprint(
        mapBytes,
        logicalName: 'maps/village.json',
      ),
      if (dialogueBytes != null && !missingDialogue)
        'dialogueSource:intro': computeAuthoringBytesFingerprint(
          dialogueBytes,
          logicalName: 'dialogues/intro.yarn',
        ),
    },
    resourceBytes: <String, List<int>>{
      assetCatalogResourceIdentity: catalogBytes,
      assetBlobResourceIdentity(artifact.digest): portraitBytes,
      'project': projectBytes,
      'map:village': mapBytes,
      if (dialogueBytes != null && !missingDialogue)
        'dialogueSource:intro': dialogueBytes,
    },
    resourceStorageKeys: <String, String>{
      assetCatalogResourceIdentity: assetCatalogStorageKey,
      assetBlobResourceIdentity(artifact.digest): assetBlobStorageKey(artifact),
      'project': 'project.json',
      'map:village': 'maps/village.json',
      if (dialogueSource != null && !missingDialogue)
        'dialogueSource:intro': 'dialogues/intro.yarn',
    },
  );
}

ProjectManifest _projectedManifest(AuthoringMutationDraft draft) {
  final change = draft.changeSet.changes.singleWhere(
    (change) => change.resource.kind == 'project',
  );
  return ProjectManifest.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(utf8.decode(change.afterBytes!)) as Map,
    ),
  );
}

MapData _projectedMap(AuthoringMutationDraft draft, String mapId) {
  final change = draft.changeSet.changes.singleWhere(
    (change) => change.resource.kind == 'map' && change.resource.id == mapId,
  );
  return MapData.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(utf8.decode(change.afterBytes!)) as Map,
    ),
  );
}

String _dialogueAfter(AuthoringMutationDraft draft) {
  final change = draft.changeSet.changes.singleWhere(
    (change) => change.resource.kind == 'dialogue',
  );
  return utf8.decode(change.afterBytes!);
}
