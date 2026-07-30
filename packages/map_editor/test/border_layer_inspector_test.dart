import 'package:flutter/widgets.dart' show Text, ValueKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_controller.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_transaction.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_preview_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
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

    final legacyPaintButton = tester.widget<PokeMapButton>(
      find.byKey(const ValueKey('border-inspector-paint-button')),
    );
    expect(legacyPaintButton.onPressed, isNotNull);
    legacyPaintButton.onPressed!.call();
    await tester.pump();
    expect(
      container.read(editorNotifierProvider).activeTool,
      EditorToolType.borderPaint,
    );
    final legacyEraseButton = tester.widget<PokeMapButton>(
      find.byKey(const ValueKey('border-inspector-erase-button')),
    );
    expect(legacyEraseButton.onPressed, isNotNull);
    legacyEraseButton.onPressed!.call();
    await tester.pump();
    expect(
      container.read(editorNotifierProvider).activeTool,
      EditorToolType.borderErase,
    );

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
        matching: find.textContaining('Matérialisée'),
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
    expect(changed.materialization, isNotNull);

    final updatedPicker = tester.widget<PokeMapDropdownField<String>>(
      find.byKey(const ValueKey('border-blueprint-change-picker')),
    );
    updatedPicker.onChanged('wall');
    await tester.pump();
    expect(find.textContaining('région'), findsWidgets);
    expect(find.textContaining('ligne'), findsWidgets);
    expect(
      find.byKey(const ValueKey('border-relink-loss-geometry')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('border-relink-loss-materialization')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('border-relink-loss-parameters')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('border-relink-loss-overrides')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('border-relink-loss-keepOutRegions')),
      findsNothing,
    );
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
    expect(find.text('Tracer la ligne'), findsOneWidget);
    expect(find.text('Créer une ouverture'), findsOneWidget);
    expect(find.text('Peindre le contour'), findsNothing);
  });

  testWidgets('two-tier stone features show separate top and face metrics',
      (tester) async {
    final project = _project(<BorderBlueprintRecord>[_twoTierStoneRecord()]);
    final map = MapData(
      id: 'stone-map',
      name: 'Falaise',
      version: ProjectVersion.v2,
      size: const GridSize(width: 8, height: 4),
      layers: <MapLayer>[
        MapLayer.border(
          id: 'border',
          name: 'Falaise',
          content: BorderLayerContent(
            features: <BorderFeature>[
              BorderFeature(
                id: 'cliff',
                name: 'Falaise du port',
                blueprintId: 'two-tier',
                seed: BorderSignedInt64.zero,
                geometry: BorderStrokeGeometry(
                  strokes: <BorderStroke>[
                    BorderStroke(
                      id: 'shore',
                      points: const <GridPos>[
                        GridPos(x: 1, y: 1),
                        GridPos(x: 2, y: 1),
                        GridPos(x: 3, y: 1),
                        GridPos(x: 4, y: 1),
                        GridPos(x: 5, y: 1),
                        GridPos(x: 6, y: 1),
                      ],
                      closed: false,
                    ),
                  ],
                ),
                overrides: const <BorderSlotOverride>[],
                keepOutRegions: const <BorderKeepOutRegion>[],
                materialization: _twoTierStoneMaterialization(),
              ),
            ],
          ),
        ),
      ],
    );

    await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/border_inspector_two_tier',
        project: project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: map,
        activeLayerId: 'border',
      ),
    );

    expect(find.text('Sommet : 3 pierres'), findsOneWidget);
    expect(find.text('Face : 2 pierres'), findsOneWidget);
    expect(find.text('Profondeur médiane : 24 px'), findsOneWidget);
    expect(find.text('Gap maximal du sommet : 2 px'), findsOneWidget);
    expect(find.text('Gap maximal de la face : 2 px'), findsOneWidget);
    expect(find.textContaining('border.resolution.'), findsNothing);
  });

  testWidgets(
      'Border inspector keeps lifecycle and local corrections preview-only until shared Apply',
      (tester) async {
    final project = _project(<BorderBlueprintRecord>[
      _record('coast-a', name: 'Côte A'),
    ]);
    final feature = BorderFeature(
      id: 'feature',
      name: 'Rivage',
      blueprintId: 'coast-a',
      seed: BorderSignedInt64.fromInt(7),
      geometry: BorderRegionGeometry(
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
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
      materialization: _materialization(),
    );
    final map = MapData(
      id: 'map',
      name: 'Border Map',
      version: ProjectVersion.v2,
      size: const GridSize(width: 4, height: 3),
      layers: <MapLayer>[
        MapLayer.border(
          id: 'border',
          name: 'Côte',
          content: BorderLayerContent(features: <BorderFeature>[feature]),
        ),
      ],
    );
    final before = map.toJson();
    final container = await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/border_local_corrections',
        project: project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: map,
        activeMapPath: '/tmp/border_local_corrections/map.json',
        activeLayerId: 'border',
      ),
    );

    expect(
      find.byKey(const ValueKey('border-invert-side-button')),
      findsNothing,
    );

    final update = tester.widget<PokeMapButton>(
      find.byKey(const ValueKey('border-update-preview-button')),
    );
    final keep = tester.widget<PokeMapButton>(
      find.byKey(const ValueKey('border-keep-materialized-button')),
    );
    expect(update.onPressed, isNotNull);
    expect(keep.onPressed, isNotNull);
    expect(find.text('Update preview'), findsOneWidget);
    expect(find.text('Conserver la matérialisation'), findsOneWidget);

    update.onPressed!.call();
    await tester.pump();
    expect(
      container.read(borderPreviewControllerProvider).phase,
      BorderPreviewPhase.resolved,
    );
    expect(container.read(editorNotifierProvider).activeMap, same(map));
    expect(container.read(editorNotifierProvider).activeMap!.toJson(), before);
    expect(container.read(editorNotifierProvider).mapUndoStack, isEmpty);

    keep.onPressed!.call();
    await tester.pump();
    expect(
      container.read(borderPreviewControllerProvider),
      const BorderPreviewState.idle(),
    );
    expect(container.read(editorNotifierProvider).activeMap, same(map));
    expect(container.read(editorNotifierProvider).mapUndoStack, isEmpty);

    final slotPicker = tester.widget<PokeMapDropdownField<String>>(
      find.byKey(const ValueKey('border-local-slot-picker')),
    );
    expect(slotPicker.items, hasLength(1));
    expect(slotPicker.items.single.label, contains('Emplacement 1'));
    expect(slotPicker.items.single.label, isNot(contains('slot-a')));
    for (final key in <String>[
      'border-local-variation-button',
      'border-local-replace-button',
      'border-local-move-button',
      'border-local-remove-button',
      'border-local-lock-button',
      'border-local-keep-out-button',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget);
      expect(
        tester.widget<PokeMapButton>(find.byKey(ValueKey(key))).onPressed,
        isNotNull,
      );
    }
    expect(find.text('Nouvelle variation locale'), findsOneWidget);
    expect(find.text('Remplacer'), findsOneWidget);
    expect(find.text('Déplacer'), findsOneWidget);
    expect(find.text('Retirer'), findsOneWidget);
    expect(find.text('Verrouiller'), findsOneWidget);
    expect(find.text('Zone interdite'), findsOneWidget);

    tester
        .widget<PokeMapButton>(
          find.byKey(const ValueKey('border-local-variation-button')),
        )
        .onPressed!
        .call();
    await tester.pump();

    final preview = container.read(borderPreviewControllerProvider);
    expect(preview.phase, BorderPreviewPhase.resolved);
    expect(preview.transaction!.proposedFeature.overrides, hasLength(1));
    expect(container.read(editorNotifierProvider).activeMap, same(map));
    expect(container.read(editorNotifierProvider).activeMap!.toJson(), before);
    expect(container.read(editorNotifierProvider).mapUndoStack, isEmpty);

    tester
        .widget<PokeMapButton>(
          find.byKey(const ValueKey('border-preview-apply-button')),
        )
        .onPressed!
        .call();
    await tester.pump();

    final applied = container
        .read(editorNotifierProvider)
        .activeMap!
        .layers
        .whereType<BorderLayer>()
        .single
        .content
        .features
        .single;
    expect(applied.overrides, hasLength(1));
    expect(container.read(editorNotifierProvider).mapUndoStack, hasLength(1));
  });

  for (final template in <BorderBlueprintTemplate>[
    BorderBlueprintTemplate.connectedLine,
    BorderBlueprintTemplate.masonryLine,
    BorderBlueprintTemplate.stoneChainLine,
  ]) {
    final templateLabel = switch (template) {
      BorderBlueprintTemplate.connectedLine => 'connected line',
      BorderBlueprintTemplate.masonryLine => 'masonry line',
      BorderBlueprintTemplate.stoneChainLine => 'stone chain',
      _ => throw StateError('Unsupported line template: $template'),
    };
    testWidgets(
        '$templateLabel side button creates a cancellable preview without map writes',
        (tester) async {
      final project = _project(<BorderBlueprintRecord>[
        _record(
          'cliff',
          name: 'Falaise',
          template: template,
        ),
      ]);
      final map = MapData(
        id: 'map',
        name: 'Connected line map',
        version: ProjectVersion.v2,
        size: const GridSize(width: 4, height: 3),
        layers: <MapLayer>[
          MapLayer.border(
            id: 'border',
            name: 'Falaises',
            content: BorderLayerContent(
              formatVersion: template == BorderBlueprintTemplate.stoneChainLine
                  ? BorderLayerContent.formatVersionV3
                  : BorderLayerContent.formatVersionV1,
              features: <BorderFeature>[
                BorderFeature(
                  id: 'cliff-feature',
                  name: 'Falaise libre',
                  blueprintId: 'cliff',
                  seed: BorderSignedInt64.fromInt(7),
                  geometry: BorderStrokeGeometry(
                    alignment:
                        template == BorderBlueprintTemplate.stoneChainLine
                            ? BorderStrokeAlignment.gridEdges
                            : BorderStrokeAlignment.cellCenters,
                    strokes: <BorderStroke>[
                      BorderStroke(
                        id: 'stroke',
                        points: const <GridPos>[
                          GridPos(x: 0, y: 1),
                          GridPos(x: 1, y: 1),
                          GridPos(x: 2, y: 1),
                        ],
                        closed: false,
                      ),
                    ],
                  ),
                  overrides: const <BorderSlotOverride>[],
                  keepOutRegions: const <BorderKeepOutRegion>[],
                ),
              ],
            ),
          ),
        ],
      );
      final preview = BorderPreviewController(
        resolver: (_) => BorderResolutionResult(
          materialization: _materialization(),
          diagnosticReport: const BorderDiagnosticsReport.empty(),
        ),
      );
      final before = map.toJson();
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/connected_line_side',
          project: project,
          workspaceMode: EditorWorkspaceMode.map,
          activeMap: map,
          activeMapPath: '/tmp/connected_line_side/map.json',
          activeLayerId: 'border',
        ),
        overrides: <Override>[
          borderPreviewControllerProvider.overrideWith((ref) => preview),
        ],
      );

      expect(find.text('Côté principal'), findsOneWidget);
      if (template == BorderBlueprintTemplate.stoneChainLine) {
        expect(
          find.text(
            'Déplace les pierres de l\'autre côté du tracé sans retourner leurs pixels.',
          ),
          findsOneWidget,
        );
      }
      final invert = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('border-invert-side-button')),
      );
      expect(invert.onPressed, isNotNull);

      invert.onPressed!.call();
      await tester.pump();

      expect(preview.state.phase, BorderPreviewPhase.resolved);
      expect(
        preview.state.transaction!.proposedFeature.lineSide,
        BorderLineSide.inverted,
      );
      expect(find.text('Côté inversé'), findsOneWidget);
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('border-invert-side-button')),
            )
            .onPressed,
        isNotNull,
        reason:
            'A resolved draw must remain invertible before its first Apply.',
      );
      expect(container.read(editorNotifierProvider).activeMap, same(map));
      expect(
          container.read(editorNotifierProvider).activeMap!.toJson(), before);
      expect(container.read(editorNotifierProvider).mapUndoStack, isEmpty);

      tester
          .widget<PokeMapButton>(
            find.byKey(const ValueKey('border-preview-cancel-button')),
          )
          .onPressed!
          .call();
      await tester.pump();

      expect(preview.state, const BorderPreviewState.idle());
      expect(
          container.read(editorNotifierProvider).activeMap!.toJson(), before);
      expect(container.read(editorNotifierProvider).mapUndoStack, isEmpty);
    });
  }

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

  testWidgets(
      'Border inspector localizes resize feedback only for its map identity',
      (tester) async {
    final fixture = _previewFixture();
    final container = await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/border_resize_feedback',
        project: fixture.project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: fixture.map,
        activeLayerId: 'border',
      ),
    );
    container.read(borderResizeFeedbackProvider.notifier).state =
        BorderResizeFeedback(
      mapIdentity: fixture.map,
      diagnosticReport: BorderDiagnosticsReport(
        diagnostics: <BorderDiagnostic>[
          BorderDiagnostic(
            code: 'region_cell_clipped',
            severity: BorderDiagnosticSeverity.warning,
            phase: BorderDiagnosticPhase.resize,
            scope: BorderDiagnosticScope.geometry,
            featureId: 'coast',
            cell: const GridPos(x: 3, y: 0),
            suggestedAction: 'border.resize.review_clipped_cells',
          ),
          BorderDiagnostic(
            code: 'region_padding_added',
            severity: BorderDiagnosticSeverity.info,
            phase: BorderDiagnosticPhase.resize,
            scope: BorderDiagnosticScope.geometry,
            featureId: 'coast',
            cell: const GridPos(x: 4, y: 0),
            suggestedAction: 'border.resize.review_padded_cells',
          ),
        ],
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('border-resize-diagnostics')),
      findsOneWidget,
    );
    expect(find.text('Redimensionnement de la carte'), findsOneWidget);
    expect(find.textContaining('La zone a été coupée'), findsOneWidget);
    expect(find.textContaining('La zone a été agrandie'), findsOneWidget);
    expect(find.text('region_cell_clipped'), findsNothing);

    container.read(editorNotifierProvider.notifier).state = container
        .read(editorNotifierProvider)
        .copyWith(activeMap: fixture.map.copyWith(name: 'Autre identité'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('border-resize-diagnostics')),
      findsNothing,
      reason: 'feedback must never leak to another map object',
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
      borderCatalog: ProjectBorderCatalog(
        formatVersion: records.any(
          (record) =>
              record.draft.definition.template ==
              BorderBlueprintTemplate.stoneChainLine,
        )
            ? ProjectBorderCatalog.formatVersionV3
            : records.any(
                (record) =>
                    record.draft.definition.template ==
                    BorderBlueprintTemplate.connectedLine,
              )
                ? ProjectBorderCatalog.formatVersionV2
                : ProjectBorderCatalog.formatVersionV1,
        records: records,
        visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
      ),
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
              primitives: template == BorderBlueprintTemplate.organicEdge
                  ? <BorderPublishedPrimitive>[
                      _primitive('structure'),
                      _primitive('structure-alt'),
                    ]
                  : const <BorderPublishedPrimitive>[],
              defaults: _params(),
              sortOrder: 0,
            ),
          )
        : null,
    isDeprecated: isDeprecated,
  );
}

