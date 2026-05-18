import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/shadow/runtime_static_placed_element_shadow_collection.dart';
import 'package:map_runtime/src/shadow/runtime_static_placed_element_shadow_sources.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
import 'package:path/path.dart' as p;

const _defaultProjectPath = '/Users/karim/Desktop/selbrume/project.json';
const _defaultRepoRoot = '/Users/karim/Project/pokemonProject';
const _defaultOutputDir =
    '/Users/karim/Project/pokemonProject/reports/shadows/screenshots';
const _defaultPrefix = 'shadow65';
const _mapId = 'Selbrume';
const _overviewScale = 0.25;
const _contactCropWidth = 900;
const _contactCropHeight = 650;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('selbrume shadow screenshot harness', () async {
    final config = _HarnessConfig.fromEnvironment();
    await Directory(config.outputDir).create(recursive: true);
    await Directory(config.artifactDir).create(recursive: true);

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: config.projectPath,
      mapId: _mapId,
    );
    final tileImages = await loadTilesetImagesById(
      bundle.tilesetAbsolutePathsById,
      transparentColorByTilesetId: {
        for (final tileset in bundle.manifest.tilesets)
          if (tileset.transparentColor != null)
            tileset.id: tileset.transparentColor!,
      },
    );
    final shadowRows = _buildShadowRows(bundle: bundle);
    final counts = _buildCounts(shadowRows);

    final layer = MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: tileImages,
      shadowCollectionProvider: () =>
          buildRuntimeStaticPlacedElementShadowCollectionForBundle(
        bundle: bundle,
      ),
    );
    layer.update(0);

    final worldWidth = bundle.map.size.width * bundle.cellWidth;
    final worldHeight = bundle.map.size.height * bundle.cellHeight;
    final overviewPath =
        p.join(config.outputDir, '${config.prefix}_selbrume_overview.png');
    await _renderCapture(
      layer,
      filePath: overviewPath,
      cropLeft: 0,
      cropTop: 0,
      outputWidth: (worldWidth * _overviewScale).round(),
      outputHeight: (worldHeight * _overviewScale).round(),
      scale: _overviewScale,
    );

    final captures = <_CaptureArtifact>[];
    for (final row
        in shadowRows.where((row) => row.geometryType == 'contactLedge')) {
      final cropLeft =
          (row.instructionLeft - 260).clamp(0, worldWidth - _contactCropWidth);
      final cropTop =
          (row.instructionTop - 430).clamp(0, worldHeight - _contactCropHeight);
      final screenshotPath = p.join(
        config.outputDir,
        '${config.prefix}_contact_ledge_${row.rank}_${_safeFilePart(row.elementId)}.png',
      );
      await _renderCapture(
        layer,
        filePath: screenshotPath,
        cropLeft: cropLeft.toDouble(),
        cropTop: cropTop.toDouble(),
        outputWidth: _contactCropWidth,
        outputHeight: _contactCropHeight,
      );
      captures.add(
        _CaptureArtifact(
          row: row,
          cropLeft: cropLeft.toDouble(),
          cropTop: cropTop.toDouble(),
          cropWidth: _contactCropWidth,
          cropHeight: _contactCropHeight,
          screenshotPath: screenshotPath,
          fileSizeBytes: await File(screenshotPath).length(),
          sha256: await _sha256ForFile(screenshotPath),
        ),
      );
      debugPrint(
        'capture rank=${row.rank} element=${row.elementId} '
        'cropLeft=${cropLeft.toStringAsFixed(1)} '
        'cropTop=${cropTop.toStringAsFixed(1)}',
      );
    }

    final overviewArtifact = _CurrentImageArtifact(
      kind: 'overview',
      rank: null,
      elementId: null,
      path: overviewPath,
      sha256: await _sha256ForFile(overviewPath),
      fileSizeBytes: await File(overviewPath).length(),
      width: (worldWidth * _overviewScale).round(),
      height: (worldHeight * _overviewScale).round(),
    );
    final currentArtifacts = <_CurrentImageArtifact>[
      overviewArtifact,
      for (final capture in captures)
        _CurrentImageArtifact(
          kind: 'contactLedge',
          rank: capture.row.rank,
          elementId: capture.row.elementId,
          path: capture.screenshotPath,
          sha256: capture.sha256,
          fileSizeBytes: capture.fileSizeBytes,
          width: capture.cropWidth,
          height: capture.cropHeight,
        ),
    ];
    final baselineComparison = config.compareBaseline
        ? await _compareAgainstBaseline(
            config: config,
            currentArtifacts: currentArtifacts,
            counts: counts,
          )
        : null;
    final indexPath =
        p.join(config.artifactDir, '${config.artifactStem}_capture_index.tsv');
    final manifestPath = p.join(
      config.artifactDir,
      '${config.artifactStem}_capture_manifest.json',
    );
    await File(indexPath).writeAsString(_captureIndexTsv(captures));
    await File(manifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'lot': config.lotLabel,
        'projectPath': config.projectPath,
        'mapId': _mapId,
        'prefix': config.prefix,
        'outputDir': config.outputDir,
        'overview': overviewArtifact.toJson(),
        'indexTsv': indexPath,
        'counts': counts.toJson(),
        if (baselineComparison != null)
          'baselineComparison': baselineComparison.summaryJson(),
        'captures': [
          for (final capture in captures) capture.toJson(),
        ],
      }),
    );

    final summary = {
      'projectPath': config.projectPath,
      'outputDir': config.outputDir,
      'prefix': config.prefix,
      'overview': overviewArtifact.toJson(),
      'indexTsv': indexPath,
      'manifest': manifestPath,
      'counts': counts.toJson(),
      if (baselineComparison != null)
        'baselineComparison': baselineComparison.summaryJson(),
    };
    debugPrint(const JsonEncoder.withIndent('  ').convert(summary));

    expect(counts.staticInstructions, 10);
    expect(counts.contactLedge, 10);
    expect(counts.genericProjection, 0);
    expect(captures, hasLength(10));
    expect(currentArtifacts, hasLength(11));
    expect(File(overviewPath).existsSync(), isTrue);
    expect(File(indexPath).existsSync(), isTrue);
    expect(File(manifestPath).existsSync(), isTrue);
    if (config.compareBaseline) {
      expect(File(config.compareOutputJson).existsSync(), isTrue);
      expect(File(config.compareOutputTsv).existsSync(), isTrue);
      expect(baselineComparison?.hasBlockingFailure, isFalse);
    }
  });
}

