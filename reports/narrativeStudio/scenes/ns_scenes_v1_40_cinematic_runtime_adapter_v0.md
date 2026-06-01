# NS-SCENES-V1-40 — Cinematic Runtime Adapter V0

Date : 2026-06-01

## 1. Resume executif

Le lot `NS-SCENES-V1-40 — Cinematic Runtime Adapter V0` est realise.

Le runtime Scene V1 ne fait plus un ack immediat pour les `CinematicNode`
canoniques. `SceneRuntimePlanIntent.playCinematic(cinematicId)` passe par un
adapter awaitable qui :

- resout uniquement les `CinematicAsset` canoniques depuis
  `ProjectManifest.cinematics` comme workflow normal ;
- transmet une request explicite a un player V0 testable ;
- attend une vraie completion asynchrone ;
- retourne le port Scene `completed` seulement apres completion ;
- propage un echec controle sans commit partiel des consequences Scene.

Les bridges `ScenarioAsset` / Cutscene Studio restent un chemin legacy
explicite, non promu comme canonical. Les refs inconnues echouent proprement.

## 2. Gate 0

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 15
```

Sortie initiale :

```text
/Users/karim/Project/pokemonProject
main
git status --short --untracked-files=all
Sortie : <vide>
git diff --stat
Sortie : <vide>
git diff --name-only
Sortie : <vide>
eadb0052 chore(reports): add missing screenshot for V1-15 wire anchor color code
0fe8fa1f feat(narrative): add cinematic scene builder picker v0 (NS-SCENES-V1-39)
6644def0 feat(narrative): add cinematics library v0 (NS-SCENES-V1-38)
05d631f8 feat(narrative): add cinematic asset core model v0 (NS-SCENES-V1-37)
ba7a91f3 update package_config.json
7c4667a4 feat(runtime): finalize cinematic v1 bridge decision and battle auto-switch
27ae87af chore(repo): ignore and untrack .idea workspace
1bc426a9 feat(runtime): sync gamepads plugin packages and host tests
2db4a2b4 Merge branch 'runtime-battle-bridge-psdk-restart'
5f6a17b7 feat(scenes): add facts and world rules manager ui v0
dcbf33b3 feat: complete PSDK runtime bridge diagnostics
8b78df97 feat(scenes): add v1-33 v1-34 runtime persistence projection gates
29c78ea8 chore(scenes): add v1-32 readiness checkpoint report
49fc181c chore(scenes): add v1-31-bis evidence report
9d012e04 feat(scenes): add scene consequence authoring UI
```

## 3. Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- prompt V1-40 attache
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_36_cinematic_v1_contract_bridge_decision.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_37_cinematic_asset_core_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_38_cinematics_library_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_39_cinematic_scene_builder_picker_v0.md`
- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_executor.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_host_callbacks.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_dialogue_runtime_awaitable_adapter.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_adapter.dart`
- `packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/map_runtime.dart`
- `packages/map_runtime/test/scene_event_runtime_hook_test.dart`
- `packages/map_runtime/test/scene_dialogue_runtime_awaitable_adapter_test.dart`
- `packages/map_runtime/test/scene_battle_runtime_outcome_adapter_test.dart`

## 4. Design Gate — Cinematic Runtime Adapter V0

1. `playCinematic` arrive dans `SceneRuntimeExecutor`, qui appelle
   `SceneRuntimeExecutionCallbacks.playCinematic`.
2. L'ancien ack etait dans
   `PlayableMapGame._buildSceneRuntimeHostCallbacks`, avec le log
   `[scene_runtime] cinematic bridge acknowledged id=...`.
3. Chemin actuel :
   `PlayableMapGame` -> `SceneEventRuntimeHook` ->
   `SceneRuntimeExecutor` -> `SceneRuntimeHostCallbacks.playCinematic`.
4. L'adapter est place dans
   `packages/map_runtime/lib/src/application/scene_runtime/`, comme les
   adapters Dialogue et Battle.
5. La resolution canonical lit `ProjectManifest.cinematics` et compare
   `CinematicAsset.id`.
6. Les bridges sont detectes via `buildCinematicPublicContracts(project)` et
   `CinematicPublicContractSourceKind.scenarioBridge`.
7. Contrat ajoute : `SceneCinematicRuntimeRequest`,
   `SceneCinematicRuntimeAwaitableResult`, `SceneCinematicRuntimePlayer`.
8. La temporalite est prouvee avec `Completer` dans les tests adapter et hook.
9. Le succes mappe vers `scenePortId == completed`.
10. Les echecs retournent `failed` ; dans le hook, l'exception callback donne
    `sceneExecutionFailed`, donc les consequences stagees ne sont pas commit.
11. Politique bridge : compatibilite legacy explicite, completed conserve,
    sans player canonical et sans promotion.
12. `ScenarioRuntimeExecutor` et `CutsceneRuntimeRunner` ne sont pas utilises :
    ils restent legacy et ne deviennent pas runtime canonical Cinematic V1.
13. Aucun Builder V2 n'est demarre.
14. Tests temporels : adapter pending, hook pending avant `setFact`,
    hook pending avant `markEventConsumed`, failure discard.

## 5. Scope realise

- Adapter runtime awaitable pour CinematicAsset canonique.
- Result/request/player runtime cinematic V0.
- Player no-visual borne et honnete.
- Wiring `PlayableMapGame.playCinematic`.
- Tests adapter canonical/unknown/bridge/failure/pending.
- Tests hook no partial writes apres cinematic pending/failure.
- Non-regressions core et runtime.
- Roadmaps mises a jour.

## 6. Decisions runtime

`SceneCinematicRuntimeNoVisualPlayer` n'est pas le futur playback visuel.
Il attend la duree estimee des steps `durationMs`, ou `Duration.zero` si la
timeline est vide. Le point produit important de V1-40 est l'attente awaitable
et le contrat de completion, pas l'interpretation visuelle.

## 7. Politique canonical / bridge legacy / unknown

- Canonical : `ProjectManifest.cinematics` contient l'id ; l'adapter cree une
  request, appelle le player et attend.
- Bridge legacy : l'id correspond a un contrat `scenarioBridge`; l'adapter
  retourne `legacyBridgeAcknowledged`, avec port `completed`, sans player
  canonical.
- Unknown : l'adapter retourne `failed(unknownCinematicId)`, aucun completed
  silencieux.

## 8. Adapter ajoute

Fichiers crees :

- `packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_result.dart`
- `packages/map_runtime/test/scene_cinematic_runtime_awaitable_adapter_test.dart`

Types ajoutes :

- `SceneCinematicRuntimePlayer`
- `SceneCinematicRuntimeRequest`
- `SceneCinematicRuntimeAwaitableAdapter`
- `SceneCinematicRuntimeNoVisualPlayer`
- `SceneCinematicRuntimeAwaitableStatus`
- `SceneCinematicRuntimeAwaitableErrorCode`
- `SceneCinematicRuntimeAwaitableResult`

## 9. Player V0 / completion policy

Le player V0 est no-visual. Il ne deplace pas d'acteur, ne joue pas de son,
n'affiche pas de dialogue, ne lance pas de combat et n'ecrit pas de
`GameState`. Il attend uniquement une duree bornee derivee de la timeline.

## 10. Wiring PlayableMapGame / SceneRuntimeHostCallbacks

`PlayableMapGame._buildSceneRuntimeHostCallbacks.playCinematic` cree un
`SceneCinematicRuntimeAwaitableAdapter` avec :

- `runtimeSourceId` scene/map/event/page ;
- `project: _bundle.manifest` ;
- `player: const SceneCinematicRuntimeNoVisualPlayer()`.

L'ancien log d'ack bridge est retire du chemin canonical.

## 11. Comportement temporel prouve

Tests avec `Completer` :

- l'adapter reste pending tant que le fake player n'a pas complete ;
- le hook reste pending avant de commit `setFact` apres cinematic ;
- le hook reste pending avant de commit `markEventConsumed` apres cinematic ;
- completion manuelle -> Scene continue -> consequence commit.

## 12. No partial writes / staging consequences

`SceneEventRuntimeHook` stage deja les consequences pendant l'execution et ne
commit que si `SceneRuntimeExecutor` termine en `completed`. Les nouveaux tests
prouvent :

- failure cinematic apres consequence stagee -> pas de `updatedGameState` ;
- unknown cinematic -> echec avant execution, pas de write ;
- `gameState` original reste non mute.

## 13. Tests ajoutes ou modifies

Ajoute :

- `packages/map_runtime/test/scene_cinematic_runtime_awaitable_adapter_test.dart`

Modifie :

- `packages/map_runtime/test/scene_event_runtime_hook_test.dart`

## 14. Commandes executees

```bash
cd packages/map_runtime && flutter test --reporter=compact test/scene_cinematic_runtime_awaitable_adapter_test.dart
cd packages/map_runtime && flutter test --reporter=compact test/scene_event_runtime_hook_test.dart
cd packages/map_runtime && flutter test --reporter=compact test/scene_runtime_golden_slice_smoke_test.dart
cd packages/map_core && dart test test/scene_runtime_plan_test.dart
cd packages/map_core && dart test test/scene_project_diagnostics_test.dart
cd packages/map_core && dart test test/linked_asset_public_contracts_test.dart
cd packages/map_core && dart analyze
cd packages/map_runtime && flutter analyze --no-fatal-infos lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_result.dart lib/map_runtime.dart lib/src/presentation/flame/playable_map_game.dart test/scene_cinematic_runtime_awaitable_adapter_test.dart test/scene_event_runtime_hook_test.dart
```

## 15. Resultats des tests

Red phase :

```text
scene_event_runtime_hook_test.dart a echoue avec types manquants :
SceneCinematicRuntimeAwaitableResult, SceneCinematicRuntimePlayer,
SceneCinematicRuntimeRequest, SceneCinematicRuntimeAwaitableAdapter.
```

Green phase :

```text
test/scene_cinematic_runtime_awaitable_adapter_test.dart: +7 All tests passed!
test/scene_event_runtime_hook_test.dart: +24 All tests passed!
test/scene_runtime_golden_slice_smoke_test.dart: +3 All tests passed!
test/scene_runtime_plan_test.dart: +15 All tests passed!
test/scene_project_diagnostics_test.dart: +7 All tests passed!
test/linked_asset_public_contracts_test.dart: +9 All tests passed!
```

## 16. Analyze

```text
cd packages/map_core && dart analyze
Analyzing map_core...
No issues found!

