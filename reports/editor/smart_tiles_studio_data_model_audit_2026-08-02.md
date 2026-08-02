# Audit complet — Smart Tiles Studio, terrains, chemins et bordures

Date : 2026-08-02  
Dépôt : `/Users/karim/Project/pokemonProject`  
Révision auditée : `0816d2903` (`main`)  
Type de travail : audit en lecture seule du code produit ; aucun correctif produit, aucune mise à jour de roadmap  
Lot proposé : **STS-CONSOLIDATION-01 — contrat d'authoring Terrain / Path / Border**  
Statut proposé : **BLOCKED pour le flux d'authoring utilisateur**, **PARTIAL pour le moteur Smart Tile et ses transports**

## 1. Verdict exécutif

L'impression de blocage est confirmée. Le problème principal n'est pas une corruption générale de la sérialisation Smart Tile : le modèle `SmartTileLayer`, son codec JSON, son résolveur visuel et le rendu runtime disposent de bases solides et de tests verts. Le blocage vient d'une **migration d'architecture inachevée** :

1. l'ancien système `TerrainLayer` / `PathLayer` reste présent, rendu et partiellement éditable ;
2. le nouveau système `SmartTileLayer` / `ProjectSmartTileCatalog` a été ajouté avec son propre contrat ;
3. le Smart Tiles Studio ne permet aujourd'hui de créer de façon guidée que les chemins ERW16 ;
4. l'éditeur World Map, les actions canoniques `map_authoring`, JSONL et MCP ne partagent pas encore le même flux sémantique ;
5. un patch local non commité tente de reconnecter le World Map aux Smart Tiles, mais il remplace la compatibilité legacy au lieu de l'étendre et modifie simultanément des invariants fondamentaux du terrain.

Il en résulte un système où chaque sous-ensemble peut passer ses tests isolément tout en ne constituant pas un parcours utilisateur cohérent de bout en bout. En pratique, à `HEAD`, un calque Smart Tile publié par le Studio ne peut pas être armé comme calque Terrain/Chemin par le flux normal de peinture World Map. Dans le patch local, ce sont inversement les anciens calques Terrain/Chemin qui deviennent inéligibles.

### Sévérités

| Sévérité | Nombre | Synthèse |
|---|---:|---|
| P0 | 0 | Pas de preuve de perte de données automatique ou de corruption irréversible. |
| P1 | 3 | Routage d'outil incompatible, contradiction des invariants terrain/vide, absence de contrat canonique de bout en bout. |
| P2 | 10 | Studio limité au chemin, publication/sauvegarde non atomique, migration hors API, culling et offsets, parité MCP, gardes et validation de publication incomplètes. |
| P3 | 5 | Ordre de composition implicite, vocabulaire ambigu, libellés/choix/onglets de Studio encore incomplets. |

### Statuts proposés des lots Smart Tiles existants

Ces statuts sont une proposition d'audit ; la spec/roadmap n'a pas été modifiée.

| Lot | Objectif de la spec | Statut proposé | Motif |
|---|---|---|---|
| `STS-01` | données natives sérialisables | `PARTIAL` à confirmer | modèles/codecs solides, mais invariant Terrain non stabilisé |
| `STS-02` | moteur pur testé | `PARTIAL` | résolveur testé, mais culling/offsets et contrats legacy restent incomplets |
| `STS-03` | création d'un brouillon | `PARTIAL` | shell présent, tranche guidée limitée |
| `STS-04` | preset complet éditable | `BLOCKED` | Terrain/Forêt non guidés, presets existants largement read-only |
| `STS-05` | preset validable/publiable | `PARTIAL` | publication présente, validation globale et persistance non atomique |
| `STS-06` | utilisation réelle en map | `PARTIAL` | moteur de peinture présent, raccordement `HEAD` bloqué et WIP régressif pour legacy |
| `STS-07` | parité/gate de livraison | `BLOCKED` | parité legacy, quatre transports et acceptance locale non démontrées |

## 2. Réponse directe aux symptômes

### « Je ne peux plus placer de terrains »

Confirmé pour le nouveau système : le Studio affiche un usage Terrain, mais sa création guidée est désactivée. La seule tranche guidée implémentée est le chemin ERW16. Un preset Terrain déjà présent ou migré peut exister, mais le produit ne fournit pas encore un parcours complet et canonique pour le créer, le publier, l'ajouter, armer le bon outil et le peindre.

### « Je ne peux plus mettre de chemins »

Confirmé à `HEAD` pour un chemin Smart Tile : l'activation Paint reconnaît les `TerrainLayer` et `PathLayer` legacy, pas les `SmartTileLayer` avec `usage == path`. Le Studio peut publier et ajouter un calque Smart Tile, mais le World Map ne l'arme pas comme chemin dans le flux normal.

Le patch local en cours inverse le problème : il reconnaît les Smart Tiles Terrain/Chemin, mais retire les types legacy de la compatibilité Paint. Cela ne constitue pas encore une migration sûre.

### « Les bordures ne fonctionnent pas comme les terrains et chemins »

Confirmé, mais c'est en partie intentionnel : les bordures de carte sont modélisées par `BorderLayer` et `BorderLayerContent`, avec blueprint, géométrie et matérialisation. Elles ne sont pas un `SmartTileUsage`. À côté, un `SmartTileLayer` contient des `horizontalEdges`, `verticalEdges` et `corners` pour résoudre les transitions graphiques. Les deux concepts utilisent un vocabulaire proche sans partager le même workflow. Le produit doit rendre cette séparation explicite et fournir un parcours guidé distinct pour les bordures.

## 3. Périmètre, méthode et non-objectifs

### Périmètre inspecté

