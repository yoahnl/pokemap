# AC-00 — Audit des contrats source/cible d’Avelune Converter

Date : 11 octobre 2026. Statut de livraison : TO REVIEW ; audit technique vérifié, décision finale de Yoahn réservée. Périmètre : audit et documentation uniquement.

## Verdict et limite de preuve

La route native minimale est identifiée et testée avec les API existantes : bootstrap empty 2D, import d’images, atlas/collections, création/sauvegarde et relecture de cartes. AC-01 peut être cadré sans changer map_core. La future application sera dans apps/avelune_converter ; aucun dossier applicatif ni package n’est créé pendant AC-00.

Les 158 tests ciblés exécutés passent : map_core 23, map_authoring 90, map_gameplay 32, map_runtime 11, MCP 2. Cela prouve des primitives natives sur le worktree courant. Aucun convertisseur, parseur RMXP, export issu de Kanto, contrôle visuel Studio, parcours Player ou appareil mobile n’a été exécuté. La fidélité des priorités, passages directionnels et événements XP reste à qualifier.

Ticket canonique : https://app.notion.com/p/3f6197a7bfa5815e8d7febae398dd3f6. Famille existante : 14. Monde, exploration et narration — Post-bêta ; Domaine = Monde & narration, Gate bêta = non, Rang d’exécution = Hors gate. La bêta n’est ni élargie ni rendue dépendante du convertisseur. DONE reste réservé à la décision de Yoahn.

## Gate 0 — audit initial et interprétation du kit

- Dépôt : /Users/karim/Project/pokemonProject.
- Branche : main. HEAD : edb8a9aa079837653717b58da7dbad8926e40691.
- Le kit inspectait e445219017080d2c039bf2dc8c3dcedd3157c071 ; sa photographie ne décrit pas nécessairement ce checkout.
- État initial : 256 chemins modifiés ou non suivis ; apps 101, packages 132, tools 22, autre 1. Aucun chemin converter préexistant.
- Les commandes pwd, git branch --show-current, git rev-parse HEAD, git status --short --untracked-files=all, git diff --stat et git log --oneline -n 5 ont été capturées avant la première écriture documentaire.
- Les contrats map_data.dart et validators.dart étaient déjà modifiés. L’audit vise HEAD + contenu local, avec empreintes des fichiers consultés dans evidence/index.json.
- Aucun AGENTS.md plus proche trouvé dans apps, packages, tools ou documentation par rg --files.
- Les règles locales codex_rule.md et les skills using-pokemap-mcp / verification-before-completion ont été lus. Les sous-agents ont travaillé en lecture seule ; le sous-agent Tests a exécuté seulement les suites convenues.
- Aucun code produit, test, manifeste, dépendance de package, configuration Flutter, design system, roadmap ou données de jeu n’est modifié.

Adaptations explicites :

1. Le kit demande trois Markdown et un index Markdown ; AGENTS.md et codex_rule.md imposent un document consolidé. Ce rapport réunit audit, inventaire source, décision d’architecture, gates et critique ; les capacités et preuves restent en JSON, sous documentation/reports/converter/AC-00/.
2. Le kit demande le contenu complet des documents ; le dépôt interdit les copies intégrales de sources dans des rapports. Les fichiers créés, leurs zones, hashes et preuves canoniques sont fournis directement, sans snapshot Markdown redondant.
3. La règle générale codex_rule.md « créer ou modifier des tests » est inapplicable à la portée explicite AC-00, qui interdit de modifier des tests existants et reste documentaire. Les tests existants pertinents sont rejoués ; aucun comportement nouveau n’est introduit.
4. Les cas de migration évoqués dans le README des contrats ne sont pas un besoin de compatibilité pré-1.0. Le futur writer produit le contrat courant, refuse les versions inconnues et n’ajoute pas de migration implicite.
5. Le schéma target-capabilities est strict : branche, état sale et hashes restent dans ce rapport et evidence, pas dans des propriétés JSON supplémentaires.
6. Les anciens painters sous packages/map_editor ne sont pas une preuve de consommation par l’application apps/avelune_studio actuelle. La validation visible du Studio courant reste non effectuée.

Gate 0 : PASS pour lancer l’audit cible ; corpus réel absent, et donc profil source Essentials non établi.