cd packages/map_runtime && flutter analyze --no-fatal-infos ...
Analyzing 6 items...
No issues found! (ran in 2.4s)
```

## 17. Recherches anti-scope

```bash
git diff --name-only -- packages/map_editor packages/map_battle packages/map_gameplay examples
```

Sortie :

```text
<vide>
```

Recherche anti-Builder V2 :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart:814: occurrence preexistante dans un message UI V1-38, aucun code V1-40.
```

Recherche anti-Selbrume sur les fichiers code V1-40 :

```text
<vide>
```

Recherche anti-gameplay dans l'adapter/result cinematic :

```text
<vide>
```

## 18. Fichiers crees

- `packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_result.dart`
- `packages/map_runtime/test/scene_cinematic_runtime_awaitable_adapter_test.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_40_cinematic_runtime_adapter_v0.md`

## 19. Fichiers modifies

- `packages/map_runtime/lib/map_runtime.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/scene_event_runtime_hook_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 20. Roadmaps mises a jour

V1-40 est ajoute comme DONE dans :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Prochain lot recommande :

```text
NS-SCENES-V1-41 — Cinematic Builder V0 Scope / Runtime Playback Contract
```

## 21. Limites connues

- Pas de playback visuel complet.
- Pas de Cinematic Builder V2.
- Pas de timeline editor UI.
- Pas de migration Scenario/Cutscene.
- Pas de branches cinematic skipped/failed authorables.
- Pas d'effets gameplay depuis Cinematic.

## 22. Non-objectifs confirmes

Confirme :

- aucun `map_editor` modifie ;
- aucun `map_battle` modifie ;
- aucun `map_gameplay` modifie ;
- aucun `examples` modifie ;
- aucun `ScenarioRuntimeExecutor` promu ;
- aucun `CutsceneRuntimeRunner` promu ;
- aucune donnee Selbrume creee ;
- aucun `StorylineStep.sceneLinkIds` branche ;
- aucun Builder V2 commence.

## 23. Evidence Pack

Fichiers nouveaux petits : les deux fichiers runtime cinematic et le test
adapter sont complets dans le diff.

Hunks majeurs :

- `map_runtime.dart` exporte l'adapter/result cinematic.
- `playable_map_game.dart` remplace l'ancien ack par
  `SceneCinematicRuntimeAwaitableAdapter`.
- `scene_event_runtime_hook_test.dart` ajoute les tests pending/no partial
  writes cinematic.
- roadmaps : entree V1-40 DONE et prochain lot V1-41.

Git status final :

```text
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/scene_event_runtime_hook_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart
?? packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_result.dart
?? packages/map_runtime/test/scene_cinematic_runtime_awaitable_adapter_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_40_cinematic_runtime_adapter_v0.md
```

Git diff --stat final :

```text
 packages/map_runtime/lib/map_runtime.dart          |  11 +
 .../src/presentation/flame/playable_map_game.dart  |  23 +-
 .../test/scene_event_runtime_hook_test.dart        | 414 +++++++++++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  15 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  19 +-
 5 files changed, 471 insertions(+), 11 deletions(-)
