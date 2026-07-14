import 'package:flutter/widgets.dart' show Text, ValueKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_controller.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_transaction.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_preview_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/shared/inspector_section_card.dart';

import 'shell_chrome_test_harness.dart';

void main() {
  testWidgets('MapInspector presents Border as a dedicated active layer',
      (tester) async {
    final project = _project(<BorderBlueprintRecord>[_record('coast-a')]);
    const map = MapData(
      id: 'map',
      name: 'Border Map',
      version: ProjectVersion.v2,
      size: GridSize(width: 4, height: 3),
      layers: <MapLayer>[
        MapLayer.border(id: 'border', name: 'Côte'),
      ],
    );

    await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/border_inspector_project',
        project: project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: map,
        activeLayerId: 'border',
      ),
    );

    expect(find.text('Actif : Calque de bordure'), findsOneWidget);
    expect(find.text('Calque de bordure actif'), findsOneWidget);
    expect(find.text('Visuel uniquement — aucune collision'), findsOneWidget);
    expect(find.textContaining('Calque de collision actif'), findsNothing);
    expect(find.textContaining('Calque de surface actif'), findsNothing);

    final titles = tester
        .widgetList<InspectorSectionCard>(find.byType(InspectorSectionCard))
        .map((card) => card.title)
        .toList(growable: false);
    expect(titles.indexOf('Bordures'), titles.indexOf('Calques') + 1);
  });

  testWidgets(
      'Border inspector exposes published CRUD and confirms compatible blueprint changes',
      (tester) async {
    final project = _project(<BorderBlueprintRecord>[
      _record('coast-a', name: 'Côte A'),
      _record('coast-b', name: 'Côte B'),
      _record(
        'wall',
        name: 'Muret',
        template: BorderBlueprintTemplate.masonryLine,
      ),
      _record('draft', name: 'Brouillon', published: false),
      _record('old', name: 'Ancienne', isDeprecated: true),
    ]);
    final map = MapData(
      id: 'map',
      name: 'Border Map',
      version: ProjectVersion.v2,
      size: const GridSize(width: 4, height: 3),
      layers: <MapLayer>[
        MapLayer.border(
          id: 'border',
          name: 'Côte',
          opacity: 0.8,
          content: BorderLayerContent(
            features: <BorderFeature>[
              BorderFeature(
                id: 'feature',
                name: 'Rivage',
                blueprintId: 'coast-a',
                seed: BorderSignedInt64.zero,
                geometry: BorderRegionGeometry(
                  width: 4,
                  height: 3,
                  cells: List<bool>.filled(12, false),
                ),
                overrides: const <BorderSlotOverride>[],
                keepOutRegions: const <BorderKeepOutRegion>[],
                materialization: _materialization(),
              ),
            ],
          ),
        ),
      ],
    );

    final container = await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/border_inspector_crud',
        project: project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: map,
        activeLayerId: 'border',
      ),
    );

    expect(find.byKey(const ValueKey('border-create-feature-button')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('border-feature-feature')), findsOneWidget);
    expect(find.byKey(const ValueKey('border-rename-feature-button')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('border-move-feature-up-button')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('border-move-feature-down-button')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('border-delete-feature-button')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('border-layer-opacity-slider')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('border-layer-visibility-button')),
        findsOneWidget);

    final createPicker = tester.widget<PokeMapDropdownField<String>>(
      find.byKey(const ValueKey('border-blueprint-create-picker')),
    );
    expect(
      createPicker.items.map((item) => item.value),
      containsAll(<String>['coast-a', 'coast-b', 'wall']),
    );
    expect(
        createPicker.items.map((item) => item.value), isNot(contains('draft')));
    expect(
        createPicker.items.map((item) => item.value), isNot(contains('old')));

    final beforeJson =
        container.read(editorNotifierProvider).activeMap!.toJson();
    final changePicker = tester.widget<PokeMapDropdownField<String>>(
      find.byKey(const ValueKey('border-blueprint-change-picker')),
    );
    changePicker.onChanged('coast-b');
    await tester.pump();

    expect(
        container.read(editorNotifierProvider).activeMap!.toJson(), beforeJson);
    expect(find.text('Avant : Côte A'), findsOneWidget);
    expect(find.text('Après : Côte B'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('border-blueprint-before-state')),
        matching: find.textContaining('Contour organique'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('border-blueprint-before-state')),
        matching: find.textContaining('Matérialisée'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('border-blueprint-after-state')),
        matching: find.textContaining('Non matérialisée'),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('border-blueprint-consequence')),
          )
          .data,
      contains('matérialisation'),
    );
    final confirmButton = tester.widget<PokeMapButton>(
      find.byKey(const ValueKey('border-confirm-blueprint-change')),
    );
    expect(confirmButton.onPressed, isNotNull);
    confirmButton.onPressed!.call();
    await tester.pumpAndSettle();
    expect(find.text('Confirmer le changement de blueprint'), findsOneWidget);
    expect(
        container.read(editorNotifierProvider).activeMap!.toJson(), beforeJson);

    await tester.tap(find.text('Changer le blueprint'));
    await tester.pumpAndSettle();
    final changed = container
        .read(editorNotifierProvider)
        .activeMap!
        .layers
        .whereType<BorderLayer>()
        .single
        .content
        .features
        .single;
    expect(changed.blueprintId, 'coast-b');
    expect(changed.materialization, isNull);

    final updatedPicker = tester.widget<PokeMapDropdownField<String>>(
      find.byKey(const ValueKey('border-blueprint-change-picker')),
    );
    updatedPicker.onChanged('wall');
    await tester.pump();
    expect(find.textContaining('région'), findsWidgets);
    expect(find.textContaining('ligne'), findsWidgets);
    final createSeparate = tester.widget<PokeMapButton>(
      find.byKey(
        const ValueKey('border-create-feature-from-blueprint-change'),
      ),
    );
    final resetCurrent = tester.widget<PokeMapButton>(
      find.byKey(const ValueKey('border-reset-blueprint-change')),
    );
    expect(createSeparate.onPressed, isNotNull);
    expect(resetCurrent.onPressed, isNotNull);
    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(const ValueKey('border-confirm-blueprint-change')),
          )
          .onPressed,
      isNull,
    );

    resetCurrent.onPressed!.call();
    await tester.pumpAndSettle();
    expect(find.text('Remettre la bordure à zéro'), findsOneWidget);
    expect(
      container
          .read(editorNotifierProvider)
          .activeMap!
          .layers
          .whereType<BorderLayer>()
          .single
          .content
          .features
          .single
          .blueprintId,
      'coast-b',
      reason: 'the destructive reset must wait for explicit confirmation',
    );

    await tester.tap(find.text('Remettre à zéro'));
    await tester.pumpAndSettle();
    final reset = container
        .read(editorNotifierProvider)
        .activeMap!
        .layers
        .whereType<BorderLayer>()
        .single
        .content
        .features
        .single;
    expect(reset.blueprintId, 'wall');
    expect(reset.geometry, isA<BorderStrokeGeometry>());
    expect((reset.geometry as BorderStrokeGeometry).strokes, isEmpty);
    expect(reset.overrides, isEmpty);
    expect(reset.keepOutRegions, isEmpty);
    expect(reset.materialization, isNull);
  });

  testWidgets(
      'resolved Border preview exposes variation and Apply then leaves the preview flow',
      (tester) async {
    final fixture = _previewFixture();
    final preview = BorderPreviewController(
      resolver: _successfulPreview,
      applier: ({required map, required transaction}) =>
          map.copyWith(name: 'Aperçu appliqué'),
    );
    final container = await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/border_preview_actions',
        project: fixture.project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: fixture.map,
        activeMapPath: '/tmp/border_preview_actions/map.json',
        activeLayerId: 'border',
      ),
      overrides: <Override>[
        borderPreviewControllerProvider.overrideWith((ref) => preview),
      ],
    );
    _resolvePreview(
      preview,
      fixture,
      projectRootPath: '/tmp/border_preview_actions',
      activeMapPath: '/tmp/border_preview_actions/map.json',
    );
    final initialSeed = preview.state.transaction!.proposedFeature.seed;
    await tester.pump();

    final apply = tester.widget<PokeMapButton>(
      find.byKey(const ValueKey('border-preview-apply-button')),
    );
    final cancel = tester.widget<PokeMapButton>(
      find.byKey(const ValueKey('border-preview-cancel-button')),
    );
    final variation = tester.widget<PokeMapButton>(
      find.byKey(const ValueKey('border-preview-variation-button')),
    );
    expect(apply.onPressed, isNotNull);
    expect(cancel.onPressed, isNotNull);
    expect(variation.onPressed, isNotNull);
    expect(find.text('Aperçu prêt à appliquer'), findsOneWidget);

    variation.onPressed!.call();
    await tester.pump();
    expect(preview.state.phase, BorderPreviewPhase.resolved);
    expect(preview.state.transaction!.proposedFeature.seed, isNot(initialSeed));

    apply.onPressed!.call();
    await tester.pump();
    expect(preview.state, const BorderPreviewState.idle());
    expect(
      find.byKey(const ValueKey('border-preview-actions')),
      findsNothing,
    );
    expect(container.read(editorNotifierProvider).activeMap!.name,
        'Aperçu appliqué');
    expect(container.read(editorNotifierProvider).mapUndoStack, hasLength(1));
    expect(find.byKey(const ValueKey('border-feature-coast')), findsOneWidget);
  });

  testWidgets(
      'invalid Border preview explains disabled Apply and Cancel exits without mutation',
      (tester) async {
    final fixture = _previewFixture();
    final before = fixture.map.toJson();
    final preview = BorderPreviewController(
      resolver: (_) => BorderResolutionResult(
        materialization: null,
        diagnosticReport: BorderDiagnosticsReport(
          diagnostics: <BorderDiagnostic>[
            BorderDiagnostic(
              code: 'border.test.invalid_preview',
              severity: BorderDiagnosticSeverity.error,
              phase: BorderDiagnosticPhase.resolution,
              scope: BorderDiagnosticScope.feature,
              featureId: 'coast',
              suggestedAction: 'border.action.edit_geometry',
            ),
          ],
        ),
      ),
    );
    final container = await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/border_preview_invalid',
        project: fixture.project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: fixture.map,
        activeMapPath: '/tmp/border_preview_invalid/map.json',
        activeLayerId: 'border',
      ),
      overrides: <Override>[
        borderPreviewControllerProvider.overrideWith((ref) => preview),
      ],
    );
    _resolvePreview(
      preview,
      fixture,
      projectRootPath: '/tmp/border_preview_invalid',
      activeMapPath: '/tmp/border_preview_invalid/map.json',
    );
    final initialSeed = preview.state.transaction!.proposedFeature.seed;
    await tester.pump();

    expect(find.text('Aperçu invalide'), findsOneWidget);
    expect(find.textContaining('1 diagnostic'), findsOneWidget);
    expect(find.textContaining('Corrigez'), findsOneWidget);
    expect(find.text('Diagnostic de bordure à vérifier.'), findsOneWidget);
    expect(find.text('border.test.invalid_preview'), findsNothing);
    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(const ValueKey('border-preview-apply-button')),
          )
          .onPressed,
      isNull,
    );
    final variation = tester.widget<PokeMapButton>(
      find.byKey(const ValueKey('border-preview-variation-button')),
    );
    final cancel = tester.widget<PokeMapButton>(
      find.byKey(const ValueKey('border-preview-cancel-button')),
    );
    expect(variation.onPressed, isNotNull);
    expect(cancel.onPressed, isNotNull);

    variation.onPressed!.call();
    await tester.pump();
    expect(preview.state.phase, BorderPreviewPhase.invalid);
    expect(preview.state.transaction!.proposedFeature.seed, isNot(initialSeed));
    cancel.onPressed!.call();
    await tester.pump();

    expect(preview.state, const BorderPreviewState.idle());
    expect(container.read(editorNotifierProvider).activeMap!.toJson(), before);
    expect(container.read(editorNotifierProvider).mapUndoStack, isEmpty);
    expect(
      find.byKey(const ValueKey('border-preview-actions')),
      findsNothing,
    );
  });

  testWidgets('invalid preview lists every actionable diagnostic',
      (tester) async {
    final fixture = _previewFixture();
    final preview = BorderPreviewController(
      resolver: (_) => BorderResolutionResult(
        materialization: null,
        diagnosticReport: BorderDiagnosticsReport(
          diagnostics: <BorderDiagnostic>[
            _previewDiagnostic('border.resolution.anchor_outside_asset'),
            _previewDiagnostic('border.resolution.coverage_gap'),
            _previewDiagnostic('border.resolution.ground_snapshot_missing'),
            _previewDiagnostic('border.resolution.orientation_unavailable'),
            _previewDiagnostic('border.resolution.visual_snapshot_invalid'),
          ],
        ),
      ),
    );
    await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/border_preview_diagnostics',
        project: fixture.project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: fixture.map,
        activeMapPath: '/tmp/border_preview_diagnostics/map.json',
        activeLayerId: 'border',
      ),
      overrides: <Override>[
        borderPreviewControllerProvider.overrideWith((ref) => preview),
      ],
    );
    _resolvePreview(
      preview,
      fixture,
      projectRootPath: '/tmp/border_preview_diagnostics',
      activeMapPath: '/tmp/border_preview_diagnostics/map.json',
    );
    await tester.pump();

    expect(find.textContaining('5 diagnostics'), findsOneWidget);
    expect(
      find.text('Replacez l’ancre de l’élément à l’intérieur de son visuel.'),
      findsOneWidget,
    );
    expect(
      find.text(
          'Republiez le visuel absent ou invalide utilisé par le blueprint.'),
      findsOneWidget,
      reason: 'the fifth diagnostic must not be silently truncated',
    );
  });
}

