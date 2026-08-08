# Audit complet de PokeMap — état du projet au 8 août 2026

Date : 8 août 2026
Lot d'audit : `AUDIT-POKEMAP-COMPLET-2026-08-08`
Périmètre : monorepo PokeMap, Smart Tiles Studio, studios d'authoring, runtime, mécaniques de fangame, packages, distribution, MCP, CI et roadmaps
Nature de la passe : audit, validations et build read-only ; aucun correctif de production n'a été réalisé
Snapshot initial : `a936c5a76` sur `main`
Snapshot final observé : `f03a79511` sur `main`

> **Décision postérieure à l'audit :** la règle globale de longueur des fichiers Dart, son cliquet, son hook et sa gate CI ont été retirés le 8 août 2026. Les constats et priorités de ce rapport relatifs à cette règle décrivent uniquement le snapshot audité et ne constituent plus une action à mener.

## Verdict exécutif

PokeMap a beaucoup progressé et plusieurs sous-systèmes sont réellement substantiels. Le moteur de combat pur, le modèle Smart Tiles, la résolution visuelle, l'API d'authoring canonique et une grande partie des transports sont en bien meilleur état que lors des audits précédents.

Le projet complet ne peut cependant pas être déclaré vert ou prêt à produire un fangame Gen V de bout en bout.

Verdict global : **PARTIAL / NO-GO pour une certification complète**.

Les quatre causes principales sont :

1. une résolution de dépendances propre impossible pour le host jouable et l'outil de certification à cause de Riverpod ;
2. des suites cassées par la migration du modèle `TileLayer` et le passage obligatoire des projets Smart Tiles au format v6 ;
3. l'absence de playtest intégré dans l'éditeur et d'un profil de règles de combat Gen V global, explicite et versionné ;
4. des gates CI trompeuses ou cassées, dont le contrôle de longueur annoncé à 3 000 lignes qui contrôle actuellement 30 000 lignes.

Concernant Smart Tiles Studio : **le socle V1 et les lots historiques STN-01 à STN-11 restent largement crédibles, mais le Studio complet doit être classé PARTIAL et non DONE au snapshot audité**. Le modèle, la résolution, le rendu et la majorité du no-code fonctionnent. Le flux canonique de rollback est rouge, aucun test ciblé ne prouve encore receipt, history/undo et restauration des poids de densité, la validation globale est incomplète, la preuve de parité reste en partie déclarative et les gates globales editor/runtime sont rouges.

## Tableau des grands chantiers

| Grand chantier | État | Ce qui est bon | Ce qui empêche le vert |
|---|---|---|---|
| Modèle de carte et sérialisation v6 | 🟡 PARTIAL | Modèle riche, validation importante, Smart Tiles natifs | Tests et fixtures encore écrits pour l'ancien `TileLayer` ou des manifests v2 |
| Smart Tiles Studio | 🟡 PARTIAL | Modèle, résolution, transitions, patterns, rendu editor/runtime, Tiled V1 | Rollback canonique rouge ; aucun test ciblé receipt/history/undo/restauration des poids ; validation et preuves perf/parité insuffisantes |
| API canonique `map_authoring` | 🟢 solide mais non certifiée globalement | Suite séquentielle verte, transactions et 229 actions live | Inventaires désynchronisés, parité largement auto-déclarée, flakiness des workers concurrents |
| MCP PokeMap | 🟡 PARTIAL | Serveur live, 229 mutations, Smart Tiles et Tiled exposés | Gate release volontairement bloquée par cinq dettes PMCP-081, catalogue README obsolète, cold workers parfois en timeout |
| Ouverture de projets existants v6 | 🟡 À REVALIDER | Flux UI, restauration, dirty guards et tests ciblés présents | Smoke UI réel bloqué par le sandbox ; lifecycle global rouge ; aucun soutien legacy v2 exigé |
| World Map et connexions | 🟡 en évolution active | Lectures, actions, canvas adjacent-map récemment ajoutés | Snapshot modifié pendant l'audit ; validation globale editor rouge |
| Runtime carte | 🟡 PARTIAL | Plus de 2 100 tests passent, rendu Smart Tiles ciblé vert | Test Border obsolète, golden rotation divergente, 27 erreurs d'analyse dans un test legacy |
| Playtest intégré à PokeMap | 🔴 TODO | Ports et idées de composition existent | `PT-01` à `PT-11` sont TODO ; aucun vrai bouton carte → runtime certifié |
| Moteur de combat | 🟢 local / 🟡 hermétique | `map_battle` : 1 772 tests verts et analyse verte | Pas de profil Gen V global ; suite dépendante d'un PSDK externe sur machine propre |
| Données Pokémon jusqu'à la Gen IX | 🟡 PARTIAL | Catalogues et moteur ambitieux, indépendants du rendu | Complétude fonctionnelle end-to-end non certifiée dans un jeu jouable |
| Boucle fangame Gen V | 🟡 PARTIAL / NO-GO | Beaucoup de briques isolées existent | Nouvelle partie, starter, capture, progression, PC, menus, économie et story flow non certifiés ensemble |
| Narrative / événements / cinématiques | 🟡 PARTIAL | Modèles et studios riches, authoring canonique présent | Nombreux goldens rouges, fixtures Selbrume v2, preview vrai runtime absente |
| Audio | 🟡 PARTIAL | Mixer runtime, bus music/effects, driver cinématique, fades/loops, title music et preview existent | Audio Studio générique, lifecycle global, authoring complet, validation et budgets restent à fermer |
| Temps / jour-nuit / calendrier | 🔴 TODO ou différé | Roadmap détaillée | Moteur de temps et cycle jour-nuit non intégrés ; saisons explicitement différées |
| Personalization Studio / Hub | 🟡 PARTIAL | Packaging E2E ciblé passe dans Hub | UX non auditée comme utilisable ; composition propre bloquée par Riverpod |
| Distribution / Avelune Hub | 🔴 non certifiable | 376 tests Hub : 375 verts et 1 rouge | Fixture Selbrume v2 rouge, certification et host non résolvables proprement |
| CI, qualité et dette de fichiers | 🔴 | Plusieurs analyses ciblées vertes | Workflow de certification au mauvais chemin, gate 30 000, croissance baseline non bloquante, pas de matrice globale fiable |
| Roadmaps et preuves | 🟡 désynchronisées | Beaucoup de lots et rapports existent | Résumés, Evidence Packs et états ne correspondent plus tous au code actuel |

