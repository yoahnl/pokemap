# Environment Studio Lot 13 — Preset Creation Form Shell V0

## 1. Résumé exécutif

Ajout d’un mode local **browser / brouillon** dans `EnvironmentStudioPanel` : action « Préparer un preset », formulaire `EnvironmentPresetDraftForm` branché sur `EnvironmentPresetDraft` et `validateEnvironmentPresetDraft` (sans `knownTemplateIds` en dur), affichage des issues en français via `environment_preset_draft_presentation.dart`, annulation et réinitialisation sans aucune mutation de `ProjectManifest` ni appel à `buildEnvironmentPresetFromDraft` / `upsertProjectEnvironmentPreset`.

## 2. Périmètre du lot

- `map_editor` uniquement : panel + widgets + tests + rapport.
- Pas de persistance, pas de `map_core` modifié.

## 3. Audit initial du draft et du browser

Audits effectués sur : `environment_studio_panel.dart` (liste + détail + diagnostics projet), `environment_preset_draft.dart` (API Lot 12), widgets liste/détail/diagnostics existants, tests Environment Studio, `cupertino_editor_widgets.dart` (`EditorChrome`).

Décision : état `_panelMode` + `_draft` + `_draftFormEpoch` dans le `State` du panel ; `ValueKey(_draftFormEpoch)` pour recréer les contrôleurs du formulaire après reset.

## 4. Décisions UI / état local

- `EnvironmentStudioPanelMode` exporté depuis `environment_studio_panel.dart`.
- Bannière d’en-tête : texte distinct en mode brouillon vs browser.
- Zone palette formulaire : libellé distinct de l’issue de validation « Palette vide » pour éviter collision de recherche texte.
- Boutons d’action du formulaire en `Wrap` pour éviter overflow sur petits viewports de test.

## 5. Formulaire brouillon ajouté

- `environment_preset_draft_form.dart` : champs id, nom, template, catégorie, ordre ; paramètres en lecture seule ; note palette ; boutons Retour / Réinitialiser.
- `environment_preset_draft_validation_view.dart` : compteurs + cartes issue (sévérité FR + kind FR + message technique).
- `environment_preset_draft_presentation.dart` : `environmentPresetDraftIssueKindLabel` / `environmentPresetDraftIssueSeverityLabel`.

## 6. Validation affichée

- `validateEnvironmentPresetDraft(_draft, manifest: widget.manifest, knownTemplateIds: const {})` à chaque build en mode brouillon (pas de liste hardcodée de templates).

## 7. Non-persistance garantie

- Aucun appel UI à `buildEnvironmentPresetFromDraft`, `upsertProjectEnvironmentPreset`, `replaceProjectEnvironmentPresets`.
- Tests : stabilité des ids de presets du manifest après parcours formulaire + annulation ; absence des libellés anglais Save/Create/Generate.

## 8. Pourquoi aucune sauvegarde / génération dans ce lot

Alignement roadmap : Lot 16 prévu pour l’upsert manifest ; Lot 13 limite l’UX au brouillon local.

## 9. Fichiers modifiés

- `packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart` (M)
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart` (nouveau)
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_validation_view.dart` (nouveau)
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_presentation.dart` (nouveau)
- `packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart` (nouveau)
- `packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart` (M)
- `packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart` (M)
- `reports/forest/environment_studio_lot_13_preset_creation_form_shell.md` (ce fichier)

## 10. Tests ajoutés ou modifiés

- Nouveau fichier `environment_studio_preset_creation_form_test.dart` (ouverture, champs, validation, saisie, reset, cancel, non-persistance, surface de test agrandie, `ensureVisible` sur boutons).
- `environment_studio_workspace_test.dart` : bouton Préparer + attente d’un seul `CupertinoButton` en browser.
- `environment_studio_preset_browser_test.dart` : visibilité du bouton Préparer.

## 11. Commandes exécutées

```bash
cd packages/map_editor
dart format lib/src/features/environment_studio/environment_studio_panel.dart \
  lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart \
  lib/src/features/environment_studio/widgets/environment_preset_draft_validation_view.dart \
  lib/src/features/environment_studio/widgets/environment_preset_draft_presentation.dart \
  test/environment_studio/environment_studio_preset_creation_form_test.dart \
  test/environment_studio/environment_studio_workspace_test.dart \
  test/environment_studio/environment_studio_preset_browser_test.dart

flutter analyze (7 chemins)

flutter test test/environment_studio/environment_studio_preset_creation_form_test.dart --reporter expanded
flutter test test/environment_studio --reporter expanded
flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart --reporter expanded
flutter test test/environment_studio/environment_studio_workspace_entry_test.dart --reporter expanded
flutter test 2>&1 | tail -n 4
```

## 12. Résultats des commandes

### dart format

```
Formatted 7 files (0 changed) in 0.02 seconds.

```

### flutter analyze

```
Analyzing 7 items...                                            
No issues found! (ran in 1.4s)

```

### flutter test — formulaire ciblé

```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart
00:00 +0: environmentPresetDraftIssueKindLabel libellés FR attendus (extrait)
00:00 +1: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:00 +2: EnvironmentStudioPanel — formulaire brouillon champs initiaux vides et params standard
00:00 +3: EnvironmentStudioPanel — formulaire brouillon validation initiale : id, nom, template, palette
00:00 +4: EnvironmentStudioPanel — formulaire brouillon saisie met à jour le draft et la validation
00:00 +5: EnvironmentStudioPanel — formulaire brouillon sortOrder : texte invalide conserve la valeur draft
00:01 +6: EnvironmentStudioPanel — formulaire brouillon Réinitialiser brouillon remet les champs vides
00:01 +7: EnvironmentStudioPanel — formulaire brouillon Retour au browser restaure la liste sans modifier le manifest
00:01 +8: EnvironmentStudioPanel — formulaire brouillon aucun Save / Create / Generate dans l’UI
00:01 +9: EnvironmentStudioPanel — formulaire brouillon catégorie optionnelle : champ vide
00:01 +10: All tests passed!

