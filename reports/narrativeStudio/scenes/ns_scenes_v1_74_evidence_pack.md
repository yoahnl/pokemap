# Evidence Pack — NS-SCENES-V1-74

## Lot

`NS-SCENES-V1-74 — Cinematic Stage Context Diagnostics / Preview Readiness Polish V0`

## Gate 0

- Working tree avant V1-74 déjà modifié par les lots précédents V1-73/V1-74 en cours.
- Fichiers V1-74 attendus :
  - `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
  - `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
  - `packages/map_editor/test/cinematic_builder_workspace_test.dart`
  - `packages/map_editor/test/cinematics_library_workspace_test.dart`
  - `reports/narrativeStudio/scenes/road_map_scenes.md`
  - `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
  - nouveau fichier pur editor `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart`
- Fichiers runtime/gameplay/battle/examples non modifiés par V1-74.

## RED

Test ajouté avant implémentation :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows cinematic stage preview readiness checklist without starting preview'
```

Sortie utile RED :

```text
Expected: exactly one matching candidate
Actual: Found 0 widgets with text "Préparation preview"
```

## GREEN

Le même test après implémentation :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows cinematic stage preview readiness checklist without starting preview'
```

Sortie utile :

```text
+1: All tests passed!
```

## Code Complet Ajouté

Fichier : `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart`

```dart
import 'package:map_core/map_core.dart';

enum CinematicStagePreviewReadinessKind {
  sandboxOnly,
  incomplete,
  blocked,
  ready,
}

enum CinematicStagePreviewReadinessItemKind {
  ok,
  incomplete,
  blocking,
  upcoming,
}

final class CinematicStagePreviewReadiness {
  const CinematicStagePreviewReadiness({
    required this.kind,
    required this.statusLabel,
    required this.libraryStatusLabel,
    required this.summary,
    required this.items,
    required this.diagnostics,
  });

  final CinematicStagePreviewReadinessKind kind;
  final String statusLabel;
  final String libraryStatusLabel;
  final String summary;
  final List<CinematicStagePreviewReadinessItem> items;
  final List<CinematicStagePreviewReadinessDiagnostic> diagnostics;
}

final class CinematicStagePreviewReadinessItem {
  const CinematicStagePreviewReadinessItem({
    required this.label,
    required this.kind,
    required this.statusLabel,
    required this.message,
  });

  final String label;
  final CinematicStagePreviewReadinessItemKind kind;
  final String statusLabel;
  final String message;

  String get displayLine => '$label — $statusLabel : $message';
}

final class CinematicStagePreviewReadinessDiagnostic {
  const CinematicStagePreviewReadinessDiagnostic({
    required this.code,
    required this.message,
    required this.severity,
  });

  final String code;
  final String message;
  final CinematicsLibraryDiagnosticSeverity severity;
}

