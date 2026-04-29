# Lot 109 — Editor Generate Lava Hazard Zone from Surface V0

## 1. Résumé exécutif honnête

Lot 109 ajoute l'action éditeur `Lave dangereuse` dans le menu comportement Surface existant. Elle génère des `MapGameplayZone(kind: hazard)` avec `HazardZonePayload(hazardKind: HazardKind.lava, damagePerStep > 0)` depuis une surface peinte, via la chaîne déjà validée : plan pur, assessment, dialog de confirmation, puis batch apply `EditorNotifier.applyGeneratedGameplayZones(...)`.

Le champ `Dégâts par pas` est prérempli à `5`, modifiable, et strictement validé comme entier positif. Le lot ne touche pas au runtime Flutter, ne mute pas HP / party / `GameState`, et n'ouvre ni ice ni mud.

## 2. Périmètre

Inclus :

- troisième choix `Lave dangereuse` dans `SurfaceBehaviorActionMenu` ;
- presenter lava spécifique `buildLavaHazardSurfaceGameplayZonePreview(...)` ;
- dialog `LavaHazardSurfaceGameplayZoneDialog` ;
- helper `applyLavaHazardGameplayZonePlan(...)` ;
- tests presenter, dialog, routing menu, batch apply, rejets de plans invalides ;
- rapport Lot 109.

Exclus :

- modèles `map_core` ;
- production `map_gameplay` ;
- production `map_runtime` / `PlayableMapGame` ;
- application réelle des dégâts ;
- ice / mud / poison / swamp / pitfall editor.

## 3. Gate 0 — status initial

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
 M packages/map_gameplay/lib/map_gameplay.dart
 M packages/map_gameplay/lib/src/gameplay_step.dart
 M packages/map_gameplay/lib/src/gameplay_step_result.dart
?? packages/map_gameplay/lib/src/gameplay_hazard.dart
?? packages/map_gameplay/test/hazard_runtime_consumption_test.dart
?? reports/surface/surface_engine_lot_108_hazard_runtime_consumption_prep.md

git diff --stat
 packages/map_gameplay/lib/map_gameplay.dart        |  1 +
 packages/map_gameplay/lib/src/gameplay_step.dart   | 42 ++++++++++++++++++++--
 .../map_gameplay/lib/src/gameplay_step_result.dart |  4 +++
 3 files changed, 44 insertions(+), 3 deletions(-)

git log --oneline -n 10
e8bfc68e lot 107: Lava Hazard from Surface Workflow Decision
4851b53f lot 106: Surface Behavior Action Menu
2305f276 lot 104: Surface Gameplay Bridge Runtime E2E Closure
8b5c3728 lot 103: Editor Generate Surfable Water Gameplay Zone from Surface
6a3db8e3 lot 101: Tall Grass Surface Workflow Hardening - Batch Apply
b224b0f6 fix: resolve RenderFlex overflow errors in layers and surface panels
888f1339 fix: resolve RenderFlex overflow errors in layers and surface panels
58ab7070 lot 100/95: Editor Generate Gameplay Zone from Surface
15fa925c lot 99/95: Surface Gameplay - Surface to Gameplay Zone Coverage Diagnostics
70b0f90d lot 98/95: Surface Gameplay - Surface to Gameplay Zone Generation Plan

find . -name AGENTS.md -print
./AGENTS.md
```

Changements préexistants au Gate 0 : fichiers Lot 108 dans `map_gameplay` et rapport Lot 108. Pendant le lot, l'historique local a ensuite affiché `3ef5fc92 lot 108: Hazard Runtime Consumption Prep`; je n'ai exécuté aucune commande git d'écriture.

Changements du Lot 109 : uniquement les cinq fichiers `map_editor` listés en section 18 et le présent rapport.

## 4. Context Mode usage

Context Mode a été utilisé agressivement pour :

- Gate 0 ;
- audit Lots 107 / 108 ;
- audit menu comportement Surface ;
- audit presenters/dialogs/actions existants ;
- audit map_core hazard generation ;
- audit tests gameplay hazard ;
- test rouge TDD ;
- tests/régressions/analyse ;
- diff/scope review.

Commandes d'audit lancées :

```text
rg -n "Lot 107|Lot 108|HazardZonePayload|HazardKind.lava|damagePerStep|GameplayHazardEffect|Moved.hazardEffect|hazard runtime|Lave dangereuse" reports/surface packages/map_core/lib packages/map_gameplay/lib packages/map_gameplay/test
rg -n "SurfaceBehaviorActionMenu|Créer un comportement depuis cette surface|Herbe haute avec rencontres|Eau surfable|CupertinoActionSheet|SurfaceToGameplayZoneDialog|SurfableWaterSurfaceGameplayZoneDialog" packages/map_editor/lib packages/map_editor/test
rg -n "buildTallGrassEncounterSurfaceGameplayZonePreview|buildSurfableWaterSurfaceGameplayZonePreview|SurfaceToGameplayZoneDialog|SurfableWaterSurfaceGameplayZoneDialog|applyTallGrassEncounterGameplayZonePlan|applySurfableWaterGameplayZonePlan|SurfaceGameplayZoneBehaviorDraft" packages/map_editor/lib packages/map_editor/test
rg -n "SurfaceGameplayZoneBehaviorDraft.hazard|HazardZonePayload|HazardKind.lava|damagePerStep|GameplayZoneKind.hazard|createSurfaceGameplayZoneGenerationPlan|greedyRectangles" packages/map_core/lib packages/map_core/test
rg -n "hazard_runtime_consumption|GameplayHazardEffect|Moved.hazardEffect|generated lava zones|HazardKind.lava|damagePerStep" packages/map_gameplay/test packages/map_gameplay/lib
```

## 5. Audit Lots 107 / 108

Findings importants :

- Lot 107 a décidé le payload lava V0 : `HazardZonePayload(hazardKind: HazardKind.lava, damagePerStep: 5)`.
- Lot 107 a posé la règle : `damagePerStep` positif, zone sur les cellules lava elles-mêmes.
- Lot 108 a ajouté `GameplayHazardEffect` et `Moved.hazardEffect` côté `map_gameplay`.
- Lot 108 prouve que les generated lava zones issues du plan Surface sont consommées côté gameplay.
- Lot 109 peut donc coder l'authoring editor lava.
- Lot 109 ne doit surtout pas appliquer les dégâts ni toucher au runtime Flutter.

## 6. Audit Surface Behavior Action Menu

`SurfaceBehaviorActionMenu` avait déjà :

- bouton unique `Créer un comportement depuis cette surface` ;
- `CupertinoActionSheet` ;
- choix `Herbe haute avec rencontres` ;
- choix `Eau surfable` ;
- routing vers les dialogs existants ;
- batch apply via helpers métier.

Décision : ajouter `Lave dangereuse` comme troisième choix dans ce même menu. On ne revient pas à des boutons séparés dans la palette principale.

## 7. Audit presenters/dialogs/actions existants

Les presenters tall grass et water construisent déjà :

- source `SurfaceGameplayZoneGenerationSource` depuis `SurfaceLayer` + `surfacePresetId` ;
- plan `createSurfaceGameplayZoneGenerationPlan(...)` ;
- strategy `greedyRectangles` ;
- assessment `assessSurfaceGameplayZoneGenerationPlan(...)` ;
- état `canConfirm`, messages, summary, coverage.

Les dialogs sont textuels, courts, et désactivent l'action quand le plan est `blocked`. Les helpers d'application valident toute la liste avant batch apply, évitant les mutations partielles.

Décision : garder un presenter lava spécifique et un dialog lava spécifique, sans généraliser prématurément.

## 8. Décision UX lava V0

UX retenue :

- menu : `Lave dangereuse` ;
- dialog : `Créer une zone de lave dangereuse` ;
- type affiché : `Lave dangereuse` ;
- champ numérique : `Dégâts par pas` ;
- valeur par défaut : `5` ;
- bouton : `Créer la zone de lave` ;
- confirmation active seulement si plan ready/needsReview et `damagePerStep > 0`.

Aucun champ script, badge, ability, encounter table ou movement mode.

## 9. Presenter lava

`buildLavaHazardSurfaceGameplayZonePreview(...)` prend :

- `map` ;
- `surfaceLayer` ;
- `surfacePresetId` ;
- `presets` ;
- `damagePerStep` ;
- policy optionnelle.

Il bloque :

- map null ;
- calque Surface null ;
- preset vide ;
- preset absent du catalogue ;
- aucune cellule peinte ;
- `damagePerStep == null` ou `<= 0`.

Il génère :

```text
SurfaceGameplayZoneBehaviorDraft.hazard(
  HazardZonePayload(hazardKind: HazardKind.lava, damagePerStep: damagePerStep),
)
```

avec `greedyRectangles`, `zoneIdPrefix = '<surfacePresetId>-lava'`, `zoneNamePrefix = '<Nom surface> - Lave'`, `existingZones = map.gameplayZones`.

## 10. Dialog lava

`LavaHazardSurfaceGameplayZoneDialog` est un `CupertinoAlertDialog` textuel. Il affiche surface, cellules, type, zones, champ `Dégâts par pas`, summary assessment, messages, couverture et hors surface.

Le champ est prérempli à `5`. La saisie `0` rend le plan bloqué et désactive le bouton. La saisie `8` régénère un plan avec `damagePerStep == 8`.

## 11. Helper applyLavaHazardGameplayZonePlan

Le helper refuse :

- plan vide ;
- zone non hazard ;
- payload hazard null ;
- `hazardKind != HazardKind.lava` ;
- `damagePerStep <= 0`.

Il appelle ensuite `EditorNotifier.applyGeneratedGameplayZones(...)` avec `selectZoneId = zones.first.id` et message `Zones de lave créées depuis la surface`. Aucun plan invalide ne peut muter partiellement la map.

## 12. Menu behavior routing

Le menu propose maintenant :

- `Herbe haute avec rencontres` ;
- `Eau surfable` ;
- `Lave dangereuse`.

Le choix lava ouvre `LavaHazardSurfaceGameplayZoneDialog`, puis applique le plan confirmé via `applyLavaHazardGameplayZonePlan(...)`.

## 13. Tests lancés

Test rouge TDD :

```text
cd packages/map_editor && flutter test test/surface_painter/surface_to_gameplay_zone_action_test.dart --no-pub --reporter expanded