## 1. Smart Tiles Studio

### Verdict détaillé

| Capacité | Verdict | Preuve principale |
|---|---|---|
| Modèle Smart Tile natif | DONE | Modèles v6, sérialisation et suite `map_core/test/smart_tiles` verte : `+291 ~1` |
| Résolution déterministe | DONE dans le périmètre V1 | Résolveurs, seeds, candidates, transitions et tests ciblés verts |
| Patterns réutilisables | DONE dans le périmètre V1 | Modèle, paint/erase et flux editor testés |
| Rendu dans l'éditeur | DONE dans le périmètre Smart Tiles | Tests ciblés editor verts hors gate canonique |
| Rendu runtime | DONE dans le périmètre Smart Tiles | 12 tests runtime Smart Tiles verts |
| Studio no-code | PARTIAL | 217 tests Studio ciblés passent, mais le gate canonique finit à `+2 -1` |
| Import Tiled / Wang | PARTIAL | Atlas réguliers, image collections et TMX V1 présents ; Wang direct sur image collection et couverture TMX large non certifiés |
| Densité par poids de candidate | PARTIAL | Modèle, action canonique et UI présents ; aucun test ciblé ne prouve receipt, history/undo et restauration exacte des poids |
| Validation readiness | PARTIAL | `smart_tile_layer_readiness.dart` diagnostique les poids orphelins, sans preuve d'intégration dans la validation globale du projet |
| Undo / redo canonique | PARTIAL | Historique canonique présent ; la mutation de poids n'est pas prouvée dans la pile canonique au même niveau que paint/erase |
| API Dart directe | DONE pour les actions inspectées | `smart_tile.layer.set_candidate_weights` est enregistrée et testée |
| CLI / JSONL / MCP | PARTIAL | Action live visible ; la preuve PMCP reste largement déclarative et l'inventaire de capacité est stale |
| Performance | PARTIAL | Budgets de work-count ciblés verts ; budgets temporels globaux rouges ou sensibles à la charge |

### Échec bloquant reproduit

Commande :

```text
cd packages/map_editor
flutter test test/smart_tiles_studio/smart_tile_canonical_editor_flow_test.dart --reporter expanded
```

Résultat : `+2 -1`, exit 1.

Le scénario « a rejected canonical gesture rolls back its optimistic map exactly » s'arrête sur :

```text
Canonical editor flow failed: The material is not available in this Smart Tile layer.
```

Le message localisé a remplacé le contrat textuel attendu par le test. Le test n'atteint donc plus ses assertions de rollback. Il faut décider si le contrat stable est un code d'erreur ou un texte utilisateur, adapter le test au contrat stable, puis prouver que la carte optimiste est restaurée byte-for-byte.

### Parité live

`pokemap_describe` répond `ok: true` au snapshot final et annonce :

- 229 actions de mutation ;
- 17 kinds de ressources publiés par `describe()` ;
- 22 actions contenant `smart_tile` ou `tiled` ;
- `smart_tile.layer.set_candidate_weights` est bien exposée.

Ce résultat prouve la découvrabilité live. Il ne suffit pas à prouver que les quatre transports exécutent réellement chaque sémantique : la matrice `fullParity` affecte encore largement les transports depuis un catalogue déclaratif.

