# BETA-ENC-007 — Comportements gameplay natifs des calques Smart Tile

Date d’audit : 2026-08-23
Statut proposé : `TODO` — `Gate bêta = true`
Domaine : `Rencontres & capture`
Lots mécaniques concernés : `FG-108` (validation à compléter), `FG-180`, `FG-181` et `FG-182` (preuves à adapter/rejouer, sans changement de statut)
Décision de scope : Yoahn a explicitement demandé le 2026-08-23 que ce nouveau ticket appartienne à la bêta.

## Verdict exécutif

Le comportement proposé par l’interface existe, mais il n’est pas attaché au calque Smart Tile. Le flux actuel transforme les cellules du calque en rectangles `MapGameplayZone`, les persiste séparément puis demande au runtime de ne lire que ces rectangles. Une peinture ultérieure peut donc produire de l’herbe visible sans rencontre tant qu’une resynchronisation n’a pas recréé les zones.

La correction canonique recommandée est de porter un comportement gameplay typé directement dans chaque `SmartTileLayer`, de résoudre les rencontres depuis les cellules sémantiques du calque et de supprimer le flux de génération/synchronisation de zones pour ce cas. Les zones manuelles restent disponibles pour les régions rectangulaires qui ne dépendent pas d’un calque Smart Tile.

Pour `Le train de 17h42`, la migration cible trois calques d’herbes hautes, un par table de rencontres, puis la suppression des dix zones de rencontre générées. Le résultat attendu est une partition exacte des 649 cellules d’herbe : 217 cellules nord, 194 sous-bois et 238 abords de gare, sans cellule oubliée ni chevauchement.

## Demande utilisateur et périmètre

Objectifs :

- retirer les zones de rencontre dérivées des Smart Tiles ;
- ajouter le comportement « hautes herbes avec rencontres » directement au calque ;
- autoriser plusieurs calques lorsque plusieurs tables de rencontres sont nécessaires ;
- migrer et certifier le projet `Le train de 17h42` ;
- garantir la parité API directe, JSONL/CLI, éditeur et MCP.

Non-objectifs :

- supprimer le concept général de `MapGameplayZone` ;
- modifier les tables de rencontres, la formule de tirage ou la capture ;
- introduire une compatibilité duale entre comportement natif et zones générées ;
- refondre l’ensemble du Smart Tiles Studio ;
- modifier directement le statut des lots `FG-108`, `FG-180`, `FG-181` et `FG-182`.

## Audit initial

### État Git

L’audit a commencé sur `main` au SHA `e6f95fad805f58af038fef4b6f9e7a77c7798b41`, dans un worktree déjà modifié par d’autres travaux. Pendant l’audit, des changements concurrents ont avancé `main` jusqu’au SHA `2c18210c2a4413bc8a881252cc098dfaeefbf605`. Aucun de ces changements n’a été modifié, masqué ou nettoyé par cet audit.

Le seul fichier ajouté par cet audit est le présent rapport. La liste finale des modifications concurrentes est conservée dans la section « État Git final ».

### Preuve visuelle

La capture utilisateur du 2026-08-23 montre une action intitulée « Créer un comportement depuis ce Smart Tile » avec les choix « Herbe haute avec rencontres », « Eau surfable » et « Lave dangereuse ». Cette formulation laisse raisonnablement entendre que le comportement sera porté par le Smart Tile.

Le dialogue d’implémentation révèle cependant sa vraie sortie : `SmartTileToGameplayZoneDialog` affiche « Créer une zone de rencontre depuis ce Smart Tile », compte les zones générées et propose ensuite « Synchroniser les zones » (`packages/map_editor/lib/src/features/smart_tiles_studio/presentation/smart_tile_to_gameplay_zone_dialog.dart:54-79`, `:138-150`).

Limite de preuve : l’application exécutable n’a pas été pilotée pendant cet audit ; la capture fournie et les contrats courants du dépôt constituent la preuve visuelle et structurelle. Une validation manuelle sur build réel reste un critère du ticket.

