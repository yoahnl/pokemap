# NS-EVENT-V2 — Phase F1 — Runtime Authority, Progress, Lifecycle & Outcome Outbox V0

## 1. Résumé exécutif

```text
Phase F1 : CLOSED / ACCEPTED
F1-0 : PASS
F1-A : PASS
F1-B : PASS
F1-C : PASS
F1-D : PASS
V2-17 : PASS
V2-18 : PASS
Phase F2 : READY
Blockers : aucun
```

F1 livre une autorité de dispatch Event V2 fail-closed, une progression persistante séparée du legacy, un lifecycle transactionnel, un gate runtime partagé et une outbox persistante. Aucun bridge de source production n'est branché. Le contrat d'exactly-once reste volontairement limité à l'anti-replay local persistant.

## 2. Baseline

- Branche : `main`.
- Commit de départ : `2d9642d140d897831dcc0821baecca686eac52c0`.
- Sujet : `fix(event-v2): close F1-ENTRY-TER Selbrume runtime contracts`.
- Worktree initial : propre.
- Les rapports historiques F1, F1-PREREQ et F1-ENTRY n'ont pas été modifiés.

## 3. Documents normatifs

Documents lus et appliqués :

- `MVP Selbrume/event_builder_v2_architecture_decisions.md` ;
- `MVP Selbrume/road_map_event_builder_v2.md` ;
- rapports de clôture Phases A, B, C, D, E et E-bis ;
- rapport blocker F1 historique ;
- rapport F1-PREREQ ;
- rapport F1-ENTRY-TER ;
- `AGENTS.md` et `codex_rule.md`.

Aucune décision ADR ratifiée n'a été redéfinie.

## 4. MCP Dart

MCP Dart a été utilisé avec les roots `map_core`, `map_gameplay` et `map_runtime`. Les symboles imposés ont été résolus via LSP : définitions/records/registry Event, sources, outcomes, conditions, reuse policy, index source, claims validés, resolver Fact, `GameState`, `SaveData`, conversions persistence, `FileGameSaveRepository` et contrats Scene runtime. L'analyse ciblée MCP des nouveaux fichiers runtime n'a signalé aucune erreur.

## 5. Sous-agents et incidents

Passes spécialisées exécutées :

- A — Dispatch Domain ;
- B — Planner & Conditions ;
- C — Progress Domain & Codec ;
- D — Lifecycle & Atomic Commit ;
- E — Runtime Activity & Save Gate ;
- F — Outcome Outbox ;
- G — Compatibility & Migration Boundaries ;
- H — Tests, Performance & Documentation ;
- R1 — Runtime Integrity ;
- R2 — Compatibility Truthfulness ;
- orchestrateur principal.

Un worker `map_core` a été interrompu avant son compte rendu final. Ses changements ont été inspectés, repris par l'orchestrateur et entièrement revalidés. Deux commandes ciblées ont d'abord utilisé un chemin de package répété ; elles ont été relancées depuis le bon répertoire. Aucun PASS ne repose sur ces exécutions partielles.

## 6. Gate 0

