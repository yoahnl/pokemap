import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/presentation/border_preview_painter.dart';
import 'package:map_editor/src/features/border_studio/application/border_asset_snapshot_service.dart';
import 'package:map_editor/src/features/border_studio/application/border_project_element_asset_service.dart';
import 'package:map_editor/src/features/border_studio/application/border_publication_candidate_builder.dart';
import 'package:path/path.dart' as p;

const stoneChainVisualMapSize = GridSize(width: 16, height: 12);
const stoneChainVisualTileSizePx = 32;
const stoneChainVisualCanvasWidth = 512;
const stoneChainVisualCanvasHeight = 384;

final class StoneChainVisualCase {
  StoneChainVisualCase({
    required this.id,
    required this.goldenFile,
    required Iterable<GridPos> points,
    required Iterable<GridPos> turnVertices,
    required this.closed,
    this.lineSide = BorderLineSide.primary,
    this.rotationEnabled = false,
  })  : points = List<GridPos>.unmodifiable(points),
        turnVertices = List<GridPos>.unmodifiable(turnVertices);

  final String id;
  final String goldenFile;
  final List<GridPos> points;
  final List<GridPos> turnVertices;
  final bool closed;
  final BorderLineSide lineSide;
  final bool rotationEnabled;
}

final class StoneChainVisualCaseResolution {
  StoneChainVisualCaseResolution({
    required this.visualCase,
    required this.feature,
    required this.evidence,
    required this.parameters,
    required this.edgeCount,
    required Map<String, BorderPrimitiveRole> rolesByPrimitiveId,
  }) : _rolesByPrimitiveId = rolesByPrimitiveId;

  final StoneChainVisualCase visualCase;
  final BorderFeature feature;
  final StoneChainLineBorderResolutionEvidence evidence;
  final BorderGenerationParams parameters;
  final int edgeCount;
  final Map<String, BorderPrimitiveRole> _rolesByPrimitiveId;

  String get diagnostics => evidence.result.diagnostics
      .map(
        (item) => '${item.severity.name}:${item.code} ${item.parameters}',
      )
      .join(', ');

  List<BorderResolvedPlacement> get primaryPlacements =>
      evidence.result.materialization!.placements
          .where(
            (placement) =>
                placement.stableOrderKey.passIndex == 0 &&
                const <BorderPrimitiveRole>{
                  BorderPrimitiveRole.structureLarge,
                  BorderPrimitiveRole.structureMedium,
                  BorderPrimitiveRole.filler,
                  BorderPrimitiveRole.lineCorner,
                  BorderPrimitiveRole.lineCap,
                }.contains(_rolesByPrimitiveId[placement.primitiveId]),
          )
          .toList(growable: false);

  List<BorderResolvedPlacement> get cornerPlacements => _placementsWithRoles(
        const <BorderPrimitiveRole>{BorderPrimitiveRole.lineCorner},
      );

  List<BorderResolvedPlacement> get capPlacements => _placementsWithRoles(
        const <BorderPrimitiveRole>{BorderPrimitiveRole.lineCap},
      );

  List<BorderResolvedPlacement> get mediumPlacements => _placementsWithRoles(
        const <BorderPrimitiveRole>{BorderPrimitiveRole.structureMedium},
      );

  List<BorderResolvedPlacement> get turnConnectorPlacements {
    final expectedSlotKeys = <String>{
      for (final vertex in visualCase.turnVertices)
        for (final incoming in <bool>[true, false])
          turnConnectorSlotKey(vertex, incoming: incoming),
    };
    return evidence.result.materialization!.placements
        .where((placement) => expectedSlotKeys.contains(placement.slotKey))
        .toList(growable: false);
  }

  String turnConnectorSlotKey(GridPos vertex, {required bool incoming}) =>
      buildBorderStoneChainNodeSlotKey(
        featureId: feature.id,
        strokeId: borderStrokeLineageNamespaceV1(visualCase.id),
        vertex: vertex,
        passIndex: 0,
        role: BorderPrimitiveRole.structureMedium,
        rank: visualCase.points.indexOf(vertex) * 2 + (incoming ? 0 : 1),
      );

  List<BorderResolvedPlacement> _placementsWithRoles(
    Set<BorderPrimitiveRole> roles,
  ) =>
      evidence.result.materialization!.placements
          .where(
            (placement) => roles.contains(
              _rolesByPrimitiveId[placement.primitiveId],
            ),
          )
          .toList(growable: false);
}