## Architecture actuelle

### 1. Deux sources de vérité persistées

`SmartTileLayer` porte le preset, la palette de matériaux, le champ sémantique, les variantes et le mode d’animation, mais aucun comportement gameplay typé (`packages/map_core/lib/src/models/map_layer.dart:121-145`).

`MapGameplayZone` porte séparément une zone rectangulaire, une priorité et les payloads typés de rencontre, mouvement, danger ou spécial (`packages/map_core/lib/src/models/map_data.dart:160-205`). Son commentaire précise explicitement qu’il sépare le comportement gameplay du visuel.

Ce découplage est valable pour une zone manuelle. Il devient fragile lorsque la zone est seulement une projection persistée d’un calque Smart Tile, car toute modification des cellules exige une seconde mutation pour maintenir la projection à jour.

### 2. Le comportement montré par l’UI est un brouillon de génération

`SmartTileGameplayZoneBehaviorDraft` ne fait pas partie du calque. Il alimente `createSmartTileGameplayZoneGenerationPlan`, qui :

1. calcule une provenance calque/preset/matériau/comportement ;
2. convertit les cellules en rectangles par bounding box ou algorithme glouton ;
3. construit un `MapGameplayZone` par rectangle avec le payload choisi.

Références :

- `packages/map_core/lib/src/operations/smart_tile_to_gameplay_zone_generation_plan.dart:90-143` ;
- `packages/map_core/lib/src/operations/smart_tile_to_gameplay_zone_generation_plan.dart:276-304` ;
- `packages/map_core/lib/src/operations/smart_tile_to_gameplay_zone_generation_plan.dart:519-554`.

### 3. La mutation canonique synchronise des zones

L’action authoring publiée est `gameplay_zone.smart_tile.sync`, décrite comme une synchronisation de zones générées depuis un binding Smart Tile. Son entrée accepte une liste `zones` et remplace les zones portant la même provenance (`packages/map_authoring/lib/src/domains/maps/trigger_zone_actions.dart:21-25`, `:67-69`, `:171-181`).

Le contrat est déjà testé dans l’API authoring et dans `tools/pokemap_mcp`, mais il expose précisément l’abstraction que la nouvelle architecture doit remplacer.

### 4. Le runtime ne consulte que `gameplayZones`

`checkEncounterAtPlayerPosition` transmet `world.map.gameplayZones` à `resolveEncounterZoneAtPosition` (`packages/map_gameplay/lib/src/gameplay_encounter.dart:136-149`). Le resolver filtre ces rectangles par position, kind et priorité. Les résolveurs de fond et de musique de combat consultent eux aussi `map.gameplayZones`.

Conséquence : supprimer aujourd’hui les zones de rencontre désactive les rencontres, même si les hautes herbes sont présentes dans un calque Smart Tile.

## Audit du projet `Le train de 17h42`

Carte auditée :

`/Users/karim/Desktop/pokeMap Project/le_train_de_17h42/maps/route_hanazuki_vers_gare_hanazuki.json`

État constaté :

| Élément | Valeur |
| --- | ---: |
| Taille de carte | 70 × 85 |
| Calques | 6 |
| Calque d’herbes | `smart_path_surface_global_grass_long_layer` |
| Preset | `smart_path_surface_global_grass_long` |
| Matériau | `smart_material_surface_global_grass_long` |
| Activation animation | `on_enter` |
| Visibilité enregistrée | `false` |
| Propriétés gameplay du calque | aucune |
| Cellules d’herbes hautes | 649 |
| Zones de rencontre générées | 10 |
| Cellules d’herbe couvertes | 634 |
| Cellules d’herbe non couvertes | 15 |
| Cellules couvertes plusieurs fois | 0 |

Répartition actuelle couverte :

| Table | Zones | Cellules couvertes |
| --- | ---: | ---: |
| `enc_hanazuki_route_herbes_hautes` | 2 | 202 |
| `enc_hanazuki_route_sous_bois` | 3 | 194 |
| `enc_hanazuki_route_abords_gare` | 5 | 238 |

