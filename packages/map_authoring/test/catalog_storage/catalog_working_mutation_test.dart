import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_working_mutation.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('project translation compares stored index pages once', () async {
    final project = ProjectManifest(
      name: 'Before',
      maps: [],
      tilesets: [
        for (var i = 0; i < 400; i++)
          ProjectTilesetEntry(
              id: 'tile-$i', name: 'Tile $i', relativePath: 'tile.png')
      ],
      resourceLibraryCatalog: ResourceLibraryCatalog(entries: [
        for (var i = 0; i < 400; i++)
          ResourceLibraryEntry(
              resourceKind: 'tileset',
              resourceId: 'tile-$i',
              description: 'Known tile')
      ]),
    );
    final next = project.copyWith(
      name: 'After',
      tilesets: project.tilesets.take(399).toList(),
      resourceLibraryCatalog: ResourceLibraryCatalog(
          entries: project.resourceLibraryCatalog.entries
              .where((entry) => entry.resourceId != 'tile-399')
              .toList()),
    );
    final built = PortableCatalogPublication.encodeProject(project);
    final reads = <String, int>{};
    final storage = await CatalogSnapshot.open(
      root: built.storage.root,
      readObject: (reference) async {
        reads.update(reference.sha256, (count) => count + 1, ifAbsent: () => 1);
        return built.storage.objects[reference.sha256]!;
      },
    );
    final catalog = await PortableProjectCatalog.fromSnapshot(storage);
    final revision = 'sha256:${'a' * 64}';
    final resource = AuthoringResourceRef(kind: 'project', id: 'project');
    final plan = AuthoringPlan(
      planId: 'test-plan',
      receiptId: 'test-receipt',
      baseRevision: revision,
      request: AuthoringRequest(
          requestId: 'test',
          actionId: 'map.create',
          actionVersion: 1,
          workspaceHandle: 'workspace',
          expectedRevision: revision,
          idempotencyKey: 'test'),
      seed: 0,
      createdAt: DateTime.utc(2026),
      expiresAt: DateTime.utc(2027),
      changeSet: AuthoringChangeSet(
        changes: [
          AuthoringResourceChange(
              resource: resource,
              storageKey: 'project.json',
              beforeBytes: utf8.encode(jsonEncode(project.toJson())),
              afterBytes: utf8.encode(jsonEncode(next.toJson())))
        ],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
              operation: AuthoringDiffOperation.replace,
              resource: resource,
              path: '/name',
              before: 'Before',
              after: 'After')
        ]),
      ),
    );
    addTearDown(plan.releasePayloads);
    final snapshot = ProjectSnapshot(
      projectHandle: const ProjectHandle('project'),
      revision: revision,
      manifest: project,
      materializedCatalogProject: true,
      maps: [],
      resourceFingerprints: {},
      resourceStorageKeys: {},
    );
    reads.clear();
    final translated = await CatalogWorkingMutation.translate(
      catalog: catalog,
      snapshot: snapshot,
      publicPlan: plan,
    );
    expect(translated.projectedProject.toJson(), next.toJson());
    expect(translated.removals.toSet(), {
      CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'tile-399'),
      CatalogDefinitionKey(
          CatalogDefinitionKind.resourceLibraryEntry, 'tileset:tile-399'),
    });
    expect(
        translated.upserts
            .any((unit) => unit.key.kind == CatalogDefinitionKind.tileset),
        isFalse);
    final indexCount = built.storage.objects.values
        .where((bytes) => const {'root', 'branch', 'leaf'}
            .contains((jsonDecode(utf8.decode(bytes)) as Map)['type']))
        .length;
    expect(reads.values.fold<int>(0, (sum, count) => sum + count),
        lessThan(indexCount * 16));
  });
}
