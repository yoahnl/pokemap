# Rapport ultra complet — correction flux réel `authoring -> runtime -> save -> reload` (Emma)

## 1) Résumé exécutif

Le bug réel venait de **deux incohérences de données** dans le pipeline produit :

1. Côté authoring, des lignes `worldChanges` pouvaient encore être persistées avec `mapId` non vide et `entityId` vide.
2. Côté progression, une step pouvait rester en `completion.mode = manual` alors qu’elle était en pratique pilotée par une cutscene principale, ce qui empêchait la complétion runtime de cette step dans `completedStepIds`.

Cette passe corrige le pipeline à ses points critiques :

- validation défensive de persistance authoring,
- normalisation completion cohérente avec cutscene principale,
- logs runtime/save/reload explicites,
- tests de non-régression et d’intégration data flow.

---

## 2) Diagnostic réel (et pourquoi la passe précédente était insuffisante)

### 2.1 Ce qui cassait encore

- `project.json` pouvait garder :
  - `step_2.completion.mode = manual`
  - `worldChanges[].entityId = ""`
- Runtime : seule `step_2_1` était complétée dans les logs, pas `step_2`.

### 2.2 Pourquoi la correction précédente ne suffisait pas

La passe précédente corrigeait surtout l’illusion de sélection UI (dropdown), mais ne fermait pas assez le système :

- pas de garde-fou global de persistance bloquant un worldChange invalide,
- pas d’auto-alignement systématique `manual -> whenCutsceneEnds` quand la structure de step indiquait déjà une cutscene principale,
- logs runtime/save pas assez explicites pour suivre la chaîne complète jusqu’au fichier sauvegardé.

---

## 3) Corrections implémentées

## A. Authoring Step Studio

### A1. Validation défensive avant persistance

Fichier : `packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart`

Ajout de :

- `validateStepStudioDocumentForPersistence(...)`

Règle métier :

- si `worldChange.mapId` est non vide, `entityId` doit être non vide.

Cette validation est appelée dans la sauvegarde UI Step Studio.

### A2. Blocage de save si données invalides

Fichier : `packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart`

Dans `_saveDraft()` :

- appel à `validateStepStudioDocumentForPersistence(draft)`,
- si erreur :
  - save annulé,
  - log `[step_studio_trace] action=save_blocked_validation ...`,
  - message explicite côté UI.

=> plus de persistance silencieuse d’un `entityId:""` avec `mapId` rempli.

### A3. Normalisation completion cohérente

Fichier : `packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart`

Dans `_normalizeDocument(...)` :

- si une step est `manual` **sans champs completion renseignés**,
- et qu’elle a une cutscene liée (priorité rôle `main`),
- completion auto-fixée en :
  - `mode = whenCutsceneEnds`
  - `cutsceneId = <cutscene main ou première disponible>`

Log ajouté :

- `[step_studio_trace] action=normalize_completion_autofix ...`

=> `step_2` ne reste plus en `manual` par incohérence d’authoring dans ce cas.

## B. Runtime / save / reload

### B1. Logs explicites de complétion step

Fichier : `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

Ajouts :

- `runtime_mark_step_completed_candidate` (avant mutation)
- `runtime_completed_steps_updated` (après mutation)
- `runtime_save_requested` (au moment du save, avec `completedStepIds` et `completedCutsceneIds`)

### B2. Logs explicites de présence PNJ appliquée

Même fichier (`playable_map_game.dart`) :

- `npc_presence_applied map=... entity=... present=...`
- `npc_mount_skipped ... reason=presence_predicate_false`
- `npc_mount_added ...`

=> lisibilité directe de la décision présence au moment où elle est propagée au rendu.

---

## 4) Tests ajoutés / mis à jour

## A. Authoring

Fichier : `packages/map_editor/test/step_studio_authoring_test.dart`

Ajouts :

1. `normalize auto-fix: completion manual + cutscene principale => whenCutsceneEnds`
2. `validation persistence blocks worldChange mapId with empty entityId`

Tests existants conservés et passants :

- persistance `mapId = Bourivka center`, `step_2`, `entityId = emma`,
- réouverture/reparse metadata avec conservation d’`emma`.

## B. Runtime completion

Fichier : `packages/map_runtime/test/step_studio_completion_runtime_test.dart`

Ajout :

- mapping non-régression réaliste de deux cutscenes :
  - `premier_pas -> step_2_1`
  - `premier_dialogue_avec_le_professeur_emma -> step_2`

## C. Intégration data flow save/reload

Fichier : `packages/map_runtime/test/step_studio_save_reload_visibility_integration_test.dart`

Couverture :

- fin cutscene -> `step_2` complétée,
- save/reload (`toJson/fromJson` GameState),
- réévaluation présence Emma sur `Bourivka center` => absente.

---

## 5) Commandes de test lancées

- `flutter test packages/map_editor/test/step_studio_authoring_test.dart packages/map_editor/test/step_studio_workspace_regression_test.dart packages/map_editor/test/inspector_embedded_dropdown_unset_test.dart`
- `flutter test packages/map_runtime/test/step_studio_completion_runtime_test.dart packages/map_runtime/test/step_studio_save_reload_visibility_integration_test.dart packages/map_runtime/test/npc_runtime_presence_test.dart`

Résultat : toutes vertes.

---

## 6) Fichiers modifiés

- `packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart`
- `packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart`
- `packages/map_editor/test/step_studio_authoring_test.dart`
- `packages/map_editor/test/step_studio_workspace_regression_test.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/step_studio_completion_runtime_test.dart`

---

## 7) Relocation Emma vers le lab

État honnête :

- Le pipeline corrigé ici garantit la **disparition persistante sur la map source** via règles de présence + progression save/reload.
- L’apparition persistante d’Emma dans `lab` nécessite un mécanisme explicite de présence côté cible (autre règle, autre entité cible, ou système de relocation persistant).

Donc :

- disparition à `Bourivka center` : couverte,
- apparition à `lab` : dépend du modèle authoré côté map/lab (non hardcodé ici).

---

## 8) Checklist manuelle terrain

1. Ouvrir Step Studio sur `step_2`.
2. Vérifier worldChange : `mapId=Bourivka center`, `entityId=emma` (sinon save bloqué).
3. Sauver Step Studio.
4. Vérifier dans `project.json` :
  - `completion.mode` cohérent (`whenCutsceneEnds` si cutscene main),
  - `worldChanges[].entityId = "emma"`.
5. Jouer la cutscene `premier_dialogue_avec_le_professeur_emma`.
6. Vérifier logs runtime :
  - `runtime_mark_step_completed_candidate ... step=step_2`
  - `runtime_completed_steps_updated ... after=[..., step_2]`
7. Sauver puis reloader.
8. Vérifier logs save/reload :
  - `runtime_save_requested ... completedStepIds=[..., step_2]`
  - `save_repo_write_* ... completedStepIds=[..., step_2]`
9. Retourner à `Bourivka center` et vérifier absence d’Emma.

---

## 9) Ce qui est désormais garanti

- Un worldChange invalide (map sans entité) ne peut plus être sauvegardé silencieusement.
- Une step laissée en `manual` mais visiblement pilotée par cutscene est auto-normalisée de manière persistable.
- Le chemin runtime de complétion step est traçable et vérifiable.
- Le chemin save/reload de progression est traçable et vérifiable.
- Le masquage d’Emma sur la map source devient cohérent avec la progression persistée.