### Conclusion Smart Tiles

Le bon libellé produit est : **« Smart Tiles V1 substantiellement livré ; Smart Tiles Studio complet PARTIAL, fermeture courte nécessaire »**.

Pour le remettre au vert :

1. stabiliser le contrat d'erreur du geste canonique et restaurer le test de rollback ;
2. ajouter un test ciblé prouvant la receipt, l'history/undo et la restauration exacte des poids de densité ;
3. faire remonter la readiness des poids dans `MapValidator` et la validation de playtest ;
4. remplacer la parité auto-déclarée par une preuve exécutable directe/API, JSONL, editor et MCP ;
5. produire des receipts de performance reproductibles, avec budgets séparant coût algorithmique et temps wall-clock.

## 2. Packages, tests et analyses

Les premières suites lancées en parallèle ont montré de nombreux timeouts de contention. Elles n'ont pas été utilisées comme verdict définitif. Les résultats ci-dessous viennent de relances isolées ou séquentielles, sauf mention explicite.

| Package / application | Tests frais | Analyse fraîche | Verdict |
|---|---|---|---|
| `map_core` | `+3977 ~1 -8`, exit 1 | verte | 🔴 tests rouges |
| `map_gameplay` | compilation impossible dans 8 fichiers de test | 17 issues, exit 3 | 🔴 migration de tests incomplète |
| `map_battle` | `+1772`, exit 0 | verte | 🟢 localement ; 🟡 sans PSDK externe |
| `map_authoring` | `+446` en série, exit 0 | verte | 🟢 en série |
| `map_distribution` | `+75 -6`, exit 1 | verte | 🔴 fixtures de rapports absentes |
| `map_runtime` | `+2128 -2`, exit 1 | 27 issues dans un test Border legacy | 🔴 |
| `map_player_ui` | `+0 -21`, compilation impossible | verte avec résolution existante | 🔴 composition incohérente |
| `map_editor` | arrêt à `+5106 ~11 -95` après hang >10 min | 9 infos `prefer_const_constructors` | 🔴 suite globale non exploitable |
| `playable_runtime_host` | arrêt à `+237 ~3 -23` après hang | verte avec cache existant | 🔴 et `pub get` impossible |
| `pokemap_hub` | `+375 -1`, exit 1 | verte | 🟡 une fixture v2 obsolète |
| `pokemap_product_certification` | résolution propre impossible | verte seulement avec cache existant | 🔴 non certifiable |
| `gamepads_darwin` / `gamepads_ios` | aucun test package | analyse `--no-pub` verte | 🔴 `pub get` exit 65 |
| `tools/pokemap_mcp` | protocoles séquentiels verts ; cold worker flaky | `npm run check` vert | 🟡 |

### Détail des huit échecs `map_core`

1. inventaire de capacités d'authoring désynchronisé ; `smart_tile.layer.reconstruct` est live mais absent de l'attendu ;
2. budget Border `< 8 s`, mesure `9.643802 s` ;
3. receipt absent `reports/gameplay/generated/battle_mvp_capability_gate_v0.json` ;
4. dossier attendu `reports/gameplay/` absent depuis le contexte du test ;
5. budget Border `< 12 s`, mesure `16.099378 s` ;
6. receipt absent `battle_full_capability_gate_v0.json` ;
7. fixture de save absente sous `reports/product/pokemap_hub/phase_0/saves/...` ;
8. budget narrative `<= 80 000 µs`, mesure `105 937 µs`.

### `map_gameplay`

Huit fichiers de test utilisent encore les paramètres supprimés `tiles` et `tilesetId` de `TileLayer` :

- `placed_elements_collision_test.dart` ;
- `placed_element_behaviors_test.dart` ;
- `smart_tile_generated_gameplay_zone_bridge_test.dart` ;
- `gameplay_movement_effect_test.dart` ;
- `collision_building_golden_slice_test.dart` ;
- `hazard_runtime_consumption_test.dart` ;
- `placed_element_rotation_gameplay_test.dart` ;
- `los_detection_test.dart`.

Le choix produit peut rester « pas de legacy ». La bonne correction est alors de migrer ou supprimer explicitement ces tests, pas de réintroduire l'ancien modèle.

### `map_runtime`

Deux causes :

- `test/border/border_map_layers_component_ordering_test.dart` compile encore contre l'ancienne API Surface/Terrain/Path ;
- le golden `reports/ui/world_map_editor_gate_5_rotation_runtime.png` diverge dans `world_map_rotation_visual_evidence_test`.

### `map_editor`

La suite globale a été interrompue après plus de dix minutes, car un test Narrative a atteint son timeout de dix minutes et le suivant ne progressait plus. Les 95 échecs observés se regroupent en :

