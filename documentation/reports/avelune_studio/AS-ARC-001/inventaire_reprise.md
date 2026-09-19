# Inventaire de reprise

## Lecture de la matrice

Les décisions portent sur la reprise dans Avelune Studio, pas sur une suppression immédiate de l’existant. **Reprendre** vise le métier et ses contrats ; **adapter** signale une évolution nécessaire ; **réécrire la présentation** conserve les moteurs ; **différer** conserve explicitement la capacité dans la cible finale M4.

Niveaux : **exécuté** = résultat frais dans le README ; **lu** = assertions examinées, sans résultat d’exécution ; **trouvé** = fichier localisé seulement ; **non vérifié** = parcours non qualifié. Les responsables ci-dessous sont des packages/contrats, jamais des personnes inventées.

## Packages réellement présents

| Package | Responsabilité et preuve actuelle | Décision |
|---|---|---|
| `map_core` | Modèles, JSON et opérations pures ; `pubspec.yaml:1-25`, `lib/src/models/map_data.dart:26-60`, `lib/src/operations/map_visual_composition.dart:165-263`. | Reprendre les types métier et faire évoluer seulement le contrat partagé nécessaire. |
| `map_authoring` | Ports, orchestration, I/O local, transactions, export ; `pubspec.yaml:13-23`, façades [A1](#a1). Pure Dart, mais pas domaine pur exempt de filesystem. | Reprendre via façades, adapter frontières manquantes. |
| `map_gameplay` | Décisions d’exploration, collisions et interactions ; `pubspec.yaml:1-22`, `lib/src/gameplay_world_state.dart:842-876,1101-1157`. | Reprendre ; préserver priorité gameplay indépendamment de l’ordre visuel. |
| `map_battle` | Moteur de combat pur dépendant de `map_core`, `pubspec.yaml:1-22`. Son indépendance complète vis-à-vis de `map_core` n’est pas réelle. | Reprendre ; règles de combat non auditées dans ce lot. |
| `map_runtime` | Flutter/Flame, chargeurs, rendu et sessions Player ; `pubspec.yaml:17-42`, [R1](#r1). | Reprendre le moteur et adapter sa consommation du contrat d’ordre. |
| `map_editor` | Application Flutter/Riverpod et orchestration globale ; `pubspec.yaml:11-44`, [E1](#e1). | Réécrire la présentation, extraire/adopter seulement les responsabilités utiles. |
| `map_distribution` | Contrats de package, construction, inspection et politiques ; `lib/map_distribution.dart:3-27`. | Reprendre, audit détaillé à l’intégration export. |

Les chemins `pubspec.yaml` de ce tableau sont relatifs à `packages/<package>/`. Les fichiers métier indiqués dans chaque ligne ont le même préfixe.

## Matrice de capacités

| Capacité | Entrée actuelle | Package et API publique / responsable | Données persistées | Couplages | Preuves disponibles | Décision proposée | Jalon |
|---|---|---|---|---|---|---|---|
| Sessions projet / ouverture | `EditorNotifier.activateProject` [E1](#e1) | `AuthoringReadServicePort.openProject`, composition locale [A1](#a1) | `ProjectManifest`, `project.json`, références de cartes [A2](#a2) | Session editor mélange vue et document ; autorisation de chemin/I/O en périphérie | Code approfondi ; concurrency tests lus [T1](#t1) | Reprendre ouverture ; adapter autorité de session | M1 |
| Cartes / activation | `activateMap`, `LoadMapUseCase.executeDocument` [E1](#e1) | Lecture canonique `queryProject` ; contrat d’activation chaude à adapter [A2](#a2) | `MapData`, révision de ressource | Snapshot projet versus chargement ciblé ; dirty Save/Discard/Cancel | Code approfondi ; tests activation trouvés [T2](#t2) | Adapter documents chauds et état de vue | M1 |
| Sauvegarde / conflits | `saveActiveMap`, `SaveMapUseCase.executeRevisioned` [E2](#e2) | `AuthoringMutationServicePort.planMutation/applyMutation` [A3](#a3) | Carte entière sérialisée, journal et reçus | Flush/cible/révision ; multi-fichiers récupérables, pas atomicité totale | Code approfondi ; tests histoire exécutés ; persistance editor trouvée | Reprendre garanties, adapter passage document→commit | M1 |
| Peinture / régions | `beginMapStroke/endMapStroke` [E3](#e3) | Action `map.apply_operations`, opérations de `map_core` [A4](#a4) | Cellules tiles/collisions/Smart Tiles | `layerId` ; types non adressables par cellule refusés | Batch tests lus ; buffers examinés | Reprendre opérations, réécrire présentation | M1 limité ; M2 complet |
| Sélection / déplacement | Hit-stack, clic cyclique, preview puis commit [E4](#e4) | Primitives core et actions de décor ; hit-test actuel interne editor | Position uniquement au commit ; sélection non persistée comme contenu | Emprises/cellules, ordre de rendu, Riverpod/Flutter côté vue | Tests hit-test lus, déplacement trouvés | Adapter sélection hétérogène ; réécrire présentation | M1 |
| Décors préparés | Palette tileset/éléments et outils carte [E5](#e5) | Actions `PlacedElementActions` derrière façade [A5](#a5) | `MapPlacedElement`, référence catalogue, position, rotation, `layerId` | Ancrage 2D, target layer, gameplay et rendu | 52 tests core exécutés au total ; handlers lus | Reprendre mutations ; adapter placement sans calque visible | M1 |
| Devant/derrière / pile | Commandes de calques, pas commande générique d’ordre d’objet [E4](#e4) | `MapVisualStackConfig`, `buildMapVisualCompositionPlan` [R1](#r1) | `visualStack` versionné et ordre des calques ; pas rang indépendant typé du décor | Passes séparées et ordre des comportements gameplay | Analyse core/runtime approfondie ; future sémantique non vérifiée | Adapter contrat partagé ; réécrire présentation | Bloquant pour M1 sans calques |
| Annuler / refaire | `MapEditingController`, `MapHistoryCoordinator` [E3](#e3) | Port public undo ; redo interne seulement [A3](#a3) | Snapshots/deltas locaux ; histoire transactionnelle disque | Deux mécanismes à articuler ; aucune double autorité | 8 tests historiques exécutés avec succès | Adapter contrat public et histoire de session | M1 |
| Collisions / occlusion | Outils collision et propriétés du décor | `ElementCollisionProfile`, gameplay, actions de décor [A5](#a5), [R1](#r1) | Masques collision/occlusion, `applyCollision` | Découpage runtime peut dépendre du profil ; ordre ne doit pas le muter | Tests occlusion runtime lus, non exécutés | Reprendre, protéger invariants ; UI guidée différée | M1 invariants ; M2 édition complète |
| Ressources / tilesets / import | Bibliothèque et palette [E5](#e5) | Registre assets/tilesets/Tiled, staging public [A6](#a6) | Références manifest, fichiers assets, identités de ressources | Filesystem, décodage, caches, rangement | Enregistrement handlers lu ; parcours import non vérifié | Reprendre contrats ; réécrire présentation intégrée | M1 ressources prêtes ; M2 imports |
| Smart Tiles / surfaces / chemins | Smart Tiles Studio et peinture | `SmartTileCellActions`, types `MapLayer.smartTile`, matériaux [A6](#a6) | Cellules, material/pattern/atlas/preset, `layerId` | Résolution dérivée, publication canonique async | Batch et tests environnement lus ; transport catalog lu, pas preuve globale | Reprendre résolveurs ; adapter intention→support interne | M2 ; sous-ensemble M1 à décider |
| Bordures | Border workspace et previews | `BorderActions`, `MapLayer.border` [A7](#a7) | Strokes/régions/features/variations/verrous | Preview puis materialize ; géométrie et révision | Entrées code lues ; tests seulement trouvés | Reprendre métier ; réécrire présentation | M2 |
| Environnements | Environment workspace | `EnvironmentActions.previewGeneration/applyGeneration` [A7](#a7) | Masques, seed, placements dérivés, couches source/cible | Génération déterministe ; écrit des placedElements ciblant une TileLayer | Tests déterminisme/halo lus ; garde taille exécutée en échec | Reprendre génération ; adapter support/ordre | M2 |
| Personnages | Character Studio, entités carte [E5](#e5) | Catalogue/actions `characterStudio*` [A8](#a8) | Characters, catalogues et instances | Sprites, comportements, événements | Registre/manifeste examinés ; parcours non vérifié | Reprendre contrats ; différer présentation complète | M3 |
| Dialogues | Dialogue Studio [E5](#e5) | Actions narratives canoniques, données core [A8](#a8) | Dialogues, bibliothèques et références | Sessions narratives editor `ChangeNotifier` ; gardes de dépendances | Entrées localisées ; parcours non vérifié | Reprendre métier ; réécrire présentation contextuelle | M3 |
| Événements / interactions | Event Builder et route V2 [E5](#e5) | Registre événements/actions [A8](#a8) | Scripts/eventsV2/facts/worldRules | Transactions narratives, références et validation | Handlers inventoriés ; non vérifié fonctionnellement | Reprendre contrats ; différer UI | M3 |
| Scènes / progression / histoire | Scenes, Storylines, Global Story, Step Studio [E5](#e5) | Données et actions narratives [A8](#a8) | Scenes, storylines, faits et étapes | État global editor et sessions spécialisées | Inventaire seulement ; moteurs non requalifiés | Reprendre ; réécrire parcours contextuel, espace histoire dédié | M3 |
| Cinématiques | Cinematic Builder [E5](#e5) | Actions cinématiques / `PresentationCinematicDraft` local [A8](#a8) | Cinématiques, pistes et médias | Canvas, timeline, playback, ressources | Entrées identifiées ; timing/audio non vérifiés | Reprendre contrats ; différer présentation | M3 |
| Catalogues de jeu | Pokémon catalogs / Encounter Studio | Handlers gameplay, modèles core [A8](#a8) | Pokémon, items, trainers, shops, badges, encounters | Cohérence catalogues ; gameplay et battle distincts | Inventaire seulement ; aucune certification mécanique | Reprendre ; différer intégration complète | M3–M4 |
| Personnalisation | Personalization Studio [E5](#e5) | Contrats présentation/projet et actions [A8](#a8) | Présentation, menus, audio, thèmes | Preview Flutter/audio, sessions editor | Entrées localisées ; rendu final non vérifié | Reprendre contrats ; réécrire présentation | M4 |
| Test / aperçu / Player | Contrats de test et hôtes séparés [R2](#r2) | `MapRenderPort`, `PlaytestPort`, `RuntimePlaytestPort` | Snapshot/révision, reçus/checkpoint selon driver | Flutter/Flame ; choix explicite du snapshot testé | Tests adapter lus ; aucun Player exécuté | Adapter raccordement réel ; reprendre moteur | M1 minimal ; M3 contextuel |
| Export / distribution | Game export controller et service [E5](#e5) | `map_distribution`, actions authoring de projection/export [A9](#a9) | Package, manifestes et receipts | Prérequis de publication plus larges que sauvegarde brouillon | Barrel et entrées lus ; test export trouvé | Reprendre ; différer qualification complète | M4 |
| MCP / API / JSONL | Serveur `tools/pokemap_mcp`, adapters editor | Façades et registre canoniques [A1](#a1), [A6](#a6) | Plans, receipts, opérations et journal | Worker/transport, root policy, handles/révisions | Describe live échoué code 78 ; tests boundary/histoire exécutés | Reprendre transport ; adapter nouvelles commandes sémantiques | M1 et chaque extension |

## Références de code et tests

Les abréviations suivantes désignent des préfixes complets : **C** = `packages/map_core/lib/src/`, **A** = `packages/map_authoring/lib/src/`, **E** = `packages/map_editor/lib/src/`, **R** = `packages/map_runtime/lib/src/`. Elles évitent de recopier de longs chemins dans chaque cellule ; tous les fichiers cités sont locaux au SHA du README.

### A1

`packages/map_authoring/lib/map_authoring_api.dart:10-52` et `map_authoring_local.dart:4-50` ; A`api/authoring_read_api.dart:39-71` ; A`api/authoring_mutation_api.dart:61-112`. La façade historique n’est pas recommandée comme import général. Les handlers internes cités ensuite sont des preuves d’implémentation, pas des imports conseillés au client.

### A2

A`workspace/project_open_service.dart:61-127` (`openProject`), A`workspace/project_snapshot_loader.dart:259-307,729-739` (`load`, vérification de changement), A`api/authoring_read_api.dart:123-131` ; C`models/map_data.dart:26-60` ; C`models/project_manifest.dart:858-866` (références de carte).

### A3

A`api/local_map_authoring_mutation_api.dart:394-485,622-682` (composition et apply), A`transactions/journaled_transaction.dart:99-185,255-310` (CAS, journal, promotions et historique), A`history/undo_service.dart:140-198` (`planRedo`). Le port A`api/authoring_mutation_api.dart:61-104` ne déclare pas redo.

### A4

A`domains/maps/map_operations_batch.dart:23-68` ; A`domains/maps/region_operations.dart:36-52,654-682` ; A`domains/maps/semantic_map_action_support.dart:103-151` (validation et sérialisation complète de la carte).

### A5

A`domains/maps/placed_element_actions.dart:103-307` ; C`models/map_data.dart:221-240` ; C`models/project_manifest.dart:1047-1048` ; C`models/element_collision_profile.dart:30-61`.

### A6

A`application/map_mutation_dispatcher.dart:9-42,87-139` ; A`registry/resource_kind_registry.dart:306-348` ; A`domains/maps/smart_tile_cell_actions.dart:51-68,144-161` ; C`models/map_layer.dart:124-147` ; C`models/project_manifest.dart:936-1064`.

### A7

A`domains/maps/border_actions.dart:168-243,275-751` ; C`models/map_layer.dart:180-191` ; A`domains/maps/environment_actions.dart:208-364,375-690,1148-1160`.

### A8

A`application/map_mutation_dispatcher.dart:23-42,87-435` ; A`registry/resource_kind_registry.dart:361-539,552-582` ; C`models/project_manifest.dart:441-521,1177-1294`. Ces références prouvent données/enregistrement et non le fonctionnement complet des parcours.

### A9

`packages/map_distribution/lib/map_distribution.dart:3-27` ; A`domains/distribution/runtime_project_projection_builder.dart` (entrée repérée, implémentation complète non auditée) ; `packages/map_editor/lib/game_export.dart:4` (barrel d’export historique, pas autorisation d’importer tout l’éditeur).

### E1

E`features/editor/state/editor_notifier.dart:727-802,3092-3296` ; E`features/editor/application/project_session_controller.dart:13-92` ; E`features/editor/state/editor_state.dart:65-151` ; E`application/use_cases/map_use_cases.dart:180-215` ; E`ui/canvas/map_canvas.dart:815-817,2074-2100`.

### E2

E`features/editor/state/editor_notifier.dart:2762-2913` ; E`application/use_cases/map_use_cases.dart:18-80` ; E`application/authoring_api/authoring_mutation_adapter.dart:94-130,246-275,402-450` ; E`infrastructure/repositories/atomic_map_document_persistence.dart:66-120`.

### E3

E`features/editor/state/editor_notifier.dart:8649-8742,8831-8860,9180-9210,9353-9460` ; E`features/editor/application/map_editing_controller.dart:11-80` ; E`application/services/map_history_coordinator.dart:7-9,313-355`.

### E4

E`features/editor/application/map_canvas_object_hit_test.dart:119-219,231-237` ; E`features/editor/state/editor_notifier.dart:7156-7225,7287-7334` ; E`features/editor/application/map_context_command.dart:3-50` ; E`ui/canvas/map_canvas.dart:2637-2700` (preview de déplacement).

### E5

E`ui/canvas/editor_canvas_host.dart:25-51` route les espaces ; E`ui/panels/tileset_palette_panel.dart` fournit la palette. Entrées secondaires localisées, non auditées intégralement : `ui/canvas/dialogue_studio_workspace.dart`, `ui/canvas/events/event_builder_workspace.dart`, `ui/canvas/events_v2/event_builder_v2_product_route.dart`, `ui/canvas/scenes_workspace.dart`, `ui/canvas/storylines_workspace.dart`, `ui/canvas/global_story_studio_workspace.dart`, `ui/canvas/step_studio_workspace.dart`, `ui/canvas/cinematics/cinematic_builder_workspace.dart`, `ui/canvas/pokemon_catalogs_workspace.dart`, `features/personalization/presentation/personalization_studio_workspace.dart`, `features/game_export/presentation/game_package_export_controller.dart` (tous sous E). La localisation de ces fichiers n’équivaut pas à la preuve d’un parcours.

### R1

C`models/map_visual_stack_config.dart:9-52`, C`operations/map_visual_composition.dart:165-263` ; R`presentation/flame/runtime_map_layer_paint_order.dart:8-18`, R`presentation/flame/map_layers_component.dart:436-486,1214-1225,1335-1364`. Voir [l’analyse d’empilement](dependances_et_flux.md#empilement-persistance-et-runtime).

### R2

A`ports/playtest_port.dart:10-31` ; R`application/runtime_playtest_port.dart:28-37,53-75` ; R`application/load_runtime_map_bundle.dart:231-241,262-306` ; `examples/playable_runtime_host/lib/src/evaluation/driver/evaluation_playtest_adapter.dart:31-68`.

### T1

Tests **lus non exécutés** de `packages/map_authoring/test/` : `workspace/project_snapshot_concurrency_test.dart:11-224`, `domains/maps/map_operations_batch_test.dart:43-216,437-549`, `domains/maps/environment_actions_test.dart:9-176`, `domains/maps/smart_tile_catalog_transport_parity_test.dart:9-53`. Ce dernier contrôle notamment les budgets/limites du transport, pas toute la parité métier.

Tests **trouvés seulement** : flux JSONL Smart Tile et Border, actions Smart Tile/Border/Environment preset, export API. Aucun résultat de ces suites n’est revendiqué.

### T2

Tests editor **lus** : `packages/map_editor/test/features/editor/application/map_canvas_object_hit_test_test.dart` (familles, ordre, gros bâtiment, couches cachées, cycle). **Trouvés non exécutés** : `test/map_canvas_object_selection_test.dart`, `test/features/editor/state/editor_notifier_map_activation_test.dart`, `test/editor_project_session_controller_test.dart`, `test/map_history_delta_test.dart`, `test/editor_image_cache_test.dart`, `test/infrastructure/repositories/atomic_map_document_persistence_test.dart`, sous `packages/map_editor/`.

Tests runtime **lus non exécutés**, sous `packages/map_runtime/test/` : `runtime_playtest_port_test.dart`, `playable_map_game_placed_element_occlusion_test.dart`, `static_placed_element_occlusion_patch_resolution_test.dart`. Les résultats des seules suites exécutées figurent dans le [README](README.md#vérifications-et-preuves-fraîches).
