# NS-EVENT-V2 — Phase F2 — Runtime Source Bridges V0

## 1. Résumé exécutif

```text
Phase F2 : CLOSED / ACCEPTED le 2026-07-15
NS-EVENT-V2-19 : PASS
NS-EVENT-V2-20 : PASS
NS-EVENT-V2-21 : PASS
NS-EVENT-V2-22 : PASS
Gate de sortie : ACCEPTED
Phase G : READY
```

Ce document est le rapport principal de la mission **Phase F2 — Runtime Source
Bridges**, jalons `NS-EVENT-V2-19` à `NS-EVENT-V2-22`. Le rapport et son
Evidence Pack constituent ensemble le livrable de clôture exigé par
`codex_rule.md`. Les contenus complets des fichiers créés sont annexés dans
`ns_event_v2_phase_f2_closure_evidence_pack.md`; les deux documents de clôture
eux-mêmes sont exclus de cette annexe afin d'éviter une récursion documentaire.

Le statut ci-dessus repose sur deux revues contradictoires indépendantes, une
matrice finale de 191 tests F2, les suites complètes des quatre packages et les
smokes runtime/host. Aucun placeholder ne subsiste dans le document final.

## 2. Nom exact, scope et décision sur le prompt

- Mission : `Phase F2 — Runtime Source Bridges`.
- Jalons : `NS-EVENT-V2-19`, `NS-EVENT-V2-20`, `NS-EVENT-V2-21`,
  `NS-EVENT-V2-22`.
- Demande utilisateur : finir la Phase F, F1 étant déjà fermée au HEAD.
- Interprétation retenue : terminer F2, seule sous-phase F restante, sans
  commencer l'intégration Map Editor de Phase G.
- Lots gameplay associés consultés : `FG-014`, `FG-082`, `FG-086` et `FG-088`.
  Ils restent `TODO`; F2 ne prétend pas les fermer.

Le prompt était cohérent avec la roadmap, mais le simple passage des tests
initiaux n'était pas une preuve suffisante de clôture. La revue contradictoire a
donc été autorisée à bloquer le verdict et a effectivement trouvé des chemins
d'orphelinage asynchrones. Ils ont été traités dans F2 parce qu'ils violaient
directement les ADR de suspension, d'outbox et d'ordre de restauration.

## 3. Baseline Git et Gate 0

```text
Répertoire : /Users/karim/Project/pokemonProject
Branche : main
HEAD : 2f68328a38bf218c843e497940f8dd24a7a9c194
Sujet : feat(event-v2): close NS-EVENT-V2 Phase F1
Worktree initial F2 : propre
```

