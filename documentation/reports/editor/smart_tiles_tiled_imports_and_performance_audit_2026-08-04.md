# Audit Smart Tiles — imports Tiled, atomicité et grandes cartes

Date : 2026-08-04  
Révision auditée : `cd52c046f3a2692666ca1cc7dbade1b3408f57a0`  
Branche : `main`, 22 commits devant `origin/main` au début de l'audit  
État Git initial : propre

## 1. Verdict exécutif

La cible demandée est atteignable proprement sans faire de Tiled une dépendance de PokeMap. Le noyau Wang natif n'est pas le point faible actuel : les 28 TSX du pack ERW qui contiennent des Wang Sets passent tous le parseur et le compilateur PokeMap existants. Les problèmes restants se situent après et autour de ce noyau.

| Axe | État audité | Verdict |
|---|---:|---|
| Parseur et compilateur Wang natif | `DONE` pour les TSX à atlas régulier | Les 28 TSX Wang ERW passent, dont l'atlas principal de 3960 tuiles et 10 Wang Sets. |
| Import durable image + asset + tileset + Wang | `PARTIAL` | Chaque action est atomique isolément, mais le parcours éditeur enchaîne trois transactions durables. Une panne tardive peut laisser un asset ou un tileset orphelin. |
| TSX « image collection » | `MISSING` | Le parseur les refuse explicitement et le schéma de tileset ne sait représenter qu'un atlas régulier associé à une image. |
| Import de cartes TMX | `MISSING` | Aucun parseur ni action TMX n'existe. Le modèle `TileLayer` actuel ne suffit pas à préserver les cartes ERW fidèlement. |
| Validation locale avec les assets ERW | `PARTIAL` | Deux portes locales existent et passent avec les vrais fichiers. Elles ne couvrent ni les collections d'images ni une carte TMX complète. |
| Très grandes cartes riches | `PARTIAL` | Le viewport est correctement borné jusqu'à 1024² cellules, mais il n'existe aucun benchmark combinant terrains, chemins, motifs, forêts et assets réels. |

La recommandation est de réaliser **18 lots répartis sur quatre phases, STN-08 à STN-11**. Il ne faut pas commencer par ajouter un parseur TMX directement dans l'éditeur : cela reproduirait précisément le problème de deux systèmes partiels vivant côte à côte.

## 2. Cible fonctionnelle confirmée

La cible reste « Smart Tiles natif » :

1. PokeMap possède son schéma, ses règles, ses cartes et son résolveur.
2. TSX et TMX sont uniquement des formats d'entrée optionnels.
3. Une fois importées, les données ne dépendent plus de Tiled ni des chemins machine d'origine.
4. Une carte TMX peut produire des couches de tuiles littérales fidèles pour servir de carte de référence ou de test.
5. Les Wang Sets des TSX associés produisent en parallèle des presets Smart Tiles natifs pour poursuivre l'authoring.
6. Les couches TMX déjà peintes ne sont pas converties automatiquement en champs sémantiques terrain/chemin. Cette inversion n'est pas fiable en présence de variantes, transformations, retouches manuelles ou plusieurs tilesets.

Le futur parcours peut donc proposer deux intentions clairement séparées :

| Intention | Comportement |
|---|---|
| **Importer fidèlement** — cible de STN-10 | Préserve la composition visuelle TMX dans des couches littérales natives et importe les définitions TSX/Wang disponibles. |
| **Reconstruire en Smart Tiles** — hors cible initiale | Assistant ultérieur, uniquement quand la correspondance Wang est non ambiguë, avec aperçu, taux de couverture et validation humaine. |

Une couche de tuiles littérale n'est pas un retour de `TerrainLayer` ou `PathLayer`. Elle ne porte aucune logique terrain ou chemin. Toute nouvelle peinture sémantique reste portée par `SmartTileLayer`.

## 3. Passes d'audit

La politique active de cette session ne permettait pas de déléguer à des sub-agents sans demande explicite. Les contrôles exigés ont donc été menés comme trois passes locales indépendantes.

