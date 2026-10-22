import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import 'support/native_writer_fixture.dart';

void main() {
  const mib = 1024 * 1024;

  test('separates logical assets and retained blobs at both byte boundaries',
      () {
    final catalog = AssetCatalog(records: [
      for (var index = 0; index < 8; index++) _declaredRecord(index, 64 * mib),
    ]);
    expect(NativeStudyVerifier.validateAssetBudget(catalog),
        (logicalAssetBytes: 512 * mib, retainedBlobBytes: 512 * mib));
  });

  test('logical aliases retain one blob and cannot exceed the logical budget',
      () {
    final artifact = _declaredRecord(0, 64 * mib).artifact;
    final records = [
      for (var index = 0; index < 8; index++)
        _declaredRecord(index, 64 * mib, artifact: artifact)
    ];
    final budget =
        NativeStudyVerifier.validateAssetBudget(AssetCatalog(records: records));
    expect(budget, (logicalAssetBytes: 512 * mib, retainedBlobBytes: 64 * mib));
    expect(
        budget.retainedBlobBytes, lessThanOrEqualTo(budget.logicalAssetBytes));
    expect(
        () => NativeStudyVerifier.validateAssetBudget(AssetCatalog(records: [
              ...records,
              _declaredRecord(8, 1),
            ])),
        throwsA(_failureContaining('logical assets')));
  });

  test('asset budget preserves the exact per-artifact byte ceiling', () {
    expect(
        () => NativeStudyVerifier.validateAssetBudget(AssetCatalog(records: [
              _declaredRecord(0, 64 * mib + 1),
            ])),
        throwsA(_failureContaining('64 MiB')));
  });

  test('logical paths may name the same exact retained blob', () {
    final record = _declaredRecord(0, 64 * mib);
    final alias =
        record.copyWith(logicalPath: assetBlobStorageKey(record.artifact));
    expect(
        NativeStudyVerifier.validateAssetBudget(AssetCatalog(records: [alias])),
        (logicalAssetBytes: 64 * mib, retainedBlobBytes: 64 * mib));
  });

  test('one retained blob may serve references with distinct media types', () {
    final first = _declaredRecord(0, 32);
    final second = _declaredRecord(1, 32,
        artifact: ContentArtifactRef(
            digest: first.artifact.digest,
            mediaType: 'application/json',
            byteLength: first.artifact.byteLength));
    expect(
        NativeStudyVerifier.validateAssetBudget(
            AssetCatalog(records: [first, second])),
        (logicalAssetBytes: 64, retainedBlobBytes: 32));
  });

  test('asset budget refuses conflicting identities on a shared storage key',
      () {
    final first = _declaredRecord(0, 32);
    final second = _declaredRecord(1, 32);
    expect(
        () => NativeStudyVerifier.validateAssetBudget(AssetCatalog(records: [
              first.copyWith(logicalPath: assetBlobStorageKey(second.artifact)),
              second,
            ])),
        throwsA(_failureContaining('conflicting content identities')));
    expect(
        () => NativeStudyVerifier.validateAssetBudget(AssetCatalog(records: [
              first,
              _declaredRecord(1, 33,
                  artifact: ContentArtifactRef(
                      digest: first.artifact.digest,
                      mediaType: first.artifact.mediaType,
                      byteLength: 33)),
            ])),
        throwsA(_failureContaining('conflicting content identities')));
  });

  test('asset budget honors cancellation before traversing records', () {
    final cancellation = ScanCancellation()..cancel();
    expect(
        () => NativeStudyVerifier.validateAssetBudget(AssetCatalog(),
            cancellation: cancellation),
        throwsA(isA<ContractError>()
            .having((error) => error.code, 'code', 'source.cancelled')));
  });

  test('logical record ceiling remains independent from maps and blob count',
      () {
    expect(NativeStudyVerifier.maxLogicalAssetRecords, 16384);
    expect(
        () => NativeStudyVerifier.validateInventory(
            logicalAssetCount: 16384, mapCount: 4096),
        returnsNormally);
    expect(
        () => NativeStudyVerifier.validateInventory(
            logicalAssetCount: 16385, mapCount: 1),
        throwsA(isA<ConverterWorkflowFailure>()
            .having((error) => error.code, 'code', 'native.verify.failed')
            .having((error) => error.message, 'message',
                contains('logical asset records'))));
    expect(
        () => NativeStudyVerifier.validateInventory(
            logicalAssetCount: 1, mapCount: 4097),
        throwsA(isA<ConverterWorkflowFailure>()
            .having((error) => error.message, 'message', contains('maps'))));
  });

  test('read-only verification admits 513 logical aliases of one retained blob',
      () async {
    final root =
        await Directory.systemTemp.createTemp('native-verify-aliases-');
    try {
      final created = await Directory('${root.path}/output').create();
      final output = Directory(await created.resolveSymbolicLinks());
      final fixture = await NativeWriterFixture.create(output.path,
          sourceRootPath: '${root.path}/source');
      final result = await const NativeProjectWriter()
          .write(fixture.plan, fixture.context, fixture.draft);
      final catalogFile = File('${result.projectPath}/$assetCatalogStorageKey');
      final catalog = AssetCatalog.fromJson(
          jsonDecode(await catalogFile.readAsString()) as Map<String, dynamic>);
      final original = catalog.records.single;
      final records = [original];
      for (var index = 1; index <= 512; index++) {
        final alias = AssetRecord(
            id: 'alias_$index',
            logicalPath: 'assets/aliases/$index.png',
            artifact: original.artifact);
        final file = File('${result.projectPath}/${alias.logicalPath}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(fixture.atlasBytes);
        records.add(alias);
      }
      await catalogFile
          .writeAsString(jsonEncode(AssetCatalog(records: records).toJson()));
      expect(records.map((record) => record.artifact.handle).toSet(),
          {original.artifact.handle});
      final blobs =
          await Directory('${result.projectPath}/assets/.pokemap-store')
              .list(recursive: true)
              .where((entry) => entry is File)
              .toList();
      expect(blobs, hasLength(1));
      final before = await _tree(result.projectPath);
      const verifier = NativeStudyVerifier();
      final first = await verifier.verify(
          projectPath: result.projectPath, allowedParentPath: output.path);
      final second = await verifier.verify(
          projectPath: result.projectPath, allowedParentPath: output.path);
      expect(first.assetCount, 513);
      expect(first.mapCount, 1);
      expect(second.nativeRevision, first.nativeRevision);
      expect(second.assetCount, first.assetCount);
      expect(await _tree(result.projectPath), before);
      expect(first.playableCertified, isFalse);
      final aliasFile = File('${result.projectPath}/assets/aliases/1.png');
      final aliasBytes = await aliasFile.readAsBytes();
      await aliasFile.writeAsBytes([...aliasBytes]..[0] ^= 1);
      await expectLater(
          verifier.verify(
              projectPath: result.projectPath, allowedParentPath: output.path),
          throwsA(isA<ConverterWorkflowFailure>()
              .having((error) => error.code, 'code', 'native.verify.failed')));
      await aliasFile.writeAsBytes(aliasBytes);
      final blob = blobs.single as File;
      final blobBytes = await blob.readAsBytes();
      await blob.writeAsBytes([...blobBytes]..[0] ^= 1);
      await expectLater(
          verifier.verify(
              projectPath: result.projectPath, allowedParentPath: output.path),
          throwsA(isA<ConverterWorkflowFailure>()
              .having((error) => error.code, 'code', 'native.verify.failed')));
      await blob.writeAsBytes(blobBytes);
      expect(await _tree(result.projectPath), before);
    } finally {
      await root.delete(recursive: true);
    }
  }, skip: !Platform.isMacOS);
}

AssetRecord _declaredRecord(int index, int byteLength,
        {ContentArtifactRef? artifact}) =>
    AssetRecord(
        id: 'asset_$index',
        logicalPath: 'assets/test/$index.bin',
        artifact: artifact ??
            ContentArtifactRef(
                digest: 'sha256:${index.toRadixString(16).padLeft(64, '0')}',
                mediaType: 'application/octet-stream',
                byteLength: byteLength));

Matcher _failureContaining(String text) => isA<ConverterWorkflowFailure>()
    .having((error) => error.code, 'code', 'native.verify.failed')
    .having((error) => error.message, 'message', contains(text));

Future<Map<String, List<int>>> _tree(String root) async => {
      await for (final file in Directory(root).list(recursive: true))
        if (file is File)
          file.path.substring(root.length + 1): await file.readAsBytes()
    };
