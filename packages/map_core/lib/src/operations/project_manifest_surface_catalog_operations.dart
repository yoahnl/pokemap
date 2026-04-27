import '../models/project_manifest.dart';
import '../models/surface_catalog.dart';

/// Opérations **pures** sur le champ unique [`ProjectManifest.surfaceCatalog`].
///
/// Couche de **préparation** pour les futurs use cases applicatifs et Surface
/// Studio : évite de répéter `ProjectManifest.copyWith(surfaceCatalog: …)`
/// partout dans le code appelant.
///
/// * **Aucune persistance disque** — pas d’I/O, pas de sérialisation JSON ici.
/// * **Aucun diagnostic** — ne pas appeler [`diagnoseProjectSurfaceCatalog`]
///   ni équivalent ; les appelants lancent les analyses explicitement si besoin.
/// * S’appuie exclusivement sur [`ProjectManifest.copyWith`] pour produire un
///   **nouveau** manifest sans muter l’instance source ni le catalogue source.
/// * Le catalogue Surface reste le seul point d’entrée `surfaceCatalog` sur le
///   manifest (pas de clés éclatées legacy).

/// Expose le [`ProjectSurfaceCatalog`] actuel du [manifest] — **même instance**
/// que [`ProjectManifest.surfaceCatalog`], sans copie ni validation.
ProjectSurfaceCatalog getProjectManifestSurfaceCatalog(ProjectManifest manifest) =>
    manifest.surfaceCatalog;

/// Vrai si [`ProjectSurfaceCatalog.isEmpty`] pour le catalogue du [manifest].
bool projectManifestSurfaceCatalogIsEmpty(ProjectManifest manifest) =>
    manifest.surfaceCatalog.isEmpty;

/// Retourne un **nouveau** [`ProjectManifest`] dont seul [`surfaceCatalog`]
/// est remplacé par [surfaceCatalog] ; tous les autres champs sont préservés.
ProjectManifest replaceProjectManifestSurfaceCatalog(
  ProjectManifest manifest,
  ProjectSurfaceCatalog surfaceCatalog,
) =>
    manifest.copyWith(surfaceCatalog: surfaceCatalog);

/// Applique [update] **une fois** au catalogue courant et remplace
/// `surfaceCatalog` par le résultat. Les exceptions levées par [update] sont
/// **propageées** (aucun catch).
ProjectManifest updateProjectManifestSurfaceCatalog(
  ProjectManifest manifest,
  ProjectSurfaceCatalog Function(ProjectSurfaceCatalog current) update,
) =>
    manifest.copyWith(surfaceCatalog: update(manifest.surfaceCatalog));

/// Remplace le catalogue par un [`ProjectSurfaceCatalog`] **vide**
/// (`ProjectSurfaceCatalog()`).
ProjectManifest clearProjectManifestSurfaceCatalog(ProjectManifest manifest) =>
    manifest.copyWith(surfaceCatalog: ProjectSurfaceCatalog());
