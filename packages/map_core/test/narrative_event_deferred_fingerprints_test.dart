import 'dart:convert';
import 'dart:isolate';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final eager = buildNarrativeEventProjectCatalog(
    project: _project,
    maps: [_map],
  );

  test('deferred fingerprints stay untouched during catalog resolutions', () {
    var manifestReads = 0;
    var mapReads = 0;
    final hashes = Map<String, String>.of(eager.mapHashes);
    final catalog = _deferred(
      eager,
      manifestHash: () {
        manifestReads++;
        return eager.manifestHash;
      },
      mapHashes: () {
        mapReads++;
        return hashes;
      },
    );
    expect([manifestReads, mapReads], [0, 0]);
    expect(_semantics(catalog), _semantics(eager));
    expect(
      catalog.resolveSource(NarrativeEventSourceRef.mapEnter('field')).status,
      eager.resolveSource(NarrativeEventSourceRef.mapEnter('field')).status,
    );
    expect(
      catalog.resolveScene('scene').status,
      eager.resolveScene('scene').status,
    );
    expect(
      catalog.resolveEvent('missing').status,
      NarrativeEventProjectResolutionStatus.missing,
    );
    expect(catalog.hasBlockingDiagnostics, eager.hasBlockingDiagnostics);
    expect([manifestReads, mapReads], [0, 0]);
    expect(catalog.manifestHash, eager.manifestHash);
    expect(catalog.manifestHash, eager.manifestHash);
    expect([manifestReads, mapReads], [1, 0]);
    final first = catalog.mapHashes;
    expect(first, eager.mapHashes);
    expect(catalog.mapHashes, same(first));
    expect([manifestReads, mapReads], [1, 1]);
    hashes['field'] = 'changed-after-read';
    expect(catalog.mapHashes, eager.mapHashes);
    expect(() => first['another'] = 'hash', throwsUnsupportedError);
  });

  test('invalid deferred manifest hashes fail only when read', () {
    final catalog = _deferred(
      eager,
      manifestHash: () => ' invalid ',
      mapHashes: () => const {},
    );
    expect(
      catalog.resolveScene('scene').status,
      eager.resolveScene('scene').status,
    );
    expect(() => catalog.manifestHash, throwsArgumentError);
  });

  for (final hashes in <Map<String, String>>[
    {'': 'hash'},
    {' field': 'hash'},
    {'field': ''},
    {'field': ' hash '},
  ]) {
    test('invalid deferred map hashes fail only when read: $hashes', () {
      final catalog = _deferred(
        eager,
        manifestHash: () => 'manifest',
        mapHashes: () => hashes,
      );
      expect(catalog.hasBlockingDiagnostics, eager.hasBlockingDiagnostics);
      expect(() => catalog.mapHashes, throwsArgumentError);
    });
  }

  test('ordinary constructor still rejects invalid fingerprints eagerly', () {
    expect(
      () => _ordinary(eager, manifestHash: '', mapHashes: const {}),
      throwsArgumentError,
    );
    expect(
      () => _ordinary(
        eager,
        manifestHash: 'valid',
        mapHashes: const {'field': ''},
      ),
      throwsArgumentError,
    );
  });

  test(
    'builder deferral preserves hashes and snapshots the supplied map list',
    () {
      final maps = <MapData>[_map];
      final deferred = buildNarrativeEventProjectCatalog(
        project: _project,
        maps: maps,
        deferFingerprints: true,
      );
      expect(_semantics(deferred), _semantics(eager));
      maps[0] = _map.copyWith(id: 'replacement', name: 'Replacement');
      maps.clear();
      expect(deferred.manifestHash, eager.manifestHash);
      expect(deferred.mapHashes, eager.mapHashes);
      expect(deferred.nativeMaps, [_map]);
      expect(deferred.nativeMapIds, ['field']);
    },
  );

  test('default builder retains eager canonicalization validation', () {
    final invalid = _project.copyWith(
      globalProperties: {'invalid': double.nan},
    );
    expect(
      () => buildNarrativeEventProjectCatalog(project: invalid, maps: [_map]),
      throwsA(isA<JsonUnsupportedObjectError>()),
    );
    final deferred = buildNarrativeEventProjectCatalog(
      project: invalid,
      maps: [_map],
      deferFingerprints: true,
    );
    expect(deferred.scenes.single.scene.id, 'scene');
    expect(
      () => deferred.manifestHash,
      throwsA(isA<JsonUnsupportedObjectError>()),
    );
  });

  test(
    'deferred callbacks and builder catalogs cross a real isolate boundary',
    () async {
      final transferred = await Isolate.run(() {
        final original = buildNarrativeEventProjectCatalog(
          project: _project,
          maps: [_map],
        );
        var manifestReads = 0;
        var mapReads = 0;
        return (
          catalog: _deferred(
            original,
            manifestHash: () {
              manifestReads++;
              return original.manifestHash;
            },
            mapHashes: () {
              mapReads++;
              return original.mapHashes;
            },
          ),
          built: buildNarrativeEventProjectCatalog(
            project: _project,
            maps: [_map],
            deferFingerprints: true,
          ),
          reads: () => (manifestReads, mapReads),
        );
      });
      expect(transferred.reads(), (0, 0));
      expect(_semantics(transferred.catalog), _semantics(eager));
      expect(transferred.catalog.manifestHash, eager.manifestHash);
      expect(transferred.catalog.manifestHash, eager.manifestHash);
      expect(transferred.reads(), (1, 0));
      final hashes = transferred.catalog.mapHashes;
      expect(hashes, eager.mapHashes);
      expect(transferred.catalog.mapHashes, same(hashes));
      expect(transferred.reads(), (1, 1));
      expect(transferred.built.manifestHash, eager.manifestHash);
      expect(transferred.built.mapHashes, eager.mapHashes);
      expect(transferred.built.mapHashes, same(transferred.built.mapHashes));
    },
  );

  test(
    'invalid map fingerprints retain eager default and deferred getter validation',
    () {
      final map = _map.copyWith(properties: {'invalid': double.infinity});
      expect(
        () => buildNarrativeEventProjectCatalog(project: _project, maps: [map]),
        throwsA(isA<JsonUnsupportedObjectError>()),
      );
      final deferred = buildNarrativeEventProjectCatalog(
        project: _project,
        maps: [map],
        deferFingerprints: true,
      );
      expect(_semantics(deferred), _semantics(eager));
      expect(deferred.manifestHash, eager.manifestHash);
      expect(
        () => deferred.mapHashes,
        throwsA(isA<JsonUnsupportedObjectError>()),
      );
    },
  );
}