Commandes de Gate 0 exécutées en lecture seule :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
git log -20 --oneline --decorate
```

Résultat : F2 a commencé sur `main`, au commit F1 ci-dessus, sans diff. Pendant
la validation finale, un processus externe a temporairement modifié
`selbrume/project.json`, `selbrume/maps/map_bourg_selbrume.json` et créé un
lock, une map de test et trois snapshots PNG. Cela a produit une passe runtime
rouge pendant que les fichiers étaient écrits. Ces changements ont ensuite
disparu du worktree sans intervention de cette mission ; ils ne figurent ni
dans l'inventaire F2 ni dans l'état Git final. La suite complète a été relancée
après stabilisation et est verte.

## 4. Documents et règles lus

- `AGENTS.md` ;
- `codex_rule.md` ;
- `pokemap_roadmap_mecaniques_fangame.md` ;
- `MVP Selbrume/road_map_event_builder_v2.md` ;
- `MVP Selbrume/event_builder_v2_architecture_decisions.md` ;
- rapports de clôture et Evidence Packs des Phases D, E, F1-PREREQ et F1 ;
- implémentations et tests F1 de l'autorité, du lifecycle, du gate et de
  l'outbox.

ADR appliqués sans les redéfinir :

- `ADR-EV2-004` — provenance qualifiée des outcomes ;
- `ADR-EV2-007` — autorité unique et fallback ;
- `ADR-EV2-011` — un seul Event gagnant par occurrence ;
- `ADR-EV2-013` — lifecycle, suspension et checkpoint interdit ;
- `ADR-EV2-014` / `014-A` — outbox FIFO, corrélation et anti-replay ;
- `ADR-EV2-015` — `mapEnter` après restauration et après outbox restaurée.

## 5. Audit initial

### 5.1 Contrats existants

F1 fournissait déjà :

- `NarrativeEventDispatchAuthority` préparée et fail-closed ;
- `NarrativeEventDispatchPlanner` ;
- `NarrativeEventExecutionCoordinator` transactionnel ;
- `NarrativeEventStateTransactions` ;
- `NarrativeOutcomeOutboxProcessor` ;
- `NarrativeRuntimeActivityGate` et son port ;
- `NarrativeEventProgress` persisté dans `GameState`/`SaveData`.

Il manquait les quatre branchements de production. `PlayableMapGame` contenait
encore plusieurs chemins directs Scenario/Scene/Battle, des activations map
implicites et aucune orchestration qualifiée complète des outcomes réentrants.

### 5.2 Fichiers et zones à risque identifiés

- composition runtime dans `PlayableMapGame` ;
- boot, warp, connection et `loadGame` ;
- interaction `MapEntity` et fallback gameplay ;
- occupation/fronts de `MapTrigger` ;
- Scene V1 et Battle, y compris leur write-back ;
- bridge Scenario legacy `emitOutcome` ;
- save/load pendant dialogue, Battle ou continuation mémoire ;
- host de démonstration et distinction seed/restauration.

### 5.3 Risques initiaux

- double dispatch V2 + legacy ;
- fallback après claim ;
- `mapEnter` dupliqué ou omis au load ;
- trigger perdu, doublé ou réarmé trop tôt ;
- collision d'outcome homonyme entre Scene et Battle ;
- enfant dispatché avant commit parent ;
- save au milieu d'une continuation non sérialisable ;
- deadlock lorsqu'une delivery provoque warp puis `mapEnter` ;
- résultat d'un handoff externe attribué au mauvais Scenario.

### 5.4 Frontières conservées

Aucun changement de schéma `map_core`, aucune UI `map_editor`, aucune migration
de projet, aucun nouveau producteur Yarn autonome et aucun fan-out multi-Events
n'étaient autorisés dans F2.

## 6. Sous-agents et passes contradictoires

| Passe | Rôle | Verdict / apport |
|---|---|---|
| Audit architecture initial | Audit / Architecture | `PASS` — scope F2 confirmé ; quatre bridges et orchestration restore/outbox manquants |
| Implémentation V2-19…22 | Implémentation | `PASS` — quatre sources branchées derrière F1, tests ciblés ajoutés |
| Postfix architecture review | Critique | `BLOCKED`, puis corrigé — drains enfants bloqués après transition |
| Suspension handoff map | Audit ciblé | `PASS` — inventaire dialogue, mouvement, Battle, script, warp et transition |
| Suspension barrier implementation | Implémentation / Tests | `PASS` — barrière LIFO `sceneSuspended`, corrélation et reprise causale |
| Validation V3 | Tests / Build validation | `PASS` fonctionnel/debug ; `FAIL` packaging release documenté |
| Barrier final review | Critique finale contradictoire | `BLOCKED`, puis `PASS` — ownerships reproduits, corrigés et revérifiés |
| Checkpoint/load fixes | Implémentation / Tests | `PASS` — gates avant side effects, purge load et Scene V1 checkpoint-safe |
| Retry containment review | Critique / TDD | `BLOCKED`, puis `PASS` — retries détachés et warp physique corrigés |
| Final independent review 1 | Critique read-only | `PASS` — matrice F2 `+191`, aucun blocker résiduel |
| Final independent review 2 | Critique read-only | `PASS` — interlock warp frais `+9`, aucun blocker résiduel |
| Inventaire rapport | Documentation / Audit | `PASS` — 23 tracked, 21 créés annexés, limites et hotspot documentés |

La critique finale n'a pas été traitée comme une formalité. Elle a d'abord
retourné `BLOCKED`, notamment pour : échec async du setup Battle, mouvement
écrasant une continuation, erreur script récursive, restore qui avançait vers
`mapEnter` avant la fin d'une delivery, adoption croisée de transition/warp/
Battle, side effects démarrés pendant checkpoint et états transitoires survivant
à un load. Les deux verdicts contradictoires finaux sont `PASS`.

## 7. NS-EVENT-V2-19 — Map Enter Production Dispatch Bridge V0

Statut final : `PASS`.

Livré :

- `MapActivationReason` explicite : `initialBoot`, `warp`, `connection`,
  `saveRestore` ;
- identité `MapActivation` et occurrence `mapEnter` canonique ;
- une seule émission après activation physique réussie ;
- boot, warp, connection et load branchés sur le même bridge ;
- restauration de map/pose/monde avant occurrence ;
- outbox restaurée drainée avant `mapEnter` ;
- activation stale/dupliquée et échec de cible fail-closed ;
- whiteout même-map sans seconde activation ;
- host distinguant une vraie save versionnée d'un seed manuel.

Les régressions tardives ont ajouté une fence de restauration : si une delivery
raw ouvre dialogue, Battle, mouvement, script ou warp, le `mapEnter
saveRestore` attend la fermeture causale de cette continuation et le reste de
la FIFO, sans ouvrir l'input ou les triggers concurrents.

## 8. NS-EVENT-V2-20 — Entity Interaction Production Dispatch Bridge V0

Statut final : `PASS`.

Livré :

- `NarrativeSpatialProductionDispatchBridge` partagé ;
- `npc`, `sign`, `item` et `custom` éligibles ;
- `spawn` exclu ;
- `MapPlacedElement` reste sur son pipeline historique ;
- occurrence qualifiée avant tout fallback ;
- fallback uniquement sur `noMatch` autorisé ;
- claim inéligible, autorité bloquée, Scene manquante et exception sans
  second dispatch ;
- input verrouillé pendant arbitrage et feedback joueur en cas d'échec.

## 9. NS-EVENT-V2-21 — Trigger Enter Production Dispatch Bridge V0

Statut final : `PASS`.

Livré :

- résolution pure des fronts extérieur→intérieur ;
- triggers `event` et `custom` uniquement ;
- initialisation depuis un spawn intérieur silencieuse ;
- sortie/réentrée réarme exactement une fois ;
- overlaps conservés en ordre UTF-16 stable puis FIFO runtime ;
- triggers système exclus ;
- queue retenue pendant dialogue/dispatch ;
- interlock trigger/warp empêchant une occurrence sur une activation stale.

`MapGameplayZone`, raw tile et triggers système restent volontairement hors
source Event V2.

## 10. NS-EVENT-V2-22 — Qualified Outcome Received Dispatch & Reentrancy V0

Statut final : `PASS`.

Livré :

- outcomes Scene, Battle et Scenario legacy toujours qualifiées par producteur ;
- Battle autonome émise après write-back autoritatif ;
- Battle hébergée écrite dans le state de travail Scene, publiée uniquement au
  commit final, abandonnée avec le parent en rollback ;
- ordre Battle(s) puis outcome final Scene ;
- bridge Scenario raw limité à `legacyScenario` ;
- `correlationId`, causation et `depth` propagés aux continuations ;
- FIFO persistante, receipt delivered et absence de replay après reload ;
- drain réentrant supportant transition map puis `mapEnter` enfant ;
- barrière LIFO `sceneSuspended` pour dialogue, mouvement, Battle, script et
  warp ;
- save et load refusés pendant un effet mémoire actif non checkpointable ; les
  queues encore inactives que le load sait purger restent chargeables ;
- ownership typé des handoffs pour empêcher adoption, écrasement ou attribution
  du résultat d'un autre producteur ;
- erreur/cancel terminal ferme la lease et ne reprend pas le Scenario comme un
  faux succès.

## 11. Architecture du drain et des continuations

Le flux final attendu est :

```text
outcome producteur
→ enqueue qualifiée + commit producteur
→ process FIFO head
→ commit delivered du parent + enqueue enfants
→ si effet async : barrière sceneSuspended
→ effet owner-scoped
→ enfants causaux drainés
→ reprise Scenario
→ éventuel transfert de la même barrière
→ fermeture lease
→ tête FIFO suivante
```

Lors d'un `saveRestore`, la même chaîne se termine avant la préparation du
`mapEnter`. Le verrou d'activation reste actif pour l'input et les sources
concurrentes ; seuls les handoffs appartenant à la barrière supérieure peuvent
progresser.

## 12. Inventaire des fichiers tracked modifiés

L'inventaire final précis, les lignes et deltas sont dans l'Evidence Pack.
Zones fonctionnelles :

| Fichier | Zones modifiées | Raison / impact |
|---|---|---|
| `MVP Selbrume/road_map_event_builder_v2.md` | statut global, Phase F2, V2-19…22, clôture, Phase G | refléter les preuves et rendre G exécutable uniquement après acceptation |
| `examples/playable_runtime_host/lib/main.dart` | `_ProjectLoaderPageState` | transmettre save et raison d'activation cohérentes |
| `examples/playable_runtime_host/lib/src/runtime_launch_save.dart` | `resolveRuntimeHostInitialMapActivationReason` | distinguer restore versionnée et seed |
| `examples/playable_runtime_host/test/p3_narrative_smoke_slice_test.dart` | attente activation initiale | adapter le smoke au hook async |
| `examples/playable_runtime_host/test/runtime_launch_save_test.dart` | tests resolver | preuve restore/boot |
| `packages/map_gameplay/lib/map_gameplay.dart` | barrel | exporter les fronts trigger purs |
| `packages/map_runtime/lib/map_runtime.dart` | barrel | exporter activation et bridges typés |
| `packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart` | lease/cancel/purge | empêcher une cutscene mémoire de survivre au load |
| `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart` | `emitOutcome` | différer la livraison raw vers l'outbox |
| `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart` | contexte/emitter | port de collecte qualifiée |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart` | rebase state courant | conserver les write-backs async |
| `packages/map_runtime/lib/src/application/script_command_executor.dart` | ordre des handoffs | réserver l'owner avant callback synchrone |
| `packages/map_runtime/lib/src/application/scripted_entity_movement_controller.dart` | remplacement atomique | annuler proprement l'ancien mouvement même sur cible immédiate/KO |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | composition, activations, spatial, triggers, outcomes, barriers, handoffs, save/load | intégration production complète F2 |
| `packages/map_runtime/test/cutscene_runtime_runner_test.dart` | cancel/load | preuve de frontière de lifetime |
| `packages/map_runtime/test/item_pickup_give_item_readiness_test.dart` | attente boot | non-régression item |
| `packages/map_runtime/test/ns_event_34_scene_target_handoff_smoke_test.dart` | attente boot | non-régression Scene V1 |
| `packages/map_runtime/test/ns_event_35_trigger_variants_lifecycle_gate_test.dart` | attente boot | non-régression trigger |
| `packages/map_runtime/test/playable_map_game_input_test.dart` | fixtures/assertions warp/connection | raisons et interlocks activation |
| `packages/map_runtime/test/playable_map_game_whiteout_lite_test.dart` | compteur activation | aucun double mapEnter |
| `packages/map_runtime/test/scenario_runtime_executor_test.dart` | defer outcome | aucune récursion inline |
| `packages/map_runtime/test/script_runtime_mvp_test.dart` | erreurs/handoff | terminalisation sans reprise fantôme |
| `packages/map_runtime/test/scripted_entity_movement_controller_test.dart` | remplacement | ownership de mouvement atomique |

