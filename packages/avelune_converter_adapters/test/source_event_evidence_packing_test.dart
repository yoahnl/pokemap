import 'dart:convert';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_converter_adapters/src/source_event_evidence.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';

const _limits = NativeWriteLimits(
    maxArtifacts: 1024,
    maxMutations: 4096,
    jsonLimits: ContractLimits(maxTextCodeUnits: 16777216));

Map<String, Object?> _context(int index) => {
      'kind': 'sourceEventExecutionContext',
      'version': 1,
      'sourceSnapshotHash': 'a' * 64,
      'normalizationHash': 'b' * 64,
      'sourceProfileHash': 'c' * 64,
      'baseDraftHash': 'd' * 64,
      'staticDoorIdentity': 'event_$index',
      'mapIds': {for (var id = 1; id <= 383; id++) '$id': 'native_map_$id'},
      'mapHashes': {for (var id = 1; id <= 383; id++) '$id': 'e' * 64},
      'qualified': index.isEven,
      'refusals': [if (index.isOdd) 'exactRefusal'],
      'proof': {
        'actorOwner': index,
        'scope': [index, index + 1],
        'mapAutonomyAudit': {
          'policy': 'unchanged',
          'pages': [
            for (var row = 0; row < 24; row++)
              {
                'row': row,
                'span': [row, row + 1],
                'hash': 'f' * 64,
                'audit': 'source-$row-' * 32
              },
            {
              'row': 0,
              'span': [0, 1],
              'hash': 'f' * 64,
              'audit': 'source-0-' * 32
            },
          ]
        },
        'witnesses': [
          {'id': 1, 'sha256': 'a' * 64},
          {'id': 1, 'sha256': 'a' * 64}
        ]
      },
    };

Map<String, Object?> _parallelContext(int index) => _context(index)
  ..['proof'] = {
    'parallelDormancy': {
      'sourceSnapshotHash': 'a' * 64,
      'normalizationHash': 'b' * 64,
      'profileHash': 'c' * 64,
      'activeSourceMapIds': [index + 1],
      'qualified': index.isEven,
      'refusals': [if (index.isOdd) 'localDormancyRefusal'],
      'nativeWriteSet': [
        for (var row = 0; row < 1024; row++)
          {
            'sourceMapId': row % 383 + 1,
            'sourceEventId': row,
            'pageIndex': 0,
            'factId': 'fact_$row',
            'value': true
          },
      ],
      'nativeWriteSetSemantics': 'conservativeMayWriteUpperBound',
      'potentiallyProjectableEvents': [
        for (var row = 0; row < 1024; row++) 'event_$row'
      ],
      'quarantinedWholeEvents': [
        for (var row = 0; row < 1024; row++) 'quarantine_$row'
      ],
      'nativeSourceWritesToControllerGuards': [index],
      'wholeRawEventWitnesses': [
        {'sourceEventId': index, 'sha256': 'f' * 64}
      ],
    },
  };

List<int> _reassemble(List<NativeArtifact> artifacts) {
  final root = jsonDecode(utf8.decode(artifacts.last.bytes)) as Map;
  if (root['kind'] != 'sourceEventProjectionChunks') {
    return artifacts.single.bytes;
  }
  final bytes = <int>[];
  for (final descriptor in root['chunks'] as List) {
    expect(descriptor['offset'], bytes.length);
    final chunk =
        artifacts.singleWhere((a) => a.handle == descriptor['artifactHandle']);
    final json = jsonDecode(utf8.decode(chunk.bytes)) as Map;
    expect(json['offset'], bytes.length);
    final part = base64Decode(json['bytesBase64'] as String);
    expect(part.length, descriptor['byteLength']);
    bytes.addAll(part);
  }
  expect(bytes.length, root['byteLength']);
  expect(crypto.sha256.convert(bytes).toString(), root['sha256']);
  return bytes;
}

