# PokeMap solo — réaudit PSDK et roadmap fonctionnelle complète

Date de l'audit : 2026-08-25  
Rapport relu : `documentation/reports/gameplay/audit_parite_fonctionnelle_psdk_pokemap_2026-08-24.md`  
Révision PokeMap de fin de vérification : `2143385093b7458539c0621d5c8aa590b63dbec6`  
Référence PSDK locale : build `6711` (version décodée `26.55`), dépôt sans métadonnées Git exploitables  
Nature du document : audit de code, critique du rapport existant et roadmap technique de produit  
Statut : proposition hors Notion, sans création de ticket et sans modification du code produit

## 1. Verdict exécutif

Le rapport du 24 août est un bon audit documentaire et une mauvaise roadmap courante.

Il est bon parce qu'il cite ses sources, distingue plusieurs niveaux de preuve, ne transforme pas mécaniquement un fichier ou une classe en fonctionnalité jouable et reconnaît ses propres limites. Son inventaire PSDK reste utile, ses comptages sont reproductibles et sa prudence sur la parité de combat est saine.

Il n'est plus une bonne roadmap pour trois raisons :

1. une partie importante de ses manques est désormais explicitement hors produit ;
2. plusieurs capacités PokeMap ont progressé depuis son snapshot `6ee23f76904c...` ;
3. plusieurs statuts du roadmap racine sont plus anciens que le code qu'ils prétendent décrire.

La conclusion corrigée est la suivante :

> PokeMap possède déjà une tranche verticale solo crédible : nouvelle partie, starter, exploration multi-maps, narration, rencontres à pied et en Surf, combat simple, capture, progression, services, sauvegarde et packaging. Ce qui manque le plus n'est pas une seconde architecture, mais la fermeture des mécaniques encore nominales, la certification des transports et une preuve Player installée réellement conduite comme par un joueur.

Le prochain chantier ne doit donc pas être « refaire PSDK en Dart ». Il doit être :

```text
vérité de périmètre et réparations rouges
→ preuve Player et transports
→ terrains, pêche, Repel et field abilities
→ combat simple et progression certifiés
→ journal de quêtes et monde vivant
→ corpus, authoring avancé et certification finale
```

## 2. Contrat produit retenu

### 2.1 Cible incluse

La cible est un fangame Pokémon solo, orienté aventure scénarisée, avec :

- nouvelle partie, titre, starter et identité joueur ;
- exploration de cartes, connexions, warps, terrains et obstacles ;
- dialogues, événements, Common Events, quêtes et progression narrative ;
- rencontres sauvages simples à pied, en Surf et à la pêche ;
- combats simples uniquement ;
- capture, fuite, changement, KO et remplacement forcé ;
- XP, niveaux, apprentissage de capacités, évolution et amitié utile au gameplay ;
- équipe, PC, sac, objets, boutiques, soin et argent ;
- dresseurs, rivaux, champions, récompenses et badges ;
- Pokédex, carte du monde, voyage rapide et services Pokémon locaux ;
- sauvegarde, reprise, défaite de type whiteout et fin de scénario avec crédits ;
- cycle jour/nuit déterministe, météo overworld et follower Pokémon cosmétique ;
- authoring no-code, validation, import/export PokeMap et transports canoniques.

### 2.2 Hors périmètre ferme

Les fonctionnalités suivantes sont classées `OUT OF SCOPE`. Elles ne comptent ni comme manque, ni comme dette de parité, ni comme critère de sortie :

- combats doubles, triples et hordes ;
- concours et mini-jeux ;
- plantation et croissance des baies ;
- pension, daycare multiples, reproduction, compatibilité de reproduction, héritages et œufs ;
- Safari ;
- Nuzlocke ;
- Hall of Fame ;
- Voltorb Flip, Ruins of Alph puzzle et machines à sous ;
- phases lunaires et reproduction de l'horloge RSE ;
- réseau, multijoueur et services online ;
- système public de plugins pour le moment ;
- Headbutt ;
- rencontres Rock Smash ;
- Pokémon errants ;
- historique et chaînes de rencontres ;
- shiny, Shiny Charm et chaîne de pêche shiny ;
- Pokerus.

La répétition de Nuzlocke dans la demande est interprétée comme une confirmation, pas comme la volonté d'en supprimer deux fois le code avec davantage d'enthousiasme.

### 2.3 Interprétations nécessaires

| Sujet ambigu | Décision de périmètre |
|---|---|
| Pêche | La pêche simple avec trois cannes reste incluse ; seules les chaînes shiny sont exclues. |
| Rock Smash | L'obstacle destructible peut rester une field ability ; les rencontres déclenchées par Rock Smash sont exclues. |
| Jour/nuit | Un cycle simple et déterministe reste inclus ; phases lunaires et simulation fidèle de l'horloge RSE sont exclues. |
| Météo | La météo overworld reste incluse, sans dépendance à l'heure réelle de la machine. |
| Fin de jeu | Une fin de scénario et des crédits restent inclus ; le Hall of Fame est exclu. |
| Échanges | Un échange scénarisé avec un PNJ local reste possible ; tout échange réseau est exclu. |
| Followers | Un follower Pokémon purement solo et cosmétique reste une cible tardive. |
| Plugins | Les registres internes typés restent permis ; aucune API d'extension publique ou compatibilité de plugins n'est planifiée. |

## 3. Avis détaillé sur le rapport du 24 août

### 3.1 Ce qu'il fait bien

- Il définit une taxonomie explicite : présent, partiel, manquant, non certifié et hors scope.
- Il sépare correctement les modèles, l'authoring, le runtime et la preuve Player dans ses meilleures sections.
- Il évite de confondre un nombre de fichiers avec une couverture fonctionnelle.
- Il ancre ses comptages PSDK : 1 518 fichiers Ruby, 29 fichiers `MoveAnimation`, 18 enregistrements spécifiques, 316 enregistrements de mécaniques de moves, 271 abilities, 176 items, 100/50/45 Common Events, 874 animations, 2 249 timings et 482 événements de maps.
- Il dit honnêtement que les tests ciblés, les goldens et les seams de debug ne valent pas validation humaine installée.
- Il conserve la différence essentielle entre « modèle présent » et « fonctionnalité consommée par le Player ».

Un replay automatisé a résolu les 212 occurrences de références `chemin:ligne` vérifiées par le validateur du rapport, sans fichier absent ni ligne hors limites. Un second parseur plus strict a trouvé 211 jetons distincts, eux aussi valides. La différence vient du mode de tokenisation, pas d'une référence cassée.

### 3.2 Ce qu'il faut corriger

| Point du rapport historique | Correction 2026-08-25 |
|---|---|
| Les doubles sont une priorité | Ils sont hors scope et déjà désactivés par le profil canonique. |
| L'élevage et les œufs sont une priorité | Ils sont hors scope ; seules quelques métadonnées résiduelles restent à nettoyer ou à reloger. |
| Les baies à cultiver, concours, Safari, Nuzlocke et mini-jeux sont des manques | Ils sont hors produit et sortent du dénominateur de parité. |
| Shiny est une capacité à compléter | Shiny est déjà partiellement implémenté ; la décision correcte est de le retirer proprement si l'exclusion est ferme. |
| Headbutt et rencontres Rock Smash sont des chantiers | Headbutt sort du contrat ; Rock Smash ne reste que comme obstacle éventuel. |
| Le shell Player est essentiellement absent | Titre, Nouveau jeu, Continue, Options, chargement et crédits ont désormais des surfaces et tests ciblés. |
| Les cris n'ont pas de consommateur runtime | Le runtime appelle désormais `playCry`, avec test d'ordre d'introduction. |
| Les transitions de combat sont à peine configurables | Quinze transitions sont authorables ; la validation installée reste néanmoins incomplète. |
| Les FG-010–016 et FG-140–143 sont `TODO` | Le code fournit déjà une partie substantielle de ces lots ; ils nécessitent un réaudit de statut. |
| Les transports Items sont absents | Les actions existent sur plusieurs transports ; ce sont les receipts globaux injectés et la certification complète qui manquent. |

### 3.3 Verdict documentaire

| Axe | Verdict |
|---|---|
| Qualité des sources | `PASS` |
| Reproductibilité de l'inventaire PSDK | `PASS` |
| Prudence sur les faux positifs | `PASS` |
| Actualité de l'état PokeMap | `PARTIAL`, snapshot dépassé |
| Conformité au nouveau périmètre | `FAIL`, exclusions non appliquées |
| Utilisation comme roadmap courante | `FAIL` sans le présent delta |

Il faut donc conserver le rapport comme photographie historique, pas le réécrire comme s'il avait toujours connu le périmètre du 25 août.

## 4. Méthode et niveau de preuve

### 4.1 Snapshots

L'inspection a commencé sur `ff304411177b1df43179e2b6e704be1a7aead756`. Le checkout a avancé pendant l'audit via quatre commits concurrents :

- `de243e33e` — lecture audio de Presentation ;
- `e96a5ab81` — enregistrement de profil Presentation ;
- `69ca4059a` — lecture vidéo de Presentation ;
- `d33ebcdcc` — présentation visuelle de combat ;
- `214338509` — ordre de présentation du KO et du remplacement forcé.

Ces commits ne modifient pas les contrats de périmètre, d'authoring ou le roadmap cités dans ce document. La vérification finale a été refaite à `2143385093b7458539c0621d5c8aa590b63dbec6` ; le dernier commit renforce la présentation du remplacement forcé sans fermer à lui seul le lot de combat correspondant.

