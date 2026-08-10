import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Character Studio animation definition actions', () {
    test('registers every specialized animation catalog action', () {
      final ids = AuthoringMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();

      expect(
        ids,
        containsAll(<String>{
          'characterStudio.animationDefinition.create',
          'characterStudio.animationDefinition.update',
          'characterStudio.animationDefinition.reorder',
          'characterStudio.animationDefinition.deletePlan',
          'characterStudio.animationDefinition.delete',
        }),
      );
    });

    test('creates a custom definition with a stable global identity', () {
      final draft = const CharacterStudioAnimationDefinitionActions().build(
        _context(
          snapshot: _snapshot(
            definitions: const <CharacterCustomAnimationDefinition>[],
          ),
          actionId: 'characterStudio.animationDefinition.create',
          parameters: const <String, Object?>{
            'displayName': 'Danse de victoire !',
            'mode': 'directional',
          },
        ),
      );
      final definition = _projected(draft)
          .characterStudioCatalog
          .customAnimationDefinitions
          .single;

      expect(definition.id, 'danse-de-victoire');
      expect(definition.displayName, 'Danse de victoire !');
      expect(definition.mode, CharacterCustomAnimationMode.directional);
      expect(definition.sortOrder, 0);
      expect(draft.preview['animationDefinitionId'], 'danse-de-victoire');
    });

    test('protects every system identity from custom creation', () {
      for (final label in <String>['Base', 'Idle', 'Walk', 'Run']) {
        expect(
          () => const CharacterStudioAnimationDefinitionActions().build(
            _context(
              snapshot: _snapshot(
                definitions: const <CharacterCustomAnimationDefinition>[],
              ),
              actionId: 'characterStudio.animationDefinition.create',
              parameters: <String, Object?>{
                'displayName': label,
                'mode': 'directional',
              },
            ),
          ),
          throwsA(
            isA<CharacterStudioActionException>().having(
              (error) => error.code,
              'code',
              'character_studio.animation_definition.id_reserved',
            ),
          ),
        );
      }
    });

    test('renames without changing identity, mode, or order', () {
      final draft = const CharacterStudioAnimationDefinitionActions().build(
        _context(
          snapshot: _snapshot(),
          actionId: 'characterStudio.animationDefinition.update',
          parameters: const <String, Object?>{
            'id': 'emote',
            'displayName': 'Saluer',
          },
        ),
      );
      final definition = _projected(draft)
          .characterStudioCatalog
          .customAnimationDefinitions
          .single;

      expect(definition.id, 'emote');
      expect(definition.displayName, 'Saluer');
      expect(definition.mode, CharacterCustomAnimationMode.directional);
      expect(definition.sortOrder, 0);
    });

    test('changes an unused mode and locks a referenced mode', () {
      final draft = const CharacterStudioAnimationDefinitionActions().build(
        _context(
          snapshot: _snapshot(),
          actionId: 'characterStudio.animationDefinition.update',
          parameters: const <String, Object?>{
            'id': 'emote',
            'displayName': 'Émote',
            'mode': 'single',
          },
        ),
      );

      expect(
        _projected(draft)
            .characterStudioCatalog
            .customAnimationDefinitions
            .single
            .mode,
        CharacterCustomAnimationMode.single,
      );
      expect(
        () => const CharacterStudioAnimationDefinitionActions().build(
          _context(
            snapshot: _snapshot(withClipUsage: true),
            actionId: 'characterStudio.animationDefinition.update',
            parameters: const <String, Object?>{
              'id': 'emote',
              'displayName': 'Émote',
              'mode': 'single',
            },
          ),
        ),
        throwsA(
          isA<CharacterStudioActionException>().having(
            (error) => error.code,
            'code',
            'character_studio.animation_definition.mode_locked',
          ),
        ),
      );
    });

    test('reorders only the exact custom definition set', () {
      final snapshot = _snapshot(
        definitions: const <CharacterCustomAnimationDefinition>[
          CharacterCustomAnimationDefinition(
            id: 'emote',
            displayName: 'Émote',
            mode: CharacterCustomAnimationMode.directional,
          ),
          CharacterCustomAnimationDefinition(
            id: 'jump',
            displayName: 'Saut',
            mode: CharacterCustomAnimationMode.single,
            sortOrder: 1,
          ),
        ],
      );
      final draft = const CharacterStudioAnimationDefinitionActions().build(
        _context(
          snapshot: snapshot,
          actionId: 'characterStudio.animationDefinition.reorder',
          parameters: const <String, Object?>{
            'orderedIds': <String>['jump', 'emote'],
          },
        ),
      );

      expect(
        _projected(draft)
            .characterStudioCatalog
            .customAnimationDefinitions
            .map((definition) => '${definition.id}:${definition.sortOrder}'),
        <String>['jump:0', 'emote:1'],
      );
      expect(
        () => const CharacterStudioAnimationDefinitionActions().build(
          _context(
            snapshot: snapshot,
            actionId: 'characterStudio.animationDefinition.reorder',
            parameters: const <String, Object?>{
              'orderedIds': <String>['emote'],
            },
          ),
        ),
        throwsA(
          isA<CharacterStudioActionException>().having(
            (error) => error.code,
            'code',
            'character_studio.animation_definition.reorder_mismatch',
          ),
        ),
      );
    });

    test('delete plan requires dry-run and reports clip dependencies', () {
      final snapshot = _snapshot(withClipUsage: true);
      final draft = const CharacterStudioAnimationDefinitionActions().build(
        _context(
          snapshot: snapshot,
          actionId: 'characterStudio.animationDefinition.deletePlan',
          parameters: const <String, Object?>{'id': 'emote'},
          dryRun: true,
        ),
      );
      final dependencies = draft.preview['dependencies']! as List<Object?>;

      expect(draft.preview['requiresResolution'], isTrue);
      expect(draft.preview['choices'], <Object?>['replace', 'clear', 'cancel']);
      expect(dependencies, hasLength(1));
      expect((dependencies.single! as Map)['sourceId'], 'elia');
      expect(
        () => const CharacterStudioAnimationDefinitionActions().build(
          _context(
            snapshot: snapshot,
            actionId: 'characterStudio.animationDefinition.deletePlan',
            parameters: const <String, Object?>{'id': 'emote'},
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
      final snapshot = _snapshot(withClipUsage: true);
      expect(
        () => const CharacterStudioAnimationDefinitionActions().build(
          _context(
            snapshot: snapshot,
            actionId: 'characterStudio.animationDefinition.delete',
            parameters: const <String, Object?>{'id': 'emote'},
          ),
        ),
        throwsA(
          isA<CharacterStudioActionException>().having(
            (error) => error.code,
            'code',
            'character_studio.animation_definition.resolution_required',
          ),
        ),
      );

      final draft = const CharacterStudioAnimationDefinitionActions().build(
        _context(
          snapshot: snapshot,
          actionId: 'characterStudio.animationDefinition.delete',
          parameters: const <String, Object?>{
            'id': 'emote',
            'resolution': 'clear',
          },
        ),
      );
      final projected = _projected(draft);

      expect(
        projected.characterStudioCatalog.customAnimationDefinitions,
        isEmpty,
      );
      expect(projected.characters.single.customAnimations, isEmpty);
      expect(
        draft.changeSet.changes.single.beforeBytes,
        snapshot.resourceBytes('project'),
      );
      expect(draft.preview['resolvedDependencyCount'], 1);
    });

    test('referenced deletion replaces compatible clips transactionally', () {
      final snapshot = _snapshot(
        withClipUsage: true,
        definitions: const <CharacterCustomAnimationDefinition>[
          CharacterCustomAnimationDefinition(
            id: 'emote',
            displayName: 'Émote',
            mode: CharacterCustomAnimationMode.directional,
          ),
          CharacterCustomAnimationDefinition(
            id: 'gesture',
            displayName: 'Geste',
            mode: CharacterCustomAnimationMode.directional,
            sortOrder: 1,
          ),
        ],
      );
      final draft = const CharacterStudioAnimationDefinitionActions().build(
        _context(
          snapshot: snapshot,
          actionId: 'characterStudio.animationDefinition.delete',
          parameters: const <String, Object?>{
            'id': 'emote',
            'resolution': 'replace',
            'replacementId': 'gesture',
          },
        ),
      );
      final projected = _projected(draft);

      expect(
        projected.characterStudioCatalog.customAnimationDefinitions
            .map((definition) => definition.id),
        <String>['gesture'],
      );
      expect(
        projected.characters.single.customAnimations.single.definitionId,
        'gesture',
      );
    });

    test('replacement requires a compatible mode', () {
      final incompatible = _snapshot(
        withClipUsage: true,
        definitions: const <CharacterCustomAnimationDefinition>[
          CharacterCustomAnimationDefinition(
            id: 'emote',
            displayName: 'Émote',
            mode: CharacterCustomAnimationMode.directional,
          ),
          CharacterCustomAnimationDefinition(
            id: 'jump',
            displayName: 'Saut',
            mode: CharacterCustomAnimationMode.single,
            sortOrder: 1,
          ),
        ],
      );

      expect(
        () => const CharacterStudioAnimationDefinitionActions().build(
          _context(
            snapshot: incompatible,
            actionId: 'characterStudio.animationDefinition.delete',
            parameters: const <String, Object?>{
              'id': 'emote',
              'resolution': 'replace',
              'replacementId': 'jump',
            },
          ),
        ),
        throwsA(
          isA<CharacterStudioActionException>().having(
            (error) => error.code,
            'code',
            'character_studio.animation_definition.replacement_mode_mismatch',
          ),
        ),
      );
    });

    test('replacement rejects a duplicate directional clip slot', () {
      final snapshot = _snapshot(
        withClipUsage: true,
        withReplacementClipUsage: true,
        definitions: const <CharacterCustomAnimationDefinition>[
          CharacterCustomAnimationDefinition(
            id: 'emote',
            displayName: 'Émote',
            mode: CharacterCustomAnimationMode.directional,
          ),
          CharacterCustomAnimationDefinition(
            id: 'gesture',
            displayName: 'Geste',
            mode: CharacterCustomAnimationMode.directional,
            sortOrder: 1,
          ),
        ],
      );

      expect(
        () => const CharacterStudioAnimationDefinitionActions().build(
          _context(
            snapshot: snapshot,
            actionId: 'characterStudio.animationDefinition.delete',
            parameters: const <String, Object?>{
              'id': 'emote',
              'resolution': 'replace',
              'replacementId': 'gesture',
            },
          ),
        ),
        throwsA(
          isA<CharacterStudioActionException>().having(
            (error) => error.code,
            'code',
            'character_studio.animation_definition.replacement_slot_conflict',
          ),
        ),
      );
    });

    test('system definitions cannot enter the custom deletion flow', () {
      expect(
        () => const CharacterStudioAnimationDefinitionActions().build(
          _context(
            snapshot: _snapshot(),
            actionId: 'characterStudio.animationDefinition.deletePlan',
            parameters: const <String, Object?>{'id': 'walk'},
            dryRun: true,
          ),
        ),
        throwsA(
          isA<CharacterStudioActionException>().having(
            (error) => error.code,
            'code',
            'character_studio.animation_definition.system_immutable',
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
      requestId: 'request-animation-definition',
      actionId: actionId,
      actionVersion: 1,
      workspaceHandle: 'workspace-character-studio',
      parameters: parameters,
      expectedRevision: snapshot.revision,
      idempotencyKey: 'idem-animation-definition',
      dryRun: dryRun,
    ),
    planId: 'plan-animation-definition',
    seed: 1,
  );
}

ProjectSnapshot _snapshot({
  List<CharacterCustomAnimationDefinition> definitions =
      const <CharacterCustomAnimationDefinition>[
    CharacterCustomAnimationDefinition(
      id: 'emote',
      displayName: 'Émote',
      mode: CharacterCustomAnimationMode.directional,
    ),
  ],
  bool withClipUsage = false,
  bool withReplacementClipUsage = false,
}) {
  final manifest = ProjectManifest(
    name: 'Animation definition fixture',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    characterStudioCatalog: ProjectCharacterStudioCatalog(
      customAnimationDefinitions: definitions,
    ),
    characters: <ProjectCharacterEntry>[
      ProjectCharacterEntry(
        id: 'elia',
        name: 'Élia',
        tilesetId: 'elia-sheet',
        customAnimations: <CharacterCustomAnimationClip>[
          if (withClipUsage)
            const CharacterCustomAnimationClip(
              definitionId: 'emote',
              direction: EntityFacing.south,
              sourceAssetId: 'elia-emote-sheet',
            ),
          if (withReplacementClipUsage)
            const CharacterCustomAnimationClip(
              definitionId: 'gesture',
              direction: EntityFacing.south,
              sourceAssetId: 'elia-gesture-sheet',
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
    projectHandle: const ProjectHandle('animation_definition_project'),
    revision:
        'sha256:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
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