| Passe | Périmètre | Verdict |
|---|---|---|
| A — Transactions et authoring canonique | `map_core`, `map_authoring`, services éditeur, journaux et artefacts | Le moteur transactionnel sait déjà appliquer une mutation multi-ressources. Le défaut est l'orchestration du cas Tiled, pas la fondation transactionnelle. |
| B — Formats et corpus ERW | Spécification officielle Tiled, 38 TSX et 24 TMX locaux | Le corpus jouable est une excellente cible V1 orthogonale/finie/CSV, mais force le support multi-tilesets et sub-cellule. |
| C — Preuves, performance et transports | Tests core/authoring/editor, vrais assets ERW, benchmark de culling, serveur MCP | Le socle actuel est vert et la parité MCP Wang existe. Les nouveaux imports devront conserver la même parité. |

## 4. Architecture actuelle et défaut d'atomicité

### 4.1 Ce qui est déjà solide

- `AuthoringChangeSet` accepte plusieurs ressources dans une même opération et refuse les ressources ou clés de stockage dupliquées.
- `JournaledAuthoringTransaction` prépare, réserve, promeut, journalise et récupère des changements multi-fichiers.
- `asset.import` écrit déjà atomiquement le catalogue d'assets et, si nécessaire, le blob adressé par contenu.
- `map.create` démontre qu'une seule action peut créer un fichier de carte et modifier `project.json` dans le même change set.
- les builders sont `FutureOr<AuthoringMutationDraft>` : une action composite peut donc lire les handles d'artefacts avant de construire son plan.

Zones structurantes :

- `packages/map_authoring/lib/src/transactions/authoring_plan.dart:106`
- `packages/map_authoring/lib/src/transactions/change_set.dart:85`
- `packages/map_authoring/lib/src/transactions/journaled_transaction.dart:62`
- `packages/map_authoring/lib/src/domains/assets/asset_actions.dart:80`
- `packages/map_authoring/lib/src/domains/maps/map_lifecycle_adapter.dart:38`

### 4.2 Séquence actuelle

Le parcours TSX/Wang éditeur exécute actuellement :

1. staging opaque de l'image externe ;
2. `asset.import` — catalogue d'assets et blob ;
3. lecture/décodage de l'image importée ;
4. `tileset.upsert` — modification de `project.json` ;
5. `smart_tile.tiled_wang.import` — seconde modification de `project.json` ;
6. relecture et vérification du snapshot.

Les étapes 2, 4 et 5 sont trois commits différents. Les contrôles en amont réduisent fortement le risque, mais ne créent pas de rollback inter-action. Une erreur de révision, un conflit de catalogue ou une panne après l'étape 2 ou 4 peut laisser un état durable partiel.

Zones concernées :

- `packages/map_editor/lib/src/features/smart_tiles_studio/application/smart_tile_source_asset_import_service.dart:133`
- `packages/map_editor/lib/src/features/smart_tiles_studio/application/smart_tile_tiled_wang_import_service.dart:168`
- `packages/map_authoring/lib/src/domains/assets/tileset_actions.dart:262`
- `packages/map_authoring/lib/src/domains/maps/smart_tile_catalog_actions.dart:170`

### 4.3 Correction recommandée

Créer une seule action publique, provisoirement nommée `tileset.tiled.import`, qui reçoit un bundle de handles d'artefacts et produit un unique `AuthoringMutationDraft` contenant :

- la nouvelle version du catalogue d'assets ;
- tous les blobs nouveaux ou générés ;
- une seule version projetée de `project.json` comprenant le tileset et le bundle Smart Tiles ;
- le rapport d'import et les diagnostics structurés.

Le staging externe peut rester préalable : il est temporaire et ne fait pas partie de l'état projet. Aucune mutation durable ne doit commencer avant la validation de toute la fermeture de dépendances.

L'action composite ne doit pas appeler récursivement `asset.import`, `tileset.upsert` puis `smart_tile.tiled_wang.import`. Il faut extraire leurs calculs purs en projecteurs réutilisables, construire le catalogue d'assets projeté puis le manifeste projeté, et enfin fabriquer un seul change set. Cela évite les doubles écritures concurrentes de `project.json`.

Le contrat doit aussi garantir :

- identifiants dérivés de digests et clé d'idempotence stable ;
- déduplication de blob sans écrasement silencieux d'identité ;
- conflits détectés au plan, avant toute promotion ;
- aucune route durable publique permettant encore le vieux parcours Tiled fractionné ;
- fault injection à chaque checkpoint du journal, puis preuve « tout ou rien » après récupération.

## 5. TSX « image collection »

### 5.1 Limite exacte

