# NSC-61 — Modularisation du Cinematic Builder

Date : 2026-07-20
Statut proposé : **DONE**

## Lot et objectif

- Lot canonique : **NSC-61 — Modulariser sans changer le comportement**.
- Phase : **6 — Cinematics professionnelles**.
- Alignement gameplay : prépare l’auteur cinématique consommé par **FG-082** ; ne prétend pas implémenter les commandes runtime ni étendre le périmètre MVP de **FG-145**.
- Critère de succès : isoler l’état de présentation et donner à la palette, la scène, la timeline et l’inspecteur une frontière propriétaire testable, sans changement visuel ni mutation de données.

## Audit initial

Le workspace cinématique était concentré dans un fichier de 13 567 lignes. La sélection locale, la sonde temporelle et les modes de placement vivaient directement dans le State principal. Les quatre surfaces n’avaient pas de frontière stable. Le guardrail de design system tolèrait encore 13 références directes à des couleurs dans ce fichier.

État Git initial du lot : propre après le commit NSC-60 `d1193d5a`.

## Passes indépendantes

Aucun sub-agent n’a été lancé : l’instruction d’exécution active interdit la délégation sans demande explicite. Les vérifications ont donc été séparées en passes locales indépendantes :

1. **Passe architecture** : état éphémère extrait dans `CinematicBuilderController` ; frontières render-neutral pour les quatre surfaces.
2. **Passe design system** : remplacement des 13 couleurs directes par trois tokens sémantiques, suppression de la dette autorisée.
3. **Passe comportementale** : contrôleur, ownership des surfaces, caractérisation complète du builder.
4. **Passe visuelle/performance** : goldens inchangés ; zéro rebuild après stabilisation.

Verdict cumulé : **GO**.

## Décisions

- Le contrôleur ne connaît ni transaction projet, ni persistance, ni runtime : il possède uniquement l’état de présentation local.
- Les panneaux sont des frontières de composition à coût visuel nul. Ils permettent une migration progressive des implémentations privées sans big bang.
- Les scrims deviennent des tokens de thème explicites ; aucune couleur produit n’est ajoutée dans l’écran.
- Les clés de surface stables servent de contrat aux tests et aux futures extractions.

## Fichiers modifiés

- `packages/map_editor/lib/src/theme/pokemap_color_tokens.dart` : tokens `transparent`, `scrimSoft`, `scrimSubtle`, light/dark/copyWith/lerp.
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart` : branchement du contrôleur, frontières des quatre surfaces, retrait de toutes les couleurs directes.
- `packages/map_editor/test/cinematic_builder_workspace_test.dart` : preuve d’intégration des quatre frontières.
- `packages/map_editor/test/design_system_guardrail_test.dart` : dette cinématique ramenée de 13 à 0.
- `packages/map_editor/test/theme/pokemap_theme_test.dart` : contrat exact des nouveaux tokens.

## Fichiers créés

- `packages/map_editor/lib/src/ui/canvas/cinematics/builder/cinematic_builder_controller.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/builder/cinematic_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/builder/cinematic_palette_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/builder/cinematic_stage_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/builder/cinematic_timeline_panel.dart`
- `packages/map_editor/test/ui/canvas/cinematics/cinematic_builder_controller_test.dart`
- `packages/map_editor/test/ui/canvas/cinematics/cinematic_inspector_panel_test.dart`
- `packages/map_editor/test/ui/canvas/cinematics/cinematic_palette_panel_test.dart`
- `packages/map_editor/test/ui/canvas/cinematics/cinematic_stage_panel_test.dart`
- `packages/map_editor/test/ui/canvas/cinematics/cinematic_timeline_panel_test.dart`

## Zones précises modifiées

- Constructor et propriétés de `PokeMapColorTokens`, palettes light/dark, `copyWith` et `lerp`.
- Cycle de vie de `_CinematicBuilderWorkspaceState` : création, synchronisation et destruction du contrôleur.
- Accès à `selectedStepId`, `timelineProbeTimeMs`, `timelineProbeSnapHint`, `selectedStagePointId` et `addStagePointMode`.
- Composition principale : palette, stage, timeline et inspector enveloppés par leurs propriétaires publics.
- Décorations du builder : références directes remplacées par les tokens du contexte.

## TDD

RED observé :

- les cinq tests de modules échouaient car le contrôleur et les quatre panneaux n’existaient pas ;
- le test de thème échouait car les trois tokens n’existaient pas.

GREEN obtenu après l’implémentation ciblée.

## Commandes et résultats exacts

```text
dart format [15 fichiers]
Formatted 15 files (0 changed) in 0.23 seconds.