Les 15 cellules sans rencontre sont `(23,15)` et `(9..22,16)`. Elles prolongent spatialement la zone nord ; la migration proposée les rattache donc à `enc_hanazuki_route_herbes_hautes`. Cette hypothèse doit être confirmée visuellement pendant la migration, mais elle donne une partition cohérente de 217 + 194 + 238 = 649 cellules.

## Options étudiées

### Option A — Comportement natif et résolution directe depuis les cellules

Ajouter au `SmartTileLayer` une liaison de rencontre typée facultative visant un matériau du calque. Le runtime teste la cellule sémantique sous le joueur, résout le comportement du ou des calques concernés puis applique le même contrat de rencontre.

Avantages :

- une seule source de vérité ;
- toute cellule peinte devient immédiatement jouable ;
- pas de fragmentation en rectangles ni de resynchronisation ;
- comportement visible et éditable au bon endroit dans l’éditeur ;
- plusieurs tables obtenues naturellement par plusieurs calques.

Risques :

- adaptation transversale core/gameplay/runtime/editor/authoring/MCP ;
- résolution explicite des overlaps entre calques et zones manuelles ;
- migration des projets existants nécessaire.

Verdict : **recommandée**.

### Option B — Comportement natif compilé en zones virtuelles en mémoire

Le comportement est persisté sur le calque, puis converti à la lecture en zones non persistées afin de réutiliser le resolver actuel.

Avantage : réduction du changement runtime initial.

Inconvénients : conservation d’une projection rectangulaire inutile, identité virtuelle plus complexe, risques de divergences dans les résolveurs secondaires et coût de maintenance durable.

Verdict : acceptable seulement comme détail interne transitoire dans une même livraison, jamais comme second contrat public ou persistant.

### Option C — Conserver les zones synchronisées et améliorer l’automatisation

Déclencher automatiquement `gameplay_zone.smart_tile.sync` après chaque peinture.

Avantage : changement minimal.

Inconvénients : deux sources persistées, mutations couplées, risque de panne partielle, diff JSON bruyant et UX trompeuse. Cette option ne satisfait pas la demande de porter le comportement directement dans le calque.

Verdict : rejetée.

## Architecture cible

### Contrat `map_core`

Ajouter un contrat bêta ciblé `SmartTileEncounterBehavior` porté par `SmartTileLayer` avec :

- `materialId` requis afin que le comportement cible explicitement une matière de la palette ;
- `priority` ;
- un `EncounterZonePayload` ;
- un identifiant stable de source dérivé du calque pour les diagnostics, traces et tie-breaks déterministes.

Le périmètre bêta autorise une liaison de rencontre par calque. Lorsque deux tables sont nécessaires, l’auteur crée deux calques. Ce choix évite d’inventer dans ce ticket une plateforme générique pour l’eau et la lave et reste cohérent avec la demande utilisateur. Une évolution multi-comportements pourra être conçue plus tard sur preuve d’un besoin réel.

Le comportement s’applique à une position si la cellule sémantique du calque référence exactement `materialId`. Un calque masqué ne doit jamais provoquer de rencontres invisibles : si une liaison active possède des cellules mais `isVisible = false`, la validation bloque le playtest/export avec un diagnostic explicite. La migration rend donc les trois calques visibles.

### Résolution `map_gameplay`

Créer un resolver canonique `EncounterSource` au niveau de la carte qui rassemble :

- les zones manuelles compatibles ;
- les comportements natifs des calques dont la cellule correspond à la position ;
- une politique unique de priorité, d’ambiguïté et de tie-break stable.

`checkEncounterAtPlayerPosition`, le handoff runtime, les résolveurs de fond de combat, de musique et le préchauffage doivent consommer le même résultat résolu. Aucun consommateur ne doit reconstruire sa propre interprétation. Les DTOs concernés doivent parler de `encounterSourceId`/`encounterSourceKind`, pas prétendre que toute source est une zone.

