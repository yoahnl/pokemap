# LOT 63 — MAP ENTITIES: comportement de déplacement PNJ simple et réutilisable

## 1. Résumé exécutif

Ce lot implémente une base **map-centric** de comportement overworld PNJ, strictement séparée de la narration:

- ajout d’un modèle `movement` sur les NPC (`idle`, `patrol`, `scriptedOnly`) dans `map_core`;
- ajout d’une UI réelle dans `EntityPropertiesPanel` pour éditer ce comportement;
- exécution runtime de la patrouille par défaut via la brique existante de déplacement scripté/pathfinding (pas de second moteur parallèle);
- règle de cohabitation cutscene respectée: le déplacement scripté prioritaire suspend la patrouille, puis la patrouille reprend.

Le lot reste dans le périmètre demandé (runtime + map entities editor + tests ciblés), sans toucher au système Global Story/Step/Cutscene authoring UI.

---

## 2. Objectif exact du lot

Permettre à une entité NPC de map d’avoir un comportement de déplacement par défaut:

- `idle`
- `patrol`
- `scriptedOnly`

avec:

- sérialisation/désérialisation robuste;
- édition depuis le panneau Map Entities;
- exécution overworld runtime avec pause/loop/vitesse simple;
- compatibilité claire avec le pilotage cutscene/scripté.

---

## 3. Périmètre et hors périmètre

### Inclus

- `map_core`: modèle de config de mouvement NPC + JSON;
- `map_editor`: UI d’édition de la config dans le panneau entité;
- `map_runtime`: application du comportement par défaut en overworld via le contrôleur de déplacement scripté;
- tests unitaires ciblés.

### Explicitement non traité

- UI scénario / story / step;
- nouvelle UX narrative;
- logique Global Story/Step;
- comportement avancé type wander conditionnel;
- caméra/timeline/choix joueur UI.

---

## 4. Audit initial (existant analysé)

Fichiers audités avant finalisation:

- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart`
- `packages/map_runtime/lib/src/application/scripted_entity_movement_models.dart`
- `packages/map_runtime/lib/src/application/scripted_entity_movement_controller.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/scripted_entity_movement_controller_test.dart`

Constat:

- brique de déplacement scripté/pathfinding déjà présente et réutilisable;
- absence de configuration de mouvement NPC par défaut côté modèle map;
- absence de UI dédiée dans Map Entities;
- `PlayableMapGame` avait déjà le point de branchement nécessaire via `_resetScriptedNpcMovementController`.

---

## 5. Décisions de conception retenues

## 5.1 Modèle simple et strict côté NPC

Ajout d’une config dédiée au payload NPC:

- `MapEntityNpcMovementMode`: `idle`, `patrol`, `scriptedOnly`
- `MapEntityNpcMovementConfig`:
  - `mode`
  - `waypoints`
  - `loop`
  - `pauseDurationMs`
  - `stepDurationMs`

Choix clés:

- configuration limitée au besoin produit du lot;
- valeurs par défaut sûres (`idle`, liste vide, pause 0, step 200ms);
- backward compatibility: si champ absent dans JSON existant, le PNJ reste immobile.

## 5.2 Réutilisation stricte du contrôleur de déplacement scripté

Pas d’implémentation concurrente:

- patrouille overworld branchée sur `ScriptedEntityMovementController`;
- ajout minimal dans le contrôleur pour supporter `pauseDurationMs` et `stepDurationMs`;
- le déplacement scripté ponctuel (`moveEntityTo`) continue d’être la commande prioritaire.

## 5.3 Cohabitation cutscene / overworld

Règle runtime appliquée:

- si une tâche de move scripté est active pour une entité, la patrouille n’interfère pas;
- quand la tâche se termine, la patrouille continue naturellement.

Techniquement, cette règle est assurée par la logique existante:

- `_tickPatrols` ignore l’entité si `_activeTasks.containsKey(entityId)` ou si `_isEntityStepping(entityId)`.

---

## 6. Implémentation détaillée

## 6.1 `map_core`: modèle de mouvement NPC

Fichier: `packages/map_core/lib/src/models/map_entity_payloads.dart`

Extrait clé:

```dart
enum MapEntityNpcMovementMode {
  @JsonValue('idle')
  idle,
  @JsonValue('patrol')
  patrol,
  @JsonValue('scriptedOnly')
  scriptedOnly,
}

