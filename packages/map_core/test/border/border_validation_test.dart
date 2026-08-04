import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _hexA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _hexB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _snapshotA = 'border-snapshot-sha256:$_hexA';
const _snapshotB = 'border-snapshot-sha256:$_hexB';
const _validHash =
    'sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';

void main() {
  test('grid-edge vertices use inclusive map bounds', () {
    BorderResolutionRequest edgeRequest(BorderStrokeGeometry geometry) =>
        _request(
          template: BorderBlueprintTemplate.stoneChainLine,
          feature: BorderFeature(
            id: 'feature',
            name: 'Feature',
            blueprintId: 'blueprint',
            seed: BorderSignedInt64.zero,
            geometry: geometry,
            overrides: const <BorderSlotOverride>[],
            keepOutRegions: const <BorderKeepOutRegion>[],
          ),
        );

    BorderStrokeGeometry geometry(
      List<GridPos> points, {
      BorderStrokeAlignment alignment = BorderStrokeAlignment.gridEdges,
    }) =>
        BorderStrokeGeometry(
          strokes: <BorderStroke>[
            BorderStroke(id: 'edge', points: points, closed: false),
          ],
          alignment: alignment,
        );

    BorderDiagnosticsReport diagnose(BorderStrokeGeometry value) =>
        diagnoseBorderFeature(
          edgeRequest(value),
          materialization: null,
          purpose: BorderFeatureValidationPurpose.resolution,
          snapshotIntegrity: _integrity(),
        );

    final boundary = geometry(const <GridPos>[
      GridPos(x: 2, y: 2),
      GridPos(x: 3, y: 2),
    ]);
    expect(_codes(diagnose(boundary)),
        isNot(contains('border.feature.stroke_cell_out_of_bounds')));
    expect(
      _codes(diagnose(geometry(
        const <GridPos>[GridPos(x: 2, y: 2), GridPos(x: 3, y: 2)],
        alignment: BorderStrokeAlignment.cellCenters,
      ))),
      contains('border.feature.stroke_cell_out_of_bounds'),
    );
    for (final invalid in <List<GridPos>>[
      const <GridPos>[GridPos(x: -1, y: 0), GridPos(x: 0, y: 0)],
      const <GridPos>[GridPos(x: 3, y: 2), GridPos(x: 4, y: 2)],
    ]) {
      expect(
        _codes(diagnose(geometry(invalid))),
        contains('border.feature.stroke_cell_out_of_bounds'),
      );
    }
  });

  group('diagnoseBorderBlueprint', () {
    test('a valid published record has no diagnostics', () {
      final report = diagnoseBorderBlueprint(
        _record(),
        project: _project(),
        purpose: BorderBlueprintValidationPurpose.resolution,
        snapshotIntegrity: _integrity(),
      );

      expect(report.diagnostics, isEmpty);
    });

    test(
        'draft source element and Smart Tile references are recoverable errors',
        () {
      final report = diagnoseBorderBlueprint(
        _record(
          draftPrimitives: <BorderPrimitiveDraft>[
            _draftPrimitive(sourceElementId: 'missing-element'),
          ],
          draftGround: BorderGroundDraft(
            sourceSmartTilePresetId: 'missing-smart-tile',
            edgeBandCells: 1,
          ),
        ),
        project: _project(),
        purpose: BorderBlueprintValidationPurpose.authoring,
        snapshotIntegrity: _integrity(),
      );

      expect(
        _codes(report),
        containsAll(<String>[
          'border.blueprint.source_element_missing',
          'border.blueprint.source_smart_tile_preset_missing',
        ]),
      );
      expect(report.errorCount, 2);
    });

    test('duplicates and every metric invariant produce stable diagnostics',
        () {
      final invalidRle = _metrics(occupancy: 'not-rle');
      final emptyRle = _metrics(occupancy: 'border-rle-v1:4:0:4');
      final invalidAnchor = _metrics(
        defaultAnchor: const BorderPixelPos(x: 2, y: 0),
      );
      final record = _record(
        draftPrimitives: <BorderPrimitiveDraft>[
          _draftPrimitive(id: 'duplicate', metrics: invalidRle),
          _draftPrimitive(id: 'duplicate', metrics: emptyRle),
          _draftPrimitive(
            id: 'anchor',
            anchor: const BorderPixelPos(x: -1, y: 0),
            metrics: invalidAnchor,
          ),
        ],
        publishedPrimitives: <BorderPublishedPrimitive>[
          _publishedPrimitive(id: 'published-duplicate'),
          _publishedPrimitive(id: 'published-duplicate'),
        ],
      );

      final report = diagnoseBorderBlueprint(
        record,
        project: _project(),
        purpose: BorderBlueprintValidationPurpose.publication,
        snapshotIntegrity: _integrity(),
      );

      expect(
        _codes(report),
        containsAll(<String>[
          'border.blueprint.duplicate_primitive_id',
          'border.blueprint.occupancy_mask_invalid',
          'border.blueprint.occupancy_mask_empty',
          'border.blueprint.anchor_outside_asset',
        ]),
      );
      expect(
        report.diagnostics,
        orderedEquals(report.diagnostics.toList()..sort()),
      );
    });

    test('rejects in-memory metrics beyond the bounded RLE V1 dimensions', () {
      final oversizedMetrics = BorderPrimitiveAssetMetrics(
        assetFingerprint: 'oversized',
        pixelSize: const GridSize(width: 8193, height: 1),
        opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
        defaultAnchorPx: const BorderPixelPos(x: 0, y: 0),
        occupancyMaskRle: 'border-rle-v1:8193:1:8193',
      );
      final report = diagnoseBorderBlueprint(
        _record(
          publishedPrimitives: <BorderPublishedPrimitive>[
            _publishedPrimitive(metrics: oversizedMetrics),
          ],
        ),
        project: _project(),
        purpose: BorderBlueprintValidationPurpose.resolution,
        snapshotIntegrity: _integrity(),
      );

      expect(
        _codes(report),
        contains('border.blueprint.occupancy_mask_invalid'),
      );
    });

    test('missing published snapshot differs from invalid integrity', () {
      final record = _record();
      final missing = diagnoseBorderBlueprint(
        record,
        project: _project(includeSnapshot: false),
        purpose: BorderBlueprintValidationPurpose.resolution,
        snapshotIntegrity: _integrity(),
      );
      final invalidStatuses = <BorderVisualSnapshotIntegrity>[
        _status(metadataValid: false),
        _status(filesPresent: false),
        _status(contentFingerprintMatches: false),
      ];

      expect(_codes(missing),
          contains('border.blueprint.visual_snapshot_missing'));
      for (final status in invalidStatuses) {
        final report = diagnoseBorderBlueprint(
          record,
          project: _project(),
          purpose: BorderBlueprintValidationPurpose.resolution,
          snapshotIntegrity: <String, BorderVisualSnapshotIntegrity>{
            _snapshotA: status,
          },
        );
        expect(
          _codes(report),
          contains('border.blueprint.visual_snapshot_invalid'),
        );
      }
    });

    test('deduplicates shared published ground snapshot diagnostics', () {
      final sharedGround = BorderPublishedGround(
        sourceSmartTilePresetId: 'surface',
        edgeBandCells: 1,
        visualSnapshotIdsByRole: <BorderGroundVariantRole, String>{
          for (final role in standardBorderGroundVariantRoleOrder) role: _snapshotB,
        },
      );
      final report = diagnoseBorderBlueprint(
        _record(publishedGround: sharedGround),
        project: _project(),
        purpose: BorderBlueprintValidationPurpose.resolution,
        snapshotIntegrity: _integrity(),
      );

      expect(
        report.diagnostics.where(
          (diagnostic) =>
              diagnostic.code == 'border.blueprint.visual_snapshot_missing',
        ),
        hasLength(1),
      );
    });

    test('unpublished record is loadable but resolution-diagnosed', () {
      final report = diagnoseBorderBlueprint(
        _record(published: false),
        project: _project(includeSnapshot: false),
        purpose: BorderBlueprintValidationPurpose.resolution,
        snapshotIntegrity: const <String, BorderVisualSnapshotIntegrity>{},
      );

      expect(_codes(report), contains('border.blueprint.not_published'));
      expect(report.hasErrors, isTrue);
    });
  });

  group('diagnoseBorderFeature intent and references', () {
    test(
        'materialization absence is info while authoring and error for play/export',
        () {
      final request = _request();
      final authoring = diagnoseBorderFeature(
        request,
        materialization: null,
        purpose: BorderFeatureValidationPurpose.authoring,
        snapshotIntegrity: _integrity(),
      );
      final play = diagnoseBorderFeature(
        request,
        materialization: null,
        purpose: BorderFeatureValidationPurpose.playExport,
        snapshotIntegrity: _integrity(),
      );

      expect(
        authoring.diagnostics
            .singleWhere(
              (diagnostic) =>
                  diagnostic.code == 'border.materialization.missing',
            )
            .severity,
        BorderDiagnosticSeverity.info,
      );
      expect(
        play.diagnostics
            .singleWhere(
              (diagnostic) =>
                  diagnostic.code == 'border.materialization.missing',
            )
            .severity,
        BorderDiagnosticSeverity.error,
      );
    });

    test(
        'validates template family, dimensions, emptiness, keep-outs, and stroke bounds',
        () {
      final emptyWrongSize = _request(
        feature: BorderFeature(
          id: 'feature',
          name: 'Feature',
          blueprintId: 'blueprint',
          seed: BorderSignedInt64.zero,
          geometry: BorderRegionGeometry(
            width: 1,
            height: 1,
            cells: const <bool>[false],
          ),
          overrides: const <BorderSlotOverride>[],
          keepOutRegions: <BorderKeepOutRegion>[
            BorderKeepOutRegion(
              id: 'wrong-size',
              region: BorderRegionGeometry(
                width: 1,
                height: 1,
                cells: const <bool>[true],
              ),
            ),
          ],
        ),
      );
      final wrongFamily = _request(
        template: BorderBlueprintTemplate.masonryLine,
      );
      final outOfBoundsStroke = _request(
        template: BorderBlueprintTemplate.masonryLine,
        feature: BorderFeature(
          id: 'feature',
          name: 'Feature',
          blueprintId: 'blueprint',
          seed: BorderSignedInt64.zero,
          geometry: BorderStrokeGeometry(
            strokes: <BorderStroke>[
              BorderStroke(
                id: 'stroke',
                points: const <GridPos>[
                  GridPos(x: 2, y: 0),
                  GridPos(x: 3, y: 0),
                ],
                closed: false,
              ),
            ],
          ),
          overrides: const <BorderSlotOverride>[],
          keepOutRegions: const <BorderKeepOutRegion>[],
        ),
      );

      final reports = <BorderDiagnosticsReport>[
        diagnoseBorderFeature(
          emptyWrongSize,
          materialization: null,
          purpose: BorderFeatureValidationPurpose.resolution,
          snapshotIntegrity: _integrity(),
        ),
        diagnoseBorderFeature(
          wrongFamily,
          materialization: null,
          purpose: BorderFeatureValidationPurpose.resolution,
          snapshotIntegrity: _integrity(),
        ),
        diagnoseBorderFeature(
          outOfBoundsStroke,
          materialization: null,
          purpose: BorderFeatureValidationPurpose.resolution,
          snapshotIntegrity: _integrity(),
        ),
      ];
      final codes = reports.expand(_codes).toSet();

      expect(
        codes,
        containsAll(<String>[
          'border.feature.region_size_mismatch',
          'border.feature.geometry_empty',
          'border.feature.keep_out_size_mismatch',
          'border.feature.geometry_template_mismatch',
          'border.feature.stroke_cell_out_of_bounds',
        ]),
      );
    });

    test('connected-line accepts strokes and rejects region geometry', () {
      final region = diagnoseBorderFeature(
        _request(template: BorderBlueprintTemplate.connectedLine),
        materialization: null,
        purpose: BorderFeatureValidationPurpose.resolution,
        snapshotIntegrity: _integrity(),
      );
      final stroke = diagnoseBorderFeature(
        _request(
          template: BorderBlueprintTemplate.connectedLine,
          feature: BorderFeature(
            id: 'feature',
            name: 'Feature',
            blueprintId: 'blueprint',
            seed: BorderSignedInt64.zero,
            geometry: BorderStrokeGeometry(
              strokes: <BorderStroke>[
                BorderStroke(
                  id: 'stroke',
                  points: const <GridPos>[
                    GridPos(x: 0, y: 0),
                    GridPos(x: 1, y: 0),
                  ],
                  closed: false,
                ),
              ],
            ),
            overrides: const <BorderSlotOverride>[],
            keepOutRegions: const <BorderKeepOutRegion>[],
          ),
        ),
        materialization: null,
        purpose: BorderFeatureValidationPurpose.resolution,
        snapshotIntegrity: _integrity(),
      );

      expect(
        _codes(region),
        contains('border.feature.geometry_template_mismatch'),
      );
      expect(
        _codes(stroke),
        isNot(contains('border.feature.geometry_template_mismatch')),
      );
    });

    test('diagnoses dangling primitive and locked snapshot override references',
        () {
      final feature = BorderFeature(
        id: 'feature',
        name: 'Feature',
        blueprintId: 'blueprint',
        seed: BorderSignedInt64.zero,
        geometry: _region(),
        overrides: <BorderSlotOverride>[
          BorderSlotOverride(
            slotKey: 'replacement',
            variationSalt: BorderSignedInt64.zero,
            suppressed: false,
            locked: false,
            replacementPrimitiveId: 'missing',
          ),
          BorderSlotOverride(
            slotKey: 'locked',
            variationSalt: BorderSignedInt64.zero,
            suppressed: false,
            locked: true,
            lockedPlacement: _placement(
              slotKey: 'locked',
              primitiveId: 'missing',
              snapshotId: _snapshotB,
            ),
          ),
        ],
        keepOutRegions: const <BorderKeepOutRegion>[],
      );
      final report = diagnoseBorderFeature(
        _request(
          feature: feature,
          snapshots: <BorderVisualSnapshot>[
            _snapshotAModel(),
            _snapshotBModel()
          ],
        ),
        materialization: null,
        purpose: BorderFeatureValidationPurpose.resolution,
        snapshotIntegrity: <String, BorderVisualSnapshotIntegrity>{
          _snapshotA: _status(),
          _snapshotB: _status(
            snapshotId: _snapshotB,
            filesPresent: false,
          ),
        },
      );

      expect(
        _codes(report),
        containsAll(<String>[
          'border.feature.override_primitive_missing',
          'border.feature.override_snapshot_missing_or_corrupt',
        ]),
      );
    });
  });

  group('diagnoseBorderFeature materialization', () {
    test(
        'diagnoses ground, anchor, anchorRowMajor, bounds, receipt, output, and snapshot',
        () {
      final request = _request(
        snapshots: <BorderVisualSnapshot>[_snapshotAModel(), _snapshotBModel()],
      );
      final base = _materialization(
        request,
        ground: <BorderResolvedGroundCell>[
          _ground(x: 99, snapshotId: _snapshotB),
        ],
        placements: <BorderResolvedPlacement>[
          _placement(
            anchor: const GridPos(x: 99, y: 0),
            anchorRowMajor: 0,
            opaqueX: 999,
          ),
        ],
      );
      final invalidReceipt = _replaceReceipt(
        base,
        inputFingerprint: _validHash,
        outputFingerprint: _validHash,
      );
      final report = diagnoseBorderFeature(
        request,
        materialization: invalidReceipt,
        purpose: BorderFeatureValidationPurpose.playExport,
        snapshotIntegrity: <String, BorderVisualSnapshotIntegrity>{
          _snapshotA: _status(),
          _snapshotB: _status(snapshotId: _snapshotB, metadataValid: false),
        },
      );

      expect(
        _codes(report),
        containsAll(<String>[
          'border.materialization.ground_cell_out_of_bounds',
          'border.materialization.anchor_out_of_bounds',
          'border.materialization.anchor_row_major_invalid',
          'border.materialization.opaque_bounds_outside_canvas',
          'border.materialization.receipt_input_fingerprint_invalid',
          'border.materialization.output_fingerprint_invalid',
          'border.materialization.snapshot_missing_or_corrupt',
        ]),
      );
      expect(report.hasErrors, isTrue);
    });

    test('missing blueprint with valid old output remains play/export-safe',
        () {
      final oldRequest = _request();
      final oldOutput = _materialization(oldRequest);
      final current = _request(
        published: false,
        feature: BorderFeature(
          id: 'feature',
          name: 'Feature',
          blueprintId: 'blueprint',
          seed: BorderSignedInt64.fromInt(99),
          geometry: BorderRegionGeometry(
            width: 1,
            height: 1,
            cells: const <bool>[false],
          ),
          overrides: const <BorderSlotOverride>[],
          keepOutRegions: const <BorderKeepOutRegion>[],
        ),
      );
      final report = diagnoseBorderFeature(
        current,
        materialization: oldOutput,
        purpose: BorderFeatureValidationPurpose.playExport,
        snapshotIntegrity: _integrity(),
      );

      expect(report.hasErrors, isFalse);
      expect(
        _codes(report),
        containsAll(<String>[
          'border.feature.blueprint_unavailable',
          'border.feature.region_size_mismatch',
          'border.feature.geometry_empty',
          'border.materialization.blueprint_missing',
        ]),
      );
      expect(
        report.diagnostics
            .where(
                (diagnostic) => diagnostic.code.startsWith('border.feature.'))
            .every((diagnostic) =>
                diagnostic.severity != BorderDiagnosticSeverity.error),
        isTrue,
      );
    });

    test(
        'corrupt snapshot used only by a newer blueprint does not block old output export',
        () {
      final oldRequest = _request(revision: 1);
      final output = _materialization(oldRequest);
      final current = _request(
        revision: 2,
        primitiveSnapshotId: _snapshotB,
        snapshots: <BorderVisualSnapshot>[_snapshotAModel(), _snapshotBModel()],
      );
      final integrity = <String, BorderVisualSnapshotIntegrity>{
        _snapshotA: _status(),
        _snapshotB: _status(
          snapshotId: _snapshotB,
          contentFingerprintMatches: false,
        ),
      };
      final freshness = assessBorderMaterializationFreshness(
        current,
        materialization: output,
        snapshotIntegrity: integrity,
      );
      final report = diagnoseBorderFeature(
        current,
        materialization: output,
        purpose: BorderFeatureValidationPurpose.playExport,
        snapshotIntegrity: integrity,
      );

      expect(freshness.state, BorderMaterializationState.stale);
      expect(freshness.isRenderable, isTrue);
      expect(freshness.canRegenerate, isFalse);
      expect(report.hasErrors, isFalse);
    });

    test(
        'canonical output and current-input hash failures become invalid state and diagnostics',
        () {
      final request = _request();
      final nonPortable = 9007199254740992;
      final placement = _placement(
        topLeftX: nonPortable,
        opaqueX: nonPortable,
      );
      final materialization = _materializationWithoutOutputHash(
        request,
        placements: <BorderResolvedPlacement>[placement],
      );

      expect(
        () => assessBorderMaterializationFreshness(
          request,
          materialization: materialization,
          snapshotIntegrity: _integrity(),
        ),
        returnsNormally,
      );
      final freshness = assessBorderMaterializationFreshness(
        request,
        materialization: materialization,
        snapshotIntegrity: _integrity(),
      );
      final report = diagnoseBorderFeature(
        request,
        materialization: materialization,
        purpose: BorderFeatureValidationPurpose.playExport,
        snapshotIntegrity: _integrity(),
      );
      expect(freshness.state, BorderMaterializationState.invalid);
      expect(freshness.reasons, contains(BorderStalenessReason.outputAltered));
      expect(_codes(report),
          contains('border.materialization.output_fingerprint_invalid'));

      final hugeRequest = _request(
        mapSize: GridSize(width: nonPortable, height: 2),
        feature: BorderFeature(
          id: 'feature',
          name: 'Feature',
          blueprintId: 'blueprint',
          seed: BorderSignedInt64.zero,
          geometry: BorderRegionGeometry(
            width: 3,
            height: 2,
            cells: const <bool>[true, true, false, false, true, false],
          ),
          overrides: const <BorderSlotOverride>[],
          keepOutRegions: const <BorderKeepOutRegion>[],
        ),
      );
      final hugeFreshness = assessBorderMaterializationFreshness(
        hugeRequest,
        materialization: _materialization(request),
        snapshotIntegrity: _integrity(),
      );
      expect(hugeFreshness.state, BorderMaterializationState.invalid);
    });
  });
}