- goldens Narrative, Cinematic, Scenes et Storyline divergents ;
- référence visuelle Event Builder absente ou non conforme ;
- projet Selbrume v2 refusé par le loader v6 et assets Selbrume manquants ;
- tests et fixtures Border obsolètes ;
- lifecycle d'ouverture attendant une session stale mais recevant `manifest_invalid` ;
- Environment Studio : mutations d'ajout, suppression, régénération et paramètres de zone qui ne produisent pas l'état attendu ;
- gate Smart Tiles canonique rouge ;
- timeouts/hangs Narrative.

Ce total n'est pas un nombre de défauts produit indépendants : beaucoup d'échecs partagent les mêmes migrations de fixtures et de goldens. Il interdit néanmoins toute déclaration globale verte.

### `map_distribution` et Hub

Les six échecs de `map_distribution` sont tous des fichiers de preuve absents sous `reports/product/pokemap_hub/phase_0/` : vecteurs de canonicalisation, manifests valides/invalides et matrice de compatibilité.

Le Hub finit à `+375 -1`. Le seul échec charge une fixture Selbrume `version: v2`, alors que le loader exige désormais v6. Puisque le legacy n'est pas un objectif, cette fixture doit être migrée ou retirée du gate.

## 3. Build propre, dépendances et CI

### P0 — Riverpod empêche une résolution propre

`apps/pokemap_hub/pubspec.yaml:17` demande `flutter_riverpod ^3.0.3`.
`packages/map_editor/pubspec.yaml:16` demande `flutter_riverpod ^2.4.9`.

Le host et la certification composent les deux packages. Les deux commandes suivantes échouent avant compilation :

```text
cd examples/playable_runtime_host && flutter pub get --dry-run --offline
cd tools/pokemap_product_certification && flutter pub get --dry-run --offline
```

Message commun : `pokemap_hub ... incompatible with map_editor ... version solving failed`.

Les analyses vertes avec un `.dart_tool` existant ne constituent donc pas une preuve de build reproductible.

### P0 — Les plugins gamepad déclarent un workspace absent

`packages/gamepads_darwin/pubspec.yaml:2` et `packages/gamepads_ios/pubspec.yaml:2` déclarent `resolution: workspace`, alors que le dépôt ne possède pas de workspace Dart racine et que leurs contraintes de langage ne satisfont pas le prérequis de cette syntaxe.

`flutter pub get --dry-run --offline` finit avec exit 65 pour les deux packages.

### P0 — Workflow de certification au mauvais chemin

Le package réel est `tools/pokemap_product_certification`. Le workflow `.github/workflows/pokemap_hub_product_certification.yml` utilise pourtant :

- `tool/pokemap_product_certification/**` à la ligne 27 ;
- `working-directory: tool/pokemap_product_certification` aux lignes 70 et 384.

Conséquences : les changements du vrai package ne déclenchent pas correctement le workflow et les jobs concernés échouent avant leurs tests.

Le filtre `tools/performance/**` est correct au snapshot final ; l'ancien diagnostic sur un chemin singulier `tool/performance` ne s'applique plus.

### P0 — Le gate de 3 000 lignes contrôle 30 000

`tools/check_file_length.dart:16` définit :

```text
const int _limit = 30000;
```

`AGENTS.md`, la baseline et le workflow annoncent 3 000. La commande sort pourtant avec exit 0 et :

```text
File length OK — no file over 30000 lines outside the baseline (17 tolerated).
```

Le checker ne parcourt en outre que `packages` et `apps`, pas `examples` ou `tools`, et la croissance d'un fichier baseline est rapportée sans faire échouer la gate.

Deux fichiers ont grandi au-dessus de leur propre baseline :

| Fichier | Baseline | Actuel | Croissance |
|---|---:|---:|---:|
| `packages/map_core/lib/src/validation/validators.dart` | 3 106 | 3 117 | +11 |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | 13 790 | 13 977 | +187 |

### Autres risques de reproductibilité

- la dépendance au Pokémon SDK situé dans le dossier frère reste non hermétique pour une CI ou une machine neuve ;
- onze artefacts macOS `ephemeral_backup_20260323` sont suivis, dont un lien absolu ;
- aucune matrice CI unique ne certifie tous les packages du monorepo ;
- aucun lane CI dédié ne certifie le serveur MCP et son catalogue live ;
- certaines releases nécessitent des outils externes, secrets et notarisation non disponibles pendant cet audit.

## 4. Ouverture d'un projet et playtest

### Ouvrir un projet v6 existant

Le produit possède désormais :

- l'action toolbar et le dialogue d'ouverture ;
- un folder picker avec fallback de chemin ;
- l'activation et le chargement du projet ;
- la restauration du dernier projet et les bookmarks ;
- des guards de travail non sauvegardé ;
- des tests ciblés de ces responsabilités.

Des commits ont aussi ajouté les lectures de connexions, le graphe monde et l'ouverture d'une carte adjacente depuis le canvas pendant l'audit.

