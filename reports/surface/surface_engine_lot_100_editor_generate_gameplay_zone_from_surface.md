# Lot 100 — Editor Generate Tall Grass Gameplay Zone from Surface V0

## 1. Résumé exécutif honnête

Le Lot 100 branche une première action éditeur depuis le Surface Painter pour le seul cas V0 autorisé : créer des `MapGameplayZone` de type `encounter` depuis une surface peinte, typiquement `tall_grass`.

La chaîne utilisée est celle décidée aux Lots 96–99 : le `SurfaceLayer` reste strictement visuel, le plan de génération vient de `createSurfaceGameplayZoneGenerationPlan`, l'évaluation vient de `assessSurfaceGameplayZoneGenerationPlan`, puis la confirmation crée des zones gameplay existantes via les seams publics de l'éditeur.

Le lot ne touche pas `map_core`, `map_runtime`, `map_gameplay`, `map_battle`, les modèles persistants, le JSON, Surface Studio, ni Surface Painter côté peinture. Le choix V0 reste volontairement étroit : pas de surf, pas de lave, pas de glace, pas de boue.

## 2. Périmètre

Inclus :

- action dans `SurfacePainterPanel` : `Créer une zone de rencontre` ;
- dialog textuel de confirmation ;
- presenter Surface -> plan -> assessment ;
- helper d'application qui utilise les méthodes existantes du `EditorNotifier` ;
- tests widget/presenter/intégration notifier ciblés ;
- rapport complet.

Exclus et respecté :

- pas de modification de modèle `MapData`, `MapGameplayZone`, `SurfaceLayer`, `SurfaceCellPlacement` ;
- pas de `ProjectManifest`, JSON, build_runner, runtime, gameplay, battle ;
- pas de surf, lava/hazard runtime, ice, mud, migration legacy ;
- pas de refonte Surface Studio ou GameplayZone panel ;
- pas d'assistant multi-step complet.

Changements préexistants : aucun changement local au Gate 0.

Changements du Lot 100 : un fichier Surface Painter modifié, quatre fichiers Surface Painter créés, ce rapport créé.

## 3. Gate 0 — status initial

Commandes exécutées avant modification :

```text
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
```

Sorties :

```text
PWD
/Users/karim/Project/pokemonProject

BRANCH
main

STATUS

DIFF_STAT

LOG
15fa925c lot 99/95: Surface Gameplay - Surface to Gameplay Zone Coverage Diagnostics
70b0f90d lot 98/95: Surface Gameplay - Surface to Gameplay Zone Generation Plan
8d62718f lot 97/95: Surface Gameplay - Surface Gameplay Zone Authoring Workflow Spec
ac7984f2 lot 96/95: Surface Gameplay - Zones Bridge Decision Report
a4d62f39 lot 94/95: Surface Gameplay
83654389 feat: add surface runtime test files and golden slice reports
1f900e67 feat(map_runtime): render surface layers
da2b244d feat(map_runtime): add surface runtime resolver
32fbb0b5 feat(map_editor): improve surface mapping editor
d5561df7 feat(map_editor): edit surface role animation mapping
```

Nested `AGENTS.md` :

```text
./AGENTS.md
```

Aucun `AGENTS.md` plus profond n'a été trouvé sous `packages/map_editor`.

## 4. Context Mode usage

Context Mode MCP a été utilisé pour :

- Gate 0 ;
- audit Surface Painter / Surface palette ;
- audit GameplayZone editing ;
- audit encounter tables ;
- audit tests existants ;
- sorties de tests et d'analyse ;
- status/diff final ;
- `ctx_stats` final.

Le binaire `ctx` demandé par `ctx stats` n'est pas disponible dans le shell local :

```text
ctx stats
zsh:1: command not found: ctx
```

Les outils MCP Context Mode sont disponibles et ont été utilisés. `ctx_doctor` a retourné :

```text
context-mode doctor
- [x] Runtimes: 7/11 (64%) — javascript, shell, python, ruby, rust, php, perl
- [-] Performance: NORMAL — install Bun for 3-5x speed boost
- [x] Server test: PASS
- [x] FTS5 / SQLite: PASS — native module works
- [x] Hook script: PASS — /opt/homebrew/lib/node_modules/context-mode/hooks/pretooluse.mjs
- [x] Version: v1.0.100
```

Stats compactes MCP finales :

