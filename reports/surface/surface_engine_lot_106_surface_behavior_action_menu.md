# Lot 106 — Surface Behavior Action Menu V0

## 1. Résumé exécutif honnête

Le Lot 106 remplace les deux actions comportementales visibles dans le Surface Painter par une entrée unique :

```text
Créer un comportement depuis cette surface
```

Cette entrée ouvre un `CupertinoActionSheet` court avec deux choix V0 :

```text
Herbe haute avec rencontres
Eau surfable
```

Chaque choix route vers le dialog métier existant, sans modifier la génération, l'assessment, le batch apply, les payloads ou le runtime. Tall grass continue d'ouvrir `SurfaceToGameplayZoneDialog` et water continue d'ouvrir `SurfableWaterSurfaceGameplayZoneDialog`.

Aucun comportement lava/ice/mud n'est codé.

## 2. Périmètre

Inclus :

- remplacement des boutons directs `Créer une zone de rencontre` et `Rendre cette eau surfable` dans la palette principale ;
- ajout d'un composant UI borné `SurfaceBehaviorActionMenu` ;
- routing vers les dialogs existants ;
- adaptation des tests widget Surface Painter ;
- relance des régressions éditeur, gameplay bridge et map_core ;
- rapport complet avec Evidence Pack.

Exclus :

- aucun modèle `map_core` ;
- aucun payload modifié ;
- aucune production `map_gameplay`, `map_runtime`, `map_battle` ;
- aucun nouveau comportement lava/ice/mud ;
- aucune refonte Surface Studio ;
- aucun assistant multi-step.

## 3. Gate 0 — status initial

Commande exécutée avant modification :

```text
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
find . -name AGENTS.md -print
```

Sortie initiale :

```text
## pwd
/Users/karim/Project/pokemonProject

## git branch --show-current
main

## git status --short --untracked-files=all
?? reports/surface/surface_engine_lot_105_surface_gameplay_bridge_closure_roadmap.md

## git diff --stat
(empty)

## git log --oneline -n 10
2305f276 lot 104: Surface Gameplay Bridge Runtime E2E Closure
8b5c3728 lot 103: Editor Generate Surfable Water Gameplay Zone from Surface
6a3db8e3 lot 101: Tall Grass Surface Workflow Hardening - Batch Apply
b224b0f6 fix: resolve RenderFlex overflow errors in layers and surface panels
888f1339 fix: resolve RenderFlex overflow errors in layers and surface panels
58ab7070 lot 100/95: Editor Generate Gameplay Zone from Surface
15fa925c lot 99/95: Surface Gameplay - Surface to Gameplay Zone Coverage Diagnostics
70b0f90d lot 98/95: Surface Gameplay - Surface to Gameplay Zone Generation Plan
8d62718f lot 97/95: Surface Gameplay - Surface to Gameplay Zone Authoring Workflow Spec
ac7984f2 lot 96/95: Surface Gameplay - Zones Bridge Decision Report

## find . -name AGENTS.md -print
./AGENTS.md
```

Changements préexistants :

- `reports/surface/surface_engine_lot_105_surface_gameplay_bridge_closure_roadmap.md` était déjà non suivi avant le Lot 106.

Changements du Lot 106 : voir sections fichiers créés/modifiés.

## 4. Context Mode usage

Context Mode a été utilisé pour :

- Gate 0 ;
- audits `rg` Surface Painter, dialogs/actions, patterns UI et tests ;
- exécution du test rouge ;
- exécution de la matrice tests/analyze ;
- conservation des sorties longues sans polluer la conversation.

Commandes d'audit lancées :

```text
rg -n "SurfacePainterPanel|SurfacePalettePanel|Créer une zone de rencontre|Rendre cette eau surfable|showCupertinoDialog|SurfaceToGameplayZoneDialog|SurfableWaterSurfaceGameplayZoneDialog|surface_to_gameplay_zone" packages/map_editor/lib packages/map_editor/test reports/surface
rg -n "CupertinoActionSheet|CupertinoAlertDialog|CupertinoButton|showCupertinoModalPopup|showCupertinoDialog|ActionSheet|Menu|behavior|Comportement|Créer un comportement" packages/map_editor/lib packages/map_editor/test
rg -n "surface_to_gameplay_zone_action|SurfacePainterPanel|Créer une zone de rencontre|Rendre cette eau surfable|SurfaceToGameplayZoneDialog|SurfableWaterSurfaceGameplayZoneDialog|find.text|tap" packages/map_editor/test
```

