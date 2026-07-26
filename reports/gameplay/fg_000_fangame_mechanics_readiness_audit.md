# FG-000 — Audit complet de préparation fangame et comparaison Pokémon

Date de l'audit : 2026-07-26

Lot canonique : `FG-000 — Fangame Mechanics Readiness Audit V0`

Périmètre : monorepo PokeMap, fixture Selbrume, applications Player/Hub, authoring no-code, distribution et expérience joueur

Verdict global : **PARTIEL / NO-GO validation — solide vertical slice, pas encore une expérience Pokémon mainline complète ni une plateforme profondément personnalisable**

Statut proposé du lot documentaire après finalisation de cette preuve : **`DONE` pour l'audit FG-000 uniquement** ; ce statut ne vaut ni validation du produit ni release

Modification de la roadmap : **aucune**, conformément à la demande qui porte sur un audit et non sur sa mise à jour

---

## 1. Résumé exécutif

PokeMap n'est plus un simple prototype de carte. Le dépôt contient un vrai socle de fangame :

- création d'une nouvelle partie à partir de données auteur ;
- choix de starter ;
- exploration, collisions, connexions de cartes, NPC, dialogues et choix ;
- rencontres sauvages, capture, party et stockage PC ;
- combats singles sauvages et trainers ;
- persistance des PV, PP et statuts ;
- XP, niveaux, apprentissage d'attaques et évolution par niveau ;
- récompenses, argent, objets et faits de progression ;
- Sac, boutique, soin, PC, Pokédex en lecture seule et menu pause ;
- sauvegarde transactionnelle, chargement et reprise depuis le Hub ;
- éditeur no-code déjà riche, validations et Golden Slice Selbrume ;
- shell joueur responsive, clavier, tactile et gamepad.

La conclusion n'est toutefois pas « PokeMap a toutes les fonctions d'un jeu Pokémon ». Les plus gros écarts ne sont plus uniquement des fonctions absentes : ce sont surtout des ruptures entre les couches.

1. Le moteur de combat sait faire davantage que le runtime ne permet réellement de jouer.
2. L'éditeur expose parfois des réglages que le runtime PSDK ignore ou dégrade.
3. Plusieurs menus existent mais restent surtout consultatifs.
4. La campagne peut poser ses faits finaux, mais aucun flux gameplay ne conduit encore au résultat et aux crédits.
5. La preuve de release `FG-185` reste **NO-GO** : son receipt canonique manque et trois tests d'intégration/validation Selbrume sont actuellement rouges, même si le moteur de bataille, les analyses, l'E2E joueur ciblé et le build Hub sont verts.
6. La personnalisation exportée se limite aujourd'hui surtout à quelques métadonnées et illustrations de bibliothèque ; elle ne constitue pas encore un véritable **Personalization Hub**.

Le meilleur ordre de travail n'est donc pas d'ajouter immédiatement une longue liste de gadgets Pokémon. Il faut d'abord fermer les ruptures produit : vérité authoring/runtime, parcours Golden Slice jusqu'aux crédits, décisions de combat, rencontres, menus jouables et contrat de présentation. L'introduction vidéo peut être le premier résultat visible du Personalization Hub, mais elle doit reposer sur un contrat de présentation versionné plutôt que sur un lecteur vidéo ajouté isolément à un écran.

---

## 2. Définition des statuts

| Statut | Signification dans cet audit |
|---|---|
| **COMPLET V0** | Le parcours défini est modélisé, authorable quand nécessaire, exécuté dans le runtime, visible/utilisable par le joueur, persisté si nécessaire et couvert par une preuve fraîche ou un test pertinent. |
| **PARTIEL** | Une partie substantielle existe, mais il manque une couche, une profondeur Pokémon importante ou une preuve bout-en-bout. |
| **CONTRAT SEUL** | Le modèle, le moteur ou le service existe, mais le joueur ou l'auteur ne peut pas encore en profiter honnêtement. |
| **ABSENT** | Aucun flux produit significatif n'a été identifié. |
| **DEFERRED** | Élément explicitement repoussé après le MVP ; son absence n'est pas un blocage du Golden Slice actuel. |
| **NO-GO** | La fonctionnalité peut exister, mais la preuve requise pour une revendication de release n'est pas satisfaite. |

Le qualificatif **fort** signifie qu'une large majorité du parcours existe mais qu'une rupture de couche ou une preuve précise manque encore. Les statuts composites tels que **COMPLET V0 / PARTIEL Pokémon** séparent la fermeture du lot PokeMap défini de la profondeur du benchmark mainline. Une plage telle que **ABSENT à PARTIEL** signifie que des fondations adjacentes existent, sans constituer encore la capacité produit nommée.

Un lot peut être `DONE` dans son périmètre V0 tout en restant `PARTIEL` face à toute la profondeur d'un jeu Pokémon. Par exemple, la formule de capture V0 est fermée, mais les familles de Balls et les métadonnées complètes d'un Pokémon capturé ne le sont pas.

---

## 3. Référence Pokémon utilisée

Comparer à « un jeu Pokémon » sans définir de cible produirait une fausse précision : les générations n'ont ni les mêmes mécaniques ni les mêmes fonctionnalités. Cet audit retient :

- un **socle mainline solo classique**, inspiré notamment de Pokémon Brilliant Diamond / Shining Pearl ;
- quelques commodités modernes de Pokémon Sword / Shield ;
- les fonctions propres à une génération — concours, raids, Dynamax, camping, souterrains — comme références avancées et non comme critères bloquants du MVP PokeMap.

Les sources officielles utilisées décrivent notamment :

