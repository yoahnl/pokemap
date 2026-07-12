import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/shadow/runtime_static_placed_element_shadow_sources.dart';
import 'package:path/path.dart' as p;

const _manifestFileName = 'capture_manifest.json';
const _overviewMaxWidth = 640;
const _overviewMaxHeight = 480;

const _canonicalMapIds = <String>[
  'map_bourg_selbrume',
  'map_port_brisants',
  'map_bois_chaise_brume',
  'map_marais_salants',
  'map_passage_dames',
  'map_phare_exterieur',
  'map_phare_interieur',
  'map_sommet_phare',
  'map_cabane_gardien',
  'map_maison_joueur',
];

/// Named review crops are intentionally explicit. They cover the authored
/// landmarks, entrances and story clues which cannot be judged reliably from
/// a downscaled whole-map overview.
const _namedCropsByMapId = <String, List<_NamedCropSpec>>{
  'map_bourg_selbrume': <_NamedCropSpec>[
    _NamedCropSpec('player_house', <String>[
      'pe_bourg_maison_joueur_facade',
    ]),
    _NamedCropSpec('pokemon_center', <String>[
      'pe_bourg_centre_facade',
    ]),
    _NamedCropSpec('village_well', <String>['pe_bourg_puits']),
    _NamedCropSpec('market_kiosk', <String>['pe_bourg_kiosque']),
  ],
  'map_port_brisants': <_NamedCropSpec>[
    _NamedCropSpec('wingull_nest', <String>['pe_port_nid_goelise']),
    _NamedCropSpec('harbor_boat', <String>['pe_port_bateau']),
    _NamedCropSpec('harbor_hangar', <String>['pe_port_hangar']),
  ],
  'map_bois_chaise_brume': <_NamedCropSpec>[
    _NamedCropSpec('forest_entry_sign', <String>['pe_bois_panneau_001']),
    _NamedCropSpec('forest_bench', <String>['pe_bois_banc_001']),
    _NamedCropSpec('fallen_trunk', <String>['pe_bois_tronc_tombe_001']),
  ],
  'map_marais_salants': <_NamedCropSpec>[
    _NamedCropSpec('salt_worker_cabin', <String>[
      'pe_marais_cabane_paludier',
    ]),
    _NamedCropSpec('marsh_sluice', <String>['pe_marais_ecluse']),
    _NamedCropSpec('clue_glass', <String>['pe_marais_indice_verre']),
    _NamedCropSpec('clue_electrical_tracks', <String>[
      'pe_marais_indice_traces_electriques',
    ]),
    _NamedCropSpec('clue_lens_marker', <String>[
      'pe_marais_indice_repere_lentille',
    ]),
    _NamedCropSpec('crystal_one', <String>['pe_marais_cristal_1']),
    _NamedCropSpec('crystal_two', <String>['pe_marais_cristal_2']),
    _NamedCropSpec('crystal_three', <String>['pe_marais_cristal_3']),
  ],
  'map_passage_dames': <_NamedCropSpec>[
    _NamedCropSpec('tide_barrier', <String>['pe_passage_barriere']),
    _NamedCropSpec('wet_causeway', <String>['pe_passage_chaussee_humide']),
    _NamedCropSpec('eastern_steps', <String>['pe_passage_marches']),
  ],
  'map_phare_exterieur': <_NamedCropSpec>[
    _NamedCropSpec(
      'lighthouse_tower',
      <String>['pe_phare_batiment'],
      widthCells: 12,
      heightCells: 14,
    ),
    _NamedCropSpec('guardian_cabin', <String>['pe_phare_cabane_facade']),
  ],
  'map_phare_interieur': <_NamedCropSpec>[
    _NamedCropSpec('ground_floor_entry', <String>['pe_phare_escalier_bas']),
    _NamedCropSpec('guardian_note', <String>[
      'pe_phare_note_ancien_gardien',
    ]),
    _NamedCropSpec('lighthouse_mechanism', <String>[
      'pe_phare_mecanisme',
    ]),
    _NamedCropSpec('summit_access', <String>['pe_phare_escalier_haut']),
  ],
  'map_sommet_phare': <_NamedCropSpec>[
    _NamedCropSpec(
      'lantern_and_platform',
      <String>[
        'pe_sommet_lanterne',
        'pe_sommet_plateforme',
      ],
      heightCells: 14,
    ),
    _NamedCropSpec('summit_mechanism', <String>['pe_sommet_mecanisme']),
    _NamedCropSpec('interior_hatch', <String>['pe_sommet_trappe']),
  ],
  'map_cabane_gardien': <_NamedCropSpec>[
    _NamedCropSpec('guardian_journal', <String>['pe_cabane_journal']),
    _NamedCropSpec('guardian_key', <String>['pe_cabane_cle']),
    _NamedCropSpec('secondary_door', <String>[
      'pe_cabane_porte_secondaire',
    ]),
  ],
  'map_maison_joueur': <_NamedCropSpec>[
    _NamedCropSpec('player_bed', <String>['pe_maison_lit']),
    _NamedCropSpec('player_desk', <String>['pe_maison_bureau']),
    _NamedCropSpec('house_exit', <String>['pe_maison_porte']),
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('captures the selected canonical Selbrume beta maps', () async {
    final config = _CaptureHarnessConfig.fromEnvironment();
    await config.outputDirectory.create(recursive: true);

    expect(_namedCropsByMapId.keys.toSet(), _canonicalMapIds.toSet());

    final mapCaptures = <_MapCaptureResult>[];
    for (final mapId in config.mapIds) {
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: config.projectFile.path,
        mapId: mapId,
      );
      final tileImages = await _loadTilesetsForCapture(bundle);
      final scene = _MapCaptureScene(
        bundle: bundle,
        tileImagesByTilesetId: tileImages,
      );
      final result = await _captureMap(
        scene: scene,
        outputDirectory: config.outputDirectory,
        namedCrops: _namedCropsByMapId[mapId]!,
        logicalTilePx: config.logicalTilePx,
      );
      mapCaptures.add(result);
      debugPrint(
        'Selbrume capture: $mapId -> ${result.artifacts.length} PNG files',
      );
    }

    final manifest = <String, Object?>{
      'schemaVersion': 1,
      'projectFile': p.basename(config.projectFile.path),
      'mapCount': mapCaptures.length,
      'artifactCount': mapCaptures.fold<int>(
        0,
        (count, map) => count + map.artifacts.length,
      ),
      'maps': <Object?>[
        for (final capture in mapCaptures) capture.toJson(),
      ],
    };
    final manifestFile = File(
      p.join(config.outputDirectory.path, _manifestFileName),
    );
    final manifestText =
        '${const JsonEncoder.withIndent('  ').convert(manifest)}\n';
    await manifestFile.writeAsString(manifestText);

    expect(mapCaptures, hasLength(config.mapIds.length));
    expect(
      mapCaptures.map((capture) => capture.mapId).toList(),
      config.mapIds,
    );
    expect(
      mapCaptures.expand((capture) => capture.artifacts).where(
            (artifact) => artifact.kind == _CaptureKind.overview,
          ),
      hasLength(config.mapIds.length),
    );
    expect(
      mapCaptures.expand((capture) => capture.artifacts).where(
            (artifact) => artifact.kind == _CaptureKind.collisionOverlay,
          ),
      hasLength(config.mapIds.length),
    );
    expect(
      mapCaptures.expand((capture) => capture.artifacts).where(
            (artifact) => artifact.kind == _CaptureKind.namedCrop,
          ),
      hasLength(
        config.mapIds.expand((mapId) => _namedCropsByMapId[mapId]!).length,
      ),
    );
    for (final artifact in mapCaptures.expand((capture) => capture.artifacts)) {
      final file = File(p.join(config.outputDirectory.path, artifact.filename));
      expect(file.existsSync(), isTrue, reason: artifact.filename);
      expect(await file.length(), artifact.byteSize, reason: artifact.filename);
      expect(artifact.byteSize, greaterThan(0), reason: artifact.filename);
      expect(
        artifact.sha256,
        matches(RegExp(r'^[0-9a-f]{64}$')),
        reason: artifact.filename,
      );
      expect(
        await _sha256ForFile(file),
        artifact.sha256,
        reason: artifact.filename,
      );
    }
    expect(manifestFile.existsSync(), isTrue);
    expect(
      (jsonDecode(await manifestFile.readAsString())
          as Map<String, dynamic>)['mapCount'],
      config.mapIds.length,
    );
    expect(
      manifestText.contains(config.projectFile.absolute.path),
      isFalse,
      reason:
          'The portable manifest must not persist an absolute project path.',
    );
    expect(
      manifestText.contains(config.outputDirectory.absolute.path),
      isFalse,
      reason: 'The portable manifest must not persist an absolute output path.',
    );

    debugPrint(
      'Selbrume capture manifest: ${manifestFile.path} '
      '(${manifest['artifactCount']} PNG files)',
    );
  });
}

