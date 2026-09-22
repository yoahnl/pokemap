# AS-MAP-001 — Placements de la carte dans Avelune Studio

Reprise dans la page Carte d'Avelune Studio des capacités de placement que
l'ancien `map_editor` proposait. Ce rapport suit l'avancement lot par lot ; il
ne prétend pas que Studio remplace l'ancien éditeur.

## Inventaire des familles

L'ancien éditeur déclarait six familles de placement dans
`WorldMapPlacementSubtool` (`packages/map_editor/lib/src/features/editor/application/world_map_tool_family.dart`) :
`object`, `entity`, `event`, `trigger`, `warp`, `gameplayZone`.

Le modèle `MapData` porte huit collections : `layers`, `placedElements`,
`entities`, `connections`, `warps`, `triggers`, `gameplayZones`, `events`.
`map_core` fournit déjà les opérations partagées de chaque famille
(`map_warps.dart`, `map_gameplay_zones.dart`, `map_triggers.dart`,
`map_entities.dart`, `map_placed_elements.dart`, `map_connections.dart`).

| Famille | Opérations partagées | État au début du ticket | Classement |
| --- | --- | --- | --- |
| `object` → `placedElements` | `map_placed_elements.dart` | placer, déplacer, supprimer, devant/derrière, pile sous le curseur | déjà accessible |
| `entity` — npc | `map_entities.dart` | placer, déplacer, dupliquer, supprimer, renommer, orientation, blocage | déjà accessible |
| `entity` — sign, item, spawn, custom | mêmes opérations, payloads typés | `CharacterEditingCommands.place` force `kind: npc`, `at()` ne voit que les npc | existante, non raccordée |
| `warp` | `map_warps.dart` | aucune occurrence dans `apps/avelune_studio/lib` | réellement manquante |
| `gameplayZone` | `map_gameplay_zones.dart` (5 charges utiles) | aucune occurrence | réellement manquante |
| `trigger` | `map_triggers.dart` | créé à la main en `copyWith`, type `event` seul, jamais sélectionnable au clic | partiellement raccordée |
| `connection` | `map_connections.dart` | aucune occurrence | hors placement : liaison de bord entre cartes, pas un objet posé |
| `event` (`MapEventDefinition`) | legacy + `legacy_map_event_projection.dart` | remplacé par `NarrativeEventRecord` (écran Événements) | remplacé, à ne pas reprendre |
| tuiles, terrains, calques | `map_layers.dart`, `map_paint.dart` | peindre, terrains, masquage, devant/derrière | déjà accessible, conservé |

Trois distinctions que l'inventaire a permis de ne pas confondre :

- l'outil « zone » existant dessine une **zone d'histoire** (`MapTrigger` de type
  `event` relié à une interaction narrative, `narrative_navigation.dart`), pas
  une zone de gameplay ;
- un **décor visuel** (`MapPlacedElement`) n'est pas une **entité de gameplay**
  (`MapEntity`) : ce sont deux collections distinctes du modèle ;
- `MapEventDefinition` est le système que l'écran Événements remplace ; le
  raccorder recréerait un parcours abandonné.

## Lot 1 — Passages entre cartes

### Ce qui est repris

- une famille « Passages » dans la palette, qui liste les cartes du projet
  autres que la carte courante ;
- un outil « Placer un passage » dans la barre d'outils ;
- le tracé du passage sur la carte avec le nom de sa destination, et
  « Destination introuvable » quand la carte cible a disparu du projet ;
