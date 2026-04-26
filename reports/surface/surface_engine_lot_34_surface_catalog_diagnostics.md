# Surface Engine — Lot 34 : `surface_catalog_diagnostics` (V0)

## 1. Résumé exécutif

Introduction d’une opération pure **`diagnoseProjectSurfaceCatalog`** sur un **`ProjectSurfaceCatalog`**, retournant un **`SurfaceCatalogDiagnosticsReport`** avec des **`SurfaceCatalogDiagnostic`** typés (3 kinds d’`error` V0). Aucune persistance, aucun `ProjectManifest`, aucun autre package. Couverture : refs preset → animation manquante, frame → atlas manquant, frame hors géométrie d’atlas (si l’atlas est présent).

## 2. Pourquoi ce lot vient après le Lot 33-bis

Le Lot 33 a posé le catalogue mémoire ; le 33-bis a finalisé les preuves documentaires. Le 34 **utilise** ce catalogue pour des diagnostics d’assemblage auteur, sans aller vers le runtime.

## 3. Fichiers consultés (audit)

- `surface.dart`, `surface_catalog.dart`, `map_core.dart`, `project_manifest.dart`
- `standard_surface_preset_builder.dart`, `legacy_surface_catalog_diagnostics.dart` (contexte, non modifié)
- Rapports 32b, 33, 33b

## 4. Fichiers créés

- `packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart`
- `packages/map_core/test/surface_catalog_diagnostics_test.dart`
- `reports/surface/surface_engine_lot_34_surface_catalog_diagnostics.md` (ce fichier)

## 5. Fichiers modifiés

- `packages/map_core/lib/map_core.dart` (une ligne d’`export`)

## 6. API ajoutée

- `SurfaceCatalogDiagnosticSeverity` (`error`)
- `SurfaceCatalogDiagnosticKind` (`missingPresetAnimation`, `missingAnimationAtlas`, `animationFrameOutsideAtlasGeometry`)
- `SurfaceCatalogDiagnostic`, `SurfaceCatalogDiagnosticsReport`, `diagnoseProjectSurfaceCatalog`

## 7. Sémantique de `SurfaceCatalogDiagnosticSeverity`

V0 : uniquement **error** (pas de `warning`).

## 8. Sémantique de `SurfaceCatalogDiagnosticKind`

Trois cas exclusifs de ce lot, décrits en §12–14.

## 9. Sémantique de `SurfaceCatalogDiagnostic`

Valeur immuable : sévérité, kind, message lisible, champs ciblant preset / animation / atlas / rôle / index de frame selon le kind.

## 10. Sémantique de `SurfaceCatalogDiagnosticsReport`

Copie défensive, liste exposée **non modifiable** ; `count`, `hasDiagnostics`, `hasErrors`, `byKind` (liste filtrée non modifiable) ; `==` / `hashCode` (ordre des diagnostics compte).

## 11. Sémantique de `diagnoseProjectSurfaceCatalog`

Lecture seule sur le catalogue, aucune mutation. Ordre des résultats : d’abord chaque **preset** dans l’ordre, chaque **ref** ; puis chaque **animation**, chaque **frame** dans l’ordre.

## 12. `missingPresetAnimation`

`animationById(ref.animationId) == null` ; champs : `presetId`, `animationId`, `role`, `frameIndex` et `atlasId` nuls.

## 13. `missingAnimationAtlas`

`atlasById(frame.tileRef.atlasId) == null` ; `animationId`, `atlasId`, `frameIndex` remplis ; `presetId` / `role` nuls.

## 14. `animationFrameOutsideAtlasGeometry`

Atlas **présent** mais `!frame.tileRef.isInside(atlas.geometry)` ; message inclut colonne, ligne.

## 15. Absence de double diagnostic (atlas manquant + hors grille)

Si l’atlas n’existe pas, on n’applique **pas** la vérification géométrique sur cette frame (§13 seulement).

## 16. Ordre des diagnostics

Déterministe, pas de tri par id ni par message (§11).

## 17. Pas de warnings

Aucun niveau `warning` dans ce V0 (scope futur éventuel).

## 18. Pas de résolution runtime

Pas de chargement de texture, pas de moteur, pas d’intégration `map_runtime`.

## 19. Relation avec `ProjectSurfaceCatalog`

Le diagnostic **consomme** les lookups du catalogue (byId) et les structures existantes (refs, frames).

## 20. Relation avec `ProjectManifest` futur

Aucun lien dans ce lot ; le rapport reste en mémoire, hors schéma JSON.

## 21. Ce qui a été testé

