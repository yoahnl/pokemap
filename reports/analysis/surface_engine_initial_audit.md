# Surface Engine - Audit initial

Date: 2026-04-26

## Synthese

Le systeme actuel de PokeMap possede deja plusieurs briques utiles pour les surfaces: des `TerrainLayer`, des `PathLayer`, des presets visuels, des frames animees, un resolver d'autotile simple et un rendu Flame capable de dessiner des frames par cellule. Ces briques permettent un MVP credible, notamment pour des chemins, de l'eau simple et quelques animations de presets.

La limite structurante est que la "surface" n'existe pas encore comme entite metier unifiee. Elle est aujourd'hui dispersee entre:

- `TerrainType`, pour les terrains peints en grille.
- `PathLayer`, pour des cellules booleennes avec un `presetId`.
- `ProjectTerrainPreset`, pour des variantes visuelles de terrain.
- `ProjectPathPreset`, pour des variantes d'autotile associees a un type de surface.
- `MapGameplayZone`, pour les rencontres, les mouvements, les hazards et les comportements gameplay.
- Le renderer Flame, qui assemble lui-meme ces contrats au moment de dessiner.

Cette dispersion explique pourquoi l'eau animee, les hautes herbes, la lave, la glace, les rails ou les ponts risquent de devenir des cas particuliers si on continue a empiler des comportements dans `ProjectPathPreset` et `MapLayersComponent`.

L'observation de Pokemon SDK / Pokemon Studio est pertinente, mais le concept a reprendre n'est pas Tiled lui-meme. Les idees utiles sont: atlas en grille, taille de tile explicite, colonnes de variantes, lignes de frames temporelles, durees de frames, horloge synchronisee, roles d'autotile, regles d'adjacence et separation entre rendu visuel, animation et gameplay.

## Portee de l'audit

Ce rapport est volontairement un cadrage technique. Aucun comportement runtime n'a ete modifie, aucun modele existant n'a ete supprime et aucune migration JSON n'a ete introduite.

Commandes Git utilisees: uniquement des commandes de lecture, notamment `git status --short` et `git diff --stat`.

Commandes Git interdites non utilisees: `git add`, `git commit`, `git push`, `git reset`, `git checkout`, `git restore`, `git stash`, `git merge`, `git rebase`, `git tag`.

## Etat du workspace

Le workspace etait deja sale avant la creation de ce rapport. Les changements existants semblent concerner surtout `examples/playable_runtime_host`, `packages/map_battle`, plusieurs fichiers de combat dans `packages/map_runtime`, des rapports `psdk-*`, ainsi que quelques fichiers non suivis.

Ce rapport n'a pas tente de nettoyer, restaurer ou modifier ces changements. Le seul fichier cree par cette mission est:

- `reports/analysis/surface_engine_initial_audit.md`

## Fichiers consultes

### Racine

- `AGENTS.md`

### map_core

- `packages/map_core/lib/map_core.dart`
- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_gameplay_zone_payloads.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/tileset.dart`
- `packages/map_core/lib/src/models/visual_frame_json.dart`
- `packages/map_core/lib/src/operations/map_path.dart`
- `packages/map_core/lib/src/operations/map_placed_element_animation.dart`
- `packages/map_core/lib/src/operations/map_terrain.dart`
- `packages/map_core/lib/src/operations/map_terrain_autotile.dart`
- `packages/map_core/lib/src/operations/path_animation_rules.dart`
- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_core/test/path_animation_triggers_test.dart`
- `packages/map_core/test/path_preset_frames_test.dart`
- `packages/map_core/test/placed_element_animation_test.dart`

### map_gameplay

- `packages/map_gameplay/pubspec.yaml`
- `packages/map_gameplay/lib/src/gameplay_encounter.dart`
- `packages/map_gameplay/lib/src/gameplay_world_state.dart`
- `packages/map_gameplay/test/movement_mode_water_test.dart`
- `packages/map_gameplay/test/path_animation_triggers_test.dart`

Note: aucun `README.md` n'a ete trouve dans `packages/map_gameplay` lors de cet audit.

### map_runtime

- `packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart`
- `packages/map_runtime/lib/src/infrastructure/runtime_tileset_image.dart`
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/runtime_path_autotile.dart`
- `packages/map_runtime/test/map_layers_component_render_pass_test.dart`
- `packages/map_runtime/test/placed_element_animation_runtime_test.dart`
- `packages/map_runtime/test/runtime_path_animation_trigger_playback_test.dart`
- `packages/map_runtime/test/runtime_path_autotile_animation_test.dart`

### map_editor

- `packages/map_editor/lib/src/application/models/path_autotile_set.dart`
- `packages/map_editor/lib/src/application/models/terrain_selection_mode.dart`
- `packages/map_editor/lib/src/application/services/path_autotile_resolver.dart`
- `packages/map_editor/lib/src/application/services/path_layer_editing_coordinator.dart`
- `packages/map_editor/lib/src/application/services/terrain_painting_coordinator.dart`
- `packages/map_editor/lib/src/application/services/terrain_preset_resolver.dart`
- `packages/map_editor/lib/src/application/use_cases/project_tileset_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/terrain_preset_use_cases.dart`
- `packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer/dialogs/import_tileset_dialog.dart`
- `packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart`
- `packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart`
- `packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart`
- `packages/map_editor/lib/src/ui/panels/tileset_palette/dialogs/element_frame_picker_dialog.dart`
- `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/animation/placed_element_animation_widgets.dart`
- `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/palette/tileset_palette_preview.dart`
- `packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart`

## Verification des chemins demandes

Tous les fichiers demandes explicitement existent sous les chemins indiques:

- `packages/map_core/lib/src/models/tileset.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/operations/map_path.dart`
- `packages/map_core/lib/src/operations/map_terrain.dart`
- `packages/map_core/lib/src/operations/map_terrain_autotile.dart`
- `packages/map_core/lib/src/operations/path_animation_rules.dart`
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/runtime_path_autotile.dart`
- `packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart`
- `packages/map_runtime/lib/src/infrastructure/runtime_tileset_image.dart`
- `packages/map_runtime/test/placed_element_animation_runtime_test.dart`
- `packages/map_runtime/test/runtime_path_autotile_animation_test.dart`
- `packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart`
- `packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart`
- `packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart`

