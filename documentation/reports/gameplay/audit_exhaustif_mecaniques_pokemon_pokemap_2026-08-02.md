# Audit exhaustif des mécaniques Pokémon de PokeMap

**Nom de l'audit :** `FG-AUDIT-POKEMON-MECHANICS-2026-08-02`  
**Date :** 2 août 2026  
**Nature :** audit documentaire, produit, architecture, code, runtime et parité d'authoring  
**Périmètre :** moteur de fangames Pokémon générique ; aucun contenu propre à un fangame particulier  
**Roadmap examinée :** `pokemap_roadmap_mecaniques_fangame.md`  
**Verdict global :** `PARTIAL — moteur Pokémon MVP crédible, moteur Pokémon complet non atteint`

---

## 0. Addendum de cadrage produit — combat et catalogue Générations I à IX

Une décision produit postérieure à la passe d'audit précise la cible :

- **l'aventure** reste classique, structurée et inspirée de la Génération V ;
- **la première surface joueur** reste centrée sur les combats singles ;
- **le moteur de combat** doit être aussi complet, data-driven et extensible que
  possible, sans être limité aux règles ou au contenu de la Génération V ;
- **toutes les espèces de Pokémon des Générations I à IX** doivent pouvoir être
  présentes dans un projet et utilisées en combat ;
- les formes standards, les 18 types standards — Fairy compris —, les moves, talents
  et objets de combat nécessaires à ces Pokémon entrent dans la cible moteur ;
- Stellar et les transformations dépendant exclusivement de Mega, Z-Moves, Dynamax,
  Gigamax ou Téracristallisation restent indisponibles tant que ces gimmicks sont
  explicitement au parking ;
- fournir tous les Pokémon en combat ne rend pas immédiatement obligatoires toutes
  leurs méthodes canoniques d'obtention ou d'évolution postérieures à la Génération V ;
- reproduction, saisons et Dive rejoignent également le parking explicite ;
- doubles, Triple et Rotation restent à traiter après la première boucle singles
  stable.

Cet addendum remplace toute formulation plus bas qui limiterait le **catalogue Pokémon
ou le moteur de combat** aux Générations I à V. Les limitations I–V restantes doivent
être comprises comme le périmètre initial de l'aventure, de la progression et des
méthodes d'obtention. Le gap proposé `FG-208` doit donc séparer un **Battle Ruleset
I–IX** d'un **Adventure Scope classique**, et non figer tout le moteur sur la
Génération V.

---

## 1. Résumé exécutif

Oui, il manque encore beaucoup de mécaniques Pokémon.

PokeMap n'est toutefois plus un simple éditeur de cartes. Le dépôt contient déjà une
boucle RPG implémentée et historiquement couverte — nouvelle partie, starter,
exploration, événements, rencontres, combat, capture, progression, équipe, boîtes,
sac, boutiques, soins, dresseurs, récompenses, sauvegarde et menus joueur — mais elle
n'est pas recertifiée au `HEAD` actuel. Les tests purs relancés pendant cet audit
confirment une partie importante de ce socle ; le runtime Flutter reste bloqué par le
chantier Smart Tiles.

Le problème principal est désormais la **profondeur de fidélité Pokémon** et non
l'absence totale de boucle de jeu. Quatre constats structurants dominent l'audit :

1. **Il n'existe pas de profil global de règles Pokémon versionné.** Le moteur utilise
   aujourd'hui une cible hybride : certaines règles sont modernes, d'autres sont des
   variantes PokeMap simplifiées. Cela est explicitement reconnu par
   `BattleParityTarget.canonicalV1`.
2. **Le kernel de combat est très en avance sur la surface joueur.** Il possède une
   couverture PSDK importante, des effets, talents, objets, terrains, météo et un
   début de support multi-slot ; mais la boucle runtime jouée reste essentiellement
   pensée en singles, et le document de parité déclare encore dégâts et statuts
   `PARTIAL`, les speed ties en `GAP`, l'XP et la capture en variantes intentionnelles.
3. **Le modèle persistant d'un Pokémon est insuffisant pour les systèmes avancés.** Il
   conserve déjà niveau, XP, IV, EV, nature, talent, sexe, moves, PP, PV, statut,
   shiny, objet tenu, surnom, amitié et provenance. Il lui manque notamment un ID
   d'individu stable, la forme, l'OT complet, la langue, l'état œuf, les rubans,
   marques et données générationnelles.
4. **La roadmap canonique est en retard sur le code.** Des éléments encore notés
   `TODO` ou `PARTIAL` dans la roadmap ont désormais des contrats, UI, chemins runtime
   et tests : New Game, starter, menus pause, Pokédex simple, PC, TM/HM, cycle de
   dresseur et rematches. Elle doit être rebaselinée avant d'être utilisée comme
   vérité de statut.

La décision produit prise après cet audit est plus étroite : construire d'abord un
**fangame classique inspiré de la Génération V, en singles**. Les règles doivent être
versionnées, mais un seul profil est actif pour le moment. Les combats doubles seront
réévalués après stabilisation des singles. Les mécaniques modernes listées à la
section 1.1 sont explicitement sorties de la roadmap active, et la branche `Legends`
est exclue.

### Verdict produit

| Promesse | Verdict |
|---|---|
| « Créer un petit fangame Pokémon singles jouable » | **Crédible, avec limites et validation runtime actuellement bloquée par le chantier Smart Tiles** |
| « Créer un fangame Pokémon classique riche » | **Partiel** |
| « Reproduire fidèlement une génération donnée » | **Non, faute de ruleset global et de parité complète** |
| « Créer n'importe quel jeu Pokémon de Générations I à IX » | **Non** |
| « Fournir doubles, élevage, échange, temps vivant et field moves complets » | **Non ou très partiel** |
| « Authorer toutes les mécaniques sans code, via UI/API/MCP » | **Non, parité partielle** |

### 1.1 Décision produit — cible Génération V classique

| Élément | Décision actuelle |
|---|---|
| Direction générale | Jeu classique inspiré Génération V, pas une reproduction de `Legends` |
| Combat | Singles uniquement pour la première cible stable |
| Doubles, Triple et Rotation | `LATER` — aucun lot actif avant la stabilité des singles |
| Structure du monde | Routes, villes, donjons et progression structurée ; pas d'open world |
| Rencontres | Rencontres aléatoires en herbe, grotte et eau ; rencontres statiques scriptées autorisées |
| Sauvegarde | Sauvegarde manuelle ; autosave mis de côté |
| Types | Profil Génération V par défaut : 17 types, sans Fairy ni Stellar |
| Moves | Split physique/spécial par attaque ; TM réutilisables, sans crafting |
| Pokémon | Talents, objets tenus, natures, IV/EV, amitié et formes compatibles avec la cible I–V |
| Terrain | Field abilities/HM classiques ou abstraction équivalente ; pas de système Ride Génération VII |
| Temps | Jour/nuit et saisons compatibles avec la cible Génération V, à implémenter après le cœur singles |
| Capture | Capture classique en combat ; capture critique Génération V à traiter dans le ruleset |

Cette cible est « inspirée Génération V » : elle fixe une direction cohérente sans
obliger PokeMap à reproduire tous les bugs, contenus ou formats annexes de Noir/Blanc.

### 1.2 Parking explicite

| Mécanique | Décision | Définition utile |
|---|---|---|
| `Pokémon Legends` | `EXCLUDED` | Pas de capture en temps réel, dégâts au joueur, furtivité ou action speed |
| Mega Evolution | `PARKED` | Gimmick de Génération VI |
| Z-Moves | `PARKED` | Gimmick de Génération VII |
| SOS | `PARKED` | Renforts de Pokémon sauvages en combat, introduits en Génération VII |
| Ride remplaçant les HM | `PARKED` | Montures/services terrain de Génération VII remplaçant les capacités de l'équipe |
| Dynamax/Gigamax | `PARKED` | Gimmick de Génération VIII |
| Raids | `PARKED` | Combats coopératifs Max/Téra et règles de boss associées |
| Spawns visibles | `PARKED` | Pokémon sauvages affichés et mobiles sur la carte avant le combat ; ce n'est pas une rencontre statique scénarisée |
| Autosave | `PARKED` | Sauvegarde automatique ; la cible actuelle reste manuelle |
| Mints | `PARKED` | Objets changeant l'effet statistique d'une nature sans changer sa nature d'origine |
| Téracristallisation | `PARKED` | Gimmick de Génération IX |
| Open world | `PARKED` | Monde ouvert continu et progression libre |
| Auto-battle | `PARKED` | Combat automatique lancé dans l'overworld |
| Pique-nique | `PARKED` | Système Génération IX lié aux œufs, repas et interactions |
| Crafting de TM | `PARKED` | Fabrication de TM avec matériaux ; la cible Génération V utilise des TM réutilisables |
| Doubles, Triple, Rotation | `LATER` | Réévaluation uniquement après une boucle singles Génération V stable |

`PARKED` signifie : documenté pour ne pas l'oublier, mais sans lot actif, sans critère
de release et sans influence sur l'architecture immédiate. `EXCLUDED` est plus fort :
la branche `Legends` ne fait pas partie de la direction produit actuelle.

---

## 2. Méthode, définitions et limites

### 2.1 Niveaux de priorité du référentiel

| Niveau | Définition |
|---|---|
| `P0` | Indispensable pour annoncer un moteur de fangame Pokémon jouable |
| `P1` | Attendu d'un moteur Pokémon local réellement complet |
| `P2` | Avancé, compétitif, post-game ou QoL riche |
| `P3` | Gimmick générationnel, online ou expérience spéciale |

### 2.2 Statuts utilisés pour PokeMap

