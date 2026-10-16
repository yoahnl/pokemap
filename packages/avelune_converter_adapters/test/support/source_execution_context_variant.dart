import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;

final class ReattestedExecutionFiles implements SourceFilePort {
  const ReattestedExecutionFiles(this.delegate, this.fileId, this.bytes);
  final SourceFilePort delegate;
  final ConverterId fileId;
  final List<int> bytes;
  @override
  Future<List<int>> read(ConverterId id) =>
      id == fileId ? Future.value(List.of(bytes)) : delegate.read(id);
}

Future<({NormalizedSourceProject source, SourceFilePort files})>
    reattestExecutionVariant(NormalizedSourceProject source,
        SourceFilePort files, String mutation) async {
  final archive = source.archive.files.values
      .singleWhere((file) => file.entry.relativePath == 'Data/Map205.rxdata');
  final document = archive.document;
  final bytes = List<int>.of(archive.rawBytes);
  MarshalNode field(MarshalNode node, String name) =>
      document.node(node.instanceVariables
          .singleWhere((pair) => document.node(pair.key).name == name)
          .value);
  final events = field(document.node(document.rootId), '@events');
  MarshalNode event(int id) => document.node(events.pairs
      .singleWhere(
          (pair) => document.node(pair.key).integerValue == BigInt.from(id))
      .value);
  MarshalNode page(int id) =>
      document.node(field(event(id), '@pages').elements.first);
  void integer(MarshalNode node, int value) {
    final offset = node.location.byteOffset;
    if (node.kind != MarshalKind.integer ||
        bytes[offset] != 0x69 ||
        bytes[offset + 1] !=
            (node.integerValue == BigInt.zero
                ? 0
                : node.integerValue!.toInt() + 5)) {
      throw StateError('Expected exact small integer bytes.');
    }
    bytes[offset + 1] = value == 0 ? 0 : value + 5;
  }

  switch (mutation) {
    case 'unguardedController':
      final guard = field(field(page(14), '@condition'), '@self_switch_valid');
      if (guard.kind != MarshalKind.boolean ||
          guard.booleanValue != true ||
          bytes[guard.location.byteOffset] != 0x54) {
        throw StateError('Expected true source guard.');
      }
      bytes[guard.location.byteOffset] = 0x46;
    case 'changedControllerWait':
      final first = document.node(field(page(14), '@list').elements.first);
      integer(document.node(field(first, '@parameters').elements.single), 26);
    case 'changedSourceWriter':
      final command = document.node(field(page(13), '@list').elements[2]);
      final string =
          document.node(field(command, '@parameters').elements.single);
      const before = 'pbSetSelfSwitch(14,"A",true)',
          after = 'pbSetSelfSwitch(15,"A",true)';
      if (string.text().text != before ||
          string.dataOffset == null ||
          before.length != after.length) {
        throw StateError('Expected exact writer literal.');
      }
      bytes.setRange(string.dataOffset!, string.dataOffset! + after.length,
          utf8.encode(after));
    case 'thirdParallel':
      integer(field(page(5), '@trigger'), 4);
    default:
      throw ArgumentError.value(mutation);
  }
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
  final reattested = ReattestedExecutionFiles(files, entry.fileId, bytes);
  final normalized = await const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: reattested,
      selectedMapIds: {98, 100, 102, 166, 205},
      includeEventSystem: true,
      includeConnections: true);
  return (source: normalized, files: reattested);
}
