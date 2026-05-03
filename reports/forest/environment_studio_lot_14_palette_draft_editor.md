# Environment Studio Lot 14 — Palette Draft Editor V0

## 1. Résumé exécutif

Édition locale de la palette du brouillon dans [EnvironmentPresetDraftForm] : ajout d’items (`EnvironmentPaletteItemDraft` vide + poids 1), cartes [EnvironmentPaletteItemDraftEditor] (elementId, poids avec garde parse, collision en [CupertinoSlidingSegmentedControl], tags CSV, action « Retirer »), validation inchangée via [validateEnvironmentPresetDraft]. Aucune mutation [ProjectManifest], aucun upsert ni [buildEnvironmentPresetFromDraft] dans l’UI.

## 2. Périmètre du lot

- `packages/map_editor` uniquement (widgets + tests + rapport).
- Pas de `map_core`, pas de persistance, pas de `build_runner`.

## 3. Audit initial du formulaire brouillon

Fichiers relus : `environment_studio_panel.dart`, `environment_preset_draft.dart`, `environment_preset_draft_form.dart`, `environment_preset_draft_validation_view.dart`, `environment_preset_draft_presentation.dart`, `environment_palette_item_view.dart`, tests Environment Studio existants, `cupertino_editor_widgets.dart`.

Constats : `_emit` ne remontait que les champs texte et reprenait `widget.draft.palette` tel quel ; la validation palette était déjà complète côté draft ; les libellés FR collision existaient en read-only dans `environment_palette_item_view.dart`.

**Pattern retenu** : `_emit(palette:)` optionnel ; liste clonée à chaque mutation ; un `StatefulWidget` par slot avec `ValueKey('palette-draft-slot-$i')` + `didUpdateWidget` pour resynchroniser les contrôleurs quand l’item du slot change après réindexation.

## 4. Décisions UI / édition palette locale

- Titre « Palette du brouillon » + note de non-persistance alignée cahier.
- Bouton « Ajouter un item de palette » ; item initial `elementId: ''`, `weight: 1`.
- Tags : `split(',')` + `trim` + `toSet()` (tags vides conservés pour `emptyPaletteTag`).
- Poids : si parse `int` impossible, pas d’`onChanged` (brouillon inchangé).
- Collision : trois segments FR comme le browser read-only.

## 5. Éditeur d’item palette ajouté

Fichier `environment_palette_item_draft_editor.dart` : contrôleurs `dispose` en sortie ; `didUpdateWidget` si `item` change.

## 6. Validation palette affichée

Réutilisation de [EnvironmentPresetDraftValidationView] sans refactor ; issues `emptyPalette`, `emptyPaletteElementId`, `duplicatePaletteElementId`, `missingPaletteElement`, `invalidPaletteWeight`, `emptyPaletteTag` couvertes par tests widget.

## 7. Non-persistance garantie

- Aucun appel UI à `buildEnvironmentPresetFromDraft`, `upsertProjectEnvironmentPreset`, `replaceProjectEnvironmentPresets`, `clearProjectEnvironmentPresets`.
- Tests : liste `environmentPresets` inchangée après édition palette + annulation.

## 8. Pourquoi aucune sauvegarde / génération dans ce lot

Lot 16 prévu pour l’upsert manifest ; ce lot ne fait qu’enrichir le brouillon en mémoire dans le `State` du panel.

## 9. Fichiers modifiés

- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart` (M)
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart` (nouveau)
- `packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart` (M — attentes section palette)
- `packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart` (nouveau)
- `reports/forest/environment_studio_lot_14_palette_draft_editor.md` (ce fichier)

`environment_preset_draft_validation_view.dart` : non modifié (affichage suffisant).

## 10. Tests ajoutés ou modifiés

- `environment_preset_palette_draft_editor_test.dart` : 9 scénarios (ajout, element connu/absent, poids, collision, tags, retirer, doublon, non-persistance).
- `environment_studio_preset_creation_form_test.dart` : clés / textes section palette V14.

## 11. Commandes exécutées

```bash
cd packages/map_editor
dart format lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart \
  lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart \
  test/environment_studio/environment_studio_preset_creation_form_test.dart \
  test/environment_studio/environment_preset_palette_draft_editor_test.dart

flutter analyze lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart \
  lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart \
  test/environment_studio/environment_studio_preset_creation_form_test.dart \
  test/environment_studio/environment_preset_palette_draft_editor_test.dart

flutter test test/environment_studio/environment_preset_palette_draft_editor_test.dart --reporter expanded
flutter test test/environment_studio/environment_studio_preset_creation_form_test.dart \
  test/environment_studio/environment_preset_draft_test.dart --reporter expanded
flutter test test/environment_studio --reporter expanded
flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart --reporter expanded
flutter test 2>&1 | tail -n 8
```

## 12. Résultats des commandes

### dart format

```
Formatted 4 files (0 changed) in 0.01 seconds.

```

### flutter analyze

```
Analyzing 4 items...                                            
No issues found! (ran in 1.0s)

```

### flutter test — palette draft (isolé)

```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart
00:00 +0: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:00 +1: EnvironmentStudioPanel — palette brouillon (Lot 14) elementId connu : plus d’emptyPaletteElementId ni missingPaletteElement
00:00 +2: EnvironmentStudioPanel — palette brouillon (Lot 14) elementId absent : Élément introuvable
00:01 +3: EnvironmentStudioPanel — palette brouillon (Lot 14) poids 3 valide, poids 0 invalide, texte non numérique inchangé
00:01 +4: EnvironmentStudioPanel — palette brouillon (Lot 14) collision : bascule Collision forcée puis Collision désactivée
00:01 +5: EnvironmentStudioPanel — palette brouillon (Lot 14) tags : tree, canopy OK ; tree, , canopy → Tag vide
00:01 +6: EnvironmentStudioPanel — palette brouillon (Lot 14) Retirer : palette vide, emptyPalette revient
00:01 +7: EnvironmentStudioPanel — palette brouillon (Lot 14) deux items même elementId : Élément dupliqué
00:01 +8: EnvironmentStudioPanel — palette brouillon (Lot 14) édition palette + retour browser : manifest.environmentPresets inchangé
00:01 +9: All tests passed!

```

### flutter test — creation_form + environment_preset_draft_test

```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: environmentPresetDraftIssueKindLabel libellés FR attendus (extrait)
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentGenerationParamsDraft standard s’aligne sur EnvironmentGenerationParams.standard()
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +24: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +25: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +26: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +27: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +28: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +29: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +30: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +31: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +32: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +33: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +34: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +35: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +36: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +37: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +38: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +39: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +40: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +41: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +42: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +43: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +44: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +45: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon champs initiaux vides et params standard
00:00 +46: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon validation initiale : id, nom, template, palette
00:00 +47: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon saisie met à jour le draft et la validation
00:00 +48: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon sortOrder : texte invalide conserve la valeur draft
00:01 +49: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon Réinitialiser brouillon remet les champs vides
00:01 +50: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon Retour au browser restaure la liste sans modifier le manifest
00:01 +51: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon aucun Save / Create / Generate dans l’UI
00:01 +52: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon catégorie optionnelle : champ vide
00:01 +53: All tests passed!

```

### flutter test — dossier test/environment_studio (sortie complète enregistrée)

