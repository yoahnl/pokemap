# Collision Lot 3 — Red Tests Triage / Legacy Contract Clarification

## 1. Résumé exécutif

Collision-3 clarifie les tests rouges sans implémenter le normalizer.

Verdict court :

- le test editor qui ne compilait plus est corrigé côté test uniquement ;
- le test repository legacy est séparé en comportement actuel vert et contrat futur skip ;
- les tests gameplay legacy sont séparés en caractérisation actuelle verte et contrats futurs skip ;
- aucun fichier de production n'est modifié ;
- Collision-4 peut créer le normalizer pur `map_core` avec des attentes explicites.

Le travail a été réalisé dans le worktree isolé :

```text
/Users/karim/.config/superpowers/worktrees/pokemonProject/collision-source-of-truth-worktree
```

Les rapports Collision V0 et Collision-2 étaient non suivis dans le workspace principal et absents du worktree frais. Ils ont donc été relus depuis :

```text
/Users/karim/Project/pokemonProject/reports/collision/collision_system_audit_v0.md
/Users/karim/Project/pokemonProject/reports/collision/collision_lot_2_source_of_truth_implementation_plan.md
```

## 2. Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte dans le worktree Collision-3 :

```text
```

Interprétation :

- Aucun fichier modifié au départ dans le worktree Collision-3.
- Les rapports précédents étaient disponibles dans le workspace principal, pas dans ce worktree frais.

## 3. Rappel du contrat source-of-truth

Contrat repris des rapports Collision V0 et Collision-2 :

| Donnée | Statut |
|---|---|
| `collisionMask` | Vérité gameplay fine des éléments placés |
| `pixelMask` | Nom JSON historique de `collisionMask` |
| `cells` | Projection legacy, fallback et debug coarse |
| `shapeCells` | Intention auteur coarse |
| `manualAddedCells` | Retouches auteur coarse positives |
| `manualRemovedCells` | Retouches auteur coarse négatives |
| `visualMask` | Preview/analyse, pas collision |
| `occlusionMask` | Futur rendu/occlusion, pas collision |

Pourquoi Collision-3 existe :

- Les tests rouges mélangeaient trois sujets distincts : un bug de compilation test, un contrat futur repository, et un contrat futur gameplay.
- Créer le normalizer avant de clarifier les tests aurait rendu le lot Collision-4 ambigu.
- Les tests doivent distinguer le comportement actuel acceptable du comportement futur attendu.

Pourquoi le normalizer n'est pas créé ici :

- Le contrat du lot interdit toute modification de production.
- Le futur fichier `element_collision_profile_normalizer.dart` appartient à Collision-4.
- `FileProjectRepository.loadProject()` et `GameplayWorldState` doivent rester inchangés dans ce lot.

## 4. Tests rouges avant modification

### 4.1 `project_element_collision_persistence_test.dart`

Commande :

```bash
cd packages/map_editor
flutter test --reporter expanded test/project_element_collision_persistence_test.dart
```

Sortie utile :

```text
test/project_element_collision_persistence_test.dart:163:48: Error: Cannot invoke a non-'const' constructor where a const expression is expected.
  return const ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(),
                                               ^^^^^^^^^^^^^^^^^^^^^
test/project_element_collision_persistence_test.dart:163:16: Error: Cannot invoke a non-'const' factory where a const expression is expected.
  return const ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(),
               ^^^^^^^^^^^^^^^
00:00 +0 -1: Some tests failed.
```

Cause :

- Le helper `_projectManifest()` utilisait `const ProjectManifest(...)` avec `ProjectSurfaceCatalog()`, qui n'est pas const.
- Le test échouait au chargement, avant d'exercer la collision.

Décision de triage :

- Corriger le helper de test.
- Ne pas modifier `ProjectManifest`.
- Ne pas modifier `ProjectSurfaceCatalog`.

### 4.2 `project_element_collision_file_repository_roundtrip_test.dart`

Commande :

```bash
cd packages/map_editor
flutter test --reporter expanded test/project_element_collision_file_repository_roundtrip_test.dart
```