List<_ShadowCaptureRow> _buildShadowRows({required RuntimeMapBundle bundle}) {
  final elementsById = <String, ProjectElementEntry>{
    for (final element in bundle.manifest.elements) element.id: element,
  };
  final sources = buildRuntimeStaticPlacedElementShadowSources(bundle: bundle);
  final rows = <_ShadowCaptureRow>[];
  var rank = 0;
  for (final source in sources) {
    final collection = buildRuntimeStaticPlacedElementShadowCollection(
      catalog: bundle.manifest.shadowCatalog,
      sources: [source],
    );
    for (final instruction in collection.instructions) {
      rank += 1;
      final element = elementsById[source.elementId];
      final shadow = element?.shadow;
      final family = shadow?.family;
      final geometryType =
          instruction.shape == ShadowRuntimeShapeKind.projectedPolygon &&
                  family == StaticShadowFamily.building
              ? 'contactLedge'
              : instruction.shape.name;
      rows.add(
        _ShadowCaptureRow(
          rank: rank,
          placementIdOrIndex: source.id,
          elementId: source.elementId,
          elementName: element?.name ?? source.elementId,
          worldX: source.metrics.worldLeft,
          worldY: source.metrics.worldTop,
          instructionLeft: instruction.worldLeft,
          instructionTop: instruction.worldTop,
          instructionWidth: instruction.width,
          instructionHeight: instruction.height,
          instructionArea: instruction.width * instruction.height,
          opacity: instruction.opacity,
          shapeKind: instruction.shape.name,
          geometryType: geometryType,
          renderPass: instruction.renderPass.name,
          family: family?.name ?? 'null',
          profile: shadow?.shadowProfileId ?? 'null',
        ),
      );
    }
  }
  return rows;
}

