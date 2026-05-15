# Collision Lot 2 — Source of Truth Implementation Plan V0

## 1. Résumé exécutif

Ce lot ne modifie aucun comportement de production. Il transforme l'audit collision V0 en plan d'intervention fichier par fichier.

Verdict court : la priorité n'est pas de créer une nouvelle Collision V2. Le code possède déjà une collision fine locale via `ElementCollisionProfile.collisionMask`, sérialisée sous le nom JSON historique `pixelMask`, et `map_gameplay` la consomme déjà avant `cells`. La priorité des prochains lots est de stabiliser ce contrat :

- `collisionMask` devient la vérité gameplay fine des éléments placés.
- `pixelMask` reste le nom JSON historique.
- `cells` devient projection legacy, fallback et debug coarse.
- la migration des profils legacy doit être pure, centralisée et testée.
- `map_gameplay` doit rester simple : il consomme un profil normalisé et garde son fallback legacy.
- l'éditeur doit arrêter les divergences entre le flux cellule/polygone et le triple mask editor.
- `occlusionMask` reste hors collision : c'est un futur contrat d'occlusion.

Les tests rouges caractérisés confirment le même défaut de contrat : certains profils legacy contiennent des `cells` pleines alors que l'intention auteur est dans `manualAddedCells`; comme `collisionMask` est absent, `map_gameplay` applique le fallback `cells` et bloque trop de pixels.

## 2. Git status initial

Commande exécutée au début du lot :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M examples/playable_runtime_host/ios/Runner.xcodeproj/project.pbxproj
?? packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
?? packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
?? reports/collision/collision_system_audit_v0.md
```

Inventaire initial :

| Catégorie | Fichiers |
|---|---|
| Modifiés avant ce lot | `examples/playable_runtime_host/ios/Runner.xcodeproj/project.pbxproj` |
| Non suivis avant ce lot | `packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart`, `packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart`, `reports/collision/collision_system_audit_v0.md` |
| Créés par ce lot | `reports/collision/collision_lot_2_source_of_truth_implementation_plan.md` |
| Modifiés par ce lot hors rapport | Aucun |
| Supprimés par ce lot | Aucun |
| Generated modifiés par ce lot | Aucun |

## 3. Rappel des conclusions de l’audit V0

Fichier relu :

```text
reports/collision/collision_system_audit_v0.md
```

Conclusions structurantes extraites de l'audit V0 :

| Sujet | Preuve citée de l'audit V0 | Décision pour Collision-2 |
|---|---|---|
| `collisionMask` existe déjà | Section "Verdict court" et sections "Modèle actuel de collision", "Consommation runtime / gameplay" | Ne pas créer un second système fin. Stabiliser celui-ci. |
| `pixelMask` est le nom JSON historique | Sections "Sérialisation / persistance" et "Décision source-of-truth" | Conserver ce nom JSON pour compatibilité. Ne pas renommer en JSON dans les prochains lots. |
| `cells` reste legacy | Sections "Modèle actuel", "Limites actuelles", "Compatibilité V1 -> V2" | Déclasser `cells` en projection/fallback/debug, sans suppression. |
| `map_gameplay` consomme `collisionMask` | Section "Consommation runtime / gameplay" | Garder la priorité `collisionMask`, renforcer les tests. |
| Fallback gameplay sur `cells` | Section "Hitbox joueur et conventions" | Garder ce fallback pour les vieux projets, mais normaliser en amont. |
| Triple mask editor | Sections "Flux d'édition", "Preview / UI actuelle" | Le triple mask editor est le meilleur flux source-of-truth actuel. |
| Editeur cellule/polygone | Sections "Flux d'édition", "Limites actuelles" | Le flux coarse doit cesser de détruire ou diverger de `collisionMask`. |
| Tests rouges | Sections "Tests existants", "Bugs ou comportements suspects" | Créer un lot dédié de triage contractuel avant correction. |
| `occlusionMask` non consommé runtime | Sections "Collision vs occlusion vs interaction", "Risques produit" | Sortir l'occlusion des lots source-of-truth collision. |
| Génération auto et documentation | Sections "Génération automatique actuelle", "Limites actuelles" | Aligner documentation, tests et heuristiques, sans changer le modèle en premier. |

Les sections de l'audit V0 qui justifient les décisions de ce rapport sont :

- `## 2. Verdict court`
- `## 7. Modèle actuel de collision`
- `## 8. Sérialisation / persistance`
- `## 9. Flux d’édition dans map_editor`
- `## 10. Génération automatique actuelle`
- `## 12. Consommation runtime / gameplay`
- `## 13. Hitbox joueur et conventions`
- `## 14. Collision vs occlusion vs interaction`
- `## 15. Tests existants`
- `## 16. Limites actuelles`
- `## 17. Bugs ou comportements suspects`
- `## 20. Architecture cible recommandée`
- `## 21. Stratégie de compatibilité V1 -> V2`

## 4. Commandes exécutées

Commandes Git et audit :

```bash
git status --short --untracked-files=all
```

```bash
python3 - <<'PY'
from pathlib import Path
path = Path('reports/collision/collision_system_audit_v0.md')
print(path.exists(), path.stat().st_size if path.exists() else 0)
PY
```

```bash
rg -n "collisionMask|pixelMask|cells|manualAddedCells|manualRemovedCells|occlusionMask|visualMask|shapeCells|ElementCollisionProfile|PlayerCollisionConventionsV1|worldStaticObstaclesCollidePixelRect|_buildPixelCollisionCache|_buildPlacedElementCellCollisionCache|showCollisionOverlay|FileProjectRepository|ProjectValidator" packages/map_core packages/map_editor packages/map_gameplay packages/map_runtime
```

```bash
python3 - <<'PY'
from pathlib import Path
files = [
  'packages/map_core/lib/src/models/element_collision_profile.dart',
  'packages/map_core/lib/src/operations/element_collision_mask_codec.dart',
  'packages/map_core/lib/src/collision/pixel_rect.dart',
  'packages/map_core/lib/src/collision/player_collision_conventions_v1.dart',
  'packages/map_core/lib/src/operations/map_entity_collision_footprint.dart',
  'packages/map_core/lib/src/models/project_manifest.dart',
  'packages/map_core/lib/src/models/tileset.dart',
  'packages/map_core/lib/src/validation/validators.dart',
  'packages/map_core/lib/src/operations/element_collision_profile_normalizer.dart',
  'packages/map_editor/lib/src/application/services/element_collision_authoring_service.dart',
  'packages/map_editor/lib/src/application/services/element_collision_base_cells_from_padding_service.dart',
  'packages/map_editor/lib/src/application/services/element_collision_cells_overlay_service.dart',
  'packages/map_editor/lib/src/application/services/element_collision_profile_generator.dart',
  'packages/map_editor/lib/src/application/services/element_collision_shape_rasterizer_service.dart',
  'packages/map_editor/lib/src/application/collision_generation/element_visual_occupancy_analyzer.dart',
  'packages/map_editor/lib/src/application/collision_generation/element_visual_occupancy_raster.dart',
  'packages/map_editor/lib/src/application/collision_generation/placed_element_auto_collision_generator.dart',
  'packages/map_editor/lib/src/application/collision_generation/placed_element_collision_params.dart',
  'packages/map_editor/lib/src/application/collision_generation/placed_element_mask_heuristics_v1.dart',
  'packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart',
  'packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/collision/element_collision_editor.dart',
  'packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/collision/element_collision_profile_painter.dart',
  'packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart',
  'packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart',
  'packages/map_gameplay/lib/src/gameplay_world_state.dart',
  'packages/map_gameplay/lib/src/collision/pixel_movement_resolver.dart',
  'packages/map_gameplay/lib/src/gameplay_player_state.dart',
  'packages/map_gameplay/lib/src/gameplay_step.dart',
  'packages/map_gameplay/lib/src/movement_block_reason.dart',
  'packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart',
  'packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart',
  'packages/map_runtime/lib/src/presentation/flame/player_component.dart',
  'packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart',
]
for file in files:
    p = Path(file)
    print(f"{file}: {'exists' if p.exists() else 'MISSING'}" + (f", lines={len(p.read_text().splitlines())}" if p.exists() else ""))
PY
```

Commandes de tests rouges :

```bash
cd packages/map_editor && flutter test --reporter expanded test/project_element_collision_persistence_test.dart
```

```bash
cd packages/map_editor && flutter test --reporter expanded test/project_element_collision_file_repository_roundtrip_test.dart
```

```bash
cd packages/map_gameplay && flutter test --reporter expanded test/placed_elements_collision_test.dart
```

Commande de contrôle après les tests gameplay :

```bash
git status --short --untracked-files=all && git diff --name-only -- packages/map_gameplay/.dart_tool/package_config.json packages/map_gameplay/.dart_tool/package_graph.json
```

Résultat du contrôle `.dart_tool` : aucun nom de fichier imprimé par `git diff --name-only`, donc les tests gameplay lancés avec `flutter test` n'ont pas produit de diff sur les deux fichiers `.dart_tool` historiquement sensibles.

Commandes explicitement non exécutées :

- `build_runner` : interdit par le contrat.
- `git add`, `git commit`, `git reset`, `git restore`, `git checkout`, `git stash`, `git merge`, `git rebase`, `git push`, `git pull`, `git tag`, `git clean` : interdits par le contrat.
- `dart test --reporter expanded test/placed_elements_collision_test.dart` dans `packages/map_gameplay` : remplacé par `flutter test --reporter expanded test/placed_elements_collision_test.dart` pour éviter la modification de fichiers `.dart_tool` déjà observée dans l'audit V0.

## 5. Tests rouges reproduits / caractérisés

### `packages/map_editor/test/project_element_collision_persistence_test.dart`

Commande :

```bash
cd packages/map_editor && flutter test --reporter expanded test/project_element_collision_persistence_test.dart
```

Sortie utile exacte :

```text
test/project_element_collision_persistence_test.dart:163:48: Error: Cannot invoke a non-'const' constructor where a const expression is expected.
  return const ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(),
                                               ^^^^^^^^^^^^^^^^^^^^^
test/project_element_collision_persistence_test.dart:163:16: Error: Cannot invoke a non-'const' factory where a const expression is expected.
  return const ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(),
               ^^^^^^^^^^^^^^^
00:00 +0 -1: Some tests failed.
```

Test rouge :

- Le fichier de test ne compile pas.

Fichier concerné :

- `packages/map_editor/test/project_element_collision_persistence_test.dart`

Cause caractérisée :

- Le helper `_projectManifest()` utilise `const ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(), ...)`.
- `ProjectSurfaceCatalog()` n'est pas un constructeur const dans l'état actuel du code.
- Le test échoue avant toute assertion collision.

Correction recommandée :

