# Lot 103 — Editor Generate Surfable Water Gameplay Zone from Surface V0

## 1. Résumé exécutif honnête

Le Lot 103 ajoute l'action éditeur V0 `Rendre cette eau surfable` dans le Surface Painter. L'action prend la surface peinte sélectionnée, génère un plan Surface -> GameplayZone avec `greedyRectangles`, évalue ce plan avec l'assessment des Lots 98/99, affiche une confirmation textuelle, puis applique les zones via le batch apply existant du Lot 101.

Le payload généré est strictement celui décidé au Lot 102 : `MapGameplayZone(kind: GameplayZoneKind.movement)` avec `MovementZonePayload(requiredMode: MovementMode.surf)`. `allowedModes` n'est pas utilisé par le presenter V0. Les zones couvrent les cellules water peintes elles-mêmes. Aucun runtime surf, aucun modèle `MapGameplayZone`, aucun `SurfaceLayer`, aucun JSON et aucune rencontre surf ne sont modifiés.

La dette précondition `movement_mode_water_test.dart` a été confirmée puis corrigée uniquement dans les fixtures de test en ajoutant `surfaceCatalog: ProjectSurfaceCatalog()` aux deux `ProjectManifest` concernés.

## 2. Périmètre

Inclus :

- action Surface Painter `Rendre cette eau surfable` ;
- preview/presenter water spécifique ;
- dialog textuel V0 water ;
- helper d'application `applySurfableWaterGameplayZonePlan` ;
- application batch via `EditorNotifier.applyGeneratedGameplayZones` ;
- tests presenter/dialog/panel/application/non-mutation ;
- correction fixture de test `movement_mode_water_test.dart`.

Exclus et respecté :

- pas de runtime surf ;
- pas de modification `MapGameplayZone` ;
- pas de modification `MovementZonePayload` ;
- pas de modification `SurfaceLayer` / `SurfaceCellPlacement` ;
- pas d'encounter surf ;
- pas de lava / ice / mud ;
- pas de JSON / build_runner / migration legacy.

## 3. Gate 0 — status initial

Commandes exécutées avant modification :

```text
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
find .. -name AGENTS.md -print
```

Sorties :