```text
942.8K tokens saved · 91.3% reduction · 2h 21m
Without context-mode: 3.9 MB
With context-mode: 352.7 KB
3.6 MB kept out of your conversation
102 calls
ctx_batch_execute: 9 calls, 2.7 MB saved
ctx_execute: 51 calls, 518.9 KB saved
ctx_search: 8 calls, 326.8 KB saved
ctx_stats: 8 calls, 58.5 KB saved
ctx_index: 20 calls, 38.6 KB saved
ctx_doctor: 5 calls, 18.8 KB saved
ctx_upgrade: 1 call, 5.2 KB saved
version: v1.0.100
update available: v1.0.100 -> v1.0.103
```

## 5. Audit Surface Painter

Commandes d'audit :

```text
rg -n "SurfacePalettePanel|SurfacePaintingController|surface_painter|SurfaceLayer|SurfaceCellPlacement|surfacePresetId|selectedSurface|paintSurface|eraseSurface|surfaceCatalog" packages/map_editor/lib packages/map_editor/test packages/map_core/lib packages/map_core/test
sed -n '1,260p' packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart
sed -n '1,260p' packages/map_editor/lib/src/features/surface_painter/surface_painting_controller.dart
sed -n '1,220p' packages/map_editor/lib/src/features/surface_painter/surface_catalog_availability.dart
sed -n '1,260p' packages/map_core/lib/src/operations/surface_to_gameplay_zone_generation_plan.dart
sed -n '1,260p' packages/map_core/lib/src/operations/surface_to_gameplay_zone_generation_assessment.dart
```

Findings importants :

- `SurfacePainterPanel` connaît la map active, le `surfaceCatalog`, les `SurfaceLayer`, le `selectedSurfacePresetId` et les presets disponibles.
- `SurfacePalettePanel` liste les presets et pilote la sélection du preset via `EditorNotifier.setSelectedSurfacePreset`.
- Le meilleur point d'entrée V0 est le `SurfacePainterPanel`, près des contrôles `paint/erase`, car il possède déjà la map, le layer actif, la sélection et les presets.
- Les placements sont stockés dans `SurfaceLayer.placements` et filtrables par `surfacePresetId`.
- L'action utilise le `SurfaceLayer` actif, avec fallback vers l'unique `SurfaceLayer` si exactement un layer Surface existe.

## 6. Audit GameplayZone editing

Commandes d'audit :

```text
rg -n "GameplayZoneEditingService|GameplayZoneEditingCoordinator|gameplay_zone|addGameplayZone|updateGameplayZone|selectGameplayZone|MapGameplayZone|EncounterZonePayload|EncounterKind" packages/map_editor/lib packages/map_editor/test packages/map_core/lib packages/map_core/test
sed -n '1,260p' packages/map_editor/lib/src/application/services/gameplay_zone_editing_service.dart
sed -n '1,260p' packages/map_editor/lib/src/application/services/gameplay_zone_editing_coordinator.dart
sed -n '1,260p' packages/map_editor/lib/src/application/use_cases/gameplay_zone_use_cases.dart
sed -n '1,260p' packages/map_editor/lib/src/ui/panels/gameplay_zone_properties_panel.dart
sed -n '1,260p' packages/map_core/lib/src/operations/map_gameplay_zones.dart
```

Findings importants :

- L'éditeur dispose déjà de `EditorNotifier.addGameplayZoneAt`, `updateGameplayZone` et `selectGameplayZone`.
- Ces méthodes passent par les use cases/services existants et par `_applyMapMutation`, donc elles déclenchent le dirty state via le chemin habituel.
- Pour éviter une mutation parallèle dans le widget, le Lot 100 ajoute un helper d'application qui appelle ces méthodes publiques.
- La sélection de la première zone créée est faite après confirmation via `selectGameplayZone`.
- Limite V0 : plusieurs zones créées produisent plusieurs mutations existantes (`add` puis `update` par zone), donc potentiellement plusieurs entrées d'historique. Aucun seam batch n'a été inventé dans ce lot.

## 7. Audit encounter tables

Commande d'audit :

```text
rg -n "EncounterTable|encounterTable|encounter tables|EncounterZonePayload|encounterTableId|route.*encounter|battleBackground" packages/map_core/lib packages/map_editor/lib packages/map_editor/test packages/map_runtime/lib
```

Findings importants :

- Les tables de rencontres vivent dans `ProjectManifest.encounterTables` sous forme de `ProjectEncounterTable`.
- Le `GameplayZonePropertiesPanel` sait déjà lire `project?.encounterTables` et afficher une liste de tables disponibles.
- Le Lot 100 reste V0 : le dialog utilise un champ texte `encounterTableId`, pré-rempli avec la première table disponible si elle existe, et affiche les IDs disponibles.
- Si aucune table n'est disponible, l'utilisateur peut saisir un ID manuellement, mais la confirmation reste bloquée tant que le champ est vide.

