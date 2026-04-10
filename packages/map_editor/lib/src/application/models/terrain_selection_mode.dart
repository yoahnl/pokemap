/// Mode de sélection courant pour les outils terrain/path.
///
/// Cette notion est utilisée à la fois par l'orchestration applicative
/// (coordination des presets) et par l'état éditeur/UI.
/// Elle vit donc dans `application/models` pour éviter qu'un service
/// applicatif dépende de `features/editor/state`.
enum TerrainSelectionMode {
  terrain,
  path,
}
