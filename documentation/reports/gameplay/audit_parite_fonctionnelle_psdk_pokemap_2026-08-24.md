# Audit exhaustif des fonctionnalités PSDK et de la parité PokeMap

| Champ | Valeur |
|---|---|
| Ticket | `POST-SYS-004` — Auditer exhaustivement les fonctionnalités PSDK et la parité PokeMap |
| Date de l'audit | 2026-08-24 |
| PokeMap audité | `main` — `6ee23f76904c9e47f5510361902279a8b7d29312` |
| PSDK audité | Snapshot local build `6711`, soit `26.55` par décodage du numéro de publication |
| Projet PSDK témoin | Pokémon Studio `2.9.1`, démo `1.0.23` |
| Nature du travail | Audit statique PSDK et tests ciblés PokeMap, sans modification de code produit |
| Verdict global | PokeMap couvre déjà une tranche fangame cohérente et mieux intégrée pour l'auteur, mais pas encore la largeur mécanique de PSDK |

## 1. Verdict exécutif

PSDK est aujourd'hui plus large que PokeMap sur la quantité de mécaniques Pokémon historiques. Son avance la plus nette concerne le monde vivant, les systèmes secondaires et la profondeur accumulée : cycle temporel, météo, followers, baies, pension et reproduction, œufs, rencontres spécialisées, formats de combat multiples, Safari, concours, mini-jeux et nombreux comportements de terrain.

PokeMap n'est cependant pas un « petit PSDK incomplet ». Son architecture est déjà meilleure sur plusieurs axes structurants : éditeur unifié, authoring transactionnel et révisionné, transports direct/JSONL/Editor/MCP, validations explicites, Smart Tiles sémantiques, narration structurée, cinématiques audio/vidéo, sauvegardes transactionnelles, preuves automatisées et packaging `.avelunegame`.

Le vrai constat est donc le suivant :

1. **PokeMap possède déjà les briques cohérentes d'un mini-fangame** : la Golden Fangame E2E passe isolément, tandis que PC, shop et soin sont prouvés par des services ciblés. Cela ne constitue pas une unique preuve globale : le Golden Item ne compile actuellement pas.
2. **La parité “moteur Pokémon complet” reste partielle** : plusieurs systèmes existent comme modèles ou moteurs mais ne sont pas activés, authorables et jouables de bout en bout.
3. **Les trous les plus importants ne sont pas dans les fondations de combat** : ils sont dans le monde vivant, les rencontres avancées, les capacités terrain, les quêtes joueur, les doubles, la reproduction et la couverture d'authoring.
4. **PSDK contient aussi des faux positifs** : GTS dépendant d'un serveur tiers historique, échange direct cassé, P2P non implémenté, commandes documentées sans implémentation, concours incomplet, caches faibles et outils legacy mutateurs.
5. **La bonne cible n'est pas “copier PSDK”** : il faut reprendre les mécaniques utiles dans les contrats canoniques PokeMap, sans importer ses dépendances RMXP, son exécution Ruby arbitraire ni ses couches de compatibilité.

### Résumé par grand domaine

| Domaine | PSDK | PokeMap | Verdict comparatif |
|---|---|---|---|
| Cartes et navigation | Très large, Tiled + RMXP + SystemTags | Fort, natif, no-code, Smart Tiles, connexions et warps | **PokeMap mieux aligné avec son intégration produit**, PSDK plus varié en terrains |
| Événements et narration | Puissant mais largement RMXP/Ruby | Event V2, Scenes, Storylines, dialogues et cinématiques structurés | **PokeMap mieux aligné avec le no-code moderne** |
| Monde vivant | Temps, lune, météo, followers, baies | Quelques briques visuelles, pas de système cohérent | **Avantage PSDK net** |
| Rencontres | Walk, surf, pêche, headbutt, roaming, hordes | Walk/surf natifs, règles et overrides solides | **PokeMap partiel** |
| Combat | Large moteur Gen IV+, singles/doubles/triples, Safari, Mega | Singles très avancé, registre de parité et runtime intégré | **PokeMap solide mais format produit plus étroit** |
| Progression | EXP, EV, loyauté, évolutions, breeding, œufs | EXP, level-up, move learning, évolutions et capture | **PokeMap partiel** |
| Party, bag, PC, shops | Très complet | Tranche fonctionnelle cohérente, PC UI encore à certifier intégralement | **Parité proche sur le cœur** |
| Quêtes | Objectifs/récompenses et quest book | Storylines et side quests, pas de journal joueur | **PokeMap partiel** |
| Concours et mini-jeux | Présents, maturité variable | Absents | **Avantage PSDK**, priorité secondaire |
| Online | GTS legacy, P2P et trade incomplets | Désactivé explicitement | **Aucune cible fiable à copier** |
| Studio et données | Pokémon Studio externe + Tiled + RMXP + Ruby | Éditeur Flutter unifié + API canonique | **Alignement architectural PokeMap observable** |
| Validation et automatisation | Tests et outils disparates | Forte densité de tests, capability truth, receipts | **Alignement PokeMap observable**, sans audit UI Studio |
| Distribution | Release PSDK historique | `.avelunegame` et Hub présents en code/tests | **Architecture PokeMap plus moderne**, installation réelle à recertifier |

## 2. Périmètre, méthode et niveau de preuve

### 2.1 Définition d'« exhaustif »

L'inventaire vise l'exhaustivité **par famille fonctionnelle observable dans le snapshot**. Il ne duplique pas chaque entrée de données — les 728 moves, 935 items ou 807 fichiers Pokémon du sample ne sont pas chacun une fonctionnalité distincte. Chaque mécanisme, workflow d'auteur, système joueur, outil ou extension identifié est classé dans la matrice ; les recherches négatives et les limites de corpus restent explicites.

### 2.2 Statuts PokeMap

| Symbole | Statut | Critère |
|---|---|---|
| ✅ | Complet | Modèle, authoring, runtime et preuve ciblée disponibles lorsque ces couches s'appliquent |
| 🟡 | Partiel | Flux réellement présent, mais profondeur, couche, couverture ou preuve manquante |
| 🧱 | Socle | Modèle, moteur ou API présent sans parcours joueur complet |
| 🚫 | Désactivé | Capacité connue mais refusée par le ruleset ou le runtime produit |
| ❌ | Absent | Aucun système équivalent identifié |
| ❓ | Non prouvé | Indice ou code présent, mais preuve insuffisante pour conclure |

### 2.3 Qualificatifs PSDK

| Qualificatif | Sens |
|---|---|
| Cœur | Code moteur réellement branché |
| Flux cohérent | Chaîne statique complète identifiée dans le code |
| Legacy | Couche RMXP, compatibilité ou outil historique |
| Externe | Dépendance à Pokémon Studio, Tiled, RMXP, un serveur ou un asset non certifié |
| Stub/défaut | API morte, TODO, absence prouvée ou bug concret |

### 2.4 Corpus inspecté

| Corpus | Volume observé |
|---|---:|
| Scripts Ruby PSDK | 1 518 fichiers |
| Systèmes PSDK | 384 fichiers |
| Combat PSDK | 907 fichiers |
| Concours PSDK | 55 fichiers |
| Outils PSDK | 59 fichiers |
| Données Studio du sample | 2 866 fichiers |
| Pokémon du sample | 807 JSON |
| Moves du sample | 728 JSON |
| Items du sample | 935 JSON |
| Abilities du sample | 233 JSON |
| Trainers du sample | 14 JSON |
| Maps du sample | 21 maps liées + un template |
| Événements de map inventoriés | 482 |
| Common Events | 100 slots, dont 45 événements nommés non réservés |
| Animations RMXP | 874 animations, 2 249 timings |
| Graphismes du sample | 12 357 fichiers |
| Audios du sample | 1 331 fichiers |

Les répertoires PSDK et sample ne contiennent aucun `.git`. Le numéro `6711` est donc la seule identité locale vérifiable ; son décodage en `26.55` est prouvé par le loader PSDK (`P00`). Aucune branche ni SHA upstream ne peut être certifiée. Le lanceur du sample peut en outre résoudre un autre binaire local, une variable `PSDK_BINARY_PATH` ou `~/.pokemonsdk` (`P54`).

### 2.5 Anatomie réelle du pipeline d'auteur PSDK

```text
Pokémon Studio externe  → catalogues JSON et configuration
Tiled externe           → tuiles, passages, priorités et SystemTags
RPG Maker XP externe    → événements, Common Events et animations RMXP
Ruby manuel             → comportements spéciaux, plugins, battle events
PSDK                     → conversions, caches, runtime, debug et release
```

Le dossier `scripts/3 Studio` contient **40 fichiers Ruby et 3 389 lignes** : modèles, configs, accessors et compilation runtime. Il ne contient pas le code de l'interface graphique Pokémon Studio. Les formulaires, pickers, validations UX, undo et imports interactifs de Studio restent donc non inspectables.

`Studio2PSDK.rb` exclut explicitement `maps` et `events` de sa compilation et considère `psdk.dat` valide dès qu'il existe (`P16`). Les maps visuelles passent par Tiled, tandis que les événements restent dans les objets RMXP existants : le convertisseur recharge la map, puis remplace principalement tables de tuiles et métadonnées (`P25`).

#### Données Studio et Tiled du sample

| Famille | Inventaire observé |
|---|---:|
| JSON dans les catégories Studio | 2 861 |
| Fichiers racine Studio supplémentaires | 5 : `map_info.json`, `text_info.json`, `mtimes.dat`, `psdk.dat`, `.DS_Store` |
| Total `Data/Studio` | 2 866 fichiers, dont 2 863 JSON |
| `Data/Studio/events` | 0 fichier |
| Maps Tiled numérotées | 22 TMX : 21 maps + un template |
| Règles automapping | 4 TMX |
| Tilesets | 21 TSX + 21 PNG source |
| Overviews | 21 |
| Queue Tiled | `Data/Tiled/.jobs/map_jobs.json` vaut `[]` |

#### Textes, plugins et outils

| Famille | Inventaire observé |
|---|---:|
| Dialogues CSV | 111 |
| Caches dialogue `.en.dat` | 111 |
| CSV Studio | 6 |
| Langues déclarées dans `project.studio` | 7 : `en`, `fr`, `it`, `de`, `es`, `ko`, `kana` |
| Langues sélectionnables dans `language_config.json` | 1 : `en` |
| Utilitaires Ruby libres dans `plugins/` | 30 |
| Packages `.psdkplug` installés | 0 |

Les 30 scripts libres sont chargés comme utilities `--util`, distinctement du gestionnaire cœur `.psdkplug` (`P20`, `P59`). Le sample ne contient ni `.psdkplug` ni `plugins.dat`. Les outils couvrent notamment éditeurs legacy worldmap/SystemTags, imports texte, génération de machines à états, `Tester` avec évaluation Ruby, sauvegarde encodée en image, captures de map et auto-update.

#### Bibliothèques de contenu du sample

| Ressource | Fichiers |
|---|---:|
| Graphismes Pokédex | 7 460 |
| Characters | 2 468 |
| Sheets d'animation | 181 |
| Transitions | 79 |
| Effets sonores `se` | 1 170 |
| Musiques `bgm` | 99 |
| Jingles `me` | 27 |
| Sons de particules | 20 |
| Ambiances `bgs` | 14 |

Ces volumes prouvent un contenu de démonstration riche, pas un gestionnaire d'assets Studio ni une licence d'utilisation pour PokeMap.

## 3. Liste précise des fonctionnalités manquantes ou incomplètes dans PokeMap

Les priorités ci-dessous sont **post-bêta**. Elles ne modifient ni le gate, ni les familles, ni les dépendances de la bêta gelée.

### 3.1 Priorité A — valeur fangame structurante

