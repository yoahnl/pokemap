import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/ui/shared/inspector_embedded_widgets.dart';

void main() {
  testWidgets(
    'allowUnsetSelection: valeur hors liste affiche le placeholder sans crash',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InspectorEmbeddedDropdown(
              accent: Colors.cyan,
              fieldLabel: 'Entité',
              valueLabel: 'Choisir une entité (PNJ)',
              orderedIds: const <String>['emma', 'rival'],
              selectedMenuValue: '',
              selectedIdForCheck: null,
              allowUnsetSelection: true,
              idToLabel: (id) => id,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Choisir une entité (PNJ)'), findsOneWidget);
      await tester.tap(find.text('Choisir une entité (PNJ)'));
      await tester.pumpAndSettle();

      expect(find.text('emma'), findsWidgets);
    },
  );

  testWidgets(
    'allowUnsetSelection: choisir une ligne émet bien l’id (flux worldChanges PNJ)',
    (tester) async {
      String? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InspectorEmbeddedDropdown(
              accent: Colors.cyan,
              fieldLabel: 'Entité',
              valueLabel: 'Choisir une entité (PNJ)',
              orderedIds: const <String>['emma', 'rival'],
              selectedMenuValue: '',
              selectedIdForCheck: null,
              allowUnsetSelection: true,
              idToLabel: (id) => id,
              onSelected: (id) => picked = id,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Choisir une entité (PNJ)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('emma').last);
      await tester.pumpAndSettle();

      expect(picked, 'emma');
    },
  );
}