Future<_MapCaptureResult> _captureMap({
  required _MapCaptureScene scene,
  required Directory outputDirectory,
  required List<_NamedCropSpec> namedCrops,
  required int? logicalTilePx,
}) async {
  final bundle = scene.bundle;
  final worldWidth = bundle.map.size.width * bundle.cellWidth;
  final worldHeight = bundle.map.size.height * bundle.cellHeight;
  if (worldWidth <= 0 || worldHeight <= 0) {
    throw StateError('${bundle.map.id} has non-positive runtime dimensions.');
  }

  final overviewGeometry = _CaptureGeometry.fitWholeMap(
    worldWidth: worldWidth,
    worldHeight: worldHeight,
    forcedScale: logicalTilePx == null
        ? null
        : math.min(
            logicalTilePx / bundle.cellWidth,
            logicalTilePx / bundle.cellHeight,
          ),
  );
  final overview = await _renderArtifact(
    scene: scene,
    outputDirectory: outputDirectory,
    filename: '${bundle.map.id}__overview.png',
    kind: _CaptureKind.overview,
    geometry: overviewGeometry,
  );
  final collisionOverlay = await _renderArtifact(
    scene: scene,
    outputDirectory: outputDirectory,
    filename: '${bundle.map.id}__collision.png',
    kind: _CaptureKind.collisionOverlay,
    geometry: overviewGeometry,
    showCollisionOverlay: true,
  );

  final crops = <_CaptureArtifact>[];
  for (final crop in namedCrops) {
    final geometry = _resolveNamedCropGeometry(scene.bundle, crop);
    crops.add(
      await _renderArtifact(
        scene: scene,
        outputDirectory: outputDirectory,
        filename: '${bundle.map.id}__crop__${_safeFilePart(crop.name)}.png',
        kind: _CaptureKind.namedCrop,
        name: crop.name,
        focusPlacedElementIds: crop.placedElementIds,
        geometry: geometry,
      ),
    );
  }

  return _MapCaptureResult(
    mapId: bundle.map.id,
    mapName: bundle.map.name,
    widthCells: bundle.map.size.width,
    heightCells: bundle.map.size.height,
    cellWidthPx: bundle.cellWidth,
    cellHeightPx: bundle.cellHeight,
    worldWidthPx: worldWidth,
    worldHeightPx: worldHeight,
    artifacts: <_CaptureArtifact>[
      overview,
      collisionOverlay,
      ...crops,
    ],
  );
}

