# NS-SCENES-V1-23-bis — Event to Scene Link V0

## 1. Résumé du lot

`NS-SCENES-V1-23-bis` est livré.

Le lot ajoute le plus petit contrat persistant honnête pour relier une page d’event de map à une Scene V1 :

```text
MapEventPage.sceneTarget -> MapEventSceneTarget(sceneId)
```

Le lien est authoring-only. Il ne lance aucune Scene en runtime, ne crée aucun `SceneRuntimePlan`, ne promeut pas `ScenarioAsset` et ne branche pas `StorylineStep.sceneLinkIds`.

## 2. Rappel du scope

Réalisé :

- modèle JSON/Freezed `MapEventSceneTarget` ;
- champ optionnel `MapEventPage.sceneTarget` ;
- opérations pures `setMapEventPageSceneTarget` et `clearMapEventPageSceneTarget` ;
- validation MapValidator des refs Scene quand le manifest est disponible ;
- diagnostics purs Event -> Scene ;
- picker Scene V1 borné dans `EventPropertiesPanel` ;
- tests core et widget editor ;
- roadmaps mises à jour.

Non-objectifs respectés :

- pas de runtime Scene ;
- pas de `SceneRuntimePlan` ;
- pas de `SceneRuntimeExecutor` ;
- pas de `StorylineStep.sceneLinkIds` ;
- pas de `MapEventDefinition.sceneId` global ;
- pas de metadata magic string ;
- pas de fake scene/event/ref ;
- pas de données Selbrume.

## 3. Gate 0 complet

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sorties :

```text
/Users/karim/Project/pokemonProject
main
git status initial :
Sortie : <vide>
git diff --stat initial :
Sortie : <vide>
git diff --name-only initial :
Sortie : <vide>
a2e14b19 docs(scenes): add V1-23 architecture decision and roadmap updates
9e85a187 feat(scenes): add payload pickers for linked assets,workdir:/Users/karim/Project/pokemonProject
e3325807 feat(scenes): add linked asset contracts and scene V0 node deletion
d170d0da docs(scenes): add linked-asset contracts audit and update roadmaps
48f3d520 docs(scenes): add checkpoint narrative studio direction and update roadmaps
c9a3d6e2 docs(scenes): add roadmap checkpoint correction and roadmap updates
23fc0436 chore(selbrume): update project scene condition metadata
4d25c19b Fix scene graph zoom scaling
3f9e2671 refactor(editor): route narrative modes to empty inspector
a87ba24a feat(scenes): add world rule model and authoring pipeline
```

## 4. Changements préexistants vs changements du lot

Changements préexistants :

```text
Sortie : <vide>
```

Changements introduits par ce lot :

- fichiers core modèle/generated/opérations/validation/diagnostics/tests ;
- fichier editor `EventPropertiesPanel` et test widget ciblé ;
- roadmaps Scenes ;
- présent rapport.

## 5. Fichiers créés/modifiés

Fichiers créés :

```text
packages/map_core/lib/src/diagnostics/event_scene_link_diagnostics.dart
packages/map_core/test/event_scene_link_diagnostics_test.dart
packages/map_editor/test/event_properties_panel_scene_target_test.dart
reports/narrativeStudio/scenes/ns_scenes_v1_23_bis_event_to_scene_link_v0.md
```

Fichiers modifiés :