Une collision de même priorité avec payloads différents doit produire un diagnostic bloquant avant playtest/export, comme le contrat de rencontre canonique le fait déjà pour les zones.

### Authoring, éditeur et MCP

Remplacer l’usage de `gameplay_zone.smart_tile.sync` dans le parcours « Herbe haute avec rencontres » par deux mutations sémantiques :

- `smart_tile.layer.set_encounter_behavior` ;
- `smart_tile.layer.clear_encounter_behavior`.

Le détail de calque exposé par les resources authoring/MCP doit inclure le comportement courant. Les quatre transports doivent partager le même contrat : API Dart directe, JSONL/CLI, éditeur et MCP.

Dans l’éditeur, l’action devient « Comportement du calque ». L’état courant est affiché et modifiable sans vocabulaire de génération de rectangles. Le choix « Herbe haute avec rencontres » ouvre un sélecteur guidé de table, de kind, de fond et de musique ; aucun ID brut ne doit être obligatoire lorsque le catalogue permet un picker.

Après bascule canonique, retirer les presenters, plans, branches et tests consacrés uniquement à la génération/synchronisation des zones de rencontre issues des hautes herbes. `gameplay_zone.smart_tile.sync` ne doit pas être supprimé globalement dans ce ticket : l’eau surfable et la lave l’utilisent encore et sont hors périmètre. La politique pré-1.0 autorise en revanche de ne conserver aucun bridge legacy pour les rencontres d’herbe.

La resource `smartTileLayer` doit passer à une version qui expose explicitement la liaison dans son détail et son résumé. L’éditeur doit appeler les mêmes actions canoniques que JSONL/MCP ; aujourd’hui il contourne l’action authoring et appelle son `EditorNotifier` directement.

### Validation

Ajouter des diagnostics pour :

- matériau absent de la palette ;
- payload absent ou incohérent avec `kind` ;
- table de rencontres inconnue ;
- binding dupliqué ou conflit de priorité ;
- calque vide avec comportement actif ;
- coexistence interdite d’un comportement natif et d’anciennes zones portant la provenance correspondante.

Deux défauts de provenance rendent la synchronisation actuelle encore plus fragile : `hasSameBinding` ne compare que le calque et `behaviorKey`, tandis que le `behaviorKey` courant `encounter.walk` n’inclut pas la table. Deux tables `walk` sur un même calque peuvent donc se remplacer. À l’inverse, les dix zones du projet utilisent l’ancien key `encounter-walk-hanazuki-forest` ; une synchronisation courante risque de les dupliquer au lieu de les remplacer.

## Plan d’implémentation proposé

### Phase 1 — Contrat et résolution pure

1. Ajouter le modèle typé et sa sérialisation dans `map_core`.
2. Ajouter les validateurs et le resolver carte/cellule déterministe.
3. Adapter `map_gameplay` pour les rencontres et les effets liés à la position.
4. Adapter les résolveurs runtime de fond et musique de combat au résultat canonique.
5. Supprimer ou rendre inaccessibles les anciennes projections persistées pour les rencontres d’herbe.

### Phase 2 — Parité authoring complète

1. Ajouter les actions set/clear au catalogue `map_authoring`.
2. Exposer le comportement dans les resources et receipts.
3. Brancher les transports JSONL/CLI et MCP.
4. Reconstruire `tools/pokemap_mcp`, exécuter ses tests et vérifier `pokemap_describe` sur un serveur live.
5. Remplacer l’action éditeur de génération de rencontres par l’édition directe du calque, avec un picker de tables `walk` et sans ID brut.

### Phase 3 — Migration du projet de certification

1. Créer une sauvegarde exacte de `Le train de 17h42`.
2. Recharger le projet et vérifier sa révision avant mutation.
3. Scinder le calque actuel en trois calques utilisant le même preset et le même matériau.
4. Affecter les cellules aux tables : nord 217, sous-bois 194, abords de gare 238.
5. Attacher un comportement de rencontre `walk` à chaque calque.
6. Supprimer uniquement les dix zones de rencontre dotées de la provenance Smart Tile correspondante.
7. Conserver toutes les autres zones et données de la carte.
8. Rendre les trois calques visibles.
9. Recharger, valider, rendre et playtester le projet.