Sortie utile :

```text
00:00 +0: FileProjectRepository collision roundtrip load migrates broken manual profile and save persists corrected cells
FileProjectRepository: Loading project from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/collision_repo_roundtrip_JPkXm7/project.json
00:00 +0 -1: FileProjectRepository collision roundtrip load migrates broken manual profile and save persists corrected cells [E]
  Expected: [
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
              GridPos(x: 4, y: 5)
            ]
    Actual: [
              GridPos(x: 0, y: 0),
              GridPos(x: 1, y: 0),
              GridPos(x: 2, y: 0),
              GridPos(x: 3, y: 0),
              GridPos(x: 4, y: 0),
              GridPos(x: 5, y: 0),
              GridPos(x: 0, y: 1),
              ...
            ]
     Which: at location [0] is GridPos(x: 0, y: 0) instead of GridPos(x: 0, y: 3)
00:00 +0 -1: Some tests failed.
```

Cause :

- Le JSON legacy contient `cells` en rectangle plein 6x7.
- L'intention auteur est dans `manualAddedCells`.
- `FileProjectRepository.loadProject()` ne normalise pas encore les profils collision.

Décision de triage :

- Option B appliquée.
- Ajouter un test vert qui décrit le comportement actuel.
- Conserver le contrat futur avec le corps du test et le placer en skip précis Collision-4/Collision-6.

### 4.3 `placed_elements_collision_test.dart`

Commande :

```bash
cd packages/map_gameplay
flutter test --reporter expanded test/placed_elements_collision_test.dart
```

Sortie utile :

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

Cause :

- `GameplayWorldState` lit `collisionMask` en premier.
- Quand `collisionMask` est absent, `GameplayWorldState` utilise `cells` comme fallback legacy.
- Les fixtures legacy testées ont des `cells` pleines.
- Le futur normalizer doit réparer ces profils en amont.

Décision de triage :

- Ne pas modifier `GameplayWorldState`.
- Ajouter des tests verts qui décrivent le comportement actuel.
- Conserver les contrats futurs en skip précis Collision-4/Collision-7.

### 4.4 Effet `.dart_tool` pendant reproduction

Après les commandes de reproduction, le test runner a modifié des fichiers tracked historiques :

```text
packages/map_gameplay/.dart_tool/package_config.json
packages/map_gameplay/.dart_tool/package_graph.json
```

Commande de contrôle :

```bash
git diff --name-only
```

Sortie observée pendant mitigation :

```text
packages/map_gameplay/.dart_tool/package_config.json
packages/map_gameplay/.dart_tool/package_graph.json
```

Action de mitigation exécutée :

```bash
git show HEAD:packages/map_gameplay/.dart_tool/package_config.json > packages/map_gameplay/.dart_tool/package_config.json
git show HEAD:packages/map_gameplay/.dart_tool/package_graph.json > packages/map_gameplay/.dart_tool/package_graph.json
git diff --name-only -- packages/map_gameplay/.dart_tool/package_config.json packages/map_gameplay/.dart_tool/package_graph.json
```

Sortie finale de cette mitigation :

```text
```

Décision :

- Ne pas inclure ces fichiers dans Collision-3.
- Utiliser ensuite `flutter test --no-pub` pour éviter une nouvelle résolution de dépendances.

## 5. Décisions de triage

| Zone | Décision | Raison |
|---|---|---|
| Test editor persistence | Corriger le helper non const | Bug de test sans lien collision. |
| Test repository legacy | Option B | La suite doit être verte maintenant sans perdre le contrat futur. |
| Tests gameplay legacy | Caractérisation actuelle + skips futurs | Le fallback legacy est le comportement actuel; le normalizer appartient à Collision-4. |
| Production | Aucun changement | Interdit par le lot et non nécessaire. |
| `.dart_tool` | Mitigation à zéro diff | Effet de test runner, hors périmètre Collision-3. |

## 6. Fichiers modifiés

Fichiers de test modifiés :

