import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart';
import 'package:map_editor/src/features/narrative/application/global_story_studio_authoring.dart';
import 'package:map_editor/src/features/narrative/application/overview/narrative_overview_read_model.dart';
import 'package:map_editor/src/features/narrative/application/step_studio_authoring.dart';
import 'package:map_editor/src/ui/canvas/narrative_overview_workspace.dart';

void main() {
  testWidgets(
    'NarrativeOverviewWorkspace renders a minimal authoring overview from the read model',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject('test_project'),
      );

      await _pumpOverview(tester, readModel);

      expect(find.text('Aperçu'), findsOneWidget);
      expect(
        find.text('Vue d’ensemble auteur du Narrative Studio.'),
        findsOneWidget,
      );
      expect(find.textContaining('test_project'), findsOneWidget);
      expect(find.textContaining('Non évalué'), findsWidgets);
      expect(
        find.textContaining(
          'Les sections détaillées seront construites dans les lots suivants.',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(find.text('Indicateurs auteur'), findsOneWidget);
      for (final label in <String>[
        'Chapitres',
        'Scènes',
        'Cinématiques',
        'Quêtes',
        'Dialogues',
        'Problèmes ouverts',
      ]) {
        expect(find.text(label), findsWidgets);
      }
      for (final metricId in <String>[
        'chapters',
        'scenes',
        'cutscenes',
        'quests',
        'dialogues',
        'open_issues',
      ]) {
        expect(
          find.byKey(ValueKey('narrative-overview-kpi-$metricId')),
          findsOneWidget,
        );
      }
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace does not present unavailable modules as real data',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject('test_project'),
      );

      await _pumpOverview(tester, readModel);

      expect(_textInKpi('dialogues', '0'), findsOneWidget);
      expect(_textInKpi('chapters', '0'), findsOneWidget);
      expect(_textInKpi('quests', 'Hors scope V0'), findsOneWidget);
      expect(_textInKpi('quests', 'Pas de modèle Quest'), findsOneWidget);
      expect(_textInKpi('open_issues', 'Non évalué'), findsOneWidget);
      expect(
        _textInKpi('open_issues', 'Validation non lancée'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Facts : nécessite un modèle', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Activité récente : hors scope V0',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Notifications : hors scope V0',
          skipOffstage: false,
        ),
        findsOneWidget,
      );

      expect(find.textContaining('Selbrume'), findsNothing);
      expect(find.textContaining('La brume du phare'), findsNothing);
      expect(find.text('42'), findsNothing);
      expect(find.text('1 236'), findsNothing);
      expect(find.text('1236'), findsNothing);
      expect(find.text('24'), findsNothing);
      expect(find.text('12'), findsNothing);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace KPI cards consume read model values',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject(
          'test_project',
          dialogues: const <ProjectDialogueEntry>[
            ProjectDialogueEntry(
              id: 'test_dialogue_1',
              name: 'Test Dialogue',
              relativePath: 'dialogues/test_dialogue_1.yarn',
            ),
          ],
        ),
      );

      await _pumpOverview(tester, readModel, width: 960);

      expect(_textInKpi('dialogues', '1'), findsOneWidget);
      expect(_textInKpi('dialogues', 'Disponible'), findsOneWidget);
      expect(_textInKpi('quests', 'Hors scope V0'), findsOneWidget);
      expect(_textInKpi('open_issues', 'Non évalué'), findsOneWidget);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace KPI layout renders on a narrower desktop width',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject('test_project'),
      );

      await _pumpOverview(tester, readModel, width: 620, height: 720);

      expect(find.text('Aperçu'), findsOneWidget);
      expect(find.text('Vue d’ensemble auteur du Narrative Studio.'),
          findsOneWidget);
      expect(find.textContaining('test_project'), findsOneWidget);
      expect(find.byKey(const ValueKey('narrative-overview-kpi-grid')),
          findsOneWidget);
      expect(_textInKpi('cutscenes', '0'), findsOneWidget);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace renders an honest empty main story card',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject('test_project'),
      );

      await _pumpOverview(tester, readModel);

      expect(find.byKey(const ValueKey('narrative-overview-main-story-card')),
          findsOneWidget);
      expect(find.text('Histoire principale'), findsOneWidget);
      expect(find.text('Aucune histoire principale'), findsOneWidget);
      expect(find.text('Aucune histoire principale définie.'), findsOneWidget);
      expect(find.text('Modifier à venir'), findsOneWidget);
      expect(_textInMainStory('Problèmes ouverts'), findsOneWidget);
      expect(_textInMainStory('Non évalué'), findsWidgets);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace renders explicit main story data from the read model',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject(
          'test_project',
          scenarios: <ScenarioAsset>[
            _globalStoryWithDocuments(),
            _cutsceneScenario(
              id: 'test_cutscene_1',
              dialogueId: 'test_dialogue_1',
            ),
          ],
          dialogues: const <ProjectDialogueEntry>[
            ProjectDialogueEntry(
              id: 'test_dialogue_1',
              name: 'Test Dialogue',
              relativePath: 'dialogues/test_dialogue_1.yarn',
            ),
          ],
        ),
      );

      await _pumpOverview(tester, readModel, width: 1040, height: 960);

      expect(find.text('Test Main Story'), findsOneWidget);
      expect(find.text('A generic authoring synopsis.'), findsOneWidget);
      expect(_textInMainStory('Scènes liées'), findsOneWidget);
      expect(_textInMainStory('Dialogues liés'), findsOneWidget);
      expect(_textInMainStory('1'), findsNWidgets(2));
      expect(_textInMainStory('Problèmes ouverts'), findsOneWidget);
      expect(_textInMainStory('Non évalué'), findsWidgets);
      expect(find.text('Test Chapter One'), findsOneWidget);
      expect(find.text('Test Chapter Two'), findsOneWidget);
      expect(find.textContaining('Fallback'), findsNothing);
      expect(find.textContaining('Selbrume'), findsNothing);
      expect(find.textContaining('La brume du phare'), findsNothing);
      expect(find.text('42'), findsNothing);
      expect(find.text('27'), findsNothing);
      expect(find.text('412'), findsNothing);
      expect(find.text('3'), findsNothing);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace explains missing description and fallback chapters',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject(
          'test_project',
          scenarios: const <ScenarioAsset>[
            ScenarioAsset(
              id: 'test_global_story',
              name: 'Fallback Test Story',
              description: '',
              scope: ScenarioScope.globalStory,
              entryNodeId: 'start',
              metadata: <String, String>{
                'step.id': 'test_step_1',
                'step.name': 'Fallback Step',
                'step.cutsceneIds': 'test_cutscene_1',
              },
            ),
            ScenarioAsset(
              id: 'test_cutscene_1',
              name: 'Test Cutscene',
              scope: ScenarioScope.localEventFlow,
              entryNodeId: 'start',
              metadata: <String, String>{
                kCutsceneStudioSchemaMetadataKey: kCutsceneStudioSchemaVersion,
              },
            ),
          ],
        ),
      );

      await _pumpOverview(tester, readModel, width: 1040, height: 960);

      expect(find.text('Fallback Test Story'), findsOneWidget);
      expect(find.text('Synopsis non renseigné.'), findsOneWidget);
      expect(find.text('Chapitres issus d’un fallback'), findsOneWidget);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace renders ambiguous main story state explicitly',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject(
          'test_project',
          scenarios: const <ScenarioAsset>[
            ScenarioAsset(
              id: 'test_global_story_a',
              name: 'Test Story A',
              scope: ScenarioScope.globalStory,
              entryNodeId: 'start',
            ),
            ScenarioAsset(
              id: 'test_global_story_b',
              name: 'Test Story B',
              scope: ScenarioScope.globalStory,
              entryNodeId: 'start',
            ),
          ],
        ),
      );

      await _pumpOverview(tester, readModel);

      expect(find.text('Sélection requise'), findsOneWidget);
      expect(find.text('Plusieurs histoires principales possibles.'),
          findsOneWidget);
      expect(find.text('Source ambiguë'), findsOneWidget);
      expect(_textInMainStory('Indisponible'), findsWidgets);
      expect(find.text('Test Story A'), findsNothing);
      expect(find.text('Test Story B'), findsNothing);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace captures KPI cards screenshot when requested',
    (tester) async {
      if (!const bool.fromEnvironment('NS_HOME_04_CAPTURE_SCREENSHOT')) {
        return;
      }

      await _loadScreenshotFont();
      tester.view.physicalSize = const Size(1180, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject(
          'test_project',
          dialogues: const <ProjectDialogueEntry>[
            ProjectDialogueEntry(
              id: 'test_dialogue_1',
              name: 'Test Dialogue',
              relativePath: 'dialogues/test_dialogue_1.yarn',
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MacosTheme(
          data: MacosThemeData.dark(),
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: ColoredBox(
                key: const ValueKey('ns-home-04-screenshot-root'),
                color: const Color(0xFF07111F),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontFamily: _screenshotFontFamily),
                  child: Center(
                    child: SizedBox(
                      width: 1180,
                      height: 760,
                      child: NarrativeOverviewWorkspace(readModel: readModel),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final screenshotFile = File(
        '../../reports/narrativeStudio/ui/screenshots/'
        'ns_home_04_overview_kpi_cards.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('ns-home-04-screenshot-root')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace captures main story card screenshot when requested',
    (tester) async {
      if (!const bool.fromEnvironment('NS_HOME_05_CAPTURE_SCREENSHOT')) {
        return;
      }

      await _loadScreenshotFont();
      tester.view.physicalSize = const Size(1180, 980);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject(
          'test_project',
          scenarios: <ScenarioAsset>[
            _globalStoryWithDocuments(),
            _cutsceneScenario(
              id: 'test_cutscene_1',
              dialogueId: 'test_dialogue_1',
            ),
          ],
          dialogues: const <ProjectDialogueEntry>[
            ProjectDialogueEntry(
              id: 'test_dialogue_1',
              name: 'Test Dialogue',
              relativePath: 'dialogues/test_dialogue_1.yarn',
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MacosTheme(
          data: MacosThemeData.dark(),
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: ColoredBox(
                key: const ValueKey('ns-home-05-screenshot-root'),
                color: const Color(0xFF07111F),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontFamily: _screenshotFontFamily),
                  child: Center(
                    child: SizedBox(
                      width: 1180,
                      height: 980,
                      child: NarrativeOverviewWorkspace(readModel: readModel),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final screenshotFile = File(
        '../../reports/narrativeStudio/ui/screenshots/'
        'ns_home_05_overview_main_story_card.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('ns-home-05-screenshot-root')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );
}

const _screenshotFontFamily = 'NsHome04ScreenshotFont';

Future<void> _loadScreenshotFont() async {
  final fontBytes =
      File('/System/Library/Fonts/Supplemental/Arial.ttf').readAsBytesSync();
  final loader = FontLoader(_screenshotFontFamily)
    ..addFont(Future<ByteData>.value(ByteData.sublistView(fontBytes)));
  await loader.load();
}

Finder _textInKpi(String metricId, String text) {
  return find.descendant(
    of: find.byKey(ValueKey('narrative-overview-kpi-$metricId')),
    matching: find.text(text),
  );
}

Finder _textInMainStory(String text) {
  return find.descendant(
    of: find.byKey(const ValueKey('narrative-overview-main-story-card')),
    matching: find.text(text),
  );
}

Future<void> _pumpOverview(
  WidgetTester tester,
  NarrativeOverviewReadModel readModel, {
  double width = 900,
  double height = 900,
}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  return tester.pumpWidget(
    MacosTheme(
      data: MacosThemeData.light(),
      child: CupertinoApp(
        home: CupertinoPageScaffold(
          child: SizedBox(
            width: width,
            height: height,
            child: NarrativeOverviewWorkspace(readModel: readModel),
          ),
        ),
      ),
    ),
  );
}

ProjectManifest _minimalProject(
  String name, {
  List<ScenarioAsset> scenarios = const <ScenarioAsset>[],
  List<ProjectDialogueEntry> dialogues = const <ProjectDialogueEntry>[],
}) {
  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: name,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    scenarios: scenarios,
    dialogues: dialogues,
  );
}

ScenarioAsset _globalStoryWithDocuments({
  String name = 'Test Main Story',
  String description = 'A generic authoring synopsis.',
}) {
  const stepDocument = StepStudioDocument(
    globalStoryScenarioId: 'test_global_story',
    steps: <StepStudioStep>[
      StepStudioStep(
        id: 'test_step_1',
        name: 'Step One',
        description: 'First test step.',
        order: 0,
        activation: StepStudioActivationRule(
          mode: StepStudioActivationMode.atGameStart,
        ),
        completion: StepStudioCompletionRule(
          mode: StepStudioCompletionMode.whenCutsceneEnds,
          cutsceneId: 'test_cutscene_1',
        ),
        cutscenes: <StepStudioCutsceneLink>[
          StepStudioCutsceneLink(
            cutsceneId: 'test_cutscene_1',
            role: StepStudioCutsceneRole.main,
          ),
        ],
      ),
      StepStudioStep(
        id: 'test_step_2',
        name: 'Step Two',
        description: 'Second test step.',
        order: 1,
        activation: StepStudioActivationRule(
          mode: StepStudioActivationMode.afterStep,
          stepId: 'test_step_1',
        ),
        completion: StepStudioCompletionRule(
          mode: StepStudioCompletionMode.manual,
        ),
      ),
    ],
  );

  const globalStoryDocument = GlobalStoryStudioDocument(
    globalStoryScenarioId: 'test_global_story',
    entryStepId: 'test_step_1',
    nodes: <GlobalStoryStepNode>[
      GlobalStoryStepNode(
        stepId: 'test_step_1',
        links: <GlobalStoryStepLink>[
          GlobalStoryStepLink(toStepId: 'test_step_2'),
        ],
      ),
      GlobalStoryStepNode(stepId: 'test_step_2'),
    ],
    chapters: <GlobalStoryChapter>[
      GlobalStoryChapter(
        id: 'test_chapter_1',
        name: 'Test Chapter One',
        description: 'First test chapter.',
        stepIds: <String>['test_step_1'],
        order: 0,
      ),
      GlobalStoryChapter(
        id: 'test_chapter_2',
        name: 'Test Chapter Two',
        description: 'Second test chapter.',
        stepIds: <String>['test_step_2'],
        order: 1,
      ),
    ],
  );

  return ScenarioAsset(
    id: 'test_global_story',
    name: name,
    description: description,
    scope: ScenarioScope.globalStory,
    entryNodeId: 'start',
    metadata: <String, String>{
      kStepStudioSchemaMetadataKey: kStepStudioSchemaVersion,
      kStepStudioDocumentMetadataKey: stepDocument.toMetadataJson(),
      kGlobalStoryStudioSchemaMetadataKey: kGlobalStoryStudioSchemaVersion,
      kGlobalStoryStudioDocumentMetadataKey:
          globalStoryDocument.toMetadataJson(),
    },
  );
}

ScenarioAsset _cutsceneScenario({
  required String id,
  String? dialogueId,
}) {
  return ScenarioAsset(
    id: id,
    name: 'Test Cutscene',
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'start',
    metadata: const <String, String>{
      kCutsceneStudioSchemaMetadataKey: kCutsceneStudioSchemaVersion,
    },
    nodes: <ScenarioNode>[
      if (dialogueId != null)
        ScenarioNode(
          id: 'open_dialogue',
          payload: const ScenarioNodePayload(actionKind: 'openDialogue'),
          binding: ScenarioNodeBinding(dialogueId: dialogueId),
        ),
    ],
  );
}