```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart: environmentDiagnosticKindLabel quelques kinds FR stables
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart: EnvironmentStudioPanel — browser read-only sections identité, paramètres, palette et diagnostics visibles
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart: EnvironmentStudioPanel — browser read-only sections identité, paramètres, palette et diagnostics visibles
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart: EnvironmentStudioPanel état vide : titre, badge read-only, pas de liste ni détail
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart: EnvironmentStudioPanel état vide : titre, badge read-only, pas de liste ni détail
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart: EnvironmentStudioPanel état vide : titre, badge read-only, pas de liste ni détail
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart: EnvironmentStudioPanel état vide : titre, badge read-only, pas de liste ni détail
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart: EnvironmentStudioPanel état vide : titre, badge read-only, pas de liste ni détail
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart: EnvironmentStudioPanel état vide : titre, badge read-only, pas de liste ni détail
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +24: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +25: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +26: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +27: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +28: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +29: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +30: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +31: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +32: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +33: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +34: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +35: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +36: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +37: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +38: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +39: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +40: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +41: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +42: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +43: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +44: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +45: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +46: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +47: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +48: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +49: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +50: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +51: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +52: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +53: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +54: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:00 +55: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +56: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +57: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +58: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:01 +59: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace le project explorer ouvre Environment Studio au tap (clé dédiée)
00:01 +60: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace le project explorer ouvre Environment Studio au tap (clé dédiée)
00:01 +61: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace le project explorer ouvre Environment Studio au tap (clé dédiée)
00:01 +62: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:01 +63: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:01 +64: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:01 +65: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:01 +66: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:01 +67: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:02 +68: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:02 +69: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) elementId connu : plus d’emptyPaletteElementId ni missingPaletteElement
00:02 +70: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) elementId absent : Élément introuvable
00:02 +71: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) poids 3 valide, poids 0 invalide, texte non numérique inchangé
00:02 +72: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) collision : bascule Collision forcée puis Collision désactivée
00:02 +73: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) tags : tree, canopy OK ; tree, , canopy → Tag vide
00:02 +74: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) Retirer : palette vide, emptyPalette revient
00:02 +75: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) deux items même elementId : Élément dupliqué
00:03 +76: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) édition palette + retour browser : manifest.environmentPresets inchangé
00:03 +77: All tests passed!

```

### flutter test — editor_workspace_controller + top_toolbar

```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectPokedexWorkspace switches mode and clears stale errors
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectTrainerWorkspace switches mode and clears stale errors
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectDialogueWorkspace keeps project session and only changes mode
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectEnvironmentStudioWorkspace switches mode and clears stale errors
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectPokemonCatalogSection opens the parent workspace and stores the section
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows the app brand and project workspace label
Warning: Falling back on slow accent color resolution. It's possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui's accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar falls back to the workspace label when no project is loaded
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows the toolbar status chip when a status is present
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows the trainer studio label for the trainer workspace
00:01 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar enables project save and disables map history in Path Studio
00:01 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows neutral Save Project when project is clean in Path Studio
00:01 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar enables project save and disables map history in Environment Studio
00:01 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows Environment Studio in the workspace brand strip
00:01 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar keeps map save action in map workspace
00:01 +14: All tests passed!

```

### flutter test — map_editor complet (dernières lignes pertinentes, exit code 1)

```
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/items_catalog_sync_lMqb95/project.json
00:58 +907 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: sync converts PokeAPI item payload fields into the local catalog shape
00:58 +908 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: ... malformed payloads and duplicate external resources with warnings
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/items_catalog_sync_fZKETR/project.json
00:58 +908 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: sync tolerates malformed payloads and duplicate external resources with warnings
00:58 +908 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: ... pokemon data root for both the items catalog and local sprite assets
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/items_catalog_sync_bNXkGC/project.json
00:58 +909 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: sync honors a custom pokemon data root for both the items catalog and local sprite assets
00:58 +909 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: load use case reads the synced catalog after a real sync
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/items_catalog_sync_NN0JD0/project.json
00:58 +910 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: load use case reads the synced catalog after a real sync
00:58 +910 -34: Some tests failed.

```

## 13. Git status initial et final

**Git status initial** (capturé au début de l’implémentation Lot 14, avant rapport) :

```
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
 M packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart
?? packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart
?? packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart

```

**Preuve fichier `environment_palette_item_draft_editor.dart` absent de `HEAD`** :

```
fatal: path 'packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart' exists on disk, but not in 'HEAD'
```

**Git status final** (`git status --short --untracked-files=all`) :

```
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
 M packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart
?? packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart
?? packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart
?? reports/forest/environment_studio_lot_14_palette_draft_editor.md

```

### Fichiers inspectés pendant l’audit

- `packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart`
- `packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_draft.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_validation_view.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_presentation.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_view.dart`
- Tests `environment_preset_draft_test.dart`, `environment_studio_preset_creation_form_test.dart`, `environment_studio_preset_browser_test.dart`, `environment_studio_workspace_test.dart`
- `packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart`

### Confirmations Evidence Pack

- Aucun `ProjectManifest` modifié par ce lot (brouillon local uniquement).
- Aucun `MapLayer` modifié.
- Aucun appel à `upsertProjectEnvironmentPreset` dans le code livré du lot.
- Aucune sauvegarde disque ajoutée par ce lot.
- Aucun générateur créé.
- Aucun `build_runner` lancé.
- Aucun fichier généré modifié.
- Aucune opération git d’écriture (`commit` / `add` / `push` / etc.).

## 14. Contenu complet des fichiers créés ou modifiés

### `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart`

