import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/characters/character_studio_controller.dart';
import 'package:avelune_studio/presentation/features/characters/character_studio_portrait_panel.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  const character = ProjectCharacterEntry(
    id: 'voyageuse',
    name: 'Voyageuse',
    tilesetId: 'voyageuse',
    frameWidth: 1,
    frameHeight: 1,
  );
  const project = ProjectManifest(
    name: 'Expressions',
    maps: [],
    tilesets: [],
    characters: [character],
  );

  for (final action in ['Créer l’état', 'Annuler', 'Barrière']) {
    testWidgets('focused portrait state dialog closes safely through $action', (
      tester,
    ) async {
      var calls = 0;
      String? operation;
      Map<String, Object?>? parameters;
      final controller = CharacterStudioController(
        project: () => project,
        mutate: (actionId, values) async {
          calls++;
          operation = actionId;
          parameters = values;
          return project;
        },
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => CharacterStudioPortraitPanel(
                project: project,
                character: character,
                controller: controller,
                port: _UnusedResourcePort(),
                onImport: (_) => fail('No portrait import was requested'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ajouter un état'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Nom de l’état'),
        ' Neutre accentué ',
      );
      expect(
        tester
            .state<EditableTextState>(find.byType(EditableText))
            .widget
            .focusNode
            .hasFocus,
        isTrue,
      );
      if (action == 'Barrière') {
        await tester.tapAt(const Offset(5, 5));
      } else {
        await tester.tap(find.text(action));
      }
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Ajouter un état'), findsOneWidget);
      expect(controller.error, isNull);
      expect(controller.saving, isFalse);
      if (action == 'Créer l’état') {
        expect(calls, 1);
        expect(operation, 'characterStudio.portraitState.create');
        expect(parameters, {'displayName': 'Neutre accentué'});
      } else {
        expect(calls, 0);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}

class _UnusedResourcePort implements ResourcePort {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected resource access: ${invocation.memberName}');
}