List<String> _codes(BorderDiagnosticsReport report) =>
    <String>[for (final diagnostic in report.diagnostics) diagnostic.code];

ProjectManifest _project({bool includeSnapshot = true}) => ProjectManifest(
      name: 'Project',
      version: includeSnapshot ? ProjectVersion.v6 : ProjectVersion.v6,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      borderCatalog: includeSnapshot
          ? ProjectBorderCatalog(
              visualSnapshots: <BorderVisualSnapshot>[_snapshotAModel()],
            )
          : const ProjectBorderCatalog.empty(),
    );

BorderBlueprintRecord _record({
  bool published = true,
  List<BorderPrimitiveDraft> draftPrimitives = const <BorderPrimitiveDraft>[],
  BorderGroundDraft? draftGround,
  List<BorderPublishedPrimitive>? publishedPrimitives,
  BorderPublishedGround? publishedGround,
}) =>
    BorderBlueprintRecord(
      id: 'blueprint',
      draft: BorderBlueprintDraft(
        baseRevision: 0,
        definition: BorderBlueprintDraftDefinition(
          name: 'Draft',
          previewSeed: BorderSignedInt64.zero,
          template: BorderBlueprintTemplate.organicEdge,
          primitives: draftPrimitives,
          defaults: _params(),
          ground: draftGround,
          sortOrder: 0,
        ),
      ),
      latestPublished: published
          ? BorderBlueprintRevision(
              revision: 1,
              definition: BorderBlueprintPublishedDefinition(
                name: 'Published',
                previewSeed: BorderSignedInt64.zero,
                template: BorderBlueprintTemplate.organicEdge,
                primitives: publishedPrimitives ??
                    <BorderPublishedPrimitive>[_publishedPrimitive()],
                defaults: _params(),
                ground: publishedGround,
                sortOrder: 0,
              ),
            )
          : null,
    );

