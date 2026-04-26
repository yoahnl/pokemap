# PokeMap — Spécification technique Surface Engine / Tile Animation Engine

Version : 0.1  
Date : 2026-04-26  
Statut : document de cadrage technique avant implémentation  
Périmètre : `map_core`, `map_editor`, `map_runtime`, `map_gameplay`  
Décision principale : remplacer progressivement la logique actuelle `Path Library` par un vrai système de surfaces animées, sans dépendance obligatoire à Tiled.

---

## 1. Résumé exécutif

Le système actuel de PokeMap permet déjà de poser des terrains, des paths, des éléments placés et certaines animations simples. Il est suffisant pour un MVP, mais il ne permet pas encore d'atteindre le niveau de qualité visuelle observé dans Pokémon SDK / Pokémon Studio pour l'eau, les hautes herbes, les transitions de surfaces et les autotiles complexes.

Le problème principal n'est pas uniquement graphique. Il est structurel : PokeMap traite encore les surfaces comme des variantes de `path`, alors qu'un Pokémon-like a besoin d'un vrai modèle de surfaces du monde.

Il faut donc introduire une nouvelle brique canonique :

```text
Surface Engine
```

Cette brique doit couvrir :

- les surfaces visuelles : eau, herbe haute, routes, sable, glace, lave, marais, rails, ponts, falaises, transitions ;
- les atlas de surfaces : images sources découpées en tiles, avec transparence, grille, métadonnées ;
- les animations de tiles : frames, durées, groupes de synchronisation ;
- l'autotiling : choix automatique de la bonne variante selon les voisins ;
- le rendu runtime Flame : résolution de frame, source rect, draw sans anti-aliasing, synchronisation ;
- l'édition no-code : un vrai `Surface Studio`, compréhensible par une personne non développeuse ;
- la séparation stricte entre rendu visuel et comportement gameplay.

La règle stratégique est simple :

```text
PokeMap ne doit pas dépendre de Tiled.
PokeMap doit comprendre et réimplémenter proprement les concepts utiles que Tiled et Pokémon SDK exploitent.
```

Tiled peut rester une inspiration et éventuellement une source d'import facultative plus tard. Il ne doit pas devenir une dépendance runtime, ni une vérité produit, ni un prérequis pour créer un jeu.

---

## 2. Décisions non négociables

### 2.1. Pas de dépendance obligatoire à Tiled

PokeMap doit pouvoir :

- importer une image de tileset ;
- définir une grille ;
- choisir une couleur de transparence ;
- créer des animations de tiles ;
- mapper des variantes d'autotile ;
- prévisualiser l'eau ou les hautes herbes ;
- rendre ces surfaces dans le runtime Flame ;

sans jamais demander à l'utilisateur d'ouvrir Tiled.

Tiled peut éventuellement être supporté comme :

- import facultatif `.tsx` ;
- import facultatif `.tmx` ;
- outil de migration ;
- source de debug ;
- format d'échange avancé.

Mais la vérité projet doit être dans les fichiers PokeMap.

### 2.2. Ne pas copier RMXP

Pokémon SDK compile vers des contraintes historiques liées à RPG Maker XP / RGSS : autotiles RMXP, groupes de 48 variantes, limites de texture, IDs internes spécifiques, conversion vers `graphics/autotiles`, etc.

PokeMap ne doit pas copier aveuglément :

- les IDs autotile RMXP ;
- la contrainte stricte des 48 variantes comme vérité universelle ;
- les fichiers `.rxdata` ;
- la logique Ruby ;
- les limites de texture pensées pour RMXP ;
- la dépendance aux conventions internes de Pokémon SDK.

PokeMap doit reprendre les idées utiles :

- atlas animé ;
- colonne = variante ;
- ligne = frame temporelle ;
- durée par frame ;
- compteur synchronisé ;
- autotile basé sur voisinage ;
- génération/validation d'assets ;
- rendu natif côté tilemap.

### 2.3. Séparer visuel et gameplay

Une surface visuelle ne doit pas décider seule du gameplay.

Exemples :

- une tile bleue ne doit pas automatiquement imposer `surf` ;
- une herbe haute visuelle ne doit pas automatiquement déclencher des rencontres ;
- une lave visuelle ne doit pas automatiquement infliger des dégâts ;
- un pont visuel ne doit pas automatiquement changer la collision.

Le comportement gameplay doit rester porté par des modèles explicites :

- zones de mouvement ;
- zones de rencontre ;
- zones de danger ;
- scripts ;
- collisions ;
- règles de runtime.

Le `Surface Studio` peut aider à générer ou suggérer ces zones, mais il ne doit pas fusionner définitivement le pixel et la règle métier.

### 2.4. Garder la compatibilité avec l'existant

Il ne faut pas supprimer brutalement :

- `ProjectPathPreset` ;
- `PathLayer` ;
- `RuntimePathAutotileSet` ;
- les tests existants sur paths ;
- les projets existants.

La migration doit être progressive :

1. ajouter les surfaces V2 ;
2. rendre le runtime capable de lire les deux mondes ;
3. proposer une migration `PathPreset` -> `SurfacePreset` ;
4. conserver les anciens paths comme mode legacy ;
5. déprécier progressivement l'ancien modèle seulement quand le nouveau couvre vraiment l'usage.

---

## 3. Analyse de l'image source et du TSX uploadé

### 3.1. Ce que montre le TSX

Le fichier TSX uploadé décrit un tileset nommé `HGSS Nature` avec les caractéristiques suivantes :

```xml
<tileset version="1.10" tiledversion="1.11.0" name="HGSS Nature" tilewidth="32" tileheight="32" tilecount="3451" columns="48">
 <image source="../Assets/TECH-Nature.png" trans="f05ba1" width="1536" height="2080"/>
```

Interprétation :

- taille logique d'une tile : `32x32` ;
- largeur image source déclarée : `1536 px` ;
- `1536 / 32 = 48` colonnes ;
- hauteur image source déclarée : `2080 px` ;
- `2080 / 32 = 65` lignes ;
- transparence déclarée : `#f05ba1`, le rose/magenta utilisé comme couleur de masque.

Le fichier TSX contient surtout une liste de tiles et un `wangset` :

```xml
<wangsets>
  <wangset name="Testing" type="corner" tile="-1">
    <wangcolor name="Chemin herbe" color="#ff0000" tile="-1" probability="1"/>
    <wangcolor name="Chemin herbe to sand" color="#00ff00" tile="-1" probability="1"/>
    <wangtile tileid="433" wangid="0,0,0,1,0,0,0,0"/>
```

Ce `wangset` n'est pas une animation. C'est une description d'autotiling / transition. Il explique quelle tile utiliser selon une configuration de coins/côtés voisins.

Donc il faut distinguer deux dimensions :

```text
TSX / Wangset = règles de choix des variantes selon le voisinage
Atlas animé = frames temporelles pour faire bouger certaines variantes
```

Ces deux sujets doivent être séparés dans PokeMap.

### 3.2. Structure visuelle des atlas d'eau

Les images d'eau observées suivent une logique très classique de moteur 2D :

```text
colonnes = variantes visuelles
lignes   = frames temporelles
```

Pour un atlas vertical animé :

```text
sourceX = variantColumn * tileWidth
sourceY = frameIndex * tileHeight
sourceW = tileWidth
sourceH = tileHeight
```

Exemple avec tiles `32x32` :

```text
sourceX = column * 32
sourceY = frame * 32
sourceW = 32
sourceH = 32
```

C'est cette structure qu'il faut rendre native dans PokeMap.

### 3.3. Rôle du magenta `#f05ba1`

Le magenta est une couleur de transparence. Il sert à distinguer les zones réellement dessinées des zones transparentes, notamment pour :

