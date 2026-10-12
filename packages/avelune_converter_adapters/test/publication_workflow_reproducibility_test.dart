import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';
import 'support/native_reproducibility.dart';

const _authoringRoot = '.pokemap/authoring/';
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
        approved.context.decisions.canonicalHash,
      ];
      final bootstrapBytes = <Map<String, List<int>>>[];
      final writer =
          NativeProjectWriter(checkpoint: (stage, _, projectPath) async {
        if (stage == NativeWriteStage.afterBootstrap) {
          final files = await readNativeStudyTree(projectPath!);
          bootstrapBytes.add({
            for (final entry in files.entries)
              if (!entry.key.startsWith(_authoringRoot)) entry.key: entry.value
          });
        }
      });
      final first = await writer.write(approved.plan, approved.context, draft);
      final second = await writer.write(approved.plan, approved.context, draft);
      expect(bootstrapBytes, hasLength(2));
      expect(bootstrapBytes.first, bootstrapBytes.last);
      expect(first.stagingRoot, isNot(second.stagingRoot));
      expect(first.projectPath, isNot(second.projectPath));
      expect(first.draftHash, second.draftHash);
      expect(first.nativeRevision, second.nativeRevision);
      expect(first.mapHashes, second.mapHashes);
      expect(first.assetHashes, second.assetHashes);
      expect(first.published, isFalse);
      expect(second.published, isFalse);
      expect(await Directory('${output.path}/${draft.folderName}').exists(),
          isFalse);
      final firstBytes = await readNativeStudyTree(first.projectPath);
      final secondBytes = await readNativeStudyTree(second.projectPath);
      final expectedOperations = draft.mutations
          .map((mutation) => mutation.operationId.value)
          .toList(growable: false);
      expect(recoverNativeBootstrapBytes(firstBytes, expectedOperations),
          bootstrapBytes.first);
      expect(recoverNativeBootstrapBytes(secondBytes, expectedOperations),
          bootstrapBytes.last);
      assertCanonicalNativeEquality(
          firstBytes, secondBytes, expectedOperations, bootstrapBytes.first);
      assertCanonicalNativeEquality(
          firstBytes, secondBytes, expectedOperations);
      final compared = await compareNativeStudyDirectories(
          leftProjectPath: first.projectPath,
          rightProjectPath: second.projectPath,
          allowedParentPath: output.path,
          expectedOperationIds: expectedOperations);
      expect(compared.left.nativeRevision, first.nativeRevision);
      expect(compared.right.nativeRevision, second.nativeRevision);
      expect(compared.fileCount, firstBytes.length);
      expect(compared.toJson()['equal'], isTrue);
      expect(firstBytes.keys, unorderedEquals(secondBytes.keys));
      expect(firstBytes.length, secondBytes.length);
      expect(
          firstBytes.keys.where((name) =>
              name.startsWith('${_authoringRoot}blobs/') &&
              name.endsWith('.blob')),
          isNotEmpty);
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
      final changedNative = {...secondBytes};
      changedNative['project.json'] = [...secondBytes['project.json']!, 32];
      expect(
          () => assertCanonicalNativeEquality(firstBytes, changedNative,
              expectedOperations, bootstrapBytes.first),
          throwsFormatException);
      final blob = secondBytes.keys
          .firstWhere((name) => name.startsWith('${_authoringRoot}blobs/'));
      final changedBlob = {...secondBytes};
      changedBlob[blob] = [...secondBytes[blob]!, 0];
      expect(
          () => assertCanonicalNativeEquality(firstBytes, changedBlob,
              expectedOperations, bootstrapBytes.first),
          throwsFormatException);
      final unexpectedMetadata = {...secondBytes};
      unexpectedMetadata['${_authoringRoot}unlisted.log'] = const [1];
      expect(
          () => assertCanonicalNativeEquality(firstBytes, unexpectedMetadata,
              expectedOperations, bootstrapBytes.first),
          throwsFormatException);
      final changedBootstrapReceipt = {...secondBytes};
      final ledger =
          _jsonLines(secondBytes['${_authoringRoot}idempotency.jsonl']!);
      final bootstrapReceipt = _object(_object(ledger[1]['record'])['receipt']);
      bootstrapReceipt['afterRevision'] = 'sha256:${'0' * 64}';
      changedBootstrapReceipt['${_authoringRoot}idempotency.jsonl'] =
          _encodeLines(ledger);
      expect(
          () => assertCanonicalNativeEquality(
              firstBytes,
              changedBootstrapReceipt,
              expectedOperations,
              bootstrapBytes.first),
          throwsFormatException);
      final history =
          _jsonLines(secondBytes['${_authoringRoot}history.jsonl']!);
      final firstChange = history
          .expand((event) =>
              (_object(_object(event['payload'])['entry'])['changes'] as List))
          .map(_object)
          .firstWhere((change) => change['storageKey'] == 'project.json');
      final preImageId = firstChange['beforeBlobId'] as String;
      final missingPreImage = {...secondBytes}
        ..remove('${_authoringRoot}blobs/${preImageId.substring(7)}.blob');
      expect(
          () =>
              recoverNativeBootstrapBytes(missingPreImage, expectedOperations),
          throwsFormatException);
      final changedPreImageRevision = {...secondBytes};
      firstChange['beforeRevision'] = 'sha256:${'0' * 64}';
      _rehashChain(history, 'authoring-history-event.json');
      changedPreImageRevision['${_authoringRoot}history.jsonl'] =
          _encodeLines(history);
      expect(
          () => recoverNativeBootstrapBytes(
              changedPreImageRevision, expectedOperations),
          throwsFormatException);
      expect(
          () => recoverNativeBootstrapBytes(
              secondBytes, expectedOperations.reversed.toList()),
          throwsFormatException);
      final invalidChain = {...secondBytes};
      final audit = _jsonLines(secondBytes['${_authoringRoot}audit.jsonl']!);
      (_object(audit.first['record']))['code'] = 'fixture.changed';
      invalidChain['${_authoringRoot}audit.jsonl'] = _encodeLines(audit);
      expect(
          () => assertCanonicalNativeEquality(firstBytes, invalidChain,
              expectedOperations, bootstrapBytes.first),
          throwsFormatException);
      final changedAudit = {...secondBytes};
      _rehashChain(audit, 'authoring-audit-event.json');
      changedAudit['${_authoringRoot}audit.jsonl'] = _encodeLines(audit);
      expect(
          () => assertCanonicalNativeEquality(firstBytes, changedAudit,
              expectedOperations, bootstrapBytes.first),
          throwsFormatException);
      expect(await readNativeStudyTree(first.projectPath), firstBytes);
      expect(await readNativeStudyTree(second.projectPath), secondBytes);
      expect(await readNativeStudyTree(source.sourceRootPath!), sourceBefore);
      expect([
        draft.canonicalHash,
        approved.plan.canonicalHash,
        approved.context.sourceSnapshotHash,
        approved.context.targetCapabilities.canonicalHash,
        approved.context.decisions.canonicalHash,
      ], inputHashes);
    } finally {
      await root.delete(recursive: true);
    }
  }, skip: !Platform.isMacOS);
}

void _rehashChain(List<Map<String, dynamic>> events, String logicalName) {
  String? previous;
  for (final event in events) {
    event['previousDigest'] = previous;
    final payload = {...event}..remove('digest');
    event['digest'] =
        computeAuthoringJsonFingerprint(payload, logicalName: logicalName);
    previous = event['digest'] as String;
  }
}

List<Map<String, dynamic>> _jsonLines(List<int> bytes) {
  final content = utf8.decode(bytes);
  _require(content.endsWith('\n'), 'Log is not completely flushed.');
  return content
      .substring(0, content.length - 1)
      .split('\n')
      .map((line) => _object(jsonDecode(line)))
      .toList(growable: false);
}

List<int> _encodeLines(List<Map<String, dynamic>> events) =>
    utf8.encode('${events.map(canonicalAuthoringJson).join('\n')}\n');

Map<String, dynamic> _object(Object? value) {
  _require(value is Map<String, dynamic>, 'Expected a JSON object.');
  return value as Map<String, dynamic>;
}

void _require(bool condition, String message) {
  if (!condition) throw FormatException(message);
}
