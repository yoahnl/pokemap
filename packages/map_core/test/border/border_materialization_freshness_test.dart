import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _hexA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _hexB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _snapshotA = 'border-snapshot-sha256:$_hexA';
const _snapshotB = 'border-snapshot-sha256:$_hexB';
const _wrongHash =
    'sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';

void main() {
  group('assessBorderMaterializationFreshness', () {
    test('inclusive grid-edge boundary remains fresh and regenerable', () {
      final request = _request(
        template: BorderBlueprintTemplate.stoneChainLine,
        geometry: BorderStrokeGeometry(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'bottom-edge',
              points: const <GridPos>[
                GridPos(x: 2, y: 2),
                GridPos(x: 3, y: 2),
              ],
              closed: false,
            ),
          ],
          alignment: BorderStrokeAlignment.gridEdges,
        ),
      );

      final result = assessBorderMaterializationFreshness(
        request,
        materialization: _materialization(request),
        snapshotIntegrity: _integrity(),
      );

      expect(result.state, BorderMaterializationState.fresh);
      expect(result.reasons, isEmpty);
      expect(result.canRegenerate, isTrue);
    });

    test('alignment change is stale and incompatible with stone-chain', () {
      final stroke = BorderStroke(
        id: 'edge',
        points: const <GridPos>[
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
        ],
        closed: false,
      );
      final base = _request(
        template: BorderBlueprintTemplate.stoneChainLine,
        geometry: BorderStrokeGeometry(
          strokes: <BorderStroke>[stroke],
          alignment: BorderStrokeAlignment.gridEdges,
        ),
      );
      final changed = _request(
        template: BorderBlueprintTemplate.stoneChainLine,
        geometry: BorderStrokeGeometry(strokes: <BorderStroke>[stroke]),
      );

      final result = assessBorderMaterializationFreshness(
        changed,
        materialization: _materialization(base),
        snapshotIntegrity: _integrity(),
      );

      expect(result.state, BorderMaterializationState.stale);
      expect(result.reasons,
          <BorderStalenessReason>{BorderStalenessReason.geometryOrSeedChanged});
      expect(result.canRegenerate, isFalse);
    });

    test('null is unmaterialized, nonrenderable, and regenerable when valid',
        () {
      final result = assessBorderMaterializationFreshness(
        _request(),
        materialization: null,
        snapshotIntegrity: _integrity(),
      );

      expect(result.state, BorderMaterializationState.unmaterialized);
      expect(result.reasons, isEmpty);
      expect(result.isRenderable, isFalse);
      expect(result.canRegenerate, isTrue);
    });

    test('an exact receipt and output are fresh and renderable', () {
      final request = _request();
      final result = assessBorderMaterializationFreshness(
        request,
        materialization: _materialization(request),
        snapshotIntegrity: _integrity(),
      );

      expect(result.state, BorderMaterializationState.fresh);
      expect(result.reasons, isEmpty);
      expect(result.isRenderable, isTrue);
      expect(result.canRegenerate, isTrue);
    });

    test('derives every non-invalidating component reason', () {
      final base = _request();
      final materialization = _materialization(base);
      final cases = <(BorderResolutionRequest, BorderStalenessReason)>[
        (
          _request(revision: 2),
          BorderStalenessReason.blueprintNewer,
        ),
        (
          _request(published: false),
          BorderStalenessReason.blueprintMissing,
        ),
        (
          _request(seed: BorderSignedInt64.fromInt(99)),
          BorderStalenessReason.geometryOrSeedChanged,
        ),
        (
          _request(paramsOverride: _params(depthRows: 2)),
          BorderStalenessReason.parametersChanged,
        ),
        (
          _request(overrides: <BorderSlotOverride>[_override()]),
          BorderStalenessReason.overridesChanged,
        ),
        (
          _request(keepOutRegions: <BorderKeepOutRegion>[_keepOut()]),
          BorderStalenessReason.keepOutRegionsChanged,
        ),
        (
          _request(tileSize: const GridSize(width: 17, height: 16)),
          BorderStalenessReason.mapContextChanged,
        ),
        (
          _request(resolverVersion: 4),
          BorderStalenessReason.resolverNewer,
        ),
      ];

      for (final (request, reason) in cases) {
        final result = assessBorderMaterializationFreshness(
          request,
          materialization: materialization,
          snapshotIntegrity: _integrity(),
        );
        expect(result.state, BorderMaterializationState.stale,
            reason: '$reason');
        expect(result.reasons, <BorderStalenessReason>{reason});
        expect(result.isRenderable, isTrue);
      }
    });

    test('returns multiple reasons in explicit V1 order', () {
      final base = _request();
      final result = assessBorderMaterializationFreshness(
        _request(
          revision: 2,
          seed: BorderSignedInt64.fromInt(99),
          paramsOverride: _params(depthRows: 3),
          resolverVersion: 4,
        ),
        materialization: _materialization(base),
        snapshotIntegrity: _integrity(),
      );

      expect(
        result.reasons.toList(),
        <BorderStalenessReason>[
          BorderStalenessReason.blueprintNewer,
          BorderStalenessReason.geometryOrSeedChanged,
          BorderStalenessReason.parametersChanged,
          BorderStalenessReason.resolverNewer,
        ],
      );
      expect(borderStalenessReasonV1Order.last,
          BorderStalenessReason.outputAltered);
    });

    test('missing blueprint preserves valid old output but cannot regenerate',
        () {
      final base = _request();
      final result = assessBorderMaterializationFreshness(
        _request(published: false),
        materialization: _materialization(base),
        snapshotIntegrity: _integrity(),
      );

      expect(result.state, BorderMaterializationState.stale);
      expect(result.reasons,
          <BorderStalenessReason>{BorderStalenessReason.blueprintMissing});
      expect(result.isRenderable, isTrue);
      expect(result.canRegenerate, isFalse);
    });

    test('output alteration has invalid precedence over stale reasons', () {
      final base = _request();
      final original = _materialization(base);
      final altered = BorderMaterialization(
        receipt: original.receipt,
        ground: <BorderResolvedGroundCell>[
          _ground(x: 1, snapshotId: _snapshotA),
        ],
        placements: const <BorderResolvedPlacement>[],
      );
      final result = assessBorderMaterializationFreshness(
        _request(seed: BorderSignedInt64.fromInt(99)),
        materialization: altered,
        snapshotIntegrity: _integrity(),
      );

      expect(result.state, BorderMaterializationState.invalid);
      expect(
        result.reasons.toList(),
        <BorderStalenessReason>[
          BorderStalenessReason.geometryOrSeedChanged,
          BorderStalenessReason.outputAltered,
        ],
      );
      expect(result.isRenderable, isFalse);
    });

    test('each caller-supplied snapshot integrity flag invalidates output', () {
      final request = _request();
      final materialization = _materialization(request);
      final cases = <BorderVisualSnapshotIntegrity>[
        _status(metadataValid: false),
        _status(filesPresent: false),
        _status(contentFingerprintMatches: false),
      ];

      for (final status in cases) {
        final result = assessBorderMaterializationFreshness(
          request,
          materialization: materialization,
          snapshotIntegrity: <String, BorderVisualSnapshotIntegrity>{
            _snapshotA: status,
          },
        );
        expect(result.state, BorderMaterializationState.invalid);
        expect(
          result.reasons,
          contains(BorderStalenessReason.visualSnapshotMissingOrCorrupt),
        );
        expect(result.isRenderable, isFalse);
      }
    });

    test(
        'missing snapshot model or mismatched integrity key invalidates output',
        () {
      final base = _request();
      final materialization = _materialization(base);
      final missingModel =
          _request(snapshots: <BorderVisualSnapshot>[_snapshotBModel()]);
      final wrongStatus = BorderVisualSnapshotIntegrity(
        snapshotId: _snapshotB,
        metadataValid: true,
        filesPresent: true,
        contentFingerprintMatches: true,
      );

      for (final requestAndIntegrity in <(
        BorderResolutionRequest,
        Map<String, BorderVisualSnapshotIntegrity>
      )>[
        (missingModel, _integrity()),
        (
          base,
          <String, BorderVisualSnapshotIntegrity>{_snapshotA: wrongStatus}
        ),
      ]) {
        final result = assessBorderMaterializationFreshness(
          requestAndIntegrity.$1,
          materialization: materialization,
          snapshotIntegrity: requestAndIntegrity.$2,
        );
        expect(result.state, BorderMaterializationState.invalid);
        expect(result.reasons,
            contains(BorderStalenessReason.visualSnapshotMissingOrCorrupt));
      }
    });

    test(
        'a corrupt snapshot referenced only by a newer blueprint affects only regeneration',
        () {
      final oldRequest = _request(revision: 1);
      final newRequest = _request(
        revision: 2,
        primitiveSnapshotId: _snapshotB,
        snapshots: <BorderVisualSnapshot>[_snapshotAModel(), _snapshotBModel()],
      );
      final result = assessBorderMaterializationFreshness(
        newRequest,
        materialization: _materialization(oldRequest),
        snapshotIntegrity: <String, BorderVisualSnapshotIntegrity>{
          _snapshotA: _status(),
          _snapshotB: _status(
            snapshotId: _snapshotB,
            contentFingerprintMatches: false,
          ),
        },
      );

      expect(result.state, BorderMaterializationState.stale);
      expect(result.reasons, <BorderStalenessReason>{
        BorderStalenessReason.blueprintNewer,
        BorderStalenessReason.visualSnapshotMissingOrCorrupt,
      });
      expect(result.isRenderable, isTrue);
      expect(result.canRegenerate, isFalse);
    });

    test(
        'same-revision corrupt primitive snapshot unused by output is stale and renderable',
        () {
      final request = _request(
        extraPrimitiveSnapshotId: _snapshotB,
        snapshots: <BorderVisualSnapshot>[_snapshotAModel(), _snapshotBModel()],
      );
      final materialization = _materialization(
        request,
        ground: const <BorderResolvedGroundCell>[],
        placements: <BorderResolvedPlacement>[_placement()],
      );

      for (final integrity in <Map<String, BorderVisualSnapshotIntegrity>>[
        <String, BorderVisualSnapshotIntegrity>{
          _snapshotA: _status(),
          _snapshotB: _status(
            snapshotId: _snapshotB,
            contentFingerprintMatches: false,
          ),
        },
        <String, BorderVisualSnapshotIntegrity>{_snapshotA: _status()},
      ]) {
        final result = assessBorderMaterializationFreshness(
          request,
          materialization: materialization,
          snapshotIntegrity: integrity,
        );

        expect(result.state, BorderMaterializationState.stale);
        expect(result.reasons, <BorderStalenessReason>{
          BorderStalenessReason.visualSnapshotMissingOrCorrupt,
        });
        expect(result.isRenderable, isTrue);
        expect(result.canRegenerate, isFalse);
      }
    });

    test(
        'same-revision missing primitive snapshot model unused by output stays renderable',
        () {
      final receiptRequest = _request(
        extraPrimitiveSnapshotId: _snapshotB,
        snapshots: <BorderVisualSnapshot>[_snapshotAModel(), _snapshotBModel()],
      );
      final currentRequest = _request(
        extraPrimitiveSnapshotId: _snapshotB,
        snapshots: <BorderVisualSnapshot>[_snapshotAModel()],
      );

      final result = assessBorderMaterializationFreshness(
        currentRequest,
        materialization: _materialization(
          receiptRequest,
          ground: const <BorderResolvedGroundCell>[],
          placements: <BorderResolvedPlacement>[_placement()],
        ),
        snapshotIntegrity: _integrity(),
      );

      expect(result.state, BorderMaterializationState.stale);
      expect(result.reasons, <BorderStalenessReason>{
        BorderStalenessReason.visualSnapshotMissingOrCorrupt,
      });
      expect(result.isRenderable, isTrue);
      expect(result.canRegenerate, isFalse);
    });

    test(
        'same-revision corrupt published-ground snapshot unused by output stays renderable',
        () {
      final request = _request(
        groundSnapshotId: _snapshotB,
        snapshots: <BorderVisualSnapshot>[_snapshotAModel(), _snapshotBModel()],
      );
      final result = assessBorderMaterializationFreshness(
        request,
        materialization: _materialization(
          request,
          ground: <BorderResolvedGroundCell>[_ground(x: 0)],
        ),
        snapshotIntegrity: <String, BorderVisualSnapshotIntegrity>{
          _snapshotA: _status(),
          _snapshotB: _status(snapshotId: _snapshotB, filesPresent: false),
        },
      );

      expect(result.state, BorderMaterializationState.stale);
      expect(result.reasons, <BorderStalenessReason>{
        BorderStalenessReason.visualSnapshotMissingOrCorrupt,
      });
      expect(result.isRenderable, isTrue);
      expect(result.canRegenerate, isFalse);
    });

    test(
        'newer non-fingerprintable blueprint leaves valid old output renderable',
        () {
      final oldRequest = _request(revision: 1);
      final currentRequest = _request(
        revision: 2,
        extraPrimitiveId: 'primitive',
        extraPrimitiveSnapshotId: _snapshotA,
      );

      final result = assessBorderMaterializationFreshness(
        currentRequest,
        materialization: _materialization(oldRequest),
        snapshotIntegrity: _integrity(),
      );

      expect(result.state, BorderMaterializationState.stale);
      expect(result.reasons, <BorderStalenessReason>{
        BorderStalenessReason.blueprintNewer,
      });
      expect(result.isRenderable, isTrue);
      expect(result.canRegenerate, isFalse);
    });

    test(
        'an unused corrupt catalogue snapshot changes neither output nor regeneration',
        () {
      final request = _request(
        snapshots: <BorderVisualSnapshot>[_snapshotAModel(), _snapshotBModel()],
      );
      final result = assessBorderMaterializationFreshness(
        request,
        materialization: _materialization(request),
        snapshotIntegrity: <String, BorderVisualSnapshotIntegrity>{
          _snapshotA: _status(),
          _snapshotB: _status(
            snapshotId: _snapshotB,
            filesPresent: false,
          ),
        },
      );

      expect(result.state, BorderMaterializationState.fresh);
      expect(result.canRegenerate, isTrue);
    });

    test('forged receipt aggregate is invalid without inventing a reason', () {
      final request = _request();
      final valid = _materialization(request);
      final forged = _replaceReceipt(
        valid,
        inputFingerprint: _wrongHash,
      );
      final result = assessBorderMaterializationFreshness(
        request,
        materialization: forged,
        snapshotIntegrity: _integrity(),
      );

      expect(result.state, BorderMaterializationState.invalid);
      expect(result.reasons, isEmpty);
      expect(result.isRenderable, isFalse);
    });

    test(
        'lower revision, lower resolver, and same-revision blueprint mismatch are invalid',
        () {
      final receiptRequest = _request(revision: 2, resolverVersion: 3);
      final materialization = _materialization(receiptRequest);
      final cases = <BorderResolutionRequest>[
        _request(revision: 1, resolverVersion: 3),
        _request(revision: 2, resolverVersion: 2),
        _request(revision: 2, resolverVersion: 3, primitiveWeight: 2),
      ];

      for (final request in cases) {
        final result = assessBorderMaterializationFreshness(
          request,
          materialization: materialization,
          snapshotIntegrity: _integrity(),
        );
        expect(result.state, BorderMaterializationState.invalid);
        expect(result.isRenderable, isFalse);
      }
    });

    test('structural bounds and anchor-row-major violations are invalid', () {
      final request = _request();
      final cases = <BorderMaterialization>[
        _materialization(
          request,
          ground: <BorderResolvedGroundCell>[
            _ground(x: 99, snapshotId: _snapshotA),
          ],
        ),
        _materialization(
          request,
          placements: <BorderResolvedPlacement>[
            _placement(anchor: const GridPos(x: 1, y: 0), anchorRowMajor: 0),
          ],
        ),
        _materialization(
          request,
          placements: <BorderResolvedPlacement>[
            _placement(
              anchor: const GridPos(x: 1, y: 0),
              opaqueX: 500,
            ),
          ],
        ),
      ];

      for (final materialization in cases) {
        final result = assessBorderMaterializationFreshness(
          request,
          materialization: materialization,
          snapshotIntegrity: _integrity(),
        );
        expect(result.state, BorderMaterializationState.invalid);
        expect(result.reasons, isEmpty);
      }
    });

    test('invalid geometry and dangling override prevent regeneration', () {
      final empty = _request(
        geometry: BorderRegionGeometry(
          width: 3,
          height: 2,
          cells: List<bool>.filled(6, false),
        ),
      );
      final dangling = _request(
        overrides: <BorderSlotOverride>[
          BorderSlotOverride(
            slotKey: 'slot',
            variationSalt: BorderSignedInt64.zero,
            suppressed: false,
            locked: false,
            replacementPrimitiveId: 'missing',
          ),
        ],
      );

      for (final request in <BorderResolutionRequest>[empty, dangling]) {
        final result = assessBorderMaterializationFreshness(
          request,
          materialization: null,
          snapshotIntegrity: _integrity(),
        );
        expect(result.state, BorderMaterializationState.unmaterialized);
        expect(result.canRegenerate, isFalse);
      }
    });

    test('oversized in-memory RLE metrics cannot regenerate', () {
      final request = _request(
        primitiveMetrics: BorderPrimitiveAssetMetrics(
          assetFingerprint: 'oversized',
          pixelSize: const GridSize(width: 8193, height: 1),
          opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
          defaultAnchorPx: const BorderPixelPos(x: 0, y: 0),
          occupancyMaskRle: 'border-rle-v1:8193:1:8193',
        ),
      );

      final result = assessBorderMaterializationFreshness(
        request,
        materialization: null,
        snapshotIntegrity: _integrity(),
      );

      expect(result.state, BorderMaterializationState.unmaterialized);
      expect(result.canRegenerate, isFalse);
    });

    test(
        'corrupt snapshot referenced by a locked override prevents regeneration',
        () {
      final locked = BorderSlotOverride(
        slotKey: 'slot',
        variationSalt: BorderSignedInt64.zero,
        suppressed: false,
        locked: true,
        lockedPlacement: _placement(
          snapshotId: _snapshotB,
          primitiveId: 'primitive',
        ),
      );
      final request = _request(
        overrides: <BorderSlotOverride>[locked],
        snapshots: <BorderVisualSnapshot>[_snapshotAModel(), _snapshotBModel()],
      );
      final result = assessBorderMaterializationFreshness(
        request,
        materialization: null,
        snapshotIntegrity: <String, BorderVisualSnapshotIntegrity>{
          _snapshotA: _status(),
          _snapshotB: _status(
            snapshotId: _snapshotB,
            metadataValid: false,
          ),
        },
      );

      expect(result.state, BorderMaterializationState.unmaterialized);
      expect(result.canRegenerate, isFalse);
    });

    test(
        'locked override snapshot must be the snapshot published for its primitive',
        () {
      final locked = BorderSlotOverride(
        slotKey: 'slot',
        variationSalt: BorderSignedInt64.zero,
        suppressed: false,
        locked: true,
        lockedPlacement: _placement(
          snapshotId: _snapshotB,
          primitiveId: 'primitive',
        ),
      );
      final request = _request(
        overrides: <BorderSlotOverride>[locked],
        snapshots: <BorderVisualSnapshot>[_snapshotAModel(), _snapshotBModel()],
      );
      final result = assessBorderMaterializationFreshness(
        request,
        materialization: null,
        snapshotIntegrity: <String, BorderVisualSnapshotIntegrity>{
          _snapshotA: _status(),
          _snapshotB: _status(snapshotId: _snapshotB),
        },
      );

      expect(result.state, BorderMaterializationState.unmaterialized);
      expect(result.canRegenerate, isFalse);
    });

    test(
        'unauthorized current locked snapshot only stales an independent old output',
        () {
      final base = _request();
      final locked = BorderSlotOverride(
        slotKey: 'slot',
        variationSalt: BorderSignedInt64.zero,
        suppressed: false,
        locked: true,
        lockedPlacement: _placement(
          snapshotId: _snapshotB,
          primitiveId: 'primitive',
        ),
      );
      final current = _request(
        overrides: <BorderSlotOverride>[locked],
        snapshots: <BorderVisualSnapshot>[_snapshotAModel(), _snapshotBModel()],
      );

      final result = assessBorderMaterializationFreshness(
        current,
        materialization: _materialization(base),
        snapshotIntegrity: <String, BorderVisualSnapshotIntegrity>{
          _snapshotA: _status(),
          _snapshotB: _status(snapshotId: _snapshotB),
        },
      );

      expect(result.state, BorderMaterializationState.stale);
      expect(result.reasons, <BorderStalenessReason>{
        BorderStalenessReason.overridesChanged,
      });
      expect(result.isRenderable, isTrue);
      expect(result.canRegenerate, isFalse);
    });

    test(
        'unfingerprintable current locked override can never leave output fresh',
        () {
      final base = _request();
      final locked = BorderSlotOverride(
        slotKey: 'slot',
        variationSalt: BorderSignedInt64.zero,
        suppressed: false,
        locked: true,
        lockedPlacement: _placement(
          snapshotId: _snapshotB,
          primitiveId: 'primitive',
        ),
      );
      final current = _request(overrides: <BorderSlotOverride>[locked]);

      final result = assessBorderMaterializationFreshness(
        current,
        materialization: _materialization(base),
        snapshotIntegrity: _integrity(),
      );

      expect(result.state, BorderMaterializationState.stale);
      expect(
        result.reasons,
        <BorderStalenessReason>{
          BorderStalenessReason.overridesChanged,
          BorderStalenessReason.visualSnapshotMissingOrCorrupt,
        },
      );
      expect(result.isRenderable, isTrue);
      expect(result.canRegenerate, isFalse);
    });

    test(
        'self-consistent forged snapshot component is invalid at same revision',
        () {
      final request = _request();
      final valid = _materialization(request);
      final original = valid.receipt.components;
      final forgedComponents = BorderInputFingerprints(
        blueprint: original.blueprint,
        geometryAndSeed: original.geometryAndSeed,
        parameters: original.parameters,
        overrides: original.overrides,
        keepOutRegions: original.keepOutRegions,
        mapContext: original.mapContext,
        visualSnapshots: _wrongHash,
      );
      final forged = _replaceReceipt(
        valid,
        components: forgedComponents,
        inputFingerprint: computeBorderAggregateInputFingerprint(
          resolverVersion: valid.receipt.resolverVersion,
          blueprintRevision: valid.receipt.blueprintRevision,
          components: forgedComponents,
        ),
      );

      final result = assessBorderMaterializationFreshness(
        request,
        materialization: forged,
        snapshotIntegrity: _integrity(),
      );

      expect(result.state, BorderMaterializationState.invalid);
      expect(result.isRenderable, isFalse);
    });
  });
}

