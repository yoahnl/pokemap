import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Character Studio portrait state actions', () {
    test('registers every specialized portrait catalog action', () {
      final ids = AuthoringMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();

      expect(
        ids,
        containsAll(<String>{
          'characterStudio.portraitState.create',
          'characterStudio.portraitState.update',
          'characterStudio.portraitState.reorder',
          'characterStudio.portraitState.deletePlan',
          'characterStudio.portraitState.delete',
        }),
      );
    });

    test('creates a stable slug and appends the state deterministically', () {
      final draft = const CharacterStudioPortraitStateActions().build(
        _context(
          snapshot: _snapshot(),
          actionId: 'characterStudio.portraitState.create',
          parameters: const <String, Object?>{
            'displayName': 'Très contente !',
          },
        ),
      );
      final states = _projected(draft).characterStudioCatalog.portraitStates;

      expect(states.map((state) => state.id),
          <String>['neutral', 'tres-contente']);
      expect(states.last.displayName, 'Très contente !');
      expect(states.last.sortOrder, 1);
      expect(draft.preview['portraitStateId'], 'tres-contente');
    });

    test('rejects a derived identity collision without changing bytes', () {
      expect(
        () => const CharacterStudioPortraitStateActions().build(
          _context(
            snapshot: _snapshot(),
            actionId: 'characterStudio.portraitState.create',
            parameters: const <String, Object?>{'displayName': 'Neutral'},
          ),
        ),
        throwsA(
          isA<CharacterStudioActionException>().having(
            (error) => error.code,
            'code',
            'character_studio.portrait_state.id_conflict',
          ),
        ),
      );
    });

    test('renames without changing stable identity or order', () {
      final draft = const CharacterStudioPortraitStateActions().build(
        _context(
          snapshot: _snapshot(),
          actionId: 'characterStudio.portraitState.update',
          parameters: const <String, Object?>{
            'id': 'neutral',
            'displayName': 'Calme',
          },
        ),
      );
      final state =
          _projected(draft).characterStudioCatalog.portraitStates.single;

      expect(state.id, 'neutral');
      expect(state.displayName, 'Calme');
      expect(state.sortOrder, 0);
    });

    test('reorders only an exact catalog identity set', () {
      final snapshot = _snapshot(
        states: const <CharacterPortraitStateDefinition>[
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
      );
      final draft = const CharacterStudioPortraitStateActions().build(
        _context(
          snapshot: snapshot,
          actionId: 'characterStudio.portraitState.reorder',
          parameters: const <String, Object?>{
            'orderedIds': <String>['sad', 'neutral'],
          },
        ),
      );

      expect(
        _projected(draft)
            .characterStudioCatalog
            .portraitStates
            .map((state) => '${state.id}:${state.sortOrder}'),
        <String>['sad:0', 'neutral:1'],
      );
      expect(
        () => const CharacterStudioPortraitStateActions().build(
          _context(
            snapshot: snapshot,
            actionId: 'characterStudio.portraitState.reorder',
            parameters: const <String, Object?>{
              'orderedIds': <String>['sad'],
            },
          ),
        ),
        throwsA(
          isA<CharacterStudioActionException>().having(
            (error) => error.code,
            'code',
            'character_studio.portrait_state.reorder_mismatch',
          ),
        ),
      );
    });

    test('delete plan requires dry-run and reports stable dependencies', () {
      final snapshot = _snapshot(withPortraitUsage: true);
      final draft = const CharacterStudioPortraitStateActions().build(
        _context(
          snapshot: snapshot,
          actionId: 'characterStudio.portraitState.deletePlan',
          parameters: const <String, Object?>{'id': 'neutral'},
          dryRun: true,
        ),
      );
      final dependencies = draft.preview['dependencies']! as List<Object?>;

      expect(draft.preview['requiresResolution'], isTrue);
      expect(draft.preview['choices'], <Object?>['replace', 'clear', 'cancel']);
      expect(dependencies, hasLength(1));
      expect((dependencies.single! as Map)['sourceId'], 'elia');
      expect(
        () => const CharacterStudioPortraitStateActions().build(
          _context(
            snapshot: snapshot,
            actionId: 'characterStudio.portraitState.deletePlan',
            parameters: const <String, Object?>{'id': 'neutral'},
          ),
        ),
        throwsA(
          isA<CharacterStudioActionException>().having(
            (error) => error.code,
            'code',
            'character_studio.delete_plan_requires_dry_run',
          ),
        ),
      );
    });

    test('referenced deletion requires and applies clear atomically', () {
      final snapshot = _snapshot(withPortraitUsage: true);
      expect(
        () => const CharacterStudioPortraitStateActions().build(
          _context(
            snapshot: snapshot,
            actionId: 'characterStudio.portraitState.delete',
            parameters: const <String, Object?>{'id': 'neutral'},
          ),
        ),
        throwsA(
          isA<CharacterStudioActionException>().having(
            (error) => error.code,
            'code',
            'character_studio.portrait_state.resolution_required',
          ),
        ),
      );

      final draft = const CharacterStudioPortraitStateActions().build(
        _context(
          snapshot: snapshot,
          actionId: 'characterStudio.portraitState.delete',
          parameters: const <String, Object?>{
            'id': 'neutral',
            'resolution': 'clear',
          },
        ),
      );
      final projected = _projected(draft);

      expect(projected.characterStudioCatalog.portraitStates, isEmpty);
      expect(projected.characters.single.portraits, isEmpty);
      expect(draft.changeSet.changes.single.beforeBytes,
          snapshot.resourceBytes('project'));
      expect(draft.preview['resolvedDependencyCount'], 1);
    });

    test('referenced deletion can replace every portrait transactionally', () {
      final snapshot = _snapshot(
        withPortraitUsage: true,
        states: const <CharacterPortraitStateDefinition>[
          CharacterPortraitStateDefinition(
            id: 'neutral',
            displayName: 'Neutre',
          ),
          CharacterPortraitStateDefinition(
            id: 'calm',
            displayName: 'Calme',
            sortOrder: 1,
          ),
        ],
      );
      final draft = const CharacterStudioPortraitStateActions().build(
        _context(
          snapshot: snapshot,
          actionId: 'characterStudio.portraitState.delete',
          parameters: const <String, Object?>{
            'id': 'neutral',
            'resolution': 'replace',
            'replacementId': 'calm',
          },
        ),
      );
      final projected = _projected(draft);

      expect(
        projected.characterStudioCatalog.portraitStates
            .map((state) => state.id),
        <String>['calm'],
      );
      expect(
        projected.characters.single.portraits.single.portraitStateId,
        'calm',
      );
    });

    test('planner rejects a stale expected revision before action execution',
        () async {
      final snapshot = _snapshot();
      final planner = AuthoringActionPlanner(
        store: AuthoringPlanStore(
          clock: () => DateTime.utc(2026, 8, 10),
        ),
        tokenFactory: (prefix) => '${prefix}token',
        seedFactory: () => 1,
      );

      await expectLater(
        planner.plan(
          request: AuthoringRequest(
            requestId: 'stale-create',
            actionId: 'characterStudio.portraitState.create',
            actionVersion: 1,
            workspaceHandle: 'workspace',
            parameters: const <String, Object?>{'displayName': 'Joie'},
            expectedRevision:
                'sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
          ),
          snapshot: snapshot,
          build: const CharacterStudioPortraitStateActions().build,
        ),
        throwsA(
          isA<AuthoringPlanException>().having(
            (error) => error.code,
            'code',
            'plan.stale',
          ),
        ),
      );
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
      requestId: 'request-portrait-state',
      actionId: actionId,
      actionVersion: 1,
      workspaceHandle: 'workspace-character-studio',
      parameters: parameters,
      expectedRevision: snapshot.revision,
      idempotencyKey: 'idem-portrait-state',
      dryRun: dryRun,
    ),
    planId: 'plan-portrait-state',
    seed: 1,
  );
}

