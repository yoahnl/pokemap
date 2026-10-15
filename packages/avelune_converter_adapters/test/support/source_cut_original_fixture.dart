import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';

final class _Files implements SourceFilePort {
  _Files(this.bytes);
  final Map<ConverterId, List<int>> bytes;

  @override
  Future<List<int>> read(ConverterId id) async => List.of(bytes[id]!);
}

List<int> _replaceLiteral(List<int> bytes, String before, String after) {
  final old = utf8.encode(before), next = utf8.encode(after);
  final pattern = [0x22, old.length + 5, ...old];
  for (var index = 0; index <= bytes.length - pattern.length; index++) {
    if (List.generate(pattern.length, (slot) => bytes[index + slot])
        .indexed
        .every((entry) => entry.$2 == pattern[entry.$1])) {
      return [
        ...bytes.take(index),
        0x22,
        next.length + 5,
        ...next,
        ...bytes.skip(index + pattern.length)
      ];
    }
  }
  throw StateError('Source literal not found: $before');
}

Future<NormalizedSourceProject> readOriginalCutSource(String folder,
    {String? before,
    String? after,
    Set<int> selectedMapIds = const {98, 100}}) async {
  final input = jsonDecode(await File('$folder/snapshot.json').readAsString())
      as Map<String, dynamic>;
  final frozen =
      jsonDecode(await File('$folder/normalized.json').readAsString())
          as Map<String, dynamic>;
  final bytes = <ConverterId, List<int>>{
    for (final row in frozen['archive']['files'])
      ConverterId(row['entry']['fileId'] as String):
          base64Decode(row['rawBytes'] as String)
  };
  final map = (input['entries'] as List)
      .cast<Map>()
      .singleWhere((row) => row['relativePath'] == 'Data/Map098.rxdata');
  final mapId = ConverterId(map['fileId'] as String);
  if (before != null) {
    bytes[mapId] = _replaceLiteral(bytes[mapId]!, before, after!);
  }
  final changed = before != null;
  final snapshot = SourceSnapshot(
      logicalProjectNamespace:
          ConverterId(input['logicalProjectNamespace'] as String),
      policyHash: Sha256Hash(input['policyHash'] as String),
      entries: [
        for (final row in input['entries'])
          SourceFileEntry(
              fileId: ConverterId(row['fileId'] as String),
              relativePath: row['relativePath'] as String,
              kind: SourceNodeKind.values.byName(row['kind'] as String),
              byteLength: row['fileId'] == mapId.value && changed
                  ? bytes[mapId]!.length
                  : row['byteLength'] as int,
              sha256: row['sha256'] == null
                  ? null
                  : Sha256Hash(row['fileId'] == mapId.value && changed
                      ? crypto.sha256.convert(bytes[mapId]!).toString()
                      : row['sha256'] as String),
              format: row['format'] as String,
              family: row['family'] as String)
      ],
      diagnostics: [],
      excludedPaths: (input['excludedPaths'] as List).cast<String>(),
      profileEvidence: [
        for (final row in input['profileEvidence'])
          SourceProfileEvidence(
              relativePath: row['relativePath'] as String,
              fileHash: Sha256Hash(row['fileHash'] as String),
              version: row['version'] as String,
              line: row['line'] as int,
              excerpt: row['excerpt'] as String)
      ],
      state: SourceScanState.values.byName(input['state'] as String));
  return const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: _Files(bytes),
      selectedMapIds: selectedMapIds,
      includeEventSystem: true);
}

final class CutSourceFiles implements SourceFilePort {
  CutSourceFiles(this.source, this.root, {this.changedPath});
  final NormalizedSourceProject source;
  final String root;
  final String? changedPath;
  final reads = <String>[];
  @override
  Future<List<int>> read(ConverterId id) async {
    final entry =
        source.snapshot.entries.singleWhere((entry) => entry.fileId == id);
    reads.add(entry.relativePath);
    final bytes = await File('$root/${entry.relativePath}').readAsBytes();
    if (entry.relativePath == changedPath) bytes[bytes.length - 1] ^= 1;
    return bytes;
  }
}

Future<SourceEventStudyComposition> composeOriginalCutSource(
    {required String archivePath,
    required String sourceRoot,
    required String outputParentPath,
    String folderName = 'native-cut',
    Set<int> sourceMapIds = const {98, 100},
    NativeWriteLimits limits =
        const NativeWriteLimits(maxArtifacts: 512, maxMutations: 2048)}) async {
  final timer = Stopwatch()..start();
  final source =
      await readOriginalCutSource(archivePath, selectedMapIds: sourceMapIds);
  stdout.writeln(
      'Cut normal workflow normalized in ${timer.elapsedMilliseconds} ms');
  final files = CutSourceFiles(source, sourceRoot);
  Future<LiteralTileComposition> literalWith(
          List<LiteralDependencyDecision> decisions) =>
      const LiteralTileComposer().compose(
          source: source,
          files: files,
          selectedSourceMapIds: sourceMapIds.toList()..sort(),
          projectName: 'Original Cut qualification',
          parentPath: outputParentPath,
          folderName: folderName,
          sourceRootPath: sourceRoot,
          allowFirstFrameAutotiles: true,
          dependencyDecisions: decisions,
          limits: limits);
  var literal = await literalWith(const []);
  final decisions = [
    for (final dependency in literal.dependencies)
      if (dependency.kind == LiteralDependencyKind.staticTransfer &&
          dependency.targetSourceMapId != null &&
          !sourceMapIds.contains(dependency.targetSourceMapId))
        LiteralDependencyDecision(
            sourceSnapshotHash: source.snapshot.canonicalHash,
            selectionHash:
                literalSelectionHash(source, sourceMapIds.toList()..sort()),
            locator: dependency.locator,
            targetSourceMapId: dependency.targetSourceMapId!,
            decision: LiteralDependencyDisposition.excludeStudy)
  ];
  if (decisions.isNotEmpty) literal = await literalWith(decisions);
  if (literal.draft == null) throw StateError('Original Cut literal refused');
  stdout.writeln(
      'Cut normal workflow literal in ${timer.elapsedMilliseconds} ms');
  final semantic = await const SourceSemanticStudyComposer()
      .compose(source: source, base: literal, files: files, limits: limits);
  if (semantic == null) throw StateError('Original Cut semantics refused');
  stdout.writeln(
      'Cut normal workflow semantics in ${timer.elapsedMilliseconds} ms');
  final events = await const SourceEventStudyComposer()
      .compose(source: source, base: semantic, files: files, limits: limits);
  if (events == null) {
    throw StateError('Original Cut event composition refused');
  }
  stdout
      .writeln('Cut normal workflow events in ${timer.elapsedMilliseconds} ms');
  return events;
}