BorderPrimitiveDraft _draftPrimitive({
  String id = 'draft',
  String sourceElementId = 'source',
  BorderPixelPos anchor = const BorderPixelPos(x: 1, y: 1),
  BorderPrimitiveAssetMetrics? metrics,
}) =>
    BorderPrimitiveDraft(
      id: id,
      sourceElementId: sourceElementId,
      role: BorderPrimitiveRole.structureLarge,
      weight: 1,
      anchorPx: anchor,
      transforms: _transforms(),
      currentMetrics: metrics ?? _metrics(),
    );

BorderPublishedPrimitive _publishedPrimitive({
  String id = 'primitive',
  String snapshotId = _snapshotA,
  BorderPrimitiveAssetMetrics? metrics,
}) =>
    BorderPublishedPrimitive(
      id: id,
      sourceElementId: 'source',
      visualSnapshotId: snapshotId,
      role: BorderPrimitiveRole.structureLarge,
      weight: 1,
      anchorPx: const BorderPixelPos(x: 1, y: 1),
      transforms: _transforms(),
      publishedMetrics: metrics ?? _metrics(),
    );

BorderTransformPolicy _transforms() => BorderTransformPolicy(
      allowFlipX: false,
      allowedQuarterTurns: <int>[0],
    );

BorderPrimitiveAssetMetrics _metrics({
  String occupancy = 'border-rle-v1:4:1:4',
  BorderPixelPos defaultAnchor = const BorderPixelPos(x: 1, y: 1),
}) =>
    BorderPrimitiveAssetMetrics(
      assetFingerprint: 'asset',
      pixelSize: const GridSize(width: 2, height: 2),
      opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 2, height: 2),
      defaultAnchorPx: defaultAnchor,
      occupancyMaskRle: occupancy,
    );

