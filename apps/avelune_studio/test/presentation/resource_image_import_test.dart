import 'dart:typed_data';

import 'package:avelune_studio/presentation/features/resources/resource_image_import.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'unreadable PNG preview reports a recoverable error and cancels',
    (tester) async {
      var completed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  final result = await confirmImageImport(
                    context,
                    PickedResourceImage(
                      '/unused.png',
                      'Image',
                      Uint8List(24),
                      16,
                      24,
                    ),
                    16,
                    24,
                  );
                  expect(result, isNull);
                  completed = true;
                },
                child: const Text('Préparer'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Préparer'));
      await tester.pumpAndSettle();
      expect(
        find.text('Cette image PNG ne peut pas être prévisualisée.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Annuler'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(completed, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
