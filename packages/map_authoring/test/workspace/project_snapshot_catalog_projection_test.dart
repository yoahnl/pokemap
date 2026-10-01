import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../domains/maps/map_metadata_fixture.dart';

void main() {
  test('folder and title post-images retain the complete cached snapshot',
      () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final before = await f.snapshots.load(f.opened.projectHandle);
    final manifest = before.manifest.copyWith(groups: const [
      ProjectMapGroup(
          id: 'folder', name: 'Village', type: MapGroupType.village),
    ], maps: [
      before.manifest.maps.single
          .copyWith(groupId: 'folder', name: 'Village été')
    ]);
    final map = before.maps.single.copyWith(name: 'Village été');
    final changes = [
      change(
          before, 'project', encodeProjectAuthoringDocument(before, manifest)),
      change(before, 'map:town', encodeMapAuthoringDocument(map)),
    ];
    final projected =
        const ProjectSnapshotMapProjector().project(before, changes);
    expect(projected, isNotNull);
    expect(projected!.manifest, manifest);
    expect(projected.mapById('town'), map);
    expect(projected.resourceStorageKeys, before.resourceStorageKeys);
    expect(projected.pokemonInventoryComplete, before.pokemonInventoryComplete);
    for (final edit in changes) {
      await File('${f.root.path}/${edit.storageKey}')
          .writeAsBytes(edit.afterBytes!);
    }
    final reread = await f.snapshots.load(f.opened.projectHandle);
    expect(projected.revision, reread.revision);
    expect(projected.resourceFingerprints, reread.resourceFingerprints);
    expect(projected.manifest, reread.manifest);
  });

  test('folder-only post-image reuses unchanged map objects and bytes',
      () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final before = await f.snapshots.load(f.opened.projectHandle);
    final manifest = before.manifest.copyWith(groups: const [
      ProjectMapGroup(
          id: 'folder', name: 'Village', type: MapGroupType.village),
    ]);
    final projected = const ProjectSnapshotMapProjector().project(before, [
      change(
          before, 'project', encodeProjectAuthoringDocument(before, manifest)),
    ]);
    expect(projected, isNotNull);
    expect(identical(projected!.maps.single, before.maps.single), isTrue);
    expect(
        projected.resourceBytes('map:town'), before.resourceBytes('map:town'));
    expect(projected.manifest, manifest);
  });

  test(
      'unrelated manifests, new identities and paths require the strict loader',
      () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final before = await f.snapshots.load(f.opened.projectHandle);
    for (final manifest in [
      before.manifest.copyWith(name: 'Other project'),
      before.manifest
          .copyWith(settings: before.manifest.settings.copyWith(tileWidth: 32)),
      before.manifest.copyWith(maps: []),
      before.manifest
          .copyWith(maps: [before.manifest.maps.single.copyWith(id: 'other')]),
      before.manifest.copyWith(maps: [
        before.manifest.maps.single.copyWith(relativePath: 'maps/other.json')
      ]),
      before.manifest.copyWith(
          maps: [before.manifest.maps.single.copyWith(role: MapRole.interior)]),
    ]) {
      expect(
          const ProjectSnapshotMapProjector().project(before, [
            change(before, 'project',
                encodeProjectAuthoringDocument(before, manifest)),
          ]),
          isNull);
    }
    final rawSettings = jsonDecode(utf8.decode(before.resourceBytes('project')))
        as Map<String, dynamic>;
    (rawSettings['settings'] as Map)['unmodeled'] = {
      'dependencies': ['new']
    };
    expect(
        const ProjectSnapshotMapProjector().project(before, [
          change(before, 'project', utf8.encode(jsonEncode(rawSettings))),
        ]),
        isNull);
    final raw = jsonDecode(utf8.decode(before.resourceBytes('project')))
        as Map<String, dynamic>;
    raw['unsupported'] = {
      'references': ['external']
    };
    expect(
        const ProjectSnapshotMapProjector().project(before, [
          change(before, 'project', utf8.encode(jsonEncode(raw))),
        ]),
        isNull);
  });

  test('invalid folder relationships and projection bindings are refused',
      () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final before = await f.snapshots.load(f.opened.projectHandle);
    final manifest = before.manifest.copyWith(groups: const [
      ProjectMapGroup(
          id: 'folder',
          name: 'Village',
          parentGroupId: 'folder',
          type: MapGroupType.village),
    ]);
    expect(
        const ProjectSnapshotMapProjector().project(before, [
          change(before, 'project',
              encodeProjectAuthoringDocument(before, manifest)),
        ]),
        isNull);
    expect(
        () => before.projectMapResources(
              revision: before.revision,
              manifest: before.manifest.copyWith(maps: [
                before.manifest.maps.single
                    .copyWith(relativePath: 'other.json'),
              ]),
              maps: before.maps,
              resourceFingerprints: before.resourceFingerprints,
              replacementBytes: const {},
            ),
        throwsArgumentError);
  });

  test('stale pre-images and duplicate manifest changes are not adopted',
      () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final before = await f.snapshots.load(f.opened.projectHandle);
    final manifest = before.manifest.copyWith(groups: const [
      ProjectMapGroup(
          id: 'folder', name: 'Village', type: MapGroupType.village),
    ]);
    final edit = change(
        before, 'project', encodeProjectAuthoringDocument(before, manifest));
    expect(const ProjectSnapshotMapProjector().project(before, [edit, edit]),
        isNull);
    expect(
        const ProjectSnapshotMapProjector().project(before, [
          AuthoringResourceChange(
              resource: AuthoringResourceRef(kind: 'project', id: 'project'),
              storageKey: edit.storageKey,
              beforeBytes: [0],
              afterBytes: edit.afterBytes),
        ]),
        isNull);
  });
}

AuthoringResourceChange change(
        ProjectSnapshot snapshot, String identity, List<int> bytes) =>
    AuthoringResourceChange(
        resource: AuthoringResourceRef(
            kind: identity == 'project' ? 'project' : 'map',
            id: identity == 'project' ? 'project' : identity.substring(4),
            revision: snapshot.resourceFingerprints[identity]),
        storageKey: snapshot.resourceStorageKeys[identity]!,
        beforeBytes: snapshot.resourceBytes(identity),
        afterBytes: bytes);