`parseTiledWangTileset` exige aujourd'hui un `tilecount` positif, refuse `columns == 0` et exige exactement une image racine. `TilesetAtlasSpec` exige également un unique asset et une grille régulière dont les dimensions divisent exactement l'image.

Zones concernées :

- `packages/map_core/lib/src/operations/tiled_wang_import.dart:153`
- `packages/map_core/lib/src/operations/tiled_wang_import.dart:176`
- `packages/map_authoring/lib/src/domains/assets/tileset_actions.dart:72`

### 5.2 Réalité du pack ERW

Le pack contient 4 collections d'images, soit **1318 images de tuile** au total :

| Collection | Images | Variantes de dimensions | Wang Sets |
|---|---:|---:|---:|
| sheet 1 sprites | 639 | 23 | 0 |
| sheet 2 sprites | 297 | 38 | 0 |
| sheet 3 sprites | 60 | 19 | 0 |
| sheet 4 sprites | 322 | 3 | 0 |

Ces collections servent principalement aux props. Elles ne bloquent pas les terrains Wang du pack : les Wang Sets ERW sont dans des atlas réguliers, déjà compris par PokeMap.

### 5.3 Schéma natif recommandé

Le metadata `TilesetAtlasSpec` ne devrait plus rester un contrat typé local à `map_authoring` caché dans `globalProperties`. Il faut un contrat `map_core` de source de tileset, avec deux formes exclusives :

```text
ProjectTilesetSource
├── regularAtlas
│   ├── assetId, dimensions pixel
│   ├── grille, marge, espacement et offset
│   └── tileCount
└── imageCollection
    ├── pages normalisées
    └── tileDefinitions indexées par l'identité TSX locale
        ├── pageId + rectangle source
        ├── dimensions et offset visuel
        ├── animation éventuelle
        └── propriétés/collision importées explicitement
```

Pour éviter 1318 textures indépendantes au runtime, l'importeur doit assembler les images dans des pages d'atlas générées de manière déterministe : ordre stable par ID, aucun pivotement, padding/extrusion adaptés au pixel art, limite de page explicite, digests reproductibles. Les pages générées deviennent les seuls assets durables nécessaires au rendu. Les images achetées restent des entrées locales de l'import et ne sont jamais commitées dans le dépôt PokeMap.

Le parseur `map_core` doit seulement produire des descripteurs purs et une fermeture de dépendances. Le décodage PNG et le packing appartiennent à `map_authoring`, au moment de construire la mutation.

## 6. TMX : faisabilité et contraintes du corpus

La documentation officielle Tiled confirme que TMX peut mélanger plusieurs tilesets via des GID globaux, stocker les flags de transformation dans les quatre bits hauts, encoder les couches en XML, CSV ou base64 compressé, et contenir des couches de tuiles, objets, images et groupes. Références :

- <https://doc.mapeditor.org/en/stable/reference/tmx-map-format/>
- <https://doc.mapeditor.org/en/stable/reference/global-tile-ids/>

L'implémentation PokeMap doit s'appuyer sur cette spécification et ses propres fixtures. Le code Tiled peut servir à comprendre les cas limites, mais aucune portion GPL ne doit être copiée dans PokeMap.

### 6.1 Corpus ERW observé

| Fait | Valeur |
|---|---:|
| Fichiers TMX | 24 |
| Cartes d'exemple jouables | 3 |
| Règles d'automapping Tiled | 21 |
| Orientation | 24/24 orthogonales |
| Taille de cellule | 24/24 en 32×32 |
| Cartes infinies / chunks | 0 / 0 |
| Encodage des couches | 64/64 en CSV non compressé |
| Tilesets externes référencés | 33 distincts, 76 références |
| Couches de tuiles | 64 |
| Couches d'objets | 16 |
| Tile objects | 217 |
| Objets de forme | 34 |
| GID analysés | 121600, dont 10826 non vides |
| GID transformés dans ce corpus | 0 |

La carte principale fait 80×80, possède 6 couches de tuiles et une couche d'objets, et référence 19 tilesets. Parmi les 64 couches du corpus, 18 utilisent plus d'un tileset ; une couche de la carte principale en utilise 6.

Les 21 TMX de règles ne sont pas des cartes jouables. Certaines références `:/automap-tiles.tsx` désignent une ressource interne à Tiled. Le scanner doit les identifier comme règles d'automapping et les exclure du parcours « importer une carte », avec diagnostic, plutôt que tenter de résoudre ce chemin comme un fichier local.