```dart
import 'package:flutter/cupertino.dart';

import '../../../ui/shared/cupertino_editor_widgets.dart';
import '../authoring/environment_preset_draft.dart';
import 'environment_palette_item_draft_editor.dart';
import 'environment_preset_draft_validation_view.dart';

/// Formulaire local de brouillon (aucune persistance manifest).
class EnvironmentPresetDraftForm extends StatefulWidget {
  const EnvironmentPresetDraftForm({
    super.key,
    required this.draft,
    required this.validation,
    required this.onChanged,
    required this.onCancel,
    required this.onReset,
  });

  final EnvironmentPresetDraft draft;
  final EnvironmentPresetDraftValidationReport validation;
  final ValueChanged<EnvironmentPresetDraft> onChanged;
  final VoidCallback onCancel;
  final VoidCallback onReset;

  @override
  State<EnvironmentPresetDraftForm> createState() =>
      _EnvironmentPresetDraftFormState();
}

class _EnvironmentPresetDraftFormState
    extends State<EnvironmentPresetDraftForm> {
  late final TextEditingController _idCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _templateCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _sortCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _idCtrl = TextEditingController(text: d.id);
    _nameCtrl = TextEditingController(text: d.name);
    _templateCtrl = TextEditingController(text: d.templateId);
    _categoryCtrl = TextEditingController(text: d.categoryId ?? '');
    _sortCtrl = TextEditingController(text: d.sortOrder.toString());
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _templateCtrl.dispose();
    _categoryCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  void _emit({List<EnvironmentPaletteItemDraft>? palette}) {
    final so = int.tryParse(_sortCtrl.text.trim());
    widget.onChanged(
      EnvironmentPresetDraft(
        id: _idCtrl.text,
        name: _nameCtrl.text,
        templateId: _templateCtrl.text,
        palette: palette ?? widget.draft.palette,
        defaultParams: widget.draft.defaultParams,
        categoryId:
            _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text,
        sortOrder: so ?? widget.draft.sortOrder,
      ),
    );
  }

  void _addPaletteItem() {
    final next = [
      ...widget.draft.palette,
      EnvironmentPaletteItemDraft(elementId: '', weight: 1),
    ];
    _emit(palette: next);
  }

  void _replacePaletteItem(int index, EnvironmentPaletteItemDraft item) {
    final next = List<EnvironmentPaletteItemDraft>.from(widget.draft.palette);
    next[index] = item;
    _emit(palette: next);
  }

  void _removePaletteItem(int index) {
    final next = List<EnvironmentPaletteItemDraft>.from(widget.draft.palette)
      ..removeAt(index);
    _emit(palette: next);
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final fill = EditorChrome.chipFill(context);
    final border = CupertinoColors.separator.resolveFrom(context);
    final p = widget.draft.defaultParams;

    return SingleChildScrollView(
      key: const Key('environment-studio-draft-form-scroll'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nouveau preset d’environnement',
            key: const Key('environment-studio-draft-form-title'),
            style: TextStyle(
              color: label,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: EditorChrome.accentWarm.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: EditorChrome.accentWarm.withValues(alpha: 0.45),
              ),
            ),
            child: const Text(
              'Brouillon local non sauvegardé',
              key: Key('environment-studio-draft-local-badge'),
              style: TextStyle(
                color: EditorChrome.accentWarm,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ce formulaire prépare un preset. L’enregistrement dans le projet sera '
            'ajouté dans un prochain lot.',
            key: const Key('environment-studio-draft-form-intro'),
            style: TextStyle(
              color: subtle,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _fieldLabel(context, 'Id'),
          const SizedBox(height: 4),
          CupertinoTextField(
            key: const Key('environment-studio-draft-field-id'),
            controller: _idCtrl,
            placeholder: 'Identifiant unique',
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 14),
          _fieldLabel(context, 'Nom'),
          const SizedBox(height: 4),
          CupertinoTextField(
            key: const Key('environment-studio-draft-field-name'),
            controller: _nameCtrl,
            placeholder: 'Nom affiché',
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 14),
          _fieldLabel(context, 'Template'),
          const SizedBox(height: 4),
          CupertinoTextField(
            key: const Key('environment-studio-draft-field-template'),
            controller: _templateCtrl,
            placeholder: 'Ex. forest_dense',
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 14),
          _fieldLabel(context, 'Catégorie (optionnel)'),
          const SizedBox(height: 4),
          CupertinoTextField(
            key: const Key('environment-studio-draft-field-category'),
            controller: _categoryCtrl,
            placeholder: 'Laisser vide si sans catégorie',
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 14),
          _fieldLabel(context, 'Ordre d’affichage'),
          const SizedBox(height: 4),
          CupertinoTextField(
            key: const Key('environment-studio-draft-field-sort'),
            controller: _sortCtrl,
            placeholder: '0',
            keyboardType: TextInputType.number,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 22),
          Text(
            'Paramètres par défaut (lecture seule pour l’instant)',
            style: TextStyle(
              color: label,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Densité ${p.density.toStringAsFixed(2)} · '
                'Variation ${p.variation.toStringAsFixed(2)} · '
                'Densité des bords ${p.edgeDensity.toStringAsFixed(2)} · '
                'Espacement min. ${p.minSpacingCells} cases',
                key: const Key('environment-studio-draft-params-readonly'),
                style: TextStyle(color: subtle, fontSize: 12.5, height: 1.35),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Palette du brouillon',
            key: const Key('environment-studio-draft-palette-section-title'),
            style: TextStyle(
              color: label,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les éléments ajoutés ici restent dans le brouillon local tant que la '
            'création réelle n’est pas branchée.',
            key: const Key('environment-studio-draft-palette-local-note'),
            style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: CupertinoButton(
              key: const Key('environment-studio-draft-palette-add-item'),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              onPressed: _addPaletteItem,
              child: const Text('Ajouter un item de palette'),
            ),
          ),
          const SizedBox(height: 10),
          if (widget.draft.palette.isEmpty)
            Text(
              'Aucun item pour l’instant.',
              key: const Key('environment-studio-draft-palette-no-items'),
              style: TextStyle(color: subtle, fontSize: 13),
            )
          else ...[
            for (var i = 0; i < widget.draft.palette.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i < widget.draft.palette.length - 1 ? 12 : 0,
                ),
                child: EnvironmentPaletteItemDraftEditor(
                  key: ValueKey('palette-draft-slot-$i'),
                  index: i,
                  item: widget.draft.palette[i],
                  onChanged: (it) => _replacePaletteItem(i, it),
                  onRemove: () => _removePaletteItem(i),
                ),
              ),
          ],
          const SizedBox(height: 22),
          Text(
            'Validation du brouillon',
            style: TextStyle(
              color: label,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          EnvironmentPresetDraftValidationView(
            report: widget.validation,
            labelColor: label,
            subtleColor: subtle,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CupertinoButton(
                key: const Key('environment-studio-draft-cancel'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                onPressed: widget.onCancel,
                child: const Text('Retour au browser'),
              ),
              CupertinoButton(
                key: const Key('environment-studio-draft-reset'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                onPressed: widget.onReset,
                child: const Text('Réinitialiser brouillon'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        color: EditorChrome.subtleLabel(context),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

```

### `packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/shared/cupertino_editor_widgets.dart';
import '../authoring/environment_preset_draft.dart';

