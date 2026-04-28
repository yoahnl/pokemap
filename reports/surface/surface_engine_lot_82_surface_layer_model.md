# Lot 82 — SurfaceLayer Model V0

## Résumé exécutif

Le Lot 82 ajoute le modèle minimal de placement Surface dans `map_core`.

Décision appliquée depuis le Lot 81 :

- un nouveau case `MapLayer.surface` existe ;
- les placements sont sparse ;
- chaque placement contient uniquement `x`, `y`, `surfacePresetId` ;
- aucun rôle autotile calculé n’est persisté ;
- aucun `animationId`, `atlasId` ou `tilesetId` n’est stocké dans la cellule ;
- `ProjectManifest` et les modèles `surface.dart` / `surface_catalog.dart` ne sont pas modifiés.

Le lot reste limité au modèle map `map_core`, à la validation minimale associée, aux generated Freezed/JSON attendus et aux tests de caractérisation du nouveau modèle.

## Périmètre

Inclus :

- ajout de `SurfaceCellPlacement` dans `packages/map_core/lib/src/models/map_layer.dart` ;
- ajout de `MapLayer.surface(...)` ;
- génération `map_layer.freezed.dart` et `map_layer.g.dart` ;
- validation minimale dans `MapValidator` ;
- adaptation minimale des opérations `map_layers.dart` et `map_resize.dart` parce que le nouveau case Freezed rend certains dispatchs exhaustifs ;
- tests ciblés dans `packages/map_core/test/surface_layer_model_test.dart`.

Exclus :

- pas de painter Surface ;
- pas de palette Surface ;
- pas de resolver autotile ;
- pas de preview éditeur ;
- pas de renderer runtime Flame ;
- pas de migration legacy ;
- pas de diagnostic de placement contre `ProjectManifest.surfaceCatalog`.

## Gate 0 — Status initial avant modification

Commandes exécutées avant toute modification :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
```

Sortie complète :

```text
/Users/karim/Project/pokemonProject
main
9645a04b docs(surface): decide surface placement model
19c75e77 feat(map_editor): ajouter preset vertical atlas et golden slice e2e
ccdf1094 fix(map_editor): lisibilité et ergonomie sélecteur colonne aperçu atlas
33d776aa feat(map_editor): Lot 78 — animations Surface depuis atlas vertical
1a92a64e feat(map_editor): Surface Studio Lot 77 — plan génération animations atlas vertical
021abf5f feat(map_editor): Surface Studio Lots 75–76 — mapping colonnes + preview animation
cd9bf788 feat(map_editor): Surface Studio Lot 74 — assistant atlas vertical + preview grand format
13569f30 feat(map_editor): Surface Studio Lot 73 — grille sur aperçu image source
24467c67 feat(map_editor): Surface Studio Lot 72 — aperçu image source (résolution disque)
fcdc064d feat(map_editor): Surface Studio Lot 71 — aperçu grille atlas (preview V0)
```

Notes :

- `git status --short --untracked-files=all` : aucune sortie.
- `git diff --stat` : aucune sortie.
- Status initial vide.
- Aucun changement préexistant détecté.

## Audit initial

Fichiers audités :

- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/map_layer.freezed.dart`
- `packages/map_core/lib/src/models/map_layer.g.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_core/lib/src/operations/map_layers.dart`
- `packages/map_core/lib/src/operations/map_resize.dart`
- `packages/map_core/test/map_core_test.dart`
- `packages/map_core/test/path_animation_triggers_test.dart`
- recherches ciblées dans `packages/map_core/test/**`

Constats :

- `MapLayer` est une union Freezed avec `runtimeType`.
- Les cases existants sont `tile`, `collision`, `terrain`, `path`, `object`.
- `MapData.layers` contient `List<MapLayer>` et round-trip via `MapData.toJson()` / `MapData.fromJson()`.
- `MapValidator` valide déjà les propriétés communes de layer : `id`, `name`, `opacity`.
- `TileLayer`, `CollisionLayer`, `TerrainLayer` et `PathLayer` sont des grilles denses validées contre `width * height`.
- `ObjectLayer` n’a pas de grille.
- `PathLayer` possède un `presetId` au niveau layer ; ce pattern n’est pas repris pour Surface afin de conserver un modèle par placement.
- `MapLayerKind` existe mais n’a pas été étendu dans ce lot pour ne pas brancher la création de layer Surface dans les opérations/UI existantes.