/// Visual bench backed by the real Selbrume project elements and immutable
/// Border snapshot payloads. A draft-only project is published in memory; no
/// manifest or snapshot file is ever written by this fixture.
final class StoneChainVisualFixture {
  StoneChainVisualFixture._({
    required File projectFile,
    required List<int> projectBytesBefore,
    required this.manifest,
    required this.blueprintId,
    required this.publishedRevision,
    required this.frameImagesByKey,
  })  : _projectFile = projectFile,
        _projectBytesBefore = List<int>.unmodifiable(projectBytesBefore),
        cases = List<StoneChainVisualCase>.unmodifiable(_visualCases()),
        allowedQuarterTurnsByPrimitiveId = Map<String, List<int>>.unmodifiable(
          <String, List<int>>{
            for (final primitive in publishedRevision.definition.primitives)
              primitive.id: List<int>.unmodifiable(
                primitive.transforms.allowedQuarterTurns,
              ),
          },
        ),
        _rolesByPrimitiveId = Map<String, BorderPrimitiveRole>.unmodifiable(
          <String, BorderPrimitiveRole>{
            for (final primitive in publishedRevision.definition.primitives)
              primitive.id: primitive.role,
          },
        );

  static Future<StoneChainVisualFixture> load() async {
    final projectRoot = p.normalize(
      p.join(Directory.current.path, '..', '..', 'selbrume'),
    );
    final projectFile = File(p.join(projectRoot, 'project.json'));
    final projectBytesBefore = await projectFile.readAsBytes();
    final projectJson =
        jsonDecode(utf8.decode(projectBytesBefore)) as Map<String, Object?>;
    final sourceManifest = ProjectManifest.fromJson(projectJson);
    const blueprintId = 'border-blueprint-3';
    final sourceRecord = sourceManifest.borderCatalog.recordById(blueprintId);
    if (sourceRecord == null) {
      throw StateError('$blueprintId is missing from Selbrume project.json');
    }

    var manifest = sourceManifest;
    var payloadsByRelativePath = <String, Uint8List>{};
    if (sourceRecord.latestPublished == null) {
      const assetService = BorderProjectElementAssetService();
      final preparations = <String, BorderAssetSnapshotPreparation>{};
      for (final primitive in sourceRecord.draft.definition.primitives) {
        final prepared = await assetService.reanalyze(
          manifest: sourceManifest,
          projectRootPath: projectRoot,
          primitive: primitive,
        );
        preparations[primitive.id] = prepared.preparation;
      }
      final candidate = const BorderPublicationCandidateBuilder().build(
        manifest: sourceManifest,
        draftRecord: sourceRecord,
        primitiveSnapshotsByPrimitiveId: preparations,
      );
      manifest = candidate.nextManifest;
      payloadsByRelativePath = <String, Uint8List>{
        for (final payload in candidate.files)
          payload.relativePath: Uint8List.fromList(payload.bytes),
      };
    }

    final publishedRecord = manifest.borderCatalog.recordById(blueprintId)!;
    final publishedRevision = publishedRecord.latestPublished;
    if (publishedRevision == null || publishedRevision.revision < 1) {
      throw StateError(
        '$blueprintId visual fixture requires a published revision, got '
        '${publishedRevision?.revision}',
      );
    }
    final activeDraftPrimitiveIds = <String>{
      for (final primitive in publishedRecord.draft.definition.primitives)
        if (primitive.weight > 0) primitive.id,
    };
    final publishedPrimitiveIds = <String>{
      for (final primitive in publishedRevision.definition.primitives)
        primitive.id,
    };
    if (publishedPrimitiveIds.isEmpty ||
        publishedPrimitiveIds.length !=
            publishedRevision.definition.primitives.length ||
        publishedPrimitiveIds.difference(activeDraftPrimitiveIds).isNotEmpty ||
        activeDraftPrimitiveIds.difference(publishedPrimitiveIds).isNotEmpty) {
      throw StateError(
        '$blueprintId must publish every active draft primitive exactly once; '
        'active=$activeDraftPrimitiveIds, published=$publishedPrimitiveIds',
      );
    }

    final frameImagesByKey = <String, ui.Image?>{};
    for (final primitive in publishedRevision.definition.primitives) {
      final snapshot = manifest.borderCatalog.visualSnapshotById(
        primitive.visualSnapshotId,
      );
      if (snapshot == null || snapshot.frames.length != 1) {
        throw StateError(
          '${primitive.id} must reference one published visual frame',
        );
      }
      final frame = snapshot.frames.single;
      final relativePath = frame.relativeAssetPath;
      final bytes = payloadsByRelativePath[relativePath] ??
          await File(p.join(projectRoot, relativePath)).readAsBytes();
      final image = await _decodePng(Uint8List.fromList(bytes));
      frameImagesByKey[editorBorderFrameImageKey(snapshot.id, 0)] = image;
    }

    return StoneChainVisualFixture._(
      projectFile: projectFile,
      projectBytesBefore: projectBytesBefore,
      manifest: manifest,
      blueprintId: blueprintId,
      publishedRevision: publishedRevision,
      frameImagesByKey: frameImagesByKey,
    );
  }

