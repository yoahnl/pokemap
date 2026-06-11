# NS-SCENES-V1-107 — Cinematic Manual Path Core Model V0

## 1. Résumé exécutif

Le lot **NS-SCENES-V1-107** implémente le modèle de données, les opérations d'authoring et les diagnostics associés aux chemins manuels cinématiques (Manual Paths) au sein du package `map_core`. Conformément aux décisions du contrat V1-106, cette implémentation reste strictement limitée à la partie **authoring-only** (modélisation de points de passage ordonnés référençant des repères spatiaux, liaison logique de propriété par rapport à un bloc `actorMove` et diagnostics de cohérence), sans aucune introduction de mécanique d'interpolation, de tracé visuel ou d'exécution au runtime.

Tous les tests ciblés et l'ensemble de la suite de tests de `map_core` (2484 tests au total) passent avec succès. L'analyse statique Dart ne rapporte aucune erreur ou avertissement.

---

## 2. Gate 0

*   **Repository :** `pokemonProject`
*   **Package cible :** `packages/map_core`
*   **Auteur :** Antigravity AI
*   **Objectif :** Intégrer le modèle `CinematicManualPath`, les opérations d'authoring pures et les validations diagnostics associées dans `map_core`.
*   **Scope strict :** Pas d'UI, pas de Flame, pas de runtime, pas d'interpolation, pas de modifications Xcode.

---

## 3. Fichiers lus