BorderDiagnostic _previewDiagnostic(String code) => BorderDiagnostic(
      code: code,
      severity: BorderDiagnosticSeverity.error,
      phase: BorderDiagnosticPhase.resolution,
      scope: BorderDiagnosticScope.feature,
      featureId: 'coast',
      suggestedAction: 'border.action.edit_geometry',
    );

({ProjectManifest project, MapData map}) _previewFixture() {
  final project = _project(<BorderBlueprintRecord>[
    _record('coast-a', name: 'Côte A'),
  ]);
  final map = MapData(
    id: 'map',
    name: 'Border preview map',
    version: ProjectVersion.v2,
    size: const GridSize(width: 4, height: 3),
    layers: <MapLayer>[
      MapLayer.border(
        id: 'border',
        name: 'Côte',
        content: BorderLayerContent(
          features: <BorderFeature>[
            BorderFeature(
              id: 'coast',
              name: 'Rivage',
              blueprintId: 'coast-a',
              seed: BorderSignedInt64.fromInt(7),
              geometry: BorderRegionGeometry(
                width: 4,
                height: 3,
                cells: List<bool>.filled(12, false),
              ),
              overrides: const <BorderSlotOverride>[],
              keepOutRegions: const <BorderKeepOutRegion>[],
            ),
          ],
        ),
      ),
    ],
  );
  return (project: project, map: map);
}