  final File _projectFile;
  final List<int> _projectBytesBefore;
  final ProjectManifest manifest;
  final String blueprintId;
  final BorderBlueprintRevision publishedRevision;
  final Map<String, ui.Image?> frameImagesByKey;
  final List<StoneChainVisualCase> cases;
  final Map<String, List<int>> allowedQuarterTurnsByPrimitiveId;
  final Map<String, BorderPrimitiveRole> _rolesByPrimitiveId;

  StoneChainVisualCaseResolution resolve(
    StoneChainVisualCase visualCase, {
    List<BorderSlotOverride> overrides = const <BorderSlotOverride>[],
  }) {
    final defaults = publishedRevision.definition.defaults;
    final parameters = visualCase.rotationEnabled
        ? BorderGenerationParams(
            irregularityPermille: defaults.irregularityPermille,
            detailDensityPermille: defaults.detailDensityPermille,
            variationPermille: defaults.variationPermille,
            maxOverlapPx: defaults.maxOverlapPx,
            gapTolerancePx: defaults.gapTolerancePx,
            depthRows: defaults.depthRows,
            allowAutoRotation: true,
          )
        : defaults;
    final feature = BorderFeature(
      id: 'stone-chain-visual-${visualCase.id}',
      name: visualCase.id,
      blueprintId: blueprintId,
      seed: publishedRevision.definition.previewSeed,
      geometry: BorderStrokeGeometry(
        strokes: <BorderStroke>[
          BorderStroke(
            id: visualCase.id,
            points: visualCase.points,
            closed: visualCase.closed,
          ),
        ],
        alignment: BorderStrokeAlignment.gridEdges,
      ),
      lineSide: visualCase.lineSide,
      paramsOverride: visualCase.rotationEnabled ? parameters : null,
      overrides: overrides,
      keepOutRegions: const <BorderKeepOutRegion>[],
    );
    final evidence = resolveStoneChainLineBorderWithEvidence(
      BorderResolutionRequest(
        mapSize: stoneChainVisualMapSize,
        tileSizePx: const GridSize(
          width: stoneChainVisualTileSizePx,
          height: stoneChainVisualTileSizePx,
        ),
        blueprintId: blueprintId,
        blueprintRevision: publishedRevision,
        feature: feature,
        visualSnapshots: manifest.borderCatalog.visualSnapshots,
        resolverVersion: borderResolverVersion,
      ),
    );
    return StoneChainVisualCaseResolution(
      visualCase: visualCase,
      feature: feature,
      evidence: evidence,
      parameters: parameters,
      edgeCount: visualCase.closed
          ? visualCase.points.length
          : visualCase.points.length - 1,
      rolesByPrimitiveId: _rolesByPrimitiveId,
    );
  }

  Future<ui.Image> render(StoneChainVisualCaseResolution resolution) async {
    final materialization = resolution.evidence.result.materialization;
    if (materialization == null) {
      throw StateError(
        '${resolution.visualCase.id} cannot render: ${resolution.diagnostics}',
      );
    }
    final source = resolution.feature;
    final feature = BorderFeature(
      id: source.id,
      name: source.name,
      blueprintId: source.blueprintId,
      seed: source.seed,
      geometry: source.geometry,
      lineSide: source.lineSide,
      paramsOverride: source.paramsOverride,
      overrides: source.overrides,
      keepOutRegions: source.keepOutRegions,
      materialization: materialization,
    );
    final layer = MapLayer.border(
      id: 'stone-chain-visual-layer',
      name: 'Stone chain visual bench',
      content: BorderLayerContent(features: <BorderFeature>[feature]),
    ) as BorderLayer;
    final map = MapData(
      id: 'stone-chain-visual-${resolution.visualCase.id}',
      name: resolution.visualCase.id,
      version: ProjectVersion.v6,
      size: stoneChainVisualMapSize,
      properties: const <String, dynamic>{
        'tileLayerOrder': 'bottom_to_top',
      },
      layers: <MapLayer>[layer],
    );

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, 512, 384),
      ui.Paint()..color = const ui.Color(0xFF29313A),
    );
    const BorderPreviewPainter().paintLayer(
      canvas,
      map: map,
      layer: layer,
      catalog: manifest.borderCatalog,
      frameImagesByKey: frameImagesByKey,
      sourceTileWidth: stoneChainVisualTileSizePx,
      sourceTileHeight: stoneChainVisualTileSizePx,
      displayScale: 1,
      elapsedMs: 0,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      stoneChainVisualCanvasWidth,
      stoneChainVisualCanvasHeight,
    );
    picture.dispose();
    return image;
  }

  Future<bool> projectBytesAreUnchanged() async {
    final current = await _projectFile.readAsBytes();
    if (current.length != _projectBytesBefore.length) return false;
    for (var index = 0; index < current.length; index += 1) {
      if (current[index] != _projectBytesBefore[index]) return false;
    }
    return true;
  }

  void dispose() {
    for (final image in frameImagesByKey.values.whereType<ui.Image>()) {
      image.dispose();
    }
  }
}

