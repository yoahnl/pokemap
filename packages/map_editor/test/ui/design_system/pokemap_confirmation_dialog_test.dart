import 'package:flutter/material.dart';
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
}
