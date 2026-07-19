import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_scene_focus_provider.dart';
import 'package:map_editor/src/features/narrative/state/narrative_validator_providers.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_destination.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_navigation.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart';
import 'package:map_editor/src/ui/canvas/narrative_validator_workspace.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  testWidgets(
    'Validator is a real Narrative Studio route and jumps to Fact and Scene sources',
    (tester) async {
      final project = ProjectManifest(
        name: 'Validator route project',
        maps: const [],
        tilesets: const [],
        surfaceCatalog: const ProjectSurfaceCatalog.empty(),
        facts: [
          NarrativeFactDefinition(
            id: 'fact_other',
            label: 'Autre Fact',
          ),
          NarrativeFactDefinition(
            id: 'fact_passage',
            label: 'Passage exact',
          ),
        ],
        scenes: [
          _scene(id: 'scene_other', name: 'Autre scène'),
          _scene(id: 'scene_ending', name: 'Scène de fin exacte'),
        ],
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
        initialState: EditorState(
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
      final factNavigation =
          container.read(narrativeStudioNavigationControllerProvider);
      expect(factNavigation.location.selection?.kind,
          NarrativeStudioAssetKind.fact);
      expect(factNavigation.location.selection?.assetId, 'fact_passage');
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const ValueKey('fact-editor-label-field')),
                matching: find.byType(TextField),
              ),
            )
            .controller
            ?.text,
        'Passage exact',
      );
      expect(
        factNavigation.pendingReturn?.location.selection?.kind,
        NarrativeStudioAssetKind.diagnostic,
      );

      await tester.tap(find.byKey(
        const ValueKey('narrative-studio-product-nav-return'),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(NarrativeValidatorWorkspace), findsOneWidget);
      expect(
        find.byKey(
          ValueKey(
            'narrative-validator-diagnostic-${report.diagnostics.last.stableKey}',
          ),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Focus>(
              find.byKey(
                ValueKey(
                  'narrative-validator-diagnostic-${report.diagnostics.last.stableKey}',
                ),
              ),
            )
            .focusNode
            ?.hasFocus,
        isTrue,
      );
      expect(
        container
            .read(narrativeStudioNavigationControllerProvider)
            .restorationRequest,
        isNull,
      );

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
      final sceneNavigation =
          container.read(narrativeStudioNavigationControllerProvider);
      expect(sceneNavigation.location.selection?.kind,
          NarrativeStudioAssetKind.scene);
      expect(sceneNavigation.location.selection?.assetId, 'scene_ending');
      expect(
        tester
            .widget<PokeMapSidebarItem>(
              find.byKey(const ValueKey('scenes-tree-item-scene_ending')),
            )
            .selected,
        isTrue,
      );
      expect(find.byType(NarrativeValidatorWorkspace), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Validator opens the exact World Rule editor instead of the first rule',
    (tester) async {
      final project = ProjectManifest(
        name: 'World Rule route project',
        maps: const [],
        tilesets: const [],
        surfaceCatalog: const ProjectSurfaceCatalog.empty(),
        facts: [
          NarrativeFactDefinition(id: 'fact_gate', label: 'Portail ouvert'),
        ],
        worldRules: [
          _worldRule(id: 'rule_other', label: 'Autre règle'),
          _worldRule(id: 'rule_target', label: 'Règle exacte'),
        ],
      );
      const diagnostic = NarrativeProjectDiagnostic(
        code: 'worldRuleTargetMissing',
        severity: NarrativeProjectDiagnosticSeverity.error,
        domain: NarrativeProjectDiagnosticDomain.worldRule,
        message: 'La règle exacte doit être revue.',
        path: 'worldRules.rule_target',
        destination: NarrativeProjectDiagnosticDestination.worldRule,
        worldRuleId: 'rule_target',
      );
      await _pumpValidatorShell(
        tester,
        project: project,
        diagnostics: const [diagnostic],
      );

      await tester.tap(find.text('Ouvrir la source'));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(
                  const ValueKey('world-rule-editor-label-field'),
                ),
                matching: find.byType(TextField),
              ),
            )
            .controller
            ?.text,
        'Règle exacte',
      );
    },
  );

  testWidgets(
    'Validator opens an exact Storyline chapter and step in Structure',
    (tester) async {
      final project = ProjectManifest(
        name: 'Storyline route project',
        maps: const [],
        tilesets: const [],
        surfaceCatalog: const ProjectSurfaceCatalog.empty(),
        storylines: [
          StorylineAsset(
            id: 'story_other',
            type: StorylineType.main,
            title: 'Autre histoire',
          ),
          StorylineAsset(
            id: 'story_target',
            type: StorylineType.sideQuest,
            title: 'Histoire exacte',
            chapters: [
              StorylineChapter(
                id: 'chapter_other',
                title: 'Autre chapitre',
                order: 0,
              ),
              StorylineChapter(
                id: 'chapter_target',
                title: 'Chapitre exact',
                order: 1,
                steps: [
                  StorylineStep(
                    id: 'step_other',
                    title: 'Autre étape',
                    order: 0,
                  ),
                  StorylineStep(
                    id: 'step_target',
                    title: 'Étape exacte',
                    order: 1,
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      const diagnostic = NarrativeProjectDiagnostic(
        code: 'storylineStepNeverCompleted',
        severity: NarrativeProjectDiagnosticSeverity.error,
        domain: NarrativeProjectDiagnosticDomain.storyline,
        message: 'L’étape exacte est bloquée.',
        path: 'storylines.story_target.chapter_target.step_target',
        destination: NarrativeProjectDiagnosticDestination.storyline,
        storylineId: 'story_target',
        chapterId: 'chapter_target',
        stepId: 'step_target',
      );
      await _pumpValidatorShell(
        tester,
        project: project,
        diagnostics: const [diagnostic],
      );

      await tester.tap(find.text('Ouvrir la source'));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<PokeMapCard>(
              find.descendant(
                of: find.byKey(
                  const ValueKey('storylines-v1-row-story_target'),
                ),
                matching: find.byType(PokeMapCard),
              ),
            )
            .selected,
        isTrue,
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
      expect(find.text('Étape exacte'), findsOneWidget);
    },
  );

  testWidgets(
    'Validator keeps its route when an external Map cannot be loaded',
    (tester) async {
      const project = ProjectManifest(
        name: 'Unavailable map route project',
        maps: [
          ProjectMapEntry(
            id: 'map_missing',
            name: 'Map absente',
            relativePath: 'maps/map_missing.json',
          ),
        ],
        tilesets: [],
        surfaceCatalog: ProjectSurfaceCatalog.empty(),
      );
      const diagnostic = NarrativeProjectDiagnostic(
        code: 'mapUnavailable',
        severity: NarrativeProjectDiagnosticSeverity.error,
        domain: NarrativeProjectDiagnosticDomain.map,
        message: 'La map cible est indisponible.',
        path: 'maps.map_missing',
        destination: NarrativeProjectDiagnosticDestination.map,
        mapId: 'map_missing',
      );
      final container = await _pumpValidatorShell(
        tester,
        project: project,
        diagnostics: const [diagnostic],
      );

      await tester.tap(find.text('Ouvrir la source'));
      await tester.pumpAndSettle();

      expect(
        container.read(editorNotifierProvider).workspaceMode,
        EditorWorkspaceMode.narrativeValidator,
      );
      final navigation =
          container.read(narrativeStudioNavigationControllerProvider);
      expect(
        navigation.location.destination,
        NarrativeStudioDestination.validator,
      );
      expect(navigation.pendingReturn, isNull);
      expect(find.byType(NarrativeValidatorWorkspace), findsOneWidget);
    },
  );

  testWidgets(
    'Validator rejects a stale Dialogue target without leaving its route',
    (tester) async {
      const project = ProjectManifest(
        name: 'Stale Dialogue route project',
        maps: [],
        tilesets: [],
        surfaceCatalog: ProjectSurfaceCatalog.empty(),
      );
      const diagnostic = NarrativeProjectDiagnostic(
        code: 'dialogueMissing',
        severity: NarrativeProjectDiagnosticSeverity.error,
        domain: NarrativeProjectDiagnosticDomain.dialogue,
        message: 'Le dialogue supprimé doit être vérifié.',
        path: 'dialogues.dialogue_missing',
        destination: NarrativeProjectDiagnosticDestination.dialogue,
        dialogueId: 'dialogue_missing',
      );
      final container = await _pumpValidatorShell(
        tester,
        project: project,
        diagnostics: const [diagnostic],
      );

      await tester.tap(find.text('Ouvrir la source'));
      await tester.pump();
      for (var frame = 0; frame < 5; frame += 1) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final editor = container.read(editorNotifierProvider);
      final navigation =
          container.read(narrativeStudioNavigationControllerProvider);
      expect(editor.workspaceMode, EditorWorkspaceMode.narrativeValidator);
      expect(editor.errorMessage, contains('dialogue_missing'));
      expect(
        navigation.location.destination,
        NarrativeStudioDestination.validator,
      );
      expect(navigation.pendingReturn, isNull);
      expect(find.byType(NarrativeValidatorWorkspace), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Validator rejects a stale Event target without arming a return',
    (tester) async {
      const project = ProjectManifest(
        name: 'Stale Event route project',
        maps: [],
        tilesets: [],
        surfaceCatalog: ProjectSurfaceCatalog.empty(),
      );
      const diagnostic = NarrativeProjectDiagnostic(
        code: 'eventMissing',
        severity: NarrativeProjectDiagnosticSeverity.error,
        domain: NarrativeProjectDiagnosticDomain.event,
        message: 'L’événement supprimé doit être vérifié.',
        path: 'events.event_missing',
        destination: NarrativeProjectDiagnosticDestination.event,
        eventId: 'event_missing',
      );
      final container = await _pumpValidatorShell(
        tester,
        project: project,
        diagnostics: const [diagnostic],
      );

      await tester.tap(find.text('Ouvrir la source'));
      await tester.pump();
      for (var frame = 0; frame < 5; frame += 1) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final editor = container.read(editorNotifierProvider);
      final navigation =
          container.read(narrativeStudioNavigationControllerProvider);
      expect(editor.workspaceMode, EditorWorkspaceMode.narrativeValidator);
      expect(editor.errorMessage, contains('event_missing'));
      expect(
        navigation.location.destination,
        NarrativeStudioDestination.validator,
      );
      expect(navigation.pendingReturn, isNull);
      expect(find.byType(NarrativeValidatorWorkspace), findsOneWidget);
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

Future<ProviderContainer> _pumpValidatorShell(
  WidgetTester tester, {
  required ProjectManifest project,
  required List<NarrativeProjectDiagnostic> diagnostics,
}) async {
  return pumpEditorShellPage(
    tester,
    initialState: EditorState(
      projectRootPath: '/virtual/exact-validator-project',
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
        (_, __) async => NarrativeProjectValidationReport(
          diagnostics: diagnostics,
          mapEventViews: const [],
        ),
      ),
    ],
  );
}

SceneAsset _scene({required String id, required String name}) => SceneAsset(
      id: id,
      name: name,
      graph: SceneGraph(
        startNodeId: '${id}_start',
        nodes: [
          SceneNode(id: '${id}_start', kind: SceneNodeKind.start),
        ],
        edges: const [],
      ),
    );

WorldRuleDefinition _worldRule({
  required String id,
  required String label,
}) =>
    WorldRuleDefinition(
      id: id,
      label: label,
      source: const WorldRuleSource(
        kind: WorldRuleSourceKind.fact,
        sourceId: 'fact_gate',
        predicate: WorldRuleSourcePredicate.isTrue,
      ),
      target: const WorldRuleTarget(
        kind: WorldRuleTargetKind.mapEvent,
        mapId: 'map_gate',
        eventId: 'event_gate',
      ),
      effect: const WorldRuleEffect(
        kind: WorldRuleEffectKind.eventEnabled,
      ),
    );
