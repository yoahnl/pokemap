# Phase R1 — Lot 4 — Mini-fix feedback final batch sans write réel

## 1. Résumé exécutif honnête

Mini-fix livré, strictement local au lot 4.

Le problème était réel : le feedback final du batch pouvait rester non-erreur quand aucune espèce n'avait été réellement importée, dès lors qu'il n'y avait pas d'erreur technique stricte et seulement des conflits et/ou des skips.

Le correctif retenu est minimal :

- le critère de feedback final batch est désormais le même que celui du refresh workspace : **au moins une écriture réelle appliquée** ;
- s'il n'y a **aucune écriture réelle**, le feedback final est explicitement négatif ;
- le message final devient explicite : `Aucune espèce importée ...` ;
- le mono-espèce et le lot 3 ne sont pas touchés ;
- aucun pipeline batch parallèle n'a été créé.

## 2. Problème exact identifié

Point de vérité actuel audité dans [pokedex_import_flow.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart).

### Où sont calculés les éléments batch finaux

- `feedbackMessage` final batch : `_buildBatchImportFeedback(...)`
- `feedbackIsError` final batch : `_closeBatchResult()`
- `shouldRefreshWorkspace` : `_closeBatchResult()`
- `selectedSpeciesId` : `_selectBatchImportedSpeciesId(...)`

### Comportement avant correctif

Dans `_closeBatchResult()` :

- `selectedSpeciesId` était déterminé par la première espèce avec `hasWritesApplied == true` ;
- `shouldRefreshWorkspace` dépendait de `selectedSpeciesId != null` ;
- `feedbackMessage` était toujours construit avec le préfixe `Batch terminé` ;
- `feedbackIsError` ne passait à `true` que si `!importedAnySpecies && result.failedCount > 0`.

Conséquence :

- `0 succès / N conflits / 0 erreurs / 0 skips` pouvait rester non-erreur ;
- `0 succès / 0 conflits / 0 erreurs / N skips` pouvait rester non-erreur ;
- `0 succès / N conflits / 0 erreurs / M skips` pouvait rester non-erreur ;
- alors qu'aucune espèce n'avait été réellement écrite et qu'aucun refresh utile ne devait avoir lieu.

## 3. Règle produit retenue

Règle choisie :

- **succès global** seulement si au moins une espèce a réellement été écrite ;
- **feedback négatif explicite** si aucune espèce n'a été écrite, même sans erreur technique.

Formulation retenue :

- avec write réel : `Batch terminé · ...`
- sans write réel : `Aucune espèce importée · ...`

Signal binaire retenu :

- `feedbackIsError == false` si au moins une écriture réelle a eu lieu ;
- `feedbackIsError == true` sinon.

Pourquoi cette règle :

- elle réutilise le même critère que `shouldRefreshWorkspace` ;
- elle ne change pas le contrat du pipeline batch ;
- elle reste petite, stable, et compréhensible ;
- elle évite un faux succès silencieux.

Ce qui a été explicitement rejeté :

- un troisième état de feedback intermédiaire ;
- un nouveau classifieur batch ;
- une logique fondée uniquement sur `failedCount` ;
- une refonte plus large du wizard.

## 4. Fichiers modifiés

### Modifiés

- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart`
- `packages/map_editor/test/pokedex_external_batch_execute_ui_test.dart`

### Créés

- `reports/phase-r1-lot-4-mini-fix-no-write-feedback-report.md`

### Supprimés

- aucun

## 5. Justification fichier par fichier

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart`

Mini-fix du point de vérité du feedback batch final :

- ajout d'un helper local `_hasBatchWritesApplied(...)` ;
- `feedbackIsError` aligné sur l'absence de write réel ;
- `feedbackMessage` rendu explicite avec `Aucune espèce importée` quand aucun write réel n'a eu lieu.

Le refresh et la sélection post-batch ne sont pas cassés :

- `selectedSpeciesId` continue d'être déterminé par `_selectBatchImportedSpeciesId(...)` ;
- `shouldRefreshWorkspace` continue de dépendre des écritures réelles ;
- aucun changement du pipeline applicatif.

### `packages/map_editor/test/pokedex_external_batch_execute_ui_test.dart`

Ajout de la couverture produit réelle du mini-fix :

- cas succès avec write réel -> feedback non-erreur ;
- cas conflit-only sans write -> feedback négatif ;
- cas skip-only sans write -> feedback négatif ;
- cas mixte conflits + skips sans write -> feedback négatif.

Le choix du widget test est volontaire : le point de vérité est dans `_closeBatchResult()` et le comportement demandé est un comportement produit visible, pas juste une règle abstraite.

## 6. Tests ajoutés / modifiés

### Tests modifiés

Dans `packages/map_editor/test/pokedex_external_batch_execute_ui_test.dart` :

- le test de succès existant vérifie maintenant explicitement l'icône succès ;
- ajout de trois tests de non-success sans write réel.

### Cas couverts

#### Cas A

Batch avec au moins une espèce réellement écrite
→ feedback non-erreur

#### Cas B

Batch avec `0 succès` et seulement conflits
→ feedback final négatif / erreur UI

#### Cas C

Batch avec `0 succès` et seulement skips
→ feedback final négatif / erreur UI

#### Cas D

Batch avec `0 succès` et mélange conflits + skips
→ feedback final négatif / erreur UI

## 7. Sub-agents utilisés, conclusions, retenu / rejeté

Le système ne permettait pas de créer de nouveaux sub-agents propres à ce tour. J'ai donc réutilisé honnêtement des threads existants.

### Scope / architecture — Boyle

Conclusion :

- le bon critère est déjà là : `hasWritesApplied` ;
- il faut l'utiliser aussi pour le feedback final ;
- il ne faut pas toucher au contrat du pipeline batch.

Retenu : oui.
Rejeté : toute nouvelle couche batch ou changement de modèle.

### UX / produit — Avicenna

Conclusion :

- le feedback final doit être piloté par le write réel, pas par le simple fait que le batch s'est terminé ;
- le message doit dire explicitement que rien n'a été importé.

Retenu : oui sur la logique produit.
Rejeté : l'idée d'un état “warning” intermédiaire, car le composant existant est binaire succès/erreur et le mini-fix devait rester strict sur son scope.

### Test matrix / contradicteur — Mendel

Conclusion :

- le meilleur point de vérité à tester est le widget flow réel ;
- il faut verrouiller les trois cas sans write réel + le cas avec write réel ;
- il faut vérifier aussi l'absence de refresh utile dans les cas sans write.

Retenu : oui.
Rejeté : sur-isoler artificiellement la logique dans un nouveau helper public juste pour la tester.

## 8. Commandes réellement exécutées

### Lecture / audit

```text
sed -n '560,705p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart
sed -n '232,285p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart
sed -n '1,520p' packages/map_editor/test/pokedex_external_batch_execute_ui_test.dart
sed -n '1,220p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_feedback_banner.dart
rg -n "feedbackIsError|pokedex-feedback-banner" packages/map_editor/test/pokedex_workspace_ui_test.dart packages/map_editor/test/pokedex_external_batch_execute_ui_test.dart
rg -n "isFullySkipped|hasWritesApplied|hasConflicts" packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart
sed -n '168,214p' packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart
```

### Validation

```text
dart format packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart packages/map_editor/test/pokedex_external_batch_execute_ui_test.dart
flutter analyze --no-pub lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart test/pokedex_external_batch_execute_ui_test.dart
flutter test test/pokedex_external_batch_execute_ui_test.dart
flutter test test/pokedex_external_batch_dry_run_ui_test.dart
flutter test test/pokedex_workspace_ui_test.dart --plain-name "imports a pokemon from API externe and refreshes the workspace"
```

