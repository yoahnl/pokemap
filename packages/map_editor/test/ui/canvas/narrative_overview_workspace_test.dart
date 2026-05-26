import 'package:flutter/cupertino.dart';
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
        ),
        findsOneWidget,
      );
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

      expect(find.textContaining('Dialogues : 0'), findsOneWidget);
      expect(find.textContaining('Chapitres : 0'), findsOneWidget);
      expect(find.textContaining('Quêtes : hors scope V0'), findsOneWidget);
      expect(
          find.textContaining('Facts : nécessite un modèle'), findsOneWidget);
      expect(
        find.textContaining('Activité récente : hors scope V0'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Notifications : hors scope V0'),
        findsOneWidget,
      );

      expect(find.textContaining('Selbrume'), findsNothing);
      expect(find.textContaining('La brume du phare'), findsNothing);
      expect(find.text('42'), findsNothing);
      expect(find.text('1 236'), findsNothing);
      expect(find.text('1236'), findsNothing);
    },
  );
}

ProjectManifest _minimalProject(String name) {
  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: name,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
  );
}
