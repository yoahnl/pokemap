# PMCP-071 — Commandes manquantes, jobs et artefacts

## Résumé exécutif

Verdict proposé : `DONE` pour PMCP-071. L'Authoring API expose désormais des
contrats purs pour les jobs longs, leurs événements, l'annulation, le retry et
les artefacts content-addressés. L'hôte d'évaluation relie ces contrats au vrai
worker pool avec une séquence stable côté service, une annulation bornée qui ne
prétend jamais avoir arrêté un worker bloqué, et des manifests sans chemin
machine. Le catalogue PokeMap Eval passe de 31 à 48 opérations et chaque
opération applicable possède un chemin de dispatcher explicite.

Le roadmap `pokemap_roadmap_mecaniques_fangame.md` n'est pas modifié. Les lots
`FG-180` à `FG-184` restent `DONE`; `FG-185` reste `PARTIAL`, faute de preuve de
signature/notarisation, d'installation froide et de walkthrough humain.

## Scope confirmé

- Contrats jobs/artefacts : `map_authoring`, sans Flutter, Flame ni I/O.
- Façade publique runtime : `map_runtime`.
- Exécution, collecte et commandes réelles : `playable_runtime_host`.
- Aucun transport MCP, aucune écriture du projet Selbrume et aucune commande
  opaque générique.

## Audit initial

- Base Git du lot : `66f15182d feat(authoring): add sandboxed playtest sessions`.
- Le worker pool possédait déjà isolation, protocole et receipts, mais aucun
  contrat Authoring `start/get/events/cancel/retry` ni manifeste commun.
- Le catalogue exposait 31 commandes, avec un switch partagé depuis PMCP-070;
  les actions roster/PC/bag/vente/bataille/shell restaient absentes.
- Les snapshots savaient affirmer le monde et le combat mais pas l'outcome de
  campagne comme racine de premier rang.
- Le lockfile hôte, le prototype `.superpowers/...` et les changements
  `map_editor` observés pendant le lot sont externes et restent hors commit.

## Fichiers

Créés :

- `packages/map_authoring/lib/src/contracts/artifact_contracts.dart` — types
  d'artefact, références content-addressées, manifeste et assertions visuelles.
- `packages/map_authoring/lib/src/contracts/job_contracts.dart` — lifecycle,
  requête, snapshot, événement, annulation et port de jobs.
- `packages/map_authoring/test/contracts/job_contract_test.dart` — invariants,
  transitions, JSON et validation du manifeste.
- `examples/playable_runtime_host/lib/src/evaluation/authoring/evaluation_authoring_job_service.dart`
  — service Authoring, adapter worker pool et collecteur de fichiers sûr.
- `examples/playable_runtime_host/lib/src/evaluation/driver/runtime_player_shell_automation.dart`
  — adapter typé vers le vrai `RuntimePlayerCoordinator`.
- `examples/playable_runtime_host/test/evaluation/evaluation_authoring_job_service_test.dart`
  — ordre, cancellation coopérative/bloquée, retry et artefacts.
- `examples/playable_runtime_host/test/evaluation/evaluation_phase6_command_catalog_test.dart`
  — parité exacte catalogue/dispatcher et capability truth.
- `examples/playable_runtime_host/test/evaluation/evaluation_phase6_assertions_test.dart`
  — assertions `scene` et `outcome`.
- `reports/analysis/pmcp_071_eval_jobs_artifacts_evidence_appendix.md` — contenu
  complet des nouveaux fichiers Dart.

Modifiés :

- `packages/map_authoring/lib/map_authoring.dart` — exports jobs/artefacts.
- `packages/map_runtime/lib/map_runtime.dart` — réexports publics.
- `examples/playable_runtime_host/lib/src/evaluation/contracts/evaluation_state_snapshot.dart`
  — racine gelée et sérialisée `outcome`.
- `examples/playable_runtime_host/lib/src/evaluation/driver/evaluation_driver.dart`
  — capabilities roster, battle et shell.
- `examples/playable_runtime_host/lib/src/evaluation/driver/selbrume_evaluation_driver.dart`
  — branchements réels party/PC/bag/shop/battle et snapshots scène/outcome.
- `examples/playable_runtime_host/lib/src/evaluation/interactive/interactive_evaluation_bridge.dart`
  — injection facultative du shell réel attaché.
- `examples/playable_runtime_host/lib/src/evaluation/runner/evaluation_assertion_evaluator.dart`
  — autorisation de la racine `outcome`.
- `examples/playable_runtime_host/lib/src/evaluation/runner/evaluation_command_dispatcher.dart`
  — 48 chemins explicites et contrôle des capabilities.
- `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart`
  — commandes, disponibilité et séquence utilisateur/diagnostic.