void _resolvePreview(
  BorderPreviewController preview,
  ({ProjectManifest project, MapData map}) fixture, {
  required String projectRootPath,
  required String activeMapPath,
}) {
  preview.begin(
    map: fixture.map,
    layerId: 'border',
    featureId: 'coast',
    context: createEditorBorderPreviewContext(
      projectRootPath: projectRootPath,
      activeMapPath: activeMapPath,
      project: fixture.project,
      map: fixture.map,
    ),
  );
  preview.updateGeometry(
    BorderRegionGeometry(
      width: 4,
      height: 3,
      cells: const <bool>[
        true,
        true,
        false,
        false,
        true,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
      ],
    ),
  );
  preview.resolve(
    blueprintRevision:
        fixture.project.borderCatalog.recordById('coast-a')!.latestPublished!,
    tileSizePx: const GridSize(width: 16, height: 16),
    visualSnapshots: const <BorderVisualSnapshot>[],
    resolverVersion: 1,
  );
}

BorderResolutionResult _successfulPreview(BorderResolutionRequest _) =>
    BorderResolutionResult(
      materialization: _materialization(),
      diagnosticReport: const BorderDiagnosticsReport.empty(),
    );

ProjectManifest _project(List<BorderBlueprintRecord> records) =>
    ProjectManifest(
      name: 'Border Inspector',
      version: ProjectVersion.v2,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      borderCatalog: ProjectBorderCatalog(records: records),
    );

