import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import '../models/border_blueprint.dart';
import '../models/border_diagnostics.dart';
import '../models/border_feature.dart';
import '../models/border_geometry.dart';
import '../models/border_materialization.dart';
import '../models/border_resolution.dart';
import '../models/border_value_objects.dart';
import '../models/border_visual_snapshot.dart';
import '../models/geometry.dart';
import 'border_coverage.dart';
import 'border_linear_lattice.dart';
import 'border_publication_readiness.dart';
import 'border_resolver.dart';
import 'border_slot_keys.dart';
import 'border_template_capabilities.dart';
import 'connected_line_border_resolver.dart';
import 'masonry_line_border_resolver.dart';
import 'organic_edge_canonical_gallery.dart';
import 'post_and_rail_line_border_resolver.dart';
import 'stone_chain_contact_metrics.dart';
import 'stone_chain_line_border_resolver.dart';

const GridSize _lineGalleryMapSize = GridSize(width: 12, height: 10);

/// Template-neutral canonical gallery resolved from production solvers.
@immutable
final class BorderCanonicalGalleryResult {
  BorderCanonicalGalleryResult._({
    required this.template,
    required this.report,
    required List<BorderCanonicalGalleryCaseResult> cases,
    required this.resolutionDiagnostics,
  }) : _cases = List<BorderCanonicalGalleryCaseResult>.unmodifiable(cases);

  final BorderBlueprintTemplate template;
  final BorderPublicationGalleryReport report;
  final List<BorderCanonicalGalleryCaseResult> _cases;
  final BorderDiagnosticsReport resolutionDiagnostics;

  List<BorderCanonicalGalleryCaseResult> get cases => _cases;

  bool get allCasesResolved =>
      _cases.length ==
          borderCanonicalGalleryCasesForTemplate(template).length &&
      _cases.every(
        (item) =>
            item.resolverResult.canApply &&
            (!borderTemplateRequiresInvertedCanonicalGallery(template) ||
                item.invertedResolverResult?.canApply == true),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderCanonicalGalleryResult &&
          template == other.template &&
          report == other.report &&
          _listEquals(_cases, other._cases) &&
          resolutionDiagnostics == other.resolutionDiagnostics;

  @override
  int get hashCode => Object.hash(
        template,
        report,
        Object.hashAll(_cases),
        resolutionDiagnostics,
      );
}

/// One neutral case, including the exact geometry sent to the real solver.
@immutable
final class BorderCanonicalGalleryCaseResult {
  const BorderCanonicalGalleryCaseResult._({
    required this.galleryCase,
    required this.mapSize,
    required this.geometry,
    required this.resolverResult,
    this.invertedResolverResult,
    required this.publicationSample,
  });

  final BorderCanonicalGalleryCase galleryCase;
  final GridSize mapSize;
  final BorderFeatureGeometry geometry;

  /// Primary-side output retained under the original gallery API.
  final BorderResolutionResult resolverResult;

  /// Opposite-side output when the template's publication contract requires
  /// both sides; `null` for the historical one-sided galleries.
  final BorderResolutionResult? invertedResolverResult;
  final BorderPublicationGallerySample publicationSample;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderCanonicalGalleryCaseResult &&
          galleryCase == other.galleryCase &&
          mapSize == other.mapSize &&
          geometry == other.geometry &&
          resolverResult == other.resolverResult &&
          invertedResolverResult == other.invertedResolverResult &&
          publicationSample == other.publicationSample;