CinematicStagePreviewReadiness buildCinematicStagePreviewReadiness({
  required CinematicAsset asset,
  required CinematicsLibraryEntry entry,
  required List<ProjectMapEntry> maps,
}) {
  final stageContext = asset.stageContext;
  final effectiveContext = stageContext ?? CinematicStageContext();
  final diagnostics = _stageDiagnostics(entry)
      .map(
        (diagnostic) => CinematicStagePreviewReadinessDiagnostic(
          code: diagnostic.code,
          message: _humanStageDiagnosticMessage(diagnostic, asset),
          severity: diagnostic.severity,
        ),
      )
      .toList(growable: false);
  final items = <CinematicStagePreviewReadinessItem>[
    _mapItem(asset, maps),
    _backdropItem(asset, effectiveContext, maps),
    _actorBindingsItem(asset, effectiveContext),
    _initialPlacementsItem(asset, effectiveContext),
    _movementTargetsItem(asset, effectiveContext),
    _mapAwareSourcesItem(asset, effectiveContext),
  ];

  final hasBlocking = diagnostics.any(
        (diagnostic) =>
            diagnostic.severity == CinematicsLibraryDiagnosticSeverity.error,
      ) ||
      items.any((item) =>
          item.kind == CinematicStagePreviewReadinessItemKind.blocking);
  final hasIncomplete = items.any(
    (item) => item.kind == CinematicStagePreviewReadinessItemKind.incomplete,
  );

  if (stageContext == null) {
    return CinematicStagePreviewReadiness(
      kind: CinematicStagePreviewReadinessKind.sandboxOnly,
      statusLabel: 'Sandbox uniquement',
      libraryStatusLabel: 'sandbox uniquement',
      summary:
          'Ajoute un contexte de scène pour préparer une future preview. La preview réelle arrivera plus tard.',
      items: items,
      diagnostics: diagnostics,
    );
  }
  if (hasBlocking) {
    return CinematicStagePreviewReadiness(
      kind: CinematicStagePreviewReadinessKind.blocked,
      statusLabel: 'À corriger avant preview',
      libraryStatusLabel: 'à corriger avant preview',
      summary:
          'Corrige les éléments bloquants avant une future preview. La preview réelle arrivera plus tard.',
      items: items,
      diagnostics: diagnostics,
    );
  }
  if (hasIncomplete || diagnostics.isNotEmpty) {
    return CinematicStagePreviewReadiness(
      kind: CinematicStagePreviewReadinessKind.incomplete,
      statusLabel: 'Contexte incomplet',
      libraryStatusLabel: 'contexte incomplet',
      summary:
          'Complète les éléments de préparation avant une future preview. La preview réelle arrivera plus tard.',
      items: items,
      diagnostics: diagnostics,
    );
  }
  return CinematicStagePreviewReadiness(
    kind: CinematicStagePreviewReadinessKind.ready,
    statusLabel: 'Prêt pour future preview',
    libraryStatusLabel: 'prêt pour future preview',
    summary:
        'Le contexte est prêt pour une future preview. La preview réelle arrivera plus tard.',
    items: items,
    diagnostics: diagnostics,
  );
}

CinematicStagePreviewReadinessItem _mapItem(
  CinematicAsset asset,
  List<ProjectMapEntry> maps,
) {
  final mapId = asset.mapId;
  if (mapId == null || mapId.trim().isEmpty) {
    return _item(
      'Map de scène',
      CinematicStagePreviewReadinessItemKind.incomplete,
      'Choisis une map de scène',
    );
  }
  final map = _stageMapForId(maps, mapId);
  if (map == null) {
    return _item(
      'Map de scène',
      CinematicStagePreviewReadinessItemKind.blocking,
      'La map de scène n’existe plus dans le projet',
    );
  }
  return _item(
      'Map de scène', CinematicStagePreviewReadinessItemKind.ok, map.name);
}

CinematicStagePreviewReadinessItem _backdropItem(
  CinematicAsset asset,
  CinematicStageContext context,
  List<ProjectMapEntry> maps,
) {
  return switch (context.backdropMode) {
    CinematicStageBackdropMode.none => _item(
        'Décor',
        CinematicStagePreviewReadinessItemKind.ok,
        'aucun décor',
      ),
    CinematicStageBackdropMode.projectMap =>
      asset.mapId == null || _stageMapForId(maps, asset.mapId) == null
          ? _item(
              'Décor',
              CinematicStagePreviewReadinessItemKind.blocking,
              'choisis une map avant d’utiliser un décor de map',
            )
          : _item(
              'Décor',
              CinematicStagePreviewReadinessItemKind.ok,
              'décor depuis la map',
            ),
  };
}

CinematicStagePreviewReadinessItem _actorBindingsItem(
  CinematicAsset asset,
  CinematicStageContext context,
) {
  if (asset.requiredActors.isEmpty) {
    return _item(
      'Acteurs liés',
      CinematicStagePreviewReadinessItemKind.ok,
      'aucun acteur requis',
    );
  }
  final duplicatePlayer = context.actorBindings
          .where((binding) => binding.kind == CinematicActorBindingKind.player)
          .length >
      1;
  if (duplicatePlayer) {
    return _item(
      'Acteurs liés',
      CinematicStagePreviewReadinessItemKind.blocking,
      'un seul acteur peut représenter le joueur',
    );
  }
  for (final actor in asset.requiredActors) {
    final binding = _actorBindingFor(context, actor.actorId);
    if (binding == null || binding.kind == CinematicActorBindingKind.unbound) {
      return _item(
        'Acteurs liés',
        CinematicStagePreviewReadinessItemKind.incomplete,
        '${_actorDisplayLabel(actor)} est non lié',
      );
    }
    if (binding.kind == CinematicActorBindingKind.mapEntity &&
        binding.mapEntityId == null) {
      return _item(
        'Acteurs liés',
        CinematicStagePreviewReadinessItemKind.upcoming,
        'Sélection d’entités prévue dans un lot suivant.',
      );
    }
  }
  return _item(
    'Acteurs liés',
    CinematicStagePreviewReadinessItemKind.ok,
    'acteurs prêts pour une future preview',
  );
}

