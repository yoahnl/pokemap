import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
      'native revision observations are bounded and released with their handles',
      () async {
    final h = await _AudioHarness.create(
        catalog: false, unrelated: 0, legacyReadable: true);
    addTearDown(h.close);
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [h.root.path], fileReader: h.reader);
    final service = ProjectOpenService(
        policy: policy,
        fileReader: h.reader,
        handles: h.handles,
        workshopScope: true);
    final workspaces = <WorkspaceHandle>[];
    try {
      for (var i = 0; i < 10; i++) {
        final opened = await service.openProject(h.root.path);
        workspaces.add(opened.workspaceHandle);
        await h.snapshots.load(opened.projectHandle);
        expect(h.snapshots.retainedNativeRevisionCount, lessThanOrEqualTo(8));
      }
      expect(h.snapshots.retainedNativeRevisionCount, 8);
    } finally {
      for (final workspace in workspaces) {
        h.handles.closeWorkspace(workspace);
      }
    }
    expect(h.snapshots.retainedNativeRevisionCount, 0);
  });
  for (final changed in ['project', 'media', 'target', 'disappeared']) {
    test('native full revision refuses changed $changed dependencies',
        () async {
      final h = await _AudioHarness.create(
          catalog: false, unrelated: 0, legacyReadable: true);
      addTearDown(h.close);
      final artifact =
          await h.api.artifacts.put(_wav(), declaredMediaType: 'audio/wav');
      final assets = File('${h.root.path}/$assetCatalogStorageKey');
      if (changed == 'disappeared') {
        await assets.parent.create(recursive: true);
        await assets.writeAsString(jsonEncode(AssetCatalog().toJson()));
      }
      final full = await h.snapshots.load(h.opened.projectHandle);
      if (changed == 'project') {
        final file = File('${h.root.path}/project.json');
        final json = jsonDecode(await file.readAsString()) as Map;
        json['name'] = 'Concurrent author';
        await file.writeAsString(jsonEncode(json));
      } else if (changed == 'media') {
        final file = File('${h.root.path}/$projectMediaCatalogStorageKey');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(
            encodeProjectMediaCatalogBytes(ProjectMediaCatalog()));
      } else if (changed == 'target') {
        await assets.parent.create(recursive: true);
        await assets.writeAsString(jsonEncode(AssetCatalog(records: [
          AssetRecord(
              id: 'legacy',
              logicalPath: 'assets/audio/legacy.wav',
              artifact: artifact.reference)
        ]).toJson()));
      } else {
        await assets.delete();
      }
      h.reader.paths.clear();
      await expectLater(
          h.api.planMutation(
              h.opened.projectHandle,
              AuthoringRequest(
                  requestId: 'legacy',
                  actionId: 'presentationMedia.import',
                  actionVersion: 1,
                  workspaceHandle: h.opened.workspaceHandle.value,
                  expectedRevision: full.revision,
                  idempotencyKey: 'legacy',
                  parameters: {
                    'artifactHandle': artifact.reference.handle,
                    'assetId': 'legacy',
                    'mediaId': 'legacy',
                    'label': 'Legacy',
                    'kind': 'audio',
                    'logicalPath': 'assets/audio/legacy.wav',
                  })),
          throwsA(isA<AuthoringPlanException>()
              .having((e) => e.code, 'code', 'plan.stale')));
      expect(h.reader.paths.where((path) => path.startsWith('maps/')), isEmpty);
    });
  }
  test(
      'equal revisions from another origin are not trusted without a same handle observation',
      () async {
    final a = await _AudioHarness.create(
        catalog: false, unrelated: 0, legacyReadable: true);
    addTearDown(a.close);
    final b = await _AudioHarness.create(
        catalog: false,
        unrelated: 0,
        legacyReadable: true,
        sharedHandles: a.handles,
        sharedSnapshots: a.snapshots);
    addTearDown(b.close);
    final full = await a.snapshots.load(a.opened.projectHandle);
    final artifact =
        await b.api.artifacts.put(_wav(), declaredMediaType: 'audio/wav');
    b.reader.paths.clear();
    await expectLater(
        b.api.planMutation(
            b.opened.projectHandle,
            AuthoringRequest(
                requestId: 'foreign',
                actionId: 'presentationMedia.import',
                actionVersion: 1,
                workspaceHandle: b.opened.workspaceHandle.value,
                expectedRevision: full.revision,
                idempotencyKey: 'foreign',
                parameters: {
                  'artifactHandle': artifact.reference.handle,
                  'assetId': 'legacy',
                  'mediaId': 'legacy',
                  'label': 'Legacy',
                  'kind': 'audio',
                  'logicalPath': 'assets/audio/legacy.wav',
                })),
        throwsA(isA<AuthoringPlanException>()
            .having((e) => e.code, 'code', 'plan.stale')));
    expect(b.reader.paths.where((path) => path.startsWith('maps/')), isEmpty);
  });
  test(
      'an observed native full revision remains compatible with a scoped import',
      () async {
    final h = await _AudioHarness.create(
        catalog: false, unrelated: 0, legacyReadable: true);
    addTearDown(h.close);
    final artifact =
        await h.api.artifacts.put(_wav(), declaredMediaType: 'audio/wav');
    final parameters = <String, Object?>{
      'artifactHandle': artifact.reference.handle,
      'assetId': 'legacy',
      'mediaId': 'legacy',
      'label': 'Legacy',
      'kind': 'audio',
      'logicalPath': 'assets/audio/legacy.wav'
    };
    final full = await h.snapshots.load(h.opened.projectHandle);
    final scoped = await h.api.readWorkshopSnapshot(h.opened.projectHandle,
        actionId: 'presentationMedia.import', parameters: parameters);
    expect(full.revision, isNot(scoped.revision));
    h.reader.paths.clear();
    final plan = await h.api.planMutation(
        h.opened.projectHandle,
        AuthoringRequest(
            requestId: 'legacy',
            actionId: 'presentationMedia.import',
            actionVersion: 1,
            workspaceHandle: h.opened.workspaceHandle.value,
            expectedRevision: full.revision,
            idempotencyKey: 'legacy',
            parameters: parameters));
    final applied = await h.api.applyMutation(h.opened.projectHandle,
        planId: plan.planId, operationId: 'legacy');
    final replayed = await h.api.applyMutation(h.opened.projectHandle,
        planId: plan.planId, operationId: 'legacy');
    expect(replayed.toJson(), applied.toJson());
    expect(h.reader.paths.where((path) => path.startsWith('maps/')), isEmpty);
  });
  for (final catalog in [false, true]) {
    for (final unrelated in [0, 2000]) {
      test(
          'audio imports are scoped and reversible catalog=$catalog unrelated=$unrelated',
          () async {
        final h =
            await _AudioHarness.create(catalog: catalog, unrelated: unrelated);
        addTearDown(h.close);
        final initialProject =
            await File('${h.root.path}/project.json').readAsBytes();
        final counts = <int>[];
        String? receiptId;
        for (var i = 0; i < 2; i++) {
          final artifact =
              await h.api.artifacts.put(_wav(), declaredMediaType: 'audio/wav');
          final parameters = <String, Object?>{
            'artifactHandle': artifact.reference.handle,
            'assetId': 'sound-$i',
            'mediaId': 'sound-$i',
            'label': 'Sound $i',
            'kind': 'audio',
            'logicalPath': 'assets/audio/sound-$i.wav',
          };
          h.reader.paths.clear();
          final snapshot = await h.api.readWorkshopSnapshot(
              h.opened.projectHandle,
              actionId: 'presentationMedia.import',
              parameters: parameters);
          expect(snapshot.maps, isEmpty);
          expect(snapshot.manifest.cinematicMediaAssets, isEmpty);
          expect(snapshot.manifest.facts, isEmpty);
          final plan = await h.api.planMutation(
              h.opened.projectHandle,
              AuthoringRequest(
                  requestId: 'import-$i',
                  actionId: 'presentationMedia.import',
                  actionVersion: 1,
                  workspaceHandle: h.opened.workspaceHandle.value,
                  expectedRevision: snapshot.revision,
                  idempotencyKey: 'import-$i',
                  parameters: parameters));
          expect(plan.plan.changeSet.changes.length,
              (i == 0 ? 3 : 2) + (catalog ? 1 : 0));
          final applied = await h.api.applyMutation(h.opened.projectHandle,
              planId: plan.planId, operationId: 'import-$i');
          receiptId = applied.receipt.receiptId;
          counts.add(h.reader.paths.length);
          expect(h.reader.paths.where((path) => path.startsWith('maps/')),
              isEmpty);
          expect(h.reader.paths.where(h.unrelatedPaths.contains), isEmpty);
          expect(h.reader.paths.length, lessThan(240));
          expect(await File('${h.root.path}/project.json').readAsBytes(),
              initialProject);
        }
        final media = decodeProjectMediaCatalogBytes(
            await File('${h.root.path}/$projectMediaCatalogStorageKey')
                .readAsBytes());
        expect(media.entries.map((entry) => entry.id), ['sound-0', 'sound-1']);
        expect(media.entries.first.technicalMetadata!.mediaType, 'audio/wav');
        final fresh = await h.api.readWorkshopSnapshot(h.opened.projectHandle,
            actionId: 'project.audio.cue.configure',
            parameters: const {
              'cueId': 'ui.confirm',
              'binding': {'source': 'custom', 'mediaId': 'sound-0', 'gain': .4},
            });
        expect(fresh.maps, isEmpty);
        await h.api.undoMutation(h.opened.projectHandle,
            entryId: receiptId!, idempotencyKey: 'undo-import');
        expect(
            decodeProjectMediaCatalogBytes(
                    await File('${h.root.path}/$projectMediaCatalogStorageKey')
                        .readAsBytes())
                .entries
                .map((entry) => entry.id),
            ['sound-0']);
        final gainReads = <int>[];
        final savedAssets =
            await File('${h.root.path}/$assetCatalogStorageKey').readAsBytes();
        final savedMedia =
            await File('${h.root.path}/$projectMediaCatalogStorageKey')
                .readAsBytes();
        for (final gain in [.4, .6]) {
          final parameters = <String, Object?>{
            'cueId': 'ui.confirm',
            'binding': {'source': 'custom', 'mediaId': 'sound-0', 'gain': gain}
          };
          h.reader.paths.clear();
          final scoped = await h.api.readWorkshopSnapshot(
              h.opened.projectHandle,
              actionId: 'project.audio.cue.configure',
              parameters: parameters);
          final plan = await h.api.planMutation(
              h.opened.projectHandle,
              AuthoringRequest(
                  requestId: 'gain-$gain',
                  actionId: 'project.audio.cue.configure',
                  actionVersion: 1,
                  workspaceHandle: h.opened.workspaceHandle.value,
                  expectedRevision: scoped.revision,
                  idempotencyKey: 'gain-$gain',
                  parameters: parameters));
          await h.api.applyMutation(h.opened.projectHandle,
              planId: plan.planId, operationId: 'gain-$gain');
          gainReads.add(h.reader.paths.length);
          expect(
              h.reader.paths.where(
                  (path) => path.startsWith('maps/') || path.endsWith('.blob')),
              isEmpty);
          expect(h.reader.paths.where(h.unrelatedPaths.contains), isEmpty);
          expect(h.reader.paths.length, lessThan(240));
        }
        expect(
            await File('${h.root.path}/$assetCatalogStorageKey').readAsBytes(),
            savedAssets);
        expect(
            await File('${h.root.path}/$projectMediaCatalogStorageKey')
                .readAsBytes(),
            savedMedia);
        print(jsonEncode({
          'audioImportCatalog': catalog,
          'unrelated': unrelated,
          'reads': counts,
          'customGainReads': gainReads
        }));
      },
          timeout: const Timeout(Duration(minutes: 8)),
          skip: unrelated > 0 &&
                  Platform.environment['AVELUNE_AUDIO_LARGE_SCOPE'] != '1'
              ? 'Opt-in local 2000-record scope proof'
              : false);
    }
  }
}