L'inventaire tracked final contient exactement 23 fichiers F2. Les deltas
exacts sont reproduits dans l'Evidence Pack ; aucun fichier `selbrume/` hors
roadmap ne reste modifié au snapshot Git final.

## 13. Inventaire des fichiers créés

Les fichiers créés de production/tests couvrent : fronts trigger purs,
activation map, snapshot runtime, exécution Scene, bridges map/spatial et les
intégrations boot/restore/entity/trigger/outcome. Le rapport V2-19 reste une
photographie historique prise avant V2-20…22 ; ses mentions `F2 IN_PROGRESS` ne
sont pas le statut canonique final.

Inventaire et contenu complet :
`ns_event_v2_phase_f2_closure_evidence_pack.md`, section « Annexes — contenus
complets ». Nombre final hors documents de clôture : `21` fichiers,
`19 026` lignes.

## 14. Tests créés ou modifiés

Matrice couverte :

- positif : chacun des quatre hooks exécute sa Scene/consumer une fois ;
- négatif : source inéligible, claim, stale activation, cible absente, Scene
  manquante, setup Battle KO, script KO, warp KO ;
- garde-fous : déduplication, FIFO, corrélation/profondeur, no fallback,
  checkpoint busy, owner requestId/sourceId/target ;
- non-régressions : item pickup, Scene target, trigger lifecycle, input,
  whiteout, smoke runtime/host, save/load.