### 4.2 Grille de certification

Une fonctionnalité n'est considérée complète que si les six couches applicables sont démontrées :

| Couche | Question |
|---|---|
| A — Socle | Le contrat, les invariants, la sérialisation et la validation existent-ils ? |
| B — Authoring | Une opération canonique permet-elle de créer ou modifier la sémantique ? |
| C — Editor | Le parcours no-code est-il guidé, lisible et validé ? |
| D — Runtime | La mécanique est-elle réellement consommée et persistée ? |
| E — Player | Un joueur peut-il la déclencher et l'observer sans seam de debug ? |
| F — Transports | Direct API, JSONL/CLI, Editor et MCP prouvent-ils la même sémantique ? |

Légende : `DONE` = preuve fraîche et applicable ; `PARTIAL` = tranche réelle mais incomplète ; `NOMINAL` = vocabulaire ou surface sans consommation ; `MISSING` = absent ; `N/A` = couche non applicable. Les systèmes `OOS` sont exclus de cette matrice plutôt que déguisés en couches inapplicables.

## 5. État réel de PokeMap

### 5.1 Matrice fonctionnelle

| Système retenu | A | B | C | D | E | F | Verdict |
|---|---:|---:|---:|---:|---:|---:|---|
| Nouvelle partie / starter | DONE | DONE | DONE | DONE | PARTIAL | PARTIAL | Fonction réelle, parcours installé humain absent |
| Titre / Continue / Options / crédits | DONE | N/A | DONE | DONE | PARTIAL | N/A | Plus avancé que le rapport historique |
| Maps / warps / connections | DONE | DONE | DONE | DONE | PARTIAL | DONE | Solide, validation humaine à renouveler |
| Terrains riches | PARTIAL | PARTIAL | PARTIAL | NOMINAL | MISSING | PARTIAL | Le mouvement ne produit pas encore les effets attendus |
| Dialogues / événements / narration | DONE | DONE | DONE | DONE | PARTIAL | PARTIAL | Catalogue riche, receipts incomplets |
| Common Events | MISSING | MISSING | MISSING | MISSING | MISSING | MISSING | Aucun contrat de production canonique trouvé |
| Quêtes | PARTIAL | DONE | DONE | PARTIAL | MISSING | PARTIAL | Storylines oui, Quest Book joueur non |
| Rencontres walk / surf | DONE | DONE | DONE | DONE | PARTIAL | DONE | Tranche réelle |
| Pêche simple | NOMINAL | PARTIAL | PARTIAL | MISSING | MISSING | PARTIAL | Trois enums de cannes ne font toujours pas mordre un Magicarpe |
| Repel | PARTIAL | DONE | PARTIAL | MISSING | MISSING | PARTIAL | Authorable mais explicitement inerte |
| Rencontres statiques / cadeaux | DONE | DONE | DONE | DONE | PARTIAL | PARTIAL | Consommation et idempotence à certifier globalement |
| Field abilities | PARTIAL | PARTIAL | PARTIAL | PARTIAL | PARTIAL | PARTIAL | Surf seul est signé |
| Dresseurs / rivaux / rematch | DONE | DONE | DONE | DONE | PARTIAL | PARTIAL | Roadmap historique en retard sur le code |
| Party / PC | DONE | PARTIAL | PARTIAL | DONE | PARTIAL | PARTIAL | PC et Summary encore à fermer |
| Bag / items | DONE | DONE | DONE | DONE | PARTIAL | PARTIAL | Régression Golden Item actuelle |
| Shops / healing | DONE | DONE | DONE | DONE | PARTIAL | PARTIAL | Bon socle, preuve Player à consolider |
| Capture | DONE | DONE | DONE | DONE | PARTIAL | PARTIAL | E2E runtime fort, déclenchement debug dans la meilleure preuve |
| Combat simple | PARTIAL | PARTIAL | PARTIAL | DONE | PARTIAL | NOMINAL | Le runtime existe, la simulation n'est pas une action canonique enregistrée |
| Moves / statuts / abilities / held items | PARTIAL | PARTIAL | PARTIAL | PARTIAL | PARTIAL | PARTIAL | Large couverture, pas exhaustivité démontrée |
| IA de combat | PARTIAL | PARTIAL | PARTIAL | PARTIAL | PARTIAL | NOMINAL | Profils et scores existent, cible fermée à définir |
| XP / niveau / évolution / move learning | DONE | PARTIAL | DONE | DONE | PARTIAL | NOMINAL | Exécution réelle, transports de progression non certifiés |
| Argent / récompenses / badges | DONE | DONE | DONE | DONE | PARTIAL | PARTIAL | Régression Editor sur les items de récompense |
| Pokédex | DONE | DONE | DONE | DONE | PARTIAL | DONE | Projection inconnue/vue/capturée réelle |
| Carte du monde | DONE | DONE | DONE | DONE | PARTIAL | PARTIAL | Projection Player réelle et volontairement consultative |
| Voyage rapide / Fly | MISSING | MISSING | MISSING | MISSING | MISSING | MISSING | Graphe réutilisable, mais aucune commande de voyage |
| Sauvegarde / reprise / slots | DONE | N/A | N/A | PARTIAL | PARTIAL | N/A | Continue réel ; atomicité non uniforme selon le host |
| Whiteout / respawn | DONE | N/A | N/A | DONE | PARTIAL | N/A | Heal, perte d'argent, centre et checkpoint réels |
| Jour / nuit | MISSING | MISSING | MISSING | MISSING | MISSING | MISSING | À concevoir sans horloge machine |
| Météo overworld | PARTIAL | PARTIAL | DONE | MISSING | MISSING | PARTIAL | Métadonnée de map sans consommateur runtime |
| Follower Pokémon | MISSING | MISSING | MISSING | MISSING | MISSING | MISSING | Le test `followCharacter` concerne un PNJ leader |
| Packaging / readiness / export | DONE | DONE | DONE | DONE | PARTIAL | DONE | Pipeline fail-closed substantiel |

### 5.2 Capacités déjà solides

#### Nouvelle partie, shell et sauvegarde

- Le seed de nouvelle partie et le starter sont projetés par `packages/map_gameplay/lib/src/new_game_state_builder.dart:58-180`.
- L'orchestration Player vit dans `packages/map_runtime/lib/src/player/runtime_player_coordinator.dart:830-1023`.
- `campaign.new_game.update` est une action canonique dans `packages/map_authoring/lib/src/domains/gameplay/campaign_content_actions.dart:145-177`.
- Titre, Continue, Nouveau jeu, Options et crédits sont exercés dans `packages/map_player_ui/test/player/player_runtime_startup_shell_test.dart:290-375` et `:529-625`.
- `packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart:46-143` fournit une implémentation atomique, mais le host Player standalone actif passe encore par `StandalonePlayerSaveGateway.commit` dans `examples/playable_runtime_host/lib/src/runtime_startup_host.dart:396-409`. L'atomicité n'est donc pas prouvée uniformément pour tous les hosts.
- Les checkpoints et courses sauvegarde/Continue sont testés dans `packages/map_runtime/test/player/runtime_player_save_race_test.dart:10-146`.
- La défaite produit un whiteout complet dans `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:9598-9671`, validé par `packages/map_runtime/test/playable_map_game_whiteout_lite_test.dart:19-102`.

#### Narration et monde interactif

Le catalogue narratif expose 24 commandes dans `packages/map_core/lib/src/read_models/narrative_command_catalog.dart:3-29`, puis leurs contrats jusqu'à `:431`. Il couvre notamment dialogue, faits, étapes de scénario, items, argent, Pokémon, starter configuré, warp, boutique, soin, PC, combat de dresseur, rencontre statique, cinématique, heal, badge, field ability, fin de jeu, présence et déplacement de PNJ.

La faiblesse n'est pas l'absence de commandes. C'est l'absence d'une projection joueur de quêtes, d'un Common Event réutilisable assez typé et de receipts uniformes sur les quatre transports.

#### Dresseurs, combat et progression

- Équipe, difficulté, held item, ability, récompenses, dialogues et rematch sont portés par `packages/map_core/lib/src/models/project_trainer.dart:20-28` et `:81-191`.
- Le lifecycle one-shot/rematch est résolu dans `packages/map_runtime/lib/src/application/runtime_trainer_lifecycle_policy.dart:26-87`.
- Capture, party et sauvegarde traversent un E2E runtime dans `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart:810-963`, mais le combat y est ouvert par un seam debug.
- XP, argent, badge, field unlock et idempotence save/reload sont couverts dans `packages/map_runtime/test/playable_map_game_post_battle_progression_integration_test.dart:90-248`, avec le même type de limite.
- La vérité canonique du combat reconnaît elle-même ses axes partiels dans `packages/map_battle/lib/src/data/battle_parity_target.dart:75-183`.

#### Packaging

L'export `.avelunegame`, la validation fail-closed et la réouverture sont implémentés dans `packages/map_authoring/lib/src/domains/distribution/game_package_export_service.dart:88-153` et `:323-375`. La readiness vérifie notamment nouvelle partie, starter et fin atteignable dans `packages/map_authoring/lib/src/domains/distribution/game_package_gameplay_readiness_gate.dart:184-310`. JSONL et MCP exposent l'export via `packages/map_authoring/lib/src/tooling/jsonl_worker.dart:475-480` et `tools/pokemap_mcp/src/tools/game_export.ts:12-50`.