  @override
  int get hashCode => Object.hash(
        galleryCase,
        mapSize,
        geometry,
        resolverResult,
        invertedResolverResult,
        publicationSample,
      );
}

/// Resolves the immutable canonical gallery for a published V1 template.
BorderCanonicalGalleryResult resolveBorderCanonicalGallery({
  required String blueprintId,
  required BorderBlueprintRevision blueprintRevision,
  required Iterable<BorderVisualSnapshot> visualSnapshots,
  required GridSize tileSizePx,
  int resolverVersion = borderResolverVersion,
}) {
  final definition = blueprintRevision.definition;
  final snapshots = visualSnapshots.toList(growable: false);
  if (definition.template == BorderBlueprintTemplate.organicEdge) {
    return _adaptOrganicGallery(
      resolveOrganicEdgeCanonicalGallery(
        blueprintId: blueprintId,
        blueprintRevision: blueprintRevision,
        visualSnapshots: snapshots,
        tileSizePx: tileSizePx,
        resolverVersion: resolverVersion,
      ),
    );
  }
  final cases = <BorderCanonicalGalleryCaseResult>[];
  final diagnostics = <BorderDiagnostic>[];

  for (final galleryCase in borderCanonicalGalleryCasesForTemplate(
    definition.template,
  )) {
    final caseWire = borderCanonicalGalleryCaseV1WireName(galleryCase);
    switch (definition.template) {
      case BorderBlueprintTemplate.masonryLine:
        final geometry = _masonryGeometryFor(galleryCase);
        final evidence = resolveMasonryLineBorderWithEvidence(
          _request(
            mapSize: _lineGalleryMapSize,
            tileSizePx: tileSizePx,
            blueprintId: blueprintId,
            blueprintRevision: blueprintRevision,
            visualSnapshots: snapshots,
            resolverVersion: resolverVersion,
            caseWire: caseWire,
            geometry: geometry,
          ),
        );
        diagnostics.addAll(evidence.result.diagnostics);
        final sample = BorderPublicationGallerySample(
          galleryCase: galleryCase,
          coverageChecks: <BorderPublicationCoverageCheck>[
            _masonryCoverageCheck(
              evidence,
              definition.defaults),
          ],
          structuralRuns: _structuralRuns(
            caseWire: caseWire,
            result: evidence.result,
            definition: definition,
            geometry: geometry,
            acceptedRoles: const <BorderPrimitiveRole>{
              BorderPrimitiveRole.structureLarge,
              BorderPrimitiveRole.structureMedium,
              BorderPrimitiveRole.filler,
            },
          ),
        );
        cases.add(
          BorderCanonicalGalleryCaseResult._(
            galleryCase: galleryCase,
            mapSize: _lineGalleryMapSize,
            geometry: geometry,
            resolverResult: evidence.result,
            publicationSample: sample,
          ),
        );
      case BorderBlueprintTemplate.postAndRailLine:
        final geometry = _fenceGeometryFor(galleryCase);
        final evidence = resolvePostAndRailLineBorderWithEvidence(
          _request(
            mapSize: _lineGalleryMapSize,
            tileSizePx: tileSizePx,
            blueprintId: blueprintId,
            blueprintRevision: blueprintRevision,
            visualSnapshots: snapshots,
            resolverVersion: resolverVersion,
            caseWire: caseWire,
            geometry: geometry,
          ),
        );
        diagnostics.addAll(evidence.result.diagnostics);
        final sample = BorderPublicationGallerySample(
          galleryCase: galleryCase,
          coverageChecks: _fenceCoverageChecks(
            galleryCase: galleryCase,
            evidence: evidence,
            params: definition.defaults,
          ),
          structuralRuns: _structuralRuns(
            caseWire: caseWire,
            result: evidence.result,
            definition: definition,
            geometry: geometry,
            acceptedRoles: const <BorderPrimitiveRole>{
              BorderPrimitiveRole.post,
              BorderPrimitiveRole.span,
            },
          ),
        );
        cases.add(
          BorderCanonicalGalleryCaseResult._(
            galleryCase: galleryCase,
            mapSize: _lineGalleryMapSize,
            geometry: geometry,
            resolverResult: evidence.result,
            publicationSample: sample,
          ),
        );
      case BorderBlueprintTemplate.connectedLine:
        final geometry = _connectedLineGeometryFor(galleryCase);
        final primary = resolveConnectedLineBorderWithEvidence(
          _request(
            mapSize: _lineGalleryMapSize,
            tileSizePx: tileSizePx,
            blueprintId: blueprintId,
            blueprintRevision: blueprintRevision,
            visualSnapshots: snapshots,
            resolverVersion: resolverVersion,
            caseWire: caseWire,
            geometry: geometry,
            lineSide: BorderLineSide.primary,
          ),
        );
        final inverted = resolveConnectedLineBorderWithEvidence(
          _request(
            mapSize: _lineGalleryMapSize,
            tileSizePx: tileSizePx,
            blueprintId: blueprintId,
            blueprintRevision: blueprintRevision,
            visualSnapshots: snapshots,
            resolverVersion: resolverVersion,
            caseWire: caseWire,
            geometry: geometry,
            lineSide: BorderLineSide.inverted,
          ),
        );
        diagnostics
          ..addAll(primary.result.diagnostics)
          ..addAll(inverted.result.diagnostics);
        final sample = BorderPublicationGallerySample(
          galleryCase: galleryCase,
          coverageChecks: _connectedLineCoverageChecks(
            galleryCase: galleryCase,
            params: definition.defaults,
            geometry: geometry,
            definition: definition,
            primary: primary.result,
            inverted: inverted.result,
            tileSizePx: tileSizePx,
          ),
          structuralRuns: <BorderPublicationStructuralRun>[
            ..._structuralRuns(
              caseWire: caseWire,
              idPrefix: 'primary:$caseWire',
              result: primary.result,
              definition: definition,
              geometry: geometry,
              acceptedRoles: const <BorderPrimitiveRole>{
                BorderPrimitiveRole.lineCap,
                BorderPrimitiveRole.lineStraight,
                BorderPrimitiveRole.lineCorner,
              },
            ),
            ..._structuralRuns(
              caseWire: caseWire,
              idPrefix: 'inverted:$caseWire',
              result: inverted.result,
              definition: definition,
              geometry: geometry,
              acceptedRoles: const <BorderPrimitiveRole>{
                BorderPrimitiveRole.lineCap,
                BorderPrimitiveRole.lineStraight,
                BorderPrimitiveRole.lineCorner,
              },
            ),
          ],
        );
        cases.add(
          BorderCanonicalGalleryCaseResult._(
            galleryCase: galleryCase,
            mapSize: _lineGalleryMapSize,
            geometry: geometry,
            resolverResult: primary.result,
            invertedResolverResult: inverted.result,
            publicationSample: sample,
          ),
        );
      case BorderBlueprintTemplate.stoneChainLine:
        final geometry = _stoneChainGeometryFor(
          galleryCase,
          depthRows: definition.defaults.depthRows,
        );
        final primary = resolveStoneChainLineBorderWithEvidence(
          _request(
            mapSize: _lineGalleryMapSize,
            tileSizePx: tileSizePx,
            blueprintId: blueprintId,
            blueprintRevision: blueprintRevision,
            visualSnapshots: snapshots,
            resolverVersion: resolverVersion,
            caseWire: caseWire,
            geometry: geometry,
            lineSide: BorderLineSide.primary,
          ),
        );
        final inverted = resolveStoneChainLineBorderWithEvidence(
          _request(
            mapSize: _lineGalleryMapSize,
            tileSizePx: tileSizePx,
            blueprintId: blueprintId,
            blueprintRevision: blueprintRevision,
            visualSnapshots: snapshots,
            resolverVersion: resolverVersion,
            caseWire: caseWire,
            geometry: geometry,
            lineSide: BorderLineSide.inverted,
          ),
        );
        diagnostics
          ..addAll(primary.result.diagnostics)
          ..addAll(inverted.result.diagnostics);
        final requiresTwoTierEvidence =
            borderTemplateRequiresTwoTierStoneChainEvidence(
          template: definition.template,
          depthRows: definition.defaults.depthRows,
        );
        final primaryMeasurement =
            requiresTwoTierEvidence && primary.result.canApply
                ? _measureStoneChainPublicationEvidence(
                    result: primary.result,
                    definition: definition,
                    geometry: geometry,
                    featureId: 'border-gallery-v1:$caseWire',
                    lineSide: BorderLineSide.primary,
                  )
                : null;
        final invertedMeasurement =
            requiresTwoTierEvidence && inverted.result.canApply
                ? _measureStoneChainPublicationEvidence(
                    result: inverted.result,
                    definition: definition,
                    geometry: geometry,
                    featureId: 'border-gallery-v1:$caseWire',
                    lineSide: BorderLineSide.inverted,
                  )
                : null;
        final sample = BorderPublicationGallerySample(
          galleryCase: galleryCase,
          coverageChecks: requiresTwoTierEvidence
              ? _twoTierStoneChainCoverageChecks(
                  primary: primaryMeasurement,
                  inverted: invertedMeasurement,
                  params: definition.defaults,
                )
              : <BorderPublicationCoverageCheck>[
                  _stoneChainCoverageCheck(
                    primary: primary,
                    inverted: inverted,
                    params: definition.defaults,
                  ),
                ],
          structuralRuns: const <BorderPublicationStructuralRun>[],
          primaryStoneChainEvidence: primaryMeasurement?.evidence,
          invertedStoneChainEvidence: invertedMeasurement?.evidence,
        );
        cases.add(
          BorderCanonicalGalleryCaseResult._(
            galleryCase: galleryCase,
            mapSize: _lineGalleryMapSize,
            geometry: geometry,
            resolverResult: primary.result,
            invertedResolverResult: inverted.result,
            publicationSample: sample,
          ),
        );
      case BorderBlueprintTemplate.organicEdge:
        throw StateError('Organic gallery is adapted before line dispatch');
    }
  }

  return BorderCanonicalGalleryResult._(
    template: definition.template,
    report: BorderPublicationGalleryReport(
      resolverVersion: resolverVersion,
      canonicalGalleryVersion: borderCanonicalGalleryVersion,
      candidateFingerprint: computeBorderPublicationCandidateFingerprint(
        blueprintId: blueprintId,
        definition: definition,
        resolverVersion: resolverVersion,
      ),
      samples: <BorderPublicationGallerySample>[
        for (final item in cases) item.publicationSample,
      ],
    ),
    cases: cases,
    resolutionDiagnostics: BorderDiagnosticsReport(diagnostics: diagnostics),
  );
}

BorderCanonicalGalleryResult _adaptOrganicGallery(
  OrganicEdgeCanonicalGalleryResult source,
) =>
    BorderCanonicalGalleryResult._(
      template: BorderBlueprintTemplate.organicEdge,
      report: source.report,
      cases: <BorderCanonicalGalleryCaseResult>[
        for (final item in source.cases)
          BorderCanonicalGalleryCaseResult._(
            galleryCase: item.galleryCase,
            mapSize: GridSize(
              width: item.geometry.width,
              height: item.geometry.height,
            ),
            geometry: item.geometry,
            resolverResult: item.resolverEvidence.result,
            publicationSample: item.publicationSample,
          ),
      ],
      resolutionDiagnostics: source.resolutionDiagnostics,
    );

BorderResolutionRequest _request({
  required GridSize mapSize,
  required GridSize tileSizePx,
  required String blueprintId,
  required BorderBlueprintRevision blueprintRevision,
  required Iterable<BorderVisualSnapshot> visualSnapshots,
  required int resolverVersion,
  required String caseWire,
  required BorderFeatureGeometry geometry,
  BorderLineSide lineSide = BorderLineSide.primary,
}) =>
    BorderResolutionRequest(
      mapSize: mapSize,
      tileSizePx: tileSizePx,
      blueprintId: blueprintId,
      blueprintRevision: blueprintRevision,
      feature: BorderFeature(
        id: 'border-gallery-v1:$caseWire',
        name: caseWire,
        blueprintId: blueprintId,
        seed: blueprintRevision.definition.previewSeed,
        geometry: geometry,
        lineSide: lineSide,
        overrides: const <BorderSlotOverride>[],
        keepOutRegions: const <BorderKeepOutRegion>[],
      ),
      visualSnapshots: visualSnapshots,
      resolverVersion: resolverVersion,
    );

BorderStrokeGeometry _masonryGeometryFor(
  BorderCanonicalGalleryCase galleryCase,
) =>
    switch (galleryCase) {
      BorderCanonicalGalleryCase.longEdge => BorderStrokeGeometry(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'primary',
              points: <GridPos>[
                for (var x = 2; x <= 9; x += 1) GridPos(x: x, y: 5)],
              closed: false,
            ),
          ],
        ),
      BorderCanonicalGalleryCase.sharpCorner => BorderStrokeGeometry(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'primary',
              points: const <GridPos>[
                GridPos(x: 2, y: 2),
                GridPos(x: 3, y: 2),
                GridPos(x: 4, y: 2),
                GridPos(x: 5, y: 2),
                GridPos(x: 5, y: 3),
                GridPos(x: 5, y: 4),
                GridPos(x: 5, y: 5),
                GridPos(x: 5, y: 6),
              ],
              closed: false,
            ),
          ],
        ),
      BorderCanonicalGalleryCase.endpoint => BorderStrokeGeometry(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'primary',
              points: const <GridPos>[
                GridPos(x: 4, y: 4),
                GridPos(x: 5, y: 4),
                GridPos(x: 6, y: 4),
                GridPos(x: 7, y: 4),
              ],
              closed: false,
            ),
          ],
        ),
      _ => throw const ValidationException(
          'Organic or fence-only case is not valid in the masonry gallery',
        ),
    };