```text
packages/map_core/lib/map_core.dart
packages/map_core/lib/src/models/map_event_definition.dart
packages/map_core/lib/src/models/map_event_definition.freezed.dart
packages/map_core/lib/src/models/map_event_definition.g.dart
packages/map_core/lib/src/operations/map_events.dart
packages/map_core/lib/src/validation/validators.dart
packages/map_core/test/map_events_test.dart
packages/map_editor/lib/src/ui/panels/event_properties_panel.dart
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## 6. Design retenu

Le lien vit sur `MapEventPage`, pas sur `MapEventDefinition`.

Raison : un event de map est un conteneur positionné, alors que la page porte déjà le comportement actif conditionnel : condition, script, message, hidden/disabled. Le lien Scene V1 doit donc dépendre de la page active.

Le modèle retenu est volontairement petit :

```dart
@freezed
class MapEventSceneTarget with _$MapEventSceneTarget {
  @JsonSerializable(explicitToJson: true)
  const factory MapEventSceneTarget({
    required String sceneId,
  }) = _MapEventSceneTarget;
}
```

## 7. Modèle Event -> Scene ajouté

`MapEventPage` gagne :

```dart
@JsonKey(includeIfNull: false) MapEventSceneTarget? sceneTarget,
```

Règles :

- `null` = pas de cible Scene V1 ;
- `sceneTarget.sceneId` = id de `SceneAsset` attendu dans `ProjectManifest.scenes` ;
- aucun runtime implicite ;
- aucun remplacement automatique de `message` ou `script`.

## 8. JSON / compatibilité

Compatibilité prouvée par tests :

- ancien JSON sans `sceneTarget` donne `MapEventPage.sceneTarget == null` ;
- `sceneTarget == null` n’est pas sérialisé comme objet vide ;
- JSON avec `sceneTarget` roundtrip correctement ;
- `copyWith` conserve `sceneTarget`.

`build_runner` a été nécessaire car `map_event_definition.dart` est un modèle Freezed/JSON.

## 9. Opérations authoring ajoutées

Opérations pures :

```dart
MapData setMapEventPageSceneTarget(
  MapData map, {
  required String eventId,
  required int pageNumber,
  required String sceneId,
})
```

```dart
MapData clearMapEventPageSceneTarget(
  MapData map, {
  required String eventId,
  required int pageNumber,
})
```

Garanties :

- pas de mutation de `MapData` original ;
- cible `eventId + pageNumber` ;
- conserve message, script, condition, metadata, sprite et flags de page ;
- refuse event inconnu ;
- refuse page inconnue ;
- refuse `sceneId` vide ;
- ne valide pas toute la Scene cible, ce rôle reste aux validators/diagnostics.

## 10. Diagnostics ajoutés

Nouveau diagnostic pur :

```dart
EventSceneLinkDiagnosticsReport diagnoseEventSceneLinks({
  required ProjectManifest project,
  required Iterable<MapData> maps,
})
```

Codes :

```text
eventSceneTargetUnknown
eventSceneTargetEmpty
eventSceneTargetDisabledPage
eventSceneTargetSceneHasErrors
```

Décision severity :

- cible vide : error ;
- scene inconnue : error ;
- page disabled avec cible : warning ;
- Scene cible avec diagnostics Scene errors : warning.

Le warning pour Scene cible invalide évite de sur-bloquer les drafts authoring, tout en rendant le problème visible avant le runtime.

## 11. UI editor ajoutée

Dans `EventPropertiesPanel`, la section page affiche maintenant :

- picker `Scene V1` depuis `ProjectManifest.scenes` ;
- état vide `Aucune Scene V1 disponible` ;
- valeur `Aucune Scene V1` si aucun lien ;
- label lisible `Nom Scene (scene_id)` ;
- bouton `Retirer Scene` ;
- message `Lien authoring uniquement, runtime Scene à venir.` ;
- warning si message/script legacy coexistent avec le lien Scene.

Le flux reste cohérent avec le panneau existant : l’auteur choisit une Scene puis enregistre la page.

## 12. Ce qui reste authoring-only

Le lien est stocké et validable, mais il ne déclenche rien. Il prépare le futur runtime sans le démarrer.

## 13. Pourquoi aucun runtime n’a été codé

Le lot V1-23-bis devait seulement rendre le lien authoring persistant. L’exécution appartient au futur plan pur `NS-SCENES-V1-24 — Scene Runtime Plan V0`, puis à un executor runtime ultérieur.

## 14. Pourquoi aucun ScenarioAsset n’a été promu

Le lien cible `ProjectManifest.scenes` et `SceneAsset`. `ScenarioAsset` reste legacy/bridge et n’est pas utilisé comme modèle final de Scene V1.

## 15. Pourquoi aucune donnée Selbrume n’a été créée

Les tests utilisent des IDs neutres (`scene_intro`, `event_gate`, `map_test`) et aucun nom produit Selbrume. Aucune fixture produit n’est ajoutée.

## 16. Tests exécutés avec sorties exactes

### RED core

Commande :

```bash
cd packages/map_core && dart test test/map_events_test.dart test/event_scene_link_diagnostics_test.dart
```

Sortie :

```text
Failed to load "test/map_events_test.dart":
Error: Couldn't find constructor 'MapEventSceneTarget'.
Error: No named parameter with the name 'sceneTarget'.
Error: Method not found: 'setMapEventPageSceneTarget'.
Error: Method not found: 'clearMapEventPageSceneTarget'.
Failed to load "test/event_scene_link_diagnostics_test.dart":
Error: Method not found: 'diagnoseEventSceneLinks'.
Error: Undefined name 'EventSceneLinkDiagnosticCode'.
Error: Undefined name 'EventSceneLinkDiagnosticSeverity'.
Some tests failed.
```

### RED editor

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/event_properties_panel_scene_target_test.dart
```