ProjectSnapshot _snapshot({
  List<CharacterPortraitStateDefinition> states =
      const <CharacterPortraitStateDefinition>[
    CharacterPortraitStateDefinition(id: 'neutral', displayName: 'Neutre'),
  ],
  bool withPortraitUsage = false,
}) {
  final manifest = ProjectManifest(
    name: 'Portrait state fixture',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    characterStudioCatalog: ProjectCharacterStudioCatalog(
      portraitStates: states,
    ),
    characters: <ProjectCharacterEntry>[
      ProjectCharacterEntry(
        id: 'elia',
        name: 'Élia',
        tilesetId: 'elia-sheet',
        portraits: <CharacterPortraitVariant>[
          if (withPortraitUsage)
            const CharacterPortraitVariant(
              portraitStateId: 'neutral',
              assetId: 'elia-neutral',
            ),
        ],
      ),
    ],
  );
  final bytes = utf8.encode(jsonEncode(manifest.toJson()));
  final fingerprint = computeAuthoringBytesFingerprint(
    bytes,
    logicalName: 'project.json',
  );
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('portrait_state_project'),
    revision:
        'sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
    manifest: manifest,
    maps: const <MapData>[],
    resourceFingerprints: <String, String>{'project': fingerprint},
    resourceBytes: <String, List<int>>{'project': bytes},
    resourceStorageKeys: const <String, String>{'project': 'project.json'},
  );
}

ProjectManifest _projected(AuthoringMutationDraft draft) {
  return ProjectManifest.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
          as Map,
    ),
  );
}
