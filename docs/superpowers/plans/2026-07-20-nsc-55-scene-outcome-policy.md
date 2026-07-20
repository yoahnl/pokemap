# NSC-55 — Terminalité, défaite et politique de retry

## Objectif

Porter l'intention de terminalité sur l'unique propriétaire canonique,
`SceneEndPayload`, puis détecter sans heuristique les Events one-shot qui
peuvent consommer leur source avant une fin explicitement réessayable.

## Contrat et non-objectifs

- Ajouter une policy nullable `progression`, `retryable` ou
  `terminalFailureAccepted` à chaque fin de Scene.
- Un champ absent reste `null` et produit un diagnostic indéterminé ; aucun ID,
  titre ou label n'est interprété.
- La policy est projetée dans le plan runtime, sans changer la sémantique de
  checkpoint existante.
- Le diagnostic NSC-55 ne prouve que le retry narratif. La corrélation avec
  l'atteignabilité physique reste réservée à NSC-57 après NSC-56.
- Storyline et Event ne dupliquent jamais la policy.

## Étapes TDD

1. RED — ajouter les tests codec/round-trip et opération d'authoring core.
2. GREEN — ajouter l'enum, le champ nullable et l'opération pure.
3. RED — ajouter les scénarios Validator one-shot/retryable, correction,
   terminal accepté et absence de policy.
4. GREEN — produire uniquement des diagnostics fondés sur la policy explicite
   et la reachability NSC-54.
5. RED — ajouter le test du picker Scene Builder.
6. GREEN — relier le picker design-system à l'opération pure.
7. RED/GREEN — prouver la projection runtime, les gates de checkpoint et
   annoter la slice Phare Selbrume.
8. REFACTOR — formatter, lancer les tests ciblés puis les suites/analyzers et
   effectuer les passes Audit/Architecture, Tests, Build et Critique finale.

## Commandes de preuve

```bash
cd packages/map_core && dart test test/scene_authoring_operations_test.dart test/project_manifest_scenes_test.dart test/narrative_project_validator_test.dart
cd packages/map_core && dart test && dart analyze
cd packages/map_editor && flutter test test/scene_outcome_policy_authoring_test.dart
cd packages/map_editor && flutter test && flutter analyze
cd packages/map_runtime && flutter test test/scene_runtime_state_persistence_gate_test.dart
cd packages/map_runtime && flutter test && flutter analyze
cd examples/playable_runtime_host && flutter test test/selbrume_lighthouse_retry_integration_test.dart
cd examples/playable_runtime_host && flutter test && flutter analyze
```
