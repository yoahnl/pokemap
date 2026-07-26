# Evidence Pack — FG-092 / RM-015, commandes d'état NPC V0

Date de clôture technique provisoire : 2026-07-26
Lot : `RM-015`
Gap : `FG-092`
Roadmap source : `reports/gameplay/fg_000_remediation_and_personalization_roadmap.md`

## 1. Verdict

**Implémentation du lot : complète. Verdict de gate provisoire :
`PARTIAL`, promotion `DONE` proposée après la gate séquentielle de Phase 1.**

Le produit possède maintenant deux contrats narratifs no-code typés et
réellement consommés :

- `setNpcPresence`, conséquence persistante qui masque ou réactive un NPC ;
- `moveNpc`, commande interactive qui déplace un NPC présent vers un warp
  auteur et attend un résultat `completed` ou `blocked`.

Les preuves Core, Runtime, Selbrume et les analyseurs concernés sont vertes.
Les suites complètes Core et Runtime sont vertes. La suite complète Editor
concurrente a rencontré trois tests sensibles à la charge ; chacun repasse
isolément. Une exécution Editor complète séquentielle reste donc exigée par la
gate finale de Phase 1 avant de promouvoir formellement `RM-015` à `DONE`.

La roadmap n'est pas modifiée par ce lot.

## 2. Audit initial et rouges

### 2.1 État Git initial

Immédiatement après le commit `RM-012`, l'arbre contenait les changements
utilisateur préexistants suivants :

```text
 M apps/pokemap_hub/lib/src/ui/hub_app.dart
 M apps/pokemap_hub/lib/src/ui/hub_shell.dart
 M apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
 M apps/pokemap_hub/test/ui/hub_preferences_store_test.dart
 M apps/pokemap_hub/test/ui/hub_shell_test.dart
 M packages/map_player_ui/lib/src/localization/player_localizations.dart
 M packages/map_player_ui/lib/src/preferences/player_preferences.dart
```

Ils sont restés hors périmètre et ne doivent pas être inclus dans le commit du
lot.

### 2.2 Audit fonctionnel initial

| Couche | État initial | Écart |
|---|---|---|
| Core | mouvement scripté et prédicats de présence séparés | aucun contrat Scene unifié et sérialisable |
| Catalogue | pseudo-capacité NPC différée | publication mensongère impossible à prouver de bout en bout |
| Editor | pas de commande guidée NPC publiable | auteur obligé de sortir du flux no-code |
| Runtime | contrôleur de mouvement et projection de présence existants | aucune consommation des commandes Scene correspondantes |
| Selbrume | vrais NPC et warps disponibles | aucune preuve canonique consommant les deux contrats |

### 2.3 Rouges observés

La première passe Runtime a correctement échoué :

```text
non_exhaustive_switch_expression:
SceneInteractiveCommandKind.moveNpc n'était pas traité

undefined_named_parameter:
le paramètre moveNpc n'existait pas sur
SceneInteractiveCommandRuntimeExecutor

undefined_function:
sceneNpcPresenceMetadataKey n'était pas exporté
```

Une passe intermédiaire a aussi détecté l'import manquant de `MapEntityKind`
dans les diagnostics Core.

La première suite Runtime complète après implémentation a détecté trois
régressions réelles :

```text
Expected: null
Actual: GridPos(x: 1, y: 1)
```

Elles concernaient :

- la libération d'un mouvement NPC en attente après entrée dans un warp ;
- la conservation du propriétaire après rejet d'un remplacement inaccessible ;
- l'annulation du premier propriétaire après remplacement par un second
  mouvement.

Cause : la réactivation dynamique remontait tout NPC absent dont le prédicat
général était vrai, y compris un NPC volontairement transféré par warp.

Correction : le remontage dynamique est désormais réservé à un override Scene
explicite `present`; l'absence créée par un transfert reste autoritaire.

Enfin, la première suite Core complète a détecté deux attentes devenues
obsolètes :

- la matrice de vérité attendait encore `setNpcPresence` en `deferred` ;
- le test du catalogue attendait encore la conséquence NPC non publiable.

Ces gates attendent maintenant les deux contrats NPC en `promoted`/publiables.

## 3. Décisions et non-objectifs

### 3.1 Contrats

- La référence guidée Editor est `mapId::entityId`; elle est convertie en
  champs Core séparés `mapId` et `entityId`.
- `setNpcPresence` écrit une valeur persistante dans
  `GameState.metadata` :
  `pokemap.npcPresence.<mapId>.<entityId> = present|hidden`.
- Un override Scene explicite a priorité sur les prédicats de présence
  génériques et les World Rules.