- contrats et codecs `map_core` ;
- opérations de calque, resize, validation et migration legacy ;
- actions et batch `map_authoring` ;
- Smart Tiles Studio et World Map dans `map_editor` ;
- rendu éditeur et runtime ;
- transports direct API, JSONL/CLI et MCP ;
- tests ciblés, analyse statique et historique Git pertinent ;
- documentation de conception Smart Tiles et tranche guidée ERW16.

### Méthode

- comparaison du contrat documenté, de `HEAD` et du worktree non commité ;
- traçage des flux create → publish → add layer → activate → paint → save → reload → render ;
- recherche des deux familles legacy et Smart ;
- exécution de tests/analyzers ciblés ;
- vérification du catalogue MCP vivant ;
- passes indépendantes données/architecture, éditeur/UX, tests/runtime/MCP, puis critique finale.

### Non-objectifs

- aucun correctif de code ;
- aucune suppression de legacy ;
- aucune migration de projet utilisateur ;
- aucune décision arbitraire sur la densité du terrain ;
- aucune mise à jour du roadmap mécanique fangame : cet audit porte sur l'infrastructure d'authoring, pas sur un lot `FG-*`.

Le dépôt demande normalement d'ajouter un test rouge avant une correction. La requête présente étant explicitement un audit, modifier les tests ou le produit aurait dépassé l'autorisation. Les tests existants ont été exécutés comme preuve.

## 4. État Git initial et condition d'audit

### État initial observé

```text
 M packages/map_authoring/test/domains/maps/map_operations_batch_test.dart
 M packages/map_core/lib/src/operations/map_resize.dart
 M packages/map_core/lib/src/operations/smart_tile_layer_operations.dart
 M packages/map_core/lib/src/validation/validators.dart
 M packages/map_core/test/smart_tiles/smart_tile_layer_operations_test.dart
 M packages/map_editor/lib/src/features/editor/application/world_map_tool_activation.dart
 M packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_layers_inspector.dart
 M packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_paint_inspector.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/test/features/editor/application/world_map_paint_layer_routing_test.dart
 M packages/map_editor/test/features/editor/application/world_map_tool_activation_test.dart
 M packages/map_editor/test/features/editor/presentation/world_map/world_map_layers_inspector_test.dart
 M packages/map_editor/test/features/editor/presentation/world_map/world_map_paint_inspector_test.dart
 M packages/map_editor/test/smart_tiles_studio/smart_tile_map_editing_test.dart
?? packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_smart_tile_paint_palette.dart
?? skills/creating-pokemap-maps-from-reference/scripts/__pycache__/inventory_assets.cpython-314.pyc
```

Le worktree était donc déjà sale avant l'audit. Pendant l'audit, des modifications externes supplémentaires sont apparues dans le design system et ses tests. Aucun de ces changements ne provient de cet audit. Cette évolution simultanée impose de séparer explicitement :

- **HEAD** : comportement livré par `0816d2903` ;
- **WIP local** : correctif non commité, instable pendant l'observation ;
- **rapport** : seul fichier créé par le présent audit.

## 5. Cartographie du modèle de données

### 5.1 Famille legacy

| Concept | Modèle | Édition | Rendu | Statut |
|---|---|---|---|---|
| Terrain | `TerrainLayer` + définitions terrain | outils historiques de peinture | encore rendu éditeur/runtime | maintenu, non déclaré read-only |
| Chemin | `PathLayer` + path presets/patterns | outils historiques de peinture | encore rendu éditeur/runtime | maintenu, migration explicite disponible |
| Bordure | `BorderLayer` + features/blueprints | workflow géométrique/procédural | matérialisation dédiée | système séparé, encore canonique |

### 5.2 Famille Smart Tile

`MapLayer` est une union sérialisée qui inclut désormais `SmartTileLayer`. Le discriminant `MapLayerKind.smartTile` et les codecs sont présents. Le calque stocke :

- `presetId` ;
- `usage` ;
- `materialPalette` ;
- `materialCells` ;
- `horizontalEdges` ;
- `verticalEdges` ;
- `corners`.

Sources principales :

- [map_layer.dart](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_layer.dart:102)
- [enums.dart](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/enums.dart:146)
- [smart_tile.dart](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/smart_tile.dart:1)
- [smart_tile_resolver.dart](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/operations/smart_tile_resolver.dart:118)

Cette structure est saine pour représenter une topologie Smart Tile : la grille de matières est distincte des arêtes et coins résolus. Les round-trips JSON et validations v4 sont testés. Le défaut n'est donc pas « un seul mauvais JSON », mais l'absence d'un contrat unique de création et mutation entre les couches applicatives.

### 5.3 Deux sens différents de « bordure »

```text
SmartTileLayer
  ├── materialCells       matière logique par cellule
  ├── horizontalEdges     transition locale entre cellules
  ├── verticalEdges       transition locale entre cellules
  └── corners             transition locale aux intersections

BorderLayer
  ├── feature             objet/segment de bordure de carte
  ├── published blueprint règles procédurales
  ├── geometry            forme de niveau/carte
  └── materialization     éléments rendus/collisionnables
```

Recommandation : conserver ces contrats séparés. Une bordure procédurale n'est pas simplement un matériau peint. En revanche, le produit doit employer des libellés non ambigus, par exemple « transitions Smart Tile » et « bordures procédurales de carte ».

## 6. Flux réels de bout en bout

### 6.1 Flux souhaité

```text
Studio
  → créer/modifier un preset dans le catalogue projet
  → valider et publier le preset
  → persister le catalogue avant toute référence de map
  → ajouter un SmartTileLayer
  → armer automatiquement le bon outil
  → peindre / remplir / effacer
  → sauvegarder map + projet de façon cohérente
  → recharger
  → résoudre et rendre dans éditeur + runtime
```

### 6.2 Flux observé à HEAD

