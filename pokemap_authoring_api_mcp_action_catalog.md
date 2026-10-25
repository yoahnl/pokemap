# PokeMap Authoring API → MCP — catalogue complet des actions cibles

Date : 2026-07-31

Statut : catalogue d’architecture et d’inventaire, sans implémentation ni
changement de roadmap

Périmètre : capacités actuelles et cible complète, avec distinction entre
fondations existantes, capacités partielles et capacités à créer

## 1. Verdict

Oui, PokeMap gagnerait fortement à disposer d’un MCP, mais le MCP ne doit pas
devenir une seconde implémentation de l’éditeur.

La cible correcte est :

```text
map_core / map_gameplay / map_battle / map_distribution
                         ↑
               PokeMap Authoring API
                ↙         ↓          ↘
          map_editor   CLI/SDK   preview/playtest
                                      ↓
                                 MCP PokeMap
```

L’Authoring API doit être la source de vérité des lectures, mutations,
validations, transactions et receipts. `map_editor` devra progressivement
l’utiliser lui aussi. Le MCP restera un adaptateur mince.

Le dépôt contient déjà beaucoup de briques :

- modèles typés riches dans `map_core` ;
- opérations pures d’authoring, particulièrement avancées pour la narration ;
- use cases cartes, layers, assets, entités et catalogues dans `map_editor` ;
- persistance revisionnée et atomique pour certains documents ;
- transactions et recovery pour certains workflows ;
- moteur de gameplay et battle réutilisable ;
- framework de playtest déterministe dans `playable_runtime_host` ;
- construction et inspection de packages dans `map_distribution`.

Le manque principal n’est donc pas « toutes les fonctions métier », mais :

- une façade d’authoring unique sans Flutter ;
- un registre global d’actions et de schémas ;
- un cycle uniforme `plan → preview → validate → apply → receipt` ;
- des transactions projet fiables pour les écritures multi-fichiers ;
- une idempotence durable ;
- un historique durable ;
- une gestion unifiée des assets ;
- une parité prouvée entre éditeur, API directe et MCP.

## 2. Ce que signifie « couvrir 100 % »

Une liste statique ne peut pas garantir éternellement 100 % d’un produit qui
évolue. La couverture complète doit donc être définie de manière vérifiable :

1. chaque type persisté ou manipulable est enregistré comme `resourceKind` ;
2. chaque action de l’éditeur possède un équivalent dans l’Authoring API ;
3. chaque effet runtime authorable possède une commande et une preuve de
   consommation runtime ;
4. chaque action publie son schéma, ses permissions, ses risques et ses
   garanties ;
5. une matrice de parité détecte automatiquement toute nouvelle capacité non
   exposée ;
6. le MCP expose le registre de capacités au lieu de prétendre connaître une
   liste figée.

Une cellule de couverture ne peut prendre que l’un des statuts suivants :

```text
SUPPORTED
NOT_APPLICABLE avec justification
BLOCKED avec raison
MISSING
```

Le terme « 100 % » devient acceptable uniquement lorsque toutes les cellules
applicables sont `SUPPORTED`.

## 3. Légende d’audit

Cette légende décrit les fondations du dépôt au 2026-07-31. Elle ne remplace
pas les statuts officiels de la roadmap et ne propose aucun lot `DONE`.

| Code | Signification |
|---|---|
| `E` | Logique existante et réutilisable trouvée dans le dépôt |
| `P` | Capacité partielle, dispersée, UI-couplée ou sans façade transactionnelle uniforme |
| `M` | Action canonique manquante ou comportement non prouvé |

Verdict des passes d’audit :

| Passe | Verdict |
|---|---|
| Cartes et éditeur | Moteur d’authoring riche, mais commandes dispersées et plusieurs mutations importantes uniquement orchestrées par l’état Flutter |
| Narration et gameplay | Contrats avancés et beaucoup de logique runtime réelle ; façades d’authoring et de playtest encore incomplètes selon les domaines |
| Architecture transversale | Persistance et recovery solides sur quelques chemins, mais aucun bus d’actions, registre d’idempotence, permission model ou transaction projet universelle |

## 4. Choix d’architecture

### Option A — Un outil MCP par petite opération

Avantage : schémas très explicites.

Inconvénients : plusieurs centaines d’outils, découverte coûteuse, évolution
difficile et risque de dupliquer la logique PokeMap dans le serveur MCP.

### Option B — Un unique outil de patch JSON

Avantage : implémentation initiale rapide.

Inconvénients : perte de sémantique, références cassables, aucune vraie
validation métier, mauvais support du dry-run et risque élevé de corruption.

### Option C — API canonique typée + façade MCP compacte

C’est l’option recommandée :

- le registre interne contient toutes les actions métier ;
- une CLI/SDK permet de les tester indépendamment de MCP ;
- le MCP expose environ douze outils génériques bien typés ;
- les opérations métier restent découvrables via `action.list` et
  `action.describe` ;
- les schémas des familles de commandes utilisent des unions discriminées ;
- l’éditeur et le MCP produisent les mêmes receipts.

## 5. Contrat commun obligatoire

### 5.1 Descripteur d’action

Chaque action du catalogue doit déclarer :

```text
id
contractVersion
resourceKinds[]
inputSchema
outputSchema
requiredCapabilities[]
requiredPermissions[]
riskLevel
confirmationPolicy
synchronous | asynchronous
supportsDryRun
supportsBatch
atomicity
idempotent
undoable
runtimeEvidenceLevel
supportedProjectVersions[]
deprecatedSince?
replacementActionId?
relatedRoadmapLots[]
```

### 5.2 Enveloppe de requête

```json
{
  "requestId": "req_opaque",
  "projectHandle": "project_opaque",
  "actionId": "map.region.fill_rect",
  "actionVersion": 1,
  "arguments": {},
  "expectedRevisions": {},
  "idempotencyKey": "caller_stable_key",
  "dryRun": true,
  "seed": 12345
}
```

Les handles et curseurs sont opaques. Un chemin physique ne sert jamais
d’identité métier.

### 5.3 Enveloppe de résultat

```json
{
  "requestId": "req_opaque",
  "status": "planned",
  "changed": true,
  "revisionsBefore": {},
  "revisionsAfter": {},
  "data": {},
  "diff": {},
  "affectedResources": [],
  "diagnostics": [],
  "artifacts": [],
  "receiptId": "receipt_opaque",
  "undo": {
    "undoable": true,
    "token": "undo_opaque",
    "expiresAt": "..."
  }
}
```

### 5.4 Invariants de mutation

Toute mutation doit :

- accepter `expectedRevision` ou `expectedRevisions` ;
- exiger une `idempotencyKey` ;
- fixer ses IDs et son seed dès la planification ;
- offrir le même pipeline en dry-run et en apply ;
- calculer l’impact sur les références avant écriture ;
- retourner un diff structuré ;
- refuser un plan devenu périmé ;
- annoncer honnêtement son atomicité ;
- produire un receipt durable ;
- fournir un undo durable ou expliquer pourquoi il est impossible.

Une opération multi-fichiers journalisée est dite « récupérable », pas
« atomique », si le stockage ne garantit pas réellement l’atomicité globale.

### 5.5 Erreurs structurées minimales

```text
invalid_request
unsupported_api_version
unsupported_action
schema_violation
validation_failed
not_found
already_exists
ambiguous_reference
broken_reference
dependency_conflict
revision_conflict
plan_stale
idempotency_conflict
permission_denied
confirmation_required
read_only_future_schema
busy
recovery_required
recovery_blocked
resource_limit
rate_limited
cancelled
timeout
external_dependency_failed
persistence_failed
internal_error
```

Chaque erreur doit également porter `fieldPath`, `resourceRef`, `retryable`,
`remediation[]`, `diagnostics[]` et `requestId` lorsque ces champs sont
applicables.

## 6. Actions transversales

État actuel global : `P/M`.

### 6.1 Découverte et capacités

```text
server.get_info
server.health
server.get_limits
capability.list
capability.get
resource_kind.list
resource_kind.describe
action.list
action.describe
action.search
schema.list
schema.get
validation_code.list
validation_code.describe
```

### 6.2 Workspace et projet

```text
workspace.list
workspace.open
workspace.inspect
workspace.close
workspace.recovery_status
workspace.recover

project.create
project.open
project.inspect
project.update
project.clone
project.reload
project.close
project.delete_plan
project.delete_apply
project.import_plan
project.import_apply
project.export
project.search
project.statistics
project.list_files
project.list_content
project.revision_get
project.diff
project.validate
project.reference_graph
```

### 6.3 Lecture générique

```text
resource.list
resource.get
resource.batch_get
resource.search
resource.summary
resource.snapshot
resource.diff
catalog.search
catalog.get_options
change.list_since
```

Toutes les lectures volumineuses doivent accepter :

- `summary | detail` ;
- sélection de champs ;
- filtres et tri déterministes ;
- pagination par curseur ;
- révision de snapshot ;
- profondeur maximale pour les graphes.

### 6.4 Mutations génériques

Ces actions existent pour chaque `resourceKind` où elles ont du sens :

```text
resource.create
resource.update
resource.patch
resource.upsert
resource.clone
resource.delete_plan
resource.delete_apply
resource.restore
resource.move
resource.reorder
resource.link
resource.unlink
resource.batch
resource.import_plan
resource.import_apply
resource.export
resource.migrate_plan
resource.migrate_apply
```

Elles complètent les actions métier de haut niveau ; elles ne les remplacent
pas. `map.draw_path` reste préférable à une série de patches de cellules.

### 6.5 Planification, transactions et drafts

```text
action.plan
action.execute
change_set.diff

draft.create
draft.get
draft.patch
draft.validate
draft.commit
draft.discard

transaction.begin
transaction.stage
transaction.preview
transaction.validate
transaction.commit
transaction.abort
transaction.status
transaction.recover

batch.validate
batch.execute
conflict.inspect
conflict.resolve
```

### 6.6 Historique, snapshots et recovery

```text
project_snapshot.create
project_snapshot.list
project_snapshot.get
project_snapshot.restore_plan
project_snapshot.restore_apply
project_snapshot.delete

history.list
history.get
revision.diff
undo.plan
undo.apply
redo.plan
redo.apply
revision.revert_plan
revision.revert_apply

recovery.inspect
recovery.plan
recovery.apply
recovery.dismiss
audit.list
audit.get
receipt.get
```

### 6.7 Jobs et artefacts

```text
job.submit
job.get
job.events
job.cancel
job.retry
job.artifacts

artifact.get
artifact.list
artifact.download
artifact.expire
```

Imports massifs, validations complètes, migrations, exports, rendus et
playtests doivent pouvoir devenir des jobs.

## 7. Types de ressources à enregistrer

Le registre doit au minimum couvrir :

```text
project
projectSettings
projectPokemonConfig
projectNewGameConfig
projectPresentationProfile
projectPresentationPreset
resourceLibraryCatalog
resourceFamily
resourceLibraryEntry
mapGroup
map
mapLayer
mapConnection
mapWarp
mapTrigger
mapGameplayZone
mapPlacedElement
mapEntity
mapEvent
tilesetFolder
tileset
tilesetElementGroup
tilesetPaletteEntry
elementCategory
element
smartTileAtlas
smartTileMaterial
smartTilePattern
smartTileAnimation
smartTileDraft
smartTilePreset
smartTileLayer
environmentPreset
borderBlueprint
borderFeature
encounterTable
encounterEntry
dialogueFolder
dialogue
script
scenario
narrativeEvent
narrativeFact
worldRule
scene
storyline
cinematic
cinematicMediaAsset
shop
badge
trainer
character
pokemonSpecies
pokemonForm
pokemonLearnset
pokemonEvolution
pokemonMedia
pokemonMove
pokemonAbility
pokemonItem
pokemonType
pokemonCatalog
gameSave
gamePackage
```

Chaque ressource applicable doit être couverte par :

```text
list
get
search
create
update
clone
references
validate
delete_plan
delete_apply
```

Les ressources organisables ajoutent `move` et `reorder`. Les ressources
importables ajoutent `import_plan`, `import_apply` et `export`.

## 8. Projet, configuration et organisation

État actuel : `E/P` pour les modèles et plusieurs CRUD ; `M` pour la façade
uniforme, les révisions projet et les transactions globales.

```text
project.settings_get
project.settings_update
project.pokemon_config_get
project.pokemon_config_update
project.new_game_config_get
project.new_game_config_update
project.presentation_get
project.presentation_update
presentation.update
presentation.preset.import_plan
presentation.preset.import_apply
presentation.preset.export
presentation.preset.delete_plan
presentation.preset.delete_apply
project.global_properties_get
project.global_properties_patch
project.global_properties_remove
project.version_upgrade_plan
project.version_upgrade_apply
project.migration_list
project.migration_plan
project.migration_apply

map_group.list_tree
map_group.create
map_group.update
map_group.rename
map_group.move
map_group.reorder
map_group.move_map
map_group.set_tags
map_group.patch_properties
map_group.delete_plan
map_group.delete_apply
```

`ProjectNewGameConfig` nécessite notamment :

```text
new_game.set_start_map
new_game.set_start_spawn
new_game.set_identity_defaults
new_game.set_avatar_options
new_game.set_starting_money
new_game.set_initial_bag
new_game.set_initial_party
new_game.set_initial_facts
new_game.starter_create
new_game.starter_update
new_game.starter_clone
new_game.starter_reorder
new_game.starter_delete
new_game.build_initial_state
new_game.preview
new_game.validate
```

## 9. Assets et fichiers de contenu

État actuel : `P`. Plusieurs imports et analyses spécialisés existent, mais
aucun gestionnaire d’assets universel.

### 9.1 Cycle générique

```text
asset.list
asset.get
asset.inspect
asset.search
asset.preview
asset.verify
asset.import_plan
asset.import_apply
asset.replace_plan
asset.replace_apply
asset.copy
asset.move
asset.rename
asset.delete_plan
asset.delete_apply
asset.deduplicate_plan
asset.deduplicate_apply
asset.find_usages
asset.find_unused
asset.relink_plan
asset.relink_apply
asset.metadata_update
asset.license_update
asset.thumbnail
```

Les données binaires passent par des handles d’artefacts avec digest, MIME,
taille et expiration ; elles ne sont pas injectées comme de gros blobs JSON.
`asset.delete` peut recevoir la liste exacte `acknowledgedUsages` pour confirmer
des usages déclaratifs périmés ; toute référence réellement dérivée du projet ou
d'une map continue de bloquer la suppression.

### 9.2 Images et atlas

```text
raster.inspect_dimensions
raster.inspect_alpha
raster.detect_grid
raster.normalize_grid
raster.crop
raster.slice
raster.transparent_color_preview
raster.transparent_color_apply
raster.optimize
raster.build_atlas
raster.validate_bounds
raster.render_preview
```

### 9.3 Vidéo, audio et fontes

```text
video.inspect
video.validate
video.transcode_plan
video.transcode_apply
video.poster_generate
video.captions_validate

audio.inspect
audio.validate
audio.preview
audio.normalize_plan
audio.normalize_apply

font.inspect
font.validate_license
font.validate_glyph_coverage
font.import_plan
font.import_apply
font.assign_role
```