- Dans Collision-3, modifier uniquement le test pour supprimer le `const` de `ProjectManifest(...)` et conserver des valeurs immuables là où les constructeurs le permettent.
- Ne pas modifier `ProjectManifest` ni `ProjectSurfaceCatalog` pour satisfaire ce test.

Lot recommandé :

- Collision-3 — Red Tests Triage / Legacy Contract Clarification

### `packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart`

Commande :

```bash
cd packages/map_editor && flutter test --reporter expanded test/project_element_collision_file_repository_roundtrip_test.dart
```

Sortie utile exacte :

```text
Expected: [
            GridPos:x:0, y:3,
            GridPos:x:1, y:3,
            GridPos:x:2, y:3,
            GridPos:x:3, y:3,
            GridPos:x:4, y:3,
            GridPos:x:0, y:4,
            GridPos:x:1, y:4,
            GridPos:x:2, y:4,
            GridPos:x:3, y:4,
            GridPos:x:4, y:4,
            GridPos:x:1, y:5,
            GridPos:x:2, y:5,
            GridPos:x:3, y:5,
            GridPos:x:4, y:5
          ]
  Actual: [
            GridPos:x:0, y:0,
            GridPos:x:1, y:0,
            GridPos:x:2, y:0,
            GridPos:x:3, y:0,
            GridPos:x:4, y:0,
            GridPos:x:0, y:1,
            GridPos:x:1, y:1,
            GridPos:x:2, y:1,
            GridPos:x:3, y:1,
            GridPos:x:4, y:1,
            GridPos:x:0, y:2,
            GridPos:x:1, y:2,
            GridPos:x:2, y:2,
            GridPos:x:3, y:2,
            GridPos:x:4, y:2,
            GridPos:x:0, y:3,
            GridPos:x:1, y:3,
            GridPos:x:2, y:3,
            GridPos:x:3, y:3,
            GridPos:x:4, y:3,
            GridPos:x:0, y:4,
            GridPos:x:1, y:4,
            GridPos:x:2, y:4,
            GridPos:x:3, y:4,
            GridPos:x:4, y:4,
            GridPos:x:0, y:5,
            GridPos:x:1, y:5,
            GridPos:x:2, y:5,
            GridPos:x:3, y:5,
            GridPos:x:4, y:5
          ]
   Which: at location [0] is GridPos:<GridPos(x: 0, y: 0)> instead of GridPos:<GridPos(x: 0, y: 3)>
test/project_element_collision_file_repository_roundtrip_test.dart 33:7
00:00 +0 -1: Some tests failed.
```

Test rouge :

- `FileProjectRepository load migrates legacy element collision profiles before validation`

Fichiers concernés :

- `packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
- futur `packages/map_core/lib/src/operations/element_collision_profile_normalizer.dart`

Cause caractérisée :

- Le JSON legacy testé contient `shapeCells: []`, des `cells` pleines et une intention auteur plus fine dans `manualAddedCells`.
- `FileProjectRepository.loadProject()` exécute `migrateProjectManifestJson(...)`, puis `ProjectManifest.fromJson(...)`, puis `ProjectValidator.validate(...)`.
- Aucun normalizer collision n'est appelé entre `fromJson` et `validate`.
- Le profil reste donc avec `cells` pleines.

Correction recommandée :

- Créer un normalizer pur dans `map_core`.
- Appeler la normalisation collision depuis le chargement repository, après `ProjectManifest.fromJson(...)` et avant validation.
- Le test doit valider que les `cells` du profil chargé deviennent la projection correcte de l'intention legacy, sans modifier `ProjectManifest` ni le codec JSON.

Lot recommandé :

- Collision-4 — Element Collision Profile Normalizer V0
- Collision-6 — Editor Persistence Uses Normalizer

### `packages/map_gameplay/test/placed_elements_collision_test.dart`

Commande exécutée :

```bash
cd packages/map_gameplay && flutter test --reporter expanded test/placed_elements_collision_test.dart
```

Écart par rapport à la commande recommandée :

- La commande recommandée était `dart test --reporter expanded test/placed_elements_collision_test.dart`.
- La commande lancée utilise `flutter test` pour éviter la modification de fichiers `.dart_tool` dans ce package.
- Contrôle exécuté ensuite : `git diff --name-only -- packages/map_gameplay/.dart_tool/package_config.json packages/map_gameplay/.dart_tool/package_graph.json`.
- Résultat : aucun fichier imprimé.

Sortie utile exacte :

```text
00:00 +7 -1: GameplayWorldState placed element collisions legacy broken manual profile is migrated before gameplay reads placed element cells [E]
  Expected: false
    Actual: <true>
  test/placed_elements_collision_test.dart 314:7

00:00 +7 -2: GameplayWorldState placed element collisions gameplay collision uses the placed element id only [E]
  Expected: false
    Actual: <true>
  test/placed_elements_collision_test.dart 373:7