_RuntimeCounts _buildCounts(List<_ShadowCaptureRow> rows) {
  final byElement = <String, int>{};
  final byFamily = <String, int>{};
  final byProfile = <String, int>{};
  var contactLedge = 0;
  var genericProjection = 0;
  for (final row in rows) {
    byElement[row.elementId] = (byElement[row.elementId] ?? 0) + 1;
    byFamily[row.family] = (byFamily[row.family] ?? 0) + 1;
    byProfile[row.profile] = (byProfile[row.profile] ?? 0) + 1;
    if (row.geometryType == 'contactLedge') {
      contactLedge += 1;
    }
    if (row.family == 'genericProjection') {
      genericProjection += 1;
    }
  }
  return _RuntimeCounts(
    staticInstructions: rows.length,
    contactLedge: contactLedge,
    genericProjection: genericProjection,
    byElement: byElement,
    byFamily: byFamily,
    byProfile: byProfile,
  );
}

Future<void> _renderCapture(
  MapLayersComponent layer, {
  required String filePath,
  required double cropLeft,
  required double cropTop,
  required int outputWidth,
  required int outputHeight,
  double scale = 1,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF000000),
  );
  canvas.save();
  canvas.scale(scale, scale);
  canvas.translate(-cropLeft, -cropTop);
  layer.render(canvas);
  canvas.restore();
  final image =
      await recorder.endRecording().toImage(outputWidth, outputHeight);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) {
    throw StateError('Could not encode PNG for $filePath');
  }
  await File(filePath).writeAsBytes(Uint8List.view(data.buffer));
}

String _captureIndexTsv(List<_CaptureArtifact> captures) {
  const headers = [
    'rank',
    'elementId',
    'elementName',
    'placementIdOrIndex',
    'worldX',
    'worldY',
    'cropLeft',
    'cropTop',
    'cropWidth',
    'cropHeight',
    'screenshotPath',
    'shapeKind',
    'geometryType',
    'family',
    'profile',
    'opacity',
    'instructionWidth',
    'instructionHeight',
    'instructionArea',
  ];
  final lines = <String>[headers.join('\t')];
  for (final capture in captures) {
    lines.add([
      capture.row.rank,
      capture.row.elementId,
      capture.row.elementName,
      capture.row.placementIdOrIndex,
      capture.row.worldX,
      capture.row.worldY,
      capture.cropLeft,
      capture.cropTop,
      capture.cropWidth,
      capture.cropHeight,
      capture.screenshotPath,
      capture.row.shapeKind,
      capture.row.geometryType,
      capture.row.family,
      capture.row.profile,
      capture.row.opacity,
      capture.row.instructionWidth,
      capture.row.instructionHeight,
      capture.row.instructionArea,
    ].map((value) => '$value').join('\t'));
  }
  return '${lines.join('\n')}\n';
}

Future<String> _sha256ForFile(String filePath) async {
  final result = await Process.run('shasum', ['-a', '256', filePath]);
  if (result.exitCode != 0) {
    throw StateError('Could not calculate sha256 for $filePath: '
        '${result.stderr}');
  }
  final output = (result.stdout as String).trim();
  return output.split(RegExp(r'\s+')).first;
}