- les bords d'eau ;
- les coins ;
- les transitions ;
- les overlays de surface ;
- les éléments partiels.

Dans PokeMap, il faut convertir cette couleur en alpha réel au moment de l'import, ou au minimum stocker cette information dans le modèle d'atlas.

Le runtime Flame ne doit pas dépendre d'une couleur magique au moment du rendu. Il doit recevoir une image déjà correctement masquée ou un `RuntimeTilesetImage` préparé.

### 3.4. Ce que l'image ne peut pas dire seule

Une image ne suffit jamais.

Elle ne dit pas :

- combien de frames composent une animation ;
- combien de millisecondes dure chaque frame ;
- quelles colonnes appartiennent au même groupe de synchronisation ;
- quelle colonne représente un centre, un bord nord, un bord sud, un coin, une transition ;
- si la surface est passable ;
- si elle déclenche une rencontre ;
- si elle doit être rendue sous ou au-dessus du joueur ;
- si elle doit produire une animation one-shot quand le joueur marche dessus.

Il faut donc un manifest PokeMap à côté de l'image.

---

## 4. État actuel de PokeMap

### 4.1. Modèles tileset déjà présents

PokeMap possède déjà des modèles utiles :

- `ProjectTilesetEntry` ;
- `TilesetPaletteEntry` ;
- `TilesetSourceRect` ;
- `TilesetVisualFrame` ;
- `ProjectElementEntry` ;
- `ProjectTerrainPreset` ;
- `TerrainPresetVariant` ;
- `ProjectPathPreset` ;
- `PathPresetVariantMapping`.

Le point positif : `TilesetVisualFrame` contient déjà :

```text
tilesetId
source rect
durationMs
```

Donc PokeMap a déjà une notion de frame visuelle.

Le point faible : cette notion est locale et générique. Elle est utilisée pour des entrées palette, des éléments, des terrains ou des paths, mais elle ne constitue pas un vrai modèle de surface animée.

### 4.2. Modèle `PathSurfaceKind`

PokeMap possède déjà une énumération proche du futur besoin :

```text
path
road
water
tallGrass
ice
lava
swamp
rails
bridge
special
custom
```

C'est un indice fort que le concept métier existe déjà, mais il est actuellement encore enfermé dans la notion de `Path`.

Le bon refactor conceptuel est :

```text
PathSurfaceKind -> SurfaceKind ou SurfacePresetKind
```

Mais il ne faut pas faire un renommage violent immédiatement. Il faut créer une V2 propre, puis migrer.

### 4.3. Modèle `PathLayer`

Aujourd'hui, une couche path ressemble conceptuellement à ceci :

```text
id
name
isVisible
opacity
presetId
cells: List<bool>
properties
animationMode
animationTriggers
```

Limites :

- une couche path référence un seul `presetId` ;
- une cellule est seulement active ou inactive ;
- impossible de stocker plusieurs types de surface dans la même couche ;
- impossible de faire naturellement des transitions entre deux surfaces différentes ;
- impossible de porter des overrides par cellule sans bricoler `properties` ;
- l'autotiling repose surtout sur un masque booléen ;
- le système n'est pas idéal pour eau + sable + falaise + pont + hautes herbes.

### 4.4. Resolver actuel des paths

Le resolver actuel utilise :

- un masque cardinal ;
- 16 combinaisons de base ;
- quelques variantes supplémentaires pour les coins internes.

Variantes actuelles importantes :

```text
isolated
endNorth
endEast
endSouth
endWest
horizontal
vertical
cornerNE
cornerSE
cornerSW
cornerNW
innerCornerNE
innerCornerSE
innerCornerSW
innerCornerNW
teeNorth
teeEast
teeSouth
teeWest
cross
```

Ce système est utile pour des routes simples. Il devient limité pour :

- surfaces à coins complexes ;
- transitions à deux matériaux ;
- Wang tiles ;
- bords d'eau avec rochers ;
- cascades ;
- ponts au-dessus de l'eau ;
- autotiles animés ;
- variations aléatoires pondérées ;
- transitions diagonales riches.

### 4.5. Runtime actuel

Le runtime possède `RuntimePathAutotileSet`.

Il sait :

- construire une map `TerrainPathVariant -> frames` depuis un `ProjectPathPreset` ;
- choisir la première frame en statique ;
- résoudre une frame en boucle selon `elapsedMs` ;
- résoudre une animation one-shot ;
- normaliser les durées via les helpers d'animation d'éléments placés.

C'est une très bonne base. Mais ce n'est pas encore un Tile Animation Engine.

Limites actuelles :

- pas d'atlas d'animation global ;
- pas de groupe de synchronisation partagé entre plusieurs variantes ;
- pas de manifest d'animation de tiles ;
- pas de cache runtime spécialisé par surface ;
- pas de `SurfaceAnimationClock` ;
- pas de séparation claire entre animation loop globale et animation déclenchée localement ;
- pas de renderer spécialisé pour surfaces ;
- le rendu path est encore dans `MapLayersComponent`, qui fait déjà beaucoup trop de choses.

### 4.6. Rendu actuel dans `MapLayersComponent`

Le rendu actuel :

- parcourt les couches visibles ;
- peint les terrains ;
- peint les paths ;
- peint les tile layers ;
- peint les entités ;
- peint éventuellement les collisions ;
- résout les frames de paths ;
- gère les animations d'éléments placés ;
- gère les one-shot de path rules.

Problème : `MapLayersComponent` devient une zone de concentration de responsabilité. Il ne faut pas ajouter toute la logique Surface Engine dedans sans séparation, sinon on fabrique un gros machin bien poisseux, le genre de composant qui finit par faire le café, le rendu, la météo et une crise existentielle.

Le Surface Engine doit avoir ses propres classes runtime.

---

## 5. Ce que Pokémon SDK fait mieux

### 5.1. Animated tiles comme donnée native

Pokémon SDK charge des tiles animées via une structure du type :

```text
AnimatedTile
- gid
- frames

Frame
- tile_id
- duration
```

Donc une tile animée n'est pas juste une image qui change. C'est une donnée structurée : chaque frame pointe vers une tile source et possède une durée.

### 5.2. Compilation des autotiles animés

Pokémon SDK groupe les tiles animées, calcule le nombre de frames, crée une image de sortie, puis dessine les colonnes animées dans un atlas final.

La logique importante est :

```text
imageWidth  = numberOfAnimatedTiles * 32
imageHeight = frameCount * 32
```

Puis :

```text
pour chaque variante animée
  dessiner toutes ses frames verticalement dans sa colonne
```

C'est exactement le format qu'on doit reprendre conceptuellement.

### 5.3. Compteurs d'animation synchronisés

Pokémon SDK conserve des compteurs d'animation. Les tiles qui partagent les mêmes durées peuvent partager un même compteur.

Cela évite que :

- le centre de l'eau soit à la frame 4 ;
- le bord gauche soit à la frame 9 ;
- le coin soit à la frame 17.

Si les variantes d'une même surface ne sont pas synchronisées, le rendu devient immédiatement mauvais.

### 5.4. Tilemap runtime natif

Pokémon SDK branche le tilemap comme composant central du `Spriteset_Map`. La tilemap est mise à jour à chaque frame avec la caméra, les offsets, les autotiles, les compteurs et les maps chargées.

La conséquence : l'eau animée n'est pas un overlay bricolé. Elle fait partie du rendu natif de la map.

PokeMap doit viser la même philosophie côté Flame.

---

## 6. Architecture cible PokeMap

### 6.1. Vue d'ensemble

Architecture cible :