| # | Fonction à compléter | État PokeMap | Ce que PSDK démontre | Proposition PokeMap |
|---:|---|---|---|---|
| A1 | Journal de quêtes joueur | ❌ Absent ; Storylines/side quests existent en amont | États active/finished/failed, objectifs et récompenses | Ajouter un modèle de lecture joueur dérivé des Storylines, sans second système de vérité |
| A2 | Rencontres pêche/headbutt/rock smash/roaming | 🚫 Pêche/headbutt/rock smash non produits ; ❌ roaming absent | Managers spécialisés et règles contextuelles | Étendre `EncounterSource` et les comportements Smart Tile canoniques |
| A3 | Capacités terrain complètes | 🟡 Surf ; 🚫 Cut/Strength/Flash/Rock Smash/Waterfall/Dive ; ❌ Fly hors contrat | Cut, Strength, Fly, Flash, Rock Smash, Dive, Waterfall, cannes | Étendre le service evaluate/confirm/commit avec authoring et golden slice par capacité |
| A4 | Terrains overworld riches | 🟡 Collision forte, effets de déplacement incomplets | Glace, ledges, ponts, rapides, escaliers, escalade | Porter les sémantiques dans Smart Tiles, jamais comme tags opaques RMXP |
| A5 | Couverture authoring Pokémon | 🟡 Items/Trainer régressés, Ability Studio absent | Studio manipule les catalogues principaux | Unifier pickers et actions enregistrées pour abilities, held items et récompenses |
| A6 | Combats doubles end-to-end | 🚫 Topologie moteur présente, setup produit refuse non-single | Single/double/triple/allié/hordes | Activer doubles seulement après contrat runtime, UI de ciblage, IA et tests de parcours |
| A7 | Événements scriptés pendant le combat | 🟡 Orchestration narrative autour du combat, pas de hooks complets | Hooks de phase et actions IA forcées | Exposer des Battle Steps typés dans l'API d'authoring, sans évaluation de code arbitraire |
| A8 | Couverture visuelle des moves | 🟡 18 recettes exactes sur 952 moves, nombreux fallbacks | Registre + fallback RMXP avec 181 sheets | Prioriser les familles chorégraphiques, mesurer le fallback et certifier visuellement |
| A9 | Corpus Pokémon prêt à l'emploi | ❌ Absent ; le framework de données existe, pas le corpus complet | Sample riche en espèces/items/moves/abilities/assets | Livrer un catalogue importable/licite versionné, distinct du moteur |
| A10 | Régression Item/Trainer actuelle | 🟡 Deux tests Trainer rouges et journey Item non compilable | Sans équivalent direct | Réparer les pickers et retirer l'ancien `zoneId` avant de revendiquer la tranche globale verte |

### 3.2 Priorité B — profondeur RPG attendue

| # | Fonction à construire | État PokeMap | Ce que PSDK démontre | Proposition PokeMap |
|---:|---|---|---|---|
| B1 | Cycle jour/nuit | ❌ | Horloge réelle/virtuelle et interpolation de teinte | Service de temps déterministe, horloge de projet et règles authorables |
| B2 | Météo overworld | ❌ | Pluie, soleil, sable, grêle, brouillard, neige + particules | Séparer état gameplay, rendu et transitions ; réutiliser les catalogues visuels |
| B3 | Plantation et croissance des baies | ❌ | Planter, arroser, stades, récolter | Comportement d'entité persistant avec horloge simulable |
| B4 | Followers Pokémon/NPC multiples | ❌ | Followers, équipe et mode Let's Go | Composant runtime + règles de warp + authoring de formation |
| B5 | Pension, reproduction et œufs | 🚫 Explicitement désactivé | Compatibilité, héritage, IV, moves, objets et éclosion | Lot autonome après stabilisation progression/PC, sans compatibilité legacy |
| B6 | EV, loyauté et progression au pas | 🟡 Données et quelques conditions, boucle joueur incomplète | Pokerus, plafonds EV, bonheur, pas, poison, œufs | Formaliser les événements de progression et leurs receipts |
| B7 | Pokémon errants et chaînes | ❌ | Roaming, historique, chaîne de pêche, shiny modifiers | Système déterministe sauvegardable au-dessus des encounters |
| B8 | Repel et modificateurs de rencontres | 🚫 | Répulsif, talents, objets et terrains | Ajouter les règles au moteur pur et les déclarer dans capability truth |
| B9 | Boutique de Pokémon | ❌ | Génération, paiement et stockage | Type de shop dédié, pas un item déguisé en Pokémon |
| B10 | Profil dresseur et badges multi-régions | 🟡 Facts/progression sans surface dédiée complète | Profil, temps de jeu et grille de badges | Vue joueur dérivée de la progression existante |
| B11 | Worldmap, lieux et fast travel | 🟡 Connexions présentes, surface joueur limitée | Worldmaps, zones, fly et warps | Construire sur la topologie canonique PokeMap et les capacités terrain |
| B12 | Options et remappage d'inputs | 🟡 Personnalisation existante, remapping non certifié | Clavier/manette, conflits, volumes, langue, autorun | Registre d'actions d'entrée indépendant des touches physiques |

### 3.3 Priorité C — systèmes secondaires facultatifs

| # | Fonction | État | Recommandation |
|---:|---|---|---|
| C1 | Concours Pokémon | ❌ | Lot séparé ; le moteur PSDK est présent mais IA et récompenses restent pauvres |
| C2 | Safari | ❌ | À concevoir comme ruleset de rencontre/capture, pas comme duplication du moteur |
| C3 | Nuzlocke | ❌ | Preset de règles optionnel après stabilisation des hooks de mort/capture/zone |
| C4 | Hall of Fame | ❌ dédié | Peut être une composition Storyline + cinematic + snapshot d'équipe |
| C5 | Mining | ❌ | Plugin/minigame optionnel |
| C6 | Voltorb Flip | ❌ | Plugin/minigame optionnel |
| C7 | Ruins of Alph puzzle | ❌ | Plugin/minigame optionnel |
| C8 | Machines à sous | ❌ | Faible priorité et contraintes produit/légales à considérer |
| C9 | Phases lunaires et horloge RSE | ❌ | Extensions du système de temps, pas fondations séparées |
| C10 | Dynamic lights et map overlays avancés | 🟡 | Étendre les systèmes visuels existants seulement avec besoin de jeu concret |

### 3.4 Priorité D — ne pas copier tel quel

| Fonction PSDK | Pourquoi elle ne doit pas devenir une cible directe |
|---|---|
| GTS historique | Serveur tiers, HTTP en clair et disponibilité non prouvée |
| P2P serveur/client | Modes déclarés mais non programmés dans `Scene_Map` |
| Échange online direct | API appelle une classe absente du snapshot ; l'échange PNJ local existe séparément |
| Ruby arbitraire dans les événements | Incompatible avec le no-code validé et une surface sûre |
| RMXP comme éditeur d'événements | Fragmenterait l'autorité des données PokeMap |
| Cache Marshal validé par simple existence | Invalidation insuffisante et format dépendant du runtime Ruby |
| Outils legacy mutateurs sans transaction | Risque de réécriture et absence d'undo/receipt |
| Plugins non sandboxés | SHA-512 contrôle l'intégrité, pas la confiance du code exécuté |
| Compatibilité pré-1.0 | Explicitement hors politique produit PokeMap |

## 4. Matrice exhaustive PSDK ↔ PokeMap

Les références `Pxx` et `Mxx` renvoient au registre de preuves de la section 5.

### 4.1 Plateforme, données, Studio et outillage

| ID | Fonction PSDK | Réalité PSDK | PokeMap | Écart ou décision | Réf. |
|---|---|---|---|---|---|
| F00 | Titre, nouvelle partie, reprise et crédits | ✅ Cœur | 🟡 Nouvelle partie/reprise fortes, titre/crédits non certifiés ici | Compléter la preuve de composition joueur | P14/M09 |
| F01 | Runtime RPG 2D | ✅ Cœur LiteRGSS2/Ruby | ✅ Flutter/Flame | Deux architectures fonctionnelles ; PokeMap vise davantage de plateformes | P01/M01 |
| F02 | Installation et mise à jour par Pokémon Studio | 🟡 UI externe non inspectée | 🟡 Hub/éditeur en code et tests ; installation réelle non rejouée | Workflow PokeMap plus unifié, mais non fraîchement certifié | P15/M15 |
| F03 | Bridge Studio ↔ moteur | 🟡 JSONL limité à quatre opérations métier plus `exit` | 🟡 Actions enregistrées fortes en direct/JSONL/Editor/MCP, couverture non universelle | Avantage architectural PokeMap, avec trous items et dry-runs | P16/M03 |
| F04 | Compilation JSON vers cache runtime | ✅ mais invalidation grossière | ✅ Chargement projet validé | Ne pas reproduire le cache “existe donc valide” | P16/M03 |
| F05 | Catalogue abilities | ✅ 233 données dans le sample, effets Ruby | 🟡 Registre moteur, pas d'Ability Studio | Compléter authoring et vérité d'effet | P17/P62/M12 |
| F06 | Catalogue items | ✅ 935 items dans le sample, classes spécialisées | 🟡 Modèle/runtime forts, transports authoring globaux vides | Compléter couverture authoring | P17/P62/M11 |
| F07 | Catalogue moves | ✅ 728 moves dans le sample et handlers cœur | 🟡 Moteur/parité larges, corpus projet et visuels incomplets | Poursuivre registres + contenu | P17/P39/M07 |
| F08 | Espèces et formes | ✅ 807 fichiers riches dans le sample | 🟡 Framework complet, corpus projet réduit | Besoin d'un catalogue prêt à l'emploi | P17/M12 |
| F09 | Learnsets | ✅ Donnée Studio | ✅ Schéma et progression | Parité structurelle ; contenu à enrichir | P17/M08 |
| F10 | Évolutions | ✅ Données + hooks Ruby | ✅ Service typé | PokeMap évite les hooks `func` arbitraires | P17/P33/M08 |
| F11 | Dex, natures et types | ✅ Données Studio | 🟡 Framework présent, corpus et surfaces joueur incomplets | Compléter contenu et parcours joueur | P17/M12 |
| F12 | Trainers et équipes | ✅ Données riches | 🟡 Trainer Studio + runtime, deux tests UI rouges | Réparer held items et rewards | P17/M16 |
| F13 | Groupes de rencontres | ✅ Conditions et tags | ✅ Zones/règles/overrides | PokeMap limité aux sources actives walk/surf | P17/M05 |
| F14 | Zones, worldmaps et maplinks | ✅ | 🟡 Maps/connections fortes, worldmap joueur limitée | Construire la vue monde sur la topologie existante | P17/M02 |
| F15 | Données de quêtes | ✅ Objectifs/récompenses par méthodes | 🟡 Storylines structurées | Journal et projections gameplay à finir | P17/M04 |
| F16 | Configuration projet | 🟡 Contrats JSON/runtime ; UI et validations Studio non inspectables | ✅ Manifest typé et validé | Avantage architectural observable PokeMap | P17/M03 |
| F17 | Migration ancien PSDK → Studio | 🟡 Legacy, catégories court-circuitées | 🟡 Import PSDK existant | PokeMap ne doit pas garantir le legacy pré-1.0 | P18/M14 |
| F18 | Import PokeAPI/Showdown | ❌ Pas de fonction équivalente prouvée dans ce snapshot | 🟡 Imports PokeMap partiels | Différenciateur PokeMap à stabiliser | M14 |
| F19 | Scripts projet personnalisés | ✅ Ruby manuel | 🧱 API d'authoring et code Dart, pas de script joueur sandboxé | Ne pas exposer une évaluation arbitraire | P19/M03 |
| F20 | Plugins `.psdkplug` | 🟡 Puissants, non sandboxés | ❌ Pas de marketplace plugin équivalente | Option postérieure, avec permissions explicites | P20/M14 |
| F21 | Localisation CSV | ✅ Fallback et compilation | 🟡 Modèles et textes, parcours multilingue incomplet | Construire une chaîne éditoriale intégrée | P21/M13 |
| F22 | Packaging release | ✅ Dossier Release historique | 🟡 `.avelunegame`/Hub en code et tests non rejoués | Installed-flow PokeMap à recertifier | P22/M15 |
| F23 | Auto-update moteur | 🟡 Historique MD5 local | ❓ Distribution PokeMap non certifiée ici | Concevoir une mise à jour signée si nécessaire | P58/M15 |
| F24 | Debugger/terminal | ✅ Warp, battle test, terminal Ruby | 🟡 Harnesses et tests présents, aucun debugger/terminal équivalent prouvé | Ne pas ajouter de terminal arbitraire au produit | P23/M16 |
| F25 | Simulation IA | ✅ Scénarios JSON + fenêtre debug | 🟡 Dry-run battle authoring non enregistré | Transformer en outil de diagnostic avec receipt | P23/M14 |
| F26 | Export YAML/restauration | 🟡 Legacy avec `unsafe_load` | ✅ JSON canonique, révisions et transactions | Ne pas copier l'outil legacy | P23/M03 |
| F27 | CI moteur | 🟡 GitLab RSpec/RuboCop, sample non construit, `.github` absent | 🟡 Quick checks Hub/core/editor ; gameplay, battle et runtime non couverts par ce workflow | Compléter seulement les gates CI utiles et peu coûteuses | P22/M17 |
| F28 | Éditeur worldmap historique | 🟡 UI legacy sans undo/transaction | 🟡 Worldmap PokeMap en construction | Conserver l'autorité canonique PokeMap | P59/M02 |
| F29 | Éditeur SystemTags historique | 🟡 Peinture directe de données legacy | 🟡 Smart Tiles et collisions natifs, effets terrain partiels | Ne pas importer l'éditeur legacy | P59/M05 |
| F30 | Imports/export texte legacy | 🟡 Swoosh sans merge, Text2CSV figé sur sept langues | 🟡 Localisation PokeMap incomplète | Concevoir un workflow multilingue transactionnel | P59/M13 |
| F31 | StateMachineBuilder et Tester | 🟡 Génération Ruby et `eval` manuel | 🟡 Steps typés et tests automatisés | Avantage architectural observable PokeMap | P59/M04 |
| F32 | SaveToPicture et captures de map | ✅ Outils ponctuels | ❓ Pas d'équivalent certifié | Outils QA optionnels, pas mécaniques produit | P59/M15 |
| F33 | Maintenance release/update/treeshake/signature | 🟡 Large outillage ; signature explicitement prototype | 🟡 Packaging moderne, chaîne signée non certifiée | Ne pas confondre prototype et distribution sûre | P60/M15 |

