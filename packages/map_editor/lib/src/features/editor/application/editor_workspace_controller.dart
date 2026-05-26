import '../state/editor_state.dart';

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

  EditorState selectTrainerWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.trainer);
  }

  EditorState selectNarrativeOverviewWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.narrativeOverview);
  }

  EditorState selectGlobalStoryWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.globalStory);
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

  EditorState selectPathStudioWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.pathStudio);
  }

  EditorState selectEnvironmentStudioWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.environmentStudio);
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