BorderBlueprintRecord _record(
  String id, {
  String? name,
  BorderBlueprintTemplate template = BorderBlueprintTemplate.organicEdge,
  bool published = true,
  bool isDeprecated = false,
}) {
  final draft = BorderBlueprintDraftDefinition(
    name: name ?? id,
    previewSeed: BorderSignedInt64.zero,
    template: template,
    primitives: const <BorderPrimitiveDraft>[],
    defaults: _params(),
    sortOrder: 0,
  );
  return BorderBlueprintRecord(
    id: id,
    draft: BorderBlueprintDraft(
      baseRevision: published ? 1 : 0,
      definition: draft,
    ),
    latestPublished: published
        ? BorderBlueprintRevision(
            revision: 1,
            definition: BorderBlueprintPublishedDefinition(
              name: name ?? id,
              previewSeed: BorderSignedInt64.zero,
              template: template,
              primitives: const <BorderPublishedPrimitive>[],
              defaults: _params(),
              sortOrder: 0,
            ),
          )
        : null,
    isDeprecated: isDeprecated,
  );
}

BorderGenerationParams _params() => BorderGenerationParams(
      irregularityPermille: 0,
      detailDensityPermille: 0,
      variationPermille: 0,
      maxOverlapPx: 0,
      gapTolerancePx: 0,
      depthRows: 1,
    );