@freezed
class MapEntityNpcMovementConfig with _$MapEntityNpcMovementConfig {
  @JsonSerializable(explicitToJson: true)
  const factory MapEntityNpcMovementConfig({
    @Default(MapEntityNpcMovementMode.idle) MapEntityNpcMovementMode mode,
    @Default(<GridPos>[]) List<GridPos> waypoints,
    @Default(true) bool loop,
    @Default(0) int pauseDurationMs,
    @Default(200) int stepDurationMs,
  }) = _MapEntityNpcMovementConfig;
}
```

Intégration au NPC:

```dart
@Default(MapEntityNpcMovementConfig()) MapEntityNpcMovementConfig movement,
```

Génération associée:

- `map_entity_payloads.freezed.dart`
- `map_entity_payloads.g.dart`

## 6.2 `map_editor`: UI d’édition dans Map Entities

Fichier: `packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart`

Ajouts principaux:

- état local d’édition:
  - `_npcMovementMode`, `_npcMovementLoop`, `_npcMovementPauseMs`, `_npcMovementStepMs`, `_npcWaypointRows`
- helpers:
  - `_npcMovementModeLabel(...)`
  - `_addNpcWaypointRow(...)`
  - `_npcMovementFields(...)`
- synchro lecture/écriture:
  - `_syncControllers(...)` lit `entity.npc?.movement`
  - `_saveSelectedEntity(...)` persist la config vers `MapEntityNpcData.movement`

Extrait UI:

```dart
InspectorEmbeddedDropdown(
  fieldLabel: _l('Déplacement PNJ', 'NPC movement'),
  valueLabel: _npcMovementModeLabel(_npcMovementMode),
  orderedIds: modeIds,
  ...
)
```

Comportement UI:

- mode `idle`/`scriptedOnly`: seuls les contrôles du mode sont affichés;
- mode `patrol`: affiche loop, pause, step duration, waypoints éditables;
- validation simple des waypoints (`X/Y` entiers obligatoires).

## 6.3 `map_runtime`: application du comportement overworld par défaut

### a) Helper pur de résolution

Nouveau fichier:

- `packages/map_runtime/lib/src/application/npc_overworld_movement_defaults.dart`

Responsabilité:

- transformer une `MapEntity` NPC configurée en `ScriptedEntityPatrolRoute?`;
- renvoyer `null` pour `idle`, `scriptedOnly` ou liste insuffisante.

### b) Extension minimale du modèle de patrouille

Fichier:

- `packages/map_runtime/lib/src/application/scripted_entity_movement_models.dart`

Ajout:

- `pauseDurationMs`
- `stepDurationMs`

### c) Contrôleur de déplacement scripté

Fichier:

- `packages/map_runtime/lib/src/application/scripted_entity_movement_controller.dart`

Ajouts:

- `ScriptedEntityStepStarter` accepte `double? durationSeconds`;
- `moveEntityTo(..., {double? stepDurationSeconds})`;
- `_MoveTask` transporte `stepDurationSeconds`;
- `_tickPatrols(double dt)` gère pause waypoint + restart segment;
- `startPatrol` garde l’API simple.

### d) Branchement dans `PlayableMapGame`

Fichier:

- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

Ajouts:

- import `resolveNpcDefaultPatrolRoute`;
- `startScriptedNpcPatrol` expose pause/step;
- `_startScriptedNpcStep` prend une durée optionnelle;
- `_resetScriptedNpcMovementController()` appelle `_applyNpcOverworldDefaultMovement()`;
- `_applyNpcOverworldDefaultMovement()`:
  - démarre la patrouille par défaut pour les NPC en mode `patrol`;
  - stoppe patrouille sinon.

---

## 7. Fichiers modifiés / créés

## 7.1 Fichiers modifiés

- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.freezed.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.g.dart`
- `packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart`
- `packages/map_runtime/lib/map_runtime.dart`
- `packages/map_runtime/lib/src/application/scripted_entity_movement_models.dart`
- `packages/map_runtime/lib/src/application/scripted_entity_movement_controller.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/scripted_entity_movement_controller_test.dart`

## 7.2 Fichiers créés

- `packages/map_core/test/map_entity_npc_movement_config_test.dart`
- `packages/map_runtime/lib/src/application/npc_overworld_movement_defaults.dart`
- `packages/map_runtime/test/npc_overworld_movement_defaults_test.dart`

---

## 8. Tests ajoutés et adaptés

## 8.1 `map_core`

`map_entity_npc_movement_config_test.dart`:

- defaults sûrs;
- roundtrip JSON patrol;
- backward compatibility (JSON sans `movement`).

## 8.2 `map_runtime`

`npc_overworld_movement_defaults_test.dart`:

- `idle` => pas de route;
- `scriptedOnly` => pas de route;
- `patrol` avec <2 waypoints => pas de route;
- `patrol` valide => route correcte.