## Role actuel des fichiers principaux

### `packages/map_core/lib/src/models/tileset.dart`

`TilesetConfig` decrit un tileset generique avec `id`, `name`, `relativePath`, `tileSize`, `tileProperties` et `customProperties`. `TileProperties` permet de stocker `isPassable` et des proprietes arbitraires par `tileId`.

Ce modele existe dans `map_core`, mais le modele projet utilise surtout `ProjectTilesetEntry` dans `project_manifest.dart`. Cela cree deja deux niveaux de representation: un `TilesetConfig` assez generique, et un modele projet plus riche cote editeur.

Point important: `TilesetConfig.tileSize` existe, mais beaucoup de flux actuels s'appuient sur `ProjectSettings.tileWidth` et `ProjectSettings.tileHeight`. Une future Surface Engine ne devrait donc pas supposer que tout est toujours en 32x32, meme si le modele Pokemon SDK observe travaille souvent en 32x32.

### `packages/map_core/lib/src/models/map_layer.dart`

`MapLayer` est une union Freezed avec:

- `TileLayer`, qui stocke une grille de `tileId`.
- `CollisionLayer`, qui stocke une grille de booleens.
- `TerrainLayer`, qui stocke une grille de `TerrainType`.
- `PathLayer`, qui stocke une grille de booleens, un `presetId`, des proprietes, un `PathAnimationMode` et des regles de trigger.

Le point cle est que `PathLayer` ne stocke pas une surface par cellule. Il stocke un masque booleen et reference un preset unique pour toute la couche. C'est simple et compatible avec un systeme de chemins, mais limite pour des surfaces modernes qui ont besoin de variations, de transitions, de gameplay et de rendu differencies.

Il n'existe pas encore de `SurfaceLayer`.

### `packages/map_core/lib/src/models/project_manifest.dart`

`ProjectManifest` centralise les definitions projet: tilesets, elements, presets terrain, presets path, encounter tables, maps, settings, folders et templates.

Les elements les plus importants pour ce sujet sont:

- `ProjectSettings`, avec `tileWidth`, `tileHeight` et `displayScale`.
- `ProjectTilesetEntry`, avec image source, scope, dossiers, entrees de palette et groupes d'elements.
- `TilesetSourceRect`, qui decrit une zone source en coordonnees de grille.
- `TilesetVisualFrame`, qui represente une frame visuelle avec `source`, `durationMs` et eventuellement un `tilesetId` override.
- `ProjectTerrainPreset`, qui relie un `TerrainType` a des variantes visuelles ponderees.
- `TerrainPresetVariant`, qui contient une liste de `TilesetVisualFrame`.
- `ProjectPathPreset`, qui relie un `PathSurfaceKind` a des variantes d'autotile.
- `PathPresetVariantMapping`, qui associe une `TerrainPathVariant` a une liste de frames.
- `PathAnimationTriggerRule`, qui decrit quand et comment une animation de path se declenche.

`TilesetVisualFrame` est une bonne primitive existante: elle est deja partagee entre elements, terrains et paths. En revanche, elle ne suffit pas a exprimer un atlas anime de surface sous forme declarative, par exemple "colonnes = variantes, lignes = frames temporelles".

### `packages/map_core/lib/src/models/enums.dart`

`TerrainType` est limite a `none`, `grass`, `dirt`, `sand`, `rock`, `stone`, `indoor`.

`PathSurfaceKind` est plus riche: `path`, `road`, `water`, `tallGrass`, `ice`, `lava`, `swamp`, `rails`, `bridge`, `special`, `custom`.

`TerrainPathVariant` contient dix-neuf variantes d'autotile: centre, extremites, lignes, coins exterieurs, coins interieurs, tees, croix et isole.

Le fait que `PathSurfaceKind` connaisse deja `water`, `tallGrass`, `ice`, `lava`, `rails`, etc. est un bon point d'ancrage. Mais dans l'editeur, toutes ces intentions ne sont pas encore vraiment authorables.

### `packages/map_core/lib/src/models/map_data.dart`

`MapGameplayZone` separe deja les comportements gameplay des couches visuelles. Les zones peuvent etre de type encounter, movement, hazard, special ou custom. C'est une tres bonne base conceptuelle pour eviter de melanger rendu visuel et comportement moteur.

Limite actuelle: les zones sont rectangulaires et ne sont pas encore reliees explicitement a une surface authorable. Les hautes herbes peuvent donc exister comme zone de rencontre et comme visuel, mais le lien entre les deux reste manuel ou implicite.

### `packages/map_core/lib/src/models/map_gameplay_zone_payloads.dart`

Ce fichier porte les payloads de gameplay:

- `EncounterZonePayload`, avec table de rencontres, type de rencontre et background de combat optionnel.
- `MovementZonePayload`, avec mode requis et modes autorises.
- `HazardZonePayload`.
- `SpecialZonePayload`.

Ces payloads confirment que le gameplay est deja pense comme un contrat separe. Une future surface ne devrait pas remplacer brutalement ces zones. Elle devrait plutot pouvoir proposer des valeurs par defaut ou des assistants pour creer les zones adaptees.

### `packages/map_core/lib/src/operations/map_path.dart`

Ce fichier manipule les `PathLayer`:

- creation et recherche de layer path;
- assignation d'un `presetId`;
- peinture et effacement de cellules booleennes;
- edition des proprietes;
- edition des triggers d'animation;
- changement du mode d'animation.

Le path est donc actuellement une couche de masque, pas une couche de surface riche. C'est un bon format de compatibilite, mais pas un modele suffisant pour representer une famille d'autotiles animee.

### `packages/map_core/lib/src/operations/map_terrain.dart`

Ce fichier manipule les `TerrainLayer`:

- peinture de rectangles en `TerrainType`;
- effacement en `TerrainType.none`;
- lecture du terrain a une cellule.

Le terrain est encore une enum par cellule, sans reference directe a un preset de surface. Le rendu choisit ensuite un preset via le `TerrainType`. Cela convient pour des sols simples, mais limite les surfaces personnalisees et les transitions riches.

