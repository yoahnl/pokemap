# NSC-37 — Registre de commandes narratives et exécuteurs typés

Date : 2026-07-20  
Verdict : **DONE proposé pour l’intégration NSC-37**  
Statuts FG-080 à FG-092 : **inchangés**

## Résumé exécutif

Le projet dispose d’un catalogue canonique unique décrivant ID, paramètres, lot FG, capacités model/editor/runtime, backend et wire de chaque commande narrative. Les effets persistants existants pointent exclusivement vers les huit `SceneConsequence`; Dialogue, Combat et Cinématique restent des nœuds Scene dédiés. Warp, boutique et PC utilisent un seul payload awaitable `SceneInteractiveCommand` porté par `SceneActionPayload`.

Le plan et l’exécuteur Scene connaissent ce wire, attendent un résultat explicite, échouent sans handler, refusent un port inconnu et inscrivent un receipt dans `SceneExecutionContext` afin qu’une reprise n’exécute pas deux fois la commande. Le runtime fournit un dispatcher fermé par type. L’index de dépendances inventorie Map/Warp/Shop, et les diagnostics bloquent une Map de destination inconnue.

Les commandes soin, badge, Field Ability et présence PNJ restent visibles mais `unsupported`; aucune mécanique FG inexistante n’est simulée.

## Audit initial et décisions

- `SceneConsequence` était déjà le wire canonique de huit effets persistants et son writer était atomique.
- `SceneActionPayload` ne portait qu’une conséquence ou un `actionKind` legacy.
- Aucun registre unique ne permettait à l’éditeur de distinguer backend, support et paramètres.
- `SceneRuntimeExecutor` savait attendre Dialogue/Combat/Cinématique mais pas une interaction générique typée.
- Décision : étendre l’Action node existant plutôt que créer un second type de graph node.
- Décision : le catalogue référence les contrats FG ; il ne change aucun statut FG et ne duplique aucun exécuteur métier.

## Passes locales

| Passe | Verdict |
|---|---|
| Lovelace — architecture | PASS : un effet = un backend = un wire. |
| Peirce — modèle/runtime | PASS : JSON, plan, dispatcher fermé, receipt idempotent. |
| Ramanujan — vérification | PASS : core complet +4162, ciblé core +94, runtime ciblé +12, analyses vertes. |
| Auto-critique | PASS avec limites honnêtes : les quatre mécaniques non prouvées restent non publiables. |

## Inventaire et zones précises

### map_core

- `lib/src/models/narrative_command_descriptor.dart` : contrat capabilities/backend/paramètres/wire.
- `lib/src/models/scene_interactive_command.dart` : payloads Warp/Shop/PC et ports explicites.
- `lib/src/read_models/narrative_command_catalog.dart` : catalogue canonique et entrées unsupported.
- `lib/src/diagnostics/narrative_command_diagnostics.dart` : unicité et destination Map.
- `lib/src/models/scene_asset.dart` : `SceneActionPayload.interactiveCommand`, JSON et exclusivité.
- `lib/src/runtime/scene_runtime_plan.dart` : intent `executeInteractiveCommand`.
- `lib/src/runtime/scene_runtime_plan_builder.dart` : compilation Action interactive.
- `lib/src/runtime/scene_runtime_executor.dart` : callback awaitable, contrôle des ports, receipt/reprise.
- `lib/src/read_models/narrative_dependency_index.dart` : usages Map/Warp/Shop.
- `lib/map_core.dart` : exports publics.
- tests : `scene_interactive_command_test.dart`, `narrative_command_catalog_test.dart`, extension ciblée de `narrative_dependency_index_test.dart`.

### map_runtime

- `lib/src/application/scene_runtime/scene_interactive_command_runtime_executor.dart` : dispatcher fermé.
- `lib/src/application/scene_runtime/scene_runtime_host_callbacks.dart` : seam facultatif rétrocompatible.
- `lib/map_runtime.dart` : export public.
- tests : `scene_interactive_command_runtime_executor_test.dart`, `narrative_command_save_load_integration_test.dart`.

## Commandes et résultats exacts

```text
cd packages/map_core
dart test test/scene_interactive_command_test.dart test/narrative_command_catalog_test.dart test/narrative_dependency_index_test.dart test/scene_runtime_plan_test.dart test/scene_runtime_executor_test.dart --reporter failures-only
+94: All tests passed!

dart analyze
No issues found!

dart test --reporter failures-only
+4162: All tests passed!
```

```text
cd packages/map_runtime
flutter test test/scene_interactive_command_runtime_executor_test.dart test/narrative_command_save_load_integration_test.dart test/narrative_scene_runtime_execution_test.dart test/scene_runtime_state_persistence_gate_test.dart --reporter failures-only
+12: All tests passed!

flutter analyze --no-fatal-infos
No issues found! (ran in 4.7s)
```

`git diff --check` sur les chemins NSC-37 : aucune sortie.

## État Git et isolation

- Base : `54f677b0 feat(narrative): complete dialogue studio workflow`.
- Le worktree global contient toujours plus d’un millier de chemins d’un chantier Border/Selbrume concurrent.
- Le commit NSC-37 utilise `git commit --only` sur le présent inventaire et ce rapport.
- Aucun fichier Event Builder, Selbrume ou Border Studio n’est inclus.

## Contenu des fichiers créés

Les fichiers créés ci-dessus sont de petits contrats et tests Dart sans génération. Leur contenu intégral canonique est celui enregistré par le commit NSC-37 ; le diff complet est consultable avec `git show <commit> --` sur l’inventaire. Cette référence au blob Git évite une copie documentaire susceptible de diverger.

## Risques, limites et auto-critique

- Le dispatcher runtime garantit le type, l’ordre, le résultat et le receipt ; l’intégration concrète d’un host doit fournir les handlers Warp/Shop/PC.
- Shop n’a pas encore de registre projet canonique dans `map_core`; sa dépendance est donc `legacyExternal` et non un faux target résolu.
- Heal Party, Badge, Field Ability et présence PNJ ne sont pas publiables. Présence PNJ doit passer par Fact + WorldRule.
- Le receipt réutilise `appliedPersistentNodeIds` car il porte déjà la sémantique de non-répétition du nœud ; un futur renommage en receipt générique pourrait clarifier ce rôle sans changer le wire.
- Les statuts FG-080 à FG-092 ne sont pas modifiés : ce lot prouve uniquement le parapluie d’intégration Narrative Studio.