### 5.3 Manques fonctionnels confirmés

#### Terrains et navigation

Le socle sait nommer plusieurs comportements, mais `packages/map_gameplay/test/gameplay_movement_effect_test.dart:173-214` prouve encore que le pas de monde ne produit aucun `movementEffect`. Il manque un contrat sémantique complet pour glace, ledges, courants, escaliers, ponts et autres transitions de plan, puis sa consommation runtime.

#### Pêche

`EncounterKind` contient les trois cannes dans `packages/map_core/lib/src/models/enums.dart:388-406`, alors que `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:4753-4779` ne choisit que `walk` ou `surf`. Il manque l'action Player, le state machine lancer/attendre/mordre/échouer, la résolution d'une table adaptée, l'annulation et la persistance pertinente.

#### Repel

Le modèle et l'authoring existent, mais `packages/map_editor/test/item_effect_editor_unsupported_test.dart:8-17` et `:58-72` documentent explicitement que l'effet runtime n'est pas supporté.

#### Field abilities

`packages/map_gameplay/lib/src/field_action.dart:15-22` et `:69-105` montrent que Surf est la seule capacité signée ; Cut, Strength, Flash, Rock Smash obstacle, Waterfall et Dive renvoient encore `FieldActionUnsupported`. Fly n'appartient pas à cet enum : le voyage rapide nécessite un contrat séparé, aujourd'hui absent.

#### Quêtes

`StorylineAsset` et ses actions d'authoring sont riches, mais aucune projection Player ne forme un Quest Book avec états actif, terminé, échoué, objectifs et récompenses observables.

#### Carte du monde, météo, jour/nuit et follower

- La world map Player est volontairement lecture seule dans `packages/map_runtime/lib/src/player/runtime_player_pause_data_builder.dart:116-165`.
- `packages/map_core/lib/src/models/map_metadata.dart:27-74` porte une météo, sans consommateur `map_runtime`.
- Aucun système actif de time-of-day n'a été trouvé.
- `packages/map_runtime/test/playable_map_game_input_test.dart:642-708` fait suivre un PNJ leader par le joueur ; ce n'est pas un Pokémon follower.

### 5.4 Surfaces nominales et vérité transport

`packages/map_authoring/lib/src/domains/gameplay/battle_actions.dart:3-47` et `packages/map_authoring/lib/src/domains/gameplay/progression_actions.dart:3-63` décrivent des actions, mais `packages/map_authoring/test/domains/gameplay/battle_simulation_contract_test.dart:41-58` garantit que `battle.simulate` n'est pas enregistré dans le dispatcher canonique. Un descripteur n'est donc pas une capacité exécutable.

Le catalogue MCP live annonce :

- 336 actions de mutation ;
- 47 familles de ressources ;
- 82 ressources dans la synthèse de parité ;
- 86 actions avec au moins une preuve E2E ;
- 82 actions entièrement E2E selon les receipts injectés ;
- certification globale des transports incomplète ;
- certification Items incomplète.

Le script `tool/pmcp085_conformance.dart` retourne 254 actions incomplètes. Les neuf actions Items déclarent les transports CLI, Direct API, Editor et MCP mais n'ont aucun `endToEndVerifiedTransports` dans la projection live sans bundle de receipts. Le problème est donc la preuve globale et non l'inexistence des adaptateurs.

### 5.5 Résidus hors scope à traiter

Le profil canonique désactive déjà reproduction, combats doubles, gimmicks modernes et online dans `packages/map_core/lib/src/models/pokemon_ruleset_profile.dart:17`, `:70-75` et `:118-123`.

Il reste cependant des surfaces incohérentes avec le nouveau contrat :

| Résidu | État actuel | Décision recommandée |
|---|---|---|
| Shiny | Modèle de policy, générateur, contrôles Editor, données Trainer et surfaces Player existent | Retirer le contrat public, la génération et les contrôles si l'exclusion est définitive ; aucun bridge pré-1.0 |
| Headbutt | Enum et vocabulaire de table existent, sans déclencheur runtime | Supprimer de la sémantique d'encounter |
| Breeding metadata | `eggGroups`, `hatchCycles` et `genderRatio` cohabitent | Garder `genderRatio` dans une métadonnée d'espèce neutre ; retirer le reste si inutilisé |
| Rock Smash encounters | Pas de kind canonique complet | Ne jamais l'ajouter ; conserver seulement l'obstacle si souhaité |
| Doubles | Désactivés mais branches historiques peuvent subsister | Simplifier les chemins touchés vers le single, sans migration de compatibilité |
| Assets Voltorb | Occurrences d'animation de combat | Ne pas les confondre avec le mini-jeu Voltorb Flip |
| Berries | Objets et effets de combat | Conserver l'objet ; ne pas créer de plantation ni croissance |

Cette épuration est une rupture de schéma acceptable avant 1.0.0, mais elle n'est pas un gate de complétude du fangame solo : les fonctionnalités concernées sont déjà sorties du score et du chemin critique. Si Yoahn choisit ultérieurement de les enlever du produit plutôt que de les laisser dormantes, le nettoyage devra être un lot de maintenance séparé, explicite et non bloquant, avec rejet clair des anciennes données — pas une collection de fallbacks qui finirait par ressembler à un vide-grenier hanté.

## 6. Ce qu'il faut reprendre de PSDK

### 6.1 Principe

PSDK est l'oracle local pour décrire ce que fait PSDK : ordre de scène, choreography, feedback, conditions historiques et cas limites. Il ne décide pas automatiquement de la règle cible PokeMap. Le profil de génération PokeMap reste l'autorité pour les formules qui changent selon les générations, notamment critiques, speed ties, types, dégâts et apprentissages. PSDK ne doit devenir ni une dépendance, ni un format runtime, ni une architecture à translittérer.

À reprendre : invariants compatibles avec la génération cible, séquences, conditions, priorités, contrats UX et cas limites.  
À ne pas reprendre : Ruby dynamique, `send`, variables globales, singletons mutables, tags numériques magiques, bytecode RMXP, `Marshal`, XOR de sauvegarde, couplage à la frame et branches multi-combat hors scope.

Politique de source :

- `PokemonRulesetProfile` et le manifeste de génération PokeMap décident des règles mathématiques ;
- le Ruby PSDK décrit la référence PSDK et la choreography à comparer ;
- le projet PSDK exécutable confirme l'organisation et la provenance des assets ;
- toute divergence volontaire est écrite dans le manifeste de cible au lieu d'être maquillée en « parité ».

### 6.2 Inventaire de conversion priorisé

