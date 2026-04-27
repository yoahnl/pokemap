// Surface Studio — détail des presets (Lot 57).
//
// Lecture seule : affiche uniquement [SurfaceStudioReadModel.presets] et les
// champs dérivés de [SurfaceStudioPresetReadModel] (Lot 51). Aucun catalogue
// brut, aucun re-calcul des animations liées ni des rôles, aucun JSON, aucun I/O,
// aucune mutation de manifest.

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';

/// Libellé français pour [SurfaceVariantRole] (affichage auteur, pas le nom d’énum brut).
String surfaceStudioSurfaceVariantRoleLabel(SurfaceVariantRole role) {
  switch (role) {
    case SurfaceVariantRole.isolated:
      return 'Isolé';
    case SurfaceVariantRole.endNorth:
      return 'Fin nord';
    case SurfaceVariantRole.endEast:
      return 'Fin est';
    case SurfaceVariantRole.endSouth:
      return 'Fin sud';
    case SurfaceVariantRole.endWest:
      return 'Fin ouest';
    case SurfaceVariantRole.horizontal:
      return 'Horizontal';
    case SurfaceVariantRole.vertical:
      return 'Vertical';
    case SurfaceVariantRole.cornerNE:
      return 'Coin nord-est';
    case SurfaceVariantRole.cornerSE:
      return 'Coin sud-est';
    case SurfaceVariantRole.cornerSW:
      return 'Coin sud-ouest';
    case SurfaceVariantRole.cornerNW:
      return 'Coin nord-ouest';
    case SurfaceVariantRole.innerCornerNE:
      return 'Coin intérieur nord-est';
    case SurfaceVariantRole.innerCornerSE:
      return 'Coin intérieur sud-est';
    case SurfaceVariantRole.innerCornerSW:
      return 'Coin intérieur sud-ouest';
    case SurfaceVariantRole.innerCornerNW:
      return 'Coin intérieur nord-ouest';
    case SurfaceVariantRole.teeNorth:
      return 'T nord';
    case SurfaceVariantRole.teeEast:
      return 'T est';
    case SurfaceVariantRole.teeSouth:
      return 'T sud';
    case SurfaceVariantRole.teeWest:
      return 'T ouest';
    case SurfaceVariantRole.cross:
      return 'Croix';
  }
}

/// Textes visibles (aucun nom de type interne dans l’UI).
class SurfaceStudioPresetDetailViewLabels {
  const SurfaceStudioPresetDetailViewLabels._();

  static const String title = 'Presets Surface';
  static const String emptyTitle = 'Aucun preset Surface';
  static const String emptyHint =
      'Les presets associent des rôles de surface à des animations.';

  static const String labelIdentifiant = 'Identifiant';
  static const String labelVariantes = 'Variantes';
  static const String labelRoles = 'Rôles';
  static const String labelAnimationsLiees = 'Animations liées';
  static const String labelCouverture = 'Couverture standard';
  static const String labelCategorie = 'Catégorie';
  static const String labelOrdre = 'Ordre';

  static const String categorieAucune = 'Aucune catégorie';
  static const String couverturePleine = 'Rôles standards complets';
  static const String couverturePartielle = 'Rôles standards incomplets';
  static const String aucuneAnimLiee = 'Aucune animation liée';

  static String variantesLigne(int n) {
    if (n <= 1) {
      return '1 variante';
    }
    return '$n variantes';
  }

  static String animationsLieesSummary(int n) {
    if (n <= 0) {
      return aucuneAnimLiee;
    }
    if (n == 1) {
      return '1 animation liée';
    }
    return '$n animations liées';
  }
}

/// Fiches presets **lecture seule** : ordre = [SurfaceStudioReadModel.presets].
class SurfaceStudioPresetDetailView extends StatelessWidget {
  const SurfaceStudioPresetDetailView({
    super.key,
    required this.readModel,
  });

  final SurfaceStudioReadModel readModel;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          SurfaceStudioPresetDetailViewLabels.title,
          style: TextStyle(
            color: label,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        if (readModel.presets.isEmpty) ...[
          Text(
            SurfaceStudioPresetDetailViewLabels.emptyTitle,
            style: TextStyle(
              color: subtle,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            SurfaceStudioPresetDetailViewLabels.emptyHint,
            style: TextStyle(
              color: subtle,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ] else
          ...readModel.presets.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PresetFiche(
                row: row,
                label: label,
                subtle: subtle,
              ),
            ),
          ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context),
          width: 1,
        ),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: child,
    );
  }
}

class _KeyVal extends StatelessWidget {
  const _KeyVal({
    required this.k,
    required this.v,
    required this.valueColor,
  });

  final String k;
  final String v;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '$k : $v',
        style: TextStyle(
          color: valueColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
      ),
    );
  }
}

class _PresetFiche extends StatelessWidget {
  const _PresetFiche({
    required this.row,
    required this.label,
    required this.subtle,
  });

  final SurfaceStudioPresetReadModel row;
  final Color label;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    final animIds = row.referencedAnimationIds;
    final nAnim = animIds.length;
    final roleLabels = row.roles.map(surfaceStudioSurfaceVariantRoleLabel);
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.name,
            style: TextStyle(
              color: label,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          _KeyVal(
            k: SurfaceStudioPresetDetailViewLabels.labelIdentifiant,
            v: row.id,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioPresetDetailViewLabels.labelVariantes,
            v: SurfaceStudioPresetDetailViewLabels.variantesLigne(
              row.variantCount,
            ),
            valueColor: label,
          ),
          const SizedBox(height: 4),
          Text(
            SurfaceStudioPresetDetailViewLabels.labelRoles,
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          ...roleLabels.map(
            (r) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                r,
                style: TextStyle(
                  color: label,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            SurfaceStudioPresetDetailViewLabels.labelAnimationsLiees,
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              SurfaceStudioPresetDetailViewLabels.animationsLieesSummary(
                nAnim,
              ),
              style: TextStyle(
                color: label,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (nAnim > 0)
            ...animIds.map(
              (id) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  id,
                  style: TextStyle(
                    color: label,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            SurfaceStudioPresetDetailViewLabels.labelCouverture,
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              row.coversStandardRoles
                  ? SurfaceStudioPresetDetailViewLabels.couverturePleine
                  : SurfaceStudioPresetDetailViewLabels.couverturePartielle,
              style: TextStyle(
                color: label,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _KeyVal(
            k: SurfaceStudioPresetDetailViewLabels.labelCategorie,
            v: row.categoryId == null || row.categoryId!.isEmpty
                ? SurfaceStudioPresetDetailViewLabels.categorieAucune
                : row.categoryId!,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioPresetDetailViewLabels.labelOrdre,
            v: row.sortOrder.toString(),
            valueColor: label,
          ),
        ],
      ),
    );
  }
}
