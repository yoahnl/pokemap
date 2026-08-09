/// Workspace central actuellement affiché dans l'éditeur.
///
/// Ce type reste simple et orienté UI/session. Le déplacer hors de
/// `editor_state.dart` réduit le bruit du fichier racine et prépare une
/// décomposition plus propre des slices d'état dans les prochains lots.
enum EditorWorkspaceMode {
  map,
  tileset,
  encounter,

  // Workspace Pokédex minimal branché dans l'éditeur.
  //
  // Intention produit:
  // - rendre visible une vraie entree Pokédex dans l'editeur ;
  // - ouvrir un workspace central dedie ;
  // - permettre d'afficher une liste simple des especes importees.
  //
  // Important:
  // ce mode reste volontairement limite :
  // - pas de recherche ;
  // - pas de filtres ;
  // - pas de fiche detail ;
  // - pas d'edition.
  pokedex,

  // Workspaces narratifs centraux.
  //
  // Intention produit (non négociable):
  // - ces surfaces vivent dans l'îlot central, comme des workspaces de
  //   premier plan (pas comme des "petits panneaux" latéraux).
  // - la colonne gauche sert à naviguer/ouvrir.
  // - la colonne droite sert à inspecter le contexte sélectionné.
  narrativeOverview,
  globalStory,
  scenes,
  events,
  step,
  cutscene,

  /// Studio de conversation (dialogues `.yarn` en blocs visuels).
  dialogue,

  /// Manager no-code des Facts authorés.
  facts,

  /// Shop Builder no-code et états conditionnels des boutiques.
  shops,

  /// Manager no-code des règles visibles du monde.
  worldRules,

  /// Verdict global de jouabilité narrative et Map Events View.
  narrativeValidator,

  /// Studio natif unifié pour terrains, chemins et surfaces forestières.
  smartTilesStudio,

  /// Shell Environment Studio V0 (Lot Environment-9).
  ///
  /// Surface centrale read-only : résumé des presets Environment et
  /// diagnostics agrégés (`map_core`), sans édition ni génération.
  environmentStudio,

  /// Point d'entrée central du Personalization Studio.
  ///
  /// La Phase 0 expose le profil de présentation du projet en lecture seule.
  /// Les éditeurs et le save flow restent hors de ce contrat initial.
  personalizationStudio,

  /// Studio no-code des blueprints de bordure réutilisables.
  ///
  /// Ce workspace ne dessine pas sur une carte : il assemble des assets,
  /// leurs rôles et des règles déterministes, puis publie une révision
  /// immuable consommée ensuite par World Maps.
  borderStudio,
}