flutter analyze lib/src/theme/pokemap_color_tokens.dart lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/builder test/cinematic_builder_workspace_test.dart test/design_system_guardrail_test.dart test/theme/pokemap_theme_test.dart test/ui/canvas/cinematics
No issues found! (ran in 6.4s)

flutter test --reporter compact [11 suites ciblées]
00:57 +377: All tests passed!

NSC-60 cinematic baseline:
coldLoadMs=890
builderOpenMs=903
openFirstBuilds=6271
openRebuilds=0
settledFirstBuilds=0
settledRebuilds=0

git diff --check
aucune sortie, code 0

flutter build macos --debug
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

Les trois goldens canonique Library/Builder/Legacy inclus dans ces suites sont restés identiques.

## Non-objectifs

- Aucun changement de schéma.
- Aucun nouveau bloc cinématique.
- Aucun changement de transaction ou de runtime.
- Aucun déplacement massif des implémentations privées : les frontières de composition rendent cette migration possible par incréments sûrs.

## Risques et limites

- Le workspace source reste volumineux ; NSC-61 crée les points de coupe mais ne prétend pas achever une réécriture physique complète.
- Les wrappers ajoutent huit first-builds dans la mesure isolée ; aucun rebuild stabilisé n’est ajouté et les budgets NSC-60 restent respectés.
- Les valeurs de performance sont des garde-fous de test local, pas des garanties matérielles universelles.

## Auto-critique

La modularisation choisit volontairement une couture de composition prudente. Elle est moins spectaculaire qu’un déplacement immédiat de milliers de lignes, mais elle réduit le risque de régression visuelle et fournit des contrats testables. La prochaine amélioration architecturale pourra déplacer chaque implémentation privée derrière sa frontière, lot par lot, sans modifier l’API du workspace.

## Inventaire complet des fichiers créés

### `packages/map_editor/lib/src/ui/canvas/cinematics/builder/cinematic_builder_controller.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

/// Semantic snap origin kept outside the timeline widget so extraction does
/// not turn local UI state into a second authoring model.
enum CinematicTimelineProbeSnapHint {
  timelineStart,
  timelineEnd,
  blockStart,
  blockEnd,
}

/// Owns transient Cinematic Builder selection state only.
///
/// Project mutations remain in the authoring transaction callbacks. This
/// controller deliberately contains no persistence, asset cloning or runtime
/// playback logic, which protects the behavior-constant boundary of NSC-61.
final class CinematicBuilderController extends ChangeNotifier {
  CinematicBuilderController({required CinematicAsset asset})
      : _assetId = asset.id;

  String _assetId;
  String? _selectedStepId;
  int? _timelineProbeTimeMs;
  CinematicTimelineProbeSnapHint? _timelineProbeSnapHint;
  String? _selectedStagePointId;
  bool _addStagePointMode = false;

  String get assetId => _assetId;

  String? get selectedStepId => _selectedStepId;
  set selectedStepId(String? value) => _update(
        _selectedStepId != value,
        () => _selectedStepId = value,
      );

  int? get timelineProbeTimeMs => _timelineProbeTimeMs;
  set timelineProbeTimeMs(int? value) => _update(
        _timelineProbeTimeMs != value,
        () => _timelineProbeTimeMs = value,
      );

