import 'package:avelune_studio/presentation/gallery/studio_widget_gallery.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_resource_card.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_search_field.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';

void main() {
  for (final (name, size, textScale) in [
    ('desktop', const Size(1440, 1000), 1.0),
    ('compact-large-text', const Size(480, 800), 1.75),
  ]) {
    testWidgets('gallery controls resources and tokens remain usable: $name', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(loadDesktopCaptureFonts);
      final capture = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: studioTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
            home: const StudioWidgetGallery(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Catalogue des widgets'), findsOneWidget);
      await tester.tap(find.text('Principale'));
      await tester.pumpAndSettle();
      expect(find.text('Principale activée.'), findsOneWidget);
      await captureM3Widget(tester, capture, 'studio-gallery-$name-controls');

      await tester.tap(find.text('Ressources'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byType(StudioSearchField));
      await tester.enterText(find.byType(TextField), 'introuvable');
      await tester.pumpAndSettle();
      expect(find.text('Aucun exemple trouvé'), findsOneWidget);
      expect(find.byType(StudioResourceCard), findsNothing);
      await tester.tap(find.byTooltip('Effacer la recherche'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Nature'));
      await tester.tap(find.text('Nature'));
      await tester.pumpAndSettle();
      expect(find.text('Sélection : Forêt · 2 résultats'), findsOneWidget);
      await tester.ensureVisible(find.text('Rivière'));
      await tester.tap(find.text('Rivière'));
      await tester.pumpAndSettle();
      expect(find.text('Sélection : Rivière · 2 résultats'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await captureM3Widget(tester, capture, 'studio-gallery-$name-resources');

      await tester.tap(find.text('Charte'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Couleurs sémantiques'));
      await tester.pumpAndSettle();
      expect(find.text('Sélection carte'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await captureM3Widget(tester, capture, 'studio-gallery-$name-tokens');
      await tester.pumpWidget(const SizedBox());
    });
  }
}
