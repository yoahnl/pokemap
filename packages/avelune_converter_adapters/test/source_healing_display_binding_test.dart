import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:avelune_converter_adapters/src/source_healing_display_binding.dart';

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
    {String? before, String? after, String? imageHash}) async {
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
  final map = (input['entries'] as List)
      .cast<Map>()
      .singleWhere((row) => row['relativePath'] == 'Data/Map102.rxdata');
  final mapId = ConverterId(map['fileId'] as String);
  if (before != null) {
    bytes[mapId] = _replaceLiteral(bytes[mapId]!, before, after!);
  }
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
              byteLength: row['fileId'] == mapId.value && before != null
                  ? bytes[mapId]!.length
                  : row['byteLength'] as int,
              sha256: row['sha256'] == null
                  ? null
                  : Sha256Hash(row['fileId'] == mapId.value && before != null
                      ? crypto.sha256.convert(bytes[mapId]!).toString()
                      : row['relativePath'] ==
                                  'Graphics/Characters/OBJ_FRLG_Healing1.png' &&
                              imageHash != null
                          ? imageHash
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
  return const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: _Files(bytes),
      selectedMapIds: {102},
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
    final bytes = await File('$root/${entry.relativePath}').readAsBytes();
    if (entry.relativePath == changedPath) bytes[bytes.length - 1] ^= 1;
    return bytes;
  }
}

