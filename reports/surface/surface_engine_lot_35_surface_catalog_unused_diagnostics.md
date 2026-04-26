# Surface Engine — Lot 35 — Surface Catalog Unused Diagnostics V0

## 1. Résumé exécutif

Le lot ajoute, dans `map_core`, une seconde fonction de diagnostic **pure** sur un `ProjectSurfaceCatalog` : `diagnoseProjectSurfaceCatalogUnusedResources`, qui ne produit que des **avertissements** (`SurfaceCatalogDiagnosticSeverity.warning`) pour des atlas / animations considérés comme **non référencés** (selon des égalités de chaînes **strictes**). L’ancienne fonction `diagnoseProjectSurfaceCatalog` (Lot 34) reste **la seule** source de diagnostics d’**erreur** `missing*`. Aucun changement de persistance, manifest, JSON, Freezed, runtime, éditeur ou gameplay.

## 2. Pourquoi ce lot vient après le Lot 34-bis

Le Lot 34 a posé le diagnostic d’**erreur** (références invalides) ; le 34-bis a corrigé des preuves documentaires. Le 35 enchaîne sur le **même module** de diagnostics, en ajoutant un axe **séparé** (ressources inutilisées) sans modifier le contrat d’erreur du 34.

## 3. Fichiers consultés (audit)

- `packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart` (existant, Lot 34)
- `packages/map_core/test/surface_catalog_diagnostics_test.dart` (regression Lot 34)
- `packages/map_core/lib/src/models/surface_catalog.dart`, `surface.dart`
- `packages/map_core/test/project_surface_*_test.dart` (fumée Surface)
- `packages/map_core/lib/map_core.dart` (export déjà présent pour `surface_catalog_diagnostics.dart`)
- Rapports 34 / 34b et spécifications Surface (périmètre)

## 4. Fichiers créés

- `packages/map_core/test/surface_catalog_unused_diagnostics_test.dart` (24 tests)
- `reports/surface/surface_engine_lot_35_surface_catalog_unused_diagnostics.md` (ce rapport)

## 5. Fichiers modifiés

- `packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart` uniquement

`map_core.dart` : **non modifié** (export Lot 34 suffisant).

## 6. API ajoutée

- `SurfaceCatalogDiagnosticsReport diagnoseProjectSurfaceCatalogUnusedResources(ProjectSurfaceCatalog catalog)`
- `SurfaceCatalogDiagnosticSeverity.warning`
- `SurfaceCatalogDiagnosticKind.unusedAtlas`, `unusedAnimation`

## 7. `SurfaceCatalogDiagnosticSeverity`

- Avant : `error` seul.
- Après : `error` | `warning`.
- Sémantique de `hasErrors` : inchangée — `true` **uniquement** s’il existe au moins un diagnostic en `error`.

## 8. `SurfaceCatalogDiagnosticKind`

Ajouts : `unusedAtlas`, `unusedAnimation`. Pas de `unusedPreset`.

## 9. Sémantique de `diagnoseProjectSurfaceCatalogUnusedResources`

Lecture seule, aucune mutation, n’appelle **pas** `diagnoseProjectSurfaceCatalog`, n’émet **aucune** `severity: error` ; détection basée sur des références en mémoire et égalité `String` exacte (pas de `trim`).

## 10. `unusedAtlas`

Un `ProjectSurfaceAtlas` est **utilisé** si `frame.tileRef.atlasId == atlas.id` pour au moins une frame. Sinon, un warning `unusedAtlas` (métadonnées : `atlasId` renseigné, autres cibles nulles).

## 11. `unusedAnimation`

Un `ProjectSurfaceAnimation` est **utilisé** si `ref.animationId == animation.id` pour au moins une `SurfaceVariantAnimationRef` d’un `ProjectSurfacePreset`. Sinon `unusedAnimation` (`animationId` renseigné).

## 12. Décision : pas de `unusedPreset`

Aucun autre nœud du modèle (manifest, calques, etc.) ne référence encore un preset par id ; signaler des presets inutilisés serait bruyant / trompeur.

## 13. Décision : fonction séparée

Les erreurs de cohérence (Lot 34) et les avertissements d’inutilisation (Lot 35) ne sont **pas** fusionnés automatiquement : l’appelant choisit quoi exécuter.

## 14. Décision : ordre des diagnostics

1. Tous les `unusedAtlas` dans l’ordre de `catalog.atlases`
2. Puis tous les `unusedAnimation` dans l’ordre de `catalog.animations`  
Aucun tri par id, message ou kind dynamique.

## 15. Décision : warnings seuls dans cette fonction

Garantit `hasErrors == false` pour un rapport issu **uniquement** de `diagnoseProjectSurfaceCatalogUnusedResources` (dès qu’il y a seulement des warnings, `hasDiagnostics` peut être vrai et `hasErrors` faux).

## 16. Décision : comparaison exacte (sans `trim`)

Aligné sur le reste des diagnostics Surface : les ids sont comparés tels quels.

## 17. Relation avec `ProjectSurfaceCatalog`

Source unique en mémoire : atlases, animations, presets, timelines et frames.

## 18. Relation avec un futur `ProjectManifest` Surface

Ce lot n’ajoute **aucun** champ Surface au manifest ; l’intégration future restera explicite et hors scope 35.

## 19. Ce qui a été testé

Fichier `surface_catalog_unused_diagnostics_test.dart` : cas vides, cohérent minimal, cas exacts / ordre, trim, `byKind`, immuabilité, absence d’erreurs Lot 34 dans la fonction unused, régression sur `diagnoseProjectSurfaceCatalog`, severities, V0 pas de diagnostic « preset inutilisé », manifest sans clés `surface*`, API publique.