Future<_CaptureArtifact> _renderArtifact({
  required _MapCaptureScene scene,
  required Directory outputDirectory,
  required String filename,
  required _CaptureKind kind,
  required _CaptureGeometry geometry,
  String? name,
  List<String> focusPlacedElementIds = const <String>[],
  bool showCollisionOverlay = false,
}) async {
  final file = File(p.join(outputDirectory.path, filename));
  await _renderScene(
    scene,
    file: file,
    geometry: geometry,
    showCollisionOverlay: showCollisionOverlay,
  );
  return _CaptureArtifact(
    mapId: scene.bundle.map.id,
    kind: kind,
    name: name,
    focusPlacedElementIds: focusPlacedElementIds,
    filename: filename,
    widthPx: geometry.outputWidth,
    heightPx: geometry.outputHeight,
    byteSize: await file.length(),
    sha256: await _sha256ForFile(file),
  );
}

Future<void> _renderScene(
  _MapCaptureScene scene, {
  required File file,
  required _CaptureGeometry geometry,
  required bool showCollisionOverlay,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(
      0,
      0,
      geometry.outputWidth.toDouble(),
      geometry.outputHeight.toDouble(),
    ),
    ui.Paint()..color = const ui.Color(0xFF000000),
  );
  canvas.save();
  canvas.scale(geometry.scale, geometry.scale);
  canvas.translate(-geometry.worldLeft, -geometry.worldTop);
  scene.background.showCollisionOverlay = showCollisionOverlay;
  scene.background.render(canvas);
  scene.foreground.render(canvas);
  scene.background.showCollisionOverlay = false;
  canvas.restore();

  final picture = recorder.endRecording();
  final image = await picture.toImage(
    geometry.outputWidth,
    geometry.outputHeight,
  );
  picture.dispose();
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (byteData == null) {
    throw StateError('Could not encode ${file.path} as PNG.');
  }
  await file.writeAsBytes(
    byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    ),
  );
}

