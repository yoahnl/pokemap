# PMCP-070 — Ports de playtest et session sandboxée

## Résumé exécutif

Verdict proposé : `DONE` pour PMCP-070. L’Authoring API expose désormais des
contrats de playtest purs et path-free. `map_runtime` adapte un driver isolé en
session start/pause/resume/stop avec commandes, événements ordonnés, snapshots,
diffs, capture et receipt. PokeMap Eval partage le même dispatcher entre ses
scénarios existants et le port API, recalcule la révision du projet, utilise son
save sérialisé en mémoire, et supprime récursivement son sandbox de capture.

Le roadmap `pokemap_roadmap_mecaniques_fangame.md` n’est pas modifié. Les lots
`FG-180` à `FG-184` restent `DONE`; `FG-185` reste `PARTIAL`, car ce lot ne
prouve ni signature/notarisation ni walkthrough humain de release.

## Scope confirmé

- Contrats/port : `map_authoring`, sans Flutter/Flame/I/O.
- Orchestration runtime : `map_runtime`.
- Adaptation PokeMap Eval et I/O temporaire : `playable_runtime_host`.
- Aucun transport MCP, aucune migration éditeur, aucun changement du projet
  Selbrume, aucune sauvegarde de production.

## Audit initial

- Base Git : `b13d74aa9 feat(authoring): add battle progression authoring` sur
  `main`, autorisé explicitement par l’utilisateur pour des commits par lot.
- PokeMap Eval possédait déjà `EvaluationDriver`, `EvaluationScenarioRunner`,
  un worker pool, snapshots/diffs/events/receipts et un save sérialisé en
  mémoire, mais aucun port Authoring API ni session pilotable hors scénario.
- Le runner contenait son propre switch privé : le dupliquer dans un adapter
  aurait créé deux vérités de capability.
- `ProjectTreeDigest` existait déjà et exclut saves/build/caches, ce qui permet
  une révision produit stable pendant l’exécution.
- Le workspace avait avant le lot : `examples/playable_runtime_host/pubspec.lock`
  modifié, le prototype `.superpowers/...` non suivi, et le rapport UI
  `reports/ui/world_map_editor_gate_5_evidence_pack_2026-07-29.md` non suivi.
  Ils restent hors commit.

## Fichiers

Créés :

- `pokemap_authoring_api_mcp_phase_6_implementation_plan.md` — plan et gates de
  la phase complète.
- `packages/map_authoring/lib/src/contracts/playtest_contracts.dart` — identité,
  lifecycle, commande, événement, snapshot/diff/résultat et receipt.
- `packages/map_authoring/lib/src/ports/playtest_port.dart` — port/session purs.
- `packages/map_authoring/test/contracts/playtest_contract_test.dart` — JSON,
  validation, immutabilité et liaison du receipt.
- `packages/map_runtime/lib/src/application/runtime_playtest_port.dart` —
  orchestration, guards de révision, replay d’événements et cleanup idempotent.
- `packages/map_runtime/test/runtime_playtest_port_test.dart` — lifecycle,
  ordre, pause, artefact, drift initial/en cours de session et double stop.
- `examples/playable_runtime_host/lib/src/evaluation/runner/evaluation_command_dispatcher.dart`
  — dispatcher unique des commandes réelles.
- `examples/playable_runtime_host/lib/src/evaluation/driver/evaluation_playtest_adapter.dart`
  — digest du tree, factory seedée, sandbox et capture content-addressée.
- `examples/playable_runtime_host/test/evaluation/evaluation_playtest_adapter_test.dart`
  — isolation et preuve sur le vrai runtime Selbrume.
- `reports/analysis/pmcp_070_sandboxed_playtest_sessions_evidence_appendix.md`
  — contenu complet des nouveaux fichiers Dart.

Modifiés :

- `packages/map_authoring/lib/map_authoring.dart` — exports publics.
- `packages/map_runtime/lib/map_runtime.dart` — façade des contrats et adapter.
- `examples/playable_runtime_host/lib/src/evaluation/driver/evaluation_driver.dart`
  — documentation de la frontière partagée.