- `examples/playable_runtime_host/lib/src/evaluation/web/evaluation_worker_pool.dart`
  — arrêt forcé borné d'un worker bloqué.
- Tests existants du parser, du driver Selbrume et du port réel — nouvelles
  attentes, preuve par vraies mutations et budget explicite du smoke lourd.

## Passes séparées exigées par `codex_rule.md`

- **Audit / Architecture — PASS** : contrats purs dans `map_authoring`, I/O et
  runtime conservés dans l'hôte, façade sans chemins machine.
- **Implémentation — PASS** : lifecycle traçable, retries liés par `retryOf`,
  artefacts `image/log/receipt`, commandes applicables sans fallback opaque.
- **Tests — PASS** : RED observé sur contrats, service, catalogue et assertions,
  puis GREEN ciblé et suites complètes Authoring/Runtime.
- **Build / Validation — PASS** : analyses des trois packages vertes; le build
  Flutter pertinent est couvert par les tests compilants.
- **Critique finale — PASS avec limites tracées** : le shell n'annonce ses
  commandes que lorsqu'un vrai coordinateur est attaché; le ciblage manuel est
  déclaré non applicable au combat V1 mono-cible.

Les sub-agents n'ont pas été lancés : l'instruction développeur interdit la
délégation sans demande explicite. Ces cinq passes sont donc locales et
séparées, conformément au fallback de `codex_rule.md`.

## TDD et commandes exactes

RED observé :

```text
dart test test/contracts/job_contract_test.dart
Result: compilation failed — contrats jobs/artefacts absents.
flutter test test/evaluation/evaluation_authoring_job_service_test.dart
Result: compilation failed — service Authoring absent.
flutter test test/evaluation/evaluation_phase6_command_catalog_test.dart
Result: échec — catalogue incomplet et capabilities absentes.
flutter test test/evaluation/evaluation_phase6_assertions_test.dart
Result: échec — racine outcome absente.
```

GREEN final :

```text
packages/map_authoring
dart test
Result: +287, all tests passed.
dart analyze
Result: No issues found.

packages/map_runtime
flutter test
Result: +2282, ~1 skipped, all executed tests passed.
flutter analyze
Result: No issues found.

examples/playable_runtime_host
flutter test <10 fichiers PMCP-070/071 ciblés> --reporter compact
Result: +36, all tests passed.
flutter analyze
Result: No issues found.

Investigation de stabilité
/usr/bin/time -p flutter test test/evaluation/evaluation_playtest_adapter_test.dart \
  --plain-name 'canonical port drives the real Selbrume evaluation runtime' \
  --timeout 2m --reporter compact
Result: +1, all tests passed; real 64.95 s.
```

La tentative `flutter test test/evaluation --reporter compact` a terminé
`+134 ~2 -1` : le smoke Selbrume avait encore le timeout Flutter implicite de
30 s. La reproduction isolée mesurée à 64.95 s a établi la cause; le test porte
désormais explicitement un budget de deux minutes, et la matrice ciblée repasse
verte. Aucun comportement produit n'a été modifié pour masquer ce timeout.

## Zones modifiées et invariants

- Les événements de service sont renumérotés à partir de 1, indépendamment des
  séquences internes du worker conservées dans le payload.
- `cancel` retourne dans la borne demandée. Un worker coopératif devient
  `cancelled`; un worker bloqué reste honnêtement `cancelling` avec
  `bounded=false`, puis subit un `forceStop` best-effort.
- Un retry crée un nouvel ID/attempt et conserve la relation vers le job source.
- Les artefacts refusent IDs/séquences dupliqués, chemins hors racine et liens
  symboliques; le contrat ne publie que digest, taille, média et URI logique.
- L'ensemble des 48 clés du catalogue est exactement égal à
  `EvaluationCommandDispatcher.supportedOperations`.
- Les mutations party/PC/bag testées passent par `PlayerStorageOperations`, le
  vrai contrôleur player service et le commit/save runtime.
- Les actions UI sont explicitement indisponibles en headless; elles ne sont
  simulées que si un vrai shell est injecté.

## Auto-critique, risques et non-objectifs

- Les branches battle switch/progression/trainer/static sont typées et analysées,
  mais la preuve Selbrume de ce lot se concentre sur party/PC/bag; PMCP-072 doit
  les couvrir dans sa Golden Slice publique quand elles sont pertinentes.
- L'adapter du shell compile et respecte la capability truth, mais l'hôte
  headless n'invente pas de pause/options/Pokédex.
- Les assertions visuelles comparent l'identité des octets (média/digest/taille),
  pas une ressemblance perceptuelle.
- Aucun statut de roadmap n'est écrit automatiquement.

## Git

État final attendu : commit isolé
`feat(eval): add runtime jobs and artifacts`. Les changements externes
`map_editor`, le lockfile hôte et le prototype `.superpowers` restent non stagés.