```text
packages/map_editor/test/project_element_collision_persistence_test.dart
packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart
packages/map_gameplay/test/placed_elements_collision_test.dart
```

Rapport créé :

```text
reports/collision/collision_lot_3_red_tests_triage.md
```

Fichiers de production modifiés :

```text
Aucun
```

Fichiers generated conservés sans diff final :

```text
packages/map_gameplay/.dart_tool/package_config.json
packages/map_gameplay/.dart_tool/package_graph.json
```

## 7. Changements réalisés fichier par fichier

### `packages/map_editor/test/project_element_collision_persistence_test.dart`

Changement :

- remplacement de `return const ProjectManifest(...)` par `return ProjectManifest(...)`;
- conservation de `const` sur les listes et entrées qui peuvent rester const ;
- aucune modification des assertions collision.

Raison :

- `ProjectSurfaceCatalog()` n'est pas const.
- Le test devait compiler avant de tester la persistance collision.

### `packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart`

Changements :

- ajout du test vert `load currently preserves legacy cells before Collision-4 normalizer`;
- conservation du test futur sous le nom `future normalizer contract migrates broken manual profile and save persists corrected cells`;
- ajout d'un skip précis Collision-4/Collision-6 ;
- ajout du helper `_legacyFullCells()`.

Contrat actuel documenté :

- le repository préserve les `cells` legacy pleines ;
- `shapeCells` reste vide ;
- `manualAddedCells` conserve l'intention auteur.

Contrat futur conservé :

- le normalizer devra migrer les profils legacy et persister les cellules corrigées.

### `packages/map_gameplay/test/placed_elements_collision_test.dart`

Changements :

- renommage du test mask/cells contradictoires en `uses collisionMask before legacy cells when both exist`;
- ajout du test vert `falls back to legacy cells when collisionMask is absent`;
- ajout du test vert `currently over-blocks unnormalized legacy full cells`;
- conservation des deux contrats futurs avec skip précis Collision-4/Collision-7.

Contrat actuel documenté :

- `collisionMask` gagne contre `cells`;
- `cells` sert de fallback quand `collisionMask` est absent;
- un profil legacy non normalisé bloque trop large aujourd'hui.

Contrat futur conservé :

- un profil normalisé doit garder le toit passable et bloquer uniquement la silhouette auteur.

## 8. Tests skip ajoutés ou conservés

| Fichier | Test | Raison |
|---|---|---|
| `packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart` | `future normalizer contract migrates broken manual profile and save persists corrected cells` | `Pending Collision-4/Collision-6: legacy collision profile normalizer is not implemented or wired into FileProjectRepository yet.` |
| `packages/map_gameplay/test/placed_elements_collision_test.dart` | `future normalizer contract keeps legacy roof area passable before gameplay reads placed element cells` | `Pending Collision-4/Collision-7: ElementCollisionProfile normalizer is not implemented before GameplayWorldState consumes legacy cells.` |
| `packages/map_gameplay/test/placed_elements_collision_test.dart` | `future normalizer contract keeps placed element id isolation` | `Pending Collision-4/Collision-7: normalized placed element profiles are not available to gameplay yet.` |

Nombre total de skips ajoutés/conservés par Collision-3 :

```text
3
```

## 9. Tests relancés après modification

Commandes expanded :

```bash
cd packages/map_editor
flutter test --no-pub --reporter expanded test/project_element_collision_persistence_test.dart
```

```bash
cd packages/map_editor
flutter test --no-pub --reporter expanded test/project_element_collision_file_repository_roundtrip_test.dart
```

```bash
cd packages/map_gameplay
flutter test --no-pub --reporter expanded test/placed_elements_collision_test.dart
```

Commandes compact :

```bash
cd packages/map_editor
flutter test --no-pub --reporter compact test/project_element_collision_persistence_test.dart test/project_element_collision_file_repository_roundtrip_test.dart
```

```bash
cd packages/map_gameplay
flutter test --no-pub --reporter compact test/placed_elements_collision_test.dart
```

Commande de format :