### Phase 4 — Suppression de l’ancien chemin de rencontre

1. Retirer « Herbe haute avec rencontres » du flux de génération de zones.
2. Supprimer uniquement le code et les tests de projection devenus sans appel pour les rencontres ; conserver le chemin actif eau/lave.
3. Mettre à jour les fixtures de rencontre vers le contrat canonique.
4. Vérifier qu’aucun parcours éditeur/API/JSONL/MCP ne produit encore de zones depuis des hautes herbes.

## Fichiers et packages probablement concernés

### Contrats et opérations

- `packages/map_core/lib/src/models/map_layer.dart`
- nouveaux modèles sous `packages/map_core/lib/src/models/`
- resolver et validateurs sous `packages/map_core/lib/src/`
- `packages/map_core/lib/map_core.dart`
- fichiers Freezed/JSON générés du périmètre exact
- retrait ciblé des branches encounter dans le générateur/synchroniseur si ces fichiers restent nécessaires aux comportements eau/lave

### Gameplay et runtime

- `packages/map_gameplay/lib/src/gameplay_encounter.dart`
- `packages/map_gameplay/lib/src/gameplay_world_state.dart`
- `packages/map_gameplay/lib/src/gameplay_step.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_background_resolver.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_music_resolver.dart`

### Authoring, éditeur et MCP

- domaine maps de `packages/map_authoring`
- resources/détails de calques Smart Tile
- `packages/map_editor/lib/src/features/smart_tiles_studio/`
- `tools/pokemap_mcp`
- catalogue d’actions authoring consommé par MCP

### Projet de certification

- `/Users/karim/Desktop/pokeMap Project/le_train_de_17h42/maps/route_hanazuki_vers_gare_hanazuki.json`
- manifeste uniquement si le contrat de schéma courant l’exige

## Critères d’acceptation du ticket

- [ ] `SmartTileLayer` persiste un comportement gameplay typé visant un matériau de sa palette.
- [ ] Une cellule peinte sur ce calque devient immédiatement éligible aux rencontres après sauvegarde/relecture, sans zone générée ni action de synchronisation.
- [ ] Effacer une cellule supprime immédiatement son éligibilité après sauvegarde/relecture.
- [ ] Une liaison active sur un calque masqué produit un diagnostic bloquant et ne peut pas créer de rencontre invisible.
- [ ] Plusieurs calques peuvent porter des tables différentes ; la priorité et les overlaps sont déterministes et diagnostiqués.
- [ ] Les zones manuelles continuent de fonctionner avec une politique de résolution partagée et documentée.
- [ ] Fond de combat, musique et table viennent du même comportement résolu.
- [ ] L’éditeur permet de créer, voir, modifier et retirer le comportement directement depuis le calque.
- [ ] Aucun workflow normal n’exige de saisir ou modifier du JSON brut.
- [ ] API directe, JSONL/CLI, éditeur et MCP produisent le même JSON canonique et les mêmes diagnostics.
- [ ] `pokemap_describe` live publie les nouvelles actions/resources ; `gameplay_zone.smart_tile.sync` reste limité aux comportements non-rencontre encore actifs.
- [ ] `Le train de 17h42` contient trois calques d’herbes avec 217, 194 et 238 cellules, soit 649 cellules au total, sans trou ni overlap.
- [ ] Les dix zones de rencontre dérivées du Smart Tile ont disparu du projet ; les autres zones sont inchangées.
- [ ] Un playtest réel déclenche des rencontres dans les 15 cellules auparavant non couvertes et conserve les trois tables attendues.
- [ ] Le DoD pertinent de `FG-108`, les parcours bêta `FG-180`/`FG-182` et la Golden Gate rencontre → capture → sauvegarde restent verts.

## Tests attendus

### `map_core`

