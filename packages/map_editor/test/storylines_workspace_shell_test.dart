import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_workspace_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  group('NS-STORYLINES-V1-07 create main storyline flow', () {
    testWidgets('shows only Graph and Structure tabs', (tester) async {
      await _pumpStorylinesShell(tester);

      final tabs = find.byKey(const ValueKey('storylines-tabs'));
      expect(find.descendant(of: tabs, matching: find.text('Graph')),
          findsOneWidget);
      expect(find.descendant(of: tabs, matching: find.text('Structure')),
          findsOneWidget);
      expect(find.descendant(of: tabs, matching: find.text('Étapes')),
          findsNothing);
      expect(find.descendant(of: tabs, matching: find.text('Scènes')),
          findsNothing);
      expect(find.descendant(of: tabs, matching: find.text('Statistiques')),
          findsNothing);
      expect(find.descendant(of: tabs, matching: find.text('Tests')),
          findsNothing);
    });

    testWidgets('shows V1 empty state without importing legacy globalStory',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _legacyOnlyProject(),
      );

      expect(find.text('Aucune storyline auteur'), findsWidgets);
      expect(find.byKey(const ValueKey('storylines-create-main-cta')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-graph-target-read-only')),
          findsOneWidget);
      expect(find.textContaining('ne sera pas importée automatiquement'),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-v1-legacy-preview-card')),
          findsOneWidget);
      expect(find.text('Legacy Global Story'), findsWidgets);
      expect(harness.project.storylines, isEmpty);
      expect(harness.project.scenarios.single.scope, ScenarioScope.globalStory);
    });

    testWidgets(
        'opens and cancels create main storyline dialog without mutation',
        (tester) async {
      final harness = await _pumpStorylinesShell(tester);
      final before = harness.project.toJson();

      await _openCreateDialog(tester);
      expect(find.byKey(const ValueKey('storylines-create-main-dialog')),
          findsOneWidget);
      expect(find.text('Histoire principale'), findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-create-title-field')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-create-description-field')),
          findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('storylines-create-cancel')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('storylines-create-main-dialog')),
          findsNothing);
      expect(harness.project.storylines, isEmpty);
      expect(harness.project.toJson(), before);
    });

    testWidgets('requires title before create', (tester) async {
      final harness = await _pumpStorylinesShell(tester);

      await _openCreateDialog(tester);

      final submit = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('storylines-create-submit')),
      );
      expect(submit.onPressed, isNull);
      expect(find.text('Titre obligatoire.'), findsOneWidget);
      expect(harness.project.storylines, isEmpty);
    });

    testWidgets('creates a main StorylineAsset and syncs Graph and Structure',
        (tester) async {
      final harness = await _pumpStorylinesShell(tester);

      await _createMainStoryline(
        tester,
        title: 'Ma grande histoire',
        description: 'Une structure auteur propre.',
      );

      final storylines = harness.project.storylines;
      expect(storylines, hasLength(1));
      final storyline = storylines.single;
      expect(storyline.id, 'storyline_ma_grande_histoire');
      expect(storyline.type, StorylineType.main);
      expect(storyline.status, StorylineStatus.draft);
      expect(storyline.title, 'Ma grande histoire');
      expect(storyline.description, 'Une structure auteur propre.');
      expect(storyline.chapters, isEmpty);
      expect(storyline.sceneLinks, isEmpty);
      expect(storyline.relationships, isEmpty);

      expect(find.text('Ma grande histoire'), findsWidgets);
      expect(
          find.text('Ajoutez des chapitres dans Structure.'), findsOneWidget);

      await _openStructureTab(tester);
      expect(find.byKey(const ValueKey('storylines-structure-read-only')),
          findsOneWidget);
      expect(find.text('Chapitres'), findsWidgets);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('storylines-v1-structure-steps')),
          matching: find.text('Étapes narratives'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('storylines-v1-structure-scenes')),
          matching: find.text('Scènes liées'),
        ),
        findsOneWidget,
      );
      expect(find.text('Nouveau chapitre — bientôt'), findsOneWidget);
    });

    testWidgets('generates stable unique ids on collision', (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_main_story',
            type: StorylineType.sideQuest,
            title: 'Existing secondary',
          ),
        ]),
      );

      await _createMainStoryline(tester, title: 'Main Story');

      final ids = harness.project.storylines.map((s) => s.id).toList();
      expect(ids, contains('storyline_main_story'));
      expect(ids, contains('storyline_main_story_2'));
      expect(ids.toSet(), hasLength(ids.length));
      expect(
        harness.project.storylines
            .where((s) => s.type == StorylineType.sideQuest),
        hasLength(1),
      );
    });

    testWidgets('does not allow creating a second main storyline',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );

      final cta = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('storylines-create-main-cta')),
      );
      expect(cta.onPressed, isNull);
      expect(harness.project.storylines, hasLength(1));
    });

    testWidgets('creation does not import legacy or promote localEventFlow',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _legacyAndLocalEventProject(),
      );

      await _createMainStoryline(tester, title: 'Fresh Main Story');

      expect(harness.project.storylines, hasLength(1));
      expect(harness.project.storylines.single.title, 'Fresh Main Story');
      expect(harness.project.storylines.single.legacySource, isNull);
      expect(
        harness.project.storylines
            .where((s) => s.type == StorylineType.sideQuest),
        isEmpty,
      );
      expect(harness.project.scenarios, hasLength(2));
      expect(
        harness.project.scenarios.map((scenario) => scenario.scope),
        containsAll([ScenarioScope.globalStory, ScenarioScope.localEventFlow]),
      );
      expect(find.text('Legacy Global Story'), findsNothing);
      expect(find.text('Local Event Flow'), findsNothing);
    });

    testWidgets('Graph, Structure and disabled chapter CTA do not mutate',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );
      final before = harness.project.toJson();
      final beforeMode = harness.editorState.workspaceMode;

      await _openStructureTab(tester);
      await tester.tap(
        find.byKey(const ValueKey('storylines-new-chapter-disabled')),
        warnIfMissed: false,
      );
      await tester.pump();
      await _openGraphTab(tester);

      expect(harness.project.toJson(), before);
      expect(harness.editorState.workspaceMode, beforeMode);
    });

    testWidgets('keeps target fake data and Maps out of the V1 UI',
        (tester) async {
      await _pumpStorylinesShell(tester,
          project: _legacyAndLocalEventProject());

      for (final value in _targetOnlyStrings) {
        expect(find.text(value), findsNothing, reason: value);
      }
      expect(find.text('Maps'), findsNothing);
    });

    test('storylines UI source keeps raw colors out of the feature', () {
      final source = File('lib/src/ui/canvas/storylines_workspace.dart');
      expect(source.existsSync(), isTrue);

      final contents = source.readAsStringSync();
      const rawColorPattern = 'Color' '(0x';
      const materialColorsPattern = 'Colors' '.';
      expect(contents, isNot(contains(rawColorPattern)));
      expect(contents, isNot(contains(materialColorsPattern)));
    });

    test('storylines shell test keeps raw colors out', () {
      final source = File('test/storylines_workspace_shell_test.dart');
      expect(source.existsSync(), isTrue);

      final contents = source.readAsStringSync();
      const rawColorPattern = 'Color' '(0x';
      const materialColorsPattern = 'Colors' '.';
      expect(contents, isNot(contains(rawColorPattern)));
      expect(contents, isNot(contains(materialColorsPattern)));
    });

    testWidgets('uses PokeMap dark theme in the Visual Gate harness',
        (tester) async {
      await _pumpStorylinesShell(tester);

      final shellContext = tester.element(
        find.byKey(const ValueKey('storylines-workspace-shell')),
      );
      expect(Theme.of(shellContext).brightness, Brightness.dark);
    });

    testWidgets('writes V1-07 Visual Gate screenshots', (tester) async {
      await _pumpStorylinesShell(tester, surfaceSize: const Size(1600, 1000));
      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_v1_07_empty_storylines_desktop.png',
        ),
      );

      await _pumpStorylinesShell(tester, surfaceSize: const Size(1600, 1000));
      await _openCreateDialog(tester);
      await expectLater(
        find.byKey(const ValueKey('storylines-create-main-dialog')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_v1_07_create_main_dialog.png',
        ),
      );
      await tester.tap(find.byKey(const ValueKey('storylines-create-cancel')));
      await tester.pumpAndSettle();

      await _pumpStorylinesShell(tester, surfaceSize: const Size(1600, 1000));
      await _createMainStoryline(tester, title: 'Visual Gate Main');
      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_v1_07_created_main_graph.png',
        ),
      );

      await _openStructureTab(tester);
      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_v1_07_created_main_structure.png',
        ),
      );
    });
  });
}