Future<_BaselineComparisonResult> _compareAgainstBaseline({
  required _HarnessConfig config,
  required List<_CurrentImageArtifact> currentArtifacts,
  required _RuntimeCounts counts,
}) async {
  final baselineDir = config.baselineDir;
  if (baselineDir == null) {
    throw StateError(
      'SHADOW_BASELINE_DIR is required when SHADOW_COMPARE_BASELINE=true',
    );
  }
  final manifestFile = File(p.join(baselineDir, 'baseline_manifest.json'));
  if (!manifestFile.existsSync()) {
    throw StateError('Baseline manifest is missing: ${manifestFile.path}');
  }

  final manifest =
      jsonDecode(await manifestFile.readAsString()) as Map<String, Object?>;
  final expectedCounts = manifest['counts'] as Map<String, Object?>;
  final baselineCaptures =
      (manifest['captures'] as List<Object?>).cast<Map<String, Object?>>();
  final expected = manifest['expected'] as Map<String, Object?>?;
  final expectedElementIds =
      (expected?['contactElementIds'] as List<Object?>?)?.cast<String>();
  final currentElementIds = [
    for (final artifact in currentArtifacts)
      if (artifact.kind == 'contactLedge') artifact.elementId,
  ];

  final structureFailures = <String>[];
  void expectStructure(bool condition, String message) {
    if (!condition) {
      structureFailures.add(message);
    }
  }

  expectStructure(
      counts.staticInstructions == expectedCounts['staticInstructions'],
      'staticInstructions mismatch');
  expectStructure(counts.contactLedge == expectedCounts['contactLedge'],
      'contactLedge mismatch');
  expectStructure(
      counts.genericProjection == expectedCounts['genericProjection'],
      'genericProjection mismatch');
  expectStructure(currentArtifacts.length == expectedCounts['captures'],
      'capture count mismatch');
  if (expectedElementIds != null) {
    expectStructure(
      _listEquals(currentElementIds, expectedElementIds),
      'contact element ids mismatch',
    );
  }

  final currentByKey = {
    for (final artifact in currentArtifacts) artifact.key: artifact,
  };
  final rows = <_BaselineComparisonRow>[];
  if (structureFailures.isNotEmpty) {
    rows.add(
      _BaselineComparisonRow.structureFailure(
        structureFailures.join('; '),
      ),
    );
  }

  for (final baseline in baselineCaptures) {
    final kind = baseline['kind'] as String;
    final rank = baseline['rank'] as int?;
    final elementId = baseline['elementId'] as String?;
    final baselinePath = _resolveRepoPath(baseline['baselinePath'] as String);
    final current = currentByKey[_artifactKey(kind, rank)];
    final baselineFile = File(baselinePath);
    final baselineExists = baselineFile.existsSync();
    final currentExists = current != null && File(current.path).existsSync();
    final baselineWidth = baseline['width'] as int;
    final baselineHeight = baseline['height'] as int;
    final currentWidth = current?.width;
    final currentHeight = current?.height;
    final baselineSha256 = baseline['sha256'] as String;
    final baselineFileSizeBytes = baseline['fileSizeBytes'] as int;

    var status = 'match';
    if (!baselineExists) {
      status = 'missing-baseline-fail';
    } else if (!currentExists) {
      status = 'missing-current-fail';
    } else if (baselineWidth != currentWidth ||
        baselineHeight != currentHeight) {
      status = 'dimension-mismatch-fail';
    } else if (baselineSha256 != current.sha256) {
      status = 'pixel-diff-informative';
    }

    rows.add(
      _BaselineComparisonRow(
        rank: rank,
        kind: kind,
        elementId: elementId,
        baselinePath: baselinePath,
        currentPath: current?.path,
        baselineSha256: baselineSha256,
        currentSha256: current?.sha256,
        exactHashMatch: baselineSha256 == current?.sha256,
        baselineFileSizeBytes: baselineFileSizeBytes,
        currentFileSizeBytes: current?.fileSizeBytes,
        baselineWidth: baselineWidth,
        baselineHeight: baselineHeight,
        currentWidth: currentWidth,
        currentHeight: currentHeight,
        status: status,
      ),
    );
  }

  final result = _BaselineComparisonResult(
    baselineId: manifest['baselineId'] as String? ?? 'unknown',
    baselineDir: baselineDir,
    counts: counts,
    rows: rows,
  );
  await Directory(p.dirname(config.compareOutputJson)).create(recursive: true);
  await Directory(p.dirname(config.compareOutputTsv)).create(recursive: true);
  await File(config.compareOutputJson).writeAsString(
    const JsonEncoder.withIndent('  ').convert(result.toJson()),
  );
  await File(config.compareOutputTsv).writeAsString(result.toTsv());
  debugPrint(
    'baseline comparison wrote ${config.compareOutputJson} and '
    '${config.compareOutputTsv}',
  );
  if (result.hasBlockingFailure) {
    throw StateError('Blocking baseline comparison failure');
  }
  return result;
}