- round-trip JSON du comportement ;
- application par matériau et position ;
- cellule vide, hors carte et calque vide ;
- validation payload/kind/table/matériau ;
- priorité et ambiguïté entre calques et zones manuelles ;
- resize de carte et conservation des comportements.

### `map_gameplay`

- rencontre sur cellule native et absence hors cellule ;
- ajout/suppression de cellule sans synchronisation ;
- seed déterministe, table, niveau et espèce inchangés ;
- cohérence des conditions et des priorités ;
- benchmark reproductible avec plusieurs calques candidats.

### `map_runtime`

- fond et musique issus de la même source résolue ;
- smoke de déclenchement de rencontre ;
- sauvegarde/reprise sans divergence.

### `map_editor`

- widget tests du sélecteur et de l’état éditable ;
- parcours peinture → comportement → sauvegarde → relecture ;
- absence de zones générées ;
- validation visuelle sur build exécutable, pas seulement golden.

### `map_authoring` et MCP

- mutations directes set/clear ;
- transport JSONL ;
- transaction, revision, receipt et idempotence ;
- test MCP ciblé ;
- typecheck/build du serveur ;
- vérification du catalogue live.

### Projet externe

- sauvegarde exacte et diff borné ;
- décodage avec le schéma courant ;
- open/validate/render/close via le flux authoring canonique ;
- inspection des 649 cellules et zéro zone Smart Tile dérivée ;
- identité visuelle du plan résolu avant/après sur les 649 cellules ;
- assertions ciblées : `(9,8)`, `(9,16)` et `(23,15)` → table nord ; `(6,24)` → sous-bois ; `(22,51)` → abords gare ;
- playtest manuel des trois régions et des anciennes 15 cellules orphelines.

## Risques et garde-fous

- **Overlap entre sources** : centraliser la résolution, interdire les tie-breaks improvisés par consommateur.
- **Coût par pas** : indexer les comportements actifs par calque/cellule et conserver un benchmark borné.
- **Visibilité confondue avec gameplay** : diagnostic bloquant explicite pour un comportement actif sur `isVisible = false`.
- **Migration destructrice** : sauvegarde exacte, suppression ciblée par provenance, relecture avant/après.
- **Double contrat transitoire** : migration atomique au schéma courant ; pas de fallback pré-1.0.
- **Parité incomplète** : aucun verdict `DONE` si l’un des transports ou le catalogue live manque.
- **Validation purement statique** : le ticket reste `TO REVIEW` jusqu’à la validation manuelle de Yoahn sur l’exécutable.

## Passes d’audit

### Audit / Architecture

Verdict : la cause racine est confirmée. Le modèle du calque ne porte aucun comportement ; le générateur fabrique des rectangles persistés ; le runtime lit exclusivement ces rectangles. L’option native résolue par cellule est la seule qui supprime la double vérité.

### Design d’implémentation

Verdict : `SmartTileEncounterBehavior` typé dans `map_core`, résolution pure `EncounterSource`, adaptation ciblée des consommateurs, puis remplacement du seul parcours d’herbe. Une liaison par calque est suffisante pour la bêta et évite d’embarquer eau/lave dans le lot.

### Tests et migration

Verdict : les tests actuels couvrent très bien la génération/synchronisation, mais doivent être remplacés par des preuves de comportement natif et de non-régression du contrat encounter. `packages/map_gameplay/test/smart_tile_generated_gameplay_zone_bridge_test.dart` affirme même explicitement que le `SmartTileLayer` seul reste visuel : ce test devra être inversé. Le projet réel fournit une certification chiffrée forte : 649 cellules et trois tables.

### Build / Validation

Audit sans implémentation : aucun build de livraison ni test de nouveau comportement ne peut être déclaré vert. Une baseline fraîche de l’ancien comportement a néanmoins été exécutée : 59 tests `map_core`, 15 tests `map_gameplay` et 30 tests `map_editor` ont passé sur les fichiers ciblés. Cette baseline prouve le point de départ, pas l’existence de la cible.

### Critique finale