## Corpus source et lecture du kit — AUD-03

Aucun dossier RMXP/Kanto n’a été fourni ou sélectionné dans cette session. Le chemin fourni désigne le kit documentaire, qui ne contient ni Kanto ni moteur RMXP. Aucun ancien chemin de corpus, checkout PSDK ou dossier de jeu n’a été inventorié par inférence. Il s’agit d’une source non fournie, pas d’un verdict « format non supporté ».

Les prompts, sept spécifications, contrats et exemples JSON, plan de tests, matrice de traçabilité, sources et lots du kit ont été consultés. Les sept PNG Source, Analyse, Revue assets, Comparaison, Assistance IA, Plan export et Résultat ont été ouverts. Leurs compteurs, ressources et badges sont fictifs ; ils ne constituent aucune preuve produit.

Le manifeste SHA-256 du kit contient 55 fichiers : 55 contrôlés, zéro divergence. validate_kit.py passe avec jsonschema 4.26.0 dans un environnement uv isolé : 18 JSON parsés, 7 schemas, 7 exemples valides, 5 mutations négatives refusées, 7 PNG, 7 SVG, 80 cas spécifiés et 17 lots spécifiés. Ce contrôle certifie le kit uniquement.

Aucun Game.exe, Game.rb, script Ruby, compilateur PBS, plugin source, clé API ou fournisseur IA n’a été exécuté ou utilisé. Aucun téléchargement de corpus ou runtime. La dépendance du validateur a été fournie par uv sans modifier le dépôt ni ses manifests.

## Contrats cible vérifiés — AUD-02

Les chemins ci-dessous sont relatifs au dépôt ; les lignes désignent le worktree audité.