### 6.2 Bloquants du modèle actuel

`TileLayer` contient aujourd'hui un seul `tilesetId` optionnel et une liste d'entiers. Il ne peut pas préserver :

- plusieurs tilesets dans la même couche ;
- l'identité locale d'une tuile indépendamment du GID de la carte ;
- les flips horizontal, vertical ou diagonal ;
- une image de tuile de taille variable et son ancrage.

`ObjectLayer` ne stocke aucun contenu. Les `MapPlacedElement` sont placés sur une `GridPos` et limités aux quarts de tour. Dans le corpus ERW, les 217 tile objects ont une rotation compatible, mais seulement 17 ont des coordonnées X/Y toutes deux alignées sur la grille. Une simple conversion vers `GridPos` déplacerait donc 200 objets.

Zones concernées :

- `packages/map_core/lib/src/models/map_layer.dart:37`
- `packages/map_core/lib/src/models/map_layer.dart:73`
- `packages/map_core/lib/src/models/map_data.dart:191`

### 6.3 Représentation recommandée des couches littérales

Pour garder un JSON compact, la couche doit utiliser une palette de références :

```text
LiteralTileLayer
├── palette[]
│   └── { tilesetId, localTileId, transform }
└── cells[]
    └── 0 = vide, N = palette[N - 1]
```

Un résolveur pur `map_core`, analogue à `resolveSmartTileLayerVisuals`, convertira ensuite cette couche en instructions visuelles neutres comprenant page, rectangle source, transformation, géométrie et ordre de dessin. L'éditeur et le runtime devront consommer ce même résolveur. Cela évite un nouveau couple de renderers divergents.

Le remplacement de l'encodage actuel justifie un bump de schéma. Une migration unique peut transformer les anciennes couches littérales à tileset unique vers la palette, puis l'ancien renderer doit être supprimé. Même si la compatibilité des anciens projets n'est pas requise par le produit, une migration déterministe évite de maintenir deux modèles en parallèle pendant le développement.

### 6.4 Portée TMX V1 recommandée

Supporter et valider :

- cartes orthogonales finies ;
- tilesets TSX externes ;
- couches CSV ;
- GID, `firstgid` et les quatre flags, même si ERW ne les utilise pas ;
- visibilité et opacité ;
- propriétés typées conservées dans un namespace d'import ;
- tile objects avec position sub-cellule et géométrie visuelle ;
- incompatibilité explicite entre grille TMX et grille projet, avec choix utilisateur « adopter » seulement pour un projet compatible.

Reconnaître mais refuser proprement en V1 :

- cartes infinies et chunks ;
- orientations isométrique, hexagonale, staggered ou oblique ;
- image layers ;
- templates externes ;
- compression zstd si aucun décodeur borné n'est ajouté ;
- conversion automatique de formes arbitraires vers des collisions ou zones gameplay.

Les groupes peuvent être aplatis en conservant un chemin de couche et les effets hérités, ou être refusés au premier lot. Les formats base64 non compressé, gzip et zlib sont raisonnables à ajouter au parseur borné même s'ils ne sont pas nécessaires au corpus ERW.

### 6.5 Mutation TMX atomique

L'action `map.tiled.import` doit écrire en une seule transaction :

- catalogue et blobs d'assets ;
- sources de tilesets et Smart Tile catalog compilé ;
- entrée de carte dans `project.json` ;
- fichier `maps/<id>.json` ;
- rapport d'import durable sans chemins machine.

Le préflight doit produire avant confirmation : dépendances trouvées/manquantes, éléments supportés/refusés, grille, dimensions, coût estimé, collisions d'identité, nombre d'assets et aperçu des couches. Aucune propriété Tiled ne doit devenir une règle de gameplay par simple convention de nom.

## 7. Validation ERW sans commiter les assets

### 7.1 Preuves fraîches obtenues

Deux mécanismes locaux existent déjà :

- `POKEMAP_STN07_ERW_TSX` dans `smart_tile_tiled_wang_import_service_test.dart` ;
- `POKEMAP_STN07_ERW_FOREST_PNG` dans `smart_tile_stn07_organic_forest_golden_workflow_test.dart`.

Avec les fichiers locaux achetés :