- la sélection au clic et le déplacement au glisser, avec aperçu ;
- un inspecteur : carte d'arrivée, case d'arrivée X et Y, déclenchement
  (à l'entrée ou au contact), ouverture de la carte d'arrivée, suppression ;
- annulation et rétablissement pas à pas, enregistrement et réouverture.

Les écritures passent toutes par les opérations partagées de `map_core`
(`addWarpToMap`, `updateWarpOnMap`, `removeWarpFromMap`) et leur validation.
`WarpEditingCommands` ajoute la seule garantie que `map_core` ne peut pas
donner, faute de connaître le manifeste : la carte de destination existe
réellement dans le projet.

### Tests

| Fichier | Ce qu'il mesure | Tests |
| --- | --- | --- |
| `test/map_workspace/warp_editing_test.dart` | destination retenue, destinations proposées, destination disparue, familles voisines intactes, validation partagée, annulation pas à pas | 6 |
| `test/map_workspace/warp_canvas_test.dart` | pose au clic, identité après zoom et panoramique, déplacement au glisser et annulation, priorité de sélection face à un personnage | 4 |
| `test/map_workspace/warp_runtime_destination_test.dart` | survie à l'enregistrement et à la réouverture, destination lue par le moteur de jeu, mode de déclenchement respecté | 3 |
| `test/map_workspace/warp_visual_test.dart` | palette et inspecteur à 1536×1024 et 1024×640 ×1.5, captures | 2 |

Le test d'identité après zoom calcule le point cliqué depuis le viewport et la
matrice en vigueur, jamais depuis la boîte du canvas mesurée : une erreur
d'échelle ne peut pas s'y annuler. Vérifié par le négatif — une erreur de 10 %
introduite dans `_cell` fait tomber deux des quatre tests du canvas.

### Limites de ce lot

- la case d'arrivée est validée comme positive, pas contre la taille réelle de
  la carte de destination : celle-ci n'est pas chargée quand l'inspecteur
  s'affiche. Le test runtime vérifie la borne, l'interface ne la vérifie pas ;
- `allowedApproachFacings` et `triggerPadding` existent dans le modèle et ne
  sont pas exposés dans l'inspecteur ;
- un passage occupe une seule case ; l'ancien éditeur permettait une marge de
  déclenchement.

### Effets de bord assumés

- `StudioPaletteTabs` resserre ses onglets au-delà de quatre items (marge
  verticale et interligne réduits). En dessous de cinq, rien ne change, donc les
  deux autres usages (terrains) ne bougent pas. Sans cela, le cinquième onglet
  faisait déborder la barre latérale de 9 px à 1024×640, ce que
  `desktop_workspace_layout_test` a détecté.

  Deux approches ont été essayées puis rejetées avant celle-ci : trois colonnes,
  qui tronquait « Personnages » et « Passages » ; une barre défilante
  horizontale, qui sortait l'onglet actif du champ et faisait tomber six tests
  existants du plan de travail.
- extraction de `MapWorkspacePaletteColumn` depuis `map_workspace_layout.dart`,
  de `buildEditingOverlay` depuis `map_workspace_canvas.dart`, et
  factorisation du dessin des libellés dans `MapCanvasOverlay`, pour rester sous
  le plafond de 300 lignes. Aucun changement de comportement.

## Lot 2 — Point de départ du joueur et panneaux

Ce lot est passé devant les zones de gameplay pour une raison mesurée : le
moteur refuse une carte sans point d'apparition joueur
(`GameplaySpawnResolutionException`, `player_spawn_resolver.dart`). Aucune carte
construite dans Studio n'était jouable, et les tests runtime du lot 1 ont dû
fournir un `spawn` à la main.

### Ce qui est repris

- un outil « Placer le départ du joueur » et un outil « Placer un panneau » ;
- le tracé des deux familles sur la carte avec leur libellé ;
- la sélection au clic et le déplacement au glisser ;
- un inspecteur de point d'apparition : rôle (départ du joueur, apparition PNJ,
  événement, mise au point), regard, suppression, et le rappel qu'une carte sans
  départ ne peut pas être jouée ;
- un inspecteur de panneau : titre, texte affiché, blocage du passage,
  suppression. Le nom de l'entité suit le titre pour que la carte reste lisible.