00:00 +0 -1: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart [E]
Compilation failed for testPath=/Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart:
test/surface_painter/surface_to_gameplay_zone_action_test.dart:151:23: Error: Method not found: 'buildLavaHazardSurfaceGameplayZonePreview'.
test/surface_painter/surface_to_gameplay_zone_action_test.dart:396:20: Error: Method not found: 'LavaHazardSurfaceGameplayZoneDialog'.
test/surface_painter/surface_to_gameplay_zone_action_test.dart:915:23: Error: Method not found: 'applyLavaHazardGameplayZonePlan'.
00:00 +0 -1: Some tests failed.
```

Debug intermédiaire :

```text
Root cause debug after first implementation run:
Expected: exactly one matching candidate
Actual: _AncestorWidgetFinder:<Found 2 widgets with type "CupertinoTextField" that are ancestors of widgets with text "5">
Location: test/surface_painter/surface_to_gameplay_zone_action_test.dart line 411
Fix: assert the keyed CupertinoTextField and its controller text instead of using widgetWithText on internal editable text/placeholder descendants.
```

Tests finaux :

```text
cd packages/map_editor && flutter test test/surface_painter/surface_to_gameplay_zone_action_test.dart --no-pub --reporter expanded
00:01 +29: All tests passed!

cd packages/map_editor && flutter test test/surface_painter --no-pub --reporter expanded
00:02 +71: All tests passed!

cd packages/map_gameplay && dart test test/hazard_runtime_consumption_test.dart --reporter expanded
00:00 +7: All tests passed!

cd packages/map_gameplay && dart test test/surface_generated_gameplay_zone_bridge_test.dart --reporter expanded
00:00 +3: All tests passed!

cd packages/map_gameplay && dart test test/movement_mode_water_test.dart --reporter expanded
00:00 +6: All tests passed!

cd packages/map_gameplay && dart test test/surf_evaluation_test.dart --reporter expanded
00:00 +12: All tests passed!

cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_plan_test.dart --reporter expanded
00:00 +16: All tests passed!

cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_assessment_test.dart --reporter expanded
00:00 +12: All tests passed!
```

Format :

```text
dart format packages/map_editor/lib/src/features/surface_painter/surface_behavior_action_menu.dart packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_action.dart packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_dialog.dart packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_presenter.dart packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart
Formatted packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_presenter.dart
Formatted packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart
Formatted 5 files (2 changed) in 0.02 seconds.
```

## 14. Résultats

Tous les tests lancés passent :

- `surface_to_gameplay_zone_action_test.dart` : 29 tests ;
- `test/surface_painter` : 71 tests ;
- `hazard_runtime_consumption_test.dart` : 7 tests ;
- `surface_generated_gameplay_zone_bridge_test.dart` : 3 tests ;
- `movement_mode_water_test.dart` : 6 tests ;
- `surf_evaluation_test.dart` : 12 tests ;
- `surface_to_gameplay_zone_generation_plan_test.dart` : 16 tests ;
- `surface_to_gameplay_zone_generation_assessment_test.dart` : 12 tests.

## 15. Analyse lancée

```text
cd packages/map_editor && flutter analyze lib/src/features/surface_painter/surface_behavior_action_menu.dart lib/src/features/surface_painter/surface_to_gameplay_zone_action.dart lib/src/features/surface_painter/surface_to_gameplay_zone_dialog.dart lib/src/features/surface_painter/surface_to_gameplay_zone_presenter.dart test/surface_painter/surface_to_gameplay_zone_action_test.dart
Analyzing 5 items...
No issues found! (ran in 1.6s)
```

## 16. Résultats analyze

Analyse ciblée clean : `No issues found!`.

## 17. Fichiers créés

- `reports/surface/surface_engine_lot_109_editor_generate_lava_hazard_zone_from_surface.md`

## 18. Fichiers modifiés

- `packages/map_editor/lib/src/features/surface_painter/surface_behavior_action_menu.dart`
- `packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_action.dart`
- `packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_dialog.dart`
- `packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_presenter.dart`
- `packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart`

## 19. Fichiers supprimés

Aucun fichier supprimé.

## 20. Contenu complet des fichiers créés

Le rapport `reports/surface/surface_engine_lot_109_editor_generate_lava_hazard_zone_from_surface.md` est le présent fichier ; son contenu n'est pas recopié récursivement conformément à l'exception demandée.

## 21. Contenu complet des fichiers modifiés

### `packages/map_editor/lib/src/features/surface_painter/surface_behavior_action_menu.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../editor/state/editor_notifier.dart';
import 'surface_to_gameplay_zone_action.dart';
import 'surface_to_gameplay_zone_dialog.dart';

enum _SurfaceBehaviorChoice {
  tallGrassEncounter,
  surfableWater,
  lavaHazard,
}

class SurfaceBehaviorActionMenu extends StatelessWidget {
  const SurfaceBehaviorActionMenu({
    super.key,
    required this.map,
    required this.surfaceLayer,
    required this.surfacePresetId,
    required this.presets,
    required this.encounterTables,
    required this.notifier,
  });

  final MapData? map;
  final SurfaceLayer? surfaceLayer;
  final String? surfacePresetId;
  final List<ProjectSurfacePreset> presets;
  final List<ProjectEncounterTable> encounterTables;
  final EditorNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      onPressed: map == null ? null : () => _openBehaviorMenu(context),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.wand_stars, size: 16),
          SizedBox(width: 4),
          Flexible(
            child: Text('Créer un comportement depuis cette surface'),
          ),
        ],
      ),
    );
  }

  Future<void> _openBehaviorMenu(BuildContext context) async {
    final choice = await showCupertinoModalPopup<_SurfaceBehaviorChoice>(
      context: context,
      builder: (sheetContext) {
        return CupertinoActionSheet(
          title: const Text('Créer un comportement depuis cette surface'),
          message: const Text('Choisissez le comportement gameplay à créer.'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(sheetContext).pop(
                _SurfaceBehaviorChoice.tallGrassEncounter,
              ),
              child: const Text('Herbe haute avec rencontres'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(sheetContext).pop(
                _SurfaceBehaviorChoice.surfableWater,
              ),
              child: const Text('Eau surfable'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(sheetContext).pop(
                _SurfaceBehaviorChoice.lavaHazard,
              ),
              child: const Text('Lave dangereuse'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Annuler'),
          ),
        );
      },
    );

    if (!context.mounted || choice == null) {
      return;
    }

    switch (choice) {
      case _SurfaceBehaviorChoice.tallGrassEncounter:
        await _openTallGrassDialog(context);
      case _SurfaceBehaviorChoice.surfableWater:
        await _openSurfableWaterDialog(context);
      case _SurfaceBehaviorChoice.lavaHazard:
        await _openLavaHazardDialog(context);
    }
  }

  Future<void> _openTallGrassDialog(BuildContext context) async {
    final currentMap = map;
    if (currentMap == null) {
      return;
    }
    final plan = await showCupertinoDialog<SurfaceGameplayZoneGenerationPlan>(
      context: context,
      builder: (dialogContext) {
        return SurfaceToGameplayZoneDialog(
          map: currentMap,
          surfaceLayer: surfaceLayer,
          surfacePresetId: surfacePresetId,
          presets: presets,
          encounterTables: encounterTables,
          onConfirm: (plan) => Navigator.of(dialogContext).pop(plan),
        );
      },
    );
    if (plan == null) {
      return;
    }
    applyTallGrassEncounterGameplayZonePlan(
      notifier: notifier,
      plan: plan,
    );
  }

  Future<void> _openSurfableWaterDialog(BuildContext context) async {
    final currentMap = map;
    if (currentMap == null) {
      return;
    }
    final plan = await showCupertinoDialog<SurfaceGameplayZoneGenerationPlan>(
      context: context,
      builder: (dialogContext) {
        return SurfableWaterSurfaceGameplayZoneDialog(
          map: currentMap,
          surfaceLayer: surfaceLayer,
          surfacePresetId: surfacePresetId,
          presets: presets,
          onConfirm: (plan) => Navigator.of(dialogContext).pop(plan),
        );
      },
    );
    if (plan == null) {
      return;
    }
    applySurfableWaterGameplayZonePlan(
      notifier: notifier,
      plan: plan,
    );
  }

  Future<void> _openLavaHazardDialog(BuildContext context) async {
    final currentMap = map;
    if (currentMap == null) {
      return;
    }
    final plan = await showCupertinoDialog<SurfaceGameplayZoneGenerationPlan>(
      context: context,
      builder: (dialogContext) {
        return LavaHazardSurfaceGameplayZoneDialog(
          map: currentMap,
          surfaceLayer: surfaceLayer,
          surfacePresetId: surfacePresetId,
          presets: presets,
          onConfirm: (plan) => Navigator.of(dialogContext).pop(plan),
        );
      },
    );
    if (plan == null) {
      return;
    }
    applyLavaHazardGameplayZonePlan(
      notifier: notifier,
      plan: plan,
    );
  }
}

```
### `packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_action.dart`

```dart
import 'package:map_core/map_core.dart';

import '../editor/state/editor_notifier.dart';

bool applyTallGrassEncounterGameplayZonePlan({
  required EditorNotifier notifier,
  required SurfaceGameplayZoneGenerationPlan plan,
}) {
  final zones = plan.generatedZones;
  if (zones.isEmpty) {
    return false;
  }
  if (zones.any((zone) => !_isTallGrassEncounterZone(zone))) {
    return false;
  }

  return notifier.applyGeneratedGameplayZones(
    zones: zones,
    selectZoneId: zones.first.id,
    statusMessage: 'Zones de rencontre créées depuis la surface',
  );
}

bool applySurfableWaterGameplayZonePlan({
  required EditorNotifier notifier,
  required SurfaceGameplayZoneGenerationPlan plan,
}) {
  final zones = plan.generatedZones;
  if (zones.isEmpty) {
    return false;
  }
  if (zones.any((zone) => !_isSurfableWaterMovementZone(zone))) {
    return false;
  }

  return notifier.applyGeneratedGameplayZones(
    zones: zones,
    selectZoneId: zones.first.id,
    statusMessage: 'Zones Surf créées depuis la surface',
  );
}

bool applyLavaHazardGameplayZonePlan({
  required EditorNotifier notifier,
  required SurfaceGameplayZoneGenerationPlan plan,
}) {
  // Authoring only: this stores lava damage metadata on gameplay zones.
  // HP / party mutation is intentionally left to gameplay/runtime consumers.
  final zones = plan.generatedZones;
  if (zones.isEmpty) {
    return false;
  }
  if (zones.any((zone) => !_isLavaHazardZone(zone))) {
    return false;
  }

  return notifier.applyGeneratedGameplayZones(
    zones: zones,
    selectZoneId: zones.first.id,
    statusMessage: 'Zones de lave créées depuis la surface',
  );
}

bool _isTallGrassEncounterZone(MapGameplayZone zone) {
  return zone.kind == GameplayZoneKind.encounter &&
      zone.encounter != null &&
      zone.encounter?.encounterKind == EncounterKind.walk;
}

bool _isSurfableWaterMovementZone(MapGameplayZone zone) {
  return zone.kind == GameplayZoneKind.movement &&
      zone.movement != null &&
      zone.movement?.requiredMode == MovementMode.surf;
}

bool _isLavaHazardZone(MapGameplayZone zone) {
  return zone.kind == GameplayZoneKind.hazard &&
      zone.hazard != null &&
      zone.hazard?.hazardKind == HazardKind.lava &&
      (zone.hazard?.damagePerStep ?? 0) > 0;
}

```
### `packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_dialog.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import 'surface_to_gameplay_zone_presenter.dart';

class SurfaceToGameplayZoneDialog extends StatefulWidget {
  const SurfaceToGameplayZoneDialog({
    super.key,
    required this.map,
    required this.surfaceLayer,
    required this.surfacePresetId,
    required this.presets,
    required this.encounterTables,
    required this.onConfirm,
    this.onCancel,
  });

  final MapData? map;
  final SurfaceLayer? surfaceLayer;
  final String? surfacePresetId;
  final List<ProjectSurfacePreset> presets;
  final List<ProjectEncounterTable> encounterTables;
  final ValueChanged<SurfaceGameplayZoneGenerationPlan> onConfirm;
  final VoidCallback? onCancel;

  @override
  State<SurfaceToGameplayZoneDialog> createState() =>
      _SurfaceToGameplayZoneDialogState();
}

class _SurfaceToGameplayZoneDialogState
    extends State<SurfaceToGameplayZoneDialog> {
  late final TextEditingController _encounterTableController;

  @override
  void initState() {
    super.initState();
    _encounterTableController = TextEditingController(
      text:
          widget.encounterTables.isEmpty ? '' : widget.encounterTables.first.id,
    );
  }

  @override
  void dispose() {
    _encounterTableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = buildTallGrassEncounterSurfaceGameplayZonePreview(
      map: widget.map,
      surfaceLayer: widget.surfaceLayer,
      surfacePresetId: widget.surfacePresetId,
      presets: widget.presets,
      encounterTableId: _encounterTableController.text,
    );

    return CupertinoAlertDialog(
      title: const Text('Créer une zone de rencontre depuis cette surface'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          _InfoLine(label: 'Surface', value: preview.surfaceLabel),
          _InfoLine(label: 'Cellules', value: '${preview.sourceCellCount}'),
          _InfoLine(
            label: 'Zones',
            value: '${preview.generatedZoneCount}',
          ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Table de rencontres'),
          ),
          const SizedBox(height: 6),
          CupertinoTextField(
            key: const Key('surface-to-gameplay-zone-encounter-table-field'),
            controller: _encounterTableController,
            placeholder: 'route_1_grass',
            onChanged: (_) => setState(() {}),
          ),
          if (widget.encounterTables.isNotEmpty) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Disponible : ${widget.encounterTables.map((table) => table.id).join(', ')}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              preview.summaryTitle,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(preview.summaryDescription),
          ),
          const SizedBox(height: 8),
          for (final message in preview.messages) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text('• ${message.title}'),
            ),
            const SizedBox(height: 3),
          ],
          if (preview.assessment != null) ...[
            const SizedBox(height: 8),
            _InfoLine(
              label: 'Couverture',
              value:
                  '${(preview.assessment!.coveragePercent * 100).toStringAsFixed(1)}%',
            ),
            _InfoLine(
              label: 'Hors surface',
              value:
                  '${(preview.assessment!.extraCellRatio * 100).toStringAsFixed(1)}%',
            ),
          ],
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed:
              preview.canConfirm ? () => widget.onConfirm(preview.plan!) : null,
          child: const Text('Créer les zones'),
        ),
      ],
    );
  }
}