```text
Studio Path ERW16
  → publie le manifest en mémoire
  → ajoute SmartTileLayer à la map en mémoire
  → World Map Paint ne reconnaît pas ce SmartTileLayer
  → blocage avant peinture normale
```

Le moteur de peinture existe déjà dans [editor_notifier.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart:5600) et une opération dédiée existe à [editor_notifier.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart:5717). Le canvas appelle bien le flux Terrain à [map_canvas.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/map_canvas.dart:1116). L'interruption se situe principalement dans l'éligibilité et l'activation du calque, pas dans l'absence absolue d'une fonction de peinture.

### 6.3 Flux observé dans le WIP local

Le patch local modifie [world_map_tool_activation.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/application/world_map_tool_activation.dart:177) pour router `SmartTileLayer(usage: terrain/path)` et ajoute une palette Smart Tile non suivie par Git. Mais il retire simultanément `TerrainLayer` et `PathLayer` de la compatibilité. Le bon changement transitoire doit être **additif** : accepter legacy et Smart tant que la migration explicite n'est pas achevée.

## 7. Findings détaillés

### P1-01 — Le World Map et le Studio ne partagent pas le même contrat d'activation

**Preuve**

- À `HEAD`, `world_map_tool_activation.dart` ne reconnaît que `TerrainLayer` et `PathLayer` pour les outils Terrain/Chemin.
- `addSmartTileLayer` crée bien un `SmartTileLayer` dans [editor_notifier.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart:9240).
- Le Studio publie puis appelle l'ajout de calque à [smart_tiles_studio_panel.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/smart_tiles_studio/presentation/smart_tiles_studio_panel.dart:1857).
- Aucun armement canonique de l'outil n'est garanti à la sortie de ce flux.

**Conséquence**

Un utilisateur peut terminer la publication mais ne pas pouvoir utiliser le résultat dans la carte. C'est le blocage utilisateur principal.

**WIP**

Le WIP corrige l'éligibilité Smart, mais casse l'éligibilité legacy. Une bascule destructive sans migration ni message utilisateur viole le principe de coexistence documenté.

**Recommandation**

Introduire une politique d'activation unique par `MapLayerKind` et `SmartTileUsage`, supportant temporairement les deux familles. Le Studio doit pouvoir demander atomiquement « ajouter et activer » via une action applicative canonique.

### P1-02 — Trois représentations contradictoires du vide/terrain

**Contrat à HEAD**

- un seul provider terrain principal ;
- un calque Smart Terrain initialisé avec l'index palette `1` partout ;
- la validation interdit l'index `0` dans les cellules Terrain.

**Contrats concurrents**

- `smart_tile.layer.normalize` et certaines opérations d'effacement remettent les lattices à `0` ;
- le batch final valide ensuite la map et peut rejeter ce résultat ;
- le résolveur interprète `0` comme vide ;
- la migration legacy peut créer un matériau explicite `isEmpty` ;
- le WIP autorise plusieurs terrains, initialise à `0` et remplit les extensions de resize à `0`.

Sources :

- [layer_actions.dart](/Users/karim/Project/pokemonProject/packages/map_authoring/lib/src/domains/maps/layer_actions.dart:234)
- [region_operations.dart](/Users/karim/Project/pokemonProject/packages/map_authoring/lib/src/domains/maps/region_operations.dart:114)
- [map_operations_batch.dart](/Users/karim/Project/pokemonProject/packages/map_authoring/lib/src/domains/maps/map_operations_batch.dart:175)
- [legacy_smart_tile_migration.dart](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/operations/legacy_smart_tile_migration.dart:465)
- [smart_tile_resolver.dart](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/operations/smart_tile_resolver.dart:118)

**Conséquence**

Selon le point d'entrée, effacer une cellule peut être légal, rejeté par validation, ou représenté par une matière spéciale. Le resize peut inventer du terrain ou, dans le WIP, agrandir une base terrain avec du vide. Les tests locaux reflètent la nouvelle décision WIP, mais la documentation et `HEAD` reflètent encore l'ancienne.

**Recommandation**

Avant de fusionner le WIP, prendre une décision d'architecture écrite :

1. `0` est-il l'unique représentation canonique du vide ? Recommandation : oui ;
2. un Terrain Smart doit-il être dense ou sparse ?
3. la map accepte-t-elle un seul provider terrain ou plusieurs calques composés ?
4. comment resize, erase, merge et migration préservent-ils ce contrat ?

Ensuite seulement aligner modèle, validators, opérations, migration, specs et tests dans un même lot.

### P1-03 — L'éditeur contourne la couche canonique `map_authoring`

Le Smart Tiles Studio et `EditorNotifier` mutent majoritairement les contrats core directement. La couche `map_authoring` n'expose que deux actions Smart dédiées :

- `smart_tile.layer.normalize` ;
- `smart_tile.layer.merge`.

Il n'existe pas de famille sémantique complète et découvrable pour créer/modifier/publier un preset, ajouter/activer un calque, peindre/remplir/effacer une matière et planifier/appliquer une migration.

Le batch générique ou la sauvegarde JSON brute ne suffisent pas à établir la parité : ils exposent une forme de stockage, pas les règles produit.

**Conséquence**

Les transports direct API, JSONL, éditeur et MCP peuvent produire des états différents ou ne pas savoir reproduire le workflow utilisateur. Les tests de parité ne voient que les actions déjà enregistrées et ne signalent donc pas les actions sémantiques absentes.

**Recommandation**

Faire de `map_authoring` la source de vérité des mutations Smart Tile, puis brancher l'éditeur, JSONL et MCP sur les mêmes actions et validations.

### P2-01 — Le Studio annoncé couvre seulement Path ERW16

La documentation de tranche actuelle exclut explicitement Terrain, forêt, Border Studio et migration destructive. Le guide ERW Corner16 supporte uniquement `SmartTileUsage.path`. Les cartes Terrain et forêt sont visibles dans l'UI mais désactivées avec une indication de guide à venir.