## 5. Audit Surface Painter actuel

Avant Lot 106, `SurfacePainterPanel` affichait dans le même `Wrap` :

- `Peindre Surface` ;
- `Effacer Surface` ;
- `Créer une zone de rencontre` ;
- `Rendre cette eau surfable`.

Les deux actions comportementales ouvraient directement leurs dialogs via `showCupertinoDialog`, puis appliquaient les plans avec :

- `applyTallGrassEncounterGameplayZonePlan(...)` ;
- `applySurfableWaterGameplayZonePlan(...)`.

Données nécessaires déjà disponibles dans le panel :

- `map` ;
- `generationLayer` ;
- `state.selectedSurfacePresetId` ;
- `presets` ;
- `state.project?.encounterTables` ;
- `notifier`.

Ce sont exactement les données passées au nouveau menu. Les dialogs et helpers métier restent inchangés.

## 6. Audit patterns UI

L'app utilise déjà fortement Cupertino : `CupertinoButton`, `CupertinoAlertDialog`, `showCupertinoDialog`, et des menus de choix via `showCupertinoModalPopup` + `CupertinoActionSheet` dans d'autres zones de l'éditeur.

Décision : utiliser `CupertinoActionSheet`.

Pourquoi :

- deux choix seulement en V0 ;
- action courte, pas un assistant ;
- pattern natif iOS/Cupertino déjà présent ;
- extensible plus tard pour lava/ice/mud ;
- évite de réécrire les dialogs métier.

## 7. Décision UX V0

La palette principale affiche désormais une action :

```text
Créer un comportement depuis cette surface
```

Le menu propose :

```text
Herbe haute avec rencontres
Eau surfable
Annuler
```

Les comportements futurs ne sont pas affichés en V0. Les afficher désactivés ajouterait du bruit sans fonctionnalité.

Le bouton reste désactivé si aucune map active n'existe. Si une map existe mais que la surface/preset/placement est invalide, le menu reste accessible et les dialogs existants affichent déjà les états bloqués.

## 8. Implémentation réalisée

Fichier créé :

- `packages/map_editor/lib/src/features/surface_painter/surface_behavior_action_menu.dart`

Fichiers modifiés :

- `packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart`
- `packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart`

Implémentation :

- `SurfaceBehaviorActionMenu` affiche le bouton unique ;
- `_openBehaviorMenu` affiche un `CupertinoActionSheet` ;
- `_openTallGrassDialog` ouvre le dialog tall grass existant ;
- `_openSurfableWaterDialog` ouvre le dialog water existant ;
- les helpers `applyTallGrassEncounterGameplayZonePlan` et `applySurfableWaterGameplayZonePlan` restent réutilisés.

## 9. Routing tall grass

Flux :

```text
Créer un comportement depuis cette surface
→ Herbe haute avec rencontres
→ SurfaceToGameplayZoneDialog
→ applyTallGrassEncounterGameplayZonePlan(...)
```

Le test vérifie que le choix ouvre :

```text
Créer une zone de rencontre depuis cette surface
```

et que le plan reste prêt à appliquer.

## 10. Routing water

Flux :

```text
Créer un comportement depuis cette surface
→ Eau surfable
→ SurfableWaterSurfaceGameplayZoneDialog
→ applySurfableWaterGameplayZonePlan(...)
```

Le test vérifie que le choix ouvre :

```text
Rendre cette eau surfable
```

et que le plan reste prêt à appliquer.

## 11. Tests lancés

Test rouge TDD :

```text
cd packages/map_editor && flutter test test/surface_painter/surface_to_gameplay_zone_action_test.dart --no-pub --reporter expanded
```

Résultat rouge attendu avant implémentation :

```text
exitCode: 1
Expected: exactly one matching candidate
Actual: Found 0 widgets with text "Créer un comportement depuis cette surface"
00:00 +14 -3: Some tests failed.
```

Tests de validation :

```text
cd packages/map_editor && flutter test test/surface_painter/surface_to_gameplay_zone_action_test.dart --no-pub --reporter expanded
cd packages/map_editor && flutter test test/surface_painter --no-pub --reporter expanded
cd packages/map_editor && flutter test test/map_selection_controller_test.dart --no-pub --reporter expanded
cd packages/map_gameplay && dart test test/surface_generated_gameplay_zone_bridge_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/movement_mode_water_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/surf_evaluation_test.dart --reporter expanded
cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_plan_test.dart --reporter expanded
cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_assessment_test.dart --reporter expanded
```