### Git utile

```text
git status --short
git diff --stat -- packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart packages/map_editor/test/pokedex_external_batch_execute_ui_test.dart
git diff -- packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart packages/map_editor/test/pokedex_external_batch_execute_ui_test.dart
```

## 9. Résultats réels

### `dart format`

```text
Formatted packages/map_editor/test/pokedex_external_batch_execute_ui_test.dart
Formatted 2 files (1 changed) in 0.02 seconds.
```

### `flutter analyze --no-pub`

```text
Analyzing 2 items...
No issues found! (ran in 1.8s)
```

### `flutter test test/pokedex_external_batch_execute_ui_test.dart`

```text
00:03 +5: All tests passed!
```

### `flutter test test/pokedex_external_batch_dry_run_ui_test.dart`

```text
00:03 +3: All tests passed!
```

### `flutter test test/pokedex_workspace_ui_test.dart --plain-name "imports a pokemon from API externe and refreshes the workspace"`

```text
00:02 +1: All tests passed!
```

## 10. Incidents rencontrés

### Incident 1 — premier `flutter analyze` lancé avec des chemins doublés

Depuis `packages/map_editor`, j'ai d'abord lancé :

```text
flutter analyze --no-pub packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart packages/map_editor/test/pokedex_external_batch_execute_ui_test.dart
```

Sortie :

```text
You provided the path '/Users/karim/Project/pokemonProject/packages/map_editor/packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart', however it does not exist on disk
```

Correction : relance avec des chemins relatifs au package.

### Incident 2 — premier `flutter test` filtré avec plusieurs `--plain-name`

Tentative trop ambitieuse sur plusieurs filtres de noms en une seule commande.
Résultat : aucun test ne matchait cette combinaison.

Correction :

- exécution du fichier ciblé complet pour le mini-fix ;
- non-régressions relancées séparément.

## 11. État git utile

Note : le snapshot git ci-dessous a été capturé juste avant la génération de ce report pour éviter l'auto-référence du fichier de report dans ses propres extraits.

### `git status --short`

```text
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart
 M packages/map_editor/test/pokedex_external_batch_execute_ui_test.dart
```

### `git diff --stat -- ...`

```text
 .../pokedex_workspace/pokedex_import_flow.dart     |  24 +-
 .../pokedex_external_batch_execute_ui_test.dart    | 327 +++++++++++++++++++++
 2 files changed, 346 insertions(+), 5 deletions(-)
```

## 12. Checklist finale

- [x] scope strictement local au lot 4
- [x] aucun pipeline batch parallèle
- [x] aucun nouveau modèle de résultat parallèle
- [x] pas de refactor lourd du wizard
- [x] mono-espèce intact
- [x] lot 3 intact
- [x] feedback final explicitement négatif quand 0 write réel
- [x] refresh non cassé
- [x] sélection post-batch non cassée
- [x] tests ciblés verts
- [x] analyze vert
- [x] aucun commit git
- [x] aucune écriture git destructive

## 13. Annexe — contenu complet de tous les fichiers texte modifiés / créés

Note explicite : ce report n'inclut pas sa propre source complète dans cette annexe pour éviter une récursion infinie. Les autres fichiers texte touchés par ce mini-fix sont inclus intégralement ci-dessous.


### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart`

