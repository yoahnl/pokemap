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
terrainPresetCategory
pathPresetCategory
terrainPreset
pathPreset
pathPatternPreset
surfacePreset
surfaceAtlas
environmentPreset
borderBlueprint
borderFeature
shadowPreset
projectedBuildingShadowPreset
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
element.set_shadow
element.set_projected_shadow
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
shadow_preset
projected_building_shadow_preset
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

État actuel : `E/P` pour les opérations de base ; `M` pour les transformations
de région et le batch atomique universel.

### 12.1 Layers

```text
layer.list
layer.get
layer.add_tile
layer.add_collision
layer.add_terrain
layer.add_path
layer.add_surface
layer.add_object
layer.add_environment
layer.add_border
layer.rename
layer.clone
layer.delete
layer.delete_all
layer.move
layer.reorder
layer.set_visibility
layer.set_opacity
layer.set_properties
layer.remove_property
layer.assign_tileset
layer.clear_content
layer.lock
layer.unlock
layer.copy_between_maps
layer.merge_plan
layer.merge_apply
layer.get_usage
layer.validate
layer.batch_apply
```

### 12.2 Primitives de cellules

Ces familles s’appliquent à `tile`, `terrain`, `path`, `surface` et
`collision` lorsque la sémantique le permet :

```text
cell.get
cell.sample
cell.paint
cell.erase
cell.replace

region.get
region.paint_pattern
region.stamp
region.fill_layer
region.fill_rect
region.fill_polygon
region.draw_line
region.draw_polyline
region.flood_fill
region.replace
region.clear
region.invert
region.copy
region.cut
region.paste
region.move
region.rotate
region.flip_horizontal
region.flip_vertical
region.crop
region.histogram
region.find_usages
region.stamp_template
```

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

## 13. Terrains, chemins, surfaces, environnements et bordures

État actuel : `E/P`, mais les workflows sont répartis entre core, use cases,
contrôleurs et état d’éditeur.

### 13.1 Terrain et chemins

```text
terrain.paint
terrain.paint_pattern
terrain.erase
terrain.erase_pattern
terrain.fill
terrain.replace

path.paint
path.paint_pattern
path.erase
path.erase_pattern
path.fill
path.assign_preset
path.set_properties
path.set_animation_mode
path.trigger_add
path.trigger_update
path.trigger_remove
path.preview
```

### 13.2 Surfaces

```text
surface.ensure_layer
surface.paint
surface.erase
surface.erase_area
surface.replace_placements
surface.clear
surface.inspect_usage
surface.generate_gameplay_zones_plan
surface.generate_gameplay_zones_apply
surface.validate
surface.render_preview
```

### 13.3 Environnements

```text
environment.attach_to_tile_layer
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
environment.generated_placement_move
environment.generated_placement_delete
environment.generated_placements_clear
environment.diagnostics
environment.render_preview
```

### 13.4 Bordures

```text
border_layer.stroke_add
border_layer.stroke_update
border_layer.stroke_delete
border_layer.region_fill
border_layer.region_clear
border_layer.feature_create
border_layer.feature_update
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
border_layer.resize_plan
border_layer.resize_apply
border_layer.resolve
border_layer.preview
border_layer.diagnostics
border_layer.publication_readiness
```

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
placed_element.rotate
placed_element.delete
placed_element.replace_for_layer
placed_element.set_collision
placed_element.set_opacity
placed_element.set_shadow_override
placed_element.clear_shadow_override
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

### 14.2 Entités

```text
entity.list
entity.get
entity.find_at
entity.create
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
entity.clear_payload
entity.set_visual
entity.clear_visual
entity.set_blocks_movement
entity.patch_properties
entity.validate
```

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
gameplay_zone.update
gameplay_zone.move
gameplay_zone.resize
gameplay_zone.clone
gameplay_zone.delete
gameplay_zone.set_encounter_payload
gameplay_zone.set_movement_payload
gameplay_zone.set_movement_effect_payload
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
world_rule.clone
world_rule.enable
world_rule.disable
world_rule.reorder
world_rule.delete_plan
world_rule.delete_apply
world_rule.simulate
world_rule.validate
```

## 16. Events, Scenes, Storylines et cinématiques

État actuel : `E/P`.

### 16.1 Map Events et Event V2

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

### 16.3 Catalogue canonique de commandes Scene

Ces 22 commandes existent déjà dans le catalogue canonique et doivent devenir
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
| `pokemap_validate` | Validations ciblées ou complètes |
| `pokemap_render` | Previews et rendus |
| `pokemap_playtest` | Sessions et scénarios de playtest |
| `pokemap_job` | Poll/events/cancel/retry si l’extension Tasks n’est pas disponible |
| `pokemap_artifact` | Métadonnées et lecture d’artefacts |
| `pokemap_history` | History/diff/undo/redo |
| `pokemap_recovery` | Inspection et reprise explicite |

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
