import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/application/models/narrative_authoring_transaction.dart';
import 'package:map_editor/src/application/ports/narrative_authoring_persistence_gateway.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_builder_workspace.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematics_library_workspace.dart';
import 'package:map_editor/src/ui/canvas/cutscene_studio_workspace.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_navigation.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_destination.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_navigation.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/editor_shell_page.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';

import '../../shell_chrome_test_harness.dart';
import '../../support/event_builder_v2_visual_harness.dart';

void main() {
  testWidgets(
    'Cinematics keeps one product shell and page through Library, Builder and legacy',
    (tester) async {
      final project = _cinematicsProject();
      final before = project.toJson();

      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: project,
          workspaceMode: EditorWorkspaceMode.cutscene,
        ),
        surfaceSize: const Size(1672, 941),
      );

      void expectSharedRoute() {
        expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
        expect(find.byType(NarrativeStudioProductNavigation), findsOneWidget);
        expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
        expect(find.byType(ProjectExplorerPanel), findsNothing);
        expect(
          find.byKey(
            const ValueKey<String>(
              'narrative-studio-product-nav-cinematics',
            ),
          ),
          findsOneWidget,
        );
      }

      expectSharedRoute();
      expect(find.byType(CinematicsLibraryWorkspace), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cinematics-library-workspace')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-entry-cinematic_intro')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('cinematics-library-open-builder-button')),
      );
      await tester.pumpAndSettle();

      expectSharedRoute();
      expect(find.byType(CinematicBuilderWorkspace), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Narrative Studio  /  Cinématiques  /  Intro cinématique',
        ),
        findsOneWidget,
      );
      expect(
        container
            .read(narrativeStudioNavigationControllerProvider)
            .location
            .childRoute,
        NarrativeStudioChildRoute.cinematicBuilder,
      );
      expect(
        container
            .read(narrativeStudioNavigationControllerProvider)
            .location
            .selection
            ?.assetId,
        'cinematic_intro',
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-back-button')),
      );
      await tester.pumpAndSettle();

      expectSharedRoute();
      expect(find.byType(CinematicsLibraryWorkspace), findsOneWidget);
      expect(
        container.read(narrativeStudioNavigationControllerProvider).location,
        NarrativeStudioRouteLocation.cinematics(),
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematics-library-open-builder-button')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CinematicBuilderWorkspace), findsOneWidget);
      await tester.tap(
        find.byKey(
          const ValueKey('narrative-studio-product-nav-cinematics'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CinematicsLibraryWorkspace), findsOneWidget);
      expect(
        container.read(narrativeStudioNavigationControllerProvider).location,
        NarrativeStudioRouteLocation.cinematics(),
      );

      await tester.tap(
        find.byKey(
          const ValueKey('cinematics-library-open-legacy-button'),
        ),
      );
      await tester.pumpAndSettle();

      expectSharedRoute();
      expect(find.byType(CutsceneStudioWorkspace), findsOneWidget);
      expect(find.text('Narrative Studio  ›  Step  ›  Cutscene'), findsNothing);
      for (final action in <String>[
        'Sauvegarder',
        'Réinitialiser',
        'Nouvelle cutscene',
      ]) {
        expect(find.text(action), findsOneWidget);
      }
      expect(find.text('Tester'), findsNothing);
      expect(find.text('Simuler'), findsNothing);
      expect(
        find.text('Narrative Studio  /  Cinématiques  /  Ancien studio'),
        findsOneWidget,
      );
      expect(
        container
            .read(narrativeStudioNavigationControllerProvider)
            .location
            .childRoute,
        NarrativeStudioChildRoute.cinematicLegacy,
      );
      expect(
        find.byKey(const ValueKey('cinematics-library-back-button')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematics-library-back-button')),
      );
      await tester.pumpAndSettle();

      expectSharedRoute();
      expect(find.byType(CinematicsLibraryWorkspace), findsOneWidget);
      expect(
        container.read(narrativeStudioNavigationControllerProvider).location,
        NarrativeStudioRouteLocation.cinematics(),
      );
      expect(project.toJson(), before);
    },
  );

  testWidgets(
    'a stale Cinematic deep link fails closed without losing its return',
    (tester) async {
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: _cinematicsProject(),
          workspaceMode: EditorWorkspaceMode.cutscene,
        ),
        surfaceSize: const Size(1672, 941),
      );
      final returnExpectation = NarrativeStudioReturnExpectation(
        location: NarrativeStudioRouteLocation.cinematics(),
      );
      container
          .read(narrativeStudioNavigationControllerProvider.notifier)
          .navigate(
            NarrativeStudioRouteLocation.cinematics(
              childRoute: NarrativeStudioChildRoute.cinematicBuilder,
              selection: NarrativeStudioAssetSelection(
                kind: NarrativeStudioAssetKind.cinematic,
                assetId: 'cinematic_deleted',
              ),
            ),
            returnExpectation: returnExpectation,
          );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('cinematics-library-requested-unavailable'),
        ),
        findsOneWidget,
      );
      expect(find.text('Cinématique introuvable'), findsOneWidget);
      expect(find.byType(CinematicBuilderWorkspace), findsNothing);
      expect(
        find.byKey(const ValueKey('cinematic-entry-cinematic_intro')),
        findsNothing,
        reason: 'Une cible obsolète ne doit pas sélectionner le premier item.',
      );
      final staleNavigation =
          container.read(narrativeStudioNavigationControllerProvider);
      expect(staleNavigation.pendingReturn, returnExpectation);
      expect(staleNavigation.restorationRequest, isNull);

      await tester.tap(
        find.byKey(
          const ValueKey('narrative-studio-product-nav-return'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(narrativeStudioNavigationControllerProvider).location,
        returnExpectation.location,
      );
      expect(
        container
            .read(narrativeStudioNavigationControllerProvider)
            .pendingReturn,
        isNull,
      );
      expect(
        find.byKey(
          const ValueKey('cinematics-library-requested-unavailable'),
        ),
        findsNothing,
      );
      expect(find.byType(CinematicsLibraryWorkspace), findsOneWidget);
    },
  );

  testWidgets(
    'Cinematics CRUD persists through the shared authoring transaction',
    (tester) async {
      final root = Directory.systemTemp.createTempSync(
        'cinematics_authoring_transaction_',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final manifestFile = File('${root.path}/project.json');
      final project = _cinematicsProject().copyWith(scenarios: const []);
      manifestFile.writeAsStringSync(jsonEncode(project.toJson()));
      final gateway = _SynchronousManifestGateway();

      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: project,
          workspaceMode: EditorWorkspaceMode.cutscene,
        ),
        surfaceSize: const Size(1672, 941),
        overrides: [
          narrativeAuthoringPersistenceGatewayProvider.overrideWithValue(
            gateway,
          ),
        ],
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = notifier.state.copyWith(projectRootPath: root.path);
      await tester.pump();

      await tester.enterText(
        find.byKey(const ValueKey('cinematics-library-create-title-field')),
        'Départ du port',
      );
      await tester.tap(
        find.byKey(const ValueKey('cinematics-library-create-button')),
      );
      await tester.pump();
      expect(
        gateway.calls,
        1,
        reason: container.read(editorNotifierProvider).errorMessage,
      );
      await _pumpUntil(
        tester,
        () =>
            !container.read(editorNotifierProvider).isSaving &&
            container
                .read(editorNotifierProvider)
                .project!
                .cinematics
                .any((asset) => asset.title == 'Départ du port'),
      );

      expect(
        container
            .read(editorNotifierProvider)
            .project!
            .cinematics
            .map((asset) => asset.title),
        contains('Départ du port'),
      );
      expect(
        _readManifest(manifestFile).cinematics.map((asset) => asset.title),
        contains('Départ du port'),
      );
      expect(container.read(editorNotifierProvider).isProjectDirty, isFalse);

      await tester.enterText(
        find.byKey(const ValueKey('cinematics-library-title-field')),
        'Départ du phare',
      );
      await _invokeAsyncPokeMapButton(
        tester,
        find.byKey(const ValueKey('cinematics-library-save-button')),
        () =>
            !container.read(editorNotifierProvider).isSaving &&
            container
                .read(editorNotifierProvider)
                .project!
                .cinematics
                .any((asset) => asset.title == 'Départ du phare'),
      );

      expect(
        _readManifest(manifestFile).cinematics.map((asset) => asset.title),
        contains('Départ du phare'),
      );
      expect(container.read(editorNotifierProvider).isProjectDirty, isFalse);

      final deleteButton =
          find.byKey(const ValueKey('cinematics-library-delete-button'));
      await tester.tap(deleteButton);
      await tester.pump();
      await tester.tap(deleteButton);
      await _pumpUntil(
        tester,
        () =>
            !container.read(editorNotifierProvider).isSaving &&
            container
                .read(editorNotifierProvider)
                .project!
                .cinematics
                .every((asset) => asset.title != 'Départ du phare'),
      );

      expect(
        _readManifest(manifestFile).cinematics.map((asset) => asset.title),
        isNot(contains('Départ du phare')),
      );
      expect(container.read(editorNotifierProvider).isProjectDirty, isFalse);
      expect(gateway.calls, 3);
    },
  );

  testWidgets(
    'Cinematics never reports a dirty no-op retry as saved',
    (tester) async {
      final root = Directory.systemTemp.createTempSync(
        'cinematics_authoring_failed_retry_',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final manifestFile = File('${root.path}/project.json');
      final project = _cinematicsProject().copyWith(scenarios: const []);
      manifestFile.writeAsStringSync(jsonEncode(project.toJson()));
      final gateway = _FailingManifestGateway();

      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: project,
          workspaceMode: EditorWorkspaceMode.cutscene,
        ),
        surfaceSize: const Size(1672, 941),
        overrides: [
          narrativeAuthoringPersistenceGatewayProvider.overrideWithValue(
            gateway,
          ),
        ],
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = notifier.state.copyWith(projectRootPath: root.path);
      await tester.pump();

      final titleField =
          find.byKey(const ValueKey('cinematics-library-title-field'));
      final saveButton =
          find.byKey(const ValueKey('cinematics-library-save-button'));
      await tester.enterText(titleField, 'Intro locale non enregistrée');
      await _invokeAsyncPokeMapButton(
        tester,
        saveButton,
        () =>
            !container.read(editorNotifierProvider).isSaving &&
            container
                    .read(editorNotifierProvider)
                    .project!
                    .cinematics
                    .first
                    .title ==
                'Intro locale non enregistrée',
      );

      expect(gateway.calls, 1);
      expect(container.read(editorNotifierProvider).isProjectDirty, isTrue);
      expect(
        find.text(
          'Modification non enregistrée. Consultez le diagnostic du projet.',
        ),
        findsOneWidget,
      );
      expect(
        _readManifest(manifestFile).cinematics.first.title,
        isNot('Intro locale non enregistrée'),
      );

      await _invokeAsyncPokeMapButton(
        tester,
        saveButton,
        () => container.read(editorNotifierProvider).errorMessage != null,
      );

      expect(gateway.calls, 1);
      expect(container.read(editorNotifierProvider).isProjectDirty, isTrue);
      expect(
        container.read(editorNotifierProvider).errorMessage,
        contains('Conflit narratif détecté'),
      );
      expect(find.byKey(narrativeDocumentCompareActionKey), findsOneWidget);
      expect(find.text('Métadonnées sauvegardées.'), findsNothing);
      expect(
        find.text(
          'Modification non enregistrée. Consultez le diagnostic du projet.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('Cinematics project-absent state still owns one shared page', (
    tester,
  ) async {
    await pumpEditorShellPage(
      tester,
      initialState: const EditorState(
        workspaceMode: EditorWorkspaceMode.cutscene,
      ),
      surfaceSize: const Size(1280, 768),
    );

    expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
    expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
    expect(find.byType(ProjectExplorerPanel), findsNothing);
    expect(find.text('Aucun projet chargé'), findsOneWidget);
    expect(
      find.text(
        'Chargez un projet pour ouvrir la bibliothèque et les outils cinématiques.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Cinematics shared route is responsive at supported widths', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.25;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final size in <Size>[
      const Size(1280, 768),
      const Size(1366, 768),
      const Size(1440, 900),
      const Size(1672, 941),
      const Size(1920, 941),
    ]) {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: _cinematicsProject(),
          workspaceMode: EditorWorkspaceMode.cutscene,
        ),
        surfaceSize: size,
      );

      expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
      expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Library viewport: $size');

      await tester.tap(
        find.byKey(const ValueKey('cinematic-entry-cinematic_intro')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('cinematics-library-open-builder-button')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CinematicBuilderWorkspace), findsOneWidget);
      expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Builder viewport: $size');

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-back-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('cinematics-library-open-legacy-button'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CutsceneStudioWorkspace), findsOneWidget);
      expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Legacy viewport: $size');

      await tester.tap(
        find.byKey(const ValueKey('cinematics-library-back-button')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CinematicsLibraryWorkspace), findsOneWidget);
    }
  });

  for (final goldenState in <String>['library', 'builder', 'legacy']) {
    testWidgets(
      'matches the full Cinematics $goldenState route at 1672x941',
      (tester) async {
        await loadEventBuilderV2PhaseKCaptureFonts();
        await pumpEditorShellPage(
          tester,
          initialState: EditorState(
            project: _cinematicsProject(),
            workspaceMode: EditorWorkspaceMode.cutscene,
          ),
          surfaceSize: const Size(1672, 941),
          fontFamily: eventBuilderV2PhaseKCaptureFontFamily,
          cupertinoFontFamily: eventBuilderV2PhaseKCaptureFontFamily,
        );

        if (goldenState == 'builder') {
          await tester.tap(
            find.byKey(const ValueKey('cinematic-entry-cinematic_intro')),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(
              const ValueKey('cinematics-library-open-builder-button'),
            ),
          );
        } else if (goldenState == 'legacy') {
          await tester.tap(
            find.byKey(
              const ValueKey('cinematics-library-open-legacy-button'),
            ),
          );
        }
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump();

        final golden = File(
          'test/goldens/narrative_studio/cinematics/'
          'cinematics_${goldenState}_full_product_route_1672x941.png',
        );
        golden.parent.createSync(recursive: true);
        await expectLater(
          find.byType(EditorShellPage),
          matchesGoldenFile(golden.absolute.path),
        );
      },
    );
  }
}

