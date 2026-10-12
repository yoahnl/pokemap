import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';

Sha256Hash nativeFixtureHash(List<int> bytes) =>
    Sha256Hash(crypto.sha256.convert(bytes).toString());

List<int> nativeFixturePngWithIdat(List<int> original, List<int> idat) => [
      ...original.take(33),
      ..._pngChunk('IDAT', idat),
      ..._pngChunk('IEND', []),
    ];

List<int> _pngChunk(String type, List<int> payload) {
  final body = [...ascii.encode(type), ...payload];
  var crc = 0xffffffff;
  for (final byte in body) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 1) == 0 ? crc >> 1 : (crc >> 1) ^ 0xedb88320;
    }
  }
  final size = ByteData(4)..setUint32(0, payload.length, Endian.big);
  final checksum = ByteData(4)..setUint32(0, crc ^ 0xffffffff, Endian.big);
  return [
    ...size.buffer.asUint8List(),
    ...body,
    ...checksum.buffer.asUint8List()
  ];
}

final class NativeFixtureApproval {
  const NativeFixtureApproval(this.plan, this.context);

  final ConversionPlan plan;
  final PlanContext context;
}

NativeFixtureApproval approveNativeFixtureDraft(NativeProjectDraft draft,
    {String? bindingEvidence,
    bool offline = true,
    bool exampleOnly = false,
    bool approved = true,
    String state = 'ready',
    String requestedMode = 'study',
    List<int>? selectedSourceMapIds,
    List<int> dependencySourceMapIds = const []}) {
  final snapshot = draft.source.snapshot;
  final capabilities = TargetCapabilities.fromJson({
    'schemaVersion': '1.0',
    'kind': 'targetCapabilities',
    'exampleOnly': false,
    'profileId': 'original-native-writer-harness',
    'repository': 'yoahnl/pokemap',
    'revision': 'controlled-fixture-local-v1',
    'capabilities': [
      {
        'capabilityId': 'native.project.loadSaveReload',
        'status': 'supported',
        'scope':
            'Controlled original native writer and literal tile fixtures only',
        'evidence': [
          {
            'type': 'test',
            'summary':
                'Synthetic admission context for controlled original writer and literal tile qualification fixtures',
            'reference': 'fixture:original-native-writer-v1',
          }
        ],
        'limitations': [
          'Controlled qualification fixtures only; no production approval or gameplay certification'
        ],
      }
    ],
  });
  final decisions = ReviewDecisions.fromJson({
    'schemaVersion': '1.0',
    'kind': 'reviewDecisions',
    'exampleOnly': false,
    'sessionId': 'original-native-fixture-session',
    'sourceSnapshotHash': snapshot.canonicalHash.value,
    'revision': 1,
    'decisions': <Object?>[],
  });
  final rulesHash = canonicalHashOf(
      {'fixtureRules': 'controlled-original-native-literal-fixtures-v1'});
  final plan = ConversionPlan.fromJson({
    'schemaVersion': '1.0',
    'kind': 'conversionPlan',
    'exampleOnly': exampleOnly,
    'planId': 'original-native-fixture-plan',
    'state': state,
    'sourceSnapshotHash': snapshot.canonicalHash.value,
    'targetProfileHash': capabilities.canonicalHash.value,
    'rulesHash': rulesHash.value,
    'decisionsHash': decisions.canonicalHash.value,
    'decisionRevision': 1,
    'converterVersion': 'original-harness-v1',
    'logicalProjectNamespace': snapshot.logicalProjectNamespace.value,
    'requestedMode': requestedMode,
    'selectedSourceMapIds':
        selectedSourceMapIds ?? draft.source.selectedSourceMapIds,
    'dependencySourceMapIds': dependencySourceMapIds,
    'outputPolicy': {
      'destinationFolderName': draft.folderName,
      'destinationMustBeNew': true,
      'offline': offline,
      'assetOutputMode': 'sharedAtlas',
    },
    'operations': [
      for (final mutation in draft.mutations)
        {
          'operationId': mutation.operationId.value,
          'domain':
              mutation.actionId.startsWith('tileset.') ? 'assets' : 'maps',
          'sourceEntityIds':
              mutation.sourceEntityIds.map((id) => id.value).toList(),
          'targetEntityIds':
              mutation.targetEntityIds.map((id) => id.value).toList(),
          'targetActionId': mutation.actionId,
          'status': 'planned',
          'evidenceRefs': [bindingEvidence ?? draft.bindingEvidence],
        }
    ],
    'findings': <Object?>[],
    'approvedByHuman': approved,
  });
  return NativeFixtureApproval(
      plan,
      PlanContext(
        logicalProjectNamespace: snapshot.logicalProjectNamespace,
        sourceSnapshotHash: snapshot.canonicalHash,
        sessionId: decisions.sessionId,
        targetCapabilities: capabilities,
        rulesHash: rulesHash,
        decisions: decisions,
        candidates: [],
        converterVersion: plan.converterVersion,
        approvedPlanHash: plan.canonicalHash,
        sourceMapIds: draft.source.selectedSourceMapIds.toSet(),
        sourceEntityIds:
            draft.mutations.expand((value) => value.sourceEntityIds).toSet(),
        targetEntityIds:
            draft.mutations.expand((value) => value.targetEntityIds).toSet(),
        actionCapabilities: {
          for (final value in draft.mutations)
            value.actionId: ConverterId('native.project.loadSaveReload'),
        },
        approvedCandidateHashes: {},
      ));
}