00:00 +8 -2: Some tests failed.
```

Tests rouges :

- `legacy broken manual profile is migrated before gameplay reads placed element cells`
- `gameplay collision uses the placed element id only`

Fichiers concernés :

- `packages/map_gameplay/test/placed_elements_collision_test.dart`
- `packages/map_gameplay/lib/src/gameplay_world_state.dart`
- futur `packages/map_core/lib/src/operations/element_collision_profile_normalizer.dart`

Cause caractérisée :

- `GameplayWorldState._buildPixelCollisionCache(...)` lit `collisionMask` en premier.
- `GameplayWorldState._buildPlacedElementCellCollisionCache(...)` ignore les profils qui ont `collisionMask != null`, puis applique `profile.cells` comme fallback.
- Les tests construisent un profil legacy avec `collisionMask == null` et `cells` pleines.
- Le fallback legacy lit donc les `cells` pleines et bloque le bâtiment au complet.

Correction recommandée :

- Ne pas déplacer une migration complexe dans `map_gameplay`.
- Normaliser les profils en amont avec une fonction pure dans `map_core`.
- Ajouter des tests gameplay qui prouvent que :
  - `collisionMask` gagne contre `cells`;
  - `cells` sert uniquement de fallback lorsque `collisionMask` est absent;
  - un profil legacy déjà normalisé ne bloque pas le toit.

Lot recommandé :

- Collision-3 — Red Tests Triage / Legacy Contract Clarification
- Collision-4 — Element Collision Profile Normalizer V0
- Collision-7 — Gameplay Legacy Fallback Hardening

## 6. Décision source-of-truth recommandée

| Donnée | Statut recommandé | Lecteur principal | Écrivain principal | Rôle |
|---|---|---|---|---|
| `collisionMask` | Vérité gameplay fine | `map_gameplay`, overlay runtime debug | triple mask editor, génération auto, normalizer | Collision fine locale des éléments placés |
| `pixelMask` JSON | Nom legacy conservé | codecs JSON | codecs JSON | Compatibilité des projets existants |
| `cells` | Projection legacy, fallback, debug coarse | fallback gameplay si pas de `collisionMask`, overlay debug | projection depuis mask ou ancien éditeur coarse | Compatibilité coarse |
| `shapeCells` | Intention auteur coarse | éditeur cellule/polygone | éditeur cellule/polygone | Forme auteur avant retouches |
| `manualAddedCells` | Intention auteur coarse | éditeur cellule/polygone, normalizer legacy | éditeur cellule/polygone | Retouches positives |
| `manualRemovedCells` | Intention auteur coarse | éditeur cellule/polygone, normalizer legacy | éditeur cellule/polygone | Retouches négatives |
| `visualMask` | Aide analyse / preview | éditeur | génération auto | Occupation visuelle, non bloquante |
| `occlusionMask` | Future vérité occlusion, pas collision | runtime dans un futur lot | triple mask editor, génération auto | Rendu devant/derrière |

Réponses explicites :

1. Vérité gameplay pour les éléments placés : `collisionMask`.
2. Rôle de `collisionMask` : masque pixel-level local, stampé dans le bitmap monde gameplay.
3. Rôle du nom JSON `pixelMask` : nom persistant historique de `collisionMask`, à conserver.
4. Rôle de `cells` : projection coarse, fallback legacy, debug, compatibilité.
5. Rôle de `shapeCells` : base auteur coarse éditable.
6. Rôle de `manualAddedCells` / `manualRemovedCells` : intention auteur coarse, utilisée par normalisation legacy et éditeur coarse.
7. Rôle de `visualMask` : aide de génération et preview, sans effet collision.
8. Rôle de `occlusionMask` : futur contrat d'occlusion visuelle, séparé de la collision.
9. Qui consomme quoi : gameplay consomme `collisionMask` puis fallback `cells`; runtime debug affiche `collisionMask` puis `cells`; editor consomme toutes les données auteur; runtime de rendu ne consomme pas `occlusionMask`.
10. Qui écrit quoi : triple mask editor et generator écrivent les masks; éditeur cellule/polygone écrit les champs coarse; normalizer écrit des projections cohérentes dans les prochains lots.

## 7. Qui lit quoi / qui écrit quoi

| Package | Lectures actuelles | Écritures actuelles | Décision |
|---|---|---|---|
| `map_core` | Modèle et codecs JSON | Désérialisation via generated/json helpers | Porter le normalizer pur, sans Flutter, sans image analysis. |
| `map_editor` | Tous les champs du profil | `cells`, `shapeCells`, `manualAddedCells`, `manualRemovedCells`, `visualMask`, `collisionMask`, `occlusionMask` selon le flux | Réconcilier les flux auteur et appeler la normalisation au bon niveau repository/service. |
| `map_gameplay` | `collisionMask` puis `cells` fallback | Caches internes pixel/cell | Ne pas ajouter de migration métier. Garder la lecture simple et testée. |
| `map_runtime` | `collisionMask` puis `cells` pour overlay debug | Aucun profil persistant | Ne pas modifier pour source-of-truth. Reporter l'occlusion. |

Constat précis :

- Le flux cellule/polygone écrit surtout `cells` et les champs d'intention coarse.
- Le triple mask editor écrit `collisionMask` et `occlusionMask`, puis reprojette `cells` depuis `collisionMask`.
- La génération auto écrit `visualMask`, `collisionMask`, `occlusionMask`, et laisse `cells` vide.
- `FileProjectRepository.loadProject()` ne normalise pas les profils collision après chargement.
- Le risque d'écrasement vient du service auteur coarse qui reconstruit un `ElementCollisionProfile` sans reprendre explicitement les masks existants.

## 8. Plan fichier par fichier

### `packages/map_core/lib/src/models/element_collision_profile.dart`

**Statut recommandé :**
À modifier

**Rôle actuel :**
Définit `ElementCollisionProfile`, `ElementCollisionMaskType` et `ElementCollisionPixelMask`. Le champ Dart `collisionMask` est sérialisé avec `@JsonKey(name: 'pixelMask')`.

**Problème constaté :**
Les commentaires du fichier indiquent encore que le runtime consomme uniquement `cells`. Cette documentation contredit le gameplay actuel, qui consomme déjà `collisionMask`.

**Pourquoi ce fichier est concerné :**
C'est le contrat de domaine partagé. Les prochains lots doivent rendre le statut source-of-truth lisible dans le modèle sans modifier le JSON.

**Changement recommandé :**
Mettre à jour les commentaires de `ElementCollisionProfile` :
- `collisionMask` = vérité gameplay fine;
- `pixelMask` = nom JSON historique conservé;
- `cells` = projection legacy/fallback/debug;
- `occlusionMask` = occlusion future, non collision.

Ne pas ajouter de champ V2.

**Changement interdit :**
Renommer `pixelMask` dans le JSON, supprimer `cells`, modifier les signatures generated, modifier `ProjectManifest`.

**Dépendances :**
`element_collision_profile_normalizer.dart` proposé, tests JSON existants, `ElementCollisionMaskCodec`.

**Tests à ajouter ou modifier :**
Un test `map_core` qui prouve qu'un profil avec `collisionMask` se sérialise sous `pixelMask` et se relit dans `collisionMask`.

**Risques :**
Un changement de JSON casserait les projets existants.

**Critère d’acceptation :**
Le modèle documente le contrat réel et les tests confirment le nom JSON `pixelMask`.

**Lot recommandé :**
Collision-4

### `packages/map_core/lib/src/operations/element_collision_mask_codec.dart`

**Statut recommandé :**
À modifier plus tard

**Rôle actuel :**
Encode et décode les lignes de mask, valide la cohérence width/height/rows et expose `cellsFromPixelMask(...)`.

**Problème constaté :**
La projection `collisionMask -> cells` existe déjà, mais le contrat officiel "cells est une projection legacy" n'est pas isolé par des tests de source-of-truth.

**Pourquoi ce fichier est concerné :**
Le normalizer doit réutiliser `cellsFromPixelMask(...)` plutôt qu'écrire une projection ad hoc.

**Changement recommandé :**
Ajouter des tests autour de `cellsFromPixelMask(...)` :
- cellule active si un pixel de la tuile est solide;
- dimensions invalides rejetées par decode;
- mask vide donne `cells` vides;
- projection stable avec `tileSize` du profil/projet.

Le code peut rester inchangé si les tests passent.

**Changement interdit :**
Modifier l'encodage compact sans migration JSON, mélanger occlusion et collision dans cette opération.

**Dépendances :**
`ElementCollisionProfile`, futur normalizer.

**Tests à ajouter ou modifier :**
`packages/map_core/test/...element_collision_mask_codec...`

**Risques :**
Changer la projection peut modifier le fallback gameplay et l'overlay runtime.

**Critère d’acceptation :**
La projection mask -> cells devient un contrat testable et stable.

**Lot recommandé :**
Collision-5

### `packages/map_core/lib/src/operations/element_collision_profile_normalizer.dart`

**Statut recommandé :**
À créer dans un futur lot

**Rôle actuel :**
Fichier absent.

**Problème constaté :**
La normalisation attendue par les tests rouges n'a pas de lieu pur et partagé. L'éditeur, la persistance et le gameplay n'ont pas de contrat central pour corriger les profils legacy.

**Pourquoi ce fichier est concerné :**
Le problème doit être résolu dans `map_core`, qui porte les contrats purs, sans dépendance Flutter et sans dépendance image.

**Changement recommandé :**
Créer une fonction pure :

```dart
ElementCollisionProfile normalizeElementCollisionProfile(
  ElementCollisionProfile profile, {
  required int tileSize,
})
```

Responsabilités V0 :
- conserver `collisionMask` lorsqu'il existe;
- si `collisionMask` existe, recalculer `cells` par `ElementCollisionMaskCodec.cellsFromPixelMask(...)`;
- si `collisionMask` est absent et que le profil legacy contient `shapeCells`/`manualAddedCells`/`manualRemovedCells`, reconstruire `cells` depuis l'intention coarse;
- conserver `visualMask` et `occlusionMask` sans les utiliser pour la collision;
- ne pas lire d'image;
- ne pas connaître `ProjectManifest`;
- ne pas connaître `map_editor`;
- ne pas connaître `map_gameplay`.

API complémentaire recommandée :

```dart
ElementCollisionProfile normalizeElementCollisionProfileForLegacyAuthoring(
  ElementCollisionProfile profile, {
  required int tileSize,
})
```

Cette seconde API ne doit être ajoutée que si les tests prouvent qu'une distinction est nécessaire entre projection stricte depuis mask et réparation legacy.

**Changement interdit :**
Créer un modèle V2, introduire Flutter, lire des assets, modifier le JSON, migrer occlusion vers collision.

**Dépendances :**
`ElementCollisionProfile`, `ElementCollisionMaskCodec`, `GridPos`.

**Tests à ajouter ou modifier :**
Tests `map_core` :
- profil avec `collisionMask` et `cells` contradictoires donne `cells` projetées depuis mask;
- profil legacy avec `manualAddedCells` non vide et `cells` pleines donne `cells` reconstruites depuis l'intention auteur;
- `manualRemovedCells` retire les cellules;
- `visualMask` ne change pas `cells`;
- `occlusionMask` ne change pas `cells`;
- dimensions invalides restent gérées par le codec, pas par une logique opaque.

**Risques :**
Une normalisation trop agressive peut modifier d'anciens projets qui dépendaient de `cells` pleines. Le lot doit définir des conditions d'activation strictes et les documenter dans les tests.

**Critère d’acceptation :**
Les tests rouges de repository/gameplay peuvent être corrigés en appelant cette fonction, sans changement de modèle persistant.

**Lot recommandé :**
Collision-4

### `packages/map_core/lib/src/collision/pixel_rect.dart`

**Statut recommandé :**
À ne pas modifier

**Rôle actuel :**
Représente des rectangles pixel-level avec opérations d'intersection et translation.

**Problème constaté :**
Aucun problème source-of-truth identifié.

**Pourquoi ce fichier est concerné :**
Il participe à la hitbox joueur et au resolver pixel, mais pas à la divergence `cells`/`collisionMask`.

**Changement recommandé :**
Aucun.

**Changement interdit :**
Modifier les coordonnées ou les règles d'intersection dans un lot source-of-truth.

**Dépendances :**
`PlayerCollisionConventionsV1`, `PixelMovementResolverV1`.

**Tests à ajouter ou modifier :**
Aucun dans Collision-3 à Collision-6. Garder les tests existants si présents.

**Risques :**
Un changement ici modifierait le déplacement joueur au-delà du périmètre.

**Critère d’acceptation :**
Le fichier reste inchangé.

**Lot recommandé :**
Hors lot

### `packages/map_core/lib/src/collision/player_collision_conventions_v1.dart`

**Statut recommandé :**
À auditer seulement

**Rôle actuel :**
Définit la convention de hitbox joueur. L'audit V0 indique une hitbox pieds de 12x8 px.

**Problème constaté :**
La convention existe et fonctionne avec le resolver pixel. Aucun défaut source-of-truth des éléments placés n'est localisé ici.

**Pourquoi ce fichier est concerné :**
Les tests gameplay doivent continuer à prouver que la hitbox 12x8 interagit avec `collisionMask`.

**Changement recommandé :**
Aucun changement dans les lots de normalisation. Ajouter plus tard une preview editor de cette hitbox, sans modifier la convention.

**Changement interdit :**
Changer les dimensions pour masquer les défauts legacy.

**Dépendances :**
`GameplayPlayerState`, `PixelMovementResolverV1`.

**Tests à ajouter ou modifier :**
Tests gameplay de non-régression de la hitbox actuelle.

**Risques :**
Un changement de hitbox transformerait des tests source-of-truth en tests de gameplay.

**Critère d’acceptation :**
Collision-7 garde les dimensions et les tests prouvent la compatibilité.

**Lot recommandé :**
Collision-7, puis Collision-9 pour preview.

### `packages/map_core/lib/src/operations/map_entity_collision_footprint.dart`

**Statut recommandé :**
À ne pas modifier

**Rôle actuel :**
Calcule des footprints d'entités sur la grille.

**Problème constaté :**
Le problème actuel concerne les éléments placés et `ElementCollisionProfile`, pas les footprints d'entités.

**Pourquoi ce fichier est concerné :**
Il appartient au périmètre collision, mais pas à la source-of-truth des placed elements.

**Changement recommandé :**
Aucun.

**Changement interdit :**
Fusionner footprint entité et masks d'éléments placés.

**Dépendances :**
Opérations map/entity existantes.

**Tests à ajouter ou modifier :**
Aucun dans les lots Collision-3 à Collision-8.

**Risques :**
Mélanger les deux modèles créerait une migration inutile.

**Critère d’acceptation :**
Le fichier reste inchangé.

**Lot recommandé :**
Hors lot

### `packages/map_core/lib/src/models/project_manifest.dart`

**Statut recommandé :**
À ne pas modifier

**Rôle actuel :**
Porte `ProjectManifest` et les entrées de projet, dont `ProjectElementEntry.collisionProfile`.

**Problème constaté :**
Le test rouge de persistance peut donner envie de modifier le manifest. Ce serait une correction au mauvais niveau.

**Pourquoi ce fichier est concerné :**
Il contient le champ persistant, mais le schéma n'est pas la cause de la divergence.

**Changement recommandé :**
Aucun changement de modèle. Le normalizer doit traiter les valeurs après désérialisation.

**Changement interdit :**
Ajouter un champ V2, modifier `ProjectElementEntry`, modifier `ProjectManifest` pour rendre un test const, changer les defaults JSON.

**Dépendances :**
`FileProjectRepository`, generated JSON.

**Tests à ajouter ou modifier :**
Tests de repository et tests JSON autour du profil, sans toucher au manifest.

**Risques :**
Modifier le manifest impose un lot de migration beaucoup plus large.

**Critère d’acceptation :**
Les tests rouges passent dans les lots futurs sans modification de `ProjectManifest`.

**Lot recommandé :**
Collision-3 et Collision-6 comme fichier explicitement non modifié.

### `packages/map_core/lib/src/models/tileset.dart`

**Statut recommandé :**
À ne pas modifier

**Rôle actuel :**
Modèle tileset. Il n'est pas la source du profil collision élément.

**Problème constaté :**
Aucun problème source-of-truth identifié.

**Pourquoi ce fichier est concerné :**
Présent dans le périmètre initial, utile pour vérifier qu'il n'y a pas une seconde source de collision.

**Changement recommandé :**
Aucun.

**Changement interdit :**
Ajouter de la collision élément dans tileset pour contourner `ProjectElementEntry`.

**Dépendances :**
Modèles tileset existants.

**Tests à ajouter ou modifier :**
Aucun.

**Risques :**
Déplacer la collision vers tileset créerait deux contrats persistants.

**Critère d’acceptation :**
Le fichier reste inchangé.

**Lot recommandé :**
Hors lot

### `packages/map_core/lib/src/validation/validators.dart`

**Statut recommandé :**
À modifier plus tard

**Rôle actuel :**
Valide les données projet. L'audit ciblé n'a pas identifié de validation explicite complète des dimensions de masks collision dans ce fichier.

**Problème constaté :**
Le repository valide le manifest, mais la validation ne formalise pas encore les invariants source-of-truth collision au niveau projet.

**Pourquoi ce fichier est concerné :**
Après création du normalizer, la validation doit pouvoir signaler les profils incohérents sans transformer les données.

**Changement recommandé :**
Ajouter des validations non mutantes :
- dimensions `collisionMask.width/height` cohérentes avec les rows;
- `collisionMask.type == collision` quand utilisé comme collision;
- `occlusionMask.type == occlusion` quand utilisé comme occlusion;
- `visualMask.type == visual` quand utilisé comme visual;
- pas de pollution de collision par `visualMask`/`occlusionMask`.

**Changement interdit :**
Faire la normalisation dans le validator, corriger silencieusement les profils, dépendre de Flutter.

**Dépendances :**
`ElementCollisionProfile`, `ElementCollisionMaskCodec`.

**Tests à ajouter ou modifier :**
Tests `map_core` de validation projet avec masks invalides.

**Risques :**
Une validation trop stricte peut rejeter des projets legacy avant normalisation.

**Critère d’acceptation :**
La validation signale les erreurs résiduelles après normalisation et n'effectue aucune mutation.

**Lot recommandé :**
Collision-5 ou Collision-6 selon ordre retenu.

### `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`

**Statut recommandé :**
À modifier

**Rôle actuel :**
`FileProjectRepository.loadProject()` lit le JSON, appelle `migrateProjectManifestJson(...)`, désérialise `ProjectManifest`, valide puis retourne le projet. `saveProject()` valide et écrit `project.toJson()`.

**Problème constaté :**
La normalisation collision legacy n'est pas appelée. Le test rouge de roundtrip attend une migration des profils avant validation/usage.

**Pourquoi ce fichier est concerné :**
C'est le point d'entrée de chargement projet editor. Il peut appliquer une normalisation pure sans coupler le modèle à l'éditeur UI.

**Changement recommandé :**
Dans Collision-6 :
- appeler une fonction pure de normalisation des profils collision après `ProjectManifest.fromJson(migratedJson)` et avant `ProjectValidator.validate(project)`;
- ne pas écrire immédiatement le projet normalisé sur disque au chargement;
- conserver `saveProject()` comme validation + écriture, sauf si un test prouve qu'un save explicite doit projeter `cells` depuis `collisionMask`.

**Changement interdit :**
Modifier le JSON brut à la main, faire une migration image, changer `ProjectManifest`, ignorer `ProjectValidator`.

**Dépendances :**
Futur normalizer `map_core`, tests repository rouges.

**Tests à ajouter ou modifier :**
Adapter `project_element_collision_file_repository_roundtrip_test.dart` pour vérifier :
- le chargement normalise le profil legacy;
- le fichier source n'est pas réécrit pendant load;
- un save explicite conserve `pixelMask` si présent.

**Risques :**
Une normalisation au mauvais endroit peut rendre le comportement différent entre editor, runtime host et gameplay tests.

**Critère d’acceptation :**
Le test repository rouge passe avec une normalisation pure importée de `map_core`, sans modification de modèle.

**Lot recommandé :**
Collision-6

### `packages/map_editor/lib/src/application/services/element_collision_authoring_service.dart`

**Statut recommandé :**
À modifier

**Rôle actuel :**
Reconstruit un `ElementCollisionProfile` coarse depuis padding, forme, additions et suppressions manuelles.

**Problème constaté :**
Le service reconstruit un profil avec champs coarse et ne préserve pas explicitement `collisionMask`, `occlusionMask` ou `visualMask`.

**Pourquoi ce fichier est concerné :**
Le flux cellule/polygone peut diverger du triple mask editor ou écraser les masks existants si une action coarse réémet un profil complet.

**Changement recommandé :**
Dans un lot après normalizer :
- ajouter un chemin explicite "coarse edit" qui soit préserve les masks existants tant que l'utilisateur ne demande pas une reprojection, soit les invalide avec une action UI explicite;
- utiliser le normalizer/projection pour recalculer `cells` à partir du mask quand `collisionMask` reste source-of-truth;
- documenter dans le service qu'il écrit l'intention coarse, pas la vérité fine.

**Changement interdit :**
Recréer un `collisionMask` depuis `cells` sans action explicite, supprimer `occlusionMask`, traiter l'image source.

**Dépendances :**
`ElementCollisionBaseCellsFromPaddingService`, `ElementCollisionCellsOverlayService`, futur normalizer.

**Tests à ajouter ou modifier :**
Tests service :
- édition coarse ne détruit pas `collisionMask` existant sans action explicite;
- édition coarse conserve `occlusionMask`;
- édition coarse met à jour `shapeCells` et manual overrides.

**Risques :**
Préserver un mask tout en modifiant `cells` peut créer une UI incohérente si aucun message n'explique la source active.

**Critère d’acceptation :**
Un profil issu du triple mask editor ne perd pas ses masks après ouverture/fermeture du flux coarse.

**Lot recommandé :**
Collision-8

### `packages/map_editor/lib/src/application/services/element_collision_base_cells_from_padding_service.dart`

**Statut recommandé :**
À ne pas modifier

**Rôle actuel :**
Calcule des cellules de base depuis le padding.

**Problème constaté :**
Service volontairement coarse. Il n'est pas responsable de la source-of-truth fine.

**Pourquoi ce fichier est concerné :**
Il alimente l'éditeur cellule/polygone et peut rester comme outil legacy.

**Changement recommandé :**
Aucun changement fonctionnel.

**Changement interdit :**
Générer un pixel mask dans ce service.

**Dépendances :**
`ElementCollisionAuthoringService`.

**Tests à ajouter ou modifier :**
Aucun dans Collision-3 à Collision-6.

**Risques :**
Lui donner une responsabilité fine rendrait le flux padding ambigu.

**Critère d’acceptation :**
Le service reste cell-only.

**Lot recommandé :**
Hors lot

### `packages/map_editor/lib/src/application/services/element_collision_cells_overlay_service.dart`

**Statut recommandé :**
À ne pas modifier

**Rôle actuel :**
Combine base cells, additions et suppressions manuelles.

**Problème constaté :**
Le service n'est pas cassé; son contrat doit rester coarse.

**Pourquoi ce fichier est concerné :**
Il décrit précisément le rôle de `manualAddedCells`/`manualRemovedCells`.

**Changement recommandé :**
Aucun changement. Le normalizer peut réutiliser la même logique ou une opération pure équivalente dans `map_core`.

**Changement interdit :**
Importer ce service editor dans `map_core` ou `map_gameplay`.

**Dépendances :**
`GridPos`, service authoring.

**Tests à ajouter ou modifier :**
Tests normalizer dans `map_core`, pas tests editor ici en priorité.

**Risques :**
Dupliquer la logique sans tests peut créer des écarts entre `map_core` et `map_editor`.

**Critère d’acceptation :**
La logique coarse reste cohérente entre service editor et normalizer core.

**Lot recommandé :**
Collision-4 pour équivalent core.

### `packages/map_editor/lib/src/application/services/element_collision_profile_generator.dart`

**Statut recommandé :**
À auditer seulement

**Rôle actuel :**
Génère des profils collision à partir de paramètres editor selon le flux actuel.

**Problème constaté :**
Le flux générateur historique peut produire des profils coarse et doit être distingué de la génération auto pixel mask.

**Pourquoi ce fichier est concerné :**
Il fait partie des écrivains potentiels du profil collision.

**Changement recommandé :**
Dans Collision-8 ou Collision-11, documenter son rôle exact : générateur coarse legacy ou façade vers la génération fine. Ajouter un test qui garantit qu'il ne détruit pas `collisionMask` en dehors d'une régénération explicite.

**Changement interdit :**
Le transformer en analyseur image.

**Dépendances :**
Services authoring et UI editor.

**Tests à ajouter ou modifier :**
Test de non-destruction des masks si le service reçoit un profil existant.

**Risques :**
Laisser deux générateurs non nommés augmente la confusion UX.

**Critère d’acceptation :**
Le service a un contrat clair dans les tests.

**Lot recommandé :**
Collision-8 ou Collision-11

### `packages/map_editor/lib/src/application/services/element_collision_shape_rasterizer_service.dart`

**Statut recommandé :**
À ne pas modifier

**Rôle actuel :**
Rasterise des polygones en cellules grille avec sur-échantillonnage.

**Problème constaté :**
Ce rasterizer produit des `GridPos`, pas un `collisionMask` pixel-level.

**Pourquoi ce fichier est concerné :**
Le prompt initial mentionne les polygones; le code montre qu'ils servent au flux coarse.

**Changement recommandé :**
Aucun changement dans les lots source-of-truth. Garder comme outil auteur coarse.

**Changement interdit :**
Présenter ce rasterizer comme solution de précision pixel-level.

**Dépendances :**
Editeur cellule/polygone.

**Tests à ajouter ou modifier :**
Aucun en priorité.

**Risques :**
Confondre rasterisation coarse et mask fine perpétue la mauvaise lecture produit.

**Critère d’acceptation :**
La documentation UI distingue polygone coarse et mask fine.

**Lot recommandé :**
Collision-8

### `packages/map_editor/lib/src/application/collision_generation/element_visual_occupancy_analyzer.dart`

**Statut recommandé :**
À auditer seulement

**Rôle actuel :**
Analyse l'occupation visuelle d'une image.

**Problème constaté :**
L'analyse visuelle aide la génération, mais ne doit pas devenir le modèle domaine.

**Pourquoi ce fichier est concerné :**
Il alimente `visualMask` et les heuristiques de génération.

**Changement recommandé :**
Aucun changement avant alignement doc/tests de Collision-11.

**Changement interdit :**
Déplacer cette logique dans `map_core`.

**Dépendances :**
`ElementVisualOccupancyRaster`, heuristiques generation.

**Tests à ajouter ou modifier :**
Tests d'heuristiques avec images/rasters synthétiques.

**Risques :**
Une dépendance alpha trop directe rend collision et ombres décoratives confondues.

**Critère d’acceptation :**
L'analyse visuelle reste editor-only.

**Lot recommandé :**
Collision-11

### `packages/map_editor/lib/src/application/collision_generation/element_visual_occupancy_raster.dart`

**Statut recommandé :**
À auditer seulement

**Rôle actuel :**
Structure de raster d'occupation visuelle.

**Problème constaté :**
Aucun défaut source-of-truth direct.

**Pourquoi ce fichier est concerné :**
Il fait partie de la génération auto des masks.

**Changement recommandé :**
Aucun avant Collision-11.

**Changement interdit :**
L'exposer comme modèle persistant dans `map_core`.

**Dépendances :**
Analyseur et heuristiques editor.

**Tests à ajouter ou modifier :**
Tests generation editor si les heuristiques changent.

**Risques :**
Confusion entre occupation visuelle et collision.

**Critère d’acceptation :**
`visualMask` reste preview/analyse, pas collision.

**Lot recommandé :**
Collision-11

### `packages/map_editor/lib/src/application/collision_generation/placed_element_auto_collision_generator.dart`

**Statut recommandé :**
À modifier

**Rôle actuel :**
Produit `visualMask`, `collisionMask`, `occlusionMask` depuis l'occupation visuelle et les heuristiques. Retourne actuellement un profil avec `cells: const []`.

**Problème constaté :**
Le generator écrit la vérité fine mais ne remplit pas la projection `cells`. Cela reste compatible avec gameplay, mais moins compatible avec debug/fallback et la décision source-of-truth.

**Pourquoi ce fichier est concerné :**
C'est l'un des écrivains principaux de `collisionMask`.

**Changement recommandé :**
Après Collision-5, décider et tester l'une des règles suivantes :
- soit laisser `cells` vide pour les profils generated avec `collisionMask`, en documentant que `cells` est fallback absent;
- soit remplir `cells` par projection depuis `collisionMask` pour faciliter debug/legacy.

La recommandation retenue est la deuxième : remplir `cells` par `ElementCollisionMaskCodec.cellsFromPixelMask(...)`, car elle aligne generator et triple mask editor.

**Changement interdit :**
Changer les heuristiques de collision dans le même lot que la projection contractuelle.

**Dépendances :**
`PlacedElementMaskHeuristicsV1`, `ElementCollisionMaskCodec`.

**Tests à ajouter ou modifier :**
Tests editor generation :
- profile generated contient `collisionMask`;
- `cells` égale la projection du mask;
- `occlusionMask` existe mais ne modifie pas `cells`.

**Risques :**
Remplir `cells` peut changer des snapshots ou attentes qui supposaient `cells: []`.

**Critère d’acceptation :**
Generator et triple mask editor produisent la même projection coarse pour un même mask collision.

**Lot recommandé :**
Collision-5 ou Collision-11 selon stratégie de moindre risque.

### `packages/map_editor/lib/src/application/collision_generation/placed_element_collision_params.dart`

**Statut recommandé :**
À modifier

**Rôle actuel :**
Décrit les paramètres de génération auto.

**Problème constaté :**
La documentation dit que le masque collision copie l'alpha visuel, alors que le generator utilise les heuristiques `PlacedElementMaskHeuristicsV1`.

**Pourquoi ce fichier est concerné :**
La documentation actuelle trompe la lecture produit et technique.

**Changement recommandé :**
Remplacer le commentaire par un contrat exact :
- l'alpha sert à construire une occupation visuelle;
- des heuristiques séparent collision et occlusion;
- les ombres et bandes hautes peuvent être traitées;
- le résultat n'est pas pixel-perfect alpha.

**Changement interdit :**
Changer le comportement generation dans un lot de documentation.

**Dépendances :**
`PlacedElementAutoCollisionGenerator`, `PlacedElementMaskHeuristicsV1`.

**Tests à ajouter ou modifier :**
Aucun pour un commentaire seul. Ajouter un test de comportement dans Collision-11.

**Risques :**
Laisser le commentaire faux conduit à de mauvaises corrections dans les prochains lots.

**Critère d’acceptation :**
Le commentaire décrit les heuristiques réellement appelées.

**Lot recommandé :**
Collision-11

### `packages/map_editor/lib/src/application/collision_generation/placed_element_mask_heuristics_v1.dart`

**Statut recommandé :**
À auditer seulement

**Rôle actuel :**
Sépare `visualMask`, `collisionMask` et `occlusionMask` à partir d'un raster visuel.

**Problème constaté :**
Les heuristiques sont utiles, mais elles sont exposées par une documentation trop simplifiée.

**Pourquoi ce fichier est concerné :**
Il porte la logique réelle que le plan doit préserver avant de la modifier.

**Changement recommandé :**
Ajouter des tests de caractérisation avant tout changement :
- bâtiment avec toit haut;
- ombre intégrée;
- petit prop;
- sprite transparent partiel.

**Changement interdit :**
Réécrire les heuristiques pendant le lot de normalisation source-of-truth.

**Dépendances :**
Analyzer/raster editor.

**Tests à ajouter ou modifier :**
Tests editor unitaires de raster synthétique.

**Risques :**
Changer ces heuristiques en même temps que la migration masquerait les causes de régression.

**Critère d’acceptation :**
Les heuristiques actuelles sont caractérisées avant évolution.

**Lot recommandé :**
Collision-11

### `packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart`

**Statut recommandé :**
À modifier plus tard

**Rôle actuel :**
Feuille UI d'édition collision élément, intégrant le flux cellule/polygone.

**Problème constaté :**
L'UI ne rend pas assez visible quelle donnée est la vérité active : mask fine ou cells coarse.

**Pourquoi ce fichier est concerné :**
C'est l'entrée auteur principale et donc le lieu où la divergence doit devenir explicite.

**Changement recommandé :**
Dans Collision-8 :
- afficher un libellé clair lorsque `collisionMask` est actif;
- signaler que les cellules visibles sont une projection coarse;
- éviter une action coarse qui remplace un mask sans confirmation;
- ne pas ajouter de jargon JSON.

**Changement interdit :**
Modifier le comportement gameplay, lancer une migration project-wide depuis l'UI, exposer `pixelMask` comme terme utilisateur principal.

**Dépendances :**
`ElementCollisionAuthoringService`, `ElementCollisionEditor`, triple mask editor.

**Tests à ajouter ou modifier :**
Tests widget ciblés :
- présence du label "collision fine active" ou équivalent produit;
- action coarse ne détruit pas `collisionMask` sans confirmation.

**Risques :**
Une UI trop technique peut contredire l'objectif no-code.

**Critère d’acceptation :**
Un auteur comprend si la collision effective vient du mask ou des cells.

**Lot recommandé :**
Collision-8

### `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/collision/element_collision_editor.dart`

**Statut recommandé :**
À modifier plus tard

**Rôle actuel :**
Widget d'édition collision orienté cellules et formes.

**Problème constaté :**
Le widget expose une grille coarse; cette grille ne représente pas toute la précision du `collisionMask`.

**Pourquoi ce fichier est concerné :**
Il doit devenir un éditeur d'intention coarse ou une projection explicite, pas une fausse vérité fine.

**Changement recommandé :**
Ajouter des labels/états en Collision-8 et des tests widget de non-destruction des masks.

**Changement interdit :**
Transformer ce widget en nouvel éditeur pixel fine sans décision UX.

**Dépendances :**
Painter, service authoring.

**Tests à ajouter ou modifier :**
Widget tests de labels et callbacks.

**Risques :**
Une grille coarse présentée comme finale prolonge le problème produit initial.

**Critère d’acceptation :**
La grille indique son rôle de projection ou d'édition coarse.

**Lot recommandé :**
Collision-8

### `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/collision/element_collision_profile_painter.dart`

**Statut recommandé :**
À modifier plus tard

**Rôle actuel :**
Peint la preview collision profil.

**Problème constaté :**
La preview doit distinguer projection cells, mask fine, visual et occlusion.

**Pourquoi ce fichier est concerné :**
La clarté visuelle dépend du painter.

**Changement recommandé :**
Ajouter un mode overlay qui montre `collisionMask` quand présent et `cells` fallback quand absent.

**Changement interdit :**
Faire de l'occlusion un blocage collision.

**Dépendances :**
UI editor, `ElementCollisionMaskCodec`.

**Tests à ajouter ou modifier :**
Golden/widget tests si infrastructure disponible; sinon tests painter ciblés si existants.

**Risques :**
Les previews trompeuses conduisent à des corrections manuelles destructrices.

**Critère d’acceptation :**
La preview affiche la même source que gameplay.

**Lot recommandé :**
Collision-8

### `packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart`

**Statut recommandé :**
À modifier plus tard

**Rôle actuel :**
Édite `visualMask`, `collisionMask` et `occlusionMask`. Si le profil n'a que `cells`, il dérive un bitmap en remplissant les tiles. `_emitProfile()` reprojette `cells` depuis `collisionMask`.

**Problème constaté :**
Ce widget est le plus proche du contrat cible, mais ses labels et tests doivent officialiser la vérité.

**Pourquoi ce fichier est concerné :**
C'est l'écrivain UI principal du `collisionMask`.

**Changement recommandé :**
Ajouter tests et libellés :
- `collisionMask` est la collision utilisée en gameplay;
- `occlusionMask` est hors collision;
- `cells` est projection exportée pour compatibilité.

**Changement interdit :**
Supprimer la reprojection `cells`, fusionner occlusion et collision, exposer `pixelMask` comme terme utilisateur.

**Dépendances :**
`ElementCollisionMaskCodec`, profile painter.

**Tests à ajouter ou modifier :**
Widget/unit tests :
- édition collision émet `collisionMask`;
- édition occlusion ne modifie pas `collisionMask`;
- `cells` émis égale la projection du mask.

**Risques :**
Si ce widget reste correct mais isolé, les autres flux continueront à diverger.

**Critère d’acceptation :**
Le triple mask editor devient la référence testée de l'écriture fine.

**Lot recommandé :**
Collision-8

### `packages/map_gameplay/lib/src/gameplay_world_state.dart`

**Statut recommandé :**
À modifier prudemment

**Rôle actuel :**
Construit les caches collision monde. `_buildPixelCollisionCache(...)` stamp `collisionMask`. `_buildPlacedElementCellCollisionCache(...)` applique `cells` seulement si `collisionMask == null`.

**Problème constaté :**
Le fallback est correct pour un profil legacy cohérent, mais il amplifie les profils legacy incohérents qui ont `cells` pleines.

**Pourquoi ce fichier est concerné :**
Les tests rouges gameplay échouent ici, mais la cause racine est le profil non normalisé.

**Changement recommandé :**
Dans Collision-7 :
- ajouter des tests qui figent la priorité `collisionMask`;
- ajouter un test qui prouve que `cells` n'est utilisé que sans mask;
- ne pas intégrer de migration complexe dans `GameplayWorldState`;
- accepter éventuellement une assertion/guard légère si un profil contient `collisionMask` et `cells` contradictoires, sans changer la lecture effective.

**Changement interdit :**
Recalculer des masks depuis image, appliquer les heuristiques editor, normaliser tout le manifest dans gameplay.

**Dépendances :**
Futur normalizer, `PixelMovementResolverV1`, `GameplayPlayerState`.

**Tests à ajouter ou modifier :**
Tests gameplay :
- mask gagne contre cells contradictoires;
- fallback cells pour profils sans mask;
- profil legacy normalisé ne bloque pas le toit;
- sliding conservé.

**Risques :**
Mettre trop de migration ici couplerait gameplay aux bugs d'authoring.

**Critère d’acceptation :**
Gameplay reste consommateur simple et les tests décrivent le contrat mask-first.

**Lot recommandé :**
Collision-7

### `packages/map_gameplay/lib/src/collision/pixel_movement_resolver.dart`

**Statut recommandé :**
À ne pas modifier

**Rôle actuel :**
Résout le déplacement pixel par axes séparés et teste la hitbox contre `worldStaticObstaclesCollidePixelRect`.

**Problème constaté :**
Aucun problème source-of-truth identifié.

**Pourquoi ce fichier est concerné :**
Il confirme que la collision gameplay est déjà pixel-level.

**Changement recommandé :**
Aucun changement dans les lots source-of-truth.

**Changement interdit :**
Changer le sliding pour corriger un profil legacy incohérent.

**Dépendances :**
`GameplayWorldState`, `PlayerCollisionConventionsV1`.

**Tests à ajouter ou modifier :**
Tests de non-régression sliding dans Collision-7.

**Risques :**
Modifier le resolver transformerait un problème de données en changement de mouvement.

**Critère d’acceptation :**
Le resolver reste inchangé pendant les lots Collision-3 à Collision-6.

**Lot recommandé :**
Collision-7 pour tests seulement.

### `packages/map_gameplay/lib/src/gameplay_player_state.dart`

**Statut recommandé :**
À ne pas modifier

**Rôle actuel :**
Porte l'état joueur et les conventions de hitbox.

**Problème constaté :**
Aucun défaut source-of-truth placé ici.

**Pourquoi ce fichier est concerné :**
Il confirme la hitbox joueur utilisée par gameplay.

**Changement recommandé :**
Aucun.

**Changement interdit :**
Changer la hitbox pour faire passer les tests rouges.

**Dépendances :**
`PlayerCollisionConventionsV1`, `gameplay_step.dart`.

**Tests à ajouter ou modifier :**
Tests gameplay de hitbox actuelle.

**Risques :**
Un changement de hitbox modifie les sensations de déplacement.

**Critère d’acceptation :**
La hitbox reste identique.

**Lot recommandé :**
Collision-7 et Collision-9 pour preview sans changement gameplay.

### `packages/map_gameplay/lib/src/gameplay_step.dart`

**Statut recommandé :**
À ne pas modifier

**Rôle actuel :**
Orchestre le pas gameplay, appelle le resolver pixel et projette les pieds sur la grille pour d'autres systèmes.

**Problème constaté :**
La divergence `cells`/`collisionMask` est dans la construction des caches, pas dans le pas gameplay.

**Pourquoi ce fichier est concerné :**
Il vérifie que la collision de mouvement est découplée des interactions grille.

**Changement recommandé :**
Aucun pour source-of-truth collision.

**Changement interdit :**
Modifier le stepping pour masquer une collision trop large.

**Dépendances :**
`PixelMovementResolverV1`, state gameplay.

**Tests à ajouter ou modifier :**
Aucun en priorité.

**Risques :**
Changer ce fichier peut affecter triggers, acteurs et interactions.

**Critère d’acceptation :**
Le fichier reste inchangé.

**Lot recommandé :**
Hors lot

### `packages/map_gameplay/lib/src/movement_block_reason.dart`

**Statut recommandé :**
À ne pas modifier

**Rôle actuel :**
Énumère les raisons de blocage.

**Problème constaté :**
Le contrat source-of-truth n'a pas besoin d'une nouvelle raison de blocage.

**Pourquoi ce fichier est concerné :**
Présent dans le périmètre gameplay collision.

**Changement recommandé :**
Aucun.

**Changement interdit :**
Ajouter une raison spécifique "legacy cells" ou "pixel mask" dans un lot de normalisation.

**Dépendances :**
Gameplay movement.

**Tests à ajouter ou modifier :**
Aucun.

**Risques :**
Exposer l'implémentation des masks dans les raisons de blocage rendrait l'API trop technique.

**Critère d’acceptation :**
Le fichier reste inchangé.

**Lot recommandé :**
Hors lot

### `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`

**Statut recommandé :**
À ne pas modifier pour source-of-truth

**Rôle actuel :**
Rend les layers et l'overlay debug collision. L'overlay placed elements lit `collisionMask` et fallback `cells`.

**Problème constaté :**
L'overlay debug est aligné avec gameplay pour la source collision. `occlusionMask` n'est pas consommé pour le rendu.

**Pourquoi ce fichier est concerné :**
C'est la seule zone runtime inspectée qui affiche explicitement les collisions.

**Changement recommandé :**
Ne pas modifier dans les lots de normalisation. Dans un futur lot runtime, ajouter un test/smoke qui compare overlay debug et source gameplay.

**Changement interdit :**
Implémenter l'occlusion visuelle dans un lot source-of-truth collision, utiliser `occlusionMask` comme blocage.

**Dépendances :**
Flame runtime, `ElementCollisionMaskCodec`.

**Tests à ajouter ou modifier :**
Futur test runtime overlay si infrastructure stable.

**Risques :**
Mélanger occlusion et collision dans runtime casserait le cas des toits, portes et enseignes.

**Critère d’acceptation :**
Le runtime debug continue d'afficher `collisionMask` puis `cells`.

**Lot recommandé :**
Collision-12 pour décision occlusion, hors Collision-3 à Collision-8.

### `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