```text
map_core
  Surface models
  Surface layer model
  Surface autotile resolver
  Surface animation resolver
  Surface validation
  Surface migration legacy

map_editor
  Surface Studio
  Surface atlas import
  Surface animation authoring
  Surface autotile mapping UI
  Surface behavior authoring
  Diagnostics and previews

map_runtime
  RuntimeSurfaceCatalog
  RuntimeSurfaceAnimationClock
  RuntimeSurfaceAutotileResolver
  RuntimeSurfaceLayerComponent
  RuntimeSurfaceOverlayComponent

map_gameplay
  Movement / encounter / hazard integration
  Surface-to-zone helpers only when explicit
```

### 6.2. Principe de vérité

La vérité des surfaces doit vivre dans le manifest projet PokeMap.

Proposition conceptuelle :

```text
ProjectManifest
- surfaceFolders
- surfaceAtlases
- surfaceAnimationGroups
- surfacePresets
- surfaceCategories
```

Les noms exacts peuvent évoluer, mais le découpage doit rester.

---

## 7. Nouveaux modèles `map_core`

### 7.1. `SurfaceAtlas`

Fichier proposé :

```text
packages/map_core/lib/src/models/surface_atlas.dart
```

Responsabilité : décrire une image source découpée en tiles.

Champs proposés :

```text
id: String
name: String
relativePath: String
tileWidth: int
tileHeight: int
columns: int
rows: int
transparentColor: String?
alphaMode: SurfaceAtlasAlphaMode
layoutHints: List<SurfaceAtlasLayoutHint>
folderId: String?
sortOrder: int
```

Enums proposés :

```text
SurfaceAtlasAlphaMode
- imageAlpha
- colorKey
- opaque

SurfaceAtlasLayoutHint
- regularGrid
- verticalAnimationAtlas
- horizontalAnimationStrip
- mixedTileset
```

Validation :

- `id.trim()` non vide ;
- `relativePath.trim()` non vide ;
- `tileWidth > 0` ;
- `tileHeight > 0` ;
- `columns > 0` ;
- `rows > 0` ;
- si `transparentColor != null`, format `#RRGGBB` ou `RRGGBB` ;
- l'image réelle doit être compatible avec `columns * tileWidth` et `rows * tileHeight` côté éditeur/runtime.

### 7.2. `SurfaceTileRef`

Responsabilité : pointer vers une tile ou une région dans un atlas.

Fichier possible :

```text
packages/map_core/lib/src/models/surface_tile_ref.dart
```

Champs proposés :

```text
atlasId: String
x: int
y: int
width: int
height: int
```

Règle :

- `x` et `y` sont en coordonnées de tile, pas en pixels ;
- `width` et `height` sont en nombre de tiles ;
- pour une surface standard, `width = 1` et `height = 1`.

### 7.3. `SurfaceAnimationDefinition`

Responsabilité : décrire une animation de tile ou de variante.

Fichier proposé :

```text
packages/map_core/lib/src/models/surface_animation.dart
```

Champs proposés :

```text
id: String
name: String
syncGroupId: String?
frames: List<SurfaceAnimationFrame>
playback: SurfaceAnimationPlayback
```

`SurfaceAnimationFrame` :

```text
tile: SurfaceTileRef
durationMs: int
```

`SurfaceAnimationPlayback` :

```text
loop
oneShot
pingPong
staticFirstFrame
```

Validation :

- au moins une frame ;
- toutes les durées strictement positives ;
- toutes les frames pointent vers un atlas connu ;
- toutes les frames ont la même taille logique ;
- pour une animation de surface loop globale, `syncGroupId` recommandé ;
- si `playback = staticFirstFrame`, une seule frame recommandée.

### 7.4. `SurfaceAnimationSyncGroup`

Responsabilité : synchroniser plusieurs animations.

Champs proposés :

```text
id: String
name: String
clockMode: SurfaceAnimationClockMode
phaseOffsetMs: int
```

`SurfaceAnimationClockMode` :

```text
globalMapClock
localLayerClock
localCellClock
manualTrigger
```

Règles :

- l'eau doit généralement utiliser `globalMapClock` ;
- les hautes herbes déclenchées au pas doivent généralement utiliser `localCellClock` ou `manualTrigger` ;
- les animations de lave peuvent utiliser `globalMapClock` ;
- les animations de rails ou machines peuvent utiliser `localLayerClock`.

### 7.5. `SurfacePreset`

Responsabilité : décrire une surface métier auteur.

Fichier proposé :

```text
packages/map_core/lib/src/models/surface_preset.dart
```

Champs proposés :

```text
id: String
name: String
kind: SurfaceKind
categoryId: String?
autotileSetId: String?
defaultVariantId: String?
renderMode: SurfaceRenderMode
behavior: SurfaceBehaviorRef?
tags: List<String>
sortOrder: int
```

`SurfaceKind` :

```text
road
path
water
tallGrass
sand
ice
lava
swamp
mud
rails
bridge
cliff
ledge
carpet
indoorFloor
custom
```

`SurfaceRenderMode` :

```text
background
surfaceOverlay
foregroundOverlay
underActor
overActorFeet
fullForeground
```

Interprétation :

- `background` : sol classique ;
- `surfaceOverlay` : posé au-dessus du terrain de base ;
- `overActorFeet` : utile pour hautes herbes ;
- `fullForeground` : utile pour certains ponts ou éléments spéciaux.

### 7.6. `SurfaceAutotileSet`

Responsabilité : mapper des configurations de voisinage vers des variantes visuelles.

Fichier proposé :

```text
packages/map_core/lib/src/models/surface_autotile.dart
```

Champs proposés :

```text
id: String
name: String
mode: SurfaceAutotileMode
variants: List<SurfaceAutotileVariant>
fallbackVariantId: String?
```

`SurfaceAutotileMode` :

```text
none
cardinal4
corner8
wangCorner
wangEdge
customMask
```

`SurfaceAutotileVariant` :

```text
id: String
label: String
pattern: SurfaceAdjacencyPattern
visual: SurfaceVisualRef
weight: int
```

`SurfaceVisualRef` :

```text
staticTile: SurfaceTileRef?
animationId: String?
```

Règles :

- une variante peut être statique ou animée ;
- une variante animée référence `SurfaceAnimationDefinition` ;
- plusieurs variantes peuvent partager le même pattern avec des poids différents ;
- une variante peut être une transition entre deux surfaces.

### 7.7. `SurfaceAdjacencyPattern`

Responsabilité : exprimer le voisinage requis.

Proposition :

```text
north: SurfaceNeighborMatch
east: SurfaceNeighborMatch
south: SurfaceNeighborMatch
west: SurfaceNeighborMatch
northEast: SurfaceNeighborMatch
southEast: SurfaceNeighborMatch
southWest: SurfaceNeighborMatch
northWest: SurfaceNeighborMatch
```

`SurfaceNeighborMatch` :

```text
same
other
empty
any
surface:<surfaceId>
kind:<SurfaceKind>
notSame
```

Cette modélisation permet de reproduire l'esprit des `wangid` sans stocker un `wangid` brut dépendant de Tiled.

### 7.8. `SurfaceLayer`

À ajouter dans `MapLayer` comme nouvelle union value.

Proposition :

```text
@FreezedUnionValue('surface')
MapLayer.surface({
  required String id,
  required String name,
  bool isVisible = true,
  double opacity = 1.0,
  List<String> surfaceIds = const [],
  Map<String, SurfaceCellOverride> cellOverrides = const {},
})
```

`surfaceIds` :

- taille attendue : `mapWidth * mapHeight` ;
- chaîne vide = aucune surface ;
- valeur non vide = `SurfacePreset.id`.

`SurfaceCellOverride` :

```text
variantId: String?
animationEnabled: bool?
behaviorEnabled: bool?
properties: Map<String, String>
```

Pourquoi une `SurfaceLayer` plutôt qu'étendre `PathLayer` ?

- on évite de casser l'existant ;
- on garde un modèle legacy simple ;
- on autorise plusieurs surfaces dans une même couche ;
- on prépare les transitions entre surfaces ;
- on rend le modèle plus proche du besoin réel.