Sortie :

```text
Compilation failed:
Error: Couldn't find constructor 'MapEventSceneTarget'.
Error: The getter 'sceneTarget' isn't defined for the type 'MapEventPage'.
Some tests failed.
```

### GREEN core ciblé

Commande :

```bash
cd packages/map_core && dart test test/map_events_test.dart test/event_scene_link_diagnostics_test.dart
```

Sortie :

```text
00:00 +0: loading test/map_events_test.dart
00:00 +0: test/map_events_test.dart: map event scene targets reads older page JSON without sceneTarget as null
00:00 +1: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target
00:00 +15: All tests passed!
```

### GREEN editor ciblé

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/event_properties_panel_scene_target_test.dart
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/event_properties_panel_scene_target_test.dart
00:01 +0: scene picker selects and clears a real Scene V1 target
00:02 +1: scene picker selects and clears a real Scene V1 target
00:02 +1: scene picker shows an honest empty state when no scenes exist
00:02 +2: All tests passed!
```

### Regression Scenes workspace

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/scenes_workspace_shell_test.dart
00:08 +52: All tests passed!
```

### Regression overview shell

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
00:05 +19: All tests passed!
```

### Regression projection narrative

Première tentative :

```bash
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
```

Sortie :

```text
Failed to code sign binary: exit code: 1  /Users/karim/Project/pokemonProject/packages/map_editor/build/native_assets/macos/objective_c.dylib: No such file or directory
```

Relance :

```bash
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/narrative_workspace_projection_test.dart
00:01 +0: buildNarrativeWorkspaceProjection splits global story and local flows, and projects steps
00:01 +3: All tests passed!
```

## 17. Analyze avec sortie exacte

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie :

```text
Analyzing map_core...
No issues found!
```

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/panels/event_properties_panel.dart test/event_properties_panel_scene_target_test.dart
```

Sortie :

```text
Analyzing 2 items...

   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/panels/event_properties_panel.dart:339:11 • prefer_const_constructors
   info • 'minSize' is deprecated and shouldn't be used. Use minimumSize instead. This feature was deprecated after v3.28.0-3.0.pre. Try replacing the use of the deprecated member with the replacement • lib/src/ui/panels/event_properties_panel.dart:679:19 • deprecated_member_use
   info • Use 'const' for final variables initialized to a constant value. Try replacing 'final' with 'const' • lib/src/ui/panels/event_properties_panel.dart:1118:5 • prefer_const_declarations
   info • 'minSize' is deprecated and shouldn't be used. Use minimumSize instead. This feature was deprecated after v3.28.0-3.0.pre. Try replacing the use of the deprecated member with the replacement • lib/src/ui/panels/event_properties_panel.dart:1141:17 • deprecated_member_use

4 issues found. (ran in 1.7s)
```

`--no-fatal-infos` était demandé pour l’analyse ciblée editor. Les infos indiquées correspondent à du code existant dans le fichier ou à des préférences non bloquantes ; aucune erreur analyzer n’est sortie.

