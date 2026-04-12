part of 'pokedex_workspace_page.dart';

// Orchestration du flow d'import JSON.
//
// La feuille modale guide l'utilisateur dans un enchaînement lisible : source,
// fichier, aperçu puis confirmation. Les use cases existants restent la seule
// porte d'entrée métier de l'import.

Future<PokemonJsonImportResult?> showPokedexImportFlowSheet({
  required BuildContext context,
  required ProjectWorkspace workspace,
  required PokedexImportPreviewer previewImport,
  required PokedexImporter importPokemon,
  Future<String?> Function()? pickJsonSourceFile,
}) {
  // Le picker natif reste confiné à la présentation :
  // - la UI choisit un chemin local ;
  // - l’application lit, valide et importe ;
  // - aucun widget ne parse de JSON ni ne décide du write.
  return showMacosEditorTallSheet<PokemonJsonImportResult>(
    context: context,
    maxWidth: 760,
    builder: (sheetContext) => _PokedexImportFlowSheet(
      workspace: workspace,
      previewImport: previewImport,
      importPokemon: importPokemon,
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

enum _PokedexImportWizardStep {
  source,
  jsonFile,
  preview,
}

// Le wizard reste volontairement petit et séquentiel.
// On ne crée pas de route dédiée ni de nouveau state container global :
// - l’étape "source" choisit la famille d’import ;
// - l’étape "jsonFile" choisit le fichier local ;
// - l’étape "preview" montre la synthèse applicative avant le write.
class _PokedexImportFlowSheet extends StatefulWidget {
  const _PokedexImportFlowSheet({
    required this.workspace,
    required this.previewImport,
    required this.importPokemon,
    required this.pickJsonSourceFile,
  });

  final ProjectWorkspace workspace;
  final PokedexImportPreviewer previewImport;
  final PokedexImporter importPokemon;
  final Future<String?> Function() pickJsonSourceFile;

  @override
  State<_PokedexImportFlowSheet> createState() =>
      _PokedexImportFlowSheetState();
}

class _PokedexImportFlowSheetState extends State<_PokedexImportFlowSheet> {
  _PokedexImportWizardStep _step = _PokedexImportWizardStep.source;
  String? _selectedJsonSourcePath;
  PokemonJsonImportPreview? _preview;
  bool _isBusy = false;
  String? _errorMessage;

  @override
  void dispose() {
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
    final sourcePath = _selectedJsonSourcePath?.trim();
    if (sourcePath == null || sourcePath.isEmpty) {
      setState(() {
        _errorMessage = 'Sélectionnez un fichier JSON à importer.';
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final preview = await widget.previewImport(
        widget.workspace,
        sourcePath,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _preview = preview;
        _step = _PokedexImportWizardStep.preview;
        _isBusy = false;
      });
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
    final sourcePath = _selectedJsonSourcePath?.trim();
    if (sourcePath == null || sourcePath.isEmpty) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.importPokemon(
        widget.workspace,
        sourcePath,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(result);
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

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      _PokedexImportWizardStep.source => _PokedexImportSourceStep(
          onContinue: () {
            setState(() {
              _step = _PokedexImportWizardStep.jsonFile;
              _errorMessage = null;
            });
          },
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
      _PokedexImportWizardStep.preview => _PokedexImportPreviewStep(
          preview: _preview!,
          isBusy: _isBusy,
          errorMessage: _errorMessage,
          onBack: () {
            setState(() {
              _step = _PokedexImportWizardStep.jsonFile;
              _errorMessage = null;
            });
          },
          onImport: _confirmImport,
        ),
    };
  }
}