### 7.9. Migration legacy

Fichier proposé :

```text
packages/map_core/lib/src/io/surface_legacy_migration.dart
```

Responsabilités :

- ne pas modifier les projets automatiquement de façon destructrice ;
- proposer une conversion contrôlée de `PathLayer` vers `SurfaceLayer` ;
- convertir `ProjectPathPreset` vers `SurfacePreset` quand possible ;
- produire un rapport de migration ;
- conserver les IDs autant que possible ;
- préserver les `PathAnimationTriggerRule` sous forme de comportements ou triggers surface.

---

## 8. Nouveaux services et opérations `map_core`

### 8.1. `surface_autotile_resolver.dart`

Fichier proposé :

```text
packages/map_core/lib/src/operations/surface_autotile_resolver.dart
```

Responsabilité : résoudre la variante visuelle à utiliser pour une cellule.

Entrée :

```text
surfaceLayer
mapSize
position
surfacePresets
autotileSets
randomSeed optional
```

Sortie :

```text
ResolvedSurfaceVariant
- surfaceId
- variantId
- visualRef
- patternMatched
- fallbackUsed
```

Cas à gérer :

- cellule vide ;
- surface sans autotile ;
- surface avec autotile cardinal4 ;
- surface avec autotile corner8 ;
- surface avec règles Wang-like ;
- transition surface A -> surface B ;
- variante manquante ;
- fallback explicite ;
- fallback debug.

### 8.2. `surface_animation_resolver.dart`

Fichier proposé :

```text
packages/map_core/lib/src/operations/surface_animation_resolver.dart
```

Responsabilité : logique pure de résolution de frame.

Entrée :

```text
animation
elapsedMs
mode
```

Sortie :

```text
SurfaceAnimationFrameResolution
- frameIndex
- frame
- completed
```

Règles :

- supporter les durées irrégulières ;
- supporter les boucles ;
- supporter one-shot ;
- supporter ping-pong plus tard ;
- ne pas dépendre de Flutter/Flame.

### 8.3. `map_surface.dart`

Fichier proposé :

```text
packages/map_core/lib/src/operations/map_surface.dart
```

Responsabilités :

- peindre une surface ;
- effacer une surface ;
- remplir une zone ;
- remplacer une surface par une autre ;
- redimensionner une `SurfaceLayer` ;
- fusionner / séparer des couches ;
- valider la taille `surfaceIds` ;
- calculer les cellules affectées par une modification pour invalider les voisins.

Important : quand une cellule change, il faut invalider :

```text
la cellule modifiée
ses 4 voisins cardinaux
ses 4 diagonales si le mode d'autotile les utilise
```

### 8.4. `surface_validation.dart`

Fichier proposé :

```text
packages/map_core/lib/src/validation/surface_validation.dart
```

Validation de projet :

- atlas référencés existants ;
- animations avec frames valides ;
- sync groups existants ;
- variantes d'autotile valides ;
- `SurfaceLayer.surfaceIds.length == width * height` ;
- pas de `surfaceId` inconnu ;
- pas d'animation sans frame ;
- pas de durée `<= 0` ;
- pas de source rect hors atlas ;
- pas de cycle de dépendance inutile ;
- warnings si variantes essentielles manquantes.

---

## 9. Architecture runtime `map_runtime`

### 9.1. Ne pas gonfler `MapLayersComponent`

Il faut éviter d'ajouter tout le Surface Engine directement dans `MapLayersComponent`.

Créer plutôt :

```text
packages/map_runtime/lib/src/presentation/flame/runtime_surface_catalog.dart
packages/map_runtime/lib/src/presentation/flame/runtime_surface_animation_clock.dart
packages/map_runtime/lib/src/presentation/flame/runtime_surface_autotile_resolver.dart
packages/map_runtime/lib/src/presentation/flame/runtime_surface_layer_component.dart
packages/map_runtime/lib/src/presentation/flame/runtime_surface_overlay_component.dart
```

### 9.2. `RuntimeSurfaceCatalog`

Responsabilité : précompiler les données projet en structures rapides.

Contenu :

```text
atlasesById
animationsById
syncGroupsById
presetsById
autotileSetsById
```

Il doit aussi produire :

```text
animationId -> normalized durations
surfaceId -> renderMode
surfaceId -> behaviorRef
variantId -> visualRef
```

### 9.3. `RuntimeSurfaceAnimationClock`

Responsabilité : résoudre le temps d'animation.

Cas :

- clock globale map ;
- clock layer ;
- clock cell ;
- clock déclenchée manuellement.

API conceptuelle :

```text
elapsedForSyncGroup(syncGroupId)
elapsedForLayer(layerId, syncGroupId)
elapsedForCell(layerId, x, y, syncGroupId)
startCellOneShot(layerId, x, y, animationId)
stopCellLoop(layerId, x, y, animationId)
```

### 9.4. `RuntimeSurfaceFrameResolver`

Responsabilité : convertir une surface résolue en source rect dessinable.

Entrée :

```text
surfaceId
variantId
elapsedMs
```

Sortie :

```text
RuntimeSurfaceFrame
- atlasId
- sourceRectPixels
- opacity
- renderMode
```

Règles :

- utiliser `SurfaceAnimationDefinition` si `visual.animationId` existe ;
- utiliser `SurfaceTileRef` statique sinon ;
- appliquer le `syncGroupId` ;
- ne jamais faire de logique gameplay.

### 9.5. `RuntimeSurfaceLayerComponent`

Responsabilité : dessiner les `SurfaceLayer`.

Fonctionnement :

1. parcourir les cellules visibles seulement ;
2. résoudre le `surfaceId` ;
3. résoudre la variante via `RuntimeSurfaceAutotileResolver` ;
4. résoudre la frame via `RuntimeSurfaceFrameResolver` ;
5. dessiner avec `drawImageRect` ;
6. désactiver l'anti-aliasing ;
7. utiliser `FilterQuality.none` ;
8. respecter l'opacité de couche ;
9. respecter le render pass.

Rendu pixel art obligatoire :

```text
isAntiAlias = false
filterQuality = none
positions entières ou contrôlées
source rect aligné sur la grille
pas de scaling fractionnaire non maîtrisé
```

### 9.6. Optimisation runtime

Version simple au début :

- parcourir toutes les cellules visibles ;
- résoudre et dessiner.

Optimisations à prévoir ensuite :

- culling par caméra ;
- cache des cellules statiques ;
- séparation statique / animée ;
- regroupement par atlas ;
- dirty rectangles autour des cellules modifiées ;
- cache de résolution d'autotile ;
- invalidation uniquement sur cellule + voisins ;
- métriques de rendu en debug.

---

## 10. Surface Studio côté éditeur

### 10.1. Objectif produit

Le `Surface Studio` doit être l'outil no-code permettant de créer et gérer :

- l'eau ;
- les hautes herbes ;
- les routes ;
- le sable ;
- la glace ;
- la lave ;
- les marais ;
- les rails ;
- les ponts ;
- les transitions entre surfaces.

Il doit remplacer progressivement l'idée trop limitée de `Path Library`.

### 10.2. Structure UI proposée

Fichiers proposés :

```text
packages/map_editor/lib/src/ui/canvas/surface_studio/surface_studio_workspace.dart
packages/map_editor/lib/src/ui/canvas/surface_studio/surface_studio_shell.dart
packages/map_editor/lib/src/ui/canvas/surface_studio/surface_atlas_panel.dart
packages/map_editor/lib/src/ui/canvas/surface_studio/surface_animation_panel.dart
packages/map_editor/lib/src/ui/canvas/surface_studio/surface_autotile_panel.dart
packages/map_editor/lib/src/ui/canvas/surface_studio/surface_behavior_panel.dart
packages/map_editor/lib/src/ui/canvas/surface_studio/surface_preview_panel.dart
packages/map_editor/lib/src/ui/canvas/surface_studio/surface_diagnostics_panel.dart
```