NativeProjectDraft copyNativeFixtureDraft(NativeProjectDraft draft,
        {NormalizedSourceProject? source,
        String? projectName,
        String? parentPath,
        String? folderName,
        Map<int, String>? mapIds,
        List<NativeArtifact>? artifacts,
        List<NativeMutation>? mutations,
        Map<String, Object?>? compositionEvidence,
        int? defaultMapWidth,
        int? defaultMapHeight,
        NativeWriteLimits limits = const NativeWriteLimits()}) =>
    NativeProjectDraft(
      source: source ?? draft.source,
      projectName: projectName ?? draft.projectName,
      parentPath: parentPath ?? draft.parentPath,
      folderName: folderName ?? draft.folderName,
      sourceRootPath: draft.sourceRootPath,
      mapIds: mapIds ?? draft.mapIds,
      artifacts: artifacts ?? draft.artifacts,
      mutations: mutations ?? draft.mutations,
      compositionEvidence: compositionEvidence ?? draft.compositionEvidence,
      defaultMapWidth: defaultMapWidth ?? draft.defaultMapWidth,
      defaultMapHeight: defaultMapHeight ?? draft.defaultMapHeight,
      limits: limits,
    );

NativeMutation copyNativeFixtureMutation(NativeMutation mutation,
        {ConverterId? operationId,
        String? actionId,
        int? actionVersion,
        List<ConverterId>? sourceEntityIds,
        List<ConverterId>? targetEntityIds,
        Map<String, Object?>? parameters}) =>
    NativeMutation(
      operationId: operationId ?? mutation.operationId,
      actionId: actionId ?? mutation.actionId,
      actionVersion: actionVersion ?? mutation.actionVersion,
      sourceEntityIds: sourceEntityIds ?? mutation.sourceEntityIds,
      targetEntityIds: targetEntityIds ?? mutation.targetEntityIds,
      parameters: parameters ?? mutation.parameters,
    );

final class NativeWriterFixture {
  NativeWriterFixture._(this.sourceRootPath, this.sourceBytes, this.atlasBytes,
      this.source, this.expectedMap, this.draft, this.plan, this.context);

  final String sourceRootPath;
  final Map<String, List<int>> sourceBytes;
  final List<int> atlasBytes;
  final NormalizedSourceProject source;
  final MapData expectedMap;
  final NativeProjectDraft draft;
  final ConversionPlan plan;
  final PlanContext context;

