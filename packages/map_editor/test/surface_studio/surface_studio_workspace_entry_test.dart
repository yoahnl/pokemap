// Tests widget — entrée workspace Surface Studio (Lot 53).

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
import 'package:map_editor/src/ui/canvas/editor_canvas_host.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  group('Surface Studio workspace entry (Lot 53)', () {
    test('EditorWorkspaceMode.surfaceStudio exists in enum', () {
      expect(
        EditorWorkspaceMode.values.contains(EditorWorkspaceMode.surfaceStudio),
        isTrue,
      );
    });

    testWidgets('entry title Surface Studio is visible in explorer',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_lot53',
          project: _buildProjectWithSurfaceCatalog(
            _minimalCoherentSurfaceCatalog(),
          ),
        ),
      );

      expect(find.text('Surface Studio'), findsWidgets);
    });

    testWidgets('subtitle mentions animated surfaces (Surfaces animées)', (
      tester,
    ) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_lot53',
          project: _buildProjectWithSurfaceCatalog(
            _minimalCoherentSurfaceCatalog(),
          ),
        ),
      );

      expect(
        find.textContaining('Surfaces animées', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('Terrain / Surface Studio / Path Library order in column', (
      tester,
    ) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_lot53',
          project: _buildProjectWithSurfaceCatalog(
            _minimalCoherentSurfaceCatalog(),
          ),
        ),
      );

      final terrain = find.text('Terrain Library');
      final path = find.text('Path Library');
      final surfaceEntry =
          find.byKey(const Key('surface-studio-workspace-entry'));
      expect(terrain, findsOneWidget);
      expect(path, findsOneWidget);
      expect(surfaceEntry, findsOneWidget);
      final yTerrain = tester.getTopLeft(terrain).dy;
      final ySurface = tester.getTopLeft(surfaceEntry).dy;
      final yPath = tester.getTopLeft(path).dy;
      expect(yTerrain, lessThan(ySurface));
      expect(ySurface, lessThan(yPath));
    });

    testWidgets('tap entry opens center panel with Lecture seule', (
      tester,
    ) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_lot53',
          project: _buildProjectWithSurfaceCatalog(
            _minimalCoherentSurfaceCatalog(),
          ),
        ),
      );

      await tester.ensureVisible(
        find.byKey(const Key('surface-studio-workspace-entry')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('surface-studio-workspace-entry')));
      await tester.pumpAndSettle();

      expect(find.text('Lecture seule'), findsOneWidget);
      expect(find.byType(SurfaceStudioPanel), findsOneWidget);
      expect(find.text('Catalogue Surface'), findsOneWidget);
      expect(find.text('Atlas Surface'), findsOneWidget);
      expect(find.text('Animations Surface'), findsOneWidget);
      expect(find.text('Presets Surface'), findsOneWidget);
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(find.text('Water Isolated Loop'), findsOneWidget);
      expect(find.text('Water Surface'), findsOneWidget);
      expect(find.text('Diagnostics Surface'), findsOneWidget);
    });

    testWidgets('EditorCanvasHost builds SurfaceStudioPanel in surface mode', (
      tester,
    ) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_lot53_host',
          project: _buildProjectWithSurfaceCatalog(
            _minimalCoherentSurfaceCatalog(),
          ),
          workspaceMode: EditorWorkspaceMode.surfaceStudio,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EditorCanvasHost), findsOneWidget);
      expect(find.byType(SurfaceStudioPanel), findsOneWidget);
    });

    testWidgets('works without an active map (no map required)',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_lot53_no_map',
          project: _buildProjectWithSurfaceCatalog(
            _minimalCoherentSurfaceCatalog(),
          ),
          activeMap: null,
          activeMapPath: null,
        ),
      );

      expect(
        find.text('Open a map to start building your world.'),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const Key('surface-studio-workspace-entry')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('surface-studio-workspace-entry')));
      await tester.pumpAndSettle();

      expect(find.text('Lecture seule'), findsOneWidget);
    });

    testWidgets('panel shows 1/1/1 from manifest when catalog is minimal', (
      tester,
    ) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_lot53_counts',
          project: _buildProjectWithSurfaceCatalog(
            _minimalCoherentSurfaceCatalog(),
          ),
          workspaceMode: EditorWorkspaceMode.surfaceStudio,
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(SurfaceStudioPanel),
          matching: find.text('1'),
        ),
        findsNWidgets(3),
      );
    });

    testWidgets(
        'read-only: future action CupertinoButtons are disabled, no TextField',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_lot53_ro',
          project: _buildProjectWithSurfaceCatalog(
            _minimalCoherentSurfaceCatalog(),
          ),
          workspaceMode: EditorWorkspaceMode.surfaceStudio,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(
        find.text(SurfaceStudioPanel.actionCreateAtlasLabel),
        findsOneWidget,
      );
      final createButton = tester.widget<CupertinoButton>(
        find.ancestor(
          of: find.text(SurfaceStudioPanel.actionCreateAtlasLabel),
          matching: find.byType(CupertinoButton),
        ),
      );
      expect(createButton.onPressed, isNull);
    });

    testWidgets('no Surface save button labels', (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_lot53_save',
          project: _buildProjectWithSurfaceCatalog(
            _minimalCoherentSurfaceCatalog(),
          ),
          workspaceMode: EditorWorkspaceMode.surfaceStudio,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Sauvegarder Surface'), findsNothing);
      expect(find.textContaining('Enregistrer Surface'), findsNothing);
      expect(find.textContaining('Save Surface'), findsNothing);
    });

    testWidgets('no internal type names in visible shell copy', (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_lot53_copy',
          project: _buildProjectWithSurfaceCatalog(
            _minimalCoherentSurfaceCatalog(),
          ),
          workspaceMode: EditorWorkspaceMode.surfaceStudio,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
      expect(
          find.textContaining('SurfaceVariantAnimationRefSet'), findsNothing);
    });
  });
}

// --- Même minimal catalogue qu’au test Lot 52 (1 atlas, 1 anim, 1 preset) ---

ProjectSurfaceCatalog _minimalCoherentSurfaceCatalog() {
  final g = SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
  final atlas = ProjectSurfaceAtlas(
    id: 'water-atlas',
    name: 'Water Atlas',
    tilesetId: 'nature-tileset',
    geometry: g,
  );
  final frame = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
    durationMs: 120,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'water-isolated-loop',
    name: 'Water Isolated Loop',
    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[frame]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: <SurfaceVariantAnimationRef>[
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'water-isolated-loop',
      ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'water-surface',
    name: 'Water Surface',
    variantAnimations: refs,
  );
  return ProjectSurfaceCatalog(
    atlases: <ProjectSurfaceAtlas>[atlas],
    animations: <ProjectSurfaceAnimation>[anim],
    presets: <ProjectSurfacePreset>[preset],
  );
}

ProjectManifest _buildProjectWithSurfaceCatalog(ProjectSurfaceCatalog c) {
  return ProjectManifest(
    name: 'Surface Lot53',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
    surfaceCatalog: c,
  );
}
