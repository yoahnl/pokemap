import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Character Studio animation clip actions', () {
    test('registers clip and frame semantic actions', () {
      final ids = AuthoringMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();

      expect(
        ids,
        containsAll(<String>{
          'characterStudio.animationClip.upsert',
          'characterStudio.animationClip.delete',
          'characterStudio.animationFrame.insert',
          'characterStudio.animationFrame.update',
          'characterStudio.animationFrame.reorder',
          'characterStudio.animationFrame.delete',
        }),
      );
    });

    test('upserts one system slot without replacing its frames', () {
      final draft = const CharacterStudioAnimationClipActions().build(
        _context(
          snapshot: _snapshot(),
          actionId: 'characterStudio.animationClip.upsert',
          parameters: const <String, Object?>{
            'characterId': 'elia',
            'kind': 'system',
            'state': 'base',
            'direction': 'south',
            'sourceAssetId': 'elia-base-v2',
            'loop': false,
          },
        ),
      );
      final animation = _character(draft).animations.single;

      expect(animation.state, CharacterAnimationState.idle);
      expect(animation.direction, EntityFacing.south);
      expect(animation.sourceAssetId, 'elia-base-v2');
      expect(animation.loop, isFalse);
      expect(animation.frames, hasLength(2));
      expect(draft.changeSet.changes, hasLength(1));
    });

    test('creates directional and single custom slots from global definitions',
        () {
      final directional = const CharacterStudioAnimationClipActions().build(
        _context(
          snapshot: _snapshot(),
          actionId: 'characterStudio.animationClip.upsert',
          parameters: const <String, Object?>{
            'characterId': 'elia',
            'kind': 'custom',
            'definitionId': 'wave',
            'direction': 'east',
            'sourceAssetId': 'elia-wave',
          },
        ),
      );
      expect(
        _character(directional).customAnimations.single.direction,
        EntityFacing.east,
      );

      final single = const CharacterStudioAnimationClipActions().build(
        _context(
          snapshot: _snapshot(),
          actionId: 'characterStudio.animationClip.upsert',
          parameters: const <String, Object?>{
            'characterId': 'elia',
            'kind': 'custom',
            'definitionId': 'sleep',
            'sourceAssetId': 'elia-sleep',
          },
        ),
      );
      expect(_character(single).customAnimations.single.direction, isNull);
    });

    test('enforces the direction mode of custom definitions', () {
      expect(
        () => const CharacterStudioAnimationClipActions().build(
          _context(
            snapshot: _snapshot(),
            actionId: 'characterStudio.animationClip.upsert',
            parameters: const <String, Object?>{
              'characterId': 'elia',
              'kind': 'custom',
              'definitionId': 'wave',
              'sourceAssetId': 'elia-wave',
            },
          ),
        ),
        throwsA(
          isA<CharacterStudioActionException>().having(
            (error) => error.code,
            'code',
            'character_studio.animation.direction_required',
          ),
        ),
      );
      expect(
        () => const CharacterStudioAnimationClipActions().build(
          _context(
            snapshot: _snapshot(),
            actionId: 'characterStudio.animationClip.upsert',
            parameters: const <String, Object?>{
              'characterId': 'elia',
              'kind': 'custom',
              'definitionId': 'sleep',
              'direction': 'south',
              'sourceAssetId': 'elia-sleep',
            },
          ),
        ),
        throwsA(
          isA<CharacterStudioActionException>().having(
            (error) => error.code,
            'code',
            'character_studio.animation.direction_forbidden',
          ),
        ),
      );
    });

    test('inserts and updates a frame with exact rect and duration', () {
      final inserted = const CharacterStudioAnimationClipActions().build(
        _context(
          snapshot: _snapshot(),
          actionId: 'characterStudio.animationFrame.insert',
          parameters: <String, Object?>{
            ..._baseSlot,
            'frameIndex': 1,
            'frame': _frame(x: 8, durationMs: 90),
          },
        ),
      );
      final insertedFrames = _character(inserted).animations.single.frames;
      expect(insertedFrames, hasLength(3));
      expect(insertedFrames[1].source.x, 8);
      expect(insertedFrames[1].durationMs, 90);

      final updated = const CharacterStudioAnimationClipActions().build(
        _context(
          snapshot: _snapshot(),
          actionId: 'characterStudio.animationFrame.update',
          parameters: <String, Object?>{
            ..._baseSlot,
            'frameIndex': 0,
            'frame': _frame(x: 12, durationMs: 210),
          },
        ),
      );
      final updatedFrame = _character(updated).animations.single.frames.first;
      expect(updatedFrame.source.x, 12);
      expect(updatedFrame.durationMs, 210);
    });

    test('reorders and deletes frames by semantic slot', () {
      final reordered = const CharacterStudioAnimationClipActions().build(
        _context(
          snapshot: _snapshot(),
          actionId: 'characterStudio.animationFrame.reorder',
          parameters: const <String, Object?>{
            ..._baseSlot,
            'fromIndex': 0,
            'toIndex': 1,
          },
        ),
      );
      expect(
        _character(reordered)
            .animations
            .single
            .frames
            .map((frame) => frame.source.x),
        <int>[4, 0],
      );

      final deleted = const CharacterStudioAnimationClipActions().build(
        _context(
          snapshot: _snapshot(),
          actionId: 'characterStudio.animationFrame.delete',
          parameters: const <String, Object?>{
            ..._baseSlot,
            'frameIndex': 0,
          },
        ),
      );
      expect(
        _character(deleted).animations.single.frames.single.source.x,
        4,
      );
    });

    test('rejects invalid frame geometry before producing a draft', () {
      expect(
        () => const CharacterStudioAnimationClipActions().build(
          _context(
            snapshot: _snapshot(),
            actionId: 'characterStudio.animationFrame.update',
            parameters: <String, Object?>{
              ..._baseSlot,
              'frameIndex': 0,
              'frame': _frame(x: -1, durationMs: 0),
            },
          ),
        ),
        throwsA(
          isA<CharacterStudioActionException>().having(
            (error) => error.code,
            'code',
            'character_studio.animation.frame_invalid',
          ),
        ),
      );
    });

    test('deletes only the selected clip slot', () {
      final draft = const CharacterStudioAnimationClipActions().build(
        _context(
          snapshot: _snapshot(),
          actionId: 'characterStudio.animationClip.delete',
          parameters: _baseSlot,
        ),
      );

      expect(_character(draft).animations, isEmpty);
      expect(_character(draft).customAnimations, isEmpty);
    });
  });
}

