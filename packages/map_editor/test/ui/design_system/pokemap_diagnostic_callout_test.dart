import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets(
      'diagnostic callout exposes text, icon and consolidated semantics',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: const Scaffold(
          body: PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.error,
            title: 'Élément introuvable',
            message: 'Choisissez un autre élément déclencheur.',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.text('Élément introuvable'), findsOneWidget);
    expect(
      find.text('Choisissez un autre élément déclencheur.'),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                'Erreur. Élément introuvable. '
                    'Choisissez un autre élément déclencheur.' &&
            widget.properties.liveRegion == true,
      ),
      findsOneWidget,
    );

    final surface = tester.widget<Container>(
      find.descendant(
        of: find.byType(PokeMapDiagnosticCallout),
        matching: find.byType(Container),
      ),
    );
    final decoration = surface.decoration! as BoxDecoration;
    expect(decoration.color, PokeMapColorTokens.dark.errorSoft);
    expect(tester.takeException(), isNull);
  });

  testWidgets('diagnostic action remains an accessible real button',
      (tester) async {
    var actionCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.warning,
            title: 'Conflit possible',
            message: 'Vérifiez la priorité des événements.',
            actionLabel: 'Gérer l’ordre',
            onAction: () => actionCount += 1,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.text('Gérer l’ordre'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.button == true &&
            widget.properties.enabled == true,
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Gérer l’ordre'));
    await tester.pump();

    expect(actionCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('information diagnostic uses the information icon',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: const Scaffold(
          body: PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.info,
            message: 'La position se modifie depuis la carte.',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                'Information. La position se modifie depuis la carte.',
      ),
      findsOneWidget,
    );
  });
}