**Statut recommandé :**
À ne pas modifier

**Rôle actuel :**
Intègre `GameplayWorldState` dans Flame et synchronise le joueur.

**Problème constaté :**
La collision effective vient de `map_gameplay`, pas d'une logique dupliquée ici.

**Pourquoi ce fichier est concerné :**
Il confirme que runtime ne doit pas porter le contrat source-of-truth collision.

**Changement recommandé :**
Aucun.

**Changement interdit :**
Dupliquer un resolver collision dans Flame.

**Dépendances :**
`map_gameplay`, composants Flame.

**Tests à ajouter ou modifier :**
Smoke runtime plus tard si une golden slice bâtiment est ajoutée.

**Risques :**
Une duplication runtime/gameplay créerait deux comportements de collision.

**Critère d’acceptation :**
Le gameplay reste source du mouvement.

**Lot recommandé :**
Collision-10 pour golden slice.

### `packages/map_runtime/lib/src/presentation/flame/player_component.dart`

**Statut recommandé :**
À ne pas modifier

**Rôle actuel :**
Affiche le joueur et synchronise sa pose visuelle.

**Problème constaté :**
Aucune logique de source-of-truth collision.

**Pourquoi ce fichier est concerné :**
Il est cité dans le périmètre runtime, mais ne doit pas absorber la collision.

