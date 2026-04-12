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
