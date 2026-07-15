import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_transaction.dart';
import 'package:map_editor/src/features/border_map_editing/presentation/border_diagnostic_presentation.dart';

void main() {
  test('localizes known diagnostics and never exposes a raw fallback code', () {
    final known = _diagnostic(
      code: 'border.resolution.region_empty',
      severity: BorderDiagnosticSeverity.error,
    );
    final unknown = _diagnostic(
      code: 'border.test.future_code',
      severity: BorderDiagnosticSeverity.warning,
    );

    expect(localizeEditorBorderDiagnostic(known), 'Peignez une zone non vide.');
    expect(localizeEditorBorderDiagnostic(unknown),
        'Diagnostic de bordure à vérifier.');
    expect(
        localizeEditorBorderDiagnostic(unknown), isNot(contains(unknown.code)));
  });

  test('localizes every diagnostic currently emitted by Border resolution', () {
    const codes = <String>[
      'border.resolution.anchor_outside_asset',
      'border.resolution.blueprint_unavailable',
      'border.resolution.contour_empty',
      'border.resolution.coverage_gap',
      'border.resolution.coverage_overlap',
      'border.resolution.duplicate_primitive_id',
      'border.resolution.ground_snapshot_missing',
      'border.resolution.keep_out_size_mismatch',
      'border.resolution.keep_outs_not_supported',
      'border.resolution.linear_ground_not_supported',
      'border.resolution.masonry_end_finish_missing',
      'border.resolution.masonry_end_finish_outside_canvas',
      'border.resolution.materialization_empty',
      'border.resolution.occupancy_empty',
      'border.resolution.occupancy_invalid',
      'border.resolution.orientation_unavailable',
      'border.resolution.overrides_not_supported',
      'border.resolution.placement_outside_canvas',
      'border.resolution.post_role_missing',
      'border.resolution.proposal_not_canonical',
      'border.resolution.region_empty',
      'border.resolution.region_geometry_required',
      'border.resolution.region_size_mismatch',
      'border.resolution.repetition_four_identical',
      'border.resolution.repetition_low_window_variety',
      'border.resolution.role_not_supported_by_template',
      'border.resolution.span_role_missing',
      'border.resolution.span_too_short',
      'border.resolution.stroke_geometry_empty',
      'border.resolution.stroke_geometry_required',
      'border.resolution.stroke_invalid',
      'border.resolution.stroke_not_canonical',
      'border.resolution.stroke_out_of_bounds',
      'border.resolution.structural_occupancy_empty',
      'border.resolution.structural_occupancy_invalid',
      'border.resolution.structural_role_missing',
      'border.resolution.template_mismatch',
      'border.resolution.template_solver_unavailable',
      'border.resolution.visual_snapshot_invalid',
    ];

    for (final code in codes) {
      final localized = localizeEditorBorderDiagnostic(
        _diagnostic(code: code, severity: BorderDiagnosticSeverity.error),
      );
      expect(localized, isNot('Diagnostic de bordure à vérifier.'),
          reason: code);
      expect(localized, isNot(contains(code)), reason: code);
    }
  });

  test('localizes every diagnostic currently emitted by Border resize', () {
    const codes = <String>[
      'invalid_tile_size',
      'tile_size_exceeds_portable_integer_range',
      'old_map_size_out_of_border_rle_bounds',
      'new_map_size_out_of_border_rle_bounds',
      'region_size_mismatch',
      'keep_out_region_size_mismatch',
      'materialization_output_fingerprint_invalid',
      'materialization_output_fingerprint_mismatch',
      'stroke_points_clipped',
      'stroke_fragment_too_short',
      'stroke_split',
      'stroke_closed_to_open',
      'region_cell_clipped',
      'keep_out_cell_clipped',
      'region_padding_added',
      'keep_out_padding_added',
      'ground_cell_out_of_bounds',
      'placement_anchor_out_of_bounds',
      'placement_bounds_out_of_bounds',
    ];

    for (final code in codes) {
      final localized = localizeEditorBorderDiagnostic(
        _diagnostic(
          code: code,
          severity: BorderDiagnosticSeverity.warning,
        ),
      );
      expect(
        localized,
        isNot('Diagnostic de bordure à vérifier.'),
        reason: code,
      );
      expect(localized, isNot(contains(code)), reason: code);
    }
  });

  test('template mismatch remediation stays compatible with every template',
      () {
    final diagnostic = _diagnostic(
      code: 'border.resolution.template_mismatch',
      severity: BorderDiagnosticSeverity.error,
    );

    expect(
      localizeEditorBorderDiagnostic(diagnostic),
      'Choisissez un blueprint compatible avec cette géométrie de bordure.',
    );
  });

  test('unsupported role remediation stays compatible with every template', () {
    final diagnostic = _diagnostic(
      code: 'border.resolution.role_not_supported_by_template',
      severity: BorderDiagnosticSeverity.error,
    );

    expect(
      localizeEditorBorderDiagnostic(diagnostic),
      'Attribuez à cet élément un rôle accepté par le type de bordure sélectionné.',
    );
  });

  test('builds cell-local warning/error marks and ignores global info', () {
    final marks = buildEditorBorderDiagnosticOverlayMarks(
      <BorderDiagnostic>[
        _diagnostic(
          code: 'border.warning',
          severity: BorderDiagnosticSeverity.warning,
          cell: const GridPos(x: 2, y: 1),
        ),
        _diagnostic(
          code: 'border.error',
          severity: BorderDiagnosticSeverity.error,
          cell: const GridPos(x: 0, y: 3),
        ),
        _diagnostic(
          code: 'border.info',
          severity: BorderDiagnosticSeverity.info,
        ),
      ],
    );

    expect(marks, hasLength(2));
    expect(marks[0].cell, const GridPos(x: 2, y: 1));
    expect(marks[0].severity, BorderDiagnosticSeverity.warning);
    expect(marks[1].cell, const GridPos(x: 0, y: 3));
    expect(marks[1].severity, BorderDiagnosticSeverity.error);
  });

  test('aggregates one mark per cell and lets error dominate warning', () {
    final marks = buildEditorBorderDiagnosticOverlayMarks(
      <BorderDiagnostic>[
        _diagnostic(
          code: 'border.warning',
          severity: BorderDiagnosticSeverity.warning,
          cell: const GridPos(x: 4, y: 2),
        ),
        _diagnostic(
          code: 'border.error',
          severity: BorderDiagnosticSeverity.error,
          cell: const GridPos(x: 4, y: 2),
        ),
        _diagnostic(
          code: 'border.warning.other',
          severity: BorderDiagnosticSeverity.warning,
          cell: const GridPos(x: 1, y: 1),
        ),
      ],
    );

    expect(marks, hasLength(2));
    expect(marks[0].cell, const GridPos(x: 1, y: 1));
    expect(marks[1].cell, const GridPos(x: 4, y: 2));
    expect(marks[1].severity, BorderDiagnosticSeverity.error);
  });

  test('never exposes diagnostics from a preview owned by another map', () {
    final mapA = _diagnosticMap('map-a');
    final mapB = _diagnosticMap('map-b');
    final clonedMapA = MapData.fromJson(mapA.toJson());
    final preview = _preview(
      map: mapA,
      diagnostics: <BorderDiagnostic>[
        _diagnostic(
          code: 'border.resolution.coverage_gap',
          severity: BorderDiagnosticSeverity.error,
          cell: const GridPos(x: 0, y: 0),
        ),
      ],
    );

    expect(
      editorBorderPreviewDiagnosticsForMap(
        map: mapB,
        preview: preview,
      ),
      isEmpty,
    );
    expect(
      editorBorderPreviewDiagnosticsForMap(
        map: mapA,
        preview: preview,
      ),
      hasLength(1),
    );
    expect(
      editorBorderPreviewDiagnosticsForMap(
        map: clonedMapA,
        preview: preview,
      ),
      isEmpty,
      reason: 'same map id must not bypass document identity isolation',
    );
  });

  test('diagnostic overlay paints token-provided warning and error colors',
      () async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    paintEditorBorderDiagnosticOverlay(
      canvas,
      marks: <EditorBorderDiagnosticOverlayMark>[
        const EditorBorderDiagnosticOverlayMark(
          cell: GridPos(x: 0, y: 0),
          severity: BorderDiagnosticSeverity.warning,
        ),
        const EditorBorderDiagnosticOverlayMark(
          cell: GridPos(x: 1, y: 0),
          severity: BorderDiagnosticSeverity.error,
        ),
      ],
      tileWidth: 16,
      tileHeight: 16,
      zoom: 1,
      palette: const EditorBorderDiagnosticOverlayPalette(
        warningFill: ui.Color(0xFF112233),
        warningStroke: ui.Color(0xFF223344),
        errorFill: ui.Color(0xFF445566),
        errorStroke: ui.Color(0xFF556677),
      ),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(32, 16);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    expect(_pixel(bytes!, image.width, 8, 8), const ui.Color(0xFF112233));
    expect(_pixel(bytes, image.width, 24, 8), const ui.Color(0xFF445566));
    picture.dispose();
    image.dispose();
  });
}

