import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show immutable;
import 'package:map_core/map_core.dart';

import '../application/border_preview_transaction.dart';

String localizeEditorBorderDiagnostic(BorderDiagnostic diagnostic) {
  final message = switch (diagnostic.code) {
    'border.resolution.region_empty' => 'Peignez une zone non vide.',
    'border.resolution.region_geometry_required' =>
      'Utilisez une géométrie de zone pour ce blueprint organique.',
    'border.resolution.region_size_mismatch' =>
      'Adaptez la zone aux dimensions actuelles de la carte.',
    'border.resolution.blueprint_unavailable' =>
      'Le blueprint publié est indisponible.',
    'border.resolution.proposal_not_canonical' =>
      'Recréez l’aperçu : sa proposition n’est plus canonique.',
    'border.resolution.template_solver_unavailable' =>
      'Ce type de blueprint ne peut pas encore être résolu sur la carte.',
    'border.resolution.template_mismatch' =>
      'Choisissez un blueprint compatible avec cette géométrie de bordure.',
    'border.resolution.contour_empty' =>
      'Élargissez la zone pour obtenir un contour exploitable.',
    'border.resolution.anchor_outside_asset' =>
      'Replacez l’ancre de l’élément à l’intérieur de son visuel.',
    'border.resolution.duplicate_primitive_id' =>
      'Attribuez un identifiant unique à chaque élément du blueprint.',
    'border.resolution.ground_snapshot_missing' =>
      'Publiez le visuel de sol utilisé par cette bordure.',
    'border.resolution.keep_out_size_mismatch' =>
      'Adaptez les zones d’exclusion aux dimensions de la carte.',
    'border.resolution.keep_outs_not_supported' =>
      'Retirez les zones d’exclusion avant de générer cette bordure linéaire.',
    'border.resolution.linear_ground_not_supported' =>
      'Retirez le sol intérieur : il n’est pas disponible pour une bordure linéaire.',
    'border.resolution.masonry_end_finish_missing' =>
      'Ajoutez une finition d’extrémité adaptée au muret.',
    'border.resolution.masonry_end_finish_outside_canvas' =>
      'Déplacez l’extrémité du muret pour garder sa finition dans la carte.',
    'border.resolution.overrides_not_supported' =>
      'Retirez les remplacements manuels incompatibles avec ce blueprint.',
    'border.resolution.occupancy_empty' =>
      'Ajoutez des pixels opaques au visuel publié.',
    'border.resolution.occupancy_invalid' =>
      'Republiez le visuel avec un masque d’occupation valide.',
    'border.resolution.placement_outside_canvas' =>
      'Déplacez le tracé pour que ses éléments restent visibles dans la carte.',
    'border.resolution.post_role_missing' =>
      'Ajoutez au moins un poteau au blueprint de clôture.',
    'border.resolution.role_not_supported_by_template' =>
      'Attribuez à cet élément un rôle accepté par le type de bordure sélectionné.',
    'border.resolution.structural_role_missing' =>
      'Ajoutez au moins un élément structurel au blueprint.',
    'border.resolution.span_role_missing' =>
      'Ajoutez au moins une traverse au blueprint de clôture.',
    'border.resolution.span_too_short' =>
      'Élargissez ce segment ou choisissez une traverse plus courte.',
    'border.resolution.stroke_geometry_empty' =>
      'Tracez au moins une ligne de deux cases.',
    'border.resolution.stroke_geometry_required' =>
      'Utilisez une géométrie de ligne pour ce blueprint.',
    'border.resolution.stroke_invalid' =>
      'Simplifiez le tracé pour supprimer ses raccords invalides.',
    'border.resolution.stroke_not_canonical' =>
      'Recréez le tracé afin de le remettre dans son ordre canonique.',
    'border.resolution.stroke_out_of_bounds' =>
      'Replacez le tracé entièrement dans les limites de la carte.',
    'border.resolution.structural_occupancy_empty' =>
      'Ajoutez des pixels opaques à l’élément structurel publié.',
    'border.resolution.structural_occupancy_invalid' =>
      'Republiez l’élément structurel avec une empreinte valide.',
    'border.resolution.coverage_gap' =>
      'Réduisez l’ouverture ou ajustez les éléments de bordure.',
    'border.resolution.coverage_overlap' =>
      'Réduisez le chevauchement ou ajustez les éléments de bordure.',
    'border.resolution.connected_line_cap_role_missing' =>
      'Ajoutez au moins une variante au rôle Extrémité.',
    'border.resolution.connected_line_straight_role_missing' =>
      'Ajoutez au moins une variante au rôle Segment droit.',
    'border.resolution.connected_line_corner_role_missing' =>
      'Ajoutez au moins une variante au rôle Angle.',
    'border.resolution.connected_line_transform_unavailable' =>
      'Autorisez la rotation ou le miroir nécessaire pour ce raccord.',
    'border.resolution.connected_line_topology_invalid' =>
      'Simplifiez le tracé pour retirer sa branche ou son croisement.',
    'border.resolution.orientation_unavailable' =>
      'Autorisez l’orientation manquante dans le blueprint.',
    'border.resolution.repetition_four_identical' =>
      'Ajoutez des variantes pour éviter quatre éléments identiques de suite.',
    'border.resolution.repetition_low_window_variety' =>
      'Augmentez la variété des éléments sur cette portion de bordure.',
    'border.resolution.materialization_empty' =>
      'Ajoutez des éléments compatibles pour générer la bordure.',
    'border.resolution.visual_snapshot_invalid' =>
      'Republiez le visuel absent ou invalide utilisé par le blueprint.',
    'invalid_tile_size' =>
      'Choisissez des dimensions de tuile strictement positives.',
    'tile_size_exceeds_portable_integer_range' =>
      'Réduisez les dimensions de tuile à une valeur portable.',
    'old_map_size_out_of_border_rle_bounds' =>
      'Réduisez la carte source aux limites prises en charge.',
    'new_map_size_out_of_border_rle_bounds' =>
      'Choisissez une nouvelle taille de carte prise en charge.',
    'region_size_mismatch' =>
      'Réparez la zone pour qu’elle corresponde à la taille actuelle de la carte.',
    'keep_out_region_size_mismatch' =>
      'Réparez la zone d’exclusion pour qu’elle corresponde à la carte.',
    'materialization_output_fingerprint_invalid' =>
      'Régénérez la bordure avant de redimensionner la carte.',
    'materialization_output_fingerprint_mismatch' =>
      'Régénérez la bordure : son résultat publié a changé.',
    'stroke_points_clipped' =>
      'Le tracé a été coupé aux nouvelles limites de la carte.',
    'stroke_fragment_too_short' =>
      'Un fragment de tracé devenu trop court a été retiré.',
    'stroke_split' => 'Le tracé coupé a été séparé en plusieurs fragments.',
    'stroke_closed_to_open' => 'La boucle coupée est devenue un tracé ouvert.',
    'region_cell_clipped' =>
      'La zone a été coupée aux nouvelles limites de la carte.',
    'keep_out_cell_clipped' =>
      'La zone d’exclusion a été coupée aux nouvelles limites.',
    'region_padding_added' => 'La zone a été agrandie avec des cases vides.',
    'keep_out_padding_added' =>
      'La zone d’exclusion a été agrandie avec des cases vides.',
    'ground_cell_out_of_bounds' => 'Une case de sol hors cadre a été retirée.',
    'placement_anchor_out_of_bounds' =>
      'Un élément dont l’ancre est hors cadre a été retiré.',
    'placement_bounds_out_of_bounds' =>
      'Un élément devenu entièrement hors cadre a été retiré.',
    _ => 'Diagnostic de bordure à vérifier.',
  };
  final location = <String>[
    if (diagnostic.cell case final cell?) 'case ${cell.x}, ${cell.y}',
    if (diagnostic.strokeId case final strokeId?) 'tracé $strokeId',
    if (diagnostic.segmentIndex case final segmentIndex?)
      'segment ${segmentIndex + 1}',
    if (diagnostic.slotKey case final slotKey?) 'emplacement $slotKey',
  ];
  return location.isEmpty ? message : '$message (${location.join(' · ')})';
}