Verdict : **PARTIAL / à revalider sur une application installée**.

Le build macOS debug de `map_editor` réussit :

```text
✓ Built build/macos/Build/Products/Debug/PokeMap.app
```

Le smoke Marionette déterministe n'a pas pu atteindre l'UI. Le sandbox macOS refuse au binaire debug la lecture directe du projet dans le dépôt et dans `/private/tmp`, tandis que le terminal n'est pas autorisé à copier la fixture dans le conteneur applicatif. La fixture source a été hashée avant/après et est restée identique :

```text
7fe25c2dd4443a244b582a8c79300daecef179325fadb15f7cda8f4e8f49db65
```

Il faut une passe manuelle ou automatisée via le vrai folder picker, qui accorde un bookmark de sécurité, sur une build installée. Le projet de validation doit être v6. Le support d'un projet v2 n'est pas requis par la décision produit.

### Playtest intégré

La roadmap `documentation/roadmap/road_map_runtime_media_cinematics_audio_time.md` garde :

- `PT-01` à `PT-11` en TODO ;
- `PT-12` et `PT-13` en PARTIAL.

Le bouton « Tester » du Global Story Studio est explicitement désactivé tant que la boucle globale n'est pas branchée. Des simulations locales d'événements ou de presets existent, mais elles ne remplacent pas le vrai runtime.

Verdict : **TODO pour la boucle éditer → lancer la carte → diagnostiquer → revenir**.

## 5. Mécaniques de fangame Pokémon

### Cadre produit confirmé

La cible immédiate reste un fangame de structure Gen V en combat simple. Le moteur et les données peuvent couvrir les Pokémon jusqu'à la Gen IX, sans imposer les gimmicks postérieurs au gameplay de base.

Sont explicitement différés : Mega, Z-Moves, SOS, Ride remplaçant, Dynamax, raids, spawns visibles, autosave, mints, Téra, open world, auto-battle, pique-nique, crafting de CT, reproduction, saisons, Dive et combats doubles.

### État des grands blocs mécaniques

| Bloc mécanique | État | Lecture audit |
|---|---|---|
| Nouvelle partie et starter | PARTIAL | Contrats et contenu existent, flow global non certifié |
| Party | PARTIAL | Modèles et opérations présents, boucle UI/runtime incomplète |
| PC / boîtes | PARTIAL | Pas de preuve end-to-end complète |
| Sac, objets, boutiques, soin | PARTIAL | Briques présentes, parcours joueur complet non certifié |
| Rencontres sauvages | PARTIAL | Tables/zones/runtime existent, chaîne globale rouge |
| Capture | PARTIAL | Mécanique présente sans certification complète avec party/PC/save |
| Dresseurs | PARTIAL | Contenu et combats existent, progression/story intégrée incomplète |
| XP, niveaux, capacités, évolutions | PARTIAL | Moteur riche, persistance et UI end-to-end non closes |
| Récompenses, argent, badges | PARTIAL | Modèles et commandes présents, golden slice globale non verte |
| Capacités de terrain | PARTIAL | Surf avancé ; reste non clos ; Dive différé |
| Événements et dialogues no-code | PARTIAL | Authoring riche, tests editor/goldens rouges |
| Menus runtime | PARTIAL | Plusieurs écrans existent, parcours complet non certifié |
| Save/load gameplay | PARTIAL | Contrats robustes dans Hub, fixtures et intégration encore rouges |
| Readiness et export jouable | PARTIAL / NO-GO | FG-185 reste PARTIAL/NO-GO |
| Profil de règles Gen V | TODO | Aucun ruleset global/versionné trouvé dans `map_battle`, `map_core` ou `map_runtime` |

Le package `map_battle` est vert localement, mais sa suite complète découvre des sources PSDK dans le dossier frère fourni sur cette machine : cette preuve n'est pas hermétique sur une machine propre. Par ailleurs, « moteur de combat vert » et « règles Gen V cohérentes » sont deux affirmations différentes. Il manque un profil explicite qui fixe au même endroit au moins : table des types, catégories physique/spécial, précision, critiques, ordre/priorités, météo, statuts, switch, fuite, capture, XP, learn/evolution hooks et choix de compatibilité avec les données Gen IX.

### Roadmap FG

Inventaire automatisé des lots uniques du fichier canonique `pokemap_roadmap_mecaniques_fangame.md` :

| Statut déclaré | Nombre de lots uniques |
|---|---:|
| DONE | 40 |
| TODO | 41 |
| PARTIAL | 12 |
| DEFERRED | 21 |

Une occurrence dupliquée de `FG-024` existe. Le document est désynchronisé : le résumé de phases et la liste des prochains lots continuent de présenter certains travaux comme TODO alors que `FG-180` à `FG-184` sont déclarés DONE. `FG-185` reste PARTIAL/NO-GO, ce qui correspond au verdict frais.