BorderResolutionRequest _request({
  bool published = true,
  int revision = 1,
  int resolverVersion = 3,
  BorderSignedInt64? seed,
  BorderFeatureGeometry? geometry,
  BorderGenerationParams? paramsOverride,
  List<BorderSlotOverride> overrides = const <BorderSlotOverride>[],
  List<BorderKeepOutRegion> keepOutRegions = const <BorderKeepOutRegion>[],
  GridSize tileSize = const GridSize(width: 16, height: 16),
  String primitiveSnapshotId = _snapshotA,
  String extraPrimitiveId = 'extra-primitive',
  String? extraPrimitiveSnapshotId,
  String? groundSnapshotId,
  int primitiveWeight = 1,
  BorderPrimitiveAssetMetrics? primitiveMetrics,
  List<BorderVisualSnapshot>? snapshots,
  BorderBlueprintTemplate template = BorderBlueprintTemplate.organicEdge,
}) {
  final feature = BorderFeature(
    id: 'feature',
    name: 'Feature',
    blueprintId: 'blueprint',
    seed: seed ?? BorderSignedInt64.fromInt(7),
    geometry: geometry ??
        BorderRegionGeometry(
          width: 3,
          height: 2,
          cells: const <bool>[true, true, false, false, true, false],
        ),
    paramsOverride: paramsOverride,
    overrides: overrides,
    keepOutRegions: keepOutRegions,
  );
  return BorderResolutionRequest(
    mapSize: const GridSize(width: 3, height: 2),
    tileSizePx: tileSize,
    blueprintId: 'blueprint',
    blueprintRevision: published
        ? BorderBlueprintRevision(
            revision: revision,
            definition: BorderBlueprintPublishedDefinition(
              name: 'Blueprint',
              previewSeed: BorderSignedInt64.zero,
              template: template,
              primitives: <BorderPublishedPrimitive>[
                _primitive(
                  snapshotId: primitiveSnapshotId,
                  weight: primitiveWeight,
                  metrics: primitiveMetrics,
                ),
                if (extraPrimitiveSnapshotId != null)
                  _primitive(
                    id: extraPrimitiveId,
                    snapshotId: extraPrimitiveSnapshotId,
                    weight: 1,
                  ),
              ],
              defaults: _params(),
              ground: groundSnapshotId == null
                  ? null
                  : BorderPublishedGround(
                      sourceSmartTilePresetId: 'surface',
                      edgeBandCells: 1,
                      visualSnapshotIdsByRole: <SurfaceVariantRole, String>{
                        for (final role in standardSurfaceVariantRoleOrder)
                          role: role == SurfaceVariantRole.cross
                              ? groundSnapshotId
                              : _snapshotA,
                      },
                    ),
              sortOrder: 0,
            ),
          )
        : null,
    feature: feature,
    visualSnapshots: snapshots ?? <BorderVisualSnapshot>[_snapshotAModel()],
    resolverVersion: resolverVersion,
  );
}