## 18. Build runner

Commande :

```bash
cd packages/map_core && dart run build_runner build --delete-conflicting-outputs
```

Sortie :

```text
Generating the build script.
Reading the asset graph.
Checking for updates.
Updating the asset graph.
Building, incremental build.
W SDK language version 3.12.0 is newer than `analyzer` language version 3.9.0. Run `dart pub upgrade`.
W json_serializable on lib/src/models/element_collision_profile.dart:
  The version constraint "^4.8.1" on json_annotation allows versions before 4.9.0 which is not allowed.
Running the post build.
Writing the asset graph.
Built with build_runner in 11s; wrote 15 outputs.
```

Fichiers generated modifiés dans le diff :

```text
packages/map_core/lib/src/models/map_event_definition.freezed.dart
packages/map_core/lib/src/models/map_event_definition.g.dart
```

## 19. Visual Gate

Le Visual Gate est couvert par le widget test :

```bash
cd packages/map_editor && flutter test --reporter=compact test/event_properties_panel_scene_target_test.dart
```

Ce test prouve :

- le picker Scene V1 est visible ;
- l’état vide est visible ;
- une Scene réelle peut être sélectionnée ;
- le lien est enregistré dans la page event en mémoire ;
- le lien peut être retiré ;
- message/script legacy restent conservés ;
- aucun `ProjectManifest.scenes` n’est créé automatiquement.

## 20. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
Sortie : <vide>
```

## 21. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 packages/map_core/lib/map_core.dart                |   1 +
 .../lib/src/models/map_event_definition.dart       |  21 ++
 .../src/models/map_event_definition.freezed.dart   | 211 ++++++++++++++++++++-
 .../lib/src/models/map_event_definition.g.dart     |  18 ++
 .../map_core/lib/src/operations/map_events.dart    |  65 +++++++
 .../map_core/lib/src/validation/validators.dart    |  21 ++
 packages/map_core/test/map_events_test.dart        | 201 +++++++++++++++++++-
 .../lib/src/ui/panels/event_properties_panel.dart  | 136 ++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  18 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  19 +-
 10 files changed, 699 insertions(+), 12 deletions(-)
```

Note : `git diff --stat` n’inclut pas les fichiers non suivis. Le `git status final` ci-dessous liste les fichiers créés.

## 22. git diff --name-only

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_core/lib/map_core.dart
packages/map_core/lib/src/models/map_event_definition.dart
packages/map_core/lib/src/models/map_event_definition.freezed.dart
packages/map_core/lib/src/models/map_event_definition.g.dart
packages/map_core/lib/src/operations/map_events.dart
packages/map_core/lib/src/validation/validators.dart
packages/map_core/test/map_events_test.dart
packages/map_editor/lib/src/ui/panels/event_properties_panel.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Note : `git diff --name-only` n’inclut pas les fichiers non suivis. Le `git status final` ci-dessous liste les fichiers créés.

## 23. git status final exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/models/map_event_definition.dart
 M packages/map_core/lib/src/models/map_event_definition.freezed.dart
 M packages/map_core/lib/src/models/map_event_definition.g.dart
 M packages/map_core/lib/src/operations/map_events.dart
 M packages/map_core/lib/src/validation/validators.dart
 M packages/map_core/test/map_events_test.dart
 M packages/map_editor/lib/src/ui/panels/event_properties_panel.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/lib/src/diagnostics/event_scene_link_diagnostics.dart
?? packages/map_core/test/event_scene_link_diagnostics_test.dart
?? packages/map_editor/test/event_properties_panel_scene_target_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_23_bis_event_to_scene_link_v0.md
```

## 24. Evidence Pack

### Fichiers lus

```text
AGENTS.md
agent_rules.md
skills/README.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_23_event_to_scene_trigger_prep.md
reports/narrativeStudio/scenes/ns_scenes_v1_22_payload_pickers_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_21_linked_asset_contracts_v0.md
packages/map_core/lib/src/models/map_event_definition.dart
packages/map_core/lib/src/models/map_event_definition.freezed.dart
packages/map_core/lib/src/models/map_event_definition.g.dart
packages/map_core/lib/src/models/map_data.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/lib/src/operations/map_events.dart
packages/map_core/lib/src/validation/validators.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/panels/event_properties_panel.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
```

### Contenu complet des fichiers créés

`packages/map_core/lib/src/diagnostics/event_scene_link_diagnostics.dart` :

```dart
import '../models/map_data.dart';
import '../models/project_manifest.dart';
import 'scene_diagnostics.dart';