La roadmap courte `documentation/roadmap/roadmap_suivi_mecaniques_pokemon_generation_v.md`, datée du 2 août, doit être considérée comme un tableau historique à resynchroniser, pas comme une preuve actuelle.

## 6. Cinématiques, médias, audio et temps

### Cinématiques

Les modèles et l'authoring canonique de cinématique sont substantiels. Le Studio ne doit pas être déclaré fini globalement : les goldens Cinematic/Narrative sont rouges, la preview dans le vrai runtime (`CIN-ST-12`) est TODO et la boucle playtest est absente.

La cible neutre reste pertinente : timelines in-game, plans caméra, fondus, dialogues, animation, médias vidéo/panorama et plans de paysage défilant doivent être des primitives génériques, jamais spécifiques à « Le train de 17h42 ».

### Audio

Le sous-système audio est **PARTIAL**, pas absent. Le dépôt contient déjà `RuntimeAudioMixer`, les bus music/effects, `FlameAudioCinematicRuntimeDriver`, lecture/fade/loop runtime, `RuntimeTitleMusicController`, import de musique de titre et preview dans Personalization Studio, avec des tests ciblés.

Le grand chantier restant concerne l'Audio Studio générique, le lifecycle global et la couverture projet complète. La cible recommandée reste :

1. assets et métadonnées audio dans `map_core` ;
2. intentions et règles pures de déclenchement dans `map_gameplay` ;
3. lecture, bus, ducking, boucles, spatialisation et lifecycle dans `map_runtime` ;
4. Audio Studio no-code et preview dans `map_editor` ;
5. validation des références, licences, volumes, formats et budgets ;
6. parité authoring directe, JSONL et MCP pour les sémantiques de projet.

### Temps

Le cycle jour-nuit, l'horloge de jeu, les jours de semaine, les contrôles de playtest et leurs effets visuels/audio sont encore TODO. La saison reste explicitement différée. Le moteur doit permettre un temps simulé indépendant de l'horloge système, avec un adaptateur optionnel vers l'heure réelle plutôt qu'un couplage obligatoire.

## 7. PokeMap MCP

### Ce qui est validé

- `npm run check` est vert ;
- la conformance PMCP-085 ciblée passe `7/7` ;
- les protocoles séquentiels passent `6/6` ;
- les tests read/workspace/security passent `5/5` ;
- le serveur live répond et publie 229 mutations ;
- les actions Smart Tiles/Tiled sont découvrables.

### Ce qui reste partiel

- le README annonce encore 61 ressources / 219 actions alors que le catalogue courant en annonce davantage ;
- le gate release complet relève cinq bypasses editor de `PMCP-081` ;
- une première passe concurrente cold-worker a produit 6 réussites sur 11 et 5 timeouts ;
- la « full parity » est surtout une déclaration de catalogue, pas un E2E indépendant pour chaque action.

Verdict : **transport utilisable et riche, certification globale PARTIAL**.

## 8. Roadmaps et studios

Les roadmaps ont servi à guider des travaux substantiels, mais elles ne peuvent plus être utilisées seules pour répondre « où en est-on ? ».

| Studio / domaine | État audit frais |
|---|---|
| Smart Tiles Studio | PARTIAL, presque clos dans son V1 mais gate canonique rouge |
| Border Studio | PARTIAL, budgets et tests legacy rouges |
| Environment Studio | PARTIAL, plusieurs mutations editor rouges |
| Narrative / Event / Scene / Storyline | PARTIAL, modèles riches mais nombreux goldens/fixtures rouges |
| Cinematic Studio | PARTIAL, authoring riche mais preview runtime et gates globales absents |
| Personalization Studio | PARTIAL, packaging ciblé existe mais UX et composition globale non certifiées |
| Audio Studio | TODO majeur |
| Runtime/playtest Studio | TODO majeur |
| World time Studio | TODO |
| Auto-update editor | roadmap avancée, non recertifiée dans cet audit transversal |

La règle pour la suite doit être : un lot n'est DONE que si ses tests ciblés, son analyse, son build consommateur, sa fixture v6 et son transport applicable sont frais et verts.

## 9. Priorités recommandées

### P0 — Rétablir une baseline technique honnête

Ordre recommandé :

1. corriger les chemins `tool/` → `tools/` du workflow de certification ;
2. remettre la limite à 3 000, étendre les roots utiles et faire échouer toute croissance baseline ;
3. aligner Riverpod entre Hub et editor, puis prouver `pub get` propre dans host et certification ;
4. retirer `resolution: workspace` des gamepads ou créer un vrai workspace compatible ;
5. migrer les huit tests `map_gameplay`, le test Border runtime et les fixtures v2 vers v6, sans restaurer le legacy ;
6. restaurer une matrice package-par-package fraîche en CI.

