import 'dart:async';

import 'package:avelune_studio/presentation/features/map_builder/map_builder_name_field.dart';
import 'package:avelune_studio/presentation/shared/widgets/editor_text_transactions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'saving waits for a submission that started when the field lost focus',
    (tester) async {
      final gate = Completer<bool>();
      final transactions = EditorTextTransactions();
      var current = 'Avant';
      String? saved;
      var submissions = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorTextTransactionsScope(
              transactions: transactions,
              child: Column(
                children: [
                  MapBuilderNameField(
                    value: current,
                    label: 'Nom',
                    enabled: true,
                    onSubmit: (name) async {
                      submissions++;
                      if (!await gate.future) return false;
                      current = name;
                      return true;
                    },
                  ),
                  TextButton(
                    onPressed: () async {
                      await MapBuilderNameField.commitFocused();
                      await transactions.finish();
                      saved = current;
                    },
                    child: const Text('Enregistrer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Après');
      await tester.tap(find.text('Enregistrer'));
      await tester.pump();
      expect(saved, isNull);
      expect(submissions, 1);
      gate.complete(true);
      await tester.pumpAndSettle();
      expect(saved, 'Après');
      expect(transactions.pending, isFalse);
    },
  );

  test(
    'a failed pending transaction is observable and releases the wait',
    () async {
      final transactions = EditorTextTransactions();
      final gate = Completer<void>();
      final submitted = transactions.track(gate.future);
      final save = transactions.finish();
      final failure = StateError('Échec de saisie');
      final submittedCheck = expectLater(submitted, throwsA(same(failure)));
      final saveCheck = expectLater(save, throwsA(same(failure)));
      gate.completeError(failure);
      await Future.wait([submittedCheck, saveCheck]);
      expect(transactions.pending, isFalse);
      await transactions.finish();
    },
  );
}
