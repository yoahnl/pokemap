# Collision Lot 10 — Building Golden Slice / End-to-End Collision Authoring V0

## 1. Résumé exécutif

Collision-10 ajoute une golden slice comportementale autour d’un bâtiment réaliste, sans modification de production.

Verdict court :

- `map_core` teste la normalisation d’un profil bâtiment legacy `cells` pleines + silhouette auteur dans `manualAddedCells`.
- `map_editor` teste le chargement repository, la sauvegarde explicite du profil normalisé, les libellés de vérité UI et la preview hitbox joueur.
- `map_gameplay` teste la consommation d’un profil bâtiment normalisé : toit passable, base bloquante, profil legacy non normalisé encore sur-bloquant, priorité `collisionMask`, et hitbox joueur `12 × 8 px`.
- Aucun fichier `lib/**` n’a été modifié.
- Aucun asset, screenshot golden, runtime Flame, génération automatique, build_runner ou fichier generated n’a été ajouté.

Inventaire complet :

| Catégorie | Fichiers |
|---|---|
| Créés | `packages/map_core/test/element_collision_building_golden_slice_test.dart` |
| Créés | `packages/map_editor/test/collision_building_golden_slice_test.dart` |
| Créés | `packages/map_gameplay/test/collision_building_golden_slice_test.dart` |
| Créés | `reports/collision/collision_lot_10_building_golden_slice.md` |
| Modifiés | Aucun |
| Supprimés | Aucun |
| Générés | Aucun |
| Untracked touchés | les quatre fichiers créés ci-dessus |
| Hors lot préexistant | Aucun au status initial |