**Changement recommandé :**
Aucun.

**Changement interdit :**
Mettre la hitbox gameplay dans le composant visuel comme source de vérité.

**Dépendances :**
Flame rendering.

**Tests à ajouter ou modifier :**
Aucun dans les lots source-of-truth.

**Risques :**
Coupler visuel et collision rendrait les skins/animations risqués.

**Critère d’acceptation :**
Le composant reste visuel.

**Lot recommandé :**
Hors lot

### `packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart`

**Statut recommandé :**
À ne pas modifier

**Rôle actuel :**
Hôte runtime de rendu.

**Problème constaté :**
Aucun lien direct avec la divergence `cells`/`collisionMask`.

**Pourquoi ce fichier est concerné :**
Inspection demandée pour vérifier absence de duplication collision.

**Changement recommandé :**
Aucun.

**Changement interdit :**
Ajouter de la collision source-of-truth dans ce hôte.

**Dépendances :**
Runtime Flame.

**Tests à ajouter ou modifier :**
Aucun.

**Risques :**
Dupliquer la collision dans runtime affaiblit le contrat gameplay.

**Critère d’acceptation :**
Le fichier reste inchangé.

**Lot recommandé :**
Hors lot

## 9. Fichiers à créer

| Fichier | Lot | Responsabilité |
|---|---|---|
| `packages/map_core/lib/src/operations/element_collision_profile_normalizer.dart` | Collision-4 | Normalisation pure `ElementCollisionProfile`, sans Flutter, sans image, sans manifest. |
| `packages/map_core/test/...element_collision_profile_normalizer_test.dart` | Collision-4 | Tests legacy/manual/mask/projection. |
| Tests `map_core` codec/JSON ciblés | Collision-4 ou Collision-5 | Contrat `pixelMask` et projection `cells`. |
| Tests `map_editor` repository/service/widget ciblés | Collision-6 et Collision-8 | Persistance normalisée et non-destruction des masks. |
| Tests `map_gameplay` mask-first/fallback ciblés | Collision-7 | Contrat runtime gameplay. |
| Golden slice bâtiment | Collision-10 | Cas produit maison/toit/porte/cheminée. |

