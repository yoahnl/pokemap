import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/editor_canvas_host.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';

void main() {
  const sampleProject = ProjectManifest(
    name: 'pokedex_ui_test',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
  );

  testWidgets('ProjectExplorerPanel shows a Pokédex entry tile',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Le lot 12 ne doit dependre d'aucune lecture Pokemon reelle.
    // On injecte donc un manifest projet minimal en memoire, sans species,
    // sans learnsets et sans aucun service Pokemon branche.
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const CupertinoApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 420,
                height: 980,
                child: ProjectExplorerPanel(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pokedex-explorer-entry')), findsOneWidget);
    expect(find.text('Pokédex'), findsWidgets);
    expect(find.textContaining('placeholder only'), findsOneWidget);
  });

  testWidgets('tapping the Pokédex entry opens the placeholder workspace', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);

    // Etat minimal volontaire:
    // si ce test passe avec un projet quasiment vide, cela prouve que
    // l'ouverture du placeholder Pokédex ne depend pas d'un chargement reel
    // de donnees Pokemon.
    notifier.state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.map,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const CupertinoApp(
            home: CupertinoPageScaffold(
              child: Row(
                children: [
                  SizedBox(
                    width: 420,
                    height: 980,
                    child: ProjectExplorerPanel(),
                  ),
                  Expanded(
                    child: SizedBox(
                      width: 980,
                      height: 980,
                      child: EditorCanvasHost(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pokedex-explorer-entry')));
    await tester.pumpAndSettle();

    expect(notifier.state.workspaceMode, EditorWorkspaceMode.pokedex);
    expect(
        find.byKey(const Key('pokedex-placeholder-workspace')), findsOneWidget);
    expect(
      find.text(
        'Cette section deviendra plus tard le point d’entrée du contenu Pokémon du projet.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
          'le vrai contenu détaillé arrivera dans les prochains lots'),
      findsOneWidget,
    );
  });
}