  CinematicTimelineProbeSnapHint? get timelineProbeSnapHint =>
      _timelineProbeSnapHint;
  set timelineProbeSnapHint(CinematicTimelineProbeSnapHint? value) => _update(
        _timelineProbeSnapHint != value,
        () => _timelineProbeSnapHint = value,
      );

  String? get selectedStagePointId => _selectedStagePointId;
  set selectedStagePointId(String? value) => _update(
        _selectedStagePointId != value,
        () => _selectedStagePointId = value,
      );

  bool get addStagePointMode => _addStagePointMode;
  set addStagePointMode(bool value) => _update(
        _addStagePointMode != value,
        () => _addStagePointMode = value,
      );

  /// Preserves local state for an updated snapshot of the same asset, while
  /// rejecting a selected step that no longer exists. Switching assets clears
  /// all ephemeral context and cannot leak one Cinematic selection to another.
  void synchronize(CinematicAsset asset) {
    if (_assetId != asset.id) {
      _assetId = asset.id;
      _reset(notify: true);
      return;
    }
    final selectedStepId = _selectedStepId;
    if (selectedStepId != null &&
        !asset.timeline.steps.any((step) => step.id == selectedStepId)) {
      _selectedStepId = null;
      notifyListeners();
    }
  }

  void clearTimelineProbe() {
    final changed =
        _timelineProbeTimeMs != null || _timelineProbeSnapHint != null;
    _timelineProbeTimeMs = null;
    _timelineProbeSnapHint = null;
    if (changed) notifyListeners();
  }

  void _reset({required bool notify}) {
    _selectedStepId = null;
    _timelineProbeTimeMs = null;
    _timelineProbeSnapHint = null;
    _selectedStagePointId = null;
    _addStagePointMode = false;
    if (notify) notifyListeners();
  }

  void _update(bool changed, VoidCallback update) {
    if (!changed) return;
    update();
    notifyListeners();
  }
}
```
### `packages/map_editor/lib/src/ui/canvas/cinematics/builder/cinematic_inspector_panel.dart`

```dart
import 'package:flutter/widgets.dart';

/// Render-neutral owner for the Cinematic selection inspector.
final class CinematicInspectorPanel extends StatelessWidget {
  const CinematicInspectorPanel({super.key, required this.child});

  static const surfaceKey = ValueKey<String>('cinematic-inspector-panel');

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: surfaceKey, child: child);
}
```

### `packages/map_editor/lib/src/ui/canvas/cinematics/builder/cinematic_palette_panel.dart`

```dart
import 'package:flutter/widgets.dart';

/// Stable extraction boundary for the Cinematic command palette.
///
/// NSC-61 keeps this wrapper render-neutral so the characterized golden and
/// layout remain unchanged while the surface gains an independent owner.
final class CinematicPalettePanel extends StatelessWidget {
  const CinematicPalettePanel({super.key, required this.child});

  static const surfaceKey = ValueKey<String>('cinematic-palette-panel');

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: surfaceKey, child: child);
}
```

### `packages/map_editor/lib/src/ui/canvas/cinematics/builder/cinematic_stage_panel.dart`

```dart
import 'package:flutter/widgets.dart';

/// Render-neutral owner for the stage/preview surface extracted in NSC-61.
final class CinematicStagePanel extends StatelessWidget {
  const CinematicStagePanel({super.key, required this.child});

  static const surfaceKey = ValueKey<String>('cinematic-stage-panel');

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: surfaceKey, child: child);
}
```

### `packages/map_editor/lib/src/ui/canvas/cinematics/builder/cinematic_timeline_panel.dart`

```dart
import 'package:flutter/widgets.dart';

/// Render-neutral owner for the deterministic Cinematic timeline surface.
final class CinematicTimelinePanel extends StatelessWidget {
  const CinematicTimelinePanel({super.key, required this.child});