Ce chantier est le plus rentable : il transforme des caches locaux trompeurs en build reproductible et rend toutes les autres preuves fiables.

### P1 — Fermer Smart Tiles Studio

Une fois la baseline verte : rollback canonique, densité/undo, readiness globale, parité exécutable et receipts de performance.

### P1 — Ouvrir et tester depuis PokeMap

Certifier l'ouverture réelle d'un projet v6 via le folder picker, puis livrer `PT-01` à `PT-05` : carte courante, snapshot temporaire, spawn de test, save isolée et contrôle de session.

### P2 — Définir le ruleset Gen V et fermer la boucle RPG

Créer le profil de règles Gen V, puis prendre une golden slice unique : Nouvelle partie → starter → exploration → rencontre → capture ou combat dresseur → récompense/XP → soin/boutique → sauvegarde/rechargement.

### P2 — Audio, cinématiques runtime et temps

Construire ces moteurs après la boucle d'itération editor/runtime, afin que chaque incrément puisse être testé immédiatement dans le vrai jeu.

## 10. Commandes et preuves principales

| Commande | Résultat exact ou signal |
|---|---|
| `cd packages/map_core && dart test --reporter expanded` | `+3977 ~1 -8`, exit 1 |
| `cd packages/map_core && dart analyze` | `No issues found!`, exit 0 |
| `cd packages/map_core && dart test test/smart_tiles` | `+291 ~1`, exit 0 |
| `cd packages/map_gameplay && dart test` | compilation rouge dans 8 tests |
| `cd packages/map_gameplay && dart analyze` | 17 issues, exit 3 |
| `cd packages/map_battle && dart test` | `+1772`, exit 0 |
| `cd packages/map_battle && dart analyze` | `No issues found!`, exit 0 |
| `cd packages/map_authoring && dart test --concurrency=1` | `+446`, exit 0 |
| `cd packages/map_authoring && dart analyze` | `No issues found!`, exit 0 |
| `cd packages/map_distribution && dart test --reporter expanded` | `+75 -6`, exit 1 |
| `cd packages/map_distribution && dart analyze` | `No issues found!`, exit 0 |
| `cd packages/map_runtime && flutter test` | `+2128 -2`, exit 1 |
| `cd packages/map_runtime && flutter analyze` | 27 issues, exit 1 |
| `cd packages/map_editor && flutter analyze` | 9 infos, exit 1 |
| `cd packages/map_editor && flutter test` | interrompu à `+5106 ~11 -95` après hang |
| `cd packages/map_editor && flutter test test/smart_tiles_studio/smart_tile_canonical_editor_flow_test.dart --reporter expanded` | `+2 -1`, exit 1 |
| `cd packages/map_editor && flutter build macos --debug --no-pub` | `✓ Built build/macos/Build/Products/Debug/PokeMap.app`, exit 0 |
| `cd packages/map_player_ui && flutter test` | `+0 -21`, compilation rouge |
| `cd packages/map_player_ui && flutter analyze --no-pub` | `No issues found!`, exit 0 |
| `cd examples/playable_runtime_host && flutter pub get --dry-run --offline` | version solving failed, exit 1 |
| `cd examples/playable_runtime_host && flutter test --no-pub` | interrompu à `+237 ~3 -23` après hang |
| `cd examples/playable_runtime_host && flutter analyze --no-pub` | `No issues found!`, exit 0 avec résolution existante |
| `cd apps/pokemap_hub && flutter test --reporter expanded` | `+375 -1`, exit 1 |
| `cd apps/pokemap_hub && flutter analyze --no-pub` | `No issues found!`, exit 0 |
| `cd tools/pokemap_product_certification && flutter pub get --dry-run --offline` | version solving failed, exit 1 |
| `cd tools/pokemap_product_certification && flutter analyze --no-pub` | `No issues found!`, exit 0 avec résolution existante |
| `cd packages/gamepads_darwin && flutter pub get --dry-run --offline` | workspace/langage invalide, exit 65 |
| `cd packages/gamepads_ios && flutter pub get --dry-run --offline` | workspace/langage invalide, exit 65 |
| `cd packages/gamepads_darwin && flutter analyze --no-pub` | `No issues found!`, exit 0 |
| `cd packages/gamepads_ios && flutter analyze --no-pub` | `No issues found!`, exit 0 |
| `cd tools/pokemap_mcp && npm run check` | exit 0 |
| `cd packages/map_authoring && dart run tool/pmcp085_conformance.dart` | 62 concepts, 229 mutations, 0 bloqué/manquant |
| `cd packages/map_authoring && dart test --concurrency=1 test/parity/full_authoring_parity_test.dart` | `+7`, exit 0 |
| `cd tools/pokemap_mcp && node --import tsx --test --test-concurrency=1 test/protocol_compatibility.test.ts` | 6 tests, 6 pass, 0 fail, exit 0 |
| `cd tools/pokemap_mcp && node --import tsx --test --test-concurrency=1 test/read_only_server.test.ts` | 5 tests, 5 pass, 0 fail, exit 0 |
| `dart tools/check_file_length.dart` | exit 0, mais contrôle 30 000 lignes |
| `pokemap_describe` live | `ok: true`, 229 mutations, 17 resource kinds |
| `POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh` | `Markdown hygiene: 1 new Markdown file(s), all in canonical locations.`, exit 0 |