### `packages/map_core/lib/src/operations/map_terrain_autotile.dart`

Ce fichier contient la logique pure de resolution d'autotile actuelle:

- calcul de masque cardinal nord/est/sud/ouest;
- resolution vers `TerrainPathVariant`;
- prise en compte partielle des diagonales pour certains coins interieurs;
- ajustements de bord de carte.

Cette logique est utile et testable, mais elle est tres specifique au schema actuel de `TerrainPathVariant`. Elle ne sait pas exprimer des regles par surface, des transitions entre materiaux differents, des variantes alternatives ponderees, des fallbacks declares ou des roles plus riches.

### `packages/map_core/lib/src/operations/path_animation_rules.dart`

Ce fichier normalise les regles d'animation de path, notamment en donnant des ids stables si une regle n'en a pas.

Il ne constitue pas un moteur d'animation de tile. Il gere la couche de declenchement et de normalisation des regles.

### `packages/map_core/lib/src/operations/map_placed_element_animation.dart`

Ce fichier contient le resolver d'animation le plus reutilise aujourd'hui:

- modes `none`, `loop`, `pingPong`;
- vitesse;
- autoplay;
- depart aleatoire deterministe;
- offset;
- durees de frames;
- one-shot.

Le runtime path/autotile reutilise ce resolver pour choisir une frame. C'est pratique, mais conceptuellement les animations de surfaces sont aujourd'hui derivees d'une primitive d'elements places. Une Surface Engine gagnerait a extraire une primitive plus neutre: timeline de tile, horloge, groupe de synchronisation et frame resolver deterministe.

### `packages/map_core/lib/src/validation/validators.dart`

Le validator verifie notamment:

- les references de tilesets;
- les frames visuelles;
- les presets terrain;
- les presets path;
- les regles d'animation de path;
- les tailles de grilles des layers.

Risque majeur observe: le validator interdit le partage d'un meme tileset entre presets terrain et presets path. Cette regle etait probablement utile pour eviter des ambiguites d'edition, mais elle deviendra discutable si les surfaces modernes partagent un atlas commun.

Le validator impose aussi des frames visuelles valides et des durees positives. Ces invariants seront utiles a conserver pour les surfaces.

### `packages/map_runtime/lib/src/presentation/flame/runtime_path_autotile.dart`

`RuntimePathAutotileSet` convertit un `ProjectPathPreset` en map runtime `TerrainPathVariant -> List<TilesetVisualFrame>`.

Il sait:

- retourner la frame statique d'une variante;
- retourner une frame loop selon `elapsedMs`;
- retourner une frame one-shot;
- respecter un override de `tilesetId` par frame.

Il ne sait pas:

- deduire une famille d'atlas animee depuis un layout colonne/ligne;
- appliquer un groupe de synchronisation explicite;
- choisir une variante alternative ponderee;
- gerer des fallbacks declares dans le modele runtime;
- exprimer des regles d'adjacence par type de surface.

Il depend directement de `ProjectPathPreset`, ce qui en fait aujourd'hui un adaptateur de compatibilite path plutot qu'un renderer de surfaces generique.

### `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`

Ce composant est le coeur du rendu Flame des maps.

Il fait beaucoup de choses:

- dessin des tile layers;
- dessin des terrain layers;
- dessin des path layers;
- dessin des entites;
- gestion de passes background/foreground;
- dessin optionnel de collision;
- resolution des presets terrain;
- resolution des presets path;
- animation des elements places;
- animation des terrains;
- animation des paths;
- resolution des triggers de path;
- fallback visuel quand un preset ou une frame manque.

Points positifs:

- le rendu utilise `FilterQuality.none` et `isAntiAlias = false` dans plusieurs chemins importants, ce qui est coherent avec du pixel art;
- les paths animes peuvent deja etre synchronises par le meme `elapsedMs`;
- les layers foreground/background existent deja;
- le runtime sait dessiner des frames issues de tilesets differents.

Limites:

- pas de moteur de surface separe;
- pas de moteur d'animation de tiles explicite;
- pas de cache statique / cellules animees clairement separees;
- pas de culling camera observe dans les boucles principales;
- logique runtime, animation et fallback visuel sont tres concentres dans un gros composant;
- les hautes herbes avec overlay au-dessus du bas du joueur ne sont pas un comportement de surface natif.

### `packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart`

Ce fichier collecte les tilesets requis pour lancer une map runtime. Il inspecte notamment:

- les tile layers;
- les elements places;
- les presets terrain;
- les presets path;
- les overrides de tilesets dans les frames.

Une future `ProjectSurfaceDefinition` devra etre integree ici, sinon les images d'atlas de surface ne seront pas chargees par le runtime.

### `packages/map_runtime/lib/src/infrastructure/runtime_tileset_image.dart`

`RuntimeTilesetImage` encapsule une image de tileset chargee et supporte le decoupage en chunks verticaux.

Il fournit:

- `drawImageRect`, capable de dessiner une source rect meme si elle traverse plusieurs chunks;
- `containsSourceRect`;
- `imageWidth`, `imageHeight`;
- `dispose`.

C'est une brique importante pour des grands atlas animes. Elle sait deja dessiner des rectangles source precis, mais elle ne gere pas de conversion magenta -> alpha. Les assets existants semblent donc supposes utiliser leur alpha natif.

### `packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart`

Le panneau palette gere les entrees de palette, les elements, les groupes d'elements, les frames et certains apercus.

Il montre que l'editeur possede deja des patterns UX reutilisables:

- selection d'une zone source;
- frames multiples;
- duree par frame;
- apercu anime;
- edition d'elements visuels.

Ces patterns peuvent inspirer Surface Studio, mais ils sont aujourd'hui orientes palette/elements, pas surface/autotile.

### `packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart`

Ce panneau est deja presente comme une "Surface Library". En pratique, il separe:

- `Terrains`;
- `Paths`.

Il donne acces aux presets, a leur details, a l'edition des sprites ou de mapping.

C'est probablement le meilleur point d'entree UI pour introduire progressivement Surface Studio, car le vocabulaire "surface" existe deja cote interface. Mais il ne faut pas simplement renommer les paths: il faut clarifier les concepts.