### 10.3. Atlas panel

Fonctions :

- importer une image ;
- définir tile width / tile height ;
- détecter colonnes / lignes ;
- choisir transparence : alpha existant, color key, opaque ;
- prévisualiser la grille ;
- cliquer une tile pour voir ses coordonnées ;
- vérifier les rects hors limites ;
- convertir magenta en alpha réel ;
- afficher les dimensions réelles de l'image.

### 10.4. Animation panel

Fonctions :

- créer une animation depuis une colonne verticale ;
- créer une animation depuis une bande horizontale ;
- créer une animation en sélectionnant des tiles manuellement ;
- définir durée par défaut ;
- éditer durée par frame ;
- créer un sync group ;
- prévisualiser en boucle ;
- prévisualiser à vitesse 0.5x, 1x, 2x ;
- détecter les frames au masque alpha incohérent ;
- afficher un warning si les dimensions des frames diffèrent.

### 10.5. Autotile panel

Fonctions :

- choisir le mode d'autotile ;
- mapper les variantes ;
- afficher les variantes obligatoires ;
- afficher les variantes optionnelles ;
- permettre plusieurs variantes pondérées ;
- tester sur une mini-map ;
- signaler les patterns non couverts ;
- générer des mappings automatiques depuis une disposition connue ;
- importer un `wangset` facultativement plus tard.

### 10.6. Behavior panel

Fonctions :

- définir le type de surface ;
- définir le render mode ;
- suggérer une zone gameplay ;
- associer une zone de rencontre ;
- associer une règle de mouvement ;
- associer un danger ;
- définir si la surface peut déclencher une animation locale ;
- définir si elle masque les pieds du joueur.

Important : le panel peut suggérer du gameplay, mais ne doit pas rendre le visuel magiquement gameplay.

### 10.7. Preview panel

Fonctions :

- mini-carte de test ;
- pinceau rapide ;
- prévisualisation de l'autotile ;
- prévisualisation animation ;
- toggle debug masks ;
- toggle cell borders ;
- toggle frame index ;
- preview avec player sprite pour hautes herbes ;
- preview surf pour eau.

### 10.8. Diagnostics panel

Warnings à afficher :

- atlas introuvable ;
- dimensions non divisibles par tile size ;
- couleur de transparence absente ;
- animation sans sync group ;
- animation avec durées incohérentes ;
- variantes essentielles manquantes ;
- fallback utilisé ;
- animation qui référence un atlas supprimé ;
- surface sans render mode ;
- surface water sans suggestion de movement zone ;
- tall grass sans suggestion d'encounter zone.

---

## 11. Cas spécial : l'eau

### 11.1. Besoins visuels

L'eau doit gérer :

- centre animé ;
- bords animés ou semi-animés ;
- coins ;
- coins internes ;
- transitions avec roche ;
- transitions avec sable ;
- transitions avec herbe ;
- ponts au-dessus ;
- cascades plus tard ;
- reflets ou écume plus tard.

### 11.2. Besoins animation

Pour une eau propre :

- toutes les variantes d'une même eau doivent partager un sync group ;
- les durées doivent être cohérentes ;
- les frames doivent boucler sans saut brutal ;
- les bords ne doivent pas trembler ;
- les masques alpha doivent rester cohérents entre frames.

Validation spécifique :

```text
Si une animation de surface water possède plusieurs frames,
le Studio doit comparer le masque alpha de chaque frame.
Si le masque change fortement, afficher un warning.
```

### 11.3. Besoins gameplay

L'eau visuelle peut suggérer :

- une zone `MovementMode.surf` ;
- une zone de rencontre aquatique ;
- un son de pas / surf ;
- des particules.

Mais elle ne doit pas imposer automatiquement ces comportements sans action explicite.

### 11.4. Surface water V1 minimum

Pour considérer `Water V1` comme réussi :

- un atlas animé vertical peut être importé ;
- au moins centre + bords + coins sont supportés ;
- les frames sont synchronisées ;
- le runtime rend l'eau animée dans Flame ;
- l'eau reste pixel perfect ;
- la map peut mélanger terrain statique + eau animée ;
- une preview éditeur montre la même animation que le runtime ;
- un test couvre la frame à `0ms`, `duration-1`, `duration`, fin de cycle.

---

## 12. Cas spécial : les hautes herbes

### 12.1. Besoins visuels

Les hautes herbes ne doivent pas être traitées comme une eau verte.

Elles ont besoin de :

- tile de base ;
- variation visuelle ;
- overlay au-dessus des pieds du joueur ;
- animation locale quand le joueur marche dessus ;
- option de mouvement léger ou bruissement ;
- rendu stable quand aucun acteur ne marche dessus.

### 12.2. Render mode recommandé

Pour les hautes herbes :

```text
renderMode = overActorFeet
```

Ce mode implique :

- une partie de l'herbe peut être dessinée au-dessus du bas du joueur ;
- le joueur reste visible ;
- le moteur doit éviter que l'herbe masque tout le sprite.

### 12.3. Animation recommandée

Deux types d'animation :

```text
idleLoop optional
stepOneShot required for premium feel
```

`idleLoop` :

- léger mouvement permanent ;
- global ou layer clock ;
- optionnel.

`stepOneShot` :

- déclenché quand joueur ou NPC entre dans la cellule ;
- local à la cellule ;
- ne doit pas déclencher toute la couche ;
- peut redémarrer si un acteur repasse dessus.

### 12.4. Gameplay recommandé

Les hautes herbes peuvent suggérer :

- zone de rencontre ;
- encounter kind `walk` ;
- son de pas ;
- animation locale.

Mais encore une fois, la zone de rencontre doit rester explicite.

---

## 13. Migration depuis `Path Library`

### 13.1. Pourquoi migrer

La `Path Library` actuelle mélange :

- routes ;
- eau ;
- herbe haute ;
- glace ;
- lave ;
- rails ;
- ponts.

Le nom `Path` devient faux. Ce sont des surfaces.

### 13.2. Stratégie de migration

Étape 1 : garder `Path Library` telle quelle.

Étape 2 : ajouter `Surface Studio` en parallèle.

Étape 3 : proposer une action :

```text
Convert legacy paths to surfaces
```

Étape 4 : pour chaque `ProjectPathPreset` :

```text
ProjectPathPreset.id -> SurfacePreset.id
ProjectPathPreset.name -> SurfacePreset.name
ProjectPathPreset.surfaceKind -> SurfacePreset.kind
ProjectPathPreset.variants -> SurfaceAutotileSet.variants
```

Étape 5 : pour chaque `PathLayer` :

```text
PathLayer.cells + presetId -> SurfaceLayer.surfaceIds
```

Étape 6 : conserver l'ancien `PathLayer` si l'utilisateur refuse la migration.

### 13.3. Migration des triggers

Les `PathAnimationTriggerRule` doivent être converties vers un modèle plus général :

```text
SurfaceInteractionRule
```

Champs possibles :

```text
id
enabled
trigger
playback
scope
animationId
```

Correspondance :

```text
onStep -> onActorStep
onEnter -> onActorEnter
onNear -> onActorNear
onAction -> onPlayerAction
onBump -> onActorBump
whileInside -> whileActorInside
```

---

## 14. Roadmap proposée

## Lot S0 — Audit surfaces réel

### But

Produire un état des lieux exact avant modification.

### Fichiers à inspecter