```bash
dart format packages/map_editor/test/project_element_collision_persistence_test.dart packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart packages/map_gameplay/test/placed_elements_collision_test.dart
```

Sortie format :

```text
Formatted packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart
Formatted packages/map_gameplay/test/placed_elements_collision_test.dart
Formatted 3 files (2 changed) in 0.01 seconds.
```

## 10. Résultats des tests ciblés

### Expanded editor persistence

```text
00:00 +0: Project element collision persistence create use case persists final cells and padding through json
00:00 +1: Project element collision persistence update use case keeps edited final cells after roundtrip
00:00 +2: Project element collision persistence shape-authored profile survives json roundtrip without falling back to full padding base
00:00 +3: All tests passed!
```

### Expanded editor repository

```text
00:00 +0: FileProjectRepository collision roundtrip load currently preserves legacy cells before Collision-4 normalizer
FileProjectRepository: Loading project from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/collision_repo_roundtrip_current_pCGCTC/project.json
00:00 +1: FileProjectRepository collision roundtrip future normalizer contract migrates broken manual profile and save persists corrected cells
  Skip: Pending Collision-4/Collision-6: legacy collision profile normalizer is not implemented or wired into FileProjectRepository yet.
00:00 +1 ~1: All tests passed!
```

### Expanded gameplay

```text
00:00 +0: GameplayWorldState placed element collisions applyCollision=true blocks movement cell
00:00 +1: GameplayWorldState placed element collisions applyCollision=false does not block movement cell
00:00 +2: GameplayWorldState placed element collisions unknown element id does not block
00:00 +3: GameplayWorldState placed element collisions missing collision profile does not block
00:00 +4: GameplayWorldState placed element collisions pixelMask is used as source-of-truth when provided
00:00 +5: GameplayWorldState placed element collisions uses collisionMask before legacy cells when both exist
00:00 +6: GameplayWorldState placed element collisions falls back to legacy cells when collisionMask is absent
00:00 +7: GameplayWorldState placed element collisions one GridPos blocks one full world cell and nothing sub-tile exists
00:00 +8: GameplayWorldState placed element collisions currently over-blocks unnormalized legacy full cells
00:00 +9: GameplayWorldState placed element collisions future normalizer contract keeps legacy roof area passable before gameplay reads placed element cells
  Skip: Pending Collision-4/Collision-7: ElementCollisionProfile normalizer is not implemented before GameplayWorldState consumes legacy cells.
00:00 +9 ~1: GameplayWorldState placed element collisions future normalizer contract keeps placed element id isolation
  Skip: Pending Collision-4/Collision-7: normalized placed element profiles are not available to gameplay yet.
00:00 +9 ~2: GameplayWorldState placed element collisions roof-like coarse cell set blocks the exact whole world cells it names
00:00 +10 ~2: All tests passed!
```

### Compact editor

```text
00:01 +4 ~1: 1 skipped test.
00:01 +4 ~1: All other tests passed!
```

### Compact gameplay

```text
00:00 +10 ~2: 2 skipped tests.
00:00 +10 ~2: All other tests passed!
```

## 11. Vérification absence de modification production

Commande :

```bash
git diff --name-only
```

Sortie avant création du rapport :

```text
packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart
packages/map_editor/test/project_element_collision_persistence_test.dart
packages/map_gameplay/test/placed_elements_collision_test.dart
```

Conclusion :

- Aucun fichier `packages/*/lib/**` modifié.
- Aucun fichier `packages/map_core/lib/**` modifié.
- Aucun fichier `packages/map_gameplay/lib/**` modifié.
- Aucun fichier `packages/map_runtime/lib/**` modifié.
- Aucun fichier `packages/map_editor/lib/**` modifié.
- Aucun fichier generated avec diff final.

Note :

- Le rapport est un fichier non suivi et apparaît dans `git status`, pas dans `git diff --name-only`.

## 12. Ce que Collision-3 ne corrige volontairement pas

Collision-3 ne corrige pas :