### 4.2 Cartes, navigation, événements et narration

| ID | Fonction PSDK | Réalité PSDK | PokeMap | Écart ou décision | Réf. |
|---|---|---|---|---|---|
| W01 | Création de maps | 🟡 Studio + Tiled externe | ✅ Éditeur natif | Alignement produit PokeMap observable | P24/M02 |
| W02 | Tilesets externes Tiled | ✅ TSX/PNG | 🟡 Catalogue/éditeur natif, imports Tiled partiels | PokeMap possède sa donnée, la parité d'import reste partielle | P24/M14 |
| W03 | Templates et automapping | 🟡 Sample HGSS spécifique | ✅ Smart Tiles sémantiques | Alignement produit PokeMap observable, pas une parité 1:1 | P24/M02 |
| W04 | Migration RMXP vers Tiled | 🟡 One-shot legacy | ❌ Non requis | Hors cible produit | P57/M14 |
| W05 | Compilation Tiled vers RMXP | ✅ Jobs automatiques | ❌ Non requis | PokeMap ne doit pas dépendre de RMXP | P25/M02 |
| W06 | Passages, priorités et terrain tags | ✅ Couches nommées strictes | 🟡 Collision complète, effets terrain partiels | Étendre Smart Tiles | P25/M05 |
| W07 | Tuiles animées | ✅ Avec plafonds/timing contraints | 🟡 Rendu présent, parité fonctionnelle non certifiée | Besoin d'un audit visuel ciblé | P25/M02 |
| W08 | Flip Tiled horizontal/vertical | ✅ | 🟡 Import partiel | Vérifier les transformations supportées | P25/M14 |
| W09 | Flip diagonal Tiled | 🟡 Flag lu mais non appliqué | ❓ | Ne pas considérer PSDK comme oracle correct ici | P25/M14 |
| W10 | Événements de map | ✅ RMXP externe | ✅ Event V2 natif | Alignement produit PokeMap observable | P02/M04 |
| W11 | Common Events | ✅ 100 slots, 45 nommés non réservés | 🟡 Scenes/Steps réutilisables, pas d'équivalent global certifié | Réutiliser les primitives narratives existantes | P02/M04 |
| W12 | Dialogues et choix | ✅ RMXP/interpréteur | ✅ Dialogue Studio/runtime | Authoring PokeMap mieux aligné avec le no-code | P02/M04 |
| W13 | Switches, variables et self-switches | ✅ | ✅ Facts/WorldRules/conditions | Équivalent plus typé dans PokeMap | P02/M04 |
| W14 | Boucles, labels et branchements | ✅ RMXP | 🟡 Catalogue narratif borné | Ajouter seulement les contrôles nécessaires, pas un langage général | P02/M04 |
| W15 | Téléportation, routes et scroll | ✅ | 🟡 Warps/connections complets ; scroll/caméra non prouvés ici | Parité du cœur de navigation seulement | P03/M02 |
| W16 | Détection PNJ rectangle/cercle/direction | ✅ | 🟡 Interactions/zones présentes, géométries exactes à compléter | Enrichir les triggers s'ils servent un cas produit | P03/M02 |
| W17 | Caméra vers événement/tuile | ✅ | 🟡 Cinématiques/caméra présentes, équivalence exacte non certifiée | Exposer une commande typée si manque réel | P03/M13 |
| W18 | Pathfinding pondéré | ✅ | 🟡 Navigation/patrouilles présentes, parité non certifiée | Audit ciblé avant nouveau moteur | P03/M02 |
| W19 | Warps avec followers/surf/roaming | ✅ | 🟡 Warps et surf, pas followers/roaming | Étendre sans casser la continuité de map | P03/M05 |
| W20 | Fog, transitions et overlays | ✅ | 🟡 Transitions/cinématiques riches, environnement incomplet | Rattacher au futur monde vivant | P02/M13 |
| W21 | Particules overworld | ✅ DSL Ruby/Marshal | 🟡 Systèmes média, pas de catalogue météo complet | Créer un primitive visuel PokeMap si besoin | P26/M13 |
| W22 | Animations RMXP | ✅ 874 animations | 🟡 Battle/cinematic runtimes, couverture move partielle | Continuer l'outil natif et l'import rerunnable | P26/M13 |
| W23 | Battle events | ✅ Hooks Ruby/YARB | 🟡 Encadrement narratif, hooks mid-battle incomplets | Créer des commandes typées | P12/M04 |
| W24 | Extraction dialogues vers CSV | 🟡 Mutateur sans dry-run | ❌ Non requis comme architecture cible | Garder les dialogues canoniques PokeMap | P21/M04 |
| W25 | Commandes événementielles « safe » | ❌ Document seulement | ✅ Catalogue borné de 24 commandes | Différenciateur PokeMap prouvé | P27/M04 |
| W26 | Commandes RMXP acteurs/ennemis | ❌ Plusieurs commandes HP/SP/EXP/niveau/skills/ennemis sont des no-op | ❌ Non pertinent comme API cible | Ne pas compter l'interpréteur RMXP comme couverture Pokémon réelle | P56/M04 |
| W27 | Reconciliation « Loaded Last » | ✅ Warps, followers, rencontres, horloge, Shaymin, Pokerus et migrations | 🟡 Responsabilités distribuées dans des services typés | Vérifier les effets à la source, pas reproduire un hook global | P55/M05 |
| W28 | Rustine de compatibilité legacy | 🟡 Réintroduit des API historiques | ❌ Volontairement hors politique pré-1.0 | Ne pas copier | P55/M01 |

### 4.3 Monde vivant, joueur, menus et persistance

| ID | Fonction PSDK | Réalité PSDK | PokeMap | Écart ou décision | Réf. |
|---|---|---|---|---|---|
| U01 | Followers multiples | ✅ | ❌ | Manque post-bêta | P04/M05 |
| U02 | Mode Let's Go follower | ✅ | ❌ | À séparer du follower cosmétique | P04/M05 |
| U03 | Plantation de baies | ✅ | ❌ | Manque post-bêta | P05/M09 |
| U04 | Arrosage, stades et récolte | ✅ | ❌ | Nécessite horloge persistante | P05/M09 |
| U05 | Météo overworld logique | ✅ | ❌ | Manque post-bêta | P06/M13 |
| U06 | Météo overworld visuelle | ✅ | 🟡 Primitives visuelles sans système complet | Construire logique avant effets | P06/M13 |
| U07 | Cycle jour/nuit réel ou virtuel | ✅ | ❌ | Manque post-bêta | P07/M09 |
| U08 | Teintes interpolées | ✅ | 🧱 Possible via présentation, pas piloté par horloge | Rattacher au cycle temporel | P07/M13 |
| U09 | Phases lunaires | ✅ | ❌ | Option après temps/jour-nuit | P07/M09 |
| U10 | Audio BGM/BGS/ME/SE/cris | ✅ | 🟡 Mixer/cinématiques forts, cries sans consommateur certifié | Finaliser cries et rôles audio gameplay | P08/M13 |
| U11 | Canaux audio dédiés | ✅ | ✅ Mixer/ducking | Authoring PokeMap mieux aligné avec ses contraintes | P08/M13 |
| U12 | Running shoes/autorun | ✅ | 🟡 Déplacement joueur présent, règle d'équipement non certifiée | Définir la cible produit avant parité | P09/M05 |
| U13 | Vélos Mach/Acro | ✅ | ❌ | Faible priorité avant field moves | P09/M05 |
| U14 | Surf | ✅ | 🟡 Service complet, preuve authored fraîche limitée | Compléter golden authoring | P09/M05 |
| U15 | Cut/Strength/Flash/Rock Smash | ✅ | 🚫 | Étendre le contrat field action | P09/M05 |
| U16a | Waterfall/Dive | ✅ | 🚫 Présents dans l'enum, refusés par le ruleset bêta et `evaluateFieldAction` | Nécessite monde, warps et terrain cohérents | P09/M05 |
| U16b | Fly/Dig | ✅ | ❌ Absents du contrat `FieldAbility` | Concevoir les contrats avant toute activation | P09/M05 |
| U17 | Glace, ledges, ponts, rapides, escaliers | ✅ | 🟡 | Étendre Smart Tiles et movement effects | P03/M05 |
| U18 | Menu principal conditionnel | ✅ | 🟡 Pause/menu et surfaces joueur présents, composition globale non certifiée | Vérifier la composition installée finale | P10/M11 |
| U19 | Profil dresseur et temps de jeu | ✅ | 🟡 | Ajouter une projection joueur dédiée | P10/M09 |
| U20 | Badges multi-régions | ✅ | 🟡 Facts/progression, UI dédiée limitée | Surface dérivée, pas second stockage | P10/M04 |
| U21 | Party add/remove/swap/heal | ✅ | ✅ | Parité du cœur | P10/M08 |
| U22 | Bag poches/tri/favoris/raccourcis | ✅ | 🟡 Usages forts, ergonomie exacte non équivalente | Évaluer par besoin UX | P10/M11 |
| U23 | Bag use/give/register/toss/sell | ✅ | 🟡 Use/sell forts, give/register à certifier | Compléter selon capability truth | P10/M11 |
| U24 | PC boxes et battle boxes | ✅ | 🟡 Stockage/opérations PC complets ; écran PC partiel ; Battle Boxes dédiées absentes | Surface Summary PC à recertifier | P10/M10 |
| U25 | PC multisélection/release/rename/theme | ✅ | 🟡 UI PokeMap plus étroite | Prioriser les actions joueur utiles | P10/M10 |
| U26 | Pokédex régional/national/formes | ✅ | 🟡 Framework/surface, corpus réduit | Corpus et cartes de spawn à compléter | P10/M12 |
| U27 | Boutique items et stock limité | ✅ | 🟡 Service ciblé vert, authoring et parcours intégré non prouvés ici | Compléter la preuve end-to-end | P10/M11 |
| U28 | Prix personnalisés et Premier Ball | ✅ | 🟡 Prix/stock oui, bonus spécifique non prouvé | Règle de promotion générique préférable | P10/M11 |
| U29 | Boutique de Pokémon | ✅ | ❌ | Manque post-bêta | P10/M11 |
| U30 | Centre de soin | ✅ via événements/systèmes | 🟡 Service de soin vert, authoring et parcours intégré non prouvés ici | Compléter la preuve end-to-end | P09/M11 |
| U31 | Sauvegardes multiples | ✅ | ✅ Contrats/save slots | PokeMap plus transactionnel | P11/M09 |
| U32 | Backup/restauration corruption | ✅ `.bak` | 🟡 Commit/rollback transactionnel, pas d'équivalent `.bak` certifié | Objectif de cohérence couvert, restauration fichier à distinguer | P11/M09 |
| U33 | Autosave | ❌ PSDK | 🟡 Politique et tests présents, non exécutés dans cette passe | Avantage potentiel PokeMap à conserver | P11/M09 |
| U34 | Options volumes/texte/langue/scale | ✅ | 🟡 Personnalisation partielle | Compléter surface joueur | P11/M13 |
| U35 | Remappage clavier/manette | ✅ | ❓ Non certifié | À auditer/construire | P11/M05 |
| U36 | Accessibilité avancée | ❌ PSDK également limité | 🟡 Captions/cinématiques, couverture globale non auditée | Ne pas prendre PSDK comme plafond | P11/M13 |

