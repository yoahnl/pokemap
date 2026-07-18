import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_scene_focus_provider.dart';
import 'package:map_editor/src/features/narrative/state/narrative_validator_providers.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart';
import 'package:map_editor/src/ui/canvas/narrative_validator_workspace.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  testWidgets(
    'Validator is a real Narrative Studio route and jumps to Fact and Scene sources',
    (tester) async {
      const project = ProjectManifest(
        name: 'Validator route project',
        maps: [],
        tilesets: [],
        surfaceCatalog: ProjectSurfaceCatalog.empty(),
      );
      final report = NarrativeProjectValidationReport(
        diagnostics: const [
          NarrativeProjectDiagnostic(
            code: 'sceneUnreachable',
            severity: NarrativeProjectDiagnosticSeverity.error,
            domain: NarrativeProjectDiagnosticDomain.scene,
            message: 'La Scene de fin est inaccessible.',
            path: 'scenes.scene_ending',
            destination: NarrativeProjectDiagnosticDestination.scene,
            sceneId: 'scene_ending',
          ),
          NarrativeProjectDiagnostic(
            code: 'requiredFactNeverProduced',
            severity: NarrativeProjectDiagnosticSeverity.error,
            domain: NarrativeProjectDiagnosticDomain.fact,
            message: 'Le Fact de passage n’est jamais produit.',
            path: 'facts.fact_passage',
            destination: NarrativeProjectDiagnosticDestination.fact,
            factId: 'fact_passage',
          ),
        ],
        mapEventViews: const [],
      );

      final container = await pumpEditorShellPage(
        tester,
        initialState: const EditorState(
          projectRootPath: '/virtual/validator-project',
          project: project,
          workspaceMode: EditorWorkspaceMode.narrativeValidator,
        ),
        surfaceSize: const Size(1672, 941),
        overrides: [
          narrativeValidatorPokemonCatalogLoaderProvider.overrideWithValue(
            (_) async => NarrativeValidatorPokemonCatalogSnapshot(
              speciesIds: const <String>{},
              moveIds: const <String>{},
            ),
          ),
          narrativeValidatorReportLoaderProvider.overrideWithValue(
            (_, __) async => report,
          ),
        ],
      );

      expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
      expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
      expect(find.byType(NarrativeValidatorWorkspace), findsOneWidget);
      expect(find.text('Narrative Studio  /  Validateur'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('narrative-studio-product-nav-validator'),
        ),
        findsOneWidget,
      );
      expect(find.text('La Scene de fin est inaccessible.'), findsOneWidget);

      await tester.tap(find.text('Ouvrir la source').last);
      await tester.pumpAndSettle();

      expect(
        container.read(editorNotifierProvider).workspaceMode,
        EditorWorkspaceMode.facts,
      );

      await tester.tap(
        find.byKey(
          const ValueKey('narrative-studio-product-nav-validator'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NarrativeValidatorWorkspace), findsOneWidget);

      await tester.tap(find.text('Ouvrir la source').first);
      await tester.pumpAndSettle();

      expect(
        container.read(editorNotifierProvider).workspaceMode,
        EditorWorkspaceMode.scenes,
      );
      expect(
        container.read(narrativeSceneFocusProvider)?.sceneId,
        'scene_ending',
      );
      expect(find.byType(NarrativeValidatorWorkspace), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  test('snapshot identity changes when the in-memory manifest changes', () {
    const first = ProjectManifest(
      name: 'First',
      maps: [],
      tilesets: [],
      surfaceCatalog: ProjectSurfaceCatalog.empty(),
    );
    final second = first.copyWith(name: 'Second');

    final firstRequest = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: '/virtual/project/../project',
      project: first,
    );
    final equivalentRequest = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: '/virtual/project',
      project: first,
    );
    final changedRequest = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: '/virtual/project',
      project: second,
    );
    final activeMapRequest = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: '/virtual/project',
      project: first,
      activeMap: const MapData(
        id: 'map_live',
        name: 'Map live',
        size: GridSize(width: 8, height: 8),
        layers: [],
      ),
    );
    final catalogRequest = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: '/virtual/project',
      project: first,
      pokemonCatalogFingerprint: 'catalog-v2',
    );

    expect(firstRequest, equivalentRequest);
    expect(changedRequest, isNot(firstRequest));
    expect(activeMapRequest, isNot(firstRequest));
    expect(catalogRequest, isNot(firstRequest));
    expect(firstRequest.project, same(first));
  });
}