```text
part of 'pokedex_workspace_page.dart';

// Orchestration unique du flow d'import Pokédex.
//
// Cette feuille modale reste volontairement la seule porte d'entrée UI pour
// les imports Pokédex :
// - source locale JSON ;
// - source produit `API externe` ;
// - aperçu avant write ;
// - confirmation finale.
//
// Toute la logique métier reste hors des widgets :
// - l'UI choisit une source et affiche un résumé ;
// - les providers injectés appellent les use cases existants ;
// - aucun parsing JSON ou HTTP ne vit ici.

Future<_CompletedPokedexImportFlowResult?> _showPokedexImportFlowSheet({
  required BuildContext context,
  required ProjectWorkspace workspace,
  required PokedexImportPreviewer previewImport,
  required PokedexImporter importPokemon,
  required PokedexExternalSpeciesSearcher searchExternalSpecies,
  required PokedexExternalBatchSelectionResolver resolveExternalBatchSelection,
  required PokedexExternalImportPreviewer previewExternalImport,
  required PokedexExternalBatchPreviewer previewExternalBatchImport,
  required PokedexExternalBatchImporter importExternalBatch,
  required PokedexExternalImporter importExternalPokemon,
  Future<String?> Function()? pickJsonSourceFile,
}) {
  return showMacosEditorTallSheet<_CompletedPokedexImportFlowResult>(
    context: context,
    maxWidth: 760,
    builder: (sheetContext) => _PokedexImportFlowSheet(
      workspace: workspace,
      previewImport: previewImport,
      importPokemon: importPokemon,
      searchExternalSpecies: searchExternalSpecies,
      resolveExternalBatchSelection: resolveExternalBatchSelection,
      previewExternalImport: previewExternalImport,
      previewExternalBatchImport: previewExternalBatchImport,
      importExternalBatch: importExternalBatch,
      importExternalPokemon: importExternalPokemon,
      pickJsonSourceFile: pickJsonSourceFile ?? _pickPokedexJsonSourceFile,
    ),
  );
}

Future<String?> _pickPokedexJsonSourceFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['json'],
    withData: false,
  );
  final pickedPath = result?.files.single.path;
  if (pickedPath == null) {
    return null;
  }
  await _beginPokedexImportBundleAccessIfNeeded(pickedPath);
  return pickedPath;
}

Future<void> _beginPokedexImportBundleAccessIfNeeded(
    String selectedPath) async {
  if (defaultTargetPlatform != TargetPlatform.macOS) {
    return;
  }
  try {
    await _macOsImportFileAccessChannel.invokeMethod<void>(
      'beginImportBundleAccess',
      <String, String>{'selectedPath': selectedPath},
    );
  } catch (_) {
    // Best effort only.
  }
}

Future<void> _endPokedexImportBundleAccessIfNeeded() async {
  if (defaultTargetPlatform != TargetPlatform.macOS) {
    return;
  }
  try {
    await _macOsImportFileAccessChannel.invokeMethod<void>(
      'endImportBundleAccess',
    );
  } catch (_) {
    // Best effort only.
  }
}

enum _PokedexImportSourceKind {
  jsonLocal,
  externalApi,
}

enum _PokedexExternalImportMode {
  singleSpecies,
  batchDryRun,
}

enum _PokedexImportWizardStep {
  source,
  jsonFile,
  externalQuery,
  preview,
  result,
}

class _CompletedPokedexImportFlowResult {
  const _CompletedPokedexImportFlowResult({
    required this.feedbackMessage,
    required this.feedbackIsError,
    this.selectedSpeciesId,
    this.shouldRefreshWorkspace = false,
  });

  final String feedbackMessage;
  final bool feedbackIsError;
  final String? selectedSpeciesId;
  final bool shouldRefreshWorkspace;
}

// Le wizard reste séquentiel et local à la présentation.
//
// On ne crée pas de route dédiée ni de state container global :
// - un petit état d'écran pour la progression du modal ;
// - des callbacks injectés pour les use cases ;
// - une seule source de vérité métier dans les résultats applicatifs.
class _PokedexImportFlowSheet extends StatefulWidget {
  const _PokedexImportFlowSheet({
    required this.workspace,
    required this.previewImport,
    required this.importPokemon,
    required this.searchExternalSpecies,
    required this.resolveExternalBatchSelection,
    required this.previewExternalImport,
    required this.previewExternalBatchImport,
    required this.importExternalBatch,
    required this.importExternalPokemon,
    required this.pickJsonSourceFile,
  });

  final ProjectWorkspace workspace;
  final PokedexImportPreviewer previewImport;
  final PokedexImporter importPokemon;
  final PokedexExternalSpeciesSearcher searchExternalSpecies;
  final PokedexExternalBatchSelectionResolver resolveExternalBatchSelection;
  final PokedexExternalImportPreviewer previewExternalImport;
  final PokedexExternalBatchPreviewer previewExternalBatchImport;
  final PokedexExternalBatchImporter importExternalBatch;
  final PokedexExternalImporter importExternalPokemon;
  final Future<String?> Function() pickJsonSourceFile;

  @override
  State<_PokedexImportFlowSheet> createState() =>
      _PokedexImportFlowSheetState();
}

class _PokedexImportFlowSheetState extends State<_PokedexImportFlowSheet> {
  _PokedexImportWizardStep _step = _PokedexImportWizardStep.source;
  _PokedexImportSourceKind _selectedSource = _PokedexImportSourceKind.jsonLocal;
  _PokedexExternalImportMode _externalImportMode =
      _PokedexExternalImportMode.singleSpecies;
  String? _selectedJsonSourcePath;
  PokemonJsonImportPreview? _jsonPreview;
  PokemonExternalImportResult? _externalPreview;
  PokemonExternalBatchImportResult? _externalBatchPreview;
  PokemonExternalBatchImportResult? _externalBatchImportResult;
  PokemonExternalBatchImportProgress? _externalBatchImportProgress;
  bool _isBusy = false;
  bool _isSearchingExternalSpecies = false;
  bool _isResolvingExternalBatch = false;
  String? _errorMessage;
  late final TextEditingController _externalQueryController;
  late final FocusNode _externalQueryFocusNode;
  Timer? _externalQueryDebounceTimer;
  int _externalQuerySearchRequestId = 0;
  PokemonExternalSpeciesSearchResult _externalSpeciesSearchResult =
      const PokemonExternalSpeciesSearchResult.empty(
    rawQuery: '',
    normalizedQuery: '',
  );
  PokemonExternalBatchSelectionResult _externalBatchSelectionResult =
      PokemonExternalBatchSelectionResult.empty(
    rawQuery: '',
    normalizedQuery: '',
  );
  PokemonExternalSpeciesSuggestion? _selectedExternalSuggestion;

  @override
  void initState() {
    super.initState();
    _externalQueryController = TextEditingController();
    _externalQueryFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _externalQueryDebounceTimer?.cancel();
    _externalQueryController.dispose();
    _externalQueryFocusNode.dispose();
    unawaited(_endPokedexImportBundleAccessIfNeeded());
    super.dispose();
  }

  Future<void> _pickJsonSource() async {
    final pickedPath = await widget.pickJsonSourceFile();
    if (!mounted || pickedPath == null) {
      return;
    }
    setState(() {
      _selectedJsonSourcePath = pickedPath;
      _errorMessage = null;
    });
  }

  void _handleExternalModeChanged(_PokedexExternalImportMode mode) {
    if (_externalImportMode == mode) {
      return;
    }

    _externalQueryDebounceTimer?.cancel();
    _externalQuerySearchRequestId += 1;
    setState(() {
      _externalImportMode = mode;
      _selectedExternalSuggestion = null;
      _externalPreview = null;
      _externalBatchPreview = null;
      _externalBatchImportResult = null;
      _externalBatchImportProgress = null;
      _errorMessage = null;
      _isSearchingExternalSpecies = false;
      _isResolvingExternalBatch = false;
      if (mode == _PokedexExternalImportMode.singleSpecies) {
        _externalBatchSelectionResult =
            PokemonExternalBatchSelectionResult.empty(
          rawQuery: _externalQueryController.text,
          normalizedQuery: _externalQueryController.text.trim(),
        );
      } else {
        _externalSpeciesSearchResult =
            const PokemonExternalSpeciesSearchResult.empty(
          rawQuery: '',
          normalizedQuery: '',
        );
      }
    });

    _handleExternalQueryChanged(_externalQueryController.text);
  }

  void _handleExternalQueryChanged(String rawQuery) {
    _externalQueryDebounceTimer?.cancel();
    final normalizedQuery = rawQuery.trim();

    if (normalizedQuery.isEmpty) {
      setState(() {
        _selectedExternalSuggestion = null;
        _isSearchingExternalSpecies = false;
        _isResolvingExternalBatch = false;
        _externalSpeciesSearchResult = PokemonExternalSpeciesSearchResult.empty(
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
        );
        _externalBatchSelectionResult =
            PokemonExternalBatchSelectionResult.empty(
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
        );
        _externalPreview = null;
        _externalBatchPreview = null;
        _externalBatchImportResult = null;
        _externalBatchImportProgress = null;
        _errorMessage = null;
      });
      return;
    }

    final requestId = ++_externalQuerySearchRequestId;
    setState(() {
      _selectedExternalSuggestion = null;
      _externalPreview = null;
      _externalBatchPreview = null;
      _externalBatchImportResult = null;
      _externalBatchImportProgress = null;
      _isSearchingExternalSpecies =
          _externalImportMode == _PokedexExternalImportMode.singleSpecies;
      _isResolvingExternalBatch =
          _externalImportMode == _PokedexExternalImportMode.batchDryRun;
      if (_externalImportMode == _PokedexExternalImportMode.singleSpecies) {
        _externalSpeciesSearchResult = PokemonExternalSpeciesSearchResult.empty(
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
        );
      } else {
        _externalBatchSelectionResult =
            PokemonExternalBatchSelectionResult.empty(
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
        );
      }
      _errorMessage = null;
    });

    final requestedMode = _externalImportMode;

    // Un petit debounce UI suffit ici :
    // - il évite de re-solliciter la résolution à chaque caractère ;
    // - il ne déplace aucune logique métier dans l'UI ;
    // - le vrai contrat reste porté par les use cases injectés.
    _externalQueryDebounceTimer =
        Timer(const Duration(milliseconds: 180), () async {
      if (requestedMode == _PokedexExternalImportMode.singleSpecies) {
        final result = await widget.searchExternalSpecies(rawQuery);
        if (!mounted || requestId != _externalQuerySearchRequestId) {
          return;
        }
        setState(() {
          _isSearchingExternalSpecies = false;
          _externalSpeciesSearchResult = result;
        });
        return;
      }

      final result = await widget.resolveExternalBatchSelection(rawQuery);
      if (!mounted || requestId != _externalQuerySearchRequestId) {
        return;
      }
      setState(() {
        _isResolvingExternalBatch = false;
        _externalBatchSelectionResult = result;
      });
    });
  }

  void _handleExternalSuggestionSelected(
    PokemonExternalSpeciesSuggestion suggestion,
  ) {
    _externalQueryDebounceTimer?.cancel();
    _externalQuerySearchRequestId += 1;
    setState(() {
      _selectedExternalSuggestion = suggestion;
      _isSearchingExternalSpecies = false;
      _errorMessage = null;
    });
  }

  Future<void> _loadPreview() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      switch (_selectedSource) {
        case _PokedexImportSourceKind.jsonLocal:
          final sourcePath = _selectedJsonSourcePath?.trim();
          if (sourcePath == null || sourcePath.isEmpty) {
            throw const EditorValidationException(
              'Sélectionnez un fichier JSON à importer.',
            );
          }
          final preview = await widget.previewImport(
            widget.workspace,
            sourcePath,
          );
          if (!mounted) {
            return;
          }
          setState(() {
            _jsonPreview = preview;
            _externalPreview = null;
            _externalBatchImportResult = null;
            _externalBatchImportProgress = null;
            _step = _PokedexImportWizardStep.preview;
            _isBusy = false;
          });
          break;
        case _PokedexImportSourceKind.externalApi:
          switch (_externalImportMode) {
            case _PokedexExternalImportMode.singleSpecies:
              final selectedSuggestion = _selectedExternalSuggestion;
              if (selectedSuggestion == null) {
                throw const EditorValidationException(
                  'Sélectionnez explicitement une espèce externe avant de prévisualiser.',
                );
              }
              final preview = await widget.previewExternalImport(
                widget.workspace,
                selectedSuggestion.speciesId,
              );
              if (!mounted) {
                return;
              }
              setState(() {
                _externalPreview = preview;
                _externalBatchPreview = null;
                _externalBatchImportResult = null;
                _externalBatchImportProgress = null;
                _jsonPreview = null;
                _step = _PokedexImportWizardStep.preview;
                _isBusy = false;
              });
              break;
            case _PokedexExternalImportMode.batchDryRun:
              final selection = _externalBatchSelectionResult;
              if (!selection.canDryRun) {
                throw const EditorValidationException(
                  'Résolvez d’abord une sélection batch valide avant de lancer le dry-run.',
                );
              }
              final preview = await widget.previewExternalBatchImport(
                widget.workspace,
                selection.resolvedSpeciesIds,
              );
              if (!mounted) {
                return;
              }
              setState(() {
                _externalBatchPreview = preview;
                _externalPreview = null;
                _externalBatchImportResult = null;
                _externalBatchImportProgress = null;
                _jsonPreview = null;
                _step = _PokedexImportWizardStep.preview;
                _isBusy = false;
              });
              break;
          }
          break;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBusy = false;
        _errorMessage = _resolveApplicationMessage(error);
      });
    }
  }

  Future<void> _confirmImport() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      switch (_selectedSource) {
        case _PokedexImportSourceKind.jsonLocal:
          final sourcePath = _selectedJsonSourcePath?.trim();
          if (sourcePath == null || sourcePath.isEmpty) {
            throw const EditorValidationException(
              'Sélectionnez un fichier JSON à importer.',
            );
          }
          final result = await widget.importPokemon(
            widget.workspace,
            sourcePath,
          );
          if (!mounted) {
            return;
          }
          Navigator.of(context).pop(
            _CompletedPokedexImportFlowResult(
              selectedSpeciesId: result.preview.speciesId,
              shouldRefreshWorkspace: true,
              feedbackMessage: _buildSingleImportFeedback(
                primaryName: result.preview.primaryName,
                importedLearnset: result.importedLearnset,
                importedEvolution: result.importedEvolution,
                importedMedia: result.importedMedia,
              ),
              feedbackIsError: false,
            ),
          );
          break;
        case _PokedexImportSourceKind.externalApi:
          switch (_externalImportMode) {
            case _PokedexExternalImportMode.singleSpecies:
              final selectedSuggestion = _selectedExternalSuggestion;
              if (selectedSuggestion == null) {
                throw const EditorValidationException(
                  'Sélectionnez explicitement une espèce externe avant d’importer.',
                );
              }
              final result = await widget.importExternalPokemon(
                widget.workspace,
                selectedSuggestion.speciesId,
              );
              if (!mounted) {
                return;
              }
              if (result.hasConflicts) {
                setState(() {
                  _isBusy = false;
                  _externalPreview = result;
                  _errorMessage =
                      'Des fichiers existent déjà pour cette espèce. L’import externe reste volontairement prudent et ne remplace rien dans cette phase.';
                });
                return;
              }
              Navigator.of(context).pop(
                _CompletedPokedexImportFlowResult(
                  selectedSpeciesId: result.preview.speciesId,
                  shouldRefreshWorkspace: true,
                  feedbackMessage: _buildSingleImportFeedback(
                    primaryName: result.preview.primaryName,
                    importedLearnset: result.importedLearnset,
                    importedEvolution: result.importedEvolution,
                    importedMedia: result.importedMedia,
                    downloadedAssetCount: result.downloadedAssetCount,
                  ),
                  feedbackIsError: false,
                ),
              );
              break;
            case _PokedexExternalImportMode.batchDryRun:
              throw const EditorValidationException(
                'Utilisez l’action dédiée du lot 4 pour exécuter le batch réel depuis la prévisualisation batch.',
              );
          }
          break;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBusy = false;
        _errorMessage = _resolveApplicationMessage(error);
      });
    }
  }

  Future<void> _executeExternalBatchImport() async {
    final selection = _externalBatchSelectionResult;
    if (!selection.canDryRun) {
      setState(() {
        _errorMessage =
            'Résolvez d’abord une sélection batch valide avant d’exécuter l’import.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isBusy = true;
      _externalBatchImportResult = null;
      _externalBatchImportProgress = null;
      // Le lot 4 sépare explicitement la preview dry-run du résultat réel :
      // au clic sur "Exécuter", on bascule immédiatement sur l'écran de
      // résultat, puis on y alimente une progression honnête au fil des
      // callbacks applicatifs.
      _step = _PokedexImportWizardStep.result;
    });

    try {
      final result = await widget.importExternalBatch(
        widget.workspace,
        selection.resolvedSpeciesIds,
        onProgress: (progress) {
          if (!mounted) {
            return;
          }
          setState(() {
            _externalBatchImportProgress = progress;
          });
        },
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isBusy = false;
        _externalBatchImportResult = result;
        _externalBatchImportProgress ??= PokemonExternalBatchImportProgress(
          totalCount: selection.targets.length,
          completedCount: result.entries.length,
          successfulCount: result.successfulCount,
          skippedCount: result.skippedCount,
          conflictCount: result.conflictCount,
          failedCount: result.failedCount,
          lastCompletedSpeciesId:
              result.entries.isEmpty ? '' : result.entries.last.speciesId,
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBusy = false;
        _externalBatchImportResult = null;
        _errorMessage = _resolveApplicationMessage(error);
      });
    }
  }

  String _resolveApplicationMessage(Object error) {
    return switch (error) {
      final EditorApplicationException applicationError =>
        applicationError.message,
      _ => error.toString(),
    };
  }

  void _closeBatchResult() {
    final result = _externalBatchImportResult;
    if (result == null) {
      Navigator.of(context).pop();
      return;
    }

    final selectedSpeciesId = _selectBatchImportedSpeciesId(
      selection: _externalBatchSelectionResult,
      result: result,
    );
    final importedAnySpecies = _hasBatchWritesApplied(result);
    Navigator.of(context).pop(
      _CompletedPokedexImportFlowResult(
        selectedSpeciesId: selectedSpeciesId,
        shouldRefreshWorkspace: importedAnySpecies,
        feedbackMessage: _buildBatchImportFeedback(
          result,
          importedAnySpecies: importedAnySpecies,
        ),
        feedbackIsError: !importedAnySpecies,
      ),
    );
  }

  bool _hasBatchWritesApplied(PokemonExternalBatchImportResult result) {
    return result.entries.any(
      (entry) => entry.result?.hasWritesApplied == true,
    );
  }

  String? _selectBatchImportedSpeciesId({
    required PokemonExternalBatchSelectionResult selection,
    required PokemonExternalBatchImportResult result,
  }) {
    final entriesBySpeciesId = <String, PokemonExternalBatchImportEntryResult>{
      for (final entry in result.entries) entry.speciesId: entry,
    };
    // Règle produit stable retenue pour le refresh du workspace :
    // on choisit la première espèce réellement écrite en respectant l'ordre
    // visible de la sélection batch, pas l'ordre interne du use case.
    for (final target in selection.targets) {
      final entry = entriesBySpeciesId[target.speciesId];
      if (entry?.result?.hasWritesApplied == true) {
        return target.speciesId;
      }
    }
    return null;
  }

  String _buildSingleImportFeedback({
    required String primaryName,
    required bool importedLearnset,
    required bool importedEvolution,
    required bool importedMedia,
    int downloadedAssetCount = 0,
  }) {
    final importedArtifacts = <String>[
      'espèce',
      if (importedLearnset) 'learnset',
      if (importedEvolution) 'évolutions',
      if (importedMedia) 'médias',
    ];
    if (downloadedAssetCount > 0) {
      importedArtifacts.add('$downloadedAssetCount assets');
    }
    return 'Import terminé pour $primaryName · ${importedArtifacts.join(', ')}';
  }

  String _buildBatchImportFeedback(
    PokemonExternalBatchImportResult result, {
    required bool importedAnySpecies,
  }) {
    final prefix =
        importedAnySpecies ? 'Batch terminé' : 'Aucune espèce importée';
    return '$prefix · ${result.successfulCount} succès, '
        '${result.conflictCount} conflits, ${result.failedCount} erreurs, '
        '${result.skippedCount} skips';
  }

  void _continueFromSource() {
    setState(() {
      _errorMessage = null;
      _step = switch (_selectedSource) {
        _PokedexImportSourceKind.jsonLocal => _PokedexImportWizardStep.jsonFile,
        _PokedexImportSourceKind.externalApi =>
          _PokedexImportWizardStep.externalQuery,
      };
    });
  }

  void _goBackFromPreview() {
    setState(() {
      _errorMessage = null;
      _step = switch (_selectedSource) {
        _PokedexImportSourceKind.jsonLocal => _PokedexImportWizardStep.jsonFile,
        _PokedexImportSourceKind.externalApi =>
          _PokedexImportWizardStep.externalQuery,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    // Le sheet macOS fournit le cadre général, mais pas de marge interne forte.
    // On ajoute donc ici un padding commun à tout le wizard :
    // - même respiration sur chaque étape ;
    // - aucun besoin de répéter des `Padding` différents dans chaque widget ;
    // - correction purement visuelle, sans toucher à la logique du flow.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: switch (_step) {
        _PokedexImportWizardStep.source => _PokedexImportSourceStep(
            selectedSource: _selectedSource,
            onSourceSelected: (value) {
              setState(() {
                _selectedSource = value;
                _errorMessage = null;
              });
            },
            onContinue: _continueFromSource,
            onCancel: () => Navigator.of(context).pop(),
          ),
        _PokedexImportWizardStep.jsonFile => _PokedexImportJsonFileStep(
            selectedJsonSourcePath: _selectedJsonSourcePath,
            isBusy: _isBusy,
            errorMessage: _errorMessage,
            onPickJsonSource: _pickJsonSource,
            onContinue: _loadPreview,
            onCancel: () => Navigator.of(context).pop(),
          ),
        _PokedexImportWizardStep.externalQuery =>
          _PokedexImportExternalQueryStep(
            externalImportMode: _externalImportMode,
            controller: _externalQueryController,
            focusNode: _externalQueryFocusNode,
            isBusy: _isBusy,
            isSearching: _isSearchingExternalSpecies,
            isResolvingBatch: _isResolvingExternalBatch,
            errorMessage: _errorMessage,
            searchResult: _externalSpeciesSearchResult,
            batchSelectionResult: _externalBatchSelectionResult,
            selectedSuggestion: _selectedExternalSuggestion,
            onModeChanged: _handleExternalModeChanged,
            onQueryChanged: _handleExternalQueryChanged,
            onSuggestionSelected: _handleExternalSuggestionSelected,
            onContinue: _loadPreview,
            onCancel: () => Navigator.of(context).pop(),
          ),
        _PokedexImportWizardStep.preview => switch (_selectedSource) {
            _PokedexImportSourceKind.jsonLocal => _PokedexImportPreviewStep(
                preview: _jsonPreview!,
                isBusy: _isBusy,
                errorMessage: _errorMessage,
                onBack: _goBackFromPreview,
                onImport: _confirmImport,
              ),
            _PokedexImportSourceKind.externalApi => switch (
                  _externalImportMode) {
                _PokedexExternalImportMode.singleSpecies =>
                  _PokedexExternalImportPreviewStep(
                    preview: _externalPreview!,
                    isBusy: _isBusy,
                    errorMessage: _errorMessage,
                    onBack: _goBackFromPreview,
                    onImport: _confirmImport,
                  ),
                _PokedexExternalImportMode.batchDryRun =>
                  _PokedexExternalBatchPreviewStep(
                    selection: _externalBatchSelectionResult,
                    preview: _externalBatchPreview!,
                    isBusy: _isBusy,
                    errorMessage: _errorMessage,
                    onBack: _goBackFromPreview,
                    onImport: _executeExternalBatchImport,
                    onClose: () => Navigator.of(context).pop(),
                  ),
              },
          },
        _PokedexImportWizardStep.result =>
          _PokedexExternalBatchExecutionResultStep(
            selection: _externalBatchSelectionResult,
            progress: _externalBatchImportProgress,
            result: _externalBatchImportResult,
            isBusy: _isBusy,
            errorMessage: _errorMessage,
            onClose: _closeBatchResult,
          ),
      },
    );
  }
}

```