BorderResolutionRequest _request({
  bool published = true,
  int revision = 1,
  BorderBlueprintTemplate template = BorderBlueprintTemplate.organicEdge,
  BorderFeature? feature,
  GridSize mapSize = const GridSize(width: 3, height: 2),
  String primitiveSnapshotId = _snapshotA,
  List<BorderVisualSnapshot>? snapshots,
}) =>
    BorderResolutionRequest(
      mapSize: mapSize,
      tileSizePx: const GridSize(width: 16, height: 16),
      blueprintId: 'blueprint',
      blueprintRevision: published
          ? BorderBlueprintRevision(
              revision: revision,
              definition: BorderBlueprintPublishedDefinition(
                name: 'Published',
                previewSeed: BorderSignedInt64.zero,
                template: template,
                primitives: <BorderPublishedPrimitive>[
                  _publishedPrimitive(snapshotId: primitiveSnapshotId),
                ],
                defaults: _params(),
                sortOrder: 0,
              ),
            )
          : null,
      feature: feature ??
          BorderFeature(
            id: 'feature',
            name: 'Feature',
            blueprintId: 'blueprint',
            seed: BorderSignedInt64.zero,
            geometry: _region(),
            overrides: const <BorderSlotOverride>[],
            keepOutRegions: const <BorderKeepOutRegion>[],
          ),
      visualSnapshots: snapshots ?? <BorderVisualSnapshot>[_snapshotAModel()],
      resolverVersion: 3,
    );