BorderBlueprintRecord _twoTierStoneRecord() {
  final primitives = <BorderPublishedPrimitive>[
    _stonePrimitive('top', BorderPrimitiveRole.structureLarge),
    _stonePrimitive('face', BorderPrimitiveRole.structureMedium),
  ];
  final defaults = BorderGenerationParams(
    irregularityPermille: 180,
    detailDensityPermille: 0,
    variationPermille: 1000,
    maxOverlapPx: 8,
    gapTolerancePx: 0,
    depthRows: 2,
    allowAutoRotation: false,
  );
  return BorderBlueprintRecord(
    id: 'two-tier',
    draft: BorderBlueprintDraft(
      baseRevision: 1,
      definition: BorderBlueprintDraftDefinition(
        name: 'Falaise deux étages',
        previewSeed: BorderSignedInt64.zero,
        template: BorderBlueprintTemplate.stoneChainLine,
        primitives: const <BorderPrimitiveDraft>[],
        defaults: defaults,
        sortOrder: 0,
      ),
    ),
    latestPublished: BorderBlueprintRevision(
      revision: 1,
      definition: BorderBlueprintPublishedDefinition(
        name: 'Falaise deux étages',
        previewSeed: BorderSignedInt64.zero,
        template: BorderBlueprintTemplate.stoneChainLine,
        primitives: primitives,
        defaults: defaults,
        sortOrder: 0,
      ),
    ),
  );
}

