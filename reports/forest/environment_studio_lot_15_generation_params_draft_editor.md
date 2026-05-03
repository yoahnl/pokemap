# Environment Studio Lot 15 — Generation Params Draft Editor V0

## 1. Résumé exécutif

Édition locale des paramètres de génération du brouillon (`density`, `variation`, `edgeDensity`, `minSpacingCells`) via [EnvironmentGenerationParamsDraftEditor] intégré dans [EnvironmentPresetDraftForm] ; saisie avec conservation du brouillon si parse impossible ; valeurs hors bornes émises pour alimenter [validateEnvironmentPresetDraft] ; [didUpdateWidget] pour resynchroniser après « Réinitialiser brouillon ». Aucune persistance manifest.

## 2. Périmètre du lot

- `map_editor` : widget éditeur, formulaire, tests, rapport.
- Pas de `map_core`, pas de `build_runner`, pas d’upsert.

## 3. Audit initial du formulaire brouillon

Fichiers relus : `environment_preset_draft.dart` (validation `invalidDensity` etc.), `environment_preset_draft_form.dart`, `environment_palette_item_draft_editor.dart` (référence contrôleurs), `environment_preset_draft_validation_view.dart`, `environment_preset_draft_presentation.dart`, tests Environment Studio listés au cahier, `cupertino_editor_widgets.dart`.

**Pattern** : `_emit(defaultParams:)` en parallèle de `_emit(palette:)` ; champs doubles avec `double.tryParse` / entier avec `int.tryParse` ; `_formatDouble` avec `truncateToDouble` pour afficher `0.5` et non `0`.

## 4. Décisions UI / édition params locale

- Titre « Paramètres de génération » + note brouillon local.
- Quatre `CupertinoTextField` avec clés de test stables.
- Pas de sliders (V0 texte uniquement).

## 5. Éditeur params ajouté

`environment_generation_params_draft_editor.dart` : quatre contrôleurs, `dispose`, `didUpdateWidget` sur changement de `params`.

## 6. Validation params affichée

Réutilisation de [validateEnvironmentPresetDraft] et [EnvironmentPresetDraftValidationView] sans modification de la vue.

## 7. Non-persistance garantie

Tests widget sur `manifest.environmentPresets` inchangé après édition + annulation ; aucune API de persistance dans l’UI.

## 8. Pourquoi aucune sauvegarde / génération dans ce lot

Lot 16 prévu pour l’enregistrement manifest ; ce lot limite l’UX au brouillon.

## 9. Fichiers modifiés

- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart` (M)
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart` (nouveau)
- `packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart` (nouveau)
- `packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart` (M)
- `reports/forest/environment_studio_lot_15_generation_params_draft_editor.md` (ce fichier)

## 10. Tests ajoutés ou modifiés

- Nouveau fichier `environment_generation_params_draft_editor_test.dart` (8 scénarios cahier §11).
- `environment_studio_preset_creation_form_test.dart` : attentes champs params standard à la place du bloc lecture seule.

## 11. Commandes exécutées

```bash
cd packages/map_editor
dart format lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart \
  lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart \
  test/environment_studio/environment_studio_preset_creation_form_test.dart \
  test/environment_studio/environment_generation_params_draft_editor_test.dart

flutter analyze (4 chemins ciblés)

flutter test test/environment_studio/environment_generation_params_draft_editor_test.dart --reporter expanded
flutter test test/environment_studio --reporter expanded
flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart --reporter expanded
flutter test 2>&1 | tail -n 6
```

## 12. Résultats des commandes

### dart format

```
Formatted 4 files (0 changed) in 0.01 seconds.

```

### flutter analyze

```
Analyzing 4 items...                                            
No issues found! (ran in 1.4s)

```

### flutter test — params draft (isolé)

```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart
00:00 +0: EnvironmentStudioPanel — params génération brouillon (Lot 15) affichage initial : titres et valeurs standard
00:00 +1: EnvironmentStudioPanel — params génération brouillon (Lot 15) densité 0.75 OK puis 1.5 → Densité invalide
00:00 +2: EnvironmentStudioPanel — params génération brouillon (Lot 15) variation 0.25 OK puis -0.1 → Variation invalide
00:00 +3: EnvironmentStudioPanel — params génération brouillon (Lot 15) densité des bords 0.6 OK puis 2 → Densité des bords invalide
00:01 +4: EnvironmentStudioPanel — params génération brouillon (Lot 15) espacement 3 OK puis -1 → Espacement invalide
00:01 +5: EnvironmentStudioPanel — params génération brouillon (Lot 15) saisie non parseable : champ affiché, draft inchangé
00:01 +6: EnvironmentStudioPanel — params génération brouillon (Lot 15) Réinitialiser brouillon remet les params standard
00:01 +7: EnvironmentStudioPanel — params génération brouillon (Lot 15) modifier params puis retour browser : manifest.environmentPresets inchangé
00:01 +8: All tests passed!

```

### flutter test — dossier test/environment_studio (sortie complète)