- `moveNpc` cible un warp existant de la map active.
- Les sorties sont fermées : `completed` ou `blocked`.
- Un second `moveNpc` Scene sur le même NPC pendant un déplacement est rejeté
  afin de préserver un propriétaire d'attente unique.
- Le déplacement réel réutilise le contrôleur scripté et les règles de
  collision existantes ; aucune logique gameplay n'est déplacée dans Flame.

### 3.2 No-code

- Les deux commandes sont publiées dans le catalogue canonique.
- L'Editor fournit un sélecteur NPC guidé issu des maps connues.
- Le warp est choisi parmi les références auteur existantes.
- Aucun ID NPC brut n'est requis dans le flux normal.
- Les diagnostics rejettent map, NPC ou warp inconnus avant runtime.

### 3.3 Non-objectifs

- pas de système de trajectoire multi-waypoints auteur ;
- pas de téléportation silencieuse du NPC ;
- pas de mouvement vers une coordonnée brute ;
- pas de déplacement inter-map sans warp ;
- pas de refonte des patrouilles ;
- pas de modification des changements Hub/player UI préexistants ;
- pas de mise à jour de statut dans la roadmap avant la gate finale.

## 4. Inventaire et zones modifiées

### 4.1 Core

| Fichier | Zone précise |
|---|---|
| `packages/map_core/lib/src/models/scene_consequence.dart` | kind, factory, JSON et égalité de `SceneSetNpcPresenceConsequence` |
| `packages/map_core/lib/src/models/scene_interactive_command.dart` | kind, factory, sorties et JSON de `SceneMoveNpcInteractiveCommand` |
| `packages/map_core/lib/src/models/narrative_command_descriptor.dart` | paramètre guidé `npc` |
| `packages/map_core/lib/src/read_models/narrative_command_catalog.dart` | IDs et descripteurs publiables `setNpcPresence` / `moveNpc` |
| `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart` | validation map/NPC/warp et nouveaux codes d'erreur |
| `packages/map_core/lib/src/authoring/scene_authoring_operations.dart` | titre et validation de la conséquence NPC |
| `packages/map_core/lib/src/operations/narrative_symbolic_reachability_solver.dart` | projection symbolique de présence NPC |
| `packages/map_core/lib/src/runtime/scene_runtime_dry_run_preview.dart` | état dry-run `npcPresenceByRef` |
| `packages/map_core/test/narrative_command_catalog_test.dart` | promotion des contrats NPC |
| `packages/map_core/test/project_capability_truth_test.dart` | vérité de capacité NPC promue |
| `packages/map_core/test/narrative_command_contract_parity_test.dart` | parité sérialisation/diagnostics/catalogue |
| `packages/map_core/test/scene_runtime_dry_run_preview_test.dart` | projection de présence NPC |
| `packages/map_core/test/scene_npc_state_command_test.dart` | round-trips typés |

### 4.2 Editor

| Fichier | Zone précise |
|---|---|
| `packages/map_editor/lib/src/application/services/narrative_template_catalog.dart` | conversion du `npcRef` guidé vers les payloads typés |
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | options NPC guidées |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart` | alimentation du sélecteur depuis les maps |
| `packages/map_editor/test/narrative_template_catalog_test.dart` | construction des deux commandes |
| `packages/map_editor/test/scene_action_builder_test.dart` | authoring guidé et absence d'ID brut |
| `packages/map_editor/test/selbrume_npc_state_commands_test.dart` | preuve canonique avec Mael et le warp de la maison |

### 4.3 Runtime

| Fichier | Zone précise |
|---|---|
| `packages/map_runtime/lib/map_runtime.dart` | export des helpers de présence |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_npc_state_metadata.dart` | clé persistante et lecture d'override |
| `packages/map_runtime/lib/src/application/npc_runtime_presence.dart` | priorité de l'override Scene |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_write_result.dart` | erreur `unknownNpc` |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart` | validation et écriture persistante |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_interactive_command_runtime_executor.dart` | handler `moveNpc` |
| `packages/map_runtime/lib/src/application/scripted_entity_movement_controller.dart` | suivi ciblé d'un NPC réactivé |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | exécution réelle, attente terminale, purge/remontage et garde warp |
| `packages/map_runtime/test/narrative_command_runtime_parity_test.dart` | parité catalogue/runtime |
| `packages/map_runtime/test/npc_runtime_presence_test.dart` | override persistant |
| `packages/map_runtime/test/scene_consequence_runtime_writer_test.dart` | succès et NPC inconnu |
| `packages/map_runtime/test/scene_interactive_command_runtime_executor_test.dart` | routage `moveNpc` |
| `packages/map_runtime/test/scripted_entity_movement_controller_test.dart` | réactivation sans hard reset |

### 4.4 Fichiers créés