Sources :

- [2026-07-31-smart-tiles-guided-erw16-path.md](/Users/karim/Project/pokemonProject/docs/superpowers/plans/2026-07-31-smart-tiles-guided-erw16-path.md:1)
- [smart_tile_guide.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/smart_tiles_studio/application/smart_tile_guide.dart:85)
- [smart_tiles_studio_panel.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/smart_tiles_studio/presentation/smart_tiles_studio_panel.dart:680)

Ce n'est pas un bug caché du guide ; c'est une divergence entre l'étendue du nom « Smart Tiles Studio » et la tranche réellement livrée. Terrain ne doit pas être présenté comme disponible tant que son parcours n'est pas complet.

### P2-02 — Publication du preset et sauvegarde de la map non atomiques

Le Studio met à jour le manifest puis ajoute le calque à la map en mémoire. Les commandes de sauvegarde de la toolbar distinguent sauvegarde de map et sauvegarde de projet. Une map peut donc référencer un `presetId` dont le catalogue projet n'a pas encore été persisté.

Sources :

- [smart_tiles_studio_workspace.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/smart_tiles_studio/presentation/smart_tiles_studio_workspace.dart:34)
- [smart_tiles_studio_panel.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/smart_tiles_studio/presentation/smart_tiles_studio_panel.dart:1857)
- [top_toolbar.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/shared/top_toolbar.dart:205)

Recommandation : persister le catalogue/preset publié avant de permettre à la map d'enregistrer sa référence, ou fournir une transaction applicative avec rollback et indicateur dirty commun.

### P2-03 — Migration legacy explicite mais hors du contrat canonique

La migration existe dans [migrate_legacy_smart_tiles.dart](/Users/karim/Project/pokemonProject/packages/map_editor/tool/migrate_legacy_smart_tiles.dart:1). Elle est dry-run par défaut, applique avec copie de récupération et peut conserver des types non résolus. C'est une bonne base de sécurité.

Limites :

- CLI dédiée, non action `map_authoring` ;
- pas de découverte MCP ;
- pas de migration automatique au chargement ;
- cas terrain multi-type partiellement résolus ;
- pas de parcours utilisateur guidé avec preview des changements.

La migration doit rester explicite et réversible, mais être promue en action canonique plan/apply plutôt que réimplémentée dans chaque transport.

### P2-04 — Culling incomplet pour les visuels multipart

L'éditeur ne demande au résolveur que les cellules exactement visibles. Le runtime élargit la zone d'environ trois cellules. Or les footprints et offsets du modèle ne sont pas contractuellement bornés à trois. Un visuel ancré hors viewport mais dont une partie déborde dans le viewport peut disparaître.

Sources :

- [map_grid_painter.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:2728)
- [map_layers_component.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:148)

Ce défaut est secondaire pour la tranche Path ERW16 actuelle, mais deviendra bloquant pour forêt/terrain multipart. Le padding de résolution doit dériver des footprints/offsets maximum du catalogue ou d'un index pré-calculé.

### P2-05 — Parité MCP incomplète et rendu MCP simplifié

Le catalogue MCP vivant expose 229 actions de mutation au total, mais seulement les deux actions `smart_tile.layer.normalize/merge`. Aucun contrat Smart Tile de catalogue, publication ou migration n'est découvrable.

Le `RuntimeAuthoringMapRenderAdapter` utilisé par le transport d'authoring représente surtout les `materialCells`; il ne prouve pas un rendu asset-accurate des règles, frames, transitions et bordures.

Source : [runtime_authoring_map_render_adapter.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/authoring_preview/runtime_authoring_map_render_adapter.dart:98)

La conformance PMCP reste verte parce qu'elle vérifie la complétude du catalogue enregistré, pas l'absence de concepts métier non enregistrés.

### P2-06 — Les offsets de l'atlas peuvent être perdus à la publication

Le modèle d'atlas possède `pixelOffsetX` et `pixelOffsetY`, mais la géométrie intermédiaire issue de la détection de grille ne les transporte pas. `compileAtlas()` reconstruit ensuite l'atlas avec les valeurs par défaut. Un atlas source utilisant un offset non nul peut donc changer d'alignement après compilation/publication.

Sources :

- [smart_tile.dart](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/smart_tile.dart:343)
- [smart_tile_grid_detector.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/smart_tiles_studio/application/smart_tile_grid_detector.dart:17)
- [smart_tile_authoring_controller.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/smart_tiles_studio/application/smart_tile_authoring_controller.dart:395)

Recommandation : inclure les offsets dans le value object intermédiaire et ajouter un round-trip de publication avec offsets non nuls.

### P2-07 — Republier le même brouillon peut ajouter plusieurs calques

Le callback `onAddToActiveMap` est rappelé à chaque publication et la session reste dans un état de création. Aucun verrou idempotent ni test de double clic/republication ne démontre qu'un second calque identique n'est pas ajouté.

Source : [smart_tiles_studio_panel.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/smart_tiles_studio/presentation/smart_tiles_studio_panel.dart:1857)

Recommandation : séparer « Publier » de « Ajouter à la map », ou rendre l'opération combinée idempotente par preset/map et révision.

### P2-08 — La validation d'un preset sélectionné valide tout le catalogue

Le service de publication valide le manifest complet. Un autre brouillon structurellement invalide peut bloquer le preset actif ; les diagnostics peuvent alors désigner une ressource qui n'appartient pas au contexte actuellement ouvert.

Sources :

- [smart_tiles_studio_panel.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/smart_tiles_studio/presentation/smart_tiles_studio_panel.dart:1346)
- [smart_tile_publication_service.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/smart_tiles_studio/application/smart_tile_publication_service.dart:21)