`MapEntityEditingCommands` couvre les entités non-npc et passe par
`addEntityToMap`, `updateEntityOnMap`, `moveEntityOnMap`,
`removeEntityFromMap`. Les personnages gardent `CharacterEditingCommands`,
qui reste adossé au catalogue de personnages du projet.

### Tests

| Fichier | Ce qu'il mesure | Tests |
| --- | --- | --- |
| `test/map_workspace/entity_editing_test.dart` | carte injouable sans départ puis jouable avec, départ suivi au déplacement, rôle lu et non supposé, texte du panneau, refus de poser un personnage, annulation pas à pas | 6 |
| `test/map_workspace/entity_canvas_test.dart` | pose et sélection en un clic, glisser et annulation, priorité du personnage, familles voisines intactes | 4 |
| `test/map_workspace/marker_visual_test.dart` | inspecteurs de départ et de panneau à 1024×640, captures | 2 |

### Limites de ce lot

- la famille `item` n'est pas reprise : son `gameItemId` renvoie au catalogue
  `data/pokemon/catalogs/items.json`, qu'aucun port de Studio n'expose
  aujourd'hui. Poser un objet demanderait un champ d'identifiant libre, donc des
  références invalides sans le dire. C'est un chantier à part entière ;
- la famille `custom` n'est pas reprise non plus, faute de charge utile typée ;
- le `DialogueRef` d'un panneau n'est pas exposé : seul le texte simple l'est ;
- rien n'empêche encore de poser deux départs du joueur sur une même carte.

### Effet de bord assumé

La zone d'outils de la colonne palette est bornée à 40 % de la hauteur
disponible et défile au-delà. Sans cela, neuf outils faisaient déborder la
colonne aux petites hauteurs, comme le cinquième onglet du lot 1.

## Lot 3 — Zones de gameplay

### Ce qui est repris

- un outil « Dessiner une zone de jeu » : un glisser trace la zone, un clic
  simple sur une zone existante la retrouve pour la modifier, un clic sur du
  vide crée une zone d'une case ;
- le tracé des zones sur la carte avec leur nom ;
- un inspecteur : nom, type (rencontres, déplacement requis, effet de surface,
  danger, spéciale), priorité, suppression, et les propriétés propres au type —
  table de rencontres du projet, mode de déplacement requis, effet et coût par
  pas, nature du danger et dégâts par pas ;
- un avertissement quand une zone de rencontres n'a pas de table, ou quand sa
  table a disparu du projet.

Changer le type déplace la charge utile : l'ancienne est effacée, la nouvelle
créée, et le nom par défaut suit le type tant que l'auteur ne l'a pas écrit
lui-même.

### Tests

| Fichier | Ce qu'il mesure | Tests |
| --- | --- | --- |
| `test/map_workspace/gameplay_zone_editing_test.dart` | rectangle et charge utile, table absente ou disparue, changement de type, propriétés par type, déplacement, redimensionnement, priorité, superposition, annulation | 6 |
| `test/map_workspace/gameplay_zone_canvas_test.dart` | tracé au glisser, séparation d'avec la zone d'histoire, familles voisines intactes, re-sélection au clic, création au clic sur du vide, non-capture en mode sélection | 6 |
| `test/map_workspace/gameplay_zone_runtime_test.dart` | une zone dangereuse blesse réellement le joueur, une zone sans dégâts reste inerte, la priorité décide entre deux zones superposées | 3 |
| `test/map_workspace/zone_visual_test.dart` | inspecteurs rencontres et danger à 1024×640, captures | 2 |

### Limites de ce lot

- le type se choisit après le tracé, dans l'inspecteur : l'outil pose toujours
  une zone de rencontres par défaut ;
- les propriétés libres d'une zone `special` ne sont pas éditables ;
- le fond de combat, la musique et les transitions d'une zone de rencontres
  existent dans le modèle et ne sont pas exposés ;
- la zone se déplace et se redimensionne par commande, pas encore par
  poignées sur la carte ;
- le type `custom` du modèle est nommé mais jamais proposé : le modèle le
  réserve aux extensions et déconseille son usage dans du code neuf.