```text
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/tileset.dart
packages/map_core/lib/src/models/map_layer.dart
packages/map_core/lib/src/models/enums.dart
packages/map_core/lib/src/models/map_metadata.dart
packages/map_core/lib/src/operations/map_path.dart
packages/map_core/lib/src/operations/map_terrain.dart
packages/map_core/lib/src/operations/map_terrain_autotile.dart
packages/map_core/lib/src/operations/path_animation_rules.dart
packages/map_editor/lib/src/application/services/path_autotile_resolver.dart
packages/map_editor/lib/src/application/services/path_layer_editing_coordinator.dart
packages/map_editor/lib/src/application/use_cases/path_layer_use_cases.dart
packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart
packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/presentation/flame/runtime_path_autotile.dart
packages/map_gameplay/lib/src/surf_evaluation.dart
packages/map_gameplay/lib/src/gameplay_encounter.dart
```

### Livrable

```text
reports/analysis/surface_engine_s0_audit.md
```

### Le rapport doit contenir

- tous les modèles actuels ;
- tous les endroits qui peignent terrain/path/tile ;
- tous les tests existants liés aux paths ;
- les comportements surf / encounter déjà branchés ;
- les risques de migration ;
- les noms de fichiers exacts ;
- les limites confirmées ;
- une recommandation de lot S1 ajustée si nécessaire.

### Tests

Aucun test nouveau obligatoire. Le lot est documentaire.

### Critères d'acceptation

- aucun code produit modifié ;
- rapport présent ;
- état réel documenté ;
- divergences avec cette spec signalées ;
- aucune hypothèse non vérifiée vendue comme vérité.

---

## Lot S1 — Modèle Surface Core V1

### But

Ajouter les modèles fondamentaux dans `map_core`, sans changer le rendu runtime.

### Fichiers à créer

```text
packages/map_core/lib/src/models/surface_atlas.dart
packages/map_core/lib/src/models/surface_animation.dart
packages/map_core/lib/src/models/surface_autotile.dart
packages/map_core/lib/src/models/surface_preset.dart
packages/map_core/lib/src/models/surface_behavior.dart
packages/map_core/lib/src/validation/surface_validation.dart
packages/map_core/test/surface_atlas_model_test.dart
packages/map_core/test/surface_animation_model_test.dart
packages/map_core/test/surface_autotile_model_test.dart
packages/map_core/test/surface_preset_model_test.dart
packages/map_core/test/surface_validation_test.dart
```

### Fichiers à modifier

```text
packages/map_core/lib/map_core.dart
packages/map_core/lib/src/models/project_manifest.dart
```

### Changements attendus

Ajouter dans `ProjectManifest` :

```text
surfaceAtlases
surfaceAnimationSyncGroups
surfaceAnimations
surfaceAutotileSets
surfacePresets
surfaceFolders optional
surfaceCategories optional
```

Tous les nouveaux champs doivent avoir des defaults vides pour ne pas casser les anciens projets.

### Tests obligatoires

- sérialisation `SurfaceAtlas` ;
- désérialisation avec champs optionnels absents ;
- validation `tileWidth <= 0` rejetée ;
- validation `tileHeight <= 0` rejetée ;
- validation `columns <= 0` rejetée ;
- validation `rows <= 0` rejetée ;
- validation couleur transparente invalide rejetée ;
- animation sans frame rejetée ;
- frame avec durée `0` rejetée ;
- frame qui référence un atlas inconnu rejetée ;
- surface preset sans id rejeté ;
- autotile variant sans visual rejeté ;
- manifest legacy sans surfaces reste valide.

### Non-objectifs

- pas d'UI ;
- pas de rendu runtime ;
- pas de migration automatique ;
- pas de suppression de `ProjectPathPreset`.

---

## Lot S2 — Import atlas natif PokeMap

### But

Permettre à l'éditeur de créer un `SurfaceAtlas` depuis une image, sans Tiled.

### Fichiers à créer

```text
packages/map_editor/lib/src/application/services/surface_atlas_importer.dart
packages/map_editor/lib/src/application/models/surface_atlas_import_result.dart
packages/map_editor/lib/src/application/use_cases/import_surface_atlas_use_case.dart
packages/map_editor/test/surface_atlas_importer_test.dart
packages/map_editor/test/import_surface_atlas_use_case_test.dart
```

### Fonctionnalités

L'importeur doit prendre :

```text
imagePath
tileWidth
tileHeight
transparentColor optional
alphaMode
atlasName
```

Il doit produire :

```text
SurfaceAtlas
warnings
computedColumns
computedRows
```

### Règles

- ne pas importer si image introuvable ;
- refuser tile size invalide ;
- warning si dimensions non divisibles ;
- support explicite de `#f05ba1` ;
- copier l'image dans le projet seulement via une action explicite ;
- ne pas modifier silencieusement l'image originale.

### Tests obligatoires

- import image `1536x2080` en `32x32` donne `48x65` ;
- couleur `f05ba1` acceptée ;
- couleur `#f05ba1` acceptée ;
- couleur invalide rejetée ;
- image dimensions non divisibles donne warning ;
- chemin vide rejeté ;
- atlas id normalisé et stable.

---

## Lot S3 — Surface Animation Core + vertical atlas

### But

Créer automatiquement des animations depuis un atlas vertical : colonnes = variantes, lignes = frames.

### Fichiers à créer

```text
packages/map_editor/lib/src/application/services/surface_vertical_animation_builder.dart
packages/map_editor/lib/src/application/models/surface_animation_build_request.dart
packages/map_editor/lib/src/application/models/surface_animation_build_result.dart
packages/map_editor/test/surface_vertical_animation_builder_test.dart
```

### Entrée

```text
atlasId
startColumn
columnCount
startRow
frameCount
defaultDurationMs
syncGroupId
namePrefix
```

### Sortie

```text
SurfaceAnimationSyncGroup
List<SurfaceAnimationDefinition>
```

### Exemple

Pour une image comme l'atlas d'eau vertical :

```text
startColumn = 0
columnCount = 23
startRow = 0
frameCount = 32
defaultDurationMs = 80
syncGroupId = water_main
```

Le builder doit générer :

```text
water_main_variant_00
water_main_variant_01
...
water_main_variant_22
```

Chaque animation contient 32 frames :

```text
frame 0 -> tile(column, row 0)
frame 1 -> tile(column, row 1)
...
frame 31 -> tile(column, row 31)
```

### Tests obligatoires

- génère exactement `columnCount` animations ;
- chaque animation a `frameCount` frames ;
- toutes les frames ont `durationMs = defaultDurationMs` ;
- les coordonnées sont correctes ;
- `syncGroupId` commun ;
- rejet si `frameCount <= 0` ;
- rejet si `columnCount <= 0` ;
- rejet si source dépasse l'atlas ;
- support de durées custom par frame.

---

## Lot S4 — SurfaceLayer V1

### But

Ajouter une vraie couche de surfaces dans les maps.

### Fichiers à modifier

```text
packages/map_core/lib/src/models/map_layer.dart
packages/map_core/lib/src/operations/map_resize.dart
packages/map_core/lib/src/operations/map_layers.dart
packages/map_core/lib/src/validation/validators.dart
packages/map_core/lib/map_core.dart
```

### Fichiers à créer

```text
packages/map_core/lib/src/models/surface_cell_override.dart
packages/map_core/lib/src/operations/map_surface.dart
packages/map_core/test/surface_layer_model_test.dart
packages/map_core/test/map_surface_operations_test.dart
packages/map_core/test/map_resize_surface_layer_test.dart
```

### Changements

Ajouter `MapLayer.surface`.

Stockage recommandé :

```text
surfaceIds: List<String>
```

Règle :

- chaîne vide = aucune surface ;
- string non vide = id de `SurfacePreset` ;
- longueur attendue = `width * height`.

### Tests obligatoires

