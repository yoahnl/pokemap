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
    for (final row in shadowRows.where((row) => row.geometryType == 'contactLedge')) {
      final cropLeft =
          (row.instructionLeft - 260).clamp(0, worldWidth - _contactCropWidth);
      final cropTop = (row.instructionTop - 430)
          .clamp(0, worldHeight - _contactCropHeight);
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

    final overviewArtifact = {
      'path': overviewPath,
      'width': (worldWidth * _overviewScale).round(),
      'height': (worldHeight * _overviewScale).round(),
      'fileSizeBytes': await File(overviewPath).length(),
      'sha256': await _sha256ForFile(overviewPath),
    };
    final indexPath =
        p.join(config.artifactDir, 'shadow_lot_65_capture_index.tsv');
    final manifestPath =
        p.join(config.artifactDir, 'shadow_lot_65_capture_manifest.json');
    await File(indexPath).writeAsString(_captureIndexTsv(captures));
    await File(manifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'lot': 'Shadow-65',
        'projectPath': config.projectPath,
        'mapId': _mapId,
        'prefix': config.prefix,
        'outputDir': config.outputDir,
        'overview': overviewArtifact,
        'indexTsv': indexPath,
        'counts': counts.toJson(),
        'captures': [
          for (final capture in captures) capture.toJson(),
        ],
      }),
    );

    final summary = {
      'projectPath': config.projectPath,
      'outputDir': config.outputDir,
      'prefix': config.prefix,
      'overview': overviewArtifact,
      'indexTsv': indexPath,
      'manifest': manifestPath,
      'counts': counts.toJson(),
    };
    debugPrint(const JsonEncoder.withIndent('  ').convert(summary));

    expect(counts.staticInstructions, 10);
    expect(counts.contactLedge, 10);
    expect(counts.genericProjection, 0);
    expect(captures, hasLength(10));
    expect(File(overviewPath).existsSync(), isTrue);
    expect(File(indexPath).existsSync(), isTrue);
    expect(File(manifestPath).existsSync(), isTrue);
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
  final image = await recorder.endRecording().toImage(outputWidth, outputHeight);
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

String _safeFilePart(String value) {
  return value.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
}

final class _HarnessConfig {
  const _HarnessConfig({
    required this.projectPath,
    required this.outputDir,
    required this.prefix,
    required this.artifactDir,
  });

  factory _HarnessConfig.fromEnvironment() {
    final projectPath =
        Platform.environment['SELBRUME_PROJECT_PATH'] ?? _defaultProjectPath;
    final outputDir = Directory(
      Platform.environment['SHADOW_SCREENSHOT_OUTPUT_DIR'] ?? _defaultOutputDir,
    ).absolute.path;
    final prefix =
        _safeFilePart(Platform.environment['SHADOW_SCREENSHOT_PREFIX'] ??
            _defaultPrefix);
    final artifactDir = p.basename(outputDir) == 'screenshots'
        ? Directory(outputDir).parent.path
        : outputDir;
    return _HarnessConfig(
      projectPath: projectPath,
      outputDir: outputDir,
      prefix: prefix,
      artifactDir: artifactDir,
    );
  }

  final String projectPath;
  final String outputDir;
  final String prefix;
  final String artifactDir;
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