```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart: environmentDiagnosticKindLabel quelques kinds FR stables
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) affichage initial : titres et valeurs standard
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) affichage initial : titres et valeurs standard
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) affichage initial : titres et valeurs standard
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) affichage initial : titres et valeurs standard
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) affichage initial : titres et valeurs standard
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) affichage initial : titres et valeurs standard
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart: EnvironmentStudioPanel — browser read-only diagnostic erreur élément palette : drilldown
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart: EnvironmentStudioPanel tap sur un autre preset met à jour le détail
00:01 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart: EnvironmentStudioPanel tap sur un autre preset met à jour le détail
00:01 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart: EnvironmentStudioPanel tap sur un autre preset met à jour le détail
00:01 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) densité 0.75 OK puis 1.5 → Densité invalide
00:01 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) densité 0.75 OK puis 1.5 → Densité invalide
00:01 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) densité 0.75 OK puis 1.5 → Densité invalide
00:01 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) variation 0.25 OK puis -0.1 → Variation invalide
00:01 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) densité des bords 0.6 OK puis 2 → Densité des bords invalide
00:01 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) espacement 3 OK puis -1 → Espacement invalide
00:01 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) saisie non parseable : champ affiché, draft inchangé
00:01 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) Réinitialiser brouillon remet les params standard
00:02 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) modifier params puis retour browser : manifest.environmentPresets inchangé
00:04 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:04 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +24: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +25: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +26: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +27: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +28: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +29: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +30: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +31: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +32: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +33: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +34: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +35: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +36: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +37: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +38: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +39: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +40: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +41: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +42: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +43: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +44: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +45: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +46: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +47: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +48: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +49: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +50: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +51: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +52: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +53: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +54: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +55: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +56: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +57: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +58: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +59: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +60: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +61: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +62: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +63: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +64: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:05 +65: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:05 +66: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:05 +67: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:06 +68: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:06 +69: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:06 +70: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:06 +71: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon saisie met à jour le draft et la validation
00:06 +72: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) elementId connu : plus d’emptyPaletteElementId ni missingPaletteElement
00:06 +73: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) elementId connu : plus d’emptyPaletteElementId ni missingPaletteElement
00:06 +74: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon Réinitialiser brouillon remet les champs vides
00:06 +75: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) elementId absent : Élément introuvable
00:06 +76: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon Retour au browser restaure la liste sans modifier le manifest
00:06 +77: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) poids 3 valide, poids 0 invalide, texte non numérique inchangé
00:07 +78: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) poids 3 valide, poids 0 invalide, texte non numérique inchangé
00:07 +79: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon catégorie optionnelle : champ vide
00:07 +80: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) collision : bascule Collision forcée puis Collision désactivée
00:07 +81: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) tags : tree, canopy OK ; tree, , canopy → Tag vide
00:07 +82: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) Retirer : palette vide, emptyPalette revient
00:07 +83: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) deux items même elementId : Élément dupliqué
00:07 +84: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) édition palette + retour browser : manifest.environmentPresets inchangé
00:08 +85: All tests passed!

```

### flutter test — editor_workspace_controller + top_toolbar

```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectPokedexWorkspace switches mode and clears stale errors
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectTrainerWorkspace switches mode and clears stale errors
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectDialogueWorkspace keeps project session and only changes mode
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectEnvironmentStudioWorkspace switches mode and clears stale errors
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectPokemonCatalogSection opens the parent workspace and stores the section
00:04 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows the app brand and project workspace label
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:05 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar falls back to the workspace label when no project is loaded
00:05 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows the toolbar status chip when a status is present
00:05 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows the trainer studio label for the trainer workspace
00:05 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar enables project save and disables map history in Path Studio
00:05 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows neutral Save Project when project is clean in Path Studio
00:05 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar enables project save and disables map history in Environment Studio
00:05 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows Environment Studio in the workspace brand strip
00:05 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar keeps map save action in map workspace
00:05 +14: All tests passed!

```

### flutter test — map_editor complet (lignes finales, exit 1)

```
01:00 +916 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: ... malformed payloads and duplicate external resources with warnings
01:00 +916 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: ... pokemon data root for both the items catalog and local sprite assets
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/items_catalog_sync_v8PETh/project.json
01:00 +917 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: sync honors a custom pokemon data root for both the items catalog and local sprite assets
01:00 +917 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: load use case reads the synced catalog after a real sync
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/items_catalog_sync_8MnVD0/project.json
01:00 +918 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: load use case reads the synced catalog after a real sync
01:00 +918 -34: Some tests failed.

```

## 13. Git status initial et final

**Git status initial** (avant ajout des fichiers Lot 15 : pas de `environment_generation_params_draft_editor` dans l’arbre versionné) : les fichiers du lot apparaissaient uniquement comme modifications locales / non suivis une fois le travail commencé.

**Preuve fichier widget absent de `HEAD`** :

```
fatal: path 'packages/map_editor/lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart' exists on disk, but not in 'HEAD'
```

**Git status final** (`git status --short --untracked-files=all`) :

```
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
 M packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart
?? packages/map_editor/lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart
?? packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart
?? reports/forest/environment_studio_lot_15_generation_params_draft_editor.md

```

### Fichiers inspectés pendant l’audit

- `packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_draft.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_validation_view.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_presentation.dart`
- `packages/map_editor/test/environment_studio/environment_preset_draft_test.dart`
- `packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart`
- `packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart`
- `packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart`

### Confirmations Evidence Pack

