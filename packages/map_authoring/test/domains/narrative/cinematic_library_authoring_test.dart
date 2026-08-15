import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('publishes and queries the cinematic library aggregate', () {
    final registry = AuthoringResourceKindRegistry.canonical();
    const service = ProjectQueryService();
    final snapshot = _snapshot();

    expect(
      registry.queryableResourceKindIds,
      containsAll(<String>{
        'cinematicLibraryCatalog',
        'cinematicLibraryFolder',
        'cinematicLibraryEntry',
      }),
    );
    final folders = service.query(
      snapshot,
      AuthoringQueryRequest(
        resourceKind: 'cinematicLibraryFolder',
        operation: AuthoringQueryOperation.list,
        filters: const <String, Object?>{'family': 'world'},
        view: AuthoringQueryView.detail,
      ),
    );
    final entry = service.query(
      snapshot,
      AuthoringQueryRequest(
        resourceKind: 'cinematicLibraryEntry',
        operation: AuthoringQueryOperation.get,
        ids: const <String>['presentation:presentation-intro'],
        view: AuthoringQueryView.detail,
      ),
    );

    expect(folders.items.single, containsPair('id', 'world-folder'));
    expect(entry.items.single, containsPair('folderId', 'opening-folder'));
  });

  test('registers the semantic folder and placement action surface', () {
    final descriptors = {
      for (final descriptor
          in AuthoringMutationDispatcher.canonical().descriptors)
        descriptor.id: descriptor,
    };
    const expected = <String>{
      'cinematicLibraryAsset.create',
      'cinematicLibraryAsset.duplicate',
      'cinematicLibraryAsset.delete',
      'cinematicLibraryFolder.create',
      'cinematicLibraryFolder.rename',
      'cinematicLibraryFolder.move',
      'cinematicLibraryFolder.reorder',
      'cinematicLibraryFolder.setArchived',
      'cinematicLibraryFolder.delete',
      'cinematicLibraryEntry.place',
      'cinematicLibraryEntry.reorder',
      'cinematicLibraryEntry.setArchived',
      'cinematicLibraryEntry.remove',
    };

    expect(descriptors.keys, containsAll(expected));
    for (final actionId in expected) {
      expect(
        descriptors[actionId]!.guarantees,
        containsAll(<AuthoringGuarantee>{
          AuthoringGuarantee.dryRun,
          AuthoringGuarantee.idempotent,
          AuthoringGuarantee.atomic,
          AuthoringGuarantee.revisionChecked,
          AuthoringGuarantee.undoable,
        }),
      );
    }
  });

  test('creates world and Presentation assets with their placement atomically',
      () {
    final world = _apply(
      _snapshot().manifest,
      'cinematicLibraryAsset.create',
      const <String, Object?>{
        'family': 'world',
        'cinematicId': 'world-created',
        'title': 'World created',
        'targetFolderId': 'world-folder',
        'targetIndex': 1,
        'startingPoint': 'establishingShot',
      },
    );
    final presentation = _apply(
      world,
      'cinematicLibraryAsset.create',
      const <String, Object?>{
        'family': 'presentation',
        'cinematicId': 'presentation-created',
        'title': 'Presentation created',
        'targetFolderId': 'opening-folder',
        'targetIndex': 1,
        'templateId': 'titleIdentity',
        'templateVersion': 1,
      },
    );

    final worldAsset = presentation.cinematics.singleWhere(
      (asset) => asset.id == 'world-created',
    );
    final presentationAsset = presentation.presentationCinematics.singleWhere(
      (asset) => asset.id == 'presentation-created',
    );
    expect(worldAsset.timeline.steps, hasLength(2));
    expect(
      worldAsset.timeline.steps.last.kind,
      CinematicTimelineStepKind.camera,
    );
    expect(presentationAsset.layers, isNotEmpty);
    expect(
      presentation.cinematicLibraryCatalog
          .entryFor(CinematicLibraryFamily.world, 'world-created')
          ?.folderId,
      'world-folder',
    );
    expect(
      presentation.cinematicLibraryCatalog
          .entryFor(
            CinematicLibraryFamily.presentation,
            'presentation-created',
          )
          ?.folderId,
      'opening-folder',
    );
  });

  test('duplicates and deletes both cinematic families with their placement',
      () {
    var manifest = _snapshot().manifest;
    manifest = _apply(
      manifest,
      'cinematicLibraryAsset.duplicate',
      const <String, Object?>{
        'family': 'world',
        'cinematicId': 'world-intro',
        'duplicateId': 'world-copy',
        'title': 'World copy',
        'targetFolderId': 'world-folder',
        'targetIndex': 1,
      },
    );
    manifest = _apply(
      manifest,
      'cinematicLibraryAsset.duplicate',
      const <String, Object?>{
        'family': 'presentation',
        'cinematicId': 'presentation-intro',
        'duplicateId': 'presentation-copy',
        'title': 'Presentation copy',
        'targetFolderId': 'opening-folder',
        'targetIndex': 1,
      },
    );

    expect(
        manifest.cinematics.map((asset) => asset.id), contains('world-copy'));
    expect(
      manifest.presentationCinematics.map((asset) => asset.id),
      contains('presentation-copy'),
    );
    expect(
      manifest.cinematicLibraryCatalog
          .entryFor(CinematicLibraryFamily.world, 'world-copy'),
      isNotNull,
    );
    expect(
      manifest.cinematicLibraryCatalog.entryFor(
        CinematicLibraryFamily.presentation,
        'presentation-copy',
      ),
      isNotNull,
    );

    manifest = _apply(
      manifest,
      'cinematicLibraryAsset.delete',
      const <String, Object?>{
        'family': 'world',
        'cinematicId': 'world-copy',
      },
    );
    manifest = _apply(
      manifest,
      'cinematicLibraryAsset.delete',
      const <String, Object?>{
        'family': 'presentation',
        'cinematicId': 'presentation-copy',
      },
    );

    expect(manifest.cinematics.map((asset) => asset.id),
        isNot(contains('world-copy')));
    expect(
      manifest.presentationCinematics.map((asset) => asset.id),
      isNot(contains('presentation-copy')),
    );
    expect(
      manifest.cinematicLibraryCatalog
          .entryFor(CinematicLibraryFamily.world, 'world-copy'),
      isNull,
    );
    expect(
      manifest.cinematicLibraryCatalog.entryFor(
        CinematicLibraryFamily.presentation,
        'presentation-copy',
      ),
      isNull,
    );
  });

  test('applies canonical folder and placement mutations atomically', () {
    final source = _snapshot().manifest;
    final worldAssetBefore = source.cinematics.first.toJson();
    final created = _apply(
      source,
      'cinematicLibraryFolder.create',
      const <String, Object?>{
        'folderId': 'chapters',
        'family': 'world',
        'name': 'Chapters',
        'parentFolderId': 'world-folder',
        'targetIndex': 0,
      },
    );
    final renamed = _apply(
      created,
      'cinematicLibraryFolder.rename',
      const <String, Object?>{
        'folderId': 'chapters',
        'name': 'Story chapters',
      },
    );
    final placed = _apply(
      renamed,
      'cinematicLibraryEntry.place',
      const <String, Object?>{
        'family': 'world',
        'cinematicId': 'world-second',
        'targetFolderId': 'chapters',
        'targetIndex': 0,
      },
    );
    final archived = _apply(
      placed,
      'cinematicLibraryEntry.setArchived',
      const <String, Object?>{
        'family': 'world',
        'cinematicId': 'world-second',
        'isArchived': true,
      },
    );

    expect(
      archived.cinematicLibraryCatalog.requireFolder('chapters').name,
      'Story chapters',
    );
    expect(
      archived.cinematicLibraryCatalog
          .entryFor(CinematicLibraryFamily.world, 'world-second')!
          .isArchived,
      isTrue,
    );
    expect(archived.cinematics.first.toJson(), worldAssetBefore);
  });

  test('covers move, reorder, archive, remove and guarded delete actions', () {
    var manifest = _snapshot().manifest;
    manifest = _apply(
      manifest,
      'cinematicLibraryFolder.create',
      const {
        'folderId': 'temporary',
        'family': 'world',
        'name': 'Temporary',
        'parentFolderId': null,
        'targetIndex': 1,
      },
    );
    manifest = _apply(
      manifest,
      'cinematicLibraryFolder.create',
      const {
        'folderId': 'nested',
        'family': 'world',
        'name': 'Nested',
        'parentFolderId': 'temporary',
        'targetIndex': 0,
      },
    );
    manifest = _apply(
      manifest,
      'cinematicLibraryFolder.move',
      const {
        'folderId': 'nested',
        'targetParentFolderId': 'world-folder',
        'targetIndex': 0,
      },
    );
    manifest = _apply(
      manifest,
      'cinematicLibraryFolder.reorder',
      const {'folderId': 'temporary', 'targetIndex': 0},
    );
    manifest = _apply(
      manifest,
      'cinematicLibraryFolder.setArchived',
      const {'folderId': 'temporary', 'isArchived': true},
    );
    manifest = _apply(
      manifest,
      'cinematicLibraryEntry.place',
      const {
        'family': 'world',
        'cinematicId': 'world-second',
        'targetFolderId': 'nested',
        'targetIndex': 0,
      },
    );
    manifest = _apply(
      manifest,
      'cinematicLibraryEntry.reorder',
      const {
        'family': 'world',
        'cinematicId': 'world-second',
        'targetIndex': 0,
      },
    );
    manifest = _apply(
      manifest,
      'cinematicLibraryEntry.setArchived',
      const {
        'family': 'world',
        'cinematicId': 'world-second',
        'isArchived': true,
      },
    );

    expect(
      () => _apply(
        manifest,
        'cinematicLibraryFolder.delete',
        const {'folderId': 'nested'},
      ),
      throwsA(
        isA<CinematicLibraryAuthoringException>().having(
          (error) => error.code,
          'code',
          'cinematic_library.folder_not_empty',
        ),
      ),
    );

    manifest = _apply(
      manifest,
      'cinematicLibraryEntry.remove',
      const {'family': 'world', 'cinematicId': 'world-second'},
    );
    manifest = _apply(
      manifest,
      'cinematicLibraryFolder.delete',
      const {'folderId': 'nested'},
    );
    manifest = _apply(
      manifest,
      'cinematicLibraryFolder.delete',
      const {'folderId': 'temporary'},
    );

    expect(
      manifest.cinematicLibraryCatalog.folders.map((folder) => folder.id),
      isNot(containsAll(<String>['nested', 'temporary'])),
    );
  });

  test('reports placement removal as a semantic remove diff', () {
    final snapshot = _snapshot();
    final draft = const CinematicLibraryActions().build(
      AuthoringPlanningContext(
        snapshot: snapshot,
        request: AuthoringRequest(
          requestId: 'remove-placement',
          actionId: 'cinematicLibraryEntry.remove',
          actionVersion: 1,
          workspaceHandle: 'workspace-cinematic-library',
          parameters: const {
            'family': 'world',
            'cinematicId': 'world-intro',
          },
          expectedRevision: snapshot.revision,
          idempotencyKey: 'remove-placement',
        ),
        planId: 'plan-remove-placement',
        seed: 1,
      ),
    );

    expect(
      draft.changeSet.diff.entries.single.operation,
      AuthoringDiffOperation.remove,
    );
  });

  test('fails closed on v6 and unknown cinematic identities', () {
    final v6 = ProjectManifest(
      name: 'V6',
      version: ProjectVersion.v6,
      maps: const [],
      tilesets: const [],
    );

    expect(
      () => _apply(
        v6,
        'cinematicLibraryFolder.create',
        const {
          'folderId': 'folder',
          'family': 'world',
          'name': 'Folder',
          'parentFolderId': null,
          'targetIndex': 0,
        },
      ),
      throwsA(
        isA<CinematicLibraryAuthoringException>().having(
          (error) => error.code,
          'code',
          'cinematic_library.project_v7_required',
        ),
      ),
    );
    expect(
      () => _apply(
        _snapshot().manifest,
        'cinematicLibraryEntry.place',
        const {
          'family': 'presentation',
          'cinematicId': 'missing',
          'targetFolderId': 'opening-folder',
          'targetIndex': 0,
        },
      ),
      throwsA(
        isA<CinematicLibraryAuthoringException>().having(
          (error) => error.code,
          'code',
          'cinematic_library.asset_unknown',
        ),
      ),
    );
  });
}