## 12. Résultats

```text
map_editor targeted action | exit 0 | 00:00 +16: EditorNotifier surfable water surface generation rejects movement plans that do not require surf without mutating / 00:00 +17: All tests passed!
map_editor surface_painter regression | exit 0 | 00:02 +58: surface_to_gameplay_zone_action_test.dart: EditorNotifier surfable water surface generation rejects movement plans that do not require surf without mutating / 00:02 +59: All tests passed!
map_editor map_selection regression | exit 0 | 00:00 +4: MapSelectionController surface paint is compatible only with SurfaceLayer / 00:00 +5: All tests passed!
map_gameplay bridge E2E | exit 0 | 00:00 +2: surface generated gameplay zone bridge generated tall grass encounter zones are consumed by encounters / 00:00 +3: All tests passed!
map_gameplay movement_mode_water | exit 0 | 00:00 +5: movement mode water traversal movement zone requiring surf is treated as water for walking mode / 00:00 +6: All tests passed!
map_gameplay surf_evaluation | exit 0 | 00:00 +11: partyHasUsableFieldMove returns false for empty party / 00:00 +12: All tests passed!
map_core generation_plan | exit 0 | 00:00 +15: diagnostics and immutability coverage and diagnostics support value equality / 00:00 +16: All tests passed!
map_core generation_assessment | exit 0 | 00:00 +11: assessment messages and immutability assessment messages and assessment support value equality / 00:00 +12: All tests passed!
```

`git diff --check` : exit 0, aucune sortie.

## 13. Analyse lancée

Commande :

```text
cd packages/map_editor && flutter analyze lib/src/features/surface_painter/surface_behavior_action_menu.dart lib/src/features/surface_painter/surface_palette_panel.dart test/surface_painter/surface_to_gameplay_zone_action_test.dart
```

## 14. Résultats analyze

```text
map_editor targeted analyze | exit 0 | Analyzing 3 items... / No issues found! (ran in 1.5s)
```

## 15. Fichiers créés

- `packages/map_editor/lib/src/features/surface_painter/surface_behavior_action_menu.dart`
- `reports/surface/surface_engine_lot_106_surface_behavior_action_menu.md`

## 16. Fichiers modifiés

- `packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart`
- `packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart`

## 17. Fichiers supprimés

Aucun fichier supprimé.

## 18. Contenu complet des fichiers créés

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
}

```


### `reports/surface/surface_engine_lot_106_surface_behavior_action_menu.md`

Le présent rapport est le second fichier créé par le Lot 106. Conformément à l'exception explicite du prompt, il ne se recopie pas récursivement dans lui-même.

## 19. Contenu complet des fichiers modifiés

### `packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../editor/state/editor_notifier.dart';
import '../editor/tools/editor_tool.dart';
import 'surface_catalog_availability.dart';
import 'surface_behavior_action_menu.dart';
import '../../ui/shared/cupertino_editor_widgets.dart';

/// Minimal Surface palette for map placement authoring.
///
/// The palette intentionally selects a `ProjectSurfacePreset.id`, not an atlas
/// or animation id. The map placement model stores only `surfacePresetId`; frame
/// resolution, autotile roles and visual preview are future Surface Engine lots.
class SurfacePalettePanel extends StatelessWidget {
  const SurfacePalettePanel({
    super.key,
    required this.availability,
    required this.presets,
    required this.selectedSurfacePresetId,
    required this.onPresetSelected,
    this.onOpenSurfaceStudio,
  });