enum EventSceneLinkDiagnosticSeverity {
  error,
  warning,
  info,
}

enum EventSceneLinkDiagnosticCode {
  eventSceneTargetUnknown,
  eventSceneTargetEmpty,
  eventSceneTargetDisabledPage,
  eventSceneTargetSceneHasErrors,
}

final class EventSceneLinkDiagnostic {
  const EventSceneLinkDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    required this.mapId,
    required this.eventId,
    required this.pageNumber,
    required this.pageIndex,
    this.sceneId,
    this.suggestedFixLabel,
  });

  final EventSceneLinkDiagnosticCode code;
  final EventSceneLinkDiagnosticSeverity severity;
  final String message;
  final String mapId;
  final String eventId;
  final int pageNumber;
  final int pageIndex;
  final String? sceneId;
  final String? suggestedFixLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventSceneLinkDiagnostic &&
          other.code == code &&
          other.severity == severity &&
          other.message == message &&
          other.mapId == mapId &&
          other.eventId == eventId &&
          other.pageNumber == pageNumber &&
          other.pageIndex == pageIndex &&
          other.sceneId == sceneId &&
          other.suggestedFixLabel == suggestedFixLabel;

  @override
  int get hashCode => Object.hash(
        code,
        severity,
        message,
        mapId,
        eventId,
        pageNumber,
        pageIndex,
        sceneId,
        suggestedFixLabel,
      );
}

final class EventSceneLinkDiagnosticsReport {
  EventSceneLinkDiagnosticsReport({
    required List<EventSceneLinkDiagnostic> diagnostics,
  }) : _diagnostics = List<EventSceneLinkDiagnostic>.unmodifiable(diagnostics);

  final List<EventSceneLinkDiagnostic> _diagnostics;

  List<EventSceneLinkDiagnostic> get diagnostics => _diagnostics;

  int get count => _diagnostics.length;

  int get errorCount => _diagnostics
      .where((diagnostic) =>
          diagnostic.severity == EventSceneLinkDiagnosticSeverity.error)
      .length;

  int get warningCount => _diagnostics
      .where((diagnostic) =>
          diagnostic.severity == EventSceneLinkDiagnosticSeverity.warning)
      .length;

  int get infoCount => _diagnostics
      .where((diagnostic) =>
          diagnostic.severity == EventSceneLinkDiagnosticSeverity.info)
      .length;

  bool get hasDiagnostics => _diagnostics.isNotEmpty;

  bool get hasErrors => errorCount > 0;

  List<EventSceneLinkDiagnostic> byCode(
    EventSceneLinkDiagnosticCode code,
  ) {
    return List<EventSceneLinkDiagnostic>.unmodifiable(
      _diagnostics.where((diagnostic) => diagnostic.code == code),
    );
  }
}