Les noms exacts des fichiers et cas sont indexés dans l'Evidence Pack.

## 15. Commandes et résultats ciblés

```text
Matrice F2 finale (17 fichiers) : +191, All tests passed.
Interlock warp/retry indépendant : +9, All tests passed.
Retry boot/entity/trigger/outbox/map interlock : +33, All tests passed.
Régressions Scenario/warp filtrées : +7, All tests passed.
Follow leader warp + qualified/checkpoint/input : +98, All tests passed.
Smoke runtime battle : +3, All tests passed.
Smoke host launch/narrative/save : +6, All tests passed.
```

## 16. Suites complètes

```text
map_core      : +2987, All tests passed.
map_gameplay  : +282, All tests passed.
map_runtime   : +1769 ~1, 1 skipped test, All other tests passed.
runtime host  : +50, All tests passed.
```

Le skip runtime final est compté séparément : 1 test skippé et 1 769 tests
passés. Il n'est pas présenté comme un test réussi.

## 17. Analyses et format

```text
map_core analyze      : No issues found! (exit 0)
map_gameplay analyze  : No issues found! (exit 0)
runtime ciblé         : 11 items, No issues found! (exit 0)
runtime global        : 347 infos; exit 1 par défaut, exit 0 avec --no-fatal-infos
host global           : 1 info; exit 1 par défaut, exit 0 avec --no-fatal-infos
dart format           : 42 fichiers, 0 changement; dernier sous-ensemble 5 fichiers, 0 changement
git diff --check      : propre (exit 0)
```