  final SurfaceCatalogAvailability availability;
  final List<ProjectSurfacePreset> presets;
  final String? selectedSurfacePresetId;
  final ValueChanged<String> onPresetSelected;
  final VoidCallback? onOpenSurfaceStudio;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Surfaces',
          style: TextStyle(
            color: label,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        _SurfaceCatalogCounts(availability: availability),
        const SizedBox(height: 8),
        Text(
          availability.primaryMessage,
          style: TextStyle(
            color: availability.canPaint ? subtle : label,
            fontSize: 13,
            fontWeight:
                availability.canPaint ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          availability.secondaryMessage,
          style: TextStyle(color: subtle, fontSize: 12),
        ),
        if (presets.isEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Les presets sont les surfaces que vous pouvez peindre sur la map.',
            style: TextStyle(color: subtle, fontSize: 12),
          ),
          if (onOpenSurfaceStudio != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                onPressed: onOpenSurfaceStudio,
                child: Text(availability.recommendedActionLabel),
              ),
            ),
          ],
        ] else ...[
          const SizedBox(height: 10),
          Text(
            'Sélectionner une surface',
            style: TextStyle(color: subtle, fontSize: 12),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < presets.length; i++) ...[
            _SurfacePresetTile(
              preset: presets[i],
              selected: presets[i].id == selectedSurfacePresetId,
              onSelected: onPresetSelected,
            ),
            if (i < presets.length - 1) const SizedBox(height: 6),
          ],
        ],
      ],
    );
  }
}

/// Small editor-facing wrapper that wires the palette to `EditorNotifier`.
///
/// It creates/selects a SurfaceLayer as an authoring target but still does not
/// render the resulting placements. In Lot 84 the visible map remains unchanged;
/// the saved map data gains sparse SurfaceCellPlacement entries.
class SurfacePainterPanel extends ConsumerWidget {
  const SurfacePainterPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = state.activeMap;
    final catalog = state.project?.surfaceCatalog ?? ProjectSurfaceCatalog();
    final availability = SurfaceCatalogAvailability.fromCatalog(catalog);
    final presets =
        state.project?.surfaceCatalog.presets ?? const <ProjectSurfacePreset>[];
    final surfaceLayers =
        map?.layers.whereType<SurfaceLayer>().toList(growable: false) ??
            const <SurfaceLayer>[];
    final activeLayer = _activeSurfaceLayer(map, state.activeLayerId);
    final generationLayer =
        activeLayer ?? (surfaceLayers.length == 1 ? surfaceLayers.first : null);
    final canPaint = map != null &&
        availability.canPaint &&
        (state.selectedSurfacePresetId?.trim().isNotEmpty ?? false);
    final subtle = EditorChrome.subtleLabel(context);

    final content = Padding(
      padding: EdgeInsets.all(embedded ? 0 : 10),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SurfaceLayerTargetBlock(
              surfaceLayers: surfaceLayers,
              activeLayer: activeLayer,
              onSelect: notifier.setActiveLayer,
              onCreate: () => notifier.activateFirstSurfaceLayer(
                createIfMissing: true,
              ),
            ),
            const SizedBox(height: 12),
            SurfacePalettePanel(
              availability: availability,
              presets: presets,
              selectedSurfacePresetId: state.selectedSurfacePresetId,
              onPresetSelected: notifier.selectSurfacePreset,
              onOpenSurfaceStudio: notifier.selectSurfaceStudioWorkspace,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                CupertinoButton.filled(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  onPressed: canPaint ? notifier.selectSurfacePaintMode : null,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.paintbrush, size: 16),
                      SizedBox(width: 6),
                      Text('Peindre Surface'),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  onPressed: activeLayer == null
                      ? null
                      : () => notifier.selectTool(EditorToolType.eraser),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.delete_left, size: 16),
                      SizedBox(width: 6),
                      Text('Effacer Surface'),
                    ],
                  ),
                ),
                SurfaceBehaviorActionMenu(
                  map: map,
                  surfaceLayer: generationLayer,
                  surfacePresetId: state.selectedSurfacePresetId,
                  presets: presets,
                  encounterTables: state.project?.encounterTables ?? const [],
                  notifier: notifier,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _statusLine(
                activeLayer: activeLayer,
                hasSurfaceLayer: surfaceLayers.isNotEmpty,
                presetSelected:
                    state.selectedSurfacePresetId?.trim().isNotEmpty ?? false,
                availability: availability,
              ),
              style: TextStyle(color: subtle, fontSize: 12),
            ),
          ],
        ),
      ),
    );

    if (embedded) {
      return content;
    }
    return Container(
      decoration: BoxDecoration(color: EditorChrome.islandFill(context)),
      child: content,
    );
  }

  SurfaceLayer? _activeSurfaceLayer(MapData? map, String? activeLayerId) {
    if (map == null || activeLayerId == null) {
      return null;
    }
    for (final layer in map.layers) {
      if (layer.id == activeLayerId && layer is SurfaceLayer) {
        return layer;
      }
    }
    return null;
  }

  String _statusLine({
    required SurfaceLayer? activeLayer,
    required bool hasSurfaceLayer,
    required bool presetSelected,
    required SurfaceCatalogAvailability availability,
  }) {
    if (!availability.canPaint) {
      if (hasSurfaceLayer) {
        return 'Un calque Surface existe, mais aucune surface n’est encore peignable.';
      }
      return availability.secondaryMessage;
    }
    if (!presetSelected) {
      return 'Sélectionnez une surface, puis peignez sur la map.';
    }
    if (activeLayer == null) {
      return 'Le premier clic créera un calque Surface automatiquement.';
    }
    return 'Calque actif : ${activeLayer.name}';
  }
}