| Priorité | Domaine PSDK et sources | Sémantique à conserver | Conversion PokeMap |
|---|---|---|---|
| P0 | Terrain : `scripts/4 Systems/003 Map Engine/100 SystemTags.rb:11-53`, `:56-117`, `:122-143`, `:146-150` et `scripts/4 Systems/003 Map Engine/2 Logic/50 RMXP/405 Game_Player_passable.rb:52-95` | Taxonomie direction/ledge/eau/couche, puis décision de passabilité séparée | `map_core` pour `TerrainBehavior`, `map_gameplay` pour le reducer de mouvement, Editor guidé, runtime uniquement adaptateur visuel |
| P0 | Warps : `scripts/1 RMXP Scripts/028 Interpreter_5.rb:5-46`, `scripts/4 Systems/003 Map Engine/3 GamePlay/200 Scene_Map.rb:163-206` | Préconditions, destination, direction, transition et ordre de déclenchement | Commande `Warp`, validation graphe, transaction de navigation et rollback |
| P0 | Triggers : `scripts/4 Systems/003 Map Engine/2 Logic/50 RMXP/410 Game_Player_check_trigger.rb:5-60`, `:104-120` | Priorité action/touch/map, filtrage et anti-double déclenchement | Scheduler déterministe à identités stables |
| P0 | Interpréteur : `scripts/1 RMXP Scripts/024 Interpreter_1.rb:9-15`, `:45-52`, `:75-145` | File de commandes, attente, branchement et reprise | Hiérarchie scellée `EventCommand`, contexte immuable et résultats typés |
| P0 | Commandes : `scripts/1 RMXP Scripts/026 Interpreter_3.rb:4-60`, `:95-214`, `:216-294` et `scripts/1 RMXP Scripts/027 Interpreter_4.rb:3-178` | Dialogues, conditions, Common Events, switches, variables, mutations et contrôle de flux | `StoryPredicate` et commandes canoniques, sans `send` ni IDs opaques |
| P0 | Commandes monde : `scripts/1 RMXP Scripts/028 Interpreter_5.rb:48-194`, `:195-320`, `:321-385` | Déplacement, routes, attente, transitions, écran et audio | Effets publiés vers runtime, horloge testable et annulation explicite |
| P0 | Common Events : `scripts/1 RMXP Scripts/013 Game_CommonEvent.rb:23-67` | Ressource réutilisable, trigger, condition et exécution persistante | `CommonEventAsset` paramétré, action authoring et projection Player |
| P0 | Quêtes : `scripts/4 Systems/800 Quest/1 PFM/001 PFM Quests.rb:10-42`, `:59-72`, `:75-180`, `:237-320` | Activation, états, objectifs, récompenses et requêtes | Reducer de quête pur, événements de progression et read model |
| P0 | Objet de quête : `scripts/4 Systems/800 Quest/1 PFM/002 PFM Quests Quest.rb:11-35`, `:42-111`, `:125-135`, `:152-278`, `:318-360`, `:392-401` | Objectifs, récompenses, visibilité et hooks de vérification ; les getters PSDK peuvent muter l'état | Snapshot typé, commandes et receipts ; aucune mutation pendant une lecture |
| P0 | Save config : `scripts/4 Systems/106 Save Load/001 Configs.rb:3-29` et `scripts/4 Systems/106 Save Load/3 GamePlay/402 Save logic.rb:96-102` | Slots, header, clé, nom de fichier, versions et politique d'écrasement | Schéma PokeMap actuel uniquement, slots explicites et diagnostics |
| P0 | Save : `scripts/4 Systems/106 Save Load/3 GamePlay/402 Save logic.rb:3-35`, `:38-58`, `:60-85`, `:96-126` | Backup `.bak`, contrôle de réécriture, erreur et restauration ; PSDK écrit directement la destination | Cible PokeMap atomique : temporaire + checksum + rename + last-good ; jamais `Marshal` ou XOR |
| P1 | Party/PC : `scripts/4 Systems/000 General/3 GameState/201 Management.rb:63-109`, `:161-172` | Routage party/box, full/failure, retrait, échange et soin ; le transfert PSDK n'est pas atomique | Policy pure atomique, IDs stables, commande et receipt |
| P1 | Statut Pokémon : `scripts/4 Systems/000 General/1 PFM/2 Pokemon/800 Pokemon Status.rb:3-36` | Soin, statut, KO et cohérence | Transaction de soin partagée par Centre, item et whiteout |
| P1 | Storage : `scripts/4 Systems/200 Storage/1 PFM/001 Main.rb:7-16`, `:38-70`, `:121-154`, `:204-241` | Boîtes, capacité, déplacement et sélection | `map_gameplay` pour règles, Player UI pour navigation, persistance stable |
| P1 | Sac : `scripts/4 Systems/103 Bag/3 GamePlay/320 Bag_Choices.rb:25-111` | Capacités contextuelles et filtrage d'action | `ItemCapability`, disponibilité et raison d'indisponibilité |
| P1 | Boutique : `scripts/4 Systems/203 Shop/3 GamePlay/100 Shop.rb:23-40`, `:57-105` et `scripts/4 Systems/203 Shop/3 GamePlay/130 Shop_Actions.rb:5-42`, `:44-112` | Quote, quantité, argent, capacité et commit | `ShopQuote` → commande → receipt atomique |
| P1 | Rencontre : `scripts/4 Systems/999 Wild/100 Wild Battle (manager).rb:57-102`, `:169-217`, `:335-349` | Sélection, table, niveau, filtre et branches multi explicites à rejeter | Resolver pur à RNG injecté, verrouillé à zéro ou une rencontre ; aucune branche double, roaming, history ou shiny |
| P1 | Compteur : `scripts/4 Systems/999 Wild/102 Encounter Count.rb:12-68` | Pas avant nouvelle tentative et reset | État explicite dans la session, test déterministe |
| P1 | Dresseur : `scripts/2 PSDK Event Interpreter/100 Interpreter_Environnement.rb:9-68`, `:78-140` | Vision et détection ; guards Safari à ne pas importer | Lifecycle typé et choreography runtime |
| P1 | Séquences : `scripts/2 PSDK Event Interpreter/130 Interpreter_Sequences.rb:44-76`, `:165-199` | Approche, dialogue, pré-combat, défaite et reprise de map | Commande narrative + transaction d'outcome |
| P1 | Fin de combat : `scripts/5 Battle/04 Logic/1 Handlers/111 BattleEndHandler.rb:38-77`, `:123-181`, `:282-327` | Ordre des récompenses, callbacks et retour monde | Un seul `BattleOutcomeReceipt`, appliqué idempotemment |
| P1 | Scene battle : `scripts/5 Battle/04 Logic/0 Battle Info/001 Battle_Info.rb:59-81`, `:169-212` et `scripts/5 Battle/01 Scene/103 Scene Battle Phase.rb:34-49` | Participants, configuration, phase et transition | Contrat battle simple, sans `vs_type` 2/3 |
| P1 | Choix : `scripts/5 Battle/01 Scene/101 Scene Choice.rb:35-179`, `:234-290`, `:317-334` | Fight, Bag, Pokémon, Run et invalidations | Commandes typées et raisons UI, reducer pur |
| P1 | Actions : `scripts/5 Battle/04 Logic/102 Actions.rb:24-56`, `:91-112` | Priorité, ordre et validation | Queue d'actions déterministe et event log |
| P1 | Attaque : `scripts/5 Battle/05 Actions/002 Attack.rb:37-103`, `scripts/5 Battle/10 Move/120 Procedure.rb:35-137`, `:285-294`, `:476-487` et `scripts/5 Battle/10 Move/130 Move Prevention.rb:7-25` | Cible, PP, préventions, échecs et résolution | `BattleCommand` → événements, sans mutation UI |
| P1 | Item/Switch : `scripts/5 Battle/05 Actions/004 Item.rb:24-45`, `scripts/5 Battle/05 Actions/005 Switch.rb:22-60` et `scripts/5 Battle/01 Scene/101 Scene Choice.rb:135-150`, `:260-274` | Réservation/consommation, remboursement, invalidation et remplacement | Transaction unique avec sortie persistable |
| P1 | Dégâts : `scripts/5 Battle/10 Move/101 Damage_Calc.rb:3-67` | Ordre des modificateurs et arrondis de la génération PSDK, à comparer au profil PokeMap | Pipeline PokeMap nommé, tests de génération cible et traces explicatives |
| P1 | Effets : `scripts/5 Battle/10 Move/120 Procedure.rb:35-160`, `scripts/5 Battle/04 Logic/1 Handlers/103 StatusChangeHandler.rb:5-72`, `:105-125` | Déclencheurs, blocages, ordre et fin de tour | Registres typés, manifeste de couverture et événements |
| P1 | Abilities/items : `scripts/5 Battle/06 Effects/04 Ability Effects/001 AbilityBase.rb:14-45`, `scripts/5 Battle/06 Effects/05 Item Effects/001 ItemBase.rb:11-41`, `scripts/5 Battle/04 Logic/1 Handlers/106 EndTurnHandler.rb:13-24` | Hooks et ordre communs | Interfaces fermées et ordonnancement central, pas de plugin public |
| P1 | IA : `scripts/5 Battle/30 AI/100 Base.rb:16-59`, `:75-138`, `scripts/5 Battle/30 AI/101 MoveActionFor.rb:20-99`, `scripts/5 Battle/30 AI/200 GenericAI.rb:4-119` | Connaissance, candidats, score, risque et choix | Profils purs, RNG injecté et trace explicative testable |
| P1 | Capture : `scripts/5 Battle/04 Logic/1 Handlers/109 CatchHandler.rb:5-45`, `:47-149`, `:153-225` et `scripts/5 Battle/01 Scene/101 Scene Choice.rb:181-204`, `:317-334` | Calcul, shakes, réussite, destination party/PC et fin ; branche Nuzlocke exclue | Résultat typé puis transaction capture/party/PC/save |
| P1 | Progression : `scripts/5 Battle/04 Logic/1 Handlers/200 ExpHandler.rb:15-43`, `:53-123`, `scripts/5 Battle/01 Scene/0 BattleUI/050 ExpDistributionAbstraction.rb:52-80` et `scripts/5 Battle/04 Logic/1 Handlers/111 BattleEndHandler.rb:261-280` | Distribution XP, level-up, apprentissage et évolution post-combat | Un `ProgressionOutcome` idempotent par participant |
| P2 | Pêche : `scripts/4 Systems/999 Wild/100 Wild Battle (manager).rb:78-102`, `:256-277` et `scripts/4 Systems/003 Map Engine/2 Logic/50 RMXP/460 Game_Player_state.rb:165-205` | Canne, état, animation et table ; délais/bite/échec viennent des Common Events des cannes | State machine finie, sans historique ni chaîne shiny |
| P2 | Repel : `scripts/4 Systems/999 Wild/100 Wild Battle (manager).rb:337-349`, `scripts/4 Systems/999 Wild/101 Wild Battle (configuration).rb:43-57`, `:145-173`, `:208-217`, `scripts/4 Systems/000 General/3 GameState/200 Accessors.rb:50-66`, `:284-291`, `:394-405`, `scripts/4 Systems/003 Map Engine/2 Logic/101 EventTasks.rb:115` et `scripts/4 Systems/003 Map Engine/3 GamePlay/200 Scene_Map.rb:55-65` | Filtre de niveau, pas restants, cooldown et expiration | Effet d'item persistant, feedback et resolver pur |
| P2 | Field process : `scripts/4 Systems/000 General/1 PFM/1 Helpers/310 SkillProcess.rb:32-57` | Évaluer, confirmer, exécuter | Généraliser le pattern Surf existant |
| P2 | Passabilité : `scripts/4 Systems/003 Map Engine/2 Logic/50 RMXP/405 Game_Player_passable.rb:52-84` | Direction, terrain, véhicule et blocage | `FieldActionEvaluation` et `MovementDecision` purs |
| P2 | Pokédex : `scripts/4 Systems/101 Dex/001 Pokedex.rb:86-127`, `:208-255`, `:276-374` et `scripts/4 Systems/101 Dex/100 Dex.rb:94-200` | Seen/caught, formes et pages UX | Read model Player, sans shiny |
| P2 | World map : `scripts/4 Systems/206 TownMap/400 WorldMap.rb:287-300`, `:419-445`, `:548-566` et `scripts/4 Systems/202 Environment/120 Environnement.rb:80-99`, `:172-198` | Nœuds, découverte, sélection et voyage, sans roaming | Graphe validé, `FastTravelCommand` et confirmation |
| P2 | Options : `scripts/4 Systems/105 Options/1 PFM/500 Options.rb:7-60`, `:62-130`, `scripts/4 Systems/105 Options/3 GamePlay/048 KeyBinding.rb:4-14`, `:64-119`, `:141-202` et `scripts/4 Systems/105 Options/3 GamePlay/049 KeyBinding_LS.rb:55-70` | Valeurs, contraintes, persistance des options et des touches | Profil local versionné, remapping avec conflits guidés |
| P2 | Météo : `scripts/4 Systems/202 Environment/121 Weather.rb:3-41`, `:129-154` et `scripts/4 Systems/003 Map Engine/1 Graphics/200 Game_Screen.rb:63-100`, `:128-133` | Type, durée, projection en switches, transition et intensité graphique | `WorldWeatherState`, rendu runtime et predicates narratifs |
| P2 | Jour/nuit : `scripts/4 Systems/003 Map Engine/1 Graphics/353 DayNightTint.rb:96-108`, `:143-147`, `:227-309` | Segments et teinte, sans calendrier RSE ni `Time.new` machine | `WorldClock` déterministe, temps de projet injecté, aucun temps machine implicite |
| P3 | Follower : `scripts/4 Systems/003 Map Engine/2 Logic/01 FollowMe/300 Core.rb:29-52`, `:66-132`, `:194-252`, `:281-321` | File de positions, warp, masquage et reprise | Un follower cosmétique, sans combat ni encounter bonus |

