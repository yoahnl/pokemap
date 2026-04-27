// Tests widget — entrée workspace Surface Studio (Lot 53).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_selection_inspector.dart';
import 'package:map_editor/src/ui/canvas/editor_canvas_host.dart';
import 'package:path/path.dart' as p;

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

      expect(find.text('Lecture seule'), findsNWidgets(2));
      expect(find.text('Inspecteur Surface'), findsOneWidget);
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

      expect(find.text('Lecture seule'), findsNWidgets(2));
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

      final counters =
          find.descendant(
        of: find.byType(SurfaceStudioPanel),
        matching: find.byKey(const ValueKey('surface_studio_header_counters')),
      );
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsNWidgets(3),
      );
    });

    testWidgets(
        'read-only: actions désactivées; TextField seulement brouillon Lot 60',
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

      expect(
        find.descendant(
          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
          matching: find.byType(TextField),
        ),
        findsWidgets,
      );
      expect(find.text('Créer un atlas'), findsNothing);
      expect(
        find.text(SurfaceStudioPanel.actionImportVerticalAtlasLabel),
        findsOneWidget,
      );
      final importButton = tester.widget<CupertinoButton>(
        find.ancestor(
          of: find.text(SurfaceStudioPanel.actionImportVerticalAtlasLabel),
          matching: find.byType(CupertinoButton),
        ),
      );
      expect(importButton.onPressed, isNull);
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

    testWidgets('Lot 59 — Inspecteur Surface visible en mode workspace', (
      tester,
    ) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_lot59_insp',
          project: _buildProjectWithSurfaceCatalog(
            _minimalCoherentSurfaceCatalog(),
          ),
          workspaceMode: EditorWorkspaceMode.surfaceStudio,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Inspecteur Surface'), findsOneWidget);
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

    testWidgets(
        'Lot 64 — préparer sauvegarde : manifest en mémoire (notifier) sans disque',
        (tester) async {
      final empty = _buildProjectWithSurfaceCatalog(
        ProjectSurfaceCatalog(),
      );
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_lot64',
          project: empty,
          workspaceMode: EditorWorkspaceMode.surfaceStudio,
        ),
      );
      await tester.pumpAndSettle();
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'shell64');
      await tester.enterText(nameF, 'S');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      final p = container.read(editorNotifierProvider).project;
      expect(p, isNotNull);
      expect(p!.surfaceCatalog.atlases.length, 1);
      expect(p.surfaceCatalog.atlases.first.id, 'shell64');
      expect(
        find.text(SurfaceStudioPanel.manifestMemoryUpdatedNote),
        findsOneWidget,
      );
      for (final s in <String>[
        'Sauvegarder le projet',
        'Projet sauvegardé',
        'Save project',
      ]) {
        expect(find.text(s), findsNothing);
      }
    });

    testWidgets('Lot 65 — project.json on disk before official save: no new atlas', (
      tester,
    ) async {
      final temp = Directory.systemTemp.createTempSync('map_editor_lot65_');
      addTearDown(() {
        if (temp.existsSync()) {
          temp.deleteSync(recursive: true);
        }
      });
      final empty = _buildProjectWithSurfaceCatalog(ProjectSurfaceCatalog());
      final manifestPath = p.join(temp.path, 'project.json');
      File(manifestPath).writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(empty.toJson()),
      );
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: temp.path,
          project: empty,
          workspaceMode: EditorWorkspaceMode.surfaceStudio,
        ),
      );
      await tester.pumpAndSettle();
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'lot65a');
      await tester.enterText(nameF, 'N');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      final onDisk = File(manifestPath).readAsStringSync();
      final decoded =
          jsonDecode(onDisk) as Map<String, dynamic>;
      final sc = (decoded['surfaceCatalog'] as Map<String, dynamic>?) ?? {};
      final atl = sc['atlases'] as List<dynamic>? ?? [];
      expect(atl, isEmpty);
    });

    testWidgets(
        'Lot 65 — apply manifest + saveProjectManifest écrit surfaceCatalog (sans UI prep)',
        (tester) async {
      final temp = Directory.systemTemp.createTempSync('map_editor_lot65_prog_');
      addTearDown(() {
        if (temp.existsSync()) {
          temp.deleteSync(recursive: true);
        }
      });
      final empty = _buildProjectWithSurfaceCatalog(ProjectSurfaceCatalog());
      final manifestPath = p.join(temp.path, 'project.json');
      File(manifestPath).writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(empty.toJson()),
      );
      final withCat = replaceProjectManifestSurfaceCatalog(
        empty,
        _minimalCoherentSurfaceCatalog(),
      );
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: temp.path,
          project: empty,
          workspaceMode: EditorWorkspaceMode.surfaceStudio,
        ),
      );
      await tester.pumpAndSettle();
      container
          .read(editorNotifierProvider.notifier)
          .applyInMemoryProjectManifest(withCat);
      await tester.pumpAndSettle();
      expect(
        container.read(editorNotifierProvider).project!.surfaceCatalog.atlases
            .length,
        1,
      );
      var ok = false;
      await tester.runAsync(() async {
        ok = await container
            .read(editorNotifierProvider.notifier)
            .saveProjectManifest();
      });
      expect(ok, isTrue);
      final onDisk = File(manifestPath).readAsStringSync();
      final loaded = ProjectManifest.fromJson(
        jsonDecode(onDisk) as Map<String, dynamic>,
      );
      expect(loaded.name, empty.name);
      expect(loaded.surfaceCatalog.atlases.length, 1);
      expect(loaded.surfaceCatalog.atlases.first.id, 'water-atlas');
    });

    testWidgets(
        'Lot 65 — UI prep puis saveProjectManifest écrit surfaceCatalog',
        (tester) async {
      final temp = Directory.systemTemp.createTempSync('map_editor_lot65_ui_');
      addTearDown(() {
        if (temp.existsSync()) {
          temp.deleteSync(recursive: true);
        }
      });
      final empty = _buildProjectWithSurfaceCatalog(ProjectSurfaceCatalog());
      final manifestPath = p.join(temp.path, 'project.json');
      File(manifestPath).writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(empty.toJson()),
      );
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: temp.path,
          project: empty,
          workspaceMode: EditorWorkspaceMode.surfaceStudio,
        ),
      );
      await tester.pumpAndSettle();
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'lot65save');
      await tester.enterText(nameF, 'N');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      expect(
        container.read(editorNotifierProvider).project!.surfaceCatalog.atlases
            .length,
        1,
      );
      var ok = false;
      await tester.runAsync(() async {
        ok = await container
            .read(editorNotifierProvider.notifier)
            .saveProjectManifest();
      });
      expect(ok, isTrue);
      final onDisk = File(manifestPath).readAsStringSync();
      final loaded = ProjectManifest.fromJson(
        jsonDecode(onDisk) as Map<String, dynamic>,
      );
      expect(loaded.name, empty.name);
      expect(loaded.surfaceCatalog.atlases.length, 1);
      expect(loaded.surfaceCatalog.atlases.first.id, 'lot65save');
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