BorderStrokeGeometry _fenceGeometryFor(
  BorderCanonicalGalleryCase galleryCase,
) =>
    switch (galleryCase) {
      BorderCanonicalGalleryCase.longEdge => BorderStrokeGeometry(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'primary',
              points: <GridPos>[
                for (var x = 2; x <= 9; x += 1) GridPos(x: x, y: 5)],
              closed: false,
            ),
          ],
        ),
      BorderCanonicalGalleryCase.sharpCorner => BorderStrokeGeometry(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'primary',
              points: const <GridPos>[
                GridPos(x: 2, y: 2),
                GridPos(x: 3, y: 2),
                GridPos(x: 4, y: 2),
                GridPos(x: 5, y: 2),
                GridPos(x: 5, y: 3),
                GridPos(x: 5, y: 4),
                GridPos(x: 5, y: 5),
                GridPos(x: 5, y: 6),
              ],
              closed: false,
            ),
          ],
        ),
      BorderCanonicalGalleryCase.endpoint => BorderStrokeGeometry(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'primary',
              points: const <GridPos>[
                GridPos(x: 4, y: 4),
                GridPos(x: 5, y: 4),
                GridPos(x: 6, y: 4),
                GridPos(x: 7, y: 4),
              ],
              closed: false,
            ),
          ],
        ),
      BorderCanonicalGalleryCase.opening => BorderStrokeGeometry(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'leading',
              points: const <GridPos>[
                GridPos(x: 1, y: 5),
                GridPos(x: 2, y: 5),
                GridPos(x: 3, y: 5),
                GridPos(x: 4, y: 5),
              ],
              closed: false,
            ),
            BorderStroke(
              id: 'trailing',
              points: const <GridPos>[
                GridPos(x: 7, y: 5),
                GridPos(x: 8, y: 5),
                GridPos(x: 9, y: 5),
                GridPos(x: 10, y: 5),
              ],
              closed: false,
            ),
          ],
        ),
      _ => throw const ValidationException(
          'Organic-only case is not valid in the fence gallery',
        ),
    };

BorderStrokeGeometry _connectedLineGeometryFor(
  BorderCanonicalGalleryCase galleryCase,
) {
  if (galleryCase == BorderCanonicalGalleryCase.sBend) {
    return BorderStrokeGeometry(
      strokes: <BorderStroke>[
        BorderStroke(
          id: 'primary',
          points: const <GridPos>[
            GridPos(x: 1, y: 2),
            GridPos(x: 2, y: 2),
            GridPos(x: 3, y: 2),
            GridPos(x: 3, y: 3),
            GridPos(x: 3, y: 4),
            GridPos(x: 4, y: 4),
            GridPos(x: 5, y: 4),
            GridPos(x: 5, y: 5),
            GridPos(x: 5, y: 6),
            GridPos(x: 6, y: 6),
            GridPos(x: 7, y: 6),
          ],
          closed: false,
        ),
      ],
    );
  }
  if (galleryCase != BorderCanonicalGalleryCase.sharpCorner) {
    return _fenceGeometryFor(galleryCase);
  }
  return BorderStrokeGeometry(
    strokes: <BorderStroke>[
      BorderStroke(
        id: 'leftTurn',
        points: const <GridPos>[
          GridPos(x: 1, y: 2),
          GridPos(x: 2, y: 2),
          GridPos(x: 3, y: 2),
          GridPos(x: 4, y: 2),
          GridPos(x: 4, y: 3),
          GridPos(x: 4, y: 4),
          GridPos(x: 4, y: 5),
        ],
        closed: false,
      ),
      BorderStroke(
        id: 'rightTurn',
        points: const <GridPos>[
          GridPos(x: 10, y: 4),
          GridPos(x: 10, y: 5),
          GridPos(x: 10, y: 6),
          GridPos(x: 10, y: 7),
          GridPos(x: 9, y: 7),
          GridPos(x: 8, y: 7),
          GridPos(x: 7, y: 7),
        ],
        closed: false,
      ),
    ],
  );
}

BorderStrokeGeometry _stoneChainGeometryFor(
        BorderCanonicalGalleryCase galleryCase,
        {required int depthRows,
}) =>
    BorderStrokeGeometry(
      alignment: BorderStrokeAlignment.gridEdges,
      strokes: switch (galleryCase) {
        BorderCanonicalGalleryCase.longEdge => <BorderStroke>[
            BorderStroke(
              id: 'horizontal',
              points: <GridPos>[
                for (var x = 1; x <= 10; x += 1) GridPos(x: x, y: 3)],
              closed: false,
            ),
            BorderStroke(
              id: 'vertical',
              points: <GridPos>[
                for (var y = 1; y <= 8; y += 1) GridPos(x: 11, y: y)],
              closed: false,
            ),
          ],
        BorderCanonicalGalleryCase.sharpCorner => <BorderStroke>[
            if (depthRows == 2) ...<BorderStroke>[
              BorderStroke(
                id: 'convexL',
                points: const <GridPos>[
                  GridPos(x: 1, y: 2),
                  GridPos(x: 2, y: 2),
                  GridPos(x: 3, y: 2),
                  GridPos(x: 4, y: 2),
                  GridPos(x: 4, y: 3),
                  GridPos(x: 4, y: 4),
                  GridPos(x: 4, y: 5),
                ],
                closed: false,
              ),
              BorderStroke(
                id: 'concaveL',
                points: const <GridPos>[
                  GridPos(x: 10, y: 4),
                  GridPos(x: 10, y: 5),
                  GridPos(x: 10, y: 6),
                  GridPos(x: 10, y: 7),
                  GridPos(x: 9, y: 7),
                  GridPos(x: 8, y: 7),
                  GridPos(x: 7, y: 7),
                ],
                closed: false,
              ),
            ] else
              BorderStroke(
                id: 'primary',
                points: const <GridPos>[
                  GridPos(x: 2, y: 2),
                  GridPos(x: 3, y: 2),
                  GridPos(x: 4, y: 2),
                  GridPos(x: 5, y: 2),
                  GridPos(x: 5, y: 3),
                  GridPos(x: 5, y: 4),
                  GridPos(x: 5, y: 5),
                  GridPos(x: 5, y: 6),
                ],
                closed: false,
              ),
          ],
        BorderCanonicalGalleryCase.endpoint => <BorderStroke>[
            BorderStroke(
              id: 'primary',
              points: const <GridPos>[
                GridPos(x: 4, y: 4),
                GridPos(x: 5, y: 4),
                GridPos(x: 6, y: 4),
                GridPos(x: 7, y: 4),
              ],
              closed: false,
            ),
          ],
        BorderCanonicalGalleryCase.sBend => <BorderStroke>[
            BorderStroke(
              id: 'primary',
              points: const <GridPos>[
                GridPos(x: 1, y: 2),
                GridPos(x: 2, y: 2),
                GridPos(x: 3, y: 2),
                GridPos(x: 3, y: 3),
                GridPos(x: 3, y: 4),
                GridPos(x: 4, y: 4),
                GridPos(x: 5, y: 4),
                GridPos(x: 5, y: 3),
                GridPos(x: 5, y: 2),
                GridPos(x: 6, y: 2),
                GridPos(x: 7, y: 2),
              ],
              closed: false,
            ),
          ],
        BorderCanonicalGalleryCase.closedLoop => <BorderStroke>[
            BorderStroke(
              id: 'primary',
              points: const <GridPos>[
                GridPos(x: 3, y: 2),
                GridPos(x: 4, y: 2),
                GridPos(x: 5, y: 2),
                GridPos(x: 6, y: 2),
                GridPos(x: 6, y: 3),
                GridPos(x: 6, y: 4),
                GridPos(x: 6, y: 5),
                GridPos(x: 5, y: 5),
                GridPos(x: 4, y: 5),
                GridPos(x: 3, y: 5),
                GridPos(x: 3, y: 4),
                GridPos(x: 3, y: 3),
              ],
              closed: true,
            ),
          ],
        _ => throw const ValidationException(
            'Non-stone case is not valid in the stone-chain gallery',
          ),
      },
    );