- l'atlas principal ERW 1760×2304, 3960 tuiles et 10 Wang Sets passe ;
- les 28 TSX ERW contenant au moins un Wang Set passent individuellement, 28/28 ;
- un arbre ERW 192×160 passe la projection canopy/understory/collision ;
- aucun fichier acheté n'a été copié dans le dépôt.

### 7.2 Extension recommandée

Ajouter un seul point d'entrée local `POKEMAP_ERW_ROOT`, puis dériver les dépendances par chemins relatifs découverts. Le pipeline local doit couvrir :

1. inventaire sans copie du corpus ;
2. parsing des 28 TSX Wang ;
3. parsing puis packing des 4 image collections ;
4. import atomique de la carte principale 80×80 ;
5. relecture depuis un nouveau process éditeur ;
6. construction des instructions éditeur et runtime ;
7. checksum structurel stable du projet importé ;
8. rapport éphémère de temps, mémoire et diagnostics.

Les tests CI doivent utiliser des fixtures synthétiques minuscules créées pour PokeMap. Les tests ERW restent conditionnels et locaux. Aucun screenshot, PNG, TSX ou TMX acheté ne doit être ajouté aux fixtures, snapshots ou rapports Git.

La fermeture de dépendances doit être sécurisée : taille totale bornée, nombre de fichiers borné, chemins réels vérifiés sous la racine explicitement sélectionnée, symlinks contrôlés, images réellement décodées, XML et décompression soumis à des budgets. Le chemin spécial `:/` doit être refusé.

## 8. Performance

### 8.1 Garanties existantes

`resolveSmartTileLayerVisuals` accepte un viewport et calcule une plage de propriétaires élargie par l'enveloppe visuelle des presets et motifs. Le test éditeur actuel prouve que le nombre de cellules Smart Tile visitées reste identique pour le même viewport sur une carte 128² et 1024².

Zones concernées :

- `packages/map_core/lib/src/operations/smart_tile_layer_visual_resolver.dart:61`
- `packages/map_editor/test/ui/world_map/world_map_large_map_performance_test.dart:383`
- `tools/performance/benchmark_support.dart`

Cette preuve protège le culling, mais ne mesure ni les temps, ni le tri de nombreuses instructions, ni les patterns riches, ni plusieurs passes forêt, ni la sérialisation d'un très gros champ.

### 8.2 Matrice de benchmark cible

Le générateur doit être déterministe et produire au minimum 128², 256², 512² et 1024² cellules avec :

- terrain dense à plusieurs matières et transitions ;
- réseau de chemins avec croisements ;
- motifs simples et multi-cellules ;
- forêt avec ground, understory, shadow, canopy et foreground ;
- animations synchronisées et par cellule ;
- géométries débordantes ;
- couche littérale multi-tilesets et props ;
- collisions et placements.

Mesures séparées :

| Domaine | Mesures |
|---|---|
| `map_core` | résolution plein champ, résolution viewport, édition ligne/rectangle/remplissage, JSON encode/decode, checksums |
| `map_authoring` | plan/apply d'un import riche, taille du journal, récupération injectée, réouverture snapshot |
| `map_editor` | pan/zoom, construction d'instructions, paint, rebuilds, cache images, work counts |
| `map_runtime` | chargement bundle, instructions visibles, culling, première frame et régime stable |

Utiliser le harness existant : warmups, échantillons, p50/p95/max, RSS, mode JIT/AOT, commit, état Git, fingerprint de l'arbre et checksum du résultat. Les tests CI doivent faire échouer les régressions algorithmiques et les work counts. Les budgets temporels absolus seront figés seulement après une baseline sur la machine cible ; les inventer dans cet audit donnerait une fausse garantie.

## 9. Parité API, JSONL, éditeur et MCP

Les nouveaux parcours doivent rester dans `map_authoring`. L'éditeur ne doit ni écrire directement les assets, ni compiler seul une carte durable.

Contrats recommandés :

```text
tileset.tiled.inspect   # lecture/préflight d'un bundle TSX
tileset.tiled.import    # mutation atomique asset + tileset + Wang
map.tiled.inspect       # lecture/préflight d'un bundle TMX
map.tiled.import        # mutation atomique assets + tilesets + carte
```

Chaque mutation doit être découvrable dans `pokemap_describe` avec schémas stricts, permissions, niveaux de risque, ressources affectées et garanties `dryRun`, idempotence, révision, atomicité et undo. Les preuves de Done doivent inclure :