```

### flutter test — dossier test/environment_studio

```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart: environmentDiagnosticKindLabel quelques kinds FR stables
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart: EnvironmentStudioPanel état vide : titre, badge read-only, pas de liste ni détail
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart: EnvironmentStudioPanel — browser read-only sections identité, paramètres, palette et diagnostics visibles
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart: EnvironmentStudioPanel liste presets et sélection du premier par défaut
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart: EnvironmentStudioPanel — browser read-only catégorie absente : affiche —
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart: EnvironmentStudioPanel tap sur un autre preset met à jour le détail
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart: EnvironmentStudioPanel tap sur un autre preset met à jour le détail
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart: EnvironmentStudioPanel tap sur un autre preset met à jour le détail
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart: EnvironmentStudioPanel — browser read-only unknownTemplateId : kind FR et templateId affiché si knownTemplateIds
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart: EnvironmentStudioPanel browser : un seul CupertinoButton « Préparer un preset »
00:00 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart: EnvironmentStudioPanel — browser read-only read-only : pas de libellés Create / Edit / Delete / Generate / Save
00:00 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart: EnvironmentStudioPanel — browser read-only browser : bouton Préparer un preset visible
00:03 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentGenerationParamsDraft standard s’aligne sur EnvironmentGenerationParams.standard()
00:03 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentGenerationParamsDraft copyWith modifie chaque champ
00:03 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentGenerationParamsDraft égalité de valeur
00:03 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentPaletteItemDraft accepte elementId vide sans throw
00:03 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentPaletteItemDraft accepte weight <= 0 sans throw
00:03 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentPaletteItemDraft collisionMode par défaut
00:03 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentPaletteItemDraft copie défensive tags et exposés immuables
00:03 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentPaletteItemDraft copyWith modifie les champs
00:03 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentPaletteItemDraft égalité indépendante de l’ordre des tags source
00:03 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentPresetDraft empty crée un brouillon formulaire
00:03 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentPresetDraft fromPreset conserve champs et convertit palette / params
00:03 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: environmentPresetDraftIssueKindLabel libellés FR attendus (extrait)
00:03 +24: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: environmentPresetDraftIssueKindLabel libellés FR attendus (extrait)
00:03 +25: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: environmentPresetDraftIssueKindLabel libellés FR attendus (extrait)
00:03 +26: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: environmentPresetDraftIssueKindLabel libellés FR attendus (extrait)
00:03 +27: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: environmentPresetDraftIssueKindLabel libellés FR attendus (extrait)
00:03 +28: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: environmentPresetDraftIssueKindLabel libellés FR attendus (extrait)
00:03 +29: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: validateEnvironmentPresetDraft duplicateId en création
00:03 +30: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +31: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +32: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +33: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +34: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +35: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +36: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +37: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +38: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +39: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +40: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +41: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +42: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +43: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +44: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +45: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +46: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +47: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +48: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +49: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +50: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +51: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +52: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +53: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +54: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +55: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:03 +56: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:04 +56: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:04 +57: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:04 +58: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:04 +59: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace le project explorer ouvre Environment Studio au tap (clé dédiée)
00:04 +60: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace le project explorer ouvre Environment Studio au tap (clé dédiée)
00:04 +61: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace le project explorer ouvre Environment Studio au tap (clé dédiée)
00:04 +62: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace le project explorer ouvre Environment Studio au tap (clé dédiée)
00:04 +63: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace le project explorer ouvre Environment Studio au tap (clé dédiée)
00:04 +64: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon Réinitialiser brouillon remet les champs vides
00:04 +65: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon Retour au browser restaure la liste sans modifier le manifest
00:04 +66: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon aucun Save / Create / Generate dans l’UI
00:04 +67: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon catégorie optionnelle : champ vide
00:05 +68: All tests passed!

```

### flutter test — editor_workspace_controller + top_toolbar

```
Waiting for another flutter command to release the startup lock...
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectPokedexWorkspace switches mode and clears stale errors
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectTrainerWorkspace switches mode and clears stale errors
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectDialogueWorkspace keeps project session and only changes mode
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectEnvironmentStudioWorkspace switches mode and clears stale errors
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectPokemonCatalogSection opens the parent workspace and stores the section
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows the app brand and project workspace label
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar falls back to the workspace label when no project is loaded
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows the toolbar status chip when a status is present
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows the trainer studio label for the trainer workspace
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar enables project save and disables map history in Path Studio
00:00 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows neutral Save Project when project is clean in Path Studio
00:00 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar enables project save and disables map history in Environment Studio
00:00 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows Environment Studio in the workspace brand strip
00:00 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar keeps map save action in map workspace
00:00 +14: All tests passed!

```

### flutter test — environment_studio_workspace_entry (isolé)

```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart
00:00 +0: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:00 +1: Environment Studio — entrée workspace affiche le message projet absent sans manifest
00:00 +2: Environment Studio — entrée workspace le project explorer ouvre Environment Studio au tap (clé dédiée)
00:01 +3: All tests passed!

```

### flutter test — suite complète map_editor (dernières lignes)

```
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/items_catalog_sync_eOr3w5/project.json

00:59 +900 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: ... pokemon data root for both the items catalog and local sprite assets   
00:59 +900 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: load use case reads the synced catalog after a real sync                   
00:59 +900 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: load use case reads the synced catalog after a real sync                   
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/items_catalog_sync_TQh1pY/project.json

00:59 +901 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: load use case reads the synced catalog after a real sync                   
00:59 +901 -34: Some tests failed.                                                                                                                                                                     