BorderPublicationCoverageCheck _stoneChainCoverageCheck({
  required StoneChainLineBorderResolutionEvidence primary,
  required StoneChainLineBorderResolutionEvidence inverted,
  required BorderGenerationParams params,
}) =>
    BorderPublicationCoverageCheck(
      component: BorderCanonicalCoverageComponent.primary,
      longestContiguousGapPx: primary.maximumGapPx > inverted.maximumGapPx
          ? primary.maximumGapPx
          : inverted.maximumGapPx,
      maximumPairwiseOverlapPx:
          primary.maximumTangentOverlapPx > inverted.maximumTangentOverlapPx
              ? primary.maximumTangentOverlapPx
              : inverted.maximumTangentOverlapPx,
      gapTolerancePx: params.gapTolerancePx,
      maxOverlapPx: params.maxOverlapPx,
    );

List<BorderPublicationCoverageCheck> _twoTierStoneChainCoverageChecks({
  required _StoneChainPublicationMeasurement? primary,
  required _StoneChainPublicationMeasurement? inverted,
  required BorderGenerationParams params,
}) =>
    <BorderPublicationCoverageCheck>[
      for (final component in const <BorderCanonicalCoverageComponent>[
        BorderCanonicalCoverageComponent.lip,
        BorderCanonicalCoverageComponent.face,
      ])
        BorderPublicationCoverageCheck(
          component: component,
          longestContiguousGapPx: _maximum(<int>[
            primary?.coverageFor(component).gap ?? 0,
            inverted?.coverageFor(component).gap ?? 0,
          ]),
          maximumPairwiseOverlapPx: _maximum(<int>[
            primary?.coverageFor(component).overlap ?? 0,
            inverted?.coverageFor(component).overlap ?? 0,
          ]),
          gapTolerancePx: params.gapTolerancePx,
          maxOverlapPx: params.maxOverlapPx,
        ),
    ];

_StoneChainPublicationMeasurement _measureStoneChainPublicationEvidence({
  required BorderResolutionResult result,
  required BorderBlueprintPublishedDefinition definition,
  required BorderStrokeGeometry geometry,
  required String featureId,
  required BorderLineSide lineSide,
}) {
  final primitiveById = <String, BorderPublishedPrimitive>{
    for (final primitive in definition.primitives) primitive.id: primitive,
  };
  final topologicalRuns = _stoneChainTopologicalRuns(
    geometry: geometry,
    lineSide: lineSide,
  );
  final turnFaceRuns = _stoneChainTurnFaceRuns(
    featureId: featureId,
    geometry: geometry,
    lineSide: lineSide,
    runs: topologicalRuns,
  );
  final placements = <_StoneChainPublicationPlacement>[];
  for (final placement in result.materialization?.placements ??
      const <BorderResolvedPlacement>[]) {
    final primitive = primitiveById[placement.primitiveId];
    if (primitive == null) continue;
    final row = switch (primitive.role) {
      BorderPrimitiveRole.structureLarge ||
      BorderPrimitiveRole.lineCorner ||
      BorderPrimitiveRole.lineCap =>
        _StoneChainPublicationRow.lip,
      BorderPrimitiveRole.structureMedium => _StoneChainPublicationRow.face,
      _ => null,
    };
    if (row == null) continue;
    final axes = _stoneChainAxesFor(
      primitive.authoredOrientation,
      placement.transform.quarterTurns,
    );
    if (axes == null) continue;
    final station = GridPos(
      x: placement.anchorCell.x + (axes.normal.dx < 0 ? 1 : 0),
      y: placement.anchorCell.y + (axes.normal.dy < 0 ? 1 : 0),
    );
    final topologicalRun = _stoneChainTopologicalRunFor(
      runs: topologicalRuns,
      station: station,
      normal: axes.normal,
      isTurnFace: turnFaceRuns.containsKey(placement.slotKey),
      turnRunKey: turnFaceRuns[placement.slotKey],
    );
    placements.add(
      _StoneChainPublicationPlacement(
        placement: placement,
        primitive: primitive,
        row: row,
        runKey: topologicalRun?.key ??
            (
              strokeId: 'unassigned:${placement.slotKey}',
              ordinal: 0,
              normalDx: axes.normal.dx,
              normalDy: axes.normal.dy,
            ),
        normal: axes.normal,
        tangent: axes.tangent,
      ),
    );
  }
  final lips = placements
      .where((placement) => placement.row == _StoneChainPublicationRow.lip)
      .toList(growable: false);
  final faces = placements
      .where((placement) => placement.row == _StoneChainPublicationRow.face)
      .toList(growable: false);
  final lipCoverage = _measureStoneChainRowCoverage(lips);
  final faceCoverage = _measureStoneChainRowCoverage(faces);
  final lipRuns = _stoneChainPublicationRuns(lips);
  final faceRunByPlacement =
      <_StoneChainPublicationPlacement, _StoneChainPublicationRunKey>{
    for (final entry in _stoneChainPublicationRuns(faces).entries)
      for (final placement in entry.value) placement: entry.key,
  };

  final visibleDepths = <int>[];
  final interlocks = <int>[];
  for (final face in faces) {
    final candidates = lips
        .where((lip) => lip.strokeId == face.strokeId)
        .toList(growable: false);
    var bestInterlock = 0;
    for (final lip in candidates) {
      final contact = measureStoneChainContact(
        first: lip.mask,
        second: face.mask,
        tangent: face.tangent,
        normal: face.normal,
      );
      if (contact.opaqueIntersectionPixels > bestInterlock) {
        bestInterlock = contact.opaqueIntersectionPixels;
      }
    }
    interlocks.add(bestInterlock);
    final faceFront = _maximumBoundsProjection(
      face.placement.opaqueWorldBoundsPx,
      face.normal,
    );
    int? lipFront;
    final faceRun = faceRunByPlacement[face];
    final depthCandidates = faceRun == null
        ? candidates.where(
            (lip) =>
                lip.normal.dx == face.normal.dx &&
                lip.normal.dy == face.normal.dy,
          )
        : lipRuns[faceRun] ?? const <_StoneChainPublicationPlacement>[];
    for (final lip in depthCandidates) {
      final candidateFront = _maximumBoundsProjection(
        lip.placement.opaqueWorldBoundsPx,
        face.normal,
      );
      if (lipFront == null || candidateFront > lipFront) {
        lipFront = candidateFront;
      }
    }
    final visibleDepth = faceFront - (lipFront ?? faceFront);
    visibleDepths.add(visibleDepth > 0 ? visibleDepth : 0);
  }
  visibleDepths.sort();

  return _StoneChainPublicationMeasurement(
    evidence: BorderPublicationStoneChainEvidence(
      lipPlacementCount: lips.length,
      facePlacementCount: faces.length,
      minimumCrossRowInterlockPixels:
          interlocks.isEmpty ? 0 : interlocks.reduce(_minimumInt),
      minimumVisibleFaceDepthPx:
          visibleDepths.isEmpty ? 0 : visibleDepths.first,
      medianVisibleFaceDepthPx: _integerMedian(visibleDepths),
      alignedJointRatioPermille: _alignedJointRatioPermille(
        lips: lips,
        faces: faces,
      ),
      lipConnectedComponentCount: _maximumConnectedComponentsByStroke(lips),
      faceConnectedComponentCount: _maximumConnectedComponentsByStroke(faces),
      combinedConnectedComponentCount:
          _maximumConnectedComponentsByStroke(placements,
      ),
    ),
    lipCoverage: lipCoverage,
    faceCoverage: faceCoverage,
  );
}

