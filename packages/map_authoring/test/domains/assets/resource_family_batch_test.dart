import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('families publish atomically with parents later in the same batch',
      () async {
    final snapshot = _snapshot();
    final draft = await _build(snapshot, [
      {
        'operation': 'create',
        'familyId': 'child',
        'name': 'Child',
        'parentId': 'parent'
      },
      {
        'operation': 'create',
        'familyId': 'parent',
        'name': 'Parent',
        'parentId': 'props'
      },
      {'operation': 'update', 'familyId': 'existing', 'name': 'Updated'},
    ]);
    expect(draft.changeSet.changes, hasLength(1));
    final result = _project(draft);
    final families = {
      for (final family in result.resourceLibraryCatalog.families)
        family.id: family
    };
    expect(families['child']!.parentId, 'parent');
    expect(families['existing']!.parentId, 'props');
    expect(families['keep']!.name, 'Keep');
    expect(result.resourceLibraryCatalog.entries,
        snapshot.manifest.resourceLibraryCatalog.entries);
    expect(result.maps, snapshot.manifest.maps);
    expect(snapshot.manifest.resourceLibraryCatalog.families, hasLength(2));
  });

  test('invalid second operation leaves all families unchanged', () async {
    final snapshot = _snapshot();
    final before = snapshot.manifest.toJson();
    await expectLater(
        _build(snapshot, [
          {'operation': 'create', 'familyId': 'new', 'name': 'New'},
          {'operation': 'update', 'familyId': 'absent', 'name': 'Missing'},
        ]),
        throwsA(isA<VisualLibraryException>().having((e) => e.code, 'code',
            'resource_library.family_unknown_or_duplicate')));
    expect(snapshot.manifest.toJson(), before);
  });

  test(
      'parent then child uses the final catalogue and rejects an invalid child atomically',
      () async {
    final snapshot = _snapshot();
    final parent = {
      'operation': 'create',
      'familyId': 'parent',
      'name': 'Parent'
    };
    final child = {
      'operation': 'create',
      'familyId': 'child',
      'name': 'Child',
      'parentId': 'parent'
    };
    final result = _project(await _build(snapshot, [parent, child]));
    expect(
        result.resourceLibraryCatalog.families
            .firstWhere((f) => f.id == 'child')
            .parentId,
        'parent');
    final before = snapshot.manifest.toJson();
    await expectLater(
        _build(snapshot, [
          parent,
          {...child, 'parentId': 'missing'}
        ]),
        throwsA(isA<VisualLibraryException>()
            .having((e) => e.code, 'code', 'resource_library.invalid')));
    expect(snapshot.manifest.toJson(), before);
  });

  test('duplicate input identities are rejected', () async {
    await expectLater(
        _build(_snapshot(), [
          {'operation': 'create', 'familyId': 'new', 'name': 'First'},
          {'operation': 'update', 'familyId': 'new', 'name': 'Second'},
        ]),
        throwsA(isA<VisualLibraryException>().having(
            (e) => e.code, 'code', 'resource_library.family_batch_duplicate')));
  });

  test('predefined identities, missing parents and cycles are rejected',
      () async {
    await expectLater(
        _build(_snapshot(), [
          {'operation': 'update', 'familyId': 'props', 'name': 'Renamed'},
        ]),
        throwsA(isA<VisualLibraryException>().having(
            (e) => e.code, 'code', 'resource_library.predefined_family')));
    for (final entries in [
      [
        {
          'operation': 'create',
          'familyId': 'new',
          'name': 'New',
          'parentId': 'absent'
        }
      ],
      [
        {
          'operation': 'create',
          'familyId': 'first',
          'name': 'First',
          'parentId': 'second'
        },
        {
          'operation': 'create',
          'familyId': 'second',
          'name': 'Second',
          'parentId': 'first'
        },
      ],
    ]) {
      await expectLater(
          _build(_snapshot(), entries),
          throwsA(isA<VisualLibraryException>()
              .having((e) => e.code, 'code', 'resource_library.invalid')));
    }
  });

  test('empty, over-limit and deletion batches are rejected', () async {
    for (final entries in [
      <Map<String, Object?>>[],
      [
        for (var i = 0; i < 51; i++)
          {'operation': 'create', 'familyId': 'family-$i', 'name': 'Family $i'}
      ],
      [
        {'operation': 'delete', 'familyId': 'existing', 'name': 'No'}
      ],
    ]) {
      await expectLater(
          _build(_snapshot(), entries),
          throwsA(isA<VisualLibraryException>().having(
              (e) => e.code, 'code', 'resource_library.family_batch_invalid')));
    }
  });

  test('50 entries are allowed and explicit null clears a parent', () async {
    final snapshot = _snapshot();
    final result = _project(await _build(snapshot, [
      {
        'operation': 'update',
        'familyId': 'existing',
        'name': 'Existing',
        'parentId': null
      },
      for (var i = 0; i < 49; i++)
        {'operation': 'create', 'familyId': 'family-$i', 'name': 'Family $i'},
    ]));
    expect(result.resourceLibraryCatalog.families, hasLength(51));
    expect(
        result.resourceLibraryCatalog.families
            .firstWhere((f) => f.id == 'existing')
            .parentId,
        isNull);
  });
}

Future<AuthoringMutationDraft> _build(
        ProjectSnapshot snapshot, List<Map<String, Object?>> entries) async =>
    await MapMutationDispatcher.canonical().build(AuthoringPlanningContext(
      snapshot: snapshot,
      request: AuthoringRequest(
          requestId: 'family-batch',
          actionId: 'resource.family.apply_batch',
          actionVersion: 1,
          workspaceHandle: 'workspace',
          expectedRevision: snapshot.revision,
          idempotencyKey: 'family-batch',
          parameters: {'families': entries}),
      planId: 'family-batch-plan',
      seed: 1,
    ));

ProjectManifest _project(AuthoringMutationDraft draft) =>
    ProjectManifest.fromJson(
      jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
          as Map<String, dynamic>,
    );

ProjectSnapshot _snapshot() {
  final manifest = ProjectManifest(
    name: 'Families batch',
    tilesets: const [],
    maps: const [
      ProjectMapEntry(id: 'garden', name: 'Garden', relativePath: 'garden.json')
    ],
    resourceLibraryCatalog: ResourceLibraryCatalog(families: [
      ResourceFamily(id: 'existing', name: 'Existing', parentId: 'props'),
      ResourceFamily(id: 'keep', name: 'Keep'),
    ]),
  );
  final bytes = utf8.encode(jsonEncode(manifest.toJson()));
  final revision = computeNarrativeProjectFingerprint([
    NarrativeProjectFingerprintEntry(
        relativePath: 'project.json', bytes: bytes),
  ]);
  return ProjectSnapshot(
      projectHandle: const ProjectHandle('family-batch-project'),
      revision: revision,
      manifest: manifest,
      maps: const [],
      resourceFingerprints: {'project': revision},
      resourceBytes: {'project': bytes});
}