### 4.4 Rencontres, créatures, progression et quêtes

| ID | Fonction PSDK | Réalité PSDK | PokeMap | Écart ou décision | Réf. |
|---|---|---|---|---|---|
| G01 | Rencontres walk | ✅ | ✅ | Parité du cœur | P28/M05 |
| G02 | Rencontres surf | ✅ | ✅ | Parité du cœur | P28/M05 |
| G03 | Rencontres pêche | ✅ | 🚫 | Étendre sources et comportements | P28/M05 |
| G04 | Headbutt | ✅ | 🚫 | Étendre Smart Tiles/entities | P28/M05 |
| G05 | Rock Smash encounters | ✅ | 🚫 | Coupler field action et encounter | P28/M05 |
| G06 | Pokémon errants | ✅ | ❌ | Système sauvegardable post-bêta | P28/M09 |
| G07 | Répulsif | ✅ | 🚫 | Ajouter aux règles pures | P28/M05 |
| G08 | Modificateurs par talent/objet/terrain | ✅ | 🟡 Conditions/overrides, couverture canonique limitée | Étendre sans handlers opaques | P28/M05 |
| G09 | Historique et chaînes de rencontres | ✅ | ❌ | Option progression/shiny | P28/M09 |
| G10 | Rencontres doubles/triples/hordes | ✅ | 🚫 | Dépend des formats combat | P28/M06 |
| G11 | Génération forme/IV/nature/ability/moves | ✅ | ✅ Framework | Corpus/coverage à enrichir | P29/M12 |
| G12 | Objets tenus sauvages | ✅ | 🧱 Pas d'authoring dans `ProjectEncounterPokemonOverrides` | Étendre le contrat avant le runtime | P29/M05 |
| G13 | Shiny et Shiny Charm | ✅ | 🧱 Modèles présents, parcours complet non certifié | Audit ciblé avant lot | P29/M12 |
| G14 | Chaîne de pêche shiny | ✅ | ❌ | Dépend de la pêche/historique | P29/M05 |
| G15 | Overflow party vers PC | ✅ | ✅ | Parité du cœur | P30/M10 |
| G16 | Daycare multiples | ✅ | 🚫 | Lot breeding autonome | P31/M01 |
| G17 | Compatibilité de reproduction | ✅ | 🚫 | Lot breeding autonome | P31/M01 |
| G18 | Héritage forme/nature/ability/moves | ✅ | 🚫 | Lot breeding autonome | P31/M01 |
| G19 | Héritage IV/Destiny Knot/power items | ✅ | 🚫 | Lot breeding autonome | P31/M01 |
| G20 | Éclosion et animation | ✅ | 🚫 | Dépend du modèle œuf et de la progression au pas | P31/M01 |
| G21 | Learn/forget/replace/reminder | ✅ | 🟡 Move learning et décisions runtime ; reminder dédié non prouvé | Compléter ou certifier la surface reminder | P32/M08 |
| G22 | Courbes d'EXP et level-up | ✅ | ✅ Variante PokeMap assumée | Pas besoin d'identité stricte si ruleset explicite | P32/M08 |
| G23 | EXP participants/Exp Share/trade | ✅ | 🟡 Distribution PokeMap plus simple | Choisir règles produit avant extension | P32/M07 |
| G24a | EV | ✅ | 🧱 IV/EV sauvegardés et utilisés par le calcul de stats, boucle de gain joueur non certifiée | Manque de profondeur progression | P32/M18 |
| G24b | Pokerus | ✅ | ❌ Recherche statique négative dans packages/examples/tools | Système optionnel après les EV | P32/M18 |
| G25 | Loyauté/bonheur | ✅ | 🟡 Conditions existantes, mise à jour joueur non complète | Formaliser événements de loyauté | P32/M08 |
| G26 | Évolutions niveau/item/move/amitié | ✅ | ✅ Méthodes beta | Parité utile du cœur | P33/M08 |
| G27 | Évolutions trade/map/météo/genre | ✅ | 🟡 Couverture ciblée, méthodes non toutes jouables | Étendre selon catalogue produit | P33/M08 |
| G28 | Scène d'évolution annulable/forcée | ✅ | 🟡 Runtime de décision, scène visuelle fraîche non certifiée | Ajouter une validation visuelle installée | P33/M08 |
| G29 | Progression au pas | ✅ Poison/œuf/loyauté/évolution | 🟡 Étroit | Créer un pipeline d'événements de pas | P33/M08 |
| G30 | Nuzlocke | ✅ Module dédié | ❌ | Preset optionnel | P34/M09 |
| G31 | États de quêtes | ✅ Active/finished/failed | 🟡 Storylines/steps | Ajouter projections et échec explicite si nécessaire | P35/M04 |
| G32 | Objectifs NPC/item/battle/capture/egg/custom | ✅ | 🟡 Steps riches, pas toutes les familles | Étendre le catalogue typé | P35/M04 |
| G33 | Récompenses quêtes | ✅ Item/money/Pokémon | 🟡 Rewards narrative/gameplay, couverture authoring incomplète | Stabiliser authoring et UI | P35/M04 |
| G34 | Quest book joueur | ✅ | ❌ | Priorité A | P35/M04 |
| G35 | Achievements/trophées | ❌ PSDK | ❌ PokeMap | Pas un manque de parité PSDK | P35/M04 |
| G36 | API événementielle Pokémon | ✅ Ajouter/stocker/retirer, apprendre, cri, renommer, œuf, combat sauvage | 🟡 Commandes narratives/gameplay typées, couverture incomplète | Étendre le catalogue PokeMap sans script arbitraire | P56/M04 |

### 4.5 Combat

| ID | Fonction PSDK | Réalité PSDK | PokeMap | Écart ou décision | Réf. |
|---|---|---|---|---|---|
| B01 | Setup joueurs/adversaires/sacs/IA/BGM | ✅ | ✅ | Parité du cœur | P36/M06 |
| B02 | Combat sauvage single | ✅ | ✅ | Flux produit vert ciblé | P36/M06 |
| B03 | Combat dresseur single | ✅ | ✅ | Flux produit vert ciblé | P36/M06 |
| B04 | Combat double | ✅ | 🚫 Ruleset/setup produit | Priorité A après contrat end-to-end | P36/M01 |
| B05 | Combat triple | ✅ | 🚫 | Priorité plus basse que doubles | P36/M01 |
| B06 | Allié dresseur | ✅ | 🚫 | Dépend des formats multi-battlers | P36/M01 |
| B07 | Hordes de cinq | ✅ | 🚫 | Faible priorité, UI spécifique | P28/M01 |
| B08 | Fight/bag/party/flee | ✅ | ✅ | Parité du cœur | P37/M06 |
| B09 | Sélection de cible | ✅ | 🧱 Moteur/topologie, produit single | À activer avec doubles | P37/M06 |
| B10 | Switch et shift | ✅ | 🟡 Switch single présent, shift/multi incomplets | Étendre avec doubles/triples | P37/M06 |
| B11 | Commandes multi-battlers | ✅ | 🧱 | Non exposé produit | P37/M06 |
| B12 | Tri priorité/vitesse | ✅ | 🟡 Gate PokeMap signale encore speed ties partiels | Continuer la parité pure | P38/M07 |
| B13 | Pursuit/Quick Claw/Custap/Quick Draw | ✅ | 🟡 Registre large, exactitude famille par famille | Couvrir par manifest/tests | P38/M07 |
| B14 | Fin de tour et remplacements | ✅ | 🟡 Cœur fort, formats multi absents | Maintenir gate ciblé | P38/M07 |
| B15 | Ordre move/status/weather/ability/item | ✅ avec TODO Stall/Poison Touch | 🟡 Parité explicite partielle | Les deux moteurs ont des écarts ; ne pas idéaliser PSDK | P38/M07 |
| B16 | Modèle move riche et central | 🟡 Riche, mais `Move#clone` interdit et effets non exhaustifs | ✅ Modèle PokeMap structuré | Comparer les capacités prouvées, pas le nom des classes | P39/M07 |
| B17 | Formule de dégâts | ✅ Gen IV | 🟡 Variante/cible documentée, encore partielle | Ruleset explicite plutôt que copie aveugle | P39/M07 |
| B18 | Pipeline précision/dégâts/effets | ✅ | 🟡 Large couverture, parité non totale | Poursuivre les preuves par famille | P39/M07 |
| B19 | Immunités et redirections | ✅ | 🟡 | Compléter registre et tests | P39/M07 |
| B20 | Multi-hit et Population Bomb | ✅ | 🟡 | Couverture move registry à maintenir | P39/M07 |
| B21 | Statuts majeurs et confusion/flinch | ✅ | 🟡 Gate explicitement partiel | Priorité mécanique avant cosmétique | P40/M07 |
| B22 | Météo de combat | ✅ normale/primale/neige | 🟡 Moteur partiel | Étendre selon cible générationnelle | P40/M07 |
| B23 | Terrains de combat | ✅ mais bug Grassy identifié | 🟡 Moteur partiel | Ne pas prendre le bug PSDK comme référence | P40/M07 |
| B24 | Abilities | ✅ 271 registrations mesurées | 🟡 278 abilities, fallback inert possible | Capability truth et coverage manifest nécessaires | P41/M07 |
| B25 | Held items et effets | ✅ 176 registrations mesurées | 🟡 Registre + régression authoring | Réparer authoring puis élargir couverture | P41/M11 |
| B26 | IA niveaux 0–7 | ✅ | 🟡 IA et difficultés présentes, équivalence non totale | Comparer décisions, pas numéros de niveau | P42/M06 |
| B27 | Évaluation cible/dégâts/statuts | ✅ | 🟡 | Tests de décision multi-cibles avec doubles | P42/M07 |
| B28 | Fuite | ✅ | ✅ | Parité du cœur | P43/M06 |
| B29 | Fin de combat/argent/blackout | ✅ | ✅ | PokeMap possède aussi recovery/save | P43/M08 |
| B30 | EXP/évolution/Dex/quêtes en fin de combat | ✅ | 🟡 Progression présente, journal de quêtes absent | Compléter la projection quête | P43/M08 |
| B31 | Capture et balls spéciales | ✅ | 🟡 Capture minimale complète, familles de balls partielles | Catalogue de balls à enrichir | P44/M06 |
| B32 | Implémentation PSDK de critical catch et shakes | ✅ | 🟡 Présentation/règles variables | Choisir la cible ruleset, sans confondre PSDK et canon indépendant | P44/M07 |
| B33 | Capture vers party/PC et renommage | ✅ | 🟡 Party/PC complets, renommage non prouvé | Parité fonctionnelle principale hors renommage | P44/M10 |
| B34 | Mega Evolution | ✅ | 🚫 Modern gimmicks désactivés | Hors cible beta | P45/M01 |
| B35 | Z-Moves | ❌ côté joueur PSDK | 🚫 PokeMap | Pas un manque face à ce snapshot | P45/M01 |
| B36 | Dynamax/Gigantamax | ❌ côté joueur PSDK | 🚫 PokeMap | Pas un manque face à ce snapshot | P45/M01 |
| B37 | Terastallization | ❌ côté joueur PSDK | 🚫 PokeMap | Pas un manque face à ce snapshot | P45/M01 |
| B38 | Safari | ✅ avec défaut de clamp | ❌ | Système optionnel à redessiner | P46/M06 |
| B39 | Battle events mid-fight | ✅ hooks Ruby | 🟡 | Créer hooks typés authorables | P47/M04 |
| B40 | Actions IA forcées par événement | ✅ | ❌ | À intégrer au futur Battle Step Studio | P47/M14 |
| B41 | Animations de moves spécifiques | 🟡 29 fichiers, 18 registrations spécifiques ; fallback RMXP | 🟡 18 recettes exactes/952, fallbacks | Les deux ont une couverture partielle ; les 316 `Move.register` PSDK concernent la mécanique, pas l'animation | P48/M13 |
| B42 | Fallback animation générique | ✅ | ✅ | PokeMap doit mesurer son taux de fallback | P48/M13 |
| B43 | Visuel 2D/Fake3D | ✅ Deux moteurs visuels | 🟡 Surface 2D, pas de Fake3D | Fake3D non prioritaire sans demande produit | P48/M13 |
| B44 | Transitions générationnelles | ✅ Assets nombreux | 🟡 Transitions présentes, couverture installée non certifiée | Nettoyer les références et certifier le build installé | P48/M13 |