({int gap, int overlap}) _measureStoneChainRowCoverage(
  List<_StoneChainPublicationPlacement> placements,
) {
  final runs = _stoneChainPublicationRuns(placements);
  var maximumGap = 0;
  var maximumOverlap = 0;
  for (final run in runs.values) {
    final ordered = run.toList(growable: false)
      ..sort((left, right) {
        final byProjection = _minimumBoundsProjection(
          left.placement.opaqueWorldBoundsPx,
          left.tangent,
        ).compareTo(
          _minimumBoundsProjection(
            right.placement.opaqueWorldBoundsPx,
            right.tangent,
          ),
        );
        return byProjection != 0
            ? byProjection
            : left.placement.slotKey.compareTo(right.placement.slotKey);
      });
    final continuity = measureStoneChainRowContinuity(
      samples: <StoneChainRowSample>[
        for (var index = 0; index < ordered.length; index += 1)
          StoneChainRowSample(
            strokeId: ordered.first.strokeId,
            slotKey: ordered[index].placement.slotKey,
            pathDistancePx: index,
            closed: false,
            mask: ordered[index].mask,
          ),
      ],
      tangent: ordered.first.tangent,
      normal: ordered.first.normal,
    );
    if (continuity.maximumGapPx > maximumGap) {
      maximumGap = continuity.maximumGapPx;
    }
    if (continuity.maximumOverlapPx > maximumOverlap) {
      maximumOverlap = continuity.maximumOverlapPx;
    }
  }
  return (gap: maximumGap, overlap: maximumOverlap);
}

int _maximumConnectedComponentsByStroke(
  List<_StoneChainPublicationPlacement> placements,
) {
  final byStroke = <String, List<_StoneChainPublicationPlacement>>{};
  for (final placement in placements) {
    (byStroke[placement.strokeId] ??= <_StoneChainPublicationPlacement>[])
        .add(placement,
    );
  }
  var maximum = 0;
  for (final entry in byStroke.entries) {
    final continuity = measureStoneChainRowContinuity(
      samples: <StoneChainRowSample>[
        for (var index = 0; index < entry.value.length; index += 1)
          StoneChainRowSample(
            strokeId: '${entry.key}:component:$index',
            slotKey: entry.value[index].placement.slotKey,
            pathDistancePx: 0,
            closed: false,
            mask: entry.value[index].mask,
          ),
      ],
      tangent: StoneChainAxis(dx: 1, dy: 0),
      normal: StoneChainAxis(dx: 0, dy: 1),
    );
    if (continuity.connectedComponentCount > maximum) {
      maximum = continuity.connectedComponentCount;
    }
  }
  return maximum;
}

int _alignedJointRatioPermille({
  required List<_StoneChainPublicationPlacement> lips,
  required List<_StoneChainPublicationPlacement> faces,
}) {
  final lipJointsByRun = _stoneChainJointCoordinatesByRun(lips);
  final faceJointsByRun = _stoneChainJointCoordinatesByRun(faces);
  var aligned = 0;
  var totalFaceJoints = 0;
  for (final entry in faceJointsByRun.entries) {
    totalFaceJoints += entry.value.length;
    final lipJoints = lipJointsByRun[entry.key] ?? const <int>{};
    aligned += _countApproximatelyAlignedJoints(
      faceJoints: entry.value,
      lipJoints: lipJoints,
    );
  }
  return totalFaceJoints == 0 ? 0 : (aligned * 1000) ~/ totalFaceJoints;
}

int _countApproximatelyAlignedJoints({
  required Set<int> faceJoints,
  required Set<int> lipJoints,
}) {
  const tolerancePx = 2;
  final orderedFaceJoints = faceJoints.toList(growable: false)..sort();
  final orderedLipJoints = lipJoints.toList(growable: false)..sort();
  var faceIndex = 0;
  var lipIndex = 0;
  var aligned = 0;
  while (faceIndex < orderedFaceJoints.length &&
      lipIndex < orderedLipJoints.length) {
    final delta = orderedFaceJoints[faceIndex] - orderedLipJoints[lipIndex];
    if (delta.abs() <= tolerancePx) {
      aligned += 1;
      faceIndex += 1;
      lipIndex += 1;
    } else if (delta < 0) {
      faceIndex += 1;
    } else {
      lipIndex += 1;
    }
  }
  return aligned;
}

List<_StoneChainTopologicalRun> _stoneChainTopologicalRuns({
  required BorderStrokeGeometry geometry,
  required BorderLineSide lineSide,
}) {
  final sideSign = lineSide == BorderLineSide.primary ? 1 : -1;
  final runs = <_StoneChainTopologicalRun>[];
  for (final stroke in geometry.strokes) {
    final edges = <_StoneChainTopologicalEdge>[];
    final edgeCount =
        stroke.closed ? stroke.points.length : stroke.points.length - 1;
    for (var index = 0; index < edgeCount; index += 1) {
      final start = stroke.points[index];
      final end = stroke.points[(index + 1) % stroke.points.length];
      final tangent = StoneChainAxis(
        dx: end.x - start.x,
        dy: end.y - start.y);
      edges.add(
        _StoneChainTopologicalEdge(
          start: start,
          end: end,
          normal: StoneChainAxis(
            dx: -tangent.dy * sideSign,
            dy: tangent.dx * sideSign,
          ),
        ),
      );
    }
    final edgeGroups = <List<_StoneChainTopologicalEdge>>[];
    for (final edge in edges) {
      if (edgeGroups.isEmpty ||
          !_sameStoneChainAxis(edgeGroups.last.first.normal, edge.normal)) {
        edgeGroups.add(<_StoneChainTopologicalEdge>[edge]);
      } else {
        edgeGroups.last.add(edge);
      }
    }
    if (stroke.closed &&
        edgeGroups.length > 1 &&
        _sameStoneChainAxis(
          edgeGroups.first.first.normal,
          edgeGroups.last.first.normal,
        )) {
      edgeGroups.first.insertAll(0, edgeGroups.removeLast());
    }
    for (var ordinal = 0; ordinal < edgeGroups.length; ordinal += 1) {
      final group = edgeGroups[ordinal];
      runs.add(
        _StoneChainTopologicalRun(
          key: (
            strokeId: stroke.id,
            ordinal: ordinal,
            normalDx: group.first.normal.dx,
            normalDy: group.first.normal.dy,
          ),
          normal: group.first.normal,
          stations: <GridPos>{
            for (final edge in group) edge.start,
            for (final edge in group) edge.end,
          },
        ),
      );
    }
  }
  return runs;
}

