// Surface Studio workspace entry tests for the V2.1 integrated wizard.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_workflow_layout.dart';
import 'package:map_editor/src/ui/canvas/editor_canvas_host.dart';
import 'package:path/path.dart' as p;

import '../shell_chrome_test_harness.dart';

void main() {
  group('Surface Studio workspace entry V2.1', () {
    test('EditorWorkspaceMode.surfaceStudio exists in enum', () {
      expect(
        EditorWorkspaceMode.values.contains(EditorWorkspaceMode.surfaceStudio),
        isTrue,
      );
    });

    testWidgets('entry remains visible in the explorer', (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_v21_entry',
          project: _projectWithSurfaceCatalog(_minimalSurfaceCatalog()),
        ),
      );

      expect(find.byKey(const Key('surface-studio-workspace-entry')),
          findsOneWidget);
      expect(find.text('Surface Studio'), findsWidgets);
      expect(
        find.textContaining('Surfaces animées', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('surface workspace renders one integrated assistant',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/surface_v21_workspace',
          project: _projectWithSurfaceCatalog(_minimalSurfaceCatalog()),
          workspaceMode: EditorWorkspaceMode.surfaceStudio,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EditorCanvasHost), findsOneWidget);
      expect(find.byType(SurfaceStudioPanel), findsOneWidget);
      expect(find.byKey(const Key('surfaceStudio.shell')), findsOneWidget);
      expect(
        find.text('Surface Studio — Assistant de mapping d’atlas'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('surface_studio_legacy_authoring_bridge')),
        findsNothing,
      );
      expect(find.byType(SurfaceStudioWorkflowLayout), findsNothing);
      expect(find.text('Assistant de création'), findsNothing);
      expect(find.text('Inspecteur Surface'), findsNothing);
    });

    testWidgets(
        'new wizard save prep updates manifest memory without disk write',
        (tester) async {
      final temp = Directory.systemTemp.createTempSync('map_editor_v21_prep_');
      addTearDown(() {
        if (temp.existsSync()) {
          temp.deleteSync(recursive: true);
        }
      });
      final empty = _projectWithSurfaceCatalog(ProjectSurfaceCatalog());
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

      await _createAtlasFromWizard(tester, id: 'v21-prep');
      await tester
          .tap(find.byKey(const Key('surfaceStudio.action.saveCatalog')));
      await tester.pumpAndSettle();

      final inMemory = container.read(editorNotifierProvider).project!;
      expect(inMemory.surfaceCatalog.atlases.map((atlas) => atlas.id),
          contains('v21-prep'));

      final onDisk = File(manifestPath).readAsStringSync();
      final decoded = jsonDecode(onDisk) as Map<String, dynamic>;
      final surfaceCatalog =
          (decoded['surfaceCatalog'] as Map<String, dynamic>?) ?? {};
      expect(surfaceCatalog['atlases'] as List<dynamic>? ?? [], isEmpty);
    });

    testWidgets('new wizard save prep then saveProjectManifest writes disk',
        (tester) async {
      final temp = Directory.systemTemp.createTempSync('map_editor_v21_save_');
      addTearDown(() {
        if (temp.existsSync()) {
          temp.deleteSync(recursive: true);
        }
      });
      final empty = _projectWithSurfaceCatalog(ProjectSurfaceCatalog());
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

      await _createAtlasFromWizard(tester, id: 'v21-save');
      await tester
          .tap(find.byKey(const Key('surfaceStudio.action.saveCatalog')));
      await tester.pumpAndSettle();

      var ok = false;
      await tester.runAsync(() async {
        ok = await container
            .read(editorNotifierProvider.notifier)
            .saveProjectManifest();
      });

      expect(ok, isTrue);
      final loaded = ProjectManifest.fromJson(
        jsonDecode(File(manifestPath).readAsStringSync())
            as Map<String, dynamic>,
      );
      expect(loaded.surfaceCatalog.atlases.map((atlas) => atlas.id),
          contains('v21-save'));
    });
  });
}

Future<void> _createAtlasFromWizard(
  WidgetTester tester, {
  required String id,
}) async {
  await tester.enterText(
    find.byKey(const Key('surfaceStudio.import.atlasId')),
    id,
  );
  await tester.enterText(
    find.byKey(const Key('surfaceStudio.import.atlasName')),
    'Surface $id',
  );
  await tester.enterText(
    find.byKey(const Key('surfaceStudio.import.tilesetId')),
    'nature-tileset',
  );
  final createButton =
      find.byKey(const Key('surfaceStudio.import.createAtlas'));
  await tester.ensureVisible(createButton);
  await tester.pumpAndSettle();
  await tester.tap(createButton);
  await tester.pump();
}

ProjectManifest _projectWithSurfaceCatalog(ProjectSurfaceCatalog catalog) {
  return ProjectManifest(
    name: 'Surface V2.1',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'nature-tileset',
        name: 'Nature Tileset',
        relativePath: 'assets/tilesets/nature.png',
      ),
    ],
    surfaceCatalog: catalog,
  );
}

ProjectSurfaceCatalog _minimalSurfaceCatalog() {
  final atlas = ProjectSurfaceAtlas(
    id: 'water-atlas',
    name: 'Water Atlas',
    tilesetId: 'nature-tileset',
    geometry: SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
      gridSize: SurfaceAtlasGridSize(columns: 12, rows: 32),
      layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
    ),
  );
  final animation = ProjectSurfaceAnimation(
    id: 'water-isolated-loop',
    name: 'Water Isolated Loop',
    timeline: SurfaceAnimationTimeline(
      frames: [
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(
            atlasId: 'water-atlas',
            column: 0,
            row: 0,
          ),
          durationMs: 120,
        ),
      ],
    ),
  );
  final preset = ProjectSurfacePreset(
    id: 'water-surface',
    name: 'Water Surface',
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: 'water-isolated-loop',
        ),
      ],
    ),
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [animation],
    presets: [preset],
  );
}