List<BorderDiagnostic> editorBorderPreviewDiagnosticsForMap({
  required MapData map,
  required BorderPreviewTransaction? preview,
}) {
  if (preview == null ||
      preview.mapId != map.id ||
      !identical(preview.context.mapIdentity, map)) {
    return const <BorderDiagnostic>[];
  }
  return preview.result?.diagnosticReport.diagnostics ??
      const <BorderDiagnostic>[];
}

@immutable
final class EditorBorderDiagnosticOverlayMark {
  const EditorBorderDiagnosticOverlayMark({
    required this.cell,
    required this.severity,
  });

  final GridPos cell;
  final BorderDiagnosticSeverity severity;
}

List<EditorBorderDiagnosticOverlayMark> buildEditorBorderDiagnosticOverlayMarks(
  Iterable<BorderDiagnostic> diagnostics,
) {
  final severityByCell = <GridPos, BorderDiagnosticSeverity>{};
  for (final diagnostic in diagnostics) {
    final cell = diagnostic.cell;
    if (cell == null || diagnostic.severity == BorderDiagnosticSeverity.info) {
      continue;
    }
    final previous = severityByCell[cell];
    if (previous == null ||
        borderDiagnosticSeverityV1Rank(diagnostic.severity) <
            borderDiagnosticSeverityV1Rank(previous)) {
      severityByCell[cell] = diagnostic.severity;
    }
  }
  final cells = severityByCell.keys.toList(growable: false)
    ..sort((left, right) {
      final byRow = left.y.compareTo(right.y);
      return byRow != 0 ? byRow : left.x.compareTo(right.x);
    });
  return List<EditorBorderDiagnosticOverlayMark>.unmodifiable(
    cells.map(
      (cell) => EditorBorderDiagnosticOverlayMark(
        cell: cell,
        severity: severityByCell[cell]!,
      ),
    ),
  );
}