Recommandation : valider localement le sous-graphe du preset pour l'édition, puis conserver une validation globale séparée avant sauvegarde projet.

### P2-09 — Gardes de contexte insuffisantes dans le WIP World Map

Le dialogue d'ajout du WIP revalide surtout `map.id`, pas l'identité complète du projet/document. Deux documents homonymes ou un callback devenu obsolète peuvent cibler un contexte différent. La palette choisit aussi implicitement la dernière couche du même preset lorsque plusieurs couches compatibles existent.

Sources :

- [world_map_layers_inspector.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_layers_inspector.dart:518)
- [world_map_smart_tile_paint_palette.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_smart_tile_paint_palette.dart:265)

Recommandation : capturer et revalider projet + chemin canonique + révision de map ; exiger une destination de calque explicite quand plusieurs candidats existent.

### P2-10 — Les tests verts ne prouvent pas encore les scénarios de contrat

La passe finale intégrée couvre désormais 123 tests verts sur le snapshot observé, mais elle valide aussi les nouvelles attentes WIP : terrain vide/multiple et routage Smart-only. Elle ne caractérise pas simultanément la compatibilité legacy, les trous runtime, l'empilement multi-terrain, les offsets d'atlas, la republication idempotente et le save/reload catalogue + map.

Recommandation : ajouter ces scénarios comme tests de contrat avant de considérer les tests WIP comme preuve de non-régression.

### P3-01 — Ordre de composition Smart Tile implicite

L'ordre de calques contient des règles particulières entre `PathLayer` et `TerrainLayer` legacy. Les Smart Tiles sont principalement insérés à la position demandée ou en fin de pile. Une politique de composition explicite est nécessaire avant d'autoriser plusieurs providers terrain.

Source : [map_layers.dart](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/operations/map_layers.dart:76)

### P3-02 — Vocabulaire « bordure » ambigu

Les edges/corners Smart Tile sont des transitions topologiques locales. Le Border Studio gère des features procédurales de carte. La documentation et l'UI doivent distinguer ces deux concepts pour éviter qu'un utilisateur cherche les mêmes opérations de peinture dans les deux systèmes.

### P3-03 — Libellé de publication figé

La section de publication du Studio affiche l'usage « Chemin » en dur. Cela est vrai pour la tranche actuelle, mais deviendra mensonger dès qu'un autre usage sera activé.

Source : [smart_tiles_studio_panel.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/smart_tiles_studio/presentation/smart_tiles_studio_panel.dart:1093)

### P3-04 — Choix « preset vide » implémenté mais non exposé

`SmartTileStudioSourceChoice.emptyPreset` existe dans le domaine, mais n'est pas proposé parmi les choix visibles. Cette capacité ne doit pas être comptée comme disponible tant que l'UI ne l'expose pas et ne la teste pas.

Source : [smart_tiles_studio_panel.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/smart_tiles_studio/presentation/smart_tiles_studio_panel.dart:477)

### P3-05 — Les onglets Atlas et Animations ne sont pas filtrés par preset

Les onglets présentent le catalogue global plutôt que les ressources effectivement rattachées au preset sélectionné. Cela augmente le risque d'éditer ou d'interpréter une ressource hors contexte.

Sources :

- [smart_tiles_studio_panel.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/smart_tiles_studio/presentation/smart_tiles_studio_panel.dart:1140)
- [smart_tiles_studio_panel.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/smart_tiles_studio/presentation/smart_tiles_studio_panel.dart:1416)

## 8. Ce qui fonctionne réellement

Il est important de ne pas jeter les fondations valides :

- union `MapLayer` et codecs JSON Smart Tile cohérents ;
- modèle séparant matières, arêtes et coins ;
- résolveur partagé entre éditeur et runtime ;
- rendu legacy et Smart pouvant coexister ;
- runtime capable de charger les assets référencés par les règles ;
- tests core Smart Tiles verts ;
- tests Studio isolés verts ;
- tests runtime Smart Tile ciblés verts ;
- CLI de migration prudente, dry-run et récupération ;
- actions atomiques normalize/merge déjà présentes.

Ces acquis indiquent qu'une consolidation est préférable à une réécriture complète.

## 9. Matrice de parité actuelle

| Capacité | Core direct | `map_authoring` | JSONL/CLI | Éditeur | MCP | Verdict |
|---|---|---|---|---|---|---|
| Codec `SmartTileLayer` | Oui | transitif | Oui | Oui | forme brute | PASS technique |
| Créer/modifier preset | Oui, modèles | Non canonique | partiel/outils | Studio | Non | BLOCKED |
| Publier preset | direct manifest | Non | partiel | Oui, mémoire | Non | BLOCKED |
| Ajouter calque | Oui | batch générique | générique | Oui | générique | PARTIAL |
| Activer outil | N/A | Non | Non | legacy à HEAD, Smart en WIP | Non | BLOCKED |
| Paint/fill/erase Smart | opérations disponibles | générique/partiel | générique | direct notifier | non sémantique | PARTIAL |
| Normalize/merge | Oui | Oui | Oui | partiel | Oui | PASS ciblé |
| Migration plan/apply | Oui + CLI | Non | CLI dédiée | Non guidé | Non | PARTIAL |
| Rendu éditeur | résolveur | N/A | N/A | Oui | simplifié | PARTIAL |
| Rendu runtime | résolveur partagé | N/A | playtest | Oui | adapter simplifié | PASS ciblé / PARTIAL transport |

## 10. Analyse du patch local non commité

### Changements pertinents observés

- `smart_tile_layer_operations.dart` : retrait de l'exclusivité terrain et initialisation terrain à `0` ;
- `validators.dart` : retrait des validations d'unicité/couverture terrain ;
- `map_resize.dart` : extension des Smart Terrain avec `0` ;
- `world_map_tool_activation.dart` : routage Paint vers Smart Terrain/Path ;
- `world_map_paint_inspector.dart` : intégration d'une palette Smart ;
- `world_map_smart_tile_paint_palette.dart` : nouveau fichier non suivi ;
- tests core, authoring et editor ajustés pour la nouvelle décision.