EventSceneLinkDiagnosticsReport diagnoseEventSceneLinks({
  required ProjectManifest project,
  required Iterable<MapData> maps,
}) {
  final sceneById = {
    for (final scene in project.scenes) scene.id: scene,
  };
  final diagnostics = <EventSceneLinkDiagnostic>[];

  for (final map in maps) {
    for (final event in map.events) {
      for (var pageIndex = 0; pageIndex < event.pages.length; pageIndex++) {
        final page = event.pages[pageIndex];
        final target = page.sceneTarget;
        if (target == null) {
          continue;
        }
        final sceneId = target.sceneId.trim();
        if (sceneId.isEmpty) {
          diagnostics.add(
            EventSceneLinkDiagnostic(
              code: EventSceneLinkDiagnosticCode.eventSceneTargetEmpty,
              severity: EventSceneLinkDiagnosticSeverity.error,
              message: 'La cible Scene V1 de la page d’event est vide.',
              mapId: map.id,
              eventId: event.id,
              pageNumber: page.pageNumber,
              pageIndex: pageIndex,
              suggestedFixLabel: 'Choisir une Scene V1 existante.',
            ),
          );
          continue;
        }

        final scene = sceneById[sceneId];
        if (scene == null) {
          diagnostics.add(
            EventSceneLinkDiagnostic(
              code: EventSceneLinkDiagnosticCode.eventSceneTargetUnknown,
              severity: EventSceneLinkDiagnosticSeverity.error,
              message:
                  'La page d’event cible une Scene V1 introuvable: $sceneId.',
              mapId: map.id,
              eventId: event.id,
              pageNumber: page.pageNumber,
              pageIndex: pageIndex,
              sceneId: sceneId,
              suggestedFixLabel: 'Choisir une Scene V1 existante.',
            ),
          );
          continue;
        }

        if (page.isDisabled) {
          diagnostics.add(
            EventSceneLinkDiagnostic(
              code: EventSceneLinkDiagnosticCode.eventSceneTargetDisabledPage,
              severity: EventSceneLinkDiagnosticSeverity.warning,
              message:
                  'La page d’event est désactivée mais cible une Scene V1.',
              mapId: map.id,
              eventId: event.id,
              pageNumber: page.pageNumber,
              pageIndex: pageIndex,
              sceneId: sceneId,
              suggestedFixLabel:
                  'Réactiver la page ou retirer la cible Scene V1.',
            ),
          );
        }

        if (diagnoseScene(scene).hasErrors) {
          diagnostics.add(
            EventSceneLinkDiagnostic(
              code: EventSceneLinkDiagnosticCode.eventSceneTargetSceneHasErrors,
              severity: EventSceneLinkDiagnosticSeverity.warning,
              message:
                  'La Scene V1 ciblée contient des erreurs de diagnostics.',
              mapId: map.id,
              eventId: event.id,
              pageNumber: page.pageNumber,
              pageIndex: pageIndex,
              sceneId: sceneId,
              suggestedFixLabel:
                  'Corriger la Scene avant tout branchement runtime.',
            ),
          );
        }
      }
    }
  }

  return EventSceneLinkDiagnosticsReport(diagnostics: diagnostics);
}
```

`packages/map_core/test/event_scene_link_diagnostics_test.dart` :

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('diagnoseEventSceneLinks', () {
    test('does not report pages without scene target', () {
      final report = diagnoseEventSceneLinks(
        project: _projectWithScenes([_validScene('scene_intro')]),
        maps: [
          _mapWithPage(const MapEventPage(pageNumber: 0)),
        ],
      );

      expect(report.diagnostics, isEmpty);
      expect(report.hasErrors, isFalse);
    });

    test('accepts a scene target referencing an existing scene', () {
      final report = diagnoseEventSceneLinks(
        project: _projectWithScenes([_validScene('scene_intro')]),
        maps: [
          _mapWithPage(
            const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_intro'),
            ),
          ),
        ],
      );

      expect(report.diagnostics, isEmpty);
    });

    test('reports missing and empty scene targets as errors', () {
      final report = diagnoseEventSceneLinks(
        project: _projectWithScenes([]),
        maps: [
          _mapWithPage(
            const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'missing_scene'),
            ),
          ),
          _mapWithPage(
            const MapEventPage(
              pageNumber: 1,
              sceneTarget: MapEventSceneTarget(sceneId: ''),
            ),
            eventId: 'event_empty',
          ),
        ],
      );

      expect(report.hasErrors, isTrue);
      expect(
        report.byCode(EventSceneLinkDiagnosticCode.eventSceneTargetUnknown),
        hasLength(1),
      );
      expect(
        report.byCode(EventSceneLinkDiagnosticCode.eventSceneTargetEmpty),
        hasLength(1),
      );
    });

    test('warns when a disabled page targets a scene', () {
      final report = diagnoseEventSceneLinks(
        project: _projectWithScenes([_validScene('scene_intro')]),
        maps: [
          _mapWithPage(
            const MapEventPage(
              pageNumber: 0,
              isDisabled: true,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_intro'),
            ),
          ),
        ],
      );

      final diagnostic = report
          .byCode(
            EventSceneLinkDiagnosticCode.eventSceneTargetDisabledPage,
          )
          .single;
      expect(diagnostic.severity, EventSceneLinkDiagnosticSeverity.warning);
      expect(report.hasErrors, isFalse);
    });

    test('warns when the target scene has scene diagnostics errors', () {
      final report = diagnoseEventSceneLinks(
        project: _projectWithScenes([_invalidScene('scene_broken')]),
        maps: [
          _mapWithPage(
            const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_broken'),
            ),
          ),
        ],
      );

      final diagnostic = report
          .byCode(
            EventSceneLinkDiagnosticCode.eventSceneTargetSceneHasErrors,
          )
          .single;
      expect(diagnostic.severity, EventSceneLinkDiagnosticSeverity.warning);
      expect(report.hasErrors, isFalse);
    });
  });
}

MapData _mapWithPage(MapEventPage page, {String eventId = 'event_gate'}) {
  return MapData(
    id: 'map_test',
    name: 'Test Map',
    size: const GridSize(width: 8, height: 8),
    layers: [
      MapLayer.tile(
        id: 'l_base',
        name: 'Base',
        tiles: List<int>.filled(64, 0),
      ),
    ],
    events: [
      MapEventDefinition(
        id: eventId,
        title: 'Gate',
        position: const EventPosition(layerId: 'l_base', x: 2, y: 2),
        pages: [page],
      ),
    ],
  );
}

ProjectManifest _projectWithScenes(List<SceneAsset> scenes) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    scenes: scenes,
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

SceneAsset _validScene(String id) {
  return SceneAsset(
    id: id,
    name: 'Intro Scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_end',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}

SceneAsset _invalidScene(String id) {
  return SceneAsset(
    id: id,
    name: 'Broken Scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
      ],
    ),
  );
}
```

