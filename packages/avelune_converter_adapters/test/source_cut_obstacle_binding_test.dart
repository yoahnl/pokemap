import 'dart:convert';
import 'dart:io';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_converter_adapters/src/source_field_obstacle_binding.dart';
import 'package:avelune_converter_adapters/src/native_project_writer.dart';

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

Future<NormalizedSourceProject> _source(String folder,
    {String? before, String? after}) async {
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
      selectedMapIds: {98, 100},
      includeEventSystem: true);
}

final class _SourceFiles implements SourceFilePort {
  _SourceFiles(this.source, this.root, {this.changedPath});
  final NormalizedSourceProject source;
  final String root;
  final String? changedPath;
  final reads = <String>[];
  @override
  Future<List<int>> read(ConverterId id) async {
    final entry =
        source.snapshot.entries.singleWhere((entry) => entry.fileId == id);
    reads.add(entry.relativePath);
    final explicitScripts = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];
    final sourcePath = entry.relativePath == 'Data/Scripts.rxdata' && explicitScripts != null
        ? explicitScripts : '$root/${entry.relativePath}';
    final bytes = await File(sourcePath).readAsBytes();
    if (entry.relativePath == changedPath) bytes[bytes.length - 1] ^= 1;
    return bytes;
  }
}

void main() {
  final archive = Platform.environment['AVELUNE_AC13_DOOR_ARCHIVE'];
  final sourceRoot = Platform.environment['AVELUNE_AC13_SOURCE_ROOT'];
  group('source Cut obstacle bindings', () {
    late NormalizedSourceProject source;
    late SourceEventAnalysis analysis;
    setUpAll(() async {
      source = await _source(archive!);
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.forProject(source,
interpretationProfile: fixtureSourceInterpretationProfile,
))
          .analyze();
    });
    test(
        'the five trees bind to Cascade Badge without granting player progress',
        () async {
      final files = _SourceFiles(source, sourceRoot!);
      final result = (await const SourceFieldObstacleBindingResolver()
          .read(source: source, analysis: analysis, files: files))!;
      expect(result.byEventIdentity, hasLength(5));
      expect(result.badges.single.label, 'Badge source 12 (région 1)');
      expect(result.badges.single.fieldAbilityUnlock, FieldAbility.cut);
      expect(result.mutations.map((m) => m.actionId), [
        'tileset.import_image',
        'element_category.upsert',
        'element.upsert',
        'campaign.badge.upsert'
      ]);
      expect(result.mutations.last.parameters['value'], result.badges.single.toJson());
      expect(result.evidence['initialPlayerStateMutated'], isFalse);
      expect(result.evidence['audioSourceParity'], isFalse);
      expect(files.reads, [
        'Data/Scripts.rxdata',
        'PBS/map_metadata.txt',
        'Graphics/Characters/OBJ_FRLG_Cut Tree.png'
      ]);
      for (final entry in result.byEventIdentity.entries) {
        final binding = entry.value;
        final event =
            analysis.events.singleWhere((e) => e.identity == entry.key);
        expect(
            binding.isBoundToEvent(
                source: source, analysis: analysis, event: event),
            isTrue);
        final native = binding.createNativeEntity(
            'tree_${binding.sourceMapId}_${binding.sourceEventId}');
        expect(native.kind, MapEntityKind.custom);
        expect(native.fieldObstacle!.kind, FieldObstacleKind.cutTree);
        expect(native.fieldObstacle!.resetPolicy,
            FieldObstacleResetPolicy.mapInstance);
        expect(native.npc, isNull);
        expect(native.size, const GridSize(width: 1, height: 1));
        expect(native.blocksMovement, isTrue);
        expect(native.editorVisual!.elementId, result.elements.single.id);
        expect(binding.toJson()['nativeRequiresNonFaintedPokemon'], isTrue);
        expect(binding.toJson()['initialPlayerAbilityUnlocked'], isFalse);
      }
    });
    test('the source frame stays a static one cell native visual', () async {
      final result = (await const SourceFieldObstacleBindingResolver().read(
          source: source,
          analysis: analysis,
          files: _SourceFiles(source, sourceRoot!)))!;
      expect(result.artifacts.single.rawSha256.value,
          '68271cc5662b112111bec29ea8122466712535a4fd2381262a20a65064e974cb');
      expect(result.elements.single.frames, hasLength(1));
      expect(result.elements.single.frames.single.source,
          const TilesetSourceRect(x: 0, y: 0));
      expect(result.evidence['sourcePixelsResampled'], isFalse);
      expect(
          result.elements.single.collisionProfile!.cells, [const GridPos(x: 0, y: 0)]);
    });
    for (final path in [
      'Data/Scripts.rxdata',
      'PBS/map_metadata.txt',
      'Graphics/Characters/OBJ_FRLG_Cut Tree.png'
    ]) {
      test(
          'changed admitted source bytes refuse $path before native activation',
          () async {
        await expectLater(
            const SourceFieldObstacleBindingResolver().read(
                source: source,
                analysis: analysis,
                files: _SourceFiles(source, sourceRoot!, changedPath: path)),
            throwsA(isA<ContractError>()
                .having((e) => e.code, 'code', 'source.field_obstacle.source_changed')));
      });
    }
    test('source read quota refuses before reading the archive', () async {
      final files = _SourceFiles(source, sourceRoot!);
      await expectLater(
          const SourceFieldObstacleBindingResolver().read(
              source: source,
              analysis: analysis,
              files: files,
              limits: const NativeWriteLimits(maxArtifactBytes: 1)),
          throwsA(isA<NativeWriteException>()
              .having((e) => e.code, 'code', 'events.field_obstacle.quota')));
      expect(files.reads, isEmpty);
    });
    test('foreign event cannot reuse a Cut binding', () async {
      final result = (await const SourceFieldObstacleBindingResolver().read(
          source: source,
          analysis: analysis,
          files: _SourceFiles(source, sourceRoot!)))!;
      final tree = result.byEventIdentity.values.first;
      final other =
          analysis.events.firstWhere((e) => e.identity != tree.eventIdentity);
      expect(
          tree.isBoundToEvent(source: source, analysis: analysis, event: other),
          isFalse);
    });
  }, skip: archive == null || sourceRoot == null);
}