CinematicStagePreviewReadinessItem _initialPlacementsItem(
  CinematicAsset asset,
  CinematicStageContext context,
) {
  if (asset.requiredActors.isEmpty) {
    return _item(
      'Positions initiales',
      CinematicStagePreviewReadinessItemKind.ok,
      'aucun acteur à placer',
    );
  }
  for (final actor in asset.requiredActors) {
    final placement = _initialPlacementFor(context, actor.actorId);
    if (placement == null ||
        placement.kind == CinematicActorInitialPlacementKind.unset) {
      return _item(
        'Positions initiales',
        CinematicStagePreviewReadinessItemKind.incomplete,
        '${_actorDisplayLabel(actor)} n’a pas d’entrée de scène',
      );
    }
    if (placement.kind ==
            CinematicActorInitialPlacementKind.fromMovementTarget &&
        !_hasMovementTarget(asset, placement.targetId)) {
      return _item(
        'Positions initiales',
        CinematicStagePreviewReadinessItemKind.blocking,
        'une entrée de scène pointe vers une cible absente',
      );
    }
    if (placement.kind == CinematicActorInitialPlacementKind.fromMapEntity) {
      final binding = _actorBindingFor(context, actor.actorId);
      if (binding?.kind != CinematicActorBindingKind.mapEntity ||
          binding?.mapEntityId == null) {
        return _item(
          'Positions initiales',
          CinematicStagePreviewReadinessItemKind.incomplete,
          '${_actorDisplayLabel(actor)} doit être lié à une entité de map',
        );
      }
    }
  }
  return _item(
    'Positions initiales',
    CinematicStagePreviewReadinessItemKind.ok,
    'entrées de scène définies',
  );
}

CinematicStagePreviewReadinessItem _movementTargetsItem(
  CinematicAsset asset,
  CinematicStageContext context,
) {
  if (asset.movementTargets.isEmpty) {
    return _item(
      'Cibles de mouvement',
      CinematicStagePreviewReadinessItemKind.ok,
      'aucune cible de mouvement',
    );
  }
  for (final target in asset.movementTargets) {
    final binding = _movementTargetBindingFor(context, target.targetId);
    if (binding == null) {
      return _item(
        'Cibles de mouvement',
        CinematicStagePreviewReadinessItemKind.incomplete,
        '${target.label} n’a pas encore de source',
      );
    }
    if (binding.kind == CinematicMovementTargetBindingKind.abstractPoint) {
      continue;
    }
    if (binding.sourceId == null) {
      return _item(
        'Cibles de mouvement',
        CinematicStagePreviewReadinessItemKind.upcoming,
        '${target.label} attend une source map-aware',
      );
    }
  }
  return _item(
    'Cibles de mouvement',
    CinematicStagePreviewReadinessItemKind.ok,
    '${asset.movementTargets.first.label} reste un point abstrait',
  );
}

CinematicStagePreviewReadinessItem _mapAwareSourcesItem(
  CinematicAsset asset,
  CinematicStageContext context,
) {
  final hasMapAwareActor = context.actorBindings.any(
    (binding) => binding.kind == CinematicActorBindingKind.mapEntity,
  );
  final hasMapAwareTarget = context.movementTargetBindings.any(
    (binding) =>
        binding.kind == CinematicMovementTargetBindingKind.mapEntity ||
        binding.kind == CinematicMovementTargetBindingKind.mapEvent,
  );
  if (!hasMapAwareActor && !hasMapAwareTarget) {
    return _item(
      'Sources map-aware',
      CinematicStagePreviewReadinessItemKind.upcoming,
      'Sélection d’entités prévue dans un lot suivant. '
          'Sélection d’events prévue dans un lot suivant.',
    );
  }
  final hasMissingSource = context.actorBindings.any(
        (binding) =>
            binding.kind == CinematicActorBindingKind.mapEntity &&
            binding.mapEntityId == null,
      ) ||
      context.movementTargetBindings.any(
        (binding) =>
            (binding.kind == CinematicMovementTargetBindingKind.mapEntity ||
                binding.kind == CinematicMovementTargetBindingKind.mapEvent) &&
            binding.sourceId == null,
      );
  if (hasMissingSource) {
    return _item(
      'Sources map-aware',
      CinematicStagePreviewReadinessItemKind.upcoming,
      'Le Builder ne reçoit pas encore les entités/events de la map.',
    );
  }
  return _item(
    'Sources map-aware',
    CinematicStagePreviewReadinessItemKind.ok,
    'sources map-aware renseignées',
  );
}

