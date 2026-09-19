import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/characters/character_inspector.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_panels.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import '../support/map_workspace_fixture.dart';
import 'character_editing_test.dart' show guide;

void main() {
  testWidgets(
    'palette and inspector support real instance edits at enlarged text',
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
      Widget app(Widget child) => MaterialApp(
        theme: studioTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(body: SizedBox(width: 300, child: child)),
      );
      await tester.pumpWidget(
        app(
          StatefulBuilder(
            builder: (context, setState) => MapWorkspacePalette(
              project: project,
              document: document,
              visuals: WorkspaceTestVisuals(),
              view: view,
              search: search,
              onChanged: () => setState(() {}),
            ),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('character-search')),
        'Voyageuse',
      );
      await tester.pump();
      expect(find.text('Chef de gare'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('character-traveler')));
      await tester.pump();
      expect(view.character!.id, 'traveler');
      expect(view.characterQuery, 'Voyageuse');
      expect(view.tool, StudioMapTool.character);
      expect(document.dirty, isFalse);
      final commands = CharacterEditingCommands(document, project);
      var selected = commands
          .place(view.character!, const GridPos(x: 3, y: 4))
          .id;
      MapEntity? edited;
      await tester.pumpWidget(
        app(
          StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: CharacterInspector(
                document: document,
                project: project,
                entity: commands.selected(selected)!,
                visuals: WorkspaceTestVisuals(),
                onChanged: () => setState(() {}),
                onSelect: (id) => setState(() => selected = id!),
                onEditInteraction: (entity) => edited = entity,
              ),
            ),
          ),
        ),
      );
      final before = document.undoCount;
      await tester.enterText(
        find.byKey(const ValueKey('character-name')),
        'Voyageuse du quai',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(
        commands.selected(selected)!.npc!.displayName,
        'Voyageuse du quai',
      );
      expect(document.undoCount, before + 1);
      await tester.ensureVisible(find.text('Bloque le passage'));
      await tester.tap(find.text('Bloque le passage'));
      await tester.pump();
      expect(commands.selected(selected)!.blocksMovement, isFalse);
      await tester.ensureVisible(find.text('Écrire son interaction'));
      await tester.tap(find.text('Écrire son interaction'));
      expect(edited!.id, selected);
      await tester.ensureVisible(find.byTooltip('Dupliquer le personnage'));
      await tester.tap(find.byTooltip('Dupliquer le personnage'));
      await tester.pump();
      expect(document.current.entities, hasLength(2));
      expect(tester.takeException(), isNull);
    },
  );
}
