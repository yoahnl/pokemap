import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart'
    show
        ControlSize,
        MacosIcon,
        MacosPopupButton,
        MacosPopupMenuItem,
        ProgressCircle,
        PushButton;
import 'package:path/path.dart' as p;

import '../../../app/providers/pokedex_providers.dart';
import '../../../application/errors/application_errors.dart';
import '../../../application/models/pokedex_species_detail.dart';
import '../../../application/models/pokemon_database_index.dart';
import '../../../application/models/pokemon_project_data_models.dart';
import '../../../application/ports/project_workspace.dart';
import '../../../application/use_cases/import_external_pokemon_use_cases.dart';
import '../../../application/use_cases/import_pokemon_json_bundle_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_evolution_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_forms_classification_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_learnset_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_media_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_metadata_use_case.dart';
import '../../../features/editor/state/editor_notifier.dart';
import '../../../infrastructure/filesystem/project_filesystem.dart';
import '../pokedex_workspace_loader.dart';
import '../../shared/cupertino_editor_widgets.dart';

part 'pokedex_workspace_body.dart';
part 'pokedex_workspace_logic.dart';
part 'pokedex_empty_state.dart';
part 'pokedex_feedback_banner.dart';
part 'pokedex_list_panel.dart';
part 'pokedex_toolbar.dart';
part 'pokedex_filters_panel.dart';
part 'pokedex_list_row.dart';
part 'pokedex_import_flow.dart';
part 'pokedex_import_flow_steps.dart';
part 'pokedex_import_flow_support.dart';
part 'pokedex_detail_panel.dart';
part 'pokedex_overview_panel.dart';
part 'pokedex_metadata_editor.dart';
part 'pokedex_metadata_editor_fields.dart';
part 'pokedex_forms_panel.dart';
part 'pokedex_learnset_panel.dart';
part 'pokedex_learnset_sections.dart';
part 'pokedex_evolution_panel.dart';
part 'pokedex_media_panel.dart';
part 'pokedex_common_widgets.dart';
part 'pokedex_formatters.dart';

const String _allTypesFilterValue = '__all_types__';
const String _allGenerationsFilterValue = '__all_generations__';
const String _allStatusesFilterValue = '__all_statuses__';
const String _enabledStatusFilterValue = '__enabled_only__';
const String _overviewTabId = 'overview';
const MethodChannel _macOsImportFileAccessChannel =
    MethodChannel('map_editor/file_access');

// Bibliothèque racine du workspace Pokédex.
//
// Toute la logique métier reste hors de l'UI :
// - les use cases et loaders sont injectés depuis les providers existants ;
// - cette couche orchestre uniquement l'affichage, la sélection locale et les
//   transitions utilisateur du workspace ;
// - le découpage en `part` garde les widgets privés déjà en place tout en
//   rendant l'écran maintenable et lisible pour l'équipe.
/// Workspace central Pokédex du lot 13.
///
/// Le widget public reste volontairement lisible :
/// - il lit le contexte éditeur existant ;
/// - il délègue le chargement par défaut à un helper local dédié ;
/// - il compose les quatre états UI strictement nécessaires.
///
/// On évite ainsi deux extrêmes :
/// - un gros widget fourre-tout mêlant UI et instanciation infra ;
/// - une nouvelle architecture Pokédex "future-ready" disproportionnée.
class PokedexWorkspace extends ConsumerWidget {
  const PokedexWorkspace({
    super.key,
    this.loader,
    this.detailLoader,
    this.importPreviewer,
    this.importer,
    this.externalImportPreviewer,
    this.externalImporter,
    this.pickJsonImportFile,
    this.metadataSaver,
    this.formsClassificationSaver,
    this.learnsetSaver,
    this.evolutionSaver,
    this.mediaSaver,
  });