```text
PWD
/Users/karim/Project/pokemonProject

BRANCH
main

STATUS
?? reports/surface/surface_engine_lot_102_surfable_water_from_surface_workflow_decision.md

DIFF_STAT
(no output)

LOG
6a3db8e3 lot 101: Tall Grass Surface Workflow Hardening - Batch Apply
b224b0f6 fix: resolve RenderFlex overflow errors in layers and surface panels
888f1339 fix: resolve RenderFlex overflow errors in layers and surface panels
58ab7070 lot 100/95: Editor Generate Gameplay Zone from Surface
15fa925c lot 99/95: Surface Gameplay - Surface to Gameplay Zone Coverage Diagnostics
70b0f90d lot 98/95: Surface Gameplay - Surface to Gameplay Zone Generation Plan
8d62718f lot 97/95: Surface Gameplay - Surface Gameplay Zone Authoring Workflow Spec
ac7984f2 lot 96/95: Surface Gameplay - Zones Bridge Decision Report
a4d62f39 lot 94/95: Surface Gameplay
83654389 feat: add surface runtime test files and golden slice reports

AGENTS
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Le `AGENTS.md` pertinent est celui de `/Users/karim/Project/pokemonProject`. Aucun `AGENTS.md` plus profond dans le repo n'a été trouvé.

Changements préexistants :

```text
?? reports/surface/surface_engine_lot_102_surfable_water_from_surface_workflow_decision.md
```

Changements du Lot 103 : les six fichiers modifiés listés plus bas et le rapport Lot 103.

## 4. Context Mode usage

Context Mode MCP a été utilisé pour :

- Gate 0 ;
- audits repository-wide ;
- sorties de tests ;
- sorties analyzer ;
- diagnostic du RED et des échecs intermédiaires ;
- `ctx_stats`.

Note d'exécution : le binaire shell `ctx` n'est pas disponible dans cette session (`zsh:1: command not found: ctx`, observé au Lot 102). Les statistiques ci-dessous proviennent donc de l'outil MCP Context Mode `ctx_stats`.

```text
1.5M tokens saved · 88.2% reduction · 3h 17m
Without context-mode: 6.5 MB
With context-mode: 782.6 KB
5.7 MB kept out of your conversation
143 calls
ctx_batch_execute: 32 calls, 4.9 MB saved
ctx_execute: 63 calls, 502.1 KB saved
ctx_search: 8 calls, 233.2 KB saved
ctx_stats: 14 calls, 79.0 KB saved
ctx_index: 20 calls, 27.6 KB saved
ctx_doctor: 5 calls, 13.4 KB saved
ctx_upgrade: 1 call, 3.7 KB saved
version: v1.0.100
update available: v1.0.100 -> v1.0.103
```

## 5. Précondition movement_mode_water_test

Commande lancée au début du lot :

```text
cd packages/map_gameplay && dart test test/movement_mode_water_test.dart --reporter expanded
```

Résultat initial :

```text
test/movement_mode_water_test.dart:152:31: Error: Required named parameter 'surfaceCatalog' must be provided.
test/movement_mode_water_test.dart:171:31: Error: Required named parameter 'surfaceCatalog' must be provided.
EXIT_CODE=1
```

Correction réalisée : uniquement dans `packages/map_gameplay/test/movement_mode_water_test.dart`, ajout de `surfaceCatalog: ProjectSurfaceCatalog()` aux deux fixtures `ProjectManifest`. La production `map_gameplay` n'a pas été modifiée.

Résultat après correction :

```text
00:00 +6: All tests passed!
EXIT_CODE=0
```

## 6. Audit tall grass workflow

Commandes d'audit :

```text
rg -n "TallGrass|Encounter|applyTallGrassEncounterGameplayZonePlan|buildTallGrassEncounterSurfaceGameplayZonePreview|SurfaceToGameplayZoneDialog|Créer une zone de rencontre|surface_to_gameplay_zone" packages/map_editor/lib packages/map_editor/test reports/surface
sed -n '1,260p' packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_presenter.dart
sed -n '1,280p' packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_dialog.dart
sed -n '1,240p' packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_action.dart
sed -n '130,240p' packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart
sed -n '1,380p' packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart
```

Findings :

- Le workflow tall grass utilisait déjà `createSurfaceGameplayZoneGenerationPlan`, `assessSurfaceGameplayZoneGenerationPlan`, `greedyRectangles`, un dialog textuel, et le batch apply Lot 101.
- `applyTallGrassEncounterGameplayZonePlan` valide toutes les zones avant d'appeler `EditorNotifier.applyGeneratedGameplayZones`, ce qui évite les mutations partielles.
- Le batch apply est réutilisable pour water car il accepte déjà des `MapGameplayZone` candidates complètes.
- Le presenter tall grass reste spécifique à `EncounterZonePayload` / `EncounterKind.walk` / `encounterTableId`.
- Le Lot 103 garde donc un presenter/dialog water spécifique, sans généraliser prématurément les deux workflows.

## 7. Audit surf / movement / GameplayWorldState

Commandes d'audit :

```text
rg -n "MovementZonePayload|MovementMode.surf|allowedModes|requiredMode|GameplayZoneKind.movement|evaluateSurfAttempt|GameplayWorldState|waterCell|isWaterCell|waterRequiresSurf|setPlayerMovementMode|EncounterKind.surf" packages/map_core/lib packages/map_core/test packages/map_gameplay/lib packages/map_gameplay/test packages/map_runtime/lib packages/map_runtime/test
sed -n '1,230p' packages/map_gameplay/test/movement_mode_water_test.dart
```

Findings :

- `MovementZonePayload` possède `requiredMode` et `allowedModes`, mais l'éditeur expose déjà surtout `requiredMode`.
- `GameplayWorldState` traite une zone movement comme water si `requiredMode == MovementMode.surf` ou si `allowedModes` contient surf.
- `evaluateSurfAttempt` ne lit pas directement les zones ; il reçoit `isTargetWater` après détection par le world/runtime.
- Le choix V0 reste donc `MovementZonePayload(requiredMode: MovementMode.surf)`.
- La zone doit couvrir les cellules water elles-mêmes : le runtime bloque l'entrée dans la cellule water cible, puis déclenche le flow Surf.

## 8. Décision UX V0

Libellé retenu : `Rendre cette eau surfable`.

Pourquoi : ce libellé exprime l'intention utilisateur no-code. `Créer une zone Surf` est plus technique et parle déjà en termes de zone interne.

Le Surface Painter affiche désormais deux actions distinctes :

- `Créer une zone de rencontre` pour tall grass / encounter ;
- `Rendre cette eau surfable` pour water / movement surf.

Le dialog V0 reste textuel, sans preview graphique et sans assistant multi-step.

## 9. Design technique

Briques ajoutées :

- `SurfableWaterSurfaceGameplayZonePreview` ;
- `buildSurfableWaterSurfaceGameplayZonePreview(...)` ;
- `SurfableWaterSurfaceGameplayZoneDialog` ;
- `applySurfableWaterGameplayZonePlan(...)`.

Briques réutilisées :

- `SurfaceGameplayZoneGenerationSource` ;
- `SurfaceGameplayZoneBehaviorDraft.movement(...)` ;
- `createSurfaceGameplayZoneGenerationPlan(...)` ;
- `SurfaceGameplayZoneGenerationStrategy.greedyRectangles` ;
- `assessSurfaceGameplayZoneGenerationPlan(...)` ;
- `EditorNotifier.applyGeneratedGameplayZones(...)`.

Aucune extraction générique large n'a été faite : tall grass et water restent deux workflows courts, lisibles et bornés.

## 10. Source de génération

La source water V0 utilise :

- map active ;
- SurfaceLayer actif ou unique fourni par le panel ;
- `selectedSurfacePresetId` ;
- placements du `SurfaceLayer` filtrés par `surfacePresetId` ;
- preset correspondant dans le catalogue Surface.

Cas bloquants gérés :

- aucune map ;
- aucun calque Surface ;
- aucun preset sélectionné ;
- preset absent du catalogue ;
- aucune cellule peinte pour ce preset.

Le code ne tente pas de deviner automatiquement que le preset est vraiment water. C'est volontaire : `ProjectSurfacePreset` reste visuel et ne porte pas de gameplay kind.

## 11. Payload movement/surf

Payload V0 généré :

```dart
const SurfaceGameplayZoneBehaviorDraft.movement(
  MovementZonePayload(requiredMode: MovementMode.surf),
)
```

Ce draft produit des `MapGameplayZone` de type :

```dart
GameplayZoneKind.movement
MovementZonePayload(requiredMode: MovementMode.surf)
```

`allowedModes` n'est pas renseigné par le presenter V0. Aucune `EncounterZonePayload` et aucun `EncounterKind.surf` ne sont créés par ce workflow.

## 12. Dialog / confirmation UI

Dialog ajouté : `SurfableWaterSurfaceGameplayZoneDialog`.

Contenu :

- titre `Rendre cette eau surfable` ;
- surface source ;
- nombre de cellules ;
- mode `Surf` ;
- nombre de zones prévues ;
- résumé assessment ;
- messages assessment ;
- couverture / hors surface si assessment disponible.

Boutons :

- `Annuler` ;
- `Créer la zone Surf`.

Règle : le bouton de confirmation est actif si le plan est `ready` ou `needsReview`, et désactivé si le plan est `blocked`.

## 13. Application MapGameplayZone movement/surf

Helper ajouté : `applySurfableWaterGameplayZonePlan(...)`.

Règles :

- refuse un plan vide ;
- refuse toute zone non `GameplayZoneKind.movement` ;
- refuse toute zone movement sans payload ;
- refuse toute zone dont `movement.requiredMode != MovementMode.surf` ;
- applique toutes les zones en batch via `EditorNotifier.applyGeneratedGameplayZones(...)` ;
- sélectionne la première zone générée ;
- ne modifie pas les `SurfaceLayer`.

Les tests couvrent l'absence de mutation partielle pour plan non movement et pour movement non surf.

## 14. Tests lancés

Commandes lancées :

```text
cd packages/map_editor && flutter test test/surface_painter/surface_to_gameplay_zone_action_test.dart --no-pub --reporter expanded
cd packages/map_editor && flutter test test/surface_painter --no-pub --reporter expanded
cd packages/map_editor && flutter test test/map_selection_controller_test.dart --no-pub --reporter expanded
cd packages/map_gameplay && dart test test/movement_mode_water_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/surf_evaluation_test.dart --reporter expanded
cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_plan_test.dart --reporter expanded
cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_assessment_test.dart --reporter expanded
git diff --check
```

## 15. Résultats

```text
RED initial editor test:
00:00 +0 -1: Some tests failed.
Compilation failed because buildSurfableWaterSurfaceGameplayZonePreview, SurfableWaterSurfaceGameplayZoneDialog, and applySurfableWaterGameplayZonePlan did not exist yet.
EXIT_CODE=1