`packages/map_editor/test/event_properties_panel_scene_target_test.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/panels/event_properties_panel.dart';

void main() {
  testWidgets('scene picker selects and clears a real Scene V1 target',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final map = _mapWithEvent(
      const MapEventPage(
        pageNumber: 0,
        message: 'Legacy message',
        script: ScriptRef(scriptId: 'script_intro'),
      ),
    );
    container.read(editorNotifierProvider.notifier).state = EditorState(
      project: _projectWithScene(),
      activeMap: map,
      activeLayerId: 'l_base',
      selectedMapEventId: 'event_gate',
    );

    await _pumpPanel(tester, container);

    expect(find.byKey(const ValueKey('event-scene-target-dropdown')),
        findsOneWidget);
    expect(find.text('Lien authoring uniquement, runtime Scene à venir.'),
        findsOneWidget);
    expect(find.textContaining('message ou un script legacy'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('event-scene-target-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Intro Scene (scene_intro)').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('event-save-page-button')),
    );
    await tester.tap(find.byKey(const ValueKey('event-save-page-button')));
    await tester.pumpAndSettle();

    var page = container
        .read(editorNotifierProvider)
        .activeMap!
        .events
        .single
        .pages
        .single;
    expect(page.sceneTarget, const MapEventSceneTarget(sceneId: 'scene_intro'));
    expect(page.message, 'Legacy message');
    expect(page.script, const ScriptRef(scriptId: 'script_intro'));

    await tester.tap(find.byKey(const ValueKey('event-clear-scene-target')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('event-save-page-button')),
    );
    await tester.tap(find.byKey(const ValueKey('event-save-page-button')));
    await tester.pumpAndSettle();

    page = container
        .read(editorNotifierProvider)
        .activeMap!
        .events
        .single
        .pages
        .single;
    expect(page.sceneTarget, isNull);
    expect(page.message, 'Legacy message');
    expect(page.script, const ScriptRef(scriptId: 'script_intro'));
    expect(
        container.read(editorNotifierProvider).project!.scenes, hasLength(1));
  });

  testWidgets('scene picker shows an honest empty state when no scenes exist',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = EditorState(
      project: _projectWithoutScenes(),
      activeMap: _mapWithEvent(const MapEventPage(pageNumber: 0)),
      activeLayerId: 'l_base',
      selectedMapEventId: 'event_gate',
    );

    await _pumpPanel(tester, container);

    expect(find.text('Aucune Scene V1 disponible'), findsOneWidget);
    expect(find.text('Aucune Scene V1'), findsOneWidget);
  });
}

Future<void> _pumpPanel(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.binding.setSurfaceSize(const Size(900, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData.light(useMaterial3: false),
        darkTheme: ThemeData.dark(useMaterial3: false),
        themeMode: ThemeMode.dark,
        home: const Scaffold(
          body: SizedBox(
            width: 520,
            height: 1450,
            child: EventPropertiesPanel(embedded: true),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

MapData _mapWithEvent(MapEventPage page) {
  return MapData(
    id: 'map_test',
    name: 'Test Map',
    size: const GridSize(width: 8, height: 8),
    layers: [
      MapLayer.tile(
        id: 'l_base',
        name: 'Base',
        tiles: List<int>.filled(64, 0),
      ),
    ],
    events: [
      MapEventDefinition(
        id: 'event_gate',
        title: 'Gate',
        position: const EventPosition(layerId: 'l_base', x: 2, y: 2),
        pages: [page],
      ),
    ],
  );
}

ProjectManifest _projectWithScene() {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    scripts: const [
      ProjectScriptEntry(
        id: 'script_intro',
        name: 'Intro Script',
        asset: ScriptAsset(
          id: 'script_intro',
          nodes: [ScriptNode(id: 'start')],
        ),
      ),
    ],
    scenes: [_validScene('scene_intro')],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

ProjectManifest _projectWithoutScenes() {
  return const ProjectManifest(
    name: 'Project',
    maps: [],
    tilesets: [],
    surfaceCatalog: ProjectSurfaceCatalog.empty(),
  );
}

SceneAsset _validScene(String id) {
  return SceneAsset(
    id: id,
    name: 'Intro Scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_end',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}
```