| Statut | Définition |
|---|---|
| `DONE` | Contrat complet au périmètre déclaré et appuyé par des preuves fraîches |
| `PARTIAL` | Une partie existe, mais la fidélité, la surface joueur, l'authoring ou les preuves sont incomplètes |
| `ABSENT` | Aucun système jouable cohérent trouvé ; une enum ou un champ ne suffit pas |
| `UNVERIFIED` | Code trouvé, mais validation fraîche impossible ou incomplète |

Le caractère MVP, avancé ou optionnel est porté par la colonne `Priorité`, pas par le
statut.

Une mécanique n'est considérée comme complète que si les couches nécessaires sont
alignées :

```text
modèle de données -> règles pures -> runtime -> surface joueur
                  -> authoring no-code -> sauvegarde/export -> tests
                  -> API directe / JSONL / éditeur / MCP quand applicable
```

L'existence d'un identifiant `EncounterKind.headbutt`, d'une valeur
`FieldAbility.waterfall` ou d'un asset Mega ne prouve donc pas une boucle jouable.

### 2.3 Périmètre de recherche

La recherche couvre les mécaniques de la série principale des Générations I à IX,
les ruptures majeures entre générations, la branche `Legends`, les formats de combat,
les systèmes secondaires et les gimmicks. Les sources officielles sont privilégiées
pour les bases et les fonctionnalités récentes ; Bulbapedia sert de référentiel
transgénérationnel recoupé.

Les contenus exacts — Pokédex national complet, nombre précis d'attaques, d'objets ou
de talents — sont distingués des capacités du moteur. Un moteur peut être capable de
supporter une mécanique sans fournir l'intégralité du catalogue officiel.

### 2.4 Limites de l'audit

- Aucun code de production n'a été modifié.
- Aucun statut de la roadmap canonique n'a été réécrit.
- Le worktree était déjà très sale sur le chantier Smart Tiles.
- Les tests Flutter runtime/UI ne compilent pas dans cet état ; cette panne n'est pas
  attribuée aux mécaniques auditées.
- Le gate de couverture PSDK demande un projet externe absent de ce workspace.
- L'audit évalue le dépôt actuel, pas une intention exprimée uniquement dans un
  document ou un nom d'enum.

---

## 3. Référentiel Pokémon synthétique