void main() {
  final archive = Platform.environment['AVELUNE_AC13_DOOR_ARCHIVE'];
  final root = Platform.environment['AVELUNE_AC13_SOURCE_ROOT'];
  group('original healing display native binding', () {
    late NormalizedSourceProject source;
    late SourceEventAnalysis analysis;
    setUpAll(() async {
      source = await _source(archive!);
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .analyze();
    });
    test(
        'the two real source sheets produce six native four-frame variants without scripts or NPC',
        () async {
      final files = _SourceFiles(source, root!);
      final result = await const SourceHealingDisplayBindingResolver()
          .read(source: source, analysis: analysis, files: files);
      expect(result, isNotNull);
      final binding = result!;
      expect(binding.elements, hasLength(6));
      expect(binding.artifacts, hasLength(2));
      expect(binding.artifacts.map((a) => a.rawSha256.value), [
        '1ff2dd7e2836708834f4e34bf820251d9829bcfa8b35c4af4b21116e75608209',
        'f44799bc293ab69576f1c35dc6f7cca6b5bc1ac16e4aac8db0015e3e275116d1'
      ]);
      for (var n = 0; n < 6; n++) {
        final element = binding.elements[n];
        expect(element.frames, hasLength(4));
        expect(element.collisionProfile, isNull);
        for (var x = 0; x < 4; x++) {
          expect(
              element.frames[x].source, TilesetSourceRect(x: x, y: n % 3 + 1));
          expect(element.frames[x].durationMs, 125);
        }
      }
      final native = binding.createNativeEntity('native-balls');
      expect(native.pos, const GridPos(x: 7, y: 4));
      expect(native.kind, MapEntityKind.custom);
      expect(native.npc, isNull);
      expect(native.editorVisual, isNull);
      expect(native.blocksMovement, isFalse);
      expect(native.healingDisplay!.variantElementIds,
          binding.elements.map((e) => e.id));
      expect(binding.mutations.map((m) => m.actionId), [
        'tileset.import_image',
        'tileset.import_image',
        'element_category.upsert',
        for (var n = 0; n < 6; n++) 'element.upsert'
      ]);
      expect(binding.mutations.take(2).map((m) => m.parameters['tileWidth']),
          [64, 64]);
      expect(binding.mutations.take(2).map((m) => m.parameters['tileHeight']),
          [48, 48]);
      expect(
          binding.isBoundToEvent(
              source: source,
              analysis: analysis,
              event: analysis.eventAt(102, 4)!),
          isTrue);
      expect(binding.evidence['sourceScriptsExecuted'], 0);
      expect(binding.evidence['fullSourceParityQualified'], isFalse);
      expect(files.reads, [
        'Graphics/Characters/OBJ_FRLG_Healing1.png',
        'Graphics/Characters/OBJ_FRLG_Healing2.png'
      ]);
    });
    test('exact admitted image and operation budgets remain usable', () async {
      final binding = await const SourceHealingDisplayBindingResolver().read(
          source: source,
          analysis: analysis,
          files: _SourceFiles(source, root!),
          limits: const NativeWriteLimits(
              maxArtifacts: 2,
              maxMutations: 9,
              maxImagePixels: 98304,
              maxArtifactBytes: 2191,
              maxTotalArtifactBytes: 3899));
      expect(binding!.artifacts, hasLength(2));
      expect(binding.mutations, hasLength(9));
    });
    test(
        'fresh source image identity cannot borrow the qualified visual template',
        () async {
      final changed = await _source(archive!, imageHash: '0' * 64);
      final changedAnalysis = SourceEventAnalyzer.forProject(changed,
              profile: SourceEventProfile.kantoForProject(changed))
          .analyze();
      final files = _SourceFiles(changed, root!);
      await expectLater(
          const SourceHealingDisplayBindingResolver()
              .read(source: changed, analysis: changedAnalysis, files: files),
          throwsA(isA<SourceHealingDisplayBindingUnavailable>()
              .having((e) => e.reason, 'reason', 'source_image_unqualified')));
      expect(files.reads, isEmpty);
    });
    test('binding lists and nested evidence are immutable', () async {
      final binding = (await const SourceHealingDisplayBindingResolver().read(
          source: source,
          analysis: analysis,
          files: _SourceFiles(source, root!)))!;
      expect(() => binding.elements.clear(), throwsUnsupportedError);
      expect(() => binding.artifacts.clear(), throwsUnsupportedError);
      expect(() => binding.mutations.clear(), throwsUnsupportedError);
      expect(() => binding.evidence.clear(), throwsUnsupportedError);
      expect(
          () => ((binding.evidence['program'] as Map)['pages'] as List).clear(),
          throwsUnsupportedError);
    });
    test('an analysis without this source event imports no visual resources',
        () async {
      final files = _SourceFiles(source, root!);
      final other = SourceEventAnalysis(
          profile: analysis.profile,
          events: analysis.events
              .where((event) => event.sourceEventId != 4)
              .toList(),
          diagnostics: []);
      expect(
          await const SourceHealingDisplayBindingResolver()
              .read(source: source, analysis: other, files: files),
          isNull);
      expect(files.reads, isEmpty);
    });
    test(
        'unqualified profile and forged analyzed anchor are refused before file IO',
        () async {
      final current = analysis.eventAt(102, 4)!;
      final changed = SourceEventDefinition(
          sourceMapId: current.sourceMapId,
          sourceEventId: current.sourceEventId,
          sourceFileId: current.sourceFileId,
          identity: current.identity,
          name: current.name,
          x: current.x + 1,
          y: current.y,
          locator: current.locator,
          pages: current.pages);
      for (final other in [
        SourceEventAnalysis(
            profile: SourceEventProfile.kantoForProject(source,
                scriptsArchiveHash: Sha256Hash('0' * 64)),
            events: analysis.events,
            diagnostics: []),
        SourceEventAnalysis(profile: analysis.profile, events: [
          for (final event in analysis.events)
            if (event == current) changed else event
        ], diagnostics: [])
      ]) {
        final files = _SourceFiles(source, root!);
        await expectLater(
            const SourceHealingDisplayBindingResolver()
                .read(source: source, analysis: other, files: files),
            throwsA(isA<SourceHealingDisplayBindingUnavailable>()));
        expect(files.reads, isEmpty);
      }
    });
    for (final limit in [
      const NativeWriteLimits(maxArtifacts: 1),
      const NativeWriteLimits(maxMutations: 8),
      const NativeWriteLimits(maxTotalImagePixels: 98303),
      const NativeWriteLimits(maxImagePixels: 49151),
      const NativeWriteLimits(maxTotalArtifactBytes: 3898),
      const NativeWriteLimits(maxArtifactBytes: 2190)
    ]) {
      test(
          'native resource limits refuse before source image reads ${limit.maxArtifacts}/${limit.maxMutations}/${limit.maxImagePixels}/${limit.maxTotalImagePixels}/${limit.maxTotalArtifactBytes}/${limit.maxArtifactBytes}',
          () async {
        final files = _SourceFiles(source, root!);
        await expectLater(
            const SourceHealingDisplayBindingResolver().read(
                source: source,
                analysis: analysis,
                files: files,
                limits: limit),
            throwsA(isA<NativeWriteException>().having(
                (e) => e.code, 'code', 'events.healing_display.quota')));
        expect(files.reads, isEmpty);
      });
    }
    test('split image budget admits both healing sheets at the exact individual limit', () async {
      final files = _SourceFiles(source, root!);
      final result = await const SourceHealingDisplayBindingResolver().read(
        source: source, analysis: analysis, files: files,
        limits: const NativeWriteLimits(maxImagePixels: 49152, maxTotalImagePixels: 98304));
      expect(result!.artifacts, hasLength(2));
    });
    for (final path in [
      'Graphics/Characters/OBJ_FRLG_Healing1.png',
      'Graphics/Characters/OBJ_FRLG_Healing2.png'
    ]) {
      test('changed actual image bytes are refused $path', () async {
        await expectLater(
            const SourceHealingDisplayBindingResolver().read(
                source: source,
                analysis: analysis,
                files: _SourceFiles(source, root!, changedPath: path)),
            throwsA(isA<ContractError>().having((e) => e.code, 'code',
                'source.healing_display.image_changed')));
      });
    }
    for (final mutation in [
      ('OBJ_FRLG_Healing1', 'OBJ_FRLG_HealingX'),
      ('get_character(4).pattern = 0', 'get_character(4).pattern = 1')
    ]) {
      test(
          'fresh source suffix or image identity cannot borrow this binding ${mutation.$1}',
          () async {
        final changed =
            await _source(archive!, before: mutation.$1, after: mutation.$2);
        final changedAnalysis = SourceEventAnalyzer.forProject(changed,
                profile: SourceEventProfile.kantoForProject(changed))
            .analyze();
        final files = _SourceFiles(changed, root!);
        await expectLater(
            const SourceHealingDisplayBindingResolver()
                .read(source: changed, analysis: changedAnalysis, files: files),
            throwsA(isA<SourceHealingDisplayBindingUnavailable>().having(
                (e) => e.reason, 'reason', 'source_program_unqualified')));
        expect(files.reads, isEmpty);
      });
    }
  },
      skip: archive == null || root == null
          ? 'Original source archive and immutable source root are required.'
          : false);
}