const _targetOnlyStrings = <String>[
  'Histoire globale',
  'La brume du phare',
  'Le port',
  'Les marais',
  'Le phare',
  'Les cristaux de sel',
  'Le Goélise du port',
  'La cabane du phare',
  'Mystère',
  'Exploration',
  'Phare',
  'Côtiers',
  '5 chapitres',
  '27 scènes',
  '412 dialogues',
  '18 facts',
  '3 problèmes',
  'Active',
  'Haute',
  'Validé',
  'Défini',
  'En cours',
  'Quête annexe fake',
];

Future<void> _openCreateDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('storylines-create-main-cta')));
  await tester.pumpAndSettle();
}

Future<void> _createMainStoryline(
  WidgetTester tester, {
  required String title,
  String? description,
}) async {
  await _openCreateDialog(tester);
  await tester.enterText(
    find.byKey(const ValueKey('storylines-create-title-field')),
    title,
  );
  if (description != null) {
    await tester.enterText(
      find.byKey(const ValueKey('storylines-create-description-field')),
      description,
    );
  }
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('storylines-create-submit')));
  await tester.pumpAndSettle();
}

Future<void> _openStructureTab(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(const ValueKey('storylines-tabs')),
      matching: find.text('Structure'),
    ),
  );
  await tester.pump();
}

