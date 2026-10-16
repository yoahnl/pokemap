import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;

final class _ReattestedWarpFiles implements SourceFilePort {
  const _ReattestedWarpFiles(this.delegate, this.fileId, this.bytes);
  final SourceFilePort delegate;
  final ConverterId fileId;
  final List<int> bytes;
  @override
  Future<List<int>> read(ConverterId id) =>
      id == fileId ? Future.value(List.of(bytes)) : delegate.read(id);
}

Future<({NormalizedSourceProject source, SourceFilePort files})>
    reattestExternalWarpLiteral(NormalizedSourceProject source,
        SourceFilePort files, int mapId, String before, String after) async {
  final archive = source.archive.files.values.singleWhere(
      (file) => file.entry.relativePath == 'Data/Map$mapId.rxdata');
  final old = utf8.encode(before), replacement = utf8.encode(after);
  if (old.length > 122 || replacement.length > 122) {
    throw ArgumentError('A short source literal is required.');
  }
  final pattern = [0x22, old.length + 5, ...old];
  final offset =
      List.generate(archive.rawBytes.length - pattern.length + 1, (i) => i)
          .firstWhere((i) => List.generate(pattern.length, (j) => j)
              .every((j) => archive.rawBytes[i + j] == pattern[j]));
  final bytes = [
    ...archive.rawBytes.take(offset),
    0x22,
    replacement.length + 5,
    ...replacement,
    ...archive.rawBytes.skip(offset + pattern.length)
  ];
  final entry = archive.entry;
  final snapshot = SourceSnapshot(
      logicalProjectNamespace: source.snapshot.logicalProjectNamespace,
      policyHash: source.snapshot.policyHash,
      entries: [
        for (final current in source.snapshot.entries)
          if (current.fileId != entry.fileId)
            current
          else
            SourceFileEntry(
                fileId: entry.fileId,
                relativePath: entry.relativePath,
                kind: entry.kind,
                byteLength: bytes.length,
                sha256: Sha256Hash(crypto.sha256.convert(bytes).toString()),
                format: entry.format,
                family: entry.family)
      ],
      diagnostics: source.snapshot.diagnostics,
      excludedPaths: source.snapshot.excludedPaths,
      profileEvidence: source.snapshot.profileEvidence,
      state: source.snapshot.state);
  final changed = _ReattestedWarpFiles(files, entry.fileId, bytes);
  final normalized = await const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: changed,
      selectedMapIds: {98, 100, 102, 166, 205},
      includeEventSystem: true,
      includeConnections: true);
  return (source: normalized, files: changed);
}
