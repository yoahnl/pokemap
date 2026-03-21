# RPG Map Editor - Architecture & Roadmap

## Architecture (Clean Architecture)

Le projet est structuré en monorepo avec 3 packages principaux :

### 1. `map_core` (Pure Dart)
- **Domain Models**: Entités immuables (Freezed) représentant les maps, tilesets, entités, warps, triggers.
- **Serialization**: Gestion du format JSON central.
- **Logic**: Validation métier et calculs géométriques sur la grille.
- **Indépendance**: Aucune dépendance à Flutter ou Flame.

### 2. `map_editor` (Flutter Desktop)
- **Presentation**: UI modulaire (Riverpod) avec shell desktop (Toolbar, Explorer, Canvas, Inspector).
- **Application**: Use cases pour l'orchestration des actions (Save/Load Project, Edit Map).
- **Infrastructure**: Adaptateurs concrets pour le filesystem et la persistance.

### 3. `map_runtime` (Dart/Flame)
- **Component**: `MapRuntime` destiné à être intégré dans un jeu Flame.
- **Responsabilité**: Lecture du format `map_core` et rendu/physique.

## Prochaines étapes suggérées

1. **Édition de Tiles**:
   - Implémenter le rendu des tiles dans `MapCanvasPanel` via un `CustomPainter`.
   - Créer un `TilesetPalette` pour sélectionner les tiles.
   - Ajouter la logique de "peinture" dans `EditorNotifier`.

2. **Système Undo/Redo**:
   - Intégrer un historique d'états dans `EditorNotifier` ou utiliser un package dédié.

3. **Collisions & Entités**:
   - Ajouter des outils de dessin de rectangles de collision.
   - Créer des formulaires dynamiques dans `PropertyInspectorPanel` selon le type d'entité sélectionnée.

4. **Runtime**:
   - Développer le `MapRuntime` pour qu'il puisse instancier des `SpriteComponent` Flame à partir des données de `map_core`.

## Commandes utiles

- Générer le code : `dart run build_runner build --delete-conflicting-outputs` (dans chaque package)
- Lancer l'éditeur : `cd packages/map_editor && flutter run -d macos` (ou windows/linux)