BorderPublishedPrimitive _stonePrimitive(
  String id,
  BorderPrimitiveRole role,
) =>
    BorderPublishedPrimitive(
      id: id,
      sourceElementId: '$id-source',
      visualSnapshotId: _snapshotId,
      role: role,
      authoredOrientation: BorderPrimitiveOrientation.south,
      weight: 1000,
      anchorPx: const BorderPixelPos(x: 5, y: 5),
      transforms: BorderTransformPolicy(
        allowFlipX: false,
        allowedQuarterTurns: const <int>[0],
      ),
      publishedMetrics: BorderPrimitiveAssetMetrics(
        assetFingerprint: 'asset-$id',
        pixelSize: const GridSize(width: 12, height: 24),
        opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 12, height: 24),
        defaultAnchorPx: const BorderPixelPos(x: 5, y: 5),
        occupancyMaskRle: encodeBorderRleMask(
          List<bool>.filled(12 * 24, true),
        ),
      ),
    );

BorderMaterialization _twoTierStoneMaterialization() => BorderMaterialization(
      receipt: _materialization().receipt,
      ground: const <BorderResolvedGroundCell>[],
      placements: <BorderResolvedPlacement>[
        _stonePlacement('top-1', 'top', passIndex: 0, x: 0, width: 10),
        _stonePlacement('top-2', 'top', passIndex: 0, x: 10, width: 10),
        _stonePlacement('top-3', 'top', passIndex: 0, x: 22, width: 10),
        _stonePlacement(
          'face-1',
          'face',
          passIndex: 1,
          x: 0,
          width: 12,
          height: 24,
        ),
        _stonePlacement(
          'face-2',
          'face',
          passIndex: 1,
          x: 14,
          width: 12,
          height: 24,
        ),
      ],
    );