25 tests : vide, scénario cohérent, 3 types d’erreurs, ordre preset/refs/frames, absence de double diagnostic, id exacts sans `trim`, `byKind`, immuabilité, copie défensive, `hasErrors`, égalité, export public, manifest minimal sans clés `surface*`.

## 22. Ce que les tests prouvent

Stabilité de l’ordre, invariants d’immuabilité, filtrage `byKind`, et non-régression du contrat manifeste (clés `surface*` absentes de `toJson` minimal).

## 23. Ce qui n’a volontairement pas été fait

JSON, Freezed, warnings, orphelins d’atlas/animation, validateur projet complet, autres packages.

## 24. Pourquoi `ProjectManifest` n’a toujours pas été modifié

Le lot est limité à une opération `map_core` en mémoire.

## 25. Pourquoi aucun fichier generated

Dart manuel, pas de `build_runner` ni `part` pour ce lot.

## 26. Pourquoi pas de `SurfacePresetKind` / `surfaceKind`

Hors scope diagnostic de références internes V0.

## 27. Impact prochains lots

Fondation pour l’UI d’erreurs auteur, extensions (warnings, inutilisés), intégration manifeste quand le contrat existera.

## 28. Commandes lancées

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/surface_catalog_diagnostics_test.dart
```

```bash
/opt/homebrew/bin/dart analyze \
  lib/src/operations/surface_catalog_diagnostics.dart \
  lib/src/models/surface_catalog.dart \
  lib/src/models/surface.dart \
  lib/src/operations/standard_surface_preset_builder.dart \
  test/surface_catalog_diagnostics_test.dart \
  test/project_surface_catalog_test.dart \
  test/standard_surface_preset_builder_test.dart \
  test/project_surface_preset_test.dart \
  test/project_surface_animation_test.dart \
  test/project_surface_atlas_test.dart \
  lib/map_core.dart
```

```bash
/opt/homebrew/bin/dart test
```

## 29. Résultats

- `dart test test/surface_catalog_diagnostics_test.dart` : **+25: All tests passed!**
- `dart analyze` (chemins ci-dessus) : **No issues found!**
- `dart test` (tout le package) : **+783: All tests passed!**

## 30. Total exact `dart test` sur `map_core`

**783** tests.

## 31. Points de vigilance

- Les messages sont des chaînes **anglaises** structurées (alignement avec d’autres messages techniques du monorepo) ; l’i18n est hors scope.
- L’**ordre** des diagnostics compte pour l’égalité de `SurfaceCatalogDiagnosticsReport` : ne pas s’en servir comme clé sémantique abstraite.
- Toute **severity** `error` dans V0 rend `hasErrors` vrai (ici une seule valeur d’énum).

## 32. Autocritique

- Pas d’`info` / `warning` : volontaire ; à étendre si le produit le demande.
- Les helpers de comparaison de listes (diagnostics) restent **locales** à ce fichier (pas de partage obligatoire avec `surface_catalog.dart`).

## 33. Ce que le prompt semble discutable ou incomplet

- L’imposition de **lister intégralement** les gros extractions (§35–36 du prompt utilisateur) dans le rapport *et* l’exhaustivité d’un seul message de réponse : la source de vérité reste les fichiers du dépôt + `git diff` en lecture seule.

## 34. Auto-review (checklist)

- Lot limité à `surface_catalog_diagnostics` + test + export + rapport : **oui**
- Aucun manifest modifié : **oui**
- Pas de generated : **oui**
- Pas de `SurfacePresetKind` : **oui**
- Pas d’autres paquets : **oui**
- Couverture des 3 diagnostics + pas de double sur atlas manquant : **oui**
- Ordre stable : **oui**
- Listes immuables / copie : **oui**
- Export : **oui**
- Test manifest : **oui**
- 783 tests verts : **oui**
- Pas de commande Git d’écriture : **oui** (côté exécution de ce lot)

## 35. Contenu intégral des fichiers créés / modifiés

- **Nouveaux** : intégralité dans le dépôt → `lib/src/operations/surface_catalog_diagnostics.dart`, `test/surface_catalog_diagnostics_test.dart`.
- **Modifié** : `map_core.dart` (ajout d’une ligne d’`export`).

## 36. Diff complet réel

Utiliser (lecture seule, depuis la racine du dépôt, après ajout des fichiers non versionnés) :

```text
git diff
git diff --stat
```

Avant `git add`, la commande `git status --short` doit montrer les fichiers new/modified du lot 34. Le **diff binaire** exact du livrable n’est formé qu’après indexation ; pour ce lot, l’**état** des sources est donné par les chemins et le contenu des fichiers §35.