class SurfableWaterSurfaceGameplayZoneDialog extends StatelessWidget {
  const SurfableWaterSurfaceGameplayZoneDialog({
    super.key,
    required this.map,
    required this.surfaceLayer,
    required this.surfacePresetId,
    required this.presets,
    required this.onConfirm,
    this.onCancel,
  });

  final MapData? map;
  final SurfaceLayer? surfaceLayer;
  final String? surfacePresetId;
  final List<ProjectSurfacePreset> presets;
  final ValueChanged<SurfaceGameplayZoneGenerationPlan> onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final preview = buildSurfableWaterSurfaceGameplayZonePreview(
      map: map,
      surfaceLayer: surfaceLayer,
      surfacePresetId: surfacePresetId,
      presets: presets,
    );

    return CupertinoAlertDialog(
      title: const Text('Rendre cette eau surfable'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          _InfoLine(label: 'Surface', value: preview.surfaceLabel),
          _InfoLine(label: 'Cellules', value: '${preview.sourceCellCount}'),
          const _InfoLine(label: 'Mode', value: 'Surf'),
          _InfoLine(label: 'Zones', value: '${preview.generatedZoneCount}'),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              preview.summaryTitle,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(preview.summaryDescription),
          ),
          const SizedBox(height: 8),
          for (final message in preview.messages) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text('• ${message.title}'),
            ),
            const SizedBox(height: 3),
          ],
          if (preview.assessment != null) ...[
            const SizedBox(height: 8),
            _InfoLine(
              label: 'Couverture',
              value:
                  '${(preview.assessment!.coveragePercent * 100).toStringAsFixed(1)}%',
            ),
            _InfoLine(
              label: 'Hors surface',
              value:
                  '${(preview.assessment!.extraCellRatio * 100).toStringAsFixed(1)}%',
            ),
          ],
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: onCancel ?? () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: preview.canConfirm ? () => onConfirm(preview.plan!) : null,
          child: const Text('Créer la zone Surf'),
        ),
      ],
    );
  }
}

class LavaHazardSurfaceGameplayZoneDialog extends StatefulWidget {
  const LavaHazardSurfaceGameplayZoneDialog({
    super.key,
    required this.map,
    required this.surfaceLayer,
    required this.surfacePresetId,
    required this.presets,
    required this.onConfirm,
    this.onCancel,
  });

  final MapData? map;
  final SurfaceLayer? surfaceLayer;
  final String? surfacePresetId;
  final List<ProjectSurfacePreset> presets;
  final ValueChanged<SurfaceGameplayZoneGenerationPlan> onConfirm;
  final VoidCallback? onCancel;

  @override
  State<LavaHazardSurfaceGameplayZoneDialog> createState() =>
      _LavaHazardSurfaceGameplayZoneDialogState();
}

