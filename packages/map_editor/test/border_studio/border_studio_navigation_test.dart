import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/border_studio_workspace.dart';
import 'package:map_editor/src/features/border_studio/state/border_studio_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/panels/map_inspector_panel.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  testWidgets(
      'Border Studio opens without an active map and exposes five steps',
      (tester) async {
    await pumpEditorCanvasHostHarness(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/border-studio-project',
        project: _project(),
        workspaceMode: EditorWorkspaceMode.borderStudio,
        activeMap: null,
      ),
    );

    expect(find.byType(BorderStudioWorkspace), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('border-studio-workspace')),
      findsOneWidget,
    );
    for (final label in <String>[
      'Type',
      'Assets',
      'Rôles',
      'Règles',
      'Aperçu et publication',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byType(MapCanvas), findsNothing);
    expect(find.byType(MapInspectorPanel), findsNothing);
  });

  testWidgets('World Explorer places Border Studio directly after World Maps',
      (tester) async {
    final container = await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/border-studio-project',
        project: _project(),
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: null,
      ),
      surfaceSize: const Size(1600, 1000),
    );

    final worldMaps = find.text('World Maps');
    final borderCard =
        find.byKey(const ValueKey<String>('border-studio-module-card'));
    final terrainLibrary = find.text('Terrain Library');
    expect(worldMaps, findsOneWidget);
    expect(borderCard, findsOneWidget);
    expect(terrainLibrary, findsOneWidget);
    expect(tester.getTopLeft(worldMaps).dy,
        lessThan(tester.getTopLeft(borderCard).dy));
    expect(
      tester.getTopLeft(borderCard).dy,
      lessThan(tester.getTopLeft(terrainLibrary).dy),
    );

    await tester.tap(borderCard);
    await tester.pumpAndSettle();

    expect(
      container.read(editorNotifierProvider).workspaceMode,
      EditorWorkspaceMode.borderStudio,
    );
    expect(find.byType(BorderStudioWorkspace), findsOneWidget);
    expect(find.byType(MapInspectorPanel), findsNothing);
  });

  testWidgets('leaving a dirty Border draft requires an explicit choice',
      (tester) async {
    final project = _projectWithDraft();
    final container = await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/border-studio-project',
        project: project,
        workspaceMode: EditorWorkspaceMode.borderStudio,
        activeMap: null,
      ),
      surfaceSize: const Size(1600, 1000),
    );
    final draftController =
        container.read(borderStudioDraftControllerProvider.notifier);
    draftController.renameBlueprint('Côte modifiée');

    container
        .read(editorNotifierProvider.notifier)
        .selectEnvironmentStudioWorkspace();
    await tester.pumpAndSettle();

    expect(find.text('Brouillon non enregistré'), findsOneWidget);
    expect(find.text('Enregistrer'), findsOneWidget);
    expect(find.text('Abandonner les modifications'), findsOneWidget);
    expect(find.text('Rester'), findsOneWidget);

    await tester.tap(find.text('Rester'));
    await tester.pumpAndSettle();
    expect(
      container.read(editorNotifierProvider).workspaceMode,
      EditorWorkspaceMode.borderStudio,
    );
    expect(draftController.state.isDirty, isTrue);
  });
}

ProjectManifest _project() => const ProjectManifest(
      name: 'border-studio-project',
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
      surfaceCatalog: ProjectSurfaceCatalog.empty(),
    );

ProjectManifest _projectWithDraft() => ProjectManifest(
      name: 'border-studio-project',
      version: ProjectVersion.v2,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      surfaceCatalog: const ProjectSurfaceCatalog.empty(),
      borderCatalog: ProjectBorderCatalog(
        records: <BorderBlueprintRecord>[
          BorderBlueprintRecord(
            id: 'coast',
            draft: BorderBlueprintDraft(
              baseRevision: 0,
              definition: BorderBlueprintDraftDefinition(
                name: 'Côte',
                previewSeed: BorderSignedInt64.fromInt(1),
                template: BorderBlueprintTemplate.organicEdge,
                primitives: const <BorderPrimitiveDraft>[],
                defaults: BorderGenerationParams(
                  irregularityPermille: 250,
                  detailDensityPermille: 500,
                  variationPermille: 300,
                  maxOverlapPx: 4,
                  gapTolerancePx: 1,
                  depthRows: 1,
                ),
                sortOrder: 0,
              ),
            ),
          ),
        ],
      ),
    );