## Modèle SurfaceCellPlacement

Ajout :

```dart
@freezed
class SurfaceCellPlacement with _$SurfaceCellPlacement {
  const factory SurfaceCellPlacement({
    required int x,
    required int y,
    required String surfacePresetId,
  }) = _SurfaceCellPlacement;

  factory SurfaceCellPlacement.fromJson(Map<String, dynamic> json) =>
      _$SurfaceCellPlacementFromJson(json);
}
```

Sémantique V0 :

- `x` et `y` sont des coordonnées de cellule dans la map ;
- `surfacePresetId` référence un `ProjectSurfacePreset` par id ;
- aucune référence directe à animation, atlas ou tileset ;
- aucun rôle autotile calculé ;
- aucune metadata gameplay.

Validation :

- les factories Freezed restent des value objects simples ;
- les règles structurelles liées à la map sont dans `MapValidator`, comme pour les layers existants.

## Modèle SurfaceLayer

Ajout du case :

```dart
@FreezedUnionValue('surface')
@JsonSerializable(explicitToJson: true)
const factory MapLayer.surface({
  required String id,
  required String name,
  @Default(true) bool isVisible,
  @Default(1.0) double opacity,
  @Default([]) List<SurfaceCellPlacement> placements,
  @Default(<String, String>{}) Map<String, String> properties,
}) = SurfaceLayer;
```

Sémantique V0 :

- `placements` est une liste sparse ;
- pas de grille complète ;
- pas de `surfacePresetId` au niveau layer ;
- pas de rôle autotile persisté ;
- `properties` suit le précédent de `PathLayer`, sans sémantique Surface spécifique en V0.

Pourquoi pas `surfacePresetId` au niveau layer :

- le modèle doit permettre des placements de presets différents ;
- le choix d’UI futur peut être plus restrictif, mais le modèle map ne doit pas être enfermé dans “un preset par layer” comme `PathLayer`.

## JSON / generated files

`build_runner` a été lancé uniquement dans `packages/map_core` :

```bash
dart run build_runner build --delete-conflicting-outputs
```

Sortie synthétique :

```text
W SDK language version 3.10.0 is newer than `analyzer` language version 3.9.0. Run `dart pub upgrade`.
W json_serializable on lib/src/models/element_collision_profile.dart:
  The version constraint "^4.8.1" on json_annotation allows versions before 4.9.0 which is not allowed.
Built with build_runner in 8s; wrote 12 outputs.
```

Fichiers generated modifiés et attendus :

- `packages/map_core/lib/src/models/map_layer.freezed.dart`
- `packages/map_core/lib/src/models/map_layer.g.dart`

Justification :

- `SurfaceCellPlacement` est un nouveau modèle Freezed/JSON ;
- `MapLayer.surface` est un nouveau case de l’union Freezed ;
- `runtimeType: surface` est généré par `map_layer.g.dart`.

Exemple JSON caractérisé :

```json
{
  "runtimeType": "surface",
  "id": "surface-main",
  "name": "Surfaces",
  "isVisible": true,
  "opacity": 1.0,
  "placements": [
    {
      "x": 4,
      "y": 8,
      "surfacePresetId": "water-surface"
    }
  ],
  "properties": {}
}
```

## Validation

`MapValidator` valide maintenant les `SurfaceLayer` :

- `x >= 0` ;
- `y >= 0` ;
- `x < map.size.width` ;
- `y < map.size.height` ;
- `surfacePresetId.trim().isNotEmpty` ;
- pas deux placements avec la même coordonnée dans un même `SurfaceLayer` ;
- clés de `properties` non vides ;
- `opacity` reste validé par la règle commune existante.

Non fait :