class _LavaHazardSurfaceGameplayZoneDialogState
    extends State<LavaHazardSurfaceGameplayZoneDialog> {
  late final TextEditingController _damageController;

  @override
  void initState() {
    super.initState();
    _damageController = TextEditingController(text: '5');
  }

  @override
  void dispose() {
    _damageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = buildLavaHazardSurfaceGameplayZonePreview(
      map: widget.map,
      surfaceLayer: widget.surfaceLayer,
      surfacePresetId: widget.surfacePresetId,
      presets: widget.presets,
      damagePerStep: int.tryParse(_damageController.text.trim()),
    );

    return CupertinoAlertDialog(
      title: const Text('Créer une zone de lave dangereuse'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          _InfoLine(label: 'Surface', value: preview.surfaceLabel),
          _InfoLine(label: 'Cellules', value: '${preview.sourceCellCount}'),
          const _InfoLine(label: 'Type', value: 'Lave dangereuse'),
          _InfoLine(label: 'Zones', value: '${preview.generatedZoneCount}'),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Dégâts par pas'),
          ),
          const SizedBox(height: 6),
          CupertinoTextField(
            key: const Key('surface-to-gameplay-zone-lava-damage-field'),
            controller: _damageController,
            keyboardType: TextInputType.number,
            placeholder: '5',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              preview.summaryTitle,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(preview.summaryDescription),
          ),
          const SizedBox(height: 8),
          for (final message in preview.messages) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text('• ${message.title}'),
            ),
            const SizedBox(height: 3),
          ],
          if (preview.assessment != null) ...[
            const SizedBox(height: 8),
            _InfoLine(
              label: 'Couverture',
              value:
                  '${(preview.assessment!.coveragePercent * 100).toStringAsFixed(1)}%',
            ),
            _InfoLine(
              label: 'Hors surface',
              value:
                  '${(preview.assessment!.extraCellRatio * 100).toStringAsFixed(1)}%',
            ),
          ],
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed:
              preview.canConfirm ? () => widget.onConfirm(preview.plan!) : null,
          child: const Text('Créer la zone de lave'),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label : ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

```
### `packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_presenter.dart`

```dart
import 'package:map_core/map_core.dart';

final class TallGrassEncounterSurfaceGameplayZonePreview {
  TallGrassEncounterSurfaceGameplayZonePreview({
    required this.surfaceLabel,
    required this.sourceCellCount,
    required this.status,
    required Iterable<SurfaceGameplayZoneGenerationAssessmentMessage> messages,
    this.plan,
    this.assessment,
  }) : messages =
            List<SurfaceGameplayZoneGenerationAssessmentMessage>.unmodifiable(
          messages,
        );

  final String surfaceLabel;
  final int sourceCellCount;
  final SurfaceGameplayZoneGenerationAssessmentStatus status;
  final List<SurfaceGameplayZoneGenerationAssessmentMessage> messages;
  final SurfaceGameplayZoneGenerationPlan? plan;
  final SurfaceGameplayZoneGenerationAssessment? assessment;

  bool get canConfirm =>
      plan != null &&
      assessment != null &&
      status != SurfaceGameplayZoneGenerationAssessmentStatus.blocked;

  int get generatedZoneCount => plan?.generatedZones.length ?? 0;

  String get summaryTitle {
    return assessment?.summaryTitle ??
        (messages.isEmpty ? 'Plan bloqué' : messages.first.title);
  }

  String get summaryDescription {
    return assessment?.summaryDescription ??
        (messages.isEmpty ? null : messages.first.description) ??
        'Corrigez la surface avant de continuer.';
  }
}

final class SurfableWaterSurfaceGameplayZonePreview {
  SurfableWaterSurfaceGameplayZonePreview({
    required this.surfaceLabel,
    required this.sourceCellCount,
    required this.status,
    required Iterable<SurfaceGameplayZoneGenerationAssessmentMessage> messages,
    this.plan,
    this.assessment,
  }) : messages =
            List<SurfaceGameplayZoneGenerationAssessmentMessage>.unmodifiable(
          messages,
        );

  final String surfaceLabel;
  final int sourceCellCount;
  final SurfaceGameplayZoneGenerationAssessmentStatus status;
  final List<SurfaceGameplayZoneGenerationAssessmentMessage> messages;
  final SurfaceGameplayZoneGenerationPlan? plan;
  final SurfaceGameplayZoneGenerationAssessment? assessment;

  bool get canConfirm =>
      plan != null &&
      assessment != null &&
      status != SurfaceGameplayZoneGenerationAssessmentStatus.blocked;

  int get generatedZoneCount => plan?.generatedZones.length ?? 0;

  String get summaryTitle {
    return assessment?.summaryTitle ??
        (messages.isEmpty ? 'Plan bloqué' : messages.first.title);
  }

  String get summaryDescription {
    return assessment?.summaryDescription ??
        (messages.isEmpty ? null : messages.first.description) ??
        'Corrigez la surface avant de continuer.';
  }
}

final class LavaHazardSurfaceGameplayZonePreview {
  LavaHazardSurfaceGameplayZonePreview({
    required this.surfaceLabel,
    required this.sourceCellCount,
    required this.damagePerStep,
    required this.status,
    required Iterable<SurfaceGameplayZoneGenerationAssessmentMessage> messages,
    this.plan,
    this.assessment,
  }) : messages =
            List<SurfaceGameplayZoneGenerationAssessmentMessage>.unmodifiable(
          messages,
        );

  final String surfaceLabel;
  final int sourceCellCount;
  final int? damagePerStep;
  final SurfaceGameplayZoneGenerationAssessmentStatus status;
  final List<SurfaceGameplayZoneGenerationAssessmentMessage> messages;
  final SurfaceGameplayZoneGenerationPlan? plan;
  final SurfaceGameplayZoneGenerationAssessment? assessment;

  bool get canConfirm =>
      plan != null &&
      assessment != null &&
      status != SurfaceGameplayZoneGenerationAssessmentStatus.blocked;

  int get generatedZoneCount => plan?.generatedZones.length ?? 0;

  String get summaryTitle {
    return assessment?.summaryTitle ??
        (messages.isEmpty ? 'Plan bloqué' : messages.first.title);
  }

  String get summaryDescription {
    return assessment?.summaryDescription ??
        (messages.isEmpty ? null : messages.first.description) ??
        'Corrigez la surface avant de continuer.';
  }
}

TallGrassEncounterSurfaceGameplayZonePreview
    buildTallGrassEncounterSurfaceGameplayZonePreview({
  required MapData? map,
  required SurfaceLayer? surfaceLayer,
  required String? surfacePresetId,
  required List<ProjectSurfacePreset> presets,
  required String encounterTableId,
  SurfaceGameplayZoneGenerationAssessmentPolicy? assessmentPolicy,
}) {
  if (map == null) {
    return _blockedPreview(
      title: 'Aucune map active',
      description: 'Ouvrez une map avant de créer une zone de rencontre.',
    );
  }
  if (surfaceLayer == null) {
    return _blockedPreview(
      title: 'Aucun calque Surface actif',
      description:
          'Sélectionnez un calque Surface contenant la surface peinte.',
    );
  }

  final normalizedPresetId = surfacePresetId?.trim();
  if (normalizedPresetId == null || normalizedPresetId.isEmpty) {
    return _blockedPreview(
      title: 'Surface requise',
      description: 'Sélectionnez une surface peinte avant de créer une zone.',
    );
  }

  final preset = _findPresetById(presets, normalizedPresetId);
  if (preset == null) {
    return _blockedPreview(
      title: 'Surface absente du catalogue',
      description:
          'La surface "$normalizedPresetId" n’existe pas dans le catalogue Surface.',
      surfaceLabel: normalizedPresetId,
    );
  }

  final cells = surfaceLayer.placements
      .where(
        (placement) => placement.surfacePresetId.trim() == normalizedPresetId,
      )
      .map((placement) => GridPos(x: placement.x, y: placement.y))
      .toList(growable: false);
  if (cells.isEmpty) {
    return _blockedPreview(
      title: 'Aucune cellule peinte',
      description:
          'Cette surface n’a aucun placement dans le calque Surface ciblé.',
      surfaceLabel: preset.name,
    );
  }

  final normalizedEncounterTableId = encounterTableId.trim();
  if (normalizedEncounterTableId.isEmpty) {
    return _blockedPreview(
      title: 'Table de rencontres requise',
      description: 'Renseignez un encounterTableId avant de créer les zones.',
      surfaceLabel: preset.name,
      sourceCellCount: cells.length,
    );
  }

  final source = SurfaceGameplayZoneGenerationSource(
    surfaceLayerId: surfaceLayer.id,
    surfaceLayerName: surfaceLayer.name,
    surfacePresetId: normalizedPresetId,
    mapSize: map.size,
    cells: cells,
  );
  final plan = createSurfaceGameplayZoneGenerationPlan(
    source: source,
    behavior: SurfaceGameplayZoneBehaviorDraft.encounter(
      EncounterZonePayload(
        encounterTableId: normalizedEncounterTableId,
        encounterKind: EncounterKind.walk,
      ),
    ),
    strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
    zoneIdPrefix: '$normalizedPresetId-encounter',
    zoneNamePrefix: '${preset.name} - Rencontre',
    existingZones: map.gameplayZones,
  );
  final assessment = assessSurfaceGameplayZoneGenerationPlan(
    plan,
    policy: assessmentPolicy,
  );

  return TallGrassEncounterSurfaceGameplayZonePreview(
    surfaceLabel: preset.name,
    sourceCellCount: source.cells.length,
    status: assessment.status,
    messages: assessment.messages,
    plan: plan,
    assessment: assessment,
  );
}

SurfableWaterSurfaceGameplayZonePreview
    buildSurfableWaterSurfaceGameplayZonePreview({
  required MapData? map,
  required SurfaceLayer? surfaceLayer,
  required String? surfacePresetId,
  required List<ProjectSurfacePreset> presets,
  SurfaceGameplayZoneGenerationAssessmentPolicy? assessmentPolicy,
}) {
  if (map == null) {
    return _blockedWaterPreview(
      title: 'Aucune map active',
      description: 'Ouvrez une map avant de créer une zone Surf.',
    );
  }
  if (surfaceLayer == null) {
    return _blockedWaterPreview(
      title: 'Aucun calque Surface actif',
      description:
          'Sélectionnez un calque Surface contenant la surface peinte.',
    );
  }

  final normalizedPresetId = surfacePresetId?.trim();
  if (normalizedPresetId == null || normalizedPresetId.isEmpty) {
    return _blockedWaterPreview(
      title: 'Surface requise',
      description: 'Sélectionnez une surface peinte avant de créer une zone.',
    );
  }

  final preset = _findPresetById(presets, normalizedPresetId);
  if (preset == null) {
    return _blockedWaterPreview(
      title: 'Surface absente du catalogue',
      description:
          'La surface "$normalizedPresetId" n’existe pas dans le catalogue Surface.',
      surfaceLabel: normalizedPresetId,
    );
  }

  final cells = surfaceLayer.placements
      .where(
        (placement) => placement.surfacePresetId.trim() == normalizedPresetId,
      )
      .map((placement) => GridPos(x: placement.x, y: placement.y))
      .toList(growable: false);
  if (cells.isEmpty) {
    return _blockedWaterPreview(
      title: 'Aucune cellule peinte',
      description:
          'Cette surface n’a aucun placement dans le calque Surface ciblé.',
      surfaceLabel: preset.name,
    );
  }

  final source = SurfaceGameplayZoneGenerationSource(
    surfaceLayerId: surfaceLayer.id,
    surfaceLayerName: surfaceLayer.name,
    surfacePresetId: normalizedPresetId,
    mapSize: map.size,
    cells: cells,
  );
  final plan = createSurfaceGameplayZoneGenerationPlan(
    source: source,
    behavior: const SurfaceGameplayZoneBehaviorDraft.movement(
      MovementZonePayload(requiredMode: MovementMode.surf),
    ),
    strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
    zoneIdPrefix: '$normalizedPresetId-surf',
    zoneNamePrefix: '${preset.name} - Surf',
    existingZones: map.gameplayZones,
  );
  final assessment = assessSurfaceGameplayZoneGenerationPlan(
    plan,
    policy: assessmentPolicy,
  );

  return SurfableWaterSurfaceGameplayZonePreview(
    surfaceLabel: preset.name,
    sourceCellCount: source.cells.length,
    status: assessment.status,
    messages: assessment.messages,
    plan: plan,
    assessment: assessment,
  );
}

LavaHazardSurfaceGameplayZonePreview buildLavaHazardSurfaceGameplayZonePreview({
  required MapData? map,
  required SurfaceLayer? surfaceLayer,
  required String? surfacePresetId,
  required List<ProjectSurfacePreset> presets,
  required int? damagePerStep,
  SurfaceGameplayZoneGenerationAssessmentPolicy? assessmentPolicy,
}) {
  if (map == null) {
    return _blockedLavaPreview(
      title: 'Aucune map active',
      description: 'Ouvrez une map avant de créer une zone de lave.',
      damagePerStep: damagePerStep,
    );
  }
  if (surfaceLayer == null) {
    return _blockedLavaPreview(
      title: 'Aucun calque Surface actif',
      description:
          'Sélectionnez un calque Surface contenant la surface peinte.',
      damagePerStep: damagePerStep,
    );
  }

  final normalizedPresetId = surfacePresetId?.trim();
  if (normalizedPresetId == null || normalizedPresetId.isEmpty) {
    return _blockedLavaPreview(
      title: 'Surface requise',
      description: 'Sélectionnez une surface peinte avant de créer une zone.',
      damagePerStep: damagePerStep,
    );
  }

  final preset = _findPresetById(presets, normalizedPresetId);
  if (preset == null) {
    return _blockedLavaPreview(
      title: 'Surface absente du catalogue',
      description:
          'La surface "$normalizedPresetId" n’existe pas dans le catalogue Surface.',
      surfaceLabel: normalizedPresetId,
      damagePerStep: damagePerStep,
    );
  }

  final cells = surfaceLayer.placements
      .where(
        (placement) => placement.surfacePresetId.trim() == normalizedPresetId,
      )
      .map((placement) => GridPos(x: placement.x, y: placement.y))
      .toList(growable: false);
  if (cells.isEmpty) {
    return _blockedLavaPreview(
      title: 'Aucune cellule peinte',
      description:
          'Cette surface n’a aucun placement dans le calque Surface ciblé.',
      surfaceLabel: preset.name,
      damagePerStep: damagePerStep,
    );
  }

  if (damagePerStep == null || damagePerStep <= 0) {
    return _blockedLavaPreview(
      title: 'Dégâts par pas invalides',
      description:
          'Renseignez un entier strictement positif pour créer une zone de lave.',
      surfaceLabel: preset.name,
      sourceCellCount: cells.length,
      damagePerStep: damagePerStep,
    );
  }

  // Keep lava as a normal MapGameplayZone hazard: SurfaceLayer remains visual.
  final source = SurfaceGameplayZoneGenerationSource(
    surfaceLayerId: surfaceLayer.id,
    surfaceLayerName: surfaceLayer.name,
    surfacePresetId: normalizedPresetId,
    mapSize: map.size,
    cells: cells,
  );
  final plan = createSurfaceGameplayZoneGenerationPlan(
    source: source,
    behavior: SurfaceGameplayZoneBehaviorDraft.hazard(
      HazardZonePayload(
        hazardKind: HazardKind.lava,
        damagePerStep: damagePerStep,
      ),
    ),
    strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
    zoneIdPrefix: '$normalizedPresetId-lava',
    zoneNamePrefix: '${preset.name} - Lave',
    existingZones: map.gameplayZones,
  );
  final assessment = assessSurfaceGameplayZoneGenerationPlan(
    plan,
    policy: assessmentPolicy,
  );

  return LavaHazardSurfaceGameplayZonePreview(
    surfaceLabel: preset.name,
    sourceCellCount: source.cells.length,
    damagePerStep: damagePerStep,
    status: assessment.status,
    messages: assessment.messages,
    plan: plan,
    assessment: assessment,
  );
}

ProjectSurfacePreset? _findPresetById(
  List<ProjectSurfacePreset> presets,
  String presetId,
) {
  for (final preset in presets) {
    if (preset.id.trim() == presetId) {
      return preset;
    }
  }
  return null;
}

LavaHazardSurfaceGameplayZonePreview _blockedLavaPreview({
  required String title,
  required String description,
  String surfaceLabel = 'Surface',
  int sourceCellCount = 0,
  int? damagePerStep,
}) {
  return LavaHazardSurfaceGameplayZonePreview(
    surfaceLabel: surfaceLabel,
    sourceCellCount: sourceCellCount,
    damagePerStep: damagePerStep,
    status: SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
    messages: [
      SurfaceGameplayZoneGenerationAssessmentMessage(
        severity: SurfaceGameplayZoneGenerationDiagnosticSeverity.error,
        title: title,
        description: description,
      ),
    ],
  );
}

SurfableWaterSurfaceGameplayZonePreview _blockedWaterPreview({
  required String title,
  required String description,
  String surfaceLabel = 'Surface',
  int sourceCellCount = 0,
}) {
  return SurfableWaterSurfaceGameplayZonePreview(
    surfaceLabel: surfaceLabel,
    sourceCellCount: sourceCellCount,
    status: SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
    messages: [
      SurfaceGameplayZoneGenerationAssessmentMessage(
        severity: SurfaceGameplayZoneGenerationDiagnosticSeverity.error,
        title: title,
        description: description,
      ),
    ],
  );
}

TallGrassEncounterSurfaceGameplayZonePreview _blockedPreview({
  required String title,
  required String description,
  String surfaceLabel = 'Surface',
  int sourceCellCount = 0,
}) {
  return TallGrassEncounterSurfaceGameplayZonePreview(
    surfaceLabel: surfaceLabel,
    sourceCellCount: sourceCellCount,
    status: SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
    messages: [
      SurfaceGameplayZoneGenerationAssessmentMessage(
        severity: SurfaceGameplayZoneGenerationDiagnosticSeverity.error,
        title: title,
        description: description,
      ),
    ],
  );
}

```
### `packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/surface_painter/surface_palette_panel.dart';
import 'package:map_editor/src/features/surface_painter/surface_to_gameplay_zone_action.dart';
import 'package:map_editor/src/features/surface_painter/surface_to_gameplay_zone_dialog.dart';
import 'package:map_editor/src/features/surface_painter/surface_to_gameplay_zone_presenter.dart';

void main() {
  group('Tall grass surface to gameplay zone presenter', () {
    test('builds a greedy encounter generation preview from painted cells', () {
      final preview = buildTallGrassEncounterSurfaceGameplayZonePreview(
        map: _mapWithTallGrassSurface(),
        surfaceLayer: _tallGrassLayer(),
        surfacePresetId: 'tall_grass',
        presets: [_surfacePreset(id: 'tall_grass', name: 'Tall Grass')],
        encounterTableId: 'route_1_grass',
      );

      expect(preview.canConfirm, isTrue);
      expect(
        preview.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.ready,
      );
      expect(preview.plan, isNotNull);
      expect(
        preview.plan!.strategy,
        SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
      );
      expect(preview.plan!.generatedZones, hasLength(2));
      expect(
        preview.plan!.generatedZones.every(
          (zone) =>
              zone.kind == GameplayZoneKind.encounter &&
              zone.encounter?.encounterTableId == 'route_1_grass' &&
              zone.encounter?.encounterKind == EncounterKind.walk,
        ),
        isTrue,
      );
      expect(preview.assessment!.coveragePercent, 1);
      expect(preview.assessment!.extraCellRatio, 0);
    });

    test('blocks confirmation when encounterTableId is empty', () {
      final preview = buildTallGrassEncounterSurfaceGameplayZonePreview(
        map: _mapWithTallGrassSurface(),
        surfaceLayer: _tallGrassLayer(),
        surfacePresetId: 'tall_grass',
        presets: [_surfacePreset(id: 'tall_grass', name: 'Tall Grass')],
        encounterTableId: '   ',
      );

      expect(preview.canConfirm, isFalse);
      expect(
        preview.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
      );
      expect(preview.plan, isNull);
      expect(
        preview.messages.map((message) => message.title),
        contains('Table de rencontres requise'),
      );
    });

    test('blocks when selected surface has no painted placement', () {
      final preview = buildTallGrassEncounterSurfaceGameplayZonePreview(
        map: _mapWithTallGrassSurface(),
        surfaceLayer: _tallGrassLayer(),
        surfacePresetId: 'water',
        presets: [
          _surfacePreset(id: 'tall_grass', name: 'Tall Grass'),
          _surfacePreset(id: 'water', name: 'Water'),
        ],
        encounterTableId: 'route_1_grass',
      );

      expect(preview.canConfirm, isFalse);
      expect(
        preview.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
      );
      expect(
        preview.messages.map((message) => message.title),
        contains('Aucune cellule peinte'),
      );
    });
  });

  group('Surfable water surface to gameplay zone presenter', () {
    test('builds a greedy movement/surf generation preview from painted cells',
        () {
      final preview = buildSurfableWaterSurfaceGameplayZonePreview(
        map: _mapWithWaterSurface(),
        surfaceLayer: _waterLayer(),
        surfacePresetId: 'water',
        presets: [_surfacePreset(id: 'water', name: 'Water')],
      );

      expect(preview.canConfirm, isTrue);
      expect(
        preview.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.ready,
      );
      expect(preview.plan, isNotNull);
      expect(
        preview.plan!.strategy,
        SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
      );
      expect(preview.plan!.generatedZones, hasLength(2));
      expect(
        preview.plan!.generatedZones.every(
          (zone) =>
              zone.kind == GameplayZoneKind.movement &&
              zone.movement?.requiredMode == MovementMode.surf &&
              zone.movement?.allowedModes.isEmpty == true,
        ),
        isTrue,
      );
      expect(preview.assessment!.coveragePercent, 1);
      expect(preview.assessment!.extraCellRatio, 0);
    });

    test('blocks when selected water surface has no painted placement', () {
      final preview = buildSurfableWaterSurfaceGameplayZonePreview(
        map: _mapWithWaterSurface(),
        surfaceLayer: _waterLayer(),
        surfacePresetId: 'tall_grass',
        presets: [
          _surfacePreset(id: 'water', name: 'Water'),
          _surfacePreset(id: 'tall_grass', name: 'Tall Grass'),
        ],
      );

      expect(preview.canConfirm, isFalse);
      expect(
        preview.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
      );
      expect(
        preview.messages.map((message) => message.title),
        contains('Aucune cellule peinte'),
      );
    });
  });

  group('Lava hazard surface to gameplay zone presenter', () {
    test('builds a greedy hazard/lava generation preview from painted cells',
        () {
      final preview = buildLavaHazardSurfaceGameplayZonePreview(
        map: _mapWithLavaSurface(),
        surfaceLayer: _lavaLayer(),
        surfacePresetId: 'lava',
        presets: [_surfacePreset(id: 'lava', name: 'Lava')],
        damagePerStep: 5,
      );

      expect(preview.canConfirm, isTrue);
      expect(preview.damagePerStep, 5);
      expect(
        preview.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.ready,
      );
      expect(preview.plan, isNotNull);
      expect(
        preview.plan!.strategy,
        SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
      );
      expect(preview.plan!.generatedZones, hasLength(2));
      expect(
        preview.plan!.generatedZones.every(
          (zone) =>
              zone.kind == GameplayZoneKind.hazard &&
              zone.hazard?.hazardKind == HazardKind.lava &&
              zone.hazard?.damagePerStep == 5,
        ),
        isTrue,
      );
      expect(preview.assessment!.coveragePercent, 1);
      expect(preview.assessment!.extraCellRatio, 0);
    });

    test('blocks when damagePerStep is not positive', () {
      final preview = buildLavaHazardSurfaceGameplayZonePreview(
        map: _mapWithLavaSurface(),
        surfaceLayer: _lavaLayer(),
        surfacePresetId: 'lava',
        presets: [_surfacePreset(id: 'lava', name: 'Lava')],
        damagePerStep: 0,
      );

      expect(preview.canConfirm, isFalse);
      expect(
        preview.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
      );
      expect(preview.plan, isNull);
      expect(
        preview.messages.map((message) => message.title),
        contains('Dégâts par pas invalides'),
      );
    });

    test('blocks when selected lava surface has no painted placement', () {
      final preview = buildLavaHazardSurfaceGameplayZonePreview(
        map: _mapWithLavaSurface(),
        surfaceLayer: _lavaLayer(),
        surfacePresetId: 'water',
        presets: [
          _surfacePreset(id: 'lava', name: 'Lava'),
          _surfacePreset(id: 'water', name: 'Water'),
        ],
        damagePerStep: 5,
      );

      expect(preview.canConfirm, isFalse);
      expect(
        preview.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
      );
      expect(
        preview.messages.map((message) => message.title),
        contains('Aucune cellule peinte'),
      );
    });

    test('blocks when selected lava preset is absent from catalog', () {
      final preview = buildLavaHazardSurfaceGameplayZonePreview(
        map: _mapWithLavaSurface(),
        surfaceLayer: _lavaLayer(),
        surfacePresetId: 'lava',
        presets: const [],
        damagePerStep: 5,
      );

      expect(preview.canConfirm, isFalse);
      expect(
        preview.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
      );
      expect(
        preview.messages.map((message) => message.title),
        contains('Surface absente du catalogue'),
      );
    });

    test('blocks when map is null', () {
      final preview = buildLavaHazardSurfaceGameplayZonePreview(
        map: null,
        surfaceLayer: _lavaLayer(),
        surfacePresetId: 'lava',
        presets: [_surfacePreset(id: 'lava', name: 'Lava')],
        damagePerStep: 5,
      );

      expect(preview.canConfirm, isFalse);
      expect(
        preview.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
      );
      expect(
        preview.messages.map((message) => message.title),
        contains('Aucune map active'),
      );
    });
  });

  group('SurfaceToGameplayZoneDialog', () {
    testWidgets('requires an encounter table id before confirming',
        (tester) async {
      SurfaceGameplayZoneGenerationPlan? confirmedPlan;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: SurfaceToGameplayZoneDialog(
              map: _mapWithTallGrassSurface(),
              surfaceLayer: _tallGrassLayer(),
              surfacePresetId: 'tall_grass',
              presets: [_surfacePreset(id: 'tall_grass', name: 'Tall Grass')],
              encounterTables: const [],
              onConfirm: (plan) => confirmedPlan = plan,
            ),
          ),
        ),
      );

      expect(
        find.text('Créer une zone de rencontre depuis cette surface'),
        findsOneWidget,
      );
      expect(find.text('Table de rencontres requise'), findsOneWidget);
      expect(
        tester
            .widget<CupertinoDialogAction>(
              find.widgetWithText(CupertinoDialogAction, 'Créer les zones'),
            )
            .onPressed,
        isNull,
      );
      expect(confirmedPlan, isNull);

      await tester.enterText(
        find.byKey(const Key('surface-to-gameplay-zone-encounter-table-field')),
        'route_1_grass',
      );
      await tester.pump();

      expect(find.text('Plan prêt à appliquer'), findsOneWidget);

      final createAction = tester.widget<CupertinoDialogAction>(
        find.widgetWithText(CupertinoDialogAction, 'Créer les zones'),
      );
      expect(createAction.onPressed, isNotNull);
      createAction.onPressed!();

      expect(confirmedPlan, isNotNull);
      expect(confirmedPlan!.generatedZones, hasLength(2));
    });
  });

  group('SurfableWaterSurfaceGameplayZoneDialog', () {
    testWidgets('confirms a ready surfable water plan', (tester) async {
      SurfaceGameplayZoneGenerationPlan? confirmedPlan;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: SurfableWaterSurfaceGameplayZoneDialog(
              map: _mapWithWaterSurface(),
              surfaceLayer: _waterLayer(),
              surfacePresetId: 'water',
              presets: [_surfacePreset(id: 'water', name: 'Water')],
              onConfirm: (plan) => confirmedPlan = plan,
            ),
          ),
        ),
      );

      expect(find.text('Rendre cette eau surfable'), findsOneWidget);
      expect(find.text('Mode : '), findsOneWidget);
      expect(find.text('Surf'), findsOneWidget);
      expect(find.text('Plan prêt à appliquer'), findsOneWidget);

      final createAction = tester.widget<CupertinoDialogAction>(
        find.widgetWithText(CupertinoDialogAction, 'Créer la zone Surf'),
      );
      expect(createAction.onPressed, isNotNull);
      createAction.onPressed!();

      expect(confirmedPlan, isNotNull);
      expect(confirmedPlan!.generatedZones, hasLength(2));
    });

    testWidgets('disables confirmation when the water plan is blocked',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: SurfableWaterSurfaceGameplayZoneDialog(
              map: _mapWithWaterSurface(),
              surfaceLayer: _waterLayer(),
              surfacePresetId: 'tall_grass',
              presets: [_surfacePreset(id: 'tall_grass', name: 'Tall Grass')],
              onConfirm: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Rendre cette eau surfable'), findsOneWidget);
      expect(find.text('Aucune cellule peinte'), findsOneWidget);
      expect(
        tester
            .widget<CupertinoDialogAction>(
              find.widgetWithText(
                CupertinoDialogAction,
                'Créer la zone Surf',
              ),
            )
            .onPressed,
        isNull,
      );
    });
  });

  group('LavaHazardSurfaceGameplayZoneDialog', () {
    testWidgets('confirms a ready lava hazard plan with default damage',
        (tester) async {
      SurfaceGameplayZoneGenerationPlan? confirmedPlan;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: LavaHazardSurfaceGameplayZoneDialog(
              map: _mapWithLavaSurface(),
              surfaceLayer: _lavaLayer(),
              surfacePresetId: 'lava',
              presets: [_surfacePreset(id: 'lava', name: 'Lava')],
              onConfirm: (plan) => confirmedPlan = plan,
            ),
          ),
        ),
      );

      expect(find.text('Créer une zone de lave dangereuse'), findsOneWidget);
      expect(find.text('Dégâts par pas'), findsOneWidget);
      expect(find.text('Type : '), findsOneWidget);
      expect(find.text('Lave dangereuse'), findsOneWidget);
      final damageField = tester.widget<CupertinoTextField>(
        find.byKey(const Key('surface-to-gameplay-zone-lava-damage-field')),
      );
      expect(damageField.controller?.text, '5');
      expect(find.text('Plan prêt à appliquer'), findsOneWidget);

      final createAction = tester.widget<CupertinoDialogAction>(
        find.widgetWithText(CupertinoDialogAction, 'Créer la zone de lave'),
      );
      expect(createAction.onPressed, isNotNull);
      createAction.onPressed!();

      expect(confirmedPlan, isNotNull);
      expect(confirmedPlan!.generatedZones, hasLength(2));
      expect(
        confirmedPlan!.generatedZones.every(
          (zone) =>
              zone.kind == GameplayZoneKind.hazard &&
              zone.hazard?.hazardKind == HazardKind.lava &&
              zone.hazard?.damagePerStep == 5,
        ),
        isTrue,
      );
    });

    testWidgets('requires positive damage and uses edited damage in the plan',
        (tester) async {
      SurfaceGameplayZoneGenerationPlan? confirmedPlan;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: LavaHazardSurfaceGameplayZoneDialog(
              map: _mapWithLavaSurface(),
              surfaceLayer: _lavaLayer(),
              surfacePresetId: 'lava',
              presets: [_surfacePreset(id: 'lava', name: 'Lava')],
              onConfirm: (plan) => confirmedPlan = plan,
            ),
          ),
        ),
      );

      final field = find.byKey(
        const Key('surface-to-gameplay-zone-lava-damage-field'),
      );
      await tester.enterText(field, '0');
      await tester.pump();

      expect(find.text('Dégâts par pas invalides'), findsOneWidget);
      expect(
        tester
            .widget<CupertinoDialogAction>(
              find.widgetWithText(
                CupertinoDialogAction,
                'Créer la zone de lave',
              ),
            )
            .onPressed,
        isNull,
      );

      await tester.enterText(field, '8');
      await tester.pump();

      final createAction = tester.widget<CupertinoDialogAction>(
        find.widgetWithText(CupertinoDialogAction, 'Créer la zone de lave'),
      );
      expect(createAction.onPressed, isNotNull);
      createAction.onPressed!();

      expect(confirmedPlan, isNotNull);
      expect(
        confirmedPlan!.generatedZones.every(
          (zone) => zone.hazard?.damagePerStep == 8,
        ),
        isTrue,
      );
    });
  });

  group('SurfacePainterPanel behavior action menu', () {
    testWidgets('shows one behavior action and opens behavior choices',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final keepAlive = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        project: _projectManifest(),
        activeMap: _mapWithTallGrassSurface(),
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'tall_grass',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const CupertinoApp(
            home: CupertinoPageScaffold(
              child: SurfacePainterPanel(embedded: true),
            ),
          ),
        ),
      );

      expect(
        find.text('Créer un comportement depuis cette surface'),
        findsOneWidget,
      );
      expect(find.text('Créer une zone de rencontre'), findsNothing);
      expect(find.text('Rendre cette eau surfable'), findsNothing);

      await tester.tap(
        find.text('Créer un comportement depuis cette surface'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Herbe haute avec rencontres'), findsOneWidget);
      expect(find.text('Eau surfable'), findsOneWidget);
      expect(find.text('Lave dangereuse'), findsOneWidget);
    });

    testWidgets('routes tall grass choice to the encounter dialog',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final keepAlive = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        project: _projectManifest(),
        activeMap: _mapWithTallGrassSurface(),
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'tall_grass',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const CupertinoApp(
            home: CupertinoPageScaffold(
              child: SurfacePainterPanel(embedded: true),
            ),
          ),
        ),
      );

      await tester.tap(
        find.text('Créer un comportement depuis cette surface'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Herbe haute avec rencontres'));
      await tester.pumpAndSettle();

      expect(
        find.text('Créer une zone de rencontre depuis cette surface'),
        findsOneWidget,
      );
      expect(find.text('Plan prêt à appliquer'), findsOneWidget);
    });

    testWidgets('routes water choice to the surfable water dialog',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final keepAlive = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        project: _projectManifest(
          surfacePresets: [_surfacePreset(id: 'water', name: 'Water')],
        ),
        activeMap: _mapWithWaterSurface(),
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'water',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const CupertinoApp(
            home: CupertinoPageScaffold(
              child: SurfacePainterPanel(embedded: true),
            ),
          ),
        ),
      );

      await tester.tap(
        find.text('Créer un comportement depuis cette surface'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eau surfable'));
      await tester.pumpAndSettle();

      expect(find.text('Rendre cette eau surfable'), findsOneWidget);
      expect(find.text('Plan prêt à appliquer'), findsOneWidget);
    });

    testWidgets('routes lava choice to the lava hazard dialog', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final keepAlive = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        project: _projectManifest(
          surfacePresets: [_surfacePreset(id: 'lava', name: 'Lava')],
        ),
        activeMap: _mapWithLavaSurface(),
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'lava',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const CupertinoApp(
            home: CupertinoPageScaffold(
              child: SurfacePainterPanel(embedded: true),
            ),
          ),
        ),
      );

      await tester.tap(
        find.text('Créer un comportement depuis cette surface'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lave dangereuse'));
      await tester.pumpAndSettle();

      expect(find.text('Créer une zone de lave dangereuse'), findsOneWidget);
      expect(find.text('Plan prêt à appliquer'), findsOneWidget);
    });
  });

  group('EditorNotifier tall grass surface generation', () {
    test(
        'adds multiple encounter gameplay zones in one mutation and selects first',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithTallGrassSurface();
      notifier.state = EditorState(
        project: _projectManifest(),
        activeMap: initialMap,
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'tall_grass',
        savedMapSnapshot: initialMap,
      );
      final preview = buildTallGrassEncounterSurfaceGameplayZonePreview(
        map: initialMap,
        surfaceLayer: _tallGrassLayer(),
        surfacePresetId: 'tall_grass',
        presets: [_surfacePreset(id: 'tall_grass', name: 'Tall Grass')],
        encounterTableId: 'route_1_grass',
      );

      final applied = applyTallGrassEncounterGameplayZonePlan(
        notifier: notifier,
        plan: preview.plan!,
      );

      final state = container.read(editorNotifierProvider);
      final updatedMap = state.activeMap!;
      expect(applied, isTrue);
      expect(updatedMap.gameplayZones, hasLength(2));
      expect(
        updatedMap.gameplayZones.every(
          (zone) =>
              zone.kind == GameplayZoneKind.encounter &&
              zone.encounter?.encounterTableId == 'route_1_grass' &&
              zone.encounter?.encounterKind == EncounterKind.walk,
        ),
        isTrue,
      );
      expect(state.selectedGameplayZoneId, updatedMap.gameplayZones.first.id);
      expect(state.isDirty, isTrue);
      expect(state.mapUndoStack, hasLength(1));
      expect(state.canUndoMap, isTrue);
      expect(
        updatedMap.layers.whereType<SurfaceLayer>().single.placements,
        initialMap.layers.whereType<SurfaceLayer>().single.placements,
      );
    });

    test('rejects non-encounter plans without mutating the map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithTallGrassSurface();
      notifier.state = EditorState(
        project: _projectManifest(),
        activeMap: initialMap,
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'tall_grass',
        savedMapSnapshot: initialMap,
      );

      final applied = applyTallGrassEncounterGameplayZonePlan(
        notifier: notifier,
        plan: _planForBehavior(
          const SurfaceGameplayZoneBehaviorDraft.movement(
            MovementZonePayload(requiredMode: MovementMode.surf),
          ),
        ),
      );

      final state = container.read(editorNotifierProvider);
      expect(applied, isFalse);
      expect(state.activeMap, initialMap);
      expect(state.activeMap!.gameplayZones, isEmpty);
      expect(state.mapUndoStack, isEmpty);
      expect(state.selectedGameplayZoneId, isNull);
      expect(state.isDirty, isFalse);
    });

    test('rejects non-walk encounter plans without mutating the map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithTallGrassSurface();
      notifier.state = EditorState(
        project: _projectManifest(),
        activeMap: initialMap,
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'tall_grass',
        savedMapSnapshot: initialMap,
      );

      final applied = applyTallGrassEncounterGameplayZonePlan(
        notifier: notifier,
        plan: _planForBehavior(
          const SurfaceGameplayZoneBehaviorDraft.encounter(
            EncounterZonePayload(
              encounterTableId: 'route_1_surf',
              encounterKind: EncounterKind.surf,
            ),
          ),
        ),
      );

      final state = container.read(editorNotifierProvider);
      expect(applied, isFalse);
      expect(state.activeMap, initialMap);
      expect(state.activeMap!.gameplayZones, isEmpty);
      expect(state.mapUndoStack, isEmpty);
      expect(state.selectedGameplayZoneId, isNull);
      expect(state.isDirty, isFalse);
    });
  });

  group('EditorNotifier surfable water surface generation', () {
    test(
        'adds multiple movement surf gameplay zones in one mutation and selects first',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithWaterSurface();
      notifier.state = EditorState(
        project: _projectManifest(
          surfacePresets: [_surfacePreset(id: 'water', name: 'Water')],
        ),
        activeMap: initialMap,
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'water',
        savedMapSnapshot: initialMap,
      );
      final preview = buildSurfableWaterSurfaceGameplayZonePreview(
        map: initialMap,
        surfaceLayer: _waterLayer(),
        surfacePresetId: 'water',
        presets: [_surfacePreset(id: 'water', name: 'Water')],
      );

      final applied = applySurfableWaterGameplayZonePlan(
        notifier: notifier,
        plan: preview.plan!,
      );

      final state = container.read(editorNotifierProvider);
      final updatedMap = state.activeMap!;
      expect(applied, isTrue);
      expect(updatedMap.gameplayZones, hasLength(2));
      expect(
        updatedMap.gameplayZones.every(
          (zone) =>
              zone.kind == GameplayZoneKind.movement &&
              zone.movement?.requiredMode == MovementMode.surf &&
              zone.movement?.allowedModes.isEmpty == true,
        ),
        isTrue,
      );
      expect(state.selectedGameplayZoneId, updatedMap.gameplayZones.first.id);
      expect(state.isDirty, isTrue);
      expect(state.mapUndoStack, hasLength(1));
      expect(state.canUndoMap, isTrue);
      expect(
        updatedMap.layers.whereType<SurfaceLayer>().single.placements,
        initialMap.layers.whereType<SurfaceLayer>().single.placements,
      );
    });

    test('rejects non-movement plans without mutating the map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithWaterSurface();
      notifier.state = EditorState(
        project: _projectManifest(
          surfacePresets: [_surfacePreset(id: 'water', name: 'Water')],
        ),
        activeMap: initialMap,
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'water',
        savedMapSnapshot: initialMap,
      );

      final applied = applySurfableWaterGameplayZonePlan(
        notifier: notifier,
        plan: _planForBehavior(
          const SurfaceGameplayZoneBehaviorDraft.encounter(
            EncounterZonePayload(
              encounterTableId: 'route_1_grass',
              encounterKind: EncounterKind.walk,
            ),
          ),
        ),
      );

      final state = container.read(editorNotifierProvider);
      expect(applied, isFalse);
      expect(state.activeMap, initialMap);
      expect(state.activeMap!.gameplayZones, isEmpty);
      expect(state.mapUndoStack, isEmpty);
      expect(state.selectedGameplayZoneId, isNull);
      expect(state.isDirty, isFalse);
    });

    test('rejects movement plans that do not require surf without mutating',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithWaterSurface();
      notifier.state = EditorState(
        project: _projectManifest(
          surfacePresets: [_surfacePreset(id: 'water', name: 'Water')],
        ),
        activeMap: initialMap,
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'water',
        savedMapSnapshot: initialMap,
      );

      final applied = applySurfableWaterGameplayZonePlan(
        notifier: notifier,
        plan: _planForBehavior(
          const SurfaceGameplayZoneBehaviorDraft.movement(
            MovementZonePayload(requiredMode: MovementMode.walk),
          ),
        ),
      );

      final state = container.read(editorNotifierProvider);
      expect(applied, isFalse);
      expect(state.activeMap, initialMap);
      expect(state.activeMap!.gameplayZones, isEmpty);
      expect(state.mapUndoStack, isEmpty);
      expect(state.selectedGameplayZoneId, isNull);
      expect(state.isDirty, isFalse);
    });
  });

  group('EditorNotifier lava hazard surface generation', () {
    test(
        'adds multiple hazard lava gameplay zones in one mutation and selects first',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithLavaSurface();
      notifier.state = EditorState(
        project: _projectManifest(
          surfacePresets: [_surfacePreset(id: 'lava', name: 'Lava')],
        ),
        activeMap: initialMap,
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'lava',
        savedMapSnapshot: initialMap,
      );
      final preview = buildLavaHazardSurfaceGameplayZonePreview(
        map: initialMap,
        surfaceLayer: _lavaLayer(),
        surfacePresetId: 'lava',
        presets: [_surfacePreset(id: 'lava', name: 'Lava')],
        damagePerStep: 5,
      );

      final applied = applyLavaHazardGameplayZonePlan(
        notifier: notifier,
        plan: preview.plan!,
      );

      final state = container.read(editorNotifierProvider);
      final updatedMap = state.activeMap!;
      expect(applied, isTrue);
      expect(updatedMap.gameplayZones, hasLength(2));
      expect(
        updatedMap.gameplayZones.every(
          (zone) =>
              zone.kind == GameplayZoneKind.hazard &&
              zone.hazard?.hazardKind == HazardKind.lava &&
              zone.hazard?.damagePerStep == 5,
        ),
        isTrue,
      );
      expect(state.selectedGameplayZoneId, updatedMap.gameplayZones.first.id);
      expect(state.isDirty, isTrue);
      expect(state.mapUndoStack, hasLength(1));
      expect(state.canUndoMap, isTrue);
      expect(
        updatedMap.layers.whereType<SurfaceLayer>().single.placements,
        initialMap.layers.whereType<SurfaceLayer>().single.placements,
      );
    });

    test('rejects non-hazard plans without mutating the map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithLavaSurface();
      notifier.state = EditorState(
        project: _projectManifest(
          surfacePresets: [_surfacePreset(id: 'lava', name: 'Lava')],
        ),
        activeMap: initialMap,
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'lava',
        savedMapSnapshot: initialMap,
      );

      final applied = applyLavaHazardGameplayZonePlan(
        notifier: notifier,
        plan: _planForBehavior(
          const SurfaceGameplayZoneBehaviorDraft.movement(
            MovementZonePayload(requiredMode: MovementMode.surf),
          ),
        ),
      );

      final state = container.read(editorNotifierProvider);
      expect(applied, isFalse);
      expect(state.activeMap, initialMap);
      expect(state.activeMap!.gameplayZones, isEmpty);
      expect(state.mapUndoStack, isEmpty);
      expect(state.selectedGameplayZoneId, isNull);
      expect(state.isDirty, isFalse);
    });

    test('rejects non-lava hazard plans without mutating the map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithLavaSurface();
      notifier.state = EditorState(
        project: _projectManifest(
          surfacePresets: [_surfacePreset(id: 'lava', name: 'Lava')],
        ),
        activeMap: initialMap,
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'lava',
        savedMapSnapshot: initialMap,
      );

      final applied = applyLavaHazardGameplayZonePlan(
        notifier: notifier,
        plan: _planForBehavior(
          const SurfaceGameplayZoneBehaviorDraft.hazard(
            HazardZonePayload(
              hazardKind: HazardKind.poison,
              damagePerStep: 5,
            ),
          ),
        ),
      );

      final state = container.read(editorNotifierProvider);
      expect(applied, isFalse);
      expect(state.activeMap, initialMap);
      expect(state.activeMap!.gameplayZones, isEmpty);
      expect(state.mapUndoStack, isEmpty);
      expect(state.selectedGameplayZoneId, isNull);
      expect(state.isDirty, isFalse);
    });

    test('rejects lava hazard plans without positive damage', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithLavaSurface();
      notifier.state = EditorState(
        project: _projectManifest(
          surfacePresets: [_surfacePreset(id: 'lava', name: 'Lava')],
        ),
        activeMap: initialMap,
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'lava',
        savedMapSnapshot: initialMap,
      );

      final applied = applyLavaHazardGameplayZonePlan(
        notifier: notifier,
        plan: _planForBehavior(
          const SurfaceGameplayZoneBehaviorDraft.hazard(
            HazardZonePayload(
              hazardKind: HazardKind.lava,
              damagePerStep: 0,
            ),
          ),
        ),
      );

      final state = container.read(editorNotifierProvider);
      expect(applied, isFalse);
      expect(state.activeMap, initialMap);
      expect(state.activeMap!.gameplayZones, isEmpty);
      expect(state.mapUndoStack, isEmpty);
      expect(state.selectedGameplayZoneId, isNull);
      expect(state.isDirty, isFalse);
    });
  });
}