```

Git diff --name-only final :

```text
packages/map_runtime/lib/map_runtime.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/test/scene_event_runtime_hook_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Git diff --check final :

```text
<vide>
```

## 24. Auto-review critique

1. Canonical CinematicAsset est-il le seul workflow normal ? Oui.
2. `scenarioBridge` peut-il etre traite comme canonical ? Non.
3. L'ancien ack immediat existe-t-il encore pour canonical ? Non.
4. L'adapter attend-il une Future/Completer dans les tests ? Oui.
5. `completed` est-il retourne seulement apres completion ? Oui.
6. `skipped/failed/cancelled` deviennent-ils des branches authorables ? Non.
7. La cinematic peut-elle ecrire un Fact ? Non.
8. La cinematic peut-elle lancer un combat ? Non.
9. `ScenarioRuntimeExecutor` ou `CutsceneRuntimeRunner` sont-ils promus ? Non.
10. Builder V2 ou timeline editor ont-ils ete commences ? Non.
11. Aucune donnee Selbrume creee ? Oui.
12. Limite restante : le player V0 est no-visual ; le vrai playback et le
    Builder cinematic restent a cadrer.

## 25. Recommandation pour le prochain lot

```text
NS-SCENES-V1-41 — Cinematic Builder V0 Scope / Runtime Playback Contract
```

Raison : apres V1-40, Scene sait attendre une cinematic canonique. Il faut
maintenant cadrer le vrai playback/builder sans transformer Cinematic en script
gameplay ni ressusciter `ScenarioAsset` comme modele final.