### Aspects allant dans le bon sens

- connexion explicite entre `SmartTileUsage` et l'outil World Map ;
- UI de sélection de matière au lieu d'un ID brut ;
- tests d'intégration World Map plus proches du parcours utilisateur ;
- alignement erase/normalize vers un index vide unique `0`.

### Risques bloquants avant intégration

1. les calques legacy deviennent inéligibles au lieu de rester compatibles pendant la migration ;
2. le changement dense → sparse et mono-provider → multi-provider n'est pas précédé d'une décision d'architecture ;
3. specs, validators, migration, resize et composition ne sont pas encore alignés ;
4. les mutations editor continuent de contourner `map_authoring` ;
5. le worktree change pendant les tests, donc les preuves WIP ne décrivent pas un snapshot stable ;
6. une régression UI distincte sur l'annulation du drag d'opacité reste rouge dans la suite ciblée.

Verdict du patch : **direction utile, mais non intégrable en l'état comme résolution complète**.

## 11. Validation exécutée

Toutes les commandes ci-dessous ont été exécutées fraîchement pendant l'audit.

| Commande | Résultat exact utile |
|---|---|
| `cd packages/map_core && dart test test/smart_tiles` | exit 0, `+69`, `All tests passed!` |
| `cd packages/map_authoring && dart test test/domains/maps/smart_tile_layer_actions_test.dart test/domains/maps/map_operations_batch_test.dart test/parity/full_authoring_parity_test.dart` | exit 0, `+22`, tous verts |
| `cd packages/map_runtime && flutter test test/smart_tile_runtime_render_test.dart` | exit 0, `+2`, tous verts |
| `cd packages/map_editor && flutter test test/smart_tiles_studio` | exit 0, `+44`, tous verts |
| première exécution : `cd packages/map_editor && flutter test test/smart_tiles_studio/smart_tile_map_editing_test.dart test/features/editor/application/world_map_tool_activation_test.dart test/features/editor/application/world_map_paint_layer_routing_test.dart test/features/editor/presentation/world_map/world_map_paint_inspector_test.dart test/features/editor/presentation/world_map/world_map_layers_inspector_test.dart` | exit 1, `+80`, 1 échec transitoire : `cancelled opacity drag closes before a distinct next gesture`, attendu opacité `< 1`, obtenu `1.0` |
| exécution finale : `cd packages/map_editor && flutter test test/smart_tiles_studio test/features/editor/application/world_map_tool_activation_test.dart test/features/editor/application/world_map_paint_layer_routing_test.dart test/features/editor/presentation/world_map/world_map_paint_inspector_test.dart test/features/editor/presentation/world_map/world_map_layers_inspector_test.dart` | exit 0, `+123`, `All tests passed!` |
| `cd packages/map_core && dart analyze` | exit 0, `No issues found!` |
| `cd packages/map_authoring && dart analyze` | exit 0, `No issues found!` |
| `cd packages/map_runtime && flutter analyze` | exit 0, `No issues found!` |
| `cd packages/map_editor && flutter analyze` | exit 0, `No issues found!` |
| `cd packages/map_authoring && dart run tool/pmcp085_conformance.dart` | exit 0 ; resources `62`, mutations `229`, blocked/missing `0`, N/A `51`, catalog complete `true` |
| `cd tools/pokemap_mcp && npm run check` | exit 0, TypeScript check vert |
| `cd tools/pokemap_mcp && npm test` | exit 0 ; tests `25`, pass `25`, fail `0`, durée `34359ms` ; build inclus |
| catalogue vivant `pokemap_describe` | succès ; 229 actions, uniquement 2 actions dédiées Smart Tile (`normalize`, `merge`) |

L'échec d'opacité n'est pas attribué au Smart Tile : il touchait un fichier modifié en parallèle dans le design system/inspector et n'a pas été reproduit lors de l'exécution finale stable. Il est conservé dans l'historique de preuve pour documenter la dérive du worktree, mais la suite editor ciblée finale est verte.

### Build

Le build TypeScript du serveur MCP est couvert par `npm test` et a réussi. Aucun build d'application Flutter complet n'a été lancé : l'audit ne modifie pas le produit et les analyses plus tests ciblés étaient proportionnés au risque. Il ne faut donc pas interpréter ce rapport comme une preuve de build desktop/release complet.

### Documentation Flame

Une recherche a été lancée sur la documentation Flame configurée pour le rendu par source rect/footprint ; elle n'a retourné aucun résultat. La version déclarée inspectée est Flame `^1.35.0`. L'audit du rendu s'appuie donc sur le code existant et ses tests, sans inventer d'API Flame.

## 12. Verdict des passes indépendantes

### Passe Audit / Architecture des données

Verdict : **PARTIAL**, aucun P0, deux P1 structurants. La sérialisation est saine ; le conflit vide/densité/provider et le double authoring sont les causes principales. La migration est prudente mais périphérique.

### Passe Éditeur / UX / flux utilisateur

Verdict : **BLOCKED**. `HEAD` ne permet pas d'activer le calque Smart publié dans le flux normal ; le WIP inverse le blocage vers le legacy. Terrain/forêt sont annoncés mais non guidés. Publication et sauvegarde ne sont pas atomiques.

### Passe Tests / Runtime / MCP

Verdict : **PARTIAL**. Les suites unitaires isolées, la suite editor intégrée finale et le runtime ciblé sont verts. Les tests ne prouvent pas le golden flow complet et ont été modifiés pour accepter les nouveaux invariants WIP. Le catalogue MCP ne couvre pas l'authoring Smart Tile complet et le culling multipart reste insuffisamment testé.

