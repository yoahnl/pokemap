// Surface Studio — détail des animations (Lot 57).
//
// Lecture seule : affiche uniquement [SurfaceStudioReadModel.animations] et les
// champs dérivés de [SurfaceStudioAnimationReadModel] (Lot 51). Aucun catalogue
// brut, aucun re-calcul des atlas référencés, aucun JSON, aucun I/O, aucune
// mutation de manifest.

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';

/// Textes visibles (aucun nom de type interne dans l’UI).
class SurfaceStudioAnimationDetailViewLabels {
  const SurfaceStudioAnimationDetailViewLabels._();

  static const String title = 'Animations Surface';
  static const String emptyTitle = 'Aucune animation Surface';
  static const String emptyHint =
      'Les animations décrivent les frames utilisées par les surfaces animées.';

  static const String labelIdentifiant = 'Identifiant';
  static const String labelFrames = 'Frames';
  static const String labelDureeTotale = 'Durée totale';
  static const String labelAtlasRef = 'Atlas référencés';
  static const String labelSync = 'Groupe de synchronisation';
  static const String labelCategorie = 'Catégorie';
  static const String labelOrdre = 'Ordre';

  static const String syncAucun = 'Aucun groupe';
  static const String categorieAucune = 'Aucune catégorie';
  static const String aucunAtlas = 'Aucun atlas référencé';

  static String framesLigne(int n) {
    if (n <= 1) {
      return '1 frame';
    }
    return '$n frames';
  }

  static String atlasRefSummary(int n) {
    if (n <= 0) {
      return aucunAtlas;
    }
    if (n == 1) {
      return '1 atlas référencé';
    }
    return '$n atlas référencés';
  }
}

/// Fiches animations **lecture seule** : ordre = [SurfaceStudioReadModel.animations].
class SurfaceStudioAnimationDetailView extends StatelessWidget {
  const SurfaceStudioAnimationDetailView({
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
          SurfaceStudioAnimationDetailViewLabels.title,
          style: TextStyle(
            color: label,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        if (readModel.animations.isEmpty) ...[
          Text(
            SurfaceStudioAnimationDetailViewLabels.emptyTitle,
            style: TextStyle(
              color: subtle,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            SurfaceStudioAnimationDetailViewLabels.emptyHint,
            style: TextStyle(
              color: subtle,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ] else
          ...readModel.animations.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AnimationFiche(
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

class _AnimationFiche extends StatelessWidget {
  const _AnimationFiche({
    required this.row,
    required this.label,
    required this.subtle,
  });

  final SurfaceStudioAnimationReadModel row;
  final Color label;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    final refIds = row.referencedAtlasIds;
    final nAtlas = refIds.length;
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
            k: SurfaceStudioAnimationDetailViewLabels.labelIdentifiant,
            v: row.id,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioAnimationDetailViewLabels.labelFrames,
            v: SurfaceStudioAnimationDetailViewLabels.framesLigne(
              row.frameCount,
            ),
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioAnimationDetailViewLabels.labelDureeTotale,
            v: '${row.totalDurationMs} ms',
            valueColor: label,
          ),
          const SizedBox(height: 4),
          Text(
            SurfaceStudioAnimationDetailViewLabels.labelAtlasRef,
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
              SurfaceStudioAnimationDetailViewLabels.atlasRefSummary(nAtlas),
              style: TextStyle(
                color: label,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (nAtlas > 0)
            ...refIds.map(
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
          _KeyVal(
            k: SurfaceStudioAnimationDetailViewLabels.labelSync,
            v: row.syncGroupId == null || row.syncGroupId!.isEmpty
                ? SurfaceStudioAnimationDetailViewLabels.syncAucun
                : row.syncGroupId!,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioAnimationDetailViewLabels.labelCategorie,
            v: row.categoryId == null || row.categoryId!.isEmpty
                ? SurfaceStudioAnimationDetailViewLabels.categorieAucune
                : row.categoryId!,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioAnimationDetailViewLabels.labelOrdre,
            v: row.sortOrder.toString(),
            valueColor: label,
          ),
        ],
      ),
    );
  }
}