## 8. Décision UX V0

Libellé retenu : `Créer une zone de rencontre`.

Justification :

- plus clair et plus étroit que `Créer un comportement depuis cette surface` ;
- évite de promettre surf/lava/ice/mud ;
- correspond exactement à la sortie V0 : `MapGameplayZone(kind: encounter)`.

Le dialog porte le titre : `Créer une zone de rencontre depuis cette surface`.

## 9. Design technique

La chaîne technique V0 est :

```text
SurfacePainterPanel
-> SurfaceToGameplayZoneDialog
-> buildTallGrassEncounterSurfaceGameplayZonePreview
-> createSurfaceGameplayZoneGenerationPlan(strategy: greedyRectangles)
-> assessSurfaceGameplayZoneGenerationPlan
-> applyTallGrassEncounterGameplayZonePlan
-> EditorNotifier.addGameplayZoneAt / updateGameplayZone / selectGameplayZone
```

Aucun modèle existant n'est modifié. Aucun modèle persistent nouveau n'est ajouté. Les modèles Lot 98/99 de `map_core` sont réutilisés.

## 10. Source de génération

La source est construite à partir de :

- `map.id` pour l'identifiant de map ;
- `SurfaceLayer.id` et `SurfaceLayer.name` ;
- `selectedSurfacePresetId` ;
- `SurfaceLayer.placements` filtrés sur ce preset ;
- coordonnées converties en `GridPos`.

Cas gérés :

- aucune map : `blocked` ;
- aucun `SurfaceLayer` cible : `blocked` ;
- aucun preset sélectionné : `blocked` ;
- preset absent du catalogue : `blocked` ;
- aucun placement pour ce preset : `blocked` ;
- `encounterTableId` vide : `blocked`.

## 11. Dialog / confirmation UI

Le dialog V0 est textuel et sobre. Il affiche :

- surface source ;
- nombre de cellules ;
- champ `Table de rencontres` ;
- IDs de tables disponibles si présents ;
- statut `ready / needsReview / blocked` via `summaryTitle` et `summaryDescription` ;
- messages utilisateur issus de l'assessment Lot 99 ;
- nombre de zones générées ;
- couverture et ratio de cellules hors surface.

Comportement de confirmation :

- `encounterTableId` vide : bouton désactivé ;
- plan `blocked` : bouton désactivé ;
- plan `ready` ou `needsReview` : bouton actif ;
- confirmation retourne le `SurfaceGameplayZoneGenerationPlan` au caller.

Pas de preview graphique carte dans ce lot.

## 12. Mutation MapGameplayZone

La mutation est centralisée dans `applyTallGrassEncounterGameplayZonePlan`.

Règles :

- vérifie que chaque candidate est une zone `encounter` ;
- vérifie `EncounterKind.walk` ;
- appelle `EditorNotifier.addGameplayZoneAt(zone.area.pos)` ;
- récupère l'id temporaire sélectionné via le getter fourni par le caller ;
- appelle `EditorNotifier.updateGameplayZone(...)` pour appliquer id, nom, area, priority et payload générés ;
- sélectionne la première zone générée à la fin.

Le widget ne modifie pas directement `MapData`.

## 13. ID / naming strategy

Préfixes V0 :

```text
zoneIdPrefix = <surfacePresetId>-encounter
zoneNamePrefix = <Nom surface> - Rencontre
```

Exemple :

```text
tall_grass-encounter
Tall Grass - Rencontre
```

Les collisions d'ID restent gérées par la brique du Lot 98 via les `existingZones` de la map.

## 14. Tests lancés

Commandes lancées :

```text
cd packages/map_editor && flutter test test/surface_painter/surface_to_gameplay_zone_action_test.dart --no-pub --reporter expanded
cd packages/map_editor && flutter test test/surface_painter --no-pub --reporter expanded
cd packages/map_editor && if [ -d test/gameplay_zone ]; then flutter test test/gameplay_zone --no-pub --reporter expanded; else echo "No test/gameplay_zone directory"; fi
cd packages/map_editor && flutter test test/map_selection_controller_test.dart --no-pub --reporter expanded
cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_plan_test.dart --reporter expanded
cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_assessment_test.dart --reporter expanded
cd packages/map_core && dart test test/map_gameplay_zone_validation_test.dart --reporter expanded
```

## 15. Résultats

Lignes finales exactes :

