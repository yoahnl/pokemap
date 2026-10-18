import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/entity_presentation_controls.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_choice.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_commit_field.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  testWidgets(
    'Studio edits variants through canonical action with validation and undo',
    (tester) async {
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 6, height: 6),
        entities: const [
          MapEntity(
            id: 'owner',
            kind: MapEntityKind.custom,
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      );
      const project = ProjectManifest(name: 'Test', maps: [], tilesets: []);
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, revision: 'base', mapId: 'map'),
      );
      final commands = MapEntityEditingCommands(document, project);
      late StateSetter redraw;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                redraw = setState;
                return SingleChildScrollView(
                  child: EntityPresentationControls(
                    entity: document.current.entities.single,
                    project: project,
                    mapId: 'map',
                    mapSize: map.size,
                    onChanged: (value) => setState(
                      () => commands.setPresentation('owner', value),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ajouter une variante'));
      await tester.pumpAndSettle();
      expect(
        document.current.entities.single.presentation!.variants,
        hasLength(1),
      );
      final blocking = find.byWidgetPredicate(
        (widget) =>
            widget is StudioChoice &&
            widget.label == 'La variante bloque le passage',
      );
      await tester.ensureVisible(blocking);
      await tester.tap(blocking);
      await tester.pumpAndSettle();
      expect(
        document
            .current
            .entities
            .single
            .presentation!
            .variants
            .single
            .blocksMovement,
        isFalse,
      );
      final size = find.byWidgetPredicate(
        (widget) =>
            widget is StudioCommitField && widget.label == 'Largeur en cases',
      );
      await tester.ensureVisible(size);
      final input = find.descendant(of: size, matching: find.byType(TextField));
      await tester.enterText(input, 'n’importe quoi');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(
        document
            .current
            .entities
            .single
            .presentation!
            .variants
            .single
            .size
            .width,
        1,
      );
      expect(
        find.text(
          'Choisissez une taille de 1 à 64 cases qui reste dans la carte.',
        ),
        findsOneWidget,
      );
      await tester.enterText(input, '2');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(
        document
            .current
            .entities
            .single
            .presentation!
            .variants
            .single
            .size
            .width,
        2,
      );
      expect(tester.takeException(), isNull);
      document.restore(redo: false);
      redraw(() {});
      await tester.pumpAndSettle();
      expect(
        document
            .current
            .entities
            .single
            .presentation!
            .variants
            .single
            .size
            .width,
        1,
      );
    },
  );
}