BorderMaterialization _materialization() => BorderMaterialization(
      receipt: BorderResolutionReceipt(
        resolverVersion: 1,
        blueprintRevision: 1,
        components: BorderInputFingerprints(
          blueprint:
              'sha256:0000000000000000000000000000000000000000000000000000000000000000',
          geometryAndSeed:
              'sha256:1111111111111111111111111111111111111111111111111111111111111111',
          parameters:
              'sha256:2222222222222222222222222222222222222222222222222222222222222222',
          overrides:
              'sha256:3333333333333333333333333333333333333333333333333333333333333333',
          keepOutRegions:
              'sha256:4444444444444444444444444444444444444444444444444444444444444444',
          mapContext:
              'sha256:5555555555555555555555555555555555555555555555555555555555555555',
          visualSnapshots:
              'sha256:6666666666666666666666666666666666666666666666666666666666666666',
        ),
        inputFingerprint:
            'sha256:7777777777777777777777777777777777777777777777777777777777777777',
        outputFingerprint:
            'sha256:8888888888888888888888888888888888888888888888888888888888888888',
      ),
      ground: <BorderResolvedGroundCell>[
        BorderResolvedGroundCell(
          x: 0,
          y: 0,
          visualSnapshotId:
              'border-snapshot-sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          resolvedRole: SurfaceVariantRole.isolated,
        ),
      ],
      placements: const <BorderResolvedPlacement>[],
    );