const _map = MapData(
  id: 'field',
  name: 'Field',
  size: GridSize(width: 4, height: 4),
);

final _project = ProjectManifest(
  name: 'Deferred fingerprints',
  maps: const [
    ProjectMapEntry(
      id: 'field',
      name: 'Field',
      relativePath: 'maps/field.json',
    ),
  ],
  tilesets: const [],
  scenes: [
    SceneAsset(
      id: 'scene',
      name: 'Scene',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(),
          ),
        ],
        edges: [
          SceneEdge(
            id: 'end',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
    ),
  ],
);

NarrativeEventProjectCatalog _deferred(
  NarrativeEventProjectCatalog source, {
  required String Function() manifestHash,
  required Map<String, String> Function() mapHashes,
}) => NarrativeEventProjectCatalog.withDeferredFingerprints(
  manifestHash: manifestHash,
  mapHashes: mapHashes,
  spatialSources: source.spatialSources,
  outcomeSources: source.outcomeSources,
  scenes: source.scenes,
  facts: source.facts,
  events: source.events,
  diagnostics: source.diagnostics,
  nativeMapIds: source.nativeMapIds,
  nativeMaps: source.nativeMaps,
);

NarrativeEventProjectCatalog _ordinary(
  NarrativeEventProjectCatalog source, {
  required String manifestHash,
  required Map<String, String> mapHashes,
}) => NarrativeEventProjectCatalog(
  manifestHash: manifestHash,
  mapHashes: mapHashes,
  spatialSources: source.spatialSources,
  outcomeSources: source.outcomeSources,
  scenes: source.scenes,
  facts: source.facts,
  events: source.events,
  diagnostics: source.diagnostics,
  nativeMapIds: source.nativeMapIds,
  nativeMaps: source.nativeMaps,
);

Map<String, Object?> _semantics(NarrativeEventProjectCatalog catalog) => {
  'scenes': [for (final value in catalog.scenes) value.toDebugJson()],
  'events': [for (final value in catalog.events) value.toDebugJson()],
  'facts': [for (final value in catalog.facts) value.toDebugJson()],
  'diagnostics': [for (final value in catalog.diagnostics) value.toDebugJson()],
  'spatial': catalog.spatialSources.toDebugJson(),
  'outcomes': catalog.outcomeSources.toDebugJson(),
};
