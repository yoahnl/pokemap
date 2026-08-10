import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Character Studio character actions', () {
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
          snapshot: _snapshot(),
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
      final before = _snapshot();
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
          snapshot: _snapshot(),
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
          snapshot: _snapshot(defaultPlayerCharacterId: 'elia'),
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
          snapshot: _snapshot(),
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
          snapshot: _snapshot(),
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
          snapshot: _snapshot(),
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
          snapshot: _snapshot(withReferences: true),
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

    test('referenced deletion requires an explicit resolution', () {
      expect(
        () => const CharacterStudioCharacterActions().build(
          _context(
            snapshot: _snapshot(withReferences: true),
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
      final snapshot = _snapshot(withReferences: true);
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
          snapshot: _snapshot(withReferences: true),
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

ProjectSnapshot _snapshot({
  bool withReferences = false,
  String? defaultPlayerCharacterId,
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
    characterStudioCatalog: const ProjectCharacterStudioCatalog(
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
    characters: const <ProjectCharacterEntry>[
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
      ),
    ],
    settings: ProjectSettings(
      defaultPlayerCharacterId:
          withReferences ? 'elia' : defaultPlayerCharacterId,
    ),
    newGame: ProjectNewGameConfig(
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
              timeline: CinematicTimeline(),
            ),
          ]
        : const <CinematicAsset>[],
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
  final projectBytes = utf8.encode(jsonEncode(manifest.toJson()));
  final mapBytes = utf8.encode(jsonEncode(map.toJson()));
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('character_action_project'),
    revision:
        'sha256:abababababababababababababababababababababababababababababababab',
    manifest: manifest,
    maps: <MapData>[map],
    resourceFingerprints: <String, String>{
      'project': computeAuthoringBytesFingerprint(
        projectBytes,
        logicalName: 'project.json',
      ),
      'map:village': computeAuthoringBytesFingerprint(
        mapBytes,
        logicalName: 'maps/village.json',
      ),
    },
    resourceBytes: <String, List<int>>{
      'project': projectBytes,
      'map:village': mapBytes,
    },
    resourceStorageKeys: const <String, String>{
      'project': 'project.json',
      'map:village': 'maps/village.json',
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
