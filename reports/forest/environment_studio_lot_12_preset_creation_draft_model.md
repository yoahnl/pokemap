# Environment Studio Lot 12 — Environment Preset Creation Draft Model V0

## 1. Résumé exécutif

Introduction d’un modèle **pur Dart** (`environment_preset_draft.dart`) dans `map_editor` : brouillons immuables pour paramètres, items de palette et preset complet ; validation auteur `validateEnvironmentPresetDraft` avec rapport typé ; conversion `buildEnvironmentPresetFromDraft` déléguée aux factories `map_core` (sans manifest). Aucune UI, aucune mutation de `ProjectManifest`, aucun changement `map_core`.

## 2. Périmètre du lot

- Fichiers autorisés uniquement : `environment_preset_draft.dart`, `environment_preset_draft_test.dart`, ce rapport.
- Pas de Flutter dans le module draft ; pas de provider / repository / persistance.

## 3. Audit initial du modèle EnvironmentPreset existant

Fichiers relus (audit) :

- `packages/map_core/lib/src/models/environment.dart` — `EnvironmentPreset` et `EnvironmentPaletteItem` valident à la construction (id/nom/template non vides, catégorie non vide si fournie, palette non vide, `elementId` non vide, `weight >= 1`, tags non vides après trim, pas de doublons d’`elementId` dans la palette). `EnvironmentGenerationParams` : intervalles unitaires et `minSpacingCells >= 0`.
- `packages/map_core/lib/src/operations/project_manifest_environment_preset_operations.dart` — upsert / unicité des ids côté manifest.
- `packages/map_core/lib/src/operations/environment_preset_diagnostics.dart` — diagnostics runtime preset (hors scope draft, mais cohérence des ids / templates).
- Fichiers `map_editor` Environment Studio (panel, widgets, tests) — patterns de tests avec `ProjectManifest` + `ProjectElementEntry` minimal.

Conclusion : le **formulaire** doit accepter des états invalides ; la **conversion** vers `EnvironmentPreset` reste stricte via `map_core`.

## 4. Décisions de modélisation du brouillon

- Placer le draft dans **map_editor** (couche auteur / UI future), pas dans `map_core`, pour ne pas diluer le contrat sérialisable ni importer des notions de formulaire dans le cœur.
- Validations draft **redondantes** avec `map_core` pour l’UX (messages stables) ; `buildEnvironmentPresetFromDraft` ne refait pas le manifest.
- `existingPresetId` : comparaison avec `preset.id == existingKey` pour ignorer le doublon « soi-même » en édition ; chaîne vide / whitespace seule ⇒ traité comme création.
- Tags vides : pas de filtrage silencieux ; `build` laisse `EnvironmentPaletteItem` lever.

## 5. Types de brouillon ajoutés

- `EnvironmentGenerationParamsDraft` — `const` + `standard()` aligné sur `EnvironmentGenerationParams.standard()`, `copyWith`, `==` / `hashCode`.
- `EnvironmentPaletteItemDraft` — constructeur public avec tags copiés en `Set.unmodifiable`.
- `EnvironmentPresetDraft` — factory avec copie défensive de la liste ; `empty()`, `fromPreset()`, `copyWith` avec `clearCategoryId`.

## 6. Validation du brouillon

- `EnvironmentPresetDraftIssueSeverity` / `Kind` / `Issue` / `ValidationReport` avec listes non modifiables.
- `validateEnvironmentPresetDraft` : ordre stable (champs globaux → `duplicateId` → `unknownTemplateId` warning → `emptyPalette` → items).
- `unknownTemplateId` en **warning** si `knownTemplateIds` non vide et template absent du set.

## 7. Conversion vers EnvironmentPreset

- `buildEnvironmentPresetFromDraft` : trim ; `ArgumentError` explicite si `id` vide après trim ou `categoryId` fourni mais vide après trim ; sinon délégation à `EnvironmentPaletteItem`, `EnvironmentGenerationParams`, `EnvironmentPreset`.

## 8. Pourquoi aucune UI / sauvegarde / génération dans ce lot

Alignement roadmap : Lot 12 = modèle + validation ; Lots 13+ brancheront le formulaire et l’upsert manifest.

## 9. Fichiers modifiés

- `packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_draft.dart` (nouveau)
- `packages/map_editor/test/environment_studio/environment_preset_draft_test.dart` (nouveau)
- `reports/forest/environment_studio_lot_12_preset_creation_draft_model.md` (ce fichier)

## 10. Tests ajoutés

- Couverture demandée §11 du cahier des charges : drafts, validation (y compris `existingPresetId`, ordre, palette), `build`, rapport.

## 11. Commandes exécutées

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
dart format lib/src/features/environment_studio/authoring/environment_preset_draft.dart test/environment_studio/environment_preset_draft_test.dart
flutter analyze lib/src/features/environment_studio/authoring/environment_preset_draft.dart test/environment_studio/environment_preset_draft_test.dart
flutter test test/environment_studio/environment_preset_draft_test.dart --reporter expanded
flutter test test/environment_studio --reporter expanded
flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart --reporter expanded
flutter test 2>&1 | tail -n 3
```

## 12. Résultats des commandes

### dart format

```
Formatted 2 files (0 changed) in 0.02 seconds.

```

### flutter analyze

```
Analyzing 2 items...                                            
No issues found! (ran in 1.3s)

```

### flutter test (ciblé draft)

```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart
00:00 +0: EnvironmentGenerationParamsDraft standard s’aligne sur EnvironmentGenerationParams.standard()
00:00 +1: EnvironmentGenerationParamsDraft copyWith modifie chaque champ
00:00 +2: EnvironmentGenerationParamsDraft égalité de valeur
00:00 +3: EnvironmentPaletteItemDraft accepte elementId vide sans throw
00:00 +4: EnvironmentPaletteItemDraft accepte weight <= 0 sans throw
00:00 +5: EnvironmentPaletteItemDraft collisionMode par défaut
00:00 +6: EnvironmentPaletteItemDraft copie défensive tags et exposés immuables
00:00 +7: EnvironmentPaletteItemDraft copyWith modifie les champs
00:00 +8: EnvironmentPaletteItemDraft égalité indépendante de l’ordre des tags source
00:00 +9: EnvironmentPresetDraft empty crée un brouillon formulaire
00:00 +10: EnvironmentPresetDraft fromPreset conserve champs et convertit palette / params
00:00 +11: EnvironmentPresetDraft palette copiée défensivement et immuable
00:00 +12: EnvironmentPresetDraft copyWith et clearCategoryId
00:00 +13: EnvironmentPresetDraft égalité de valeur
00:00 +14: validateEnvironmentPresetDraft draft valide => aucune issue
00:00 +15: validateEnvironmentPresetDraft emptyId
00:00 +16: validateEnvironmentPresetDraft duplicateId en création
00:00 +17: validateEnvironmentPresetDraft duplicateId ignoré si existingPresetId identique
00:00 +18: validateEnvironmentPresetDraft duplicateId en édition avec renommage vers id occupé
00:00 +19: validateEnvironmentPresetDraft existingPresetId whitespace traité comme absent
00:00 +20: validateEnvironmentPresetDraft emptyName
00:00 +21: validateEnvironmentPresetDraft emptyTemplateId
00:00 +22: validateEnvironmentPresetDraft unknownTemplateId warning si knownTemplateIds non vide
00:00 +23: validateEnvironmentPresetDraft unknownTemplateId absent si knownTemplateIds vide
00:00 +24: validateEnvironmentPresetDraft emptyCategoryId si categoryId whitespace
00:00 +25: validateEnvironmentPresetDraft invalidDensity / variation / edgeDensity / minSpacingCells
00:00 +26: validateEnvironmentPresetDraft emptyPalette
00:00 +27: validateEnvironmentPresetDraft emptyPaletteElementId
00:00 +28: validateEnvironmentPresetDraft duplicatePaletteElementId sur le second item
00:00 +29: validateEnvironmentPresetDraft missingPaletteElement
00:00 +30: validateEnvironmentPresetDraft missingPaletteElement non produit si elementId vide
00:00 +31: validateEnvironmentPresetDraft invalidPaletteWeight
00:00 +32: validateEnvironmentPresetDraft emptyPaletteTag
00:00 +33: validateEnvironmentPresetDraft issuesForPaletteIndex et index négatif
00:00 +34: validateEnvironmentPresetDraft ordre stable des kinds (extrait)
00:00 +35: buildEnvironmentPresetFromDraft convertit un draft valide
00:00 +36: buildEnvironmentPresetFromDraft trim id / name / templateId / categoryId / elementId / tags
00:00 +37: buildEnvironmentPresetFromDraft lève si id vide après trim
00:00 +38: buildEnvironmentPresetFromDraft lève si tag vide après trim
00:00 +39: buildEnvironmentPresetFromDraft ne vérifie pas le manifest (duplicate accepté si map_core OK)
00:00 +40: EnvironmentPresetDraftValidationReport issues défensives / immuables / compteurs / égalité
00:00 +41: EnvironmentPresetDraftValidationReport hasErrors / hasWarnings
00:00 +42: EnvironmentPresetDraftValidationReport issuesForKind retourne non modifiable
00:00 +43: All tests passed!

```

### flutter test (régression `test/environment_studio`)

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
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart: EnvironmentStudioPanel ne propose aucun CupertinoButton dans le panneau
00:00 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart: EnvironmentStudioPanel — browser read-only read-only : pas de libellés Create / Edit / Delete / Generate / Save
00:03 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentGenerationParamsDraft standard s’aligne sur EnvironmentGenerationParams.standard()
00:03 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentGenerationParamsDraft copyWith modifie chaque champ
00:03 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentGenerationParamsDraft égalité de valeur
00:03 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentPaletteItemDraft accepte elementId vide sans throw
00:03 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentPaletteItemDraft accepte weight <= 0 sans throw
00:03 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentPaletteItemDraft collisionMode par défaut
00:03 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentPaletteItemDraft copie défensive tags et exposés immuables
00:03 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentPaletteItemDraft copyWith modifie les champs
00:03 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentPaletteItemDraft égalité indépendante de l’ordre des tags source
00:03 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentPresetDraft empty crée un brouillon formulaire
00:03 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentPresetDraft fromPreset conserve champs et convertit palette / params
00:03 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentPresetDraft palette copiée défensivement et immuable
00:03 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentPresetDraft copyWith et clearCategoryId
00:03 +24: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentPresetDraft égalité de valeur
00:03 +25: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: validateEnvironmentPresetDraft draft valide => aucune issue
00:03 +26: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: validateEnvironmentPresetDraft emptyId
00:03 +27: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: validateEnvironmentPresetDraft duplicateId en création
00:03 +28: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: validateEnvironmentPresetDraft duplicateId ignoré si existingPresetId identique
00:03 +29: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: validateEnvironmentPresetDraft duplicateId en édition avec renommage vers id occupé
00:03 +30: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: validateEnvironmentPresetDraft existingPresetId whitespace traité comme absent
00:03 +31: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: validateEnvironmentPresetDraft emptyName
00:03 +32: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: validateEnvironmentPresetDraft emptyTemplateId
00:03 +33: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: validateEnvironmentPresetDraft unknownTemplateId warning si knownTemplateIds non vide
00:03 +34: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: validateEnvironmentPresetDraft unknownTemplateId absent si knownTemplateIds vide
00:03 +35: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: validateEnvironmentPresetDraft emptyCategoryId si categoryId whitespace
00:03 +36: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: validateEnvironmentPresetDraft invalidDensity / variation / edgeDensity / minSpacingCells
00:03 +37: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: validateEnvironmentPresetDraft emptyPalette
00:03 +38: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: validateEnvironmentPresetDraft emptyPaletteElementId
00:03 +39: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: validateEnvironmentPresetDraft duplicatePaletteElementId sur le second item
00:03 +40: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: validateEnvironmentPresetDraft missingPaletteElement
00:03 +41: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: validateEnvironmentPresetDraft missingPaletteElement non produit si elementId vide
00:03 +42: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: validateEnvironmentPresetDraft invalidPaletteWeight
00:03 +43: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: validateEnvironmentPresetDraft emptyPaletteTag
00:03 +44: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: validateEnvironmentPresetDraft issuesForPaletteIndex et index négatif
00:03 +45: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: validateEnvironmentPresetDraft ordre stable des kinds (extrait)
00:03 +46: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: buildEnvironmentPresetFromDraft convertit un draft valide
00:03 +47: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: buildEnvironmentPresetFromDraft trim id / name / templateId / categoryId / elementId / tags
00:03 +48: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: buildEnvironmentPresetFromDraft lève si id vide après trim
00:03 +49: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: buildEnvironmentPresetFromDraft lève si tag vide après trim
00:03 +50: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: buildEnvironmentPresetFromDraft ne vérifie pas le manifest (duplicate accepté si map_core OK)
00:03 +51: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentPresetDraftValidationReport issues défensives / immuables / compteurs / égalité
00:03 +52: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentPresetDraftValidationReport hasErrors / hasWarnings
00:03 +53: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_draft_test.dart: EnvironmentPresetDraftValidationReport issuesForKind retourne non modifiable
00:03 +54: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:03 +55: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace affiche le message projet absent sans manifest
00:03 +56: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace le project explorer ouvre Environment Studio au tap (clé dédiée)
00:04 +57: All tests passed!

```