### 4.6 Concours, online, mini-jeux et systèmes secondaires

| ID | Fonction PSDK | Réalité PSDK | PokeMap | Écart ou décision | Réf. |
|---|---|---|---|---|---|
| S01 | Concours à quatre participants | 🟡 Entrée moteur branchée depuis la map, aucun parcours sample prouvé | ❌ | Lot optionnel autonome | P49/M01 |
| S02 | Cinq manches, appeal/jam/enthousiasme | ✅ logique | ❌ | Ne pas coupler au moteur battle | P49/M01 |
| S03 | IA de concours | 🟡 Explicitement aléatoire | ❌ | PSDK n'est pas une cible de qualité ici | P49/M01 |
| S04 | Récompenses/rubans concours | 🟡 Non intégrés, événements requis | ❌ | À concevoir si le lot est retenu | P49/M04 |
| S05 | GTS | 🟡 Client legacy, service externe non certifié | 🚫 Online désactivé | Ne pas copier | P50/M01 |
| S06 | Échange online direct | ❌ Classe runtime absente | 🚫 | Pas un manque face à un flux fonctionnel | P50/M01 |
| S06b | Échange PNJ local | 🟡 Fonctionnel, évolution trade incluse, animation TODO | ❌ Parcours dédié non prouvé | Capacité RPG distincte de l'online | P50/M08 |
| S07 | P2P serveur/client | ❌ Modes déclarés, non programmés | 🚫 | Pas un manque face à un flux fonctionnel | P50/M01 |
| S08 | Hall of Fame | 🟡 API/système, parcours non certifié | ❌ dédié | Composer via Storyline/cinematic si besoin | P51/M04 |
| S09 | Mining | 🟡 Présent, parcours non certifié | ❌ | Plugin optionnel | P51/M01 |
| S10 | Voltorb Flip | 🟡 Présent, parcours non certifié | ❌ | Plugin optionnel | P51/M01 |
| S11 | Ruins of Alph puzzle | 🟡 Annoncé/présent dans les systèmes | ❌ | Plugin optionnel | P51/M01 |
| S12 | Machines à sous | 🟡 Présentes | ❌ | Faible priorité | P51/M01 |
| S13 | Horloge RSE | ✅ Système dédié | ❌ | Extension du futur système de temps | P52/M09 |
| S14 | Dynamic lights | ✅ Système dédié | 🟡 Primitives visuelles, parité non auditée | Extension visuelle optionnelle | P52/M13 |
| S15 | Map overlays | ✅ | 🟡 Présentation/cinématiques | Généraliser seulement avec cas produit | P52/M13 |
| S16 | Movie playback | ✅ Minimal | ✅ Vidéo/cinématiques/captions | Différenciateur PokeMap prouvé | P52/M13 |
| S17 | Soft reset F12 | ✅ | ❌ dédié | Non prioritaire sur plateformes Flutter | P53/M09 |
| S18 | Screenshot par commande | ✅ | ❓ | Outil QA possible, pas mécanique fangame | P51/M15 |
| S19 | Nuzlocke | ✅ Module | ❌ | Preset optionnel | P34/M01 |
| S20 | Achievements | ❌ | ❌ | Hors comparaison PSDK | P35/M04 |

## 5. Registre des preuves

### 5.1 PSDK et sample

Les chemins `PSDK/` désignent `/Users/karim/Project/pokemonProject autre dossiers/pokemonsdk-development/`. Les chemins `DEMO/` désignent `/Users/karim/Project/pokemonProject autre dossiers/pokémon_sdk_test_project/`.