- pas de validation d’existence du `surfacePresetId` dans `ProjectManifest.surfaceCatalog` ;
- pas de validation des rôles Surface ;
- pas de validation des animations/atlas.

Ces validations appartiennent à un futur lot de diagnostics de placement.

## Implémentation

Changements manuels :

- ajout de `SurfaceCellPlacement` et `MapLayer.surface` ;
- ajout d’une branche `surface` dans `_copyLayer` pour conserver rename/visibility/opacity ;
- ajout d’une branche `surface` dans `resizeMapData` pour filtrer les placements qui sortent des nouvelles bornes ;
- extension interne de `_validateLayer` pour recevoir `mapWidth` et `mapHeight`.

Pourquoi `map_resize.dart` a été touché :

- l’ajout d’un case Freezed rend `layer.map(...)` exhaustif ;
- `resizeMapData` ne compilait plus sans branche `surface` ;
- le comportement minimal cohérent pour un stockage sparse est de conserver les placements encore dans les bornes et d’écarter ceux qui ne le sont plus.

## Fichiers créés

- `packages/map_core/test/surface_layer_model_test.dart`
- `reports/surface/surface_engine_lot_82_surface_layer_model.md`

## Fichiers modifiés

- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/map_layer.freezed.dart`
- `packages/map_core/lib/src/models/map_layer.g.dart`
- `packages/map_core/lib/src/operations/map_layers.dart`
- `packages/map_core/lib/src/operations/map_resize.dart`
- `packages/map_core/lib/src/validation/validators.dart`

## Fichiers supprimés

- Aucun.

## Tests lancés

### RED initial

Commande :

```bash
cd packages/map_core && dart test test/surface_layer_model_test.dart
```

Résultat attendu et obtenu avant production code :

```text
Failed to load "test/surface_layer_model_test.dart":
test/surface_layer_model_test.dart:9:25: Error: Method not found: 'SurfaceCellPlacement'.
test/surface_layer_model_test.dart:44:30: Error: Member not found: 'MapLayer.surface'.
test/surface_layer_model_test.dart:61:37: Error: 'SurfaceLayer' isn't a type.
Some tests failed.
```

### Test ciblé Lot 82

Commande :

```bash
cd packages/map_core && dart test test/surface_layer_model_test.dart
```

Ligne finale exacte :

```text
00:00 +16: All tests passed!
```

### Tests existants ciblés

Commande :

```bash
cd packages/map_core && dart test test/map_core_test.dart
```

Ligne finale exacte :

```text
00:00 +4: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/path_animation_triggers_test.dart
```

Ligne finale exacte :

```text
00:00 +6: All tests passed!
```

### Suite complète map_core

Commande :

```bash
cd packages/map_core && dart test
```

Ligne finale exacte :

```text
00:02 +1234: All tests passed!
```

## Analyse lancée

Commande demandée :

```bash
cd packages/map_core && dart analyze lib test
```

Sortie exacte :

```text
Analyzing lib, test...

   info - lib/src/models/enums.dart:34:3 - The constant name 'upper_floor' isn't a lowerCamelCase identifier. Try changing the name to follow the lowerCamelCase style. - constant_identifier_names
   info - lib/src/models/enums.dart:44:3 - The constant name 'sub_area' isn't a lowerCamelCase identifier. Try changing the name to follow the lowerCamelCase style. - constant_identifier_names

2 issues found.
```

Interprétation :

- l’analyse globale ne sort pas `No issues found!` à cause de deux infos dans `enums.dart` ;
- `enums.dart` n’est pas modifié par ce lot ;
- ces infos sont une dette préexistante au changement Lot 82 ;
- elles n’ont pas été corrigées pour respecter le périmètre et éviter une modification d’enum hors lot.

Analyse ciblée sur tous les fichiers Dart modifiés/créés manuellement :

```bash
cd packages/map_core && dart analyze \
  lib/src/models/map_layer.dart \
  lib/src/operations/map_layers.dart \
  lib/src/operations/map_resize.dart \
  lib/src/validation/validators.dart \
  test/surface_layer_model_test.dart