### 9.4 Sécurité des assets

Toute action doit :

- rester sous les racines autorisées ;
- résoudre les symlinks avant validation ;
- interdire les traversées de chemin ;
- calculer un digest ;
- limiter taille, dimensions et complexité ;
- vérifier le type réel du fichier ;
- annoncer les références cassées par une suppression ou un déplacement.

## 10. Tilesets, palettes, éléments et presets visuels

État actuel : `E/P`, avec beaucoup de use cases existants et plusieurs façades
spécialisées à normaliser.

### 10.1 Tilesets et dossiers

```text
tileset_folder.list_tree
tileset_folder.create
tileset_folder.rename
tileset_folder.move
tileset_folder.delete
tileset_folder.assign_tileset
tileset_folder.move_tileset_to_root

tileset.list
tileset.get
tileset.import_plan
tileset.import_apply
tileset.update
tileset.clone
tileset.delete_plan
tileset.delete_apply
tileset.reorder
tileset.assign_to_map
tileset.assign_to_layer
tileset.list_assignable
tileset.replace_image_plan
tileset.replace_image_apply
tileset.set_transparent_color
tileset.regrid_plan
tileset.regrid_apply
tileset.normalize
tileset.build_atlas
tileset.validate_bounds
tileset.find_usages
tileset.tile_property_get
tileset.tile_property_set
tileset.tile_property_remove
```

### 10.2 Palette

```text
palette_entry.list
palette_entry.get
palette_entry.create
palette_entry.update
palette_entry.upsert
palette_entry.clone
palette_entry.delete
palette_entry.reorder
palette_entry.move_category
palette_entry.set_frames
palette_entry.set_animation
palette_entry.validate_source_rect
palette_entry.render_preview
```

### 10.3 Éléments réutilisables

```text
element_category.list_tree
element_category.create
element_category.rename
element_category.move
element_category.reorder
element_category.delete_plan
element_category.delete_apply

tileset_element_group.list_tree
tileset_element_group.create
tileset_element_group.rename
tileset_element_group.move
tileset_element_group.reorder
tileset_element_group.delete_plan
tileset_element_group.delete_apply

element.list
element.search
element.get
element.create
element.update
element.clone
element.move
element.reorder
element.change_owner_tileset_plan
element.change_owner_tileset_apply
element.delete_plan
element.delete_apply
element.find_usages
element.set_frames
element.set_tags
element.set_recommended_layer
element.set_collision_profile
element.set_animation
element.render_preview
element.validate
```

Une suppression d’élément doit scanner toutes les cartes et refuser l’écriture
ou proposer une réécriture explicite des `placedElements`.

### 10.4 Collisions d’élément

```text
element_collision.describe
element_collision.generate
element_collision.rebuild
element_collision.recalculate_from_padding
element_collision.use_padding_as_base
element_collision.add_cells
element_collision.remove_cells
element_collision.apply_brush_stroke
element_collision.apply_polygon
element_collision.set_primary_shape
element_collision.reset_overrides
element_collision.clear
element_collision.render_preview
element_collision.validate
```

### 10.5 Presets

Les cycles CRUD complets s’appliquent à :

```text
terrain_preset_category
path_preset_category
terrain_preset
path_preset
path_pattern_preset
surface_preset
surface_atlas
environment_preset
border_blueprint
```

Actions spécialisées :

```text
preset.import_plan
preset.import_apply
preset.export
preset.render_preview
preset.validate
preset.publish_plan
preset.publish_apply

terrain_preset.variant_add
terrain_preset.variant_update
terrain_preset.variant_remove
terrain_preset.variant_reorder
terrain_preset.weight_normalize

path_preset.variant_map
path_preset.variant_unmap
path_preset.autotile_preview
path_preset.autotile_validate

surface_catalog.inspect
surface_catalog.diagnostics
surface_catalog.replace_plan
surface_catalog.replace_apply
surface_catalog.clear_plan
surface_catalog.clear_apply

border_blueprint.primitive_add
border_blueprint.primitive_update
border_blueprint.primitive_remove
border_blueprint.asset_link
border_blueprint.asset_unlink
border_blueprint.preview
border_blueprint.diagnostics
border_blueprint.publication_readiness
```

## 11. Cartes et organisation du monde

État actuel : `E/P`. Le lifecycle principal existe ; les opérations de région,
la vue monde globale et plusieurs transactions croisées sont à créer.

### 11.1 Cycle de carte

```text
map.list
map.get
map.get_summary
map.get_region
map.create
map.save
map.rename
map.update_metadata
map.patch_properties
map.clone
map.duplicate
map.delete_plan
map.delete_apply
map.resize_plan
map.resize_apply
map.clear_plan
map.clear_apply
map.snapshot
map.compare
map.validate
map.dependencies
map.incoming_references
map.visual_stack_inspect
map.visual_stack_migrate_plan
map.visual_stack_migrate_apply
map.render
map.render_region
```

`map.update_metadata` v1 est opérationnelle : `mapId` et les champs optionnels
`name`, `role`, `isIndoor`, `allowEscapeRope`, `escapeRopeDungeonId`.
Le donjon est un identifiant de groupe existant choisi explicitement (ou `null`) ;
le rangement de la bibliothèque ne déduit aucune appartenance de gameplay.
La Corde Sortie utilise un effet typé `escape_rope`, cible `world`, contexte
`overworld`, consommation `onApplied`, authorable via `item.set_overworld_effect`.
Le titre est normalisé sur les deux documents dans une transaction récupérable.
L'identité, le chemin et les références restent inchangés. Le nom identique
dans le manifeste et la carte refuse un plan avec `map.no_change`, sans écriture.
Ce contrat ne réutilise pas `map.rename`, qui change l'identité.

### 11.2 Graphe du monde

```text
world_graph.inspect
world_graph.list_connected
world_graph.list_disconnected
world_graph.find_path
world_graph.validate_consistency
world_graph.render

connection.list
connection.get
connection.upsert
connection.delete
connection.preview_alignment
connection.create_bidirectional_plan
connection.create_bidirectional_apply
connection.update_bidirectional_plan
connection.update_bidirectional_apply
connection.delete_bidirectional_plan
connection.delete_bidirectional_apply
connection.validate

warp.list
warp.get
warp.create
warp.update
warp.delete
warp.create_reciprocal_plan
warp.create_reciprocal_apply
warp.update_pair_plan
warp.update_pair_apply
warp.delete_pair_plan
warp.delete_pair_apply
warp.validate_target
warp.validate_pairs
```

Limite actuelle à conserver honnêtement : il n’existe pas de coordonnées de
cartes persistées dans un monde global. Une future vue monde éditable exige un
nouveau modèle `worldLayout`; elle ne doit pas être simulée à partir de l’UI.

## 12. Layers et édition de cellules/régions

État actuel : `M` via l’action atomique `map.apply_operations`. Une couche de
tuiles est créée vide, sans `tilesetId`; chaque cellule référence ensuite une
entrée de sa palette canonique multi-tilesets.

### 12.1 Layers

```text
layer.add
layer.clear
layer.delete
layer.move
layer.remove
layer.rename
layer.reorder
layer.set_opacity
layer.set_visibility
```

`layer.add` accepte `layerKind`, `layerId`, `name` et `insertIndex`. Le champ
historique `tilesetId` est refusé. Les terrains, chemins et surfaces sont créés
avec `smart_tile.layer.create`, jamais avec un type de couche historique.

### 12.2 Primitives de cellules

Ces primitives de `map.apply_operations` s’appliquent aux couches `tile`,
`smart_tile` et `collision` lorsque la sémantique le permet :

```text
region.copy
region.cut
region.erase
region.fill
region.flip
region.flood_fill
region.move
region.paint
region.paste
region.replace
region.rotate
region.stamp
shape.line
shape.polygon
shape.polyline
shape.rectangle
```

Pour une couche `tile`, la valeur vide est `null` et une tuile est un objet
`tile_palette_entry_v1` (`tilesetId`, `localTileId`, transformation D4
optionnelle). Les lectures bornées utilisent `pokemap_query` sur une map en
`get/detail` avec l’extension `region`; elles répondent avec l’encodage
`tile_palette_v1`, la palette et les lignes d’indices.

Commande essentielle pour les agents :

```text
map.apply_operations
```

Elle accepte une liste compacte et atomique de primitives de région, éléments,
entités, zones et références. Elle évite des milliers d’appels MCP pour une
seule carte.

### 12.3 Autotiling

```text
autotile.resolve
autotile.preview
autotile.apply
autotile.validate
autotile.rebuild_region
```

## 13. Smart Tiles, environnements et bordures

Les terrains, chemins et surfaces organiques utilisent exclusivement le
catalogue et les couches Smart Tiles du format v6. Les actions historiques
Terrain/Path/Surface ne font plus partie du contrat découvrable.

### 13.1 Smart Tiles

```text
smart_tile.animation.delete
smart_tile.animation.upsert
smart_tile.atlas.upsert
smart_tile.cell.erase
smart_tile.cell.paint
smart_tile.cell.paint_batch
smart_tile.layer.change_preset
smart_tile.layer.create
smart_tile.layer.delete
smart_tile.layer.merge
smart_tile.layer.normalize
smart_tile.layer.reconstruct
smart_tile.layer.set_animation_activation
smart_tile.material.upsert
smart_tile.material.upsert_batch
smart_tile.pattern.delete
smart_tile.pattern.erase
smart_tile.pattern.paint
smart_tile.pattern.paint_batch
smart_tile.pattern.upsert
smart_tile.pattern.upsert_batch
smart_tile.preset.delete
smart_tile.preset.draft.delete
smart_tile.preset.draft.import
smart_tile.preset.draft.upsert
smart_tile.preset.publish
tileset.tiled.import
tileset.tiled.wang_bundle.delete
```

Les sources visuelles Smart Tile acceptent `{kind: "model3d", modelId, scale,
offsetX, offsetY, offsetZ, animationIndex, followTerrain}` dans les projets 3D.
Les offsets sont des nombres finis, par défaut zéro. X/Z sont exprimés en
unités de cellule et s’ajoutent aux offsets du part avant sa rotation par
quarts de tour ; Y reste vertical. `followTerrain` vaut `true` par défaut et
échantillonne la hauteur à l’ancre finale. Avec `false`, `offsetY` est une
hauteur absolue. L’ancre finale doit rester dans la carte, même si les bornes
visuelles du modèle dépassent. Le modèle doit exister ; échelle positive
bornée à 1000, index d’animation et rotations sont validés. Les symétries de sprite
sont refusées pour les modèles. `smart_tile.preset.publish` et les mutations
de cellules conservent le même contrat : le calque stocke l’intention peinte,
et les modèles unitaires sont dérivés à la hauteur du terrain dans Studio et
le runtime. La gomme retire ces modèles, sans objet ajouté à la scène sauvegardée.
Les identités dérivées `smt_` sont réservées et ne peuvent pas être éditées avec
les commandes ordinaires d’objets. La suppression d’un modèle utilisé par un
preset, un brouillon ou un motif est bloquée.

Le catalogue Smart Tile 9 accepte `parts[].spatialClip` sur les sources
`model3d` statiques des canaux `ground`, `understory` et `canopy`. Le rectangle normalisé porte les champs
`left`, `top`, `right`, `bottom` ; sa projection conserve la densité du modèle
et les coordonnées de texture. L'inspection doit être dépourvue d'animations
de nœuds et de matériaux, même si `animationIndex` est nul. Les symétries,
les profils de rampe et un `replacesGround` avec clip partiel sont refusés.
Le remplacement de sol reste réservé au canal `ground`. Les clips conservent
leurs faces extérieures ; des partitions adjacentes doivent attribuer les
faces verticales communes à un seul composant pour éviter les doublons.
`map3d.instance.upsert` et `map3d.instance.upsert_batch` acceptent aussi un
`instance.clip`, exprimé en cellules relativement au pivot avant rotation.
Ces instances imposent `blocksMovement: false` et `animationIndex: null` ;
le centre tourné du clip sert à vérifier l'ancrage dans la carte.
Avec `followTerrain: true`, les sources Smart Tile clippées échantillonnent
le terrain au centre du support visible ; les sources non clippées gardent
l'ancre finale comme point d'échantillonnage.
Les remplacements de source et configurations unitaires ou par lots conservent
ces gardes, y compris pour les motifs et brouillons non peints. Le paquet de
jeu exige `map3d.model-clip@1` et le pack de ressources `models.static-clip`.

`smart_tile.material.upsert_batch` v1 reçoit `{materials: [...]}` avec 1 à 250
documents natifs de matériau. Les identifiants répétés sont refusés ; chaque
document utilise le même décodage strict que `smart_tile.material.upsert`.
Le catalogue fusionné passe un seul préflight projet et produit une seule
mutation atomique du manifeste, révisionnée et annulable en un lot. Les autres
entrées du catalogue et les cartes sont conservées. Le diff porte uniquement
sur les matériaux du lot et utilise la projection Smart Tile bornée existante.
Le workflow éditeur unitaire reste inchangé.

`smart_tile.preset.draft.import` v1 reçoit `{draftId, artifactHandle}`. L’artefact
doit être un objet JSON UTF-8 de type `application/json`, limité à 8 MiB, dont
l’identité et les octets sont vérifiés avant le préflight natif. Son identifiant
doit correspondre à `draftId`. Les identifiants de tête (`draftId`, cible et
source du preset) sont limités à 128 caractères. Une identité existante
différente est refusée.
Les atlas, matériaux, animations, règles et profils restent isolés dans le draft
jusqu’à `smart_tile.preset.publish`. La limite de requête des transports reste
inchangée. La mutation du manifeste est atomique, révisionnée et annulable ; le
plan conserve les postimages nécessaires à la reprise. La lease de l’artefact
est libérée une seule fois après application ou récupération réussie, et après
un dry run. Les gros documents des diffs Smart Tile sont représentés par une
empreinte qualifiée par son domaine, leur taille et leurs compteurs ; les chaînes
du résumé sont limitées à 256 caractères Unicode et les champs tronqués sont
signalés. Les données natives restent complètes.

`smart_tile.layer.create` conserve la préimage exacte du manifeste lorsque
le preset publié est déjà lié au catalogue. Un vrai changement de catalogue
utilise la même projection de diff bornée à 64 KiB avant résumé ; les postimages
et la reprise restent complètes. Les writers du manifeste normalisent les
défauts neutres connus de tout le catalogue, y compris les ressources déjà
présentes, tout en conservant les extensions inconnues et les valeurs non neutres.

Les champs `cell`, `edge`, `corner` et `mixed` sont peignables par geste
atomique avec `smart_tile.cell.paint` et `smart_tile.cell.erase`. Un geste Wang
projette le matériau vers la cellule sémantique et toutes les arêtes et/ou tous
les coins actifs de son empreinte. Les opérations de région génériques restent
refusées sur Wang, car elles ne portent pas l'intention mono-matériau nécessaire
pour résoudre sans ambiguïté les raccords partagés.