### 6.3 Common Events PSDK à convertir en templates, pas en scripts

Le projet de démonstration PSDK fournit des Common Events significatifs pour Surf, Strength, Fly, Cut, Waterfall, Flash et Dive. Ils sont utiles pour reconstruire la séquence visible et les conditions, mais ne doivent pas être importés comme bytecode RMXP ni conserver leurs IDs numériques.

Racine de référence : `/Users/karim/Project/pokemonProject autre dossiers/pokémon_sdk_test_project`.

| Séquence | Référence exacte |
|---|---|
| Surf entrée | `Data/CommonEvents.rxdata.yml:2142-2310` |
| Surf sortie | `Data/CommonEvents.rxdata.yml:2311-2388` |
| Strength | `Data/CommonEvents.rxdata.yml:2533-2853`, orthographié `Strenght` dans la donnée PSDK |
| Fly | `Data/CommonEvents.rxdata.yml:3173-3231` |
| Cut | `Data/CommonEvents.rxdata.yml:5162-5332` |
| Old Rod | `Data/CommonEvents.rxdata.yml:5333-5441` |
| Good Rod | `Data/CommonEvents.rxdata.yml:5442-5550` |
| Super Rod | `Data/CommonEvents.rxdata.yml:5551-5659` |
| Waterfall | `Data/CommonEvents.rxdata.yml:6239-6546` |
| Flash | `Data/CommonEvents.rxdata.yml:6547-6660` |
| Dive | `Data/CommonEvents.rxdata.yml:6986-7267` |

La conversion cible est :

```text
Common Event PSDK
→ scénario comportemental documenté
→ commande et prédicats typés PokeMap
→ template no-code paramétrable
→ test de reducer
→ test runtime
→ receipt Player
```

## 7. Architecture cible

### 7.1 Flux canonique

```text
Editor / Direct API / JSONL / MCP
                │
                ▼
       map_authoring actions
                │
                ▼
      map_core contracts/data
          │              │
          ▼              ▼
 map_gameplay rules   map_battle rules
          │              │
          └──────┬───────┘
                 ▼
       map_runtime adapters
                 │
                 ▼
          map_player_ui
                 │
                 ▼
      installed human receipt
```

Une sémantique visible ne doit jamais apparaître uniquement dans l'Editor ou dans Flame. L'Editor produit un contrat canonique ; les packages purs décident ; le runtime adapte ; le Player présente.

### 7.2 Règles transverses

1. Un seul format canonique courant ; aucune lecture double ou migration pré-1.0 sans demande explicite.
2. RNG et horloges injectés partout où un test déterministe est attendu.
3. Commandes, événements et receipts ont des identités stables pour l'idempotence.
4. Les transactions combat, capture, progression et récompenses sont appliquées une seule fois.
5. Toute action no-code a des références guidées, des erreurs lisibles et un aperçu lorsque pertinent.
6. Toute action user-visible évalue la parité Direct API, JSONL, Editor et MCP.
7. Les registres de moves, abilities et items restent internes et typés ; ils ne deviennent pas une API de plugins.
8. Les fonctionnalités hors scope sont supprimées ou rejetées clairement, jamais laissées comme boutons fantômes.

## 8. Roadmap complète

Les identifiants `SOLO-*` ci-dessous sont des ancres de planification documentaire. Ils ne créent aucun ticket Notion, ne modifient pas le backlog bêta gelé et ne constituent pas un nouveau grand domaine.

### Phase 0 — vérité, scope et rouges actuels

Objectif : rendre les preuves fiables avant d'ajouter du produit.

| ID | Lot | Dépendances | Zones de départ | Critère de sortie |
|---|---|---|---|---|
| SOLO-000 | Figer le contrat solo et la lecture des surfaces OOS | Aucune | `pokemon_ruleset_profile.dart`, encounter enums, shiny policy, Editor encounter, species breeding metadata | Matrice incluse/OOS versionnée ; aucune fonctionnalité OOS ne compte comme manque, dépendance ou gate ; décision « dormant ou retrait » enregistrée séparément pour chaque surface existante |
| SOLO-001 | Réparer la compilation Golden Item | Aucune | `examples/playable_runtime_host/lib/src/golden_item_system_journey.dart`, `battle_start_request.dart` | `WildBattleStartRequest` utilise `encounterSourceId` et `encounterSourceKind` ; les deux tests host ciblés chargent et passent |
| SOLO-002 | Réparer les pickers Items du Trainer Studio | Aucune | Trainer Studio, repository de catalogues locaux, `trainer_library_panel_test.dart` | Held items et récompenses listent le catalogue attendu ; 17/17 tests ciblés verts |
| SOLO-003 | Réauditer les statuts FG devenus faux | SOLO-000, SOLO-001, SOLO-002 | `pokemap_roadmap_mecaniques_fangame.md` et preuves citées ici | Chaque lot concerné est classé TODO/PARTIAL/TO REVIEW proposé avec preuve fraîche ; aucun `DONE` automatique |
| SOLO-004 | Générer une matrice A–F vivante | SOLO-003 | `map_authoring` parity catalog, receipts, roadmap dashboard | Une entrée par capacité, SHA, fichier, commande et date ; aucun compteur de registration présenté comme E2E |
| SOLO-005 | Fermer le contrat de receipts transport | SOLO-004 | parity catalog, Direct API, JSONL, Editor, MCP | Chaque action applicable publie les quatre receipts ou une justification N/A ; conformance live verte |
| SOLO-006 | Produire le harness Player installé sans seam debug | SOLO-001, SOLO-004 | installed host, input driver, receipt validator | Parcours visible uniquement par inputs Player ; aucun `debugOpenBattleForTest`, mutation GameState ou receipt synthétique |

Vérification minimale :

```bash
cd examples/playable_runtime_host && flutter test test/golden_fangame_slice_e2e_test.dart test/golden_item_system_flow_test.dart
cd packages/map_editor && flutter test test/trainer_library_panel_test.dart
cd packages/map_authoring && dart test test/parity/full_authoring_parity_test.dart
cd tools/pokemap_mcp && npm run check && npm test
cd packages/map_authoring && dart run tool/pmcp085_conformance.dart
```

### Phase 1 — shell Player, sauvegarde et cycle de session

Objectif : certifier et finir le cycle démarrer → jouer → sauver → reprendre → perdre → continuer.

| ID | Lot | Dépendances | Zones de départ | Critère de sortie |
|---|---|---|---|---|
| SOLO-100 | Rebaseliner titre, Continue, Nouveau jeu, Options, crédits | SOLO-006 | `map_player_ui`, `runtime_startup_coordinator.dart` | Tous les états visibles, focusables, navigables clavier/manette et testés dans le Player installé |
| SOLO-101 | Certifier nouvelle partie et starter | SOLO-100 | `new_game_state_builder.dart`, coordinator Player, campaign actions | Seed, starter, map, position, identité et save initiale traversent A–F et un receipt Player |
| SOLO-102 | Fermer pause menu et routeur de détails | SOLO-100 | `runtime_player_detail_router.dart`, `map_player_ui` | Party, Bag, Dex, Map, profil et options ont retour, focus, empty/error states et persistance correcte |
| SOLO-103 | Fermer slots, Continue et last-good | SOLO-101 | save repository, save race tests, startup shell | Slots nommés, save atomique, corruption diagnostiquée, dernier état sain et aucune écriture concurrente perdue |
| SOLO-104 | Options audio, langue et remapping | SOLO-100 | options models, player shell, input mapping | Valeurs contraintes, conflits de touches expliqués, persistance locale et application immédiate |
| SOLO-105 | Certifier whiteout et checkpoint | SOLO-103 | `playable_map_game.dart`, whiteout tests | Heal, perte d'argent, retour centre, réapparition et save/reload sans double application |
| SOLO-106 | Gate de phase : export, installation et cycle de session | SOLO-101, SOLO-102, SOLO-103, SOLO-104, SOLO-105 | package export service, readiness gate, installed host | Tous les lots 100–105 sont verts ; archive fail-closed, réouverture, installation isolée, Nouvelle partie et Continue depuis le package |

