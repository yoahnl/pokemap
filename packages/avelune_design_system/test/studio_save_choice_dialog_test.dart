import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<Future<StudioSaveChoice>> ask(WidgetTester tester) async {
    late Future<StudioSaveChoice> choice;
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => choice = showStudioSaveChoiceDialog(
                context,
                title: 'Enregistrer les modifications ?',
                message: 'Le projet contient des modifications.',
                saveLabel: 'Enregistrer',
                discardLabel: 'Ne pas enregistrer',
                cancelLabel: 'Annuler',
              ),
              child: const Text('quitter'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('quitter'));
    await tester.pumpAndSettle();
    return choice;
  }

  for (final (key, expected) in [
    ('studio-save-choice-save', StudioSaveChoice.save),
    ('studio-save-choice-discard', StudioSaveChoice.discard),
    ('studio-save-choice-cancel', StudioSaveChoice.cancel),
  ]) {
    testWidgets('the save choice dialog answers $expected', (tester) async {
      final choice = await ask(tester);
      expect(find.text('Enregistrer les modifications ?'), findsOneWidget);
      expect(
        find.text('Le projet contient des modifications.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();

      expect(await choice, expected);
      expect(find.byKey(const ValueKey('studio-save-choice')), findsNothing);
    });
  }

  testWidgets('dismissing the save choice dialog cancels', (tester) async {
    final choice = await ask(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(await choice, StudioSaveChoice.cancel);

    final again = await ask(tester);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(await again, StudioSaveChoice.cancel);
  });

  testWidgets('the save choice dialog follows the theme tokens', (
    tester,
  ) async {
    await ask(tester);
    final scheme = Theme.of(
      tester.element(find.byKey(const ValueKey('studio-save-choice'))),
    ).colorScheme;
    final discard = tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byKey(const ValueKey('studio-save-choice-discard')),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(discard.style?.foregroundColor?.resolve(const {}), scheme.error);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('studio-save-choice-save')),
        matching: find.byType(FilledButton),
      ),
      findsOneWidget,
    );
  });
}