Le point de vigilance principal est la tentation de conserver une génération de zones de rencontre « juste en interne » trop longtemps. Une projection transitoire en mémoire peut aider à livrer par étapes, mais si elle devient un contrat public ou persistant, le problème est seulement déplacé. Le ticket doit se fermer avec une seule source de vérité enregistrée pour les rencontres d’herbe : le calque. Il ne faut pas généraliser ce lot à Surf/lave, ni oublier les consommateurs secondaires (fond, musique, préchauffage, export).

## Commandes d’audit exécutées

- `git status --short --untracked-files=all`
- `git rev-parse --abbrev-ref HEAD`
- `git rev-parse HEAD`
- recherches `rg -n` ciblées sur les modèles, resolvers, actions authoring, UI et tests Smart Tile/encounter
- lecture ciblée avec numéros de lignes des contrats et générateurs
- analyse Python en lecture seule de la carte `route_hanazuki_vers_gare_hanazuki.json`
- requête Notion en lecture seule des tickets `BETA-ENC-*`
- `cd packages/map_core && dart test test/smart_tile_gameplay_zone_synchronization_test.dart test/smart_tile_to_gameplay_zone_generation_assessment_test.dart test/beta_playability_validator_test.dart` — 59 tests passés
- `cd packages/map_gameplay && dart test test/smart_tile_generated_gameplay_zone_bridge_test.dart test/encounter_resolution_contract_test.dart` — 15 tests passés
- `cd packages/map_editor && flutter test test/smart_tiles_studio/smart_tile_to_gameplay_zone_action_test.dart` — 30 tests passés
- nettoyage obligatoire des harness Flutter après la suite ciblée

Résultats exacts structurants :

- `BETA-ENC-001` à `BETA-ENC-006` existent déjà et sont `DONE` ; le prochain identifiant disponible est `BETA-ENC-007` ;
- la carte contient 649 cellules d’herbe, 634 couvertes, 15 non couvertes, zéro overlap ;
- le runtime courant reçoit uniquement `world.map.gameplayZones` ;
- l’action authoring courante est `gameplay_zone.smart_tile.sync` ;
- aucun nouveau comportement n’a été implémenté ou testé pendant cet audit ; seuls les contrats existants ont été certifiés comme baseline.

## État Git final

Branche `main`, SHA `2c18210c2a4413bc8a881252cc098dfaeefbf605`.

```text
 M packages/map_authoring/lib/src/domains/assets/element_actions.dart
 M packages/map_authoring/lib/src/domains/assets/tileset_actions.dart
 M packages/map_authoring/lib/src/domains/assets/visual_organization_actions.dart
 M packages/map_authoring/lib/src/parity/full_authoring_parity.dart
 M packages/map_authoring/test/domains/assets/visual_library_contract_test.dart
 M packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart
 M packages/map_editor/test/map_palette_asset_browser_test.dart
 M packages/map_editor/test/ui_panels_smoke_test.dart
 M tools/pokemap_mcp/test/mutation_server.test.ts
?? apps/pokemap_hub/reports/cin038/probe.json
?? apps/pokemap_hub/reports/cin084/measurements.json
?? documentation/reports/gameplay/beta_enc_007_smart_tile_native_gameplay_behavior_audit_2026-08-23.md
```

Seul le dernier fichier appartient à cet audit. Toutes les autres entrées sont des travaux concurrents préexistants et sont restées intactes.

## Recommandation de gouvernance

Créer `BETA-ENC-007` dans l’unique grand domaine existant `6. Rencontres et capture`, avec `Gate bêta = true`, `Statut = TODO`, `Priorité = P0`, `Rang d’exécution = Must`, `Effort = L` et `Readiness = Prêt réel`.

Cette création constitue l’exception explicite demandée par Yoahn à la règle de backlog bêta gelé. Elle ne modifie ni la structure des familles, ni le graphe des tickets déjà signés, ni leur statut.

Ticket créé et relu : [BETA-ENC-007 — Porter les rencontres directement sur les calques Smart Tile](https://app.notion.com/p/3c5197a7bfa58123afc6e2cfc1cd8753).