_CaptureGeometry _resolveNamedCropGeometry(
  RuntimeMapBundle bundle,
  _NamedCropSpec spec,
) {
  if (spec.placedElementIds.isEmpty) {
    throw StateError('${bundle.map.id} has an empty named crop ${spec.name}.');
  }
  final placedById = <String, MapPlacedElement>{
    for (final placed in bundle.map.placedElements) placed.id: placed,
  };
  final elementById = <String, ProjectElementEntry>{
    for (final element in bundle.manifest.elements) element.id: element,
  };
  var centerXCells = 0.0;
  var centerYCells = 0.0;
  for (final placedId in spec.placedElementIds) {
    final placed = placedById[placedId];
    if (placed == null) {
      throw StateError(
        '${bundle.map.id} is missing named-crop landmark $placedId.',
      );
    }
    final element = elementById[placed.elementId];
    final source = element == null || element.frames.isEmpty
        ? null
        : element.frames.first.source;
    final widthCells = source == null || source.width <= 0 ? 1 : source.width;
    final heightCells =
        source == null || source.height <= 0 ? 1 : source.height;
    centerXCells += placed.pos.x + (widthCells / 2);
    centerYCells += placed.pos.y + (heightCells / 2);
  }
  centerXCells /= spec.placedElementIds.length;
  centerYCells /= spec.placedElementIds.length;

  final worldWidth = bundle.map.size.width * bundle.cellWidth;
  final worldHeight = bundle.map.size.height * bundle.cellHeight;
  final cropWidth = math.min(
    worldWidth,
    spec.widthCells * bundle.cellWidth,
  );
  final cropHeight = math.min(
    worldHeight,
    spec.heightCells * bundle.cellHeight,
  );
  final requestedLeft = (centerXCells * bundle.cellWidth) - (cropWidth / 2);
  final requestedTop = (centerYCells * bundle.cellHeight) - (cropHeight / 2);
  final maxLeft = math.max(0.0, worldWidth - cropWidth);
  final maxTop = math.max(0.0, worldHeight - cropHeight);
  return _CaptureGeometry(
    worldLeft: requestedLeft.clamp(0.0, maxLeft).toDouble(),
    worldTop: requestedTop.clamp(0.0, maxTop).toDouble(),
    outputWidth: cropWidth.round(),
    outputHeight: cropHeight.round(),
    scale: 1,
  );
}

Future<Map<String, RuntimeTilesetImage>> _loadTilesetsForCapture(
  RuntimeMapBundle bundle,
) async {
  return loadTilesetImagesById(
    bundle.tilesetAbsolutePathsById,
    transparentColorByTilesetId: <String, TilesetTransparentColor>{
      for (final tileset in bundle.manifest.tilesets)
        if (tileset.transparentColor != null)
          tileset.id: tileset.transparentColor!,
    },
  );
}

String _safeFilePart(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_-]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

Future<String> _sha256ForFile(File file) async {
  return _sha256(await file.readAsBytes());
}