Future<void> _openGraphTab(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(const ValueKey('storylines-tabs')),
      matching: find.text('Graph'),
    ),
  );
  await tester.pump();
}

Future<_StorylinesHarness> _pumpStorylinesShell(
  WidgetTester tester, {
  Size surfaceSize = const Size(1600, 1000),
  ProjectManifest? project,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = ProviderContainer();
  addTearDown(container.dispose);
  final editorSubscription = container.listen(
    editorNotifierProvider,
    (_, __) {},
  );
  addTearDown(editorSubscription.close);

  container.read(editorNotifierProvider.notifier).state = EditorState(
    project: project ?? _emptyStorylinesProject(),
    workspaceMode: EditorWorkspaceMode.globalStory,
  );
  container
      .read(narrativeWorkspaceControllerProvider.notifier)
      .openGlobalStory();

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.light(),
        darkTheme: PokeMapTheme.dark(),
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: SizedBox(
            width: surfaceSize.width,
            height: surfaceSize.height,
            child: const NarrativeWorkspaceCanvas(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();

  return _StorylinesHarness(container);
}

ProjectManifest _emptyStorylinesProject() {
  return const ProjectManifest(
    surfaceCatalog: ProjectSurfaceCatalog.empty(),
    name: 'Audit Project',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
  );
}

ProjectManifest _legacyOnlyProject() {
  return const ProjectManifest(
    surfaceCatalog: ProjectSurfaceCatalog.empty(),
    name: 'Legacy Project',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
    scenarios: <ScenarioAsset>[
      ScenarioAsset(
        id: 'legacy_global_story',
        name: 'Legacy Global Story',
        description: 'Legacy description',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
      ),
    ],
  );
}

ProjectManifest _legacyAndLocalEventProject() {
  return const ProjectManifest(
    surfaceCatalog: ProjectSurfaceCatalog.empty(),
    name: 'Legacy Project',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
    scenarios: <ScenarioAsset>[
      ScenarioAsset(
        id: 'legacy_global_story',
        name: 'Legacy Global Story',
        description: 'Legacy description',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
      ),
      ScenarioAsset(
        id: 'local_event_flow',
        name: 'Local Event Flow',
        description: 'Must not become side quest',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'local_start',
      ),
    ],
  );
}

ProjectManifest _projectWithStorylines(List<StorylineAsset> storylines) {
  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: 'Storylines Project',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    storylines: storylines,
  );
}

class _StorylinesHarness {
  const _StorylinesHarness(this.container);

  final ProviderContainer container;

  EditorState get editorState => container.read(editorNotifierProvider);

  ProjectManifest get project => editorState.project!;
}