`scripted_entity_movement_controller_test.dart` (extension):

- patrouille `loop=false`;
- pause waypoint;
- coexistence: override scripté puis reprise de patrouille.

---

## 9. Validations réellement exécutées

## 9.1 Format

Commande:

```bash
dart format packages/map_core/lib/src/models/map_entity_payloads.dart \
  packages/map_core/test/map_entity_npc_movement_config_test.dart \
  packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart \
  packages/map_runtime/lib/map_runtime.dart \
  packages/map_runtime/lib/src/application/scripted_entity_movement_models.dart \
  packages/map_runtime/lib/src/application/scripted_entity_movement_controller.dart \
  packages/map_runtime/lib/src/application/npc_overworld_movement_defaults.dart \
  packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart \
  packages/map_runtime/test/scripted_entity_movement_controller_test.dart \
  packages/map_runtime/test/npc_overworld_movement_defaults_test.dart
```

Résultat: OK.

## 9.2 Analyze ciblé

Commandes:

```bash
# map_editor
flutter analyze lib/src/ui/panels/entity_properties_panel.dart

# map_runtime
flutter analyze \
  lib/src/application/scripted_entity_movement_models.dart \
  lib/src/application/scripted_entity_movement_controller.dart \
  lib/src/application/npc_overworld_movement_defaults.dart \
  lib/src/presentation/flame/playable_map_game.dart \
  test/scripted_entity_movement_controller_test.dart \
  test/npc_overworld_movement_defaults_test.dart

# map_core
flutter analyze lib/src/models/map_entity_payloads.dart \
  test/map_entity_npc_movement_config_test.dart
```

Résultats:

- `map_editor`: **No issues found**
- `map_runtime`: **No issues found**
- `map_core`: **6 warnings `invalid_annotation_target`** sur `map_entity_payloads.dart`
  - warnings déjà présents sur ce pattern `freezed/json_serializable`
  - pas de blocage des tests ni de génération.

## 9.3 Tests ciblés

Commandes:

```bash
# map_core
flutter test test/map_entity_npc_movement_config_test.dart

# map_runtime
flutter test test/scripted_entity_movement_controller_test.dart \
  test/npc_overworld_movement_defaults_test.dart
```

Résultats:

- `map_core` test: **All tests passed**
- `map_runtime` tests ciblés: **All tests passed**

---

## 10. Limites restantes

- mode `patrol` ne fait pas encore d’édition graphique des waypoints sur canvas (édition numérique X/Y uniquement);
- pas de comportement avancé type random wander / avoidance complexe (hors scope du lot);
- warnings analyzer `map_core` (`invalid_annotation_target`) toujours présents sur ce fichier (pré-existant au lot).

---

## 11. Prochaines étapes logiques (hors lot)

- édition waypoints directement sur la map (UX);
- visualisation overlay runtime des routes;
- presets de comportement NPC supplémentaires (`guard`, `returnHome`) en conservant la même brique commune;
- tests intégration runtime plus proches du cycle complet map load -> actor spawn -> patrol run.

---

## 12. État git final exact

`git status --short`:

```text
 M packages/map_core/lib/src/models/map_entity_payloads.dart
 M packages/map_core/lib/src/models/map_entity_payloads.freezed.dart
 M packages/map_core/lib/src/models/map_entity_payloads.g.dart
 M packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/lib/src/application/scripted_entity_movement_controller.dart
 M packages/map_runtime/lib/src/application/scripted_entity_movement_models.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/scripted_entity_movement_controller_test.dart
?? packages/map_core/test/map_entity_npc_movement_config_test.dart
?? packages/map_runtime/lib/src/application/npc_overworld_movement_defaults.dart
?? packages/map_runtime/test/npc_overworld_movement_defaults_test.dart
```

`git diff --stat` (tracked):

```text
.../lib/src/models/map_entity_payloads.dart        |  38 ++-
.../src/models/map_entity_payloads.freezed.dart    | 314 +++++++++++++++++-
.../lib/src/models/map_entity_payloads.g.dart      |  36 ++
.../lib/src/ui/panels/entity_properties_panel.dart | 366 ++++++++++++++++++---
packages/map_runtime/lib/map_runtime.dart          |   2 +
.../scripted_entity_movement_controller.dart       |  37 ++-
.../scripted_entity_movement_models.dart           |   7 +-
.../src/presentation/flame/playable_map_game.dart  |  27 +-
.../scripted_entity_movement_controller_test.dart  | 166 ++++++++++
9 files changed, 933 insertions(+), 60 deletions(-)
```

