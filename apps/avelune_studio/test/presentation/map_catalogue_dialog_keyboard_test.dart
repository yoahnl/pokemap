import 'dart:async';
import 'package:avelune_studio/presentation/features/map_workspace/map_catalogue_form_dialog.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_draft_field.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('focused input survives refusal and Enter cannot double submit', (
    tester,
  ) async {
    final pending = Completer<String?>();
    var name = 'Titre', submits = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showMapCatalogueForm(
                context,
                title: 'Renommer',
                submitLabel: 'Enregistrer',
                valid: () => name.trim().isNotEmpty,
                fields: (refresh, busy) => StudioDraftField(
                  value: name,
                  label: 'Nom',
                  enabled: !busy,
                  onChanged: (value) {
                    name = value;
                    refresh();
                  },
                ),
                submit: () {
                  submits++;
                  return pending.future;
                },
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Écluse du moulin');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(submits, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('Renommer'), findsOneWidget);
    pending.complete('Révision modifiée.');
    await tester.pumpAndSettle();
    expect(find.text('Révision modifiée.'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(name, 'Écluse du moulin');
    await tester.tap(find.byType(TextField));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Renommer'), findsNothing);
  });
}
