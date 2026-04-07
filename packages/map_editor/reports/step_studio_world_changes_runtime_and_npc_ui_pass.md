# Rapport — World changes Step Studio (runtime) + fiabilisation UI PNJ

**Date** : 2026-04-06  
**Périmètre** : `map_gameplay`, `map_runtime`, `map_editor` (aucune écriture Git).

---

## 1. Diagnostic initial

### Symptôme produit

- Les `worldChanges` du Step Studio étaient bien **sérialisés** dans `authoring.stepStudioDocument` (métadonnées du scénario `globalStory`).
- `PlayerProgression.completedStepIds` était bien **persisté** quand une step se terminait.
- En revanche, le runtime ne **lisait jamais** `worldChanges` pour filtrer les entités sur la carte.

### Cause racine exacte

Le pipeline existant ne branchait que :

- `MapEntityRuntimePredicateEvaluator.isNpcPresentOnMap` → règles **`visibilityRule` sur le PNJ** (map entity).
- Aucune lecture des `steps[].worldChanges[]` du JSON Step Studio.
- De plus, `NpcMapPresencePredicate` était `bool Function(MapEntity)` **sans** `mapId` : impossible d’appliquer correctement une règle dont la clé est `(mapId, entityId)` pour les cartes voisines chargées en même temps que la carte active.

---

## 2. Architecture retenue

### Source de vérité des `worldChanges`

- Même clé que le reste du runtime Step Studio : `kStepStudioDocumentMetadataKey` (`authoring.stepStudioDocument`).
- Parsing dans **map_runtime** (pas de dépendance à `map_editor`), en miroir de `buildStepCompletionCutsceneIndex` : parcours des scénarios `ScenarioScope.globalStory`, `jsonDecode`, lecture de `steps[].worldChanges[]`.

### Nouveau module

Fichier : `packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart`

- `StepStudioWorldPresenceRuleKind` : noms **stables** = `.name` des enums côté Step Studio (`visibleBeforeStepCompletion`, `hiddenAfterStepCompletion`, etc.).
- `StepStudioWorldPresenceRule` : `mapId`, `entityId`, `sourceStepId` (id de la **step** porteuse de la ligne), `presenceRule`.
- `buildStepStudioWorldPresenceRuleList(List<ScenarioAsset>)` : liste aplatie de toutes les règles.
- `entityPassesStepStudioWorldPresence(...)` : filtre pour un `MapEntity` donné sur une carte donnée.
- `presenceAllowedForStepStudioWorldRule` : sémantique booléenne documentée en commentaires.

### Stratégie de résolution (priorité)

Pour un PNJ sur une carte `mapId` :

1. **Règle entité** (`MapEntityNpcData.visibilityRule`) via `MapEntityRuntimePredicateEvaluator.isNpcPresentOnMap` — inchangée.
2. **Règles Step Studio** : si une ou plusieurs entrées matchent `(mapId, entity.id)`, **toutes** doivent autoriser la présence (**ET** logique). S’il n’y a aucune règle applicable → pas de contrainte Step Studio (comportement neutre).

Formule : `présent = baseEntité && stepStudioWorld`.

### Sémantique des `presenceRule`

| Règle (JSON / enum) | `sourceStepCompleted == false` | `sourceStepCompleted == true` |
|---------------------|-------------------------------|-------------------------------|
| `visibleBeforeStepCompletion` | présent | absent |
| `hiddenAfterStepCompletion` | présent | absent |
| `visibleAfterStepCompletion` | absent | présent |
| `visibleOnlyWhenCompleted` | absent | présent |

Remarque honnête : **`hiddenAfterStepCompletion` et `visibleBeforeStepCompletion` sont équivalents** sur la grille pour une step donnée (les libellés produit restent distincts dans le Step Studio).

### Extension `NpcMapPresencePredicate`

Fichier : `packages/map_gameplay/lib/src/gameplay_world_state.dart`

```dart
typedef NpcMapPresencePredicate = bool Function(
  String mapId,
  MapEntity npcEntity,
);
```

Les caches `_buildBlockingEntityByPos` / `_buildEntityByPos` passent `map.id` au prédicat.

Intégration runtime : `PlayableMapGame._npcPresencePredicateFor` enchaîne évaluateur + `entityPassesStepStudioWorldPresence` ; `_applyNpcVisibilityToLoadedMap` et `MapLayersComponent` utilisent `bundle.map.id` ; la détection trainer LoS utilise `_world.map.id`.

### Cache

`PlayableMapGame` met en cache la liste parsée tant que la **référence** `ProjectManifest` est `identical` à la précédente (`_ensureStepStudioWorldRulesForManifest`). Si le moteur recrée un manifest à chaque chargement, le cache se reconstruit (coût linéaire en nombre de steps / worldChanges — acceptable).

### Réactivité

`_refreshWorldNpcPresence()` était déjà appelé après complétion de step / chargement save / transitions pertinentes : **aucun changement de flux** nécessaire une fois le prédicat enrichi — le monde se reconstruit comme avant, mais le booléen inclut désormais les `worldChanges`.

---

## 3. Limites restantes (honnêtes)

- **Types d’entités** : seuls les **PNJ** passent par `NpcMapPresencePredicate`. Un `worldChange` ciblant un panneau, un item ou un spawn **n’a aucun effet** sur la grille tant que `map_gameplay` n’étend pas le filtre aux autres kinds.
- **`mapId` authoring** : la valeur doit correspondre à **`MapData.id`** (identifiant carte dans le projet), pas forcément au libellé affiché « Bourivka center ». Si l’auteur a choisi l’id technique dans le Step Studio, tout fonctionne ; sinon, décalage id / nom → règle non matchée.
- **Tests widget Flame** : pas de test `PlayableMapGame` complet ; la couverture repose sur des tests **logiques** + `GameplayWorldState` + parse JSON.