| Contrat | Preuve du code exécuté ou consommé | Conséquence pour le writer |
|---|---|---|
| Manifeste 2D | packages/map_core/lib/src/models/project_manifest.dart:577-608 | Version v8 ; v9 correspond à la scène 3D. surfaceCatalog et anciens champs terrain/path rejetés. Ne pas injecter les schemas du convertisseur dans project.json. |
| Bootstrap | packages/map_authoring/lib/src/workspace/project_creation_contracts.dart:20-41,79-84 ; packages/map_authoring/lib/src/workspace/project_creation_kit.dart:19-106 | Demander explicitement twoD / empty / tileSize 32. Empty crée project.json sans carte, asset ou personnage ; newGame désactivé. La valeur par défaut est 16. |
| Dimensions | packages/map_authoring/lib/src/workspace/project_creation_contracts.dart:79-84 ; packages/map_core/lib/src/validation/validators.dart:2588-2593 ; packages/map_authoring/lib/src/domains/maps/map_lifecycle_adapter.dart:49-50 | La requête initiale accepte 3–256 ; ne pas présenter ce plafond comme une limite générale de toutes les cartes. La fixture Table 3×2×3 est une fixture de parseur, pas une requête bootstrap valide de hauteur 2. |
| Création sûre | packages/map_authoring/lib/src/workspace/local_project_creation_service.dart:41-50,88-125 ; packages/map_authoring/lib/src/workspace/project_creation_transaction.dart:95-125 | Destination neuve et réservation OS exclusive. Un échec après réservation peut conserver un residualPath récupérable ; ne pas promettre une disparition automatique du dossier. |
| Ouverture/relecture | packages/map_authoring/lib/src/workspace/project_open_service.dart:36-44,61-111 ; packages/map_authoring/lib/src/workspace/project_snapshot_loader.dart:365-369,416,452-469 | Open est readOnly et lit le manifeste ; la validation complète exige le chargement strict des cartes. L’ouverture seule n’est pas la preuve de validité du projet entier. |
| Map lifecycle | packages/map_authoring/lib/src/domains/maps/map_lifecycle_adapter.dart:29-118,145-190,580-581,650-654 | map.create enregistre carte+manifeste et canonicalV1 ; map.save passe par MapData.fromJson, validateurs et codec natifs avec préimage exact. Requery après mutation. |
| Identités | packages/map_authoring/lib/src/domains/maps/map_lifecycle_adapter.dart:714-722 | ID portable lowercase, 64 caractères max, noms réservés rejetés ; garder ID source et ID cible distincts dans la provenance. |
| Palette | packages/map_core/lib/src/models/map_layer.dart:102-110,282-286 ; packages/map_core/lib/src/validation/validators.dart:2667,3377-3417 | 0 = vide ; n positif = palette[n−1] ; localTileId zéro-based. cells doit avoir width×height valeurs valides. |
| Parcours des cellules | packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart:417-422 ; packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:1029-1033 | Row-major, index y×width+x. Normaliser explicitement Table source vers ce parcours. |
| Atlas/collections | packages/map_core/lib/src/models/project_tileset_source.dart:121-178,191-216 ; packages/map_core/lib/src/operations/project_tileset_visual_resolver.dart:379-390 | Rectangles de sélection d’éléments d’atlas en cellules ; géométrie, marges et spacing de l’atlas en pixels ; sourceRect de collections en pixels, pages indépendantes et IDs sparse. Éviter toute confusion d’unités. |
| Assets et chemins | packages/map_authoring/lib/src/domains/assets/asset_store.dart:7,12,265-266 ; packages/map_authoring/lib/src/domains/assets/asset_actions.dart:398-417 ; packages/map_authoring/lib/src/domains/assets/tileset_actions.dart:589-628 | Import via artifactHandle et catalogue assets/.pokemap-assets.json ; atlas source.assetId correspond au logicalPath ; chaque page collection a son asset. Pas de copie PNG suivie d’un manifeste inventé. |
| Éléments réutilisables | packages/map_core/lib/src/models/project_manifest.dart:977-994 ; packages/map_authoring/lib/src/domains/assets/element_actions.dart:148-173 | Frames temporelles, pas assemblage graphique simultané. ElementActions exige des ProjectRegularAtlasTilesetSource. Une collection native de tiles ne suffit pas à produire un élément natif. |
| Instances et collision | packages/map_core/lib/src/models/map_data.dart:283-303 ; packages/map_core/lib/src/models/element_collision_profile.dart:28-61 | Instance = pos, pixelOffset, pixelSize, rotation, visualOrder, opacité, behaviors ; applyCollision=true par défaut. La décision d’un import purement visuel doit être explicite. |
| Pile visuelle | packages/map_core/lib/src/models/map_visual_stack_config.dart:22-33 ; packages/map_core/lib/src/operations/map_visual_composition.dart:159-180,184-236 | canonicalV1 : liste front-first, peinture à rebours. Calques data exclus du rendu runtime ; configuration explicite, sans réintroduire de SurfaceLayer historique. |
| Décor/acteur | packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:628-631,1659-1688 ; packages/map_runtime/lib/src/presentation/flame/overworld_render_priority.dart:1-15 ; packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:4538-4541 | ObjectLayer au background ; certains TileLayer foreground via marqueurs nom/ID ; acteurs triés aux pieds. Le visualOrder des éléments n’est pas un contrat générique de priorité XP. |
| Animations | packages/map_core/lib/src/operations/project_tileset_visual_resolver.dart:147-156 ; packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:1028,1072 | Durées cumulées, modulo et temps écoulé natifs. Codec/résolveur testés ; reconstruction et timing XP, clock du Studio courant et rendu visible non certifiés. |
| Collision directionnelle | packages/map_core/lib/src/models/map_layer.dart:112-119 ; packages/map_core/lib/src/models/project_tileset_source.dart:9-14,91-95 ; packages/map_gameplay/lib/src/gameplay_world_state.dart:427-458,819-858 | Cellules booléennes et property.passable ; pas de masque directionnel dans ces contrats. collisionObjects restent metadata tant qu’aucune règle consommée ne les traduit. |
| Terrain | packages/map_core/lib/src/models/map_gameplay_zone_payloads.dart:64-96 ; packages/map_gameplay/lib/src/gameplay_world_state.dart:968-1003 ; packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:12291-12327 | Payloads movement/Surf présents ; tags Essentials ne prouvent aucune action terrain. Mapping générique des capacités différées non établi. |
| Pages d’événements | packages/map_core/lib/src/models/map_event_definition.dart:30-32,108-143 ; packages/map_gameplay/lib/src/event_page_resolver.dart:28-39 | Première page satisfaite. Le mapper doit normaliser l’ordre selon le contrat source réellement identifié ; pageNumber ne décide pas l’ordre. |
| API narrative actuelle | packages/map_authoring/lib/src/domains/narrative/event_actions.dart:15-22 ; packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:9994-10020 | Authoring Event V2 exposé, anciennes pages persistables encore consommées. Pas de choix automatique d’écriture V1 en contournant V2 ; mapping à établir avant AC-13. |
| Variables/self-switches | packages/map_gameplay/lib/src/script_condition_evaluator.dart:114-159,248-288 ; packages/map_runtime/lib/src/application/script_command_executor.dart:28-53 | Flags et variables consommés. Pas de self-switch source prouvé ; noms map+event+lettre et save/reload à qualifier si mapping proposé. |
| Dialogue | packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:10009-10018,11140-11147 ; packages/map_runtime/lib/src/application/script_command_executor.dart:145-168 | page.message affiche une notification ; openDialogue suspend réellement le script. Ne pas réduire un Show Text/choix à une notification. |
| Warps/connexions | packages/map_core/lib/src/models/map_data.dart:489-537 ; packages/map_authoring/lib/src/domains/maps/warp_connection_actions.dart:68-107 ; packages/map_gameplay/lib/src/gameplay_step.dart:37-54,92-103,143-157 | Contrats natifs présents. Approche/facing, entrée/bump et offset de connexion ne sont pas des collisions directionnelles. Parcours converti et save/reload à prouver. |