/// Carte éditable d’un [EnvironmentPaletteItemDraft] (Lot Environment-14).
///
/// [ValueKey] côté parent : **`palette-draft-slot-$index`** ([index] stable dans
/// la liste). Quand un item est retiré, les indices se réindexent : les
/// contrôleurs du slot `i` sont resynchronisés depuis le nouvel [item] via
/// [didUpdateWidget] pour éviter d’afficher le texte d’un ancien voisin.
class EnvironmentPaletteItemDraftEditor extends StatefulWidget {
  const EnvironmentPaletteItemDraftEditor({
    super.key,
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final EnvironmentPaletteItemDraft item;
  final ValueChanged<EnvironmentPaletteItemDraft> onChanged;
  final VoidCallback onRemove;

  @override
  State<EnvironmentPaletteItemDraftEditor> createState() =>
      _EnvironmentPaletteItemDraftEditorState();
}

class _EnvironmentPaletteItemDraftEditorState
    extends State<EnvironmentPaletteItemDraftEditor> {
  late final TextEditingController _elementIdCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _tagsCtrl;

  @override
  void initState() {
    super.initState();
    _elementIdCtrl = TextEditingController(text: widget.item.elementId);
    _weightCtrl = TextEditingController(text: widget.item.weight.toString());
    _tagsCtrl = TextEditingController(text: _tagsToField(widget.item.tags));
  }

  @override
  void didUpdateWidget(covariant EnvironmentPaletteItemDraftEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      _elementIdCtrl.text = widget.item.elementId;
      _weightCtrl.text = widget.item.weight.toString();
      _tagsCtrl.text = _tagsToField(widget.item.tags);
    }
  }

  @override
  void dispose() {
    _elementIdCtrl.dispose();
    _weightCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  static String _tagsToField(Set<String> tags) {
    final list = tags.toList()..sort();
    return list.join(', ');
  }

  static Set<String> _fieldToTags(String text) {
    return text.split(',').map((t) => t.trim()).toSet();
  }

  static int _collisionToSegment(EnvironmentCollisionMode m) {
    return switch (m) {
      EnvironmentCollisionMode.useElementDefault => 0,
      EnvironmentCollisionMode.forceEnabled => 1,
      EnvironmentCollisionMode.forceDisabled => 2,
    };
  }

  static EnvironmentCollisionMode _segmentToCollision(int i) {
    return switch (i) {
      1 => EnvironmentCollisionMode.forceEnabled,
      2 => EnvironmentCollisionMode.forceDisabled,
      _ => EnvironmentCollisionMode.useElementDefault,
    };
  }

  void _emit({
    String? elementId,
    int? weight,
    EnvironmentCollisionMode? collisionMode,
    Set<String>? tags,
  }) {
    widget.onChanged(
      widget.item.copyWith(
        elementId: elementId,
        weight: weight,
        collisionMode: collisionMode,
        tags: tags,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final fill = EditorChrome.chipFill(context);
    final border = CupertinoColors.separator.resolveFrom(context);
    final seg = _collisionToSegment(widget.item.collisionMode);

    return DecoratedBox(
      key: Key('environment-studio-palette-draft-item-${widget.index}'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
        color: fill,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Item ${widget.index + 1}',
                    style: TextStyle(
                      color: subtle,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                CupertinoButton(
                  key: Key(
                    'environment-studio-palette-draft-remove-${widget.index}',
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  onPressed: widget.onRemove,
                  child: const Text('Retirer'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Element id',
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            CupertinoTextField(
              key: Key(
                'environment-studio-palette-draft-element-${widget.index}',
              ),
              controller: _elementIdCtrl,
              placeholder: 'Identifiant d’élément',
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              onChanged: (v) => _emit(elementId: v),
            ),
            const SizedBox(height: 10),
            Text(
              'Poids',
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            CupertinoTextField(
              key: Key(
                'environment-studio-palette-draft-weight-${widget.index}',
              ),
              controller: _weightCtrl,
              placeholder: '1',
              keyboardType: TextInputType.number,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              onChanged: (raw) {
                final t = raw.trim();
                if (t.isEmpty) {
                  return;
                }
                final parsed = int.tryParse(t);
                if (parsed == null) {
                  return;
                }
                _emit(weight: parsed);
              },
            ),
            const SizedBox(height: 10),
            Text(
              'Collision',
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<int>(
                key: Key(
                  'environment-studio-palette-draft-collision-${widget.index}',
                ),
                groupValue: seg,
                children: {
                  0: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Défaut élément',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: label),
                    ),
                  ),
                  1: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Collision forcée',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: label),
                    ),
                  ),
                  2: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Collision désactivée',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: label),
                    ),
                  ),
                },
                onValueChanged: (v) {
                  if (v == null) {
                    return;
                  }
                  _emit(collisionMode: _segmentToCollision(v));
                },
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tags',
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            CupertinoTextField(
              key: Key(
                'environment-studio-palette-draft-tags-${widget.index}',
              ),
              controller: _tagsCtrl,
              placeholder: 'tree, canopy',
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              onChanged: (v) => _emit(tags: _fieldToTags(v)),
            ),
          ],
        ),
      ),
    );
  }
}

```

### `packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';

void main() {
  group('EnvironmentStudioPanel — palette brouillon (Lot 14)', () {
    testWidgets(
        'ajouter un item : emptyPalette disparaît, emptyPaletteElementId',
        (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      expect(
        _validationHas(tester, 'Palette vide'),
        isTrue,
      );

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();

      expect(
        _validationHas(tester, 'Palette vide'),
        isFalse,
      );
      expect(
        _validationHas(tester, 'Élément de palette vide'),
        isTrue,
      );
      expect(
        find.byKey(const Key('environment-studio-palette-draft-item-0')),
        findsOneWidget,
      );
    });

    testWidgets(
        'elementId connu : plus d’emptyPaletteElementId ni missingPaletteElement',
        (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('environment-studio-palette-draft-element-0')),
        'elm',
      );
      await tester.pumpAndSettle();

      expect(
        _validationHas(tester, 'Élément de palette vide'),
        isFalse,
      );
      expect(
        _validationHas(tester, 'Élément introuvable'),
        isFalse,
      );
    });

    testWidgets('elementId absent : Élément introuvable', (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('environment-studio-palette-draft-element-0')),
        'inconnu_xyz',
      );
      await tester.pumpAndSettle();

      expect(
        _validationHas(tester, 'Élément introuvable'),
        isTrue,
      );
    });

    testWidgets(
        'poids 3 valide, poids 0 invalide, texte non numérique inchangé',
        (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();

      final w =
          find.byKey(const Key('environment-studio-palette-draft-weight-0'));

      await tester.enterText(w, '3');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Poids invalide'),
        isFalse,
      );

      await tester.enterText(w, '0');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Poids invalide'),
        isTrue,
      );

      await tester.enterText(w, '5');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Poids invalide'),
        isFalse,
      );

      await tester.enterText(w, 'not_int');
      await tester.pumpAndSettle();
      expect(
        (tester.widget<CupertinoTextField>(w)).controller?.text,
        'not_int',
      );
      expect(
        _validationHas(tester, 'Poids invalide'),
        isFalse,
      );
    });

    testWidgets(
        'collision : bascule Collision forcée puis Collision désactivée',
        (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Défaut élément'), findsWidgets);

      await tester.tap(find.text('Collision forcée').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Collision désactivée').last);
      await tester.pumpAndSettle();
    });

    testWidgets('tags : tree, canopy OK ; tree, , canopy → Tag vide', (
      tester,
    ) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();

      final tags =
          find.byKey(const Key('environment-studio-palette-draft-tags-0'));

      await tester.enterText(tags, 'tree, canopy');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Tag vide'),
        isFalse,
      );

      await tester.enterText(tags, 'tree, , canopy');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Tag vide'),
        isTrue,
      );
    });

    testWidgets('Retirer : palette vide, emptyPalette revient', (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();

      expect(
        _validationHas(tester, 'Palette vide'),
        isFalse,
      );

      await tester.ensureVisible(
        find.byKey(const Key('environment-studio-palette-draft-remove-0')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('environment-studio-palette-draft-remove-0')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('environment-studio-draft-palette-no-items')),
        findsOneWidget,
      );
      expect(
        _validationHas(tester, 'Palette vide'),
        isTrue,
      );
    });

    testWidgets('deux items même elementId : Élément dupliqué', (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('environment-studio-palette-draft-element-0')),
        'elm',
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('environment-studio-palette-draft-element-1')),
        'elm',
      );
      await tester.pumpAndSettle();

      expect(
        _validationHas(tester, 'Élément dupliqué'),
        isTrue,
      );
    });

    testWidgets(
        'édition palette + retour browser : manifest.environmentPresets inchangé',
        (tester) async {
      final manifest = _manifest(
        environmentPresets: [
          _preset(id: 'keep'),
        ],
        elements: [_element(id: 'elm')],
      );
      final idsBefore =
          manifest.environmentPresets.map((p) => p.id).toList(growable: false);

      await _pump(tester, manifest);
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('environment-studio-palette-draft-element-0')),
        'elm',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('environment-studio-draft-cancel')),
      );
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('environment-studio-draft-cancel')));
      await tester.pumpAndSettle();

      expect(
        manifest.environmentPresets.map((p) => p.id).toList(growable: false),
        idsBefore,
      );
      expect(manifest.environmentPresets.length, 1);
    });
  });
}

bool _validationHas(WidgetTester tester, String substring) {
  final matches = find.descendant(
    of: find.byKey(const Key('environment-studio-draft-validation-root')),
    matching: find.textContaining(substring),
  );
  return matches.evaluate().isNotEmpty;
}