### `packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart`

Ce fichier contient beaucoup d'authoring actuel:

- creation et edition de presets terrain;
- creation et edition de presets path;
- selection de frames;
- duree d'animation;
- mapping manuel des variantes de path.

Point important: l'UI de creation d'un path expose seulement deux types de traversal: ground et water. Les `PathSurfaceKind` comme `tallGrass`, `ice`, `lava`, `swamp`, `rails`, `bridge`, `special` et `custom` existent dans le modele, mais ne sont pas authorables clairement depuis cette UI.

Autre point: les mappings path sont normalises vers des sources 1x1. Cela colle a un autotile simple par tile, mais ne couvre pas des motifs plus riches ou des morceaux multi-tiles.

### `packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart`

Ce workspace affiche le schema d'autotile et la zone de mapping sur atlas.

Il sait:

- presenter les variantes principales;
- presenter certains coins interieurs;
- afficher les frames d'une variante;
- ajouter, dupliquer, supprimer et reordonner des frames;
- editer les durees;
- animer un apercu.

Il est tres proche d'un futur outil de Surface Studio, mais reste lie a `TerrainPathVariant` et au mapping manuel. Il manque notamment un assistant "atlas vertical anime": colonnes de variantes, lignes de frames.

### `packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart`

Ce canvas permet de selectionner des zones dans un tileset et de creer des elements projet. Il s'appuie sur `ProjectSettings.tileWidth/tileHeight`.

Il ne permet pas encore de definir un atlas de surface, une grille d'animation, des roles d'autotile ou des variantes. C'est un autre point d'entree possible pour Surface Studio, surtout pour l'import/decoupage.

### `packages/map_editor/lib/src/application/models/path_autotile_set.dart`

Ce modele editeur fournit un set d'autotile par defaut pour les paths, avec une map `TerrainPathVariant -> List<TilesetVisualFrame>`.

Il peut fusionner des mappings par defaut et des mappings issus du preset. C'est utile cote editeur, mais attention: le runtime `RuntimePathAutotileSet` ne semble pas appliquer le meme fallback par defaut. Une variante visible en preview editeur pourrait donc ne pas exister de la meme facon au runtime si elle n'a pas ete materialisee dans le preset.

### `packages/map_editor/lib/src/application/services/path_autotile_resolver.dart`

Ce service resout le set d'autotile affiche dans l'editeur. Il utilise les defaults quand le preset n'a pas de variants.

Ce service peut devenir un adaptateur de compatibilite pendant la migration: `ProjectPathPreset` pourrait etre converti vers une surface legacy preview sans changer les donnees.

### `packages/map_editor/lib/src/application/services/terrain_painting_coordinator.dart`

Ce coordinator peint des `TerrainType` dans des `TerrainLayer`. Il efface les autres layers terrain pour eviter les conflits.

Il ne connait pas les surfaces personnalisees, les roles, les variantes ou les behaviors.

### `packages/map_editor/lib/src/application/services/path_layer_editing_coordinator.dart`

Ce coordinator peint des booleens dans un `PathLayer` et assigne un `presetId`.

Il montre la limite de granularite actuelle: une couche path = un masque + un preset. Pour une Surface Engine, il faudra soit creer une nouvelle couche, soit introduire un adaptateur de compatibilite qui conserve les `PathLayer` existants.

### `packages/map_editor/lib/src/application/use_cases/terrain_preset_use_cases.dart`

Ces use cases creent, mettent a jour et suppriment les presets terrain/path. Ils valident les references et appliquent des normalisations.

Risque important: ils imposent eux aussi la separation stricte entre tilesets de terrain et tilesets de path. Cette regle pourrait bloquer une bibliotheque de surfaces partageant un atlas.

### `packages/map_editor/lib/src/application/use_cases/project_tileset_use_cases.dart`

Ces use cases gerent l'import, la mise a jour et la suppression de tilesets projet.

Ils ne stockent pas encore de metadonnees de grille par tileset ou par surface atlas, au-dela du rect source utilise par les entrees/presets. Une Surface Engine aura besoin d'un endroit explicite pour dire: tile size, layout, transparence, roles et animation.

### `packages/map_gameplay/lib/src/gameplay_world_state.dart`

`GameplayWorldState` derive actuellement certaines cellules d'eau depuis les `PathLayer` dont le preset a `surfaceKind == PathSurfaceKind.water`, et depuis les zones gameplay de mouvement qui requierent `surf`.

Cela preserve une compatibilite pratique: une eau visuelle peut bloquer le joueur sans zone explicite. Mais c'est aussi une forme de couplage entre visuel et gameplay. Pour le futur, cette logique devrait devenir un pont de compatibilite, pas la seule source de verite.

### `packages/map_gameplay/lib/src/gameplay_encounter.dart`

La resolution des rencontres passe par les `MapGameplayZone` de type encounter. Elle ne depend pas directement de `TerrainType` ou `PathSurfaceKind`.

C'est sain pour les hautes herbes: l'herbe visuelle et la zone de rencontre doivent rester decouplees. Surface Studio pourrait seulement aider a creer/aligner les deux.

## Pourquoi le systeme actuel est insuffisant

### La surface n'est pas une entite metier

Aujourd'hui, une surface comme l'eau est une combinaison de path layer, path preset, frames, surface kind et logique runtime/gameplay. Une haute herbe serait encore plus composite: visuel, overlay, rencontre, animation locale et passabilite.

Sans entite `Surface`, chaque nouvelle famille de surface risque d'ajouter un comportement dans un endroit different.

### L'animation de tile n'est pas une primitive native

Les animations de paths et terrains reposent sur des listes de `TilesetVisualFrame` et sur le resolver des elements places. Cela fonctionne, mais il manque:

- timeline declarative de surface;
- groupe de synchronisation;
- layout atlas colonne/ligne;
- separation claire entre animation globale et animation locale;
- resolver deterministe dedie aux tiles;
- notion de frame commune entre plusieurs variantes d'une meme surface.

### L'autotiling est trop specifique

`TerrainPathVariant` et `resolvePathVariantAt` couvrent un schema simple de dix-neuf variantes. Ce schema ne suffit pas pour toutes les surfaces modernes:

- transitions entre surfaces differentes;
- bords et coins separes de la texture centrale;
- fallback explicite;
- variantes alternatives ponderees;
- role mapping flexible;
- surfaces non strictement "blob path".

### Les mappings sont trop manuels

L'editeur permet de mapper des variantes une par une. C'est puissant, mais lent et fragile pour des atlases animes. Pour l'eau Pokemon SDK-like, on veut pouvoir dire: cette colonne est telle variante, cette ligne est telle frame, chaque frame dure tant de millisecondes.

### L'eau fonctionne, mais comme un cas path

L'eau actuelle peut etre representee par `PathSurfaceKind.water`, dessinee par `RuntimePathAutotileSet` et animee par `MapLayersComponent`.

Mais le concept reste "path preset anime" plutot que "surface d'eau". Il manque les contrats natifs pour les bords, transitions, sync groups, fallback, preview animee structuree et comportement surf/encounter configure proprement.

### Les hautes herbes ne sont pas de l'eau verte

Les hautes herbes ont besoin:

- d'une passabilite normale;
- d'une zone ou d'un contrat de rencontre;
- d'un overlay au-dessus d'une partie du joueur;
- d'une animation locale au passage du joueur;
- de variations visuelles locales.

Le systeme path peut dessiner une surface, mais ne modele pas ces dimensions. Traiter les hautes herbes comme un path anime global serait architecturalement fragile.

### Le runtime concentre trop de responsabilites

`MapLayersComponent` est deja responsable du rendu, de l'animation, de la selection de frame, des fallbacks et d'une partie de la resolution de comportements. Une Surface Engine devrait sortir progressivement ces responsabilites dans des composants purs et testables.

### Le gameplay est partiellement separe, mais pas encore relie aux surfaces

`MapGameplayZone` est une bonne separation. Toutefois, l'eau de mouvement est derivee aussi du `PathSurfaceKind.water`. Il faudra conserver ce comportement pour les maps existantes, tout en introduisant un contrat plus explicite pour les nouvelles surfaces.

## Pourquoi l'eau Pokemon SDK parait plus belle et plus fluide

L'eau observee dans Pokemon SDK / Pokemon Studio beneficie d'un modele plus structure:

- un atlas organise en grille;
- des variantes d'autotile coherentes;
- des colonnes qui correspondent a des roles visuels;
- des lignes qui correspondent aux frames temporelles;
- une horloge commune;
- des durees de frames coherentes;
- des bords, coins et centres penses comme une famille;
- des morceaux partiels avec transparence alpha ou couleur cle;
- un mapping d'adjacence robuste;
- un rendu qui choisit une source deterministe par variant et frame.

Le schema conceptuel est simple:

```text
sourceX = columnIndex * tileWidth
sourceY = currentFrameIndex * tileHeight
sourceWidth = tileWidth
sourceHeight = tileHeight
```

PokeMap peut deja imiter cela manuellement avec plusieurs `TilesetVisualFrame`, mais ne peut pas encore le declarer comme structure native. C'est la difference importante: l'animation existe, mais elle n'est pas encore un langage de surface.

## Concepts a reprendre sans dependre de Tiled

Les concepts utiles sont independants de Tiled:

- atlas source;
- grille de tiles;
- taille de tile explicite;
- roles de variantes;
- layout d'animation par colonnes et lignes;
- durees de frames;
- groupe de synchronisation;
- resolver de frame deterministe;
- regles d'adjacence;
- transitions entre surfaces;
- alpha ou couleur de transparence;
- preview animee;
- compatibilite pixel-art sans filtering flou.

Ce qu'il ne faut pas reprendre aveuglement:

- les IDs historiques de Pokemon SDK;
- une dependance obligatoire a Tiled;
- le modele RMXP comme contrainte;
- une structure d'atlas unique imposee a tous les projets;
- un gros refactor global avant d'avoir des tests.

## Points d'integration pour de nouveaux modeles Surface

### `map_core`: source de verite des contrats

Le point d'entree naturel est `ProjectManifest`, avec une future collection optionnelle, par exemple `surfaceDefinitions`.

Un modele prudent pourrait separer:

- identite: `id`, `name`, `kind`, tags, dossier;
- visuel: `tilesetId`, tile width/height, transparence, preview;
- autotile: roles, regles, mappings, fallbacks;
- animation: timeline, durees, sync group, playback;
- gameplay: contrat ou template de zones, sans remplacer `MapGameplayZone`;
- compatibilite: lien optionnel vers un `ProjectPathPreset` legacy ou generation depuis legacy.

Cette collection devrait avoir une valeur par defaut vide pour ne pas casser les anciens projets.

### `map_core` operations

Ajouter un systeme de surface ne doit pas modifier immediatement `map_path.dart` ou `map_terrain.dart`. Les premiers micro-lots peuvent ajouter des operations pures de resolution:

- resolver de timeline;
- resolver d'atlas layout;
- adapter `ProjectPathPreset -> SurfaceDefinition` en lecture;
- tests de compatibilite.

### `map_core` validation

Les validators devront verifier:

- references de tilesets;
- dimensions de tile;
- frames et durees;
- roles obligatoires;
- fallbacks;
- coherence entre variantes et animation;
- compatibilite JSON.

Attention a la regle actuelle qui interdit le partage d'un tileset entre terrain et path. Une surface library moderne pourrait avoir besoin de partager un atlas entre plusieurs surfaces.

### `map_runtime`

Les points d'integration sont:

- `runtime_manifest_tilesets.dart`, pour charger les tilesets des surfaces;
- `runtime_path_autotile.dart`, comme adaptateur legacy ou premier backend de compatibilite;
- `map_layers_component.dart`, qui devrait deleguer progressivement a un renderer de surface;
- `runtime_tileset_image.dart`, deja utile pour les atlas grands et les source rects.

Une cible progressive serait:

```text
MapLayersComponent
  -> RuntimeSurfaceRenderer
       -> RuntimeSurfaceResolver
       -> TileAnimationClock / TileAnimationResolver
       -> SurfaceAutotileResolver
```

Mais ce decoupage ne doit pas arriver en un seul refactor.

### `map_editor`

