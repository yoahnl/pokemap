# SEL-FIN — Evidence Pack de clôture du démonstrateur Selbrume

> Date de clôture : 2026-07-18
> Branche auditée : `main`
> Commit de référence : `f93b70ad12a1930e332bef6c4eebcc10026690dc`
> Périmètre : `SEL-FIN-00` à `SEL-FIN-09`
> Roadmap associée : `FG-080`, `FG-081`, `FG-082`, `FG-092`, `FG-093`, `FG-180` à `FG-185`

## 1. Verdict exécutif

| Porte | Verdict | Justification vérifiable |
|---|---:|---|
| Gate fonctionnelle du démonstrateur **Selbrume** | **PASS / GO** | Suites Core, Gameplay, Battle, Runtime, Editor et Host vertes ; analyses package-scoped vertes ; build Release arm64 vérifié ; revue finale GO. |
| Validité narrative de `selbrume/project.json` | **PASS** | Le validateur Selbrume produit `0` erreur bloquante. Les avertissements observés sont informatifs et sont détaillés plus bas. |
| Parcours joueur canonique | **PASS ciblé** | Le test E2E Host parcourt le New Game, le starter, le port, Lysa victoire/défaite, le marais, Soline, les deux branches Goélise, la cabane, les gardiens, le boss statique, la disparition de la brume et l'épilogue, avec sauvegardes/rechargements intermédiaires. |
| QA desktop du Narrative Studio | **PASS ciblé** | Les routes Scenes, Event Builder, Validator et New Game ont été ouvertes sur une copie jetable du projet ; le compteur Scenes a été corrigé puis revérifié à `31`. |
| Suite complète `map_runtime` | **PASS** | Résultat frais communiqué : `+1827 ~1`, code de sortie `0`; `flutter analyze` : `No issues found! (5.7s)`. |
| Suite complète `map_editor` | **PASS après triage** | Relevé initial : `04:38 +3359 -40`; second : `+3384 -17`; finale : `03:31 +3403: All tests passed!`, exit `0`. |
| Suite complète `playable_runtime_host` | **PASS final** | Premier relevé : `03:05 +63 -3`; intermédiaire : `03:03 +66`; transitoire post-FIFO : `01:33 +65 -1`; final de capture : `03:04 +66: All tests passed!`, exit `0`. Le transitoire n'a pas été reproduit. |
| Build macOS `map_editor` | **PASS arm64** | `FLUTTER_XCODE_ARCHS=arm64 flutter build macos --release`, exit `0`, `map_editor.app (37.4MB)` ; Mach-O/lipo arm64 vérifiés. La tentative universelle par défaut reste limitée par Flutter beta + Xcode 27. |
| `FG-185 — MVP Release Gate V0` global | **PARTIAL** | La gate Selbrume ne suffit pas à clôturer la gate globale du moteur : les critères génériques multi-projets, la totalité des paquets critiques et la validation utilisateur finale restent distincts. |

**Verdict final : GO pour le démonstrateur Selbrume.** Ce GO est borné au démonstrateur et à un build macOS Release arm64. Il ne transforme pas `FG-185` global en `DONE` et ne masque pas la limitation externe du build universel.

## 2. Nom exact et objectif du lot

**Nom exact :** `SEL-FIN — Clôture fonctionnelle, éditoriale et QA du démonstrateur Selbrume`.

L'objectif n'est pas de déclarer que tout PokeMap est terminé. Il est de prouver jusqu'où le moteur actuel peut réellement produire et jouer le démonstrateur décrit dans `MVP Selbrume/selbrume.md`, en s'appuyant sur le workflow no-code décrit dans `MVP Selbrume/narrative_studio.md`.

Le lot couvre :

- le démarrage d'une nouvelle partie configuré par projet ;
- le choix exact d'un starter et sa persistance ;
- les sorties Yarn déclarées et consommées par les Scenes ;
- les conséquences narratives réellement écrites dans le world state ;
- la projection des Facts et World Rules sur la carte ;
- la lecture ordonnée des cinématiques V1 ;
- le contenu narratif canonique de Selbrume ;
- un validateur no-code fail-closed ;
- un parcours E2E avec sauvegarde/rechargement ;
- une QA desktop et une gate de release honnête.

## 3. Audit initial obligatoire

### 3.1 Sources et contrats lus avant implémentation

| Source | Rôle dans l'audit |
|---|---|
| `AGENTS.md` | Frontières de packages, règles Git, design system, validation et exigences de rapport. |
| `codex_rule.md` | Audit, sous-agents, preuves, build, critique finale et annexes obligatoires. |
| `pokemap_roadmap_mecaniques_fangame.md` | Lots `FG-*`, critères de done et distinction entre readiness du démonstrateur et release globale. |
| `MVP Selbrume/selbrume.md` | Source de vérité du scénario, des personnages, embranchements, combats et épilogue. |
| `MVP Selbrume/narrative_studio.md` | Workflow d'authoring attendu dans le Narrative Studio. |
| `reports/gameplay/fg_000_narrative_studio_selbrume_capability_matrix.md` | Matrice initiale « supporté / partiel / absent ». |
| `reports/gameplay/fg_000_narrative_studio_selbrume_readiness_audit.md` | Audit initial détaillé des capacités et trous bloquants. |

### 3.2 État fonctionnel trouvé

L'audit a confirmé qu'une part importante des briques existait déjà, mais que l'enchaînement démonstrateur n'était pas prouvé de bout en bout. Les principaux trous étaient :

1. absence d'un contrat projet complet pour le New Game et les starters ;
2. sorties Yarn insuffisamment déclarées/propagées jusqu'aux ports de Scene ;
3. conséquences de Scene trop limitées pour exprimer toutes les transitions Selbrume ;
4. cinématiques décrites mais non jouées comme une timeline V1 réellement ordonnée ;
5. contenu Selbrume partiel ou encore relié à des fixtures historiques ;
6. absence d'une validation globale de reachability et de catalogues runtime ;
7. absence d'un E2E couvrant le parcours, les branches et les reloads ;
8. absence d'une gate desktop finale avec preuves visuelles.

### 3.3 Contrats d'architecture préservés

| Package | Responsabilité préservée |
|---|---|
| `map_core` | Modèles JSON, conséquences, diagnostics et validation narrative pure Dart. |
| `map_gameplay` | Construction du state de nouvelle partie, résolution du spawn et projection pure du world state. |
| `map_battle` | État et setup de combat ; aucune dépendance Flutter ajoutée. |
| `map_runtime` | Exécution des Scenes, dialogues, combats, cinématiques et projection Flame. |
| `map_editor` | Authoring no-code, catalogues, pickers et validation ; aucune logique runtime cachée dans l'UI. |
| `playable_runtime_host` | Chargement du projet réel, sauvegarde/rechargement et preuve E2E intégrée. |

### 3.4 Risques identifiés avant changement

- worktree déjà très sale, contenant notamment le chantier UI Narrative Studio ;
- possibilité d'attribuer à tort des modifications préexistantes aux lots SEL-FIN ;
- schéma `ProjectManifest` généré, donc risque de désynchronisation Freezed/JSON ;
- simulateur de reachability susceptible de mentir si les catalogues manquent ;
- branchements Yarn susceptibles d'être acceptés par l'éditeur mais ignorés au runtime ;
- cinématiques susceptibles de n'être que des délais sans effet visuel ;
- tests historiques susceptibles de coder d'anciennes maps ou restrictions de routes ;
- save legacy susceptible de perdre les HP courants ou de démarrer sur une mauvaise map.

## 4. État Git initial

Le travail a été réalisé directement dans le workspace principal, conformément à la demande explicite de ne pas créer de worktree dédié.

| Mesure initiale | Valeur |
|---|---|
| Branche | `main` |
| HEAD | `f93b70ad12a1930e332bef6c4eebcc10026690dc` |
| `git status --short --untracked-files=all` | `204` entrées : `63 M`, `3 D`, `138 ??` |
| SHA-256 du snapshot porcelain initial | `c85a6a1960d6090b9982ebc48bf709c75596ae20f9e7a6b49cf7ce1e651fc2ae` |
| Snapshot au démarrage du plan d'implémentation | `70 M`, `3 D`, au moins `149 ??` ; capture de la liste non exhaustive |

Cette baseline était **déjà sale**. En conséquence :

- le diff global n'est pas une mesure fiable du seul effort SEL-FIN ;
- les fichiers UI convergence et leurs goldens/failures ne sont pas revendiqués comme créations SEL-FIN ;
- aucun reset, stash, commit ou push n'a été effectué ; un cleanup final strictement borné a supprimé `80` PNG de diagnostics golden temporaires non suivis, après audit et sans toucher aux références ni aux preuves ;
- l'inventaire de la section 8 distingue les changements fonctionnels SEL-FIN du bruit préexistant.

## 5. Découpage et état des lots

| Lot | Objet | Preuve principale | État de clôture |
|---|---|---|---:|
| `SEL-FIN-00` | Promouvoir la fixture Event V2 vers le projet canonique et fermer le cycle Lysa minimal | Tests Host/runtime sur `selbrume/` réel | `DONE` |
| `SEL-FIN-01` | New Game par projet, spawn, inventaire, Facts et trois starters exacts | Modèle JSON, formulaire no-code, boot runtime et tests d'intégration | `DONE` |
| `SEL-FIN-02` | Sorties Yarn déclarées et routées vers les ports de Scene | Codec/editor/runtime + branches Lysa/Goélise | `DONE` |
| `SEL-FIN-03` | Conséquences de Scene et catalogues no-code | Modèle, authoring, writer runtime et tests positifs/négatifs | `DONE` |
| `SEL-FIN-04` | World State visible sur la map | Facts/World Rules, présence PNJ et couches conditionnelles | `DONE` |
| `SEL-FIN-05` | Cinématiques V1 ordonnées et restaurables | Controller pur + sink Flame + intégrations | `DONE` |
| `SEL-FIN-06` | Campagne canonique Selbrume | 31 Scenes, 29 Events, 16 cinématiques, 22 dialogues, 4 storylines | `DONE` |
| `SEL-FIN-07` | Validator no-code et reachability fail-closed | 27 tests core, providers/editor, route Validator, `0` erreur Selbrume | `DONE` |
| `SEL-FIN-08` | Golden journey E2E et save/reload | 5 tests Host incluant parcours principal et branches | `DONE` |
| `SEL-FIN-09` | QA desktop, non-régressions et release gate | Captures, suites complètes, build et revue finale | `DONE` |

Les dix lots SEL-FIN sont clôturés par les gates fraîches de ce rapport. Aucun statut du fichier roadmap global n'est modifié automatiquement : `FG-185` reste explicitement `PARTIAL`.

## 6. Résultat fonctionnel obtenu

### 6.1 Configuration canonique de nouvelle partie

Le projet canonique déclare :

| Champ | Valeur |
|---|---|
| New Game | activé |
| Map de départ | Bourg de Selbrume |
| Spawn | `spawn` |
| Nom joueur initial | `Joueur` |
| Argent | `500` |
| Sac | `3` Potions |
| Équipe avant choix | vide |
| Scene de choix | `scene_mael_intro` |
| Starters | Bulbizarre, Salamèche, Carapuce — niveau `16` |

Les trois options transportent leurs espèces, niveau, genre, talent, PV courants et moves initiaux. Le runtime privilégie la map configurée par `newGame`, sauf lorsqu'une sauvegarde valide impose explicitement sa propre map de reprise.

### 6.2 Campagne narrative canonique

Snapshot vérifié du contenu :

| Entité | Quantité |
|---|---:|
| Maps | 10 |
| Dialogues Yarn | 22 |
| Scenarios | 3 |
| Cinématiques | 16 |
| Facts | 49 |
| World Rules | 34 |
| Scenes | 31 |
| Storylines | 4 |
| Chapitres | 7 |
| Étapes | 26 |
| Liens étape → Scene | 39 |
| Trainers | 5 |
| Characters | 9 |
| Encounter tables | 1 |
| Events V2 | 29 |

Le graphe de Scenes contient `210` nodes et `196` edges. Les conséquences déclarées couvrent notamment `completeStoryStep`, `giveConfiguredStarter`, `giveItem`, `giveMoney` et `setFact`. Les événements couvrent les interactions d'entité, entrées de zone et réceptions d'outcomes.

### 6.3 Branches et conséquences réellement couvertes

- choix du starter et ajout exact à l'équipe ;
- ouverture puis fermeture du Port des Brisants ;
- Lysa : victoire et défaite, avec outcomes réels de combat ;
- indices et cristaux du Marais salants ;
- rencontre de Soline et passage des Dames ;
- Goélise : rendre l'objet ou le garder, avec conséquences distinctes ;
- récupération de la clé et lecture du journal dans la cabane ;
- progression des gardiens ;
- combat statique du boss au phare ;
- disparition de la brume projetée par le world state ;
- épilogue au port.

### 6.4 Cinématiques V1

Les `16` cinématiques totalisent `68` étapes de timeline :

| Kind | Nombre |
|---|---:|
| `actorEmote` | 5 |
| `actorFace` | 1 |
| `actorMove` | 3 |
| `camera` | 11 |
| `fade` | 28 |
| `shake` | 4 |
| `wait` | 16 |

Le controller préflight la timeline, exécute les étapes dans l'ordre, gère l'annulation et restaure l'état visuel. Le sink Flame applique les effets caméra, acteur, emote, dialogue, fade et shake au lieu de simuler leur réussite par un simple délai.

### 6.5 Validator fail-closed

Le validateur vérifie notamment :

- références New Game, map et spawn ;
- catalogues de maps, trainers, teams et assets de Scene ;
- ports/outcomes déclarés et consommateurs ;
- reachability des Facts et étapes, y compris ordre legacy des pages ;
- cycles, auto-déverrouillage et producteurs inatteignables ;
- sources d'événements orphelines ;
- début/fin des storylines ;
- borne de recherche à `4096` états avec échec conservateur si la preuve dépasse la borne.

Les catalogues manquants ne sont pas traités comme des catalogues vides valides : la validation échoue de manière explicite. Les adversaires uniquement référencés par une Scene sont inclus dans les catalogues nécessaires.

## 7. Verdicts des sous-agents et passes obligatoires

| Passe | Mission | Verdict |
|---|---|---|
| Audit / Architecture | Comparer specs, roadmap, rapports et contrats réels | **PASS** — périmètre découpé en 10 lots, frontières de packages préservées, baseline sale identifiée. |
| Implémentation | Fermer `SEL-FIN-00` à `SEL-FIN-08` par petits contrats testables | **PASS ciblé** — lots livrés comme candidats `DONE`, sans changement Git destructif. |
| Tests | Vérifier les contrats core/editor/runtime/host et trier les régressions | **PASS** — Core `+3058`, Gameplay `+288`, Battle `+1722`, Runtime `+1827 ~1`, Editor `+3403`, Host `+66`. |
| Build / Validation | Analyzers, suites complètes, build desktop et preuves visuelles | **PASS arm64** — analyses Runtime/Host/Editor vertes et build Release arm64 vérifié. |
| Critique finale | Chercher effets de bord, assertions affaiblies, faux supports et scope mélangé | **GO** — Critical `0`, Important `0`, Minor non bloquants `2`, aucun finding de release restant. |
| Triage contrats runtime | Reproduire et classifier les 21 échecs runtime intermédiaires | **PASS** — attentes historiques obsolètes, pas de régression produit ; ciblé réconcilié `+84 ~1`. |
| Desktop QA | Ouvrir les routes réelles et comparer visuellement | **PASS ciblé** — 10 captures, bug compteur Scenes corrigé et revérifié. |

La critique finale a explicitement vérifié : priorité de map sauvegarde/New Game, starter exact, `currentHp` et migration legacy, solver borné/fail-closed, validation de `startSpawnId`, catalogues Scene-only, absence d'import Marionette en production et non-affaiblissement des assertions runtime.

## 8. Inventaire des fichiers SEL-FIN

### 8.1 Règle d'attribution

Le workspace contenait déjà des modifications Narrative Studio/UI avant SEL-FIN. Le tableau suivant ne revendique que les fichiers utilisés ou changés pour les contrats fonctionnels Selbrume. Les dossiers `test/failures`, assets sources V2 et anciens rapports UI restent hors attribution, même s'ils apparaissent dans le `git status` global. L'unique exception UI est le groupe explicitement borné de `20` références visuelles rafraîchies pendant la gate Editor et inventoriées en sections 8.8 et 11.2.

> **Inventaire figé :** les lignes ci-dessous constituent l'inventaire fonctionnel SEL-FIN consolidé avec les sous-agents. Les autres changements du dirty worktree ne sont pas attribués à ces lots.

### 8.2 Host jouable

| Fichier | Zone modifiée/créée | Raison | Impact |
|---|---|---|---|
| `examples/playable_runtime_host/lib/main.dart` | bootstrap projet, map de lancement, état New Game/save | Consommer la configuration du projet réel | Le host démarre/reprend sur la bonne map avec le bon state. |
| `examples/playable_runtime_host/lib/src/runtime_launch_save.dart` | DTO save, `currentHp`, migration legacy | Préserver l'état exact de l'équipe | Les reloads ne régénèrent pas arbitrairement les PV. |
| `examples/playable_runtime_host/lib/src/runtime_project_launch_map.dart` | `resolveRuntimeProjectLaunchMap` | Centraliser la priorité save/New Game/fallback | Résolution déterministe et testable de la map. |
| `examples/playable_runtime_host/test/runtime_launch_save_test.dart` | round trips et legacy | Prouver la compatibilité save | Cas positif, migration et garde-fous. |
| `examples/playable_runtime_host/test/runtime_project_launch_map_test.dart` | matrice de priorité des maps | Prouver la résolution | Empêche un retour accidentel à la première map. |
| `examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart` | slice Lysa sur `selbrume/` | Promouvoir la fixture vers le canon | Le projet réel devient la source de preuve. |
| `examples/playable_runtime_host/test/selbrume_event_v2_lysa_golden_slice_test.dart` | harness canonique et consommation FIFO | Ajouter la précondition Port et prouver l'ordre des outcomes | Les branches Lysa ne passent pas grâce à une outbox résiduelle. |
| `examples/playable_runtime_host/test/selbrume_canonical_narrative_campaign_test.dart` | contrats de campagne | Vérifier le contenu canonique | Détecte les liens/scènes/outcomes manquants. |
| `examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` | 5 parcours E2E | Prouver branches et reloads | Gate joueur principale du démonstrateur. |

### 8.3 Core et Gameplay

| Fichier | Zone modifiée/créée | Raison | Impact |
|---|---|---|---|
| `packages/map_core/lib/map_core.dart` | exports publics | Exposer New Game et validator | API disponible aux packages consommateurs. |
| `packages/map_core/lib/src/models/project_manifest.dart` | champ `newGame` | Porter le contrat dans le manifest | Configuration sérialisée par projet. |
| `packages/map_core/lib/src/models/project_manifest.freezed.dart` | code généré `newGame` | Synchroniser Freezed | Copies/égalité conformes au modèle. |
| `packages/map_core/lib/src/models/project_manifest.g.dart` | code généré JSON | Synchroniser la sérialisation | Round trip JSON complet. |
| `packages/map_core/lib/src/models/project_new_game_config.dart` | `ProjectNewGameConfig`, `ProjectStarterOption` | Modéliser le démarrage no-code | Contrat pur Dart, defaults legacy et validation. |
| `packages/map_core/lib/src/models/scene_consequence.dart` | kinds et payloads de conséquence | Exprimer les transitions Selbrume | Les Scenes écrivent Facts, étapes, objets, argent et starter. |
| `packages/map_core/lib/src/authoring/scene_authoring_operations.dart` | création/mise à jour des conséquences | Authoring sûr | L'éditeur ne fabrique pas de payload incohérent. |
| `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart` | diagnostics des conséquences et ports | Détecter les références invalides | Erreurs visibles avant runtime. |
| `packages/map_core/lib/src/diagnostics/world_rule_diagnostics.dart` | analyse Facts/Rules | Prouver les projections | Réduit les règles mortes ou impossibles. |
| `packages/map_core/lib/src/operations/narrative_project_validator.dart` | rapport, map-event view, solver reachability | Validation globale fail-closed | Gate no-code du projet réel. |
| `packages/map_core/lib/src/runtime/scene_runtime_executor.dart` | propagation outcome/dialogue | Relier Yarn aux edges | Les branches choisies au dialogue pilotent la Scene. |
| `packages/map_core/lib/src/read_models/golden_slice_readiness.dart` | compteurs/contrats readiness | Refléter les nouvelles sources | Readiness cohérente avec le canon. |
| `packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart` | catalogues Scene-only | Ne pas perdre les adversaires indirects | Validator/runtime voient tous les IDs réellement utilisés. |
| `packages/map_core/lib/src/validation/beta_playability_validator.dart` | délégation/diagnostics narrative | Intégrer la gate | Les erreurs narratives rejoignent la validation projet. |
| `packages/map_core/lib/src/validation/validators.dart` | validation New Game | Refuser map/spawn/starter invalides | Le manifest invalide échoue avant le jeu. |
| `packages/map_gameplay/lib/map_gameplay.dart` | exports publics | Exposer builders/resolvers | API consommable par runtime/host. |
| `packages/map_gameplay/lib/src/new_game_state_builder.dart` | construction d'état initial | Appliquer sac, argent, Facts, équipe vide | New Game déterministe. |
| `packages/map_gameplay/lib/src/player_spawn_resolver.dart` | spawn configuré | Résoudre `startSpawnId` | Position de départ conforme au projet. |
| `packages/map_gameplay/lib/src/gameplay_world_state.dart` | projection présence/règles | Réagir aux Facts | PNJ et couches reflètent la progression. |

### 8.4 Editor no-code

| Fichier | Zone modifiée/créée | Raison | Impact |
|---|---|---|---|
| `packages/map_editor/lib/src/features/narrative/state/narrative_validator_providers.dart` | snapshots et rafraîchissement de catalogues | Alimenter le validator avec les vraies ressources | Gate rafraîchissable et fail-closed. |
| `packages/map_editor/lib/src/features/narrative/state/new_game_authoring_catalog_provider.dart` | maps/spawns disponibles | Fournir des pickers | Aucun ID manuel nécessaire au flux normal. |
| `packages/map_editor/lib/src/features/narrative/state/scene_consequence_catalog_providers.dart` | facts/steps/items/dialogues/combats | Alimenter l'inspecteur de Scene | Conséquences guidées par catalogues. |
| `packages/map_editor/lib/src/ui/canvas/narrative_validator_workspace.dart` | onglets diagnostics/events, filtres, navigation | Rendre la validation actionnable | L'auteur peut localiser et corriger les problèmes. |
| `packages/map_editor/lib/src/ui/canvas/new_game/project_new_game_configuration_sheet.dart` | formulaire New Game et cartes starters | Authoring sans JSON | Configuration accessible dans le Narrative Studio. |
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | routes Validator/New Game | Brancher les nouveaux workspaces | Navigation produit cohérente. |
| `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart` | catalogues/authoring de conséquences | Éditer les réactions de Scene | Workflow Selbrume no-code. |
| `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart` | affichage/édition payloads | Représenter les nouveaux kinds | Pas de perte silencieuse des valeurs. |
| `packages/map_editor/lib/src/features/dialogue/application/dialogue_yarn_codec.dart` | métadonnées d'outcomes | Déclarer les sorties Yarn | Ports de Scene vérifiables. |
| `packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_validation.dart` | validation outcomes | Détecter doublons/IDs invalides | Erreurs d'authoring visibles. |
| `packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_model.dart` | état des outcomes | Éditer les déclarations | Round trip editor complet. |
| `packages/map_editor/lib/src/features/dialogue/application/dialogue_preview_runner.dart` | preview des sorties | Tester un branchement | Prévisualisation sans runtime complet. |
| `packages/map_editor/lib/src/application/use_cases/project_dialogue_use_cases.dart` | persistance dialogue | Sauvegarder les déclarations | Écriture atomique avec le projet. |
| `packages/map_editor/lib/src/features/editor/application/project_content_controller.dart` | refresh/écriture des ressources | Maintenir les catalogues à jour | Validator et pickers reflètent le disque. |
| `packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart` | KPI Scenes | Corriger `0` vers `project.scenes.length` | Overview affiche `31` Scenes. |
| `packages/map_editor/tool/seed_selbrume_canonical_narrative_content.dart` | seed idempotent du canon | Rejouer/valider le contenu | Campagne reproductible sans édition JSON manuelle. |
| `packages/map_editor/dev/marionette_main.dart` | entrypoint debug-only | QA desktop automatisable | Aucun import dans le binaire production. |
| `packages/map_editor/lib/src/debug/marionette_project_bootstrap.dart` | bootstrap copie jetable | Ouvrir un projet QA sans toucher l'utilisateur | Preuves reproductibles et isolées. |
| `packages/map_editor/pubspec.yaml` | dev dependencies Marionette | Activer le harness debug | Dépendance limitée au développement. |
| `packages/map_editor/pubspec.lock` | résolution des dev dependencies | Figer la QA | Build/test reproductibles. |

### 8.5 Runtime et combat

| Fichier | Zone modifiée/créée | Raison | Impact |
|---|---|---|---|
| `packages/map_runtime/lib/map_runtime.dart` | exports publics | Exposer les nouveaux contrôleurs | API runtime cohérente. |
| `packages/map_runtime/lib/src/application/dialogue_runtime_models.dart` | outcome sélectionné | Porter la sortie Yarn | Scene reçoit la branche réelle. |
| `packages/map_runtime/lib/src/application/parse_yarn_dialogue.dart` | parsing des déclarations | Lire les outcomes | Contrat editor/runtime aligné. |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_dialogue_runtime_awaitable_adapter.dart` | résultat awaitable | Attendre la sélection | Pas de continuation prématurée. |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_dialogue_runtime_awaitable_result.dart` | outcome terminal | Représenter succès/annulation | Branches déterministes. |
| `packages/map_runtime/lib/src/application/scene_runtime/cinematic_runtime_playback_controller.dart` | timeline ordonnée | Exécuter la cinématique V1 | Préflight, annulation et restauration. |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_result.dart` | résultat cinématique | Propager fin/échec | Scene attend le vrai playback. |
| `packages/map_runtime/lib/src/presentation/flame/flame_cinematic_runtime_playback_sink.dart` | effets Flame | Appliquer caméra/acteurs/fade/shake | Cinématique visible et restaurable. |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart` | handlers de conséquences | Écrire le world state | Récompenses/progression réellement consommées. |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_write_result.dart` | statut d'écriture | Ne pas masquer les refus | Erreurs de conséquence explicites. |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | boot, scenes, outcomes, world state, boss | Intégrer les contrats | Parcours jouable par les hooks production. |
| `packages/map_runtime/lib/src/application/battle_start_request.dart` | combat statique | Démarrer un boss sans trainer map | Boss du phare réellement jouable. |
| `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart` | mapping request → setup | Porter l'équipe/statique | Battle reçoit les données exactes. |
| `packages/map_runtime/lib/src/application/runtime_psdk_battle_setup_mapper.dart` | mapping SDK | Conserver moves/HP/genre | Combat cohérent avec le starter et le boss. |
| `packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart` | résultat session | Propager victoire/défaite | Outcome Scene fidèle au combat. |
| `packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart` | soin sur PV courants | Préserver l'état exact | Sac et save partagent le même modèle de PV. |
| `packages/map_battle/lib/src/battle_setup.dart` | setup/HP initiaux | Accepter l'état runtime exact | Pas de régénération implicite. |
| `packages/map_battle/lib/src/battle_session.dart` | session et état courant | Préserver les PV | Résultat sauvegardable après combat. |

### 8.6 Contenu `selbrume/`

| Fichier(s) | Zone modifiée/créée | Raison | Impact |
|---|---|---|---|
| `selbrume/project.json` | New Game, storylines, steps, scenes, events, cinematics, facts/rules, trainers/characters | Porter la campagne canonique | Source de vérité jouée et validée. |
| `selbrume/maps/map_bourg_selbrume.json` | spawn, placements et transitions | Départ canonique | New Game et progression initiale. |
| `selbrume/maps/map_port_brisants.json` | sources/port/Goélise/Lysa | Branches du port | Slice Lysa et choix Goélise. |
| `selbrume/maps/map_marais_salants.json` | indices/cristaux/Soline | Progression marais | Boucle d'enquête jouable. |
| `selbrume/maps/map_passage_dames.json` | passage et règles | Accès conditionnel | World State visible. |
| `selbrume/maps/map_bois_chaise_brume.json` | navigation et gardiens | Progression intermédiaire | Route vers le phare. |
| `selbrume/maps/map_cabane_gardien.json` | clé/journal | Étape cabane | Préconditions du phare. |
| `selbrume/maps/map_phare_exterieur.json` | progression gardiens | Approche du boss | Enchaînement canonique. |
| `selbrume/maps/map_phare_interieur.json` | montée du phare | Transition | Accès au sommet. |
| `selbrume/maps/map_sommet_phare.json` | boss statique | Climax | Combat final et brume. |
| `selbrume/dialogues/*.yarn` (22 fichiers) | titres, lignes et outcomes déclarés | Couvrir toutes les conversations et variantes | Les ports Yarn/Scene et l'épilogue sont jouables. |

### 8.7 Tests et preuves ajoutés/modifiés

L'inventaire détaillé des tests se trouve en section 9. Les captures binaires sont inventoriées avec dimensions et SHA-256 en section 11. Le contenu intégral des fichiers texte créés est prévu dans l'annexe B, conformément à `codex_rule.md`.

### 8.8 Corrections déclenchées par la revue finale

Le reviewer et son agent de triage ont travaillé en lecture seule. Ils n'ont effectué aucune écriture fichier ni opération Git. Les corrections suivantes ont été appliquées par le parent ou les agents d'implémentation après reproduction de leurs constats :

| Fichier | Zone corrigée | Raison | Impact |
|---|---|---|---|
| `packages/map_runtime/test/selbrume_map_catalog_integrity_test.dart` | attentes de catalogue Selbrume | Aligner le contrat sur le canon promu | Vérifie les ressources réelles, pas l'ancienne fixture. |
| `packages/map_runtime/test/selbrume_map_navigation_contract_test.dart` | routes/locks canoniques | Intégrer les nouvelles gates de progression | Navigation testée selon le scénario final. |
| `packages/map_runtime/test/selbrume_asset_integrity_contract_test.dart` | proxy nid de Goélise | Remplacer l'ancien asset attendu | Contrat d'asset strict sur `goelise_nest_proxy`. |
| `packages/map_runtime/test/selbrume_map_render_smoke_test.dart` | scène rendue | Aligner le smoke sur les maps canoniques | Le rendu prouve le contenu promu. |
| `packages/map_runtime/test/support/selbrume_map_test_fixture.dart` | helpers/catalogues | Partager les nouvelles attentes | Les tests ne divergent pas entre eux. |
| `packages/map_editor/tool/generate_selbrume_canonical_maps.dart` | générateur du proxy Goélise | Corriger un vrai drift générateur ↔ canon | `validate-authored` redevient strictement vert. |
| `packages/map_editor/test/selbrume_project_roundtrip_test.dart` | attente proxy/round trip | Prouver la sortie du générateur corrigé | Le canon reste stable après round trip. |
| `packages/map_editor/test/scene_cinematic_picker_test.dart` | timers/pump de cinématique | Attendre la vraie timeline | Cinq tests fonctionnels redeviennent déterministes. |
| `packages/map_editor/test/facts_world_rules_manager_test.dart` | golden/attentes Facts | Refléter le workspace convergé | Les quatre comportements Facts restent verts. |
| `packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart` | clés stables des compteurs/modules | Permettre des assertions ciblées sans ambiguïté textuelle | Les valeurs légitimes restent visibles et testables. |
| `packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart` | contrats de navigation partagée | Remplacer les attentes de l'ancien shell | Le test suit le product shell réellement livré. |
| `packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart` | compteurs et diagnostics Overview | Distinguer World Rule, diagnostic et absence de Scene | Aucun diagnostic réel n'est masqué. |
| `packages/map_editor/test/selbrume_editor_repository_roundtrip_test.dart` | placements Port/total et proxy | Refléter la migration du nid | `43` placements au Port, `475` au total, proxy conservé au reload. |
| `packages/map_editor/test/support/narrative_studio_visual_harness.dart` | sélection keyed Validator | Stabiliser les routes visuelles | Le harness cible la destination réelle. |
| `packages/map_editor/test/ui/canvas/narrative_studio_shell_contract_test.dart` | présence Validator/product shell | Actualiser le contrat du shell partagé | L'ancien shell n'est plus attendu. |
| `packages/map_editor/test/ui/canvas/narrative_studio_shell_policy_test.dart` | policy Validator | Aligner la destination avec la policy | Le Validator est une route intentionnelle. |
| `packages/map_editor/test/ui/canvas/narrative_studio_visual_contract_test.dart` | assertions de route keyed | Éviter les collisions de labels | Les contrats visuels vérifient les clés produit. |
| `packages/map_editor/test/ui/shell/project_explorer_handoff_test.dart` | handoff Project Explorer → product shell | Refléter la navigation convergée | Un seul shell Narrative Studio est attendu. |
| `examples/playable_runtime_host/event_builder_v2_selbrume_slice/project.json` | bloc `newGame` par défaut | Régénérer la fixture avec le schéma courant | Fixture byte-for-byte compatible avec `ProjectManifest`. |
| `examples/playable_runtime_host/event_builder_v2_selbrume_slice/fixture_manifest.json` | bytes/SHA du seul `project.json` | Recalculer l'intégrité après sérialisation New Game | Les `18` autres payloads/hashes restent identiques. |

Vingt références visuelles ont ensuite été mises à jour à partir de sorties vérifiées : comparaison binaire `20/20` exacte, `0` mismatch, `0` missing. Leur manifeste complet figure en section 11.2. Les images `test/**/failures` utilisées pour la comparaison sont des sorties de diagnostic, pas des références produit à versionner.

## 9. Tests créés ou modifiés

### 9.1 `map_core`

| Fichier | Couverture |
|---|---|
| `test/project_new_game_config_test.dart` | defaults legacy, round trip JSON, valeurs invalides, références et équipe vide/existante. |
| `test/project_dialogue_declared_outcomes_test.dart` | déclarations Yarn valides, doublons et sérialisation. |
| `test/narrative_project_validator_test.dart` | 27 cas : projet jouable, reachability, page order, cycles, borne, catalogs, spawn, storylines et sources orphelines. |
| `test/scene_consequence_model_test.dart` | payloads positifs/négatifs et compatibilité JSON. |
| `test/scene_authoring_operations_test.dart` | authoring guidé et refus des références invalides. |
| `test/scene_diagnostics_test.dart` | diagnostics conséquences/ports. |
| `test/scene_runtime_executor_test.dart` | routage par outcome réel. |
| `test/world_rule_diagnostics_test.dart` | Facts/rules atteignables, mortes et cycliques. |
| `test/beta_playability_validator_test.dart` | remontée des diagnostics narratifs. |
| `test/linked_asset_public_contracts_test.dart` | adversaires Scene-only. |

### 9.2 `map_gameplay`

| Fichier | Couverture |
|---|---|
| `test/project_new_game_state_builder_test.dart` | argent, sac, facts, équipe et trois starters. |
| `test/npc_map_presence_predicate_test.dart` | présence conditionnelle projetée depuis le world state. |

### 9.3 `map_editor`

| Fichier | Couverture |
|---|---|
| `test/narrative_validator_provider_test.dart` | snapshot, refresh réel et catalogues manquants fail-closed. |
| `test/narrative_validator_workspace_test.dart` | filtres, onglets, empty state et navigation source. |
| `test/ui/canvas/narrative_validator_route_test.dart` | route produit et wiring. |
| `test/selbrume_narrative_validator_test.dart` | canon Selbrume sans erreur bloquante. |
| `test/project_new_game_configuration_form_test.dart` | formulaire, pickers et starters. |
| `test/selbrume_canonical_narrative_seed_test.dart` | seed canonique idempotent et complet. |
| `test/marionette_project_bootstrap_test.dart` | copie jetable, chemin, arguments et garde-fous. |
| `test/features/narrative/application/overview/narrative_overview_read_model_test.dart` | compteur Scenes réel (`31` pour le canon). |
| Tests dialogue/scenes existants modifiés | outcomes, conséquences et non-régressions UI. |

### 9.4 `map_runtime` et `map_battle`

| Fichier | Couverture |
|---|---|
| `test/dialogue_runtime_outcome_test.dart` | sélection/annulation et propagation d'outcome. |
| `test/cinematic_runtime_playback_controller_test.dart` | ordre, préflight, annulation, erreur et restauration. |
| `test/flame_cinematic_runtime_playback_sink_test.dart` | caméra, acteur, fade, shake et reset. |
| `test/playable_map_game_cinematic_runtime_integration_test.dart` | Scene attend la timeline réelle. |
| `test/playable_map_game_dialogue_outcome_scene_integration_test.dart` | outcome Yarn → edge de Scene. |
| `test/playable_map_game_project_new_game_boot_test.dart` | boot configuré et garde-fous. |
| `test/playable_map_game_world_state_v1_integration_test.dart` | projection Facts/Rules sur la carte. |
| `test/selbrume_new_game_starter_integration_test.dart` | starter exact au niveau 16. |
| `test/static_battle_start_request_test.dart` | requête de boss statique. |
| `test/selbrume_static_boss_playable_map_game_integration_test.dart` | combat final et outcome. |
| `test/selbrume_event_v2_trigger_battle_anchor_integration_test.dart` | ancre de combat Event V2. |
| Tests runtime historiques réconciliés | routes/maps/assets/rendering canoniques, sans affaiblir les assertions. |

### 9.5 Host E2E

`examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` contient cinq scénarios :

1. reload après déplacement 32 px au travers de la gate du port ;
2. victoire Lysa via un move réellement dommageable ;
3. défaite Lysa via le move de statut et la branche defeat ;
4. parcours principal complet via les hooks production, avec checkpoints `before_port`, `after_lysa`, `after_marsh`, `before_boss`, `after_boss`, `after_epilogue` ;
5. branche alternative Goélise « garder » et sa récompense distincte.

## 10. Commandes et résultats exacts

Les commandes ci-dessous sont retranscrites sans convertir un échec en succès. L'historique des gates rouges puis réconciliées est conservé avec le résultat final frais.

### 10.1 Core

```text
Commande ciblée validator :
cd packages/map_core && dart test test/narrative_project_validator_test.dart

Résultat : 27/27 tests réussis, code de sortie 0.
```

```text
Commande complète Core :
cd packages/map_core && dart test

Résultat final : +3058: All tests passed!
Code de sortie : 0.
```

```text
Commande analyse :
cd packages/map_core && dart analyze

Résultat : analyse propre (aucun diagnostic).
```

```text
Commande complète Gameplay :
cd packages/map_gameplay && dart test

Résultat final : +288: All tests passed!
Code de sortie : 0.

Commande analyse Gameplay :
cd packages/map_gameplay && dart analyze

Résultat : aucun diagnostic, code de sortie 0.
```

```text
Commande complète Battle :
cd packages/map_battle && dart test

Résultat final : +1722: All tests passed!
Code de sortie : 0.

Commande analyse Battle :
cd packages/map_battle && dart analyze

Résultat : aucun diagnostic, code de sortie 0.
```

### 10.2 Editor ciblé

```text
Commande ciblée :
cd packages/map_editor && flutter test --no-pub \
  test/narrative_validator_provider_test.dart \
  test/narrative_validator_workspace_test.dart \
  test/ui/canvas/narrative_validator_route_test.dart \
  test/selbrume_narrative_validator_test.dart \
  test/features/narrative/application/overview/narrative_overview_read_model_test.dart

Résultat consolidé communiqué : providers + gate + Overview, 14/14 tests réussis.
```

```text
Commande analyse :
cd packages/map_editor && flutter analyze

Sortie exacte :
Analyzing map_editor...
No issues found! (ran in 4.6s)

Code de sortie : 0.
Durée murale : 5.5 s.
```

### 10.3 Runtime ciblé et complet

```text
Commande de réconciliation ciblée :
cd packages/map_runtime && flutter test --no-pub [fichiers runtime concernés]

Résultat : +84 ~1, code de sortie 0.
```

```text
Commande complète :
cd packages/map_runtime && flutter test

Résultat : +1827 ~1, code de sortie 0.
```

```text
Commande analyse :
cd packages/map_runtime && flutter analyze

Résultat exact : No issues found! (5.7s)
```

Les 21 échecs observés pendant une passe intermédiaire ont été reproduits puis classés comme attentes historiques obsolètes : catalogues (`10`), navigation (`9`), asset (`1`), render (`1`). Le rerun ciblé initial était `+63 ~1 -21`, puis `+84 ~1` après réconciliation. Les assertions ont été mises à jour vers les routes et assets canoniques, sans suppression de vérification produit.

### 10.4 Host E2E et suite complète

```text
Commande E2E :
cd examples/playable_runtime_host && flutter test --no-pub test/selbrume_player_journey_e2e_test.dart

Résultat : +5, durée 03:08, code de sortie 0.
```

```text
Commande suite complète Host :
cd examples/playable_runtime_host && flutter test --no-pub

Premier résultat : 03:05 +63 -3: Some tests failed.
Code de sortie : 1.
Rerun après réconciliation minimale : 03:03 +66: All tests passed!
Code de sortie intermédiaire : 0.
Premier rerun complet post-FIFO : 01:33 +65 -1.
Échec unique : selbrume_player_journey_e2e_test.dart — player completes Selbrume through PlayableMapGame production hooks.
Rerun final avec capture d'assertion : 03:04 +66: All tests passed!
Code de sortie final : 0.
```

Les trois rouges initiaux sont :

1. `selbrume_canonical_narrative_campaign_test` : `cinematic_mist_disperses` attendu sans exécution préalable de `scene_mist_disperses` ;
2. deux variantes promoted Selbrume de `selbrume_event_v2_lysa_golden_slice_test` : précondition `fact_port_alert_seen` absente du harness et slice canonique Lysa enrichi/séparé par outcome ;
3. les deux versions fondées sur la fixture versionnée restent vertes.

Le diagnostic a confirmé des contrats de test obsolètes et le premier rerun complet est vert. La revue demande toutefois une preuve plus forte que les outcomes Lysa sont consommés dans l'ordre FIFO ; le vert `+66` est donc conservé comme jalon intermédiaire, pas comme gate finale.

```text
Commande ciblée FIFO :
cd examples/playable_runtime_host && flutter test --no-pub test/selbrume_event_v2_lysa_golden_slice_test.dart

Résultat : 4.86s, +4: All tests passed!
Code de sortie : 0.
```

La full Host post-preuve a ensuite été rejouée jusqu'au résultat final vert `03:04 +66`, documenté plus haut.

```text
Commande de reproduction du grand E2E :
cd examples/playable_runtime_host && flutter test --no-pub test/selbrume_player_journey_e2e_test.dart

Résultat : 03:00 +5: All tests passed!
Code de sortie : 0.
```

Le test isolé vert ne suffisait pas à classer l'échec complet comme résolu. La full de capture finale est verte et n'a reproduit aucun signal ; le transitoire `+65 -1` reste documenté comme non reproduit.

```text
Micro-renforcements finaux :
- Lysa FIFO ciblé : +4, exit 0, 4.43s.
- Fichier E2E complet : +5, exit 0, 03:00.
- Promotion canonique ciblée : +1, exit 0, 3.51s.

Commande analyse Host :
cd examples/playable_runtime_host && flutter analyze

Résultat exact : No issues found! (ran in 4.1s)
Code de sortie : 0.
```

### 10.5 Suite complète Editor

```text
Commande :
cd packages/map_editor && flutter test --no-pub

Premier résultat de gate : 04:38 +3359 -40.
Second résultat après un premier triage : +3384 -17.
Résultat final : 03:31 +3403: All tests passed!
Code de sortie final : 0.
```

La suite complète fraîche remplace le NO-GO provisoire. L'historique des rouges reste documenté afin de montrer leur reproduction, leur triage et les corrections exactes, sans maquiller le chemin vers le vert.

Triage provisoire des `40` rouges :

- `20` échecs de goldens intentionnellement modifiés par la convergence UI ; après mise à jour, comparaison binaire des `20` `testImage` aux `20` références : `20/20` identiques, `0` mismatch, `0` missing ;
- vrai drift du générateur proxy Goélise corrigé strictement ; `validate-authored` : `+6`, code de sortie `0` ;
- timers des tests de cinématiques Scene corrigés ; ciblé : `5/5` verts ;
- comportements Facts : `4/4` verts, avec un golden obsolète restant alors dans le ciblé ;
- ciblé Facts + Cinematic après corrections : `+9 -1`, l'unique rouge étant ce golden ensuite mis à jour.

Ces résultats réduisent le risque de régression fonctionnelle, mais ne remplacent pas le rerun complet final. Le second rerun conserve `17` rouges. L'audit assertion par assertion des `16` hors gros tests conclut à **aucun défaut produit** :

- `13` contrats Validator obsolètes (`9` routes visuelles, policy, shell contract, navigation Overview et handoff Project Explorer) ; la destination Validator est intentionnelle et cohérente avec la policy/route, les assertions de test doivent devenir keyed ;
- Overview #1 : les deux valeurs `1` sont légitimes — une World Rule et un diagnostic « source jamais produite » ; le diagnostic ne doit pas être masqué ;
- Overview #2 : la fixture ne fournit aucune `project.scenes`, donc le compteur canonique `0` est correct ; la correction recommandée est d'ajouter une Scene canonique à la fixture pour préserver l'attente `1` ;
- round trip : Port `44 → 43`, total `476 → 475` après migration exacte du nid ; le test doit aussi attester que `goelise_nest_proxy` survit au reload ;
- le dix-septième rouge était une fixture Event V2 générée obsolète, sans défaut produit : seul le bloc `newGame` par défaut est ajouté à `event_builder_v2_selbrume_slice/project.json`, et `fixture_manifest.json` ne change que les bytes/hash associés ; les `18` autres payloads/hashes sont identiques.

Les `17/17` rouges sont donc expliqués sans défaut produit identifié. Après application des corrections ciblées :

```text
Réconciliation Editor — 7 fichiers ciblés : +89, All tests passed.
Persistence migration + fixture byte-for-byte : +5, All tests passed.
```

Les commandes exactes et leurs listes de fichiers ciblés seront figées avec les autres sorties finales. Le rerun complet confirme que la réconciliation n'a laissé aucun test Editor rouge.

### 10.6 Build

```text
Commande build Editor :
cd packages/map_editor && FLUTTER_XCODE_ARCHS=arm64 flutter build macos --release

Résultat exact : ✓ Built build/macos/Build/Products/Release/map_editor.app (37.4MB)
Code de sortie : 0.
Durée murale : ~58 s.
```

```text
Vérifications binaires :
file build/macos/Build/Products/Release/map_editor.app/Contents/MacOS/map_editor
=> Mach-O 64-bit executable arm64

xcrun lipo -info build/macos/Build/Products/Release/map_editor.app/Contents/MacOS/map_editor
=> Non-fat file ... is architecture: arm64

xcrun lipo -verify_arch arm64 build/macos/Build/Products/Release/map_editor.app/Contents/MacOS/map_editor
=> code de sortie 0.
```

La tentative universelle par défaut a échoué dans l'outillage, pas dans le code Dart/Flutter du produit : Flutter beta `3.46.0-0.3.pre` invoque `lipo -verify_arch` avec deux architectures, alors que Xcode 27 exige un seul input/arch. Le framework `FlutterMacOS` contient bien `x86_64+arm64`. La gate prouvée ici est donc un build Release **arm64**, pas un bundle universel.

Warning non bloquant : le catalogue `AppIcon` contient un enfant non assigné.

```text
Seed check final : exit 0
Selbrume canonical narrative content is up to date.

git diff --check : exit 0.
```

## 11. QA desktop et preuves binaires

### 11.1 Captures Desktop QA SEL-FIN-09

La QA a utilisé une copie jetable byte-for-byte du projet canonique. Aucune écriture n'a été conservée dans le projet utilisateur. Les copies ont été supprimées après chaque session et la session QA propre a été fermée. Une instance `map_editor.app` plus ancienne, appartenant potentiellement à l'utilisateur, n'a pas été interrompue.

| Preuve | Dimensions | SHA-256 | Observation |
|---|---:|---|---|
| `01-map-editor-bootstrap.png` | 1920×1128 | `4527ff5bd923037c09f2a674c5699cf465e11db39abcc2bf3c164224a40d6160` | Projet chargé dans l'éditeur. |
| `02-narrative-studio-scenes.png` | 1920×1080 | `14e83c9c37ac37b4e2a87b4e7ed5f78c25afdc4b7ae9e42bd5597510ae563570` | Workspace Scenes canonique. |
| `03-narrative-studio-events-selected.png` | 1920×1080 | `10e0eeb84e3fff1365be92397aeb57050a6b8fc84ab68b7cd048124261754a9c` | Event Builder avec événement sélectionné. |
| `04-reference-vs-events-contact-sheet.png` | 3344×941 | `7fb1f7bc5ceab32ddc2dc89250e0c71751dc7329ec88f5eae199f0c942884628` | Comparaison cible/Events. |
| `05-narrative-validator-zero-errors.png` | 1920×1080 | `2bac9bbab0c45d1d268fb9a15975fc648c86069366ab7abe688dcaee7110073d` | Validator : Jouable, 0 erreur, 29 events. |
| `06-new-game-no-code-starters.png` | 1920×1080 | `346f7d43b831ed1a3be685dcddf1cca14a17e18b6918efeb128ae5da5038e601` | Formulaire New Game et 3 starters. |
| `07-reference-vs-scenes-contact-sheet.png` | 3344×941 | `3a755e6deb4a875ab7c625852dd092c5d62ab67c240c2bc338e0f48b7b2a48fa` | Comparaison cible/Scenes. |
| `08-reference-vs-validator-contact-sheet.png` | 3344×941 | `8b3ef0ed58ccc75e7bf6011b4eb43c64a3497dc6e72e184f3f4d6098723bffa4` | Comparaison cible/Validator. |
| `09-reference-vs-new-game-contact-sheet.png` | 3344×941 | `b7425151165db216f32943fa9c7f68d8e8d1b53604af8006899c74c16356fc13` | Comparaison cible/New Game. |
| `10-overview-scenes-31-after-fix.png` | 1920×1080 | `58ab9b2688cbac233ca25da48122231269a3bbe1bdfee74c8057909cbe0ca0ad` | KPI et inspector Scenes corrigés à `31`. |

Limites observées pendant la QA :

- `get_logs` Marionette a renvoyé une erreur serveur ; la console a servi de fallback d'observabilité ;
- un overflow transitoire de `+55` puis `+113` px a été journalisé au démarrage dans `editor_shell_page.dart`, puis l'interface s'est stabilisée ;
- cette QA prouve les routes ciblées, pas chaque interaction de tous les workspaces Narrative Studio.

### 11.2 Références visuelles rafraîchies pendant la gate Editor

| Référence | Dimensions | SHA-256 |
|---|---:|---|
| `packages/map_editor/test/goldens/event_builder_v2/phase_1/event_builder_v2_full_product_route_1672x941.png` | 1672×941 | `84ed2ba33512081e3675df212dbfba737a7a84f7e01f023f3339e09bcbada3d0` |
| `packages/map_editor/test/goldens/narrative_studio/cinematics/cinematics_builder_full_product_route_1672x941.png` | 1672×941 | `bb15688a9b9a678f941aa05ef73b2cfe4a160a55cc94b6a2ec9e488227e516ec` |
| `packages/map_editor/test/goldens/narrative_studio/cinematics/cinematics_legacy_full_product_route_1672x941.png` | 1672×941 | `15fa289552c52c46f0a7260ef0529390cbdad3298ad840adf27ede959728aee1` |
| `packages/map_editor/test/goldens/narrative_studio/cinematics/cinematics_library_full_product_route_1672x941.png` | 1672×941 | `b40fbb29f873a3c91a327ff5db118af9414366dee88801eed27f13a4ce271cb5` |
| `packages/map_editor/test/goldens/narrative_studio/dialogues/dialogues_full_product_route_1672x941.png` | 1672×941 | `7a0560ed16024380ec367472d8f54b4de134fc09ab57a894f259c31e9068c62d` |
| `packages/map_editor/test/goldens/narrative_studio/events/event_builder_legacy_full_product_route_1672x941.png` | 1672×941 | `ed5080dafb2711dff898e517704d7f7fa06034f233fa168682041b1e83e5469a` |
| `packages/map_editor/test/goldens/narrative_studio/facts/facts_full_product_route_1672x941.png` | 1672×941 | `c625ad3e9c2e6a493a5eef743276eb74d828843c02749254826ab01749c5e224` |
| `packages/map_editor/test/goldens/narrative_studio/overview/overview_full_product_route_1672x941.png` | 1672×941 | `121d05f0429a5d49312457de80344bce950c45d6e9e479fc2de3eeaec90ed350` |
| `packages/map_editor/test/goldens/narrative_studio/scenes/scenes_full_product_route_1672x941.png` | 1672×941 | `a6f6b34f827b29fc5073cfffb899ab5f2a4dc7588aa496dc72784f8a0f4950c8` |
| `packages/map_editor/test/goldens/narrative_studio/step/step_full_product_route_1672x941.png` | 1672×941 | `fc52b15448ff6e028e271303cfff9c6da60e047cc01870000e16e3a630bf4afd` |
| `packages/map_editor/test/goldens/narrative_studio/storylines/storylines_full_product_route_1672x941.png` | 1672×941 | `2de3cd31dae4732e46527d6a1e028e6b67fbd90d9fbb200ff63f871194108076` |
| `packages/map_editor/test/goldens/narrative_studio/world_rules/world_rules_full_product_route_1672x941.png` | 1672×941 | `07df5f07134f7a01ae8f3ccae79cea1dbbc0e64be29ea6f3458cfb01c36930bc` |
| `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_35_facts_world_rules_manager_ui_v0.png` | 1440×900 | `18b5ad39c33428568a4194329d701e7d27b0dc8404dcb98a56f4f9460a3e8191` |
| `reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_bis_graph_focus_canvas.png` | 1552×879 | `54b3e291ad12e95787760206dab1e6cc801dbb639c7ce0c8501cf4c7e1dae9d7` |
| `reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_bis_graph_full_layout.png` | 1600×1000 | `f3061f9e611d77e9f9e7ec37d1198bdd14f81289305469ecfb8124ffb2dcb314` |
| `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_authoring_actions.png` | 1008×781 | `dcf1535a0684586d431fa0db51314e7d20d97d9186b357459cde19a5630e3d5b` |
| `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_collapsed_chapter.png` | 1008×781 | `93c0f705cdb2c1a73a218d50dcb072b408620ebb0ef8fbcca4fb18863140375f` |
| `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_expanded_chapter_steps.png` | 1008×781 | `93c0f705cdb2c1a73a218d50dcb072b408620ebb0ef8fbcca4fb18863140375f` |
| `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_full_width_accordion.png` | 1600×1000 | `f9fe63a034652d8169921b4d11dc1a0ec63cc8a7194194f3aa315901a5233560` |
| `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_graph_regression.png` | 1600×1000 | `e2bcb2aad62800d5ef0e963d614be3ccb412ec35edf73d1eba9b92af213e1ed1` |

## 12. Gate de clôture

### 12.1 Critères GO Selbrume

| Critère | État |
|---|---:|
| Canon Selbrume chargeable sans fixture de substitution | PASS |
| New Game et starter exact consommés au runtime | PASS |
| Dialogues/outcomes branchent réellement les Scenes | PASS |
| Conséquences modifient le world state réel | PASS |
| Cinématiques exécutées et restaurées | PASS |
| Validator Selbrume sans erreur bloquante | PASS |
| Parcours principal + branches + reloads | PASS |
| Analyses Core, Runtime, Host et Editor | PASS |
| Suite runtime complète | PASS |
| Suite Host complète | PASS — `03:04 +66`, exit `0` |
| Suite Editor finale | PASS — `03:31 +3403`, exit `0` |
| Build Editor final | PASS Release arm64 — 37.4 MB, Mach-O/lipo vérifiés |
| Critique finale consolidée | GO — Critical `0`, Important `0`, Minor non bloquants `2` |

### 12.2 Distinction avec `FG-185`

Tous les critères ci-dessus étant verts, le verdict retenu est :

- **Selbrume Demonstrator Gate : PASS / GO** ;
- **`FG-185 — MVP Release Gate V0` global : PARTIAL**.

`FG-185` exige une assurance plus large que le seul contenu Selbrume : gate générique, projets arbitraires, paquets critiques complets, validation de playabilité globale et acceptation utilisateur. Ce rapport ne modifie donc pas le statut roadmap global.

### 12.3 Statuts roadmap proposés — non appliqués

| Lot roadmap | Statut proposé | Portée de la proposition |
|---|---:|---|
| `FG-146` | candidat `DONE` | Contrat Event/Scene/outcome prouvé sur le canon et par les gates complètes. |
| `FG-147` | candidat `DONE` | Conséquences narratives et consommation runtime prouvées. |
| `FG-180` | `PARTIAL` global | Le démonstrateur est jouable, mais la readiness générique multi-projets reste plus large. |
| `FG-182` | `PARTIAL` global | Le contenu Selbrume est complet pour la démo ; la couverture globale du moteur reste distincte. |
| `FG-183` | candidat `DONE` | Authoring Narrative Studio + validation + runtime démontrés de bout en bout. |
| `FG-185` | `PARTIAL` global | GO Selbrume obtenu, release gate PokeMap globale non clôturée. |

Ces statuts sont des **propositions fondées sur les preuves fraîches**. Le fichier `pokemap_roadmap_mecaniques_fangame.md` n'est pas modifié sans demande explicite de l'utilisateur.

## 13. État Git final

```text
Branche : main
HEAD : f93b70ad12a1930e332bef6c4eebcc10026690dc
Statut final : 386 entrées — 177 M, 3 D, 206 ??
SHA-256 du snapshot porcelain final : d385088e0003511383ae22d52dc845f242fbe16ed4d0893615f1b0583ccc5514
SHA-256 de selbrume/project.json : b62423b77b97f2d10bfb9ee5be8cef006607bf5a4aa60e00b341608462c48e26
Fingerprint des sources Selbrume hors lock : ce8afc1d60a50fd685f4d94a27a50b7b4a92fd67bc1064155bbd2275775f0147
```

Le relevé final compte `386` entrées. Le diff tracked global compte `180` fichiers, `24996` insertions et `4836` suppressions. Ces volumes incluent les changements préexistants du workspace et ne représentent pas le seul lot SEL-FIN. Le cleanup final a supprimé `80` PNG de diagnostic non suivis sous `test/failures/**` et `test/ui/canvas/failures/**` ; aucun golden de référence ni aucune preuve n'a été supprimé.

Le lock local `selbrume/.pokemap-project-*.lock` est conservé parce qu'une instance Debug utilisateur/préexistante de `map_editor` tourne encore. Cette instance précède la QA SEL-FIN de plusieurs heures et n'a pas été interrompue. Le lock n'est pas un artefact produit et ne doit pas être versionné.

## 14. Limites explicitement conservées

- Les quatre storylines restent marquées `draft` dans le contenu ; le démonstrateur peut être jouable sans transformer ce statut éditorial en faux `published`.
- L'option starter créée manuellement par l'UI utilise encore des defaults techniques (`abilityId: unknown`, PV `1`) et les moves ne sont pas éditables dans ce formulaire. Le canon Selbrume est complet et le runtime dérive les moves ; l'authoring générique mérite un lot UX séparé.
- Le solveur statique est volontairement conservateur et borné à `4096` états ; au-delà, il échoue de manière explicite plutôt que de promettre une reachability non prouvée.
- `cinematic_lysa_port` reste une cinématique minimale `wait` ; les autres cinématiques canoniques portent des timelines multi-étapes.
- Marionette est debug-only et ne doit jamais être importé par la production.
- La QA visuelle n'est pas une preuve d'absence de tout overflow à toutes les tailles de fenêtre.
- Les tests ciblés SEL-FIN ne se substituent pas à la suite globale ; la suite Editor complète a donc été rejouée jusqu'au résultat vert `+3403`.
- Le build Release final est prouvé pour `arm64`. Le bundle universel reste bloqué par l'interaction Flutter beta `3.46.0-0.3.pre` / Xcode 27 décrite section 10.6.
- Aucun commit, push ou changement de branche n'est inclus dans ce lot de rapport.

## 15. Risques restants

| Risque | Gravité | Mitigation / suite |
|---|---:|---|
| Dette historique révélée par les `40` rouges initiaux | Résolu pour la gate | Triage exhaustif, ciblés `+89` et `+5`, puis full `+3403` verte. |
| Worktree massif et préexistant | Important | Committer par scopes après revue utilisateur ; ne pas mélanger UI convergence, contenu, runtime et preuves. |
| Defaults starter générique pauvres | Mineur | Lot UX New Game pour moves, HP dérivés et talents guidés. |
| Borne du solver | Mineur | Exposer un diagnostic clair et ajouter une stratégie symbolique si de gros projets dépassent la borne. |
| Observabilité Marionette partielle | Mineur | Corriger `get_logs` ou conserver un fallback console documenté. |
| Overflows transitoires au bootstrap | Mineur | Reproduire dans un test responsive ciblé avant une release UI générale. |
| Storylines `draft` | Mineur produit | Décider explicitement du workflow publication avant une distribution publique. |
| Bundle macOS universel non produit | Mineur release | Utiliser une version Flutter/Xcode dont la vérification `lipo` multi-arch est compatible, puis rejouer le build universel. |
| AppIcon avec enfant non assigné | Mineur packaging | Nettoyer le catalogue d'assets avant distribution publique. |

## 16. Auto-critique finale

### Ce qui est solide

- les preuves partent du projet canonique, pas d'une fixture avantageuse ;
- chaque grande capacité traverse modèle → authoring → runtime → test ;
- les catalogues du validator sont fail-closed ;
- le parcours E2E utilise les hooks production et force plusieurs save/reload ;
- les échecs intermédiaires runtime ont été reproduits et triés au lieu d'être masqués ;
- la QA a détecté un vrai défaut de compteur Scenes, corrigé puis revérifié visuellement.

### Ce qui aurait pu être mieux

- un worktree initial propre ou un commit de baseline aurait rendu l'attribution des fichiers beaucoup plus sûre ; la demande explicite de travailler dans le workspace principal a été respectée, mais le coût d'audit est élevé ;
- la taille du seed canonique et du test E2E rend leur revue plus difficile ; des helpers de campagne plus petits pourraient améliorer la maintenabilité sans changer les comportements ;
- la gate Editor aurait dû être rejouée plus tôt après chaque sous-lot pour réduire le triage final ;
- l'UI New Game prouve le canon mais ne couvre pas encore un authoring complet de créature ;
- le rapport ne doit pas confondre un GO démonstrateur avec une release globale de PokeMap.

### Recherche active de faux supports

Aucun support n'est revendiqué uniquement parce qu'un modèle JSON l'accepte. Les claims centraux disposent d'un consommateur runtime et d'un test d'intégration : starter, outcome Yarn, conséquence, world state, cinématique, boss, save/reload. Les warnings informatifs du validator et l'historique des rouges Editor restent documentés, tandis que la gate finale est bien verte.

## 17. Prochaines étapes proposées, non implémentées

1. faire relire et accepter le GO Selbrume par l'utilisateur sur un parcours manuel complet ;
2. découper le dirty worktree en commits cohérents après accord explicite ;
3. ouvrir un lot UX New Game générique pour stats/moves/talents ;
4. rejouer le build macOS universel avec une combinaison Flutter/Xcode compatible ;
5. traiter séparément la dette UI/packaging restante, dont AppIcon et les overflows transitoires ;
6. définir les preuves additionnelles nécessaires pour faire passer `FG-185` global de `PARTIAL` à `DONE`.

## Annexe A — Commandes de gel du rapport

Ces commandes ont été rejouées au gel final :

```bash
git rev-parse HEAD
git branch --show-current
git status --short --untracked-files=all
git diff --check
shasum -a 256 selbrume/project.json
find selbrume -type f ! -name '*.lock' -print0 | sort -z | xargs -0 shasum -a 256 | shasum -a 256
for f in reports/gameplay/evidence/sel_fin_09_desktop_qa/*.png; do
  sips -g pixelWidth -g pixelHeight "$f"
  shasum -a 256 "$f"
done
```

## Annexe B — Contenu intégral des fichiers texte créés

Conformément à `codex_rule.md`, cette annexe contient le contenu intégral des `64` fichiers texte créés et attribués aux lots SEL-FIN. Chaque snapshot est précédé de sa taille et de son SHA-256. Les fichiers binaires de preuve ne sont pas encodés dans le Markdown : leurs dimensions et hashes figurent en section 11.

Le présent rapport est lui-même un fichier texte créé. Son corps complet constitue son propre contenu de référence ; il n'est pas ré-imbriqué récursivement dans cette annexe.

### `reports/gameplay/fg_000_narrative_studio_selbrume_readiness_audit.md`

- Taille : `42230` octets
- SHA-256 : `1280c49601915aefef13c3755f9638b259448279498fd177c916587aacaaa413`

~~~~~~markdown
# Audit complet du Narrative Studio pour le démonstrateur Selbrume

Date de l'audit : 18 juillet 2026<br>
Périmètre : état du moteur, du runtime, de l'éditeur no-code et du contenu Selbrume ; aucune implémentation demandée<br>
Référentiels : `MVP Selbrume/narrative_studio.md`, `MVP Selbrume/selbrume.md`, `pokemap_roadmap_mecaniques_fangame.md`<br>
Lot narratif : **N1 — Existing Narrative Studio Audit vs Canonical Model**, appliqué ici au démonstrateur complet Selbrume<br>
Lot mécanique transverse : **FG-000 — baseline audit**, limité à ce périmètre narratif ; aucun statut de roadmap n'a été modifié<br>
Branche et révision observées : `main`, `f93b70ad12a1930e332bef6c4eebcc10026690dc`

## 1. Verdict exécutif

### Réponse courte

| Objet évalué | Avancement estimé | Verdict |
|---|---:|---|
| Narrative Studio face à la vision canonique | **50 %** | `PARTIAL` |
| Capacités moteur/runtime utiles à Selbrume | **62 %** | `PARTIAL` |
| Démonstrateur Selbrume complet, du démarrage à l'épilogue | **50 % ± 5 points** | **non prêt / gate `FAIL`** |

Si un seul nombre doit être retenu, **Selbrume est à environ 50 % de sa réalisation fonctionnelle**. Ce pourcentage ne signifie pas que la moitié des fichiers manque : beaucoup de contenu est déjà déclaré. Il signifie que la moitié environ de la chaîne **auteur no-code → donnée persistée → déclenchement réel → interaction jouée → conséquence sauvegardée → validation de campagne** est démontrée.

Le socle est substantiel : modèles narratifs, Facts, Story Steps, Event V2, Scenes graphées, dialogues Yarn affichables, combats trainer/wild, World Rules simples et sauvegarde générique existent. Le démonstrateur n'est pourtant pas livrable, car cinq capacités critiques restent absentes ou non prouvées :

1. le choix de starter et le chemin « party déjà existante » ne sont pas un flux auteur/runtime complet ;
2. les choix Yarn ne produisent pas d'outcomes persistants utilisables par une Scene ;
3. les Scenes ne savent pas encore attribuer les récompenses nécessaires (Pokémon, objets, argent) par leur contrat canonique ;
4. les cinématiques Selbrume ne sont pas jouées visuellement dans le runtime ;
5. aucune preuve end-to-end ne parcourt réellement les 12 étapes principales, les 3 quêtes annexes, les combats, les choix et les sauvegardes jusqu'à l'épilogue.

La gate fraîche est en outre rouge : le contrat de hash du projet promu est périmé et deux tests d'intégration Event V2 du projet courant expirent.

## 2. Ce que signifie « démonstrateur Selbrume complet »

Cet audit évalue le démonstrateur complet décrit par `selbrume.md`, et non uniquement la Golden Slice Lysa. La cible comprend notamment :

- 9 maps canoniques décrites par la spécification ;
- 4 chapitres principaux et 12 étapes principales détaillées ;
- l'introduction de Maël, avec les variantes starter/party existante ;
- la panique au port, le choix de ton, Lysa, puis la convergence victoire/défaite ;
- Mado, les trois indices, Soline et l'ouverture du passage ;
- le phare, deux gardiens, la confrontation finale et l'épilogue ;
- 3 quêtes annexes : cristaux de sel, Goélise et cabane du gardien ;
- des choix, récompenses, Facts, World Rules, combats et sauvegardes cohérents sur une session annoncée de 2 à 3 heures.

La spécification Narrative Studio cible 11 surfaces produit : Overview, Storylines Board, Storyline Graph, Scenes Library, Scene Builder, Cinematics Library, Cinematic Builder V2, Map Events View, Event Builder, Facts/World Rules et Validator.

## 3. Méthode et prudence sur les pourcentages

Chaque capacité a été notée selon cinq niveaux :

- `0` : absente ;
- `0,25` : structure ou prototype sans boucle fonctionnelle ;
- `0,50` : partielle, utilisable dans certains cas ;
- `0,75` : fonctionnelle mais incomplète ou insuffisamment prouvée ;
- `1` : complète et couverte par une preuve fraîche représentative.

Une moyenne ne peut pas rendre un démonstrateur « prêt » si une gate critique est rouge. Les trois pourcentages répondent à des questions différentes : maturité de l'outil auteur, capacité technique du moteur et fermeture réelle du contenu Selbrume. L'incertitude de ±5 points vient du worktree concurrent, de l'absence de walkthrough manuel complet et de plusieurs ambiguïtés dans les spécifications.

### 3.1 Score Narrative Studio

| Domaine | Poids | Niveau | Points | Lecture |
|---|---:|---:|---:|---|
| Shell et navigation unifiée | 10 | 0,75 | 7,5 | navigation spécialisée présente, mais encore en convergence |
| Overview | 8 | 0,50 | 4 | utile, mais encore lié en partie au modèle legacy Scenario |
| Storylines Board et Graph | 15 | 0,50 | 7,5 | structure auteur présente ; branches/conditions/outcomes incomplets |
| Scenes Library et Builder | 15 | 0,50 | 7,5 | graphes, références et diagnostics solides ; authoring des conséquences incomplet |
| Event Builder V2 et Map Events | 15 | 0,50 | 7,5 | quatre sources runtime ; vue cartographique consolidée et actions avancées absentes |
| Dialogues Yarn | 10 | 0,50 | 5 | CRUD, fichiers et lecture ; pas de liaison choix → outcome |
| Facts et World Rules | 10 | 0,75 | 7,5 | bonne base booléenne ; effets environnementaux trop limités |
| Cinematics | 12 | 0,25 | 3 | authoring avancé visible ; playback production non visuel |
| Validator produit | 5 | 0,25 | 1,25 | diagnostics locaux, pas de route ni de gate globale de campagne |
| **Total brut** | **100** |  | **50,75** | **arrondi prudent : 50 %** |

### 3.2 Score des capacités moteur/runtime

| Domaine | Poids | Points acquis | Motif principal |
|---|---:|---:|---|
| Contrats, JSON et sérialisation | 15 | 13 | modèles structurés et validations nombreuses |
| Event V2 et exécution de Scenes | 20 | 14 | boucle solide en fixture ; deux intégrations projet courant rouges |
| Dialogue/Yarn | 10 | 5 | affichage, options et jumps ; aucun outcome public/persisté |
| Cinématiques | 10 | 2 | résolution/attente seulement, sans playback visuel production |
| Combats et rencontres | 15 | 12 | trainer/wild, write-back et persistance ; parcours Selbrume complet non joué |
| État, sauvegarde et World Rules | 15 | 11 | socle générique fort ; campagne/mid-quest non prouvée |
| Nouvelle partie et récompenses | 10 | 3 | mutations génériques existantes, sans boucle canonique Narrative Studio |
| Validation end-to-end | 5 | 2 | diagnostics ciblés, pas de preuve campagne |
| **Total** | **100** | **62** | **capacité moteur partielle** |

### 3.3 Score du démonstrateur complet

| Résultat attendu | Poids | Points acquis | État |
|---|---:|---:|---|
| Contenu structurel et raccords déclarés | 15 | 12 | inventaire riche, encore `draft` et volatil |
| Ouverture, Maël et starter | 10 | 4 | chemin party existante semé ; starter bloqué |
| Trame principale jusqu'à l'épilogue | 30 | 15 | Scenes présentes, pas de parcours réel complet |
| Combats, boss et récompenses | 15 | 7 | moteurs présents, intégration/récompenses incomplètes |
| Trois quêtes annexes | 10 | 3 | structure déclarée, choix/récompenses non fermés |
| Sauvegarde de la progression | 10 | 6 | round-trips génériques, pas de campagne longue prouvée |
| Authoring no-code du contenu | 4 | 2 | plusieurs surfaces, persistance fragmentée |
| Validator Selbrume dérivé du projet | 4 | 1 | absent comme gate globale |
| Walkthrough end-to-end réel | 2 | 0 | aucune preuve du démarrage à l'épilogue |
| **Total** | **100** | **50** | **non prêt** |

## 4. Audit initial et état du dépôt

Au début de l'audit :

- branche `main`, HEAD `f93b70ad12a1930e332bef6c4eebcc10026690dc` ;
- 204 entrées dans `git status --short --untracked-files=all` ;
- 63 fichiers modifiés, 3 supprimés et 138 non suivis ;
- empreinte SHA-256 du porcelain initial : `c85a6a1960d6090b9982ebc48bf709c75596ae20f9e7a6b49cf7ce1e651fc2ae` ;
- les changements préexistants couvrent notamment `packages/map_editor`, `reports/` et `selbrume/`.

L'audit n'a pas tenté de nettoyer, restaurer, indexer ou committer ce worktree.

### 4.1 Mutation concurrente du contenu Selbrume

`selbrume/project.json` a été modifié à plusieurs reprises par un travail concurrent pendant l'audit. Les lectures ont notamment vu les empreintes `949f08f1…`, puis `f22c2bf0…`, avec augmentation de 28 à 30 Scenes et de 25 à 27 Events V2. Le point de coupe utilisé pour les inventaires finaux de ce rapport est :

- SHA-256 : `f22c2bf0b8b935a781c4e1c70db83d56ed956583118e3ea2d3427bca7f851141` ;
- date fichier : `2026-07-18T12:15:22+0200` ;
- taille : `1 453 954` octets ;
- deux lectures espacées de trois secondes ont donné la même empreinte.

Ce point de coupe est une photographie, pas une baseline promue. Les pourcentages portent d'abord sur les capacités du moteur et restent valables même si le contenu continue d'évoluer.

## 5. Inventaire du snapshot Selbrume observé

| Élément | Quantité observée | Commentaire |
|---|---:|---|
| Maps dans le manifeste | 10 | la spécification canonique en énumère 9 ; l'écart doit être expliqué, pas forcément supprimé |
| Storylines | 4 | toutes au statut `draft` |
| Chapitres | 7 | 4 principaux + chapitres de quêtes annexes |
| Story Steps | 26 | 37 liens Step → Scene |
| Events V2 | 27 | 9 `entityInteract`, 16 `triggerEnter`, 2 `outcomeReceived` ; tous `oneShot` |
| Scenes | 30 | 184 nœuds et 154 arêtes |
| Nœuds d'action | 70 | 42 `setFact`, 28 `completeStoryStep` |
| Facts | 46 | booléens |
| World Rules | 6 | essentiellement visibilité et override de dialogue |
| Cinematics | 16 | 15 timelines Selbrume réduites à un unique `wait` ; 1 prototype non Selbrume plus riche |
| Dialogues déclarés | 12 | tous avec `declaredOutcomes: []` |
| Trainers | 5 | Lysa, deux gardiens et confrontation finale inclus dans les graphes observés |
| Encounter tables | 1 | couverture faible pour une campagne de 2–3 h |
| Scripts | 0 | le flux canonique repose sur Event V2/Scenes |

La structure est nettement plus avancée que le niveau de preuve runtime. Cinq Facts n'ont pas de producteur Scene : `fact_test`, hors périmètre, et les quatre Facts fonctionnels suivants :

- `fact_starter_received`, faux par défaut : blocage du chemin starter A ;
- `fact_player_started_with_existing_pokemon`, **vrai par défaut** : configuration B déjà résolue, pas un blocage autonome ;
- `fact_goelise_object_returned`, faux par défaut : aucun outcome Yarn ne le produit ;
- `fact_goelise_object_kept`, faux par défaut : aucun outcome Yarn ne le produit.

Les blocages non résolus sont donc le chemin starter A et les deux résultats du choix Goélise. Une simulation d'atteignabilité optimiste — sources supposées activables, victoires de combat accordées et sans jouer les overlays — atteint **26 Events sur 27**. Le seul Event restant bloqué est le retour au pêcheur, qui exige `fact_goelise_object_returned = true`. Cette simulation n'est pas un walkthrough.

Le manifeste documente lui-même les limites actuelles :

- `selbrume.activeStarterConfiguration = existingPokemon` ;
- `selbrume.starterChoiceStatus = blocked_missing_give_pokemon_consequence` ;
- `selbrume.dialogueChoicePersistenceStatus = blocked_missing_yarn_outcome_binding` ;
- `selbrume.sideQuestRewardStatus = authored_narratively_runtime_reward_pending` ;
- `selbrume.cinematicStatus = semantic_runtime_v1`.

## 6. Ce qui va bien

### 6.1 Architecture et contrats

- `map_core` possède des modèles explicites pour Storyline, Chapter, Story Step, Scene, Cinematic, Fact, World Rule et Event V2.
- Les frontières de packages sont globalement respectées : contrats dans `map_core`, mutations de progression dans `map_gameplay`, orchestration dans `map_runtime`, authoring dans `map_editor`.
- Les Scenes ont un graphe sérialisable avec nœuds start/end, dialogue Yarn, cinematic, battle, action et branches de combat.
- Les références croisées, graphes, Facts, World Rules et cinematics disposent de diagnostics ciblés bien testés.

### 6.2 Event V2 et Scenes runtime

- Les quatre sources nécessaires au slice existent : `mapEnter`, `triggerEnter`, `entityInteract` et `outcomeReceived`.
- La coordination Event V2 applique l'autorité de dispatch et la consommation automatique d'un Event `oneShot` après succès ; l'absence de nœud explicite `markEventConsumed` dans les Scenes n'est donc pas, à elle seule, une anomalie.
- Le runner de Scene sait suspendre l'exécution pendant dialogue, cinematic et battle, puis appliquer atomiquement les conséquences prises en charge.
- Les branches victoire/défaite de Lysa existent dans le snapshot courant et les deux Scenes post-combat complètent `step_rival_battle`.

### 6.3 Gameplay et persistance génériques

- Le moteur de combat sait préparer des rencontres trainer/wild, renvoyer victoire/défaite, écrire les PV, mettre à jour la party et enregistrer un trainer vaincu.
- Les mutations gameplay savent déjà donner un Pokémon, un objet ou de l'argent dans d'autres contrats legacy/génériques.
- La sauvegarde générique couvre party, PC/boxes, bag, argent, progression, Facts, Story Steps, Event V2 consommés et outbox.
- Des tests frais prouvent des slices Selbrume isolées : première interaction, capture, premier combat trainer et sauvegarde/rechargement.

### 6.4 Éditeur no-code

- Une navigation Narrative Studio spécialisée existe, avec Overview, Storylines, Scenes, Events, Cinematics, Dialogues, Facts et World Rules.
- Dialogues : création, import, renommage, suppression, dossiers et fichier Yarn réel sont couverts.
- Facts/World Rules : la base d'authoring est utilisable et les diagnostics sont solides.
- Cinematic Builder : les surfaces savent représenter acteurs, placements, mouvements, caméra, timeline et points de scène ; le problème est désormais surtout le playback runtime et la vraie densité des timelines Selbrume.
- Event Builder V2 permet de choisir une source, des conditions, une Scene, une politique de réutilisation et une priorité.

## 7. Ce qui ne va pas ou reste incomplet

### 7.1 Blocage P0 — choix Yarn sans conséquence exploitable

Le runtime peut afficher des options et suivre des jumps Yarn, mais son contrat public n'expose pas d'outcome de dialogue. `packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart:343` le dit explicitement. Le test `scene_dialogue_runtime_awaitable_adapter_test.dart` vérifie même que l'adaptateur n'invente pas d'outcome.

Conséquences pour Selbrume :

- le ton `confident` / `hesitant` / `aggressive` face à Lysa ne peut pas alimenter proprement une branche ;
- le choix du port ne peut pas durablement modifier la foule ou les dialogues ;
- accepter/refuser la quête de Mado n'est pas raccordé ;
- rendre/garder l'objet du Goélise ne produit aucun Fact ;
- les branches `branchByOutcome` sont modélisées, mais l'UI les désactive avec `mapping futur requis` dans `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart:1501`.

La convergence post-combat de Lysa n'utilise pas `branchByOutcome` : elle repose sur deux Events V2 `outcomeReceived`, vers `scene_rival_after_win` et `scene_rival_after_loss`. C'est un raccord valide pour les outcomes de combat. En revanche, `branchByOutcome` reste réellement inutilisable : les diagnostics le marquent unsupported dans `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart:284-287` et le plan builder runtime le rejette dans `packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart:42` et `:137`.

### 7.2 Blocage P0 — conséquences Narrative Scene trop étroites

Le contrat canonique `SceneConsequence` ne propose que :

- `setFact` ;
- `markEventConsumed` ;
- `completeStoryStep`.

Il est défini dans `packages/map_core/lib/src/models/scene_consequence.dart:3-27` et exécuté dans `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart:52-61`.

Les mutations `givePokemon`, give item et money existent ailleurs, mais ne sont pas authorables comme conséquences de Scene. Cela bloque : starter, récompenses de Mado, récompenses de quêtes annexes, objets trouvés/rendus, argent et récompense finale. Ajouter seulement le contenu ne contourne pas ce manque de capacité produit.

### 7.3 Blocage P0 — nouvelle partie et starter

Le builder de nouvelle partie peut construire un état valide, mais le starter des tests est injecté directement par une mutation. Il n'existe pas de boucle complète : détection party vide → choix guidé → attribution → confirmation → Fact → activation de l'étape suivante. Le snapshot actuel choisit explicitement la configuration B « Pokémon déjà présent » et marque la configuration starter comme bloquée.

Pour respecter `selbrume.md`, les deux chemins doivent converger vers le même contrat de progression et être sauvegardables.

### 7.4 Blocage P0 — projet courant non vert en intégration

Deux problèmes frais empêchent tout verdict READY :

- le test J5 attend le hash `8689d1d9736b543863e40806c1640a76dc8b395a928313f529c0b0384d455167`, alors que le snapshot courant vaut `f22c2bf0…` ;
- `selbrume_event_v2_three_source_integration_test.dart` finit à `4 PASS / 2 FAIL` : deux cas projet promu expirent après l'entrée dans des Scenes désormais awaitables, alors que les variantes fixture passent.

Les logs prouvent au moins pour l'entrée du port que la source Event est résolue, `scene_port_entry` est lancée, Yarn est parsé et l'overlay de dialogue s'ouvre ; le harness attend ensuite la consommation terminale sans avancer le nouveau dialogue/cinematic awaitable. La gate est bien rouge, mais ce résultat ne prouve pas un défaut de résolution de la source Event. Le hash signale de son côté une baseline de promotion périmée, pas un défaut moteur. Il faut réconcilier baseline et harness, puis terminer les overlays et prouver la consommation `oneShot`.

### 7.5 Blocage P1 — cinématiques sémantiques mais non visuelles

`PlayableMapGame` instancie `SceneCinematicRuntimeNoVisualPlayer` dans `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:7460`. Ce player résout la timeline et attend sa durée, mais ne joue ni mouvement d'acteur, ni caméra, ni fade, ni emote, ni son, ni FX dans le jeu.

Le contenu confirme le problème : les 15 cinematics Selbrume sont des placeholders d'un seul `wait`. Seul `cinematic_uwu`, prototype hors campagne canonique, contient une timeline riche. Les IDs existent, mais l'expérience narrative voulue n'existe pas encore à l'écran.

### 7.6 Blocage P1 — World Rules insuffisantes pour les transformations du monde

Les sources couvrent Fact, Story Step complété et Event consommé. Les cibles/effets couvrent surtout visibilité d'entité, override de dialogue et activation d'Event. Cela convient pour masquer Lysa ou changer une réplique, mais pas pour :

- ouvrir réellement un passage ou une porte ;
- changer collision/pathfinding ;
- activer/désactiver un objet de carte complexe ;
- changer ambiance, météo, brouillard ou tiles ;
- matérialiser la résolution du phare.

Pour Selbrume, l'ouverture du Passage des Dames et la dissipation de la brume ont besoin d'effets environnementaux de production, pas seulement de Facts.

### 7.7 Blocage P1 — Validator non global

Le Validator est intentionnellement absent de la navigation produit, documenté dans `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_destination.dart:4`. Les diagnostics actuels sont utiles mais locaux.

La gate Selbrume doit dériver du projet, sans booléens injectés, au minimum :

- atteignabilité des Story Steps et des 27 Events ;
- références map/entity/trigger/dialogue/cinematic/trainer ;
- production et consommation des Facts ;
- fermeture des outcomes Yarn et battle ;
- présence des conséquences de récompense ;
- convergence des branches ;
- couverture de checkpoints save/load ;
- absence de Scene orpheline ou de contenu `draft` bloquant.

Le test beta actuel reçoit notamment `hasSaveLoadSupport: true` comme information externe : son PASS ne démontre donc pas le save de la campagne.

### 7.8 Fidélité de la confrontation finale

Le flow générique de static encounter existe surtout via le contrat `Scenario` legacy et ses tests. Dans le contenu Selbrume courant, `scene_final_pokemon` lance au contraire un combat `trainer` vers `trainer_boss_phare_pokemon`. Cela permet une victoire/défaite et ferme la branche victoire, mais ne prouve pas une vraie rencontre Pokémon statique avec politique de capture, consommation, réapparition ou apaisement propre au canon.

Ce choix peut être accepté comme simplification MVP, mais il doit être explicite. Sinon, le moteur et l'éditeur doivent fermer le contrat static encounter Event V2/Scene et ses conséquences.

### 7.9 Dette produit de l'éditeur

- Overview lit encore une vision legacy `Scenario/globalStory` tandis que Storylines repose sur `StorylineAsset`.
- Storyline Graph visualise surtout la structure ; les conditions et outcomes ne sont pas un langage auteur complet.
- Il n'existe pas de Map Events View consolidée montrant, sur une carte, tous les événements et leur état de raccordement.
- Event Builder V2 ne porte pas directement les récompenses, changements de monde, activation d'étape, timer ou orchestration multi-actions.
- Les Facts sont booléens ; aucun compteur/quantité n'est prévu pour les collectes sans multiplier les Facts.
- La persistance éditeur reste fragmentée : dialogues et Event V2 ont des chemins disque plus affirmés que plusieurs autres surfaces du manifeste.

## 8. Écarts de contenu et ambiguïtés des spécifications

Même avec les capacités moteur complétées, les documents demandent une passe de normalisation :

- `step_unlock_passage` est cité mais n'a pas de fiche détaillée et chevauche `step_report_to_soline` ;
- plusieurs Steps n'explicitent pas leur condition d'activation ou de complétion ;
- `scene_starter_choice` n'est pas défini complètement dans la spécification ;
- plusieurs références Yarn sont citées sans fiche de dialogue correspondante ;
- l'outcome `aggressive` de Lysa n'a pas de traitement canonique clair ;
- Mado peut produire `refuse_for_now`, mais le flux décrit déverrouille tout de même la quête ;
- le chemin « Pokémon déjà existant » ne décrit pas clairement l'activation de l'aller au port ;
- l'activation de la confrontation finale est incomplète dans le document ;
- la politique après défaite du boss n'est pas tranchée ;
- les équipes, récompenses, starters et timelines cinématiques sont seulement partiellement spécifiés ;
- le contrat de sauvegarde ne définit pas les checkpoints et invariants de round-trip attendus ;
- la cible 2–3 h de Selbrume est plus large que la Golden Slice générique 30–60 minutes de la roadmap.

Le snapshot courant fait des choix raisonnables, par exemple une configuration B « party existante » et une défaite du boss qui ne résout pas la brume, mais ces choix doivent devenir des décisions produit canoniques, pas seulement des métadonnées de seed.

## 9. Matrice de capacité par package

| Package | Verdict | Capacité présente | Manque déterminant pour Selbrume |
|---|---|---|---|
| `map_core` | `PARTIAL` | modèles, JSON, graphes, diagnostics | outcomes Yarn publics, conséquences de récompense, World Rules environnementales, validator global |
| `map_gameplay` | `PARTIAL` | Facts, étapes, party/bag/PC, mutations, save state | orchestration de starter et récompenses depuis le contrat narratif |
| `map_battle` | `PARTIAL` à fort | moteur de combat générique | preuve des combats Lysa/gardiens/boss joués, progression et récompenses de campagne |
| `map_runtime` | `PARTIAL` | Event V2, Scene runner, dialogue, battle handoff, sauvegarde | outcomes Yarn, playback cinematic visuel, deux intégrations projet courant rouges |
| `map_editor` | `PARTIAL` | majorité des surfaces auteur et diagnostics ciblés | fermeture no-code des branches/conséquences, Map Events, Validator, persistance homogène |
| host jouable | `PARTIAL` | fixtures et slices ciblées | vrai walkthrough du projet promu, sans callbacks simulés |

## 10. Passe Tests — verdict strict `FAIL`

Les tests prouvent des briques solides, mais pas Selbrume de bout en bout.

| Exigence | Prouvé | Non prouvé ou rouge |
|---|---|---|
| Projet promu | chargement et assertions riches prévues | hash J5 périmé, test arrêté avant les assertions runtime |
| Event V2 | fixtures Lysa/indice/port vertes | 2 timeouts sur le projet courant |
| Nouvelle partie | état, party/bag et round-trip | starter ajouté directement, aucun choix runtime |
| Scene Lysa | intents dialogue/cinematic/battle et outcomes simulés | choix Yarn, cinematic et combat joué non prouvés |
| Combat trainer | write-back, progression, argent, save | victoire contrôlée, pas une partie Lysa jouée par input |
| Sauvegarde | round-trips mémoire/disque génériques | aucun parcours mid-quête/choix/annexe complet |
| Validator | diagnostics graph/références et prérequis génériques | pas d'atteignabilité globale ni de preuve save dérivée |
| Campagne | test courant de 4 Scenes avec 2 cas verts | appels directs et callbacks simulés ; rival, indices, quêtes et traversal sautés |

Angles morts de preuve :

- aucun test ne réalise les 12 étapes dans l'ordre depuis une vraie nouvelle partie ;
- aucun test ne ferme les trois quêtes annexes et leurs récompenses ;
- aucun outcome Yarn réel n'alimente une branche de Scene ;
- aucun playback cinematic visuel n'est branché ;
- aucun combat Lysa n'est joué via overlay/input jusqu'au résultat ;
- aucun save/reload n'est exécuté au milieu des indices, cristaux, choix Lysa ou boss ;
- aucun validator ne prouve l'atteignabilité de la campagne entière.

## 11. Commandes et résultats frais

### 11.1 Inventaire et contrôle du snapshot

```bash
git status --short --untracked-files=all
git rev-parse --abbrev-ref HEAD
git rev-parse HEAD
shasum -a 256 selbrume/project.json
stat -f '%Sm|%z|%i' -t '%Y-%m-%dT%H:%M:%S%z' selbrume/project.json
jq '{maps:(.maps|length), dialogues:(.dialogues|length), scripts:(.scripts|length), scenarios:(.scenarios|length), cinematics:(.cinematics|length), facts:(.facts|length), worldRules:(.worldRules|length), scenes:(.scenes|length), storylines:(.storylines|length), trainers:(.trainers|length), characters:(.characters|length), encounterTables:(.encounterTables|length)}' selbrume/project.json
jq '{events:(.eventRegistry.records|length), eventSourceKinds:([.eventRegistry.records[].definition.source.kind]|group_by(.)|map({kind:.[0],count:length})), oneShot:([.eventRegistry.records[]|select(.definition.reusePolicy=="oneShot")]|length)}' selbrume/project.json
jq '{storylines:(.storylines|length), chapters:([.storylines[].chapters[]?]|length), steps:([.storylines[].chapters[]?.steps[]?]|length), stepSceneLinks:([.storylines[].chapters[]?.steps[]?.sceneLinkIds[]?]|length), statuses:([.storylines[].status]|group_by(.)|map({status:.[0],count:length}))}' selbrume/project.json
jq '{actionKinds:([.scenes[].graph.nodes[]?.payload.consequence?.kind]|group_by(.)|map({kind:.[0],count:length})), nodeKinds:([.scenes[].graph.nodes[]?.kind]|group_by(.)|map({kind:.[0],count:length})), graphNodeCount:([.scenes[].graph.nodes[]?]|length), graphEdgeCount:([.scenes[].graph.edges[]?]|length), sceneOutcomeCount:([.scenes[].declaredOutcomes[]?]|length)}' selbrume/project.json
jq -r '[.scenes[].graph.nodes[]? | select(.payload.kind=="action") | .payload.consequence | select(.kind=="setFact") | .factId] | unique[]' selbrume/project.json
```

Résultat utile : branche/HEAD ci-dessus ; snapshot `f22c2bf0…` stable sur deux lectures de trois secondes ; inventaire donné en section 5.

### 11.2 Diagnostics core ciblés

Depuis `packages/map_core` :

```bash
dart test test/golden_slice_readiness_test.dart test/scene_diagnostics_test.dart test/world_rule_diagnostics_test.dart test/cinematic_diagnostics_test.dart test/narrative_validator_test.dart
```

Résultat : **exit 0, 110/110 tests passés**.

### 11.3 Éditeur ciblé

Depuis `packages/map_editor` :

```bash
flutter test test/ui/canvas/narrative_studio_destination_test.dart test/features/narrative/application/overview/narrative_overview_read_model_test.dart test/storylines_current_global_story_characterization_test.dart test/scenes_workspace_shell_test.dart test/narrative_event_builder_v2_use_case_test.dart test/dialogue_disk_hierarchy_v13_test.dart test/facts_world_rules_manager_test.dart test/cinematics_library_workspace_test.dart
```

Résultat : **exit 0, `+131: All tests passed!`**. La résolution des dépendances de ce run a actualisé `packages/map_editor/pubspec.lock`, qui était déjà modifié au début de l'audit ; ce side effect est documenté en section 16.

### 11.4 Slices runtime P6

Depuis `packages/map_runtime` :

```bash
flutter test test/p6_selbrume_first_narrative_interaction_test.dart test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart test/p6_selbrume_first_trainer_battle_golden_slice_test.dart test/p6_selbrume_save_load_golden_slice_test.dart
```

Résultat : **exit 0, 4/4 tests passés**.

### 11.5 Projet promu et campagne simulée sur le snapshot final

Depuis `examples/playable_runtime_host` :

```bash
flutter test --reporter=compact test/selbrume_event_v2_promoted_project_test.dart test/selbrume_canonical_narrative_campaign_test.dart
```

Résultat : **exit 1, 2 passés / 1 échec**. L'échec est le hash J5 : attendu `8689d1…`, obtenu `f22c2bf…`. Les deux tests de campagne passent, mais appellent directement quatre Scenes et simulent dialogue/cinematic/battle ; ils ne constituent pas un E2E jouable.

### 11.6 Sources Event V2 par hooks de production

Depuis `packages/map_runtime` :

```bash
flutter test --reporter=compact test/selbrume_event_v2_three_source_integration_test.dart
```

Résultat : **exit 1, 4 passés / 2 échecs**. Les deux cas projet promu expirent après dispatch dans les nouvelles opérations awaitables ; les variantes fixture passent. Les logs du port montrent la Scene résolue et le dialogue ouvert avant le timeout : la gate/harness est obsolète, sans démontrer à elle seule une panne de résolution Event V2.

### 11.7 Vérifications non lancées

- pas de suite complète de chaque package : l'audit privilégie les gates narratives ciblées et le worktree est très actif ;
- pas de `dart analyze` / `flutter analyze` global : aucune modification de code n'a été réalisée, et une analyse verte ne prouverait pas le walkthrough ;
- pas de build release : hors du besoin « état des capacités » et non probant pour la campagne ;
- pas de walkthrough GUI manuel de 2–3 h : c'est précisément la preuve manquante à construire.

## 12. Verdict des sub-agents / passes indépendantes

| Passe | Verdict | Conclusion |
|---|---|---|
| Audit spécification | `PASS` pour l'extraction, `PARTIAL` pour la fermeture | cible canonique inventoriée ; contradictions et fiches manquantes empêchent un contrat totalement fermé |
| Audit éditeur/authoring | `PARTIAL` | Narrative Studio ≈ 50 %, fermeture auteur directe de Selbrume ≈ 40 % |
| Audit moteur/runtime | `PARTIAL` | capacité technique 60–65 %, démonstrateur end-to-end 45–55 % |
| Tests | **`FAIL` strict** | unités/slices nombreuses au vert, mais hash et deux intégrations fraîches au rouge ; aucun E2E complet |
| Build/Validation | `PARTIAL`, gate READY `FAIL` | diagnostics ciblés verts ; validator global, playback et campagne manquent |
| Critique finale | `PASS` sur la conclusion, `PARTIAL` sur le niveau de preuve | scores et verdict global confirmés ; corrections de précision intégrées ; aucune conclusion READY |

## 13. Lots roadmap concernés — proposition de statut, sans modification

L'audit ne propose **aucun lot `DONE`**. Les statuts ci-dessous sont des recommandations à confirmer par une passe de clôture dédiée :

| Lots | Statut proposé | Motif |
|---|---|---|
| `FG-000` | `PARTIAL` | baseline narrative complète, pas audit repo-wide de toute la mécanique |
| `FG-010`, `FG-011`, `FG-014`, `FG-016` | `PARTIAL` | nouvelle partie/party/save présents, flux starter et campagne non fermés |
| `FG-012`, `FG-013`, `FG-103` | `BLOCKED` ou `TODO` | modèle/flow starter et Gift Pokémon non fermés depuis Narrative Studio |
| `FG-020`, `FG-021`, `FG-024`, `FG-025` | `PARTIAL` | party/PC/bag génériques, intégration narrative/reward incomplète |
| `FG-040` à `FG-052` | `PARTIAL` à absent selon le sous-lot | persistance combat présente ; PP/status/XP/level/moves/évolution/reward presentation et certains cas UX ne sont pas tous prouvés pour Selbrume |
| `FG-060`, `FG-064`, `FG-067`, `FG-068` | `PARTIAL` à `TODO` | registry d'items, key-item gates, pickup et hidden item ne sont pas fermés via les conséquences Narrative Scene ni prouvés en campagne |
| `FG-080` à `FG-094` | `PARTIAL` à `TODO` selon le sous-lot | commandes, conditions, executor, Action Builder et templates existent à des degrés différents ; choix, récompenses et world changes manquent |
| `FG-100`, `FG-102`, `FG-107`, `FG-108` | `PARTIAL` à `TODO` | audit/validation d'encounters partiels ; static encounter surtout legacy, consommation et authoring Selbrume non prouvés |
| `FG-140`, `FG-141`, `FG-145`, `FG-146` | `PARTIAL` | trainer defeated, dialogue post-battle et follow-up rival existent partiellement ; le progression validator ne détecte pas encore la campagne impossible |
| `FG-147` | `TODO` à `PARTIAL` | aucun walkthrough complet automatisé et joué |
| `FG-163`, `FG-165` | `PARTIAL` | menus/handoff utiles, pas évalués comme boucle complète ici |
| `FG-180`, `FG-181` | `PARTIAL` | socle projet/maps riche, état concurrent et preuves d'usage incomplètes |
| `FG-182` | `BLOCKED` | contenu narratif canonique non entièrement exécutable |
| `FG-183` | `PARTIAL` | plusieurs matrices de tests existent, sans preuve globale verte |
| `FG-184`, `FG-185` | `TODO` | dashboard generator et release gate non prouvés par cet audit ; la gate fonctionnelle observée est rouge |

Le lot narratif **N1** est proposé comme livrable d'audit par le présent rapport, après intégration de la critique et du statut Git final ; aucun statut de roadmap n'est modifié. Le lot **N13 — Lysa Golden Slice** est avancé, mais ne doit pas être confondu avec la readiness du démonstrateur complet.

## 14. Ordre recommandé pour terminer Selbrume

### P0 — rendre la boucle narrative réellement fermable

1. Figer une baseline Selbrume promue et réconcilier le hash, les maps, les dialogues et le harness Event V2.
2. Corriger les deux timeouts du projet réel et garder les variantes fixture comme tests de caractérisation.
3. Définir un contrat Yarn `choice/outcome` qualifié, le persister et le rendre sélectionnable dans Scene Builder.
4. Étendre les conséquences de Scene : donner/retirer objet, donner Pokémon, argent, récompense idempotente, éventuellement warp/transition.
5. Implémenter les deux chemins Maël : starter si party vide et convergence avec party existante.
6. Fermer les choix Lysa, Mado et Goélise avec Facts, dialogues post-choix et récompenses.

### P1 — rendre l'expérience visible et cohérente dans le monde

7. Brancher un player cinematic visuel de production puis remplacer les 15 placeholders Selbrume par de vraies timelines.
8. Étendre les World Rules aux portes, collisions, passages, objets, brouillard/ambiance et état du phare.
9. Clarifier le boss : nature de la rencontre, défaite, retry, récompense et condition exacte de dissipation.

### P1/P2 — prouver le démonstrateur

10. Construire un Validator Selbrume dérivé uniquement du projet, accessible depuis Narrative Studio.
11. Ajouter un parcours E2E par checkpoints : new game, port/Lysa, trois indices, passage, phare, boss, épilogue, trois quêtes annexes.
12. À chaque checkpoint, sauver/recharger et vérifier idempotence des événements, récompenses et branches.
13. Faire un walkthrough manuel de la build cible, relever la durée, les blocages, les dialogues et les états du monde, puis seulement proposer les lots `DONE`.

## 15. Fichiers et zones inspectés

Principaux contrats/code :

- `packages/map_core/lib/src/models/scene_consequence.dart` ;
- `packages/map_core/lib/src/models/world_rule.dart` ;
- `packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart` ;
- `packages/map_core/lib/src/diagnostics/` ;
- `packages/map_gameplay/lib/src/game_state_mutations.dart` ;
- `packages/map_runtime/lib/src/application/scene_runtime/` ;
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` ;
- `packages/map_editor/lib/src/ui/canvas/narrative_studio/` ;
- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart` ;
- `packages/map_editor/lib/src/ui/canvas/events_v2/`.

Contenu et spécifications :

- `MVP Selbrume/narrative_studio.md` ;
- `MVP Selbrume/selbrume.md` ;
- `selbrume/project.json` ;
- `selbrume/maps/` ;
- `selbrume/dialogues/`.

Preuves historiques consultées sans les substituer aux runs frais :

- `reports/narrativeStudio/ns_studio_product_beta_readiness_audit.md` ;
- `reports/narrativeStudio/ns_studio_product_beta_readiness_evidence_pack.md` ;
- `reports/narrativeStudio/events/ns_event_34_runtime_handoff_smoke_editor_authored_scene_target_gate.md` ;
- `reports/narrativeStudio/events/ns_event_35_trigger_variants_runtime_handoff_lifecycle_semantics_gate.md` ;
- `reports/narrativeStudio/events/ns_event_v2_phase_j_selbrume_golden_slice_evidence_pack.md` ;
- plans/audits Scenes V1-137/V1-138 et rapports de fermeture Facts/World Rules associés.

Les preuves historiques portent parfois sur d'autres révisions, dont `2f683…`, et ne valent pas preuve fraîche pour le HEAD `f93b70…` et le snapshot Selbrume volatil courant.

## 16. Fichiers modifiés par cet audit

### Créé

- `reports/gameplay/fg_000_narrative_studio_selbrume_readiness_audit.md` — le présent rapport ; toutes ses lignes sont nouvelles et son contenu complet constitue l'artefact livré.

### Code et tests

- aucun fichier Dart modifié ;
- aucun test créé ou modifié par l'audit ;
- aucune roadmap modifiée ;
- aucune opération Git d'écriture effectuée.

### Side effect de validation sur un fichier déjà dirty

- `packages/map_editor/pubspec.lock` était déjà `M` dans l'état initial. La résolution déclenchée par le run éditeur a actualisé les zones suivantes dans le diff courant : `matcher 0.12.19 → 0.12.20`, `meta 1.18.0 → 1.19.0`, `test_api 0.7.11 → 0.7.12`, `vector_math 2.2.0 → 2.4.0`, avec leurs SHA. Il n'a pas été restauré, car l'état antérieur non committé appartient au worktree utilisateur et une restauration aurait été destructive.

Les autres changements visibles dans le worktree, y compris `selbrume/project.json`, les maps/dialogues, les fichiers Narrative Studio et les nouveaux tests/outils de seed, sont préexistants ou proviennent d'un travail concurrent. Ils ne sont pas revendiqués par cet audit.

### État Git final — résumé et extrait ciblé

```text
photographie : 2026-07-18T12:37:07+0200
222 entrées : 70 modifiées/autres, 3 supprimées, 149 non suivies
répartition : packages 74, selbrume 85, reports 61, examples 1, design-qa.md 1
empreinte SHA-256 du porcelain : a18980b744943dba7381f6553cdd33c678fa6f4369924a7093c3802bcfd0140e
 M packages/map_editor/pubspec.lock
 M selbrume/project.json
?? reports/gameplay/fg_000_narrative_studio_selbrume_readiness_audit.md
```

Le porcelain complet comporte 222 lignes et n'est pas recopié intégralement ici ; il est reproductible avec `git status --short --untracked-files=all`. Le résumé, l'empreinte et l'extrait ci-dessus constituent la photographie contrôlée. Toute évolution concurrente ultérieure ne doit pas être attribuée à l'audit.

## 17. Auto-critique et risques

1. **Snapshot volatil.** Le contenu Selbrume a changé pendant la lecture. L'inventaire est exact pour `f22c2bf0…`, pas garanti pour une révision ultérieure.
2. **Pas de walkthrough visuel complet.** L'audit inspecte contrats, contenu et tests, mais ne remplace pas une partie humaine de 2–3 h.
3. **Pourcentage de maturité, pas couverture.** Le 50 % est un score de fermeture fonctionnelle pondéré, avec ±5 points d'incertitude ; ce n'est ni un taux de lignes ni un nombre de tâches.
4. **Spécification contradictoire.** Certains écarts peuvent être résolus par une décision produit plutôt que par du code ; ils restent bloquants tant que la décision n'est pas canonique.
5. **Tests simulés.** Plusieurs « Golden Slices » appellent directement des Scenes ou contrôlent les outcomes ; ils surévalueraient la readiness si on les lisait comme des parcours joués.
6. **Vérification ciblée.** Les suites complètes, analyses statiques et builds n'ont pas été relancés ; le verdict ne prétend donc pas à une santé globale du monorepo.
7. **Risque de double système.** Tant que Scenario legacy et Storyline/Scene/Event V2 coexistent dans les surfaces produit, des auteurs peuvent configurer un état que le runtime ne consomme pas de la façon attendue.

## 18. Conclusion

Le Narrative Studio n'est plus un prototype vide : il dispose d'une vraie architecture auteur et d'un runtime narratif crédible. Le problème principal n'est plus « pouvoir stocker une histoire », mais **fermer les interactions qui donnent du sens à cette histoire** : choix, conséquences, récompenses, transformations du monde, cinématiques visibles et validation end-to-end.

Le démonstrateur complet Selbrume doit donc rester **`PARTIAL`, environ 50 %**, et **ne peut pas être proposé `DONE` ou READY** sur les preuves actuelles. Le chemin le plus court n'est pas d'ajouter encore des IDs ou des Scenes ; il est de terminer les contrats transverses P0, de stabiliser le projet promu, puis de prouver une campagne réellement jouée et sauvegardée.
~~~~~~
### `reports/gameplay/fg_000_narrative_studio_selbrume_capability_matrix.md`

- Taille : `20059` octets
- SHA-256 : `dad259029390fe08fc54a855e4ca2110aff51fed848983bc528786bbeb24356c`

~~~~~~markdown
# Matrice précise — Narrative Studio et démonstrateur Selbrume

Date : 18 juillet 2026<br>
Source : `reports/gameplay/fg_000_narrative_studio_selbrume_readiness_audit.md`<br>
Baseline de contenu : `selbrume/project.json`, SHA-256 `f22c2bf0b8b935a781c4e1c70db83d56ed956583118e3ea2d3427bca7f851141`<br>
Verdict hérité de l'audit : Narrative Studio **50 %**, capacité moteur/runtime **62 %**, démonstrateur complet **environ 50 % et non prêt**

## Légende

| État | Signification |
|---|---|
| `PRÊT` | La capacité ciblée existe et dispose d'une preuve fraîche suffisante pour être utilisée dans Selbrume. |
| `PARTIEL` | Le socle existe, mais un cas important, une intégration ou une preuve manque. |
| `MANQUANT` | Le contrat produit/runtime requis n'existe pas encore. |
| `BLOQUÉ` | Le contenu existe, mais ne peut pas être terminé avec les capacités actuelles. |
| `GATE ROUGE` | Une vérification fraîche échoue ; aucune readiness ne peut être déclarée. |

`PRÊT` désigne une capacité isolée, pas un lot roadmap `DONE`. Aucun lot mécanique n'est proposé `DONE` dans l'audit parent.

## 1. Matrice des capacités du Narrative Studio et du moteur

| Domaine | Élément | État | Ce qui est prêt | Ce qui manque exactement | Impact sur Selbrume | Priorité |
|---|---|---|---|---|---|---|
| Données | Modèles et JSON narratifs | `PRÊT` | Storyline, Chapter, Step, Scene, Event V2, Fact, World Rule et Cinematic sont structurés et sérialisables. | Pas de manque bloquant pour stocker la structure actuelle. | Le projet peut représenter une campagne riche sans JSON manuel côté utilisateur. | — |
| Données | Références du snapshot | `PARTIEL` | 30 Scenes, 27 Events, 46 Facts, 16 cinematics et 12 dialogues sont déclarés ; les références structurales principales sont valides. | L'atteignabilité n'est qu'optimiste : 26 Events sur 27 ; aucune preuve de parcours réel complet. | Le volume de contenu ne garantit pas sa jouabilité. | P0 |
| Navigation | Shell Narrative Studio | `PARTIEL` | Navigation spécialisée vers Overview, Storylines, Scenes, Events, Cinematics, Dialogues, Facts et World Rules. | Validator absent ; convergence UI et persistance encore inégales. | L'auteur peut accéder aux principaux outils, mais pas fermer le projet depuis un seul endroit. | P1 |
| Overview | Vue d'ensemble | `PARTIEL` | Résumé et accès aux espaces narratifs. | Une partie repose encore sur `Scenario/globalStory` legacy au lieu de la source canonique Storyline/Scene/Event V2. | Risque d'afficher un état différent de celui réellement exécuté. | P1 |
| Storylines | Board, chapitres et Steps | `PARTIEL` | 4 Storylines, 7 chapitres et 26 Steps sont authorés ; 37 liens Step → Scene. | Statut `draft` partout ; conditions d'activation, outcomes et progression globale incomplets. | La structure Selbrume est visible, mais sa progression n'est pas démontrée. | P0 |
| Storylines | Graph de progression | `PARTIEL` | Visualisation structurelle des Storylines et Steps. | Pas de langage complet pour conditions, branches, convergence et outcomes. | Impossible d'auditer visuellement toute la campagne et ses chemins. | P1 |
| Scenes | Library et graphes de base | `PRÊT` | Start/end, dialogue, cinematic, battle, action, arêtes et diagnostics sont utilisables. | Aucun manque pour les séquences linéaires et branches de combat simples. | Les scènes principales peuvent être décrites et exécutées. | — |
| Scenes | Conséquences d'état simples | `PRÊT` | `setFact`, `completeStoryStep` et `markEventConsumed` sont modélisés, validés et exécutés. | La palette est trop courte pour les récompenses de RPG. | Les milestones narratifs et Facts peuvent avancer. | — |
| Scenes | `branchByOutcome` | `MANQUANT` | Le type existe dans le modèle. | UI désactivée (`mapping futur requis`), diagnostic unsupported et rejet par le plan builder runtime. | Les choix de dialogue ne peuvent pas piloter directement un graphe de Scene. | P0 |
| Scenes | Récompenses canoniques | `MANQUANT` | Des mutations give Pokémon/item/money existent ailleurs dans le moteur. | Aucune conséquence Scene authorable pour donner/retirer Pokémon, objet, argent ou récompense idempotente. | Bloque starter, récompenses de Mado, Goélise, cabane et récompense finale. | P0 |
| Events V2 | Sources de déclenchement | `PRÊT` | `mapEnter`, `triggerEnter`, `entityInteract` et `outcomeReceived` existent dans le moteur. | Pas de manque structurel pour les déclencheurs Selbrume actuels. | Maël, port, indices, NPC et follow-ups battle peuvent être raccordés. | — |
| Events V2 | Conditions sur Facts | `PRÊT` | Conditions booléennes testées et utilisées dans le projet. | Pas de variables/counters ni de composition avancée authorable. | Suffisant pour les trois indices séparés ; moins adapté aux collectes génériques. | P2 |
| Events V2 | Politique `oneShot` | `PRÊT` | Consommation automatique après succès, autorité de dispatch et persistance save/load. | La preuve doit encore être étendue à toute la campagne réelle. | Évite les doubles scènes et doubles récompenses lorsque le flux termine. | P1 |
| Events V2 | Intégration du projet promu | `GATE ROUGE` | Les variantes fixture des trois sources passent ; les logs du port montrent source résolue, Scene lancée et dialogue ouvert. | Deux tests du projet réel expirent ensuite dans les opérations awaitables ; le harness ne ferme pas les nouveaux overlays. | La baseline courante ne peut pas être déclarée verte. | P0 |
| Events | Map Events View consolidée | `MANQUANT` | Event Builder V2 sait éditer un Event individuel. | Aucune vue globale par map montrant sources, zones, NPC, conditions, Scenes et erreurs de raccordement. | L'auteur ne peut pas contrôler rapidement les 27 Events de Selbrume. | P1 |
| Dialogues | Fichiers et authoring Yarn | `PRÊT` | Création, import, renommage, suppression, dossiers, lecture disque et sélection de nœud. | Pas de manque pour un dialogue linéaire. | Les conversations peuvent être écrites et jouées. | — |
| Dialogues | Options et jumps à l'écran | `PARTIEL` | Le runtime sait afficher des choix et suivre les jumps Yarn. | Le choix sélectionné ne devient pas un outcome public/persisté. | Le joueur peut choisir visuellement, mais le monde ne mémorise pas le choix. | P0 |
| Dialogues | Outcome Yarn → Scene/Fact | `MANQUANT` | Aucun contrat public ne l'expose aujourd'hui. | Qualifier l'outcome, le persister, le mapper dans Scene Builder et le transmettre au runtime. | Bloque ton de Lysa, panique du port, acceptation Mado et décision Goélise. | P0 |
| Facts | Facts booléens | `PRÊT` | 46 Facts, valeurs par défaut, écriture runtime, diagnostics et save/load. | Aucun manque pour des états oui/non. | Le cœur de la progression Selbrume est représentable. | — |
| Facts | Variables et compteurs | `MANQUANT` | Les collectes peuvent être simulées avec un Fact par objet. | Pas de compteur/valeur numérique réutilisable. | Non bloquant pour les 3 cristaux actuels, mais coûteux pour étendre le jeu. | P2 |
| World Rules | Visibilité et dialogue NPC | `PRÊT` | Masquer/afficher une entité, override de dialogue et activation d'Event. | Pas de manque pour changer un NPC simple après progression. | Lysa et les dialogues post-quête peuvent évoluer. | — |
| World Rules | Portes, collisions et environnement | `MANQUANT` | Les Facts déclencheurs existent. | Aucun effet complet pour collision, porte, passage, tiles, brouillard, météo, ambiance ou mécanisme du phare. | L'ouverture du Passage des Dames et la dissipation de la brume ne sont pas matérialisées proprement. | P1 |
| Cinematics | Modèle et Builder | `PARTIEL` | Timeline, acteurs, placements, déplacements, caméra, emotes et diagnostics sont authorables. | La persistance/UX complète n'est pas prouvée sur toute une campagne. | L'outil peut concevoir une cinématique, mais Selbrume n'en fournit presque pas de réelles. | P1 |
| Cinematics | Contenu Selbrume | `BLOQUÉ` | 15 IDs de cinematics canoniques existent. | Les 15 timelines Selbrume sont chacune réduites à un unique `wait`; seul un prototype hors campagne est riche. | Les moments narratifs clés n'ont pas de mise en scène réelle. | P1 |
| Cinematics | Playback runtime visuel | `MANQUANT` | Résolution de l'asset et attente de la durée. | `PlayableMapGame` utilise `SceneCinematicRuntimeNoVisualPlayer` : aucun mouvement, caméra, fade, emote, son ou FX visible. | Même une timeline complète ne serait pas jouée visuellement. | P1 |
| Validation | Diagnostics locaux | `PRÊT` | Graphes, références, Facts, World Rules, cinematics et readiness ciblée ; 110 tests core frais au vert. | Ces diagnostics ne calculent pas la campagne complète. | Les erreurs locales sont bien détectées. | — |
| Validation | Validator produit global | `MANQUANT` | Un validator beta et plusieurs diagnostics existent. | Route produit absente ; pas d'atteignabilité des Steps/Events, de fermeture des outcomes, de récompenses ou de checkpoints save dérivés du projet. | Impossible d'obtenir un verdict « Selbrume jouable » fiable depuis l'éditeur. | P0 |
| Persistance éditeur | Sauvegarde des assets auteur | `PARTIEL` | Dialogues et Event V2 ont des chemins disque affirmés. | Persistance moins homogène pour plusieurs autres surfaces du manifeste. | Risque qu'une configuration visible ne soit pas la donnée réellement promue. | P1 |

## 2. Matrice des capacités gameplay nécessaires à Selbrume

| Domaine | Élément | État | Ce qui est prêt | Ce qui manque exactement | Impact sur le démonstrateur | Priorité |
|---|---|---|---|---|---|---|
| Nouvelle partie | Construction du GameState | `PRÊT` | État initial, spawn, party/bag et validation générique sont testés. | Le flux produit complet doit encore sélectionner la configuration narrative. | Le moteur sait démarrer une partie techniquement. | — |
| Nouvelle partie | Configuration B, party existante | `PRÊT` | `fact_player_started_with_existing_pokemon` est vrai par défaut et le projet fournit une équipe initiale. | La convergence produit avec le chemin starter doit être explicitée. | La route B active permet d'avancer sans choisir un starter. | P1 |
| Nouvelle partie | Configuration A, choix du starter | `MANQUANT` | Le moteur sait ajouter un Pokémon par mutation générique. | Picker auteur, écran/runtime de choix, conséquence `givePokemon`, anti-duplication, Fact et convergence. | Le chemin prévu dans `selbrume.md` n'est pas jouable. | P0 |
| Party/Bag/PC | État et opérations génériques | `PRÊT` | Party, stockage, bag, argent, capture vers party/box et sérialisation existent. | Pas de raccord universel depuis Narrative Scene. | Les systèmes RPG de base peuvent conserver les résultats. | P0 pour le raccord |
| Sauvegarde | Round-trip générique | `PRÊT` | Party, PC, bag, argent, progression, Facts, Steps, Events consommés et outbox sont sauvegardables. | Pas de preuve longue à travers toute la campagne. | Le format sait conserver l'état narratif. | — |
| Sauvegarde | Checkpoints Selbrume | `PARTIEL` | Des slices ciblées save/load passent. | Aucun save/reload après choix Lysa, au milieu des indices/cristaux, autour du boss ou après les quêtes annexes. | Risque de duplication ou de progression perdue sur une partie de 2–3 h. | P0 |
| Combat | Trainer battle | `PRÊT` | Setup, victoire/défaite, write-back PV, trainer defeated, argent et persistance sont présents. | Les combats Selbrume ne sont pas tous joués par input réel dans un E2E. | Les combats peuvent fonctionner isolément. | P1 |
| Combat | Lysa victoire/défaite | `PARTIEL` | Deux outcomes battle et deux Events `outcomeReceived`; les deux Scenes post-combat complètent le Step. | Choix de ton absent, cinematic non visuel, combat non parcouru jusqu'au résultat par un test joueur complet. | La structure converge, l'expérience complète n'est pas prouvée. | P0 |
| Combat | Gardiens du phare | `PARTIEL` | Deux Scenes battle et Facts de victoire existent. | Pas de traversal et de combats joués end-to-end, ni de récompenses/progression démontrées. | Le mini-donjon est déclaré, pas validé comme séquence jouable. | P1 |
| Combat | Pokémon final / boss | `PARTIEL` | Victoire/défaite et branche de résolution sont authorées. | Le boss est un `trainer battle`, pas une static encounter canonique ; politique capture/retry/apaisement non fermée. | Simplification MVP possible, mais fidélité au scénario non décidée. | P1 |
| Combat | XP, level-up, moves et récompenses | `PARTIEL` | Certaines briques et tests ciblés existent. | Aucune preuve de progression cohérente sur les quatre combats et 2–3 h de jeu. | La courbe de progression de Selbrume n'est pas validée. | P1 |
| Rencontres | Wild encounter et capture | `PRÊT` pour une slice | Une Golden Slice capture/party existe et passe. | Densité, tables et équilibre de toute la campagne non définis ; une seule encounter table observée. | Suffisant pour une preuve isolée, trop faible pour une démo de 2–3 h. | P1 |
| Récompenses | Objets, argent et Pokémon depuis l'histoire | `MANQUANT` | Mutations gameplay disponibles hors contrat narratif. | Conséquences Scene authorables et idempotentes, présentation et save/reload. | Les quêtes peuvent se terminer narrativement sans donner leur récompense réelle. | P0 |
| Monde | Ouverture du Passage des Dames | `PARTIEL` | Fact et Scene de déverrouillage existent. | Effet physique sur collision/porte/passage et preuve de traversal. | Le récit peut déclarer le passage ouvert sans garantir que le joueur passe. | P0 |
| Monde | Dissipation de la brume | `PARTIEL` | Facts de résolution, Scene et cinematic ID existent. | World Rule environnementale et playback cinematic visuel. | La fin est enregistrée mais peu ou pas visible dans le monde. | P1 |

## 3. Matrice de fermeture du contenu Selbrume

| Arc ou contenu | État | Prêt dans le snapshot | Manque exact avant validation | Priorité |
|---|---|---|---|---|
| Maël — introduction | `PARTIEL` | Dialogue, Event, Scene, Facts et complétion des Steps. | Vrai choix starter A et convergence des deux configurations. | P0 |
| Port — alerte/panique | `PARTIEL` | Trigger, dialogues, Facts, Scenes et cinematics IDs. | Outcome du choix joueur et effet durable sur foule/dialogues. | P0 |
| Lysa — rencontre et combat | `PARTIEL` | NPC Event, Scene battle, victoire/défaite, deux follow-ups et convergence du Step. | Ton Yarn mémorisé, cinematic visuel et combat joué end-to-end. | P0 |
| Marais — arrivée et Mado | `PARTIEL` | Events, dialogues, Scenes et démarrage narratif. | Refus/acceptation réellement branché ; récompense de quête. | P0 |
| Trois indices | `PARTIEL` | Trois Events/Scenes/Facts et Fact agrégé. | Deux timeouts du harness à réconcilier ; traversal réel et save mid-enquête. | P0 |
| Soline — passage | `PARTIEL` | Conditions, dialogue, Fact et Step. | Transformation physique du passage et traversée prouvée. | P0 |
| Cristaux de sel | `PARTIEL` | Trois collectes, Facts, retour Mado et Steps. | Récompense réelle, idempotence et save/reload de la quête. | P0 |
| Goélise | `BLOQUÉ` | Départ de quête, nid, dialogue de choix et Scene de retour. | Les Facts `returned/kept` ne sont jamais produits ; l'Event de retour exige `returned=true` et reste le seul Event non atteignable dans la simulation 26/27. | P0 |
| Cabane du gardien | `PARTIEL` | Yvon, clé, carnet, Facts et Steps. | Attribution/consommation d'objet, world change, récompense et parcours réel. | P1 |
| Arrivée au phare | `PARTIEL` | Trigger, Scene, Fact et cinematic ID. | Timeline réelle, playback visuel et traversal depuis le passage. | P1 |
| Deux gardiens | `PARTIEL` | Deux battles et Facts de victoire. | Combats joués, progression, dialogue/récompense et save intermédiaire. | P1 |
| Confrontation finale | `PARTIEL` | Battle, outcomes, Facts de résolution et Step. | Décision trainer-vs-static, retry/capture/apaisement et preuve jouée. | P1 |
| Épilogue | `PARTIEL` | Trigger, Scene, dialogue, Facts de fin et Steps. | World change visible, cinematic finale réelle et arrivée par le parcours complet. | P1 |
| Campagne principale complète | `MANQUANT` comme preuve | Les 12 Steps principaux ont une structure substantielle. | Un walkthrough réel, ordonné, depuis New Game jusqu'à l'épilogue. | P0 |
| Trois quêtes annexes complètes | `MANQUANT` comme preuve | Les trois Storylines et la plupart des assets existent. | Choix, récompenses, idempotence et save/load end-to-end pour chacune. | P0 |
| Baseline promue | `GATE ROUGE` | Le projet courant charge dans plusieurs tests et le snapshot est inventorié. | Hash J5 attendu `8689d1…` contre snapshot `f22c2bf0…`; promotion et harness à remettre en cohérence. | P0 |
| Démonstrateur 2–3 h | `MANQUANT` comme preuve | Fondations moteur et contenu déclaré. | Build cible, parcours humain complet, durée mesurée, checkpoints save et absence de soft-lock. | P0 |

## 4. Ordre de traitement recommandé

| Ordre | Travail | Critère de sortie vérifiable |
|---:|---|---|
| 1 | Stabiliser le projet promu et le harness Event V2 | Hash volontairement promu ; les 6 cas du test trois-sources passent, overlays compris. |
| 2 | Ajouter le contrat Yarn outcome | Un choix réel produit un outcome qualifié, sauvegardé et utilisable par une Scene. |
| 3 | Étendre les conséquences Narrative Scene | Donner/retirer item, Pokémon et argent avec idempotence et round-trip. |
| 4 | Fermer les deux chemins Maël | Party vide → choix starter ; party existante → continuation ; même Step final. |
| 5 | Fermer Lysa, Mado et Goélise | Chaque choix pose les bons Facts, change les dialogues et ne se rejoue pas après reload. |
| 6 | Brancher le playback cinematic visuel | Mouvement, caméra, fade/emote/FX visibles dans `PlayableMapGame`; plus aucun placeholder Selbrume. |
| 7 | Étendre les World Rules environnementales | Passage, collisions/portes et brume changent réellement selon les Facts. |
| 8 | Construire le Validator global | Il détecte Event/Step inaccessible, Fact jamais produit, reward absent et outcome non fermé. |
| 9 | Prouver la campagne | E2E par checkpoints + walkthrough manuel du démarrage à l'épilogue et des 3 quêtes. |

## 5. Lecture finale

### Déjà prêt et réutilisable

- contrats narratifs et sérialisation ;
- graphes de Scenes linéaires et branches de combat ;
- Facts booléens et complétion de Steps ;
- sources Event V2 et `oneShot` ;
- dialogues Yarn linéaires ;
- combat trainer/wild et persistance générique ;
- party, bag, PC et sauvegarde générique ;
- diagnostics locaux.

### Manques qui bloquent directement Selbrume

- choix Yarn transformé en outcome persistant ;
- conséquences Scene de récompense ;
- flow starter complet ;
- fermeture de la quête Goélise ;
- baseline/harness Event V2 vert ;
- Validator global et E2E campagne.

### Manques nécessaires à la qualité du démonstrateur

- cinématiques visuelles et vraies timelines ;
- World Rules environnementales ;
- progression/rewards cohérents sur tous les combats ;
- sauvegardes à des checkpoints de quête ;
- walkthrough réel de 2–3 h.

## 6. Provenance et état des modifications

| Passe de l'audit parent | Verdict repris |
|---|---|
| Spécification | extraction `PASS`, fermeture `PARTIAL` |
| Éditeur/authoring | `PARTIAL`, environ 50 % |
| Moteur/runtime | `PARTIAL`, 60–65 % |
| Tests | `FAIL` strict pour la readiness |
| Critique finale | conclusion confirmée, niveau de preuve `PARTIAL` |

Fichier créé par cette demande :

- `reports/gameplay/fg_000_narrative_studio_selbrume_capability_matrix.md` — toutes les lignes sont nouvelles ; aucun fichier de code ou test n'a été modifié.

La roadmap n'est pas modifiée. Cette matrice explicite l'audit parent ; elle ne transforme aucun lot en `DONE`.
~~~~~~
### `examples/playable_runtime_host/lib/src/runtime_project_launch_map.dart`

- Taille : `1803` octets
- SHA-256 : `1f8dec65a0c729d0388458ea6b9dfed6baee14d9ce56e53724e3af93ae566555`

~~~~~~dart
import 'package:map_core/map_core.dart';

/// Maps displayed by the runtime host and the map selected for launch.
final class RuntimeHostProjectMapSelection {
  const RuntimeHostProjectMapSelection({
    required this.maps,
    required this.selectedMapId,
  });

  final List<ProjectMapEntry> maps;
  final String? selectedMapId;
}

/// Resolves the first bundle that the runtime host must load for a project.
///
/// Priority is deliberate:
/// 1. a versioned launch save restores its authored map;
/// 2. a valid enabled New Game start map boots a fresh project correctly;
/// 3. a valid persisted host selection resumes a legacy project's last map;
/// 4. legacy projects fall back to the first map in picker order.
RuntimeHostProjectMapSelection resolveRuntimeHostProjectMapSelection(
  ProjectManifest manifest, {
  String? versionedLaunchMapId,
  String? preferredMapId,
}) {
  final maps = List<ProjectMapEntry>.of(manifest.maps)
    ..sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      if (byOrder != 0) return byOrder;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  final immutableMaps = List<ProjectMapEntry>.unmodifiable(maps);

  String? validMapId(String? candidate) {
    final normalized = candidate?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return immutableMaps.any((map) => map.id == normalized) ? normalized : null;
  }

  final selectedMapId = validMapId(versionedLaunchMapId) ??
      (manifest.newGame.enabled
          ? validMapId(manifest.newGame.startMapId)
          : null) ??
      validMapId(preferredMapId) ??
      (immutableMaps.isEmpty ? null : immutableMaps.first.id);

  return RuntimeHostProjectMapSelection(
    maps: immutableMaps,
    selectedMapId: selectedMapId,
  );
}
~~~~~~

### `examples/playable_runtime_host/test/runtime_project_launch_map_test.dart`

- Taille : `2295` octets
- SHA-256 : `ccd388cb714000d3cb069237f1f42a7b08506736b7eabe0fce5f4c51bfffa741`

~~~~~~dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:pokemap_loader/src/runtime_project_launch_map.dart';

void main() {
  test('New Game start map overrides stale host preferences', () {
    final selection = resolveRuntimeHostProjectMapSelection(
      _manifest(
        newGame: const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'map_story_start',
        ),
      ),
      preferredMapId: 'map_sorted_first',
    );

    expect(
      selection.maps.map((entry) => entry.id),
      orderedEquals(<String>['map_sorted_first', 'map_story_start']),
      reason: 'The picker remains sorted independently from launch policy.',
    );
    expect(selection.selectedMapId, 'map_story_start');
  });

  test('versioned launch save map overrides New Game start map', () {
    final manifest = _manifest(
      newGame: const ProjectNewGameConfig(
        enabled: true,
        startMapId: 'map_story_start',
      ),
    );

    expect(
      resolveRuntimeHostProjectMapSelection(
        manifest,
        versionedLaunchMapId: 'map_sorted_first',
        preferredMapId: 'map_story_start',
      ).selectedMapId,
      'map_sorted_first',
    );
  });

  test('legacy projects preserve valid preference and sorted fallback', () {
    final manifest = _manifest(newGame: const ProjectNewGameConfig());

    expect(
      resolveRuntimeHostProjectMapSelection(
        manifest,
        preferredMapId: 'map_story_start',
      ).selectedMapId,
      'map_story_start',
    );
    expect(
      resolveRuntimeHostProjectMapSelection(
        manifest,
        preferredMapId: 'missing_map',
      ).selectedMapId,
      'map_sorted_first',
    );
  });
}

ProjectManifest _manifest({required ProjectNewGameConfig newGame}) {
  return ProjectManifest(
    name: 'Launch map test',
    newGame: newGame,
    tilesets: const <ProjectTilesetEntry>[],
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map_story_start',
        name: 'Story start',
        relativePath: 'maps/story_start.json',
        sortOrder: 20,
      ),
      ProjectMapEntry(
        id: 'map_sorted_first',
        name: 'Aardvark',
        relativePath: 'maps/sorted_first.json',
        sortOrder: 10,
      ),
    ],
  );
}
~~~~~~

### `examples/playable_runtime_host/test/selbrume_canonical_narrative_campaign_test.dart`

- Taille : `9527` octets
- SHA-256 : `422371685aa3d7966b9c0faed2354b3fd0ac7fe1a109b7579ad462670fb31706`

~~~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Selbrume canonical campaign scenes execute through the current engine',
      () async {
    final fixture = _loadSelbrume();
    var state = const GameState(
      saveId: 'selbrume_canonical_campaign',
      currentMapId: 'map_bourg_selbrume',
    );
    final dialogueIds = <String>[];
    final cinematicIds = <String>[];
    final battleTrainerIds = <String>[];

    Future<NarrativeSceneExecutionCompleted> execute(
      String sceneId, {
      String battleOutcome = 'victory',
      String dialogueOutcome = 'completed',
    }) async {
      final result = await executeNarrativeEventScene(
        request: NarrativeSceneExecutionRequest(
          eventId: 'event_test_$sceneId',
          sceneId: sceneId,
          executionId: 'execution_test_$sceneId',
          gameState: state,
        ),
        project: fixture.project,
        mapsById: fixture.mapsById,
        currentGameState: () => state,
        callbacks: SceneRuntimeHostCallbacks(
          // Keep this campaign harness aligned with the production Scene hook:
          // canonical Fact branches (notably New Game party routing) must be
          // evaluated from the evolving GameState instead of being bypassed.
          evaluateCondition: (intent) =>
              _resolveConditionOutput(fixture.project, state, intent),
          showDialogue: (intent) {
            dialogueIds.add(intent.dialogueId!);
            return dialogueOutcome;
          },
          playCinematic: (intent) {
            cinematicIds.add(intent.cinematicId!);
            return 'completed';
          },
          startBattle: (intent) {
            battleTrainerIds.add(intent.trainerId!);
            return battleOutcome;
          },
        ),
      );
      expect(
        result,
        isA<NarrativeSceneExecutionCompleted>(),
        reason: result is NarrativeSceneExecutionFailed
            ? result.failure.toString()
            : sceneId,
      );
      final completed = result as NarrativeSceneExecutionCompleted;
      state = completed.updatedGameState;
      return completed;
    }

    await execute('scene_mael_intro');
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      containsPair('fact_mael_mission_given', true),
    );
    expect(
      state.progression.completedStepIds,
      containsAll(<String>['step_intro_selbrume', 'step_receive_mission']),
    );

    await execute('scene_port_entry', dialogueOutcome: 'reassure');
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      containsPair('fact_port_crowd_reassured', true),
    );
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      isNot(containsPair('fact_port_crowd_panicked', true)),
    );
    expect(state.progression.completedStepIds, contains('step_go_to_port'));

    await execute('scene_rival_after_loss');
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      containsPair('fact_rival_port_lost_once', true),
    );
    expect(
      state.progression.completedStepIds,
      contains('step_rival_battle'),
      reason: 'The defeat outcome must converge back into the main story.',
    );

    await execute('scene_soline_unlock_passage');
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      containsPair('fact_passage_dames_unlocked', true),
    );

    final finalResult = await execute('scene_final_pokemon');
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      containsPair('fact_mist_source_resolved', true),
    );
    expect(
      state.progression.completedStepIds,
      contains('step_final_confrontation'),
    );
    expect(
      finalResult.qualifiedOutcomes,
      contains(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'scene_final_pokemon',
          outcomeId: 'lighthouse.pokemon.appeased',
        ),
      ),
    );
    final mistResult = await execute('scene_mist_disperses');
    expect(
      mistResult.qualifiedOutcomes,
      contains(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'scene_mist_disperses',
          outcomeId: 'mist_resolved',
        ),
      ),
      reason: 'The final battle outcome must lead into the distinct '
          'mist-dispersal Scene.',
    );
    expect(
      battleTrainerIds,
      contains('trainer_boss_phare_pokemon'),
    );
    expect(
        dialogueIds,
        containsAll(<String>[
          'dialogue_mael_intro',
          'dialogue_port_alert',
          'dialogue_soline',
          'dialogue_lighthouse',
          'dialogue_lysa_port',
        ]));
    expect(
        cinematicIds,
        containsAll(<String>[
          'cinematic_port_reassure',
          'cinematic_passage_revealed',
          'cinematic_mist_disperses',
        ]));
    expect(cinematicIds, isNot(contains('cinematic_port_panic')));
  });

  test('the lighthouse boss defeat path does not resolve the mist', () async {
    final fixture = _loadSelbrume();
    var state = const GameState(
      saveId: 'selbrume_canonical_campaign_defeat',
      currentMapId: 'map_sommet_phare',
    );
    final result = await executeNarrativeEventScene(
      request: NarrativeSceneExecutionRequest(
        eventId: 'event_test_final_defeat',
        sceneId: 'scene_final_pokemon',
        executionId: 'execution_test_final_defeat',
        gameState: state,
      ),
      project: fixture.project,
      mapsById: fixture.mapsById,
      currentGameState: () => state,
      callbacks: SceneRuntimeHostCallbacks(
        evaluateCondition: (intent) =>
            _resolveConditionOutput(fixture.project, state, intent),
        showDialogue: (_) => 'completed',
        playCinematic: (_) => 'completed',
        startBattle: (_) => 'defeat',
      ),
    );
    expect(result, isA<NarrativeSceneExecutionCompleted>());
    state = (result as NarrativeSceneExecutionCompleted).updatedGameState;
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      isNot(containsPair('fact_mist_source_resolved', true)),
    );
    expect(
      result.qualifiedOutcomes,
      contains(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'scene_final_pokemon',
          outcomeId: 'lighthouse.pokemon.defeat',
        ),
      ),
    );
  });
}

({ProjectManifest project, Map<String, MapData> mapsById}) _loadSelbrume() {
  final root = _findRepositoryRoot();
  final projectRoot = Directory(p.join(root.path, 'selbrume'));
  final project = ProjectManifest.fromJson(
    _readJson(File(p.join(projectRoot.path, 'project.json'))),
  );
  return (
    project: project,
    mapsById: <String, MapData>{
      for (final entry in project.maps)
        entry.id: MapData.fromJson(
          _readJson(File(p.join(projectRoot.path, entry.relativePath))),
        ),
    },
  );
}

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      throw StateError('pokemonProject repository root not found.');
    }
    current = current.parent;
  }
}

Map<String, dynamic> _readJson(File file) =>
    (jsonDecode(file.readAsStringSync()) as Map).cast<String, dynamic>();

String _resolveConditionOutput(
  ProjectManifest project,
  GameState state,
  SceneRuntimePlanIntent intent,
) {
  final source = intent.conditionSource;
  if (source == null) {
    throw StateError('Scene condition intent is missing a condition source.');
  }

  if (source.sourceKind == SceneConditionSourceKind.fact) {
    final matched = evaluateCanonicalNarrativeFactSceneCondition(
      source: source,
      gameState: state,
      resolver: NarrativeFactRuntimeResolver.fromFacts(project.facts),
    );
    return matched ? 'true' : 'false';
  }

  final value = switch (source.sourceKind) {
    SceneConditionSourceKind.factLikeStoryFlag =>
      state.storyFlags.activeFlags.contains(source.sourceId) ||
          state.progression.storyFlags.contains(source.sourceId),
    SceneConditionSourceKind.storyStepCompletion =>
      state.progression.completedStepIds.contains(source.sourceId),
    SceneConditionSourceKind.consumedEvent =>
      state.consumedEventIds.contains(source.sourceId),
    _ => throw UnsupportedError(
        'Condition source ${source.sourceKind.name} is outside this campaign.',
      ),
  };

  final matched = switch (source.operator) {
    SceneConditionOperator.isTrue => value,
    SceneConditionOperator.isFalse => !value,
    SceneConditionOperator.equals => switch (source.value) {
        'true' || SceneConditionValues.completed => value,
        'false' || SceneConditionValues.notCompleted => !value,
        _ => throw UnsupportedError(
            'Condition value ${source.value} is outside this campaign.',
          ),
      },
  };
  return matched ? 'true' : 'false';
}
~~~~~~
### `examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart`

- Taille : `61181` octets
- SHA-256 : `0b029188235c3f104480c76146fc357a827096a3c56a558b510fbc71b523778e`

~~~~~~dart
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

const Set<String> _oneShotsThroughPortAlert = <String>{
  'evt_019abcde-5000-7000-8000-000000000011',
  'evt_019abcde-4000-7000-8000-000000000002',
};
const Set<String> _oneShotsThroughLysaVictory = <String>{
  ..._oneShotsThroughPortAlert,
  'evt_019abcde-4000-7000-8000-000000000001',
  'evt_019abcde-5000-7000-8000-000000000033',
};
const Set<String> _oneShotsThroughLysaDefeat = <String>{
  ..._oneShotsThroughPortAlert,
  'evt_019abcde-4000-7000-8000-000000000001',
  'evt_019abcde-5000-7000-8000-000000000034',
};
const Set<String> _oneShotsThroughGoeliseKeep = <String>{
  ..._oneShotsThroughLysaVictory,
  'evt_019abcde-5000-7000-8000-000000000020',
  'evt_019abcde-5000-7000-8000-000000000022',
  'evt_019abcde-5000-7000-8000-000000000035',
};
const Set<String> _oneShotsThroughMarsh = <String>{
  ..._oneShotsThroughLysaVictory,
  'evt_019abcde-5000-7000-8000-000000000012',
  'evt_019abcde-4000-7000-8000-000000000003',
  'evt_019abcde-5000-7000-8000-000000000014',
  'evt_019abcde-5000-7000-8000-000000000015',
  'evt_019abcde-5000-7000-8000-000000000017',
  'evt_019abcde-5000-7000-8000-000000000018',
  'evt_019abcde-5000-7000-8000-000000000019',
  'evt_019abcde-5000-7000-8000-000000000032',
};
const Set<String> _oneShotsThroughLighthouseGuardians = <String>{
  ..._oneShotsThroughMarsh,
  'evt_019abcde-5000-7000-8000-000000000016',
  'evt_019abcde-5000-7000-8000-000000000020',
  'evt_019abcde-5000-7000-8000-000000000022',
  'evt_019abcde-5000-7000-8000-000000000021',
  'evt_019abcde-5000-7000-8000-000000000023',
  'evt_019abcde-5000-7000-8000-000000000029',
  'evt_019abcde-5000-7000-8000-000000000030',
  'evt_019abcde-5000-7000-8000-000000000025',
  'evt_019abcde-5000-7000-8000-000000000026',
  'evt_019abcde-5000-7000-8000-000000000027',
};
const Set<String> _oneShotsThroughBoss = <String>{
  ..._oneShotsThroughLighthouseGuardians,
  'evt_019abcde-5000-7000-8000-000000000028',
  'evt_019abcde-5000-7000-8000-000000000036',
};
const Set<String> _oneShotsThroughEpilogue = <String>{
  ..._oneShotsThroughBoss,
  'evt_019abcde-5000-7000-8000-000000000031',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'checkpoint reload preserves 32px movement through the opened port gate',
    () async {
      final journey = await _SelbrumeJourney.start();

      await journey.interactWith(
        entityId: 'npc_mael',
        dialogue: const _DialogueChoice(linesBeforeChoice: 1),
      );
      await journey.waitForFact('fact_mael_mission_given');
      await journey.navigateTo(const GridPos(x: 17, y: 24));
      await journey.checkpoint(
        'before_port_regression',
        expectedConsumedEventIds: const <String>{
          'evt_019abcde-5000-7000-8000-000000000011',
        },
      );
      final starterBeforeReentry = journey.state.party.members.single.toJson();
      final oneShotsBeforeReentry = Set<String>.from(
        journey.state.narrativeEventProgress.consumedNarrativeEventIds,
      );
      await journey.interactWith(entityId: 'npc_mael');
      expect(journey.state.party.members, hasLength(1));
      expect(
        journey.state.party.members.single.toJson(),
        starterBeforeReentry,
        reason: 'Re-entering Mael after reload must not replay starter grant.',
      );
      expect(
        journey.state.narrativeEventProgress.consumedNarrativeEventIds,
        oneShotsBeforeReentry,
        reason: 'Re-entry must not consume or replay a new Event Registry ID.',
      );

      final diagnostic = journey.pathDiagnostic(
        const GridPos(x: 26, y: 54),
        gateEntityId: 'gate_bourg_to_port',
      );
      await journey.crossConnection(
        MapConnectionDirection.south,
        preferredAxis: 26,
      );

      expect(
        journey.state.currentMapId,
        'map_port_brisants',
        reason: diagnostic,
      );
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  test('Lysa victory uses a real damaging move and victory branch', () async {
    final journey = await _SelbrumeJourney.start();
    await journey.prepareLysaBattle();
    final moveStart = journey.selectedBattleMoveIds.length;

    await journey.interactWith(
      entityId: 'npc_lysa',
      dialogue: const _DialogueChoice(linesBeforeChoice: 2),
      battleFactId: 'fact_rival_port_defeated',
      battleStrategy: _BattleStrategy.win,
      expectedTrainerId: 'trainer_lysa_port',
      expectedEnemySpeciesId: 'bulbasaur',
    );

    final victoryMoves = journey.battleMoveChoices.skip(moveStart);
    expect(
      victoryMoves,
      contains(
        isA<_BattleMoveChoiceEvidence>()
            .having((move) => move.power, 'power', greaterThan(0))
            .having(
              (move) => move.effectiveness,
              'effectiveness',
              greaterThan(0),
            ),
      ),
    );
    expect(
      journey.state.narrativeFactRuntimeState
          .overridesByFactId['fact_rival_port_defeated'],
      isTrue,
    );
    expect(
      journey.state.narrativeFactRuntimeState
          .overridesByFactId['fact_rival_port_lost_once'],
      isNot(isTrue),
    );
    await journey.checkpoint(
      'lysa_victory',
      expectedConsumedEventIds: _oneShotsThroughLysaVictory,
    );
  }, timeout: const Timeout(Duration(minutes: 1)));

  test('Lysa defeat uses a real status move and defeat branch', () async {
    final journey = await _SelbrumeJourney.start();
    await journey.prepareLysaBattle();
    final moveStart = journey.selectedBattleMoveIds.length;

    await journey.interactWith(
      entityId: 'npc_lysa',
      dialogue: const _DialogueChoice(linesBeforeChoice: 2),
      battleFactId: 'fact_rival_port_defeated',
      acceptedDefeatFactId: 'fact_rival_port_lost_once',
      battleStrategy: _BattleStrategy.lose,
      expectedTrainerId: 'trainer_lysa_port',
      expectedEnemySpeciesId: 'bulbasaur',
    );

    final deliberateLossMoves =
        journey.battleMoveChoices.skip(moveStart).toList();
    expect(deliberateLossMoves, isNotEmpty);
    expect(
      deliberateLossMoves.map((move) => move.moveId),
      everyElement('growl'),
    );
    expect(
      deliberateLossMoves.map((move) => move.power),
      everyElement(0),
    );
    expect(
      journey.state.narrativeFactRuntimeState
          .overridesByFactId['fact_rival_port_lost_once'],
      isTrue,
    );
    expect(
      journey.state.narrativeFactRuntimeState
          .overridesByFactId['fact_rival_port_defeated'],
      isNot(isTrue),
    );
    await journey.checkpoint(
      'lysa_defeat',
      expectedConsumedEventIds: _oneShotsThroughLysaDefeat,
    );
    await journey.crossConnection(MapConnectionDirection.north);
    await journey.crossConnection(
      MapConnectionDirection.east,
      preferredAxis: 22,
    );
    await journey.crossConnection(
      MapConnectionDirection.east,
      preferredAxis: 22,
    );
    await journey.enterTrigger('zone_marais_entry');
    await journey.waitForFact('fact_marais_unlocked');
    expect(journey.state.currentMapId, 'map_marais_salants');
  }, timeout: const Timeout(Duration(minutes: 1)));

  test(
    'player completes Selbrume through PlayableMapGame production hooks',
    () async {
      final journey = await _SelbrumeJourney.start();

      await journey.interactWith(
        entityId: 'npc_mael',
        dialogue: const _DialogueChoice(linesBeforeChoice: 1),
      );
      await journey.waitForFact('fact_mael_mission_given');
      journey.expectStarterMatchesAuthoredOption('starter_bulbasaur');
      await journey.navigateTo(const GridPos(x: 17, y: 24));
      await journey.checkpoint(
        'before_port',
        expectedConsumedEventIds: const <String>{
          'evt_019abcde-5000-7000-8000-000000000011',
        },
      );

      final bourgPortPathDiagnostic = journey.pathDiagnostic(
        const GridPos(x: 26, y: 54),
        gateEntityId: 'gate_bourg_to_port',
      );
      await journey.crossConnection(
        MapConnectionDirection.south,
        preferredAxis: 26,
      );
      expect(journey.state.currentMapId, 'map_port_brisants',
          reason: bourgPortPathDiagnostic);
      await journey.enterTrigger(
        'zone_port_entry',
        dialogue: const _DialogueChoice(
          linesBeforeChoice: 2,
          choiceIndex: 1,
        ),
      );
      await journey.waitForFact('fact_port_alert_seen');
      expect(journey.state.currentMapId, 'map_port_brisants');

      final movesBeforeLysa = journey.selectedBattleMoveIds.length;
      await journey.interactWith(
        entityId: 'npc_lysa',
        dialogue: const _DialogueChoice(linesBeforeChoice: 2),
        battleFactId: 'fact_rival_port_defeated',
        expectedTrainerId: 'trainer_lysa_port',
        expectedEnemySpeciesId: 'bulbasaur',
      );
      expect(
        journey.state.progression.completedStepIds,
        contains('step_rival_battle'),
      );
      expect(
        journey.battleMoveChoices.skip(movesBeforeLysa),
        contains(
          isA<_BattleMoveChoiceEvidence>()
              .having((move) => move.power, 'power', greaterThan(0))
              .having(
                (move) => move.effectiveness,
                'effectiveness',
                greaterThan(0),
              ),
        ),
        reason: 'Lysa must be beaten with a damaging, non-immune move '
            'selected in the UI.',
      );
      await journey.checkpoint(
        'after_lysa',
        expectedConsumedEventIds: _oneShotsThroughLysaVictory,
      );
      await journey.expectConsumedTriggerDoesNotReplay('zone_port_entry');

      await journey.crossConnection(MapConnectionDirection.north);
      await journey.crossConnection(
        MapConnectionDirection.east,
        preferredAxis: 22,
      );
      await journey.crossConnection(
        MapConnectionDirection.east,
        preferredAxis: 22,
      );
      await journey.enterTrigger('zone_marais_entry');
      await journey.waitForFact('fact_marais_unlocked');

      await journey.interactWith(
        entityId: 'npc_mado',
        dialogue: const _DialogueChoice(linesBeforeChoice: 2),
      );
      await journey.waitForFact('fact_crystals_quest_started');

      await journey.interactWith(entityId: 'clue_glass_object');
      await journey.waitForFact('fact_clue_glass_found');
      await journey.enterTrigger('tr_marais_indice_traces_electriques');
      await journey.waitForFact('fact_clue_electric_tracks_found');
      await journey.enterTrigger('tr_marais_indice_repere_lentille');
      await journey.waitForFact('fact_clue_lighthouse_mark_found');

      await journey.enterTrigger('tr_marais_cristal_1');
      await journey.waitForFact('fact_crystal_1_found');
      await journey.enterTrigger('tr_marais_cristal_2');
      await journey.waitForFact('fact_crystal_2_found');
      await journey.enterTrigger('tr_marais_cristal_3');
      await journey.waitForFact('fact_crystal_3_found');
      await journey.interactWith(entityId: 'npc_mado');
      await journey.waitForFact('fact_crystals_quest_completed');
      expect(
        journey.state.bag.entries,
        contains(
          const BagEntry(
            itemId: 'super-potion',
            categoryId: 'medicine',
            quantity: 1,
          ),
        ),
      );
      await journey.checkpoint(
        'after_marsh',
        expectedConsumedEventIds: _oneShotsThroughMarsh,
      );

      await journey.crossConnection(MapConnectionDirection.west);
      await journey.crossConnection(MapConnectionDirection.west);
      await journey.crossConnection(
        MapConnectionDirection.south,
        preferredAxis: 39,
      );
      await journey.interactWith(entityId: 'npc_soline');
      await journey.waitForFact('fact_passage_dames_unlocked');

      await journey.interactWith(entityId: 'npc_pecheur');
      await journey.waitForFact('fact_goelise_quest_started');
      await journey.enterTrigger(
        'tr_port_nest',
        dialogue: const _DialogueChoice(linesBeforeChoice: 1),
      );
      await journey.waitForFact('fact_goelise_object_returned');
      final moneyBeforeReward = journey.state.trainerProfile.money;
      await journey.interactWith(entityId: 'npc_pecheur');
      await journey.waitForFact('fact_goelise_quest_completed');
      expect(journey.state.trainerProfile.money, moneyBeforeReward + 300);
      expect(
        journey.state.narrativeFactRuntimeState
            .overridesByFactId['fact_goelise_object_kept'],
        isNot(isTrue),
      );
      expect(
        journey.state.bag.entries.map((entry) => entry.itemId),
        isNot(contains('pearl')),
      );

      await journey.crossConnection(MapConnectionDirection.north);
      await journey.crossConnection(
        MapConnectionDirection.east,
        preferredAxis: 28,
      );
      await journey.crossConnection(
        MapConnectionDirection.east,
        preferredAxis: 28,
      );
      await journey.crossConnection(
        MapConnectionDirection.south,
        preferredAxis: 28,
      );
      await journey.crossConnection(
        MapConnectionDirection.east,
        preferredAxis: 10,
      );
      await journey.enterTrigger('zone_lighthouse_entry');
      await journey.waitForFact('fact_lighthouse_reached');

      await journey.interactWith(entityId: 'npc_yvon');
      await journey.waitForFact('fact_cabin_quest_started');
      await journey.enterTrigger('tr_cabin_key_outside');
      await journey.waitForFact('fact_cabin_key_found');
      await journey.enterWarp('warp_phare_ext_to_cabane');
      expect(journey.state.currentMapId, 'map_cabane_gardien');
      await journey.enterTrigger('tr_cabane_journal');
      await journey.waitForFact('fact_cabin_quest_completed');
      expect(
        journey.state.bag.entries.map((entry) => entry.itemId),
        containsAll(<String>['basement-key', 'rare-candy']),
      );
      await journey.enterWarp('warp_cabane_to_phare_exterieur');

      await journey.enterWarp('warp_phare_ext_to_interieur');
      await journey.enterTrigger('tr_phare_note');
      await journey.waitForFact('fact_lighthouse_old_note_read');
      await journey.enterTrigger(
        'tr_phare_guardian_1',
        battleFactId: 'fact_lighthouse_guardian_1_defeated',
        expectedTrainerId: 'trainer_phare_gardien_1',
        expectedEnemySpeciesId: 'magnemite',
      );
      await journey.enterTrigger(
        'tr_phare_guardian_2',
        battleFactId: 'fact_lighthouse_guardian_2_defeated',
        expectedTrainerId: 'trainer_phare_gardien_2',
        expectedEnemySpeciesId: 'gastly',
      );
      expect(
        journey.state.progression.completedStepIds,
        contains('step_climb_lighthouse'),
      );
      await journey.enterWarp('warp_phare_interieur_to_sommet');
      await journey.checkpoint(
        'before_boss',
        expectedConsumedEventIds: _oneShotsThroughLighthouseGuardians,
      );

      await journey.enterTrigger(
        'tr_sommet_confrontation',
        battleFactId: 'fact_mist_source_resolved',
        expectStaticBattle: true,
      );
      await journey.waitForFact('fact_mist_source_resolved');
      await journey.checkpoint(
        'after_boss',
        expectedConsumedEventIds: _oneShotsThroughBoss,
      );
      expect(
        journey.isEntityVisible('map_sommet_phare', 'fog_sommet'),
        isFalse,
      );
      expect(
        journey.isEntityVisible(
          'map_sommet_phare',
          'boss_phare_pokemon',
        ),
        isFalse,
      );
      await journey.expectConsumedTriggerDoesNotReplay(
        'tr_sommet_confrontation',
      );

      await journey.enterWarp('warp_sommet_to_phare_interieur');
      await journey.enterWarp('warp_phare_interieur_to_exterieur');
      await journey.crossConnection(MapConnectionDirection.west);
      await journey.crossConnection(MapConnectionDirection.north);
      await journey.crossConnection(MapConnectionDirection.west);
      await journey.crossConnection(MapConnectionDirection.west);
      await journey.crossConnection(
        MapConnectionDirection.south,
        preferredAxis: 24,
      );
      await journey.enterTrigger('zone_port_center');
      await journey.waitForFact('fact_main_story_completed');
      await journey.checkpoint(
        'after_epilogue',
        expectedConsumedEventIds: _oneShotsThroughEpilogue,
      );
      for (final fog in const <(String, String)>[
        ('map_port_brisants', 'fog_port'),
        ('map_marais_salants', 'fog_marais'),
        ('map_passage_dames', 'fog_passage'),
        ('map_phare_exterieur', 'fog_phare'),
      ]) {
        expect(
          journey.isEntityVisible(fog.$1, fog.$2),
          isFalse,
          reason: '${fog.$2} must remain hidden after serialized reload.',
        );
      }
      expect(
        journey.isEntityVisible(
          'map_port_brisants',
          'goelise_nest_proxy',
        ),
        isFalse,
      );

      expect(
        journey.state.progression.completedStepIds,
        containsAll(<String>[
          'step_intro_selbrume',
          'step_rival_battle',
          'step_find_three_clues',
          'step_climb_lighthouse',
          'step_final_confrontation',
          'step_main_story_completed',
          'step_crystals_completed',
          'step_goelise_completed',
          'step_cabin_completed',
        ]),
      );
      expect(journey.savedCheckpointNames, <String>[
        'before_port',
        'after_lysa',
        'after_marsh',
        'before_boss',
        'after_boss',
        'after_epilogue',
      ]);
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );

  test('Goelise keep choice reaches its authored alternative reward', () async {
    final journey = await _SelbrumeJourney.start();
    await journey.interactWith(
      entityId: 'npc_mael',
      dialogue: const _DialogueChoice(linesBeforeChoice: 1, choiceIndex: 1),
    );
    await journey.waitForFact('fact_mael_mission_given');
    await journey.crossConnection(
      MapConnectionDirection.south,
      preferredAxis: 26,
    );
    await journey.enterTrigger(
      'zone_port_entry',
      dialogue: const _DialogueChoice(linesBeforeChoice: 2),
    );
    await journey.waitForFact('fact_port_alert_seen');
    await journey.interactWith(
      entityId: 'npc_lysa',
      dialogue: const _DialogueChoice(linesBeforeChoice: 2),
      battleFactId: 'fact_rival_port_defeated',
      expectedTrainerId: 'trainer_lysa_port',
      expectedEnemySpeciesId: 'bulbasaur',
    );
    await journey.interactWith(entityId: 'npc_pecheur');
    await journey.waitForFact('fact_goelise_quest_started');
    await journey.enterTrigger(
      'tr_port_nest',
      dialogue: const _DialogueChoice(linesBeforeChoice: 1, choiceIndex: 1),
    );
    await journey.waitForFact('fact_goelise_object_kept');
    final moneyBeforeKeepReward = journey.state.trainerProfile.money;
    await journey.interactWith(entityId: 'npc_pecheur');
    await journey.waitForFact('fact_goelise_quest_completed');

    expect(
      journey.state.bag.entries.map((entry) => entry.itemId),
      contains('pearl'),
    );
    expect(journey.state.trainerProfile.money, moneyBeforeKeepReward);
    expect(
      journey.state.narrativeFactRuntimeState
          .overridesByFactId['fact_goelise_object_returned'],
      isNot(isTrue),
    );
    await journey.checkpoint(
      'goelise_keep',
      expectedConsumedEventIds: _oneShotsThroughGoeliseKeep,
    );
  }, timeout: const Timeout(Duration(minutes: 2)));
}

final class _SelbrumeJourney {
  _SelbrumeJourney._({
    required this.game,
    required this.project,
    required this.projectRoot,
  });

  final _JourneyPlayableMapGame game;
  final ProjectManifest project;
  final Directory projectRoot;
  final Map<String, MapData> _mapsById = <String, MapData>{};
  final Map<String, Set<String>> _runtimeRejectedEdgesByMapId =
      <String, Set<String>>{};
  final List<String> savedCheckpointNames = <String>[];
  final List<_BattleMoveChoiceEvidence> battleMoveChoices =
      <_BattleMoveChoiceEvidence>[];

  GameState get state => game.gameStateSnapshot;
  List<String> get selectedBattleMoveIds =>
      battleMoveChoices.map((choice) => choice.moveId).toList(growable: false);

  void expectStarterMatchesAuthoredOption(String optionId) {
    final authoredStarter = project.newGame.starterOptions
        .singleWhere((option) => option.id == optionId)
        .pokemon;
    expect(
      state.party.members,
      <PlayerPokemon>[authoredStarter],
      reason: 'The Scene starter grant must consume the complete project-owned '
          'New Game option (HP, moves, nature, ability and level), not rebuild '
          'a partial Pokemon from the Scene consequence.',
    );
  }

  String pathDiagnostic(GridPos target, {required String gateEntityId}) {
    final map = _currentMap;
    final projection = const RuntimeWorldRuleProjectionHook().resolve(
      project: project,
      gameState: state,
      map: map,
    );
    final world = _pathfindingWorld(map);
    final reason = world.movementBlockReasonAt(
      x: target.x,
      y: target.y,
      movementMode: state.playerMovementMode,
    );
    return 'map=${map.id}, from=${game.debugPlayerGridPosition}, '
        'mission=${state.narrativeFactRuntimeState.overridesByFactId['fact_mael_mission_given']}, '
        'gateHidden=${projection.hiddenEntityIds.contains(gateEntityId)}, '
        'targetBlock=${reason?.name}, '
        'gridReachable=${_hasGridPath(world, target)}, '
        'physicalPathLength=${_findPath(target, avoidEncounters: false)?.length}';
  }

  static Future<_SelbrumeJourney> start() async {
    final repositoryRoot = _findRepositoryRoot();
    final projectRoot = Directory(p.join(repositoryRoot.path, 'selbrume'));
    final projectPath = p.join(projectRoot.path, 'project.json');
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: projectPath,
      mapId: 'map_bourg_selbrume',
    );
    final saveRepository = _SerializedMemoryGameSaveRepository();
    final game = _JourneyPlayableMapGame(
      bundle: bundle,
      projectFilePath: projectPath,
      saveRepository: saveRepository,
    );
    final journey = _SelbrumeJourney._(
      game: game,
      project: bundle.manifest,
      projectRoot: projectRoot,
    );
    game.onGameResize(Vector2(640, 480));
    await game.onLoad();
    await journey._pumpUntil(
      () => !game.debugIsMapActivationDispatchInFlight,
      label: 'initial New Game activation',
    );
    expect(journey.state.currentMapId, 'map_bourg_selbrume');
    expect(journey.state.party.members, isEmpty);
    return journey;
  }

  Future<void> checkpoint(
    String name, {
    required Set<String> expectedConsumedEventIds,
  }) async {
    expect(await game.saveGame(), isTrue, reason: 'save checkpoint $name');
    final before = SaveData.fromJson(
      saveDataFromGameState(state).toJson(),
    );
    final consumedBefore = Set<String>.from(
      state.narrativeEventProgress.consumedNarrativeEventIds,
    );
    expect(
      consumedBefore,
      unorderedEquals(expectedConsumedEventIds),
      reason: 'The exact Event Registry one-shot set must match before '
          'checkpoint $name.',
    );
    expect(await game.loadGame(), isTrue, reason: 'load checkpoint $name');
    await _pumpUntil(
      () =>
          !game.debugIsLoadActivationWorkInFlight &&
          !game.debugIsMapActivationDispatchInFlight,
      label: 'reload checkpoint $name',
    );
    expect(saveDataFromGameState(state).toJson(), before.toJson());
    expect(
      state.narrativeEventProgress.consumedNarrativeEventIds,
      consumedBefore,
      reason: 'One-shot consumption must survive checkpoint $name.',
    );
    expect(
      state.narrativeEventProgress.consumedNarrativeEventIds,
      unorderedEquals(expectedConsumedEventIds),
      reason: 'The exact Event Registry one-shot set must match after '
          'checkpoint $name.',
    );
    savedCheckpointNames.add(name);
  }

  Future<void> waitForFact(String factId) async {
    await _settleUntil(
      () => state.narrativeFactRuntimeState.overridesByFactId[factId] == true,
      label: 'Fact $factId',
    );
  }

  bool isEntityVisible(String mapId, String entityId) {
    final map = _mapById(mapId);
    final entity = map.entities.singleWhere((entry) => entry.id == entityId);
    final projection = const RuntimeWorldRuleProjectionHook().resolve(
      project: project,
      gameState: state,
      map: map,
    );
    return projection.isMapEntityVisible(entity);
  }

  Future<void> expectConsumedTriggerDoesNotReplay(String triggerId) async {
    final trigger = _currentMap.triggers.singleWhere(
      (entry) => entry.id == triggerId,
    );
    final consumedBefore = Set<String>.from(
      state.narrativeEventProgress.consumedNarrativeEventIds,
    );
    if (_contains(trigger.area, game.debugPlayerGridPosition)) {
      await navigateTo(_reachableCellOutsideArea(trigger.area));
    }
    await navigateTo(_reachableCellInArea(trigger.area));
    await _pumpUntil(
      () =>
          !game.debugIsNarrativeSpatialDispatchInFlight &&
          !game.debugIsNarrativeOutcomeWorkInFlight,
      label: 'consumed trigger $triggerId skip',
      maxTicks: 1000,
    );
    expect(
      game.debugFlowPhaseName,
      'overworld',
      reason: 'Consumed trigger $triggerId must not replay authored flow.',
    );
    expect(game.debugPendingBattleRequest, isNull);
    expect(
      state.narrativeEventProgress.consumedNarrativeEventIds,
      consumedBefore,
    );
  }

  Future<void> prepareLysaBattle() async {
    await interactWith(
      entityId: 'npc_mael',
      dialogue: const _DialogueChoice(linesBeforeChoice: 1, choiceIndex: 1),
    );
    await waitForFact('fact_mael_mission_given');
    await crossConnection(
      MapConnectionDirection.south,
      preferredAxis: 26,
    );
    await enterTrigger(
      'zone_port_entry',
      dialogue: const _DialogueChoice(linesBeforeChoice: 2),
    );
    await waitForFact('fact_port_alert_seen');
  }

  Future<void> interactWith({
    required String entityId,
    _DialogueChoice? dialogue,
    String? battleFactId,
    String? acceptedDefeatFactId,
    _BattleStrategy battleStrategy = _BattleStrategy.win,
    String? expectedTrainerId,
    String? expectedEnemySpeciesId,
  }) async {
    final map = _currentMap;
    final entity = map.entities.singleWhere((entry) => entry.id == entityId);
    final approach = _shortestReachableApproach(entity);
    await navigateTo(approach.stagingPosition);
    await _tapMovement(_controlForDirection(approach.facing));
    expect(game.debugPlayerGridPosition, approach.position);
    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );
    await _handleAuthoredFlow(
      sourceLabel: 'entity $entityId',
      dialogue: dialogue,
      battleFactId: battleFactId,
      acceptedDefeatFactId: acceptedDefeatFactId,
      battleStrategy: battleStrategy,
      expectedTrainerId: expectedTrainerId,
      expectedEnemySpeciesId: expectedEnemySpeciesId,
    );
  }

  Future<void> enterTrigger(
    String triggerId, {
    _DialogueChoice? dialogue,
    String? battleFactId,
    bool expectStaticBattle = false,
    _BattleStrategy battleStrategy = _BattleStrategy.win,
    String? expectedTrainerId,
    String? expectedEnemySpeciesId,
  }) async {
    final trigger = _currentMap.triggers.singleWhere(
      (entry) => entry.id == triggerId,
    );
    if (_contains(trigger.area, game.debugPlayerGridPosition)) {
      await navigateTo(_reachableCellOutsideArea(trigger.area));
    }
    final target = _reachableCellInArea(trigger.area);
    await navigateTo(
      target,
      deferBattleInArea:
          battleFactId != null || expectStaticBattle ? trigger.area : null,
    );
    await _handleAuthoredFlow(
      sourceLabel: 'trigger $triggerId',
      dialogue: dialogue,
      battleFactId: battleFactId,
      expectStaticBattle: expectStaticBattle,
      battleStrategy: battleStrategy,
      expectedTrainerId: expectedTrainerId,
      expectedEnemySpeciesId: expectedEnemySpeciesId,
    );
  }

  Future<void> enterWarp(String warpId) async {
    final sourceMapId = state.currentMapId;
    final warp = _currentMap.warps.singleWhere((entry) => entry.id == warpId);
    if (game.debugPlayerGridPosition == warp.pos) {
      await navigateTo(_adjacentReachableCell(warp.pos));
    }
    await navigateTo(warp.pos);
    await _pumpUntil(
      () =>
          state.currentMapId == warp.targetMapId &&
          !game.debugHasPendingMapTransition,
      label: 'warp $warpId to ${warp.targetMapId} from $sourceMapId',
      allowTransitionClock: true,
    );
    await _settleUntil(
      () =>
          game.debugFlowPhaseName == 'overworld' &&
          !game.debugIsMapActivationDispatchInFlight &&
          !game.debugIsNarrativeSpatialDispatchInFlight,
      label: 'post-warp flow $warpId',
    );
  }

  Future<void> crossConnection(
    MapConnectionDirection direction, {
    int? preferredAxis,
  }) async {
    final sourceMap = _currentMap;
    final connection = sourceMap.connections.singleWhere(
      (entry) => entry.direction == direction,
    );
    final candidates = _connectionBoundaryCandidates(
      sourceMap,
      direction,
      preferredAxis,
    );
    Object? lastFailure;
    for (final boundary in candidates) {
      final path = _pathTo(boundary);
      if (path == null) continue;
      final before = state.currentMapId;
      try {
        await navigateTo(boundary);
        await _tapMovement(_controlForConnection(direction));
        await _pumpUntil(
          () => state.currentMapId == connection.targetMapId,
          label: 'connection ${direction.name} to ${connection.targetMapId}',
          maxTicks: 600,
          allowTransitionClock: true,
        );
        await _pumpUntil(
          () => !game.debugHasPendingMapTransition,
          label: 'connection transition ${direction.name}',
          allowTransitionClock: true,
        );
        await _pumpUntil(
          () => game.debugFlowPhaseName == 'overworld',
          label: 'connection overworld resume ${direction.name}',
          allowTransitionClock: true,
        );
        return;
      } catch (error) {
        lastFailure = error;
        if (state.currentMapId != before) rethrow;
      }
    }
    final rejected =
        _runtimeRejectedEdgesByMapId[sourceMap.id]?.toList() ?? <String>[];
    rejected.sort();
    fail(
      'No production-input route crossed ${sourceMap.id} '
      '${direction.name} to ${connection.targetMapId}; '
      'current=${game.debugPlayerGridPosition}, '
      'lastFailure=$lastFailure, rejectedEdges=$rejected.',
    );
  }

  Future<void> navigateTo(
    GridPos target, {
    MapRect? deferBattleInArea,
  }) async {
    for (var attempt = 0; attempt < 600; attempt++) {
      if (game.debugPlayerGridPosition == target) return;
      if (game.debugFlowPhaseName != 'overworld') {
        fail(
          'Unexpected ${game.debugFlowPhaseName} flow while physically '
          'navigating ${state.currentMapId}.',
        );
      }
      final path = _pathTo(target);
      if (path == null || path.isEmpty) {
        fail(
          'No physical path on ${state.currentMapId} from '
          '${game.debugPlayerGridPosition} to $target.',
        );
      }
      final direction = path.first;
      final before = game.debugPlayerGridPosition;
      await _tapMovement(_controlForDirection(direction));
      if (game.debugPendingBattleRequest != null ||
          game.debugFlowPhaseName == 'battleTransition' ||
          game.debugFlowPhaseName == 'battle') {
        if (deferBattleInArea != null &&
            _contains(deferBattleInArea, game.debugPlayerGridPosition)) {
          return;
        }
        await _pumpUntil(
          () =>
              game.debugFlowPhaseName == 'battleTransition' ||
              game.debugFlowPhaseName == 'battle',
          label: 'incidental encounter handoff',
        );
        await _driveRealBattle(
          expectStaticBattle: false,
          strategy: _BattleStrategy.flee,
        );
        await _settleUntil(
          () => game.debugFlowPhaseName == 'overworld',
          label: 'incidental encounter return to overworld',
        );
      }
      final after = game.debugPlayerGridPosition;
      if (after == before) {
        _runtimeRejectedEdgesByMapId
            .putIfAbsent(state.currentMapId, () => <String>{})
            .add(_edgeKey(before, direction));
      }
    }
    fail(
      'Physical navigation exceeded 600 steps on ${state.currentMapId} '
      'towards $target.',
    );
  }

  Future<void> _handleAuthoredFlow({
    required String sourceLabel,
    _DialogueChoice? dialogue,
    String? battleFactId,
    String? acceptedDefeatFactId,
    bool expectStaticBattle = false,
    _BattleStrategy battleStrategy = _BattleStrategy.win,
    String? expectedTrainerId,
    String? expectedEnemySpeciesId,
  }) async {
    await _pumpUntil(
      () =>
          game.debugFlowPhaseName != 'overworld' ||
          game.debugIsNarrativeSpatialDispatchInFlight,
      label: 'authored spatial dispatch start for $sourceLabel',
    );
    if (dialogue != null) {
      await _pumpUntil(
        () => game.debugFlowPhaseName == 'dialogue',
        label: 'authored Yarn open',
        driveCinematic: true,
      );
      await completeOpenDialogue(dialogue);
    } else if (game.debugFlowPhaseName == 'dialogue') {
      await completeOpenDialogue(const _DialogueChoice());
    }

    if (battleFactId != null) {
      await _pumpUntil(
        () =>
            game.debugFlowPhaseName == 'battleTransition' ||
            game.debugFlowPhaseName == 'battle',
        label: 'authored battle handoff',
        driveCinematic: true,
      );
      await _driveRealBattle(
        expectStaticBattle: expectStaticBattle,
        strategy: battleStrategy,
        expectedTrainerId: expectedTrainerId,
        expectedEnemySpeciesId: expectedEnemySpeciesId,
      );
      await _settleUntil(
        () =>
            state.narrativeFactRuntimeState.overridesByFactId[battleFactId] ==
                true ||
            (acceptedDefeatFactId != null &&
                state.narrativeFactRuntimeState
                        .overridesByFactId[acceptedDefeatFactId] ==
                    true),
        label: 'battle consequence $battleFactId',
      );
      if (battleStrategy == _BattleStrategy.lose) {
        expect(
          acceptedDefeatFactId,
          isNotNull,
          reason: 'A deliberate loss must declare its authored defeat Fact.',
        );
        expect(
          state.narrativeFactRuntimeState
              .overridesByFactId[acceptedDefeatFactId],
          isTrue,
        );
        expect(
          state.narrativeFactRuntimeState.overridesByFactId[battleFactId],
          isNot(isTrue),
        );
      } else {
        expect(
          state.narrativeFactRuntimeState.overridesByFactId[battleFactId],
          isTrue,
          reason: 'This canonical battle must be won to continue.',
        );
      }
      await _settleUntil(
        () =>
            game.debugFlowPhaseName == 'overworld' &&
            !game.debugIsNarrativeSpatialDispatchInFlight &&
            !game.debugIsNarrativeOutcomeWorkInFlight &&
            !game.debugIsCinematicPlaying,
        label: 'authored battle completion for $sourceLabel',
      );
      return;
    }

    await _settleUntil(
      () =>
          game.debugFlowPhaseName == 'overworld' &&
          !game.debugIsNarrativeSpatialDispatchInFlight &&
          !game.debugIsNarrativeOutcomeWorkInFlight &&
          !game.debugIsCinematicPlaying,
      label: 'authored non-battle completion',
    );
  }

  Future<void> completeOpenDialogue(_DialogueChoice choice) async {
    await _pumpUntil(
      () => game.debugFlowPhaseName == 'dialogue',
      label: 'dialogue open',
      driveCinematic: true,
    );
    if (choice.linesBeforeChoice case final lineCount?) {
      for (var line = 0; line < lineCount; line++) {
        _pressPrimary();
        await _microPump();
      }
      for (var move = 0; move < choice.choiceIndex; move++) {
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.down),
          ),
          isTrue,
        );
        await _microPump();
      }
      _pressPrimary();
      await _microPump();
    }
    for (var input = 0; input < 40; input++) {
      if (game.debugFlowPhaseName != 'dialogue') return;
      _pressPrimary();
      await _microPump();
    }
    fail('Yarn did not close after 40 explicit player inputs.');
  }

  Future<void> _driveRealBattle({
    required bool expectStaticBattle,
    _BattleStrategy strategy = _BattleStrategy.win,
    String? expectedTrainerId,
    String? expectedEnemySpeciesId,
  }) async {
    await _pumpUntil(
      () => game.debugFlowPhaseName == 'battle',
      label: 'Battle transition completion',
      allowTransitionClock: true,
    );
    await _waitForBattleInputReady();
    final initialBattle = game.debugBattleSessionSnapshot;
    expect(initialBattle, isNotNull);
    final canUseWildFleeStrategy =
        !initialBattle!.setup.isTrainerBattle && initialBattle.setup.allowFlee;
    final effectiveStrategy =
        strategy == _BattleStrategy.flee && !canUseWildFleeStrategy
            ? _BattleStrategy.win
            : strategy;
    if (expectedTrainerId != null) {
      expect(initialBattle.setup.isTrainerBattle, isTrue);
      expect(initialBattle.setup.trainerId, expectedTrainerId);
    }
    if (expectedEnemySpeciesId != null) {
      expect(initialBattle.state.enemy.speciesId, expectedEnemySpeciesId);
    }
    if (expectStaticBattle) {
      expect(initialBattle.setup.isTrainerBattle, isFalse);
      expect(initialBattle.setup.allowCapture, isFalse);
      expect(initialBattle.setup.allowFlee, isFalse);
      expect(initialBattle.setup.trainerId, isNull);
      expect(initialBattle.state.enemy.speciesId, 'lanturn');
    }

    var medicineAttempted = false;
    for (var turn = 0; turn < 80; turn++) {
      if (game.debugFlowPhaseName != 'battle') return;
      await _waitForBattleInputReady();
      if (game.debugFlowPhaseName != 'battle') return;
      if (effectiveStrategy == _BattleStrategy.flee) {
        await _tryRunFromBattle();
        continue;
      }
      final battle = game.debugBattleSessionSnapshot;
      expect(battle, isNotNull);
      final player = battle!.state.player;
      if (effectiveStrategy == _BattleStrategy.win &&
          !medicineAttempted &&
          player.currentHp < player.maxHp) {
        medicineAttempted = true;
        if (!await _tryUseFirstMedicine()) {
          await _useBestDamagingMove();
        }
      } else if (effectiveStrategy == _BattleStrategy.lose) {
        await _useStatusMove();
      } else {
        await _useBestDamagingMove();
      }
    }
    fail('A real Selbrume battle exceeded 80 turns.');
  }

  Future<void> _tryRunFromBattle() async {
    final overlay = game.debugBattleOverlayComponent;
    expect(overlay, isNotNull);
    final activeOverlay = overlay!;
    if (activeOverlay.currentMenuMode.name == 'continueOnly') {
      _pressPrimary();
      await _waitForBattleInputReady();
      return;
    }
    for (var back = 0;
        back < 3 && activeOverlay.currentMenuMode.name != 'root';
        back++) {
      expect(game.backFromBattleOverlay(), isTrue);
      await _microPump();
    }
    expect(activeOverlay.currentMenuMode.name, 'root');
    await _pressBattleDirection(RuntimeInputControl.up);
    await _pressBattleDirection(RuntimeInputControl.left);
    await _pressBattleDirection(RuntimeInputControl.down);
    await _pressBattleDirection(RuntimeInputControl.right);
    _pressPrimary();
    await _waitForBattleInputReady();
  }

  Future<void> _useBestDamagingMove() async {
    final battle = game.debugBattleSessionSnapshot;
    expect(battle, isNotNull);
    final player = battle!.state.player;
    final enemy = battle.state.enemy;
    final enemyTypes = enemy.typing?.types ?? const <String>[];
    var bestIndex = -1;
    var bestScore = 0.0;
    for (var index = 0; index < player.moves.length; index++) {
      final move = player.moves[index];
      if (move.power <= 0 || move.currentPp <= 0) continue;
      final effectiveness = _moveEffectiveness(move.type, enemyTypes);
      final stab = (player.typing?.hasType(move.type) ?? false) ? 1.5 : 1.0;
      final score = move.power * effectiveness * stab;
      if (score > bestScore) {
        bestScore = score;
        bestIndex = index;
      }
    }
    expect(
      bestIndex,
      greaterThanOrEqualTo(0),
      reason: 'The active battler needs a non-immune damaging move.',
    );
    await _useMoveAtIndex(bestIndex);
  }

  Future<void> _useStatusMove() async {
    final battle = game.debugBattleSessionSnapshot;
    expect(battle, isNotNull);
    final moves = battle!.state.player.moves;
    final statusIndex = moves.indexWhere(
      (move) => move.power == 0 && move.currentPp > 0,
    );
    expect(
      statusIndex,
      greaterThanOrEqualTo(0),
      reason: 'The deliberate-loss proof requires a real status move.',
    );
    await _useMoveAtIndex(statusIndex);
  }

  Future<void> _useMoveAtIndex(int moveIndex) async {
    final overlay = game.debugBattleOverlayComponent;
    expect(overlay, isNotNull);
    final activeOverlay = overlay!;
    if (activeOverlay.currentMenuMode.name == 'continueOnly') {
      _pressPrimary();
      await _waitForBattleInputReady();
      return;
    }
    for (var back = 0;
        back < 3 && activeOverlay.currentMenuMode.name != 'root';
        back++) {
      expect(game.backFromBattleOverlay(), isTrue);
      await _microPump();
    }
    expect(activeOverlay.currentMenuMode.name, 'root');
    await _pressBattleDirection(RuntimeInputControl.up);
    await _pressBattleDirection(RuntimeInputControl.left);
    _pressPrimary();
    await _microPump();
    expect(activeOverlay.currentMenuMode.name, 'fight');
    if (moveIndex >= 2) {
      await _pressBattleDirection(RuntimeInputControl.down);
    }
    if (moveIndex.isOdd) {
      await _pressBattleDirection(RuntimeInputControl.right);
    }
    final battle = game.debugBattleSessionSnapshot;
    expect(battle, isNotNull);
    final selectedMove = battle!.state.player.moves[moveIndex];
    battleMoveChoices.add(
      _BattleMoveChoiceEvidence(
        moveId: selectedMove.id,
        power: selectedMove.power,
        effectiveness: _moveEffectiveness(
          selectedMove.type,
          battle.state.enemy.typing?.types ?? const <String>[],
        ),
      ),
    );
    _pressPrimary();
    await _waitForBattleInputReady();
  }

  Future<bool> _tryUseFirstMedicine() async {
    final overlay = game.debugBattleOverlayComponent;
    expect(overlay, isNotNull);
    final activeOverlay = overlay!;
    for (var back = 0;
        back < 3 && activeOverlay.currentMenuMode.name != 'root';
        back++) {
      expect(game.backFromBattleOverlay(), isTrue);
      await _microPump();
    }
    expect(activeOverlay.currentMenuMode.name, 'root');
    await _pressBattleDirection(RuntimeInputControl.up);
    await _pressBattleDirection(RuntimeInputControl.left);
    await _pressBattleDirection(RuntimeInputControl.right);
    _pressPrimary();
    await _microPump();
    expect(activeOverlay.currentMenuMode.name, 'bag');
    _pressPrimary();
    await _microPump();
    if (activeOverlay.currentMenuMode.name != 'bagMedicineTarget') {
      expect(game.backFromBattleOverlay(), isTrue);
      await _microPump();
      expect(activeOverlay.currentMenuMode.name, 'root');
      return false;
    }
    _pressPrimary();
    await _waitForBattleInputReady();
    return true;
  }

  Future<void> _waitForBattleInputReady() async {
    await game.debugWaitForBattleOverlaySync();
    await _pumpUntil(
      () =>
          game.debugFlowPhaseName != 'battle' ||
          !(game.debugBattleOverlayComponent?.isTurnPresentationActive ??
              false),
      label: 'battle presentation completion',
      allowTransitionClock: true,
    );
  }

  Future<void> _pressBattleDirection(RuntimeInputControl control) async {
    expect(
      game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
      isTrue,
    );
    await _microPump();
  }

  Future<void> _settleUntil(
    bool Function() done, {
    required String label,
  }) {
    return _pumpUntil(
      done,
      label: label,
      driveCinematic: true,
      drivePlainDialogue: true,
      allowTransitionClock: true,
      maxTicks: 6000,
    );
  }

  Future<void> _pumpUntil(
    bool Function() done, {
    required String label,
    int maxTicks = 3000,
    bool driveCinematic = false,
    bool drivePlainDialogue = false,
    bool allowTransitionClock = false,
  }) async {
    for (var tick = 0; tick < maxTicks; tick++) {
      if (done()) return;
      if (driveCinematic &&
          game.debugIsCinematicPlaying &&
          game.debugCinematicDialogueLine != null) {
        _pressPrimary();
      } else if (drivePlainDialogue && game.debugFlowPhaseName == 'dialogue') {
        _pressPrimary();
      }
      game.update(0.016);
      await Future<void>.delayed(
        allowTransitionClock ? const Duration(milliseconds: 1) : Duration.zero,
      );
    }
    fail(
      'Timed out waiting for $label: map=${state.currentMapId}, '
      'pos=${game.debugPlayerGridPosition}, '
      'phase=${game.debugFlowPhaseName}, '
      'notification=${game.debugNotificationText}.',
    );
  }

  Future<void> _microPump() async {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }

  void _pressPrimary() {
    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );
  }

  Future<void> _tapMovement(RuntimeInputControl control) async {
    expect(
      game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
      isTrue,
    );
    game.update(0.016);
    expect(
      game.handleRuntimeInputEvent(RuntimeInputEvent.release(control)),
      isTrue,
    );
    await _pumpUntil(
      () => !game.debugIsPlayerStepping,
      label: 'movement ${control.name}',
      maxTicks: 500,
    );
  }

  MapData get _currentMap => _mapById(state.currentMapId);

  MapData _mapById(String mapId) {
    return _mapsById.putIfAbsent(mapId, () {
      final entry = project.maps.singleWhere((map) => map.id == mapId);
      final json = jsonDecode(
        File(p.join(projectRoot.path, entry.relativePath)).readAsStringSync(),
      ) as Map<String, dynamic>;
      return MapData.fromJson(json);
    });
  }

  GameplayWorldState _pathfindingWorld(MapData map) {
    final projection = const RuntimeWorldRuleProjectionHook().resolve(
      project: project,
      gameState: state,
      map: map,
    );
    bool entityPresence(String _, MapEntity entity) =>
        projection.isMapEntityVisible(entity);
    return GameplayWorldState.initial(
      map: map,
      playerPos: game.debugPlayerGridPosition,
      playerFacing: _directionFromFacing(state.playerFacing),
      project: project,
      tileWidth: project.settings.tileWidth,
      tileHeight: project.settings.tileHeight,
      npcMapPresencePredicate: entityPresence,
      mapEntityPresencePredicate: entityPresence,
    );
  }

  List<Direction>? _pathTo(GridPos target) {
    return _findPath(target, avoidEncounters: true) ??
        _findPath(target, avoidEncounters: false);
  }

  List<Direction>? _findPath(
    GridPos target, {
    required bool avoidEncounters,
  }) {
    final map = _currentMap;
    final world = _pathfindingWorld(map);
    final start = game.debugPlayerGridPosition;
    if (start == target) return <Direction>[];
    if (!_inside(map, target) || world.isBlocked(target.x, target.y)) {
      return null;
    }
    final queue = Queue<GridPos>()..add(start);
    final previous = <GridPos, ({GridPos pos, Direction direction})>{};
    final visited = <GridPos>{start};
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      for (final direction in const <Direction>[
        Direction.north,
        Direction.east,
        Direction.south,
        Direction.west,
      ]) {
        final next = _translated(current, direction);
        if (!_inside(map, next) ||
            visited.contains(next) ||
            (_runtimeRejectedEdgesByMapId[map.id]
                    ?.contains(_edgeKey(current, direction)) ??
                false) ||
            !_canTakePhysicalStep(world, current, direction, next) ||
            (_isUnintendedWarpCell(map, next, target)) ||
            (avoidEncounters && _isEncounterCell(map, next))) {
          continue;
        }
        visited.add(next);
        previous[next] = (pos: current, direction: direction);
        if (next == target) {
          final reversed = <Direction>[];
          var cursor = next;
          while (cursor != start) {
            final edge = previous[cursor]!;
            reversed.add(edge.direction);
            cursor = edge.pos;
          }
          return reversed.reversed.toList(growable: false);
        }
        queue.add(next);
      }
    }
    return null;
  }

  bool _hasGridPath(GameplayWorldState world, GridPos target) {
    final map = _currentMap;
    final start = game.debugPlayerGridPosition;
    final queue = Queue<GridPos>()..add(start);
    final visited = <GridPos>{start};
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      for (final direction in Direction.values) {
        final next = _translated(current, direction);
        if (!_inside(map, next) ||
            visited.contains(next) ||
            world.isBlocked(next.x, next.y)) {
          continue;
        }
        if (next == target) return true;
        visited.add(next);
        queue.add(next);
      }
    }
    return start == target;
  }

  bool _canTakePhysicalStep(
    GameplayWorldState baseWorld,
    GridPos from,
    Direction direction,
    GridPos expectedTarget,
  ) {
    final positioned = baseWorld.withPlayer(
      GameplayPlayerState.fromGridSpawn(
        cell: from,
        facing: direction,
        movementMode: state.playerMovementMode,
        tileWidthPx: project.settings.tileWidth,
        tileHeightPx: project.settings.tileHeight,
        mapWidthCells: baseWorld.map.size.width,
        mapHeightCells: baseWorld.map.size.height,
      ),
    );
    var cursor = positioned;
    for (var pixelStep = 0; pixelStep < 32; pixelStep++) {
      final result = stepGameplayWorld(cursor, MoveIntent(direction));
      if (result is Blocked) return false;
      cursor = result.world;
      if (cursor.player.pos == expectedTarget) return true;
      if (cursor.player.pos != from) return false;
    }
    return false;
  }

  _EntityApproach _shortestReachableApproach(MapEntity entity) {
    final candidates = <_EntityApproach>[];
    for (final entry in <({Direction facing, GridPos position})>[
      (
        facing: Direction.south,
        position: GridPos(x: entity.pos.x, y: entity.pos.y - 1),
      ),
      (
        facing: Direction.west,
        position: GridPos(x: entity.pos.x + entity.size.width, y: entity.pos.y),
      ),
      (
        facing: Direction.north,
        position:
            GridPos(x: entity.pos.x, y: entity.pos.y + entity.size.height),
      ),
      (
        facing: Direction.east,
        position: GridPos(x: entity.pos.x - 1, y: entity.pos.y),
      ),
    ]) {
      final stagingPosition = GridPos(
        x: entry.position.x - entry.facing.dx,
        y: entry.position.y - entry.facing.dy,
      );
      final stagingPath = _pathTo(stagingPosition);
      final approachPath = _pathTo(entry.position);
      if (stagingPath != null && approachPath != null) {
        candidates.add(
          _EntityApproach(
            position: entry.position,
            stagingPosition: stagingPosition,
            facing: entry.facing,
            pathLength: stagingPath.length + 1,
          ),
        );
      }
    }
    if (candidates.isEmpty) {
      fail('Entity ${entity.id} has no reachable interaction front.');
    }
    candidates.sort((a, b) => a.pathLength.compareTo(b.pathLength));
    return candidates.first;
  }

  GridPos _reachableCellInArea(MapRect area) {
    final candidates = <({GridPos pos, int length})>[];
    for (var y = area.pos.y; y < area.pos.y + area.size.height; y++) {
      for (var x = area.pos.x; x < area.pos.x + area.size.width; x++) {
        final pos = GridPos(x: x, y: y);
        final path = _pathTo(pos);
        if (path != null) candidates.add((pos: pos, length: path.length));
      }
    }
    if (candidates.isEmpty) fail('Trigger area $area has no reachable cell.');
    candidates.sort((a, b) => a.length.compareTo(b.length));
    return candidates.first.pos;
  }

  GridPos _adjacentReachableCell(GridPos origin) {
    for (final direction in Direction.values) {
      final candidate = _translated(origin, direction);
      if (_pathTo(candidate) != null) return candidate;
    }
    fail('No reachable exit adjacent to $origin on ${state.currentMapId}.');
  }

  GridPos _reachableCellOutsideArea(MapRect area) {
    final candidates = <({GridPos pos, int length})>[];
    for (var y = area.pos.y - 1; y <= area.pos.y + area.size.height; y++) {
      for (final x in <int>[area.pos.x - 1, area.pos.x + area.size.width]) {
        final pos = GridPos(x: x, y: y);
        final path = _pathTo(pos);
        if (path != null) candidates.add((pos: pos, length: path.length));
      }
    }
    for (var x = area.pos.x; x < area.pos.x + area.size.width; x++) {
      for (final y in <int>[area.pos.y - 1, area.pos.y + area.size.height]) {
        final pos = GridPos(x: x, y: y);
        final path = _pathTo(pos);
        if (path != null) candidates.add((pos: pos, length: path.length));
      }
    }
    if (candidates.isEmpty) {
      fail('Trigger area $area has no reachable outside cell.');
    }
    candidates.sort((a, b) => a.length.compareTo(b.length));
    return candidates.first.pos;
  }

  Iterable<GridPos> _connectionBoundaryCandidates(
    MapData map,
    MapConnectionDirection direction,
    int? preferredAxis,
  ) {
    final result = <GridPos>[];
    final axisLength = switch (direction) {
      MapConnectionDirection.north ||
      MapConnectionDirection.south =>
        map.size.width,
      MapConnectionDirection.east ||
      MapConnectionDirection.west =>
        map.size.height,
    };
    final preferred =
        (preferredAxis ?? axisLength ~/ 2).clamp(0, axisLength - 1);
    final axes = List<int>.generate(axisLength, (index) => index)
      ..sort((a, b) => (a - preferred).abs().compareTo((b - preferred).abs()));
    for (final axis in axes) {
      result.add(
        switch (direction) {
          MapConnectionDirection.north => GridPos(x: axis, y: 0),
          MapConnectionDirection.south =>
            GridPos(x: axis, y: map.size.height - 1),
          MapConnectionDirection.east =>
            GridPos(x: map.size.width - 1, y: axis),
          MapConnectionDirection.west => GridPos(x: 0, y: axis),
        },
      );
    }
    return result;
  }

  bool _isEncounterCell(MapData map, GridPos pos) {
    return map.gameplayZones.any(
      (zone) =>
          zone.kind == GameplayZoneKind.encounter &&
          pos.x >= zone.area.pos.x &&
          pos.y >= zone.area.pos.y &&
          pos.x < zone.area.pos.x + zone.area.size.width &&
          pos.y < zone.area.pos.y + zone.area.size.height,
    );
  }

  bool _isUnintendedWarpCell(MapData map, GridPos pos, GridPos target) {
    if (pos == target) return false;
    return map.warps.any(
      (warp) =>
          warp.triggerMode == MapWarpTriggerMode.onEnter && warp.pos == pos,
    );
  }
}

final class _JourneyPlayableMapGame extends PlayableMapGame {
  _JourneyPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    required super.saveRepository,
  });

  @override
  bool get isLoaded => true;
}

enum _BattleStrategy { win, lose, flee }

final class _SerializedMemoryGameSaveRepository implements GameSaveRepository {
  String? _payload;

  @override
  Future<void> save(GameState value) async {
    _payload = jsonEncode(value.toJson());
  }

  @override
  Future<GameState?> load() async {
    final payload = _payload;
    if (payload == null) return null;
    return normalizeLoadedGameState(
      GameState.fromJson(
        jsonDecode(payload) as Map<String, dynamic>,
      ),
    );
  }

  @override
  Future<bool> exists() async => _payload != null;

  @override
  Future<void> delete() async => _payload = null;
}

final class _DialogueChoice {
  const _DialogueChoice({this.linesBeforeChoice, this.choiceIndex = 0});

  final int? linesBeforeChoice;
  final int choiceIndex;
}

final class _BattleMoveChoiceEvidence {
  const _BattleMoveChoiceEvidence({
    required this.moveId,
    required this.power,
    required this.effectiveness,
  });

  final String moveId;
  final int power;
  final double effectiveness;
}

final class _EntityApproach {
  const _EntityApproach({
    required this.position,
    required this.stagingPosition,
    required this.facing,
    required this.pathLength,
  });

  final GridPos position;
  final GridPos stagingPosition;
  final Direction facing;
  final int pathLength;
}

GridPos _translated(GridPos pos, Direction direction) {
  return switch (direction) {
    Direction.north => GridPos(x: pos.x, y: pos.y - 1),
    Direction.east => GridPos(x: pos.x + 1, y: pos.y),
    Direction.south => GridPos(x: pos.x, y: pos.y + 1),
    Direction.west => GridPos(x: pos.x - 1, y: pos.y),
  };
}

bool _inside(MapData map, GridPos pos) {
  return pos.x >= 0 &&
      pos.y >= 0 &&
      pos.x < map.size.width &&
      pos.y < map.size.height;
}

bool _contains(MapRect area, GridPos pos) {
  return pos.x >= area.pos.x &&
      pos.y >= area.pos.y &&
      pos.x < area.pos.x + area.size.width &&
      pos.y < area.pos.y + area.size.height;
}

double _moveEffectiveness(String attackType, List<String> defenderTypes) {
  const immunityByAttackType = <String, Set<String>>{
    'normal': <String>{'ghost'},
    'fighting': <String>{'ghost'},
    'ghost': <String>{'normal'},
    'electric': <String>{'ground'},
    'ground': <String>{'flying'},
    'psychic': <String>{'dark'},
    'poison': <String>{'steel'},
    'dragon': <String>{'fairy'},
  };
  const canonicalStarterMatchups = <String, Map<String, double>>{
    'normal': <String, double>{'rock': 0.5, 'steel': 0.5},
    'fire': <String, double>{
      'fire': 0.5,
      'water': 0.5,
      'grass': 2,
      'ice': 2,
      'bug': 2,
      'rock': 0.5,
      'dragon': 0.5,
      'steel': 2,
    },
  };
  final normalizedAttack = attackType.trim().toLowerCase();
  var multiplier = 1.0;
  for (final rawDefenderType in defenderTypes) {
    final defenderType = rawDefenderType.trim().toLowerCase();
    if (immunityByAttackType[normalizedAttack]?.contains(defenderType) ??
        false) {
      return 0;
    }
    multiplier *=
        canonicalStarterMatchups[normalizedAttack]?[defenderType] ?? 1;
  }
  return multiplier;
}

Direction _directionFromFacing(EntityFacing facing) {
  return switch (facing) {
    EntityFacing.north => Direction.north,
    EntityFacing.east => Direction.east,
    EntityFacing.south => Direction.south,
    EntityFacing.west => Direction.west,
  };
}

RuntimeInputControl _controlForDirection(Direction direction) {
  return switch (direction) {
    Direction.north => RuntimeInputControl.up,
    Direction.east => RuntimeInputControl.right,
    Direction.south => RuntimeInputControl.down,
    Direction.west => RuntimeInputControl.left,
  };
}

RuntimeInputControl _controlForConnection(MapConnectionDirection direction) {
  return switch (direction) {
    MapConnectionDirection.north => RuntimeInputControl.up,
    MapConnectionDirection.east => RuntimeInputControl.right,
    MapConnectionDirection.south => RuntimeInputControl.down,
    MapConnectionDirection.west => RuntimeInputControl.left,
  };
}

String _edgeKey(GridPos from, Direction direction) =>
    '${from.x}:${from.y}:${direction.name}';

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      throw StateError('pokemonProject repository root not found.');
    }
    current = current.parent;
  }
}
~~~~~~

### `packages/map_core/lib/src/models/project_new_game_config.dart`

- Taille : `7996` octets
- SHA-256 : `1707f01d5f59f46fabbbe5af7dfe7e9ccc864661d137ce441255bafe2314507d`

~~~~~~dart
import 'package:meta/meta.dart' show immutable;

import 'save_data.dart';

@immutable
final class ProjectStarterOption {
  const ProjectStarterOption({
    required this.id,
    required this.label,
    required this.pokemon,
  });

  factory ProjectStarterOption.fromJson(Map<String, dynamic> json) {
    return ProjectStarterOption(
      id: _readRequiredString(json, 'id'),
      label: _readRequiredString(json, 'label'),
      pokemon: PlayerPokemon.fromJson(_readObject(json, 'pokemon')),
    );
  }

  final String id;
  final String label;
  final PlayerPokemon pokemon;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'label': label,
        'pokemon': pokemon.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectStarterOption &&
          other.id == id &&
          other.label == label &&
          other.pokemon == pokemon;

  @override
  int get hashCode => Object.hash(id, label, pokemon);
}

/// Project-owned contract used to create a real new game without host fixtures.
///
/// The config deliberately describes state only. Narrative presentation and
/// starter selection remain authored as Yarn/Scene/Event assets referenced by
/// [starterSelectionSceneId].
@immutable
final class ProjectNewGameConfig {
  const ProjectNewGameConfig({
    this.enabled = false,
    this.startMapId = '',
    this.startSpawnId,
    this.playerName = 'Player',
    this.startingMoney = 0,
    this.initialBag = const <BagEntry>[],
    this.initialParty = const <PlayerPokemon>[],
    this.initialFacts = const <String, bool>{},
    this.existingPartyFactId,
    this.starterSelectionSceneId,
    this.starterOptions = const <ProjectStarterOption>[],
  });

  factory ProjectNewGameConfig.fromJson(Map<String, dynamic> json) {
    return ProjectNewGameConfig(
      enabled: _readBool(json, 'enabled', fallback: false),
      startMapId: _readString(json, 'startMapId') ?? '',
      startSpawnId: _readString(json, 'startSpawnId'),
      playerName: _readString(json, 'playerName') ?? 'Player',
      startingMoney: _readInt(json, 'startingMoney', fallback: 0),
      initialBag: _readObjectList(json, 'initialBag')
          .map(BagEntry.fromJson)
          .toList(growable: false),
      initialParty: _readObjectList(json, 'initialParty')
          .map(PlayerPokemon.fromJson)
          .toList(growable: false),
      initialFacts: _readBoolMap(json, 'initialFacts'),
      existingPartyFactId: _readString(json, 'existingPartyFactId'),
      starterSelectionSceneId: _readString(json, 'starterSelectionSceneId'),
      starterOptions: _readObjectList(json, 'starterOptions')
          .map(ProjectStarterOption.fromJson)
          .toList(growable: false),
    );
  }

  final bool enabled;
  final String startMapId;
  final String? startSpawnId;
  final String playerName;
  final int startingMoney;
  final List<BagEntry> initialBag;
  final List<PlayerPokemon> initialParty;
  final Map<String, bool> initialFacts;
  final String? existingPartyFactId;
  final String? starterSelectionSceneId;
  final List<ProjectStarterOption> starterOptions;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'enabled': enabled,
        'startMapId': startMapId,
        if (startSpawnId != null) 'startSpawnId': startSpawnId,
        'playerName': playerName,
        'startingMoney': startingMoney,
        'initialBag': initialBag.map((entry) => entry.toJson()).toList(),
        'initialParty': initialParty.map((member) => member.toJson()).toList(),
        'initialFacts': Map<String, bool>.from(initialFacts),
        if (existingPartyFactId != null)
          'existingPartyFactId': existingPartyFactId,
        if (starterSelectionSceneId != null)
          'starterSelectionSceneId': starterSelectionSceneId,
        'starterOptions':
            starterOptions.map((option) => option.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectNewGameConfig &&
          other.enabled == enabled &&
          other.startMapId == startMapId &&
          other.startSpawnId == startSpawnId &&
          other.playerName == playerName &&
          other.startingMoney == startingMoney &&
          _listEquals(other.initialBag, initialBag) &&
          _listEquals(other.initialParty, initialParty) &&
          _mapEquals(other.initialFacts, initialFacts) &&
          other.existingPartyFactId == existingPartyFactId &&
          other.starterSelectionSceneId == starterSelectionSceneId &&
          _listEquals(other.starterOptions, starterOptions);

  @override
  int get hashCode => Object.hash(
        enabled,
        startMapId,
        startSpawnId,
        playerName,
        startingMoney,
        Object.hashAll(initialBag),
        Object.hashAll(initialParty),
        Object.hashAllUnordered(initialFacts.entries),
        existingPartyFactId,
        starterSelectionSceneId,
        Object.hashAll(starterOptions),
      );
}

String _readRequiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('ProjectStarterOption.$key must be a string.');
  }
  return value;
}

String? _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('ProjectNewGameConfig.$key must be a string.');
  }
  return value;
}

bool _readBool(
  Map<String, dynamic> json,
  String key, {
  required bool fallback,
}) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is! bool) {
    throw FormatException('ProjectNewGameConfig.$key must be a boolean.');
  }
  return value;
}

int _readInt(
  Map<String, dynamic> json,
  String key, {
  required int fallback,
}) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is! int) {
    throw FormatException('ProjectNewGameConfig.$key must be an integer.');
  }
  return value;
}

Map<String, dynamic> _readObject(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map) {
    throw FormatException('ProjectStarterOption.$key must be an object.');
  }
  return Map<String, dynamic>.from(value);
}

List<Map<String, dynamic>> _readObjectList(
  Map<String, dynamic> json,
  String key,
) {
  final value = json[key];
  if (value == null) return const <Map<String, dynamic>>[];
  if (value is! List) {
    throw FormatException('ProjectNewGameConfig.$key must be a list.');
  }
  return <Map<String, dynamic>>[
    for (final item in value)
      if (item is Map)
        Map<String, dynamic>.from(item)
      else
        throw FormatException(
          'ProjectNewGameConfig.$key entries must be objects.',
        ),
  ];
}

Map<String, bool> _readBoolMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return const <String, bool>{};
  if (value is! Map) {
    throw FormatException('ProjectNewGameConfig.$key must be an object.');
  }
  final decoded = <String, bool>{};
  for (final entry in value.entries) {
    if (entry.key is! String || entry.value is! bool) {
      throw FormatException(
        'ProjectNewGameConfig.$key must contain boolean values.',
      );
    }
    decoded[entry.key as String] = entry.value as bool;
  }
  return decoded;
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V> left, Map<K, V> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (!right.containsKey(entry.key) || right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}
~~~~~~

### `packages/map_core/lib/src/operations/narrative_project_validator.dart`

- Taille : `64640` octets
- SHA-256 : `5bb172076c8bf3cb0f949a0fb0b5c3ce51921a398672695ec68125b47bca6843`

~~~~~~dart
import 'package:meta/meta.dart' show immutable;

import '../diagnostics/cinematic_diagnostics.dart';
import '../diagnostics/event_scene_link_diagnostics.dart';
import '../diagnostics/scene_diagnostics.dart';
import '../diagnostics/storyline_scene_link_diagnostics.dart';
import '../diagnostics/world_rule_diagnostics.dart';
import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/map_event_definition.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/project_manifest.dart';
import '../models/scenario_asset.dart';
import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';
import '../models/script_conditions.dart';
import '../models/storyline_asset.dart';
import '../models/world_rule.dart';
import '../read_models/narrative_event_validation_read_model.dart';
import '../validation/beta_playability_validator.dart';
import 'build_narrative_event_project_catalog.dart';
import 'build_narrative_event_validation_report.dart';
import 'narrative_validator.dart';

/// Severity shared by every diagnostic displayed by Narrative Validator.
enum NarrativeProjectDiagnosticSeverity { info, warning, error }

/// Stable product domains used by filters and navigation.
enum NarrativeProjectDiagnosticDomain {
  storyline,
  scene,
  event,
  dialogue,
  cinematic,
  fact,
  worldRule,
  map,
  runtime,
}

/// Product routes supported by the global Validator.
enum NarrativeProjectDiagnosticDestination {
  overview,
  map,
  event,
  scene,
  storyline,
  dialogue,
  cinematic,
  fact,
  worldRule,
}

enum NarrativeMapEventsGroupKind { map, outcomes, unassigned }

@immutable
final class NarrativeProjectDiagnostic {
  const NarrativeProjectDiagnostic({
    required this.code,
    required this.severity,
    required this.domain,
    required this.message,
    required this.path,
    required this.destination,
    this.suggestedFixLabel,
    this.mapId,
    this.eventId,
    this.sceneId,
    this.dialogueId,
    this.cinematicId,
    this.storylineId,
    this.chapterId,
    this.stepId,
    this.factId,
    this.worldRuleId,
  });

  final String code;
  final NarrativeProjectDiagnosticSeverity severity;
  final NarrativeProjectDiagnosticDomain domain;
  final String message;
  final String path;
  final NarrativeProjectDiagnosticDestination destination;
  final String? suggestedFixLabel;
  final String? mapId;
  final String? eventId;
  final String? sceneId;
  final String? dialogueId;
  final String? cinematicId;
  final String? storylineId;
  final String? chapterId;
  final String? stepId;
  final String? factId;
  final String? worldRuleId;

  /// Validator V1 never advertises a mutation unless it is deterministic.
  /// No aggregated diagnostic currently satisfies that contract.
  bool get hasDeterministicRepair => false;

  String get stableKey => <String?>[
        severity.name,
        domain.name,
        code,
        path,
        mapId,
        eventId,
        sceneId,
        dialogueId,
        cinematicId,
        storylineId,
        chapterId,
        stepId,
        factId,
        worldRuleId,
      ].map((value) => value ?? '').join('\u001f');
}

@immutable
final class NarrativeMapEventEntry {
  const NarrativeMapEventEntry({
    required this.eventId,
    required this.label,
    required this.enabled,
    required this.sourceKind,
    required this.sourceConnected,
    required this.sceneId,
    required this.sceneConnected,
    required this.conditionCount,
    required this.diagnosticCount,
    this.warningCount = 0,
    this.mapId,
    this.sourceOwnerId,
    this.sourceOwnerLabel,
    this.sourceEntityKind,
    this.sceneLabel,
  });

  final String eventId;
  final String label;
  final bool? enabled;
  final NarrativeEventSourceKind? sourceKind;
  final String? mapId;
  final String? sourceOwnerId;
  final String? sourceOwnerLabel;
  final MapEntityKind? sourceEntityKind;
  final bool sourceConnected;
  final String? sceneId;
  final String? sceneLabel;
  final bool sceneConnected;
  final int conditionCount;
  final int diagnosticCount;
  final int warningCount;
}

@immutable
final class NarrativeMapEventsView {
  NarrativeMapEventsView({
    required this.groupKind,
    required this.mapId,
    required this.label,
    required List<NarrativeMapEventEntry> events,
  }) : events = List<NarrativeMapEventEntry>.unmodifiable(events);

  final NarrativeMapEventsGroupKind groupKind;
  final String? mapId;
  final String label;
  final List<NarrativeMapEventEntry> events;

  int get errorCount =>
      events.fold(0, (sum, event) => sum + event.diagnosticCount);
  int get orphanSourceCount =>
      events.where((event) => !event.sourceConnected).length;
}

@immutable
final class NarrativeProjectValidationReport {
  NarrativeProjectValidationReport({
    required List<NarrativeProjectDiagnostic> diagnostics,
    required List<NarrativeMapEventsView> mapEventViews,
  })  : diagnostics =
            List<NarrativeProjectDiagnostic>.unmodifiable(diagnostics),
        mapEventViews =
            List<NarrativeMapEventsView>.unmodifiable(mapEventViews);

  final List<NarrativeProjectDiagnostic> diagnostics;
  final List<NarrativeMapEventsView> mapEventViews;

  int get errorCount => diagnostics
      .where(
          (item) => item.severity == NarrativeProjectDiagnosticSeverity.error)
      .length;
  int get warningCount => diagnostics
      .where(
          (item) => item.severity == NarrativeProjectDiagnosticSeverity.warning)
      .length;
  int get infoCount => diagnostics
      .where((item) => item.severity == NarrativeProjectDiagnosticSeverity.info)
      .length;
  int get totalEventCount => mapEventViews.fold(
        0,
        (sum, view) => sum + view.events.length,
      );
  bool get isPlayable => errorCount == 0;

  List<NarrativeProjectDiagnostic> byCode(String code) =>
      List<NarrativeProjectDiagnostic>.unmodifiable(
        diagnostics.where((item) => item.code == code),
      );

  List<NarrativeProjectDiagnostic> byDomain(
    NarrativeProjectDiagnosticDomain domain,
  ) =>
      List<NarrativeProjectDiagnostic>.unmodifiable(
        diagnostics.where((item) => item.domain == domain),
      );
}

/// Builds the single narrative playability verdict used by the editor.
///
/// Existing domain diagnostics remain the source of truth. This operation
/// maps them into one stable report, then adds only the cross-domain static
/// solvability checks that cannot belong to an individual asset validator.
NarrativeProjectValidationReport validateNarrativeProject(
  ProjectManifest project, {
  required List<MapData> maps,
  Set<String>? knownSpeciesIds,
  Set<String>? knownMoveIds,
  bool requirePokemonCatalogs = false,
}) {
  final diagnostics = <NarrativeProjectDiagnostic>[];
  final mapsById = {for (final map in maps) map.id: map};
  final normalizedKnownSpeciesIds =
      knownSpeciesIds == null ? null : _trimmedNonBlankIds(knownSpeciesIds);
  final normalizedKnownMoveIds =
      knownMoveIds == null ? null : _trimmedNonBlankIds(knownMoveIds);

  _appendLegacyNarrativeDiagnostics(project, maps, diagnostics);
  _appendSceneDiagnostics(project, diagnostics);
  _appendSceneBattleReadinessDiagnostics(
    project,
    diagnostics,
    knownSpeciesIds: normalizedKnownSpeciesIds,
    knownMoveIds: normalizedKnownMoveIds,
  );
  _appendStorylineLinkDiagnostics(project, diagnostics);
  _appendCinematicDiagnostics(project, diagnostics);
  _appendWorldRuleDiagnostics(project, maps, diagnostics);
  _appendEventSceneLinkDiagnostics(project, maps, diagnostics);
  _appendEventV2Diagnostics(project, maps, diagnostics);
  _appendRuntimeReadinessDiagnostics(
    project,
    mapsById,
    diagnostics,
    knownSpeciesIds: normalizedKnownSpeciesIds,
    knownMoveIds: normalizedKnownMoveIds,
    requirePokemonCatalogs: requirePokemonCatalogs,
  );
  _appendSolvabilityDiagnostics(project, maps, diagnostics);

  final normalized = <String, NarrativeProjectDiagnostic>{};
  for (final diagnostic in diagnostics) {
    normalized.putIfAbsent(diagnostic.stableKey, () => diagnostic);
  }
  final sorted = normalized.values.toList()..sort(_compareDiagnostics);
  final mapViews = _buildMapEventViews(
    project,
    mapsById: mapsById,
    diagnostics: sorted,
  );
  return NarrativeProjectValidationReport(
    diagnostics: sorted,
    mapEventViews: mapViews,
  );
}

void _appendLegacyNarrativeDiagnostics(
  ProjectManifest project,
  List<MapData> maps,
  List<NarrativeProjectDiagnostic> target,
) {
  for (final diagnostic
      in diagnoseNarrativeProject(project, maps: maps).diagnostics) {
    target.add(
      NarrativeProjectDiagnostic(
        code: diagnostic.kind.name,
        severity: _legacySeverityForProject(project, diagnostic),
        domain: _legacyDomain(diagnostic.kind),
        message: diagnostic.message,
        path: diagnostic.path,
        destination: _legacyDestination(diagnostic),
        mapId: diagnostic.mapId,
        sceneId: diagnostic.scenarioId,
        dialogueId: _legacyDialogueId(diagnostic),
      ),
    );
  }
}

void _appendSceneDiagnostics(
  ProjectManifest project,
  List<NarrativeProjectDiagnostic> target,
) {
  for (final scene in project.scenes) {
    for (final diagnostic
        in diagnoseSceneAgainstProject(scene, project).diagnostics) {
      final dialogueId =
          diagnostic.code == SceneDiagnosticCode.dialogueRefUnknown
              ? _sceneNodeDialogueId(scene, diagnostic.nodeId)
              : null;
      target.add(
        NarrativeProjectDiagnostic(
          code: diagnostic.code.name,
          severity: switch (diagnostic.severity) {
            SceneDiagnosticSeverity.error =>
              NarrativeProjectDiagnosticSeverity.error,
            SceneDiagnosticSeverity.warning =>
              NarrativeProjectDiagnosticSeverity.warning,
            SceneDiagnosticSeverity.info =>
              NarrativeProjectDiagnosticSeverity.info,
          },
          domain: dialogueId == null
              ? NarrativeProjectDiagnosticDomain.scene
              : NarrativeProjectDiagnosticDomain.dialogue,
          message: diagnostic.message,
          path: 'scenes.${scene.id}.${diagnostic.target.name}',
          destination: dialogueId == null
              ? NarrativeProjectDiagnosticDestination.scene
              : NarrativeProjectDiagnosticDestination.dialogue,
          suggestedFixLabel: diagnostic.suggestedFixLabel,
          sceneId: scene.id,
          dialogueId: dialogueId,
        ),
      );
    }
  }
}

void _appendStorylineLinkDiagnostics(
  ProjectManifest project,
  List<NarrativeProjectDiagnostic> target,
) {
  for (final diagnostic
      in diagnoseStorylineSceneLinks(project: project).diagnostics) {
    target.add(
      NarrativeProjectDiagnostic(
        code: diagnostic.code.name,
        severity: switch (diagnostic.severity) {
          StorylineSceneLinkDiagnosticSeverity.error =>
            NarrativeProjectDiagnosticSeverity.error,
          StorylineSceneLinkDiagnosticSeverity.warning =>
            NarrativeProjectDiagnosticSeverity.warning,
          StorylineSceneLinkDiagnosticSeverity.info =>
            NarrativeProjectDiagnosticSeverity.info,
        },
        domain: NarrativeProjectDiagnosticDomain.storyline,
        message: diagnostic.message,
        path:
            'storylines.${diagnostic.storylineId}.${diagnostic.chapterId}.${diagnostic.stepId}',
        destination: NarrativeProjectDiagnosticDestination.storyline,
        suggestedFixLabel: diagnostic.suggestedFixLabel,
        storylineId: diagnostic.storylineId,
        chapterId: diagnostic.chapterId,
        stepId: diagnostic.stepId,
        sceneId: diagnostic.sceneId,
      ),
    );
  }
}

void _appendCinematicDiagnostics(
  ProjectManifest project,
  List<NarrativeProjectDiagnostic> target,
) {
  for (final diagnostic
      in diagnoseCinematicsAgainstProject(project).diagnostics) {
    target.add(
      NarrativeProjectDiagnostic(
        code: diagnostic.code.name,
        severity: switch (diagnostic.severity) {
          CinematicDiagnosticSeverity.error =>
            NarrativeProjectDiagnosticSeverity.error,
          CinematicDiagnosticSeverity.warning =>
            NarrativeProjectDiagnosticSeverity.warning,
          CinematicDiagnosticSeverity.info =>
            NarrativeProjectDiagnosticSeverity.info,
        },
        domain: NarrativeProjectDiagnosticDomain.cinematic,
        message: diagnostic.message,
        path: 'cinematics.${diagnostic.cinematicId}.${diagnostic.target.name}',
        destination: NarrativeProjectDiagnosticDestination.cinematic,
        suggestedFixLabel: diagnostic.suggestedFixLabel,
        cinematicId: diagnostic.cinematicId,
      ),
    );
  }
}

void _appendWorldRuleDiagnostics(
  ProjectManifest project,
  List<MapData> maps,
  List<NarrativeProjectDiagnostic> target,
) {
  for (final diagnostic
      in diagnoseWorldRules(project, maps: maps).diagnostics) {
    target.add(
      NarrativeProjectDiagnostic(
        code: diagnostic.code.name,
        severity: switch (diagnostic.severity) {
          WorldRuleDiagnosticSeverity.error =>
            NarrativeProjectDiagnosticSeverity.error,
          WorldRuleDiagnosticSeverity.warning =>
            NarrativeProjectDiagnosticSeverity.warning,
          WorldRuleDiagnosticSeverity.info =>
            NarrativeProjectDiagnosticSeverity.info,
        },
        domain: NarrativeProjectDiagnosticDomain.worldRule,
        message: diagnostic.message,
        path: 'worldRules.${diagnostic.ruleId}',
        destination: NarrativeProjectDiagnosticDestination.worldRule,
        suggestedFixLabel: diagnostic.suggestedFixLabel,
        mapId: diagnostic.mapId,
        worldRuleId: diagnostic.ruleId,
      ),
    );
  }
}

void _appendEventSceneLinkDiagnostics(
  ProjectManifest project,
  List<MapData> maps,
  List<NarrativeProjectDiagnostic> target,
) {
  for (final diagnostic
      in diagnoseEventSceneLinks(project: project, maps: maps).diagnostics) {
    target.add(
      NarrativeProjectDiagnostic(
        code: diagnostic.code.name,
        severity: switch (diagnostic.severity) {
          EventSceneLinkDiagnosticSeverity.error =>
            NarrativeProjectDiagnosticSeverity.error,
          EventSceneLinkDiagnosticSeverity.warning =>
            NarrativeProjectDiagnosticSeverity.warning,
          EventSceneLinkDiagnosticSeverity.info =>
            NarrativeProjectDiagnosticSeverity.info,
        },
        domain: NarrativeProjectDiagnosticDomain.event,
        message: diagnostic.message,
        path:
            'maps.${diagnostic.mapId}.events.${diagnostic.eventId}.pages.${diagnostic.pageNumber}',
        destination: NarrativeProjectDiagnosticDestination.event,
        suggestedFixLabel: diagnostic.suggestedFixLabel,
        mapId: diagnostic.mapId,
        eventId: diagnostic.eventId,
        sceneId: diagnostic.sceneId,
      ),
    );
  }
}

void _appendEventV2Diagnostics(
  ProjectManifest project,
  List<MapData> maps,
  List<NarrativeProjectDiagnostic> target,
) {
  final registry = project.eventRegistry;
  if (registry == null) return;
  final catalog =
      buildNarrativeEventProjectCatalog(project: project, maps: maps);
  final report = buildNarrativeEventValidationReport(
    registry: registry,
    catalog: catalog,
  );
  for (final diagnostic in report.diagnostics) {
    final destination = diagnostic.destination;
    target.add(
      NarrativeProjectDiagnostic(
        code: diagnostic.code,
        severity: switch (diagnostic.severity) {
          NarrativeEventValidationSeverity.error =>
            NarrativeProjectDiagnosticSeverity.error,
          NarrativeEventValidationSeverity.warning =>
            NarrativeProjectDiagnosticSeverity.warning,
          NarrativeEventValidationSeverity.info =>
            NarrativeProjectDiagnosticSeverity.info,
        },
        domain: NarrativeProjectDiagnosticDomain.event,
        message: diagnostic.message,
        path: diagnostic.path,
        destination: _eventDestination(destination.kind, destination.mapId),
        mapId: destination.mapId ?? _eventMapId(project, diagnostic.eventId),
        eventId: diagnostic.eventId ?? destination.eventId,
        sceneId: destination.sceneId,
      ),
    );
  }
}

void _appendRuntimeReadinessDiagnostics(
  ProjectManifest project,
  Map<String, MapData> mapsById,
  List<NarrativeProjectDiagnostic> target, {
  required Set<String>? knownSpeciesIds,
  required Set<String>? knownMoveIds,
  required bool requirePokemonCatalogs,
}) {
  final newGame = project.newGame;
  _appendConfiguredNewGameSpawnDiagnostics(project, mapsById, target);
  _appendPokemonCatalogAvailabilityDiagnostics(
    project,
    target,
    knownSpeciesIds: knownSpeciesIds,
    knownMoveIds: knownMoveIds,
    required: requirePokemonCatalogs,
  );
  final report = validateBetaPlayability(
    project,
    context: BetaPlayabilityValidationContext(
      mapsById: mapsById,
      startMapId: newGame.enabled ? newGame.startMapId : null,
      knownSpeciesIds: knownSpeciesIds ?? const <String>{},
      knownMoveIds: knownMoveIds ?? const <String>{},
      speciesCatalogIsAuthoritative: knownSpeciesIds != null,
      moveCatalogIsAuthoritative: knownMoveIds != null,
      initialPartySpeciesIds: {
        for (final pokemon in newGame.initialParty) pokemon.speciesId,
        for (final option in newGame.starterOptions) option.pokemon.speciesId,
      },
      initialPartyMoveIds: {
        for (final pokemon in newGame.initialParty)
          for (final move in pokemon.knownMoveIds) move,
        for (final option in newGame.starterOptions)
          for (final move in option.pokemon.knownMoveIds) move,
      },
      requiresInitialParty: false,
      requiresTrainerBattle: project.trainers.isNotEmpty,
      requiresSaveLoad: true,
      hasSaveLoadSupport: true,
    ),
  );
  for (final diagnostic in report.diagnostics) {
    target.add(
      NarrativeProjectDiagnostic(
        code: 'runtime${_upperFirst(diagnostic.kind.name)}',
        severity: switch (diagnostic.severity) {
          BetaPlayabilityDiagnosticSeverity.error =>
            NarrativeProjectDiagnosticSeverity.error,
          BetaPlayabilityDiagnosticSeverity.warning =>
            NarrativeProjectDiagnosticSeverity.warning,
          BetaPlayabilityDiagnosticSeverity.info =>
            NarrativeProjectDiagnosticSeverity.info,
        },
        domain: NarrativeProjectDiagnosticDomain.runtime,
        message: diagnostic.message,
        path: diagnostic.path ?? 'runtime',
        destination: diagnostic.mapId == null
            ? NarrativeProjectDiagnosticDestination.overview
            : NarrativeProjectDiagnosticDestination.map,
        suggestedFixLabel: diagnostic.actionHint,
        mapId: diagnostic.mapId,
      ),
    );
  }
}

void _appendPokemonCatalogAvailabilityDiagnostics(
  ProjectManifest project,
  List<NarrativeProjectDiagnostic> target, {
  required Set<String>? knownSpeciesIds,
  required Set<String>? knownMoveIds,
  required bool required,
}) {
  if (!required) return;
  if (knownSpeciesIds == null) {
    target.add(
      NarrativeProjectDiagnostic(
        code: 'runtimePokemonSpeciesCatalogUnavailable',
        severity: NarrativeProjectDiagnosticSeverity.error,
        domain: NarrativeProjectDiagnosticDomain.runtime,
        message:
            'Le catalogue des espèces Pokémon n’a pas pu être chargé pour la validation.',
        path: 'pokemon.speciesDir',
        destination: NarrativeProjectDiagnosticDestination.overview,
        suggestedFixLabel: 'Vérifier le dossier ${project.pokemon.speciesDir}.',
      ),
    );
  }
  if (knownMoveIds == null) {
    target.add(
      NarrativeProjectDiagnostic(
        code: 'runtimePokemonMoveCatalogUnavailable',
        severity: NarrativeProjectDiagnosticSeverity.error,
        domain: NarrativeProjectDiagnosticDomain.runtime,
        message:
            'Le catalogue des capacités Pokémon n’a pas pu être chargé pour la validation.',
        path: 'pokemon.catalogFiles.moves',
        destination: NarrativeProjectDiagnosticDestination.overview,
        suggestedFixLabel: 'Vérifier le fichier du catalogue des capacités.',
      ),
    );
  }
}

void _appendConfiguredNewGameSpawnDiagnostics(
  ProjectManifest project,
  Map<String, MapData> mapsById,
  List<NarrativeProjectDiagnostic> target,
) {
  final newGame = project.newGame;
  final spawnId = newGame.startSpawnId?.trim();
  if (!newGame.enabled || spawnId == null || spawnId.isEmpty) return;

  final mapId = newGame.startMapId.trim();
  final map = mapsById[mapId];
  if (map == null) return;

  MapEntity? spawn;
  for (final entity in map.entities) {
    if (entity.id == spawnId) {
      spawn = entity;
      break;
    }
  }
  final path = 'maps.$mapId.entities.$spawnId';
  if (spawn == null) {
    target.add(
      NarrativeProjectDiagnostic(
        code: 'runtimeNewGameStartSpawnMissing',
        severity: NarrativeProjectDiagnosticSeverity.error,
        domain: NarrativeProjectDiagnosticDomain.runtime,
        message:
            'Le point de départ New Game « $spawnId » est absent de la map configurée.',
        path: path,
        destination: NarrativeProjectDiagnosticDestination.map,
        suggestedFixLabel: 'Choisir un point de départ joueur existant.',
        mapId: mapId,
      ),
    );
    return;
  }

  if (spawn.kind != MapEntityKind.spawn ||
      spawn.spawn?.role != EntitySpawnRole.playerStart) {
    target.add(
      NarrativeProjectDiagnostic(
        code: 'runtimeNewGameStartSpawnNotPlayerStart',
        severity: NarrativeProjectDiagnosticSeverity.error,
        domain: NarrativeProjectDiagnosticDomain.runtime,
        message:
            'Le point de départ New Game « $spawnId » doit être un Spawn de rôle playerStart.',
        path: path,
        destination: NarrativeProjectDiagnosticDestination.map,
        suggestedFixLabel: 'Configurer cette entité comme départ joueur.',
        mapId: mapId,
      ),
    );
    return;
  }

  if (!_entityOriginIsInsideMap(map, spawn)) {
    target.add(
      NarrativeProjectDiagnostic(
        code: 'runtimeNewGameStartSpawnOutOfBounds',
        severity: NarrativeProjectDiagnosticSeverity.error,
        domain: NarrativeProjectDiagnosticDomain.runtime,
        message:
            'Le point de départ New Game « $spawnId » se trouve hors des limites de la map.',
        path: path,
        destination: NarrativeProjectDiagnosticDestination.map,
        suggestedFixLabel: 'Replacer le départ joueur dans la map.',
        mapId: mapId,
      ),
    );
  }
}

void _appendSceneBattleReadinessDiagnostics(
  ProjectManifest project,
  List<NarrativeProjectDiagnostic> target, {
  required Set<String>? knownSpeciesIds,
  required Set<String>? knownMoveIds,
}) {
  final trainersById = {
    for (final trainer in project.trainers) trainer.id.trim(): trainer,
  };
  for (final scene in project.scenes) {
    for (final node in scene.graph.nodes) {
      final payload = node.payload;
      if (payload is! SceneBattlePayload ||
          (payload.battleKind != 'trainer' && payload.battleKind != 'static')) {
        continue;
      }
      final trainerId = payload.trainerId?.trim();
      final trainer = trainerId == null ? null : trainersById[trainerId];
      // Unknown references are already diagnosed by diagnoseSceneAgainstProject.
      if (trainerId == null || trainerId.isEmpty || trainer == null) continue;

      final nodePath = 'scenes.${scene.id}.nodes.${node.id}.battle';
      if (trainer.team.isEmpty) {
        target.add(
          _sceneBattleDiagnostic(
            code: 'sceneBattleTrainerHasEmptyTeam',
            message:
                'L’adversaire « $trainerId » de ce combat ne possède aucun Pokémon.',
            path: '$nodePath.trainerId',
            sceneId: scene.id,
            suggestedFixLabel: 'Ajouter au moins un Pokémon à son équipe.',
          ),
        );
        continue;
      }

      for (var index = 0; index < trainer.team.length; index += 1) {
        final pokemon = trainer.team[index];
        final pokemonPath = '$nodePath.trainer.$trainerId.team.$index';
        final speciesId = pokemon.speciesId.trim();
        if (speciesId.isEmpty) {
          target.add(
            _sceneBattleDiagnostic(
              code: 'sceneBattleTrainerPokemonMissingSpecies',
              message:
                  'Un Pokémon de l’adversaire « $trainerId » ne référence aucune espèce.',
              path: '$pokemonPath.speciesId',
              sceneId: scene.id,
              suggestedFixLabel: 'Choisir une espèce dans le catalogue.',
            ),
          );
        } else if (knownSpeciesIds != null &&
            !knownSpeciesIds.contains(speciesId)) {
          target.add(
            _sceneBattleDiagnostic(
              code: 'sceneBattleTrainerPokemonSpeciesUnknown',
              message:
                  'L’espèce « $speciesId » de l’adversaire « $trainerId » est absente du catalogue.',
              path: '$pokemonPath.speciesId',
              sceneId: scene.id,
              suggestedFixLabel: 'Choisir une espèce existante.',
            ),
          );
        }

        final normalizedMoveIds = pokemon.moves
            .map((moveId) => moveId.trim())
            .where((moveId) => moveId.isNotEmpty)
            .toList(growable: false);
        if (normalizedMoveIds.isEmpty) {
          target.add(
            _sceneBattleDiagnostic(
              code: 'sceneBattleTrainerPokemonMissingMoves',
              message:
                  'Un Pokémon de l’adversaire « $trainerId » ne possède aucune capacité utilisable.',
              path: '$pokemonPath.moves',
              sceneId: scene.id,
              suggestedFixLabel: 'Ajouter au moins une capacité.',
            ),
          );
        } else if (normalizedMoveIds.length != pokemon.moves.length) {
          target.add(
            _sceneBattleDiagnostic(
              code: 'sceneBattleTrainerPokemonMoveIdBlank',
              message:
                  'Une capacité de l’adversaire « $trainerId » possède une référence vide.',
              path: '$pokemonPath.moves',
              sceneId: scene.id,
              suggestedFixLabel: 'Retirer ou remplacer la capacité vide.',
            ),
          );
        }
        if (knownMoveIds != null) {
          for (final moveId in normalizedMoveIds) {
            if (knownMoveIds.contains(moveId)) continue;
            target.add(
              _sceneBattleDiagnostic(
                code: 'sceneBattleTrainerPokemonMoveUnknown',
                message:
                    'La capacité « $moveId » de l’adversaire « $trainerId » est absente du catalogue.',
                path: '$pokemonPath.moves',
                sceneId: scene.id,
                suggestedFixLabel: 'Choisir une capacité existante.',
              ),
            );
          }
        }
      }
    }
  }
}

Set<String> _trimmedNonBlankIds(Iterable<String> values) => values
    .map((value) => value.trim())
    .where((value) => value.isNotEmpty)
    .toSet();

NarrativeProjectDiagnostic _sceneBattleDiagnostic({
  required String code,
  required String message,
  required String path,
  required String sceneId,
  required String suggestedFixLabel,
}) {
  return NarrativeProjectDiagnostic(
    code: code,
    severity: NarrativeProjectDiagnosticSeverity.error,
    domain: NarrativeProjectDiagnosticDomain.scene,
    message: message,
    path: path,
    destination: NarrativeProjectDiagnosticDestination.scene,
    suggestedFixLabel: suggestedFixLabel,
    sceneId: sceneId,
  );
}

void _appendSolvabilityDiagnostics(
  ProjectManifest project,
  List<MapData> maps,
  List<NarrativeProjectDiagnostic> target,
) {
  final reachability = _solveNarrativeReachability(project, maps);
  final reachableSceneIds = reachability.sceneIds;
  final producedFacts = reachability.trueFactIds;
  final completedSteps = reachability.completedStepIds;
  final registry = project.eventRegistry;

  final requiredFacts = <String>{};
  if (registry != null) {
    for (final record in registry.records) {
      final definition = record.definitionOrNull;
      if (definition == null || record.enabledOrNull != true) continue;
      for (final condition in definition.conditions) {
        condition.when(
          fact: (factId, expectedValue) {
            if (expectedValue) requiredFacts.add(factId);
          },
          narrativeEventConsumed: (_, __) {},
        );
      }
    }
  }
  for (final rule in project.worldRules) {
    if (rule.enabled &&
        rule.source.kind == WorldRuleSourceKind.fact &&
        rule.source.predicate == WorldRuleSourcePredicate.isTrue) {
      requiredFacts.add(rule.source.sourceId);
    }
  }
  for (final factId in requiredFacts.difference(producedFacts)) {
    target.add(
      NarrativeProjectDiagnostic(
        code: 'requiredFactNeverProduced',
        severity: NarrativeProjectDiagnosticSeverity.error,
        domain: NarrativeProjectDiagnosticDomain.fact,
        message:
            'Le Fact « $factId » est requis par le parcours mais aucune Scene ni configuration initiale ne le produit.',
        path: 'facts.$factId',
        destination: NarrativeProjectDiagnosticDestination.fact,
        suggestedFixLabel: 'Ajouter une conséquence Définir un Fact.',
        factId: factId,
      ),
    );
  }

  for (final storyline in project.storylines) {
    if (storyline.status == StorylineStatus.disabled ||
        storyline.status == StorylineStatus.archived) {
      continue;
    }
    final steps = <({String chapterId, StorylineStep step})>[
      for (final chapter
          in (storyline.chapters.toList()
            ..sort((a, b) => a.order.compareTo(b.order))))
        for (final step
            in (chapter.steps.toList()
              ..sort((a, b) => a.order.compareTo(b.order))))
          (chapterId: chapter.id, step: step),
    ];
    var impossible = false;
    if (steps.isEmpty) {
      impossible = true;
      target.addAll([
        _storylineShapeDiagnostic(
          code: 'storylineMissingBeginning',
          message: 'La storyline ne possède aucune étape de départ.',
          storyline: storyline,
        ),
        _storylineShapeDiagnostic(
          code: 'storylineMissingEnding',
          message: 'La storyline ne possède aucune étape de fin.',
          storyline: storyline,
        ),
      ]);
    } else {
      final first = steps.first;
      if (!_stepHasReachableScene(first.step, reachableSceneIds)) {
        impossible = true;
        target.add(
          _stepDiagnostic(
            code: 'storylineMissingBeginning',
            message: 'La première étape ne possède aucune Scene déclenchable.',
            storyline: storyline,
            chapterId: first.chapterId,
            step: first.step,
          ),
        );
      }
      for (final entry in steps) {
        if (!_stepHasReachableScene(entry.step, reachableSceneIds)) {
          impossible = true;
          target.add(
            _stepDiagnostic(
              code: 'storylineStepInaccessible',
              message: 'L’étape ne possède aucune Scene liée à un Event actif.',
              storyline: storyline,
              chapterId: entry.chapterId,
              step: entry.step,
            ),
          );
        }
        if (!completedSteps.contains(entry.step.id)) {
          impossible = true;
          target.add(
            _stepDiagnostic(
              code: 'storylineStepNeverCompleted',
              message: 'Aucune conséquence narrative ne termine cette étape.',
              storyline: storyline,
              chapterId: entry.chapterId,
              step: entry.step,
            ),
          );
        }
      }
      final last = steps.last;
      if (!completedSteps.contains(last.step.id)) {
        target.add(
          _stepDiagnostic(
            code: 'storylineMissingEnding',
            message: 'La dernière étape ne peut pas être terminée.',
            storyline: storyline,
            chapterId: last.chapterId,
            step: last.step,
          ),
        );
      }
    }
    if (impossible) {
      target.add(
        _storylineShapeDiagnostic(
          code: 'storylineImpossible',
          message: storyline.type == StorylineType.sideQuest
              ? 'Cette quête ne possède pas de parcours statiquement solvable.'
              : 'Cette storyline ne possède pas de parcours statiquement solvable.',
          storyline: storyline,
        ),
      );
    }
  }
}

({
  Set<String> sceneIds,
  Set<String> trueFactIds,
  Set<String> completedStepIds,
}) _solveNarrativeReachability(
  ProjectManifest project,
  List<MapData> maps,
) {
  final mapsById = {for (final map in maps) map.id: map};
  final possibleFactValues = <String, Set<bool>>{
    for (final fact in project.facts)
      fact.id: <bool>{
        project.newGame.initialFacts[fact.id] ?? fact.defaultValue,
      },
  };
  for (final entry in project.newGame.initialFacts.entries) {
    possibleFactValues.putIfAbsent(entry.key, () => <bool>{entry.value});
  }
  final reachableSceneIds = <String>{};
  final reachableSceneOutcomeKeys = <String>{};
  final reachableEventIds = <String>{};
  final completedStepIds = <String>{};

  final registry = project.eventRegistry;
  var changed = true;
  while (changed) {
    changed = false;

    for (final map in maps) {
      for (final event in map.events) {
        final pages = _staticallyApplicableLegacyPages(
          event,
          mapId: map.id,
          possibleFactValues: possibleFactValues,
          reachableEventIds: reachableEventIds,
        );
        for (final page in pages) {
          if (page.isDisabled) continue;
          final sceneId = page.sceneTarget?.sceneId.trim();
          if (sceneId != null &&
              sceneId.isNotEmpty &&
              reachableSceneIds.add(sceneId)) {
            changed = true;
          }
        }
      }
    }

    if (registry != null) {
      for (final record in registry.records) {
        if (record.enabledOrNull != true ||
            reachableEventIds.contains(record.id)) {
          continue;
        }
        final definition = record.definitionOrNull;
        if (definition == null ||
            !_eventSourceStaticallyReachable(
              definition.source,
              mapsById: mapsById,
              reachableSceneOutcomeKeys: reachableSceneOutcomeKeys,
            ) ||
            !_eventConditionsStaticallyReachable(
              definition.conditions,
              possibleFactValues: possibleFactValues,
              reachableEventIds: reachableEventIds,
            )) {
          continue;
        }
        if (reachableEventIds.add(record.id)) changed = true;
        if (reachableSceneIds.add(definition.sceneId)) changed = true;
      }
    }

    for (final scene in project.scenes) {
      if (!reachableSceneIds.contains(scene.id)) continue;
      final reachableNodeIds = _reachableSceneNodeIds(
        scene,
        possibleFactValues: possibleFactValues,
        reachableEventIds: reachableEventIds,
        completedStepIds: completedStepIds,
      );
      for (final node in scene.graph.nodes) {
        if (!reachableNodeIds.contains(node.id)) continue;
        final payload = node.payload;
        if (payload is SceneEndPayload && payload.sceneOutcomeId != null) {
          if (reachableSceneOutcomeKeys.add(
            _sceneOutcomeKey(scene.id, payload.sceneOutcomeId!),
          )) {
            changed = true;
          }
          continue;
        }
        if (payload is! SceneActionPayload || payload.consequence == null) {
          continue;
        }
        switch (payload.consequence!) {
          case SceneSetFactConsequence(:final factId, :final value):
            if (possibleFactValues
                .putIfAbsent(factId, () => <bool>{})
                .add(value)) {
              changed = true;
            }
          case SceneCompleteStoryStepConsequence(:final stepId):
            if (completedStepIds.add(stepId)) changed = true;
          case SceneMarkEventConsumedConsequence(:final eventId):
            if (reachableEventIds.add(eventId)) changed = true;
          case SceneGiveItemConsequence():
          case SceneTakeItemConsequence():
          case SceneGiveMoneyConsequence():
          case SceneGivePokemonConsequence():
          case SceneGiveConfiguredStarterConsequence():
            break;
        }
      }
    }

    for (final storyline in project.storylines) {
      for (final link in storyline.sceneLinks) {
        final sceneId = link.sceneRef?.targetId.trim();
        if (sceneId == null || !reachableSceneIds.contains(sceneId)) continue;
        for (final outcome in link.outcomeLinks) {
          if (!reachableSceneOutcomeKeys.contains(
            _sceneOutcomeKey(sceneId, outcome.outcomeId),
          )) {
            continue;
          }
          for (final effect in outcome.effects) {
            if (effect.type == StorylineEffectType.completeStep &&
                completedStepIds.add(effect.targetId)) {
              changed = true;
            }
            if (effect.type == StorylineEffectType.emitFact) {
              final value = effect.value?.trim().toLowerCase() != 'false';
              if (possibleFactValues
                  .putIfAbsent(effect.targetId, () => <bool>{})
                  .add(value)) {
                changed = true;
              }
            }
          }
        }
      }
    }
  }

  return (
    sceneIds: reachableSceneIds,
    trueFactIds: <String>{
      for (final entry in possibleFactValues.entries)
        if (entry.value.contains(true)) entry.key,
    },
    completedStepIds: completedStepIds,
  );
}

bool _eventSourceStaticallyReachable(
  NarrativeEventSourceRef source, {
  required Map<String, MapData> mapsById,
  required Set<String> reachableSceneOutcomeKeys,
}) {
  return source.when(
    entityInteract: (mapId, entityId) => _sourceConnected(
      NarrativeEventSourceRef.entityInteract(mapId, entityId),
      mapsById,
    ),
    triggerEnter: (mapId, triggerId) => _sourceConnected(
      NarrativeEventSourceRef.triggerEnter(mapId, triggerId),
      mapsById,
    ),
    mapEnter: (mapId) => mapsById.containsKey(mapId),
    outcomeReceived: (outcome) =>
        outcome.producerKind != NarrativeOutcomeProducerKind.scene ||
        reachableSceneOutcomeKeys.contains(
          _sceneOutcomeKey(outcome.producerId, outcome.outcomeId),
        ),
  );
}

List<MapEventPage> _staticallyApplicableLegacyPages(
  MapEventDefinition event, {
  required String mapId,
  required Map<String, Set<bool>> possibleFactValues,
  required Set<String> reachableEventIds,
}) {
  // EventPageResolver observes list order. We therefore evaluate the complete
  // condition chain for each possible authored boolean state and retain the
  // first selected page for that state. Merely taking the first page that can
  // be true is insufficient: it would incorrectly hide a fallback whenever
  // the same condition can also become false. Conversely, evaluating pages in
  // isolation would invent a fallback after exhaustive `flag set` / `unset`
  // pages. Unsupported or malformed conditions fail closed for the residual
  // states instead of exposing a producer the runtime may never select.
  final variables = <String>{};
  for (final page in event.pages) {
    final condition = page.condition;
    if (condition != null) {
      _collectLegacyConditionVariables(condition, variables);
    }
  }

  final orderedVariables = variables.toList(growable: false)..sort();
  const maxAssignments = 4096;
  var assignmentCount = 1;
  for (final variable in orderedVariables) {
    final valueCount = _legacyVariableValues(
      variable,
      possibleFactValues: possibleFactValues,
      reachableEventIds: reachableEventIds,
    ).length;
    if (valueCount == 0 || assignmentCount > maxAssignments ~/ valueCount) {
      return _deterministicallyApplicableLegacyPages(
        event,
        mapId: mapId,
        possibleFactValues: possibleFactValues,
        reachableEventIds: reachableEventIds,
      );
    }
    assignmentCount *= valueCount;
  }
  final selectedIndexes = <int>{};
  final assignment = <String, bool>{};

  void selectForAssignment() {
    for (var index = 0; index < event.pages.length; index++) {
      final condition = event.pages[index].condition;
      if (condition == null) {
        selectedIndexes.add(index);
        return;
      }
      final matches = _evaluateLegacyConditionForAssignment(
        condition,
        mapId: mapId,
        assignment: assignment,
      );
      if (matches == null) return;
      if (matches) {
        selectedIndexes.add(index);
        return;
      }
    }
  }

  void enumerateAssignments(int index) {
    if (index == orderedVariables.length) {
      selectForAssignment();
      return;
    }
    final variable = orderedVariables[index];
    final values = _legacyVariableValues(
      variable,
      possibleFactValues: possibleFactValues,
      reachableEventIds: reachableEventIds,
    );
    for (final value in values) {
      assignment[variable] = value;
      enumerateAssignments(index + 1);
    }
    assignment.remove(variable);
  }

  enumerateAssignments(0);
  return [
    for (var index = 0; index < event.pages.length; index++)
      if (selectedIndexes.contains(index)) event.pages[index],
  ];
}

Set<bool> _legacyVariableValues(
  String variable, {
  required Map<String, Set<bool>> possibleFactValues,
  required Set<String> reachableEventIds,
}) {
  final separatorIndex = variable.indexOf('\u001f');
  if (separatorIndex < 1 || separatorIndex == variable.length - 1) {
    return const <bool>{};
  }
  final kind = variable.substring(0, separatorIndex);
  final id = variable.substring(separatorIndex + 1);
  return switch (kind) {
    'fact' => possibleFactValues[id] ?? const <bool>{false},
    'event' => reachableEventIds.contains(id)
        ? const <bool>{false, true}
        : const <bool>{false},
    _ => const <bool>{},
  };
}

List<MapEventPage> _deterministicallyApplicableLegacyPages(
  MapEventDefinition event, {
  required String mapId,
  required Map<String, Set<bool>> possibleFactValues,
  required Set<String> reachableEventIds,
}) {
  final assignment = <String, bool>{};
  for (final page in event.pages) {
    final condition = page.condition;
    if (condition == null) return [page];

    final conditionVariables = <String>{};
    _collectLegacyConditionVariables(condition, conditionVariables);
    for (final variable in conditionVariables) {
      final values = _legacyVariableValues(
        variable,
        possibleFactValues: possibleFactValues,
        reachableEventIds: reachableEventIds,
      );
      if (values.length != 1) return const <MapEventPage>[];
      assignment[variable] = values.single;
    }
    final matches = _evaluateLegacyConditionForAssignment(
      condition,
      mapId: mapId,
      assignment: assignment,
    );
    if (matches == null) return const <MapEventPage>[];
    if (matches) return [page];
  }
  return const <MapEventPage>[];
}

void _collectLegacyConditionVariables(
  ScriptCondition condition,
  Set<String> target,
) {
  switch (condition.type) {
    case ScriptConditionType.flagIsSet:
    case ScriptConditionType.flagIsUnset:
      final factId = condition.params[ScriptConditionParams.flagName]?.trim();
      if (factId != null && factId.isNotEmpty) {
        target.add('fact\u001f$factId');
      }
    case ScriptConditionType.eventIsConsumed:
      final eventId = condition.params[ScriptConditionParams.eventId]?.trim();
      if (eventId != null && eventId.isNotEmpty) {
        target.add('event\u001f$eventId');
      }
    case ScriptConditionType.allOf:
    case ScriptConditionType.anyOf:
    case ScriptConditionType.not:
    case ScriptConditionType.playerOnMap:
    case ScriptConditionType.variableEquals:
    case ScriptConditionType.variableGreaterThan:
    case ScriptConditionType.variableLessThan:
    case ScriptConditionType.fieldAbilityUnlocked:
    case ScriptConditionType.partyHasMove:
    case ScriptConditionType.partyHasUsableMove:
      break;
  }
  for (final child in condition.children) {
    _collectLegacyConditionVariables(child, target);
  }
}

bool? _evaluateLegacyConditionForAssignment(
  ScriptCondition condition, {
  required String mapId,
  required Map<String, bool> assignment,
}) {
  final children = [
    for (final child in condition.children)
      _evaluateLegacyConditionForAssignment(
        child,
        mapId: mapId,
        assignment: assignment,
      ),
  ];
  switch (condition.type) {
    case ScriptConditionType.allOf:
      if (children.any((child) => child == null)) return null;
      return children.every((child) => child!);
    case ScriptConditionType.anyOf:
      if (children.any((child) => child == null)) return null;
      return children.any((child) => child!);
    case ScriptConditionType.not:
      if (children.length != 1 || children.single == null) return null;
      return !children.single!;
    case ScriptConditionType.flagIsSet:
    case ScriptConditionType.flagIsUnset:
      final factId = condition.params[ScriptConditionParams.flagName]?.trim();
      if (factId == null || factId.isEmpty) return null;
      final expected = condition.type == ScriptConditionType.flagIsSet;
      return assignment['fact\u001f$factId'] == expected;
    case ScriptConditionType.eventIsConsumed:
      final eventId = condition.params[ScriptConditionParams.eventId]?.trim();
      if (eventId == null || eventId.isEmpty) return null;
      return assignment['event\u001f$eventId'];
    case ScriptConditionType.playerOnMap:
      final expectedMapId =
          condition.params[ScriptConditionParams.mapId]?.trim();
      if (expectedMapId == null || expectedMapId.isEmpty) return null;
      return expectedMapId == mapId;
    case ScriptConditionType.variableEquals:
    case ScriptConditionType.variableGreaterThan:
    case ScriptConditionType.variableLessThan:
    case ScriptConditionType.fieldAbilityUnlocked:
    case ScriptConditionType.partyHasMove:
    case ScriptConditionType.partyHasUsableMove:
      return null;
  }
}

String _sceneOutcomeKey(String sceneId, String outcomeId) =>
    '$sceneId\u001f$outcomeId';

bool _entityOriginIsInsideMap(MapData map, MapEntity entity) {
  return entity.pos.x >= 0 &&
      entity.pos.y >= 0 &&
      entity.pos.x < map.size.width &&
      entity.pos.y < map.size.height;
}

bool _eventConditionsStaticallyReachable(
  List<NarrativeEventCondition> conditions, {
  required Map<String, Set<bool>> possibleFactValues,
  required Set<String> reachableEventIds,
}) {
  return conditions.every(
    (condition) => condition.when(
      fact: (factId, expectedValue) =>
          possibleFactValues[factId]?.contains(expectedValue) == true,
      narrativeEventConsumed: (eventId, expectedValue) =>
          expectedValue ? reachableEventIds.contains(eventId) : true,
    ),
  );
}

List<NarrativeMapEventsView> _buildMapEventViews(
  ProjectManifest project, {
  required Map<String, MapData> mapsById,
  required List<NarrativeProjectDiagnostic> diagnostics,
}) {
  final mapLabels = {for (final entry in project.maps) entry.id: entry.name};
  final groups = <String?, List<NarrativeMapEventEntry>>{};
  final registry = project.eventRegistry;
  if (registry != null) {
    for (final record in registry.records) {
      final source = _recordSource(record);
      final identity = _sourceIdentity(source);
      final presentation = _sourceOwnerPresentation(source, mapsById);
      final mapId = identity.mapId;
      final groupKey = source == null
          ? '__unassigned__'
          : source.kind == NarrativeEventSourceKind.outcomeReceived
              ? '__outcomes__'
              : mapId;
      final sceneId = _recordSceneId(record);
      groups.putIfAbsent(groupKey, () => <NarrativeMapEventEntry>[]).add(
            NarrativeMapEventEntry(
              eventId: record.id,
              label: _recordLabel(record),
              enabled: record.enabledOrNull,
              sourceKind: source?.kind,
              mapId: mapId,
              sourceOwnerId: identity.ownerId,
              sourceOwnerLabel: presentation.label,
              sourceEntityKind: presentation.entityKind,
              sourceConnected: _sourceConnected(source, mapsById),
              sceneId: sceneId,
              sceneLabel: _sceneLabel(project, sceneId),
              sceneConnected: sceneId != null &&
                  project.scenes.any((scene) => scene.id == sceneId),
              conditionCount: _recordConditions(record).length,
              diagnosticCount: diagnostics
                  .where((diagnostic) =>
                      diagnostic.eventId == record.id &&
                      diagnostic.severity ==
                          NarrativeProjectDiagnosticSeverity.error)
                  .length,
              warningCount: diagnostics
                  .where((diagnostic) =>
                      diagnostic.eventId == record.id &&
                      diagnostic.severity ==
                          NarrativeProjectDiagnosticSeverity.warning)
                  .length,
            ),
          );
    }
  }

  final views = <NarrativeMapEventsView>[
    for (final entry in project.maps)
      NarrativeMapEventsView(
        groupKind: NarrativeMapEventsGroupKind.map,
        mapId: entry.id,
        label: entry.name,
        events: groups.remove(entry.id) ?? const [],
      ),
  ];
  for (final entry in groups.entries.where(
    (entry) => entry.key != '__outcomes__' && entry.key != '__unassigned__',
  )) {
    views.add(
      NarrativeMapEventsView(
        groupKind: NarrativeMapEventsGroupKind.map,
        mapId: entry.key,
        label: mapLabels[entry.key] ?? entry.key ?? 'Map inconnue',
        events: entry.value,
      ),
    );
  }
  final outcomes = groups['__outcomes__'];
  if (outcomes != null && outcomes.isNotEmpty) {
    views.add(
      NarrativeMapEventsView(
        groupKind: NarrativeMapEventsGroupKind.outcomes,
        mapId: null,
        label: 'Résultats narratifs',
        events: outcomes,
      ),
    );
  }
  final unassigned = groups['__unassigned__'];
  if (unassigned != null && unassigned.isNotEmpty) {
    views.add(
      NarrativeMapEventsView(
        groupKind: NarrativeMapEventsGroupKind.unassigned,
        mapId: null,
        label: 'Sources à configurer',
        events: unassigned,
      ),
    );
  }
  return views;
}

NarrativeProjectDiagnostic _storylineShapeDiagnostic({
  required String code,
  required String message,
  required StorylineAsset storyline,
}) =>
    NarrativeProjectDiagnostic(
      code: code,
      severity: NarrativeProjectDiagnosticSeverity.error,
      domain: NarrativeProjectDiagnosticDomain.storyline,
      message: message,
      path: 'storylines.${storyline.id}',
      destination: NarrativeProjectDiagnosticDestination.storyline,
      storylineId: storyline.id,
    );

NarrativeProjectDiagnostic _stepDiagnostic({
  required String code,
  required String message,
  required StorylineAsset storyline,
  required String chapterId,
  required StorylineStep step,
}) =>
    NarrativeProjectDiagnostic(
      code: code,
      severity: NarrativeProjectDiagnosticSeverity.error,
      domain: NarrativeProjectDiagnosticDomain.storyline,
      message: message,
      path: 'storylines.${storyline.id}.$chapterId.${step.id}',
      destination: NarrativeProjectDiagnosticDestination.storyline,
      storylineId: storyline.id,
      chapterId: chapterId,
      stepId: step.id,
    );

bool _stepHasReachableScene(StorylineStep step, Set<String> enabledSceneIds) =>
    step.sceneLinkIds.any(enabledSceneIds.contains);

Set<String> _reachableSceneNodeIds(
  SceneAsset scene, {
  required Map<String, Set<bool>> possibleFactValues,
  required Set<String> reachableEventIds,
  required Set<String> completedStepIds,
}) {
  final nodesById = {for (final node in scene.graph.nodes) node.id: node};
  final outgoing = <String, List<SceneEdge>>{};
  for (final edge in scene.graph.edges) {
    if (!nodesById.containsKey(edge.fromNodeId) ||
        !nodesById.containsKey(edge.toNodeId)) {
      continue;
    }
    outgoing.putIfAbsent(edge.fromNodeId, () => <SceneEdge>[]).add(edge);
  }
  final reachable = <String>{};
  final pending = <String>[scene.graph.startNodeId];
  while (pending.isNotEmpty) {
    final nodeId = pending.removeLast();
    final node = nodesById[nodeId];
    if (node == null || !reachable.add(nodeId)) continue;
    for (final edge in outgoing[nodeId] ?? const <SceneEdge>[]) {
      if (_sceneEdgeIsStaticallyTraversable(
        node,
        edge,
        possibleFactValues: possibleFactValues,
        reachableEventIds: reachableEventIds,
        completedStepIds: completedStepIds,
      )) {
        pending.add(edge.toNodeId);
      }
    }
  }
  return reachable;
}

bool _sceneEdgeIsStaticallyTraversable(
  SceneNode node,
  SceneEdge edge, {
  required Map<String, Set<bool>> possibleFactValues,
  required Set<String> reachableEventIds,
  required Set<String> completedStepIds,
}) {
  switch (node.kind) {
    case SceneNodeKind.start:
    case SceneNodeKind.merge:
      return edge.fromPortId == 'completed' &&
          edge.kind == SceneEdgeKind.defaultFlow;
    case SceneNodeKind.end:
    case SceneNodeKind.branchByOutcome:
      return false;
    case SceneNodeKind.action:
      return edge.fromPortId == 'completed' &&
          (edge.kind == SceneEdgeKind.defaultFlow ||
              edge.kind == SceneEdgeKind.actionCompleted);
    case SceneNodeKind.cinematic:
      return edge.fromPortId == 'completed' &&
          edge.kind == SceneEdgeKind.cinematicCompleted;
    case SceneNodeKind.battle:
      return edge.fromPortId == 'victory' &&
              edge.kind == SceneEdgeKind.battleVictory ||
          edge.fromPortId == 'defeat' &&
              edge.kind == SceneEdgeKind.battleDefeat;
    case SceneNodeKind.yarnDialogue:
      final payload = node.payload as SceneYarnDialoguePayload;
      if (edge.fromPortId == 'completed') {
        return edge.kind == SceneEdgeKind.defaultFlow;
      }
      return payload.expectedOutcomes.contains(edge.fromPortId) &&
          edge.kind == SceneEdgeKind.dialogueOutcome;
    case SceneNodeKind.condition:
      final possibility = _sceneConditionPossibility(
        (node.payload as SceneConditionPayload).conditionSource,
        possibleFactValues: possibleFactValues,
        reachableEventIds: reachableEventIds,
        completedStepIds: completedStepIds,
      );
      return edge.fromPortId == 'true' &&
              edge.kind == SceneEdgeKind.conditionTrue &&
              possibility.canBeTrue ||
          edge.fromPortId == 'false' &&
              edge.kind == SceneEdgeKind.conditionFalse &&
              possibility.canBeFalse;
  }
}

({bool canBeTrue, bool canBeFalse}) _sceneConditionPossibility(
  SceneConditionSource? source, {
  required Map<String, Set<bool>> possibleFactValues,
  required Set<String> reachableEventIds,
  required Set<String> completedStepIds,
}) {
  if (source == null) return (canBeTrue: true, canBeFalse: true);

  Set<bool>? values;
  switch (source.sourceKind) {
    case SceneConditionSourceKind.fact:
    case SceneConditionSourceKind.factLikeStoryFlag:
      values = possibleFactValues[source.sourceId];
    case SceneConditionSourceKind.storyStepCompletion:
      values = completedStepIds.contains(source.sourceId)
          ? const <bool>{false, true}
          : const <bool>{false};
    case SceneConditionSourceKind.consumedEvent:
      values = reachableEventIds.contains(source.sourceId)
          ? const <bool>{false, true}
          : const <bool>{false};
    case SceneConditionSourceKind.storyStepActive:
    case SceneConditionSourceKind.inventoryItem:
    case SceneConditionSourceKind.partyState:
    case SceneConditionSourceKind.trainerDefeated:
    case SceneConditionSourceKind.dialogueOutcome:
    case SceneConditionSourceKind.battleOutcome:
    case SceneConditionSourceKind.scriptVariable:
    case SceneConditionSourceKind.worldState:
      return (canBeTrue: true, canBeFalse: true);
  }
  if (values == null || values.isEmpty) {
    return (canBeTrue: true, canBeFalse: true);
  }

  bool? matches(bool value) {
    return switch (source.operator) {
      SceneConditionOperator.isTrue => value,
      SceneConditionOperator.isFalse => !value,
      SceneConditionOperator.equals => switch (source.value) {
          'true' || SceneConditionValues.completed => value,
          'false' || SceneConditionValues.notCompleted => !value,
          _ => null,
        },
    };
  }

  final results = {for (final value in values) matches(value)};
  if (results.contains(null)) {
    return (canBeTrue: true, canBeFalse: true);
  }
  return (
    canBeTrue: results.contains(true),
    canBeFalse: results.contains(false),
  );
}

String? _sceneNodeDialogueId(SceneAsset scene, String? nodeId) {
  if (nodeId == null) return null;
  for (final node in scene.graph.nodes) {
    if (node.id == nodeId && node.payload is SceneYarnDialoguePayload) {
      return (node.payload as SceneYarnDialoguePayload).dialogueId;
    }
  }
  return null;
}

String? _legacyDialogueId(NarrativeValidationDiagnostic diagnostic) {
  return switch (diagnostic.kind) {
    NarrativeValidationDiagnosticKind.openDialogueReferencesUnknownDialogue ||
    NarrativeValidationDiagnosticKind
          .conditionalDialogueReferencesUnknownDialogue =>
      diagnostic.referencedId,
    _ => null,
  };
}

NarrativeProjectDiagnosticDomain _legacyDomain(
  NarrativeValidationDiagnosticKind kind,
) =>
    switch (kind) {
      NarrativeValidationDiagnosticKind.openDialogueReferencesUnknownDialogue ||
      NarrativeValidationDiagnosticKind
            .conditionalDialogueReferencesUnknownDialogue =>
        NarrativeProjectDiagnosticDomain.dialogue,
      NarrativeValidationDiagnosticKind.flagReadNeverProduced ||
      NarrativeValidationDiagnosticKind.setFlagNeverRead =>
        NarrativeProjectDiagnosticDomain.fact,
      NarrativeValidationDiagnosticKind
          .visibilityRuleConditionalMissingPredicate ||
      NarrativeValidationDiagnosticKind.worldRulePredicateEmptyRefId =>
        NarrativeProjectDiagnosticDomain.worldRule,
      _ => NarrativeProjectDiagnosticDomain.storyline,
    };

NarrativeProjectDiagnosticDestination _legacyDestination(
  NarrativeValidationDiagnostic diagnostic,
) {
  if (diagnostic.mapId != null) {
    return NarrativeProjectDiagnosticDestination.map;
  }
  if (_legacyDialogueId(diagnostic) != null) {
    return NarrativeProjectDiagnosticDestination.dialogue;
  }
  if (_legacyDomain(diagnostic.kind) == NarrativeProjectDiagnosticDomain.fact) {
    return NarrativeProjectDiagnosticDestination.fact;
  }
  return NarrativeProjectDiagnosticDestination.storyline;
}

NarrativeProjectDiagnosticSeverity _legacySeverity(
  NarrativeValidationSeverity severity,
) =>
    switch (severity) {
      NarrativeValidationSeverity.error =>
        NarrativeProjectDiagnosticSeverity.error,
      NarrativeValidationSeverity.warning =>
        NarrativeProjectDiagnosticSeverity.warning,
    };

NarrativeProjectDiagnosticSeverity _legacySeverityForProject(
  ProjectManifest project,
  NarrativeValidationDiagnostic diagnostic,
) {
  if (diagnostic.kind ==
          NarrativeValidationDiagnosticKind.scenarioGraphHasNoSource &&
      project.storylines.isNotEmpty) {
    ScenarioAsset? scenario;
    for (final candidate in project.scenarios) {
      if (candidate.id == diagnostic.scenarioId) {
        scenario = candidate;
        break;
      }
    }
    if (scenario?.scope == ScenarioScope.globalStory &&
        scenario!.metadata.containsKey('authoring.globalStoryStudioSchema')) {
      return NarrativeProjectDiagnosticSeverity.warning;
    }
  }
  return _legacySeverity(diagnostic.severity);
}

NarrativeProjectDiagnosticDestination _eventDestination(
  NarrativeEventValidationDestinationKind kind,
  String? mapId,
) =>
    switch (kind) {
      NarrativeEventValidationDestinationKind.mapSource =>
        NarrativeProjectDiagnosticDestination.map,
      NarrativeEventValidationDestinationKind.eventSource when mapId != null =>
        NarrativeProjectDiagnosticDestination.map,
      NarrativeEventValidationDestinationKind.scene =>
        NarrativeProjectDiagnosticDestination.scene,
      _ => NarrativeProjectDiagnosticDestination.event,
    };

String? _eventMapId(ProjectManifest project, String? eventId) {
  if (eventId == null) return null;
  final registry = project.eventRegistry;
  if (registry == null) return null;
  for (final record in registry.records) {
    if (record.id == eventId) {
      return _sourceIdentity(_recordSource(record)).mapId;
    }
  }
  return null;
}

NarrativeEventSourceRef? _recordSource(NarrativeEventRecord record) =>
    record.when(
      draft: (draft) => draft.source,
      configured: (definition, _) => definition.source,
    );

String? _recordSceneId(NarrativeEventRecord record) => record.when(
      draft: (draft) => draft.sceneId,
      configured: (definition, _) => definition.sceneId,
    );

String? _sceneLabel(ProjectManifest project, String? sceneId) {
  if (sceneId == null) return null;
  for (final scene in project.scenes) {
    if (scene.id == sceneId) return scene.name;
  }
  return null;
}

String _recordLabel(NarrativeEventRecord record) => record.when(
      draft: (draft) => draft.name,
      configured: (definition, _) => definition.name,
    );

List<NarrativeEventCondition> _recordConditions(NarrativeEventRecord record) =>
    record.when(
      draft: (draft) => draft.conditions,
      configured: (definition, _) => definition.conditions,
    );

({String? mapId, String? ownerId}) _sourceIdentity(
  NarrativeEventSourceRef? source,
) =>
    source?.when(
      entityInteract: (mapId, entityId) => (mapId: mapId, ownerId: entityId),
      triggerEnter: (mapId, triggerId) => (mapId: mapId, ownerId: triggerId),
      mapEnter: (mapId) => (mapId: mapId, ownerId: null),
      outcomeReceived: (_) => (mapId: null, ownerId: null),
    ) ??
    (mapId: null, ownerId: null);

bool _sourceConnected(
  NarrativeEventSourceRef? source,
  Map<String, MapData> mapsById,
) {
  if (source == null) return false;
  return source.when(
    entityInteract: (mapId, entityId) =>
        mapsById[mapId]?.entities.any((entity) => entity.id == entityId) ??
        false,
    triggerEnter: (mapId, triggerId) =>
        mapsById[mapId]?.triggers.any((trigger) => trigger.id == triggerId) ??
        false,
    mapEnter: mapsById.containsKey,
    outcomeReceived: (_) => true,
  );
}

({String? label, MapEntityKind? entityKind}) _sourceOwnerPresentation(
  NarrativeEventSourceRef? source,
  Map<String, MapData> mapsById,
) {
  if (source == null) return (label: null, entityKind: null);
  return source.when(
    entityInteract: (mapId, entityId) {
      MapEntity? entity;
      for (final candidate
          in mapsById[mapId]?.entities ?? const <MapEntity>[]) {
        if (candidate.id == entityId) {
          entity = candidate;
          break;
        }
      }
      return (
        label: entity?.inspectorHeadline,
        entityKind: entity?.kind,
      );
    },
    triggerEnter: (mapId, triggerId) {
      MapTrigger? trigger;
      for (final candidate
          in mapsById[mapId]?.triggers ?? const <MapTrigger>[]) {
        if (candidate.id == triggerId) {
          trigger = candidate;
          break;
        }
      }
      final name = trigger?.name.trim();
      return (
        label: name == null || name.isEmpty ? trigger?.id : name,
        entityKind: null,
      );
    },
    mapEnter: (mapId) => (
      label: mapsById[mapId]?.name,
      entityKind: null,
    ),
    outcomeReceived: (outcome) => (
      label: outcome.outcomeId,
      entityKind: null,
    ),
  );
}

int _compareDiagnostics(
  NarrativeProjectDiagnostic left,
  NarrativeProjectDiagnostic right,
) {
  final severity = right.severity.index.compareTo(left.severity.index);
  if (severity != 0) return severity;
  return left.stableKey.compareTo(right.stableKey);
}

String _upperFirst(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
~~~~~~

### `packages/map_core/test/project_dialogue_declared_outcomes_test.dart`

- Taille : `2232` octets
- SHA-256 : `33ae93d6fd8c0aa21a6cbea5334e6c39105e05edfc8dff455d54d71ab3609f8f`

~~~~~~dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Project dialogue declared outcomes', () {
    test('round-trips declared outcomes and defaults legacy JSON to empty', () {
      final legacy = ProjectManifest.fromJson(_projectJson());
      expect(legacy.dialogues.single.declaredOutcomes, isEmpty);

      final manifest = ProjectManifest.fromJson(
        _projectJson(
          declaredOutcomes: [
            {'id': 'accepted', 'label': 'Accepter'},
            {'id': 'refused', 'label': 'Refuser'},
          ],
        ),
      );

      expect(
        manifest.dialogues.single.declaredOutcomes
            .map((outcome) => (outcome.id, outcome.label)),
        [('accepted', 'Accepter'), ('refused', 'Refuser')],
      );
      expect(
        ProjectManifest.fromJson(manifest.toJson())
            .dialogues
            .single
            .declaredOutcomes,
        manifest.dialogues.single.declaredOutcomes,
      );
    });

    test('rejects blank or duplicate declared outcome ids and blank labels',
        () {
      for (final outcomes in <List<Map<String, Object?>>>[
        [
          {'id': '   ', 'label': 'Accepter'},
        ],
        [
          {'id': 'accepted', 'label': 'Accepter'},
          {'id': ' accepted ', 'label': 'Encore'},
        ],
        [
          {'id': 'accepted', 'label': '   '},
        ],
        [
          {'id': 'completed', 'label': 'Terminé'},
        ],
      ]) {
        final manifest = ProjectManifest.fromJson(
          _projectJson(declaredOutcomes: outcomes),
        );

        expect(
          () => ProjectValidator.validate(manifest),
          throwsA(isA<ValidationException>()),
          reason: '$outcomes',
        );
      }
    });
  });
}

Map<String, Object?> _projectJson({
  List<Map<String, Object?>>? declaredOutcomes,
}) {
  return {
    'name': 'Dialogue outcomes test',
    'version': 'v1',
    'maps': <Object?>[],
    'tilesets': <Object?>[],
    'dialogues': [
      {
        'id': 'dialogue_intro',
        'name': 'Introduction',
        'relativePath': 'dialogues/intro.yarn',
        if (declaredOutcomes != null) 'declaredOutcomes': declaredOutcomes,
      },
    ],
  };
}
~~~~~~

### `packages/map_core/test/project_new_game_config_test.dart`

- Taille : `5530` octets
- SHA-256 : `d74635b1931f805ef7581609e43fa94e10098e742be59db3a97943908eeb5f61`

~~~~~~dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Project new game config', () {
    test('legacy manifests default to a disabled config', () {
      final manifest = ProjectManifest.fromJson({
        'name': 'legacy',
        'maps': <Object?>[],
        'tilesets': <Object?>[],
      });

      expect(manifest.newGame.enabled, isFalse);
      expect(manifest.newGame.initialParty, isEmpty);
      expect(manifest.newGame.starterOptions, isEmpty);
      expect(manifest.toJson()['newGame'], isA<Map<String, dynamic>>());
    });

    test('round-trips spawn, inventory, facts, party and starter options', () {
      const config = ProjectNewGameConfig(
        enabled: true,
        startMapId: 'map_start',
        startSpawnId: 'spawn_home',
        playerName: 'Maël',
        startingMoney: 500,
        initialBag: [
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
        ],
        initialParty: [
          PlayerPokemon(
            speciesId: 'eevee',
            natureId: 'hardy',
            abilityId: 'run-away',
            level: 5,
            currentHp: 20,
          ),
        ],
        initialFacts: {'fact_intro_active': true},
        existingPartyFactId: 'fact_existing_party',
        starterSelectionSceneId: 'scene_starter_choice',
        starterOptions: [
          ProjectStarterOption(
            id: 'starter_bulbasaur',
            label: 'Bulbizarre',
            pokemon: PlayerPokemon(
              speciesId: 'bulbasaur',
              natureId: 'hardy',
              abilityId: 'overgrow',
              level: 5,
              currentHp: 20,
            ),
          ),
        ],
      );
      final manifest = _manifest(config);

      final decoded = ProjectManifest.fromJson(manifest.toJson());

      expect(decoded.newGame, config);
      expect(decoded.newGame.starterOptions.single.id, 'starter_bulbasaur');
    });

    test('validator rejects references and structurally invalid values', () {
      final invalidConfigs = <ProjectNewGameConfig>[
        const ProjectNewGameConfig(enabled: true),
        const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'missing_map',
        ),
        const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'map_start',
          startingMoney: -1,
        ),
        const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'map_start',
          initialBag: [
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 0),
          ],
        ),
        const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'map_start',
          existingPartyFactId: 'missing_fact',
        ),
        const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'map_start',
          starterSelectionSceneId: 'missing_scene',
        ),
      ];

      for (final config in invalidConfigs) {
        expect(
          () => ProjectValidator.validate(_manifest(config)),
          throwsA(isA<ValidationException>()),
          reason: config.toString(),
        );
      }
    });

    test('validator accepts both empty-party and existing-party starts', () {
      for (final initialParty in <List<PlayerPokemon>>[
        const [],
        const [
          PlayerPokemon(
            speciesId: 'eevee',
            natureId: 'hardy',
            abilityId: 'run-away',
            level: 5,
            currentHp: 20,
          ),
        ],
      ]) {
        final manifest = _manifest(
          ProjectNewGameConfig(
            enabled: true,
            startMapId: 'map_start',
            existingPartyFactId: 'fact_existing_party',
            initialParty: initialParty,
            starterSelectionSceneId: 'scene_starter_choice',
            starterOptions: const [
              ProjectStarterOption(
                id: 'starter_bulbasaur',
                label: 'Bulbizarre',
                pokemon: PlayerPokemon(
                  speciesId: 'bulbasaur',
                  natureId: 'hardy',
                  abilityId: 'overgrow',
                  level: 5,
                  currentHp: 20,
                ),
              ),
            ],
          ),
        );

        expect(() => ProjectValidator.validate(manifest), returnsNormally);
      }
    });
  });
}

ProjectManifest _manifest(ProjectNewGameConfig newGame) {
  return ProjectManifest(
    name: 'new game config test',
    maps: const [
      ProjectMapEntry(
        id: 'map_start',
        name: 'Start',
        relativePath: 'maps/map_start.json',
      ),
    ],
    tilesets: const [],
    facts: [
      NarrativeFactDefinition(
        id: 'fact_intro_active',
        label: 'Introduction active',
      ),
      NarrativeFactDefinition(
        id: 'fact_existing_party',
        label: 'Équipe existante',
      ),
    ],
    scenes: [
      SceneAsset(
        id: 'scene_starter_choice',
        name: 'Starter choice',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'edge_start_end',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
      ),
    ],
    newGame: newGame,
  );
}
~~~~~~

### `packages/map_core/test/narrative_project_validator_test.dart`

- Taille : `45483` octets
- SHA-256 : `6fda5ce943c2a6e6f9d77ba4a820cb1a91a259bb2b9843902ff79e7105499e60`

~~~~~~dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _eventA = 'evt_019abcde-4000-7000-8000-000000000071';
const _eventB = 'evt_019abcde-4000-7000-8000-000000000072';
const _eventC = 'evt_019abcde-4000-7000-8000-000000000073';

void main() {
  group('Narrative project validator', () {
    test('aggregates a playable project and exposes its map Event view', () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project,
        maps: [fixture.map],
      );

      expect(report.isPlayable, isTrue);
      expect(report.errorCount, 0);
      expect(report.mapEventViews, hasLength(1));
      final mapView = report.mapEventViews.single;
      expect(mapView.mapId, 'map_port');
      expect(mapView.events, hasLength(1));
      expect(mapView.events.single.eventId, _eventA);
      expect(mapView.events.single.sourceConnected, isTrue);
      expect(mapView.events.single.sourceEntityKind, MapEntityKind.npc);
      expect(mapView.events.single.sourceOwnerLabel, 'Guide');
      expect(mapView.events.single.sceneConnected, isTrue);
      expect(mapView.events.single.sceneLabel, 'Introduction');
      expect(mapView.events.single.conditionCount, 0);
    });

    test('reports an impossible Step and a required Fact never produced', () {
      final fixture = _fixture(
        completeStep: false,
        requireFact: true,
      );

      final report = validateNarrativeProject(
        fixture.project,
        maps: [fixture.map],
      );

      expect(report.isPlayable, isFalse);
      expect(
        report.byCode('storylineStepNeverCompleted').single.stepId,
        'step_intro',
      );
      final factDiagnostic = report.byCode('requiredFactNeverProduced').single;
      expect(factDiagnostic.factId, 'fact_gate');
      expect(
        factDiagnostic.destination,
        NarrativeProjectDiagnosticDestination.fact,
      );
      expect(
        report.byDomain(NarrativeProjectDiagnosticDomain.storyline),
        isNotEmpty,
      );
    });

    test('ignores Fact producers that are unreachable inside a Scene', () {
      final fixture = _fixture(requireFact: true);
      final scene = fixture.project.scenes.single;
      final unreachableProducer = SceneNode(
        id: 'unreachable_fact',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.setFact(factId: 'fact_gate', value: true),
        ),
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [
            SceneAsset(
              id: scene.id,
              name: scene.name,
              description: scene.description,
              storylineId: scene.storylineId,
              chapterId: scene.chapterId,
              tags: scene.tags,
              graph: SceneGraph(
                startNodeId: scene.graph.startNodeId,
                nodes: [...scene.graph.nodes, unreachableProducer],
                edges: scene.graph.edges,
              ),
              declaredOutcomes: scene.declaredOutcomes,
              metadata: scene.metadata,
            ),
          ],
        ),
        maps: [fixture.map],
      );

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
    });

    test('does not let an Event unlock itself with its own Scene Fact', () {
      final fixture = _fixture(requireFact: true);
      final scene = fixture.project.scenes.single;
      final selfProducer = SceneNode(
        id: 'self_fact',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.setFact(factId: 'fact_gate', value: true),
        ),
      );
      final selfGatedScene = SceneAsset(
        id: scene.id,
        name: scene.name,
        graph: SceneGraph(
          startNodeId: scene.graph.startNodeId,
          nodes: [...scene.graph.nodes, selfProducer],
          edges: [
            SceneEdge(
              id: 'start_self_fact',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'self_fact',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'self_fact_complete',
              fromNodeId: 'self_fact',
              fromPortId: 'completed',
              toNodeId: 'complete_step',
              kind: SceneEdgeKind.actionCompleted,
            ),
            ...scene.graph.edges.where(
              (edge) => edge.id != 'start_action',
            ),
          ],
        ),
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(scenes: [selfGatedScene]),
        maps: [fixture.map],
      );

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
      expect(report.byCode('storylineStepInaccessible'), hasLength(1));
    });

    test(
        'does not apply Storyline effects from an outcome the reachable Scene cannot emit',
        () {
      final fixture = _fixture(
        completeStep: false,
        requireFact: true,
      );
      final scene = _outcomeScene(
        id: 'scene_intro',
        emittedOutcomeId: 'available_outcome',
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [scene],
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [
              _record(id: _eventA, entityId: 'npc_guide'),
              _record(
                id: _eventB,
                entityId: 'npc_guide',
                conditions: [NarrativeEventCondition.fact('fact_gate', true)],
              ),
            ],
            legacyClaims: const [],
          ),
          storylines: [
            _storylineWithOutcomeEffects(
              base: fixture.project.storylines.single,
              sceneId: scene.id,
              outcomeId: 'impossible_outcome',
            ),
          ],
        ),
        maps: [fixture.map],
      );

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
      expect(report.byCode('storylineStepNeverCompleted'), hasLength(1));
    });

    test('does not apply Storyline effects from an unreachable Scene producer',
        () {
      final fixture = _fixture(
        completeStep: false,
        requireFact: true,
      );
      final hiddenScene = _outcomeScene(
        id: 'scene_hidden',
        emittedOutcomeId: 'completed',
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [...fixture.project.scenes, hiddenScene],
          storylines: [
            _storylineWithOutcomeEffects(
              base: fixture.project.storylines.single,
              sceneId: hiddenScene.id,
              outcomeId: 'completed',
            ),
          ],
        ),
        maps: [fixture.map],
      );

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
      expect(report.byCode('storylineStepNeverCompleted'), hasLength(1));
    });

    test('applies Storyline effects from an exact reachable Scene outcome', () {
      final fixture = _fixture(
        completeStep: false,
        requireFact: true,
      );
      final scene = _outcomeScene(
        id: 'scene_intro',
        emittedOutcomeId: 'completed',
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [scene],
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [
              _record(id: _eventA, entityId: 'npc_guide'),
              _record(
                id: _eventB,
                entityId: 'npc_guide',
                conditions: [NarrativeEventCondition.fact('fact_gate', true)],
              ),
            ],
            legacyClaims: const [],
          ),
          storylines: [
            _storylineWithOutcomeEffects(
              base: fixture.project.storylines.single,
              sceneId: scene.id,
              outcomeId: 'completed',
            ),
          ],
        ),
        maps: [fixture.map],
      );

      expect(report.byCode('requiredFactNeverProduced'), isEmpty);
      expect(report.byCode('storylineStepNeverCompleted'), isEmpty);
    });

    test('legacy reachability stops at the first applicable disabled page', () {
      final fixture = _fixture(
        completeStep: false,
        requireFact: true,
      );
      final hiddenProducer = _factProducingScene('scene_legacy_hidden');
      final map = fixture.map.copyWith(
        events: [
          MapEventDefinition(
            id: 'legacy_gate',
            pages: const [
              MapEventPage(pageNumber: 0, isDisabled: true),
              MapEventPage(
                pageNumber: 1,
                sceneTarget: MapEventSceneTarget(
                  sceneId: 'scene_legacy_hidden',
                ),
              ),
            ],
            position: const EventPosition(layerId: 'events', x: 5, y: 5),
          ),
        ],
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [...fixture.project.scenes, hiddenProducer],
        ),
        maps: [map],
      );

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
    });

    test(
        'legacy reachability keeps the fallback when an earlier disabled condition can become false',
        () {
      final fixture = _fixture(completeStep: false);
      final map = fixture.map.copyWith(
        events: [
          MapEventDefinition(
            id: 'legacy_conditional_gate',
            pages: [
              MapEventPage(
                pageNumber: 0,
                condition: ScriptConditionFactory.flagIsSet('fact_gate'),
                isDisabled: true,
              ),
              const MapEventPage(
                pageNumber: 1,
                sceneTarget: MapEventSceneTarget(
                  sceneId: 'scene_legacy_fallback',
                ),
              ),
            ],
            position: const EventPosition(layerId: 'events', x: 5, y: 5),
          ),
        ],
      );
      final project = fixture.project.copyWith(
        facts: [
          NarrativeFactDefinition(
            id: 'fact_gate',
            label: 'Gate initially open',
            defaultValue: true,
          ),
          NarrativeFactDefinition(
            id: 'fact_unlock',
            label: 'Fallback reached',
          ),
        ],
        scenes: [
          _factScene(
            id: 'scene_intro',
            factId: 'fact_gate',
            value: false,
          ),
          _factScene(
            id: 'scene_legacy_fallback',
            factId: 'fact_unlock',
            value: true,
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            _record(id: _eventA, entityId: 'npc_guide'),
            _record(
              id: _eventB,
              entityId: 'npc_guide',
              conditions: [
                NarrativeEventCondition.fact('fact_unlock', true),
              ],
            ),
          ],
          legacyClaims: const [],
        ),
      );

      final report = validateNarrativeProject(project, maps: [map]);

      expect(report.byCode('requiredFactNeverProduced'), isEmpty);
    });

    test('legacy reachability does not invent a jointly impossible fallback',
        () {
      final fixture = _fixture(completeStep: false);
      final map = fixture.map.copyWith(
        events: [
          MapEventDefinition(
            id: 'legacy_exhaustive_gate',
            pages: [
              MapEventPage(
                pageNumber: 0,
                condition: ScriptConditionFactory.flagIsSet('fact_gate'),
              ),
              MapEventPage(
                pageNumber: 1,
                condition: ScriptConditionFactory.flagIsUnset('fact_gate'),
              ),
              const MapEventPage(
                pageNumber: 2,
                sceneTarget: MapEventSceneTarget(
                  sceneId: 'scene_impossible_fallback',
                ),
              ),
            ],
            position: const EventPosition(layerId: 'events', x: 5, y: 5),
          ),
        ],
      );
      final project = fixture.project.copyWith(
        facts: [
          NarrativeFactDefinition(
            id: 'fact_gate',
            label: 'Gate',
            defaultValue: true,
          ),
          NarrativeFactDefinition(
            id: 'fact_unlock',
            label: 'Impossible fallback',
          ),
        ],
        scenes: [
          _factScene(
            id: 'scene_intro',
            factId: 'fact_gate',
            value: false,
          ),
          _factScene(
            id: 'scene_impossible_fallback',
            factId: 'fact_unlock',
            value: true,
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            _record(id: _eventA, entityId: 'npc_guide'),
            _record(
              id: _eventB,
              entityId: 'npc_guide',
              conditions: [
                NarrativeEventCondition.fact('fact_unlock', true),
              ],
            ),
          ],
          legacyClaims: const [],
        ),
      );

      final report = validateNarrativeProject(project, maps: [map]);

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
    });

    test('legacy reachability fails closed within a bounded state search', () {
      final fixture = _fixture(completeStep: false);
      final branchingFactIds = [
        for (var index = 0; index < 14; index++) 'fact_branch_$index',
      ];
      final map = fixture.map.copyWith(
        events: [
          MapEventDefinition(
            id: 'legacy_large_condition_gate',
            pages: [
              MapEventPage(
                pageNumber: 0,
                condition: ScriptConditionFactory.anyOf([
                  for (final factId in branchingFactIds)
                    ScriptConditionFactory.flagIsUnset(factId),
                ]),
                isDisabled: true,
              ),
              const MapEventPage(
                pageNumber: 1,
                sceneTarget: MapEventSceneTarget(
                  sceneId: 'scene_large_condition_fallback',
                ),
              ),
            ],
            position: const EventPosition(layerId: 'events', x: 5, y: 5),
          ),
        ],
      );
      final project = fixture.project.copyWith(
        facts: [
          for (final factId in branchingFactIds)
            NarrativeFactDefinition(id: factId, label: factId),
          NarrativeFactDefinition(
            id: 'fact_unlock',
            label: 'Large fallback reached',
          ),
        ],
        scenes: [
          ...fixture.project.scenes,
          _manyFactScene('scene_many_fact_values', branchingFactIds),
          _factScene(
            id: 'scene_large_condition_fallback',
            factId: 'fact_unlock',
            value: true,
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            ...fixture.project.eventRegistry!.records,
            _record(
              id: _eventC,
              entityId: 'npc_guide',
              sceneId: 'scene_many_fact_values',
            ),
            _record(
              id: _eventB,
              entityId: 'npc_guide',
              conditions: [
                NarrativeEventCondition.fact('fact_unlock', true),
              ],
            ),
          ],
          legacyClaims: const [],
        ),
      );

      final report = validateNarrativeProject(project, maps: [map]);

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
    });

    test('does not traverse a statically impossible Scene condition port', () {
      final fixture = _fixture(completeStep: false);
      final project = fixture.project.copyWith(
        facts: [
          NarrativeFactDefinition(id: 'fact_never', label: 'Never true'),
          NarrativeFactDefinition(id: 'fact_unlock', label: 'Unlock'),
        ],
        scenes: [
          _conditionalFactScene(
            conditionFactId: 'fact_never',
            trueFactId: 'fact_unlock',
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            _record(id: _eventA, entityId: 'npc_guide'),
            _record(
              id: _eventB,
              entityId: 'npc_guide',
              conditions: [
                NarrativeEventCondition.fact('fact_unlock', true),
              ],
            ),
          ],
          legacyClaims: const [],
        ),
      );

      final report = validateNarrativeProject(project, maps: [fixture.map]);

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
    });

    test('does not emit an outcome behind an impossible Scene condition port',
        () {
      final fixture = _fixture(completeStep: false);
      final project = fixture.project.copyWith(
        facts: [
          NarrativeFactDefinition(id: 'fact_never', label: 'Never true'),
          NarrativeFactDefinition(id: 'fact_unlock', label: 'Unlock'),
        ],
        scenes: [
          _conditionalOutcomeScene(conditionFactId: 'fact_never'),
          _factScene(
            id: 'scene_outcome_consumer',
            factId: 'fact_unlock',
            value: true,
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            _record(id: _eventA, entityId: 'npc_guide'),
            NarrativeEventRecord.configuredStructurallyUnchecked(
              NarrativeEventDefinition(
                id: _eventB,
                name: 'Impossible outcome consumer',
                source: NarrativeEventSourceRef.outcomeReceived(
                  NarrativeOutcomeRef(
                    producerKind: NarrativeOutcomeProducerKind.scene,
                    producerId: 'scene_intro',
                    outcomeId: 'success',
                  ),
                ),
                conditions: const [],
                sceneId: 'scene_outcome_consumer',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 1,
              ),
              enabled: true,
            ),
            _record(
              id: _eventC,
              entityId: 'npc_guide',
              conditions: [
                NarrativeEventCondition.fact('fact_unlock', true),
              ],
            ),
          ],
          legacyClaims: const [],
        ),
      );

      final report = validateNarrativeProject(project, maps: [fixture.map]);

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
    });

    test('reports a missing configured New Game start spawn on its map', () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          newGame: const ProjectNewGameConfig(
            enabled: true,
            startMapId: 'map_port',
            startSpawnId: 'spawn_missing',
          ),
        ),
        maps: [fixture.map],
      );

      final diagnostic =
          report.byCode('runtimeNewGameStartSpawnMissing').single;
      expect(diagnostic.severity, NarrativeProjectDiagnosticSeverity.error);
      expect(diagnostic.destination, NarrativeProjectDiagnosticDestination.map);
      expect(diagnostic.mapId, 'map_port');
      expect(diagnostic.path, contains('spawn_missing'));
    });

    test('reports a configured New Game start entity that is not playerStart',
        () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          newGame: const ProjectNewGameConfig(
            enabled: true,
            startMapId: 'map_port',
            startSpawnId: 'npc_guide',
          ),
        ),
        maps: [fixture.map],
      );

      final diagnostic =
          report.byCode('runtimeNewGameStartSpawnNotPlayerStart').single;
      expect(diagnostic.destination, NarrativeProjectDiagnosticDestination.map);
      expect(diagnostic.mapId, 'map_port');
    });

    test('reports a configured New Game start spawn outside map bounds', () {
      final fixture = _fixture();
      final map = fixture.map.copyWith(
        entities: [
          for (final entity in fixture.map.entities)
            if (entity.id == 'spawn_player')
              entity.copyWith(pos: const GridPos(x: 16, y: 1))
            else
              entity,
        ],
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          newGame: const ProjectNewGameConfig(
            enabled: true,
            startMapId: 'map_port',
            startSpawnId: 'spawn_player',
          ),
        ),
        maps: [map],
      );

      final diagnostic =
          report.byCode('runtimeNewGameStartSpawnOutOfBounds').single;
      expect(diagnostic.destination, NarrativeProjectDiagnosticDestination.map);
      expect(diagnostic.mapId, 'map_port');
    });

    test('accepts an in-bounds configured playerStart spawn', () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          newGame: const ProjectNewGameConfig(
            enabled: true,
            startMapId: 'map_port',
            startSpawnId: 'spawn_player',
          ),
        ),
        maps: [fixture.map],
      );

      expect(report.byCode('runtimeNewGameStartSpawnMissing'), isEmpty);
      expect(report.byCode('runtimeNewGameStartSpawnNotPlayerStart'), isEmpty);
      expect(report.byCode('runtimeNewGameStartSpawnOutOfBounds'), isEmpty);
    });

    test('reports an unknown trainer referenced only by a Scene battle', () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [
            _battleScene(
              battleKind: 'trainer',
              trainerId: 'trainer_missing',
            ),
          ],
        ),
        maps: [fixture.map],
      );

      final diagnostic = report.byCode('battleTrainerRefUnknown').single;
      expect(
          diagnostic.destination, NarrativeProjectDiagnosticDestination.scene);
      expect(diagnostic.sceneId, 'scene_intro');
    });

    test('reports an empty Scene-only static boss team', () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [
            _battleScene(
              battleKind: 'static',
              trainerId: 'trainer_boss',
            ),
          ],
          trainers: const [
            ProjectTrainerEntry(
              id: 'trainer_boss',
              name: 'Gardien',
              trainerClass: 'Static boss',
            ),
          ],
        ),
        maps: [fixture.map],
      );

      final diagnostic = report.byCode('sceneBattleTrainerHasEmptyTeam').single;
      expect(diagnostic.severity, NarrativeProjectDiagnosticSeverity.error);
      expect(
          diagnostic.destination, NarrativeProjectDiagnosticDestination.scene);
      expect(diagnostic.sceneId, 'scene_intro');
    });

    test('reports missing authoritative species and moves in a Scene opponent',
        () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [
            _battleScene(
              battleKind: 'trainer',
              trainerId: 'trainer_invalid_team',
            ),
          ],
          trainers: const [
            ProjectTrainerEntry(
              id: 'trainer_invalid_team',
              name: 'Dresseur incomplet',
              trainerClass: 'Trainer',
              team: [
                ProjectTrainerPokemonEntry(speciesId: '', level: 5),
              ],
            ),
          ],
        ),
        maps: [fixture.map],
      );

      expect(
        report.byCode('sceneBattleTrainerPokemonMissingSpecies'),
        hasLength(1),
      );
      expect(
        report.byCode('sceneBattleTrainerPokemonMissingMoves'),
        hasLength(1),
      );
    });

    test('reports unknown catalog IDs in a Scene-only opponent', () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [
            _battleScene(
              battleKind: 'trainer',
              trainerId: 'trainer_unknown_catalog_ids',
            ),
          ],
          trainers: const [
            ProjectTrainerEntry(
              id: 'trainer_unknown_catalog_ids',
              name: 'Dresseur invalide',
              trainerClass: 'Trainer',
              team: [
                ProjectTrainerPokemonEntry(
                  speciesId: 'missing_species',
                  level: 5,
                  moves: ['missing_move'],
                ),
              ],
            ),
          ],
        ),
        maps: [fixture.map],
        knownSpeciesIds: const {'bulbasaur'},
        knownMoveIds: const {'tackle'},
      );

      expect(
        report.byCode('sceneBattleTrainerPokemonSpeciesUnknown'),
        hasLength(1),
      );
      expect(
        report.byCode('sceneBattleTrainerPokemonMoveUnknown'),
        hasLength(1),
      );
    });

    test('reports unknown catalog IDs in every New Game starter option', () {
      final fixture = _fixture();
      final project = fixture.project.copyWith(
        newGame: ProjectNewGameConfig(
          enabled: true,
          startMapId: fixture.map.id,
          starterOptions: const [
            ProjectStarterOption(
              id: 'starter_missing',
              label: 'Starter invalide',
              pokemon: PlayerPokemon(
                speciesId: 'missing_species',
                natureId: 'hardy',
                abilityId: 'missing_ability',
                knownMoveIds: ['missing_move'],
                level: 5,
                currentHp: 20,
              ),
            ),
          ],
        ),
      );

      final report = validateNarrativeProject(
        project,
        maps: [fixture.map],
        knownSpeciesIds: const <String>{},
        knownMoveIds: const <String>{},
      );

      expect(report.byCode('runtimeMissingPokemonSpecies'), hasLength(1));
      expect(report.byCode('runtimeMissingPokemonMove'), hasLength(1));
    });

    test('fails closed when required Pokemon catalogs were not loaded', () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project,
        maps: [fixture.map],
        requirePokemonCatalogs: true,
      );

      expect(
        report.byCode('runtimePokemonSpeciesCatalogUnavailable'),
        hasLength(1),
      );
      expect(
        report.byCode('runtimePokemonMoveCatalogUnavailable'),
        hasLength(1),
      );
    });

    test('reports a dependency cycle as an impossible narrative branch', () {
      final fixture = _fixture(eventDependencyCycle: true);

      final report = validateNarrativeProject(
        fixture.project,
        maps: [fixture.map],
      );

      expect(report.isPlayable, isFalse);
      expect(
        report.diagnostics.any(
          (diagnostic) =>
              diagnostic.domain == NarrativeProjectDiagnosticDomain.event &&
              diagnostic.code.toLowerCase().contains('cycle'),
        ),
        isTrue,
      );
    });

    test('keeps an orphaned map source visible and navigable', () {
      final fixture = _fixture(orphanSource: true);

      final report = validateNarrativeProject(
        fixture.project,
        maps: [fixture.map],
      );

      final event = report.mapEventViews.single.events.single;
      expect(event.sourceConnected, isFalse);
      expect(event.sourceOwnerId, 'npc_missing');
      expect(event.diagnosticCount, greaterThan(0));
      final diagnostic = report.diagnostics.firstWhere(
        (item) => item.eventId == _eventA && item.mapId == 'map_port',
      );
      expect(diagnostic.destination, NarrativeProjectDiagnosticDestination.map);
    });

    test('reports Storylines without a beginning or an ending', () {
      final fixture = _fixture();
      final emptyStoryline = StorylineAsset(
        id: 'story_empty',
        type: StorylineType.sideQuest,
        status: StorylineStatus.active,
        title: 'Quête vide',
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          storylines: [...fixture.project.storylines, emptyStoryline],
        ),
        maps: [fixture.map],
      );

      expect(report.byCode('storylineMissingBeginning'), hasLength(1));
      expect(report.byCode('storylineMissingEnding'), hasLength(1));
      expect(
        report.byCode('storylineImpossible').single.storylineId,
        'story_empty',
      );
    });

    test('keeps a superseded Global Story authoring Scenario as a warning only',
        () {
      final fixture = _fixture();
      const legacyAuthoringGraph = ScenarioAsset(
        id: 'global_story',
        name: 'Global Story',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
        nodes: [
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
        ],
        edges: [
          ScenarioEdge(
            id: 'start_end',
            fromNodeId: 'start',
            toNodeId: 'end',
          ),
        ],
        metadata: {
          'authoring.globalStoryStudioSchema': 'global_story_studio_v1.1',
        },
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(scenarios: const [legacyAuthoringGraph]),
        maps: [fixture.map],
      );

      final diagnostic = report.byCode('scenarioGraphHasNoSource').single;
      expect(
        diagnostic.severity,
        NarrativeProjectDiagnosticSeverity.warning,
      );
      expect(report.isPlayable, isTrue);
    });
  });
}

({ProjectManifest project, MapData map}) _fixture({
  bool completeStep = true,
  bool requireFact = false,
  bool eventDependencyCycle = false,
  bool orphanSource = false,
}) {
  final map = MapData(
    id: 'map_port',
    name: 'Port',
    size: const GridSize(width: 16, height: 16),
    layers: const [MapLayer.object(id: 'events', name: 'Events')],
    mapMetadata: const MapMetadata(defaultSpawnId: 'spawn_player'),
    entities: const [
      MapEntity(
        id: 'spawn_player',
        name: 'Départ',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 1),
        spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
      ),
      MapEntity(
        id: 'npc_guide',
        name: 'Guide',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 3, y: 4),
      ),
    ],
  );
  final scene = _scene(completeStep: completeStep);
  final records = <NarrativeEventRecord>[
    _record(
      id: _eventA,
      entityId: orphanSource ? 'npc_missing' : 'npc_guide',
      conditions: [
        if (requireFact) NarrativeEventCondition.fact('fact_gate', true),
        if (eventDependencyCycle)
          NarrativeEventCondition.narrativeEventConsumed(_eventB, true),
      ],
    ),
    if (eventDependencyCycle)
      _record(
        id: _eventB,
        entityId: 'npc_guide',
        conditions: [
          NarrativeEventCondition.narrativeEventConsumed(_eventA, true),
        ],
      ),
  ];

  return (
    map: map,
    project: ProjectManifest(
      name: 'Validator fixture',
      maps: const [
        ProjectMapEntry(
          id: 'map_port',
          name: 'Port',
          relativePath: 'maps/map_port.json',
        ),
      ],
      tilesets: const [],
      scenes: [scene],
      facts: [
        NarrativeFactDefinition(id: 'fact_gate', label: 'Passage ouvert'),
      ],
      storylines: [
        StorylineAsset(
          id: 'story_main',
          type: StorylineType.main,
          status: StorylineStatus.active,
          title: 'Histoire principale',
          chapters: [
            StorylineChapter(
              id: 'chapter_intro',
              title: 'Introduction',
              order: 0,
              steps: [
                StorylineStep(
                  id: 'step_intro',
                  title: 'Rencontrer le guide',
                  order: 0,
                  sceneLinkIds: const ['scene_intro'],
                ),
              ],
            ),
          ],
        ),
      ],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: records,
        legacyClaims: const [],
      ),
    ),
  );
}

NarrativeEventRecord _record({
  required String id,
  required String entityId,
  String sceneId = 'scene_intro',
  List<NarrativeEventCondition> conditions = const [],
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: 'Event $id',
      source: NarrativeEventSourceRef.entityInteract('map_port', entityId),
      conditions: conditions,
      sceneId: sceneId,
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: id == _eventA ? 0 : 1,
    ),
    enabled: true,
  );
}

SceneAsset _scene({required bool completeStep}) {
  final nodes = <SceneNode>[
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    if (completeStep)
      SceneNode(
        id: 'complete_step',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.completeStoryStep(stepId: 'step_intro'),
        ),
      ),
    SceneNode(id: 'end', kind: SceneNodeKind.end),
  ];
  return SceneAsset(
    id: 'scene_intro',
    name: 'Introduction',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: nodes,
      edges: completeStep
          ? [
              SceneEdge(
                id: 'start_action',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'complete_step',
                kind: SceneEdgeKind.defaultFlow,
              ),
              SceneEdge(
                id: 'action_end',
                fromNodeId: 'complete_step',
                fromPortId: 'completed',
                toNodeId: 'end',
                kind: SceneEdgeKind.defaultFlow,
              ),
            ]
          : [
              SceneEdge(
                id: 'start_end',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'end',
                kind: SceneEdgeKind.defaultFlow,
              ),
            ],
    ),
  );
}

SceneAsset _outcomeScene({
  required String id,
  required String emittedOutcomeId,
}) {
  return SceneAsset(
    id: id,
    name: id,
    declaredOutcomes: [
      SceneOutcome(id: emittedOutcomeId, label: emittedOutcomeId),
    ],
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: emittedOutcomeId),
        ),
      ],
      edges: [
        SceneEdge(
          id: 'start_end',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}

SceneAsset _factProducingScene(String id) {
  return SceneAsset(
    id: id,
    name: id,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: 'fact_gate', value: true),
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start_fact',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'set_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'fact_end',
          fromNodeId: 'set_fact',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

SceneAsset _factScene({
  required String id,
  required String factId,
  required bool value,
}) {
  return SceneAsset(
    id: id,
    name: id,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: factId, value: value),
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start_fact',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'set_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'fact_end',
          fromNodeId: 'set_fact',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

SceneAsset _manyFactScene(String id, List<String> factIds) {
  final actionIds = [
    for (var index = 0; index < factIds.length; index++) 'set_fact_$index',
  ];
  return SceneAsset(
    id: id,
    name: id,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        for (var index = 0; index < factIds.length; index++)
          SceneNode(
            id: actionIds[index],
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.setFact(
                factId: factIds[index],
                value: true,
              ),
            ),
          ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start_to_first',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: actionIds.first,
          kind: SceneEdgeKind.defaultFlow,
        ),
        for (var index = 0; index < actionIds.length - 1; index++)
          SceneEdge(
            id: 'action_${index}_to_${index + 1}',
            fromNodeId: actionIds[index],
            fromPortId: 'completed',
            toNodeId: actionIds[index + 1],
            kind: SceneEdgeKind.defaultFlow,
          ),
        SceneEdge(
          id: 'last_to_end',
          fromNodeId: actionIds.last,
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}

SceneAsset _conditionalFactScene({
  required String conditionFactId,
  required String trueFactId,
}) {
  return SceneAsset(
    id: 'scene_intro',
    name: 'Conditional fact',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'condition',
          kind: SceneNodeKind.condition,
          payload: SceneConditionPayload(
            conditionSource: SceneConditionSource(
              sourceKind: SceneConditionSourceKind.fact,
              sourceId: conditionFactId,
              operator: SceneConditionOperator.isTrue,
            ),
          ),
        ),
        SceneNode(
          id: 'true_action',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: trueFactId, value: true),
          ),
        ),
        SceneNode(id: 'true_end', kind: SceneNodeKind.end),
        SceneNode(id: 'false_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start_condition',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'condition',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'condition_true',
          fromNodeId: 'condition',
          fromPortId: 'true',
          toNodeId: 'true_action',
          kind: SceneEdgeKind.conditionTrue,
        ),
        SceneEdge(
          id: 'condition_false',
          fromNodeId: 'condition',
          fromPortId: 'false',
          toNodeId: 'false_end',
          kind: SceneEdgeKind.conditionFalse,
        ),
        SceneEdge(
          id: 'true_action_end',
          fromNodeId: 'true_action',
          fromPortId: 'completed',
          toNodeId: 'true_end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

SceneAsset _conditionalOutcomeScene({required String conditionFactId}) {
  return SceneAsset(
    id: 'scene_intro',
    name: 'Conditional outcome',
    declaredOutcomes: [SceneOutcome(id: 'success', label: 'Success')],
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'condition',
          kind: SceneNodeKind.condition,
          payload: SceneConditionPayload(
            conditionSource: SceneConditionSource(
              sourceKind: SceneConditionSourceKind.fact,
              sourceId: conditionFactId,
              operator: SceneConditionOperator.isTrue,
            ),
          ),
        ),
        SceneNode(
          id: 'success_end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: 'success'),
        ),
        SceneNode(id: 'false_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start_condition',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'condition',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'condition_true',
          fromNodeId: 'condition',
          fromPortId: 'true',
          toNodeId: 'success_end',
          kind: SceneEdgeKind.conditionTrue,
        ),
        SceneEdge(
          id: 'condition_false',
          fromNodeId: 'condition',
          fromPortId: 'false',
          toNodeId: 'false_end',
          kind: SceneEdgeKind.conditionFalse,
        ),
      ],
    ),
  );
}

StorylineAsset _storylineWithOutcomeEffects({
  required StorylineAsset base,
  required String sceneId,
  required String outcomeId,
}) {
  return StorylineAsset(
    id: base.id,
    type: base.type,
    status: base.status,
    title: base.title,
    chapters: base.chapters,
    sceneLinks: [
      StorylineSceneLink(
        id: 'link_$sceneId',
        chapterId: 'chapter_intro',
        stepId: 'step_intro',
        label: sceneId,
        state: StorylineSceneLinkState.linkedScenario,
        role: StorylineSceneLinkRole.primary,
        sceneRef: StorylineSceneRef(
          kind: StorylineSceneRefKind.scenario,
          targetId: sceneId,
        ),
        order: 0,
        expectedOutcomeIds: [outcomeId],
        outcomeLinks: [
          StorylineSceneOutcomeLink(
            id: 'effect_$outcomeId',
            outcomeId: outcomeId,
            effects: [
              StorylineEffect(
                type: StorylineEffectType.completeStep,
                targetId: 'step_intro',
              ),
              StorylineEffect(
                type: StorylineEffectType.emitFact,
                targetId: 'fact_gate',
                value: 'true',
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

SceneAsset _battleScene({
  required String battleKind,
  required String trainerId,
}) {
  return SceneAsset(
    id: 'scene_intro',
    name: 'Combat',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: battleKind,
            trainerId: trainerId,
            declaredOutcomes: const ['victory', 'defeat'],
          ),
        ),
        SceneNode(id: 'victory_end', kind: SceneNodeKind.end),
        SceneNode(id: 'defeat_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start_battle',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'battle',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'battle_victory',
          fromNodeId: 'battle',
          fromPortId: 'victory',
          toNodeId: 'victory_end',
          kind: SceneEdgeKind.battleVictory,
        ),
        SceneEdge(
          id: 'battle_defeat',
          fromNodeId: 'battle',
          fromPortId: 'defeat',
          toNodeId: 'defeat_end',
          kind: SceneEdgeKind.battleDefeat,
        ),
      ],
    ),
  );
}
~~~~~~

### `packages/map_gameplay/test/project_new_game_state_builder_test.dart`

- Taille : `5432` octets
- SHA-256 : `846c63af1dbd5d6018bc52eb754e7a7b7a1d9525c3cdb557a02ef01ca90e8931`

~~~~~~dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('createNewGameStateFromProject', () {
    test('builds the authored empty-party start and preserves it through save',
        () {
      final state = createNewGameStateFromProject(
        project: _project(initialParty: const <PlayerPokemon>[]),
        startMap: _startMap(),
        saveId: 'selbrume_empty_party',
      );

      expect(state.saveId, 'selbrume_empty_party');
      expect(state.currentMapId, 'map_start');
      expect(state.playerPosition, const GridPos(x: 7, y: 8));
      expect(state.playerFacing, EntityFacing.east);
      expect(state.trainerProfile.name, 'Joueur');
      expect(state.trainerProfile.money, 350);
      expect(
        state.bag.entries,
        const <BagEntry>[
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
        ],
      );
      expect(state.party.members, isEmpty);
      expect(
        state.narrativeFactRuntimeState.overridesByFactId,
        <String, bool>{
          'fact_intro_active': true,
          'fact_existing_party': false,
        },
      );

      final reloaded = gameStateFromSaveData(saveDataFromGameState(state));
      expect(reloaded.currentMapId, state.currentMapId);
      expect(reloaded.playerPosition, state.playerPosition);
      expect(reloaded.playerFacing, state.playerFacing);
      expect(reloaded.party.members, isEmpty);
      expect(reloaded.bag, state.bag);
      expect(reloaded.trainerProfile, state.trainerProfile);
      expect(
        reloaded.narrativeFactRuntimeState,
        state.narrativeFactRuntimeState,
      );
    });

    test('builds the authored existing-party alternative and marks the fact',
        () {
      const eevee = PlayerPokemon(
        speciesId: 'eevee',
        natureId: 'hardy',
        abilityId: 'run-away',
        level: 5,
        currentHp: 20,
      );

      final state = createNewGameStateFromProject(
        project: _project(initialParty: const <PlayerPokemon>[eevee]),
        startMap: _startMap(),
      );

      expect(state.party.members, const <PlayerPokemon>[eevee]);
      expect(
        state
            .narrativeFactRuntimeState.overridesByFactId['fact_existing_party'],
        isTrue,
      );
      expect(state.progression.seenSpeciesIds, contains('eevee'));
      expect(state.progression.caughtSpeciesIds, contains('eevee'));
    });

    test('rejects a map or configured spawn outside the authored contract', () {
      expect(
        () => createNewGameStateFromProject(
          project: _project(initialParty: const <PlayerPokemon>[]),
          startMap: _startMap(mapId: 'wrong_map'),
        ),
        throwsArgumentError,
      );
      expect(
        () => createNewGameStateFromProject(
          project: _project(
            initialParty: const <PlayerPokemon>[],
            startSpawnId: 'missing_spawn',
          ),
          startMap: _startMap(),
        ),
        throwsA(isA<GameplaySpawnResolutionException>()),
      );
    });

    test('rejects a disabled project new-game contract', () {
      expect(
        () => createNewGameStateFromProject(
          project: _project(
            initialParty: const <PlayerPokemon>[],
            enabled: false,
          ),
          startMap: _startMap(),
        ),
        throwsStateError,
      );
    });
  });
}

ProjectManifest _project({
  required List<PlayerPokemon> initialParty,
  String startSpawnId = 'spawn_authored',
  bool enabled = true,
}) {
  return ProjectManifest(
    name: 'Project new game fixture',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map_start',
        name: 'Start',
        relativePath: 'maps/map_start.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: 'fact_intro_active',
        label: 'Introduction active',
      ),
      NarrativeFactDefinition(
        id: 'fact_existing_party',
        label: 'Équipe existante',
      ),
    ],
    newGame: ProjectNewGameConfig(
      enabled: enabled,
      startMapId: 'map_start',
      startSpawnId: startSpawnId,
      playerName: 'Joueur',
      startingMoney: 350,
      initialBag: const <BagEntry>[
        BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
      ],
      initialParty: initialParty,
      initialFacts: const <String, bool>{'fact_intro_active': true},
      existingPartyFactId: 'fact_existing_party',
    ),
  );
}

MapData _startMap({String mapId = 'map_start'}) {
  return MapData(
    id: mapId,
    name: 'Start',
    size: const GridSize(width: 12, height: 10),
    mapMetadata: const MapMetadata(defaultSpawnId: 'spawn_default'),
    entities: const <MapEntity>[
      MapEntity(
        id: 'spawn_default',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 2),
        spawn: MapEntitySpawnData(
          spawnKey: 'spawn_default',
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.south,
        ),
      ),
      MapEntity(
        id: 'spawn_authored',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 7, y: 8),
        spawn: MapEntitySpawnData(
          spawnKey: 'spawn_authored',
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
  );
}
~~~~~~

### `packages/map_editor/dev/marionette_main.dart`

- Taille : `2173` octets
- SHA-256 : `0c4b5d79cee856b5e524b8644da315ee245bbe7a05c68337c2302b64ae50eeae`

~~~~~~dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_editor/main.dart' show MapEditorApp;
import 'package:map_editor/src/debug/marionette_project_bootstrap.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

/// Debug-only entrypoint for deterministic, observable macOS QA.
void main() {
  // Marionette must be the sole binding initializer in this process.
  MarionetteBinding.ensureInitialized();

  const configuredProjectPath = String.fromEnvironment(
    MarionetteProjectBootstrap.projectPathDefine,
  );
  final bootstrap = MarionetteProjectBootstrap.load(configuredProjectPath);
  final initialState = bootstrap.createInitialState();
  final container = ProviderContainer(
    overrides: <Override>[
      editorNotifierProvider.overrideWith(
        () => _MarionetteSeededEditorNotifier(initialState),
      ),
    ],
  );

  // Force provider creation before runApp, then expose the live provider state
  // so the driver can prove that the rendered shell owns the expected copy.
  container.read(editorNotifierProvider);
  registerMarionetteExtension(
    name: 'pokemap.activeProjectPath',
    description: 'Returns the active and expected PokeMap project roots.',
    callback: (_) async {
      final activePath = container.read(editorNotifierProvider).projectRootPath;
      return MarionetteExtensionResult.success(<String, dynamic>{
        'activeProjectPath': activePath,
        'expectedProjectPath': bootstrap.projectRootPath,
        'matches': activePath == bootstrap.projectRootPath,
      });
    },
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MapEditorApp(),
    ),
  );
}

/// Seeds only the debug container; production continues to use EditorNotifier.
final class _MarionetteSeededEditorNotifier extends EditorNotifier {
  _MarionetteSeededEditorNotifier(this.initialState);

  final EditorState initialState;

  @override
  EditorState build() => initialState;
}
~~~~~~

### `packages/map_editor/lib/src/debug/marionette_project_bootstrap.dart`

- Taille : `2767` octets
- SHA-256 : `bf92514a0545e95c652e10d67ad63ae807544993bd1e94e8a4f1edc967cefc41`

~~~~~~dart
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../application/models/narrative_event_authoring_session.dart';
import '../features/editor/state/editor_state.dart';

/// Immutable, prevalidated project seed used only by the Marionette entrypoint.
///
/// Loading happens before `runApp`, so desktop QA never races the editor's
/// remembered-project restoration and never interacts with an uncertain root.
final class MarionetteProjectBootstrap {
  const MarionetteProjectBootstrap._({
    required this.projectRootPath,
    required this.manifest,
  });

  static const projectPathDefine = 'MARIONETTE_PROJECT_PATH';

  final String projectRootPath;
  final ProjectManifest manifest;

  /// Resolves and validates the required debug project root synchronously.
  ///
  /// Synchronous I/O is intentional here: any missing, unreadable, symlinked,
  /// or invalid project aborts before Flutter can render an interactive frame.
  static MarionetteProjectBootstrap load(String configuredProjectPath) {
    final trimmed = configuredProjectPath.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        configuredProjectPath,
        projectPathDefine,
        'A deterministic project root is required for desktop QA.',
      );
    }

    final requestedRoot = p.normalize(p.absolute(trimmed));
    final directory = Directory(requestedRoot);
    if (!directory.existsSync()) {
      throw StateError(
          'Marionette project root does not exist: $requestedRoot');
    }

    final resolvedRoot = p.normalize(directory.resolveSymbolicLinksSync());
    if (resolvedRoot != requestedRoot) {
      throw StateError(
        'Marionette project root resolved to a different path: '
        '$requestedRoot -> $resolvedRoot',
      );
    }

    final manifestFile = File(p.join(resolvedRoot, 'project.json'));
    if (!manifestFile.existsSync()) {
      throw StateError(
        'Marionette project manifest does not exist: ${manifestFile.path}',
      );
    }

    final decoded = decodeValidatedNarrativeEventAuthoringProject(
      manifestFile.readAsBytesSync(),
    );
    return MarionetteProjectBootstrap._(
      projectRootPath: resolvedRoot,
      manifest: decoded.manifest,
    );
  }

  /// Produces the exact editor state exposed to the real shell on first frame.
  ///
  /// A non-null project also makes production auto-restore exit immediately,
  /// preserving the debug bootstrap as the single project source of truth.
  EditorState createInitialState() {
    return EditorState(
      projectRootPath: projectRootPath,
      project: manifest,
      workspaceMode: EditorWorkspaceMode.map,
      statusMessage: 'Projet QA « ${manifest.name} » chargé',
    );
  }
}
~~~~~~

### `packages/map_editor/lib/src/features/narrative/state/narrative_validator_providers.dart`

- Taille : `8231` octets
- SHA-256 : `2f646ca672f48c4052e20e82a5dd9ac223e749b6a5cc40f32ffd40cb903cb692`

~~~~~~dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../application/models/narrative_event_authoring_session.dart';
import '../../../application/services/pokemon_project_data_reader.dart';
import '../../../infrastructure/filesystem/project_filesystem.dart';

class NarrativeValidatorPokemonCatalogSnapshot {
  NarrativeValidatorPokemonCatalogSnapshot({
    required Set<String>? speciesIds,
    required Set<String>? moveIds,
  })  : speciesIds = speciesIds == null
            ? null
            : Set<String>.unmodifiable(_normalizedIds(speciesIds)),
        moveIds = moveIds == null
            ? null
            : Set<String>.unmodifiable(_normalizedIds(moveIds)) {
    final sortedSpeciesIds = this.speciesIds == null
        ? null
        : (this.speciesIds!.toList(growable: false)..sort());
    final sortedMoveIds = this.moveIds == null
        ? null
        : (this.moveIds!.toList(growable: false)..sort());
    fingerprint = narrativeEventBytesFingerprint(
      canonicalizeNarrativeEventJsonUtf8({
        'speciesCatalogAvailable': this.speciesIds != null,
        'speciesIds': sortedSpeciesIds ?? const <String>[],
        'moveCatalogAvailable': this.moveIds != null,
        'moveIds': sortedMoveIds ?? const <String>[],
      }),
    );
  }

  final Set<String>? speciesIds;
  final Set<String>? moveIds;
  late final String fingerprint;
}

class NarrativeValidatorPokemonCatalogRequest {
  NarrativeValidatorPokemonCatalogRequest({
    required String projectRootPath,
    required this.pokemon,
  })  : projectRootPath = p.normalize(projectRootPath),
        configFingerprint = narrativeEventBytesFingerprint(
          canonicalizeNarrativeEventJsonUtf8(pokemon.toJson()),
        );

  factory NarrativeValidatorPokemonCatalogRequest.fromValidationRequest(
    NarrativeValidatorSnapshotRequest request,
  ) {
    return NarrativeValidatorPokemonCatalogRequest(
      projectRootPath: request.projectRootPath,
      pokemon: request.project.pokemon,
    );
  }

  final String projectRootPath;
  final ProjectPokemonConfig pokemon;
  final String configFingerprint;

  @override
  bool operator ==(Object other) =>
      other is NarrativeValidatorPokemonCatalogRequest &&
      other.projectRootPath == projectRootPath &&
      other.configFingerprint == configFingerprint;

  @override
  int get hashCode => Object.hash(projectRootPath, configFingerprint);
}

class NarrativeValidatorSnapshotRequest {
  const NarrativeValidatorSnapshotRequest({
    required this.projectRootPath,
    required this.snapshotFingerprint,
    required this.project,
    this.activeMap,
    this.pokemonCatalogFingerprint,
  });

  factory NarrativeValidatorSnapshotRequest.fromProject({
    required String projectRootPath,
    required ProjectManifest project,
    MapData? activeMap,
    String? pokemonCatalogFingerprint,
  }) {
    return NarrativeValidatorSnapshotRequest(
      projectRootPath: p.normalize(projectRootPath),
      snapshotFingerprint: narrativeEventBytesFingerprint(
        canonicalizeNarrativeEventJsonUtf8({
          'project': project.toJson(),
          if (activeMap != null) 'activeMap': activeMap.toJson(),
          if (pokemonCatalogFingerprint != null)
            'pokemonCatalogFingerprint': pokemonCatalogFingerprint,
        }),
      ),
      project: project,
      activeMap: activeMap,
      pokemonCatalogFingerprint: pokemonCatalogFingerprint,
    );
  }

  final String projectRootPath;
  final String snapshotFingerprint;
  final ProjectManifest project;
  final MapData? activeMap;
  final String? pokemonCatalogFingerprint;

  NarrativeValidatorSnapshotRequest withPokemonCatalogFingerprint(
    String fingerprint,
  ) {
    return NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: projectRootPath,
      project: project,
      activeMap: activeMap,
      pokemonCatalogFingerprint: fingerprint,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NarrativeValidatorSnapshotRequest &&
      other.projectRootPath == projectRootPath &&
      other.snapshotFingerprint == snapshotFingerprint;

  @override
  int get hashCode => Object.hash(projectRootPath, snapshotFingerprint);
}

typedef LoadNarrativeValidatorPokemonCatalogSnapshot
    = Future<NarrativeValidatorPokemonCatalogSnapshot> Function(
  NarrativeValidatorPokemonCatalogRequest request,
);

typedef LoadNarrativeValidatorReport = Future<NarrativeProjectValidationReport>
    Function(
  NarrativeValidatorSnapshotRequest request,
  NarrativeValidatorPokemonCatalogSnapshot pokemonCatalogs,
);

final narrativeValidatorPokemonCatalogLoaderProvider =
    Provider<LoadNarrativeValidatorPokemonCatalogSnapshot>((ref) {
  return (request) async {
    if (!request.pokemon.enabled) {
      return NarrativeValidatorPokemonCatalogSnapshot(
        speciesIds: const <String>{},
        moveIds: const <String>{},
      );
    }

    final workspace = ProjectFileSystem(request.projectRootPath);
    const reader = PokemonProjectDataReader();
    final speciesFuture = _loadSpeciesIds(reader, workspace);
    final movesFuture = _loadMoveIds(reader, workspace);
    return NarrativeValidatorPokemonCatalogSnapshot(
      speciesIds: await speciesFuture,
      moveIds: await movesFuture,
    );
  };
});

final narrativeValidatorPokemonCatalogSnapshotProvider =
    FutureProvider.autoDispose.family<NarrativeValidatorPokemonCatalogSnapshot,
        NarrativeValidatorPokemonCatalogRequest>((ref, request) {
  return ref.watch(narrativeValidatorPokemonCatalogLoaderProvider)(request);
});

/// Replaceable I/O seam: maps are loaded through the attested project session,
/// while the report deliberately validates the current in-memory manifest.
/// The active map replaces its saved version so unsaved authoring changes are
/// visible instead of making the Validator stale or unavailable.
final narrativeValidatorReportLoaderProvider =
    Provider<LoadNarrativeValidatorReport>((ref) {
  return (request, pokemonCatalogs) async {
    final session = await NarrativeEventAuthoringSession.prepare(
      p.join(request.projectRootPath, 'project.json'),
    );
    final maps = session.maps.toList(growable: true);
    final activeMap = request.activeMap;
    if (activeMap != null) {
      final index = maps.indexWhere((map) => map.id == activeMap.id);
      if (index < 0) {
        maps.add(activeMap);
      } else {
        maps[index] = activeMap;
      }
    }
    return validateNarrativeProject(
      request.project,
      maps: maps,
      knownSpeciesIds: pokemonCatalogs.speciesIds,
      knownMoveIds: pokemonCatalogs.moveIds,
      requirePokemonCatalogs: request.project.pokemon.enabled,
    );
  };
});

final narrativeValidatorReportProvider = FutureProvider.autoDispose.family<
    NarrativeProjectValidationReport,
    NarrativeValidatorSnapshotRequest>((ref, request) {
  final catalogRequest =
      NarrativeValidatorPokemonCatalogRequest.fromValidationRequest(request);
  final loadReport = ref.watch(narrativeValidatorReportLoaderProvider);
  return ref
      .watch(narrativeValidatorPokemonCatalogSnapshotProvider(catalogRequest)
          .future)
      .then((pokemonCatalogs) {
    final effectiveRequest =
        request.withPokemonCatalogFingerprint(pokemonCatalogs.fingerprint);
    return loadReport(
      effectiveRequest,
      pokemonCatalogs,
    );
  });
});

Future<Set<String>?> _loadSpeciesIds(
  PokemonProjectDataReader reader,
  ProjectFileSystem workspace,
) async {
  try {
    return {
      for (final entry in await reader.listSpeciesIndexEntries(workspace))
        entry.id,
    };
  } catch (_) {
    return null;
  }
}

Future<Set<String>?> _loadMoveIds(
  PokemonProjectDataReader reader,
  ProjectFileSystem workspace,
) async {
  try {
    final catalog = await reader.readCatalogByKey(workspace, 'moves');
    return {
      for (final entry in catalog.entries)
        if (entry['id'] case final String id) id,
    };
  } catch (_) {
    return null;
  }
}

Set<String> _normalizedIds(Iterable<String> values) => values
    .map((value) => value.trim())
    .where((value) => value.isNotEmpty)
    .toSet();
~~~~~~

### `packages/map_editor/lib/src/features/narrative/state/new_game_authoring_catalog_provider.dart`

- Taille : `4148` octets
- SHA-256 : `29bb114001835569327c6a26f74cbbcaccc6db72b3e1399363e0c7b829e16831`

~~~~~~dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../app/providers/core/repository_providers.dart';

final class NewGameSpawnAuthoringOption {
  const NewGameSpawnAuthoringOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

final class NewGameMapAuthoringOption {
  const NewGameMapAuthoringOption({
    required this.id,
    required this.label,
    this.spawns = const <NewGameSpawnAuthoringOption>[],
    this.loadFailed = false,
  });

  final String id;
  final String label;
  final List<NewGameSpawnAuthoringOption> spawns;
  final bool loadFailed;
}

final class NewGameMapAuthoringCatalog {
  const NewGameMapAuthoringCatalog({
    required this.maps,
    this.failedMapLabels = const <String>[],
  });

  final List<NewGameMapAuthoringOption> maps;
  final List<String> failedMapLabels;
}

final class NewGameMapAuthoringCatalogRequest {
  NewGameMapAuthoringCatalogRequest({
    required this.projectRootPath,
    required List<ProjectMapEntry> maps,
  }) : maps = List<ProjectMapEntry>.unmodifiable(maps);

  final String projectRootPath;
  final List<ProjectMapEntry> maps;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NewGameMapAuthoringCatalogRequest ||
        other.projectRootPath != projectRootPath ||
        other.maps.length != maps.length) {
      return false;
    }
    for (var index = 0; index < maps.length; index += 1) {
      if (other.maps[index] != maps[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(projectRootPath, Object.hashAll(maps));
}

final newGameMapAuthoringCatalogProvider = FutureProvider.autoDispose
    .family<NewGameMapAuthoringCatalog, NewGameMapAuthoringCatalogRequest>(
        (ref, request) async {
  final repository = ref.watch(mapRepositoryProvider);
  final workspace = ref
      .watch(projectWorkspaceFactoryProvider)
      .create(request.projectRootPath);
  final entries = request.maps.toList(growable: false)
    ..sort((left, right) {
      final byOrder = left.sortOrder.compareTo(right.sortOrder);
      if (byOrder != 0) return byOrder;
      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });
  final maps = <NewGameMapAuthoringOption>[];
  final failedMapLabels = <String>[];

  for (final entry in entries) {
    try {
      final map = await repository.loadMap(
        workspace.resolveMapPath(entry.relativePath),
      );
      final spawns = <NewGameSpawnAuthoringOption>[
        for (final entity in map.entities)
          if (entity.kind == MapEntityKind.spawn)
            NewGameSpawnAuthoringOption(
              id: entity.id,
              label: _spawnLabel(
                entity,
                isDefault: map.mapMetadata.defaultSpawnId == entity.id,
              ),
            ),
      ]..sort((left, right) {
          return left.label.toLowerCase().compareTo(right.label.toLowerCase());
        });
      maps.add(
        NewGameMapAuthoringOption(
          id: entry.id,
          label: entry.name.trim().isEmpty ? entry.id : entry.name.trim(),
          spawns: List<NewGameSpawnAuthoringOption>.unmodifiable(spawns),
        ),
      );
    } catch (_) {
      final label = entry.name.trim().isEmpty ? entry.id : entry.name.trim();
      failedMapLabels.add(label);
      maps.add(
        NewGameMapAuthoringOption(
          id: entry.id,
          label: label,
          loadFailed: true,
        ),
      );
    }
  }

  return NewGameMapAuthoringCatalog(
    maps: List<NewGameMapAuthoringOption>.unmodifiable(maps),
    failedMapLabels: List<String>.unmodifiable(failedMapLabels),
  );
});

String _spawnLabel(MapEntity entity, {required bool isDefault}) {
  final authoredLabel = entity.spawn?.spawnKey.trim();
  final entityName = entity.name.trim();
  final label = authoredLabel != null && authoredLabel.isNotEmpty
      ? authoredLabel
      : entityName.isNotEmpty
          ? entityName
          : entity.id;
  return isDefault ? '$label · spawn par défaut' : label;
}
~~~~~~

### `packages/map_editor/lib/src/features/narrative/state/scene_consequence_catalog_providers.dart`

- Taille : `8554` octets
- SHA-256 : `a7513ca504f8edfaed25821f5ca00eaef7c7326f098063b76dea65435e7b7500`

~~~~~~dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../app/providers/core/repository_providers.dart';
import '../../../app/providers/pokedex/pokedex_providers.dart';
import '../../../app/providers/pokemon_items/pokemon_items_workspace_providers.dart';

enum SceneConsequenceCatalogStatus {
  ready,
  unavailable,
  failed,
}

/// Editor-only option projected from a project-owned catalog.
///
/// [id] is kept as the persisted value, while normal authoring surfaces only
/// render [label] and user-facing [details]. This prevents a raw-ID fallback
/// from becoming the default workflow when a catalog entry is missing.
final class SceneConsequenceCatalogOption {
  const SceneConsequenceCatalogOption({
    required this.id,
    required this.label,
    this.details = const <String>[],
  });

  final String id;
  final String label;
  final List<String> details;
}

final class SceneConsequenceCatalogSection {
  const SceneConsequenceCatalogSection({
    required this.status,
    required this.options,
    required this.message,
  });

  const SceneConsequenceCatalogSection.loading()
      : status = SceneConsequenceCatalogStatus.unavailable,
        options = const <SceneConsequenceCatalogOption>[],
        message = 'Chargement du catalogue local…';

  final SceneConsequenceCatalogStatus status;
  final List<SceneConsequenceCatalogOption> options;
  final String message;

  /// A catalog with no selectable entries must not enable its picker.
  bool get isReady =>
      status == SceneConsequenceCatalogStatus.ready && options.isNotEmpty;
}

final class SceneConsequenceCatalogs {
  const SceneConsequenceCatalogs({
    required this.items,
    required this.species,
    this.configuredStarters = const SceneConsequenceCatalogSection(
      status: SceneConsequenceCatalogStatus.unavailable,
      options: <SceneConsequenceCatalogOption>[],
      message: 'Configurez des starters dans Nouveau Jeu.',
    ),
  });

  const SceneConsequenceCatalogs.loading()
      : items = const SceneConsequenceCatalogSection.loading(),
        species = const SceneConsequenceCatalogSection.loading(),
        configuredStarters = const SceneConsequenceCatalogSection.loading();

  const SceneConsequenceCatalogs.unavailable()
      : items = const SceneConsequenceCatalogSection(
          status: SceneConsequenceCatalogStatus.unavailable,
          options: <SceneConsequenceCatalogOption>[],
          message: 'Ouvrez un projet contenant un catalogue local d’objets.',
        ),
        species = const SceneConsequenceCatalogSection(
          status: SceneConsequenceCatalogStatus.unavailable,
          options: <SceneConsequenceCatalogOption>[],
          message: 'Ouvrez un projet contenant des espèces locales.',
        ),
        configuredStarters = const SceneConsequenceCatalogSection(
          status: SceneConsequenceCatalogStatus.unavailable,
          options: <SceneConsequenceCatalogOption>[],
          message: 'Configurez des starters dans Nouveau Jeu.',
        );

  final SceneConsequenceCatalogSection items;
  final SceneConsequenceCatalogSection species;
  final SceneConsequenceCatalogSection configuredStarters;

  SceneConsequenceCatalogs withConfiguredStarters(
    List<ProjectStarterOption> starters,
  ) {
    final options = <SceneConsequenceCatalogOption>[
      for (final starter in starters)
        if (starter.id.trim().isNotEmpty && starter.label.trim().isNotEmpty)
          SceneConsequenceCatalogOption(
            id: starter.id.trim(),
            label: starter.label.trim(),
            details: <String>[
              'Niveau ${starter.pokemon.level} · ${starter.pokemon.currentHp} PV',
              '${starter.pokemon.knownMoveIds.length} capacité(s) configurée(s)',
            ],
          ),
    ];
    return SceneConsequenceCatalogs(
      items: items,
      species: species,
      configuredStarters: options.isEmpty
          ? const SceneConsequenceCatalogSection(
              status: SceneConsequenceCatalogStatus.unavailable,
              options: <SceneConsequenceCatalogOption>[],
              message: 'Configurez des starters dans Nouveau Jeu.',
            )
          : SceneConsequenceCatalogSection(
              status: SceneConsequenceCatalogStatus.ready,
              options:
                  List<SceneConsequenceCatalogOption>.unmodifiable(options),
              message: '${options.length} starter(s) configuré(s).',
            ),
    );
  }
}

final sceneConsequenceCatalogsProvider = FutureProvider.autoDispose
    .family<SceneConsequenceCatalogs, String?>((ref, projectRootPath) async {
  final normalizedRoot = projectRootPath?.trim();
  if (normalizedRoot == null || normalizedRoot.isEmpty) {
    return const SceneConsequenceCatalogs.unavailable();
  }

  // Reuse the item and Pokédex workspace loaders so Scene authoring never
  // invents a second catalog schema or reads project JSON directly.
  final itemsFuture = _loadItems(ref, normalizedRoot);
  final speciesFuture = _loadSpecies(ref, normalizedRoot);
  return SceneConsequenceCatalogs(
    items: await itemsFuture,
    species: await speciesFuture,
  );
});

Future<SceneConsequenceCatalogSection> _loadItems(
  Ref ref,
  String projectRootPath,
) async {
  try {
    final view = await ref.watch(
      pokemonItemsCatalogWorkspaceLoaderProvider,
    )(projectRootPath);
    final options = <SceneConsequenceCatalogOption>[
      for (final entry in view.entries)
        if (entry.id.trim().isNotEmpty && entry.name.trim().isNotEmpty)
          SceneConsequenceCatalogOption(
            id: entry.id.trim(),
            label: entry.name.trim(),
            details: <String>[
              if (entry.shortDesc?.trim().isNotEmpty ?? false)
                entry.shortDesc!.trim(),
            ],
          ),
    ]..sort(_compareOptions);
    if (!view.isAvailable || options.isEmpty) {
      return SceneConsequenceCatalogSection(
        status: SceneConsequenceCatalogStatus.unavailable,
        options: const <SceneConsequenceCatalogOption>[],
        message: view.message ??
            'Le catalogue local ne contient aucun objet sélectionnable.',
      );
    }
    return SceneConsequenceCatalogSection(
      status: SceneConsequenceCatalogStatus.ready,
      options: List<SceneConsequenceCatalogOption>.unmodifiable(options),
      message: '${options.length} objets locaux disponibles.',
    );
  } catch (_) {
    return const SceneConsequenceCatalogSection(
      status: SceneConsequenceCatalogStatus.failed,
      options: <SceneConsequenceCatalogOption>[],
      message: 'Impossible de charger le catalogue local des objets.',
    );
  }
}

Future<SceneConsequenceCatalogSection> _loadSpecies(
  Ref ref,
  String projectRootPath,
) async {
  try {
    final workspace =
        ref.watch(projectWorkspaceFactoryProvider).create(projectRootPath);
    final entries = await ref.watch(pokedexEntryLoaderProvider)(workspace);
    final options = <SceneConsequenceCatalogOption>[
      for (final entry in entries)
        // A disabled species exists in the database but is deliberately not a
        // valid no-code choice for the current project.
        if (entry.isEnabledInProject &&
            entry.id.trim().isNotEmpty &&
            entry.primaryName.trim().isNotEmpty)
          SceneConsequenceCatalogOption(
            id: entry.id.trim(),
            label: entry.primaryName.trim(),
            details: <String>[
              'Pokédex n°${entry.nationalDex}',
            ],
          ),
    ]..sort(_compareOptions);
    if (options.isEmpty) {
      return const SceneConsequenceCatalogSection(
        status: SceneConsequenceCatalogStatus.unavailable,
        options: <SceneConsequenceCatalogOption>[],
        message: 'Aucune espèce locale activée n’est sélectionnable.',
      );
    }
    return SceneConsequenceCatalogSection(
      status: SceneConsequenceCatalogStatus.ready,
      options: List<SceneConsequenceCatalogOption>.unmodifiable(options),
      message: '${options.length} espèces locales disponibles.',
    );
  } catch (_) {
    return const SceneConsequenceCatalogSection(
      status: SceneConsequenceCatalogStatus.failed,
      options: <SceneConsequenceCatalogOption>[],
      message: 'Impossible de charger les espèces locales du projet.',
    );
  }
}

int _compareOptions(
  SceneConsequenceCatalogOption left,
  SceneConsequenceCatalogOption right,
) {
  return left.label.toLowerCase().compareTo(right.label.toLowerCase());
}
~~~~~~

### `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_destination.dart`

- Taille : `324` octets
- SHA-256 : `971f2a5daf4a769fc8ddfc12a0b1d9c26f7b46b4463478948534c36d3f6380b4`

~~~~~~dart
/// Selectable, project-level destinations exposed by Narrative Studio.
///
/// Maps is intentionally absent: it is a gateway to Map Editor, not a
/// Narrative Studio selection.
enum NarrativeStudioDestination {
  overview,
  storylines,
  scenes,
  events,
  cinematics,
  dialogues,
  facts,
  worldRules,
  validator,
}
~~~~~~

### `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_product_navigation.dart`

- Taille : `5059` octets
- SHA-256 : `036a22eecee9d1f719797b272beb52f641e91d38b2a7848094c5bfda89ca824e`

~~~~~~dart
import 'package:flutter/cupertino.dart';

import '../../design_system/design_system.dart';
import 'narrative_studio_destination.dart';

const narrativeStudioProductNavigationMapsKey =
    ValueKey<String>('narrative-studio-product-nav-maps');
const narrativeStudioProductNavigationStatusKey =
    ValueKey<String>('narrative-studio-product-navigation-status');

/// Provider-free project navigation shared by Narrative Studio workspaces.
class NarrativeStudioProductNavigation extends StatelessWidget {
  const NarrativeStudioProductNavigation({
    super.key,
    required this.selectedDestination,
    required this.onSelectDestination,
    required this.onOpenMaps,
    this.status,
  });

  final NarrativeStudioDestination selectedDestination;
  final ValueChanged<NarrativeStudioDestination> onSelectDestination;
  final VoidCallback onOpenMaps;

  /// Real project status supplied by the host. No placeholder is rendered when
  /// it is absent.
  final Widget? status;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(8),
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Column(
          children: [
            for (final item in _items.take(2)) ...[
              _NarrativeStudioNavigationItem(
                key: ValueKey<String>(
                  'narrative-studio-product-nav-${item.destination.name}',
                ),
                icon: item.icon,
                label: item.label,
                selected: item.destination == selectedDestination,
                onTap: () => onSelectDestination(item.destination),
              ),
              const SizedBox(height: 4),
            ],
            _NarrativeStudioNavigationItem(
              key: narrativeStudioProductNavigationMapsKey,
              icon: CupertinoIcons.map,
              label: 'Maps',
              selected: false,
              onTap: onOpenMaps,
            ),
            const SizedBox(height: 4),
            for (final item in _items.skip(2)) ...[
              _NarrativeStudioNavigationItem(
                key: ValueKey<String>(
                  'narrative-studio-product-nav-${item.destination.name}',
                ),
                icon: item.icon,
                label: item.label,
                selected: item.destination == selectedDestination,
                onTap: () => onSelectDestination(item.destination),
              ),
              const SizedBox(height: 4),
            ],
            if (status != null) ...[
              const Spacer(),
              SizedBox(
                key: narrativeStudioProductNavigationStatusKey,
                width: double.infinity,
                child: status,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NarrativeStudioNavigationItem extends StatelessWidget {
  const _NarrativeStudioNavigationItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PokeMapSidebarItem(
      icon: Icon(icon),
      label: label,
      compact: true,
      selected: selected,
      onTap: onTap,
    );
  }
}

class _DestinationNavigationItem {
  const _DestinationNavigationItem({
    required this.destination,
    required this.icon,
    required this.label,
  });

  final NarrativeStudioDestination destination;
  final IconData icon;
  final String label;
}

const _items = <_DestinationNavigationItem>[
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.overview,
    icon: CupertinoIcons.house,
    label: 'Aperçu',
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.storylines,
    icon: CupertinoIcons.rectangle_grid_1x2,
    label: 'Storylines',
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.scenes,
    icon: CupertinoIcons.photo,
    label: 'Scènes',
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.events,
    icon: CupertinoIcons.bolt_horizontal_circle,
    label: 'Événements',
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.cinematics,
    icon: CupertinoIcons.film,
    label: 'Cinématiques',
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.dialogues,
    icon: CupertinoIcons.text_bubble,
    label: 'Dialogues',
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.facts,
    icon: CupertinoIcons.doc_text,
    label: 'Facts',
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.worldRules,
    icon: CupertinoIcons.checkmark_shield,
    label: 'Règles du monde',
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.validator,
    icon: CupertinoIcons.checkmark_shield,
    label: 'Validateur',
  ),
];
~~~~~~

### `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_route_presentation.dart`

- Taille : `3237` octets
- SHA-256 : `6adf5fbd7b697eb78eeef2ac0fb8b4d63f446906e235e45358c2e8a2e5fd15bd`

~~~~~~dart
import '../../../features/editor/state/models/editor_workspace_mode.dart';
import 'narrative_studio_destination.dart';

/// UI-only description of an editor route inside Narrative Studio.
///
/// This value contains no provider or project data. Workspaces can enrich the
/// breadcrumb with a real chapter, step, scene or entity name at composition
/// time without changing destination selection.
class NarrativeStudioRoutePresentation {
  const NarrativeStudioRoutePresentation({
    required this.destination,
    required this.label,
    required this.breadcrumbLabels,
  });

  final NarrativeStudioDestination destination;
  final String label;
  final List<String> breadcrumbLabels;
}

/// Pure mapping between the existing editor routes and product navigation.
///
/// Non-narrative routes return `null`. In particular, Map Editor never selects
/// an item in the Narrative Studio rail.
NarrativeStudioRoutePresentation? narrativeStudioRoutePresentationFor(
  EditorWorkspaceMode workspaceMode,
) {
  return switch (workspaceMode) {
    EditorWorkspaceMode.narrativeOverview =>
      const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.overview,
        label: 'Aperçu',
        breadcrumbLabels: ['Aperçu'],
      ),
    EditorWorkspaceMode.globalStory => const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.storylines,
        label: 'Storylines',
        breadcrumbLabels: ['Storylines'],
      ),
    EditorWorkspaceMode.step => const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.storylines,
        label: 'Étape',
        breadcrumbLabels: ['Storylines', 'Étape'],
      ),
    EditorWorkspaceMode.scenes => const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.scenes,
        label: 'Scènes',
        breadcrumbLabels: ['Scènes'],
      ),
    EditorWorkspaceMode.events => const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.events,
        label: 'Event Builder',
        breadcrumbLabels: ['Event Builder'],
      ),
    EditorWorkspaceMode.cutscene => const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.cinematics,
        label: 'Cinématiques',
        breadcrumbLabels: ['Cinématiques'],
      ),
    EditorWorkspaceMode.dialogue => const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.dialogues,
        label: 'Dialogues',
        breadcrumbLabels: ['Dialogues'],
      ),
    EditorWorkspaceMode.facts => const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.facts,
        label: 'Facts',
        breadcrumbLabels: ['Facts'],
      ),
    EditorWorkspaceMode.worldRules => const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.worldRules,
        label: 'Règles du monde',
        breadcrumbLabels: ['Règles du monde'],
      ),
    EditorWorkspaceMode.narrativeValidator =>
      const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.validator,
        label: 'Validateur',
        breadcrumbLabels: ['Validateur'],
      ),
    _ => null,
  };
}
~~~~~~

### `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_shell_policy.dart`

- Taille : `1324` octets
- SHA-256 : `913b50de8566c588fb7712f5af1f954be457a176cfe582ba78fa6e67c0ddb342`

~~~~~~dart
import 'package:map_core/map_core.dart';

import '../../../features/editor/state/models/editor_workspace_mode.dart';

/// Incremental adoption gate for the shared Narrative Studio product shell.
///
/// The policy is deliberately detached from widgets and providers so routing
/// can be tested as a complete truth table before any workspace is migrated.
abstract final class NarrativeStudioShellPolicy {
  static bool shouldUseProductShell({
    required EditorWorkspaceMode workspaceMode,
    required EventSystemMode eventSystemMode,
  }) {
    if (workspaceMode == EditorWorkspaceMode.scenes ||
        workspaceMode == EditorWorkspaceMode.globalStory ||
        workspaceMode == EditorWorkspaceMode.step ||
        workspaceMode == EditorWorkspaceMode.cutscene ||
        workspaceMode == EditorWorkspaceMode.dialogue ||
        workspaceMode == EditorWorkspaceMode.facts ||
        workspaceMode == EditorWorkspaceMode.worldRules ||
        workspaceMode == EditorWorkspaceMode.narrativeValidator ||
        workspaceMode == EditorWorkspaceMode.narrativeOverview) {
      return true;
    }
    if (workspaceMode != EditorWorkspaceMode.events) return false;

    return switch (eventSystemMode) {
      EventSystemMode.legacyOnly => true,
      EventSystemMode.dualRead || EventSystemMode.v2Only => true,
    };
  }
}
~~~~~~

### `packages/map_editor/lib/src/ui/canvas/narrative_validator_workspace.dart`

- Taille : `26453` octets
- SHA-256 : `70000fb2ed12d4226d112c64cdd7a3f5d9090f2d6bc11904208828ba6b8711f0`

~~~~~~dart
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../theme/theme.dart';
import '../design_system/design_system.dart';

const narrativeValidatorWorkspaceKey =
    ValueKey<String>('narrative-validator-workspace');
const narrativeValidatorDiagnosticsTabKey =
    ValueKey<String>('narrative-validator-tab-diagnostics');
const narrativeValidatorMapEventsTabKey =
    ValueKey<String>('narrative-validator-tab-map-events');
const narrativeValidatorAllFilterKey =
    ValueKey<String>('narrative-validator-filter-all');
const narrativeValidatorErrorsFilterKey =
    ValueKey<String>('narrative-validator-filter-errors');
const narrativeValidatorWarningsFilterKey =
    ValueKey<String>('narrative-validator-filter-warnings');
const narrativeValidatorMapFilterKey =
    ValueKey<String>('narrative-validator-filter-map');
const narrativeValidatorDomainFilterKey =
    ValueKey<String>('narrative-validator-filter-domain');

enum _ValidatorTab { diagnostics, mapEvents }

enum _SeverityFilter { all, errors, warnings }

/// Global, read-only Narrative Validator surface.
///
/// It consumes the canonical map_core report and only owns presentation
/// filters/navigation callbacks. It never re-implements validation rules or
/// mutates project data.
class NarrativeValidatorWorkspace extends StatefulWidget {
  const NarrativeValidatorWorkspace({
    super.key,
    required this.report,
    this.onOpenDiagnostic,
    this.onOpenEvent,
    this.onOpenMap,
  });

  final NarrativeProjectValidationReport report;
  final ValueChanged<NarrativeProjectDiagnostic>? onOpenDiagnostic;
  final ValueChanged<String>? onOpenEvent;
  final ValueChanged<String>? onOpenMap;

  @override
  State<NarrativeValidatorWorkspace> createState() =>
      _NarrativeValidatorWorkspaceState();
}

class _NarrativeValidatorWorkspaceState
    extends State<NarrativeValidatorWorkspace> {
  _ValidatorTab _tab = _ValidatorTab.diagnostics;
  _SeverityFilter _severity = _SeverityFilter.all;
  String _domain = _allDomains;
  String _map = _allMaps;
  String? _selectedMapGroup;

  @override
  void didUpdateWidget(covariant NarrativeValidatorWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.report, widget.report)) {
      final keys = widget.report.mapEventViews.map(_mapGroupKey).toSet();
      final mapIds = widget.report.mapEventViews
          .where((view) => view.mapId != null)
          .map((view) => view.mapId!)
          .toSet();
      if (_selectedMapGroup != null && !keys.contains(_selectedMapGroup)) {
        _selectedMapGroup = null;
      }
      if (_map != _allMaps && !mapIds.contains(_map)) {
        _map = _allMaps;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    return Semantics(
      key: narrativeValidatorWorkspaceKey,
      container: true,
      label: report.isPlayable
          ? 'Validator narratif, projet jouable'
          : 'Validator narratif, projet non jouable',
      child: PokeMapPageSurface(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _VerdictHeader(report: report),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: PokeMapSegmentedTabs(
                    tabs: [
                      PokeMapSegmentedTab(
                        key: narrativeValidatorDiagnosticsTabKey,
                        label: 'Diagnostics',
                        icon: Icons.fact_check_outlined,
                        selected: _tab == _ValidatorTab.diagnostics,
                        onTap: () => setState(
                          () => _tab = _ValidatorTab.diagnostics,
                        ),
                      ),
                      PokeMapSegmentedTab(
                        key: narrativeValidatorMapEventsTabKey,
                        label: 'Events par map',
                        icon: Icons.map_outlined,
                        selected: _tab == _ValidatorTab.mapEvents,
                        onTap: () => setState(
                          () => _tab = _ValidatorTab.mapEvents,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: switch (_tab) {
                _ValidatorTab.diagnostics => _buildDiagnostics(context),
                _ValidatorTab.mapEvents => _buildMapEvents(context),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnostics(BuildContext context) {
    final diagnostics = widget.report.diagnostics.where((diagnostic) {
      final matchesSeverity = switch (_severity) {
        _SeverityFilter.all => true,
        _SeverityFilter.errors =>
          diagnostic.severity == NarrativeProjectDiagnosticSeverity.error,
        _SeverityFilter.warnings =>
          diagnostic.severity == NarrativeProjectDiagnosticSeverity.warning,
      };
      return matchesSeverity &&
          (_domain == _allDomains || diagnostic.domain.name == _domain) &&
          (_map == _allMaps || diagnostic.mapId == _map);
    }).toList();

    final mapViews = widget.report.mapEventViews
        .where((view) => view.mapId != null)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PokeMapPanel(
          padding: const EdgeInsets.all(10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final severity = PokeMapSegmentedTabs(
                tabs: [
                  PokeMapSegmentedTab(
                    key: narrativeValidatorAllFilterKey,
                    label: 'Tous',
                    selected: _severity == _SeverityFilter.all,
                    onTap: () => setState(
                      () => _severity = _SeverityFilter.all,
                    ),
                  ),
                  PokeMapSegmentedTab(
                    key: narrativeValidatorErrorsFilterKey,
                    label: 'Erreurs',
                    selected: _severity == _SeverityFilter.errors,
                    onTap: () => setState(
                      () => _severity = _SeverityFilter.errors,
                    ),
                  ),
                  PokeMapSegmentedTab(
                    key: narrativeValidatorWarningsFilterKey,
                    label: 'Avertissements',
                    selected: _severity == _SeverityFilter.warnings,
                    onTap: () => setState(
                      () => _severity = _SeverityFilter.warnings,
                    ),
                  ),
                ],
              );
              final domain = SizedBox(
                width: 220,
                child: PokeMapDropdownField<String>(
                  key: narrativeValidatorDomainFilterKey,
                  label: 'Domaine',
                  value: _domain,
                  items: [
                    const PokeMapDropdownItem(
                      value: _allDomains,
                      label: 'Tous les domaines',
                    ),
                    for (final value in NarrativeProjectDiagnosticDomain.values)
                      PokeMapDropdownItem(
                        value: value.name,
                        label: _domainLabel(value),
                      ),
                  ],
                  onChanged: (value) => setState(() => _domain = value),
                ),
              );
              final map = SizedBox(
                width: 220,
                child: PokeMapDropdownField<String>(
                  key: narrativeValidatorMapFilterKey,
                  label: 'Map',
                  value: _map,
                  items: [
                    const PokeMapDropdownItem(
                      value: _allMaps,
                      label: 'Toutes les maps',
                    ),
                    for (final view in mapViews)
                      PokeMapDropdownItem(
                        value: view.mapId!,
                        label: view.label,
                      ),
                  ],
                  onChanged: (value) => setState(() => _map = value),
                ),
              );
              if (constraints.maxWidth < 900) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    severity,
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [domain, map],
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: severity),
                  domain,
                  const SizedBox(width: 8),
                  map,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: diagnostics.isEmpty
              ? const PokeMapEmptyState(
                  title: 'Aucun diagnostic dans ce filtre',
                  description:
                      'Changez la sévérité, le domaine ou la map pour afficher le reste du rapport.',
                  icon: Icon(Icons.filter_alt_off_outlined),
                )
              : PokeMapPanel(
                  expandChild: true,
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: diagnostics.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final diagnostic = diagnostics[index];
                      return KeyedSubtree(
                        key: ValueKey<String>(
                          'narrative-validator-diagnostic-$index',
                        ),
                        child: PokeMapDiagnosticCallout(
                          severity: _calloutSeverity(diagnostic.severity),
                          title: _diagnosticTitle(diagnostic),
                          message: diagnostic.message,
                          actionLabel: widget.onOpenDiagnostic == null
                              ? null
                              : 'Ouvrir la source',
                          onAction: widget.onOpenDiagnostic == null
                              ? null
                              : () => widget.onOpenDiagnostic!(diagnostic),
                          semanticLabel:
                              '${_domainLabel(diagnostic.domain)}. ${diagnostic.message}',
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMapEvents(BuildContext context) {
    final views = widget.report.mapEventViews;
    if (views.isEmpty) {
      return const PokeMapEmptyState(
        title: 'Aucun Event narratif',
        description:
            'Créez un Event dans l’Event Builder pour voir son raccordement ici.',
        icon: Icon(Icons.map_outlined),
      );
    }
    final selectedKey = _selectedMapGroup ?? _mapGroupKey(views.first);
    final selected = views.firstWhere(
      (view) => _mapGroupKey(view) == selectedKey,
      orElse: () => views.first,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final groups = _MapGroupsPanel(
          views: views,
          selectedKey: _mapGroupKey(selected),
          onSelected: (key) => setState(() => _selectedMapGroup = key),
          onOpenMap: widget.onOpenMap,
        );
        final events = _MapEventEntriesPanel(
          view: selected,
          onOpenEvent: widget.onOpenEvent,
        );
        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 170, child: groups),
              const SizedBox(height: 10),
              Expanded(child: events),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 280, child: groups),
            const SizedBox(width: 10),
            Expanded(child: events),
          ],
        );
      },
    );
  }
}

class _VerdictHeader extends StatelessWidget {
  const _VerdictHeader({required this.report});

  final NarrativeProjectValidationReport report;

  @override
  Widget build(BuildContext context) {
    final verdict = report.isPlayable ? 'Jouable' : 'Non jouable';
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        SizedBox(
          width: 230,
          height: 128,
          child: PokeMapMetricCard(
            key: const ValueKey('narrative-validator-verdict'),
            title: 'Verdict projet',
            value: verdict,
            icon: report.isPlayable
                ? Icons.verified_outlined
                : Icons.gpp_bad_outlined,
            tone: report.isPlayable ? PokeMapTone.success : PokeMapTone.danger,
            subtitle: report.isPlayable
                ? 'Aucune erreur critique'
                : 'Corrections requises avant le playtest',
          ),
        ),
        SizedBox(
          width: 180,
          height: 128,
          child: PokeMapMetricCard(
            title: 'Erreurs',
            value: '${report.errorCount}',
            icon: Icons.error_outline,
            tone: report.errorCount == 0
                ? PokeMapTone.success
                : PokeMapTone.danger,
            subtitle:
                '${report.errorCount} ${report.errorCount == 1 ? 'erreur' : 'erreurs'}',
          ),
        ),
        SizedBox(
          width: 180,
          height: 128,
          child: PokeMapMetricCard(
            title: 'Avertissements',
            value: '${report.warningCount}',
            icon: Icons.warning_amber_outlined,
            tone: report.warningCount == 0
                ? PokeMapTone.neutral
                : PokeMapTone.warning,
            subtitle:
                '${report.warningCount} ${report.warningCount == 1 ? 'avertissement' : 'avertissements'}',
          ),
        ),
        SizedBox(
          width: 180,
          height: 128,
          child: PokeMapMetricCard(
            title: 'Events contrôlés',
            value: '${report.totalEventCount}',
            icon: Icons.bolt_outlined,
            tone: PokeMapTone.info,
            subtitle: 'Toutes les maps et outcomes',
          ),
        ),
      ],
    );
  }
}

class _MapGroupsPanel extends StatelessWidget {
  const _MapGroupsPanel({
    required this.views,
    required this.selectedKey,
    required this.onSelected,
    required this.onOpenMap,
  });

  final List<NarrativeMapEventsView> views;
  final String selectedKey;
  final ValueChanged<String> onSelected;
  final ValueChanged<String>? onOpenMap;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      expandChild: true,
      padding: EdgeInsets.zero,
      header: const Padding(
        padding: EdgeInsets.all(12),
        child: PokeMapSectionHeader(
          title: 'Maps et sources',
          description: 'Vue consolidée des raccordements',
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: views.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final view = views[index];
          final key = _mapGroupKey(view);
          return PokeMapCard(
            key: ValueKey<String>('narrative-validator-map-group-$key'),
            selected: key == selectedKey,
            padding: const EdgeInsets.all(10),
            onTap: () => onSelected(key),
            child: Row(
              children: [
                PokeMapIconTile(
                  icon: view.groupKind == NarrativeMapEventsGroupKind.map
                      ? Icons.map_outlined
                      : Icons.alt_route_outlined,
                  tone: view.orphanSourceCount == 0
                      ? PokeMapTone.info
                      : PokeMapTone.warning,
                  size: 32,
                  iconSize: 16,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        view.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.pokeMapColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${view.events.length} Event${view.events.length == 1 ? '' : 's'} · ${view.orphanSourceCount} source${view.orphanSourceCount == 1 ? '' : 's'} orpheline${view.orphanSourceCount == 1 ? '' : 's'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.pokeMapColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (view.mapId != null && onOpenMap != null)
                  PokeMapIconButton(
                    key: ValueKey<String>(
                      'narrative-validator-open-map-${view.mapId}',
                    ),
                    tooltip: 'Ouvrir dans Map Editor',
                    icon: const Icon(Icons.open_in_new, size: 16),
                    onPressed: () => onOpenMap!(view.mapId!),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MapEventEntriesPanel extends StatelessWidget {
  const _MapEventEntriesPanel({
    required this.view,
    required this.onOpenEvent,
  });

  final NarrativeMapEventsView view;
  final ValueChanged<String>? onOpenEvent;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      expandChild: true,
      padding: EdgeInsets.zero,
      header: Padding(
        padding: const EdgeInsets.all(12),
        child: PokeMapSectionHeader(
          title: view.label,
          description:
              '${view.events.length} raccordement${view.events.length == 1 ? '' : 's'} contrôlé${view.events.length == 1 ? '' : 's'}',
        ),
      ),
      child: view.events.isEmpty
          ? const PokeMapEmptyState(
              title: 'Aucun Event sur cette map',
              description:
                  'Cette map ne contient actuellement aucun raccordement Event V2.',
              icon: Icon(Icons.bolt_outlined),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(10),
              itemCount: view.events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final event = view.events[index];
                return PokeMapCard(
                  key: ValueKey<String>(
                    'narrative-validator-map-event-${event.eventId}',
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.pokeMapColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          PokeMapBadge(
                            label: event.enabled == false ? 'Inactif' : 'Actif',
                            variant: event.enabled == false
                                ? PokeMapBadgeVariant.neutral
                                : PokeMapBadgeVariant.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          PokeMapBadge(
                            label: _sourceLabel(event),
                            variant: PokeMapBadgeVariant.narrative,
                          ),
                          PokeMapBadge(
                            label: event.sourceConnected
                                ? 'Source raccordée'
                                : 'Source orpheline',
                            variant: event.sourceConnected
                                ? PokeMapBadgeVariant.success
                                : PokeMapBadgeVariant.error,
                          ),
                          PokeMapBadge(
                            label:
                                '${event.conditionCount} condition${event.conditionCount == 1 ? '' : 's'}',
                            variant: PokeMapBadgeVariant.info,
                          ),
                          PokeMapBadge(
                            label: event.sceneConnected
                                ? 'Scene · ${event.sceneLabel ?? event.sceneId}'
                                : 'Scene manquante',
                            variant: event.sceneConnected
                                ? PokeMapBadgeVariant.success
                                : PokeMapBadgeVariant.error,
                          ),
                          if (event.diagnosticCount > 0)
                            PokeMapBadge(
                              label:
                                  '${event.diagnosticCount} erreur${event.diagnosticCount == 1 ? '' : 's'}',
                              variant: PokeMapBadgeVariant.error,
                            ),
                          if (event.warningCount > 0)
                            PokeMapBadge(
                              label:
                                  '${event.warningCount} avertissement${event.warningCount == 1 ? '' : 's'}',
                              variant: PokeMapBadgeVariant.warning,
                            ),
                        ],
                      ),
                      if (onOpenEvent != null) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: PokeMapButton(
                            key: ValueKey<String>(
                              'narrative-validator-open-event-${event.eventId}',
                            ),
                            onPressed: () => onOpenEvent!(event.eventId),
                            size: PokeMapButtonSize.compact,
                            variant: PokeMapButtonVariant.secondary,
                            leading: const Icon(Icons.open_in_new, size: 15),
                            child: const Text('Ouvrir dans Event Builder'),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}

const _allDomains = '__all__';
const _allMaps = '__all_maps__';

String _mapGroupKey(NarrativeMapEventsView view) =>
    view.mapId ?? view.groupKind.name;

String _domainLabel(NarrativeProjectDiagnosticDomain domain) =>
    switch (domain) {
      NarrativeProjectDiagnosticDomain.storyline => 'Storylines',
      NarrativeProjectDiagnosticDomain.scene => 'Scenes',
      NarrativeProjectDiagnosticDomain.event => 'Events',
      NarrativeProjectDiagnosticDomain.dialogue => 'Dialogues',
      NarrativeProjectDiagnosticDomain.cinematic => 'Cinématiques',
      NarrativeProjectDiagnosticDomain.fact => 'Facts',
      NarrativeProjectDiagnosticDomain.worldRule => 'Règles du monde',
      NarrativeProjectDiagnosticDomain.map => 'Maps',
      NarrativeProjectDiagnosticDomain.runtime => 'Readiness runtime',
    };

String _diagnosticTitle(NarrativeProjectDiagnostic diagnostic) =>
    '${_domainLabel(diagnostic.domain)} · ${diagnostic.code}';

PokeMapDiagnosticSeverity _calloutSeverity(
  NarrativeProjectDiagnosticSeverity severity,
) =>
    switch (severity) {
      NarrativeProjectDiagnosticSeverity.info => PokeMapDiagnosticSeverity.info,
      NarrativeProjectDiagnosticSeverity.warning =>
        PokeMapDiagnosticSeverity.warning,
      NarrativeProjectDiagnosticSeverity.error =>
        PokeMapDiagnosticSeverity.error,
    };

String _sourceLabel(NarrativeMapEventEntry event) {
  final category = switch (event.sourceKind) {
    NarrativeEventSourceKind.entityInteract => switch (event.sourceEntityKind) {
        MapEntityKind.npc => 'PNJ',
        MapEntityKind.sign ||
        MapEntityKind.item ||
        MapEntityKind.custom =>
          'Objet',
        MapEntityKind.spawn => 'Spawn',
        null => 'Entité de map',
      },
    NarrativeEventSourceKind.triggerEnter => 'Zone',
    NarrativeEventSourceKind.mapEnter => 'Map',
    NarrativeEventSourceKind.outcomeReceived => 'Résultat narratif',
    null => 'Source à configurer',
  };
  final label = event.sourceOwnerLabel?.trim();
  return label == null || label.isEmpty ? category : '$category · $label';
}
~~~~~~

### `packages/map_editor/lib/src/ui/canvas/new_game/project_new_game_configuration_sheet.dart`

- Taille : `35710` octets
- SHA-256 : `3689eaa573df107de4e9ca261e078edf434fec1c15ca56af8131f46ffd192328`

~~~~~~dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../features/editor/state/editor_notifier.dart';
import '../../../features/narrative/state/new_game_authoring_catalog_provider.dart';
import '../../../features/narrative/state/scene_consequence_catalog_providers.dart';
import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

const projectNewGameConfigurationLauncherKey =
    ValueKey<String>('project-new-game-configuration-launcher');

/// Provider-backed content hosted by the Narrative Studio desktop side sheet.
class ProjectNewGameConfigurationSheet extends ConsumerWidget {
  const ProjectNewGameConfigurationSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorNotifierProvider);
    final project = editor.project;
    final projectRootPath = editor.projectRootPath?.trim();
    if (project == null || projectRootPath == null || projectRootPath.isEmpty) {
      return const PokeMapEmptyState(
        title: 'Projet indisponible',
        description:
            'Chargez un projet pour configurer son démarrage de partie.',
        icon: Icon(Icons.folder_open_rounded),
      );
    }

    final mapCatalog = ref.watch(
      newGameMapAuthoringCatalogProvider(
        NewGameMapAuthoringCatalogRequest(
          projectRootPath: projectRootPath,
          maps: project.maps,
        ),
      ),
    );
    final consequenceCatalogs =
        ref.watch(sceneConsequenceCatalogsProvider(projectRootPath));

    return mapCatalog.when(
      loading: () => const PokeMapEmptyState(
        title: 'Chargement du Nouveau Jeu…',
        description: 'Lecture des maps, spawns et catalogues du projet.',
        icon: Icon(Icons.hourglass_top_rounded),
      ),
      error: (error, _) => PokeMapEmptyState(
        title: 'Maps indisponibles',
        description: error.toString(),
        icon: const Icon(Icons.error_outline_rounded),
      ),
      data: (maps) => consequenceCatalogs.when(
        loading: () => const PokeMapEmptyState(
          title: 'Chargement des catalogues…',
          description: 'Lecture des objets et espèces activés du projet.',
          icon: Icon(Icons.hourglass_top_rounded),
        ),
        error: (error, _) => PokeMapEmptyState(
          title: 'Catalogues indisponibles',
          description: error.toString(),
          icon: const Icon(Icons.error_outline_rounded),
        ),
        data: (catalogs) => ProjectNewGameConfigurationForm(
          project: project,
          mapCatalog: maps,
          consequenceCatalogs: catalogs,
          onSave: (config) async {
            final notifier = ref.read(editorNotifierProvider.notifier);
            final latestProject = ref.read(editorNotifierProvider).project;
            if (latestProject == null) return false;
            notifier.applyInMemoryProjectManifest(
              latestProject.copyWith(newGame: config),
              statusMessage: 'Configuration Nouveau Jeu prête à sauvegarder.',
            );
            return notifier.saveProjectManifest();
          },
        ),
      ),
    );
  }
}

/// No-code authoring form for [ProjectNewGameConfig].
///
/// Every technical reference is selected from a project-owned catalog. The
/// form deliberately exposes no free-form ID field.
class ProjectNewGameConfigurationForm extends StatefulWidget {
  const ProjectNewGameConfigurationForm({
    super.key,
    required this.project,
    required this.mapCatalog,
    required this.consequenceCatalogs,
    required this.onSave,
  });

  final ProjectManifest project;
  final NewGameMapAuthoringCatalog mapCatalog;
  final SceneConsequenceCatalogs consequenceCatalogs;
  final Future<bool> Function(ProjectNewGameConfig config) onSave;

  @override
  State<ProjectNewGameConfigurationForm> createState() =>
      _ProjectNewGameConfigurationFormState();
}

class _ProjectNewGameConfigurationFormState
    extends State<ProjectNewGameConfigurationForm> {
  late bool _enabled;
  late String _startMapId;
  late String _startSpawnId;
  late String _existingPartyFactId;
  late String _starterSelectionSceneId;
  late List<BagEntry> _initialBag;
  late Map<String, bool> _initialFacts;
  late List<ProjectStarterOption> _starterOptions;
  late final TextEditingController _playerNameController;
  late final TextEditingController _startingMoneyController;
  String _selectedBagItemId = '';
  String _selectedInitialFactId = '';
  String _selectedStarterSpeciesId = '';
  bool _isSaving = false;
  String? _saveStatus;
  bool _saveFailed = false;

  @override
  void initState() {
    super.initState();
    final config = widget.project.newGame;
    _enabled = config.enabled;
    _startMapId = config.startMapId;
    _startSpawnId = config.startSpawnId ?? '';
    _existingPartyFactId = config.existingPartyFactId ?? '';
    _starterSelectionSceneId = config.starterSelectionSceneId ?? '';
    _initialBag = config.initialBag.toList(growable: true);
    _initialFacts = Map<String, bool>.from(config.initialFacts);
    _starterOptions = config.starterOptions.toList(growable: true);
    _playerNameController = TextEditingController(text: config.playerName);
    _startingMoneyController = TextEditingController(
      text: config.startingMoney.toString(),
    );
  }

  @override
  void dispose() {
    _playerNameController.dispose();
    _startingMoneyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final errors = _validationErrors();
    final selectedMap = _mapOption(_startMapId);
    final spawnOptions = selectedMap?.spawns ?? const [];

    return ListView(
      key: const ValueKey('project-new-game-configuration-form'),
      padding: const EdgeInsets.all(16),
      children: [
        PokeMapPanel(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PokeMapSectionHeader(
                title: 'Démarrage de partie',
                description:
                    'Le projet décide du point de départ et de l’état initial.',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PokeMapButton(
                    key: const ValueKey('new-game-enable-button'),
                    onPressed: () => setState(() {
                      _enabled = true;
                      _clearSaveStatus();
                    }),
                    variant: PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.small,
                    isSelected: _enabled,
                    leading: const Icon(Icons.play_arrow_rounded),
                    child: const Text('Activer'),
                  ),
                  PokeMapButton(
                    key: const ValueKey('new-game-disable-button'),
                    onPressed: () => setState(() {
                      _enabled = false;
                      _clearSaveStatus();
                    }),
                    variant: PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.small,
                    isSelected: !_enabled,
                    child: const Text('Désactiver'),
                  ),
                  PokeMapBadge(
                    label: _enabled ? 'Nouveau Jeu actif' : 'Inactif',
                    variant: _enabled
                        ? PokeMapBadgeVariant.success
                        : PokeMapBadgeVariant.neutral,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _NewGameSection(
          title: 'Point de départ',
          description: 'Choisissez une map puis un spawn déjà posé dessus.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PokeMapDropdownField<String>(
                key: const ValueKey('new-game-start-map-picker'),
                label: 'Map de départ',
                value: _startMapId,
                enabled: _enabled,
                items: <PokeMapDropdownItem<String>>[
                  const PokeMapDropdownItem(
                    value: '',
                    label: 'Choisir une map…',
                  ),
                  for (final map in widget.mapCatalog.maps)
                    PokeMapDropdownItem(value: map.id, label: map.label),
                ],
                onChanged: (value) => setState(() {
                  _startMapId = value;
                  final map = _mapOption(value);
                  _startSpawnId = map?.spawns.firstOrNull?.id ?? '';
                  _clearSaveStatus();
                }),
              ),
              const SizedBox(height: 10),
              PokeMapDropdownField<String>(
                key: const ValueKey('new-game-start-spawn-picker'),
                label: 'Spawn de départ',
                value: _startSpawnId,
                enabled: _enabled && spawnOptions.isNotEmpty,
                items: <PokeMapDropdownItem<String>>[
                  const PokeMapDropdownItem(
                    value: '',
                    label: 'Choisir un spawn…',
                  ),
                  for (final spawn in spawnOptions)
                    PokeMapDropdownItem(value: spawn.id, label: spawn.label),
                ],
                onChanged: (value) => setState(() {
                  _startSpawnId = value;
                  _clearSaveStatus();
                }),
              ),
              if (selectedMap?.loadFailed ?? false) ...[
                const SizedBox(height: 10),
                const PokeMapDiagnosticCallout(
                  severity: PokeMapDiagnosticSeverity.error,
                  message:
                      'Cette map ne peut pas être lue. Vérifiez son fichier avant de choisir un spawn.',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        _NewGameSection(
          title: 'Profil du joueur',
          description: 'Valeurs appliquées uniquement à une nouvelle partie.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PokeMapTextField(
                key: const ValueKey('new-game-player-name-field'),
                label: 'Nom par défaut',
                controller: _playerNameController,
                enabled: _enabled,
                onChanged: (_) => setState(_clearSaveStatus),
              ),
              const SizedBox(height: 10),
              PokeMapTextField(
                key: const ValueKey('new-game-starting-money-field'),
                label: 'Argent de départ',
                controller: _startingMoneyController,
                enabled: _enabled,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(_clearSaveStatus),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _NewGameSection(
          title: 'Branchement narratif',
          description:
              'Réutilisez les Facts et Scènes déjà authorés dans le projet.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PokeMapDropdownField<String>(
                key: const ValueKey('new-game-existing-party-fact-picker'),
                label: 'Fact « équipe déjà présente »',
                value: _existingPartyFactId,
                enabled: _enabled,
                items: <PokeMapDropdownItem<String>>[
                  const PokeMapDropdownItem(
                    value: '',
                    label: 'Aucun Fact dédié',
                  ),
                  for (final fact in widget.project.facts)
                    PokeMapDropdownItem(value: fact.id, label: fact.label),
                ],
                onChanged: (value) => setState(() {
                  _existingPartyFactId = value;
                  _clearSaveStatus();
                }),
              ),
              const SizedBox(height: 10),
              PokeMapDropdownField<String>(
                key: const ValueKey('new-game-starter-scene-picker'),
                label: 'Scène de choix du partenaire',
                value: _starterSelectionSceneId,
                enabled: _enabled,
                items: <PokeMapDropdownItem<String>>[
                  const PokeMapDropdownItem(
                    value: '',
                    label: 'Aucune Scène dédiée',
                  ),
                  for (final scene in widget.project.scenes)
                    PokeMapDropdownItem(value: scene.id, label: scene.name),
                ],
                onChanged: (value) => setState(() {
                  _starterSelectionSceneId = value;
                  _clearSaveStatus();
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _NewGameSection(
          title: 'Sac initial',
          description: widget.consequenceCatalogs.items.message,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: PokeMapDropdownField<String>(
                      key: const ValueKey('new-game-bag-item-picker'),
                      label: 'Objet du catalogue',
                      value: _selectedBagItemId,
                      enabled: _enabled &&
                          widget.consequenceCatalogs.items.options.isNotEmpty,
                      items: <PokeMapDropdownItem<String>>[
                        const PokeMapDropdownItem(
                          value: '',
                          label: 'Choisir un objet…',
                        ),
                        for (final option
                            in widget.consequenceCatalogs.items.options)
                          PokeMapDropdownItem(
                            value: option.id,
                            label: option.label,
                          ),
                      ],
                      onChanged: (value) => setState(() {
                        _selectedBagItemId = value;
                        _clearSaveStatus();
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PokeMapButton(
                    key: const ValueKey('new-game-bag-add'),
                    onPressed: _enabled && _selectedBagItemId.isNotEmpty
                        ? _addBagItem
                        : null,
                    size: PokeMapButtonSize.medium,
                    variant: PokeMapButtonVariant.secondary,
                    leading: const Icon(Icons.add_rounded),
                    child: const Text('Ajouter'),
                  ),
                ],
              ),
              if (widget.consequenceCatalogs.items.options.isEmpty) ...[
                const SizedBox(height: 10),
                PokeMapDiagnosticCallout(
                  severity: PokeMapDiagnosticSeverity.warning,
                  message: widget.consequenceCatalogs.items.message,
                ),
              ],
              for (final entry in _initialBag) ...[
                const SizedBox(height: 8),
                _BagEntryCard(
                  key: ValueKey('new-game-bag-entry-${entry.itemId}'),
                  label: _itemLabel(entry.itemId),
                  quantity: entry.quantity,
                  enabled: _enabled,
                  onDecrease: () => _changeBagQuantity(entry.itemId, -1),
                  onIncrease: () => _changeBagQuantity(entry.itemId, 1),
                  onRemove: () => _removeBagItem(entry.itemId),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        _NewGameSection(
          title: 'Facts initiaux',
          description: 'Ajoutez un Fact existant puis choisissez sa valeur.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: PokeMapDropdownField<String>(
                      key: const ValueKey('new-game-initial-fact-picker'),
                      label: 'Fact du projet',
                      value: _selectedInitialFactId,
                      enabled: _enabled && widget.project.facts.isNotEmpty,
                      items: <PokeMapDropdownItem<String>>[
                        const PokeMapDropdownItem(
                          value: '',
                          label: 'Choisir un Fact…',
                        ),
                        for (final fact in widget.project.facts)
                          PokeMapDropdownItem(
                            value: fact.id,
                            label: fact.label,
                          ),
                      ],
                      onChanged: (value) => setState(() {
                        _selectedInitialFactId = value;
                        _clearSaveStatus();
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PokeMapButton(
                    key: const ValueKey('new-game-initial-fact-add'),
                    onPressed: _enabled && _selectedInitialFactId.isNotEmpty
                        ? _addInitialFact
                        : null,
                    size: PokeMapButtonSize.medium,
                    variant: PokeMapButtonVariant.secondary,
                    leading: const Icon(Icons.add_rounded),
                    child: const Text('Ajouter'),
                  ),
                ],
              ),
              for (final entry in _stableFactEntries()) ...[
                const SizedBox(height: 8),
                _InitialFactCard(
                  key: ValueKey('new-game-initial-fact-${entry.key}'),
                  label: _factLabel(entry.key),
                  value: entry.value,
                  enabled: _enabled,
                  onChanged: (value) => setState(() {
                    _initialFacts[entry.key] = value;
                    _clearSaveStatus();
                  }),
                  onRemove: () => setState(() {
                    _initialFacts.remove(entry.key);
                    _clearSaveStatus();
                  }),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        _NewGameSection(
          title: 'Partenaires proposés',
          description: widget.consequenceCatalogs.species.message,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: PokeMapDropdownField<String>(
                      key: const ValueKey('new-game-starter-species-picker'),
                      label: 'Espèce locale',
                      value: _selectedStarterSpeciesId,
                      enabled: _enabled &&
                          widget.consequenceCatalogs.species.options.isNotEmpty,
                      items: <PokeMapDropdownItem<String>>[
                        const PokeMapDropdownItem(
                          value: '',
                          label: 'Choisir une espèce…',
                        ),
                        for (final option
                            in widget.consequenceCatalogs.species.options)
                          PokeMapDropdownItem(
                            value: option.id,
                            label: option.label,
                          ),
                      ],
                      onChanged: (value) => setState(() {
                        _selectedStarterSpeciesId = value;
                        _clearSaveStatus();
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PokeMapButton(
                    key: const ValueKey('new-game-starter-add'),
                    onPressed: _enabled && _selectedStarterSpeciesId.isNotEmpty
                        ? _addStarter
                        : null,
                    size: PokeMapButtonSize.medium,
                    variant: PokeMapButtonVariant.secondary,
                    leading: const Icon(Icons.add_rounded),
                    child: const Text('Ajouter'),
                  ),
                ],
              ),
              if (widget.consequenceCatalogs.species.options.isEmpty) ...[
                const SizedBox(height: 10),
                PokeMapDiagnosticCallout(
                  severity: PokeMapDiagnosticSeverity.warning,
                  message: widget.consequenceCatalogs.species.message,
                ),
              ],
              for (final option in _starterOptions) ...[
                const SizedBox(height: 8),
                _StarterOptionCard(
                  key: ValueKey(
                    'new-game-starter-${option.pokemon.speciesId}',
                  ),
                  label: option.label,
                  level: option.pokemon.level,
                  enabled: _enabled,
                  onDecrease: () => _changeStarterLevel(option.id, -1),
                  onIncrease: () => _changeStarterLevel(option.id, 1),
                  onRemove: () => _removeStarter(option.id),
                ),
              ],
            ],
          ),
        ),
        if (_enabled && errors.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (final error in errors) ...[
            PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.error,
              message: error,
            ),
            const SizedBox(height: 6),
          ],
        ],
        if (_saveStatus case final status?) ...[
          const SizedBox(height: 4),
          PokeMapDiagnosticCallout(
            severity: _saveFailed
                ? PokeMapDiagnosticSeverity.error
                : PokeMapDiagnosticSeverity.info,
            message: status,
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                _enabled
                    ? 'La sauvegarde écrit project.json via le flux projet existant.'
                    : 'La configuration reste conservée mais ne sera pas appliquée au runtime.',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 12),
            PokeMapButton(
              key: const ValueKey('new-game-save'),
              onPressed: errors.isEmpty && !_isSaving ? _save : null,
              isLoading: _isSaving,
              variant: PokeMapButtonVariant.success,
              leading: const Icon(Icons.save_rounded),
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      ],
    );
  }

  List<String> _validationErrors() {
    if (!_enabled) return const <String>[];
    final errors = <String>[];
    final map = _mapOption(_startMapId);
    if (_startMapId.trim().isEmpty) {
      errors.add('Choisissez une map de départ.');
    } else if (map == null) {
      errors.add('La map de départ sélectionnée n’existe plus dans le projet.');
    }
    final spawns = map?.spawns ?? const <NewGameSpawnAuthoringOption>[];
    if (spawns.isEmpty) {
      errors.add('Aucun spawn de départ sélectionnable pour cette map.');
    } else if (_startSpawnId.trim().isEmpty) {
      errors.add('Choisissez un spawn de départ.');
    } else if (!spawns.any((spawn) => spawn.id == _startSpawnId)) {
      errors.add('Le spawn de départ sélectionné n’existe plus sur cette map.');
    }
    if (_playerNameController.text.trim().isEmpty) {
      errors.add('Le nom du joueur ne peut pas être vide.');
    }
    final money = int.tryParse(_startingMoneyController.text.trim());
    if (money == null || money < 0) {
      errors.add('L’argent de départ doit être un nombre positif ou nul.');
    }
    if (_existingPartyFactId.isNotEmpty &&
        !widget.project.facts.any((fact) => fact.id == _existingPartyFactId)) {
      errors.add('Le Fact « équipe déjà présente » n’existe plus.');
    }
    if (_starterSelectionSceneId.isNotEmpty &&
        !widget.project.scenes
            .any((scene) => scene.id == _starterSelectionSceneId)) {
      errors.add('La Scène de choix du partenaire n’existe plus.');
    }
    return errors;
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _saveStatus = null;
      _saveFailed = false;
    });
    try {
      final saved = await widget.onSave(_buildConfig());
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveFailed = !saved;
        _saveStatus = saved
            ? 'Configuration sauvegardée.'
            : 'La configuration n’a pas pu être sauvegardée.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveFailed = true;
        _saveStatus = 'Échec de la sauvegarde : $error';
      });
    }
  }

  ProjectNewGameConfig _buildConfig() {
    final previous = widget.project.newGame;
    return ProjectNewGameConfig(
      enabled: _enabled,
      startMapId: _startMapId.trim(),
      startSpawnId: _startSpawnId.trim().isEmpty ? null : _startSpawnId.trim(),
      playerName: _playerNameController.text.trim(),
      startingMoney: int.tryParse(_startingMoneyController.text.trim()) ?? -1,
      initialBag: List<BagEntry>.unmodifiable(_initialBag),
      initialParty: previous.initialParty,
      initialFacts: Map<String, bool>.unmodifiable(_initialFacts),
      existingPartyFactId:
          _existingPartyFactId.isEmpty ? null : _existingPartyFactId.trim(),
      starterSelectionSceneId: _starterSelectionSceneId.isEmpty
          ? null
          : _starterSelectionSceneId.trim(),
      starterOptions: List<ProjectStarterOption>.unmodifiable(_starterOptions),
    );
  }

  NewGameMapAuthoringOption? _mapOption(String id) {
    return widget.mapCatalog.maps.where((map) => map.id == id).firstOrNull;
  }

  void _addBagItem() {
    final id = _selectedBagItemId;
    final index = _initialBag.indexWhere((entry) => entry.itemId == id);
    setState(() {
      if (index >= 0) {
        final current = _initialBag[index];
        _initialBag[index] = current.copyWith(quantity: current.quantity + 1);
      } else {
        _initialBag.add(
          BagEntry(itemId: id, categoryId: 'items', quantity: 1),
        );
      }
      _selectedBagItemId = '';
      _clearSaveStatus();
    });
  }

  void _changeBagQuantity(String itemId, int delta) {
    final index = _initialBag.indexWhere((entry) => entry.itemId == itemId);
    if (index < 0) return;
    setState(() {
      final current = _initialBag[index];
      final next = current.quantity + delta;
      if (next <= 0) {
        _initialBag.removeAt(index);
      } else {
        _initialBag[index] = current.copyWith(quantity: next);
      }
      _clearSaveStatus();
    });
  }

  void _removeBagItem(String itemId) {
    setState(() {
      _initialBag.removeWhere((entry) => entry.itemId == itemId);
      _clearSaveStatus();
    });
  }

  void _addInitialFact() {
    final id = _selectedInitialFactId;
    final fact = widget.project.facts.where((entry) => entry.id == id).first;
    setState(() {
      _initialFacts.putIfAbsent(id, () => fact.defaultValue);
      _selectedInitialFactId = '';
      _clearSaveStatus();
    });
  }

  void _addStarter() {
    final speciesId = _selectedStarterSpeciesId;
    final catalogOption = widget.consequenceCatalogs.species.options
        .where((option) => option.id == speciesId)
        .first;
    final baseId = 'starter_${_safeId(speciesId)}';
    var optionId = baseId;
    var suffix = 2;
    while (_starterOptions.any((option) => option.id == optionId)) {
      optionId = '${baseId}_$suffix';
      suffix += 1;
    }
    setState(() {
      _starterOptions.add(
        ProjectStarterOption(
          id: optionId,
          label: catalogOption.label,
          pokemon: PlayerPokemon(
            speciesId: speciesId,
            natureId: 'hardy',
            abilityId: 'unknown',
            level: 5,
            currentHp: 1,
          ),
        ),
      );
      _selectedStarterSpeciesId = '';
      _clearSaveStatus();
    });
  }

  void _changeStarterLevel(String optionId, int delta) {
    final index = _starterOptions.indexWhere((option) => option.id == optionId);
    if (index < 0) return;
    setState(() {
      final current = _starterOptions[index];
      final nextLevel = (current.pokemon.level + delta).clamp(1, 100);
      _starterOptions[index] = ProjectStarterOption(
        id: current.id,
        label: current.label,
        pokemon: current.pokemon.copyWith(level: nextLevel),
      );
      _clearSaveStatus();
    });
  }

  void _removeStarter(String optionId) {
    setState(() {
      _starterOptions.removeWhere((option) => option.id == optionId);
      _clearSaveStatus();
    });
  }

  List<MapEntry<String, bool>> _stableFactEntries() {
    final entries = _initialFacts.entries.toList(growable: false);
    entries.sort((left, right) {
      return _factLabel(left.key)
          .toLowerCase()
          .compareTo(_factLabel(right.key).toLowerCase());
    });
    return entries;
  }

  String _itemLabel(String id) {
    return widget.consequenceCatalogs.items.options
            .where((option) => option.id == id)
            .firstOrNull
            ?.label ??
        'Objet non disponible';
  }

  String _factLabel(String id) {
    return widget.project.facts
            .where((fact) => fact.id == id)
            .firstOrNull
            ?.label ??
        'Fact non disponible';
  }

  void _clearSaveStatus() {
    _saveStatus = null;
    _saveFailed = false;
  }
}

class _NewGameSection extends StatelessWidget {
  const _NewGameSection({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapSectionHeader(title: title, description: description),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _BagEntryCard extends StatelessWidget {
  const _BagEntryCard({
    super.key,
    required this.label,
    required this.quantity,
    required this.enabled,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  final String label;
  final int quantity;
  final bool enabled;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          PokeMapBadge(label: '×$quantity'),
          const SizedBox(width: 6),
          _SmallAction(label: '−', enabled: enabled, onPressed: onDecrease),
          const SizedBox(width: 4),
          _SmallAction(label: '+', enabled: enabled, onPressed: onIncrease),
          const SizedBox(width: 4),
          _SmallAction(
            label: 'Retirer',
            enabled: enabled,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _InitialFactCard extends StatelessWidget {
  const _InitialFactCard({
    super.key,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.onRemove,
  });

  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          PokeMapButton(
            onPressed: enabled ? () => onChanged(false) : null,
            size: PokeMapButtonSize.small,
            variant: PokeMapButtonVariant.secondary,
            isSelected: !value,
            child: const Text('Faux'),
          ),
          const SizedBox(width: 4),
          PokeMapButton(
            onPressed: enabled ? () => onChanged(true) : null,
            size: PokeMapButtonSize.small,
            variant: PokeMapButtonVariant.secondary,
            isSelected: value,
            child: const Text('Vrai'),
          ),
          const SizedBox(width: 4),
          _SmallAction(
            label: 'Retirer',
            enabled: enabled,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _StarterOptionCard extends StatelessWidget {
  const _StarterOptionCard({
    super.key,
    required this.label,
    required this.level,
    required this.enabled,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  final String label;
  final int level;
  final bool enabled;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          PokeMapBadge(
            label: 'Niveau $level',
            variant: PokeMapBadgeVariant.narrative,
          ),
          const SizedBox(width: 6),
          _SmallAction(label: '−', enabled: enabled, onPressed: onDecrease),
          const SizedBox(width: 4),
          _SmallAction(label: '+', enabled: enabled, onPressed: onIncrease),
          const SizedBox(width: 4),
          _SmallAction(
            label: 'Retirer',
            enabled: enabled,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PokeMapButton(
      onPressed: enabled ? onPressed : null,
      size: PokeMapButtonSize.small,
      variant: PokeMapButtonVariant.ghost,
      child: Text(label),
    );
  }
}

String _safeId(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}
~~~~~~

### `packages/map_editor/test/marionette_project_bootstrap_test.dart`

- Taille : `2264` octets
- SHA-256 : `8e018e391c766445b409b62d8f6351970c8e037b33fc7feec47e4728edf57227`

~~~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/debug/marionette_project_bootstrap.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:path/path.dart' as p;

void main() {
  test('loads a validated project into the deterministic initial state', () {
    final root = _writeProject();
    addTearDown(() => root.deleteSync(recursive: true));

    final canonicalRoot = root.resolveSymbolicLinksSync();
    final bootstrap = MarionetteProjectBootstrap.load(canonicalRoot);
    final state = bootstrap.createInitialState();

    expect(bootstrap.projectRootPath, canonicalRoot);
    expect(bootstrap.manifest.name, 'Desktop QA');
    expect(state.projectRootPath, bootstrap.projectRootPath);
    expect(state.project, same(bootstrap.manifest));
    expect(state.workspaceMode, EditorWorkspaceMode.map);
  });

  test('rejects an empty project define before rendering', () {
    expect(
      () => MarionetteProjectBootstrap.load('   '),
      throwsArgumentError,
    );
  });

  test('rejects a project root without project.json', () {
    final root = Directory.systemTemp.createTempSync('pokemap_qa_missing_');
    addTearDown(() => root.deleteSync(recursive: true));

    expect(
      () => MarionetteProjectBootstrap.load(root.path),
      throwsA(isA<StateError>()),
    );
  });

  test('rejects a symlink whose requested and resolved roots differ', () {
    final root = _writeProject();
    final link = Link('${root.path}_link')..createSync(root.path);
    addTearDown(() {
      if (link.existsSync()) link.deleteSync();
      root.deleteSync(recursive: true);
    });

    expect(
      () => MarionetteProjectBootstrap.load(link.path),
      throwsA(isA<StateError>()),
    );
  });
}

Directory _writeProject() {
  final root = Directory.systemTemp.createTempSync('pokemap_qa_project_');
  const manifest = ProjectManifest(
    name: 'Desktop QA',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
    surfaceCatalog: ProjectSurfaceCatalog.empty(),
  );
  File(p.join(root.path, 'project.json')).writeAsStringSync(
    jsonEncode(manifest.toJson()),
  );
  return root;
}
~~~~~~

### `packages/map_editor/test/narrative_validator_provider_test.dart`

- Taille : `12495` octets
- SHA-256 : `8b4ab6db1743b00799bb91a91b72481a55fb271d78f7367087acdaf2f320897d`

~~~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:map_editor/src/features/narrative/state/narrative_validator_providers.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:path/path.dart' as p;

void main() {
  test('default loader validates the current unsaved manifest snapshot',
      () async {
    final projectRoot = await Directory.systemTemp.createTemp(
      'narrative_validator_provider_',
    );
    addTearDown(() => projectRoot.delete(recursive: true));
    const savedProject = ProjectManifest(
      name: 'Saved project',
      maps: [],
      tilesets: [],
    );
    await File(p.join(projectRoot.path, 'project.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(savedProject.toJson()),
    );
    final inMemoryProject = savedProject.copyWith(
      storylines: [
        StorylineAsset(
          id: 'story_unsaved',
          type: StorylineType.main,
          status: StorylineStatus.active,
          title: 'Unsaved storyline',
        ),
      ],
    );
    final request = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: projectRoot.path,
      project: inMemoryProject,
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final report = await container.read(
      narrativeValidatorReportProvider(request).future,
    );

    expect(
      report.byCode('storylineMissingBeginning').single.storylineId,
      'story_unsaved',
    );
    expect(report.isPlayable, isFalse);
    expect(
      report.byCode('runtimePokemonSpeciesCatalogUnavailable'),
      hasLength(1),
    );
    expect(
      report.byCode('runtimePokemonMoveCatalogUnavailable'),
      hasLength(1),
    );
  });

  test('default loader replaces the saved map with the active map snapshot',
      () async {
    final projectRoot = await Directory.systemTemp.createTemp(
      'narrative_validator_active_map_',
    );
    addTearDown(() => projectRoot.delete(recursive: true));
    const savedMap = MapData(
      id: 'map_live',
      name: 'Map live',
      size: GridSize(width: 8, height: 8),
      layers: [],
      entities: [
        MapEntity(
          id: 'npc_live',
          name: 'Live NPC',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 2, y: 2),
        ),
      ],
    );
    final scene = SceneAsset(
      id: 'scene_live',
      name: 'Live Scene',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'start_end',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
    );
    const eventId = 'evt_019abcde-4000-7000-8000-000000000079';
    final project = ProjectManifest(
      name: 'Active map project',
      maps: const [
        ProjectMapEntry(
          id: 'map_live',
          name: 'Map live',
          relativePath: 'maps/map_live.json',
        ),
      ],
      tilesets: const [],
      scenes: [scene],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: [
          NarrativeEventRecord.configuredStructurallyUnchecked(
            NarrativeEventDefinition(
              id: eventId,
              name: 'Live Event',
              source: NarrativeEventSourceRef.entityInteract(
                'map_live',
                'npc_live',
              ),
              conditions: const [],
              sceneId: 'scene_live',
              reusePolicy: NarrativeEventReusePolicy.oneShot,
              priority: 0,
              order: 0,
            ),
            enabled: true,
          ),
        ],
        legacyClaims: const [],
      ),
    );
    await Directory(p.join(projectRoot.path, 'maps')).create();
    await File(p.join(projectRoot.path, 'project.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(project.toJson()),
    );
    await File(p.join(projectRoot.path, 'maps', 'map_live.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(savedMap.toJson()),
    );
    final request = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: projectRoot.path,
      project: project,
      activeMap: savedMap.copyWith(entities: const []),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final report = await container.read(
      narrativeValidatorReportProvider(request).future,
    );

    final entry = report.mapEventViews.single.events.single;
    expect(entry.eventId, eventId);
    expect(entry.sourceConnected, isFalse);
    expect(
      report.diagnostics.any(
        (diagnostic) =>
            diagnostic.eventId == eventId &&
            diagnostic.severity == NarrativeProjectDiagnosticSeverity.error,
      ),
      isTrue,
    );
  });

  test('default loader validates Scene-only opponents against local catalogs',
      () async {
    final projectRoot = await Directory.systemTemp.createTemp(
      'narrative_validator_catalogs_',
    );
    addTearDown(() => projectRoot.delete(recursive: true));
    final map = _map();
    final project = _project(
      scenes: [_battleScene('trainer_unknown_catalog')],
      trainers: const [
        ProjectTrainerEntry(
          id: 'trainer_unknown_catalog',
          name: 'Dresseur inconnu',
          trainerClass: 'Trainer',
          team: [
            ProjectTrainerPokemonEntry(
              speciesId: 'missing_species',
              level: 5,
              moves: ['missing_move'],
            ),
          ],
        ),
      ],
    );
    await _writeProject(projectRoot, project, map);
    await const SeedPokemonDemoDataUseCase().execute(
      ProjectFileSystem(projectRoot.path),
    );
    final request = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: projectRoot.path,
      project: project,
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final report = await container.read(
      narrativeValidatorReportProvider(request).future,
    );

    expect(
      report.byCode('sceneBattleTrainerPokemonSpeciesUnknown'),
      hasLength(1),
    );
    expect(
      report.byCode('sceneBattleTrainerPokemonMoveUnknown'),
      hasLength(1),
    );
    expect(
      report.byCode('runtimePokemonSpeciesCatalogUnavailable'),
      isEmpty,
    );
    expect(report.byCode('runtimePokemonMoveCatalogUnavailable'), isEmpty);
  });

  test(
      'catalog refresh changes the fingerprint and does not reuse a stale report',
      () async {
    final projectRoot = await Directory.systemTemp.createTemp(
      'narrative_validator_catalog_refresh_',
    );
    addTearDown(() => projectRoot.delete(recursive: true));
    final map = _map();
    final project = _project(
      newGame: const ProjectNewGameConfig(
        starterOptions: [
          ProjectStarterOption(
            id: 'starter_refresh',
            label: 'Starter refresh',
            pokemon: PlayerPokemon(
              speciesId: 'bulbasaur',
              natureId: 'hardy',
              abilityId: 'overgrow',
              knownMoveIds: ['catalog_refresh_move'],
              level: 5,
              currentHp: 20,
            ),
          ),
        ],
      ),
    );
    await _writeProject(projectRoot, project, map);
    await const SeedPokemonDemoDataUseCase().execute(
      ProjectFileSystem(projectRoot.path),
    );
    final request = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: projectRoot.path,
      project: project,
    );
    final catalogRequest =
        NarrativeValidatorPokemonCatalogRequest.fromValidationRequest(request);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subscription = container.listen(
      narrativeValidatorReportProvider(request),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final firstReport = await container.read(
      narrativeValidatorReportProvider(request).future,
    );
    final firstSnapshot = await container.read(
      narrativeValidatorPokemonCatalogSnapshotProvider(catalogRequest).future,
    );
    expect(firstReport.byCode('runtimeMissingPokemonMove'), hasLength(1));

    final movesFile = File(
      p.join(
        projectRoot.path,
        project.pokemon.catalogFiles['moves']!,
      ),
    );
    final movesJson = (jsonDecode(await movesFile.readAsString()) as Map)
        .cast<String, dynamic>();
    (movesJson['entries'] as List).add(
      <String, dynamic>{'id': 'catalog_refresh_move', 'name': 'Refresh Move'},
    );
    await movesFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(movesJson),
    );

    container.invalidate(
      narrativeValidatorPokemonCatalogSnapshotProvider(catalogRequest),
    );
    container.invalidate(narrativeValidatorReportProvider(request));

    final secondReport = await container.read(
      narrativeValidatorReportProvider(request).future,
    );
    final secondSnapshot = await container.read(
      narrativeValidatorPokemonCatalogSnapshotProvider(catalogRequest).future,
    );

    expect(secondSnapshot.fingerprint, isNot(firstSnapshot.fingerprint));
    expect(secondReport.byCode('runtimeMissingPokemonMove'), isEmpty);
  });
}

const _mapId = 'map_catalog_validation';

MapData _map() => const MapData(
      id: _mapId,
      name: 'Catalog validation map',
      size: GridSize(width: 8, height: 8),
      layers: [],
      entities: [
        MapEntity(
          id: 'spawn_player',
          name: 'Player start',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
        ),
      ],
    );

ProjectManifest _project({
  List<SceneAsset> scenes = const [],
  List<ProjectTrainerEntry> trainers = const [],
  ProjectNewGameConfig newGame = const ProjectNewGameConfig(),
}) {
  return ProjectManifest(
    name: 'Catalog validation project',
    maps: const [
      ProjectMapEntry(
        id: _mapId,
        name: 'Catalog validation map',
        relativePath: 'maps/map_catalog_validation.json',
      ),
    ],
    tilesets: const [],
    scenes: scenes,
    trainers: trainers,
    newGame: newGame,
  );
}

SceneAsset _battleScene(String trainerId) {
  return SceneAsset(
    id: 'scene_battle',
    name: 'Catalog battle',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: trainerId,
          ),
        ),
        SceneNode(id: 'end_victory', kind: SceneNodeKind.end),
        SceneNode(id: 'end_defeat', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start_battle',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'battle',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'battle_victory',
          fromNodeId: 'battle',
          fromPortId: 'victory',
          toNodeId: 'end_victory',
          kind: SceneEdgeKind.battleVictory,
        ),
        SceneEdge(
          id: 'battle_defeat',
          fromNodeId: 'battle',
          fromPortId: 'defeat',
          toNodeId: 'end_defeat',
          kind: SceneEdgeKind.battleDefeat,
        ),
      ],
    ),
  );
}

Future<void> _writeProject(
  Directory projectRoot,
  ProjectManifest project,
  MapData map,
) async {
  await Directory(p.join(projectRoot.path, 'maps')).create(recursive: true);
  await File(p.join(projectRoot.path, 'project.json')).writeAsString(
    const JsonEncoder.withIndent('  ').convert(project.toJson()),
  );
  await File(p.join(projectRoot.path, 'maps', 'map_catalog_validation.json'))
      .writeAsString(
    const JsonEncoder.withIndent('  ').convert(map.toJson()),
  );
}
~~~~~~

### `packages/map_editor/test/narrative_validator_workspace_test.dart`

- Taille : `6815` octets
- SHA-256 : `e4d42a897d0ba466632261dc9f847608317a7c2a512c459b94df239124d79643`

~~~~~~dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_validator_workspace.dart';

void main() {
  testWidgets('shows one playability verdict and filters diagnostics',
      (tester) async {
    await _pump(tester, report: _report());

    expect(find.byKey(narrativeValidatorWorkspaceKey), findsOneWidget);
    expect(find.text('Non jouable'), findsWidgets);
    expect(find.text('2 erreurs'), findsWidgets);
    expect(find.text('1 avertissement'), findsWidgets);
    expect(find.text('Étape impossible'), findsOneWidget);
    expect(find.text('Timeline non bloquante'), findsOneWidget);

    await tester.tap(find.byKey(narrativeValidatorErrorsFilterKey));
    await tester.pumpAndSettle();

    expect(find.text('Étape impossible'), findsOneWidget);
    expect(find.text('Timeline non bloquante'), findsNothing);
  });

  testWidgets('opens the exact diagnostic source without offering fake fixes',
      (tester) async {
    NarrativeProjectDiagnostic? opened;
    await _pump(
      tester,
      report: _report(),
      onOpenDiagnostic: (diagnostic) => opened = diagnostic,
    );

    await tester.tap(find.text('Ouvrir la source').first);
    await tester.pump();

    expect(opened?.stepId, 'step_blocked');
    expect(find.text('Réparer automatiquement'), findsNothing);
  });

  testWidgets('filters diagnostics by their owning map', (tester) async {
    await _pump(tester, report: _report());

    final mapDropdown = find.descendant(
      of: find.byKey(narrativeValidatorMapFilterKey),
      matching: find.byType(DropdownButton<String>),
    );
    await tester.tap(mapDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Port des Brisants').last);
    await tester.pumpAndSettle();

    expect(find.text('Source PNJ absente de la map.'), findsOneWidget);
    expect(find.text('Étape impossible'), findsNothing);
    expect(find.text('Timeline non bloquante'), findsNothing);
  });

  testWidgets('filters diagnostics by product domain', (tester) async {
    await _pump(tester, report: _report());

    final domainDropdown = find.descendant(
      of: find.byKey(narrativeValidatorDomainFilterKey),
      matching: find.byType(DropdownButton<String>),
    );
    await tester.tap(domainDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cinématiques').last);
    await tester.pumpAndSettle();

    expect(find.text('Timeline non bloquante'), findsOneWidget);
    expect(find.text('Étape impossible'), findsNothing);
    expect(find.text('Source PNJ absente de la map.'), findsNothing);
  });

  testWidgets('consolidates map sources, conditions, Scenes and diagnostics',
      (tester) async {
    String? openedEvent;
    String? openedMap;
    await _pump(
      tester,
      report: _report(),
      onOpenEvent: (eventId) => openedEvent = eventId,
      onOpenMap: (mapId) => openedMap = mapId,
    );

    await tester.tap(find.byKey(narrativeValidatorMapEventsTabKey));
    await tester.pumpAndSettle();

    expect(find.text('Port des Brisants'), findsWidgets);
    expect(find.text('Rencontre au port'), findsOneWidget);
    expect(find.text('PNJ · Rival au port'), findsOneWidget);
    expect(find.text('2 conditions'), findsOneWidget);
    expect(find.text('Source orpheline'), findsOneWidget);
    expect(find.text('Scene · Rencontre rival'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('narrative-validator-open-event-evt_test')),
    );
    await tester.pump();
    expect(openedEvent, 'evt_test');

    await tester.tap(
      find.byKey(const ValueKey('narrative-validator-open-map-map_port')),
    );
    await tester.pump();
    expect(openedMap, 'map_port');
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required NarrativeProjectValidationReport report,
  ValueChanged<NarrativeProjectDiagnostic>? onOpenDiagnostic,
  ValueChanged<String>? onOpenEvent,
  ValueChanged<String>? onOpenMap,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 820));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: NarrativeValidatorWorkspace(
          report: report,
          onOpenDiagnostic: onOpenDiagnostic,
          onOpenEvent: onOpenEvent,
          onOpenMap: onOpenMap,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

NarrativeProjectValidationReport _report() {
  const blocked = NarrativeProjectDiagnostic(
    code: 'storylineStepNeverCompleted',
    severity: NarrativeProjectDiagnosticSeverity.error,
    domain: NarrativeProjectDiagnosticDomain.storyline,
    message: 'Étape impossible',
    path: 'storylines.main.chapter.step_blocked',
    destination: NarrativeProjectDiagnosticDestination.storyline,
    suggestedFixLabel: 'Ajouter une conséquence.',
    storylineId: 'story_main',
    chapterId: 'chapter_main',
    stepId: 'step_blocked',
  );
  const orphan = NarrativeProjectDiagnostic(
    code: 'narrativeEventSourceMissing',
    severity: NarrativeProjectDiagnosticSeverity.error,
    domain: NarrativeProjectDiagnosticDomain.event,
    message: 'Source PNJ absente de la map.',
    path: 'eventRegistry.records.evt_test.source',
    destination: NarrativeProjectDiagnosticDestination.map,
    mapId: 'map_port',
    eventId: 'evt_test',
  );
  const cinematic = NarrativeProjectDiagnostic(
    code: 'cinematicTechnicalLabel',
    severity: NarrativeProjectDiagnosticSeverity.warning,
    domain: NarrativeProjectDiagnosticDomain.cinematic,
    message: 'Timeline non bloquante',
    path: 'cinematics.intro',
    destination: NarrativeProjectDiagnosticDestination.cinematic,
    cinematicId: 'cinematic_intro',
  );
  return NarrativeProjectValidationReport(
    diagnostics: const [blocked, orphan, cinematic],
    mapEventViews: [
      NarrativeMapEventsView(
        groupKind: NarrativeMapEventsGroupKind.map,
        mapId: 'map_port',
        label: 'Port des Brisants',
        events: const [
          NarrativeMapEventEntry(
            eventId: 'evt_test',
            label: 'Rencontre au port',
            enabled: true,
            sourceKind: NarrativeEventSourceKind.entityInteract,
            mapId: 'map_port',
            sourceOwnerId: 'npc_missing',
            sourceOwnerLabel: 'Rival au port',
            sourceEntityKind: MapEntityKind.npc,
            sourceConnected: false,
            sceneId: 'scene_port',
            sceneLabel: 'Rencontre rival',
            sceneConnected: true,
            conditionCount: 2,
            diagnosticCount: 1,
          ),
        ],
      ),
    ],
  );
}
~~~~~~

### `packages/map_editor/test/project_new_game_configuration_form_test.dart`

- Taille : `9037` octets
- SHA-256 : `a802208b51b689b18d3fb88e5372817da755ab064a4ef52906736cde098ece80`

~~~~~~dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/state/new_game_authoring_catalog_provider.dart';
import 'package:map_editor/src/features/narrative/state/scene_consequence_catalog_providers.dart';
import 'package:map_editor/src/features/narrative/application/overview/narrative_overview_read_model.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_overview_workspace.dart';
import 'package:map_editor/src/ui/canvas/new_game/project_new_game_configuration_sheet.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets(
    'exposes New Game authoring from the Narrative Studio overview',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: NarrativeOverviewWorkspace(
            readModel: buildNarrativeOverviewReadModel(project: _project()),
          ),
        ),
      );

      expect(
          find.byKey(projectNewGameConfigurationLauncherKey), findsOneWidget);
      expect(find.text('Nouveau Jeu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'authors a project-owned new game with guided project catalog pickers',
    (tester) async {
      ProjectNewGameConfig? saved;

      await _pumpForm(
        tester,
        project: _project(),
        mapCatalog: const NewGameMapAuthoringCatalog(
          maps: <NewGameMapAuthoringOption>[
            NewGameMapAuthoringOption(
              id: 'map_start',
              label: 'Bourg Selbrume',
              spawns: <NewGameSpawnAuthoringOption>[
                NewGameSpawnAuthoringOption(
                  id: 'spawn_home',
                  label: 'Devant la maison',
                ),
              ],
            ),
          ],
        ),
        consequenceCatalogs: const SceneConsequenceCatalogs(
          items: SceneConsequenceCatalogSection(
            status: SceneConsequenceCatalogStatus.ready,
            options: <SceneConsequenceCatalogOption>[
              SceneConsequenceCatalogOption(
                id: 'potion',
                label: 'Potion',
              ),
            ],
            message: '1 objet local disponible.',
          ),
          species: SceneConsequenceCatalogSection(
            status: SceneConsequenceCatalogStatus.ready,
            options: <SceneConsequenceCatalogOption>[
              SceneConsequenceCatalogOption(
                id: 'bulbasaur',
                label: 'Bulbizarre',
              ),
            ],
            message: '1 espèce locale disponible.',
          ),
        ),
        onSave: (config) async {
          saved = config;
          return true;
        },
      );

      await tester.tap(find.byKey(const ValueKey('new-game-enable-button')));
      await tester.pump();

      _selectDropdown(tester, 'new-game-start-map-picker', 'map_start');
      await tester.pump();
      _selectDropdown(tester, 'new-game-start-spawn-picker', 'spawn_home');
      _selectDropdown(
        tester,
        'new-game-existing-party-fact-picker',
        'fact_existing_party',
      );
      _selectDropdown(
        tester,
        'new-game-starter-scene-picker',
        'scene_starter_choice',
      );
      _selectDropdown(tester, 'new-game-bag-item-picker', 'potion');
      _selectDropdown(
        tester,
        'new-game-initial-fact-picker',
        'fact_intro_active',
      );
      _selectDropdown(
        tester,
        'new-game-starter-species-picker',
        'bulbasaur',
      );
      await tester.pump();

      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('new-game-player-name-field')),
          matching: find.byType(TextField),
        ),
        'Brume',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('new-game-starting-money-field')),
          matching: find.byType(TextField),
        ),
        '750',
      );

      await tester.tap(find.byKey(const ValueKey('new-game-bag-add')));
      await tester.tap(find.byKey(const ValueKey('new-game-initial-fact-add')));
      await tester.tap(find.byKey(const ValueKey('new-game-starter-add')));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('new-game-bag-entry-potion')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('new-game-initial-fact-fact_intro_active')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('new-game-starter-bulbasaur')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('new-game-save')));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!.enabled, isTrue);
      expect(saved!.startMapId, 'map_start');
      expect(saved!.startSpawnId, 'spawn_home');
      expect(saved!.playerName, 'Brume');
      expect(saved!.startingMoney, 750);
      expect(saved!.existingPartyFactId, 'fact_existing_party');
      expect(saved!.starterSelectionSceneId, 'scene_starter_choice');
      expect(saved!.initialBag.single.itemId, 'potion');
      expect(saved!.initialFacts, <String, bool>{'fact_intro_active': false});
      expect(saved!.starterOptions.single.pokemon.speciesId, 'bulbasaur');
      expect(find.text('Configuration sauvegardée.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'keeps invalid enabled configuration unsaved and explains missing references',
    (tester) async {
      var saveCalls = 0;

      await _pumpForm(
        tester,
        project: _project(),
        mapCatalog: const NewGameMapAuthoringCatalog(maps: []),
        consequenceCatalogs: const SceneConsequenceCatalogs.unavailable(),
        onSave: (config) async {
          saveCalls += 1;
          return true;
        },
      );

      await tester.tap(find.byKey(const ValueKey('new-game-enable-button')));
      await tester.pump();

      expect(find.text('Choisissez une map de départ.'), findsOneWidget);
      expect(
        find.text('Aucun spawn de départ sélectionnable pour cette map.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('new-game-save')),
            )
            .onPressed,
        isNull,
      );
      expect(saveCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );
}

void _selectDropdown(
  WidgetTester tester,
  String key,
  String value,
) {
  tester
      .widget<PokeMapDropdownField<String>>(find.byKey(ValueKey(key)))
      .onChanged(value);
}

Future<void> _pumpForm(
  WidgetTester tester, {
  required ProjectManifest project,
  required NewGameMapAuthoringCatalog mapCatalog,
  required SceneConsequenceCatalogs consequenceCatalogs,
  required Future<bool> Function(ProjectNewGameConfig config) onSave,
}) async {
  tester.view.physicalSize = const Size(760, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: ProjectNewGameConfigurationForm(
          project: project,
          mapCatalog: mapCatalog,
          consequenceCatalogs: consequenceCatalogs,
          onSave: onSave,
        ),
      ),
    ),
  );
  await tester.pump();
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Selbrume',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map_start',
        name: 'Bourg Selbrume',
        relativePath: 'maps/map_start.json',
      ),
    ],
    tilesets: const [],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: 'fact_intro_active',
        label: 'Introduction active',
      ),
      NarrativeFactDefinition(
        id: 'fact_existing_party',
        label: 'Équipe déjà présente',
      ),
    ],
    scenes: <SceneAsset>[
      SceneAsset(
        id: 'scene_starter_choice',
        name: 'Choix du partenaire',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: <SceneNode>[
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: <SceneEdge>[
            SceneEdge(
              id: 'edge',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
      ),
    ],
  );
}
~~~~~~

### `packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart`

- Taille : `32494` octets
- SHA-256 : `68bdbfa046efcdb0fe8b5941cffda94db2643bec470aede90a9325579fe8cc73`

~~~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:path/path.dart' as p;

import '../tool/seed_selbrume_canonical_narrative_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seeds the canonical Selbrume narrative inventory idempotently',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));

    final first = await seedSelbrumeCanonicalNarrativeContent(fixture);
    expect(first.changedRelativePaths, isNotEmpty);

    final firstBytes = _authoredBytes(fixture);
    final second = await seedSelbrumeCanonicalNarrativeContent(fixture);
    final secondBytes = _authoredBytes(fixture);

    expect(second.changedRelativePaths, isEmpty);
    expect(secondBytes, firstBytes);

    final manifest = ProjectManifest.fromJson(
      _readJson(File(p.join(fixture.path, 'project.json'))),
    );
    expect(() => ProjectValidator.validate(manifest), returnsNormally);
    final mapsById = <String, MapData>{
      for (final entry in manifest.maps)
        entry.id: MapData.fromJson(
          _readJson(File(p.join(fixture.path, entry.relativePath))),
        ),
    };

    expect(
      manifest.characters.map((entry) => entry.id),
      containsAll(<String>[
        'mael',
        'character_lysa',
        'character_mado',
        'character_soline',
        'character_yvon',
      ]),
    );
    expect(
      manifest.trainers.map((entry) => entry.id),
      containsAll(<String>[
        'trainer_lysa_port',
        'trainer_phare_gardien_1',
        'trainer_phare_gardien_2',
        'trainer_boss_phare_pokemon',
      ]),
    );
    expect(
      manifest.dialogues.map((entry) => entry.id),
      containsAll(canonicalSelbrumeDialogueIds),
    );
    expect(
      manifest.cinematics.map((entry) => entry.id),
      containsAll(canonicalSelbrumeCinematicIds),
    );
    expect(
      manifest.scenes.map((entry) => entry.id),
      containsAll(canonicalSelbrumeSceneIds),
    );
    expect(
      manifest.facts.map((entry) => entry.id),
      containsAll(canonicalSelbrumeFactIds),
    );

    final existingPokemon = manifest.facts.singleWhere(
      (entry) => entry.id == 'fact_player_started_with_existing_pokemon',
    );
    expect(existingPokemon.defaultValue, isFalse);
    expect(manifest.newGame.enabled, isTrue);
    expect(manifest.newGame.startMapId, 'map_bourg_selbrume');
    expect(manifest.newGame.startSpawnId, 'spawn');
    expect(manifest.newGame.initialParty, isEmpty);
    expect(
      manifest.newGame.existingPartyFactId,
      'fact_player_started_with_existing_pokemon',
    );
    expect(
      manifest.newGame.starterOptions.map((option) => option.id),
      const <String>[
        'starter_bulbasaur',
        'starter_charmander',
        'starter_squirtle',
      ],
    );
    final startersById = <String, PlayerPokemon>{
      for (final option in manifest.newGame.starterOptions)
        option.id: option.pokemon,
    };
    expect(
      startersById.map(
        (id, pokemon) => MapEntry(id, pokemon.level),
      ),
      <String, int>{
        'starter_bulbasaur': 16,
        'starter_charmander': 16,
        'starter_squirtle': 16,
      },
    );
    expect(startersById['starter_bulbasaur']!.currentHp, 40);
    expect(startersById['starter_charmander']!.currentHp, 38);
    expect(startersById['starter_squirtle']!.currentHp, 40);
    expect(
      startersById['starter_bulbasaur']!.knownMoveIds,
      contains('vine_whip'),
    );
    expect(
      startersById['starter_charmander']!.knownMoveIds,
      contains('ember'),
    );
    expect(
      startersById['starter_squirtle']!.knownMoveIds,
      contains('water_gun'),
    );
    expect(
      manifest.globalProperties['selbrume.activeStarterConfiguration'],
      'projectDriven',
    );
    expect(
      manifest.globalProperties['selbrume.starterChoiceStatus'],
      'runtime_scene_consequence_bound',
    );
    expect(
      manifest.globalProperties['selbrume.dialogueChoicePersistenceStatus'],
      'runtime_yarn_outcomes_bound',
    );
    expect(
      manifest.globalProperties['selbrume.sideQuestRewardStatus'],
      'runtime_scene_consequences_bound',
    );
    expect(
      manifest.globalProperties['selbrume.cinematicStatus'],
      'visual_runtime_v1',
    );
    expect(
      manifest.globalProperties['selbrume.worldStateStatus'],
      'runtime_world_rules_v1',
    );
    expect(
      manifest.globalProperties['selbrume.routeLocksStatus'],
      'physical_entities_runtime_projected',
    );
    expect(
      manifest.globalProperties['selbrume.bossBattleStatus'],
      'static_encounter_runtime_bound',
    );

    final storylinesById = {
      for (final storyline in manifest.storylines) storyline.id: storyline,
    };
    expect(
      storylinesById.keys,
      containsAll(<String>[
        'story_main_brume_phare',
        'story_side_salt_crystals',
        'story_side_goelise_port',
        'story_side_lighthouse_cabin',
      ]),
    );
    expect(
      storylinesById['story_main_brume_phare']!
          .chapters
          .expand((chapter) => chapter.steps)
          .map((step) => step.id),
      containsAll(<String>[
        'step_intro_selbrume',
        'step_receive_mission',
        'step_go_to_port',
        'step_rival_battle',
        'step_enter_marais',
        'step_find_three_clues',
        'step_report_to_soline',
        'step_reach_lighthouse',
        'step_climb_lighthouse',
        'step_final_confrontation',
        'step_return_to_port',
        'step_main_story_completed',
      ]),
    );

    _expectDialogueFilesAndNodes(fixture, manifest);
    _expectDialogueOutcomeContract(
      fixture,
      manifest,
      'dialogue_mael_intro',
      const <String>[
        'starter_bulbasaur',
        'starter_charmander',
        'starter_squirtle',
      ],
    );
    _expectDialogueOutcomeContract(
      fixture,
      manifest,
      'dialogue_port_alert',
      const ['panic', 'reassure'],
    );
    _expectDialogueOutcomeContract(
      fixture,
      manifest,
      'dialogue_lysa_port',
      const ['confident', 'hesitant', 'aggressive'],
    );
    _expectDialogueOutcomeContract(
      fixture,
      manifest,
      'dialogue_mado',
      const ['accept_help', 'refuse_for_now'],
    );
    _expectDialogueOutcomeContract(
      fixture,
      manifest,
      'dialogue_goelise_port',
      const ['return_item', 'keep_item'],
    );
    _expectDialogueOutcomeContract(
      fixture,
      manifest,
      'dialogue_yvon_cabin',
      const ['accept_search_key', 'ignore_for_now'],
    );
    _expectEventSourcesClose(fixture, manifest);
    final session = await NarrativeEventAuthoringSession.prepare(
      p.join(fixture.path, 'project.json'),
    );
    final validationReport = buildNarrativeEventValidationReport(
      registry: session.manifest.eventRegistry!,
      catalog: session.context.catalog,
    );
    expect(
      validationReport.diagnostics.where(
        (diagnostic) =>
            diagnostic.severity == NarrativeEventValidationSeverity.error,
      ),
      isEmpty,
    );
    _expectMapNpc(fixture, 'map_bourg_selbrume', 'npc_mael', 'mael');
    _expectMapNpc(
      fixture,
      'map_marais_salants',
      'npc_mado',
      'character_mado',
    );
    _expectMapNpc(
      fixture,
      'map_port_brisants',
      'npc_soline',
      'character_soline',
    );
    _expectMapNpc(
      fixture,
      'map_phare_exterieur',
      'npc_yvon',
      'character_yvon',
    );
    _expectWorldStateContract(manifest, mapsById);
    _expectCanonicalEventProgression(manifest);

    final lysaScene = manifest.scenes.singleWhere(
      (entry) => entry.id == 'scene_lysa_port',
    );
    expect(
      lysaScene.graph.nodes.where((node) => node.kind == SceneNodeKind.battle),
      hasLength(1),
    );
    expect(
      lysaScene.declaredOutcomes.map((outcome) => outcome.id),
      containsAll(<String>['lysa.victory', 'lysa.defeat']),
    );
    _expectStarterBranches(manifest);
    _expectCanonicalRewards(manifest);
    final finalBattle = manifest.scenes
        .singleWhere((scene) => scene.id == 'scene_final_pokemon')
        .graph
        .nodes
        .map((node) => node.payload)
        .whereType<SceneBattlePayload>()
        .single;
    expect(finalBattle.battleKind, 'static');
    expect(finalBattle.battleTemplateId, 'battle_lighthouse_pokemon');
    expect(finalBattle.trainerId, 'trainer_boss_phare_pokemon');
    expect(
      _scenesCompletingStep(manifest, 'step_climb_lighthouse'),
      <String>{'scene_lighthouse_guardian_2'},
    );
    for (final cinematic in manifest.cinematics.where(
      (entry) => canonicalSelbrumeCinematicIds.contains(entry.id),
    )) {
      expect(cinematic.timeline.steps.length, greaterThanOrEqualTo(3),
          reason: cinematic.id);
      expect(
        cinematic.timeline.steps.map((step) => step.kind).toSet(),
        isNot(equals(<CinematicTimelineStepKind>{
          CinematicTimelineStepKind.wait,
        })),
        reason: '${cinematic.id} must not remain a wait-only placeholder',
      );
    }
    _expectOutcomePathFacts(
      manifest.scenes.singleWhere((scene) => scene.id == 'scene_port_entry'),
      const <String, Set<String>>{
        'panic': {'fact_port_crowd_panicked'},
        'reassure': {'fact_port_crowd_reassured'},
      },
    );
    _expectOutcomePathFacts(
      lysaScene,
      const <String, Set<String>>{
        'confident': {'fact_lysa_tone_confident'},
        'hesitant': {'fact_lysa_tone_hesitant'},
        'aggressive': {'fact_lysa_tone_aggressive'},
      },
    );
    _expectOutcomePathFacts(
      manifest.scenes
          .singleWhere((scene) => scene.id == 'scene_goelise_nest_choice'),
      const <String, Set<String>>{
        'return_item': {'fact_goelise_object_returned'},
        'keep_item': {'fact_goelise_object_kept'},
      },
    );
    _expectYvonChoiceContract(manifest);
    _expectMistDispersalContract(manifest);
    _expectFisherEpilogueContract(manifest);
    for (final scene in manifest.scenes.where(
      (entry) => canonicalSelbrumeSceneIds.contains(entry.id),
    )) {
      final report = diagnoseSceneAgainstProject(
        scene,
        manifest,
        mapsById: mapsById,
      );
      expect(
        report.diagnostics.where(
          (diagnostic) => diagnostic.severity == SceneDiagnosticSeverity.error,
        ),
        isEmpty,
        reason: scene.id,
      );
    }
  });
}

void _expectWorldStateContract(
  ProjectManifest manifest,
  Map<String, MapData> mapsById,
) {
  const blockingEntities = <String, List<String>>{
    'map_bourg_selbrume': <String>[
      'gate_bourg_to_port',
      'gate_bourg_to_bois',
    ],
    'map_bois_chaise_brume': <String>['gate_bois_to_marais'],
    'map_marais_salants': <String>['gate_marais_to_passage'],
    'map_passage_dames': <String>['gate_passage_to_phare'],
    'map_phare_exterieur': <String>['gate_cabin_door'],
    'map_phare_interieur': <String>['gate_lighthouse_top'],
    'map_cabane_gardien': <String>['gate_cabin_shortcut'],
  };
  for (final entry in blockingEntities.entries) {
    final entities = {
      for (final entity in mapsById[entry.key]!.entities) entity.id: entity,
    };
    for (final entityId in entry.value) {
      final entity = entities[entityId];
      expect(entity, isNotNull, reason: '${entry.key}:$entityId');
      expect(entity!.blocksMovement, isTrue, reason: entityId);
      expect(entity.sign?.plainText.trim(), isNotEmpty, reason: entityId);
    }
  }

  const visualEntities = <String, Map<String, String>>{
    'map_port_brisants': <String, String>{
      'goelise_nest_proxy': 'el_port_ref_nest',
    },
    'map_marais_salants': <String, String>{
      'clue_glass_object': 'el_selbrume_indice_verre',
      'clue_electric_object': 'el_selbrume_indice_traces_electriques',
      'clue_lens_object': 'el_selbrume_indice_repere_lentille',
      'crystal_1_object': 'el_selbrume_cristal_1',
      'crystal_2_object': 'el_selbrume_cristal_2',
      'crystal_3_object': 'el_selbrume_cristal_3',
      'fog_marais': 'el_selbrume_fx_brume_basse',
    },
    'map_phare_exterieur': <String, String>{
      'cabin_key_object': 'el_selbrume_cabane_cle',
      'fog_phare': 'el_selbrume_fx_brume_basse',
    },
    'map_sommet_phare': <String, String>{
      'boss_phare_pokemon': 'el_selbrume_fx_lumiere_instable',
      'fog_sommet': 'el_selbrume_fx_brume_basse',
    },
  };
  for (final mapEntry in visualEntities.entries) {
    final entities = {
      for (final entity in mapsById[mapEntry.key]!.entities) entity.id: entity,
    };
    for (final visualEntry in mapEntry.value.entries) {
      expect(
        entities[visualEntry.key]?.editorVisual?.elementId,
        visualEntry.value,
        reason: '${mapEntry.key}:${visualEntry.key}',
      );
    }
  }

  final rulesByTarget = <String, WorldRuleDefinition>{
    for (final rule in manifest.worldRules)
      if (rule.tags.contains('canonical-narrative'))
        '${rule.target.mapId}:${rule.target.entityId}': rule,
  };
  for (final entry in blockingEntities.entries) {
    for (final entityId in entry.value) {
      final rule = rulesByTarget['${entry.key}:$entityId'];
      expect(rule, isNotNull, reason: '${entry.key}:$entityId');
      expect(rule!.effect.kind, WorldRuleEffectKind.entityHidden);
    }
  }
  for (final target in const <String>[
    'map_port_brisants:goelise_nest_proxy',
    'map_port_brisants:fog_port',
    'map_marais_salants:fog_marais',
    'map_passage_dames:fog_passage',
    'map_phare_exterieur:fog_phare',
    'map_sommet_phare:fog_sommet',
    'map_sommet_phare:boss_phare_pokemon',
  ]) {
    expect(rulesByTarget, contains(target), reason: target);
  }
  final goeliseRule = rulesByTarget['map_port_brisants:goelise_nest_proxy']!;
  expect(goeliseRule.source.kind, WorldRuleSourceKind.fact);
  expect(goeliseRule.source.sourceId, 'fact_goelise_quest_completed');
  expect(goeliseRule.effect.kind, WorldRuleEffectKind.entityHidden);

  expect(
    mapsById['map_port_brisants']!.placedElements.map((entry) => entry.id),
    isNot(contains('pe_port_nid_goelise')),
    reason:
        'The static nest placement would remain visible after the proxy is hidden.',
  );

  final diagnostics = diagnoseWorldRules(
    manifest,
    maps: mapsById.values.toList(growable: false),
  ).diagnostics.where(
        (diagnostic) => manifest.worldRules
            .singleWhere((rule) => rule.id == diagnostic.ruleId)
            .tags
            .contains('canonical-narrative'),
      );
  expect(
    diagnostics.where(
      (diagnostic) => diagnostic.severity == WorldRuleDiagnosticSeverity.error,
    ),
    isEmpty,
    reason: diagnostics
        .map((diagnostic) =>
            '${diagnostic.ruleId}:${diagnostic.code.name}:${diagnostic.message}')
        .join('\n'),
  );
}

void _expectCanonicalEventProgression(ProjectManifest manifest) {
  final definitions = <String, NarrativeEventDefinition>{
    for (final record in manifest.eventRegistry!.records)
      if (record.definitionOrNull case final definition?)
        definition.id: definition,
  };
  Set<String> requiredTrueFacts(String eventId) => definitions[eventId]!
      .conditions
      .map((condition) => condition.when(
            fact: (factId, value) => value ? factId : null,
            narrativeEventConsumed: (_, __) => null,
          ))
      .whereType<String>()
      .toSet();

  expect(
    requiredTrueFacts('evt_019abcde-4000-7000-8000-000000000001'),
    contains('fact_port_alert_seen'),
  );
  final yvon = definitions['evt_019abcde-5000-7000-8000-000000000024']!;
  expect(yvon.reusePolicy, NarrativeEventReusePolicy.reusable);
  expect(
    yvon.conditions.map((condition) => condition.when(
          fact: (factId, value) => (factId: factId, value: value),
          narrativeEventConsumed: (_, __) => null,
        )),
    contains((factId: 'fact_cabin_quest_started', value: false)),
  );

  final mistDispersal =
      definitions['evt_019abcde-5000-7000-8000-000000000036']!;
  expect(mistDispersal.sceneId, 'scene_mist_disperses');
  mistDispersal.source.when(
    entityInteract: (_, __) => fail('La dissipation vient du boss.'),
    triggerEnter: (_, __) => fail('La dissipation vient du boss.'),
    mapEnter: (_) => fail('La dissipation vient du boss.'),
    outcomeReceived: (outcome) {
      expect(outcome.producerKind, NarrativeOutcomeProducerKind.scene);
      expect(outcome.producerId, 'scene_final_pokemon');
      expect(outcome.outcomeId, 'lighthouse.pokemon.appeased');
    },
  );
  expect(
    requiredTrueFacts('evt_019abcde-4000-7000-8000-000000000002'),
    contains('fact_mael_mission_given'),
  );
  expect(
    requiredTrueFacts('evt_019abcde-4000-7000-8000-000000000003'),
    contains('fact_mado_met'),
  );
  expect(
    requiredTrueFacts('evt_019abcde-5000-7000-8000-000000000020'),
    contains('fact_lysa_goes_ahead'),
  );
  expect(
    requiredTrueFacts('evt_019abcde-5000-7000-8000-000000000027'),
    containsAll(<String>[
      'fact_lighthouse_old_note_read',
      'fact_lighthouse_guardian_1_defeated',
    ]),
  );
  final cabinKey = definitions['evt_019abcde-5000-7000-8000-000000000029']!;
  cabinKey.source.when(
    entityInteract: (_, __) => fail('La clé doit être trouvée dans une zone.'),
    triggerEnter: (mapId, triggerId) {
      expect(mapId, 'map_phare_exterieur');
      expect(triggerId, 'tr_cabin_key_outside');
    },
    mapEnter: (_) => fail('La clé doit avoir une source spatiale précise.'),
    outcomeReceived: (_) => fail('La clé ne provient pas d’un outcome.'),
  );
}

void _expectYvonChoiceContract(ProjectManifest manifest) {
  final scene = manifest.scenes.singleWhere(
    (entry) => entry.id == 'scene_yvon_intro',
  );
  final dialogue = scene.graph.nodes.singleWhere(
    (node) => node.kind == SceneNodeKind.yarnDialogue,
  );
  final payload = dialogue.payload as SceneYarnDialoguePayload;
  expect(
    payload.expectedOutcomes,
    const <String>['accept_search_key', 'ignore_for_now'],
  );

  final acceptConsequences = _reachableConsequences(
    scene,
    dialogue.id,
    'accept_search_key',
  );
  expect(
    acceptConsequences.whereType<SceneSetFactConsequence>().map(
          (consequence) => consequence.factId,
        ),
    contains('fact_cabin_quest_started'),
  );
  expect(
    acceptConsequences.whereType<SceneCompleteStoryStepConsequence>().map(
          (consequence) => consequence.stepId,
        ),
    contains('step_cabin_talk_to_yvon'),
  );

  expect(
    _reachableConsequences(scene, dialogue.id, 'ignore_for_now'),
    isEmpty,
    reason: 'Refuser pour le moment ne doit rien persister.',
  );
}

void _expectMistDispersalContract(ProjectManifest manifest) {
  final finalScene = manifest.scenes.singleWhere(
    (entry) => entry.id == 'scene_final_pokemon',
  );
  expect(
    finalScene.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneCinematicPayload>()
        .map((payload) => payload.cinematicId),
    isNot(contains('cinematic_mist_disperses')),
    reason: 'La réaction post-boss appartient à scene_mist_disperses.',
  );

  final scene = manifest.scenes.singleWhere(
    (entry) => entry.id == 'scene_mist_disperses',
  );
  expect(
    scene.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneCinematicPayload>()
        .map((payload) => payload.cinematicId),
    contains('cinematic_mist_disperses'),
  );
  final dialogue = scene.graph.nodes
      .map((node) => node.payload)
      .whereType<SceneYarnDialoguePayload>()
      .single;
  expect(dialogue.dialogueId, 'dialogue_lighthouse');
  expect(dialogue.yarnNodeName, 'MistDisperses');
  expect(
    scene.declaredOutcomes.map((outcome) => outcome.id),
    contains('mist_resolved'),
  );
  final end = scene.graph.nodes
      .map((node) => node.payload)
      .whereType<SceneEndPayload>()
      .single;
  expect(end.sceneOutcomeId, 'mist_resolved');
}

void _expectFisherEpilogueContract(ProjectManifest manifest) {
  final dialogue = manifest.dialogues.singleWhere(
    (entry) => entry.id == 'dialogue_fisher_epilogue',
  );
  expect(dialogue.defaultStartNode, 'FisherEpilogue');

  final rule = manifest.worldRules.singleWhere(
    (entry) => entry.id == 'world_rule_fisher_epilogue',
  );
  expect(rule.source.kind, WorldRuleSourceKind.fact);
  expect(rule.source.sourceId, 'fact_main_story_completed');
  expect(rule.target.mapId, 'map_port_brisants');
  expect(rule.target.entityId, 'npc_pecheur');
  expect(rule.effect.dialogueId, 'dialogue_fisher_epilogue');
  expect(rule.priority, 100);
}

Set<String> _scenesCompletingStep(
  ProjectManifest manifest,
  String stepId,
) =>
    <String>{
      for (final scene in manifest.scenes)
        if (scene.graph.nodes.any(
          (node) =>
              node.payload is SceneActionPayload &&
              (node.payload as SceneActionPayload).consequence
                  is SceneCompleteStoryStepConsequence &&
              ((node.payload as SceneActionPayload).consequence
                          as SceneCompleteStoryStepConsequence)
                      .stepId ==
                  stepId,
        ))
          scene.id,
    };

void _expectStarterBranches(ProjectManifest manifest) {
  final scene = manifest.scenes.singleWhere(
    (entry) => entry.id == 'scene_mael_intro',
  );
  final starterDialogue = scene.graph.nodes.singleWhere((node) {
    final payload = node.payload;
    return payload is SceneYarnDialoguePayload &&
        payload.yarnNodeName == 'MaelStarterChoice';
  });
  final payload = starterDialogue.payload as SceneYarnDialoguePayload;
  expect(
    payload.expectedOutcomes,
    const <String>[
      'starter_bulbasaur',
      'starter_charmander',
      'starter_squirtle',
    ],
  );
  for (final outcome in payload.expectedOutcomes) {
    final consequences = _reachableConsequences(
      scene,
      starterDialogue.id,
      outcome,
    );
    final starterGrants =
        consequences.whereType<SceneGiveConfiguredStarterConsequence>();
    expect(starterGrants, hasLength(1), reason: outcome);
    expect(starterGrants.single.starterOptionId, outcome, reason: outcome);
    expect(
      consequences
          .whereType<SceneSetFactConsequence>()
          .map((entry) => entry.factId),
      containsAll(<String>[
        'fact_starter_received',
        'fact_mael_mission_given',
      ]),
      reason: outcome,
    );
  }
}

void _expectCanonicalRewards(ProjectManifest manifest) {
  final expectedKindsByScene = <String, Set<SceneConsequenceKind>>{
    'scene_mado_crystals_return': <SceneConsequenceKind>{
      SceneConsequenceKind.giveItem,
    },
    'scene_goelise_return': <SceneConsequenceKind>{
      SceneConsequenceKind.giveMoney,
    },
    'scene_goelise_keep_reward': <SceneConsequenceKind>{
      SceneConsequenceKind.giveItem,
    },
    'scene_cabin_journal': <SceneConsequenceKind>{
      SceneConsequenceKind.giveItem,
    },
  };
  for (final entry in expectedKindsByScene.entries) {
    final scene = manifest.scenes.singleWhere((scene) => scene.id == entry.key);
    final kinds = scene.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneActionPayload>()
        .map((payload) => payload.consequence?.kind)
        .whereType<SceneConsequenceKind>()
        .toSet();
    expect(kinds, containsAll(entry.value), reason: entry.key);
  }
}

List<SceneConsequence> _reachableConsequences(
  SceneAsset scene,
  String fromNodeId,
  String fromPortId,
) {
  final nodesById = <String, SceneNode>{
    for (final node in scene.graph.nodes) node.id: node,
  };
  final pending = scene.graph.edges
      .where(
        (edge) =>
            edge.fromNodeId == fromNodeId && edge.fromPortId == fromPortId,
      )
      .map((edge) => edge.toNodeId)
      .toList();
  final visited = <String>{};
  final consequences = <SceneConsequence>[];
  while (pending.isNotEmpty) {
    final nodeId = pending.removeLast();
    if (!visited.add(nodeId)) continue;
    final node = nodesById[nodeId];
    if (node?.payload case SceneActionPayload(:final consequence?)) {
      consequences.add(consequence);
    }
    pending.addAll(
      scene.graph.edges
          .where((edge) => edge.fromNodeId == nodeId)
          .map((edge) => edge.toNodeId),
    );
  }
  return consequences;
}

void _expectDialogueOutcomeContract(
  Directory fixture,
  ProjectManifest manifest,
  String dialogueId,
  List<String> expectedOutcomeIds,
) {
  final dialogue =
      manifest.dialogues.singleWhere((entry) => entry.id == dialogueId);
  expect(
    dialogue.declaredOutcomes.map((outcome) => outcome.id),
    expectedOutcomeIds,
    reason: dialogueId,
  );
  final yarn =
      File(p.join(fixture.path, dialogue.relativePath)).readAsStringSync();
  for (final outcomeId in expectedOutcomeIds) {
    expect(yarn, contains('<<outcome $outcomeId>>'), reason: dialogueId);
  }
}

void _expectOutcomePathFacts(
  SceneAsset scene,
  Map<String, Set<String>> expectedByOutcome,
) {
  final dialogueNode = scene.graph.nodes
      .singleWhere((node) => node.kind == SceneNodeKind.yarnDialogue);
  final payload = dialogueNode.payload as SceneYarnDialoguePayload;
  expect(payload.expectedOutcomes, expectedByOutcome.keys);
  final outgoingPorts = scene.graph.edges
      .where((edge) => edge.fromNodeId == dialogueNode.id)
      .map((edge) => edge.fromPortId)
      .toSet();
  expect(
      outgoingPorts,
      containsAll(<String>{
        'completed',
        ...expectedByOutcome.keys,
      }));

  for (final entry in expectedByOutcome.entries) {
    final factIds = _reachableFactIds(scene, dialogueNode.id, entry.key);
    expect(factIds, containsAll(entry.value),
        reason: '${scene.id}:${entry.key}');
    final otherFacts = expectedByOutcome.entries
        .where((candidate) => candidate.key != entry.key)
        .expand((candidate) => candidate.value);
    expect(
      factIds.intersection(otherFacts.toSet()),
      isEmpty,
      reason: '${scene.id}:${entry.key} must not apply another choice fact',
    );
  }
}

Set<String> _reachableFactIds(
  SceneAsset scene,
  String fromNodeId,
  String fromPortId,
) {
  final nodesById = <String, SceneNode>{
    for (final node in scene.graph.nodes) node.id: node,
  };
  final pending = scene.graph.edges
      .where(
        (edge) =>
            edge.fromNodeId == fromNodeId && edge.fromPortId == fromPortId,
      )
      .map((edge) => edge.toNodeId)
      .toList();
  final visited = <String>{};
  final facts = <String>{};
  while (pending.isNotEmpty) {
    final nodeId = pending.removeLast();
    if (!visited.add(nodeId)) continue;
    final node = nodesById[nodeId];
    if (node?.payload case SceneActionPayload(:final consequence)) {
      if (consequence case SceneSetFactConsequence(:final factId)) {
        facts.add(factId);
      }
    }
    pending.addAll(
      scene.graph.edges
          .where((edge) => edge.fromNodeId == nodeId)
          .map((edge) => edge.toNodeId),
    );
  }
  return facts;
}

Map<String, List<int>> _authoredBytes(Directory fixture) {
  final files = <File>[
    File(p.join(fixture.path, 'project.json')),
    ...Directory(p.join(fixture.path, 'maps'))
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json')),
    ...Directory(p.join(fixture.path, 'dialogues'))
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.yarn')),
  ]..sort((left, right) => left.path.compareTo(right.path));
  return <String, List<int>>{
    for (final file in files)
      p.relative(file.path, from: fixture.path): file.readAsBytesSync(),
  };
}

void _expectDialogueFilesAndNodes(
  Directory fixture,
  ProjectManifest manifest,
) {
  for (final dialogue in manifest.dialogues.where(
    (entry) => canonicalSelbrumeDialogueIds.contains(entry.id),
  )) {
    final file = File(p.join(fixture.path, dialogue.relativePath));
    expect(file.existsSync(), isTrue, reason: dialogue.id);
    final content = file.readAsStringSync();
    expect(content, contains('title: ${dialogue.defaultStartNode}'));
    expect(content, contains('==='));
  }
}

void _expectEventSourcesClose(
  Directory fixture,
  ProjectManifest manifest,
) {
  final registry = manifest.eventRegistry!;
  expect(registry.records.length, greaterThanOrEqualTo(20));
  final sceneIds = manifest.scenes.map((scene) => scene.id).toSet();
  final facts = manifest.facts.map((fact) => fact.id).toSet();
  final mapCache = <String, Map<String, dynamic>>{};

  for (final record in registry.records) {
    final definition = record.definitionOrNull;
    if (definition == null) continue;
    expect(sceneIds, contains(definition.sceneId), reason: definition.id);
    for (final condition in definition.conditions) {
      condition.when(
        fact: (factId, _) =>
            expect(facts, contains(factId), reason: definition.id),
        narrativeEventConsumed: (_, __) {},
      );
    }
    definition.source.when(
      entityInteract: (mapId, entityId) {
        final map = _mapJson(fixture, manifest, mapCache, mapId);
        final ids = (map['entities'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map((entry) => entry['id']);
        expect(ids, contains(entityId), reason: definition.id);
      },
      triggerEnter: (mapId, triggerId) {
        final map = _mapJson(fixture, manifest, mapCache, mapId);
        final ids = (map['triggers'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map((entry) => entry['id']);
        expect(ids, contains(triggerId), reason: definition.id);
      },
      mapEnter: (mapId) {
        _mapJson(fixture, manifest, mapCache, mapId);
      },
      outcomeReceived: (_) {},
    );
  }
}

Map<String, dynamic> _mapJson(
  Directory fixture,
  ProjectManifest manifest,
  Map<String, Map<String, dynamic>> cache,
  String mapId,
) {
  return cache.putIfAbsent(mapId, () {
    final entry =
        manifest.maps.singleWhere((candidate) => candidate.id == mapId);
    return _readJson(File(p.join(fixture.path, entry.relativePath)));
  });
}

void _expectMapNpc(
  Directory fixture,
  String mapId,
  String entityId,
  String characterId,
) {
  final map = _readJson(File(p.join(fixture.path, 'maps', '$mapId.json')));
  final entity = (map['entities'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .singleWhere((entry) => entry['id'] == entityId);
  expect(entity['kind'], 'npc');
  expect((entity['npc'] as Map<String, dynamic>)['characterId'], characterId);
}

Directory _copySelbrumeFixture() {
  final repositoryRoot = _findRepositoryRoot();
  final source = Directory(p.join(repositoryRoot.path, 'selbrume'));
  final parent = Directory.systemTemp.createTempSync('pokemap_selbrume_seed_');
  final target = Directory(p.join(parent.path, 'selbrume'))..createSync();

  File(p.join(source.path, 'project.json'))
      .copySync(p.join(target.path, 'project.json'));
  for (final directoryName in const <String>['maps', 'dialogues']) {
    final sourceDirectory = Directory(p.join(source.path, directoryName));
    final targetDirectory = Directory(p.join(target.path, directoryName))
      ..createSync(recursive: true);
    for (final file in sourceDirectory.listSync().whereType<File>()) {
      file.copySync(p.join(targetDirectory.path, p.basename(file.path)));
    }
  }
  // Force one deterministic divergence even when the checked-in project has
  // already been seeded, so the first pass still proves repair behavior.
  final ending = File(p.join(target.path, 'dialogues', 'ending_port.yarn'));
  if (ending.existsSync()) ending.deleteSync();
  return target;
}

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        File(p.join(current.path, 'MVP Selbrume', 'selbrume.md'))
            .existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      throw StateError('pokemonProject repository root not found.');
    }
    current = current.parent;
  }
}

Map<String, dynamic> _readJson(File file) {
  return (jsonDecode(file.readAsStringSync()) as Map).cast<String, dynamic>();
}
~~~~~~

### `packages/map_editor/test/selbrume_narrative_validator_test.dart`

- Taille : `1893` octets
- SHA-256 : `76e5bd0bf41295a8c3e631006ae7358096d035324426b1560da34ac6820000ba`

~~~~~~dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/features/narrative/state/narrative_validator_providers.dart';
import 'package:path/path.dart' as p;

void main() {
  test('canonical Selbrume passes the global Narrative Validator gate',
      () async {
    final projectRoot = p.normalize(
      p.join(Directory.current.path, '..', '..', 'selbrume'),
    );
    final session = await NarrativeEventAuthoringSession.prepare(
      p.join(projectRoot, 'project.json'),
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final request = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: projectRoot,
      project: session.manifest,
    );
    final report = await container.read(
      narrativeValidatorReportProvider(request).future,
    );
    final criticalDiagnostics = report.diagnostics
        .where(
          (diagnostic) =>
              diagnostic.severity == NarrativeProjectDiagnosticSeverity.error,
        )
        .toList(growable: false);

    final canonicalEventCount = session.manifest.eventRegistry?.records.length;
    expect(canonicalEventCount, greaterThanOrEqualTo(27));
    expect(report.totalEventCount, canonicalEventCount);
    expect(
      report.mapEventViews
          .where((view) => view.groupKind == NarrativeMapEventsGroupKind.map),
      hasLength(session.manifest.maps.length),
    );
    expect(
      criticalDiagnostics,
      isEmpty,
      reason: criticalDiagnostics
          .map(
            (diagnostic) =>
                '${diagnostic.code} · ${diagnostic.path} · ${diagnostic.message}',
          )
          .join('\n'),
    );
  });
}
~~~~~~

### `packages/map_editor/test/ui/canvas/narrative_studio_destination_test.dart`

- Taille : `3431` octets
- SHA-256 : `f6b0ecfe8992a5cb8a23f875e1292bea96bdb88b6f419a7b1bf7818873a60980`

~~~~~~dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/models/editor_workspace_mode.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_destination.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_route_presentation.dart';

void main() {
  group('Narrative Studio route presentation', () {
    test('maps every narrative workspace to the canonical destination', () {
      const expected = <EditorWorkspaceMode, NarrativeStudioDestination>{
        EditorWorkspaceMode.narrativeOverview:
            NarrativeStudioDestination.overview,
        EditorWorkspaceMode.globalStory: NarrativeStudioDestination.storylines,
        EditorWorkspaceMode.step: NarrativeStudioDestination.storylines,
        EditorWorkspaceMode.scenes: NarrativeStudioDestination.scenes,
        EditorWorkspaceMode.events: NarrativeStudioDestination.events,
        EditorWorkspaceMode.cutscene: NarrativeStudioDestination.cinematics,
        EditorWorkspaceMode.dialogue: NarrativeStudioDestination.dialogues,
        EditorWorkspaceMode.facts: NarrativeStudioDestination.facts,
        EditorWorkspaceMode.worldRules: NarrativeStudioDestination.worldRules,
        EditorWorkspaceMode.narrativeValidator:
            NarrativeStudioDestination.validator,
      };

      for (final entry in expected.entries) {
        expect(
          narrativeStudioRoutePresentationFor(entry.key)?.destination,
          entry.value,
          reason: '${entry.key} must select ${entry.value}',
        );
      }
    });

    test('step remains a child breadcrumb of Storylines', () {
      final storyline = narrativeStudioRoutePresentationFor(
        EditorWorkspaceMode.globalStory,
      );
      final step = narrativeStudioRoutePresentationFor(
        EditorWorkspaceMode.step,
      );

      expect(storyline?.breadcrumbLabels, const ['Storylines']);
      expect(step?.breadcrumbLabels, const ['Storylines', 'Étape']);
      expect(step?.destination, NarrativeStudioDestination.storylines);
    });

    test('uses the canonical French labels for localized destinations', () {
      expect(
        narrativeStudioRoutePresentationFor(EditorWorkspaceMode.scenes)?.label,
        'Scènes',
      );
      expect(
        narrativeStudioRoutePresentationFor(EditorWorkspaceMode.worldRules)
            ?.label,
        'Règles du monde',
      );
    });

    test('maps stays a gateway while Validator is a real destination', () {
      expect(
        NarrativeStudioDestination.values,
        const [
          NarrativeStudioDestination.overview,
          NarrativeStudioDestination.storylines,
          NarrativeStudioDestination.scenes,
          NarrativeStudioDestination.events,
          NarrativeStudioDestination.cinematics,
          NarrativeStudioDestination.dialogues,
          NarrativeStudioDestination.facts,
          NarrativeStudioDestination.worldRules,
          NarrativeStudioDestination.validator,
        ],
      );
      expect(
        narrativeStudioRoutePresentationFor(
          EditorWorkspaceMode.narrativeValidator,
        )?.label,
        'Validateur',
      );
      expect(
        narrativeStudioRoutePresentationFor(EditorWorkspaceMode.map),
        isNull,
      );
      expect(
        narrativeStudioRoutePresentationFor(EditorWorkspaceMode.tileset),
        isNull,
      );
    });
  });
}
~~~~~~

### `packages/map_editor/test/ui/canvas/narrative_validator_route_test.dart`

- Taille : `5738` octets
- SHA-256 : `97c77dd8c4f4f2d360bed06987c0ade0e1024a4f534b903f4bbe207833d4ba37`

~~~~~~dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_scene_focus_provider.dart';
import 'package:map_editor/src/features/narrative/state/narrative_validator_providers.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart';
import 'package:map_editor/src/ui/canvas/narrative_validator_workspace.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  testWidgets(
    'Validator is a real Narrative Studio route and jumps to Fact and Scene sources',
    (tester) async {
      const project = ProjectManifest(
        name: 'Validator route project',
        maps: [],
        tilesets: [],
        surfaceCatalog: ProjectSurfaceCatalog.empty(),
      );
      final report = NarrativeProjectValidationReport(
        diagnostics: const [
          NarrativeProjectDiagnostic(
            code: 'sceneUnreachable',
            severity: NarrativeProjectDiagnosticSeverity.error,
            domain: NarrativeProjectDiagnosticDomain.scene,
            message: 'La Scene de fin est inaccessible.',
            path: 'scenes.scene_ending',
            destination: NarrativeProjectDiagnosticDestination.scene,
            sceneId: 'scene_ending',
          ),
          NarrativeProjectDiagnostic(
            code: 'requiredFactNeverProduced',
            severity: NarrativeProjectDiagnosticSeverity.error,
            domain: NarrativeProjectDiagnosticDomain.fact,
            message: 'Le Fact de passage n’est jamais produit.',
            path: 'facts.fact_passage',
            destination: NarrativeProjectDiagnosticDestination.fact,
            factId: 'fact_passage',
          ),
        ],
        mapEventViews: const [],
      );

      final container = await pumpEditorShellPage(
        tester,
        initialState: const EditorState(
          projectRootPath: '/virtual/validator-project',
          project: project,
          workspaceMode: EditorWorkspaceMode.narrativeValidator,
        ),
        surfaceSize: const Size(1672, 941),
        overrides: [
          narrativeValidatorPokemonCatalogLoaderProvider.overrideWithValue(
            (_) async => NarrativeValidatorPokemonCatalogSnapshot(
              speciesIds: const <String>{},
              moveIds: const <String>{},
            ),
          ),
          narrativeValidatorReportLoaderProvider.overrideWithValue(
            (_, __) async => report,
          ),
        ],
      );

      expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
      expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
      expect(find.byType(NarrativeValidatorWorkspace), findsOneWidget);
      expect(find.text('Narrative Studio  /  Validateur'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('narrative-studio-product-nav-validator'),
        ),
        findsOneWidget,
      );
      expect(find.text('La Scene de fin est inaccessible.'), findsOneWidget);

      await tester.tap(find.text('Ouvrir la source').last);
      await tester.pumpAndSettle();

      expect(
        container.read(editorNotifierProvider).workspaceMode,
        EditorWorkspaceMode.facts,
      );

      await tester.tap(
        find.byKey(
          const ValueKey('narrative-studio-product-nav-validator'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NarrativeValidatorWorkspace), findsOneWidget);

      await tester.tap(find.text('Ouvrir la source').first);
      await tester.pumpAndSettle();

      expect(
        container.read(editorNotifierProvider).workspaceMode,
        EditorWorkspaceMode.scenes,
      );
      expect(
        container.read(narrativeSceneFocusProvider)?.sceneId,
        'scene_ending',
      );
      expect(find.byType(NarrativeValidatorWorkspace), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  test('snapshot identity changes when the in-memory manifest changes', () {
    const first = ProjectManifest(
      name: 'First',
      maps: [],
      tilesets: [],
      surfaceCatalog: ProjectSurfaceCatalog.empty(),
    );
    final second = first.copyWith(name: 'Second');

    final firstRequest = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: '/virtual/project/../project',
      project: first,
    );
    final equivalentRequest = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: '/virtual/project',
      project: first,
    );
    final changedRequest = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: '/virtual/project',
      project: second,
    );
    final activeMapRequest = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: '/virtual/project',
      project: first,
      activeMap: const MapData(
        id: 'map_live',
        name: 'Map live',
        size: GridSize(width: 8, height: 8),
        layers: [],
      ),
    );
    final catalogRequest = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: '/virtual/project',
      project: first,
      pokemonCatalogFingerprint: 'catalog-v2',
    );

    expect(firstRequest, equivalentRequest);
    expect(changedRequest, isNot(firstRequest));
    expect(activeMapRequest, isNot(firstRequest));
    expect(catalogRequest, isNot(firstRequest));
    expect(firstRequest.project, same(first));
  });
}
~~~~~~

### `packages/map_editor/tool/seed_selbrume_canonical_narrative_content.dart`

- Taille : `132163` octets
- SHA-256 : `6924544d9e30a9af4b0c26cc1f90dcc17ead2c1e99f17635821e45a8aec249b4`

~~~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

const canonicalSelbrumeDialogueIds = <String>{
  'dialogue_mael_intro',
  'dialogue_port_alert',
  'dialogue_lysa_port',
  'dialogue_mado',
  'dialogue_soline',
  'dialogue_marais_clues',
  'dialogue_lighthouse',
  'dialogue_ending_port',
  'dialogue_goelise_port',
  'dialogue_yvon_cabin',
  'dialogue_mael_after_mission',
  'dialogue_mael_epilogue',
  'dialogue_lysa_after_loss',
  'dialogue_mado_after_crystals',
  'dialogue_soline_after_passage',
  'dialogue_soline_epilogue',
  'dialogue_fisher_after_return',
  'dialogue_fisher_after_keep',
  'dialogue_fisher_epilogue',
  'dialogue_yvon_after_cabin',
};

const canonicalSelbrumeCinematicIds = <String>{
  'cinematic_port_panic',
  'cinematic_port_reassure',
  'cinematic_rival_smiles',
  'cinematic_rival_teases',
  'cinematic_rival_depart_win',
  'cinematic_rival_depart_loss',
  'cinematic_marais_first_fog',
  'cinematic_crystal_glow',
  'cinematic_passage_revealed',
  'cinematic_lighthouse_arrival',
  'cinematic_lighthouse_light_unstable',
  'cinematic_mist_disperses',
  'cinematic_port_celebration',
  'cinematic_lighthouse_final_beam',
};

const canonicalSelbrumeSceneIds = <String>{
  'scene_mael_intro',
  'scene_port_entry',
  'scene_port_alert',
  'scene_lysa_port',
  'scene_rival_after_win',
  'scene_rival_after_loss',
  'scene_marais_entry',
  'scene_mado_intro',
  'scene_mado_crystals_return',
  'scene_soline_unlock_passage',
  'scene_clue_electric_tracks',
  'scene_clue_lighthouse_mark',
  'scene_crystal_1',
  'scene_crystal_2',
  'scene_crystal_3',
  'scene_goelise_fisher_intro',
  'scene_goelise_nest_choice',
  'scene_goelise_return',
  'scene_goelise_keep_reward',
  'scene_yvon_intro',
  'scene_cabin_key',
  'scene_cabin_journal',
  'scene_lighthouse_arrival',
  'scene_lighthouse_old_note',
  'scene_lighthouse_guardian_1',
  'scene_lighthouse_guardian_2',
  'scene_final_pokemon',
  'scene_mist_disperses',
  'scene_ending_port',
};

const canonicalSelbrumeFactIds = <String>{
  'fact_main_story_started',
  'fact_mael_intro_done',
  'fact_starter_received',
  'fact_player_started_with_existing_pokemon',
  'fact_mael_mission_given',
  'fact_port_alert_seen',
  'fact_port_crowd_panicked',
  'fact_port_crowd_reassured',
  'fact_rival_port_defeated',
  'fact_rival_port_lost_once',
  'fact_lysa_respects_player',
  'fact_lysa_goes_ahead',
  'fact_lysa_tone_confident',
  'fact_lysa_tone_hesitant',
  'fact_lysa_tone_aggressive',
  'fact_marais_unlocked',
  'fact_mado_met',
  'fact_clue_glass_found',
  'fact_clue_electric_tracks_found',
  'fact_clue_lighthouse_mark_found',
  'fact_all_clues_found',
  'fact_passage_dames_unlocked',
  'fact_lighthouse_reached',
  'fact_lighthouse_old_note_read',
  'fact_lighthouse_top_unlocked',
  'fact_lighthouse_pokemon_appeased',
  'fact_mist_source_resolved',
  'fact_ending_seen',
  'fact_main_story_completed',
  'fact_crystals_quest_started',
  'fact_crystal_1_found',
  'fact_crystal_2_found',
  'fact_crystal_3_found',
  'fact_all_crystals_found',
  'fact_crystals_quest_completed',
  'fact_goelise_quest_started',
  'fact_goelise_nest_found',
  'fact_goelise_object_returned',
  'fact_goelise_object_kept',
  'fact_goelise_quest_completed',
  'fact_cabin_quest_started',
  'fact_cabin_key_found',
  'fact_cabin_opened',
  'fact_cabin_journal_read',
  'fact_cabin_quest_completed',
  'fact_lighthouse_guardian_1_defeated',
  'fact_lighthouse_guardian_2_defeated',
};

const _eventMael = 'evt_019abcde-5000-7000-8000-000000000011';
const _eventMaraisEntry = 'evt_019abcde-5000-7000-8000-000000000012';
const _eventMadoIntro = 'evt_019abcde-5000-7000-8000-000000000013';
const _eventClueElectric = 'evt_019abcde-5000-7000-8000-000000000014';
const _eventClueLens = 'evt_019abcde-5000-7000-8000-000000000015';
const _eventSoline = 'evt_019abcde-5000-7000-8000-000000000016';
const _eventCrystal1 = 'evt_019abcde-5000-7000-8000-000000000017';
const _eventCrystal2 = 'evt_019abcde-5000-7000-8000-000000000018';
const _eventCrystal3 = 'evt_019abcde-5000-7000-8000-000000000019';
const _eventFisherIntro = 'evt_019abcde-5000-7000-8000-000000000020';
const _eventFisherReturn = 'evt_019abcde-5000-7000-8000-000000000021';
const _eventNest = 'evt_019abcde-5000-7000-8000-000000000022';
const _eventLighthouseEntry = 'evt_019abcde-5000-7000-8000-000000000023';
const _eventYvon = 'evt_019abcde-5000-7000-8000-000000000024';
const _eventLighthouseNote = 'evt_019abcde-5000-7000-8000-000000000025';
const _eventGuardian1 = 'evt_019abcde-5000-7000-8000-000000000026';
const _eventGuardian2 = 'evt_019abcde-5000-7000-8000-000000000027';
const _eventBoss = 'evt_019abcde-5000-7000-8000-000000000028';
const _eventCabinKey = 'evt_019abcde-5000-7000-8000-000000000029';
const _eventCabinJournal = 'evt_019abcde-5000-7000-8000-000000000030';
const _eventEnding = 'evt_019abcde-5000-7000-8000-000000000031';
const _eventMadoReturn = 'evt_019abcde-5000-7000-8000-000000000032';
const _eventRivalAfterWin = 'evt_019abcde-5000-7000-8000-000000000033';
const _eventRivalAfterLoss = 'evt_019abcde-5000-7000-8000-000000000034';
const _eventFisherKeepReward = 'evt_019abcde-5000-7000-8000-000000000035';
const _eventMistDisperses = 'evt_019abcde-5000-7000-8000-000000000036';

const _prettyJson = JsonEncoder.withIndent('  ');

final class SelbrumeNarrativeSeedResult {
  const SelbrumeNarrativeSeedResult({required this.changedRelativePaths});

  final List<String> changedRelativePaths;
}

Future<void> main(List<String> arguments) async {
  var check = false;
  Directory? projectRoot;
  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    if (argument == '--check') {
      check = true;
    } else if (argument == '--project-root' && index + 1 < arguments.length) {
      projectRoot = Directory(arguments[++index]);
    } else {
      stderr.writeln(
        'Usage: dart run tool/seed_selbrume_canonical_narrative_content.dart '
        '[--project-root PATH] [--check]',
      );
      exitCode = 64;
      return;
    }
  }
  final root =
      projectRoot ?? Directory(p.join(_findRepositoryRoot().path, 'selbrume'));
  final result = await seedSelbrumeCanonicalNarrativeContent(
    root,
    write: !check,
  );
  if (result.changedRelativePaths.isEmpty) {
    stdout.writeln('Selbrume canonical narrative content is up to date.');
    return;
  }
  stdout.writeln(
    '${result.changedRelativePaths.length} fichier(s) à mettre à jour :',
  );
  for (final path in result.changedRelativePaths) {
    stdout.writeln('- $path');
  }
  if (check) exitCode = 1;
}

Future<SelbrumeNarrativeSeedResult> seedSelbrumeCanonicalNarrativeContent(
  Directory projectRoot, {
  bool write = true,
}) async {
  final projectFile = File(p.join(projectRoot.path, 'project.json'));
  if (!projectFile.existsSync()) {
    throw StateError('Missing Selbrume manifest: ${projectFile.path}');
  }
  final project = _readJson(projectFile);

  _seedCharacters(project);
  _upsertProjectEntries(
    project,
    'trainers',
    _canonicalTrainers().map((entry) => entry.toJson()).toList(),
  );
  _upsertProjectEntries(
    project,
    'dialogues',
    _canonicalDialogues().map((entry) => entry.toJson()).toList(),
  );
  _upsertProjectEntries(
    project,
    'cinematics',
    _canonicalCinematics().map((entry) => entry.toJson()).toList(),
  );
  _upsertProjectEntries(
    project,
    'facts',
    _canonicalFacts().map((entry) => entry.toJson()).toList(),
  );
  _upsertProjectEntries(
    project,
    'scenes',
    _canonicalScenes().map((entry) => entry.toJson()).toList(),
  );
  _upsertProjectEntries(
    project,
    'worldRules',
    _canonicalWorldRules().map((entry) => entry.toJson()).toList(),
  );
  _repairSupersededLegacyContent(project);
  _seedNewGameConfig(project);
  _seedEventRegistry(project);
  _seedStorylineLinks(project);
  _seedCapabilityMarkers(project);

  final authoredFiles = <String, String>{
    'project.json': '${_prettyJson.convert(project)}\n',
  };
  for (final entry in _canonicalYarnFiles.entries) {
    authoredFiles[p.join('dialogues', entry.key)] = entry.value;
  }

  final manifest = ProjectManifest.fromJson(project);
  ProjectValidator.validate(manifest);
  for (final mapId in const <String>[
    'map_bourg_selbrume',
    'map_port_brisants',
    'map_marais_salants',
    'map_phare_exterieur',
    'map_phare_interieur',
    'map_bois_chaise_brume',
    'map_passage_dames',
    'map_sommet_phare',
    'map_cabane_gardien',
  ]) {
    final relativePath =
        manifest.maps.singleWhere((entry) => entry.id == mapId).relativePath;
    final mapJson = _readJson(File(p.join(projectRoot.path, relativePath)));
    _seedMap(mapId, mapJson);
    final map = MapData.fromJson(mapJson);
    MapValidator.validate(map, projectDialogueContext: manifest);
    authoredFiles[relativePath] = '${_prettyJson.convert(mapJson)}\n';
  }

  final changed = <String>[];
  for (final entry in authoredFiles.entries) {
    final file = File(p.join(projectRoot.path, entry.key));
    final before = file.existsSync() ? file.readAsStringSync() : null;
    if (before == entry.value) continue;
    changed.add(p.posix.normalize(entry.key.replaceAll('\\', '/')));
    if (write) {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(entry.value, flush: true);
    }
  }
  changed.sort();
  return SelbrumeNarrativeSeedResult(
    changedRelativePaths: List<String>.unmodifiable(changed),
  );
}

void _repairSupersededLegacyContent(Map<String, dynamic> project) {
  for (final rule in _jsonObjects(project['worldRules'])) {
    if (rule['id'] != 'world_rule_lysa_port_resolved') continue;
    final source = _jsonObjectOrEmpty(rule['source']);
    source['sourceId'] = 'fact_rival_port_defeated';
    rule['source'] = source;
    rule['description'] =
        'Compatibilité migrée vers le Fact canonique de victoire contre Lysa.';
  }

  for (final cinematic in _jsonObjects(project['cinematics'])) {
    if (cinematic['id'] != 'cinematic_uwu') continue;
    final timeline = _jsonObjectOrEmpty(cinematic['timeline']);
    for (final step in _jsonObjects(timeline['steps'])) {
      if (step['id'] != 'step_actor_move_2') continue;
      final metadata = _jsonObjectOrEmpty(step['metadata']);
      if (metadata['actor.pathMode'] == 'manual') {
        metadata['actor.pathMode'] = 'direct';
      }
      step['metadata'] = metadata;
    }
    cinematic['timeline'] = timeline;
  }
}

void _seedCharacters(Map<String, dynamic> project) {
  final characters = _jsonObjects(project['characters']);
  Map<String, dynamic> cloneCharacter(
    String sourceId,
    String id,
    String name,
  ) {
    final source = characters.singleWhere((entry) => entry['id'] == sourceId);
    final copy = _deepCopy(source);
    copy['id'] = id;
    copy['name'] = name;
    copy['tags'] = <String>['selbrume', 'canonical-narrative'];
    return copy;
  }

  final mael = cloneCharacter('mael', 'mael', 'Maël');
  final lysa = cloneCharacter('character_lysa', 'character_lysa', 'Lysa');
  _upsertProjectEntries(project, 'characters', <Map<String, dynamic>>[
    mael,
    lysa,
    cloneCharacter('mael', 'character_mado', 'Mado'),
    cloneCharacter('rival', 'character_soline', 'Soline'),
    cloneCharacter('grant', 'character_yvon', 'Yvon'),
    cloneCharacter('rival', 'character_pecheur', 'Pêcheur de Selbrume'),
  ]);
}

List<ProjectTrainerEntry> _canonicalTrainers() => <ProjectTrainerEntry>[
      const ProjectTrainerEntry(
        id: 'trainer_lysa_port',
        name: 'Lysa du port',
        trainerClass: 'Rivale',
        battleDifficulty: 5,
        characterId: 'character_lysa',
        team: <ProjectTrainerPokemonEntry>[
          ProjectTrainerPokemonEntry(
            speciesId: 'bulbasaur',
            level: 7,
            moves: <String>['tackle', 'growl'],
          ),
        ],
        tags: <String>['selbrume', 'chapter-1', 'canonical-narrative'],
      ),
      const ProjectTrainerEntry(
        id: 'trainer_phare_gardien_1',
        name: 'Écho électrique du phare',
        trainerClass: 'Écho de la brume',
        battleDifficulty: 4,
        team: <ProjectTrainerPokemonEntry>[
          ProjectTrainerPokemonEntry(
            speciesId: 'magnemite',
            level: 10,
            moves: <String>['tackle', 'supersonic', 'thunder_shock'],
          ),
        ],
        tags: <String>['selbrume', 'chapter-3', 'canonical-narrative'],
      ),
      const ProjectTrainerEntry(
        id: 'trainer_phare_gardien_2',
        name: 'Écho spectral du phare',
        trainerClass: 'Écho de la brume',
        battleDifficulty: 5,
        team: <ProjectTrainerPokemonEntry>[
          ProjectTrainerPokemonEntry(
            speciesId: 'gastly',
            level: 11,
            moves: <String>['lick', 'hypnosis', 'night_shade'],
          ),
        ],
        tags: <String>['selbrume', 'chapter-3', 'canonical-narrative'],
      ),
      const ProjectTrainerEntry(
        id: 'trainer_boss_phare_pokemon',
        name: 'Lanturn affolé du phare',
        trainerClass: 'Pokémon du phare',
        battleDifficulty: 7,
        team: <ProjectTrainerPokemonEntry>[
          ProjectTrainerPokemonEntry(
            speciesId: 'lanturn',
            level: 14,
            moves: <String>[
              'bubble',
              'supersonic',
              'thunder_wave',
              'water_gun',
            ],
          ),
        ],
        tags: <String>[
          'selbrume',
          'chapter-3',
          'boss',
          'static-encounter',
          'canonical-narrative',
        ],
      ),
    ];

List<ProjectDialogueEntry> _canonicalDialogues() =>
    const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'dialogue_mael_intro',
        name: 'Maël — introduction et mission',
        relativePath: 'dialogues/mael_intro.yarn',
        defaultStartNode: 'MaelIntro',
        description:
            'Introduction de Selbrume et choix guidé du compagnon initial.',
        declaredOutcomes: <DialogueDeclaredOutcome>[
          DialogueDeclaredOutcome(
            id: 'starter_bulbasaur',
            label: 'Choisir Bulbizarre',
          ),
          DialogueDeclaredOutcome(
            id: 'starter_charmander',
            label: 'Choisir Salamèche',
          ),
          DialogueDeclaredOutcome(
            id: 'starter_squirtle',
            label: 'Choisir Carapuce',
          ),
        ],
        tags: <String>['selbrume', 'chapter-1', 'canonical-narrative'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_port_alert',
        name: 'Alerte au Port des Brisants',
        relativePath: 'dialogues/port_alert.yarn',
        defaultStartNode: 'PortAlert',
        description: 'La foule découvre la montée anormale de la brume.',
        declaredOutcomes: <DialogueDeclaredOutcome>[
          DialogueDeclaredOutcome(id: 'panic', label: 'Paniquer'),
          DialogueDeclaredOutcome(id: 'reassure', label: 'Rassurer'),
        ],
        tags: <String>['selbrume', 'chapter-1', 'canonical-narrative'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_lysa_port',
        name: 'Lysa au port',
        relativePath: 'dialogues/lysa_port.yarn',
        defaultStartNode: 'LysaPort',
        description: 'Rencontre, provocation et suites du combat contre Lysa.',
        declaredOutcomes: <DialogueDeclaredOutcome>[
          DialogueDeclaredOutcome(id: 'confident', label: 'Assuré'),
          DialogueDeclaredOutcome(id: 'hesitant', label: 'Prudent'),
          DialogueDeclaredOutcome(id: 'aggressive', label: 'Agressif'),
        ],
        tags: <String>['selbrume', 'chapter-1', 'golden-slice'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_mado',
        name: 'Mado des marais',
        relativePath: 'dialogues/mado.yarn',
        defaultStartNode: 'MadoIntro',
        description: 'Enquête et quête des cristaux de sel.',
        declaredOutcomes: <DialogueDeclaredOutcome>[
          DialogueDeclaredOutcome(id: 'accept_help', label: 'Accepter'),
          DialogueDeclaredOutcome(
            id: 'refuse_for_now',
            label: 'Refuser pour le moment',
          ),
        ],
        tags: <String>['selbrume', 'chapter-2', 'side-quest'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_soline',
        name: 'Soline et le Passage des Dames',
        relativePath: 'dialogues/soline.yarn',
        defaultStartNode: 'SolineClues',
        description: 'Validation des indices et ouverture du passage.',
        tags: <String>['selbrume', 'chapter-2', 'canonical-narrative'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_marais_clues',
        name: 'Indices des Marais Salants',
        relativePath: 'dialogues/marais_clues.yarn',
        defaultStartNode: 'ClueGlass',
        description: 'Textes des trois indices de la brume.',
        tags: <String>['selbrume', 'chapter-2', 'exploration'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_lighthouse',
        name: 'Le Vieux Phare d’Écume',
        relativePath: 'dialogues/lighthouse.yarn',
        defaultStartNode: 'LighthouseArrival',
        description: 'Notes du gardien et confrontation finale.',
        tags: <String>['selbrume', 'chapter-3', 'canonical-narrative'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_ending_port',
        name: 'Épilogue au port',
        relativePath: 'dialogues/ending_port.yarn',
        defaultStartNode: 'EndingPort',
        description: 'Conclusion de La brume du phare.',
        tags: <String>['selbrume', 'chapter-4', 'canonical-narrative'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_goelise_port',
        name: 'Le Goélise du port',
        relativePath: 'dialogues/goelise_port.yarn',
        defaultStartNode: 'FisherIntro',
        description: 'Quête du nid et choix moral léger.',
        declaredOutcomes: <DialogueDeclaredOutcome>[
          DialogueDeclaredOutcome(id: 'return_item', label: 'Rendre l’objet'),
          DialogueDeclaredOutcome(id: 'keep_item', label: 'Garder l’objet'),
        ],
        tags: <String>['selbrume', 'side-quest', 'choice-persistence'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_yvon_cabin',
        name: 'Yvon et la cabane du gardien',
        relativePath: 'dialogues/yvon_cabin.yarn',
        defaultStartNode: 'YvonCabin',
        description: 'Clé, cabane et carnet de l’ancien gardien.',
        declaredOutcomes: <DialogueDeclaredOutcome>[
          DialogueDeclaredOutcome(
            id: 'accept_search_key',
            label: 'Chercher la clé',
          ),
          DialogueDeclaredOutcome(
            id: 'ignore_for_now',
            label: 'Revenir plus tard',
          ),
        ],
        tags: <String>['selbrume', 'side-quest', 'lore'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_mael_after_mission',
        name: 'Maël — rappel de mission',
        relativePath: 'dialogues/mael_after_mission.yarn',
        defaultStartNode: 'MaelAfterMission',
        description: 'Rappel guidé après le départ vers le port.',
        tags: <String>['selbrume', 'world-state', 'post-progression'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_mael_epilogue',
        name: 'Maël — épilogue',
        relativePath: 'dialogues/mael_epilogue.yarn',
        defaultStartNode: 'MaelEpilogue',
        description: 'Réaction finale après la dissipation de la brume.',
        tags: <String>['selbrume', 'world-state', 'epilogue'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_lysa_after_loss',
        name: 'Lysa — après la défaite du joueur',
        relativePath: 'dialogues/lysa_after_loss.yarn',
        defaultStartNode: 'RivalAfterLoss',
        description: 'Moquerie douce persistante après la branche défaite.',
        tags: <String>['selbrume', 'world-state', 'post-progression'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_mado_after_crystals',
        name: 'Mado — cristaux retrouvés',
        relativePath: 'dialogues/mado_after_crystals.yarn',
        defaultStartNode: 'MadoCompleted',
        description: 'Réaction persistante après la quête des cristaux.',
        tags: <String>['selbrume', 'world-state', 'side-quest'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_soline_after_passage',
        name: 'Soline — passage ouvert',
        relativePath: 'dialogues/soline_after_passage.yarn',
        defaultStartNode: 'SolineAfterPassage',
        description: 'Rappel du chemin vers le phare.',
        tags: <String>['selbrume', 'world-state', 'post-progression'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_soline_epilogue',
        name: 'Soline — port apaisé',
        relativePath: 'dialogues/soline_epilogue.yarn',
        defaultStartNode: 'SolineEpilogue',
        description: 'Dialogue final après le retour des bateaux.',
        tags: <String>['selbrume', 'world-state', 'epilogue'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_fisher_after_return',
        name: 'Pêcheur — objet rendu',
        relativePath: 'dialogues/fisher_after_return.yarn',
        defaultStartNode: 'FisherAfterReturn',
        description: 'Confiance persistante après avoir rendu l’objet.',
        tags: <String>['selbrume', 'world-state', 'side-quest'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_fisher_after_keep',
        name: 'Pêcheur — objet gardé',
        relativePath: 'dialogues/fisher_after_keep.yarn',
        defaultStartNode: 'FisherAfterKeep',
        description: 'Méfiance persistante après avoir gardé l’objet.',
        tags: <String>['selbrume', 'world-state', 'side-quest'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_fisher_epilogue',
        name: 'Pêcheur — épilogue',
        relativePath: 'dialogues/fisher_epilogue.yarn',
        defaultStartNode: 'FisherEpilogue',
        description: 'Le pêcheur reprend la mer après la fin de la brume.',
        tags: <String>['selbrume', 'world-state', 'epilogue'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_yvon_after_cabin',
        name: 'Yvon — carnet retrouvé',
        relativePath: 'dialogues/yvon_after_cabin.yarn',
        defaultStartNode: 'YvonAfterCabin',
        description: 'Réaction persistante après la lecture du carnet.',
        tags: <String>['selbrume', 'world-state', 'side-quest'],
      ),
    ];

List<CinematicAsset> _canonicalCinematics() {
  const definitions = <(String, String, String, String)>[
    (
      'cinematic_port_panic',
      'Panique sur les quais',
      'map_port_brisants',
      'chapter_1_port'
    ),
    (
      'cinematic_port_reassure',
      'Le port reprend son souffle',
      'map_port_brisants',
      'chapter_1_port'
    ),
    (
      'cinematic_rival_smiles',
      'Lysa sourit',
      'map_port_brisants',
      'chapter_1_port'
    ),
    (
      'cinematic_rival_teases',
      'Lysa provoque le joueur',
      'map_port_brisants',
      'chapter_1_port'
    ),
    (
      'cinematic_rival_depart_win',
      'Lysa part après la victoire',
      'map_port_brisants',
      'chapter_1_port'
    ),
    (
      'cinematic_rival_depart_loss',
      'Lysa ouvre la voie malgré la défaite',
      'map_port_brisants',
      'chapter_1_port'
    ),
    (
      'cinematic_marais_first_fog',
      'Première nappe de brume',
      'map_marais_salants',
      'chapter_2_marais'
    ),
    (
      'cinematic_crystal_glow',
      'Un cristal réagit à la brume',
      'map_marais_salants',
      'chapter_2_marais'
    ),
    (
      'cinematic_passage_revealed',
      'Le Passage des Dames apparaît',
      'map_port_brisants',
      'chapter_2_marais'
    ),
    (
      'cinematic_lighthouse_arrival',
      'Arrivée au Vieux Phare d’Écume',
      'map_phare_exterieur',
      'chapter_3_phare'
    ),
    (
      'cinematic_lighthouse_light_unstable',
      'La lentille vacille',
      'map_phare_interieur',
      'chapter_3_phare'
    ),
    (
      'cinematic_mist_disperses',
      'La brume se disperse',
      'map_sommet_phare',
      'chapter_3_phare'
    ),
    (
      'cinematic_port_celebration',
      'Selbrume célèbre le retour de la lumière',
      'map_port_brisants',
      'chapter_4_epilogue'
    ),
    (
      'cinematic_lighthouse_final_beam',
      'Le phare retrouve son faisceau',
      'map_port_brisants',
      'chapter_4_epilogue'
    ),
  ];
  return <CinematicAsset>[
    for (final definition in definitions)
      CinematicAsset(
        id: definition.$1,
        title: definition.$2,
        description: 'Beat cinématique canonique défini dans selbrume.md.',
        storylineId: 'story_main_brume_phare',
        chapterId: definition.$4,
        mapId: definition.$3,
        tags: const <String>['selbrume', 'canonical-narrative'],
        timeline: _canonicalCinematicTimeline(definition.$1, definition.$2),
        metadata: const <String, String>{
          'contentStatus': 'visual_runtime_v1',
          'source': 'selbrume.md',
        },
      ),
  ];
}

CinematicTimeline _canonicalCinematicTimeline(String id, String label) {
  final dramatic = id.contains('panic') ||
      id.contains('teases') ||
      id.contains('unstable') ||
      id.contains('fog');
  final reveal = id.contains('revealed') ||
      id.contains('disperses') ||
      id.contains('celebration') ||
      id.contains('beam');
  return CinematicTimeline(
    steps: <CinematicTimelineStep>[
      CinematicTimelineStep(
        id: '${id}_fade_out',
        kind: CinematicTimelineStepKind.fade,
        label: 'Transition — $label',
        durationMs: reveal ? 320 : 180,
        metadata: const <String, String>{
          cinematicTimelineFadeModeMetadataKey: 'fadeOut',
          'contentStatus': 'visual_runtime_v1',
        },
      ),
      CinematicTimelineStep(
        id: '${id}_establish',
        kind: dramatic
            ? CinematicTimelineStepKind.shake
            : CinematicTimelineStepKind.camera,
        label: label,
        durationMs: dramatic ? 420 : 360,
        metadata: dramatic
            ? const <String, String>{
                'contentStatus': 'visual_runtime_v1',
              }
            : const <String, String>{
                cinematicTimelineCameraModeMetadataKey: 'hold',
                'contentStatus': 'visual_runtime_v1',
              },
      ),
      CinematicTimelineStep(
        id: '${id}_breath',
        kind: CinematicTimelineStepKind.wait,
        label: 'Respiration visuelle',
        durationMs: reveal ? 420 : 180,
        metadata: const <String, String>{
          'contentStatus': 'visual_runtime_v1',
        },
      ),
      CinematicTimelineStep(
        id: '${id}_fade_in',
        kind: CinematicTimelineStepKind.fade,
        label: 'Retour au jeu — $label',
        durationMs: reveal ? 420 : 240,
        metadata: const <String, String>{
          cinematicTimelineFadeModeMetadataKey: 'fadeIn',
          'contentStatus': 'visual_runtime_v1',
        },
      ),
    ],
  );
}

List<NarrativeFactDefinition> _canonicalFacts() {
  const labels = <String, String>{
    'fact_main_story_started': 'L’histoire principale a commencé',
    'fact_mael_intro_done': 'Maël a présenté Selbrume',
    'fact_starter_received': 'Le starter a été reçu',
    'fact_player_started_with_existing_pokemon':
        'Le joueur arrive avec un Pokémon',
    'fact_mael_mission_given': 'Maël a confié la mission',
    'fact_port_alert_seen': 'L’alerte du port a été vue',
    'fact_port_crowd_panicked': 'La foule du port a paniqué',
    'fact_port_crowd_reassured': 'La foule du port a été rassurée',
    'fact_rival_port_defeated': 'Lysa a été vaincue au port',
    'fact_rival_port_lost_once': 'Le joueur a perdu une fois contre Lysa',
    'fact_lysa_respects_player': 'Lysa respecte le joueur',
    'fact_lysa_goes_ahead': 'Lysa est partie en éclaireuse',
    'fact_lysa_tone_confident': 'Le joueur a répondu à Lysa avec assurance',
    'fact_lysa_tone_hesitant': 'Le joueur est resté prudent face à Lysa',
    'fact_lysa_tone_aggressive': 'Le joueur a provoqué Lysa',
    'fact_marais_unlocked': 'Les Marais Salants sont accessibles',
    'fact_mado_met': 'Mado a été rencontrée',
    'fact_clue_glass_found': 'Le verre poli a été trouvé',
    'fact_clue_electric_tracks_found':
        'Les traces électriques ont été trouvées',
    'fact_clue_lighthouse_mark_found': 'Le repère de lentille a été trouvé',
    'fact_all_clues_found': 'Les trois indices ont été réunis',
    'fact_passage_dames_unlocked': 'Le Passage des Dames est ouvert',
    'fact_lighthouse_reached': 'Le Vieux Phare d’Écume a été atteint',
    'fact_lighthouse_old_note_read': 'L’ancienne note du phare a été lue',
    'fact_lighthouse_top_unlocked': 'Le sommet du phare est accessible',
    'fact_lighthouse_pokemon_appeased': 'Le Pokémon du phare a été apaisé',
    'fact_mist_source_resolved': 'La source de la brume est résolue',
    'fact_ending_seen': 'L’épilogue a été vu',
    'fact_main_story_completed': 'La brume du phare est terminée',
    'fact_crystals_quest_started': 'La quête des cristaux a commencé',
    'fact_crystal_1_found': 'Premier cristal de sel trouvé',
    'fact_crystal_2_found': 'Deuxième cristal de sel trouvé',
    'fact_crystal_3_found': 'Troisième cristal de sel trouvé',
    'fact_all_crystals_found': 'Les trois cristaux de sel sont réunis',
    'fact_crystals_quest_completed': 'La quête des cristaux est terminée',
    'fact_goelise_quest_started': 'La quête du Goélise a commencé',
    'fact_goelise_nest_found': 'Le nid du Goélise a été trouvé',
    'fact_goelise_object_returned': 'L’objet brillant a été rendu',
    'fact_goelise_object_kept': 'L’objet brillant a été gardé',
    'fact_goelise_quest_completed': 'La quête du Goélise est terminée',
    'fact_cabin_quest_started': 'La quête de la cabane a commencé',
    'fact_cabin_key_found': 'La clé de la cabane a été trouvée',
    'fact_cabin_opened': 'La cabane du gardien a été ouverte',
    'fact_cabin_journal_read': 'Le carnet du gardien a été lu',
    'fact_cabin_quest_completed': 'La quête de la cabane est terminée',
    'fact_lighthouse_guardian_1_defeated':
        'Le premier écho du phare est dissipé',
    'fact_lighthouse_guardian_2_defeated':
        'Le second écho du phare est dissipé',
  };
  return <NarrativeFactDefinition>[
    for (final entry in labels.entries)
      NarrativeFactDefinition(
        id: entry.key,
        label: entry.value,
        description: _factDescription(entry.key),
        category: _factCategory(entry.key),
        defaultValue: false,
        tags: const <String>['selbrume', 'canonical-narrative'],
      ),
  ];
}

String _factCategory(String id) {
  if (id.contains('crystal')) return 'Quête — Cristaux de sel';
  if (id.contains('goelise')) return 'Quête — Goélise du port';
  if (id.contains('cabin')) return 'Quête — Cabane du phare';
  if (id.contains('clue')) return 'Histoire — Enquête';
  if (id.contains('lighthouse') || id.contains('mist')) {
    return 'Histoire — Phare';
  }
  return 'Histoire principale';
}

String _factDescription(String id) {
  if (id == 'fact_starter_received') {
    return 'Le compagnon choisi a été remis par une conséquence Scene typée.';
  }
  if (id == 'fact_player_started_with_existing_pokemon') {
    return 'Dérivé automatiquement de la party initiale par le contrat New Game.';
  }
  if (id == 'fact_goelise_object_returned' ||
      id == 'fact_goelise_object_kept') {
    return 'Choix persistant produit par un outcome Yarn typé.';
  }
  return 'État narratif canonique issu de MVP Selbrume/selbrume.md.';
}

List<SceneAsset> _canonicalScenes() => <SceneAsset>[
      _maelNewGameScene(),
      _choiceScene(
        id: 'scene_port_entry',
        name: 'Première entrée au Port des Brisants',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_1_port',
        description:
            'Implémentation exécutable du déclencheur de port existant.',
        dialogue: _dialogueBeat(
          'dialogue_port_alert',
          'PortAlert',
          <String>['character_soline', 'character_pecheur'],
          expectedOutcomes: const <String>['panic', 'reassure'],
        ),
        fallbackOutcomeId: 'panic',
        branches: <String, List<_SceneBeat>>{
          'panic': <_SceneBeat>[
            _cinematicBeat('cinematic_port_panic'),
            _factBeat(
              'fact_port_crowd_panicked',
              'Mémoriser la panique du port',
            ),
          ],
          'reassure': <_SceneBeat>[
            _cinematicBeat('cinematic_port_reassure'),
            _factBeat('fact_port_crowd_reassured', 'Rassurer la foule du port'),
          ],
        },
        commonTail: <_SceneBeat>[
          _factBeat('fact_port_alert_seen', 'Mémoriser l’alerte du port'),
          _stepBeat('step_go_to_port', 'Terminer le trajet vers le port'),
        ],
      ),
      _choiceScene(
        id: 'scene_port_alert',
        name: 'Alerte au port',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_1_port',
        description:
            'Scene canonique consultable ; le déclencheur historique reste lié à scene_port_entry.',
        dialogue: _dialogueBeat(
          'dialogue_port_alert',
          'PortAlert',
          <String>['character_soline', 'character_pecheur'],
          expectedOutcomes: const <String>['panic', 'reassure'],
        ),
        fallbackOutcomeId: 'panic',
        branches: <String, List<_SceneBeat>>{
          'panic': <_SceneBeat>[
            _cinematicBeat('cinematic_port_panic'),
            _factBeat(
              'fact_port_crowd_panicked',
              'Mémoriser la panique du port',
            ),
          ],
          'reassure': <_SceneBeat>[
            _cinematicBeat('cinematic_port_reassure'),
            _factBeat('fact_port_crowd_reassured', 'Rassurer la foule du port'),
          ],
        },
      ),
      _lysaToneBattleScene(),
      _linearScene(
        id: 'scene_rival_after_win',
        name: 'Lysa après la victoire du joueur',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_1_port',
        beats: <_SceneBeat>[
          _cinematicBeat('cinematic_rival_smiles'),
          _dialogueBeat(
            'dialogue_lysa_port',
            'RivalAfterWin',
            <String>['character_lysa'],
          ),
          _factBeat(
              'fact_rival_port_defeated', 'Mémoriser la victoire contre Lysa'),
          _factBeat('fact_lysa_respects_player', 'Gagner le respect de Lysa'),
          _factBeat('fact_lysa_goes_ahead', 'Envoyer Lysa en éclaireuse'),
          _cinematicBeat('cinematic_rival_depart_win'),
          _stepBeat('step_rival_battle', 'Faire converger la branche victoire'),
        ],
      ),
      _linearScene(
        id: 'scene_rival_after_loss',
        name: 'Lysa après la défaite du joueur',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_1_port',
        beats: <_SceneBeat>[
          _cinematicBeat('cinematic_rival_teases'),
          _dialogueBeat(
            'dialogue_lysa_port',
            'RivalAfterLoss',
            <String>['character_lysa'],
          ),
          _factBeat(
              'fact_rival_port_lost_once', 'Mémoriser la défaite contre Lysa'),
          _factBeat('fact_lysa_goes_ahead', 'Envoyer Lysa en éclaireuse'),
          _cinematicBeat('cinematic_rival_depart_loss'),
          _stepBeat('step_rival_battle', 'Faire converger la branche défaite'),
        ],
      ),
      _linearScene(
        id: 'scene_marais_entry',
        name: 'Entrée dans les Marais Salants',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_2_marais',
        beats: <_SceneBeat>[
          _cinematicBeat('cinematic_marais_first_fog'),
          _factBeat('fact_marais_unlocked', 'Déverrouiller les marais'),
          _stepBeat('step_enter_marais', 'Terminer l’entrée dans les marais'),
        ],
      ),
      _choiceScene(
        id: 'scene_mado_intro',
        name: 'Rencontre avec Mado',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_2_marais',
        dialogue: _dialogueBeat(
          'dialogue_mado',
          'MadoIntro',
          <String>['character_mado'],
          expectedOutcomes: const <String>['accept_help', 'refuse_for_now'],
        ),
        fallbackOutcomeId: 'accept_help',
        branches: <String, List<_SceneBeat>>{
          'accept_help': <_SceneBeat>[
            _factBeat('fact_mado_met', 'Mémoriser la rencontre avec Mado'),
            _factBeat(
              'fact_crystals_quest_started',
              'Démarrer la quête des cristaux',
            ),
            _stepBeat(
              'step_crystals_talk_to_mado',
              'Terminer la discussion avec Mado',
            ),
          ],
          'refuse_for_now': <_SceneBeat>[
            _factBeat('fact_mado_met', 'Mémoriser la rencontre avec Mado'),
          ],
        },
      ),
      _linearScene(
        id: 'scene_mado_crystals_return',
        name: 'Rapporter les cristaux à Mado',
        storylineId: 'story_side_salt_crystals',
        chapterId: 'chapter_salt_crystals',
        description: 'Mado remet une Super Potion de manière persistante.',
        beats: <_SceneBeat>[
          _dialogueBeat(
              'dialogue_mado', 'MadoReturn', <String>['character_mado']),
          _giveItemBeat(
            'super-potion',
            1,
            'Recevoir une Super Potion de Mado',
          ),
          _factBeat('fact_all_crystals_found', 'Réunir les trois cristaux'),
          _factBeat('fact_crystals_quest_completed',
              'Terminer la quête des cristaux'),
          _stepBeat('step_crystals_collect_three', 'Terminer la collecte'),
          _stepBeat('step_crystals_return_to_mado', 'Rapporter les cristaux'),
          _stepBeat('step_crystals_completed', 'Clore la quête des cristaux'),
        ],
        metadata: const <String, String>{
          'rewardStatus': 'runtime_scene_consequence_bound',
        },
      ),
      _linearScene(
        id: 'scene_clue_glass',
        name: 'Indice du verre poli',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_2_marais',
        beats: <_SceneBeat>[
          _dialogueBeat('dialogue_marais_clues', 'ClueGlass', const <String>[]),
          _factBeat('fact_clue_glass_found', 'Trouver le verre poli'),
        ],
      ),
      _linearScene(
        id: 'scene_clue_electric_tracks',
        name: 'Indice des traces électriques',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_2_marais',
        beats: <_SceneBeat>[
          _dialogueBeat(
              'dialogue_marais_clues', 'ClueElectric', const <String>[]),
          _factBeat('fact_clue_electric_tracks_found',
              'Trouver les traces électriques'),
        ],
      ),
      _linearScene(
        id: 'scene_clue_lighthouse_mark',
        name: 'Indice du repère de lentille',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_2_marais',
        beats: <_SceneBeat>[
          _dialogueBeat('dialogue_marais_clues', 'ClueLens', const <String>[]),
          _factBeat('fact_clue_lighthouse_mark_found',
              'Trouver le repère de lentille'),
        ],
      ),
      _linearScene(
        id: 'scene_soline_unlock_passage',
        name: 'Soline ouvre le Passage des Dames',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_2_marais',
        beats: <_SceneBeat>[
          _dialogueBeat(
              'dialogue_soline', 'SolineClues', <String>['character_soline']),
          _factBeat('fact_all_clues_found', 'Réunir les trois indices'),
          _factBeat(
              'fact_passage_dames_unlocked', 'Ouvrir le Passage des Dames'),
          _cinematicBeat('cinematic_passage_revealed'),
          _stepBeat(
              'step_find_three_clues', 'Terminer la recherche des indices'),
          _stepBeat('step_report_to_soline', 'Terminer le rapport à Soline'),
        ],
      ),
      _crystalScene(1),
      _crystalScene(2),
      _crystalScene(3),
      _linearScene(
        id: 'scene_goelise_fisher_intro',
        name: 'Le pêcheur demande de l’aide',
        storylineId: 'story_side_goelise_port',
        chapterId: 'chapter_goelise_port',
        beats: <_SceneBeat>[
          _dialogueBeat('dialogue_goelise_port', 'FisherIntro',
              <String>['character_pecheur']),
          _factBeat(
              'fact_goelise_quest_started', 'Démarrer la quête du Goélise'),
          _stepBeat('step_goelise_talk_to_fisher',
              'Terminer la discussion avec le pêcheur'),
        ],
      ),
      _choiceScene(
        id: 'scene_goelise_nest_choice',
        name: 'Le nid du Goélise',
        storylineId: 'story_side_goelise_port',
        chapterId: 'chapter_goelise_port',
        description: 'Le choix Yarn persiste une décision morale distincte.',
        dialogue: _dialogueBeat(
          'dialogue_goelise_port',
          'GoeliseChoice',
          const <String>[],
          expectedOutcomes: const <String>['return_item', 'keep_item'],
        ),
        fallbackOutcomeId: 'return_item',
        branches: <String, List<_SceneBeat>>{
          'return_item': <_SceneBeat>[
            _factBeat(
              'fact_goelise_object_returned',
              'Rendre l’objet brillant',
            ),
          ],
          'keep_item': <_SceneBeat>[
            _factBeat(
              'fact_goelise_object_kept',
              'Garder l’objet brillant',
            ),
          ],
        },
        commonTail: <_SceneBeat>[
          _factBeat('fact_goelise_nest_found', 'Trouver le nid du Goélise'),
          _stepBeat('step_goelise_find_nest', 'Terminer la recherche du nid'),
          _stepBeat('step_goelise_choice', 'Valider le choix du Goélise'),
        ],
      ),
      _linearScene(
        id: 'scene_goelise_return',
        name: 'Rendre l’objet au pêcheur',
        storylineId: 'story_side_goelise_port',
        chapterId: 'chapter_goelise_port',
        beats: <_SceneBeat>[
          _dialogueBeat('dialogue_goelise_port', 'FisherReturn',
              <String>['character_pecheur']),
          _giveMoneyBeat(300, 'Recevoir 300 ₽ des pêcheurs'),
          _factBeat(
              'fact_goelise_quest_completed', 'Terminer la quête du Goélise'),
          _stepBeat('step_goelise_choice', 'Valider le choix du Goélise'),
          _stepBeat('step_goelise_return', 'Retourner voir le pêcheur'),
          _stepBeat('step_goelise_completed', 'Clore la quête du Goélise'),
        ],
      ),
      _linearScene(
        id: 'scene_goelise_keep_reward',
        name: 'Assumer le choix auprès du pêcheur',
        storylineId: 'story_side_goelise_port',
        chapterId: 'chapter_goelise_port',
        beats: <_SceneBeat>[
          _dialogueBeat('dialogue_goelise_port', 'FisherSuspicious',
              <String>['character_pecheur']),
          _giveItemBeat(
            'pearl',
            1,
            'Conserver la perle trouvée dans le nid',
          ),
          _factBeat(
              'fact_goelise_quest_completed', 'Terminer la quête du Goélise'),
          _stepBeat('step_goelise_choice', 'Valider le choix du Goélise'),
          _stepBeat('step_goelise_return', 'Retourner voir le pêcheur'),
          _stepBeat('step_goelise_completed', 'Clore la quête du Goélise'),
        ],
      ),
      _choiceScene(
        id: 'scene_yvon_intro',
        name: 'Yvon parle de la cabane du gardien',
        storylineId: 'story_side_lighthouse_cabin',
        chapterId: 'chapter_lighthouse_cabin',
        description:
            'Yvon laisse le joueur accepter la recherche ou revenir plus tard.',
        dialogue: _dialogueBeat(
          'dialogue_yvon_cabin',
          'YvonCabin',
          <String>['character_yvon'],
          expectedOutcomes: const <String>[
            'accept_search_key',
            'ignore_for_now',
          ],
        ),
        fallbackOutcomeId: 'ignore_for_now',
        branches: <String, List<_SceneBeat>>{
          'accept_search_key': <_SceneBeat>[
            _factBeat(
              'fact_cabin_quest_started',
              'Démarrer la quête de la cabane',
            ),
            _stepBeat(
              'step_cabin_talk_to_yvon',
              'Terminer la discussion avec Yvon',
            ),
          ],
          'ignore_for_now': const <_SceneBeat>[],
        },
      ),
      _linearScene(
        id: 'scene_cabin_key',
        name: 'Trouver la clé de la cabane',
        storylineId: 'story_side_lighthouse_cabin',
        chapterId: 'chapter_lighthouse_cabin',
        beats: <_SceneBeat>[
          _dialogueBeat('dialogue_yvon_cabin', 'CabinKey', const <String>[]),
          _giveItemBeat(
            'basement-key',
            1,
            'Ramasser la clé de la cabane',
          ),
          _factBeat('fact_cabin_key_found', 'Trouver la clé de la cabane'),
          _stepBeat('step_cabin_find_key', 'Terminer la recherche de la clé'),
        ],
      ),
      _linearScene(
        id: 'scene_cabin_journal',
        name: 'Lire le carnet du gardien',
        storylineId: 'story_side_lighthouse_cabin',
        chapterId: 'chapter_lighthouse_cabin',
        beats: <_SceneBeat>[
          _factBeat('fact_cabin_opened', 'Ouvrir la cabane du gardien'),
          _dialogueBeat(
              'dialogue_yvon_cabin', 'CabinJournal', const <String>[]),
          _giveItemBeat(
            'rare-candy',
            1,
            'Trouver le Super Bonbon d’Yvon',
          ),
          _factBeat('fact_cabin_journal_read', 'Lire le carnet du gardien'),
          _factBeat(
              'fact_cabin_quest_completed', 'Terminer la quête de la cabane'),
          _stepBeat('step_cabin_open_door', 'Ouvrir la porte'),
          _stepBeat('step_cabin_read_journal', 'Lire le carnet'),
          _stepBeat('step_cabin_completed', 'Clore la quête de la cabane'),
        ],
      ),
      _linearScene(
        id: 'scene_lighthouse_arrival',
        name: 'Arrivée au Vieux Phare d’Écume',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_3_phare',
        beats: <_SceneBeat>[
          _cinematicBeat('cinematic_lighthouse_arrival'),
          _dialogueBeat(
              'dialogue_lighthouse', 'LighthouseArrival', const <String>[]),
          _factBeat('fact_lighthouse_reached', 'Atteindre le phare'),
          _stepBeat(
              'step_reach_lighthouse', 'Terminer le trajet vers le phare'),
        ],
      ),
      _linearScene(
        id: 'scene_lighthouse_old_note',
        name: 'L’ancienne note du gardien',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_3_phare',
        beats: <_SceneBeat>[
          _dialogueBeat(
              'dialogue_lighthouse', 'LighthouseOldNote', const <String>[]),
          _cinematicBeat('cinematic_lighthouse_light_unstable'),
          _factBeat('fact_lighthouse_old_note_read', 'Lire la note du phare'),
        ],
      ),
      _battleScene(
        id: 'scene_lighthouse_guardian_1',
        name: 'Premier écho du phare',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_3_phare',
        trainerId: 'trainer_phare_gardien_1',
        victoryOutcomeId: 'lighthouse.guardian_1.victory',
        defeatOutcomeId: 'lighthouse.guardian_1.defeat',
        victoryBeats: <_SceneBeat>[
          _factBeat('fact_lighthouse_guardian_1_defeated',
              'Dissiper le premier écho'),
        ],
      ),
      _battleScene(
        id: 'scene_lighthouse_guardian_2',
        name: 'Second écho du phare',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_3_phare',
        trainerId: 'trainer_phare_gardien_2',
        victoryOutcomeId: 'lighthouse.guardian_2.victory',
        defeatOutcomeId: 'lighthouse.guardian_2.defeat',
        victoryBeats: <_SceneBeat>[
          _factBeat(
              'fact_lighthouse_guardian_2_defeated', 'Dissiper le second écho'),
          _factBeat('fact_lighthouse_top_unlocked',
              'Déverrouiller le sommet du phare'),
          _stepBeat('step_climb_lighthouse', 'Terminer l’exploration du phare'),
        ],
      ),
      _battleScene(
        id: 'scene_final_pokemon',
        name: 'Apaiser le Pokémon du phare',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_3_phare',
        trainerId: 'trainer_boss_phare_pokemon',
        battleKind: 'static',
        battleTemplateId: 'battle_lighthouse_pokemon',
        npcEntityId: 'boss_phare_pokemon',
        victoryOutcomeId: 'lighthouse.pokemon.appeased',
        defeatOutcomeId: 'lighthouse.pokemon.defeat',
        openingBeats: <_SceneBeat>[
          _dialogueBeat(
              'dialogue_lighthouse', 'FinalPokemon', const <String>[]),
        ],
        victoryBeats: <_SceneBeat>[
          _factBeat('fact_lighthouse_pokemon_appeased',
              'Apaiser le Pokémon du phare'),
          _factBeat(
              'fact_mist_source_resolved', 'Résoudre la source de la brume'),
          _stepBeat(
              'step_final_confrontation', 'Terminer la confrontation finale'),
        ],
      ),
      _linearScene(
        id: 'scene_mist_disperses',
        name: 'La brume se disperse',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_3_phare',
        beats: <_SceneBeat>[
          _cinematicBeat('cinematic_mist_disperses'),
          _dialogueBeat(
            'dialogue_lighthouse',
            'MistDisperses',
            const <String>['mael'],
          ),
        ],
        endOutcome: SceneOutcome(
          id: 'mist_resolved',
          label: 'La brume est dissipée',
        ),
      ),
      _linearScene(
        id: 'scene_ending_port',
        name: 'Épilogue au Port des Brisants',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_4_epilogue',
        beats: <_SceneBeat>[
          _cinematicBeat('cinematic_port_celebration'),
          _dialogueBeat('dialogue_ending_port', 'EndingPort', <String>[
            'mael',
            'character_lysa',
            'character_soline',
          ]),
          _cinematicBeat('cinematic_lighthouse_final_beam'),
          _factBeat('fact_ending_seen', 'Voir l’épilogue'),
          _factBeat('fact_main_story_completed', 'Terminer La brume du phare'),
          _stepBeat('step_return_to_port', 'Terminer le retour au port'),
          _stepBeat('step_main_story_completed', 'Clore l’histoire principale'),
        ],
      ),
    ];

SceneAsset _crystalScene(int index) => _linearScene(
      id: 'scene_crystal_$index',
      name: 'Cristal de sel $index',
      storylineId: 'story_side_salt_crystals',
      chapterId: 'chapter_salt_crystals',
      beats: <_SceneBeat>[
        _cinematicBeat('cinematic_crystal_glow'),
        _factBeat('fact_crystal_${index}_found', 'Trouver le cristal $index'),
      ],
    );

final class _SceneBeat {
  const _SceneBeat(this.title, this.payload);

  final String title;
  final SceneNodePayload payload;
}

_SceneBeat _dialogueBeat(
  String dialogueId,
  String node,
  List<String> speakers, {
  List<String> expectedOutcomes = const <String>[],
}) =>
    _SceneBeat(
      'Dialogue — $node',
      SceneYarnDialoguePayload(
        dialogueId: dialogueId,
        yarnNodeName: node,
        speakerHints: speakers,
        expectedOutcomes: expectedOutcomes,
      ),
    );

_SceneBeat _cinematicBeat(String cinematicId) => _SceneBeat(
      'Cinématique — $cinematicId',
      SceneCinematicPayload(cinematicId: cinematicId),
    );

_SceneBeat _factBeat(String factId, String label) => _SceneBeat(
      label,
      SceneActionPayload.consequence(
        SceneConsequence.setFact(factId: factId, value: true, label: label),
      ),
    );

_SceneBeat _stepBeat(String stepId, String label) => _SceneBeat(
      label,
      SceneActionPayload.consequence(
        SceneConsequence.completeStoryStep(stepId: stepId, label: label),
      ),
    );

_SceneBeat _giveConfiguredStarterBeat({
  required String starterOptionId,
  required String label,
}) =>
    _SceneBeat(
      label,
      SceneActionPayload.consequence(
        SceneConsequence.giveConfiguredStarter(
          starterOptionId: starterOptionId,
          label: label,
        ),
      ),
    );

_SceneBeat _giveItemBeat(String itemId, int quantity, String label) =>
    _SceneBeat(
      label,
      SceneActionPayload.consequence(
        SceneConsequence.giveItem(
          itemId: itemId,
          quantity: quantity,
          label: label,
        ),
      ),
    );

_SceneBeat _giveMoneyBeat(int amount, String label) => _SceneBeat(
      label,
      SceneActionPayload.consequence(
        SceneConsequence.giveMoney(amount: amount, label: label),
      ),
    );

SceneAsset _maelNewGameScene() {
  final nodes = <SceneNode>[
    SceneNode(id: 'node_start', kind: SceneNodeKind.start, title: 'Début'),
    SceneNode(
      id: 'node_party_condition',
      kind: SceneNodeKind.condition,
      title: 'Le joueur possède déjà un Pokémon ?',
      payload: SceneConditionPayload(
        conditionLabel: 'Équipe présente au démarrage',
        conditionSource: SceneConditionSource(
          sourceKind: SceneConditionSourceKind.fact,
          sourceId: 'fact_player_started_with_existing_pokemon',
          operator: SceneConditionOperator.isTrue,
          label: 'Le joueur arrive avec un Pokémon',
        ),
      ),
    ),
    SceneNode(
      id: 'node_existing_dialogue',
      kind: SceneNodeKind.yarnDialogue,
      title: 'Maël vérifie le compagnon existant',
      payload: SceneYarnDialoguePayload(
        dialogueId: 'dialogue_mael_intro',
        yarnNodeName: 'MaelExistingPokemon',
        speakerHints: const <String>['mael'],
      ),
    ),
    SceneNode(
      id: 'node_starter_dialogue',
      kind: SceneNodeKind.yarnDialogue,
      title: 'Maël propose trois compagnons',
      payload: SceneYarnDialoguePayload(
        dialogueId: 'dialogue_mael_intro',
        yarnNodeName: 'MaelStarterChoice',
        expectedOutcomes: const <String>[
          'starter_bulbasaur',
          'starter_charmander',
          'starter_squirtle',
        ],
        speakerHints: const <String>['mael'],
      ),
    ),
    SceneNode(
      id: 'node_give_bulbasaur',
      kind: SceneNodeKind.action,
      title: 'Recevoir Bulbizarre',
      payload: _giveConfiguredStarterBeat(
        starterOptionId: 'starter_bulbasaur',
        label: 'Maël confie Bulbizarre',
      ).payload,
    ),
    SceneNode(
      id: 'node_give_charmander',
      kind: SceneNodeKind.action,
      title: 'Recevoir Salamèche',
      payload: _giveConfiguredStarterBeat(
        starterOptionId: 'starter_charmander',
        label: 'Maël confie Salamèche',
      ).payload,
    ),
    SceneNode(
      id: 'node_give_squirtle',
      kind: SceneNodeKind.action,
      title: 'Recevoir Carapuce',
      payload: _giveConfiguredStarterBeat(
        starterOptionId: 'starter_squirtle',
        label: 'Maël confie Carapuce',
      ).payload,
    ),
    SceneNode(
      id: 'node_starter_received',
      kind: SceneNodeKind.action,
      title: 'Mémoriser le starter',
      payload: _factBeat(
        'fact_starter_received',
        'Mémoriser le compagnon reçu',
      ).payload,
    ),
    SceneNode(
      id: 'node_main_started',
      kind: SceneNodeKind.action,
      title: 'Démarrer l’histoire principale',
      payload: _factBeat(
        'fact_main_story_started',
        'Démarrer l’histoire principale',
      ).payload,
    ),
    SceneNode(
      id: 'node_intro_done',
      kind: SceneNodeKind.action,
      title: 'Mémoriser la rencontre',
      payload: _factBeat(
        'fact_mael_intro_done',
        'Mémoriser la rencontre avec Maël',
      ).payload,
    ),
    SceneNode(
      id: 'node_mission_given',
      kind: SceneNodeKind.action,
      title: 'Confier la mission',
      payload: _factBeat(
        'fact_mael_mission_given',
        'Confier la mission du phare',
      ).payload,
    ),
    SceneNode(
      id: 'node_intro_step',
      kind: SceneNodeKind.action,
      title: 'Terminer l’introduction',
      payload: _stepBeat(
        'step_intro_selbrume',
        'Terminer l’introduction',
      ).payload,
    ),
    SceneNode(
      id: 'node_mission_step',
      kind: SceneNodeKind.action,
      title: 'Terminer la mission de Maël',
      payload: _stepBeat(
        'step_receive_mission',
        'Terminer la mission de Maël',
      ).payload,
    ),
    SceneNode(id: 'node_end', kind: SceneNodeKind.end, title: 'Fin'),
  ];
  final edges = <SceneEdge>[
    SceneEdge(
      id: 'edge_start_condition',
      fromNodeId: 'node_start',
      fromPortId: 'completed',
      toNodeId: 'node_party_condition',
      kind: SceneEdgeKind.defaultFlow,
    ),
    SceneEdge(
      id: 'edge_condition_existing',
      fromNodeId: 'node_party_condition',
      fromPortId: 'true',
      toNodeId: 'node_existing_dialogue',
      kind: SceneEdgeKind.conditionTrue,
    ),
    SceneEdge(
      id: 'edge_condition_starter',
      fromNodeId: 'node_party_condition',
      fromPortId: 'false',
      toNodeId: 'node_starter_dialogue',
      kind: SceneEdgeKind.conditionFalse,
    ),
    SceneEdge(
      id: 'edge_existing_common',
      fromNodeId: 'node_existing_dialogue',
      fromPortId: 'completed',
      toNodeId: 'node_main_started',
      kind: SceneEdgeKind.defaultFlow,
    ),
    for (final branch in const <(String, String)>[
      ('starter_bulbasaur', 'node_give_bulbasaur'),
      ('starter_charmander', 'node_give_charmander'),
      ('starter_squirtle', 'node_give_squirtle'),
      ('completed', 'node_give_bulbasaur'),
    ])
      SceneEdge(
        id: 'edge_starter_${branch.$1}',
        fromNodeId: 'node_starter_dialogue',
        fromPortId: branch.$1,
        toNodeId: branch.$2,
        kind: branch.$1 == 'completed'
            ? SceneEdgeKind.defaultFlow
            : SceneEdgeKind.dialogueOutcome,
      ),
    for (final nodeId in const <String>[
      'node_give_bulbasaur',
      'node_give_charmander',
      'node_give_squirtle',
    ])
      SceneEdge(
        id: 'edge_${nodeId}_received',
        fromNodeId: nodeId,
        fromPortId: 'completed',
        toNodeId: 'node_starter_received',
        kind: SceneEdgeKind.actionCompleted,
      ),
    SceneEdge(
      id: 'edge_received_common',
      fromNodeId: 'node_starter_received',
      fromPortId: 'completed',
      toNodeId: 'node_main_started',
      kind: SceneEdgeKind.actionCompleted,
    ),
  ];
  _appendLinearEdges(
    edges,
    nodes
        .where((node) => const <String>{
              'node_main_started',
              'node_intro_done',
              'node_mission_given',
              'node_intro_step',
              'node_mission_step',
              'node_end',
            }.contains(node.id))
        .toList(growable: false),
  );
  return SceneAsset(
    id: 'scene_mael_intro',
    name: 'Maël prépare le départ vers le port',
    description:
        'Les configurations party vide et party existante convergent ici.',
    storylineId: 'story_main_brume_phare',
    chapterId: 'chapter_1_port',
    tags: const <String>['selbrume', 'canonical-narrative', 'new-game'],
    graph: SceneGraph(startNodeId: 'node_start', nodes: nodes, edges: edges),
    layout: SceneGraphLayout(
      nodeLayouts: <SceneNodeLayout>[
        SceneNodeLayout(nodeId: 'node_start', x: 24, y: 220),
        SceneNodeLayout(nodeId: 'node_party_condition', x: 304, y: 220),
        SceneNodeLayout(nodeId: 'node_existing_dialogue', x: 584, y: 40),
        SceneNodeLayout(nodeId: 'node_starter_dialogue', x: 584, y: 300),
        SceneNodeLayout(nodeId: 'node_give_bulbasaur', x: 864, y: 220),
        SceneNodeLayout(nodeId: 'node_give_charmander', x: 864, y: 360),
        SceneNodeLayout(nodeId: 'node_give_squirtle', x: 864, y: 500),
        SceneNodeLayout(nodeId: 'node_starter_received', x: 1144, y: 360),
        for (final indexed in const <String>[
          'node_main_started',
          'node_intro_done',
          'node_mission_given',
          'node_intro_step',
          'node_mission_step',
          'node_end',
        ].indexed)
          SceneNodeLayout(
            nodeId: indexed.$2,
            x: (1424 + indexed.$1 * 280).toDouble(),
            y: 220,
          ),
      ],
    ),
    metadata: const <String, String>{
      'source': 'MVP Selbrume/selbrume.md',
      'contentStatus': 'runtime_authored',
      'newGameContract': 'party_empty_or_existing_converges',
    },
  );
}

SceneAsset _linearScene({
  required String id,
  required String name,
  required String storylineId,
  required String chapterId,
  required List<_SceneBeat> beats,
  String? description,
  SceneOutcome? endOutcome,
  Map<String, String> metadata = const <String, String>{},
}) {
  final nodes = <SceneNode>[
    SceneNode(id: 'node_start', kind: SceneNodeKind.start, title: 'Début'),
    for (var index = 0; index < beats.length; index++)
      SceneNode(
        id: 'node_${index + 1}',
        kind: beats[index].payload.kind,
        title: beats[index].title,
        payload: beats[index].payload,
      ),
    SceneNode(
      id: 'node_end',
      kind: SceneNodeKind.end,
      title: 'Fin',
      payload: endOutcome == null
          ? null
          : SceneEndPayload(sceneOutcomeId: endOutcome.id),
    ),
  ];
  final edges = <SceneEdge>[];
  for (var index = 0; index < nodes.length - 1; index++) {
    final from = nodes[index];
    final to = nodes[index + 1];
    final port = _completedPort(from.kind);
    edges.add(
      SceneEdge(
        id: 'edge_${from.id}_${to.id}',
        fromNodeId: from.id,
        fromPortId: port,
        toNodeId: to.id,
        kind: _completedEdgeKind(from.kind),
        label: port,
      ),
    );
  }
  return SceneAsset(
    id: id,
    name: name,
    description: description ?? 'Contenu canonique issu de selbrume.md.',
    storylineId: storylineId,
    chapterId: chapterId,
    tags: const <String>['selbrume', 'canonical-narrative'],
    graph: SceneGraph(startNodeId: 'node_start', nodes: nodes, edges: edges),
    layout: _layout(nodes),
    declaredOutcomes: endOutcome == null
        ? const <SceneOutcome>[]
        : <SceneOutcome>[endOutcome],
    metadata: <String, String>{
      'source': 'MVP Selbrume/selbrume.md',
      'contentStatus': 'runtime_authored',
      ...metadata,
    },
  );
}

SceneAsset _choiceScene({
  required String id,
  required String name,
  required String storylineId,
  required String chapterId,
  required _SceneBeat dialogue,
  required Map<String, List<_SceneBeat>> branches,
  required String fallbackOutcomeId,
  List<_SceneBeat> commonTail = const <_SceneBeat>[],
  String? description,
}) {
  if (!branches.containsKey(fallbackOutcomeId)) {
    throw ArgumentError.value(
      fallbackOutcomeId,
      'fallbackOutcomeId',
      'must identify one of the authored branches',
    );
  }
  final dialoguePayload = dialogue.payload;
  if (dialoguePayload is! SceneYarnDialoguePayload) {
    throw ArgumentError.value(
      dialogue,
      'dialogue',
      'must contain a Yarn dialogue payload',
    );
  }

  final startNode = SceneNode(
    id: 'node_start',
    kind: SceneNodeKind.start,
    title: 'Début',
  );
  final dialogueNode = SceneNode(
    id: 'node_dialogue',
    kind: SceneNodeKind.yarnDialogue,
    title: dialogue.title,
    payload: dialoguePayload,
  );
  final branchNodes = <String, List<SceneNode>>{
    for (final entry in branches.entries)
      entry.key: <SceneNode>[
        for (var index = 0; index < entry.value.length; index++)
          SceneNode(
            id: 'node_${entry.key}_${index + 1}',
            kind: entry.value[index].payload.kind,
            title: entry.value[index].title,
            payload: entry.value[index].payload,
          ),
      ],
  };
  final commonNodes = <SceneNode>[
    for (var index = 0; index < commonTail.length; index++)
      SceneNode(
        id: 'node_common_${index + 1}',
        kind: commonTail[index].payload.kind,
        title: commonTail[index].title,
        payload: commonTail[index].payload,
      ),
  ];
  final endNode = SceneNode(
    id: 'node_end',
    kind: SceneNodeKind.end,
    title: 'Fin',
  );
  final nodes = <SceneNode>[
    startNode,
    dialogueNode,
    ...branchNodes.values.expand((nodes) => nodes),
    ...commonNodes,
    endNode,
  ];
  final commonTarget = commonNodes.isEmpty ? endNode : commonNodes.first;
  final edges = <SceneEdge>[
    SceneEdge(
      id: 'edge_start_dialogue',
      fromNodeId: 'node_start',
      fromPortId: 'completed',
      toNodeId: 'node_dialogue',
      kind: SceneEdgeKind.defaultFlow,
      label: 'completed',
    ),
  ];
  for (final entry in branchNodes.entries) {
    final target = entry.value.isEmpty ? commonTarget : entry.value.first;
    edges.add(
      SceneEdge(
        id: 'edge_dialogue_${entry.key}',
        fromNodeId: dialogueNode.id,
        fromPortId: entry.key,
        toNodeId: target.id,
        kind: SceneEdgeKind.dialogueOutcome,
        label: entry.key,
      ),
    );
    _appendLinearEdges(edges, entry.value);
    if (entry.value.isNotEmpty) {
      final last = entry.value.last;
      edges.add(
        SceneEdge(
          id: 'edge_${last.id}_${commonTarget.id}',
          fromNodeId: last.id,
          fromPortId: _completedPort(last.kind),
          toNodeId: commonTarget.id,
          kind: _completedEdgeKind(last.kind),
          label: _completedPort(last.kind),
        ),
      );
    }
  }
  final fallbackNodes = branchNodes[fallbackOutcomeId]!;
  final fallbackTarget =
      fallbackNodes.isEmpty ? commonTarget : fallbackNodes.first;
  edges.add(
    SceneEdge(
      id: 'edge_dialogue_completed_fallback',
      fromNodeId: dialogueNode.id,
      fromPortId: 'completed',
      toNodeId: fallbackTarget.id,
      kind: SceneEdgeKind.defaultFlow,
      label: 'completed',
    ),
  );
  if (commonNodes.isNotEmpty) {
    _appendLinearEdges(edges, <SceneNode>[...commonNodes, endNode]);
  }

  return SceneAsset(
    id: id,
    name: name,
    description: description ?? 'Choix canonique issu de selbrume.md.',
    storylineId: storylineId,
    chapterId: chapterId,
    tags: const <String>['selbrume', 'canonical-narrative', 'choice'],
    graph: SceneGraph(startNodeId: startNode.id, nodes: nodes, edges: edges),
    layout: _choiceLayout(
      startNode: startNode,
      dialogueNode: dialogueNode,
      branchNodes: branchNodes,
      commonNodes: commonNodes,
      endNode: endNode,
    ),
    metadata: const <String, String>{
      'source': 'MVP Selbrume/selbrume.md',
      'contentStatus': 'runtime_authored',
      'choicePersistenceStatus': 'runtime_yarn_outcomes_bound',
    },
  );
}

SceneAsset _lysaToneBattleScene() {
  final dialoguePayload = SceneYarnDialoguePayload(
    dialogueId: 'dialogue_lysa_port',
    yarnNodeName: 'LysaPort',
    speakerHints: const <String>['character_lysa'],
    expectedOutcomes: const <String>[
      'confident',
      'hesitant',
      'aggressive',
    ],
  );
  final nodes = <SceneNode>[
    SceneNode(
      id: 'node_start',
      kind: SceneNodeKind.start,
      title: 'Début',
    ),
    SceneNode(
      id: 'node_dialogue',
      kind: SceneNodeKind.yarnDialogue,
      title: 'Dialogue avec Lysa',
      payload: dialoguePayload,
    ),
    SceneNode(
      id: 'node_confident_fact',
      kind: SceneNodeKind.action,
      title: 'Réponse assurée',
      payload: _factBeat(
        'fact_lysa_tone_confident',
        'Mémoriser la réponse assurée',
      ).payload,
    ),
    SceneNode(
      id: 'node_confident_cinematic',
      kind: SceneNodeKind.cinematic,
      title: 'Lysa sourit',
      payload: SceneCinematicPayload(cinematicId: 'cinematic_rival_smiles'),
    ),
    SceneNode(
      id: 'node_hesitant_fact',
      kind: SceneNodeKind.action,
      title: 'Réponse prudente',
      payload: _factBeat(
        'fact_lysa_tone_hesitant',
        'Mémoriser la réponse prudente',
      ).payload,
    ),
    SceneNode(
      id: 'node_aggressive_fact',
      kind: SceneNodeKind.action,
      title: 'Provocation',
      payload: _factBeat(
        'fact_lysa_tone_aggressive',
        'Mémoriser la provocation',
      ).payload,
    ),
    SceneNode(
      id: 'node_teases_cinematic',
      kind: SceneNodeKind.cinematic,
      title: 'Lysa réplique',
      payload: SceneCinematicPayload(cinematicId: 'cinematic_rival_teases'),
    ),
    SceneNode(
      id: 'node_battle',
      kind: SceneNodeKind.battle,
      title: 'Combat contre Lysa',
      payload: SceneBattlePayload(
        battleKind: 'trainer',
        trainerId: 'trainer_lysa_port',
        npcEntityId: 'npc_lysa',
        declaredOutcomes: const <String>['victory', 'defeat'],
      ),
    ),
    SceneNode(
      id: 'node_victory_end',
      kind: SceneNodeKind.end,
      title: 'Victoire contre Lysa',
      payload: SceneEndPayload(sceneOutcomeId: 'lysa.victory'),
    ),
    SceneNode(
      id: 'node_defeat_end',
      kind: SceneNodeKind.end,
      title: 'Défaite contre Lysa',
      payload: SceneEndPayload(sceneOutcomeId: 'lysa.defeat'),
    ),
  ];
  final edges = <SceneEdge>[
    SceneEdge(
      id: 'edge_start_dialogue',
      fromNodeId: 'node_start',
      fromPortId: 'completed',
      toNodeId: 'node_dialogue',
      kind: SceneEdgeKind.defaultFlow,
      label: 'completed',
    ),
    for (final entry in const <(String, String)>[
      ('confident', 'node_confident_fact'),
      ('hesitant', 'node_hesitant_fact'),
      ('aggressive', 'node_aggressive_fact'),
    ])
      SceneEdge(
        id: 'edge_dialogue_${entry.$1}',
        fromNodeId: 'node_dialogue',
        fromPortId: entry.$1,
        toNodeId: entry.$2,
        kind: SceneEdgeKind.dialogueOutcome,
        label: entry.$1,
      ),
    SceneEdge(
      id: 'edge_dialogue_completed_fallback',
      fromNodeId: 'node_dialogue',
      fromPortId: 'completed',
      toNodeId: 'node_hesitant_fact',
      kind: SceneEdgeKind.defaultFlow,
      label: 'completed',
    ),
    SceneEdge(
      id: 'edge_confident_fact_cinematic',
      fromNodeId: 'node_confident_fact',
      fromPortId: 'completed',
      toNodeId: 'node_confident_cinematic',
      kind: SceneEdgeKind.actionCompleted,
      label: 'completed',
    ),
    SceneEdge(
      id: 'edge_confident_cinematic_battle',
      fromNodeId: 'node_confident_cinematic',
      fromPortId: 'completed',
      toNodeId: 'node_battle',
      kind: SceneEdgeKind.cinematicCompleted,
      label: 'completed',
    ),
    for (final nodeId in const <String>[
      'node_hesitant_fact',
      'node_aggressive_fact',
    ])
      SceneEdge(
        id: 'edge_${nodeId}_teases',
        fromNodeId: nodeId,
        fromPortId: 'completed',
        toNodeId: 'node_teases_cinematic',
        kind: SceneEdgeKind.actionCompleted,
        label: 'completed',
      ),
    SceneEdge(
      id: 'edge_teases_cinematic_battle',
      fromNodeId: 'node_teases_cinematic',
      fromPortId: 'completed',
      toNodeId: 'node_battle',
      kind: SceneEdgeKind.cinematicCompleted,
      label: 'completed',
    ),
    SceneEdge(
      id: 'edge_battle_victory',
      fromNodeId: 'node_battle',
      fromPortId: 'victory',
      toNodeId: 'node_victory_end',
      kind: SceneEdgeKind.battleVictory,
      label: 'victory',
    ),
    SceneEdge(
      id: 'edge_battle_defeat',
      fromNodeId: 'node_battle',
      fromPortId: 'defeat',
      toNodeId: 'node_defeat_end',
      kind: SceneEdgeKind.battleDefeat,
      label: 'defeat',
    ),
  ];
  return SceneAsset(
    id: 'scene_lysa_port',
    name: 'Rencontre et combat contre Lysa au port',
    description: 'Golden Slice Yarn → Scene → cinématique → combat.',
    storylineId: 'story_main_brume_phare',
    chapterId: 'chapter_1_port',
    tags: const <String>['selbrume', 'golden-slice', 'choice'],
    graph: SceneGraph(startNodeId: 'node_start', nodes: nodes, edges: edges),
    layout: SceneGraphLayout(
      nodeLayouts: <SceneNodeLayout>[
        SceneNodeLayout(nodeId: 'node_start', x: 24, y: 220),
        SceneNodeLayout(nodeId: 'node_dialogue', x: 324, y: 220),
        SceneNodeLayout(nodeId: 'node_confident_fact', x: 624, y: 40),
        SceneNodeLayout(nodeId: 'node_confident_cinematic', x: 924, y: 40),
        SceneNodeLayout(nodeId: 'node_hesitant_fact', x: 624, y: 220),
        SceneNodeLayout(nodeId: 'node_aggressive_fact', x: 624, y: 400),
        SceneNodeLayout(nodeId: 'node_teases_cinematic', x: 924, y: 310),
        SceneNodeLayout(nodeId: 'node_battle', x: 1224, y: 220),
        SceneNodeLayout(nodeId: 'node_victory_end', x: 1524, y: 130),
        SceneNodeLayout(nodeId: 'node_defeat_end', x: 1524, y: 310),
      ],
    ),
    declaredOutcomes: <SceneOutcome>[
      SceneOutcome(id: 'lysa.victory', label: 'Victoire contre Lysa'),
      SceneOutcome(id: 'lysa.defeat', label: 'Défaite contre Lysa'),
    ],
    metadata: const <String, String>{
      'source': 'MVP Selbrume/selbrume.md',
      'contentStatus': 'runtime_authored',
      'choicePersistenceStatus': 'runtime_yarn_outcomes_bound',
    },
  );
}

SceneGraphLayout _choiceLayout({
  required SceneNode startNode,
  required SceneNode dialogueNode,
  required Map<String, List<SceneNode>> branchNodes,
  required List<SceneNode> commonNodes,
  required SceneNode endNode,
}) {
  final maxBranchLength = branchNodes.values.fold<int>(
    0,
    (current, nodes) => nodes.length > current ? nodes.length : current,
  );
  final commonStartX = 624 + maxBranchLength * 280;
  return SceneGraphLayout(
    nodeLayouts: <SceneNodeLayout>[
      SceneNodeLayout(nodeId: startNode.id, x: 24, y: 220),
      SceneNodeLayout(nodeId: dialogueNode.id, x: 324, y: 220),
      for (final indexed in branchNodes.entries.indexed)
        for (final node in indexed.$2.value.indexed)
          SceneNodeLayout(
            nodeId: node.$2.id,
            x: (624 + node.$1 * 280).toDouble(),
            y: (40 + indexed.$1 * 180).toDouble(),
          ),
      for (final node in commonNodes.indexed)
        SceneNodeLayout(
          nodeId: node.$2.id,
          x: (commonStartX + node.$1 * 280).toDouble(),
          y: 220,
        ),
      SceneNodeLayout(
        nodeId: endNode.id,
        x: (commonStartX + commonNodes.length * 280).toDouble(),
        y: 220,
      ),
    ],
  );
}

SceneAsset _battleScene({
  required String id,
  required String name,
  required String storylineId,
  required String chapterId,
  required String trainerId,
  required String victoryOutcomeId,
  required String defeatOutcomeId,
  String battleKind = 'trainer',
  String? battleTemplateId,
  String? npcEntityId,
  List<_SceneBeat> openingBeats = const <_SceneBeat>[],
  List<_SceneBeat> victoryBeats = const <_SceneBeat>[],
}) {
  final nodes = <SceneNode>[
    SceneNode(id: 'node_start', kind: SceneNodeKind.start, title: 'Début'),
  ];
  for (var index = 0; index < openingBeats.length; index++) {
    final beat = openingBeats[index];
    nodes.add(
      SceneNode(
        id: 'node_open_${index + 1}',
        kind: beat.payload.kind,
        title: beat.title,
        payload: beat.payload,
      ),
    );
  }
  nodes.add(
    SceneNode(
      id: 'node_battle',
      kind: SceneNodeKind.battle,
      title: name,
      payload: SceneBattlePayload(
        battleKind: battleKind,
        trainerId: trainerId,
        battleTemplateId: battleTemplateId,
        npcEntityId: npcEntityId,
        declaredOutcomes: const <String>['victory', 'defeat'],
      ),
    ),
  );
  for (var index = 0; index < victoryBeats.length; index++) {
    final beat = victoryBeats[index];
    nodes.add(
      SceneNode(
        id: 'node_victory_${index + 1}',
        kind: beat.payload.kind,
        title: beat.title,
        payload: beat.payload,
      ),
    );
  }
  nodes.addAll(<SceneNode>[
    SceneNode(
      id: 'node_victory_end',
      kind: SceneNodeKind.end,
      title: 'Victoire',
      payload: SceneEndPayload(sceneOutcomeId: victoryOutcomeId),
    ),
    SceneNode(
      id: 'node_defeat_end',
      kind: SceneNodeKind.end,
      title: 'Défaite',
      payload: SceneEndPayload(sceneOutcomeId: defeatOutcomeId),
    ),
  ]);

  final edges = <SceneEdge>[];
  final openingPath = <SceneNode>[
    nodes.first,
    ...nodes.where((node) => node.id.startsWith('node_open_')),
    nodes.singleWhere((node) => node.id == 'node_battle'),
  ];
  _appendLinearEdges(edges, openingPath);
  final victoryPath =
      nodes.where((node) => node.id.startsWith('node_victory_')).toList();
  final firstVictory = victoryPath.first;
  edges.add(
    SceneEdge(
      id: 'edge_battle_victory_${firstVictory.id}',
      fromNodeId: 'node_battle',
      fromPortId: 'victory',
      toNodeId: firstVictory.id,
      kind: SceneEdgeKind.battleVictory,
      label: 'victory',
    ),
  );
  _appendLinearEdges(edges, victoryPath);
  edges.add(
    SceneEdge(
      id: 'edge_battle_defeat',
      fromNodeId: 'node_battle',
      fromPortId: 'defeat',
      toNodeId: 'node_defeat_end',
      kind: SceneEdgeKind.battleDefeat,
      label: 'defeat',
    ),
  );
  return SceneAsset(
    id: id,
    name: name,
    description: 'Combat canonique issu de selbrume.md.',
    storylineId: storylineId,
    chapterId: chapterId,
    tags: const <String>['selbrume', 'canonical-narrative', 'battle'],
    graph: SceneGraph(startNodeId: 'node_start', nodes: nodes, edges: edges),
    layout: _layout(nodes),
    declaredOutcomes: <SceneOutcome>[
      SceneOutcome(id: victoryOutcomeId, label: 'Victoire'),
      SceneOutcome(id: defeatOutcomeId, label: 'Défaite'),
    ],
    metadata: const <String, String>{
      'source': 'MVP Selbrume/selbrume.md',
      'contentStatus': 'runtime_authored',
    },
  );
}

void _appendLinearEdges(List<SceneEdge> edges, List<SceneNode> nodes) {
  for (var index = 0; index < nodes.length - 1; index++) {
    final from = nodes[index];
    final to = nodes[index + 1];
    final port = _completedPort(from.kind);
    edges.add(
      SceneEdge(
        id: 'edge_${from.id}_${to.id}',
        fromNodeId: from.id,
        fromPortId: port,
        toNodeId: to.id,
        kind: _completedEdgeKind(from.kind),
        label: port,
      ),
    );
  }
}

String _completedPort(SceneNodeKind kind) => switch (kind) {
      SceneNodeKind.cinematic => 'completed',
      SceneNodeKind.action => 'completed',
      _ => 'completed',
    };

SceneEdgeKind _completedEdgeKind(SceneNodeKind kind) => switch (kind) {
      SceneNodeKind.cinematic => SceneEdgeKind.cinematicCompleted,
      SceneNodeKind.action => SceneEdgeKind.actionCompleted,
      _ => SceneEdgeKind.defaultFlow,
    };

SceneGraphLayout _layout(List<SceneNode> nodes) => SceneGraphLayout(
      nodeLayouts: <SceneNodeLayout>[
        for (var index = 0; index < nodes.length; index++)
          SceneNodeLayout(
            nodeId: nodes[index].id,
            x: (24 + index * 300).toDouble(),
            y: nodes[index].id == 'node_defeat_end' ? 260 : 80,
          ),
      ],
    );

List<WorldRuleDefinition> _canonicalWorldRules() => <WorldRuleDefinition>[
      _dialogueRule(
        id: 'world_rule_mael_after_mission',
        label: 'Maël suit la progression de l’enquête',
        factId: 'fact_mael_mission_given',
        mapId: 'map_bourg_selbrume',
        entityId: 'npc_mael',
        dialogueId: 'dialogue_mael_after_mission',
        priority: 10,
      ),
      _dialogueRule(
        id: 'world_rule_mael_epilogue',
        label: 'Maël félicite le joueur après l’épilogue',
        factId: 'fact_main_story_completed',
        mapId: 'map_bourg_selbrume',
        entityId: 'npc_mael',
        dialogueId: 'dialogue_mael_epilogue',
        priority: 100,
      ),
      _dialogueRule(
        id: 'world_rule_mado_after_crystals',
        label: 'Mado remercie le joueur après les cristaux',
        factId: 'fact_crystals_quest_completed',
        mapId: 'map_marais_salants',
        entityId: 'npc_mado',
        dialogueId: 'dialogue_mado_after_crystals',
        priority: 10,
      ),
      _dialogueRule(
        id: 'world_rule_soline_after_passage',
        label: 'Soline commente l’ouverture du passage',
        factId: 'fact_passage_dames_unlocked',
        mapId: 'map_port_brisants',
        entityId: 'npc_soline',
        dialogueId: 'dialogue_soline_after_passage',
        priority: 10,
      ),
      _dialogueRule(
        id: 'world_rule_soline_epilogue',
        label: 'Soline commente le retour des bateaux',
        factId: 'fact_main_story_completed',
        mapId: 'map_port_brisants',
        entityId: 'npc_soline',
        dialogueId: 'dialogue_soline_epilogue',
        priority: 100,
      ),
      _dialogueRule(
        id: 'world_rule_fisher_after_return',
        label: 'Le pêcheur fait confiance au joueur',
        factId: 'fact_goelise_object_returned',
        mapId: 'map_port_brisants',
        entityId: 'npc_pecheur',
        dialogueId: 'dialogue_fisher_after_return',
        priority: 20,
      ),
      _dialogueRule(
        id: 'world_rule_fisher_after_keep',
        label: 'Le pêcheur reste méfiant',
        factId: 'fact_goelise_object_kept',
        mapId: 'map_port_brisants',
        entityId: 'npc_pecheur',
        dialogueId: 'dialogue_fisher_after_keep',
        priority: 21,
      ),
      _dialogueRule(
        id: 'world_rule_fisher_epilogue',
        label: 'Le pêcheur reprend la mer après l’épilogue',
        factId: 'fact_main_story_completed',
        mapId: 'map_port_brisants',
        entityId: 'npc_pecheur',
        dialogueId: 'dialogue_fisher_epilogue',
        priority: 100,
      ),
      _dialogueRule(
        id: 'world_rule_yvon_after_cabin',
        label: 'Yvon réagit à la lecture du carnet',
        factId: 'fact_cabin_quest_completed',
        mapId: 'map_phare_exterieur',
        entityId: 'npc_yvon',
        dialogueId: 'dialogue_yvon_after_cabin',
        priority: 10,
      ),
      _dialogueRule(
        id: 'world_rule_lysa_after_loss',
        label: 'Lysa se moque doucement après sa victoire',
        factId: 'fact_rival_port_lost_once',
        mapId: 'map_port_brisants',
        entityId: 'npc_lysa',
        dialogueId: 'dialogue_lysa_after_loss',
        priority: 20,
      ),
      _entityHideFactRule(
        id: 'world_rule_open_bourg_to_port',
        label: 'Ouvrir la route du port après la mission de Maël',
        factId: 'fact_mael_mission_given',
        mapId: 'map_bourg_selbrume',
        entityId: 'gate_bourg_to_port',
      ),
      _entityHideStepRule(
        id: 'world_rule_open_bourg_to_bois',
        label: 'Ouvrir le chemin du bois après Lysa',
        stepId: 'step_rival_battle',
        mapId: 'map_bourg_selbrume',
        entityId: 'gate_bourg_to_bois',
      ),
      _entityHideStepRule(
        id: 'world_rule_open_bois_to_marais',
        label: 'Ouvrir le chemin des marais après Lysa',
        stepId: 'step_rival_battle',
        mapId: 'map_bois_chaise_brume',
        entityId: 'gate_bois_to_marais',
      ),
      _entityHideFactRule(
        id: 'world_rule_open_marais_to_passage',
        label: 'Ouvrir le Passage des Dames',
        factId: 'fact_passage_dames_unlocked',
        mapId: 'map_marais_salants',
        entityId: 'gate_marais_to_passage',
      ),
      _entityHideFactRule(
        id: 'world_rule_open_passage_to_phare',
        label: 'Rendre le phare accessible depuis le passage',
        factId: 'fact_passage_dames_unlocked',
        mapId: 'map_passage_dames',
        entityId: 'gate_passage_to_phare',
      ),
      _entityHideStepRule(
        id: 'world_rule_open_lighthouse_top',
        label: 'Déverrouiller le sommet du phare',
        stepId: 'step_climb_lighthouse',
        mapId: 'map_phare_interieur',
        entityId: 'gate_lighthouse_top',
      ),
      _entityHideFactRule(
        id: 'world_rule_open_cabin_door',
        label: 'Ouvrir la cabane avec la clé',
        factId: 'fact_cabin_key_found',
        mapId: 'map_phare_exterieur',
        entityId: 'gate_cabin_door',
      ),
      _entityHideFactRule(
        id: 'world_rule_open_cabin_shortcut',
        label: 'Ouvrir le raccourci de la cabane',
        factId: 'fact_cabin_journal_read',
        mapId: 'map_cabane_gardien',
        entityId: 'gate_cabin_shortcut',
      ),
      for (final entry in const <(String, String, String, String)>[
        (
          'goelise_nest_proxy',
          'fact_goelise_quest_completed',
          'map_port_brisants',
          'world_rule_hide_goelise_nest'
        ),
        (
          'clue_glass_object',
          'fact_clue_glass_found',
          'map_marais_salants',
          'world_rule_hide_clue_glass'
        ),
        (
          'clue_electric_object',
          'fact_clue_electric_tracks_found',
          'map_marais_salants',
          'world_rule_hide_clue_electric'
        ),
        (
          'clue_lens_object',
          'fact_clue_lighthouse_mark_found',
          'map_marais_salants',
          'world_rule_hide_clue_lens'
        ),
        (
          'crystal_1_object',
          'fact_crystal_1_found',
          'map_marais_salants',
          'world_rule_hide_crystal_1'
        ),
        (
          'crystal_2_object',
          'fact_crystal_2_found',
          'map_marais_salants',
          'world_rule_hide_crystal_2'
        ),
        (
          'crystal_3_object',
          'fact_crystal_3_found',
          'map_marais_salants',
          'world_rule_hide_crystal_3'
        ),
        (
          'cabin_key_object',
          'fact_cabin_key_found',
          'map_phare_exterieur',
          'world_rule_hide_cabin_key'
        ),
        (
          'boss_phare_pokemon',
          'fact_lighthouse_pokemon_appeased',
          'map_sommet_phare',
          'world_rule_hide_lighthouse_boss'
        ),
      ])
        _entityHideFactRule(
          id: entry.$4,
          label: 'Retirer ${entry.$1} après interaction',
          factId: entry.$2,
          mapId: entry.$3,
          entityId: entry.$1,
        ),
      for (final entry in const <(String, String)>[
        ('map_port_brisants', 'fog_port'),
        ('map_marais_salants', 'fog_marais'),
        ('map_passage_dames', 'fog_passage'),
        ('map_phare_exterieur', 'fog_phare'),
        ('map_sommet_phare', 'fog_sommet'),
      ])
        _entityHideFactRule(
          id: 'world_rule_clear_${entry.$2}',
          label: 'Dissiper la brume de ${entry.$1}',
          factId: 'fact_mist_source_resolved',
          mapId: entry.$1,
          entityId: entry.$2,
        ),
    ];

WorldRuleDefinition _dialogueRule({
  required String id,
  required String label,
  required String factId,
  required String mapId,
  required String entityId,
  required String dialogueId,
  int priority = 0,
}) =>
    WorldRuleDefinition(
      id: id,
      label: label,
      description: 'Règle du monde canonique de Selbrume.',
      source: WorldRuleSource(
        kind: WorldRuleSourceKind.fact,
        sourceId: factId,
        predicate: WorldRuleSourcePredicate.isTrue,
      ),
      target: WorldRuleTarget(
        kind: WorldRuleTargetKind.npcDialogue,
        mapId: mapId,
        entityId: entityId,
      ),
      effect: WorldRuleEffect(
        kind: WorldRuleEffectKind.npcDialogueOverride,
        dialogueId: dialogueId,
      ),
      priority: priority,
      tags: const <String>['selbrume', 'canonical-narrative'],
    );

WorldRuleDefinition _entityHideFactRule({
  required String id,
  required String label,
  required String factId,
  required String mapId,
  required String entityId,
}) =>
    WorldRuleDefinition(
      id: id,
      label: label,
      description: 'La progression retire cet élément du monde.',
      source: WorldRuleSource(
        kind: WorldRuleSourceKind.fact,
        sourceId: factId,
        predicate: WorldRuleSourcePredicate.isTrue,
      ),
      target: WorldRuleTarget(
        kind: WorldRuleTargetKind.mapEntity,
        mapId: mapId,
        entityId: entityId,
      ),
      effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
      tags: const <String>['selbrume', 'canonical-narrative', 'world-state'],
    );

WorldRuleDefinition _entityHideStepRule({
  required String id,
  required String label,
  required String stepId,
  required String mapId,
  required String entityId,
}) =>
    WorldRuleDefinition(
      id: id,
      label: label,
      description: 'La complétion de l’étape ouvre ce passage.',
      source: WorldRuleSource(
        kind: WorldRuleSourceKind.storyStepCompletion,
        sourceId: stepId,
        predicate: WorldRuleSourcePredicate.completed,
      ),
      target: WorldRuleTarget(
        kind: WorldRuleTargetKind.mapEntity,
        mapId: mapId,
        entityId: entityId,
      ),
      effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
      tags: const <String>['selbrume', 'canonical-narrative', 'route-lock'],
    );

void _seedEventRegistry(Map<String, dynamic> project) {
  final existing = NarrativeEventRegistry.fromJson(project['eventRegistry']);
  final additions = <NarrativeEventRecord>[
    _event(
      'evt_019abcde-4000-7000-8000-000000000001',
      'Rencontre avec Lysa au port',
      NarrativeEventSourceRef.entityInteract(
        'map_port_brisants',
        'npc_lysa',
      ),
      'scene_lysa_port',
      order: 0,
      conditions: _factsTrue(<String>['fact_port_alert_seen']),
    ),
    _event(
      'evt_019abcde-4000-7000-8000-000000000002',
      'Entrée dans le Port des Brisants',
      NarrativeEventSourceRef.triggerEnter(
        'map_port_brisants',
        'zone_port_entry',
      ),
      'scene_port_entry',
      order: 1,
      conditions: _factsTrue(<String>['fact_mael_mission_given']),
    ),
    _event(
      'evt_019abcde-4000-7000-8000-000000000003',
      'Indice du verre poli',
      NarrativeEventSourceRef.entityInteract(
        'map_marais_salants',
        'clue_glass_object',
      ),
      'scene_clue_glass',
      order: 2,
      conditions: _factsTrue(<String>['fact_mado_met']),
    ),
    _event(
      _eventRivalAfterWin,
      'Suite de la victoire contre Lysa',
      NarrativeEventSourceRef.outcomeReceived(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'scene_lysa_port',
          outcomeId: 'lysa.victory',
        ),
      ),
      'scene_rival_after_win',
      order: 3,
    ),
    _event(
      _eventRivalAfterLoss,
      'Suite de la défaite contre Lysa',
      NarrativeEventSourceRef.outcomeReceived(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'scene_lysa_port',
          outcomeId: 'lysa.defeat',
        ),
      ),
      'scene_rival_after_loss',
      order: 4,
    ),
    _event(
      _eventMael,
      'Parler à Maël au bourg',
      NarrativeEventSourceRef.entityInteract('map_bourg_selbrume', 'npc_mael'),
      'scene_mael_intro',
      order: 10,
      conditions: <NarrativeEventCondition>[
        NarrativeEventCondition.fact('fact_mael_intro_done', false),
      ],
    ),
    _event(
      _eventMaraisEntry,
      'Première entrée dans les Marais Salants',
      NarrativeEventSourceRef.triggerEnter(
          'map_marais_salants', 'zone_marais_entry'),
      'scene_marais_entry',
      order: 11,
    ),
    _event(
      _eventMadoIntro,
      'Rencontrer Mado',
      NarrativeEventSourceRef.entityInteract('map_marais_salants', 'npc_mado'),
      'scene_mado_intro',
      order: 12,
      conditions: <NarrativeEventCondition>[
        NarrativeEventCondition.fact('fact_crystals_quest_started', false),
      ],
      reusePolicy: NarrativeEventReusePolicy.reusable,
    ),
    _event(
      _eventMadoReturn,
      'Rapporter les cristaux à Mado',
      NarrativeEventSourceRef.entityInteract('map_marais_salants', 'npc_mado'),
      'scene_mado_crystals_return',
      order: 13,
      conditions: _factsTrue(<String>[
        'fact_crystal_1_found',
        'fact_crystal_2_found',
        'fact_crystal_3_found',
      ]),
    ),
    _event(
      _eventClueElectric,
      'Découvrir les traces électriques',
      NarrativeEventSourceRef.triggerEnter(
        'map_marais_salants',
        'tr_marais_indice_traces_electriques',
      ),
      'scene_clue_electric_tracks',
      order: 14,
      conditions: _factsTrue(<String>['fact_mado_met']),
    ),
    _event(
      _eventClueLens,
      'Découvrir le repère de lentille',
      NarrativeEventSourceRef.triggerEnter(
        'map_marais_salants',
        'tr_marais_indice_repere_lentille',
      ),
      'scene_clue_lighthouse_mark',
      order: 15,
      conditions: _factsTrue(<String>['fact_mado_met']),
    ),
    _event(
      _eventSoline,
      'Présenter les indices à Soline',
      NarrativeEventSourceRef.entityInteract('map_port_brisants', 'npc_soline'),
      'scene_soline_unlock_passage',
      order: 16,
      conditions: _factsTrue(<String>[
        'fact_clue_glass_found',
        'fact_clue_electric_tracks_found',
        'fact_clue_lighthouse_mark_found',
      ]),
    ),
    _event(
      _eventCrystal1,
      'Ramasser le premier cristal de sel',
      NarrativeEventSourceRef.triggerEnter(
          'map_marais_salants', 'tr_marais_cristal_1'),
      'scene_crystal_1',
      order: 17,
      conditions: _factsTrue(<String>['fact_crystals_quest_started']),
    ),
    _event(
      _eventCrystal2,
      'Ramasser le deuxième cristal de sel',
      NarrativeEventSourceRef.triggerEnter(
          'map_marais_salants', 'tr_marais_cristal_2'),
      'scene_crystal_2',
      order: 18,
      conditions: _factsTrue(<String>['fact_crystals_quest_started']),
    ),
    _event(
      _eventCrystal3,
      'Ramasser le troisième cristal de sel',
      NarrativeEventSourceRef.triggerEnter(
          'map_marais_salants', 'tr_marais_cristal_3'),
      'scene_crystal_3',
      order: 19,
      conditions: _factsTrue(<String>['fact_crystals_quest_started']),
    ),
    _event(
      _eventFisherIntro,
      'Le pêcheur signale le Goélise',
      NarrativeEventSourceRef.entityInteract(
          'map_port_brisants', 'npc_pecheur'),
      'scene_goelise_fisher_intro',
      order: 20,
      conditions: <NarrativeEventCondition>[
        NarrativeEventCondition.fact('fact_lysa_goes_ahead', true),
        NarrativeEventCondition.fact('fact_goelise_quest_started', false),
      ],
    ),
    _event(
      _eventNest,
      'Trouver le nid du Goélise',
      NarrativeEventSourceRef.triggerEnter('map_port_brisants', 'tr_port_nest'),
      'scene_goelise_nest_choice',
      order: 21,
      conditions: _factsTrue(<String>['fact_goelise_quest_started']),
    ),
    _event(
      _eventFisherReturn,
      'Rendre l’objet au pêcheur',
      NarrativeEventSourceRef.entityInteract(
          'map_port_brisants', 'npc_pecheur'),
      'scene_goelise_return',
      order: 22,
      conditions: _factsTrue(<String>['fact_goelise_object_returned']),
    ),
    _event(
      _eventFisherKeepReward,
      'Assumer le choix de garder l’objet',
      NarrativeEventSourceRef.entityInteract(
          'map_port_brisants', 'npc_pecheur'),
      'scene_goelise_keep_reward',
      order: 22,
      conditions: _factsTrue(<String>['fact_goelise_object_kept']),
    ),
    _event(
      _eventLighthouseEntry,
      'Atteindre le Vieux Phare d’Écume',
      NarrativeEventSourceRef.triggerEnter(
        'map_phare_exterieur',
        'zone_lighthouse_entry',
      ),
      'scene_lighthouse_arrival',
      order: 23,
      conditions: _factsTrue(<String>['fact_passage_dames_unlocked']),
    ),
    _event(
      _eventYvon,
      'Parler à Yvon près du phare',
      NarrativeEventSourceRef.entityInteract('map_phare_exterieur', 'npc_yvon'),
      'scene_yvon_intro',
      order: 24,
      conditions: <NarrativeEventCondition>[
        NarrativeEventCondition.fact('fact_cabin_quest_started', false),
      ],
      reusePolicy: NarrativeEventReusePolicy.reusable,
    ),
    _event(
      _eventLighthouseNote,
      'Lire la note du vieux phare',
      NarrativeEventSourceRef.triggerEnter(
          'map_phare_interieur', 'tr_phare_note'),
      'scene_lighthouse_old_note',
      order: 25,
      conditions: _factsTrue(<String>['fact_lighthouse_reached']),
    ),
    _event(
      _eventGuardian1,
      'Affronter le premier écho du phare',
      NarrativeEventSourceRef.triggerEnter(
        'map_phare_interieur',
        'tr_phare_guardian_1',
      ),
      'scene_lighthouse_guardian_1',
      order: 26,
      conditions: _factsTrue(<String>['fact_lighthouse_old_note_read']),
    ),
    _event(
      _eventGuardian2,
      'Affronter le second écho du phare',
      NarrativeEventSourceRef.triggerEnter(
        'map_phare_interieur',
        'tr_phare_guardian_2',
      ),
      'scene_lighthouse_guardian_2',
      order: 27,
      conditions: _factsTrue(<String>[
        'fact_lighthouse_old_note_read',
        'fact_lighthouse_guardian_1_defeated',
      ]),
    ),
    _event(
      _eventBoss,
      'Confrontation au sommet du phare',
      NarrativeEventSourceRef.triggerEnter(
          'map_sommet_phare', 'tr_sommet_confrontation'),
      'scene_final_pokemon',
      order: 28,
      conditions: _factsTrue(<String>[
        'fact_lighthouse_top_unlocked',
        'fact_lighthouse_guardian_2_defeated',
      ]),
    ),
    _event(
      _eventMistDisperses,
      'La brume se disperse après l’apaisement du phare',
      NarrativeEventSourceRef.outcomeReceived(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'scene_final_pokemon',
          outcomeId: 'lighthouse.pokemon.appeased',
        ),
      ),
      'scene_mist_disperses',
      order: 29,
    ),
    _event(
      _eventCabinKey,
      'Trouver la clé de la cabane',
      NarrativeEventSourceRef.triggerEnter(
          'map_phare_exterieur', 'tr_cabin_key_outside'),
      'scene_cabin_key',
      order: 29,
      conditions: _factsTrue(<String>['fact_cabin_quest_started']),
    ),
    _event(
      _eventCabinJournal,
      'Lire le carnet du gardien',
      NarrativeEventSourceRef.triggerEnter(
          'map_cabane_gardien', 'tr_cabane_journal'),
      'scene_cabin_journal',
      order: 30,
      conditions: _factsTrue(<String>['fact_cabin_key_found']),
    ),
    _event(
      _eventEnding,
      'Célébration finale au port',
      NarrativeEventSourceRef.triggerEnter(
          'map_port_brisants', 'zone_port_center'),
      'scene_ending_port',
      order: 31,
      conditions: _factsTrue(<String>['fact_mist_source_resolved']),
    ),
  ];
  final byId = <String, NarrativeEventRecord>{
    for (final record in existing.records) record.id: record,
    for (final record in additions) record.id: record,
  };
  final records = byId.values.toList()
    ..sort((left, right) {
      final leftOrder =
          left.definitionOrNull?.order ?? left.draftOrNull?.order ?? 0;
      final rightOrder =
          right.definitionOrNull?.order ?? right.draftOrNull?.order ?? 0;
      final byOrder = leftOrder.compareTo(rightOrder);
      return byOrder != 0 ? byOrder : left.id.compareTo(right.id);
    });
  project['eventRegistry'] = NarrativeEventRegistry(
    schemaVersion: existing.schemaVersion,
    mode: existing.mode,
    records: records,
    legacyClaims: existing.legacyClaims,
  ).toJson();
}

NarrativeEventRecord _event(
  String id,
  String name,
  NarrativeEventSourceRef source,
  String sceneId, {
  required int order,
  List<NarrativeEventCondition> conditions = const <NarrativeEventCondition>[],
  NarrativeEventReusePolicy reusePolicy = NarrativeEventReusePolicy.oneShot,
}) =>
    NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: id,
        name: name,
        source: source,
        conditions: conditions,
        sceneId: sceneId,
        reusePolicy: reusePolicy,
        priority: 0,
        order: order,
      ),
      enabled: true,
    );

List<NarrativeEventCondition> _factsTrue(List<String> factIds) =>
    <NarrativeEventCondition>[
      for (final factId in factIds) NarrativeEventCondition.fact(factId, true),
    ];

void _seedStorylineLinks(Map<String, dynamic> project) {
  const links = <String, List<String>>{
    'step_intro_selbrume': <String>['scene_mael_intro'],
    'step_receive_mission': <String>['scene_mael_intro'],
    'step_go_to_port': <String>['scene_port_entry', 'scene_port_alert'],
    'step_rival_battle': <String>[
      'scene_lysa_port',
      'scene_rival_after_win',
      'scene_rival_after_loss',
    ],
    'step_enter_marais': <String>['scene_marais_entry', 'scene_mado_intro'],
    'step_find_three_clues': <String>[
      'scene_clue_glass',
      'scene_clue_electric_tracks',
      'scene_clue_lighthouse_mark',
    ],
    'step_report_to_soline': <String>['scene_soline_unlock_passage'],
    'step_reach_lighthouse': <String>['scene_lighthouse_arrival'],
    'step_climb_lighthouse': <String>[
      'scene_lighthouse_old_note',
      'scene_lighthouse_guardian_1',
      'scene_lighthouse_guardian_2',
    ],
    'step_final_confrontation': <String>[
      'scene_final_pokemon',
      'scene_mist_disperses',
    ],
    'step_return_to_port': <String>['scene_ending_port'],
    'step_main_story_completed': <String>['scene_ending_port'],
    'step_crystals_talk_to_mado': <String>['scene_mado_intro'],
    'step_crystals_collect_three': <String>[
      'scene_crystal_1',
      'scene_crystal_2',
      'scene_crystal_3',
    ],
    'step_crystals_return_to_mado': <String>['scene_mado_crystals_return'],
    'step_crystals_completed': <String>['scene_mado_crystals_return'],
    'step_goelise_talk_to_fisher': <String>['scene_goelise_fisher_intro'],
    'step_goelise_find_nest': <String>['scene_goelise_nest_choice'],
    'step_goelise_choice': <String>['scene_goelise_nest_choice'],
    'step_goelise_return': <String>[
      'scene_goelise_return',
      'scene_goelise_keep_reward',
    ],
    'step_goelise_completed': <String>[
      'scene_goelise_return',
      'scene_goelise_keep_reward',
    ],
    'step_cabin_talk_to_yvon': <String>['scene_yvon_intro'],
    'step_cabin_find_key': <String>['scene_cabin_key'],
    'step_cabin_open_door': <String>['scene_cabin_journal'],
    'step_cabin_read_journal': <String>['scene_cabin_journal'],
    'step_cabin_completed': <String>['scene_cabin_journal'],
  };
  final storylines = _jsonObjects(project['storylines']);
  for (final storyline in storylines) {
    storyline['authorNotes'] =
        'Contenu narratif canonique appliqué depuis MVP Selbrume/selbrume.md. '
        'Les limites moteur restantes sont documentées dans globalProperties.';
    final metadata = _jsonObjectOrEmpty(storyline['metadata']);
    metadata['source'] = 'selbrume.md';
    metadata['seedScope'] = 'canonical_narrative_content_v1';
    metadata['seed'] = 'selbrume_canonical_narrative_v1';
    storyline['metadata'] = metadata;
    for (final chapter in _jsonObjects(storyline['chapters'])) {
      for (final step in _jsonObjects(chapter['steps'])) {
        final stepLinks = links[step['id']];
        if (stepLinks == null) continue;
        step['sceneLinkIds'] = <String>{
          ..._stringList(step['sceneLinkIds']),
          ...stepLinks,
        }.toList();
      }
    }
  }
  project['storylines'] = storylines;
}

void _seedCapabilityMarkers(Map<String, dynamic> project) {
  final properties = _jsonObjectOrEmpty(project['globalProperties']);
  properties.addAll(<String, dynamic>{
    'selbrume.canonicalContentVersion': 1,
    'selbrume.canonicalSource': 'MVP Selbrume/selbrume.md',
    'selbrume.activeStarterConfiguration': 'projectDriven',
    'selbrume.starterChoiceStatus': 'runtime_scene_consequence_bound',
    'selbrume.dialogueChoicePersistenceStatus': 'runtime_yarn_outcomes_bound',
    'selbrume.sideQuestRewardStatus': 'runtime_scene_consequences_bound',
    'selbrume.cinematicStatus': 'visual_runtime_v1',
    'selbrume.worldStateStatus': 'runtime_world_rules_v1',
    'selbrume.routeLocksStatus': 'physical_entities_runtime_projected',
    'selbrume.bossBattleStatus': 'static_encounter_runtime_bound',
  });
  project['globalProperties'] = properties;
}

void _seedNewGameConfig(Map<String, dynamic> project) {
  project['newGame'] = const ProjectNewGameConfig(
    enabled: true,
    startMapId: 'map_bourg_selbrume',
    startSpawnId: 'spawn',
    playerName: 'Joueur',
    startingMoney: 500,
    initialBag: <BagEntry>[
      BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
    ],
    initialParty: <PlayerPokemon>[],
    initialFacts: <String, bool>{},
    existingPartyFactId: 'fact_player_started_with_existing_pokemon',
    starterSelectionSceneId: 'scene_mael_intro',
    starterOptions: <ProjectStarterOption>[
      ProjectStarterOption(
        id: 'starter_bulbasaur',
        label: 'Bulbizarre',
        pokemon: PlayerPokemon(
          speciesId: 'bulbasaur',
          natureId: 'hardy',
          abilityId: 'overgrow',
          level: 16,
          currentHp: 40,
          knownMoveIds: <String>['tackle', 'growl', 'vine_whip'],
        ),
      ),
      ProjectStarterOption(
        id: 'starter_charmander',
        label: 'Salamèche',
        pokemon: PlayerPokemon(
          speciesId: 'charmander',
          natureId: 'hardy',
          abilityId: 'blaze',
          level: 16,
          currentHp: 38,
          knownMoveIds: <String>['scratch', 'growl', 'ember', 'mud_slap'],
        ),
      ),
      ProjectStarterOption(
        id: 'starter_squirtle',
        label: 'Carapuce',
        pokemon: PlayerPokemon(
          speciesId: 'squirtle',
          natureId: 'hardy',
          abilityId: 'torrent',
          level: 16,
          currentHp: 40,
          knownMoveIds: <String>[
            'tackle',
            'tail_whip',
            'water_gun',
            'mud_slap',
          ],
        ),
      ),
    ],
  ).toJson();
}

void _seedMap(String mapId, Map<String, dynamic> map) {
  switch (mapId) {
    case 'map_bourg_selbrume':
      final entities = _jsonObjects(map['entities']);
      map['entities'] = _upsertById(entities, <Map<String, dynamic>>[
        _structuralAnchor(
          id: 'npc',
          name: 'Ancre historique du PNJ du bourg',
          x: 34,
          y: 29,
        ),
        _npcEntity(
          id: 'npc_mael',
          name: 'Maël',
          x: 27,
          y: 20,
          characterId: 'mael',
          dialogueId: 'dialogue_mael_intro',
          startNode: 'MaelIntro',
        ),
        _gateEntity(
          id: 'gate_bourg_to_port',
          name: 'Route du Port des Brisants fermée',
          x: 0,
          y: 54,
          width: 55,
          height: 1,
          message: 'Avant de partir au port, va parler à Maël sur la place.',
          visualElementId: 'el_selbrume_passage_barriere_fermee',
        ),
        _gateEntity(
          id: 'gate_bourg_to_bois',
          name: 'Route du Bois de la Chaise fermée',
          x: 54,
          y: 0,
          width: 1,
          height: 55,
          message: 'La brume est trop dense. Lysa doit d’abord ouvrir la voie.',
          visualElementId: 'el_selbrume_bois_ronces',
        ),
      ]);
      break;
    case 'map_port_brisants':
      map['placedElements'] = _jsonObjects(map['placedElements'])
        ..removeWhere((entry) => entry['id'] == 'pe_port_nid_goelise');
      map['entities'] = _upsertById(
        _jsonObjects(map['entities']),
        <Map<String, dynamic>>[
          _npcEntity(
            id: 'npc_soline',
            name: 'Soline',
            x: 39,
            y: 10,
            characterId: 'character_soline',
            dialogueId: 'dialogue_soline',
            startNode: 'SolineClues',
          ),
          _npcEntity(
            id: 'npc_pecheur',
            name: 'Pêcheur inquiet',
            x: 13,
            y: 17,
            characterId: 'character_pecheur',
            dialogueId: 'dialogue_goelise_port',
            startNode: 'FisherIntro',
          ),
          _visualEntity(
            id: 'goelise_nest_proxy',
            name: 'Nid du Goélise déplacé par la brume',
            x: 7,
            y: 9,
            elementId: 'el_port_ref_nest',
          ),
          _visualEntity(
            id: 'fog_port',
            name: 'Banc de brume du port',
            x: 22,
            y: 11,
            elementId: 'el_selbrume_fx_brume_basse',
          ),
        ],
      );
      break;
    case 'map_bois_chaise_brume':
      map['entities'] = _upsertById(
        _jsonObjects(map['entities']),
        <Map<String, dynamic>>[
          _gateEntity(
            id: 'gate_bois_to_marais',
            name: 'Accès aux Marais Salants fermé',
            x: 44,
            y: 0,
            width: 1,
            height: 45,
            message:
                'Les ronces et la brume barrent encore la route des marais.',
            visualElementId: 'el_selbrume_bois_ronces',
          ),
        ],
      );
      break;
    case 'map_marais_salants':
      map['entities'] = _upsertById(
        _jsonObjects(map['entities']),
        <Map<String, dynamic>>[
          _npcEntity(
            id: 'npc_mado',
            name: 'Mado',
            x: 10,
            y: 12,
            characterId: 'character_mado',
            dialogueId: 'dialogue_mado',
            startNode: 'MadoIntro',
          ),
          _gateEntity(
            id: 'gate_marais_to_passage',
            name: 'Passage des Dames fermé',
            x: 0,
            y: 44,
            width: 45,
            height: 1,
            message:
                'Le Passage des Dames reste fermé. Rapporte les trois indices à Soline.',
            visualElementId: 'el_selbrume_passage_barriere_fermee',
          ),
          _visualEntity(
            id: 'clue_glass_object',
            name: 'Indice en verre poli',
            x: 8,
            y: 32,
            elementId: 'el_selbrume_indice_verre',
          ),
          _visualEntity(
            id: 'clue_electric_object',
            name: 'Traces électriques',
            x: 32,
            y: 10,
            elementId: 'el_selbrume_indice_traces_electriques',
          ),
          _visualEntity(
            id: 'clue_lens_object',
            name: 'Repère de l’ancienne lentille',
            x: 34,
            y: 34,
            elementId: 'el_selbrume_indice_repere_lentille',
          ),
          _visualEntity(
            id: 'crystal_1_object',
            name: 'Premier cristal de sel',
            x: 14,
            y: 7,
            elementId: 'el_selbrume_cristal_1',
          ),
          _visualEntity(
            id: 'crystal_2_object',
            name: 'Deuxième cristal de sel',
            x: 24,
            y: 28,
            elementId: 'el_selbrume_cristal_2',
          ),
          _visualEntity(
            id: 'crystal_3_object',
            name: 'Troisième cristal de sel',
            x: 38,
            y: 22,
            elementId: 'el_selbrume_cristal_3',
          ),
          _visualEntity(
            id: 'fog_marais',
            name: 'Brume des Marais Salants',
            x: 20,
            y: 20,
            elementId: 'el_selbrume_fx_brume_basse',
          ),
        ],
      );
      break;
    case 'map_passage_dames':
      map['entities'] = _upsertById(
        _jsonObjects(map['entities']),
        <Map<String, dynamic>>[
          _gateEntity(
            id: 'gate_passage_to_phare',
            name: 'Route du Vieux Phare fermée',
            x: 59,
            y: 0,
            width: 1,
            height: 24,
            message: 'La barrière ne s’ouvrira qu’après l’accord de Soline.',
            visualElementId: 'el_selbrume_passage_barriere_fermee',
          ),
          _visualEntity(
            id: 'fog_passage',
            name: 'Brume du Passage des Dames',
            x: 28,
            y: 8,
            elementId: 'el_selbrume_fx_brume_basse',
          ),
        ],
      );
      break;
    case 'map_phare_exterieur':
      map['entities'] = _upsertById(
        _jsonObjects(map['entities']),
        <Map<String, dynamic>>[
          _npcEntity(
            id: 'npc_yvon',
            name: 'Yvon',
            x: 10,
            y: 12,
            characterId: 'character_yvon',
            dialogueId: 'dialogue_yvon_cabin',
            startNode: 'YvonCabin',
          ),
          _gateEntity(
            id: 'gate_cabin_door',
            name: 'Cabane du gardien verrouillée',
            x: 8,
            y: 33,
            width: 1,
            height: 1,
            message: 'La porte est verrouillée. Yvon a parlé d’une clé.',
          ),
          _visualEntity(
            id: 'cabin_key_object',
            name: 'Clé de la cabane',
            x: 14,
            y: 28,
            elementId: 'el_selbrume_cabane_cle',
          ),
          _visualEntity(
            id: 'fog_phare',
            name: 'Brume autour du vieux phare',
            x: 22,
            y: 22,
            elementId: 'el_selbrume_fx_brume_basse',
          ),
        ],
      );
      map['triggers'] = _upsertById(
        _jsonObjects(map['triggers']),
        <Map<String, dynamic>>[
          _trigger(
            id: 'tr_cabin_key_outside',
            x: 14,
            y: 28,
            eventId: 'event_selbrume_cabin_key_outside',
            width: 1,
            height: 1,
          ),
        ],
      );
      break;
    case 'map_phare_interieur':
      map['entities'] = _upsertById(
        _jsonObjects(map['entities']),
        <Map<String, dynamic>>[
          _gateEntity(
            id: 'gate_lighthouse_top',
            name: 'Escalier du sommet instable',
            x: 18,
            y: 1,
            width: 1,
            height: 1,
            message:
                'Les deux échos du phare doivent être dissipés avant de monter.',
            visualElementId: 'el_selbrume_fx_lumiere_instable',
          ),
        ],
      );
      map['triggers'] = _upsertById(
        _jsonObjects(map['triggers']),
        <Map<String, dynamic>>[
          _trigger(
            id: 'tr_phare_guardian_1',
            x: 7,
            y: 32,
            eventId: 'event_selbrume_phare_guardian_1',
          ),
          _trigger(
            id: 'tr_phare_guardian_2',
            x: 24,
            y: 14,
            eventId: 'event_selbrume_phare_guardian_2',
          ),
        ],
      );
      break;
    case 'map_sommet_phare':
      map['entities'] = _upsertById(
        _jsonObjects(map['entities']),
        <Map<String, dynamic>>[
          _visualEntity(
            id: 'boss_phare_pokemon',
            name: 'Lanturn affolé du phare',
            x: 12,
            y: 10,
            elementId: 'el_selbrume_fx_lumiere_instable',
            blocksMovement: true,
          ),
          _visualEntity(
            id: 'fog_sommet',
            name: 'Brume concentrée au sommet',
            x: 12,
            y: 12,
            elementId: 'el_selbrume_fx_brume_basse',
          ),
        ],
      );
      break;
    case 'map_cabane_gardien':
      map['entities'] = _upsertById(
        _jsonObjects(map['entities']),
        <Map<String, dynamic>>[
          _gateEntity(
            id: 'gate_cabin_shortcut',
            name: 'Raccourci du gardien fermé',
            x: 19,
            y: 8,
            width: 1,
            height: 1,
            message:
                'Le mécanisme est bloqué. Le carnet du gardien doit contenir la solution.',
          ),
        ],
      );
      map['triggers'] = _jsonObjects(map['triggers'])
        ..removeWhere((entry) => entry['id'] == 'tr_cabane_cle');
      break;
  }
}

Map<String, dynamic> _npcEntity({
  required String id,
  required String name,
  required int x,
  required int y,
  required String characterId,
  required String dialogueId,
  required String startNode,
}) =>
    <String, dynamic>{
      'id': id,
      'name': name,
      'kind': 'npc',
      'pos': <String, dynamic>{'x': x, 'y': y},
      'size': <String, dynamic>{'width': 1, 'height': 1},
      'npc': <String, dynamic>{
        'displayName': name,
        'dialogue': <String, dynamic>{
          'dialogueId': dialogueId,
          'scriptPathRelative': '',
          'startNode': startNode,
        },
        'facing': 'south',
        'visualElementId': '',
        'trainerId': null,
        'lineOfSightRange': 0,
        'defeatDialogueRef': null,
        'characterId': characterId,
        'movement': <String, dynamic>{
          'mode': 'idle',
          'waypoints': <dynamic>[],
          'loop': true,
          'pauseDurationMs': 0,
          'stepDurationMs': 200,
        },
        'visibilityRule': null,
        'conditionalDialogues': <dynamic>[],
      },
      'sign': null,
      'item': null,
      'spawn': null,
      'editorVisual': null,
      'blocksMovement': true,
      'properties': <String, String>{
        'contractRole': 'selbrume_canonical_narrative_source',
      },
    };

Map<String, dynamic> _structuralAnchor({
  required String id,
  required String name,
  required int x,
  required int y,
}) =>
    <String, dynamic>{
      'id': id,
      'name': name,
      'kind': 'custom',
      'pos': <String, dynamic>{'x': x, 'y': y},
      'size': <String, dynamic>{'width': 1, 'height': 1},
      'npc': null,
      'sign': null,
      'item': null,
      'spawn': null,
      'editorVisual': null,
      'blocksMovement': false,
      'properties': <String, String>{
        'contractRole': 'canonical_map_generator_compatibility_anchor',
        'inert': 'true',
      },
    };

Map<String, dynamic> _gateEntity({
  required String id,
  required String name,
  required int x,
  required int y,
  required int width,
  required int height,
  required String message,
  String? visualElementId,
}) =>
    <String, dynamic>{
      'id': id,
      'name': name,
      'kind': 'sign',
      'pos': <String, dynamic>{'x': x, 'y': y},
      'size': <String, dynamic>{'width': width, 'height': height},
      'npc': null,
      'sign': <String, dynamic>{
        'title': name,
        'dialogue': null,
        'plainText': message,
      },
      'item': null,
      'spawn': null,
      'editorVisual': visualElementId == null
          ? null
          : <String, dynamic>{
              'elementId': visualElementId,
              'renderInForeground': false,
            },
      'blocksMovement': true,
      'properties': <String, String>{
        'contractRole': 'selbrume_route_lock',
        'unlockProjection': 'world_rule_entity_hidden',
      },
    };

Map<String, dynamic> _visualEntity({
  required String id,
  required String name,
  required int x,
  required int y,
  required String elementId,
  bool blocksMovement = false,
}) =>
    <String, dynamic>{
      'id': id,
      'name': name,
      'kind': 'custom',
      'pos': <String, dynamic>{'x': x, 'y': y},
      'size': <String, dynamic>{'width': 1, 'height': 1},
      'npc': null,
      'sign': null,
      'item': null,
      'spawn': null,
      'editorVisual': <String, dynamic>{
        'elementId': elementId,
        'renderInForeground': false,
      },
      'blocksMovement': blocksMovement,
      'properties': <String, String>{
        'contractRole': 'selbrume_world_state_visual',
      },
    };

Map<String, dynamic> _trigger({
  required String id,
  required int x,
  required int y,
  required String eventId,
  int width = 2,
  int height = 2,
}) =>
    <String, dynamic>{
      'id': id,
      'name': id,
      'type': 'custom',
      'area': <String, dynamic>{
        'pos': <String, dynamic>{'x': x, 'y': y},
        'size': <String, dynamic>{'width': width, 'height': height},
      },
      'properties': <String, String>{
        'eventId': eventId,
        'reservedForNarrative': 'true',
      },
    };

const _canonicalYarnFiles = <String, String>{
  'mael_intro.yarn': '''title: MaelIntro
tags: selbrume chapter-1
---
Maël: Bienvenue à Selbrume. La brume n'a jamais été aussi épaisse.
Maël: Viens me voir avec ton compagnon, ou choisis-en un si tu pars de zéro.
===
title: MaelExistingPokemon
tags: selbrume chapter-1
---
Maël: Ton Pokémon semble déjà te faire confiance. Nous n'avons pas de temps à perdre.
Maël: Rejoins le Port des Brisants et découvre pourquoi le vieux phare s'est tu.
===
title: MaelStarterChoice
tags: selbrume chapter-1 starter
---
Maël: La route sera dangereuse. Lequel de ces trois compagnons veux-tu protéger ?
-> Bulbizarre, calme et tenace
    <<outcome starter_bulbasaur>>
    Maël: Bulbizarre saura sentir les changements dans les marais.
-> Salamèche, vif et courageux
    <<outcome starter_charmander>>
    Maël: Salamèche gardera une lumière près de toi dans la brume.
-> Carapuce, à l'aise avec les embruns
    <<outcome starter_squirtle>>
    Maël: Carapuce connaît déjà le rythme des marées.
Maël: Rejoins maintenant le Port des Brisants. Le vieux phare nous inquiète.
===
''',
  'port_alert.yarn': '''title: PortAlert
tags: selbrume chapter-1
---
Pêcheur: Les barques reviennent toutes seules ! On ne voit plus les balises !
Soline: Le phare envoie des éclats irréguliers. Gardez votre calme et restez sur les quais.
-> Céder à la panique
    <<outcome panic>>
    Joueur: Oh mon Dieu, on va tous mourir !
    <<jump PortPanicked>>
-> Rassurer la foule
    <<outcome reassure>>
    Joueur: Calmez-vous, on va comprendre ce qui se passe.
    <<jump PortReassured>>
===
title: PortPanicked
tags: selbrume chapter-1
---
Soline: Respire. Va voir Lysa avant que la peur ne gagne tous les quais.
===
title: PortReassured
tags: selbrume chapter-1
---
Soline: Va voir Lysa. Elle prétend connaître un passage vers les marais.
===
''',
  'lysa_port.yarn': '''title: LysaPort
tags: selbrume chapter-1 golden-slice
---
Lysa: La brume se lève sur le Port des Brisants.
Lysa: Si tu veux continuer, montre-moi ce que vaut ton équipe.
-> Répondre avec assurance
    <<outcome confident>>
    Joueur: Je ne reculerai pas devant un peu de brume.
-> Rester prudent
    <<outcome hesitant>>
    Joueur: Je préfère comprendre avant de foncer.
-> La provoquer
    <<outcome aggressive>>
    Joueur: Tu parles beaucoup pour quelqu'un qui bloque le passage.
===
title: RivalAfterWin
tags: selbrume chapter-1
---
Lysa: D'accord. Tu peux tenir le rythme. Je pars devant vers les marais.
===
title: RivalAfterLoss
tags: selbrume chapter-1
---
Lysa: Tu manques encore d'expérience, mais la brume n'attendra pas. Suis-moi quand tu seras prêt.
===
''',
  'mado.yarn': '''title: MadoIntro
tags: selbrume chapter-2 side-quest
---
Mado: La brume fait chanter le sel. Écoute bien : trois notes manquent dans les marais.
Mado: Ce sont mes cristaux. Retrouve-les et ils nous diront d'où vient cette énergie.
-> Accepter d'aider
    <<outcome accept_help>>
    Joueur: Je chercherai les trois cristaux.
-> Refuser pour le moment
    <<outcome refuse_for_now>>
    Joueur: Je dois d’abord me préparer. Je reviendrai.
===
title: MadoReturn
tags: selbrume chapter-2 side-quest
---
Mado: Les trois cristaux vibrent ensemble. Ils pointent vers la lentille du vieux phare.
Mado: Prends cette Super Potion. Elle t'aidera quand la brume se resserrera.
===
''',
  'soline.yarn': '''title: SolineClues
tags: selbrume chapter-2
---
Soline: Du verre poli, des traces électriques et la marque de l'ancienne lentille...
Soline: Tu as raison. Le Passage des Dames doit être ouvert, même si la marée se lève.
===
title: SolineAfterPassage
tags: selbrume chapter-2
---
Soline: Le passage est libre. Reviens vivant du phare.
===
''',
  'marais_clues.yarn': '''title: ClueGlass
tags: selbrume chapter-2 clue
---
Narration: Un éclat de verre parfaitement poli est pris dans le sel. Il provient d'une lentille ancienne.
===
title: ClueElectric
tags: selbrume chapter-2 clue
---
Narration: De fines brûlures bleutées serpentent dans la vase. L'énergie file vers le nord.
===
title: ClueLens
tags: selbrume chapter-2 clue
---
Narration: Une marque gravée représente le mécanisme de la lentille du phare.
===
''',
  'lighthouse.yarn': '''title: LighthouseArrival
tags: selbrume chapter-3
---
Narration: Le Vieux Phare d'Écume tremble sous chaque pulsation de lumière.
===
title: LighthouseOldNote
tags: selbrume chapter-3 lore
---
Ancien carnet: La lentille amplifie les émotions des Pokémon sensibles aux courants marins.
Ancien carnet: Si la lumière s'emballe, ne détruisez pas la source. Apaisez-la.
===
title: FinalPokemon
tags: selbrume chapter-3 boss
---
Narration: Un Lanturn affolé protège la lentille. Sa lumière pulse au rythme de la brume.
Joueur: Je ne suis pas venu te chasser. Mais je dois arrêter cette tempête.
===
title: MistDisperses
tags: selbrume chapter-3 resolution
---
Narration: Le faisceau du phare se stabilise et découpe un chemin clair dans la brume.
Maël: Même depuis le bourg, je vois la lumière. Tu as réussi ; Selbrume respire de nouveau.
===
''',
  'ending_port.yarn': '''title: EndingPort
tags: selbrume chapter-4
---
Maël: Regarde le large. Pour la première fois depuis des jours, on distingue l'horizon.
Soline: Les bateaux peuvent repartir et le Passage des Dames est redevenu sûr.
Lysa: Ne prends pas cet air satisfait. La prochaine fois, je gagne.
Narration: Au loin, le phare envoie un faisceau stable au-dessus de Selbrume.
===
''',
  'goelise_port.yarn': '''title: FisherIntro
tags: selbrume side-quest
---
Pêcheur: Un Goélise vole nos repas depuis que la brume a déplacé son nid.
Pêcheur: Trouve-le avant que quelqu'un ne décide de le chasser.
===
title: GoeliseChoice
tags: selbrume side-quest choice
---
Narration: Dans le nid repose un petit objet brillant appartenant aux pêcheurs.
-> Rendre l'objet au pêcheur
    <<outcome return_item>>
    Joueur: Le Goélise a surtout besoin qu'on remette son nid en place.
    <<jump GoeliseReturned>>
-> Garder l'objet
    <<outcome keep_item>>
    Joueur: Cet objet pourrait servir plus tard.
    <<jump GoeliseKept>>
===
title: GoeliseReturned
tags: selbrume side-quest choice
---
Narration: Le joueur décide de rendre l'objet aux pêcheurs.
===
title: GoeliseKept
tags: selbrume side-quest choice
---
Narration: Le joueur garde l'objet et devra assumer la méfiance des pêcheurs.
===
title: FisherReturn
tags: selbrume side-quest
---
Pêcheur: Le Goélise est calmé et son nid tient bon. Merci.
===
title: FisherSuspicious
tags: selbrume side-quest choice
---
Pêcheur: Le nid tient bon, mais l'objet des pêcheurs n'est jamais revenu.
Pêcheur: Garde donc cette perle. La confiance, elle, se regagne autrement.
===
''',
  'yvon_cabin.yarn': '''title: YvonCabin
tags: selbrume side-quest lore
---
Yvon: J'ai gardé ce phare autrefois. Ma vieille cabane contient un carnet sur la lentille.
Yvon: La clé a dû glisser près du mur extérieur. Si tu la retrouves, lis tout.
-> Chercher la clé
    <<outcome accept_search_key>>
    Joueur: Je retrouverai la clé et je lirai le carnet.
-> Revenir plus tard
    <<outcome ignore_for_now>>
    Joueur: Je reviendrai quand je pourrai fouiller les abords du phare.
===
title: CabinKey
tags: selbrume side-quest
---
Narration: Une clé piquée de sel porte l'emblème du vieux phare.
===
title: CabinJournal
tags: selbrume side-quest lore
---
Carnet d'Yvon: La lumière ne commande pas la mer ; elle lui répond.
Carnet d'Yvon: Un Pokémon effrayé peut transformer la lentille en amplificateur de brume.
===
''',
  'mael_after_mission.yarn': '''title: MaelAfterMission
tags: selbrume world-state chapter-1
---
Maël: Le Port des Brisants t’attend. Écoute Soline et ne sous-estime pas Lysa.
===
''',
  'mael_epilogue.yarn': '''title: MaelEpilogue
tags: selbrume world-state epilogue
---
Maël: Tu as rendu son horizon à Selbrume. Ce village se souviendra de ta lumière.
===
''',
  'lysa_after_loss.yarn': '''title: RivalAfterLoss
tags: selbrume world-state chapter-1
---
Lysa: La brume n’attend pas les retardataires. Entraîne-toi et essaie de me suivre.
===
''',
  'mado_after_crystals.yarn': '''title: MadoCompleted
tags: selbrume world-state side-quest
---
Mado: Les cristaux chantent de nouveau. Le phare ne pourra plus nous cacher sa vérité.
===
''',
  'soline_after_passage.yarn': '''title: SolineAfterPassage
tags: selbrume world-state chapter-2
---
Soline: Le Passage des Dames est ouvert. Le vieux phare est droit devant toi.
===
''',
  'soline_epilogue.yarn': '''title: SolineEpilogue
tags: selbrume world-state epilogue
---
Soline: Les bateaux repartent et la marée est lisible. Selbrume respire enfin.
===
''',
  'fisher_after_return.yarn': '''title: FisherAfterReturn
tags: selbrume world-state side-quest
---
Pêcheur: Tu as protégé le Goélise et rendu notre bien. Tu seras toujours bienvenu sur ce quai.
===
''',
  'fisher_after_keep.yarn': '''title: FisherAfterKeep
tags: selbrume world-state side-quest
---
Pêcheur: Le nid est sauf, mais la confiance ne se ramasse pas comme une perle.
===
''',
  'fisher_epilogue.yarn': '''title: FisherEpilogue
tags: selbrume world-state epilogue
---
Pêcheur: La brume est levée. Les filets sont prêts et les barques reprennent enfin la mer.
===
''',
  'yvon_after_cabin.yarn': '''title: YvonAfterCabin
tags: selbrume world-state side-quest lore
---
Yvon: Tu as lu mon carnet. Alors tu sais que la lumière doit répondre à la mer, jamais la dominer.
===
''',
};

void _upsertProjectEntries(
  Map<String, dynamic> project,
  String key,
  List<Map<String, dynamic>> additions,
) {
  project[key] = _upsertById(_jsonObjects(project[key]), additions);
}

List<Map<String, dynamic>> _upsertById(
  List<Map<String, dynamic>> base,
  List<Map<String, dynamic>> additions,
) {
  final additionsById = <String, Map<String, dynamic>>{
    for (final entry in additions) entry['id']! as String: entry,
  };
  final result = <Map<String, dynamic>>[
    for (final entry in base) additionsById.remove(entry['id']) ?? entry,
  ];
  result.addAll(additionsById.values);
  return result;
}

List<Map<String, dynamic>> _jsonObjects(Object? value) =>
    (value as List<dynamic>? ?? const <dynamic>[])
        .map((entry) => (entry as Map).cast<String, dynamic>())
        .toList();

Map<String, dynamic> _jsonObjectOrEmpty(Object? value) =>
    value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

List<String> _stringList(Object? value) =>
    (value as List<dynamic>? ?? const <dynamic>[]).whereType<String>().toList();

Map<String, dynamic> _deepCopy(Map<String, dynamic> value) =>
    (jsonDecode(jsonEncode(value)) as Map).cast<String, dynamic>();

Map<String, dynamic> _readJson(File file) =>
    (jsonDecode(file.readAsStringSync()) as Map).cast<String, dynamic>();

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        File(p.join(current.path, 'MVP Selbrume', 'selbrume.md'))
            .existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      throw StateError('pokemonProject repository root not found.');
    }
    current = current.parent;
  }
}
~~~~~~

### `packages/map_runtime/lib/src/application/scene_runtime/cinematic_runtime_playback_controller.dart`

- Taille : `16247` octets
- SHA-256 : `12fc429ddfc6c195816809d4ecca90b759982be798ffd1a36480674617604d70`

~~~~~~dart
import 'dart:async';

import 'package:map_core/map_core.dart';

import 'scene_cinematic_runtime_awaitable_adapter.dart';
import 'scene_cinematic_runtime_awaitable_result.dart';

enum CinematicRuntimeTermination {
  completed,
  cancelled,
  failed,
}

final class CinematicRuntimeSinkPreflightResult {
  const CinematicRuntimeSinkPreflightResult.ready()
      : errorCode = null,
        message = null;

  const CinematicRuntimeSinkPreflightResult.rejected({
    this.errorCode = SceneCinematicRuntimeAwaitableErrorCode.preflightRejected,
    required this.message,
  });

  final SceneCinematicRuntimeAwaitableErrorCode? errorCode;
  final String? message;

  bool get isReady => errorCode == null;
}

final class CinematicRuntimeStepContext {
  const CinematicRuntimeStepContext({
    required this.asset,
    required this.step,
    required this.stepIndex,
    required this.elapsed,
    required this.delta,
  });

  final CinematicAsset asset;
  final CinematicTimelineStep step;
  final int stepIndex;
  final Duration elapsed;
  final Duration delta;
}

/// Rendering/runtime boundary for the update-driven cinematic controller.
///
/// [preflight] must be read-only. [restore] is deliberately a single atomic
/// hook so a concrete runtime can restore camera, actors and overlays together.
abstract interface class CinematicRuntimePlaybackSink {
  CinematicRuntimeSinkPreflightResult preflight(CinematicAsset asset);

  void beginStep(CinematicRuntimeStepContext context);

  void updateStep(CinematicRuntimeStepContext context);

  bool isStepVisuallyComplete(CinematicRuntimeStepContext context);

  void endStep(CinematicRuntimeStepContext context);

  void restore(CinematicRuntimeTermination termination);
}

/// Sequential, wall-clock-free playback state machine for CinematicAsset V1.
///
/// The controller owns ordering and duration accounting only. A Flame adapter
/// can implement [CinematicRuntimePlaybackSink] in a later lot without moving
/// gameplay or rendering concerns into this application layer.
final class CinematicRuntimePlaybackController
    implements SceneCinematicRuntimePlayer {
  CinematicRuntimePlaybackController({required this.sink});

  final CinematicRuntimePlaybackSink sink;

  _CinematicRuntimeSession? _session;

  bool get isPlaying => _session != null;

  CinematicTimelineStep? get currentStep {
    final session = _session;
    if (session == null || session.stepIndex >= session.steps.length) {
      return null;
    }
    return session.steps[session.stepIndex];
  }

  @override
  Future<SceneCinematicRuntimeAwaitableResult> playCinematic(
    SceneCinematicRuntimeRequest request,
  ) {
    return play(request.asset);
  }

  Future<SceneCinematicRuntimeAwaitableResult> play(CinematicAsset asset) {
    if (_session != null) {
      return Future<SceneCinematicRuntimeAwaitableResult>.value(
        const SceneCinematicRuntimeAwaitableResult.failed(
          errorCode: SceneCinematicRuntimeAwaitableErrorCode.alreadyPlaying,
          message: 'A cinematic is already playing.',
        ),
      );
    }

    final structuralFailure = _preflightAsset(asset);
    if (structuralFailure != null) {
      return Future<SceneCinematicRuntimeAwaitableResult>.value(
        structuralFailure,
      );
    }

    final CinematicRuntimeSinkPreflightResult sinkPreflight;
    try {
      sinkPreflight = sink.preflight(asset);
    } catch (error) {
      return Future<SceneCinematicRuntimeAwaitableResult>.value(
        SceneCinematicRuntimeAwaitableResult.failed(
          errorCode: SceneCinematicRuntimeAwaitableErrorCode.preflightRejected,
          message: 'Cinematic sink preflight failed: $error',
        ),
      );
    }
    if (!sinkPreflight.isReady) {
      return Future<SceneCinematicRuntimeAwaitableResult>.value(
        SceneCinematicRuntimeAwaitableResult.failed(
          errorCode: sinkPreflight.errorCode ??
              SceneCinematicRuntimeAwaitableErrorCode.preflightRejected,
          message:
              sinkPreflight.message ?? 'Cinematic sink rejected preflight.',
        ),
      );
    }

    final session = _CinematicRuntimeSession(asset);
    _session = session;
    _beginCurrentStepOrComplete();
    return session.completer.future;
  }

  void update(Duration delta) {
    if (delta.isNegative) {
      throw ArgumentError.value(delta, 'delta', 'must not be negative');
    }
    var remaining = delta;
    while (_session != null) {
      final session = _session!;
      if (!session.stepBegun) {
        _beginCurrentStepOrComplete();
        if (_session == null || !_session!.stepBegun) return;
      }

      final step = session.steps[session.stepIndex];
      final duration = _positiveDurationOf(step);
      final stepRemaining =
          duration == null ? remaining : duration - session.stepElapsed;
      final applied = duration == null || remaining <= stepRemaining
          ? remaining
          : stepRemaining;
      session.stepElapsed += applied;
      final context = _contextFor(session, delta: applied);

      try {
        sink.updateStep(context);
        final visuallyComplete = sink.isStepVisuallyComplete(context);
        final durationComplete =
            duration != null && session.stepElapsed >= duration;
        if (!visuallyComplete && !durationComplete) return;
        sink.endStep(context);
      } catch (error) {
        _terminate(
          SceneCinematicRuntimeAwaitableResult.failed(
            errorCode: SceneCinematicRuntimeAwaitableErrorCode.sinkFailure,
            message: 'Cinematic sink step failed: $error',
          ),
          CinematicRuntimeTermination.failed,
        );
        return;
      }

      session.stepIndex++;
      session.stepElapsed = Duration.zero;
      session.stepBegun = false;
      if (duration == null) {
        remaining = Duration.zero;
      } else {
        remaining -= applied;
      }
      _beginCurrentStepOrComplete();
      if (remaining == Duration.zero) return;
    }
  }

  bool cancel({String message = 'Cinematic playback was cancelled.'}) {
    if (_session == null) return false;
    _terminate(
      SceneCinematicRuntimeAwaitableResult.failed(
        errorCode: SceneCinematicRuntimeAwaitableErrorCode.cancelled,
        message: message,
      ),
      CinematicRuntimeTermination.cancelled,
    );
    return true;
  }

  void _beginCurrentStepOrComplete() {
    while (_session != null) {
      final session = _session!;
      if (session.stepIndex >= session.steps.length) {
        _terminate(
          const SceneCinematicRuntimeAwaitableResult.completed(),
          CinematicRuntimeTermination.completed,
        );
        return;
      }
      if (session.stepBegun) return;

      final context = _contextFor(session, delta: Duration.zero);
      try {
        sink.beginStep(context);
        session.stepBegun = true;
        final visuallyComplete = sink.isStepVisuallyComplete(context);
        final duration = _positiveDurationOf(context.step);
        if (!visuallyComplete && duration != Duration.zero) return;
        sink.endStep(context);
      } catch (error) {
        _terminate(
          SceneCinematicRuntimeAwaitableResult.failed(
            errorCode: SceneCinematicRuntimeAwaitableErrorCode.sinkFailure,
            message: 'Cinematic sink step failed: $error',
          ),
          CinematicRuntimeTermination.failed,
        );
        return;
      }

      session.stepIndex++;
      session.stepElapsed = Duration.zero;
      session.stepBegun = false;
    }
  }

  CinematicRuntimeStepContext _contextFor(
    _CinematicRuntimeSession session, {
    required Duration delta,
  }) {
    return CinematicRuntimeStepContext(
      asset: session.asset,
      step: session.steps[session.stepIndex],
      stepIndex: session.stepIndex,
      elapsed: session.stepElapsed,
      delta: delta,
    );
  }

  void _terminate(
    SceneCinematicRuntimeAwaitableResult result,
    CinematicRuntimeTermination termination,
  ) {
    final session = _session;
    if (session == null) return;
    _session = null;
    var finalResult = result;
    try {
      sink.restore(termination);
    } catch (error) {
      finalResult = SceneCinematicRuntimeAwaitableResult.failed(
        errorCode: SceneCinematicRuntimeAwaitableErrorCode.sinkFailure,
        message: 'Cinematic sink restoration failed: $error',
      );
    } finally {
      if (!session.completer.isCompleted) {
        session.completer.complete(finalResult);
      }
    }
  }
}

final class _CinematicRuntimeSession {
  _CinematicRuntimeSession(this.asset)
      : steps = asset.timeline.steps,
        completer = Completer<SceneCinematicRuntimeAwaitableResult>();

  final CinematicAsset asset;
  final List<CinematicTimelineStep> steps;
  final Completer<SceneCinematicRuntimeAwaitableResult> completer;
  int stepIndex = 0;
  Duration stepElapsed = Duration.zero;
  bool stepBegun = false;
}

const _supportedKinds = <CinematicTimelineStepKind>{
  CinematicTimelineStepKind.wait,
  CinematicTimelineStepKind.camera,
  CinematicTimelineStepKind.actorMove,
  CinematicTimelineStepKind.actorFace,
  CinematicTimelineStepKind.actorEmote,
  CinematicTimelineStepKind.dialogueLine,
  CinematicTimelineStepKind.fade,
  CinematicTimelineStepKind.shake,
};

SceneCinematicRuntimeAwaitableResult? _preflightAsset(CinematicAsset asset) {
  final context = asset.stageContext;
  final bindings = <String, CinematicActorBinding>{};
  for (final binding in context?.actorBindings ?? const []) {
    if (bindings.containsKey(binding.actorId)) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
        'Actor "${binding.actorId}" has duplicate bindings.',
      );
    }
    if (binding.kind == CinematicActorBindingKind.cinematicOnly ||
        binding.kind == CinematicActorBindingKind.unbound) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.unsupportedActorBinding,
        'Actor "${binding.actorId}" uses unsupported binding '
        '"${_enumLabel(binding.kind)}".',
      );
    }
    if (binding.kind == CinematicActorBindingKind.mapEntity &&
        (binding.mapEntityId == null || binding.mapEntityId!.isEmpty)) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
        'Actor "${binding.actorId}" is missing mapEntityId.',
      );
    }
    bindings[binding.actorId] = binding;
  }
  for (final actor in asset.requiredActors) {
    if (!bindings.containsKey(actor.actorId)) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
        'Required actor "${actor.actorId}" has no runtime binding.',
      );
    }
  }

  final targetRefs = <String>{
    for (final target in asset.movementTargets) target.targetId,
  };
  final stagePointIds = <String>{
    for (final point in context?.stagePoints ?? const []) point.id,
  };
  final targetBindings = <String, CinematicMovementTargetBinding>{};
  for (final binding in context?.movementTargetBindings ?? const []) {
    if (!targetRefs.contains(binding.targetId) ||
        targetBindings.containsKey(binding.targetId)) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.invalidTargetReference,
        'Movement target "${binding.targetId}" has an invalid binding.',
      );
    }
    if (binding.kind != CinematicMovementTargetBindingKind.mapEntity &&
        binding.kind != CinematicMovementTargetBindingKind.stagePoint) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.invalidTargetReference,
        'Movement target "${binding.targetId}" uses unsupported binding '
        '"${_enumLabel(binding.kind)}".',
      );
    }
    final sourceId = binding.sourceId;
    if (sourceId == null || sourceId.isEmpty) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.invalidTargetReference,
        'Movement target "${binding.targetId}" is missing sourceId.',
      );
    }
    if (binding.kind == CinematicMovementTargetBindingKind.stagePoint &&
        !stagePointIds.contains(sourceId)) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.invalidTargetReference,
        'Movement target "${binding.targetId}" references unknown stage point '
        '"$sourceId".',
      );
    }
    targetBindings[binding.targetId] = binding;
  }
  for (final targetId in targetRefs) {
    if (!targetBindings.containsKey(targetId)) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.invalidTargetReference,
        'Movement target "$targetId" has no runtime binding.',
      );
    }
  }

  for (final step in asset.timeline.steps) {
    if (!_supportedKinds.contains(step.kind)) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.unsupportedStepKind,
        'Step "${step.id}" uses unsupported kind "${step.kind.name}".',
      );
    }
    if (step.durationMs != null && step.durationMs! < 0) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.invalidStep,
        'Step "${step.id}" has a negative duration.',
      );
    }
    if (step.kind == CinematicTimelineStepKind.wait &&
        step.durationMs == null) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.invalidStep,
        'Wait step "${step.id}" requires durationMs.',
      );
    }
    if (_requiresActor(step.kind)) {
      final actorId = step.actorId;
      if (actorId == null || !bindings.containsKey(actorId)) {
        return _failure(
          SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
          'Step "${step.id}" references an unavailable actor.',
        );
      }
    }
    if (step.kind == CinematicTimelineStepKind.actorMove) {
      final targetId = step.targetId;
      if (targetId == null || !targetBindings.containsKey(targetId)) {
        return _failure(
          SceneCinematicRuntimeAwaitableErrorCode.invalidTargetReference,
          'Step "${step.id}" references an unavailable movement target.',
        );
      }
    }
    if (step.kind == CinematicTimelineStepKind.dialogueLine &&
        (step.dialogueText == null || step.dialogueText!.isEmpty)) {
      return _failure(
        SceneCinematicRuntimeAwaitableErrorCode.invalidStep,
        'Dialogue line step "${step.id}" requires dialogueText.',
      );
    }
    if (step.kind == CinematicTimelineStepKind.camera &&
        cinematicTimelineCameraModeOf(step) ==
            CinematicTimelineCameraMode.focus) {
      final focus = cinematicTimelineCameraFocusBindingOf(step);
      if (focus == null) {
        return _failure(
          SceneCinematicRuntimeAwaitableErrorCode.invalidTargetReference,
          'Camera focus step "${step.id}" has an invalid target.',
        );
      }
      final target = focus.target;
      if (target.kind == CinematicCameraTargetKind.actor &&
          !bindings.containsKey(target.actorId)) {
        return _failure(
          SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
          'Camera step "${step.id}" references an unavailable actor.',
        );
      }
      if (target.kind == CinematicCameraTargetKind.stagePoint &&
          !stagePointIds.contains(target.stagePointId)) {
        return _failure(
          SceneCinematicRuntimeAwaitableErrorCode.invalidTargetReference,
          'Camera step "${step.id}" references an unavailable stage point.',
        );
      }
    }
  }
  return null;
}

bool _requiresActor(CinematicTimelineStepKind kind) {
  return kind == CinematicTimelineStepKind.actorMove ||
      kind == CinematicTimelineStepKind.actorFace ||
      kind == CinematicTimelineStepKind.actorEmote;
}

Duration? _positiveDurationOf(CinematicTimelineStep step) {
  final milliseconds = step.durationMs;
  return milliseconds == null ? null : Duration(milliseconds: milliseconds);
}

SceneCinematicRuntimeAwaitableResult _failure(
  SceneCinematicRuntimeAwaitableErrorCode code,
  String message,
) {
  return SceneCinematicRuntimeAwaitableResult.failed(
    errorCode: code,
    message: message,
  );
}

String _enumLabel(Object value) {
  final text = value.toString();
  final separator = text.lastIndexOf('.');
  return separator < 0 ? text : text.substring(separator + 1);
}
~~~~~~

### `packages/map_runtime/lib/src/presentation/flame/flame_cinematic_runtime_playback_sink.dart`

- Taille : `24212` octets
- SHA-256 : `d76da226d620a4844175a271d4c34e0680111bc99add7b10f66d75a5c47a49db`

~~~~~~dart
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:map_core/map_core.dart';

import '../../application/scene_runtime/cinematic_runtime_playback_controller.dart';
import '../../application/scene_runtime/scene_cinematic_runtime_awaitable_result.dart';

/// Minimal visual handle used by the production Flame cinematic sink.
///
/// Positions use world-space focus points rather than component top-left
/// coordinates so player and NPC sprites can share the same runtime contract.
abstract interface class FlameCinematicRuntimeActorHandle {
  Vector2 get focusPoint;

  EntityFacing get facing;

  void setFocusPoint(Vector2 focusPoint);

  void setFacing(EntityFacing facing);
}

/// Host boundary implemented by [PlayableMapGame]'s Flame scene.
///
/// All methods are synchronous because playback is driven by the game update
/// loop. No timer or wall-clock future participates in cinematic completion.
abstract interface class FlameCinematicRuntimeHost {
  bool get isReady;

  String get activeMapId;

  Vector2 get cameraPosition;

  set cameraPosition(Vector2 value);

  Vector2? get cameraVisibleGameSize;

  set cameraVisibleGameSize(Vector2? value);

  Vector2 get sceneCenter;

  FlameCinematicRuntimeActorHandle? get playerActor;

  FlameCinematicRuntimeActorHandle? mapEntityActor(String entityId);

  Vector2? mapEntityFocusPoint(String entityId);

  Vector2 stagePointFocusPoint(CinematicStagePoint point);

  void setCinematicInputLocked(bool locked);

  void showCinematicDialogueLine(String? text);

  void setCinematicFadeOpacity(double? opacity);

  void showCinematicActorEmote(
    FlameCinematicRuntimeActorHandle? actor,
    String? emoteId,
  );
}

/// Concrete deterministic visual sink for the CinematicAsset V1 subset.
final class FlameCinematicRuntimePlaybackSink
    implements CinematicRuntimePlaybackSink {
  FlameCinematicRuntimePlaybackSink({required this.host});

  final FlameCinematicRuntimeHost host;

  _CinematicRuntimeVisualSnapshot? _snapshot;
  Map<String, FlameCinematicRuntimeActorHandle> _actors = const {};
  _FlameCinematicStepState? _stepState;
  bool _dialogueLineSignalled = false;

  bool get isAwaitingDialogueLineAdvance =>
      _stepState is _DialogueLineStepState && !_dialogueLineSignalled;

  bool signalDialogueLineComplete() {
    if (_stepState is! _DialogueLineStepState || _dialogueLineSignalled) {
      return false;
    }
    _dialogueLineSignalled = true;
    return true;
  }

  @override
  CinematicRuntimeSinkPreflightResult preflight(CinematicAsset asset) {
    if (!host.isReady) {
      return const CinematicRuntimeSinkPreflightResult.rejected(
        message: 'The Flame cinematic runtime is not ready.',
      );
    }
    final authoredMapId = asset.mapId;
    if (authoredMapId != null && authoredMapId != host.activeMapId) {
      return CinematicRuntimeSinkPreflightResult.rejected(
        message: 'Cinematic "${asset.id}" targets map "$authoredMapId" but '
            'the active map is "${host.activeMapId}".',
      );
    }

    for (final binding in asset.stageContext?.actorBindings ?? const []) {
      if (_resolveActor(binding) == null) {
        return CinematicRuntimeSinkPreflightResult.rejected(
          errorCode:
              SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
          message: 'Cinematic actor "${binding.actorId}" is not mounted on '
              'the active Flame map.',
        );
      }
    }

    for (final binding
        in asset.stageContext?.movementTargetBindings ?? const []) {
      if (_resolveMovementTarget(asset, binding.targetId) == null) {
        return CinematicRuntimeSinkPreflightResult.rejected(
          errorCode:
              SceneCinematicRuntimeAwaitableErrorCode.invalidTargetReference,
          message: 'Cinematic movement target "${binding.targetId}" is not '
              'available on the active Flame map.',
        );
      }
    }

    for (final step in asset.timeline.steps) {
      final failure = _preflightStep(asset, step);
      if (failure != null) return failure;
    }
    return const CinematicRuntimeSinkPreflightResult.ready();
  }

  @override
  void beginStep(CinematicRuntimeStepContext context) {
    if (_snapshot == null) {
      _beginSession(context.asset);
    }
    if (_stepState != null) {
      throw StateError('A cinematic visual step is already active.');
    }

    final step = context.step;
    switch (step.kind) {
      case CinematicTimelineStepKind.wait:
        _stepState = const _PassiveStepState();
      case CinematicTimelineStepKind.camera:
        _beginCameraStep(context);
      case CinematicTimelineStepKind.actorMove:
        _beginActorMoveStep(context);
      case CinematicTimelineStepKind.actorFace:
        final actor = _requireActor(step.actorId);
        actor.setFacing(_entityFacingOf(step));
        _stepState = const _ImmediateStepState();
      case CinematicTimelineStepKind.actorEmote:
        final actor = _requireActor(step.actorId);
        final emoteId = cinematicTimelineActorEmoteEmoteIdOf(step)!;
        host.showCinematicActorEmote(actor, emoteId);
        _stepState = _ActorEmoteStepState(actor);
      case CinematicTimelineStepKind.dialogueLine:
        host.showCinematicDialogueLine(step.dialogueText);
        _dialogueLineSignalled = false;
        _stepState = const _DialogueLineStepState();
      case CinematicTimelineStepKind.fade:
        final fadeOut = step.metadata[cinematicTimelineFadeModeMetadataKey] ==
            CinematicTimelineFadeMode.fadeOut.name;
        host.setCinematicFadeOpacity(fadeOut ? 0 : 1);
        _stepState = _FadeStepState(fadeOut: fadeOut);
      case CinematicTimelineStepKind.shake:
        _stepState = _ShakeStepState(host.cameraPosition.clone());
      case CinematicTimelineStepKind.sound:
      case CinematicTimelineStepKind.music:
      case CinematicTimelineStepKind.fx:
      case CinematicTimelineStepKind.marker:
        throw StateError('Unsupported cinematic kind "${step.kind.name}".');
    }
  }

  @override
  void updateStep(CinematicRuntimeStepContext context) {
    final state = _stepState;
    if (state == null) {
      throw StateError('No cinematic visual step is active.');
    }
    final progress = _progressOf(context);
    switch (state) {
      case _CameraStepState():
        _applyCameraState(state, progress);
      case _ActorMoveStepState():
        _applyActorMoveState(state, progress);
      case _FadeStepState():
        host.setCinematicFadeOpacity(
          state.fadeOut ? progress : 1 - progress,
        );
      case _ShakeStepState():
        final envelope = math.sin(progress * math.pi);
        final offset = math.sin(progress * math.pi * 3) * 6 * envelope;
        host.cameraPosition = state.basePosition + Vector2(offset, 0);
      case _PassiveStepState():
      case _ImmediateStepState():
      case _ActorEmoteStepState():
      case _DialogueLineStepState():
        break;
    }
  }

  @override
  bool isStepVisuallyComplete(CinematicRuntimeStepContext context) {
    final state = _stepState;
    if (state is _ImmediateStepState) return true;
    if (state is _DialogueLineStepState) return _dialogueLineSignalled;
    if ((state is _CameraStepState || state is _ActorMoveStepState) &&
        context.step.durationMs == null) {
      return true;
    }
    return false;
  }

  @override
  void endStep(CinematicRuntimeStepContext context) {
    final state = _stepState;
    if (state == null) return;
    switch (state) {
      case _CameraStepState():
        _applyCameraState(state, 1);
      case _ActorMoveStepState():
        _applyActorMoveState(state, 1);
      case _FadeStepState():
        host.setCinematicFadeOpacity(state.fadeOut ? 1 : 0);
      case _ShakeStepState():
        host.cameraPosition = state.basePosition.clone();
      case _ActorEmoteStepState():
        host.showCinematicActorEmote(null, null);
      case _DialogueLineStepState():
        host.showCinematicDialogueLine(null);
      case _PassiveStepState():
      case _ImmediateStepState():
        break;
    }
    _stepState = null;
    _dialogueLineSignalled = false;
  }

  @override
  void restore(CinematicRuntimeTermination termination) {
    final snapshot = _snapshot;
    Object? firstError;
    StackTrace? firstStackTrace;

    void attempt(void Function() operation) {
      try {
        operation();
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }

    attempt(() => host.showCinematicDialogueLine(null));
    attempt(() => host.showCinematicActorEmote(null, null));
    attempt(() => host.setCinematicFadeOpacity(null));
    if (snapshot != null) {
      for (final actorSnapshot in snapshot.actors.values) {
        attempt(() => actorSnapshot.restore());
      }
      attempt(() => host.cameraPosition = snapshot.cameraPosition.clone());
      attempt(
        () => host.cameraVisibleGameSize =
            snapshot.cameraVisibleGameSize?.clone(),
      );
    }
    attempt(() => host.setCinematicInputLocked(false));

    _snapshot = null;
    _actors = const {};
    _stepState = null;
    _dialogueLineSignalled = false;

    if (firstError != null) {
      Error.throwWithStackTrace(firstError!, firstStackTrace!);
    }
  }

  CinematicRuntimeSinkPreflightResult? _preflightStep(
    CinematicAsset asset,
    CinematicTimelineStep step,
  ) {
    CinematicRuntimeSinkPreflightResult invalid(String message) {
      return CinematicRuntimeSinkPreflightResult.rejected(
        errorCode: SceneCinematicRuntimeAwaitableErrorCode.invalidStep,
        message: 'Step "${step.id}" $message',
      );
    }

    switch (step.kind) {
      case CinematicTimelineStepKind.wait:
      case CinematicTimelineStepKind.dialogueLine:
        return null;
      case CinematicTimelineStepKind.camera:
        final mode = cinematicTimelineCameraModeOf(step);
        if (mode == null) return invalid('has no supported camera mode.');
        if (mode == CinematicTimelineCameraMode.hold &&
            !_hasPositiveDuration(step)) {
          return invalid('requires a positive duration for camera hold.');
        }
        if (mode == CinematicTimelineCameraMode.focus) {
          final focus = cinematicTimelineCameraFocusBindingOf(step);
          if (focus == null || _resolveCameraFocus(asset, focus) == null) {
            return CinematicRuntimeSinkPreflightResult.rejected(
              errorCode: SceneCinematicRuntimeAwaitableErrorCode
                  .invalidTargetReference,
              message: 'Step "${step.id}" has an unavailable camera target.',
            );
          }
        }
        return null;
      case CinematicTimelineStepKind.actorMove:
        if (!_hasPositiveDuration(step)) {
          return invalid('requires a positive movement duration.');
        }
        if (cinematicTimelineActorMovementModeOf(step) == null ||
            cinematicTimelineActorPathModeOf(step) == null) {
          return invalid('has incomplete movement metadata.');
        }
        if (_resolveActorById(asset, step.actorId) == null) {
          return CinematicRuntimeSinkPreflightResult.rejected(
            errorCode:
                SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
            message: 'Step "${step.id}" has an unavailable actor.',
          );
        }
        if (_movementRoute(asset, step) == null) {
          return CinematicRuntimeSinkPreflightResult.rejected(
            errorCode:
                SceneCinematicRuntimeAwaitableErrorCode.invalidTargetReference,
            message: 'Step "${step.id}" has an unavailable movement route.',
          );
        }
        return null;
      case CinematicTimelineStepKind.actorFace:
        if (cinematicTimelineActorFacingDirectionOf(step) == null) {
          return invalid('has no facing direction.');
        }
        return null;
      case CinematicTimelineStepKind.actorEmote:
        if (!_hasPositiveDuration(step)) {
          return invalid('requires a positive emote duration.');
        }
        if (cinematicTimelineActorEmoteEmoteIdOf(step) == null) {
          return invalid('has no emote id.');
        }
        return null;
      case CinematicTimelineStepKind.fade:
        final fadeMode = step.metadata[cinematicTimelineFadeModeMetadataKey];
        if (fadeMode != CinematicTimelineFadeMode.fadeIn.name &&
            fadeMode != CinematicTimelineFadeMode.fadeOut.name) {
          return invalid('has no supported fade mode.');
        }
        if (!_hasPositiveDuration(step)) {
          return invalid('requires a positive fade duration.');
        }
        return null;
      case CinematicTimelineStepKind.shake:
        if (!_hasPositiveDuration(step)) {
          return invalid('requires a positive shake duration.');
        }
        return null;
      case CinematicTimelineStepKind.sound:
      case CinematicTimelineStepKind.music:
      case CinematicTimelineStepKind.fx:
      case CinematicTimelineStepKind.marker:
        return invalid('uses an unsupported V1 kind.');
    }
  }

  void _beginSession(CinematicAsset asset) {
    final actors = <String, FlameCinematicRuntimeActorHandle>{};
    final actorSnapshots = <String, _ActorVisualSnapshot>{};
    for (final binding in asset.stageContext?.actorBindings ?? const []) {
      final actor = _resolveActor(binding);
      if (actor == null) {
        throw StateError('Cinematic actor "${binding.actorId}" disappeared.');
      }
      actors[binding.actorId] = actor;
      actorSnapshots[binding.actorId] = _ActorVisualSnapshot(
        actor: actor,
        focusPoint: actor.focusPoint.clone(),
        facing: actor.facing,
      );
    }
    _actors =
        Map<String, FlameCinematicRuntimeActorHandle>.unmodifiable(actors);
    _snapshot = _CinematicRuntimeVisualSnapshot(
      cameraPosition: host.cameraPosition.clone(),
      cameraVisibleGameSize: host.cameraVisibleGameSize?.clone(),
      actors: Map<String, _ActorVisualSnapshot>.unmodifiable(actorSnapshots),
    );
    host.setCinematicInputLocked(true);
  }

  void _beginCameraStep(CinematicRuntimeStepContext context) {
    final mode = cinematicTimelineCameraModeOf(context.step)!;
    final fromPosition = host.cameraPosition.clone();
    final fromSize = host.cameraVisibleGameSize?.clone();
    var targetPosition = fromPosition.clone();
    var targetSize = fromSize?.clone();
    switch (mode) {
      case CinematicTimelineCameraMode.hold:
        break;
      case CinematicTimelineCameraMode.reset:
        final snapshot = _snapshot!;
        targetPosition = snapshot.cameraPosition.clone();
        targetSize = snapshot.cameraVisibleGameSize?.clone();
      case CinematicTimelineCameraMode.focus:
        final focus = cinematicTimelineCameraFocusBindingOf(context.step)!;
        targetPosition = _resolveCameraFocus(context.asset, focus)!.clone();
        final baseSize = _snapshot!.cameraVisibleGameSize ?? fromSize;
        if (baseSize != null) {
          targetSize = baseSize * _zoomFactor(focus.zoomPreset);
        }
    }
    final state = _CameraStepState(
      fromPosition: fromPosition,
      targetPosition: targetPosition,
      fromSize: fromSize,
      targetSize: targetSize,
    );
    _stepState = state;
    if (context.step.durationMs == null) _applyCameraState(state, 1);
  }

  void _beginActorMoveStep(CinematicRuntimeStepContext context) {
    final actor = _requireActor(context.step.actorId);
    final route = _movementRoute(context.asset, context.step)!;
    final points = <Vector2>[actor.focusPoint.clone(), ...route];
    _stepState = _ActorMoveStepState(actor: actor, points: points);
  }

  void _applyCameraState(_CameraStepState state, double progress) {
    host.cameraPosition =
        _lerp(state.fromPosition, state.targetPosition, progress);
    final fromSize = state.fromSize;
    final targetSize = state.targetSize;
    if (fromSize != null && targetSize != null) {
      host.cameraVisibleGameSize = _lerp(fromSize, targetSize, progress);
    } else if (progress >= 1) {
      host.cameraVisibleGameSize = targetSize?.clone();
    }
  }

  void _applyActorMoveState(_ActorMoveStepState state, double progress) {
    final points = state.points;
    if (points.length < 2) return;
    final scaled = progress.clamp(0.0, 1.0) * (points.length - 1);
    final segment = math.min(points.length - 2, scaled.floor());
    final localProgress = scaled - segment;
    final from = points[segment];
    final to = points[segment + 1];
    state.actor.setFacing(_facingBetween(from, to, state.actor.facing));
    state.actor.setFocusPoint(_lerp(from, to, localProgress));
  }

  FlameCinematicRuntimeActorHandle? _resolveActor(
    CinematicActorBinding binding,
  ) {
    final mapEntityId = binding.mapEntityId;
    return switch (binding.kind) {
      CinematicActorBindingKind.player => host.playerActor,
      CinematicActorBindingKind.mapEntity =>
        mapEntityId == null ? null : host.mapEntityActor(mapEntityId),
      CinematicActorBindingKind.cinematicOnly ||
      CinematicActorBindingKind.unbound =>
        null,
    };
  }

  FlameCinematicRuntimeActorHandle? _resolveActorById(
    CinematicAsset asset,
    String? actorId,
  ) {
    if (actorId == null) return null;
    for (final binding in asset.stageContext?.actorBindings ?? const []) {
      if (binding.actorId == actorId) return _resolveActor(binding);
    }
    return null;
  }

  FlameCinematicRuntimeActorHandle _requireActor(String? actorId) {
    final actor = actorId == null ? null : _actors[actorId];
    if (actor == null) {
      throw StateError('Cinematic actor "$actorId" is unavailable.');
    }
    return actor;
  }

  Vector2? _resolveMovementTarget(CinematicAsset asset, String targetId) {
    final context = asset.stageContext;
    if (context == null) return null;
    CinematicMovementTargetBinding? binding;
    for (final candidate in context.movementTargetBindings) {
      if (candidate.targetId == targetId) {
        binding = candidate;
        break;
      }
    }
    final sourceId = binding?.sourceId;
    if (binding == null || sourceId == null) return null;
    switch (binding.kind) {
      case CinematicMovementTargetBindingKind.mapEntity:
        return host.mapEntityFocusPoint(sourceId);
      case CinematicMovementTargetBindingKind.stagePoint:
        for (final point in context.stagePoints) {
          if (point.id == sourceId) return host.stagePointFocusPoint(point);
        }
        return null;
      case CinematicMovementTargetBindingKind.abstractPoint:
      case CinematicMovementTargetBindingKind.mapEvent:
        return null;
    }
  }

  List<Vector2>? _movementRoute(
    CinematicAsset asset,
    CinematicTimelineStep step,
  ) {
    final targetId = step.targetId;
    if (targetId == null) return null;
    final target = _resolveMovementTarget(asset, targetId);
    if (target == null) return null;
    if (cinematicTimelineActorPathModeOf(step) !=
        CinematicTimelineActorPathMode.manual) {
      return <Vector2>[target.clone()];
    }
    final context = asset.stageContext!;
    CinematicManualPath? manualPath;
    for (final candidate in context.manualPaths) {
      if (candidate.ownerActorMoveStepId == step.id) {
        manualPath = candidate;
        break;
      }
    }
    if (manualPath == null) return null;
    final stagePoints = <String, CinematicStagePoint>{
      for (final point in context.stagePoints) point.id: point,
    };
    final route = <Vector2>[];
    for (final pointId in manualPath.waypointStagePointIds) {
      final point = stagePoints[pointId];
      if (point == null) return null;
      route.add(host.stagePointFocusPoint(point));
    }
    if (route.isEmpty || route.last != target) route.add(target.clone());
    return route;
  }

  Vector2? _resolveCameraFocus(
    CinematicAsset asset,
    CinematicTimelineCameraFocusBinding focus,
  ) {
    return switch (focus.target.kind) {
      CinematicCameraTargetKind.sceneCenter => host.sceneCenter,
      CinematicCameraTargetKind.actor =>
        _resolveActorById(asset, focus.target.actorId)?.focusPoint,
      CinematicCameraTargetKind.stagePoint => _stagePointById(
          asset,
          focus.target.stagePointId,
        ),
    };
  }

  Vector2? _stagePointById(CinematicAsset asset, String? pointId) {
    if (pointId == null) return null;
    for (final point in asset.stageContext?.stagePoints ?? const []) {
      if (point.id == pointId) return host.stagePointFocusPoint(point);
    }
    return null;
  }
}

double _progressOf(CinematicRuntimeStepContext context) {
  final durationMs = context.step.durationMs;
  if (durationMs == null || durationMs <= 0) return 1;
  return (context.elapsed.inMicroseconds /
          (durationMs * Duration.microsecondsPerMillisecond))
      .clamp(0.0, 1.0);
}

bool _hasPositiveDuration(CinematicTimelineStep step) =>
    (step.durationMs ?? 0) > 0;

double _zoomFactor(CinematicCameraZoomPreset preset) {
  return switch (preset) {
    CinematicCameraZoomPreset.wide => 1,
    CinematicCameraZoomPreset.medium => 0.8,
    CinematicCameraZoomPreset.close => 0.6,
  };
}

EntityFacing _entityFacingOf(CinematicTimelineStep step) {
  return switch (cinematicTimelineActorFacingDirectionOf(step)!) {
    CinematicTimelineActorFacingDirection.up => EntityFacing.north,
    CinematicTimelineActorFacingDirection.down => EntityFacing.south,
    CinematicTimelineActorFacingDirection.left => EntityFacing.west,
    CinematicTimelineActorFacingDirection.right => EntityFacing.east,
  };
}

EntityFacing _facingBetween(
  Vector2 from,
  Vector2 to,
  EntityFacing fallback,
) {
  final dx = to.x - from.x;
  final dy = to.y - from.y;
  if (dx.abs() >= dy.abs() && dx != 0) {
    return dx > 0 ? EntityFacing.east : EntityFacing.west;
  }
  if (dy != 0) return dy > 0 ? EntityFacing.south : EntityFacing.north;
  return fallback;
}

Vector2 _lerp(Vector2 from, Vector2 to, double progress) {
  final t = progress.clamp(0.0, 1.0);
  return Vector2(
    from.x + (to.x - from.x) * t,
    from.y + (to.y - from.y) * t,
  );
}

final class _CinematicRuntimeVisualSnapshot {
  const _CinematicRuntimeVisualSnapshot({
    required this.cameraPosition,
    required this.cameraVisibleGameSize,
    required this.actors,
  });

  final Vector2 cameraPosition;
  final Vector2? cameraVisibleGameSize;
  final Map<String, _ActorVisualSnapshot> actors;
}

final class _ActorVisualSnapshot {
  const _ActorVisualSnapshot({
    required this.actor,
    required this.focusPoint,
    required this.facing,
  });

  final FlameCinematicRuntimeActorHandle actor;
  final Vector2 focusPoint;
  final EntityFacing facing;

  void restore() {
    actor.setFocusPoint(focusPoint.clone());
    actor.setFacing(facing);
  }
}

sealed class _FlameCinematicStepState {
  const _FlameCinematicStepState();
}

final class _PassiveStepState extends _FlameCinematicStepState {
  const _PassiveStepState();
}

final class _ImmediateStepState extends _FlameCinematicStepState {
  const _ImmediateStepState();
}

final class _CameraStepState extends _FlameCinematicStepState {
  const _CameraStepState({
    required this.fromPosition,
    required this.targetPosition,
    required this.fromSize,
    required this.targetSize,
  });

  final Vector2 fromPosition;
  final Vector2 targetPosition;
  final Vector2? fromSize;
  final Vector2? targetSize;
}

final class _ActorMoveStepState extends _FlameCinematicStepState {
  const _ActorMoveStepState({required this.actor, required this.points});

  final FlameCinematicRuntimeActorHandle actor;
  final List<Vector2> points;
}

final class _ActorEmoteStepState extends _FlameCinematicStepState {
  const _ActorEmoteStepState(this.actor);

  final FlameCinematicRuntimeActorHandle actor;
}

final class _DialogueLineStepState extends _FlameCinematicStepState {
  const _DialogueLineStepState();
}

final class _FadeStepState extends _FlameCinematicStepState {
  const _FadeStepState({required this.fadeOut});

  final bool fadeOut;
}

final class _ShakeStepState extends _FlameCinematicStepState {
  const _ShakeStepState(this.basePosition);

  final Vector2 basePosition;
}
~~~~~~

### `packages/map_runtime/test/cinematic_runtime_playback_controller_test.dart`

- Taille : `12602` octets
- SHA-256 : `bb28ad387006ecc71741fc9a48c231045a8b7197ff7657de10227d49dc4c107c`

~~~~~~dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('CinematicRuntimePlaybackController', () {
    test('implements the existing awaitable cinematic player port', () async {
      final sink = _RecordingSink();
      final controller = CinematicRuntimePlaybackController(sink: sink);
      final asset = _asset(
        steps: <CinematicTimelineStep>[
          _step(CinematicTimelineStepKind.wait, durationMs: 10),
        ],
      );

      final completion = controller.playCinematic(
        SceneCinematicRuntimeRequest(
          requestId: 'request',
          createdAtEpochMs: 0,
          cinematicId: asset.id,
          asset: asset,
        ),
      );
      controller.update(const Duration(milliseconds: 10));

      expect(
        (await completion).status,
        SceneCinematicRuntimeAwaitableStatus.completed,
      );
      expect(controller, isA<SceneCinematicRuntimePlayer>());
    });

    test('executes the eight V1 step kinds strictly in authored order',
        () async {
      final sink = _RecordingSink()..recordUpdates = false;
      final controller = CinematicRuntimePlaybackController(sink: sink);
      final asset = _asset(
        steps: <CinematicTimelineStep>[
          for (final kind in const <CinematicTimelineStepKind>[
            CinematicTimelineStepKind.wait,
            CinematicTimelineStepKind.camera,
            CinematicTimelineStepKind.actorMove,
            CinematicTimelineStepKind.actorFace,
            CinematicTimelineStepKind.actorEmote,
            CinematicTimelineStepKind.dialogueLine,
            CinematicTimelineStepKind.fade,
            CinematicTimelineStepKind.shake,
          ])
            _step(kind, durationMs: 10),
        ],
      );

      final completion = controller.play(asset);
      controller.update(const Duration(milliseconds: 80));
      final result = await completion;

      expect(result.status, SceneCinematicRuntimeAwaitableStatus.completed);
      expect(
        sink.events,
        <String>[
          for (final kind in const <CinematicTimelineStepKind>[
            CinematicTimelineStepKind.wait,
            CinematicTimelineStepKind.camera,
            CinematicTimelineStepKind.actorMove,
            CinematicTimelineStepKind.actorFace,
            CinematicTimelineStepKind.actorEmote,
            CinematicTimelineStepKind.dialogueLine,
            CinematicTimelineStepKind.fade,
            CinematicTimelineStepKind.shake,
          ]) ...<String>['begin:${kind.name}', 'end:${kind.name}'],
          'restore:completed',
        ],
      );
    });

    test('does not advance before visual completion or duration elapses',
        () async {
      final sink = _RecordingSink();
      final controller = CinematicRuntimePlaybackController(sink: sink);
      final completion = controller.play(
        _asset(
          steps: <CinematicTimelineStep>[
            _step(CinematicTimelineStepKind.camera),
            _step(CinematicTimelineStepKind.wait, durationMs: 10),
          ],
        ),
      );

      controller.update(const Duration(seconds: 5));
      expect(controller.currentStep?.kind, CinematicTimelineStepKind.camera);
      expect(sink.events, <String>['begin:camera', 'update:camera']);
      expect(controller.isPlaying, isTrue);

      sink.visuallyCompletedKinds.add(CinematicTimelineStepKind.camera);
      controller.update(Duration.zero);
      expect(controller.currentStep?.kind, CinematicTimelineStepKind.wait);
      expect(
        sink.events,
        containsAllInOrder(<String>['end:camera', 'begin:wait']),
      );

      controller.update(const Duration(milliseconds: 10));
      expect(
        (await completion).status,
        SceneCinematicRuntimeAwaitableStatus.completed,
      );
    });

    test('preflight rejects a missing actor before any mutation', () async {
      final sink = _RecordingSink();
      final controller = CinematicRuntimePlaybackController(sink: sink);

      final result = await controller.play(
        _asset(
          steps: <CinematicTimelineStep>[
            CinematicTimelineStep(
              id: 'face_missing',
              kind: CinematicTimelineStepKind.actorFace,
              actorId: 'missing',
            ),
          ],
        ),
      );

      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
      );
      expect(sink.preflightCalls, 0);
      expect(sink.events, isEmpty);
    });

    test('preflight rejects cinematicOnly bindings before sink mutation',
        () async {
      final sink = _RecordingSink();
      final controller = CinematicRuntimePlaybackController(sink: sink);

      final result = await controller.play(
        _asset(
          bindingKind: CinematicActorBindingKind.cinematicOnly,
          steps: <CinematicTimelineStep>[
            _step(CinematicTimelineStepKind.actorEmote, durationMs: 10),
          ],
        ),
      );

      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.unsupportedActorBinding,
      );
      expect(sink.preflightCalls, 0);
      expect(sink.events, isEmpty);
    });

    test('preflight rejects unsupported step kinds before sink mutation',
        () async {
      final sink = _RecordingSink();
      final controller = CinematicRuntimePlaybackController(sink: sink);

      final result = await controller.play(
        _asset(
          steps: <CinematicTimelineStep>[
            _step(CinematicTimelineStepKind.wait, durationMs: 10),
            _step(CinematicTimelineStepKind.sound),
          ],
        ),
      );

      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.unsupportedStepKind,
      );
      expect(sink.preflightCalls, 0);
      expect(sink.events, isEmpty);
    });

    test('preflight rejects unsupported movement targets before sink mutation',
        () async {
      final sink = _RecordingSink();
      final controller = CinematicRuntimePlaybackController(sink: sink);
      final valid = _asset(
        steps: <CinematicTimelineStep>[
          _step(CinematicTimelineStepKind.actorMove, durationMs: 10),
        ],
      );
      final invalid = CinematicAsset(
        id: valid.id,
        title: valid.title,
        requiredActors: valid.requiredActors,
        movementTargets: valid.movementTargets,
        stageContext: CinematicStageContext(
          actorBindings: valid.stageContext!.actorBindings,
          movementTargetBindings: <CinematicMovementTargetBinding>[
            CinematicMovementTargetBinding(
              targetId: 'target',
              kind: CinematicMovementTargetBindingKind.abstractPoint,
            ),
          ],
        ),
        timeline: valid.timeline,
      );

      final result = await controller.play(invalid);

      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.invalidTargetReference,
      );
      expect(sink.preflightCalls, 0);
      expect(sink.events, isEmpty);
    });

    test('sink preflight rejection stays mutation free and typed', () async {
      final sink = _RecordingSink()
        ..preflightResult = const CinematicRuntimeSinkPreflightResult.rejected(
          errorCode:
              SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
          message: 'Actor is not mounted on the active map.',
        );
      final controller = CinematicRuntimePlaybackController(sink: sink);

      final result = await controller.play(
        _asset(
          steps: <CinematicTimelineStep>[
            _step(CinematicTimelineStepKind.wait, durationMs: 10),
          ],
        ),
      );

      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
      );
      expect(sink.preflightCalls, 1);
      expect(sink.events, isEmpty);
    });

    test('cancellation completes once and restores atomically', () async {
      final sink = _RecordingSink();
      final controller = CinematicRuntimePlaybackController(sink: sink);
      final completion = controller.play(
        _asset(
          steps: <CinematicTimelineStep>[
            _step(CinematicTimelineStepKind.camera),
          ],
        ),
      );

      expect(controller.cancel(message: 'test cancellation'), isTrue);
      expect(controller.cancel(message: 'duplicate cancellation'), isFalse);
      final result = await completion;

      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.cancelled,
      );
      expect(sink.restoreCalls, 1);
      expect(sink.events.last, 'restore:cancelled');
      expect(controller.isPlaying, isFalse);
    });

    test('sink errors restore once and return a typed failure', () async {
      final sink = _RecordingSink()..throwOnUpdate = true;
      final controller = CinematicRuntimePlaybackController(sink: sink);
      final completion = controller.play(
        _asset(
          steps: <CinematicTimelineStep>[
            _step(CinematicTimelineStepKind.camera),
          ],
        ),
      );

      controller.update(const Duration(milliseconds: 1));
      final result = await completion;

      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.sinkFailure,
      );
      expect(sink.restoreCalls, 1);
      expect(controller.isPlaying, isFalse);
    });
  });
}

final class _RecordingSink implements CinematicRuntimePlaybackSink {
  int preflightCalls = 0;
  int restoreCalls = 0;
  bool throwOnUpdate = false;
  bool recordUpdates = true;
  final Set<CinematicTimelineStepKind> visuallyCompletedKinds =
      <CinematicTimelineStepKind>{};
  CinematicRuntimeSinkPreflightResult preflightResult =
      const CinematicRuntimeSinkPreflightResult.ready();
  final List<String> events = <String>[];

  @override
  CinematicRuntimeSinkPreflightResult preflight(CinematicAsset asset) {
    preflightCalls++;
    return preflightResult;
  }

  @override
  void beginStep(CinematicRuntimeStepContext context) {
    events.add('begin:${context.step.kind.name}');
  }

  @override
  void updateStep(CinematicRuntimeStepContext context) {
    if (throwOnUpdate) throw StateError('sink update failed');
    if (recordUpdates) events.add('update:${context.step.kind.name}');
  }

  @override
  bool isStepVisuallyComplete(CinematicRuntimeStepContext context) {
    return visuallyCompletedKinds.contains(context.step.kind);
  }

  @override
  void endStep(CinematicRuntimeStepContext context) {
    events.add('end:${context.step.kind.name}');
  }

  @override
  void restore(CinematicRuntimeTermination termination) {
    restoreCalls++;
    events.add('restore:${termination.name}');
  }
}

CinematicAsset _asset({
  required List<CinematicTimelineStep> steps,
  CinematicActorBindingKind bindingKind = CinematicActorBindingKind.mapEntity,
}) {
  return CinematicAsset(
    id: 'cinematic_test',
    title: 'Test cinematic',
    requiredActors: <CinematicActorRef>[
      CinematicActorRef(actorId: 'actor'),
    ],
    movementTargets: <CinematicMovementTargetRef>[
      CinematicMovementTargetRef(targetId: 'target', label: 'Target'),
    ],
    stageContext: CinematicStageContext(
      actorBindings: <CinematicActorBinding>[
        CinematicActorBinding(
          actorId: 'actor',
          kind: bindingKind,
          mapEntityId:
              bindingKind == CinematicActorBindingKind.mapEntity ? 'npc' : null,
        ),
      ],
      movementTargetBindings: <CinematicMovementTargetBinding>[
        CinematicMovementTargetBinding(
          targetId: 'target',
          kind: CinematicMovementTargetBindingKind.stagePoint,
          sourceId: 'point',
        ),
      ],
      stagePoints: <CinematicStagePoint>[
        CinematicStagePoint(
          id: 'point',
          label: 'Point',
          x: 1,
          y: 1,
        ),
      ],
    ),
    timeline: CinematicTimeline(steps: steps),
  );
}

CinematicTimelineStep _step(
  CinematicTimelineStepKind kind, {
  int? durationMs,
}) {
  return CinematicTimelineStep(
    id: 'step_${kind.name}',
    kind: kind,
    durationMs: durationMs,
    actorId: switch (kind) {
      CinematicTimelineStepKind.actorMove ||
      CinematicTimelineStepKind.actorFace ||
      CinematicTimelineStepKind.actorEmote =>
        'actor',
      _ => null,
    },
    targetId: kind == CinematicTimelineStepKind.actorMove ? 'target' : null,
    dialogueText:
        kind == CinematicTimelineStepKind.dialogueLine ? 'Hello' : null,
  );
}
~~~~~~

### `packages/map_runtime/test/dialogue_runtime_outcome_test.dart`

- Taille : `2818` octets
- SHA-256 : `c0df0e385cb3adf0c84f8e3542379c969284d2e49bd0f4bb78d0feee3d88596a`

~~~~~~dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/parse_yarn_dialogue.dart';
import 'package:map_runtime/src/presentation/flame/dialogue_overlay_component.dart';

void main() {
  group('Yarn dialogue outcomes', () {
    test('parser attaches each outcome to its choice and preserves content',
        () {
      final nodes = parseYarnFile('''
title: Start
---
Guide: Choisis.
-> Accepter
    <<outcome accepted>>
    Joueur: Oui.
    <<jump Accepted>>
-> Refuser
    <<outcome refused>>
    Joueur: Non.
===
title: Accepted
---
Guide: Continuons.
===
''');

      final choiceBlock = nodes.first.steps[1] as YarnStepChoiceBlock;
      expect(
        choiceBlock.choices.map((choice) => choice.outcomeId),
        ['accepted', 'refused'],
      );
      expect(choiceBlock.choices.first.text, 'Accepter');
      expect(choiceBlock.choices.first.steps, hasLength(2));
      expect(
        (choiceBlock.choices.first.steps.first as YarnStepLine).text,
        'Joueur: Oui.',
      );
      expect(
        (choiceBlock.choices.first.steps.last as YarnStepJump).targetNode,
        'Accepted',
      );
    });

    test('session preserves the selected outcome through lines and jumps', () {
      final nodes = parseYarnFile('''
title: Start
---
-> Accepter
    <<outcome accepted>>
    Joueur: Oui.
    <<jump Accepted>>
===
title: Accepted
---
Guide: Continuons.
===
''');

      var session = DialogueSession.start(nodes, 'Start')!;
      session = session.confirmChoice()!;
      expect(session.selectedOutcomeId, 'accepted');
      expect((session.state as DialogueShowingLine).text, 'Joueur: Oui.');

      session = session.advance()!;
      expect(session.currentNodeTitle, 'Accepted');
      expect(session.selectedOutcomeId, 'accepted');
      expect((session.state as DialogueShowingLine).text, 'Guide: Continuons.');
    });

    test('overlay returns the outcome when a choice branch ends immediately',
        () {
      final session = DialogueSession.start(
        [
          YarnNode(
            title: 'Start',
            steps: [
              YarnStepChoiceBlock([
                YarnChoice(
                  text: 'Accepter',
                  outcomeId: 'accepted',
                  steps: const [],
                ),
              ]),
            ],
          ),
        ],
        'Start',
      )!;
      String? finishedOutcome;
      final overlay = DialogueOverlayComponent(
        session: session,
        onFinished: (outcomeId) => finishedOutcome = outcomeId,
        viewportSize: Vector2(320, 240),
      );

      expect(overlay.confirmChoice(), isFalse);
      expect(finishedOutcome, 'accepted');
    });
  });
}
~~~~~~

### `packages/map_runtime/test/flame_cinematic_runtime_playback_sink_test.dart`

- Taille : `12247` octets
- SHA-256 : `dfe5ce4c398d373b441db961ac369570cd080d227c10a119fdc48c3efe1e0b1d`

~~~~~~dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('FlameCinematicRuntimePlaybackSink', () {
    test('preflight rejects an unavailable actor without runtime mutation', () {
      final host = _FakeHost()..actors.remove('npc');
      final sink = FlameCinematicRuntimePlaybackSink(host: host);

      final result = sink.preflight(_visualAsset());

      expect(result.isReady, isFalse);
      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
      );
      expect(host.inputLocked, isFalse);
      expect(host.events, isEmpty);
    });

    test('preflight rejects an incomplete map actor binding without throwing',
        () {
      final host = _FakeHost();
      final sink = FlameCinematicRuntimePlaybackSink(host: host);
      final asset = _visualAsset(
        stageContext: CinematicStageContext(
          actorBindings: <CinematicActorBinding>[
            CinematicActorBinding(
              actorId: 'lysa',
              kind: CinematicActorBindingKind.mapEntity,
            ),
          ],
        ),
      );

      final result = sink.preflight(asset);

      expect(result.isReady, isFalse);
      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.invalidActorReference,
      );
      expect(host.inputLocked, isFalse);
      expect(host.events, isEmpty);
    });

    test('renders the eight V1 beats and restores the runtime atomically',
        () async {
      final host = _FakeHost();
      final sink = FlameCinematicRuntimePlaybackSink(host: host);
      final controller = CinematicRuntimePlaybackController(sink: sink);

      final completion = controller.play(_visualAsset());

      expect(host.inputLocked, isTrue);
      controller.update(const Duration(milliseconds: 10));
      expect(controller.currentStep?.kind, CinematicTimelineStepKind.camera);

      controller.update(const Duration(milliseconds: 50));
      expect(host.cameraPosition, Vector2(15, 15));
      expect(host.cameraVisibleGameSize, Vector2(80, 64));

      controller.update(const Duration(milliseconds: 50));
      expect(controller.currentStep?.kind, CinematicTimelineStepKind.actorMove);
      controller.update(const Duration(milliseconds: 50));
      expect(host.actors['hero']!.focusPoint, Vector2(60, 30));

      controller.update(const Duration(milliseconds: 50));
      expect(
          controller.currentStep?.kind, CinematicTimelineStepKind.actorEmote);
      expect(host.emoteId, 'heart');
      expect(host.actors['npc']!.facing, EntityFacing.east);

      controller.update(const Duration(milliseconds: 100));
      expect(
        controller.currentStep?.kind,
        CinematicTimelineStepKind.dialogueLine,
      );
      expect(host.dialogueLine, 'Le phare nous attend.');
      expect(sink.isAwaitingDialogueLineAdvance, isTrue);

      expect(sink.signalDialogueLineComplete(), isTrue);
      controller.update(Duration.zero);
      expect(controller.currentStep?.kind, CinematicTimelineStepKind.fade);
      controller.update(const Duration(milliseconds: 50));
      expect(host.fadeOpacity, closeTo(0.5, 0.001));

      controller.update(const Duration(milliseconds: 50));
      expect(controller.currentStep?.kind, CinematicTimelineStepKind.shake);
      controller.update(const Duration(milliseconds: 50));
      expect(host.cameraPosition, isNot(Vector2(20, 20)));

      controller.update(const Duration(milliseconds: 50));
      final result = await completion;

      expect(result.success, isTrue);
      expect(host.inputLocked, isFalse);
      expect(host.cameraPosition, Vector2(10, 10));
      expect(host.cameraVisibleGameSize, Vector2(100, 80));
      expect(host.actors['hero']!.focusPoint, Vector2(20, 20));
      expect(host.actors['npc']!.facing, EntityFacing.south);
      expect(host.dialogueLine, isNull);
      expect(host.fadeOpacity, isNull);
      expect(host.emoteId, isNull);
    });

    test('cancellation restores camera actors overlays and input once',
        () async {
      final host = _FakeHost();
      final sink = FlameCinematicRuntimePlaybackSink(host: host);
      final controller = CinematicRuntimePlaybackController(sink: sink);
      final asset = _visualAsset(
        steps: <CinematicTimelineStep>[
          _actorMoveStep(),
        ],
      );

      final completion = controller.play(asset);
      controller.update(const Duration(milliseconds: 50));
      expect(host.actors['hero']!.focusPoint, Vector2(60, 30));

      expect(controller.cancel(), isTrue);
      expect(controller.cancel(), isFalse);
      final result = await completion;

      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.cancelled,
      );
      expect(host.inputLocked, isFalse);
      expect(host.actors['hero']!.focusPoint, Vector2(20, 20));
      expect(host.inputUnlockCount, 1);
    });

    test('restoration keeps unlocking input when overlay cleanup throws',
        () async {
      final host = _FakeHost()..throwWhenClearingDialogue = true;
      final sink = FlameCinematicRuntimePlaybackSink(host: host);
      final controller = CinematicRuntimePlaybackController(sink: sink);
      final completion = controller.play(
        _visualAsset(
          steps: <CinematicTimelineStep>[
            CinematicTimelineStep(
              id: 'line',
              kind: CinematicTimelineStepKind.dialogueLine,
              dialogueText: 'Toujours restaurer.',
            ),
          ],
        ),
      );

      expect(controller.cancel(), isTrue);
      final result = await completion;

      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.sinkFailure,
      );
      expect(host.inputLocked, isFalse);
      expect(host.inputUnlockCount, 1);
      expect(host.cameraPosition, Vector2(10, 10));
      expect(host.actors['hero']!.focusPoint, Vector2(20, 20));
    });
  });
}

final class _FakeHost implements FlameCinematicRuntimeHost {
  bool ready = true;
  bool inputLocked = false;
  int inputUnlockCount = 0;
  bool throwWhenClearingDialogue = false;
  String? dialogueLine;
  String? emoteId;
  double? fadeOpacity;
  final List<String> events = <String>[];
  final Map<String, _FakeActor> actors = <String, _FakeActor>{
    'hero': _FakeActor(Vector2(20, 20), EntityFacing.north),
    'npc': _FakeActor(Vector2(40, 20), EntityFacing.south),
  };

  @override
  String get activeMapId => 'map_port';

  @override
  bool get isReady => ready;

  @override
  Vector2 cameraPosition = Vector2(10, 10);

  @override
  Vector2? cameraVisibleGameSize = Vector2(100, 80);

  @override
  Vector2 get sceneCenter => Vector2(50, 40);

  @override
  FlameCinematicRuntimeActorHandle? get playerActor => actors['hero'];

  @override
  FlameCinematicRuntimeActorHandle? mapEntityActor(String entityId) {
    return actors[entityId];
  }

  @override
  Vector2? mapEntityFocusPoint(String entityId) {
    return actors[entityId]?.focusPoint.clone();
  }

  @override
  Vector2 stagePointFocusPoint(CinematicStagePoint point) {
    return Vector2(point.x, point.y);
  }

  @override
  void setCinematicInputLocked(bool locked) {
    inputLocked = locked;
    events.add('input:$locked');
    if (!locked) inputUnlockCount++;
  }

  @override
  void showCinematicActorEmote(
    FlameCinematicRuntimeActorHandle? actor,
    String? emoteId,
  ) {
    this.emoteId = emoteId;
    events.add('emote:${emoteId ?? '-'}');
  }

  @override
  void showCinematicDialogueLine(String? text) {
    if (text == null && throwWhenClearingDialogue) {
      throw StateError('dialogue cleanup failed');
    }
    dialogueLine = text;
    events.add('dialogue:${text ?? '-'}');
  }

  @override
  void setCinematicFadeOpacity(double? opacity) {
    fadeOpacity = opacity;
    events.add('fade:${opacity ?? '-'}');
  }
}

final class _FakeActor implements FlameCinematicRuntimeActorHandle {
  _FakeActor(this.focusPoint, this.facing);

  @override
  Vector2 focusPoint;

  @override
  EntityFacing facing;

  @override
  void setFacing(EntityFacing facing) {
    this.facing = facing;
  }

  @override
  void setFocusPoint(Vector2 focusPoint) {
    this.focusPoint = focusPoint.clone();
  }
}

CinematicAsset _visualAsset({
  List<CinematicTimelineStep>? steps,
  CinematicStageContext? stageContext,
}) {
  return CinematicAsset(
    id: 'cinematic_port',
    title: 'Port cinematic',
    mapId: 'map_port',
    requiredActors: <CinematicActorRef>[
      CinematicActorRef(actorId: 'hero'),
      CinematicActorRef(actorId: 'lysa'),
    ],
    movementTargets: <CinematicMovementTargetRef>[
      CinematicMovementTargetRef(targetId: 'lighthouse', label: 'Phare'),
    ],
    stageContext: stageContext ??
        CinematicStageContext(
          actorBindings: <CinematicActorBinding>[
            CinematicActorBinding(
              actorId: 'hero',
              kind: CinematicActorBindingKind.player,
            ),
            CinematicActorBinding(
              actorId: 'lysa',
              kind: CinematicActorBindingKind.mapEntity,
              mapEntityId: 'npc',
            ),
          ],
          movementTargetBindings: <CinematicMovementTargetBinding>[
            CinematicMovementTargetBinding(
              targetId: 'lighthouse',
              kind: CinematicMovementTargetBindingKind.stagePoint,
              sourceId: 'lighthouse_point',
            ),
          ],
          stagePoints: <CinematicStagePoint>[
            CinematicStagePoint(
              id: 'lighthouse_point',
              label: 'Phare',
              x: 100,
              y: 40,
            ),
          ],
        ),
    timeline: CinematicTimeline(
      steps: steps ??
          <CinematicTimelineStep>[
            CinematicTimelineStep(
              id: 'wait',
              kind: CinematicTimelineStepKind.wait,
              durationMs: 10,
            ),
            CinematicTimelineStep(
              id: 'camera',
              kind: CinematicTimelineStepKind.camera,
              durationMs: 100,
              metadata: const <String, String>{
                cinematicTimelineCameraModeMetadataKey: 'focus',
                cinematicTimelineCameraTargetKindMetadataKey: 'actor',
                cinematicTimelineCameraTargetActorIdMetadataKey: 'hero',
                cinematicTimelineCameraZoomPresetMetadataKey: 'close',
              },
            ),
            _actorMoveStep(),
            CinematicTimelineStep(
              id: 'face',
              kind: CinematicTimelineStepKind.actorFace,
              actorId: 'lysa',
              metadata: const <String, String>{
                cinematicTimelineActorDirectionMetadataKey: 'right',
              },
            ),
            CinematicTimelineStep(
              id: 'emote',
              kind: CinematicTimelineStepKind.actorEmote,
              durationMs: 100,
              actorId: 'lysa',
              metadata: const <String, String>{
                cinematicTimelineActorEmoteEmoteIdMetadataKey: 'heart',
              },
            ),
            CinematicTimelineStep(
              id: 'line',
              kind: CinematicTimelineStepKind.dialogueLine,
              dialogueText: 'Le phare nous attend.',
            ),
            CinematicTimelineStep(
              id: 'fade',
              kind: CinematicTimelineStepKind.fade,
              durationMs: 100,
              metadata: const <String, String>{
                cinematicTimelineFadeModeMetadataKey: 'fadeOut',
              },
            ),
            CinematicTimelineStep(
              id: 'shake',
              kind: CinematicTimelineStepKind.shake,
              durationMs: 100,
            ),
          ],
    ),
  );
}

CinematicTimelineStep _actorMoveStep() {
  return CinematicTimelineStep(
    id: 'move',
    kind: CinematicTimelineStepKind.actorMove,
    durationMs: 100,
    actorId: 'hero',
    targetId: 'lighthouse',
    metadata: const <String, String>{
      cinematicTimelineActorMovementModeMetadataKey: 'walk',
      cinematicTimelineActorPathModeMetadataKey: 'direct',
    },
  );
}
~~~~~~

### `packages/map_runtime/test/playable_map_game_cinematic_runtime_integration_test.dart`

- Taille : `6823` octets
- SHA-256 : `928bbf6ceb3e5f8cbe74a1eb7366cd23c9f1a7c6d9793a96f2b0a10c6d293f66`

~~~~~~dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'PlayableMapGame renders and awaits a cinematic before restoring input and camera',
      () async {
    final game = _LifecycleTestPlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/cinematic_runtime/project.json',
    );
    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForInitialMapActivation(game);
    final originalCameraTopLeft = game.debugCameraWorldTopLeft.clone();
    final originalPlayerPosition = game.debugPlayerGridPosition;

    final completion = game.debugExecuteNarrativeSceneForTest(
      NarrativeSceneExecutionRequest(
        eventId: 'event_cinematic_runtime',
        sceneId: 'scene_cinematic_runtime',
        executionId: 'execution_cinematic_runtime',
        gameState: game.gameStateSnapshot,
      ),
    );
    await _waitUntil(game, () => game.debugIsCinematicPlaying);

    expect(game.debugIsCinematicPlaying, isTrue);
    expect(game.debugIsGameplayInputLocked, isTrue);
    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.right),
      ),
      isTrue,
    );

    game.update(0.05);
    expect(game.debugCameraWorldTopLeft, isNot(originalCameraTopLeft));
    expect(game.debugPlayerGridPosition, originalPlayerPosition);

    game.update(0.05);
    expect(game.debugCinematicDialogueLine, 'Le phare nous attend.');
    expect(game.debugIsCinematicPlaying, isTrue);

    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );
    expect(game.debugCinematicDialogueLine, isNull);
    expect(game.debugCinematicFadeOpacity, 0);

    game.update(0.05);
    expect(game.debugCinematicFadeOpacity, closeTo(0.5, 0.001));
    game.update(0.05);
    final result = await completion;

    expect(result, isA<NarrativeSceneExecutionCompleted>());
    expect(game.debugIsCinematicPlaying, isFalse);
    expect(game.debugIsGameplayInputLocked, isFalse);
    expect(game.debugCinematicFadeOpacity, isNull);
    expect(game.debugCameraWorldTopLeft, originalCameraTopLeft);
    expect(game.debugPlayerGridPosition, originalPlayerPosition);
  });
}

final class _LifecycleTestPlayableMapGame extends PlayableMapGame {
  _LifecycleTestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
  });

  @override
  bool get isLoaded => true;
}

Future<void> _waitForInitialMapActivation(PlayableMapGame game) async {
  for (var i = 0; i < 100; i++) {
    if (!game.debugIsMapActivationDispatchInFlight) return;
    game.update(0);
    await Future<void>.value();
  }
  fail('Initial map activation did not settle.');
}

Future<void> _waitUntil(
  PlayableMapGame game,
  bool Function() condition,
) async {
  for (var i = 0; i < 100; i++) {
    if (condition()) return;
    game.update(0);
    await Future<void>.value();
  }
  fail('Runtime condition did not settle.');
}

RuntimeMapBundle _bundle() {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Cinematic runtime integration',
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'map_port',
          name: 'Port',
          relativePath: 'maps/port.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      cinematics: <CinematicAsset>[_cinematic()],
      scenes: <SceneAsset>[_scene()],
      surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    ),
    map: const MapData(
      id: 'map_port',
      name: 'Port',
      size: GridSize(width: 20, height: 15),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn_start',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn_start'),
    ),
    projectRootDirectory: '/tmp/cinematic_runtime',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

CinematicAsset _cinematic() {
  return CinematicAsset(
    id: 'cinematic_lighthouse',
    title: 'Lighthouse reveal',
    mapId: 'map_port',
    stageContext: CinematicStageContext(
      stagePoints: <CinematicStagePoint>[
        CinematicStagePoint(
          id: 'lighthouse',
          label: 'Phare',
          x: 15,
          y: 10,
        ),
      ],
    ),
    timeline: CinematicTimeline(
      steps: <CinematicTimelineStep>[
        CinematicTimelineStep(
          id: 'focus_lighthouse',
          kind: CinematicTimelineStepKind.camera,
          durationMs: 100,
          metadata: const <String, String>{
            cinematicTimelineCameraModeMetadataKey: 'focus',
            cinematicTimelineCameraTargetKindMetadataKey: 'stagePoint',
            cinematicTimelineCameraTargetStagePointIdMetadataKey: 'lighthouse',
            cinematicTimelineCameraZoomPresetMetadataKey: 'close',
          },
        ),
        CinematicTimelineStep(
          id: 'line',
          kind: CinematicTimelineStepKind.dialogueLine,
          dialogueText: 'Le phare nous attend.',
        ),
        CinematicTimelineStep(
          id: 'fade_out',
          kind: CinematicTimelineStepKind.fade,
          durationMs: 100,
          metadata: const <String, String>{
            cinematicTimelineFadeModeMetadataKey: 'fadeOut',
          },
        ),
      ],
    ),
  );
}

SceneAsset _scene() {
  return SceneAsset(
    id: 'scene_cinematic_runtime',
    name: 'Cinematic runtime Scene',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'cinematic',
          kind: SceneNodeKind.cinematic,
          payload: SceneCinematicPayload(cinematicId: 'cinematic_lighthouse'),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_cinematic',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'cinematic',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'cinematic_to_end',
          fromNodeId: 'cinematic',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.cinematicCompleted,
        ),
      ],
    ),
  );
}
~~~~~~

### `packages/map_runtime/test/playable_map_game_dialogue_outcome_scene_integration_test.dart`

- Taille : `16882` octets
- SHA-256 : `f38a0ecd128ec8d2239450c4d72a8e654981a8c08c2947ffb653c7af74b4f89a`

~~~~~~dart
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

const _mapId = 'dialogue_outcome_scene_map';
const _dialogueId = 'dialogue_outcome_scene_dialogue';
const _sceneId = 'dialogue_outcome_scene';
const _eventId = 'evt_019abcde-6200-7000-8000-000000000001';
const _entityId = 'dialogue_outcome_scene_entity';
const _acceptedFactId = 'fact.dialogue_outcome_scene.accepted';
const _acceptedOutcomeId = 'accepted';
const _refusedOutcomeId = 'refused';
const _acceptedSceneOutcomeId = 'route.accepted';
const _refusedSceneOutcomeId = 'route.refused';
const _completedSceneOutcomeId = 'route.completed';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayableMapGame Yarn outcome to direct Scene port', () {
    test('routes a real Yarn choice outcome to its declared Scene port',
        () async {
      final result = await _executeDialogueScene('''
title: Start
---
-> Accepter
    <<outcome accepted>>
-> Refuser
    <<outcome refused>>
===
''');

      final completed = result as NarrativeSceneExecutionCompleted;
      expect(
        completed.qualifiedOutcomes,
        <NarrativeOutcomeRef>[
          NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.scene,
            producerId: _sceneId,
            outcomeId: _acceptedSceneOutcomeId,
          ),
        ],
      );
    });

    test('routes a dialogue without an outcome through completed', () async {
      final result = await _executeDialogueScene('''
title: Start
---
Guide: Continuons.
===
''');

      final completed = result as NarrativeSceneExecutionCompleted;
      expect(
        completed.qualifiedOutcomes,
        <NarrativeOutcomeRef>[
          NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.scene,
            producerId: _sceneId,
            outcomeId: _completedSceneOutcomeId,
          ),
        ],
      );
    });

    test('rejects an unknown Yarn outcome before Scene routing', () async {
      final result = await _executeDialogueScene('''
title: Start
---
-> Inconnu
    <<outcome unexpected>>
===
''');

      expect(result, isA<NarrativeSceneExecutionFailed>());
      expect(
        (result as NarrativeSceneExecutionFailed).failure.toString(),
        contains('unsupported outcome "unexpected"'),
      );
    });

    test(
      'persists a consumed one-shot Event and does not replay its Yarn branch',
      () async {
        final projectRoot = await Directory.systemTemp.createTemp(
          'dialogue_outcome_event_v2_',
        );
        try {
          final yarnFile = File.fromUri(
            projectRoot.uri.resolve('dialogues/dialogue_outcome_scene.yarn'),
          );
          await yarnFile.parent.create(recursive: true);
          await yarnFile.writeAsString('''
title: Start
---
-> Accepter
    <<outcome accepted>>
-> Refuser
    <<outcome refused>>
===
''');

          final bundle = RuntimeMapBundle(
            manifest: _eventProject(),
            map: _eventMap(),
            projectRootDirectory: projectRoot.path,
            tilesetAbsolutePathsById: const <String, String>{},
          );
          final repository = _MemoryGameSaveRepository();
          var entityInteractionPreparationCount = 0;
          final game = _DialogueOutcomeSceneTestGame(
            bundle: bundle,
            projectFilePath:
                File.fromUri(projectRoot.uri.resolve('project.json')).path,
            saveData: saveDataFromGameState(_initialState()),
            saveRepository: repository,
            runtimeMapBundleLoader: ({
              required String projectFilePath,
              required String mapId,
            }) async {
              expect(mapId, _mapId);
              return bundle;
            },
            beforeNarrativeAuthorityPreparation: (occurrence) async {
              if (occurrence.source ==
                  NarrativeEventSourceRef.entityInteract(
                    _mapId,
                    _entityId,
                  )) {
                entityInteractionPreparationCount++;
              }
            },
          );

          game.onGameResize(Vector2(320, 240));
          await game.onLoad();
          await _waitUntil(
            game,
            () => !game.debugIsMapActivationDispatchInFlight,
          );

          expect(
            game.handleRuntimeInputEvent(
              const RuntimeInputEvent.press(RuntimeInputControl.primary),
            ),
            isTrue,
          );
          await _waitUntil(game, () => game.debugFlowPhaseName == 'dialogue');
          expect(
            game.handleRuntimeInputEvent(
              const RuntimeInputEvent.press(RuntimeInputControl.primary),
            ),
            isTrue,
          );
          await _waitUntil(
            game,
            () =>
                game.gameStateSnapshot.narrativeEventProgress
                    .consumedNarrativeEventIds
                    .contains(_eventId) &&
                !game.debugIsNarrativeSpatialDispatchInFlight &&
                !game.debugIsNarrativeOutcomeWorkInFlight,
          );

          expect(entityInteractionPreparationCount, 1);
          expect(
            game.gameStateSnapshot.narrativeFactRuntimeState
                .overridesByFactId[_acceptedFactId],
            isTrue,
            reason: 'The selected Yarn outcome must traverse the accepted '
                'Scene branch before the Event is consumed.',
          );
          expect(await game.saveGame(), isTrue);
          expect(repository.storedState, isNotNull);

          expect(await game.loadGame(), isTrue);
          await _waitUntil(
            game,
            () => !game.debugIsMapActivationDispatchInFlight,
          );
          expect(
            game.gameStateSnapshot.narrativeEventProgress
                .consumedNarrativeEventIds,
            contains(_eventId),
          );

          expect(
            game.handleRuntimeInputEvent(
              const RuntimeInputEvent.press(RuntimeInputControl.primary),
            ),
            isTrue,
          );
          await _waitUntil(
            game,
            () =>
                entityInteractionPreparationCount == 2 &&
                !game.debugIsNarrativeSpatialDispatchInFlight &&
                !game.debugIsNarrativeOutcomeWorkInFlight,
          );

          expect(game.debugFlowPhaseName, 'overworld');
          expect(game.debugHasPendingDialogueLoad, isFalse);
          expect(
            game.gameStateSnapshot.narrativeFactRuntimeState
                .overridesByFactId[_acceptedFactId],
            isTrue,
          );
        } finally {
          await projectRoot.delete(recursive: true);
        }
      },
    );
  });
}

Future<NarrativeSceneExecutionResult> _executeDialogueScene(
  String yarnSource,
) async {
  final projectRoot = await Directory.systemTemp.createTemp(
    'dialogue_outcome_scene_',
  );
  try {
    final yarnFile = File.fromUri(
      projectRoot.uri.resolve('dialogues/dialogue_outcome_scene.yarn'),
    );
    await yarnFile.parent.create(recursive: true);
    await yarnFile.writeAsString(yarnSource);

    final game = _DialogueOutcomeSceneTestGame(
      bundle: RuntimeMapBundle(
        manifest: _project(),
        map: _map(),
        projectRootDirectory: projectRoot.path,
        tilesetAbsolutePathsById: const <String, String>{},
      ),
      projectFilePath:
          File.fromUri(projectRoot.uri.resolve('project.json')).path,
      saveData: saveDataFromGameState(_initialState()),
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitUntil(
      game,
      () => !game.debugIsMapActivationDispatchInFlight,
    );

    final execution = game.debugExecuteNarrativeSceneForTest(
      NarrativeSceneExecutionRequest(
        eventId: 'event_dialogue_outcome_scene',
        sceneId: _sceneId,
        executionId: 'execution_dialogue_outcome_scene',
        gameState: game.gameStateSnapshot,
      ),
    );
    await _waitUntil(game, () => game.debugFlowPhaseName == 'dialogue');

    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );

    return await execution.timeout(const Duration(seconds: 2));
  } finally {
    await projectRoot.delete(recursive: true);
  }
}

ProjectManifest _project() => ProjectManifest(
      name: 'PlayableMapGame dialogue outcome Scene integration',
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: _mapId,
          name: 'Dialogue Outcome Scene Map',
          relativePath: 'maps/dialogue_outcome_scene_map.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      dialogues: const <ProjectDialogueEntry>[
        ProjectDialogueEntry(
          id: _dialogueId,
          name: 'Dialogue Outcome Scene Dialogue',
          relativePath: 'dialogues/dialogue_outcome_scene.yarn',
          declaredOutcomes: <DialogueDeclaredOutcome>[
            DialogueDeclaredOutcome(
              id: _acceptedOutcomeId,
              label: 'Accepté',
            ),
            DialogueDeclaredOutcome(
              id: _refusedOutcomeId,
              label: 'Refusé',
            ),
          ],
        ),
      ],
      scenes: <SceneAsset>[_scene()],
      surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    );

ProjectManifest _eventProject() => _project().copyWith(
      name: 'PlayableMapGame Event V2 dialogue outcome integration',
      facts: <NarrativeFactDefinition>[
        NarrativeFactDefinition(
          id: _acceptedFactId,
          label: 'Accepted branch reached',
        ),
      ],
      scenes: <SceneAsset>[_scene(recordAcceptedFact: true)],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: <NarrativeEventRecord>[
          NarrativeEventRecord.configuredStructurallyUnchecked(
            NarrativeEventDefinition(
              id: _eventId,
              name: 'One-shot dialogue outcome event',
              source: NarrativeEventSourceRef.entityInteract(
                _mapId,
                _entityId,
              ),
              conditions: const <NarrativeEventCondition>[],
              sceneId: _sceneId,
              reusePolicy: NarrativeEventReusePolicy.oneShot,
              priority: 0,
              order: 0,
            ),
            enabled: true,
          ),
        ],
        legacyClaims: const <LegacySourceClaim>[],
      ),
    );

SceneAsset _scene({bool recordAcceptedFact = false}) => SceneAsset(
      id: _sceneId,
      name: 'Dialogue Outcome Scene',
      declaredOutcomes: <SceneOutcome>[
        SceneOutcome(
          id: _acceptedSceneOutcomeId,
          label: 'Accepted route',
        ),
        SceneOutcome(
          id: _completedSceneOutcomeId,
          label: 'Completed route',
        ),
        SceneOutcome(
          id: _refusedSceneOutcomeId,
          label: 'Refused route',
        ),
      ],
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'dialogue',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(
              dialogueId: _dialogueId,
              yarnNodeName: 'Start',
              expectedOutcomes: const <String>[
                _acceptedOutcomeId,
                _refusedOutcomeId,
              ],
            ),
          ),
          if (recordAcceptedFact)
            SceneNode(
              id: 'accepted_fact',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.setFact(
                  factId: _acceptedFactId,
                  value: true,
                ),
              ),
            ),
          SceneNode(
            id: 'accepted_end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(
              sceneOutcomeId: _acceptedSceneOutcomeId,
            ),
          ),
          SceneNode(
            id: 'completed_end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(
              sceneOutcomeId: _completedSceneOutcomeId,
            ),
          ),
          SceneNode(
            id: 'refused_end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(
              sceneOutcomeId: _refusedSceneOutcomeId,
            ),
          ),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'start_to_dialogue',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'dialogue',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'dialogue_accepted',
            fromNodeId: 'dialogue',
            fromPortId: _acceptedOutcomeId,
            toNodeId: recordAcceptedFact ? 'accepted_fact' : 'accepted_end',
            kind: SceneEdgeKind.dialogueOutcome,
          ),
          if (recordAcceptedFact)
            SceneEdge(
              id: 'accepted_fact_to_end',
              fromNodeId: 'accepted_fact',
              fromPortId: 'completed',
              toNodeId: 'accepted_end',
              kind: SceneEdgeKind.actionCompleted,
            ),
          SceneEdge(
            id: 'dialogue_completed',
            fromNodeId: 'dialogue',
            fromPortId: 'completed',
            toNodeId: 'completed_end',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'dialogue_refused',
            fromNodeId: 'dialogue',
            fromPortId: _refusedOutcomeId,
            toNodeId: 'refused_end',
            kind: SceneEdgeKind.dialogueOutcome,
          ),
        ],
      ),
    );

MapData _map() => const MapData(
      id: _mapId,
      name: 'Dialogue Outcome Scene Map',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    );

MapData _eventMap() => const MapData(
      id: _mapId,
      name: 'Dialogue Outcome Event V2 Map',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
        MapEntity(
          id: _entityId,
          name: 'Dialogue outcome target',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 1, y: 2),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    );

GameState _initialState() => const GameState(
      saveId: 'dialogue-outcome-scene-save',
      currentMapId: _mapId,
      playerPosition: GridPos(x: 1, y: 1),
    );

Future<void> _waitUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 240,
}) async {
  for (var tick = 0; tick < maxTicks; tick++) {
    if (done()) return;
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail(
    'Timed out waiting for PlayableMapGame dialogue outcome integration: '
    'phase=${game.debugFlowPhaseName} '
    'activation=${game.debugIsMapActivationDispatchInFlight}.',
  );
}

final class _DialogueOutcomeSceneTestGame extends PlayableMapGame {
  _DialogueOutcomeSceneTestGame({
    required super.bundle,
    required super.projectFilePath,
    super.saveData,
    super.saveRepository,
    super.runtimeMapBundleLoader,
    super.beforeNarrativeAuthorityPreparation,
  });

  @override
  bool get isLoaded => true;
}

final class _MemoryGameSaveRepository implements GameSaveRepository {
  GameState? storedState;

  @override
  Future<void> save(GameState state) async {
    storedState = state;
  }

  @override
  Future<GameState?> load() async => storedState;

  @override
  Future<bool> exists() async => storedState != null;

  @override
  Future<void> delete() async {
    storedState = null;
  }
}
~~~~~~

### `packages/map_runtime/test/playable_map_game_project_new_game_boot_test.dart`

- Taille : `4036` octets
- SHA-256 : `5cec25102a23813111c939b74676c4828d3bd61bc9c53d306d3c8435c268578e`

~~~~~~dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('no-save boot uses the project newGame contract through onLoad',
      () async {
    final game = PlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/project_new_game/project.json',
    );

    expect(game.gameStateSnapshot.currentMapId, 'new_game_map');
    expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 5, y: 6));
    expect(game.gameStateSnapshot.playerFacing, EntityFacing.north);
    expect(game.gameStateSnapshot.trainerProfile.money, 420);
    expect(game.gameStateSnapshot.bag.entries.single.itemId, 'potion');
    expect(
      game.gameStateSnapshot.narrativeFactRuntimeState
          .overridesByFactId['fact_existing_party'],
      isFalse,
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();

    expect(game.gameStateSnapshot.currentMapId, 'new_game_map');
    expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 5, y: 6));
    expect(game.gameStateSnapshot.playerFacing, EntityFacing.north);
  });

  test('an explicit save remains authoritative over newGame config', () {
    const saved = GameState(
      saveId: 'existing_save',
      currentMapId: 'new_game_map',
      playerPosition: GridPos(x: 2, y: 3),
      playerFacing: EntityFacing.west,
      trainerProfile: TrainerProfile(name: 'Sauvegarde', money: 999),
    );
    final game = PlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/project_new_game/project.json',
      saveData: saveDataFromGameState(saved),
      initialMapActivationReason: MapActivationReason.saveRestore,
    );

    expect(game.gameStateSnapshot.saveId, 'existing_save');
    expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 2, y: 3));
    expect(game.gameStateSnapshot.trainerProfile.money, 999);
  });
}

RuntimeMapBundle _bundle() {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'New Game Project',
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'new_game_map',
          name: 'New game map',
          relativePath: 'maps/new_game_map.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      facts: <NarrativeFactDefinition>[
        NarrativeFactDefinition(
          id: 'fact_existing_party',
          label: 'Équipe existante',
        ),
      ],
      newGame: const ProjectNewGameConfig(
        enabled: true,
        startMapId: 'new_game_map',
        startSpawnId: 'spawn_new_game',
        playerName: 'Joueur',
        startingMoney: 420,
        initialBag: <BagEntry>[
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
        ],
        existingPartyFactId: 'fact_existing_party',
      ),
      surfaceCatalog: ProjectSurfaceCatalog(),
    ),
    map: const MapData(
      id: 'new_game_map',
      name: 'New game map',
      size: GridSize(width: 10, height: 10),
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn_default'),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn_default',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          spawn: MapEntitySpawnData(
            spawnKey: 'spawn_default',
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
        MapEntity(
          id: 'spawn_new_game',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 5, y: 6),
          spawn: MapEntitySpawnData(
            spawnKey: 'spawn_new_game',
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.north,
          ),
        ),
      ],
    ),
    projectRootDirectory: '/tmp/project_new_game',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}
~~~~~~

### `packages/map_runtime/test/playable_map_game_world_state_v1_integration_test.dart`

- Taille : `6612` octets
- SHA-256 : `6288f838e21e8382e498725d6500979d9678c5c360d7ef0e48e4af1a9087bf72`

~~~~~~dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayableMapGame World State V1', () {
    test('a matching World Rule removes a blocking non-NPC map entity',
        () async {
      final game = _TestPlayableMapGame(
        bundle: _bundle(
          facts: <NarrativeFactDefinition>[
            NarrativeFactDefinition(
              id: 'fact_gate_open',
              label: 'Gate open',
              defaultValue: true,
            ),
          ],
          worldRules: <WorldRuleDefinition>[
            _hideBarrierRule(
              source: const WorldRuleSource(
                kind: WorldRuleSourceKind.fact,
                sourceId: 'fact_gate_open',
                predicate: WorldRuleSourcePredicate.isTrue,
              ),
            ),
          ],
        ),
      );

      await _load(game);
      await _moveRight(game);

      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 0));
    });

    test('save/load preserves the Story Step projection that opens a route',
        () async {
      final storyline = StorylineAsset(
        id: 'storyline_route',
        type: StorylineType.main,
        title: 'Route',
        chapters: <StorylineChapter>[
          StorylineChapter(
            id: 'chapter_route',
            title: 'Route',
            order: 0,
            steps: <StorylineStep>[
              StorylineStep(
                id: 'step_gate_open',
                title: 'Open the gate',
                order: 0,
              ),
            ],
          ),
        ],
      );
      final bundle = _bundle(
        storylines: <StorylineAsset>[storyline],
        worldRules: <WorldRuleDefinition>[
          _hideBarrierRule(
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.storyStepCompletion,
              sourceId: 'step_gate_open',
              predicate: WorldRuleSourcePredicate.completed,
            ),
          ),
        ],
      );
      final lockedGame = _TestPlayableMapGame(bundle: bundle);
      await _load(lockedGame);
      await _moveRight(lockedGame);
      expect(lockedGame.debugPlayerGridPosition, const GridPos(x: 0, y: 0));

      const completed = GameState(
        saveId: 'world-state-save',
        currentMapId: 'map_world_state',
        playerPosition: GridPos(x: 0, y: 0),
        playerFacing: EntityFacing.east,
        progression: PlayerProgression(
          completedStepIds: <String>['step_gate_open'],
        ),
      );
      final restoredState = gameStateFromSaveData(
        SaveData.fromJson(saveDataFromGameState(completed).toJson()),
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        saveData: saveDataFromGameState(restoredState),
        initialMapActivationReason: MapActivationReason.saveRestore,
      );

      await _load(game);
      await _moveRight(game);

      expect(
        game.gameStateSnapshot.progression.completedStepIds,
        contains('step_gate_open'),
      );
      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 0));
    });
  });
}

WorldRuleDefinition _hideBarrierRule({required WorldRuleSource source}) {
  return WorldRuleDefinition(
    id: 'world_rule_hide_barrier',
    label: 'Open route',
    source: source,
    target: const WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEntity,
      mapId: 'map_world_state',
      entityId: 'route_barrier',
    ),
    effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
  );
}

RuntimeMapBundle _bundle({
  List<NarrativeFactDefinition> facts = const <NarrativeFactDefinition>[],
  List<StorylineAsset> storylines = const <StorylineAsset>[],
  List<WorldRuleDefinition> worldRules = const <WorldRuleDefinition>[],
}) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'World State V1',
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'map_world_state',
          name: 'World state',
          relativePath: 'maps/world_state.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      facts: facts,
      storylines: storylines,
      worldRules: worldRules,
      surfaceCatalog: ProjectSurfaceCatalog(),
    ),
    map: const MapData(
      id: 'map_world_state',
      name: 'World state',
      size: GridSize(width: 3, height: 2),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
        MapEntity(
          id: 'route_barrier',
          name: 'Closed route',
          kind: MapEntityKind.item,
          pos: GridPos(x: 1, y: 0),
          blocksMovement: true,
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    ),
    projectRootDirectory: '/tmp/world_state_v1',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    super.saveData,
    super.initialMapActivationReason,
  }) : super(projectFilePath: '/tmp/world_state_v1/project.json');

  @override
  bool get isLoaded => true;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (var i = 0; i < 240; i++) {
      if (!debugIsMapActivationDispatchInFlight) {
        return;
      }
      await Future<void>.delayed(Duration.zero);
    }
    fail('Timed out waiting for the initial map activation dispatch.');
  }
}

Future<void> _load(_TestPlayableMapGame game) async {
  game.onGameResize(Vector2(640, 480));
  await game.onLoad();
}

Future<void> _moveRight(_TestPlayableMapGame game) async {
  expect(
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.right),
    ),
    isTrue,
  );
  game.update(0.016);
  expect(
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.release(RuntimeInputControl.right),
    ),
    isTrue,
  );
  for (var i = 0; i < 240; i++) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
    if (!game.debugIsPlayerStepping && !game.debugHasPendingMapTransition) {
      return;
    }
  }
  fail('Timed out waiting for movement.');
}
~~~~~~

### `packages/map_runtime/test/selbrume_event_v2_trigger_battle_anchor_integration_test.dart`

- Taille : `7270` octets
- SHA-256 : `dd80c2b110d8aaf997ed2cc26c95544c4adfaa5b5fd4a2a07817e141eb593673`

~~~~~~dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/selbrume_event_v2_test_fixture.dart';

const _guardianEventId = 'evt_019abcde-5000-7000-8000-000000000026';
const _guardianTriggerId = 'tr_phare_guardian_1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Event V2 trigger anchors a trainer Scene that omits npcEntityId',
    () async {
      final fixture = SelbrumeEventV2RuntimeFixture.locateCanonical();
      final source = await loadRuntimeMapBundle(
        projectFilePath: fixture.projectPath,
        mapId: 'map_phare_interieur',
      );
      final bundle = _guardianHarnessBundle(source);
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: fixture.projectPath,
        saveData: saveDataFromGameState(
          GameState(
            saveId: 'selbrume_event_v2_trigger_battle_anchor',
            currentMapId: 'map_phare_interieur',
            playerPosition: const GridPos(x: 8, y: 31),
            playerFacing: EntityFacing.south,
            party: const PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'charmander',
                  natureId: 'hardy',
                  abilityId: 'blaze',
                  level: 100,
                  knownMoveIds: <String>['ember'],
                  currentHp: 999,
                ),
              ],
            ),
            narrativeFactRuntimeState: NarrativeFactRuntimeState(
              overridesByFactId: const <String, bool>{
                'fact_lighthouse_old_note_read': true,
              },
            ),
          ),
        ),
        initialMapActivationReason: MapActivationReason.saveRestore,
      );

      await _load(game);
      expect(
        game.gameStateSnapshot.narrativeFactRuntimeState
            .overridesByFactId['fact_lighthouse_old_note_read'],
        isTrue,
      );
      await _move(game, RuntimeInputControl.down);
      expect(game.debugPlayerGridPosition, const GridPos(x: 8, y: 32));
      await _pumpUntil(
        game,
        () =>
            game.debugFlowPhaseName != 'overworld' ||
            game.debugNotificationText != null,
      );
      expect(
        game.debugFlowPhaseName,
        'battleTransition',
        reason: game.debugNotificationText,
      );
      await _pumpUntil(game, () => game.debugFlowPhaseName == 'battle');
      await game.debugWaitForBattleOverlaySync();

      final battle = game.debugBattleSessionSnapshot;
      expect(battle, isNotNull);
      expect(battle!.setup.isTrainerBattle, isTrue);
      expect(battle.setup.trainerId, 'trainer_phare_gardien_1');
      expect(battle.state.enemy.speciesId, 'magnemite');

      await _chooseFirstMoveUntilBattleEnds(game);
      await _pumpUntil(
        game,
        () =>
            game.debugFlowPhaseName == 'overworld' &&
            game.gameStateSnapshot.narrativeFactRuntimeState
                    .overridesByFactId['fact_lighthouse_guardian_1_defeated'] ==
                true,
      );

      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        contains(_guardianEventId),
      );
    },
  );
}

RuntimeMapBundle _guardianHarnessBundle(RuntimeMapBundle source) {
  const spawnId = 'selbrume_guardian_anchor_test_spawn';
  final map = source.map.copyWith(
    entities: <MapEntity>[
      for (final entity in source.map.entities)
        if (entity.kind != MapEntityKind.spawn) entity,
      const MapEntity(
        id: spawnId,
        name: 'Guardian anchor integration spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 8, y: 31),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.south,
        ),
      ),
    ],
    mapMetadata: source.map.mapMetadata.copyWith(defaultSpawnId: spawnId),
  );
  expect(
    map.triggers.where((trigger) => trigger.id == _guardianTriggerId),
    hasLength(1),
  );
  return RuntimeMapBundle(
    manifest: source.manifest,
    map: map,
    projectRootDirectory: source.projectRootDirectory,
    tilesetAbsolutePathsById: source.tilesetAbsolutePathsById,
  );
}

Future<void> _load(_TestPlayableMapGame game) async {
  game.onGameResize(Vector2(640, 480));
  await game.onLoad();
  await _pumpUntil(game, () => !game.debugIsMapActivationDispatchInFlight);
}

Future<void> _move(
  PlayableMapGame game,
  RuntimeInputControl control,
) async {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  game.update(0.016);
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control)),
    isTrue,
  );
  await _pumpUntil(game, () => !game.debugIsPlayerStepping);
}

Future<void> _chooseFirstMoveUntilBattleEnds(PlayableMapGame game) async {
  for (var turn = 0; turn < 20; turn++) {
    if (game.debugFlowPhaseName != 'battle') return;
    await _waitForBattleInputReady(game);
    if (game.debugFlowPhaseName != 'battle') return;
    final overlay = game.debugBattleOverlayComponent;
    expect(overlay, isNotNull);
    final activeOverlay = overlay!;
    if (activeOverlay.currentMenuMode.name == 'continueOnly') {
      _pressPrimary(game);
      await _waitForBattleInputReady(game);
      continue;
    }
    for (var back = 0;
        back < 3 && activeOverlay.currentMenuMode.name != 'root';
        back++) {
      expect(game.backFromBattleOverlay(), isTrue);
      await _microPump(game);
    }
    expect(activeOverlay.currentMenuMode.name, 'root');
    _pressPrimary(game);
    await _microPump(game);
    expect(activeOverlay.currentMenuMode.name, 'fight');
    _pressPrimary(game);
    await _waitForBattleInputReady(game);
  }
  fail('The canonical guardian battle exceeded 20 real turns.');
}

Future<void> _waitForBattleInputReady(PlayableMapGame game) async {
  await game.debugWaitForBattleOverlaySync();
  await _pumpUntil(
    game,
    () =>
        game.debugFlowPhaseName != 'battle' ||
        !(game.debugBattleOverlayComponent?.isTurnPresentationActive ?? false),
  );
}

void _pressPrimary(PlayableMapGame game) {
  expect(
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.primary),
    ),
    isTrue,
  );
}

Future<void> _microPump(PlayableMapGame game) async {
  game.update(0.016);
  await Future<void>.delayed(Duration.zero);
}

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 3000,
}) async {
  for (var tick = 0; tick < maxTicks; tick++) {
    if (done()) return;
    game.update(0.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail(
    'Timed out in Event V2 trigger battle anchor integration '
    '(phase=${game.debugFlowPhaseName}, '
    'notification=${game.debugNotificationText}).',
  );
}

final class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    required super.saveData,
    required super.initialMapActivationReason,
  });

  @override
  bool get isLoaded => true;
}
~~~~~~

### `packages/map_runtime/test/selbrume_new_game_starter_integration_test.dart`

- Taille : `9009` octets
- SHA-256 : `0f6ab2a2db2193ef2dd694f254686c511d4b8cb15b3e167d1386fb21a263cdf3`

~~~~~~dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/selbrume_event_v2_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'canonical no-save boot gives the selected starter exactly once',
    () async {
      final fixture = SelbrumeEventV2RuntimeFixture.locateCanonical();
      final source = await loadRuntimeMapBundle(
        projectFilePath: fixture.projectPath,
        mapId: 'map_bourg_selbrume',
      );
      final bundle = _starterHarnessBundle(source);
      final repository = _MemoryGameSaveRepository();
      final maelEvent = bundle.manifest.eventRegistry!.records
          .map((record) => record.definitionOrNull)
          .whereType<NarrativeEventDefinition>()
          .singleWhere(
            (event) =>
                event.sceneId == 'scene_mael_intro' &&
                event.source ==
                    NarrativeEventSourceRef.entityInteract(
                      'map_bourg_selbrume',
                      'npc_mael',
                    ),
          );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: fixture.projectPath,
        saveRepository: repository,
        runtimeMapBundleLoader: ({
          required String projectFilePath,
          required String mapId,
        }) async {
          expect(projectFilePath, fixture.projectPath);
          if (mapId == 'map_bourg_selbrume') return bundle;
          return loadRuntimeMapBundle(
            projectFilePath: projectFilePath,
            mapId: mapId,
          );
        },
      );

      expect(game.gameStateSnapshot.party.members, isEmpty);
      expect(game.gameStateSnapshot.currentMapId, 'map_bourg_selbrume');

      game.onGameResize(Vector2(320, 240));
      await game.onLoad();
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );
      await _pumpUntil(game, () => game.debugFlowPhaseName == 'dialogue');
      await _completeOpenDialogue(game);
      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.narrativeEventProgress
                .consumedNarrativeEventIds
                .contains(maelEvent.id) &&
            !game.debugIsNarrativeSpatialDispatchInFlight,
      );

      final completed = game.gameStateSnapshot;
      expect(completed.party.members, hasLength(1));
      expect(completed.party.members.single.speciesId, 'bulbasaur');
      expect(
        completed.narrativeFactRuntimeState
            .overridesByFactId['fact_starter_received'],
        isTrue,
      );
      expect(
        completed.narrativeFactRuntimeState
            .overridesByFactId['fact_mael_mission_given'],
        isTrue,
      );
      expect(
        completed.progression.completedStepIds,
        containsAll(<String>['step_intro_selbrume', 'step_receive_mission']),
      );

      expect(await game.saveGame(), isTrue);
      expect(await game.loadGame(), isTrue);
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );
      await _pumpUntil(
        game,
        () => game.debugFlowPhaseName == 'dialogue',
      );
      await _completeOpenDialogue(game);
      await _pumpUntil(game, () => game.debugFlowPhaseName == 'overworld');

      expect(game.gameStateSnapshot.party.members, hasLength(1));
      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        contains(maelEvent.id),
      );
    },
  );

  test('canonical existing-party path skips starter and converges', () async {
    final fixture = SelbrumeEventV2RuntimeFixture.locateCanonical();
    final source = await loadRuntimeMapBundle(
      projectFilePath: fixture.projectPath,
      mapId: 'map_bourg_selbrume',
    );
    final bundle = _starterHarnessBundle(source);
    final game = _TestPlayableMapGame(
      bundle: bundle,
      projectFilePath: fixture.projectPath,
      saveData: saveDataFromGameState(
        GameState(
          saveId: 'existing_party',
          currentMapId: 'map_bourg_selbrume',
          playerPosition: const GridPos(x: 17, y: 24),
          playerFacing: EntityFacing.north,
          party: const PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'eevee',
                natureId: 'hardy',
                abilityId: 'run-away',
                level: 5,
                currentHp: 20,
              ),
            ],
          ),
          narrativeFactRuntimeState: NarrativeFactRuntimeState(
            overridesByFactId: const <String, bool>{
              'fact_player_started_with_existing_pokemon': true,
            },
          ),
        ),
      ),
      initialMapActivationReason: MapActivationReason.saveRestore,
      runtimeMapBundleLoader: ({
        required String projectFilePath,
        required String mapId,
      }) async {
        if (mapId == 'map_bourg_selbrume') return bundle;
        return loadRuntimeMapBundle(
          projectFilePath: projectFilePath,
          mapId: mapId,
        );
      },
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _pumpUntil(
      game,
      () => !game.debugIsMapActivationDispatchInFlight,
    );
    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );
    await _pumpUntil(game, () => game.debugFlowPhaseName == 'dialogue');
    await _completeOpenDialogue(game);
    await _pumpUntil(
      game,
      () =>
          game.gameStateSnapshot.narrativeFactRuntimeState
              .overridesByFactId['fact_mael_mission_given'] ==
          true,
    );

    final completed = game.gameStateSnapshot;
    expect(completed.party.members, hasLength(1));
    expect(completed.party.members.single.speciesId, 'eevee');
    expect(
      completed
          .narrativeFactRuntimeState.overridesByFactId['fact_starter_received'],
      isNot(isTrue),
    );
    expect(
      completed.progression.completedStepIds,
      containsAll(<String>['step_intro_selbrume', 'step_receive_mission']),
    );
  });
}

RuntimeMapBundle _starterHarnessBundle(RuntimeMapBundle source) {
  final map = source.map.copyWith(
    entities: <MapEntity>[
      for (final entity in source.map.entities)
        if (entity.id == 'spawn')
          entity.copyWith(
            pos: const GridPos(x: 17, y: 24),
            spawn: entity.spawn?.copyWith(facing: EntityFacing.north),
          )
        else if (entity.id == 'npc_mael')
          entity.copyWith(pos: const GridPos(x: 17, y: 23))
        else
          entity,
    ],
  );
  return RuntimeMapBundle(
    manifest: source.manifest,
    map: map,
    projectRootDirectory: source.projectRootDirectory,
    tilesetAbsolutePathsById: source.tilesetAbsolutePathsById,
  );
}

Future<void> _completeOpenDialogue(PlayableMapGame game) async {
  for (var advanceCount = 0; advanceCount < 20; advanceCount++) {
    if (game.debugFlowPhaseName != 'dialogue') return;
    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('The canonical Maël Yarn stayed open after 20 explicit inputs.');
}

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 2000,
}) async {
  for (var tick = 0; tick < maxTicks; tick++) {
    if (done()) return;
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail(
    'Timed out in canonical starter integration: '
    'phase=${game.debugFlowPhaseName}.',
  );
}

final class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    super.saveData,
    super.saveRepository,
    super.runtimeMapBundleLoader,
    super.initialMapActivationReason,
  });

  bool _loadedForTest = false;

  @override
  bool get isLoaded => _loadedForTest;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _loadedForTest = true;
  }
}

final class _MemoryGameSaveRepository implements GameSaveRepository {
  GameState? storedState;

  @override
  Future<void> save(GameState state) async => storedState = state;

  @override
  Future<GameState?> load() async => storedState;

  @override
  Future<bool> exists() async => storedState != null;

  @override
  Future<void> delete() async => storedState = null;
}
~~~~~~

### `packages/map_runtime/test/selbrume_static_boss_playable_map_game_integration_test.dart`

- Taille : `7349` octets
- SHA-256 : `a153a0f928e31b6e0e156873c1896d5a40d5a3b97a500ede8c0897551c9f223d`

~~~~~~dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/selbrume_event_v2_test_fixture.dart';

const _bossEventId = 'evt_019abcde-5000-7000-8000-000000000028';
const _bossTriggerId = 'tr_sommet_confrontation';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'canonical lighthouse boss uses the PlayableMapGame static battle pipeline',
    () async {
      final fixture = SelbrumeEventV2RuntimeFixture.locateCanonical();
      final source = await loadRuntimeMapBundle(
        projectFilePath: fixture.projectPath,
        mapId: 'map_sommet_phare',
      );
      final bundle = _bossHarnessBundle(source);
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: fixture.projectPath,
        saveData: saveDataFromGameState(
          GameState(
            saveId: 'selbrume_static_boss_pipeline',
            currentMapId: 'map_sommet_phare',
            playerPosition: const GridPos(x: 12, y: 11),
            playerFacing: EntityFacing.north,
            party: const PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'bulbasaur',
                  natureId: 'hardy',
                  abilityId: 'overgrow',
                  level: 100,
                  knownMoveIds: <String>['tackle'],
                  currentHp: 999,
                ),
              ],
            ),
            narrativeFactRuntimeState: NarrativeFactRuntimeState(
              overridesByFactId: const <String, bool>{
                'fact_lighthouse_top_unlocked': true,
                'fact_lighthouse_guardian_2_defeated': true,
              },
            ),
          ),
        ),
        initialMapActivationReason: MapActivationReason.saveRestore,
      );

      await _load(game);
      await _move(game, RuntimeInputControl.up);
      await _pumpUntil(
        game,
        () => game.debugFlowPhaseName == 'dialogue',
      );
      await _completeOpenDialogue(game);
      await _pumpUntil(
        game,
        () => game.debugFlowPhaseName == 'battleTransition',
      );

      await _pumpUntil(game, () => game.debugFlowPhaseName == 'battle');
      await game.debugWaitForBattleOverlaySync();

      final battle = game.debugBattleSessionSnapshot;
      expect(battle, isNotNull);
      expect(battle!.setup.isTrainerBattle, isFalse);
      expect(battle.setup.allowCapture, isFalse);
      expect(battle.setup.allowFlee, isFalse);
      expect(battle.setup.trainerId, isNull);
      expect(battle.state.enemy.speciesId, 'lanturn');
      expect(
        battle.decisionRequest.allowedChoices
            .whereType<PlayerBattleChoiceRun>(),
        isEmpty,
      );
      expect(
        () => battle.applyChoice(const PlayerBattleChoiceRun()),
        throwsA(isA<StateError>()),
      );

      await _chooseFirstMoveUntilBattleEnds(game);
      await _pumpUntil(
        game,
        () =>
            game.debugFlowPhaseName == 'overworld' &&
            game.gameStateSnapshot.narrativeFactRuntimeState
                    .overridesByFactId['fact_mist_source_resolved'] ==
                true,
      );

      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        contains(_bossEventId),
      );
      expect(
        game.gameStateSnapshot.storyFlags.activeFlags,
        isNot(contains('trainer_defeated:trainer_boss_phare_pokemon')),
        reason: 'A static boss must not be written back as a defeated trainer.',
      );
    },
  );
}

RuntimeMapBundle _bossHarnessBundle(RuntimeMapBundle source) {
  const spawnId = 'selbrume_static_boss_test_spawn';
  final map = source.map.copyWith(
    entities: <MapEntity>[
      for (final entity in source.map.entities)
        if (entity.kind != MapEntityKind.spawn) entity,
      const MapEntity(
        id: spawnId,
        name: 'Static boss integration spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 12, y: 11),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.north,
        ),
      ),
    ],
    mapMetadata: source.map.mapMetadata.copyWith(defaultSpawnId: spawnId),
  );
  expect(
    map.triggers.where((trigger) => trigger.id == _bossTriggerId),
    hasLength(1),
  );
  return RuntimeMapBundle(
    manifest: source.manifest,
    map: map,
    projectRootDirectory: source.projectRootDirectory,
    tilesetAbsolutePathsById: source.tilesetAbsolutePathsById,
  );
}

Future<void> _load(_TestPlayableMapGame game) async {
  game.onGameResize(Vector2(640, 480));
  await game.onLoad();
  await _pumpUntil(game, () => !game.debugIsMapActivationDispatchInFlight);
}

Future<void> _move(
  PlayableMapGame game,
  RuntimeInputControl control,
) async {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  game.update(0.016);
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control)),
    isTrue,
  );
  await _pumpUntil(game, () => !game.debugIsPlayerStepping);
}

Future<void> _completeOpenDialogue(PlayableMapGame game) async {
  for (var inputCount = 0; inputCount < 20; inputCount++) {
    if (game.debugFlowPhaseName != 'dialogue') return;
    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('The canonical boss Yarn stayed open after 20 explicit inputs.');
}

Future<void> _chooseFirstMoveUntilBattleEnds(PlayableMapGame game) async {
  for (var turn = 0; turn < 80; turn++) {
    if (game.debugFlowPhaseName != 'battle') return;
    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );
    await game.debugWaitForBattleOverlaySync();
    if (game.debugFlowPhaseName != 'battle') return;
    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );
    await game.debugWaitForBattleOverlaySync();
    await _pumpUntil(
      game,
      () {
        if (game.debugFlowPhaseName != 'battle') return true;
        final overlay = game.debugBattleOverlayComponent;
        return overlay != null && !overlay.isTurnPresentationActive;
      },
    );
  }
  fail('The canonical static boss battle exceeded 80 real turns.');
}

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 3000,
}) async {
  for (var tick = 0; tick < maxTicks; tick++) {
    if (done()) return;
    game.update(0.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail(
    'Timed out in static boss PlayableMapGame integration '
    '(phase=${game.debugFlowPhaseName}).',
  );
}

final class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    required super.saveData,
    required super.initialMapActivationReason,
  });

  @override
  bool get isLoaded => true;
}
~~~~~~

### `packages/map_runtime/test/static_battle_start_request_test.dart`

- Taille : `2150` octets
- SHA-256 : `21d32228f18fc782ed04d780e64a714e8310094e57aaad2f73a5db86af3d502f`

~~~~~~dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('static boss request has an explicit non-trainer runtime identity', () {
    const request = StaticBattleStartRequest(
      requestId: 'static:lanturn:1',
      createdAtEpochMs: 1234,
      returnContext: OverworldReturnContext(
        mapId: 'map_sommet_phare',
        playerPos: GridPos(x: 8, y: 8),
        playerFacing: Direction.north,
      ),
      battleId: 'battle_lighthouse_pokemon',
      opponentProfileId: 'trainer_boss_phare_pokemon',
      entityId: 'boss_phare_pokemon',
      mapId: 'map_sommet_phare',
      playerPos: GridPos(x: 8, y: 8),
    );

    expect(request.kind, RuntimeBattleKind.staticEncounter);
    expect(request.source, RuntimeBattleSourceKind.staticEncounter);
    expect(request.allowsPlayerFlee, isFalse);
    expect(request.toJson(), containsPair('kind', 'staticEncounter'));
    expect(
      request.toJson(),
      containsPair('opponentProfileId', 'trainer_boss_phare_pokemon'),
    );
  });

  test('wild and trainer requests preserve their flee semantics', () {
    const returnContext = OverworldReturnContext(
      mapId: 'map_port',
      playerPos: GridPos(x: 3, y: 4),
      playerFacing: Direction.south,
    );
    const wild = WildBattleStartRequest(
      requestId: 'wild:1',
      createdAtEpochMs: 1,
      returnContext: returnContext,
      mapId: 'map_port',
      zoneId: 'zone_grass',
      tableId: 'table_grass',
      encounterKind: EncounterKind.walk,
      speciesId: 'rattata',
      level: 3,
      minLevel: 2,
      maxLevel: 4,
      weight: 100,
      playerPos: GridPos(x: 3, y: 4),
    );
    const trainer = TrainerBattleStartRequest(
      requestId: 'trainer:1',
      createdAtEpochMs: 2,
      returnContext: returnContext,
      trainerId: 'trainer_lysa',
      npcEntityId: 'npc_lysa',
      mapId: 'map_port',
      playerPos: GridPos(x: 3, y: 4),
    );

    expect(wild.allowsPlayerFlee, isTrue);
    expect(trainer.allowsPlayerFlee, isFalse);
  });
}
~~~~~~

### `selbrume/dialogues/ending_port.yarn`

- Taille : `367` octets
- SHA-256 : `a160f4fcba482fc378d1444f99b12d3a5d51d7feee3243008d16dfaf4fe84414`

~~~~~~text
title: EndingPort
tags: selbrume chapter-4
---
Maël: Regarde le large. Pour la première fois depuis des jours, on distingue l'horizon.
Soline: Les bateaux peuvent repartir et le Passage des Dames est redevenu sûr.
Lysa: Ne prends pas cet air satisfait. La prochaine fois, je gagne.
Narration: Au loin, le phare envoie un faisceau stable au-dessus de Selbrume.
===
~~~~~~

### `selbrume/dialogues/fisher_after_keep.yarn`

- Taille : `149` octets
- SHA-256 : `3bf532119dac17f2fd973560db0179af06dbe4d9798df0c249841fd2697e7519`

~~~~~~text
title: FisherAfterKeep
tags: selbrume world-state side-quest
---
Pêcheur: Le nid est sauf, mais la confiance ne se ramasse pas comme une perle.
===
~~~~~~

### `selbrume/dialogues/fisher_after_return.yarn`

- Taille : `170` octets
- SHA-256 : `a2fabf1188847c93347afb366a90323ab7df67f01c5bb57a34ee1156cc268d53`

~~~~~~text
title: FisherAfterReturn
tags: selbrume world-state side-quest
---
Pêcheur: Tu as protégé le Goélise et rendu notre bien. Tu seras toujours bienvenu sur ce quai.
===
~~~~~~

### `selbrume/dialogues/fisher_epilogue.yarn`

- Taille : `160` octets
- SHA-256 : `42779bc5667cffc22679bbc9946e475f7977d83516550b91e4126839fa519abf`

~~~~~~text
title: FisherEpilogue
tags: selbrume world-state epilogue
---
Pêcheur: La brume est levée. Les filets sont prêts et les barques reprennent enfin la mer.
===
~~~~~~

### `selbrume/dialogues/goelise_port.yarn`

- Taille : `1217` octets
- SHA-256 : `809c72c23cf0e3ba143c037775dc497c4b2ce9f1456d418da27dafeaa21c4105`

~~~~~~text
title: FisherIntro
tags: selbrume side-quest
---
Pêcheur: Un Goélise vole nos repas depuis que la brume a déplacé son nid.
Pêcheur: Trouve-le avant que quelqu'un ne décide de le chasser.
===
title: GoeliseChoice
tags: selbrume side-quest choice
---
Narration: Dans le nid repose un petit objet brillant appartenant aux pêcheurs.
-> Rendre l'objet au pêcheur
    <<outcome return_item>>
    Joueur: Le Goélise a surtout besoin qu'on remette son nid en place.
    <<jump GoeliseReturned>>
-> Garder l'objet
    <<outcome keep_item>>
    Joueur: Cet objet pourrait servir plus tard.
    <<jump GoeliseKept>>
===
title: GoeliseReturned
tags: selbrume side-quest choice
---
Narration: Le joueur décide de rendre l'objet aux pêcheurs.
===
title: GoeliseKept
tags: selbrume side-quest choice
---
Narration: Le joueur garde l'objet et devra assumer la méfiance des pêcheurs.
===
title: FisherReturn
tags: selbrume side-quest
---
Pêcheur: Le Goélise est calmé et son nid tient bon. Merci.
===
title: FisherSuspicious
tags: selbrume side-quest choice
---
Pêcheur: Le nid tient bon, mais l'objet des pêcheurs n'est jamais revenu.
Pêcheur: Garde donc cette perle. La confiance, elle, se regagne autrement.
===
~~~~~~

### `selbrume/dialogues/lighthouse.yarn`

- Taille : `853` octets
- SHA-256 : `d6c41c2c9e39593ca85e9b293ccac4b41fe66c53b015f64d27b6487b222dd547`

~~~~~~text
title: LighthouseArrival
tags: selbrume chapter-3
---
Narration: Le Vieux Phare d'Écume tremble sous chaque pulsation de lumière.
===
title: LighthouseOldNote
tags: selbrume chapter-3 lore
---
Ancien carnet: La lentille amplifie les émotions des Pokémon sensibles aux courants marins.
Ancien carnet: Si la lumière s'emballe, ne détruisez pas la source. Apaisez-la.
===
title: FinalPokemon
tags: selbrume chapter-3 boss
---
Narration: Un Lanturn affolé protège la lentille. Sa lumière pulse au rythme de la brume.
Joueur: Je ne suis pas venu te chasser. Mais je dois arrêter cette tempête.
===
title: MistDisperses
tags: selbrume chapter-3 resolution
---
Narration: Le faisceau du phare se stabilise et découpe un chemin clair dans la brume.
Maël: Même depuis le bourg, je vois la lumière. Tu as réussi ; Selbrume respire de nouveau.
===
~~~~~~

### `selbrume/dialogues/lysa_after_loss.yarn`

- Taille : `154` octets
- SHA-256 : `e41507cbb4c96febd322c136cb5e91378c646c17ccbd4bd7ce3d565cea2775c2`

~~~~~~text
title: RivalAfterLoss
tags: selbrume world-state chapter-1
---
Lysa: La brume n’attend pas les retardataires. Entraîne-toi et essaie de me suivre.
===
~~~~~~

### `selbrume/dialogues/mado.yarn`

- Taille : `676` octets
- SHA-256 : `5fb5cbdef6ed33945cf288a5451c1199e6f6e7de76d912dcfb6917222384f4f6`

~~~~~~text
title: MadoIntro
tags: selbrume chapter-2 side-quest
---
Mado: La brume fait chanter le sel. Écoute bien : trois notes manquent dans les marais.
Mado: Ce sont mes cristaux. Retrouve-les et ils nous diront d'où vient cette énergie.
-> Accepter d'aider
    <<outcome accept_help>>
    Joueur: Je chercherai les trois cristaux.
-> Refuser pour le moment
    <<outcome refuse_for_now>>
    Joueur: Je dois d’abord me préparer. Je reviendrai.
===
title: MadoReturn
tags: selbrume chapter-2 side-quest
---
Mado: Les trois cristaux vibrent ensemble. Ils pointent vers la lentille du vieux phare.
Mado: Prends cette Super Potion. Elle t'aidera quand la brume se resserrera.
===
~~~~~~

### `selbrume/dialogues/mado_after_crystals.yarn`

- Taille : `156` octets
- SHA-256 : `81ae709497e3011bcc43c79b53bc49020b9d727c900faaed7f53c952c48e3510`

~~~~~~text
title: MadoCompleted
tags: selbrume world-state side-quest
---
Mado: Les cristaux chantent de nouveau. Le phare ne pourra plus nous cacher sa vérité.
===
~~~~~~

### `selbrume/dialogues/mael_after_mission.yarn`

- Taille : `152` octets
- SHA-256 : `65df86c4a1212a9c35b6277665961a877fae32504db303295b2e23f0d6772131`

~~~~~~text
title: MaelAfterMission
tags: selbrume world-state chapter-1
---
Maël: Le Port des Brisants t’attend. Écoute Soline et ne sous-estime pas Lysa.
===
~~~~~~

### `selbrume/dialogues/mael_epilogue.yarn`

- Taille : `149` octets
- SHA-256 : `64c09b06c6b4c6db4acc9e159302eeca222f423dee9207aefcf8d74637b21c31`

~~~~~~text
title: MaelEpilogue
tags: selbrume world-state epilogue
---
Maël: Tu as rendu son horizon à Selbrume. Ce village se souviendra de ta lumière.
===
~~~~~~

### `selbrume/dialogues/mael_intro.yarn`

- Taille : `1067` octets
- SHA-256 : `7c5e690851bfa6c5c41d093d3e224578a46c3d6080b70fcb7727d230b824489c`

~~~~~~text
title: MaelIntro
tags: selbrume chapter-1
---
Maël: Bienvenue à Selbrume. La brume n'a jamais été aussi épaisse.
Maël: Viens me voir avec ton compagnon, ou choisis-en un si tu pars de zéro.
===
title: MaelExistingPokemon
tags: selbrume chapter-1
---
Maël: Ton Pokémon semble déjà te faire confiance. Nous n'avons pas de temps à perdre.
Maël: Rejoins le Port des Brisants et découvre pourquoi le vieux phare s'est tu.
===
title: MaelStarterChoice
tags: selbrume chapter-1 starter
---
Maël: La route sera dangereuse. Lequel de ces trois compagnons veux-tu protéger ?
-> Bulbizarre, calme et tenace
    <<outcome starter_bulbasaur>>
    Maël: Bulbizarre saura sentir les changements dans les marais.
-> Salamèche, vif et courageux
    <<outcome starter_charmander>>
    Maël: Salamèche gardera une lumière près de toi dans la brume.
-> Carapuce, à l'aise avec les embruns
    <<outcome starter_squirtle>>
    Maël: Carapuce connaît déjà le rythme des marées.
Maël: Rejoins maintenant le Port des Brisants. Le vieux phare nous inquiète.
===
~~~~~~

### `selbrume/dialogues/marais_clues.yarn`

- Taille : `450` octets
- SHA-256 : `438b75848e05107b5200a0fc3011454af513aa711cc44fcff0bfb18bbf92f2e3`

~~~~~~text
title: ClueGlass
tags: selbrume chapter-2 clue
---
Narration: Un éclat de verre parfaitement poli est pris dans le sel. Il provient d'une lentille ancienne.
===
title: ClueElectric
tags: selbrume chapter-2 clue
---
Narration: De fines brûlures bleutées serpentent dans la vase. L'énergie file vers le nord.
===
title: ClueLens
tags: selbrume chapter-2 clue
---
Narration: Une marque gravée représente le mécanisme de la lentille du phare.
===
~~~~~~

### `selbrume/dialogues/port_alert.yarn`

- Taille : `727` octets
- SHA-256 : `3d55736ddb340eb2e2ffbb00dafdf6c1eaa156522b75abe8c10275ab9d7340c6`

~~~~~~text
title: PortAlert
tags: selbrume chapter-1
---
Pêcheur: Les barques reviennent toutes seules ! On ne voit plus les balises !
Soline: Le phare envoie des éclats irréguliers. Gardez votre calme et restez sur les quais.
-> Céder à la panique
    <<outcome panic>>
    Joueur: Oh mon Dieu, on va tous mourir !
    <<jump PortPanicked>>
-> Rassurer la foule
    <<outcome reassure>>
    Joueur: Calmez-vous, on va comprendre ce qui se passe.
    <<jump PortReassured>>
===
title: PortPanicked
tags: selbrume chapter-1
---
Soline: Respire. Va voir Lysa avant que la peur ne gagne tous les quais.
===
title: PortReassured
tags: selbrume chapter-1
---
Soline: Va voir Lysa. Elle prétend connaître un passage vers les marais.
===
~~~~~~

### `selbrume/dialogues/soline.yarn`

- Taille : `343` octets
- SHA-256 : `2738fd399aaa8b9cc0051da8a7b79ab3bc28ef43f1f152b3771bf87a643d2c80`

~~~~~~text
title: SolineClues
tags: selbrume chapter-2
---
Soline: Du verre poli, des traces électriques et la marque de l'ancienne lentille...
Soline: Tu as raison. Le Passage des Dames doit être ouvert, même si la marée se lève.
===
title: SolineAfterPassage
tags: selbrume chapter-2
---
Soline: Le passage est libre. Reviens vivant du phare.
===
~~~~~~

### `selbrume/dialogues/soline_after_passage.yarn`

- Taille : `149` octets
- SHA-256 : `07f970a622c872ecaeadfb98726811f9c11f3fe2aecfefec76cff7acb09779be`

~~~~~~text
title: SolineAfterPassage
tags: selbrume world-state chapter-2
---
Soline: Le Passage des Dames est ouvert. Le vieux phare est droit devant toi.
===
~~~~~~

### `selbrume/dialogues/soline_epilogue.yarn`

- Taille : `146` octets
- SHA-256 : `968fe8c42fb633224c0a4c330d6c9287401feab3829a5eac4ae1fc53b4d37337`

~~~~~~text
title: SolineEpilogue
tags: selbrume world-state epilogue
---
Soline: Les bateaux repartent et la marée est lisible. Selbrume respire enfin.
===
~~~~~~

### `selbrume/dialogues/yvon_after_cabin.yarn`

- Taille : `175` octets
- SHA-256 : `fb27cf0bf353e8ed539a378e553e5498cf7fc05a613e0672c05423cd48f0622c`

~~~~~~text
title: YvonAfterCabin
tags: selbrume world-state side-quest lore
---
Yvon: Tu as lu mon carnet. Alors tu sais que la lumière doit répondre à la mer, jamais la dominer.
===
~~~~~~

### `selbrume/dialogues/yvon_cabin.yarn`

- Taille : `807` octets
- SHA-256 : `1a92c766f89cc3034b52914eca756cead86e82e086ceaf78d2ef7cf5a77551c0`

~~~~~~text
title: YvonCabin
tags: selbrume side-quest lore
---
Yvon: J'ai gardé ce phare autrefois. Ma vieille cabane contient un carnet sur la lentille.
Yvon: La clé a dû glisser près du mur extérieur. Si tu la retrouves, lis tout.
-> Chercher la clé
    <<outcome accept_search_key>>
    Joueur: Je retrouverai la clé et je lirai le carnet.
-> Revenir plus tard
    <<outcome ignore_for_now>>
    Joueur: Je reviendrai quand je pourrai fouiller les abords du phare.
===
title: CabinKey
tags: selbrume side-quest
---
Narration: Une clé piquée de sel porte l'emblème du vieux phare.
===
title: CabinJournal
tags: selbrume side-quest lore
---
Carnet d'Yvon: La lumière ne commande pas la mer ; elle lui répond.
Carnet d'Yvon: Un Pokémon effrayé peut transformer la lentille en amplificateur de brume.
===
~~~~~~
