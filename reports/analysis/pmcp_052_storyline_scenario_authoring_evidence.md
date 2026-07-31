# PMCP-052 — Evidence Pack Storylines et migration Scenarios

Date : 2026-07-31
Lot : `PMCP-052 — Storylines et migration Scenarios`
Verdict proposé : `DONE`

## Résumé exécutif

Le lot expose le lifecycle Storyline, le reorder stable des Chapters/Steps,
les projections de progression, le lifecycle Scenario et l’import planifié
des Global Stories legacy. L’import est additif : le Scenario original reste
lisible et inchangé comme preuve de rollback.

Les reads Storyline rendent cycles, destinations manquantes, étapes
structurellement inatteignables, disponibilité et aperçu de complétion. Les
reads Scenario rendent la simulation pure et le plan de migration complet.

## Audit initial et verdicts

État Git initial : arbre suivi propre à
`017c1109 feat(authoring): add modern narrative authoring`.

L’audit narratif avait identifié les opérations Storyline et le preview
d’import legacy déjà présents dans `map_core`. Verdict : les adapter, conserver
les identités et ne jamais supprimer le reader/source legacy pendant l’import.

| Passe | Verdict | Signal |
|---|---|---|
| Audit narratif | Conforme | Projection et migration core réutilisées |
| TDD | Conforme | RED sur trois façades, puis 4 preuves vertes |
| Tests authoring | Conforme | 265 tests passent |
| Tests core | Conforme | 60 tests Storyline/Scenario passent |
| Analyse/format | Conforme | analyses vertes, 156 fichiers inchangés |
| Critique finale | Conforme avec limites | Reachability structurale, état runtime non inventé |

## Fichiers et zones modifiées

Créés :

- `packages/map_authoring/lib/src/domains/narrative/storyline_actions.dart`
- `packages/map_authoring/lib/src/domains/narrative/storyline_inspection.dart`
- `packages/map_authoring/lib/src/domains/narrative/scenario_actions.dart`
- `packages/map_authoring/test/domains/narrative/storyline_scenario_authoring_test.dart`
- `reports/analysis/pmcp_052_storyline_scenario_authoring_evidence.md`
- `reports/analysis/pmcp_052_storyline_scenario_authoring_evidence_appendix.md`

Modifiés :

- `packages/map_authoring/lib/map_authoring.dart`
- `packages/map_authoring/lib/src/domains/maps/map_mutation_dispatcher.dart`
- `packages/map_authoring/lib/src/registry/resource_kind_registry.dart`
- `packages/map_authoring/lib/src/workspace/project_query_service.dart`
- `packages/map_authoring/test/registry/action_registry_test.dart`

L’annexe reproduit le contenu complet des fichiers texte créés hors rapports
auto-référents. Le diff du commit dédié documente les zones exactes modifiées.

## Commandes et résultats exacts

```text
dart test test/domains/narrative/storyline_scenario_authoring_test.dart
RED initial : exit 1 — StorylineActions, StorylineInspector et
ScenarioActions absents.

Résultat final : 00:00 +4: All tests passed!

cd packages/map_authoring && dart test
00:14 +265: All tests passed!

cd packages/map_authoring && dart analyze
Analyzing map_authoring...
No issues found!

dart format --output=none --set-exit-if-changed lib test bin
Formatted 156 files (0 changed) in 0.23 seconds.

cd packages/map_core && dart test \
  test/storyline_authoring_operations_test.dart \
  test/storyline_progression_operations_test.dart \
  test/storyline_legacy_import_preview_test.dart \
  test/narrative_scenario_authoring_draft_test.dart \
  test/scenario_assets_test.dart
00:00 +60: All tests passed!

cd packages/map_core && dart analyze
Analyzing map_core...
No issues found!
```

## Preuves de fin

- Reorder Chapters/Steps normalise les ordres sans changer aucun identifiant.
- Un cycle `requires` est rendu par le diagnostic canonique `cycleDetected` et
  bloque la publication.
- Les Steps hors chemin structurel sont signalés `unreachableStep` sans
  prétendre connaître un `GameState` absent.
- Le preview expose candidats, issues, backup requis et condition de retrait
  du reader.
- L’import conserve `manifest.scenarios` byte-for-byte au round-trip et crée
  une Storyline avec `legacySource.sourceId` et reçu `imported=true`.
- La simulation Scenario rend seulement nœuds visités et effets prévisionnels,
  avec `sideEffectsApplied=false`.

## Roadmap gameplay

Le lot contribue aux lots narratifs `FG-080–FG-093`, sans fermer leurs preuves
runtime/UI end-to-end. Aucun statut du roadmap n’est modifié.

## Limites, risques et auto-critique

La reachability additionnelle est structurelle et émet un warning : elle ne
déclare pas une Step runtime-inaccessible lorsque ses conditions dépendent du
joueur. La simulation Scenario choisit le premier edge dans l’ordre auteur ;
elle sert à vérifier la forme et les effets, pas à remplacer l’exécuteur
runtime avec conditions et choix. La migration est volontairement additive,
donc un futur nettoyage devra attendre que `readerRemovalCondition` soit
satisfaite.

État Git final attendu : PMCP-052 seul commit, `.superpowers/...` externe non
staged et non modifié.