Chaque action reçoit exactement une source de cellules : soit `cells`, soit une
`selection` géométrique native. Les sélections supportées sont `line`
(`start`/`end`), `rectangle` rempli (`start`/`end`) et `floodFill` sémantique à
quatre voisins (`seed`). Les listes `cells` explicites restent bornées à 4 096
coordonnées, tandis qu’une sélection géométrique peut couvrir toute l’étendue de
la map. Leur projection reste déterministe et conserve une seule
transaction/annulation pour tout le geste.

`smart_tile.cell.paint_batch` reçoit `{mapId, layerId, strokes}`, avec chaque
stroke au format `{materialId, cells: [{x, y}]}`. Le lot porte sur une seule
couche et accepte de 1 à 4 096 strokes, pour un total de 65 536 coordonnées
entrantes au maximum. Les cellules répétées avec le même matériau sont
dédupliquées ; une cellule revendiquée par deux matériaux différents est
refusée. Toute entrée invalide refuse le lot entier avant projection. La
projection réutilise les gestes Smart Tiles natifs, puis valide et sauvegarde
une seule map avec une transaction/annulation pour tout le lot.

`map3d.camera.configure` conserve un profil fixe par carte et accepte
`projection: perspective | orthographic`. `orthographicHeight` est la hauteur
verticale complète visible, exprimée en cases du monde, strictement positive
et bornée à 10 000. Les profils perspective existants conservent leur champ de
vision, inclinaison, orientation et distance. En orthographique, le zoom et la
transition optique règlent la hauteur visible sans déplacer la caméra ; les
vues libre et du dessus de Studio conservent leur projection de travail.
Le même profil est proposé par l'inspecteur de carte, l'API, JSONL et MCP.
Un paquet utilisant cette projection exige `map3d.camera-orthographic@1`.

`party_companion.configure` v1 reçoit `{enabled, mappings}`, chaque association
portant `{speciesId, formId, characterId}`. La ressource
`partyCompanionConfiguration` v1 est un singleton d'identifiant `project` :
ses vues summary et detail exposent `{id, resourceKind, enabled, mappings}`.
L'action demande la permission `projectWrite` et déclare les capacités
`authoring.gameData.pokemon` et `map3d.party-companion@1`. Les champs inconnus
et les associations espèce/forme répétées sont refusés. Le premier
membre conscient de l'équipe détermine le personnage qui suit le trajet validé
du joueur à une case de distance. Les espèces et formes doivent être actives
dans le catalogue du projet, et les personnages doivent disposer des quatre
directions de marche. Le compagnon ne bloque pas le joueur ; les scènes et les
changements de carte réinitialisent son trajet transitoire. L'inspecteur Studio,
l'API, JSONL et MCP utilisent ce même contrat. Sa publication exige
`map3d.party-companion@1`.