## Lot 4 — Zones d'histoire modifiables

La création passait par un `copyWith(triggers: [...])` écrit à la main dans
`narrative_navigation.dart`, donc sans normalisation ni validation, et aucune
zone d'histoire n'était sélectionnable depuis la carte.

### Ce qui est repris

- la création passe désormais par `addTriggerToMap` : un identifiant en double
  ou une zone hors carte est refusé au lieu d'entrer dans le document ;
- un clic simple avec l'outil « zone d'histoire » retrouve la zone sous le
  curseur au lieu d'en ouvrir une nouvelle ; sur du vide, le parcours narratif
  s'ouvre comme avant ;
- un inspecteur : nom, rappel de ce qui tient la zone, suppression ;
- la suppression est refusée quand une interaction de l'histoire s'appuie sur
  la zone, en relisant `buildNarrativeDependencyIndex` comme le fait déjà la
  suppression d'un personnage. Le bouton est alors désactivé et nommé.

Le parcours narratif lui-même n'est pas touché : tracer une zone sur du vide
crée toujours le trigger puis ouvre l'éditeur d'interaction.

### Tests

| Fichier | Ce qu'il mesure | Tests |
| --- | --- | --- |
| `test/map_workspace/trigger_editing_test.dart` | validation partagée à la création, renommage, déplacement, redimensionnement, suppression et annulation, refus de suppression quand l'histoire s'en sert, zone sous un point, re-sélection au clic sans ouvrir d'interaction | 5 |
| `test/map_workspace/trigger_visual_test.dart` | inspecteur à 1024×640, capture | 1 |

### Limites de ce lot

- seuls les triggers de type `event` sont tracés et retrouvés sur la carte ;
  les autres types du modèle (`warp`, `message`, `interaction`, `spawn`,
  `camera`, `custom`) ne sont ni posés ni listés ;
- l'inspecteur n'offre pas encore de raccourci vers l'interaction liée ;
- le déplacement et le redimensionnement existent en commande, sans poignées
  sur la carte.

## Captures

- `captures/asmap001-passages-1536.png` — palette et inspecteur de passage à 1536×1024.
- `captures/asmap001-passages-1024.png` — le même à 1024×640 avec texte ×1.5.
- `captures/asmap001-spawn.png` — inspecteur du point de départ à 1024×640.
- `captures/asmap001-sign.png` — inspecteur du panneau à 1024×640.
- `captures/asmap001-zone-encounter.png` — inspecteur d'une zone de rencontres.
- `captures/asmap001-zone-hazard.png` — inspecteur d'une zone dangereuse.
- `captures/asmap001-story-zone.png` — inspecteur d'une zone d'histoire.

La troncature d'un libellé dans un menu déroulant ne lève aucune exception :
elle a été vue sur la capture, pas par un test. Les libellés de déclenchement
ont été raccourcis pour cette raison.

## Lots restants

| Lot | Objet | État |
| --- | --- | --- |
| 1 | passages entre cartes | livré |
| 2 | point de départ du joueur et panneaux | livré |
| 3 | zones de gameplay (rencontres, mouvement, effet, danger, spéciale) | livré |
| 4 | zones d'histoire sélectionnables et modifiables, création via `addTriggerToMap` | livré |

Les familles `item` et `custom` restent hors de portée tant que Studio n'expose
pas le catalogue d'objets ; c'est dit dans les limites du lot 2, pas escamoté.

## Ce que ce ticket ne fait pas

- il ne remplace pas `map_editor` : les familles `item` et `custom`, les
  propriétés avancées des rencontres, les poignées de redimensionnement sur la
  carte et les liaisons de bord (`connections`) restent hors de Studio ;
- il ne touche ni au clic droit (AS-MAP-002) ni à l'export ;
- il ne refond rien du Narrative Studio : le parcours des zones d'histoire est
  conservé, seule sa création est passée par la validation partagée.
