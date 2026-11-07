import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the theme reads its type scale from the tokens', () {
    final text = studioTheme().textTheme;
    expect(text.bodyMedium?.fontSize, StudioTypeScale.body);
    expect(text.bodySmall?.fontSize, StudioTypeScale.caption);
    expect(text.labelLarge?.fontSize, StudioTypeScale.label);
    expect(text.titleMedium?.fontSize, StudioTypeScale.title);
    expect(text.titleLarge?.fontSize, StudioTypeScale.heading);
    expect(
      StudioSpacing.values,
      orderedEquals([...StudioSpacing.values]..sort()),
    );
    expect(StudioDensity.denseRow, lessThan(StudioDensity.row));
  });

  testWidgets('state badges carry a word and an icon, not colour alone', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: const Scaffold(
          body: Column(
            children: [
              StudioStateBadge.inherited('du projet'),
              StudioStateBadge.local(),
              StudioStateBadge.draft(),
              StudioStateBadge.mixed(),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Hérité du projet'), findsOneWidget);
    expect(find.text('Valeur locale'), findsOneWidget);
    expect(find.text('Non enregistré'), findsOneWidget);
    expect(find.text('Valeurs différentes'), findsOneWidget);
    expect(find.byType(Icon), findsNWidgets(4));
  });
}