| Réf. | Preuve principale |
|---|---|
| P00 | `PSDK/version.txt:1`; décodage dans `PSDK/scripts/tools/GameLoader/1_setupConstantAndLoadPath.rb:38-42` et `PSDK/maintenance/publish_release.rb:35-37` |
| P01 | `PSDK/README.md:31-41`; `PSDK/scripts/4 Systems/003 Map Engine/3 GamePlay/200 Scene_Map.rb:163-207` |
| P02 | `PSDK/scripts/1 RMXP Scripts/024 Interpreter_1.rb:55-145`; `PSDK/scripts/1 RMXP Scripts/026 Interpreter_3.rb:1-285`; `PSDK/scripts/1 RMXP Scripts/027 Interpreter_4.rb:3-239`; `PSDK/scripts/1 RMXP Scripts/028 Interpreter_5.rb:3-220` |
| P03 | `PSDK/scripts/2 PSDK Event Interpreter/100 Interpreter_Environnement.rb:9-157`; `PSDK/scripts/2 PSDK Event Interpreter/105 Interpreter_Camera.rb:7-18`; `PSDK/scripts/4 Systems/003 Map Engine/2 Logic/50 RMXP/700 Pathfinding.rb:34-127` |
| P04 | `PSDK/scripts/4 Systems/003 Map Engine/2 Logic/01 FollowMe/300 Core.rb:15-132` |
| P05 | `PSDK/scripts/4 Systems/003 Map Engine/2 Logic/03 Berries/700 BerryTrees.rb:13-202` |
| P06 | `PSDK/scripts/4 Systems/202 Environment/121 Weather.rb:3-154`; `PSDK/scripts/4 Systems/003 Map Engine/1 Graphics/902 Overworld Weather.rb:173-337` |
| P07 | `PSDK/scripts/4 Systems/003 Map Engine/1 Graphics/353 DayNightTint.rb:119-308`; `PSDK/scripts/4 Systems/202 Environment/122 Moon Phases.rb:10-122` |
| P08 | `PSDK/scripts/1 RMXP Scripts/021 Game_System.rb:35-159`; `PSDK/scripts/0 Dependencies/2 Audio/004 AudioChannels.rb:16-133` |
| P09 | `DEMO/Data/CommonEvents.rxdata.yml:2143-7925`; `PSDK/scripts/4 Systems/003 Map Engine/100 SystemTags.rb:11-150` |
| P10 | `PSDK/scripts/4 Systems/100 Menu/100 Menu.rb:216-307`; `PSDK/scripts/4 Systems/104 Trainer/400 Trainer.rb:30-155`; `PSDK/scripts/4 Systems/103 Bag/3 GamePlay/320 Bag_Choices.rb:25-80`; `PSDK/scripts/4 Systems/200 Storage/3 GamePlay/006 Actions.rb:47-159`; `PSDK/scripts/4 Systems/101 Dex/001 Pokedex.rb:86-374`; `PSDK/scripts/4 Systems/203 Shop/3 GamePlay/100 Shop.rb:3-95`; `PSDK/scripts/4 Systems/203 Shop/3 GamePlay/130 Shop_Actions.rb:14-121`; `PSDK/scripts/4 Systems/203 Shop/3 GamePlay/200 Pokemon_Shop.rb:3-33`; `PSDK/scripts/4 Systems/203 Shop/3 GamePlay/230 Pokemon_Shop_Actions.rb:15-24` |
| P11 | `PSDK/scripts/4 Systems/106 Save Load/001 Configs.rb:3-30`; `PSDK/scripts/4 Systems/106 Save Load/3 GamePlay/402 Save logic.rb:18-126`; `PSDK/scripts/4 Systems/105 Options/1 PFM/500 Options.rb:7-117`; `PSDK/scripts/4 Systems/105 Options/3 GamePlay/048 KeyBinding.rb:1-180` |
| P12 | `PSDK/scripts/5 Battle/01 Scene/104 Scene Event.rb:8-86`; `DEMO/Data/Events/Battle/00002 Demo.rb:6-92` |
| P14 | `PSDK/scripts/4 Systems/001 Title/003 Actions.rb:27-40` |
| P15 | `PSDK/README.md:18-21`; `DEMO/project.studio:2-35`; `DEMO/demo_version.txt:1` |
| P16 | `PSDK/scripts/tools/Studio/Handler.rb:15-78`; `PSDK/scripts/tools/Studio2PSDK.rb:54-105` |
| P17 | `DEMO/Data/Studio/abilities/overgrow.json:1-6`; `DEMO/Data/Studio/items/potion.json:1-17`; `DEMO/Data/Studio/moves/thunderbolt.json:1-51`; `DEMO/Data/Studio/pokemon/eevee.json:2-220`; `DEMO/Data/Studio/trainers/trainer_1.json:1-169`; `DEMO/Data/Studio/dex/poni.json:1-28`; `DEMO/Data/Studio/natures/hardy.json:1-16`; `DEMO/Data/Studio/types/fire.json:1-40`; `DEMO/Data/Studio/groups/group_19.json:1-61`; `DEMO/Data/Studio/zones/zone_0.json:1`; `DEMO/Data/Studio/worldmaps/0.json:1`; `DEMO/Data/Studio/maplinks/maplink_3.json:1-18`; `DEMO/Data/Studio/quests/quest_0.json:1-138`; `DEMO/Data/configs/settings_config.json:2-7`; `DEMO/Data/configs/display_config.json:1`; `DEMO/Data/Studio/maps/map003.json:2-25` |
| P18 | `PSDK/scripts/tools/PSDKEditor.rb:19-91` |
| P19 | `DEMO/scripts/HOW_TO_CREATE_A_CUSTOM_SCRIPT.md:82-105,195-215` |
| P20 | `PSDK/scripts/tools/PluginManager.rb:1-73,348-465` |
| P21 | `PSDK/scripts/3 Studio/400 Text.rb:24-180`; `PSDK/scripts/tools/EventText2CSV.rb:13-48`; `DEMO/project.studio:6-35`; `DEMO/Data/configs/language_config.json:2-9` |
| P22 | `PSDK/scripts/tools/Compilation/project_compilation.rb:27-231`; `PSDK/.gitlab-ci.yml:1-58` |
| P23 | `PSDK/scripts/tools/Debugger/Debug.rb:31-57`; `PSDK/scripts/tools/Debugger/Terminal.rb:17-69`; `PSDK/scripts/tools/AI/AISimulation.rb:14-39`; `PSDK/scripts/tools/ProjectToYAML.rb:32-80` |
| P24 | `DEMO/Data/Tiled/README_TILED.md:33-101`; `DEMO/Data/Tiled/Maps/rules.txt:1-4`; `DEMO/Data/Tiled/.jobs/map_jobs.json:1` |
| P25 | `PSDK/scripts/tools/Tiled2Rxdata/Tiled2Rxdata.rb:21-64`; `PSDK/scripts/tools/Tiled2Rxdata/map.rb:44-65,81-123`; `PSDK/scripts/tools/Tiled2Rxdata/animated_tiles.rb:34-50`; `PSDK/scripts/tools/Tiled2Rxdata/tile.rb:105-114,230-241` |
| P26 | `DEMO/Data/Animations/Particles.rb:1-121`; `DEMO/Data/Animations.rxdata.yml:3-96` |
| P27 | `PSDK/docs/SafeEvalCommand.md:348-361`; aucune implémentation `#safe:` ou `Data/EventCommands` trouvée |
| P28 | `PSDK/scripts/4 Systems/999 Wild/100 Wild Battle (manager).rb:1-294`; `PSDK/scripts/4 Systems/999 Wild/102 Encounter Count.rb:12-168` |
| P29 | `PSDK/scripts/4 Systems/000 General/1 PFM/2 Pokemon/001 Initialize.rb:18-235` |
| P30 | `PSDK/scripts/4 Systems/000 General/3 GameState/201 Management.rb:63-82` |
| P31 | `PSDK/scripts/4 Systems/201 Daycare/011 Daycare.rb:86-510`; `PSDK/scripts/4 Systems/303 Evolve/200 Hatch.rb:39-170` |
| P32 | `PSDK/scripts/4 Systems/000 General/1 PFM/2 Pokemon/600 Pokemon Skills.rb:3-134`; `PSDK/scripts/4 Systems/000 General/1 PFM/2 Pokemon/400 Pokemon exp & evolve.rb:33-149`; `PSDK/scripts/4 Systems/000 General/1 PFM/2 Pokemon/300 Pokemon EV.rb:3-72` |
| P33 | `PSDK/scripts/4 Systems/000 General/1 PFM/2 Pokemon/400 Pokemon exp & evolve.rb:164-270`; `PSDK/scripts/4 Systems/303 Evolve/100 Evolve.rb:19-120` |
| P34 | `PSDK/scripts/4 Systems/204 Nuzlocke/016 Nuzlocke.rb:24-81` |
| P35 | `PSDK/scripts/4 Systems/800 Quest/1 PFM/001 PFM Quests.rb:1-320`; `PSDK/scripts/4 Systems/800 Quest/1 PFM/002 PFM Quests Quest.rb:318-403` |
| P36 | `PSDK/scripts/5 Battle/04 Logic/0 Battle Info/001 Battle_Info.rb:3-212`; `PSDK/scripts/5 Battle/01 Scene/100 Scene.rb:28-169` |
| P37 | `PSDK/scripts/5 Battle/01 Scene/101 Scene Choice.rb:35-230` |
| P38 | `PSDK/scripts/5 Battle/04 Logic/102 Actions.rb:3-185`; `PSDK/scripts/5 Battle/04 Logic/104 end of battle phase & switch choice.rb:3-131`; `PSDK/scripts/5 Battle/04 Logic/106 Effects.rb:27-59` |
| P39 | `PSDK/scripts/5 Battle/10 Move/100 Move.rb:4-306`; `PSDK/scripts/5 Battle/10 Move/101 Damage_Calc.rb:3-45`; `PSDK/scripts/5 Battle/10 Move/120 Procedure.rb:35-517` |
| P40 | `PSDK/scripts/5 Battle/04 Logic/1 Handlers/103 StatusChangeHandler.rb:5-265`; `PSDK/scripts/5 Battle/06 Effects/06 Weather Effects/001 WeatherBase.rb:8-120`; `PSDK/scripts/5 Battle/06 Effects/07 Field Terrain Effects/100 Grassy.rb:31-34` |
| P41 | `PSDK/scripts/5 Battle/06 Effects/04 Ability Effects/001 AbilityBase.rb:14-45`; `PSDK/scripts/5 Battle/06 Effects/05 Item Effects/001 ItemBase.rb:11-40` |
| P42 | `PSDK/scripts/5 Battle/30 AI/200 GenericAI.rb:4-131`; `PSDK/scripts/5 Battle/30 AI/101 MoveActionFor.rb:16-99` |
| P43 | `PSDK/scripts/5 Battle/04 Logic/1 Handlers/108 FleeHandler.rb:13-60`; `PSDK/scripts/5 Battle/04 Logic/1 Handlers/111 BattleEndHandler.rb:38-327` |
| P44 | `PSDK/scripts/5 Battle/04 Logic/1 Handlers/109 CatchHandler.rb:5-235`; `PSDK/scripts/5 Battle/01 Scene/101 Scene Choice.rb:181-230` |
| P45 | `PSDK/scripts/5 Battle/04 Logic/400 MegaEvolve.rb:14-45`; `PSDK/scripts/5 Battle/01 Scene/101 Scene Choice.rb:71-108` |
| P46 | `PSDK/scripts/5 Battle/01 Scene/105 Safari.rb:16-169` |
| P47 | `PSDK/scripts/5 Battle/01 Scene/104 Scene Event.rb:8-86`; hook obsolète `DEMO/Data/Events/Battle/00003 PalbolskyBattle.rb:164-174` contre événement émis `PSDK/scripts/5 Battle/01 Scene/104 Scene Event.rb:30-34` |
| P48 | `PSDK/scripts/5 Battle/20 MoveAnimation/000 MoveAnimation.rb:10-116`; `PSDK/scripts/5 Battle/02 Visual/206 Show_stuff.rb:166-191`; 18 appels `MoveAnimation.register_specific_animation` dans 29 fichiers MoveAnimation |
| P49 | `PSDK/scripts/6 Contest/01 Scene/100 Scene.rb:24-130`; `PSDK/scripts/6 Contest/04 Logic/101 Round.rb:3-149`; `PSDK/scripts/6 Contest/30 AI/100 Base.rb:26-64`; entrée `PSDK/scripts/2 PSDK Event Interpreter/130 Interpreter_Sequences.rb:224-246` et appel map `PSDK/scripts/4 Systems/003 Map Engine/3 GamePlay/201 Scene_Map calling.rb:74-81` |
| P50 | `PSDK/scripts/4 Systems/901 GTS/09000 GTS.rb:48-65,782-923`; échange online cassé `PSDK/scripts/2 PSDK Event Interpreter/110 Interpreter_Pokemon.rb:230-235`; échange PNJ `PSDK/scripts/2 PSDK Event Interpreter/130 Interpreter_Sequences.rb:201-214`; P2P `PSDK/scripts/4 Systems/003 Map Engine/3 GamePlay/201 Scene_Map calling.rb:91-121` |
| P51 | Casino/Hall/mining `PSDK/scripts/2 PSDK Event Interpreter/120 Interpreter_Shortcut.rb:333-381`; screenshot `PSDK/scripts/2 PSDK Event Interpreter/120 Interpreter_Shortcut.rb:459-465`; Ruins `PSDK/scripts/4 Systems/900 Games/03 Ruine Alpha/00002 Ruine_Alpha_by_FL0RENT_.rb:1-14` |
| P52 | `PSDK/scripts/4 Systems/400 RSE Clock/004 RSEClock.rb:5-43`; `PSDK/scripts/4 Systems/951 DynamicLight/001 DynamicLight.rb:1-100`; `PSDK/scripts/4 Systems/952 MapOverlay/001 Overlay.rb:1-42`; `PSDK/scripts/4 Systems/950 Movie/099 Movie.rb:1-97` |
| P53 | `PSDK/scripts/9 Loaded Last/200 SoftReset.rb:1-52` |
| P54 | `DEMO/Game.rb:6-11`; résolution locale, `PSDK_BINARY_PATH`, puis `~/.pokemonsdk`; `DEMO/game-mac.sh:2-5` contient un chemin machine absolu périmé |
| P55 | `PSDK/scripts/9 Loaded Last/100 PSDK Tasks.rb:2-174`; `PSDK/scripts/9 Loaded Last/000 Rustine.rb:1-14` |
| P56 | No-op RMXP `PSDK/scripts/1 RMXP Scripts/029 Interpreter_6.rb:105-172`; `PSDK/scripts/1 RMXP Scripts/030 Interpreter_7.rb:4-52`; API Pokémon `PSDK/scripts/2 PSDK Event Interpreter/110 Interpreter_Pokemon.rb:8-191` |
| P57 | `PSDK/scripts/tools/Rxdata2Tiled/Rxdata2Tiled.rb:1-22`; non-écrasement dans `PSDK/scripts/tools/Rxdata2Tiled/map.rb:55-60` et `PSDK/scripts/tools/Rxdata2Tiled/tileset.rb:39-51` |
| P58 | `PSDK/scripts/tools/AutoUpdate/AutoUpdate.rb:10-87`; `PSDK/maintenance/make_update.rb:1-93` |
| P59 | `PSDK/scripts/tools/PARGV.rb:241-258`; `PSDK/scripts/tools/Debugger/WorldMapEditor.rb:6-136`; `PSDK/scripts/tools/Editors/SystemTags.rb:13-249`; `PSDK/scripts/tools/SwooshTextImport.rb:52-60`; `PSDK/scripts/tools/Text2CSV.rb:1-25`; `PSDK/scripts/tools/StateMachineBuilder/StateMachineBuilder.rb:90-130`; `PSDK/scripts/tools/Tester.rb:68-73`; `PSDK/scripts/tools/SaveToPicture.rb:1-80`; `PSDK/scripts/tools/take_map_snap.rb:1-49` |
| P60 | `PSDK/maintenance/make_release.rb:62-69`; `PSDK/maintenance/make_update.rb:1-93`; `PSDK/maintenance/publish_release.rb:20-82`; `PSDK/maintenance/treeshake.rb:1`; `PSDK/maintenance/sign_data.rb:1-14` |
| P62 | Ability effect `PSDK/scripts/5 Battle/06 Effects/04 Ability Effects/050 BoostingMoveType.rb:12-50`; item class `PSDK/scripts/3 Studio/2 Data/0 Item/003 HealingItem.rb:1-22` |

