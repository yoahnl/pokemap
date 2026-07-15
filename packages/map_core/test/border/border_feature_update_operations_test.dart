import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _hexA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _hexB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _snapshotA = 'border-snapshot-sha256:$_hexA';
const _snapshotB = 'border-snapshot-sha256:$_hexB';
const _wrongHash =
    'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

void main() {
  group('unit Border feature updates', () {
    test('all authored fields replace only their requested field', () {
      final fixture = _fixture();
      final original = fixture.feature;
      final geometry = BorderRegionGeometry(
        width: 3,
        height: 2,
        cells: const <bool>[false, true, true, false, false, true],
      );
      final seed = BorderSignedInt64.fromInt(99);
      final overrides = <BorderSlotOverride>[_override('new-slot')];
      final params = _params(depthRows: 4);
      final keepOutRegions = <BorderKeepOutRegion>[
        _keepOut('new-keep-out'),
      ];

      final cases = <(MapData, void Function(BorderFeature))>[
        (
          updateBorderFeatureGeometry(
            fixture.map,
            layerId: 'border',
            featureId: 'feature',
            geometry: geometry,
          ),
          (updated) {
            expect(updated.geometry, same(geometry));
            expect(updated.seed, original.seed);
            expect(updated.overrides, original.overrides);
          },
        ),
        (
          updateBorderFeatureSeed(
            fixture.map,
            layerId: 'border',
            featureId: 'feature',
            seed: seed,
          ),
          (updated) {
            expect(updated.seed, same(seed));
            expect(updated.geometry, original.geometry);
            expect(updated.overrides, original.overrides);
          },
        ),
        (
          updateBorderFeatureOverrides(
            fixture.map,
            layerId: 'border',
            featureId: 'feature',
            overrides: overrides,
          ),
          (updated) {
            expect(updated.overrides, overrides);
            expect(updated.geometry, original.geometry);
            expect(updated.seed, original.seed);
          },
        ),
        (
          updateBorderFeatureParameters(
            fixture.map,
            layerId: 'border',
            featureId: 'feature',
            paramsOverride: params,
          ),
          (updated) {
            expect(updated.paramsOverride, same(params));
            expect(updated.geometry, original.geometry);
            expect(updated.seed, original.seed);
          },
        ),
        (
          updateBorderFeatureKeepOutRegions(
            fixture.map,
            layerId: 'border',
            featureId: 'feature',
            keepOutRegions: keepOutRegions,
          ),
          (updated) {
            expect(updated.keepOutRegions, keepOutRegions);
            expect(updated.geometry, original.geometry);
            expect(updated.seed, original.seed);
          },
        ),
      ];

      for (final (map, verifyChanged) in cases) {
        final updated = _featureOf(map);
        verifyChanged(updated);
        expect(updated.id, original.id);
        expect(updated.name, original.name);
        expect(updated.blueprintId, original.blueprintId);
        if (!identical(updated.paramsOverride, params)) {
          expect(updated.paramsOverride, same(original.paramsOverride));
        }
        final changedKeepOut = updated.keepOutRegions.length == 1 &&
            updated.keepOutRegions.single.id == 'new-keep-out';
        if (!changedKeepOut) {
          expect(updated.keepOutRegions, original.keepOutRegions);
        }
        expect(updated.materialization, same(original.materialization));
        expect(map.layers[1], same(fixture.map.layers[1]));
        expect(_otherFeatureOf(map), same(fixture.otherFeature));
      }
    });

    test('parameter override can be explicitly cleared', () {
      final fixture = _fixture();

      final updated = updateBorderFeatureParameters(
        fixture.map,
        layerId: 'border',
        featureId: 'feature',
        paramsOverride: null,
      );

      expect(_featureOf(updated).paramsOverride, isNull);
      expect(_featureOf(fixture.map).paramsOverride, isNotNull);
    });

    test('invalid layer and feature targets throw without changing the map',
        () {
      final fixture = _fixture();
      for (final target in <(String, String)>[
        ('missing', 'feature'),
        ('collision', 'feature'),
        ('border', 'missing'),
      ]) {
        expect(
          () => updateBorderFeatureSeed(
            fixture.map,
            layerId: target.$1,
            featureId: target.$2,
            seed: BorderSignedInt64.zero,
          ),
          throwsA(isA<ValidationException>()),
        );
      }
      expect(_featureOf(fixture.map), same(fixture.feature));
    });
  });

  group('computeBorderFeatureEditFingerprint', () {
    test('is exact SHA-256 JCS and includes materialization', () {
      final fixture = _fixture();
      final expected =
          'sha256:${narrativeEventCanonicalSha256(<String, Object?>{
            'schema': 'border-feature-edit-v1',
            'feature': encodeBorderFeatureJson(fixture.feature),
          })}';
      final withoutMaterialization = _copyFeature(
        fixture.feature,
        materialization: null,
        replaceMaterialization: true,
      );

      expect(computeBorderFeatureEditFingerprint(fixture.feature), expected);
      expect(
        computeBorderFeatureEditFingerprint(withoutMaterialization),
        isNot(expected),
      );
    });
  });

  group('applyBorderFeaturePreview', () {
    test(
        'applies a canonical result atomically and only replaces proposed state',
        () {
      final fixture = _fixture();
      final proposedFeature = BorderFeature(
        id: 'feature',
        name: 'Proposed display name is ignored',
        blueprintId: 'blueprint',
        seed: BorderSignedInt64.fromInt(42),
        geometry: BorderRegionGeometry(
          width: 3,
          height: 2,
          cells: const <bool>[false, true, true, false, true, true],
        ),
        paramsOverride: _params(depthRows: 2),
        overrides: const <BorderSlotOverride>[],
        keepOutRegions: <BorderKeepOutRegion>[_keepOut('proposed-keep-out')],
        materialization: fixture.materialization,
      );
      final request = _request(feature: proposedFeature);
      expect(request.feature.materialization, isNull,
          reason: 'requests must strip any old materialization');
      final result = resolveBorderFeature(request);
      expect(result.canApply, isTrue);
      final newMaterialization = result.materialization!;

      final updated = applyBorderFeaturePreview(
        fixture.map,
        expectedMapId: fixture.map.id,
        layerId: 'border',
        featureId: 'feature',
        expectedBaseFeatureFingerprint:
            computeBorderFeatureEditFingerprint(fixture.feature),
        proposedRequest: request,
        proposedResult: result,
      );
      final applied = _featureOf(updated);

      expect(updated, isNot(same(fixture.map)));
      expect(applied.id, fixture.feature.id);
      expect(applied.name, fixture.feature.name);
      expect(applied.blueprintId, fixture.feature.blueprintId);
      expect(applied.seed, request.feature.seed);
      expect(applied.geometry, request.feature.geometry);
      expect(applied.paramsOverride, request.feature.paramsOverride);
      expect(applied.overrides, request.feature.overrides);
      expect(applied.keepOutRegions, request.feature.keepOutRegions);
      expect(applied.materialization, same(newMaterialization));
      expect(_otherFeatureOf(updated), same(fixture.otherFeature));
      expect(updated.layers[1], same(fixture.map.layers[1]));
      expect(_featureOf(fixture.map), same(fixture.feature),
          reason: 'the original immutable map remains untouched');
    });

    test('error result is an identity no-op before coherence checks', () {
      final fixture = _fixture();
      final result = BorderResolutionResult(
        materialization: null,
        diagnosticReport: BorderDiagnosticsReport(
          diagnostics: <BorderDiagnostic>[_error()],
        ),
      );

      final updated = applyBorderFeaturePreview(
        fixture.map,
        expectedMapId: 'wrong-map-is-irrelevant',
        layerId: 'missing',
        featureId: 'missing',
        expectedBaseFeatureFingerprint: 'invalid',
        proposedRequest: _request(),
        proposedResult: result,
      );

      expect(updated, same(fixture.map));
    });

    test('all optimistic conflicts are identity-preserving no-ops', () {
      final fixture = _fixture();
      final request = _request();
      final result = BorderResolutionResult(
        materialization: _materialization(request),
        diagnosticReport: const BorderDiagnosticsReport.empty(),
      );
      final baseFingerprint =
          computeBorderFeatureEditFingerprint(fixture.feature);
      final differentSizeRequest = _request(
        mapSize: const GridSize(width: 4, height: 2),
        feature: BorderFeature(
          id: 'feature',
          name: 'Feature',
          blueprintId: 'blueprint',
          seed: BorderSignedInt64.fromInt(7),
          geometry: BorderRegionGeometry(
            width: 4,
            height: 2,
            cells: const <bool>[
              true,
              true,
              false,
              false,
              false,
              true,
              false,
              false
            ],
          ),
          overrides: const <BorderSlotOverride>[],
          keepOutRegions: const <BorderKeepOutRegion>[],
        ),
      );
      final differentSizeResult = BorderResolutionResult(
        materialization: _materialization(differentSizeRequest),
        diagnosticReport: const BorderDiagnosticsReport.empty(),
      );
      final cases = <MapData Function()>[
        () => applyBorderFeaturePreview(
              fixture.map,
              expectedMapId: 'wrong',
              layerId: 'border',
              featureId: 'feature',
              expectedBaseFeatureFingerprint: baseFingerprint,
              proposedRequest: request,
              proposedResult: result,
            ),
        () => applyBorderFeaturePreview(
              fixture.map,
              expectedMapId: fixture.map.id,
              layerId: 'missing',
              featureId: 'feature',
              expectedBaseFeatureFingerprint: baseFingerprint,
              proposedRequest: request,
              proposedResult: result,
            ),
        () => applyBorderFeaturePreview(
              fixture.map,
              expectedMapId: fixture.map.id,
              layerId: 'collision',
              featureId: 'feature',
              expectedBaseFeatureFingerprint: baseFingerprint,
              proposedRequest: request,
              proposedResult: result,
            ),
        () => applyBorderFeaturePreview(
              fixture.map,
              expectedMapId: fixture.map.id,
              layerId: 'border',
              featureId: 'missing',
              expectedBaseFeatureFingerprint: baseFingerprint,
              proposedRequest: request,
              proposedResult: result,
            ),
        () => applyBorderFeaturePreview(
              fixture.map,
              expectedMapId: fixture.map.id,
              layerId: 'border',
              featureId: 'feature',
              expectedBaseFeatureFingerprint: _wrongHash,
              proposedRequest: request,
              proposedResult: result,
            ),
        () => applyBorderFeaturePreview(
              fixture.map,
              expectedMapId: fixture.map.id,
              layerId: 'border',
              featureId: 'feature',
              expectedBaseFeatureFingerprint: baseFingerprint,
              proposedRequest: differentSizeRequest,
              proposedResult: differentSizeResult,
            ),
      ];

      for (final apply in cases) {
        expect(apply(), same(fixture.map));
      }
    });

    test('mismatched proposed feature identity or blueprint is a no-op', () {
      final fixture = _fixture();
      final fingerprint = computeBorderFeatureEditFingerprint(fixture.feature);
      for (final proposedFeature in <BorderFeature>[
        _plainFeature(id: 'other'),
        _plainFeature(blueprintId: 'other-blueprint'),
      ]) {
        final request = _request(
          feature: proposedFeature,
          blueprintId: proposedFeature.blueprintId,
        );
        final result = BorderResolutionResult(
          materialization: _materialization(request),
          diagnosticReport: const BorderDiagnosticsReport.empty(),
        );
        expect(
          applyBorderFeaturePreview(
            fixture.map,
            expectedMapId: fixture.map.id,
            layerId: 'border',
            featureId: 'feature',
            expectedBaseFeatureFingerprint: fingerprint,
            proposedRequest: request,
            proposedResult: result,
          ),
          same(fixture.map),
        );
      }
    });

    test('rejects every incoherent exact receipt component', () {
      final fixture = _fixture();
      final request = _request();
      final valid = _materialization(request);
      final wrongComponents = BorderInputFingerprints(
        blueprint: _wrongHash,
        geometryAndSeed: valid.receipt.components.geometryAndSeed,
        parameters: valid.receipt.components.parameters,
        overrides: valid.receipt.components.overrides,
        keepOutRegions: valid.receipt.components.keepOutRegions,
        mapContext: valid.receipt.components.mapContext,
        visualSnapshots: valid.receipt.components.visualSnapshots,
      );
      final cases = <BorderMaterialization>[
        _replaceReceipt(valid, resolverVersion: 99),
        _replaceReceipt(valid, blueprintRevision: 99),
        _replaceReceipt(valid, components: wrongComponents),
        _replaceReceipt(valid, inputFingerprint: _wrongHash),
        _replaceReceipt(valid, outputFingerprint: _wrongHash),
      ];

      for (final materialization in cases) {
        final result = BorderResolutionResult(
          materialization: materialization,
          diagnosticReport: const BorderDiagnosticsReport.empty(),
        );
        expect(
          () => applyBorderFeaturePreview(
            fixture.map,
            expectedMapId: fixture.map.id,
            layerId: 'border',
            featureId: 'feature',
            expectedBaseFeatureFingerprint:
                computeBorderFeatureEditFingerprint(fixture.feature),
            proposedRequest: request,
            proposedResult: result,
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('successful preview without a published revision is incoherent', () {
      final fixture = _fixture();
      final requestWithRevision = _request();
      final result = BorderResolutionResult(
        materialization: _materialization(requestWithRevision),
        diagnosticReport: const BorderDiagnosticsReport.empty(),
      );
      final requestWithoutRevision = _request(published: false);

      expect(
        () => applyBorderFeaturePreview(
          fixture.map,
          expectedMapId: fixture.map.id,
          layerId: 'border',
          featureId: 'feature',
          expectedBaseFeatureFingerprint:
              computeBorderFeatureEditFingerprint(fixture.feature),
          proposedRequest: requestWithoutRevision,
          proposedResult: result,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test(
        'rejects rehashed output with invalid structure or an unavailable snapshot',
        () {
      final fixture = _fixture();
      final request = _request();
      final cases = <BorderMaterialization>[
        _materialization(
          request,
          ground: <BorderResolvedGroundCell>[_ground(x: 99)],
        ),
        _materialization(
          request,
          placements: <BorderResolvedPlacement>[
            _placement(
              anchor: const GridPos(x: 99, y: 0),
              anchorRowMajor: 99,
            ),
          ],
        ),
        _materialization(
          request,
          placements: <BorderResolvedPlacement>[
            _placement(opaqueX: 500),
          ],
        ),
        _materialization(
          request,
          placements: <BorderResolvedPlacement>[
            _placement(anchorRowMajor: 0),
          ],
        ),
        _materialization(
          request,
          ground: <BorderResolvedGroundCell>[
            _ground(snapshotId: _snapshotB),
          ],
        ),
      ];

      for (final materialization in cases) {
        expect(
          () => applyBorderFeaturePreview(
            fixture.map,
            expectedMapId: fixture.map.id,
            layerId: 'border',
            featureId: 'feature',
            expectedBaseFeatureFingerprint:
                computeBorderFeatureEditFingerprint(fixture.feature),
            proposedRequest: request,
            proposedResult: BorderResolutionResult(
              materialization: materialization,
              diagnosticReport: const BorderDiagnosticsReport.empty(),
            ),
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('non-portable current feature fingerprint is a conflict no-op', () {
      final fixture = _fixture();
      final request = _request();
      final alteredMaterialization = BorderMaterialization(
        receipt: fixture.materialization.receipt,
        ground: fixture.materialization.ground,
        placements: <BorderResolvedPlacement>[
          _placement(topLeftX: int.parse('9007199254740993')),
        ],
      );
      final unportableFeature = _copyFeature(
        fixture.feature,
        materialization: alteredMaterialization,
        replaceMaterialization: true,
      );
      final borderLayer = fixture.map.layers.first as BorderLayer;
      final conflictedMap = fixture.map.copyWith(
        layers: <MapLayer>[
          borderLayer.copyWith(
            content: BorderLayerContent(
              formatVersion: borderLayer.content.formatVersion,
              features: <BorderFeature>[
                unportableFeature,
                fixture.otherFeature,
              ],
            ),
          ),
          fixture.map.layers[1],
        ],
      );
      final result = BorderResolutionResult(
        materialization: _materialization(request),
        diagnosticReport: const BorderDiagnosticsReport.empty(),
      );

      expect(
        applyBorderFeaturePreview(
          conflictedMap,
          expectedMapId: conflictedMap.id,
          layerId: 'border',
          featureId: 'feature',
          expectedBaseFeatureFingerprint: _wrongHash,
          proposedRequest: request,
          proposedResult: result,
        ),
        same(conflictedMap),
      );
    });

    test('edit fingerprint enforces the recursive portable integer domain', () {
      final fixture = _fixture();

      BorderFeature featureWithTopLeft(int value) {
        final alteredMaterialization = BorderMaterialization(
          receipt: fixture.materialization.receipt,
          ground: fixture.materialization.ground,
          placements: <BorderResolvedPlacement>[
            _placement(topLeftX: value),
          ],
        );
        return _copyFeature(
          fixture.feature,
          materialization: alteredMaterialization,
          replaceMaterialization: true,
        );
      }

      for (final portable in <int>[
        int.parse('9007199254740991'),
        int.parse('-9007199254740991'),
      ]) {
        expect(
          computeBorderFeatureEditFingerprint(featureWithTopLeft(portable)),
          startsWith('sha256:'),
        );
      }
      for (final nonPortable in <int>[
        int.parse('9007199254740992'),
        int.parse('-9007199254740992'),
      ]) {
        expect(
          () => computeBorderFeatureEditFingerprint(
            featureWithTopLeft(nonPortable),
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    });
  });
}

({
  MapData map,
  BorderFeature feature,
  BorderFeature otherFeature,
  BorderMaterialization materialization,
}) _fixture() {
  final initialRequest = _request();
  final materialization = _materialization(initialRequest);
  final feature = _copyFeature(
    initialRequest.feature,
    materialization: materialization,
    replaceMaterialization: true,
  );
  final otherFeature = _plainFeature(id: 'other-feature');
  return (
    map: MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 3, height: 2),
      version: ProjectVersion.v2,
      layers: <MapLayer>[
        MapLayer.border(
          id: 'border',
          name: 'Border',
          content: BorderLayerContent(
            features: <BorderFeature>[feature, otherFeature],
          ),
        ),
        const MapLayer.collision(
          id: 'collision',
          name: 'Collision',
          collisions: <bool>[true, false, false, true, false, false],
        ),
      ],
    ),
    feature: feature,
    otherFeature: otherFeature,
    materialization: materialization,
  );
}

BorderResolutionRequest _request({
  BorderFeature? feature,
  GridSize mapSize = const GridSize(width: 3, height: 2),
  String blueprintId = 'blueprint',
  bool published = true,
}) {
  final effectiveFeature = feature ?? _plainFeature();
  return BorderResolutionRequest(
    mapSize: mapSize,
    tileSizePx: const GridSize(width: 16, height: 16),
    blueprintId: blueprintId,
    blueprintRevision: published
        ? BorderBlueprintRevision(
            revision: 1,
            definition: BorderBlueprintPublishedDefinition(
              name: 'Blueprint',
              previewSeed: BorderSignedInt64.zero,
              template: BorderBlueprintTemplate.organicEdge,
              primitives: <BorderPublishedPrimitive>[_primitive()],
              defaults: _params(),
              sortOrder: 0,
            ),
          )
        : null,
    feature: effectiveFeature,
    visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
    resolverVersion: 3,
  );
}

BorderFeature _plainFeature({
  String id = 'feature',
  String blueprintId = 'blueprint',
}) =>
    BorderFeature(
      id: id,
      name: 'Feature $id',
      blueprintId: blueprintId,
      seed: BorderSignedInt64.fromInt(7),
      geometry: BorderRegionGeometry(
        width: 3,
        height: 2,
        cells: const <bool>[true, true, false, false, true, false],
      ),
      paramsOverride: _params(),
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
    );

BorderFeature _copyFeature(
  BorderFeature source, {
  BorderMaterialization? materialization,
  bool replaceMaterialization = false,
}) =>
    BorderFeature(
      id: source.id,
      name: source.name,
      blueprintId: source.blueprintId,
      seed: source.seed,
      geometry: source.geometry,
      paramsOverride: source.paramsOverride,
      overrides: source.overrides,
      keepOutRegions: source.keepOutRegions,
      materialization:
          replaceMaterialization ? materialization : source.materialization,
    );

BorderFeature _featureOf(MapData map) =>
    (map.layers.first as BorderLayer).content.featureById('feature')!;

BorderFeature _otherFeatureOf(MapData map) =>
    (map.layers.first as BorderLayer).content.featureById('other-feature')!;

BorderGenerationParams _params({int depthRows = 1}) => BorderGenerationParams(
      irregularityPermille: 100,
      detailDensityPermille: 200,
      variationPermille: 300,
      maxOverlapPx: 1,
      gapTolerancePx: 1,
      depthRows: depthRows,
    );

BorderPublishedPrimitive _primitive() => BorderPublishedPrimitive(
      id: 'primitive',
      sourceElementId: 'source',
      visualSnapshotId: _snapshotA,
      role: BorderPrimitiveRole.structureLarge,
      weight: 1,
      anchorPx: const BorderPixelPos(x: 8, y: 8),
      transforms: BorderTransformPolicy(
        allowFlipX: false,
        allowedQuarterTurns: <int>[0, 1, 2, 3],
      ),
      publishedMetrics: BorderPrimitiveAssetMetrics(
        assetFingerprint: 'asset',
        pixelSize: const GridSize(width: 16, height: 16),
        opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
        defaultAnchorPx: const BorderPixelPos(x: 8, y: 8),
        occupancyMaskRle: encodeBorderRleMask(List<bool>.filled(16 * 16, true)),
      ),
    );

BorderVisualSnapshot _snapshot() => BorderVisualSnapshot(
      id: _snapshotA,
      contentFingerprint: _hexA,
      frames: <BorderVisualFrameSnapshot>[
        BorderVisualFrameSnapshot(
          relativeAssetPath: 'assets/borders/snapshots/a.png',
          sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
          durationMs: 100,
        ),
      ],
    );

BorderSlotOverride _override(String slotKey) => BorderSlotOverride(
      slotKey: slotKey,
      variationSalt: BorderSignedInt64.zero,
      suppressed: false,
      locked: false,
      replacementPrimitiveId: 'primitive',
    );

BorderKeepOutRegion _keepOut(String id) => BorderKeepOutRegion(
      id: id,
      region: BorderRegionGeometry(
        width: 3,
        height: 2,
        cells: const <bool>[false, false, false, false, false, false],
      ),
    );

BorderMaterialization _materialization(
  BorderResolutionRequest request, {
  int groundX = 0,
  List<BorderResolvedGroundCell>? ground,
  List<BorderResolvedPlacement> placements = const <BorderResolvedPlacement>[],
}) {
  final resolvedGround =
      ground ?? <BorderResolvedGroundCell>[_ground(x: groundX)];
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

BorderResolvedGroundCell _ground({
  int x = 0,
  String snapshotId = _snapshotA,
}) =>
    BorderResolvedGroundCell(
      x: x,
      y: 0,
      visualSnapshotId: snapshotId,
      resolvedRole: SurfaceVariantRole.isolated,
    );

BorderResolvedPlacement _placement({
  GridPos anchor = const GridPos(x: 1, y: 0),
  int anchorRowMajor = 1,
  int opaqueX = 16,
  int topLeftX = 16,
}) =>
    BorderResolvedPlacement(
      id: 'placement',
      slotKey: 'slot',
      primitiveId: 'primitive',
      visualSnapshotId: _snapshotA,
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
        slotKey: 'slot',
      ),
    );

BorderMaterialization _replaceReceipt(
  BorderMaterialization source, {
  int? resolverVersion,
  int? blueprintRevision,
  BorderInputFingerprints? components,
  String? inputFingerprint,
  String? outputFingerprint,
}) =>
    BorderMaterialization(
      receipt: BorderResolutionReceipt(
        resolverVersion: resolverVersion ?? source.receipt.resolverVersion,
        blueprintRevision:
            blueprintRevision ?? source.receipt.blueprintRevision,
        components: components ?? source.receipt.components,
        inputFingerprint: inputFingerprint ?? source.receipt.inputFingerprint,
        outputFingerprint:
            outputFingerprint ?? source.receipt.outputFingerprint,
      ),
      ground: source.ground,
      placements: source.placements,
    );

BorderDiagnostic _error() => BorderDiagnostic(
      code: 'border.test.error',
      severity: BorderDiagnosticSeverity.error,
      phase: BorderDiagnosticPhase.resolution,
      scope: BorderDiagnosticScope.feature,
      suggestedAction: 'border.action.fix',
    );
