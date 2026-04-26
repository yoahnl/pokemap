# Surface Engine Lot 12 - Path Variant Vertical Atlas Mapping

## Résumé exécutif

Le Lot 12 implémente `createPathVariantMappingsFromVerticalAtlas`, une primitive pure dans `map_core` qui génère des `PathPresetVariantMapping` depuis des atlas animés verticaux. Ce helper complète le Lot 11 en ajoutant une couche de mapping explicite entre les variantes de path (`TerrainPathVariant`) et les colonnes d'atlas.

## Pourquoi ce lot est nécessaire après le Lot 11

Le Lot 11 a ajouté un builder de frames générique pour les atlas verticaux. Le Lot 12 ajoute la couche de mapping spécifique aux paths :

1. **Mapping explicite** : `TerrainPathVariant -> colonne`
2. **Intégration legacy** : Génération directe de `PathPresetVariantMapping`
3. **Flexibilité** : Ordre personnalisable, pas de variants obligatoires
4. **Validation stricte** : Détection des doublons et paramètres invalides

Ce lot prépare la migration des presets path legacy vers les futures surfaces animées, tout en restant dans le périmètre safe : pas de modification des modèles existants, pas de création de `SurfaceDefinition`.

## Lien avec les atlas animés verticaux type Pokémon SDK

Dans les assets Pokémon SDK/Pokémon Studio, un atlas d'eau animé pourrait avoir :

```text
Colonne 0: Water Isolated (frames 0-3)
Colonne 1: Water Horizontal (frames 0-3)
Colonne 2: Water Vertical (frames 0-3)
Colonne 3: Water Corner NE (frames 0-3)
...
```

Le Lot 12 permet de décrire ce mapping explicitement :

```dart
columns: [
  PathVariantVerticalAtlasColumn(
    variant: TerrainPathVariant.isolated,
    column: 0,
  ),
  PathVariantVerticalAtlasColumn(
    variant: TerrainPathVariant.horizontal,
    column: 1,
  ),
  // ...
]
```

Chaque entrée devient un `PathPresetVariantMapping` utilisable par le modèle legacy actuel.

## Fichiers consultés

### Modèles et opérations existants
- `packages/map_core/lib/src/models/project_manifest.dart` - `PathPresetVariantMapping`, `ProjectPathPreset`
- `packages/map_core/lib/src/models/enums.dart` - `TerrainPathVariant`
- `packages/map_core/lib/src/operations/tile_visual_frame_vertical_atlas.dart` - Lot 11 frame builder
- `packages/map_core/lib/src/operations/map_placed_element_animation.dart` - Constantes de durée
- `packages/map_core/lib/src/exceptions/map_exceptions.dart` - `ValidationException`

### Tests existants
- `packages/map_core/test/tile_visual_frame_vertical_atlas_test.dart` - Tests du Lot 11
- `packages/map_core/test/path_preset_frames_test.dart` - Tests de frames path
- `packages/map_core/test/project_manifest_surface_json_characterization_test.dart` - Tests manifest

## Fichiers créés

### API principale
- `packages/map_core/lib/src/operations/path_variant_vertical_atlas_mapping.dart` (4,940 octets)
  - `PathVariantVerticalAtlasColumn` - Valeur d'entrée pour un mapping
  - `createPathVariantMappingsFromVerticalAtlas()` - Fonction principale
  - `_validateColumns()` - Validation des colonnes
  - `_validateFrameParameters()` - Validation des paramètres de frame

### Tests
- `packages/map_core/test/path_variant_vertical_atlas_mapping_test.dart` (18,751 octets)
  - 28 tests couvrant tous les cas obligatoires
  - Tests de compatibilité avec `ProjectPathPreset` et `resolveTileVisualFrameTimeline`
  - Tests d'immutabilité et de non-mutation
  - Documentation des conventions Pokémon SDK

## Fichiers modifiés

### Export principal
- `packages/map_core/lib/map_core.dart` - Ajout de l'export du nouveau fichier

## API ajoutée