### flutter test (régressions workspace / toolbar)

```
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

### flutter test (suite complète `map_editor`, dernières lignes)

```

01:00 +889 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: ... pokemon data root for both the items catalog and local sprite assets   
01:00 +889 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: load use case reads the synced catalog after a real sync                   
01:00 +889 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: load use case reads the synced catalog after a real sync                   
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/items_catalog_sync_MUrKtY/project.json

01:00 +890 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: load use case reads the synced catalog after a real sync                   
01:00 +890 -34: Some tests failed.                                                                                                                                                                     

```

## 13. Git status initial et final

**Preuve absence au commit HEAD** (les chemins Lot 12 n’étaient pas versionnés) :

```
fatal: path 'packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_draft.dart' exists on disk, but not in 'HEAD'
exit:128
```

**État final** (`git status --short --untracked-files=all` à la racine après rédaction du rapport) :

```
?? packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_draft.dart
?? packages/map_editor/test/environment_studio/environment_preset_draft_test.dart

```

### Confirmations Evidence Pack

- Aucun `ProjectManifest` modifié (aucun fichier manifest / opérations manifest dans ce lot).
- Aucun `MapLayer` modifié.
- Aucune UI de création `EnvironmentPreset` ajoutée.
- Aucun générateur créé.
- Aucune sauvegarde disque créée par ce lot.
- Aucun `build_runner` lancé.
- Aucun fichier généré modifié.
- Aucun `git commit` / `git add` / `git push` / `git reset` / `git checkout` / `git restore` / `git stash` / merge / rebase / tag.

## 14. Contenu complet des fichiers créés ou modifiés

### `packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_draft.dart`

```dart
import 'package:map_core/map_core.dart';

// ---------------------------------------------------------------------------
// Generation params draft
// ---------------------------------------------------------------------------

/// Brouillon des paramètres de génération : valeurs hors bornes autorisées
/// jusqu’à [validateEnvironmentPresetDraft].
final class EnvironmentGenerationParamsDraft {
  const EnvironmentGenerationParamsDraft({
    required this.density,
    required this.variation,
    required this.edgeDensity,
    required this.minSpacingCells,
  });

  /// Aligné sur [EnvironmentGenerationParams.standard] (map_core).
  factory EnvironmentGenerationParamsDraft.standard() {
    final s = EnvironmentGenerationParams.standard();
    return EnvironmentGenerationParamsDraft(
      density: s.density,
      variation: s.variation,
      edgeDensity: s.edgeDensity,
      minSpacingCells: s.minSpacingCells,
    );
  }

  final double density;
  final double variation;
  final double edgeDensity;
  final int minSpacingCells;

  EnvironmentGenerationParamsDraft copyWith({
    double? density,
    double? variation,
    double? edgeDensity,
    int? minSpacingCells,
  }) {
    return EnvironmentGenerationParamsDraft(
      density: density ?? this.density,
      variation: variation ?? this.variation,
      edgeDensity: edgeDensity ?? this.edgeDensity,
      minSpacingCells: minSpacingCells ?? this.minSpacingCells,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentGenerationParamsDraft &&
            density == other.density &&
            variation == other.variation &&
            edgeDensity == other.edgeDensity &&
            minSpacingCells == other.minSpacingCells;
  }

  @override
  int get hashCode =>
      Object.hash(density, variation, edgeDensity, minSpacingCells);
}

// ---------------------------------------------------------------------------
// Palette item draft
// ---------------------------------------------------------------------------

/// Item de palette en cours de saisie (états invalides permis).
final class EnvironmentPaletteItemDraft {
  EnvironmentPaletteItemDraft({
    required this.elementId,
    required this.weight,
    this.collisionMode = EnvironmentCollisionMode.useElementDefault,
    Set<String> tags = const <String>{},
  }) : tags = Set.unmodifiable(Set<String>.from(tags));

  final String elementId;
  final int weight;
  final EnvironmentCollisionMode collisionMode;

  /// Copie défensive à la construction ; exposé immuable.
  final Set<String> tags;

  EnvironmentPaletteItemDraft copyWith({
    String? elementId,
    int? weight,
    EnvironmentCollisionMode? collisionMode,
    Set<String>? tags,
  }) {
    final nextTags =
        tags != null ? Set<String>.from(tags) : Set<String>.from(this.tags);
    return EnvironmentPaletteItemDraft(
      elementId: elementId ?? this.elementId,
      weight: weight ?? this.weight,
      collisionMode: collisionMode ?? this.collisionMode,
      tags: nextTags,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentPaletteItemDraft &&
            elementId == other.elementId &&
            weight == other.weight &&
            collisionMode == other.collisionMode &&
            _setEquals(tags, other.tags);
  }

  @override
  int get hashCode {
    final sorted = tags.toList()..sort();
    return Object.hash(
      elementId,
      weight,
      collisionMode,
      Object.hashAll(sorted),
    );
  }
}

// ---------------------------------------------------------------------------
// Preset draft
// ---------------------------------------------------------------------------

/// Brouillon complet de preset Environment (création / future édition).
final class EnvironmentPresetDraft {
  factory EnvironmentPresetDraft({
    required String id,
    required String name,
    required String templateId,
    required List<EnvironmentPaletteItemDraft> palette,
    required EnvironmentGenerationParamsDraft defaultParams,
    String? categoryId,
    int sortOrder = 0,
  }) {
    return EnvironmentPresetDraft._(
      id: id,
      name: name,
      templateId: templateId,
      palette: List<EnvironmentPaletteItemDraft>.unmodifiable(
        List<EnvironmentPaletteItemDraft>.from(palette),
      ),
      defaultParams: defaultParams,
      categoryId: categoryId,
      sortOrder: sortOrder,
    );
  }

  factory EnvironmentPresetDraft.empty() {
    return EnvironmentPresetDraft(
      id: '',
      name: '',
      templateId: '',
      palette: const [],
      defaultParams: EnvironmentGenerationParamsDraft.standard(),
      categoryId: null,
      sortOrder: 0,
    );
  }

  factory EnvironmentPresetDraft.fromPreset(EnvironmentPreset preset) {
    return EnvironmentPresetDraft(
      id: preset.id,
      name: preset.name,
      templateId: preset.templateId,
      palette: [
        for (final item in preset.palette)
          EnvironmentPaletteItemDraft(
            elementId: item.elementId,
            weight: item.weight,
            collisionMode: item.collisionMode,
            tags: item.tags,
          ),
      ],
      defaultParams: EnvironmentGenerationParamsDraft(
        density: preset.defaultParams.density,
        variation: preset.defaultParams.variation,
        edgeDensity: preset.defaultParams.edgeDensity,
        minSpacingCells: preset.defaultParams.minSpacingCells,
      ),
      categoryId: preset.categoryId,
      sortOrder: preset.sortOrder,
    );
  }

  const EnvironmentPresetDraft._({
    required this.id,
    required this.name,
    required this.templateId,
    required this.palette,
    required this.defaultParams,
    required this.categoryId,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String templateId;

  /// Copie défensive ; liste immuable.
  final List<EnvironmentPaletteItemDraft> palette;

  final EnvironmentGenerationParamsDraft defaultParams;
  final String? categoryId;
  final int sortOrder;

  EnvironmentPresetDraft copyWith({
    String? id,
    String? name,
    String? templateId,
    List<EnvironmentPaletteItemDraft>? palette,
    EnvironmentGenerationParamsDraft? defaultParams,
    String? categoryId,
    bool clearCategoryId = false,
    int? sortOrder,
  }) {
    final nextCategory =
        clearCategoryId ? null : (categoryId ?? this.categoryId);
    return EnvironmentPresetDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      templateId: templateId ?? this.templateId,
      palette: palette ?? this.palette,
      defaultParams: defaultParams ?? this.defaultParams,
      categoryId: nextCategory,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentPresetDraft &&
            id == other.id &&
            name == other.name &&
            templateId == other.templateId &&
            _listEquals(palette, other.palette) &&
            defaultParams == other.defaultParams &&
            categoryId == other.categoryId &&
            sortOrder == other.sortOrder;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        templateId,
        Object.hashAll(palette),
        defaultParams,
        categoryId,
        sortOrder,
      );
}

// ---------------------------------------------------------------------------
// Validation — issues
// ---------------------------------------------------------------------------

enum EnvironmentPresetDraftIssueSeverity {
  error,
  warning,
}

enum EnvironmentPresetDraftIssueKind {
  emptyId,
  duplicateId,
  emptyName,
  emptyTemplateId,
  unknownTemplateId,
  emptyPalette,
  emptyPaletteElementId,
  duplicatePaletteElementId,
  missingPaletteElement,
  invalidPaletteWeight,
  emptyPaletteTag,
  invalidDensity,
  invalidVariation,
  invalidEdgeDensity,
  invalidMinSpacingCells,
  emptyCategoryId,
}

final class EnvironmentPresetDraftIssue {
  const EnvironmentPresetDraftIssue({
    required this.severity,
    required this.kind,
    required this.message,
    this.presetId,
    this.elementId,
    this.templateId,
    this.paletteIndex,
    this.tag,
  });

  final EnvironmentPresetDraftIssueSeverity severity;
  final EnvironmentPresetDraftIssueKind kind;
  final String message;
  final String? presetId;
  final String? elementId;
  final String? templateId;
  final int? paletteIndex;
  final String? tag;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentPresetDraftIssue &&
            severity == other.severity &&
            kind == other.kind &&
            message == other.message &&
            presetId == other.presetId &&
            elementId == other.elementId &&
            templateId == other.templateId &&
            paletteIndex == other.paletteIndex &&
            tag == other.tag;
  }

  @override
  int get hashCode => Object.hash(
        severity,
        kind,
        message,
        presetId,
        elementId,
        templateId,
        paletteIndex,
        tag,
      );
}

// ---------------------------------------------------------------------------
// Validation — report
// ---------------------------------------------------------------------------

final class EnvironmentPresetDraftValidationReport {
  factory EnvironmentPresetDraftValidationReport({
    required List<EnvironmentPresetDraftIssue> issues,
  }) {
    return EnvironmentPresetDraftValidationReport._(
      issues: List<EnvironmentPresetDraftIssue>.unmodifiable(
        List<EnvironmentPresetDraftIssue>.from(issues),
      ),
    );
  }

  const EnvironmentPresetDraftValidationReport._({required this.issues});

  final List<EnvironmentPresetDraftIssue> issues;

  bool get hasIssues => issues.isNotEmpty;

  bool get hasErrors => issues
      .any((i) => i.severity == EnvironmentPresetDraftIssueSeverity.error);

  bool get hasWarnings => issues.any(
        (i) => i.severity == EnvironmentPresetDraftIssueSeverity.warning,
      );

  int get issueCount => issues.length;

  int get errorCount => issues
      .where((i) => i.severity == EnvironmentPresetDraftIssueSeverity.error)
      .length;

  int get warningCount => issues
      .where((i) => i.severity == EnvironmentPresetDraftIssueSeverity.warning)
      .length;

  List<EnvironmentPresetDraftIssue> issuesForKind(
    EnvironmentPresetDraftIssueKind kind,
  ) {
    return List<EnvironmentPresetDraftIssue>.unmodifiable(
      [
        for (final i in issues)
          if (i.kind == kind) i
      ],
    );
  }

