import '../state/editor_state.dart';
import '../../smart_tiles_studio/application/smart_tile_studio_launch_context.dart';

/// Routeur pur des workspaces centraux de l'éditeur.
///
/// Pourquoi cette classe existe :
/// - `EditorNotifier` n'a pas besoin de porter lui-même tous les changements
///   de mode "simples" ;
/// - ces transitions ne lisent ni le disque ni Riverpod ;
/// - cela prépare un notifier plus fin, sans recréer un second store.
///
/// Frontière volontaire :
/// - on ne gère ici que les bascules de workspace triviales ;
/// - `selectTilesetWorkspace` reste dans le notifier, car il valide un id et
///   réinitialise un contexte spécifique tileset.
class EditorWorkspaceController {
  const EditorWorkspaceController();

  EditorState selectMapWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.map);
  }

  EditorState selectPokedexWorkspace(EditorState current) {
    return _openWorkspace(
      current.copyWith(
        pokemonCatalogSection: PokemonCatalogSection.pokedex,
      ),
      EditorWorkspaceMode.pokedex,
    );
  }

  EditorState selectPokemonCatalogSection(
    EditorState current,
    PokemonCatalogSection section,
  ) {
    return _openWorkspace(
      current.copyWith(pokemonCatalogSection: section),
      EditorWorkspaceMode.pokedex,
    );
  }

  EditorState selectEncounterWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.encounter);
  }

  EditorState selectEncounterStudioSection(
    EditorState current,
    EncounterStudioSection section,
  ) {
    return _openWorkspace(
      current.copyWith(encounterStudioSection: section),
      EditorWorkspaceMode.encounter,
    );
  }

  EditorState selectTrainerWorkspace(EditorState current) {
    return selectEncounterStudioSection(
      current,
      EncounterStudioSection.trainers,
    );
  }

  EditorState selectWildEncounterWorkspace(EditorState current) {
    return selectEncounterStudioSection(
      current,
      EncounterStudioSection.wildEncounters,
    );
  }

  EditorState selectWildEncounterTableWorkspace(
    EditorState current,
    String tableId,
  ) {
    return selectEncounterStudioSection(
      current.copyWith(encounterStudioTableId: tableId),
      EncounterStudioSection.wildEncounters,
    );
  }

  EditorState selectNarrativeOverviewWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.narrativeOverview);
  }

  EditorState selectGlobalStoryWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.globalStory);
  }

  EditorState selectScenesWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.scenes);
  }

  EditorState selectEventsWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.events);
  }

  EditorState selectStepWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.step);
  }

  EditorState selectCutsceneWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.cutscene);
  }

  EditorState selectDialogueWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.dialogue);
  }

  EditorState selectFactsWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.facts);
  }

  EditorState selectShopsWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.shops);
  }

  EditorState selectWorldRulesWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.worldRules);
  }

  EditorState selectNarrativeValidatorWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.narrativeValidator);
  }

  EditorState selectSmartTilesStudioWorkspace(EditorState current) {
    final activeMap = current.activeMap;
    return _openWorkspace(
      current.copyWith(
        smartTilesStudioLaunchContext: activeMap == null
            ? const SmartTilesStudioLaunchContext.library()
            : SmartTilesStudioLaunchContext.map(mapId: activeMap.id),
      ),
      EditorWorkspaceMode.smartTilesStudio,
    );
  }

  EditorState selectSmartTilesStudioLibraryWorkspace(EditorState current) {
    return _openWorkspace(
      current.copyWith(
        smartTilesStudioLaunchContext:
            const SmartTilesStudioLaunchContext.library(),
      ),
      EditorWorkspaceMode.smartTilesStudio,
    );
  }

  EditorState selectEnvironmentStudioWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.environmentStudio);
  }

  EditorState selectPersonalizationStudioWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.personalizationStudio);
  }

  EditorState selectBorderStudioWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.borderStudio);
  }

  /// Normalise les transitions de workspace :
  /// - on conserve tout l'état métier courant ;
  /// - on bascule seulement la surface centrale active ;
  /// - on efface l'erreur courante pour éviter de laisser un message obsolète
  ///   d'un autre workflow polluer le nouvel espace.
  EditorState _openWorkspace(
    EditorState current,
    EditorWorkspaceMode workspaceMode,
  ) {
    return current
        .copyWithProjectSession(
          current.projectSession.copyWith(workspaceMode: workspaceMode),
        )
        .copyWithDocumentStatus(
          current.documentStatus.copyWith(errorMessage: null),
        );
  }
}