CinematicStagePreviewReadinessItem _item(
  String label,
  CinematicStagePreviewReadinessItemKind kind,
  String message,
) {
  return CinematicStagePreviewReadinessItem(
    label: label,
    kind: kind,
    statusLabel: _itemStatusLabel(kind),
    message: message,
  );
}

String _itemStatusLabel(CinematicStagePreviewReadinessItemKind kind) {
  return switch (kind) {
    CinematicStagePreviewReadinessItemKind.ok => 'OK',
    CinematicStagePreviewReadinessItemKind.incomplete => 'À compléter',
    CinematicStagePreviewReadinessItemKind.blocking => 'Bloquant',
    CinematicStagePreviewReadinessItemKind.upcoming => 'À venir',
  };
}

ProjectMapEntry? _stageMapForId(List<ProjectMapEntry> maps, String? mapId) {
  if (mapId == null) {
    return null;
  }
  for (final map in maps) {
    if (map.id == mapId) {
      return map;
    }
  }
  return null;
}

CinematicActorBinding? _actorBindingFor(
  CinematicStageContext context,
  String actorId,
) {
  for (final binding in context.actorBindings) {
    if (binding.actorId == actorId) {
      return binding;
    }
  }
  return null;
}

CinematicActorInitialPlacement? _initialPlacementFor(
  CinematicStageContext context,
  String actorId,
) {
  for (final placement in context.initialPlacements) {
    if (placement.actorId == actorId) {
      return placement;
    }
  }
  return null;
}

CinematicMovementTargetBinding? _movementTargetBindingFor(
  CinematicStageContext context,
  String targetId,
) {
  for (final binding in context.movementTargetBindings) {
    if (binding.targetId == targetId) {
      return binding;
    }
  }
  return null;
}

bool _hasMovementTarget(CinematicAsset asset, String? targetId) {
  if (targetId == null) {
    return false;
  }
  return asset.movementTargets.any((target) => target.targetId == targetId);
}

List<CinematicsLibraryDiagnosticView> _stageDiagnostics(
  CinematicsLibraryEntry entry,
) {
  return entry.diagnostics
      .where((diagnostic) => _stageDiagnosticCodes.contains(diagnostic.code))
      .toList(growable: false);
}

String _humanStageDiagnosticMessage(
  CinematicsLibraryDiagnosticView diagnostic,
  CinematicAsset asset,
) {
  final actorLabel = _actorLabelFor(asset, diagnostic.sourceId);
  final targetLabel = _targetLabelFor(asset, diagnostic.sourceId);
  return switch (diagnostic.code) {
    'stageMapUnknown' => 'La map de scène n’existe plus dans le projet.',
    'stageBackdropRequiresMap' =>
      'Choisis une map avant d’utiliser un décor de map.',
    'actorBindingUnknownActor' =>
      'Un binding vise un acteur qui n’existe plus.',
    'actorBindingMissing' =>
      'Lie l’acteur ${actorLabel ?? 'requis'} avant une future preview.',
    'actorBindingDuplicatePlayer' =>
      'Un seul acteur peut représenter le joueur.',
    'actorBindingRequiresStageMap' =>
      'Choisis une map avant de lier un acteur à une entité.',
    'actorBindingMapEntityMissingSource' =>
      'Sélection d’entités prévue dans un lot suivant.',
    'actorInitialPlacementUnknownActor' =>
      'Une entrée de scène vise un acteur absent.',
    'actorInitialPlacementMissing' =>
      'Définis une entrée de scène pour ${actorLabel ?? 'cet acteur'}.',
    'actorInitialPlacementTargetUnknown' =>
      'Cette entrée de scène pointe vers une cible absente.',
    'actorInitialPlacementRequiresBinding' =>
      'Lie l’acteur avant d’utiliser son entité de map comme entrée.',
    'movementTargetBindingUnknownTarget' =>
      'Cette cible de mouvement n’existe plus.',
    'movementTargetBindingRequiresStageMap' =>
      'Choisis une map avant de lier une cible à une entité ou un event.',
    'movementTargetBindingMissingSource' => targetLabel == null
        ? 'Sélection d’events prévue dans un lot suivant.'
        : '$targetLabel attend une sélection d’entité ou d’event.',
    _ => diagnostic.message,
  };
}