@immutable
final class EditorBorderDiagnosticOverlayPalette {
  const EditorBorderDiagnosticOverlayPalette({
    required this.warningFill,
    required this.warningStroke,
    required this.errorFill,
    required this.errorStroke,
  });

  final ui.Color warningFill;
  final ui.Color warningStroke;
  final ui.Color errorFill;
  final ui.Color errorStroke;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorBorderDiagnosticOverlayPalette &&
          warningFill == other.warningFill &&
          warningStroke == other.warningStroke &&
          errorFill == other.errorFill &&
          errorStroke == other.errorStroke;

  @override
  int get hashCode =>
      Object.hash(warningFill, warningStroke, errorFill, errorStroke);
}

void paintEditorBorderDiagnosticOverlay(
  ui.Canvas canvas, {
  required List<EditorBorderDiagnosticOverlayMark> marks,
  required double tileWidth,
  required double tileHeight,
  required double zoom,
  required EditorBorderDiagnosticOverlayPalette palette,
}) {
  if (tileWidth <= 0 || tileHeight <= 0 || zoom <= 0) return;
  for (final mark in marks) {
    final isError = mark.severity == BorderDiagnosticSeverity.error;
    final rect = ui.Rect.fromLTWH(
      mark.cell.x * tileWidth,
      mark.cell.y * tileHeight,
      tileWidth,
      tileHeight,
    ).deflate(1 / zoom);
    canvas.drawRect(
      rect,
      ui.Paint()
        ..isAntiAlias = false
        ..style = ui.PaintingStyle.fill
        ..color = isError ? palette.errorFill : palette.warningFill,
    );
    canvas.drawRect(
      rect,
      ui.Paint()
        ..isAntiAlias = false
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2 / zoom
        ..color = isError ? palette.errorStroke : palette.warningStroke,
    );
  }
}