Future<void> _pump(WidgetTester tester, ProjectManifest manifest) async {
  tester.view.physicalSize = const Size(900, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MacosApp(
      home: CupertinoPageScaffold(
        child: EnvironmentStudioPanel(manifest: manifest),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProjectManifest _manifest({
  List<EnvironmentPreset> environmentPresets = const [],
  List<ProjectElementEntry> elements = const [],
}) {
  return ProjectManifest(
    name: 'palette-draft-test',
    maps: const [],
    tilesets: const [],
    environmentPresets: environmentPresets,
    elements: elements,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

EnvironmentPreset _preset({required String id}) {
  return EnvironmentPreset(
    id: id,
    name: 'P $id',
    templateId: 'tpl',
    palette: [
      EnvironmentPaletteItem(elementId: 'elm', weight: 1),
    ],
    defaultParams: EnvironmentGenerationParams.standard(),
    sortOrder: 0,
  );
}

ProjectElementEntry _element({required String id}) {
  return ProjectElementEntry(
    id: id,
    name: 'El $id',
    tilesetId: 'ts',
    categoryId: 'cat',
    frames: const [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0),
      ),
    ],
  );
}

```

### `packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/environment_studio/authoring/environment_preset_draft.dart';
import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';
import 'package:map_editor/src/features/environment_studio/widgets/environment_preset_draft_presentation.dart';

void main() {
  group('environmentPresetDraftIssueKindLabel', () {
    test('libellés FR attendus (extrait)', () {
      expect(
        environmentPresetDraftIssueKindLabel(
          EnvironmentPresetDraftIssueKind.emptyId,
        ),
        'Id vide',
      );
      expect(
        environmentPresetDraftIssueKindLabel(
          EnvironmentPresetDraftIssueKind.emptyPalette,
        ),
        'Palette vide',
      );
    });
  });

  group('EnvironmentStudioPanel — formulaire brouillon', () {
    testWidgets('action Préparer un preset visible puis formulaire', (
      tester,
    ) async {
      await _pump(
        tester,
        _manifest(
          environmentPresets: [
            _preset(id: 'a'),
          ],
          elements: [_element(id: 'elm')],
        ),
      );

      expect(find.byKey(const Key('environment-studio-open-draft')),
          findsOneWidget);
      expect(find.text('Préparer un preset'), findsOneWidget);

      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('environment-studio-draft-form-title')),
        findsOneWidget,
      );
      expect(find.text('Nouveau preset d’environnement'), findsOneWidget);
      expect(
        find.byKey(const Key('environment-studio-draft-local-badge')),
        findsOneWidget,
      );
      expect(find.text('Brouillon local non sauvegardé'), findsOneWidget);
      expect(
        find.byKey(const Key('environment-studio-draft-form-intro')),
        findsOneWidget,
      );
    });

    testWidgets('champs initiaux vides et params standard', (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      expect(
        (tester.widget<CupertinoTextField>(
                find.byKey(const Key('environment-studio-draft-field-id'))))
            .controller
            ?.text,
        '',
      );
      expect(
        (tester.widget<CupertinoTextField>(
                find.byKey(const Key('environment-studio-draft-field-name'))))
            .controller
            ?.text,
        '',
      );
      expect(
        (tester.widget<CupertinoTextField>(find
                .byKey(const Key('environment-studio-draft-field-template'))))
            .controller
            ?.text,
        '',
      );
      expect(
        (tester.widget<CupertinoTextField>(find
                .byKey(const Key('environment-studio-draft-field-category'))))
            .controller
            ?.text,
        '',
      );
      expect(
        (tester.widget<CupertinoTextField>(
                find.byKey(const Key('environment-studio-draft-field-sort'))))
            .controller
            ?.text,
        '0',
      );
      expect(
        find.byKey(const Key('environment-studio-draft-params-readonly')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-studio-draft-palette-section-title')),
        findsOneWidget,
      );
      expect(find.text('Palette du brouillon'), findsOneWidget);
      expect(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-studio-draft-palette-no-items')),
        findsOneWidget,
      );
    });

    testWidgets('validation initiale : id, nom, template, palette', (
      tester,
    ) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('environment-studio-draft-validation-counts')),
        findsOneWidget,
      );
      expect(find.textContaining('erreur'), findsWidgets);
      expect(find.textContaining('Id vide'), findsOneWidget);
      expect(find.textContaining('Nom vide'), findsOneWidget);
      expect(find.textContaining('Template vide'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('environment-studio-draft-validation-root')),
          matching: find.textContaining('Palette vide'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('saisie met à jour le draft et la validation', (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-id')),
        'new_id',
      );
      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-name')),
        'Nom',
      );
      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-template')),
        'tpl1',
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Id vide'), findsNothing);
      expect(find.textContaining('Nom vide'), findsNothing);
      expect(find.textContaining('Template vide'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('environment-studio-draft-validation-root')),
          matching: find.textContaining('Palette vide'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sortOrder : texte invalide conserve la valeur draft', (
      tester,
    ) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-sort')),
        'not_a_number',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-id')),
        'x',
      );
      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-name')),
        'N',
      );
      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-template')),
        't',
      );
      await tester.pumpAndSettle();

      expect(
        (tester.widget<CupertinoTextField>(
                find.byKey(const Key('environment-studio-draft-field-sort'))))
            .controller
            ?.text,
        'not_a_number',
      );
    });

    testWidgets('Réinitialiser brouillon remet les champs vides', (
      tester,
    ) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-id')),
        'tmp',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('environment-studio-draft-reset')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('environment-studio-draft-reset')));
      await tester.pumpAndSettle();

      expect(
        (tester.widget<CupertinoTextField>(
                find.byKey(const Key('environment-studio-draft-field-id'))))
            .controller
            ?.text,
        '',
      );
      expect(
        (tester.widget<CupertinoTextField>(
                find.byKey(const Key('environment-studio-draft-field-sort'))))
            .controller
            ?.text,
        '0',
      );
    });

    testWidgets('Retour au browser restaure la liste sans modifier le manifest',
        (tester) async {
      final manifest = _manifest(
        environmentPresets: [
          _preset(id: 'keep'),
        ],
        elements: [_element(id: 'elm')],
      );
      final idsBefore =
          manifest.environmentPresets.map((p) => p.id).toList(growable: false);
      final n = idsBefore.length;

      await _pump(tester, manifest);
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-id')),
        'intruder',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('environment-studio-draft-cancel')),
      );
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('environment-studio-draft-cancel')));
      await tester.pumpAndSettle();

      expect(manifest.environmentPresets.length, n);
      expect(
        manifest.environmentPresets.map((p) => p.id).toList(growable: false),
        idsBefore,
      );
      expect(find.byKey(const Key('environment-studio-preset-list')),
          findsOneWidget);
      expect(find.text('keep'), findsWidgets);
    });

    testWidgets('aucun Save / Create / Generate dans l’UI', (tester) async {
      await _pump(
        tester,
        _manifest(
          environmentPresets: [_preset(id: 'z')],
          elements: [_element(id: 'elm')],
        ),
      );
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Save'), findsNothing);
      expect(find.textContaining('Create'), findsNothing);
      expect(find.textContaining('Generate'), findsNothing);
    });

    testWidgets('catégorie optionnelle : champ vide', (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      expect(
        (tester.widget<CupertinoTextField>(find
                .byKey(const Key('environment-studio-draft-field-category'))))
            .controller
            ?.text,
        '',
      );
    });
  });
}

