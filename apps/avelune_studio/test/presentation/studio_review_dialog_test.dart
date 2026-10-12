import 'package:avelune_studio/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('review dialog exposes three distinct exit decisions', (
    tester,
  ) async {
    final decisions = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: StudioReviewDialog(
            title: 'Conserver la revue ?',
            content: const Text('Les corrections ne sont pas enregistrées.'),
            cancelLabel: 'Rester',
            onCancelled: () => decisions.add('stay'),
            secondaryActionLabel: 'Abandonner les changements',
            onSecondaryAction: () => decisions.add('discard'),
            confirmLabel: 'Enregistrer et fermer',
            onConfirmed: () => decisions.add('save'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Rester'));
    await tester.tap(find.text('Abandonner les changements'));
    await tester.tap(find.text('Enregistrer et fermer'));
    expect(decisions, ['stay', 'discard', 'save']);
    expect(tester.takeException(), isNull);
  });
}