`contact_device.configure` v1 reçoit `{configuration}`, où `null` retire
l'appareil et un objet complet définit `{id, label, acquiredFactId,
emptyMessage, contacts}`. Chaque contact définit `{id, label,
registeredFactId, sceneId, unavailableSceneId}`, avec `availableFactId` et
`characterId` facultatifs. Les faits sont des booléens déclarés, distincts pour
l'acquisition et chaque enregistrement ; les scènes et personnages doivent
exister. La ressource `contactDeviceConfiguration` v1 est un singleton
d'identifiant `project` : ses vues summary et detail exposent
`{id, resourceKind, configuration}`, avec `configuration: null` en l'absence
d'appareil. L'action demande la permission `projectWrite` et déclare les
capacités `authoring.contact_device` et `project.contact-device@1`. Les champs
inconnus, identifiants de contacts répétés et faits d'enregistrement partagés
sont refusés.
L'appareil apparaît dans le menu après acquisition et ses contacts persistent
par les faits narratifs existants. Les appels exécutent les conversations
configurées, sans réseau. Studio, l'API, JSONL et MCP utilisent le même contrat,
limité aux projets 3D. Sa publication exige `project.contact-device@1`.

Ces deux mutations sont de risque `medium` et déclarent les garanties
`atomic`, `dryRun`, `idempotent`, `revisionChecked` et `undoable`. Elles
remplacent la configuration complète par le cycle canonique plan/apply ; les
ressources singleton ne constituent pas un chemin d'écriture JSON parallèle.

Les commandes de scène `playSoundEffect` et `playMusicEffect` acceptent le
booléen facultatif `waitForCompletion` ; lorsqu'il vaut `true`, leur sortie
attend la fin naturelle du média. Une erreur, un arrêt ou une annulation libère
l'attente sans annoncer une lecture achevée. Les scènes 3D utilisant ces sons
exigent `map3d.scene-audio@1` ; le lecteur et les volumes sont partagés avec les
commandes audio existantes.

Les lots de ressources et de placements 3D utilisent les contrats suivants :

```text
model3d.import_batch
map3d.instance.upsert_batch
map3d.instance.delete_batch
map3d.terrain.surface.upsert_batch
map3d.terrain.surface.delete_batch
```

`model3d.import_batch` v1 reçoit `{models: [{modelId, name, artifactHandle}]}`.
Le lot contient de 1 à 50 modèles et au maximum 64 Mio (67 108 864 octets) de
GLB vérifiés, comptés pour chaque entrée même si plusieurs références partagent
un blob. Les identités, les références opaques et tous les GLB sont vérifiés
avant publication. Les ressources, le catalogue d'assets et le manifeste sont
publiés avec leurs préimages et la récupération transactionnelle existante.
La visibilité de plusieurs fichiers ne constitue pas une transaction atomique
du projet entier.

Le diff du plan décrit seulement les modèles ajoutés, avec un effet `add` par
identité. Une entrée dépassant 8 Kio devient un `modelSummary` : identités,
propriétés, bornes et comptes de l'inspection, taille et empreinte de l'entrée
complète dans le domaine `model3d-entry.json`. Les préimages et postimages
transactionnelles restent complètes ; les modèles existants et les presets
sans rapport ne sont pas répétés dans la réponse.

`map3d.instance.upsert_batch` v1 reçoit `{mapId, instances: [instance]}`, avec
les mêmes champs de placement que `map3d.instance.upsert`. Le lot contient de
1 à 50 instances sur une seule map 3D. Les identités doivent être distinctes,
les modèles et les animations doivent exister et toutes les positions doivent
être valides. Toute entrée invalide refuse le lot entier. La map est projetée
et validée avant une seule écriture atomique et une seule annulation de lot ;
les terrains, la caméra, la navigation et les autres instances sont conservés.

`model3d.configure` accepte un `rampProfile` local au modèle :
`{x, z, width, depth, lowHeight, highHeight, direction}` ou `null`.
Les poses créent alors leur pente franchissable ; les transformations et les
suppressions d’instances mettent leurs pentes à jour dans la même écriture de
carte. Les rotations de ces escaliers sont cardinales, les hauteurs s’alignent
sur les niveaux du terrain et les lots refusent tout chevauchement final.
La reconfiguration du profil publie le manifeste et les cartes concernées avec
récupération transactionnelle et une seule annulation. Le profil reste dans
les packs de ressources ; l’export de jeu conserve seulement les rampes
calculées et refuse les escaliers dont les extrémités ne sont pas raccordées.

`model3d.configure_batch` v1 reçoit `{models: [configuration]}` pour 1 à 50
identités distinctes existantes. Chaque configuration reprend les champs de
`model3d.configure` : `modelId`, `name`, `scale`, `pivot`, `collisionBounds`,
`rampProfile` et `blocksMovementByDefault`. Une propriété omise conserve sa
valeur ; `collisionBounds: null` et `rampProfile: null` suppriment explicitement
ces profils. Une identité inconnue ou dupliquée, un champ interdit ou une
configuration invalide refuse tout le lot avant publication.

Le lot prépare un seul manifeste final et au plus un changement par carte
concernée par les rampes attachées. Il conserve les identités, les médias et
les inspections des modèles. Modifier seulement le blocage par défaut ne
change pas les overrides des instances déjà placées. Les diffs sont bornés
par modèle ; les postimages restent complètes. La publication multi-fichiers
est récupérable, vérifiée par révision, idempotente et annulable ; elle ne
prétend pas être atomique entre fichiers. Le contrat demande `projectWrite`,
sans permission d'acquisition de sources. Les appels unitaires et par lot
partagent la même validation ; aucun écran de configuration supplémentaire
n'est requis pour utiliser ce contrat d'automatisation.

`map3d.instance.delete_batch` v1 reçoit `{mapId, instanceIds: [instanceId]}`.
Le lot contient de 1 à 50 identités distinctes d'une seule map 3D. Une identité
absente, un doublon, une instance Smart Tile, une instance détenue par une aire
d'environnement ou une feature de bordure, ou une référence narrative restante
refuse le lot entier. Toutes les gardes sont évaluées avant projection ; une
seule map est validée et écrite, avec une seule annulation pour le lot.
Les placements d'environnement explicitement manuels peuvent recevoir une
transformation exacte via `map3d.instance.upsert` ou `upsert_batch` ; leur
suppression reste une opération de l'aire qui conserve ses métadonnées.

`map3d.terrain.surface.upsert_batch` v1 reçoit `{mapId, surfaces}` et
`map3d.terrain.surface.delete_batch` v1 reçoit `{mapId, surfaceIds}`. Chaque
lot contient de 1 à 128 identités distinctes, pour un maximum de 128 surfaces
sur une carte. Une surface contient `id`, une origine `x`, `z`, une `height`,
les pentes optionnelles `gradientX`, `gradientZ` et de 1 à 32 `footprints`.
Chaque empreinte convexe contient de 3 à 16 points `{x, z}` locaux à l'origine.
Les hauteurs physiques des sommets restent entre 0 et 1024 ; toutes les
empreintes doivent rester dans les limites de la carte. Un lot invalide ou
une suppression d'identité absente refuse toute écriture. Les deux actions
acceptent `reanchorInstances`, booléen optionnel valant `true` par défaut.
Lorsqu'il est vrai, les instances conservent leur décalage par rapport au
terrain, y compris lors de la suppression. Lorsqu'il est faux, toutes leurs
positions restent intactes. Studio expose le même choix dans les réglages
de surface, pour le dessin, la modification et la gomme.
Une transaction et une annulation couvrent le lot entier.
Le plan expose seulement les identités et les comptes de surfaces et
d'instances réancrées ; le détail se lit dans la ressource `map`.
Une scène possédant ces surfaces utilise `spatialScene.schemaVersion: 2`
et un composant `terrainSurfaces.schemaVersion: 1`. Une scène de grille sans
surface continue utilise la version 1. La version 1 refuse explicitement
le champ de surfaces continues pour éviter sa perte par un ancien lecteur.
L'export déclare `map3d.terrain-surfaces@1` et l'inspection de paquet exige
cette capacité dès qu'une carte contient une surface continue.

Les motifs multi-cellules sont des ressources `smartTilePattern` natives. Ils
sont créés/supprimés avec `smart_tile.pattern.upsert`/`delete` et peints ou
effacés atomiquement avec `smart_tile.pattern.paint`/`erase`.

`smart_tile.pattern.upsert_batch` reçoit `patterns`, une liste de 1 à 250
définitions réutilisables, limitée à 16 384 cellules définies au total.
Les identifiants dupliqués, les documents invalides et les références invalides
font refuser le lot entier avant écriture. Le catalogue est validé à l'échelle
du projet, puis une seule transaction et une seule annulation couvrent le lot ;
les cartes et les autres collections du manifeste sont conservées.

`smart_tile.pattern.paint_batch` reçoit `mapId`, `layerId`, `strokes` et un
`collisionLayerId` optionnel. Les 1 à 250 gestes contiennent `patternId`,
`strokeId`, `selection` (`stamp`, `line` ou `rectangle`) et les phases signées
optionnelles `phaseX`/`phaseY`. Le lot est limité à 65 536 cellules compilées,
y compris les recouvrements. Les gestes sont appliqués dans l'ordre fourni ;
des identifiants de geste dupliqués ou un geste invalide refusent tout le lot.
Les collisions explicites suivent le même ordre. Une seule écriture de carte
et une seule annulation couvrent le lot ; les autres couches et le manifeste
sont conservés.

Le paramètre optionnel `materialId` de `smart_tile.pattern.paint` et de chaque
geste de `paint_batch` lie le motif au matériau de ses cellules occupées. Les
cellules vides restent inchangées et `eraseMaterial` conserve la priorité. Sans
ce paramètre, les matériaux sont préservés. `smart_tile.pattern.erase` accepte
`clearMaterial: true` pour effacer aussi le matériau des cellules qui n'ont
plus de propriétaire de motif ; les propriétaires conservés restent intacts.
La prévisualisation expose `clearedMaterialCellCount` et une seule annulation
couvre les changements visuels et sémantiques.

`tileset.tiled.import` importe en une transaction l'image préalablement mise en
scène, son tileset atlas régulier et les Wang Sets sélectionnés vers le catalogue
Smart Tiles natif. Un clic, y compris depuis Smart Tiles Studio, produit un seul
plan et un seul reçu récupérable. Tiled n'est ni lancé ni requis au runtime ; les
usages PokeMap des Wang Sets restent des choix explicites de l'auteur.

`tileset.tiled.wang_bundle.delete` supprime atomiquement un import Wang complet :
asset, blob, tileset, atlas, matériaux, animations et presets. La suppression est
refusée tant qu'une couche de carte référence encore l'un de ses presets.

`smart_tile.layer.reconstruct` analyse une couche visuelle littérale à partir
d'un preset publié, puis propose une couche Smart Tile native masquée sans
modifier la source. L'application est à risque élevé et requiert la
confirmation liée au plan ; la couverture, les ambiguïtés et les cellules non
résolues restent visibles avant confirmation.

Les métadonnées et le rangement logique des ressources utilisent
`tileset.metadata.update` (nom et dossier, identité/source/grille conservées),
`tileset_folder.upsert`/`delete`, `element_category.upsert`/`delete`,
`element.category.assign`, `smart_tile.category.upsert`/`delete` et
`smart_tile.preset.category.assign`. Les dossiers de planches et les catégories
de décors restent hiérarchiques ; les catégories Smart Tiles restent plates.
Les suppressions de conteneurs occupés sont refusées. Le déplacement d'un
preset ne publie pas son brouillon de préparation. Ces commandes traversent
le dispatcher canonique et les transactions revisionnées communes.

Le classement transversal des ressources est indépendant de ces catégories
métier et utilise les actions canoniques suivantes :

```text
resource.family.create
resource.family.update
resource.family.delete
resource.family.apply_batch
resource.classify
resource.classify_batch
```

`resource.family.create` reçoit `{familyId, name, parentId?}` ;
`resource.family.update` reçoit les mêmes champs, avec conservation du parent
si `parentId` est absent et retour à la racine s'il vaut `null`.
`resource.family.delete` reçoit `{familyId}` et refuse les familles prédéfinies,
les familles ayant des enfants et celles contenant des ressources classées.
`resource.family.apply_batch` reçoit `{families: [{operation, familyId, name,
parentId?}]}` avec 1 à 50 identités distinctes. `operation` vaut `create` ou
`update` et conserve les préconditions des commandes unitaires. Les parents
peuvent être définis plus loin dans le lot ; les références et les cycles
sont validés sur le résultat final, avant une unique écriture atomique.
Les familles prédéfinies et les suppressions restent exclues de ce lot.
`resource.classify` reçoit `{resourceKind, resourceId, familyId?, mapId?, role?,
placementContext?}`. `role` accepte `standard` et `component` ; son omission
conserve le rôle existant.
Un champ absent conserve la valeur ; `null` retire la famille ou rétablit la
disponibilité projet. Les identités typées acceptées sont `element`, `model3d`,
`smartTilePreset`, `tileset`, `borderBlueprint`, `environmentPreset` et
`character`. Une identité, une famille ou une carte inconnue refuse le plan.

`resource.classify_batch` reçoit `{entries: [{resourceKind, resourceId,
familyId?, mapId?, role?, placementContext?}]}` avec 1 à 100 entrées et sans
doublon d'identité typée.
Chaque entrée conserve la sémantique absent/null de `resource.classify`.
Les usages directs et indirects des portées locales sont validés sur le
catalogue final par la garde partagée ; aucun état intermédiaire n'est sauvegardé.
Le lot produit une seule transaction revisionnée et un seul historique
annulable. Une entrée invalide refuse l'ensemble sans écrire. Ce raccourci
de classement en masse est exposé à l'API, au JSONL et au MCP ; l'interface
Studio conserve son classement individuel sans nouvel outil de lot.

`placementContext` accepte `interior`, `exterior`, `both` ou `null` dans les
deux actions. Son omission conserve le contexte existant ; `null` l'efface.
Dans le catalogue, un champ absent ou `null` signifie « non renseigné », sans
inférence depuis la famille, la dimension ou la carte. Une entrée portant
uniquement un contexte est conservée ; modifier sa famille, sa portée ou son
rôle préserve le contexte omis. La duplication d'un décor hérite de ces
métadonnées. Ce classement descriptif ne restreint ni la disponibilité sur une
carte ni le placement : seule la portée `mapId` conserve ce rôle.

Le catalogue persiste au `formatVersion: 2` et refuse explicitement la version
1, sans migration. Les lecteurs utilisant `ProjectManifest` — API, JSONL,
Studio, export et Player — doivent être reconstruits avec ce codec commun.
Les deux actions restent en version 1 : leur nouveau champ est optionnel et
leurs schémas découvrables décrivent les valeurs, la conservation et le clear.

Les trois lectures via `pokemap_query` sont `resourceLibraryCatalog` (id
`resource-library`, catalogue et familles effectives), `resourceFamily`
(familles prédéfinies et personnalisées, descendants) et
`resourceLibraryEntry` (id composé `resourceKind:resourceId`, classement et
portée explicites). Elles supportent `list`, `get`, `batch_get`, `search` et
`summary`. Les définitions des sept types classables restent accessibles via
leur propre `resourceKind`. Familles et classements sont des métadonnées
d'auteur ; leur rendu et leur exécution runtime sont `NOT_APPLICABLE`.

Une portée locale est contrôlée sur les usages sauvegardés directs et
indirects, dans la préparation, les mutations canoniques et l'export source
avant projection runtime. Copier ou supprimer une carte portant des ressources
locales exige leur promotion préalable ou leur suppression explicite ; aucune
promotion silencieuse ni copie physique automatique des sources n'est faite.

Le remplacement compatible d’une source utilise `tileset.source.replace`
avec un artifact figé. Les dimensions et la grille restent identiques ; les
références mutables sont réconciliées et les snapshots publiés conservés.
`tileset.remove` retire une définition inutilisée ; `removeSource` est une
option séparée, revalidée sur les usages. Aucun blob partagé n’est purgé.
`element.duplicate` crée une nouvelle définition indépendante, partageant
ses sources ; `element.delete` refuse les usages directs, indirects et de
conservation technique. Les deux suppressions et le remplacement exigent
la confirmation du plan à risque élevé. Le dispatcher, la CLI JSONL,
le transport MCP stdio et les contrôleurs Studio utilisent ces contrats.

### 13.2 Environnements

`environment.preset.upsert_batch` reçoit `{presets: [...]}` avec 1 à 50
définitions complètes et des identités distinctes. Chaque palette respecte
les mêmes validations que `environment.preset.upsert`. Un échec refuse
l'ensemble du lot ; le résultat valide produit une seule modification du
manifeste, sans modifier les cartes ni les autres presets.

```text
environment.preset.upsert
environment.preset.upsert_batch
environment.preset.delete
environment.attach_to_tile_layer
environment.attach_to_spatial_terrain
environment.detach_from_tile_layer
environment.area_list
environment.area_get
environment.area_create
environment.area_update
environment.area_delete
environment.area_set_preset
environment.area_set_seed
environment.mask_paint
environment.mask_erase
environment.mask_clear
environment.generate_plan
environment.generate_apply
environment.regenerate_plan
environment.regenerate_apply
environment.shuffle_plan
environment.shuffle_apply
environment.generated_placement_add
environment.generated_placement_adopt_batch
environment.generated_placement_move
environment.generated_placement_delete
environment.generated_placements_clear
environment.diagnostics
environment.render_preview
```

Les palettes d'environnement référencent exclusivement des éléments 2D
(`elementId`) ou des modèles 3D (`modelId`), sans mélange dans un preset.
`environment.attach_to_spatial_terrain` cible le terrain natif d'une carte v9
avec `mapId` et `layerId`. Les mêmes masques, graines, paramètres et opérations
génèrent des instances unitaires dans `spatialScene.instances`. Le masque spatial
désigne les cellules d'ancrage ; les dimensions visuelles du modèle ne nécessitent
pas de remplir toute son empreinte dans le masque. Un item 3D peut définir
`cellOffsetWorld: {x, y, z}` : l'ancre est le centre de cellule décalé en X/Z,
avec la hauteur du terrain sous cette ancre plus Y. Seule l'ancre doit rester
dans les limites de la carte ; la canopée peut les dépasser. Ce champ est interdit
sur un item 2D. L'aperçu reste lié aux entrées exactes et à la révision courante.
Chaque zone conserve ses `generatedPlacementIds` ; les ajouts et déplacements
manuels sont identifiés par `manualPlacementIds` et préservés à la régénération.
La régénération bornée et la suppression ne retirent que les instances de la
zone. `environment.generated_placement_add` exige exactement un `elementId`
ou un `modelId`, selon la dimension du preset. Les références et leur portée
locale sont contrôlées directement et par les usages transitifs sauvegardés.
L'identité automatique conserve sa cellule d'origine indépendamment du décalage
XYZ : une régénération locale, un déplacement ou une suppression visent cette
cellule canonique. Les placements manuels conservent leurs transformations libres.

`environment.generated_placement_adopt_batch` rattache de 1 à 250 placements
existants à une zone avec `mapId`, `layerId`, `areaId` et `placementIds`.
L'opération conserve leurs identités, transformations et propriétés ; elle les
enregistre comme placements manuels de la zone, sans supprimer ni recréer les
objets. Elle refuse les identités dupliquées, absentes, déjà rattachées à une
autre zone ou incompatibles avec la palette. Cette opération permet notamment
de reprendre un décor existant dans le système Environnement sans déplacer ses
éléments ni casser leurs références.

### 13.3 Bordures

```text
border.blueprint.draft.upsert
border.blueprint.publish
border.blueprint.set_deprecated
border.blueprint.delete
border_layer.stroke_add
border_layer.stroke_update
border_layer.stroke_delete
border_layer.stroke_erase
border_layer.region_fill
border_layer.region_clear
border_layer.feature_create
border_layer.feature_update
border_layer.set_foreground
border_layer.feature_move
border_layer.feature_reorder
border_layer.feature_delete
border_layer.feature_set_blueprint
border_layer.feature_set_variation
border_layer.feature_lock
border_layer.feature_unlock
border_layer.feature_set_keep_out
border_layer.relink_plan
border_layer.relink_apply
border_layer.materialize_plan
border_layer.materialize_apply
border_layer.materialize_batch_apply
border_layer.resize_plan
border_layer.resize_apply
border_layer.resolve
border_layer.preview
border_layer.diagnostics
border_layer.publication_readiness
```

Les primitives de bordure utilisent exactement un `sourceElementId` 2D ou un
`sourceModelId` 3D, sans mélange dans un blueprint. Le catalogue natif utilise
`formatVersion: 5`, les features natives `formatVersion: 4`. En 3D, les sources
restent des références vivantes aux modèles du projet ; aucune image de snapshot
ni métrique pixel n'est publiée. `anchorWorld` optionnel désigne une ancre locale
GLB ; sans valeur, le pivot du modèle est utilisé.

Le type 2D `horizontalFacade` exige le sous-format de catalogue 11. Il utilise
les rôles `lineCap` et `lineStraight` sur des tracés ouverts horizontaux à centres
de cellules ; plusieurs tracés définissent les ouvertures. Sa galerie vérifie
`longEdge`, `endpoint` et `opening`. Les tracés verticaux, obliques ou fermés,
la rotation automatique, le miroir et le côté inversé sont refusés. Les actions
`border.blueprint.draft.upsert` et `border.blueprint.publish` décrivent ce contrat
dans leur extension `horizontalFacade`. Les autres types gardent leurs propres
galeries et contrôles.

Le kit 3D initial utilise `connectedLine` avec les rôles `lineCap`, `lineStraight`
et `lineCorner`. Les mêmes traits et contours de régions, y compris leurs trous,
produisent des instances natives orientées et posées sur le relief. Les slots et
IDs d'instances sont déterministes ; chaque feature conserve seulement ses
références d'ownership dans `materialization.spatialPlacements`. Les zones à éviter,
la variation pondérée, la suppression de slots et le verrouillage par
`lockedInstanceId` sont résolus dans le même contrat.

Une définition 3D peut déclarer `straightOnly: true` dans son draft et sa révision
publiée. Ce profil exige seulement `lineCap` et `lineStraight` ; `lineCorner` reste
facultatif. Il annonce explicitement des tracés droits uniquement : toute chaîne
qui tourne et toute région non vide sont refusées avant matérialisation avec
`border.spatial.straight_only_geometry_required`, même si un coin est présent.
La restriction participe aux fingerprints de publication et d'aperçu. Elle est
interdite aux blueprints 2D et aux autres templates.

`border_layer.feature_create` accepte `lineSide: "primary" | "inverted"` dès
la création, avec `primary` par défaut et la même validation que l'édition du côté.
Les actions de création et d'édition contrôlent la restriction `straightOnly`
avant toute persistence de géométrie ; leurs plans refusent les virages atomiquement.

Le sous-format de catalogue 13 permet les séquences 3D à angles :
`definition.sequenceLength` et `primitives[].sequenceIndex` restent explicites,
avec un angle pour chaque phase et les deux virages lorsque le contour est dirigé.
Les anciens motifs droits restent représentables en 12 ; la lecture seule ne
promeut pas leur catalogue. Les contrats sont exposés dans `spatialCornerSequence`.

Une primitive 3D `lineCorner` peut définir `cornerJoinCells`, entier de 0 à 8
valant zéro par défaut. L'angle réserve ce nombre de slots droits avant et après
son ancre, sans déplacer les autres instances ni modifier la progression du motif.
Les réservations suivent les contours fermés. Une extrémité, un autre angle,
une réservation concurrente ou une personnalisation de slot dans cette zone
fait refuser la matérialisation atomiquement ; supprimer l'angle libère ses voisins.
Ce champ exige le catalogue 13, conserve les données historiques sans réservation
et est décrit par l'extension `spatialCornerJoins` des actions de brouillon/publication.

Une feature 3D peut définir `spatialOffsetWorld: {x, y, z}` pour décaler un profil
réutilisable dans les coordonnées de la carte, après rotation de ses primitives.
Le décalage absent vaut zéro ; `border_layer.feature_update` conserve une valeur
absente et l'efface avec `null`. Le champ exige le format de layer 4 et est refusé
sur une carte 2D. La génération contrôle les ancrages après décalage et conserve
les IDs de slots et leur ownership. Modifier le décalage rend l'aperçu périmé ;
la régénération explicite replace les modèles tout en préservant les poses verrouillées.

`border_layer.materialize_apply` prépare puis applique un aperçu canonique lié
aux entrées exactes, aux sources et à la révision. Une modification du pivot,
de l'échelle ou du relief produit un diagnostic de matérialisation périmée ; la
régénération explicite recalcule les ancrages et conserve les instances étrangères.
Les références de modèles sont contrôlées pour la suppression et les portées
locales transitives. Le relink natif vers un autre blueprint est refusé avec
`border.spatial.relink_unsupported` ; l'édition du kit courant puis sa régénération
est prise en charge. Le redimensionnement natif passe par les opérations spatiales,
pas par `border_layer.resize_apply` réservé aux cartes 2D.

`border_layer.materialize_batch_apply` résout de 1 à 128 couples uniques
`{layerId, featureId}` d'une même `mapId`, avec `tileWidthPx`, `tileHeightPx`
et `resolverVersion`. Le plan utilise les mêmes résolveurs 2D/3D que l'action
unitaire. Un diagnostic bloquant refuse tout le lot ; la publication conserve
une seule frontière d'historique et d'annulation. Les sources, tracés, overrides
et collisions ne sont pas remplacés par des images aplaties. Les doublons,
champs inconnus et dépassements de borne sont refusés avant écriture.

`border_layer.stroke_erase` accepte `mapId`, `layerId`, `featureId` et `points`
(1 à 4096 coordonnées entières `{x, y}` dans le lattice du tracé). Il découpe les
strokes touchés, conserve leur lineage déterministe et rematérialise les fragments
en une seule transaction 2D ou 3D. Les pièces étrangères restent inchangées ; les
overrides des slots supprimés sont retirés et les slots survivants gardent
leurs corrections. Effacer tous les fragments supprime la feature et ses pièces.
Une cellule extérieure est refusée ; une gomme sans changement renvoie
`map.no_change`. Studio partage ce contrat pour son mode local Tracer/Gommer,
avec aperçu, annulation et un seul undo au relâchement.

## 14. Éléments placés, entités, triggers et zones

État actuel : `E/P`.

### 14.1 Instances d’éléments

```text
placed_element.list
placed_element.get
placed_element.find_at
placed_element.place
placed_element.batch_place
placed_element.update
placed_element.clone
placed_element.move
placed_element.set_geometry
placed_element.rotate
placed_element.delete
placed_element.replace_for_layer
placed_element.set_collision
placed_element.set_opacity
placed_element.set_animation
placed_element.reset_animation
placed_element.behavior_add
placed_element.behavior_update
placed_element.behavior_enable
placed_element.behavior_disable
placed_element.behavior_remove
placed_element.patch_properties
placed_element.validate_footprint
placed_element.detach_from_tile_projection
```

`placed_element.set_geometry` (v1) définit atomiquement la position absolue en
pixels et la taille d’une instance authored. Paramètres obligatoires : `mapId`,
`instanceId`, `pixelX`, `pixelY`, `pixelSize`. Les coordonnées sont des entiers
stricts. `pixelSize` vaut `null` pour la taille naturelle ou un objet contenant
uniquement `width` et `height`, entiers strictement positifs, d’aire maximale
1 048 576 pixels. Omettre `pixelSize` est une erreur. Les champs inconnus, les
instances générées et les emprises hors carte sont refusés sans écriture.
La normalisation conserve un résidu positif inférieur à la tuile sur chaque axe.
L’ordre des instances est conservé ; planification, contrôle de révision et undo
suivent le contrat canonique.

### 14.2 Entités

```text
entity.list
entity.get
entity.find_at
entity.create
entity.create_batch
entity.update
entity.upsert
entity.clone
entity.move
entity.batch_move
entity.resize
entity.delete
entity.set_npc_payload
entity.set_sign_payload
entity.set_item_payload
entity.set_spawn_payload
entity.set_field_obstacle
entity.set_interactive_encounter
entity.set_healing_display
entity.clear_payload
entity.set_visual
entity.clear_visual
entity.set_blocks_movement
entity.patch_properties
entity.validate
```

`entity.set_field_obstacle` (v1) définit ou retire un obstacle typé sur un
objet existant. Les paramètres obligatoires sont `mapId`, `entityId` et
`fieldObstacle`. Le payload accepté contient uniquement `kind` (`cutTree`,
`strengthBoulder` ou `rockSmashRock`) et `resetPolicy: mapInstance` ;
`null` explicite retire ce payload, tandis qu’un
champ omis est refusé. L’objet doit être `custom`, bloquant, d’une case, sur une
carte 2D et posséder un visuel du catalogue du projet. Les champs inconnus et
les objets incompatibles sont refusés sans écriture. Position, visuel et autres
propriétés sont conservés ; planification, contrôle de révision et annulation
suivent le contrat canonique. Le payload `fieldObstacle` ne contient pas de configuration de rencontre ;
celle-ci utilise la capacité indépendante `entity.set_interactive_encounter`.
Cette capacité post-bêta ne débloque
aucune CS pour le joueur et ne change pas le périmètre bêta signé de Surf.

`entity.set_interactive_encounter` (v1) définit ou retire une rencontre sur
un objet `custom`, bloquant, d’une case, avec un visuel du projet en 2D.
Les paramètres sont `mapId`, `entityId` et `interactiveEncounter` explicitement
nullable. Le payload strict contient `trigger` (`headbutt` ou `afterRockSmash`),
`encounterTableId`, `reusePolicy` (`repeatable` ou `oncePerMapInstance`),
`conditions` (conditions de script natives) et `presentation` (source de rencontre
native, dont la table et le type doivent correspondre au déclencheur).
Coud’Boule requiert une table `headbutt`, un Pokémon non K.O. connaissant
`headbutt`, un objet sans obstacle terrain et une interaction à pied.
`afterRockSmash` requiert un obstacle `rockSmashRock` et une table `special`.
La chance provient exclusivement du champ `chancePerStep` de la table, évalué
une fois par tentative. La consommation par instance intervient quand le combat
Avelune est prêt ; annulation, refus, absence de rencontre ou échec du lancement
ne consomment pas cette rencontre. Un Éclate-Roc réussi reste appliqué si son
combat optionnel échoue. Les données de présentation sont capturées avant la
disparition du rocher. La ressource interrogeable `map` expose cette capacité
via `entities[].interactiveEncounter` et son contrat dans les extensions.
La sauvegarde des instances utilise le schéma strict 5 ; les schémas précédents
sont refusés explicitement, sans migration. Le périmètre bêta reste inchangé.

`entity.set_healing_display` (v1) définit ou retire les six variantes natives
associées à la taille de l’équipe pendant un soin. Les paramètres obligatoires
sont `mapId`, `entityId` et `healingDisplay`. Le payload contient uniquement
`variantElementIds`, une liste ordonnée de six références uniques à des éléments
du projet ; `null` explicite retire ce payload. L’objet doit être `custom`, non
bloquant, d’une case, sur une carte 2D, sans autre payload ni visuel statique.
Les variantes doivent avoir des cadres natifs valides, sans collision et de
dimensions identiques. Les commandes génériques préservent ou valident ce
contrat. Planification sans écriture, contrôle de révision et annulation suivent
le contrat canonique. La commande de scène `openHeal` peut désigner cet objet
par `displayEntityId` ; seul le soin natif accepté pilote son affichage éphémère.
Cette capacité post-bêta ne modifie pas le périmètre bêta signé.

Actions NPC explicites :

```text
npc.set_facing
npc.set_character
npc.set_trainer
npc.set_dialogue
npc.set_defeat_dialogue
npc.set_visibility_rule
npc.conditional_dialogue_add
npc.conditional_dialogue_update
npc.conditional_dialogue_remove
npc.set_movement_mode
npc.waypoint_add
npc.waypoint_move
npc.waypoint_reorder
npc.waypoint_remove
npc.waypoint_clear
npc.preview_route
```

### 14.3 Triggers

```text
trigger.list
trigger.get
trigger.find_at
trigger.create
trigger.update
trigger.move
trigger.resize
trigger.clone
trigger.delete_plan
trigger.delete_apply
trigger.patch_properties
trigger.references
trigger.validate
```

### 14.4 Zones gameplay

```text
gameplay_zone.list
gameplay_zone.get
gameplay_zone.find_at
gameplay_zone.create
gameplay_zone.smart_tile.sync
gameplay_zone.update
gameplay_zone.move
gameplay_zone.resize
gameplay_zone.clone
gameplay_zone.delete
gameplay_zone.set_encounter_payload
gameplay_zone.set_movement_payload
gameplay_zone.set_movement_effect_payload
gameplay_zone.set_field_action_payload
gameplay_zone.set_hazard_payload
gameplay_zone.set_special_payload
gameplay_zone.clear_payload
gameplay_zone.set_priority
gameplay_zone.validate
```

### 14.5 Collision effective

```text
collision_layer.paint
collision_layer.erase
collision_layer.fill
collision_layer.clear
collision_layer.invert
collision_layer.replace_region
collision_layer.generate_from_elements_plan
collision_layer.generate_from_elements_apply
collision_layer.merge_plan
collision_layer.merge_apply