BorderResolvedPlacement _stonePlacement(
  String id,
  String primitiveId, {
  required int passIndex,
  required int x,
  required int width,
  int height = 12,
}) =>
    BorderResolvedPlacement(
      id: id,
      slotKey: 'slot-$id',
      primitiveId: primitiveId,
      visualSnapshotId: _snapshotId,
      anchorCell: GridPos(x: x ~/ 16, y: passIndex),
      topLeftWorldPx: BorderPixelPos(x: x, y: passIndex * 12),
      opaqueWorldBoundsPx: BorderPixelRect(
        x: x,
        y: passIndex * 12,
        width: width,
        height: height,
      ),
      transform: BorderSpriteTransform(quarterTurns: 0, flipX: false),
      drawBand: BorderDrawBand.structure,
      stableOrderKey: BorderStableOrderKey(
        drawBandIndex: borderDrawBandV1Index(BorderDrawBand.structure),
        anchorRowMajor: passIndex * 1000 + x,
        passIndex: passIndex,
        rank: 0,
        ordinalLocal: x,
        slotKey: 'slot-$id',
      ),
    );

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
      placements: <BorderResolvedPlacement>[
        BorderResolvedPlacement(
          id: 'placement-a',
          slotKey: 'slot-a',
          primitiveId: 'structure',
          visualSnapshotId: _snapshotId,
          anchorCell: const GridPos(x: 0, y: 0),
          topLeftWorldPx: const BorderPixelPos(x: 0, y: 0),
          opaqueWorldBoundsPx:
              BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
          transform: BorderSpriteTransform(quarterTurns: 0, flipX: false),
          drawBand: BorderDrawBand.structure,
          stableOrderKey: BorderStableOrderKey(
            drawBandIndex: borderDrawBandV1Index(BorderDrawBand.structure),
            anchorRowMajor: 0,
            passIndex: 0,
            rank: 0,
            ordinalLocal: 0,
            slotKey: 'slot-a',
          ),
        ),
      ],
    );