  List<EnvironmentPresetDraftIssue> issuesForPaletteIndex(int index) {
    if (index < 0) {
      return const [];
    }
    return List<EnvironmentPresetDraftIssue>.unmodifiable(
      [
        for (final i in issues)
          if (i.paletteIndex == index) i
      ],
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentPresetDraftValidationReport &&
            _listEquals(issues, other.issues);
  }

  @override
  int get hashCode => Object.hashAll(issues);
}

// ---------------------------------------------------------------------------
// validateEnvironmentPresetDraft
// ---------------------------------------------------------------------------

/// Valide un [EnvironmentPresetDraft] contre un manifest et options auteur.
///
/// [existingPresetId] trimé : en édition, le preset portant cet id ne provoque
/// pas [EnvironmentPresetDraftIssueKind.duplicateId] pour lui-même.
EnvironmentPresetDraftValidationReport validateEnvironmentPresetDraft(
  EnvironmentPresetDraft draft, {
  required ProjectManifest manifest,
  Set<String> knownTemplateIds = const <String>{},
  String? existingPresetId,
}) {
  final issues = <EnvironmentPresetDraftIssue>[];
  final trimmedExisting = existingPresetId?.trim();

  void add(EnvironmentPresetDraftIssue issue) {
    issues.add(issue);
  }

  // --- 1. Champs globaux (ordre stable) ---
  final tid = draft.id.trim();
  if (tid.isEmpty) {
    add(const EnvironmentPresetDraftIssue(
      severity: EnvironmentPresetDraftIssueSeverity.error,
      kind: EnvironmentPresetDraftIssueKind.emptyId,
      message: 'Environment preset draft id is empty.',
    ));
  }

  final tname = draft.name.trim();
  if (tname.isEmpty) {
    add(const EnvironmentPresetDraftIssue(
      severity: EnvironmentPresetDraftIssueSeverity.error,
      kind: EnvironmentPresetDraftIssueKind.emptyName,
      message: 'Environment preset draft name is empty.',
    ));
  }

  final ttemplate = draft.templateId.trim();
  if (ttemplate.isEmpty) {
    add(const EnvironmentPresetDraftIssue(
      severity: EnvironmentPresetDraftIssueSeverity.error,
      kind: EnvironmentPresetDraftIssueKind.emptyTemplateId,
      message: 'Environment preset draft templateId is empty.',
    ));
  }

  if (draft.categoryId != null) {
    final c = draft.categoryId!.trim();
    if (c.isEmpty) {
      add(const EnvironmentPresetDraftIssue(
        severity: EnvironmentPresetDraftIssueSeverity.error,
        kind: EnvironmentPresetDraftIssueKind.emptyCategoryId,
        message: 'Environment preset draft categoryId is empty.',
      ));
    }
  }

  final p = draft.defaultParams;
  if (p.density < 0.0 || p.density > 1.0) {
    add(const EnvironmentPresetDraftIssue(
      severity: EnvironmentPresetDraftIssueSeverity.error,
      kind: EnvironmentPresetDraftIssueKind.invalidDensity,
      message: 'Environment preset draft density must be between 0.0 and 1.0.',
    ));
  }
  if (p.variation < 0.0 || p.variation > 1.0) {
    add(const EnvironmentPresetDraftIssue(
      severity: EnvironmentPresetDraftIssueSeverity.error,
      kind: EnvironmentPresetDraftIssueKind.invalidVariation,
      message:
          'Environment preset draft variation must be between 0.0 and 1.0.',
    ));
  }
  if (p.edgeDensity < 0.0 || p.edgeDensity > 1.0) {
    add(const EnvironmentPresetDraftIssue(
      severity: EnvironmentPresetDraftIssueSeverity.error,
      kind: EnvironmentPresetDraftIssueKind.invalidEdgeDensity,
      message:
          'Environment preset draft edgeDensity must be between 0.0 and 1.0.',
    ));
  }
  if (p.minSpacingCells < 0) {
    add(const EnvironmentPresetDraftIssue(
      severity: EnvironmentPresetDraftIssueSeverity.error,
      kind: EnvironmentPresetDraftIssueKind.invalidMinSpacingCells,
      message: 'Environment preset draft minSpacingCells must be >= 0.',
    ));
  }

  // --- 2. duplicateId ---
  final existingKey = (trimmedExisting != null && trimmedExisting.isNotEmpty)
      ? trimmedExisting
      : null;
  if (tid.isNotEmpty) {
    var duplicate = false;
    for (final preset in manifest.environmentPresets) {
      if (preset.id != tid) {
        continue;
      }
      if (existingKey != null && preset.id == existingKey) {
        continue;
      }
      duplicate = true;
      break;
    }
    if (duplicate) {
      add(EnvironmentPresetDraftIssue(
        severity: EnvironmentPresetDraftIssueSeverity.error,
        kind: EnvironmentPresetDraftIssueKind.duplicateId,
        message:
            'Environment preset draft id duplicates existing preset "$tid".',
        presetId: tid,
      ));
    }
  }

  // --- 3. unknownTemplateId (warning) ---
  if (knownTemplateIds.isNotEmpty && ttemplate.isNotEmpty) {
    if (!knownTemplateIds.contains(ttemplate)) {
      add(EnvironmentPresetDraftIssue(
        severity: EnvironmentPresetDraftIssueSeverity.warning,
        kind: EnvironmentPresetDraftIssueKind.unknownTemplateId,
        message:
            'Environment preset draft templateId "$ttemplate" is not in knownTemplateIds.',
        templateId: ttemplate,
      ));
    }
  }

  // --- 4. emptyPalette ---
  if (draft.palette.isEmpty) {
    add(const EnvironmentPresetDraftIssue(
      severity: EnvironmentPresetDraftIssueSeverity.error,
      kind: EnvironmentPresetDraftIssueKind.emptyPalette,
      message: 'Environment preset draft palette is empty.',
    ));
  }

  // --- 5. Items palette (ordre des index) ---
  final elementsById = <String, ProjectElementEntry>{
    for (final e in manifest.elements) e.id: e,
  };

  final seenElementIds = <String, int>{};
  for (var i = 0; i < draft.palette.length; i++) {
    final item = draft.palette[i];
    final eid = item.elementId.trim();

    if (eid.isEmpty) {
      add(EnvironmentPresetDraftIssue(
        severity: EnvironmentPresetDraftIssueSeverity.error,
        kind: EnvironmentPresetDraftIssueKind.emptyPaletteElementId,
        message: 'Environment preset draft palette item has empty elementId.',
        paletteIndex: i,
      ));
    } else {
      if (seenElementIds.containsKey(eid)) {
        add(EnvironmentPresetDraftIssue(
          severity: EnvironmentPresetDraftIssueSeverity.error,
          kind: EnvironmentPresetDraftIssueKind.duplicatePaletteElementId,
          message:
              'Environment preset draft palette duplicate elementId "$eid" at index $i.',
          elementId: eid,
          paletteIndex: i,
        ));
      } else {
        seenElementIds[eid] = i;
      }

      if (!elementsById.containsKey(eid)) {
        add(EnvironmentPresetDraftIssue(
          severity: EnvironmentPresetDraftIssueSeverity.error,
          kind: EnvironmentPresetDraftIssueKind.missingPaletteElement,
          message:
              'Environment preset draft palette references missing element "$eid".',
          elementId: eid,
          paletteIndex: i,
        ));
      }
    }

    if (item.weight <= 0) {
      add(EnvironmentPresetDraftIssue(
        severity: EnvironmentPresetDraftIssueSeverity.error,
        kind: EnvironmentPresetDraftIssueKind.invalidPaletteWeight,
        message:
            'Environment preset draft palette item weight must be >= 1 (index $i).',
        elementId: eid.isEmpty ? null : eid,
        paletteIndex: i,
      ));
    }

    for (final rawTag in item.tags) {
      if (rawTag.trim().isEmpty) {
        add(EnvironmentPresetDraftIssue(
          severity: EnvironmentPresetDraftIssueSeverity.error,
          kind: EnvironmentPresetDraftIssueKind.emptyPaletteTag,
          message:
              'Environment preset draft palette item has empty tag (index $i).',
          elementId: eid.isEmpty ? null : eid,
          paletteIndex: i,
          tag: rawTag,
        ));
      }
    }
  }

  return EnvironmentPresetDraftValidationReport(issues: issues);
}

// ---------------------------------------------------------------------------
// buildEnvironmentPresetFromDraft
// ---------------------------------------------------------------------------

/// Construit un [EnvironmentPreset] map_core à partir d’un brouillon valide.
///
/// Ne consulte pas le manifest : appeler [validateEnvironmentPresetDraft]
/// avant une persistance. Lève [ArgumentError] si les constructeurs map_core
/// rejettent les données (id vide, tag vide, etc.) — pas de filtrage silencieux
/// des tags vides.
EnvironmentPreset buildEnvironmentPresetFromDraft(
  EnvironmentPresetDraft draft,
) {
  final nid = draft.id.trim();
  if (nid.isEmpty) {
    throw ArgumentError.value(
      draft.id,
      'draft.id',
      'buildEnvironmentPresetFromDraft: id cannot be empty after trim.',
    );
  }
  final nname = draft.name.trim();
  final ntemplate = draft.templateId.trim();
  final String? cat;
  if (draft.categoryId == null) {
    cat = null;
  } else {
    final c = draft.categoryId!.trim();
    if (c.isEmpty) {
      throw ArgumentError.value(
        draft.categoryId,
        'draft.categoryId',
        'buildEnvironmentPresetFromDraft: categoryId cannot be empty after trim.',
      );
    }
    cat = c;
  }

  final palette = <EnvironmentPaletteItem>[
    for (final d in draft.palette)
      EnvironmentPaletteItem(
        elementId: d.elementId.trim(),
        weight: d.weight,
        collisionMode: d.collisionMode,
        tags: d.tags.map((t) => t.trim()).toSet(),
      ),
  ];

  final params = EnvironmentGenerationParams(
    density: draft.defaultParams.density,
    variation: draft.defaultParams.variation,
    edgeDensity: draft.defaultParams.edgeDensity,
    minSpacingCells: draft.defaultParams.minSpacingCells,
  );

  return EnvironmentPreset(
    id: nid,
    name: nname,
    templateId: ntemplate,
    palette: palette,
    defaultParams: params,
    categoryId: cat,
    sortOrder: draft.sortOrder,
  );
}

// --- helpers ---

bool _setEquals(Set<String> a, Set<String> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (final x in a) {
    if (!b.contains(x)) {
      return false;
    }
  }
  return true;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

```

### `packages/map_editor/test/environment_studio/environment_preset_draft_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/environment_studio/authoring/environment_preset_draft.dart';

void main() {
  group('EnvironmentGenerationParamsDraft', () {
    test('standard s’aligne sur EnvironmentGenerationParams.standard()', () {
      final d = EnvironmentGenerationParamsDraft.standard();
      final c = EnvironmentGenerationParams.standard();
      expect(d.density, c.density);
      expect(d.variation, c.variation);
      expect(d.edgeDensity, c.edgeDensity);
      expect(d.minSpacingCells, c.minSpacingCells);
    });

    test('copyWith modifie chaque champ', () {
      const base = EnvironmentGenerationParamsDraft(
        density: 0.1,
        variation: 0.2,
        edgeDensity: 0.3,
        minSpacingCells: 1,
      );
      expect(base.copyWith(density: 0.9).density, 0.9);
      expect(base.copyWith(variation: 0.8).variation, 0.8);
      expect(base.copyWith(edgeDensity: 0.7).edgeDensity, 0.7);
      expect(base.copyWith(minSpacingCells: 42).minSpacingCells, 42);
    });

    test('égalité de valeur', () {
      const a = EnvironmentGenerationParamsDraft(
        density: 0.5,
        variation: 0.5,
        edgeDensity: 0.5,
        minSpacingCells: 0,
      );
      const b = EnvironmentGenerationParamsDraft(
        density: 0.5,
        variation: 0.5,
        edgeDensity: 0.5,
        minSpacingCells: 0,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('EnvironmentPaletteItemDraft', () {
    test('accepte elementId vide sans throw', () {
      expect(
        () => EnvironmentPaletteItemDraft(elementId: '', weight: 0),
        returnsNormally,
      );
    });

    test('accepte weight <= 0 sans throw', () {
      expect(
        () => EnvironmentPaletteItemDraft(elementId: 'a', weight: 0),
        returnsNormally,
      );
    });

    test('collisionMode par défaut', () {
      final d = EnvironmentPaletteItemDraft(elementId: 'x', weight: 1);
      expect(d.collisionMode, EnvironmentCollisionMode.useElementDefault);
    });

    test('copie défensive tags et exposés immuables', () {
      final raw = {'a', 'b'};
      final d = EnvironmentPaletteItemDraft(
        elementId: 'e',
        weight: 1,
        tags: raw,
      );
      raw.add('c');
      expect(d.tags, {'a', 'b'});
      expect(() => (d.tags as dynamic).add('z'), throwsA(anything));
    });

    test('copyWith modifie les champs', () {
      final d = EnvironmentPaletteItemDraft(
        elementId: 'e',
        weight: 1,
        tags: {'t'},
      );
      final n = d.copyWith(
        elementId: 'f',
        weight: 2,
        collisionMode: EnvironmentCollisionMode.forceDisabled,
        tags: {'u'},
      );
      expect(n.elementId, 'f');
      expect(n.weight, 2);
      expect(n.collisionMode, EnvironmentCollisionMode.forceDisabled);
      expect(n.tags, {'u'});
    });

    test('égalité indépendante de l’ordre des tags source', () {
      final a = EnvironmentPaletteItemDraft(
        elementId: 'e',
        weight: 1,
        tags: {'z', 'a'},
      );
      final b = EnvironmentPaletteItemDraft(
        elementId: 'e',
        weight: 1,
        tags: {'a', 'z'},
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('EnvironmentPresetDraft', () {
    test('empty crée un brouillon formulaire', () {
      final d = EnvironmentPresetDraft.empty();
      expect(d.id, '');
      expect(d.name, '');
      expect(d.templateId, '');
      expect(d.palette, isEmpty);
      expect(d.categoryId, isNull);
      expect(d.sortOrder, 0);
      expect(
        d.defaultParams,
        EnvironmentGenerationParamsDraft.standard(),
      );
    });

    test('fromPreset conserve champs et convertit palette / params', () {
      final preset = EnvironmentPreset(
        id: 'p1',
        name: 'N',
        templateId: 'tpl',
        palette: [
          EnvironmentPaletteItem(
            elementId: 'oak',
            weight: 2,
            collisionMode: EnvironmentCollisionMode.forceEnabled,
            tags: {'a', 'b'},
          ),
        ],
        defaultParams: EnvironmentGenerationParams(
          density: 0.2,
          variation: 0.3,
          edgeDensity: 0.4,
          minSpacingCells: 3,
        ),
        categoryId: 'cat',
        sortOrder: 7,
      );
      final d = EnvironmentPresetDraft.fromPreset(preset);
      expect(d.id, 'p1');
      expect(d.name, 'N');
      expect(d.templateId, 'tpl');
      expect(d.categoryId, 'cat');
      expect(d.sortOrder, 7);
      expect(d.palette.length, 1);
      expect(d.palette.single.elementId, 'oak');
      expect(d.palette.single.weight, 2);
      expect(d.palette.single.collisionMode,
          EnvironmentCollisionMode.forceEnabled);
      expect(d.palette.single.tags, {'a', 'b'});
      expect(d.defaultParams.density, 0.2);
      expect(d.defaultParams.minSpacingCells, 3);
    });

    test('palette copiée défensivement et immuable', () {
      final item = EnvironmentPaletteItemDraft(elementId: 'e', weight: 1);
      final list = [item];
      final d = EnvironmentPresetDraft(
        id: 'a',
        name: 'b',
        templateId: 'c',
        palette: list,
        defaultParams: EnvironmentGenerationParamsDraft.standard(),
      );
      list.add(EnvironmentPaletteItemDraft(elementId: 'x', weight: 1));
      expect(d.palette.length, 1);
      expect(() => (d.palette as dynamic).add(item), throwsA(anything));
    });

    test('copyWith et clearCategoryId', () {
      final d = EnvironmentPresetDraft(
        id: 'i',
        name: 'n',
        templateId: 't',
        palette: [
          EnvironmentPaletteItemDraft(elementId: 'e', weight: 1),
        ],
        defaultParams: EnvironmentGenerationParamsDraft.standard(),
        categoryId: 'old',
      );
      final cleared = d.copyWith(clearCategoryId: true);
      expect(cleared.categoryId, isNull);
      final updated = d.copyWith(categoryId: 'new');
      expect(updated.categoryId, 'new');
    });

    test('égalité de valeur', () {
      final a = _validDraft();
      final b = _validDraft();
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('validateEnvironmentPresetDraft', () {
    test('draft valide => aucune issue', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft(),
        manifest: _manifest(),
      );
      expect(r.hasIssues, isFalse);
      expect(r.issueCount, 0);
    });

    test('emptyId', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(id: '  '),
        manifest: _manifest(),
      );
      expect(
          r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyId), isNotEmpty);
    });

    test('duplicateId en création', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(id: 'existing'),
        manifest: _manifest(),
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.duplicateId),
        isNotEmpty,
      );
    });

    test('duplicateId ignoré si existingPresetId identique', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(id: 'existing'),
        manifest: _manifest(),
        existingPresetId: 'existing',
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.duplicateId),
        isEmpty,
      );
    });

    test('duplicateId en édition avec renommage vers id occupé', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(id: 'existing'),
        manifest: _manifest(),
        existingPresetId: 'other',
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.duplicateId),
        isNotEmpty,
      );
    });

    test('existingPresetId whitespace traité comme absent', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(id: 'existing'),
        manifest: _manifest(),
        existingPresetId: '   ',
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.duplicateId),
        isNotEmpty,
      );
    });

    test('emptyName', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(name: ''),
        manifest: _manifest(),
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyName),
        isNotEmpty,
      );
    });