collision.query_effective_at
collision.query_effective_region
collision.explain_provenance
collision.preview_player_hitbox
collision.validate_walkability
collision.validate_reachability
```

L’API doit distinguer le calque collision édité, le profil collision d’un
élément et la vérité gameplay calculée.

## 15. Dialogues, scripts et narration

État actuel : `E/P`, particulièrement avancé dans `map_core/src/authoring`.

### 15.1 Dialogues et Yarn

```text
dialogue_folder.list_tree
dialogue_folder.create
dialogue_folder.rename
dialogue_folder.move
dialogue_folder.reorder
dialogue_folder.delete_plan
dialogue_folder.delete_apply

dialogue.list
dialogue.get
dialogue.create
dialogue.import_plan
dialogue.import_apply
dialogue.update_metadata
dialogue.move
dialogue.clone
dialogue.delete_plan
dialogue.delete_apply
dialogue.source_get
dialogue.source_save
dialogue.set_default_start_node
dialogue.set_tags
dialogue.outcome_add
dialogue.outcome_update
dialogue.outcome_replace_plan
dialogue.outcome_replace_apply
dialogue.outcome_delete_plan
dialogue.outcome_delete_apply
dialogue.references
dialogue.compile
dialogue.validate
dialogue.preview
dialogue.simulate
```

Authoring Yarn structuré cible :

```text
yarn.node_create
yarn.node_update
yarn.node_clone
yarn.node_delete
yarn.line_add
yarn.line_update
yarn.line_delete
yarn.choice_add
yarn.choice_update
yarn.choice_delete
yarn.jump_set
yarn.outcome_set
yarn.command_add
yarn.command_update
yarn.command_delete
yarn.condition_set
yarn.localization_get
yarn.localization_update
```

### 15.2 Scripts legacy

```text
script.list
script.get
script.create
script.update
script.clone
script.delete_plan
script.delete_apply
script.node_add
script.node_update
script.node_move
script.node_reorder
script.node_delete
script.command_add
script.command_update
script.command_reorder
script.command_delete
script.condition_set
script.validate
script.simulate
script.migrate_to_scene_plan
script.migrate_to_scene_apply
```

Commandes legacy réellement connues :

```text
goto
end
setFlag
clearFlag
setVariable
incrementVariable
openDialogue
waitForDialogue
warpPlayer
giveItem
unlockFieldAbility
markEventConsumed
```

### 15.3 Facts et World Rules

```text
narrative_fact.list
narrative_fact.get
narrative_fact.create
fact.create_batch
narrative_fact.update
narrative_fact.clone
narrative_fact.type_change_plan
narrative_fact.type_change_apply
narrative_fact.delete_plan
narrative_fact.delete_apply
narrative_fact.find_usages
narrative_fact.validate

world_rule.list
world_rule.get
world_rule.create
world_rule.update
world_rule.upsert_batch
world_rule.clone
world_rule.enable
world_rule.disable
world_rule.reorder
world_rule.delete_plan
world_rule.delete_apply
world_rule.simulate
world_rule.validate
```

`fact.create_batch` v1 reçoit `{facts: [...]}` avec de 1 à 128 définitions
complètes. Il crée uniquement de nouveaux états narratifs, dans l’ordre reçu,
avec les mêmes identifiants canoniques, types et aliases runtime que
`fact.create`. Une collision avec un état existant, un doublon ou un membre
invalide refuse tout le lot. Le plan produit un seul draft de projet, une seule
transaction et une entrée d’historique. Les limites de requête, révisions,
autorisations et contrôles de rejeu restent ceux du transport canonique.

`entity.create_batch` v1 reçoit `{mapId, entities: [...]}` avec de 1 à 128
entités complètes sur une même carte. Chaque membre suit la normalisation et
les validations de `entity.create` ; les identifiants doivent être nouveaux et
uniques après normalisation. Un membre invalide refuse le lot avant toute
écriture. La carte candidate est validée une fois et publiée par une seule
transaction, avec une seule entrée d’historique. Aucun remplacement implicite
d’une entité existante n’est autorisé.

`world_rule.upsert_batch` crée ou met à jour atomiquement de 1 à 128 règles
complètes dans `rules`, avec des IDs uniques. Les règles existantes conservent
leur position ; les nouvelles suivent l’ordre reçu et doivent porter l’ID
canonique de leur libellé, avec suffixe de collision si nécessaire. Le batch
produit un seul draft, une validation des règles changées et une transaction.
Un membre invalide refuse l’ensemble. Les diagnostics avant/après sont
conservés sans exiger qu’un projet déjà diagnostiqué soit entièrement publiable.
Les révisions, la prévisualisation, le rejeu et l’historique utilisent les
contrats canoniques. La suppression reste unitaire. Les éventuels Facts
préalables restent des publications distinctes ; leur succès suivi d’un refus
des règles doit être signalé comme partiel par Studio.

## 16. Events, Scenes, Storylines et cinématiques

AS-UI-011 : `presentationCinematic.publish` publie un montage final et son
classement, avec les médias staged nécessaires et, lorsqu’il est demandé, le
lien vers une scène précise. L’action canonique compare les bases du montage,
du classement, des médias utilisés et de la scène avant une transaction unique.
Elle conserve les imports indépendants, refuse les sources obsolètes et ne
publie aucune carte ni autre document ouvert. Les preuves directe, JSONL et
Studio sont dans les tests `presentation_publication_ui11` et
`presentation_adapter_ui11` ; le transport MCP utilise la même action.

État actuel : `E/P`.

### 16.1 Map Events et Event V2

`event_v2.record_upsert_batch` importe atomiquement de 1 à 128 enregistrements
Event V2 complets dans `records`, avec des IDs uniques. La validation canonique,
les sources de contact et les références sont identiques à `event_v2.record_upsert`.
Les remplacements conservent leur position, les nouveaux IDs suivent l’ordre reçu.
L’action respecte expectedRevision, plan/apply et les reçus idempotents standards.
Elle expose les mêmes données Event V2 à Studio et au runtime ; aucune nouvelle
primitive UI n’est requise pour ce transport d’import en masse du convertisseur.


```text
map_event.list
map_event.get
map_event.create
map_event.update
map_event.clone
map_event.move
map_event.delete_plan
map_event.delete_apply
map_event.page_add
map_event.page_update
map_event.page_reorder
map_event.page_delete
map_event.page_set_condition
map_event.page_set_script
map_event.page_set_scene
map_event.page_set_sprite
map_event.page_enable
map_event.page_disable
map_event.validate