SurfaceGameplayZoneGenerationPlan _planForBehavior(
  SurfaceGameplayZoneBehaviorDraft behavior,
) {
  return createSurfaceGameplayZoneGenerationPlan(
    source: SurfaceGameplayZoneGenerationSource(
      surfaceLayerId: 'surface-main',
      surfaceLayerName: 'Surfaces',
      surfacePresetId: 'tall_grass',
      cells: const [
        GridPos(x: 0, y: 0),
        GridPos(x: 2, y: 0),
      ],
      mapSize: const GridSize(width: 8, height: 8),
    ),
    behavior: behavior,
    strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
    zoneIdPrefix: 'tall-grass-encounter',
    zoneNamePrefix: 'Tall Grass - Rencontre',
  );
}

MapData _mapWithTallGrassSurface() {
  return MapData(
    id: 'route_1',
    name: 'Route 1',
    size: const GridSize(width: 8, height: 8),
    layers: [_tallGrassLayer()],
  );
}

MapData _mapWithWaterSurface() {
  return MapData(
    id: 'route_1',
    name: 'Route 1',
    size: const GridSize(width: 8, height: 8),
    layers: [_waterLayer()],
  );
}

MapData _mapWithLavaSurface() {
  return MapData(
    id: 'route_1',
    name: 'Route 1',
    size: const GridSize(width: 8, height: 8),
    layers: [_lavaLayer()],
  );
}

