import 'dart:io';
import 'dart:ui' show Size;

import 'package:flutter/widgets.dart' show ValueKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/ui/design_system/pokemap_button.dart';
import 'package:map_editor/src/ui/design_system/pokemap_eraser_footprint_dialog.dart';
import 'package:map_editor/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart';
import 'package:map_editor/src/ui/shared/top_toolbar/widgets/toolbar_capsules.dart';

import 'shell_chrome_test_harness.dart';

void main() {
  group('TopToolbar', () {
    test('normalizes manual project paths for the macOS picker fallback', () {
      expect(
        resolveProjectManifestPathFromUserSelection(
          '/Users/karim/PokeMapDemo',
        ),
        '/Users/karim/PokeMapDemo/project.json',
      );
      expect(
        resolveProjectManifestPathFromUserSelection(
          '"/Users/karim/PokeMapDemo/project.json"',
        ),
        '/Users/karim/PokeMapDemo/project.json',
      );
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        expect(
          resolveProjectManifestPathFromUserSelection('~/PokeMapDemo'),
          '$home/PokeMapDemo/project.json',
        );
      }
    });

    testWidgets('shows the app brand and project workspace label',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_project',
          project: buildShellChromeProject(name: 'Pokemon Map'),
          workspaceMode: EditorWorkspaceMode.pokedex,
        ),
      );

      expect(find.text('RPG Map Editor'), findsOneWidget);
      expect(find.text('Pokemon Map  •  Catalogues Pokémon'), findsOneWidget);
    });

    testWidgets('falls back to the workspace label when no project is loaded',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: const EditorState(),
      );

      expect(find.text('RPG Map Editor'), findsOneWidget);
      expect(find.text('World Editor'), findsOneWidget);
    });

    testWidgets(
      'keeps map zoom on the canvas and preserves tileset zoom controls',
      (tester) async {
        final initialState = EditorState(
          projectRootPath: '/tmp/top_toolbar_zoom_scope',
          project: buildShellChromeProject(),
          activeMap: buildShellChromeMap(),
          workspaceMode: EditorWorkspaceMode.map,
        );
        final container = await pumpTopToolbarHarness(
          tester,
          initialState: initialState,
          surfaceSize: const Size(1800, 220),
        );

        Finder zoomButton(String tooltip) => find.byWidgetPredicate(
              (widget) =>
                  widget is ToolbarCapsuleButton && widget.tooltip == tooltip,
            );

        expect(find.text('Affichage'), findsNothing);
        expect(zoomButton('Zoom Out'), findsNothing);
        expect(zoomButton('Zoom In'), findsNothing);

        container.read(editorNotifierProvider.notifier).state =
            initialState.copyWith(
          workspaceMode: EditorWorkspaceMode.tileset,
        );
        await tester.pump();

        expect(find.text('Affichage'), findsOneWidget);
        expect(zoomButton('Zoom Out'), findsOneWidget);
        expect(zoomButton('Zoom In'), findsOneWidget);

        await tester.tap(zoomButton('Zoom In'));
        await tester.pump();
        expect(
            container.read(editorNotifierProvider).zoom, closeTo(1.1, 0.001));
      },
    );

    testWidgets('shows the toolbar status chip when a status is present',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_status',
          project: buildShellChromeProject(),
          statusMessage: 'Map saved',
        ),
      );

      expect(find.text('Map saved'), findsOneWidget);
    });

    testWidgets('shows the trainer studio label for the trainer workspace',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_trainer',
          project: buildShellChromeProject(name: 'Pokemon Map'),
          workspaceMode: EditorWorkspaceMode.trainer,
        ),
      );

      expect(find.text('Pokemon Map  •  Trainer Studio'), findsOneWidget);
    });

    testWidgets('uses the French Narrative Studio overview chrome label',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_narrative_overview',
          project: buildShellChromeProject(name: 'test_project'),
          workspaceMode: EditorWorkspaceMode.narrativeOverview,
        ),
      );

      expect(
        find.text('test_project  •  Narrative Studio / Aperçu'),
        findsOneWidget,
      );
      expect(find.textContaining('Narrative Overview'), findsNothing);

      final overviewButton = tester.widget<ToolbarCapsuleButton>(
        find.byWidgetPredicate(
          (widget) =>
              widget is ToolbarCapsuleButton &&
              widget.tooltip == 'Ouvrir Narrative Studio / Aperçu',
        ),
      );
      expect(overviewButton.selected, isTrue);
      expect(overviewButton.onPressed, isNotNull);

      expect(find.text('Carte'), findsNothing);
      expect(find.text('Affichage'), findsNothing);
      expect(find.text('Calques'), findsNothing);

      ToolbarCapsuleButton buttonWithTooltip(String tooltip) {
        return tester.widget<ToolbarCapsuleButton>(
          find.byWidgetPredicate(
            (widget) =>
                widget is ToolbarCapsuleButton && widget.tooltip == tooltip,
          ),
        );
      }

      expect(
        buttonWithTooltip(
                'Nouvelle storyline à venir — création non branchée en V0')
            .onPressed,
        isNull,
      );
      expect(
        buttonWithTooltip(
                'Validation narrative à venir — aucun validateur global branché en V0')
            .onPressed,
        isNull,
      );
      expect(
        buttonWithTooltip(
                'Recherche narrative à venir — aucune recherche globale branchée en V0')
            .onPressed,
        isNull,
      );
      expect(
        buttonWithTooltip(
                'Notifications indisponibles — aucune source fiable en V0')
            .onPressed,
        isNull,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ToolbarCapsuleButton && widget.tooltip == 'New Map',
        ),
        findsNothing,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ToolbarCapsuleButton &&
              widget.tooltip == 'Masquer/Afficher le panneau des calques',
        ),
        findsNothing,
      );
    });

    testWidgets(
        'enables project save and disables map history in Smart Tiles Studio',
        (tester) async {
      final projectDir = Directory('/tmp/top_toolbar_smart_tiles_studio');
      if (!projectDir.existsSync()) {
        projectDir.createSync(recursive: true);
      }
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_smart_tiles_studio',
          project: buildShellChromeProject(name: 'Pokemon Map'),
          workspaceMode: EditorWorkspaceMode.smartTilesStudio,
          activeMap: buildShellChromeMap(),
          isProjectDirty: true,
          canUndoMap: true,
          canRedoMap: true,
        ),
      );

      ToolbarCapsuleButton buttonWithTooltip(String tooltip) {
        return tester.widget<ToolbarCapsuleButton>(
          find.byWidgetPredicate(
            (widget) =>
                widget is ToolbarCapsuleButton && widget.tooltip == tooltip,
          ),
        );
      }

      final saveButton =
          buttonWithTooltip('Save Project — unsaved project changes');
      expect(saveButton.onPressed, isNotNull);
      expect(saveButton.selected, isTrue);
      expect(buttonWithTooltip('Undo').onPressed, isNull);
      expect(buttonWithTooltip('Redo').onPressed, isNull);

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ToolbarCapsuleButton && widget.tooltip == 'Save Map',
        ),
        findsNothing,
      );
    });

    testWidgets(
        'shows neutral Save Project when project is clean in Smart Tiles Studio',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_smart_tiles_studio_clean',
          project: buildShellChromeProject(name: 'Pokemon Map'),
          workspaceMode: EditorWorkspaceMode.smartTilesStudio,
          activeMap: buildShellChromeMap(),
          isProjectDirty: false,
        ),
      );

      final saveButton = tester.widget<ToolbarCapsuleButton>(
        find.byWidgetPredicate(
          (widget) =>
              widget is ToolbarCapsuleButton &&
              widget.tooltip == 'Save Project',
        ),
      );
      expect(saveButton.onPressed, isNotNull);
      expect(saveButton.selected, isFalse);
    });

    testWidgets(
        'enables project save and disables map history in Environment Studio',
        (tester) async {
      final projectDir = Directory('/tmp/top_toolbar_environment_studio');
      if (!projectDir.existsSync()) {
        projectDir.createSync(recursive: true);
      }
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_environment_studio',
          project: buildShellChromeProject(name: 'Pokemon Map'),
          workspaceMode: EditorWorkspaceMode.environmentStudio,
          activeMap: buildShellChromeMap(),
          isProjectDirty: true,
          canUndoMap: true,
          canRedoMap: true,
        ),
      );

      ToolbarCapsuleButton buttonWithTooltip(String tooltip) {
        return tester.widget<ToolbarCapsuleButton>(
          find.byWidgetPredicate(
            (widget) =>
                widget is ToolbarCapsuleButton && widget.tooltip == tooltip,
          ),
        );
      }

      final saveButton =
          buttonWithTooltip('Save Project — unsaved project changes');
      expect(saveButton.onPressed, isNotNull);
      expect(saveButton.selected, isTrue);
      expect(buttonWithTooltip('Undo').onPressed, isNull);
      expect(buttonWithTooltip('Redo').onPressed, isNull);

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ToolbarCapsuleButton && widget.tooltip == 'Save Map',
        ),
        findsNothing,
      );
    });

    testWidgets('shows Environment Studio in the workspace brand strip',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_env_label',
          project: buildShellChromeProject(name: 'Pokemon Map'),
          workspaceMode: EditorWorkspaceMode.environmentStudio,
        ),
      );

      expect(
        find.text('Pokemon Map  •  Environment Studio'),
        findsOneWidget,
      );
    });

    testWidgets('keeps map save action in map workspace', (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_map',
          project: buildShellChromeProject(name: 'Pokemon Map'),
          workspaceMode: EditorWorkspaceMode.map,
          activeMap: buildShellChromeMap(),
          canUndoMap: true,
          canRedoMap: true,
        ),
      );

      ToolbarCapsuleButton buttonWithTooltip(String tooltip) {
        return tester.widget<ToolbarCapsuleButton>(
          find.byWidgetPredicate(
            (widget) =>
                widget is ToolbarCapsuleButton && widget.tooltip == tooltip,
          ),
        );
      }

      expect(buttonWithTooltip('Save Map').onPressed, isNotNull);
      buttonWithTooltip('Save Map').onPressed?.call();
      await tester.pumpAndSettle();
    });

    testWidgets(
        'keeps collision brush sizing paint-only and shows the eraser footprint',
        (tester) async {
      final map = buildShellChromeMap(
        width: 4,
        height: 4,
        layers: const <MapLayer>[
          MapLayer.collision(
            id: 'collision',
            name: 'Collision',
            collisions: <bool>[
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
            ],
          ),
        ],
      );
      final initialState = EditorState(
        project: buildShellChromeProject(),
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: map,
        activeLayerId: 'collision',
        activeTool: EditorToolType.collisionPaint,
      );
      final container = await pumpTopToolbarHarness(
        tester,
        initialState: initialState,
        surfaceSize: const Size(1800, 900),
      );

      Finder collisionSizeButton() => find.byWidgetPredicate(
            (widget) =>
                widget is ToolbarCapsuleButton &&
                widget.tooltip.startsWith('Collision Brush Size:'),
          );

      expect(collisionSizeButton(), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>('eraser-footprint-toolbar-button'),
        ),
        findsNothing,
      );

      container.read(editorNotifierProvider.notifier).state =
          initialState.copyWith(
        activeTool: EditorToolType.eraser,
        eraserFootprint: const EditorEraserFootprint.custom(
          size: GridSize(width: 3, height: 2),
        ),
      );
      await tester.pump();

      expect(collisionSizeButton(), findsNothing);
      expect(find.text('Gomme 3×2'), findsOneWidget);
      final footprintButton = tester.widget<PokeMapButton>(
        find.byKey(
          const ValueKey<String>('eraser-footprint-toolbar-button'),
        ),
      );
      expect(footprintButton.isSelected, isTrue);
      expect(footprintButton.onPressed, isNotNull);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('eraser-footprint-toolbar-button'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(pokeMapEraserFootprintDialogKey), findsOneWidget);

      await tester.tap(find.byKey(pokeMapEraserSingleTileChoiceKey));
      await tester.pump();
      await tester.tap(find.byKey(pokeMapEraserFootprintApplyButtonKey));
      await tester.pumpAndSettle();

      final configuredState = container.read(editorNotifierProvider);
      expect(
        configuredState.eraserFootprint,
        isA<SingleTileEditorEraserFootprint>(),
      );
      expect(configuredState.isDirty, isFalse);
      expect(configuredState.mapUndoStack, isEmpty);
    });

    testWidgets(
        'reapplying a previous-brush footprint preserves its frozen size',
        (tester) async {
      final map = buildShellChromeMap(
        width: 4,
        height: 4,
        layers: <MapLayer>[
          TileLayer(
            id: 'tiles',
            name: 'Tiles',
            tiles: List<int>.filled(16, 0),
          ),
        ],
      );
      final container = await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          project: buildShellChromeProject(),
          workspaceMode: EditorWorkspaceMode.map,
          activeMap: map,
          activeLayerId: 'tiles',
          activeTool: EditorToolType.eraser,
          eraserFootprint: const EditorEraserFootprint.previousBrush(
            size: GridSize(width: 3, height: 2),
          ),
          savedMapSnapshot: map,
        ),
        surfaceSize: const Size(1800, 900),
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      expect(
        notifier.resolveCurrentPaintFootprintForEraser(),
        const GridSize(width: 1, height: 1),
        reason: 'The live paint brush deliberately differs from the snapshot',
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('eraser-footprint-toolbar-button'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('3 × 2 cases'), findsOneWidget);

      await tester.tap(find.byKey(pokeMapEraserFootprintApplyButtonKey));
      await tester.pumpAndSettle();

      final configuredState = container.read(editorNotifierProvider);
      expect(
        configuredState.eraserFootprint,
        const EditorEraserFootprint.previousBrush(
          size: GridSize(width: 3, height: 2),
        ),
      );
      expect(configuredState.isDirty, isFalse);
      expect(configuredState.mapUndoStack, isEmpty);
    });

    testWidgets(
        'shows dedicated Border paint and erase only for a compatible active feature',
        (tester) async {
      final container = await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          project: _borderProject(
            template: BorderBlueprintTemplate.organicEdge,
          ),
          workspaceMode: EditorWorkspaceMode.map,
          activeMap: _borderMap(),
          activeLayerId: 'borders',
        ),
      );

      ToolbarCapsuleButton buttonWithTooltip(String tooltip) {
        return tester.widget<ToolbarCapsuleButton>(
          find.byWidgetPredicate(
            (widget) =>
                widget is ToolbarCapsuleButton && widget.tooltip == tooltip,
          ),
        );
      }

      final paint = buttonWithTooltip('Border Paint Tool');
      final erase = buttonWithTooltip('Border Erase Tool');
      expect(paint.onPressed, isNotNull);
      expect(erase.onPressed, isNotNull);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ToolbarCapsuleButton && widget.tooltip == 'Eraser Tool',
        ),
        findsNothing,
        reason: 'Border erase must not reuse the generic eraser',
      );

      paint.onPressed!.call();
      await tester.pump();
      expect(
        container.read(editorNotifierProvider).activeTool,
        EditorToolType.borderPaint,
      );

      erase.onPressed!.call();
      await tester.pump();
      expect(
        container.read(editorNotifierProvider).activeTool,
        EditorToolType.borderErase,
      );
    });

    testWidgets('shows disabled Border tools with the incompatibility reason',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          project: _borderProject(
            template: BorderBlueprintTemplate.masonryLine,
          ),
          workspaceMode: EditorWorkspaceMode.map,
          activeMap: _borderMap(),
          activeLayerId: 'borders',
        ),
      );

      final buttons = tester
          .widgetList<ToolbarCapsuleButton>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is ToolbarCapsuleButton &&
                  (widget.tooltip.startsWith('Border Paint Tool') ||
                      widget.tooltip.startsWith('Border Erase Tool')),
            ),
          )
          .toList(growable: false);
      expect(buttons, hasLength(2));
      expect(
          buttons,
          everyElement(predicate<ToolbarCapsuleButton>(
            (button) =>
                button.onPressed == null &&
                button.tooltip.contains('géométrie') &&
                button.tooltip.contains('blueprint'),
          )));
    });

    testWidgets('shows disabled Border tools when no feature exists',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          project: _borderProject(
            template: BorderBlueprintTemplate.organicEdge,
          ),
          workspaceMode: EditorWorkspaceMode.map,
          activeMap: _borderMap(withFeature: false),
          activeLayerId: 'borders',
        ),
      );

      final buttons = tester
          .widgetList<ToolbarCapsuleButton>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is ToolbarCapsuleButton &&
                  (widget.tooltip.startsWith('Border Paint Tool') ||
                      widget.tooltip.startsWith('Border Erase Tool')),
            ),
          )
          .toList(growable: false);
      expect(buttons, hasLength(2));
      expect(
          buttons,
          everyElement(predicate<ToolbarCapsuleButton>(
            (button) =>
                button.onPressed == null &&
                button.tooltip.contains('Sélectionnez ou créez une bordure'),
          )));
    });
  });
}

