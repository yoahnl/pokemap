import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/application/overview/narrative_overview_read_model.dart';
import 'package:map_editor/src/ui/canvas/narrative_overview_workspace.dart';

void main() {
  testWidgets(
    'NarrativeOverviewWorkspace renders a minimal authoring overview from the read model',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject('test_project'),
      );

      await tester.pumpWidget(
        MacosTheme(
          data: MacosThemeData.light(),
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 900,
                height: 640,
                child: NarrativeOverviewWorkspace(readModel: readModel),
              ),
            ),
          ),
        ),
      );

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
        expect(find.text(label), findsOneWidget);
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

      await tester.pumpWidget(
        MacosTheme(
          data: MacosThemeData.light(),
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 900,
                height: 640,
                child: NarrativeOverviewWorkspace(readModel: readModel),
              ),
            ),
          ),
        ),
      );

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

      await tester.pumpWidget(
        MacosTheme(
          data: MacosThemeData.light(),
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 960,
                height: 640,
                child: NarrativeOverviewWorkspace(readModel: readModel),
              ),
            ),
          ),
        ),
      );

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

      await tester.pumpWidget(
        MacosTheme(
          data: MacosThemeData.light(),
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 620,
                height: 720,
                child: NarrativeOverviewWorkspace(readModel: readModel),
              ),
            ),
          ),
        ),
      );

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

ProjectManifest _minimalProject(
  String name, {
  List<ProjectDialogueEntry> dialogues = const <ProjectDialogueEntry>[],
}) {
  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: name,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    dialogues: dialogues,
  );
}
