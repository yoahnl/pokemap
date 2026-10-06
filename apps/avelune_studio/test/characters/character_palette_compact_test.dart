import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_panels.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_workspace_fixture.dart';
import 'character_editing_test.dart' show guide;

void main() {
  testWidgets(
    'compact character catalogue keeps cards reachable while searching',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final document = EditableMapDocument(
        MapWorkspaceDocument(
          map: workspaceMap('a'),
          revision: 'base',
          mapId: 'a',
        ),
      );
      final project = workspaceProject.copyWith(
        characters: [
          guide,
          guide.copyWith(id: 'traveler', name: 'Voyageuse'),
        ],
      );
      final view = MapWorkspaceViewState()..paletteTab = 'Personnages';
      final search = TextEditingController();
      addTearDown(view.dispose);
      addTearDown(search.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 900,
                height: 88,
                child: StatefulBuilder(
                  builder: (context, update) => MapWorkspacePalette(
                    project: project,
                    document: document,
                    visuals: WorkspaceTestVisuals(),
                    view: view,
                    search: search,
                    compactContent: true,
                    onChanged: () => update(() {}),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('character-guide')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('character-traveler')).hitTestable(),
        findsOneWidget,
      );
      expect(
        tester.widget<GridView>(find.byType(GridView)).scrollDirection,
        Axis.horizontal,
      );
      expect(find.byKey(const ValueKey('character-search')), findsNothing);
      await tester.tap(find.byTooltip('Rechercher un personnage'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('character-search')),
        'Voyageuse',
      );
      await tester.pump();
      expect(view.characterQuery, 'Voyageuse');
      expect(find.byKey(const ValueKey('character-guide')), findsNothing);
      expect(
        find.byKey(const ValueKey('character-traveler')).hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('character-traveler')));
      await tester.pump();
      expect(view.character?.id, 'traveler');
      expect(view.tool, StudioMapTool.character);
      expect(document.dirty, isFalse);
      await tester.tap(find.byTooltip('Masquer la recherche des personnages'));
      await tester.pumpAndSettle();
      expect(view.characterQuery, isEmpty);
      expect(
        find.byKey(const ValueKey('character-guide')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