ProjectManifest _readManifest(File file) {
  final decoded = jsonDecode(file.readAsStringSync());
  return ProjectManifest.fromJson(Map<String, dynamic>.from(decoded as Map));
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition,
) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (condition()) return;
  }
  fail('Timed out while waiting for the narrative authoring transaction.');
}

Future<void> _invokeAsyncPokeMapButton(
  WidgetTester tester,
  Finder finder,
  bool Function() condition,
) async {
  final button = tester.widget<PokeMapButton>(finder);
  await tester.runAsync(() async {
    button.onPressed!.call();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final deadline = DateTime.now().add(const Duration(seconds: 2));
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('Timed out while waiting for the async narrative action.');
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
  await tester.pump();
}

final class _SynchronousManifestGateway
    implements NarrativeAuthoringPersistenceGateway {
  int calls = 0;

  @override
  Future<NarrativeAuthoringPersistenceResult> persist(
    NarrativeAuthoringTransaction transaction,
  ) {
    calls += 1;
    File(transaction.projectPath).writeAsStringSync(
      jsonEncode(transaction.after.toJson()),
      flush: true,
    );
    return Future.value(
      const NarrativeAuthoringPersistenceResult.committed(),
    );
  }
}

final class _FailingManifestGateway
    implements NarrativeAuthoringPersistenceGateway {
  int calls = 0;

  @override
  Future<NarrativeAuthoringPersistenceResult> persist(
    NarrativeAuthoringTransaction transaction,
  ) {
    calls += 1;
    return Future.value(
      const NarrativeAuthoringPersistenceResult(
        status: NarrativeAuthoringPersistenceStatus.persistenceFailed,
        code: 'staleProjectRevision',
        message: 'The project changed externally.',
      ),
    );
  }
}

ProjectManifest _cinematicsProject() {
  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: 'Cinématiques route fixture',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    scenarios: const <ScenarioAsset>[
      ScenarioAsset(
        id: 'scenario_legacy',
        name: 'Ancienne cinématique',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'start',
        metadata: <String, String>{
          'authoring.cutsceneSchema': 'cutscene-studio-v0',
        },
      ),
    ],
    cinematics: <CinematicAsset>[
      CinematicAsset(
        id: 'cinematic_intro',
        title: 'Intro cinématique',
        timeline: CinematicTimeline(),
      ),
    ],
  );
}
