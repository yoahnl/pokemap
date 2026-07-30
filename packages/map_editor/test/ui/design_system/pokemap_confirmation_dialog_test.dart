import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('returns the typed action selected by the user', (tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Builder(
          builder: (context) => PokeMapButton(
            onPressed: () async {
              result = await showPokeMapConfirmationDialog<String>(
                context: context,
                title: 'Modifications en attente',
                message: 'Enregistrer avant de continuer ?',
                actions: const [
                  PokeMapDialogAction(label: 'Annuler', value: 'cancel'),
                  PokeMapDialogAction(
                    label: 'Ignorer',
                    value: 'discard',
                    variant: PokeMapButtonVariant.danger,
                  ),
                  PokeMapDialogAction(
                    label: 'Enregistrer',
                    value: 'save',
                    variant: PokeMapButtonVariant.success,
                  ),
                ],
              );
            },
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    expect(find.byKey(pokeMapConfirmationDialogKey), findsOneWidget);
    expect(find.text('Modifications en attente'), findsOneWidget);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(result, 'save');
    expect(find.byKey(pokeMapConfirmationDialogKey), findsNothing);
  });

  testWidgets('renders optional details in a dedicated scrollable slot',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Builder(
          builder: (context) => PokeMapButton(
            onPressed: () => showPokeMapConfirmationDialog<bool>(
              context: context,
              title: 'Supprimer le calque',
              message: 'Cette action est définitive.',
              details: Column(
                children: [
                  for (var index = 0; index < 30; index += 1)
                    Text('Détail $index'),
                ],
              ),
              actions: const [
                PokeMapDialogAction(label: 'Annuler', value: false),
                PokeMapDialogAction(label: 'Supprimer', value: true),
              ],
            ),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Détail 0'), findsOneWidget);
    expect(
      find.byKey(pokeMapConfirmationDialogDetailsScrollKey),
      findsOneWidget,
    );
  });

  testWidgets('keeps actions reachable with long details at small height',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(560, 260));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Builder(
          builder: (context) => PokeMapButton(
            onPressed: () async {
              result = await showPokeMapConfirmationDialog<bool>(
                context: context,
                title: 'Supprimer',
                message: 'Conséquences',
                details: Column(
                  children: [
                    for (var index = 0; index < 50; index += 1)
                      Text('Relation $index'),
                  ],
                ),
                actions: const [
                  PokeMapDialogAction(label: 'Annuler', value: false),
                  PokeMapDialogAction(label: 'Supprimer', value: true),
                ],
              );
            },
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Supprimer'), findsWidgets);
    await tester.tap(find.widgetWithText(PokeMapButton, 'Supprimer'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('Escape dismisses a confirmation with details', (tester) async {
    bool? result = true;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Builder(
          builder: (context) => PokeMapButton(
            onPressed: () async {
              result = await showPokeMapConfirmationDialog<bool>(
                context: context,
                title: 'Supprimer',
                message: 'Conséquences',
                details: const Text('Détail'),
                actions: const [
                  PokeMapDialogAction(label: 'Annuler', value: false),
                ],
              );
            },
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byKey(pokeMapConfirmationDialogKey), findsNothing);
    expect(result, isNull);
  });
}