### 5.2 PokeMap

| Réf. | Preuve principale |
|---|---|
| M01 | `packages/map_core/lib/src/models/pokemon_ruleset_profile.dart:17,70-74`; breeding, doubles, modern gimmicks et online explicitement désactivés |
| M02 | `packages/map_core/lib/src/models/map_data.dart:24-46`; `packages/map_authoring/lib/src/application/map_mutation_dispatcher.dart:75-381` |
| M03 | `packages/map_authoring/test/parity/full_authoring_parity_test.dart:171-181,233-249`; quatre transports certifiés pour les actions enregistrées couvertes, pas pour tout l'authoring ; transports items globaux vides |
| M04 | `packages/map_core/lib/src/models/storyline_asset.dart:9-205`; `packages/map_core/lib/src/read_models/narrative_command_catalog.dart:3-430`; `examples/playable_runtime_host/test/selbrume_canonical_narrative_campaign_test.dart:297-377` |
| M05 | `packages/map_core/lib/src/models/project_manifest.dart:1074-1137`; `packages/map_gameplay/lib/src/field_action.dart:15-22,69-105,176-200`; `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:4725-4727` |
| M06 | `packages/map_battle/lib/src/application/battle_session_facade.dart:50-69`; `packages/map_battle/lib/src/domain/battle/battle_setup.dart:68-73`; `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart:41-1470` |
| M07 | `packages/map_battle/lib/src/data/psdk_parity_gate.dart:12-22`; `packages/map_battle/lib/src/data/battle_parity_target.dart:84-172` |
| M08 | `packages/map_gameplay/lib/src/battle_progression_service.dart:119-335`; `packages/map_gameplay/lib/src/pokemon_evolution_service.dart:293-481` |
| M09 | `packages/map_core/lib/src/models/save_data.dart:152-800`; `packages/map_runtime/lib/src/player/runtime_player_coordinator.dart:897-942`; `packages/map_runtime/test/playable_map_game_save_load_transaction_test.dart:15-108`; `packages/map_runtime/test/player/runtime_player_coordinator_lifecycle_test.dart:47-128` |
| M10 | `packages/map_runtime/test/player/runtime_pc_service_test.dart:6-432` |
| M11 | `packages/map_gameplay/lib/src/project_item_effect_support.dart:36-48`; `packages/map_core/lib/src/read_models/item_capability_truth.dart:77-110`; `packages/map_runtime/test/player/runtime_shop_service_test.dart:33-258`; `packages/map_runtime/test/player/runtime_heal_service_test.dart:33-169` |
| M12 | `packages/map_core/lib/src/models/pokemon_project_data.dart:207-970`; `packages/map_battle/test/psdk_ability_registry_manifest_test.dart:293-315` |
| M13 | `packages/map_core/lib/src/models/project_media_catalog.dart:1-310`; `packages/map_core/lib/src/models/cinematic_asset.dart:7-70`; `packages/map_runtime/test/flame_cinematic_runtime_playback_sink_test.dart:49-167`; `packages/map_runtime/test/battle_animation_visual_source_report_test.dart:18-25` |
| M14 | `packages/map_authoring/lib/src/domains/gameplay/battle_actions.dart:42-45`; `packages/map_authoring/lib/src/domains/gameplay/progression_actions.dart:55-61`; imports sous `packages/map_editor/lib/src/infrastructure/external/` |
| M15 | `packages/map_editor/test/game_export/game_package_export_service_test.dart:66-90`; `examples/playable_runtime_host/test/phase_7a_installed_golden_journey_test.dart:22-100`; preuves présentes dans le dépôt mais non rejouées pendant cet audit |
| M16 | `examples/playable_runtime_host/lib/src/golden_item_system_journey.dart:645`; `packages/map_runtime/lib/src/application/battle_start_request.dart:63`; `packages/map_editor/test/trainer_library_panel_test.dart:326,528` |
| M17 | `.github/workflows/pokemap_quick_checks.yml:31-79`; quick checks Hub, roadmap core et editor avec Flutter épinglé |
| M18 | `packages/map_core/lib/src/models/save_data.dart:152-165`; `packages/map_gameplay/lib/src/pokemon_stat_calculator.dart:289-300`; recherche négative R18 ci-dessous |

Recherche négative R18, rejouée sans résultat :

```bash
rg -n -i 'pokerus|pokérus|poke.?rus' packages examples tools -g '*.dart' -g '*.json'
```

## 6. Ce qui est mieux aligné avec les contraintes produit PokeMap

| Différenciateur | PokeMap | Limite PSDK observée |
|---|---|---|
| Autorité des données | Projet PokeMap canonique | Données réparties entre Studio, Tiled, RXDATA, Ruby et caches |
| Éditeur unifié | Studios Flutter et design system | UI Studio externe non disponible dans le snapshot ; RMXP encore requis |
| API d'authoring | Direct, JSONL, Editor et MCP pour les actions enregistrées couvertes ; couverture globale encore partielle | Bridge Studio limité à quelques opérations |
| Transactions | Révisions, receipts, validations et undo ciblés | Outils legacy souvent mutateurs sans transaction |
| No-code narratif | Catalogue de commandes borné et structuré | Interpréteur RMXP et scripts Ruby arbitraires |
| Smart Tiles | Sémantique terrain/comportement native | SystemTags et couches Tiled nommées strictement |
| Cinématiques | Audio, vidéo, captions, timelines et authoring | Movie minimal et animations largement externes/manuelles |
| Validation | Capability truth et validateurs projet | Gardes structurelles partielles, sans validation globale des références/unicités ; cache insuffisamment invalidé |
| Tests | Suites package-scoped, golden slices, parité transport | Tests moteur disparates, sample non certifié par CI |
| Distribution | Archive `.avelunegame` et Hub | Dossier Release sans signature/notarisation prouvée |
| Sécurité d'extension | Pas d'exécution arbitraire utilisateur dans le flux normal | Plugins/scripts Ruby exécutables et dépendances téléchargeables |
| Multi-plateforme | Flutter desktop/mobile | PSDK centré sur son runtime historique |

## 7. Défauts et limites identifiés dans le snapshot PSDK

PSDK ne doit pas être traité comme une spécification parfaite. L'audit a identifié notamment :

- ordre de `Poison Touch` et ability `Stall` encore TODO ;
- `Move#clone` lève volontairement une exception ;
- réduction de dégâts du Grassy Terrain compare les moves au symbole du terrain ;
- modificateurs Safari calculés avec `clamp` sans conserver le résultat ;
- hook de démo `battle_phase_end` alors que le moteur émet `battle_turn_end` ;
- trade online direct vers une classe `GamePlay::Trade` absente, tandis que l'échange PNJ local existe ;
- modes P2P déclarés mais non programmés ;
- GTS sur service tiers historique avec configuration HTTP ;
- commande « safe eval » documentée mais non implémentée ;
- concours avec IA aléatoire et récompenses non intégrées ;
- autosave absent ;
- fallback `data_map_link` renvoyant un placeholder de dex ;
- flip diagonal Tiled lu mais non appliqué ;
- cache `psdk.dat` considéré valide par simple existence ;
- Studio UI, validations, undo et imports interactifs impossibles à certifier sans son dépôt ;
- projet sample pouvant charger un autre PSDK local que le snapshot audité.

## 8. Roadmap et proposition de séquençage

### Lots concernés

- `FG-000 — Fangame Mechanics Readiness Audit V0` : **PARTIAL**. Cet audit apporte l'inventaire comparatif majeur, mais ne remplace pas la certification fraîche de chaque lot FG et de chaque surface installée.
- `FG-200+ — Advanced parity` : **DEFERRED**, inchangé. Les fonctions secondaires ne deviennent pas des critères de bêta.
- `POST-SYS-004` : **TO REVIEW** après trois contre-relectures finales sans blocage.

### Séquence recommandée

1. Réparer les deux régressions fraîches Item/Trainer afin de restaurer une base de preuve propre.
2. Fermer la chaîne terrain/encounters : field moves, pêche/headbutt/roaming, repel et movement effects.
3. Ajouter le journal de quêtes comme projection des Storylines existantes.
4. Compléter l'authoring abilities/items/trainers avant d'élargir le corpus.
5. Activer les combats doubles de bout en bout, puis seulement leurs variantes.
6. Créer le monde vivant : temps, météo, baies et followers.
7. Ajouter breeding/œufs après PC et progression, conformément à un lot post-bêta dédié.
8. Traiter concours, Safari, Nuzlocke et mini-jeux comme modules optionnels.
9. Laisser online hors cible tant qu'un besoin produit et un modèle de sécurité ne sont pas explicites.

## 9. Vérifications exécutées

### 9.1 Tests ciblés pilotés par l'audit

| Commande | Résultat exact |
|---|---|
| `cd packages/map_core && dart test test/pokemon_ruleset_profile_test.dart test/project_capability_truth_test.dart` | `+15: All tests passed!` |
| `cd packages/map_gameplay && dart test test/pokemon_gameplay_rules_test.dart` | `+3: All tests passed!` |
| `cd packages/map_battle && dart test test/psdk_registry_manifest_test.dart test/psdk_final_parity_gate_test.dart test/psdk_battle_topology_test.dart` | `+67: All tests passed!` |
| `cd packages/map_battle && dart test test/psdk_parity_gate_test.dart test/psdk_final_parity_gate_test.dart test/battle_parity_target_test.dart test/psdk_ability_registry_manifest_test.dart` | `+21: All tests passed!` |
| `cd packages/map_authoring && dart test test/parity/full_authoring_parity_test.dart test/domains/gameplay/campaign_content_authoring_test.dart test/domains/gameplay/item_catalog_actions_test.dart` | `+27: All tests passed!` |
| `cd examples/playable_runtime_host && flutter test test/golden_fangame_slice_e2e_test.dart` | `+1: All tests passed!` |

### 9.2 Défauts et incidents frais

| Commande/passe | Résultat |
|---|---|
| `cd packages/map_authoring && dart test test/parity/full_authoring_parity_test.dart test/domains/gameplay/campaign_content_actions_test.dart test/domains/gameplay/item_catalog_actions_test.dart` | `+23 -1` ; erreur opérateur, fichier `campaign_content_actions_test.dart` inexistant, puis commande corrigée verte |
| `cd examples/playable_runtime_host && flutter test test/golden_fangame_slice_e2e_test.dart test/golden_item_system_flow_test.dart test/phase_a_golden_slice_launch_test.dart test/selbrume_canonical_narrative_campaign_test.dart` | `+16 -2` ; `examples/playable_runtime_host/lib/src/golden_item_system_journey.dart:645` passe encore `zoneId`, supprimé de `WildBattleStartRequest` |
| `cd packages/map_editor && flutter test test/trainer_library_panel_test.dart` | `+14 -2` ; dropdowns sans Leftovers/Oran Berry aux lignes de test 326 et 528 |
| `cd examples/playable_runtime_host && flutter test test/golden_fangame_slice_e2e_test.dart test/selbrume_player_journey_e2e_test.dart` | Exit `137` après `+5`, deux tests Selbrume « did not complete » ; passe inconclusive, harness concurrents réapés |

Les harness Flutter ont été réapés après les suites. Aucun test PSDK runtime, service GTS, Studio, Tiled ou RMXP n'a été lancé : l'audit PSDK repose sur le code Ruby local et le contenu du sample, conformément à la règle qui fait du source Ruby l'oracle de parité.

### 9.3 Analyse et build

