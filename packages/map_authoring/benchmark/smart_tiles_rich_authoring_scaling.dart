import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../../tools/performance/benchmark_support.dart';
import '../../../tools/performance/smart_tiles_rich_map_fixture.dart';

const _tileLayerCount = 3;
const _tileGids = <int>[1, 2147483649, 1073741825, 536870913];
const _tsx = '''
<tileset name="Rich benchmark" tilewidth="1" tileheight="1"
    tilecount="1" columns="1">
  <image source="rich.png" width="1" height="1"/>
</tileset>
''';

Future<void> main(List<String> arguments) async {
  try {
    final cli = PerformanceCli.parse(
      arguments,
      allowed: const <String>{
        'warmups',
        'samples',
        'recovery-samples',
        'extents',
        'output',
      },
    );
    final warmups = cli.nonNegativeInt('warmups', fallback: 1);
    final samples = cli.positiveInt('samples', fallback: 5);
    final recoverySamples = cli.positiveInt('recovery-samples', fallback: 1);
    final extents = cli.positiveInts(
      'extents',
      fallback: smartTilesRichMapExtents.join(','),
      singularLabel: 'extent',
    );
    for (final extent in extents) {
      if (!smartTilesRichMapExtents.contains(extent)) {
        throw FormatException(
          'extent must be one of ${smartTilesRichMapExtents.join(', ')}',
        );
      }
    }
    final outputPath = cli.requiredValue('output');
    validatedPackageOutput(outputPath, packageName: 'map_authoring');

    final results = <Map<String, Object?>>[];
    for (final extent in extents) {
      final source = _RichTiledSource.generate(extent);
      for (var index = 0; index < warmups; index += 1) {
        await _measureImport(source, recovery: false);
      }
      final measured = <_ImportMeasurement>[];
      for (var index = 0; index < samples; index += 1) {
        measured.add(await _measureImport(source, recovery: false));
      }
      final recovered = <_ImportMeasurement>[];
      for (var index = 0; index < recoverySamples; index += 1) {
        recovered.add(await _measureImport(source, recovery: true));
      }
      _requireStable(measured, label: 'import ${extent}x$extent');
      _requireStable(recovered, label: 'recovery ${extent}x$extent');
      final first = measured.first;
      final firstRecovery = recovered.first;
      results.add(<String, Object?>{
        'extent': extent,
        'datasetFingerprint': source.fingerprint,
        'rssBytesAfterSamples': ProcessInfo.currentRss,
        'profiles': <String, Object?>{
          'plan': _phaseProfile(measured, _Phase.plan),
          'apply': _phaseProfile(measured, _Phase.apply),
          'reopen': _phaseProfile(measured, _Phase.reopen),
          'recovery': _phaseProfile(recovered, _Phase.recovery),
        },
        'workCounts': <String, Object?>{
          'sourceCellCount': extent * extent * _tileLayerCount,
          'tileLayerCount': first.tileLayerCount,
          'objectCount': first.objectCount,
          'affectedResourceCount': first.affectedResourceCount,
          'diffEntryCount': first.diffEntryCount,
          'journalBytes': first.journalBytes,
          'recoveredResourceCount': firstRecovery.affectedResourceCount,
          'recoveryJournalBytes': firstRecovery.journalBytes,
        },
        'reopenedSnapshotChecksum': first.snapshotChecksum,
      });
    }

    final receipt = await performanceReceipt(
      benchmark: 'smart_tiles_rich_authoring_scaling',
      warmups: warmups,
      sampleCount: samples,
      arguments: <String>[
        'benchmark/smart_tiles_rich_authoring_scaling.dart',
        ...arguments,
      ],
      metadata: <String, Object?>{
        'extents': extents,
        'recoverySampleCount': recoverySamples,
        'actionId': 'map.tiled.import',
        'transactionPolicy': 'recoverable-multi-resource',
      },
      results: results,
    );
    await writePerformanceReceipt(
      outputPath: outputPath,
      packageName: 'map_authoring',
      receipt: receipt,
    );
  } on FormatException catch (error) {
    stderr.writeln('smart_tiles_rich_authoring_scaling: ${error.message}');
    exitCode = 64;
  }
}

