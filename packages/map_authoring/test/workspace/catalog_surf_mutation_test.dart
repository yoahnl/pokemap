import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final unrelated in [0, 2000]) {
    test(
        'Surf first and repeated edits use bounded settings scope with $unrelated unrelated records',
        () async {
      final h = await _Fixture.create(unrelated);
      addTearDown(h.close);
      final counts = <int>[];
      final timings = <Object?>[];
      for (var i = 0; i < 2; i++) {
        h.reader.paths.clear();
        final watch = Stopwatch()..start();
        final parameters = <String, Object?>{
          'configuration': {
            'enabled': true,
            'requiresKnownMove': i == 0,
            'accessMode': 'always',
            'speedCellsPerSecond': 4.0,
          }
        };
        final snapshot = await h.mutations.readWorkshopSnapshot(
            h.opened.projectHandle,
            actionId: 'surf.configure',
            parameters: parameters);
        expect(snapshot.availableProjectSections, {'settings'});
        expect(snapshot.manifest.maps, isEmpty);
        expect(snapshot.manifest.facts, isEmpty);
        expect(snapshot.manifest.tilesets, isEmpty);
        final scopeMs = watch.elapsedMilliseconds;
        final plan = await h.mutations.planMutation(
            h.opened.projectHandle,
            AuthoringRequest(
              requestId: 'surf-$i',
              idempotencyKey: 'surf-$i',
              actionId: 'surf.configure',
              actionVersion: 1,
              workspaceHandle: h.opened.workspaceHandle.value,
              expectedRevision: snapshot.revision,
              parameters: parameters,
            ));
        final planMs = watch.elapsedMilliseconds - scopeMs;
        await h.mutations.applyMutation(h.opened.projectHandle,
            planId: plan.planId, operationId: 'surf-$i');
        timings.add({
          'scopeMs': scopeMs,
          'planMs': planMs,
          'applyMs': watch.elapsedMilliseconds - scopeMs - planMs,
          'totalMs': watch.elapsedMilliseconds
        });
        counts.add(h.reader.paths.length);
        expect(h.reader.paths.where(h.unrelatedObjects.contains), isEmpty);
        expect(
            h.reader.paths.where((path) =>
                path.startsWith('maps/') || path.startsWith('assets/')),
            isEmpty);
        expect(await File('${h.root.path}/project.json').readAsBytes(),
            h.descriptorBytes);
        final reopened = await h.mutations.readWorkshopSnapshot(
            h.opened.projectHandle,
            actionId: 'surf.configure');
        expect(reopened.manifest.settings.toJson()['surf'],
            parameters['configuration']);
      }
      expect(counts.every((count) => count < 220), isTrue, reason: '$counts');
      print(jsonEncode({
        'surfUnrelated': unrelated,
        'reads': counts,
        'firstRepeatedMs': timings
      }));
      if (unrelated > 0) {
        h.reader.paths.clear();
        final page = await h.read.queryProject(
            h.opened.projectHandle,
            AuthoringQueryRequest(
              resourceKind: 'fact',
              operation: AuthoringQueryOperation.list,
              pageSize: 12,
            ));
        expect(page.items, hasLength(12));
        expect(page.totalAvailable, 2000);
        expect(page.nextCursor, isNotNull);
        expect(h.reader.paths.where(h.unrelatedObjects.contains), isEmpty);
        expect(h.reader.paths.length, lessThan(65));
      }
    },
        timeout: const Timeout(Duration(minutes: 8)),
        skip: unrelated > 0 &&
                Platform.environment['AVELUNE_SURF_LARGE_SCOPE'] != '1'
            ? 'Opt-in local 2000-record fixture'
            : false);
  }
}

final class _Fixture {
  _Fixture(this.root, this.opened, this.handles, this.mutations, this.read,
      this.reader, this.descriptorBytes, this.unrelatedObjects);
  final Directory root;
  final OpenedProject opened;
  final WorkspaceHandleStore handles;
  final LocalMapAuthoringMutationApi mutations;
  final AuthoringReadApi read;
  final _CountingReader reader;
  final List<int> descriptorBytes;
  final Set<String> unrelatedObjects;

  static Future<_Fixture> create(int unrelated) async {
    final qa =
        Directory('/Users/karim/Library/Caches/AveluneQA/surf-v1/authoring');
    await qa.create(recursive: true);
    final root = await qa.createTemp('catalog-');
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final working = await WorkingProjectCatalog.create(
        store: store,
        projectId: 'surf',
        project: ProjectManifest(
          name: 'Surf',
          maps: [
            for (var i = 0; i < (unrelated == 0 ? 0 : 2); i++)
              ProjectMapEntry(
                  id: 'map-$i', name: 'Map $i', relativePath: 'maps/$i.json')
          ],
          tilesets: [
            for (var i = 0; i < (unrelated == 0 ? 0 : 1); i++)
              ProjectTilesetEntry(
                  id: 'asset-$i',
                  name: 'Asset $i',
                  relativePath: 'assets/$i.png')
          ],
          facts: [
            for (var i = 0; i < unrelated; i++)
              NarrativeFactDefinition(id: 'fact-$i', label: 'Fact $i')
          ],
        ));
    final objects = <String>{};
    if (unrelated > 0) {
      final entry = (await working.catalog.snapshot.indexEntry(
          CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'asset-0')))!;
      final path = 'catalog/objects/${entry.reference.sha256}.json';
      objects.add(path);
      await File('${root.path}/$path')
          .writeAsString('Unrelated resource must never be decoded');
    }
    final reader = _CountingReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        catalogMetadataFields: {});
    final opened = await opener.openProject(root.path);
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final mutations = LocalMapAuthoringMutationApi(
        policy: policy, snapshotLoader: snapshots, catalogFileReader: reader);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _Fixture(
        root,
        opened,
        handles,
        mutations,
        AuthoringReadApi(openService: opener, snapshotLoader: snapshots),
        reader,
        await File('${root.path}/project.json').readAsBytes(),
        objects);
  }

  Future<void> close() async {
    await mutations.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}

final class _CountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  final delegate = const LocalProjectFileReader();
  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<List<int>> readBytes(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.readBytes(
        projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  bool get supportsStreamingResources => true;
  @override
  Stream<List<int>> openRead(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.openRead(
        projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) =>
      delegate.probeResource(
          projectRoot: projectRoot, relativePath: relativePath);
}