### Phase 2 — monde, terrains et field abilities

Objectif : remplacer les vocabulaires nominaux par une exploration Pokémon complète et déterministe.

| ID | Lot | Dépendances | Zones de départ | Critère de sortie |
|---|---|---|---|---|
| SOLO-200 | Contrat sémantique de terrain | SOLO-000 | `map_core` terrain/tile metadata, validators | Chaque comportement possède paramètres, invariants, rendu attendu et erreur de validation ; aucun tag numérique PSDK |
| SOLO-201 | Reducer de mouvement riche | SOLO-200 | `map_gameplay` movement effects | Glace, ledge, courant/conveyor et blocage directionnel retournent des décisions pures testées |
| SOLO-202 | Escaliers, ponts et plans | SOLO-200 | collision/navigation contracts, runtime camera | Passage de plan, priorité visuelle, collision et sortie de zone cohérents dans les quatre directions |
| SOLO-203 | Connexions, warps et rollback | SOLO-200 | world graph, warp actions, runtime loader | Destination validée, direction, transition, échec atomique et rollback ; graphe inspectable MCP |
| SOLO-204 | Recertifier Surf | SOLO-201 | `field_action.dart`, runtime input, save | Evaluate → confirm → commit, mount/dismount, collision, rencontres Surf et save/reload Player |
| SOLO-205 | Généraliser le framework Field Action | SOLO-204 | field action contracts, badges/abilities | Une API evaluate/execute partagée avec raison d'indisponibilité, confirmation et receipt |
| SOLO-206 | Cut, Strength et Rock Smash obstacle | SOLO-205 | terrain behaviors, event commands, animations | Obstacles authorables, état consommé persistant, feedback Player ; aucune rencontre Rock Smash |
| SOLO-207 | Flash, Waterfall et Dive | SOLO-205 | map metadata, navigation, field gates | Conditions, transitions, rendering et retour sûrs ; save/reload au milieu de l'état valide |
| SOLO-208 | Fly, voyage rapide et gate d'exploration | SOLO-201, SOLO-202, SOLO-203, SOLO-205, SOLO-206, SOLO-207 | world graph, Player world map | Tous les lots 200–207 sont verts ; nœuds découverts, destination disponible, confirmation et warp atomique |

Vérification minimale : tests purs `map_core`/`map_gameplay`, widget tests Editor, tests input runtime, save/reload, action JSONL et MCP live par terrain/field ability.

### Phase 3 — rencontres sauvages simples

Objectif : un pipeline unique, single-only et sans fonctions exclues.

| ID | Lot | Dépendances | Zones de départ | Critère de sortie |
|---|---|---|---|---|
| SOLO-300 | Nettoyer le contrat Encounter | SOLO-000 | `EncounterKind`, tables, conditions, serializer | Kinds aléatoires retenus : walk, surf et old/good/super rod ; les statiques restent un contrat narratif séparé ; headbutt/shiny/roaming/multi absents |
| SOLO-301 | Recertifier walk et surf | SOLO-300, SOLO-204 | resolver gameplay, runtime steps | RNG injecté, cooldown, filtre terrain, niveau, zéro ou une rencontre, save/reload et Player receipt |
| SOLO-302 | Implémenter la pêche simple | SOLO-300 | rod item/use, Player input, encounter resolver | Equip/use canne, lancer, bite/échec, annulation, table par canne et combat simple ; aucune chaîne shiny |
| SOLO-303 | Implémenter Repel | SOLO-301 | item effects, save state, encounter resolver | Compteur de pas persistant, filtre niveau, expiration, feedback et renouvellement explicite |
| SOLO-304 | Fermer statiques et cadeaux | SOLO-300 | narrative commands, consumed IDs, party/PC | Précondition, déclenchement, capture/acceptation, destination et non-répétition après reload |
| SOLO-305 | Conditions d'environnement et gate encounters | SOLO-301, SOLO-302, SOLO-303, SOLO-304 | encounter conditions, clock/weather futures | Tous les lots 300–304 sont verts ; conditions typées map/terrain/time/weather sans scripts opaques, prévisualisées et explicables |

### Phase 4 — événements, Common Events et quêtes

Objectif : passer d'un catalogue riche à un système de scénario jouable et observable.

| ID | Lot | Dépendances | Zones de départ | Critère de sortie |
|---|---|---|---|---|
| SOLO-400 | Certifier les 24 commandes narratives | SOLO-005 | narrative catalog, dispatcher, Editor | Chaque commande a validation, preview ou feedback, runtime, persistance, Direct/JSONL/Editor/MCP |
| SOLO-401 | Créer `CommonEventAsset` typé | SOLO-400 | `map_core`, authoring narrative | Paramètres, conditions, trigger, appel imbriqué borné et identité stable ; aucun bytecode RMXP |
| SOLO-402 | Scheduler déterministe d'événements | SOLO-401 | runtime event queue, waits, map triggers | Ordre action/touch/map, waits, annulation, changement de map et reload sans double exécution |
| SOLO-403 | Reducer de quête | SOLO-400 | Storyline models, progression projection | États inactive/active/completed/failed, objectifs, visibilité et récompenses idempotentes |
| SOLO-404 | Quest Book Player | SOLO-403 | pause menu, player read models | Liste, détail, progression, objectifs masqués/révélés, empty/error states et notification non bloquante |
| SOLO-405 | Choreography PNJ | SOLO-402 | moveNpc, presence, character animation | Déplacement, regard, attente, collision, leader/follow sequence, warp et reprise déterministes |
| SOLO-406 | Fin de scénario, crédits et gate narrative | SOLO-400, SOLO-401, SOLO-402, SOLO-403, SOLO-404, SOLO-405 | finishGame, readiness gate, startup shell | Tous les lots 400–405 sont verts ; condition atteignable, sauvegarde finale, crédits et retour titre ; aucun Hall of Fame |

### Phase 5 — combat simple certifié

Objectif : fermer une cible explicite, pas poursuivre un mirage d'exhaustivité Pokémon indéfinie.

| ID | Lot | Dépendances | Zones de départ | Critère de sortie |
|---|---|---|---|---|
| SOLO-500 | Figer le manifeste de combat single | SOLO-000, SOLO-004 | `battle_parity_target.dart`, ruleset profile | Génération ciblée, règles, moves, statuts, abilities, items et IA listés avec statut et preuve ; aucune ligne doubles |
| SOLO-501 | Fermer ordre, priorité et arrondis | SOLO-500 | `map_battle` action queue/damage pipeline | Speed ties, priorité, accuracy, critique, STAB, types, modificateurs et arrondis couverts par tables de la génération PokeMap ; ordre de scène comparé séparément à PSDK |
| SOLO-502 | Switch, KO et remplacement forcé | SOLO-501 | battle commands, Player overlay | Switch volontaire, Pursuit-like si retenu, KO, remplacement forcé, team wipe et invalidations sans deadlock UI |
| SOLO-503 | Fermer registres moves/status/abilities/items | SOLO-501 | registries et manifests `map_battle` | Aucun enregistrement ciblé sans implémentation ou statut explicite ; hooks ordonnés et tests de manifeste |
| SOLO-504 | Profils d'IA | SOLO-501 | AI knowledge/scoring/actions | Profils simple/normal/expert, candidats légaux, score explicable, RNG injecté et aucune triche non déclarée |
| SOLO-505 | Capture, fuite et outcome transactionnel | SOLO-502 | catch handler, runtime outcome, party/PC/save | Résultat unique appliqué une fois : ball, capture, destination, XP/récompenses, fuite et retour monde |
| SOLO-506 | Hooks de combat scénarisé | SOLO-400, SOLO-505 | narrative trainer/static battle commands | Pré/post-combat, victoire/défaite, faits, récompenses et rematch via contrats typés ; transports certifiés |
| SOLO-507 | Présentation, audio et gate combat single | SOLO-501, SOLO-502, SOLO-503, SOLO-504, SOLO-505, SOLO-506 | battle overlay, animation plan, imported PSDK assets | Tous les lots 500–506 sont verts ; familles visuelles couvertes, ordre PSDK référencé, cri/audio/transition testés sur build installé |

La fermeture du combat doit être mesurée par un manifeste de cible et des scénarios observables, jamais par le nombre de classes ou d'enregistrements.

### Phase 6 — progression, équipe et économie

Objectif : rendre chaque victoire utile et chaque état durable.