- sérialisation layer surface ;
- map legacy sans surface OK ;
- resize agrandit correctement `surfaceIds` ;
- resize réduit correctement `surfaceIds` ;
- paint surface sur cellule ;
- erase surface ;
- fill rectangle ;
- replace surface ;
- surface inconnue détectée par validation.

---

## Lot S5 — Runtime Surface Animation Engine

### But

Faire rendre des surfaces animées dans Flame, sans encore créer toute l'UI Surface Studio.

### Fichiers à créer

```text
packages/map_runtime/lib/src/presentation/flame/runtime_surface_catalog.dart
packages/map_runtime/lib/src/presentation/flame/runtime_surface_animation_clock.dart
packages/map_runtime/lib/src/presentation/flame/runtime_surface_frame_resolver.dart
packages/map_runtime/lib/src/presentation/flame/runtime_surface_autotile_resolver.dart
packages/map_runtime/lib/src/presentation/flame/runtime_surface_layer_component.dart
packages/map_runtime/test/runtime_surface_catalog_test.dart
packages/map_runtime/test/runtime_surface_animation_clock_test.dart
packages/map_runtime/test/runtime_surface_frame_resolver_test.dart
packages/map_runtime/test/runtime_surface_layer_component_test.dart
```

### Fichiers à modifier

```text
packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
```

### Stratégie d'intégration

Option recommandée :

- garder `MapLayersComponent` pour legacy terrain/path/tile/entities ;
- ajouter un composant dédié pour les surfaces ;
- contrôler l'ordre de rendu par `SurfaceRenderMode`.

### Tests obligatoires

- frame à `0ms` ;
- frame après une durée ;
- fin de cycle ;
- durées irrégulières ;
- deux animations même sync group donnent même frame index temporel ;
- deux sync groups indépendants peuvent avoir des offsets différents ;
- source rect calculé correctement ;
- filtre pixel art désactivé ;
- atlas manquant ne crashe pas et ne dessine rien ;
- animation manquante produit fallback ou warning contrôlé.

---

## Lot S6 — Surface Autotile Resolver V2

### But

Remplacer la logique path trop limitée par un resolver surface extensible.

### Fichiers à créer

```text
packages/map_core/lib/src/operations/surface_autotile_resolver.dart
packages/map_core/test/surface_autotile_resolver_cardinal_test.dart
packages/map_core/test/surface_autotile_resolver_corner_test.dart
packages/map_core/test/surface_autotile_resolver_wang_like_test.dart
```

### Fonctionnalités V1

- `none` ;
- `cardinal4` ;
- `corner8` ;
- fallback ;
- variantes pondérées ;
- déterminisme via seed ;
- invalidation cellule + voisins.

### Fonctionnalités V2 plus tard

- transitions entre surfaces différentes ;
- Wang edge complet ;
- Wang corner complet ;
- multi-material terrain ;
- variations saisonnières.

### Tests obligatoires

- centre plein ;
- bord nord ;
- bord est ;
- bord sud ;
- bord ouest ;
- coins externes ;
- coins internes ;
- isolé ;
- fallback si variante absente ;
- choix pondéré déterministe ;
- surface voisine différente n'est pas `same`.

---

## Lot S7 — Surface Studio V1

### But

Créer l'UI no-code permettant de gérer les surfaces.

### Fichiers à créer

```text
packages/map_editor/lib/src/features/surfaces/application/surface_studio_controller.dart
packages/map_editor/lib/src/features/surfaces/application/surface_studio_state.dart
packages/map_editor/lib/src/features/surfaces/application/surface_studio_selectors.dart
packages/map_editor/lib/src/ui/canvas/surface_studio/surface_studio_workspace.dart
packages/map_editor/lib/src/ui/canvas/surface_studio/surface_studio_shell.dart
packages/map_editor/lib/src/ui/canvas/surface_studio/surface_atlas_panel.dart
packages/map_editor/lib/src/ui/canvas/surface_studio/surface_animation_panel.dart
packages/map_editor/lib/src/ui/canvas/surface_studio/surface_autotile_panel.dart
packages/map_editor/lib/src/ui/canvas/surface_studio/surface_behavior_panel.dart
packages/map_editor/lib/src/ui/canvas/surface_studio/surface_preview_panel.dart
packages/map_editor/lib/src/ui/canvas/surface_studio/surface_diagnostics_panel.dart
packages/map_editor/lib/src/app/providers/surfaces/surface_studio_providers.dart
```

### Tests à créer

```text
packages/map_editor/test/surface_studio_controller_test.dart
packages/map_editor/test/surface_studio_workspace_test.dart
packages/map_editor/test/surface_atlas_panel_test.dart
packages/map_editor/test/surface_animation_panel_test.dart
packages/map_editor/test/surface_autotile_panel_test.dart
packages/map_editor/test/surface_preview_panel_test.dart
```

### Critères UX

L'utilisateur doit pouvoir :

1. importer une image ;
2. voir la grille ;
3. créer une animation verticale ;
4. prévisualiser l'animation ;
5. créer une surface `Water` ;
6. mapper les variantes ;
7. voir les variantes manquantes ;
8. tester sur une mini-map ;
9. sauvegarder ;
10. utiliser la surface dans une map.

---

## Lot S8 — Water V1 produit

### But

Livrer un premier cas produit complet : eau animée utilisable sur une map.

### Données à créer dans fixtures

```text
packages/map_core/test/fixtures/surfaces/water_vertical_atlas_project.json
packages/map_runtime/test/fixtures/surfaces/water_runtime_project.json
```

### Fichiers runtime/editor à ajuster

Selon les lots précédents.

### Critères d'acceptation

- atlas vertical d'eau importable ;
- animations générées ;
- sync group partagé ;
- surface `Water` créée ;
- variants centre/bords/coins mappés ;
- rendu Flame animé ;
- preview éditeur animée ;
- aucun recours à Tiled ;
- aucun TSX requis ;
- aucun comportement surf automatique imposé ;
- possibilité de créer une zone surf séparée.

---

## Lot S9 — Tall Grass V1 produit

### But

Livrer hautes herbes propres : visuel + overlay + animation locale + intégration encounter explicite.

### Besoins

- surface `TallGrass` ;
- render mode `overActorFeet` ;
- animation one-shot sur entrée ou pas ;
- preview avec player ;
- suggestion de zone encounter ;
- pas de rencontre automatique sans zone.

### Fichiers possibles

```text
packages/map_runtime/lib/src/presentation/flame/runtime_surface_actor_overlay_component.dart
packages/map_runtime/lib/src/application/surface_actor_interaction_runtime.dart
packages/map_gameplay/lib/src/surface_interaction.dart
```

### Tests obligatoires

- marcher dans une herbe déclenche animation cellule ;
- l'animation ne déclenche pas toute la couche ;
- deux cellules peuvent être à des frames différentes ;
- l'overlay masque seulement les pieds selon configuration ;
- encounter zone séparée continue de fonctionner ;
- sans encounter zone, aucune rencontre ne se déclenche.

---

## Lot S10 — Migration legacy Path -> Surface

### But

Permettre de convertir les anciens projets.

### Fichiers à créer

```text
packages/map_core/lib/src/io/surface_legacy_migration.dart
packages/map_editor/lib/src/application/use_cases/migrate_legacy_paths_to_surfaces_use_case.dart
packages/map_editor/test/migrate_legacy_paths_to_surfaces_use_case_test.dart
packages/map_core/test/surface_legacy_migration_test.dart
```

### Critères

- migration non destructive par défaut ;
- rapport détaillé ;
- IDs conservés autant que possible ;
- paths water deviennent surfaces water ;
- paths tall grass deviennent surfaces tall grass ;
- triggers conservés ou signalés ;
- aucun projet existant cassé.

---

## Lot S11 — Optimisation et golden maps

### But

Stabiliser perf et rendu.

### À faire