SurfaceLayer _tallGrassLayer() {
  return const SurfaceLayer(
    id: 'surface-main',
    name: 'Surfaces',
    placements: [
      SurfaceCellPlacement(
        x: 0,
        y: 0,
        surfacePresetId: 'tall_grass',
      ),
      SurfaceCellPlacement(
        x: 1,
        y: 0,
        surfacePresetId: 'tall_grass',
      ),
      SurfaceCellPlacement(
        x: 0,
        y: 1,
        surfacePresetId: 'tall_grass',
      ),
    ],
  );
}

SurfaceLayer _waterLayer() {
  return const SurfaceLayer(
    id: 'surface-main',
    name: 'Surfaces',
    placements: [
      SurfaceCellPlacement(
        x: 2,
        y: 0,
        surfacePresetId: 'water',
      ),
      SurfaceCellPlacement(
        x: 3,
        y: 0,
        surfacePresetId: 'water',
      ),
      SurfaceCellPlacement(
        x: 2,
        y: 1,
        surfacePresetId: 'water',
      ),
    ],
  );
}

SurfaceLayer _lavaLayer() {
  return const SurfaceLayer(
    id: 'surface-main',
    name: 'Surfaces',
    placements: [
      SurfaceCellPlacement(
        x: 4,
        y: 0,
        surfacePresetId: 'lava',
      ),
      SurfaceCellPlacement(
        x: 5,
        y: 0,
        surfacePresetId: 'lava',
      ),
      SurfaceCellPlacement(
        x: 4,
        y: 1,
        surfacePresetId: 'lava',
      ),
    ],
  );
}