La boucle historique de la série principale est : recevoir un partenaire, explorer,
capturer et entraîner, combattre des Dresseurs, progresser par badges ou défis,
atteindre la Ligue ou la fin de l'histoire, puis compléter le Pokédex et le post-game.
Le [guide officiel de combat BDSP](https://diamondpearl.pokemon.com/en-us/trainersguide/fundamentals/battling/)
confirme notamment l'équipe de six, les commandes de combat, les statistiques, PP,
statuts et objets tenus. La synthèse transgénérationnelle est décrite par la page
[Core series](https://bulbapedia.bulbagarden.net/wiki/Core_series).

### 3.1 Ruptures importantes entre générations

| Génération | Ruptures mécaniques importantes | Conséquence pour PokeMap | Référence |
|---|---|---|---|
| I | Special unique, DVs/stat experience, catégories liées au type, comportements historiques atypiques | Profil rétro séparé uniquement | [Gen I](https://bulbapedia.bulbagarden.net/wiki/Generation_I) |
| II | Sp. Atk/Sp. Def, Dark/Steel, objets tenus, sexe, œufs, amitié, shiny, temps, météo, roamers | Plusieurs éléments deviennent `P1` | [Gen II](https://bulbapedia.bulbagarden.net/wiki/Generation_II) |
| III | Talents, natures, IV/EV modernes, doubles, météo overworld, concours, Frontier | Base du modèle individuel moderne | [Gen III](https://bulbapedia.bulbagarden.net/wiki/Generation_III) |
| IV | Split physique/spécial par attaque, formes et évolutions riches, online, hazards normalisés | Socle indispensable de la cible Génération V | [Gen IV](https://bulbapedia.bulbagarden.net/wiki/Generation_IV) |
| V | Hidden Abilities, saisons, XP mise à l'échelle, capture critique, Triple/Rotation | Cible active pour le cœur ; Triple/Rotation restent `LATER` | [Gen V](https://bulbapedia.bulbagarden.net/wiki/Generation_V) |
| VI | Fairy, Mega, déplacement enrichi, horde, affection, XP de capture | Hors cible actuelle | [Gen VI](https://bulbapedia.bulbagarden.net/wiki/Generation_VI) |
| VII | Z-Moves, formes régionales, SOS, Ride remplaçant les HM, Hyper Training | Hors cible actuelle | [Gen VII](https://bulbapedia.bulbagarden.net/wiki/Generation_VII) |
| VIII | Dynamax, raids, spawns visibles, Box Link, mints, autosave ; `Legends` change exploration et combat | Hors cible actuelle | [Gen VIII](https://bulbapedia.bulbagarden.net/wiki/Generation_VIII) |
| IX | Téra, open world, auto-battle, pique-nique, crafting TM, outbreaks modernes, nouvelle obéissance | Hors cible actuelle | [Gen IX](https://bulbapedia.bulbagarden.net/wiki/Generation_IX) |

Les lignes VI à IX restent dans le référentiel de recherche uniquement pour expliquer
le parking. Elles ne créent aucun besoin produit dans la roadmap active.

### 3.2 Cœur mécanique attendu

Le référentiel complet comporte au minimum les familles suivantes :

- identité joueur, New Game, starter et progression narrative ;
- cartes, collisions, interactions, warps, triggers, PNJ et traversal ;
- individu Pokémon persistant complet ;
- espèces, formes, types, statistiques, talents, moves, objets et learnsets ;
- rencontres sauvages, génération d'individus et capture ;
- combat singles ; doubles conservés uniquement dans le parking `LATER` ;
- XP, EV, niveaux, apprentissage, amitié, obéissance et évolution ;
- équipe, PC, Pokédex, sac et menus ;
- boutiques, Centres, défaite et services ;
- temps, météo, calendrier et monde vivant ;
- élevage, œufs et échange pour un moteur avancé ;
- post-game, facilities et contenus secondaires compatibles I–V ;
- authoring sans code, validation, sauvegarde, export et parité des transports.

---

## 4. Inventaire architectural actuel

### 4.1 Packages centraux observés

| Package | Rôle mécanique observé |
|---|---|
| `map_core` | Modèles de projet, `GameState`, save, party, PC, progression, trainers, badges, rencontres, validations |
| `map_gameplay` | New Game, exploration pure, rencontres, Surf, objets joueur, PC, shops, progression, évolution, défaite |
| `map_battle` | Kernel de combat, PSDK, timeline, IA, moves, talents, objets, statuts, terrains, météo, capture |
| `map_runtime` | Intégration Flame/Flutter, combats, services joueur, write-back, menus, scènes, save/load |
| `map_player_ui` | Titre, pause, party, bag, PC, shop, heal, options et surfaces joueur |
| `map_editor` | Studios et catalogues Pokémon, trainers, shops, scènes, authoring de projet |
| `map_authoring` | API canonique de mutations et lectures authorables |
| `map_distribution` | Packaging et validation de contenu distribué |
| `tools/pokemap_mcp` | Transport MCP et catalogue d'actions découvrables |

### 4.2 Point d'architecture à corriger

Une partie importante des schémas Pokémon — espèces, breeding, progression d'espèce,
formes, contenu Dex, learnsets et évolutions — vit dans
`packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`.
Pour un moteur générique, les contrats canoniques partagés devraient appartenir à une
couche indépendante de l'éditeur, idéalement `map_core` ou un package de catalogue
pur. Le runtime charge actuellement ces données par des loaders spécialisés, ce qui
augmente le risque de divergence entre éditeur, runtime, authoring et MCP.

### 4.3 Profil de combat explicitement hybride

`packages/map_battle/lib/src/data/battle_parity_target.dart` déclare :

| Axe | Cible actuelle | Alignement déclaré |
|---|---|---|
| Dégâts | style mainline Génération IX | `PARTIAL` |
| Speed ties | aléatoire seedé reproductible | `GAP` |
| Statuts majeurs | cœur moderne Génération IX | `PARTIAL` |
| Critiques | stages et multiplicateur moderne | `ALIGNED` |
| Expérience | formule PokeMap simplifiée | `INTENTIONAL_VARIANT` |
| Capture | formule MVP PokeMap, une Ball canonique | `INTENTIONAL_VARIANT` |

Le même document précise que les compteurs PSDK ne prouvent pas la parité joueur sans
preuves de bridge runtime, surface joueur et golden E2E.

Ce profil code actuel n'est plus la cible produit : il référence explicitement des
règles Génération IX pour dégâts, speed ties et statuts. La première décision du lot
Ruleset devra être de définir une cible Génération V vérifiable, puis de mesurer les
écarts du kernel existant contre elle. Il ne faut pas simplement renommer le profil
hybride actuel.

---

## 5. Matrice globale PokeMap contre le référentiel

| Domaine | Priorité / scope | Statut | Ce qui existe | Écart principal |
|---|---:|---|---|---|
| Profil de génération/ruleset | P0 | `ABSENT` | Cible battle hybride locale | Pas de profil projet global couvrant type chart, XP, capture, TM, obéissance, etc. |
| New Game / identité initiale | P0 | `UNVERIFIED` | Contrats purs verts : nom, avatar, pronoms, spawn, argent, sac, équipe, facts | Boucle produit non recertifiée ; introduction canonique et rival adaptatif à authorer |
| Starter | P0 | `UNVERIFIED` | Options configurées, scène et conséquence dédiée | Runtime non recertifié ; don vers PC si party pleine absent |
| Sauvegarde / chargement | P0 | `UNVERIFIED` | `GameState`, enveloppes, checksums, migrations et tests purs verts | Transaction et parcours runtime non recertifiés au HEAD |
| Individu Pokémon | P0 | `PARTIAL` | Niveau, XP, IV/EV, nature, talent, sexe, moves/PP, PV/statut, shiny, objet, surnom, amitié, provenance | ID stable, forme, OT/ID, langue, œuf, ribbons/marks, données modernes |
| Catalogues Pokémon | P0 | `PARTIAL` | Espèces, stats, types, talents, breeding data, learnset, évolution, médias | Contrats trop liés à `map_editor`, contenu et validations variables |
| Exploration | P0 | `PARTIAL` | Collisions, interactions, warps, maps, PNJ, hazards, pathfinding | Course, vélo/monture, follower, traversal riche, objets cachés natifs |
| Événements/dialogues | P0 | `PARTIAL` | Events, Facts, flags, conditions, scènes, choix et conséquences | Commandes générales, arithmétique, aléatoire, contrôle temps/météo, common events |
| Rencontres walk/surf | P0 | `UNVERIFIED` | Contrats purs verts : zones, taux, poids, niveau, conditions, RNG | Runtime non recertifié ; génération d'individu et modifiers encore simplifiés |
| Rencontres avancées | P1 | `PARTIAL` | Enums fishing/headbutt/gift/special, statique scriptable | Pêche, headbutt, roamers, swarms et Repel incomplets ; spawns visibles hors cible |
| Capture | P0 | `PARTIAL` | Formule, RNG, consommation, party→box, stockage plein, Dex | Balls spécialisées I–V, capture critique et shakes/parité Génération V |
| Combat singles kernel | P0 | `PARTIAL` | Moves, effects, talents, items, statuts, switches, météo, terrains, hazards, IA | Axes officiels encore partiels ; règles hybrides |
| Surface combat joueur | P0 | `UNVERIFIED` | Overlay, commandes, bridge runtime, progression/write-back | Tests Flutter bloqués ; remplacement/ciblage et tous les chemins non prouvés frais |
| Doubles/multi | LATER | `PARTIAL` | Slots PSDK, targeting et tests internes ; produit joueur absent | Parking explicite jusqu'à stabilisation des singles Génération V |
| XP/niveaux/stats | P0 | `PARTIAL` | Courbes, multi-level, stats, move learning, post-battle | XP simplifiée, participants/Exp Share par profil, traded bonus, EV yield, caps |
| Move learning | P0 | `PARTIAL` | 4 moves, accepter/remplacer/refuser, TM/HM | Reminder, Deleter, tutors, egg/event moves et PP Up/PP Max I–V |
| Évolution | P0 | `PARTIAL` | Niveau, objet, amitié et move connu | Échange, temps, lieu, genre, held item, party, stats et méthodes I–V |
| Amitié | P1 | `PARTIAL` | Valeur persistée et condition d'évolution | Gains/pertes, moves, capture et marche selon le profil Génération V |
| Obéissance | P1 | `ABSENT` | Badges et met level partiels dans les données | OT, outsider, seuils, actions de désobéissance et profils générationnels |
| Party / Summary | P0 | `PARTIAL` | Max 6, lead/reorder, fiche joueur, PV/PP/statuts | Identité stable et opérations avancées |
| PC / boîtes | P0 | `PARTIAL` | 8×30, deposit/withdraw/swap, fiche détaillée basique, garde dernier utilisable | Release, rename/wallpaper, recherche, multisélection, favoris, œufs |
| Pokédex joueur | P0 | `PARTIAL` | Inconnu/vu/capturé, numéro, nom, types, compteur implicite | Formes, régional/national, habitat, détail, recherche, récompenses, langues/shiny |
| Bag / objets | P0 | `PARTIAL` | Quantités, catégories, soins HP/statut/PP, revive, TM, évolution, Balls metadata | Registre unifié data-driven, toss/register/sort, effets riches et contextes |
| Objets tenus | P1 | `PARTIAL` | Champ persistant, effets battle PSDK, consommation/write-back | Équiper/retirer/échanger depuis l'équipe ou le PC, politique facility/link |
| Boutiques | P0 | `UNVERIFIED` | Contrats purs verts : buy/sell, stock, prix, états conditionnels, compteurs | Runtime non recertifié ; devises multiples et réassort temporel absents |
| Centres / soins / défaite | P0 | `PARTIAL` | Soin complet, checkpoint, whiteout, perte d'argent, warp | UX canonique Centre/respawn et politiques de défaite scénarisée à généraliser |
| Dresseurs | P0 | `PARTIAL` | Équipe, difficulté, dialogues, rewards, flags, badge, rematch | Partners/doubles, objets IA riches, équipes évolutives, schedules de rematch |
| Gym/rival/Ligue | P0/P1 | `PARTIAL` | Templates gym/rival et rewards | Templates de parcours complets, Hall of Fame, crédits, Elite Four/post-game |
| Field abilities | P1 | `PARTIAL` | Surf implémenté, évaluation pure verte, runtime non recertifié ; enums des autres capacités | Cut/Strength/Flash/Rock Smash/Waterfall/Dive et Fly/fast travel incomplets |
| Temps/calendrier | P1 | `ABSENT` | Aucun système actif ; roadmap générique séparée | Horloge, période, semaine, pause, save, conditions et événements |
| Météo overworld | P1 | `PARTIAL` | Météo de combat et quelques données de map | Contrôleur monde, transitions, rencontre, musique, rendu et sync battle |
| Baies/respawns/monde vivant | P1/P2 | `ABSENT` | Respawn d'entité modélisé partiellement | Croissance, récolte, timers, swarms, événements quotidiens |
| Élevage/œufs | P2 | `PARTIAL` | Egg groups et hatch cycles dans les données d'espèce ; runtime absent | Compatibilité, production, héritage, pas, éclosion, stockage et UI |
| Échange | P2/P3 | `ABSENT` | `origin=trade` seulement | OT/IDs/langue, in-game trade, trade evolution, local/online |
| Shiny hunting | P2 | `PARTIAL` | `isShiny` persistant et visuels ; système de chasse absent | Odds/ruleset, locks, Masuda, chains, charms, outbreaks |
| Formes | P1 | `PARTIAL` | Formes d'espèce minimales et formId chez trainers | Forme de l'individu, changement, stats/types/talent/media/evolution runtime |
| Ribbons/marks/titles | P2 | `ABSENT` | Aucun contrat d'individu | Acquisition, affichage, titre actif, concours/facilities |
| Battle Facilities | P2 | `ABSENT` | Pas de boucle produit | Règles, level normalization, restore, streak, BP, teams de location |
| Fin/crédits/post-game narratif | P1/P2 | `PARTIAL` | `SceneFinishGameConsequence`, coordination runtime et flags | Hall of Fame, records, validation de post-game et parcours authoring dédiés |
| Mega et Z-Moves | PARKED | `PARTIAL` | Action Mega kernel et comportements Z dédiés | Hors roadmap active ; aucune complétion demandée |
| Dynamax et Téra | PARKED | `ABSENT` | Traces, familles d'effets ou tooling sans action produit équivalente | Hors roadmap active ; aucune implémentation demandée |
| Online/co-op | PARKED | `ABSENT` | Architecture pure utile mais pas de produit | Hors cible locale Génération V actuelle |
| Authoring no-code | P0 | `PARTIAL` | Studios New Game, Dex, trainers, shops, scènes et mutations | Beaucoup de mécaniques manquantes n'ont aucun picker/validator/simulateur |
| MCP | P0 pour parité | `PARTIAL` | Catalogue PMCP-085, 229 mutations | Lecture mécanique peu découvrable : seulement 5 resourceKinds query live |
| Packaging/export | P0 | `UNVERIFIED` | Manifestes, validation et distribution | Runtime actuellement non compilable dans le worktree ; couverture de nouveaux états future |

### 5.1 Preuves principales de la matrice

| Domaine | Preuves code | Preuves tests ou réserve |
|---|---|---|
| New Game | `project_new_game_config.dart:50`, `new_game_state_builder.dart:123`, `playable_map_game.dart:269` | Tests core/gameplay verts ; Flutter bloqué |
| Sauvegarde / chargement | `save_envelope.dart:56`, `game_state_save_envelope_mapper.dart:9`, `playable_map_game_session_runtime.dart:308-319` | Codec/migrations/mapping purs verts ; runtime bloqué |
| Événements/dialogues | `map_event_definition.dart:21`, `scene_consequence.dart:24`, `scene_consequence_runtime_writer.dart:8` | Présence et nombreux tests ciblés ; palette Pokémon partielle |
| Rencontres | `gameplay_encounter.dart:121`, `playable_map_game.dart:4392` | Contrats de conditions verts ; runtime bloqué |
| Capture | `capture_formula.dart:59`, `battle_capture_action_handler.dart:25`, `runtime_battle_outcome_apply.dart:483` | Formule et destination purs testés ; formule intentionnellement simplifiée |
| Combat | `battle_parity_target.dart:65-150` | Target test vert ; gate PSDK externe absent |
| Individu et PC | `save_data.dart:152`, `save_data.dart:354`, `player_pc_overlay.dart:289` | Persistence/storage purs verts ; UI bloquée |
| Party | `save_data.dart:283`, `runtime_player_pause_data_builder.dart:138` | Roster/storage purs verts ; surface Flutter bloquée |
| Pokédex | `save_data.dart:487`, `runtime_player_pause_data_builder.dart:405` | Vu/capturé persistés ; surface simple et non recertifiée |
| Objets | `player_item_effects.dart:92` | `party_bag_heal_operations_test.dart` vert |
| TM/HM | `pokemon_move_machine_service.dart:102` | Service pur vert ; surface joueur non recertifiée |
| Évolution | `pokemon_evolution_service.dart:290` | Service pur vert ; runtime non recertifié |
| XP/niveaux | `battle_progression_service.dart:119` | Progression ciblée verte ; formule PokeMap simplifiée |
| Surf | `surf_evaluation.dart:42`, `playable_map_game.dart:10670` | Évaluation pure verte ; runtime bloqué |
| Cadeau/starter party pleine | `scene_consequence_runtime_writer.dart:297-390` | Rejet `partyFull` confirmé par lecture |
| Boutiques | `game_state_mutations.dart:348,561`, `player_service_runtime_controller.dart:228` | Achat/vente purs verts ; service runtime non recertifié |
| Soins/défaite | `game_state_mutations.dart:795`, `player_defeat_recovery.dart:116`, `player_service_runtime_controller.dart:339` | Soins et recovery purs verts ; runtime bloqué |
| Dresseurs | `project_trainer.dart:104`, `playable_map_game.dart:8125-8223` | Contrats lifecycle/rewards verts ; runtime non recertifié |
| Carte joueur | `runtime_player_pause_data_builder.dart:101` | Lecture seule ; Fly explicitement futur |
| Météo de map | `map_metadata.dart:47-58` | Métadonnée présente ; contrôleur de monde absent |
| Temps/calendrier | `projected_building_shadow_diagnostics.dart:183` | Diagnostic explicite : aucun système time-of-day actif |
| Temps de jeu | `playable_map_game_session_runtime.dart:67,78,308-319` | Chronomètre session présent ; profil parallèle à caractériser |
| Breeding | `pokemon_project_data_models.dart:289` | Données d'espèce uniquement ; aucune boucle runtime trouvée |
| Échange/obéissance | `save_data.dart:109-146` | Origine `trade` et met level seulement ; aucun système trouvé |
| Fin/crédits | `scene_consequence.dart:817-927` | Contrat présent ; produit post-game partiel |
| Authoring | `full_authoring_parity.dart:132`, `local_map_authoring_mutation_api.dart:96` | PMCP-085 : 62 ressources, 229 mutations, 18 tests ciblés verts |
| MCP | `tools/pokemap_mcp/test/mutation_server.test.ts:650-655` | Describe live vert ; cinq resourceKinds query ; rendu réel rouge |
| Packaging | `game_package_builder.dart:31` | 49 tests ciblés verts, 1 preuve de compatibilité supprimée |

Les chemins sont relatifs à leurs packages. Les preuves Flutter sont des preuves de
présence de code, pas des preuves de compilation au `HEAD` actuel.

### 5.2 Les quinze lacunes les plus structurantes

1. profil global de règles Pokémon versionné ;
2. identité persistante complète de chaque Pokémon ;
3. catalogues canoniques partagés hors de l'éditeur ;
4. fidélité singles : ordre, dégâts, statuts et triggers ;
5. moteur d'objets data-driven unifié ;
6. génération sauvage aléatoire et modificateurs de rencontres ;
7. capture complète et familles de Balls jusqu'à la Génération V ;
8. XP, EV, amitié et obéissance par ruleset ;
9. acquisition, PP et mémoire des moves jusqu'à la Génération V ;
10. registre d'évolutions I–V combinable ;
11. PC, Pokédex, gifts et held-item UX cohérents ;
12. field abilities classiques et Fly ;
13. temps, météo, saisons et monde vivant ;
14. breeding, œufs et échange local ;
15. recertification runtime, authoring et distribution de la boucle singles.

### 5.3 Lots de roadmap dont le statut textuel est obsolète ou non prouvable

Ce tableau ne remplace pas un Evidence Pack et ne modifie pas la roadmap.

| Lots | Statut roadmap | Statut observé | Réserve |
|---|---|---|---|
| FG-010 | `TODO` | `DONE` contrat pur | `createNewGameState*` et tests purs verts |
| FG-011 | `TODO` | `UNVERIFIED` produit | Flow runtime présent, Flutter non compilable |
| FG-012 | `TODO` | `DONE` modèle | Options de starter et validations présentes |
| FG-013 | `TODO` | `UNVERIFIED` produit | Scène/conséquence et intégration présentes, test non relançable |
| FG-015 | `TODO` | `UNVERIFIED` produit | Pause shell et coordinator présents, UI non compilable |
| FG-029 | `PARTIAL`, Summary PC absent | `PARTIAL` | La fiche PC basique existe désormais ; opérations modernes manquent |
| FG-050 | `TODO` | `PARTIAL` | Objets de combat génériques dans le kernel ; surface produit incomplète |
| FG-071 | `PARTIAL`, commande soin absente | `PARTIAL` | Service/commande/runtime présents ; recertification bloquée |
| FG-072 | `TODO` | `PARTIAL` | Held effects et write-back battle présents ; équiper/retirer côté joueur absent |
| FG-073 | `TODO` | `PARTIAL` | Service TM/HM pur vert ; surface joueur non recertifiée |
| FG-080/081 | `TODO` | `PARTIAL` | Modèles, commandes, Facts/conditions et builders existent, plusieurs voies coexistent |
| FG-100/101 | `TODO` | `PARTIAL` | Audit implicite, tables et conditions présents ; famille de rencontres incomplète |
| FG-120 | `PARTIAL` | `UNVERIFIED` produit | Surf pur vert et code runtime présent ; Flutter bloqué |
| FG-140 | `TODO` | `UNVERIFIED` produit | Politique defeated/rematch présente ; runtime non recertifié |
| FG-160 à FG-163 | `TODO` | `UNVERIFIED` produit | Menus pause, Dex, options et save présents ; Flutter bloqué |
| FG-164 | `TODO` | `PARTIAL` | Carte consultable présente ; fast travel absent |
| FG-165 | `DONE` | `UNVERIFIED` preuve | Code présent, mais Evidence Pack référencé supprimé |

---

## 6. Analyse détaillée des lacunes

### 6.1 Lacune structurante no 1 — Ruleset Pokémon global

Une recherche du dépôt ne trouve aucun `generationProfile`, `mechanicsProfile` ou
ruleset projet global. Or les choix suivants varient selon les générations :

- table des types et présence de Fairy/Stellar ;
- split physique/spécial ;
- formule de dégâts, critique, burn et paralysie ;
- ordre des actions et speed ties ;
- durée du sommeil, gel/neige et statuts ;
- XP, Exp Share, XP de capture et bonus traded ;
- EV/IV, caps, vitamines et Pokérus ;
- formule de capture et capture critique ;
- consommabilité des TM/HM/TR ;
- disponibilité des talents et objets tenus ;
- obéissance ;
- soin par dépôt en PC ;
- field moves versus Ride/montures ;
- gimmick autorisé et nombre d'activations.

Sans ce contrat, deux projets PokeMap ne peuvent pas dire de manière vérifiable à
quelles règles ils obéissent. La recommandation est un `PokemonRulesetProfile` pur et
versionné, référencé par le projet et injecté dans gameplay, battle, runtime,
validation et authoring.

### 6.2 Données individuelles

`PlayerPokemon` couvre déjà un bon socle, mais les absences suivantes bloquent
échange, breeding, formes, Pokédex riche et opérations PC modernes :

| Donnée manquante | Impact |
|---|---|
| ID d'instance stable | Quêtes ciblées, échanges, historique, multisélection PC, replay |
| `formId` persistant | Formes régionales, transformations, stats/types/media spécifiques |
| OT name + Trainer ID + Secret ID | Outsider, surnom, obéissance, trade, shiny traditionnel |
| Langue d'origine | XP traded, Masuda, noms et Pokédex linguistique |
| Date/version/région de rencontre | Summary, règles d'événement, provenance |
| État œuf + cycles restants | Breeding, stockage et éclosion |
| Slot/Hidden Ability | Evolution, Capsule/Patch et héritage |
| Move memory/relearn set | Reminder moderne et transfert de moves |
| Hyper Training + mint effect | Hors cible ; ne pas les ajouter au modèle V1 Génération V |
| Ribbons I–V | Post-game, concours et identité d'individu ; marks modernes hors cible |
| Taille/scale individuelle | Hors cible actuelle sauf besoin explicite d'un fangame |
| Tera Type/Dynamax/GMax | Hors cible actuelle ; ne pas les ajouter au modèle V1 Génération V |

Le champ shiny est correctement attaché à l'individu ; il ne faut pas le déplacer au
niveau espèce.

### 6.3 Rencontres et génération sauvage

La table actuelle sait choisir espèce et niveau par poids, taux et conditions. Elle ne
décrit pas encore complètement la génération de l'individu : forme, moveset, talent,
nature, sexe, IV, shiny, objet tenu et politiques de lock.

Les méthodes et modificateurs manquants ou non prouvés sont :

- pêche par canne ;
- headbutt, Rock Smash et Sweet Scent/leurre ;
- rencontres statiques consommables avec politique de respawn ;
- cadeaux et fossiles routés vers party ou PC ;
- Repel avec règle du premier membre utilisable ;
- heure, jour, météo et saison composables ;
- capacités du lead modifiant type, niveau, sexe ou objets ;
- doubles sauvages à revoir avec le futur chantier doubles ;
- roamers conservant PV et statut ;
- swarms/outbreaks ;
- chaînes et shiny hunting ;
- tables par version/région.

Les hordes, SOS et spawns visibles ne sont pas des lacunes de la cible active : ils
sont explicitement `PARKED` avec les mécaniques post-Génération V.

### 6.4 Capture

La capture MVP est transactionnelle pour le chemin party vers première boîte libre et
met à jour vu/capturé. Les manques sont :

- familles de Balls avec conditions de tour, lieu, type, niveau, poids, vitesse,
  sexe, heure, pêche ou espèce déjà capturée ;
- Master Ball garantie ;
- capture critique ;
- nombre de secousses et messages associés ;
- profils de formule par génération ;
- proposition de surnom ;
- politique Génération V explicite d'envoi automatique vers une boîte ;
- Safari classique si un fangame le demande ;
- bonus de capture et effets initiaux de certaines Balls.

Le choix moderne équipe/boîte, la capture en doubles, les raids et la capture hors
combat ne font pas partie de la cible singles actuelle.

Attention : le don de Pokémon par scène et le starter configuré retournent actuellement
`partyFull` au lieu d'utiliser la politique party-vers-PC de la capture. C'est un écart
de cohérence fonctionnelle concret.

### 6.5 Combat

Le kernel contient une base très importante et ne doit pas être sous-estimé. Le gate
PSDK encode historiquement 728 attaques strictes, 330 méthodes et 482 effets portés.
Ces nombres n'ont pas pu être reproouvés pendant cette passe, car le test demande le
répertoire externe `../../pokémon_sdk_test_project/Data/Studio/moves` absent.

Les priorités restantes sont :

1. choisir et versionner le ruleset ;
2. fermer le `GAP` speed ties ;
3. terminer la parité dégâts/statuts ;
4. prouver l'ordre des triggers talents/objets/moves ;
5. prouver faint, replacement et fin de tour ;
6. fermer et certifier le ruleset d'aventure singles Génération V ;
7. rendre les objets de combat et held items authorables et cohérents ;
8. fournir un log déterministe/replay exploitable.

Targeting multi-slot, spread moves, redirection, IA partenaire et toute boucle doubles
sont conservés en `LATER`, hors des critères de sortie du cœur singles.

Les détails souvent oubliés comprennent les arrondis intermédiaires, reset des stages
et volatiles au switch, persistance PV/PP/statut, Struggle, actions invalidées après
K.O., changements de Vitesse en cours de tour, ordre des triggers de switch-in,
consommation d'objet seulement après validation, et absence d'XP/argent permanent en
facility/link.

### 6.6 XP, moves et évolution

PokeMap sait attribuer une XP simplifiée, gérer plusieurs levels, recalculer les stats,
proposer un move et une évolution. Pour un moteur complet, il faut encore :

- profils d'Exp Share ;
- participants exacts et bonus traded/Lucky Egg ;
- EV yield et caps ;
- Rare Candy ;
- Move Reminder, Deleter et Tutor ;
- PP Up/PP Max ;
- moves egg/event/transfer ;
- politique TM/HM Génération V, avec TM réutilisables ;
- annulation/blocage/retry d'évolution ;
- registre d'évolution combinable couvrant les méthodes I–V.

Les bonus d'affection, Bonbons Exp., TR et mémoire moderne des moves sont postérieurs
à la cible et ne constituent pas des lacunes actives.

Le service d'évolution pur ne reconnaît actuellement que les triggers `levelUp` et
`itemUse`, avec conditions niveau, amitié, objet et move connu. Il manque entre autres :

- échange et échange avec objet ;
- heure et jour/nuit ;
- sexe ;
- objet tenu au level-up ;
- lieu, région ou biome ;
- espèce/type dans l'équipe ;
- comparaison de statistiques ;
- forme ou personnalité ;
- cas produisant un second Pokémon avec slot et Ball disponibles.

Les méthodes fondées sur la météo, les dégâts reçus, les critiques, des actions
répétées, les pas, le spin, la coopération ou une commande manuelle sont postérieures
à la Génération V et restent hors de ce registre actif.

Référence : [Methods of Evolution](https://bulbapedia.bulbagarden.net/wiki/Methods_of_Evolution).

### 6.7 Party, PC, Pokédex et menus

Les menus joueur réels comprennent titre, New Game/Continue/Load, pause, party, bag,
Pokédex, carte, sauvegarde et options. Le PC sait déposer, retirer et échanger ; son
overlay affiche une fiche basique. Les manques sont :

- ID d'individu stable ;
- release avec confirmation et règles de dernier Pokémon ;
- rename de boîte, wallpaper, favoris, markings ;
- recherche, filtres, tri et multisélection ;
- gestion explicite des œufs ;
- opérations d'objet tenu depuis party/PC ;
- Battle Box/verrouillage compatible Génération V ;
- Pokédex par formes, régional/national, habitat et détails ;
- récompenses de complétion ;
- carte interactive et Fly/fast travel.

Le Pokédex runtime est aujourd'hui une liste utile mais simple : inconnu, vu, capturé,
numéro, nom et types. Les catalogues auteur sont plus riches que la surface joueur.

### 6.8 Objets et économie

Le registre MVP des objets joueur couvre Potion, soins de statut, Revive, Ether, un
key-item générique et la Poké Ball. Les TM/HM, évolutions, objets de combat et held
items passent par plusieurs services/loaders distincts.

La priorité est de définir un schéma d'effet data-driven unique, avec :

- contextes terrain/combat/cible ;
- validité et non-consommation sur échec ;
- effets composés atomiques ;
- consommabilité ;
- poche, stack, unicité, toss/sell/register ;
- effets de capture ;
- held lifecycle ;
- scripts authorables encadrés ;
- restitution/write-back par ruleset.

Manquent encore Repel, Rope, vitamines, Rare Candy, PP Up, X-items complets, baies,
fossiles, plusieurs devises, BP/coins et réassorts temporels compatibles I–V. Le
crafting de TM est `PARKED` et ne constitue pas une lacune de la cible actuelle.

### 6.9 Monde, terrain et services

Surf constitue une vraie boucle : capacité débloquée, Pokémon conscient connaissant le
move, eau ciblée et changement de mode. Cut, Strength, Rock Smash, Flash, Waterfall,
Dive et Fly n'ont pas de boucles équivalentes complètes.

La modélisation doit distinguer :

- capacité de terrain débloquée ;
- condition de progression ;
- éventuelle compatibilité d'un Pokémon ;
- action sur obstacle ou mode de traversal ;
- consommation ou non d'une ressource ;
- présentation ;
- persistance du changement de monde.

La cible active conserve les Field Abilities/HM classiques. Les Ride/montures modernes
sont `PARKED` et ne doivent pas influencer le contrat V1 au-delà d'une architecture
qui évite de bloquer une extension future.

### 6.10 Temps, météo et monde vivant

Aucun vrai cycle jour/nuit, calendrier ou saison n'est actif. La météo de combat ne
constitue pas une météo d'overworld. Le futur système doit fournir :

- horloge canonique persistée ;
- mode narratif, accéléré ou appareil ;
- pause et avance contrôlée ;
- périodes matin/jour/soir/nuit ;
- jour de semaine et calendrier optionnel ;
- météo monde et politique de transfert au combat ;
- conditions de rencontres, évolutions, PNJ et événements ;
- éclairage, audio et ambiance comme consommateurs ;
- timers de respawn, baies, swarms et rematches ;
- comportement offline et protection optionnelle contre la manipulation d'horloge.

Références : [Time](https://bulbapedia.bulbagarden.net/wiki/Time) et
[Weather](https://bulbapedia.bulbagarden.net/wiki/Weather).

### 6.11 Élevage, échange et obéissance

Les données d'espèce contiennent déjà egg groups et hatch cycles, mais aucun runtime de
breeding n'a été trouvé. Un module complet doit couvrir compatibilité, Ditto, production
d'œuf, cycles, Flame Body-like, espèce/forme, héritage IV/nature/talent/Ball/moves,
Destiny Knot, Power Items, Masuda, stockage et éclosion.

L'échange doit commencer par l'échange interne avec un PNJ avant tout online : OT,
Trainer IDs, langue, provenance, surnom, bonus XP, friendship reset éventuel,
obéissance et évolution par échange. L'online reste `P3` et ne doit pas bloquer la
boucle locale.

Références : [Pokémon breeding](https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9mon_breeding),
[Trade](https://bulbapedia.bulbagarden.net/wiki/Trade) et
[Obedience](https://bulbapedia.bulbagarden.net/wiki/Obedience).

### 6.12 Contenus secondaires et parking

Sont explicitement hors roadmap active : Mega/Primal, Z-Moves, Dynamax/Gigamax,
raids, Téra, SOS, Ride, spawns visibles, autosave, mints, open world, auto-battle,
pique-nique, crafting de TM et toute variante `Legends`. Les doubles, Triple et
Rotation sont classés `LATER`, après certification des singles.

Les contenus secondaires compatibles avec une inspiration Génération V peuvent être
réévalués plus tard sans bloquer le cœur :

- Safari, Bug-Catching Contest, Game Corner ;
- concours, Pokéblocks/Poffins et rubans ;
- Battle Tower/Frontier/Subway/Maison/Tree ;
- Secret Bases, Underground, Pokéathlon, Musical, Pokéstar Studios ;
- follower, photo, fashion et décorations ;
- Poké Radar, swarms et shiny hunting compatibles I–V ;
- Hall of Fame, rematches de Ligue, achievements/diplomas ;
- échange local, Mystery Gift local/offline et post-game.

Aucun item du parking ne doit créer de dépendance, de schéma obligatoire ou de critère
de release dans le ruleset Génération V V1.

---

## 7. Parité no-code, API, MCP et distribution

### 7.1 Constat MCP live

Un appel live `pokemap_describe` a réussi : catalogue `PMCP-085`, 229 actions de
mutation. Les actions couvrent notamment New Game, badges, personnages, rencontres,
shops, trainers, NPC, scènes, zones de gameplay, catalogues Pokémon, learnsets,
évolutions et médias.

La conformance authoring annonce par ailleurs 62 ressources dans sa matrice
`fullParity`, deux commandes runtime (`render` et `playtest`) et 36 mutations voisines
des mécaniques de fangame. Cette matrice prouve la présence de descriptors et de
cellules de transport ; elle ne prouve pas à elle seule qu'une UI complète ou qu'un
parcours runtime réel existe pour chaque action.

La lecture générique live n'expose cependant que cinq `resourceKinds` :

- `asset` ;
- `elementCategory` ;
- `map` ;
- `project` ;
- `tilesetFolder`.

Il existe donc un écart de découvrabilité : les mutations mécaniques sont nombreuses,
mais Pokémon, trainers, encounters, shops, badges et autres entités ne sont pas des
ressources de lecture de premier rang dans le catalogue live.

Les tests de parité actuels ont également des limites importantes :

- la seule équivalence Direct API vers JSONL réellement exécutée de bout en bout est
  `map.create` ;
- la golden MCP d'équivalence complète porte elle aussi sur `map.create` ;
- le contrôle Editor vérifie surtout que les `actionId` utilisés appartiennent au
  catalogue, pas que chaque mutation canonique dispose d'une interface no-code ;
- `battle.*`, `progression.*` et `sandbox.*` sont des commandes de simulation ou
  playtest, volontairement hors dispatcher de mutations projet ;
- le playtest MCP vert utilise un exécuteur factice injecté ; aucune preuve actuelle
  ne montre un playtest réel de production terminé avec succès ;
- le rendu MCP réel échoue actuellement sur la compilation Smart Tiles.

### 7.2 Règle de parité à appliquer à chaque lot

Pour toute mécanique authorable, la définition de terminé doit couvrir :

| Transport/surface | Preuve attendue |
|---|---|
| API directe `map_authoring` | Contrat canonique et test ciblé |
| JSONL/CLI | Mutation et lecture round-trip |
| Éditeur | Pickers, labels, validation, preview/simulation |
| MCP | Action découvrable, schéma, exemple, erreurs structurées |
| Runtime | Effet réellement jouable et sauvegardé |
| Distribution | Données et assets présents dans le package produit |

Une sauvegarde JSON générique ou une mutation « whole project » ne prouve pas
l'exposition sémantique de la mécanique.

### 7.3 Faux positifs à éviter dans les futurs Evidence Packs

| Preuve trouvée | Ce qu'elle ne prouve pas |
|---|---|
| `campaign.new_game.update` | L'écran New Game et la sélection du starter réellement jouables |
| `map.save` | Une sauvegarde de partie joueur |
| Ressource `gameSave` dans `fullParity` | Une lecture `gameSave` disponible parmi les cinq resourceKinds MCP live |
| `campaign.badge.upsert` | Le flux runtime d'attribution d'un badge |
| `entity.set_item_payload` | Le ramassage, la transaction et l'idempotence d'un objet |
| `campaign.encounter_table.upsert` | Pêche, static/gift, Repel, Surf et consommation persistée |
| `ProjectGameplayReadinessReport` | Une vérification autonome de la fraîcheur des preuves du projet |
| `pokemap_validate` | Un Golden Slice, un walkthrough ou une readiness Pokémon complète |
| `GamePackageBuilder` | La jouabilité ; il attend déjà un arbre runtime préparé et sûr |

`validateBetaPlayability` est par ailleurs permissif : support save/load vrai par
défaut, capture non requise par défaut, absence de starter ou de source de Ball en
warning, et `isPlayable` ignore les warnings. C'est utile pour une beta générique,
mais insuffisant comme certification « fangame Pokémon complet ».

---

## 8. Roadmap proposée — nouveaux lots provisoires

Ces IDs sont **des propositions d'audit**. Ils ne modifient pas la roadmap canonique et
doivent être rebaselinés avec les lots existants avant adoption.

### 8.1 Priorité immédiate — rendre la cible vérifiable

| Lot provisoire | Objet | Critère de sortie principal |
|---|---|---|
| `FG-208` | Pokemon Ruleset Gen-V-inspired v1 | Profil singles Génération V versionné, consommé par core/gameplay/battle/runtime/editor/MCP |
| `FG-209` | Rebaseline roadmap et evidence | Statuts alignés au HEAD, preuves disparues réparées ou retirées |
| `FG-210` | PlayerPokemon Identity v2 | ID stable, formId, OT/IDs, langue, egg/provenance + migration |
| `FG-211` | Canonical Pokémon Catalogue Contracts | Schémas déplacés hors de `map_editor`, loaders et transports alignés |
| `FG-212` | Unified Item Effect Engine | Effets data-driven, contextes, transaction, bag/held/battle/capture |
| `FG-213` | Gift/Starter party→PC policy | Aucun Pokémon offert perdu ou rejeté si une boîte est libre |

### 8.2 Compléter le cœur Pokémon local

| Lot provisoire | Objet | Dépendances |
|---|---|---|
| `FG-214` | Battle order, speed ties et trigger lifecycle Gen V | FG-208 |
| `FG-215` | Damage/status parity closure Gen V | FG-208, FG-214 |
| `FG-216` | Held item player lifecycle | FG-210, FG-212 |
| `FG-217` | Friendship and obedience I–V | FG-208, FG-210 |
| `FG-218` | Wild generation et encounter modifiers | FG-208, FG-210, temps futur |
| `FG-219` | Capture balls I–V et critical capture | FG-208, FG-212, FG-218 |
| `FG-220` | Evolution method registry I–V | FG-208, FG-210 |
| `FG-221` | Move acquisition matrix I–V | TM Génération V réutilisables ; catalogue canonique, FG-212 |
| `FG-222` | PC advanced operations | FG-210, FG-216 |
| `FG-223` | Pokédex forms, regional dex et completion | FG-210, catalogue canonique |
| `FG-224` | FieldAbility framework | Surf migration puis Cut/Strength/Rock Smash/Flash/Waterfall/Dive |
| `FG-225` | Fly et carte interactive | FG-224 |
| `FG-226` | Time/calendar/weather world core | Roadmap runtime générique + FG-208 |
| `FG-227` | Daily world systems | FG-226 ; berries, respawns, swarms, rematches |
| `FG-228` | Trainer AI profiles and scripted bosses | FG-208, combat stable |
| `FG-229` | Gym/Ligue/Hall of Fame templates | Trainers, scenes, rewards, post-game |

### 8.3 Compléments Génération V après le cœur singles

| Lot provisoire | Objet | Positionnement |
|---|---|---|
| `FG-231` | Breeding and Egg lifecycle | Module local avancé |
| `FG-232` | In-game trade and trade evolution | Avant tout online |
| `FG-233` | Battle Facility ruleset | Normalisation, restore, streak, BP, rental |
| `FG-234` | Forms, shiny et ribbons I–V | Identité et post-game compatible avec la cible |

### 8.4 Parking sans lot actif

| Sujet | Décision de roadmap |
|---|---|
| Doubles, Triple et Rotation | Revoir uniquement après la certification singles Génération V |
| Mega, Z-Moves, Dynamax, Téra | Aucun lot actif |
| SOS, Ride et spawns visibles | Aucun lot actif |
| Raids, open world, auto-battle et pique-nique | Aucun lot actif |
| Autosave, mints et crafting de TM | Aucun lot actif |
| Gameplay `Legends` | Exclu de la direction actuelle |
| Online/co-op | Hors cible actuelle ; ne pas confondre avec l'échange local/NPC |

### 8.5 Ordre recommandé

```text
Ruleset + rebaseline
  -> identité individuelle + catalogues + objets
  -> combat fidèle + amitié/obéissance + rencontres/capture
  -> évolutions/moves + PC/Dex + field abilities
  -> temps/météo/monde vivant + IA/templates de progression
  -> breeding/trade local + facilities compatibles Génération V
  -> STOP : certifier la cible avant de rouvrir le parking
```

---

## 9. Checklist de fidélité souvent oubliée

Cette liste doit devenir une base de critères de tests, pas un seul lot :

1. ordre exact des événements de tour ;
2. arrondis exacts des dégâts et statistiques ;
3. RNG déterministe et injectable ;
4. `[LATER]` ciblage et portée en doubles ;
5. `[LATER]` réduction des spread moves ;
6. ordre faint/replacement/end-of-turn ;
7. reset stages/volatiles au switch ;
8. persistance PV, PP et statut majeur ;
9. Struggle si aucun move utilisable ;
10. contact distinct de la catégorie physique ;
11. immunités de type, talent et statut ;
12. ordre des talents, moves, objets et baies ;
13. held items consommés, volés, échangés et write-back ;
14. item non consommé si l'action est rejetée ;
15. restauration en facility/link ;
16. participants exacts à l'XP ;
17. XP simultanée/séquentielle selon profil ;
18. EV yield et caps ;
19. conservation correcte des PV au level-up/évolution ;
20. move learning avec quatre slots, remplacement et refus ;
21. Move Reminder et move memory ;
22. évolutions multi-conditions, annulation et retry ;
23. amitié : gains, pertes, seuils et effets selon le profil Génération V ;
24. obéissance selon OT, met level et progression ;
25. vu distinct de capturé ;
26. forme distincte de l'espèce ;
27. shiny comme propriété individuelle ;
28. OT, IDs, langue et provenance persistants ;
29. capture atomique party/box/Dex ;
30. stockage plein traité explicitement ;
31. `[LATER]` capture en doubles seulement quand autorisée ;
32. rencontre statique idempotente ;
33. roamer conservant PV/statut ;
34. dresseur vaincu idempotent ;
35. rematch comme politique, sans effacer la preuve de première victoire ;
36. blackout transactionnel ;
37. dernier Centre/checkpoint ;
38. argent de victoire et perte de défaite séparés ;
39. FieldAbility séparée du move ;
40. Repel utilisant le membre défini par le ruleset ;
41. temps/météo/saison composables dans les tables ;
42. objet sauvage tenu ;
43. shiny locks authorables ;
44. form changes en combat et retour de forme ;
45. IA produisant des commandes sans muter directement l'état ;
46. rulesets aventure/facility/PvP/raid distincts ;
47. log/replay des décisions ;
48. save au milieu d'un flux sans récompense dupliquée ;
49. diagnostics de références et conditions manquantes ;
50. picker no-code pour tous les IDs importants ;
51. parité API/JSONL/éditeur/MCP/runtime ;
52. distinction support moteur/catalogue réellement fourni.

---

## 10. Audit initial, fichiers et état Git

### 10.1 État Git initial observé avant la création du rapport

```text
modified=54 deleted=0 renamed=0 untracked=15 total=69
```

Les changements préexistants concernent majoritairement Smart Tiles dans
`map_core`, `map_authoring`, `map_editor` et leurs tests. La roadmap générique
`documentation/road_map_runtime_media_cinematics_audio_time.md` était déjà non suivie.
Aucun de ces fichiers n'a été modifié par cet audit.

### 10.2 Fichier créé par l'audit

| Fichier | Raison |
|---|---|
| `documentation/reports/gameplay/audit_exhaustif_mecaniques_pokemon_pokemap_2026-08-02.md` | Livrable consolidé demandé : référentiel web, audit du dépôt, matrice des écarts et roadmap proposée |

Le présent document constitue le contenu complet du seul fichier créé.

### 10.3 Zones de code inspectées

- `pokemap_roadmap_mecaniques_fangame.md` ;
- `packages/map_core/lib/src/models/save_data.dart` ;
- `packages/map_core/lib/src/models/game_state.dart` ;
- `packages/map_core/lib/src/models/project_manifest.dart` ;
- `packages/map_core/lib/src/models/project_trainer.dart` ;
- `packages/map_gameplay/lib/src/new_game_state_builder.dart` ;
- `packages/map_gameplay/lib/src/gameplay_encounter.dart` ;
- `packages/map_gameplay/lib/src/player_item_effects.dart` ;
- `packages/map_gameplay/lib/src/player_storage_operations.dart` ;
- `packages/map_gameplay/lib/src/pokemon_evolution_service.dart` ;
- `packages/map_gameplay/lib/src/pokemon_move_machine_service.dart` ;
- `packages/map_gameplay/lib/src/player_defeat_recovery.dart` ;
- `packages/map_battle/lib/src/data/battle_parity_target.dart` ;
- `packages/map_runtime/lib/src/application` et services joueur ;
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` ;
- `packages/map_runtime/lib/src/player/runtime_player_pause_data_builder.dart` ;
- `packages/map_player_ui/lib/src/player` ;
- `packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart` ;
- `packages/map_authoring` et catalogue live `tools/pokemap_mcp`.

### 10.4 État Git final de la passe principale

```text
modified=54 deleted=0 renamed=0 untracked=16 total=70
```

La seule entrée ajoutée par cet audit par rapport au snapshot initial est le présent
rapport non suivi. Les 54 modifications et les 15 autres fichiers non suivis sont des
changements préexistants conservés sans intervention.

### 10.5 État Git lors du recadrage Génération V

```text
modified=54 deleted=0 renamed=0 untracked=18 total=72
```

Deux autres fichiers non suivis sont apparus dans le worktree après la passe principale.
Ils sont hors du périmètre de ce recadrage et n'ont pas été modifiés ici.

---

## 11. Vérifications fraîches

### 11.1 Tests passants

```text
cd packages/map_core && dart test \
  test/game_state_persistence_test.dart \
  test/save_data_test.dart \
  test/player_roster_validation_test.dart \
  test/project_encounter_conditions_test.dart \
  test/project_trainer_lifecycle_test.dart \
  test/project_trainer_reward_test.dart \
  test/project_gameplay_readiness_test.dart \
  test/golden_slice_readiness_test.dart \
  test/save/game_state_save_envelope_mapper_test.dart \
  test/save/save_compatibility_test.dart \
  test/save/save_migration_test.dart
```

Résultat exact : `+91: All tests passed!`

```text
cd packages/map_gameplay && dart test \
  test/new_game_state_builder_test.dart \
  test/project_new_game_state_builder_test.dart \
  test/player_storage_operations_test.dart \
  test/party_bag_heal_operations_test.dart \
  test/pokemon_evolution_service_test.dart \
  test/pokemon_move_machine_service_test.dart \
  test/player_defeat_recovery_test.dart \
  test/capture_destination_operations_test.dart \
  test/surf_evaluation_test.dart
```

Résultat exact : `+121: All tests passed!`

Une passe dépôt indépendante plus large a également obtenu :

- `map_gameplay` : `+126: All tests passed!` ;
- `map_battle` ciblé hors gate externe : `+19: All tests passed!` ;
- `map_core` ciblé différent : `+81: All tests passed!`.

### 11.2 Tests limités ou bloqués

```text
cd packages/map_battle && dart test \
  test/battle_parity_target_test.dart \
  test/psdk_parity_gate_test.dart
```

Résultat : `+4 -1`. Le contrat `BattleParityTarget` passe ; le test de baseline
PSDK échoue avec :

```text
Bad state: PSDK Studio moves directory not found:
../../pokémon_sdk_test_project/Data/Studio/moves
```

Une passe capability gates indépendante a obtenu `+11 -2` : les deux échecs
proviennent de JSON attendus sous `reports/gameplay/generated/` absents du HEAD.

Les sélections Flutter `map_runtime` et `map_player_ui` ne chargent pas les tests à
cause des changements Smart Tiles préexistants. Erreurs représentatives :

```text
The getter 'materialCells' isn't defined for the type 'SmartTileLayer'.
```

```text
The argument type '... 13 parameters ...' can't be assigned to the parameter
type '... 10 parameters ...' in runtime_manifest_tilesets.dart.
```

La passe runtime indépendante a produit `+29 -11` avant blocage de compilation.
Notre sélection multi-tests a échoué au chargement pour les mêmes causes. Aucun
résultat Flutter vert n'est donc revendiqué.

Trois Golden Slice du host ont également été ciblées : `0` test exécuté et `3`
erreurs de chargement/compilation Smart Tiles. Le renderer manuel s'arrête avec le
code `254` pour la même cause.

### 11.3 MCP

`pokemap_describe` live : succès, `structuredContent.ok=true`, catalogue `PMCP-085`,
229 actions de mutation, cinq resource kinds de query.

La passe `map_authoring` a exécuté `dart run tool/pmcp085_conformance.dart` :
`62 ressources, 229 mutations, 0 cellule manquante`, puis `18` tests ciblés passés.

Dans `tools/pokemap_mcp`, `npm run check` et `npm run build` passent. Sur trois tests
ciblés, deux passent et le rendu réel échoue avec `render.response_invalid`, en aval
de la compilation Smart Tiles.

### 11.4 Analyse et build

- Aucun `dart analyze` ou `flutter analyze` global n'est revendiqué : le chantier
  Smart Tiles en cours rendrait le résultat non représentatif de cet audit.
- Aucun build produit n'est revendiqué.
- `map_distribution` : `49` tests ciblés passent et `1` échoue, car
  `reports/product/pokemap_hub/phase_0/compatibility/compatibility-matrix.json`,
  supprimé du checkout, est encore requis par le test.
- `POKEMAP_MARKDOWN_MAX_NEW=2 bash tools/scripts/check_markdown_hygiene.sh` a été
  relancé après le recadrage. Résultat : `EXIT=0`, avec exactement deux nouveaux
  fichiers Markdown, tous deux dans des emplacements canoniques. Le présent rapport
  pèse 70 512 octets, sous la limite de 262 144 octets.

---

## 12. Verdict des passes imposées

| Passe | Verdict | Justification |
|---|---|---|
| Référentiel web | `PASS` | Taxonomie I–IX, différences de générations, gimmicks et oubliés fréquents recoupés |
| Audit/architecture | `PASS avec risques` | Inventaire code et écarts établis ; roadmap obsolète identifiée |
| Implémentation | `N/A` | Audit uniquement ; aucune implémentation autorisée ou nécessaire |
| Tests purs | `PASS ciblé` | 91 tests core et 121 tests gameplay verts dans la passe principale |
| Battle parity gate | `BLOCKED externe` | Projet PSDK externe absent et preuves JSON générées supprimées |
| Runtime/UI | `BLOCKED worktree` | Compilation Smart Tiles désynchronisée avant chargement des tests |
| Build/distribution | `NO-GO pour certification` | Aucun build vert possible dans l'état courant |
| MCP | `PASS santé / PARTIAL parité` | Describe live vert, mais lectures mécaniques peu découvrables |
| Critique finale | `PASS processus` | Deux relectures indépendantes : `GO` sur le fond, `NO-GO` pour certifier le projet ; statuts, preuves, roadmap, clôture et calibration corrigés |

---

## 13. Risques et décisions

### 13.1 Risques critiques

1. **Fausse promesse de compatibilité.** Sans ruleset, « compatible Pokémon moderne »
   n'est pas mesurable.
2. **Kernel versus produit.** Des centaines d'effets battle ne signifient pas que le
   joueur peut réellement les utiliser dans un parcours complet.
3. **Roadmap obsolète.** Elle sous-estime le code récent et référence des Evidence
   Packs supprimés ; elle ne peut plus servir seule de vérité.
4. **Identité d'individu.** Son absence rend coûteux tout ajout trade/breeding/forms/
   ribbons/PC avancé.
5. **Divergence des objets.** Plusieurs moteurs d'effets risquent des incohérences
   catalogue, UI, battle et write-back.
6. **Schémas liés à l'éditeur.** Le runtime et les transports peuvent diverger d'un
   modèle Pokémon dont le propriétaire n'est pas partagé.
7. **Enums trompeuses.** Des valeurs de modèle donnent une impression de support sans
   boucle runtime.
8. **Validation runtime rouge.** Tant que Smart Tiles ne recompile pas, aucune
   certification player-facing n'est honnête.

Le risque de reproductibilité est concret : `reports/gameplay/`,
`selbrume/project.json`, `selbrume/walkthrough.json` et la matrice de compatibilité
produit référencée par les tests sont absents du checkout. Les anciens rapports sont
consultables dans l'historique Git, mais ne constituent plus une preuve fraîche
reproductible. Les statuts `DONE` de FG-180 à FG-184 doivent donc être réaudités avant
toute certification, même si une partie du code sous-jacent existe toujours. Le gate
FG-185 historique concluait déjà `NO-GO` faute de receipts exécutés ; aucun élément de
cette passe ne renverse ce verdict de release.

### 13.2 Décisions recommandées

- Mettre `FG-208 Ruleset` et `FG-209 Rebaseline` avant de multiplier les mécaniques.
- Stabiliser l'identité individuelle et les catalogues avant breeding/trade/forms.
- Unifier les objets avant d'ajouter baies, Balls et held items avancés.
- Garder tout chantier doubles en parking jusqu'à la certification du ruleset singles.
- Traiter temps/météo comme infrastructure du monde consommée par rencontres,
  évolutions, visuel et audio.
- Ne planifier aucun lot Mega/Z/Dynamax/Téra dans la roadmap active.
- Préparer l'online par déterminisme, logs et validation pure, sans le développer
  avant la boucle locale complète.

---

## 14. Auto-critique

- La série Pokémon contient des centaines de cas particuliers par move, talent,
  objet, forme et génération. Cet audit les regroupe en contrats testables ; il ne
  prétend pas être une preuve bit-perfect de chaque entrée de catalogue.
- Bulbapedia est une source communautaire. Les règles centrales ont été recoupées avec
  des guides officiels, mais une implémentation de parité devra figer ses propres
  références et vectors de tests.
- Les tests runtime rouges empêchent de confirmer fraîchement plusieurs parcours
  player-facing déjà présents dans le code.
- La roadmap a beaucoup évolué depuis ses statuts textuels. Toute bascule vers `DONE`
  exige un Evidence Pack frais et ne doit pas être déduite uniquement de cet audit.
- Certains systèmes sont authorables par scènes génériques sans disposer d'une
  expérience Pokémon dédiée. Ils sont classés `PARTIAL`, car le produit vise le
  no-code guidé plutôt qu'un bricolage de flags.
- Le playtime existe dans l'enveloppe de session via un chronomètre runtime, tandis que
  `TrainerProfile.playtimeSeconds` semble constituer une seconde source non
  synchronisée. L'écart exact doit être caractérisé avant modification.

---

## 15. Bibliographie condensée

### 15.1 Sources officielles

- [Trainer Fundamentals](https://diamondpearl.pokemon.com/en-au/trainersguide/fundamentals/)
- [Battling](https://diamondpearl.pokemon.com/en-us/trainersguide/fundamentals/battling/)
- [Raising and Evolving](https://diamondpearl.pokemon.com/en-au/trainersguide/fundamentals/raising/)
- [Completing the Pokédex](https://diamondpearl.pokemon.com/en-us/trainersguide/pokedex/)
- [Dynamax](https://swordshield.pokemon.com/en-us/gameplay/dynamax-powerful-pokemon/)
- [Max Raid Battles](https://swordshield.pokemon.com/en-us/gameplay/max-raid-battles/how-to-max-raid/)
- [Gigantamax](https://swordshield.pokemon.com/en-us/gameplay/gigantamax/)
- [Hidden Abilities](https://swordshield.pokemon.com/en-us/gameplay/hidden-abilities/)
- [Battle Stadium](https://swordshield.pokemon.com/en-us/gameplay/pokemon-battle-stadium/)
- [Terastal battle rules](https://www.pokemon.co.jp/ex/sv/ja/battle/220822_02/)
- [Terastal overview](https://www.pokemon.co.jp/ex/sv/ja/features/220803_07/)
- [Play! Pokémon VG Rules](https://www.pokemon.com/static-assets/content-assets/cms2/pdf/play-pokemon/rules/play-pokemon-vg-rules-formats-and-penalty-guidelines-en.pdf)

### 15.2 Références transgénérationnelles

- [Core series](https://bulbapedia.bulbagarden.net/wiki/Core_series)
- [Game mechanics](https://bulbapedia.bulbagarden.net/wiki/Category:Game_mechanics)
- [Pokémon battle](https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9mon_battle)
- [Damage](https://bulbapedia.bulbagarden.net/wiki/Damage)
- [Move](https://bulbapedia.bulbagarden.net/wiki/Move)
- [Priority](https://bulbapedia.bulbagarden.net/wiki/Priority)
- [Stat modifier](https://bulbapedia.bulbagarden.net/wiki/Stat_modifier)
- [Status condition](https://bulbapedia.bulbagarden.net/wiki/Status_condition)
- [Ability](https://bulbapedia.bulbagarden.net/wiki/Ability)
- [Held item](https://bulbapedia.bulbagarden.net/wiki/Held_item)
- [Encounter](https://bulbapedia.bulbagarden.net/wiki/Encounter)
- [Mass outbreak](https://bulbapedia.bulbagarden.net/wiki/Mass_outbreak)
- [Repel](https://bulbapedia.bulbagarden.net/wiki/Repel)
- [Catch rate](https://bulbapedia.bulbagarden.net/wiki/Catch_rate)
- [Experience](https://bulbapedia.bulbagarden.net/wiki/Experience)
- [Exp. Share](https://bulbapedia.bulbagarden.net/wiki/Exp._Share)
- [Methods of Evolution](https://bulbapedia.bulbagarden.net/wiki/Methods_of_Evolution)
- [Move Reminder](https://bulbapedia.bulbagarden.net/wiki/Move_Reminder)
- [TM](https://bulbapedia.bulbagarden.net/wiki/TM)
- [Pokémon breeding](https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9mon_breeding)
- [Egg Group](https://bulbapedia.bulbagarden.net/wiki/Egg_Group)
- [Field move](https://bulbapedia.bulbagarden.net/wiki/Field_move)
- [HM](https://bulbapedia.bulbagarden.net/wiki/HM)
- [Time](https://bulbapedia.bulbagarden.net/wiki/Time)
- [Weather](https://bulbapedia.bulbagarden.net/wiki/Weather)
- [Party](https://bulbapedia.bulbagarden.net/wiki/Party)
- [Pokémon Storage System](https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9mon_Storage_System)
- [Pokédex entry](https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9dex_entry)
- [Bag](https://bulbapedia.bulbagarden.net/wiki/Bag)
- [Pokémon Center](https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9mon_Center)
- [Black out](https://bulbapedia.bulbagarden.net/wiki/Black_out)
- [Trade](https://bulbapedia.bulbagarden.net/wiki/Trade)
- [Obedience](https://bulbapedia.bulbagarden.net/wiki/Obedience)
- [Double Battle](https://bulbapedia.bulbagarden.net/wiki/Double_Battle)
- [Battle facility](https://bulbapedia.bulbagarden.net/wiki/Battle_facility)
- [Released Pokémon](https://bulbapedia.bulbagarden.net/wiki/Released_Pok%C3%A9mon)

### 15.3 Pages générationnelles

- [Generation I](https://bulbapedia.bulbagarden.net/wiki/Generation_I)
- [Generation II](https://bulbapedia.bulbagarden.net/wiki/Generation_II)
- [Generation III](https://bulbapedia.bulbagarden.net/wiki/Generation_III)
- [Generation IV](https://bulbapedia.bulbagarden.net/wiki/Generation_IV)
- [Generation V](https://bulbapedia.bulbagarden.net/wiki/Generation_V)
- [Generation VI](https://bulbapedia.bulbagarden.net/wiki/Generation_VI)
- [Generation VII](https://bulbapedia.bulbagarden.net/wiki/Generation_VII)
- [Generation VIII](https://bulbapedia.bulbagarden.net/wiki/Generation_VIII)
- [Generation IX](https://bulbapedia.bulbagarden.net/wiki/Generation_IX)

---

## 16. Conclusion

PokeMap possède déjà l'ossature d'un bon moteur de fangames Pokémon singles. Ce qui
manque n'est plus une seule « grosse feature », mais une couche de définition et de
cohérence transversale : rulesets, identité individuelle, catalogues partagés,
objets unifiés, fidélité combat, rencontres riches, évolution, terrain, temps et
parité no-code.

Le prochain meilleur investissement est donc de **définir le contrat Pokémon du
moteur**, puis de rebaseliner la roadmap et de certifier une aventure singles de type
Génération V. Le breeding, l'échange local et les facilities pourront suivre ce cœur ;
les doubles resteront `LATER`, et les gimmicks postérieurs resteront `PARKED`. C'est ce
qui transformera le socle actuel d'un RPG de capture très avancé en un moteur Pokémon
dont les promesses sont précises, testables et durables.
