# FG-183 — Regression Matrix V0

Date: 2026-07-21 · mise à jour Phase 4 le 2026-07-23

Proposed status: **DONE**

## Résumé exécutif

Cette matrice relie les lots FG-180 à FG-185 aux tests qui prouvent leur
contrat, distingue une boucle rapide des suites exhaustives et fournit les
commandes package-scoped attendues dans ce monorepo sans orchestrateur.

## Audit initial

- Branche : `main`.
- HEAD initial : `c06c49db`.
- Worktree initial : propre.
- Les Evidence Packs contenaient des commandes isolées, mais aucun document ne
  permettait de déterminer rapidement les régressions à relancer par lot.
- Inventaire frais : Core 332 fichiers de test, Gameplay 39, Battle 138,
  Runtime 209, Editor 468 et Runtime Host 33.

## Mapping lots vers tests rapides

| Lot | Contrat protégé | Commande rapide |
|---|---|---|
| FG-180 | Rapport de readiness, sévérités et fail-closed | `cd packages/map_core && dart test test/project_gameplay_readiness_test.dart` |
| FG-181 | Manifest, trois maps, données et walkthrough | `cd examples/playable_runtime_host && flutter test test/golden_fangame_slice_fixture_test.dart` |
| FG-182 | Parcours complet et transaction shop | `cd packages/map_gameplay && dart test test/party_bag_heal_operations_test.dart` puis `cd examples/playable_runtime_host && flutter test test/golden_fangame_slice_e2e_test.dart` |
| FG-183 | Existence des chemins et exécution de la matrice | Les commandes de la section « Gate Phase 10 » |
| FG-184 | Parsing roadmap/rapports et sortie Markdown | `cd packages/map_core && dart test test/gameplay_roadmap_dashboard_test.dart` puis CLI read-only |
| FG-185 | Agrégation fail-closed de cinq preuves | `cd packages/map_core && dart test test/mvp_release_gate_test.dart` |

## Gate rapide Phase 10

À exécuter pendant le développement :

```bash
cd packages/map_core
dart test \
  test/project_gameplay_readiness_test.dart \
  test/mvp_release_gate_test.dart \
  test/narrative_command_contract_parity_test.dart

cd packages/map_gameplay
dart test test/party_bag_heal_operations_test.dart

cd packages/map_runtime
flutter test \
  test/narrative_command_runtime_parity_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart \
  test/p6_selbrume_beta_validator_pass_test.dart \
  test/p6_selbrume_first_trainer_battle_golden_slice_test.dart \
  test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart \
  test/p6_selbrume_save_load_golden_slice_test.dart

cd examples/playable_runtime_host
flutter test \
  test/golden_fangame_slice_fixture_test.dart \
  test/golden_fangame_slice_e2e_test.dart \
  test/phase_a_golden_slice_launch_test.dart
```

## Matrice fonctionnelle étendue

| Domaine | Tests de référence |
|---|---|
| New Game / starter | `packages/map_gameplay/test/new_game_state_builder_test.dart`, `packages/map_runtime/test/playable_map_game_project_new_game_boot_test.dart` |
| Encounter / capture / PC | `packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart`, `packages/map_gameplay/test/capture_destination_operations_test.dart` |
| Trainer / récompenses / level-up | `packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart`, `packages/map_gameplay/test/battle_reward_operations_test.dart` |
| Bag / shop / heal | `packages/map_gameplay/test/party_bag_heal_operations_test.dart` |
| Field ability | `packages/map_gameplay/test/surf_evaluation_test.dart`, `packages/map_gameplay/test/script_system_integration_test.dart` |
| Save / reload | `packages/map_runtime/test/file_game_save_repository_test.dart`, `packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart` |
| Runtime battle handoff | `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart` |
| Contrat no-code / runtime | `packages/map_core/test/narrative_command_contract_parity_test.dart`, `packages/map_runtime/test/narrative_command_runtime_parity_test.dart` |
| Campagne Selbrume | `examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` |
| Golden Fangame Slice | `examples/playable_runtime_host/test/golden_fangame_slice_e2e_test.dart` |
| Release gate | `packages/map_core/test/mvp_release_gate_test.dart` |

## Commandes complètes par package

```bash
cd packages/map_core && dart test && dart analyze
cd packages/map_gameplay && dart test && dart analyze
cd packages/map_battle && dart test && dart analyze
cd packages/map_runtime && flutter test && flutter analyze
cd packages/map_editor && flutter test && flutter analyze
cd examples/playable_runtime_host && flutter test && flutter analyze
```

## Smokes et builds de release

```bash
cd packages/map_runtime
flutter test test/phase_a_golden_battle_slice_smoke_test.dart

cd examples/playable_runtime_host
flutter test test/phase_a_golden_slice_launch_test.dart
flutter test test/golden_fangame_slice_e2e_test.dart
flutter test test/selbrume_player_journey_e2e_test.dart

cd packages/map_editor
flutter build macos --debug

cd examples/playable_runtime_host
flutter build macos --debug
```

## Politique d’utilisation

1. Pendant un lot, exécuter son test ciblé après chaque RED/GREEN.
2. Avant le commit du lot, exécuter la gate rapide concernée et l’analyse du
   package touché.
3. Avant FG-185, exécuter toutes les suites, analyses, smokes et builds.
4. Une commande non exécutée reste `UNVERIFIED`; un rapport historique ne vaut
   pas preuve fraîche.

## Exécution fraîche de la gate rapide

Résultats du 2026-07-21 avant commit du lot :

```text
Core FG-180 + FG-185 : +11, All tests passed!
Gameplay shop/bag/heal : +14, All tests passed!
Runtime battle/P6 : +7, All tests passed!
Host fixture/E2E/launch : +3, All tests passed!
```

## Limites et risques

- La matrice ne lance aucune commande elle-même.
- Les fichiers de test peuvent évoluer; FG-184 rendra le statut des lots
  automatisable, pas la découverte sémantique de tous les tests.
- Les comptes de fichiers sont informatifs, pas des mesures de couverture.
- La roadmap canonique n’est pas modifiée.

## Passes obligatoires

| Passe | Verdict |
|---|---|
| Audit / Architecture | PASS — commandes package-scoped |
| Implémentation documentaire | PASS — lots, domaines et niveaux de gate reliés |
| Tests | PASS — gate rapide fraîche `+11`, `+14`, `+7`, `+3` |
| Build / Validation | Reporté à FG-185 pour la matrice exhaustive |
| Critique | PASS — aucune couverture chiffrée inventée |