ProjectManifest _projectManifest({
  List<ProjectSurfacePreset>? surfacePresets,
}) {
  return ProjectManifest(
    name: 'Demo',
    maps: const [],
    tilesets: const [],
    encounterTables: const [
      ProjectEncounterTable(
        id: 'route_1_grass',
        name: 'Route 1 Grass',
        encounterKind: EncounterKind.walk,
      ),
    ],
    surfaceCatalog: ProjectSurfaceCatalog(
      presets: surfacePresets ??
          [_surfacePreset(id: 'tall_grass', name: 'Tall Grass')],
    ),
  );
}

ProjectSurfacePreset _surfacePreset({
  required String id,
  required String name,
}) {
  return ProjectSurfacePreset(
    id: id,
    name: name,
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: '$id-isolated',
        ),
      ],
    ),
  );
}

```


## 22. Git status final

```text
git status --short --untracked-files=all
 M packages/map_editor/lib/src/features/surface_painter/surface_behavior_action_menu.dart
 M packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_action.dart
 M packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_dialog.dart
 M packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_presenter.dart
 M packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart
?? reports/surface/surface_engine_lot_109_editor_generate_lava_hazard_zone_from_surface.md

git diff --stat
 .../surface_behavior_action_menu.dart              |  35 ++
 .../surface_to_gameplay_zone_action.dart           |  28 ++
 .../surface_to_gameplay_zone_dialog.dart           | 124 ++++++
 .../surface_to_gameplay_zone_presenter.dart        | 171 ++++++++
 .../surface_to_gameplay_zone_action_test.dart      | 455 +++++++++++++++++++++
 5 files changed, 813 insertions(+)