### Passe Implémentation

Verdict : **N/A par décision de périmètre**. Aucune implémentation n'était autorisée/demandée. Le WIP existant a seulement été audité ; il n'a pas été créé ni modifié par cette passe.

### Passe Build / Validation

Verdict : **PASS ciblé / PARTIAL global**. Analyzers des quatre packages verts, tests MCP verts, suites Smart et editor ciblées finales vertes ; pas de build Flutter complet ni de golden flow save/reload quatre transports.

### Passe Critique

Verdict : **NEEDS_CHANGES avant intégration du WIP**. L'audit répond au blocage sans recommander de réécriture. Le risque principal serait de traiter le routage UI comme le seul bug et de fusionner le WIP sans fixer d'abord le contrat terrain/vide/provider et la parité d'authoring. La critique recommande comme déblocage minimal de conserver l'invariant terrain de `HEAD` jusqu'à décision explicite, de rendre les routes legacy + Smart additives, et de traiter l'effacement Terrain comme retour au matériau par défaut plutôt que comme création implicite d'un trou.

La passe critique a signalé transitoirement que la spec `2026-07-30-smart-tiles-studio-design.md` semblait absente. Une vérification finale avec `test -f` et `rg --files` l'a bien retrouvée dans `docs/superpowers/specs/`; les références de design sont donc vérifiables dans le snapshot final.

## 13. Plan de consolidation recommandé

### Étape 0 — Stabiliser le snapshot

- geler temporairement les ajouts fonctionnels Smart Tile ;
- isoler le WIP actuel sur un snapshot révisable ;
- ne pas conclure sur les tests à partir d'un worktree en évolution.

### Étape 1 — Décision d'architecture

Écrire un ADR court couvrant :

- vide canonique (`0` recommandé) ;
- terrain dense ou sparse ;
- mono-provider ou composition multi-calques ;
- ordre de calques ;
- comportement resize/erase/merge ;
- relation explicite entre legacy, Smart Tile et Border.

Critère de sortie : specs et examples mis à jour avant changement de validators.

### Étape 2 — Source de vérité `map_authoring`

Créer des actions sémantiques canoniques :

- catalog preset create/update/validate/publish ;
- layer add/remove/activate ;
- material paint/fill/erase ;
- migration plan/apply ;
- transaction publish + persist catalog + add/activate layer.

Critère de sortie : le même payload est prouvé via API directe, JSONL, editor et MCP.

### Étape 3 — Coexistence et migration

- conserver le rendu legacy ;
- conserver temporairement l'activation legacy et Smart ;
- marquer clairement les calques legacy ;
- fournir preview, dry-run, recovery et rapport de migration ;
- ne rendre le legacy read-only qu'après chemin de migration prouvé.

### Étape 4 — Golden flow Path

Automatiser :

```text
créer Path ERW16
→ publier
→ persister catalogue
→ ajouter et activer calque
→ peindre
→ effacer
→ sauvegarder
→ recharger
→ rendu éditeur
→ rendu runtime
```

Les quatre transports doivent partager les mêmes assertions de domaine.

### Étape 5 — Terrain

Activer Terrain dans le Studio seulement après l'ADR et le golden flow Path. Tester notamment map neuve, terrain partiel/complet selon décision, resize, plusieurs calques si autorisés, sauvegarde/reload et migration.

### Étape 6 — Border et forêt/multipart

- conserver Border comme domaine séparé ;
- créer un workflow guidé/atomique de border feature ;
- renommer clairement transitions versus bordures ;
- dériver le culling des footprints/offsets réels avant d'activer forêt/multipart.

## 14. Critères de clôture proposés pour STS-CONSOLIDATION-01

Le lot ne devrait être proposé `DONE` que si :

1. un ADR tranche vide/densité/provider/ordre ;
2. aucun validator ne contredit erase, normalize, resize ou migration ;
3. un projet legacy reste éditable ou dispose d'une migration explicite prouvée ;
4. un preset Path puis Terrain peut être créé, publié, persisté, ajouté, activé et peint sans action cachée ;
5. save/reload ne peut pas laisser une map référencer un preset absent ;
6. direct API, JSONL, editor et MCP utilisent les mêmes actions `map_authoring` ;
7. le catalogue MCP découvre ces actions et ressources ;
8. éditeur et runtime rendent le même résultat logique ;
9. le golden flow automatisé est vert ;
10. la suite editor ciblée est entièrement verte sur un worktree stable ;
11. les limites Border et multipart sont explicitement couvertes ou déclarées hors lot.

## 15. Décisions et non-décisions

### Décisions recommandées

- consolider, ne pas réécrire ;
- faire de `map_authoring` l'unique frontière de mutation ;
- migrer de façon explicite et réversible ;
- garder Border distinct des transitions Smart Tile ;
- utiliser une compatibilité additive jusqu'à clôture de migration.

### Décisions volontairement laissées au lot

- terrain dense versus sparse ;
- un versus plusieurs providers terrain ;
- priorité de composition de plusieurs Smart Tile layers ;
- moment exact où le legacy devient read-only ou supprimable.

Ces décisions ont des conséquences de données et ne doivent pas être déduites d'un patch UI.

## 16. Inventaire des fichiers et zones audités

### Modèle / opérations / validation

- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/src/models/smart_tile.dart`
- `packages/map_core/lib/src/operations/smart_tile_layer_operations.dart`
- `packages/map_core/lib/src/operations/map_resize.dart`
- `packages/map_core/lib/src/operations/map_layers.dart`
- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_core/lib/src/operations/smart_tile_resolver.dart`
- `packages/map_core/lib/src/operations/legacy_smart_tile_migration.dart`

### Authoring / transports