- appel direct `map_authoring` ;
- JSONL/CLI ;
- adapter éditeur ;
- serveur MCP réel ;
- receipt sémantiquement équivalent sur les quatre transports ;
- PMCP-085 et catalogue documentaire mis à jour ;
- rebuild et suite `tools/pokemap_mcp`.

Pour MCP, les fichiers doivent être staged par handles opaques depuis une racine étroite autorisée. Il ne faut jamais élargir la racine MCP au dossier personnel pour atteindre le pack ERW.

## 10. Roadmap recommandée — 18 lots

### Phase STN-08 — Fondations typées et import atomique, 4 lots

| Lot | Contenu | Critère Done principal | Taille |
|---|---|---|---:|
| STN-08.1 | Déplacer la source d'atlas régulière vers un contrat typé `map_core`, migrer puis supprimer le metadata parallèle dans `globalProperties`. | Un tileset régulier possède une seule représentation canonique consommée par éditeur/runtime. | L |
| STN-08.2 | Extraire les projecteurs purs asset, tileset et Wang ; construire un plan composite sans appels d'actions imbriqués. | Le plan projeté contient catalogue, blob et une seule mutation de manifeste. | M |
| STN-08.3 | Ajouter `tileset.tiled.import` pour les atlas réguliers et tester conflits, idempotence et tous les checkpoints de récupération. | Après chaque panne injectée : état complet ou état initial, jamais d'orphelin. | L |
| STN-08.4 | Basculer l'UI et MCP sur l'action composite, retirer la route Tiled publique fractionnée. | Parité direct/JSONL/éditeur/MCP et catalogue live ; un clic produit un receipt unique. | M |

### Phase STN-09 — Collections d'images TSX, 5 lots

| Lot | Contenu | Critère Done principal | Taille |
|---|---|---|---:|
| STN-09.1 | Étendre le schéma avec `imageCollection`, pages et définitions de tuiles sparse. | IDs non contigus, dimensions variables, offset, propriétés et animations sérialisés/validés. | L |
| STN-09.2 | Généraliser le parseur TSX et produire une fermeture de dépendances sans I/O dans `map_core`. | Diagnostics précis pour image manquante, doublon, taille ou référence invalide. | M |
| STN-09.3 | Ajouter le packer déterministe pixel-art et les artefacts générés adressés par contenu. | Même entrée = mêmes pages/digests ; aucune dépendance runtime aux fichiers source. | L |
| STN-09.4 | Ajouter un résolveur visuel partagé et les previews no-code pour les props de collection. | Éditeur et runtime produisent les mêmes géométries, animations et culling. | L |
| STN-09.5 | Prouver les 4 collections ERW via `POKEMAP_ERW_ROOT`. | 1318 images importées localement, réouverture réussie, zéro asset licencié dans Git. | M |

### Phase STN-10 — Import TMX, 6 lots

| Lot | Contenu | Critère Done principal | Taille |
|---|---|---|---:|
| STN-10.1 | Remplacer l'encodage `TileLayer` par palette `{tilesetId, localTileId, transform}` et migration unique. | Multi-tilesets et D4 rendus identiquement dans éditeur/runtime, ancien chemin supprimé. | L |
| STN-10.2 | Parseur TMX pur et borné : carte, dépendances, couches, propriétés, CSV/XML/base64, gzip/zlib, GID et flags. | Fixtures officielles/synthétiques positives et corpus malformé fail-closed. | L |
| STN-10.3 | Compiler couches TMX vers `MapData`, politique de grille explicite et diagnostics de fidélité. | La carte principale conserve ses 6 couches et les références de 19 tilesets. | L |
| STN-10.4 | Étendre les placements visuels sub-cellule et importer les tile objects ; préserver les formes non mappées dans le rapport. | Les 217 tile objects ERW gardent leur position visuelle ; aucune collision gameplay n'est inventée. | L |
| STN-10.5 | Ajouter inspect/import no-code et action atomique `map.tiled.import`, puis parité MCP. | Assets, tilesets, manifeste et carte sont un seul receipt récupérable. | L |
| STN-10.6 | Golden workflow synthétique CI et workflow réel ERW local. | Import, fermeture/réouverture, rendu éditeur/runtime et playtest de la carte 80×80 réussissent. | L |

### Phase STN-11 — Performance et durcissement, 3 lots