Commandes exécutées avant modification :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --name-status
git diff --check
git log --oneline -n 20
git ls-files | rg '(^|/)\.dart_tool/' || true
```

Résultats : `pwd=/Users/karim/Project/pokemonProject`, branche `main`, worktree/diffs vides, HEAD `2d9642d1`, aucun `.dart_tool` suivi.

## 7. F1-0 Contract Revalidation

- Facts : `defaultValue=true` avec override `false` résout `false`, y compris après save/reload.
- Consommateurs : resolver direct, World Rules, condition Scene canonique et `ScriptCondition` avec contexte Fact restent cohérents.
- Dual-read : `canStartDualRead == canEnterDualRead`.
- Tombstone local : entrée refusée, exécution dual-read permise.
- Collision globale : entrée et exécution refusées.
- Baseline fraîche : `map_core` 2955 tests, `map_gameplay` 245 tests, `map_runtime` 1695 tests avec un skip historique ; toutes vertes avant implémentation.

## 8. Public API

Les exports publics ajoutent :

- `NarrativeEventOccurrence` ;
- `NarrativeEventProgress` et `NarrativeOutcomeDelivery` ;
- préparation et décisions `NarrativeEventDispatchAuthority` ;
- `NarrativeEventDispatchPlanner` ;
- `NarrativeEventExecutionCoordinator` et ses résultats typés ;
- `NarrativeEventStateTransactions` ;
- `NarrativeOutcomeOutboxProcessor` et ses résultats typés ;
- `NarrativeRuntimeActivityGate` et `NarrativeRuntimeActivityPort`.

## 9. NarrativeEventOccurrence

Le modèle pur enveloppe une `NarrativeEventSourceRef`, avec `correlationId` et `depth` optionnels. Il représente exactement `entityInteract`, `triggerEnter`, `mapEnter` et `outcomeReceived`, sans géométrie, Flutter, Flame ni persistance dans `GameState`.

## 10. Authority Preparation

`NarrativeEventDispatchAuthority.prepare` retourne une union fermée `ready | blocked`. La préparation bloque les registry/schema/modes incohérents, un dual-read non exécutable, les divergences claim/provenance et un catalog snapshot structurellement invalide. Le planner exige une autorité préparée.

## 11. Truth Table

| Mode / claim | Candidat éligible | Décision | Fallback legacy |
|---|---:|---|---:|
| `legacyOnly` | indifférent | `noMatch` | oui |
| `dualRead`, absent | oui | `handled` | non |
| `dualRead`, absent | non | `noMatch` | oui |
| `dualRead`, valid | oui | `handled` | non |
| `dualRead`, valid | non | `claimedButIneligible` | non |
| `dualRead`, tombstone local | indifférent | `claimedButIneligible` | non |
| `v2Only` | oui | `handled` | non |
| `v2Only` | non | `noMatch` | non |

## 12. Conditions

Les conditions sont évaluées en AND ordonné. `fact` passe par `NarrativeFactRuntimeResolver`. `narrativeEventConsumed` lit uniquement `NarrativeEventProgress.consumedNarrativeEventIds`. Story Step et la lecture directe des story flags restent hors contrat.

## 13. Candidate Ordering

Le tri est déterministe : `priority DESC`, puis `order ASC`, puis `eventId ASC`. L'index source fournit le bucket concerné ; les entrées et collections exposées restent immuables.

## 14. Claims & Tombstones

Un claim valide bloque le fallback même si sa cible est inéligible. Un autre Event de même source peut gagner s'il est mieux classé et éligible. Un tombstone bloque seulement sa source locale. Un conflit global bloque la préparation entière.

## 15. F1-A Tests and Review

Les tests couvrent les quatre sources, trois modes, claims/tombstones, conflit global, drafts/disabled, Facts, consumed, oneShot/reusable, ordre, déterminisme, immutabilité et validation catalog/runtime. R1 et R2 : PASS final.

## 16. NarrativeEventProgress

Le namespace persistant contient :

- `consumedNarrativeEventIds` ;
- `pendingOutcomeDeliveries` en FIFO ;
- `terminalOutcomeDeliveryIds` comme receipts anti-replay.

Les collections sont normalisées, immuables et encodées de façon stable.

## 17. SaveData / GameState

`GameState` et `SaveData` portent désormais `narrativeEventProgress`, par défaut vide. Les generated Freezed/JSON, conversions `gameStateFromSaveData`, `saveDataFromGameState`, normalisation et `FileGameSaveRepository` propagent explicitement ce champ.

## 18. Old Save Compatibility

L'absence du champ charge `NarrativeEventProgress.empty`. Les consumed legacy et story flags ne sont ni copiés ni migrés. Les IDs V2 orphelins sont conservés. Une delivery orpheline reste liée à son producteur qualifié et n'est jamais réassignée par rapprochement.

## 19. Namespace Separation

`consumedEventIds` demeure strictement legacy. Aucun code F1 ne le lit comme progression Event V2. Le rollback `legacyOnly` ne déclenche aucune migration eager.

## 20. Delivery Model

`NarrativeOutcomeDelivery` conserve exactement : `deliveryId`, outcome qualifié, `causationExecutionId`, `rootCorrelationId`, `depth`, `attemptCount`. Le delivery ID reste stable entre retry et save/reload. La qualification producteur/id empêche les collisions d'outcome homonymes.

## 21. F1-B Tests and Review

Les tests couvrent empty/immutabilité/ordre JSON, consumed, pending/terminal, doublons et overlap stricts, anciennes saves, round-trips, repository, legacy/Facts inchangés, orphelins et stabilité des IDs. R1 et R2 : PASS final.

## 22. Execution Coordinator

Le coordinateur application-level reçoit occurrence, autorité, planner, transactions, callback Scene, activity port et factories injectables. Il n'a aucune dépendance Flame/UI et ne déclenche jamais lui-même le fallback legacy.

## 23. Transactional Working State

La Scene travaille sur un snapshot. Seul un succès complet commite conséquences, consommation oneShot et deliveries en une mutation atomique. Failure, cancel et exception retournent l'état autoritatif inchangé.

## 24. oneShot / reusable

- `oneShot` est consommé uniquement après succès Scene complet.
- `reusable` n'est jamais ajouté au consumed V2 et reste rejouable.
- `claimedButIneligible` et `noMatch` n'exécutent aucun callback.

## 25. Concurrency

`NarrativeEventStateTransactions` sérialise globalement les commits narratifs. Les transactions ordinaires sont volontairement non réentrantes. Une file distincte `serializeOutbox` coordonne l'outbox sans deadlock. Deux processors partageant la même autorité transactionnelle ne perdent pas de mise à jour et respectent les têtes FIFO.

## 26. Activity Gate

Le gate partagé représente `idle`, `dispatching`, `sceneActive`, `sceneSuspended` et `outboxProcessing`. Les leases garantissent la sortie d'activité, y compris en exception. `NarrativeRuntimeActivityPort` adapte le contrat gameplay au gate runtime.

## 27. Save/Load Gate

Save et load consultent le même gate injecté dans `FileGameSaveRepository`. Toute activité non idle bloque l'opération avant même la résolution du chemin. Le motif est typé et stable. Un test compose coordinateur réel, port réel et repository réel.

## 28. F1-C Tests and Review

Les tests couvrent succès/failure/cancel, reusable répété, ordre des conséquences, outcomes uniquement au succès, intégrité de l'original, concurrence, chaque état busy, save et load, noMatch/claim, callback unique et exception. R1 et R2 : PASS final.

## 29. Outcome Enqueue

Chaque outcome qualifié d'une Scene réussie devient une delivery FIFO avec ID stable, corrélation racine et `depth + 1`. Failure/cancel n'ajoutent rien.

## 30. Outbox Processor

Le processor utilise un dispatcher abstrait et aucun producteur réel. Il lit une tête FIFO hors lock de commit, effectue le dispatch, puis finalise contre l'état autoritatif courant sous la sérialisation outbox partagée.

## 31. Retry / Attempts

Seule une panne d'infrastructure avant planning est retryable. Le même `deliveryId` est conservé. Trois tentatives de dispatch maximum sont autorisées ; l'échec suivant terminalise sans nouvelle exécution.

## 32. Correlation / Depth

La corrélation racine et la causation sont conservées. `depth <= 8` est dispatchable ; une delivery de profondeur 9 est terminalisée avant callback avec diagnostic stable.

## 33. Terminal States

Success et terminal failure retirent le pending et enregistrent un receipt anti-replay. Un état autoritatif divergent est terminalisé `dataInconsistency` plutôt que fusionné silencieusement.

## 34. Strict Wire / Defensive Memory

Le codec rejette doublons pending/terminal et overlap du même ID. Un objet incohérent injecté en mémoire n'est pas redispatché : pending nettoyé, terminal conservé, diagnostic `dataInconsistency`.

## 35. F1-D Tests and Review

Les tests couvrent enqueue, FIFO, save/reload, success, retries, ID stable, terminal, depth 8/9, overlap mémoire/wire, émissions distinctes, anti-replay, exception, gate, atomicité, corrélation et producteurs qualifiés. R1 et R2 : PASS final.

## 36. Generated Files

Seuls les generated directement liés à `GameState` et `SaveData` ont changé. Deux passes finales build_runner ont écrit zéro output ; la seconde a tout skip. Avertissement non bloquant : SDK language 3.12 plus récent que l'analyzer 3.9 utilisé par le builder.

## 37. Tests Ciblés

Tous les gates ciblés F1-A/B/C/D ont été exécutés et sont verts. Les fichiers ciblés incluent authority/occurrence, planner/truth table/conditions, progress/codec/persistence, coordinator/lifecycle/concurrency, activity/save gate et outbox/retry/reentrancy.

## 38. Tests Complets

Résultats finaux frais :

```text
map_core      : 2987 tests passed
map_gameplay  : 278 tests passed
map_runtime   : 1645 passed, 1 historical skip, all other tests passed
runtime host  : 48 tests passed
```

## 39. Analyze and Build

```text
map_core dart analyze                         : No issues found
map_gameplay dart analyze                     : No issues found
map_runtime flutter analyze --no-fatal-infos  : exit 0, 348 infos, 0 warning, 0 error
runtime host flutter analyze --no-fatal-infos : exit 0, 1 historical info
macOS debug build                             : PASS
```

Application produite : `examples/playable_runtime_host/build/macos/Build/Products/Debug/playable_runtime_host.app`.

## 40. Runtime Host

`flutter pub get`, la suite complète, l'analyse et le build macOS debug ont réussi. `pub get` a signalé 21 packages plus récents incompatibles avec les contraintes courantes, sans changement de lockfile.

## 41. Performance

Mesures descriptives JIT, sans seuil, sur Apple M1 Pro, 32 GiB, macOS 27.0. Dart CLI 3.12.1 ; Flutter 3.46.0-0.3.pre avec Dart 3.13.0 beta. Warmups et itérations sont imprimés par le test.

Échantillons 10 000 :

| Cas | Moyenne | Médiane | p95 | Complexité déclarée |
|---|---:|---:|---:|---|
| planner oneShot consumed | 3566.22 us | 2889 us | 6393 us | O(n) |
| planner claim valid | 355.33 us | 157 us | 1872 us | O(1) lookup + sélection |
| planner tombstone | 0.11 us | 0 us | 1 us | O(1) |
| progress consumed codec | 11828.86 us | 11869 us | 12110 us | O(n) |
| progress pending codec | 37351 us | 35249 us | 46658 us | O(n) |
| outbox one FIFO head | 17085.43 us | 16568 us | 20396 us | O(n) remplacement immuable |

Le test couvre aussi 1/100/1000/10000 Events, conditions, claims et plusieurs sources. La mémoire est une approximation de fixture, pas une mesure RSS.

## 42. Compatibility

Les anciennes saves, Facts, pipeline legacy, registry/modes et claims existants sont préservés. Aucun eager migration, feature flag parallèle ou transformation de story flags n'a été ajouté. Le host confirme la compatibilité trans-package.

## 43. Scope Final

Modifications limitées à `map_core`, `map_gameplay`, application/infrastructure/tests `map_runtime`, roadmap et rapports. Aucun fichier `map_editor`, `map_battle`, présentation runtime, Selbrume, assets, host `lib`, lockfile ou `.dart_tool` n'a changé.

## 44. Risks

- F2 doit construire resolver, registry, claims et catalog depuis le même snapshot frais.
- La garantie de sérialisation suppose une instance partagée de `NarrativeEventStateTransactions` au composition root.
- Le chemin exact de divergence concurrente est protégé par terminalisation mais ne possède pas un test de race dédié.
- Aucun test unique ne traverse outbox + runtime port + repository ensemble ; les deux liaisons sont toutefois testées séparément.
- Les effets externes doivent assurer leur propre idempotence ; aucune garantie exactly-once externe.
- Les mesures JIT sont indicatives et dépendantes de la machine.

## 45. F2 Readiness

F2 est `READY`. Il pourra brancher les quatre sources de production sur les APIs F1, à condition d'utiliser un composition root unique pour snapshots, gate et transactions. V2-19 à V2-22 restent non commencés.

## 46. Auto-review

La première composition outbox permettait une réentrance transactionnelle fragile et risquait de perdre des pending ajoutés par un consumer. Elle a été remplacée par une sérialisation outbox dédiée, lecture hors commit lock et finalisation contre l'état courant. La validation catalog a également été renforcée pour rendre la préparation réellement fail-closed.

## 47. Contradictory Reviews

R1 a d'abord bloqué sur catalog, outbox/reentrance et atomicité concurrente. R2 a bloqué sur composition du gate et sincérité des frontières. Après corrections et nouveaux tests :

```text
R1 Runtime Integrity            : PASS, 0 blocker
R2 Compatibility Truthfulness   : PASS, 0 blocker
```

Les réserves non bloquantes sont reprises en section 44.

## 48. Prompt Critique

Le prompt est précis et ses gates ont évité de mélanger F1 avec F2. Son volume entraîne cependant des répétitions importantes entre rapport principal, Evidence Pack et sorties ciblées/complètes. Une future version pourrait fournir une table de preuves canonique unique et distinguer explicitement les champs delivery ratifiés des exemples indicatifs.

## 49. Verdict

```text
PHASE F1 : CLOSED / ACCEPTED

F1-0 — Contract Revalidation : PASS
F1-A — Dispatch Authority Planner : PASS
F1-B — Progress & Persistence : PASS
F1-C — Lifecycle & Busy Gate : PASS
F1-D — Outcome Outbox : PASS

V2-17 : PASS
V2-18 : PASS

Phase F2 : READY
```

Aucun bridge production, aucune UI, aucune donnée Selbrume et aucun commit Git n'ont été ajoutés.
