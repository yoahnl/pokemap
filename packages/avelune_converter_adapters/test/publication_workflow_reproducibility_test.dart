import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';
import 'support/native_reproducibility.dart';

const _authoringRoot = '.pokemap/authoring/';
const _ledgerPath = '.pokemap/authoring/idempotency.jsonl';

void main() {
  test('PUB-04 identical approved conversion writes identical native data',
      () async {
    final root = await Directory.systemTemp.createTemp('ac15-pub04-original-');
    try {
      final output = await Directory('${root.path}/output').create();
      final source = await LiteralTileFixture.create(
          sourceRootPath: '${root.path}/source',
          maps: [LiteralFixtureMap(id: 1), LiteralFixtureMap(id: 8)]);
      final sourceBefore = await readNativeStudyTree(source.sourceRootPath!);
      final composition = await const LiteralTileComposer().compose(
          source: source.source,
          files: source.files,
          selectedSourceMapIds: const [1, 8],
          projectName: 'Original reproducible native study',
          parentPath: output.path,
          folderName: 'original-pub04-study',
          sourceRootPath: source.sourceRootPath);
      expect(composition.canWrite, isTrue);
      final draft = composition.draft!;
      final approved = approveNativeFixtureDraft(draft);
      final inputHashes = [
        draft.canonicalHash,
        approved.plan.canonicalHash,
        approved.context.sourceSnapshotHash,
        approved.context.targetCapabilities.canonicalHash,
        approved.context.decisions.canonicalHash
      ];
      final createdBytes = <Map<String, List<int>>>[];
      final writer =
          NativeProjectWriter(checkpoint: (stage, _, projectPath) async {
        if (stage == NativeWriteStage.afterCreation) {
          createdBytes.add({
            for (final entry
                in (await readNativeStudyTree(projectPath!)).entries)
              if (!entry.key.startsWith(_authoringRoot)) entry.key: entry.value
          });
        }
      });
      final first = await writer.write(approved.plan, approved.context, draft);
      final second = await writer.write(approved.plan, approved.context, draft);
      expect(createdBytes, hasLength(2));
      expect(createdBytes.first, createdBytes.last);
      expect(first.stagingRoot, isNot(second.stagingRoot));
      expect(first.projectPath, isNot(second.projectPath));
      expect(first.draftHash, second.draftHash);
      expect(first.nativeRevision, second.nativeRevision);
      expect(first.mapHashes, second.mapHashes);
      expect(first.assetHashes, second.assetHashes);
      expect(first.creationInventoryFingerprint,
          second.creationInventoryFingerprint);
      expect(first.creationTransactionReceipt.extensions['operationId'],
          isNot(second.creationTransactionReceipt.extensions['operationId']));
      expect(first.importUndoHistoryRetained, isFalse);
      expect(second.importUndoHistoryRetained, isFalse);
      expect(first.published, isFalse);
      expect(second.published, isFalse);
      expect(await Directory('${output.path}/${draft.folderName}').exists(),
          isFalse);
      final firstBytes = await readNativeStudyTree(first.projectPath);
      final secondBytes = await readNativeStudyTree(second.projectPath);
      final fingerprint = first.creationInventoryFingerprint;
      expect(recoverNativeCreationBytes(firstBytes, fingerprint),
          createdBytes.first);
      expect(recoverNativeCreationBytes(secondBytes, fingerprint),
          createdBytes.last);
      assertCanonicalNativeEquality(firstBytes, secondBytes, fingerprint);
      final compared = await compareNativeStudyDirectories(
          leftProjectPath: first.projectPath,
          rightProjectPath: second.projectPath,
          allowedParentPath: output.path,
          expectedInventoryFingerprint: fingerprint);
      expect(compared.left.nativeRevision, first.nativeRevision);
      expect(compared.right.nativeRevision, second.nativeRevision);
      expect(compared.fileCount, firstBytes.length);
      expect(compared.toJson()['publicationTransactionsPerOutput'], 1);
      expect(compared.toJson()['equal'], isTrue);
      expect(firstBytes.keys, unorderedEquals(secondBytes.keys));
      for (final receipt in [first, second]) {
        const reader = LocalProjectFileReader();
        final policy = await WorkspacePolicy.create(
            allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
        final handles = WorkspaceHandleStore();
        final opener = ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles);
        final opened = await opener.openProject(receipt.projectPath);
        try {
          final native = await ProjectSnapshotLoader(handles: handles).load(
              opened.projectHandle,
              policy: ProjectSnapshotLoadPolicy.strict);
          expect(native.revision, receipt.nativeRevision);
          expect(native.loadDiagnostics, isEmpty);
          for (final map in composition.nativeMaps.values) {
            expect(native.mapById(map.id), map);
          }
        } finally {
          opener.closeWorkspace(opened.workspaceHandle);
        }
      }
      void rejects(Map<String, List<int>> changed) => expect(
          () => assertCanonicalNativeEquality(firstBytes, changed, fingerprint),
          throwsFormatException);
      rejects({
        ...secondBytes,
        'project.json': [...secondBytes['project.json']!, 32]
      });
      final blob = secondBytes.keys.firstWhere((key) => key.endsWith('.blob'));
      rejects({
        ...secondBytes,
        blob: [...secondBytes[blob]!, 0]
      });
      rejects({...secondBytes}..remove(blob));
      rejects({
        ...secondBytes,
        '${_authoringRoot}unlisted.log': const [1]
      });
      rejects({
        ...secondBytes,
        '${_authoringRoot}transactions/write.lock': const [1]
      });
      rejects({...secondBytes}..remove(_ledgerPath));
      expect(
          () => recoverNativeCreationBytes(secondBytes, 'sha256:${'0' * 64}'),
          throwsFormatException);
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (record) => record['operationId'] = 'native-creation-0-0',
        (record) => _object(record['scope'])['actorId'] = 'other-actor',
        (record) => record['payloadFingerprint'] = 'sha256:${'0' * 64}',
        (record) =>
            _object(record['receipt'])['afterRevision'] = 'sha256:${'0' * 64}',
        (record) => _object(_object(record['receipt'])['extensions'])[
            'inventoryFingerprint'] = 'sha256:${'0' * 64}',
      ]) {
        final events = _jsonLines(secondBytes[_ledgerPath]!);
        mutate(_object(events.last['record']));
        rejects({...secondBytes, _ledgerPath: _encodeLines(events)});
      }
      final events = _jsonLines(secondBytes[_ledgerPath]!);
      for (final forgeId in [true, false]) {
        final forged = _jsonLines(secondBytes[_ledgerPath]!);
        final rawReceipt = _object(_object(forged.last['record'])['receipt']);
        final rawDiff = _object(rawReceipt['diff']);
        final rawEntry = (rawDiff['entries'] as List).map(_object).firstWhere(
            (entry) => _object(entry['resource'])['kind'] == 'project');
        final rawResource = _object(rawEntry['resource']);
        if (forgeId) {
          rawResource['id'] = 'project-another-operation';
        } else {
          rawResource['extensions'] = {'forged': true};
        }
        final diff = AuthoringDiff.fromJson(rawDiff);
        rawReceipt['affectedResources'] = [
          for (final resource in diff.affectedResources) resource.toJson()
        ];
        rawReceipt['beforeRevision'] = AuthoringRevisionSet([
          for (final entry in diff.entries)
            AuthoringResourceRevision(resource: entry.resource, revision: null)
        ]).fingerprint;
        rawReceipt['afterRevision'] = AuthoringRevisionSet([
          for (final entry in diff.entries)
            AuthoringResourceRevision(
                resource: entry.resource,
                revision: computeAuthoringBytesFingerprint(
                    secondBytes[entry.resource.kind == 'project'
                        ? 'project.json'
                        : entry.resource.id]!,
                    logicalName: entry.resource.kind == 'project'
                        ? 'project.json'
                        : entry.resource.id))
        ]).fingerprint;
        rejects({...secondBytes, _ledgerPath: _encodeLines(forged)});
      }
      rejects({
        ...secondBytes,
        _ledgerPath: _encodeLines([...events, events.last])
      });
      expect(await readNativeStudyTree(first.projectPath), firstBytes);
      expect(await readNativeStudyTree(second.projectPath), secondBytes);
      expect(await readNativeStudyTree(source.sourceRootPath!), sourceBefore);
      expect([
        draft.canonicalHash,
        approved.plan.canonicalHash,
        approved.context.sourceSnapshotHash,
        approved.context.targetCapabilities.canonicalHash,
        approved.context.decisions.canonicalHash
      ], inputHashes);
    } finally {
      await root.delete(recursive: true);
    }
  }, skip: !Platform.isMacOS);
}

List<Map<String, dynamic>> _jsonLines(List<int> bytes) => utf8
    .decode(bytes)
    .trimRight()
    .split('\n')
    .map((line) => _object(jsonDecode(line)))
    .toList();
List<int> _encodeLines(List<Map<String, dynamic>> events) =>
    utf8.encode('${events.map(canonicalAuthoringJson).join('\n')}\n');
Map<String, dynamic> _object(Object? value) => value as Map<String, dynamic>;
