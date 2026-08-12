import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('PokeMapDisclosure exposes its content on pointer and keyboard', (
    tester,
  ) async {
    var expanded = false;
    late StateSetter setHostState;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              return PokeMapDisclosure(
                key: const ValueKey<String>('disclosure'),
                label: 'Options avancées',
                expanded: expanded,
                onExpandedChanged: (value) {
                  setHostState(() => expanded = value);
                },
                child: const Text('Contenu secondaire'),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Contenu secondaire'), findsNothing);
    await tester.tap(find.text('Options avancées'));
    await tester.pumpAndSettle();
    expect(find.text('Contenu secondaire'), findsOneWidget);

    await tester.tap(find.text('Options avancées'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Contenu secondaire'), findsOneWidget);
  });
}