Precondition movement_mode_water_test before fixture fix:
test/movement_mode_water_test.dart:152:31: Error: Required named parameter 'surfaceCatalog' must be provided.
test/movement_mode_water_test.dart:171:31: Error: Required named parameter 'surfaceCatalog' must be provided.
EXIT_CODE=1

Final targeted editor test:
00:00 +16: All tests passed!
EXIT_CODE=0

Final Surface Painter regression:
00:02 +58: All tests passed!
EXIT_CODE=0

Final map selection regression:
00:00 +5: All tests passed!
EXIT_CODE=0

Final movement_mode_water_test:
00:00 +6: All tests passed!
EXIT_CODE=0

Final surf_evaluation_test:
00:00 +12: All tests passed!
EXIT_CODE=0

Final map_core generation plan:
00:00 +16: All tests passed!
EXIT_CODE=0

Final map_core assessment:
00:00 +12: All tests passed!
EXIT_CODE=0

Final git diff check:
EXIT_CODE=0
```

## 16. Analyse lancée

Commandes lancées :

```text
cd packages/map_editor && flutter analyze lib/src/features/surface_painter/surface_to_gameplay_zone_action.dart lib/src/features/surface_painter/surface_to_gameplay_zone_dialog.dart lib/src/features/surface_painter/surface_to_gameplay_zone_presenter.dart lib/src/features/surface_painter/surface_palette_panel.dart test/surface_painter/surface_to_gameplay_zone_action_test.dart
cd packages/map_gameplay && dart analyze test/movement_mode_water_test.dart
```

## 17. Résultats analyze

```text
map_editor targeted analyze:
Analyzing 5 items...
No issues found! (ran in 1.6s)
EXIT_CODE=0