Les contrats de rendu communs et les consommateurs Player ont été identifiés. Le painter historique packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart et son ordre de peinture ont aussi été consultés ; ils restent une preuve de l’ancien éditeur, sans assimilation automatique au Studio courant. Le MCP Flame a été consulté par la passe runtime avant l’inspection ; la source PokeMap décide des sémantiques du projet.

Le Studio courant peint bien via le renderer partagé : apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_canvas_render.dart:117-126 → apps/avelune_studio/lib/platform/rendering/studio_map_resources.dart:415-424 → apps/avelune_studio/lib/platform/rendering/studio_map_visual_widgets.dart:10-24,268-283 → packages/map_runtime/lib/src/application/authoring_preview/runtime_authoring_map_renderer.dart:187-199. apps/avelune_studio/lib/platform/rendering/studio_resource_index.dart:87-104,134-149 collecte les pages/frames et palette/cells. Mais le chemin inspecté initialise le renderer avec update(0) uniquement (apps/avelune_studio/lib/platform/rendering/studio_map_visual_widgets.dart:79-83,114-118,157-161), sans ticker dt>0 trouvé dans ce périmètre. Animation visible du Studio courant : unverified, avec risque explicite d’aperçu statique. Aucun correctif réalisé. Les tests Studio actuels apps/avelune_studio/test/infrastructure/studio_map_resources_test.dart:36-142 sont consultés, non rejoués.

## Table source → cible → règle → test futur → perte