BorderRegionGeometry _region() => BorderRegionGeometry(
      width: 3,
      height: 2,
      cells: const <bool>[true, true, false, false, true, false],
    );

BorderGenerationParams _params() => BorderGenerationParams(
      irregularityPermille: 100,
      detailDensityPermille: 200,
      variationPermille: 300,
      maxOverlapPx: 1,
      gapTolerancePx: 1,
      depthRows: 1,
    );

BorderVisualSnapshot _snapshotAModel() => _snapshot(_hexA);
BorderVisualSnapshot _snapshotBModel() => _snapshot(_hexB);

BorderVisualSnapshot _snapshot(String hex) => BorderVisualSnapshot(
      id: 'border-snapshot-sha256:$hex',
      contentFingerprint: hex,
      frames: <BorderVisualFrameSnapshot>[
        BorderVisualFrameSnapshot(
          relativeAssetPath: 'assets/borders/snapshots/$hex.png',
          sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 2, height: 2),
          durationMs: 100,
        ),
      ],
    );

Map<String, BorderVisualSnapshotIntegrity> _integrity() =>
    <String, BorderVisualSnapshotIntegrity>{_snapshotA: _status()};

BorderVisualSnapshotIntegrity _status({
  String snapshotId = _snapshotA,
  bool metadataValid = true,
  bool filesPresent = true,
  bool contentFingerprintMatches = true,
}) =>
    BorderVisualSnapshotIntegrity(
      snapshotId: snapshotId,
      metadataValid: metadataValid,
      filesPresent: filesPresent,
      contentFingerprintMatches: contentFingerprintMatches,
    );