_StoneChainTopologicalRun? _stoneChainTopologicalRunFor({
  required List<_StoneChainTopologicalRun> runs,
  required GridPos station,
  required StoneChainAxis normal,
  required bool isTurnFace,
  required _StoneChainPublicationRunKey? turnRunKey,
}) {
  for (final run in runs) {
    if (_sameStoneChainAxis(run.normal, normal) &&
        run.stations.contains(station)) {
      return run;
    }
  }
  if (!isTurnFace || turnRunKey == null) return null;

  // Turn-face slots encode the vertex and pass: rank zero designates the
  // incoming run, rank one the outgoing run. This remains unambiguous even
  // when the shoulder cell is equally close to parallel neighbours. Still
  // require a real one-cell shoulder so a malformed slot cannot make a
  // genuinely detached placement look connected.
  for (final run in runs) {
    if (run.key == turnRunKey &&
        _sameStoneChainAxis(run.normal, normal) &&
        _isOneTangentCellFromRun(station: station, run: run)) {
      return run;
    }
  }
  return null;
}

Map<String, _StoneChainPublicationRunKey?> _stoneChainTurnFaceRuns({
  required String featureId,
  required BorderStrokeGeometry geometry,
  required BorderLineSide lineSide,
  required List<_StoneChainTopologicalRun> runs,
}) {
  final result = <String, _StoneChainPublicationRunKey?>{};
  final sideSign = lineSide == BorderLineSide.primary ? 1 : -1;
  for (final stroke in geometry.strokes) {
    final firstTurnIndex = stroke.closed ? 0 : 1;
    final endTurnIndex =
        stroke.closed ? stroke.points.length : stroke.points.length - 1;
    for (var index = firstTurnIndex; index < endTurnIndex; index += 1) {
      final previous = stroke
          .points[(index - 1 + stroke.points.length) % stroke.points.length];
      final vertex = stroke.points[index];
      final next = stroke.points[(index + 1) % stroke.points.length];
      final incoming = StoneChainAxis(
        dx: vertex.x - previous.x,
        dy: vertex.y - previous.y,
      );
      final outgoing = StoneChainAxis(
        dx: next.x - vertex.x,
        dy: next.y - vertex.y,
      );
      if (_sameStoneChainAxis(incoming, outgoing)) continue;
      void registerTurnFaceRun({
        required StoneChainAxis tangent,
        required GridPos edgeStart,
        required GridPos edgeEnd,
        required int rank,
      }) {
        final normal = StoneChainAxis(
          dx: -tangent.dy * sideSign,
          dy: tangent.dx * sideSign,
        );
        final candidates = runs
            .where(
              (run) =>
                  run.key.strokeId == stroke.id &&
                  _sameStoneChainAxis(run.normal, normal) &&
                  run.stations.contains(edgeStart) &&
                  run.stations.contains(edgeEnd),
            )
            .toList(growable: false);
        final slotKey = buildBorderStoneChainNodeSlotKey(
          featureId: featureId,
          strokeId: borderStrokeLineageNamespaceV1(stroke.id),
          vertex: vertex,
          passIndex: 1,
          role: BorderPrimitiveRole.structureMedium,
          rank: rank,
        );
        result[slotKey] = candidates.length == 1 ? candidates.single.key : null;
      }

      registerTurnFaceRun(
        tangent: incoming,
        edgeStart: previous,
        edgeEnd: vertex,
        rank: 0,
      );
      registerTurnFaceRun(
        tangent: outgoing,
        edgeStart: vertex,
        edgeEnd: next,
        rank: 1,
      );
    }
  }
  return result;
}

bool _isOneTangentCellFromRun({
  required GridPos station,
  required _StoneChainTopologicalRun run,
}) =>
    run.stations.any((candidate) {
      final dx = station.x - candidate.x;
      final dy = station.y - candidate.y;
      return dx.abs() + dy.abs() == 1 &&
          dx * run.normal.dx + dy * run.normal.dy == 0;
    });

bool _sameStoneChainAxis(StoneChainAxis left, StoneChainAxis right) =>
    left.dx == right.dx && left.dy == right.dy;

Map<_StoneChainPublicationRunKey, Set<int>> _stoneChainJointCoordinatesByRun(
  List<_StoneChainPublicationPlacement> placements,
) {
  final runs = _stoneChainPublicationRuns(placements);
  return <_StoneChainPublicationRunKey, Set<int>>{
    for (final entry in runs.entries)
      entry.key: _stoneChainJointCoordinates(entry.value),
  };
}

Map<_StoneChainPublicationRunKey, List<_StoneChainPublicationPlacement>>
    _stoneChainPublicationRuns(
  List<_StoneChainPublicationPlacement> placements) {
  final runs =
      <_StoneChainPublicationRunKey, List<_StoneChainPublicationPlacement>>{};
  for (final placement in placements) {
    (runs[placement.runKey] ??= <_StoneChainPublicationPlacement>[]).add(
      placement,
    );
  }
  return runs;
}

Set<int> _stoneChainJointCoordinates(
  List<_StoneChainPublicationPlacement> placements,
) {
  final ordered = placements.toList(growable: false)
    ..sort((left, right) {
      final byProjection = _minimumBoundsProjection(
        left.placement.opaqueWorldBoundsPx,
        left.tangent,
      ).compareTo(
        _minimumBoundsProjection(
          right.placement.opaqueWorldBoundsPx,
          right.tangent,
        ),
      );
      return byProjection != 0
          ? byProjection
          : left.placement.slotKey.compareTo(right.placement.slotKey);
    });
  return <int>{
    for (var index = 1; index < ordered.length; index += 1)
      (_maximumBoundsProjection(
                ordered[index - 1].placement.opaqueWorldBoundsPx,
                ordered[index - 1].tangent,
              ) +
              _minimumBoundsProjection(
                ordered[index].placement.opaqueWorldBoundsPx,
                ordered[index].tangent,
              )) ~/
          2,
  };
}

({StoneChainAxis normal, StoneChainAxis tangent})? _stoneChainAxesFor(
  BorderPrimitiveOrientation authored,
  int quarterTurns,
) {
  if (authored == BorderPrimitiveOrientation.legacyAxis) return null;
  final authoredRank = switch (authored) {
    BorderPrimitiveOrientation.east => 0,
    BorderPrimitiveOrientation.south => 1,
    BorderPrimitiveOrientation.west => 2,
    BorderPrimitiveOrientation.north => 3,
    BorderPrimitiveOrientation.legacyAxis => throw StateError('unreachable'),
  };
  return switch ((authoredRank + quarterTurns) % 4) {
    0 => (
        normal: StoneChainAxis(dx: 1, dy: 0),
        tangent: StoneChainAxis(dx: 0, dy: -1),
      ),
    1 => (
        normal: StoneChainAxis(dx: 0, dy: 1),
        tangent: StoneChainAxis(dx: 1, dy: 0),
      ),
    2 => (
        normal: StoneChainAxis(dx: -1, dy: 0),
        tangent: StoneChainAxis(dx: 0, dy: 1),
      ),
    3 => (
        normal: StoneChainAxis(dx: 0, dy: -1),
        tangent: StoneChainAxis(dx: -1, dy: 0),
      ),
    _ => throw StateError('unreachable'),
  };
}

int _minimumBoundsProjection(BorderPixelRect bounds, StoneChainAxis axis) =>
    _boundsProjections(bounds, axis).reduce(_minimumInt);

int _maximumBoundsProjection(BorderPixelRect bounds, StoneChainAxis axis) =>
    _boundsProjections(bounds, axis).reduce(_maximumInt);

List<int> _boundsProjections(BorderPixelRect bounds, StoneChainAxis axis) =>
    <int>[
      bounds.x * axis.dx + bounds.y * axis.dy,
      (bounds.right - 1) * axis.dx + bounds.y * axis.dy,
      bounds.x * axis.dx + (bounds.bottom - 1) * axis.dy,
      (bounds.right - 1) * axis.dx + (bounds.bottom - 1) * axis.dy,
    ];

int _minimumInt(int left, int right) => left < right ? left : right;

int _maximumInt(int left, int right) => left > right ? left : right;

int _integerMedian(List<int> sortedValues) {
  if (sortedValues.isEmpty) return 0;
  final middle = sortedValues.length ~/ 2;
  return sortedValues.length.isOdd
      ? sortedValues[middle]
      : (sortedValues[middle - 1] + sortedValues[middle]) ~/ 2;
}

