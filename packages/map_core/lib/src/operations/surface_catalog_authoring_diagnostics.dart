// Surface catalog authoring — agrégation non persistante (Lot 36).
//
// Ce module fournit [diagnoseProjectSurfaceCatalogForAuthoring], un point
// d'entrée **confort** pour l'auteur (éditeur) : un seul rapport combinant
// les **erreurs** de cohérence (Lot 34, [diagnoseProjectSurfaceCatalog]) et
// les **avertissements** d'inutilisation (Lot 35,
// [diagnoseProjectSurfaceCatalogUnusedResources]).
//
// * Ne remplace **pas** les deux fonctions spécialisées : elles restent la
//   source de vérité pour un axe diagnostic isolé.
// * Ordre **volontaire** : d'abord toutes les entrées d'erreur (ordre interne
//   du Lot 34 inchangé), puis toutes les entrées d'avertissement (ordre interne
//   du Lot 35 inchangé).
// * **Aucune** déduplication, **aucune** fusion de messages, **aucun** re-tri.

import '../models/surface_catalog.dart';
import 'surface_catalog_diagnostics.dart';

/// Retourne un [SurfaceCatalogDiagnosticsReport] **auteur** : concaténation
/// des diagnostics d'[diagnoseProjectSurfaceCatalog] puis de
/// [diagnoseProjectSurfaceCatalogUnusedResources], **sans** mutation du
/// [ProjectSurfaceCatalog] et **sans** remplacer un validateur projet complet.
SurfaceCatalogDiagnosticsReport diagnoseProjectSurfaceCatalogForAuthoring(
  ProjectSurfaceCatalog catalog,
) {
  final errors = diagnoseProjectSurfaceCatalog(catalog);
  final warnings = diagnoseProjectSurfaceCatalogUnusedResources(catalog);
  return SurfaceCatalogDiagnosticsReport(
    diagnostics: [
      ...errors.diagnostics,
      ...warnings.diagnostics,
    ],
  );
}