BorderMaterialization _materialization(
  BorderResolutionRequest request, {
  List<BorderResolvedGroundCell>? ground,
  List<BorderResolvedPlacement> placements = const <BorderResolvedPlacement>[],
}) {
  final resolvedGround = ground ?? <BorderResolvedGroundCell>[_ground(x: 0)];
  final components = computeBorderInputFingerprints(request);
  final revision = request.blueprintRevision!;
  return BorderMaterialization(
    receipt: BorderResolutionReceipt(
      resolverVersion: request.resolverVersion,
      blueprintRevision: revision.revision,
      components: components,
      inputFingerprint: computeBorderAggregateInputFingerprint(
        resolverVersion: request.resolverVersion,
        blueprintRevision: revision.revision,
        components: components,
      ),
      outputFingerprint: computeBorderOutputFingerprint(
        ground: resolvedGround,
        placements: placements,
      ),
    ),
    ground: resolvedGround,
    placements: placements,
  );
}

BorderMaterialization _materializationWithoutOutputHash(
  BorderResolutionRequest request, {
  required List<BorderResolvedPlacement> placements,
}) {
  final components = computeBorderInputFingerprints(request);
  return BorderMaterialization(
    receipt: BorderResolutionReceipt(
      resolverVersion: request.resolverVersion,
      blueprintRevision: request.blueprintRevision!.revision,
      components: components,
      inputFingerprint: computeBorderAggregateInputFingerprint(
        resolverVersion: request.resolverVersion,
        blueprintRevision: request.blueprintRevision!.revision,
        components: components,
      ),
      outputFingerprint: _validHash,
    ),
    ground: const <BorderResolvedGroundCell>[],
    placements: placements,
  );
}

