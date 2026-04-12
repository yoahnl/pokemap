import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart'
    show
        ControlSize,
        MacosIcon,
        MacosPopupButton,
        MacosPopupMenuItem,
        ProgressCircle,
        PushButton;
import 'package:map_editor/src/ui/canvas/pokedex_workspace_loader.dart';
import 'package:path/path.dart' as p;

import '../../application/errors/application_errors.dart';
import '../../application/models/pokedex_species_detail.dart';
import '../../application/models/pokemon_database_index.dart';
import '../../application/models/pokemon_project_data_models.dart';
import '../../application/ports/project_workspace.dart';
import '../../application/use_cases/import_pokemon_json_bundle_use_case.dart';
import '../../application/use_cases/update_pokedex_species_evolution_use_case.dart';
import '../../application/use_cases/update_pokedex_species_forms_classification_use_case.dart';
import '../../application/use_cases/update_pokedex_species_learnset_use_case.dart';
import '../../application/use_cases/update_pokedex_species_media_use_case.dart';
import '../../application/use_cases/update_pokedex_species_metadata_use_case.dart';
import '../shared/cupertino_editor_widgets.dart';

/// Vue de chargement minimale du lot 13.
///
/// On garde un état très simple et honnête :
/// - pas d'overlay complexe ;
/// - pas de skeleton list ;
/// - pas de faux comportement "riche" qui préparerait en douce les lots
///   suivants.
class PokedexWorkspaceLoadingState extends StatelessWidget {
  const PokedexWorkspaceLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return DefaultTextStyle(
      style: TextStyle(
        color: subtle,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      child: const PokedexWorkspaceStateFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: ProgressCircle(),
            ),
            SizedBox(height: 14),
            Text(
              'Chargement de la liste Pokédex…',
              key: Key('pokedex-loading-label'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte d'erreur minimale du lot 13.
///
/// L'objectif n'est pas d'ajouter une UX de récupération riche ; on rend
/// simplement l'erreur lisible, sans masquer qu'un chargement a échoué.
class PokedexWorkspaceErrorState extends StatelessWidget {
  const PokedexWorkspaceErrorState({
    super.key,
    required this.error,
  });

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final message = switch (error) {
      final EditorApplicationException applicationError =>
        applicationError.message,
      _ => error?.toString() ?? 'Erreur inconnue',
    };

    return PokedexWorkspaceStateCard(
      key: const Key('pokedex-error-state'),
      title: 'Pokédex',
      accent: EditorChrome.inspectorJoyCoral,
      titleStyle: TextStyle(
        color: label,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      message: 'Impossible de charger la liste locale des espèces.\n$message',
      messageStyle: TextStyle(
        color: subtle,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.45,
      ),
    );
  }
}

/// Etat dédié des lots 14/15 quand les critères locaux ne matchent aucune entrée.
///
/// Il doit rester distinct de l'état "aucune espèce importée" :
/// - ici, la base locale contient des espèces ;
/// - ce sont uniquement les critères courants (recherche et/ou filtres) qui
///   n'ont trouvé aucun match.
/// On garde donc un message sobre, non anxiogène, et différent d'une erreur.
class PokedexWorkspaceNoResultsState extends StatelessWidget {
  const PokedexWorkspaceNoResultsState({
    super.key,
    required this.query,
    this.selectedType,
    this.selectedGeneration,
    this.selectedStatus,
  });

  final String query;
  final String? selectedType;
  final String? selectedGeneration;
  final String? selectedStatus;

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim();
    final normalizedStatus = switch (selectedStatus) {
      _PokedexFilterDropdown.enabledOnlyValue => 'Activées',
      _PokedexFilterDropdown.disabledOnlyValue => 'Désactivées',
      _ => selectedStatus,
    };
    final activeCriteriaLines = <String>[
      if (normalizedQuery.isNotEmpty)
        'Recherche actuelle : "$normalizedQuery".',
      if (selectedType != null) 'Type : $selectedType.',
      if (selectedGeneration != null) 'Génération : $selectedGeneration.',
      if (normalizedStatus != null) 'Statut : $normalizedStatus.',
    ];
    final suffix = activeCriteriaLines.isEmpty
        ? ''
        : '\n${activeCriteriaLines.join('\n')}';

    return PokedexWorkspaceStateCard(
      key: const Key('pokedex-no-results-state'),
      title: 'Pokédex',
      message: 'Aucun résultat avec les critères actuels.$suffix',
    );
  }
}

/// Vue succès du lot 13.
///
/// Elle reste volontairement en lecture seule, mais la phase 5 ajoute une
/// vraie sélection locale de ligne pour ouvrir la fiche détail.
class PokedexWorkspaceSpeciesList extends StatelessWidget {
  const PokedexWorkspaceSpeciesList({
    super.key,
    required this.entries,
    required this.selectedSpeciesId,
    required this.onEntrySelected,
    required this.onImportRequested,
    required this.query,
    required this.onQueryChanged,
    required this.filtersExpanded,
    required this.onToggleFiltersExpanded,
    required this.availableTypes,
    required this.selectedType,
    required this.onTypeChanged,
    required this.availableGenerations,
    required this.selectedGeneration,
    required this.onGenerationChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
    this.feedbackMessage,
    this.feedbackIsError = false,
    this.emptyStateChild,
    this.emptyResultsChild,
  });

  final List<PokemonDatabaseIndexEntry> entries;
  final String? selectedSpeciesId;
  final ValueChanged<PokemonDatabaseIndexEntry> onEntrySelected;
  final VoidCallback onImportRequested;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final bool filtersExpanded;
  final VoidCallback onToggleFiltersExpanded;
  final List<String> availableTypes;
  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final List<String> availableGenerations;
  final String selectedGeneration;
  final ValueChanged<String> onGenerationChanged;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;
  final String? feedbackMessage;
  final bool feedbackIsError;
  final Widget? emptyStateChild;
  final Widget? emptyResultsChild;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 2, 6, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: EditorChrome.accentJade.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: EditorChrome.accentJade.withValues(alpha: 0.55),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      CupertinoIcons.square_stack_3d_down_right_fill,
                      size: 18,
                      color: EditorChrome.accentJade,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pokédex',
                          style: TextStyle(
                            color: label,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Simple species list from local project data: number, name, ID, types.',
                          style: TextStyle(
                            color: subtle,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  CupertinoButton(
                    key: const Key('pokedex-import-button'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    color: EditorChrome.accentJade.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(14),
                    onPressed: onImportRequested,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.add,
                          size: 16,
                          color: CupertinoColors.white,
                        ),
                        SizedBox(width: 8),
                        Text('Importer des Pokémon'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (feedbackMessage != null) ...[
                const SizedBox(height: 12),
                PokedexWorkspaceFeedbackBanner(
                  message: feedbackMessage!,
                  isError: feedbackIsError,
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _PokedexSearchField(
                      query: query,
                      onChanged: onQueryChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  CupertinoButton(
                    key: const Key('pokedex-toggle-filters-button'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    color: EditorChrome.islandFillElevated(context),
                    borderRadius: BorderRadius.circular(14),
                    onPressed: onToggleFiltersExpanded,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.slider_horizontal_3,
                          size: 16,
                          color: CupertinoColors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(filtersExpanded ? 'Masquer' : 'Filtres'),
                      ],
                    ),
                  ),
                ],
              ),
              if (filtersExpanded) ...[
                const SizedBox(height: 12),
                _PokedexSimpleFiltersBar(
                  availableTypes: availableTypes,
                  selectedType: selectedType,
                  onTypeChanged: onTypeChanged,
                  availableGenerations: availableGenerations,
                  selectedGeneration: selectedGeneration,
                  onGenerationChanged: onGenerationChanged,
                  selectedStatus: selectedStatus,
                  onStatusChanged: onStatusChanged,
                ),
              ] else if (_hasAnyFilterApplied()) ...[
                const SizedBox(height: 10),
                Text(
                  _activeFiltersSummary(),
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (entries.isNotEmpty) ...[
          const _PokedexListHeader(),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: emptyStateChild != null
              ? SingleChildScrollView(child: emptyStateChild)
              : emptyResultsChild != null
                  ? SingleChildScrollView(child: emptyResultsChild)
                  : ListView.separated(
                      key: const Key('pokedex-species-list'),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return _PokedexListRow(
                          entry: entry,
                          isSelected: selectedSpeciesId == entry.id,
                          onPressed: () => onEntrySelected(entry),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  bool _hasAnyFilterApplied() {
    return selectedType != _PokedexFilterDropdown.allTypesValue ||
        selectedGeneration != _PokedexFilterDropdown.allGenerationsValue ||
        selectedStatus != _PokedexFilterDropdown.allStatusesValue;
  }

  String _activeFiltersSummary() {
    final parts = <String>[];
    if (selectedType != _PokedexFilterDropdown.allTypesValue) {
      parts.add('Type : $selectedType');
    }
    if (selectedGeneration != _PokedexFilterDropdown.allGenerationsValue) {
      parts.add('Génération : $selectedGeneration');
    }
    if (selectedStatus == _PokedexFilterDropdown.enabledOnlyValue) {
      parts.add('Activées');
    } else if (selectedStatus == _PokedexFilterDropdown.disabledOnlyValue) {
      parts.add('Désactivées');
    }
    return parts.join(' · ');
  }
}

class PokedexWorkspaceFeedbackBanner extends StatelessWidget {
  const PokedexWorkspaceFeedbackBanner({
    super.key,
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final accent =
        isError ? EditorChrome.inspectorJoyCoral : EditorChrome.accentJade;
    final label = EditorChrome.primaryLabel(context);

    return Container(
      key: const Key('pokedex-feedback-banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? CupertinoIcons.exclamationmark_triangle_fill
                : CupertinoIcons.check_mark_circled_solid,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: label,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PokedexWorkspaceImportEmptyState extends StatelessWidget {
  const PokedexWorkspaceImportEmptyState({
    super.key,
    required this.onImportRequested,
  });

  final VoidCallback onImportRequested;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: EditorChrome.accentWarm.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
            child: Column(
              key: const Key('pokedex-empty-state'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: EditorChrome.accentPrune.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    CupertinoIcons.folder,
                    size: 34,
                    color: EditorChrome.accentLilac,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Importer des Pokémon',
                  style: TextStyle(
                    color: label,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Aucune espèce importée pour le moment. Utilisez le bouton "Importer" pour charger des espèces locales dans le Pokédex du projet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                CupertinoButton(
                  key: const Key('pokedex-empty-state-import-button'),
                  color: EditorChrome.accentJade.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(16),
                  onPressed: onImportRequested,
                  child: const Text('Importer des Pokémon'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
  return result?.files.single.path;
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

class _PokedexImportSourceStep extends StatelessWidget {
  const _PokedexImportSourceStep({
    required this.onContinue,
    required this.onCancel,
  });

  final VoidCallback onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('pokedex-import-source-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Importer des Pokémon',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 20),
        Text(
          'Choisir une source :',
          style: editorMacosFormLabelStyle(context),
        ),
        const SizedBox(height: 12),
        const _PokedexImportSourceCard(
          cardKey: Key('pokedex-import-json-source-card'),
          title: 'Fichier JSON',
          icon: CupertinoIcons.doc_text_fill,
          isSelected: true,
        ),
        const SizedBox(height: 10),
        const _PokedexImportSourceCard(
          cardKey: Key('pokedex-import-pokeapi-source-card'),
          title: 'PokéAPI',
          icon: CupertinoIcons.cloud_fill,
          isEnabled: false,
          trailingLabel: 'Bientôt',
        ),
        const SizedBox(height: 10),
        const _PokedexImportSourceCard(
          cardKey: Key('pokedex-import-showdown-source-card'),
          title: 'Showdown',
          icon: CupertinoIcons.refresh_circled_solid,
          isEnabled: false,
          trailingLabel: 'Bientôt',
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: onCancel,
              child: const Text('Annuler'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key('pokedex-import-source-continue-button'),
              controlSize: ControlSize.large,
              onPressed: onContinue,
              child: const Text('Continuer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexImportJsonFileStep extends StatelessWidget {
  const _PokedexImportJsonFileStep({
    required this.selectedJsonSourcePath,
    required this.isBusy,
    required this.errorMessage,
    required this.onPickJsonSource,
    required this.onContinue,
    required this.onCancel,
  });

  final String? selectedJsonSourcePath;
  final bool isBusy;
  final String? errorMessage;
  final Future<void> Function() onPickJsonSource;
  final Future<void> Function() onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final hasFile = selectedJsonSourcePath?.trim().isNotEmpty == true;

    return Column(
      key: const Key('pokedex-import-json-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Import depuis fichier JSON',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 20),
        Text(
          'Choisir une source :',
          style: editorMacosFormLabelStyle(context),
        ),
        const SizedBox(height: 12),
        CupertinoButton(
          key: const Key('pokedex-import-pick-json-file-button'),
          color: EditorChrome.accentJade.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          onPressed: isBusy ? null : onPickJsonSource,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.folder_open, size: 18),
              SizedBox(width: 8),
              Text('Choisir un fichier'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          key: const Key('pokedex-import-selected-file'),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: EditorChrome.accentWarm.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Text(
            hasFile
                ? p.basename(selectedJsonSourcePath!)
                : 'Aucun fichier sélectionné',
            style: TextStyle(
              color: hasFile ? CupertinoColors.white : subtle,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const Key('pokedex-import-error-message'),
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: isBusy ? null : onCancel,
              child: const Text('Annuler'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key('pokedex-import-json-continue-button'),
              controlSize: ControlSize.large,
              onPressed: isBusy ? null : onContinue,
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressCircle(),
                    )
                  : const Text('Continuer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexImportPreviewStep extends StatelessWidget {
  const _PokedexImportPreviewStep({
    required this.preview,
    required this.isBusy,
    required this.errorMessage,
    required this.onBack,
    required this.onImport,
  });

  final PokemonJsonImportPreview preview;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onBack;
  final Future<void> Function() onImport;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('pokedex-import-preview-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Aperçu de l\'import',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: EditorChrome.accentWarm.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${preview.nationalDex.toString().padLeft(3, '0')} ${preview.primaryName}',
                  key: const Key('pokedex-import-preview-title'),
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Type : ${preview.types.join(' / ')}',
                  key: const Key('pokedex-import-preview-types'),
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                _PokedexImportArtifactLine(
                  key: const Key('pokedex-import-preview-learnset-status'),
                  preview: preview.learnset,
                ),
                const SizedBox(height: 10),
                _PokedexImportArtifactLine(
                  key: const Key('pokedex-import-preview-evolution-status'),
                  preview: preview.evolution,
                ),
                const SizedBox(height: 10),
                _PokedexImportArtifactLine(
                  key: const Key('pokedex-import-preview-media-status'),
                  preview: preview.media,
                ),
              ],
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const Key('pokedex-import-error-message'),
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              key: const Key('pokedex-import-preview-back-button'),
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: isBusy ? null : onBack,
              child: const Text('Retour'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key('pokedex-import-confirm-button'),
              controlSize: ControlSize.large,
              onPressed: isBusy ? null : onImport,
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressCircle(),
                    )
                  : const Text('Importer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexImportSourceCard extends StatelessWidget {
  const _PokedexImportSourceCard({
    required this.cardKey,
    required this.title,
    required this.icon,
    this.isSelected = false,
    this.isEnabled = true,
    this.trailingLabel,
  });

  final Key cardKey;
  final String title;
  final IconData icon;
  final bool isSelected;
  final bool isEnabled;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final accent = isSelected
        ? EditorChrome.accentJade
        : EditorChrome.accentWarm.withValues(alpha: 0.45);
    final text = isEnabled
        ? EditorChrome.primaryLabel(context)
        : EditorChrome.subtleLabel(context);

    return DecoratedBox(
      key: cardKey,
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent, width: isSelected ? 1.2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 18, color: text),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (trailingLabel != null)
              Text(
                trailingLabel!,
                style: TextStyle(
                  color: EditorChrome.subtleLabel(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PokedexImportArtifactLine extends StatelessWidget {
  const _PokedexImportArtifactLine({
    super.key,
    required this.preview,
  });

  final PokemonImportArtifactPreview preview;

  @override
  Widget build(BuildContext context) {
    final isFound = preview.isFound;
    final accent = isFound ? EditorChrome.accentJade : EditorChrome.accentWarm;
    final text = EditorChrome.primaryLabel(context);

    return Row(
      children: [
        Icon(
          isFound
              ? CupertinoIcons.check_mark_circled_solid
              : CupertinoIcons.exclamationmark_triangle_fill,
          size: 18,
          color: accent,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${preview.label} ${isFound ? 'trouvé${preview.label == 'Évolutions' ? 'es' : ''}' : 'manquants'}',
            style: TextStyle(
              color: text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PokedexSimpleFiltersBar extends StatelessWidget {
  const _PokedexSimpleFiltersBar({
    required this.availableTypes,
    required this.selectedType,
    required this.onTypeChanged,
    required this.availableGenerations,
    required this.selectedGeneration,
    required this.onGenerationChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  final List<String> availableTypes;
  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final List<String> availableGenerations;
  final String selectedGeneration;
  final ValueChanged<String> onGenerationChanged;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const Key('pokedex-filters-panel'),
      spacing: 12,
      runSpacing: 12,
      children: [
        _PokedexFilterDropdown(
          label: 'Type',
          popupKey: const Key('pokedex-type-filter'),
          value: selectedType,
          onChanged: onTypeChanged,
          items: <String>[
            _PokedexFilterDropdown.allTypesValue,
            ...availableTypes,
          ],
          itemLabelBuilder: (value) {
            if (value == _PokedexFilterDropdown.allTypesValue) {
              return 'Tous types';
            }
            return value;
          },
        ),
        _PokedexFilterDropdown(
          label: 'Génération',
          popupKey: const Key('pokedex-generation-filter'),
          value: selectedGeneration,
          onChanged: onGenerationChanged,
          items: <String>[
            _PokedexFilterDropdown.allGenerationsValue,
            ...availableGenerations,
          ],
          itemLabelBuilder: (value) {
            if (value == _PokedexFilterDropdown.allGenerationsValue) {
              return 'Toutes gén.';
            }
            return 'Génération $value';
          },
        ),
        _PokedexFilterDropdown(
          label: 'Statut',
          popupKey: const Key('pokedex-status-filter'),
          value: selectedStatus,
          onChanged: onStatusChanged,
          items: const <String>[
            _PokedexFilterDropdown.allStatusesValue,
            _PokedexFilterDropdown.enabledOnlyValue,
            _PokedexFilterDropdown.disabledOnlyValue,
          ],
          itemLabelBuilder: (value) {
            switch (value) {
              case _PokedexFilterDropdown.allStatusesValue:
                return 'Toutes';
              case _PokedexFilterDropdown.enabledOnlyValue:
                return 'Activées';
              case _PokedexFilterDropdown.disabledOnlyValue:
                return 'Désactivées';
            }
            return value;
          },
        ),
      ],
    );
  }
}

class _PokedexSearchField extends StatefulWidget {
  const _PokedexSearchField({
    required this.query,
    required this.onChanged,
  });

  final String query;
  final ValueChanged<String> onChanged;

  @override
  State<_PokedexSearchField> createState() => _PokedexSearchFieldState();
}

class _PokedexSearchFieldState extends State<_PokedexSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _PokedexSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentWarm.withValues(alpha: 0.28);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.search,
              color: subtle,
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CupertinoTextField.borderless(
                key: const Key('pokedex-search-field'),
                controller: _controller,
                onChanged: widget.onChanged,
                clearButtonMode: OverlayVisibilityMode.editing,
                placeholder: 'Rechercher par nom, id ou numéro dex',
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PokedexFilterDropdown extends StatelessWidget {
  const _PokedexFilterDropdown({
    required this.label,
    required this.popupKey,
    required this.value,
    required this.onChanged,
    required this.items,
    required this.itemLabelBuilder,
  });

  static const String allTypesValue = '__all_types__';
  static const String allGenerationsValue = '__all_generations__';
  static const String allStatusesValue = '__all_statuses__';
  static const String enabledOnlyValue = '__enabled_only__';
  static const String disabledOnlyValue = '__disabled_only__';

  final String label;
  final Key popupKey;
  final String value;
  final ValueChanged<String> onChanged;
  final List<String> items;
  final String Function(String value) itemLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentWarm.withValues(alpha: 0.28);

    return SizedBox(
      // `MacosPopupButton` réserve de la place pour le libellé et l'icône
      // interne. On donne donc une largeur volontairement confortable pour
      // éviter les overflows de layout, notamment avec les libellés français
      // "Toutes les générations" / "Tous les types".
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          DecoratedBox(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: SizedBox(
                width: double.infinity,
                child: MacosPopupButton<String>(
                  key: popupKey,
                  value: value,
                  onChanged: (nextValue) {
                    if (nextValue != null) {
                      onChanged(nextValue);
                    }
                  },
                  items: [
                    for (final item in items)
                      MacosPopupMenuItem<String>(
                        value: item,
                        child: Text(itemLabelBuilder(item)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PokedexListHeader extends StatelessWidget {
  const _PokedexListHeader();

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              'Numéro',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              'Nom',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              'ID',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              'Types',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 92,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Statut',
                style: _headerStyle(subtle),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle(Color color) {
    return TextStyle(
      color: color,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.25,
    );
  }
}

class _PokedexListRow extends StatelessWidget {
  const _PokedexListRow({
    required this.entry,
    required this.isSelected,
    required this.onPressed,
  });

  final PokemonDatabaseIndexEntry entry;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final surface = isSelected
        ? Color.lerp(
            EditorChrome.islandFillElevated(context),
            EditorChrome.accentJade,
            0.12,
          )!
        : EditorChrome.islandFillElevated(context);
    final border = isSelected
        ? EditorChrome.accentJade.withValues(alpha: 0.65)
        : EditorChrome.accentWarm.withValues(alpha: 0.35);
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return CupertinoButton(
      key: Key('pokedex-row-${entry.id}'),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: isSelected ? 1.4 : 1),
          boxShadow: EditorChrome.sectionCardShadows(context),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 88,
                child: Text(
                  '#${entry.nationalDex.toString().padLeft(4, '0')}',
                  style: TextStyle(
                    color: label,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Text(
                  entry.primaryName,
                  style: TextStyle(
                    color: label,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  entry.id,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entry.types
                      .map((type) => _PokedexTypeChip(label: type))
                      .toList(growable: false),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 92,
                child: Align(
                  alignment: Alignment.topRight,
                  child: _PokedexStatusChip(
                    label: entry.isEnabledInProject ? 'Activé' : 'Désactivé',
                    isEnabled: entry.isEnabledInProject,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PokedexTypeChip extends StatelessWidget {
  const _PokedexTypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final text = EditorChrome.primaryLabel(context);
    final fill = Color.lerp(
      EditorChrome.chipFill(context),
      EditorChrome.accentJade,
      0.18,
    )!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: EditorChrome.accentJade.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: text,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PokedexStatusChip extends StatelessWidget {
  const _PokedexStatusChip({
    required this.label,
    required this.isEnabled,
  });

  final String label;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final accent =
        isEnabled ? EditorChrome.accentJade : EditorChrome.inspectorJoyCoral;
    final text = EditorChrome.primaryLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: text,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class PokedexWorkspaceDetailPane extends StatelessWidget {
  const PokedexWorkspaceDetailPane({
    super.key,
    required this.selectedEntry,
    required this.selectedTabId,
    required this.onTabChanged,
    required this.detailFuture,
    required this.onSaveMetadata,
    required this.onSaveFormsClassification,
    required this.onSaveLearnset,
    required this.onSaveEvolution,
    required this.onSaveMedia,
  });

  final PokemonDatabaseIndexEntry? selectedEntry;
  final String selectedTabId;
  final ValueChanged<String> onTabChanged;
  final Future<PokedexSpeciesDetail>? detailFuture;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSaveMetadata;
  final Future<void> Function(
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) onSaveFormsClassification;
  final Future<void> Function(UpdatePokedexSpeciesLearnsetRequest request)
      onSaveLearnset;
  final Future<void> Function(UpdatePokedexSpeciesEvolutionRequest request)
      onSaveEvolution;
  final Future<void> Function(UpdatePokedexSpeciesMediaRequest request)
      onSaveMedia;

  @override
  Widget build(BuildContext context) {
    final entry = selectedEntry;
    if (entry == null || detailFuture == null) {
      return const PokedexWorkspaceStateCard(
        key: Key('pokedex-detail-empty-state'),
        title: 'Fiche espèce',
        message:
            'Sélectionnez une espèce dans la liste pour afficher son overview, ses formes, son learnset, ses évolutions et ses médias.',
      );
    }

    return FutureBuilder<PokedexSpeciesDetail>(
      future: detailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PokedexWorkspaceStateCard(
            key: Key('pokedex-detail-loading-state'),
            title: 'Fiche espèce',
            message: 'Chargement de la fiche Pokédex locale…',
          );
        }

        if (snapshot.hasError) {
          final message = switch (snapshot.error) {
            final EditorApplicationException applicationError =>
              applicationError.message,
            _ => snapshot.error?.toString() ?? 'Erreur inconnue',
          };
          return PokedexWorkspaceStateCard(
            key: const Key('pokedex-detail-error-state'),
            title: 'Fiche espèce',
            accent: EditorChrome.inspectorJoyCoral,
            message: 'Impossible de charger la fiche de ${entry.id}.\n$message',
          );
        }

        final detail = snapshot.data;
        if (detail == null) {
          return const PokedexWorkspaceStateCard(
            title: 'Fiche espèce',
            message: 'Aucune donnée Pokédex détaillée disponible.',
          );
        }

        return _PokedexSpeciesDetailView(
          entry: entry,
          detail: detail,
          selectedTabId: selectedTabId,
          onTabChanged: onTabChanged,
          onSaveMetadata: onSaveMetadata,
          onSaveFormsClassification: onSaveFormsClassification,
          onSaveLearnset: onSaveLearnset,
          onSaveEvolution: onSaveEvolution,
          onSaveMedia: onSaveMedia,
        );
      },
    );
  }
}

class _PokedexSpeciesDetailView extends StatelessWidget {
  const _PokedexSpeciesDetailView({
    required this.entry,
    required this.detail,
    required this.selectedTabId,
    required this.onTabChanged,
    required this.onSaveMetadata,
    required this.onSaveFormsClassification,
    required this.onSaveLearnset,
    required this.onSaveEvolution,
    required this.onSaveMedia,
  });

  final PokemonDatabaseIndexEntry entry;
  final PokedexSpeciesDetail detail;
  final String selectedTabId;
  final ValueChanged<String> onTabChanged;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSaveMetadata;
  final Future<void> Function(
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) onSaveFormsClassification;
  final Future<void> Function(UpdatePokedexSpeciesLearnsetRequest request)
      onSaveLearnset;
  final Future<void> Function(UpdatePokedexSpeciesEvolutionRequest request)
      onSaveEvolution;
  final Future<void> Function(UpdatePokedexSpeciesMediaRequest request)
      onSaveMedia;

  @override
  Widget build(BuildContext context) {
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentWarm.withValues(alpha: 0.35);
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      key: const Key('pokedex-detail-pane'),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              entry.primaryName,
              style: TextStyle(
                color: label,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '#${entry.nationalDex.toString().padLeft(4, '0')} • ${entry.id}',
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: entry.types
                  .map((type) => _PokedexTypeChip(label: type))
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
            CupertinoSlidingSegmentedControl<String>(
              key: const Key('pokedex-detail-tabs'),
              groupValue: selectedTabId,
              onValueChanged: (value) {
                if (value != null) {
                  onTabChanged(value);
                }
              },
              children: const <String, Widget>{
                'overview': Padding(
                  key: Key('pokedex-tab-overview'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Overview'),
                ),
                'forms': Padding(
                  key: Key('pokedex-tab-forms'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Formes'),
                ),
                'learnset': Padding(
                  key: Key('pokedex-tab-learnset'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Learnset'),
                ),
                'evolutions': Padding(
                  key: Key('pokedex-tab-evolutions'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Évolutions'),
                ),
                'media': Padding(
                  key: Key('pokedex-tab-media'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Médias'),
                ),
              },
            ),
            const SizedBox(height: 18),
            Expanded(
              child: _PokedexDetailTabBody(
                entry: entry,
                detail: detail,
                selectedTabId: selectedTabId,
                onSaveMetadata: onSaveMetadata,
                onSaveFormsClassification: onSaveFormsClassification,
                onSaveLearnset: onSaveLearnset,
                onSaveEvolution: onSaveEvolution,
                onSaveMedia: onSaveMedia,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PokedexDetailTabBody extends StatelessWidget {
  const _PokedexDetailTabBody({
    required this.entry,
    required this.detail,
    required this.selectedTabId,
    required this.onSaveMetadata,
    required this.onSaveFormsClassification,
    required this.onSaveLearnset,
    required this.onSaveEvolution,
    required this.onSaveMedia,
  });

  final PokemonDatabaseIndexEntry entry;
  final PokedexSpeciesDetail detail;
  final String selectedTabId;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSaveMetadata;
  final Future<void> Function(
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) onSaveFormsClassification;
  final Future<void> Function(UpdatePokedexSpeciesLearnsetRequest request)
      onSaveLearnset;
  final Future<void> Function(UpdatePokedexSpeciesEvolutionRequest request)
      onSaveEvolution;
  final Future<void> Function(UpdatePokedexSpeciesMediaRequest request)
      onSaveMedia;

  @override
  Widget build(BuildContext context) {
    return switch (selectedTabId) {
      'forms' => _PokedexFormsTab(
          detail: detail,
          onSave: onSaveFormsClassification,
        ),
      'learnset' => _PokedexLearnsetTab(
          detail: detail,
          onSave: onSaveLearnset,
        ),
      'evolutions' => _PokedexEvolutionTab(
          detail: detail,
          onSave: onSaveEvolution,
        ),
      'media' => _PokedexMediaTab(
          detail: detail,
          onSave: onSaveMedia,
        ),
      _ => _PokedexOverviewTab(
          entry: entry,
          detail: detail,
          onSaveMetadata: onSaveMetadata,
        ),
    };
  }
}

class _PokedexOverviewTab extends StatelessWidget {
  const _PokedexOverviewTab({
    required this.entry,
    required this.detail,
    required this.onSaveMetadata,
  });

  final PokemonDatabaseIndexEntry entry;
  final PokedexSpeciesDetail detail;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSaveMetadata;

  @override
  Widget build(BuildContext context) {
    final species = detail.species;

    return SingleChildScrollView(
      key: const Key('pokedex-overview-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PokedexDetailSectionCard(
            title: 'Identité',
            child: Column(
              children: [
                _PokedexPropertyLine(
                  label: 'Nom principal',
                  value: entry.primaryName,
                ),
                _PokedexPropertyLine(label: 'ID', value: species.id),
                _PokedexPropertyLine(
                  label: 'Numéro national',
                  value: species.nationalDex.toString(),
                ),
                _PokedexPropertyLine(
                  label: 'Nom espèce',
                  value: _localizedValue(species.speciesName),
                ),
                _PokedexPropertyLine(
                  label: 'Génération',
                  value: species.genIntroduced.toString(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexEditableMetadataSection(
            species: species,
            onSave: onSaveMetadata,
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Stats',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatChip(label: 'HP', value: species.baseStats.hp),
                _StatChip(label: 'ATK', value: species.baseStats.atk),
                _StatChip(label: 'DEF', value: species.baseStats.def),
                _StatChip(label: 'SPA', value: species.baseStats.spa),
                _StatChip(label: 'SPD', value: species.baseStats.spd),
                _StatChip(label: 'SPE', value: species.baseStats.spe),
                _StatChip(label: 'BST', value: species.baseStats.bst),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Talents',
            child: Column(
              children: [
                _PokedexPropertyLine(
                  label: 'Talent principal',
                  value: species.abilities.primary,
                ),
                _PokedexPropertyLine(
                  label: 'Talent secondaire',
                  value: species.abilities.secondary ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'Talent caché',
                  value: species.abilities.hidden ?? 'Aucun',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Références locales',
            child: Column(
              children: [
                _PokedexPropertyLine(
                  label: 'Learnset',
                  value: species.refs.learnset,
                ),
                _PokedexPropertyLine(
                  label: 'Évolution',
                  value: species.refs.evolution,
                ),
                _PokedexPropertyLine(
                  label: 'Média',
                  value: species.refs.media,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PokedexEditableMetadataSection extends StatefulWidget {
  const _PokedexEditableMetadataSection({
    required this.species,
    required this.onSave,
  });

  final PokemonSpeciesFile species;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSave;

  @override
  State<_PokedexEditableMetadataSection> createState() =>
      _PokedexEditableMetadataSectionState();
}

class _PokedexEditableMetadataSectionState
    extends State<_PokedexEditableMetadataSection> {
  final Map<String, TextEditingController> _nameControllers =
      <String, TextEditingController>{};
  final List<TextEditingController> _typeControllers =
      <TextEditingController>[];
  late TextEditingController _flavorTextController;
  late List<String> _orderedLocales;
  late bool _isEnabledInProject;
  late bool _starterEligible;
  late bool _giftOnly;
  late bool _tradeOnly;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _saveErrorMessage;

  @override
  void initState() {
    super.initState();
    _flavorTextController = TextEditingController();
    _replaceDraftFromSpecies(widget.species);
  }

  @override
  void didUpdateWidget(covariant _PokedexEditableMetadataSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.species != widget.species) {
      // Dès qu'une nouvelle espèce est relue depuis le workspace, on considère
      // qu'elle devient la nouvelle vérité locale :
      // - après sélection d'une autre ligne ;
      // - après sauvegarde réussie et rechargement ;
      // - après changement de filtres qui force une nouvelle fiche.
      //
      // On jette donc proprement tout draft local restant.
      _replaceDraftFromSpecies(widget.species);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    }
  }

  @override
  void dispose() {
    _disposeNameControllers();
    _disposeTypeControllers();
    _flavorTextController.dispose();
    super.dispose();
  }

  void _replaceDraftFromSpecies(PokemonSpeciesFile species) {
    _disposeNameControllers();
    _disposeTypeControllers();

    _orderedLocales = _orderedLocaleKeys(species.names);
    for (final locale in _orderedLocales) {
      _nameControllers[locale] = TextEditingController(
        text: species.names[locale] ?? '',
      );
    }
    final sourceTypes = species.typing.types.isEmpty
        ? const <String>['']
        : species.typing.types;
    for (final type in sourceTypes) {
      _typeControllers.add(TextEditingController(text: type));
    }

    _flavorTextController.value = TextEditingValue(
      text: species.dexContent.flavorText ?? '',
      selection: TextSelection.collapsed(
        offset: (species.dexContent.flavorText ?? '').length,
      ),
    );
    _isEnabledInProject = species.classification.isEnabledInProject;
    _starterEligible = species.gameplayFlags.starterEligible;
    _giftOnly = species.gameplayFlags.giftOnly;
    _tradeOnly = species.gameplayFlags.tradeOnly;
  }

  void _disposeNameControllers() {
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    _nameControllers.clear();
  }

  void _disposeTypeControllers() {
    for (final controller in _typeControllers) {
      controller.dispose();
    }
    _typeControllers.clear();
  }

  Future<void> _saveDraft() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _saveErrorMessage = null;
    });

    try {
      await widget.onSave(
        UpdatePokedexSpeciesMetadataRequest(
          speciesId: widget.species.id,
          isEnabledInProject: _isEnabledInProject,
          names: <String, String>{
            for (final locale in _orderedLocales)
              locale: _nameControllers[locale]?.text ?? '',
          },
          types: _typeControllers.map((controller) => controller.text).toList(),
          flavorText: _flavorTextController.text,
          starterEligible: _starterEligible,
          giftOnly: _giftOnly,
          tradeOnly: _tradeOnly,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isEditing = false;
        _isSaving = false;
        _saveErrorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = switch (error) {
        final EditorApplicationException applicationError =>
          applicationError.message,
        _ => error.toString(),
      };

      setState(() {
        _isSaving = false;
        _saveErrorMessage = message;
      });
    }
  }

  void _addTypeField() {
    setState(() {
      _typeControllers.add(TextEditingController());
    });
  }

  void _removeTypeField(int index) {
    if (_typeControllers.length <= 1) {
      return;
    }
    setState(() {
      final controller = _typeControllers.removeAt(index);
      controller.dispose();
    });
  }

  void _cancelEditing() {
    setState(() {
      _replaceDraftFromSpecies(widget.species);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final species = widget.species;

    return _PokedexDetailSectionCard(
      title: 'Métadonnées locales',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditing) ...[
            _PokedexBooleanEditorRow(
              key: const Key('pokedex-enabled-switch-row'),
              label: 'Activée dans le projet',
              description:
                  'Le filtre liste et le statut local utilisent ce booléen persistant.',
              value: _isEnabledInProject,
              switchKey: const Key('pokedex-enabled-switch'),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _isEnabledInProject = value),
            ),
            const SizedBox(height: 12),
            for (final locale in _orderedLocales) ...[
              _PokedexEditorTextField(
                label: 'Nom (${locale.toUpperCase()})',
                fieldKey: Key('pokedex-name-field-$locale'),
                controller: _nameControllers[locale]!,
                enabled: !_isSaving,
              ),
              const SizedBox(height: 10),
            ],
            _PokedexEditableTypeFields(
              controllers: _typeControllers,
              enabled: !_isSaving,
              onAddType: _isSaving ? null : _addTypeField,
              onRemoveType: _isSaving ? null : _removeTypeField,
            ),
            const SizedBox(height: 12),
            _PokedexEditorTextField(
              label: 'Texte Pokédex',
              fieldKey: const Key('pokedex-flavor-text-field'),
              controller: _flavorTextController,
              enabled: !_isSaving,
              minLines: 3,
              maxLines: 6,
              placeholder: 'Texte local affiché dans la fiche Pokédex',
            ),
            const SizedBox(height: 12),
            _PokedexBooleanEditorRow(
              key: const Key('pokedex-starter-eligible-switch-row'),
              label: 'Starter éligible',
              value: _starterEligible,
              switchKey: const Key('pokedex-starter-eligible-switch'),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _starterEligible = value),
            ),
            const SizedBox(height: 10),
            _PokedexBooleanEditorRow(
              key: const Key('pokedex-gift-only-switch-row'),
              label: 'Obtenu par cadeau',
              value: _giftOnly,
              switchKey: const Key('pokedex-gift-only-switch'),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _giftOnly = value),
            ),
            const SizedBox(height: 10),
            _PokedexBooleanEditorRow(
              key: const Key('pokedex-trade-only-switch-row'),
              label: 'Échange uniquement',
              value: _tradeOnly,
              switchKey: const Key('pokedex-trade-only-switch'),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _tradeOnly = value),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                CupertinoButton.filled(
                  key: const Key('pokedex-save-metadata-button'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  onPressed: _isSaving ? null : _saveDraft,
                  child: Text(_isSaving ? 'Enregistrement…' : 'Enregistrer'),
                ),
                const SizedBox(width: 10),
                CupertinoButton(
                  key: const Key('pokedex-cancel-metadata-button'),
                  onPressed: _isSaving ? null : _cancelEditing,
                  child: const Text('Annuler'),
                ),
              ],
            ),
            if (_saveErrorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _saveErrorMessage!,
                key: const Key('pokedex-metadata-save-error'),
                style: const TextStyle(
                  color: EditorChrome.inspectorJoyCoral,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ] else ...[
            _PokedexPropertyLine(
              label: 'Statut projet',
              value: species.classification.isEnabledInProject
                  ? 'Activée'
                  : 'Désactivée',
            ),
            for (final locale in _orderedLocaleKeys(species.names))
              _PokedexPropertyLine(
                label: 'Nom (${locale.toUpperCase()})',
                value: (species.names[locale]?.trim().isNotEmpty ?? false)
                    ? species.names[locale]!.trim()
                    : 'Valeur vide',
              ),
            _PokedexPropertyLine(
              label: 'Texte Pokédex',
              value: species.dexContent.flavorText?.trim().isNotEmpty == true
                  ? species.dexContent.flavorText!.trim()
                  : 'Aucun texte local',
            ),
            _PokedexPropertyLine(
              label: 'Types',
              value: species.typing.types.isEmpty
                  ? 'Aucun type'
                  : species.typing.types.join(', '),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FlagChip(
                  label: species.gameplayFlags.starterEligible
                      ? 'Starter éligible'
                      : 'Starter non éligible',
                ),
                _FlagChip(
                  label: species.gameplayFlags.giftOnly
                      ? 'Obtenu par cadeau'
                      : 'Pas cadeau uniquement',
                ),
                _FlagChip(
                  label: species.gameplayFlags.tradeOnly
                      ? 'Échange uniquement'
                      : 'Pas échange uniquement',
                ),
              ],
            ),
            const SizedBox(height: 14),
            CupertinoButton(
              key: const Key('pokedex-edit-metadata-button'),
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  _replaceDraftFromSpecies(widget.species);
                  _isEditing = true;
                  _saveErrorMessage = null;
                });
              },
              child: const Text('Modifier'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PokedexBooleanEditorRow extends StatelessWidget {
  const _PokedexBooleanEditorRow({
    super.key,
    required this.label,
    required this.value,
    required this.switchKey,
    required this.onChanged,
    this.description,
  });

  final String label;
  final bool value;
  final Key switchKey;
  final ValueChanged<bool>? onChanged;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final labelColor = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description!,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        CupertinoSwitch(
          key: switchKey,
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _PokedexEditorTextField extends StatelessWidget {
  const _PokedexEditorTextField({
    required this.label,
    required this.fieldKey,
    required this.controller,
    required this.enabled,
    this.minLines = 1,
    this.maxLines = 1,
    this.placeholder,
    this.description,
  });

  final String label;
  final Key fieldKey;
  final TextEditingController controller;
  final bool enabled;
  final int minLines;
  final int maxLines;
  final String? placeholder;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final labelColor = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentWarm.withValues(alpha: 0.28);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1),
          ),
          child: CupertinoTextField(
            key: fieldKey,
            controller: controller,
            enabled: enabled,
            minLines: minLines,
            maxLines: maxLines,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            placeholder: placeholder,
            placeholderStyle: TextStyle(
              color: subtle,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PokedexEditableTypeFields extends StatelessWidget {
  const _PokedexEditableTypeFields({
    required this.controllers,
    required this.enabled,
    required this.onAddType,
    required this.onRemoveType,
  });

  final List<TextEditingController> controllers;
  final bool enabled;
  final VoidCallback? onAddType;
  final void Function(int index)? onRemoveType;

  @override
  Widget build(BuildContext context) {
    final labelColor = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Types',
                style: TextStyle(
                  color: labelColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            CupertinoButton(
              key: const Key('pokedex-add-type-button'),
              padding: EdgeInsets.zero,
              onPressed: enabled ? onAddType : null,
              child: const Text('+ ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Le premier type reste le type principal affiché dans la liste. Les valeurs vides sont ignorées à la sauvegarde.',
          style: TextStyle(
            color: subtle,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < controllers.length; index++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _PokedexEditorTextField(
                  label: 'Type ${index + 1}',
                  fieldKey: Key('pokedex-type-field-$index'),
                  controller: controllers[index],
                  enabled: enabled,
                  placeholder: 'electric',
                ),
              ),
              const SizedBox(width: 10),
              CupertinoButton(
                key: Key('pokedex-remove-type-button-$index'),
                padding: const EdgeInsets.only(top: 28),
                onPressed: enabled && controllers.length > 1
                    ? () => onRemoveType?.call(index)
                    : null,
                child: const Text('Retirer'),
              ),
            ],
          ),
          if (index != controllers.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PokedexFormsTab extends StatefulWidget {
  const _PokedexFormsTab({
    required this.detail,
    required this.onSave,
  });

  final PokedexSpeciesDetail detail;
  final Future<void> Function(
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) onSave;

  @override
  State<_PokedexFormsTab> createState() => _PokedexFormsTabState();
}

class _PokedexFormsTabState extends State<_PokedexFormsTab> {
  late final TextEditingController _baseFormIdController;
  late final TextEditingController _formIdController;
  late final TextEditingController _formNameController;
  late final TextEditingController _otherFormsController;
  late bool _isBaseForm;
  late bool _isObtainable;
  late bool _isLegendary;
  late bool _isMythical;
  late bool _isBaby;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _saveErrorMessage;

  @override
  void initState() {
    super.initState();
    _baseFormIdController = TextEditingController();
    _formIdController = TextEditingController();
    _formNameController = TextEditingController();
    _otherFormsController = TextEditingController();
    _replaceDraftFromSpecies(widget.detail.species);
  }

  @override
  void didUpdateWidget(covariant _PokedexFormsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail != widget.detail) {
      _replaceDraftFromSpecies(widget.detail.species);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    }
  }

  @override
  void dispose() {
    _baseFormIdController.dispose();
    _formIdController.dispose();
    _formNameController.dispose();
    _otherFormsController.dispose();
    super.dispose();
  }

  void _replaceDraftFromSpecies(PokemonSpeciesFile species) {
    final forms = species.forms;
    final classification = species.classification;
    _baseFormIdController.text =
        forms.baseFormId.trim().isEmpty ? species.id : forms.baseFormId;
    _formIdController.text = forms.formId;
    _formNameController.text = forms.formName ?? '';
    _otherFormsController.text = forms.otherForms.join('\n');
    _isBaseForm = forms.isBaseForm;
    _isObtainable = classification.isObtainable;
    _isLegendary = classification.isLegendary;
    _isMythical = classification.isMythical;
    _isBaby = classification.isBaby;
  }

  Future<void> _saveDraft() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _saveErrorMessage = null;
    });

    try {
      await widget.onSave(
        UpdatePokedexSpeciesFormsClassificationRequest(
          speciesId: widget.detail.species.id,
          baseFormId: _isBaseForm
              ? widget.detail.species.id
              : _baseFormIdController.text,
          isBaseForm: _isBaseForm,
          formId: _formIdController.text,
          formName: _formNameController.text,
          otherForms: _splitNonEmptyLines(_otherFormsController.text),
          isObtainable: _isObtainable,
          isLegendary: _isLegendary,
          isMythical: _isMythical,
          isBaby: _isBaby,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isEditing = false;
        _isSaving = false;
        _saveErrorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = switch (error) {
        final EditorApplicationException applicationError =>
          applicationError.message,
        _ => error.toString(),
      };
      setState(() {
        _isSaving = false;
        _saveErrorMessage = message;
      });
    }
  }

  void _cancelEditing() {
    setState(() {
      _replaceDraftFromSpecies(widget.detail.species);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final species = widget.detail.species;
    final forms = species.forms;
    final classification = species.classification;
    final currentFormId = forms.formId.isEmpty ? 'base' : forms.formId;
    final baseFormId = forms.baseFormId.isEmpty ? species.id : forms.baseFormId;

    return SingleChildScrollView(
      key: const Key('pokedex-forms-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PokedexDetailSectionCard(
            title: 'Formes et classification',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isEditing) ...[
                  _PokedexBooleanEditorRow(
                    key: const Key('pokedex-is-base-form-switch-row'),
                    label: 'Forme de base',
                    description:
                        'Quand ce flag est actif, la baseFormId suit automatiquement l’id de l’espèce.',
                    value: _isBaseForm,
                    switchKey: const Key('pokedex-is-base-form-switch'),
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _isBaseForm = value),
                  ),
                  const SizedBox(height: 12),
                  _PokedexEditorTextField(
                    label: 'Form ID',
                    description:
                        'Identifiant local simple de la forme courante.',
                    fieldKey: const Key('pokedex-form-id-field'),
                    controller: _formIdController,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Base form ID',
                    description:
                        'Référence locale de la forme de base. Verrouillée si cette espèce est la base.',
                    fieldKey: const Key('pokedex-base-form-id-field'),
                    controller: _baseFormIdController,
                    enabled: !_isSaving && !_isBaseForm,
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Nom de forme',
                    description:
                        'Valeur optionnelle affichée dans la fiche locale.',
                    fieldKey: const Key('pokedex-form-name-field'),
                    controller: _formNameController,
                    enabled: !_isSaving,
                    placeholder: 'Ex. Méga, Alola, Hisui…',
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Autres formes',
                    description:
                        'Une forme par ligne. Les valeurs vides, doublons et auto-références sont ignorés.',
                    fieldKey: const Key('pokedex-other-forms-field'),
                    controller: _otherFormsController,
                    enabled: !_isSaving,
                    minLines: 3,
                    maxLines: 6,
                    placeholder: 'mega\nalola\nhisui',
                  ),
                  const SizedBox(height: 12),
                  _PokedexBooleanEditorRow(
                    key: const Key('pokedex-is-obtainable-switch-row'),
                    label: 'Obtenable',
                    value: _isObtainable,
                    switchKey: const Key('pokedex-is-obtainable-switch'),
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _isObtainable = value),
                  ),
                  const SizedBox(height: 10),
                  _PokedexBooleanEditorRow(
                    key: const Key('pokedex-is-legendary-switch-row'),
                    label: 'Légendaire',
                    value: _isLegendary,
                    switchKey: const Key('pokedex-is-legendary-switch'),
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _isLegendary = value),
                  ),
                  const SizedBox(height: 10),
                  _PokedexBooleanEditorRow(
                    key: const Key('pokedex-is-mythical-switch-row'),
                    label: 'Mythique',
                    value: _isMythical,
                    switchKey: const Key('pokedex-is-mythical-switch'),
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _isMythical = value),
                  ),
                  const SizedBox(height: 10),
                  _PokedexBooleanEditorRow(
                    key: const Key('pokedex-is-baby-switch-row'),
                    label: 'Bébé',
                    value: _isBaby,
                    switchKey: const Key('pokedex-is-baby-switch'),
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _isBaby = value),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      CupertinoButton.filled(
                        key: const Key('pokedex-save-forms-button'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        onPressed: _isSaving ? null : _saveDraft,
                        child: Text(
                          _isSaving ? 'Enregistrement…' : 'Enregistrer',
                        ),
                      ),
                      const SizedBox(width: 10),
                      CupertinoButton(
                        key: const Key('pokedex-cancel-forms-button'),
                        onPressed: _isSaving ? null : _cancelEditing,
                        child: const Text('Annuler'),
                      ),
                    ],
                  ),
                  if (_saveErrorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _saveErrorMessage!,
                      key: const Key('pokedex-forms-save-error'),
                      style: const TextStyle(
                        color: EditorChrome.inspectorJoyCoral,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ] else ...[
                  _PokedexPropertyLine(
                    label: 'Forme courante',
                    value: forms.formName == null || forms.formName!.isEmpty
                        ? currentFormId
                        : '${forms.formName} ($currentFormId)',
                  ),
                  _PokedexPropertyLine(
                    label: 'Forme de base',
                    value: baseFormId,
                  ),
                  _PokedexPropertyLine(
                    label: 'Est la forme de base',
                    value: forms.isBaseForm ? 'Oui' : 'Non',
                  ),
                  _PokedexPropertyLine(
                    label: 'Autres formes',
                    value: forms.otherForms.isEmpty
                        ? 'Aucune autre forme locale'
                        : forms.otherForms.join(', '),
                  ),
                  _PokedexPropertyLine(
                    label: 'Statut projet',
                    value: classification.isEnabledInProject
                        ? 'Activée'
                        : 'Désactivée',
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FlagChip(
                        label: classification.isObtainable
                            ? 'Obtenable'
                            : 'Non obtenable',
                      ),
                      if (classification.isLegendary)
                        const _FlagChip(label: 'Légendaire'),
                      if (classification.isMythical)
                        const _FlagChip(label: 'Mythique'),
                      if (classification.isBaby) const _FlagChip(label: 'Bébé'),
                      if (!classification.isLegendary &&
                          !classification.isMythical &&
                          !classification.isBaby)
                        const _FlagChip(label: 'Aucun flag rare'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  CupertinoButton(
                    key: const Key('pokedex-edit-forms-button'),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _replaceDraftFromSpecies(widget.detail.species);
                        _isEditing = true;
                        _saveErrorMessage = null;
                      });
                    },
                    child: const Text('Modifier'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Flags gameplay simples',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (species.gameplayFlags.starterEligible)
                  const _FlagChip(label: 'Starter éligible'),
                if (species.gameplayFlags.giftOnly)
                  const _FlagChip(label: 'Obtenu par cadeau'),
                if (species.gameplayFlags.tradeOnly)
                  const _FlagChip(label: 'Échange uniquement'),
                if (!species.gameplayFlags.starterEligible &&
                    !species.gameplayFlags.giftOnly &&
                    !species.gameplayFlags.tradeOnly)
                  const _FlagChip(label: 'Aucun flag gameplay'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PokedexLearnsetTab extends StatefulWidget {
  const _PokedexLearnsetTab({
    required this.detail,
    required this.onSave,
  });

  final PokedexSpeciesDetail detail;
  final Future<void> Function(UpdatePokedexSpeciesLearnsetRequest request)
      onSave;

  @override
  State<_PokedexLearnsetTab> createState() => _PokedexLearnsetTabState();
}

class _PokedexLearnsetTabState extends State<_PokedexLearnsetTab> {
  late final TextEditingController _startingMovesController;
  late final TextEditingController _relearnMovesController;
  late final TextEditingController _levelUpController;
  late final TextEditingController _tmController;
  late final TextEditingController _tutorController;
  late final TextEditingController _eggController;
  late final TextEditingController _eventController;
  late final TextEditingController _transferController;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _saveErrorMessage;

  @override
  void initState() {
    super.initState();
    _startingMovesController = TextEditingController();
    _relearnMovesController = TextEditingController();
    _levelUpController = TextEditingController();
    _tmController = TextEditingController();
    _tutorController = TextEditingController();
    _eggController = TextEditingController();
    _eventController = TextEditingController();
    _transferController = TextEditingController();
    _replaceDraftFromDetail(widget.detail);
  }

  @override
  void didUpdateWidget(covariant _PokedexLearnsetTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail != widget.detail) {
      _replaceDraftFromDetail(widget.detail);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    }
  }

  @override
  void dispose() {
    _startingMovesController.dispose();
    _relearnMovesController.dispose();
    _levelUpController.dispose();
    _tmController.dispose();
    _tutorController.dispose();
    _eggController.dispose();
    _eventController.dispose();
    _transferController.dispose();
    super.dispose();
  }

  void _replaceDraftFromDetail(PokedexSpeciesDetail detail) {
    final learnset = detail.learnset;
    _startingMovesController.text =
        learnset == null ? '' : _formatLineList(learnset.startingMoves);
    _relearnMovesController.text =
        learnset == null ? '' : _formatLineList(learnset.relearnMoves);
    _levelUpController.text =
        learnset == null ? '' : _formatLearnsetLevelUpEntries(learnset.levelUp);
    _tmController.text =
        learnset == null ? '' : _formatLearnsetMoveEntries(learnset.tm);
    _tutorController.text =
        learnset == null ? '' : _formatLearnsetMoveEntries(learnset.tutor);
    _eggController.text =
        learnset == null ? '' : _formatLearnsetMoveEntries(learnset.egg);
    _eventController.text =
        learnset == null ? '' : _formatLearnsetMoveEntries(learnset.event);
    _transferController.text =
        learnset == null ? '' : _formatLearnsetMoveEntries(learnset.transfer);
  }

  Future<void> _saveDraft() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _saveErrorMessage = null;
    });

    try {
      await widget.onSave(
        UpdatePokedexSpeciesLearnsetRequest(
          speciesId: widget.detail.species.id,
          startingMoves: _splitNonEmptyLines(_startingMovesController.text),
          relearnMoves: _splitNonEmptyLines(_relearnMovesController.text),
          levelUp: _parseLearnsetLevelUpEntries(_levelUpController.text),
          tm: _parseLearnsetMoveEntries(_tmController.text, label: 'tm'),
          tutor: _parseLearnsetMoveEntries(
            _tutorController.text,
            label: 'tutor',
          ),
          egg: _parseLearnsetMoveEntries(_eggController.text, label: 'egg'),
          event: _parseLearnsetMoveEntries(
            _eventController.text,
            label: 'event',
          ),
          transfer: _parseLearnsetMoveEntries(
            _transferController.text,
            label: 'transfer',
          ),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isEditing = false;
        _isSaving = false;
        _saveErrorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = switch (error) {
        final EditorApplicationException applicationError =>
          applicationError.message,
        _ => error.toString(),
      };
      setState(() {
        _isSaving = false;
        _saveErrorMessage = message;
      });
    }
  }

  void _cancelEditing() {
    setState(() {
      _replaceDraftFromDetail(widget.detail);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final learnset = widget.detail.learnset;
    final learnsetRef = widget.detail.species.refs.learnset.trim();

    return SingleChildScrollView(
      key: const Key('pokedex-learnset-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isEditing) ...[
            _PokedexDetailSectionCard(
              title: 'Édition learnset locale',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PokedexPropertyLine(
                    label: 'Ref learnset',
                    value: learnsetRef.isEmpty ? 'Ref absente' : learnsetRef,
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Moves de départ',
                    description:
                        'Un move id par ligne. Les doublons exacts sont ignorés.',
                    fieldKey: const Key('pokedex-learnset-starting-field'),
                    controller: _startingMovesController,
                    enabled: !_isSaving,
                    minLines: 2,
                    maxLines: 5,
                    placeholder: 'tackle\ngrowl',
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Moves à réapprendre',
                    description: 'Un move id par ligne.',
                    fieldKey: const Key('pokedex-learnset-relearn-field'),
                    controller: _relearnMovesController,
                    enabled: !_isSaving,
                    minLines: 2,
                    maxLines: 5,
                    placeholder: 'vine_whip',
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Level-up',
                    description:
                        'Une entrée par ligne au format moveId|level|source|versionGroup.',
                    fieldKey: const Key('pokedex-learnset-level-up-field'),
                    controller: _levelUpController,
                    enabled: !_isSaving,
                    minLines: 3,
                    maxLines: 8,
                    placeholder: 'vine_whip|7|level_up|scarlet-violet',
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'TM',
                    description:
                        'Une entrée par ligne au format moveId|versionGroup.',
                    fieldKey: const Key('pokedex-learnset-tm-field'),
                    controller: _tmController,
                    enabled: !_isSaving,
                    minLines: 2,
                    maxLines: 6,
                    placeholder: 'protect|scarlet-violet',
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Tutor',
                    description:
                        'Une entrée par ligne au format moveId|versionGroup.',
                    fieldKey: const Key('pokedex-learnset-tutor-field'),
                    controller: _tutorController,
                    enabled: !_isSaving,
                    minLines: 2,
                    maxLines: 6,
                    placeholder: 'seed_bomb|scarlet-violet',
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Egg',
                    description:
                        'Une entrée par ligne au format moveId|versionGroup.',
                    fieldKey: const Key('pokedex-learnset-egg-field'),
                    controller: _eggController,
                    enabled: !_isSaving,
                    minLines: 2,
                    maxLines: 6,
                    placeholder: 'petal_dance|scarlet-violet',
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Event',
                    description:
                        'Une entrée par ligne au format moveId|versionGroup.',
                    fieldKey: const Key('pokedex-learnset-event-field'),
                    controller: _eventController,
                    enabled: !_isSaving,
                    minLines: 2,
                    maxLines: 6,
                    placeholder: 'celebrate|scarlet-violet',
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Transfer',
                    description:
                        'Une entrée par ligne au format moveId|versionGroup.',
                    fieldKey: const Key('pokedex-learnset-transfer-field'),
                    controller: _transferController,
                    enabled: !_isSaving,
                    minLines: 2,
                    maxLines: 6,
                    placeholder: 'toxic|scarlet-violet',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      CupertinoButton.filled(
                        key: const Key('pokedex-save-learnset-button'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        onPressed: _isSaving ? null : _saveDraft,
                        child: Text(
                          _isSaving ? 'Enregistrement…' : 'Enregistrer',
                        ),
                      ),
                      const SizedBox(width: 10),
                      CupertinoButton(
                        key: const Key('pokedex-cancel-learnset-button'),
                        onPressed: _isSaving ? null : _cancelEditing,
                        child: const Text('Annuler'),
                      ),
                    ],
                  ),
                  if (_saveErrorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _saveErrorMessage!,
                      key: const Key('pokedex-learnset-save-error'),
                      style: const TextStyle(
                        color: EditorChrome.inspectorJoyCoral,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            if (learnset == null)
              _PokedexMissingSection(
                key: const Key('pokedex-learnset-missing'),
                title: 'Learnset',
                message: learnsetRef.isEmpty
                    ? 'La ref learnset est vide dans l’espèce locale ; aucun learnset ne peut être édité depuis cette fiche.'
                    : 'Aucun learnset local trouvé pour cette espèce. Vous pouvez en créer un depuis cet onglet.',
              )
            else ...[
              _PokedexDetailSectionCard(
                title: 'Moves de départ',
                child: Text(
                  learnset.startingMoves.isEmpty
                      ? 'Aucun move de départ déclaré.'
                      : learnset.startingMoves.join(', '),
                ),
              ),
              const SizedBox(height: 12),
              _PokedexDetailSectionCard(
                title: 'Moves à réapprendre',
                child: Text(
                  learnset.relearnMoves.isEmpty
                      ? 'Aucun move à réapprendre déclaré.'
                      : learnset.relearnMoves.join(', '),
                ),
              ),
              const SizedBox(height: 12),
              _PokedexDetailSectionCard(
                title: 'Level-up',
                child: learnset.levelUp.isEmpty
                    ? const Text('Aucune entrée level-up.')
                    : Column(
                        children: learnset.levelUp
                            .map(
                              (entry) => _PokedexPropertyLine(
                                label:
                                    '${entry.moveId} • niveau ${entry.level}',
                                value:
                                    '${entry.versionGroup} • source ${entry.source}',
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
              const SizedBox(height: 12),
              _LearnsetMoveSection(title: 'TM', entries: learnset.tm),
              const SizedBox(height: 12),
              _LearnsetMoveSection(title: 'Tutor', entries: learnset.tutor),
              const SizedBox(height: 12),
              _LearnsetMoveSection(title: 'Egg', entries: learnset.egg),
              const SizedBox(height: 12),
              _LearnsetMoveSection(title: 'Event', entries: learnset.event),
              const SizedBox(height: 12),
              _LearnsetMoveSection(
                title: 'Transfer',
                entries: learnset.transfer,
              ),
            ],
            const SizedBox(height: 12),
            _PokedexDetailSectionCard(
              title: 'Édition locale',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    learnsetRef.isEmpty
                        ? 'Impossible d’éditer ce learnset tant que la ref locale est vide.'
                        : 'Le learnset édité réécrit uniquement le JSON local déjà relié par les refs de l’espèce.',
                  ),
                  if (learnsetRef.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    CupertinoButton(
                      key: const Key('pokedex-edit-learnset-button'),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _replaceDraftFromDetail(widget.detail);
                          _isEditing = true;
                          _saveErrorMessage = null;
                        });
                      },
                      child: Text(
                        learnset == null ? 'Créer localement' : 'Modifier',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PokedexEvolutionTab extends StatefulWidget {
  const _PokedexEvolutionTab({
    required this.detail,
    required this.onSave,
  });

  final PokedexSpeciesDetail detail;
  final Future<void> Function(UpdatePokedexSpeciesEvolutionRequest request)
      onSave;

  @override
  State<_PokedexEvolutionTab> createState() => _PokedexEvolutionTabState();
}

class _PokedexEvolutionTabState extends State<_PokedexEvolutionTab> {
  late final TextEditingController _preEvolutionController;
  late final TextEditingController _entriesController;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _saveErrorMessage;

  @override
  void initState() {
    super.initState();
    _preEvolutionController = TextEditingController();
    _entriesController = TextEditingController();
    _replaceDraftFromDetail(widget.detail);
  }

  @override
  void didUpdateWidget(covariant _PokedexEvolutionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail != widget.detail) {
      _replaceDraftFromDetail(widget.detail);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    }
  }

  @override
  void dispose() {
    _preEvolutionController.dispose();
    _entriesController.dispose();
    super.dispose();
  }

  void _replaceDraftFromDetail(PokedexSpeciesDetail detail) {
    final evolution = detail.evolution;
    _preEvolutionController.text = evolution?.preEvolution ?? '';
    _entriesController.text =
        evolution == null ? '' : _formatEvolutionEntries(evolution.evolutions);
  }

  Future<void> _saveDraft() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _saveErrorMessage = null;
    });

    try {
      await widget.onSave(
        UpdatePokedexSpeciesEvolutionRequest(
          speciesId: widget.detail.species.id,
          preEvolution: _preEvolutionController.text,
          evolutions: _parseEvolutionEntries(_entriesController.text),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isEditing = false;
        _isSaving = false;
        _saveErrorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = switch (error) {
        final EditorApplicationException applicationError =>
          applicationError.message,
        _ => error.toString(),
      };
      setState(() {
        _isSaving = false;
        _saveErrorMessage = message;
      });
    }
  }

  void _cancelEditing() {
    setState(() {
      _replaceDraftFromDetail(widget.detail);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final evolution = widget.detail.evolution;
    final evolutionRef = widget.detail.species.refs.evolution.trim();

    return SingleChildScrollView(
      key: const Key('pokedex-evolutions-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isEditing) ...[
            _PokedexDetailSectionCard(
              title: 'Édition évolution locale',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PokedexPropertyLine(
                    label: 'Ref évolution',
                    value: evolutionRef.isEmpty ? 'Ref absente' : evolutionRef,
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Pré-évolution',
                    description:
                        'Laissez vide si l’espèce n’a pas de pré-évolution locale.',
                    fieldKey: const Key('pokedex-pre-evolution-field'),
                    controller: _preEvolutionController,
                    enabled: !_isSaving,
                    placeholder: 'bulbasaur',
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Évolutions suivantes',
                    description:
                        'Une entrée par ligne au format targetSpeciesId|method|minLevel|itemId|requiredMoveId|conditionFr|conditionEn.',
                    fieldKey: const Key('pokedex-evolution-entries-field'),
                    controller: _entriesController,
                    enabled: !_isSaving,
                    minLines: 3,
                    maxLines: 8,
                    placeholder:
                        'ivysaur|level_up|16|||Évolue au niveau 16|Evolves at level 16',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      CupertinoButton.filled(
                        key: const Key('pokedex-save-evolution-button'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        onPressed: _isSaving ? null : _saveDraft,
                        child: Text(
                          _isSaving ? 'Enregistrement…' : 'Enregistrer',
                        ),
                      ),
                      const SizedBox(width: 10),
                      CupertinoButton(
                        key: const Key('pokedex-cancel-evolution-button'),
                        onPressed: _isSaving ? null : _cancelEditing,
                        child: const Text('Annuler'),
                      ),
                    ],
                  ),
                  if (_saveErrorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _saveErrorMessage!,
                      key: const Key('pokedex-evolution-save-error'),
                      style: const TextStyle(
                        color: EditorChrome.inspectorJoyCoral,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            if (evolution == null)
              _PokedexMissingSection(
                key: const Key('pokedex-evolutions-missing'),
                title: 'Évolutions',
                message: evolutionRef.isEmpty
                    ? 'La ref évolution est vide dans l’espèce locale ; aucune évolution ne peut être éditée depuis cette fiche.'
                    : 'Aucune donnée d’évolution locale trouvée pour cette espèce. Vous pouvez en créer une depuis cet onglet.',
              )
            else ...[
              _PokedexDetailSectionCard(
                title: 'Pré-évolution',
                child: Text(evolution.preEvolution?.trim().isNotEmpty == true
                    ? evolution.preEvolution!
                    : 'Aucune'),
              ),
              const SizedBox(height: 12),
              _PokedexDetailSectionCard(
                title: 'Évolutions suivantes',
                child: evolution.evolutions.isEmpty
                    ? const Text('Aucune évolution déclarée.')
                    : Column(
                        children: evolution.evolutions
                            .map(
                              (entry) => _PokedexPropertyLine(
                                label: entry.targetSpeciesId,
                                value: _describeEvolution(entry),
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
            ],
            const SizedBox(height: 12),
            _PokedexDetailSectionCard(
              title: 'Édition locale',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evolutionRef.isEmpty
                        ? 'Impossible d’éditer cette chaîne tant que la ref locale est vide.'
                        : 'La chaîne d’évolution reste limitée au contrat déjà supporté par le modèle courant.',
                  ),
                  if (evolutionRef.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    CupertinoButton(
                      key: const Key('pokedex-edit-evolution-button'),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _replaceDraftFromDetail(widget.detail);
                          _isEditing = true;
                          _saveErrorMessage = null;
                        });
                      },
                      child: Text(
                        evolution == null ? 'Créer localement' : 'Modifier',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PokedexMediaTab extends StatefulWidget {
  const _PokedexMediaTab({
    required this.detail,
    required this.onSave,
  });

  final PokedexSpeciesDetail detail;
  final Future<void> Function(UpdatePokedexSpeciesMediaRequest request) onSave;

  @override
  State<_PokedexMediaTab> createState() => _PokedexMediaTabState();
}

class _PokedexMediaTabState extends State<_PokedexMediaTab> {
  late final TextEditingController _defaultFormIdController;
  late final TextEditingController _variantEntriesController;
  late final TextEditingController _animationEntriesController;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _saveErrorMessage;

  @override
  void initState() {
    super.initState();
    _defaultFormIdController = TextEditingController();
    _variantEntriesController = TextEditingController();
    _animationEntriesController = TextEditingController();
    _replaceDraftFromDetail(widget.detail);
  }

  @override
  void didUpdateWidget(covariant _PokedexMediaTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail != widget.detail) {
      _replaceDraftFromDetail(widget.detail);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    }
  }

  @override
  void dispose() {
    _defaultFormIdController.dispose();
    _variantEntriesController.dispose();
    _animationEntriesController.dispose();
    super.dispose();
  }

  void _replaceDraftFromDetail(PokedexSpeciesDetail detail) {
    final media = detail.media;
    _defaultFormIdController.text = media?.defaultFormId ?? '';
    _variantEntriesController.text =
        media == null ? '' : _formatMediaVariantEntries(media.variants);
    _animationEntriesController.text =
        media == null ? '' : _formatMediaAnimationEntries(media.variants);
  }

  Future<void> _saveDraft() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _saveErrorMessage = null;
    });

    try {
      final variants = _parseMediaVariants(_variantEntriesController.text);
      _applyMediaAnimationEntries(
        variants,
        _animationEntriesController.text,
      );

      await widget.onSave(
        UpdatePokedexSpeciesMediaRequest(
          speciesId: widget.detail.species.id,
          defaultFormId: _defaultFormIdController.text,
          variants: variants,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isEditing = false;
        _isSaving = false;
        _saveErrorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = switch (error) {
        final EditorApplicationException applicationError =>
          applicationError.message,
        _ => error.toString(),
      };
      setState(() {
        _isSaving = false;
        _saveErrorMessage = message;
      });
    }
  }

  void _cancelEditing() {
    setState(() {
      _replaceDraftFromDetail(widget.detail);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.detail.media;
    final mediaRef = widget.detail.species.refs.media.trim();

    return SingleChildScrollView(
      key: const Key('pokedex-media-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isEditing) ...[
            _PokedexDetailSectionCard(
              title: 'Édition média locale',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PokedexPropertyLine(
                    label: 'Ref média',
                    value: mediaRef.isEmpty ? 'Ref absente' : mediaRef,
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Forme par défaut',
                    description:
                        'La forme par défaut doit exister dans la liste des variantes.',
                    fieldKey: const Key('pokedex-media-default-form-field'),
                    controller: _defaultFormIdController,
                    enabled: !_isSaving,
                    placeholder: 'base',
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Variantes média',
                    description:
                        'Une ligne par variante : variantId|front|back|frontShiny|backShiny|icon|party|overworld|portrait|cry.',
                    fieldKey: const Key('pokedex-media-variants-field'),
                    controller: _variantEntriesController,
                    enabled: !_isSaving,
                    minLines: 4,
                    maxLines: 10,
                    placeholder:
                        'base|assets/pokemon/sprites/bulbasaur/front.png|assets/pokemon/sprites/bulbasaur/back.png|||assets/pokemon/sprites/bulbasaur/icon.png|assets/pokemon/sprites/bulbasaur/party.png||assets/pokemon/portraits/bulbasaur.png|assets/pokemon/cries/bulbasaur.ogg',
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Animations',
                    description:
                        'Une ligne par animation : variantId|animationKey|sheet|animationId.',
                    fieldKey: const Key('pokedex-media-animations-field'),
                    controller: _animationEntriesController,
                    enabled: !_isSaving,
                    minLines: 3,
                    maxLines: 8,
                    placeholder:
                        'base|battleFront|assets/pokemon/sprites/bulbasaur/battle_front_sheet.png|battle_front',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      CupertinoButton.filled(
                        key: const Key('pokedex-save-media-button'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        onPressed: _isSaving ? null : _saveDraft,
                        child: Text(
                          _isSaving ? 'Enregistrement…' : 'Enregistrer',
                        ),
                      ),
                      const SizedBox(width: 10),
                      CupertinoButton(
                        key: const Key('pokedex-cancel-media-button'),
                        onPressed: _isSaving ? null : _cancelEditing,
                        child: const Text('Annuler'),
                      ),
                    ],
                  ),
                  if (_saveErrorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _saveErrorMessage!,
                      key: const Key('pokedex-media-save-error'),
                      style: const TextStyle(
                        color: EditorChrome.inspectorJoyCoral,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            if (media == null)
              _PokedexMissingSection(
                key: const Key('pokedex-media-missing'),
                title: 'Médias',
                message: mediaRef.isEmpty
                    ? 'La ref média est vide dans l’espèce locale ; aucun média ne peut être édité depuis cette fiche.'
                    : 'Aucune donnée média locale trouvée pour cette espèce. Vous pouvez en créer une depuis cet onglet.',
              )
            else ...[
              _PokedexDetailSectionCard(
                title: 'Variante par défaut',
                child: Column(
                  children: [
                    _PokedexPropertyLine(
                      label: 'Forme par défaut',
                      value: media.defaultFormId,
                    ),
                    _PokedexPropertyLine(
                      label: 'Variantes déclarées',
                      value: media.variants.keys.join(', '),
                    ),
                  ],
                ),
              ),
              for (final entry in media.variants.entries) ...[
                const SizedBox(height: 12),
                _PokedexDetailSectionCard(
                  title: entry.key == media.defaultFormId
                      ? 'Variante ${entry.key} (défaut)'
                      : 'Variante ${entry.key}',
                  child: Column(
                    children: [
                      _PokedexPropertyLine(
                        label: 'front',
                        value: entry.value.frontStatic ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'back',
                        value: entry.value.backStatic ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'front shiny',
                        value: entry.value.frontShinyStatic ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'back shiny',
                        value: entry.value.backShinyStatic ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'icon',
                        value: entry.value.icon ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'party',
                        value: entry.value.party ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'overworld',
                        value: entry.value.overworld ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'portrait',
                        value: entry.value.portrait ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'cry',
                        value: entry.value.cry ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'Animations',
                        value: entry.value.animations.isEmpty
                            ? 'Aucune animation locale déclarée.'
                            : entry.value.animations.entries
                                .map(
                                  (animation) =>
                                      '${animation.key}: ${animation.value.animationId}',
                                )
                                .join(', '),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const _PokedexDetailSectionCard(
                title: 'Contrat média',
                child: Text(
                  'Les médias Pokémon restent de simples références locales vers assets/pokemon/... et n’utilisent jamais de GIF.',
                ),
              ),
            ],
            const SizedBox(height: 12),
            _PokedexDetailSectionCard(
              title: 'Édition locale',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mediaRef.isEmpty
                        ? 'Impossible d’éditer ces médias tant que la ref locale est vide.'
                        : 'Les chemins restent de simples refs locales cohérentes avec le contrat média actuel.',
                  ),
                  if (mediaRef.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    CupertinoButton(
                      key: const Key('pokedex-edit-media-button'),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _replaceDraftFromDetail(widget.detail);
                          _isEditing = true;
                          _saveErrorMessage = null;
                        });
                      },
                      child:
                          Text(media == null ? 'Créer localement' : 'Modifier'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LearnsetMoveSection extends StatelessWidget {
  const _LearnsetMoveSection({
    required this.title,
    required this.entries,
  });

  final String title;
  final List<PokemonLearnsetMoveEntry> entries;

  @override
  Widget build(BuildContext context) {
    return _PokedexDetailSectionCard(
      title: title,
      child: entries.isEmpty
          ? Text('Aucune entrée $title.')
          : Column(
              children: entries
                  .map(
                    (entry) => _PokedexPropertyLine(
                      label: entry.moveId,
                      value: entry.versionGroup,
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _PokedexMissingSection extends StatelessWidget {
  const _PokedexMissingSection({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _PokedexDetailSectionCard(
      title: title,
      child: Text(message),
    );
  }
}

class _PokedexDetailSectionCard extends StatelessWidget {
  const _PokedexDetailSectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surface = Color.lerp(
      EditorChrome.islandFillElevated(context),
      CupertinoColors.black,
      0.06,
    )!;
    final border = EditorChrome.accentWarm.withValues(alpha: 0.24);
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: DefaultTextStyle(
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: label,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _PokedexPropertyLine extends StatelessWidget {
  const _PokedexPropertyLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final labelColor = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final fill = EditorChrome.islandFillElevated(context);
    final labelColor = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: EditorChrome.accentJade.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: subtle,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: TextStyle(
                color: labelColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final text = EditorChrome.primaryLabel(context);
    final fill = Color.lerp(
      EditorChrome.chipFill(context),
      EditorChrome.accentWarm,
      0.18,
    )!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: text,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

String _localizedValue(Map<String, String> values) {
  for (final key in const <String>['fr', 'en']) {
    final value = values[key]?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return values.values.firstWhere(
    (value) => value.trim().isNotEmpty,
    orElse: () => 'Aucune valeur locale',
  );
}

List<String> _orderedLocaleKeys(Map<String, String> values) {
  final locales = values.keys
      .map((key) => key.trim())
      .where((key) => key.isNotEmpty)
      .toSet()
      .toList(growable: false);

  // On garde un ordre stable et lisible dans la UI :
  // - `fr` puis `en` si présents, car ce sont les locales déjà privilégiées
  //   ailleurs dans le Pokédex ;
  // - puis le reste en ordre alphabétique pour éviter tout mouvement arbitraire
  //   des champs entre deux rebuilds.
  locales.sort((left, right) {
    final leftPriority = switch (left) {
      'fr' => 0,
      'en' => 1,
      _ => 2,
    };
    final rightPriority = switch (right) {
      'fr' => 0,
      'en' => 1,
      _ => 2,
    };
    final priorityCompare = leftPriority.compareTo(rightPriority);
    if (priorityCompare != 0) {
      return priorityCompare;
    }
    return left.compareTo(right);
  });

  return locales;
}

List<String> _splitNonEmptyLines(String raw) {
  return LineSplitter.split(raw)
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
}

String _formatLineList(List<String> values) {
  return values.join('\n');
}

String _formatLearnsetLevelUpEntries(
  List<PokemonLearnsetLevelUpEntry> entries,
) {
  return entries
      .map(
        (entry) =>
            '${entry.moveId}|${entry.level}|${entry.source}|${entry.versionGroup}',
      )
      .join('\n');
}

String _formatLearnsetMoveEntries(List<PokemonLearnsetMoveEntry> entries) {
  return entries
      .map((entry) => '${entry.moveId}|${entry.versionGroup}')
      .join('\n');
}

List<PokemonLearnsetLevelUpEntry> _parseLearnsetLevelUpEntries(String raw) {
  final entries = <PokemonLearnsetLevelUpEntry>[];
  final lines = LineSplitter.split(raw).toList(growable: false);

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.isEmpty) {
      continue;
    }

    final parts = line.split('|');
    if (parts.length != 4) {
      throw EditorValidationException(
        'Pokemon learnset levelUp line ${index + 1} must use moveId|level|source|versionGroup',
      );
    }

    final level = int.tryParse(parts[1].trim());
    if (level == null) {
      throw EditorValidationException(
        'Pokemon learnset levelUp line ${index + 1} level must be an integer',
      );
    }

    entries.add(
      PokemonLearnsetLevelUpEntry(
        moveId: parts[0].trim(),
        level: level,
        source: parts[2].trim(),
        versionGroup: parts[3].trim(),
      ),
    );
  }

  return entries;
}

List<PokemonLearnsetMoveEntry> _parseLearnsetMoveEntries(
  String raw, {
  required String label,
}) {
  final entries = <PokemonLearnsetMoveEntry>[];
  final lines = LineSplitter.split(raw).toList(growable: false);

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.isEmpty) {
      continue;
    }

    final parts = line.split('|');
    if (parts.length != 2) {
      throw EditorValidationException(
        'Pokemon learnset $label line ${index + 1} must use moveId|versionGroup',
      );
    }

    entries.add(
      PokemonLearnsetMoveEntry(
        moveId: parts[0].trim(),
        versionGroup: parts[1].trim(),
      ),
    );
  }

  return entries;
}

String _formatEvolutionEntries(List<PokemonEvolutionEntry> entries) {
  return entries
      .map(
        (entry) => [
          entry.targetSpeciesId,
          entry.method,
          entry.minLevel?.toString() ?? '',
          entry.itemId ?? '',
          entry.requiredMoveId ?? '',
          entry.conditionText['fr'] ?? '',
          entry.conditionText['en'] ?? '',
        ].join('|'),
      )
      .join('\n');
}

List<PokemonEvolutionEntry> _parseEvolutionEntries(String raw) {
  final entries = <PokemonEvolutionEntry>[];
  final lines = LineSplitter.split(raw).toList(growable: false);

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.isEmpty) {
      continue;
    }

    final parts = line.split('|');
    if (parts.length < 2 || parts.length > 7) {
      throw EditorValidationException(
        'Pokemon evolution line ${index + 1} must use targetSpeciesId|method|minLevel|itemId|requiredMoveId|conditionFr|conditionEn',
      );
    }

    while (parts.length < 7) {
      parts.add('');
    }

    final rawLevel = parts[2].trim();
    final minLevel = rawLevel.isEmpty ? null : int.tryParse(rawLevel);
    if (rawLevel.isNotEmpty && minLevel == null) {
      throw EditorValidationException(
        'Pokemon evolution line ${index + 1} minLevel must be an integer',
      );
    }

    final conditionText = <String, String>{};
    final fr = parts[5].trim();
    final en = parts[6].trim();
    if (fr.isNotEmpty) {
      conditionText['fr'] = fr;
    }
    if (en.isNotEmpty) {
      conditionText['en'] = en;
    }

    entries.add(
      PokemonEvolutionEntry(
        targetSpeciesId: parts[0].trim(),
        method: parts[1].trim(),
        minLevel: minLevel,
        itemId: _trimmedOrNull(parts[3]),
        requiredMoveId: _trimmedOrNull(parts[4]),
        conditionText: conditionText,
      ),
    );
  }

  return entries;
}

String _formatMediaVariantEntries(Map<String, PokemonMediaVariant> variants) {
  return variants.entries
      .map(
        (entry) => [
          entry.key,
          entry.value.frontStatic ?? '',
          entry.value.backStatic ?? '',
          entry.value.frontShinyStatic ?? '',
          entry.value.backShinyStatic ?? '',
          entry.value.icon ?? '',
          entry.value.party ?? '',
          entry.value.overworld ?? '',
          entry.value.portrait ?? '',
          entry.value.cry ?? '',
        ].join('|'),
      )
      .join('\n');
}

String _formatMediaAnimationEntries(Map<String, PokemonMediaVariant> variants) {
  final lines = <String>[];
  for (final entry in variants.entries) {
    for (final animation in entry.value.animations.entries) {
      lines.add(
        [
          entry.key,
          animation.key,
          animation.value.sheet,
          animation.value.animationId,
        ].join('|'),
      );
    }
  }
  return lines.join('\n');
}

Map<String, PokemonMediaVariant> _parseMediaVariants(String raw) {
  final variants = <String, PokemonMediaVariant>{};
  final lines = LineSplitter.split(raw).toList(growable: false);

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.isEmpty) {
      continue;
    }

    final parts = line.split('|');
    if (parts.length > 10) {
      throw EditorValidationException(
        'Pokemon media variant line ${index + 1} must use variantId|front|back|frontShiny|backShiny|icon|party|overworld|portrait|cry',
      );
    }

    while (parts.length < 10) {
      parts.add('');
    }

    variants[parts[0].trim()] = PokemonMediaVariant(
      frontStatic: _trimmedOrNull(parts[1]),
      backStatic: _trimmedOrNull(parts[2]),
      frontShinyStatic: _trimmedOrNull(parts[3]),
      backShinyStatic: _trimmedOrNull(parts[4]),
      icon: _trimmedOrNull(parts[5]),
      party: _trimmedOrNull(parts[6]),
      overworld: _trimmedOrNull(parts[7]),
      portrait: _trimmedOrNull(parts[8]),
      cry: _trimmedOrNull(parts[9]),
    );
  }

  return variants;
}

void _applyMediaAnimationEntries(
  Map<String, PokemonMediaVariant> variants,
  String raw,
) {
  final lines = LineSplitter.split(raw).toList(growable: false);

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.isEmpty) {
      continue;
    }

    final parts = line.split('|');
    if (parts.length != 4) {
      throw EditorValidationException(
        'Pokemon media animation line ${index + 1} must use variantId|animationKey|sheet|animationId',
      );
    }

    final variantId = parts[0].trim();
    if (variantId.isEmpty) {
      throw EditorValidationException(
        'Pokemon media animation line ${index + 1} variantId cannot be empty',
      );
    }

    final currentVariant = variants[variantId] ?? const PokemonMediaVariant();
    final animations = <String, PokemonMediaAnimationRef>{
      ...currentVariant.animations,
      parts[1].trim(): PokemonMediaAnimationRef(
        sheet: parts[2].trim(),
        animationId: parts[3].trim(),
      ),
    };

    variants[variantId] = PokemonMediaVariant(
      frontStatic: currentVariant.frontStatic,
      backStatic: currentVariant.backStatic,
      frontShinyStatic: currentVariant.frontShinyStatic,
      backShinyStatic: currentVariant.backShinyStatic,
      icon: currentVariant.icon,
      party: currentVariant.party,
      overworld: currentVariant.overworld,
      portrait: currentVariant.portrait,
      cry: currentVariant.cry,
      animations: animations,
    );
  }
}

String? _trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String _describeEvolution(PokemonEvolutionEntry entry) {
  final explicit = _localizedValue(entry.conditionText);
  if (explicit != 'Aucune valeur locale') {
    return explicit;
  }
  if (entry.minLevel != null) {
    return 'Évolue au niveau ${entry.minLevel}';
  }
  if (entry.itemId != null && entry.itemId!.trim().isNotEmpty) {
    return 'Évolue avec ${entry.itemId}';
  }
  if (entry.requiredMoveId != null && entry.requiredMoveId!.trim().isNotEmpty) {
    return 'Évolue avec le move ${entry.requiredMoveId}';
  }
  if (entry.method.trim().isNotEmpty) {
    return 'Méthode : ${entry.method}';
  }
  return 'Condition non précisée';
}

/// Carte de base réutilisée pour "pas de projet", "vide" et "erreur".
///
/// On mutualise uniquement la présentation visuelle commune, sans introduire un
/// système d'état générique plus large que le besoin du lot 13.
class PokedexWorkspaceStateCard extends StatelessWidget {
  const PokedexWorkspaceStateCard({
    super.key,
    required this.title,
    required this.message,
    this.accent = EditorChrome.inspectorJoyAmber,
    this.titleStyle,
    this.messageStyle,
  });

  final String title;
  final String message;
  final Color accent;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return PokedexWorkspaceStateFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(CupertinoColors.white, accent, 0.72)!,
                  Color.lerp(accent, const Color(0xFF1A1408), 0.35)!,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accent.withValues(alpha: 0.82),
                width: 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: const MacosIcon(
              CupertinoIcons.book_fill,
              color: CupertinoColors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: titleStyle ??
                TextStyle(
                  color: label,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: messageStyle ??
                TextStyle(
                  color: subtle,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}

class PokedexWorkspaceStateFrame extends StatelessWidget {
  const PokedexWorkspaceStateFrame({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surface = EditorChrome.islandFillElevated(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: EditorChrome.inspectorJoyAmber.withValues(alpha: 0.38),
              width: 1.1,
            ),
            boxShadow: EditorChrome.sectionCardShadows(context),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
            child: child,
          ),
        ),
      ),
    );
  }
}
