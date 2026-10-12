import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';

import '../test/support/literal_tile_fixture.dart';
import '../test/support/native_writer_fixture.dart';
import 'native_writer_probe.dart' show sourceFileHashes;

Future<void> main(List<String> arguments) async {
  if (arguments.length != 3 ||
      arguments[0] != '--offline' ||
      arguments[1] != '--parent' ||
      !arguments[2].startsWith('/')) {
    stderr.writeln(
        'Usage: literal-tile-probe --offline --parent ABSOLUTE_EXISTING_DIRECTORY');
    exitCode = 64;
    return;
  }
  final parent = await Directory(arguments[2]).resolveSymbolicLinks();
  final qualification =
      await Directory(parent).createTemp('ac06-original-qualification-');
  final sourcePath = '${qualification.path}/original-source';
  await LiteralTileFixture.create(
    namespace: 'original-ac06-literal-qualification',
    sourceRootPath: sourcePath,
    maps: [
      LiteralFixtureMap(
        id: 1,
        width: 3,
        height: 3,
        layers: const [
          [384, 391, 392, 0, 384, 0, 392, 391, 384],
          [0, 0, 0, 0, 391, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
        ],
      ),
    ],
  );
  final before = await sourceFileHashes(sourcePath);
  final sourceTree = await MacOsSourceTree.open(sourcePath);
  try {
    final snapshot = await SourceScanner().scan(
      source: sourceTree,
      logicalProjectNamespace:
          ConverterId('original-ac06-literal-qualification'),
    );
    final files =
        await SnapshotSourceFiles.bind(source: sourceTree, snapshot: snapshot);
    final normalized = await const RmxpSourceNormalizer()
        .normalize(snapshot: snapshot, files: files);
    final composition = await const LiteralTileComposer().compose(
      source: normalized,
      files: files,
      selectedSourceMapIds: const [1],
      projectName: 'Original literal tile qualification',
      parentPath: qualification.path,
      folderName: 'converted-literal-fixture',
      sourceRootPath: sourcePath,
    );
    final draft = composition.draft;
    if (draft == null ||
        composition.playableCertified ||
        composition.diagnostics.any((value) => value.blocksPlanning)) {
      throw StateError(
          'Controlled fixture composition failed: ${jsonEncode(composition.diagnostics.map((value) => value.toJson()).toList())}');
    }
    await files.verifyUnchanged();
    final admission = approveNativeFixtureDraft(
      draft,
      selectedSourceMapIds: composition.selectedSourceMapIds,
      dependencySourceMapIds: composition.includedSourceMapIds
          .where((id) => !composition.selectedSourceMapIds.contains(id))
          .toList(),
    );
    final receipt = await const NativeProjectWriter()
        .write(admission.plan, admission.context, draft);
    await files.verifyUnchanged();
    final after = await sourceFileHashes(sourcePath);
    final unchanged = jsonEncode(before) == jsonEncode(after);
    if (!unchanged || !receipt.verified || receipt.published) {
      throw StateError('Controlled literal tile qualification failed');
    }
    stdout.writeln(jsonEncode({
      'schemaVersion': 1,
      'lot': 'AC-06',
      'proofKind': 'literalTileAotOriginalFixture',
      'offline': true,
      'controlledQualificationFixture': true,
      'humanProductionApproval': false,
      'playableCertified': composition.playableCertified,
      'qualificationRoot': qualification.path,
      'sourceRoot': sourcePath,
      'sourceProfileState': snapshot.profile.state.name,
      'sourceSnapshotHash': snapshot.canonicalHash.value,
      'normalizedSourceHash': normalized.canonicalHash.value,
      'sourceFileHashes': before,
      'sourceUnchanged': unchanged,
      'compositionHash': composition.compositionHash.value,
      'draftHash': receipt.draftHash.value,
      'projectPath': receipt.projectPath,
      'stagingRoot': receipt.stagingRoot,
      'verified': receipt.verified,
      'published': receipt.published,
      'nativeRevision': receipt.nativeRevision,
      'mapIds': {
        for (final entry in composition.mapIds.entries)
          entry.key.toString(): entry.value,
      },
      'mapHashes':
          receipt.mapHashes.map((id, hash) => MapEntry(id, hash.value)),
      'assetHashes':
          receipt.assetHashes.map((id, hash) => MapEntry(id, hash.value)),
      'crops': composition.crops.map((crop) => crop.toJson()).toList(),
      'layerProvenance':
          composition.layerProvenance.map((layer) => layer.toJson()).toList(),
      'dependencies':
          composition.dependencies.map((value) => value.toJson()).toList(),
      'diagnostics':
          composition.diagnostics.map((value) => value.toJson()).toList(),
    }));
  } finally {
    await sourceTree.close();
  }
}