## 10. Fichiers à modifier

| Fichier | Lot | Changement précis |
|---|---|---|
| `packages/map_core/lib/src/models/element_collision_profile.dart` | Collision-4 | Corriger les commentaires source-of-truth, conserver JSON `pixelMask`. |
| `packages/map_core/lib/src/operations/element_collision_mask_codec.dart` | Collision-5 | Ajouter tests, code inchangé si tests verts. |
| `packages/map_core/lib/src/validation/validators.dart` | Collision-5/6 | Ajouter validations non mutantes des masks après normalisation. |
| `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart` | Collision-6 | Appeler le normalizer après `ProjectManifest.fromJson` et avant validation. |
| `packages/map_editor/lib/src/application/services/element_collision_authoring_service.dart` | Collision-8 | Préserver ou invalider explicitement les masks lors d'éditions coarse. |
| `packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart` | Collision-8 | Labels et garde-fous UI source active. |
| `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/collision/element_collision_editor.dart` | Collision-8 | Clarifier grille coarse/projection. |
| `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/collision/element_collision_profile_painter.dart` | Collision-8 | Preview alignée sur source effective. |
| `packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart` | Collision-8 | Tests et labels, conserver reprojection. |
| `packages/map_editor/lib/src/application/collision_generation/placed_element_collision_params.dart` | Collision-11 | Corriger commentaire alpha/heuristiques. |
| `packages/map_editor/lib/src/application/collision_generation/placed_element_auto_collision_generator.dart` | Collision-5/11 | Aligner projection `cells` depuis mask ou documenter `cells` vide. Recommandation : projection. |
| `packages/map_gameplay/lib/src/gameplay_world_state.dart` | Collision-7 | Tests/guards légers, pas de migration complexe. |

## 11. Fichiers à ne pas modifier

