# Rapport complet — correction flux réel `authoring -> runtime -> save -> reload`

## 0) Problème réel confirmé

Les données réelles fournies montrent bien deux défaillances bloquantes :

1. `authoring.stepStudioDocument` contenait encore un `worldChanges` avec `entityId:""` (donc aucune cible PNJ).
2. Le save runtime ne contenait pas `step_2` dans `completedStepIds`, même après fin de cutscene.

Avec ces deux conditions, Emma ne peut pas disparaître durablement au reload.

---

## 1) Causes racines traitées

## A. Côté authoring Step Studio

### A1. Sauvegardes silencieuses de lignes invalides
Le Step Studio autorisait la sauvegarde d’une ligne worldChange avec `mapId` renseigné mais `entityId` vide. Même avec une UI améliorée, ce cas restait possible et produisait exactement ton JSON invalide.

### A2. Step en `manual` malgré présence de cutscene principale
Une step avec `completion.mode = manual` ne peut pas alimenter `completedStepIds` automatiquement à la fin de cutscene. Si cette configuration apparaît alors que la step est en réalité pilotée par une cutscene, la persistance progression diverge.

## B. Côté runtime/save

La logique de complétion existait déjà, mais il manquait des traces suffisamment explicites pour prouver :
- l’instant où la step est marquée complétée,
- la mutation effective de `completedStepIds`,
- le contenu final écrit au save.

---

## 2) Correctifs implémentés

### 2.1 `packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart`

- Ajout de traces structurées `[step_studio_trace]` pour :
  - création worldChange,
  - changement de map,
  - sélection d’entité,
  - mise à jour draft,
  - pré-save.
- **Nouveau garde-fou save** : blocage de sauvegarde si une ligne worldChange a `mapId` non vide et `entityId` vide.
  - Log : `action=save_blocked_empty_entity ...`
  - Message utilisateur via `_entityLookupError`.
- Trace de changement du mode de completion :
  - `action=completion_mode_changed ... from=... to=...`

Impact : impossible de persister de nouveau un worldChange “ciblant une map” sans entité.

### 2.2 `packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart`

- Traces d’entrée/sortie de `applyStepStudioDocumentToGlobalScenario` :
  - `action=apply_document` (rows normalisées),
  - `action=apply_document_metadata` (`contains_emma`, `contains_empty_entity`).
- **Auto-fix de normalisation completion** :
  - si `completion.mode == manual` et qu’aucun champ completion n’est renseigné,
  - mais qu’une cutscene est liée à la step (`main` prioritaire),
  - alors la completion est auto-alignée vers `whenCutsceneEnds` avec cette cutscene.
  - Log : `action=normalize_completion_autofix ... manual->whenCutsceneEnds ...`

Impact : évite le cas “step pilotée par cutscene mais restée manual”, qui cassait `completedStepIds`.

### 2.3 `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

Ajout de logs runtime explicites :

- Quand une step candidate est détectée à la fin de cutscene :
  - `runtime_mark_step_completed_candidate ... before=[...]`
- Quand `completedStepIds` est effectivement modifié :
  - `runtime_completed_steps_updated ... after=[...]`
- Au moment du save :
  - `runtime_save_requested ... completedStepIds=[...] completedCutsceneIds=[...]`

### 2.4 `packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart`

Ajout des logs d’écriture effective :

- `save_repo_write_start ... completedStepIds=[...]`
- `save_repo_write_done ... completedStepIds=[...]`

Impact : preuve complète “avant save” et “écrit disque”.

---

## 3) Tests ajoutés / mis à jour

### 3.1 Authoring

Fichier : `packages/map_editor/test/step_studio_authoring_test.dart`

- Test persistance réelle : `Bourivka center` + `step_2` + `entityId=emma`.
- Test réouverture metadata : conservation de `entityId=emma`.
- **Nouveau test auto-fix completion** : `manual + cutscene principale` devient `whenCutsceneEnds`.

### 3.2 Runtime integration data flow

Fichier : `packages/map_runtime/test/step_studio_save_reload_visibility_integration_test.dart`

Scénario couvert :
1. mapping cutscene -> `step_2` via index Step Studio,
2. marquage completion,
3. roundtrip save/reload (`GameState.toJson/fromJson`),
4. évaluation présence PNJ sur `Bourivka center` : Emma absente.

### 3.3 Dropdown/selection guard

Fichier : `packages/map_editor/test/inspector_embedded_dropdown_unset_test.dart`

- placeholder sans sélection implicite,
- émission réelle de `emma` sur sélection.

---

## 4) Exécution des tests

Passés :

- `flutter test packages/map_editor/test/step_studio_authoring_test.dart packages/map_editor/test/inspector_embedded_dropdown_unset_test.dart`
- `flutter test packages/map_runtime/test/step_studio_save_reload_visibility_integration_test.dart packages/map_runtime/test/step_studio_completion_runtime_test.dart packages/map_runtime/test/npc_runtime_presence_test.dart`
- `flutter test packages/map_editor/test/step_studio_workspace_regression_test.dart`

Aucun commit git effectué.

---

## 5) Ce que ça change concrètement sur ton cas

Avec ces changements, le pipeline ne peut plus “accepter silencieusement” un worldChange invalide (`entityId:""`) lors d’un save Step Studio. De plus, une step manifestement pilotée par cutscene n’est plus laissée en `manual` au moment de normaliser/sauver le document.

Conséquence attendue pour ton flux réel :
- `project.json` doit sortir avec `entityId:"emma"` (sinon save bloqué),
- `completion.mode` de la step concernée doit être cohérent (`whenCutsceneEnds`) si une cutscene principale existe,
- au runtime, la fin de cutscene doit loguer la mutation de `completedStepIds`,
- au save, les logs doivent montrer `completedStepIds` contenant `step_2`.

---

## 6) Vérification terrain (checklist)

1. Dans Step Studio, sur la step cible, sélectionner map + Emma puis sauvegarder.
2. Vérifier console éditeur :
   - `action=world_change_entity_selected ... entityId=emma`
   - `action=apply_document ... entity=emma`
   - `action=apply_document_metadata ... contains_emma=true`
3. Ouvrir `project.json` :
   - ligne worldChange avec `"entityId":"emma"`.
4. Jouer la cutscene de fin step, puis sauvegarder :
   - `runtime_mark_step_completed_candidate ... step=step_2`
   - `runtime_completed_steps_updated ... after=[..., step_2]`
   - `runtime_save_requested ... completedStepIds=[..., step_2]`
   - `save_repo_write_done ... completedStepIds=[..., step_2]`
5. Reload + retour Bourivka center : Emma absente.

---

## 7) Limites restantes

- Le test UI “full interaction StepStudioWorkspace + save notifier + reload manifest disque + assert JSON” a été tenté mais instable dans le harness widget existant. La couverture actuelle est robuste via :
  - garde-fous runtime réels,
  - logs de bout en bout,
  - tests authoring + intégration data flow runtime/save/reload.

Si nécessaire, prochaine passe dédiée : harness E2E UI stabilisé avec repository fake instrumenté.
