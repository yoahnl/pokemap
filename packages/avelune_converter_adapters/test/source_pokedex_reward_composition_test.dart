import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';

final class _Files implements SourceFilePort {
  _Files(this.bytes, this.paths, this.sourceRoot);
  final Map<ConverterId, List<int>> bytes;
  final Map<ConverterId, String> paths;
  final String sourceRoot;

  @override
  Future<List<int>> read(ConverterId id) async => bytes.containsKey(id)
      ? List.of(bytes[id]!)
      : File('$sourceRoot/${paths[id]}').readAsBytes();
}

Future<(NormalizedSourceProject, SourceFilePort)> _source(
    String folder, String sourceRoot,
    {bool changedDex = false, bool unrelatedDex = false}) async {
  final input = jsonDecode(await File('$folder/snapshot.json').readAsString())
      as Map<String, dynamic>;
  final frozen =
      jsonDecode(await File('$folder/normalized.json').readAsString())
          as Map<String, dynamic>;
  final bytes = <ConverterId, List<int>>{
    for (final dynamic row in frozen['archive']['files'])
      ConverterId(row['entry']['fileId'] as String):
          base64Decode(row['rawBytes'] as String)
  };
  final paths = <ConverterId, String>{
    for (final dynamic row in input['entries'])
      ConverterId(row['fileId'] as String): row['relativePath'] as String,
  };
  final dexId = paths.entries
      .singleWhere((entry) => entry.value == 'Data/regional_dexes.dat')
      .key;
  if (changedDex || unrelatedDex) {
    final raw = await File('$sourceRoot/Data/regional_dexes.dat').readAsBytes();
    final before = utf8.encode(changedDex ? 'BULBASAUR' : 'MISSINGNO');
    final after = utf8.encode(changedDex ? 'NOTASAUUR' : 'OTHERDEXX');
    var found = false;
    for (var i = 0; i <= raw.length - before.length; i++) {
      if (before.indexed.every((pair) => raw[i + pair.$1] == pair.$2)) {
        raw.setRange(i, i + after.length, after);
        found = true;
        break;
      }
    }
    if (!found) throw StateError('Missing source dex symbol');
    bytes[dexId] = raw;
  }
  final changed = bytes.containsKey(dexId);
  final files = _Files(bytes, paths, sourceRoot);
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
              byteLength: row['fileId'] == dexId.value && changed
                  ? bytes[dexId]!.length
                  : row['byteLength'] as int,
              sha256: row['sha256'] == null
                  ? null
                  : Sha256Hash(row['fileId'] == dexId.value && changed
                      ? crypto.sha256.convert(bytes[dexId]!).toString()
                      : row['sha256'] as String),
              format: row['format'] as String,
              family: row['family'] as String)
      ],
      diagnostics: [],
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
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: files,
      selectedMapIds: {102},
      includeEventSystem: true);
  return (source, files);
}

void main() {
  final archive = Platform.environment['AVELUNE_AC13_DOOR_ARCHIVE'];
  final root = Platform.environment['AVELUNE_AC13_SOURCE_ROOT'];
  test(
      'normal original-map composition imports the aide and preserves both catalogs',
      () async {
    final fixture = await _source(archive!, root!);
    final temporary =
        await Directory.systemTemp.createTemp('everstone-normal-composition-');
    addTearDown(() => temporary.delete(recursive: true));
    const limits = NativeWriteLimits(maxArtifacts: 512, maxMutations: 2048);
    Future<LiteralTileComposition> composeLiteral(
            List<LiteralDependencyDecision> decisions) =>
        const LiteralTileComposer().compose(
            source: fixture.$1,
            files: fixture.$2,
            selectedSourceMapIds: const [102],
            projectName: 'Everstone original-map qualification',
            parentPath: temporary.path,
            folderName: 'native',
            sourceRootPath: root,
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
              sourceSnapshotHash: fixture.$1.snapshot.canonicalHash,
              selectionHash: literalSelectionHash(fixture.$1, [102]),
              locator: dependency.locator,
              targetSourceMapId: dependency.targetSourceMapId!,
              decision: LiteralDependencyDisposition.excludeStudy)
    ];
    if (decisions.isNotEmpty) literal = await composeLiteral(decisions);
    expect(literal.draft, isNotNull,
        reason:
            '${literal.diagnostics.map((entry) => entry.toJson()).toList()}');
    final semantic = (await const SourceSemanticStudyComposer().compose(
        source: fixture.$1, base: literal, files: fixture.$2, limits: limits))!;
    final composition = (await const SourceEventStudyComposer().compose(
        source: fixture.$1,
        base: semantic,
        files: fixture.$2,
        limits: limits))!;
    final binding =
        composition.draft.compositionEvidence['sourceEvents'] as Map;
    final rows =
        (composition.projection.semanticEvidence['events'] as List).cast<Map>();
    final aide =
        rows.singleWhere((row) => (row['locator'] as Map)['eventId'] == 10);
    expect(aide['status'], 'adaptedStaticSemantics', reason: '${aide['gaps']}');
    expect(binding['pokedexRewardBinding'], isNotNull);
    final companionMutation = composition.draft.mutations.singleWhere(
        (mutation) =>
            mutation.actionId == 'asset.import' &&
            (mutation.parameters['usages'] as List?)
                    ?.contains('converter.sourceEvents') ==
                true);
    final companion = composition.draft.artifacts.singleWhere((artifact) =>
        artifact.handle == companionMutation.parameters['artifactHandle']);
    final companionJson = jsonDecode(utf8.decode(companion.bytes)) as Map;
    final preserved =
        (companionJson['preservedSourceFiles'] as List).cast<Map>();
    expect(
        preserved
            .any((row) => row['relativePath'] == 'Data/regional_dexes.dat'),
        isTrue);
    expect(preserved.any((row) => row['relativePath'] == 'Data/items.dat'),
        isTrue);
    expect(
        composition.projection.itemCatalog!.entries
            .any((item) => item.displayName == 'Everstone'),
        isTrue);
    expect(composition.projection.semanticEvidence['nativeExecutionQualified'],
        isNot(true));
  },
      skip: archive == null || root == null
          ? 'Original source and archive required.'
          : false,
      timeout: const Timeout(Duration(minutes: 3)));
}