```

Sortie exacte :

```text
Analyzing map_layer.dart, map_layers.dart, map_resize.dart, validators.dart, surface_layer_model_test.dart...
No issues found!
```

## Résultats

- Le test Lot 82 ciblé passe.
- Les tests existants ciblés `map_core_test.dart` et `path_animation_triggers_test.dart` passent.
- La suite complète `map_core` passe avec `+1234`.
- L’analyse ciblée des fichiers modifiés est clean.
- L’analyse globale `lib test` révèle deux infos préexistantes dans `enums.dart`, non modifié.

## Evidence Pack

### Status initial complet

```text
/Users/karim/Project/pokemonProject
main
9645a04b docs(surface): decide surface placement model
19c75e77 feat(map_editor): ajouter preset vertical atlas et golden slice e2e
ccdf1094 fix(map_editor): lisibilité et ergonomie sélecteur colonne aperçu atlas
33d776aa feat(map_editor): Lot 78 — animations Surface depuis atlas vertical
1a92a64e feat(map_editor): Surface Studio Lot 77 — plan génération animations atlas vertical
021abf5f feat(map_editor): Surface Studio Lots 75–76 — mapping colonnes + preview animation
cd9bf788 feat(map_editor): Surface Studio Lot 74 — assistant atlas vertical + preview grand format
13569f30 feat(map_editor): Surface Studio Lot 73 — grille sur aperçu image source
24467c67 feat(map_editor): Surface Studio Lot 72 — aperçu image source (résolution disque)
fcdc064d feat(map_editor): Surface Studio Lot 71 — aperçu grille atlas (preview V0)
```

### Fichiers audités

- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/map_layer.freezed.dart`
- `packages/map_core/lib/src/models/map_layer.g.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_core/lib/src/operations/map_layers.dart`
- `packages/map_core/lib/src/operations/map_resize.dart`
- `packages/map_core/test/map_core_test.dart`
- `packages/map_core/test/path_animation_triggers_test.dart`

### Generated files modifiés

- `packages/map_core/lib/src/models/map_layer.freezed.dart`
- `packages/map_core/lib/src/models/map_layer.g.dart`

### Sorties clés

Tests :

```text
test/surface_layer_model_test.dart: 00:00 +16: All tests passed!
test/map_core_test.dart: 00:00 +4: All tests passed!
test/path_animation_triggers_test.dart: 00:00 +6: All tests passed!
dart test: 00:02 +1234: All tests passed!
```

Analyse :

```text
dart analyze lib test: 2 infos préexistantes dans lib/src/models/enums.dart.
dart analyze fichiers modifiés: No issues found!
```

## Git status final

Commandes Gate final exécutées :

```bash
git status --short --untracked-files=all
git diff --stat
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
```

Sortie `git status --short --untracked-files=all` :

```text
 M packages/map_core/lib/src/models/map_layer.dart
 M packages/map_core/lib/src/models/map_layer.freezed.dart
 M packages/map_core/lib/src/models/map_layer.g.dart
 M packages/map_core/lib/src/operations/map_layers.dart
 M packages/map_core/lib/src/operations/map_resize.dart
 M packages/map_core/lib/src/validation/validators.dart
?? packages/map_core/test/surface_layer_model_test.dart
?? reports/surface/surface_engine_lot_82_surface_layer_model.md
```

Sortie `git diff --stat` :

```text
 packages/map_core/lib/src/models/map_layer.dart    |  23 +
 .../map_core/lib/src/models/map_layer.freezed.dart | 709 +++++++++++++++++++++
 packages/map_core/lib/src/models/map_layer.g.dart  |  45 ++
 .../map_core/lib/src/operations/map_layers.dart    |   5 +
 .../map_core/lib/src/operations/map_resize.dart    |   9 +
 .../map_core/lib/src/validation/validators.dart    |  45 +-
 6 files changed, 834 insertions(+), 2 deletions(-)
```

Interprétation :

- aucun fichier présent au status initial n’a disparu ;
- les fichiers modifiés sont dans `packages/map_core` et relèvent du modèle/validation map ;
- les fichiers untracked sont le test Lot 82 et le rapport Lot 82 ;
- `git diff --stat` ne liste pas les fichiers untracked, ce qui est attendu.

