import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('panel and inspector headings retain their text hierarchy', (
    tester,
  ) async {
    final theme = studioTheme();
    const titleKey = ValueKey('inspector-title');
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: Column(
            children: [
              StudioPanelHeading(
                eyebrow: 'CONSTRUCTION',
                title: 'Espace',
                description: 'Gérer la carte.',
              ),
              StudioPanelHeading.inspector(
                eyebrow: 'SÉLECTION',
                title: 'Maison',
                titleKey: titleKey,
                description: 'Décor placé',
                descriptionGap: StudioSpacing.s,
              ),
              StudioEyebrow('DESCRIPTION TRÈS LONGUE', singleLine: true),
            ],
          ),
        ),
      ),
    );

    final panel = tester.widget<Text>(find.text('Espace'));
    final inspector = tester.widget<Text>(find.byKey(titleKey));
    final description = tester.widget<Text>(find.text('Décor placé'));
    expect(panel.style?.fontSize, theme.textTheme.titleMedium?.fontSize);
    expect(inspector.style?.fontSize, theme.textTheme.titleSmall?.fontSize);
    expect(panel.style?.fontWeight, FontWeight.w700);
    expect(description.style?.color, theme.colorScheme.onSurfaceVariant);
    expect(
      tester.getTopLeft(find.text('Espace')).dy -
          tester.getBottomLeft(find.text('CONSTRUCTION')).dy,
      StudioSpacing.xs,
    );
    expect(
      tester.getTopLeft(find.byKey(titleKey)).dy -
          tester.getBottomLeft(find.text('SÉLECTION')).dy,
      StudioSpacing.m,
    );
    expect(
      tester.getTopLeft(find.text('Décor placé')).dy -
          tester.getBottomLeft(find.byKey(titleKey)).dy,
      StudioSpacing.s,
    );
    final eyebrow = tester.widget<Text>(find.text('DESCRIPTION TRÈS LONGUE'));
    expect(eyebrow.maxLines, 1);
    expect(eyebrow.overflow, TextOverflow.ellipsis);
    expect(eyebrow.style?.letterSpacing, 1);
    expect(tester.widget<Text>(find.text('CONSTRUCTION')).maxLines, isNull);
  });

  testWidgets('compact progress keeps its size and accessible label', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: const Scaffold(
          body: Center(
            child: StudioProgressIndicator.compact(label: 'Aperçu en cours'),
          ),
        ),
      ),
    );

    final progress = find.byType(CircularProgressIndicator);
    expect(tester.getSize(progress), const Size.square(16));
    expect(tester.widget<CircularProgressIndicator>(progress).strokeWidth, 2);
    expect(find.bySemanticsLabel('Aperçu en cours'), findsOneWidget);
  });

  testWidgets('inline search keeps the query local and supports disabled use', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final queries = <String>[];
    const enabledKey = ValueKey('enabled-search');
    const disabledKey = ValueKey('disabled-search');
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: Column(
            children: [
              StudioInlineSearchField(
                key: enabledKey,
                hint: 'Rechercher un élément',
                controller: controller,
                onChanged: queries.add,
              ),
              const StudioInlineSearchField(
                key: disabledKey,
                hint: 'Recherche indisponible',
              ),
            ],
          ),
        ),
      ),
    );

    await tester.enterText(find.byKey(enabledKey), 'route');
    expect(queries, ['route']);
    expect(controller.text, 'route');
    final disabled = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(disabledKey),
        matching: find.byType(TextField),
      ),
    );
    expect(disabled.enabled, isFalse);
    expect(disabled.decoration?.isDense, isTrue);
    expect(find.byTooltip('Effacer la recherche'), findsNothing);
  });
}