BorderPreviewTransaction _preview({
  required MapData map,
  required List<BorderDiagnostic> diagnostics,
}) {
  final mapIdentity = Object();
  return BorderPreviewTransaction(
    context: BorderPreviewContext(
      projectRootPath: '/project',
      activeMapPath: '/project/${map.id}.json',
      projectIdentity: mapIdentity,
      mapIdentity: map,
      borderCatalogFingerprint: 'catalog',
    ),
    mapId: map.id,
    mapSize: const GridSize(width: 1, height: 1),
    layerId: 'border',
    featureId: 'coast',
    baseFeatureFingerprint: 'feature',
    proposedFeature: BorderFeature(
      id: 'coast',
      name: 'Coast',
      blueprintId: 'blueprint',
      seed: BorderSignedInt64.zero,
      geometry: BorderRegionGeometry(
        width: 1,
        height: 1,
        cells: const <bool>[true],
      ),
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
    ),
    variationOrdinal: 0,
    result: BorderResolutionResult(
      materialization: null,
      diagnosticReport: BorderDiagnosticsReport(diagnostics: diagnostics),
    ),
  );
}

MapData _diagnosticMap(String id) => MapData(
      id: id,
      name: id,
      size: const GridSize(width: 1, height: 1),
    );

BorderDiagnostic _diagnostic({
  required String code,
  required BorderDiagnosticSeverity severity,
  GridPos? cell,
}) =>
    BorderDiagnostic(
      code: code,
      severity: severity,
      phase: BorderDiagnosticPhase.resolution,
      scope: BorderDiagnosticScope.feature,
      featureId: 'coast',
      cell: cell,
      suggestedAction: 'border.action.edit_geometry',
    );

ui.Color _pixel(ByteData bytes, int width, int x, int y) {
  final offset = ((y * width) + x) * 4;
  return ui.Color.fromARGB(
    bytes.getUint8(offset + 3),
    bytes.getUint8(offset),
    bytes.getUint8(offset + 1),
    bytes.getUint8(offset + 2),
  );
}