String _artifactKey(String kind, int? rank) => '$kind:${rank ?? 0}';

bool _listEquals(List<Object?> left, List<Object?> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i += 1) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}

String _resolveRepoPath(String value) {
  if (p.isAbsolute(value)) {
    return value;
  }
  return p.normalize(p.join(_defaultRepoRoot, value));
}

String _safeFilePart(String value) {
  return value.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
}

final class _HarnessConfig {
  const _HarnessConfig({
    required this.projectPath,
    required this.outputDir,
    required this.prefix,
    required this.artifactDir,
    required this.artifactStem,
    required this.lotLabel,
    required this.compareBaseline,
    required this.baselineDir,
    required this.compareOutputJson,
    required this.compareOutputTsv,
  });

  factory _HarnessConfig.fromEnvironment() {
    final projectPath =
        Platform.environment['SELBRUME_PROJECT_PATH'] ?? _defaultProjectPath;
    final outputDir = Directory(
      Platform.environment['SHADOW_SCREENSHOT_OUTPUT_DIR'] ?? _defaultOutputDir,
    ).absolute.path;
    final prefix = _safeFilePart(
        Platform.environment['SHADOW_SCREENSHOT_PREFIX'] ?? _defaultPrefix);
    final artifactDir = p.basename(outputDir) == 'screenshots'
        ? Directory(outputDir).parent.path
        : outputDir;
    final artifactStem = _artifactStemForPrefix(prefix);
    final lotLabel = _lotLabelForArtifactStem(artifactStem);
    final compareBaseline = _envFlag('SHADOW_COMPARE_BASELINE');
    final baselineDirValue = Platform.environment['SHADOW_BASELINE_DIR'];
    final baselineDir = baselineDirValue == null || baselineDirValue.isEmpty
        ? null
        : _resolveRepoPath(baselineDirValue);
    final compareOutputJson = _resolveRepoPath(
      Platform.environment['SHADOW_BASELINE_COMPARE_OUTPUT_JSON'] ??
          p.join(artifactDir, '${artifactStem}_baseline_compare.json'),
    );
    final compareOutputTsv = _resolveRepoPath(
      Platform.environment['SHADOW_BASELINE_COMPARE_OUTPUT_TSV'] ??
          p.join(artifactDir, '${artifactStem}_baseline_compare.tsv'),
    );
    return _HarnessConfig(
      projectPath: projectPath,
      outputDir: outputDir,
      prefix: prefix,
      artifactDir: artifactDir,
      artifactStem: artifactStem,
      lotLabel: lotLabel,
      compareBaseline: compareBaseline,
      baselineDir: baselineDir,
      compareOutputJson: compareOutputJson,
      compareOutputTsv: compareOutputTsv,
    );
  }

  final String projectPath;
  final String outputDir;
  final String prefix;
  final String artifactDir;
  final String artifactStem;
  final String lotLabel;
  final bool compareBaseline;
  final String? baselineDir;
  final String compareOutputJson;
  final String compareOutputTsv;
}

String _artifactStemForPrefix(String prefix) {
  final match = RegExp(r'^shadow(\d+)$').firstMatch(prefix);
  if (match != null) {
    return 'shadow_lot_${match.group(1)}';
  }
  return prefix;
}

String _lotLabelForArtifactStem(String artifactStem) {
  final match = RegExp(r'^shadow_lot_(\d+)$').firstMatch(artifactStem);
  if (match != null) {
    return 'Shadow-${match.group(1)}';
  }
  return artifactStem;
}

bool _envFlag(String name) {
  final value = Platform.environment[name]?.toLowerCase();
  return value == '1' || value == 'true' || value == 'yes';
}