git log --oneline -n 10
3ef5fc92 lot 108: Hazard Runtime Consumption Prep
e8bfc68e lot 107: Lava Hazard from Surface Workflow Decision
4851b53f lot 106: Surface Behavior Action Menu
2305f276 lot 104: Surface Gameplay Bridge Runtime E2E Closure
8b5c3728 lot 103: Editor Generate Surfable Water Gameplay Zone from Surface
6a3db8e3 lot 101: Tall Grass Surface Workflow Hardening - Batch Apply
b224b0f6 fix: resolve RenderFlex overflow errors in layers and surface panels
888f1339 fix: resolve RenderFlex overflow errors in layers and surface panels
58ab7070 lot 100/95: Editor Generate Gameplay Zone from Surface
15fa925c lot 99/95: Surface Gameplay - Surface to Gameplay Zone Coverage Diagnostics
```

## 23. Périmètre explicitement non touché

Confirmations :

- map_core production non modifié ;
- map_gameplay production non modifié par Lot 109 ;
- map_runtime production non modifié ;
- map_battle non modifié ;
- MapData modèle non modifié ;
- MapGameplayZone modèle non modifié ;
- HazardZonePayload non modifié ;
- HazardKind non modifié ;
- MovementZonePayload non modifié ;
- EncounterZonePayload non modifié ;
- SurfaceLayer non modifié ;
- SurfaceCellPlacement non modifié ;
- ProjectManifest non modifié ;
- aucun JSON ;
- aucun generated/build_runner ;
- aucun runtime Flutter modifié ;
- aucune application de dégâts HP / party / GameState ;
- aucun ice / mud codé ;
- aucune migration legacy ;
- aucun filtre surfacePresetId dans MapGameplayZone.

## 24. ctx stats

```text
ctx stats
/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/.ctx-mode-5nU7QK/script.sh: line 1: ctx: command not found

context-mode doctor
- [x] Runtimes: 7/11 (64%) — javascript, shell, python, ruby, rust, php, perl
- [-] Performance: NORMAL — install Bun for 3-5x speed boost
- [x] Server test: PASS
- [x] FTS5 / SQLite: PASS — native module works
- [x] Hook script: PASS — /opt/homebrew/lib/node_modules/context-mode/hooks/pretooluse.mjs
- [x] Version: v1.0.100
```

Context Mode MCP a été utilisé pour Gate 0, audits, tests, analyse, diff et report checks. La commande shell `ctx stats` demandée a été exécutée ; le binaire shell n'est pas installé, mais le serveur MCP Context Mode fonctionne. Principales sorties indexées : Gate 0 47 lignes / 1,4 KB, audit 2917 lignes / 152,7 KB, vérifications finales 210 lignes / 24,8 KB, diff/scope 972 lignes / 32,3 KB.

## 25. Limites restantes

- L'action crée les zones lava/hazard, mais aucun feedback Flutter runtime n'est codé dans ce lot.
- Les dégâts restent seulement des métadonnées authorées et un effet observable côté `map_gameplay` via Lot 108.
- Pas de validation automatique que le preset sélectionné est visuellement de la lave ; l'utilisateur choisit explicitement `Lave dangereuse`.
- Pas de preview graphique de couverture.
- Pas de regroupement plus riche type assistant multi-step.

## 26. Auto-critique

- Est-ce que “Lave dangereuse” existe dans le menu comportement ? Oui.
- Est-ce que le lot reste limité à lava/hazard editor ? Oui.
- Est-ce que tall grass reste fonctionnel ? Oui.
- Est-ce que water/surf reste fonctionnel ? Oui.
- Est-ce que SurfaceLayer reste visuel ? Oui.
- Est-ce que MapGameplayZone est réutilisé ? Oui.
- Est-ce que HazardZonePayload(hazardKind: lava, damagePerStep > 0) est utilisé ? Oui.
- Est-ce que damagePerStep est obligatoire ou prérempli à 5 ? Oui, prérempli à 5 et strictement positif.
- Est-ce que greedyRectangles est utilisé par défaut ? Oui.
- Est-ce que la confirmation empêche un plan blocked ? Oui.
- Est-ce que les zones créées sont des MapGameplayZone hazard/lava ? Oui.
- Est-ce que la map devient dirty ? Oui.
- Est-ce qu'aucune SurfaceLayer n'est modifiée ? Oui.
- Est-ce que les plans invalides ne mutent rien partiellement ? Oui.
- Est-ce que hazard_runtime_consumption_test.dart passe ? Oui.
- Est-ce que les tests ciblés passent ? Oui.
- Est-ce que les régressions Surface Painter passent ? Oui.
- Est-ce que l'analyse ciblée passe ? Oui.
- Est-ce que Context Mode a été utilisé agressivement ? Oui.
- Est-ce que ctx stats est inclus ? Oui, avec sortie exacte du CLI indisponible et doctor MCP.
- Est-ce que le contenu complet des fichiers créés/modifiés est copié dans le rapport ? Oui, les fichiers modifiés sont copiés et le rapport lui-même est exclu par exception.
- Est-ce qu'un Lot 109-bis est nécessaire ? Non. Le workflow editor lava V0 est branché et testé.

## 27. Regard critique sur le prompt

Le prompt est bien séquencé : Lot 107 a empêché un bouton lava inerte, Lot 108 a prouvé la consommation gameplay minimale, et Lot 109 peut donc rester un lot authoring propre. La contrainte la plus saine est l'interdiction d'appliquer les dégâts aux HP / party dans l'éditeur : elle garde l'authoring et le runtime séparés.

Point à surveiller plus tard : le test principal `surface_to_gameplay_zone_action_test.dart` devient assez massif. Un futur lot de maintenance pourrait scinder les tests par comportement sans changer la logique métier.