| Source à qualifier | Cible actuelle | Règle de conversion proposée | Test à produire au lot concerné | Risque de perte / gate |
|---|---|---|---|---|
| Table RMXP x/y/z | TileLayer.palette/cells | Décodeur inerte ; normalisation row-major ; palette internée par tileset/localTileId/transform | Table synthétique 3×2×3 avec sentinelles de coordonnées et cellules vides | Axes/calques inversés : bloquant |
| Atlas source | regularAtlas + asset import | Préserver pixels, taille de cellule, marge, spacing et logicalPath | Golden non carré + gutters + bord d’atlas | Décalage et échelle implicite |
| Tiles sparse/images | imageCollection | Conserver pages/IDs et rectangles pixels | IDs non contigus, tailles variables, référence manquante refusée | Confusion pixel/cellule ou palette/local ID |
| Maison rectangulaire | ProjectElementEntry | Rectangle contigu d’un atlas régulier ; frames temporelles | Crop exact puis élément placé, collision explicitée | Défaut applyCollision peut fabriquer du blocage |
| Composition disjointe | Placements littéraux ou image contrôlée | Conserver les placements ; rasterisation locale seulement si décidée et sans perdre provenance | Composition à trous et chevauchements | Pas de composite natif fictif dans properties |
| Composition avec plusieurs priorités | Plusieurs placements/masques qualifiés | Ne pas aplatir en un objet unique sans preuve de tri acteur | Même acteur avant/derrière chaque partie, pixels+déplacement | Fidélité partielle ; publication fidèle bloquée |
| Autotiles et timelines | Variantes littérales + timelines natives | Profils source identifiés, aucune reconnaissance universelle | Topologie des variantes et cycle aux instants limites | Codec animation natif ≠ animation XP fidèle |
| Passage plein/vide | CollisionLayer/profils d’élément | Traduction explicite des règles consommées | Obstacle, activation, bords et trajet | Support natif testé, mapping source non établi |
| Passage directionnel | Pas d’équivalent dans le contrat booléen audité | Issue de compatibilité visible ; pas d’approximation silencieuse | Traversée dans quatre directions et interaction | Unsupported dans ce profil natif ; gate fidèle |
| Priorité de tile/acteur | canonicalV1 + mécanismes d’occlusion dédiés | Séparer pile de calques et profondeur acteurs | Pieds/ligne d’égalité, haut de décor, chevauchements | Noms de layers insuffisants |
| Page source conditionnelle | Narrative V2 à déterminer | Normaliser ordre et conditions ; choisir API publique avant écriture | Deux pages concurrentes, flag, variable, disabled, reprise | Première page native satisfaite ; source non qualifiée |
| Self-switch | Mapping éventuel vers flags/facts | Identité map+event+lettre, aucune collision de noms | Deux maps même ID local, A/B, save/reload | Pas déjà supporté ; unverified |
| Texte/choix | Dialogue/Scene/script | Utiliser la vraie suspension de dialogue | Texte, choix, suite et fermeture | page.message seul perd le comportement |
| Warp/connexion | Warp/MapConnection + API canonique | Préserver cible, offset, déclencheur et approche | Aller/retour, collision cible, non-retrigger, save | Parcours converti unverified |
| Ruby/plugin inconnu | Diagnostic et source inerte | Aucune exécution ; branche non traduite visible | Opcode inconnu, classe/tag refusé, quotas | Extraction ≠ gameplay traduit |
| Catalogues Essentials | Modèles natifs sélectionnés | Profil de version établi avant mapping | Normalisation IDs/références et refus variantes | Source non fournie ; aucune compatibilité générale |

Les FG consultés par la passe runtime concernent FG-080/081/082/088/090 (événements, conditions, exécution, état, warp) et FG-120 (actions terrain). La roadmap indique notamment FG-082 et FG-120 PARTIAL aux lignes 1271 et 1557. Aucun lot FG implémenté, aucun statut proposé DONE, aucune roadmap modifiée.

## Route minimale du futur writer

1. Créer une destination neuve par LocalProjectCreationService, twoD/empty/32 ; conserver le staging et les diagnostics en cas d’échec.
2. Ouvrir via ProjectOpenService sous une WorkspacePolicy étroite, charger le snapshot strict et composer LocalMapAuthoringMutationApi.
3. Stage des artifacts puis asset.import, tileset.upsert et catégories/éléments réellement représentables.
4. map.create pour l’identité et le fichier ; construire MapData et TileLayer natifs, puis map.save avec expectedRevision fraîche.
5. Plan puis apply des mutations canoniques ; confirmations opaques là où requises ; requery et validation stricte après écritures.
6. Fermer, rouvrir et valider les cartes complètes. La future preuve AC-05 ajoute une modification/sauvegarde native puis nouvelle relecture indépendante.
7. Publier uniquement une destination vérifiée selon le mode d’étude/jouable. Les transactions sont récupérables par mutation ; l’atomicité d’une conversion complète n’est pas acquise par composition de plusieurs mutations.

AC-00 identifie cette route ; il ne crée pas de writer ni de golden converti. Les fixtures temporaires générées par les tests existants ne sont pas un projet Converter livré.

## API, JSONL, éditeur et MCP

Entrées publiques : packages/map_authoring/lib/map_authoring_api.dart:1-5,12-15,53-55 ; map_authoring_local.dart:6-7,38-44,59-66. map_authoring.dart:1-6 se décrit comme umbrella historique ; privilégier les deux surfaces ciblées.