| Fichier | Rôle |
|---|---|
| `packages/map_core/test/scene_npc_state_command_test.dart` | contrats Core minimaux |
| `packages/map_editor/test/selbrume_npc_state_commands_test.dart` | preuve auteur sur le projet canonique |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_npc_state_metadata.dart` | stockage persistant de présence |
| `reports/gameplay/fg_092_npc_state_commands_v0.md` | présent Evidence Pack |

Le présent fichier constitue lui-même son contenu intégral. Le contenu intégral
des trois autres fichiers créés figure en annexe A.

## 5. Passes de vérification

Aucun sub-agent n'a été lancé pour ce lot, conformément à l'instruction de
coordination active. Les passes indépendantes suivantes ont été effectuées :

| Passe | Verdict |
|---|---|
| Contrat/Core | PASS après mise à jour des gates de catalogue et de vérité |
| Authoring/Selbrume | PASS, deux commandes construites avec références réelles |
| Runtime | PASS après correction du remontage post-warp |
| Régression complète Core | PASS |
| Régression complète Runtime | PASS |
| Régression complète Editor concurrente | PARTIAL : trois tests de charge rouges, trois retries isolés verts |
| Auto-critique finale | risque résiduel documenté, aucune dérive de package détectée |

## 6. Commandes et résultats exacts

### 6.1 Core

```bash
cd packages/map_core
dart test \
  test/project_capability_truth_test.dart \
  test/narrative_command_catalog_test.dart \
  test/scene_npc_state_command_test.dart \
  test/narrative_command_contract_parity_test.dart
dart analyze
```

Résultat final :

```text
+18: All tests passed!
No issues found!
```

Suite complète finale, reporter JSON :

```text
exit=0 success=True completed_events=4821 skipped=0 failed_count=0
```

### 6.2 Editor

```bash
cd packages/map_editor
flutter test \
  test/narrative_template_catalog_test.dart \
  test/scene_action_builder_test.dart \
  test/selbrume_npc_state_commands_test.dart
flutter analyze
```

Résultat :

```text
+21: All tests passed!
No issues found!
```

Suite complète concurrente :

```text
+4148 -3: Some tests failed.
```

Échecs et retries isolés :

| Test | Échec dans la suite | Retry isolé |
|---|---|---|
| `narrative_event_authoring_snapshot_performance_test.dart` | p95 `1 833 349 µs` > `1 250 000 µs` | `+1`, pass ; recovery gate p95 `113 047 µs` < `400 000 µs` |
| `narrative_global_search_performance_test.dart` | p95 `308 262 µs` > `220 000 µs` | `+1`, pass ; exact p95 `95 069 µs` |
| `selbrume_two_tier_stone_chain_visual_goldens_test.dart` | timeout 30 s | `+1`, pass |

### 6.3 Runtime

Commande ciblée :

```bash
cd packages/map_runtime
flutter test \
  test/npc_runtime_presence_test.dart \
  test/scene_consequence_runtime_writer_test.dart \
  test/scene_interactive_command_runtime_executor_test.dart \
  test/narrative_command_runtime_parity_test.dart \
  test/scripted_entity_movement_controller_test.dart
flutter analyze
```

Résultat final :

```text
+56: All tests passed!
No issues found! (ran in 4.4s)
```

Reproduction puis correction des trois régressions warp :

```bash
flutter test \
  test/playable_map_game_qualified_outcome_v2_integration_test.dart \
  --name 'advances and releases|preserves a wait-for-completion|cancels the first wait'