### `packages/map_editor/test/pokedex_external_batch_execute_ui_test.dart`

```text
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/pokedex_species_detail.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/models/pokemon_external_batch_selection.dart';
import 'package:map_editor/src/application/models/pokemon_external_query_resolution.dart';
import 'package:map_editor/src/application/models/pokemon_external_species_search_result.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/import_external_pokemon_use_cases.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/pokedex_workspace.dart';

void main() {
  const sampleProject = ProjectManifest(
    name: 'pokedex_external_batch_execute_test',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
  );

  Future<void> pumpPokedexWidget(
    WidgetTester tester,
    ProviderContainer container, {
    required Widget child,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 980);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: MacosApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 1280,
                height: 900,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openBatchPreview(
    WidgetTester tester, {
    required String query,
  }) async {
    await tester
        .tap(find.byKey(const Key('pokedex-empty-state-import-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('pokedex-import-external-api-source-card')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('pokedex-import-source-continue-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('pokedex-import-external-mode-batch-option')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pokedex-import-external-batch-query-field')),
      query,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    await tester.tap(
      find.byKey(const Key('pokedex-import-external-batch-preview-button')),
    );
    await tester.pumpAndSettle();
  }

  PokedexWorkspace buildWorkspace({
    required Future<PokemonExternalBatchSelectionResult> Function(
      String rawQuery,
    ) externalBatchSelectionResolver,
    required Future<PokemonExternalBatchImportResult> Function(
      ProjectWorkspace workspace,
      List<String> speciesIds,
    ) externalBatchPreviewer,
    required Future<PokemonExternalBatchImportResult> Function(
      ProjectWorkspace workspace,
      List<String> speciesIds, {
      void Function(PokemonExternalBatchImportProgress progress)? onProgress,
    }) externalBatchImporter,
    required Future<List<PokemonDatabaseIndexEntry>> Function(
      ProjectWorkspace workspace,
    ) loader,
    required Future<PokedexSpeciesDetail> Function(
      ProjectWorkspace workspace,
      String speciesId,
    ) detailLoader,
  }) {
    return PokedexWorkspace(
      loader: loader,
      detailLoader: detailLoader,
      importPreviewer: (_, __) async => throw UnimplementedError(),
      importer: (_, __) async => throw UnimplementedError(),
      externalSpeciesSearcher: (rawQuery) async =>
          const PokemonExternalSpeciesSearchResult.empty(
        rawQuery: '',
        normalizedQuery: '',
      ),
      externalBatchSelectionResolver: externalBatchSelectionResolver,
      externalBatchPreviewer: externalBatchPreviewer,
      externalBatchImporter: externalBatchImporter,
      externalImportPreviewer: (_, __) async => throw UnimplementedError(),
      externalImporter: (_, __) async => throw UnimplementedError(),
    );
  }

  testWidgets(
      'keeps dry-run and batch execution separate and shows a final report',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var previewCallCount = 0;
    var importCallCount = 0;
    final executedSpeciesIds = <List<String>>[];

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_batch_execute_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        loader: (_) async => const <PokemonDatabaseIndexEntry>[],
        detailLoader: (_, __) async => _buildDetail(
          id: 'pikachu',
          nationalDex: 25,
          primaryName: 'Pikachu',
          types: const <String>['electric'],
        ),
        externalBatchSelectionResolver: (rawQuery) async =>
            _resolvedBatchSelection(),
        externalBatchPreviewer: (_, speciesIds) async {
          previewCallCount += 1;
          expect(speciesIds, <String>['pikachu', 'bulbasaur']);
          return _sampleBatchDryRunPreview();
        },
        externalBatchImporter: (_, speciesIds, {onProgress}) async {
          importCallCount += 1;
          executedSpeciesIds.add(List<String>.from(speciesIds));
          onProgress?.call(
            const PokemonExternalBatchImportProgress(
              totalCount: 2,
              completedCount: 1,
              successfulCount: 1,
              skippedCount: 0,
              conflictCount: 0,
              failedCount: 0,
              lastCompletedSpeciesId: 'pikachu',
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 10));
          onProgress?.call(
            const PokemonExternalBatchImportProgress(
              totalCount: 2,
              completedCount: 2,
              successfulCount: 1,
              skippedCount: 0,
              conflictCount: 1,
              failedCount: 0,
              lastCompletedSpeciesId: 'bulbasaur',
            ),
          );
          return _sampleBatchImportResult();
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openBatchPreview(
      tester,
      query: 'pikachu, 25, bulbasaur',
    );

    expect(previewCallCount, 1);
    expect(importCallCount, 0);
    expect(
      find.byKey(const Key('pokedex-import-external-batch-preview-step')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('pokedex-import-external-batch-execute-button')),
    );
    await tester.pump();

    expect(importCallCount, 1);
    expect(
      find.byKey(const Key('pokedex-import-external-batch-result-step')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Progression observée : 1 / 2'),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 20));
    await tester.pumpAndSettle();

    expect(previewCallCount, 1);
    expect(
      executedSpeciesIds,
      <List<String>>[
        <String>['pikachu', 'bulbasaur'],
      ],
    );
    expect(
      find.textContaining('Progression observée : 2 / 2'),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('pokedex-import-external-batch-result-entry-pikachu'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('pokedex-import-external-batch-result-entry-bulbasaur'),
      ),
      findsOneWidget,
    );
    expect(find.text('Import réussi'), findsOneWidget);
    expect(find.text('Conflit'), findsOneWidget);
  });

  testWidgets(
      'refreshes the workspace and selects the first imported species after a real batch',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final importedDetailsById = <String, PokedexSpeciesDetail>{};
    final detailRequests = <String>[];
    var entries = <PokemonDatabaseIndexEntry>[];

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_batch_execute_workspace_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        loader: (_) async => entries,
        detailLoader: (_, speciesId) async {
          detailRequests.add(speciesId);
          return importedDetailsById[speciesId]!;
        },
        externalBatchSelectionResolver: (rawQuery) async =>
            _resolvedBatchSelection(),
        externalBatchPreviewer: (_, __) async => _sampleBatchDryRunPreview(),
        externalBatchImporter: (_, __, {onProgress}) async {
          importedDetailsById['pikachu'] = _buildDetail(
            id: 'pikachu',
            nationalDex: 25,
            primaryName: 'Pikachu',
            types: const <String>['electric'],
          );
          importedDetailsById['bulbasaur'] = _buildDetail(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: const <String>['grass', 'poison'],
          );
          entries = <PokemonDatabaseIndexEntry>[
            _buildEntry(
              id: 'bulbasaur',
              nationalDex: 1,
              primaryName: 'Bulbasaur',
              types: const <String>['grass', 'poison'],
            ),
            _buildEntry(
              id: 'pikachu',
              nationalDex: 25,
              primaryName: 'Pikachu',
              types: const <String>['electric'],
            ),
          ];
          onProgress?.call(
            const PokemonExternalBatchImportProgress(
              totalCount: 2,
              completedCount: 2,
              successfulCount: 2,
              skippedCount: 0,
              conflictCount: 0,
              failedCount: 0,
              lastCompletedSpeciesId: 'bulbasaur',
            ),
          );
          return _sampleBatchImportResult(
            orderedEntries: <PokemonExternalBatchImportEntryResult>[
              _successfulBatchEntry(
                speciesId: 'bulbasaur',
                nationalDex: 1,
                primaryName: 'Bulbasaur',
                types: const <String>['grass', 'poison'],
              ),
              _successfulBatchEntry(
                speciesId: 'pikachu',
                nationalDex: 25,
                primaryName: 'Pikachu',
                types: const <String>['electric'],
              ),
            ],
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openBatchPreview(
      tester,
      query: 'pikachu, 25, bulbasaur',
    );
    await tester.tap(
      find.byKey(const Key('pokedex-import-external-batch-execute-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('pokedex-import-external-batch-result-step')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
          const Key('pokedex-import-external-batch-result-close-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pokedex-row-pikachu')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-row-bulbasaur')), findsOneWidget);
    expect(detailRequests, contains('pikachu'));
    expect(
      find.byKey(const Key('pokedex-feedback-banner')),
      findsOneWidget,
    );
    expect(
      find.text('Batch terminé · 2 succès, 0 conflits, 0 erreurs, 0 skips'),
      findsOneWidget,
    );
    expect(
      find.byIcon(CupertinoIcons.check_mark_circled_solid),
      findsOneWidget,
    );
  });

  testWidgets(
      'shows an error feedback when no species was imported because all entries conflicted',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final detailRequests = <String>[];

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_batch_execute_conflicts_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        loader: (_) async => const <PokemonDatabaseIndexEntry>[],
        detailLoader: (_, speciesId) async {
          detailRequests.add(speciesId);
          return _buildDetail(
            id: speciesId,
            nationalDex: 25,
            primaryName: 'Unused',
            types: const <String>['normal'],
          );
        },
        externalBatchSelectionResolver: (rawQuery) async =>
            _resolvedBatchSelection(),
        externalBatchPreviewer: (_, __) async => _sampleBatchDryRunPreview(),
        externalBatchImporter: (_, __, {onProgress}) async {
          onProgress?.call(
            const PokemonExternalBatchImportProgress(
              totalCount: 2,
              completedCount: 2,
              successfulCount: 0,
              skippedCount: 0,
              conflictCount: 2,
              failedCount: 0,
              lastCompletedSpeciesId: 'bulbasaur',
            ),
          );
          return _conflictsOnlyBatchImportResult();
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openBatchPreview(
      tester,
      query: 'pikachu, 25, bulbasaur',
    );
    await tester.tap(
      find.byKey(const Key('pokedex-import-external-batch-execute-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('pokedex-import-external-batch-result-close-button'),
      ),
    );
    await tester.pumpAndSettle();

    expect(detailRequests, isEmpty);
    expect(
      find.text(
          'Aucune espèce importée · 0 succès, 2 conflits, 0 erreurs, 0 skips'),
      findsOneWidget,
    );
    expect(
      find.byIcon(CupertinoIcons.exclamationmark_triangle_fill),
      findsOneWidget,
    );
  });

  testWidgets(
      'shows an error feedback when no species was imported because all entries were skipped',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final detailRequests = <String>[];

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_batch_execute_skips_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        loader: (_) async => const <PokemonDatabaseIndexEntry>[],
        detailLoader: (_, speciesId) async {
          detailRequests.add(speciesId);
          return _buildDetail(
            id: speciesId,
            nationalDex: 25,
            primaryName: 'Unused',
            types: const <String>['normal'],
          );
        },
        externalBatchSelectionResolver: (rawQuery) async =>
            _resolvedBatchSelection(),
        externalBatchPreviewer: (_, __) async => _sampleBatchDryRunPreview(),
        externalBatchImporter: (_, __, {onProgress}) async {
          onProgress?.call(
            const PokemonExternalBatchImportProgress(
              totalCount: 2,
              completedCount: 2,
              successfulCount: 0,
              skippedCount: 2,
              conflictCount: 0,
              failedCount: 0,
              lastCompletedSpeciesId: 'bulbasaur',
            ),
          );
          return _skipsOnlyBatchImportResult();
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openBatchPreview(
      tester,
      query: 'pikachu, 25, bulbasaur',
    );
    await tester.tap(
      find.byKey(const Key('pokedex-import-external-batch-execute-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('pokedex-import-external-batch-result-close-button'),
      ),
    );
    await tester.pumpAndSettle();

    expect(detailRequests, isEmpty);
    expect(
      find.text(
          'Aucune espèce importée · 0 succès, 0 conflits, 0 erreurs, 2 skips'),
      findsOneWidget,
    );
    expect(
      find.byIcon(CupertinoIcons.exclamationmark_triangle_fill),
      findsOneWidget,
    );
  });

  testWidgets(
      'shows an error feedback when no species was imported because entries were skipped or conflicted',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final detailRequests = <String>[];

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_batch_execute_mixed_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        loader: (_) async => const <PokemonDatabaseIndexEntry>[],
        detailLoader: (_, speciesId) async {
          detailRequests.add(speciesId);
          return _buildDetail(
            id: speciesId,
            nationalDex: 25,
            primaryName: 'Unused',
            types: const <String>['normal'],
          );
        },
        externalBatchSelectionResolver: (rawQuery) async =>
            _resolvedBatchSelection(),
        externalBatchPreviewer: (_, __) async => _sampleBatchDryRunPreview(),
        externalBatchImporter: (_, __, {onProgress}) async {
          onProgress?.call(
            const PokemonExternalBatchImportProgress(
              totalCount: 2,
              completedCount: 2,
              successfulCount: 0,
              skippedCount: 1,
              conflictCount: 1,
              failedCount: 0,
              lastCompletedSpeciesId: 'bulbasaur',
            ),
          );
          return _mixedNoWriteBatchImportResult();
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openBatchPreview(
      tester,
      query: 'pikachu, 25, bulbasaur',
    );
    await tester.tap(
      find.byKey(const Key('pokedex-import-external-batch-execute-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('pokedex-import-external-batch-result-close-button'),
      ),
    );
    await tester.pumpAndSettle();

    expect(detailRequests, isEmpty);
    expect(
      find.text(
          'Aucune espèce importée · 0 succès, 1 conflits, 0 erreurs, 1 skips'),
      findsOneWidget,
    );
    expect(
      find.byIcon(CupertinoIcons.exclamationmark_triangle_fill),
      findsOneWidget,
    );
  });
}

PokemonExternalBatchSelectionResult _resolvedBatchSelection() {
  return PokemonExternalBatchSelectionResult.resolved(
    rawQuery: 'pikachu, 25, bulbasaur',
    normalizedQuery: 'pikachu, 25, bulbasaur',
    resolution: PokemonExternalExplicitListQueryResolution(
      rawQuery: 'pikachu, 25, bulbasaur',
      normalizedQuery: 'pikachu, 25, bulbasaur',
      queries: const <PokemonExternalSingleQuery>[
        PokemonExternalSingleQuery.species(
          rawValue: 'pikachu',
          normalizedValue: 'pikachu',
        ),
        PokemonExternalSingleQuery.nationalDex(
          rawValue: '25',
          nationalDex: 25,
        ),
        PokemonExternalSingleQuery.species(
          rawValue: 'bulbasaur',
          normalizedValue: 'bulbasaur',
        ),
      ],
    ),
    targets: <PokemonExternalBatchSelectionTarget>[
      PokemonExternalBatchSelectionTarget(
        speciesId: 'pikachu',
        primaryName: 'Pikachu',
        nationalDex: 25,
        generation: 1,
        requestedInputs: const <String>['pikachu', '25'],
      ),
      PokemonExternalBatchSelectionTarget(
        speciesId: 'bulbasaur',
        primaryName: 'Bulbasaur',
        nationalDex: 1,
        generation: 1,
        requestedInputs: const <String>['bulbasaur'],
      ),
    ],
  );
}

PokemonExternalBatchImportResult _sampleBatchDryRunPreview() {
  return PokemonExternalBatchImportResult(
    dryRun: true,
    mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
    entries: <PokemonExternalBatchImportEntryResult>[
      _successfulBatchEntry(
        speciesId: 'pikachu',
        nationalDex: 25,
        primaryName: 'Pikachu',
        types: const <String>['electric'],
        dryRun: true,
      ),
      _conflictBatchEntry(
        speciesId: 'bulbasaur',
        nationalDex: 1,
        primaryName: 'Bulbasaur',
        types: const <String>['grass', 'poison'],
        dryRun: true,
      ),
    ],
  );
}

PokemonExternalBatchImportResult _sampleBatchImportResult({
  List<PokemonExternalBatchImportEntryResult>? orderedEntries,
}) {
  return PokemonExternalBatchImportResult(
    dryRun: false,
    mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
    entries: orderedEntries ??
        <PokemonExternalBatchImportEntryResult>[
          _successfulBatchEntry(
            speciesId: 'pikachu',
            nationalDex: 25,
            primaryName: 'Pikachu',
            types: const <String>['electric'],
          ),
          _conflictBatchEntry(
            speciesId: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: const <String>['grass', 'poison'],
          ),
        ],
  );
}

PokemonExternalBatchImportResult _conflictsOnlyBatchImportResult() {
  return PokemonExternalBatchImportResult(
    dryRun: false,
    mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
    entries: <PokemonExternalBatchImportEntryResult>[
      _conflictBatchEntry(
        speciesId: 'pikachu',
        nationalDex: 25,
        primaryName: 'Pikachu',
        types: const <String>['electric'],
      ),
      _conflictBatchEntry(
        speciesId: 'bulbasaur',
        nationalDex: 1,
        primaryName: 'Bulbasaur',
        types: const <String>['grass', 'poison'],
      ),
    ],
  );
}

PokemonExternalBatchImportResult _skipsOnlyBatchImportResult() {
  return PokemonExternalBatchImportResult(
    dryRun: false,
    mergePolicy: PokemonExternalImportMergePolicy.skipExisting,
    entries: <PokemonExternalBatchImportEntryResult>[
      _skippedBatchEntry(
        speciesId: 'pikachu',
        nationalDex: 25,
        primaryName: 'Pikachu',
        types: const <String>['electric'],
      ),
      _skippedBatchEntry(
        speciesId: 'bulbasaur',
        nationalDex: 1,
        primaryName: 'Bulbasaur',
        types: const <String>['grass', 'poison'],
      ),
    ],
  );
}

PokemonExternalBatchImportResult _mixedNoWriteBatchImportResult() {
  return PokemonExternalBatchImportResult(
    dryRun: false,
    mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
    entries: <PokemonExternalBatchImportEntryResult>[
      _conflictBatchEntry(
        speciesId: 'pikachu',
        nationalDex: 25,
        primaryName: 'Pikachu',
        types: const <String>['electric'],
      ),
      _skippedBatchEntry(
        speciesId: 'bulbasaur',
        nationalDex: 1,
        primaryName: 'Bulbasaur',
        types: const <String>['grass', 'poison'],
      ),
    ],
  );
}

PokemonExternalBatchImportEntryResult _successfulBatchEntry({
  required String speciesId,
  required int nationalDex,
  required String primaryName,
  required List<String> types,
  bool dryRun = false,
}) {
  return PokemonExternalBatchImportEntryResult(
    speciesId: speciesId,
    result: PokemonExternalImportResult(
      requestedSpeciesId: speciesId,
      importedSpeciesId: speciesId,
      preview: _previewFor(
        speciesId: speciesId,
        nationalDex: nationalDex,
        primaryName: primaryName,
        types: types,
      ),
      dryRun: dryRun,
      mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
      artifacts: <PokemonExternalImportArtifactResult>[
        PokemonExternalImportArtifactResult(
          kind: PokemonExternalImportArtifactKind.species,
          relativePath:
              'data/pokemon/species/${nationalDex.toString().padLeft(4, '0')}-$speciesId.json',
          action: dryRun
              ? PokemonExternalImportArtifactAction.create
              : PokemonExternalImportArtifactAction.create,
          existedBefore: false,
        ),
      ],
      downloadedAssets: dryRun
          ? const <PokemonExternalAssetDownloadResult>[]
          : <PokemonExternalAssetDownloadResult>[
              PokemonExternalAssetDownloadResult(
                label: 'Portrait',
                relativePath: 'assets/pokemon/portraits/$speciesId.png',
                sourceUrl: 'https://assets.example.test/$speciesId.png',
                wasWritten: true,
              ),
            ],
      warnings: const <String>[
        'Import best-effort.',
      ],
    ),
  );
}

PokemonExternalBatchImportEntryResult _conflictBatchEntry({
  required String speciesId,
  required int nationalDex,
  required String primaryName,
  required List<String> types,
  bool dryRun = false,
}) {
  return PokemonExternalBatchImportEntryResult(
    speciesId: speciesId,
    result: PokemonExternalImportResult(
      requestedSpeciesId: speciesId,
      importedSpeciesId: speciesId,
      preview: _previewFor(
        speciesId: speciesId,
        nationalDex: nationalDex,
        primaryName: primaryName,
        types: types,
      ),
      dryRun: dryRun,
      mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
      artifacts: <PokemonExternalImportArtifactResult>[
        PokemonExternalImportArtifactResult(
          kind: PokemonExternalImportArtifactKind.species,
          relativePath:
              'data/pokemon/species/${nationalDex.toString().padLeft(4, '0')}-$speciesId.json',
          action: PokemonExternalImportArtifactAction.conflict,
          existedBefore: true,
        ),
      ],
    ),
  );
}

PokemonExternalBatchImportEntryResult _skippedBatchEntry({
  required String speciesId,
  required int nationalDex,
  required String primaryName,
  required List<String> types,
}) {
  return PokemonExternalBatchImportEntryResult(
    speciesId: speciesId,
    result: PokemonExternalImportResult(
      requestedSpeciesId: speciesId,
      importedSpeciesId: speciesId,
      preview: _previewFor(
        speciesId: speciesId,
        nationalDex: nationalDex,
        primaryName: primaryName,
        types: types,
      ),
      dryRun: false,
      mergePolicy: PokemonExternalImportMergePolicy.skipExisting,
      artifacts: <PokemonExternalImportArtifactResult>[
        PokemonExternalImportArtifactResult(
          kind: PokemonExternalImportArtifactKind.species,
          relativePath:
              'data/pokemon/species/${nationalDex.toString().padLeft(4, '0')}-$speciesId.json',
          action: PokemonExternalImportArtifactAction.skip,
          existedBefore: true,
        ),
      ],
    ),
  );
}

PokemonExternalImportPreview _previewFor({
  required String speciesId,
  required int nationalDex,
  required String primaryName,
  required List<String> types,
}) {
  return PokemonExternalImportPreview(
    speciesId: speciesId,
    nationalDex: nationalDex,
    primaryName: primaryName,
    types: types,
    learnset: const PokemonExternalImportPreviewArtifact(
      label: 'Learnset',
      isAvailable: true,
    ),
    evolution: const PokemonExternalImportPreviewArtifact(
      label: 'Evolution',
      isAvailable: true,
    ),
    media: const PokemonExternalImportPreviewArtifact(
      label: 'Media',
      isAvailable: true,
    ),
    cries: const PokemonExternalImportPreviewArtifact(
      label: 'Cries',
      isAvailable: true,
    ),
  );
}

PokemonDatabaseIndexEntry _buildEntry({
  required String id,
  required int nationalDex,
  required String primaryName,
  required List<String> types,
}) {
  return PokemonDatabaseIndexEntry(
    id: id,
    nationalDex: nationalDex,
    primaryName: primaryName,
    genIntroduced: 1,
    types: types,
    isEnabledInProject: true,
    refs: PokemonDatabaseIndexRefs(
      learnset: id,
      evolution: id,
      media: id,
    ),
  );
}

PokedexSpeciesDetail _buildDetail({
  required String id,
  required int nationalDex,
  required String primaryName,
  required List<String> types,
}) {
  return PokedexSpeciesDetail(
    species: PokemonSpeciesFile(
      id: id,
      slug: id,
      nationalDex: nationalDex,
      names: <String, String>{
        'fr': primaryName,
        'en': primaryName,
      },
      speciesName: const <String, String>{
        'fr': 'Pokémon test',
        'en': 'Test Pokemon',
      },
      genIntroduced: 1,
      typing: PokemonSpeciesTyping(types: types),
      baseStats: const PokemonSpeciesBaseStats(
        hp: 45,
        atk: 49,
        def: 49,
        spa: 65,
        spd: 65,
        spe: 45,
        bst: 318,
      ),
      abilities: const PokemonSpeciesAbilities(primary: 'static'),
      breeding: const PokemonSpeciesBreeding(
        genderRatio: <String, double>{'male': 0.5, 'female': 0.5},
        eggGroups: <String>['field'],
        hatchCycles: 20,
      ),
      progression: const PokemonSpeciesProgression(
        growthRateId: 'medium_fast',
        baseExp: 64,
        catchRate: 45,
        baseFriendship: 50,
      ),
      forms: PokemonSpeciesForms(
        baseFormId: id,
        isBaseForm: true,
        formId: 'base',
        otherForms: const <String>[],
      ),
      classification: const PokemonSpeciesClassification(
        isEnabledInProject: true,
        isObtainable: true,
      ),
      refs: PokemonSpeciesRefs(
        learnset: id,
        evolution: id,
        media: id,
      ),
      dexContent: const PokemonSpeciesDexContent(
        heightM: 0.7,
        weightKg: 6.9,
        color: 'yellow',
      ),
      gameplayFlags: const PokemonSpeciesGameplayFlags(),
      sourceMeta: const PokemonSpeciesSourceMeta(
        seededBy: 'test',
        seedVersion: 1,
      ),
    ),
    learnset: PokemonLearnsetFile(
      speciesId: id,
    ),
    evolution: PokemonEvolutionFile(
      speciesId: id,
    ),
    media: PokemonMediaFile(
      speciesId: id,
      defaultFormId: 'base',
      variants: const <String, PokemonMediaVariant>{
        'base': PokemonMediaVariant(),
      },
    ),
  );
}

```

## 14. Confirmation explicite

Aucun commit git n'a été fait.
Aucun amend, merge, rebase, push, stash, tag ou reset n'a été fait.
