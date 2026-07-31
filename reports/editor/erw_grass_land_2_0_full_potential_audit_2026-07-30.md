# Audit ERW Grass Land 2.0 v2.1 — exploitation complète dans PokeMap

Date : 30 juillet 2026

Périmètre : bundle local ERW, modèle de données PokeMap, éditeur Flutter et runtime Flame

Nature : audit read-only du produit et du code ; aucun asset ERW importé ou copié

## 1. Verdict exécutif

Oui : le gabarit historique PokeMap `160 × 96` n'est pas le bon modèle universel pour ce bundle.

Il n'est pas intrinsèquement erroné : il correspond au système PokeMap de chemins simples composé de 20 variantes nommées. En revanche, ERW Grass Land 2.0 n'est pas un « path atlas » à faire entrer dans ce gabarit. C'est un petit système Tiled complet, composé de :

- plusieurs tilesets utilisés dans une même carte et parfois dans un même calque ;
- plusieurs couches graphiques superposées dans un ordre précis ;
- 45 Wang sets décrivant des transitions riches ;
- plusieurs candidats visuels pondérés pour une même topologie ;
- 568 tuiles animées ;
- des collections de props de tailles variables ;
- des objets placés librement au pixel et ancrés selon les règles de Tiled ;
- 21 cartes de règles d'Automapping appliquées en plusieurs passes.

Forcer ce système dans `TerrainPathVariant` et dans une image `160 × 96` détruit précisément les informations qui rendent les exemples du bundle beaux : les transitions, les variations, les superpositions, les ancrages, les animations et les règles de composition.

La recommandation centrale est donc :

> Construire un compilateur d'import Tiled → PokeMap, puis ajouter un moteur Wang et un moteur d'objets libres natifs à PokeMap. Tiled reste une source d'import ; le runtime ne dépend jamais de Tiled et continue à exécuter uniquement des données possédées par PokeMap.

Il ne faut ni abandonner PokeMap, ni remplacer tous ses outils existants. Plusieurs fondations sont réutilisables : atlas multi-cases, frames animées, profils de collision, ordre des couches simples, bibliothèque d'éléments, culling et formats JSON. Il faut ajouter un niveau de représentation plus riche à côté des chemins simples actuels.

## 2. Décision produit recommandée

### À arrêter

- recréer manuellement l'herbe et les chemins déjà fournis par ERW ;
- réduire un Wang set à 20 cases fixes ;
- importer uniquement les PNG en ignorant les TSX/TMX ;
- obliger tous les props à s'aligner sur une case entière ;
- considérer qu'un calque de tuiles n'utilise qu'une seule image ;
- demander à l'utilisateur de choisir manuellement des GID ou des fragments techniques d'atlas.

### À conserver

- la grille logique de projet `32 × 32` pour ce bundle ;
- les anciens Path/Surface/Terrain Studio pour les projets et assets simples ;
- les `TilesetSourceRect` multi-cases ;
- les frames et durées déjà sérialisables ;
- les `ProjectElementEntry` et leurs profils de collision ;
- les catégories et dossiers de la bibliothèque ;
- l'ordre, la visibilité et l'opacité des couches existantes ;
- le culling du runtime ;
- le principe architectural selon lequel PokeMap possède et exécute ses propres données.

### À construire

Deux capacités complémentaires :

1. **Fidélité d'import** : lire les métadonnées Tiled et compiler les samples ERW en cartes PokeMap visuellement identiques.
2. **Fidélité d'authoring** : permettre ensuite de peindre dans PokeMap avec les Wang sets et les règles ERW, sans manipuler les tuiles techniques à la main.

## 3. Périmètre audité

### Bundle

- `/Users/karim/Downloads/ERW - Grass Land 2.0 v2.1`
- `/Users/karim/Downloads/ERW - Grass Land 2.0 v2.1/TiledMap Editor`
- `/Users/karim/Downloads/ERW - Grass Land 2.0 v2.1/Tilesets`

Les deux dossiers initialement cités ne sont pas autonomes. Quatre TSX sont des collections d'images et référencent également le dossier :

- `/Users/karim/Downloads/ERW - Grass Land 2.0 v2.1/Props`

Le bundle complet a donc été pris en compte.

### PokeMap

- `packages/map_core`
- `packages/map_editor`
- `packages/map_runtime`
- rapports historiques relatifs à Surface Studio et à l'ancien import TSX

### Références officielles

