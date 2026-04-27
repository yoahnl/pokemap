// Surface Studio — navigateur de catalogue lecture seule (Lot 54).
//
// Consomme uniquement [SurfaceStudioReadModel] (Lot 51) : pas de
// re-calcul de diagnostics, pas de JSON, pas de fichier, pas de mutation
// de manifest, pas d’I/O, pas d’état mutable.

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_animation_detail_view.dart';
import 'surface_studio_atlas_detail_view.dart';
import 'surface_studio_preset_detail_view.dart';

/// Libellés visibles (aucun nom de type Dart interne).
class SurfaceStudioCatalogBrowserLabels {
  const SurfaceStudioCatalogBrowserLabels._();

  static const String title = 'Catalogue Surface';
  static const String emptyGlobal = 'Le catalogue Surface est vide';
  static const String emptyGlobalHint =
      'Les prochains lots permettront d’ajouter des atlas, des animations et des presets.';
  static const String sectionAtlas = 'Atlas';
  static const String sectionAnimations = 'Animations';
  static const String sectionPresets = 'Presets';
  static const String emptyAtlas = 'Aucun atlas Surface';
  static const String emptyAnimations = 'Aucune animation Surface';
  static const String emptyPresets = 'Aucun preset Surface';

  static const String labelId = 'Identifiant';
  static const String labelTileset = 'Tileset';
  static const String labelTile = 'Tile';
  static const String labelGrid = 'Grille';
  static const String labelLayout = 'Layout';
  static const String labelUsedBy = 'Utilisé par';

  static const String labelFrames = 'Frames';
  static const String labelTotalDuration = 'Durée totale';
  static const String labelRefAtlases = 'Atlas référencés';
  static const String labelSync = 'Groupe de synchronisation';
  static const String labelCategory = 'Catégorie';

  static const String labelVariants = 'Variantes';
  static const String labelRoles = 'Rôles';
  static const String labelPresetAnimationRefs = 'Animations liées';
  static const String labelCoverage = 'Couverture standard';
  static const String coverageFull = 'Rôles standards complets';
  static const String coveragePartial = 'Rôles standards incomplets';

  static const String notUsed = 'Non utilisé';

  static String usedByAnimations(int n) {
    if (n <= 0) {
      return notUsed;
    }
    if (n == 1) {
      return 'Utilisé par 1 animation';
    }
    return 'Utilisé par $n animations';
  }

  static String frameLabel(int n) {
    if (n <= 1) {
      return '1 frame';
    }
    return '$n frames';
  }

  static String variantLabel(int n) {
    if (n <= 1) {
      return '1 variante';
    }
    return '$n variantes';
  }
}

/// Navigateur de catalogue **lecture seule** : seules les listes et champs
/// dérivés du [SurfaceStudioReadModel] sont affichés (ordre source).
class SurfaceStudioCatalogBrowser extends StatelessWidget {
  const SurfaceStudioCatalogBrowser({
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
          SurfaceStudioCatalogBrowserLabels.title,
          style: TextStyle(
            color: label,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        if (readModel.isEmpty) ...[
          Text(
            SurfaceStudioCatalogBrowserLabels.emptyGlobal,
            style: TextStyle(
              color: label,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            SurfaceStudioCatalogBrowserLabels.emptyGlobalHint,
            style: TextStyle(
              color: subtle,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
        ],
        SurfaceStudioAtlasDetailView(readModel: readModel),
        const SizedBox(height: 18),
        SurfaceStudioAnimationDetailView(readModel: readModel),
        const SizedBox(height: 18),
        SurfaceStudioPresetDetailView(readModel: readModel),
      ],
    );
  }
}