## 11. Passes indépendantes et contre-vérification

### Passe Smart Tiles

Verdict indépendant : **PARTIAL**. Les lots V1 historiques restent crédibles, mais la fermeture Studio est bloquée par le rollback canonique, l'absence de preuve ciblée receipt/history/undo/restauration des poids, la validation et les preuves de parité/performance.

### Passe mécaniques/runtime

Verdict indépendant : **PARTIAL / NO-GO Gen V jouable**. Le moteur de combat est riche, mais il manque le ruleset global, le playtest intégré et la golden slice RPG certifiée.

### Passe packages/build/CI

Verdict indépendant : **BLOCKED pour clean build et certification**. Le workflow de certification, la gate de longueur, Riverpod et les manifests workspace des gamepads sont les blocages principaux.

### Contre-lecture finale

La première contre-lecture a conclu `CHANGES_NEEDED` sur dix imprécisions de formulation ou de preuve. Une seconde passe a trouvé deux résidus sur la formulation densité/undo et les commandes MCP exactes. Les douze corrections ont été intégrées : comptage Hub, résultat cold-worker, caractère fail-closed de PMCP-081, prudence sur receipt/undo densité, audio PARTIAL, non-herméticité PSDK, résultats exacts, commandes MCP, état Git, hygiène Markdown et ordre des P0.

### Passe d'implémentation

Non applicable : l'utilisateur a demandé un audit, pas des correctifs. Aucun changement de production n'a été réalisé.

## 12. État Git, fichiers et limites

### État initial

```text
HEAD a936c5a76
 M packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_connections_inspector.dart
 M packages/map_editor/test/features/editor/presentation/world_map/world_map_connections_inspector_test.dart
```

### Activité concurrente observée

Pendant l'audit, une autre activité a fait avancer `main` :

```text
cdf4667f9 fix(editor): load draft connection targets
7e804d245 add petitparser
f03a79511 feat(editor): open adjacent maps from canvas
```

L'audit n'a exécuté aucune opération Git d'écriture. Les validations antérieures au déplacement de HEAD restent applicables aux zones non touchées ; les contrôles Smart Tiles canonique, Hub, résolution de dépendances, build editor, MCP live et gate de longueur ont été rejoués sur `f03a79511`.

### Fichier ajouté par l'audit

- `documentation/reports/architecture/pokemap_complete_project_audit_2026-08-08.md` : rapport consolidé présent.

Aucun code de production, test, fixture, roadmap canonique ou configuration n'a été modifié par cet audit.

### État final

```text
HEAD f03a79511
?? documentation/reports/architecture/pokemap_complete_project_audit_2026-08-08.md
```

### Limites

- pas de couverture LCOV globale, donc aucun pourcentage de couverture n'est avancé ;
- pas de notarisation, release mobile ou machine propre ;
- smoke d'ouverture UI bloqué par les permissions sandbox, donc ouverture v6 classée à revalider ;
- les suites editor et host ont dû être interrompues après hang ;
- les performances wall-clock sont sensibles à la charge et ne constituent pas seules une mesure algorithmique ;
- l'état Git a changé pendant l'audit, et les résultats sont explicitement rattachés aux snapshots concernés.

## 13. Auto-critique finale

Cet audit privilégie la preuve fraîche et refuse de transformer un rapport historique DONE en verdict actuel sans gate verte. Cette prudence peut sous-estimer des fonctionnalités qui marchent manuellement mais dont les tests sont obsolètes. Inversement, un grand nombre de tests verts ne prouve pas la qualité d'un parcours utilisateur complet.

Le plus grand risque d'interprétation serait de confondre les migrations volontairement non legacy avec des régressions produit. Les fixtures v2 ne demandent pas de restaurer le support v2 ; elles demandent de rendre les gates cohérentes avec la décision v6. Le second risque serait de déclarer Smart Tiles inachevé en bloc : ce serait faux. Son cœur V1 est avancé ; c'est sa certification Studio complète qui manque.

La priorité recommandée n'est donc pas de réécrire les systèmes fonctionnels. Elle est de rétablir une baseline reproductible et honnête, fermer Smart Tiles sur cinq preuves précises, puis brancher le vrai playtest. À ce moment-là seulement, le ruleset Gen V et les mécaniques RPG pourront avancer avec une boucle d'itération fiable.