enum _StoneChainPublicationRow { lip, face }

typedef _StoneChainPublicationRunKey = ({
  String strokeId,
  int ordinal,
  int normalDx,
  int normalDy,
});

final class _StoneChainTopologicalEdge {
  const _StoneChainTopologicalEdge({
    required this.start,
    required this.end,
    required this.normal,
  });

  final GridPos start;
  final GridPos end;
  final StoneChainAxis normal;
}

final class _StoneChainTopologicalRun {
  _StoneChainTopologicalRun({
    required this.key,
    required this.normal,
    required Set<GridPos> stations,
  }) : stations = Set<GridPos>.unmodifiable(stations);

  final _StoneChainPublicationRunKey key;
  final StoneChainAxis normal;
  final Set<GridPos> stations;
}

final class _StoneChainPublicationPlacement {
  const _StoneChainPublicationPlacement({
    required this.placement,
    required this.primitive,
    required this.row,
    required this.runKey,
    required this.normal,
    required this.tangent,
  });

  final BorderResolvedPlacement placement;
  final BorderPublishedPrimitive primitive;
  final _StoneChainPublicationRow row;
  final _StoneChainPublicationRunKey runKey;
  final StoneChainAxis normal;
  final StoneChainAxis tangent;

  String get strokeId => runKey.strokeId;

  StoneChainPlacedMask get mask => StoneChainPlacedMask(
        metrics: primitive.publishedMetrics,
        transform: placement.transform,
        topLeftWorldPx: placement.topLeftWorldPx,
      );
}

final class _StoneChainPublicationMeasurement {
  const _StoneChainPublicationMeasurement({
    required this.evidence,
    required this.lipCoverage,
    required this.faceCoverage,
  });

  final BorderPublicationStoneChainEvidence evidence;
  final ({int gap, int overlap}) lipCoverage;
  final ({int gap, int overlap}) faceCoverage;

  ({int gap, int overlap}) coverageFor(
    BorderCanonicalCoverageComponent component,
  ) =>
      switch (component) {
        BorderCanonicalCoverageComponent.lip => lipCoverage,
        BorderCanonicalCoverageComponent.face => faceCoverage,
        _ => throw const ValidationException(
            'Two-tier coverage only supports lip and face components',
          ),
      };
}

BorderPublicationCoverageCheck _masonryCoverageCheck(
  MasonryLineBorderResolutionEvidence evidence,
  BorderGenerationParams params,
) =>
    BorderPublicationCoverageCheck(
      component: BorderCanonicalCoverageComponent.primary,
      longestContiguousGapPx: _maximum(
        evidence.edges.map((edge) => edge.longestGapPx),
      ),
      maximumPairwiseOverlapPx: _maximum(
        evidence.edges.map((edge) => edge.maximumPairwiseOverlapPx),
      ),
      gapTolerancePx: params.gapTolerancePx,
      maxOverlapPx: params.maxOverlapPx,
    );

List<BorderPublicationCoverageCheck> _fenceCoverageChecks({
  required BorderCanonicalGalleryCase galleryCase,
  required PostAndRailLineBorderResolutionEvidence evidence,
  required BorderGenerationParams params,
}) {
  final edgesByStroke = <String, List<PostAndRailLineEdgeResolutionEvidence>>{};
  for (final edge in evidence.edges) {
    edgesByStroke
        .putIfAbsent(
            edge.strokeId, () => <PostAndRailLineEdgeResolutionEvidence>[],
        )
        .add(edge);
  }
  final components = borderCanonicalCoverageComponentsForCase(
    template: BorderBlueprintTemplate.postAndRailLine,
    galleryCase: galleryCase,
  );
  return <BorderPublicationCoverageCheck>[
    for (final component in components)
      BorderPublicationCoverageCheck(
        component: component,
        longestContiguousGapPx: _maximum(
          _fenceEdgesForComponent(edgesByStroke, component,
          )
              .map((edge) => edge.longestGapPx),
        ),
        maximumPairwiseOverlapPx: _maximum(
          _fenceEdgesForComponent(edgesByStroke, component,
          )
              .map((edge) => edge.maximumPairwiseOverlapPx),
        ),
        gapTolerancePx: params.gapTolerancePx,
        maxOverlapPx: params.maxOverlapPx,
      ),
  ];
}

List<BorderPublicationCoverageCheck> _connectedLineCoverageChecks({
  required BorderCanonicalGalleryCase galleryCase,
  required BorderGenerationParams params,
  required BorderStrokeGeometry geometry,
  required BorderBlueprintPublishedDefinition definition,
  required BorderResolutionResult primary,
  required BorderResolutionResult inverted,
  required GridSize tileSizePx,
}) {
  final strokesById = <String, BorderStroke>{
    for (final stroke in geometry.strokes) stroke.id: stroke,
  };
  final primitivesById = <String, BorderPublishedPrimitive>{
    for (final primitive in definition.primitives) primitive.id: primitive,
  };
  return <BorderPublicationCoverageCheck>[
    for (final component in borderCanonicalCoverageComponentsForCase(
      template: BorderBlueprintTemplate.connectedLine,
      galleryCase: galleryCase,
    ))
      _connectedLineCoverageCheck(
        component: component,
        strokes: switch (component) {
          BorderCanonicalCoverageComponent.leadingStroke => <BorderStroke>[
              strokesById['leading']!,
          ],
          BorderCanonicalCoverageComponent.trailingStroke => <BorderStroke>[
              strokesById['trailing']!,
          ],
          _ => geometry.strokes,
        },
        primary: primary,
        inverted: inverted,
        primitivesById: primitivesById,
        tileSizePx: tileSizePx,
        params: params,
      ),
  ];
}

BorderPublicationCoverageCheck _connectedLineCoverageCheck({
  required BorderCanonicalCoverageComponent component,
  required List<BorderStroke> strokes,
  required BorderResolutionResult primary,
  required BorderResolutionResult inverted,
  required Map<String, BorderPublishedPrimitive> primitivesById,
  required GridSize tileSizePx,
  required BorderGenerationParams params,
}) {
  final assessments = <({int gap, int overlap})>[
    for (final result in <BorderResolutionResult>[primary, inverted])
      for (final stroke in strokes)
        _connectedLineStrokeCoverage(
          stroke: stroke,
          result: result,
          primitivesById: primitivesById,
          tileSizePx: tileSizePx,
          params: params,
        ),
  ];
  return BorderPublicationCoverageCheck(
    component: component,
    longestContiguousGapPx: _maximum(
      assessments.map((assessment) => assessment.gap),
    ),
    maximumPairwiseOverlapPx: _maximum(
      assessments.map((assessment) => assessment.overlap),
    ),
    gapTolerancePx: params.gapTolerancePx,
    maxOverlapPx: params.maxOverlapPx,
  );
}