```

Résultat final :

```text
+3: All tests passed!
```

Suite complète finale, reporter JSON :

```text
exit=0 success=True completed_events=2434 skipped=1 failed_count=0
```

Smoke :

```bash
flutter test test/phase_a_golden_battle_slice_smoke_test.dart
```

Résultat :

```text
+3: All tests passed!
```

### 6.4 Hygiène

```bash
git diff --check
```

Résultat : exit `0`, aucune erreur.

## 7. Auto-critique et risques

1. **Gate Editor non encore intégralement verte dans une seule exécution.**
   Les trois échecs sont reproductiblement verts isolément, mais le DoD exige
   une suite séquentielle complète avant promotion formelle.
2. **Stockage metadata V0.** La clé est stable et persistée avec le GameState,
   mais ne possède pas encore de migration dédiée si le format de référence NPC
   change.
3. **Map active uniquement.** `moveNpc` refuse un NPC d'une map non active.
   C'est intentionnel pour éviter une simulation hors écran implicite.
4. **Concurrence volontairement stricte.** Un second mouvement Scene sur le
   même NPC est `blocked`; aucune file d'attente par NPC n'est fournie en V0.
5. **Réactivation.** Le NPC revient à sa position auteur, pas à sa dernière
   position avant masquage. Ce comportement est déterministe mais devra être
   explicité si un futur lot demande la conservation de position.
6. **Remontage Flame.** La création dynamique est couverte indirectement par les
   tests runtime et les régressions warp, sans golden visuel spécifique.
7. **Arbre dirty.** Les modifications utilisateur préexistantes restent
   présentes ; le commit du lot ne représentera donc pas un arbre globalement
   propre.

## 8. État Git avant commit

La passe finale doit exécuter :

```bash
git status --short --untracked-files=all
git diff --check
```

Les changements Hub et player UI listés en section 2.1 restent volontairement
hors index. Les fichiers de la section 4 constituent le seul périmètre
autorisable pour le commit `RM-015`.

## Annexe A — contenu intégral des fichiers créés

### A.1 `packages/map_core/test/scene_npc_state_command_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('NPC presence consequence round-trips as a typed persistent command',
      () {
    final consequence = SceneConsequence.setNpcPresence(
      mapId: 'map.selbrume',
      entityId: 'npc.guard',
      present: false,
    );

    final roundTrip = SceneConsequence.fromJson(consequence.toJson());

    expect(roundTrip, consequence);
    expect(roundTrip, isA<SceneSetNpcPresenceConsequence>());
  });

  test('NPC movement command round-trips with explicit blocked output', () {
    final command = SceneInteractiveCommand.moveNpc(
      mapId: 'map.selbrume',
      entityId: 'npc.guard',
      warpId: 'warp.exit',
    );

    final roundTrip = SceneInteractiveCommand.fromJson(command.toJson());

    expect(roundTrip, command);
    expect(roundTrip.outputPortIds, ['completed', 'blocked']);
  });
}
```

### A.2 `packages/map_editor/test/selbrume_npc_state_commands_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/narrative_template_catalog.dart';
import 'package:path/path.dart' as p;

void main() {
  test('Selbrume consumes both guided NPC state contracts', () {
    final root = _repositoryRoot();
    final project = ProjectManifest.fromJson(
      _readJson(p.join(root.path, 'selbrume', 'project.json')),
    );
    final map = MapData.fromJson(
      _readJson(
        p.join(
          root.path,
          'selbrume',
          'maps',
          'map_bourg_selbrume.json',
        ),
      ),
    );
    final payloads = <String, SceneNodePayload>{
      NarrativeCommandIds.setNpcPresence:
          buildScenePayloadForNarrativeCommand(
        commandId: NarrativeCommandIds.setNpcPresence,
        parameters: const {
          'npcRef': 'map_bourg_selbrume::npc_mael',
          'present': 'false',
        },
      ),
      NarrativeCommandIds.moveNpc: buildScenePayloadForNarrativeCommand(
        commandId: NarrativeCommandIds.moveNpc,
        parameters: const {
          'npcRef': 'map_bourg_selbrume::npc_mael',
          'warpId': 'warp_bourg_to_maison',
        },
      ),
    };

    for (final entry in payloads.entries) {
      final scene = _scene(entry.key, entry.value);
      final diagnostics = diagnoseSceneAgainstProject(
        scene,
        project,
        mapsById: {map.id: map},
      );

      expect(diagnostics.hasErrors, isFalse, reason: entry.key);
      expect(buildSceneRuntimePlan(scene).canBuild, isTrue, reason: entry.key);
      expect(
        SceneNodePayload.fromJson(entry.value.toJson()),
        entry.value,
        reason: entry.key,
      );
    }
  });
}

SceneAsset _scene(String commandId, SceneNodePayload payload) => SceneAsset(
      id: 'scene.selbrume.npc.$commandId',
      name: 'Selbrume NPC $commandId',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(id: 'command', kind: payload.kind, payload: payload),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'start-command',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'command',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'command-end',
            fromNodeId: 'command',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
        ],
      ),
    );

Map<String, dynamic> _readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

Directory _repositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
      return current;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Repository root containing Selbrume was not found.');
    }
    current = parent;
  }
}
```

### A.3 `packages/map_runtime/lib/src/application/scene_runtime/scene_npc_state_metadata.dart`

```dart
import 'package:map_core/map_core.dart';

String sceneNpcPresenceMetadataKey({
  required String mapId,
  required String entityId,
}) =>
    'pokemap.npcPresence.${mapId.trim()}.${entityId.trim()}';

bool? sceneNpcPresenceOverride(
  GameState gameState, {
  required String mapId,
  required String entityId,
}) {
  return switch (gameState.metadata[
      sceneNpcPresenceMetadataKey(mapId: mapId, entityId: entityId)]) {
    'present' => true,
    'hidden' => false,
    _ => null,
  };
}
```