- culling caméra ;
- cache statique ;
- mesure FPS debug ;
- golden sample map avec eau + herbe haute ;
- tests de non-régression sur frame resolver ;
- tests de rendu source rect ;
- tests grandes maps.

### Critères

- grande map avec surfaces animées reste fluide ;
- pas de filtrage flou ;
- pas de jitter visible ;
- pas de désynchronisation eau ;
- pas de mutation du state projet pendant le rendu.

---

## 15. Tests globaux à prévoir

### map_core

```text
surface_atlas_model_test.dart
surface_animation_model_test.dart
surface_autotile_model_test.dart
surface_preset_model_test.dart
surface_layer_model_test.dart
surface_validation_test.dart
surface_autotile_resolver_cardinal_test.dart
surface_autotile_resolver_corner_test.dart
surface_animation_resolver_test.dart
surface_legacy_migration_test.dart
```

### map_editor

```text
surface_atlas_importer_test.dart
surface_vertical_animation_builder_test.dart
surface_studio_controller_test.dart
surface_studio_workspace_test.dart
surface_atlas_panel_test.dart
surface_animation_panel_test.dart
surface_autotile_panel_test.dart
surface_preview_panel_test.dart
migrate_legacy_paths_to_surfaces_use_case_test.dart
```

### map_runtime

```text
runtime_surface_catalog_test.dart
runtime_surface_animation_clock_test.dart
runtime_surface_frame_resolver_test.dart
runtime_surface_autotile_resolver_test.dart
runtime_surface_layer_component_test.dart
runtime_surface_water_animation_test.dart
runtime_surface_tall_grass_interaction_test.dart
```

### map_gameplay

```text
surface_movement_zone_integration_test.dart
surface_encounter_zone_integration_test.dart
surface_tall_grass_no_implicit_encounter_test.dart
surface_water_no_implicit_surf_test.dart
```

---

## 16. Exemple de manifest cible

Exemple simplifié pour une eau animée.

```json
{
  "surfaceAtlases": [
    {
      "id": "hgss_water_atlas",
      "name": "HGSS Water Atlas",
      "relativePath": "assets/surfaces/hgss_water.png",
      "tileWidth": 32,
      "tileHeight": 32,
      "columns": 23,
      "rows": 32,
      "transparentColor": "#f05ba1",
      "alphaMode": "colorKey",
      "layoutHints": ["verticalAnimationAtlas"]
    }
  ],
  "surfaceAnimationSyncGroups": [
    {
      "id": "water_main",
      "name": "Water Main",
      "clockMode": "globalMapClock",
      "phaseOffsetMs": 0
    }
  ],
  "surfaceAnimations": [
    {
      "id": "water_center",
      "name": "Water Center",
      "syncGroupId": "water_main",
      "playback": "loop",
      "frames": [
        {
          "tile": { "atlasId": "hgss_water_atlas", "x": 0, "y": 0, "width": 1, "height": 1 },
          "durationMs": 80
        },
        {
          "tile": { "atlasId": "hgss_water_atlas", "x": 0, "y": 1, "width": 1, "height": 1 },
          "durationMs": 80
        }
      ]
    }
  ],
  "surfacePresets": [
    {
      "id": "water_hgss",
      "name": "Water HGSS",
      "kind": "water",
      "autotileSetId": "water_hgss_autotile",
      "renderMode": "surfaceOverlay",
      "tags": ["water", "animated"]
    }
  ]
}
```

---

## 17. Risques techniques

### 17.1. Risque : modèle trop générique

Si le modèle essaie de couvrir tous les cas possibles dès le début, il deviendra inutilisable.

Solution : commencer par :

- atlas ;
- animation ;
- sync group ;
- autotile simple ;
- water ;
- tall grass.

Ne pas ouvrir un moteur général de shaders, particules, saisons, météo et transitions multi-biomes au premier lot.

### 17.2. Risque : casser les maps existantes

Solution : ajouter `SurfaceLayer` en parallèle, ne pas remplacer `PathLayer` tout de suite.

### 17.3. Risque : runtime trop lent

Solution : version naïve d'abord, mais architecture prévue pour cache/culling.

### 17.4. Risque : UI trop technique

Solution : le Surface Studio doit parler métier :

- Eau ;
- Herbes hautes ;
- Route ;
- Sable ;
- Glace ;
- Animation ;
- Variante manquante ;
- Prévisualiser.

Éviter dans l'UI principale :

- GID ;
- Wang ID ;
- bitmask brut ;
- source rect brute ;
- tile local ID ;
- jargon Tiled.

Ces termes peuvent exister dans un panneau avancé/debug, pas dans le workflow principal.

### 17.5. Risque : confondre surface et gameplay

Solution : maintenir des zones gameplay explicites.

---

## 18. Ce qu'il ne faut pas faire

Ne pas faire :

- rendre PokeMap dépendant de Tiled ;
- stocker des `wangid` bruts comme modèle canonique ;
- remplacer brutalement `PathLayer` ;
- mettre toute la logique dans `MapLayersComponent` ;
- faire de l'eau un simple élément placé ;
- traiter les hautes herbes comme de l'eau verte ;
- imposer `surf` parce qu'une surface est bleue ;
- déclencher des rencontres parce qu'une surface est verte ;
- copier les limites RMXP ;
- ouvrir trop tôt un système générique de particules / shaders / météo.

---

## 19. Définition de réussite globale

Le chantier sera réussi quand PokeMap permettra de :

1. importer une image de surface sans Tiled ;
2. déclarer une couleur de transparence ;
3. créer des animations depuis des colonnes verticales ;
4. synchroniser toutes les variantes d'eau ;
5. mapper des variantes autotile ;
6. poser une surface eau sur une map ;
7. voir l'eau animée dans l'éditeur ;
8. voir la même eau animée dans le runtime Flame ;
9. poser des hautes herbes ;
10. voir une animation locale quand le joueur marche dedans ;
11. garder les zones gameplay explicites ;
12. migrer les anciens paths sans casser les projets ;
13. conserver un rendu pixel perfect.

---

## 20. Checklist pour agent externe

Si cette spec est confiée à Codex, Qwen ou un autre agent de génération de code, l'agent doit respecter ces règles :

- commencer par un audit du repo réel ;
- signaler toute divergence avec cette spec ;
- ne pas faire de commit ;
- ne pas faire de push ;
- ne pas faire de rebase ;
- ne pas faire de merge ;
- ne pas faire de reset destructeur ;
- limiter chaque lot à son périmètre ;
- produire un rapport markdown complet ;
- lister tous les fichiers créés, modifiés ou supprimés ;
- inclure le contenu complet des fichiers créés ou modifiés dans le rapport si demandé ;
- lancer les tests ciblés ;
- lancer les tests de package si raisonnable ;
- expliquer précisément les tests non lancés ;
- faire une autocritique finale ;
- utiliser une passe de review séparée si possible.

---

## 21. Recommandation finale

La direction canonique recommandée est :

```text
Surface Engine d'abord.
Surface Studio ensuite.
Water V1 comme premier golden slice.
Tall Grass V1 comme deuxième golden slice.
Migration legacy seulement après preuve runtime.
```

Le chantier est important, mais il est justifié. Les surfaces ne sont pas un détail cosmétique dans un Pokémon-like. Elles structurent l'identité visuelle du monde, la lisibilité de la map, les comportements d'exploration, les rencontres sauvages et la sensation de polish.

PokeMap ne doit donc pas bricoler l'eau et les hautes herbes dans l'ancien système de paths. Il doit assumer une vraie brique produit :

```text
Surface Studio + Surface Engine + Tile Animation Engine
```

C'est cette brique qui permettra d'atteindre le niveau de propreté visuelle observé dans Pokémon SDK, tout en gardant une architecture moderne, no-code, maintenable et indépendante de Tiled.
