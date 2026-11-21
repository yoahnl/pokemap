import 'dart:typed_data';
import 'dart:ui' as ui;

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

    final progress = find.byType(StudioProgressIndicator);
    expect(tester.getSize(progress), const Size.square(16));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.bySemanticsLabel('Aperçu en cours'), findsOneWidget);
  });

  testWidgets('the progress logo stays static with reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: StudioProgressIndicator()),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(StudioProgressIndicator)),
      const Size.square(36),
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('the rotating logo draws the crescent, wave and star in stages', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: const Scaffold(body: Center(child: StudioProgressIndicator())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final first = await _paintedProgress(tester);
    expect(first.blue, greaterThan(10));
    expect(first.purple, 0);
    expect(first.cyan, 0);

    await tester.pump(const Duration(milliseconds: 980));
    final middle = await _paintedProgress(tester);
    expect(middle.blue, greaterThan(first.blue));
    expect(middle.purple, greaterThan(100));
    expect(middle.cyan, 0);

    await tester.pump(const Duration(milliseconds: 680));
    final complete = await _paintedProgress(tester);
    expect(complete.purple, greaterThan(100));
    expect(complete.cyan, greaterThan(50));
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

Future<({int blue, int purple, int cyan})> _paintedProgress(
  WidgetTester tester,
) async {
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(StudioProgressIndicator),
      matching: find.byType(CustomPaint),
    ),
  );
  final pixels = (await tester.runAsync<ByteData>(() async {
    final recorder = ui.PictureRecorder();
    paint.painter!.paint(ui.Canvas(recorder), const Size.square(144));
    final picture = recorder.endRecording();
    final image = await picture.toImage(144, 144);
    try {
      return (await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      ))!;
    } finally {
      image.dispose();
      picture.dispose();
    }
  }))!;
  var blue = 0;
  var purple = 0;
  var cyan = 0;
  for (var i = 0; i < pixels.lengthInBytes; i += 4) {
    if (pixels.getUint8(i + 3) < 160) continue;
    final r = pixels.getUint8(i);
    final g = pixels.getUint8(i + 1);
    final b = pixels.getUint8(i + 2);
    if (g > 180 && g - r > 80) {
      cyan++;
    } else if (r > 1.13 * g && b > r + 25) {
      purple++;
    } else if (b > g + 25 && g > r) {
      blue++;
    }
  }
  return (blue: blue, purple: purple, cyan: cyan);
}