Le describe MCP vivant retourne ok=true, protocole pokemap.authoring.v1, schemaVersion 1. Les actions asset.import, tileset.upsert, element.upsert, placed_element.place, map.create et map.save sont découvrables. Le snapshot réduit des actions et ses déclarations est conservé dans evidence/commands.json.

La matrice annonce les transports cli/directApi/editor/mcp, mais toutes les actions sélectionnées n’ont pas des endToEndVerifiedTransports et leurs transportExecutionReceipts sont vides. Une déclaration de catalogue ne certifie pas l’exécution courante de tous les transports.

Preuves fraîches : tests direct API et JSONL de bootstrap/lifecycle/assets ; deux tests du vrai serveur MCP, dont son build empaqueté. Aucun editor end-to-end courant ni mutation d’un projet utilisateur via le serveur MCP vivant. Aucune feature nouvelle à exposer dans AC-00 ; PMCP-085 exhaustif, conformance globale et reload d’un serveur de session ne sont pas requis pour cette livraison documentaire. La parité complète du futur Converter reste unverified. Aucun élargissement des roots ni édition brute d’un projet pour simuler une action manquante.

## Décision d’architecture

| Emplacement proposé, non créé | Responsabilité |
|---|---|
| packages/avelune_converter_core | Dart pur : IR, provenance, diagnostics, décisions humaines, plans, ports et use cases. Ni Flutter, ni filesystem/réseau implicite, ni import d’éditeur. |
| packages/avelune_converter_adapters | Dart pur : inventaire, decode source, raster, session, hashes, cible via map_authoring_api/local, puis fournisseur IA facultatif. |
| packages/avelune_converter_adapters/bin/avelune_converter.dart | CLI de composition partageant les use cases ; pas de package CLI séparé au départ. |
| apps/avelune_converter | Application Flutter indépendante pour le parcours guidé, jobs et revue humaine. |
| Package UI partagé minimal à cadrer avant AC-09 | Extraction seulement des tokens/primitives utiles du Studio courant ; décision de lot UI explicite avant création. |

Trois unités initiales suffisent ; domain/application restent des dossiers internes. Les schémas convertisseur ne deviennent ni le format natif Avelune ni une dépendance du Player.

Le design system Studio est interne : apps/avelune_studio/lib/presentation/theme/studio_tokens.dart:3-12,59 ; studio_theme.dart:1-4 ; shared/widgets/buttons/studio_button.dart:1-5 ; shared/widgets/layout/studio_panel.dart:1-4. Aucun package public dédié trouvé dans les manifests. Le design system historique map_editor est sous lib/src et dépend du thème de l’éditeur ; map_player_ui est orienté Player/runtime. L’alternative « importer tout Studio/map_editor » est rejetée, de même qu’une copie parallèle du thème. Cette décision ne bloque pas AC-01.

Aucun parseur Marshal retenu, aucun audit de licence tiers réalisé. AC-03 devra vérifier licence, tags, références/cycles, quotas, représentation Table et absence de callbacks/instanciation Ruby. Aucun Marshal.load, eval, _load ou marshal_load de la source. Données/graphes inertes seulement.

## Prochain lot admissible : AC-01

AC-01 doit créer uniquement le cœur Dart et les enveloppes typées/validées : provenance, source IR, candidats, décisions, capacités, plan et rapport. Refuser les versions/IDs/rectangles invalides, plans exampleOnly applicables, approbations incohérentes et capacités supported sans preuve pertinente. Les ports isolent clock, source, disque, raster, session, cible et vision ; aucun scan, parseur, writer, réseau ou interface implicite.

Fixtures futures : Table 3×2×3 pour le parseur AC-03 ; projet bootstrap minimal de dimensions valides pour AC-05 ; deux sources graphiques, un objet rectangulaire, une composition non représentable, un cas inconnu et une ambiguïté de priorité. Ces fixtures originales n’exigent pas Kanto. La sélection du corpus réel et de son profil de version sera nécessaire pour sa qualification ultérieure.

AC-01 reste TODO, non commencé.

## Commandes et résultats

Les stdout exacts et exit codes sont dans evidence/commands.json ; l’index associe leurs hashes et les fichiers consultés. Le profil final contient 28 capacités : 13 supported, 3 unsupported, 2 partial et 10 unverified. La validation du schéma passe, et quatre mutations négatives (propriété supplémentaire, preuve absente, statut inconnu, scope manquant) sont refusées.

