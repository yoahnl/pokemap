# Rapport : visibilité PNJ + dialogues conditionnels (runtime réel)

Date de rédaction : 2026-04-06. Aucune opération Git effectuée dans le cadre de cette passe.

## Diagnostic (état avant / besoin)

- Les **PNJ** (`MapEntityNpcData`) supportaient déjà un dialogue unique, dresseur, déplacement, etc., sans règle de visibilité ni chaîne de dialogues conditionnels côté données structurées.
- La **sauvegarde** exposait déjà `storyFlags` / `StoryFlags.activeFlags` et `PlayerProgression.completedStepIds` (steps Step Studio terminées).
- Il **manquait** une persistance explicite pour « cette cutscene locale a atteint la fin » indépendamment des steps, pour des prédicats du type « scène terminée » sur les PNJ.
- Les **chapitres** du Global Story Studio vivent dans la metadata `authoring.globalStoryStudioDocument` du scénario `globalStory` ; le runtime ne les lisait pas encore pour l’évaluation de conditions.

## Choix d’architecture

### Une seule règle de visibilité par PNJ

- Modèle : `visibilityRule: MapEntityNpcVisibilityRule?` — `null` ou mode `always` ⇒ toujours visible.
- Modes : `visibleWhen` / `hiddenWhen` + un `MapEntityRuntimePredicate` unique.
- **Pas** de liste AND/OR dans cette passe (lisibilité produit + scope maîtrisé).

### Dialogues conditionnels

- `conditionalDialogues` : liste **ordonnée** ; **première** variante dont la condition est vraie gagne ; sinon `dialogue` (défaut) ; sinon rien.

### Prédicats (`MapEntityRuntimePredicate`)

- `storyFlagSet` / `storyFlagUnset` → `GameState.storyFlags.activeFlags`.
- `stepCompleted` / `stepNotCompleted` → `PlayerProgression.completedStepIds`.
- `chapterCompleted` / `chapterNotCompleted` → toutes les `stepIds` du chapitre (metadata Global Story) doivent être / ne pas être toutes complétées.
- `cutsceneCompleted` / `cutsceneNotCompleted` → `PlayerProgression.completedCutsceneIds` (ids de scénarios **`localEventFlow`** dont le graphe a atteint `reachedEnd`).

### Persistance cutscene terminée

- Nouveau champ : `PlayerProgression.completedCutsceneIds`.
- Rempli dans `PlayableMapGame._finalizeScenarioRuntimeResult` lorsque `reachedEnd` et `ScenarioScope.localEventFlow` (les scénarios globaux ne sont **pas** ajoutés, pour éviter la confusion avec les cutscenes de carte).

### Séparation des paquets

- **map_core** : modèles JSON + validation `assertValidMapEntityTypedPayloads`.
- **map_gameplay** : `NpcMapPresencePredicate` + exclusion des PNJ des caches `_blockingEntityByPos` / `_entityByPos` si le filtre retourne `false`.
- **map_runtime** : parse chapitres (`global_story_chapter_runtime.dart`), évaluation (`map_entity_runtime_predicate_evaluator.dart`), branchement `PlayableMapGame`, rendu (`MapLayersComponent`, `OverworldActorComponent`).
- **map_editor** : **pas** d’UI no-code complète dans cette passe ; **préservation** des champs `visibilityRule` / `conditionalDialogues` à l’enregistrement d’une entité pour ne pas effacer du JSON importé.

## Fichiers modifiés ou ajoutés

### map_core

- `lib/src/models/map_entity_payloads.dart` (déjà enrichi en amont de la session) — enums / règles / variantes.
- `lib/src/models/save_data.dart` — `completedCutsceneIds`.
- `lib/src/operations/map_entities.dart` — validation visibilité + variantes dialogue.
- **Tests** : `test/map_entity_runtime_rules_serialization_test.dart`.

### map_gameplay

- `lib/src/gameplay_world_state.dart` — `NpcMapPresencePredicate`, caches filtrés, `withNpcMapPresencePredicate`.
- `lib/map_gameplay.dart` — export du typedef.
- **Tests** : `test/npc_map_presence_predicate_test.dart`.

### map_runtime

- `lib/src/application/global_story_chapter_runtime.dart` (**nouveau**).
- `lib/src/application/map_entity_runtime_predicate_evaluator.dart` (**nouveau**).
- `lib/src/application/step_studio_completion_runtime.dart` — `appendCompletedCutsceneIdIfAbsent`.
- `lib/src/presentation/flame/playable_map_game.dart` — prédicat monde, dialogues résolus, persistance cutscene, rafraîchissement visibilité, LoS trainers.
- `lib/src/presentation/flame/map_layers_component.dart` — masque les PNJ « élément projet ».
- `lib/src/presentation/flame/overworld_actor_component.dart` — `setGameplayVisible`.
- **Tests** : `test/map_entity_runtime_predicate_evaluator_test.dart`, `test/global_story_chapter_runtime_test.dart`, extension de `test/step_studio_completion_runtime_test.dart`.