Le panneau `terrain_editor_panel.dart` est le bon point d'entree UX, car il parle deja de "Surface Library".

Les composants reutilisables existent:

- selection atlas dans `tileset_editor_canvas.dart`;
- frame picking;
- edition de frames;
- preview animee;
- mapping workspace.

Le premier Surface Studio ne devrait pas tout refaire. Il peut commencer par un mode lecture/preview d'un `ProjectPathPreset`, puis ajouter un assistant de layout pour les atlas animes.

### `map_gameplay`

`map_gameplay` doit rester pur et ne pas connaitre Flutter/Flame.

La direction la plus saine:

- conserver `MapGameplayZone` comme source explicite des encounters et des mouvements speciaux;
- conserver temporairement le pont legacy `PathSurfaceKind.water -> requires surf`;
- ajouter plus tard un contrat de surface qui peut generer ou completer des zones gameplay;
- eviter de faire des hautes herbes une consequence automatique et opaque du visuel.

## Architecture cible proposee

### Surface Engine

Une Surface Engine devrait etre une couche metier qui sait decrire et resoudre une surface, sans dependre du renderer Flame.

Responsabilites:

- lire une definition de surface;
- resoudre le role d'autotile d'une cellule;
- choisir une variante;
- choisir une frame;
- produire une instruction de rendu pure.

### Tile Animation Engine

Le Tile Animation Engine devrait etre une primitive pure:

- timeline de frames;
- durees par frame;
- horloge globale ou locale;
- sync group;
- mode global loop;
- mode one-shot local;
- randomisation deterministe optionnelle pour variations, pas pour l'eau synchronisee.

Il peut reutiliser l'experience de `map_placed_element_animation.dart`, mais ne doit pas rester semantiquement accroche aux elements places.

### Surface Studio

Surface Studio dans l'editeur devrait permettre progressivement:

- importer ou choisir un atlas;
- definir la taille de tile;
- definir une grille;
- declarer un layout colonne/ligne;
- mapper les roles;
- previsualiser l'animation;
- configurer des comportements gameplay;
- tester l'autotiling sur une mini grille;
- sauvegarder une definition propre.

### Runtime Surface Renderer

Le renderer runtime devrait:

- recevoir des draw commands ou des resolutions de surface;
- garder `FilterQuality.none`;
- separer cellules statiques et animees;
- preparer un cache quand possible;
- culler selon la camera;
- gerer les overlays comme les hautes herbes sans melanger avec la logique de rencontre.

## Compatibilite et risques

### Ne pas casser les `PathLayer`

Les maps existantes utilisent `PathLayer`. Il faut conserver lecture, edition et runtime. Les surfaces peuvent d'abord s'ajouter a cote, puis fournir des adaptateurs.

### Ne pas casser les `ProjectPathPreset`

`ProjectPathPreset` est deja utilise par l'editeur, le runtime et le gameplay. Une migration brutale serait trop risquee. Il faut commencer par un pont de compatibilite.

### Ne pas casser les `TerrainLayer`

Les `TerrainLayer` stockent des `TerrainType`, pas des ids de surface. Changer cela demanderait une migration importante. A eviter au debut.

### Attention aux fichiers generes

Les modeles Freezed/JSON de `map_core`, `map_editor` et `map_runtime` impliquent `build_runner` si on modifie les schemas. Le premier vrai micro-lot de modele devra inclure les fichiers generes necessaires, mais seulement dans le package touche.

### Risque de partage de tilesets

La regle actuelle qui interdit de partager un tileset entre presets terrain et path peut devenir incompatible avec une Surface Library moderne. Il faudra la traiter explicitement, pas la contourner.

### Risque de divergence preview/runtime

L'editeur a des fallbacks de mapping via `PathAutotileSet.defaultForTileset`. Le runtime ne semble pas appliquer exactement le meme fallback. Avant d'ajouter des surfaces, il faut eviter d'amplifier cette divergence.

### Risque d'UI trompeuse

Le modele `PathSurfaceKind` contient beaucoup de valeurs, mais l'UI de creation expose surtout ground/water. Les utilisateurs pourraient croire que PokeMap supporte pleinement tall grass, lava, rails, etc., alors que ces comportements ne sont pas modelises.

### Risque de couplage gameplay/visuel

L'eau a actuellement un pont pratique: `PathSurfaceKind.water` implique une contrainte de surf dans certains chemins gameplay. Pour les nouvelles surfaces, il faut eviter d'ajouter des comportements implicites partout. Les hautes herbes doivent rester visuellement et gameplayement decouplees.

### Risque autour de la transparence magenta

Pokemon SDK peut utiliser des morceaux partiels avec couleur de transparence. PokeMap ne doit pas appliquer une conversion magenta globale sans option explicite, car cela pourrait detruire des assets ou des previews existantes.

### Risque de hardcoder le 32x32

Le prompt cite des tiles 32x32, mais PokeMap a deja des `ProjectSettings.tileWidth/tileHeight` et un `TilesetConfig.tileSize`. La Surface Engine doit supporter 32x32, pas l'imposer partout.

## Ordre de micro-lots propose

### Lot 0 - Rapport d'audit

Produire ce rapport, sans changement comportemental.

### Lot 1 - Tests de caracterisation de l'autotile existant

Ajouter des tests purs dans `map_core` pour `map_terrain_autotile.dart`:

- cellules isolees;
- lignes horizontales et verticales;
- coins exterieurs;
- coins interieurs;
- tees;
- croix;
- bords de carte;
- grilles invalides.

Objectif: verrouiller le comportement actuel avant toute extraction.

### Lot 2 - Extraire un resolver de timeline de tile

Creer une primitive pure de resolution de frames de tile, probablement dans `map_core` si elle reste sans Flutter.

Elle peut commencer comme facade autour des listes de `TilesetVisualFrame` et du comportement existant. Aucun schema JSON necessaire au depart.

Tests:

- durees par frame;
- boucle;
- one-shot;
- fallback frame statique;
- frames avec tileset override.

### Lot 3 - Ajouter un modele Surface minimal et non utilise

Ajouter une collection optionnelle vide dans `ProjectManifest`, par exemple `surfaceDefinitions`.