const Map<String, Object?> _baseSlot = <String, Object?>{
  'characterId': 'elia',
  'kind': 'system',
  'state': 'base',
  'direction': 'south',
};

Map<String, Object?> _frame({required int x, required int durationMs}) {
  return <String, Object?>{
    'source': <String, Object?>{
      'x': x,
      'y': 0,
      'width': 4,
      'height': 8,
    },
    'durationMs': durationMs,
  };
}

AuthoringPlanningContext _context({
  required ProjectSnapshot snapshot,
  required String actionId,
  required Map<String, Object?> parameters,
}) {
  return AuthoringPlanningContext(
    snapshot: snapshot,
    request: AuthoringRequest(
      requestId: 'request-animation-clip',
      actionId: actionId,
      actionVersion: 1,
      workspaceHandle: 'workspace-character-studio',
      parameters: parameters,
      expectedRevision: snapshot.revision,
      idempotencyKey: 'idem-animation-clip',
    ),
    planId: 'plan-animation-clip',
    seed: 1,
  );
}

ProjectSnapshot _snapshot() {
  final manifest = ProjectManifest(
    name: 'Animation clip fixture',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'characters',
        name: 'Characters',
        relativePath: 'assets/characters.png',
      ),
    ],
    characterStudioCatalog: const ProjectCharacterStudioCatalog(
      customAnimationDefinitions: <CharacterCustomAnimationDefinition>[
        CharacterCustomAnimationDefinition(
          id: 'wave',
          displayName: 'Saluer',
          mode: CharacterCustomAnimationMode.directional,
        ),
        CharacterCustomAnimationDefinition(
          id: 'sleep',
          displayName: 'Dormir',
          mode: CharacterCustomAnimationMode.single,
          sortOrder: 1,
        ),
      ],
    ),
    characters: const <ProjectCharacterEntry>[
      ProjectCharacterEntry(
        id: 'elia',
        name: 'Élia',
        tilesetId: 'characters',
        animations: <CharacterAnimation>[
          CharacterAnimation(
            state: CharacterAnimationState.idle,
            direction: EntityFacing.south,
            sourceAssetId: 'elia-base',
            frames: <CharacterAnimationFrame>[
              CharacterAnimationFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 4, height: 8),
                durationMs: 120,
              ),
              CharacterAnimationFrame(
                source: TilesetSourceRect(x: 4, y: 0, width: 4, height: 8),
                durationMs: 120,
              ),
            ],
          ),
        ],
      ),
    ],
  );
  final bytes = utf8.encode(jsonEncode(manifest.toJson()));
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('animation_clip_project'),
    revision:
        'sha256:acacacacacacacacacacacacacacacacacacacacacacacacacacacacacacacac',
    manifest: manifest,
    maps: const <MapData>[],
    resourceFingerprints: <String, String>{
      'project': computeAuthoringBytesFingerprint(
        bytes,
        logicalName: 'project.json',
      ),
    },
    resourceBytes: <String, List<int>>{'project': bytes},
    resourceStorageKeys: const <String, String>{'project': 'project.json'},
  );
}

ProjectCharacterEntry _character(AuthoringMutationDraft draft) {
  final bytes = draft.changeSet.changes.single.afterBytes!;
  return ProjectManifest.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(utf8.decode(bytes)) as Map,
    ),
  ).characters.single;
}
