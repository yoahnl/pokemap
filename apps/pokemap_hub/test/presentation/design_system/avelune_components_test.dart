import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/presentation/design_system/avelune_design_system.dart';

void main() {
  testWidgets('AvelunePressable exposes state and physical press feedback',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _TestApp(
        child: AvelunePressable(
          semanticLabel: 'Cartouche Selbrume',
          selected: true,
          onPressed: () => taps++,
          child: const SizedBox(width: 120, height: 80),
        ),
      ),
    );

    final semantics =
        tester.getSemantics(find.byType(AvelunePressable)).getSemanticsData();
    expect(semantics.label, 'Cartouche Selbrume');
    expect(semantics.hasAction(ui.SemanticsAction.tap), isTrue);
    expect(semantics.flagsCollection.isButton, isTrue);
    expect(semantics.flagsCollection.isEnabled, ui.Tristate.isTrue);
    expect(semantics.flagsCollection.isSelected, ui.Tristate.isTrue);
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(AvelunePressable)),
    );
    await tester.pump();
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      lessThan(1),
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('AvelunePressable disables callbacks and uses reduced motion',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _TestApp(
        disableAnimations: true,
        child: AvelunePressable(
          semanticLabel: 'Jeu indisponible',
          enabled: false,
          invalid: true,
          onPressed: () => taps++,
          child: const SizedBox(width: 120, height: 80),
        ),
      ),
    );

    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration,
      AveluneMotionTokens.reduced.press,
    );
    await tester.tap(find.byType(AvelunePressable));
    expect(taps, 0);
    final semantics =
        tester.getSemantics(find.byType(AvelunePressable)).getSemanticsData();
    expect(semantics.label, 'Jeu indisponible');
    expect(semantics.hasAction(ui.SemanticsAction.tap), isFalse);
    expect(semantics.flagsCollection.isButton, isTrue);
    expect(semantics.flagsCollection.isEnabled, ui.Tristate.isFalse);
  });

  testWidgets('AveluneIconControl keeps a 48 dp target', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: AveluneIconControl(
          semanticLabel: 'Fermer',
          icon: Icons.close_rounded,
          onPressed: () {},
        ),
      ),
    );

    final size = tester.getSize(find.byType(AveluneIconControl));
    expect(size.width, greaterThanOrEqualTo(AveluneShapes.minimumTouchTarget));
    expect(size.height, greaterThanOrEqualTo(AveluneShapes.minimumTouchTarget));
    final semantics =
        tester.getSemantics(find.bySemanticsLabel('Fermer')).getSemanticsData();
    expect(semantics.hasAction(ui.SemanticsAction.tap), isTrue);
    expect(semantics.flagsCollection.isButton, isTrue);
    expect(semantics.flagsCollection.isEnabled, ui.Tristate.isTrue);
  });

  testWidgets('shared panels and state messages remain semantic',
      (tester) async {
    var actionCount = 0;
    await tester.pumpWidget(
      _TestApp(
        child: Column(
          children: <Widget>[
            const AveluneSectionLabel(
              icon: Icons.schedule_rounded,
              label: 'Activité récente',
            ),
            AveluneStateMessage(
              kind: AveluneStateMessageKind.error,
              title: 'Jeu indisponible',
              message: 'Certains fichiers nécessaires sont manquants.',
              actionLabel: 'Réessayer',
              onAction: () => actionCount++,
            ),
          ],
        ),
      ),
    );

    expect(find.byType(AveluneInsetPanel), findsOneWidget);
    expect(find.text('Activité récente'), findsOneWidget);
    expect(find.text('Jeu indisponible'), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    expect(actionCount, 1);
  });

  testWidgets('AveluneSheet opens and dismisses through its real control',
      (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => AveluneSheet.show<void>(
              context: context,
              title: 'Détails du jeu',
              builder: (_) => const Text('Informations'),
            ),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    expect(find.text('Détails du jeu'), findsOneWidget);
    expect(find.text('Informations'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Détails du jeu'), findsNothing);
  });

  testWidgets('bottom navigation exposes only home and settings',
      (tester) async {
    AveluneNavigationItem? selected;
    await tester.pumpWidget(
      _TestApp(
        child: AveluneBottomNavigation(
          selectedItem: AveluneNavigationItem.home,
          onItemSelected: (value) => selected = value,
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.byType(AveluneBottomNavigation), findsOneWidget);
    final semantics = tester
        .getSemantics(find.byType(AvelunePressable).first)
        .getSemanticsData();
    expect(semantics.hasAction(ui.SemanticsAction.tap), isTrue);
    expect(semantics.flagsCollection.isButton, isTrue);
    expect(semantics.flagsCollection.isEnabled, ui.Tristate.isTrue);
    expect(semantics.flagsCollection.isSelected, ui.Tristate.isTrue);

    await tester.tap(find.text('Settings'));
    expect(selected, AveluneNavigationItem.settings);
  });

  testWidgets('shared components tolerate reasonable text scaling',
      (tester) async {
    await tester.pumpWidget(
      _TestApp(
        textScaler: const TextScaler.linear(1.4),
        child: SizedBox(
          width: 320,
          height: 420,
          child: Column(
            children: <Widget>[
              Expanded(
                child: AveluneStateMessage(
                  kind: AveluneStateMessageKind.info,
                  title: 'Storage information',
                  message: 'Your installed games remain available offline.',
                  actionLabel: 'Review settings',
                  onAction: () {},
                ),
              ),
              AveluneBottomNavigation(
                selectedItem: AveluneNavigationItem.home,
                onItemSelected: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Review settings'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.child,
    this.disableAnimations = false,
    this.textScaler = TextScaler.noScaling,
  });

  final Widget child;
  final bool disableAnimations;
  final TextScaler textScaler;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AveluneThemeData.standard.applyTo(ThemeData.dark()),
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(
            disableAnimations: disableAnimations,
            textScaler: textScaler,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