---

## 4. UI PNJ / flags (map_editor)

### Nœud Yarn (variantes)

- **Décision** : conserver le champ texte optionnel, avec une **note explicite** (bannière corail) dans `entity_properties_panel.dart` : dette produit assumée, vide = nœud défaut Dialogue Studio. Pas de picker de nœuds dans cette passe (scope / coût).

### Flags « catalogue »

- En plus de l’inférence existante depuis scénarios / Step Studio, fusion des entrées de  
  `ProjectManifest.globalProperties['authoring.knownStoryFlagIds']` (liste de chaînes, opt-in dans `project.json`).
- Test : `test/npc_runtime_rules_authoring_catalog_test.dart`.

---

## 5. Fichiers modifiés ou ajoutés

| Fichier | Rôle |
|---------|------|
| `map_runtime/.../step_studio_world_presence_runtime.dart` | **Nouveau** — parse + sémantique + `entityPassesStepStudioWorldPresence`. |
| `map_runtime/.../playable_map_game.dart` | Combine prédicat entité + world changes ; cache ; trainer LoS. |
| `map_runtime/.../map_layers_component.dart` | `presence(map.id, entity)`. |
| `map_gameplay/.../gameplay_world_state.dart` | Typedef + passage `map.id` dans les caches. |
| `map_gameplay/test/npc_map_presence_predicate_test.dart` | Signature du prédicat. |
| `map_runtime/test/step_studio_world_presence_runtime_test.dart` | **Nouveau** — parse, Emma cachée après step, `GameplayWorldState`, `visibleAfter`. |
| `map_editor/.../npc_runtime_rules_authoring_catalog.dart` | `authoring.knownStoryFlagIds`. |
| `map_editor/.../entity_properties_panel.dart` | Footnote transparence nœud Yarn. |
| `map_editor/test/npc_runtime_rules_authoring_catalog_test.dart` | **Nouveau**. |

---

## 6. Extraits de code clés

### Combinaison prédicat (runtime)

```261:280:packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
  NpcMapPresencePredicate _npcPresencePredicateFor(ProjectManifest manifest) {
    _ensureStepStudioWorldRulesForManifest(manifest);
    final worldRules = _cachedStepStudioWorldRules;
    return (String mapId, MapEntity npcEntity) {
      final base = MapEntityRuntimePredicateEvaluator(
        gameState: _gameState,
        chapterIndex: buildGlobalStoryChapterStepIndex(manifest.scenarios),
      ).isNpcPresentOnMap(npcEntity);
      if (!base) {
        return false;
      }
      return entityPassesStepStudioWorldPresence(
        mapId: mapId,
        entity: npcEntity,
        completedStepIds: _gameState.progression.completedStepIds,
        rules: worldRules,
      );
    };
  }
```

### Jeu « Emma » après complétion de step (test)

Le test `Emma disparaît après completion de la step` dans `step_studio_world_presence_runtime_test.dart` fixe `hiddenAfterStepCompletion` + `completedStepIds: ['step_2_1']` et attend `entityPassesStepStudioWorldPresence == false`.

---

## 7. Tests exécutés (résultats)

| Commande | Résultat |
|----------|----------|
| `dart test` dans `packages/map_gameplay` | **OK** (81 tests). |
| `flutter test test/step_studio_world_presence_runtime_test.dart test/map_entity_runtime_predicate_evaluator_test.dart` dans `packages/map_runtime` | **OK**. |
| `dart test test/npc_map_presence_predicate_test.dart` dans `packages/map_gameplay` | **OK**. |
| `flutter test test/npc_runtime_rules_authoring_catalog_test.dart` dans `packages/map_editor` | **OK**. |

**Non relancé ici** : `flutter test` complet `map_editor` (un test Global Story Studio workspace est connu flaky dans l’historique du dépôt).

---

## 8. Risques résiduels

- Auteurs confondant **nom** de carte et **id** technique dans `worldChanges.mapId`.
- Plusieurs règles contradictoires sur la même entité → **ET** strict peut tout masquer ; à documenter côté formation produit.
- Manifest recréé à identité différente à chaque frame → théoriquement pourrait invalider le cache trop souvent (peu probable dans le code actuel).

---

## 9. Ce qui est réellement branché après cette passe

- **Oui** : lecture JSON `worldChanges`, utilisation de `completedStepIds`, impact sur **collision**, **entityAt**, **rendu** (layers), **LoS trainer** (via le même prédicat que pour le gameplay visible).
- **Non** : world changes sur entités non-PNJ ; picker de nœuds Yarn pour les variantes de dialogue.

---

## 10. Vérification du cas « Emma / Bourivka »

Pour que le cas utilisateur fonctionne de bout en bout :

1. Dans le Step Studio, `worldChanges[].mapId` = **id** de la carte dans le manifeste (celui de `MapData.id` / entrée projet), pas seulement le nom d’affichage.
2. `entityId` = **`MapEntity.id`** du PNJ (ex. `emma`).
3. `presenceRule` = `hiddenAfterStepCompletion` sur la step qui se termine.
4. La step terminée doit avoir son id dans `completedStepIds` après l’événement de complétion (déjà géré par le runtime Step Studio existant).

Si ces quatre points sont alignés, Emma disparaît dès `_refreshWorldNpcPresence()` après mise à jour de la progression.