```

## 13. Git status initial et final

**Git status initial** (instantané fourni par l’outil au tout début de la conversation, avant travail Lot 13 ; peut inclure d’autres lots non commit) :

```
M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/models/enums.dart
 M packages/map_core/lib/src/models/project_manifest.dart
 M packages/map_core/lib/src/models/project_manifest.freezed.dart
 M packages/map_core/lib/src/models/project_manifest.g.dart
 M packages/map_core/lib/src/operations/terrain_preset_subtile_for_map_cell.dart
?? packages/map_core/lib/src/operations/terrain_preset_variant_pick.dart
 M packages/map_core/test/terrain_preset_subtile_for_map_cell_test.dart
?? packages/map_core/test/terrain_preset_variant_pick_test.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart
 M packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
```

**Preuve fichiers nouveaux absents de `HEAD`** :

```
fatal: path 'packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart' exists on disk, but not in 'HEAD'
exit:128
```

**État final** (`git status --short --untracked-files=all`) :

```
 M packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
 M packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart
 M packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart
?? packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
?? packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_presentation.dart
?? packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_validation_view.dart
?? packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart
?? reports/forest/environment_studio_lot_13_preset_creation_form_shell.md

```

Les entrées `M` / `??` hors `packages/map_editor/...environment_studio...` et hors `reports/forest/...lot_13...` relèvent d’autres chantiers non commit sur la même copie de travail.

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

*(Les corps exacts sont ceux du disque au moment du rapport ; chemins relatifs à la racine du dépôt.)*

### Fichiers modifiés — `git diff`

#### `packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart b/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
index 01977da6..1c93fe91 100644
--- a/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
@@ -2,9 +2,20 @@ import 'package:flutter/cupertino.dart';
 import 'package:map_core/map_core.dart';
 
 import '../../ui/shared/cupertino_editor_widgets.dart';
+import 'authoring/environment_preset_draft.dart';
 import 'widgets/environment_preset_detail.dart';
+import 'widgets/environment_preset_draft_form.dart';
 import 'widgets/environment_preset_list.dart';
 
+/// Modes locaux du panneau Environment Studio (Lot Environment-13).
+enum EnvironmentStudioPanelMode {
+  /// Liste + détail des presets existants (non mutateur).
+  browser,
+
+  /// Formulaire de brouillon sans persistance manifest.
+  createDraft,
+}
+
 /// Browser read-only des presets Environment (Lot Environment-10, polish 11).
 ///
 /// Sélection locale uniquement ([StatefulWidget]) : aucune mutation du
@@ -12,6 +23,10 @@ import 'widgets/environment_preset_list.dart';
 ///
 /// [knownTemplateIds] non vide active les diagnostics `unknownTemplateId` pour
 /// les [EnvironmentPreset.templateId] absents du set (défaut `{}` = désactivé).