| Fichier | Raison |
|---|---|
| `packages/map_core/lib/src/models/project_manifest.dart` | Le schéma manifest n'est pas en cause. |
| `packages/map_core/lib/src/models/tileset.dart` | Pas source de collision placed element. |
| `packages/map_core/lib/src/collision/pixel_rect.dart` | Hitbox primitive stable. |
| `packages/map_core/lib/src/collision/player_collision_conventions_v1.dart` | Convention 12x8 à conserver. |
| `packages/map_core/lib/src/operations/map_entity_collision_footprint.dart` | Entités séparées des placed elements. |
| `packages/map_editor/lib/src/application/services/element_collision_base_cells_from_padding_service.dart` | Service coarse uniquement. |
| `packages/map_editor/lib/src/application/services/element_collision_cells_overlay_service.dart` | Logique coarse stable, ne doit pas dépendre d'editor dans core. |
| `packages/map_editor/lib/src/application/services/element_collision_shape_rasterizer_service.dart` | Polygone -> cells, pas mask fine. |
| `packages/map_gameplay/lib/src/collision/pixel_movement_resolver.dart` | Resolver déjà pixel-level; ne pas masquer un problème de données. |
| `packages/map_gameplay/lib/src/gameplay_player_state.dart` | Hitbox joueur stable. |
| `packages/map_gameplay/lib/src/gameplay_step.dart` | Orchestration gameplay non responsable. |
| `packages/map_gameplay/lib/src/movement_block_reason.dart` | Pas besoin d'exposer la source interne. |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | Runtime délègue à gameplay. |
| `packages/map_runtime/lib/src/presentation/flame/player_component.dart` | Composant visuel. |
| `packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart` | Hôte rendu sans source collision. |

## 12. Roadmap recommandée

## Collision-3 — Red Tests Triage / Legacy Contract Clarification

**Objectif :**
Faire passer les tests rouges au statut "contrat clair" sans implémenter la normalisation.

**Pourquoi ce lot existe :**
Les tests rouges mélangent compilation test, migration attendue et gameplay fallback.

**Fichiers à créer :**
Aucun fichier de production. Tests ajustés si le lot devient implémentation test.

**Fichiers à modifier :**
Tests rouges uniquement.

**Fichiers à ne pas modifier :**
`ProjectManifest`, runtime, gameplay production.

**Changements précis :**
Corriger le `const` invalide du test editor. Renommer ou commenter les tests legacy pour expliciter qu'ils attendent le futur normalizer.

**Tests à ajouter/modifier :**
Les trois tests rouges reproduits.

**Commandes de validation :**
```bash
cd packages/map_editor && flutter test --reporter expanded test/project_element_collision_persistence_test.dart
cd packages/map_editor && flutter test --reporter expanded test/project_element_collision_file_repository_roundtrip_test.dart
cd packages/map_gameplay && flutter test --reporter expanded test/placed_elements_collision_test.dart
```

**Risques :**
Corriger les tests pour les rendre verts sans contrat.

**Critères d’acceptation :**
Chaque test rouge indique clairement le contrat cible et le lot qui le rendra vert.

## Collision-4 — Element Collision Profile Normalizer V0

**Objectif :**
Créer le normalizer pur dans `map_core`.

**Pourquoi ce lot existe :**
La réparation legacy doit être partagée par editor et gameplay tests sans coupler les packages.

**Fichiers à créer :**
`packages/map_core/lib/src/operations/element_collision_profile_normalizer.dart`

**Fichiers à modifier :**
`packages/map_core/lib/map_core.dart` si le barrel expose les opérations; `element_collision_profile.dart` pour commentaires.

**Fichiers à ne pas modifier :**
`ProjectManifest`, `map_editor`, `map_gameplay`.

**Changements précis :**
Ajouter une fonction pure de normalisation des profils et les tests associés.

**Tests à ajouter/modifier :**
Tests normalizer legacy/manual/mask.

**Commandes de validation :**
```bash
cd packages/map_core && dart test
cd packages/map_core && dart analyze
```

**Risques :**
Normalisation trop large sur vieux projets.

**Critères d’acceptation :**
Le normalizer est testé sans dépendance Flutter et ne change pas le schéma JSON.

## Collision-5 — collisionMask -> cells Projection Contract

**Objectif :**
Officialiser la projection `cells` depuis `collisionMask`.

**Pourquoi ce lot existe :**
`cells` reste nécessaire pour compatibilité/debug/fallback.

**Fichiers à créer :**
Tests codec/projection.

**Fichiers à modifier :**
`ElementCollisionMaskCodec` seulement si un test révèle un écart.

**Fichiers à ne pas modifier :**
Runtime/gameplay UI.

**Changements précis :**
Tester `cellsFromPixelMask(...)` et décider que les écrivains principaux utilisent cette projection.

**Tests à ajouter/modifier :**
Tests projection tile-size et dimensions.

**Commandes de validation :**
```bash
cd packages/map_core && dart test
```

**Risques :**
Changer la projection modifie les overlays.

**Critères d’acceptation :**
La projection est stable et documentée par tests.

## Collision-6 — Editor Persistence Uses Normalizer

**Objectif :**
Appliquer la normalisation au chargement repository editor.

**Pourquoi ce lot existe :**
Le test rouge repository attend cette étape.

**Fichiers à créer :**
Aucun fichier production hors tests si normalizer existe.

**Fichiers à modifier :**
`packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`

**Fichiers à ne pas modifier :**
`ProjectManifest`, codecs generated.

**Changements précis :**
Après `ProjectManifest.fromJson`, appliquer la normalisation des profils collision, puis valider.

**Tests à ajouter/modifier :**
`project_element_collision_file_repository_roundtrip_test.dart`.

**Commandes de validation :**
```bash
cd packages/map_editor && flutter test --reporter expanded test/project_element_collision_file_repository_roundtrip_test.dart
cd packages/map_editor && flutter test
```

**Risques :**
Normaliser au save au lieu du load peut provoquer une réécriture implicite.

**Critères d’acceptation :**
Load retourne un manifest normalisé sans réécrire le fichier.

## Collision-7 — Gameplay Legacy Fallback Hardening

**Objectif :**
Figer le contrat gameplay mask-first et fallback legacy.

**Pourquoi ce lot existe :**
Les tests rouges gameplay doivent prouver le contrat, pas imposer une migration editor dans gameplay.

**Fichiers à créer :**
Tests gameplay ciblés.

**Fichiers à modifier :**
`packages/map_gameplay/lib/src/gameplay_world_state.dart` seulement si un guard léger est nécessaire.

**Fichiers à ne pas modifier :**
Resolver, hitbox, step, movement reasons.

**Changements précis :**
Ajouter tests : mask prioritaire, cells fallback, profil normalisé, sliding.

**Tests à ajouter/modifier :**
`placed_elements_collision_test.dart`.

**Commandes de validation :**
```bash
cd packages/map_gameplay && flutter test --reporter expanded test/placed_elements_collision_test.dart
cd packages/map_gameplay && dart test
```

**Risques :**
Importer trop de logique legacy dans gameplay.

**Critères d’acceptation :**
Gameplay lit simplement `collisionMask` puis `cells`.

## Collision-8 — UI Truth Labels / PixelMask vs Cells

**Objectif :**
Clarifier dans l'éditeur quelle donnée est effective.

**Pourquoi ce lot existe :**
Le produit est no-code; la vérité technique ne doit pas rester invisible.

**Fichiers à créer :**
Tests widget ciblés.

**Fichiers à modifier :**
Sheet, editor widget, painter, triple mask editor, authoring service.

**Fichiers à ne pas modifier :**
Gameplay/runtime.

**Changements précis :**
Labels, guard de non-destruction mask, preview source active.

**Tests à ajouter/modifier :**
Widget tests labels et callbacks.

**Commandes de validation :**
```bash
cd packages/map_editor && flutter test
```

**Risques :**
Libellés trop techniques pour les utilisateurs non-développeurs.

**Critères d’acceptation :**
Un utilisateur voit si la collision effective vient du mask ou de la grille coarse.

## Collision-9 — Player Foot Hitbox Preview in Editor

**Objectif :**
Afficher la hitbox pieds 12x8 dans les previews collision.

**Pourquoi ce lot existe :**
La précision réelle dépend de l'intersection mask + foot hitbox.

**Fichiers à créer :**
Tests widget/painter.

**Fichiers à modifier :**
Painter/editor preview.

**Fichiers à ne pas modifier :**
`PlayerCollisionConventionsV1` sauf export nécessaire déjà existant.

**Changements précis :**
Preview visuelle, pas de changement gameplay.

**Tests à ajouter/modifier :**
Tests UI de rendu/état.

**Commandes de validation :**
```bash
cd packages/map_editor && flutter test
```

**Risques :**
Faire croire que la hitbox est éditable si elle ne l'est pas.

**Critères d’acceptation :**
Preview fidèle aux conventions gameplay actuelles.

## Collision-10 — Building Golden Slice

**Objectif :**
Créer un cas produit bâtiment avec toit, porte, cheminée, décrochements.

**Pourquoi ce lot existe :**
Les tests unitaires ne suffisent pas pour le problème produit initial.

**Fichiers à créer :**
Fixture/golden test ciblé selon package retenu.

**Fichiers à modifier :**
Tests editor/gameplay/runtime selon slice.

**Fichiers à ne pas modifier :**
Modèles persistants.

**Changements précis :**
Fixture contrôlée avec `collisionMask`, projection `cells`, déplacement joueur attendu.

**Tests à ajouter/modifier :**
Golden gameplay/runtime slice.

**Commandes de validation :**
```bash
cd packages/map_gameplay && dart test
cd packages/map_runtime && flutter test
```

**Risques :**
Créer une fixture trop lourde.

**Critères d’acceptation :**
Le bâtiment reproduit le cas produit et reste stable en CI locale.

## Collision-11 — Auto-generation Documentation / Heuristics Alignment

**Objectif :**
Aligner documentation, tests et heuristiques de génération.

**Pourquoi ce lot existe :**
Le commentaire "copy alpha" ne décrit pas le comportement réel.

**Fichiers à créer :**
Tests heuristiques raster synthétique.

**Fichiers à modifier :**
`placed_element_collision_params.dart`, generator si projection `cells` décidée.

**Fichiers à ne pas modifier :**
`map_core` modèle.

**Changements précis :**
Documenter heuristiques et caractériser bâtiments/ombres/props.

**Tests à ajouter/modifier :**
Tests génération visual/collision/occlusion.

**Commandes de validation :**
```bash
cd packages/map_editor && flutter test
```

**Risques :**
Changer heuristiques sans golden produit.

**Critères d’acceptation :**
Docs et tests décrivent le comportement réel.

## Collision-12 — Occlusion Runtime Decision Report

**Objectif :**
Décider comment `occlusionMask` sera consommé sans le mélanger à la collision.

**Pourquoi ce lot existe :**
Les bâtiments nécessitent collision et occlusion séparées.

**Fichiers à créer :**
Rapport décision ou prototype non persistant selon demande.

**Fichiers à modifier :**
Aucun dans un report-only lot.

**Fichiers à ne pas modifier :**
Gameplay collision.

**Changements précis :**
Analyser rendu devant/derrière joueur, z-order, masks occlusion.