- Aucun code Dart, Flutter, TypeScript ou Ruby n'a été modifié.
- `dart analyze`, `flutter analyze` et les builds produit sont **N/A pour le diff documentaire** ; les tests ciblés servent uniquement à qualifier les affirmations de parité actuelles.
- Une certification visuelle d'un build installé reste nécessaire pour les transitions, animations et parcours Hub finaux.
- Validateur inline des références `path:line` : `212` références vérifiées, `0` chemin ou ligne invalide.
- Validateur inline des colonnes de tableaux Markdown : `table_column_issues=0`.
- `bash tools/scripts/check_markdown_hygiene.sh` : échec attendu, la limite par défaut est zéro nouveau Markdown.
- `POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh` : `Markdown hygiene: 1 new Markdown file(s), all in canonical locations.`

### 9.4 Commandes d'inventaire reproductibles

Variables utilisées :

```bash
PSDK_ROOT='/Users/karim/Project/pokemonProject autre dossiers/pokemonsdk-development'
DEMO_ROOT='/Users/karim/Project/pokemonProject autre dossiers/pokémon_sdk_test_project'
```

Comptage moteur et Studio :

```bash
find "$PSDK_ROOT/scripts" -type f -name '*.rb' | wc -l
find "$PSDK_ROOT/scripts/3 Studio" -type f -name '*.rb' | wc -l
find "$PSDK_ROOT/scripts/3 Studio" -type f -name '*.rb' -print0 | xargs -0 wc -l | tail -1
find "$DEMO_ROOT/Data/Studio" -type f | wc -l
find "$DEMO_ROOT/Data/Studio" -type f -name '*.json' | wc -l
find "$DEMO_ROOT/Data/Studio/events" -type f | wc -l
```

Résultats : `1518`, `40`, `3389 total`, `2866`, `2863`, `0`.

Sous-arbres moteur et catégories Studio :

```bash
for d in '4 Systems' '5 Battle' '6 Contest' tools; do
  printf '%s=' "$d"
  find "$PSDK_ROOT/scripts/$d" -type f -name '*.rb' | wc -l
done
for d in abilities dex groups items maplinks maps moves natures pokemon quests trainers types worldmaps zones; do
  printf '%s=' "$d"
  find "$DEMO_ROOT/Data/Studio/$d" -type f -name '*.json' | wc -l
done
```

Résultats moteur : `4 Systems=384`, `5 Battle=907`, `6 Contest=55`, `tools=59`.

Résultats Studio : `abilities=233`, `dex=8`, `groups=26`, `items=935`, `maplinks=21`, `maps=21`, `moves=728`, `natures=25`, `pokemon=807`, `quests=3`, `trainers=14`, `types=18`, `worldmaps=4`, `zones=18`.

Comptage Tiled, plugins et localisation :

```bash
find "$DEMO_ROOT/Data/Tiled" -type f -name '*.tmx' | wc -l
find "$DEMO_ROOT/Data/Tiled/Maps" -maxdepth 1 -type f -name '*.tmx' | rg -v '/rules_' | wc -l
find "$DEMO_ROOT/Data/Tiled/Maps" -maxdepth 1 -type f -name '*.tmx' | rg '/rules_' | wc -l
find "$DEMO_ROOT/Data/Tiled" -type f -name '*.tsx' | wc -l
find "$DEMO_ROOT/Data/Tiled/Assets" -type f -name '*.png' | wc -l
find "$DEMO_ROOT/Data/Tiled/Overviews" -type f | wc -l
find "$DEMO_ROOT/plugins" -maxdepth 1 -type f -name '*.rb' | wc -l
find "$DEMO_ROOT" -type f -name '*.psdkplug' | wc -l
find "$DEMO_ROOT" -type f -name 'plugins.dat' | wc -l
find "$DEMO_ROOT/Data/Text/Dialogs" -type f -name '*.csv' | wc -l
find "$DEMO_ROOT/Data/Text/Dialogs" -type f -name '*.en.dat' | wc -l
find "$DEMO_ROOT/Data/Text/Studio" -type f -name '*.csv' | wc -l
```

Résultats : `26` TMX au total, `22` maps/template, `4` rules, `21` TSX, `21` PNG, `21` overviews, `30` utilities Ruby, `0` `.psdkplug`, `0` `plugins.dat`, `111` CSV, `111` caches `.en.dat`, `6` CSV Studio.

Comptage des registres et objets YAML :

```bash
rg -g '*.rb' '^Battle::MoveAnimation\.register_specific_animation' "$PSDK_ROOT/scripts/5 Battle/20 MoveAnimation" | wc -l
find "$PSDK_ROOT/scripts/5 Battle/20 MoveAnimation" -type f -name '*.rb' | wc -l
rg -g '*.rb' 'Move\.register' "$PSDK_ROOT/scripts/5 Battle" | wc -l
rg -g '*.rb' '^\s+register\(:' "$PSDK_ROOT/scripts/5 Battle/06 Effects/04 Ability Effects" | wc -l
rg -g '*.rb' '^\s+register\(:' "$PSDK_ROOT/scripts/5 Battle/06 Effects/05 Item Effects" | wc -l
rg -c '^- !ruby/object:RPG::Animation\r?$' "$DEMO_ROOT/Data/Animations.rxdata.yml"
rg -c '^  - !ruby/object:RPG::Animation::Timing\r?$' "$DEMO_ROOT/Data/Animations.rxdata.yml"
rg -c '^- !ruby/object:RPG::CommonEvent\r?$' "$DEMO_ROOT/Data/CommonEvents.rxdata.yml"
rg '^  name:' "$DEMO_ROOT/Data/CommonEvents.rxdata.yml" | sed 's/^  name: //' | rg -v "^(''|\"\"|~)?\r?$"
rg '^  name:' "$DEMO_ROOT/Data/CommonEvents.rxdata.yml" | sed 's/^  name: //' | rg -v "^(''|\"\"|~)?\r?$" | rg -v '^\"--- Reserved\"\r?$' | wc -l
rg '^  [0-9]+: !ruby/object:RPG::Event\r?$' "$DEMO_ROOT"/Data/Map*.rxdata.yml | wc -l
```

Résultats : `18` animations spécifiques dans `29` fichiers, `316` registrations de mécaniques move, `271` abilities, `176` items, `874` animations, `2249` timings, `100` slots Common Events, `50` noms non vides dont `5` réservés et donc `45` noms non réservés, `482` événements de map.

Comptage de contenu :

```bash
find "$DEMO_ROOT/graphics/pokedex" -type f | wc -l
find "$DEMO_ROOT/graphics" -type f | wc -l
find "$DEMO_ROOT/graphics/characters" -type f | wc -l
find "$DEMO_ROOT/graphics/animations" -type f | wc -l
find "$DEMO_ROOT/graphics/transitions" -type f | wc -l
find "$DEMO_ROOT/audio/se" -type f | wc -l
find "$DEMO_ROOT/audio" -type f | wc -l
find "$DEMO_ROOT/audio/bgm" -type f | wc -l
find "$DEMO_ROOT/audio/me" -type f | wc -l
find "$DEMO_ROOT/audio/particles" -type f | wc -l
find "$DEMO_ROOT/audio/bgs" -type f | wc -l
```

Résultats : `12357` graphismes au total, dont `7460` Pokédex, `2468` characters, `181` animations et `79` transitions ; `1331` audios au total, dont `1170` SE, `99` BGM, `27` ME, `20` particules et `14` BGS.

Les premiers essais `rg` non ancrés sur les YAML ont volontairement été rejetés : ils comptaient aussi les objets imbriqués. Seuls les motifs ancrés ci-dessus soutiennent les agrégats du rapport.

## 10. Fichiers, diff et état Git

### État initial

- Branche : `main`
- HEAD : `6ee23f76904c9e47f5510361902279a8b7d29312`
- Relation remote : `main...origin/main [ahead 1]`
- Worktree : propre

### Fichier créé

- `documentation/reports/gameplay/audit_parite_fonctionnelle_psdk_pokemap_2026-08-24.md`
  - métadonnées et méthode ;
  - verdict par domaine ;
  - liste priorisée des manques ;
  - matrice exhaustive par famille ;
  - registre de preuves ;
  - différenciateurs et défauts PSDK ;
  - roadmap, vérifications, risques et critique finale.

### Zones modifiées

Aucun fichier produit n'a été modifié. Le diff attendu est un unique nouveau rapport Markdown.

### État final

```text
?? documentation/reports/gameplay/audit_parite_fonctionnelle_psdk_pokemap_2026-08-24.md
```

## 11. Verdict des passes spécialisées

| Passe | Verdict |
|---|---|
| Audit moteur/gameplay PSDK | **PASS après correction** — animations, Common Events, trades, hooks et Loaded Last distingués et prouvés |
| Audit Studio/data/tooling PSDK | **PASS après correction** — pipeline, compteurs, outils, assets et commandes reproductibles vérifiés |
| Audit PokeMap | **PASS avec réserves produit** — statuts stricts et preuves validés ; Golden Item et Trainer Studio restent rouges |
| Implémentation | **N/A** — aucune implémentation demandée ni réalisée |
| Tests | **PARTIAL** — preuves ciblées vertes, deux régressions produit et une passe exit 137 documentées |
| Build/validation installée | **N/A / non rejouée** — audit documentaire, aucun nouvel artefact produit |

## 12. Limites, risques et auto-critique

### Limites

1. Le dépôt de l'interface Pokémon Studio n'est pas présent ; ses écrans, validations, undo et workflows réels ne sont pas certifiés.
2. PSDK et le sample n'ont pas de métadonnées Git ; le snapshot ne peut pas être rattaché à un SHA upstream.
3. L'exhaustivité porte sur les familles fonctionnelles, pas sur l'exécution individuelle de chaque move, item, ability ou animation.
4. Les résultats visuels ne sont pas acceptés sur la seule base de tests ; aucune comparaison côte à côte PSDK/PokeMap installée n'a été menée.
5. Quelques absences sont établies par recherche statique négative ; elles devront être réévaluées si du code externe ou un plugin est ajouté au périmètre.
6. Le sample peut charger un PSDK différent via ses chemins de résolution (`P54`) ; aucune exécution du sample n'a donc été utilisée comme preuve.

### Risques de mauvaise décision

- Compter un modèle comme une fonctionnalité joueur ferait surévaluer PokeMap.
- Compter un fichier Ruby comme un flux fonctionnel ferait surévaluer PSDK.
- Chercher une identité générationnelle stricte partout ferait perdre les avantages de rulesets explicites.
- Importer des systèmes secondaires avant de fermer terrain/rencontres/quêtes fragmenterait la roadmap.
- Copier les hooks Ruby ou le pipeline RMXP introduirait une dette contraire au no-code et à l'autorité des données PokeMap.

### Auto-critique finale

Le rapport privilégie volontairement une granularité de « capacité produit » plutôt qu'un inventaire de symboles. C'est la seule comparaison utile : 907 fichiers de combat ne valent pas 907 fonctionnalités, pas plus qu'un enum `breeding` ne vaut une pension jouable. La matrice peut encore être enrichie ultérieurement par trois audits spécialisés — fidélité visuelle move par move, couverture canonique ability/item/move, et parcours UI installé — mais elle est suffisante pour orienter provisoirement les lots post-bêta et écarter les curiosités Ruby sans valeur produit démontrée.

## 13. Conclusion

PokeMap n'a pas besoin de devenir PSDK avec une autre peinture. Il doit devenir le moteur que PSDK aurait été avec une autorité de données unique, un vrai no-code, des contrats sûrs et des preuves reproductibles — tout en récupérant progressivement la profondeur mécanique que PSDK a accumulée.

La priorité raisonnable est donc : **terrain et rencontres avancées → quêtes joueur → authoring Pokémon complet → doubles → monde vivant → breeding**, puis seulement les modules secondaires. Le reste peut attendre sagement dans la Poké Ball, sans invoquer trois éditeurs externes et un démon mineur en Ruby pour arroser une baie.