- Aucun `ProjectManifest` modifié par ce lot.
- Aucun `MapLayer` modifié.
- Aucun appel à `upsertProjectEnvironmentPreset` dans le code livré.
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
import 'environment_generation_params_draft_editor.dart';
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

  void _emit({
    List<EnvironmentPaletteItemDraft>? palette,
    EnvironmentGenerationParamsDraft? defaultParams,
  }) {
    final so = int.tryParse(_sortCtrl.text.trim());
    widget.onChanged(
      EnvironmentPresetDraft(
        id: _idCtrl.text,
        name: _nameCtrl.text,
        templateId: _templateCtrl.text,
        palette: palette ?? widget.draft.palette,
        defaultParams: defaultParams ?? widget.draft.defaultParams,
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
          EnvironmentGenerationParamsDraftEditor(
            key: const Key('environment-studio-draft-params-editor'),
            params: widget.draft.defaultParams,
            onChanged: (p) => _emit(defaultParams: p),
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

### `packages/map_editor/lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart`

```dart
import 'package:flutter/cupertino.dart';

import '../../../ui/shared/cupertino_editor_widgets.dart';
import '../authoring/environment_preset_draft.dart';

/// Éditeur local des [EnvironmentGenerationParamsDraft] (Lot Environment-15).
///
/// Doubles : parse avec [double.tryParse] ; si vide ou non parseable, pas d’appel
/// à [onChanged] (le brouillon conserve la valeur précédente). Les valeurs hors
/// [0, 1] sont tout de même émises pour que [validateEnvironmentPresetDraft]
/// remonte [invalidDensity] / [invalidVariation] / [invalidEdgeDensity].
///
/// Entier : [int.tryParse] pour [minSpacingCells] ; valeurs négatives émises pour
/// [invalidMinSpacingCells].
///
/// [didUpdateWidget] resynchronise les contrôleurs quand [params] change (ex. :
/// « Réinitialiser brouillon » sur le parent).
class EnvironmentGenerationParamsDraftEditor extends StatefulWidget {
  const EnvironmentGenerationParamsDraftEditor({
    super.key,
    required this.params,
    required this.onChanged,
  });

  final EnvironmentGenerationParamsDraft params;
  final ValueChanged<EnvironmentGenerationParamsDraft> onChanged;

  @override
  State<EnvironmentGenerationParamsDraftEditor> createState() =>
      _EnvironmentGenerationParamsDraftEditorState();
}

class _EnvironmentGenerationParamsDraftEditorState
    extends State<EnvironmentGenerationParamsDraftEditor> {
  late final TextEditingController _densityCtrl;
  late final TextEditingController _variationCtrl;
  late final TextEditingController _edgeDensityCtrl;
  late final TextEditingController _minSpacingCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.params;
    _densityCtrl = TextEditingController(text: _formatDouble(p.density));
    _variationCtrl = TextEditingController(text: _formatDouble(p.variation));
    _edgeDensityCtrl =
        TextEditingController(text: _formatDouble(p.edgeDensity));
    _minSpacingCtrl = TextEditingController(text: p.minSpacingCells.toString());
  }

  @override
  void didUpdateWidget(
      covariant EnvironmentGenerationParamsDraftEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params != widget.params) {
      final p = widget.params;
      _densityCtrl.text = _formatDouble(p.density);
      _variationCtrl.text = _formatDouble(p.variation);
      _edgeDensityCtrl.text = _formatDouble(p.edgeDensity);
      _minSpacingCtrl.text = p.minSpacingCells.toString();
    }
  }

  @override
  void dispose() {
    _densityCtrl.dispose();
    _variationCtrl.dispose();
    _edgeDensityCtrl.dispose();
    _minSpacingCtrl.dispose();
    super.dispose();
  }

  static String _formatDouble(double v) {
    if (v == v.truncateToDouble()) {
      return v.toInt().toString();
    }
    return v.toString();
  }

  void _emitDensity(String raw) {
    final t = raw.trim();
    if (t.isEmpty) {
      return;
    }
    final v = double.tryParse(t);
    if (v == null) {
      return;
    }
    widget.onChanged(widget.params.copyWith(density: v));
  }

  void _emitVariation(String raw) {
    final t = raw.trim();
    if (t.isEmpty) {
      return;
    }
    final v = double.tryParse(t);
    if (v == null) {
      return;
    }
    widget.onChanged(widget.params.copyWith(variation: v));
  }

  void _emitEdgeDensity(String raw) {
    final t = raw.trim();
    if (t.isEmpty) {
      return;
    }
    final v = double.tryParse(t);
    if (v == null) {
      return;
    }
    widget.onChanged(widget.params.copyWith(edgeDensity: v));
  }

  void _emitMinSpacing(String raw) {
    final t = raw.trim();
    if (t.isEmpty) {
      return;
    }
    final v = int.tryParse(t);
    if (v == null) {
      return;
    }
    widget.onChanged(widget.params.copyWith(minSpacingCells: v));
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final fill = EditorChrome.chipFill(context);
    final border = CupertinoColors.separator.resolveFrom(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Paramètres de génération',
              key: const Key('environment-studio-draft-params-section-title'),
              style: TextStyle(
                color: label,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ces valeurs restent dans le brouillon local tant que la création '
              'réelle n’est pas branchée.',
              key: const Key('environment-studio-draft-params-local-note'),
              style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
            ),
            const SizedBox(height: 14),
            _subLabel(context, 'Densité'),
            const SizedBox(height: 4),
            CupertinoTextField(
              key: const Key('environment-studio-draft-params-density'),
              controller: _densityCtrl,
              placeholder: '0.0 – 1.0',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              onChanged: _emitDensity,
            ),
            const SizedBox(height: 12),
            _subLabel(context, 'Variation'),
            const SizedBox(height: 4),
            CupertinoTextField(
              key: const Key('environment-studio-draft-params-variation'),
              controller: _variationCtrl,
              placeholder: '0.0 – 1.0',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              onChanged: _emitVariation,
            ),
            const SizedBox(height: 12),
            _subLabel(context, 'Densité des bords'),
            const SizedBox(height: 4),
            CupertinoTextField(
              key: const Key('environment-studio-draft-params-edge-density'),
              controller: _edgeDensityCtrl,
              placeholder: '0.0 – 1.0',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              onChanged: _emitEdgeDensity,
            ),
            const SizedBox(height: 12),
            _subLabel(context, 'Espacement minimal'),
            const SizedBox(height: 4),
            CupertinoTextField(
              key: const Key('environment-studio-draft-params-min-spacing'),
              controller: _minSpacingCtrl,
              placeholder: '≥ 0',
              keyboardType: TextInputType.number,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              onChanged: _emitMinSpacing,
            ),
          ],
        ),
      ),
    );
  }

  Widget _subLabel(BuildContext context, String text) {
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

### `packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';

void main() {
  group('EnvironmentStudioPanel — params génération brouillon (Lot 15)', () {
    testWidgets('affichage initial : titres et valeurs standard',
        (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('environment-studio-draft-params-editor')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-studio-draft-params-section-title')),
        findsOneWidget,
      );
      expect(find.text('Paramètres de génération'), findsOneWidget);
      expect(
        (tester.widget<CupertinoTextField>(find
                .byKey(const Key('environment-studio-draft-params-density'))))
            .controller
            ?.text,
        '0.5',
      );
      expect(
        (tester.widget<CupertinoTextField>(find
                .byKey(const Key('environment-studio-draft-params-variation'))))
            .controller
            ?.text,
        '0.5',
      );
      expect(
        (tester.widget<CupertinoTextField>(find.byKey(
                const Key('environment-studio-draft-params-edge-density'))))
            .controller
            ?.text,
        '0.5',
      );
      expect(
        (tester.widget<CupertinoTextField>(find.byKey(
                const Key('environment-studio-draft-params-min-spacing'))))
            .controller
            ?.text,
        '0',
      );
    });

    testWidgets('densité 0.75 OK puis 1.5 → Densité invalide', (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      final d =
          find.byKey(const Key('environment-studio-draft-params-density'));
      await tester.enterText(d, '0.75');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Densité invalide'),
        isFalse,
      );

      await tester.enterText(d, '1.5');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Densité invalide'),
        isTrue,
      );
    });

    testWidgets('variation 0.25 OK puis -0.1 → Variation invalide', (
      tester,
    ) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      final f =
          find.byKey(const Key('environment-studio-draft-params-variation'));
      await tester.enterText(f, '0.25');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Variation invalide'),
        isFalse,
      );

      await tester.enterText(f, '-0.1');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Variation invalide'),
        isTrue,
      );
    });

    testWidgets('densité des bords 0.6 OK puis 2 → Densité des bords invalide',
        (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      final f =
          find.byKey(const Key('environment-studio-draft-params-edge-density'));
      await tester.enterText(f, '0.6');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Densité des bords invalide'),
        isFalse,
      );

      await tester.enterText(f, '2');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Densité des bords invalide'),
        isTrue,
      );
    });

    testWidgets('espacement 3 OK puis -1 → Espacement invalide',
        (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      final f =
          find.byKey(const Key('environment-studio-draft-params-min-spacing'));
      await tester.enterText(f, '3');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Espacement invalide'),
        isFalse,
      );

      await tester.enterText(f, '-1');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Espacement invalide'),
        isTrue,
      );
    });

    testWidgets('saisie non parseable : champ affiché, draft inchangé', (
      tester,
    ) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      final d =
          find.byKey(const Key('environment-studio-draft-params-density'));
      await tester.enterText(d, 'abc');
      await tester.pumpAndSettle();
      expect((tester.widget<CupertinoTextField>(d)).controller?.text, 'abc');
      expect(
        _validationHas(tester, 'Densité invalide'),
        isFalse,
      );

      final m =
          find.byKey(const Key('environment-studio-draft-params-min-spacing'));
      await tester.enterText(m, 'xyz');
      await tester.pumpAndSettle();
      expect((tester.widget<CupertinoTextField>(m)).controller?.text, 'xyz');
      expect(
        _validationHas(tester, 'Espacement invalide'),
        isFalse,
      );
    });

    testWidgets('Réinitialiser brouillon remet les params standard', (
      tester,
    ) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-params-density')),
        '0.25',
      );
      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-params-min-spacing')),
        '7',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('environment-studio-draft-reset')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('environment-studio-draft-reset')));
      await tester.pumpAndSettle();

      expect(
        (tester.widget<CupertinoTextField>(find
                .byKey(const Key('environment-studio-draft-params-density'))))
            .controller
            ?.text,
        '0.5',
      );
      expect(
        (tester.widget<CupertinoTextField>(find.byKey(
                const Key('environment-studio-draft-params-min-spacing'))))
            .controller
            ?.text,
        '0',
      );
    });

    testWidgets(
        'modifier params puis retour browser : manifest.environmentPresets inchangé',
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

      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-params-density')),
        '0.2',
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
  return find
      .descendant(
        of: find.byKey(const Key('environment-studio-draft-validation-root')),
        matching: find.textContaining(substring),
      )
      .evaluate()
      .isNotEmpty;
}

