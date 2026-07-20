import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/dialogue_studio_workspace.dart';
import 'package:map_editor/src/ui/canvas/facts_world_rules/facts_world_rules_workspace.dart';
import 'package:map_editor/src/ui/canvas/narrative_overview_workspace.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_destination.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_navigation.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/editor_shell_page.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';

import '../../shell_chrome_test_harness.dart';
import '../../support/narrative_studio_capture_fonts.dart';

const _specializedRoutesCaptureFontFamily =
    'NarrativeStudioSpecializedRoutesArial';

void main() {
  late Directory projectRoot;

  setUp(() async {
    projectRoot = await Directory.systemTemp.createTemp(
      'map_editor_specialized_routes_',
    );
  });

  tearDown(() async {
    if (await projectRoot.exists()) {
      await projectRoot.delete(recursive: true);
    }
  });

  final routeCases = <({
    EditorWorkspaceMode mode,
    Type workspaceType,
    String breadcrumb,
  })>[
    (
      mode: EditorWorkspaceMode.narrativeOverview,
      workspaceType: NarrativeOverviewWorkspace,
      breadcrumb: 'Narrative Studio  /  Aperçu',
    ),
    (
      mode: EditorWorkspaceMode.dialogue,
      workspaceType: DialogueStudioWorkspace,
      breadcrumb: 'Narrative Studio  /  Dialogues',
    ),
    (
      mode: EditorWorkspaceMode.facts,
      workspaceType: FactsWorldRulesWorkspace,
      breadcrumb: 'Narrative Studio  /  Facts',
    ),
    (
      mode: EditorWorkspaceMode.worldRules,
      workspaceType: FactsWorldRulesWorkspace,
      breadcrumb: 'Narrative Studio  /  Règles du monde',
    ),
  ];

  for (final routeCase in routeCases) {
    testWidgets(
      '${routeCase.mode.name} full route owns exactly one shared product shell and context',
      (tester) async {
        final project = _project();
        final activeMap = _map();
        final container = await pumpEditorShellPage(
          tester,
          initialState: EditorState(
            projectRootPath: projectRoot.path,
            project: project,
            activeMap: activeMap,
            workspaceMode: routeCase.mode,
            isProjectDirty: true,
          ),
          surfaceSize: const Size(1672, 941),
        );

        expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
        expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
        expect(find.byType(routeCase.workspaceType), findsOneWidget);
        expect(find.byType(ProjectExplorerPanel), findsNothing);
        expect(find.text(routeCase.breadcrumb), findsOneWidget);
        expect(find.text('Modifications non enregistrées'), findsOneWidget);
        expect(container.read(editorNotifierProvider).project, project);
        expect(container.read(editorNotifierProvider).activeMap, activeMap);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'product navigation switches Overview, Dialogues, Facts and World Rules without mutating project or map',
    (tester) async {
      final project = _project();
      final activeMap = _map();
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: projectRoot.path,
          project: project,
          activeMap: activeMap,
          workspaceMode: EditorWorkspaceMode.narrativeOverview,
          isProjectDirty: true,
        ),
        surfaceSize: const Size(1672, 941),
      );

      for (final destination in <({String key, EditorWorkspaceMode mode})>[
        (
          key: 'narrative-studio-product-nav-dialogues',
          mode: EditorWorkspaceMode.dialogue,
        ),
        (
          key: 'narrative-studio-product-nav-facts',
          mode: EditorWorkspaceMode.facts,
        ),
        (
          key: 'narrative-studio-product-nav-worldRules',
          mode: EditorWorkspaceMode.worldRules,
        ),
        (
          key: 'narrative-studio-product-nav-overview',
          mode: EditorWorkspaceMode.narrativeOverview,
        ),
      ]) {
        await tester.tap(find.byKey(ValueKey<String>(destination.key)));
        await tester.pumpAndSettle();

        final state = container.read(editorNotifierProvider);
        expect(state.workspaceMode, destination.mode);
        expect(state.project, project);
        expect(state.activeMap, activeMap);
        expect(state.isProjectDirty, isTrue);
        expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
        expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
        expect(find.byType(ProjectExplorerPanel), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('Events child navigation opens Map Events without leaving Events',
      (tester) async {
    final project = _project();
    final activeMap = _map();
    final container = await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: projectRoot.path,
        project: project,
        activeMap: activeMap,
        workspaceMode: EditorWorkspaceMode.events,
      ),
      surfaceSize: const Size(1672, 941),
    );

    await tester.tap(
      find.byKey(
        const ValueKey('narrative-studio-product-nav-map-events'),
      ),
    );
    await tester.pump();

    final navigation =
        container.read(narrativeStudioNavigationControllerProvider);
    expect(navigation.location.destination, NarrativeStudioDestination.events);
    expect(
      navigation.location.childRoute,
      NarrativeStudioChildRoute.mapEvents,
    );
    expect(
      container.read(editorNotifierProvider).workspaceMode,
      EditorWorkspaceMode.events,
    );
    expect(
      find.text('Narrative Studio  /  Événements  /  Events par map'),
      findsOneWidget,
    );
    expect(find.text('Narrative Studio  /  Validateur'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a real project switch clears deep-link and return context',
      (tester) async {
    final project = _project();
    final container = await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: projectRoot.path,
        project: project,
        activeMap: _map(),
        workspaceMode: EditorWorkspaceMode.events,
      ),
      surfaceSize: const Size(1672, 941),
    );
    final navigation =
        container.read(narrativeStudioNavigationControllerProvider.notifier);
    navigation.navigate(
      NarrativeStudioRouteLocation.events(
        childRoute: NarrativeStudioChildRoute.mapEvents,
        selection: NarrativeStudioAssetSelection(
          kind: NarrativeStudioAssetKind.event,
          assetId: 'event.port',
        ),
      ),
      returnExpectation: NarrativeStudioReturnExpectation(
        location: NarrativeStudioRouteLocation.scenes(
          selection: NarrativeStudioAssetSelection(
            kind: NarrativeStudioAssetKind.scene,
            assetId: 'scene.port',
          ),
        ),
      ),
    );
    await tester.pump();

    container.read(editorNotifierProvider.notifier).state = container
        .read(editorNotifierProvider)
        .copyWith(projectRootPath: '${projectRoot.path}/second-project');
    await tester.pump();
    await tester.pump();

    final reset = container.read(narrativeStudioNavigationControllerProvider);
    expect(
      reset.projectIdentity,
      'disk:${projectRoot.path}/second-project\u001esession:0',
    );
    expect(reset.location, NarrativeStudioRouteLocation.events());
    expect(reset.pendingReturn, isNull);
    expect(reset.restorationRequest, isNull);
    expect(
      find.text('Narrative Studio  /  Événements  /  Event Builder'),
      findsOneWidget,
    );
  });

  testWidgets('reloading the same project starts a fresh navigation session',
      (tester) async {
    final project = _project();
    final manifestPath = '${projectRoot.path}/project.json';
    await tester.runAsync(
      () => File(manifestPath).writeAsString(jsonEncode(project.toJson())),
    );
    final container = await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: projectRoot.path,
        project: project,
        workspaceMode: EditorWorkspaceMode.events,
      ),
      surfaceSize: const Size(1280, 768),
      overrides: [
        projectRepositoryProvider.overrideWithValue(
          _StaticProjectRepository(project),
        ),
      ],
    );
    final navigation =
        container.read(narrativeStudioNavigationControllerProvider.notifier);
    navigation.navigate(
      NarrativeStudioRouteLocation.events(
        childRoute: NarrativeStudioChildRoute.mapEvents,
      ),
      returnExpectation: NarrativeStudioReturnExpectation(
        location: NarrativeStudioRouteLocation.scenes(),
      ),
    );
    await tester.pump();
    final previousIdentity = container
        .read(narrativeStudioNavigationControllerProvider)
        .projectIdentity;

    await tester.runAsync(
      () => container
          .read(editorNotifierProvider.notifier)
          .loadProject(manifestPath, rememberAsRecent: false),
    );
    await tester.pump();
    await tester.pump();

    final reset = container.read(narrativeStudioNavigationControllerProvider);
    expect(reset.projectIdentity, isNot(previousIdentity));
    expect(
      reset.location.childRoute,
      isNot(NarrativeStudioChildRoute.mapEvents),
    );
    expect(reset.location.selection, isNull);
    expect(reset.pendingReturn, isNull);
    expect(reset.restorationRequest, isNull);
  });

  testWidgets('two in-memory projects do not share a null navigation identity',
      (tester) async {
    final container = await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        project: _project(),
        workspaceMode: EditorWorkspaceMode.events,
      ),
      surfaceSize: const Size(1280, 768),
    );
    final controller =
        container.read(narrativeStudioNavigationControllerProvider.notifier);
    controller.navigate(
      NarrativeStudioRouteLocation.events(
        childRoute: NarrativeStudioChildRoute.mapEvents,
      ),
      returnExpectation: NarrativeStudioReturnExpectation(
        location: NarrativeStudioRouteLocation.scenes(),
      ),
    );
    await tester.pump();

    container.read(editorNotifierProvider.notifier).state = container
        .read(editorNotifierProvider)
        .copyWith(project: _project().copyWith(name: 'Second memory project'));
    await tester.pump();
    await tester.pump();

    final reset = container.read(narrativeStudioNavigationControllerProvider);
    expect(reset.projectIdentity, startsWith('memory:Second memory project'));
    expect(reset.location, NarrativeStudioRouteLocation.events());
    expect(reset.pendingReturn, isNull);
  });

  testWidgets('generic Map chrome restores a non-Event narrative deep link',
      (tester) async {
    final container = await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: projectRoot.path,
        project: _project(),
        activeMap: _map(),
        workspaceMode: EditorWorkspaceMode.map,
      ),
      surfaceSize: const Size(1280, 768),
    );
    final expectedReturn = NarrativeStudioReturnExpectation(
      location: NarrativeStudioRouteLocation.validator(
        selection: NarrativeStudioAssetSelection(
          kind: NarrativeStudioAssetKind.diagnostic,
          assetId: 'diagnostic.map-route',
        ),
      ),
      focusAnchorId: 'diagnostic.map-route',
    );
    container
        .read(narrativeStudioNavigationControllerProvider.notifier)
        .rememberExternalReturn(expectedReturn);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('narrative-map-generic-return-banner')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('narrative-map-generic-return')),
    );
    await tester.pump();

    expect(
      container.read(editorNotifierProvider).workspaceMode,
      EditorWorkspaceMode.narrativeValidator,
    );
    final restored =
        container.read(narrativeStudioNavigationControllerProvider);
    expect(restored.location, expectedReturn.location);
    expect(restored.pendingReturn, isNull);
    expect(restored.restorationRequest?.expectation, expectedReturn);
  });

  testWidgets('shared Return preserves an exact Storyline Step child route',
      (tester) async {
    final container = await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: projectRoot.path,
        project: _project(),
        workspaceMode: EditorWorkspaceMode.dialogue,
      ),
      surfaceSize: const Size(1280, 768),
    );
    final stepLocation = NarrativeStudioRouteLocation.storylines(
      childRoute: NarrativeStudioChildRoute.storylineStep,
      selection: NarrativeStudioAssetSelection(
        kind: NarrativeStudioAssetKind.step,
        assetId: 'step.return',
        parentId: 'chapter.return',
        rootId: 'story.return',
      ),
    );
    container
        .read(narrativeStudioNavigationControllerProvider.notifier)
        .navigate(
          NarrativeStudioRouteLocation.dialogues(),
          returnExpectation: NarrativeStudioReturnExpectation(
            location: stepLocation,
          ),
        );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('narrative-studio-product-nav-return')),
    );
    await tester.pump();

    expect(
      container.read(editorNotifierProvider).workspaceMode,
      EditorWorkspaceMode.step,
    );
    expect(
      container.read(narrativeStudioNavigationControllerProvider).location,
      stepLocation,
    );
  });

  testWidgets(
    'canonical dependency Step intent opens the exact Storyline Structure row',
    (tester) async {
      final project = ProjectManifest(
        name: 'Canonical Storyline route',
        maps: const [],
        tilesets: const [],
        surfaceCatalog: const ProjectSurfaceCatalog.empty(),
        storylines: [
          StorylineAsset(
            id: 'story_target',
            type: StorylineType.main,
            title: 'Histoire cible',
            chapters: [
              StorylineChapter(
                id: 'chapter_target',
                title: 'Chapitre cible',
                order: 0,
                steps: [
                  StorylineStep(
                    id: 'step_other',
                    title: 'Autre étape',
                    order: 0,
                  ),
                  StorylineStep(
                    id: 'step_target',
                    title: 'Étape cible',
                    order: 1,
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: projectRoot.path,
          project: project,
          workspaceMode: EditorWorkspaceMode.globalStory,
        ),
        surfaceSize: const Size(1672, 941),
      );
      final intent = buildNarrativeDependencyIndex(project: project)
          .definitionsFor(
            const NarrativeDependencyKey(
              NarrativeDependencyTargetKind.step,
              'step_target',
            ),
          )
          .single
          .navigationIntent!;

      final resolution = container
          .read(narrativeStudioNavigationControllerProvider.notifier)
          .navigateToDependency(intent);
      await tester.pumpAndSettle();

      expect(
        resolution.location?.childRoute,
        NarrativeStudioChildRoute.storylineLibrary,
      );
      expect(
        container.read(editorNotifierProvider).workspaceMode,
        EditorWorkspaceMode.globalStory,
      );
      expect(
        find.byKey(
          const ValueKey('storylines-chapter-expanded-chapter_target'),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<PokeMapCard>(
              find.byKey(const ValueKey('storylines-step-row-step_target')),
            )
            .selected,
        isTrue,
      );
      expect(find.text('Étape cible'), findsOneWidget);

      container
          .read(narrativeStudioNavigationControllerProvider.notifier)
          .navigateToDependency(
            const NarrativeDependencyNavigationIntent(
              kind: NarrativeDependencyTargetKind.step,
              assetId: 'step_deleted',
              parentId: 'chapter_target',
              rootId: 'story_target',
            ),
          );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('storylines-requested-unavailable')),
        findsOneWidget,
      );
      expect(find.text('Cible de storyline introuvable'), findsOneWidget);
    },
  );

  for (final mode in <EditorWorkspaceMode>[
    EditorWorkspaceMode.narrativeOverview,
    EditorWorkspaceMode.dialogue,
    EditorWorkspaceMode.facts,
    EditorWorkspaceMode.worldRules,
  ]) {
    testWidgets(
      '${mode.name} keeps its shared context when no project is loaded',
      (tester) async {
        await pumpEditorShellPage(
          tester,
          initialState: EditorState(workspaceMode: mode),
          surfaceSize: const Size(1280, 768),
        );

        expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
        expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
        expect(find.byType(ProjectExplorerPanel), findsNothing);
        expect(find.text('Aucun projet chargé'), findsOneWidget);
        if (mode == EditorWorkspaceMode.narrativeOverview) {
          expect(
            find.byKey(
              const ValueKey('narrative-overview-project-unavailable'),
            ),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  const responsiveSizes = <Size>[
    Size(1280, 768),
    Size(1366, 768),
    Size(1440, 900),
    Size(1672, 941),
    Size(1920, 941),
  ];
  const responsiveTextScales = <double>[1, 1.25, 1.5];

  for (final routeCase in routeCases) {
    for (final size in responsiveSizes) {
      for (final textScale in responsiveTextScales) {
        testWidgets(
          '${routeCase.mode.name} is overflow-free at '
          '${size.width}x${size.height} and ${textScale * 100}% text',
          (tester) async {
            tester.platformDispatcher.textScaleFactorTestValue = textScale;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );

            await pumpEditorShellPage(
              tester,
              initialState: EditorState(
                projectRootPath: projectRoot.path,
                project: _project(),
                activeMap: _map(),
                workspaceMode: routeCase.mode,
              ),
              surfaceSize: size,
            );

            expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
            expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  for (final goldenCase in <({
    EditorWorkspaceMode mode,
    String routeName,
  })>[
    (
      mode: EditorWorkspaceMode.narrativeOverview,
      routeName: 'overview',
    ),
    (
      mode: EditorWorkspaceMode.dialogue,
      routeName: 'dialogues',
    ),
    (
      mode: EditorWorkspaceMode.facts,
      routeName: 'facts',
    ),
    (
      mode: EditorWorkspaceMode.worldRules,
      routeName: 'world_rules',
    ),
  ]) {
    testWidgets(
      'matches the full ${goldenCase.routeName} product route at 1672x941',
      (tester) async {
        await _loadSpecializedRoutesCaptureFonts();
        await pumpEditorShellPage(
          tester,
          initialState: EditorState(
            projectRootPath: projectRoot.path,
            project: _project(),
            activeMap: _map(),
            workspaceMode: goldenCase.mode,
          ),
          surfaceSize: const Size(1672, 941),
          fontFamily: _specializedRoutesCaptureFontFamily,
          cupertinoFontFamily: _specializedRoutesCaptureFontFamily,
        );
        await tester.pumpAndSettle();

        final output = File(
          'test/goldens/narrative_studio/${goldenCase.routeName}/'
          '${goldenCase.routeName}_full_product_route_1672x941.png',
        );
        output.parent.createSync(recursive: true);
        await expectLater(
          find.byType(EditorShellPage),
          matchesGoldenFile(output.absolute.path),
        );
      },
    );
  }
}

Future<void> _loadSpecializedRoutesCaptureFonts() async {
  await loadNarrativeStudioCaptureFonts(
    textFamilies: const <String>[_specializedRoutesCaptureFontFamily],
  );
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Specialized routes',
    maps: const [
      ProjectMapEntry(
        id: 'map_route',
        name: 'Route',
        relativePath: 'maps/route.json',
      ),
    ],
    tilesets: const [],
    facts: [
      NarrativeFactDefinition(id: 'fact_started', label: 'A commencé'),
    ],
  );
}

MapData _map() {
  return const MapData(
    id: 'map_route',
    name: 'Route',
    size: GridSize(width: 12, height: 10),
  );
}

final class _StaticProjectRepository implements ProjectRepository {
  const _StaticProjectRepository(this.project);

  final ProjectManifest project;

  @override
  Future<ProjectManifest> loadProject(String path) async => project;

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {}
}
