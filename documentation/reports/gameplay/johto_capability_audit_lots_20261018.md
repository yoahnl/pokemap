# JOHTO-AUD-001 — Audit des écarts et lots du plus simple au plus complexe

Date : 18 octobre 2026. Auteur : Tom, avec trois revues indépendantes. Statut du livrable : audit à relire ; aucune implémentation demandée.

Ticket : [POST-WLD-JOHTO-AUD-001](https://app.notion.com/p/3fd197a7bfa581eebbe5d14699f1e419).
Domaine unique : [14. Monde, exploration et narration — Post-bêta](https://app.notion.com/p/3bf197a7bfa581bbb13adf367721992f).
Origine : retours de la session 01a10312-8010-7fc2-8084-d29355efb66b, puis liste consolidée en conversation.

## 1. Résultat et périmètre

Les 51 entrées de la liste précédente sont examinées ci-dessous, y compris les douze points présentés comme corrigés. Plusieurs anciens constats sont devenus trop larges : orientation du joueur, cadeaux Pokémon, émotes, mouvement pixel et introduction du dresseur ont déjà des contrats exécutables. Il faut compléter leurs lacunes précises et qualifier le contenu, pas réimplémenter ces systèmes.

Les écarts les plus faciles à isoler sont les huit DTO d'attaques Johto, Sniper et certains raccords d'authoring. Les changements les plus structurants sont les décors autonomes, la glace, le parallélisme cinématique et le chargement des grands projets. La certification des transports accompagne chaque lot ; elle ne doit pas être repoussée à une gigantesque opération de rattrapage.

Cet audit couvre le code courant, les modèles, validations, chemins de production, interfaces d'authoring, tests existants, catalogue MCP vivant et preuves Notion. Il ne certifie pas une partie complète, une application installée, les performances iPhone, ni la conformité visuelle de toutes les cartes. Une conclusion statique est identifiée comme telle ; un test de DTO vert ne devient jamais une preuve Player.

Aucun correctif, changement de schéma, modification de carte, écriture Git, build installé ou lancement de publication n'est effectué. Les futurs lots sont des propositions de périmètre, pas des autorisations d'exécution. Aucun critère bêta, statut DONE ou dépendance de release n'est modifié.

### État technique de référence

- Branche initiale : main.
- HEAD initial : 491ef2edc22f80168fd1a2b81873d2b7b8990de6.
- Arbre initial : 179 chemins modifiés/non suivis, inventaire complet en annexe.
- Les fichiers lus incluent des changements locaux : les conclusions portent sur le checkout observé, pas seulement le commit.
- Catalogue MCP connecté : 425 actions de mutation, 65 types de ressources interrogeables annoncés.
- Le registre de parité décrit 93 ressources ; ce nombre ne doit pas être confondu avec les 65 types de query.
- Résumé déclaratif de parité : 0 blockedOrMissing, catalogComplete=true, 153 actions avec au moins une preuve end-to-end, 116 entièrement couvertes ; transportCertificationComplete=false et itemTransportCertificationComplete=false.
- Un catalogue complet ne prouve pas que tous ses chemins de transport ou toutes les mécaniques sont certifiés.

### Méthode et règles

Lecture de codex_rule.md, skills/README.md, puis skills dispatching-parallel-agents, verification-before-completion et using-pokemap-mcp. Consultation de la roadmap mécanique, des sources PSDK locales et de Flame Docs. La recherche Flame générale n'a donné aucun résultat ; une recherche SpriteAnimationComponent a trouvé la documentation des composants de sprites. Aucun nouvel usage d'API Flame n'a été inventé.

Passes : Audit/Architecture, conception des corrections et découpage, Tests, Build/Validation, puis Critique finale. La passe « Implémentation » demandée par les règles est ici une revue de faisabilité : l'utilisateur demande un audit, donc aucun code ni test nouveau n'est écrit pour satisfaire artificiellement une règle de développement.

Les observations de la roadmap sont des rattachements, pas des promotions : FG-081/082/083/084/086/088/089/090/092/093, FG-103, FG-120/129, FG-140/141/143/144 et FG-180 selon le sujet. FG-200 et FG-206 concernent des extensions post-MVP, pas des dépendances ajoutées à la bêta. Aucun statut de roadmap n'est changé.

## 2. Comment lire les verdicts et la difficulté

- CONFIRMÉ : manque ou défaut démontré dans la chaîne actuelle ; la preuve peut être statique si aucun reproducer ciblé frais n'a été exécuté.
- PARTIEL : capacité réelle existante, mais raccord, couverture ou périmètre incomplet.
- ACQUIS : implémentation présente ; la portée exacte de la preuve reste indiquée. Cela ne signifie pas DONE produit.
- À ÉTABLIR : incident historique ou symptôme sans reproduction actuelle suffisante.
- DÉCISION : comportement actuel établi, mais changement produit à choisir avant de parler de bug.

Difficulté relative de livraison complète, pas seulement nombre de lignes :

| Niveau | Signification |
|---|---|
| 1/5 | Donnée ou règle isolée ; surface de régression bornée. |
| 2/5 | Raccord existant à compléter avec quelques consommateurs et garde-fous. |
| 3/5 | Contrat traversant modèles, authoring et runtime, avec UI et persistance selon le cas. |
| 4/5 | Nouveau comportement temporel ou physique, plusieurs états et reprise à prouver. |
| 5/5 | Architecture, ordonnancement ou topologie moteur ; forte incertitude et validation coûteuse. |

Les niveaux sont des estimations techniques, pas des mesures de durée. À niveau égal, l'ordre est une proposition de progression. Une dépendance peut imposer un ordre différent. Difficulté et urgence sont deux axes séparés.

## 3. Matrice exhaustive des 51 entrées

Les références S/C/M/P renvoient aux preuves détaillées de la section 4. Les numéros L désignent les lots proposés en section 5.

### Scènes et cinématiques

| ID | Point de la liste précédente | Verdict actuel et limite exacte | Preuve | Lot |
|---|---|---|---|---|
| F01 | Recul et direction verrouillée | CONFIRMÉ : actorMove recalcule le facing en 2D et spatial ; actorFace préalable ne suffit pas. | S01 | L10a |
| F02 | Simultanéité et conservation de pose | PARTIEL : ce sont deux problèmes distincts. Scheduler séquentiel ; spatial conserve la pose à succès, Flame 2D restaure les snapshots. | S02 | L10b puis L30 |
| F03 | Saut cinématique | CONFIRMÉ : pas de commande authorable de saut d'acteur ; les sauts dirigés des Borders sont une autre capacité. | S03 | L23 |
| F04 | Orientation du joueur en condition | ACQUIS en 2D avec playerFacing : modèle/resolver, tests API/JSONL ; UI inspectée ; MCP déclaré, parcours dédié non relancé. Le sous-ensemble spatial ne l'annonce pas. Ne pas développer worldState générique pour ce besoin. | S04, T06–T08 | L00 ; extension 3D distincte si demandée |
| F05 | Conditions sur l'équipe | CONFIRMÉ : partyState est refusé et non exécuté par les Scenes actuelles. Capacité, move connu et move utilisable demandent des prédicats définis. | S05 | L11 |
| F06 | Condition dresseur vaincu | CONFIRMÉ : trainerDefeated est refusé ; l'état canonique de victoire existe déjà et sert de base. | S05 | L06 |
| F07 | Pokémon offert : moves, surnom, retry | PARTIEL : givePokemonFromCatalog/receivePokemonFromCatalog couvrent learnset, PP, party/PC, surnom et reprise. Les moves exceptionnels explicitement imposés, comme Vitesse Extrême, ne sont pas démontrés par ce learnset automatique. | S06, T06/T08 | L00 puis L12 pour la seule lacune spécifique |
| F08 | WhiteOut dans une Scene | CONFIRMÉ : recovery runtime existante, mais aucune commande de Scene explicite identifiée pour ce chemin de défaite. | S07 | L24 |
| F09 | Costume/avatar persistant | PARTIEL : avatarCharacterId est sauvegardé et consommé ; commande de changement en cours de Scene manquante. | S08 | L15 |
| F10 | Réapparition PNJ par World Rule | CONFIRMÉ : montage visuel conditionné à un override de présence Scene true, même quand la règle finale du monde rend le PNJ présent. | S09 | L07 |
| F11 | Émotes et ancres | PARTIEL : émotes animées 2D et ancrage existent ; absence d'une preuve visuelle actuelle du symptôme Johto. Spatial exclut actorEmote. Le carré blanc historique n'est pas un bug produit actuel établi. | S10, T06 | L00 ; L17 seulement si reproduit |

### Monde et physique

| ID | Point | Verdict actuel et limite exacte | Preuve | Lot |
|---|---|---|---|---|
| F12 | Décor mobile sans rider | CONFIRMÉ : moveGameplayPlatform refuse quand le joueur n'est pas sur son support. Ne pas retirer cette garde globalement. | S11 | L25 |
| F13 | Groupes de grilles et état ouvert/fermé | PARTIEL : persistance des plateformes existe ; pas de contrat autonome coordonnant les props, collisions, attente et état durable. Même chantier fondamental que F12. | S11 | L25, sous-lot groupement après prop unique |
| F14 | Tourbillon terrain | CONFIRMÉ : absent de FieldAbility ; attaque de combat et effet visuel ne valent pas capacité terrain. | C11 | L27 |
| F15 | Glissade et blocs de glace | PARTIEL : DTO slide et poussée Strength d'une case existent ; pas de consommateur trouvé pour glissade continue ou bloc jusqu'à obstacle. | C12, T05 | L26a puis L26b |
| F16 | Mouvement fin et interaction hors grille | PARTIEL : déplacement pixel et fallback PNJ hors grille existent ; les props et d'autres interactions restent surtout indexés grille. Aucun cas restant précis n'est reproduit dans cette passe. | S12, T02/T07 | L28, démarrer par reproduction |
| F17 | Border horizontal exigeant un coin | ACQUIS par une autre capacité adaptée : horizontalFacade 2D existe. connectedLine conserve son contrat avec coins ; straightOnly est réservé 3D. Pas de bug général établi pour le besoin horizontal actuel. | M10 | L00 |

### Combat, objets et inventaires

| ID | Point | Verdict actuel et limite exacte | Preuve | Lot |
|---|---|---|---|---|
| F18 | Soins consommables du dresseur | CONFIRMÉ : options AI existantes, aucun stock authored ni alimentation de production. Récompenses joueur ne sont pas ce stock. | C01 | L21a |
| F19 | Dégâts Sandstorm | CONFIRMÉ par inspection du moteur PSDK actif ; compteur de météo testé, dégâts résiduels sans reproducer frais dédié. | C02, T03 | L14 |
| F20 | Huit effets de statut Johto perdus | CONFIRMÉ : valeurs et catégories des DTO réels incompatibles avec le projector actif ; pertes silencieuses. | C03, T04 | L01 |
| F21 | Sniper | CONFIRMÉ par inspection : absence de lecture du talent dans le chemin critique actif ; test spécifique absent. | C04 | L02 |
| F22 | restorePp en combat | CONFIRMÉ : conversion battle renvoie null, enum présente sans exécution. | C05 | L13 |
| F23 | Vérité des capacités d'objets tenus | PARTIEL : authoring/query déclarent moins que le registre réellement consommé. Lum/Sitrus/Smoke Ball existent dans le moteur. | C06, T03/T05 | L04 |
| F24 | Capacité réelle du sac | DÉCISION : aucune limite de slots/poche ; borne numérique de pile existante. Il faut choisir la règle produit avant de « réparer ». | C07, T05 | L22 |
| F25 | Balls adverses et intro dresseur | PARTIEL : planner, overlay et résolveur portrait existent. L'appel de production omet la map des Balls adverses, ce qui bloque enemyUsesBall et le portrait d'intro conditionné par celui-ci. | C08 | L16 |
| F26 | Stats adverses trainerV0 | CONFIRMÉ : IV15, EV0, nature Hardy fixes ; difficulté AI ne représente pas les stats de chaque membre HGSS. Ce n'est un défaut produit que si cette authorabilité est requise. | C09 | L21b |
| F27 | MultiBattle et réserves | DÉCISION : réserves singles câblées ; multi/doubles exclus du setup. Aucun bug de réserve singles établi. Extension distincte, hors réparation Johto minimale. | C10 | L32 optionnel |

### MCP, authoring et performances

| ID | Point | Verdict actuel et limite exacte | Preuve | Lot |
|---|---|---|---|---|
| F28 | Query eventV2 coûteuse | CONFIRMÉ : détails de tous les événements construits avant filtre/page/fieldMask et catalogue recalculé par événement. Aucun pourcentage de gain mesuré. | M01 | L05 |
| F29 | Batch narratif insuffisant | PARTIEL : event_v2.record_upsert_batch existe et est testé direct/JSONL. World Rules/Facts et trainers restent unitaires. Aucun motif pour refaire le batch EventV2. | M02, T09 | L19 par domaine |
| F30 | Lecture gros plans/diffs | PARTIEL : enveloppes bornées et APIs diff/page/chunk existent ; commandes de lecture génériques absentes JSONL/MCP. | M03 | L20 |
| F31 | Lecture pokemonDocument | CONFIRMÉ : ressource décrite mais exclue de la whitelist queryable. Écriture typée existante distincte. | M04 | L08 |
| F32 | Capture avec vrais PNJ/occlusion | CONFIRMÉ : service capture de couches sans personnages, alors qu'un renderer différent sait includeCharacters. Réutiliser le chemin adapté. | M05 | L17 |
| F33 | Diagnostics d'objet absent | PARTIEL : contexte itemCatalog non transmis par ModernNarrativeInspector ; index accepte ce catalogue. Ancien faux positif non reproduit fraîchement ; couverture des conséquences Scene également limitée à la forme. | M06 | L18 |
| F34 | Erreur après application et finalisation | PARTIEL : commit physique peut précéder hook historique ; recovery déjà implémentée et testée. Le besoin résiduel est observabilité/statut sûr, pas réécriture des transactions sans reproduction. | M07, T09 | L03a |
| F35 | render.worker_failed | À ÉTABLIR pour la cause Johto. Gateway masque l'exit non nul et perd stderr utile ; rendu MCP réel passé dans la sélection fraîche. Cela ne prouve pas la résolution de l'incident ancien. | M08, T10 | L03b diagnostic borné |
| F36 | Certification des quatre transports | PARTIEL : registre complet, mais certification incomplète. Plusieurs actions ont preuves ; l'Éditeur reste notamment absent de la preuve batch EventV2. Ne pas étendre le ticket à 425 actions sans mandat. | M09, catalogue vivant | L29 + critères de chaque lot |

### Export et grands projets

| ID | Point | Verdict actuel et limite exacte | Preuve | Lot |
|---|---|---|---|---|
| F37 | Export Johto bloqué par quotas | PARTIEL : refus historique documenté ; quotas toujours présents. Aucun nouvel export complet du projet mutable n'a été exécuté pendant cet audit. Le blocage de l'état actuel n'est donc pas recertifié. | P01, historique Notion | L31a diagnostic avant architecture |
| F38 | Partitionnement et chargement à la demande | CONFIRMÉ architecturalement : project.json central complet encore décodé. Des caches/préchargements existent déjà ; la lenteur/RAM actuelle sur iPhone n'est pas mesurée. | P02 | L31b–d après L31a |
| F39 | Profil d'export par MCP | CONFIRMÉ : game_export ne fournit que handle/mode/output ; la voie canonique attend un profil sauvegardé. Pas de CRUD sémantique de profil identifié dans ce catalogue. | P03 | L09 |

### Corrections déjà signalées, recontrôlées

| ID | Point | Verdict actuel et portée | Preuve | Lot |
|---|---|---|---|---|
| F40 | Facts EventV2 bool/int/string | ACQUIS : visiteur whenTyped ; tests frais modèle/read model. | S13, T01 | L00 |
| F41 | Exceptions narratives JSONL | ACQUIS : catch NarrativeAuthoringException avec code métier/détails filtrés. worker.internal reste légitime pour erreur inattendue. | S13, T10 | L00 |
| F42 | Condition badge | ACQUIS : profil canonique du joueur, tests modèle et gameplay frais. | T01/T02 ; ticket Scenes | L00 |
| F43 | Don d'objet reçu/sac plein/reprise | ACQUIS : ports et non-consommation en refus ; limite de pile uniquement, voir F24. | T01/T02 ; ticket Scenes | L00 |
| F44 | Patch fin des graphes/conditions | ACQUIS : actions présentes au catalogue vivant et contrats du ticket. Pas de test Player neuf de l'ensemble graphique. | catalogue vivant ; ticket Scenes | L00 |
| F45 | Delta de diagnostics dans plans | ACQUIS : introduced/resolved/unchanged et tests existants relancés dans la sélection authoring. Pas de confusion avec canPublish global. | T09 ; ticket Scenes | L00 |
| F46 | Simulation de branches | ACQUIS avec limite : vrai exécuteur et ports fournis ; pas une simulation GameState/Player complète. | catalogue scene.simulate ; ticket Scenes | L00 |
| F47 | Physique des Borders 2D | ACQUIS : masques/transformations/versions et mouvement bloqué couverts par tests frais. Ne prouve pas chaque profil de carte. | T02 | L00 |
| F48 | Plateformes Sandra/boutons | ACQUIS pour contrats et publication historique ; Player natif documenté dans Notion. Pas de nouvelle certification Player/app installée pendant cet audit. | ticket Platforms et journal Johto | L00 |
| F49 | Interaction PNJ après plateforme | ACQUIS : fallback de contact pixel testé fraîchement ; ne couvre pas tous les props. | S12, T02 | L00 |
| F50 | Métadonnées staging gros fichier | ACQUIS : réessais de vérification bornés sur staging/temporaires dont le contenu gelé est connu ; les ressources vivantes gardent leurs contrôles stricts. Tests frais de stabilité et refus. | T09 | L00 |
| F51 | Faux diagnostics globaux cartes/Facts | ACQUIS par source actuelle : mapsById transmis, resolvedFactOperator/valeur typée utilisés. Régressions historiques dans Notion ; pas de suite globale fraîche pour cette entrée. | S14 | L00 |

## 4. Preuves techniques et causes

### S — Scènes, cinématiques et physique

**S01. Recul.** packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart:746 et :751 limitent à walk/run et direct/manual. packages/map_runtime/lib/src/presentation/flame/flame_cinematic_runtime_playback_sink.dart:806–821 et packages/map_runtime/lib/src/spatial/spatial_cinematic_runtime_playback_sink.dart:332–346 réorientent selon le segment. packages/map_core/lib/src/models/scene_actor_route.dart:9–17 ne cache pas d'étape backwards ou jump.

**S02. Temps et pose.** packages/map_core/lib/src/models/cinematic_asset.dart:685–753 : liste ordonnée, pas de groupe parallèle/début absolu. packages/map_runtime/lib/src/application/scene_runtime/cinematic_runtime_playback_controller.dart:147–205 consomme un seul step. Sink Flame :351–379 et :424–427 restaure les snapshots ; sink spatial :403–416 commit à succès. Tests existants : packages/map_runtime/test/flame_cinematic_runtime_playback_sink_test.dart:151 et spatial_cinematic_runtime_playback_sink_test.dart:9. Ces tests Flutter n'ont pas été relancés.

**S03. Saut.** cinematic_asset.dart:7–22 et scene_actor_route.dart:9–17 n'offrent pas l'action. playable_map_game.dart:5645 possède un saut dirigé gameplay distinct ; test existant playable_map_game_directed_jump_test.dart.

**S04. Orientation.** packages/map_core/lib/src/models/scene_asset.dart:72–80 et :127–135 ; packages/map_core/lib/src/diagnostics/scene_diagnostics.dart:2233–2236 ; playable_map_game.dart:13651–13654 ; apps/avelune_studio/lib/presentation/features/scenes/scene_condition_form.dart:23–28 et :105–110 ; packages/map_authoring/lib/src/domains/narrative/scene_actions.dart:288–294. SpatialGameplayCapabilities.conditionSources, packages/map_core/lib/src/read_models/spatial_gameplay_capabilities.dart:50–57, ne la déclare pas.

**S05. Conditions équipe/dresseur.** packages/map_core/lib/src/authoring/scene_authoring_operations.dart:1971–1982 et scene_diagnostics.dart:2243–2249 refusent ces sources ; playable_map_game.dart:13679–13690 ne les résout pas. Autorité victoire existante : packages/map_runtime/lib/src/application/story_flags_manager.dart:29–54 et scenario_conditions.dart:26–31.

**S06. Cadeau catalogue.** Ancien givePokemon : scene_consequence.dart:102–113 ; writer :656–679. Nouveaux contrats : packages/map_runtime/lib/src/application/scene_runtime/runtime_scene_pokemon_catalog.dart:33–65 et :137–177 ; scene_consequence_runtime_writer.dart:689–733 ; packages/map_core/lib/src/models/scene_interactive_command.dart:55–62 ; API scene_actions.dart:95–129. L'interaction contrôle capacité, surnom et fingerprint dans scene_interactive_pokemon_gift.dart:26–59, :120–132, :217–233. Tests runtime existants : scene_catalog_pokemon_gift_test.dart:237/:297, scene_interactive_pokemon_gift_test.dart:59/:314. L'existence de ce parcours n'autorise pas à promettre des moves exceptionnels arbitraires.

**S07. WhiteOut.** playable_map_game.dart:10911–10988 traite HP/PP, argent, point de reprise, warp et checkpoint ; aucune commande équivalente dans SceneInteractiveCommand/SceneConsequence. Test existant packages/map_runtime/test/playable_map_game_whiteout_lite_test.dart, non relancé.

**S08. Avatar.** packages/map_core/lib/src/models/save_data.dart:674–713, save_data.g.dart:217–233 et playable_map_game.dart:17348–17357. Persistance oui, conséquence Scene de changement non identifiée.

**S09. Présence.** playable_map_game.dart:4073–4091 rafraîchit ; :4151–4159 exige sceneNpcPresenceOverride == true pour monter. packages/map_runtime/lib/src/application/npc_runtime_presence.dart:18–51 est le prédicat de présence. Les tests de prédicats ne couvrent pas un acteur Flame absent→présent→absent.

**S10. Émotes.** packages/map_core/lib/src/models/cinematic_emote_catalog.dart:80–88/:112–218 ; cinematic_emote_sprite_cache.dart:41–80 ; playable_map_game_support.dart:194–298 ; sink Flame :218–222 ; inspecteur Studio cinematic_inspector_step.dart:100–108. Spatial exclut actorEmote à spatial_gameplay_capabilities.dart:43–49. Catalogue frais testé ; rendu/placement Flutter non relancé.

**S11. Props.** packages/map_gameplay/lib/src/moving_platform_gameplay.dart:189–193 exige un rider. Le test moving_platform_gameplay_test.dart:149–157 exige ce refus. Persistance MovingPlatformWorldState à save_data.dart:823 et commit runtime playable_map_game.dart:12273–12288. Réutiliser ces autorités sans casser le contrat existant.

**S12. Finesse.** packages/map_gameplay/lib/src/gameplay_step.dart:327–498 : mouvement pixel ; :752–798 : première recherche d'interaction grille ; :800–810 : fallback PNJ pixel. Props indexés grille dans gameplay_world_state.dart:611–626. Spatial : packages/map_gameplay/lib/src/spatial_npc_interaction.dart:27–105, volume d'approche à positions réelles. Un correctif générique de mouvement sans cas rouge serait injustifié.

**S13. Corrections typées/erreurs.** packages/map_core/lib/src/operations/build_narrative_event_project_catalog.dart:174 utilise whenTyped ; jsonl_worker.dart:451 intercepte NarrativeAuthoringException, :465 conserve worker.internal pour inattendu. Les autres actions fines sont décrites par le catalogue actuel et le ticket Scenes.

**S14. Validateur global.** packages/map_core/lib/src/operations/narrative_project_validator.dart:328/:576/:808/:1318 transmet mapsById. :1146–1148 utilise resolvedFactOperator et resolvedExpectedFactValue booléenne pour le cas true, au lieu de lire aveuglément une valeur int/string comme bool.

### C — Combat et objets

**C01. Soins adverses.** packages/map_core/lib/src/models/project_trainer.dart:109/:179 : pas de stock consommable. packages/map_battle/lib/src/domain/ai/psdk_battle_ai.dart:12/:91/:134 et runtime_trainer_battle_overrides.dart:41–59 savent accepter des options ; playable_map_game.dart:9168–9171 n'en fournit pas.

**C02. Sandstorm actif.** packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart:18–28 puis BattleSessionFacade.fromPsdkSetup. packages/map_battle/lib/src/domain/handler/battle_end_turn_handler.dart:15–49 et :128–155 : progression météo sans dégâts. packages/map_battle/lib/src/domain/effect/field/weather_effect.dart:6–36 : pas de hook résiduel. L'ancien BattleConditionEngine:1016+ a des dégâts, ce qui ne prouve pas le chemin PSDK actif.

**C03. Statuts.** packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart:688–698 appelle packages/map_battle/lib/src/psdk/canonical_psdk_move_projector.dart:162–206/:246–263. Les tests acceptent l'ignorance des statuts inconnus : leur réussite n'empêche pas la perte des DTO Johto invalides.

Catalogue externe lu, jamais écrit : /Users/karim/Desktop/pokeMap Project/Bourg Palette — essai natif/data/pokemon/catalogs/moves.json. 348 033 octets ; SHA-256 stable pendant inspection : f33a0c49ffae66c3839e0e2cf568b9a9987d32e3a04d2933e2e4eaa9c30f162c.

| Attaque | Ligne ID | DTO actuel | DTO compatible actuel | Chance |
|---|---:|---|---|---:|
| poison_powder | 454 | apply_status / poisoned | apply_status / poison | 100 % |
| stun_spore | 499 | apply_status / paralyzed | apply_status / paralysis | 100 % |
| sleep_powder | 544 | apply_status / asleep | apply_status / sleep | 100 % |
| bite | 1450 | apply_status / flinch | apply_volatile_status / flinch | 30 % |
| confuse_ray | 3342 | apply_status / confused | apply_volatile_status / confusion | 100 % |
| smog | 3491 | apply_status / poisoned | apply_status / poison | 40 % |
| sludge | 3535 | apply_status / poisoned | apply_status / poison | 30 % |
| hyper_fang | 3745 | apply_status / flinch | apply_volatile_status / flinch | 10 % |

L01 vise d'abord les définitions actuelles par action canonique et un test lisant ces données. Une prévention générique peut être décidée séparément après localisation du producteur ; aucun adaptateur legacy ni migration pré-1.0 par défaut.

**C04. Sniper.** packages/map_battle/lib/src/domain/move/battle_move_damage_calculator.dart:83–116 et battle_move_critical_resolver.dart:8–30 n'appliquent pas le talent. Recherche négative de sniper dans le chemin concerné. Reproducer déterministe spécifique requis au lot.

**C05. PP.** packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart:332–335 et :361–364 excluent restorePp ; enum à :50/:375–376 insuffisante.

**C06. Vérité objets tenus.** packages/map_core/lib/src/read_models/item_capability_truth.dart:136 contre packages/map_battle/lib/src/domain/effect/item/item_effect_registry.dart:59/:230–237/:292–304. runtime_battle_combatant_seed_builder.dart:418–454 consulte le registre réel. project_query_service.dart:1313/:1420 et item_catalog_actions.dart:84 consomment la table restreinte d'authoring.

**C07. Sac.** save_data.dart:720 fixe maximumBagEntryQuantity à 2^63−1 ; :796–806 définit une liste d'entrées sans capacité. packages/map_gameplay/lib/src/items/bag_operations.dart:61–100 vérifie identifiant, quantité et dépassement.

**C08. Ball/portrait.** playable_map_game.dart:9246–9249 omet enemyLineupBallItemIdsByIndex ; packages/map_runtime/lib/src/presentation/flame/battle_combatant_ball_resolver.dart:15/:38–44 retourne null par défaut côté ennemi. battle_overlay_component.dart:1568–1588/:1618–1627 conditionne Ball et intro. _loadTrainerBattleImage à playable_map_game.dart:10241–10270 charge artwork puis Character.neutre. battle_intro_animation_planner.dart:59/:113 et battle_turn_animation_planner.dart:605–650 savent déjà présenter ces Balls.

**C09. Stats.** packages/map_gameplay/lib/src/pokemon_stat_calculator.dart:193–215 fixe trainerV0. packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:880–887 l'utilise. project_trainer.dart:83–102 n'offre pas IV/EV/nature. Difficulté AI et précision HGSS restent distinctes.

**C10. Singles/multi.** runtime_psdk_battle_setup_mapper.dart:171–196 injecte les réserves ; packages/map_battle/lib/src/psdk/domain/psdk_battle_setup.dart:61–67 construit active+reserves. packages/map_battle/lib/src/domain/battle/battle_setup.dart:68–72 rejette le non-singles. Ne pas traiter ce choix de scope comme une réserve cassée.

**C11. Tourbillon.** packages/map_core/lib/src/models/enums.dart:379–409 annonce huit FieldAbility sans whirlpool.

**C12. Glace.** enums.dart:335–341 et GameplayMovementEffect.slide définissent la donnée ; aucun consommateur trouvé dans gameplay/runtime. packages/map_gameplay/lib/src/field_obstacle_action.dart:281–360 pousse d'une case. Le modèle ne prouve ni glissade automatique ni puzzle Acajou.

### M — Authoring et transports

**M01. Query.** packages/map_authoring/lib/src/workspace/project_query_service.dart:63–91 applique l'opération après construction des ressources ; :1136–1143 et :2061–2073 enrichissent tous les EventV2 et reconstruisent le catalogue par record. Optimiser doit conserver filtres, ordre, pagination, détails et diagnostics.

**M02. Batch.** event_v2.record_upsert_batch est borné, testé direct/JSONL. packages/map_authoring/lib/src/domains/narrative/fact_rule_actions.dart:14–41 reste unitaire ; domains/gameplay/campaign_content_actions.dart:145–160/:179–200 prend un trainer. Le catalogue vivant annonce le batch EventV2, pas un batch WorldRule. Pas de batch transversal arbitraire comme première solution.

**M03. Projections.** packages/map_authoring/lib/src/api/local_map_authoring_mutation_api.dart:499–533 expose lecture diff/payload ; packages/map_authoring/lib/src/api/authoring_result_projection.dart:18–20 fixe les bornes 256 Kio enveloppe, 200 lignes, 128 Kio par chunk. La présence de ces APIs ne prouve pas leurs commandes JSONL/MCP dans tools/pokemap_mcp/src/tools/mutations.ts et le switch JSONL. Le manque de transport générique reste réel. La portée actuelle est session/projet et payload immuable à fingerprint, pas une interdiction générale de consulter un ancien reçu après nouvelle révision du projet.

**M04. Documents.** packages/map_authoring/lib/src/registry/resource_kind_registry.dart:584 décrit pokemonDocument ; whitelist :727–793 ne le rend pas queryable.

**M05. Rendu.** packages/map_runtime/lib/src/application/authoring_preview/runtime_authoring_asset_map_capture_service.dart:49–78 ne monte que couches fond/premier plan ; runtime_authoring_map_renderer.dart:17/:23 possède includeCharacters et :50 un chemin de patches. Demander un aperçu avec personnages ne nécessite pas un nouveau renderer complet.

**M06. Catalogue objets.** packages/map_authoring/lib/src/domains/narrative/modern_narrative_inspection.dart:138–153/:225–228 n'injecte pas itemCatalog. packages/map_core/lib/src/read_models/narrative_dependency_index.dart:481–486 accepte ce contexte et :523–529 collecte les définitions. packages/map_core/lib/src/diagnostics/scene_diagnostics.dart:454–458 n'a pas ce paramètre ; :1086–1118 valide seulement identifiant non vide/quantité. Il faut tester objet présent, absent et catalogue non fourni, sans transformer une absence de contexte en fausse certitude.

**M07. Transaction.** packages/map_authoring/lib/src/transactions/journaled_transaction.dart:329–349 écrit committed et receipt avant le commitHook historique. packages/map_authoring/lib/src/transactions/recovery_service.dart:108–133 reconnaît l'after-state committed et finalise. packages/map_authoring/lib/src/tooling/jsonl_worker.dart:461–467 peut répondre worker.internal à l'erreur inattendue. Les tests de recovery ne doivent pas être effacés au profit d'un nouvel algorithme de transaction.

**M08. Passerelle.** tools/pokemap_mcp/src/runtime_gateway.ts:443–449 produit render.worker_failed pour un exit non nul ; :779 jette stderr. La cause historique reste non démontrée. Le lot est un diagnostic borné et assaini avec test d'échec, pas « réparer le renderer » sans reproduction.

**M09. Parité.** BETA-WLD-010 est explicitement hors gate bêta malgré son identifiant historique. Il reste TODO pour la certification EventV2 complète. POST-WLD-SCENES-001 reste TO REVIEW ; POST-WLD-PLATFORM-001 DOING. Les résultats ne changent pas ces décisions. Des preuves batch Éditeur manquent au registre ; catalogue complet ≠ certification complète.

**M10. Border.** packages/map_core/lib/src/models/border_blueprint.dart:485–495 distingue horizontalFacade 2D de straightOnly 3D. packages/map_core/lib/src/operations/border_publication_readiness.dart:889–896 exige cap+straight et pas corner pour façade. Ne pas dégrader connectedLine ou ajouter un faux coin pour contourner un modèle inadapté.

### P — Export et grands jeux

**P01. Quotas.** packages/map_distribution/lib/src/game_package_security_policy.dart:36–50 impose notamment 32 Mio par JSON, 4 Mio pour le manifeste d'archive et 1 Gio pour l'archive et le contenu total. Le journal ajoute l'ancien refus sur nombre de valeurs JSON. Pas de modification de seuil ; pas d'assertion que l'état actuel échoue identiquement sans nouvel export.

**P02. Monolithe.** packages/map_authoring/lib/src/domains/distribution/runtime_project_projection_builder.dart:613–616 écrit project/project.json ; packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart:136–171 lit/décode le manifeste entier dans un isolate, :290–297 réutilise un manifeste préchargé et :25–39 expose des métriques. apps/pokemap_hub/lib/features/session/application/services/hub_runtime_startup_bootstrap.dart participe au démarrage. Une partition sur disque suivie de la reconstruction intégrale au démarrage ne satisferait pas l'objectif mémoire.

**P03. Profil.** tools/pokemap_mcp/src/tools/game_export.ts:24–33 ne fournit pas de configuration du profil ; packages/map_authoring/lib/src/domains/distribution/game_package_export_api.dart:112–120 exige le profil enregistré et peut refuser missingExportProfile. Le besoin porte sur une API sémantique de lecture/validation/écriture, pas sur une écriture JSON manuelle.

### Références PSDK lues, autorité de parité

Racine commune : /Users/karim/Project/pokemonProject autre dossiers/pokemonsdk-development/.

| Sujet | Ruby et lignes utiles |
|---|---|
| Recul / orientation | scripts/4 Systems/003 Map Engine/2 Logic/50 RMXP/120 Game_Character_move.rb:473–486 |
| Saut et réception | même fichier :494–517 |
| Direction fixe | scripts/4 Systems/003 Map Engine/2 Logic/50 RMXP/110 Game_Character_2.rb:371–374 |
| Route puis attente | scripts/1 RMXP Scripts/028 Interpreter_5.rb:172–193 |
| Cadeau, surnom, PC | scripts/2 PSDK Event Interpreter/130 Interpreter_Sequences.rb:14–32 |
| Changement graphisme | scripts/1 RMXP Scripts/029 Interpreter_6.rb:165–172 |
| Défaite/blackout | scripts/5 Battle/04 Logic/1 Handlers/111 BattleEndHandler.rb:38–48/:81–89 |
| Sandstorm | scripts/5 Battle/06 Effects/06 Weather Effects/100 Sandstorm.rb:6–8/:13–25/:46–50 |
| Sniper | scripts/5 Battle/10 Move/101 Damage_Calc.rb:187–191 |
| Sitrus | scripts/5 Battle/06 Effects/05 Item Effects/050 HpTriggered Healing Berries.rb:74–80 |
| Lum | scripts/5 Battle/06 Effects/05 Item Effects/100 Lum Berry.rb:42 |
| Smoke Ball | scripts/5 Battle/06 Effects/05 Item Effects/100 SmokeBall.rb:20 |

Référence HGSS déjà épinglée dans les preuves Johto : pret/pokeheartgold 9d8b7591f09b65804da2fb2dfd56f320633e0d36, blackthorn.c pour plateformes/support. Aucun code externe recopié ni nouvelle prétention de conformité Nintendo. Les règles PSDK et HGSS doivent être choisies explicitement quand elles divergent.

## 5. Lots proposés, du plus simple au plus complexe

L00 est une qualification des acquis, pas un lot de réimplémentation. L01–L31 correspondent aux écarts ou diagnostics utiles. L32 est optionnel et ne doit pas entrer dans le chemin critique de la réparation singles/Johto. Les lettres a/b/c sont des livraisons distinctes, à vérifier et relire séparément ; elles ne justifient pas un commit mélangeant plusieurs tickets.

### Niveau 0 — Retirer le travail déjà fait

| Lot | Périmètre | Sortie attendue |
|---|---|---|
| L00 | F04/F11/F17 et F40–F51 ; nouveaux dons catalogue de F07. | Réutiliser les capacités actuelles, conserver les tests ; qualification d'un événement réel uniquement quand le contenu est demandé. Ne pas recréer badges, graph patches, émotes ou plateformes. |

### Niveaux 1 et 2 — Corrections et raccords ciblés

| Ordre | Lot | Difficulté | Travail précis | Critère de sortie et dépendance |
|---:|---|---:|---|---|
| 1 | L01 — Huit DTO d'attaques | 1/5 | Corriger les huit définitions par contrat canonique ; isoler une prévention générique si souhaitée. | Projector lisant les vraies données : huit effets conservés et chances exactes ; combats déterministes de statut/volatile. Aucun alias legacy ajouté par défaut. |
| 2 | L02 — Sniper | 1/5 | Ajouter le modificateur dans le calcul actif, avec convention PSDK/HGSS explicite. | Critique forcé avec/sans talent, hors critique inchangé, suppression du talent et arrondis. Indépendant des autres lots. |
| 3 | L03a — Réponse après commit | 2/5 | Rendre visible committed/recoverable/finalized dans les erreurs et la lecture de statut. | Échec injecté après promotion : aucune réapplication ni succès mensonger ; recovery existante conservée. |
| 4 | L03b — Diagnostic render worker | 2/5 | Conserver une cause bornée et assainie, code/exit et identifiant de trace. | Worker en échec volontaire : détail exploitable sans secrets/stack brute ; cas réussi inchangé. Diagnostic avant toute réparation graphique. |
| 5 | L04 — Vérité objets tenus | 2/5 | Réconcilier authoring/query/validation avec les effets réellement consommés. | Lum/Sitrus/Smoke Ball acceptés selon capacité prouvée ; effet absent toujours refusé ; tests de consommation et retour de combat. |
| 6 | L05 — Query EventV2 | 2/5 | Construire un catalogue par requête/snapshot ; éviter détails non sélectionnés sans changer les filtres. | Comptages d'enrichissement et sorties identiques list/get/search/pagination/fieldMask ; mesure avant/après sur fixture réaliste, sans soak CI. |
| 7 | L06 — Condition trainerDefeated | 2/5 | Lire la victoire canonique avec référence trainer guidée. | Avant/après victoire/défaite/reload, ID absent refusé, UI et transports. Aucun Fact de victoire dupliqué. |
| 8 | L07 — Remount WorldRule | 2/5 | Utiliser le prédicat final de présence pour montage/démontage et collisions cohérentes. | GameWidget absent→présent→absent→présent, voisin chargé et reload ; pas seulement test de booléen. |
| 9 | L08 — Query pokemonDocument | 2/5 | Ajouter lectures typées bornées à la whitelist et au dispatcher. | list/get/filters/pagination, document absent, racine/chemin sûr et transports ; écriture existante préservée. |
| 10 | L09 — Profil d'export sémantique | 2/5 | Lire, valider et authorer le profil par API canonique/MCP, UI réutilisée. | Profil valide/périmé/référence absente, persistence et export utilisant le profil enregistré ; aucun JSON manuel. |

Les scores 1/5 ne signifient pas qu'une modification directe des fichiers de projet serait acceptable : les mutations de contenu restent canoniques et révisionnées.

### Niveau 3 — Contrats métier traversants

| Ordre | Lot | Difficulté | Travail précis | Critère de sortie et dépendance |
|---:|---|---:|---|---|
| 11 | L10a — Facing pendant déplacement | 3/5 | Dissocier mouvement et orientation, préviews et sinks 2D/spatial. | Quatre directions de recul, routes multi-segments, annulation et reprise. Aucun scheduler parallèle nécessaire. |
| 12 | L10b — Pose finale explicite | 3/5 | Politique succès/annulation ; réconcilier pose visuelle et world state 2D. | Position/orientation après dialogue suivant et reload ; rollback à annulation ; spatial acquis préservé. À séparer de L30. |
| 13 | L11 — Conditions d'équipe | 3/5 | Petits prédicats typés : capacité de réception, move connu/utilisable. | PP0, KO, move absent, capacité terrain verrouillée, référence invalide, tests Player et transports ; s'appuyer sur S05. |
| 14 | L12 — Cadeau à moves exceptionnels | 3/5 | Étendre uniquement le contrat catalogue existant si le Minidraco spécial ne peut y être décrit. | Vitesse Extrême exacte, surnom, party/PC/noCapacity, refus sans consommation, reprise et reload. L11 uniquement si une branche préalable autonome est requise ; les ports existants suffisent déjà pour refus et retry. |
| 15 | L13 — PP dans le sac de combat | 3/5 | Cible Pokémon/move, exécution, narration, consommation et write-back. | PP partiels/max, refus sans consommation, cible invalide/KO selon règle retenue, coût du tour et reload post-combat. |
| 16 | L14 — Sandstorm résiduel | 3/5 | Brancher le résiduel dans le moteur PSDK actif avec ordre de fin de tour. | 1/16 min1, immunités, expiration, KO/remplacement, suppression météo/objets ; test qui échoue sur le code actuel. |
| 17 | L15 — Avatar/costume | 3/5 | Conséquence typée, résolution média et rafraîchissement Player persistant. | Changement/restauration/reload, référence absente, dimensions/collision maîtrisées ; pas simple animation d'apparence temporaire. |
| 18 | L16 — Balls adverses | 3/5 | Décider politique authored/default, alimenter le resolver de production et ressources. | Intro portrait+premier envoi+remplacement, image/planche absente, sauvage/dresseur ; preuve Player. Les planners existants sont réutilisés. |
| 19 | L17 — Capture PNJ et émotes | 3/5 | Réutiliser includeCharacters et ordre de rendu ; diagnostiquer l'émote uniquement si encore visible en défaut. | Pixels/occlusion devant-derrière, alias media, bounds ; même scène Studio/Player/capture. Ne pas promettre une correction du carré blanc sans repro. |
| 20 | L18 — Catalogue objets dans diagnostics | 3/5 | Propager le contexte aux inspecteurs/diagnostics concernés. | Objet présent accepté, absent rejeté, contexte manquant expliqué, aucune régression des vrais blocages ; transports des diagnostics. |
| 21 | L19 — Batch sémantique par domaine | 3/5 | Commencer par WorldRules, puis Facts/trainers si mesures utiles ; garder EventV2 acquis. | Un draft/validation/transaction par batch borné, refus atomique, révision, collisions d'IDs, sorties identiques à la séquence ; dépend L20 pour gros retours si nécessaires. |
| 22 | L20 — Lire les projections par transports | 3/5 | Exposer diff paginé et payload chunks existants par JSONL/MCP. | Handles opaques liés à session/projet et reçu/plan immuable, intégrité fingerprint, page limite, restart/expiration/refus cross-session, confirmation/apply sur gros plan. Ne pas invalider arbitrairement un reçu historique ni relever la limite globale. |
| 23 | L21a — Stock de soins adverse | 3/5 | Modèle trainer, pickers, catalogue et options AI consommables. | Stock borné, consommation unique, pas de soin infini, effet refusé si non pris en charge, événements et export/reload. L04 pour vérité, L13 seulement pour objets PP supportés. |
| 24 | L21b — Stats adverses authorables | 3/5 | Nature/IV/EV explicites si périmètre produit confirmé ; indépendance de difficulté AI. | Bornes, preview et calcul réels, override individuel, export et transports. Ne pas inventer une exigence bêta HGSS. |
| 25 | L22 — Capacité de sac | 3/5 | D'abord choisir slots/poche/quantité/poids ou conserver l'illimité. | Fusion de pile, ajout nouvelle entrée, cadeau réessayable, UI, sauvegarde ; scénarios limites sans utiliser l'overflow machine comme capacité de gameplay. |

### Niveau 4 — Mouvements, récupération et preuves complètes

| Ordre | Lot | Difficulté | Travail précis | Critère de sortie et dépendance |
|---:|---|---:|---|---|
| 26 | L23 — Saut cinématique | 4/5 | Étape typée avec arc/durée/réception, joueur et PNJ. | Sur place/déplacement, réception bloquée, rollback et preview/runtime/transports ; réutiliser physique existante, dépend des règles de pose L10b. |
| 27 | L24 — WhiteOut de Scene | 4/5 | Appeler l'autorité de recovery existante depuis une commande sémantique. | Défaite réelle, HP/PP/argent/point de reprise/warp/checkpoint cohérents ; échec warp et reload ; aucun passage à la branche victoire. |
| 28 | L25 — Props physiques autonomes | 4/5 | D'abord prop unique sur rail sans rider, puis groupe synchronisé et état ouvert/fermé. | Collisions pendant trajet, occupation, entrée verrouillée, attente de fin, interruption/rollback, pose durable et reprise ; préserver plateformes porteuses. |
| 29 | L26a — Glissade joueur | 4/5 | Consommer slide avec mouvement continu déterministe. | Arrêt obstacle/sortie, input verrouillé puis rendu, warps/triggers, sauvegarde et puzzle réel. Ne pas compter un DTO comme livraison. |
| 30 | L26b — Blocs de glace | 4/5 | Trajectoire jusqu'à obstacle et état des blocs. | Réservations/collisions, position finale/reload, puzzle source ; réutiliser l'autorité des obstacles mobiles, partager les primitives de trajectoire L26a/L25 seulement si la conception le justifie. Pas de dépendance au chantier complet de props, ni mécanique nouvelle dans Flame. |
| 31 | L27 — Tourbillon terrain | 4/5 | FieldAbility, cible/obstacle, prérequis badge/move/Surf et franchissement. | Refus sans prérequis puis traversée réelle, entrée/sortie Surf, persistance et authoring/MCP ; s'appuyer sur les gates terrain existants. L11 seulement pour une branche Scene si nécessaire, aucune téléportation de remplacement. |
| 32 | L28 — Interaction fine résiduelle | 4/5 conditionnel | Reproduire d'abord un cas prop/event/comptoir restant ; compléter l'autorité concernée. | Rouge réel à position fine, obstacle/portée/priorité/présence, save/reload. Sans cas rouge, ne pas lancer une refonte générale. |
| 33 | L29 — Certification EventV2 restante | 4/5 transversal | Même fixture, actions précises et transports encore sans preuve, notamment batch Éditeur. | API/JSONL/Éditeur/MCP même résultat et refus ; N/A argumenté si aucune surface produit Éditeur pertinente, sans inventer un écran pour remplir une matrice. Documenter différés explicites. Chaque lot précédent apporte sa propre preuve ; pas de gate bêta nouvelle. |

### Niveau 5 — Architecture et extensions

| Ordre | Lot | Difficulté | Travail précis | Critère de sortie et dépendance |
|---:|---|---:|---|---|
| 34 | L30 — Parallélisme cinématique | 5/5 | Scheduler, groupes temporels et ownership acteur/caméra ; contrats d'attente. | Actions simultanées prouvées, conflits refusés, dialogue/audio, pause/seek, annulation atomique, preview/runtime cohérents. L10 doit être stabilisé avant. |
| 35 | L31a–d — Grands projets | 5/5 pour l'ensemble | a : mesure fraîche export/startup/RAM ; b : manifeste léger/index versionné ; c : résolution dépendances et cache borné/déchargement ; d : Studio/export/inspection et qualification iPhone. | Un seul .avelunegame, intégrité/quota par bloc et budget global, adjacent/preload raisonnable, aucune ressource manquante, progression/saves inchangées après unload/reload. Ne pas concaténer tous les blocs au lancement. Si L31a révèle un défaut plus simple, livrer ce correctif avant d'imposer l'architecture. |
| 36 | L32 — Doubles/multi | 5/5 optionnel | Nouvelle topologie de combat, targeting, UI, AI, remplacements et effets de zone. | Véritables combats multi-actifs et preuve Player ; aucune dépendance de la réserve singles ni de la réparation Johto actuelle. Décision produit préalable. |

Il y a 32 identifiants de lots de travail L01–L32, plus L00 de qualification. Certains sont découpés en sous-livraisons explicites ; les 36 rangs ci-dessus ne sont pas 36 tickets créés. Seul le ticket d'audit a été créé. Les dépendances doivent primer sur un simple tri numérique.

### Ordre opérationnel conseillé

Commencer par L01/L02, puis L04/L05/L06/L07 et les surfaces manquantes L08/L09/L20. Ces lots réduisent les faux diagnostics et le coût d'authoring tout en réparant des défauts isolables. Pour le scénario, enchaîner L10/L11/L12/L24 selon l'événement à débloquer. Pour Acajou/Souterrain, traiter les contrats physiques L25/L26 séparément.

L31 mérite un diagnostic très tôt si la livraison iPhone bloque réellement, même si son architecture est la plus difficile. L32 reste hors chemin critique. Ce classement est par complexité ; il ne masque pas un bloqueur de livraison derrière une liste de petites tâches.

## 6. Vérifications fraîches et limites

Les tests relancés sont existants. Aucun test nouveau n'a été écrit dans cet audit sans changement de comportement. Les totaux ci-dessous sont par commande ; ne pas additionner des suites qui peuvent se recouvrir pour prétendre une couverture globale.

### T01 — Core : typage, badge, cadeau réessayable

Depuis packages/map_core :

~~~sh
dart test test/narrative_event_builder_project_read_model_test.dart test/scene_badge_condition_test.dart test/scene_item_gift_retry_test.dart --reporter expanded
~~~

Résultat : 25 tests, All tests passed!, exit 0 ; 1,654 s.
Runner 17652, compilateur descendant 17714 ; zéro survivant confirmé, aucun signal.

### T02 — Gameplay : cadeau, badge, Borders et interaction pixel

Depuis packages/map_gameplay :

~~~sh
dart test test/scene_item_gift_test.dart test/scene_badge_condition_evaluator_test.dart test/materialized_border_collision_test.dart test/npc_pixel_interaction_test.dart --reporter expanded
~~~

Résultat : 29 tests, All tests passed!, exit 0 ; 3,789 s.
Runner 17812, descendant 17856 ; zéro survivant confirmé, aucun signal.

### T03 — Battle : météo, talents, baies, objets et AI

Depuis packages/map_battle :

~~~sh
dart test test/psdk_weather_terrain_test.dart test/psdk_ability_effects_test.dart test/psdk_item_berries_test.dart test/psdk_battle_item_action_test.dart test/psdk_ai_move_scoring_test.dart --reporter expanded
~~~

Résultat : 238 tests passés, exit 0 ; 4,880 s.
Runner 15191, descendant 15243 ; tous absents après le run, aucun kill.
Limite : durée/application météo, pas le reproducer Sandstorm résiduel spécifique.

### T04 — Projector et familles de statuts

Depuis packages/map_battle :

~~~sh
dart test test/canonical_psdk_move_projector_test.dart test/psdk_move_families/generic_status_stat_test.dart test/psdk_move_families/special_secondary_moves_test.dart --reporter expanded
~~~

Résultat : 108 tests passés, exit 0 ; 2,412 s.
Runner 18281, descendants 18304/18319/18339 ; aucun survivant.
Limite : bons alias et volatiles conservés, statuts inconnus ignorés, validation des chances reconnues ; pas combat Player lisant les huit définitions Johto.

### T05 — Sac, obstacles terrain et DTO de mouvement

Depuis packages/map_gameplay :

~~~sh
dart test test/bag_operations_test.dart test/field_obstacle_action_test.dart test/gameplay_movement_effect_test.dart test/item_capability_matrix_test.dart --reporter expanded
~~~

Résultat : 63 tests passés, exit 0 ; 2,188 s.
Runner 18393, descendant 18457 ; aucun survivant.
Limite : tests slide de donnée/validation, pas glissade physique.

### T06 — Core : orientation, émotes et cadeau catalogue

Depuis packages/map_core :

~~~sh
dart test test/scene_player_facing_condition_test.dart test/cinematic_emote_catalog_test.dart test/scene_catalog_pokemon_gift_test.dart --reporter expanded
~~~

Résultat : 25/25, exit 0.
Runner 27181, descendant 27257 ; zéro survivant.

### T07 — Gameplay : orientation et routes d'acteurs

Depuis packages/map_gameplay :

~~~sh
dart test test/scene_player_facing_condition_evaluator_test.dart test/actor_route_facing_test.dart test/actor_route_motion_test.dart --reporter expanded
~~~

Résultat : 90/90, exit 0.
Runner 27329, descendant 27385 ; zéro survivant.

### T08 — Authoring : orientation et cadeaux par transports

Depuis packages/map_authoring :

~~~sh
dart test test/domains/narrative/scene_player_facing_transport_test.dart test/domains/narrative/scene_catalog_pokemon_gift_transport_test.dart test/domains/narrative/scene_interactive_pokemon_gift_transport_test.dart --reporter expanded
~~~

Résultat : 8/8, exit 0.
Runner 27459, descendant 27573 ; zéro survivant.
Aucun drift des SHA des modèles facing/émotes/gift et playable_map_game pendant cette sélection. Ce garde n'existe pas rétroactivement pour toutes les lectures de l'audit.

### T09 — Authoring : batch, typage, staging, recovery et retours compacts

Depuis packages/map_authoring :

~~~sh
dart test test/domains/narrative/event_record_batch_transport_test.dart test/domains/narrative/modern_narrative_authoring_test.dart test/transactions/transaction_staging_metadata_test.dart test/transactions/recovery_idempotence_test.dart test/api/resource_pack_compact_result_test.dart --reporter expanded
~~~

Résultat : 59 tests, All tests passed!, exit 0. Runner 17014, compilateur descendant 17066 ; tous deux sortis seuls et absents à la relecture finale. Inventaire confirmé par la passe de critique complémentaire.

### T10 — MCP : tests et échecs à conserver

Depuis tools/pokemap_mcp :

~~~sh
node --import tsx --test --test-concurrency=1 test/narrative_event_typed_stdio.test.ts test/game_export_server.test.ts test/pokemon_documents_delete.test.ts test/runtime_server.test.ts
~~~

Sélection typage EventV2, routage export, suppression/undo Pokémon et runtime server :
premier passage 9 tests, 7 passés et 2 échecs worker.timeout au démarrage de runtimeFixture, avant les assertions métier. Suite restée ouverte après ces échecs de setup ; terminaison SIGTERM du Node détenu après vérification PID/parent. Ne pas déclarer cette sélection intégralement verte.

Reprise isolée :

~~~sh
node --import tsx --test --test-force-exit --test-name-pattern='failed playtest jobs can be retried|Pokemon preflight failure' test/runtime_server.test.ts
~~~

Résultat : 2 passés, 0 échec, exit 0 ; 21,961 s.
Flakiness de démarrage plausible ; cause de charge/CPU non mesurée. Le rendu MCP réussi de cette sélection ne démontre pas la correction de l'incident render.worker_failed historique.
Tests concernés : « failed playtest jobs can be retried as a new traced attempt » et « Pokemon preflight failure never creates a runtime executor », runtime_server.test.ts:135. Node détenu 19876, parent 18375 : SIGTERM après revalidation d'identité et parent ; descendants du harness déjà absents à la relecture finale. Le rendu réel a lancé indirectement un runner Flutter 20674, son compilateur 20985 et flutter_tester 21537 : tous suivis et absents à la relecture finale. Aucun processus de session concurrente arrêté.

### Build et analyse

- tools/pokemap_mcp : npm run check, exit 0.
- Compilation TypeScript : ./node_modules/.bin/tsc -p tsconfig.json --outDir <répertoire temporaire hors dépôt>, exit 0 ; 125 JS comparés au dist présent, 125 identiques, aucun différent/manquant. Aucun dist écrasé. Le chemin éphémère a été supprimé, pas d'artefact livrable conservé pour ce build de vérification.
- Aucun build Flutter installé, aucun build iOS, aucun dart analyze global, aucune suite complète du monorepo : audit sans modification produit et checkout partagé ; alternative retenue = compilation TS et suites ciblées ci-dessus.
- Aucun flutter test lancé directement pour les suites applicatives. T10 a lancé indirectement le worker de rendu Flutter tool/pokemap_render_worker_test.dart ; runner 20674, compilateur 20985 et flutter_tester 21537 suivis, tous absents à la vérification finale. Ce rendu réel ne qualifie pas une partie du Player ni les captures PNJ de F32.
- git diff --check : exit 0 avant rédaction du rapport.
- Plusieurs recherches ont utilisé d'anciens chemins déplacés et ont échoué ; elles ont été reprises par découverte rg --files et chemins actuels. Ces erreurs de recherche ne sont pas des tests produit rouges.
- bash tools/scripts/check_markdown_hygiene.sh : exit 1, « Markdown hygiene: 1 new Markdown files exceed the default limit of 0. » Le seul nouveau Markdown est ce rapport d'audit explicitement demandé, en emplacement canonique ; aucun override POKEMAP_MARKDOWN_MAX_NEW utilisé. Échec réel du contrôle de budget documentaire, pas erreur de source ou test ignoré.

## 7. Revue indépendante, changements et critique

### Verdicts des passes

| Passe | Verdict et limite |
|---|---|
| Audit / Architecture | Chaînes réelles inspectées ; anciens constats corrigés lorsque le contrat a évolué. Plusieurs manques confirmés par authoring + runtime, pas par enum seule. |
| Implémentation — faisabilité uniquement | Lots proposés autour des autorités existantes ; aucune implémentation effectuée. Séparer pose/parallélisme, cadeaux acquis/moves spéciaux, plateforme/prop autonome, réserve/doubles. |
| Tests | Sélections ciblées vertes côté Dart ; échecs MCP initiaux et reprise conservés. Aucune certification Player ni reproduction fraîche de tous les défauts. |
| Build / Validation | TS vérifié sans écraser dist, catalogue connecté lu ; certification globale des transports toujours incomplète. |
| Critique finale | Trois revues favorables après corrections : portée API/JSONL vs quatre transports ; dépendances facultatives cadeaux/glace/Tourbillon ; scope session/projet des projections ; N/A Éditeur motivé ; présence indirecte du worker Flutter et traçabilité. Aucun blocage technique de remise de l'audit restant. L'échec du budget documentaire reste déclaré. |

### Fichiers modifiés par cet audit

Un seul livrable technique : documentation/reports/gameplay/johto_capability_audit_lots_20261018.md.

Zones créées : synthèse/périmètre ; matrice des 51 entrées ; causes/sources ; lots ordonnés et critères ; commandes/résultats ; critique et inventaire Git. Raison : rendre la demande d'audit complète, traçable et révisable. Impact produit attendu : aucun comportement modifié. Aucun fichier source/test/config/projet édité par cette tâche.

Écritures Notion : un ticket d'audit dans la famille Monde & narration Post Bêta, sans création d'une série de tickets de bug ni de contenu. Son passage final est TO REVIEW, jamais DONE. Les autres tickets et leurs critères restent inchangés.

### Auto-critique

La couverture des 51 entrées ne signifie pas exécution de 51 reproductions. Les constats statiques Sniper/Sandstorm/WorldRule, les incidents historiques et les performances iPhone demandent leurs propres tests de sortie. Les tests verts déjà présents peuvent précisément manquer le comportement défectueux : météo sans dégâts, slide sans mouvement, projection qui ignore les inconnus.

Les niveaux de difficulté combinent surface de changement, transactions/persistance, nombre de consommateurs et coût de preuve. Ils restent des jugements d'ingénierie ; la séquence doit être affinée à chaque lot contre le checkout courant et les décisions produit. Les capacités 3D non annoncées ne doivent pas agrandir silencieusement un objectif Johto 2D.

Les sources concurrentes n'ont pas toutes été empreintées avant la première lecture. Même un HEAD stable ne garantirait pas la stabilité des fichiers locaux. Les preuves nouvelles qualifient ce qu'elles ont compilé/exécuté, pas automatiquement une future application installée.

### Clôture documentaire

HEAD final observé : 222ed7a14ee7b8c525789be0e63ff3b2c6ef1df1 ; branche main ; 180 chemins modifiés/non suivis au relevé final. Comparaison des lignes de statut avec le snapshot initial : aucun chemin initial retiré, un seul ajouté, ce rapport. Les 179 changements préexistants sont conservés.

Un commit concurrent est apparu pendant l'audit : feat(converter): import qualified Essentials Pokemon gifts. La comparaison 491ef2ed..222ed7a14 porte seulement sur 12 fichiers dans packages/avelune_converter_adapters et packages/avelune_converter_core, sans fichier Core/Gameplay/Battle/Authoring/Runtime des constats. Il n'est pas issu de cet audit. Le nouveau HEAD n'exige pas de répéter les tests moteur sans nouvelle modification pertinente ; il ne dispense pas de vérifier les changements locaux lors de la prise de chaque lot.

git diff --check final : exit 0. Contrôle d'intégrité du rapport : 51 IDs F01–F51 uniques, aucun manquant, 36 rangs monotones regroupés sous L01–L32 ; tous les chemins complets de source cités vérifiés existants. Contrôle Markdown : exit 1 pour le budget zéro, un rapport explicitement demandé ; aucun seuil modifié. Le ticket Notion est passé TO REVIEW après réenregistrement et relecture des 51 IDs et du lot L32 ; aucun statut de mécanique ou bêta promu.

## Annexe A — Git initial complet

Commande : git status --short --untracked-files=all. Snapshot initial avant création de ce rapport.

~~~text
 M apps/avelune_converter/macos/Flutter/GeneratedPluginRegistrant.swift
 M apps/avelune_studio/lib/features/map_workspace/application/spatial_model_editing_commands.dart
 M apps/avelune_studio/lib/features/resources/data/border_resource_sources.dart
 M apps/avelune_studio/lib/features/resources/data/local_border_resource_adapter.dart
 M apps/avelune_studio/lib/features/resources/domain/resource_pack_port.dart
 M apps/avelune_studio/lib/features/resources/domain/resource_port.dart
 M apps/avelune_studio/lib/platform/playtest/studio_spatial_playtest.dart
 M apps/avelune_studio/lib/presentation/features/map_workspace/map_canvas_stroke.dart
 M apps/avelune_studio/lib/presentation/features/map_workspace/map_decor_animation_panel.dart
 M apps/avelune_studio/lib/presentation/features/map_workspace/map_decor_inspector_tabs.dart
 M apps/avelune_studio/lib/presentation/features/map_workspace/map_terrain_patterns.dart
 M apps/avelune_studio/lib/presentation/features/map_workspace/map_terrain_tool_panel.dart
 M apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_view_state.dart
 M apps/avelune_studio/lib/presentation/features/map_workspace/spatial_ramp_editor.dart
 M apps/avelune_studio/lib/presentation/features/resources/border_creation_dialog.dart
 M apps/avelune_studio/lib/presentation/features/resources/border_pattern_panel.dart
 M apps/avelune_studio/lib/presentation/features/resources/model_collision_controls.dart
 M apps/avelune_studio/lib/presentation/features/resources/model_resource_library.dart
 M apps/avelune_studio/lib/presentation/features/resources/resource_catalog.dart
 M apps/avelune_studio/lib/presentation/features/resources/resource_detail_panel.dart
 M apps/avelune_studio/lib/presentation/features/resources/resource_library_bindings.dart
 M apps/avelune_studio/test/map_workspace/border_drawing_host_test.dart
 M apps/avelune_studio/test/map_workspace/map_decor_animation_panel_test.dart
 M apps/avelune_studio/test/presentation/map_canvas_patterns_test.dart
 M apps/avelune_studio/test/presentation/model_collision_controls_test.dart
 M apps/avelune_studio/test/presentation/resource_detail_ui03_test.dart
 M apps/avelune_studio/test/presentation/resource_family_catalog_test.dart
 M apps/avelune_studio/test/presentation/spatial_ramp_editor_test.dart
 M apps/avelune_studio/test/resource_io/resource_library_host_test.dart
 M apps/avelune_studio/test/support/border_catalog_fixture.dart
 M apps/avelune_studio/test/support/spatial_ramp_fixture.dart
 M apps/avelune_studio/test/terrains/terrain_brush_tall_grass_test.dart
 M apps/pokemap_hub/lib/core/config/avelune_host_compatibility.dart
 M apps/pokemap_hub/test/platform/avelune_host_compatibility_test.dart
 M packages/map_authoring/lib/src/api/local_resource_pack_transfer_api.dart
 M packages/map_authoring/lib/src/domains/assets/model3d_actions.dart
 M packages/map_authoring/lib/src/domains/assets/resource_library_actions.dart
 M packages/map_authoring/lib/src/domains/distribution/game_package_export_service.dart
 M packages/map_authoring/lib/src/domains/maps/border_actions.dart
 M packages/map_authoring/lib/src/domains/maps/border_catalog_actions.dart
 M packages/map_authoring/lib/src/domains/maps/smart_tile_catalog_actions.dart
 M packages/map_authoring/lib/src/domains/maps/smart_tile_catalog_support.dart
 M packages/map_authoring/lib/src/domains/maps/smart_tile_pattern_actions.dart
 M packages/map_authoring/lib/src/domains/maps/spatial_map_actions.dart
 M packages/map_authoring/lib/src/editing/environment_generation_support.dart
 M packages/map_authoring/lib/src/editing/environment_placement_editing.dart
 M packages/map_authoring/lib/src/parity/full_authoring_parity.dart
 M packages/map_authoring/lib/src/references/resource_library_scope_guard.dart
 M packages/map_authoring/lib/src/registry/resource_kind_registry.dart
 M packages/map_authoring/lib/src/transactions/recovery_service.dart
 M packages/map_authoring/test/application/resource_pack_selection_test.dart
 M packages/map_authoring/test/domains/assets/model3d_actions_test.dart
 M packages/map_authoring/test/domains/assets/model3d_import_batch_test.dart
 M packages/map_authoring/test/domains/assets/resource_library_actions_test.dart
 M packages/map_authoring/test/domains/assets/resource_pack_reimport_test.dart
 M packages/map_authoring/test/domains/maps/border_catalog_actions_test.dart
 M packages/map_authoring/test/domains/maps/environment_spatial_actions_test.dart
 M packages/map_authoring/test/domains/maps/smart_tile_cell_actions_test.dart
 M packages/map_authoring/test/parity/full_authoring_parity_test.dart
 M packages/map_authoring/test/tooling/jsonl_border_catalog_flow_test.dart
 M packages/map_authoring/test/tooling/jsonl_border_spatial_behavior_test.dart
 M packages/map_authoring/test/tooling/jsonl_resource_library_flow_test.dart
 M packages/map_authoring/test/tooling/jsonl_smart_tile_native_flow_test.dart
 M packages/map_authoring/test/transactions/recovery_idempotence_test.dart
 M packages/map_core/lib/map_core_domain.dart
 M packages/map_core/lib/src/models/border_blueprint.dart
 M packages/map_core/lib/src/models/border_catalog.dart
 M packages/map_core/lib/src/models/map_spatial_scene.dart
 M packages/map_core/lib/src/models/project_model3d.dart
 M packages/map_core/lib/src/models/resource_library_catalog.dart
 M packages/map_core/lib/src/models/resource_pack_catalog.dart
 M packages/map_core/lib/src/models/smart_tile.dart
 M packages/map_core/lib/src/models/smart_tile.freezed.dart
 M packages/map_core/lib/src/models/smart_tile.g.dart
 M packages/map_core/lib/src/models/spatial_navigation.dart
 M packages/map_core/lib/src/operations/border_blueprint_json_codec.dart
 M packages/map_core/lib/src/operations/border_canonical_gallery.dart
 M packages/map_core/lib/src/operations/border_format_version.dart
 M packages/map_core/lib/src/operations/border_override_resolution.dart
 M packages/map_core/lib/src/operations/border_publication_readiness.dart
 M packages/map_core/lib/src/operations/border_resolver.dart
 M packages/map_core/lib/src/operations/border_stroke_editing.dart
 M packages/map_core/lib/src/operations/border_template_capabilities.dart
 M packages/map_core/lib/src/operations/connected_line_border_resolver.dart
 M packages/map_core/lib/src/operations/project_border_catalog_json_codec.dart
 M packages/map_core/lib/src/operations/resource_pack_native_json.dart
 M packages/map_core/lib/src/operations/resource_pack_publication.dart
 M packages/map_core/lib/src/operations/smart_tile_catalog_validation.dart
 M packages/map_core/lib/src/operations/smart_tile_pattern_operations.dart
 M packages/map_core/lib/src/operations/spatial_border_resolution.dart
 M packages/map_core/lib/src/operations/spatial_map_operations.dart
 M packages/map_core/lib/src/operations/spatial_smart_tile_models.dart
 M packages/map_core/lib/src/operations/spatial_stair_attachment.dart
 M packages/map_core/lib/src/validation/validators.dart
 M packages/map_core/test/border/border_publication_readiness_test.dart
 M packages/map_core/test/border/border_slot_keys_test.dart
 M packages/map_core/test/border/connected_line_border_resolver_test.dart
 M packages/map_core/test/border/masonry_line_border_resolver_test.dart
 M packages/map_core/test/border/project_border_catalog_json_codec_test.dart
 M packages/map_core/test/project_model3d_test.dart
 M packages/map_core/test/resource_library_catalog_test.dart
 M packages/map_core/test/resource_pack_publication_test.dart
 M packages/map_core/test/smart_tiles/smart_tile_spatial_clip_test.dart
 M packages/map_core/test/spatial_stair_attachment_test.dart
 M packages/map_distribution/lib/src/game_package_project_validator.dart
 M packages/map_distribution/lib/src/resource_pack_inspector.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_render_3d/lib/src/glb_renderer_layout.dart
 M packages/map_render_3d/lib/src/model_byte_loader.dart
 M packages/map_render_3d/lib/src/spatial_ground.dart
 M packages/map_render_3d/lib/src/spatial_model_placement_preview.dart
 M packages/map_render_3d/lib/src/spatial_scene_view.dart
 M packages/map_render_3d/test/spatial_authoring_preview_test.dart
 M packages/map_render_3d/test/spatial_ground_test.dart
 M packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/lib/src/presentation/flame/smart_tile_actor_occlusion_component.dart
 M packages/map_runtime/lib/src/presentation/flame/smart_tile_animation_activation_controller.dart
 M packages/map_runtime/lib/src/spatial/spatial_exploration_session.dart
 M packages/map_runtime/lib/src/spatial/spatial_exploration_view.dart
 M packages/map_runtime/lib/src/spatial/spatial_smart_tile_animation_controller.dart
 M packages/map_runtime/test/playable_map_game_smart_tile_animation_activation_test.dart
 M packages/map_runtime/test/runtime_manifest_tilesets_smart_tile_test.dart
 M packages/map_runtime/test/smart_tile_animation_activation_controller_test.dart
 M packages/map_runtime/test/spatial_connection_session_test.dart
 M packages/map_runtime/test/spatial_smart_tile_animation_controller_test.dart
 M packages/map_runtime/test/support/spatial_smart_tile_fixture.dart
 M pokemap_authoring_api_mcp_action_catalog.md
 M tools/nb2_modular_assets/build_water_tiles.py
 M tools/nb2_modular_assets/extract_units.py
 M tools/nb2_modular_assets/test_extract_units.py
 M tools/pokemap_mcp/test/model3d_source_replace_stdio.test.ts
 M tools/pokemap_mcp/test/raster_spatial_height_stdio.test.ts
 M tools/pokemap_mcp/test/resource_library_stdio.test.ts
 M tools/pokemap_mcp/test/spatial_ramp_precision_stdio.test.ts
 M tools/scripts/convert_bw2_grass_reaction.py
 M tools/scripts/test_convert_bw2_grass_reaction.py
?? apps/avelune_studio/lib/features/resources/domain/border_sequence_primitives.dart
?? apps/avelune_studio/lib/presentation/features/resources/border_sequence_controls.dart
?? apps/avelune_studio/test/application/spatial_model_placement_defaults_test.dart
?? apps/avelune_studio/test/presentation/border_sequence_editor_test.dart
?? apps/avelune_studio/test/presentation/spatial_clipped_pattern_stroke_test.dart
?? apps/avelune_studio/test/presentation/spatial_fractional_ramp_editor_test.dart
?? apps/avelune_studio/test/resource_io/border_sequence_resource_test.dart
?? packages/map_authoring/lib/src/domains/maps/smart_tile_construction_contract.dart
?? packages/map_authoring/test/domains/assets/model3d_configure_batch_test.dart
?? packages/map_authoring/test/domains/assets/model3d_default_blocking_pack_test.dart
?? packages/map_authoring/test/domains/distribution/spatial_fractional_stair_export_test.dart
?? packages/map_authoring/test/domains/maps/border_spatial_sequence_actions_test.dart
?? packages/map_authoring/test/domains/maps/placed_element_animation_transport_test.dart
?? packages/map_authoring/test/domains/maps/spatial_fractional_ramp_actions_test.dart
?? packages/map_authoring/test/domains/maps/spatial_model_clip_actions_test.dart
?? packages/map_core/lib/src/models/smart_tile_pattern_construction.dart
?? packages/map_core/lib/src/operations/spatial_model_clip_capabilities.dart
?? packages/map_core/test/border/spatial_border_sequence_test.dart
?? packages/map_core/test/resource_pack_compact_catalog_test.dart
?? packages/map_core/test/smart_tiles/smart_tile_adaptive_construction_test.dart
?? packages/map_core/test/smart_tiles/smart_tile_pattern_clipping_policy_test.dart
?? packages/map_core/test/smart_tiles/spatial_model_clip_projection_test.dart
?? packages/map_core/test/spatial_fractional_ramps_test.dart
?? packages/map_distribution/test/game_package_model_clip_test.dart
?? packages/map_distribution/test/resource_pack_model_clip_capabilities_test.dart
?? packages/map_distribution/test/spatial_fractional_stairs_package_test.dart
?? packages/map_distribution/test/support/fractional_stair_fixture.dart
?? packages/map_render_3d/lib/src/spatial_clipped_model_cache.dart
?? packages/map_render_3d/lib/src/spatial_model_source_admission.dart
?? packages/map_render_3d/lib/src/spatial_model_source_clip.dart
?? packages/map_render_3d/lib/src/spatial_model_triangle_clip.dart
?? packages/map_render_3d/test/spatial_clipped_model_cache_test.dart
?? packages/map_render_3d/test/spatial_model_source_clip_test.dart
?? packages/map_render_3d/test/spatial_model_triangle_clip_test.dart
?? packages/map_runtime/test/frlg_tall_grass_graphic_contract_test.dart
?? tools/pokemap_mcp/test/border_native_connected_line_stdio.test.ts
?? tools/pokemap_mcp/test/border_spatial_sequence_stdio.test.ts
?? tools/pokemap_mcp/test/frlg_tall_grass_stdio.test.ts
?? tools/pokemap_mcp/test/model3d_clip_stdio.test.ts
?? tools/pokemap_mcp/test/model3d_configure_batch_stdio.test.ts
?? tools/pokemap_mcp/test/placed_element_idle_frame_stdio.test.ts
?? tools/pokemap_mcp/test/smart_tile_native_construction_stdio.test.ts
~~~