class _SurfaceCatalogCounts extends StatelessWidget {
  const _SurfaceCatalogCounts({
    required this.availability,
  });

  final SurfaceCatalogAvailability availability;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catalogue Surface :',
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _SurfaceCatalogCount(
              label: 'Atlas',
              value: availability.atlasCount,
            ),
            _SurfaceCatalogCount(
              label: 'Animations',
              value: availability.animationCount,
            ),
            _SurfaceCatalogCount(
              label: 'Presets',
              value: availability.presetCount,
            ),
          ],
        ),
      ],
    );
  }
}

class _SurfaceCatalogCount extends StatelessWidget {
  const _SurfaceCatalogCount({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return Text(
      '$label : $value',
      style: TextStyle(color: subtle, fontSize: 12),
    );
  }
}

class _SurfacePresetTile extends StatelessWidget {
  const _SurfacePresetTile({
    required this.preset,
    required this.selected,
    required this.onSelected,
  });

  final ProjectSurfacePreset preset;
  final bool selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    const accent = EditorChrome.inspectorJoyCyan;

    return CupertinoButton(
      key: Key('surface-palette-preset-${preset.id}'),
      padding: EdgeInsets.zero,
      onPressed: () => onSelected(preset.id),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.16)
              : EditorChrome.elevatedPanelBackground(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? accent : EditorChrome.separator(context),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              preset.name,
              style: TextStyle(
                color: label,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'ID : ${preset.id}',
              style: TextStyle(color: subtle, fontSize: 12),
            ),
            if (selected) ...[
              const SizedBox(height: 5),
              const Text(
                'Surface sélectionnée',
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SurfaceLayerTargetBlock extends StatelessWidget {
  const _SurfaceLayerTargetBlock({
    required this.surfaceLayers,
    required this.activeLayer,
    required this.onSelect,
    required this.onCreate,
  });

  final List<SurfaceLayer> surfaceLayers;
  final SurfaceLayer? activeLayer;
  final ValueChanged<String> onSelect;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Calque Surface',
                style: TextStyle(
                  color: label,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              onPressed: onCreate,
              child: const Text('Créer'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (surfaceLayers.isEmpty)
          Text(
            'Aucun calque Surface',
            style: TextStyle(color: subtle, fontSize: 12),
          )
        else
          for (final layer in surfaceLayers)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => onSelect(layer.id),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${layer.name} — ${layer.placements.length} placement(s)',
                  style: TextStyle(
                    color: layer.id == activeLayer?.id
                        ? EditorChrome.inspectorJoyCyan
                        : label,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
      ],
    );
  }
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


## 20. Git status final

Statut final :

```text
 M packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart
 M packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart
?? packages/map_editor/lib/src/features/surface_painter/surface_behavior_action_menu.dart
?? reports/surface/surface_engine_lot_105_surface_gameplay_bridge_closure_roadmap.md
?? reports/surface/surface_engine_lot_106_surface_behavior_action_menu.md
```

Diff stat final :

```text
.../surface_painter/surface_palette_panel.dart     | 85 ++--------------------
.../surface_to_gameplay_zone_action_test.dart      | 62 ++++++++++++++--
2 files changed, 62 insertions(+), 85 deletions(-)
```

Note : `reports/surface/surface_engine_lot_105_surface_gameplay_bridge_closure_roadmap.md` est un changement préexistant au Lot 106.

## 21. Périmètre explicitement non touché

Confirmé :

- `map_core` production non modifié ;
- `map_gameplay` production non modifié ;
- `map_runtime` production non modifié ;
- `map_battle` non modifié ;
- `MapData` modèle non modifié ;
- `MapGameplayZone` modèle non modifié ;
- `MovementZonePayload` non modifié ;
- `EncounterZonePayload` non modifié ;
- `SurfaceLayer` non modifié ;
- `SurfaceCellPlacement` non modifié ;
- `ProjectManifest` non modifié ;
- `surface.dart` non modifié ;
- `surface_catalog.dart` non modifié ;
- `map_layer.dart` non modifié ;
- `map_gameplay_zone_payloads.dart` non modifié ;
- aucun JSON ;
- aucun generated/build_runner ;
- aucun runtime surf codé ;
- aucun encounter surf codé ;
- aucun lava / ice / mud codé ;
- aucune migration legacy ;
- aucun filtre `surfacePresetId` dans `MapGameplayZone` ;
- aucune nouvelle logique gameplay.

## 22. ctx stats

Commande demandée :

```text
ctx stats
```

Résultat shell :

```text
zsh:1: command not found: ctx
```

Les outils MCP Context Mode sont disponibles et ont été utilisés. Diagnostic MCP :

```text
context-mode doctor
- Runtimes: 7/11 (64%) — javascript, shell, python, ruby, rust, php, perl
- Performance: NORMAL — install Bun for 3-5x speed boost
- Server test: PASS
- FTS5 / SQLite: PASS — native module works
- Hook script: PASS — /opt/homebrew/lib/node_modules/context-mode/hooks/pretooluse.mjs
- Version: v1.0.100
```

Stats compactes observées :

```text
Gate 0: sortie capturée via Context Mode.
Audit Lot 106: 4 commandes, 2478 lignes, 332.8KB indexés, 7 sections indexées, 4 requêtes.
Test rouge: sortie longue indexée, puis synthèse compacte confirmant exit 1.
Tests/analyze: sorties longues indexées, puis synthèse compacte des 9 commandes.
```

## 23. Limites restantes

- Le menu V0 reste textuel et court ; pas encore de cartes comportement riches.
- Lava/ice/mud ne sont pas affichés, même désactivés, pour éviter le bruit V0.
- Les dialogs métier restent séparés ; une factorisation plus large attend plus de comportements réels.
- Pas de preview graphique de coverage.
- Pas de validation automatique qu'un preset water est vraiment de l'eau.

## 24. Auto-critique

- Est-ce que l'entrée unique "Créer un comportement depuis cette surface" existe ? Oui.
- Est-ce que les anciens boutons séparés sont retirés de la surface principale ? Oui.
- Est-ce que le menu propose Herbe haute avec rencontres ? Oui.
- Est-ce que le menu propose Eau surfable ? Oui.
- Est-ce que le routing tall grass ouvre le dialog existant ? Oui.
- Est-ce que le routing water ouvre le dialog existant ? Oui.
- Est-ce que les helpers métier existants sont réutilisés ? Oui.
- Est-ce que tall grass reste fonctionnel ? Oui.
- Est-ce que water/surf reste fonctionnel ? Oui.
- Est-ce qu'aucun nouveau comportement lava/ice/mud n'est codé ? Oui.
- Est-ce qu'aucun modèle n'est modifié ? Oui.
- Est-ce que les tests ciblés passent ? Oui.
- Est-ce que les régressions Surface Painter passent ? Oui.
- Est-ce que les régressions gameplay bridge passent ? Oui.
- Est-ce que l'analyse ciblée passe ? Oui.
- Est-ce que Context Mode a été utilisé agressivement ? Oui.
- Est-ce que ctx stats est inclus ? Oui, avec mention explicite que le binaire shell est absent.
- Est-ce que le contenu complet des fichiers créés/modifiés est copié dans le rapport ? Oui, sauf exception anti-récursion pour le présent rapport.
- Est-ce qu'un Lot 106-bis est nécessaire ? Non. Le lot atteint son objectif sans changer la logique métier.

## 25. Regard critique sur le prompt

Le prompt est bien cadré : il impose une amélioration UX réelle sans ouvrir lava/ice/mud ni refaire un assistant. La contrainte de conserver les dialogs existants évite une refonte inutile.

Le seul point de tension est l'Evidence Pack complet dans un lot UI : recopier les fichiers modifiés rend le rapport long, mais utile pour revue hors Context Mode. La solution retenue garde le rapport exhaustif tout en évitant la récursion du rapport lui-même.