```text
targeted_action
00:00 +6: All tests passed!
EXIT_CODE=0

surface_painter_regression
00:02 +48: All tests passed!
EXIT_CODE=0

gameplay_zone_tests
No test/gameplay_zone directory
EXIT_CODE=0

map_selection_regression
00:00 +5: All tests passed!
EXIT_CODE=0

map_core_generation_plan
00:00 +16: All tests passed!
EXIT_CODE=0

map_core_assessment
00:00 +12: All tests passed!
EXIT_CODE=0

map_core_gameplay_zone_validation
00:00 +1: All tests passed!
EXIT_CODE=0
```

## 16. Analyse lancée

Commande lancée :

```text
cd packages/map_editor && flutter analyze lib/src/features/surface_painter/surface_palette_panel.dart lib/src/features/surface_painter/surface_to_gameplay_zone_action.dart lib/src/features/surface_painter/surface_to_gameplay_zone_dialog.dart lib/src/features/surface_painter/surface_to_gameplay_zone_presenter.dart test/surface_painter/surface_to_gameplay_zone_action_test.dart
```

## 17. Résultats analyze

Sortie ciblée finale :

```text
No issues found! (ran in 2.0s)
EXIT_CODE=0
```

## 18. Fichiers créés

```text
packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_action.dart
packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_dialog.dart
packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_presenter.dart
packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart
reports/surface/surface_engine_lot_100_editor_generate_gameplay_zone_from_surface.md
```

## 19. Fichiers modifiés

```text
packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart
```

## 20. Fichiers supprimés

```text
Aucun.
```

## 21. Contenu complet des fichiers créés

Le contenu du rapport lui-même n'est pas recopié ici pour éviter la récursion explicitement autorisée par le prompt.

### `packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_action.dart`

```dart
import 'package:map_core/map_core.dart';

import '../editor/state/editor_notifier.dart';

bool applyTallGrassEncounterGameplayZonePlan({
  required EditorNotifier notifier,
  required String? Function() selectedGameplayZoneId,
  required SurfaceGameplayZoneGenerationPlan plan,
}) {
  final zones = plan.generatedZones;
  if (zones.isEmpty) {
    return false;
  }
  if (zones.any((zone) => !_isTallGrassEncounterZone(zone))) {
    return false;
  }

  String? firstCreatedZoneId;
  for (final zone in zones) {
    notifier.addGameplayZoneAt(zone.area.pos);
    final createdZoneId = selectedGameplayZoneId();
    if (createdZoneId == null) {
      return false;
    }
    firstCreatedZoneId ??= zone.id;
    notifier.updateGameplayZone(
      zoneId: createdZoneId,
      id: zone.id,
      name: zone.name,
      kind: zone.kind,
      area: zone.area,
      priority: zone.priority,
      encounter: zone.encounter,
      movement: null,
      hazard: null,
      special: null,
    );
  }

  if (firstCreatedZoneId != null) {
    notifier.selectGameplayZone(firstCreatedZoneId);
  }
  return true;
}

bool _isTallGrassEncounterZone(MapGameplayZone zone) {
  return zone.kind == GameplayZoneKind.encounter &&
      zone.encounter != null &&
      zone.encounter?.encounterKind == EncounterKind.walk;
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
  });

  group('EditorNotifier tall grass surface generation', () {
    test('adds encounter gameplay zones, marks dirty, and preserves surfaces',
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
        selectedGameplayZoneId: () =>
            container.read(editorNotifierProvider).selectedGameplayZoneId,
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
      expect(
        updatedMap.layers.whereType<SurfaceLayer>().single.placements,
        initialMap.layers.whereType<SurfaceLayer>().single.placements,
      );
    });
  });
}

MapData _mapWithTallGrassSurface() {
  return MapData(
    id: 'route_1',
    name: 'Route 1',
    size: const GridSize(width: 8, height: 8),
    layers: [_tallGrassLayer()],
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

ProjectManifest _projectManifest() {
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
      presets: [_surfacePreset(id: 'tall_grass', name: 'Tall Grass')],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          selectedGameplayZoneId: () => ref
                              .read(editorNotifierProvider)
                              .selectedGameplayZoneId,
                          plan: plan,
                        );
                      },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.add_circled, size: 16),
                    SizedBox(width: 6),
                    Text('Créer une zone de rencontre'),
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


## 23. Git status final

Status final :

```text
 M packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart
?? packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_action.dart
?? packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_dialog.dart
?? packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_presenter.dart
?? packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart
?? reports/surface/surface_engine_lot_100_editor_generate_gameplay_zone_from_surface.md
```

Diff stat final tracked :

```text
 .../surface_painter/surface_palette_panel.dart     | 44 ++++++++++++++++++++++
 1 file changed, 44 insertions(+)
```

`git diff --check` :

```text
Aucune sortie.
```

## 24. Périmètre explicitement non touché

Confirmation :

```text
MapData modèle non modifié
MapGameplayZone modèle non modifié
SurfaceLayer non modifié
SurfaceCellPlacement non modifié
ProjectManifest non modifié
surface.dart non modifié
surface_catalog.dart non modifié
map_layer.dart non modifié
map_gameplay_zone_payloads.dart non modifié
map_core production non modifié
map_runtime non modifié
map_gameplay non modifié
map_battle non modifié
aucun JSON
aucun generated/build_runner
aucun gameplay surf codé
aucun tall grass encounter runtime codé
aucune collision Surface codée
aucune migration legacy
aucun filtre surfacePresetId dans MapGameplayZone
```

## 25. ctx stats

```text
ctx stats CLI: indisponible via shell local (zsh:1: command not found: ctx)
MCP ctx_stats: disponible et exécuté
942.8K tokens saved · 91.3% reduction · 2h 21m
Without context-mode: 3.9 MB
With context-mode: 352.7 KB
3.6 MB kept out of your conversation
102 calls
ctx_batch_execute: 9 calls, 2.7 MB saved
ctx_execute: 51 calls, 518.9 KB saved
ctx_search: 8 calls, 326.8 KB saved
ctx_stats: 8 calls, 58.5 KB saved
ctx_index: 20 calls, 38.6 KB saved
ctx_doctor: 5 calls, 18.8 KB saved
ctx_upgrade: 1 call, 5.2 KB saved
version: v1.0.100
update available: v1.0.100 -> v1.0.103
```

## 26. Limites restantes

- V0 n'a pas de dropdown riche de tables de rencontres ; le champ est textuel, pré-rempli avec la première table existante si disponible.
- V0 ne fait pas de preview graphique sur la carte ; il affiche les diagnostics textuels Lot 99.
- L'application du plan passe par les méthodes publiques existantes `addGameplayZoneAt` puis `updateGameplayZone`, donc plusieurs zones peuvent créer plusieurs entrées d'historique. C'est acceptable pour V0 mais un Lot futur peut ajouter un seam batch propre si nécessaire.
- Aucun comportement runtime d'herbe haute n'est ajouté ici ; seules les `MapGameplayZone encounter` sont authorées.

## 27. Auto-critique

- Est-ce que l'action éditeur existe ? Oui.
- Est-ce que le lot est limité à tall grass / encounter ? Oui.
- Est-ce que SurfaceLayer reste visuel ? Oui.
- Est-ce que MapGameplayZone est réutilisé ? Oui.
- Est-ce que le plan du Lot 98 est utilisé ? Oui.
- Est-ce que l'assessment du Lot 99 est utilisé ? Oui.
- Est-ce que greedyRectangles est utilisé par défaut ? Oui.
- Est-ce que encounterTableId est obligatoire ? Oui.
- Est-ce que la confirmation empêche un plan blocked ? Oui.
- Est-ce que les zones créées sont des MapGameplayZone encounter ? Oui.
- Est-ce que la map devient dirty ? Oui.
- Est-ce qu'aucune SurfaceLayer n'est modifiée ? Oui.
- Est-ce que les tests ciblés passent ? Oui.
- Est-ce que les régressions Surface Painter passent ? Oui.
- Est-ce que l'analyse ciblée passe ? Oui.
- Est-ce que Context Mode a été utilisé agressivement ? Oui, via MCP.
- Est-ce que ctx stats est inclus ? Oui, avec stats MCP et indisponibilité CLI documentées.
- Est-ce que le contenu complet des fichiers créés/modifiés est copié dans le rapport ? Oui, sauf le rapport lui-même par exception anti-récursion.
- Est-ce qu'un Lot 100-bis est nécessaire ? Non. La V0 demandée est couverte ; les limites restantes sont des raffinements de lots futurs.

## 28. Regard critique sur le prompt

Le prompt est précis et a bien empêché l'ouverture de surf/lava/ice/mud. La contrainte Evidence Pack complet est lourde mais utile pour validation externe. Le point le plus délicat est la mutation : l'exigence de ne pas dupliquer le chemin existant pousse à réutiliser les méthodes publiques du notifier, ce qui garde le lot petit mais laisse une limite d'historique batch à traiter plus tard si l'UX le demande.