+///
+/// Le mode [EnvironmentStudioPanelMode.createDraft] permet un brouillon local
+/// ([EnvironmentPresetDraft]) sans [upsertProjectEnvironmentPreset] ni
+/// [buildEnvironmentPresetFromDraft] côté UI.
 class EnvironmentStudioPanel extends StatefulWidget {
   const EnvironmentStudioPanel({
     super.key,
@@ -30,6 +45,9 @@ class EnvironmentStudioPanel extends StatefulWidget {
 
 class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
   String? _selectedPresetId;
+  EnvironmentStudioPanelMode _panelMode = EnvironmentStudioPanelMode.browser;
+  EnvironmentPresetDraft _draft = EnvironmentPresetDraft.empty();
+  int _draftFormEpoch = 0;
 
   @override
   void initState() {
@@ -87,6 +105,27 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
     return null;
   }
 
+  void _openDraftForm() {
+    setState(() {
+      _panelMode = EnvironmentStudioPanelMode.createDraft;
+      _draft = EnvironmentPresetDraft.empty();
+      _draftFormEpoch++;
+    });
+  }
+
+  void _closeDraftForm() {
+    setState(() {
+      _panelMode = EnvironmentStudioPanelMode.browser;
+    });
+  }
+
+  void _resetDraft() {
+    setState(() {
+      _draft = EnvironmentPresetDraft.empty();
+      _draftFormEpoch++;
+    });
+  }
+
   @override
   Widget build(BuildContext context) {
     final label = EditorChrome.primaryLabel(context);
@@ -100,6 +139,14 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
     );
     final s = report.summary;
 
+    final draftValidation = _panelMode == EnvironmentStudioPanelMode.createDraft
+        ? validateEnvironmentPresetDraft(
+            _draft,
+            manifest: widget.manifest,
+            knownTemplateIds: const <String>{},
+          )
+        : null;
+
     return ColoredBox(
       color: EditorChrome.largeIslandSurfaceColor(
         context,
@@ -115,19 +162,55 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                 children: [
                   _buildHeader(context, label, subtle, n),
-                  const SizedBox(height: 20),
-                  if (n == 0)
-                    Expanded(
-                      child: _buildEmptyPresets(context, subtle),
-                    )
+                  const SizedBox(height: 12),
+                  if (_panelMode == EnvironmentStudioPanelMode.browser)
+                    Align(
+                      alignment: Alignment.centerLeft,
+                      child: CupertinoButton(
+                        key: const Key('environment-studio-open-draft'),
+                        padding: const EdgeInsets.symmetric(
+                          horizontal: 8,
+                          vertical: 4,
+                        ),
+                        onPressed: _openDraftForm,
+                        child: const Text('Préparer un preset'),
+                      ),
+                    ),
+                  const SizedBox(height: 8),
+                  if (_panelMode == EnvironmentStudioPanelMode.browser)
+                    if (n == 0)
+                      Expanded(
+                        child: _buildEmptyPresets(context, subtle),
+                      )
+                    else
+                      Expanded(
+                        child: _buildBrowser(
+                          context,
+                          label,
+                          subtle,
+                          presets,
+                          report,
+                        ),
+                      )
                   else
                     Expanded(
-                      child: _buildBrowser(
-                        context,
-                        label,
-                        subtle,
-                        presets,
-                        report,
+                      child: DecoratedBox(
+                        decoration: BoxDecoration(
+                          color: EditorChrome.chipFill(context),
+                          borderRadius: BorderRadius.circular(12),
+                          border: Border.all(
+                            color:
+                                CupertinoColors.separator.resolveFrom(context),
+                          ),
+                        ),
+                        child: EnvironmentPresetDraftForm(
+                          key: ValueKey<int>(_draftFormEpoch),
+                          draft: _draft,
+                          validation: draftValidation!,
+                          onChanged: (d) => setState(() => _draft = d),
+                          onCancel: _closeDraftForm,
+                          onReset: _resetDraft,
+                        ),
                       ),
                     ),
                   const SizedBox(height: 20),
@@ -149,6 +232,7 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
     Color subtle,
     int presetCount,
   ) {
+    final isDraft = _panelMode == EnvironmentStudioPanelMode.createDraft;
     return Column(
       crossAxisAlignment: CrossAxisAlignment.stretch,
       children: [
@@ -181,10 +265,14 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
               color: EditorChrome.accentJade.withValues(alpha: 0.35),
             ),
           ),
-          child: const Text(
-            'Lecture seule — édition et génération arrivent dans les prochains lots.',
-            key: Key('environment-studio-read-only-banner'),
-            style: TextStyle(
+          child: Text(
+            isDraft
+                ? 'Brouillon local — aucune écriture dans le projet. '
+                    'Création réelle et palette éditables arrivent dans les prochains lots.'
+                : 'Lecture seule sur les presets existants — édition manifest et '
+                    'génération arrivent dans les prochains lots.',
+            key: const Key('environment-studio-read-only-banner'),
+            style: const TextStyle(
               color: EditorChrome.accentJade,
               fontSize: 12,
               fontWeight: FontWeight.w600,
@@ -208,17 +296,22 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
   Widget _buildEmptyPresets(BuildContext context, Color subtle) {
     return Align(
       alignment: Alignment.topCenter,
-      child: Text(
-        'Aucun preset d’environnement pour le moment.\n'
-        'Les presets seront créés ici dans un prochain lot.',
-        key: const Key('environment-studio-empty-presets'),
-        textAlign: TextAlign.center,
-        style: TextStyle(
-          color: subtle,
-          fontSize: 14,
-          height: 1.4,
-          fontWeight: FontWeight.w500,
-        ),
+      child: Column(
+        mainAxisSize: MainAxisSize.min,
+        children: [
+          Text(
+            'Aucun preset d’environnement pour le moment.\n'
+            'Les presets seront enregistrés dans le projet dans un prochain lot.',
+            key: const Key('environment-studio-empty-presets'),
+            textAlign: TextAlign.center,
+            style: TextStyle(
+              color: subtle,
+              fontSize: 14,
+              height: 1.4,
+              fontWeight: FontWeight.w500,
+            ),
+          ),
+        ],
       ),
     );
   }

```

#### `packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart`

```diff
diff --git a/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart b/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart
index 167a13ce..87d3d705 100644
--- a/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart
+++ b/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart
@@ -33,6 +33,9 @@ void main() {
         findsOneWidget,
       );
       expect(find.textContaining('génération organique'), findsOneWidget);
+      expect(find.byKey(const Key('environment-studio-open-draft')),
+          findsOneWidget);
+      expect(find.text('Préparer un preset'), findsOneWidget);
       expect(find.byKey(const Key('environment-studio-preset-list')),
           findsNothing);
       expect(find.byKey(const Key('environment-studio-detail-root')),
@@ -96,7 +99,7 @@ void main() {
       );
     });
 
-    testWidgets('ne propose aucun CupertinoButton dans le panneau', (
+    testWidgets('browser : un seul CupertinoButton « Préparer un preset »', (
       tester,
     ) async {
       await _pumpPanel(
@@ -110,7 +113,14 @@ void main() {
       final panel = find.byType(EnvironmentStudioPanel);
       expect(
         find.descendant(of: panel, matching: find.byType(CupertinoButton)),
-        findsNothing,
+        findsOneWidget,
+      );
+      expect(
+        find.descendant(
+          of: panel,
+          matching: find.byKey(const Key('environment-studio-open-draft')),
+        ),
+        findsOneWidget,
       );
     });
   });

```

#### `packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart`

```diff
diff --git a/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart b/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart
index 05c7eeef..b4294db6 100644
--- a/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart
+++ b/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart
@@ -325,6 +325,30 @@ void main() {
       expect(find.textContaining('Generate'), findsNothing);
       expect(find.textContaining('Save'), findsNothing);
     });
+
+    testWidgets('browser : bouton Préparer un preset visible', (tester) async {
+      await _pump(
+        tester,
+        _manifest(
+          environmentPresets: [
+            EnvironmentPreset(
+              id: 'x',
+              name: 'X',
+              templateId: 'tpl',
+              palette: [
+                EnvironmentPaletteItem(elementId: 'e1', weight: 1),
+              ],
+              defaultParams: EnvironmentGenerationParams.standard(),
+              sortOrder: 0,
+            ),
+          ],
+          elements: [_element(id: 'e1')],
+        ),
+      );
+      expect(find.byKey(const Key('environment-studio-open-draft')),
+          findsOneWidget);
+      expect(find.text('Préparer un preset'), findsOneWidget);
+    });
   });
 }
 

```

### Fichiers nouveaux — équivalent `diff /dev/null`

#### `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart`

```diff
+import 'package:flutter/cupertino.dart';
+
+import '../../../ui/shared/cupertino_editor_widgets.dart';
+import '../authoring/environment_preset_draft.dart';
+import 'environment_preset_draft_validation_view.dart';
+
+/// Formulaire local de brouillon (aucune persistance manifest).
+class EnvironmentPresetDraftForm extends StatefulWidget {
+  const EnvironmentPresetDraftForm({
+    super.key,
+    required this.draft,
+    required this.validation,
+    required this.onChanged,
+    required this.onCancel,
+    required this.onReset,
+  });
+
+  final EnvironmentPresetDraft draft;
+  final EnvironmentPresetDraftValidationReport validation;
+  final ValueChanged<EnvironmentPresetDraft> onChanged;
+  final VoidCallback onCancel;
+  final VoidCallback onReset;
+
+  @override
+  State<EnvironmentPresetDraftForm> createState() =>
+      _EnvironmentPresetDraftFormState();
+}
+
+class _EnvironmentPresetDraftFormState
+    extends State<EnvironmentPresetDraftForm> {
+  late final TextEditingController _idCtrl;
+  late final TextEditingController _nameCtrl;
+  late final TextEditingController _templateCtrl;
+  late final TextEditingController _categoryCtrl;
+  late final TextEditingController _sortCtrl;
+
+  @override
+  void initState() {
+    super.initState();
+    final d = widget.draft;
+    _idCtrl = TextEditingController(text: d.id);
+    _nameCtrl = TextEditingController(text: d.name);
+    _templateCtrl = TextEditingController(text: d.templateId);
+    _categoryCtrl = TextEditingController(text: d.categoryId ?? '');
+    _sortCtrl = TextEditingController(text: d.sortOrder.toString());
+  }
+
+  @override
+  void dispose() {
+    _idCtrl.dispose();
+    _nameCtrl.dispose();
+    _templateCtrl.dispose();
+    _categoryCtrl.dispose();
+    _sortCtrl.dispose();
+    super.dispose();
+  }
+
+  void _emit() {
+    final so = int.tryParse(_sortCtrl.text.trim());
+    widget.onChanged(
+      EnvironmentPresetDraft(
+        id: _idCtrl.text,
+        name: _nameCtrl.text,
+        templateId: _templateCtrl.text,
+        palette: widget.draft.palette,
+        defaultParams: widget.draft.defaultParams,
+        categoryId:
+            _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text,
+        sortOrder: so ?? widget.draft.sortOrder,
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
+    final p = widget.draft.defaultParams;
+
+    return SingleChildScrollView(
+      key: const Key('environment-studio-draft-form-scroll'),
+      padding: const EdgeInsets.all(20),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Text(
+            'Nouveau preset d’environnement',
+            key: const Key('environment-studio-draft-form-title'),
+            style: TextStyle(
+              color: label,
+              fontSize: 20,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          const SizedBox(height: 10),
+          Container(
+            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
+            decoration: BoxDecoration(
+              color: EditorChrome.accentWarm.withValues(alpha: 0.12),
+              borderRadius: BorderRadius.circular(8),
+              border: Border.all(
+                color: EditorChrome.accentWarm.withValues(alpha: 0.45),
+              ),
+            ),
+            child: const Text(
+              'Brouillon local non sauvegardé',
+              key: Key('environment-studio-draft-local-badge'),
+              style: TextStyle(
+                color: EditorChrome.accentWarm,
+                fontSize: 12,
+                fontWeight: FontWeight.w700,
+              ),
+            ),
+          ),
+          const SizedBox(height: 10),
+          Text(
+            'Ce formulaire prépare un preset. L’enregistrement dans le projet sera '
+            'ajouté dans un prochain lot.',
+            key: const Key('environment-studio-draft-form-intro'),
+            style: TextStyle(
+              color: subtle,
+              fontSize: 12.5,
+              height: 1.4,
+            ),
+          ),
+          const SizedBox(height: 20),
+          _fieldLabel(context, 'Id'),
+          const SizedBox(height: 4),
+          CupertinoTextField(
+            key: const Key('environment-studio-draft-field-id'),
+            controller: _idCtrl,
+            placeholder: 'Identifiant unique',
+            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
+            onChanged: (_) => _emit(),
+          ),
+          const SizedBox(height: 14),
+          _fieldLabel(context, 'Nom'),
+          const SizedBox(height: 4),
+          CupertinoTextField(
+            key: const Key('environment-studio-draft-field-name'),
+            controller: _nameCtrl,
+            placeholder: 'Nom affiché',
+            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
+            onChanged: (_) => _emit(),
+          ),
+          const SizedBox(height: 14),
+          _fieldLabel(context, 'Template'),
+          const SizedBox(height: 4),
+          CupertinoTextField(
+            key: const Key('environment-studio-draft-field-template'),
+            controller: _templateCtrl,
+            placeholder: 'Ex. forest_dense',
+            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
+            onChanged: (_) => _emit(),
+          ),
+          const SizedBox(height: 14),
+          _fieldLabel(context, 'Catégorie (optionnel)'),
+          const SizedBox(height: 4),
+          CupertinoTextField(
+            key: const Key('environment-studio-draft-field-category'),
+            controller: _categoryCtrl,
+            placeholder: 'Laisser vide si sans catégorie',
+            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
+            onChanged: (_) => _emit(),
+          ),
+          const SizedBox(height: 14),
+          _fieldLabel(context, 'Ordre d’affichage'),
+          const SizedBox(height: 4),
+          CupertinoTextField(
+            key: const Key('environment-studio-draft-field-sort'),
+            controller: _sortCtrl,
+            placeholder: '0',
+            keyboardType: TextInputType.number,
+            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
+            onChanged: (_) => _emit(),
+          ),
+          const SizedBox(height: 22),
+          Text(
+            'Paramètres par défaut (lecture seule pour l’instant)',
+            style: TextStyle(
+              color: label,
+              fontSize: 14,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          const SizedBox(height: 8),
+          DecoratedBox(
+            decoration: BoxDecoration(
+              color: fill,
+              borderRadius: BorderRadius.circular(10),
+              border: Border.all(color: border),
+            ),
+            child: Padding(
+              padding: const EdgeInsets.all(12),
+              child: Text(
+                'Densité ${p.density.toStringAsFixed(2)} · '
+                'Variation ${p.variation.toStringAsFixed(2)} · '
+                'Densité des bords ${p.edgeDensity.toStringAsFixed(2)} · '
+                'Espacement min. ${p.minSpacingCells} cases',
+                key: const Key('environment-studio-draft-params-readonly'),
+                style: TextStyle(color: subtle, fontSize: 12.5, height: 1.35),
+              ),
+            ),
+          ),
+          const SizedBox(height: 22),
+          Text(
+            'Palette',
+            style: TextStyle(
+              color: label,
+              fontSize: 14,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          const SizedBox(height: 8),
+          Text(
+            'État : aucune entrée de palette (non éditable en V0).',
+            key: const Key('environment-studio-draft-palette-empty'),
+            style: TextStyle(color: subtle, fontSize: 13),
+          ),
+          const SizedBox(height: 4),
+          Text(
+            'L’édition de palette arrive dans un prochain lot.',
+            key: const Key('environment-studio-draft-palette-note'),
+            style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
+          ),
+          const SizedBox(height: 22),
+          Text(
+            'Validation du brouillon',
+            style: TextStyle(
+              color: label,
+              fontSize: 14,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          const SizedBox(height: 8),
+          EnvironmentPresetDraftValidationView(
+            report: widget.validation,
+            labelColor: label,
+            subtleColor: subtle,
+          ),
+          const SizedBox(height: 24),
+          Wrap(
+            spacing: 8,
+            runSpacing: 8,
+            children: [
+              CupertinoButton(
+                key: const Key('environment-studio-draft-cancel'),
+                padding:
+                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
+                onPressed: widget.onCancel,
+                child: const Text('Retour au browser'),
+              ),
+              CupertinoButton(
+                key: const Key('environment-studio-draft-reset'),
+                padding:
+                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
+                onPressed: widget.onReset,
+                child: const Text('Réinitialiser brouillon'),
+              ),
+            ],
+          ),
+        ],
+      ),
+    );
+  }
+
+  Widget _fieldLabel(BuildContext context, String text) {
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

#### `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_validation_view.dart`

```diff
+import 'package:flutter/cupertino.dart';
+
+import '../../../ui/shared/cupertino_editor_widgets.dart';
+import '../authoring/environment_preset_draft.dart';
+import 'environment_preset_draft_presentation.dart';
+
+/// Liste des issues de validation d’un brouillon (FR + message technique).
+class EnvironmentPresetDraftValidationView extends StatelessWidget {
+  const EnvironmentPresetDraftValidationView({
+    super.key,
+    required this.report,
+    required this.labelColor,
+    required this.subtleColor,
+  });
+
+  final EnvironmentPresetDraftValidationReport report;
+  final Color labelColor;
+  final Color subtleColor;
+
+  @override
+  Widget build(BuildContext context) {
+    final err = report.errorCount;
+    final warn = report.warningCount;
+
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      key: const Key('environment-studio-draft-validation-root'),
+      children: [
+        Text(
+          '$err erreur${err == 1 ? '' : 's'} · '
+          '$warn avertissement${warn == 1 ? '' : 's'}',
+          key: const Key('environment-studio-draft-validation-counts'),
+          style: TextStyle(
+            color: subtleColor,
+            fontSize: 13,
+            fontWeight: FontWeight.w700,
+          ),
+        ),
+        const SizedBox(height: 10),
+        if (!report.hasIssues)
+          Text(
+            'Aucune anomalie détectée pour ce brouillon.',
+            key: const Key('environment-studio-draft-validation-empty'),
+            style: TextStyle(color: subtleColor, fontSize: 12.5),
+          )
+        else
+          ...report.issues.asMap().entries.map(
+                (e) => Padding(
+                  padding: const EdgeInsets.only(bottom: 8),
+                  child: DecoratedBox(
+                    key: Key('environment-studio-draft-issue-${e.key}'),
+                    decoration: BoxDecoration(
+                      color: EditorChrome.chipFill(context),
+                      borderRadius: BorderRadius.circular(10),
+                      border: Border.all(
+                        color: CupertinoColors.separator.resolveFrom(context),
+                      ),
+                    ),
+                    child: Padding(
+                      padding: const EdgeInsets.all(10),
+                      child: Column(
+                        crossAxisAlignment: CrossAxisAlignment.stretch,
+                        children: [
+                          Text(
+                            '${environmentPresetDraftIssueSeverityLabel(e.value.severity)} — '
+                            '${environmentPresetDraftIssueKindLabel(e.value.kind)}',
+                            style: TextStyle(
+                              color: labelColor,
+                              fontSize: 13,
+                              fontWeight: FontWeight.w700,
+                            ),
+                          ),
+                          const SizedBox(height: 4),
+                          Text(
+                            e.value.message,
+                            key: Key(
+                              'environment-studio-draft-issue-msg-${e.key}',
+                            ),
+                            style: TextStyle(
+                              color: subtleColor,
+                              fontSize: 11.5,
+                              height: 1.35,
+                            ),
+                          ),
+                        ],
+                      ),
+                    ),
+                  ),
+                ),
+              ),
+      ],
+    );
+  }
+}

```

#### `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_presentation.dart`

```diff
+import '../authoring/environment_preset_draft.dart';
+
+/// Libellés FR pour l’affichage des issues de brouillon (Lot Environment-13).
+String environmentPresetDraftIssueKindLabel(
+    EnvironmentPresetDraftIssueKind kind) {
+  return switch (kind) {
+    EnvironmentPresetDraftIssueKind.emptyId => 'Id vide',
+    EnvironmentPresetDraftIssueKind.duplicateId => 'Id déjà utilisé',
+    EnvironmentPresetDraftIssueKind.emptyName => 'Nom vide',
+    EnvironmentPresetDraftIssueKind.emptyTemplateId => 'Template vide',
+    EnvironmentPresetDraftIssueKind.unknownTemplateId => 'Template inconnu',
+    EnvironmentPresetDraftIssueKind.emptyPalette => 'Palette vide',
+    EnvironmentPresetDraftIssueKind.emptyPaletteElementId =>
+      'Élément de palette vide',
+    EnvironmentPresetDraftIssueKind.duplicatePaletteElementId =>
+      'Élément dupliqué',
+    EnvironmentPresetDraftIssueKind.missingPaletteElement =>
+      'Élément introuvable',
+    EnvironmentPresetDraftIssueKind.invalidPaletteWeight => 'Poids invalide',
+    EnvironmentPresetDraftIssueKind.emptyPaletteTag => 'Tag vide',
+    EnvironmentPresetDraftIssueKind.invalidDensity => 'Densité invalide',
+    EnvironmentPresetDraftIssueKind.invalidVariation => 'Variation invalide',
+    EnvironmentPresetDraftIssueKind.invalidEdgeDensity =>
+      'Densité des bords invalide',
+    EnvironmentPresetDraftIssueKind.invalidMinSpacingCells =>
+      'Espacement invalide',
+    EnvironmentPresetDraftIssueKind.emptyCategoryId => 'Catégorie vide',
+  };
+}
+
+String environmentPresetDraftIssueSeverityLabel(
+  EnvironmentPresetDraftIssueSeverity severity,
+) {
+  return switch (severity) {
+    EnvironmentPresetDraftIssueSeverity.error => 'Erreur',
+    EnvironmentPresetDraftIssueSeverity.warning => 'Avertissement',
+  };
+}

```

#### `packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart`

```diff
+import 'package:flutter/cupertino.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:macos_ui/macos_ui.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/environment_studio/authoring/environment_preset_draft.dart';
+import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';
+import 'package:map_editor/src/features/environment_studio/widgets/environment_preset_draft_presentation.dart';
+
+void main() {
+  group('environmentPresetDraftIssueKindLabel', () {
+    test('libellés FR attendus (extrait)', () {
+      expect(
+        environmentPresetDraftIssueKindLabel(
+          EnvironmentPresetDraftIssueKind.emptyId,
+        ),
+        'Id vide',
+      );
+      expect(
+        environmentPresetDraftIssueKindLabel(
+          EnvironmentPresetDraftIssueKind.emptyPalette,
+        ),
+        'Palette vide',
+      );
+    });
+  });
+
+  group('EnvironmentStudioPanel — formulaire brouillon', () {
+    testWidgets('action Préparer un preset visible puis formulaire', (
+      tester,
+    ) async {
+      await _pump(
+        tester,
+        _manifest(
+          environmentPresets: [
+            _preset(id: 'a'),
+          ],
+          elements: [_element(id: 'elm')],
+        ),
+      );
+
+      expect(find.byKey(const Key('environment-studio-open-draft')),
+          findsOneWidget);
+      expect(find.text('Préparer un preset'), findsOneWidget);
+
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      expect(
+        find.byKey(const Key('environment-studio-draft-form-title')),
+        findsOneWidget,
+      );
+      expect(find.text('Nouveau preset d’environnement'), findsOneWidget);
+      expect(
+        find.byKey(const Key('environment-studio-draft-local-badge')),
+        findsOneWidget,
+      );
+      expect(find.text('Brouillon local non sauvegardé'), findsOneWidget);
+      expect(
+        find.byKey(const Key('environment-studio-draft-form-intro')),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('champs initiaux vides et params standard', (tester) async {
+      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      expect(
+        (tester.widget<CupertinoTextField>(
+                find.byKey(const Key('environment-studio-draft-field-id'))))
+            .controller
+            ?.text,
+        '',
+      );
+      expect(
+        (tester.widget<CupertinoTextField>(
+                find.byKey(const Key('environment-studio-draft-field-name'))))
+            .controller
+            ?.text,
+        '',
+      );
+      expect(
+        (tester.widget<CupertinoTextField>(find
+                .byKey(const Key('environment-studio-draft-field-template'))))
+            .controller
+            ?.text,
+        '',
+      );
+      expect(
+        (tester.widget<CupertinoTextField>(find
+                .byKey(const Key('environment-studio-draft-field-category'))))
+            .controller
+            ?.text,
+        '',
+      );
+      expect(
+        (tester.widget<CupertinoTextField>(
+                find.byKey(const Key('environment-studio-draft-field-sort'))))
+            .controller
+            ?.text,
+        '0',
+      );
+      expect(
+        find.byKey(const Key('environment-studio-draft-params-readonly')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const Key('environment-studio-draft-palette-empty')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const Key('environment-studio-draft-palette-note')),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('validation initiale : id, nom, template, palette', (
+      tester,
+    ) async {
+      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      expect(
+        find.byKey(const Key('environment-studio-draft-validation-counts')),
+        findsOneWidget,
+      );
+      expect(find.textContaining('erreur'), findsWidgets);
+      expect(find.textContaining('Id vide'), findsOneWidget);
+      expect(find.textContaining('Nom vide'), findsOneWidget);
+      expect(find.textContaining('Template vide'), findsOneWidget);
+      expect(
+        find.descendant(
+          of: find.byKey(const Key('environment-studio-draft-validation-root')),
+          matching: find.textContaining('Palette vide'),
+        ),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('saisie met à jour le draft et la validation', (tester) async {
+      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-draft-field-id')),
+        'new_id',
+      );
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-draft-field-name')),
+        'Nom',
+      );
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-draft-field-template')),
+        'tpl1',
+      );
+      await tester.pumpAndSettle();
+
+      expect(find.textContaining('Id vide'), findsNothing);
+      expect(find.textContaining('Nom vide'), findsNothing);
+      expect(find.textContaining('Template vide'), findsNothing);
+      expect(
+        find.descendant(
+          of: find.byKey(const Key('environment-studio-draft-validation-root')),
+          matching: find.textContaining('Palette vide'),
+        ),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('sortOrder : texte invalide conserve la valeur draft', (
+      tester,
+    ) async {
+      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-draft-field-sort')),
+        'not_a_number',
+      );
+      await tester.pumpAndSettle();
+
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-draft-field-id')),
+        'x',
+      );
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-draft-field-name')),
+        'N',
+      );
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-draft-field-template')),
+        't',
+      );
+      await tester.pumpAndSettle();
+
+      expect(
+        (tester.widget<CupertinoTextField>(
+                find.byKey(const Key('environment-studio-draft-field-sort'))))
+            .controller
+            ?.text,
+        'not_a_number',
+      );
+    });
+
+    testWidgets('Réinitialiser brouillon remet les champs vides', (
+      tester,
+    ) async {
+      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-draft-field-id')),
+        'tmp',
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
+        (tester.widget<CupertinoTextField>(
+                find.byKey(const Key('environment-studio-draft-field-id'))))
+            .controller
+            ?.text,
+        '',
+      );
+      expect(
+        (tester.widget<CupertinoTextField>(
+                find.byKey(const Key('environment-studio-draft-field-sort'))))
+            .controller
+            ?.text,
+        '0',
+      );
+    });
+
+    testWidgets('Retour au browser restaure la liste sans modifier le manifest',
+        (tester) async {
+      final manifest = _manifest(
+        environmentPresets: [
+          _preset(id: 'keep'),
+        ],
+        elements: [_element(id: 'elm')],
+      );
+      final idsBefore =
+          manifest.environmentPresets.map((p) => p.id).toList(growable: false);
+      final n = idsBefore.length;
+
+      await _pump(tester, manifest);
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-draft-field-id')),
+        'intruder',
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
+      expect(manifest.environmentPresets.length, n);
+      expect(
+        manifest.environmentPresets.map((p) => p.id).toList(growable: false),
+        idsBefore,
+      );
+      expect(find.byKey(const Key('environment-studio-preset-list')),
+          findsOneWidget);
+      expect(find.text('keep'), findsWidgets);
+    });
+
+    testWidgets('aucun Save / Create / Generate dans l’UI', (tester) async {
+      await _pump(
+        tester,
+        _manifest(
+          environmentPresets: [_preset(id: 'z')],
+          elements: [_element(id: 'elm')],
+        ),
+      );
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      expect(find.textContaining('Save'), findsNothing);
+      expect(find.textContaining('Create'), findsNothing);
+      expect(find.textContaining('Generate'), findsNothing);
+    });
+
+    testWidgets('catégorie optionnelle : champ vide', (tester) async {
+      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      expect(
+        (tester.widget<CupertinoTextField>(find
+                .byKey(const Key('environment-studio-draft-field-category'))))
+            .controller
+            ?.text,
+        '',
+      );
+    });
+  });
+}
+
+Future<void> _pump(WidgetTester tester, ProjectManifest manifest) async {
+  tester.view.physicalSize = const Size(900, 2000);
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
+    name: 'form-shell-test',
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

## 15. Diff complet

Le §14 regroupe déjà les diffs `git` des fichiers trackés modifiés et les diffs `/dev/null` des nouveaux fichiers sources.

## 16. Auto-review

- **Points solides** : séparation présentation / validation / formulaire ; tests de non-régression manifest ; pas de `knownTemplateIds` arbitraires dans l’UI ; validation continue sans bouton « Valider » superflu.
- **Points discutables** : le libellé zone palette (« État : aucune entrée… ») diverge légèrement du wording « Palette vide » du cahier pour éviter l’ambiguïté avec l’issue `emptyPalette` dans les tests ciblés sur la vue validation.
- **Corrections faites après auto-review** : `Wrap` pour les boutons ; `tester.view.physicalSize` dans les tests formulaire ; comparaison des ids de presets au lieu de `identical` sur la liste manifest.
- **Risques restants** : formulaire long — scroll utilisateur requis sur petits écrans réels ; bruit macOS `macos_ui` accent (warning Flutter) dans les tests UI.

**Regard critique sur le prompt (questions explicites)** :

- **« Préparer un preset » évite-t-il assez l’ambiguïté ?** Oui, couplé au badge « Brouillon local non sauvegardé » et au texte d’intro ; évite « Créer » / « Save » / « Generate ».
- **Fallait-il rendre les params éditables maintenant ?** Non pour ce shell V0 : aligné recommandation lot ; Lot 15 peut étendre sans bloquer la navigation browser/draft.
- **Formulaire trop limité sans éditeur de palette ?** Acceptable : l’issue `emptyPalette` reste visible ; Lot 14 cible explicitement l’édition palette.
- **Mode `browser` / `createDraft` suffisant ?** Oui pour un premier passage : pas besoin de pile d’écrans ni d’historique undo brouillon.
- **Sauvegarde / génération / mutation manifest évitées ?** Oui : pas d’upsert ni `buildEnvironmentPresetFromDraft` dans l’UI ; tests sur liste d’ids inchangée après retour.

## 17. Verdict

Statut du lot :

- [x] Validé

Résumé :

```
Shell formulaire brouillon + validation FR + tests (68 tests environment_studio) ; analyse sans issue ; suite map_editor +901 -34 (dette préexistante hors lot, non corrigée dans ce lot).
```

Prochain lot recommandé :

```
Environment-14 — Environment Preset Palette Draft Editor V0
```