**Tests à ajouter/modifier :**
Tests runtime futurs après décision.

**Commandes de validation :**
Audit/report only.

**Risques :**
Utiliser `occlusionMask` comme blocage collision.

**Critères d’acceptation :**
Décision claire avant implémentation runtime.

Pourquoi cet ordre évite la refonte directe :

- Il corrige d'abord le contrat et les tests rouges.
- Il crée une opération pure et testée avant de brancher l'éditeur.
- Il garde gameplay simple.
- Il retarde l'UI et l'occlusion jusqu'à ce que la source de vérité soit stable.
- Il évite un second système fin qui dupliquerait `collisionMask`.

## 13. Plan de tests par package

### map_core

Tests à ajouter :

- normalisation d'un profil legacy avec `manualAddedCells`;
- `collisionMask` prioritaire sur `cells` contradictoires;
- projection `cells` depuis `collisionMask`;
- JSON `pixelMask` conservé;
- `manualRemovedCells` appliqué dans le flux legacy;
- dimensions invalides de mask rejetées;
- `visualMask` ne pollue pas collision;
- `occlusionMask` ne pollue pas collision.

Commandes :

```bash
cd packages/map_core && dart test
cd packages/map_core && dart analyze
```

### map_editor

Tests à ajouter ou modifier :

- `FileProjectRepository.loadProject()` applique la normalisation au bon endroit;
- `saveProject()` ne fait pas une migration implicite non demandée;
- l'éditeur cellule ne détruit pas `collisionMask` sans action explicite;
- triple mask editor reprojette `cells`;
- labels UI expliquent la source active;
- génération auto docs et comportement sont alignés.

Commandes :

```bash
cd packages/map_editor && flutter test
cd packages/map_editor && flutter analyze
```

### map_gameplay

Tests à ajouter ou modifier :

- `collisionMask` gagne contre `cells` contradictoires;
- `cells` fallback uniquement si `collisionMask` absent;
- profil legacy normalisé ne bloque pas tout le bâtiment;
- hitbox 12x8 continue de fonctionner;
- sliding par axes séparés conservé.

Commandes :

```bash
cd packages/map_gameplay && dart test
cd packages/map_gameplay && dart analyze
```

Note d'exécution :

- Pour reproduire les rouges sans `.dart_tool` diff, `flutter test --reporter expanded test/placed_elements_collision_test.dart` a été utilisé dans ce lot.
- Le lot d'implémentation doit choisir la commande officielle après contrôle du comportement `.dart_tool` local.

### map_runtime

Tests à ajouter plus tard :

- overlay debug collision affiche la même source que gameplay;
- aucune confusion occlusion/collision;
- rendu occlusion hors lot source-of-truth.

Commandes futures :

```bash
cd packages/map_runtime && flutter test
```

## 14. Ordre d’exécution recommandé

1. Collision-3 : clarifier les tests rouges et corriger le test qui ne compile pas.
2. Collision-4 : créer le normalizer pur `map_core`.
3. Collision-5 : figer le contrat projection `collisionMask -> cells`.
4. Collision-6 : brancher le normalizer dans `FileProjectRepository.loadProject()`.
5. Collision-7 : renforcer les tests gameplay mask-first/fallback.
6. Collision-8 : clarifier l'UI et éviter la destruction des masks.
7. Collision-9 : ajouter la preview hitbox pieds.
8. Collision-10 : créer une golden slice bâtiment.
9. Collision-11 : aligner génération auto, docs et tests.
10. Collision-12 : décider l'occlusion runtime séparément.

Ordre minimal pour traiter les rouges actuels :

1. Collision-3
2. Collision-4
3. Collision-6
4. Collision-7

## 15. Risques et arbitrages

| Risque | Impact | Arbitrage recommandé |
|---|---|---|
| Casser les vieux projets | Chargements existants modifiés | Normalizer strict, testé sur formes legacy connues. |
| Casser les tests actuels | Perte de signal | Triage Collision-3 avant implémentation. |
| Migration trop magique | Données changées sans intention | Normaliser au load, ne pas réécrire au disque sans save explicite. |
| Mélanger collision et occlusion | Bâtiments injouables ou rendu faux | `occlusionMask` hors collision jusqu'à Collision-12. |
| Créer un second système fin | Dette et duplication | Officialiser `collisionMask` existant. |
| UI trop technique | No-code affaibli | Libellés produit, pas jargon JSON. |
| Logique editor dans gameplay | Couplage package interdit | Normalizer dans `map_core`, gameplay consommateur simple. |
| Logique image dans map_core | Pure Dart contract pollué | Image analysis reste dans `map_editor`. |
| Corriger les tests au lieu du contrat | Faux vert | Tests rouges doivent pointer le normalizer et la source-of-truth. |
| Projection `cells` divergente | Debug/fallback incohérents | Une seule projection via `ElementCollisionMaskCodec.cellsFromPixelMask(...)`. |

## 16. Alternatives rejetées

| Alternative | Décision | Raison |
|---|---|---|
| Créer tout de suite un `ElementCollisionProfileV2` | Rejetée | `collisionMask` existe déjà et gameplay le consomme. |
| Renommer `pixelMask` en JSON | Rejetée | Casserait la compatibilité historique. |
| Supprimer `cells` | Rejetée | `cells` sert au fallback, debug et legacy. |
| Mettre la migration dans `map_gameplay` | Rejetée | Gameplay doit rester consommateur simple. |
| Utiliser l'alpha image comme collision vérité | Rejetée pour V0 | L'éditeur applique déjà des heuristiques et l'alpha mélange silhouettes, ombres et décor. |
| Fusionner occlusion et collision | Rejetée | Les bâtiments exigent des zones visuelles non bloquantes. |
| Corriger les tests rouges sans normalizer | Rejetée | Le problème de contrat resterait dans les données. |

## 17. Questions ouvertes

Non vérifié.

**Sujet :**
Le comportement exact de tous les tests collision existants hors trois rouges ciblés.

**Raison :**
Ce lot est report-only et les commandes ciblées demandées ont été priorisées. Un `flutter test` complet editor peut être long et produire des sorties sans rapport direct avec le plan.

**Impact :**
Un lot futur peut découvrir des tests additionnels affectés par la normalisation.

**Comment vérifier dans le prochain lot :**
Après Collision-3, lancer les tests par package indiqués dans le plan de tests.

Non vérifié.

**Sujet :**
La meilleure politique définitive pour `PlacedElementAutoCollisionGenerator.cells`.

**Raison :**
Le code actuel laisse `cells` vide avec un `collisionMask` présent. Le triple mask editor reprojette `cells`. Les deux comportements sont compatibles gameplay, mais pas équivalents pour debug/legacy.

**Impact :**
Changer generator peut modifier des attentes editor ou snapshots.

**Comment vérifier dans le prochain lot :**
Ajouter un test de projection contractuelle en Collision-5 puis appliquer la même règle au generator en Collision-11.

Non vérifié.

**Sujet :**
L'ergonomie exacte des libellés UI finaux.

**Raison :**
Ce lot planifie les changements techniques et ne conçoit pas les microcopies UI finales.

**Impact :**
Un libellé trop technique peut nuire à l'objectif no-code.

**Comment vérifier dans le prochain lot :**
Faire Collision-8 avec tests widget et revue UX centrée utilisateur non-développeur.

## 18. Recommandation finale

Lancer ensuite Collision-3, puis Collision-4.

Collision-3 doit clarifier les tests rouges sans changer le comportement de production.

Collision-4 doit créer la pièce manquante : un normalizer pur dans `map_core`. Cette pièce débloque ensuite la persistance editor, les tests gameplay et les garanties UI sans refonte.

Le système cible court terme est :

- `collisionMask` vérité gameplay;
- `pixelMask` nom JSON legacy;
- `cells` projection/fallback/debug;
- normalizer pur pour réparer les profils legacy;
- editor responsable des écritures auteur;
- gameplay responsable de consommer la source déjà normalisée;
- occlusion traitée dans un lot séparé.

## 19. Git status final

Commande exécutée en fin de lot :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
?? packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
?? packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
?? reports/collision/collision_lot_2_source_of_truth_implementation_plan.md
?? reports/collision/collision_system_audit_v0.md
?? reports/shadows/shadow_lot_20_runtime_static_placed_element_shadow_collection.md
```

Inventaire final :

| Catégorie | Fichiers |
|---|---|
| Créés par ce lot | `reports/collision/collision_lot_2_source_of_truth_implementation_plan.md` |
| Modifiés par ce lot hors rapport | Aucun |
| Supprimés par ce lot | Aucun |
| Generated modifiés par ce lot | Aucun |
| Non suivis présents en fin de lot et non créés par ce lot | `packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart`, `packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart`, `reports/collision/collision_system_audit_v0.md`, `reports/shadows/shadow_lot_20_runtime_static_placed_element_shadow_collection.md` |
| Diff tracked visible en fin de lot | Aucun fichier tracked affiché par `git status --short --untracked-files=all` |

## 20. Auto-review finale

| Question | Réponse |
|---|---|
| Ai-je créé uniquement le rapport demandé ? | Oui, un seul fichier doit être créé par ce lot : `reports/collision/collision_lot_2_source_of_truth_implementation_plan.md`. |
| Ai-je évité toute correction de code ? | Oui. |
| Ai-je relu l’audit V0 ? | Oui, conclusions structurantes extraites et citées par sections. |
| Ai-je inspecté les fichiers réels ? | Oui, les fichiers demandés ont été inventoriés et les rôles source-of-truth ont été caractérisés. |
| Ai-je caractérisé les tests rouges ? | Oui, trois commandes ciblées ont été lancées et les sorties utiles sont incluses. |
| Ai-je produit un plan fichier par fichier ? | Oui, section 8. |
| Ai-je expliqué pourquoi chaque fichier doit changer ou non ? | Oui, avec statut recommandé, risques et critères d'acceptation. |
| Ai-je proposé une roadmap par lots ? | Oui, Collision-3 à Collision-12. |
| Ai-je proposé des tests par package ? | Oui, section 13. |
| Ai-je identifié les risques ? | Oui, section 15. |
| Ai-je conservé git status initial et final ? | Oui, sections 2 et 19. |

## 21. Regard critique sur le prompt

Le prompt est utile car il interdit la correction immédiate et force une décision source-of-truth. Sa contrainte la plus importante est juste : ne pas créer une V2 tant que `collisionMask` existe déjà et n'est pas stabilisé.

Deux points demandent vigilance dans les prochains lots :

- La demande de caractériser les tests rouges sans les corriger est saine, mais Collision-3 devra accepter une petite modification de test pour le cas qui ne compile pas. Ce n'est pas une correction production.
- Le plan demande de traiter beaucoup de fichiers. Pour l'implémentation, il faut résister à l'envie de tout faire dans un seul lot. Le bon prochain mouvement est Collision-3 puis Collision-4, pas Collision-8 ou Collision-11.