## Changements préexistants

Aucun changement préexistant au Gate 0.

## Changements du Lot 82

- Ajout du modèle `SurfaceCellPlacement`.
- Ajout du case `MapLayer.surface`.
- Ajout du JSON `runtimeType: surface`.
- Ajout des validations minimales `SurfaceLayer`.
- Adaptation des helpers map_core nécessaires à l’exhaustivité Freezed.
- Ajout du test `surface_layer_model_test.dart`.
- Création de ce rapport.

## Périmètre explicitement non touché

Confirmé :

- `ProjectManifest` non modifié ;
- `surface.dart` non modifié ;
- `surface_catalog.dart` non modifié ;
- codecs Surface non modifiés ;
- `map_editor` non modifié ;
- `map_runtime` non modifié ;
- `map_gameplay` non modifié ;
- `map_battle` non modifié ;
- aucun provider Surface créé ;
- aucun repository/service Surface créé ;
- aucun painter map créé ;
- aucun runtime renderer créé ;
- aucune migration legacy codée ;
- `Runner.xcscheme` non modifié par ce lot.

## Vérification fichiers temporaires

Sortie :

```text

```

Aucun fichier temporaire correspondant aux patterns demandés n’est présent.

## Vérification mojibake

Lecture visuelle du rapport : aucune mojibake détectée.

## Auto-review

- Est-ce que SurfaceCellPlacement existe ? Oui.
- Est-ce que MapLayer.surface existe ? Oui.
- Est-ce que le stockage est sparse ? Oui, `placements: List<SurfaceCellPlacement>`.
- Est-ce que la cellule référence surfacePresetId ? Oui.
- Est-ce que le rôle autotile calculé est persisté ? Non.
- Est-ce que animationId / atlasId / tilesetId sont absents des placements ? Oui.
- Est-ce que le JSON runtimeType surface fonctionne ? Oui, testé via `MapLayer.fromJson`.
- Est-ce que MapData round-trip avec SurfaceLayer passe ? Oui.
- Est-ce que les layers legacy restent compatibles ? Oui, tests JSON legacy.
- Est-ce que ProjectManifest est modifié ? Non.
- Est-ce que build_runner a été lancé ? Oui, nécessaire pour Freezed/JSON `map_layer`.
- Est-ce que les generated modifiés sont strictement attendus ? Oui : uniquement `map_layer.freezed.dart` et `map_layer.g.dart`.
- Est-ce que map_core tests passent ? Oui, `00:02 +1234: All tests passed!`.
- Est-ce que dart analyze passe ? Analyse ciblée des fichiers modifiés : oui. Analyse globale `lib test` : non, deux infos préexistantes dans `enums.dart`.
- Est-ce qu’un fichier présent au status initial a disparu du status final ? Non.
- Est-ce qu’un fichier hors périmètre a été modifié ? Non pour les packages interdits. Les fichiers modifiés sont dans `map_core`; `map_resize.dart` est inclus car le nouveau case Freezed impose une branche exhaustive.
- Est-ce qu’un 82-bis est nécessaire ? Non pour le périmètre `map_core` demandé. Point de vigilance : des packages consommateurs possèdent des appels `when/map` exhaustifs et devront être traités dans les lots d’intégration editor/runtime, qui sont explicitement hors scope ici.

## Critique du prompt

Le prompt est clair sur le modèle cible et le périmètre. Le point le plus délicat est structurel : ajouter un nouveau case Freezed à `MapLayer` rend les appels exhaustifs `when/map` sensibles dans les packages consommateurs. Ce lot interdit de modifier `map_editor` et `map_runtime`, donc le rapport limite la preuve de non-régression à `map_core`, comme demandé.

Autre point discutable : le prompt demande `dart analyze lib test` avec résultat clean, mais le repo contient deux infos existantes dans `enums.dart`. Les corriger aurait nécessité une modification d’enum hors périmètre ; le lot documente donc la dette plutôt que de la traiter opportunément.
