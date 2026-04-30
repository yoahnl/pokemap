/// Workspace central actuellement affiché dans l'éditeur.
///
/// Ce type reste simple et orienté UI/session. Le déplacer hors de
/// `editor_state.dart` réduit le bruit du fichier racine et prépare une
/// décomposition plus propre des slices d'état dans les prochains lots.
enum EditorWorkspaceMode {
  map,
  tileset,
  trainer,

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
  globalStory,
  step,
  cutscene,

  /// Studio de conversation (dialogues `.yarn` en blocs visuels).
  dialogue,

  /// Shell Path Studio V0.
  ///
  /// Ce mode expose une surface read-only pour les `ProjectPathPatternPreset` :
  /// liste, recherche, sélection, diagnostics et inspecteur. Il ne branche ni
  /// painter, ni save flow, ni éditeur réel du motif.
  pathStudio,
}