| CWD | Commande / sélection | Résultat final |
|---|---|---|
| packages/map_core | dart test --reporter expanded test/project_tileset_source_test.dart test/project_element_frames_test.dart test/tile_layer_palette_test.dart | 00:00 +17: All tests passed! ; exit 0 |
| packages/map_core | dart test --reporter expanded test/project_tileset_visual_resolver_test.dart | 00:00 +6: All tests passed! ; exit 0 |
| packages/map_authoring | dart test --reporter expanded test/workspace/project_creation_test.dart test/workspace/project_creation_safety_test.dart test/workspace/project_open_service_test.dart test/domains/maps/map_lifecycle_contract_test.dart test/domains/maps/map_lifecycle_transaction_test.dart test/tooling/project_creation_jsonl_test.dart | 00:03 +60: All tests passed! ; exit 0 |
| packages/map_authoring | dart test --reporter expanded test/domains/assets/tileset_library_actions_test.dart test/domains/assets/tileset_image_import_test.dart test/domains/assets/element_definition_actions_test.dart test/domains/assets/element_definition_transaction_test.dart | 00:01 +30: All tests passed! ; exit 0 |
| packages/map_gameplay | dart test --reporter expanded test/script_system_integration_test.dart test/placed_element_visual_order_gameplay_test.dart test/placed_elements_collision_test.dart | 00:00 +32: All tests passed! ; exit 0 |
| packages/map_runtime | flutter test --reporter expanded test/map_layers_component_render_pass_test.dart test/map_layers_component_placed_element_render_test.dart | 00:00 +11: All tests passed! ; exit 0 |
| tools/pokemap_mcp | npm run check | tsc --noEmit ; exit 0 |
| tools/pokemap_mcp | npm run build | tsc -p tsconfig.json ; exit 0 |
| tools/pokemap_mcp | node --import tsx --test --test-concurrency=1 test/project_creation.test.ts test/map_lifecycle_server.test.ts | tests 2 ; pass 2 ; fail 0 ; exit 0 |
| packages/map_core | dart analyze puis dart analyze --format machine pour conserver tous les diagnostics | 126 issues found. ; 126 INFO, zéro WARNING/ERROR ; exit 0 |
| packages/map_authoring | dart analyze | No issues found! ; exit 0 |
| Kit | uv run --no-project --with jsonschema==4.26.0 python /Users/karim/Downloads/Avelune_Converter_Codex_Kit/05_tests/validate_kit.py --root /Users/karim/Downloads/Avelune_Converter_Codex_Kit | status passed ; 7 schemas/exemples ; 5 négatifs ; exit 0 |
| Dépôt | Contrôle SHA-256 MANIFEST_SHA256.json | 55 fichiers ; zéro divergence |

Deux essais de tooling non verts sont conservés : la première commande core incluait un chemin inexistant test/map_data_roundtrip_test.dart (exit 1, 17 tests valides et un échec de chargement), corrigé en retirant ce chemin ; le premier validateur utilisait un Python sans jsonschema (exit 2), corrigé avec uv et la version épinglée par le kit. Aucun défaut produit réparé pour faire passer l’audit.

Les 126 infos analyzer sont préexistantes à ce lot sans modification de source ; aucune correction de style hors scope. Les sorties initiales analyzer étaient tronquées par le budget de retour ; le second run machine conserve les 126 diagnostics complets. Les suites complètes, builds Studio/Player, exports, CI, release et validations d’appareils ne sont pas lancés. Aucun Converter n’existant encore, son build est N/A ; build ciblé MCP et tests natifs constituent la validation disponible.

Harnesses : gameplay runner 16266, frontend 16303 ; Flutter runner 16845, frontend 16955, testers 16991/16993. PID, PPID, commande et start-time observés pendant les runs. Inspection finale : aucun descendant confirmé survivant, aucun signal envoyé ; aucune session IDE/Flutter/MCP concurrente arrêtée.

## Fichiers créés et zones