BorderMaterialization _replaceReceipt(
  BorderMaterialization source, {
  String? inputFingerprint,
  String? outputFingerprint,
}) =>
    BorderMaterialization(
      receipt: BorderResolutionReceipt(
        resolverVersion: source.receipt.resolverVersion,
        blueprintRevision: source.receipt.blueprintRevision,
        components: source.receipt.components,
        inputFingerprint: inputFingerprint ?? source.receipt.inputFingerprint,
        outputFingerprint:
            outputFingerprint ?? source.receipt.outputFingerprint,
      ),
      ground: source.ground,
      placements: source.placements,
    );

BorderResolvedGroundCell _ground({
  required int x,
  String snapshotId = _snapshotA,
}) =>
    BorderResolvedGroundCell(
      x: x,
      y: 0,
      visualSnapshotId: snapshotId,
      resolvedRole: BorderGroundVariantRole.isolated,
    );

BorderResolvedPlacement _placement({
  String slotKey = 'slot',
  String primitiveId = 'primitive',
  String snapshotId = _snapshotA,
  GridPos anchor = const GridPos(x: 1, y: 0),
  int anchorRowMajor = 1,
  int topLeftX = 16,
  int opaqueX = 16,
}) =>
    BorderResolvedPlacement(
      id: 'placement-$slotKey',
      slotKey: slotKey,
      primitiveId: primitiveId,
      visualSnapshotId: snapshotId,
      anchorCell: anchor,
      topLeftWorldPx: BorderPixelPos(x: topLeftX, y: 0),
      opaqueWorldBoundsPx: BorderPixelRect(
        x: opaqueX,
        y: 0,
        width: 2,
        height: 2,
      ),
      transform: BorderSpriteTransform(quarterTurns: 0, flipX: false),
      drawBand: BorderDrawBand.structure,
      stableOrderKey: BorderStableOrderKey(
        drawBandIndex: borderDrawBandV1Index(BorderDrawBand.structure),
        anchorRowMajor: anchorRowMajor,
        passIndex: 0,
        rank: 0,
        ordinalLocal: 0,
        slotKey: slotKey,
      ),
    );