map_gameplay test analyze:
Analyzing movement_mode_water_test.dart...
No issues found!
EXIT_CODE=0
```

Une première passe analyze `map_editor` a signalé `prefer_const_constructors` sur `_InfoLine(label: 'Mode', value: 'Surf')`. La ligne a été corrigée en `const _InfoLine(...)`, puis l'analyse ciblée est passée.

## 18. Fichiers créés

```text
reports/surface/surface_engine_lot_103_editor_generate_surfable_water_gameplay_zone_from_surface.md
```

## 19. Fichiers modifiés

```text
packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart
packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_action.dart
packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_dialog.dart
packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_presenter.dart
packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart
packages/map_gameplay/test/movement_mode_water_test.dart
```

## 20. Fichiers supprimés

```text
Aucun.
```

## 21. Contenu complet des fichiers créés

Le seul fichier créé par ce lot est le présent rapport. Il n'est pas recopié ici afin d'éviter une récursion infinie, conformément à l'exception prévue par le prompt.

## 22. Contenu complet des fichiers modifiés

### `packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../editor/state/editor_notifier.dart';
import '../editor/tools/editor_tool.dart';
import 'surface_catalog_availability.dart';
import 'surface_to_gameplay_zone_action.dart';
import 'surface_to_gameplay_zone_dialog.dart';
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
                CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  onPressed: map == null
                      ? null
                      : () async {
                          final plan = await showCupertinoDialog<
                              SurfaceGameplayZoneGenerationPlan>(
                            context: context,
                            builder: (dialogContext) {
                              return SurfaceToGameplayZoneDialog(
                                map: map,
                                surfaceLayer: generationLayer,
                                surfacePresetId: state.selectedSurfacePresetId,
                                presets: presets,
                                encounterTables:
                                    state.project?.encounterTables ?? const [],
                                onConfirm: (plan) =>
                                    Navigator.of(dialogContext).pop(plan),
                              );
                            },
                          );
                          if (plan == null) return;
                          applyTallGrassEncounterGameplayZonePlan(
                            notifier: notifier,
                            plan: plan,
                          );
                        },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.add_circled, size: 16),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text('Créer une zone de rencontre'),
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  onPressed: map == null
                      ? null
                      : () async {
                          final plan = await showCupertinoDialog<
                              SurfaceGameplayZoneGenerationPlan>(
                            context: context,
                            builder: (dialogContext) {
                              return SurfableWaterSurfaceGameplayZoneDialog(
                                map: map,
                                surfaceLayer: generationLayer,
                                surfacePresetId: state.selectedSurfacePresetId,
                                presets: presets,
                                onConfirm: (plan) =>
                                    Navigator.of(dialogContext).pop(plan),
                              );
                            },
                          );
                          if (plan == null) return;
                          applySurfableWaterGameplayZonePlan(
                            notifier: notifier,
                            plan: plan,
                          );
                        },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.drop, size: 16),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text('Rendre cette eau surfable'),
                      ),
                    ],
                  ),
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

  group('SurfacePainterPanel action entry', () {
    testWidgets('opens the encounter generation dialog from the surface panel',
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

      expect(find.text('Créer une zone de rencontre'), findsOneWidget);

      await tester.tap(find.text('Créer une zone de rencontre'));
      await tester.pumpAndSettle();

      expect(
        find.text('Créer une zone de rencontre depuis cette surface'),
        findsOneWidget,
      );
      expect(find.text('Plan prêt à appliquer'), findsOneWidget);
    });

    testWidgets('opens the surfable water generation dialog from the panel',
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

      expect(find.text('Rendre cette eau surfable'), findsOneWidget);

      await tester.tap(find.text('Rendre cette eau surfable'));
      await tester.pumpAndSettle();

      expect(find.text('Rendre cette eau surfable'), findsWidgets);
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

### `packages/map_gameplay/test/movement_mode_water_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('movement mode water traversal', () {
    test('walking can move on regular ground', () {
      final world = GameplayWorldState.initial(
        map: _baseMap(
          includeWaterPath: false,
          includeCollisionAtTarget: false,
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: _projectWithWaterPreset(),
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(result, isA<Moved>());
      expect(result.world.player.pos, const GridPos(x: 1, y: 0));
    });

    test('walking can move on non-water path surface kinds', () {
      final world = GameplayWorldState.initial(
        map: _baseMap(
          includeWaterPath: true,
          includeCollisionAtTarget: false,
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: _projectWithRoadPreset(),
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(result, isA<Moved>());
      expect(result.world.player.pos, const GridPos(x: 1, y: 0));
    });

    test('walking is blocked on water path cells with explicit reason', () {
      final world = GameplayWorldState.initial(
        map: _baseMap(
          includeWaterPath: true,
          includeCollisionAtTarget: false,
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: _projectWithWaterPreset(),
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(result, isA<Blocked>());
      final blocked = result as Blocked;
      expect(blocked.reason, GameplayMovementBlockReason.waterRequiresSurf);
      expect(blocked.world.player.pos, const GridPos(x: 0, y: 0));
    });

    test('surfing can move on water path cells', () {
      final world = GameplayWorldState.initial(
        map: _baseMap(
          includeWaterPath: true,
          includeCollisionAtTarget: false,
        ),
        playerPos: const GridPos(x: 0, y: 0),
        playerMovementMode: MovementMode.surf,
        project: _projectWithWaterPreset(),
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(result, isA<Moved>());
      expect(result.world.player.pos, const GridPos(x: 1, y: 0));
    });

    test('solid collisions still block movement while surfing', () {
      final world = GameplayWorldState.initial(
        map: _baseMap(
          includeWaterPath: true,
          includeCollisionAtTarget: true,
        ),
        playerPos: const GridPos(x: 0, y: 0),
        playerMovementMode: MovementMode.surf,
        project: _projectWithWaterPreset(),
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(result, isA<Blocked>());
      final blocked = result as Blocked;
      expect(blocked.reason, GameplayMovementBlockReason.solid);
      expect(blocked.world.player.pos, const GridPos(x: 0, y: 0));
    });

    test('movement zone requiring surf is treated as water for walking mode',
        () {
      final map = _baseMap(
        includeWaterPath: false,
        includeCollisionAtTarget: false,
      ).copyWith(
        gameplayZones: const [
          MapGameplayZone(
            id: 'surf_zone',
            kind: GameplayZoneKind.movement,
            area: MapRect(
                pos: GridPos(x: 1, y: 0), size: GridSize(width: 1, height: 1)),
            movement: MovementZonePayload(requiredMode: MovementMode.surf),
          ),
        ],
      );
      final world = GameplayWorldState.initial(
        map: map,
        playerPos: const GridPos(x: 0, y: 0),
        project: _projectWithWaterPreset(),
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(result, isA<Blocked>());
      final blocked = result as Blocked;
      expect(blocked.reason, GameplayMovementBlockReason.waterRequiresSurf);
    });
  });
}

MapData _baseMap({
  required bool includeWaterPath,
  required bool includeCollisionAtTarget,
}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 3, height: 1),
    layers: [
      const MapLayer.tile(
        id: 'tile',
        name: 'Tile',
        tiles: [0, 0, 0],
      ),
      MapLayer.path(
        id: 'path',
        name: 'Path',
        presetId: 'water_path',
        cells: includeWaterPath
            ? const [false, true, false]
            : const [false, false, false],
      ),
      MapLayer.collision(
        id: 'collision',
        name: 'Collision',
        collisions: includeCollisionAtTarget
            ? const [false, true, false]
            : const [false, false, false],
      ),
    ],
  );
}

ProjectManifest _projectWithWaterPreset() {
  return ProjectManifest(
    name: 'project',
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(
          id: 'ts', name: 'Tileset', relativePath: 'tileset.png'),
    ],
    pathPresets: const [
      ProjectPathPreset(
        id: 'water_path',
        name: 'Water',
        surfaceKind: PathSurfaceKind.water,
        tilesetId: 'ts',
      ),
    ],
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectManifest _projectWithRoadPreset() {
  return ProjectManifest(
    name: 'project',
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(
          id: 'ts', name: 'Tileset', relativePath: 'tileset.png'),
    ],
    pathPresets: const [
      ProjectPathPreset(
        id: 'water_path',
        name: 'Road',
        surfaceKind: PathSurfaceKind.road,
        tilesetId: 'ts',
      ),
    ],
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

```

## 23. Git status final

```text
 M packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart
 M packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_action.dart
 M packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_dialog.dart
 M packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_presenter.dart
 M packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart
 M packages/map_gameplay/test/movement_mode_water_test.dart
?? reports/surface/surface_engine_lot_102_surfable_water_from_surface_workflow_decision.md
?? reports/surface/surface_engine_lot_103_editor_generate_surfable_water_gameplay_zone_from_surface.md
```

Diff stat final :

```text
.../surface_painter/surface_palette_panel.dart     | 219 ++++++++------
 .../surface_to_gameplay_zone_action.dart           |  25 ++
 .../surface_to_gameplay_zone_dialog.dart           |  88 ++++++
 .../surface_to_gameplay_zone_presenter.dart        | 146 ++++++++++
 .../surface_to_gameplay_zone_action_test.dart      | 320 ++++++++++++++++++++-
 .../test/movement_mode_water_test.dart             |  18 +-
 6 files changed, 715 insertions(+), 101 deletions(-)
```

## 24. Périmètre explicitement non touché

Confirmation :

```text
MapData modèle non modifié
MapGameplayZone modèle non modifié
MovementZonePayload non modifié
SurfaceLayer non modifié
SurfaceCellPlacement non modifié
ProjectManifest non modifié
surface.dart non modifié
surface_catalog.dart non modifié
map_layer.dart non modifié
map_gameplay_zone_payloads.dart non modifié
map_runtime production non modifié
map_gameplay production non modifié
map_battle non modifié
aucun JSON
aucun generated/build_runner
aucun gameplay surf runtime codé
aucun encounter surf codé
aucune collision Surface codée
aucune migration legacy
aucun filtre surfacePresetId dans MapGameplayZone
aucun lava / ice / mud
```

Note : `packages/map_gameplay/test/movement_mode_water_test.dart` a été modifié uniquement pour corriger les fixtures `surfaceCatalog` manquantes.

## 25. ctx stats

```text
1.5M tokens saved · 88.2% reduction · 3h 17m
Without context-mode: 6.5 MB
With context-mode: 782.6 KB
5.7 MB kept out of your conversation
143 calls
ctx_batch_execute: 32 calls, 4.9 MB saved
ctx_execute: 63 calls, 502.1 KB saved
ctx_search: 8 calls, 233.2 KB saved
ctx_stats: 14 calls, 79.0 KB saved
ctx_index: 20 calls, 27.6 KB saved
ctx_doctor: 5 calls, 13.4 KB saved
ctx_upgrade: 1 call, 3.7 KB saved
version: v1.0.100
update available: v1.0.100 -> v1.0.103
```

## 26. Limites restantes

- Le workflow ne vérifie pas sémantiquement qu'un preset est vraiment water ; `ProjectSurfacePreset` reste volontairement visuel.
- Le warning UX “cette surface ne semble pas nommée water/eau” n'est pas codé en V0.
- Pas de preview graphique de couverture dans le dialog ; uniquement les messages assessment textuels.
- Pas de rencontres surf ; elles doivent rester un workflow séparé.
- Pas de runtime surf ajouté ; ce lot authorise seulement les `MapGameplayZone movement/surf`.

## 27. Auto-critique

- Est-ce que l'action “Rendre cette eau surfable” existe ? Oui.
- Est-ce que le lot reste limité à water/surf movement ? Oui.
- Est-ce que tall grass reste intact ? Oui, le workflow et les tests tall grass passent.
- Est-ce que SurfaceLayer reste visuel ? Oui.
- Est-ce que MapGameplayZone est réutilisé ? Oui.
- Est-ce que MovementZonePayload(requiredMode: surf) est utilisé ? Oui.
- Est-ce que allowedModes n'est pas utilisé en V0 ? Oui, le presenter ne le renseigne pas.
- Est-ce que greedyRectangles est utilisé par défaut ? Oui.
- Est-ce que la confirmation empêche un plan blocked ? Oui.
- Est-ce que les zones créées sont des MapGameplayZone movement/surf ? Oui.
- Est-ce que la map devient dirty ? Oui, testé via `state.isDirty`.
- Est-ce qu'aucune SurfaceLayer n'est modifiée ? Oui, testé par comparaison des placements.
- Est-ce que les plans invalides ne mutent rien partiellement ? Oui, testé pour non movement et movement non surf.
- Est-ce que movement_mode_water_test.dart est corrigé ou remplacé par un test équivalent ? Oui, corrigé.
- Est-ce que surf_evaluation_test.dart passe ? Oui.
- Est-ce que les tests ciblés passent ? Oui.
- Est-ce que les régressions Surface Painter passent ? Oui.
- Est-ce que l'analyse ciblée passe ? Oui.
- Est-ce que Context Mode a été utilisé agressivement ? Oui.
- Est-ce que ctx stats est inclus ? Oui.
- Est-ce que le contenu complet des fichiers créés/modifiés est copié dans le rapport ? Oui pour les fichiers modifiés ; le rapport créé est exclu par exception anti-récursion.
- Est-ce qu'un Lot 103-bis est nécessaire ? Non. Le workflow V0 demandé est codé, testé et borné.

## 28. Regard critique sur le prompt

Le prompt était bien cadré : la précondition `movement_mode_water_test.dart` a évité de coder sur une base surf partiellement rouge, et les stops explicites ont empêché d'ouvrir runtime surf ou encounters surf. La seule tension produit restante est UX : deux boutons cohabitent désormais dans la palette Surface. C'est acceptable en V0, mais le prochain durcissement pourrait regrouper ces actions sous un menu “Comportement depuis Surface” si la palette devient trop chargée.