void main() {
  test(
      '383 local dormancy scopes share one exact global writer closure within existing budgets',
      () {
    final originals = [
      for (var index = 0; index < 383; index++) _parallelContext(index)
    ];
    expect(
        () => canonicalJsonOf({'contexts': originals},
            limits: _limits.jsonLimits),
        throwsA(isA<ContractError>()));
    final encoding =
        SourceEventEvidenceEncoding(enabled: true, limits: _limits);
    final encoded = [
      for (final original in originals) encoding.encodeContext(original)
    ];
    final payload = {'contexts': encoded, 'tables': encoding.tables};
    final packed = SourceEventEvidenceArtifacts.pack(payload, limits: _limits);
    expect((encoding.tables!['parallelNativeWriteClosures'] as Map).length, 1);
    expect(encoding.tables!['contract'],
        'source-event-execution-context-tables-v3');
    expect(_reassemble(packed.artifacts),
        utf8.encode(canonicalJsonOf(payload, limits: _limits.jsonLimits)));
    final restored = SourceEventEvidenceEncoding.restoreContexts(
        encoded, encoding.tables!,
        limits: _limits);
    for (var index = 0; index < originals.length; index++) {
      expect(
          canonicalHashOf(restored[index]), canonicalHashOf(originals[index]));
      expect(
          canonicalJsonOf(restored[index]), canonicalJsonOf(originals[index]));
    }
    expect(canonicalJsonOf(payload, limits: _limits.jsonLimits).length,
        lessThan(1048576));
  });

  test(
      'parallel closure references reject dangling tampered duplicate and unused evidence',
      () {
    final encoding =
        SourceEventEvidenceEncoding(enabled: true, limits: _limits);
    final encoded = [encoding.encodeContext(_parallelContext(0))];
    Map<String, Object?> tables() =>
        jsonDecode(canonicalJsonOf(encoding.tables)) as Map<String, Object?>;
    List<Map<String, Object?>?> contexts() =>
        (jsonDecode(canonicalJsonOf(encoded)) as List)
            .map((row) => Map<String, Object?>.from(row as Map))
            .toList();
    final missing = tables();
    (missing['parallelNativeWriteClosures'] as Map).clear();
    final altered = tables();
    (((altered['parallelNativeWriteClosures'] as Map).values.single
            as Map)['nativeWriteSet'] as List)
        .removeLast();
    final unused = tables();
    final extra = {'nativeWriteSet': <Object?>[]};
    (unused['parallelNativeWriteClosures']
        as Map)[canonicalHashOf(extra).value] = extra;
    final dangling = contexts();
    ((dangling.single!['proof'] as Map)['parallelDormancy']
        as Map)['nativeWriteClosureRef'] = '0' * 64;
    final duplicate = contexts();
    ((duplicate.single!['proof'] as Map)['parallelDormancy']
        as Map)['nativeWriteSet'] = [];
    for (final invalid in [missing, altered, unused]) {
      expect(
          () => SourceEventEvidenceEncoding.restoreContexts(encoded, invalid,
              limits: _limits),
          throwsA(isA<NativeWriteException>()));
    }
    for (final invalid in [dangling, duplicate]) {
      expect(
          () => SourceEventEvidenceEncoding.restoreContexts(
              invalid, encoding.tables!,
              limits: _limits),
          throwsA(isA<NativeWriteException>()));
    }
  });

  test('distinct long page scopes fit without repeating every page hash', () {
    const limits = NativeWriteLimits(
        maxArtifacts: 1024,
        maxMutations: 4096,
        jsonLimits: ContractLimits(maxTextCodeUnits: 4194304));
    final pages = [
      for (var row = 0; row < 773; row++)
        {'sourcePage': row, 'rawDataHash': 'f' * 64},
    ];
    final originals = [
      for (var index = 0; index < 128; index++)
        _context(index)
          ..['proof'] = {
            'mapAutonomyAudit': {
              'pages': [
                ...pages.skip(index),
                ...pages.take(index),
              ],
            },
          },
    ];
    final encoding = SourceEventEvidenceEncoding(enabled: true, limits: limits);
    final encoded = [
      for (final original in originals) encoding.encodeContext(original),
    ];
    final payload = {'contexts': encoded, 'tables': encoding.tables};
    final packed = SourceEventEvidenceArtifacts.pack(payload, limits: limits);
    expect(_reassemble(packed.artifacts),
        utf8.encode(canonicalJsonOf(payload, limits: limits.jsonLimits)));
    final restored = SourceEventEvidenceEncoding.restoreContexts(
        encoded, encoding.tables!,
        limits: limits);
    expect(restored.map(canonicalHashOf), originals.map(canonicalHashOf));
    expect(canonicalJsonOf(payload, limits: limits.jsonLimits).length,
        lessThan(1048576));
  });

  test('the individual JSON hard limit remains exact at 1 MiB', () {
    final atBoundary = {'v': 'x' * (1048576 - 8)};
    final afterBoundary = {'v': 'x' * (1048576 - 7)};
    final exact =
        SourceEventEvidenceArtifacts.pack(atBoundary, limits: _limits);
    expect(exact.root.bytes.length, 1048576);
    expect(exact.chunks, isEmpty);
    final split =
        SourceEventEvidenceArtifacts.pack(afterBoundary, limits: _limits);
    expect(split.chunks, isNotEmpty);
    expect(_reassemble(split.artifacts),
        utf8.encode(canonicalJsonOf(afterBoundary)));
    expect(
        () => NativeArtifact(
            bytes: utf8.encode(canonicalJsonOf(afterBoundary)),
            mediaType: 'application/json',
            limits: _limits),
        throwsA(isA<NativeWriteException>()));
  });

  test('repeated 773 page scope lists remain bounded across 528 contexts', () {
    final context = _context(0);
    ((context['proof'] as Map)['mapAutonomyAudit'] as Map)['pages'] = [
      for (var row = 0; row < 773; row++)
        {'sourcePage': row, 'rawDataHash': 'f' * 64},
    ];
    final encoding =
        SourceEventEvidenceEncoding(enabled: true, limits: _limits);
    final contexts = [
      for (var i = 0; i < 528; i++) encoding.encodeContext(context)
    ];
    final json = canonicalJsonOf(
        {'contexts': contexts, 'tables': encoding.tables},
        limits: _limits.jsonLimits);
    expect(json.length, lessThan(1048576));
    expect(
        SourceEventEvidenceEncoding.restoreContexts(contexts, encoding.tables!,
                limits: _limits)
            .every((c) => canonicalHashOf(c) == canonicalHashOf(context)),
        isTrue);
  });

  test('small payload artifacts keep exact canonical bytes and handles', () {
    final evidence = {
      'kind': 'sourceEventProjection',
      'source': 'é',
      'rows': [1, 2]
    };
    final packed = SourceEventEvidenceArtifacts.pack(evidence, limits: _limits);
    final original = NativeArtifact(
        bytes: utf8.encode(canonicalJsonOf(evidence)),
        mediaType: 'application/json',
        limits: _limits);
    expect(packed.chunks, isEmpty);
    expect(packed.root.bytes, original.bytes);
    expect(packed.root.handle, original.handle);
  });

  test('packing respects custom byte and base64 string quotas', () {
    const limits = NativeWriteLimits(
        maxArtifacts: 1024,
        maxArtifactBytes: 65536,
        jsonLimits: ContractLimits(maxStringCodeUnits: 1024));
    final evidence = {'rows': List.filled(800, 'é' * 60)};
    final packed = SourceEventEvidenceArtifacts.pack(evidence, limits: limits);
    expect(packed.chunks.length, greaterThan(1));
    expect(packed.artifacts.every((a) => a.bytes.length <= 65536), isTrue);
    for (final chunk in packed.chunks) {
      final value = jsonDecode(utf8.decode(chunk.bytes)) as Map;
      expect((value['bytesBase64'] as String).length, lessThanOrEqualTo(1024));
    }
    expect(
        _reassemble(packed.artifacts), utf8.encode(canonicalJsonOf(evidence)));
  });

  test('packing honors aggregate byte budgets and refuses effective quotas',
      () {
    final evidence = {'rows': List.filled(5000, 'source' * 150)};
    expect(() => canonicalJsonOf(evidence), throwsA(isA<ContractError>()));
    final packed = SourceEventEvidenceArtifacts.pack(evidence, limits: _limits);
    expect(_reassemble(packed.artifacts),
        utf8.encode(canonicalJsonOf(evidence, limits: _limits.jsonLimits)));
    expect(
        () => SourceEventEvidenceArtifacts.pack(evidence,
            limits: const NativeWriteLimits(
                maxArtifacts: 1,
                jsonLimits: ContractLimits(maxTextCodeUnits: 16777216))),
        throwsA(isA<NativeWriteException>()));
    expect(
        () => SourceEventEvidenceArtifacts.pack(
            {'rows': List.filled(80, 'x' * 100)},
            limits: const NativeWriteLimits(
                maxArtifactBytes: 4096, maxTotalArtifactBytes: 4096)),
        throwsA(isA<NativeWriteException>()));
    final defaults = SourceEventEvidenceArtifacts.pack(evidence,
        limits: const NativeWriteLimits());
    expect(_reassemble(defaults.artifacts), _reassemble(packed.artifacts));
  });

  test(
      'aggregate evidence exceeding record text quotas roundtrips in bounded chunks',
      () {
    final evidence = {'rows': List.filled(17, 'x' * 1000000)};
    expect(
        () => canonicalJsonOf(evidence, limits: _limits.jsonLimits),
        throwsA(isA<ContractError>()
            .having((e) => e.code, 'code', 'json.textQuota')));
    final packed = SourceEventEvidenceArtifacts.pack(evidence, limits: _limits);
    expect(packed.artifacts.every((a) => a.bytes.length <= 1048576), isTrue);
    expect(jsonDecode(utf8.decode(_reassemble(packed.artifacts))), evidence);
  });

  test('aggregate artifact budgets use exact UTF-8 and escaped canonical bytes',
      () {
    final evidence = {'rows': List.filled(8000, 'é🌲\n\t"' * 20)};
    final original =
        SourceEventEvidenceArtifacts.pack(evidence, limits: _limits);
    final bytes =
        original.artifacts.fold<int>(0, (sum, a) => sum + a.bytes.length);
    final exact = SourceEventEvidenceArtifacts.pack(evidence,
        limits: NativeWriteLimits(
            maxArtifacts: original.artifacts.length,
            maxTotalArtifactBytes: bytes));
    expect(exact.artifacts.map((a) => a.handle),
        original.artifacts.map((a) => a.handle));
    for (final limits in [
      NativeWriteLimits(maxTotalArtifactBytes: bytes - 1),
      NativeWriteLimits(maxArtifacts: original.artifacts.length - 1),
      const NativeWriteLimits(maxTotalArtifactBytes: 1024),
    ]) {
      expect(
          () => SourceEventEvidenceArtifacts.pack(evidence, limits: limits),
          throwsA(isA<NativeWriteException>()
              .having((e) => e.code, 'code', 'native.quota.artifact')));
    }
  });

  test('aggregate text beyond its derived byte bound refuses deterministically',
      () {
    const limits = NativeWriteLimits(
        maxTotalArtifactBytes: 8192,
        jsonLimits: ContractLimits(maxTextCodeUnits: 4096));
    expect(
        () => SourceEventEvidenceArtifacts.pack(
            {'rows': List.filled(9, 'x' * 1024)}, limits: limits),
        throwsA(isA<ContractError>()
            .having((e) => e.code, 'code', 'json.textQuota')));
  });

  test('aggregate evidence retains individual string depth and node quotas',
      () {
    for (final entry in [
      (
        {
          'rows': ['x' * 1025]
        },
        const ContractLimits(maxStringCodeUnits: 1024),
        'json.textQuota'
      ),
      (
        {
          'rows': [
            [
              ['x']
            ]
          ]
        },
        const ContractLimits(maxDepth: 2),
        'json.quota'
      ),
      (
        {'rows': List.filled(10, 'x')},
        const ContractLimits(maxNodes: 5),
        'json.quota'
      ),
    ]) {
      expect(
          () => SourceEventEvidenceArtifacts.pack(entry.$1,
              limits: NativeWriteLimits(jsonLimits: entry.$2)),
          throwsA(
              isA<ContractError>().having((e) => e.code, 'code', entry.$3)));
    }
  });

  test('cancelled packing emits no artifact set', () {
    final cancellation = ScanCancellation()..cancel();
    expect(
        () => SourceEventEvidenceArtifacts.pack(
            {'rows': List.filled(1000, 'x' * 2000)},
            limits: _limits, cancellation: cancellation),
        throwsA(isA<ContractError>()
            .having((e) => e.code, 'code', 'source.cancelled')));
  });

  test('383 map bindings and 528 contexts restore exact canonical hashes', () {
    final encoding =
        SourceEventEvidenceEncoding(enabled: true, limits: _limits);
    final originals = [for (var i = 0; i < 528; i++) _context(i)];
    final originalHashes = originals.map(canonicalHashOf).toList();
    final encoded = [
      for (final context in originals) encoding.encodeContext(context)
    ];
    final tables = encoding.tables!;
    expect((tables['nativeBindings'] as Map).length, 1);
    expect((tables['mapAutonomyPages'] as Map).length, 24);
    expect((tables['witnesses'] as Map).length, 1);
    final restored = SourceEventEvidenceEncoding.restoreContexts(
        encoded, tables,
        limits: _limits);
    for (var i = 0; i < originals.length; i++) {
      expect(canonicalJsonOf(restored[i]), canonicalJsonOf(originals[i]));
      expect(canonicalHashOf(restored[i]), originalHashes[i]);
      expect(canonicalHashOf(originals[i]), originalHashes[i]);
    }
    final packedBytes = canonicalJsonOf({'contexts': encoded, 'tables': tables},
            limits: _limits.jsonLimits)
        .length;
    final expandedBytes =
        originals.fold<int>(0, (sum, c) => sum + canonicalJsonOf(c).length);
    expect(packedBytes, lessThan(expandedBytes ~/ 8));
    final again = SourceEventEvidenceEncoding(enabled: true, limits: _limits);
    final encodedAgain = [for (final c in originals) again.encodeContext(c)];
    expect(canonicalJsonOf({'contexts': encodedAgain, 'tables': again.tables}),
        canonicalJsonOf({'contexts': encoded, 'tables': tables}));
  });

  test('context tables reject missing altered and unreferenced proof rows', () {
    final encoding =
        SourceEventEvidenceEncoding(enabled: true, limits: _limits);
    final encoded = [encoding.encodeContext(_context(1))];
    Map<String, Object?> copy() =>
        jsonDecode(canonicalJsonOf(encoding.tables)) as Map<String, Object?>;
    final missing = copy();
    (missing['mapAutonomyPages'] as Map)
        .remove((missing['mapAutonomyPages'] as Map).keys.first);
    final altered = copy();
    ((altered['witnesses'] as Map).values.first as Map)['id'] = 2;
    final extra = copy();
    (extra['mapAutonomyPages'] as Map)[canonicalHashOf({'extra': true}).value] =
        {'extra': true};
    final badReference = jsonDecode(canonicalJsonOf(encoded)) as List;
    badReference.single['proof']['mapAutonomyAudit']['pageListRef'] = '0' * 64;
    for (final bad in [missing, altered, extra]) {
      expect(
          () => SourceEventEvidenceEncoding.restoreContexts(encoded, bad,
              limits: _limits),
          throwsA(isA<NativeWriteException>()));
    }
    expect(
        () => SourceEventEvidenceEncoding.restoreContexts([
              Map<String, Object?>.from(badReference.single as Map)
            ], encoding.tables!, limits: _limits),
        throwsA(isA<NativeWriteException>()));
  });

  test('indexed page references reject malformed indexes and altered pages',
      () {
    final encoding =
        SourceEventEvidenceEncoding(enabled: true, limits: _limits);
    final encoded = [encoding.encodeContext(_context(1))];
    Map<String, Object?> copyTables() =>
        jsonDecode(canonicalJsonOf(encoding.tables)) as Map<String, Object?>;
    List<Map<String, Object?>?> copyContexts() =>
        (jsonDecode(canonicalJsonOf(encoded)) as List)
            .map((value) => Map<String, Object?>.from(value as Map))
            .toList();
    for (final index in <Object?>[-1, 100000, 0.5, true, '0', null]) {
      final tables = copyTables();
      final contexts = copyContexts();
      final lists = tables['mapAutonomyPageLists'] as Map;
      final pages = List<Object?>.from(lists.values.single as List);
      pages[0] = index;
      final hash = canonicalHashOf(pages).value;
      lists
        ..clear()
        ..[hash] = pages;
      ((contexts.single!['proof'] as Map)['mapAutonomyAudit']
          as Map)['pageListRef'] = hash;
      expect(
          () => SourceEventEvidenceEncoding.restoreContexts(contexts, tables,
              limits: _limits),
          throwsA(isA<NativeWriteException>()),
          reason: 'index=$index');
    }
    final altered = copyTables();
    final row = (altered['mapAutonomyPages'] as Map)['0'] as Map;
    (row['page'] as Map)['row'] = 1000;
    final missingHash = copyTables();
    ((missingHash['mapAutonomyPages'] as Map)['0'] as Map).remove('sha256');
    final legacy = copyTables()
      ..['contract'] = 'source-event-execution-context-tables-v1';
    final legacyV2 = copyTables()
      ..['contract'] = 'source-event-execution-context-tables-v2';
    for (final tables in [altered, missingHash, legacy, legacyV2]) {
      expect(
          () => SourceEventEvidenceEncoding.restoreContexts(encoded, tables,
              limits: _limits),
          throwsA(isA<NativeWriteException>()));
    }
  });

  test('disabled shared tables preserve the exact context representation', () {
    final encoding =
        SourceEventEvidenceEncoding(enabled: false, limits: _limits);
    final context = _context(1);
    expect(identical(encoding.encodeContext(context), context), isTrue);
    expect(encoding.tables, isNull);
    expect(encoding.encodeContext(null), isNull);
  });

  test(
      'large event projection preserves canonical evidence across bounded artifacts',
      () async {
    final fixture =
        await LiteralTileFixture.create(includeEventSystem: true, maps: [
      for (var mapId = 1; mapId <= 4; mapId++)
        LiteralFixtureMap(id: mapId, events: [
          for (var id = 1; id <= 400; id++)
            LiteralFixtureEvent(id: id, x: 0, y: 0, pages: const [
              LiteralFixtureEventPage(commands: []),
              LiteralFixtureEventPage(selfSwitch: 'A', commands: []),
            ]),
        ])
    ]);
    final source = fixture.source;
    expect(source.maps, isNotEmpty,
        reason: source.diagnostics.map((d) => d.toJson()).toString());
    final analysis = SourceEventAnalyzer.forProject(source,
        profile: SourceEventProfile.forProject(
          source,
          interpretationProfile: fixtureSourceInterpretationProfile,
        )).analyze();
    final projection = const SourceEventProjector().project(
        source: source,
        analysis: analysis,
        nativeMaps: {
          for (final ir in source.maps)
            ir.map.sourceMapId: MapData(
                id: 'native_${ir.map.sourceMapId}',
                name: 'Map',
                size: GridSize(width: ir.map.width, height: ir.map.height))
        },
        limits: _limits);
    final bytes = utf8.encode(canonicalJsonOf(projection.semanticEvidence,
        limits: _limits.jsonLimits));
    expect(bytes.length, greaterThan(1048576));
    expect(projection.artifacts.length, greaterThan(1));
    expect(
        projection.artifacts.every((a) => a.bytes.length <= 1048576), isTrue);
    expect(_reassemble(projection.artifacts), bytes);
  });
}