final class _ShadowCaptureRow {
  const _ShadowCaptureRow({
    required this.rank,
    required this.placementIdOrIndex,
    required this.elementId,
    required this.elementName,
    required this.worldX,
    required this.worldY,
    required this.instructionLeft,
    required this.instructionTop,
    required this.instructionWidth,
    required this.instructionHeight,
    required this.instructionArea,
    required this.opacity,
    required this.shapeKind,
    required this.geometryType,
    required this.renderPass,
    required this.family,
    required this.profile,
  });

  final int rank;
  final String placementIdOrIndex;
  final String elementId;
  final String elementName;
  final double worldX;
  final double worldY;
  final double instructionLeft;
  final double instructionTop;
  final double instructionWidth;
  final double instructionHeight;
  final double instructionArea;
  final double opacity;
  final String shapeKind;
  final String geometryType;
  final String renderPass;
  final String family;
  final String profile;
}

final class _CaptureArtifact {
  const _CaptureArtifact({
    required this.row,
    required this.cropLeft,
    required this.cropTop,
    required this.cropWidth,
    required this.cropHeight,
    required this.screenshotPath,
    required this.fileSizeBytes,
    required this.sha256,
  });

  final _ShadowCaptureRow row;
  final double cropLeft;
  final double cropTop;
  final int cropWidth;
  final int cropHeight;
  final String screenshotPath;
  final int fileSizeBytes;
  final String sha256;

  Map<String, Object?> toJson() {
    return {
      'rank': row.rank,
      'elementId': row.elementId,
      'elementName': row.elementName,
      'placementIdOrIndex': row.placementIdOrIndex,
      'worldX': row.worldX,
      'worldY': row.worldY,
      'cropLeft': cropLeft,
      'cropTop': cropTop,
      'cropWidth': cropWidth,
      'cropHeight': cropHeight,
      'screenshotPath': screenshotPath,
      'sha256': sha256,
      'fileSizeBytes': fileSizeBytes,
      'shapeKind': row.shapeKind,
      'geometryType': row.geometryType,
      'renderPass': row.renderPass,
      'family': row.family,
      'profile': row.profile,
      'opacity': row.opacity,
      'instructionWidth': row.instructionWidth,
      'instructionHeight': row.instructionHeight,
      'instructionArea': row.instructionArea,
    };
  }
}

final class _CurrentImageArtifact {
  const _CurrentImageArtifact({
    required this.kind,
    required this.rank,
    required this.elementId,
    required this.path,
    required this.sha256,
    required this.fileSizeBytes,
    required this.width,
    required this.height,
  });

  final String kind;
  final int? rank;
  final String? elementId;
  final String path;
  final String sha256;
  final int fileSizeBytes;
  final int width;
  final int height;

  String get key => _artifactKey(kind, rank);

  Map<String, Object?> toJson() {
    return {
      'kind': kind,
      'rank': rank,
      'elementId': elementId,
      'path': path,
      'sha256': sha256,
      'fileSizeBytes': fileSizeBytes,
      'width': width,
      'height': height,
    };
  }
}

final class _BaselineComparisonRow {
  const _BaselineComparisonRow({
    required this.rank,
    required this.kind,
    required this.elementId,
    required this.baselinePath,
    required this.currentPath,
    required this.baselineSha256,
    required this.currentSha256,
    required this.exactHashMatch,
    required this.baselineFileSizeBytes,
    required this.currentFileSizeBytes,
    required this.baselineWidth,
    required this.baselineHeight,
    required this.currentWidth,
    required this.currentHeight,
    required this.status,
  });

  factory _BaselineComparisonRow.structureFailure(String message) {
    return _BaselineComparisonRow(
      rank: null,
      kind: 'structure',
      elementId: null,
      baselinePath: null,
      currentPath: null,
      baselineSha256: null,
      currentSha256: null,
      exactHashMatch: false,
      baselineFileSizeBytes: null,
      currentFileSizeBytes: null,
      baselineWidth: null,
      baselineHeight: null,
      currentWidth: null,
      currentHeight: null,
      status: 'structure-fail:$message',
    );
  }

