import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;

final class ExternalOriginalFiles implements SourceFilePort {
  ExternalOriginalFiles(this.snapshot, this.root,
      {this.overrideBytes = const {}});
  final SourceSnapshot snapshot;
  final String root;
  final Map<String, List<int>> overrideBytes;

  @override
  Future<List<int>> read(ConverterId id) async {
    final entry = snapshot.entries.singleWhere((entry) => entry.fileId == id);
    if (overrideBytes[entry.relativePath] case final replacement?) {
      return List.of(replacement);
    }
    return File('$root/${entry.relativePath}').readAsBytes();
  }
}

Future<({NormalizedSourceProject source, ExternalOriginalFiles files})>
    readExternalOriginalSource(String root, String snapshotPath,
        {Set<int> selectedMapIds = const {98, 100, 102, 166, 205},
        Map<String, List<int>> overrideBytes = const {}}) async {
  final input = jsonDecode(await File(snapshotPath).readAsString()) as Map;
  final snapshot = SourceSnapshot(
      logicalProjectNamespace:
          ConverterId(input['logicalProjectNamespace'] as String),
      policyHash: Sha256Hash(input['policyHash'] as String),
      entries: [
        for (final row in (input['entries'] as List).cast<Map>())
          SourceFileEntry(
              fileId: ConverterId(row['fileId'] as String),
              relativePath: row['relativePath'] as String,
              kind: SourceNodeKind.values.byName(row['kind'] as String),
              byteLength: overrideBytes[row['relativePath']]?.length ??
                  row['byteLength'] as int,
              sha256: row['sha256'] == null
                  ? null
                  : Sha256Hash(overrideBytes[row['relativePath']] == null
                      ? row['sha256'] as String
                      : crypto.sha256
                          .convert(overrideBytes[row['relativePath']]!)
                          .toString()),
              format: row['format'] as String,
              family: row['family'] as String)
      ],
      diagnostics: [],
      excludedPaths: (input['excludedPaths'] as List).cast<String>(),
      profileEvidence: [
        for (final row in (input['profileEvidence'] as List).cast<Map>())
          SourceProfileEvidence(
              relativePath: row['relativePath'] as String,
              fileHash: Sha256Hash(row['fileHash'] as String),
              version: row['version'] as String,
              line: row['line'] as int,
              excerpt: row['excerpt'] as String)
      ],
      state: SourceScanState.values.byName(input['state'] as String));
  final files =
      ExternalOriginalFiles(snapshot, root, overrideBytes: overrideBytes);
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: files,
      selectedMapIds: selectedMapIds,
      includeEventSystem: true);
  return (source: source, files: files);
}