  static Future<NativeWriterFixture> create(
    String parentPath, {
    String? sourceRootPath,
    String folderName = 'converted-fixture',
    String namespace = 'original-native-writer-fixture',
  }) async {
    final sourcePath = sourceRootPath ?? '$parentPath/original-source';
    await Directory(sourcePath).create(recursive: true);
    final raster = image.Image(width: 64, height: 32, numChannels: 4);
    for (var y = 0; y < 32; y++) {
      for (var x = 0; x < 64; x++) {
        raster.setPixelRgba(x, y, x < 32 ? 191 : 23, x < 32 ? 31 : 173,
            x < 32 ? 47 : 211, x == 0 && y == 0 ? 0 : 255);
      }
    }
    final png = List<int>.unmodifiable(image.encodePng(raster));
    final bytes = <String, List<int>>{
      'README.md':
          utf8.encode('Controlled original Pokemon Essentials v21.1 fixture\n'),
      'Data/MapInfos.rxdata': _Marshal().dump({
        1: _Object('RPG::MapInfo', {
          '@name': 'Original fixture map',
          '@parent_id': 0,
          '@order': 1,
          '@expanded': true,
          '@scroll_x': 0,
          '@scroll_y': 0,
        }),
      }),
      'Data/Map001.rxdata': _Marshal().dump(_Object('RPG::Map', {
        '@tileset_id': 1,
        '@width': 3,
        '@height': 3,
        '@data': _Table(3, 3, 3, [
          384,
          385,
          0,
          385,
          384,
          385,
          0,
          385,
          384,
          ...List<int>.filled(18, 0),
        ]),
        '@events': <int, Object?>{},
        '@autoplay_bgm': false,
        '@autoplay_bgs': false,
        '@encounter_list': <Object?>[],
        '@encounter_step': 30,
      })),
      'Data/Tilesets.rxdata': _Marshal().dump([
        null,
        _Object('RPG::Tileset', {
          '@id': 1,
          '@name': 'Original two tiles',
          '@tileset_name': 'FixtureAtlas',
          '@autotile_names': List<String>.filled(7, ''),
          '@panorama_name': '',
          '@fog_name': '',
          '@battleback_name': '',
          '@passages':
              _Table(386, 1, 1, List<int>.filled(386, 0), dimensions: 1),
          '@priorities':
              _Table(386, 1, 1, List<int>.filled(386, 0), dimensions: 1),
          '@terrain_tags':
              _Table(386, 1, 1, List<int>.filled(386, 0), dimensions: 1),
        }),
      ]),
      'Graphics/Tilesets/FixtureAtlas.png': png,
    };
    for (final entry in bytes.entries) {
      final file = File('$sourcePath/${entry.key}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value, flush: true);
    }
    final entries = <SourceFileEntry>[
      for (final entry in bytes.entries)
        SourceFileEntry(
          fileId: ConverterId(
              'fixture-file:${base64Url.encode(utf8.encode(entry.key)).replaceAll('=', '')}'),
          relativePath: entry.key,
          kind: SourceNodeKind.file,
          byteLength: entry.value.length,
          sha256: nativeFixtureHash(entry.value),
          format: entry.key.endsWith('.rxdata')
              ? 'ruby-marshal'
              : entry.key.endsWith('.png')
                  ? 'png'
                  : 'text',
          family: entry.key.endsWith('.rxdata')
              ? 'rmxp'
              : entry.key.endsWith('.png')
                  ? 'raster'
                  : 'documentation',
        ),
    ];
    final snapshot = SourceSnapshot(
      logicalProjectNamespace: ConverterId(namespace),
      policyHash: SourceScanPolicy().canonicalHash,
      entries: entries,
      diagnostics: [],
      excludedPaths: [],
      profileEvidence: [
        SourceProfileEvidence(
          relativePath: 'README.md',
          fileHash: nativeFixtureHash(bytes['README.md']!),
          line: 1,
          version: '21.1',
          excerpt: 'Controlled original Pokemon Essentials v21.1 fixture',
        ),
      ],
      state: SourceScanState.complete,
    );
    final source = await const RmxpSourceNormalizer()
        .normalize(snapshot: snapshot, files: _FixtureFiles(snapshot, bytes));
    if (!source.canPlan) {
      throw StateError(
          'Original source fixture cannot plan: ${source.diagnostics.map((value) => value.toJson()).toList()}');
    }
    final nativeMap = MapData(
      id: 'fixture_map',
      name: 'Original fixture map',
      size: const GridSize(width: 3, height: 3),
      version: ProjectVersion.v8,
      visualStack: MapVisualStackConfig.canonicalV1,
      layers: [
        MapLayer.tile(
          id: 'fixture_base',
          name: 'Original base',
          palette: const [
            TileLayerPaletteEntry(tilesetId: 'fixture_atlas', localTileId: 0),
            TileLayerPaletteEntry(tilesetId: 'fixture_atlas', localTileId: 1),
          ],
          cells: const [1, 2, 0, 2, 1, 2, 0, 2, 1],
        ),
      ],
    );
    final artifact =
        NativeArtifact(bytes: png, expectedSha256: nativeFixtureHash(png));
    final sourceImage = snapshot.entries
        .singleWhere((entry) => entry.relativePath.endsWith('.png'));
    final sourceMapId = source.mapIdentity(1);
    final mutations = [
      NativeMutation(
        operationId: ConverterId('fixture-import-image'),
        actionId: 'tileset.import_image',
        sourceEntityIds: [sourceImage.fileId],
        targetEntityIds: [
          ConverterId('fixture_atlas'),
          ConverterId('image_fixture_atlas')
        ],
        parameters: {
          'artifactHandle': artifact.handle,
          'tilesetId': 'fixture_atlas',
          'name': 'Original two tiles',
          'tileWidth': 32,
          'tileHeight': 32,
        },
      ),
      NativeMutation(
        operationId: ConverterId('fixture-create-map'),
        actionId: 'map.create',
        sourceEntityIds: [sourceMapId],
        targetEntityIds: [ConverterId(nativeMap.id)],
        parameters: {
          'mapId': nativeMap.id,
          'name': nativeMap.name,
          'width': 3,
          'height': 3
        },
      ),
      NativeMutation(
        operationId: ConverterId('fixture-save-map'),
        actionId: 'map.save',
        sourceEntityIds: [sourceMapId],
        targetEntityIds: [ConverterId(nativeMap.id)],
        parameters: {'map': nativeMap.toJson()},
      ),
    ];
    final draft = NativeProjectDraft(
      source: source,
      projectName: 'Original native writer fixture',
      parentPath: parentPath,
      folderName: folderName,
      sourceRootPath: sourcePath,
      mapIds: {1: nativeMap.id},
      artifacts: [artifact],
      mutations: mutations,
    );
    final approval = approveNativeFixtureDraft(draft);
    return NativeWriterFixture._(
      sourcePath,
      Map.unmodifiable(bytes
          .map((key, value) => MapEntry(key, List<int>.unmodifiable(value)))),
      png,
      source,
      nativeMap,
      draft,
      approval.plan,
      approval.context,
    );
  }
}

final class _FixtureFiles implements SourceFilePort {
  _FixtureFiles(this.snapshot, this.bytes);
  final SourceSnapshot snapshot;
  final Map<String, List<int>> bytes;