- `examples/playable_runtime_host/lib/src/evaluation/runner/evaluation_scenario_runner.dart`
  — remplacement du switch privé par le dispatcher partagé; génération de
  diff/receipt inchangée.

## Passes séparées exigées par `codex_rule.md`

- **Audit / Architecture — PASS** : aucune dépendance inverse; un seul
  dispatcher; chemins locaux absents des contrats publics.
- **Implémentation — PASS** : lifecycle terminal, revision guard, JSON gelé,
  save éphémère et sandbox de capture supprimé.
- **Tests — PASS** : RED observé sur les trois packages, puis GREEN ciblé et
  suites complètes Authoring/Runtime.
- **Build / Validation — PASS** : tests compilants plus analyses des trois
  packages. Aucun exécutable distinct n’est produit par ce lot de librairie;
  `flutter test` constitue le build Flutter pertinent.
- **Critique finale — PASS avec limite tracée** : l’artefact PMCP-070 est une
  identité content-addressée dont le fichier temporaire est volontairement
  détruit. La persistance/get des artefacts appartient à PMCP-071.

Les vrais sub-agents n’ont pas été lancés : l’instruction développeur interdit
la délégation sans demande explicite. Les cinq passes ci-dessus sont donc des
passes locales séparées, comme le fallback prévu par `codex_rule.md`.

## TDD et commandes exactes

RED observé :

```text
dart test test/contracts/playtest_contract_test.dart
Result: compilation failed — PlaytestStartRequest/Command/Snapshot/Receipt absent.
flutter test test/runtime_playtest_port_test.dart
Result: compilation failed — RuntimePlaytestPort/Driver absent.
flutter test test/evaluation/evaluation_playtest_adapter_test.dart
Result: compilation failed — EvaluationPlaytestDriver absent.
```

GREEN final :

```text
packages/map_authoring
dart test test/contracts/playtest_contract_test.dart
Result: +4, all tests passed.
dart test
Result: +283, all tests passed.
dart analyze
Result: No issues found.

packages/map_runtime
flutter test test/runtime_playtest_port_test.dart
Result: +3, all tests passed.
flutter test
Result: +2282, ~1 skipped, all executed tests passed.
flutter analyze
Result: No issues found.

examples/playable_runtime_host
flutter test test/evaluation/evaluation_playtest_adapter_test.dart
Result: +2, all tests passed; le second test démarre le vrai runtime Selbrume.
flutter test test/evaluation/evaluation_playtest_adapter_test.dart \
  test/evaluation/evaluation_scenario_runner_test.dart
Result: +6 avant l’ajout du smoke Selbrume, all tests passed.
flutter analyze
Result: No issues found.
```

## Zones modifiées et invariants

- Le switch de `EvaluationScenarioRunner._executeCommand` est déplacé sans
  changement sémantique dans `EvaluationCommandDispatcher.execute`.
- `RuntimePlaytestPort.start` refuse toute révision différente et dispose le
  driver rejeté.
- Chaque observation/commande recalcule la révision; un drift bascule la
  session en `failed` et libère le driver.
- `stop` est idempotent, renvoie le même receipt et ne dispose qu’une fois.
- Le receipt lie projet/révision/scénario/seed/snapshot final/artefacts.
- Les captures exposent seulement `artifact://sha256/...`, jamais le chemin
  temporaire.

## Auto-critique, risques et non-objectifs

- Le seed est transporté jusqu’à la factory du driver et lié au receipt. Le
  driver Selbrume actuel conserve son RNG d’évaluation déterministe historique;
  PMCP-071/072 devront prouver les scénarios pour les seeds retenus plutôt que
  prétendre à une injection RNG arbitraire.
- Les commandes longues et l’accès durable aux octets d’artefact ne sont pas
  dans PMCP-070; ils sont explicitement le scope PMCP-071.
- Le worker pool existant n’est pas modifié dans ce lot : le port direct prouve
  d’abord le lifecycle; PMCP-071 unifiera get/events/cancel/retry.
- Aucun statut roadmap n’est écrit automatiquement.

## Git

État final attendu du lot : commit isolé
`feat(authoring): add sandboxed playtest sessions`. Le lockfile host et les
artefacts externes précités restent non stagés.