  /// Injection locale utile aux tests ciblés du lot 13.
  ///
  /// On garde cette extension volontairement minimale : elle permet de tester
  /// le rendu des états UI sans introduire de notifier dédié supplémentaire.
  final PokedexEntryLoader? loader;
  final PokedexSpeciesDetailLoader? detailLoader;
  final PokedexImportPreviewer? importPreviewer;
  final PokedexImporter? importer;
  final PokedexExternalImportPreviewer? externalImportPreviewer;
  final PokedexExternalImporter? externalImporter;
  final Future<String?> Function()? pickJsonImportFile;
  final PokedexSpeciesMetadataSaver? metadataSaver;
  final PokedexSpeciesFormsClassificationSaver? formsClassificationSaver;
  final PokedexSpeciesLearnsetSaver? learnsetSaver;
  final PokedexSpeciesEvolutionSaver? evolutionSaver;
  final PokedexSpeciesMediaSaver? mediaSaver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectRootPath =
        ref.watch(editorNotifierProvider.select((s) => s.projectRootPath));
    final PokedexEntryLoader resolvedLoader =
        loader ?? ref.watch(pokedexEntryLoaderProvider);
    final PokedexSpeciesDetailLoader resolvedDetailLoader =
        detailLoader ?? ref.watch(pokedexSpeciesDetailLoaderProvider);
    final PokedexImportPreviewer resolvedImportPreviewer =
        importPreviewer ?? ref.watch(pokedexImportPreviewerProvider);
    final PokedexImporter resolvedImporter =
        importer ?? ref.watch(pokedexImporterProvider);
    final PokedexExternalImportPreviewer resolvedExternalImportPreviewer =
        externalImportPreviewer ??
            ref.watch(pokedexExternalImportPreviewerProvider);
    final PokedexExternalImporter resolvedExternalImporter =
        externalImporter ?? ref.watch(pokedexExternalImporterProvider);
    final PokedexSpeciesMetadataSaver resolvedMetadataSaver =
        metadataSaver ?? ref.watch(pokedexSpeciesMetadataSaverProvider);
    final PokedexSpeciesFormsClassificationSaver
        resolvedFormsClassificationSaver = formsClassificationSaver ??
            ref.watch(pokedexSpeciesFormsClassificationSaverProvider);
    final PokedexSpeciesLearnsetSaver resolvedLearnsetSaver =
        learnsetSaver ?? ref.watch(pokedexSpeciesLearnsetSaverProvider);
    final PokedexSpeciesEvolutionSaver resolvedEvolutionSaver =
        evolutionSaver ?? ref.watch(pokedexSpeciesEvolutionSaverProvider);
    final PokedexSpeciesMediaSaver resolvedMediaSaver =
        mediaSaver ?? ref.watch(pokedexSpeciesMediaSaverProvider);

    return _PokedexWorkspaceBody(
      projectRootPath: projectRootPath,
      loader: resolvedLoader,
      detailLoader: resolvedDetailLoader,
      importPreviewer: resolvedImportPreviewer,
      importer: resolvedImporter,
      externalImportPreviewer: resolvedExternalImportPreviewer,
      externalImporter: resolvedExternalImporter,
      pickJsonImportFile: pickJsonImportFile,
      metadataSaver: resolvedMetadataSaver,
      formsClassificationSaver: resolvedFormsClassificationSaver,
      learnsetSaver: resolvedLearnsetSaver,
      evolutionSaver: resolvedEvolutionSaver,
      mediaSaver: resolvedMediaSaver,
    );
  }
}

class _PokedexWorkspaceBody extends StatefulWidget {
  const _PokedexWorkspaceBody({
    required this.projectRootPath,
    required this.loader,
    required this.detailLoader,
    required this.importPreviewer,
    required this.importer,
    required this.externalImportPreviewer,
    required this.externalImporter,
    required this.pickJsonImportFile,
    required this.metadataSaver,
    required this.formsClassificationSaver,
    required this.learnsetSaver,
    required this.evolutionSaver,
    required this.mediaSaver,
  });

  final String? projectRootPath;
  final PokedexEntryLoader loader;
  final PokedexSpeciesDetailLoader detailLoader;
  final PokedexImportPreviewer importPreviewer;
  final PokedexImporter importer;
  final PokedexExternalImportPreviewer externalImportPreviewer;
  final PokedexExternalImporter externalImporter;
  final Future<String?> Function()? pickJsonImportFile;
  final PokedexSpeciesMetadataSaver metadataSaver;
  final PokedexSpeciesFormsClassificationSaver formsClassificationSaver;
  final PokedexSpeciesLearnsetSaver learnsetSaver;
  final PokedexSpeciesEvolutionSaver evolutionSaver;
  final PokedexSpeciesMediaSaver mediaSaver;

  @override
  State<_PokedexWorkspaceBody> createState() => _PokedexWorkspaceBodyState();
}