ProjectManifest _borderProject({
  required BorderBlueprintTemplate template,
}) {
  final draft = BorderBlueprintDraftDefinition(
    name: 'Coast',
    previewSeed: BorderSignedInt64.zero,
    template: template,
    primitives: const <BorderPrimitiveDraft>[],
    defaults: _borderParams(),
    sortOrder: 0,
  );
  return ProjectManifest(
    name: 'Project',
    version: ProjectVersion.v6,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    borderCatalog: ProjectBorderCatalog(
      records: <BorderBlueprintRecord>[
        BorderBlueprintRecord(
          id: 'coast',
          draft: BorderBlueprintDraft(baseRevision: 1, definition: draft),
          latestPublished: BorderBlueprintRevision(
            revision: 1,
            definition: BorderBlueprintPublishedDefinition(
              name: 'Coast',
              previewSeed: BorderSignedInt64.zero,
              template: template,
              primitives: const <BorderPublishedPrimitive>[],
              defaults: _borderParams(),
              sortOrder: 0,
            ),
          ),
        ),
      ],
    ),
  );
}

MapData _borderMap({bool withFeature = true}) => MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: const GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.border(
          id: 'borders',
          name: 'Bordures',
          content: BorderLayerContent(
            features: <BorderFeature>[
              if (withFeature)
                BorderFeature(
                  id: 'coast-feature',
                  name: 'Coast',
                  blueprintId: 'coast',
                  seed: BorderSignedInt64.zero,
                  geometry: BorderRegionGeometry(
                    width: 3,
                    height: 3,
                    cells: List<bool>.filled(9, false),
                  ),
                  overrides: const <BorderSlotOverride>[],
                  keepOutRegions: const <BorderKeepOutRegion>[],
                ),
            ],
          ),
        ),
      ],
    );

BorderGenerationParams _borderParams() => BorderGenerationParams(
      irregularityPermille: 0,
      detailDensityPermille: 0,
      variationPermille: 0,
      maxOverlapPx: 0,
      gapTolerancePx: 0,
      depthRows: 1,
    );
