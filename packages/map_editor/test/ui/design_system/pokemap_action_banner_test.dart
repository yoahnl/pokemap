import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('stays usable at 200% text scale in light and dark themes',
      (tester) async {
    for (final theme in [PokeMapTheme.light(), PokeMapTheme.dark()]) {
      await tester.binding.setSurfaceSize(const Size(520, 420));
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: Scaffold(
            body: PokeMapActionBanner(
              title: 'Une nouvelle aventure t’attend',
              message: 'PokeMap 0.3.1 est prêt à rejoindre ton équipe.',
              tone: PokeMapTone.brand,
              actions: [
                PokeMapActionBannerAction(
                  label: 'Lire les notes',
                  onPressed: () {},
                  variant: PokeMapButtonVariant.secondary,
                ),
                PokeMapActionBannerAction(
                  label: 'Mettre à jour',
                  onPressed: () {},
                ),
              ],
              dismissLabel: 'Fermer',
              onDismiss: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Mettre à jour'), findsOneWidget);
      expect(find.byType(PokeMapPanel), findsOneWidget);
    }
  });

  testWidgets('exposes semantics and a keyboard focus order', (tester) async {
    var primaryActivations = 0;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: PokeMapActionBanner(
            title: 'Mise à jour disponible',
            message: 'La version 0.3.1 est prête.',
            tone: PokeMapTone.info,
            actions: [
              PokeMapActionBannerAction(
                label: 'Mettre à jour',
                onPressed: () => primaryActivations += 1,
              ),
            ],
            dismissLabel: 'Fermer',
            onDismiss: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.bySemanticsLabel(
        'Mise à jour disponible. La version 0.3.1 est prête.',
      ),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(primaryActivations, 1);

    semantics.dispose();
  });
}