  final int? rank;
  final String kind;
  final String? elementId;
  final String? baselinePath;
  final String? currentPath;
  final String? baselineSha256;
  final String? currentSha256;
  final bool exactHashMatch;
  final int? baselineFileSizeBytes;
  final int? currentFileSizeBytes;
  final int? baselineWidth;
  final int? baselineHeight;
  final int? currentWidth;
  final int? currentHeight;
  final String status;

  bool get isBlockingFailure =>
      status.endsWith('-fail') || status.startsWith('structure-fail');

  Map<String, Object?> toJson() {
    return {
      'rank': rank,
      'kind': kind,
      'elementId': elementId,
      'baselinePath': baselinePath,
      'currentPath': currentPath,
      'baselineSha256': baselineSha256,
      'currentSha256': currentSha256,
      'exactHashMatch': exactHashMatch,
      'baselineFileSizeBytes': baselineFileSizeBytes,
      'currentFileSizeBytes': currentFileSizeBytes,
      'baselineWidth': baselineWidth,
      'baselineHeight': baselineHeight,
      'currentWidth': currentWidth,
      'currentHeight': currentHeight,
      'status': status,
    };
  }

  String toTsvLine() {
    return [
      rank ?? '',
      kind,
      elementId ?? '',
      baselinePath ?? '',
      currentPath ?? '',
      baselineSha256 ?? '',
      currentSha256 ?? '',
      exactHashMatch,
      baselineFileSizeBytes ?? '',
      currentFileSizeBytes ?? '',
      baselineWidth ?? '',
      baselineHeight ?? '',
      currentWidth ?? '',
      currentHeight ?? '',
      status,
    ].map((value) => '$value').join('\t');
  }
}

final class _BaselineComparisonResult {
  const _BaselineComparisonResult({
    required this.baselineId,
    required this.baselineDir,
    required this.counts,
    required this.rows,
  });

  final String baselineId;
  final String baselineDir;
  final _RuntimeCounts counts;
  final List<_BaselineComparisonRow> rows;

  bool get hasBlockingFailure => rows.any((row) => row.isBlockingFailure);

  int get exactMatches => rows.where((row) => row.status == 'match').length;

  int get informativeDiffs =>
      rows.where((row) => row.status == 'pixel-diff-informative').length;

  int get blockingFailures => rows.where((row) => row.isBlockingFailure).length;

  Map<String, Object?> summaryJson() {
    return {
      'baselineId': baselineId,
      'baselineDir': baselineDir,
      'mode': 'informative-hash-v0',
      'total': rows.length,
      'exactMatches': exactMatches,
      'informativeDiffs': informativeDiffs,
      'blockingFailures': blockingFailures,
      'hasBlockingFailure': hasBlockingFailure,
    };
  }

  Map<String, Object?> toJson() {
    return {
      ...summaryJson(),
      'counts': counts.toJson(),
      'rows': [
        for (final row in rows) row.toJson(),
      ],
    };
  }

  String toTsv() {
    const headers = [
      'rank',
      'kind',
      'elementId',
      'baselinePath',
      'currentPath',
      'baselineSha256',
      'currentSha256',
      'exactHashMatch',
      'baselineFileSizeBytes',
      'currentFileSizeBytes',
      'baselineWidth',
      'baselineHeight',
      'currentWidth',
      'currentHeight',
      'status',
    ];
    return '${[
      headers.join('\t'),
      for (final row in rows) row.toTsvLine(),
    ].join('\n')}\n';
  }
}

final class _RuntimeCounts {
  const _RuntimeCounts({
    required this.staticInstructions,
    required this.contactLedge,
    required this.genericProjection,
    required this.byElement,
    required this.byFamily,
    required this.byProfile,
  });

  final int staticInstructions;
  final int contactLedge;
  final int genericProjection;
  final Map<String, int> byElement;
  final Map<String, int> byFamily;
  final Map<String, int> byProfile;

  Map<String, Object?> toJson() {
    return {
      'staticInstructions': staticInstructions,
      'contactLedge': contactLedge,
      'genericProjection': genericProjection,
      'byElement': byElement,
      'byFamily': byFamily,
      'byProfile': byProfile,
    };
  }
}