narrative_event.list
narrative_event.get
narrative_event.create_draft
narrative_event.configure
narrative_event.clone
narrative_event.rename
narrative_event.delete_plan
narrative_event.delete_apply
narrative_event.source_set
narrative_event.source_replace
narrative_event.source_remove
narrative_event.condition_set
narrative_event.condition_add
narrative_event.condition_remove
narrative_event.scene_set
narrative_event.reuse_policy_set
narrative_event.priority_set
narrative_event.activate
narrative_event.deactivate
narrative_event.publish
narrative_event.unpublish
narrative_event.reset_plan
narrative_event.reset_apply
narrative_event.simulate
narrative_event.validate
narrative_event.reachability
narrative_event.migrate_legacy_plan
narrative_event.migrate_legacy_apply
```

Sources Event V2 actuelles :

```text
mapEnter
triggerEnter
entityInteract
outcomeReceived
```

### 16.2 Scenes

```text
scene.list
scene.get
scene.create
scene.update
scene.clone
scene.archive
scene.restore
scene.delete_plan
scene.delete_apply
scene.node_add
scene.node_update
scene.node_clone
scene.node_delete
scene.node_set_layout
scene.edge_add
scene.edge_update
scene.edge_delete
scene.edge_set_layout
scene.start_set
scene.end_configure
scene.dialogue_configure
scene.condition_configure
scene.action_configure
scene.pause_menu_visibility.set
scene.battle_configure
scene.cinematic_configure
scene.branch_configure
scene.merge_configure
scene.outcome_add
scene.outcome_update
scene.outcome_delete
scene.validate
scene.simulate
scene.reachability
scene.preview
```

La commande `scene.upsert_batch` publie atomiquement de 1 à 128 scènes complètes
(`scenes`, identités `id` uniques). Elle conserve les validations de `scene.upsert`
(dialogues, politiques, catalogue d’attaques, références et plan Runtime), le contrôle
de révision, la prévisualisation, le mode dry-run, l’idempotence et une annulation
pour le lot entier. Les remplacements gardent leur ordre ; les nouvelles scènes
sont ajoutées dans l’ordre du lot. Une dernière scène invalide refuse tout le lot.

La commande `scene.interactive_command.set` accepte une présentation optionnelle
sur le Warp existant. `presentation` est un objet fermé dont `mode` vaut `fade`,
`illustrated`, `caveEntrance` ou `caveExit`. Les modes illustrés exigent un
`illustrationElementId` pointant vers un élément natif statique unique ; aucun
chemin de fichier libre ne fait partie du contrat. Cette présentation est limitée
aux projets et destinations 2D.

Les durées sont des millisecondes entières bornées de 0 à 10000 ; les fondus et la
révélation doivent être strictement positifs, et `transferDelayMs` doit être au
moins égal à `fadeOutMs`. Le délai part du début du fondu et précède le transfert, ou le début des bandes
pour une grotte. Le monde
et l’image se révèlent en parallèle après le maintien d’une illustration normale.
Les variantes de grotte utilisent quinze bandes et une récupération de teinte.
Les références d’illustration participent à `resource.usages` et au chargement des
atlas ; les formulaires guidés utilisent le même constructeur canonique.

### 16.3 Catalogue canonique de commandes Scene

Ces 23 commandes existent déjà dans le catalogue canonique et doivent devenir
des options découvrables de l’Authoring API :

```text
setFact
markEventConsumed
completeStoryStep
giveItem
takeItem
giveMoney
givePokemon
giveConfiguredStarter
healParty
awardBadge
unlockFieldAbility
setNpcPresence
setPauseMenuEntryVisibility
finishGame
warp
moveNpc
openShop
openHeal
openPc
dialogue
trainerBattle
staticEncounter
cinematic
```

Le registre futur devra aussi refléter les lots ouverts plutôt que d’inventer
des commandes non consommées par le runtime.

### 16.4 Storylines

```text
storyline.list
storyline.get
storyline.create
storyline.update
storyline.clone
storyline.archive
storyline.restore
storyline.delete_plan
storyline.delete_apply
storyline.chapter_add
storyline.chapter_update
storyline.chapter_clone
storyline.chapter_move
storyline.chapter_reorder
storyline.chapter_delete
storyline.step_add
storyline.step_update
storyline.step_clone
storyline.step_move
storyline.step_reorder
storyline.step_delete
storyline.scene_link_add
storyline.scene_link_update
storyline.scene_link_remove
storyline.relationship_add
storyline.relationship_update
storyline.relationship_remove
storyline.effect_add
storyline.effect_update
storyline.effect_remove
storyline.anchor_set
storyline.progression_connect
storyline.progression_disconnect
storyline.validate
storyline.reachability
storyline.completion_preview
```

### 16.5 Scenarios legacy

```text
scenario.list
scenario.get
scenario.create
scenario.update
scenario.clone
scenario.delete_plan
scenario.delete_apply
scenario.node_add
scenario.node_update
scenario.node_move
scenario.node_delete
scenario.edge_add
scenario.edge_update
scenario.edge_delete
scenario.binding_set
scenario.condition_set
scenario.validate
scenario.simulate
scenario.migrate_to_storyline_plan
scenario.migrate_to_storyline_apply
```

### 16.6 Cinématiques

```text
cinematic.list
cinematic.get
cinematic.create
cinematic.update
cinematic.clone
cinematic.archive
cinematic.restore
cinematic.bulk_update
cinematic.delete_plan
cinematic.delete_apply
cinematic.stage_set_map
cinematic.stage_set_backdrop
cinematic.actor_add
cinematic.actor_update
cinematic.actor_remove
cinematic.actor_set_appearance
cinematic.actor_set_initial_placement
cinematic.target_add
cinematic.target_update
cinematic.target_remove
cinematic.stage_point_add
cinematic.stage_point_update
cinematic.stage_point_remove
cinematic.path_create
cinematic.path_update
cinematic.path_delete
cinematic.timeline_step_add
cinematic.timeline_step_update
cinematic.timeline_step_move
cinematic.timeline_step_clone
cinematic.timeline_step_copy
cinematic.timeline_step_paste
cinematic.timeline_step_delete
cinematic.preflight
cinematic.preview
cinematic.play
cinematic.validate
```

Types de timeline connus :

```text
wait
camera
actorMove
actorFace
actorEmote
dialogueLine
sound
music
fade
shake
fx
marker
```

## 17. Base de données Pokémon et contenu gameplay

État actuel : `E/P/M` selon le catalogue. Les données Pokémon vivent encore
en partie dans des contrats côté éditeur et fichiers projet.

### 17.1 Catalogues génériques

Actions applicables aux catalogues :

```text
pokemon_catalog.list
pokemon_catalog.get
pokemon_catalog.search
pokemon_catalog.create_entry
pokemon_catalog.update_entry
pokemon_catalog.upsert_entry
pokemon_catalog.delete_entry_plan
pokemon_catalog.delete_entry_apply
pokemon_catalog.import_plan
pokemon_catalog.import_apply
pokemon_catalog.export
pokemon_catalog.sync_external_plan
pokemon_catalog.sync_external_apply
pokemon_catalog.validate
pokemon_catalog.find_usages
```

Kinds minimaux :

```text
species
moves
abilities
items
types
growth_rates
natures
egg_groups
habitats
encounter_rules
generations
version_groups
learnsets
evolutions
media
```

### 17.2 Espèces

```text
species.list
species.get
species.search
species.create
species.update
species.clone
species.delete_plan
species.delete_apply
species.import_json_plan
species.import_json_apply
species.import_external_plan
species.import_external_apply
species.batch_import_plan
species.batch_import_apply
species.form_add
species.form_update
species.form_delete
species.set_classification
species.set_metadata
species.set_types
species.set_stats
species.set_abilities
species.set_capture_data
species.set_growth_data
species.set_breeding_data
species.set_moves
species.set_learnset
species.set_evolutions
species.set_media
species.validate
species.render_preview
```

### 17.3 Moves, capacités et objets

```text
move.list
move.get
move.search
move.create
move.update
move.clone
move.delete_plan
move.delete_apply
move.set_effect
move.set_engine_support
move.validate
move.simulate

ability.list
ability.get
ability.search
ability.create
ability.update
ability.clone
ability.delete_plan
ability.delete_apply
ability.set_effect
ability.validate
ability.simulate

item.list
item.get
item.search
item.create
item.update
item.clone
item.delete_plan
item.delete_apply
item.set_overworld_effect
item.set_battle_effect
item.set_held_effect
item.set_capture_effect
item.set_tm_hm_move
item.validate
item.simulate
```

### 17.4 Trainers et personnages

`campaign.trainer.upsert_batch` applique atomiquement de 1 à 512 définitions
dans `values`, avec des IDs uniques. Les remplacements gardent leur position et
les nouveaux trainers suivent l’ordre du lot. Les références aux Balls et au
stock de combat sont validées avant toute écriture ; révision, rejeu et undo
portent sur une seule transaction. Le CRUD unitaire reste l’outil d’édition
guidée ; ce lot ne crée pas de nouvelle interface de maintenance dans Studio.

Le stock de soins adverse de L21a utilise l’action canonique
`campaign.trainer.upsert`, via `value.battleItems` : un dictionnaire d’IDs exacts
du catalogue d’objets vers des quantités entières de 1 à 99, avec 16 objets
distincts au maximum. Un dictionnaire vide supprime le stock. Le contrat
`trainerBattleItems` est découvrable dans les extensions de cette action.

Les références exigent un objet unique du catalogue du projet, consommé
`on_applied` en combat et ciblant un membre de l’équipe. Les effets pris en
charge pour ce stock sont `heal_hp` et `cure_status` des statuts majeurs. Une
mutation ou suppression du catalogue ne peut pas invalider un stock existant.
Les sélecteurs guidés d’Editor et de Studio partagent ce filtre d’éligibilité.

Chaque combat initialise son propre stock depuis la définition du trainer,
quelle que soit sa difficulté. Seule une consommation adverse appliquée dans
un tour validé retire une unité ; le scoring, un refus ou un rollback ne
dépensent rien. Les changements de Pokémon conservent le stock restant et un
nouveau combat réinitialise le stock authored. Ce stock est indépendant du sac
joueur, des récompenses, des objets tenus et des Balls ; il traverse l’export et
le rechargement du package sans persister les quantités dépensées.

```text
trainer.list
trainer.get
trainer.create
trainer.update
trainer.clone
trainer.delete_plan
trainer.delete_apply
trainer.team_add
trainer.team_update
trainer.team_clone
trainer.team_reorder
trainer.team_delete
trainer.set_moves
trainer.set_held_item
trainer.set_rewards
trainer.set_dialogues
trainer.set_rematch_policy
trainer.apply_template
trainer.assign_to_npc
trainer.validate
trainer.build_battle_setup
trainer.simulate_battle

character.list
character.get
character.create
character.update
character.clone
character.delete_plan
character.delete_apply
character.animation_add
character.animation_update
character.animation_reorder
character.animation_delete
character.frame_add
character.frame_update
character.frame_reorder
character.frame_delete
character.validate
character.render_preview
```

### 17.5 Rencontres

```text
encounter_table.list
encounter_table.get
encounter_table.create
encounter_table.update
encounter_table.clone
encounter_table.delete_plan
encounter_table.delete_apply
encounter_table.set_kind
encounter_table.set_chance
encounter_table.set_conditions
encounter_table.set_tags
encounter_entry.add
encounter_entry.update
encounter_entry.reorder
encounter_entry.delete
encounter_table.assign_to_zone
encounter_table.validate
encounter_table.simulate_distribution
encounter.static_create
encounter.gift_create
encounter.fishing_create
encounter.headbutt_create
encounter.surf_create
encounter.set_consumption_policy
encounter.set_respawn_policy
```

Les types non consommés par le runtime restent `M` ou `BLOCKED`; le MCP ne
doit pas les annoncer comme fonctionnels.

### 17.6 Shops et badges

```text
shop.list
shop.get
shop.create
shop.update
shop.clone
shop.delete_plan
shop.delete_apply
shop.entry_add
shop.entry_update
shop.entry_reorder
shop.entry_delete
shop.set_stock_policy
shop.set_conditions
shop.set_state
shop.validate
shop.simulate_transaction

badge.list
badge.get
badge.create
badge.update
badge.clone
badge.delete_plan
badge.delete_apply
badge.set_unlocks
badge.set_presentation
badge.validate
```

## 18. État joueur et opérations gameplay

État actuel : `E/P`. Ces actions servent au playtest, aux templates narratifs
et à l’inspection ; elles ne doivent jamais muter un projet authoré.

### 18.1 Party

```text
party.inspect
party.summary
party.add
party.give_pokemon
party.remove_guarded
party.swap
party.reorder
party.set_lead
party.heal
party.restore_pp
party.cure_status
party.revive
party.learn_move
party.replace_move
party.forget_move
party.evolve
party.equip_held_item
party.unequip_held_item
```

### 18.2 PC et boxes

```text
pc.inspect
pc.box_list
pc.box_get
pc.deposit
pc.withdraw
pc.swap_party_with_box
pc.move_within_box
pc.move_between_boxes
pc.place_first_available
pc.summary
pc.validate_capacity
```

### 18.3 Bag, argent et objets

```text
bag.inspect
bag.give
bag.take
bag.consume
bag.use_on_target
bag.use_medicine
bag.use_status_cure
bag.use_revive
bag.use_pp_item
bag.use_key_item
bag.use_repel
bag.use_tm_hm
bag.use_capture_item
bag.equip_held_item
bag.unequip_held_item

money.inspect
money.give
money.take
money.set_probe_only
```

### 18.4 Services

```text
service.shop_open
service.shop_inspect
service.shop_buy
service.shop_sell
service.shop_close
service.heal_open
service.heal_confirm
service.heal_apply
service.heal_close
service.pc_open
service.pc_close
```

### 18.5 Sauvegardes

```text
save.list_slots
save.get_slot
save.inspect
save.validate
save.encode
save.decode
save.migrate_plan
save.migrate_apply
save.write
save.reload
save.clone
save.delete_plan
save.delete_apply
save.export
save.import_plan
save.import_apply
save.checkpoint_create
save.checkpoint_restore
save.diff
save.rollback
```

## 19. Battle et progression

État actuel : `E/P`, avec moteur riche et quelques gaps de façade ou de
parité.

```text
battle.setup_validate
battle.setup_build_wild
battle.setup_build_trainer
battle.setup_build_static
battle.start
battle.inspect_state
battle.inspect_timeline
battle.choose_move
battle.choose_target
battle.switch
battle.use_item
battle.capture
battle.run
battle.advance
battle.resolve_turn
battle.resolve_all
battle.pause
battle.resume
battle.inject_seed
battle.inject_rng_probe_only
battle.apply_outcome_plan
battle.apply_outcome_apply
battle.complete_post_battle
battle.simulate
battle.receipt_get

progression.preview_xp
progression.apply_xp
progression.preview_level_up
progression.apply_level_up
progression.preview_move_learning
progression.accept_move_learning
progression.refuse_move_learning
progression.preview_evolution
progression.accept_evolution
progression.refuse_evolution
progression.preview_rewards
progression.apply_rewards
progression.apply_capture_destination
progression.apply_badge
progression.apply_trainer_defeated
```

Le write-back doit couvrir explicitement HP, PP, statut, held item, XP, niveau,
moves, évolution, capture party/box, argent, objets, Facts et badges.

## 20. Rendu, preview et intégration éditeur

État actuel : `P`. Les rendus existent surtout à travers Flutter ou des
surfaces spécialisées.

### 20.1 Rendu

```text
render.resource
render.map
render.map_region
render.layer
render.overlay
render.thumbnail
render.change_preview
render.before_after
render.status
render.cancel
```

Overlays minimaux :

```text
collision
gameplayZones
triggers
warps
connections
entities
placedElements
events
brokenReferences
plannedChanges
walkability
```

Chaque rendu est lié à une révision et un seed exacts.

### 20.2 Session éditeur optionnelle

Ces commandes améliorent une expérience de copilote, mais ne doivent pas
porter les règles métier :

```text
editor.context_get
editor.open_workspace
editor.open_map
editor.selection_get
editor.selection_set
editor.selection_clear
editor.focus_resource
editor.focus_region
editor.tool_select
editor.brush_set
editor.viewport_get
editor.viewport_set
editor.viewport_pan
editor.viewport_zoom
editor.viewport_fit_map
editor.preview_open
editor.preview_close
editor.dirty_state_get
editor.save
```

## 21. Playtest et simulation

État actuel : `E/P`. Le framework PokeMap Eval constitue une base directe.

### 21.1 Cycle

```text
playtest.scenario_list
playtest.start
playtest.command
playtest.inspect_state
playtest.inspect_events
playtest.inspect_logs
playtest.assert
playtest.capture
playtest.pause
playtest.resume
playtest.stop
playtest.run_scenario
playtest.receipt_get
```

Un playtest utilise :

- une révision projet figée ;
- une copie éphémère de l’état joueur ;
- un seed RNG ;
- un point de départ explicite ;
- des commandes déterministes ;
- snapshots, diffs, événements, logs et captures ;
- un receipt final ;
- aucune écriture dans le projet authoré ou les sauvegardes de production.

### 21.2 Commandes déjà présentes dans PokeMap Eval

```text
game.new
save.write
save.reload
movement.navigate
movement.crossConnection
movement.enterGameplayZone
world.interact
world.enterTrigger
world.enterWarp
world.enterEncounter
world.waitForFact
dialogue.advance
dialogue.choose
battle.chooseMove
battle.useItem
battle.capture
battle.run
battle.completePostBattle
battle.resolve
service.shop.inspect
service.shop.buy
service.heal
service.pc.withdraw
evidence.checkpoint
evidence.snapshot
probe.loadCheckpoint
probe.goto
probe.overrideFact
probe.setMoney
probe.seedBag
probe.seedParty
```

### 21.3 Commandes de playtest encore nécessaires

```text
movement.step
world.wait
world.inspect
dialogue.inspect
battle.switch
battle.chooseTarget
battle.startTrainer
battle.startStatic
battle.acceptMoveLearning
battle.refuseMoveLearning
battle.acceptEvolution
battle.refuseEvolution
service.shop.sell
service.shop.close
service.pc.deposit
service.pc.swap
service.pc.move
service.pc.summary
menu.pause.open
menu.pause.close
menu.party.open
menu.party.reorder
menu.party.setLead
menu.party.summary
menu.bag.open
menu.bag.use
menu.pokedex.open
menu.options.open
menu.save.open
save.slotSelect
evidence.screenshot
evidence.assertSceneOutcome
evidence.assertVisual
```

## 22. Validation, diagnostics et correctifs

État actuel : `E/P`. Beaucoup de validateurs existent, sans orchestrateur
universel ni contrat de quick-fix uniforme.

```text
validate.resource
validate.selection
validate.affected
validate.project
validate.schema
validate.identities
validate.references
validate.assets
validate.map_bounds
validate.layer_lengths
validate.world_graph
validate.warp_pairs
validate.collisions
validate.walkability
validate.narrative
validate.story_reachability
validate.encounters
validate.trainers
validate.pokemon_data
validate.new_game
validate.save_compatibility
validate.runtime_consumption
validate.playability
validate.localization
validate.accessibility
validate.presentation
validate.performance_budget
validate.export
validate.package
validate.security