BorderPublishedPrimitive _primitive({
  String id = 'primitive',
  required String snapshotId,
  required int weight,
  BorderPrimitiveAssetMetrics? metrics,
}) =>
    BorderPublishedPrimitive(
      id: id,
      sourceElementId: 'source',
      visualSnapshotId: snapshotId,
      role: BorderPrimitiveRole.structureLarge,
      weight: weight,
      anchorPx: const BorderPixelPos(x: 1, y: 1),
      transforms: BorderTransformPolicy(
        allowFlipX: false,
        allowedQuarterTurns: <int>[0],
      ),
      publishedMetrics: metrics ??
          BorderPrimitiveAssetMetrics(
            assetFingerprint: 'asset',
            pixelSize: const GridSize(width: 2, height: 2),
            opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 2, height: 2),
            defaultAnchorPx: const BorderPixelPos(x: 1, y: 1),
            occupancyMaskRle: 'border-rle-v1:4:1:4',
          ),
    );

BorderGenerationParams _params({int depthRows = 1}) => BorderGenerationParams(
      irregularityPermille: 100,
      detailDensityPermille: 200,
      variationPermille: 300,
      maxOverlapPx: 1,
      gapTolerancePx: 1,
      depthRows: depthRows,
    );

BorderSlotOverride _override() => BorderSlotOverride(
      slotKey: 'slot',
      variationSalt: BorderSignedInt64.fromInt(1),
      suppressed: false,
      locked: false,
      replacementPrimitiveId: 'primitive',
    );

