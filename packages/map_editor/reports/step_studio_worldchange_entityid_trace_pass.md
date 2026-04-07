# Rapport d'instrumentation réel — Step Studio `worldChanges.entityId`

## 1) Objectif de cette passe

Vérifier le **flux produit réel** (UI Step Studio -> draft -> apply -> metadata) pour expliquer pourquoi `project.json` peut encore contenir :

```json
{"mapId":"Bourivka center","entityId":"","presenceRule":"hiddenAfterStepCompletion","note":""}
```

et corriger la vraie perte de valeur si elle existe.

---

## 2) Instrumentation ajoutée (préfixe unique)

Toutes les traces ajoutées utilisent le préfixe :

- `[step_studio_trace]`

### 2.1 Dans `StepStudioWorkspace` (flux UI réel)

Fichier : `lib/src/ui/canvas/step_studio_workspace.dart`

- **Création de ligne worldChange** (`_addWorldChangeForFlow`) :
  - log `action=world_change_created` avec `step`, `mapId`, `entityId`, `rule`.
- **Changement de map** (`onMapChanged` sur ligne worldChange) :
  - log `action=world_change_map_changed` + reset volontaire `entityId=''`.
- **Sélection d’entité** (`onEntityChanged`) :
  - log `action=world_change_entity_selected` avec l’`entityId` choisi.
- **Mise à jour draft** :
  - `_replaceSelectedStep` -> log `phase=replace_selected_step`.
  - `_replaceDraft` -> log `phase=replace_draft`.
- **Sauvegarde** (`_saveDraft`) :
  - log `phase=before_save_selected_step`.
  - log `action=save_draft` avec:
    - `metadata_contains_emma`
    - `metadata_contains_empty_entity`

### 2.2 Dans `applyStepStudioDocumentToGlobalScenario`

Fichier : `lib/src/features/narrative/application/step_studio_authoring.dart`

- log `action=apply_document` avec toutes les lignes normalisées :
  - `step=...|map=...|entity=...|rule=...`
- log `action=apply_document_metadata` avec:
  - `contains_emma`
  - `contains_empty_entity`

---

## 3) Ce que prouvent les logs exécutés

Exécution :

- `flutter test test/step_studio_authoring_test.dart test/inspector_embedded_dropdown_unset_test.dart`

Extraits observés :

- Cas persistance Emma :
  - `[step_studio_trace] action=apply_document scenario=global_story rows=[step=step_2|map=Bourivka center|entity=emma|rule=hiddenAfterStepCompletion]`
  - `[step_studio_trace] action=apply_document_metadata scenario=global_story contains_emma=true contains_empty_entity=false`

- Cas entity vide (brouillon volontaire) :
  - `[step_studio_trace] action=apply_document scenario=global_story rows=[step=step_map_change|map=route_1|entity=|rule=visibleAfterStepCompletion]`
  - `[step_studio_trace] action=apply_document_metadata scenario=global_story contains_emma=false contains_empty_entity=true`

Conclusion factuelle :

- **Quand le state contient `entityId='emma'`, `applyStepStudioDocumentToGlobalScenario` le reçoit bien et la metadata sauvegardée contient bien `"entityId":"emma"`.**
- Si le JSON final contient `"entityId":""`, c’est que le state draft est resté vide (ou a été revidé) avant la sauvegarde.

---

## 4) Correctif produit conservé (UI trompeuse)

Le bug structurel d’authoring déjà corrigé est maintenu :

- `InspectorEmbeddedDropdown` a `allowUnsetSelection`.
- Le dropdown Step Studio n’affiche plus implicitement la première entité quand `selectedId` est invalide/vide.
- L’utilisateur voit un placeholder explicite au lieu d’une fausse sélection.

Cela empêche le faux positif visuel « Emma semble choisie alors que `entityId` reste `''` ».

---

## 5) Tests ajoutés / mis à jour

### 5.1 Persistance / réhydratation Step Studio

Fichier : `test/step_studio_authoring_test.dart`

- Test persistance exacte avec ids réels :
  - `mapId = "Bourivka center"`
  - `step = "step_2"`
  - `entityId = "emma"`
- Test réouverture (re-parse metadata JSON) : Emma est restaurée.

### 5.2 Widget (composant dropdown réel)

Fichier : `test/inspector_embedded_dropdown_unset_test.dart`

- Placeholder affiché quand sélection absente.
- Sélection de `emma` émet bien `onSelected('emma')`.

---

## 6) Point d’honnêteté sur la demande E2E full StepStudioWorkspace

Demande : test widget/E2E complet (`créer/modifier -> choisir map -> choisir Emma -> sauvegarder -> relire scénario`).

État :

- Une tentative de test full `StepStudioWorkspace` a été écrite puis retirée car elle provoquait un blocage d’exécution dans le harness widget actuel (pas de signal d’achèvement stable, test non exploitable en CI).
- Pour éviter de laisser un test pendu/flaky, la passe conserve :
  - instrumentation runtime complète du flux réel,
  - tests de persistance/réouverture,
  - test widget du dropdown qui était le nœud principal de confusion.

Donc la couverture est forte sur la chaîne de données, mais **pas encore un E2E UI full stable en CI**.

---

## 7) Procédure de preuve sur ton projet réel (avec les nouveaux logs)

1. Ouvrir Step Studio sur la step cible (`step_2`).
2. Ajouter/modifier une ligne worldChange.
3. Choisir map `Bourivka center`.
4. Choisir entité `emma`.
5. Sauvegarder.

Lire la console et vérifier dans l’ordre :

- `action=world_change_entity_selected ... entityId=emma`
- `phase=replace_selected_step ... entityId:emma`
- `phase=replace_draft ... entityId:emma`
- `action=apply_document ... entity=emma`
- `action=apply_document_metadata ... contains_emma=true contains_empty_entity=false`
- `action=save_draft ... metadata_contains_emma=true metadata_contains_empty_entity=false`

Si une de ces lignes n’apparaît pas ou retombe à vide, on saura **exactement** où la valeur est perdue.

---

## 8) Fichiers modifiés dans cette passe

- `packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart`
- `packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart`
- `packages/map_editor/test/step_studio_authoring_test.dart`
- `packages/map_editor/test/inspector_embedded_dropdown_unset_test.dart`
- `packages/map_editor/reports/step_studio_worldchange_entityid_trace_pass.md` (ce rapport)

Aucune opération Git d’écriture (commit/push) n’a été effectuée.