## 2. Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
```

Interprétation : le worktree était propre au début de Collision-10.

## 3. Rapports précédents relus

Rapports relus :

```text
reports/collision/collision_lot_4_element_collision_profile_normalizer.md
reports/collision/collision_lot_5_collision_mask_cells_projection_contract.md
reports/collision/collision_lot_6_editor_persistence_uses_normalizer.md
reports/collision/collision_lot_7_gameplay_legacy_fallback_hardening.md
reports/collision/collision_lot_8_ui_truth_labels.md
reports/collision/collision_lot_9_player_foot_hitbox_preview.md
```

Décisions reprises :

- Collision-4 : `normalizeElementCollisionProfile(...)` est la brique pure de normalisation.
- Collision-5 : `collisionMask -> cells` est une projection testée, stable, triée par `y` puis `x`.
- Collision-6 : `FileProjectRepository.loadProject()` normalise en mémoire après `ProjectManifest.fromJson(...)` et avant validation.
- Collision-7 : `GameplayWorldState` consomme ce qu’on lui donne, sans migration cachée.
- Collision-8 : l’UI expose `Collision fine active`, `Collision par grille`, `Aucune collision active`.
- Collision-9 : la preview hitbox joueur affiche les conventions V1 `12 × 8 px`, zone aux pieds, centrée en bas du sprite.

## 4. Audit ciblé des fixtures bâtiment

Fichiers inspectés :

```text
packages/map_core/lib/src/operations/element_collision_profile_normalizer.dart
packages/map_core/lib/src/operations/element_collision_mask_codec.dart
packages/map_core/lib/src/collision/player_collision_conventions_v1.dart
packages/map_core/lib/src/collision/pixel_rect.dart
packages/map_editor/lib/src/application/models/element_collision_truth_summary.dart
packages/map_editor/lib/src/application/models/player_collision_hitbox_preview.dart
packages/map_editor/test/element_collision_truth_summary_test.dart
packages/map_editor/test/player_collision_hitbox_preview_test.dart
packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart
packages/map_gameplay/lib/src/gameplay_world_state.dart
packages/map_gameplay/test/placed_elements_collision_test.dart
packages/map_core/pubspec.yaml
packages/map_editor/pubspec.yaml
packages/map_gameplay/pubspec.yaml
```

Recherche lancée :

```bash
rg -n "normalizeElementCollisionProfile|collisionMask|pixelMask|manualAddedCells|manualRemovedCells|shapeCells|PlayerCollisionConventionsV1|PlayerCollisionHitboxPreview|summarizeElementCollisionTruth|GameplayWorldState|placedElements|isBlocked|worldStaticObstaclesCollidePixelRect|roof|house|building" packages/map_core packages/map_editor packages/map_gameplay
```

Constats :

- `packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart` contient déjà une fixture `petite_maison_toit_bleu` avec `cells` pleines `6×7` et silhouette auteur dans `manualAddedCells`.
- `packages/map_gameplay/test/placed_elements_collision_test.dart` contient déjà des tests maison qui prouvent le profil legacy non normalisé sur-bloquant et le profil normalisé passable au toit.
- Il manquait une slice dédiée, lisible, qui relie explicitement `map_core`, `map_editor` et `map_gameplay` autour du même cas produit.
- Les `pubspec.yaml` confirment la séparation : `map_editor` dépend de `map_core`, pas de `map_gameplay`; `map_gameplay` dépend de `map_core`, pas de `map_editor`.

## 5. Design de la golden slice

Design retenu :

- créer un test dédié par package ;
- dupliquer localement la petite fixture bâtiment dans chaque test au lieu de créer un package ou une fixture globale ;
- ne créer aucun asset image ;
- ne créer aucun test screenshot ;
- ne modifier aucun fichier de production ;
- ne faire aucun import `map_editor` depuis `map_gameplay` ;
- ne faire aucun import `map_gameplay` depuis `map_editor`.

Raison :

- Le but est de prouver la chaîne produit sans violer les frontières de packages.
- La duplication de fixture reste courte et rend chaque test autonome.
- Le comportement testé est plus important qu’une factorisation prématurée.

## 6. Fixture bâtiment retenue

Dimensions :

```text
largeur : 6 cells
hauteur : 7 cells
tileSize : 16 px
placement gameplay : GridPos(x: 3, y: 2)
```

Profil legacy initial :

```text
collisionMask = null
cells = rectangle plein 6 × 7
shapeCells = []
manualAddedCells = silhouette réellement bloquante
manualRemovedCells = []
```

Silhouette bloquante retenue :

```text
y=0 : toit passable
y=1 : toit passable
y=2 : toit passable
y=3 : x=0..5 bloquants
y=4 : x=1..4 bloquants
y=5 : x=1..4 bloquants
y=6 : passable dans cette fixture
```

Liste exacte :

```dart
const List<GridPos> _buildingBlockingCells = [
  GridPos(x: 0, y: 3),
  GridPos(x: 1, y: 3),
  GridPos(x: 2, y: 3),
  GridPos(x: 3, y: 3),
  GridPos(x: 4, y: 3),
  GridPos(x: 5, y: 3),
  GridPos(x: 1, y: 4),
  GridPos(x: 2, y: 4),
  GridPos(x: 3, y: 4),
  GridPos(x: 4, y: 4),
  GridPos(x: 1, y: 5),
  GridPos(x: 2, y: 5),
  GridPos(x: 3, y: 5),
  GridPos(x: 4, y: 5),
];
```

## 7. Contrat testé par package

`map_core` :

- le profil legacy bâtiment est normalisé depuis l’intention auteur coarse ;
- `visualMask` et `occlusionMask` restent conservés, sans créer de collision ;
- `collisionMask` gagne contre les `cells` pleines legacy.

`map_editor` :

- `FileProjectRepository.loadProject()` retourne le bâtiment normalisé en mémoire ;
- `loadProject()` ne réécrit pas le fichier ;
- `saveProject(loaded)` persiste explicitement les `cells` corrigées ;
- le résumé UI affiche `Collision par grille` quand aucun masque fin n’existe ;
- le résumé UI affiche `Collision fine active` quand un masque fin existe ;
- la preview hitbox reste alignée avec `PlayerCollisionConventionsV1`.

`map_gameplay` :

- le toit du bâtiment normalisé est passable ;
- la base / le corps auteur bloque ;
- le profil legacy non normalisé reste volontairement sur-bloquant ;
- `collisionMask` ignore les `cells` contradictoires ;
- la hitbox joueur V1 `12 × 8 px` collisionne avec le corps mais pas avec le toit.

## 8. Fichiers créés

```text
packages/map_core/test/element_collision_building_golden_slice_test.dart
packages/map_editor/test/collision_building_golden_slice_test.dart
packages/map_gameplay/test/collision_building_golden_slice_test.dart
reports/collision/collision_lot_10_building_golden_slice.md
```

## 9. Fichiers modifiés

```text
Aucun
```

## 10. Fichiers explicitement non modifiés

```text
packages/map_core/lib/**
packages/map_editor/lib/**
packages/map_gameplay/lib/**
packages/map_runtime/**
packages/map_battle/**
examples/**
packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
packages/map_editor/lib/src/application/collision_generation/**
packages/map_core/test/element_collision_profile_normalizer_test.dart
packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart
packages/map_gameplay/test/placed_elements_collision_test.dart
fichiers generated
```

## 11. Tests ajoutés / modifiés

Tests ajoutés dans `packages/map_core/test/element_collision_building_golden_slice_test.dart` :

- `normalizes legacy building profile with full cells and manual silhouette`
- `building normalization preserves visual and occlusion masks without making them collision`
- `building collisionMask still wins over full legacy cells`

Tests ajoutés dans `packages/map_editor/test/collision_building_golden_slice_test.dart` :

- `load normalizes legacy building collision profile`
- `save persists normalized building cells`
- `truth summary shows grid collision when no fine mask exists`
- `truth summary shows fine collision when mask exists`
- `player hitbox preview stays aligned with gameplay conventions`

Tests ajoutés dans `packages/map_gameplay/test/collision_building_golden_slice_test.dart` :

- `normalized profile leaves roof cells passable`
- `normalized profile blocks authored body cells`
- `unnormalized legacy profile still over-blocks`
- `collisionMask wins over full legacy cells`
- `player foot hitbox collides with body but not roof`

Tests modifiés :

```text
Aucun
```

## 12. Commandes lancées

Inventaire et audit :

```bash
git status --short --untracked-files=all
find . -path './.git' -prune -o -name AGENTS.md -print
sed -n '1,220p' reports/collision/collision_lot_4_element_collision_profile_normalizer.md
sed -n '1,220p' reports/collision/collision_lot_5_collision_mask_cells_projection_contract.md
sed -n '1,220p' reports/collision/collision_lot_6_editor_persistence_uses_normalizer.md
sed -n '1,220p' reports/collision/collision_lot_7_gameplay_legacy_fallback_hardening.md
sed -n '1,220p' reports/collision/collision_lot_8_ui_truth_labels.md
sed -n '1,220p' reports/collision/collision_lot_9_player_foot_hitbox_preview.md
sed -n '1,260p' packages/map_gameplay/lib/src/gameplay_world_state.dart
sed -n '330,470p' packages/map_gameplay/lib/src/gameplay_world_state.dart
sed -n '858,1088p' packages/map_gameplay/lib/src/gameplay_world_state.dart
sed -n '1,220p' packages/map_core/lib/src/collision/player_collision_conventions_v1.dart
sed -n '1,140p' packages/map_core/lib/src/collision/pixel_rect.dart
sed -n '1,260p' packages/map_core/test/element_collision_profile_normalizer_test.dart
sed -n '1,360p' packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart
sed -n '1,980p' packages/map_gameplay/test/placed_elements_collision_test.dart
sed -n '1,220p' packages/map_editor/test/player_collision_hitbox_preview_test.dart
rg -n "normalizeElementCollisionProfile|collisionMask|pixelMask|manualAddedCells|manualRemovedCells|shapeCells|PlayerCollisionConventionsV1|PlayerCollisionHitboxPreview|summarizeElementCollisionTruth|GameplayWorldState|placedElements|isBlocked|worldStaticObstaclesCollidePixelRect|roof|house|building" packages/map_core packages/map_editor packages/map_gameplay
rg -n "bool isBlocked|isCellCenterBlockedLegacyForGridIndexedSystems|worldStaticObstaclesCollidePixelRect|_buildPixelCollisionCache|_buildPlacedElementCellCollisionCache|_placedElementPixelObstacleRects" packages/map_gameplay/lib/src/gameplay_world_state.dart
rg -n "class ElementCollisionProfile|factory ElementCollisionProfile|copyWith|enum ElementCollisionProfileSource|source" packages/map_core/lib/src/models/element_collision_profile.dart
git diff --name-only
git diff --stat
```

Baseline avant ajout :

```bash
cd packages/map_core
dart test test/element_collision_profile_normalizer_test.dart test/element_collision_mask_codec_test.dart

cd packages/map_editor
flutter test --no-pub --reporter compact test/element_collision_truth_summary_test.dart test/player_collision_hitbox_preview_test.dart test/project_element_collision_file_repository_roundtrip_test.dart

cd packages/map_gameplay
flutter test --no-pub --reporter compact test/placed_elements_collision_test.dart
```

RED TDD :

```bash
cd packages/map_core
dart test test/element_collision_building_golden_slice_test.dart

cd packages/map_editor
flutter test --no-pub --reporter expanded test/collision_building_golden_slice_test.dart

cd packages/map_gameplay
flutter test --no-pub --reporter expanded test/collision_building_golden_slice_test.dart
```

Tests après ajout :

```bash
cd packages/map_core
dart test test/element_collision_building_golden_slice_test.dart
dart test test/element_collision_building_golden_slice_test.dart test/element_collision_profile_normalizer_test.dart
dart test

cd packages/map_editor
flutter test --no-pub --reporter expanded test/collision_building_golden_slice_test.dart
flutter test --no-pub --reporter compact test/collision_building_golden_slice_test.dart test/element_collision_truth_summary_test.dart test/player_collision_hitbox_preview_test.dart test/project_element_collision_file_repository_roundtrip_test.dart

cd packages/map_gameplay
flutter test --no-pub --reporter expanded test/collision_building_golden_slice_test.dart
flutter test --no-pub --reporter compact test/collision_building_golden_slice_test.dart test/placed_elements_collision_test.dart
flutter test --no-pub --reporter compact
```

Analyse / format :

```bash
dart format packages/map_core/test/element_collision_building_golden_slice_test.dart packages/map_editor/test/collision_building_golden_slice_test.dart packages/map_gameplay/test/collision_building_golden_slice_test.dart

cd packages/map_core
dart analyze test/element_collision_building_golden_slice_test.dart

cd packages/map_editor
flutter analyze test/collision_building_golden_slice_test.dart
dart format packages/map_editor/test/collision_building_golden_slice_test.dart
flutter analyze --no-pub test/collision_building_golden_slice_test.dart

cd packages/map_gameplay
dart analyze test/collision_building_golden_slice_test.dart
```

Note sur le format :

- une commande intermédiaire `dart format packages/map_editor/test/collision_building_golden_slice_test.dart` a été lancée depuis `packages/map_editor`, donc elle a cherché un chemin préfixé deux fois et n’a formaté aucun fichier ;
- la commande correcte relancée depuis la racine a ensuite formaté le fichier attendu.

## 13. Résultats des tests map_core

Baseline :

```text
dart test test/element_collision_profile_normalizer_test.dart test/element_collision_mask_codec_test.dart
00:00 +20: All tests passed!
```

RED :

```text
dart test test/element_collision_building_golden_slice_test.dart
Failed to load "test/element_collision_building_golden_slice_test.dart": Does not exist.
00:00 +0 -1: Some tests failed.
```

Test ciblé Collision-10 :

```text
dart test test/element_collision_building_golden_slice_test.dart
00:00 +3: All tests passed!
```

Test groupé collision :

```text
dart test test/element_collision_building_golden_slice_test.dart test/element_collision_profile_normalizer_test.dart
00:00 +15: All tests passed!
```

Suite complète `map_core` :

```text
dart test
00:05 +1529: All tests passed!
```

## 14. Résultats des tests map_editor

Baseline :

```text
flutter test --no-pub --reporter compact test/element_collision_truth_summary_test.dart test/player_collision_hitbox_preview_test.dart test/project_element_collision_file_repository_roundtrip_test.dart
00:03 +12: All tests passed!
```

RED :

```text
flutter test --no-pub --reporter expanded test/collision_building_golden_slice_test.dart
Failed to load ".../packages/map_editor/test/collision_building_golden_slice_test.dart": Does not exist.
00:00 +0 -1: Some tests failed.
```

Test ciblé Collision-10 :

```text
flutter test --no-pub --reporter expanded test/collision_building_golden_slice_test.dart
00:00 +5: All tests passed!
```

Test groupé editor collision :

```text
flutter test --no-pub --reporter compact test/collision_building_golden_slice_test.dart test/element_collision_truth_summary_test.dart test/player_collision_hitbox_preview_test.dart test/project_element_collision_file_repository_roundtrip_test.dart
00:05 +17: All tests passed!
```

Suite complète `map_editor` :

Non vérifié.

**Sujet :**
Suite complète `packages/map_editor`.

**Raison :**
Collision-10 est limité à une golden slice collision et aux tests ciblés. Les lots 8/9 indiquent que la suite complète editor porte des dettes hors lot.

**Impact :**
Les contrats touchés par Collision-10 sont vérifiés par les tests editor ciblés. Les surfaces editor non liées à la collision bâtiment ne sont pas couvertes par ce lot.

**Comment vérifier dans Collision-11 ou Collision-12 :**
Lancer `cd packages/map_editor && flutter test --no-pub --reporter compact`, relever les échecs hors lot, et les classer sans modifier les générateurs collision dans Collision-10.

## 15. Résultats des tests map_gameplay

Baseline :

```text
flutter test --no-pub --reporter compact test/placed_elements_collision_test.dart
00:00 +12: All tests passed!
```

RED :

```text
flutter test --no-pub --reporter expanded test/collision_building_golden_slice_test.dart
Failed to load ".../packages/map_gameplay/test/collision_building_golden_slice_test.dart": Does not exist.
00:00 +0 -1: Some tests failed.
```

Test ciblé Collision-10 :

```text
flutter test --no-pub --reporter expanded test/collision_building_golden_slice_test.dart
00:00 +5: All tests passed!
```

Test groupé gameplay collision :

```text
flutter test --no-pub --reporter compact test/collision_building_golden_slice_test.dart test/placed_elements_collision_test.dart
00:00 +17: All tests passed!
```

Suite complète `map_gameplay` :

```text
flutter test --no-pub --reporter compact
00:01 +127: All tests passed!
```

## 16. Analyse statique / format

Format initial après création :

```text
dart format packages/map_core/test/element_collision_building_golden_slice_test.dart packages/map_editor/test/collision_building_golden_slice_test.dart packages/map_gameplay/test/collision_building_golden_slice_test.dart
Formatted packages/map_core/test/element_collision_building_golden_slice_test.dart
Formatted packages/map_editor/test/collision_building_golden_slice_test.dart
Formatted packages/map_gameplay/test/collision_building_golden_slice_test.dart
Formatted 3 files (3 changed) in 0.01 seconds.
```

Analyse `map_core` :

```text
dart analyze test/element_collision_building_golden_slice_test.dart
Analyzing element_collision_building_golden_slice_test.dart...
No issues found!
```

Analyse `map_editor` initiale :

```text
flutter analyze test/collision_building_golden_slice_test.dart
info • Use 'const' for final variables initialized to a constant value • test/collision_building_golden_slice_test.dart:187:3 • prefer_const_declarations
info • Use 'const' for final variables initialized to a constant value • test/collision_building_golden_slice_test.dart:188:3 • prefer_const_declarations
2 issues found. (ran in 1.4s)
```

Correction appliquée :

```text
final widthPx -> const widthPx
final heightPx -> const heightPx
```

Format final editor :

```text
dart format packages/map_editor/test/collision_building_golden_slice_test.dart
Formatted 1 file (0 changed) in 0.01 seconds.
```

Analyse `map_editor` finale :

```text
flutter analyze --no-pub test/collision_building_golden_slice_test.dart
Analyzing collision_building_golden_slice_test.dart...
No issues found! (ran in 1.5s)
```

Analyse `map_gameplay` :

```text
dart analyze test/collision_building_golden_slice_test.dart
Analyzing collision_building_golden_slice_test.dart...
No issues found!
```

## 17. Vérification du périmètre

Commande :

```bash
git diff --name-only
```

Sortie exacte finale :

```text
```

Commande :

```bash
git diff --stat
```

Sortie exacte finale :

```text
```

Conclusion :

- aucun fichier tracked n’est modifié ;
- les changements Collision-10 sont des fichiers créés non suivis ;
- aucun fichier `packages/*/lib/**` n’apparaît ;
- aucun fichier generated n’apparaît.

## 18. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
?? packages/map_core/test/element_collision_building_golden_slice_test.dart
?? packages/map_editor/test/collision_building_golden_slice_test.dart
?? packages/map_gameplay/test/collision_building_golden_slice_test.dart
?? reports/collision/collision_lot_10_building_golden_slice.md
```

## 19. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
```

Note : les fichiers Collision-10 sont non suivis, donc `git diff --stat` ne les affiche pas.

## 20. Risques / réserves

- La fixture bâtiment est synthétique et sans asset image ; elle prouve le contrat de données et de gameplay, pas le rendu visuel d’un PNG.
- La slice ne vérifie pas un écran Flutter complet avec screenshot golden.
- La suite complète `map_editor` n’a pas été lancée dans Collision-10 ; les tests editor liés à la collision bâtiment, aux libellés et au repository sont verts.
- Les helpers fixture sont dupliqués dans trois packages pour préserver les frontières de dépendance.
- Le test `collisionMask` côté gameplay utilise un mask synthétique plein par cellule, pas une silhouette pixel fine complexe de bâtiment.

## 21. Ce que cette golden slice prouve

- Un vieux profil bâtiment `cells` pleines + `manualAddedCells` silhouette est normalisé par `map_core`.
- `visualMask` et `occlusionMask` restent hors collision.
- `FileProjectRepository.loadProject()` normalise le bâtiment en mémoire sans réécrire le fichier.
- `saveProject(loaded)` persiste ensuite les `cells` corrigées.
- Le read-model UI affiche la bonne vérité : `Collision par grille` sans masque fin, `Collision fine active` avec masque fin.
- La preview hitbox editor reste cohérente avec `PlayerCollisionConventionsV1`.
- `GameplayWorldState` rend le toit passable avec un manifest normalisé.
- `GameplayWorldState` bloque la base / le corps auteur avec un manifest normalisé.
- Un manifest legacy non normalisé reste sur-bloquant, ce qui protège l’absence de migration cachée dans gameplay.
- `collisionMask` reste prioritaire sur `cells`.
- La hitbox joueur `12 × 8 px` collisionne avec le corps mais pas avec le toit.

## 22. Ce que cette golden slice ne prouve pas encore

Non vérifié.

**Sujet :**
Rendu runtime Flame et occlusion runtime.

**Raison :**
Collision-10 exclut `map_runtime` et l’occlusion runtime.

**Impact :**
La slice prouve le contrat collision et les read-models editor, pas le rendu devant/derrière.

**Comment vérifier dans Collision-12 :**
Créer un rapport ou des tests runtime dédiés à l’occlusion, sans mélanger `occlusionMask` et collision.

Non vérifié.

**Sujet :**
Génération automatique de collision depuis image / alpha.

**Raison :**
Collision-10 exclut `PlacedElementAutoCollisionGenerator`, `PlacedElementCollisionParams` et les heuristiques alpha.

**Impact :**
La slice ne prouve pas que la génération automatique produit cette silhouette bâtiment.

**Comment vérifier dans Collision-11 :**
Comparer la documentation et les heuristiques de génération automatique avec une fixture bâtiment, puis ajouter des tests dédiés au générateur.

Non vérifié.

**Sujet :**
Golden screenshot editor.

**Raison :**
Collision-10 définit “golden slice” comme slice comportementale, pas comme capture Flutter.

**Impact :**
Les labels et read-models sont testés ; la composition visuelle complète de l’écran n’est pas figée par image.

**Comment vérifier dans Collision-10-bis :**
Ajouter un test widget léger ou une capture Playwright/Flutter si le projet stabilise une surface UI dédiée à l’éditeur collision.

## 23. Recommandation après Collision-10

Recommandation :

1. Lancer Collision-11 sur l’alignement documentation / heuristiques de génération automatique, sans toucher à la slice gameplay.
2. Garder la fixture bâtiment Collision-10 comme référence comportementale pour toute évolution de génération collision.
3. Reporter l’occlusion runtime à Collision-12, avec un rapport séparé pour éviter de mélanger collision de déplacement et rendu devant/derrière.

## 24. Auto-review finale

| Question | Réponse |
|---|---|
| Ai-je évité les changements de production ? | Oui, aucun fichier `lib/**` n’est créé ou modifié. |
| Ai-je testé un bâtiment réaliste ? | Oui, bâtiment `6×7`, toit passable, base bloquante. |
| Ai-je testé le profil legacy normalisé ? | Oui, `map_core`, `map_editor`, `map_gameplay`. |
| Ai-je testé le profil legacy non normalisé ? | Oui, côté `map_gameplay`. |
| Ai-je testé le toit passable ? | Oui, coordonnées monde `(3,2)` et `(8,4)`. |
| Ai-je testé la base bloquante ? | Oui, coordonnées monde `(3,5)` et `(7,7)`. |
| Ai-je respecté la séparation packages ? | Oui, aucun import interdit. |
| Ai-je évité FileProjectRepository dans map_gameplay ? | Oui. |
| Ai-je évité GameplayWorldState dans map_editor ? | Oui. |
| Ai-je évité runtime Flame ? | Oui. |
| Ai-je évité les assets externes ? | Oui. |
| Ai-je gardé les tests lisibles ? | Oui, helpers locaux courts et fixture explicite. |
| Ai-je documenté ce que la golden slice prouve et ne prouve pas ? | Oui. |

## 25. Contenu complet des fichiers créés/modifiés

### `packages/map_core/test/element_collision_building_golden_slice_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('building collision golden slice', () {
    test(
        'normalizes legacy building profile with full cells and manual silhouette',
        () {
      final profile = ElementCollisionProfile(
        source: ElementCollisionProfileSource.manual,
        cells: _legacyFullCells(),
        manualAddedCells: _buildingBlockingCells,
      );

      final normalized = normalizeElementCollisionProfile(
        profile,
        tileSize: _tileSize,
      );

      expect(normalized.cells, _buildingBlockingCells);
      expect(normalized.manualAddedCells, _buildingBlockingCells);
      expect(normalized.shapeCells, isEmpty);
      expect(normalized.manualRemovedCells, isEmpty);
      expect(normalized.collisionMask, isNull);
    });

    test(
        'building normalization preserves visual and occlusion masks without making them collision',
        () {
      final visualMask = _maskFromCells(
        solidCells: const [GridPos(x: 0, y: 0)],
      );
      final occlusionMask = _maskFromCells(
        solidCells: const [GridPos(x: 5, y: 0)],
      );
      final profile = ElementCollisionProfile(
        source: ElementCollisionProfileSource.manual,
        visualMask: visualMask,
        occlusionMask: occlusionMask,
        cells: _legacyFullCells(),
        manualAddedCells: _buildingBlockingCells,
      );

      final normalized = normalizeElementCollisionProfile(
        profile,
        tileSize: _tileSize,
      );

      expect(normalized.visualMask, same(visualMask));
      expect(normalized.occlusionMask, same(occlusionMask));
      expect(normalized.collisionMask, isNull);
      expect(normalized.cells, _buildingBlockingCells);
    });

    test('building collisionMask still wins over full legacy cells', () {
      final collisionMask = _maskFromCells(
        solidCells: const [GridPos(x: 2, y: 5)],
      );
      final profile = ElementCollisionProfile(
        source: ElementCollisionProfileSource.manual,
        collisionMask: collisionMask,
        cells: _legacyFullCells(),
        manualAddedCells: _buildingBlockingCells,
      );

      final normalized = normalizeElementCollisionProfile(
        profile,
        tileSize: _tileSize,
      );

      expect(normalized.collisionMask, same(collisionMask));
      expect(normalized.cells, const [GridPos(x: 2, y: 5)]);
      expect(normalized.manualAddedCells, _buildingBlockingCells);
    });
  });
}

ElementCollisionPixelMask _maskFromCells({
  required List<GridPos> solidCells,
}) {
  final pixels = List<bool>.filled(
    _buildingWidthCells * _tileSize * _buildingHeightCells * _tileSize,
    false,
  );
  final widthPx = _buildingWidthCells * _tileSize;
  final heightPx = _buildingHeightCells * _tileSize;
  for (final cell in solidCells) {
    for (var y = cell.y * _tileSize; y < (cell.y + 1) * _tileSize; y++) {
      for (var x = cell.x * _tileSize; x < (cell.x + 1) * _tileSize; x++) {
        pixels[y * widthPx + x] = true;
      }
    }
  }
  return ElementCollisionPixelMask(
    widthPx: widthPx,
    heightPx: heightPx,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: widthPx,
      heightPx: heightPx,
      solidPixels: pixels,
    ),
  );
}

List<GridPos> _legacyFullCells() {
  return [
    for (var y = 0; y < _buildingHeightCells; y++)
      for (var x = 0; x < _buildingWidthCells; x++) GridPos(x: x, y: y),
  ];
}

const int _tileSize = 16;
const int _buildingWidthCells = 6;
const int _buildingHeightCells = 7;

const List<GridPos> _buildingBlockingCells = [
  GridPos(x: 0, y: 3),
  GridPos(x: 1, y: 3),
  GridPos(x: 2, y: 3),
  GridPos(x: 3, y: 3),
  GridPos(x: 4, y: 3),
  GridPos(x: 5, y: 3),
  GridPos(x: 1, y: 4),
  GridPos(x: 2, y: 4),
  GridPos(x: 3, y: 4),
  GridPos(x: 4, y: 4),
  GridPos(x: 1, y: 5),
  GridPos(x: 2, y: 5),
  GridPos(x: 3, y: 5),
  GridPos(x: 4, y: 5),
];
```

### `packages/map_editor/test/collision_building_golden_slice_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/element_collision_truth_summary.dart';
import 'package:map_editor/src/application/models/player_collision_hitbox_preview.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  group('building collision golden slice', () {
    test('load normalizes legacy building collision profile', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'collision_building_golden_load_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final manifestPath = p.join(tempDir.path, 'project.json');
      final file = File(manifestPath);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ')
            .convert(_legacyBuildingProjectJson()),
      );
      final beforeLoad = await file.readAsString();

      final loaded = await FileProjectRepository().loadProject(manifestPath);
      final profile = loaded.elements.single.collisionProfile!;
      final afterLoad = await file.readAsString();

      expect(profile.cells, _buildingBlockingCells);
      expect(profile.manualAddedCells, _buildingBlockingCells);
      expect(profile.shapeCells, isEmpty);
      expect(profile.manualRemovedCells, isEmpty);
      expect(afterLoad, beforeLoad);
    });

    test('save persists normalized building cells', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'collision_building_golden_save_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final manifestPath = p.join(tempDir.path, 'project.json');
      final file = File(manifestPath);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ')
            .convert(_legacyBuildingProjectJson()),
      );

      final repository = FileProjectRepository();
      final loaded = await repository.loadProject(manifestPath);
      await repository.saveProject(loaded, manifestPath);

      final savedJson =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final savedProfile = (((savedJson['elements'] as List).single
          as Map<String, dynamic>)['collisionProfile'] as Map<String, dynamic>);

      expect(savedProfile['cells'], _buildingBlockingCellsJson());
      expect(savedProfile['manualAddedCells'], _buildingBlockingCellsJson());
      expect(savedProfile['shapeCells'], isEmpty);
      expect(savedProfile['manualRemovedCells'], isEmpty);
    });

    test('truth summary shows grid collision when no fine mask exists', () {
      final profile = normalizeElementCollisionProfile(
        ElementCollisionProfile(
          source: ElementCollisionProfileSource.manual,
          cells: _legacyFullCells(),
          manualAddedCells: _buildingBlockingCells,
        ),
        tileSize: _tileSize,
      );

      final summary = summarizeElementCollisionTruth(profile);

      expect(summary.mode, ElementCollisionTruthMode.legacyCells);
      expect(summary.title, 'Collision par grille');
      expect(summary.description, contains('fallback'));
      expect(summary.hasCollisionMask, isFalse);
      expect(summary.hasLegacyCells, isTrue);
    });

    test('truth summary shows fine collision when mask exists', () {
      final profile = ElementCollisionProfile(
        source: ElementCollisionProfileSource.manual,
        collisionMask: _maskFromCells(
          solidCells: const [GridPos(x: 2, y: 5)],
        ),
        cells: _legacyFullCells(),
      );

      final summary = summarizeElementCollisionTruth(profile);

      expect(summary.mode, ElementCollisionTruthMode.fineMask);
      expect(summary.title, 'Collision fine active');
      expect(summary.description, contains('masque de collision fin'));
      expect(summary.hasCollisionMask, isTrue);
    });

    test('player hitbox preview stays aligned with gameplay conventions', () {
      final preview = buildPlayerCollisionHitboxPreview();

      expect(preview.dimensionsLabel, '12 × 8 px');
      expect(
        preview.hitboxWidthPx,
        PlayerCollisionConventionsV1.playerHitboxWidthPx,
      );
      expect(
        preview.hitboxHeightPx,
        PlayerCollisionConventionsV1.playerHitboxHeightPx,
      );
      expect(preview.hitboxLeftPx, 10);
      expect(preview.hitboxTopPx, 24);
      expect(preview.description, contains('zone aux pieds'));
      expect(preview.positionLabel, contains('centrée en bas'));
    });
  });
}

Map<String, dynamic> _legacyBuildingProjectJson() {
  return <String, dynamic>{
    'name': 'Building Golden Slice',
    'maps': <dynamic>[],
    'tilesets': <dynamic>[
      <String, dynamic>{
        'id': 'house',
        'name': 'house',
        'relativePath': 'tilesets/house.png',
      },
    ],
    'elementCategories': <dynamic>[
      <String, dynamic>{'id': 'building', 'name': 'building'},
    ],
    'settings': const <String, dynamic>{
      'tileWidth': _tileSize,
      'tileHeight': _tileSize,
    },
    'elements': <dynamic>[
      <String, dynamic>{
        'id': 'petite_maison_toit_bleu',
        'name': 'petite maison toit bleu',
        'tilesetId': 'house',
        'categoryId': 'building',
        'frames': const <Map<String, dynamic>>[
          <String, dynamic>{
            'tilesetId': '',
            'source': <String, dynamic>{
              'x': 0,
              'y': 341,
              'width': _buildingWidthCells,
              'height': _buildingHeightCells,
            },
          },
        ],
        'presetKind': 'building',
        'collisionProfile': <String, dynamic>{
          'source': 'manual',
          'padding': const <String, dynamic>{
            'top': 0,
            'right': 0,
            'bottom': 0,
            'left': 0,
          },
          'shapeCells': <dynamic>[],
          'cells': _legacyFullCellsJson(),
          'manualAddedCells': _buildingBlockingCellsJson(),
          'manualRemovedCells': <dynamic>[],
        },
      },
    ],
  };
}

ElementCollisionPixelMask _maskFromCells({
  required List<GridPos> solidCells,
}) {
  const widthPx = _buildingWidthCells * _tileSize;
  const heightPx = _buildingHeightCells * _tileSize;
  final pixels = List<bool>.filled(widthPx * heightPx, false);
  for (final cell in solidCells) {
    for (var y = cell.y * _tileSize; y < (cell.y + 1) * _tileSize; y++) {
      for (var x = cell.x * _tileSize; x < (cell.x + 1) * _tileSize; x++) {
        pixels[y * widthPx + x] = true;
      }
    }
  }
  return ElementCollisionPixelMask(
    widthPx: widthPx,
    heightPx: heightPx,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: widthPx,
      heightPx: heightPx,
      solidPixels: pixels,
    ),
  );
}

List<GridPos> _legacyFullCells() {
  return [
    for (var y = 0; y < _buildingHeightCells; y++)
      for (var x = 0; x < _buildingWidthCells; x++) GridPos(x: x, y: y),
  ];
}

List<Map<String, dynamic>> _legacyFullCellsJson() {
  return _legacyFullCells()
      .map((cell) => <String, dynamic>{'x': cell.x, 'y': cell.y})
      .toList(growable: false);
}

List<Map<String, dynamic>> _buildingBlockingCellsJson() {
  return _buildingBlockingCells
      .map((cell) => <String, dynamic>{'x': cell.x, 'y': cell.y})
      .toList(growable: false);
}

const int _tileSize = 16;
const int _buildingWidthCells = 6;
const int _buildingHeightCells = 7;

const List<GridPos> _buildingBlockingCells = [
  GridPos(x: 0, y: 3),
  GridPos(x: 1, y: 3),
  GridPos(x: 2, y: 3),
  GridPos(x: 3, y: 3),
  GridPos(x: 4, y: 3),
  GridPos(x: 5, y: 3),
  GridPos(x: 1, y: 4),
  GridPos(x: 2, y: 4),
  GridPos(x: 3, y: 4),
  GridPos(x: 4, y: 4),
  GridPos(x: 1, y: 5),
  GridPos(x: 2, y: 5),
  GridPos(x: 3, y: 5),
  GridPos(x: 4, y: 5),
];
```

### `packages/map_gameplay/test/collision_building_golden_slice_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('building collision golden slice', () {
    test('normalized profile leaves roof cells passable', () {
      final world = _buildingWorld(project: _normalizedBuildingProject());

      expect(world.isBlocked(3, 2), isFalse);
      expect(world.isBlocked(8, 4), isFalse);
    });

    test('normalized profile blocks authored body cells', () {
      final world = _buildingWorld(project: _normalizedBuildingProject());

      expect(world.isBlocked(3, 5), isTrue);
      expect(world.isBlocked(7, 7), isTrue);
      expect(world.isBlocked(4, 8), isFalse);
    });

    test('unnormalized legacy profile still over-blocks', () {
      final world = _buildingWorld(project: _legacyBuildingProject());

      expect(world.isBlocked(3, 2), isTrue);
      expect(world.isBlocked(8, 4), isTrue);
      expect(world.isBlocked(3, 5), isTrue);
      expect(world.isBlocked(7, 7), isTrue);
    });

    test('collisionMask wins over full legacy cells', () {
      final world = _buildingWorld(project: _maskBuildingProject());

      expect(
        world.isCellCenterBlockedLegacyForGridIndexedSystems(3, 2),
        isFalse,
      );
      expect(
        world.worldStaticObstaclesCollidePixelRect(
          const PixelRect(
            leftPx: 3 * _tileSize + 1,
            topPx: 2 * _tileSize + 1,
            widthPx: 1,
            heightPx: 1,
          ),
        ),
        isFalse,
      );
      expect(
        world.worldStaticObstaclesCollidePixelRect(
          const PixelRect(
            leftPx: 3 * _tileSize + 1,
            topPx: 5 * _tileSize + 1,
            widthPx: 1,
            heightPx: 1,
          ),
        ),
        isTrue,
      );
    });

    test('player foot hitbox collides with body but not roof', () {
      final world = _buildingWorld(project: _normalizedBuildingProject());
      final roofHitbox = _playerHitboxInsideWorldCell(
        const GridPos(x: 3, y: 2),
      );
      final bodyHitbox = _playerHitboxInsideWorldCell(
        const GridPos(x: 3, y: 5),
      );

      expect(world.worldStaticObstaclesCollidePixelRect(roofHitbox), isFalse);
      expect(world.worldStaticObstaclesCollidePixelRect(bodyHitbox), isTrue);
      expect(
          roofHitbox.widthPx, PlayerCollisionConventionsV1.playerHitboxWidthPx);
      expect(
        roofHitbox.heightPx,
        PlayerCollisionConventionsV1.playerHitboxHeightPx,
      );
    });
  });
}

GameplayWorldState _buildingWorld({
  required ProjectManifest project,
}) {
  return GameplayWorldState.initial(
    map: _buildingMap(),
    playerPos: const GridPos(x: 0, y: 0),
    project: project,
  );
}

MapData _buildingMap() {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 12, height: 12),
    layers: [
      MapLayer.tile(
        id: 'tile',
        name: 'Tile',
        tiles: List<int>.filled(144, 0),
      ),
    ],
    placedElements: const [
      MapPlacedElement(
        id: 'house::3::2',
        layerId: 'tile',
        elementId: 'petite_maison_toit_bleu',
        pos: GridPos(x: 3, y: 2),
        applyCollision: true,
      ),
    ],
  );
}

ProjectManifest _legacyBuildingProject() {
  return ProjectManifest.fromJson(
    migrateProjectManifestJson(_legacyBuildingProjectJson()),
  );
}

ProjectManifest _normalizedBuildingProject() {
  return _normalizeCollisionProfiles(_legacyBuildingProject());
}

ProjectManifest _maskBuildingProject() {
  final base = _legacyBuildingProject();
  return base.copyWith(
    elements: [
      for (final element in base.elements)
        element.copyWith(
          collisionProfile: ElementCollisionProfile(
            source: ElementCollisionProfileSource.manual,
            collisionMask: _maskFromCells(solidCells: _buildingBlockingCells),
            cells: _legacyFullCells(),
            manualAddedCells: _buildingBlockingCells,
          ),
        ),
    ],
  );
}

ProjectManifest _normalizeCollisionProfiles(ProjectManifest project) {
  final tileSize = project.settings.tileWidth;
  return project.copyWith(
    elements: [
      for (final element in project.elements)
        element.collisionProfile == null
            ? element
            : element.copyWith(
                collisionProfile: normalizeElementCollisionProfile(
                  element.collisionProfile!,
                  tileSize: tileSize,
                ),
              ),
    ],
  );
}

PixelRect _playerHitboxInsideWorldCell(GridPos cell) {
  const insetPx = 2;
  final targetLeft = cell.x * _tileSize + insetPx;
  final targetTop = cell.y * _tileSize + 4;
  return PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(
    spriteTopLeftPx: PixelPosition(
      leftPx: targetLeft -
          (PlayerCollisionConventionsV1.defaultSpriteWidthPx -
                  PlayerCollisionConventionsV1.playerHitboxWidthPx) ~/
              2,
      topPx: targetTop -
          PlayerCollisionConventionsV1.defaultSpriteHeightPx +
          PlayerCollisionConventionsV1.playerHitboxHeightPx,
    ),
    spriteWidthPx: PlayerCollisionConventionsV1.defaultSpriteWidthPx,
    spriteHeightPx: PlayerCollisionConventionsV1.defaultSpriteHeightPx,
  );
}

ElementCollisionPixelMask _maskFromCells({
  required List<GridPos> solidCells,
}) {
  final widthPx = _buildingWidthCells * _tileSize;
  final heightPx = _buildingHeightCells * _tileSize;
  final pixels = List<bool>.filled(widthPx * heightPx, false);
  for (final cell in solidCells) {
    for (var y = cell.y * _tileSize; y < (cell.y + 1) * _tileSize; y++) {
      for (var x = cell.x * _tileSize; x < (cell.x + 1) * _tileSize; x++) {
        pixels[y * widthPx + x] = true;
      }
    }
  }
  return ElementCollisionPixelMask(
    widthPx: widthPx,
    heightPx: heightPx,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: widthPx,
      heightPx: heightPx,
      solidPixels: pixels,
    ),
  );
}

Map<String, dynamic> _legacyBuildingProjectJson() {
  return <String, dynamic>{
    'name': 'Building Golden Slice',
    'maps': <dynamic>[],
    'tilesets': <dynamic>[
      <String, dynamic>{
        'id': 'ts',
        'name': 'ts',
        'relativePath': 'ts.png',
      },
    ],
    'elementCategories': <dynamic>[
      <String, dynamic>{'id': 'cat', 'name': 'cat'},
    ],
    'settings': const <String, dynamic>{
      'tileWidth': _tileSize,
      'tileHeight': _tileSize,
    },
    'elements': <dynamic>[
      <String, dynamic>{
        'id': 'petite_maison_toit_bleu',
        'name': 'petite maison toit bleu',
        'tilesetId': 'ts',
        'categoryId': 'cat',
        'frames': const <Map<String, dynamic>>[
          <String, dynamic>{
            'tilesetId': '',
            'source': <String, dynamic>{
              'x': 0,
              'y': 341,
              'width': _buildingWidthCells,
              'height': _buildingHeightCells,
            },
          },
        ],
        'presetKind': 'building',
        'collisionProfile': <String, dynamic>{
          'source': 'manual',
          'padding': const <String, dynamic>{
            'top': 0,
            'right': 0,
            'bottom': 0,
            'left': 0,
          },
          'shapeCells': <dynamic>[],
          'cells': _legacyFullCellsJson(),
          'manualAddedCells': _buildingBlockingCellsJson(),
          'manualRemovedCells': <dynamic>[],
        },
      },
    ],
  };
}

List<GridPos> _legacyFullCells() {
  return [
    for (var y = 0; y < _buildingHeightCells; y++)
      for (var x = 0; x < _buildingWidthCells; x++) GridPos(x: x, y: y),
  ];
}

List<Map<String, dynamic>> _legacyFullCellsJson() {
  return _legacyFullCells()
      .map((cell) => <String, dynamic>{'x': cell.x, 'y': cell.y})
      .toList(growable: false);
}

List<Map<String, dynamic>> _buildingBlockingCellsJson() {
  return _buildingBlockingCells
      .map((cell) => <String, dynamic>{'x': cell.x, 'y': cell.y})
      .toList(growable: false);
}

const int _tileSize = 16;
const int _buildingWidthCells = 6;
const int _buildingHeightCells = 7;

const List<GridPos> _buildingBlockingCells = [
  GridPos(x: 0, y: 3),
  GridPos(x: 1, y: 3),
  GridPos(x: 2, y: 3),
  GridPos(x: 3, y: 3),
  GridPos(x: 4, y: 3),
  GridPos(x: 5, y: 3),
  GridPos(x: 1, y: 4),
  GridPos(x: 2, y: 4),
  GridPos(x: 3, y: 4),
  GridPos(x: 4, y: 4),
  GridPos(x: 1, y: 5),
  GridPos(x: 2, y: 5),
  GridPos(x: 3, y: 5),
  GridPos(x: 4, y: 5),
];
```