BorderKeepOutRegion _keepOut() => BorderKeepOutRegion(
      id: 'keep-out',
      region: BorderRegionGeometry(
        width: 3,
        height: 2,
        cells: const <bool>[false, false, false, false, false, true],
      ),
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
  final outputGround = ground ?? <BorderResolvedGroundCell>[_ground(x: 0)];
  final components = computeBorderInputFingerprints(request);
  final output = computeBorderOutputFingerprint(
    ground: outputGround,
    placements: placements,
  );
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
      outputFingerprint: output,
    ),
    ground: outputGround,
    placements: placements,
  );
}

BorderMaterialization _replaceReceipt(
  BorderMaterialization source, {
  BorderInputFingerprints? components,
  String? inputFingerprint,
}) =>
    BorderMaterialization(
      receipt: BorderResolutionReceipt(
        resolverVersion: source.receipt.resolverVersion,
        blueprintRevision: source.receipt.blueprintRevision,
        components: components ?? source.receipt.components,
        inputFingerprint: inputFingerprint ?? source.receipt.inputFingerprint,
        outputFingerprint: source.receipt.outputFingerprint,
      ),
      ground: source.ground,
      placements: source.placements,
    );

BorderResolvedGroundCell _ground({int x = 0, String snapshotId = _snapshotA}) =>
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
  String primitiveId = 'primitive',
  String snapshotId = _snapshotA,
}) =>
    BorderResolvedPlacement(
      id: 'placement',
      slotKey: 'slot',
      primitiveId: primitiveId,
      visualSnapshotId: snapshotId,
      anchorCell: anchor,
      topLeftWorldPx: const BorderPixelPos(x: 16, y: 0),
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