    test('emptyTemplateId', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(templateId: '  '),
        manifest: _manifest(),
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyTemplateId),
        isNotEmpty,
      );
    });

    test('unknownTemplateId warning si knownTemplateIds non vide', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft(),
        manifest: _manifest(),
        knownTemplateIds: const {'other'},
      );
      final w =
          r.issuesForKind(EnvironmentPresetDraftIssueKind.unknownTemplateId);
      expect(w, isNotEmpty);
      expect(w.single.severity, EnvironmentPresetDraftIssueSeverity.warning);
    });

    test('unknownTemplateId absent si knownTemplateIds vide', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft(),
        manifest: _manifest(),
        knownTemplateIds: const {},
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.unknownTemplateId),
        isEmpty,
      );
    });

    test('emptyCategoryId si categoryId whitespace', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(categoryId: '  \t'),
        manifest: _manifest(),
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyCategoryId),
        isNotEmpty,
      );
    });

    test('invalidDensity / variation / edgeDensity / minSpacingCells', () {
      expect(
        validateEnvironmentPresetDraft(
          _validDraft().copyWith(
            defaultParams: const EnvironmentGenerationParamsDraft(
              density: -0.01,
              variation: 0.5,
              edgeDensity: 0.5,
              minSpacingCells: 0,
            ),
          ),
          manifest: _manifest(),
        ).issuesForKind(EnvironmentPresetDraftIssueKind.invalidDensity),
        isNotEmpty,
      );
      expect(
        validateEnvironmentPresetDraft(
          _validDraft().copyWith(
            defaultParams: const EnvironmentGenerationParamsDraft(
              density: 0.5,
              variation: 2,
              edgeDensity: 0.5,
              minSpacingCells: 0,
            ),
          ),
          manifest: _manifest(),
        ).issuesForKind(EnvironmentPresetDraftIssueKind.invalidVariation),
        isNotEmpty,
      );
      expect(
        validateEnvironmentPresetDraft(
          _validDraft().copyWith(
            defaultParams: const EnvironmentGenerationParamsDraft(
              density: 0.5,
              variation: 0.5,
              edgeDensity: -1,
              minSpacingCells: 0,
            ),
          ),
          manifest: _manifest(),
        ).issuesForKind(EnvironmentPresetDraftIssueKind.invalidEdgeDensity),
        isNotEmpty,
      );
      expect(
        validateEnvironmentPresetDraft(
          _validDraft().copyWith(
            defaultParams: const EnvironmentGenerationParamsDraft(
              density: 0.5,
              variation: 0.5,
              edgeDensity: 0.5,
              minSpacingCells: -1,
            ),
          ),
          manifest: _manifest(),
        ).issuesForKind(EnvironmentPresetDraftIssueKind.invalidMinSpacingCells),
        isNotEmpty,
      );
    });

    test('emptyPalette', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(palette: []),
        manifest: _manifest(),
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyPalette),
        isNotEmpty,
      );
    });

    test('emptyPaletteElementId', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(
          palette: [
            EnvironmentPaletteItemDraft(elementId: '  ', weight: 1),
          ],
        ),
        manifest: _manifest(),
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyPaletteElementId),
        isNotEmpty,
      );
    });

    test('duplicatePaletteElementId sur le second item', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(
          palette: [
            EnvironmentPaletteItemDraft(elementId: 'oak', weight: 1),
            EnvironmentPaletteItemDraft(elementId: 'oak', weight: 1),
          ],
        ),
        manifest: _manifest(),
      );
      final dup = r.issuesForKind(
        EnvironmentPresetDraftIssueKind.duplicatePaletteElementId,
      );
      expect(dup, isNotEmpty);
      expect(dup.single.paletteIndex, 1);
    });

    test('missingPaletteElement', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(
          palette: [
            EnvironmentPaletteItemDraft(elementId: 'ghost', weight: 1),
          ],
        ),
        manifest: _manifest(),
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.missingPaletteElement),
        isNotEmpty,
      );
    });

    test('missingPaletteElement non produit si elementId vide', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(
          palette: [
            EnvironmentPaletteItemDraft(elementId: '', weight: 1),
          ],
        ),
        manifest: _manifest(),
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.missingPaletteElement),
        isEmpty,
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyPaletteElementId),
        isNotEmpty,
      );
    });

    test('invalidPaletteWeight', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(
          palette: [
            EnvironmentPaletteItemDraft(elementId: 'oak', weight: 0),
          ],
        ),
        manifest: _manifest(),
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.invalidPaletteWeight),
        isNotEmpty,
      );
    });

    test('emptyPaletteTag', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(
          palette: [
            EnvironmentPaletteItemDraft(
              elementId: 'oak',
              weight: 1,
              tags: {'ok', '  '},
            ),
          ],
        ),
        manifest: _manifest(),
      );
      final tags =
          r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyPaletteTag);
      expect(tags, isNotEmpty);
      expect(tags.single.paletteIndex, 0);
    });

    test('issuesForPaletteIndex et index négatif', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(
          palette: [
            EnvironmentPaletteItemDraft(elementId: 'oak', weight: 0),
            EnvironmentPaletteItemDraft(elementId: 'oak', weight: 0),
          ],
        ),
        manifest: _manifest(),
      );
      expect(r.issuesForPaletteIndex(0), isNotEmpty);
      expect(r.issuesForPaletteIndex(1), isNotEmpty);
      expect(r.issuesForPaletteIndex(-1), isEmpty);
    });

    test('ordre stable des kinds (extrait)', () {
      final r = validateEnvironmentPresetDraft(
        EnvironmentPresetDraft(
          id: '',
          name: '',
          templateId: '',
          palette: [],
          defaultParams: const EnvironmentGenerationParamsDraft(
            density: -1,
            variation: -1,
            edgeDensity: -1,
            minSpacingCells: -1,
          ),
          categoryId: '  ',
        ),
        manifest: _manifest(),
        knownTemplateIds: const {'x'},
      );
      final kinds = [for (final i in r.issues) i.kind];
      expect(kinds.first, EnvironmentPresetDraftIssueKind.emptyId);
      expect(kinds[1], EnvironmentPresetDraftIssueKind.emptyName);
      expect(kinds[2], EnvironmentPresetDraftIssueKind.emptyTemplateId);
      expect(kinds[3], EnvironmentPresetDraftIssueKind.emptyCategoryId);
      expect(kinds[4], EnvironmentPresetDraftIssueKind.invalidDensity);
      expect(kinds[5], EnvironmentPresetDraftIssueKind.invalidVariation);
      expect(kinds[6], EnvironmentPresetDraftIssueKind.invalidEdgeDensity);
      expect(kinds[7], EnvironmentPresetDraftIssueKind.invalidMinSpacingCells);
      expect(kinds[8], EnvironmentPresetDraftIssueKind.emptyPalette);
    });
  });

  group('buildEnvironmentPresetFromDraft', () {
    test('convertit un draft valide', () {
      final draft = _validDraft();
      final p = buildEnvironmentPresetFromDraft(draft);
      expect(p.id, 'newPreset');
      expect(p.name, 'New');
      expect(p.templateId, 'forest_dense');
      expect(p.palette.single.elementId, 'oak');
    });

    test('trim id / name / templateId / categoryId / elementId / tags', () {
      final draft = EnvironmentPresetDraft(
        id: '  id1  ',
        name: '  N  ',
        templateId: '  tpl  ',
        palette: [
          EnvironmentPaletteItemDraft(
            elementId: '  oak  ',
            weight: 1,
            tags: {'  canopy  '},
          ),
        ],
        defaultParams: EnvironmentGenerationParamsDraft.standard(),
        categoryId: '  bio  ',
      );
      final p = buildEnvironmentPresetFromDraft(draft);
      expect(p.id, 'id1');
      expect(p.name, 'N');
      expect(p.templateId, 'tpl');
      expect(p.categoryId, 'bio');
      expect(p.palette.single.elementId, 'oak');
      expect(p.palette.single.tags, {'canopy'});
    });

    test('lève si id vide après trim', () {
      expect(
        () => buildEnvironmentPresetFromDraft(
          _validDraft().copyWith(id: '   '),
        ),
        throwsArgumentError,
      );
    });

    test('lève si tag vide après trim', () {
      expect(
        () => buildEnvironmentPresetFromDraft(
          _validDraft().copyWith(
            palette: [
              EnvironmentPaletteItemDraft(
                elementId: 'oak',
                weight: 1,
                tags: {' '},
              ),
            ],
          ),
        ),
        throwsArgumentError,
      );
    });

    test('ne vérifie pas le manifest (duplicate accepté si map_core OK)', () {
      final draft = _validDraft().copyWith(id: 'existing');
      final p = buildEnvironmentPresetFromDraft(draft);
      expect(p.id, 'existing');
    });
  });

  group('EnvironmentPresetDraftValidationReport', () {
    test('issues défensives / immuables / compteurs / égalité', () {
      final raw = <EnvironmentPresetDraftIssue>[
        const EnvironmentPresetDraftIssue(
          severity: EnvironmentPresetDraftIssueSeverity.error,
          kind: EnvironmentPresetDraftIssueKind.emptyId,
          message: 'm',
        ),
      ];
      final a = EnvironmentPresetDraftValidationReport(issues: raw);
      raw.add(
        const EnvironmentPresetDraftIssue(
          severity: EnvironmentPresetDraftIssueSeverity.warning,
          kind: EnvironmentPresetDraftIssueKind.unknownTemplateId,
          message: 'w',
        ),
      );
      expect(a.issueCount, 1);
      expect(() => a.issues.add(raw.first), throwsA(anything));

      final b = EnvironmentPresetDraftValidationReport(
        issues: [
          const EnvironmentPresetDraftIssue(
            severity: EnvironmentPresetDraftIssueSeverity.error,
            kind: EnvironmentPresetDraftIssueKind.emptyId,
            message: 'm',
          ),
        ],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('hasErrors / hasWarnings', () {
      final onlyErr = EnvironmentPresetDraftValidationReport(
        issues: [
          const EnvironmentPresetDraftIssue(
            severity: EnvironmentPresetDraftIssueSeverity.error,
            kind: EnvironmentPresetDraftIssueKind.emptyId,
            message: 'e',
          ),
        ],
      );
      expect(onlyErr.hasErrors, isTrue);
      expect(onlyErr.hasWarnings, isFalse);
      final onlyWarn = EnvironmentPresetDraftValidationReport(
        issues: [
          const EnvironmentPresetDraftIssue(
            severity: EnvironmentPresetDraftIssueSeverity.warning,
            kind: EnvironmentPresetDraftIssueKind.unknownTemplateId,
            message: 'w',
          ),
        ],
      );
      expect(onlyWarn.hasErrors, isFalse);
      expect(onlyWarn.hasWarnings, isTrue);
    });

    test('issuesForKind retourne non modifiable', () {
      final r = EnvironmentPresetDraftValidationReport(
        issues: [
          const EnvironmentPresetDraftIssue(
            severity: EnvironmentPresetDraftIssueSeverity.error,
            kind: EnvironmentPresetDraftIssueKind.emptyId,
            message: 'm',
          ),
        ],
      );
      final list = r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyId);
      expect(() => list.clear(), throwsA(anything));
    });
  });
}

// --- helpers ---

ProjectManifest _manifest() {
  return ProjectManifest(
    name: 'draft-test',
    maps: const [],
    tilesets: const [],
    environmentPresets: [
      EnvironmentPreset(
        id: 'existing',
        name: 'E',
        templateId: 't',
        palette: [
          EnvironmentPaletteItem(elementId: 'oak', weight: 1),
        ],
        defaultParams: EnvironmentGenerationParams.standard(),
        sortOrder: 0,
      ),
      EnvironmentPreset(
        id: 'other',
        name: 'O',
        templateId: 't',
        palette: [
          EnvironmentPaletteItem(elementId: 'oak', weight: 1),
        ],
        defaultParams: EnvironmentGenerationParams.standard(),
        sortOrder: 1,
      ),
    ],
    elements: [_element(id: 'oak')],
    surfaceCatalog: ProjectSurfaceCatalog(),
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

EnvironmentPresetDraft _validDraft() {
  return EnvironmentPresetDraft(
    id: 'newPreset',
    name: 'New',
    templateId: 'forest_dense',
    palette: [
      EnvironmentPaletteItemDraft(elementId: 'oak', weight: 1),
    ],
    defaultParams: EnvironmentGenerationParamsDraft.standard(),
    sortOrder: 0,
  );
}

```

## 15. Diff complet

### `environment_preset_draft.dart` (nouveau fichier, équivalent diff /dev/null)

```diff
+import 'package:map_core/map_core.dart';
+
+// ---------------------------------------------------------------------------
+// Generation params draft
+// ---------------------------------------------------------------------------
+
+/// Brouillon des paramètres de génération : valeurs hors bornes autorisées
+/// jusqu’à [validateEnvironmentPresetDraft].
+final class EnvironmentGenerationParamsDraft {
+  const EnvironmentGenerationParamsDraft({
+    required this.density,
+    required this.variation,
+    required this.edgeDensity,
+    required this.minSpacingCells,
+  });
+
+  /// Aligné sur [EnvironmentGenerationParams.standard] (map_core).
+  factory EnvironmentGenerationParamsDraft.standard() {
+    final s = EnvironmentGenerationParams.standard();
+    return EnvironmentGenerationParamsDraft(
+      density: s.density,
+      variation: s.variation,
+      edgeDensity: s.edgeDensity,
+      minSpacingCells: s.minSpacingCells,
+    );
+  }
+
+  final double density;
+  final double variation;
+  final double edgeDensity;
+  final int minSpacingCells;
+
+  EnvironmentGenerationParamsDraft copyWith({
+    double? density,
+    double? variation,
+    double? edgeDensity,
+    int? minSpacingCells,
+  }) {
+    return EnvironmentGenerationParamsDraft(
+      density: density ?? this.density,
+      variation: variation ?? this.variation,
+      edgeDensity: edgeDensity ?? this.edgeDensity,
+      minSpacingCells: minSpacingCells ?? this.minSpacingCells,
+    );
+  }
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is EnvironmentGenerationParamsDraft &&
+            density == other.density &&
+            variation == other.variation &&
+            edgeDensity == other.edgeDensity &&
+            minSpacingCells == other.minSpacingCells;
+  }
+
+  @override
+  int get hashCode =>
+      Object.hash(density, variation, edgeDensity, minSpacingCells);
+}
+
+// ---------------------------------------------------------------------------
+// Palette item draft
+// ---------------------------------------------------------------------------
+
+/// Item de palette en cours de saisie (états invalides permis).
+final class EnvironmentPaletteItemDraft {
+  EnvironmentPaletteItemDraft({
+    required this.elementId,
+    required this.weight,
+    this.collisionMode = EnvironmentCollisionMode.useElementDefault,
+    Set<String> tags = const <String>{},
+  }) : tags = Set.unmodifiable(Set<String>.from(tags));
+
+  final String elementId;
+  final int weight;
+  final EnvironmentCollisionMode collisionMode;
+
+  /// Copie défensive à la construction ; exposé immuable.
+  final Set<String> tags;
+
+  EnvironmentPaletteItemDraft copyWith({
+    String? elementId,
+    int? weight,
+    EnvironmentCollisionMode? collisionMode,
+    Set<String>? tags,
+  }) {
+    final nextTags =
+        tags != null ? Set<String>.from(tags) : Set<String>.from(this.tags);
+    return EnvironmentPaletteItemDraft(
+      elementId: elementId ?? this.elementId,
+      weight: weight ?? this.weight,
+      collisionMode: collisionMode ?? this.collisionMode,
+      tags: nextTags,
+    );
+  }
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is EnvironmentPaletteItemDraft &&
+            elementId == other.elementId &&
+            weight == other.weight &&
+            collisionMode == other.collisionMode &&
+            _setEquals(tags, other.tags);
+  }
+
+  @override
+  int get hashCode {
+    final sorted = tags.toList()..sort();
+    return Object.hash(
+      elementId,
+      weight,
+      collisionMode,
+      Object.hashAll(sorted),
+    );
+  }
+}
+
+// ---------------------------------------------------------------------------
+// Preset draft
+// ---------------------------------------------------------------------------
+
+/// Brouillon complet de preset Environment (création / future édition).
+final class EnvironmentPresetDraft {
+  factory EnvironmentPresetDraft({
+    required String id,
+    required String name,
+    required String templateId,
+    required List<EnvironmentPaletteItemDraft> palette,
+    required EnvironmentGenerationParamsDraft defaultParams,
+    String? categoryId,
+    int sortOrder = 0,
+  }) {
+    return EnvironmentPresetDraft._(
+      id: id,
+      name: name,
+      templateId: templateId,
+      palette: List<EnvironmentPaletteItemDraft>.unmodifiable(
+        List<EnvironmentPaletteItemDraft>.from(palette),
+      ),
+      defaultParams: defaultParams,
+      categoryId: categoryId,
+      sortOrder: sortOrder,
+    );
+  }
+
+  factory EnvironmentPresetDraft.empty() {
+    return EnvironmentPresetDraft(
+      id: '',
+      name: '',
+      templateId: '',
+      palette: const [],
+      defaultParams: EnvironmentGenerationParamsDraft.standard(),
+      categoryId: null,
+      sortOrder: 0,
+    );
+  }
+
+  factory EnvironmentPresetDraft.fromPreset(EnvironmentPreset preset) {
+    return EnvironmentPresetDraft(
+      id: preset.id,
+      name: preset.name,
+      templateId: preset.templateId,
+      palette: [
+        for (final item in preset.palette)
+          EnvironmentPaletteItemDraft(
+            elementId: item.elementId,
+            weight: item.weight,
+            collisionMode: item.collisionMode,
+            tags: item.tags,
+          ),
+      ],
+      defaultParams: EnvironmentGenerationParamsDraft(
+        density: preset.defaultParams.density,
+        variation: preset.defaultParams.variation,
+        edgeDensity: preset.defaultParams.edgeDensity,
+        minSpacingCells: preset.defaultParams.minSpacingCells,
+      ),
+      categoryId: preset.categoryId,
+      sortOrder: preset.sortOrder,
+    );
+  }
+
+  const EnvironmentPresetDraft._({
+    required this.id,
+    required this.name,
+    required this.templateId,
+    required this.palette,
+    required this.defaultParams,
+    required this.categoryId,
+    required this.sortOrder,
+  });
+
+  final String id;
+  final String name;
+  final String templateId;
+
+  /// Copie défensive ; liste immuable.
+  final List<EnvironmentPaletteItemDraft> palette;
+
+  final EnvironmentGenerationParamsDraft defaultParams;
+  final String? categoryId;
+  final int sortOrder;
+
+  EnvironmentPresetDraft copyWith({
+    String? id,
+    String? name,
+    String? templateId,
+    List<EnvironmentPaletteItemDraft>? palette,
+    EnvironmentGenerationParamsDraft? defaultParams,
+    String? categoryId,
+    bool clearCategoryId = false,
+    int? sortOrder,
+  }) {
+    final nextCategory =
+        clearCategoryId ? null : (categoryId ?? this.categoryId);
+    return EnvironmentPresetDraft(
+      id: id ?? this.id,
+      name: name ?? this.name,
+      templateId: templateId ?? this.templateId,
+      palette: palette ?? this.palette,
+      defaultParams: defaultParams ?? this.defaultParams,
+      categoryId: nextCategory,
+      sortOrder: sortOrder ?? this.sortOrder,
+    );
+  }
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is EnvironmentPresetDraft &&
+            id == other.id &&
+            name == other.name &&
+            templateId == other.templateId &&
+            _listEquals(palette, other.palette) &&
+            defaultParams == other.defaultParams &&
+            categoryId == other.categoryId &&
+            sortOrder == other.sortOrder;
+  }
+
+  @override
+  int get hashCode => Object.hash(
+        id,
+        name,
+        templateId,
+        Object.hashAll(palette),
+        defaultParams,
+        categoryId,
+        sortOrder,
+      );
+}
+
+// ---------------------------------------------------------------------------
+// Validation — issues
+// ---------------------------------------------------------------------------
+
+enum EnvironmentPresetDraftIssueSeverity {
+  error,
+  warning,
+}
+
+enum EnvironmentPresetDraftIssueKind {
+  emptyId,
+  duplicateId,
+  emptyName,
+  emptyTemplateId,
+  unknownTemplateId,
+  emptyPalette,
+  emptyPaletteElementId,
+  duplicatePaletteElementId,
+  missingPaletteElement,
+  invalidPaletteWeight,
+  emptyPaletteTag,
+  invalidDensity,
+  invalidVariation,
+  invalidEdgeDensity,
+  invalidMinSpacingCells,
+  emptyCategoryId,
+}
+
+final class EnvironmentPresetDraftIssue {
+  const EnvironmentPresetDraftIssue({
+    required this.severity,
+    required this.kind,
+    required this.message,
+    this.presetId,
+    this.elementId,
+    this.templateId,
+    this.paletteIndex,
+    this.tag,
+  });
+
+  final EnvironmentPresetDraftIssueSeverity severity;
+  final EnvironmentPresetDraftIssueKind kind;
+  final String message;
+  final String? presetId;
+  final String? elementId;
+  final String? templateId;
+  final int? paletteIndex;
+  final String? tag;
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is EnvironmentPresetDraftIssue &&
+            severity == other.severity &&
+            kind == other.kind &&
+            message == other.message &&
+            presetId == other.presetId &&
+            elementId == other.elementId &&
+            templateId == other.templateId &&
+            paletteIndex == other.paletteIndex &&
+            tag == other.tag;
+  }
+
+  @override
+  int get hashCode => Object.hash(
+        severity,
+        kind,
+        message,
+        presetId,
+        elementId,
+        templateId,
+        paletteIndex,
+        tag,
+      );
+}
+
+// ---------------------------------------------------------------------------
+// Validation — report
+// ---------------------------------------------------------------------------
+
+final class EnvironmentPresetDraftValidationReport {
+  factory EnvironmentPresetDraftValidationReport({
+    required List<EnvironmentPresetDraftIssue> issues,
+  }) {
+    return EnvironmentPresetDraftValidationReport._(
+      issues: List<EnvironmentPresetDraftIssue>.unmodifiable(
+        List<EnvironmentPresetDraftIssue>.from(issues),
+      ),
+    );
+  }
+
+  const EnvironmentPresetDraftValidationReport._({required this.issues});
+
+  final List<EnvironmentPresetDraftIssue> issues;
+
+  bool get hasIssues => issues.isNotEmpty;
+
+  bool get hasErrors => issues
+      .any((i) => i.severity == EnvironmentPresetDraftIssueSeverity.error);
+
+  bool get hasWarnings => issues.any(
+        (i) => i.severity == EnvironmentPresetDraftIssueSeverity.warning,
+      );
+
+  int get issueCount => issues.length;
+
+  int get errorCount => issues
+      .where((i) => i.severity == EnvironmentPresetDraftIssueSeverity.error)
+      .length;
+
+  int get warningCount => issues
+      .where((i) => i.severity == EnvironmentPresetDraftIssueSeverity.warning)
+      .length;
+
+  List<EnvironmentPresetDraftIssue> issuesForKind(
+    EnvironmentPresetDraftIssueKind kind,
+  ) {
+    return List<EnvironmentPresetDraftIssue>.unmodifiable(
+      [
+        for (final i in issues)
+          if (i.kind == kind) i
+      ],
+    );
+  }
+
+  List<EnvironmentPresetDraftIssue> issuesForPaletteIndex(int index) {
+    if (index < 0) {
+      return const [];
+    }
+    return List<EnvironmentPresetDraftIssue>.unmodifiable(
+      [
+        for (final i in issues)
+          if (i.paletteIndex == index) i
+      ],
+    );
+  }
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is EnvironmentPresetDraftValidationReport &&
+            _listEquals(issues, other.issues);
+  }
+
+  @override
+  int get hashCode => Object.hashAll(issues);
+}
+
+// ---------------------------------------------------------------------------
+// validateEnvironmentPresetDraft
+// ---------------------------------------------------------------------------
+
+/// Valide un [EnvironmentPresetDraft] contre un manifest et options auteur.
+///
+/// [existingPresetId] trimé : en édition, le preset portant cet id ne provoque
+/// pas [EnvironmentPresetDraftIssueKind.duplicateId] pour lui-même.
+EnvironmentPresetDraftValidationReport validateEnvironmentPresetDraft(
+  EnvironmentPresetDraft draft, {
+  required ProjectManifest manifest,
+  Set<String> knownTemplateIds = const <String>{},
+  String? existingPresetId,
+}) {
+  final issues = <EnvironmentPresetDraftIssue>[];
+  final trimmedExisting = existingPresetId?.trim();
+
+  void add(EnvironmentPresetDraftIssue issue) {
+    issues.add(issue);
+  }
+
+  // --- 1. Champs globaux (ordre stable) ---
+  final tid = draft.id.trim();
+  if (tid.isEmpty) {
+    add(const EnvironmentPresetDraftIssue(
+      severity: EnvironmentPresetDraftIssueSeverity.error,
+      kind: EnvironmentPresetDraftIssueKind.emptyId,
+      message: 'Environment preset draft id is empty.',
+    ));
+  }
+
+  final tname = draft.name.trim();
+  if (tname.isEmpty) {
+    add(const EnvironmentPresetDraftIssue(
+      severity: EnvironmentPresetDraftIssueSeverity.error,
+      kind: EnvironmentPresetDraftIssueKind.emptyName,
+      message: 'Environment preset draft name is empty.',
+    ));
+  }
+
+  final ttemplate = draft.templateId.trim();
+  if (ttemplate.isEmpty) {
+    add(const EnvironmentPresetDraftIssue(
+      severity: EnvironmentPresetDraftIssueSeverity.error,
+      kind: EnvironmentPresetDraftIssueKind.emptyTemplateId,
+      message: 'Environment preset draft templateId is empty.',
+    ));
+  }
+
+  if (draft.categoryId != null) {
+    final c = draft.categoryId!.trim();
+    if (c.isEmpty) {
+      add(const EnvironmentPresetDraftIssue(
+        severity: EnvironmentPresetDraftIssueSeverity.error,
+        kind: EnvironmentPresetDraftIssueKind.emptyCategoryId,
+        message: 'Environment preset draft categoryId is empty.',
+      ));
+    }
+  }
+
+  final p = draft.defaultParams;
+  if (p.density < 0.0 || p.density > 1.0) {
+    add(const EnvironmentPresetDraftIssue(
+      severity: EnvironmentPresetDraftIssueSeverity.error,
+      kind: EnvironmentPresetDraftIssueKind.invalidDensity,
+      message: 'Environment preset draft density must be between 0.0 and 1.0.',
+    ));
+  }
+  if (p.variation < 0.0 || p.variation > 1.0) {
+    add(const EnvironmentPresetDraftIssue(
+      severity: EnvironmentPresetDraftIssueSeverity.error,
+      kind: EnvironmentPresetDraftIssueKind.invalidVariation,
+      message:
+          'Environment preset draft variation must be between 0.0 and 1.0.',
+    ));
+  }
+  if (p.edgeDensity < 0.0 || p.edgeDensity > 1.0) {
+    add(const EnvironmentPresetDraftIssue(
+      severity: EnvironmentPresetDraftIssueSeverity.error,
+      kind: EnvironmentPresetDraftIssueKind.invalidEdgeDensity,
+      message:
+          'Environment preset draft edgeDensity must be between 0.0 and 1.0.',
+    ));
+  }
+  if (p.minSpacingCells < 0) {
+    add(const EnvironmentPresetDraftIssue(
+      severity: EnvironmentPresetDraftIssueSeverity.error,
+      kind: EnvironmentPresetDraftIssueKind.invalidMinSpacingCells,
+      message: 'Environment preset draft minSpacingCells must be >= 0.',
+    ));
+  }
+
+  // --- 2. duplicateId ---
+  final existingKey = (trimmedExisting != null && trimmedExisting.isNotEmpty)
+      ? trimmedExisting
+      : null;
+  if (tid.isNotEmpty) {
+    var duplicate = false;
+    for (final preset in manifest.environmentPresets) {
+      if (preset.id != tid) {
+        continue;
+      }
+      if (existingKey != null && preset.id == existingKey) {
+        continue;
+      }
+      duplicate = true;
+      break;
+    }
+    if (duplicate) {
+      add(EnvironmentPresetDraftIssue(
+        severity: EnvironmentPresetDraftIssueSeverity.error,
+        kind: EnvironmentPresetDraftIssueKind.duplicateId,
+        message:
+            'Environment preset draft id duplicates existing preset "$tid".',
+        presetId: tid,
+      ));
+    }
+  }
+
+  // --- 3. unknownTemplateId (warning) ---
+  if (knownTemplateIds.isNotEmpty && ttemplate.isNotEmpty) {
+    if (!knownTemplateIds.contains(ttemplate)) {
+      add(EnvironmentPresetDraftIssue(
+        severity: EnvironmentPresetDraftIssueSeverity.warning,
+        kind: EnvironmentPresetDraftIssueKind.unknownTemplateId,
+        message:
+            'Environment preset draft templateId "$ttemplate" is not in knownTemplateIds.',
+        templateId: ttemplate,
+      ));
+    }
+  }
+
+  // --- 4. emptyPalette ---
+  if (draft.palette.isEmpty) {
+    add(const EnvironmentPresetDraftIssue(
+      severity: EnvironmentPresetDraftIssueSeverity.error,
+      kind: EnvironmentPresetDraftIssueKind.emptyPalette,
+      message: 'Environment preset draft palette is empty.',
+    ));
+  }
+
+  // --- 5. Items palette (ordre des index) ---
+  final elementsById = <String, ProjectElementEntry>{
+    for (final e in manifest.elements) e.id: e,
+  };
+
+  final seenElementIds = <String, int>{};
+  for (var i = 0; i < draft.palette.length; i++) {
+    final item = draft.palette[i];
+    final eid = item.elementId.trim();
+
+    if (eid.isEmpty) {
+      add(EnvironmentPresetDraftIssue(
+        severity: EnvironmentPresetDraftIssueSeverity.error,
+        kind: EnvironmentPresetDraftIssueKind.emptyPaletteElementId,
+        message: 'Environment preset draft palette item has empty elementId.',
+        paletteIndex: i,
+      ));
+    } else {
+      if (seenElementIds.containsKey(eid)) {
+        add(EnvironmentPresetDraftIssue(
+          severity: EnvironmentPresetDraftIssueSeverity.error,
+          kind: EnvironmentPresetDraftIssueKind.duplicatePaletteElementId,
+          message:
+              'Environment preset draft palette duplicate elementId "$eid" at index $i.',
+          elementId: eid,
+          paletteIndex: i,
+        ));
+      } else {
+        seenElementIds[eid] = i;
+      }
+
+      if (!elementsById.containsKey(eid)) {
+        add(EnvironmentPresetDraftIssue(
+          severity: EnvironmentPresetDraftIssueSeverity.error,
+          kind: EnvironmentPresetDraftIssueKind.missingPaletteElement,
+          message:
+              'Environment preset draft palette references missing element "$eid".',
+          elementId: eid,
+          paletteIndex: i,
+        ));
+      }
+    }
+
+    if (item.weight <= 0) {
+      add(EnvironmentPresetDraftIssue(
+        severity: EnvironmentPresetDraftIssueSeverity.error,
+        kind: EnvironmentPresetDraftIssueKind.invalidPaletteWeight,
+        message:
+            'Environment preset draft palette item weight must be >= 1 (index $i).',
+        elementId: eid.isEmpty ? null : eid,
+        paletteIndex: i,
+      ));
+    }
+
+    for (final rawTag in item.tags) {
+      if (rawTag.trim().isEmpty) {
+        add(EnvironmentPresetDraftIssue(
+          severity: EnvironmentPresetDraftIssueSeverity.error,
+          kind: EnvironmentPresetDraftIssueKind.emptyPaletteTag,
+          message:
+              'Environment preset draft palette item has empty tag (index $i).',
+          elementId: eid.isEmpty ? null : eid,
+          paletteIndex: i,
+          tag: rawTag,
+        ));
+      }
+    }
+  }
+
+  return EnvironmentPresetDraftValidationReport(issues: issues);
+}
+
+// ---------------------------------------------------------------------------
+// buildEnvironmentPresetFromDraft
+// ---------------------------------------------------------------------------
+
+/// Construit un [EnvironmentPreset] map_core à partir d’un brouillon valide.
+///
+/// Ne consulte pas le manifest : appeler [validateEnvironmentPresetDraft]
+/// avant une persistance. Lève [ArgumentError] si les constructeurs map_core
+/// rejettent les données (id vide, tag vide, etc.) — pas de filtrage silencieux
+/// des tags vides.
+EnvironmentPreset buildEnvironmentPresetFromDraft(
+  EnvironmentPresetDraft draft,
+) {
+  final nid = draft.id.trim();
+  if (nid.isEmpty) {
+    throw ArgumentError.value(
+      draft.id,
+      'draft.id',
+      'buildEnvironmentPresetFromDraft: id cannot be empty after trim.',
+    );
+  }
+  final nname = draft.name.trim();
+  final ntemplate = draft.templateId.trim();
+  final String? cat;
+  if (draft.categoryId == null) {
+    cat = null;
+  } else {
+    final c = draft.categoryId!.trim();
+    if (c.isEmpty) {
+      throw ArgumentError.value(
+        draft.categoryId,
+        'draft.categoryId',
+        'buildEnvironmentPresetFromDraft: categoryId cannot be empty after trim.',
+      );
+    }
+    cat = c;
+  }
+
+  final palette = <EnvironmentPaletteItem>[
+    for (final d in draft.palette)
+      EnvironmentPaletteItem(
+        elementId: d.elementId.trim(),
+        weight: d.weight,
+        collisionMode: d.collisionMode,
+        tags: d.tags.map((t) => t.trim()).toSet(),
+      ),
+  ];
+
+  final params = EnvironmentGenerationParams(
+    density: draft.defaultParams.density,
+    variation: draft.defaultParams.variation,
+    edgeDensity: draft.defaultParams.edgeDensity,
+    minSpacingCells: draft.defaultParams.minSpacingCells,
+  );
+
+  return EnvironmentPreset(
+    id: nid,
+    name: nname,
+    templateId: ntemplate,
+    palette: palette,
+    defaultParams: params,
+    categoryId: cat,
+    sortOrder: draft.sortOrder,
+  );
+}
+
+// --- helpers ---
+
+bool _setEquals(Set<String> a, Set<String> b) {
+  if (identical(a, b)) {
+    return true;
+  }
+  if (a.length != b.length) {
+    return false;
+  }
+  for (final x in a) {
+    if (!b.contains(x)) {
+      return false;
+    }
+  }
+  return true;
+}
+
+bool _listEquals<T>(List<T> a, List<T> b) {
+  if (identical(a, b)) {
+    return true;
+  }
+  if (a.length != b.length) {
+    return false;
+  }
+  for (var i = 0; i < a.length; i++) {
+    if (a[i] != b[i]) {
+      return false;
+    }
+  }
+  return true;
+}

