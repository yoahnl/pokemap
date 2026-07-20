import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('BorderResolutionRequest', () {
    test('accepts a null revision and empty snapshots as valid draft input',
        () {
      final feature = _feature(materialization: _materialization());
      final request = BorderResolutionRequest(
        mapSize: const GridSize(width: 30, height: 20),
        tileSizePx: const GridSize(width: 16, height: 16),
        blueprintId: 'blueprint-a',
        blueprintRevision: null,
        feature: feature,
        visualSnapshots: const <BorderVisualSnapshot>[],
        resolverVersion: 1,
      );

      expect(request.mapSize, const GridSize(width: 30, height: 20));
      expect(request.tileSizePx, const GridSize(width: 16, height: 16));
      expect(request.blueprintId, 'blueprint-a');
      expect(request.blueprintRevision, isNull);
      expect(request.feature.materialization, isNull);
      expect(request.visualSnapshots, isEmpty);
      expect(request.visualSnapshotById(_snapshotId('a')), isNull);
      expect(request.resolverVersion, 1);
    });

    test('requires positive map and tile dimensions', () {
      for (final sizes in <(GridSize, GridSize)>[
        (
          const GridSize(width: 0, height: 20),
          const GridSize(width: 16, height: 16),
        ),
        (
          const GridSize(width: 30, height: -1),
          const GridSize(width: 16, height: 16),
        ),
        (
          const GridSize(width: 30, height: 20),
          const GridSize(width: 0, height: 16),
        ),
        (
          const GridSize(width: 30, height: 20),
          const GridSize(width: 16, height: -1),
        ),
      ]) {
        expect(
          () => _request(mapSize: sizes.$1, tileSizePx: sizes.$2),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('requires the explicit blueprint id to match the feature', () {
      expect(
        () => _request(blueprintId: 'blueprint-b'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('sorts and freezes unique snapshots and supports lookup', () {
      final snapshotA = _snapshot('a');
      final snapshotB = _snapshot('b');
      final source = <BorderVisualSnapshot>[snapshotB, snapshotA];

      final request = _request(visualSnapshots: source);
      source.clear();

      expect(
        request.visualSnapshots.map((snapshot) => snapshot.id),
        <String>[snapshotA.id, snapshotB.id],
      );
      expect(request.visualSnapshotById(snapshotA.id), same(snapshotA));
      expect(request.visualSnapshotById('missing'), isNull);
      expect(() => request.visualSnapshots.clear(), throwsUnsupportedError);

      expect(
        () => _request(visualSnapshots: <BorderVisualSnapshot>[
          snapshotA,
          snapshotA,
        ]),
        throwsA(isA<ValidationException>()),
      );
    });

    test('requires a positive resolver version', () {
      for (final version in <int>[0, -1]) {
        expect(
          () => _request(resolverVersion: version),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('retains a published revision and has deterministic value semantics',
        () {
      final revision = _revision();
      final snapshotA = _snapshot('a');
      final snapshotB = _snapshot('b');
      final withOldOutput = _request(
        blueprintRevision: revision,
        feature: _feature(materialization: _materialization()),
        visualSnapshots: <BorderVisualSnapshot>[snapshotB, snapshotA],
      );
      final withoutOldOutput = _request(
        blueprintRevision: revision,
        feature: _feature(),
        visualSnapshots: <BorderVisualSnapshot>[snapshotA, snapshotB],
      );

      expect(withOldOutput.blueprintRevision, revision);
      expect(withOldOutput.feature.materialization, isNull);
      expect(withOldOutput, withoutOldOutput);
      expect(withOldOutput.hashCode, withoutOldOutput.hashCode);
    });
  });

  group('BorderResolutionResult', () {
    test('derives success for empty and info-only diagnostics', () {
      final empty = BorderResolutionResult(
        materialization: _materialization(),
        diagnosticReport: const BorderDiagnosticsReport.empty(),
      );
      final info = BorderResolutionResult(
        materialization: _materialization(),
        diagnosticReport: BorderDiagnosticsReport(
          diagnostics: <BorderDiagnostic>[_diagnostic()],
        ),
      );

      expect(empty.status, BorderResolutionStatus.success);
      expect(empty.canApply, isTrue);
      expect(empty.diagnostics, isEmpty);
      expect(info.status, BorderResolutionStatus.success);
      expect(info.canApply, isTrue);
      expect(info.diagnostics, hasLength(1));
    });

    test('derives warning while keeping a materialization applicable', () {
      final report = BorderDiagnosticsReport(
        diagnostics: <BorderDiagnostic>[
          _diagnostic(severity: BorderDiagnosticSeverity.warning),
        ],
      );
      final result = BorderResolutionResult(
        materialization: _materialization(),
        diagnosticReport: report,
      );

      expect(result.status, BorderResolutionStatus.warning);
      expect(result.canApply, isTrue);
      expect(result.diagnosticReport, same(report));
      expect(result.diagnostics, report.diagnostics);
    });

    test('derives error only when materialization is absent', () {
      final report = BorderDiagnosticsReport(
        diagnostics: <BorderDiagnostic>[
          _diagnostic(severity: BorderDiagnosticSeverity.error),
          _diagnostic(severity: BorderDiagnosticSeverity.warning),
        ],
      );
      final result = BorderResolutionResult(
        materialization: null,
        diagnosticReport: report,
      );

      expect(result.status, BorderResolutionStatus.error);
      expect(result.canApply, isFalse);
      expect(result.materialization, isNull);
    });

    test('enforces materialization null exactly when errors exist', () {
      expect(
        () => BorderResolutionResult(
          materialization: null,
          diagnosticReport: const BorderDiagnosticsReport.empty(),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => BorderResolutionResult(
          materialization: _materialization(),
          diagnosticReport: BorderDiagnosticsReport(
            diagnostics: <BorderDiagnostic>[
              _diagnostic(severity: BorderDiagnosticSeverity.error),
            ],
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('has value semantics over materialization and report', () {
      final first = BorderResolutionResult(
        materialization: _materialization(),
        diagnosticReport: BorderDiagnosticsReport(
          diagnostics: <BorderDiagnostic>[
            _diagnostic(severity: BorderDiagnosticSeverity.warning),
          ],
        ),
      );
      final same = BorderResolutionResult(
        materialization: _materialization(),
        diagnosticReport: BorderDiagnosticsReport(
          diagnostics: <BorderDiagnostic>[
            _diagnostic(severity: BorderDiagnosticSeverity.warning),
          ],
        ),
      );
      final different = BorderResolutionResult(
        materialization: _materialization(),
        diagnosticReport: const BorderDiagnosticsReport.empty(),
      );

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(different));
    });
  });
}

BorderResolutionRequest _request({
  GridSize mapSize = const GridSize(width: 30, height: 20),
  GridSize tileSizePx = const GridSize(width: 16, height: 16),
  String blueprintId = 'blueprint-a',
  BorderBlueprintRevision? blueprintRevision,
  BorderFeature? feature,
  Iterable<BorderVisualSnapshot> visualSnapshots =
      const <BorderVisualSnapshot>[],
  int resolverVersion = 1,
}) =>
    BorderResolutionRequest(
      mapSize: mapSize,
      tileSizePx: tileSizePx,
      blueprintId: blueprintId,
      blueprintRevision: blueprintRevision,
      feature: feature ?? _feature(),
      visualSnapshots: visualSnapshots,
      resolverVersion: resolverVersion,
    );

BorderFeature _feature({BorderMaterialization? materialization}) =>
    BorderFeature(
      id: 'feature-a',
      name: 'Côte nord',
      blueprintId: 'blueprint-a',
      seed: BorderSignedInt64.fromInt(7),
      geometry: BorderRegionGeometry(
        width: 2,
        height: 1,
        cells: const <bool>[true, false],
      ),
      paramsOverride: null,
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
      materialization: materialization,
    );

BorderBlueprintRevision _revision() => BorderBlueprintRevision(
      revision: 1,
      definition: BorderBlueprintPublishedDefinition(
        name: 'Côte',
        previewSeed: BorderSignedInt64.fromInt(1),
        template: BorderBlueprintTemplate.organicEdge,
        primitives: const <BorderPublishedPrimitive>[],
        defaults: BorderGenerationParams(
          irregularityPermille: 0,
          detailDensityPermille: 0,
          variationPermille: 0,
          maxOverlapPx: 0,
          gapTolerancePx: 0,
          depthRows: 1,
        ),
        ground: null,
        categoryId: null,
        sortOrder: 0,
      ),
    );

BorderVisualSnapshot _snapshot(String hexDigit) => BorderVisualSnapshot(
      id: _snapshotId(hexDigit),
      contentFingerprint: hexDigit * 64,
      frames: <BorderVisualFrameSnapshot>[
        BorderVisualFrameSnapshot(
          relativeAssetPath: 'assets/borders/snapshots/$hexDigit.png',
          sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
          durationMs: 100,
        ),
      ],
    );

String _snapshotId(String hexDigit) =>
    'border-snapshot-sha256:${hexDigit * 64}';

BorderMaterialization _materialization() => BorderMaterialization(
      receipt: BorderResolutionReceipt(
        resolverVersion: 1,
        blueprintRevision: 1,
        components: BorderInputFingerprints(
          blueprint: _fingerprint('a'),
          geometryAndSeed: _fingerprint('b'),
          parameters: _fingerprint('c'),
          overrides: _fingerprint('d'),
          keepOutRegions: _fingerprint('e'),
          mapContext: _fingerprint('f'),
          visualSnapshots: _fingerprint('0'),
        ),
        inputFingerprint: _fingerprint('1'),
        outputFingerprint: _fingerprint('2'),
      ),
      ground: <BorderResolvedGroundCell>[
        BorderResolvedGroundCell(
          x: 0,
          y: 0,
          visualSnapshotId: _snapshotId('a'),
          resolvedRole: SurfaceVariantRole.isolated,
        ),
      ],
      placements: const <BorderResolvedPlacement>[],
    );

String _fingerprint(String hexDigit) => 'sha256:${hexDigit * 64}';

BorderDiagnostic _diagnostic({
  BorderDiagnosticSeverity severity = BorderDiagnosticSeverity.info,
}) =>
    BorderDiagnostic(
      code: 'border.test',
      severity: severity,
      phase: BorderDiagnosticPhase.resolution,
      scope: BorderDiagnosticScope.feature,
      parameters: const <String, Object?>{},
      suggestedAction: 'border.action.review',
    );