L'analyse runtime globale avec les infos fatales par défaut et la relance
`--no-fatal-infos` sont documentées séparément pour ne pas maquiller l'exit
code.

## 18. Build

Commandes :

```bash
flutter build macos --debug --no-pub
flutter build macos --release --no-pub
```

Résultats :

```text
Debug   : PASS — Built build/macos/Build/Products/Debug/playable_runtime_host.app
Release : FAIL — release_unpack_macos refuse FlutterMacOS.framework; aucun artefact release produit
```

Le défaut release local `release_unpack_macos` est distingué d'un échec
fonctionnel F2. Aucune readiness release universelle n'est revendiquée sans
artefact produit.

## 19. Compatibilité et rollback

- `legacyOnly` conserve les pipelines historiques ;
- `dualRead` ne fallback que sur `noMatch` non claimé ;
- `v2Only` ne réactive jamais le legacy ;
- les anciennes saves sans progression V2 restent compatibles via F1 ;
- le retour `legacyOnly` n'est garanti sûr qu'avant publication de contenu
  V2-only ;
- aucune migration eager ou copie des flags legacy n'est introduite.

## 20. Limites explicitement conservées

- `MapPlacedElement`, `MapEntity.spawn`, raw tile et `MapGameplayZone` ne sont
  pas des sources ajoutées par F2 ;