- [Terrains et Wang sets de Tiled](https://doc.mapeditor.org/en/stable/manual/terrain/)
- [Global Tile IDs et transformations](https://doc.mapeditor.org/en/stable/reference/global-tile-ids/)
- [Couches Tiled](https://doc.mapeditor.org/en/stable/manual/layers/)
- [Objets Tiled](https://doc.mapeditor.org/en/stable/manual/objects/)
- [Automapping Tiled](https://doc.mapeditor.org/en/stable/manual/automapping/)
- [Format de carte Tiled](https://doc.mapeditor.org/en/stable/reference/json-map-format/)

## 4. Méthode

L'audit a combiné :

- inventaire récursif des fichiers ;
- parsing XML des TMX et TSX ;
- résolution des références relatives ;
- décodage de tous les PNG et GIF ;
- inspection des Wang sets, probabilités, animations, collisions et GID ;
- analyse des calques et objets des cartes exemples ;
- rendu local des deux principales cartes de démonstration ;
- inspection visuelle de l'éditeur PokeMap en cours d'exécution ;
- lecture ciblée des modèles, validateurs, painters et renderers PokeMap ;
- lecture de l'historique Git de l'ancien Surface Studio ;
- tests de caractérisation ciblés ;
- trois passes indépendantes : bundle, éditeur/modèles et runtime.

Le logiciel Tiled n'était pas installé sur la machine. L'Automapping a donc été audité statiquement, mais pas exécuté dans Tiled.

## 5. Inventaire complet du bundle

### 5.1 Répartition générale

| Élément | Fichiers | Volume |
|---|---:|---:|
| `Characters` | 168 | 2 199 407 octets |
| `Mockups` | 29 | 12 067 971 octets |
| `Props` | 1 581 | 5 474 449 octets |
| `TiledMap Editor` | 64 | 1 040 087 octets |
| `Tilesets` | 4 076 | 11 343 437 octets |
| `TILED RANDOM TIPS.txt` | 1 | 2 795 octets |
| **Total** | **5 919** | **32 128 146 octets** |

### 5.2 Extensions

| Type | Nombre |
|---|---:|
| PNG | 5 823 |
| GIF | 27 |
| TMX | 24 |
| TSX | 38 |
| TXT | 6 |
| `.DS_Store` | 1 |

Les 62 XML TMX/TSX sont syntaxiquement valides. Les 5 850 rasters sont décodables.

### 5.3 Références

- 1 414 références XML de fichiers externes ont été résolues sans cible manquante.
- 21 chemins de cartes de règles listés dans `rules.txt` ont également été résolus après normalisation des séparateurs Windows.
- Le total est donc de 1 435 références de fichiers résolues.
- 14 références supplémentaires de la forme `:/automap-tiles.tsx` sont des ressources internes virtuelles utilisées par Tiled dans les cartes de règles ; elles ne doivent pas être signalées comme fichiers absents.
- 1 324 images référencées se trouvent sous `Props`.
- Importer seulement `Tilesets` ou seulement `TiledMap Editor` casserait donc les collections d'images.

### 5.4 Doublons

L'analyse SHA-256 a trouvé :

- 824 groupes de doublons ;
- 2 153 fichiers impliqués ;
- environ 1 653 172 octets de redondance.

L'importeur devra dédupliquer les binaires par hash tout en conservant les alias sémantiques, les identifiants de tuile et la provenance.

## 6. Anatomie technique du bundle

### 6.1 Cartes

Les 24 TMX sont :

- orthogonaux ;
- finis ;
- en grille `32 × 32` ;
- stockés en CSV non compressé ;
- sans chunks de carte infinie.

Cette base est directement compatible avec les hypothèses fondamentales de PokeMap.

### 6.2 Principales cartes exemples

| Carte | Taille | Tilesets | Tile layers | Object layers | Objets | Cellules non vides |
|---|---:|---:|---:|---:|---:|---:|
| `TiledMap Editor Example - grass land 2.0.tmx` | `80 × 80` | 19 | 6 | 1 | 19 | 3 928 |
| `Sample map.tmx` | `30 × 20` | 11 | 8 | 4 | 99 | 1 452 |

`Sample map.tmx` et `Sample map - Copia.tmx` sont identiques octet par octet.

### 6.3 Ordre de composition du sample

Le rendu de `Sample map.tmx` alterne les types de contenu :

1. terrain herbe de base ;
2. ombre supplémentaire du terrain ;
3. terre, gravier et variations ;
4. rivière ;
5. dernier niveau de terrain ;
6. ombres d'arbres en object layer ;
7. trous ;
8. murs ;
9. entrée de mine ;
10. props niveau 0 ;
11. props niveau 1 ;
12. props niveau 2.

La fidélité ne dépend donc pas seulement de « plusieurs couches ». Elle exige de préserver l'alternance exacte entre tile layers et object layers.

### 6.4 Mixed GID

Le grand exemple utilise plusieurs TSX dans chacun de ses six tile layers. Le calque `terrain0` en utilise six.

Les petits samples ont également des calques mixtes. `last terrain level`, par exemple, combine du terrain et des props provenant de plusieurs sources.

Une cellule Tiled contient un GID global. `firstgid` permet de déterminer le TSX et l'identifiant local correspondants. PokeMap ne peut pas convertir correctement ces données en gardant seulement :

```text
TileLayer.tilesetId + List<int> tiles
```

### 6.5 Wang sets

| Élément Wang | Nombre |
|---|---:|
| Wang sets | 45 |
| Wang colors | 85 |
| Wang tile associations | 3 694 |
| Sets de type `corner` | 42 |
| Sets de type `edge` | 1 |
| Sets de type `mixed` | 2 |

Le seul `Tileset-Terrain-new grass.tsx` contient :

- 10 Wang sets ;
- 38 couleurs Wang ;
- 1 594 associations ;
- jusqu'à 13 matériaux/couleurs au sein d'un même set.

Il encode notamment l'herbe, l'ombre d'herbe, la terre, le gravier, le sable, la pierre, des murs et leurs transitions.

Le `wangid` Tiled est une signature à huit positions alternant coins et arêtes. Il peut représenter des transitions qu'un simple masque cardinal à quatre bits ne distingue pas.

### 6.6 Variantes pondérées

706 tuiles déclarent une probabilité :

- 174 ont un poids positif ;
- 532 ont explicitement une probabilité `0` et ne doivent pas être choisies aléatoirement.

Ces probabilités ne sont pas décoratives. Elles servent à casser la répétition et à choisir les bonnes variantes sans produire un terrain qui change à chaque redraw.

Le choix doit être stable et déterministe, seedé au minimum par :

```text
projectId + mapId + logicalLayerId + terrainSetId + x + y
```

### 6.7 Animations

| Élément | Nombre |
|---|---:|
| Tuiles animées | 568 |
| Frames | 6 271 |
| Animations de 8 frames | 352 |
| Animations de 16 frames | 215 |
| Animation de 15 frames | 1 |
| Durée rencontrée | 100 ms par frame |

Les exemples utilisent réellement ces animations :

- 123 cellules animées dans chacun des petits samples ;
- 450 cellules animées dans le grand exemple.

Une horloge synchronisée est nécessaire pour les surfaces continues comme l'eau. Des instances lancées avec des phases différentes créeraient des coutures visuelles.

### 6.8 Collections d'images

Quatre TSX sont des collections d'images et totalisent 1 318 entrées de tailles variables.

| Collection | Entrées | Taille maximale |
|---|---:|---:|
| `Atlas-Props-sheet1-sprites.tsx` | 639 | `192 × 224` |
| `Atlas-Props-sheet2-sprites.tsx` | 297 | `352 × 288` |
| `Atlas-props-sheet3-sprites.tsx` | 60 | `544 × 320` |
| `Atlas-Props-sheet4-sprites.tsx` | 322 | `96 × 64` |

Les dimensions sont multiples de 32, ce qui permet un packing sans rééchantillonnage. En revanche, les images ne peuvent pas être interprétées comme une feuille régulière unique avant ce packing.

### 6.9 Objets libres

Dans les cartes exemples :

- 217 objets sont des tile objects ;
- 144 ont une taille différente de `32 × 32` ;
- 200 sur 217 ne sont pas positionnés sur une coordonnée strictement multiple de 32 ;
- certains dépassent les limites de la map ou utilisent une coordonnée X négative ;
- des ombres utilisent également des positions libres.

Le sample contient des props allant jusqu'à `544 × 288`.

Quatre occurrences de flip horizontal sont présentes dans les deux copies du petit sample. Même si les rotations libres, flips verticaux et diagonaux ne sont pas utilisés ici, le décodage correct des bits de transformation d'un GID évite de produire une importation silencieusement fausse.

### 6.10 Automapping

`rules.txt` référence 21 cartes de règles, organisées en sept familles et trois passes :

1. effacement ou remise à zéro ;
2. placement des tuiles principales ;
3. application des variations.

Les règles emploient notamment :

- `MatchInOrder=true` ;
- `AutomappingRadius=4` ;
- des object layers `rule_options` ;
- 34 zones avec `Probability` ;
- 14 zones avec `Disabled` ;
- des offsets de calques ;
- des opacités différentes de `1`.

Les séparateurs Windows `\` présents dans `rules.txt` devront être normalisés lors de l'import sur macOS et Linux.

### 6.11 Collisions

Le bundle ne contient que huit définitions de collision, réparties dans deux tilesets de murs. Ce sont des rectangles simples.

Elles sont importables sans perte, mais elles ne suffisent pas à rendre automatiquement l'ensemble du bundle jouable. L'éditeur de collision PokeMap restera nécessaire pour les bâtiments, arbres, props et obstacles qui n'ont pas de métadonnées de collision.

### 6.12 Assets non décrits par les TSX

Les TSX ne référencent que 1 352 des 5 823 PNG :

- 1 324 sous `Props` ;
- 28 sous `Tilesets`.

Restent en dehors de la bibliothèque Tiled :

- environ 4 046 images sous `Tilesets`, principalement des frames ou exports individuels ;
- 256 props ;
- 167 assets de personnages ;
- deux mockups PNG ;
- 27 mockups GIF.

Un import « bundle complet » devra donc distinguer :

- le noyau Tiled structuré, exploitable automatiquement ;
- les assets libres supplémentaires, importables dans une bibliothèque secondaire ;
- les mockups, à conserver comme références et non comme ressources runtime.

## 7. Ce que PokeMap sait déjà faire

| Capacité | État |
|---|:---:|
| Map orthogonale et finie | Complet |
| Grille projet `32 × 32` | Complet pour ERW |
| Plusieurs tilesets dans le manifest | Complet |
| Plusieurs tile layers | Complet |
| Ordre simple, visibilité et opacité | Complet |
| Source rect multi-case | Complet |
| Éléments multi-cases | Complet |
| Frames et durées d'élément/preset | Complet |
| Profils de collision pixel/cellule | Complet |
| Transparence/chroma | Complet |
| Culling du viewport | Complet |
| Découpage des grandes images runtime | Suffisant pour les plus grandes feuilles ERW |
| Variations stables de certains terrains natifs | Partiel mais réutilisable |

Ces capacités réduisent fortement le travail : il n'est pas nécessaire de reconstruire un moteur de map entier.

## 8. Écarts actuels dans les modèles

### 8.1 Une seule source par tile layer

`packages/map_core/lib/src/models/map_layer.dart:48-56`

`TileLayer` stocke :

- un unique `tilesetId` ;
- une liste plate de `int`.

Il ne peut pas représenter un GID Tiled, son TSX d'origine ni ses bits de flip.

### 8.2 ObjectLayer vide

`packages/map_core/lib/src/models/map_layer.dart:101-107`

`ObjectLayer` ne stocke aucun objet. La composition le transforme en no-op :

- `packages/map_core/lib/src/operations/map_visual_composition.dart:340-355`
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:358-360`

Le validateur interdit même aujourd'hui d'associer un `MapPlacedElement` à un `ObjectLayer` :

- `packages/map_core/lib/src/validation/validators.dart:1796-1828`

### 8.3 Placements limités à la grille

`packages/map_core/lib/src/models/map_data.dart:139-157`

`MapPlacedElement` possède :

- `GridPos pos` ;
- `quarterTurns` ;
- collision, opacité, animation, ombre et propriétés.

Il ne possède pas :

- de position pixel ou fixed-point ;
- d'offset ;
- d'ancre ;
- de taille d'affichage ;
- d'échelle ;
- de flip ;
- de rotation libre ;
- de z-index explicite.

### 8.4 Tileset sans métadonnées de tuile

`packages/map_core/lib/src/models/project_manifest.dart:664-685`

`ProjectTilesetEntry` ne stocke pas :

- les dimensions de tuile propres au TSX ;
- le nombre de colonnes ;
- margin/spacing ;
- tile offset ou object alignment ;
- les définitions par tile ID ;
- les animations ;
- les probabilités ;
- les collisions ;
- les Wang sets.

Les paramètres de grille sont globaux au projet :

- `packages/map_core/lib/src/models/project_manifest.dart:545-565`

Cela suffit pour ERW en `32 × 32`, mais pas pour un importeur Tiled généraliste.

### 8.5 Resolver de chemin trop pauvre

`TerrainPathVariant` contient exactement 20 valeurs :

- `packages/map_core/lib/src/models/enums.dart:195-216`

Le resolver principal utilise un masque cardinal à quatre bits :

- `packages/map_core/lib/src/operations/map_terrain_autotile.dart:22-41`

Les diagonales ne distinguent que le cas où les quatre voisins cardinaux existent et où exactement une diagonale manque :

- `packages/map_core/lib/src/operations/map_terrain_autotile.dart:124-173`

Le fallback historique `4 × 4` associe même plusieurs coins intérieurs et la croix à la même case :

- `packages/map_editor/lib/src/application/models/path_autotile_set.dart:48-59`
- `packages/map_editor/lib/src/application/models/path_autotile_set.dart:72-74`

Ce modèle doit rester disponible comme « chemin simple », pas devenir un pseudo-Wang set.

## 9. Écarts actuels dans l'éditeur

### 9.1 Mauvais point d'entrée d'import

L'import tileset actuel accepte une image :

- PNG ;
- JPG/JPEG ;
- WebP ;
- BMP.

Preuve :

- `packages/map_editor/lib/src/application/use_cases/project_tileset_use_cases.dart:61-68`

Il ne lit actuellement ni TMX, ni TSX, ni Wang set, ni `firstgid`, ni Automapping.

Le workflow « une image = un tileset » supprime les métadonnées les plus précieuses du bundle.

### 9.2 Palette et métriques basées sur une feuille régulière

Les métriques déduisent la grille par division de l'image :

- `packages/map_editor/lib/src/ui/canvas/tileset_grid_metrics.dart:11-26`

Le canvas et la palette utilisent la taille de tuile du projet :

- `packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart:97-102`
- `packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart:471-474`

Cette logique est correcte pour une feuille régulière normalisée, mais pas pour une collection TSX avant packing.

### 9.3 Atlas builder réutilisable mais incomplet

`TilesetAtlasBuilder` sait déjà :

- assembler des items alignés ;
- détecter les chevauchements ;
- vérifier un budget d'atlas.

Preuve :

- `packages/map_editor/lib/src/application/services/tileset_atlas_builder.dart:8-109`

Il manque :

- un bin-packer automatique déterministe ;
- le découpage en plusieurs atlas ;
- le mapping stable `TSX localTileId → atlas + rect` ;
- les ancres et métadonnées par entrée ;
- la déduplication par hash.

### 9.4 Raw tile layers non animés

Le painter calcule directement le source rect à partir de `tileId - 1` et ne consulte aucune timeline de tuile :

- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:1789-1868`

Le moteur de timeline existe déjà pour d'autres previews et peut être généralisé :

- `packages/map_core/lib/src/operations/tile_visual_frame_timeline.dart:72-127`

### 9.5 Ordre des objets

Le painter parcourt les `placedElements` dans leur ordre sérialisé :

- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:1959-1976`

Il n'existe aucun tri `topdown` basé sur l'ancre Y comparable à celui d'un object layer Tiled.

## 10. Écarts actuels dans le runtime

### 10.1 Résolution naïve des tuiles

Le runtime choisit une seule image pour le calque, puis calcule une case par :

```text
localId = tileId - 1
column = localId % columns
row = localId ~/ columns
```

Preuve :

- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:654-755`

Ce chemin ne peut pas préserver :

- `firstgid` ;
- plusieurs tilesets dans une couche ;
- les flips GID ;
- les collections d'images ;
- les animations génériques par tile ID ;
- margin/spacing ou tile offset.

### 10.2 Placements non tournés visuellement

Le modèle possède `quarterTurns`, mais le rendu dessine encore le source rect sans appliquer cette rotation :

- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:791-848`

Cela n'est pas le blocage principal ERW, mais devient dangereux si la collision est tournée alors que le sprite ne l'est pas.

### 10.3 Animation partielle mais bonne fondation

`RuntimePathAutotileSet` sait déjà :

- lire plusieurs frames ;
- respecter leurs durées ;
- utiliser un override de tileset par frame.

Preuve :

- `packages/map_runtime/lib/src/presentation/flame/runtime_path_autotile.dart:3-143`

Cette logique doit être généralisée à une table d'animation par identifiant local de tuile.

### 10.4 Performance

Le runtime dispose d'un culling avec marge :

- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:119-160`

En revanche, il effectue essentiellement un `drawImageRect` par tuile visible et le cache d'images ne constitue pas une politique complète d'éviction.

Décoder l'ensemble des 4 074 PNG du dossier `Tilesets` représenterait environ 135,19 Mio en RGBA avant overhead. Il ne faut pas charger les exports individuels à l'aveugle.

## 11. Historique de l'ancien import TSX

Un import TSX existait autrefois dans Surface Studio, mais il a été supprimé par :

```text
50476c67f Remove Surface Studio authoring UI
```

Cette suppression a retiré notamment :

- `tiled_tsx_animated_tileset_parser.dart` ;
- `tiled_tsx_animation_browser.dart` ;
- `tiled_tsx_surface_animation_importer.dart` ;
- leurs vues et tests.

Le rapport `reports/surface/surface_studio_purge_v0.md` confirme que Surface Studio n'est plus exposé.

Il ne faut donc pas conclure que l'import TSX existe encore.

Même restauré tel quel, l'ancien import était centré sur les animations de spritesheet. Il ne couvrait pas les TMX, les Wang sets, les mixed GID, les collections d'images ni l'Automapping. Il peut fournir des idées de parsing XML et de timeline, mais pas l'architecture cible.

## 12. Matrice de compatibilité complète

Légende :

- **Complet** : utilisable sans perte pertinente pour ERW ;
- **Partiel** : fondation existante, conversion ou extension requise ;
- **Manquant** : information impossible à représenter fidèlement ;
- **Différé** : utile pour Tiled en général, absent du bundle.

| Fonction ERW/Tiled | PokeMap actuel | Priorité | Verdict |
|---|---|:---:|---|
| Grille orthogonale `32 × 32` | Grille globale configurable | — | Complet |
| Maps finies | `GridSize` fini | — | Complet |
| Plusieurs tilesets dans le projet | Manifest multi-tilesets | — | Complet |
| Plusieurs tile layers | Modèle et rendu existants | — | Complet |
| Visibilité/opacité | Sérialisées et rendues | — | Complet |
| Ordre exact au sein des seuls tile layers | Ordre simple partagé, mais incomplet dès qu'un ObjectLayer s'intercale | P0 | Partiel |
| Alternance tile/object layers | ObjectLayer no-op | P0 | Manquant |
| Plusieurs tilesets dans une couche | Un `tilesetId` par couche | P0 | Manquant |
| `firstgid`/GID global | ID local supposé | P0 | Manquant |
| Flip horizontal GID | Pas de bit de transformation | P0 | Manquant |
| Props multi-cases | Source rect et élément multi-case | P0 | Partiel |
| Position pixel/sous-case | `GridPos` entier | P0 | Manquant |
| Position négative/hors map | Validation orientée grille | P0 | Manquant |
| Ancre de tile object | Pas de modèle d'ancre | P0 | Manquant |
| Draw order `topdown` | Ordre sérialisé | P0 | Manquant |
| Collection d'images TSX | Feuille régulière attendue | P0 | Manquant |
| Atlas packing | Builder manuel existant | P0 | Partiel |
| Animations par tile ID | Frames sur presets/éléments seulement | P0 | Manquant |
| Horloge synchronisée | Timeline réutilisable | P0 | Partiel |
| Collisions TSX | Profils PokeMap existants, import absent | P0 | Partiel |
| Wang `corner` | 20 rôles fixes | P1 | Manquant |
| Wang `edge` | 20 rôles fixes | P1 | Manquant |
| Wang `mixed` | 20 rôles fixes | P1 | Manquant |
| Plusieurs matériaux Wang | Aucun modèle | P1 | Manquant |
| Candidats pondérés | Poids terrain partiels | P1 | Partiel |
| Sélection déterministe | Stable random partiel | P1 | Partiel |
| Automapping multi-passes | Aucun moteur | P1 | Manquant |
| `MatchInOrder` | Aucun moteur | P1 | Manquant |
| `rule_options` | Aucun moteur | P1 | Manquant |
| Import/reimport avec diff | Aucun wizard | P1 | Manquant |
| Margin/spacing | Non modélisés | P2 | Différé pour ERW |
| Tile offset/object alignment générique | Non modélisés | P2 | Différé pour ERW |
| Group layers | Non modélisés | P2 | Différé |
| Image layers | Non modélisés | P2 | Différé |
| Parallaxe/tint/blend | Non modélisés | P2 | Différé |
| Infinite maps/chunks | Non modélisés | P2 | Différé |
| Base64/compression | Non importés | P2 | Différé |
| Polygones/ellipses/textes | Non importés | P2 | Différé |
| Classes/templates/propriétés typées | Non importés | P2 | Différé |
| Culling | Présent | P2 | Complet |
| Batching/cache statique | Un draw par tuile | P2 | Partiel |
| Cycle de vie des textures | Cache sans budget complet | P2 | Partiel |

## 13. Architecture cible

### 13.1 Principe de frontière

```text
Dossier ERW
   │
   ▼
Scanner et parseur XML dans map_editor
   │
   ▼
TiledImportPlan validé et prévisualisé
   │
   ▼
Compilateur d'assets et de maps
   │
   ├── PNG/atlas possédés par PokeMap
   ├── manifest JSON PokeMap
   └── maps JSON PokeMap
   │
   ▼
map_core valide ──► map_editor affiche ──► map_runtime exécute
```

Le runtime ne lit ni TMX ni TSX. Le parseur XML appartient à l'infrastructure de `map_editor`. Les contrats persistés et validés appartiennent à `map_core`.

### 13.2 Représentation riche d'une cellule

Le schéma recommandé utilise une palette locale au calque afin d'éviter un objet JSON complet par cellule :

```text
TileCellPaletteEntry
├── tilesetId
├── localTileId
├── flipHorizontal
├── flipVertical
└── flipDiagonal

RichTileLayer
├── palette[]
└── cells[]  // index dans palette, 0 = vide
```

Cette représentation :

- préserve le mixed GID ;
- préserve l'ordre de parcours du calque ;
- reste compacte ;
- permet de résoudre les animations par `tilesetId + localTileId` ;
- prépare les transformations Tiled.

#### Pourquoi ne pas simplement scinder les calques par tileset ?

La scission automatique peut servir de fallback temporaire pour des couches composées uniquement de tuiles `32 × 32` sans dépassement.

Elle n'est pas fidèle en général : un tile layer ERW peut mélanger des props surdimensionnés provenant de plusieurs TSX. Scinder la couche change alors l'ordre relatif de dessin et peut modifier les chevauchements. Le modèle riche par cellule est donc la cible P0 correcte.

### 13.3 Définition native d'une tuile

```text
ProjectTileDefinition
├── localTileId
├── visualSource
├── probability
├── animationFrames[]
├── collisionShapes[]
├── wangMemberships[]
└── importedProperties
```

`visualSource` doit accepter :

- une case d'une feuille ;
- une région d'atlas généré ;
- éventuellement une image autonome pendant la phase d'import, avant packing.

### 13.4 Object layers réels

```text
MapVisualObject
├── id
├── layerId
├── source
├── positionPx
├── displaySizePx
├── anchor
├── transform
├── opacity
├── serializedOrder
└── properties
```

Pour ERW, il faut au minimum :

- coordonnées décimales ou fixed-point ;
- position négative autorisée ;
- ancre de tile object Tiled correctement convertie ;
- taille arbitraire ;
- flip horizontal ;
- ordre sérialisé ;
- mode `topdown` trié sur la coordonnée Y de l'ancre ;
- possibilité de conserver un ordre explicite.

Les collisions gameplay peuvent continuer à utiliser une empreinte de grille distincte du placement visuel.

### 13.5 Wang set natif

```text
ProjectWangSet
├── type: corner | edge | mixed
├── colors/materials[]
├── candidatesBySignature
└── deterministicSeedPolicy

WangCandidate
├── tilesetId
├── localTileId
├── wangId[8]
└── weight
```

Il ne faut pas étendre `TerrainPathVariant` avec des dizaines ou centaines de valeurs. La signature Wang doit rester générique.

### 13.6 Automapping

Les règles Tiled doivent être compilées vers un format PokeMap maîtrisé :

```text
CompiledMapRule
├── family
├── passIndex
├── inputPatterns[]
├── outputPatterns[]
├── matchInOrder
├── radius
├── probability
└── enabled
```

Le moteur doit appliquer les passes dans l'ordre et fournir une graine stable.

## 14. Expérience éditeur recommandée

### 14.1 Nouveau point d'entrée

Ajouter :

> **Importer un bundle Tiled**

Le wizard doit scanner le dossier avant toute écriture et afficher :

- cartes, TSX et images trouvés ;
- références résolues ou cassées ;
- Wang sets ;
- animations ;
- collections d'images ;
- objets hors grille ;
- collisions ;
- règles d'Automapping ;
- fonctionnalités non prises en charge ;
- estimation du nombre d'atlas générés ;
- doublons détectés ;
- provenance/licence à renseigner.

### 14.2 Import plan

Avant de cliquer sur « Importer », l'utilisateur voit un plan :

| Niveau | Exemple |
|---|---|
| Bloquant | TSX absent, XML invalide, GID non résolu |
| Avertissement de fidélité | propriété Tiled ignorée |
| Information | image dédupliquée, atlas n°2 créé |

L'import ne doit jamais produire silencieusement une map « à peu près correcte ».

### 14.3 Prévisualisation

Afficher côte à côte :

- rendu de référence compilé depuis le TMX ;
- rendu PokeMap ;
- heatmap ou liste des différences ;
- compteur d'objets, couches et cellules importés.

Le temps d'animation et la graine doivent être figés pendant la comparaison.

### 14.4 Authoring sémantique

L'utilisateur ne devrait pas choisir un GID brut.

Il choisit :

- Herbe principale ;
- Ombre d'herbe ;
- Terre ;
- Gravier ;
- Rivière ;
- Côte ;
- Mur ;
- Trou ;
- Clôture ;
- etc.

Le brush Wang choisit les candidats et met à jour le voisinage.

Pour les murs et trous pilotés par règles, un outil sémantique applique automatiquement les couches techniques.

### 14.5 Couches logiques

Les éventuelles sous-couches techniques doivent être regroupées sous un calque logique afin de ne pas exposer la plomberie du compilateur.

Le panneau de couches doit distinguer explicitement :

- plan inférieur ;
- terrain ;
- objets triés par Y ;
- plan supérieur ;
- collision/gameplay.

Éviter les heuristiques fondées sur des noms comme `foreground` ou `roof`.

### 14.6 Reimport

Le reimport doit être :

- idempotent ;
- guidé par hashes et identifiants stables ;
- précédé d'un diff ;
- capable de préserver les collisions et métadonnées PokeMap ajoutées manuellement ;
- capable de signaler un conflit au lieu d'écraser silencieusement.

## 15. Roadmap recommandée

### Vue d'ensemble

| Lot | Priorité | Contenu | Dépend de | Résultat visible |
|---|:---:|---|---|---|
| `TILED-00` | P0 | Golden harness, fixtures et provenance | — | Référence mesurable |
| `TILED-01` | P0 | Parseur TMX/TSX et ImportPlan read-only | 00 | Bundle compris sans écriture |
| `TILED-02` | P0 | Catalogue de tuiles, copie et packing | 01 | Sheets et collections importées |
| `TILED-03` | P0 | GID, palette multi-tilesets et renderer | 02 | Tile layers fidèles |
| `TILED-04` | P0 | ObjectLayer libre, ancres et draw order | 03 | Props/ombres fidèles |
| `TILED-05` | P0 | Animations et collisions par tuile | 03–04 | Eau et murs fonctionnels |
| `TILED-06` | P1 | Wang sets et brush déterministe | 03–05 | Peinture terrain native |
| `TILED-07` | P1 | Automapping multi-passes | 06 | Murs/trous/variations natifs |
| `TILED-08` | P1 | Wizard import/reimport et fidélité | 01–07 | Workflow no-code complet |
| `TILED-09` | P2 | Cache, batching, budgets et durcissement Tiled | 03–08 | Production robuste |

### `TILED-00` — Golden harness et contrat de fidélité

Livrables :

- fixtures minimales dérivées des structures ERW sans publier les assets achetés ;
- runner de rendu déterministe ;
- graine et horloge figées ;
- comparaison screenshot ;
- politique de provenance/licence.

Critères de fin :

- le rendu actuel du sample est mesurable ;
- toute perte future de couche, GID, ancre ou ordre produit un test rouge ;
- aucun asset acheté n'est commité sans vérification de licence.

### `TILED-01` — Parseur et plan d'import

Livrables :

- lecture TMX/TSX externe ;
- `firstgid` ;
- spritesheets et image collections ;
- animations ;
- Wang sets ;
- collisions rectangulaires ;
- object layers ;
- `rules.txt` et cartes de règles ;
- normalisation des chemins ;
- diagnostics exhaustifs.

Critères de fin :

- 24/24 TMX et 38/38 TSX parsés ;
- 1 414 références XML externes résolues ;
- 21 chemins de `rules.txt` résolus après normalisation ;
- les URI internes `:/automap-tiles.tsx` sont reconnues ;
- aucune écriture n'a lieu avant validation explicite de l'ImportPlan.

### `TILED-02` — Compilateur d'assets

Livrables :

- import des 34 feuilles ;
- packing déterministe des 1 318 images de collection ;
- découpage multi-atlas sous la limite texture ;
- mapping stable des identifiants ;
- déduplication par hash ;
- provenance et rapport.

Critères de fin :

- aucun redimensionnement ni antialiasing ;
- dimensions et ancres conservées ;
- même entrée → mêmes atlas et mêmes IDs ;
- aucun chevauchement ni bleeding.

### `TILED-03` — Cellules multi-tilesets

Livrables :

- palette de cellules ;
- résolution GID/`firstgid` ;
- bits H/V/D ;
- migration JSON ;
- painter éditeur et renderer runtime ;
- ordre de parcours fidèle.

Critères de fin :

- les six calques mixtes du grand exemple sont importés ;
- les petits calques mixtes restent visuellement identiques ;
- les quatre flips horizontaux sont conservés ;
- round-trip JSON sans perte.

### `TILED-04` — ObjectLayer visuel

Livrables :

- objets dans `ObjectLayer` ;
- coordonnées pixel/fixed-point ;
- ancres ;
- tailles ;
- positions négatives ;
- ordre stable et `topdown` ;
- alternance exacte avec les tile layers.

Critères de fin :

- 217 tile objects importés ;
- 200 placements hors grille conservés ;
- objets jusqu'à `544 × 288` correctement ancrés ;
- ordre des 12 niveaux du sample préservé.

### `TILED-05` — Animation et collision

Livrables :

- table `tilesetId + localTileId → animation` ;
- timeline synchronisée ;
- durées exactes ;
- import des rectangles de collision ;
- éditeur de complétion des collisions manquantes.

Critères de fin :

- 568 animations et 6 271 frames converties ;
- 123/123 cellules animées dans chaque petit sample ;
- 450/450 dans le grand exemple ;
- huit collisions importées sans perte.

À la fin de `TILED-05`, PokeMap doit pouvoir reproduire les samples en lecture. C'est le premier jalon visuel utile.

### `TILED-06` — Wang natif

Livrables :

- signature huit positions ;
- types corner/edge/mixed ;
- matériaux multiples ;
- candidats pondérés ;
- choix déterministe ;
- brush no-code.

Critères de fin :

- 45/45 sets importés ;
- 3 694 associations conservées ;
- 706 probabilités conservées ;
- aucune tuile à probabilité `0` choisie automatiquement ;
- peinture puis effacement réparent correctement les voisins.

### `TILED-07` — Automapping

Livrables :

- règles compilées ;
- passes ordonnées ;
- rayon ;
- `MatchInOrder` ;
- `rule_options` ;
- probabilités/Disabled ;
- preview avant application.

Critères de fin :

- 21/21 rule maps compilées ;
- sept familles exécutent leurs trois passes ;
- résultat déterministe à seed identique ;
- undo/redo atomique.

### `TILED-08` — UX d'import et reimport

Livrables :

- wizard ;
- preview de fidélité ;
- diagnostics ;
- groupes de couches logiques ;
- reimport idempotent ;
- diff avant écrasement.

Critères de fin :

- aucun JSON ni GID à éditer manuellement ;
- un utilisateur peut importer ERW, ouvrir le sample et retrouver son rendu ;
- les corrections de collision PokeMap survivent au reimport.

### `TILED-09` — Performance et compatibilité étendue

Livrables :

- cache de couches statiques ou commandes précompilées ;
- invalidation par région ;
- regroupement par texture ;
- budget mémoire ;
- éviction et `ui.Image.dispose()` ;
- télémétrie de draw calls ;
- support progressif des fonctions Tiled non utilisées par ERW.

Critères de fin :

- carte `80 × 80` fluide dans éditeur et runtime ;
- aucune charge globale des 4 074 PNG ;
- textures libérées au changement de projet/map ;
- budget et diagnostic visibles.

## 16. Tests indispensables

### Parsing

- TSX spritesheet ;
- TSX collection d'images ;
- TMX multi-tilesets ;
- `firstgid` ;
- GID avec chaque bit H/V/D ;
- chemins relatifs Windows et POSIX ;
- URI interne `:/automap-tiles.tsx` ;
- trailing pixels d'une feuille dont la hauteur n'est pas multiple de 32 ;
- XML ou référence invalide avec diagnostic lisible.

### Modèle et sérialisation

- round-trip palette/cellules ;
- migration des anciens `TileLayer` ;
- round-trip objet pixel et ancre ;
- round-trip animation/collision/Wang ;
- identifiants stables au reimport ;
- données legacy inchangées.

### Rendu

- calque contenant au moins deux `firstgid` ;
- tuiles surdimensionnées issues de TSX différents dans un même calque ;
- ordre alterné tile/object/tile ;
- objet fractionnaire, négatif et hors map ;
- flip horizontal ;
- animation synchronisée ;
- golden screenshot du sample ;
- golden screenshot de la carte `80 × 80`.

### Authoring

- Wang signature pour chaque type ;
- candidats pondérés déterministes ;
- probabilité zéro jamais choisie ;
- peinture/effacement et voisinage ;
- Automapping erase/place/variations ;
- `MatchInOrder`, rayon, Disabled et Probability ;
- undo/redo ;
- reimport avec modifications locales.

### Performance

- atlas packing déterministe ;
- limite de taille texture ;
- absence de bleeding ;
- mesure draw calls ;
- chargement/déchargement de map ;
- libération des textures ;
- budget mémoire sur la grande carte.

## 17. Sécurité, portabilité et droits

### Chemins

L'importeur doit :

- résoudre les chemins à partir du fichier déclarant ;
- refuser toute sortie hors du projet cible ;
- normaliser `\` et `/` ;
- distinguer une URI interne Tiled d'un fichier absent ;
- empêcher les traversées `..` lors de la copie finale ;
- ne jamais dépendre d'un chemin absolu machine dans le JSON PokeMap.

### XML

Le parseur doit :

- désactiver les entités externes ;
- appliquer des limites de taille et profondeur ;
- produire des erreurs contextualisées par fichier et attribut ;
- rester dans l'infrastructure de l'éditeur.

### Licence

Aucun fichier local de licence, crédit, attribution ou conditions d'utilisation n'a été trouvé dans le bundle audité.

L'utilisateur indique avoir acheté le pack, mais cela ne permet pas de déduire les droits de redistribution.

Avant de commiter des assets ERW dans un dépôt :

- conserver la facture ou preuve d'achat ;
- archiver la licence exacte de la page produit ;
- vérifier les droits de modification, redistribution, équipe et publication ;
- enregistrer provenance, auteur, version et empreinte dans le manifest d'import ;
- éviter de placer des images du bundle dans un rapport versionné tant que ces droits ne sont pas confirmés.

## 18. Fonctions qui peuvent attendre

Pour ce bundle précis, les fonctions suivantes ne doivent pas bloquer le premier jalon :

- maps infinies et chunks ;
- group layers ;
- image layers ;
- parallaxe ;
- teinte et blend mode ;
- objets polygonaux, ellipses et textes ;
- templates et classes Tiled ;
- propriétés typées complètes ;
- Base64/zlib/zstd ;
- margin/spacing non nuls ;
- rotation d'objet libre et scale arbitraire.

Le schéma cible doit éviter de les rendre impossibles, mais il n'est pas nécessaire de les implémenter avant la fidélité ERW.

## 19. Résultat des passes indépendantes

### Passe A — inventaire bundle

Verdict :

- bundle sain et complet une fois `Props` inclus ;
- le rendu dépend des Wang sets, des couches, des objets libres, des animations et de l'Automapping ;
- un autotile `160 × 96` ne peut pas contenir cette information ;
- aucune cible externe manquante ;
- collisions très partielles ;
- licence locale absente.

### Passe B — éditeur et modèles

Verdict :

- les fondations d'atlas, frames, collisions et couches sont réutilisables ;
- l'import actuel d'une image statique est le mauvais niveau d'abstraction ;
- mixed GID, ObjectLayer, animation brute, Wang et Automapping sont absents ;
- le bon produit est un wizard « Importer un bundle Tiled » suivi d'outils sémantiques.

### Passe C — runtime

Verdict :

- le runtime peut afficher une version simplifiée, mais pas fidèle ;
- il suppose une image et des IDs locaux par couche ;
- ObjectLayer est un no-op ;
- les placements sont sur grille ;
- animations de path et culling offrent de bonnes briques ;
- la cible doit compiler toutes les données dans des formats PokeMap avant exécution.

Les trois passes ont été read-only et convergent sur le même diagnostic.

### Passe D — implémentation

Verdict :

- non applicable ;
- la demande portait sur un audit strictement read-only ;
- aucune implémentation, migration, import d'asset ou modification de code de production n'était autorisée ou nécessaire ;
- le seul fichier créé est le présent rapport.

### Passe E — tests, build et validation

Verdict :

- les validations structurelles du bundle et les tests de caractérisation ciblés sont réussis ;
- un build global n'est pas applicable à un audit documentaire sans modification de code ;
- les tests ciblés constituent la validation proportionnée des capacités PokeMap citées ;
- aucun statut de compatibilité ERW n'est prétendu sur la seule base de ces tests : cette preuve appartient aux futurs golden tests `TILED-00`.

### Passe F — critique finale

Verdict :

- contre-review indépendante réalisée après rédaction ;
- cohérence des chiffres ERW confirmée ;
- références `fichier:ligne` vérifiées automatiquement ;
- ambiguïté entre références XML, chemins `rules.txt` et URI virtuelles corrigée ;
- ordre des tile layers reclassé de « complet » à « partiel » dans le contexte d'une alternance avec les ObjectLayers ;
- risques de licence, d'Automapping non exécuté et de raccourci par scission mixed-GID explicitement conservés.

## 20. Vérifications exécutées

### Bundle

- parsing XML : 62/62 TMX/TSX valides ;
- références XML externes : 1 414/1 414 résolues ;
- chemins de `rules.txt` : 21/21 résolus après normalisation ;
- références de fichiers totales : 1 435/1 435 résolues ;
- URI Tiled internes reconnues : 14 ;
- rasters : 5 850/5 850 décodables ;
- analyse des Wang sets, animations, probabilités, collisions, calques et GID ;
- inventaire SHA-256 et doublons ;
- rendu local des cartes exemples ;
- inspection visuelle de l'éditeur PokeMap.

### Tests de caractérisation PokeMap

Commande :

```bash
cd packages/map_core
dart test \
  test/map_terrain_autotile_characterization_test.dart \
  test/surface_variant_role_resolver_test.dart \
  test/surface_variant_role_test.dart \
  test/map_placed_element_rotation_test.dart
```

Résultat :

```text
70 tests réussis — All tests passed!
```

Commande :

```bash
cd packages/map_editor
flutter test \
  test/path_autotile_set_test.dart \
  test/map_grid_painter_layer_order_test.dart
```

Résultat :

```text
15 tests réussis — All tests passed!
```

Commande :

```bash
cd packages/map_runtime
flutter test test/runtime_path_autotile_animation_test.dart
```

Résultat :

```text
4 tests réussis — All tests passed!
```

Ces tests ne prouvent pas une compatibilité ERW. Ils caractérisent précisément les fondations et limites actuelles sur lesquelles la roadmap s'appuie.

Les analyses globales Dart/Flutter n'ont pas été lancées : aucun code de production n'a été modifié par cet audit, et deux changements concurrents hors périmètre étaient présents dans `map_gameplay` au moment des vérifications ciblées.

## 21. État Git et fichiers

### État initial

```text
propre
commit observé : 22b858129
```

### Fichier créé par cet audit

- `reports/editor/erw_grass_land_2_0_full_potential_audit_2026-07-30.md`

Son contenu complet est le présent rapport.

Aucun code, projet PokeMap ou asset acheté n'a été modifié ou copié.

### Changements concurrents observés

Pendant l'audit, les changements suivants sont apparus dans l'espace partagé :

```text
 M packages/map_gameplay/lib/src/gameplay_world_state.dart
?? packages/map_gameplay/test/placed_element_rotation_gameplay_test.dart
```

Ils ne proviennent d'aucune des trois passes de cet audit et n'ont pas été touchés.

Avant la clôture de l'audit, un autre processus les a commités et `HEAD` a avancé vers :

```text
15d3691ef feat(map_gameplay): rotate placed element spatial footprints
```

Cet audit n'a créé ni ce commit, ni aucun autre commit.

### État final

```text
?? reports/editor/erw_grass_land_2_0_full_potential_audit_2026-07-30.md
```

Le worktree ne contient plus les deux changements `map_gameplay` non commités observés plus tôt ; seul le présent rapport est non suivi.

## 22. Auto-critique et risques résiduels

### Ce que l'audit établit avec forte confiance

- l'incompatibilité structurelle entre les 20 rôles PokeMap et les Wang sets ERW ;
- les volumes et fonctionnalités réellement utilisés ;
- l'absence actuelle d'import TMX/TSX/Wang/Automapping ;
- l'impossibilité de conserver les mixed GID et objets libres avec les modèles actuels ;
- les fondations PokeMap réutilisables ;
- l'ordre logique des lots.

### Limites

- Tiled n'était pas installé : l'Automapping n'a pas été exécuté dans son moteur officiel ;
- aucun importeur prototype n'a encore validé les hypothèses de conversion ;
- aucune mesure FPS/draw calls n'a été réalisée sur une version PokeMap du sample ;
- la fidélité pixel parfaite devra tolérer ou figer les animations ;
- les règles de licence ne sont pas disponibles localement ;
- les assets hors TSX n'ont pas de métadonnées suffisantes pour une importation sémantique automatique ;
- la compatibilité avec les futures versions de Tiled n'est pas couverte par le lot ERW initial.

### Risque architectural principal

Chercher un raccourci en scindant toujours un calque mixed-GID par tileset peut produire un sample presque correct tout en réordonnant des tuiles surdimensionnées. Le golden visuel doit empêcher que ce compromis temporaire devienne le modèle permanent.

### Risque produit principal

Exposer les Wang IDs, GID, sous-couches et atlas techniques à l'utilisateur reproduirait la complexité de Tiled sans son ergonomie. L'éditeur doit rester sémantique et no-code.

## 23. Prochaine action recommandée

Commencer par `TILED-00`, puis `TILED-01`.

Le premier objectif concret n'est pas encore de peindre M01. Il est de produire un import **read-only** de `Sample map.tmx` avec :

- inventaire complet ;
- diagnostics zéro perte ;
- rendu PokeMap comparé au rendu de référence ;
- aucune écriture avant validation.

Une fois cette golden slice fidèle, les lots `TILED-02` à `TILED-05` transformeront l'import en une vraie map PokeMap autonome. Ensuite seulement, `TILED-06` et `TILED-07` rendront les Wang sets et l'Automapping directement éditables dans PokeMap.