Map<String, Object?> _phaseProfile(
  List<_ImportMeasurement> measurements,
  _Phase phase,
) {
  final checksums = measurements
      .map((measurement) => measurement.checksumFor(phase))
      .toList(growable: false);
  if (checksums.any((checksum) => checksum != checksums.first)) {
    throw StateError('${phase.name} produced an unstable checksum.');
  }
  return <String, Object?>{
    ...percentileFields(
      measurements
          .map((measurement) => measurement.elapsedFor(phase))
          .toList(growable: false),
    ),
    'checksum': checksums.first,
  };
}

void _requireStable(
  List<_ImportMeasurement> measurements, {
  required String label,
}) {
  final checksum = measurements.first.snapshotChecksum;
  if (measurements.any((measurement) =>
      measurement.snapshotChecksum != checksum ||
      measurement.tileLayerCount != measurements.first.tileLayerCount ||
      measurement.objectCount != measurements.first.objectCount ||
      measurement.affectedResourceCount !=
          measurements.first.affectedResourceCount)) {
    throw StateError('$label produced unstable imported project evidence.');
  }
}

Future<_ImportMeasurement> _measureImport(
  _RichTiledSource source, {
  required bool recovery,
}) async {
  final root = await Directory.systemTemp.createTemp(
    recovery ? 'pokemap-rich-recovery-' : 'pokemap-rich-import-',
  );
  try {
    final manifest = ProjectManifest(
      name: 'Rich transactional import benchmark',
      version: ProjectVersion.v6,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
    );
    await File('${root.path}/project.json').writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(manifest.toJson())}\n',
      flush: true,
    );
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: <String>[root.path],
      fileReader: reader,
    );
    var token = 0;
    final handles = WorkspaceHandleStore(
      tokenFactory: (prefix) => '$prefix${token++}',
    );
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    ).openProject(root.path);
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final artifacts = MemoryArtifactStore(maximumArtifactBytes: 1024);
    final stored = await artifacts.put(
      _pngBytes,
      declaredMediaType: 'image/png',
    );
    var crashed = false;
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      artifactStore: artifacts,
      clock: () => DateTime.utc(2026, 8, 5, 10),
      faultInjector: recovery
          ? (context) {
              if (!crashed &&
                  context.checkpoint ==
                      AuthoringTransactionCheckpoint.afterResourcePromoted &&
                  context.promotionIndex == 1) {
                crashed = true;
                throw const AuthoringTransactionSimulatedCrash();
              }
            }
          : null,
    );
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    final before = await snapshots.load(opened.projectHandle);
    final request = AuthoringRequest(
      requestId: 'request-rich-${source.extent}',
      actionId: 'map.tiled.import',
      actionVersion: 1,
      workspaceHandle: opened.workspaceHandle.value,
      expectedRevision: before.revision,
      idempotencyKey:
          recovery ? 'rich-recovery-${source.extent}' : 'rich-${source.extent}',
      parameters: <String, Object?>{
        'mapId': 'rich-import-${source.extent}',
        'displayName': 'Rich import ${source.extent}x${source.extent}',
        'role': 'exterior',
        'tmx': source.tmx,
        'tilesets': <Object?>[
          <String, Object?>{
            'source': 'rich.tsx',
            'tsx': _tsx,
            'tilesetId': 'rich-import-tiles',
            'assetId': 'rich-import-image',
            'logicalPath': 'assets/tilesets/rich-import.png',
            'imageArtifacts': <Object?>[
              <String, Object?>{
                'source': 'rich.png',
                'artifactHandle': stored.reference.handle,
              },
            ],
          },
        ],
      },
    );

    final planWatch = Stopwatch()..start();
    final planned = await mutations.plan(opened.projectHandle, request);
    planWatch.stop();
    final plan = Map<String, Object?>.from(planned['plan']! as Map);
    final changeSet = Map<String, Object?>.from(plan['changeSet']! as Map);
    final planChecksum = stableFingerprint(<Object?>[
      plan['actionId'],
      plan['applicable'],
      (changeSet['changes']! as List).length,
      source.fingerprint,
    ]);
    final operationId = recovery
        ? 'operation-rich-recovery-${source.extent}'
        : 'operation-rich-${source.extent}';
    late final Map<String, Object?> applied;
    var applyUs = 0;
    var recoveryUs = 0;
    if (recovery) {
      final recoveryWatch = Stopwatch()..start();
      try {
        await mutations.apply(
          opened.projectHandle,
          planId: planned['planId']! as String,
          operationId: operationId,
        );
        throw StateError('The recovery benchmark did not inject its crash.');
      } on AuthoringTransactionSimulatedCrash {
        // The same production recovery path resumes the durable journal.
      }
      applied = await mutations.recover(
        opened.projectHandle,
        operationId: operationId,
      );
      recoveryWatch.stop();
      recoveryUs = recoveryWatch.elapsedMicroseconds;
    } else {
      final applyWatch = Stopwatch()..start();
      applied = await mutations.apply(
        opened.projectHandle,
        planId: planned['planId']! as String,
        operationId: operationId,
      );
      applyWatch.stop();
      applyUs = applyWatch.elapsedMicroseconds;
    }
    final receipt = AuthoringReceipt.fromJson(
      Map<String, dynamic>.from(applied['receipt']! as Map),
    );
    final applyChecksum = stableFingerprint(<Object?>[
      receipt.actionId,
      receipt.status.wireName,
      for (final resource in receipt.affectedResources)
        <String>[resource.kind, resource.id],
    ]);
    final journal = File(
      '${root.path}/.pokemap/authoring/transactions/$operationId/journal.json',
    );
    final journalBytes = await journal.length();

    await mutations.detachWorkspace(opened.workspaceHandle);
    var reopenToken = 0;
    final reopenedHandles = WorkspaceHandleStore(
      tokenFactory: (prefix) => '${prefix}reopen-${reopenToken++}',
    );
    final reopenWatch = Stopwatch()..start();
    final reopened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: reopenedHandles,
    ).openProject(root.path);
    final snapshot = await ProjectSnapshotLoader(handles: reopenedHandles).load(
      reopened.projectHandle,
      policy: ProjectSnapshotLoadPolicy.strict,
    );
    reopenWatch.stop();
    final map = snapshot.mapById('rich-import-${source.extent}');
    if (map == null) {
      throw StateError('The imported map is absent after reopening.');
    }
    final snapshotChecksum = _snapshotChecksum(snapshot, map);
    final tileLayerCount = map.layers.whereType<TileLayer>().length;
    final objectCount = map.layers
        .whereType<ObjectLayer>()
        .fold<int>(0, (total, layer) => total + layer.tileObjects.length);
    return _ImportMeasurement(
      planUs: planWatch.elapsedMicroseconds,
      applyUs: applyUs,
      reopenUs: reopenWatch.elapsedMicroseconds,
      recoveryUs: recoveryUs,
      planChecksum: planChecksum,
      applyChecksum: applyChecksum,
      snapshotChecksum: snapshotChecksum,
      tileLayerCount: tileLayerCount,
      objectCount: objectCount,
      affectedResourceCount: receipt.affectedResources.length,
      diffEntryCount: receipt.diff.entries.length,
      journalBytes: journalBytes,
    );
  } finally {
    await root.delete(recursive: true);
  }
}