diagnostic.list
diagnostic.get
diagnostic.explain
diagnostic.navigate
diagnostic.suppress_plan
diagnostic.suppress_apply
diagnostic.unsuppress

fix.list
fix.describe
fix.plan
fix.apply
```

Un fix reste une action planifiée explicite. Une validation ne modifie jamais
silencieusement le projet.

Rapports et preuves :

```text
readiness.capability_truth
readiness.gameplay_report
readiness.authoring_parity_report
readiness.runtime_consumer_report
readiness.golden_slice_run
readiness.regression_matrix
readiness.roadmap_dashboard
readiness.release_gate
```

## 23. Packaging, distribution et publication

État actuel : `E/P` grâce à `map_distribution`, avec des lots produit encore
ouverts pour la chaîne complète.

```text
package.plan
package.build
package.inspect
package.inventory
package.verify_content
package.verify_digest
package.verify_signature
package.sign
package.compare
package.compatibility_check
package.personalization_preflight
package.install_request_build
package.install_receipt_verify
package.release_decision
package.release_gate
package.export_artifact
```

La Golden Release Journey doit prouver que les mêmes octets passent de
l’authoring au package puis au runtime/host, sans fixture créée en contournant
l’API publique.

## 24. Permissions minimales

```text
project.read
project.write
project.destructive
asset.read
asset.write
render.run
playtest.run
playtest.control
import.run
export.run
migration.run
network.external
process.execute
secret.use
recovery.apply
```

Principes :

- lecture seule et réseau désactivé par défaut ;
- confirmation pour destruction, migration et accès externe ;
- un agent ne peut pas s’accorder lui-même une permission ;
- les chemins système, secrets et stack traces ne sortent pas par défaut ;
- les actions destructrices exposent d’abord un plan d’impact.

## 25. Surface MCP recommandée

L’API canonique contient les centaines d’actions précédentes. Le MCP peut
rester compact :

| Outil MCP | Rôle |
|---|---|
| `pokemap_describe` | Capacités, ressources, actions et schémas |
| `pokemap_workspace` | List/open/status/close/recovery |
| `pokemap_query` | Get/list/search/batch/graph |
| `pokemap_plan` | Dry-run d’une ou plusieurs actions |
| `pokemap_apply` | Commit d’un plan avec idempotence et CAS |
| `pokemap_projection` | Reprojection d’un reçu, diff paginé et chunks immuables |
| `pokemap_validate` | Validations ciblées ou complètes |
| `pokemap_render` | Previews et rendus |
| `pokemap_playtest` | Sessions et scénarios de playtest |
| `pokemap_job` | Poll/events/cancel/retry si l’extension Tasks n’est pas disponible |
| `pokemap_artifact` | Métadonnées et lecture d’artefacts |
| `pokemap_history` | History/diff/undo/redo |
| `pokemap_recovery` | Inspection et reprise explicite |

La commande JSONL `projection` et l’outil en lecture seule `pokemap_projection`
utilisent le port canonique `AuthoringResultProjectionPort`. Leur champ
`operation` accepte `receipt` avec `receiptId`, `diff` avec `diffRef`, un
`cursor` optionnel et `limit`, ou `payload` avec `payloadRef`, `offset` et
`byteLength`. Chaque opération exige `projectHandle` et refuse les champs des
autres opérations. Les plafonds existants restent 200 lignes par page et
128 Kio bruts par chunk ; les réponses de succès restent bornées à 256 Kio,
UTF-8, échappements JSON, base64 et identifiant réel de l’appel compris. Une
page peut contenir moins de lignes que la limite demandée afin de conserver
la marge de l’enveloppe. Si l’identifiant JSON-RPC consomme déjà ce budget,
MCP refuse avant toute lecture avec `resource_limit`. Le SDK réémet cet
identifiant dans le refus ; lorsque l’identifiant seul dépasse 256 Kio,
l’enveloppe d’erreur ne peut pas respecter ce plafond.

Les références opaques appartiennent à la session et au projet qui les ont
produites ; elles ne sont pas des chemins de fichiers. Les diffs et payloads
restent les copies figées du plan ou du reçu, avec `fullDiffFingerprint` et
`rawSha256` pour vérifier leur reconstruction. La lecture ne confirme pas un
plan, ne prolonge pas son TTL et n’autorise pas son application après expiration
ou conflit de révision. Un reçu historique reste lisible après une nouvelle
mutation. Après fermeture, expiration de session ou redémarrage, les anciens
handles sont refusés ; `receipt` permet de recréer des références dans une
nouvelle session à partir du reçu durable.

Les données en lecture peuvent aussi être exposées comme ressources :

```text
pokemap://project/{projectId}/summary
pokemap://project/{projectId}/manifest
pokemap://project/{projectId}/capabilities
pokemap://project/{projectId}/diagnostics
pokemap://project/{projectId}/references
pokemap://project/{projectId}/map/{mapId}
pokemap://project/{projectId}/map/{mapId}/region/{regionSpec}
pokemap://project/{projectId}/catalog/{catalogKind}
pokemap://project/{projectId}/diff/{receiptId}
pokemap://artifact/{artifactId}
```

Le MCP ne doit jamais :

- écrire directement un JSON ou un fichier projet ;
- exposer un shell arbitraire ;
- générer ses propres IDs ;
- appeler directement un controller Flutter ;
- reconstruire les règles de validation ;
- masquer un conflit de révision ;
- prétendre qu’un undo existe ;
- retourner tout le projet lorsqu’une projection ou un artefact suffit.

## 26. Alignement MCP 2026

Le design tient compte de la branche de spécification MCP `2026-07-28` :

- le protocole est conçu sans état de session implicite ;
- l’état applicatif passe par des handles explicites ;
- les outils peuvent déclarer des JSON Schemas complets ;
- les travaux longs peuvent utiliser l’extension Tasks ;
- les gros résultats peuvent être retournés comme liens de ressources ou
  artefacts.

Conséquence pour PokeMap : chaque appel reçoit explicitement
`projectHandle`, `planId`, `jobHandle`, `revision` ou `artifactId`. Il n’existe
pas de mystérieux « projet courant du MCP ».

Sources officielles consultées :

- [MCP 2026-07-28 Release Candidate](https://blog.modelcontextprotocol.io/posts/2026-07-28-release-candidate/)
- [MCP Tools — draft specification](https://modelcontextprotocol.io/specification/draft/server/tools)
- [MCP Resources — specification](https://modelcontextprotocol.io/specification/2025-11-25/server/resources)

## 27. Matrice de complétude obligatoire

Une ligne par `resourceKind`, avec les colonnes suivantes :

| Gate | Preuve attendue |
|---|---|
| Inventaire | Type, schéma et ownership identifiés |
| Lecture | Describe/list/get/search/batch |
| Mutation | Toutes les actions visibles dans l’éditeur ont un équivalent canonique |
| Fidélité | Round-trip sans perte pour chaque version supportée |
| Références | Dépendances, impact, suppression et réécriture |
| Sûreté | Dry-run, validation, CAS, permissions, confirmation |
| Durabilité | Receipt, journal et recovery |
| Replay | Retry idempotent et reprise après crash |
| Historique | Undo/redo durable ou justification de non-applicabilité |
| Visualisation | Preview/rendu lié à une révision |
| Runtime | Simulation ou playtest lorsque pertinent |
| Agent UX | Schéma découvrable, batch, pagination, field masks |
| Parité | Éditeur et MCP utilisent la même API |
| Contrat | API directe et MCP produisent le même receipt |

Tests minimaux par action de mutation :

```text
schema valide
schéma invalide
dry-run sans écriture
apply nominal
retry idempotent
conflit de révision
permission refusée
impact des références
batch atomique ou compensation documentée
undo si applicable
recovery après crash si multi-fichiers
parité API directe / MCP
```

## 28. Fondations concrètes à réutiliser

| Fondation | Emplacement |
|---|---|
| Manifest et ressources projet | `packages/map_core/lib/src/models/project_manifest.dart` |
| Carte et objets spatiaux | `packages/map_core/lib/src/models/map_data.dart` |
| Types de layers | `packages/map_core/lib/src/models/map_layer.dart` |
| Opérations pures narratives | `packages/map_core/lib/src/authoring/` |
| Validation core | `packages/map_core/lib/src/validation/` |
| Read models et capability truth | `packages/map_core/lib/src/read_models/` |
| Use cases d’édition | `packages/map_editor/lib/src/application/use_cases/` |
| Services d’édition | `packages/map_editor/lib/src/application/services/` |
| Persistance CAS des maps | `packages/map_editor/lib/src/domain/models/map_document_persistence.dart` |
| Lifecycle map récupérable | `packages/map_editor/lib/src/application/services/map_lifecycle_transaction_service.dart` |
| Transactions narratives | `packages/map_editor/lib/src/application/models/narrative_authoring_transaction.dart` |
| Gameplay pur | `packages/map_gameplay/lib/src/` |
| Battle | `packages/map_battle/lib/src/` |
| Runtime | `packages/map_runtime/lib/src/` |
| Playtest déterministe | `examples/playable_runtime_host/lib/src/evaluation/` |
| Packaging | `packages/map_distribution/lib/src/` |

## 29. Lacunes prioritaires avant le MCP

Ordre recommandé :

1. créer le registre de `resourceKinds`, actions, schémas et capacités ;
2. extraire un package Dart sans Flutter, par exemple `map_authoring` ;
3. rendre la lecture projet revisionnée et paginée ;
4. uniformiser `plan/dry-run/apply/receipt` ;
5. créer une transaction projet multi-fichiers récupérable ;
6. ajouter le ledger d’idempotence durable ;
7. migrer d’abord le lifecycle maps et `map.apply_operations` ;
8. migrer assets, tilesets, éléments et références ;
9. migrer narration, données Pokémon et gameplay authoring ;
10. extraire render/playtest/jobs derrière des ports ;
11. faire consommer l’API par `map_editor` ;
12. ajouter la CLI/SDK et les tests de contrat ;
13. générer la façade MCP et les ressources ;
14. fermer la matrice de parité avant de revendiquer 100 %.

Un premier MVP utile ne nécessite pas d’attendre toutes les lignes :

```text
pokemap_describe
pokemap_workspace
pokemap_query
pokemap_plan
pokemap_apply
pokemap_validate
pokemap_render
pokemap_history
```

Avec un premier registre couvrant :

```text
project
map
layer
region
placedElement
entity
trigger
warp
connection
gameplayZone
tileset
element
dialogue
scene
narrativeEvent
```

## 30. Roadmap et limites conservées

Ce catalogue traverse pratiquement toute la roadmap mécanique, notamment :

- `FG-010` à `FG-030` pour New Game, party, PC et sauvegarde ;
- `FG-040` à `FG-073` pour battle, progression, bag, shops et soins ;
- `FG-080` à `FG-094` pour les commandes et templates d’événements ;
- `FG-100` à `FG-108` pour les rencontres ;
- `FG-120` à `FG-129` pour les capacités terrain ;
- `FG-140` à `FG-147` pour trainers, gym et progression narrative ;
- `FG-160` à `FG-165` pour les menus runtime ;
- `FG-180` à `FG-185` pour readiness, Golden Slice et release gate.

Aucun statut de roadmap n’est modifié ou proposé `DONE` par ce document. Le
catalogue décrit une surface cible ; il n’implémente aucune mécanique et ne
constitue pas une preuve runtime fraîche.

Limites volontaires :

- aucune écriture arbitraire de fichier ;
- aucune dépendance runtime à Tiled, RMXP ou un autre éditeur ;
- aucun pilotage pixel comme API métier ;
- aucune fausse vue monde globale avant création d’un vrai contrat ;
- aucune capacité future annoncée `SUPPORTED` sans consommateur runtime et
  tests frais ;
- aucune modification des changements préexistants du worktree.

### 30.1 Gate PMCP-085 — preuves fraîches du 3 août 2026

Le catalogue est désormais matérialisé par
`AuthoringFullParityCatalog.canonical()` et inspectable avec
`dart run tool/pmcp085_conformance.dart` depuis `packages/map_authoring`.
La gate couvre explicitement les 61 `resourceKind` sémantiques de la section 7,
avec un propriétaire canonique pour chaque agrégat, afin qu’un outil générique
ne puisse pas masquer une ressource oubliée.

Preuve fraîche ciblée :

```text
resourceCount: 61
mutationActionCount: 219
blockedOrMissingCount: 0
notApplicableCount: 53
coverageScope: canonicalAuthoringCatalog
catalogComplete: true
```

`catalogComplete` qualifie uniquement le registre canonique. Il n'autorise pas
la revendication produit « 100 % » : la gate stricte reste bloquée tant que
l'inventaire PMCP-081 contient cinq chemins de mutation éditeur hors API
(lifecycle de maps, sauvegarde projet/éditeur, Event Builder et Storylines).
Le script de release exécute toutes les validations puis retourne volontairement
un code non nul tant que cette dette explicite existe.

Les 53 cellules `NOT_APPLICABLE` sont principalement les rendus de ressources
sans surface visuelle, plus les garanties de mutation projet volontairement
inapplicables à `gameSave` sandboxé et `gamePackage` dérivé. Chaque cellule
porte sa justification dans la sortie JSON. La gate de release complète reste
`tools/pokemap_mcp/scripts/pmcp085_release_gate.sh`; le présent résumé ne
remplace pas son exécution fraîche.

## 31. Conclusion

La bonne unité de construction n’est pas « le serveur MCP ». C’est le
**PokeMap Authoring API**, avec :

- un registre exhaustif et généré ;
- des commandes métier de haut niveau ;
- des opérations de région batchées ;
- des références typées ;
- des transactions revisionnées ;
- dry-run, preview, validation, diff, receipt et undo ;
- des adaptateurs de rendu, playtest et packaging ;
- une matrice de parité qui rend la promesse « 100 % » mesurable.

Une fois cette API en place, le MCP devient relativement petit et stable. Sans
elle, il ne ferait que déplacer le tâtonnement des fichiers vers un nouveau
protocole.

### CS-07 — Plongée native 2D

`gameplay_zone.set_field_action_payload` prépare un point `dive` de 1 × 1 case avec un rôle `surface` ou `underwater` et un `arrivalSpawnId` local exact (`MapEntity.id`). Un point sans lien reste enregistrable et inactif ; il bloque le playtest et l’export.

`gameplay_zone.dive.link_pair_apply` prend `mapId`, `zoneId`, `targetMapId` et `targetZoneId`. Deux points propres, non liés, de rôles opposés et sur deux cartes distinctes sont publiés ensemble après validation des deux spawns, terrains et empreintes. `gameplay_zone.dive.unlink_pair_apply` prend `mapId` et `zoneId` et retire les deux liens réciproques en conservant rôle et spawn. La garantie multi-fichier est récupérable.

Les sélecteurs rôle et spawn restent des brouillons locaux avec Undo/redo. Carte et point opposé sont des sélections UI temporaires ; seul Lier publie les liens. Lier/Délier demandent deux cartes enregistrées et rafraîchissent leurs historiques locaux. Le runtime persiste `MovementMode.dive`, revalide le ticket et les deux arrivées aux frontières asynchrones, et restaure le checkpoint source si le transfert échoue. Aucun PP n’est consommé et le périmètre bêta signé reste inchangé.


### P09 — Transfert de bibliothèques d’assets

La capacité authoring.resource_packs version 2 publie le protocole pokemap.authoring.resource_pack.v2, le canal JSONL resource_pack et l’outil MCP pokemap_resource_pack. Le schéma strict pokemap.authoring.resource_pack.transfer.input.v2, son URI et son empreinte sont découverts dans describe ; chaque verbe possède son contrat sans propriété supplémentaire. L’action canonique resource_pack.import reste version 1 ; le format ZIP est inchangé.

| Verbes de transfert | Contrat |
|---|---|
| stage, stage_license, inspect | Source autorisée vers archive ou document de licence possédé, puis inspection d’archive ; job enregistré avant I/O lourde, CPU dans le worker P04. Le document est validé UTF-8 strict en flux et borné avant publication du handle. |
| entries, selection.create, selection.patch, selection.select_filtered | Pages bornées et sélection révisionnée archive ou native ; filtre serveur par recherche, libellés, famille et descendants, contexte P02 ; choix cachés conservés. |
| prepare, preview | Préparation canonique révisionnée archive ou native. Archive : conflits preserveProject par défaut ou importCopy, aperçu borné et handle opaque. Native : métadonnées, auteur, URL et handles de licences figés avec la sélection, la révision du projet et la projection ; export par preparedExportHandle opaque. |
| start_apply | Refuse tout plan ordinaire avant écriture et applique le plan canonique `resource_pack.import`, dont le seul paramètre est preparedImportHandle ; reçu et replay durables P08. |
| start_history, start_recovery, recovery_status | Jobs undo/redo/revert et reprise explicite autorisée ; statut lisible avant snapshot complet et blocage mutateur canonique pendant pending. |
| export, read_payload | export accepte preparedExportHandle et le booléen optionnel acknowledgeOrganizationRemoval ; il construit l’archive depuis la projection native préparée puis réinspecte le pack avant artifactHandle et SHA. L’acquittement ne relance pas la projection et ne contourne pas les révisions. Téléchargement segmenté via P06, sans binaire ni chemin serveur inline. |
| get, events, cancel, release | Poll, progression honnête, annulation coopérative avant réservation, refus après, libération des références possédées. |

Les cinq kinds resourcePackJob, resourcePackInspection, resourcePackEntry, resourcePackSelection et resourcePackPreview sont temporaires, liés à la session et au projet, sans listing global. Leurs URI sont émises par le serveur sous pokemap://project/{projectHandle}/resource-pack/{resourceKind}/{handle} ; query et resources/read rejoignent le même port avant un chargement natif.

Bornes : 200 lignes par page/événements, enveloppe réelle 256 Kio échappements et base64 compris, chunks 128 Kio, patch de sélection 200 références combinées, entrée de transfert 64 Kio, corrélation JSONL de 1 à 128 octets UTF-8. Un choix de fichier local exact reste réservé à l’adaptateur de confiance ; le MCP ne s’accorde aucun accès supplémentaire. Les anciennes commandes JSONL refusent le bulk canonique avec resource_pack.job_required. Une fermeture annule avant réservation et attend la finalisation engagée ; elle conserve reçu ou recovery. L’annulation publie bounded=false, sans garantie temporelle inventée.

Preuves : test/application/resource_pack_transfer_api_test.dart, test/application/resource_pack_job_lifecycle_test.dart et test/tooling/jsonl_resource_pack_flow_test.dart dans map_authoring ; test/resource_pack_stdio.test.ts dans pokemap_mcp. Les transports API/JSONL/MCP sont qualifiés par P09 ; Studio reste PARTIAL jusqu’à P10/P11 et les volumes/natif/Player relèvent de P12. Le rattrapage de fixture MCP attend 15 outils : 14 déjà présents sur HEAD et un ajouté par P09.

P10 raccorde le parcours Studio au même port canonique : `entries.section` vaut `resources`, `families`, `authors` ou `sources`, avec pagination bornée et curseur lié à la section/au propriétaire. Les libellés abrégés déclarent leur longueur et leur complétude. Le résultat d’inspection expose l’identité, les capacités et les compteurs du pack ; les auteurs et sources se lisent par pages. Le bilan de préparation décrit la fermeture de la sélection courante, motifs compris, et non l’union historique de l’installation : créations/copies/réutilisations exclusives, présence réelle, suppressions/modifications locales observées sur les définitions principales, octets sources/licences/fichiers/métadonnées distincts et racine représentative des dépendances. Un no-op n’écrit pas et ne recrée pas une suppression locale. Les conflits lisibles et le choix explicite copie restent canoniques. Studio réconcilie le reçu réel, y compris ses pages, et bloque fermeture/changement de projet pendant finalisation ou reçu non réconcilié. La libération d’une preview invalide ses curseurs sans libérer la sélection. Les limites P09 restent inchangées ; ces extensions sont exercées en API, JSONL et MCP, puis qualifiées séparément en Studio.

P11 remplace l’export à sélection et texte libre par prepare natif puis export de la préparation immuable. L’auteur contient au maximum 128 caractères ; les 200 handles de licences au maximum sont dédupliqués avant acquisition des pins. Archives et documents ont des propriétaires distincts. Les pins de job sont acquis avant son lancement puis relâchés à son règlement ; la préparation détient ses sources sans seconde copie des médias. Une sélection périmée est refusée avant création du job export ; la révision courante du projet est vérifiée dans le job avant et après construction, avec refus resource_pack.revision_changed et aucun payload publié en cas d’écart. Le catalogue d’installation version 2 conserve les origines, associations et documents natifs nécessaires au réexport après fermeture et retrait de l’archive. L’ancien catalogue version 1 est refusé explicitement. Les sections natives families/authors/sources annoncent scope=nativeInventory et la révision de sélection capturée ; leurs attributions déclarées viennent des installations persistées et ne constituent pas les seuls crédits de la sélection. La preview paginée annonce scope=preparedNativeClosure et conserve la fermeture réellement projetée, IDs natifs atteints, promotions privé→commun, neutralisations, relations origine/ressource/fichier/document et notices des versions publiées. Les comparaisons des drafts enregistrés ignorent le workflow et comparent les définitions Border ou la compilation terrain et ses supports atteints par ID ; une compilation impossible est annoncée notComparable. Les refus de publication absente et de source publiée modifiée restent stricts. prepare natif permet cet aperçu sans acquittement ; seul export acquitte les adaptations de sa préparation exacte. Préparation, preview et curseurs partagent une durée de vie, nettoyée au release, au rejet du résultat et à la fermeture. Ces contrats restent en qualification P11 ; le parcours Studio, les notices des drafts mémoire et l’écriture native atomique exigent leurs preuves séparées.


P11 conserve aussi les crédits globaux ajoutés par l’exporteur officiel. Une origine est globale lorsque sa liste de ressources est vide et qu’aucun binding média du catalogue complet ne référence son identité. L’import conserve ces origines et leurs documents pour la fermeture courante, sans attribuer les médias au publisher. Le réexport reprend les globales d’une installation seulement lorsqu’une ressource, un support avec son propriétaire ou un fichier de cette installation est atteint ; une installation voisine reste exclue. Les racines composées seulement de motifs et les crédits sans document suivent la même règle. Le bilan licenseBytes est l’union des documents réellement requis dans cette fermeture, chemins dédupliqués, incluant les licences des origines média ; il ne mesure pas l’union historique de l’installation.

Le raccord Studio P4 réutilise la route et le contrôleur de transfert avec direction import/export explicite. La sélection d’export est globale et indépendante de la carte active. Métadonnées, licences et sélection invalident la préparation et son acquittement lorsqu’elles changent ; les notices de drafts mémoire sont limitées aux IDs atteints, y compris hors de la première page, et revérifiées avant export sans sauvegarde automatique. Préparation native et aperçu partagent un owner, tandis que les réponses tardives et les curseurs périmés sont libérés ou ignorés. Le sink est injectable : aucun export n’est annoncé terminé avant un résultat published, et une fermeture attend encore l’écriture après la fin du job canonique. Le sink de production macOS est raccordé au palier P5 ; ses tests headless et sa compilation restent distincts de la preuve AppSandbox sur un dossier réellement choisi. Les tests P4 avec sink injecté ne prouvent pas cette permission.

Le sink Studio macOS acquiert une portée dossier ponctuelle via le sélecteur natif, distincte de la création de projet. Un token opaque lie le nom validé et l’identité de destination observée par le natif ; un remplacement exige sa confirmation native. Les chunks binaires séquentiels sont bornés à 128 Kio et chaque append est attendu. seal relit le FD, vérifie SHA brut et longueur, synchronise et ferme le temporaire frère ; la dernière barrière d’annulation Dart précède finish, qui revérifie les identités et renomme dans le même dossier. Une nouvelle destination utilise uniquement le renommage exclusif si le volume le supporte. Le remplacement confirmé ne prétend pas fournir de compare-and-swap face à tous les écrivains externes, ni de durabilité certifiée après crash. published est enregistré immédiatement après rename et reste publié avec avertissement si le nettoyage échoue. Si la réponse finish se perd, une relecture du statut réconcilie le résultat ; un statut indisponible ou non terminal conserve le token et bloque fermeture/changement de projet. La relecture ne reconstruit pas le pack et ne relance pas de rename. Après une interruption non publiée, un échec de release conserve également un propriétaire de nettoyage avec le token et l’issue terminale déjà connue. Sa reprise appelle uniquement le release idempotent ; une réponse de release perdue ne réinterroge pas le statut d’un token déjà supprimé. Le propriétaire est retiré après confirmation du nettoyage. Ce cas reste distinct de finish inconnu, qui exige toujours sa relecture de statut. Les sessions native et leurs permissions sont ponctuelles, sans bookmark ou entitlement élargi. Ce sink et ses tokens restent une frontière native Studio ; les transports canoniques API/JSONL/MCP utilisent toujours leurs propres handles de préparation, artifact et read_payload. La qualification native P11 vérifie séparément le bundle signé, les entitlements embarqués, la création dans un dossier choisi hors conteneur, le remplacement confirmé, les deux annulations et la réimportation après redémarrage. Les courses de fermeture et pertes de réponse restent couvertes par les tests de propriétaires et barrières, sans faute native forcée.

La réédition conserve les identités locales des règles, candidats et fallback Terrain tout en remappant les références de projet. Le guide cardinal16/path20 est restauré uniquement par reconnaissance structurelle exacte sur la grille source ; les brouillons avancés restent refusés par l’atelier guidé. Une publication Border inscrit ses PNG certifiés, le catalogue d’assets et les blobs CAS dans le même changement journalisé que le projet, avec réutilisation des contenus identiques et refus des contradictions. La réédition Border2D sans remplacement de source conserve variantes, ordre, identités, poids, ancres et transformations ; les métriques des sources recompilées aux ancres d’origine doivent encore correspondre. Aucun nouveau verbe de transport n’est ajouté.

### Musique temporaire de scène

La commande typée `sceneMusic` est publiée par les contrats de
`scene.interactive_command.set`, `scene.graph.patch` et `scene.upsert` ;
`scene.upsert_batch` conserve le même contrat de scène.

- `play` accepte exactement `operation`, `mediaAssetId` et `volume` : le média
  doit être une musique connue unique, le volume un nombre fini de 0 à 1. La
  lecture boucle explicitement, indépendamment de `loopByDefault`.
- `restore` accepte uniquement `operation` et reprend l’ambiance capturée avant
  la première modification (`play` ou `fadeOut`) de cette transaction. Une nouvelle
  modification après restauration capture une nouvelle ambiance ; aucune pile de
  clips n’est conservée.
- `fadeOut` accepte exactement `operation` et `durationMs`, entier de 0 à 60000.
  Le fondu est programmé sans bloquer le dialogue ou les déplacements suivants.

Le JSON inclut aussi `kind: sceneMusic` pour les trois opérations. Les ports
restent `completed` et `blocked` ; la musique est transitoire, limitée à la
transaction d’une scène du monde 2D. Elle n’est ni une Fact ni un champ de
sauvegarde. Pré-session et 3D sont refusées. La musique de combat garde la
priorité. Le lecteur de présentation autonome conserve sa priorité audio.
La fin, l’échec, l’abandon et la destruction de la transaction restaurent
l’ambiance et invalident les callbacks des propriétaires précédents.

Studio et les formulaires d’événements/scènes proposent des sélecteurs d’opération
et de musique, sans saisie d’identifiant. Les champs incompatibles avec
l’opération choisie sont retirés avant validation. Les refus de référence, de
paramètres ou de dimension sont vérifiés avant écriture par les actions natives,
y compris via JSONL et le MCP.

### Facts initiaux selon l’avatar choisi

`campaign.new_game.update` accepte le champ facultatif
`initialFactValuesByAvatarCharacterId`. Ses clés doivent désigner les avatars
proposés par le projet ; chaque ligne associe des Facts déclarés à des valeurs de
leur type exact. La création de partie applique les valeurs générales, puis la
ligne de l’avatar effectivement choisi, puis la valeur dérivée
`existingPartyFactId`. Cette dernière ne peut pas être définie dans une ligne
avatar. Une table vide est omise de la sérialisation.

Ces valeurs sont initialisées une seule fois. Un changement de tenue ou un
rechargement de sauvegarde ne les recalcule pas. Le formulaire de démarrage
propose des sélecteurs d’avatar et de Fact avec édition typée. Le remplacement
d’un personnage conserve les lignes compatibles et refuse les valeurs
contradictoires avant écriture. Le solveur conserve les valeurs d’une même ligne
ensemble, sous son budget habituel, sans créer de combinaisons entre avatars.
