# BETA-PERF-010 — Audit global des performances du Map Editor et de la World Map

## Fiche de lot

| Champ | Valeur |
|---|---|
| Lot | `BETA-PERF-010` |
| Domaine Notion | `Performance éditeur` — domaine existant `0. Performance éditeur — STOP-SHIP` |
| Ticket Notion | [BETA-PERF-010](https://app.notion.com/p/3bc197a7bfa581928802f2ee88fa719f?pvs=204) |
| Nature | Audit architecture, performances, stabilité et qualité des gates |
| Date | 2026-08-15 |
| Statut proposé | `TO REVIEW` |
| Verdict | **FAIL / STOP-SHIP** |
| Confiance | Forte sur le pattern systémique, variable sur le poids relatif de chaque cause |
| Git initial | `fcfa34e2e62109ce302b6e429bcca33a86058285`, `main`, worktree propre |
| Git mesuré | `c3ad77ee0442e4482b5601367b69c3bceb039248`, `main`, worktree propre avant création de ce rapport |
| Application | Flutter macOS, `map_editor` |
| Projet utilisateur inspecté | `/Users/karim/Desktop/pokeMap Project/le_train_de_17h42` |

## Résumé exécutif

L'intuition utilisateur est confirmée : **la World Map n'est pas un incident isolé**. Le problème est systémique, mais `EditorState` n'en est pas l'unique cause. Le pattern commun est qu'un événement local ou haute fréquence sort de sa frontière locale — publication globale, `setState` racine, ticker, Future recréé ou `apply`/write lancé pendant un geste — puis déclenche un travail dimensionné par la map, le projet ou l'historique.

Le pattern causal dominant est :

```text
événement local ou haute fréquence
    ↓
sortie de la frontière locale
(publish global OU root setState OU Future/apply/write)
    ↓
comparaisons/projections/rebuilds/IO trop larges
    ↓
rescans projet/map + préparation du canvas + IO parfois lancées depuis build
    ↓
commit dense + diff/historique pleine surface au pointer-up
    ↓
validation/snapshot/plan/apply/persistence whole-document
    ↓
allocations, GC, frames manquées, blocages et risques de gestes perdus
```

Le painter de base et le culling isolé ne suffisent donc pas à expliquer le problème. Plusieurs inner loops ont déjà été optimisées et passent leurs budgets locaux, mais le coût existe avant le painter, après le handler, au pointer-up, au 25e commit, dans le shell réel et dans les écritures canoniques. Le chemin painter animé multi-layer du projet réel, lui, n'est pas innocenté.

Quatre observations fraîches montrent qu'un vert local ne certifie pas le produit :

| Preuve fraîche | Résultat | Pourquoi c'est problématique |
|---|---:|---|
| Éditeur de collision fine 1024², commit | **99,484 ms** | Gel visible au relâchement ; ce temps n'est pas bloquant dans la gate |
| Éditeur de collision fine 1024², FrameTiming P95 | **20,363 ms** | Dépasse le budget de frame à 60 Hz ; la policy est seulement `observation` |
| Soak synthétique, 5 saves, max/reporté P95 | **3,513 s** | La gate autorise 5 s, donc une sauvegarde de plusieurs secondes reste verte |
| Processus debug réel après GC forcé | **595,526,192 octets de heap Dart** | Heap retenu élevé observé ; pression système, fuite et contribution au lag non établies |

Le projet réel amplifie certains de ces défauts : manifeste de 10,311,615 octets, 28 maps, 132 tilesets, 604 éléments, 57 personnages, catalogue Smart Tile de 3,526,462 caractères, et environ 11 GiB sur disque dont 7,397,884 KiB de transactions historiques.

À l'inverse, ses maps sont petites : `map_hanazuki_village` fait 64×48 et la plus grande map canonique observée fait 70×85, soit 5 950 cellules. Les benchmarks 1024² prouvent des cliffs et une mauvaise scalabilité, mais **pas** le dominant du lag actuel sur ce projet.

Il apporte aussi un multiplicateur World Map très crédible : 266 animations Smart Tile et sept couches `animationActivation=always` sur `map_hanazuki_village`. Le clock repeint toutes les 110 ms et les couches considérées animées bypassent le picture cache. Le faux positif de classification est confirmé ; sa contribution quantitative au lag reste à profiler.

Le verdict produit est donc **STOP-SHIP** pour l'utilisabilité de l'éditeur. Il ne recommande pas une réécriture complète. Il recommande un découpage en lots ciblés, mesurés dans le shell réel, en commençant par la frontière haute fréquence et les cliffs de commit/persistence.

## 1. Audit du prompt et confirmation du scope

### 1.1 Validité de la demande

La demande est large mais cohérente avec le retour terrain : les symptômes touchent la World Map et l'application entière. Une analyse limitée au raster ou au canvas aurait été trop étroite et aurait probablement reproduit les faux positifs des gates existantes.

L'interprétation retenue est donc :

- auditer la chaîne complète input → état → build → paint → commit → persistence ;
- auditer la World Map en profondeur ;
- chercher le même pattern dans les autres studios et le shell ;
- inspecter les tests, budgets, receipts et rapports antérieurs ;
- mesurer le HEAD courant en profile sur macOS ;
- inspecter en lecture seule le projet réel et le processus Flutter réel ;
- proposer un ordre de correction sans implémenter les correctifs.

### 1.2 Scope technique

Inclus :

- `packages/map_editor` ;
- contrats et égalités de modèles dans `packages/map_core` ;
- persistence et transactions via `packages/map_authoring` ;
- receipts macOS profile ;
- projet jouable réel, en lecture seule ;
- heap Dart et RSS du processus éditeur déjà ouvert ;
- risques de correctness liés aux latences et à la concurrence.

Exclus volontairement :

- modification du code fonctionnel ;
- suppression ou migration de données du projet réel ;
- nettoyage destructif des transactions historiques ;
- attribution d'un pourcentage causal sans trace end-to-end sur le projet réel ;
- certification d'une fuite mémoire native ou Dart ;
- refonte visuelle ;
- runtime de jeu, sauf changement concurrent de HEAD signalé plus bas.

### 1.3 Frontières préservées

- Aucun Git write n'a été exécuté.
- Aucun fichier source ou test n'a été modifié.
- Aucun schéma projet n'a été changé.
- Le projet réel a été inspecté sans écriture.
- Les essais UI ont utilisé une fixture jetable lorsque l'accès sandbox au projet réel n'était pas possible.
- La parité PokeMap MCP est **N/A** : cet audit ne crée ni ne modifie une sémantique d'authoring, une commande, un format ou un comportement runtime.
- Aucun lot `FG-*` n'est applicable : il s'agit de performance éditeur et non d'une mécanique de fangame.

## 2. État Git et changement concurrent

L'audit a commencé avec :

```text
main
fcfa34e2e62109ce302b6e429bcca33a86058285
git status: propre
```

Pendant l'audit, le checkout partagé a avancé vers :

```text
main
c3ad77ee0442e4482b5601367b69c3bceb039248
feat(cinematics): bridge scene presentation playback
```

Le delta concurrent concerne uniquement `map_runtime` et ses tests Cinematics. La commande suivante confirme qu'il n'existe aucun delta dans les packages audités pour les causes principales :

```text
git diff --quiet fcfa34e2e..c3ad77ee -- \
  packages/map_editor packages/map_core packages/map_authoring
exit 0
```

Les constats `map_editor`, `map_core` et `map_authoring` restent donc valides au SHA final mesuré. Le changement de HEAD est documenté pour ne pas maquiller la provenance des preuves.

Après la fin des profils et validations, pendant la rédaction de ce rapport, une première vague de dix fichiers source est devenue modifiée dans le checkout partagé vers 01:05–01:06 :

```text
packages/map_authoring/lib/src/domains/maps/smart_tile_catalog_support.dart
packages/map_authoring/lib/src/domains/maps/smart_tile_native_transition_guard.dart
packages/map_authoring/lib/src/domains/maps/smart_tile_tiled_wang_projection.dart
packages/map_core/lib/src/models/enums.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/operations/project_manifest_border_catalog_operations.dart
packages/map_core/lib/src/operations/smart_tile_layer_creation.dart
packages/map_core/lib/src/validation/validators.dart
packages/map_editor/lib/src/application/use_cases/project_management_use_cases.dart
packages/map_editor/test/project_pokemon_config_test.dart
```

Le travail concurrent a continué à s'étendre après cette première observation, notamment vers des fichiers générés, des tests et de la documentation Cinematics. Ces modifications n'ont pas été produites, modifiées, testées ou incluses dans cet audit. Toutes les mesures et conclusions sont figées au tree propre `c3ad77ee0`. Leur contenu courant ne peut pas être certifié par les validations listées ici ; le snapshot Git au handoff est donné à la fin du rapport.

## 3. Méthode et niveaux de preuve

### 3.1 Niveaux utilisés

| Niveau | Signification |
|---|---|
| Confirmé | Le chemin existe dans le code courant ou une mesure fraîche le reproduit |
| Hypothèse forte | Le mécanisme est présent et cohérent avec les symptômes, mais pas reproduit end-to-end sur le projet réel |
| Non établi | La donnée suggère un risque mais ne permet pas de conclure |

### 3.2 Passes réalisées

- inventaire de l'architecture d'état et des consommateurs Riverpod ;
- trace des gestes pan, zoom, peinture, Smart Tiles et fine masks ;
- trace du commit, de l'historique et de la persistence canonique ;
- audit des autres studios et du shell ;
- audit des caches, Futures créés dans `build`, images et lifecycle ;
- exécution de tests ciblés et analyses statiques ;
- quatre journeys macOS en mode Flutter profile ;
- inspection du manifeste et du stockage authoring du projet réel ;
- GC forcé et allocation profile du processus réel ;
- essai Marionette sur une fixture jetable ;
- inspection visuelle Chronicle limitée à l'état d'application disponible ;
- critique indépendante des conclusions.

### 3.3 Verdicts des passes exigées

| Rôle | Verdict | Synthèse |
|---|---|---|
| Audit / Architecture | **FAIL / STOP-SHIP** | Agrégat global, blast radius Riverpod, dérivations répétées, commit/history/persistence proportionnels à la map ou au projet |
| Implémentation / Faisabilité | **N/A pour cet audit** | Aucun correctif autorisé ; découpage de lots et faisabilité audités séparément |
| Tests | **FAIL en couverture performance end-to-end** | Les tests ciblés passent, mais ils ne couvrent pas le shell réel, le pointer-up, le 25e checkpoint, la persistence réelle et les frames bloquantes |
| Build / Validation | **PASS technique / INSUFFISANT produit** | Compilation profile, analyses et tests ciblés passent ; les contrats actuels ne certifient ni la fluidité réelle ni le soak 30 minutes |
| Critique finale | **PASS après recalibration** | STOP-SHIP justifié pour la readiness ; causalité, tailles réelles, statistiques, mémoire, stockage et sévérités ont été rabattus aux preuves disponibles |

## 4. Pattern architectural global

### 4.1 Un agrégat immutable global à trop grand rayon d'explosion — P0 confirmé

`EditorState` rassemble dans le même objet :

- `ProjectManifest` complet ;
- `MapData` complet ;
- viewport et zoom ;
- sélection, outils et interaction ;
- historique, snapshot sauvegardé et dirty ;
- statuts async, erreurs et messages globaux.

Preuves principales :

- `packages/map_editor/lib/src/features/editor/state/editor_state.dart:63-150` ;
- provider global `packages/map_editor/lib/src/features/editor/state/editor_notifier.g.dart:12-26` ;
- égalité Freezed `packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart:1223-1229` ;
- égalité `MapData` dans `packages/map_core/lib/src/models/map_data.freezed.dart:337-343` ;
- égalité `ProjectManifest` dans `packages/map_core/lib/src/models/project_manifest.freezed.dart:16-36`.

Signal structurel :

- `EditorNotifier` fait environ 15 622 lignes ;
- 635 publications `state =` ;
- 595 appels `copyWith` ;
- 32 watches complets directs dans 31 fichiers ;
- 67 fichiers référencent le provider.

La taille du notifier n'est pas un benchmark CPU. Elle prouve en revanche que viewport, document, busy, messages et studios partagent le même bus et donc le même blast radius.

Les 32 full watches sont un inventaire statique, pas la preuve que 32 widgets sont simultanément montés ou reconstruits dans chaque scénario.

Nuance : pendant un simple pan, `project` et `activeMap` conservent en général leur identité et leur égalité peut court-circuiter. Lors d'une mutation map/projet, les égalités structurelles sont réellement susceptibles d'être rejouées par le provider et plusieurs selectors.

### 4.2 Les événements haute fréquence publient cet état global — P0 confirmé

Le pan et le zoom vont jusqu'au notifier global :

- pan souris : `packages/map_editor/lib/src/ui/canvas/map_canvas.dart:2752-2761` ;
- pan trackpad : `packages/map_editor/lib/src/ui/canvas/map_canvas.dart:2837-2865` ;
- molette : `packages/map_editor/lib/src/ui/canvas/map_canvas.dart:2883-2913` ;
- publication : `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart:14255-14280`.

Il n'existe pas de coalescing sur la frame et le viewport n'est pas isolé dans un controller haute fréquence. Chaque événement brut peut donc devenir une publication et un rebuild.

Le `StatusBar` combine un listener ciblé avec un watch complet de `EditorState` :

- `packages/map_editor/lib/src/ui/shared/status_bar.dart:95-121`.

Le vrai shell monte le workspace World Map et cette barre ensemble :

- `packages/map_editor/lib/src/ui/editor_shell_page.dart:930-1073`.

Résultat : même un pan qui ne modifie aucune donnée métier réveille au minimum le canvas et la barre de statut.

### 4.3 Le build du canvas refait des dérivations projet — P0 confirmé

À chaque rebuild, le canvas :

- recrée un `EditorState` temporaire : `map_canvas.dart:817-850` ;
- recalcule les chemins d'assets : `map_canvas.dart:909-920` ;
- reconstruit les transparences : `map_canvas.dart:921-928` et `3596-3617` ;
- reconstruit les maps d'images, erreurs et colonnes : `map_canvas.dart:965-990` ;
- recalcule le besoin d'animation : `map_canvas.dart:991-1001` ;
- programme un callback post-frame.

Le collecteur de chemins parcourt maps, palettes, ObjectLayers, catalogues Smart Tile, features et snapshots de bordure :

- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_tileset_path_collector.dart:5-135`.

Des index projet complets sont reconstruits pour les éléments, personnages et dresseurs :

- `packages/map_editor/lib/src/ui/canvas/entity_editor_element_visual.dart:284-347`.

Le resolver d'animation recrée plusieurs index et rescane la map et le projet :

- `packages/map_editor/lib/src/ui/canvas/map_canvas/editor_canvas_animation_need_resolver.dart:7-40` ;
- `packages/map_editor/lib/src/ui/canvas/map_canvas/editor_canvas_animation_need_resolver.dart:43-57` ;
- `packages/map_editor/lib/src/ui/canvas/map_canvas/editor_canvas_animation_need_resolver.dart:89-119` ;
- `packages/map_editor/lib/src/ui/canvas/map_canvas/editor_canvas_animation_need_resolver.dart:147-187`.

Les images peuvent être servies par cache, mais leurs collections et leurs métadonnées sont tout de même reconstruites ou comparées. Le frame peut donc être perdu avant l'appel au painter.

### 4.4 Le coût sparse du geste devient dense au pointer-up — P1 actuel / P0 scalabilité

Le buffer de stroke garde des overrides locaux pendant le geste :

- `packages/map_editor/lib/src/application/services/map_cell_stroke_buffer.dart:68-109` ;
- publication locale `map_cell_stroke_buffer.dart:831-834`.

Mais le commit rematérialise les tableaux :

- commit `map_cell_stroke_buffer.dart:440-492` ;
- TileLayer `map_cell_stroke_buffer.dart:617-645` ;
- CollisionLayer `map_cell_stroke_buffer.dart:647-666` ;
- Smart Tile `map_cell_stroke_buffer.dart:668-735`.

Le notifier applique ensuite la mutation et clôt l'historique :

- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart:8501-8543` ;
- `_applyMapMutation` `editor_notifier.dart:14294-14355`.

Après la copie dense, le chemin paie encore :

- comparaison profonde dans `packages/map_editor/lib/src/features/editor/application/map_editing_controller.dart:200-217` ;
- réconciliation des sélections dans `editor_map_session_coordinator.dart:22-173` ;
- calcul dirty par comparaison au snapshot dans `editor_map_mutation_coordinator.dart:206-223` ;
- publication globale et comparaisons des projections Riverpod.

Le journey collision fine 1024² confirme le même cliff architectural sur une autre surface de l'application : pointer move P95 1,238 ms, paint P95 4,989 ms, puis commit **99,484 ms**. Il ne monte pas la World Map et ne mesure pas directement `MapCellStrokeBuffer`. Avec des maps réelles plafonnant actuellement à 5 950 cellules, cette preuve caractérise surtout la scalabilité et les futures grandes maps.

### 4.5 L'historique est compact en stockage, pas en calcul — P1 actuel / P0 checkpoint

`MapHistoryDelta.between` construit des deltas pour tous les champs :

- `packages/map_editor/lib/src/application/models/map_history_delta.dart:48-66` ;
- layers `map_history_delta.dart:347-360` ;
- Tile/Collision `map_history_delta.dart:401-419` ;
- Smart Tile `map_history_delta.dart:610-643`.

Le helper sparse parcourt chaque index lorsque les tailles sont égales :

- `map_history_delta.dart:708-744`.

Modifier la dernière cellule d'une map 1024² peut donc demander environ 1 048 576 comparaisons par tableau concerné, même si le delta final ne contient qu'une cellule.

Le checkpoint de production ajoute un cliff périodique :

- intervalle 25 dans `map_history_coordinator.dart:7-10` ;
- composition `editing_service_providers.dart:31-37` ;
- construction avant contrôle du budget `map_history_coordinator.dart:197-230` ;
- JSON complet avant/après `map_history_entry.dart:38-66`.

Tous les 25 commits, les deux maps peuvent être synchroniquement transformées en JSON et octets. Si le checkpoint dépasse ensuite le budget de 16 MiB, il est retiré, mais le coût CPU et les allocations ont déjà eu lieu.

Le benchmark actuel désactive précisément ces checkpoints et tolère un P95 de 50 ms :

- `packages/map_editor/benchmark/map_history_delta_scaling.dart:10` ;
- `packages/map_editor/benchmark/map_history_delta_scaling.dart:60-64` ;
- `packages/map_editor/benchmark/map_history_delta_scaling.dart:168-173`.

### 4.6 La persistence reste whole-document — P0/P1 confirmé

Une modification locale du projet reconstruit et sauvegarde le manifest complet :

- `packages/map_editor/lib/src/application/use_cases/project_management_use_cases.dart:42-55` ;
- `packages/map_editor/lib/src/application/use_cases/project_element_use_cases.dart:15-45`.

La sauvegarde :

- valide le projet complet dans `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart:110-130` ;
- parcourt les domaines avec `ProjectValidator` dans `packages/map_core/lib/src/validation/validators.dart:86-133` ;
- relit, fusionne, encode, compare et flush dans `file_repositories.dart:185-237`.

L'offload commence à 1 MiB, mais `project.toJson()` est déjà construit sur l'isolate UI pour estimer la taille, et certaines branches resérialisent ensuite :

- `editor_persistence_codec_executor.dart:54-75` ;
- `file_repositories.dart:104-147` ;
- `file_repositories.dart:202-255`.

La sauvegarde map canonique passe par snapshot → plan → apply → snapshot :

- `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart:18-60` ;
- `packages/map_editor/lib/src/application/authoring_api/authoring_mutation_adapter.dart:312-362`.

Elle encode puis redécode la map, recharge des snapshots et effectue des passes d'identité sur les ressources projet. Ces opérations protègent la cohérence et les races, mais leur coût est proportionnel au projet, pas seulement à la mutation.

Le journey frais mesure :

- publication canonique : **1,625453 s** ;
- deux `apply` : **562,758 ms** et **569,976 ms** ;
- save : **640,804 ms**, dont `apply` **573,775 ms**.

Sur le scénario synthétique à 10 000 éléments placés, les cinq saves prennent de 3,146 s à 3,513 s.

## 5. World Map — causes spécifiques

### 5.1 Preview Smart Tile en pleine map — P1 chemin confirmé, sévérité actuelle à mesurer

Le hover/preview Smart Tile peut déclencher un flood fill proportionnel à la map depuis le build :

- appel `packages/map_editor/lib/src/ui/canvas/map_canvas.dart:1062-1105` ;
- flood et allocations `packages/map_core/lib/src/operations/smart_tile_layer_operations.dart:244-281` ;
- tri du résultat `packages/map_core/lib/src/operations/smart_tile_layer_operations.dart:148-167` ;
- peinture de toutes les cellules preview `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:2295-2307`.

Les gestes pattern utilisent aussi `List.contains` dans des boucles cumulatives :

- `packages/map_core/lib/src/operations/smart_tile_pattern_operations.dart:144-149` ;
- `packages/map_core/lib/src/operations/smart_tile_pattern_operations.dart:214-226`.

Le coût peut donc évoluer vers `O(n²)` sur les grandes sélections.

Ce chemin est confirmé dans le code, mais le catalogue du projet réel contient actuellement zéro `smartTileCatalog.patterns` et les maps restent petites. Il ne doit donc pas être présenté comme une cause P0 du lag actuel sans reproduire un outil qui crée ou manipule effectivement ces patterns.

### 5.2 Environment mask pleine surface — P1 hypothèse, complexité confirmée

Le chemin copie et valide la totalité du mask :

- copie `packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart:195-203` ;
- validation complète `environment_mask_use_cases.dart:209-238` ;
- publication globale `editor_notifier.dart:11592-11641` et `14294-14354` ;
- scan painter `map_grid_painter.dart:1266-1293`.

Le journey `editor_fine_mask_journey_test.dart` ne couvre **pas** ce chemin : il monte `ElementCollisionTripleMaskEditor` seul dans un `CupertinoApp`. Son commit à 99,484 ms prouve un autre éditeur dense/global, pas la latence de `environment_mask_use_cases`. Le coût World Map de l'environment mask reste confirmé par le code mais sa sévérité produit sur des maps de 3 000 à 5 950 cellules doit être mesurée séparément dans le shell réel.

### 5.3 Indexation globale au placement — P1 chemin confirmé / P0 scalabilité

Au pointer-up d'un placement, le flux rematérialise la map puis recalcule les index/catalogues :

- commit `editor_notifier.dart:8501-8538` ;
- tri catalogue et scans de couverture dans `packages/map_editor/lib/src/application/services/placed_element_instance_indexer.dart:49-78` ;
- index et footprints `placed_element_instance_indexer.dart:108-264`.

Le coût dépend du nombre d'éléments, placements, cellules et footprints, même lorsqu'une seule instance change. Le projet réel plafonne actuellement à 442 placements sur une map ; aucun timing pointer-up placement réel ne démontre que ce chemin est une cause P0 de la session actuelle.

### 5.4 Frontière de repaint différente du harness — P2, à mesurer

Le workspace de production ne place pas la même frontière que le test :

- production `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_workspace.dart:463-489` ;
- `RepaintBoundary` explicite du harness `packages/map_editor/test/ui/world_map/world_map_rebuild_isolation_test.dart:551`.

Le test prouve aussi que palette, toolbelt et inspector **ne** rebuildent pas pendant le pan dans son arbre réduit. Il ne monte ni le vrai shell, ni le Project Explorer complet, ni la StatusBar et ne chronomètre pas la préparation du canvas.

L'absence de cette `RepaintBoundary` en production est un fait, pas une cause P0 démontrée : une boundary ne supprime ni le rebuild du canvas ni son propre repaint. Son bénéfice dépend du compositing et doit être mesuré avant modification.

### 5.5 Faux positifs d'animation Smart Tile — P0 mécanisme confirmé, poids à mesurer

Le projet réel possède 32 atlases et 266 définitions d'animation Smart Tile. La map `map_hanazuki_village` contient sept couches Smart Tile avec `animationActivation=always`; `route_hanazuki_vers_gare_hanazuki.json` en contient deux.

Le resolver considère pourtant qu'une couche Smart Tile visible avec activation `always` est animée dès que **le catalogue global contient au moins une animation**, sans vérifier si le preset de cette couche emploie réellement une source animée :

- `packages/map_editor/lib/src/ui/canvas/map_canvas/editor_canvas_animation_need_resolver.dart:80-87`.

Croisement avec le projet réel :

- Hanazuki : 7/7 couches sont déclarées animées par le resolver ; 6/7 presets n'ont aucune part `source.kind=animation` ; seule la couche water en possède 41 ;
- route canonique : 2/2 couches sont déclarées animées ; leurs deux presets n'ont aucune part animée.

Ce ne sont donc pas seulement des animations coûteuses : **huit couches sur neuf observées sont des faux positifs d'animation**.

Le clock du canvas notifie les painters toutes les 110 ms :

- `packages/map_editor/lib/src/ui/canvas/map_canvas/editor_canvas_repaint_clock.dart:7-23`.

Le painter détermine les layers animés, puis contourne entièrement le picture cache lorsqu'un layer est considéré animé :

- sets animés `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:411-426` ;
- bypass `map_grid_painter.dart:1124-1144`.

Les Smart Tiles sont ensuite peints en plusieurs passes — background, actor occlusion et foreground — et chaque appel résout un visual batch :

- appels `map_grid_painter.dart:655-676`, `810-829` et `890-909` ;
- résolution `map_grid_painter.dart:3182-3250`.

Chaque résolution reconstruit aussi les maps du catalogue complet, dont les 32 atlases et 266 animations :

- `packages/map_core/lib/src/operations/smart_tile_layer_visual_resolver.dart:247-272`.

Ce mécanisme est particulièrement raccord avec le projet réellement ouvert : même sans input, plusieurs couches hors cache peuvent forcer des repaints et reconstruire des index globaux environ neuf fois par seconde. Son poids CPU/GPU exact reste à profiler, mais il doit remonter avant les optimisations `O(n²)` qui ne sont pas activées par le catalogue courant.

### 5.6 Cache painter trop lié au viewport — P1 confirmé

Des caches sont indexés par zoom exact et bounds visibles. Les couches animées contournent certains caches et plusieurs overlays ne sont pas cullés. Le pan invalide donc davantage de travail que nécessaire alors que le contenu métier n'a pas changé.

### 5.7 Repaint correctness incomplet — P1/P2 bug source, impact à reproduire

`_sameToolPreview` omet les `cells` dans `shouldRepaint` :

- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:3400-3488`.

Deux previews ayant le même mode, origine et bounds mais une géométrie interne différente peuvent ne pas repeindre. Cela peut produire une preview visuellement obsolète ou incohérente. En pratique, `hoveredTile` change souvent en même temps et force déjà un repaint ; sans reproduction dédiée, ce défaut source ne mérite pas une sévérité P0.

### 5.8 Smart Tile canonique et gestes perçus comme perdus — P1 confirmé/hypothèse forte

Le flux combine :

- map optimiste ;
- geste pending ;
- plan/apply canonique ;
- adoption d'un snapshot ;
- replay de clics arrivés pendant l'écriture.

Le code reconnaît qu'un write canonique peut prendre des centaines de millisecondes :

- `editor_notifier.dart:8607-8613`.

Sur erreur, le burst optimiste peut être rollbacké et les clics pending supprimés :

- `editor_notifier.dart:8627-8713`.

Le mécanisme est correctness-safe face à un état canonique incertain. Visuellement, il peut ressembler à des clics qui disparaissent ou à une map qui cesse de répondre.

Le canvas annule aussi un drag si la source n'est plus la même instance de `MapData` :

- `map_canvas.dart:2603-2626`.

Une adoption canonique asynchrone peut donc invalider un geste. Ce mécanisme est présent ; sa fréquence réelle sur le projet utilisateur reste à reproduire.

## 6. Problèmes globaux hors World Map

### 6.1 Sortie application et travail non sauvegardé — P0 correctness confirmé

`EditorShellPage.didRequestAppExit` ne vérifie que les drafts d'identité Character Studio puis autorise la sortie :

- `packages/map_editor/lib/src/ui/editor_shell_page.dart:187`.

L'agrégateur de readiness global connaît pourtant map dirty, manifest dirty, Narrative, Personalization, studios et save en cours :

- `packages/map_editor/lib/src/features/editor_updates/application/editor_update_providers.dart:41`.

Conséquence : quitter pendant une écriture lente ou avec d'autres travaux non sauvegardés peut perdre des données. Ce bug n'explique pas les FPS, mais il transforme les latences en risque utilisateur majeur.

### 6.2 Facts / World Rules recrée son Future dans build — P1 confirmé

`NarrativeWorkspaceCanvas` observe tout `EditorState` :

- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:63`.

Le workspace Facts/World Rules crée un loader et un nouveau Future depuis le build :

- `narrative_workspace_canvas.dart:2029` ;
- `narrative_workspace_canvas.dart:2057`.

Le loader relit ensuite séquentiellement toutes les maps non actives :

- `packages/map_editor/lib/src/application/services/narrative_project_snapshot_loader.dart:30`.

Toute update globale peut donc recréer le Future, repasser par le loading et relancer les IO. Cela explique lag, flicker et chargements concurrents sur cette surface.

### 6.3 Cinematics journalise projet et historique complets — P0/P1 confirmé

Chaque édition protège la recovery avant publication :

- `packages/map_editor/lib/src/application/services/narrative_document_session.dart:220` ;
- `narrative_document_session.dart:854`.

Le record contient baseline, document courant, undo et redo :

- `narrative_document_session.dart:880`.

Pour Cinematics, le document est un `ProjectManifest` et l'historique peut atteindre 100 entrées :

- `packages/map_editor/lib/src/app/providers/core/repository_providers.dart:313`.

Chaque historique sérialise `before` et `after` complets :

- `packages/map_editor/lib/src/infrastructure/repositories/file_narrative_document_recovery_store.dart:254`.

Chaque écriture fait encode → write → flush → reread → decode → rename :

- `file_narrative_document_recovery_store.dart:155`.

La session est initialisée à chaque ouverture de projet, même sans ouvrir Cinematics :

- `editor_notifier.dart:682` ;
- `editor_notifier.dart:806` ;
- `editor_notifier.dart:1691`.

### 6.4 Cinematics écrit à chaque delta de drag — P0/P1 confirmé

Le resize de durée lance un `unawaited` à chaque `DragUpdateDetails` :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:5797` ;
- `cinematic_builder_workspace.dart:5812`.

Chaque callback rejoint le flux d'édition et le journal complet, sans throttle ni commit de fin de geste.

Risque de concurrence : `NarrativeDocumentSession.apply` calcule depuis `_state`, attend l'écriture, puis publie :

- `narrative_document_session.dart:381`.

Deux `apply` simultanés peuvent partir du même snapshot. Le store sérialise ses writes, mais cela ne garantit pas que deux candidats calculés sur la même base fusionnent leurs changements. La perte d'une édition indépendante est une hypothèse forte à couvrir par test.

### 6.5 Cinematics reconstruit un builder monolithique à chaque frame — P1 confirmé

L'`AnimationController` appelle `setState` à chaque tick :

- `cinematic_builder_workspace.dart:443`.

Cela reconstruit un builder d'environ 14 520 lignes :

- `cinematic_builder_workspace.dart:698`.

La timeline recalcule son read-model et construit toutes les lanes sans virtualisation :

- `cinematic_builder_workspace.dart:4055` ;
- `cinematic_builder_workspace.dart:4787`.

Le test frais mesure 6 818 premiers builds pour ouvrir le builder, mais reste vert avec une limite à 10 000. Le cold load vaut 1 116 ms et l'ouverture 1 020 ms, sous un budget de 5 secondes.

### 6.6 Branding relit trois images depuis build — P1 confirmé

Cover, icon et hero sont trois widgets stateless :

- `packages/map_editor/lib/src/features/personalization/presentation/project_branding_title_preview.dart:74` ;
- `project_branding_title_preview.dart:144`.

Le Future est recréé dans `build` et le fichier est relu entièrement :

- `project_branding_title_preview.dart:261-301`.

Effets : IO répétées, nouvelles `Uint8List`, nouvelles `MemoryImage`, redécodages et état fallback temporaire.

### 6.7 Projecteurs synchrones déjà perceptiblement lents — P1 confirmé

Recherche Narrative sur 10 000 entrées : P95 frais entre 93,4 ms et 95,9 ms, sous un budget de 220 ms.

- recherche synchrone depuis build `narrative_command_palette.dart:156-203` ;
- navigation recalculant puis reconstruisant `narrative_command_palette.dart:188`.

Projection Map Events sur 100 maps / 1 000 events : P95 frais **553 ms**, sous un budget de 3 s.

- provider `narrative_event_builder_v2_providers.dart:102` ;
- chargement séquentiel `narrative_event_authoring_session.dart:29-56` ;
- fingerprint du manifest complet `narrative_event_builder_v2_providers.dart:20-48`.

Ces tests verts documentent en réalité des blocages visibles.

### 6.8 Shell et panneaux cachés restent coûteux — P1 confirmé

- Le Project Explorer reste monté via opacity/IgnorePointer quand il est invisible : `editor_shell_page.dart:1146`.
- Il calcule `buildTilesetLibraryTree(project)` avant de décider si l'enfant Tilesets doit être monté : `project_explorer_panel.dart:613`.
- Le resize de l'inspecteur droit fait `setState` sur le shell à chaque delta : `editor_shell_page.dart:1432`.
- `EditorUpdateHost` dépend indirectement de l'état complet : `editor_update_host.dart:42`.

### 6.9 Cache images : borné partiellement, metadata même sur hit — P1 confirmé

`EditorImageCache` borne le master à 32 MiB :

- `packages/map_editor/lib/src/ui/assets/editor_image_cache.dart:119`.

Mais :

- un hit exécute `exists`, `resolveSymbolicLinks` et `stat` : `editor_image_cache.dart:207` ;
- `loadCrop` redemande les metadata : `editor_image_cache.dart:285` ;
- `loadMany` fait un `Future.wait` non borné : `editor_image_cache.dart:366` ;
- le budget ne couvre ni clones consommateurs, ni GPU/native, ni `ImageCache` Flutter : `editor_image_cache.dart:641` ;
- le provider utilise le root brut sans normalisation : `editor_asset_cache_providers.dart:5`.

Le cache Character Studio est borné en nombre d'entrées, pas en octets, et la révision projet globale participe à la clé :

- `character_studio_media_resolver.dart:8-47` ;
- `character_studio_workspace.dart:91`.

Plusieurs registries Cinematics abandonnent des `ui.Image` ou codecs sans contrat de disposal explicite :

- `cinematic_tileset_asset_registry.dart:9-108` ;
- `cinematic_map_backdrop_tile_render_plan.dart:32` ;
- `cinematics_library_workspace.dart:377` et `1034` ;
- `cinematic_emote_preview_overlay.dart:46` et `373`.

Ce sont des risques de mémoire native confirmés par ownership incomplet. Leur contribution quantitative au RSS n'est pas encore établie.

## 7. Projet réel et stockage authoring

### 7.1 Manifest réel

Mesure en lecture seule du 2026-08-15 :

| Donnée | Valeur |
|---|---:|
| `project.json` | 10,311,615 octets |
| SHA-256 | `2f6c3cf882e9a4fd579d14db2224639527f85ad584061ad63526d9aa59d5aa47` |
| Dernière modification | `2026-08-14T23:49:54+0200` |
| Maps | 28 |
| Tilesets | 132 |
| Éléments catalogue | 604 |
| Personnages | 57 |
| Smart Tile presets | 46 |
| Smart Tile materials | 87 |
| Smart Tile animations | 266 |
| JSON du seul catalogue Smart Tile | 3,526,462 caractères |
| `map_hanazuki_village` | 64×48 = 3 072 cellules |
| Plus grande map canonique observée | 70×85 = 5 950 cellules |

La taille du manifest explique pourquoi tout mécanisme whole-document, fingerprint ou resérialisation peut devenir visible. La taille des maps, elle, impose une nuance : les cliffs 1024² ne peuvent pas être déclarés dominants sur les maps actuelles.

### 7.2 Empreinte disque

`du -sk` frais :

| Zone | KiB |
|---|---:|
| Projet complet | 11,537,120 |
| `assets/` | 197,800 |
| `maps/` | 4,800 |
| `.pokemap/` | 11,127,304 |
| `.pokemap/authoring/transactions/` | 7,397,884 |
| `.pokemap/authoring/blobs/` | 3,661,928 |

Les transactions contiennent 911 répertoires :

- 909 `committed` ;
- 1 `preparing` ;
- 1 `staged`.

Les journaux append-only occupent :

| Fichier | Lignes | Octets |
|---|---:|---:|
| `history.jsonl` | 927 | 33,978,666 |
| `idempotency.jsonl` | 1 854 | 33,665,999 |
| `audit.jsonl` | 1 167 | 1,032,586 |

Nuance importante : le nettoyage best-effort des transactions committed a été ajouté après la création de ces 909 répertoires, datés du 3 au 12 août. Leur accumulation est donc une dette historique, pas la preuve que le cleanup courant échoue systématiquement.

Autre nuance : l'ouverture normale d'une session ne parcourt pas automatiquement tous les journaux de transactions. Ces 7,1 GiB sont une dette disque, backup, inspection recovery et maintenance ; ils ne sont pas prouvés comme cause directe de chaque frame.

Le répertoire `preparing` le plus récent correspond à une opération `editor_map_save_...` du 14 août et contient un journal incomplet. Cela prouve au moins qu'un save a laissé un artefact de transaction à récupérer ou nettoyer.

### 7.3 Coûts IO structurels

Le système de transactions stage des payloads avant et après complets. Le blob store copie, hash et peut relire un blob complet même lors d'une réutilisation. Ce sont les principaux coûts récurrents confirmés. Les JSONL de 32 MiB sont surtout coûteux au premier accès ou après invalidation ; ils sont ensuite conservés en cache pour les appends suivants.

Ces garanties servent l'atomicité et l'idempotence. Elles doivent être conservées fonctionnellement, mais les payloads before/after, copies, hash, reads et flushs actuels augmentent le coût et les allocations des publications canoniques. Les 7,4 GiB de transactions historiques ne sont pas relus dans le chemin normal.

Aucune suppression de transaction ou blob n'a été effectuée pendant cet audit. Un nettoyage futur doit être un lot séparé, avec backup, inventaire des états, rétention explicite et preuve de recovery.

## 8. Mémoire du processus réel

### 8.1 Mesure fraîche

Le processus Flutter debug réel était ouvert depuis environ 7 h 57 au moment de la dernière mesure. L'interface visible se trouvait dans Narrative Studio/Cinematics, pas sur la World Map ; cette allocation profile décrit donc l'application globale et ne peut pas être imputée au canvas World Map. Après GC forcé via le VM service :

| Métrique | Octets |
|---|---:|
| Heap Dart utilisé | 595,526,192 |
| Capacité heap | 683,081,728 |
| External usage | 38,616,592 |
| RSS courant VM | 666,107,904 |
| Mémoire courante VM | 722,911,232 |
| Max RSS du processus | 1,916,780,544 |

Classes les plus lourdes après GC :

| Classe | Instances | Octets |
|---|---:|---:|
| `_OneByteString` | 2,235,643 | 145,077,424 |
| `_List` | 856,865 | 98,160,496 |
| `_Uint8List` | 30,397 | 68,374,928 |
| `_TwoByteString` | 16,857 | 68,079,936 |
| `_Uint32List` | 424,712 | 46,555,120 |
| `_Map` | 429,472 | 27,486,208 |
| `UnmodifiableMapView` | 407,144 | 13,028,608 |

Graphes métier retenus :

| Classe | Instances | Lecture |
|---|---:|---|
| `_ProjectManifest` | 3 | Trois graphes projet décodés |
| `_EditorState` | 5 | État courant et états encore retenus par providers/callbacks |
| `_MapData` | 37 | Au-delà des 28 maps déclarées |
| `_ProjectElementEntry` | 1 812 | Exactement 604 × 3 |
| `_ProjectTilesetEntry` | 396 | Exactement 132 × 3 |
| `_ProjectCharacterEntry` | 171 | Exactement 57 × 3 |

Des retaining paths observés passent par Riverpod, des snapshots authoring et des sessions de query. Ces trois manifests peuvent être des caches/snapshots intentionnels. Ils confirment une multiplication du graphe de données en mémoire, pas une fuite.

### 8.2 Ce que cette mesure ne prouve pas

- Elle provient d'un build debug/JIT, pas d'un build profile ou release.
- Elle ne sépare pas complètement heap Dart, images natives, GPU et caches Flutter.
- Elle ne montre pas une croissance monotone au fil du temps.
- Un max RSS à 1,9 GiB ne prouve pas que cette mémoire était simultanément utile ou retenue après GC.
- Elle ne permet pas d'attribuer le heap aux différentes fonctionnalités en pourcentage.

Verdict exact : **heap debug retenu élevé observé et graphes métier amplifiés ×3 ; fuite, pression système et contribution au lag non établies**.

## 9. Mesures profile fraîches au SHA `c3ad77ee0`

Les quatre receipts ont été générés sur un tree propre en `flutter-profile` macOS.

### 9.1 Journey projet

Receipt : `packages/map_editor/build/performance/audit_20260815_editor_project_journey.json`.

| Phase | Résultat |
|---|---:|
| Project open | 1,361626 s |
| Map open | 32,700 ms |
| Publication canonique d'un élément | 1,625453 s |
| Save | 640,804 ms |
| Frame total P95 | 8,874 ms |
| Frame total P99 | 28,558 ms |
| Frames > 16,67 ms | 3 / 164 |
| RSS fin de run | 418,807,808 octets |
| Octets alloués | 170,067,376 |
| Allocations | 595 060 |
| Heap après GC | 96,177,392 octets |

Le FrameTiming est `observation`, pas un critère d'échec. Le journey utilise une fixture synthétique et sa latence pointer s'arrête à la publication synchrone, pas au frame affiché suivant.

Deux autres signaux sont enregistrés sans faire échouer le run : mask roundtrip 1024² P95 **20,896 ms**, et un maximum `mutation.local` de **21,854 ms** noyé dans un P95 global de 2 µs calculé sur 4 708 échantillons hétérogènes.

### 9.2 Journey projection canvas

Receipt : `packages/map_editor/build/performance/audit_20260815_editor_canvas_projection_journey.json`.

| Métrique | Résultat |
|---|---:|
| Combined 1024² P95 | 1,385 ms |
| Cached repaint 1024² P95 | 1,153 ms |

Ce receipt passe ses budgets. Il exclut explicitement GPU raster, layout/composition, rasterisation de la picture et shell complet. Il prouve que le cœur de projection isolé est rapide ; il ne prouve pas que l'application qui l'entoure l'est.

Le viewport reste constant à 512×512, soit 289 cellules visibles, et les scénarios principaux affichent seulement zéro à deux éléments. C'est un contrat de culling utile, pas une reproduction du contenu de la World Map réelle.

### 9.3 Soak court

Receipt : `packages/map_editor/build/performance/audit_20260815_editor_performance_soak_journey.json`.

Configuration :

- 10 cycles paint/undo de 100 cellules ;
- fixture 128² ;
- 10 000 éléments placés ;
- 5 saves ;
- durée étendue configurée à **0 minute**.

| Métrique | Résultat | Budget |
|---|---:|---:|
| Paint P95 | 2,428 ms | 8 ms mutation |
| Undo P95 | 2,235 ms | 50 ms |
| Mutation grand projet P95 | 1,824 ms | 16 ms |
| Save grand projet médiane | 3,168892 s | — |
| Save grand projet max / P95 reporté | 3,513111 s | 5 s |
| Croissance heap de la fenêtre complète | 34,598,144 octets | 67,108,864 octets |

Le receipt passe. Les cinq observations de save sont toutes comprises entre 3,146 s et 3,513 s ; avec `n=5`, le « P95 » calculé est simplement le maximum et ne caractérise pas une distribution stable.

La fenêtre de croissance heap inclut aussi le rechargement final de la map et conserve volontairement ses 10 000 placements. Les 34,598,144 octets ne peuvent donc pas être attribués aux cinq saves ni qualifiés de fuite/rétention anormale. Ce n'est pas un soak 30 minutes et cela ne démontre pas la stabilité longue durée.

### 9.4 Éditeur de collision fine isolé

Receipt : `packages/map_editor/build/performance/audit_20260815_editor_fine_mask_journey.json`.

Ce journey monte `ElementCollisionTripleMaskEditor` seul dans un `CupertinoApp`. Il caractérise une surface globale de l'application et sa scalabilité 1024², pas la World Map ni l'environment mask.

| Extent | Pointer move P95 | Paint P95 | Commit | Frame P95 | Frame max |
|---:|---:|---:|---:|---:|---:|
| 64 | 0,057 ms | 0,409 ms | 0,466 ms | 3,697 ms | 14,646 ms |
| 256 | 0,130 ms | 0,864 ms | 6,791 ms | 4,836 ms | 9,052 ms |
| 512 | 0,366 ms | 1,690 ms | 26,654 ms | 6,242 ms | 12,557 ms |
| 1024 | 1,238 ms | 4,989 ms | **99,484 ms** | **20,363 ms** | 26,215 ms |

Les budgets ne portent que sur pointer move et paint. Commit et FrameTiming ne sont pas bloquants. Le test est donc vert alors que le scénario 1024² contient des frames hors budget et un commit d'environ 100 ms.

Il n'existe qu'une mesure de commit par dimension dans ce receipt ; la variance du commit 99,484 ms n'est donc pas estimable. Le 1024² ne contient que 38 samples FrameTiming : le P95 20,363 ms représente environ deux frames hautes dans un run unique, pas une distribution stable.

## 10. Pourquoi les gates actuelles peuvent être vertes alors que l'application lag

### 10.1 Mauvaise frontière de mesure

`pointer.to_state_publish` s'arrête dans le handler avant :

- rebuild ;
- layout ;
- préparation du canvas ;
- paint ;
- raster ;
- frame présenté ;
- commit de fin de geste.

Le soak chronomètre certains appels Notifier puis pompe après la mesure. Il ne capture donc pas tout le travail Flutter généré par la mutation.

### 10.2 Fixtures trop petites ou trop synthétiques

- Le vrai pointer drag du journey utilise une map 64².
- Les maps 1024² ne reçoivent que quatre commits et n'atteignent pas le 25e checkpoint.
- Le test d'isolation n'embarque pas le vrai shell.
- Le canvas projection exclut plusieurs étapes du frame.
- Le test Cinematics ne joue pas la timeline, ne drag pas et ne journalise pas le recovery complet.
- Les tests de grandes surfaces Narrative évaluent surtout des fonctions pures, pas Riverpod + widgets + IO + frames.
- Le test de cleanup transactionnel rejoue immédiatement une clé idempotente après l'échec injecté, ce qui permet au second passage de nettoyer ; il ne simule pas des centaines de clés jamais rejouées.
- Le cleanup de production avale les exceptions de suppression, et la sélection testée ne caractérise pas l'accumulation historique gigaoctet.
- Les tests de rétention travaillent sur cinq à six petites entrées, pas sur des JSONL de plus de 30 MiB.

### 10.3 Budgets compatibles avec un lag visible

- Save : 5 secondes.
- Recherche Narrative : 220 ms.
- Projection Map Events : 3 secondes.
- Cold/open Cinematics : 5 secondes et 10 000 builds.
- Historique : 50 ms.
- FrameTiming : observation-only.

Un test vert peut donc certifier une propriété locale tout en laissant passer une UX inutilisable.

### 10.4 Cas de production explicitement absents

- pan/zoom full-shell ;
- StatusBar et panneaux réels ;
- pointer-up 1024² comme gate ;
- 25e commit et checkpoint JSON ;
- projet avec manifest réel de 10,3 MiB ;
- catalogues réels ;
- IO et allocations pendant le geste ;
- concurrence Smart Tile/Cinematics ;
- mémoire native/GPU ;
- soak de plusieurs minutes ;
- input-to-next-presented-frame.

## 11. Bugs et risques de correctness liés au pattern

| Sévérité | Surface | Risque | Niveau de preuve |
|---|---|---|---|
| P0 | Sortie application | Travail non sauvegardé ignoré hors Character Studio | Confirmé |
| P1/P2 | World Map preview | Géométrie preview potentiellement stale car `cells` omis ; `hoveredTile` masque souvent le défaut | Bug source confirmé, impact non reproduit |
| P1 | Smart Tiles | Rollback/replay pendant write canonique perçu comme clics perdus | Mécanisme confirmé, fréquence non mesurée |
| P1 | Drag World Map | Remplacement de l'instance `MapData` annule le geste | Mécanisme confirmé, reproduction réelle manquante |
| P1 | Cinematics | `apply` concurrents calculés sur le même `_state` peuvent perdre un changement | Hypothèse forte |
| P1 | Facts/Branding | Futures recréés, flicker et IO concurrents | Confirmé par code |
| P1 | Caches Cinematics | Images/codecs non disposés ou caches stale | Ownership incomplet confirmé, impact RSS non quantifié |
| P2 | Cinematics stage | Cache du stage uniquement par `mapId`, contenu potentiellement stale | Hypothèse forte |

## 12. Plan de remédiation recommandé

Le diagnostic ne justifie pas une réécriture globale immédiate. Il justifie des lots successifs avec une même règle : **le travail interactif reste local, borné et réversible ; le travail global n'arrive qu'à un commit explicite, asynchrone et mesuré**.

### P0-A — Gate end-to-end sur shell réel

Objectif : rendre impossible un nouveau faux vert.

À mesurer en profile/release macOS :

- pan souris et trackpad ;
- zoom ;
- World Map idle avec zéro puis plusieurs layers Smart Tile `always` ;
- paint continu ;
- pointer-up ;
- 25e commit ;
- save map ;
- publication Smart Tile ;
- drag Cinematics ;
- playback Cinematics ;
- Facts/World Rules ;
- projet petit, grand synthétique et clone sûr du projet réel.

Métriques bloquantes :

- input → frame présenté suivant ;
- FrameTiming P95/P99 et jank rate ;
- nombre de publications/rebuilds ;
- `canvas.prepare`, build, paint, raster ;
- commit séparé ;
- JSON/base64/IO pendant les gestes : zéro ;
- allocations, GC, heap et RSS ;
- save médiane/P95 avec budget UX, pas 5 s.

Critères proposés :

- pointer-to-frame P95 < 16,7 ms ;
- pointer handler P95 < 8 ms ;
- commit interactif P95 < 16,7 ms ou feedback asynchrone non bloquant explicite ;
- aucun IO/JSON/base64 pendant `pointerMove` ;
- aucun FrameTiming observation-only pour une gate STOP-SHIP ;
- scénario du 25e commit obligatoire ;
- soak réel au moins 10 minutes en CI release, 30 minutes en certification.

### P0-B — Isoler viewport et interaction haute fréquence

Fichiers probables :

- `editor_state.dart` ;
- `editor_notifier.dart` ;
- `map_canvas.dart` ;
- `world_map_workspace.dart` ;
- providers/selectors World Map ;
- `status_bar.dart`.

Changements attendus :

- sortir pan/zoom/hover/drag transient de `EditorState` ;
- utiliser un controller/provider haute fréquence dédié ;
- coalescer sur la frame ;
- sélectionner uniquement des scalaires dans StatusBar et shell ;
- ajouter une vraie frontière de repaint production ;
- ne publier dans l'état documentaire qu'au commit.

### P0-C — Mettre en cache les dérivations canvas par révisions stables

À indexer une fois par révision projet/map :

- paths de tilesets ;
- index elements/characters/trainers ;
- transparences ;
- visual resolutions ;
- besoin d'animation ;
- catalogues Smart Tile ;
- footprints d'éléments.

Les clés ne doivent pas dépendre du viewport ou de l'identité globale du manifest lorsque le contenu concerné n'a pas changé.

Le premier correctif candidat est le classifier Smart Tile : une couche `always` ne doit être considérée animée que si son preset/résolution visible utilise réellement une source d'animation. Les index du catalogue et résolutions réutilisables doivent être mis en cache par révision stable.

Le chemin animé demande ensuite une stratégie séparée : distinguer picture statique et sous-parties réellement animées, culler par viewport et ne ticker que lorsqu'une animation visible est active. Il ne faut pas simplement cacher une picture animée, ce qui figerait le rendu.

### P0-D — Rendre Smart Tiles et masks sparse/viewport-bounded

- flood fill preview calculé à l'entrée pertinente, pas à chaque build ;
- résultat mémorisé par layer revision + origine + mode ;
- membership en `Set`/bitset au lieu de `List.contains` cumulatif ;
- culling strict des previews et overlays ;
- mask édité par chunks ou deltas ;
- validation incrémentale des cellules/chunks touchés ;
- aucune copie/scan pleine surface au pointer move.

### P0-E — Commit, dirty et historique incrémentaux

- réutiliser directement les overrides du stroke buffer pour construire le delta ;
- patcher seulement les chunks/cellules touchés ;
- utiliser des revisions/générations pour dirty et selectors ;
- ne pas rescanner `width × height` pour retrouver un delta déjà connu ;
- supprimer, rendre sparse ou déporter le checkpoint JSON ;
- tester explicitement le 25e commit 1024².

### P0-F — Persistence et authoring bornés

- conserver atomicité, idempotence et anti-race ;
- éviter le double `toJson` sur l'isolate UI ;
- offloader la construction/encodage complet quand elle reste nécessaire ;
- indexer les identités de ressources par révision au lieu de doubles passes complètes ;
- limiter les payloads before/after aux ressources touchées ;
- revoir blob hit pour éviter copie/hash/read redondants ;
- définir une politique de rétention des transactions committed ;
- traiter séparément le journal `preparing` après preuve de recovery.

Le nettoyage des 909 transactions historiques doit être un lot explicite et réversible. Il ne doit pas être mélangé à l'optimisation interactive.

### P0-G — Correctness immédiate

- brancher la demande de sortie sur le readiness resolver global ;
- couvrir map/project/narrative/personalization/save en cours ;
- inclure `cells` dans l'égalité de preview ou remplacer l'égalité par une révision géométrique ;
- ajouter des tests concurrence sur `NarrativeDocumentSession.apply` ;
- rendre les états busy/error spécifiques au domaine/opération.

### P0/P1-H — Cinematics selon le scénario reproduit

- état local pendant le drag ;
- une seule mutation et une seule recovery write à la fin du geste ;
- queue de mutations sérialisée ;
- journal delta ou document spécialisé, pas `ProjectManifest × historique` ;
- isoler le playback dans un petit subtree animé ;
- virtualiser les lanes ;
- formaliser ownership/disposal de `ui.Image` et codec ;
- couvrir playback long, resize rapide, apply concurrent et mémoire native.

### P1-I — Futures, projecteurs et caches globaux

- Facts/World Rules en provider mémorisé par révision stable ;
- Branding en ressources chargées une fois par path/revision ;
- recherche indexée/débouncée et hors build ;
- Map Events préparé hors isolate UI lorsque le coût le justifie ;
- Project Explorer réellement démonté ou lazy ;
- caches bornés en octets et concurrence ;
- normalisation des paths ;
- invalidation fine, non par identité du projet entier.

### Ordre recommandé

```text
P0-A mesure réelle
    ├─ lag World Map idle → animations visibles / picture cache / culling
    ├─ lag pan/zoom → projection canvas + frontière viewport
    ├─ freeze pointer-up → commit / historique / indexation
    ├─ freeze save/apply → persistence / authoring
    └─ lag Cinematics → drag local / queue recovery / playback isolé

P0-G correctness peut avancer en parallèle
P1-I autres surfaces et caches vient après les P0 reproduits
```

Sans trace réelle, aucun ordre fixe « état puis cache » ou « cache puis état » n'est prouvé. La passe de faisabilité donne au cache documentaire canvas le meilleur ratio gain/risque avant une migration d'état, mais la piste animation idle peut dominer le projet courant et Cinematics peut dominer une autre session. P0-G peut avancer en parallèle car ses correctifs sont petits et les risques de perte de travail sont élevés.

Deux variantes sont explicitement **NO-GO** :

- remplacer globalement l'égalité structurelle de `MapData` ou `ProjectManifest` par l'identité ;
- supprimer les checkpoints/doubles vérifications anti-race sans mécanisme de sûreté équivalent.

Une publication identitaire dans la seule frontière UI peut être étudiée après preuve qu'aucun modèle imbriqué n'est muté en place. L'historique guidé par les hints du stroke doit toujours retomber sur un diff complet ou échouer clairement si le hint est incohérent ; accepter silencieusement un hint incomplet casserait undo/redo.

## 13. Inventaire des fichiers concernés

### Architecture et shell

- `packages/map_editor/lib/src/features/editor/state/editor_state.dart` ;
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` ;
- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart` ;
- `packages/map_editor/lib/src/ui/editor_shell_page.dart` ;
- `packages/map_editor/lib/src/ui/shared/status_bar.dart` ;
- `packages/map_editor/lib/src/features/editor_updates/application/editor_update_providers.dart` ;
- `packages/map_editor/lib/src/features/editor_updates/presentation/editor_update_host.dart`.

### World Map

- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart` ;
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart` ;
- `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_workspace.dart` ;
- `packages/map_editor/lib/src/application/services/map_cell_stroke_buffer.dart` ;
- `packages/map_editor/lib/src/application/models/map_history_delta.dart` ;
- `packages/map_editor/lib/src/application/models/map_history_entry.dart` ;
- `packages/map_editor/lib/src/application/services/map_history_coordinator.dart` ;
- `packages/map_editor/lib/src/application/services/placed_element_instance_indexer.dart` ;
- `packages/map_core/lib/src/operations/smart_tile_layer_operations.dart` ;
- `packages/map_core/lib/src/operations/smart_tile_pattern_operations.dart` ;
- `packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart` ;
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_tileset_path_collector.dart` ;
- `packages/map_editor/lib/src/ui/canvas/map_canvas/editor_canvas_animation_need_resolver.dart`.

### Persistence et authoring

- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart` ;
- `packages/map_editor/lib/src/application/authoring_api/authoring_mutation_adapter.dart` ;
- `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart` ;
- `packages/map_core/lib/src/validation/validators.dart` ;
- loaders, transaction store, blob store et logs de `packages/map_authoring`.

### Autres studios

- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` ;
- `packages/map_editor/lib/src/application/services/narrative_project_snapshot_loader.dart` ;
- `packages/map_editor/lib/src/application/services/narrative_document_session.dart` ;
- `packages/map_editor/lib/src/infrastructure/repositories/file_narrative_document_recovery_store.dart` ;
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart` ;
- `packages/map_editor/lib/src/features/personalization/presentation/project_branding_title_preview.dart` ;
- `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_command_palette.dart` ;
- `packages/map_editor/lib/src/features/narrative/state/narrative_event_builder_v2_providers.dart` ;
- `packages/map_editor/lib/src/ui/assets/editor_image_cache.dart` ;
- caches et registries Cinematics/Character Studio cités plus haut.

## 14. Fichiers modifiés par ce lot

Un seul fichier est créé :

- `documentation/reports/editor/map_editor_global_performance_audit_2026-08-15.md` ;
  - zones : scope, preuves, pattern causal, mesures, risques correctness, plan de remédiation, validation et auto-critique ;
  - raison : conserver l'audit ultra complet demandé ;
  - impact : documentation et traçabilité uniquement.

Aucun fichier Dart, test, configuration, fixture ou donnée projet n'est modifié.

Les fichiers dirty concurrents listés dans le snapshot Git final sont exclus de l'inventaire des modifications de `BETA-PERF-010` et ont été préservés tels quels.

## 15. Tests, analyses et builds

### 15.1 Tests créés ou modifiés

Aucun. Il s'agit d'un audit sans implémentation. Créer ou ajuster des tests sans changer de contrat aurait mélangé diagnostic et correction. Les tests existants ont été exécutés pour caractériser ce qu'ils prouvent et ce qu'ils ne prouvent pas.

### 15.2 Commandes ciblées fraîches

Commande principale :

```text
cd packages/map_editor
flutter test --no-pub \
  test/ui/world_map/world_map_large_map_performance_test.dart \
  test/ui/world_map/world_map_rebuild_isolation_test.dart \
  test/application/services/editor_performance_telemetry_test.dart \
  test/performance_driver_contract_test.dart \
  test/fine_mask_performance_contract_test.dart \
  test/perf_009_project_performance_driver_test.dart
```

Résultat : **69 tests passés, exit 0**.

Autres lots ciblés exécutés pendant les passes :

- 33 tests buffer/history/isolation : passés ;
- 21 tests World Map : passés ;
- 64 tests Cinematics/cache/persistence/driver, avec 1 suite performance volontairement skipped : passés ;
- 5 tests Narrative performance : passés.

Ces ensembles peuvent se recouvrir ; ils ne sont pas additionnés artificiellement en un total global.

### 15.3 Analyses

```text
cd packages/map_editor && flutter analyze --no-pub
No issues found, exit 0

cd packages/map_authoring && dart analyze
No issues found, exit 0
```

L'analyse `map_authoring` a également été rejouée avec le Dart embarqué dans Flutter 3.13 beta : `No issues found`, exit 0.

La passe Build / Validation a en plus exécuté :

- 62 tests World Map/performance : tous passés ;
- 48 tests transactions, idempotence, recovery, history et undo/redo : tous passés sous Dart 3.12 puis Dart 3.13 beta ;
- 7 tests du contrat fine-mask : tous passés.

Verdict exact : **PASS analyse/tests ciblés**, pas certification de fluidité.

### 15.4 Builds et journeys profile

Quatre commandes `flutter drive --profile -d macos` ont compilé et exécuté l'application :

```text
flutter drive --profile -d macos \
  --driver=test_driver/performance_driver.dart \
  --target=integration_test/editor_project_journey_test.dart \
  --dart-define=POKEMAP_PERF_OUTPUT=build/performance/audit_20260815_editor_project_journey.json

flutter drive --profile -d macos \
  --driver=test_driver/performance_driver.dart \
  --target=integration_test/editor_canvas_projection_journey_test.dart \
  --dart-define=POKEMAP_PERF_OUTPUT=build/performance/audit_20260815_editor_canvas_projection_journey.json

flutter drive --profile -d macos \
  --driver=test_driver/performance_driver.dart \
  --target=integration_test/editor_performance_soak_journey_test.dart \
  --dart-define=POKEMAP_PERF_OUTPUT=build/performance/audit_20260815_editor_performance_soak_journey.json

flutter drive --profile -d macos \
  --driver=test_driver/fine_mask_performance_driver.dart \
  --target=integration_test/editor_fine_mask_journey_test.dart \
  --dart-define=POKEMAP_PERF_OUTPUT=build/performance/audit_20260815_editor_fine_mask_journey.json
```

Résultat : les quatre builds profile et journeys passent et écrivent leurs receipts au SHA `c3ad77ee0` avec `treeState=clean`.

Toolchain déclarée par les receipts : Flutter `3.46.0-0.3.pre`, framework `677d472756…`, Dart `3.13.0 beta`, Flame `1.38.0`, macOS arm64.

Avertissements non bloquants observés :

- warnings Swift de plugins externes `audioplayers` et `video_player` ;
- message `Failed to foreground app; open returned 1` avant connexion réussie ;
- avertissement du plugin `integration_test` ;
- aucun de ces messages n'a empêché les tests ni la création des receipts.

Le message de foreground diminue toutefois la valeur des runs comme mesure de ressenti : l'application a pu être pilotée sans être au premier plan. Les résultats restent valides pour les spans internes et les contrats du driver, mais ne doivent pas être confondus avec une session utilisateur réelle au focus.

Le workflow officiel demande `POKEMAP_PERF_SOAK_MINUTES=30`, tandis que le validateur accepte une valeur supérieure ou égale à zéro. Le run de cet audit à zéro minute n'est donc **pas** la certification soak finale.

Autre faiblesse de provenance : le project journey emploie un vrai fingerprint `HEAD^{tree}`. Canvas et soak hachent surtout status/diff/untracked, ce qui donne le même fingerprint pour différents commits propres ; le champ `commit` exact compense partiellement cette faiblesse. Le receipt fine-mask n'a pas de fingerprint d'arbre.

## 16. QA visuelle et reproduction réelle

Le processus utilisateur réel n'exposait pas l'extension Marionette. Une application debug jetable a donc été lancée sur une fixture seed : ouverture d'une petite map réussie et logs vides.

Une tentative de QA déterministe sur un clone APFS du projet réel a été bloquée par la sandbox/TCC macOS : l'application de test ne pouvait pas ouvrir le path temporaire ou le projet Desktop. Le clone avait le même hash que la source avant et après inspection et n'a pas été utilisé pour écrire dans le projet.

Le clone temporaire a été déplacé de façon récupérable dans :

```text
/Users/karim/.Trash/pokemap-perf-audit.AHYkhA
```

Il pourra être définitivement supprimé en vidant la Corbeille. L'application QA a été arrêtée.

Chronicle montrait l'application ouverte dans Narrative Studio/Cinematics, pas la World Map, et la frame disponible était déjà ancienne d'environ treize minutes. Cette observation n'est donc utilisée ni comme preuve de latence ni comme mesure.

## 17. Limites explicites

- Pas de geste World Map déterministe sur le projet réel à cause de la sandbox de l'application QA.
- Le processus réel inspecté est un build debug/JIT.
- Les journeys profile utilisent des fixtures synthétiques.
- Aucun soak 30 minutes n'a été exécuté ; le receipt indique 0 minute étendue.
- Pas de trace GPU native ou Instruments exhaustive.
- Pas de séparation quantitative du poids CPU de chaque cause.
- Pas de preuve de fuite mémoire monotone.
- Pas de reproduction de chaque « petit bug » signalé.
- Pas de mesure release notarized/distribuée.
- Les 909 transactions committed sont principalement historiques ; elles ne sont pas attribuées aux frames normales.
- Les retaining paths démontrent des graphes retenus, pas que chaque rétention est incorrecte.
- Le changement concurrent `map_runtime` n'a pas été audité comme cause de l'éditeur, car il n'altère pas les packages concernés.

## 18. Auto-critique finale

### Ce que cet audit prouve solidement

- Le blast radius d'`EditorState` et les full watches existent.
- Le pan/zoom publie dans l'état global sans coalescing.
- Le canvas refait des dérivations projet pendant ses rebuilds.
- Les commits fine-mask et stroke rematérialisent des structures denses.
- L'historique rescane la surface et le checkpoint sérialise des maps complètes.
- Plusieurs writes canoniques sont whole-document et prennent de centaines de millisecondes à plusieurs secondes.
- Facts, Branding et Cinematics lancent des travaux trop lourds depuis build/drag/tick.
- Les budgets actuels acceptent des latences visiblement janky.
- Le projet réel et le processus réel ont une empreinte suffisante pour amplifier ces chemins.

### Ce qui pourrait encore déplacer les priorités

- Une trace Instruments du projet réel pourrait montrer que GPU/images natives dominent un scénario précis.
- Le pan réel peut être davantage limité par raster/overdraw que par Riverpod selon la map affichée.
- Certains manifests retenus peuvent être intentionnels et nécessaires à la sûreté authoring.
- Les défauts Smart Tile ne se déclenchent pas tous avec la même fréquence selon l'outil actif.
- La sandbox a empêché une comparaison input-to-frame directement sur `le_train_de_17h42`.

### Risque de sur-correction

Découper `EditorState` en dizaines de providers sans modèle de révisions stable pourrait seulement déplacer la complexité. La bonne cible n'est pas « plus de providers » en soi : c'est une frontière claire entre état documentaire, état UI haute fréquence, read-models dérivés et opérations async.

Supprimer les snapshots, validations ou transactions pour gagner du temps serait dangereux. Les optimisations doivent préserver atomicité, recovery, idempotence et cohérence, tout en rendant leur coût incrémental ou hors du chemin interactif.

### Verdict critique final

**PASS sur la qualité de l'audit après recalibration.** Le verdict STOP-SHIP est justifié comme verdict de readiness et d'utilisabilité, pas comme preuve que chaque chemin classé P0 cause la session exacte.

Confiance finale :

- forte sur l'insuffisance des gates et le pattern de granularité ;
- moyenne sur le ranking causal World Map actuel ;
- faible sur fuite, pression mémoire ou stockage comme causes directes.

L'audit ne présente pas les 11 GiB de `.pokemap`, les trois manifests, le max RSS, le run collision fine 1024² ou l'absence de `RepaintBoundary` comme une causalité directe du lag World Map actuel.

## 19. Verdict final et statut proposé

Le domaine `Performance éditeur` reste **FAIL / STOP-SHIP**.

Le lot `BETA-PERF-010` peut être placé en `TO REVIEW` comme audit terminé, mais aucun ticket de correction ne doit être marqué `DONE` sur cette base.

La projection Notion a été créée puis relue : domaine unique `Performance éditeur`, statut `TO REVIEW`, priorité `P0`, verdict domaine `FAIL`, audit SHA `c3ad77ee0442e4482b5601367b69c3bceb039248`.

La priorité de correction est :

1. gate profile/release full-shell réellement bloquante sur clone sûr réel, cold/warm, village/route, idle et contrôle animations on/off ;
2. corriger le faux positif du classifier Smart Tile et mettre en cache les index/résolutions catalogue ;
3. corriger ensuite le scénario dominant révélé par la trace :
   - World Map idle : faux positifs animation, picture cache et culling ;
   - pan/zoom : projection canvas et frontière viewport ;
   - pointer-up : commit/history/indexation ;
   - save/apply : persistence canonique ;
   - Cinematics : drag local, recovery queue et playback isolé ;
4. correctness sortie/repaint/concurrence en parallèle ;
5. persistence, Facts, Branding, autres studios, caches, images et lifecycle ;
6. soak mémoire et Instruments native ;
7. cleanup transactionnel séparé et réversible.

La conclusion la plus importante est simple : **les optimisations locales précédentes n'étaient pas inutiles, mais elles ont certifié des morceaux. L'utilisateur, lui, utilise la chaîne entière. C'est cette chaîne qu'il faut maintenant rendre fluide et bloquer en CI.**

## 20. État Git au handoff

Snapshot pris le `2026-08-15T01:21:58+0200` :

```text
branch: main
HEAD: c3ad77ee0442e4482b5601367b69c3bceb039248

 M documentation/architecture/cinematic_v2_architecture_contract.md
 M documentation/architecture/contracts/cinematic_v2_contract_v1.json
 M documentation/roadmap/road_map_runtime_media_cinematics_audio_time.md
 M packages/map_authoring/lib/src/domains/maps/smart_tile_catalog_support.dart
 M packages/map_authoring/lib/src/domains/maps/smart_tile_native_transition_guard.dart
 M packages/map_authoring/lib/src/domains/maps/smart_tile_tiled_wang_projection.dart
 M packages/map_authoring/test/domains/assets/tiled_tileset_import_projection_test.dart
 M packages/map_authoring/test/domains/maps/smart_tile_catalog_actions_test.dart
 M packages/map_core/lib/src/models/enums.dart
 M packages/map_core/lib/src/models/map_data.g.dart
 M packages/map_core/lib/src/models/project_manifest.dart
 M packages/map_core/lib/src/models/project_manifest.freezed.dart
 M packages/map_core/lib/src/models/project_manifest.g.dart
 M packages/map_core/lib/src/operations/project_manifest_border_catalog_operations.dart
 M packages/map_core/lib/src/operations/smart_tile_layer_creation.dart
 M packages/map_core/lib/src/save/game_identity.dart
 M packages/map_core/lib/src/validation/validators.dart
 M packages/map_core/test/border/project_manifest_border_catalog_operations_test.dart
 M packages/map_core/test/smart_tiles/smart_tile_layer_creation_test.dart
 M packages/map_editor/lib/src/application/use_cases/project_management_use_cases.dart
 M packages/map_editor/test/project_pokemon_config_test.dart
?? documentation/reports/editor/map_editor_global_performance_audit_2026-08-15.md
?? packages/map_core/test/project_manifest_presentation_cinematics_test.dart
```

Le seul fichier appartenant à `BETA-PERF-010` est le rapport `documentation/reports/editor/map_editor_global_performance_audit_2026-08-15.md`. Les 21 autres fichiers modifiés et l'autre fichier untracked appartiennent au chantier concurrent et n'ont pas été touchés ni validés par cet audit.