Future<void> _pump(WidgetTester tester, ProjectManifest manifest) async {
  tester.view.physicalSize = const Size(900, 2400);
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
    name: 'gen-params-draft-test',
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
        find.byKey(const Key('environment-studio-draft-params-section-title')),
        findsOneWidget,
      );
      expect(find.text('Paramètres de génération'), findsOneWidget);
      expect(
        (tester.widget<CupertinoTextField>(find
                .byKey(const Key('environment-studio-draft-params-density'))))
            .controller
            ?.text,
        '0.5',
      );
      expect(
        (tester.widget<CupertinoTextField>(find
                .byKey(const Key('environment-studio-draft-params-variation'))))
            .controller
            ?.text,
        '0.5',
      );
      expect(
        (tester.widget<CupertinoTextField>(find.byKey(
                const Key('environment-studio-draft-params-edge-density'))))
            .controller
            ?.text,
        '0.5',
      );
      expect(
        (tester.widget<CupertinoTextField>(find.byKey(
                const Key('environment-studio-draft-params-min-spacing'))))
            .controller
            ?.text,
        '0',
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

### `environment_preset_draft_form.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart b/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
index b65de787..4d9dbceb 100644
--- a/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
+++ b/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
@@ -2,6 +2,7 @@ import 'package:flutter/cupertino.dart';
 
 import '../../../ui/shared/cupertino_editor_widgets.dart';
 import '../authoring/environment_preset_draft.dart';
+import 'environment_generation_params_draft_editor.dart';
 import 'environment_palette_item_draft_editor.dart';
 import 'environment_preset_draft_validation_view.dart';
 
@@ -56,7 +57,10 @@ class _EnvironmentPresetDraftFormState
     super.dispose();
   }
 