  static const surfaceKey = ValueKey<String>('cinematic-timeline-panel');

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: surfaceKey, child: child);
}
```

### `packages/map_editor/test/ui/canvas/cinematics/cinematic_builder_controller_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/builder/cinematic_builder_controller.dart';

void main() {
  test('keeps local selection for the same asset and resets on asset switch',
      () {
    final controller = CinematicBuilderController(asset: _asset('first'));
    addTearDown(controller.dispose);

    controller
      ..selectedStepId = 'step_a'
      ..timelineProbeTimeMs = 420
      ..timelineProbeSnapHint = CinematicTimelineProbeSnapHint.blockStart
      ..selectedStagePointId = 'point_a'
      ..addStagePointMode = true;

    controller.synchronize(_asset('first'));
    expect(controller.selectedStepId, 'step_a');
    expect(controller.timelineProbeTimeMs, 420);

    controller.synchronize(_asset('second'));
    expect(controller.selectedStepId, isNull);
    expect(controller.timelineProbeTimeMs, isNull);
    expect(controller.timelineProbeSnapHint, isNull);
    expect(controller.selectedStagePointId, isNull);
    expect(controller.addStagePointMode, isFalse);
  });

  test('drops only a selected step that disappeared from the current asset',
      () {
    final controller = CinematicBuilderController(asset: _asset('first'));
    addTearDown(controller.dispose);
    controller
      ..selectedStepId = 'step_a'
      ..selectedStagePointId = 'point_a';

    controller.synchronize(_asset('first', includeStep: false));

    expect(controller.selectedStepId, isNull);
    expect(controller.selectedStagePointId, 'point_a');
  });
}

CinematicAsset _asset(String id, {bool includeStep = true}) => CinematicAsset(
      id: id,
      title: id,
      timeline: CinematicTimeline(
        steps: [
          if (includeStep)
            CinematicTimelineStep(
              id: 'step_a',
              kind: CinematicTimelineStepKind.wait,
              durationMs: 100,
            ),
        ],
      ),
    );
```

### `packages/map_editor/test/ui/canvas/cinematics/cinematic_inspector_panel_test.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/ui/canvas/cinematics/builder/cinematic_inspector_panel.dart';

void main() {
  testWidgets('owns a stable inspector boundary without changing its child', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: CinematicInspectorPanel(child: Text('Inspector child')),
      ),
    );

    expect(find.byKey(CinematicInspectorPanel.surfaceKey), findsOneWidget);
    expect(find.text('Inspector child'), findsOneWidget);
  });
}
```

### `packages/map_editor/test/ui/canvas/cinematics/cinematic_palette_panel_test.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/ui/canvas/cinematics/builder/cinematic_palette_panel.dart';

void main() {
  testWidgets('owns a stable palette boundary without changing its child', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: CinematicPalettePanel(child: Text('Palette child')),
      ),
    );

    expect(find.byKey(CinematicPalettePanel.surfaceKey), findsOneWidget);
    expect(find.text('Palette child'), findsOneWidget);
  });
}
```

### `packages/map_editor/test/ui/canvas/cinematics/cinematic_stage_panel_test.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/ui/canvas/cinematics/builder/cinematic_stage_panel.dart';

void main() {
  testWidgets('owns a stable stage boundary without changing its child', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: CinematicStagePanel(child: Text('Stage child')),
      ),
    );

    expect(find.byKey(CinematicStagePanel.surfaceKey), findsOneWidget);
    expect(find.text('Stage child'), findsOneWidget);
  });
}
```

### `packages/map_editor/test/ui/canvas/cinematics/cinematic_timeline_panel_test.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/ui/canvas/cinematics/builder/cinematic_timeline_panel.dart';

void main() {
  testWidgets('owns a stable timeline boundary without changing its child', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: CinematicTimelinePanel(child: Text('Timeline child')),
      ),
    );

    expect(find.byKey(CinematicTimelinePanel.surfaceKey), findsOneWidget);
    expect(find.text('Timeline child'), findsOneWidget);
  });
}
```
