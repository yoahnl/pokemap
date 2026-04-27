// Surface Studio — détail des atlas (Lot 56).
//
// Lecture seule : affiche uniquement [SurfaceStudioReadModel.atlases] et les
// champs dérivés de [SurfaceStudioAtlasReadModel] (Lot 51). Aucun catalogue
// brut, aucun re-calcul d’usages, aucun JSON, aucun I/O, aucune mutation de
// manifest.

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';

/// Textes visibles (aucun nom de type de la couche domaine dans l’UI).
class SurfaceStudioAtlasDetailViewLabels {
  const SurfaceStudioAtlasDetailViewLabels._();

  static const String title = 'Atlas Surface';
  static const String emptyTitle = 'Aucun atlas Surface';
  static const String emptyHint =
      'Les atlas définissent les grilles d’images utilisées par les animations '
      'Surface.';

  static const String labelIdentifiant = 'Identifiant';
  static const String labelTileset = 'Tileset';
  static const String labelTile = 'Tile';
  static const String labelGrille = 'Grille';
  static const String labelTuiles = 'Tuiles';
  static const String labelLayout = 'Layout';
  static const String labelCategorie = 'Catégorie';
  static const String labelOrdre = 'Ordre';
  static const String labelUtilisation = 'Utilisation';
  static const String labelAnimationsUtilisatrices = 'Animations utilisatrices';

  static const String categorieAucune = 'Aucune catégorie';

  static String tileCountLigne(int n) {
    if (n <= 1) {
      return '1 tuile';
    }
    return '$n tuiles';
  }

  /// Libellé principal pour le layout d’atlas (aucun nom d’énum en UI).
  static String layoutHumain(SurfaceAtlasLayout layout) {
    switch (layout) {
      case SurfaceAtlasLayout.grid:
        return 'Grille arbitraire (pas d’axes variante/frame imposés)';
      case SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames:
        return 'Colonnes = variantes, lignes = frames';
      case SurfaceAtlasLayout.rowsAreVariantsColumnsAreFrames:
        return 'Lignes = variantes, colonnes = frames';
    }
  }

  static String utilisationLigne(int n) {
    if (n <= 0) {
      return 'Non utilisé';
    }
    if (n == 1) {
      return 'Utilisé par 1 animation';
    }
    return 'Utilisé par $n animations';
  }
}

/// Fiches atlas **lecture seule** : ordre = [SurfaceStudioReadModel.atlases].
class SurfaceStudioAtlasDetailView extends StatelessWidget {
  const SurfaceStudioAtlasDetailView({
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
          SurfaceStudioAtlasDetailViewLabels.title,
          style: TextStyle(
            color: label,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        if (readModel.atlases.isEmpty) ...[
          Text(
            SurfaceStudioAtlasDetailViewLabels.emptyTitle,
            style: TextStyle(
              color: subtle,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            SurfaceStudioAtlasDetailViewLabels.emptyHint,
            style: TextStyle(
              color: subtle,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ] else
          ...readModel.atlases.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AtlasFiche(
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

class _AtlasFiche extends StatelessWidget {
  const _AtlasFiche({
    required this.row,
    required this.label,
    required this.subtle,
  });

  final SurfaceStudioAtlasReadModel row;
  final Color label;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    final nAnim = row.usedByAnimationIds.length;
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
            k: SurfaceStudioAtlasDetailViewLabels.labelIdentifiant,
            v: row.id,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioAtlasDetailViewLabels.labelTileset,
            v: row.tilesetId,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioAtlasDetailViewLabels.labelTile,
            v: '${row.tileWidth}×${row.tileHeight}',
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioAtlasDetailViewLabels.labelGrille,
            v: '${row.columns}×${row.rows}',
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioAtlasDetailViewLabels.labelTuiles,
            v: SurfaceStudioAtlasDetailViewLabels.tileCountLigne(row.tileCount),
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioAtlasDetailViewLabels.labelLayout,
            v: SurfaceStudioAtlasDetailViewLabels.layoutHumain(row.layout),
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioAtlasDetailViewLabels.labelCategorie,
            v: row.categoryId == null || row.categoryId!.isEmpty
                ? SurfaceStudioAtlasDetailViewLabels.categorieAucune
                : row.categoryId!,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioAtlasDetailViewLabels.labelOrdre,
            v: row.sortOrder.toString(),
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioAtlasDetailViewLabels.labelUtilisation,
            v: SurfaceStudioAtlasDetailViewLabels.utilisationLigne(nAnim),
            valueColor: label,
          ),
          if (nAnim > 0) ...[
            const SizedBox(height: 4),
            Text(
              SurfaceStudioAtlasDetailViewLabels.labelAnimationsUtilisatrices,
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
            ...row.usedByAnimationIds.map(
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
          ],
        ],
      ),
    );
  }
}