ProjectSnapshot _snapshot({ProjectManifest? manifest}) {
  final effectiveManifest = manifest ??
      ProjectManifest(
        name: 'Cinematic library',
        version: ProjectVersion.v7,
        maps: const [],
        tilesets: const [],
        cinematics: [
          CinematicAsset(
            id: 'world-intro',
            title: 'World intro',
            timeline: CinematicTimeline(),
          ),
          CinematicAsset(
            id: 'world-second',
            title: 'World second',
            timeline: CinematicTimeline(),
          ),
        ],
        presentationCinematics: [
          PresentationCinematicAsset(
            id: 'presentation-intro',
            title: 'Presentation intro',
            durationUs: 1000000,
          ),
        ],
        cinematicLibraryCatalog: CinematicLibraryCatalog(
          folders: [
            CinematicLibraryFolder(
              id: 'world-folder',
              family: CinematicLibraryFamily.world,
              name: 'World',
              sortOrder: 0,
            ),
            CinematicLibraryFolder(
              id: 'opening-folder',
              family: CinematicLibraryFamily.presentation,
              name: 'Openings',
              sortOrder: 0,
            ),
          ],
          entries: [
            CinematicLibraryEntry(
              family: CinematicLibraryFamily.world,
              cinematicId: 'world-intro',
              folderId: 'world-folder',
              sortOrder: 0,
            ),
            CinematicLibraryEntry(
              family: CinematicLibraryFamily.presentation,
              cinematicId: 'presentation-intro',
              folderId: 'opening-folder',
              sortOrder: 0,
            ),
          ],
        ),
      );
  final bytes = utf8.encode(jsonEncode(effectiveManifest.toJson()));
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_cinematic_library'),
    revision: 'sha256:${List<String>.filled(64, 'c').join()}',
    manifest: effectiveManifest,
    maps: const [],
    resourceFingerprints: {
      'project': computeAuthoringBytesFingerprint(
        bytes,
        logicalName: 'project.json',
      ),
    },
    resourceBytes: {'project': bytes},
  );
}

ProjectManifest _apply(
  ProjectManifest manifest,
  String actionId,
  Map<String, Object?> parameters,
) {
  final snapshot = _snapshot(manifest: manifest);
  final draft = const CinematicLibraryActions().build(
    AuthoringPlanningContext(
      snapshot: snapshot,
      request: AuthoringRequest(
        requestId: 'request-$actionId',
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: 'workspace-cinematic-library',
        parameters: parameters,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'idempotency-$actionId',
      ),
      planId: 'plan-cinematic-library',
      seed: 1,
    ),
  );
  return ProjectManifest.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
          as Map,
    ),
  );
}
