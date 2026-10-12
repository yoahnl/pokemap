import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:crypto/crypto.dart';

import '../test/support/native_writer_fixture.dart';

Future<Map<String, String>> sourceFileHashes(String root) async {
  final hashes = <String, String>{};
  await for (final entry
      in Directory(root).list(recursive: true, followLinks: false)) {
    if (entry is File) {
      hashes[entry.path.substring(root.length + 1)] =
          sha256.convert(await entry.readAsBytes()).toString();
    }
  }
  return Map.fromEntries(
      hashes.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
}

Future<void> main(List<String> arguments) async {
  if (arguments.length != 3 ||
      arguments[0] != '--offline' ||
      arguments[1] != '--parent' ||
      !arguments[2].startsWith('/')) {
    stderr.writeln(
        'Usage: native-writer-probe --offline --parent ABSOLUTE_EXISTING_DIRECTORY');
    exitCode = 64;
    return;
  }
  final parent = await Directory(arguments[2]).resolveSymbolicLinks();
  final qualification =
      await Directory(parent).createTemp('ac05-original-qualification-');
  final fixture = await NativeWriterFixture.create(qualification.path);
  final before = await sourceFileHashes(fixture.sourceRootPath);
  final receipt = await const NativeProjectWriter()
      .write(fixture.plan, fixture.context, fixture.draft);
  final after = await sourceFileHashes(fixture.sourceRootPath);
  final sourceUnchanged = jsonEncode(before) == jsonEncode(after);
  if (!sourceUnchanged || !receipt.verified || receipt.published) {
    throw StateError('Controlled native writer qualification failed');
  }
  stdout.writeln(jsonEncode({
    'schemaVersion': 1,
    'lot': 'AC-05',
    'proofKind': 'nativeWriterAotOriginalFixture',
    'offline': true,
    'controlledQualificationFixture': true,
    'humanProductionApproval': false,
    'qualificationRoot': qualification.path,
    'sourceRoot': fixture.sourceRootPath,
    'sourceSnapshotHash': fixture.source.snapshot.canonicalHash.value,
    'normalizedSourceHash': fixture.source.canonicalHash.value,
    'sourceFileHashes': before,
    'sourceUnchanged': sourceUnchanged,
    'projectPath': receipt.projectPath,
    'stagingRoot': receipt.stagingRoot,
    'verified': receipt.verified,
    'published': receipt.published,
    'draftHash': receipt.draftHash.value,
    'nativeRevision': receipt.nativeRevision,
    'mapId': fixture.expectedMap.id,
    'mapHashes': receipt.mapHashes.map((id, hash) => MapEntry(id, hash.value)),
    'assetHashes':
        receipt.assetHashes.map((id, hash) => MapEntry(id, hash.value)),
  }));
}