| ID | Lot | Dépendances | Zones de départ | Critère de sortie |
|---|---|---|---|---|
| SOLO-600 | XP, niveau et apprentissage | SOLO-505 | progression rules, move learning UI | Distribution, level-up multiples, choix remplacer/refuser, PP et save/reload idempotents |
| SOLO-601 | Évolution | SOLO-600 | evolution catalog, runtime presentation | Niveau, item, échange local substitué si retenu, amitié et conditions monde ; cancel et reprise sûrs |
| SOLO-602 | Amitié et compteurs de pas | SOLO-600 | Pokémon instance state, step events | Gains/pertes bornés et persistants, utilisables pour évolution ; aucun egg cycle ni Pokerus |
| SOLO-603 | Party et PC complets | SOLO-600 | storage policy, Player menus | Dépôt/retrait/déplacement, box full, party minimale, Summary, recherche et save/reload |
| SOLO-604 | Bag contextuel | SOLO-600 | item capabilities, bag Player | Poches, tri, quantité, use/give/toss selon contexte, raisons d'indisponibilité et atomicité |
| SOLO-605 | Boutiques et soin | SOLO-604 | shop quote/actions, heal transaction | Achat/vente/quantité/argent/capacité, Centre et items partagent le même soin cohérent |
| SOLO-606 | Récompenses, argent et badges | SOLO-505 | trainer outcomes, profile UI | Récompenses une fois, défaite/whiteout, badge et field unlock visibles et persistants |
| SOLO-607 | Pokédex sans shiny | SOLO-505 | dex projection, media catalog | Unknown/seen/caught, formes retenues, habitat et pages Player ; aucune surface shiny |
| SOLO-608 | Services, échanges locaux et gate progression | SOLO-600, SOLO-601, SOLO-602, SOLO-603, SOLO-604, SOLO-605, SOLO-606, SOLO-607 | narrative services, NPC trade | Tous les lots 600–607 sont verts ; Move relearner/deleter/tutor, échange PNJ atomique et validation d'espèce ; aucun réseau |

### Phase 7 — monde vivant

Objectif : ajouter du contexte systémique sans recréer une centrale nucléaire pour changer la teinte du ciel.

| ID | Lot | Dépendances | Zones de départ | Critère de sortie |
|---|---|---|---|---|
| SOLO-700 | Horloge de projet déterministe | SOLO-103 | `map_core` world state, runtime clock | Segments matin/jour/soir/nuit, avance contrôlée, save/reload et temps injecté ; aucune heure machine implicite |
| SOLO-701 | Météo overworld | SOLO-200, SOLO-700 | `MapWeather`, runtime renderer, audio | Transitions, intensité, collision/visibilité si retenues, pause/save et absence de fuite vers règles de combat |
| SOLO-702 | Conditions temps/météo | SOLO-305, SOLO-701 | predicates narration/encounter/evolution | Authoring guidé, preview, résolution explicable et tests déterministes |
| SOLO-703 | Follower Pokémon cosmétique | SOLO-203, SOLO-603 | runtime movement trail, warps, Player settings | Un follower, file de positions, téléportation sûre, masquage intérieur/événement et aucun effet combat/encounter |

### Phase 8 — corpus et authoring no-code

Objectif : rendre le moteur utilisable sans écrire des IDs au marteau-piqueur.

| ID | Lot | Dépendances | Zones de départ | Critère de sortie |
|---|---|---|---|---|
| SOLO-800 | Figer génération et provenance du corpus | SOLO-500 | import tools, catalog manifests, asset licenses | Génération cible documentée, source légale/provenance, inventaire reproductible et aucun asset copié à la main |
| SOLO-801 | Species/Move/Ability Studios guidés | SOLO-800 | pokemon catalog actions, Editor design system | Pickers, formulaires, preview, dépendances et validation ; pas d'Ability Studio fantôme |
| SOLO-802 | Templates Items/Trainers/Encounters/Fields | SOLO-206, SOLO-300, SOLO-604 | campaign content authoring, Editor | Parcours débutant, valeurs sûres, previews et diagnostics avant runtime |
| SOLO-803 | Validation de jouabilité | SOLO-406, SOLO-608 | project capability truth, readiness gate | Départ, starter, route, combat, progression, soin, save et fin atteignables ; erreurs actionnables |
| SOLO-804 | Certification transport par sémantique | SOLO-005, SOLO-801, SOLO-802, SOLO-803 | map_authoring, JSONL, Editor, MCP | Chaque sémantique gameplay publique applicable a le même résultat et le même receipt sur quatre transports |
| SOLO-805 | Import/export contenu et gate authoring | SOLO-800, SOLO-803, SOLO-804 | converters, package export | Tous les lots 800–804 sont verts ; imports externes optionnels et bornés ; PokeMap reste propriétaire de ses données et runtime |

### Phase 9 — tranche dorée et certification

Objectif : prouver le produit réellement livré, pas seulement la bonne humeur des tests unitaires.

| ID | Lot | Dépendances | Zones de départ | Critère de sortie |
|---|---|---|---|---|
| SOLO-900 | Construire la golden slice solo finale | SOLO-106, SOLO-208, SOLO-305, SOLO-406, SOLO-507, SOLO-608, SOLO-702, SOLO-703, SOLO-805 | versioned fixture project | Tous les gates 1–8 sont verts ; titre → starter → quête → exploration → pêche/field gate → dresseur → capture → badge → temps/météo/follower → save/reload → fin |
| SOLO-901 | Journey automatisé installé sans seam | SOLO-900, SOLO-106 | installed host, real input driver | Package exporté/installé piloté par inputs visibles ; aucun debug seam, mutation directe ou fixture forgée |
| SOLO-902 | Receipt humain versionné | SOLO-901 | walkthrough harness, screen recording | Build/SHA/appareil, étapes, captures ou vidéo, résultat, limites et validation explicite de Yoahn |
| SOLO-903 | Gates de non-régression | SOLO-901 | package suites et CI courte | Tests ciblés package par package, smoke runtime, conformance transport et hygiene ; aucune soak coûteuse en CI |
| SOLO-904 | Certification performance locale | SOLO-901 | product certification harness | Startup, transition map, ouverture combat, save et menus mesurés localement avec budget et receipts ; hors CI ordinaire |
| SOLO-905 | Décision release candidate | SOLO-902, SOLO-903, SOLO-904 | evidence pack unique | Tous les critères inclus ont preuve fraîche ; exclusions vérifiées ; limites acceptées ; statut proposé, jamais auto-`DONE` |

## 9. Ordonnancement recommandé

### 9.1 Chemin critique

```text
SOLO-000 ───────┐
SOLO-001 ───────┼→ SOLO-003 → SOLO-004 → SOLO-005
SOLO-002 ───────┘                   │          │
                                   │          └→ authoring/transports par domaine
                                   └→ SOLO-006 → SOLO-100..106

SOLO-100..106 ─┐
SOLO-200..208 ─┤
SOLO-300..305 ─┼→ SOLO-900 → SOLO-901 → SOLO-902 → SOLO-905
SOLO-400..406 ─┤
SOLO-500..507 ─┤
SOLO-600..608 ─┤
SOLO-700..703 ─┤
SOLO-800..805 ─┘
```

### 9.2 Ce qui peut être parallélisé

- Après `SOLO-000`, réparations Golden Item et Trainer Studio sont indépendantes.
- Terrain, rencontres et quest model peuvent avancer en parallèle après fixation des contrats.
- Battle engine et Player battle presentation peuvent avancer en parallèle si l'event log est figé avant l'intégration.
- Corpus/import et transport receipts peuvent suivre chaque domaine en continu ; ils ne doivent pas attendre une « grande phase authoring » finale.
- Jour/nuit, météo et follower doivent attendre que navigation, save et predicates soient stables.

### 9.3 Les cinq prochains mouvements

1. `SOLO-001` et `SOLO-002` : revenir à une baseline ciblée verte.
2. `SOLO-000` et `SOLO-003` : nettoyer le périmètre et rebaseliner les statuts trompeurs.
3. `SOLO-006` : remplacer les preuves synthétiques par un vrai parcours Player installé.
4. `SOLO-200`, `SOLO-300`, `SOLO-302`, `SOLO-303`, `SOLO-205` : fermer exploration, pêche, Repel et field actions.
5. `SOLO-500` puis `SOLO-501..507` : fermer explicitement le combat simple au lieu d'accumuler des enregistrements.

## 10. Correspondance avec le roadmap FG existant

Le roadmap racine reste une source d'identifiants, mais ses statuts ne doivent pas être pris comme vérité courante avant réaudit.

| Lots FG | Lecture 2026-08-25 | Action proposée |
|---|---|---|
| FG-010–016 | Nouvelle partie, shell et pause plus avancés que `TODO` | Réauditer avec SOLO-100–103 |
| FG-020–030 | Party/PC et projections réelles mais fermeture Player incomplète | Aligner sur SOLO-603 |
| FG-040–053 | Combat/progression substantiels, plusieurs axes explicitement `partial` | Figer cible via SOLO-500 puis fermer par manifeste |
| FG-060–079 | Items/shop/heal largement présents ; Golden Item rouge | Réparer SOLO-001 puis certifier SOLO-604–605 |
| FG-080–094 | Catalogue narratif riche ; Common Events et Quest Book incomplets | SOLO-400–406 |
| FG-100–108 | Walk/Surf réels ; pêche et Repel absents | SOLO-300–305 ; FG-105 Headbutt devient OOS |
| FG-120–129 | Surf réel ; autres field abilities non supportées | SOLO-204–208 ; Rock Smash uniquement obstacle |
| FG-140–147 | Trainer lifecycle/rematch/rewards déjà livrés en partie | Réaudit de statut, puis SOLO-506/606 |
| FG-160–165 | Player shell, menus et Dex plus avancés que le texte | Rebaseliner avec SOLO-100–104/607 |
| FG-180–185 | Harness fort mais Player humain réel non prouvé | SOLO-900–905 |
| FG-200 | Combats doubles | OOS |
| FG-202 | Daycare, reproduction et œufs | OOS |
| FG-203 | Online et multijoueur | OOS |
| FG-204 | Concours et mini-jeux | OOS |