BorderPublishedPrimitive _primitive(String id) => BorderPublishedPrimitive(
      id: id,
      sourceElementId: '$id-source',
      visualSnapshotId: _snapshotId,
      role: BorderPrimitiveRole.structureLarge,
      weight: 1,
      anchorPx: const BorderPixelPos(x: 8, y: 8),
      transforms: BorderTransformPolicy(
        allowFlipX: true,
        allowedQuarterTurns: const <int>[0, 1, 2, 3],
      ),
      publishedMetrics: BorderPrimitiveAssetMetrics(
        assetFingerprint: 'asset-$id',
        pixelSize: const GridSize(width: 16, height: 16),
        opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
        defaultAnchorPx: const BorderPixelPos(x: 8, y: 8),
        occupancyMaskRle: encodeBorderRleMask(
          List<bool>.filled(16 * 16, true),
        ),
      ),
    );

BorderVisualSnapshot _snapshot() => BorderVisualSnapshot(
      id: _snapshotId,
      contentFingerprint: 'a' * 64,
      frames: <BorderVisualFrameSnapshot>[
        BorderVisualFrameSnapshot(
          relativeAssetPath: 'assets/borders/snapshots/a.png',
          sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
          durationMs: 100,
        ),
      ],
    );

const _snapshotId =
    'border-snapshot-sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