/// Small self-contained SHA-256 implementation keeps the capture tool
/// portable without adding a package dependency or shelling out to `shasum`.
String _sha256(List<int> input) {
  const mask = 0xffffffff;
  const initial = <int>[
    0x6a09e667,
    0xbb67ae85,
    0x3c6ef372,
    0xa54ff53a,
    0x510e527f,
    0x9b05688c,
    0x1f83d9ab,
    0x5be0cd19,
  ];
  const roundConstants = <int>[
    0x428a2f98,
    0x71374491,
    0xb5c0fbcf,
    0xe9b5dba5,
    0x3956c25b,
    0x59f111f1,
    0x923f82a4,
    0xab1c5ed5,
    0xd807aa98,
    0x12835b01,
    0x243185be,
    0x550c7dc3,
    0x72be5d74,
    0x80deb1fe,
    0x9bdc06a7,
    0xc19bf174,
    0xe49b69c1,
    0xefbe4786,
    0x0fc19dc6,
    0x240ca1cc,
    0x2de92c6f,
    0x4a7484aa,
    0x5cb0a9dc,
    0x76f988da,
    0x983e5152,
    0xa831c66d,
    0xb00327c8,
    0xbf597fc7,
    0xc6e00bf3,
    0xd5a79147,
    0x06ca6351,
    0x14292967,
    0x27b70a85,
    0x2e1b2138,
    0x4d2c6dfc,
    0x53380d13,
    0x650a7354,
    0x766a0abb,
    0x81c2c92e,
    0x92722c85,
    0xa2bfe8a1,
    0xa81a664b,
    0xc24b8b70,
    0xc76c51a3,
    0xd192e819,
    0xd6990624,
    0xf40e3585,
    0x106aa070,
    0x19a4c116,
    0x1e376c08,
    0x2748774c,
    0x34b0bcb5,
    0x391c0cb3,
    0x4ed8aa4a,
    0x5b9cca4f,
    0x682e6ff3,
    0x748f82ee,
    0x78a5636f,
    0x84c87814,
    0x8cc70208,
    0x90befffa,
    0xa4506ceb,
    0xbef9a3f7,
    0xc67178f2,
  ];

  final bytes = <int>[...input, 0x80];
  while (bytes.length % 64 != 56) {
    bytes.add(0);
  }
  final bitLength = input.length * 8;
  for (var shift = 56; shift >= 0; shift -= 8) {
    bytes.add((bitLength >> shift) & 0xff);
  }

  final hash = List<int>.of(initial);
  final words = List<int>.filled(64, 0);
  for (var offset = 0; offset < bytes.length; offset += 64) {
    for (var index = 0; index < 16; index++) {
      final start = offset + (index * 4);
      words[index] = (bytes[start] << 24) |
          (bytes[start + 1] << 16) |
          (bytes[start + 2] << 8) |
          bytes[start + 3];
    }
    for (var index = 16; index < 64; index++) {
      final s0 = _rotateRight(words[index - 15], 7) ^
          _rotateRight(words[index - 15], 18) ^
          (words[index - 15] >> 3);
      final s1 = _rotateRight(words[index - 2], 17) ^
          _rotateRight(words[index - 2], 19) ^
          (words[index - 2] >> 10);
      words[index] = (words[index - 16] + s0 + words[index - 7] + s1) & mask;
    }

    var a = hash[0];
    var b = hash[1];
    var c = hash[2];
    var d = hash[3];
    var e = hash[4];
    var f = hash[5];
    var g = hash[6];
    var h = hash[7];
    for (var index = 0; index < 64; index++) {
      final sum1 =
          _rotateRight(e, 6) ^ _rotateRight(e, 11) ^ _rotateRight(e, 25);
      final choose = (e & f) ^ ((~e & mask) & g);
      final temp1 =
          (h + sum1 + choose + roundConstants[index] + words[index]) & mask;
      final sum0 =
          _rotateRight(a, 2) ^ _rotateRight(a, 13) ^ _rotateRight(a, 22);
      final majority = (a & b) ^ (a & c) ^ (b & c);
      final temp2 = (sum0 + majority) & mask;
      h = g;
      g = f;
      f = e;
      e = (d + temp1) & mask;
      d = c;
      c = b;
      b = a;
      a = (temp1 + temp2) & mask;
    }
    hash[0] = (hash[0] + a) & mask;
    hash[1] = (hash[1] + b) & mask;
    hash[2] = (hash[2] + c) & mask;
    hash[3] = (hash[3] + d) & mask;
    hash[4] = (hash[4] + e) & mask;
    hash[5] = (hash[5] + f) & mask;
    hash[6] = (hash[6] + g) & mask;
    hash[7] = (hash[7] + h) & mask;
  }
  return hash.map((value) => value.toRadixString(16).padLeft(8, '0')).join();
}