- triggers système exclus ;
- aucun producteur Yarn autonome ;
- aucun fan-out multi-Events ;
- aucune reprise persistée à mi-Scene ; save/load sont bloqués pendant l'effet
  actif, tandis qu'un load peut purger les queues transitoires documentées ;
- aucun replay d'une delivery déjà delivered ;
- aucun Editor/UI/migration Phase G ;
- le rollback transactionnel complet d'un load destructif échoué reste
  `FG-014 TODO` ;
- `FG-082`, `FG-086` et `FG-088` restent `TODO` ;
- aucun budget de performance F2 n'est revendiqué ;
- build release universel non produit dans la toolchain locale.

## 21. Risques résiduels

- `PlayableMapGame` reste un hotspot volumineux ; la correction est bornée mais
  la densité des singletons asynchrones augmente le coût de maintenance ;
- la garantie exactly-once reste locale/persistante, pas une transaction avec
  des effets externes ;
- le ledger delivered non borné reste une mesure de readiness Phase L ;
- les handoffs mémoire ne survivent pas à un crash, conformément à ADR-EV2-013 ;
- un retry d'infrastructure reste volontairement pending jusqu'à un drain
  ultérieur ou un reload, sans hot-loop ;
- un second warp legacy immédiat lancé depuis le `mapEnter` imbriqué d'un warp
  propriétaire n'a pas de test dédié ;
- la dette de packaging Flutter/Xcode doit être traitée avant release.

## 22. Auto-critique finale

Le premier passage implémentait correctement les chemins nominaux et passait
les suites, mais associait encore plusieurs continuations à des globals non
possédés. C'était insuffisant : un autre Battle, warp ou transition pouvait être
adopté, et le pre-hook restore pouvait rendre la main trop tôt. La revue
contradictoire a forcé des reproductions avant correction et a conduit à des
owners typés et à une fence restore.

Le principal compromis restant est architectural : les fixes sont volontairement
surgicaux dans le composition root existant au lieu d'extraire un nouvel
orchestrateur de handoffs pendant un lot déjà large. Cette extraction serait
pertinente plus tard, mais la faire maintenant aurait mélangé refactor et preuve
fonctionnelle. La couverture ajoutée doit rester la protection de cette future
extraction.

## 23. État Git final

```text
23 fichiers tracked F2 modifiés.
23 fichiers F2 non suivis : 21 livrables source/test/rapport V2-19 et 2 documents de clôture.
Aucun changement Selbrume externe présent au snapshot final.
```

Aucune commande Git d'écriture (`add`, `commit`, `push`, `stash`, `reset`,
changement de branche) n'a été exécutée. Les fichiers Selbrume transitoires ont
été créés puis retirés par leur processus externe, sans action de cette mission.

## 24. Verdict et prochaine étape

```text
PHASE F2 CLOSED / ACCEPTED le 2026-07-15
Gate de sortie : PASS

V2-19 : PASS
V2-20 : PASS
V2-21 : PASS
V2-22 : PASS

Prochaine mission proposée : PHASE G — Map Editor Integration (V2-23 à V2-25)
```

Phase G peut maintenant relier le Map Editor aux sources physiques, sans
réouvrir les contrats runtime fermés par F2.