String _snapshotChecksum(ProjectSnapshot snapshot, MapData map) {
  final layers = <Object?>[];
  for (final layer in map.layers) {
    switch (layer) {
      case TileLayer(:final cells, :final palette):
        layers.add(<Object?>[
          layer.id,
          'tile',
          cells.length,
          palette.length,
          cells.first,
          cells[cells.length ~/ 2],
          cells.last,
        ]);
      case ObjectLayer(:final tileObjects):
        layers.add(<Object?>[layer.id, 'object', tileObjects.length]);
      default:
        layers.add(<Object?>[layer.id, layer.runtimeType.toString()]);
    }
  }
  return stableFingerprint(<Object?>[
    snapshot.manifest.name,
    snapshot.manifest.maps.length,
    snapshot.manifest.tilesets.length,
    map.id,
    map.size.width,
    map.size.height,
    layers,
  ]);
}

enum _Phase { plan, apply, reopen, recovery }

final class _ImportMeasurement {
  const _ImportMeasurement({
    required this.planUs,
    required this.applyUs,
    required this.reopenUs,
    required this.recoveryUs,
    required this.planChecksum,
    required this.applyChecksum,
    required this.snapshotChecksum,
    required this.tileLayerCount,
    required this.objectCount,
    required this.affectedResourceCount,
    required this.diffEntryCount,
    required this.journalBytes,
  });