int _rotateRight(int value, int count) {
  return ((value >> count) | (value << (32 - count))) & 0xffffffff;
}

final class _CaptureHarnessConfig {
  const _CaptureHarnessConfig({
    required this.projectFile,
    required this.outputDirectory,
    required this.mapIds,
    required this.logicalTilePx,
  });

  factory _CaptureHarnessConfig.fromEnvironment() {
    final projectOverride =
        Platform.environment['SELBRUME_PROJECT_PATH']?.trim();
    final projectCandidate = projectOverride == null || projectOverride.isEmpty
        ? File(p.join(_findRepositoryRoot().path, 'selbrume', 'project.json'))
        : File(p.normalize(p.absolute(projectOverride)));
    final projectFile = FileSystemEntity.isDirectorySync(projectCandidate.path)
        ? File(p.join(projectCandidate.path, 'project.json'))
        : projectCandidate;
    if (!projectFile.existsSync()) {
      throw StateError(
        'SELBRUME_PROJECT_PATH does not resolve to project.json: '
        '${projectFile.path}',
      );
    }

    final outputOverride =
        Platform.environment['SELBRUME_MAP_CAPTURE_OUTPUT_DIR']?.trim();
    if (outputOverride == null || outputOverride.isEmpty) {
      throw StateError(
        'SELBRUME_MAP_CAPTURE_OUTPUT_DIR is required so captures are never '
        'written into the repository accidentally.',
      );
    }
    final mapIdsOverride =
        Platform.environment['SELBRUME_MAP_CAPTURE_MAP_IDS']?.trim();
    final mapIds = mapIdsOverride == null || mapIdsOverride.isEmpty
        ? _canonicalMapIds
        : mapIdsOverride
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false);
    if (mapIds.isEmpty ||
        mapIds.toSet().length != mapIds.length ||
        mapIds.any((id) => !_canonicalMapIds.contains(id))) {
      throw StateError(
        'SELBRUME_MAP_CAPTURE_MAP_IDS must contain unique canonical map ids.',
      );
    }
    final logicalTileRaw =
        Platform.environment['SELBRUME_MAP_CAPTURE_LOGICAL_TILE_PX']?.trim();
    final logicalTilePx = logicalTileRaw == null || logicalTileRaw.isEmpty
        ? null
        : int.tryParse(logicalTileRaw);
    if (logicalTileRaw != null &&
        logicalTileRaw.isNotEmpty &&
        (logicalTilePx == null || logicalTilePx <= 0)) {
      throw StateError(
        'SELBRUME_MAP_CAPTURE_LOGICAL_TILE_PX must be a positive integer.',
      );
    }
    return _CaptureHarnessConfig(
      projectFile: projectFile.absolute,
      outputDirectory: Directory(
        p.normalize(p.absolute(outputOverride)),
      ),
      mapIds: List<String>.unmodifiable(mapIds),
      logicalTilePx: logicalTilePx,
    );
  }

  final File projectFile;
  final Directory outputDirectory;
  final List<String> mapIds;
  final int? logicalTilePx;
}

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    final isRoot = File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        File(p.join(current.path, 'selbrume', 'project.json')).existsSync() &&
        File(
          p.join(current.path, 'packages', 'map_runtime', 'pubspec.yaml'),
        ).existsSync();
    if (isRoot) {
      return current;
    }
    final parent = current.parent.absolute;
    if (parent.path == current.path) {
      throw StateError(
        'Could not discover the PokeMap repository root from '
        '${Directory.current.path}. Set SELBRUME_PROJECT_PATH explicitly.',
      );
    }
    current = parent;
  }
}

