// Résumé de la sélection Surface Studio (Lot 58) — **présentation seule**.
//
// Reflète l’état [SurfaceStudioSelection] tenu par le panneau : aucune édition,
// aucun catalogue, pas de persistance, pas de provider.

import 'package:flutter/cupertino.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_selection.dart';

/// En-têtes de résumé visibles (pas de noms de types internes).
class SurfaceStudioSelectionSummaryLabels {
  const SurfaceStudioSelectionSummaryLabels._();

  static const String hint =
      'Sélectionnez un élément du catalogue pour l’inspecter.';

  static const String none = 'Aucune sélection';

  static const String lineAtlas = 'Atlas sélectionné';
  static const String lineAnimation = 'Animation sélectionnée';
  static const String linePreset = 'Preset sélectionné';
}

/// Bloc read-only : ligne d’état + id + texte d’aide.
class SurfaceStudioSelectionSummary extends StatelessWidget {
  const SurfaceStudioSelectionSummary({
    super.key,
    required this.selection,
  });

  final SurfaceStudioSelection selection;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    const accent = Color(0xFF2DD4BF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selection.isNone
              ? EditorChrome.editorIslandRim(context)
              : Color.lerp(
                  EditorChrome.editorIslandRim(context),
                  accent,
                  0.45,
                )!,
          width: selection.isNone ? 1 : 1.2,
        ),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selection.isNone) ...[
            Text(
              SurfaceStudioSelectionSummaryLabels.none,
              style: TextStyle(
                color: subtle,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else ...[
            Text(
              _kindLine(selection),
              style: const TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              selection.id!,
              style: TextStyle(
                color: label,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            SurfaceStudioSelectionSummaryLabels.hint,
            style: TextStyle(
              color: subtle,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

String _kindLine(SurfaceStudioSelection s) {
  if (s.isAtlas) {
    return SurfaceStudioSelectionSummaryLabels.lineAtlas;
  }
  if (s.isAnimation) {
    return SurfaceStudioSelectionSummaryLabels.lineAnimation;
  }
  if (s.isPreset) {
    return SurfaceStudioSelectionSummaryLabels.linePreset;
  }
  return SurfaceStudioSelectionSummaryLabels.none;
}