Nuzlocke est OOS par décision produit, mais ne correspond pas à FG-204 dans le roadmap canonique.

Le roadmap pointe encore MVP-01/MVP-02 vers `packages/map_runtime/test/selbrume_new_game_starter_integration_test.dart`, fichier absent à HEAD. Ce lien doit être corrigé lors de `SOLO-003`, pas masqué par un nouveau test portant un nom de convenance.

Jour/nuit, météo overworld et follower n'ont pas de lots FG assez nets. Ils devront devenir de futurs lots Post Bêta distincts uniquement lorsqu'une mise à jour Notion sera autorisée ; ils ne doivent pas gonfler rétroactivement un ticket bêta existant.

## 11. Protocole de preuve par lot

Chaque lot implémenté devra fournir :

1. SHA et état Git initial ;
2. contrat produit et exclusions applicables ;
3. fichiers et zones modifiés ;
4. test pur de l'invariant ;
5. test authoring ou widget si visible dans l'Editor ;
6. test runtime avec save/reload si l'état persiste ;
7. preuve Direct API, JSONL, Editor et MCP ou justification N/A ;
8. build Player installé et observation réelle si le comportement est visuel ou interactif ;
9. commandes exactes, résultats et limites ;
10. état Git final et un commit dédié seulement si explicitement autorisé ;
11. statut proposé `TO REVIEW`, jamais `DONE` sans validation explicite.

### 11.1 Gates package par package

```bash
cd packages/map_core && dart test && dart analyze
cd packages/map_gameplay && dart test && dart analyze
cd packages/map_battle && dart test && dart analyze
cd packages/map_authoring && dart test && dart analyze
cd packages/map_runtime && flutter test && flutter analyze
cd packages/map_editor && flutter test && flutter analyze
cd packages/map_player_ui && flutter test && flutter analyze
cd examples/playable_runtime_host && flutter test && flutter analyze
cd tools/pokemap_mcp && npm run check && npm test
```

Les commandes Flutter restent séquentielles. Les harnesses `flutter_tester`, `frontend_server_aot` et `flutter_tools.snapshot test` doivent être reapés après chaque suite. Les parcours longs et soaks restent locaux et opt-in.

## 12. Vérifications fraîches de cet audit

### 12.1 Tests verts

| Package | Commande ciblée | Résultat |
|---|---|---|
| map_core | `dart test test/pokemon_ruleset_profile_test.dart test/storyline_progression_projection_test.dart test/project_capability_truth_test.dart test/project_encounter_conditions_test.dart` | 23 tests, tous passés |
| map_gameplay | `dart test test/field_action_test.dart test/pokemon_gameplay_rules_test.dart test/encounter_resolution_contract_test.dart test/new_game_seed_state_projection_test.dart` | 32 tests, tous passés |
| map_battle | `dart test test/psdk_final_parity_gate_test.dart test/battle_parity_target_test.dart test/battle_parity_target_ruleset_agreement_test.dart test/psdk_ability_registry_manifest_test.dart` | 24 tests, tous passés |
| map_authoring | `dart test test/parity/full_authoring_parity_test.dart test/domains/gameplay/campaign_content_authoring_test.dart` | 21 tests, tous passés |
| map_runtime | `flutter test test/playable_map_game_project_new_game_boot_test.dart test/player/runtime_startup_coordinator_test.dart test/phase_a_golden_battle_slice_smoke_test.dart` | 44 tests, tous passés |

Total ciblé vert : 144 tests.

### 12.2 Rouges reproduits

| Zone | Commande | Résultat exact utile |
|---|---|---|
| Host | `flutter test test/golden_fangame_slice_e2e_test.dart test/golden_item_system_flow_test.dart` | Exit 1 ; compilation : paramètre `zoneId` inconnu à `examples/playable_runtime_host/lib/src/golden_item_system_journey.dart:645`; 1 test a néanmoins terminé, 2 chargements signalés en échec |
| Editor | `flutter test test/trainer_library_panel_test.dart` | Exit 1 ; 15 passés, 2 échoués aux lignes 325 et 527 : `Leftovers` et `Oran Berry` absents des options |
| MCP | `npm run check && npm test` | TypeScript check vert ; 72 tests, 71 passés, 1 échec dans `tools/pokemap_mcp/test/protocol_compatibility.test.ts:158`, `actual true`, `expected undefined` |
| MCP conformance | `cd packages/map_authoring && dart run tool/pmcp085_conformance.dart` | Exit 1 ; 254 actions incomplètes ; certification globale et Items incomplètes |

Le rouge Host n'est pas un simple renommage à supprimer : `WildBattleStartRequest` attend les champs canoniques `encounterSourceId` et `encounterSourceKind`. La correction doit préserver cette provenance.

### 12.3 Limites de vérification

- Aucun full test/analyze de tous les packages n'a été lancé ; les suites ciblées ne certifient pas la santé globale.
- Aucun Player installé n'a été piloté manuellement pendant cet audit.
- Aucun benchmark ou soak n'a été exécuté.
- Les références PSDK ont été inspectées localement ; PSDK ne fournit pas de SHA Git.
- Les meilleurs journeys installés existants utilisent encore des seams de debug pour certains combats.

## 13. État Git et fichiers

### 13.1 État initial

HEAD initial : `ff304411177b1df43179e2b6e704be1a7aead756`.

Le worktree contenait déjà cinq suppressions de rapports, plusieurs modifications Presentation/editor/runtime, des tests et fichiers de configuration non suivis ainsi qu'un lock d'authoring préexistant. Aucun de ces changements n'a été réinitialisé, stashé, formaté ou ajouté à Git.

### 13.2 Fichier créé par cet audit

- `documentation/reports/roadmap/gameplay/roadmap_fangame_solo_psdk_pokemap_2026-08-25.md` — totalité du présent audit, de la matrice et de la roadmap.

Les deux locks vides créés par les suites ciblées dans `golden_fangame_slice` et `golden_personalization_v3` ont été supprimés après vérification. Le lock préexistant de `p3_narrative_smoke_slice` a été conservé.

### 13.3 État final

L'état final exact est enregistré après validation du présent document dans la section 15.

## 14. Verdict des passes indépendantes

| Passe | Verdict |
|---|---|
| Critique du rapport | `PASS documentaire avec réserves`; `FAIL` comme base de priorisation courante |
| Audit PSDK | Les invariants sont réutilisables ; la structure Ruby/RMXP ne doit pas être transposée |
| Audit PokeMap | Cœur solo substantiel ; plusieurs vocabulaires ne sont pas consommés ; preuve Player globale partielle |
| Architecture | Les frontières de packages sont adaptées à la conversion proposée |
| Authoring/MCP | Catalogue très large, receipts et simulation battle/progression incomplets |
| Runtime/E2E | Tranche verticale solide ; aucun receipt humain installé versionné à HEAD |

## 15. Auto-critique, risques et clôture

### 15.1 Risques

1. **Faux positif par modèle** : enum de canne, météo de map ou field ability ne prouvent pas une mécanique.
2. **Faux positif par test** : un evaluation driver ou `debugOpenBattleForTest` ne prouve pas le Player visible.
3. **Faux positif par catalogue** : une action déclarée ou un adaptateur MCP ne prouve pas les quatre transports.
4. **Roadmap drift** : plusieurs statuts FG sont déjà plus vieux que leur code.
5. **Exhaustivité combat** : les grands compteurs PSDK peuvent créer une illusion de couverture.
6. **Nettoyage OOS** : retirer shiny/breeding/headbutt touche schéma, Editor, runtime, fixtures et catalogues ; le lot doit rester ciblé malgré son ampleur.
7. **Concurrent work** : HEAD et worktree ont changé pendant l'audit ; toute implémentation devra repartir d'un SHA et d'un status frais.
8. **Assets/licences** : les recettes PSDK peuvent inspirer ; le code Ruby ne doit pas être copié et les assets doivent passer par des imports rerunnables avec provenance.

### 15.2 Auto-critique

Ce document est volontairement plus prescriptif que le rapport historique : il propose une architecture de conversion et 69 lots documentaires. Il ne remplace toutefois pas un plan d'implémentation juste-à-temps. Les chemins précis et les dépendances devront être revalidés au SHA du lot, car le monorepo évolue vite et une roadmap qui prétend connaître à l'avance chaque ligne de code finit généralement par écrire de la fan-fiction technique.

Les statuts proposés ne sont pas des clôtures. Aucun lot FG n'est marqué `DONE`, aucune donnée Notion n'est modifiée et aucun comportement Player visuel n'est déclaré accepté sans observation réelle.

### 15.3 Verdict final

La bonne stratégie n'est ni de courir après toute la surface historique de PSDK, ni de considérer PokeMap presque vide. Il faut reprendre de PSDK les règles et séquences qui rendent une aventure solo cohérente, les reformuler en contrats purs PokeMap, les authorer par les transports canoniques, puis les prouver dans le Player installé.

Le produit peut ignorer sans regret les doubles, l'élevage, les shiny, les chaînes, les mini-jeux, le réseau et le reste du périmètre exclu. Ce retrait ne réduit pas l'ambition : il libère assez de temps pour finir correctement ce qui compte vraiment — explorer, raconter, rencontrer, combattre, progresser, sauvegarder et terminer une aventure.

État final après création et validation du rapport : à renseigner par la passe de vérification finale.