  @override
  Future<List<int>> read(ConverterId fileId) async => bytes[snapshot.entries
      .singleWhere((entry) => entry.fileId == fileId)
      .relativePath]!;
}

final class _Object {
  const _Object(this.name, this.fields);
  final String name;
  final Map<String, Object?> fields;
}

final class _Table {
  const _Table(this.x, this.y, this.z, this.cells, {this.dimensions = 3});
  final int x;
  final int y;
  final int z;
  final int dimensions;
  final List<int> cells;
}

final class _Marshal {
  List<int> dump(Object? value) => [4, 8, ..._value(value)];

  List<int> _integer(int value) {
    if (value == 0) return [0];
    if (value > 0 && value < 123) return [value + 5];
    if (value < 0 && value > -124) return [(value - 5) & 255];
    var width = 1;
    while (value >= (1 << (8 * width)) || value < -(1 << (8 * width))) {
      width++;
    }
    return [
      value >= 0 ? width : (-width) & 255,
      for (var i = 0; i < width; i++) (value >> (8 * i)) & 255
    ];
  }

  List<int> _symbol(String value) {
    final bytes = utf8.encode(value);
    return [0x3a, ..._integer(bytes.length), ...bytes];
  }

  List<int> _value(Object? value) {
    if (value == null) return [0x30];
    if (value is bool) return [value ? 0x54 : 0x46];
    if (value is int) return [0x69, ..._integer(value)];
    if (value is String) {
      final bytes = utf8.encode(value);
      return [0x22, ..._integer(bytes.length), ...bytes];
    }
    if (value is List) {
      return [
        0x5b,
        ..._integer(value.length),
        for (final item in value) ..._value(item)
      ];
    }
    if (value is Map) {
      return [
        0x7b,
        ..._integer(value.length),
        for (final entry in value.entries) ...[
          ..._value(entry.key),
          ..._value(entry.value)
        ]
      ];
    }
    if (value is _Object) {
      return [
        0x6f,
        ..._symbol(value.name),
        ..._integer(value.fields.length),
        for (final entry in value.fields.entries) ...[
          ..._symbol(entry.key),
          ..._value(entry.value)
        ]
      ];
    }
    if (value is _Table) {
      final data = ByteData(20 + value.cells.length * 2)
        ..setUint32(0, value.dimensions, Endian.little)
        ..setUint32(4, value.x, Endian.little)
        ..setUint32(8, value.y, Endian.little)
        ..setUint32(12, value.z, Endian.little)
        ..setUint32(16, value.cells.length, Endian.little);
      for (var i = 0; i < value.cells.length; i++) {
        data.setInt16(20 + i * 2, value.cells[i], Endian.little);
      }
      final bytes = data.buffer.asUint8List();
      return [0x75, ..._symbol('Table'), ..._integer(bytes.length), ...bytes];
    }
    throw ArgumentError('Unsupported controlled Marshal fixture value');
  }
}