- `packages/map_authoring/lib/src/domains/maps/layer_actions.dart`
- `packages/map_authoring/lib/src/domains/maps/region_operations.dart`
- `packages/map_authoring/lib/src/domains/maps/map_operations_batch.dart`
- `packages/map_authoring/tool/pmcp085_conformance.dart`
- `tools/pokemap_mcp/`

### Éditeur

- `packages/map_editor/lib/src/features/smart_tiles_studio/`
- `packages/map_editor/lib/src/features/editor/application/world_map_tool_activation.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/presentation/world_map/`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_grid_painter.dart`
- `packages/map_editor/lib/src/ui/top_toolbar.dart`
- `packages/map_editor/tool/migrate_legacy_smart_tiles.dart`

### Runtime

- `packages/map_runtime/lib/src/components/map_layers_component.dart`
- `packages/map_runtime/lib/src/authoring/runtime_authoring_map_render_adapter.dart`

### Documentation / historique

- `docs/superpowers/plans/2026-07-31-smart-tiles-guided-erw16-path.md`
- `docs/superpowers/plans/2026-08-02-smart-tile-mcp-operations.md`
- document de conception Smart Tiles Studio référencé par les tests/plans
- commits `c5d4baa77`, `2c341c58e`, `44f6a85ac`

## 17. Fichiers modifiés ou créés par cet audit

### Fichiers produit modifiés

Aucun.

### Fichier créé

- `reports/editor/smart_tiles_studio_data_model_audit_2026-08-02.md`

Le contenu complet du fichier créé est le présent rapport. Aucun autre fichier n'a été créé, modifié, stagé ou commité par l'audit.

### Diff/zones précises de cet audit

```text
reports/editor/smart_tiles_studio_data_model_audit_2026-08-02.md
  nouveau rapport : sections 1 à 19
```

Les diffs produit listés en section 10 sont préexistants et appartiennent au WIP externe ; ils n'ont pas été touchés.

### État Git final observé — 2026-08-02 15:17:17 +0200

Révision inchangée : `0816d2903`.

```text
 M packages/map_authoring/test/domains/maps/map_operations_batch_test.dart
 M packages/map_core/lib/src/operations/map_resize.dart
 M packages/map_core/lib/src/operations/smart_tile_layer_operations.dart
 M packages/map_core/lib/src/validation/validators.dart
 M packages/map_core/test/smart_tiles/smart_tile_layer_operations_test.dart
 M packages/map_editor/lib/src/features/editor/application/world_map_tool_activation.dart
 M packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_layers_inspector.dart
 M packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_paint_inspector.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/design_system/pokemap_guided_slider.dart
 M packages/map_editor/lib/src/ui/design_system/pokemap_panel.dart
 M packages/map_editor/test/features/editor/application/world_map_paint_layer_routing_test.dart
 M packages/map_editor/test/features/editor/application/world_map_tool_activation_test.dart
 M packages/map_editor/test/features/editor/presentation/world_map/world_map_layers_inspector_test.dart
 M packages/map_editor/test/features/editor/presentation/world_map/world_map_paint_inspector_test.dart
 M packages/map_editor/test/smart_tiles_studio/smart_tile_map_editing_test.dart
 M packages/map_editor/test/ui/design_system/pokemap_card_panel_test.dart
 M packages/map_editor/test/ui/design_system/pokemap_guided_slider_test.dart
?? packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_smart_tile_paint_palette.dart
?? reports/editor/smart_tiles_studio_data_model_audit_2026-08-02.md
?? skills/creating-pokemap-maps-from-reference/scripts/__pycache__/inventory_assets.cpython-314.pyc
```

Diff produit final préexistant/concurrent : 18 fichiers suivis, `1329 insertions`, `562 suppressions`. Le troisième fichier non suivi est le présent rapport. `git diff --check` est vert. Aucun `git add`, commit, changement de branche ou autre écriture Git n'a été effectué.

## 18. Auto-critique et risques résiduels

1. **Pas de reproduction manuelle interactive** : l'audit trace le code et les tests, mais n'a pas lancé une session desktop avec gestes souris complets.
2. **Worktree mouvant** : des fichiers ont changé en parallèle. Le rapport distingue `HEAD` et WIP, mais le WIP ne constitue pas un snapshot reproductible tant qu'il n'est pas isolé.
3. **Pas de projet utilisateur réel migré** : aucune map de production n'a été modifiée ou soumise à la CLI de migration.
4. **Pas de build Flutter release** : seules analyses et suites ciblées ont été lancées.
5. **Rendu visuel** : le partage du résolveur est vérifié par code/tests ; aucune comparaison pixel-perfect éditeur/runtime n'a été produite.
6. **Border** : son architecture a été inspectée comme système adjacent, mais pas auditée au même niveau exhaustif que SmartTileLayer.
7. **Sévérités** : P1 signifie ici blocage de l'authoring central, pas perte de données prouvée. Aucun P0 n'est affirmé.
8. **Recommandation `0` vide** : c'est une recommandation de simplification appuyée par les opérations existantes, pas une décision produit déjà adoptée.

## 19. Conclusion

Le Smart Tiles Studio a introduit un moteur de données prometteur, mais pas encore une nouvelle source de vérité complète pour l'authoring. Le legacy et le Smart vivent effectivement ensemble ; leur rendu coexiste, mais leurs règles d'activation, de mutation, de validation et de transport ne coïncident pas. Le correctif ne doit donc pas se limiter à reconnecter une palette dans l'UI.

La résolution durable est un petit lot de consolidation architecturale : trancher le contrat terrain/vide/provider, centraliser les mutations dans `map_authoring`, maintenir une coexistence additive pendant la migration, puis prouver un golden flow complet Path avant d'activer Terrain et les usages multipart. Tant que ces critères ne sont pas remplis, le statut honnête du flux utilisateur est **BLOCKED**.