## 25. Auto-review critique

- Est-ce que j’ai modifié le runtime ? Non.
- Est-ce que j’ai modifié map_battle ? Non.
- Est-ce que j’ai modifié map_gameplay ? Non.
- Est-ce que j’ai branché `StorylineStep.sceneLinkIds` ? Non.
- Est-ce que j’ai ajouté `MapEventDefinition.sceneId` direct ? Non.
- Est-ce que j’ai utilisé metadata comme source de vérité Scene ? Non.
- Est-ce que j’ai fait de `ScenarioAsset` le modèle final de Scene ? Non.
- Est-ce que j’ai créé une fixture Selbrume ? Non.
- Est-ce que j’ai inventé une scene/event/ref produit ? Non.
- Est-ce que j’ai lancé l’exécution runtime d’une Scene ? Non.
- Est-ce que le lien vit bien au niveau MapEventPage ou action de page ? Oui, `MapEventPage.sceneTarget`.
- Est-ce que le picker utilise des SceneAsset réelles ? Oui, `ProjectManifest.scenes`.
- Est-ce que les diagnostics refs inconnues existent ? Oui.
- Est-ce que le prochain lot reste bien V1-24 et n’a pas été démarré ? Oui.

## 26. Limites et prochain lot recommandé

Limites :

- le picker enregistre lors du bouton `Enregistrer page`, comme les autres champs du panel ;
- pas de runtime ;
- pas de plan runtime ;
- pas de diagnostic global UI dédié à Event -> Scene hors tests/pure API ;
- les generated files sont modifiés uniquement par build_runner côté `map_core`.

Prochain lot recommandé :

```text
NS-SCENES-V1-24 — Scene Runtime Plan V0
```