Future<void> _pump(WidgetTester tester, ProjectManifest manifest) async {
  tester.view.physicalSize = const Size(900, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MacosApp(
      home: CupertinoPageScaffold(
        child: EnvironmentStudioPanel(manifest: manifest),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProjectManifest _manifest({
  List<EnvironmentPreset> environmentPresets = const [],
  List<ProjectElementEntry> elements = const [],
}) {
  return ProjectManifest(
    name: 'form-shell-test',
    maps: const [],
    tilesets: const [],
    environmentPresets: environmentPresets,
    elements: elements,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

EnvironmentPreset _preset({required String id}) {
  return EnvironmentPreset(
    id: id,
    name: 'P $id',
    templateId: 'tpl',
    palette: [
      EnvironmentPaletteItem(elementId: 'elm', weight: 1),
    ],
    defaultParams: EnvironmentGenerationParams.standard(),
    sortOrder: 0,
  );
}

ProjectElementEntry _element({required String id}) {
  return ProjectElementEntry(
    id: id,
    name: 'El $id',
    tilesetId: 'ts',
    categoryId: 'cat',
    frames: const [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0),
      ),
    ],
  );
}

```

## 15. Diff complet

### Fichiers modifiés — `git diff`

#### `environment_preset_draft_form.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart b/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
index c98fe40f..b65de787 100644
--- a/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
+++ b/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
@@ -2,6 +2,7 @@ import 'package:flutter/cupertino.dart';
 
 import '../../../ui/shared/cupertino_editor_widgets.dart';
 import '../authoring/environment_preset_draft.dart';
+import 'environment_palette_item_draft_editor.dart';
 import 'environment_preset_draft_validation_view.dart';
 
 /// Formulaire local de brouillon (aucune persistance manifest).
@@ -55,14 +56,14 @@ class _EnvironmentPresetDraftFormState
     super.dispose();
   }
 
-  void _emit() {
+  void _emit({List<EnvironmentPaletteItemDraft>? palette}) {
     final so = int.tryParse(_sortCtrl.text.trim());
     widget.onChanged(
       EnvironmentPresetDraft(
         id: _idCtrl.text,
         name: _nameCtrl.text,
         templateId: _templateCtrl.text,
-        palette: widget.draft.palette,
+        palette: palette ?? widget.draft.palette,
         defaultParams: widget.draft.defaultParams,
         categoryId:
             _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text,
@@ -71,6 +72,26 @@ class _EnvironmentPresetDraftFormState
     );
   }
 
+  void _addPaletteItem() {
+    final next = [
+      ...widget.draft.palette,
+      EnvironmentPaletteItemDraft(elementId: '', weight: 1),
+    ];
+    _emit(palette: next);
+  }
+
+  void _replacePaletteItem(int index, EnvironmentPaletteItemDraft item) {
+    final next = List<EnvironmentPaletteItemDraft>.from(widget.draft.palette);
+    next[index] = item;
+    _emit(palette: next);
+  }
+
+  void _removePaletteItem(int index) {
+    final next = List<EnvironmentPaletteItemDraft>.from(widget.draft.palette)
+      ..removeAt(index);
+    _emit(palette: next);
+  }
+
   @override
   Widget build(BuildContext context) {
     final label = EditorChrome.primaryLabel(context);
@@ -206,7 +227,8 @@ class _EnvironmentPresetDraftFormState
           ),
           const SizedBox(height: 22),
           Text(
-            'Palette',
+            'Palette du brouillon',
+            key: const Key('environment-studio-draft-palette-section-title'),
             style: TextStyle(
               color: label,
               fontSize: 14,
@@ -215,16 +237,43 @@ class _EnvironmentPresetDraftFormState
           ),
           const SizedBox(height: 8),
           Text(
-            'État : aucune entrée de palette (non éditable en V0).',
-            key: const Key('environment-studio-draft-palette-empty'),
-            style: TextStyle(color: subtle, fontSize: 13),
-          ),
-          const SizedBox(height: 4),
-          Text(
-            'L’édition de palette arrive dans un prochain lot.',
-            key: const Key('environment-studio-draft-palette-note'),
+            'Les éléments ajoutés ici restent dans le brouillon local tant que la '
+            'création réelle n’est pas branchée.',
+            key: const Key('environment-studio-draft-palette-local-note'),
             style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
           ),
+          const SizedBox(height: 12),
+          Align(
+            alignment: Alignment.centerLeft,
+            child: CupertinoButton(
+              key: const Key('environment-studio-draft-palette-add-item'),
+              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
+              onPressed: _addPaletteItem,
+              child: const Text('Ajouter un item de palette'),
+            ),
+          ),
+          const SizedBox(height: 10),
+          if (widget.draft.palette.isEmpty)
+            Text(
+              'Aucun item pour l’instant.',
+              key: const Key('environment-studio-draft-palette-no-items'),
+              style: TextStyle(color: subtle, fontSize: 13),
+            )
+          else ...[
+            for (var i = 0; i < widget.draft.palette.length; i++)
+              Padding(
+                padding: EdgeInsets.only(
+                  bottom: i < widget.draft.palette.length - 1 ? 12 : 0,
+                ),
+                child: EnvironmentPaletteItemDraftEditor(
+                  key: ValueKey('palette-draft-slot-$i'),
+                  index: i,
+                  item: widget.draft.palette[i],
+                  onChanged: (it) => _replacePaletteItem(i, it),
+                  onRemove: () => _removePaletteItem(i),
+                ),
+              ),
+          ],
           const SizedBox(height: 22),
           Text(
             'Validation du brouillon',

```

#### `environment_studio_preset_creation_form_test.dart`

```diff
diff --git a/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart b/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart
index 616111a9..ccaa4d5e 100644
--- a/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart
+++ b/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart
@@ -106,11 +106,16 @@ void main() {
         findsOneWidget,
       );
       expect(
-        find.byKey(const Key('environment-studio-draft-palette-empty')),
+        find.byKey(const Key('environment-studio-draft-palette-section-title')),
         findsOneWidget,
       );
+      expect(find.text('Palette du brouillon'), findsOneWidget);
       expect(
-        find.byKey(const Key('environment-studio-draft-palette-note')),
+        find.byKey(const Key('environment-studio-draft-palette-add-item')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const Key('environment-studio-draft-palette-no-items')),
         findsOneWidget,
       );
     });

```

### Fichiers nouveaux — équivalent `diff /dev/null`

#### `packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart`

```diff
+import 'package:flutter/cupertino.dart';
+import 'package:map_core/map_core.dart';
+
+import '../../../ui/shared/cupertino_editor_widgets.dart';
+import '../authoring/environment_preset_draft.dart';
+
+/// Carte éditable d’un [EnvironmentPaletteItemDraft] (Lot Environment-14).
+///
+/// [ValueKey] côté parent : **`palette-draft-slot-$index`** ([index] stable dans
+/// la liste). Quand un item est retiré, les indices se réindexent : les
+/// contrôleurs du slot `i` sont resynchronisés depuis le nouvel [item] via
+/// [didUpdateWidget] pour éviter d’afficher le texte d’un ancien voisin.
+class EnvironmentPaletteItemDraftEditor extends StatefulWidget {
+  const EnvironmentPaletteItemDraftEditor({
+    super.key,
+    required this.index,
+    required this.item,
+    required this.onChanged,
+    required this.onRemove,
+  });
+
+  final int index;
+  final EnvironmentPaletteItemDraft item;
+  final ValueChanged<EnvironmentPaletteItemDraft> onChanged;
+  final VoidCallback onRemove;
+
+  @override
+  State<EnvironmentPaletteItemDraftEditor> createState() =>
+      _EnvironmentPaletteItemDraftEditorState();
+}
+
+class _EnvironmentPaletteItemDraftEditorState
+    extends State<EnvironmentPaletteItemDraftEditor> {
+  late final TextEditingController _elementIdCtrl;
+  late final TextEditingController _weightCtrl;
+  late final TextEditingController _tagsCtrl;
+
+  @override
+  void initState() {
+    super.initState();
+    _elementIdCtrl = TextEditingController(text: widget.item.elementId);
+    _weightCtrl = TextEditingController(text: widget.item.weight.toString());
+    _tagsCtrl = TextEditingController(text: _tagsToField(widget.item.tags));
+  }
+
+  @override
+  void didUpdateWidget(covariant EnvironmentPaletteItemDraftEditor oldWidget) {
+    super.didUpdateWidget(oldWidget);
+    if (oldWidget.item != widget.item) {
+      _elementIdCtrl.text = widget.item.elementId;
+      _weightCtrl.text = widget.item.weight.toString();
+      _tagsCtrl.text = _tagsToField(widget.item.tags);
+    }
+  }
+
+  @override
+  void dispose() {
+    _elementIdCtrl.dispose();
+    _weightCtrl.dispose();
+    _tagsCtrl.dispose();
+    super.dispose();
+  }
+
+  static String _tagsToField(Set<String> tags) {
+    final list = tags.toList()..sort();
+    return list.join(', ');
+  }
+
+  static Set<String> _fieldToTags(String text) {
+    return text.split(',').map((t) => t.trim()).toSet();
+  }
+
+  static int _collisionToSegment(EnvironmentCollisionMode m) {
+    return switch (m) {
+      EnvironmentCollisionMode.useElementDefault => 0,
+      EnvironmentCollisionMode.forceEnabled => 1,
+      EnvironmentCollisionMode.forceDisabled => 2,
+    };
+  }
+
+  static EnvironmentCollisionMode _segmentToCollision(int i) {
+    return switch (i) {
+      1 => EnvironmentCollisionMode.forceEnabled,
+      2 => EnvironmentCollisionMode.forceDisabled,
+      _ => EnvironmentCollisionMode.useElementDefault,
+    };
+  }
+
+  void _emit({
+    String? elementId,
+    int? weight,
+    EnvironmentCollisionMode? collisionMode,
+    Set<String>? tags,
+  }) {
+    widget.onChanged(
+      widget.item.copyWith(
+        elementId: elementId,
+        weight: weight,
+        collisionMode: collisionMode,
+        tags: tags,
+      ),
+    );
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+    final fill = EditorChrome.chipFill(context);
+    final border = CupertinoColors.separator.resolveFrom(context);
+    final seg = _collisionToSegment(widget.item.collisionMode);
+
+    return DecoratedBox(
+      key: Key('environment-studio-palette-draft-item-${widget.index}'),
+      decoration: BoxDecoration(
+        borderRadius: BorderRadius.circular(12),
+        border: Border.all(color: border),
+        color: fill,
+      ),
+      child: Padding(
+        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.stretch,
+          children: [
+            Row(
+              children: [
+                Expanded(
+                  child: Text(
+                    'Item ${widget.index + 1}',
+                    style: TextStyle(
+                      color: subtle,
+                      fontSize: 11,
+                      fontWeight: FontWeight.w700,
+                    ),
+                  ),
+                ),
+                CupertinoButton(
+                  key: Key(
+                    'environment-studio-palette-draft-remove-${widget.index}',
+                  ),
+                  padding:
+                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
+                  minimumSize: Size.zero,
+                  onPressed: widget.onRemove,
+                  child: const Text('Retirer'),
+                ),
+              ],
+            ),
+            const SizedBox(height: 8),
+            Text(
+              'Element id',
+              style: TextStyle(
+                color: subtle,
+                fontSize: 11,
+                fontWeight: FontWeight.w700,
+              ),
+            ),
+            const SizedBox(height: 4),
+            CupertinoTextField(
+              key: Key(
+                'environment-studio-palette-draft-element-${widget.index}',
+              ),
+              controller: _elementIdCtrl,
+              placeholder: 'Identifiant d’élément',
+              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
+              onChanged: (v) => _emit(elementId: v),
+            ),
+            const SizedBox(height: 10),
+            Text(
+              'Poids',
+              style: TextStyle(
+                color: subtle,
+                fontSize: 11,
+                fontWeight: FontWeight.w700,
+              ),
+            ),
+            const SizedBox(height: 4),
+            CupertinoTextField(
+              key: Key(
+                'environment-studio-palette-draft-weight-${widget.index}',
+              ),
+              controller: _weightCtrl,
+              placeholder: '1',
+              keyboardType: TextInputType.number,
+              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
+              onChanged: (raw) {
+                final t = raw.trim();
+                if (t.isEmpty) {
+                  return;
+                }
+                final parsed = int.tryParse(t);
+                if (parsed == null) {
+                  return;
+                }
+                _emit(weight: parsed);
+              },
+            ),
+            const SizedBox(height: 10),
+            Text(
+              'Collision',
+              style: TextStyle(
+                color: subtle,
+                fontSize: 11,
+                fontWeight: FontWeight.w700,
+              ),
+            ),
+            const SizedBox(height: 6),
+            SizedBox(
+              width: double.infinity,
+              child: CupertinoSlidingSegmentedControl<int>(
+                key: Key(
+                  'environment-studio-palette-draft-collision-${widget.index}',
+                ),
+                groupValue: seg,
+                children: {
+                  0: Padding(
+                    padding: const EdgeInsets.symmetric(vertical: 8),
+                    child: Text(
+                      'Défaut élément',
+                      textAlign: TextAlign.center,
+                      style: TextStyle(fontSize: 11, color: label),
+                    ),
+                  ),
+                  1: Padding(
+                    padding: const EdgeInsets.symmetric(vertical: 8),
+                    child: Text(
+                      'Collision forcée',
+                      textAlign: TextAlign.center,
+                      style: TextStyle(fontSize: 11, color: label),
+                    ),
+                  ),
+                  2: Padding(
+                    padding: const EdgeInsets.symmetric(vertical: 8),
+                    child: Text(
+                      'Collision désactivée',
+                      textAlign: TextAlign.center,
+                      style: TextStyle(fontSize: 11, color: label),
+                    ),
+                  ),
+                },
+                onValueChanged: (v) {
+                  if (v == null) {
+                    return;
+                  }
+                  _emit(collisionMode: _segmentToCollision(v));
+                },
+              ),
+            ),
+            const SizedBox(height: 10),
+            Text(
+              'Tags',
+              style: TextStyle(
+                color: subtle,
+                fontSize: 11,
+                fontWeight: FontWeight.w700,
+              ),
+            ),
+            const SizedBox(height: 4),
+            CupertinoTextField(
+              key: Key(
+                'environment-studio-palette-draft-tags-${widget.index}',
+              ),
+              controller: _tagsCtrl,
+              placeholder: 'tree, canopy',
+              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
+              onChanged: (v) => _emit(tags: _fieldToTags(v)),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}

```

#### `packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart`

```diff
+import 'package:flutter/cupertino.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:macos_ui/macos_ui.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';
+
+void main() {
+  group('EnvironmentStudioPanel — palette brouillon (Lot 14)', () {
+    testWidgets(
+        'ajouter un item : emptyPalette disparaît, emptyPaletteElementId',
+        (tester) async {
+      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      expect(
+        _validationHas(tester, 'Palette vide'),
+        isTrue,
+      );
+
+      await tester.tap(
+        find.byKey(const Key('environment-studio-draft-palette-add-item')),
+      );
+      await tester.pumpAndSettle();
+
+      expect(
+        _validationHas(tester, 'Palette vide'),
+        isFalse,
+      );
+      expect(
+        _validationHas(tester, 'Élément de palette vide'),
+        isTrue,
+      );
+      expect(
+        find.byKey(const Key('environment-studio-palette-draft-item-0')),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets(
+        'elementId connu : plus d’emptyPaletteElementId ni missingPaletteElement',
+        (tester) async {
+      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      await tester.tap(
+        find.byKey(const Key('environment-studio-draft-palette-add-item')),
+      );
+      await tester.pumpAndSettle();
+
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-palette-draft-element-0')),
+        'elm',
+      );
+      await tester.pumpAndSettle();
+
+      expect(
+        _validationHas(tester, 'Élément de palette vide'),
+        isFalse,
+      );
+      expect(
+        _validationHas(tester, 'Élément introuvable'),
+        isFalse,
+      );
+    });
+
+    testWidgets('elementId absent : Élément introuvable', (tester) async {
+      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      await tester.tap(
+        find.byKey(const Key('environment-studio-draft-palette-add-item')),
+      );
+      await tester.pumpAndSettle();
+
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-palette-draft-element-0')),
+        'inconnu_xyz',
+      );
+      await tester.pumpAndSettle();
+
+      expect(
+        _validationHas(tester, 'Élément introuvable'),
+        isTrue,
+      );
+    });
+
+    testWidgets(
+        'poids 3 valide, poids 0 invalide, texte non numérique inchangé',
+        (tester) async {
+      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      await tester.tap(
+        find.byKey(const Key('environment-studio-draft-palette-add-item')),
+      );
+      await tester.pumpAndSettle();
+
+      final w =
+          find.byKey(const Key('environment-studio-palette-draft-weight-0'));
+
+      await tester.enterText(w, '3');
+      await tester.pumpAndSettle();
+      expect(
+        _validationHas(tester, 'Poids invalide'),
+        isFalse,
+      );
+
+      await tester.enterText(w, '0');
+      await tester.pumpAndSettle();
+      expect(
+        _validationHas(tester, 'Poids invalide'),
+        isTrue,
+      );
+
+      await tester.enterText(w, '5');
+      await tester.pumpAndSettle();
+      expect(
+        _validationHas(tester, 'Poids invalide'),
+        isFalse,
+      );
+
+      await tester.enterText(w, 'not_int');
+      await tester.pumpAndSettle();
+      expect(
+        (tester.widget<CupertinoTextField>(w)).controller?.text,
+        'not_int',
+      );
+      expect(
+        _validationHas(tester, 'Poids invalide'),
+        isFalse,
+      );
+    });
+
+    testWidgets(
+        'collision : bascule Collision forcée puis Collision désactivée',
+        (tester) async {
+      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      await tester.tap(
+        find.byKey(const Key('environment-studio-draft-palette-add-item')),
+      );
+      await tester.pumpAndSettle();
+
+      expect(find.text('Défaut élément'), findsWidgets);
+
+      await tester.tap(find.text('Collision forcée').last);
+      await tester.pumpAndSettle();
+
+      await tester.tap(find.text('Collision désactivée').last);
+      await tester.pumpAndSettle();
+    });
+
+    testWidgets('tags : tree, canopy OK ; tree, , canopy → Tag vide', (
+      tester,
+    ) async {
+      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      await tester.tap(
+        find.byKey(const Key('environment-studio-draft-palette-add-item')),
+      );
+      await tester.pumpAndSettle();
+
+      final tags =
+          find.byKey(const Key('environment-studio-palette-draft-tags-0'));
+
+      await tester.enterText(tags, 'tree, canopy');
+      await tester.pumpAndSettle();
+      expect(
+        _validationHas(tester, 'Tag vide'),
+        isFalse,
+      );
+
+      await tester.enterText(tags, 'tree, , canopy');
+      await tester.pumpAndSettle();
+      expect(
+        _validationHas(tester, 'Tag vide'),
+        isTrue,
+      );
+    });
+
+    testWidgets('Retirer : palette vide, emptyPalette revient', (tester) async {
+      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      await tester.tap(
+        find.byKey(const Key('environment-studio-draft-palette-add-item')),
+      );
+      await tester.pumpAndSettle();
+
+      expect(
+        _validationHas(tester, 'Palette vide'),
+        isFalse,
+      );
+
+      await tester.ensureVisible(
+        find.byKey(const Key('environment-studio-palette-draft-remove-0')),
+      );
+      await tester.pumpAndSettle();
+      await tester.tap(
+        find.byKey(const Key('environment-studio-palette-draft-remove-0')),
+      );
+      await tester.pumpAndSettle();
+
+      expect(
+        find.byKey(const Key('environment-studio-draft-palette-no-items')),
+        findsOneWidget,
+      );
+      expect(
+        _validationHas(tester, 'Palette vide'),
+        isTrue,
+      );
+    });
+
+    testWidgets('deux items même elementId : Élément dupliqué', (tester) async {
+      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      await tester.tap(
+        find.byKey(const Key('environment-studio-draft-palette-add-item')),
+      );
+      await tester.pumpAndSettle();
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-palette-draft-element-0')),
+        'elm',
+      );
+      await tester.pumpAndSettle();
+
+      await tester.tap(
+        find.byKey(const Key('environment-studio-draft-palette-add-item')),
+      );
+      await tester.pumpAndSettle();
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-palette-draft-element-1')),
+        'elm',
+      );
+      await tester.pumpAndSettle();
+
+      expect(
+        _validationHas(tester, 'Élément dupliqué'),
+        isTrue,
+      );
+    });
+
+    testWidgets(
+        'édition palette + retour browser : manifest.environmentPresets inchangé',
+        (tester) async {
+      final manifest = _manifest(
+        environmentPresets: [
+          _preset(id: 'keep'),
+        ],
+        elements: [_element(id: 'elm')],
+      );
+      final idsBefore =
+          manifest.environmentPresets.map((p) => p.id).toList(growable: false);
+
+      await _pump(tester, manifest);
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      await tester.tap(
+        find.byKey(const Key('environment-studio-draft-palette-add-item')),
+      );
+      await tester.pumpAndSettle();
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-palette-draft-element-0')),
+        'elm',
+      );
+      await tester.pumpAndSettle();
+
+      await tester.ensureVisible(
+        find.byKey(const Key('environment-studio-draft-cancel')),
+      );
+      await tester.pumpAndSettle();
+      await tester
+          .tap(find.byKey(const Key('environment-studio-draft-cancel')));
+      await tester.pumpAndSettle();
+
+      expect(
+        manifest.environmentPresets.map((p) => p.id).toList(growable: false),
+        idsBefore,
+      );
+      expect(manifest.environmentPresets.length, 1);
+    });
+  });
+}
+
+bool _validationHas(WidgetTester tester, String substring) {
+  final matches = find.descendant(
+    of: find.byKey(const Key('environment-studio-draft-validation-root')),
+    matching: find.textContaining(substring),
+  );
+  return matches.evaluate().isNotEmpty;
+}
+
+Future<void> _pump(WidgetTester tester, ProjectManifest manifest) async {
+  tester.view.physicalSize = const Size(900, 2200);
+  tester.view.devicePixelRatio = 1.0;
+  addTearDown(() {
+    tester.view.resetPhysicalSize();
+    tester.view.resetDevicePixelRatio();
+  });
+  await tester.pumpWidget(
+    MacosApp(
+      home: CupertinoPageScaffold(
+        child: EnvironmentStudioPanel(manifest: manifest),
+      ),
+    ),
+  );
+  await tester.pumpAndSettle();
+}
+
+ProjectManifest _manifest({
+  List<EnvironmentPreset> environmentPresets = const [],
+  List<ProjectElementEntry> elements = const [],
+}) {
+  return ProjectManifest(
+    name: 'palette-draft-test',
+    maps: const [],
+    tilesets: const [],
+    environmentPresets: environmentPresets,
+    elements: elements,
+    surfaceCatalog: ProjectSurfaceCatalog(),
+  );
+}
+
+EnvironmentPreset _preset({required String id}) {
+  return EnvironmentPreset(
+    id: id,
+    name: 'P $id',
+    templateId: 'tpl',
+    palette: [
+      EnvironmentPaletteItem(elementId: 'elm', weight: 1),
+    ],
+    defaultParams: EnvironmentGenerationParams.standard(),
+    sortOrder: 0,
+  );
+}
+
+ProjectElementEntry _element({required String id}) {
+  return ProjectElementEntry(
+    id: id,
+    name: 'El $id',
+    tilesetId: 'ts',
+    categoryId: 'cat',
+    frames: const [
+      TilesetVisualFrame(
+        source: TilesetSourceRect(x: 0, y: 0),
+      ),
+    ],
+  );
+}

```

## 16. Auto-review

- **Points solides** : contrôleurs isolés par item avec `dispose` ; poids non parseable sans mutation draft ; réutilisation validation existante ; tests couvrant doublon / missing / tag vide.
- **Points discutables** : libellé de champ « Element id » en style titre (cohérent avec spec EN) ; segments collision texte long sur petites largeurs.
- **Corrections faites après auto-review** : `dart format` sur les fichiers touchés.
- **Risques restants** : après saisie poids invalide affiché dans le champ, le brouillon reste sur l’ancien entier jusqu’à saisie valide (comportement demandé).
- **Regard critique sur le prompt** :
  - Champ texte `elementId` : suffisant V0 ; picker d’éléments = Lot ultérieur raisonnable.
  - Tags virgules : acceptable V0 ; internationalisation / UI riche plus tard.
  - Poids non parseable → conserver ancien : oui, aligné recommandation.
  - Sauvegarde / mutation manifest : respecté (tests + absence d’API persistance).

## 17. Verdict

Statut du lot :

- [x] Validé

Résumé :

```
Éditeur palette brouillon + 9 tests dédiés ; 77 tests test/environment_studio verts ; analyze sans issue ; flutter test map_editor complet +910 -34 (dette préexistante hors lot, sync items catalog).
```

Prochain lot recommandé :

```
Environment-15 — Environment Preset Generation Params Draft Editor V0
```