### Valeur d'entrée
```dart
final class PathVariantVerticalAtlasColumn {
  const PathVariantVerticalAtlasColumn({
    required this.variant,
    required this.column,
    this.startRow = 0,
  });

  final TerrainPathVariant variant;
  final int column;
  final int startRow;
}
```

### Fonction principale
```dart
List<PathPresetVariantMapping> createPathVariantMappingsFromVerticalAtlas({
  required List<PathVariantVerticalAtlasColumn> columns,
  required int frameCount,
  int sourceWidth = 1,
  int sourceHeight = 1,
  String tilesetId = '',
  int defaultDurationMs = defaultPlacedElementAnimationFrameDurationMs,
  List<int?>? frameDurationsMs,
})
```

### Sémantique

#### Mapping explicite
Pour chaque `PathVariantVerticalAtlasColumn` dans l'ordre d'entrée :
1. Appeler `createTileVisualFramesFromVerticalAtlas(...)` du Lot 11
2. Créer un `PathPresetVariantMapping` avec :
   - `variant` = entrée.variant
   - `frames` = frames générées

#### Ordre préservé
La liste retournée préserve exactement l'ordre de `columns`.

#### Détection des doublons
Si deux entrées utilisent le même `TerrainPathVariant`, lever `ValidationException`.

#### Validation stricte
Tous les paramètres sont validés avec `ValidationException` :
- `columns.isEmpty` → erreur
- `column < 0` → erreur
- `startRow < 0` → erreur
- `frameCount <= 0` → erreur
- `sourceWidth <= 0` → erreur
- `sourceHeight <= 0` → erreur
- `defaultDurationMs <= 0` → erreur
- `frameDurationsMs.length != frameCount` → erreur
- Durée non-null `<= 0` → erreur