Les fichiers suivants ont été consultés pour asseoir l'implémentation :
- `AGENTS.md` (Règles générales et conventions)
- `agent_rules.md` (Spécificités et vérité de validation)
- `codex_rule.md` (Structure des rapports et processus d'audit/critique)
- `packages/map_core/lib/src/models/cinematic_asset.dart` (Structures modèles)
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart` (Opérations pures)
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart` (Moteur de diagnostics)
- `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart` (Pistes d'édition)
- `reports/narrativeStudio/scenes/ns_scenes_v1_106_cinematic_manual_path_authoring_prep_contract.md` (Cadrage amont)

*Note : Le fichier `codex_rules.md` (au pluriel) n'existe pas dans le dépôt.*

---

## 4. Audit ownership actorMove step id

L'identifiant des blocs de la timeline (`CinematicTimelineStep.id`) a été audité et s'avère persistant et stable lors du roundtrip JSON et des opérations d'édition/durée existantes. Il est utilisé comme clé unique de référence pour relier les chemins manuels à leur bloc `actorMove` propriétaire.

---

## 5. Décision anti-double-source

Pour éviter toute double source de vérité :
- Aucun champ `manualPathId` n'a été rajouté sur la classe `CinematicTimelineStep` ou le bloc `actorMove`.
- La liaison est unidirectionnelle : l'objet `CinematicManualPath` possède le champ `ownerActorMoveStepId`.
- Les opérations d'authoring résolvent la liaison en recherchant dans le context `manualPaths` les instances où `ownerActorMoveStepId == step.id`.
- Des diagnostics ont été ajoutés pour remonter tout état ambigu (plusieurs chemins pour un même step) ou orphelin (chemin rattaché à un step inexistant).

---

## 6. Changements modèle

Dans [cinematic_asset.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/cinematic_asset.dart) :
- Ajout du mode `manual` à l'énumération `CinematicTimelineActorPathMode`.
- Création de la classe immuable `CinematicManualPath` possédant :
  - `id`: `String` (identifiant interne unique)
  - `label`: `String` (libellé utilisateur)
  - `description`: `String?` (optionnel)
  - `ownerActorMoveStepId`: `String` (liaison au step)
  - `waypointStagePointIds`: `List<String>` (liste ordonnée des repères spatiaux de passage)
- Intégration dans `CinematicStageContext` du champ `manualPaths: List<CinematicManualPath>`.

---

## 7. Changements JSON/backward compatibility

- La méthode `fromJson` de `CinematicStageContext` résout `manualPaths` via un helper de désérialisation rétrocompatible. Si le champ est absent du JSON (anciennes cinématiques), il s'initialise à une liste vide.
- `toJson` exporte proprement la structure des chemins sans valeur nulle.
- Les waypoints intermédiaires (`waypointStagePointIds`) autorisent les répétitions légitimes de repères (boucles volontaires de déplacement d'un acteur) sans les dédoubler via des structures de type `Set`, tout en nettoyant les espaces.

---

## 8. Changements pathMode

- L'énumération `CinematicTimelineActorPathMode` intègre désormais `manual` en plus de `direct`.
- Les read models et l'inspecteur reconnaissent `manual` sans planter la timeline.
- Par défaut, les nouveaux blocs `actorMove` continuent de s'initialiser en mode `direct`.

---

## 9. Opérations pures ajoutées

Dans [cinematic_authoring_operations.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart) :
- `addCinematicManualPathForActorMove` : associe un nouveau chemin manuel à un step `actorMove`.
- `updateCinematicManualPath` : met à jour le label, la description et les waypoints d'un chemin.
- `removeCinematicManualPath` : retire un chemin et réinitialise le step associé à `direct`.
- `addCinematicManualPathWaypoint` : ajoute un point de passage à la fin d'un trajet.
- `removeCinematicManualPathWaypointAt` : retire un point de passage à un index précis.
- `reorderCinematicManualPathWaypoint` : réordonne la liste ordonnée de waypoints.
- `setActorMovePathMode` : permet de basculer la métadonnée `actor.pathMode` entre `direct` et `manual`.
- `clearActorMoveManualPath` : supprime le chemin associé et réinitialise à `direct`.

---

## 10. Diagnostics ajoutés

Dans [cinematic_diagnostics.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart), 12 nouveaux codes ont été introduits dans `CinematicDiagnosticCode` :
- `manualPathEmpty` (warning ou error si utilisé par un step en mode manual)
- `manualPathStagePointMissing` (error)
- `manualPathStagePointDuplicate` (warning)
- `manualPathWithoutStageMap` (warning)
- `manualPathStagePointOutOfMap` (error)
- `actorMoveManualPathMissing` (error)
- `actorMoveManualPathAmbiguous` (error)
- `actorMoveManualPathUnused` (warning)
- `manualPathOrphaned` (warning)
- `manualPathDuplicateId` (error)
- `manualPathEmptyId` (error)
- `manualPathEmptyLabel` (warning)

Les messages utilisateur respectent le vocabulaire no-code et n'exposent pas d'identifiants techniques.

---

## 11. Read models impactés ou non

Dans [cinematic_timeline_lane_read_model.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart) :
- La fonction `_pathModeLabel` a été étendue pour traiter `manual` en renvoyant `'Manuel'`.
- Aucun calcul géométrique d'interpolation ni de rendu visuel de chemin n'a été inséré.

---

## 12. Tests ajoutés/modifiés

- **Assets / JSON :** Ajout de tests de désérialisation rétrocompatible, roundtrip JSON des chemins et immutabilité de la liste des waypoints dans `test/cinematic_asset_test.dart`.
- **Opérations pures :** Implémentation complète de tests pour toutes les opérations pures d'authoring (création, modification, reorder, suppression, bascule de mode) dans `test/cinematic_authoring_operations_test.dart`.
- **Diagnostics :** Couverture unitaire totale pour les 12 codes de diagnostics créés (cas nominaux, warning et erreurs bloquantes) dans `test/cinematic_diagnostics_test.dart`.

---

## 13. Tests exécutés

Les commandes de tests suivantes ont toutes été exécutées avec succès :
```bash
dart test --reporter=compact test/cinematic_asset_test.dart
# +21 tests passed

dart test --reporter=compact test/cinematic_authoring_operations_test.dart
# +67 tests passed

dart test --reporter=compact test/cinematic_diagnostics_test.dart
# +53 tests passed

dart test --reporter=compact
# +2484 tests passed (Totalité du package map_core)
```

---

## 14. Analyse statique

La commande `dart analyze` s'est exécutée sans rapporter aucun problème sur le package `map_core`.

---

## 15. Checks anti-scope

L'exécution des vérifications anti-scope confirme qu'aucune modification indésirable n'a été effectuée :
- `git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host` : **Sortie vide**.
- `git diff --name-only -- examples/playable_runtime_host/macos/Runner.xcodeproj/project.pbxproj packages/map_editor/macos/Runner.xcodeproj/project.pbxproj` : **Sortie vide**.
- Aucun fichier de `map_editor` n'a été altéré.

---

## 16. Roadmaps mises à jour

Les fichiers de roadmaps suivants ont été mis à jour pour déclarer V1-107 comme `DONE` et recommander V1-108 en suite immédiate :
- [road_map_scenes.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/road_map_scenes.md)
- [road_map_scene_builder_authoring.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md)

---

## 17. Git status final

```text
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
packages/map_core/lib/src/models/cinematic_asset.dart
packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
packages/map_core/test/cinematic_asset_test.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_diagnostics_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

---

## 18. Risques restants

- **Risque d'orphelins lors de suppressions globales :** Si un utilisateur supprime un bloc `actorMove` complet via le bouton de suppression globale de l'éditeur sans passer par `clearActorMoveManualPath`, le chemin manuel risque de devenir orphelin. 
  *Atténuation :* Le diagnostic `manualPathOrphaned` remontera cette situation sous forme de warning pour permettre un nettoyage facile. De plus, lors de l'implémentation de la suppression de blocs dans `map_editor` au lot V1-108, il faudra veiller à appeler la suppression des chemins associés.

---

## 19. Auto-critique

- **Solidité :** Le découplage entre les repères physiques existants et le chemin ordonné est parfait. La ré-utilisation de l'identifiant stable de step assure une liaison forte.
- **Diagnostics :** Les diagnostics couvrent tous les cas tordus (repères en dehors de la carte, doublons de repères intermédiaires, etc.).
- **Absence de `manualPathId` dans `actorMove` :** C'est une excellente décision d'architecture, car elle évite d'avoir deux champs qui pointent l'un vers l'autre dans le JSON, supprimant tout risque de désynchronisation structurelle.

---

## 20. Verdict final

Le lot **NS-SCENES-V1-107** est **DONE**.
Le modèle core authoring-only est prêt et validé par 100% de tests verts.

---

## 21. Prochain lot recommandé

```text
NS-SCENES-V1-108 — Cinematic Manual Path Drawing UI V0
```
Objectif : Implémenter l'interface de dessin interactive de ces chemins et l'édition no-code dans l'inspecteur d'instructions cinématiques.