| Fichier | Zones / objectif / impact |
|---|---|
| 00_contract_audit.md | Rapport consolidé : gates, contrats, mapping, inventaire source, architecture, validations et critique. Documentation uniquement. |
| target-capabilities.json | Profil strict des capacités natives et de leurs limites, avec preuves pertinentes. N’est pas un project.json ni un plan applicable. |
| evidence/commands.json | Captures Git initiales/finales, résultats exacts, erreurs de tooling, catalogue MCP réduit et reçus d’ownership. Aucun code source recopié. |
| evidence/index.json | Hashes SHA-256 des livrables et sources consultées, portée worktree, inventaire des références, gates et statuts de preuve. |

Aucun fichier produit ou test modifié. Le diff utile est l’ajout de ces quatre artifacts documentaires ; aucune modification aux 256 chemins préexistants. Les sources et zones pertinentes sont inventoriées dans la table de contrats et l’index, sans copie intégrale.

## Gate final, critique et état Git

AUD-01 : captures initiales/finales, empreintes et conservation des changements. AUD-02 : contrats cible, table source/cible, suites ciblées et capacités explicites. AUD-03 : absence de corpus décrite sans faux inventaire.

Empreinte des 256 chemins préexistants avant tests : 3c5bbca75c1edd1afe550a7ed8431ba6f6a1888803f4f0a884041bb80ad911d7. Même empreinte après tests et avant rédaction ; status brut SHA-256 identique 9cdc690f811568aa729757b67b06251f42298a4cca860ced3566dec05bfe0f76. Le premier contrôle final confirme 256 chemins préexistants avec le même hash, plus 4 nouveaux livrables, soit 260 chemins. Lors du dernier relevé, une modification concurrente supplémentaire apparaît dans apps/avelune_studio/lib/presentation/features/map_workspace/map_library_navigator.dart : 261 chemins au total, dont 4 livrables AC-00 et 1 chemin concurrent hors périmètre. En excluant ce chemin supplémentaire et les livrables, l’empreinte des 256 chemins initiaux reste identique. Les 75 fichiers audités conservent également leurs hashes. Branche et HEAD inchangés ; git diff --check retourne exit 0 sans diagnostic.

Passes et verdicts :

- Audit / Architecture — target_contracts, kit_architecture et runtime_contracts : route native et architecture viable, limites explicites ; correction de la distinction ancien editor / Studio actuel.
- Implémentation — passe de faisabilité target_contracts : aucun code à implémenter dans AC-00 ; route writer identifiée, AC-01 séparé.
- Tests — test_validation et passe principale : 158 tests existants passent, assertions bornées aux primitives.
- Build / Validation — passe principale et test_validation : MCP build/check verts ; kit validé ; analyzer core non silencieux mais sans warning/error ; build Converter N/A.
- Critique finale indépendante — target_contracts : PARTIAL au premier passage (scope variables, statut priorités XP et références/unités), puis PASS après corrections et seconde relecture. Aucun finding bloquant AC-00 restant ; aucun PASS de compatibilité Converter revendiqué.
- Auto-critique : tests sur un worktree sale ; absence de source/fixture convertie ; pas de certification source, visuelle ou appareil ; collisions/priorités/événements ne doivent pas être présentés comme compatibles XP complets.

Risques prioritaires : writer figé sur un contrat sale, confusion unités/indices, faux éléments composites, collision ajoutée par défaut, priorité d’événement inversée, notification assimilée au dialogue, V1 écrit en contournant V2, approximation des directions, atomicité globale supposée et import de tout l’éditeur pour réutiliser son thème.

Les captures Git finales, git diff --check et validation JSON sont intégrés aux preuves. Le garde-fou Markdown sans budget explicite retourne exit 1 pour l’unique nouveau rapport (limite par défaut 0). AC-00 ayant été explicitement demandé comme livrable d’audit, le budget borné POKEMAP_MARKDOWN_MAX_NEW=1 est appliqué à ce document consolidé : « Markdown hygiene: 1 new Markdown file(s), all in canonical locations. », exit 0. Aucun budget multi-document ni fichier hors livraison ajouté. Aucun add, commit, push, checkout, worktree, stash, reset, merge ou rebase. Gate final AC-00 : PASS documentaire pour AUD-01/02/03, avec limites source et produit explicites. Statut produit de l’audit : TO REVIEW ; aucune qualification du Converter livré. Prochain lot proposé AC-01, sans l’exécuter.