String? _actorLabelFor(CinematicAsset asset, String? actorId) {
  if (actorId == null) {
    return null;
  }
  for (final actor in asset.requiredActors) {
    if (actor.actorId == actorId) {
      return _actorDisplayLabel(actor);
    }
  }
  return actorId;
}

String _actorDisplayLabel(CinematicActorRef actor) {
  final label = actor.label?.trim();
  return label == null || label.isEmpty ? actor.actorId : label;
}

String? _targetLabelFor(CinematicAsset asset, String? targetId) {
  if (targetId == null) {
    return null;
  }
  for (final target in asset.movementTargets) {
    if (target.targetId == targetId) {
      return target.label;
    }
  }
  return targetId;
}

const _stageDiagnosticCodes = <String>{
  'stageMapUnknown',
  'stageBackdropRequiresMap',
  'actorBindingUnknownActor',
  'actorBindingMissing',
  'actorBindingDuplicatePlayer',
  'actorBindingRequiresStageMap',
  'actorBindingMapEntityMissingSource',
  'actorInitialPlacementUnknownActor',
  'actorInitialPlacementMissing',
  'actorInitialPlacementTargetUnknown',
  'actorInitialPlacementRequiresBinding',
  'movementTargetBindingUnknownTarget',
  'movementTargetBindingRequiresStageMap',
  'movementTargetBindingMissingSource',
};
```

## Hunk UI Builder V1-74

```dart
class _StagePreviewReadinessSection extends StatelessWidget {
  const _StagePreviewReadinessSection({required this.readiness});

  final CinematicStagePreviewReadiness readiness;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('cinematic-builder-stage-preview-readiness-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          title: 'Préparation preview',
          subtitle: readiness.statusLabel,
        ),
        const SizedBox(height: 8),
        _KeyValue(label: 'Statut readiness', value: readiness.statusLabel),
        _MutedText(readiness.summary),
        const SizedBox(height: 8),
        const _StrongText('Checklist no-code'),
        const SizedBox(height: 6),
        for (final item in readiness.items) ...[
          _StageReadinessItemRow(item: item),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}
```

## Hunk Library V1-74

```dart
class _MetadataSummary extends StatelessWidget {
  const _MetadataSummary({
    required this.entry,
    required this.maps,
    required this.asset,
  });

  final CinematicsLibraryEntry entry;
  final List<ProjectMapEntry> maps;
  final CinematicAsset? asset;