Le modele doit etre minimal:

- id;
- nom;
- type/kind;
- reference tileset;
- tile size ou heritage des settings;
- definition d'animation simple;
- mapping de roles minimal.

Important: aucune integration runtime obligatoire dans ce lot. Le but est la compatibilite JSON et les tests de serialization.

### Lot 4 - Adapter legacy `ProjectPathPreset -> Surface`

Creer un adaptateur pur qui transforme un `ProjectPathPreset` en representation surface runtime/editor en lecture seule.

Objectif: prouver que les paths existants peuvent etre vus comme des surfaces legacy sans migration.

### Lot 5 - Resolver de surface runtime pur

Ajouter un resolver runtime pur qui prend:

- une definition de surface ou un adaptateur legacy;
- les voisins;
- une horloge;
- un etat de playback;
- et retourne source rect + tileset + role.

Tester contre les attentes de `runtime_path_autotile_animation_test.dart`.

### Lot 6 - Integration runtime en mode compatibilite

Faire deleguer une petite partie de `MapLayersComponent` a ce resolver, sans changer le rendu attendu.

Verifier avec les tests runtime path/autotile existants et un test de rendu cible si possible.

### Lot 7 - Surface Studio preview read-only

Dans l'editeur, ajouter une preview de surface basee sur les presets path existants. Ne pas encore creer de nouveau format utilisateur complexe.

Objectif: valider l'UX et reutiliser `terrain_mapping_workspace.dart`.

### Lot 8 - Assistant atlas anime colonne/ligne

Ajouter un assistant capable de generer des mappings depuis un layout:

- colonnes = variantes;
- lignes = frames;
- duree commune ou duree par ligne;
- preview synchronisee.

Ce lot apporte le gain Pokemon SDK-like sans dependance Tiled.

### Lot 9 - Contrats gameplay de surface

Introduire des valeurs par defaut ou templates:

- eau: requires surf, encounters surf optionnels;
- hautes herbes: encounter walking optionnel, passable, overlay;
- lave: hazard optionnel;
- glace: movement modifier optionnel.

Ces contrats doivent aider a creer ou aligner des `MapGameplayZone`, pas remplacer abruptement le systeme de zones.

### Lot 10 - Hautes herbes comme surface distincte

Implementer explicitement:

- rendu base;
- overlay au-dessus du bas du joueur;
- animation locale au pas;
- lien optionnel vers encounter zone.

Ce lot doit volontairement eviter de reutiliser le comportement eau comme modele principal.

### Lot 11 - Optimisations runtime

Seulement apres stabilisation semantique:

- cache statique;
- split cellules animees;
- culling camera;
- invalidation fine.

## Tests existants a preserver

### map_core

- `packages/map_core/test/path_preset_frames_test.dart`
- `packages/map_core/test/path_animation_triggers_test.dart`
- `packages/map_core/test/placed_element_animation_test.dart`

Ces tests protegent deja les frames de presets path, les triggers d'animation et le resolver d'animation reutilise.

### map_gameplay

- `packages/map_gameplay/test/movement_mode_water_test.dart`
- `packages/map_gameplay/test/path_animation_triggers_test.dart`

Le test `movement_mode_water_test.dart` est critique pour la compatibilite de l'eau existante: walking bloque, surfing autorise, collision bloque encore, et les zones movement `surf` sont traitees comme eau.

### map_runtime

- `packages/map_runtime/test/runtime_path_autotile_animation_test.dart`
- `packages/map_runtime/test/runtime_path_animation_trigger_playback_test.dart`
- `packages/map_runtime/test/placed_element_animation_runtime_test.dart`
- `packages/map_runtime/test/map_layers_component_render_pass_test.dart`
- `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`

Ces tests protegent respectivement la selection de frames path, les triggers runtime, le resolver d'animation elementaire, les passes de rendu et un smoke runtime plus large.

### examples

- `examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart`

Ce smoke test est important pour verifier que les fixtures runtime restent chargeables.

### map_editor

Tests reperes comme pertinents par recherche, a conserver lors des lots editeur:

- tests de use cases de tilesets;
- tests de selection/coordinator de terrain;
- smoke tests de panels UI;
- tests autour des visuels d'elements.

Ces tests n'ont pas tous ete lus en detail dans cet audit, mais ils devront etre identifies precisement avant un lot Surface Studio.

## Nouveaux tests a ajouter

### Tests de caracterisation autotile

Ajouter un fichier de test pour `map_terrain_autotile.dart`, avant extraction:

- grille 1x1;
- ligne droite;
- coin;
- tee;
- croix;
- coin interieur par diagonale manquante;
- bord de carte;
- cellules hors layer;
- tailles invalides.

### Tests de timeline de tile

Ajouter des tests purs pour le futur resolver:

- frame unique;
- frames multi-durees;
- boucle exacte sur la somme des durees;
- elapsed egal a une frontiere de frame;
- one-shot avant, pendant et apres la fin;
- override tileset.

### Tests d'adaptateur legacy

Verifier que `ProjectPathPreset` converti en surface legacy produit:

- les memes variantes;
- les memes frames;
- les memes durees;
- les memes overrides de tileset;
- les memes fallbacks ou l'absence de fallback.

### Tests JSON de compatibilite

Quand `surfaceDefinitions` sera ajoute:

- ancien manifest sans surfaces se charge;
- nouveau manifest avec liste vide se round-trip;
- nouveau manifest avec surface minimale se round-trip;
- erreurs propres sur tileset inconnu ou dimensions invalides.

### Tests runtime de non-regression

Ajouter ou etendre:

- rendu path anime identique avant/apres delegation;
- selection de frame synchronisee entre plusieurs variantes;
- fallback si variante manquante;
- tile image source rect avec atlas large;
- absence de filtering flou si testable.

### Tests editor Surface Studio

Plus tard:

- assistant colonne/ligne genere les bons `TilesetVisualFrame`;
- durees preservees;
- preview utilise la meme timeline que runtime;
- mapping complet des roles;
- edition d'une surface n'altere pas les presets existants.

### Tests gameplay

Pour les surfaces gameplay:

- eau legacy continue de bloquer sans surf;
- surface eau nouvelle peut produire le meme contrat;
- hautes herbes declenchent des encounters via zone explicite;
- hautes herbes restent passables;
- overlay herbe n'implique pas rencontre si aucune zone n'existe.

## Questions et ambiguites techniques

### Quelle relation entre `TerrainType` et `SurfaceDefinition`?

Faut-il que les terrains historiques deviennent des surfaces, ou faut-il garder `TerrainType` comme classification simple? La reponse prudente est de garder les deux au debut et d'ajouter un adaptateur.

### Une cellule peut-elle porter plusieurs surfaces?

Exemples:

- sol + hautes herbes overlay;
- eau + reflet;
- pont au-dessus d'eau;
- rail sur sol;
- falaise avec bord.

Le modele actuel path/terrain ne repond pas clairement a cette question. Surface Engine devra probablement distinguer base, overlay et interaction layer.

### Les surfaces doivent-elles etre peintes par layer ou par cellule?

`PathLayer` impose un preset par couche. Une Surface Layer moderne pourrait stocker un id de surface par cellule, mais cela aurait un cout de migration et d'edition. Il faut trancher progressivement.

### Quelle est la bonne granularite du gameplay?

Une surface "eau" devrait-elle automatiquement exiger surf, ou seulement proposer un template? Pour les maps existantes, l'automatisme est utile. Pour le futur, un contrat explicite est plus sain.

### Comment modeliser les transitions entre deux surfaces?

Le systeme actuel resout surtout "cellule active vs inactive". Les transitions eau/terre, sable/herbe, boue/route ou lave/roche demandent peut-etre une notion de neighbor material et pas seulement un masque booleen.

### Comment gerer les assets avec couleur cle magenta?

Il faut definir si la conversion est:

- une option d'import;
- une propriete de tileset;
- une propriete de surface atlas;
- une operation destructive ou non destructive.

### Le tile size est-il global ou par surface?

Le prompt cite 32x32, mais le projet a `ProjectSettings.tileWidth/tileHeight` et `TilesetConfig.tileSize`. Une surface peut avoir besoin d'heriter du projet ou de definir explicitement son tile size.

### Quel est le scope exact de "Surface Studio"?

Surface Studio peut etre:

- un panneau de definitions;
- un assistant d'import;
- un editor d'autotile;
- une preview runtime;
- un generateur de gameplay zones.

Il vaut mieux commencer par un sous-ensemble tres clair.

## Ce que le prompt semble peut-etre discutable ou incomplet

### Le prompt parle beaucoup de 32x32, mais PokeMap est deja parametrable

Les exemples Pokemon SDK en 32x32 sont utiles, mais PokeMap ne devrait pas durcir cette taille. Les projets existants semblent pouvoir utiliser d'autres dimensions via `ProjectSettings`.

### Le terme "surface" peut recouvrir trop de choses

Route, eau, herbe, pont, falaise, rail et lave n'ont pas tous la meme nature. Certains sont des sols, certains sont des overlays, certains sont des obstacles, certains sont des zones de gameplay, certains sont des transitions.

Une architecture trop generique pourrait devenir abstraite et lourde. Il faut donc definir Surface comme un contrat compose, mais garder des sous-types ou capabilities explicites.

### L'eau est un excellent cas pilote, mais pas le seul modele

L'eau pousse vers animation globale synchronisee et autotile. Les hautes herbes poussent vers overlay, animation locale et encounters. Si le premier modele est trop centre sur l'eau, il deviendra insuffisant des le lot tall grass.

### Les zones gameplay sont deja une bonne idee

Le prompt insiste a raison sur le decouplage gameplay/visuel. Le repo a deja un debut solide avec `MapGameplayZone`. Il ne faut pas le jeter pour faire porter trop de gameplay directement aux surfaces.

### Il manque peut-etre une discussion sur les couches de rendu

Les hautes herbes, ponts, falaises et cascades impliquent des passes de rendu differentes. Le prompt mentionne le runtime renderer, mais il faudra probablement specifier des render planes ou des overlay roles.

### Il manque une strategie de migration utilisateur

Le prompt dit de ne pas casser les maps existantes, mais ne precise pas si les anciens path presets doivent rester authorables indefiniment, etre masques derriere Surface Studio, ou etre migrables explicitement. Cette decision produit compte beaucoup.

## Autocritique de l'analyse

Cette analyse est volontairement conservatrice. Elle privilegie les points d'integration et les risques plutot qu'un design final complet. C'est adapte a la demande initiale, mais cela signifie que certains choix restent ouverts:

- forme exacte des futurs modeles Freezed;
- nommage definitif des types Surface;
- strategie exacte de migration JSON;
- decomposition precise du renderer runtime;
- UX finale de Surface Studio.

Je n'ai pas execute les tests existants, car ce lot ne modifie aucun code executable et ne change aucun comportement. Les tests pertinents seront indispensables des le premier micro-lot de code, en particulier les tests purs de `map_terrain_autotile.dart` et les tests de compatibilite JSON si un modele Surface est ajoute.

J'ai aussi repere certains tests editeur par recherche sans tous les lire en detail. Avant un lot Surface Studio, il faudra faire un audit plus cible des tests `map_editor` et des providers/coordinators concernes.

## Conclusion

Le systeme actuel permet deja des surfaces simples et des animations ponctuelles, mais il n'a pas encore de Surface Engine. L'eau animee Pokemon SDK-like est plus fluide parce qu'elle est modelisee comme une famille coherente d'autotiles animes: variantes synchronisees, atlas structure, roles visuels et frame clock commune.

PokeMap peut reprendre ces concepts sans dependre de Tiled en introduisant progressivement:

- un modele Surface dans `map_core`;
- un Tile Animation Engine pur;
- un resolver d'autotile plus declaratif;
- un renderer de surface dans `map_runtime`;
- un Surface Studio dans `map_editor`;
- des contrats gameplay explicites, relies mais non confondus avec le visuel.

La migration doit commencer par des tests de caracterisation et des adaptateurs de compatibilite, pas par un refactor massif. Les `PathLayer`, `ProjectPathPreset`, `TerrainLayer` et `MapGameplayZone` existants doivent rester lisibles, editables et executables pendant toute la transition.