({int gap, int overlap}) _connectedLineStrokeCoverage({
  required BorderStroke stroke,
  required BorderResolutionResult result,
  required Map<String, BorderPublishedPrimitive> primitivesById,
  required GridSize tileSizePx,
  required BorderGenerationParams params,
}) {
  final strokeCells = stroke.points.toSet();
  final placements =
      (result.materialization?.placements ?? const <BorderResolvedPlacement>[])
          .where((placement) => strokeCells.contains(placement.anchorCell))
          .toList(growable: false);
  var longestGap = 0;
  var maximumOverlap = 0;
  final edgeCount =
      stroke.closed ? stroke.points.length : stroke.points.length - 1;
  for (var index = 0; index < edgeCount; index += 1) {
    final start = stroke.points[index];
    final end = stroke.points[(index + 1) % stroke.points.length];
    final horizontal = start.y == end.y;
    final startAxis = horizontal
        ? start.x * tileSizePx.width + tileSizePx.width ~/ 2
        : start.y * tileSizePx.height + tileSizePx.height ~/ 2;
    final endAxis = horizontal
        ? end.x * tileSizePx.width + tileSizePx.width ~/ 2
        : end.y * tileSizePx.height + tileSizePx.height ~/ 2;
    final targetStart = startAxis < endAxis ? startAxis : endAxis;
    final targetEnd = startAxis < endAxis ? endAxis : startAxis;
    final edgeLength = targetEnd - targetStart;
    final projections = <BorderStructuralCoverageProjection>[];
    for (final placement in placements) {
      if (placement.anchorCell != start && placement.anchorCell != end) {
        continue;
      }
      final primitive = primitivesById[placement.primitiveId];
      if (primitive == null) continue;
      final clipped = <BorderCoverageInterval>[];
      for (final interval in projectBorderStructuralMaskOntoWorldAxis(
        metrics: primitive.publishedMetrics,
        transform: placement.transform,
        topLeftWorldPx: placement.topLeftWorldPx,
        worldXAxis: horizontal,
      )) {
        final clippedStart =
            interval.startPx > targetStart ? interval.startPx : targetStart;
        final clippedEnd =
            interval.endPx < targetEnd ? interval.endPx : targetEnd;
        if (clippedEnd > clippedStart) {
          clipped.add(
            BorderCoverageInterval(
              startPx: clippedStart - targetStart + 1,
              endPx: clippedEnd - targetStart + 1,
            ),
          );
        }
      }
      if (clipped.isNotEmpty) {
        projections.add(
          BorderStructuralCoverageProjection(
            placementId: placement.id,
            drawBand: placement.drawBand,
            passIndex: placement.stableOrderKey.passIndex,
            intervals: clipped,
          ),
        );
      }
    }
    final assessment = assessBorderLoopCoverage(
      perimeterPx: edgeLength + 2,
      targetIntervals: <BorderCoverageInterval>[
        BorderCoverageInterval(startPx: 1, endPx: edgeLength + 1),
      ],
      projections: projections,
      gapTolerancePx: params.gapTolerancePx,
      maxOverlapPx: params.maxOverlapPx,
    );
    if (assessment.longestContiguousGapPx > longestGap) {
      longestGap = assessment.longestContiguousGapPx;
    }
    if (assessment.maximumPairwiseOverlapPx > maximumOverlap) {
      maximumOverlap = assessment.maximumPairwiseOverlapPx;
    }
  }
  return (gap: longestGap, overlap: maximumOverlap);
}

List<PostAndRailLineEdgeResolutionEvidence> _fenceEdgesForComponent(
  Map<String, List<PostAndRailLineEdgeResolutionEvidence>> edgesByStroke,
  BorderCanonicalCoverageComponent component,
) =>
    edgesByStroke[switch (component) {
      BorderCanonicalCoverageComponent.leadingStroke => 'leading',
      BorderCanonicalCoverageComponent.trailingStroke => 'trailing',
      _ => 'primary',
    }] ??
    const <PostAndRailLineEdgeResolutionEvidence>[];

List<BorderPublicationStructuralRun> _structuralRuns({
  required String caseWire,
  String? idPrefix,
  required BorderResolutionResult result,
  required BorderBlueprintPublishedDefinition definition,
  required BorderStrokeGeometry geometry,
  required Set<BorderPrimitiveRole> acceptedRoles,
}) {
  final rolesByPrimitiveId = <String, BorderPrimitiveRole>{
    for (final primitive in definition.primitives) primitive.id: primitive.role,
  };
  final continuityByCell = _structuralContinuityByCell(geometry);
  final grouped =
      <(String, int, BorderPrimitiveRole, int, int), List<String>>{};
  for (final placement in result.materialization?.placements ??
      const <BorderResolvedPlacement>[]) {
    final role = rolesByPrimitiveId[placement.primitiveId];
    if (role == null || !acceptedRoles.contains(role)) continue;
    final continuity = continuityByCell[placement.anchorCell];
    if (continuity == null) {
      throw const ValidationException(
        'Canonical gallery structural placement must belong to one stroke',
      );
    }
    final nodeRole = role == BorderPrimitiveRole.post ||
        role == BorderPrimitiveRole.lineCap ||
        role == BorderPrimitiveRole.lineStraight ||
        role == BorderPrimitiveRole.lineCorner;
    final segment = nodeRole ? continuity.nodeSegment : continuity.edgeSegment;
    if (segment < 0) {
      throw const ValidationException(
        'Canonical gallery structural placement must belong to one '
        'continuous stroke segment',
      );
    }
    final key = (
      continuity.strokeId,
      segment,
      role,
      placement.transform.quarterTurns,
      placement.stableOrderKey.passIndex,
    );
    grouped.putIfAbsent(key, () => <String>[]).add(placement.primitiveId);
  }
  var index = 0;
  return <BorderPublicationStructuralRun>[
    for (final entry in grouped.entries)
      BorderPublicationStructuralRun(
        id: '${idPrefix ?? caseWire}:run:${index++}',
        role: entry.key.$3,
        quarterTurns: entry.key.$4,
        passIndex: entry.key.$5,
        primitiveIds: entry.value,
      ),
  ];
}

Map<GridPos, _StructuralContinuity> _structuralContinuityByCell(
  BorderStrokeGeometry geometry,
) {
  final result = <GridPos, _StructuralContinuity>{};
  for (final stroke in geometry.strokes) {
    final edgeQuarterTurns = <int>[
      for (var index = 0;
          index <
              (stroke.closed ? stroke.points.length : stroke.points.length - 1);
          index += 1)
        _quarterTurnsBetween(
          stroke.points[index],
          stroke.points[(index + 1) % stroke.points.length],
        ),
    ];
    final edgeSegments = _continuitySegments(
      edgeQuarterTurns,
      circular: stroke.closed,
    );
    final nodeQuarterTurns = <int>[
      for (var index = 0; index < stroke.points.length; index += 1)
        index < edgeQuarterTurns.length
            ? edgeQuarterTurns[index]
            : edgeQuarterTurns.last,
    ];
    final nodeSegments = _continuitySegments(
      nodeQuarterTurns,
      circular: stroke.closed,
    );
    for (var index = 0; index < stroke.points.length; index += 1) {
      result[stroke.points[index]] = _StructuralContinuity(
        strokeId: stroke.id,
        edgeSegment: index < edgeSegments.length ? edgeSegments[index] : -1,
        nodeSegment: nodeSegments[index],
      );
    }
  }
  return result;
}

List<int> _continuitySegments(
  List<int> quarterTurns, {
  required bool circular,
}) {
  final segments = List<int>.filled(quarterTurns.length, 0, growable: false);
  var segment = 0;
  for (var index = 1; index < quarterTurns.length; index += 1) {
    if (quarterTurns[index] != quarterTurns[index - 1]) segment += 1;
    segments[index] = segment;
  }
  if (circular &&
      segments.length > 1 &&
      quarterTurns.first == quarterTurns.last) {
    final wrappedSegment = segments.last;
    for (var index = 0; index < segments.length; index += 1) {
      if (segments[index] == wrappedSegment) segments[index] = 0;
    }
  }
  return segments;
}

int _quarterTurnsBetween(GridPos start, GridPos end) {
  final deltaX = BigInt.from(end.x) - BigInt.from(start.x);
  final deltaY = BigInt.from(end.y) - BigInt.from(start.y);
  if (deltaX == BigInt.one && deltaY == BigInt.zero) return 0;
  if (deltaX == BigInt.zero && deltaY == BigInt.one) return 1;
  if (deltaX == -BigInt.one && deltaY == BigInt.zero) return 2;
  if (deltaX == BigInt.zero && deltaY == -BigInt.one) return 3;
  throw const ValidationException(
    'Canonical gallery structural runs require unit-cardinal strokes',
  );
}

final class _StructuralContinuity {
  const _StructuralContinuity({
    required this.strokeId,
    required this.edgeSegment,
    required this.nodeSegment,
  });

  final String strokeId;
  final int edgeSegment;
  final int nodeSegment;
}

int _maximum(Iterable<int> values) {
  var maximum = 0;
  for (final value in values) {
    if (value > maximum) maximum = value;
  }
  return maximum;
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
