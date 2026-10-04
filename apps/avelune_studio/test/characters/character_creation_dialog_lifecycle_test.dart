import 'package:avelune_studio/presentation/features/characters/character_studio_create_dialog.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  const project = ProjectManifest(
    name: 'Création de personnage',
    maps: [],
    tilesets: [
      ProjectTilesetEntry(
        id: 'voyageur',
        name: 'Voyageur',
        relativePath: 'voyageur.png',
        source: ProjectRegularAtlasTilesetSource(
          assetId: 'voyageur',
          pixelWidth: 256,
          pixelHeight: 256,
          tileWidth: 32,
          tileHeight: 32,
        ),
      ),
    ],
  );

  for (final action in ['Créer', 'Annuler', 'Barrière']) {
    testWidgets('focused creation dialog closes safely through $action', (
      tester,
    ) async {
      (String, String)? result;
      var completed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, refresh) => TextButton(
                onPressed: () async {
                  result = await showCharacterStudioCreateDialog(
                    context,
                    project,
                  );
                  refresh(() => completed = true);
                },
                child: Text(completed ? 'Terminé' : 'Ouvrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Nom'), ' Éloïse ');
      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode?.hasFocus ??
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
      expect(completed, isTrue);
      expect(find.byType(TextField), findsOneWidget);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Terminé'), findsOneWidget);
      expect(result, action == 'Créer' ? ('Éloïse', 'voyageur') : isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