final class _MapCaptureScene {
  _MapCaptureScene({
    required this.bundle,
    required Map<String, RuntimeTilesetImage> tileImagesByTilesetId,
  })  : background = MapLayersComponent(
          bundle: bundle,
          tileImagesByTilesetId: tileImagesByTilesetId,
          shadowCollectionProvider: () =>
              buildRuntimeStaticPlacedElementShadowCollectionForBundle(
            bundle: bundle,
          ),
        ),
        foreground = MapLayersComponent(
          bundle: bundle,
          tileImagesByTilesetId: tileImagesByTilesetId,
          renderPass: MapLayerRenderPass.foreground,
        ) {
    background.update(0);
    foreground.update(0);
  }

  final RuntimeMapBundle bundle;
  final MapLayersComponent background;
  final MapLayersComponent foreground;
}

enum _CaptureKind {
  overview('overview'),
  collisionOverlay('collision_overlay'),
  namedCrop('named_crop');

  const _CaptureKind(this.jsonName);

  final String jsonName;
}

final class _NamedCropSpec {
  const _NamedCropSpec(
    this.name,
    this.placedElementIds, {
    this.widthCells = 10,
    this.heightCells = 7,
  });

  final String name;
  final List<String> placedElementIds;
  final int widthCells;
  final int heightCells;
}

final class _CaptureGeometry {
  const _CaptureGeometry({
    required this.worldLeft,
    required this.worldTop,
    required this.outputWidth,
    required this.outputHeight,
    required this.scale,
  });

  factory _CaptureGeometry.fitWholeMap({
    required double worldWidth,
    required double worldHeight,
    double? forcedScale,
  }) {
    final scale = forcedScale ??
        math.min(
          1.0,
          math.min(
            _overviewMaxWidth / worldWidth,
            _overviewMaxHeight / worldHeight,
          ),
        );
    return _CaptureGeometry(
      worldLeft: 0,
      worldTop: 0,
      outputWidth: math.max(1, (worldWidth * scale).round()),
      outputHeight: math.max(1, (worldHeight * scale).round()),
      scale: scale,
    );
  }

  final double worldLeft;
  final double worldTop;
  final int outputWidth;
  final int outputHeight;
  final double scale;
}

final class _CaptureArtifact {
  const _CaptureArtifact({
    required this.mapId,
    required this.kind,
    required this.name,
    required this.focusPlacedElementIds,
    required this.filename,
    required this.widthPx,
    required this.heightPx,
    required this.byteSize,
    required this.sha256,
  });

  final String mapId;
  final _CaptureKind kind;
  final String? name;
  final List<String> focusPlacedElementIds;
  final String filename;
  final int widthPx;
  final int heightPx;
  final int byteSize;
  final String sha256;

  Map<String, Object?> toJson() => <String, Object?>{
        'mapId': mapId,
        'kind': kind.jsonName,
        if (name != null) 'name': name,
        if (focusPlacedElementIds.isNotEmpty)
          'focusPlacedElementIds': focusPlacedElementIds,
        'dimensions': <String, int>{
          'widthPx': widthPx,
          'heightPx': heightPx,
        },
        'filename': filename,
        'byteSize': byteSize,
        'sha256': sha256,
      };
}

final class _MapCaptureResult {
  const _MapCaptureResult({
    required this.mapId,
    required this.mapName,
    required this.widthCells,
    required this.heightCells,
    required this.cellWidthPx,
    required this.cellHeightPx,
    required this.worldWidthPx,
    required this.worldHeightPx,
    required this.artifacts,
  });

  final String mapId;
  final String mapName;
  final int widthCells;
  final int heightCells;
  final double cellWidthPx;
  final double cellHeightPx;
  final double worldWidthPx;
  final double worldHeightPx;
  final List<_CaptureArtifact> artifacts;

  Map<String, Object?> toJson() => <String, Object?>{
        'mapId': mapId,
        'mapName': mapName,
        'dimensions': <String, num>{
          'widthCells': widthCells,
          'heightCells': heightCells,
          'cellWidthPx': cellWidthPx,
          'cellHeightPx': cellHeightPx,
          'worldWidthPx': worldWidthPx,
          'worldHeightPx': worldHeightPx,
        },
        'artifacts': <Object?>[
          for (final artifact in artifacts) artifact.toJson(),
        ],
      };
}