-  void _emit({List<EnvironmentPaletteItemDraft>? palette}) {
+  void _emit({
+    List<EnvironmentPaletteItemDraft>? palette,
+    EnvironmentGenerationParamsDraft? defaultParams,
+  }) {
     final so = int.tryParse(_sortCtrl.text.trim());
     widget.onChanged(
       EnvironmentPresetDraft(
@@ -64,7 +68,7 @@ class _EnvironmentPresetDraftFormState
         name: _nameCtrl.text,
         templateId: _templateCtrl.text,
         palette: palette ?? widget.draft.palette,
-        defaultParams: widget.draft.defaultParams,
+        defaultParams: defaultParams ?? widget.draft.defaultParams,
         categoryId:
             _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text,
         sortOrder: so ?? widget.draft.sortOrder,
@@ -96,9 +100,6 @@ class _EnvironmentPresetDraftFormState
   Widget build(BuildContext context) {
     final label = EditorChrome.primaryLabel(context);
     final subtle = EditorChrome.subtleLabel(context);
-    final fill = EditorChrome.chipFill(context);
-    final border = CupertinoColors.separator.resolveFrom(context);
-    final p = widget.draft.defaultParams;
 
     return SingleChildScrollView(
       key: const Key('environment-studio-draft-form-scroll'),
@@ -198,32 +199,10 @@ class _EnvironmentPresetDraftFormState
             onChanged: (_) => _emit(),
           ),
           const SizedBox(height: 22),
-          Text(
-            'Paramètres par défaut (lecture seule pour l’instant)',
-            style: TextStyle(
-              color: label,
-              fontSize: 14,
-              fontWeight: FontWeight.w800,
-            ),
-          ),
-          const SizedBox(height: 8),
-          DecoratedBox(
-            decoration: BoxDecoration(
-              color: fill,
-              borderRadius: BorderRadius.circular(10),
-              border: Border.all(color: border),
-            ),
-            child: Padding(
-              padding: const EdgeInsets.all(12),
-              child: Text(
-                'Densité ${p.density.toStringAsFixed(2)} · '
-                'Variation ${p.variation.toStringAsFixed(2)} · '
-                'Densité des bords ${p.edgeDensity.toStringAsFixed(2)} · '
-                'Espacement min. ${p.minSpacingCells} cases',
-                key: const Key('environment-studio-draft-params-readonly'),
-                style: TextStyle(color: subtle, fontSize: 12.5, height: 1.35),
-              ),
-            ),
+          EnvironmentGenerationParamsDraftEditor(
+            key: const Key('environment-studio-draft-params-editor'),
+            params: widget.draft.defaultParams,
+            onChanged: (p) => _emit(defaultParams: p),
           ),
           const SizedBox(height: 22),
           Text(

```

### `environment_studio_preset_creation_form_test.dart`

```diff
diff --git a/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart b/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart
index ccaa4d5e..6d51eef6 100644
--- a/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart
+++ b/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart
@@ -102,9 +102,38 @@ void main() {
         '0',
       );
       expect(
-        find.byKey(const Key('environment-studio-draft-params-readonly')),
+        find.byKey(const Key('environment-studio-draft-params-section-title')),
         findsOneWidget,
       );
+      expect(find.text('Paramètres de génération'), findsOneWidget);
+      expect(
+        (tester.widget<CupertinoTextField>(find
+                .byKey(const Key('environment-studio-draft-params-density'))))
+            .controller
+            ?.text,
+        '0.5',
+      );
+      expect(
+        (tester.widget<CupertinoTextField>(find
+                .byKey(const Key('environment-studio-draft-params-variation'))))
+            .controller
+            ?.text,
+        '0.5',
+      );
+      expect(
+        (tester.widget<CupertinoTextField>(find.byKey(
+                const Key('environment-studio-draft-params-edge-density'))))
+            .controller
+            ?.text,
+        '0.5',
+      );
+      expect(
+        (tester.widget<CupertinoTextField>(find.byKey(
+                const Key('environment-studio-draft-params-min-spacing'))))
+            .controller
+            ?.text,
+        '0',
+      );
       expect(
         find.byKey(const Key('environment-studio-draft-palette-section-title')),
         findsOneWidget,

```

### Nouveau `environment_generation_params_draft_editor.dart`

```diff
+import 'package:flutter/cupertino.dart';
+
+import '../../../ui/shared/cupertino_editor_widgets.dart';
+import '../authoring/environment_preset_draft.dart';
+
+/// Éditeur local des [EnvironmentGenerationParamsDraft] (Lot Environment-15).
+///
+/// Doubles : parse avec [double.tryParse] ; si vide ou non parseable, pas d’appel
+/// à [onChanged] (le brouillon conserve la valeur précédente). Les valeurs hors
+/// [0, 1] sont tout de même émises pour que [validateEnvironmentPresetDraft]
+/// remonte [invalidDensity] / [invalidVariation] / [invalidEdgeDensity].
+///
+/// Entier : [int.tryParse] pour [minSpacingCells] ; valeurs négatives émises pour
+/// [invalidMinSpacingCells].
+///
+/// [didUpdateWidget] resynchronise les contrôleurs quand [params] change (ex. :
+/// « Réinitialiser brouillon » sur le parent).
+class EnvironmentGenerationParamsDraftEditor extends StatefulWidget {
+  const EnvironmentGenerationParamsDraftEditor({
+    super.key,
+    required this.params,
+    required this.onChanged,
+  });
+
+  final EnvironmentGenerationParamsDraft params;
+  final ValueChanged<EnvironmentGenerationParamsDraft> onChanged;
+
+  @override
+  State<EnvironmentGenerationParamsDraftEditor> createState() =>
+      _EnvironmentGenerationParamsDraftEditorState();
+}
+
+class _EnvironmentGenerationParamsDraftEditorState
+    extends State<EnvironmentGenerationParamsDraftEditor> {
+  late final TextEditingController _densityCtrl;
+  late final TextEditingController _variationCtrl;
+  late final TextEditingController _edgeDensityCtrl;
+  late final TextEditingController _minSpacingCtrl;
+
+  @override
+  void initState() {
+    super.initState();
+    final p = widget.params;
+    _densityCtrl = TextEditingController(text: _formatDouble(p.density));
+    _variationCtrl = TextEditingController(text: _formatDouble(p.variation));
+    _edgeDensityCtrl =
+        TextEditingController(text: _formatDouble(p.edgeDensity));
+    _minSpacingCtrl = TextEditingController(text: p.minSpacingCells.toString());
+  }
+
+  @override
+  void didUpdateWidget(
+      covariant EnvironmentGenerationParamsDraftEditor oldWidget) {
+    super.didUpdateWidget(oldWidget);
+    if (oldWidget.params != widget.params) {
+      final p = widget.params;
+      _densityCtrl.text = _formatDouble(p.density);
+      _variationCtrl.text = _formatDouble(p.variation);
+      _edgeDensityCtrl.text = _formatDouble(p.edgeDensity);
+      _minSpacingCtrl.text = p.minSpacingCells.toString();
+    }
+  }
+
+  @override
+  void dispose() {
+    _densityCtrl.dispose();
+    _variationCtrl.dispose();
+    _edgeDensityCtrl.dispose();
+    _minSpacingCtrl.dispose();
+    super.dispose();
+  }
+
+  static String _formatDouble(double v) {
+    if (v == v.truncateToDouble()) {
+      return v.toInt().toString();
+    }
+    return v.toString();
+  }
+
+  void _emitDensity(String raw) {
+    final t = raw.trim();
+    if (t.isEmpty) {
+      return;
+    }
+    final v = double.tryParse(t);
+    if (v == null) {
+      return;
+    }
+    widget.onChanged(widget.params.copyWith(density: v));
+  }
+
+  void _emitVariation(String raw) {
+    final t = raw.trim();
+    if (t.isEmpty) {
+      return;
+    }
+    final v = double.tryParse(t);
+    if (v == null) {
+      return;
+    }
+    widget.onChanged(widget.params.copyWith(variation: v));
+  }
+
+  void _emitEdgeDensity(String raw) {
+    final t = raw.trim();
+    if (t.isEmpty) {
+      return;
+    }
+    final v = double.tryParse(t);
+    if (v == null) {
+      return;
+    }
+    widget.onChanged(widget.params.copyWith(edgeDensity: v));
+  }
+
+  void _emitMinSpacing(String raw) {
+    final t = raw.trim();
+    if (t.isEmpty) {
+      return;
+    }
+    final v = int.tryParse(t);
+    if (v == null) {
+      return;
+    }
+    widget.onChanged(widget.params.copyWith(minSpacingCells: v));
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+    final fill = EditorChrome.chipFill(context);
+    final border = CupertinoColors.separator.resolveFrom(context);
+
+    return DecoratedBox(
+      decoration: BoxDecoration(
+        color: fill,
+        borderRadius: BorderRadius.circular(10),
+        border: Border.all(color: border),
+      ),
+      child: Padding(
+        padding: const EdgeInsets.all(12),
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.stretch,
+          children: [
+            Text(
+              'Paramètres de génération',
+              key: const Key('environment-studio-draft-params-section-title'),
+              style: TextStyle(
+                color: label,
+                fontSize: 14,
+                fontWeight: FontWeight.w800,
+              ),
+            ),
+            const SizedBox(height: 6),
+            Text(
+              'Ces valeurs restent dans le brouillon local tant que la création '
+              'réelle n’est pas branchée.',
+              key: const Key('environment-studio-draft-params-local-note'),
+              style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
+            ),
+            const SizedBox(height: 14),
+            _subLabel(context, 'Densité'),
+            const SizedBox(height: 4),
+            CupertinoTextField(
+              key: const Key('environment-studio-draft-params-density'),
+              controller: _densityCtrl,
+              placeholder: '0.0 – 1.0',
+              keyboardType:
+                  const TextInputType.numberWithOptions(decimal: true),
+              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
+              onChanged: _emitDensity,
+            ),
+            const SizedBox(height: 12),
+            _subLabel(context, 'Variation'),
+            const SizedBox(height: 4),
+            CupertinoTextField(
+              key: const Key('environment-studio-draft-params-variation'),
+              controller: _variationCtrl,
+              placeholder: '0.0 – 1.0',
+              keyboardType:
+                  const TextInputType.numberWithOptions(decimal: true),
+              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
+              onChanged: _emitVariation,
+            ),
+            const SizedBox(height: 12),
+            _subLabel(context, 'Densité des bords'),
+            const SizedBox(height: 4),
+            CupertinoTextField(
+              key: const Key('environment-studio-draft-params-edge-density'),
+              controller: _edgeDensityCtrl,
+              placeholder: '0.0 – 1.0',
+              keyboardType:
+                  const TextInputType.numberWithOptions(decimal: true),
+              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
+              onChanged: _emitEdgeDensity,
+            ),
+            const SizedBox(height: 12),
+            _subLabel(context, 'Espacement minimal'),
+            const SizedBox(height: 4),
+            CupertinoTextField(
+              key: const Key('environment-studio-draft-params-min-spacing'),
+              controller: _minSpacingCtrl,
+              placeholder: '≥ 0',
+              keyboardType: TextInputType.number,
+              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
+              onChanged: _emitMinSpacing,
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+
+  Widget _subLabel(BuildContext context, String text) {
+    return Text(
+      text,
+      style: TextStyle(
+        color: EditorChrome.subtleLabel(context),
+        fontSize: 11,
+        fontWeight: FontWeight.w700,
+      ),
+    );
+  }
+}

```

### Nouveau `environment_generation_params_draft_editor_test.dart`

```diff
+import 'package:flutter/cupertino.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:macos_ui/macos_ui.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';
+
+void main() {
+  group('EnvironmentStudioPanel — params génération brouillon (Lot 15)', () {
+    testWidgets('affichage initial : titres et valeurs standard',
+        (tester) async {
+      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      expect(
+        find.byKey(const Key('environment-studio-draft-params-editor')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const Key('environment-studio-draft-params-section-title')),
+        findsOneWidget,
+      );
+      expect(find.text('Paramètres de génération'), findsOneWidget);
+      expect(
+        (tester.widget<CupertinoTextField>(find
+                .byKey(const Key('environment-studio-draft-params-density'))))
+            .controller
+            ?.text,
+        '0.5',
+      );
+      expect(
+        (tester.widget<CupertinoTextField>(find
+                .byKey(const Key('environment-studio-draft-params-variation'))))
+            .controller
+            ?.text,
+        '0.5',
+      );
+      expect(
+        (tester.widget<CupertinoTextField>(find.byKey(
+                const Key('environment-studio-draft-params-edge-density'))))
+            .controller
+            ?.text,
+        '0.5',
+      );
+      expect(
+        (tester.widget<CupertinoTextField>(find.byKey(
+                const Key('environment-studio-draft-params-min-spacing'))))
+            .controller
+            ?.text,
+        '0',
+      );
+    });
+
+    testWidgets('densité 0.75 OK puis 1.5 → Densité invalide', (tester) async {
+      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      final d =
+          find.byKey(const Key('environment-studio-draft-params-density'));
+      await tester.enterText(d, '0.75');
+      await tester.pumpAndSettle();
+      expect(
+        _validationHas(tester, 'Densité invalide'),
+        isFalse,
+      );
+
+      await tester.enterText(d, '1.5');
+      await tester.pumpAndSettle();
+      expect(
+        _validationHas(tester, 'Densité invalide'),
+        isTrue,
+      );
+    });
+
+    testWidgets('variation 0.25 OK puis -0.1 → Variation invalide', (
+      tester,
+    ) async {
+      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      final f =
+          find.byKey(const Key('environment-studio-draft-params-variation'));
+      await tester.enterText(f, '0.25');
+      await tester.pumpAndSettle();
+      expect(
+        _validationHas(tester, 'Variation invalide'),
+        isFalse,
+      );
+
+      await tester.enterText(f, '-0.1');
+      await tester.pumpAndSettle();
+      expect(
+        _validationHas(tester, 'Variation invalide'),
+        isTrue,
+      );
+    });
+
+    testWidgets('densité des bords 0.6 OK puis 2 → Densité des bords invalide',
+        (tester) async {
+      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      final f =
+          find.byKey(const Key('environment-studio-draft-params-edge-density'));
+      await tester.enterText(f, '0.6');
+      await tester.pumpAndSettle();
+      expect(
+        _validationHas(tester, 'Densité des bords invalide'),
+        isFalse,
+      );
+
+      await tester.enterText(f, '2');
+      await tester.pumpAndSettle();
+      expect(
+        _validationHas(tester, 'Densité des bords invalide'),
+        isTrue,
+      );
+    });
+
+    testWidgets('espacement 3 OK puis -1 → Espacement invalide',
+        (tester) async {
+      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      final f =
+          find.byKey(const Key('environment-studio-draft-params-min-spacing'));
+      await tester.enterText(f, '3');
+      await tester.pumpAndSettle();
+      expect(
+        _validationHas(tester, 'Espacement invalide'),
+        isFalse,
+      );
+
+      await tester.enterText(f, '-1');
+      await tester.pumpAndSettle();
+      expect(
+        _validationHas(tester, 'Espacement invalide'),
+        isTrue,
+      );
+    });
+
+    testWidgets('saisie non parseable : champ affiché, draft inchangé', (
+      tester,
+    ) async {
+      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      final d =
+          find.byKey(const Key('environment-studio-draft-params-density'));
+      await tester.enterText(d, 'abc');
+      await tester.pumpAndSettle();
+      expect((tester.widget<CupertinoTextField>(d)).controller?.text, 'abc');
+      expect(
+        _validationHas(tester, 'Densité invalide'),
+        isFalse,
+      );
+
+      final m =
+          find.byKey(const Key('environment-studio-draft-params-min-spacing'));
+      await tester.enterText(m, 'xyz');
+      await tester.pumpAndSettle();
+      expect((tester.widget<CupertinoTextField>(m)).controller?.text, 'xyz');
+      expect(
+        _validationHas(tester, 'Espacement invalide'),
+        isFalse,
+      );
+    });
+
+    testWidgets('Réinitialiser brouillon remet les params standard', (
+      tester,
+    ) async {
+      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-draft-params-density')),
+        '0.25',
+      );
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-draft-params-min-spacing')),
+        '7',
+      );
+      await tester.pumpAndSettle();
+
+      await tester.ensureVisible(
+        find.byKey(const Key('environment-studio-draft-reset')),
+      );
+      await tester.pumpAndSettle();
+      await tester.tap(find.byKey(const Key('environment-studio-draft-reset')));
+      await tester.pumpAndSettle();
+
+      expect(
+        (tester.widget<CupertinoTextField>(find
+                .byKey(const Key('environment-studio-draft-params-density'))))
+            .controller
+            ?.text,
+        '0.5',
+      );
+      expect(
+        (tester.widget<CupertinoTextField>(find.byKey(
+                const Key('environment-studio-draft-params-min-spacing'))))
+            .controller
+            ?.text,
+        '0',
+      );
+    });
+
+    testWidgets(
+        'modifier params puis retour browser : manifest.environmentPresets inchangé',
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
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-draft-params-density')),
+        '0.2',
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
+  return find
+      .descendant(
+        of: find.byKey(const Key('environment-studio-draft-validation-root')),
+        matching: find.textContaining(substring),
+      )
+      .evaluate()
+      .isNotEmpty;
+}
+
+Future<void> _pump(WidgetTester tester, ProjectManifest manifest) async {
+  tester.view.physicalSize = const Size(900, 2400);
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
+    name: 'gen-params-draft-test',
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

- **Points solides** : séparation widget dédié ; `didUpdateWidget` pour reset ; correction `_formatDouble` (`truncateToDouble` vs `roundToDouble` toujours vrai) ; tests couvrant hors bornes et parse impossible.
- **Points discutables** : UX « champ affiché abc » sans indication explicite que le brouillon n’a pas changé (acceptable V0).
- **Corrections faites après auto-review** : `_formatDouble` corrigé après constat que `v == v.roundToDouble()` est toujours vrai pour les finis.
- **Risques restants** : grands doubles pourraient afficher une représentation longue en `toString()`.
- **Regard critique sur le prompt** : champs texte suffisants V0 ; sliders reportables ; non parseable = conserver brouillon cohérent avec poids palette ; invalides dans le draft plutôt que clamp = oui ; pas de mutation manifest.

## 17. Verdict

Statut du lot :

- [x] Validé

Résumé :

```
Éditeur params brouillon + 8 tests dédiés ; 85 tests environment_studio verts ; analyze OK ; flutter test map_editor +918 -34 (dette préexistante hors lot).
```

Prochain lot recommandé :

```
Environment-16 — Environment Preset Draft Save to Manifest V0
```
