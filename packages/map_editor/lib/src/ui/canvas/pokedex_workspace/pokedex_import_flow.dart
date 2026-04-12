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
  required PokedexExternalImportPreviewer previewExternalImport,
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
      previewExternalImport: previewExternalImport,
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

enum _PokedexImportWizardStep {
  source,
  jsonFile,
  externalQuery,
  preview,
}

class _CompletedPokedexImportFlowResult {
  const _CompletedPokedexImportFlowResult({
    required this.speciesId,
    required this.primaryName,
    required this.importedLearnset,
    required this.importedEvolution,
    required this.importedMedia,
    this.downloadedAssetCount = 0,
  });

  final String speciesId;
  final String primaryName;
  final bool importedLearnset;
  final bool importedEvolution;
  final bool importedMedia;
  final int downloadedAssetCount;
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
    required this.previewExternalImport,
    required this.importExternalPokemon,
    required this.pickJsonSourceFile,
  });

  final ProjectWorkspace workspace;
  final PokedexImportPreviewer previewImport;
  final PokedexImporter importPokemon;
  final PokedexExternalImportPreviewer previewExternalImport;
  final PokedexExternalImporter importExternalPokemon;
  final Future<String?> Function() pickJsonSourceFile;

  @override
  State<_PokedexImportFlowSheet> createState() =>
      _PokedexImportFlowSheetState();
}

class _PokedexImportFlowSheetState extends State<_PokedexImportFlowSheet> {
  _PokedexImportWizardStep _step = _PokedexImportWizardStep.source;
  _PokedexImportSourceKind _selectedSource = _PokedexImportSourceKind.jsonLocal;
  String? _selectedJsonSourcePath;
  PokemonJsonImportPreview? _jsonPreview;
  PokemonExternalImportResult? _externalPreview;
  bool _isBusy = false;
  String? _errorMessage;
  late final TextEditingController _externalQueryController;

  @override
  void initState() {
    super.initState();
    _externalQueryController = TextEditingController();
  }

  @override
  void dispose() {
    _externalQueryController.dispose();
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
            _step = _PokedexImportWizardStep.preview;
            _isBusy = false;
          });
          break;
        case _PokedexImportSourceKind.externalApi:
          final speciesQuery = _externalQueryController.text.trim();
          if (speciesQuery.isEmpty) {
            throw const EditorValidationException(
              'Saisissez un nom, un slug ou un numéro Pokédex.',
            );
          }
          final preview = await widget.previewExternalImport(
            widget.workspace,
            speciesQuery,
          );
          if (!mounted) {
            return;
          }
          setState(() {
            _externalPreview = preview;
            _jsonPreview = null;
            _step = _PokedexImportWizardStep.preview;
            _isBusy = false;
          });
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
              speciesId: result.preview.speciesId,
              primaryName: result.preview.primaryName,
              importedLearnset: result.importedLearnset,
              importedEvolution: result.importedEvolution,
              importedMedia: result.importedMedia,
            ),
          );
          break;
        case _PokedexImportSourceKind.externalApi:
          final speciesQuery = _externalQueryController.text.trim();
          if (speciesQuery.isEmpty) {
            throw const EditorValidationException(
              'Saisissez un nom, un slug ou un numéro Pokédex.',
            );
          }
          final result = await widget.importExternalPokemon(
            widget.workspace,
            speciesQuery,
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
              speciesId: result.preview.speciesId,
              primaryName: result.preview.primaryName,
              importedLearnset: result.importedLearnset,
              importedEvolution: result.importedEvolution,
              importedMedia: result.importedMedia,
              downloadedAssetCount: result.downloadedAssetCount,
            ),
          );
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

  String _resolveApplicationMessage(Object error) {
    return switch (error) {
      final EditorApplicationException applicationError =>
        applicationError.message,
      _ => error.toString(),
    };
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
    return switch (_step) {
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
      _PokedexImportWizardStep.externalQuery => _PokedexImportExternalQueryStep(
          controller: _externalQueryController,
          isBusy: _isBusy,
          errorMessage: _errorMessage,
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
          _PokedexImportSourceKind.externalApi =>
            _PokedexExternalImportPreviewStep(
              preview: _externalPreview!,
              isBusy: _isBusy,
              errorMessage: _errorMessage,
              onBack: _goBackFromPreview,
              onImport: _confirmImport,
            ),
        },
    };
  }
}