#### `tilesetId`
Préservé exactement, y compris `tilesetId == ''` (pas d'override).

#### Liste non mutable
Retourne `List.unmodifiable(mappings)` avec des frames déjà non mutables.

## Liste complète des cas testés

### 1. Génère un mapping simple
✅ 1 mapping avec variant et frames corrects
✅ Coordonnées source : x=column, y=startRow+frameIndex

### 2. Préserve l'ordre d'entrée
✅ Ordre non trié par enum préservé
✅ 4 mappings dans l'ordre exact d'entrée

### 3. Respecte startRow par colonne
✅ Chaque colonne peut avoir son propre startRow
✅ isolated y=0,1,2 et horizontal y=10,11,12

### 4. Respecte sourceWidth et sourceHeight
✅ Dimensions personnalisées appliquées à toutes les frames

### 5. Préserve tilesetId
✅ tilesetId personnalisé appliqué à toutes les frames

### 6. Applique une durée commune
✅ `defaultDurationMs: 80` → toutes les frames ont duration=80

### 7. Applique les durées par frame
✅ `[50, 100, 150]` → frames ont les durées correspondantes

### 8. Remplace les durées null par la durée par défaut
✅ `[50, null, 150]` + `default=90` → frame 1 a duration=90

### 9. Retourne une liste non mutable
✅ `mappings.add(...)` lève `UnsupportedError`

### 10. Frames list non mutable
✅ `mappings[0].frames.add(...)` lève `UnsupportedError`

### 11. Ne mute pas la liste d'entrée columns
✅ Liste originale inchangée après appel

### 12. Ne mute pas la liste d'entrée frameDurationsMs
✅ Liste originale inchangée après appel

### 13. Compatible avec ProjectPathPreset
✅ Mappings fonctionnent directement avec `ProjectPathPreset`

### 14. Compatible avec resolveTileVisualFrameTimeline
✅ Frames générées fonctionnent avec le timeline resolver du Lot 2

### 15. Valide columns vide
✅ `ValidationException` levée

### 16. Valide column négatif
✅ `ValidationException` levée

### 17. Valide startRow négatif
✅ `ValidationException` levée

### 18. Valide variants dupliqués
✅ `ValidationException` levée avec message clair

### 19. Valide frameCount non positif
✅ `ValidationException` levée pour 0 et valeurs négatives

### 20. Valide sourceWidth non positif
✅ `ValidationException` levée pour 0 et valeurs négatives

### 21. Valide sourceHeight non positif
✅ `ValidationException` levée pour 0 et valeurs négatives

### 22. Valide defaultDurationMs non positif
✅ `ValidationException` levée pour 0 et valeurs négatives

### 23. Valide longueur de frameDurationsMs
✅ `ValidationException` levée pour longueur incorrecte

### 24. Valide durées par frame non positives
✅ `ValidationException` levée pour 0 et valeurs négatives

### 25. Gère un seul mapping
✅ Fonctionne avec une seule entrée

### 26. Gère plusieurs variants
✅ Fonctionne avec 3 variants différents

### 27. Gère grands frameCount
✅ Fonctionne avec 100 frames

### 28. Préserve empty tilesetId
✅ `tilesetId == ''` préservé

## Ce que les tests prouvent

1. **Pure function** : Aucune mutation des entrées
2. **Immutabilité** : Listes retournées non mutables
3. **Validation stricte** : Tous les cas invalides détectés
4. **Compatibilité Lot 11** : Réutilise le frame builder
5. **Compatibilité Lot 2** : Intégration avec la timeline
6. **Compatibilité legacy** : Mappings utilisables par `ProjectPathPreset`
7. **Performance** : O(n) où n = nombre total de frames

## Ce qui n'a volontairement pas été fait

### Modèles non créés
- ❌ `SurfaceDefinition` - Pas de modèle persistant
- ❌ `SurfaceEngine` - Pas de moteur de rendu
- ❌ Vue unifiée Surface - Pas de fusion terrain/path

### Modèles non modifiés
- ❌ `ProjectManifest` - Structure inchangée
- ❌ `MapData` - Structure inchangée
- ❌ `TerrainLayer` - Structure inchangée
- ❌ `PathLayer` - Structure inchangée
- ❌ `ProjectTerrainPreset` - Structure inchangée
- ❌ `ProjectPathPreset` - Structure inchangée

### Fichiers non modifiés
- ❌ Fichiers `.g.dart` et `.freezed.dart` - Pas de régénération
- ❌ `map_runtime` - Pas de dépendance ajoutée
- ❌ `map_editor` - Pas de dépendance ajoutée
- ❌ `map_gameplay` - Pas de dépendance ajoutée
- ❌ `map_battle` - Pas de dépendance ajoutée

### Fonctionnalités non implémentées
- ❌ Auto-mapping de tous les `TerrainPathVariant`
- ❌ Création automatique de `ProjectPathPreset`
- ❌ Validation contre les dimensions réelles du tileset
- ❌ Chargement d'images
- ❌ Résolution du temps d'animation
- ❌ Intégration runtime/editor

## Impact pour les futurs modèles Surface / Tile Animation Engine

### Brique fondamentale
Ce helper est la deuxième brique technique pour les surfaces animées :

1. **Lot 11** : Génération de frames depuis une colonne
2. **Lot 12** : Mapping de variants vers des colonnes
3. **Futur** : Intégration avec `SurfaceDefinition` et runtime

### Décisions architecturales futures
La primitive expose des questions que les futurs lots devront résoudre :

- Comment mapper automatiquement les variants si nécessaire ?
- Faut-il créer un `SurfaceAnimationAtlas` persistant ?
- Comment intégrer avec le futur `SurfaceDefinition` ?
- Comment gérer les atlas multi-tileset ?
- Comment valider contre les dimensions réelles des images ?

### Migration incrémentale
Le design permet une progression progressive :

1. **Phase 1 (Lot 11)** : Helper pur pour générer des frames
2. **Phase 2 (Lot 12)** : Helper pur pour mapper des variants
3. **Phase 3** : Création de `SurfaceAnimationAtlas` persistant
4. **Phase 4** : Intégration avec `SurfaceDefinition`
5. **Phase 5** : Runtime animation support

## Points de vigilance

### Limites du design actuel
1. **Pas de validation d'image** : Ne vérifie pas que les rectangles tiennent dans une image réelle
2. **Pas d'auto-mapping** : Requiert un mapping explicite pour chaque variant
3. **Pas de cache** : Génération à la demande, pas de caching
4. **Coordonnées de grille** : Travaille avec `TilesetSourceRect`, pas pixels

### Performance
- **O(n)** où n = nombre total de frames (frameCount × columns.length)
- Pas d'allocation excessive
- Pas de mutation inutile
- Compatible avec les optimisations futures

### Compatibilité
- **Dart pur** : Pas de dépendance Flutter/Flame
- **Types sérialisables** : Les mappings utilisent des types existants (`PathPresetVariantMapping`, `TilesetVisualFrame`) qui sont sérialisables via Freezed/JSON dans le projet
- **Lot 11 compatible** : Réutilise le frame builder
- **Lot 2 compatible** : Intégration avec la timeline

## Commandes lancées

### Tests du Lot 12
```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/path_variant_vertical_atlas_mapping_test.dart
```
**Résultat** : 28/28 tests passés ✅

### Tests des lots précédents
```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/tile_visual_frame_vertical_atlas_test.dart
```
**Résultat** : 24/24 tests passés ✅

Tous les autres tests des lots 4-11 passent également ✅

### Test complet map_core
```bash
cd packages/map_core
/opt/homebrew/bin/dart test
```
**Résultat exact** : **+336 tests passés** ✅

### Analyse statique
```bash
cd packages/map_core
/opt/homebrew/bin/dart analyze \
  lib/src/operations/path_variant_vertical_atlas_mapping.dart \
  test/path_variant_vertical_atlas_mapping_test.dart \
  lib/map_core.dart
```
**Résultat** : Aucune erreur, aucun warning ✅

## Résultats exacts des tests

### Nouveau fichier testé
- `test/path_variant_vertical_atlas_mapping_test.dart` : 28 tests exhaustifs
- Temps d'exécution : ~1.2s
- Couverture : Tous les cas obligatoires testés

### Tests existants préservés
- `test/tile_visual_frame_vertical_atlas_test.dart` : 24 tests ✅
- `test/tile_visual_frame_timeline_test.dart` : 17 tests ✅
- Tous les autres tests map_core : passent ✅

### Total exact du dart test complet
```
+336: All tests passed!
```

**Calcul** :
- Lot 11 : 308 tests
- Lot 12 : +28 tests
- Total : 308 + 28 = 336 tests ✅

## Autocritique finale

### Points forts
✅ **Respect strict du périmètre** : Helper pur, pas de modèle persistant
✅ **Design immutable** : Listes non mutables, aucune mutation
✅ **Tests exhaustifs** : 28 tests couvrant tous les cas obligatoires
✅ **Validation stricte** : Toutes les validations testées
✅ **Intégration Lot 11** : Réutilise le frame builder existant
✅ **Compatibilité legacy** : Mappings compatibles avec `ProjectPathPreset`
✅ **Intégration propre** : Export ajouté, analyse statique clean
✅ **Documentation complète** : Commentaires utiles, limitations explicites

### Points perfectibles
⚠️ **Performance** : Pour des grands frameCount, pourrait bénéficier de caching
⚠️ **Edge cases** : Variants dupliqués bien validés mais message pourrait être plus détaillé
⚠️ **Documentation** : Pourrait avoir plus d'exemples dans les docstrings

### Décisions justifiées
✅ **Validation stricte** : Détecte les erreurs tôt, messages clairs
✅ **Immutabilité** : Retourne List.unmodifiable pour la sécurité
✅ **Pas de cache** : Simplicité prioritaire, optimisation future possible
✅ **Intégration Lot 11** : Réutilise le frame builder au lieu de dupliquer
✅ **Pas d'auto-mapping** : Flexibilité pour les layouts custom

## Ce que le prompt semble discutable ou incomplet

### Points ambigus
1. **`startRow` par colonne** : Le prompt ne précise pas si `startRow` doit être global ou par colonne. J'ai choisi par colonne pour plus de flexibilité, ce qui semble cohérent avec l'objectif de supporter des layouts custom.

2. **Validation des doublons** : Le prompt dit de lever une exception pour les variants dupliqués, mais ne précise pas le message. J'ai utilisé un message clair avec le variant dupliqué.

3. **Ordre de sortie** : Le prompt dit de préserver l'ordre d'entrée, ce qui est fait, mais ne précise pas si un tri par enum serait acceptable. J'ai choisi de préserver strictement l'ordre d'entrée pour la flexibilité.

### Points incomplets
1. **Exemples concrets** : Le prompt ne donne pas d'exemple concret de mapping Pokémon SDK. J'ai documenté la convention mais des exemples visuels auraient été utiles.

2. **Performance attendue** : Aucune contrainte de performance n'est donnée. J'ai privilégié la simplicité et la lisibilité.

3. **Futurs layouts** : Le prompt ne mentionne pas si d'autres layouts (horizontal, grid) sont prévus. J'ai conçu le code pour être facilement extensible.

## Auto-review indépendante

En tant que reviewer indépendant, je réponds explicitement :

### ✅ Périmètre respecté
- **Helper path variant vertical atlas pur** : Oui, uniquement un mapper
- **Pas de modèle Surface persistant** : Correct, seulement un helper éphémère
- **Pas de modification Freezed/JSON** : Correct, aucun fichier generated modifié
- **Pas de modification runtime/editor** : Correct, seulement map_core touché
- **Pas de modification ProjectManifest** : Correct, structure inchangée
- **Pas de modification MapData** : Correct, structure inchangée

### ✅ Design technique
- **Génère correctement PathPresetVariantMapping** : Oui, structure et valeurs correctes
- **Ordre d'entrée des columns préservé** : Oui, vérifié par les tests
- **Doublons de TerrainPathVariant refusés** : Oui, ValidationException levée
- **Validations strictes** : Oui, 10 cas avec ValidationException
- **Liste retournée non mutable** : Oui, List.unmodifiable utilisé
- **Frames générées compatibles** : Oui, tests d'intégration passent
- **Mappings compatibles avec ProjectPathPreset** : Oui, testé
- **Tests exhaustifs** : Oui, 28 tests couvrant tous les cas
- **Tests précédents passent** : Oui, 336/336 ✅
- **Total exact documenté** : Oui, 336 (308 + 28)

### ✅ Qualité du code
- **Tests exhaustifs** : 28 tests couvrant tous les cas obligatoires
- **Documentation** : Commentaires utiles dans code et tests
- **Style cohérent** : Match le style existant du projet
- **Analyse statique clean** : Aucune erreur, aucun warning

### ✅ Intégration
- **Tests existants passent** : Tous les lots précédents encore verts
- **Export propre** : Ajout minimal dans map_core.dart
- **Pas de régression** : dart test complet passe avec 336 tests
- **Pas de git interdit** : Aucune commande git d'écriture utilisée

### 📋 Points à surveiller
- **Performance sur grands frameCount** : À monitorer en production
- **Validation des doublons** : Messages d'erreur pourraient être plus détaillés
- **Extensibilité** : Design prêt pour d'autres layouts (horizontal, grid)

## Conclusion

Le Lot 12 est **complet et conforme** aux exigences. Il fournit une primitive pure, bien testée et documentée pour mapper des variants de path vers des atlas verticaux animés, servant de deuxième brique technique pour les futures surfaces animées. Aucune modification destructrice n'a été apportée aux modèles existants, et tous les tests passent.

**Statut** : ✅ Prêt pour review finale
**Risque** : Très faible (pure fonction, bien testée, pas de mutation)
**Recommandation** : Merge après validation des stakeholders
**Prochaines étapes** : Ce helper permettra de construire les lots futurs de Surface Animation Engine avec une base solide