  @override
  Widget build(BuildContext context) {
    final stageDiagnostics = _stageDiagnosticsFor(entry);
    final readiness = asset == null
        ? null
        : buildCinematicStagePreviewReadiness(
            asset: asset!,
            entry: entry,
            maps: maps,
          );
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(
            title: 'Métadonnées',
            subtitle: 'Lecture auteur',
          ),
          const SizedBox(height: 8),
          _KeyValue(label: 'Statut', value: entry.statusLabel),
          _KeyValue(label: 'Map stage', value: _stageMapLabel(entry, maps)),
          if (readiness != null)
            _KeyValue(label: 'Preview', value: readiness.libraryStatusLabel),
```

## Tests Ajoutés / Modifiés

Extrait Builder :

```dart
testWidgets(
    'shows cinematic stage preview readiness checklist without starting preview',
    (tester) async {
  _setLargeSurface(tester);
  final project = _project(cinematics: [_stageContextCinematic()]);
  await _pumpBuilderHarness(tester, project, 'cinematic_stage_context');

  expect(find.text('Préparation preview'), findsOneWidget);
  expect(find.text('Contexte incomplet'), findsWidgets);
  expect(find.textContaining('La preview réelle arrivera plus tard.'),
      findsWidgets);
  for (final label in <String>[
    'Map de scène',
    'Décor',
    'Acteurs liés',
    'Positions initiales',
    'Cibles de mouvement',
    'Sources map-aware',
  ]) {
    expect(find.textContaining(label), findsWidgets);
  }
  expect(find.textContaining('À compléter'), findsWidgets);
  expect(find.textContaining('À venir'), findsWidgets);
  expect(find.text('Lecture en cours'), findsNothing);
  for (final key in <String>[
    'cinematic-builder-transport-reset-button',
    'cinematic-builder-transport-play-button',
    'cinematic-builder-transport-stop-button',
  ]) {
    final button = tester.widget<PokeMapButton>(
      find.byKey(ValueKey<String>(key)),
    );
    expect(button.onPressed, isNull);
  }
});
```

Extrait Visual Gate :

```dart
testWidgets(
    'captures V1-74 cinematic stage preview readiness polish when requested',
    (tester) async {
  if (!const bool.fromEnvironment(
    'NS_SCENES_V1_74_CAPTURE_CINEMATIC_STAGE_PREVIEW_READINESS',
  )) {
    return;
  }

  _setLargeSurface(tester, _referenceTimelineSurfaceSize);
  await _loadScreenshotFonts();
  final project = _project(cinematics: [_stageContextCinematic()]);

  await _pumpBuilderHarness(
    tester,
    project,
    'cinematic_stage_context',
    surfaceSize: _referenceTimelineSurfaceSize,
  );

  expect(find.text('Aperçu sandbox'), findsOneWidget);
  expect(find.text('Contexte de scène'), findsOneWidget);
  expect(find.text('Préparation preview'), findsOneWidget);
  expect(find.text('Contexte incomplet'), findsWidgets);
  expect(find.textContaining('La preview réelle arrivera plus tard.'),
      findsWidgets);
  expect(find.textContaining('Map de scène — OK'), findsWidgets);
  expect(find.textContaining('Décor — OK'), findsWidgets);
  expect(find.textContaining('Acteurs liés — À compléter'), findsWidgets);
  expect(
      find.textContaining('Positions initiales — À compléter'), findsWidgets);
  expect(
      find.textContaining('Cibles de mouvement — À compléter'), findsWidgets);
  expect(find.textContaining('Sources map-aware — À venir'), findsWidgets);
  expect(find.text('Lab map'), findsWidgets);
  expect(find.text('Décor depuis la map'), findsWidgets);
  expect(find.text('Acteurs'), findsWidgets);
  expect(find.text('Binding'), findsWidgets);
  expect(find.text('Positions initiales'), findsWidgets);
  expect(find.text('Cibles de mouvement'), findsWidgets);
  expect(find.text('Timeline par pistes'), findsOneWidget);
  expect(find.text('Preview réelle à venir.'), findsWidgets);
  expect(find.text('Lecture en cours'), findsNothing);
  for (final key in <String>[
    'cinematic-builder-transport-reset-button',
    'cinematic-builder-transport-play-button',
    'cinematic-builder-transport-stop-button',
  ]) {
    final button = tester.widget<PokeMapButton>(
      find.byKey(ValueKey<String>(key)),
    );
    expect(button.onPressed, isNull);
  }
  expect(tester.takeException(), isNull);
```

Extrait Library :

```dart
expect(find.text('Preview'), findsOneWidget);
expect(find.text('sandbox uniquement'), findsOneWidget);

testWidgets('shows preview readiness summary for incomplete stage context',
    (tester) async {
  _setLargeSurface(tester);
  await tester.pumpWidget(
    _Harness(
      project: _project(
        cinematics: [
          CinematicAsset(
            id: 'cinematic_stage_preview_summary',
            title: 'Stage preview summary cinematic',
            mapId: 'map_lab',
            requiredActors: [
              CinematicActorRef(
                actorId: 'actor_professor',
                label: 'Professor',
              ),
            ],
            movementTargets: [
              CinematicMovementTargetRef(
                targetId: 'target_center',
                label: 'Centre scène',
              ),
            ],
            stageContext: CinematicStageContext(
              backdropMode: CinematicStageBackdropMode.projectMap,
            ),
            timeline: CinematicTimeline(
              steps: [
                CinematicTimelineStep(
                  id: 'step_wait',
                  kind: CinematicTimelineStepKind.wait,
                  label: 'Beat',
                  durationMs: 500,
                ),
              ],
            ),
          ),
        ],
        includeBridge: false,
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('Preview'), findsOneWidget);
  expect(find.text('contexte incomplet'), findsOneWidget);
});
```

## Commandes de Validation

### map_core

Commande :

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_asset_test.dart && dart test --reporter=compact test/project_manifest_cinematics_test.dart && dart test --reporter=compact test/cinematic_authoring_operations_test.dart && dart test --reporter=compact test/cinematic_diagnostics_test.dart && dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart && dart test --reporter=compact test/cinematic_timeline_lane_read_model_test.dart && dart analyze
```

Sorties utiles :

```text
test/cinematic_asset_test.dart: All tests passed!
test/project_manifest_cinematics_test.dart: All tests passed!
test/cinematic_authoring_operations_test.dart: All tests passed!
test/cinematic_diagnostics_test.dart: All tests passed!
test/cinematic_timeline_time_layout_read_model_test.dart: All tests passed!
test/cinematic_timeline_lane_read_model_test.dart: All tests passed!
Analyzing map_core...
No issues found!
```

### map_editor tests

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Sortie utile :

```text
+125: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
```

Sortie utile :

```text
+12: All tests passed!
```

### Visual Gate V1-74

Commande :

```bash
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_74_CAPTURE_CINEMATIC_STAGE_PREVIEW_READINESS=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

Sortie utile :

```text
+125: All tests passed!
```

Capture :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_74_cinematic_stage_context_diagnostics_preview_readiness_polish_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
SHA-256: 48db68dcf42c568593a60f1f29d676c09755f26500ba3b6679f788efe3f37e51
```

### Analyse ciblée map_editor

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
```

Sortie :

```text
Analyzing 6 items...
No issues found! (ran in 1.8s)
```

### Analyse globale map_editor

Commande :

```bash
cd packages/map_editor && flutter analyze
```

Sortie utile :

```text
Analyzing map_editor...
344 issues found. (ran in 2.9s)
```

Premiers bloqueurs hors lot :

```text
error • The named parameter 'dbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7 • undefined_named_parameter
error • The named parameter 'battleEngineAimedTarget' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:64:7 • undefined_named_parameter
error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
```

## Anti-scope

- Aucun fichier `packages/map_runtime`, `packages/map_gameplay`, `packages/map_battle` ou `examples/playable_runtime_host` n'a été modifié.
- Aucun `PlayableMapGame`, `SceneCinematicRuntimeAwaitableAdapter`, playback, timer, `currentTimeMs`, `playbackTimeMs`, `isPlaying`, pathfinding, collision, warp, spawn ou donnée Selbrume ajouté.
- Aucun champ `stageContext.mapId` n'est ajouté au modèle ; un test vérifie que ce libellé n'est pas exposé dans l'UI.

Commandes :

```bash
rg -n "currentTimeMs|playbackTimeMs|isPlaying|PlayableMapGame|SceneCinematicRuntimeAwaitableAdapter|pathfinding|collision|warp|spawn|Selbrume" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart || true
git diff --name-only | rg "^(packages/(map_runtime|map_gameplay|map_battle)|examples/playable_runtime_host)/" || true
```

Sorties :

```text
<aucune sortie>
<aucune sortie>
```

## Checks Git Finaux

### git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
<aucune sortie>
```

### git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../cinematics/cinematic_builder_workspace.dart    | 1009 ++++++++++++++-
 .../cinematics/cinematics_library_workspace.dart   |  119 +-
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  126 ++
 .../test/cinematic_builder_workspace_test.dart     | 1301 +++++++++++++++++++-
 .../test/cinematics_library_workspace_test.dart    |  149 +++
 .../scenes/road_map_scene_builder_authoring.md     |   30 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |   38 +-
 7 files changed, 2748 insertions(+), 24 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers untracked ; ils sont visibles dans le statut ci-dessous.

### git diff --name-only

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

### git status --short --untracked-files=all

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_73_cinematic_stage_map_context_editor_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_73_evidence_pack.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_74_cinematic_stage_context_diagnostics_preview_readiness_polish_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_74_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_73_cinematic_stage_map_context_editor_v0.png
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_74_cinematic_stage_context_diagnostics_preview_readiness_polish_v0.png
```

## Prochain Lot

`NS-SCENES-V1-75 — Cinematic Map Entity/Event Source Audit / Picker Prep Contract`