Future<ui.Image> _decodePng(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  try {
    final frame = await codec.getNextFrame();
    return frame.image;
  } finally {
    codec.dispose();
  }
}

List<StoneChainVisualCase> _visualCases() {
  final horizontal = <GridPos>[
    for (var x = 2; x <= 13; x += 1) GridPos(x: x, y: 6),
  ];
  final vertical = <GridPos>[
    for (var y = 1; y <= 10; y += 1) GridPos(x: 8, y: y),
  ];
  final l = <GridPos>[
    for (var x = 2; x <= 10; x += 1) GridPos(x: x, y: 2),
    for (var y = 3; y <= 9; y += 1) GridPos(x: 10, y: y),
  ];
  final s = <GridPos>[
    for (var x = 2; x <= 7; x += 1) GridPos(x: x, y: 2),
    for (var y = 3; y <= 7; y += 1) GridPos(x: 7, y: y),
    for (var x = 8; x <= 13; x += 1) GridPos(x: x, y: 7),
  ];
  final loop = <GridPos>[
    for (var x = 4; x <= 11; x += 1) GridPos(x: x, y: 3),
    for (var y = 4; y <= 8; y += 1) GridPos(x: 11, y: y),
    for (var x = 10; x >= 4; x -= 1) GridPos(x: x, y: 8),
    for (var y = 7; y >= 4; y -= 1) GridPos(x: 4, y: y),
  ];
  return <StoneChainVisualCase>[
    StoneChainVisualCase(
      id: 'horizontal',
      goldenFile: 'goldens/stone_chain_horizontal.png',
      points: horizontal,
      turnVertices: const <GridPos>[],
      closed: false,
    ),
    StoneChainVisualCase(
      id: 'vertical',
      goldenFile: 'goldens/stone_chain_vertical.png',
      points: vertical,
      turnVertices: const <GridPos>[],
      closed: false,
    ),
    StoneChainVisualCase(
      id: 'l_primary',
      goldenFile: 'goldens/stone_chain_l_primary.png',
      points: l,
      turnVertices: const <GridPos>[GridPos(x: 10, y: 2)],
      closed: false,
    ),
    StoneChainVisualCase(
      id: 'l_inverted',
      goldenFile: 'goldens/stone_chain_l_inverted.png',
      points: l,
      turnVertices: const <GridPos>[GridPos(x: 10, y: 2)],
      closed: false,
      lineSide: BorderLineSide.inverted,
    ),
    StoneChainVisualCase(
      id: 's_primary',
      goldenFile: 'goldens/stone_chain_s_primary.png',
      points: s,
      turnVertices: const <GridPos>[
        GridPos(x: 7, y: 2),
        GridPos(x: 7, y: 7),
      ],
      closed: false,
    ),
    StoneChainVisualCase(
      id: 'closed_loop',
      goldenFile: 'goldens/stone_chain_closed_loop.png',
      points: loop,
      turnVertices: const <GridPos>[
        GridPos(x: 4, y: 3),
        GridPos(x: 11, y: 3),
        GridPos(x: 11, y: 8),
        GridPos(x: 4, y: 8),
      ],
      closed: true,
    ),
    StoneChainVisualCase(
      id: 's_inverted',
      goldenFile: 'goldens/stone_chain_s_inverted.png',
      points: s,
      turnVertices: const <GridPos>[
        GridPos(x: 7, y: 2),
        GridPos(x: 7, y: 7),
      ],
      closed: false,
      lineSide: BorderLineSide.inverted,
    ),
    StoneChainVisualCase(
      id: 'l_auto_rotation',
      goldenFile: 'goldens/stone_chain_l_auto_rotation.png',
      points: l,
      turnVertices: const <GridPos>[GridPos(x: 10, y: 2)],
      closed: false,
      rotationEnabled: true,
    ),
  ];
}
