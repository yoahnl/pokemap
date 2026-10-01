import 'package:avelune_studio/presentation/features/map_workspace/map_catalogue_creation_dialog.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  for (final size in [
    const Size(1536, 1024),
    const Size(1280, 800),
    const Size(1024, 640),
  ]) {
    testWidgets(
      'creation form remains accessible at $size with enlarged text',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(1.5),
              ),
              child: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    child: const Text('Ouvrir'),
                    onPressed: () => showNewMapDialog(
                      context,
                      project: const ProjectManifest(
                        name: 'Projet 48',
                        maps: [],
                        tilesets: [],
                        settings: ProjectSettings(
                          tileWidth: 48,
                          tileHeight: 48,
                          defaultMapWidth: 37,
                          defaultMapHeight: 21,
                        ),
                      ),
                      onCreate:
                          ({
                            required name,
                            required width,
                            required height,
                            required role,
                            groupId,
                            tilesetId,
                          }) async => null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Ouvrir'));
        await tester.pumpAndSettle();
        expect(
          find.text('Cases : 48 × 48 px · grille du projet'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(TextField, 'Largeur (cases)'),
          findsOneWidget,
        );
        expect(find.text('37'), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('new-map-name')),
          'Écluse des essais',
        );
        await tester.pump();
        await tester.ensureVisible(find.text('Créer la carte'));
        await tester.tap(find.text('Créer la carte'));
        await tester.pumpAndSettle();
        expect(find.text('Nouvelle carte'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