| Lot | Contenu | Critère Done principal | Taille |
|---|---|---|---:|
| STN-11.1 | Générateur de cartes riches 128² à 1024² et benchmark core/authoring avec receipts. | Checksums stables, mesures p50/p95/max/RSS et work counts exploitables. | M |
| STN-11.2 | Profils éditeur et runtime sur pan/zoom, chargement, culling et frames visibles. | Aucun travail plein champ pendant navigation ; ressources et caches bornés. | L |
| STN-11.3 | Baseline machine cible, budgets de non-régression et campagne ERW locale. | Seuils justifiés par mesures, rapport reproductible et aucun fichier licencié persisté. | M |

Ordre critique : `08.1 → 08.2 → 08.3 → 08.4 → 09 → 10 → 11`. STN-11.1 peut commencer après STN-10.1 avec des fixtures synthétiques, mais la campagne complète dépend de STN-10.6.

## 11. Commandes et résultats frais

| Commande | Résultat exact utile |
|---|---|
| `dart test test/smart_tiles/tiled_wang_import_test.dart` dans `map_core` | exit 0, 5 tests passés |
| `dart test test/domains/maps/smart_tile_catalog_actions_test.dart` dans `map_authoring` | exit 0, 11 tests passés |
| test éditeur Wang avec l'atlas principal via `POKEMAP_STN07_ERW_TSX` | exit 0, 5 tests passés |
| même test ciblé sur chaque TSX Wang ERW | 28/28 fichiers passés, 0 échec |
| test forêt via `POKEMAP_STN07_ERW_FOREST_PNG` | exit 0, 2 tests passés |
| `flutter test test/smart_tiles_studio/smart_tile_source_asset_import_service_test.dart` | exit 0, 3 tests passés |
| `flutter test test/ui/world_map/world_map_large_map_performance_test.dart` | exit 0, 8 tests passés |
| `dart analyze` dans `map_core` | exit 0, aucun problème |
| `dart analyze` dans `map_authoring` | exit 0, aucun problème |
| `flutter analyze` dans `map_editor` | exit 0, aucun problème |
| `npm test` dans `tools/pokemap_mcp` | exit 0, 30 tests passés, 0 échec |

Les avertissements de packages plus récents disponibles n'ont pas affecté les résultats.

## 12. Fichiers modifiés par cet audit

Un seul fichier a été créé :

- `documentation/reports/editor/smart_tiles_tiled_imports_and_performance_audit_2026-08-04.md` — audit, cible technique, preuves et roadmap consolidés.

Aucun code, fixture, asset ERW, TSX, TMX, PNG ou fichier généré n'a été modifié ou ajouté.

## 13. Risques et auto-critique

1. **Le packing d'images est un vrai sous-système.** Il doit être déterministe, borné et testé visuellement ; le réduire à une concaténation de PNG créerait des textures énormes ou du bleeding.
2. **La fidélité TMX n'est pas seulement du XML.** Le schéma de tuile, les transforms, l'ordre de rendu et les placements sub-cellule doivent précéder l'action d'import.
3. **Le corpus ERW est favorable sur plusieurs points.** Il est orthogonal, fini, CSV et sans GID transformé. Les fixtures synthétiques doivent donc couvrir les flags, base64, compression et IDs sparse que ce pack n'exerce pas.
4. **Les tile objects ne sont pas du gameplay.** Les importer visuellement ne doit pas créer implicitement collisions, warps ou zones.
5. **Les mesures actuelles ne sont pas une baseline de temps.** Elles prouvent le bornage du travail et la santé du socle, pas encore une performance utilisateur cible.
6. **Le rapport recommande un bump/migration de schéma.** L'inventaire exact de toutes les fixtures V6 à mettre à jour sera à produire dans STN-08.1 ; il n'a pas été simulé dans cet audit en lecture seule.
7. **Aucune mutation destructive ou Git n'a été exécutée.** Le rapport n'est pas commité, car la demande portait sur l'audit et non sur un commit.

## 14. Prochaine étape recommandée

Commencer par **STN-08.1**, puis livrer STN-08 entièrement avant de toucher au TMX. Cette phase élimine l'état partiel actuel et donne aux collections TSX et au TMX un contrat de tileset natif durable. Commencer directement par STN-10 produirait un importeur obligé de contourner `TileLayer`, `TilesetAtlasSpec` et les trois transactions existantes, donc une nouvelle dette structurelle.