- les combats sauvages, de trainers et d'arènes, les types, PP, statuts, objets tenus, doubles, récompenses, badges et capacités de terrain dans le [guide officiel des combats BDSP](https://diamondpearl.pokemon.com/en-us/trainersguide/fundamentals/battling/) ;
- l'exploration, la bicyclette, la météo et les capacités de terrain telles que Cut, Fly, Surf, Waterfall ou Rock Climb dans le [guide officiel de Sinnoh](https://diamondpearl.pokemon.com/en-us/trainersguide/fundamentals/sinnoh/) ;
- les évolutions, l'amitié, les œufs et la pension dans le [guide officiel d'élevage BDSP](https://diamondpearl.pokemon.com/en-ca/trainersguide/fundamentals/raising/) ;
- le Pokédex vu/capturé, l'après-histoire et les rematches dans le [guide officiel du Pokédex BDSP](https://diamondpearl.pokemon.com/en-us/trainersguide/pokedex/) ;
- les fonctions facultatives comme les Grands Souterrains, bases secrètes et concours dans les [fonctionnalités officielles BDSP](https://diamondpearl.pokemon.com/en-au/features/) ;
- les boîtes accessibles, surnoms et sauvegardes modernes dans les [fonctionnalités d'aventure Sword / Shield](https://swordshield.pokemon.com/en-gb/gameplay/features-adventure/) ;
- la zone sauvage et sa météo dans la [présentation officielle Wild Area](https://swordshield.pokemon.com/en-gb/gameplay/wild-area/) ;
- les mécaniques générationnelles optionnelles dans les pages officielles [Dynamax](https://swordshield.pokemon.com/en-us/gameplay/pokemon-become-huge-dynamax/), [Max Raid Battles](https://swordshield.pokemon.com/en-us/gameplay/max-raid-battles/how-to-max-raid/) et [Pokémon Camp](https://swordshield.pokemon.com/en-ca/gameplay/pokemon-camps/).

Cette comparaison n'évalue ni l'utilisation d'assets officiels, ni la conformité juridique d'un fangame, ni une égalité au pixel près. Elle évalue la capacité fonctionnelle à produire un RPG de capture et de combat comparable.

---

## 4. Méthode et hiérarchie des preuves

### 4.1 Hiérarchie

Les conclusions suivent cet ordre :

1. code actuel et exécution fraîche ;
2. tests et fixtures actuels ;
3. rapports récents ;
4. roadmap ;
5. anciens plans et rapports historiques.

Lorsqu'un rapport historique contredit le code ou une preuve récente, il est traité comme une photographie périmée et non comme une source de vérité.

### 4.2 Passes réalisées

L'audit a été divisé en passes indépendantes :

1. règles, roadmap, rapports et état Git ;
2. architecture, contrats et authoring ;
3. combat, capture et progression ;
4. runtime, UX joueur, sauvegardes et personnalisation ;
5. tests complets, analyses statiques et build ;
6. critique finale du rapport.

### 4.3 Limites assumées

- aucune génération Pokémon cible n'a été imposée ;
- aucun playtest humain complet sur appareil n'a été réalisé ;
- la parité de chaque attaque, talent et objet du moteur PSDK n'a pas été recalculée manuellement ;
- les statuts sont qualitatifs, sans pourcentage inventé ;
- les sept modifications déjà présentes dans le worktree ont été conservées et auditées comme état préexistant ;
- les fonctionnalités de personnalisation sont évaluées comme capacité de plateforme PokeMap, pas comme copie d'une option des jeux Pokémon commerciaux.

---

## 5. État Git initial

Branche : `main`

HEAD observé : `42005e3f2757` — `finish runtime input locks and touch controls`

```text
 M apps/pokemap_hub/lib/src/ui/hub_app.dart
 M apps/pokemap_hub/lib/src/ui/hub_shell.dart
 M apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
 M apps/pokemap_hub/test/ui/hub_preferences_store_test.dart
 M apps/pokemap_hub/test/ui/hub_shell_test.dart
 M packages/map_player_ui/lib/src/localization/player_localizations.dart
 M packages/map_player_ui/lib/src/preferences/player_preferences.dart
```

Ces sept changements sont préexistants et hors du périmètre d'écriture de l'audit. Ils ajoutent notamment une préférence `launchMostRecentGameOnStartup`. Attention : le code observé ouvre le premier jeu sain de `snapshot.games`, sans preuve que ce jeu soit effectivement le dernier joué ; le libellé peut donc être trompeur.

---

## 6. Cartographie de l'architecture

| Couche | Rôle réel observé | Maturité |
|---|---|---|
| `packages/map_core` | Modèles, JSON, catalogues, validations, projet, état joueur, scènes, trainers, shops, encounters | **Solide**, mais quelques contrats Pokémon et tout le contrat de présentation profonde manquent |
| `packages/map_gameplay` | Opérations pures : nouvelle partie, party/PC, progression, récompenses, objets, règles overworld | **Solide V0** |
| `packages/map_battle` | Moteur singles PSDK, attaques, types, statuts, objets, talents, IA et scaffolding avancé | **Très riche en interne**, mais parité cible non contractualisée |
| `packages/map_runtime` | Flame, exploration, scènes, rencontres, combat, services contextuels, persistance et overlays | **Fonctionnel mais partiellement branché** |
| `packages/map_editor` | Authoring desktop no-code, bibliothèques, inspecteurs, validations, previews | **Large et cohérent**, mais certains contrôles dépassent les capacités réelles du runtime |
| `packages/map_distribution` | Manifest, packaging et branding d'un jeu exporté | **Fondation partielle** |
| `packages/map_player_ui` | Shell joueur, titre, pause, préférences et surfaces de résultat/crédits | **Solide comme shell**, options et personnalisation partiellement consommées |
| `apps/pokemap_hub` | Bibliothèque de jeux installés, lancement, stockage de sauvegardes et préférences | **Boucle minimale complète**, intégration branding/personnalisation incomplète |
| `examples/playable_runtime_host` | Host, Selbrume et preuves de parcours | **Fixture Golden Slice forte**, pas encore E2E appareil jusqu'aux crédits |

Les frontières de packages sont globalement saines : les règles de jeu restent dans les packages Dart purs, le runtime porte Flame, et l'éditeur ne dépend pas des détails internes du runtime. Le problème principal est la **parité de capacité entre ces couches**, pas leur découpage.

### 6.1 Inventaire des sources à haut signal inspectées

Cet inventaire n'est pas la liste de tous les fichiers du monorepo ; il relie les principaux verdicts aux sources de vérité réellement consultées.

| Sujet | Sources principales |
|---|---|
| New Game / starter | `packages/map_core/lib/src/models/project_new_game_config.dart`, `packages/map_gameplay/lib/src/new_game_state_builder.dart`, `packages/map_runtime/test/playable_map_game_project_new_game_boot_test.dart`, `packages/map_runtime/test/selbrume_new_game_starter_integration_test.dart` |
| État et persistance Pokémon | `packages/map_core/lib/src/models/save_data.dart`, `packages/map_core/lib/src/save/game_state_save_envelope_mapper.dart`, rapports `FG-020`/`FG-040` |
| Commandes narratives | `packages/map_core/lib/src/read_models/narrative_command_catalog.dart`, `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart`, `reports/gameplay/fg_082_093_narrative_command_runtime_parity.md` |
| Combat PSDK | `packages/map_battle/lib/src/psdk/`, `packages/map_battle/lib/src/domain/ai/psdk_battle_ai.dart`, `packages/map_runtime/lib/src/application/runtime_psdk_battle_setup_mapper.dart`, `packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart` |
| Récompenses/progression | `packages/map_gameplay/lib/src/battle_reward.dart`, `packages/map_runtime/lib/src/application/runtime_battle_reward_resolver.dart`, tests progression et post-battle cités en section 13 |
| Branding/distribution | `packages/map_distribution/lib/src/game_package_manifest.dart`, `packages/map_distribution/lib/src/game_package_manifest_codec.dart` |
| UI et préférences joueur | `packages/map_player_ui/lib/src/player/player_title_screen.dart`, `packages/map_player_ui/lib/src/preferences/player_preferences.dart` |
| Wiring Hub | `apps/pokemap_hub/lib/src/ui/player/hub_installed_game_player.dart`, `apps/pokemap_hub/lib/src/player/hub_player_save_gateway.dart` |
| Menus runtime | `reports/gameplay/fg_160_165_phase_9_runtime_menus_ux_completion.md` et rapports individuels `FG-160` à `FG-165` |
| Readiness/release | `reports/gameplay/fg_180_project_gameplay_readiness_report_v0.md`, `fg_181_golden_slice_fangame_fixture_v0.md`, `fg_182_golden_slice_end_to_end_smoke_v0.md`, `fg_183_regression_matrix_v0.md`, `fg_184_roadmap_status_dashboard_generator_v0.md`, `fg_185_mvp_release_gate_v0.md` |
| Parité combat contradictoire | `reports/psdk-fight-parity-audit.json`, `reports/psdk-fight-parity-audit.md`, `reports/analysis/psdk_fight_parity_gate_policy.md`, anciens rapports sous `reports/previous/` |
| Roadmap et règles | `pokemap_roadmap_mecaniques_fangame.md`, `AGENTS.md`, `codex_rule.md`, `skills/README.md` et skills de parallélisation/vérification/review |

---

## 7. Tableau de synthèse face à un jeu Pokémon

| Domaine | PokeMap aujourd'hui | Verdict | Écart principal |
|---|---|---|---|
| New Game, starter, boot | Flux projet réel et testé | **COMPLET V0** | Identité joueur et slots multiples |
| Exploration | Cartes, collisions, connexions, interactions | **COMPLET V0** | Véhicules, environnement et field moves étendus |
| Dialogues et événements | Modèle riche, 18 commandes publiables, runtime et builder | **PARTIEL fort** | Templates, cohérence globale et fin de jeu |
| Rencontres | Marche/Surf, statiques et cadeaux partiellement disponibles | **PARTIEL** | Conditions, fishing/headbutt, taux et vérité editor/runtime |
| Capture | Formule, débit, party/PC, seen/caught | **COMPLET V0** | Une seule Ball, métadonnées capturées incomplètes |
| Party et PC | Backend robuste, reorder/lead, écran PC | **PARTIEL fort** | Summary PC, opérations/UX modernes, surnoms |
| Combat singles | Vrai moteur PSDK et intégration runtime | **COMPLET V0 / PARTIEL Pokémon** | IA authorée ignorée, décisions items/fuite/switch, cible génération |
| Progression | XP, niveau, moves et évolution par niveau | **COMPLET V0** | Exp Share, évolutions variées, amitié |
| Objets et Sac | Médecines, cures, revive, PP, achat | **PARTIEL fort** | Objets tenus, TM/HM, repel, Ball families, vente |
| Trainers, badges, arènes | Trainers, défaite, dialogues, rewards, flags/badges possibles | **PARTIEL** | Flux trainer→badge, templates d'arène, rematches |
| Menus joueur | Pause, équipe, Sac, Pokédex, PC, shop, heal | **PARTIEL** | Plusieurs écrans surtout read-only, Carte désactivée |
| Sauvegarde | Backend transactionnel, migration, reprise Hub | **PARTIEL UX / COMPLET backend** | Profils/slots, gestion et choix réel de sauvegarde |
| Fin de jeu | Contrats résultat/crédits présents | **CONTRAT SEUL** | Aucun `Finish Game` authorable ni émission runtime |
| Distribution | Manifest, installation et branding partiel | **PARTIEL** | Validation média, présentation et build multi-plateforme |
| Personnalisation | Quelques assets et préférences globales | **ABSENT à PARTIEL** | Aucun Personalization Hub, vidéo, fonte ou thème par projet |
| Fonctions avancées | Scaffolding doubles/Mega/Z partiel dans le moteur | **DEFERRED produit** | Pas authorable/jouable ; online, breeding, contests absents |

---

## 8. Audit détaillé des fonctionnalités

### 8.1 Démarrage, profil et présentation

| Fonction Pokémon | Statut | Présent dans PokeMap | Manque pour être complet |
|---|---|---|---|
| Écran titre | **PARTIEL** | `PlayerTitleScreen`, logo/fond/accent possibles au niveau widget | Options et crédits ne sont pas des actions actives ; branding exporté non injecté |
| Vidéo / séquence d'introduction | **ABSENT** | Cinématiques caméra/dialogue/fade/audio/FX | Contrat vidéo, formats, packaging, player, skip, sous-titres, fallback et preview |
| Nouvelle partie | **COMPLET V0** | `ProjectNewGameConfig`, builder pur et boot runtime | Confirmation d'écrasement et véritable choix de slot |
| Continuer / Charger | **PARTIEL** | Dernière sauvegarde et reprise fonctionnelles | Les deux actions ciblent pratiquement la même sauvegarde ; aucun navigateur de slots |
| Profils et slots de sauvegarde | **CONTRAT SEUL / PARTIEL** | IDs de profil/slot et isolation backend | UI, création, renommage, suppression, métadonnées, screenshots |
| Nom du joueur | **ABSENT** | Valeur de configuration auteur possible | Saisie joueur, validation, utilisation dans les dialogues |
| Avatar / genre / pronoms | **ABSENT** | Aucun flow joueur identifié | Modèle, authoring, sélection et rendu |
| Apparence joueur | **ABSENT** | Sprite de projet | Choix de tenue/apparence ou variantes |
| Starter | **COMPLET V0** | Choix explicite Selbrume, runtime et idempotence | Authoring initial party plus profond et routage PC si plein |
| Tutoriel initial | **PARTIEL** | Scènes/dialogues authorables | Template et préférence hints réellement consommée |
| Crédits / À propos | **CONTRAT SEUL** | Surfaces UI et coordinateur testés | Action titre active et déclenchement gameplay |

### 8.2 Monde, exploration et déplacement

| Fonction Pokémon | Statut | Présent | Manque |
|---|---|---|---|
| Cartes tile-based | **COMPLET V0** | Modèles, éditeur, runtime Flame | — pour le périmètre de base |
| Collisions | **COMPLET V0** | Collision et blocages runtime | Validation globale plus explicite |
| Connexions / warps | **COMPLET V0** | Connexions physiques et commande Warp | Templates et simulation de parcours plus avancés |
| NPC interactifs | **COMPLET V0** | NPC, facing, dialogues et règles de présence | Commandes de déplacement/présence complètement fermées |
| Signalétique / objets interactifs | **PARTIEL** | Sources physiques réutilisables, scènes | Bibliothèque de templates et conventions unifiées |
| Course / bicyclette | **ABSENT** | Déplacement de base | États de mouvement, animation, vitesse, montage |
| Surf | **PARTIEL** | Zone/gate authorée et unlock | Traversée runtime Golden Slice et encounter conditions à fermer |
| Cut / Strength / Rock Smash / Flash | **DEFERRED** | Aucun parcours produit complet | Obstacles, animations, validation et authoring |
| Fly / fast travel | **DEFERRED / ABSENT** | Warp générique, pas de Carte runtime | Carte, destinations débloquées, animation et sécurité de spawn |
| Waterfall / Dive | **DEFERRED** | — | Mécaniques entières |
| Hazards overworld | **CONTRAT SEUL** | Modèles repérés | Consommation runtime, dégâts/effets et feedback |
| Météo et heure du monde | **ABSENT à PARTIEL** | Météo/terrain surtout côté combat | Système overworld, rendu, conditions d'encounter et persistance |
| Environnements sombres | **DEFERRED** | — | Flash/dark zone |
| Carte du monde | **ABSENT produit** | Capacité `map.v1` prévue | Provider Hub, écran, position, fast travel |
| Quêtes / journal | **ABSENT** | Faits/variables permettent une implémentation artisanale | Modèle de quête, objectifs, journal et authoring |

### 8.3 Dialogues, scènes et narration

| Fonction | Statut | Présent | Manque |
|---|---|---|---|
| Dialogue simple | **COMPLET V0** | Texte, séquences et interactions | Localisation contenu à industrialiser |
| Choix de dialogue | **COMPLET V0** | Choix compilés et runtime | Prévisualisation exhaustive de toutes branches |
| Conditions flags/variables | **PARTIEL fort** | Builder, exécution et persistance | Conditions Pokémon plus riches et validation globale |
| Actions no-code | **PARTIEL fort** | 18 commandes publiables, parité catalogue/runtime testée | Fermeture officielle des lots et suppression des preuves périmées |
| Caméra, mouvement, facing, emote | **PARTIEL fort** | Sink cinématique Flame | Templates, skip et accessibilité |
| Fades, shakes, sons et FX | **PARTIEL fort** | Contrats et adapter audio/FX | Mixer global, réglages joueur, preview auteur |
| Don/retrait d'objet | **PARTIEL fort** | Authorable et runtime | Gate globale et catalogues avancés |
| Don de Pokémon | **PARTIEL** | Contrat/commande | Party pleine vers PC et métadonnées complètes |
| Heal party | **PARTIEL fort** | `SceneHealPartyConsequence`, catalogue, writer runtime, authoring et poste de soin | Parcours joueur/promotion E2E globale encore non prouvé |
| Démarrer combat trainer | **PARTIEL fort** | Flux réel existant | Contrat command lot et parité complète |
| Démarrer rencontre statique | **PARTIEL** | Scaffolding/flux | Closure authoring/runtime/consumed state |
| Badge / field unlock | **PARTIEL** | Commandes persistantes, Surf lié à un badge dans Selbrume | Parcours complet avant/après unlock |
| Déplacement/présence NPC | **PARTIEL** | Règles monde/faits et mouvement cinématique | Commandes spécialisées unifiées |
| Templates d'événements | **ABSENT à PARTIEL** | Quelques fixtures réutilisables | Bibliothèque officielle : pickup, heal, rival, gym, fin |
| Fin de chapitre / jeu | **ABSENT runtime** | Faits finaux et contrat `GameCompletionRequest` | Commande no-code `Finish Game`, résultat, crédits et reprise postgame |

### 8.4 Données Pokémon, collection, party et PC

| Fonction Pokémon | Statut | Présent | Manque |
|---|---|---|---|
| Espèces et catalogues | **PARTIEL fort** | Données riches et hydratation | Cible de génération et audit exhaustif moderne |
| Moves et PP | **PARTIEL fort** | Moves, PP max/courant, write-back | Parité ciblée, Struggle automatique |
| Types | **PARTIEL fort** | Calcul moteur riche | Gate produit explicite par génération |
| Stats, IV et EV | **PARTIEL** | Persistés et utilisés en partie | UX avancée, adversaires réalistes, entraînement EV |
| Natures | **CONTRAT SEUL / PARTIEL** | Persistées | Calcul runtime utilise une nature neutre dans le bridge observé |
| Talents | **PARTIEL** | Moteur PSDK riche, champ persistant | Bridge/authoring/parité bout-en-bout |
| Genre, formes, shiny | **PARTIEL** | Champs trainer et joueur partiels | Rendu, capture et propagation fiables |
| Objets tenus | **CONTRAT SEUL / PARTIEL** | Champ et registre PSDK | Seed runtime, opérations joueur et write-back |
| Surnoms | **ABSENT** | — | Modèle, UI de nommage, affichage |
| Amitié | **ABSENT** | — | Valeur, évolution, événements et feedback |
| Métadonnées de rencontre | **ABSENT à PARTIEL** | Espèce/niveau essentiels | lieu/date/dresseur/origine, Ball, personnalité |
| Party de 1 à 6 | **COMPLET V0** | Persistance, validations et menu | Interactions plus riches depuis le menu |
| Réorganisation / lead | **COMPLET V0** | Opérations pures et UI testées | Drag/drop et confort avancé |
| Résumé Pokémon | **COMPLET V0** | PV, XP, statut, nature, talent, objet, moves/PP | Stats détaillées modernes et accès depuis toutes les surfaces |
| PC / boxes | **PARTIEL fort** | 8×30 slots, retrait/dépôt/swap, protections | Summary depuis PC, filtres, recherche, multi-sélection |
| Destination capture party/PC | **COMPLET V0** | Routage atomique et PC plein typé | Métadonnées de capture |
| Pokédex vu/capturé | **COMPLET V0** | Données et écran read-only | Recherche, habitats, formes, complétion moderne |
| Breeding / pension / œufs | **DEFERRED** | — | Système complet |

### 8.5 Rencontres et capture

| Fonction Pokémon | Statut | Présent | Manque |
|---|---|---|---|
| Rencontre herbes/marche | **PARTIEL** | Déclenchement organique runtime | Taux auteur, conditions temps/météo, repel, feedback |
| Rencontre Surf | **PARTIEL** | Type exposé et logique partielle | Traversée et conditions réellement prouvées |
| Rencontres par biome/map | **PARTIEL fort** | Tables authorables | Cohérence entre tous les kinds exposés et réellement déclenchables |
| Rencontre statique | **PARTIEL** | Commande/flux partiels | État consumed, validation et E2E |
| Pokémon cadeau | **PARTIEL** | Commande partielle | Routage PC, métadonnées, UX |
| Pêche | **DEFERRED** | Kind possiblement exposé | Tentative, timing, table, animation |
| Headbutt | **DEFERRED** | Kind possiblement exposé | Action terrain et tables |
| Conditions rencontre | **PARTIEL** | Modèles et certains contextes | Heure, météo, progression, lead, repel et authoring honnête |
| Taux de rencontre | **PARTIEL** | Valeur runtime fixe observée pour le flux organique | Taux par zone/table et outils de simulation |
| Formule de capture | **COMPLET V0** | HP, catch rate, statut et RNG injecté | Détails de génération choisis et shakes de présentation |
| Consommation de Ball | **COMPLET V0** | Débit atomique et receipt | Familles de Balls |
| Familles de Balls | **DEFERRED** | Une Poké Ball minimale | Modificateurs et UX |
| Échec PC plein | **COMPLET V0** | Refus typé avant débit | Message/flow joueur à polir |

Risque produit : l'éditeur expose plusieurs `EncounterKind`, mais le déclenchement organique observé ne ferme honnêtement que marche et Surf partiel. Tant que la matrice authoring→runtime n'est pas une gate, l'interface peut promettre plus que le jeu n'exécute.

### 8.6 Combat

| Fonction Pokémon | Statut | Présent | Manque |
|---|---|---|---|
| Combat sauvage singles | **COMPLET V0** | Setup PSDK, UI, outcome et persistance | Polissage et cible de parité |
| Combat trainer singles | **COMPLET V0** | Équipes, réserves, récompenses, dialogue post-combat | Difficulté réellement branchée |
| Ordre, priorité, vitesse | **PARTIEL fort** | Buckets, priorité, vitesse, Trick Room, Round | Égalités de vitesse aléatoires selon règle choisie |
| Accuracy / esquive | **PARTIEL fort** | Resolver et stages | Gate générationnelle |
| Types / immunités / STAB | **PARTIEL fort** | Pipeline PSDK riche | Couverture produit des moves bridgeables |
| Critiques | **PARTIEL fort** | Resolver PSDK | Paramètres de génération contractualisés |
| Statuts majeurs | **COMPLET V0 / PARTIEL parité** | poison, toxique, brûlure, paralysie, sommeil, gel, residuals | Nuances exactes générationnelles |
| Altérations secondaires | **PARTIEL fort** | Large moteur PSDK | Audit de chaque move/talent |
| PP | **COMPLET V0 / PARTIEL flow** | Seed, consommation, Pressure, write-back | Struggle automatique si aucune attaque légale |
| Switch volontaire | **PARTIEL** | Moteur et UI partiels | Contrat décisionnel unifié et UX durcie |
| Remplacement après K.O. | **PARTIEL** | Remplacement et réserves | `FG-052`, choix forcé UX |
| Fuite | **PARTIEL / incohérent** | Action de présentation legacy | `BattleEngineDecisionRequest` refuse la décision de fuite PSDK |
| Sac en combat | **PARTIEL** | Quatre soins PV ciblant l'actif | Cures, revive, cible party, décision générique |
| Objets tenus | **CONTRAT SEUL côté produit** | Registre PSDK riche | Seed/runtime/write-back/authoring honnête |
| IA trainer | **PARTIEL critique** | IA PSDK sait scorer et peut théoriquement switch/item | Runtime impose niveau 2, `canSwitch:false`, `canUseItem:false`; difficulté auteur ignorée |
| Capture pendant combat | **COMPLET V0** | Formule partagée et outcome runtime | Présentation et familles de Balls |
| Récompenses | **COMPLET V0 / PARTIEL badge** | Argent, objets, flags et modèle badge | Trainer authoré ne porte pas directement badge/field ability |
| Persistance post-combat | **PARTIEL fort** | PV, PP, statut, XP, moves, évolution et rewards | Objet tenu muté/consommé, métadonnées capture |
| Défaite / whiteout | **PARTIEL** | Recovery minimal | Centre, perte d'argent, message et reprise mainline |
| Doubles | **DEFERRED produit** | Scaffolding PSDK riche | Setup, UI, targeting et runtime jouable |
| Mega / Z | **DEFERRED produit** | Certaines actions testées en interne | Décision/UI/editor/runtime |
| Tera / Dynamax | **DEFERRED / ABSENT** | Pas de mécanique produit | Système complet si génération cible le demande |

Point critique : les audits PSDK ne doivent pas être présentés comme une parité Pokémon bout-en-bout. Le JSON actuel annonce notamment `728/728` attaques connues, `330/330` méthodes et `482/482` effets portés, alors que des rapports plus anciens annoncent `658/728` et `306/330`, et que le bridge runtime courant ne déclare que `20/28` cas bridgeables avec huit rejets expliqués. Cette divergence de version et de définition justifie `FG-053`.

### 8.7 Progression

| Fonction Pokémon | Statut | Présent | Manque |
|---|---|---|---|
| Gain d'XP | **COMPLET V0** | Participants, multi-adversaires, courbes | Formule cible et Exp Share |
| Courbes d'XP | **COMPLET V0** | Sept courbes | Vérification génération choisie |
| Level-up | **COMPLET V0** | Multi-level, cap, stats/PV | Présentation plus riche |
| Apprentissage d'attaque | **COMPLET V0** | Ajout, remplacement, refus | Rappel d'attaques et TM |
| Évolution niveau | **COMPLET V0** | Accept/refuse et conservation d'état | Animation/présentation approfondie |
| Évolutions objet/échange/amitié/lieu | **ABSENT / DEFERRED** | — | Conditions et UI |
| Argent | **COMPLET V0** | Gain, dépense, persistance | Perte à la défaite, plafonds/polish |
| Objets récompense | **COMPLET V0** | Grants persistants et idempotents | UX de présentation |
| Flags/variables | **COMPLET V0** | Mutations et conditions | Debug/story inspector plus global |
| Badges | **PARTIEL** | Définitions, commandes et exemple Selbrume | Flux trainer→badge et écran badge |
| Field unlock | **PARTIEL** | Commande et gate Surf | Parcours runtime complet |
| Rival et follow-up | **PARTIEL** | Selbrume et hooks | Template authoring canonique |
| Rematches | **DEFERRED** | Politique désactivée par défaut | Système complet |
| Postgame | **ABSENT** | — | État après crédits, contenus et rematches |

### 8.8 Objets, économie et services

| Fonction Pokémon | Statut | Présent | Manque |
|---|---|---|---|
| Inventaire catégorisé | **COMPLET V0** | Catégories, quantités et validations | Catalogue Pokémon plus exhaustif |
| Médecines hors combat | **COMPLET V0** | Cible, consommation et sauvegarde | Confort UX |
| Cures de statut | **COMPLET V0** | Antidote, sommeil, paralysie, brûlure/glace/full heal | — pour V0 |
| Revive | **COMPLET V0** | Effet et tests | Max Revive et variantes |
| Restauration PP | **COMPLET V0** | Registry | UI/catalogue plus étendu |
| Key items | **PARTIEL** | Catégorie et certains unlocks | Gates généralisées, non-consommabilité |
| Repel | **DEFERRED** | — | Durée, pas, encounter filtering |
| Objets au sol | **PARTIEL** | Give item et sources physiques possibles | Template pickup, sprite, consumed state |
| Objets cachés | **ABSENT** | — | Détection, feedback et authoring |
| Objets tenus | **PARTIEL moteur / ABSENT UX** | Registre battle et champ de données | Donner/retirer/échanger, seed et write-back |
| TM/HM | **ABSENT** | Moves apprenables par level-up | Item, compatibilité, consommation et UX |
| Boutique achat | **COMPLET V0** | Prix, stock, argent, quantité, dynamic profiles | — pour V0 |
| Boutique vente | **ABSENT** | Aucun flux complet identifié | Prix de revente et UI |
| Boutique dynamique | **COMPLET V0** | État, conditions, builder, simulation et Selbrume | Polish |
| Centre Pokémon | **COMPLET V0 service / PARTIEL preuve globale** | Soin contextuel, `SceneHealPartyConsequence`, writer et sauvegarde | Parcours/promotion E2E globale encore non prouvé |
| PC | **COMPLET V0 service / PARTIEL UX** | Dépôt/retrait/swap | Summary, recherche et polish |
| Crafting / curry / cuisine | **DEFERRED / ABSENT** | — | Non requis pour le MVP |

### 8.9 Trainers, arènes et structure d'histoire

| Fonction Pokémon | Statut | Présent | Manque |
|---|---|---|---|
| Trainers visibles | **COMPLET V0** | Modèles, équipes et déclenchement | Vision cones avancés si souhaités |
| Équipes authorées | **PARTIEL fort** | Espèce, niveau, moves, held item, forme, genre, shiny | Plusieurs champs avancés ne traversent pas le bridge |
| Difficulté trainer | **CONTRAT SEUL côté PSDK** | Valeur 1–10 authorable | IA runtime configurée depuis cette valeur |
| Politique trainer vaincu | **PARTIEL fort** | Flag, non-redéclenchement, dialogue de défaite | Lot et template officiellement fermés |
| Dialogue avant/après | **PARTIEL fort** | Hooks réels | Template complet et validations |
| Récompense argent/item/flag | **PARTIEL** | Modèle et apply runtime complets | L'UI no-code trainer n'expose pas `moneyReward`, `rewardItemGrants` et `rewardFlagIds` |
| Récompense badge | **PARTIEL** | Contrat de reward et commandes séparées | Champ trainer ou template d'arène atomique |
| Arène | **PARTIEL** | Peut être composée avec scènes, trainers et badge | Template guidé, validation, écran badges |
| Rival | **PARTIEL** | Fixture Selbrume et follow-up | Template réutilisable |
| Rematches | **DEFERRED** | — | Politique et scaling |
| Ligue / Elite Four | **ABSENT comme template** | Composable manuellement | Structure, séquence, hall of fame |
| Hall of Fame | **ABSENT** | — | Résultat, équipe, crédits et save postgame |

### 8.10 Menus, UX, entrées et accessibilité

| Fonction | Statut | Présent | Manque |
|---|---|---|---|
| Menu pause | **COMPLET V0** | Shell, navigation et input locks | Profondeur fonctionnelle des sous-menus |
| Équipe | **PARTIEL fort** | Liste, résumé, reorder/lead | Usage d'objets/field moves depuis le menu |
| Sac | **PARTIEL fort** | Lecture et usages overworld ciblés | Interactions complètes et battle bag |
| Pokédex | **COMPLET V0 read-only** | Vu/capturé | Recherche, filtres et détails modernes |
| Carte | **ABSENT produit** | Route/capacité prévue | Données, UI et provider |
| Options | **PARTIEL** | Préférences globales et opacité tactile en jeu | Options runtime complètes |
| Sauvegarder | **COMPLET V0** | Flux transactionnel | UX slots/profils |
| Clavier | **COMPLET V0** | Navigation et gameplay | Remapping |
| Tactile | **COMPLET V0** | Contrôles, opacité et locks | Profils de disposition |
| Gamepad | **COMPLET V0** | Navigation/input testés | Remapping et glyphes |
| Responsive | **COMPLET V0** | Portrait, resize, layouts compacts, text scaling | QA appareils réels |
| Contraste élevé | **PARTIEL** | Préférence appliquée au shell | Propagation à tous les overlays Flame |
| Mouvement réduit | **PARTIEL fort** | Snapshot et comportements testés | Cinématiques/vidéo et audit global |
| Échelle texte | **PARTIEL fort** | Préférence et tests | Textes Flame fixes restants |
| Haptique | **CONTRAT SEUL** | Préférence/controller | Aucun appel production trouvé |
| Indications/tutoriels | **CONTRAT SEUL** | Préférence `showHints` | Consommation runtime |
| Lecteur d'écran | **PARTIEL** | Sémantiques UI | E2E et overlays Flame |
| Daltonisme | **ABSENT** | — | Palettes et icônes non color-only |
| Remapping contrôles | **ABSENT** | — | Modèle, UI, persistance |
| Difficulté/accessibilité combat | **ABSENT** | — | Modes, vitesse, aides |

### 8.11 Audio, localisation et présentation

| Fonction | Statut | Présent | Manque |
|---|---|---|---|
| Sons de cinématique | **COMPLET V0** | Adapter `flame_audio` | Mixer global |
| Musique de cinématique | **PARTIEL** | Playback prévu | Volumes et transitions globales |
| Musique titre | **CONTRAT SEUL** | `GamePackageBranding.titleMusic` | Injection dans le player |
| BGM overworld | **PARTIEL / non centralisé** | Capacités ponctuelles | Système de zones, crossfade, save state |
| Musique combat | **PARTIEL / non prouvée globalement** | Infrastructure audio | Orchestration standard |
| Volumes master/music/effects | **CONTRAT SEUL en runtime** | Préférences et sliders | Projection dans les lecteurs audio |
| Localisation UI | **PARTIEL** | Français/anglais | Plus de langues et textes hardcodés |
| Localisation contenu | **PARTIEL** | Résolution de locale et données localisées ponctuelles | Workflow auteur complet |
| Sous-titres | **ABSENT comme système média** | Dialogues texte | Audio/vidéo, timing et réglages |
| Polices | **ABSENT par projet** | Thème fixe `Avenir Next`, une fonte editor branding | Contrat, licence, packaging, chargement et preview |
| Palette/thème par jeu | **ABSENT** | Accent possible au titre | Tokens sémantiques pour tous les écrans |
| HUD/layout par jeu | **ABSENT** | `layoutVariant` stocké | Variants définis et consommés |
| Illustrations branding | **PARTIEL** | Icon/cover/hero dans manifest et bibliothèque Hub | Player titre et runtime |

### 8.12 Sauvegarde, distribution, validation et release

| Fonction | Statut | Présent | Manque |
|---|---|---|---|
| Save atomique | **COMPLET V0** | Transactions, rollback et tests | — |
| Migration de save | **COMPLET V0** | Tests de migration/isolation | Politique long terme documentée |
| Autosave | **PARTIEL / ambigu** | Lifecycle et reprise | Politique auteur/joueur explicite |
| Slots multiples | **PARTIEL backend** | IDs isolés | UI de gestion |
| Manifest de jeu | **PARTIEL fort** | Métadonnées, branding, chemins | Présentation profonde versionnée |
| Installation Hub | **COMPLET V0** | Bibliothèque et lancement | Update/uninstall/versioning approfondis |
| Validation gameplay | **PARTIEL fort** | Diagnostics, readiness report et validators | Vérité authoring/runtime centralisée |
| Golden Slice | **PARTIEL fort** | Selbrume couvre de nombreux parcours via hooks production | Hub/widget/appareil jusqu'au résultat et crédits |
| Build macOS | **COMPLET pour le build debug audité** | `PokeMap Hub.app` produit avec exit `0` | Signature, notarisation et release restent hors de cette preuve |
| Builds Windows/Linux/mobile | **NON AUDITÉS** | Cibles possibles Flutter | Pipeline/release/signature |
| Gate MVP | **NO-GO release/validation** | `FG-180` à `FG-184` documentés, mais trois tests actuels sont rouges | Receipt `FG-185` manquant et régressions Selbrume à trier |

### 8.13 Après-jeu et fonctions avancées

| Fonction Pokémon | Statut | Commentaire |
|---|---|---|
| Double battles | **DEFERRED** | Le moteur possède un scaffolding intéressant, aucun produit jouable |
| Mega / Z / Tera / Dynamax | **DEFERRED** | Mega/Z partiels en interne seulement |
| Breeding / eggs | **DEFERRED** | À traiter après party/PC/progression |
| Échanges et combats online | **DEFERRED** | Hors MVP local |
| Concours et minijeux | **DEFERRED** | Spécifiques à certaines expériences |
| Battle Frontier | **DEFERRED** | Après parité combat |
| IV/EV/nature UX compétitive | **DEFERRED** | Les données existent partiellement |
| Pokédex moderne exhaustif | **DEFERRED** | Nécessite une génération cible claire |
| Raids | **ABSENT / DEFERRED** | Fonction générationnelle optionnelle |
| Camping / amitié interactive | **ABSENT / DEFERRED** | Fonction générationnelle optionnelle |
| Bases secrètes / souterrains | **ABSENT / DEFERRED** | Fonction générationnelle optionnelle |
| Contenu postgame | **ABSENT** | Devient pertinent après une vraie fin de jeu |

---

## 9. Les 19 critères MVP de la roadmap

| # | Critère | Verdict actuel | Preuve / manque décisif |
|---:|---|---|---|
| 1 | Lancer une nouvelle partie | **COMPLET V0** | Config auteur, builder et boot runtime testés |
| 2 | Choisir un starter | **COMPLET V0** | Selbrume, choix explicite et idempotence |
| 3 | Explorer 2–3 maps | **COMPLET V0** | Connexions, déplacements et fixture |
| 4 | Parler à des NPC | **COMPLET V0** | Interactions/dialogues runtime |
| 5 | Dialogues conditionnels | **PARTIEL fort** | Builder et runtime, gate globale à consolider |
| 6 | Jouer des cutscenes | **PARTIEL fort** | Caméra, mouvements, fade, audio/FX ; pas de vidéo/skip complet |
| 7 | Déclencher une rencontre sauvage | **COMPLET V0 étroit** | Marche réelle ; conditions élargies partielles |
| 8 | Capturer un Pokémon | **COMPLET V0** | Formule, débit, destination et Pokédex |
| 9 | Envoyer au PC si la party est pleine | **COMPLET V0** | Opérations et write-back testés |
| 10 | Combattre des trainers | **COMPLET V0** | Singles, équipes et outcome |
| 11 | Gagner XP et argent | **COMPLET V0** | Services et runtime transactionnel |
| 12 | Level-up | **COMPLET V0** | Multi-level et recalcul |
| 13 | Apprendre une attaque | **COMPLET V0** | Ajout/remplacement/refus |
| 14 | Obtenir un badge ou flag | **COMPLET V0** | Le critère disjonctif est satisfait par les flags ; le flux badge/gym reste partiel séparément |
| 15 | Débloquer Surf ou Cut | **PARTIEL** | Surf authoré et badge lié, traversée/refus E2E à fermer |
| 16 | Utiliser un shop | **COMPLET V0** | Shop dynamique Selbrume et sauvegarde |
| 17 | Se soigner dans un centre | **COMPLET V0 service** | Service contextuel et commande Scene existent ; promotion E2E globale encore à rétablir |
| 18 | Sauvegarder / charger proprement | **COMPLET V0 backend / PARTIEL UX** | Transaction solide ; slots/profils faibles |
| 19 | Finir une mini-histoire | **PARTIEL / NO-GO joueur** | Faits de scénario présents, mais aucun `Finish Game` vers résultat/crédits |

Le Golden Slice démontre donc la majeure partie du cœur mécanique, mais il ne démontre pas encore une **histoire finissable du point de vue du joueur**.

---

## 10. Audit spécifique du Personalization Hub

### 10.1 Ce qui existe déjà

La future fonctionnalité ne part pas de zéro :

- `GamePackageBranding` stocke `icon`, `cover`, `hero`, `accentColor`, `titleMusic` et `layoutVariant` ;
- le codec de manifest valide les chemins de branding ;
- le Hub affiche déjà icon, cover et hero dans sa bibliothèque ;
- `PlayerTitleScreen` sait afficher un fond, un logo et une couleur d'accent ;
- les préférences globales couvrent langue, mode clair/sombre, volumes, contraste, mouvement réduit, haptique, hints, échelle texte et opacité tactile ;
- les cinématiques savent jouer sons, musiques et FX ;
- le shell joueur possède déjà des primitives responsive et accessibles.

### 10.2 Ce qui empêche de parler de « hub »

| Capacité | État actuel | Besoin |
|---|---|---|
| Source de vérité | Branding dans le manifest de distribution | Contrat de présentation versionné appartenant aux données PokeMap |
| Éditeur dédié | Aucun écran central | Hub no-code avec catégories, recherche et previews |
| Aperçu en direct | Absent | Titre, dialogue, HUD, menus, combat, vidéo |
| Vidéo d'intro | Absente | Asset, séquence, lecture, skip et fallback |
| Police | Fixe / fallback plateforme | Catalogue de fontes projet et rôles typographiques |
| Palette | Accent ponctuel | Tokens sémantiques complets |
| Layout/HUD | `layoutVariant` stocké | Variantes réelles, documentées et testées |
| Audio | Métadonnées/sliders partiels | Mixer et consommation runtime |
| Localisation | FR/EN UI partiel | Assets/textes de présentation localisés |
| Accessibilité | Préférences globales partielles | Contrastes, sous-titres, reduced motion et vidéo accessible |
| Packaging | Chemins d'assets | Formats, taille, licence, hash, fallback et diagnostics |
| Migration | Non définie | Version de schéma et comportement legacy |

Le catalogue cible du Hub doit couvrir au minimum : boot/splash, vidéo d'intro, titre, logos, icon/cover/hero, écrans de chargement, identité joueur, rôles typographiques, palette sémantique, dialogues, menus, HUD overworld, HUD combat, icônes et curseurs, transitions, musique/SFX, écran résultat, crédits, assets localisés et fallbacks d'accessibilité.

### 10.3 Écart de wiring immédiat

Le Hub transmet aujourd'hui surtout auteur et description au titre du player. Il ne transmet pas de manière complète le logo, le hero/background, l'accent, la musique de titre ou la variante de layout, alors que les deux extrémités possèdent déjà une partie du contrat. C'est le quick win le plus évident.

### 10.4 Architecture recommandée

Le Personalization Hub devrait orchestrer un contrat partagé, pas écrire directement dans des widgets.

```text
map_core
  ProjectPresentationProfile versionné
    ├── introSequence / introVideo
    ├── branding
    ├── typographyRoles
    ├── semanticColorTokens
    ├── audioProfile
    ├── title/menu/dialogue/hud/battle variants
    ├── localizedPresentation
    └── accessibility fallbacks
          │
          ├── map_editor : hub no-code + previews + diagnostics
          ├── map_distribution : packaging, hashes, formats, licences
          ├── map_runtime : chargement, capacités et fallbacks
          ├── map_player_ui : consommation des tokens/variants
          └── pokemap_hub : présentation du jeu installé et lancement
```

Règles recommandées :

- aucune couleur de projet ne doit contourner les tokens sémantiques ;
- une fonte doit être déclarée avec licence, formats, fallbacks et rôles (`display`, `body`, `dialogue`, `numbers`) ;
- toute vidéo doit être skippable, avoir une image de secours et respecter reduced motion ;
- l'absence ou l'échec d'un média ne doit jamais empêcher de lancer une partie ;
- les assets localisés doivent avoir une stratégie de fallback ;
- l'éditeur doit montrer la même composition que le runtime, avec les mêmes validateurs ;
- le manifest de distribution doit être dérivé du contrat projet, et non devenir la seule source de vérité auteur.

### 10.5 Lots proposés pour la personnalisation

Ces identifiants `PH-*` sont des propositions de planification, pas des lots canoniques ajoutés à la roadmap.

| Lot proposé | Résultat attendu | Priorité |
|---|---|---|
| `PH-000` — Presentation Contract, Migration & Hub Shell | Source de vérité versionnée, registre/catégories no-code initiales, legacy compatible, diagnostics | **P0/P1** |
| `PH-001` — Existing Branding Runtime Wiring | Logo, hero, accent, title music et layout existants réellement consommés | **P0 / quick win** |
| `PH-002` — Intro Video V0 | Import, preview, packaging, lecture, skip, fallback, reduced motion, sous-titres optionnels | **P1 — premier résultat visible** |
| `PH-003` — Project Typography V0 | Fontes embarquées, rôles, fallback, licence, preview et runtime | **P1** |
| `PH-004` — Semantic Theme & HUD V0 | Palette, surfaces, dialogues, menus, battle HUD et contraste | **P1** |
| `PH-005` — Audio Identity & Mixer V0 | Musique titre/overworld/battle, SFX, bus de volume et transitions | **P2** |
| `PH-006` — Advanced Hub Previews & Presets | Preview multi-écrans avancée, recherche, presets, comparaison de variantes | **P2**, sur le shell livré par `PH-000` |
| `PH-007` — Packaging & Golden E2E | Validation assets + test export→install→intro→titre→jeu | **P2 gate** |

### 10.6 Définition de done recommandée pour la vidéo d'introduction

Une vidéo d'introduction V0 n'est complète que si :

1. l'auteur peut sélectionner un fichier via picker ;
2. formats, taille et présence sont validés avant export ;
3. l'éditeur fournit image, durée et preview ;
4. le package embarque le média sans chemin machine ;
5. le player le lit avant le titre selon une policy explicite ;
6. le joueur peut passer la vidéo ;
7. reduced motion et l'échec du codec ont un fallback ;
8. la musique/vidéo respecte les volumes ;
9. la reprise après lifecycle ne bloque pas le lancement ;
10. un test couvre projet→package→Hub→vidéo→titre et un test couvre le fallback.

Avant implémentation, une matrice codecs/plateformes doit fixer les conteneurs et codecs supportés par macOS, Windows, Linux, iOS et Android. Les validateurs doivent aussi imposer des limites explicites de résolution, débit, durée et taille de package. Tant que cette matrice n'est pas prouvée, aucun codec universel ne doit être promis ; un poster statique et un passage direct au titre restent les fallbacks obligatoires en cas de décodage impossible.

---

## 11. Priorités recommandées

### P0 — rétablir une vérité produit

1. Fermer le parcours Selbrume jusqu'à un vrai résultat/crédits avec une commande no-code `Finish Game`.
2. Produire le receipt manquant de `FG-185` et réconcilier les rapports historiques avec le code actuel.
3. Introduire une gate authoring→contrat→runtime→UI pour éviter les champs décoratifs.
4. Brancher la difficulté trainer sur l'IA PSDK et unifier fuite, item et remplacement dans le contrat de décision.
5. Définir la cible de parité combat `FG-053`.

### P1 — compléter le cœur Pokémon jouable

1. Fermer les conditions et kinds de rencontres réellement jouables.
2. Durcir switch/K.O., battle bag et objets tenus.
3. Rendre Équipe, Sac et PC plus interactifs ; ajouter un vrai gestionnaire de profils/slots.
4. Fermer badge→Surf et le template trainer/gym.
5. Gérer cadeaux/captures avec toutes les métadonnées et le routage PC.

### P1 — lancer le Personalization Hub

1. `PH-000` contrat de présentation.
2. `PH-001` wiring du branding déjà existant.
3. `PH-002` vidéo d'introduction.
4. `PH-003` fontes par projet.
5. `PH-004` thème sémantique et HUD.

### P2 — qualité de plateforme

1. Mixer audio et consommation réelle des volumes.
2. Localisation de contenu et suppression des textes runtime codés en dur.
3. Accessibilité bout-en-bout et remapping.
4. Carte/fast travel.
5. Previews, validation média et E2E d'export.

### P3 — après MVP

Doubles, breeding, rematches, Battle Frontier, online, gimmicks de génération, concours, raids, camping et Pokédex moderne exhaustif.

---

## 12. Proposition de statut pour tous les lots FG

Les colonnes distinguent le statut inscrit dans la roadmap du verdict de cet audit. `DONE proposé` signifie qu'une mise à jour pourrait être faite après accord, pas que la roadmap a été modifiée.

### Phase 0 — audit et suivi

| Lot | Roadmap | Proposition | Motif |
|---|---|---|---|
| FG-000 | TODO | **DONE proposé** | Le présent audit couvre inventaires, packages, tests, fixtures et tous les lots |
| FG-001 | TODO | **DONE proposé** | Roadmap racine présente et référencée dans `AGENTS.md` |

### Phase 1 — nouvelle partie et boot

| Lot | Roadmap | Proposition | Motif |
|---|---|---|---|
| FG-010 | TODO | **DONE proposé** | Builder de `GameState` et tests frais |
| FG-011 | TODO | **DONE proposé** | Boot New Game runtime réel |
| FG-012 | TODO | **DONE proposé** | Config et options de starter |
| FG-013 | TODO | **DONE proposé** | Choix Selbrume et idempotence |
| FG-014 | DONE | **DONE confirmé V0** | Sauvegarde transactionnelle |
| FG-015 | TODO | **DONE proposé V0** | Shell pause livré et testé ; profondeur des menus reste distincte |
| FG-016 | TODO | **DONE proposé V0** | Boot/golden smokes présents |

### Phase 2 — party, PC et capture

| Lot | Roadmap | Proposition | Motif |
|---|---|---|---|
| FG-020 | DONE | **DONE confirmé V0** | Audit/persistance PlayerPokemon |
| FG-021 | DONE | **DONE confirmé V0** | XP/PP et round-trip |
| FG-022 | DONE | **DONE confirmé V0** | 8 boxes de 30 slots |
| FG-023 | DONE | **DONE confirmé V0** | Opérations atomiques |
| FG-024 | DONE | **DONE confirmé V0** | Destination party/box |
| FG-025 | DONE | **DONE confirmé V0** | Party pleine→PC |
| FG-026 | DONE | **DONE confirmé V0** | Menu party read-only |
| FG-027 | DONE | **DONE confirmé V0** | Summary runtime |
| FG-028 | DONE | **DONE confirmé V0** | Reorder/lead |
| FG-029 | PARTIAL | **PARTIAL confirmé** | Summary depuis PC absent |
| FG-030 | DONE | **DONE confirmé V0** | Diagnostics party/box |

### Phase 3 — combat et progression

| Lot | Roadmap | Proposition | Motif |
|---|---|---|---|
| FG-040 | DONE | **DONE confirmé V0** | Contrat de persistance |
| FG-041 | DONE | **DONE confirmé V0** | PP write-back |
| FG-042 | DONE | **DONE confirmé V0** | Statuts majeurs |
| FG-043 | DONE | **DONE confirmé V0** | Modèle de reward |
| FG-044 | DONE | **DONE confirmé V0** | Distribution XP |
| FG-045 | DONE | **DONE confirmé V0** | Level-up |
| FG-046 | DONE | **DONE confirmé V0** | Learn move |
| FG-047 | DONE | **DONE confirmé V0** | Évolution niveau |
| FG-048 | DONE | **DONE confirmé V0** | Présentation décisionnelle |
| FG-049 | DONE | **DONE confirmé V0** | Formule de capture |
| FG-050 | TODO | **PARTIAL** | Quatre soins runtime, pas de décision item générique |
| FG-051 | DONE | **DONE contrat / PARTIAL flux badge** | Money/items/flags solides ; badge trainer non branché |
| FG-052 | TODO | **PARTIAL** | Switch/remplacement présents mais UX et contrat incomplets |
| FG-053 | TODO | **TODO prioritaire** | Cible génération/parité non définie, rapports contradictoires |

### Phase 4 — Sac, objets et services

| Lot | Roadmap | Proposition | Motif |
|---|---|---|---|
| FG-060 | DONE | **DONE confirmé V0** | Registry d'effets |
| FG-061 | DONE | **DONE confirmé V0** | Sac overworld |
| FG-062 | DONE | **DONE confirmé V0** | Médecines |
| FG-063 | DONE | **DONE confirmé V0** | Cure/revive |
| FG-064 | TODO | **PARTIAL** | Catégorie/gates ponctuelles, pas de système généralisé |
| FG-065 | DEFERRED | **DEFERRED confirmé** | Repel hors MVP |
| FG-066 | DEFERRED | **DEFERRED confirmé** | Une seule Ball V0 |
| FG-067 | TODO | **PARTIAL** | Give item/source physique possible, template pickup absent |
| FG-068 | TODO | **TODO** | Hidden item non identifié |
| FG-069 | DONE | **DONE confirmé V0** | Modèle shop |
| FG-070 | DONE | **DONE confirmé V0** | Achat runtime |
| FG-071 | PARTIAL | **PARTIAL confirmé** | Service et conséquence Scene présents ; preuve/promotion E2E globale à rétablir |
| FG-072 | TODO | **PARTIAL moteur / TODO produit** | Held items non traversants |
| FG-073 | TODO | **TODO** | TM/HM absent |
| FG-074 | DONE | **DONE confirmé V0** | État shop versionné |
| FG-075 | DONE | **DONE confirmé V0** | Resolver/stock |
| FG-076 | DONE | **DONE confirmé V0** | Runtime dynamique |
| FG-077 | DONE | **DONE confirmé V0** | Builder no-code |
| FG-078 | DONE | **DONE confirmé V0** | Validator/simulator |
| FG-079 | DONE | **DONE confirmé V0** | Golden Slice shop |

### Phase 5 — commandes no-code

| Lot | Roadmap | Proposition | Motif |
|---|---|---|---|
| FG-080 | TODO | **DONE proposé V0** | Modèle de commandes publié |
| FG-081 | TODO | **PARTIAL fort** | Conditions no-code réelles, profondeur Pokémon à élargir |
| FG-082 | PARTIAL | **PARTIAL confirmé** | Parité des 18 commandes publiables, mais suite runtime globale rouge |
| FG-083 | PARTIAL | **DONE proposé V0** | Give/Take item authoré, persisté et idempotent |
| FG-084 | TODO | **PARTIAL** | Give Pokémon incomplet party pleine/métadonnées |
| FG-085 | PARTIAL | **PARTIAL confirmé** | Writer, authoring et source physique ; pas de preuve fraîche isolée suffisante pour promotion |
| FG-086 | TODO | **PARTIAL fort** | Combat trainer réel, closure du contrat à documenter |
| FG-087 | TODO | **PARTIAL** | Rencontre statique non fermée bout-en-bout |
| FG-088 | TODO | **DONE proposé V0** | Flags/variables persistants et consommés |
| FG-089 | PARTIAL | **PARTIAL confirmé** | Badge/Surf authorés, parcours E2E incomplet |
| FG-090 | PARTIAL | **DONE proposé V0** | Warp réel et destination valide |
| FG-091 | PARTIAL | **DONE proposé V0** | Shop/PC ports et sources physiques |
| FG-092 | TODO | **PARTIAL** | Mouvement et présence existent séparément |
| FG-093 | PARTIAL | **PARTIAL confirmé** | Pickers, round-trip et parité ; gate editor fraîche rouge |
| FG-094 | TODO | **PARTIAL / TODO produit** | Exemples existent, bibliothèque officielle absente |

### Phase 6 — encounters élargis

| Lot | Roadmap | Proposition | Motif |
|---|---|---|---|
| FG-100 | TODO | **PARTIAL** | Audit global établi, mais matrice exhaustive `EncounterKind × modèle × editor × runtime × tests` non produite |
| FG-101 | TODO | **PARTIAL** | Conditions incomplètes |
| FG-102 | TODO | **PARTIAL** | Static flow incomplet |
| FG-103 | TODO | **PARTIAL** | Gift flow incomplet |
| FG-104 | DEFERRED | **DEFERRED confirmé** | Pêche hors MVP |
| FG-105 | DEFERRED | **DEFERRED confirmé** | Headbutt hors MVP |
| FG-106 | TODO | **PARTIAL** | Surf existe, hardening/conditions manquent |
| FG-107 | TODO | **PARTIAL** | Consumed state partiel |
| FG-108 | TODO | **PARTIAL** | Authoring large, vérité runtime incomplète |

### Phase 7 — field moves

| Lot | Roadmap | Proposition | Motif |
|---|---|---|---|
| FG-120 | PARTIAL | **PARTIAL confirmé** | Surf authoré, traversée à fermer |
| FG-121 | DEFERRED | **DEFERRED confirmé** | Cut hors MVP signé |
| FG-122 | DEFERRED | **DEFERRED confirmé** | Strength hors MVP |
| FG-123 | DEFERRED | **DEFERRED confirmé** | Rock Smash hors MVP |
| FG-124 | DEFERRED | **DEFERRED confirmé** | Flash hors MVP |
| FG-125 | DEFERRED | **DEFERRED confirmé** | Fly hors MVP |
| FG-126 | DEFERRED | **DEFERRED confirmé** | Waterfall hors MVP |
| FG-127 | DEFERRED | **DEFERRED confirmé** | Dive hors MVP |
| FG-128 | DEFERRED | **DEFERRED confirmé** | Templates avancés hors MVP |
| FG-129 | PARTIAL | **PARTIAL confirmé** | Badge/Surf liés, parcours runtime incomplet |

### Phase 8 — trainers et histoire

| Lot | Roadmap | Proposition | Motif |
|---|---|---|---|
| FG-140 | TODO | **PARTIAL fort** | Trainer vaincu marqué et bloqué |
| FG-141 | TODO | **PARTIAL fort** | Dialogue de défaite/follow-up réel |
| FG-142 | DEFERRED | **DEFERRED confirmé** | Rematch hors MVP |
| FG-143 | TODO | **PARTIAL** | Commandes badge présentes, flow trainer/gym incomplet |
| FG-144 | TODO | **PARTIAL / TODO template** | Composable, pas de template fermé |
| FG-145 | TODO | **PARTIAL** | Rival Selbrume, template absent |
| FG-146 | TODO | **PARTIAL fort** | Validators/readiness existent, fin joueur absente |
| FG-147 | TODO | **PARTIAL fort** | Rapports présents, completion runtime absente |

### Phase 9 — menus et UX joueur

| Lot | Roadmap | Proposition | Motif |
|---|---|---|---|
| FG-160 | TODO | **DONE proposé V0** | Pause complète pour le périmètre signé |
| FG-161 | TODO | **DONE proposé V0** | Pokédex read-only livré |
| FG-162 | TODO | **PARTIAL** | Options globales, runtime en jeu trop limité |
| FG-163 | TODO | **DONE proposé V0** | Save depuis le shell, confirmations/erreurs et reprise sont prouvés ; multi-slots reste un écart Pokémon hors DoD |
| FG-164 | TODO | **TODO** | Carte désactivée faute de provider |
| FG-165 | DONE | **DONE confirmé V0** | Conventions input locks revalidées |

### Phase 10 — readiness et release

| Lot | Roadmap | Proposition | Motif |
|---|---|---|---|
| FG-180 | DONE | **DONE confirmé V0** | Readiness report présent |
| FG-181 | DONE | **DONE confirmé V0** | Fixture Golden Slice |
| FG-182 | DONE | **DONE historique V0, régression actuelle à trier** | E2E ciblé `+6` vert ; deux autres preuves Selbrume runtime sont rouges ; pas Hub/appareil→crédits |
| FG-183 | DONE | **DONE confirmé V0** | Matrice de régression |
| FG-184 | DONE | **DONE confirmé V0** | Dashboard generator |
| FG-185 | PARTIAL | **PARTIAL / NO-GO** | Receipt Phase 6 manquant ; anciennes mentions GO archivées |

### Phase 11 — parité avancée

| Lot | Roadmap | Proposition | Motif |
|---|---|---|---|
| FG-200 | DEFERRED | **DEFERRED confirmé** | Doubles après singles stable |
| FG-201 | DEFERRED | **DEFERRED confirmé** | Gimmicks après génération cible |
| FG-202 | DEFERRED | **DEFERRED confirmé** | Breeding |
| FG-203 | DEFERRED | **DEFERRED confirmé** | Online |
| FG-204 | DEFERRED | **DEFERRED confirmé** | Concours/minijeux |
| FG-205 | DEFERRED | **DEFERRED confirmé** | Battle Frontier |
| FG-206 | DEFERRED | **DEFERRED confirmé** | UX IV/EV/nature |
| FG-207 | DEFERRED | **DEFERRED confirmé** | Pokédex moderne exhaustif |

---

## 13. Tests et fixtures à conserver comme preuves de référence

### 13.1 Fixtures golden et packs de référence

| Fixture | Rôle | Limite probatoire |
|---|---|---|
| `examples/playable_runtime_host/golden_fangame_slice/` | Projet compact de trois cartes avec walkthrough ; composition New Game/exploration/encounter/progression | Ne traverse pas le shell Hub complet et ne représente pas toute la campagne Selbrume |
| `examples/playable_runtime_host/golden_battle_slice/` | Projet minimal de lancement et sauvegarde autour d'un combat | Smoke de bridge, pas preuve de parité de toutes les attaques/IA/items |
| `examples/playable_runtime_host/event_builder_v2_selbrume_slice/` | Fixture authoring/export avec manifest, semantic diff, promotion payload/checkpoint, deux cartes et dialogue Lysa | Prouve surtout la cohérence des données et de la promotion, pas une interaction Player complète |
| `examples/playable_runtime_host/p3_narrative_smoke_slice/` | Petit projet narratif avec carte, projet et save de lancement | Smoke ciblé, sans profondeur de campagne |
| `examples/playable_runtime_host/evaluation/scenarios/selbrume/` | Scénarios JSON `healing_service`, `lysa_retry`, `mvp_certification`, `shop_after_lysa` | Spécifications d'évaluation ; leur présence seule n'est pas une exécution |
| `packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/` | Pack de dix espèces avec species, learnsets, évolutions et médias pour l'import manuel | Prouve l'import/catalogue, pas la jouabilité de ces Pokémon dans tous les systèmes |

Le meilleur signal de campagne actuelle reste `selbrume_player_journey_e2e_test.dart`, qui utilise les hooks de production de `PlayableMapGame` et passe fraîchement. Il reste néanmoins headless : il ne traverse ni le widget Hub complet, ni une vidéo d'introduction, ni un résultat/crédits.

### 13.2 Suites et tests

### Core et gameplay

- `packages/map_core/test/project_new_game_config_test.dart`
- `packages/map_core/test/narrative_command_contract_parity_test.dart`
- `packages/map_core/test/project_gameplay_readiness_test.dart`
- `packages/map_gameplay/test/project_new_game_state_builder_test.dart`
- `packages/map_gameplay/test/player_storage_operations_test.dart`
- `packages/map_gameplay/test/battle_progression_service_test.dart`
- `packages/map_gameplay/test/battle_move_learning_test.dart`
- `packages/map_gameplay/test/pokemon_experience_curve_test.dart`
- `packages/map_gameplay/test/pokemon_evolution_service_test.dart`

### Combat

- `packages/map_battle/test/psdk_engine_smoke_test.dart`
- `packages/map_battle/test/psdk_action_queue_test.dart`
- `packages/map_battle/test/psdk_accuracy_test.dart`
- `packages/map_battle/test/psdk_type_damage_test.dart`
- `packages/map_battle/test/psdk_status_lifecycle_test.dart`
- `packages/map_battle/test/psdk_pp_history_test.dart`
- `packages/map_battle/test/psdk_switch_action_test.dart`
- suites `psdk_ai_*`
- `packages/map_battle/test/battle_capture_formula_test.dart`
- `packages/map_battle/test/battle_capture_flow_test.dart`
- `packages/map_battle/test/psdk_battle_item_action_test.dart`

### Runtime et Player

- `packages/map_runtime/test/selbrume_new_game_starter_integration_test.dart`
- `packages/map_runtime/test/playable_map_game_project_new_game_boot_test.dart`
- `packages/map_runtime/test/playable_map_game_save_load_transaction_test.dart`
- `packages/map_runtime/test/runtime_psdk_battle_session_adapter_test.dart`
- `packages/map_runtime/test/runtime_battle_outcome_apply_test.dart`
- `packages/map_runtime/test/runtime_post_battle_decision_coordinator_test.dart`
- `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`
- `packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart`
- `packages/map_player_ui/test/player/pokemap_player_session_view_test.dart`
- `packages/map_player_ui/test/player/runtime_player_input_navigation_test.dart`
- `packages/map_player_ui/test/player/runtime_player_resize_stress_test.dart`

### Hub et Golden Slice

- `apps/pokemap_hub/integration_test/runtime_owned_player_flow_test.dart`
- `apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart`
- `apps/pokemap_hub/test/player/hub_player_save_gateway_test.dart`
- `examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart`
- `examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart`

Le futur test le plus précieux est un parcours unique :

```text
package exporté
  → installation Hub
  → vidéo d'introduction
  → titre personnalisé
  → New Game
  → starter
  → exploration/dialogue
  → sauvage/capture
  → trainer/reward
  → badge/Surf
  → shop/heal/PC
  → save/reload
  → Finish Game
  → résultat/crédits
```

---

## 14. Verdict des sous-audits et passes

| Passe | Verdict | Signal principal |
|---|---|---|
| Audit initial — règles/roadmap/rapports | **PARTIEL et désynchronisé** | Le résumé de roadmap sous-évalue du code récent et certains anciens rapports sont périmés |
| Agent Architecture/Authoring | **PARTIEL / NO-GO produit** | Bonnes frontières, mais contrôles editor parfois décoratifs |
| Implémentation | **N/A conforme** | `FG-000` impose un audit sans changement de code ; aucun correctif ni refactor n'était autorisé par le lot |
| Agent Combat/Progression | **PARTIEL** | Singles V0 solide ; bridge PSDK et parité cible restent les risques majeurs |
| Agent Runtime/UX/Personnalisation | **PARTIEL / NO-GO personnalisation** | Boucle réelle, branding et préférences peu consommés, fin de jeu non branchée |
| Passe Tests | **FAIL global** | Ciblés verts, battle complet vert, E2E joueur vert ; runtime `-2` et editor `-1` |
| Agent Build/Validation | **FAIL validation / build vert** | Analyses propres et Hub macOS construit ; trois tests reproductiblement rouges |
| Agent Critique indépendante | **GO du rapport après corrections** | Deux contradictions corrigées, fixtures ajoutées, promotions de lots rendues conservatrices |

`codex_rule.md` demande normalement de documenter les tests créés ou modifiés. Ici, le DoD plus spécifique de `FG-000` exige **aucun changement de code**. Le conflit est résolu en faveur de ce lot : seuls des tests existants ont été exécutés, et aucune suite n'a été modifiée pour faire disparaître les échecs.

---

## 15. Commandes ciblées fraîches déjà exécutées

Toutes les commandes ci-dessous ont été lancées depuis le package concerné.

```text
cd packages/map_core &&
dart test test/project_new_game_config_test.dart \
  test/narrative_command_contract_parity_test.dart \
  test/project_gameplay_readiness_test.dart
```

Résultat exact : exit `0`, `+14: All tests passed!`

```text
cd packages/map_gameplay &&
dart test test/project_new_game_state_builder_test.dart \
  test/player_storage_operations_test.dart \
  test/battle_progression_service_test.dart
```

Résultat exact : exit `0`, `+24: All tests passed!`

```text
cd packages/map_distribution &&
dart test test/game_package_manifest_codec_test.dart
```

Résultat exact : exit `0`, `+14: All tests passed!`

```text
cd packages/map_player_ui &&
flutter test test/player_title_screen_test.dart \
  test/player_localizations_test.dart \
  test/player_feedback_test.dart
```

Résultat exact : exit `0`, `+7: All tests passed!`

```text
cd apps/pokemap_hub &&
flutter test test/ui/hub_app_player_navigation_test.dart \
  test/ui/hub_preferences_store_test.dart \
  test/ui/hub_shell_test.dart
```

Résultat exact : exit `0`, `+15: All tests passed!`

```text
cd packages/map_runtime &&
flutter test test/selbrume_new_game_starter_integration_test.dart
```

Résultat exact : exit `0`, `00:07 +2: All tests passed!`

Aucun test n'a été créé ou modifié : `FG-000` impose un audit sans changement de code. Les tests existants sont réutilisés comme preuves.

---

## 16. Validation complète et build

Verdict de la passe : **FAIL global**. Trois tests sont rouges et reproductibles ; toutes les analyses exécutées, la suite complète `map_battle`, l'E2E joueur ciblé et le build Hub sont verts.

### 16.1 `map_battle`

```text
cd packages/map_battle && dart test
```

Exit `0` — `00:19 +1740: All tests passed!`

```text
cd packages/map_battle && dart analyze
```

Exit `0` — `No issues found!`

### 16.2 `map_runtime`

```text
cd packages/map_runtime && flutter test
```

Exit `1` — `02:00 +2163 ~1 -2: Some tests failed.`

Échec 1, reproduit isolément avec exit `1` :

```text
flutter test test/selbrume_event_v2_three_source_integration_test.dart \
  --plain-name 'J3 Selbrume sources through PlayableMapGame production hooks canonical Selbrume: Lysa NPC dispatches its authored Scene once'
```

Diagnostic : `Bad state: Too many elements`, `selbrume_event_v2_three_source_integration_test.dart:63:54`, via `ListBase.singleWhere`.

Échec 2, reproduit isolément avec exit `1` :

```text
flutter test test/selbrume_narrative_campaign_outcome_matrix_test.dart \
  --plain-name 'promoted Selbrume Validator dimensions fail closed on injected defects'
```

Diagnostic exact :

```text
Expected: NarrativeSymbolicVerdict:<NarrativeSymbolicVerdict.pass>
  Actual: NarrativeSymbolicVerdict:<NarrativeSymbolicVerdict.indeterminate>
```

Emplacement : `selbrume_narrative_campaign_outcome_matrix_test.dart:28:5`.

```text
cd packages/map_runtime && flutter analyze
```

Exit `0` — `No issues found! (ran in 4.2s)`

### 16.3 `map_editor`

```text
cd packages/map_editor && flutter test
```

Exit `1` — `05:49 +4144 -1: Some tests failed.`

Échec reproduit isolément avec exit `1` :

```text
flutter test test/selbrume_narrative_validator_test.dart \
  --plain-name 'canonical Selbrume passes bounded solvability and runtime proof'
```

Diagnostic exact :

```text
Expected: empty
  Actual: [Instance of 'NarrativeProjectDiagnostic']
narrativeSolvabilityIndeterminate · scenes. · Le budget symbolique global de 16384 états est dépassé.
```

Emplacement : `selbrume_narrative_validator_test.dart:45:5`.

```text
cd packages/map_editor && flutter analyze
```

Exit `0` — `No issues found! (ran in 5.7s)`

Les deux échecs de solvabilité convergent vers une preuve symbolique devenue indéterminée au budget de `16384` états. L'échec Lysa est distinct : le test attend un élément unique et en rencontre plusieurs. L'audit établit leur reproductibilité, pas leur cause définitive.

### 16.4 Host Selbrume

```text
cd examples/playable_runtime_host &&
flutter test test/selbrume_player_journey_e2e_test.dart
```

Exit `0` — `03:53 +6: All tests passed!`

```text
cd examples/playable_runtime_host && flutter analyze
```

Exit `0` :

```text
Analyzing playable_runtime_host...
No issues found! (ran in 6.3s)
```

### 16.5 Hub

```text
cd apps/pokemap_hub && flutter analyze
```

Exit `0` — `No issues found! (ran in 5.0s)`

```text
cd apps/pokemap_hub && flutter build macos --debug
```

Exit `0` — `✓ Built build/macos/Build/Products/Debug/PokeMap Hub.app`

Le build n'a ajouté aucun fichier source suivi ou non suivi ; le produit reste sous `build/`.

### 16.6 Portée non exécutée

Pour éviter toute extrapolation :

- suites complètes et analyses de `map_core`, `map_gameplay`, `map_distribution` et `map_player_ui` : **non exécutées** ; seuls les tests ciblés de la section 15 ont été lancés ;
- suite complète de `examples/playable_runtime_host` : **non exécutée** ; seul l'E2E Selbrume ciblé et l'analyse ont été lancés ;
- suite complète de `apps/pokemap_hub` : **non exécutée** ; les tests ciblés de la section 15, l'analyse et le build ont été lancés ;
- builds Windows, Linux, iOS, Android, build macOS release, signature et notarisation : **non exécutés**.

---

## 17. Fichiers modifiés et zones de diff

### Écriture de cet audit

Seul fichier créé par cette tâche :

- `reports/gameplay/fg_000_fangame_mechanics_readiness_audit.md`

Zone créée : document complet, sections 1 à 19.

Le présent document est lui-même le contenu intégral du seul fichier créé. Le recopier à l'intérieur de lui-même créerait une récursion infinie ; sa présence dans ce fichier constitue donc la livraison du contenu complet.

Vérification de forme :

```text
git diff --no-index --check /dev/null \
  reports/gameplay/fg_000_fangame_mechanics_readiness_audit.md
```

Après suppression des espaces finaux détectés par la première passe : aucune sortie de diagnostic ; exit `1` attendu, car `--no-index` signale que le nouveau fichier diffère de `/dev/null`. Comme le fichier est non suivi, `git diff --stat -- <fichier>` n'affiche pas de statistique avant ajout Git ; aucune opération `git add` n'a été réalisée.

### Fichiers préexistants non modifiés par l'audit

Les sept fichiers listés dans l'état Git initial ont été laissés intacts. Aucun fichier source, test, roadmap ou artefact généré n'a été modifié par cette tâche.

---

## 18. État Git final

```text
 M apps/pokemap_hub/lib/src/ui/hub_app.dart
 M apps/pokemap_hub/lib/src/ui/hub_shell.dart
 M apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
 M apps/pokemap_hub/test/ui/hub_preferences_store_test.dart
 M apps/pokemap_hub/test/ui/hub_shell_test.dart
 M packages/map_player_ui/lib/src/localization/player_localizations.dart
 M packages/map_player_ui/lib/src/preferences/player_preferences.dart
?? reports/gameplay/fg_000_fangame_mechanics_readiness_audit.md
```

Différence par rapport à l'état initial : uniquement le nouveau rapport non suivi. Les sept modifications préexistantes sont toujours présentes et n'ont pas été masquées, restaurées, ajoutées à l'index ou commitées. Aucun artefact de build non ignoré n'est apparu.

---

## 19. Auto-critique, risques et verdict final

### 19.1 Corrections issues de la critique indépendante

La première version du rapport sur-promettait plusieurs points. La revue indépendante a conduit aux corrections suivantes :

- `FG-082`, `FG-085` et `FG-093` restent `PARTIAL` face aux gates fraîches rouges ;
- `FG-100` reste `PARTIAL` faute de matrice exhaustive de tous les `EncounterKind` ;
- `FG-182` conserve son statut historique avec une régression actuelle explicitement à trier ;
- la commande `HealParty` est bien modélisée, authorée et exécutée ; le manque porte sur la promotion E2E globale ;
- les récompenses trainer sont présentes dans les modèles/runtime, mais pas entièrement exposées dans l'UI no-code ;
- les fixtures golden, les fichiers sources à haut signal et la portée non exécutée ont été ajoutés ;
- le shell du Personalization Hub remonte dès `PH-000` au lieu d'attendre une phase tardive ;
- `FG-163` est évalué `DONE proposé V0` selon son DoD, tout en conservant l'écart multi-slots dans la comparaison Pokémon ;
- le critère MVP « badge **ou** flag » est déclaré satisfait par les flags, sans masquer le flux badge partiel.

### 19.2 Risques connus

1. **Validation actuelle rouge** : deux preuves narratives sont indéterminées et la fixture Lysa ne respecte plus l'unicité attendue.
2. **Fin joueur absente** : une campagne peut atteindre des faits finaux sans afficher résultat/crédits.
3. **Décalage editor/runtime** : difficulté trainer, held items, certains encounters et branding peuvent être authorés ou stockés sans effet complet.
4. **Parité combat non définie** : les compteurs PSDK et anciens rapports utilisent des versions/définitions différentes.
5. **Preuve E2E limitée** : l'E2E Selbrume est vert mais headless ; aucun appareil ne couvre Hub→crédits.
6. **Portée de test partielle** : plusieurs packages n'ont reçu que des tests ciblés, pas leur suite/analyse complète.
7. **Aucune QA humaine** : lisibilité, rythme, plaisir, difficulté et accessibilité réelle ne sont pas mesurés.
8. **Plateformes non couvertes** : seul le build macOS debug du Hub a été produit.
9. **Worktree préexistant** : la préférence « lancer le dernier jeu » semble choisir le premier jeu sain plutôt que le dernier joué.
10. **Benchmark volontairement borné** : une autre génération Pokémon pourrait changer la priorité de certaines règles.

### 19.3 Auto-critique

L'audit est large mais ne prétend pas remplacer :

- un audit exhaustif attaque par attaque, talent par talent et objet par objet ;
- une matrice complète `EncounterKind × modèle × editor × runtime × tests` ;
- un playtest de la campagne sur desktop/mobile ;
- une étude juridique sur la distribution d'un fangame ;
- une spécification validée du Personalization Hub.

La distinction entre `DONE V0` et parité Pokémon est indispensable, mais elle rend certaines lignes plus complexes. Les futurs rapports devraient conserver deux axes séparés — **lot PokeMap** et **profondeur Pokémon** — plutôt que tenter un statut unique.

### 19.4 Verdict

- **Rapport FG-000 : GO / `DONE` proposé**, car le DoD documentaire est rempli, les échecs sont consignés et aucun changement de code n'était requis.
- **Produit MVP : NO-GO validation**, tant que les trois tests rouges et le receipt `FG-185` ne sont pas résolus.
- **Parité Pokémon mainline : PARTIELLE**, avec un cœur singles/progression/exploration déjà substantiel.
- **Personalization Hub : fondations PARTIELLES, capacité produit encore ABSENTE à PARTIELLE**.

Le prochain lot recommandé n'est pas une mécanique avancée : c'est la restauration de la gate Selbrume et le branchement d'une vraie fin de jeu. En parallèle, `PH-000` peut établir le contrat et le shell du Personalization Hub, puis `PH-001` brancher le branding existant et `PH-002` livrer la vidéo d'introduction comme premier résultat visible.