```

### `environment_preset_draft_test.dart` (nouveau fichier)

```diff
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/environment_studio/authoring/environment_preset_draft.dart';
+
+void main() {
+  group('EnvironmentGenerationParamsDraft', () {
+    test('standard s’aligne sur EnvironmentGenerationParams.standard()', () {
+      final d = EnvironmentGenerationParamsDraft.standard();
+      final c = EnvironmentGenerationParams.standard();
+      expect(d.density, c.density);
+      expect(d.variation, c.variation);
+      expect(d.edgeDensity, c.edgeDensity);
+      expect(d.minSpacingCells, c.minSpacingCells);
+    });
+
+    test('copyWith modifie chaque champ', () {
+      const base = EnvironmentGenerationParamsDraft(
+        density: 0.1,
+        variation: 0.2,
+        edgeDensity: 0.3,
+        minSpacingCells: 1,
+      );
+      expect(base.copyWith(density: 0.9).density, 0.9);
+      expect(base.copyWith(variation: 0.8).variation, 0.8);
+      expect(base.copyWith(edgeDensity: 0.7).edgeDensity, 0.7);
+      expect(base.copyWith(minSpacingCells: 42).minSpacingCells, 42);
+    });
+
+    test('égalité de valeur', () {
+      const a = EnvironmentGenerationParamsDraft(
+        density: 0.5,
+        variation: 0.5,
+        edgeDensity: 0.5,
+        minSpacingCells: 0,
+      );
+      const b = EnvironmentGenerationParamsDraft(
+        density: 0.5,
+        variation: 0.5,
+        edgeDensity: 0.5,
+        minSpacingCells: 0,
+      );
+      expect(a, b);
+      expect(a.hashCode, b.hashCode);
+    });
+  });
+
+  group('EnvironmentPaletteItemDraft', () {
+    test('accepte elementId vide sans throw', () {
+      expect(
+        () => EnvironmentPaletteItemDraft(elementId: '', weight: 0),
+        returnsNormally,
+      );
+    });
+
+    test('accepte weight <= 0 sans throw', () {
+      expect(
+        () => EnvironmentPaletteItemDraft(elementId: 'a', weight: 0),
+        returnsNormally,
+      );
+    });
+
+    test('collisionMode par défaut', () {
+      final d = EnvironmentPaletteItemDraft(elementId: 'x', weight: 1);
+      expect(d.collisionMode, EnvironmentCollisionMode.useElementDefault);
+    });
+
+    test('copie défensive tags et exposés immuables', () {
+      final raw = {'a', 'b'};
+      final d = EnvironmentPaletteItemDraft(
+        elementId: 'e',
+        weight: 1,
+        tags: raw,
+      );
+      raw.add('c');
+      expect(d.tags, {'a', 'b'});
+      expect(() => (d.tags as dynamic).add('z'), throwsA(anything));
+    });
+
+    test('copyWith modifie les champs', () {
+      final d = EnvironmentPaletteItemDraft(
+        elementId: 'e',
+        weight: 1,
+        tags: {'t'},
+      );
+      final n = d.copyWith(
+        elementId: 'f',
+        weight: 2,
+        collisionMode: EnvironmentCollisionMode.forceDisabled,
+        tags: {'u'},
+      );
+      expect(n.elementId, 'f');
+      expect(n.weight, 2);
+      expect(n.collisionMode, EnvironmentCollisionMode.forceDisabled);
+      expect(n.tags, {'u'});
+    });
+
+    test('égalité indépendante de l’ordre des tags source', () {
+      final a = EnvironmentPaletteItemDraft(
+        elementId: 'e',
+        weight: 1,
+        tags: {'z', 'a'},
+      );
+      final b = EnvironmentPaletteItemDraft(
+        elementId: 'e',
+        weight: 1,
+        tags: {'a', 'z'},
+      );
+      expect(a, b);
+      expect(a.hashCode, b.hashCode);
+    });
+  });
+
+  group('EnvironmentPresetDraft', () {
+    test('empty crée un brouillon formulaire', () {
+      final d = EnvironmentPresetDraft.empty();
+      expect(d.id, '');
+      expect(d.name, '');
+      expect(d.templateId, '');
+      expect(d.palette, isEmpty);
+      expect(d.categoryId, isNull);
+      expect(d.sortOrder, 0);
+      expect(
+        d.defaultParams,
+        EnvironmentGenerationParamsDraft.standard(),
+      );
+    });
+
+    test('fromPreset conserve champs et convertit palette / params', () {
+      final preset = EnvironmentPreset(
+        id: 'p1',
+        name: 'N',
+        templateId: 'tpl',
+        palette: [
+          EnvironmentPaletteItem(
+            elementId: 'oak',
+            weight: 2,
+            collisionMode: EnvironmentCollisionMode.forceEnabled,
+            tags: {'a', 'b'},
+          ),
+        ],
+        defaultParams: EnvironmentGenerationParams(
+          density: 0.2,
+          variation: 0.3,
+          edgeDensity: 0.4,
+          minSpacingCells: 3,
+        ),
+        categoryId: 'cat',
+        sortOrder: 7,
+      );
+      final d = EnvironmentPresetDraft.fromPreset(preset);
+      expect(d.id, 'p1');
+      expect(d.name, 'N');
+      expect(d.templateId, 'tpl');
+      expect(d.categoryId, 'cat');
+      expect(d.sortOrder, 7);
+      expect(d.palette.length, 1);
+      expect(d.palette.single.elementId, 'oak');
+      expect(d.palette.single.weight, 2);
+      expect(d.palette.single.collisionMode,
+          EnvironmentCollisionMode.forceEnabled);
+      expect(d.palette.single.tags, {'a', 'b'});
+      expect(d.defaultParams.density, 0.2);
+      expect(d.defaultParams.minSpacingCells, 3);
+    });
+
+    test('palette copiée défensivement et immuable', () {
+      final item = EnvironmentPaletteItemDraft(elementId: 'e', weight: 1);
+      final list = [item];
+      final d = EnvironmentPresetDraft(
+        id: 'a',
+        name: 'b',
+        templateId: 'c',
+        palette: list,
+        defaultParams: EnvironmentGenerationParamsDraft.standard(),
+      );
+      list.add(EnvironmentPaletteItemDraft(elementId: 'x', weight: 1));
+      expect(d.palette.length, 1);
+      expect(() => (d.palette as dynamic).add(item), throwsA(anything));
+    });
+
+    test('copyWith et clearCategoryId', () {
+      final d = EnvironmentPresetDraft(
+        id: 'i',
+        name: 'n',
+        templateId: 't',
+        palette: [
+          EnvironmentPaletteItemDraft(elementId: 'e', weight: 1),
+        ],
+        defaultParams: EnvironmentGenerationParamsDraft.standard(),
+        categoryId: 'old',
+      );
+      final cleared = d.copyWith(clearCategoryId: true);
+      expect(cleared.categoryId, isNull);
+      final updated = d.copyWith(categoryId: 'new');
+      expect(updated.categoryId, 'new');
+    });
+
+    test('égalité de valeur', () {
+      final a = _validDraft();
+      final b = _validDraft();
+      expect(a, b);
+      expect(a.hashCode, b.hashCode);
+    });
+  });
+
+  group('validateEnvironmentPresetDraft', () {
+    test('draft valide => aucune issue', () {
+      final r = validateEnvironmentPresetDraft(
+        _validDraft(),
+        manifest: _manifest(),
+      );
+      expect(r.hasIssues, isFalse);
+      expect(r.issueCount, 0);
+    });
+
+    test('emptyId', () {
+      final r = validateEnvironmentPresetDraft(
+        _validDraft().copyWith(id: '  '),
+        manifest: _manifest(),
+      );
+      expect(
+          r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyId), isNotEmpty);
+    });
+
+    test('duplicateId en création', () {
+      final r = validateEnvironmentPresetDraft(
+        _validDraft().copyWith(id: 'existing'),
+        manifest: _manifest(),
+      );
+      expect(
+        r.issuesForKind(EnvironmentPresetDraftIssueKind.duplicateId),
+        isNotEmpty,
+      );
+    });
+
+    test('duplicateId ignoré si existingPresetId identique', () {
+      final r = validateEnvironmentPresetDraft(
+        _validDraft().copyWith(id: 'existing'),
+        manifest: _manifest(),
+        existingPresetId: 'existing',
+      );
+      expect(
+        r.issuesForKind(EnvironmentPresetDraftIssueKind.duplicateId),
+        isEmpty,
+      );
+    });
+
+    test('duplicateId en édition avec renommage vers id occupé', () {
+      final r = validateEnvironmentPresetDraft(
+        _validDraft().copyWith(id: 'existing'),
+        manifest: _manifest(),
+        existingPresetId: 'other',
+      );
+      expect(
+        r.issuesForKind(EnvironmentPresetDraftIssueKind.duplicateId),
+        isNotEmpty,
+      );
+    });
+
+    test('existingPresetId whitespace traité comme absent', () {
+      final r = validateEnvironmentPresetDraft(
+        _validDraft().copyWith(id: 'existing'),
+        manifest: _manifest(),
+        existingPresetId: '   ',
+      );
+      expect(
+        r.issuesForKind(EnvironmentPresetDraftIssueKind.duplicateId),
+        isNotEmpty,
+      );
+    });
+
+    test('emptyName', () {
+      final r = validateEnvironmentPresetDraft(
+        _validDraft().copyWith(name: ''),
+        manifest: _manifest(),
+      );
+      expect(
+        r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyName),
+        isNotEmpty,
+      );
+    });
+
+    test('emptyTemplateId', () {
+      final r = validateEnvironmentPresetDraft(
+        _validDraft().copyWith(templateId: '  '),
+        manifest: _manifest(),
+      );
+      expect(
+        r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyTemplateId),
+        isNotEmpty,
+      );
+    });
+
+    test('unknownTemplateId warning si knownTemplateIds non vide', () {
+      final r = validateEnvironmentPresetDraft(
+        _validDraft(),
+        manifest: _manifest(),
+        knownTemplateIds: const {'other'},
+      );
+      final w =
+          r.issuesForKind(EnvironmentPresetDraftIssueKind.unknownTemplateId);
+      expect(w, isNotEmpty);
+      expect(w.single.severity, EnvironmentPresetDraftIssueSeverity.warning);
+    });
+
+    test('unknownTemplateId absent si knownTemplateIds vide', () {
+      final r = validateEnvironmentPresetDraft(
+        _validDraft(),
+        manifest: _manifest(),
+        knownTemplateIds: const {},
+      );
+      expect(
+        r.issuesForKind(EnvironmentPresetDraftIssueKind.unknownTemplateId),
+        isEmpty,
+      );
+    });
+
+    test('emptyCategoryId si categoryId whitespace', () {
+      final r = validateEnvironmentPresetDraft(
+        _validDraft().copyWith(categoryId: '  \t'),
+        manifest: _manifest(),
+      );
+      expect(
+        r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyCategoryId),
+        isNotEmpty,
+      );
+    });
+
+    test('invalidDensity / variation / edgeDensity / minSpacingCells', () {
+      expect(
+        validateEnvironmentPresetDraft(
+          _validDraft().copyWith(
+            defaultParams: const EnvironmentGenerationParamsDraft(
+              density: -0.01,
+              variation: 0.5,
+              edgeDensity: 0.5,
+              minSpacingCells: 0,
+            ),
+          ),
+          manifest: _manifest(),
+        ).issuesForKind(EnvironmentPresetDraftIssueKind.invalidDensity),
+        isNotEmpty,
+      );
+      expect(
+        validateEnvironmentPresetDraft(
+          _validDraft().copyWith(
+            defaultParams: const EnvironmentGenerationParamsDraft(
+              density: 0.5,
+              variation: 2,
+              edgeDensity: 0.5,
+              minSpacingCells: 0,
+            ),
+          ),
+          manifest: _manifest(),
+        ).issuesForKind(EnvironmentPresetDraftIssueKind.invalidVariation),
+        isNotEmpty,
+      );
+      expect(
+        validateEnvironmentPresetDraft(
+          _validDraft().copyWith(
+            defaultParams: const EnvironmentGenerationParamsDraft(
+              density: 0.5,
+              variation: 0.5,
+              edgeDensity: -1,
+              minSpacingCells: 0,
+            ),
+          ),
+          manifest: _manifest(),
+        ).issuesForKind(EnvironmentPresetDraftIssueKind.invalidEdgeDensity),
+        isNotEmpty,
+      );
+      expect(
+        validateEnvironmentPresetDraft(
+          _validDraft().copyWith(
+            defaultParams: const EnvironmentGenerationParamsDraft(
+              density: 0.5,
+              variation: 0.5,
+              edgeDensity: 0.5,
+              minSpacingCells: -1,
+            ),
+          ),
+          manifest: _manifest(),
+        ).issuesForKind(EnvironmentPresetDraftIssueKind.invalidMinSpacingCells),
+        isNotEmpty,
+      );
+    });
+
+    test('emptyPalette', () {
+      final r = validateEnvironmentPresetDraft(
+        _validDraft().copyWith(palette: []),
+        manifest: _manifest(),
+      );
+      expect(
+        r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyPalette),
+        isNotEmpty,
+      );
+    });
+
+    test('emptyPaletteElementId', () {
+      final r = validateEnvironmentPresetDraft(
+        _validDraft().copyWith(
+          palette: [
+            EnvironmentPaletteItemDraft(elementId: '  ', weight: 1),
+          ],
+        ),
+        manifest: _manifest(),
+      );
+      expect(
+        r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyPaletteElementId),
+        isNotEmpty,
+      );
+    });
+
+    test('duplicatePaletteElementId sur le second item', () {
+      final r = validateEnvironmentPresetDraft(
+        _validDraft().copyWith(
+          palette: [
+            EnvironmentPaletteItemDraft(elementId: 'oak', weight: 1),
+            EnvironmentPaletteItemDraft(elementId: 'oak', weight: 1),
+          ],
+        ),
+        manifest: _manifest(),
+      );
+      final dup = r.issuesForKind(
+        EnvironmentPresetDraftIssueKind.duplicatePaletteElementId,
+      );
+      expect(dup, isNotEmpty);
+      expect(dup.single.paletteIndex, 1);
+    });
+
+    test('missingPaletteElement', () {
+      final r = validateEnvironmentPresetDraft(
+        _validDraft().copyWith(
+          palette: [
+            EnvironmentPaletteItemDraft(elementId: 'ghost', weight: 1),
+          ],
+        ),
+        manifest: _manifest(),
+      );
+      expect(
+        r.issuesForKind(EnvironmentPresetDraftIssueKind.missingPaletteElement),
+        isNotEmpty,
+      );
+    });
+
+    test('missingPaletteElement non produit si elementId vide', () {
+      final r = validateEnvironmentPresetDraft(
+        _validDraft().copyWith(
+          palette: [
+            EnvironmentPaletteItemDraft(elementId: '', weight: 1),
+          ],
+        ),
+        manifest: _manifest(),
+      );
+      expect(
+        r.issuesForKind(EnvironmentPresetDraftIssueKind.missingPaletteElement),
+        isEmpty,
+      );
+      expect(
+        r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyPaletteElementId),
+        isNotEmpty,
+      );
+    });
+
+    test('invalidPaletteWeight', () {
+      final r = validateEnvironmentPresetDraft(
+        _validDraft().copyWith(
+          palette: [
+            EnvironmentPaletteItemDraft(elementId: 'oak', weight: 0),
+          ],
+        ),
+        manifest: _manifest(),
+      );
+      expect(
+        r.issuesForKind(EnvironmentPresetDraftIssueKind.invalidPaletteWeight),
+        isNotEmpty,
+      );
+    });
+
+    test('emptyPaletteTag', () {
+      final r = validateEnvironmentPresetDraft(
+        _validDraft().copyWith(
+          palette: [
+            EnvironmentPaletteItemDraft(
+              elementId: 'oak',
+              weight: 1,
+              tags: {'ok', '  '},
+            ),
+          ],
+        ),
+        manifest: _manifest(),
+      );
+      final tags =
+          r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyPaletteTag);
+      expect(tags, isNotEmpty);
+      expect(tags.single.paletteIndex, 0);
+    });
+
+    test('issuesForPaletteIndex et index négatif', () {
+      final r = validateEnvironmentPresetDraft(
+        _validDraft().copyWith(
+          palette: [
+            EnvironmentPaletteItemDraft(elementId: 'oak', weight: 0),
+            EnvironmentPaletteItemDraft(elementId: 'oak', weight: 0),
+          ],
+        ),
+        manifest: _manifest(),
+      );
+      expect(r.issuesForPaletteIndex(0), isNotEmpty);
+      expect(r.issuesForPaletteIndex(1), isNotEmpty);
+      expect(r.issuesForPaletteIndex(-1), isEmpty);
+    });
+
+    test('ordre stable des kinds (extrait)', () {
+      final r = validateEnvironmentPresetDraft(
+        EnvironmentPresetDraft(
+          id: '',
+          name: '',
+          templateId: '',
+          palette: [],
+          defaultParams: const EnvironmentGenerationParamsDraft(
+            density: -1,
+            variation: -1,
+            edgeDensity: -1,
+            minSpacingCells: -1,
+          ),
+          categoryId: '  ',
+        ),
+        manifest: _manifest(),
+        knownTemplateIds: const {'x'},
+      );
+      final kinds = [for (final i in r.issues) i.kind];
+      expect(kinds.first, EnvironmentPresetDraftIssueKind.emptyId);
+      expect(kinds[1], EnvironmentPresetDraftIssueKind.emptyName);
+      expect(kinds[2], EnvironmentPresetDraftIssueKind.emptyTemplateId);
+      expect(kinds[3], EnvironmentPresetDraftIssueKind.emptyCategoryId);
+      expect(kinds[4], EnvironmentPresetDraftIssueKind.invalidDensity);
+      expect(kinds[5], EnvironmentPresetDraftIssueKind.invalidVariation);
+      expect(kinds[6], EnvironmentPresetDraftIssueKind.invalidEdgeDensity);
+      expect(kinds[7], EnvironmentPresetDraftIssueKind.invalidMinSpacingCells);
+      expect(kinds[8], EnvironmentPresetDraftIssueKind.emptyPalette);
+    });
+  });
+
+  group('buildEnvironmentPresetFromDraft', () {
+    test('convertit un draft valide', () {
+      final draft = _validDraft();
+      final p = buildEnvironmentPresetFromDraft(draft);
+      expect(p.id, 'newPreset');
+      expect(p.name, 'New');
+      expect(p.templateId, 'forest_dense');
+      expect(p.palette.single.elementId, 'oak');
+    });
+
+    test('trim id / name / templateId / categoryId / elementId / tags', () {
+      final draft = EnvironmentPresetDraft(
+        id: '  id1  ',
+        name: '  N  ',
+        templateId: '  tpl  ',
+        palette: [
+          EnvironmentPaletteItemDraft(
+            elementId: '  oak  ',
+            weight: 1,
+            tags: {'  canopy  '},
+          ),
+        ],
+        defaultParams: EnvironmentGenerationParamsDraft.standard(),
+        categoryId: '  bio  ',
+      );
+      final p = buildEnvironmentPresetFromDraft(draft);
+      expect(p.id, 'id1');
+      expect(p.name, 'N');
+      expect(p.templateId, 'tpl');
+      expect(p.categoryId, 'bio');
+      expect(p.palette.single.elementId, 'oak');
+      expect(p.palette.single.tags, {'canopy'});
+    });
+
+    test('lève si id vide après trim', () {
+      expect(
+        () => buildEnvironmentPresetFromDraft(
+          _validDraft().copyWith(id: '   '),
+        ),
+        throwsArgumentError,
+      );
+    });
+
+    test('lève si tag vide après trim', () {
+      expect(
+        () => buildEnvironmentPresetFromDraft(
+          _validDraft().copyWith(
+            palette: [
+              EnvironmentPaletteItemDraft(
+                elementId: 'oak',
+                weight: 1,
+                tags: {' '},
+              ),
+            ],
+          ),
+        ),
+        throwsArgumentError,
+      );
+    });
+
+    test('ne vérifie pas le manifest (duplicate accepté si map_core OK)', () {
+      final draft = _validDraft().copyWith(id: 'existing');
+      final p = buildEnvironmentPresetFromDraft(draft);
+      expect(p.id, 'existing');
+    });
+  });
+
+  group('EnvironmentPresetDraftValidationReport', () {
+    test('issues défensives / immuables / compteurs / égalité', () {
+      final raw = <EnvironmentPresetDraftIssue>[
+        const EnvironmentPresetDraftIssue(
+          severity: EnvironmentPresetDraftIssueSeverity.error,
+          kind: EnvironmentPresetDraftIssueKind.emptyId,
+          message: 'm',
+        ),
+      ];
+      final a = EnvironmentPresetDraftValidationReport(issues: raw);
+      raw.add(
+        const EnvironmentPresetDraftIssue(
+          severity: EnvironmentPresetDraftIssueSeverity.warning,
+          kind: EnvironmentPresetDraftIssueKind.unknownTemplateId,
+          message: 'w',
+        ),
+      );
+      expect(a.issueCount, 1);
+      expect(() => a.issues.add(raw.first), throwsA(anything));
+
+      final b = EnvironmentPresetDraftValidationReport(
+        issues: [
+          const EnvironmentPresetDraftIssue(
+            severity: EnvironmentPresetDraftIssueSeverity.error,
+            kind: EnvironmentPresetDraftIssueKind.emptyId,
+            message: 'm',
+          ),
+        ],
+      );
+      expect(a, b);
+      expect(a.hashCode, b.hashCode);
+    });
+
+    test('hasErrors / hasWarnings', () {
+      final onlyErr = EnvironmentPresetDraftValidationReport(
+        issues: [
+          const EnvironmentPresetDraftIssue(
+            severity: EnvironmentPresetDraftIssueSeverity.error,
+            kind: EnvironmentPresetDraftIssueKind.emptyId,
+            message: 'e',
+          ),
+        ],
+      );
+      expect(onlyErr.hasErrors, isTrue);
+      expect(onlyErr.hasWarnings, isFalse);
+      final onlyWarn = EnvironmentPresetDraftValidationReport(
+        issues: [
+          const EnvironmentPresetDraftIssue(
+            severity: EnvironmentPresetDraftIssueSeverity.warning,
+            kind: EnvironmentPresetDraftIssueKind.unknownTemplateId,
+            message: 'w',
+          ),
+        ],
+      );
+      expect(onlyWarn.hasErrors, isFalse);
+      expect(onlyWarn.hasWarnings, isTrue);
+    });
+
+    test('issuesForKind retourne non modifiable', () {
+      final r = EnvironmentPresetDraftValidationReport(
+        issues: [
+          const EnvironmentPresetDraftIssue(
+            severity: EnvironmentPresetDraftIssueSeverity.error,
+            kind: EnvironmentPresetDraftIssueKind.emptyId,
+            message: 'm',
+          ),
+        ],
+      );
+      final list = r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyId);
+      expect(() => list.clear(), throwsA(anything));
+    });
+  });
+}
+
+// --- helpers ---
+
+ProjectManifest _manifest() {
+  return ProjectManifest(
+    name: 'draft-test',
+    maps: const [],
+    tilesets: const [],
+    environmentPresets: [
+      EnvironmentPreset(
+        id: 'existing',
+        name: 'E',
+        templateId: 't',
+        palette: [
+          EnvironmentPaletteItem(elementId: 'oak', weight: 1),
+        ],
+        defaultParams: EnvironmentGenerationParams.standard(),
+        sortOrder: 0,
+      ),
+      EnvironmentPreset(
+        id: 'other',
+        name: 'O',
+        templateId: 't',
+        palette: [
+          EnvironmentPaletteItem(elementId: 'oak', weight: 1),
+        ],
+        defaultParams: EnvironmentGenerationParams.standard(),
+        sortOrder: 1,
+      ),
+    ],
+    elements: [_element(id: 'oak')],
+    surfaceCatalog: ProjectSurfaceCatalog(),
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
+
+EnvironmentPresetDraft _validDraft() {
+  return EnvironmentPresetDraft(
+    id: 'newPreset',
+    name: 'New',
+    templateId: 'forest_dense',
+    palette: [
+      EnvironmentPaletteItemDraft(elementId: 'oak', weight: 1),
+    ],
+    defaultParams: EnvironmentGenerationParamsDraft.standard(),
+    sortOrder: 0,
+  );
+}

```

## 16. Auto-review

- **Points solides** : API alignée sur le cahier des charges ; tests exhaustifs ; pas de fuite Flutter ; `duplicateId` corrigé (comparaison `preset.id == existingKey`).
- **Points discutables** : messages de validation en anglais (stables) alors que l’UI Environment Studio est en FR — acceptable pour une couche logique partagée avant i18n.
- **Corrections après auto-review** : logique `duplicateId` / `existingPresetId` ; message `invalidPaletteWeight` explicite `>= 1`.
- **Risques restants** : double source de vérité (draft vs `map_core`) — mitigé par tests et par l’obligation d’appeler `validate` avant `build` en flux futur.
- **Regard critique sur le prompt** : `existingPresetId` utile dès maintenant ; pas de filtrage silencieux des tags — conforme ; brouillon dans `map_editor` évite d’élargir `map_core` pour des états transitoires UI.

## 17. Verdict

Statut du lot :

- [x] Validé

Résumé :

```
Modèle draft + validation + build pur map_editor ; 43 tests nouveaux verts ; régressions Environment Studio et toolbar OK ; suite complète map_editor +890 -34 (dette préexistante hors lot).
```

Prochain lot recommandé :

```
Environment-13 — Environment Preset Creation Form Shell V0
```