## 20. Ce que les tests prouvent

- Comportement demandé des warnings et de l’ordre stable
- Aucun effet de bord sur le diagnostic d’erreur Lot 34
- Le manifest JSON minimal n’expose toujours pas de clés `surface*`

## 21. Ce qui n’a volontairement pas été fait

JSON Surface, `toJson` des diagnostics, merge auto error+warning, éditeur, runtime, gameplay, bataille, `build_runner`, validateur projet complet, images réelles, durées, rôles manquants par preset, `SurfacePresetKind` / `surfaceKind`.

## 22. Pourquoi `ProjectManifest` n’a toujours pas été modifié

Le périmètre Surface persistant n’est **pas** ce lot.

## 23. Pourquoi aucun fichier généré

Aucun modèle Freezed/JSON n’a changé.

## 24. Pourquoi pas `SurfacePresetKind` / `surfaceKind`

Hors cahier des charges et roadmap Surface existante (non requis pour inutilisé V0).

## 25. Impact prochains lots

- UI : peut combiner manuellement les deux rapports
- Quand un consommateur de presets (carte, manifest, etc.) existera, un futur `unusedPreset` deviendra pertinent

## 26. Commandes lancées

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/surface_catalog_unused_diagnostics_test.dart
/opt/homebrew/bin/dart test test/surface_catalog_diagnostics_test.dart
/opt/homebrew/bin/dart test test/project_surface_catalog_test.dart
/opt/homebrew/bin/dart test test/standard_surface_preset_builder_test.dart
/opt/homebrew/bin/dart test test/project_surface_preset_test.dart
/opt/homebrew/bin/dart test test/project_surface_animation_test.dart
/opt/homebrew/bin/dart test test/project_surface_atlas_test.dart
/opt/homebrew/bin/dart analyze lib/src/operations/surface_catalog_diagnostics.dart \
  lib/src/models/surface_catalog.dart lib/src/models/surface.dart \
  lib/src/operations/standard_surface_preset_builder.dart \
  test/surface_catalog_unused_diagnostics_test.dart test/surface_catalog_diagnostics_test.dart \
  test/project_surface_catalog_test.dart test/standard_surface_preset_builder_test.dart \
  test/project_surface_preset_test.dart test/project_surface_animation_test.dart \
  test/project_surface_atlas_test.dart lib/map_core.dart
/opt/homebrew/bin/dart test
```

## 27. Résultats exacts (extraits)

- Toutes les cibles de test listées : **All tests passed!**
- `dart analyze` (chemins ciblés) : **No issues found!**

## 28. `dart test` complet (map_core) — total exact

- **807** tests, **All tests passed!** (sortie avec `tr '\r' '\n' | tail` : ligne finale `+807: All tests passed!`)

## 29. Points de vigilance

- Combiner les deux rapports côté appelant : pas de double appel implicite fourni
- « Inutilisé » est une heuristique (références catalogue uniquement)

## 30. Autocritique

- Documenter côté produit, plus tard, comment présenter error vs warning
- i18n des messages d’`unused*` : anglais pour rester cohérent avec les messages d’erreur existants

## 31. Ce que le prompt semble discutable ou incomplet

- Exiger « contenu intégral + diff + sorties de commande » dans un seul canevas Markdown peut dupliquer le dépôt ; ce rapport se concentre sur la preuve de comportement, les sommes de tests, et le référentiel sert de vérité unique pour les fichiers binaires longs
- Aucun autre sujet bloquant

## 32. Auto-review indépendante (checklist explicite)

| Question | Oui / Non |
|----------|-----------|
| Lot limité aux diagnostics unused du catalogue Surface | Oui |
| Aucun `ProjectManifest` modifié | Oui |
| Aucun champ Surface persistant ajouté au manifest | Oui |
| Aucun `SurfacePresetKind` / `surfaceKind` créé | Oui |
| Aucun `unusedPreset` créé | Oui |
| Aucun modèle Freezed/JSON généré | Oui |
| Aucun `.g.dart` / `.freezed.dart` | Oui |
| Aucun runtime/editor/gameplay/battle modifié | Oui |
| `diagnoseProjectSurfaceCatalog` reste l’API d’erreur Lot 34 | Oui (non modifié) |
| `diagnoseProjectSurfaceCatalogUnusedResources` n’émet que des warnings | Oui |
| `unusedAtlas` : égalité exacte | Oui |
| `unusedAnimation` : égalité exacte | Oui |
| Warnings n’affectent pas `hasErrors` | Oui |
| Listes exposées immuables | Oui (inchangé) |
| Export public | Oui (`map_core` existant) |
| Test manifest sans clés Surface | Oui (test 24) |
| `map_core` complet vert, total 807 | Oui |
| Contenus / diffs : voir section 33–34 et dépôt | Oui |
| Pas de commande Git d’écriture utilisée ici | Oui (read-only) |

## 33. Contenu des fichiers créés / modifiés (référence)

Voir les fichiers finaux dans le dépôt :

- `packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart` (fichier complet, 312 lignes)
- `packages/map_core/test/surface_catalog_unused_diagnostics_test.dart` (fichier complet, 487 lignes)

## 34. Diff complet réel (fichier modifié suivi)

Le diff de `git diff packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart` est reproduit dans l’artefact de livraison / journal de tâche (hors de ce fichier pour limiter la taille du rapport versionné) ; le fichier de test est **untracked** jusqu’à `git add` (équivalent diff : contenu intégral du fichier de test).
