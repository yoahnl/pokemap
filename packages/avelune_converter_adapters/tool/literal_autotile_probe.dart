import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';

import '../test/support/literal_tile_fixture.dart';
import '../test/support/native_writer_fixture.dart';
import '../test/support/original_autotile_fixture.dart';
import 'native_writer_probe.dart' show sourceFileHashes;

Future<void> main(List<String> arguments) async {
  if (arguments.length != 5 ||
      arguments[0] != '--offline' ||
      arguments[1] != '--parent' ||
      !arguments[2].startsWith('/') ||
      arguments[3] != '--scripts' ||
      !arguments[4].startsWith('/')) {
    stderr.writeln(
        'Usage: literal-autotile-probe --offline --parent ABSOLUTE_EXISTING_DIRECTORY --scripts ABSOLUTE_SCRIPTS_ARCHIVE');
    exitCode = 64;
    return;
  }
  final scripts = await File(arguments[4]).readAsBytes();
  if (literalFixtureHash(scripts).value !=
      fixtureSourceInterpretationProfile.scriptsArchiveHash.value) {
    throw StateError(
        'This qualification requires the pinned source clock archive.');
  }
  final parent = await Directory(arguments[2]).resolveSymbolicLinks();
  final root =
      await Directory(parent).createTemp('ac07-original-qualification-');
  final sourcePath = '${root.path}/original-source';
  final raster = OriginalAutotileFixture.standard();
  await LiteralTileFixture.create(interpretationProfile: fixtureSourceInterpretationProfile,

      namespace: 'original-ac07-literal-qualification',
      sourceRootPath: sourcePath,
      scriptsBytes: scripts,
      maps: [
        LiteralFixtureMap(id: 1, width: 8, height: 6, layers: [
          List.generate(48, (index) => index + 48),
          List.generate(48, (index) => index == 0 ? 79 : 0),
          List.filled(48, 0)
        ])
      ],
      tilesets: [
        LiteralFixtureTileset(id: 1, autotileNames: const ['OriginalWater'])
      ],
      autotilePngs: {
        'OriginalWater': raster.pngBytes
      });
  final before = await sourceFileHashes(sourcePath);
  final tree = await MacOsSourceTree.open(sourcePath);
  try {
    final snapshot = await SourceScanner().scan(
        source: tree,
        logicalProjectNamespace:
            ConverterId('original-ac07-literal-qualification'));
    final files =
        await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
    final normalized = await const RmxpSourceNormalizer()
        .normalize(snapshot: snapshot, files: files, interpretationProfile: fixtureSourceInterpretationProfile);
    final composition = await const LiteralTileComposer().compose(
        source: normalized,
        files: files,
        selectedSourceMapIds: const [1],
        projectName: 'Original autotile animation qualification',
        parentPath: root.path,
        folderName: 'converted-autotile-fixture',
        sourceRootPath: sourcePath);
    if (!composition.canWrite ||
        composition.autotiles.length != 1 ||
        composition.autotiles.single.degraded) {
      throw StateError(
          'Controlled animated fixture failed: ${jsonEncode(composition.diagnostics.map((value) => value.toJson()).toList())}');
    }
    final auto = composition.autotiles.single;
    if (!auto.animationVerified ||
        auto.sourceFrameCount != 3 ||
        auto.frameDurationMs != 250 ||
        auto.tileAnimations.length != 48) {
      throw StateError(
          'Controlled fixture did not preserve its attested timeline.');
    }
    await files.verifyUnchanged();
    final admission = approveNativeFixtureDraft(composition.draft!);
    final receipt = await const NativeProjectWriter()
        .write(admission.plan, admission.context, composition.draft!);
    await files.verifyUnchanged();
    final after = await sourceFileHashes(sourcePath);
    final unchanged = jsonEncode(before) == jsonEncode(after);
    if (!unchanged ||
        !receipt.verified ||
        receipt.published ||
        composition.playableCertified) {
      throw StateError('Controlled animated native qualification failed.');
    }
    stdout.writeln(jsonEncode({
      'schemaVersion': 1,
      'lot': 'AC-07',
      'proofKind': 'literalAutotileOriginalFixture',
      'offline': true,
      'controlledQualificationFixture': true,
      'humanProductionApproval': false,
      'playableCertified': false,
      'sourceRoot': sourcePath,
      'qualificationRoot': root.path,
      'sourceUnchanged': unchanged,
      'sourceFileHashes': before,
      'sourceSnapshotHash': snapshot.canonicalHash.value,
      'compositionHash': composition.compositionHash.value,
      'draftHash': receipt.draftHash.value,
      'projectPath': receipt.projectPath,
      'stagingRoot': receipt.stagingRoot,
      'verified': receipt.verified,
      'published': receipt.published,
      'nativeRevision': receipt.nativeRevision,
      'mapIds': composition.mapIds.map((id, value) => MapEntry('$id', value)),
      'nativeTilesetId': auto.nativeTilesetId,
      'sourceFrameCount': auto.sourceFrameCount,
      'variantCount': 48,
      'frameDurationMs': auto.frameDurationMs,
      'animationVerified': auto.animationVerified,
      'autotileProvenance': auto.provenance,
      'degraded': auto.degraded,
      'mapHashes':
          receipt.mapHashes.map((id, hash) => MapEntry(id, hash.value)),
      'assetHashes':
          receipt.assetHashes.map((id, hash) => MapEntry(id, hash.value)),
    }));
  } finally {
    await tree.close();
  }
}