- la normalisation legacy des profils collision ;
- le branchement de `FileProjectRepository.loadProject()` vers un normalizer ;
- le fallback legacy de `GameplayWorldState` ;
- la projection systématique `collisionMask -> cells` ;
- l'UI collision ;
- l'occlusion runtime ;
- les modèles persistants ;
- les codecs JSON.

Ces absences sont volontaires et conformes au contrat du lot.

## 13. Préparation de Collision-4

Collision-4 doit créer le normalizer pur dans `map_core`.

Contrats de tests préparés par Collision-3 :

- repository futur : un profil legacy avec `cells` pleines et `manualAddedCells` auteur doit être normalisé avant validation/sauvegarde ;
- gameplay futur : un profil legacy normalisé ne doit pas bloquer le toit ;
- gameplay futur : l'isolation par `elementId` doit rester vraie après normalisation ;
- gameplay actuel : `collisionMask` gagne contre `cells`;
- gameplay actuel : `cells` reste fallback si `collisionMask` est absent.

Changement de production attendu en Collision-4 :

```text
Créer packages/map_core/lib/src/operations/element_collision_profile_normalizer.dart
```

Changements de production non attendus en Collision-4 :

```text
GameplayWorldState
FileProjectRepository
map_runtime
UI collision
```

## 14. Risques / réserves

| Risque | État Collision-3 | Action future |
|---|---|---|
| Les skips cachent un vrai bug | Skips limités aux contrats dépendants du normalizer | Collision-4 doit les retirer ou les remplacer par tests verts après normalizer. |
| `.dart_tool` tracked bouge pendant tests | Mitigation réalisée, diff final nul sur `.dart_tool` | Continuer avec `flutter test --no-pub` dans ce worktree. |
| Le comportement actuel sur-bloquant paraît validé comme produit final | Test nommé `currently over-blocks...` | Collision-4 remplace ce comportement pour profils normalisés. |
| Le repository reste non normalisé | Test futur skip explicite | Collision-6 branche le normalizer. |

## 15. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart
 M packages/map_editor/test/project_element_collision_persistence_test.dart
 M packages/map_gameplay/test/placed_elements_collision_test.dart
?? reports/collision/collision_lot_3_red_tests_triage.md
```

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart
packages/map_editor/test/project_element_collision_persistence_test.dart
packages/map_gameplay/test/placed_elements_collision_test.dart
```

Inventaire final :

| Catégorie | Fichiers |
|---|---|
| Tests modifiés par Collision-3 | `packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart`, `packages/map_editor/test/project_element_collision_persistence_test.dart`, `packages/map_gameplay/test/placed_elements_collision_test.dart` |
| Rapport créé par Collision-3 | `reports/collision/collision_lot_3_red_tests_triage.md` |
| Fichiers de production modifiés | Aucun |
| Fichiers generated avec diff final | Aucun |
| Fichiers supprimés | Aucun |

## 16. Auto-review finale

| Question | Réponse |
|---|---|
| Ai-je modifié uniquement des tests autorisés et le rapport ? | Oui, à vérifier avec le status final. |
| Ai-je évité toute modification de production ? | Oui, `git diff --name-only` ne liste aucun fichier `lib`. |
| Ai-je corrigé le test qui ne compilait pas ? | Oui, `project_element_collision_persistence_test.dart` passe avec 3 tests verts. |
| Ai-je clarifié les tests legacy ? | Oui, comportement actuel vert et contrats futurs skip. |
| Ai-je conservé les contrats futurs sous forme explicite ? | Oui, 3 skips avec raisons Collision-4/Collision-6/Collision-7. |
| Ai-je évité de supprimer des assertions importantes ? | Oui, les corps de tests futurs sont conservés. |
| Ai-je listé tous les skips ? | Oui, section 8. |
| Ai-je relancé les tests ciblés ? | Oui, expanded et compact ciblés. |
| Ai-je préparé Collision-4 sans l’implémenter ? | Oui, aucune production modifiée. |
| Ai-je conservé git status initial et final ? | Oui, sections 2 et 15. |
