import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';

void main() {
  testWidgets('ProjectExplorerPanel shows a Catalogues Pokémon entry tile',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokemon_catalogs_project_explorer',
      project: ProjectManifest(
        name: 'catalogs_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      ),
    );

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 980);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 360,
                height: 900,
                child: ProjectExplorerPanel(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Catalogues Pokémon'), findsOneWidget);
    expect(
      find.text('Pokédex, Moves et Items dans un espace guidé unique'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('pokedex-explorer-entry')), findsOneWidget);
    expect(find.text('Pokédex'), findsWidgets);
  });
}
