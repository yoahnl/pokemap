import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import 'support/native_writer_fixture.dart';

void main() {
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
    } finally {
      await root.delete(recursive: true);
    }
  }, skip: !Platform.isMacOS);
}

Future<Map<String, List<int>>> _tree(String root) async => {
      await for (final file in Directory(root).list(recursive: true))
        if (file is File)
          file.path.substring(root.length + 1): await file.readAsBytes()
    };