  final int planUs;
  final int applyUs;
  final int reopenUs;
  final int recoveryUs;
  final String planChecksum;
  final String applyChecksum;
  final String snapshotChecksum;
  final int tileLayerCount;
  final int objectCount;
  final int affectedResourceCount;
  final int diffEntryCount;
  final int journalBytes;

  int elapsedFor(_Phase phase) => switch (phase) {
        _Phase.plan => planUs,
        _Phase.apply => applyUs,
        _Phase.reopen => reopenUs,
        _Phase.recovery => recoveryUs,
      };

  String checksumFor(_Phase phase) => switch (phase) {
        _Phase.plan => planChecksum,
        _Phase.apply => applyChecksum,
        _Phase.reopen || _Phase.recovery => snapshotChecksum,
      };
}

final class _RichTiledSource {
  const _RichTiledSource._({
    required this.extent,
    required this.tmx,
    required this.objectCount,
    required this.fingerprint,
  });

  factory _RichTiledSource.generate(int extent) {
    final layers = <String>[
      for (var layerIndex = 0; layerIndex < _tileLayerCount; layerIndex += 1)
        _csvLayer(extent, layerIndex),
    ];
    final objects = StringBuffer();
    var objectId = 1;
    for (var y = 16; y < extent; y += 32) {
      for (var x = 16; x < extent; x += 32) {
        objects.writeln(
          '<object id="$objectId" name="Prop $x,$y" class="Decoration" '
          'gid="${_tileGids[objectId % _tileGids.length]}" '
          'x="$x" y="$y" width="1" '
          'height="1" rotation="${(objectId % 4) * 90}"/>',
        );
        objectId += 1;
      }
    }
    final tmx = '''
<map version="1.10" tiledversion="1.11.2" orientation="orthogonal"
    renderorder="right-down" width="$extent" height="$extent"
    tilewidth="1" tileheight="1" infinite="0"
    nextlayerid="${_tileLayerCount + 2}" nextobjectid="$objectId">
  <properties>
    <property name="benchmark" value="smart-tiles-rich"/>
    <property name="extent" type="int" value="$extent"/>
  </properties>
  <tileset firstgid="1" source="rich.tsx"/>
  ${layers.join('\n')}
  <objectgroup id="${_tileLayerCount + 1}" name="Rich props">
    $objects
  </objectgroup>
</map>
''';
    return _RichTiledSource._(
      extent: extent,
      tmx: tmx,
      objectCount: objectId - 1,
      fingerprint: stableFingerprint(<Object?>[
        extent,
        tmx,
        _tsx,
        stableBytesFingerprint(_pngBytes),
      ]),
    );
  }

  final int extent;
  final String tmx;
  final int objectCount;
  final String fingerprint;

  static String _csvLayer(int extent, int layerIndex) {
    final data = StringBuffer();
    final count = extent * extent;
    for (var index = 0; index < count; index += 1) {
      if (index > 0) data.write(',');
      final x = index % extent;
      final y = index ~/ extent;
      final empty = layerIndex > 0 && (x + y + layerIndex) % 5 == 0;
      data.write(
        empty ? 0 : _tileGids[(x * 3 + y * 5 + layerIndex) % _tileGids.length],
      );
    }
    return '''
  <layer id="${layerIndex + 1}" name="Rich layer ${layerIndex + 1}"
      width="$extent" height="$extent" opacity="${1 - layerIndex * 0.1}">
    <data encoding="csv">$data</data>
  </layer>
''';
  }
}

final List<int> _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+'
  'A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
