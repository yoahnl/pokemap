import '../../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';

final class _OriginalTownMapFiles implements SourceFilePort {
  _OriginalTownMapFiles(this.root, this.snapshot);
  final String root;
  final SourceSnapshot snapshot;
  @override
  Future<List<int>> read(ConverterId id) async {
    final entry = snapshot.entries.singleWhere((entry) => entry.fileId == id);
    validateSourceRelativePath(entry.relativePath);
    final file = File('$root/${entry.relativePath}');
    final resolved = await file.resolveSymbolicLinks();
    if (!resolved.startsWith('$root/')) {
      throw StateError('Source reference escapes its root.');
    }
    return file.readAsBytes();
  }
}

Future<(NormalizedSourceProject, SourceFilePort)> readOriginalTownMapSource(
    {required String archivePath, required String sourceRoot}) async {
  final input =
      jsonDecode(await File('$archivePath/snapshot.json').readAsString())
          as Map<String, dynamic>;
  final snapshot = SourceSnapshot(
      logicalProjectNamespace:
          ConverterId(input['logicalProjectNamespace'] as String),
      policyHash: Sha256Hash(input['policyHash'] as String),
      entries: [
        for (final dynamic row in input['entries'])
          SourceFileEntry(
              fileId: ConverterId(row['fileId'] as String),
              relativePath: row['relativePath'] as String,
              kind: SourceNodeKind.values.byName(row['kind'] as String),
              byteLength: row['byteLength'] as int,
              sha256: row['sha256'] == null
                  ? null
                  : Sha256Hash(row['sha256'] as String),
              format: row['format'] as String,
              family: row['family'] as String)
      ],
      diagnostics: const [],
      excludedPaths: (input['excludedPaths'] as List).cast<String>(),
      profileEvidence: [
        for (final dynamic row in input['profileEvidence'])
          SourceProfileEvidence(
              relativePath: row['relativePath'] as String,
              fileHash: Sha256Hash(row['fileHash'] as String),
              version: row['version'] as String,
              line: row['line'] as int,
              excerpt: row['excerpt'] as String)
      ],
      state: SourceScanState.values.byName(input['state'] as String));
  if (snapshot.canonicalHash.value != input['canonicalHash']) {
    throw StateError('Source inventory identity changed.');
  }
  final files = _OriginalTownMapFiles(sourceRoot, snapshot);
  final source = await const RmxpSourceNormalizer().normalize(
      interpretationProfile: externalOracleInterpretationProfile(),
      snapshot: snapshot,
      files: files,
      selectedMapIds: {102},
      includeEventSystem: true);
  return (source, files);
}

Future<SourceEventStudyComposition> composeOriginalTownMapSource(
    {required String archivePath,
    required String sourceRoot,
    required String outputParentPath,
    String folderName = 'native-town-map',
    NativeWriteLimits limits =
        const NativeWriteLimits(maxArtifacts: 512, maxMutations: 2048)}) async {
  final (source, files) = await readOriginalTownMapSource(
      archivePath: archivePath, sourceRoot: sourceRoot);
  Future<LiteralTileComposition> composeLiteral(
          List<LiteralDependencyDecision> decisions) =>
      const LiteralTileComposer().compose(
          source: source,
          files: files,
          selectedSourceMapIds: const [102],
          projectName: 'Original Town Map qualification',
          parentPath: outputParentPath,
          folderName: folderName,
          sourceRootPath: sourceRoot,
          allowFirstFrameAutotiles: true,
          dependencyDecisions: decisions,
          limits: limits);
  var literal = await composeLiteral(const []);
  final decisions = [
    for (final dependency in literal.dependencies)
      if (dependency.kind == LiteralDependencyKind.staticTransfer &&
          dependency.targetSourceMapId != null &&
          dependency.targetSourceMapId != 102)
        LiteralDependencyDecision(
            sourceSnapshotHash: source.snapshot.canonicalHash,
            selectionHash: literalSelectionHash(source, [102]),
            locator: dependency.locator,
            targetSourceMapId: dependency.targetSourceMapId!,
            decision: LiteralDependencyDisposition.excludeStudy)
  ];
  if (decisions.isNotEmpty) literal = await composeLiteral(decisions);
  if (literal.draft == null) {
    throw StateError(
        'Literal composition refused: ${literal.diagnostics.map((entry) => entry.toJson()).toList()}');
  }
  final semantic = await const SourceSemanticStudyComposer()
      .compose(source: source, base: literal, files: files, limits: limits);
  if (semantic == null) {
    throw StateError('Source semantics refused the original map.');
  }
  final events = await const SourceEventStudyComposer()
      .compose(source: source, base: semantic, files: files, limits: limits);
  if (events == null) {
    throw StateError('Source events refused the original map.');
  }
  return events;
}