final class _AudioHarness {
  _AudioHarness(this.root, this.api, this.opened, this.handles, this.reader,
      this.unrelatedPaths, this.snapshots);
  final Directory root;
  final LocalMapAuthoringMutationApi api;
  final OpenedProject opened;
  final WorkspaceHandleStore handles;
  final _Reader reader;
  final Set<String> unrelatedPaths;
  final ProjectSnapshotLoader snapshots;

  static Future<_AudioHarness> create(
      {required bool catalog,
      required int unrelated,
      bool legacyReadable = false,
      WorkspaceHandleStore? sharedHandles,
      ProjectSnapshotLoader? sharedSnapshots}) async {
    final qa =
        Directory('/Users/karim/Library/Caches/AveluneQA/surf-v1/authoring');
    await qa.create(recursive: true);
    final root = await qa.createTemp('audio-import-');
    final project = ProjectManifest(name: 'Audio', maps: const [
      ProjectMapEntry(
          id: 'foreign', name: 'Foreign', relativePath: 'maps/foreign.json')
    ], tilesets: [
      if (!legacyReadable)
        const ProjectTilesetEntry(
            id: 'foreign', name: 'Foreign', relativePath: 'assets/foreign.png')
    ], facts: [
      for (var i = 0; i < unrelated; i++)
        NarrativeFactDefinition(id: 'fact-$i', label: 'Fact $i')
    ]);
    final unrelatedPaths = <String>{'maps/foreign.json', 'assets/foreign.png'};
    if (catalog) {
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      final working = await WorkingProjectCatalog.create(
          store: store, projectId: 'audio', project: project);
      final entry = (await working.catalog.snapshot.indexEntry(
          CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'foreign')))!;
      final path = 'catalog/objects/${entry.reference.sha256}.json';
      unrelatedPaths.add(path);
      await File('${root.path}/$path')
          .writeAsString('Unrelated asset must never be decoded');
    } else {
      final raw = project.toJson();
      if (!legacyReadable) {
        raw['cinematicMediaAssets'] = [
          {'unrelated-invalid': true}
        ];
      }
      await File('${root.path}/project.json').writeAsString(jsonEncode(raw));
      if (legacyReadable) {
        final map = File('${root.path}/maps/foreign.json');
        await map.parent.create(recursive: true);
        await map.writeAsString(jsonEncode(MapData(
                id: 'foreign',
                name: 'Foreign',
                size: const GridSize(width: 3, height: 3))
            .toJson()));
      }
    }
    final reader = _Reader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = sharedHandles ?? WorkspaceHandleStore();
    final opened = await ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        workshopScope: true,
        catalogMetadataFields: {}).openProject(root.path);
    final snapshots =
        sharedSnapshots ?? ProjectSnapshotLoader(handles: handles);
    final api = LocalMapAuthoringMutationApi(
        policy: policy, snapshotLoader: snapshots, catalogFileReader: reader);
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    await api.prepareWorkshopCatalog(opened.projectHandle);
    return _AudioHarness(
        root, api, opened, handles, reader, unrelatedPaths, snapshots);
  }

  Future<void> close() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}

final class _Reader
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

List<int> _wav() {
  final bytes = Uint8List(1644);
  final view = ByteData.sublistView(bytes);
  void text(int offset, String value) =>
      bytes.setRange(offset, offset + value.length, ascii.encode(value));
  text(0, 'RIFF');
  view.setUint32(4, bytes.length - 8, Endian.little);
  text(8, 'WAVE');
  text(12, 'fmt ');
  view.setUint32(16, 16, Endian.little);
  view.setUint16(20, 1, Endian.little);
  view.setUint16(22, 1, Endian.little);
  view.setUint32(24, 8000, Endian.little);
  view.setUint32(28, 16000, Endian.little);
  view.setUint16(32, 2, Endian.little);
  view.setUint16(34, 16, Endian.little);
  text(36, 'data');
  view.setUint32(40, bytes.length - 44, Endian.little);
  return bytes;
}