### map_editor

- `lib/src/ui/panels/entity_properties_panel.dart` — reprise de `visibilityRule` et `conditionalDialogues` depuis l’entité existante lors du save.

## Branchement runtime (concret)

1. **Chaque** `GameplayWorldState.initial` / `fromMap` pertinent reçoit `npcMapPresencePredicate` basé sur `_npcPresencePredicateFor(manifest)` (ou le manifest cible avant assignation de `_bundle` lors des warps).
2. **Interaction PNJ** : `_resolveNpcDialogueRef` remplace l’usage direct de `entity.npc?.dialogue` (y compris fallback dresseur / défaite).
3. **Fin de scénario** : `_finalizeScenarioRuntimeResult` met à jour `completedStepIds` (existant) **et** `completedCutsceneIds` (nouveau), puis `_refreshWorldNpcPresence()`.
4. **Flags / outcomes / cutscene runner** : appels à `_refreshWorldNpcPresence()` après mutations de `_gameState` pertinentes (callbacks scénario, cutscene, fin de combat trainer, debug).
5. **Rendu** : calques + acteurs synchronisés via `_applyNpcVisibilityToLoadedMap` au montage de map et lors des refreshs.

## Ce qui marche réellement après cette passe

- Sérialisation / validation des règles PNJ au niveau **map_core**.
- **Gameplay** : PNJ absents de la grille (collision + `entityAt`) si le prédicat de présence est faux.
- **Runtime jouable** :
  - visibilité (sprite élément + personnage) + collision + interaction cohérents ;
  - résolution de dialogue par priorité + défaut ;
  - persistance `completedCutsceneIds` pour scénarios locaux terminés ;
  - chapitre « terminé » = toutes les steps listées dans `authoring.globalStoryStudioDocument` pour ce `chapterId` sont dans `completedStepIds`.
- **Éditeur** : enregistrer une entité PNJ **ne supprime plus** `visibilityRule` / `conditionalDialogues` s’ils sont déjà dans la carte (ex. JSON édité à la main).

## Ce qui n’est pas encore supporté

- **UI no-code** dans le panneau entité pour configurer visibilité et variantes (dropdowns flags / steps / chapitres / scènes / dialogues) : **non livré** ; seule la **rétention** des données à la sauvegarde est en place.
- **Combinaison** de plusieurs règles de visibilité (AND/OR) : non prévu dans le modèle actuel.
- **Scénario global** `reachedEnd` : **n’alimente pas** `completedCutsceneIds` (volontaire).
- **Chapitre** sans steps ou inconnu dans le document global : prédicats `chapterCompleted` → faux ; `chapterNotCompleted` → vrai (pas de faux « chapitre complété »).
- **Autres surfaces** runtime (signes, objets, etc.) : pas de visibilité conditionnelle dans cette passe.
- Tests **widget** éditeur sur les futurs dropdowns : non ajoutés.

## Risques restants

- **Double rafraîchissement** de présence PNJ sur certaines transitions scénario (callback `onGameStateUpdated` + `_finalizeScenarioRuntimeResult`) — coût acceptable, à profiler si besoin.
- **Auteurs** doivent aligner les `refId` avec les ids réels (flags, steps, `ScenarioAsset.id` local, ids de chapitre Global Story) ; sans UI, la marge d’erreur reste élevée.
- **LoS trainer** : les trainers sur PNJ « masqués » ne déclenchent plus la détection (cohérent avec l’absence sur la grille).

## Exemples de résolution

1. **Visibilité** : règle `visibleWhen` + prédicat `stepCompleted` / `refId: "intro_done"` → le PNJ n’occupe la grille qu’après que `intro_done` est dans `completedStepIds`.
2. **Dialogue** : variantes `[ (stepCompleted, s1 → dlgA), (storyFlagSet, f → dlgB) ]`, défaut `dlgC` ; si `s1` complétée → `dlgA` ; sinon si `f` actif → `dlgB` ; sinon `dlgC`.
3. **Cutscene** : scénario local `id: forest_scene` atteint `reachedEnd` → `completedCutsceneIds` contient `forest_scene` → prédicat `cutsceneCompleted` / `refId: forest_scene` devient vrai.

## Tests exécutés

- `dart test` dans `packages/map_core` : `test/map_entity_runtime_rules_serialization_test.dart`.
- `dart test` dans `packages/map_gameplay` : suite complète (inclut `npc_map_presence_predicate_test.dart`).
- `flutter test` dans `packages/map_runtime` : `map_entity_runtime_predicate_evaluator_test.dart`, `step_studio_completion_runtime_test.dart`, `global_story_chapter_runtime_test.dart`.

## Harmonisation libellés « Workspace » → « Studio »

Vérification rapide : pas de changement supplémentaire nécessaire dans cette passe (références déjà documentées ailleurs).
