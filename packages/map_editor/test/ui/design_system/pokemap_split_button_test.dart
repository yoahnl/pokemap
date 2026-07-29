import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  Widget buildSubject({
    required VoidCallback? onPressed,
    required ValueChanged<String> onSelected,
    FocusNode? focusNode,
    List<PokeMapMenuItem<String>>? items,
  }) {
    return MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: Center(
          child: PokeMapSplitButton<String>(
            onPressed: onPressed,
            items: items ??
                const <PokeMapMenuItem<String>>[
                  PokeMapMenuItem(value: 'brush', label: 'Pinceau'),
                  PokeMapMenuItem(
                    value: 'fill',
                    label: 'Remplissage',
                    enabled: false,
                    disabledReason: 'Aucune zone fermée',
                  ),
                  PokeMapMenuItem(value: 'rectangle', label: 'Rectangle'),
                ],
            onSelected: onSelected,
            tooltip: 'Utiliser le pinceau',
            menuTooltip: 'Choisir un outil',
            focusNode: focusNode,
            child: const Text('Peindre'),
          ),
        ),
      ),
    );
  }

  testWidgets('keeps primary and menu pointer actions distinct',
      (tester) async {
    final semantics = tester.ensureSemantics();
    var primaryActivations = 0;
    String? selected;

    await tester.pumpWidget(
      buildSubject(
        onPressed: () => primaryActivations += 1,
        onSelected: (value) => selected = value,
      ),
    );

    await tester.tap(find.bySemanticsLabel('Utiliser le pinceau'));
    await tester.pump();
    expect(primaryActivations, 1);
    expect(selected, isNull);

    await tester.tap(find.bySemanticsLabel('Choisir un outil'));
    await tester.pump();
    expect(find.byType(PokeMapContextMenu<String>), findsOneWidget);
    expect(primaryActivations, 1);

    await tester.tap(find.text('Rectangle'));
    await tester.pump();
    expect(selected, 'rectangle');
    expect(find.byType(PokeMapContextMenu<String>), findsNothing);
    semantics.dispose();
  });

  testWidgets(
      'Enter and Space activate the focused segment and arrows skip disabled items',
      (tester) async {
    final focusNode = FocusNode(debugLabel: 'split primary');
    addTearDown(focusNode.dispose);
    var primaryActivations = 0;
    String? selected;

    await tester.pumpWidget(
      buildSubject(
        focusNode: focusNode,
        onPressed: () => primaryActivations += 1,
        onSelected: (value) => selected = value,
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(primaryActivations, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(primaryActivations, 2);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    final menuSegment = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics && widget.properties.label == 'Choisir un outil',
    );
    final menuDetector = find.descendant(
      of: menuSegment,
      matching: find.byType(FocusableActionDetector),
    );
    expect(
      tester.widget<FocusableActionDetector>(menuDetector).focusNode!.hasFocus,
      isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.byType(PokeMapContextMenu<String>), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.byType(PokeMapContextMenu<String>), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(selected, 'rectangle');
    expect(find.byType(PokeMapContextMenu<String>), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(find.byType(PokeMapContextMenu<String>), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.byType(PokeMapContextMenu<String>), findsNothing);
    expect(
      tester.widget<FocusableActionDetector>(menuDetector).focusNode!.hasFocus,
      isTrue,
    );
  });

  testWidgets('exposes tooltips and explicit semantics for both segments',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      buildSubject(
        onPressed: () {},
        onSelected: (_) {},
      ),
    );

    expect(find.byTooltip('Utiliser le pinceau'), findsOneWidget);
    expect(find.byTooltip('Choisir un outil'), findsOneWidget);
    expect(find.bySemanticsLabel('Utiliser le pinceau'), findsOneWidget);
    expect(find.bySemanticsLabel('Choisir un outil'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Utiliser le pinceau'))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Choisir un outil'))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    semantics.dispose();
  });

  testWidgets('disabled segments leave traversal and cannot activate',
      (tester) async {
    final focusNode = FocusNode(debugLabel: 'disabled split primary');
    addTearDown(focusNode.dispose);
    var primaryActivations = 0;
    String? selected;

    await tester.pumpWidget(
      buildSubject(
        focusNode: focusNode,
        onPressed: null,
        items: const [
          PokeMapMenuItem(
            value: 'fill',
            label: 'Remplissage',
            enabled: false,
            disabledReason: 'Aucune zone fermée',
          ),
        ],
        onSelected: (value) => selected = value,
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    final detectors = tester.widgetList<FocusableActionDetector>(
      find.descendant(
        of: find.byType(PokeMapSplitButton<String>),
        matching: find.byType(FocusableActionDetector),
      ),
    );
    expect(focusNode.hasFocus, isFalse);
    expect(detectors.every((detector) => detector.focusNode!.skipTraversal),
        isTrue);
    expect(
      detectors.every((detector) => !detector.focusNode!.canRequestFocus),
      isTrue,
    );
    expect(primaryActivations, 0);
    expect(selected, isNull);
    expect(find.byType(PokeMapContextMenu<String>), findsNothing);
  });

  testWidgets('anchors its menu in the nearest overlay coordinate space',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.only(left: 180, top: 120),
            child: SizedBox(
              width: 400,
              height: 300,
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (context) => Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: PokeMapSplitButton<String>(
                          onPressed: () {},
                          items: const [
                            PokeMapMenuItem(
                              value: 'brush',
                              label: 'Pinceau',
                            ),
                          ],
                          onSelected: (_) {},
                          tooltip: 'Peindre',
                          menuTooltip: 'Ouvrir les outils',
                          child: const Text('Outil'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final menuSegment = find.bySemanticsLabel('Ouvrir les outils');
    final segmentRect = tester.getRect(menuSegment);
    await tester.tap(menuSegment);
    await tester.pump();

    final menuRect = tester.getRect(
      find.descendant(
        of: find.byType(PokeMapContextMenu<String>),
        matching: find.byType(PokeMapPanel),
      ),
    );
    expect(menuRect.left, closeTo(segmentRect.left, 0.1));
    expect(menuRect.top, closeTo(segmentRect.bottom, 0.1));
  });

  testWidgets('restores primary focus when open alternatives become disabled',
      (tester) async {
    final primaryFocusNode = FocusNode(debugLabel: 'dynamic split primary');
    final harnessKey = GlobalKey<_MutableSplitHarnessState>();
    addTearDown(primaryFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: Center(
            child: _MutableSplitHarness(
              key: harnessKey,
              primaryFocusNode: primaryFocusNode,
            ),
          ),
        ),
      ),
    );

    primaryFocusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(find.byType(PokeMapContextMenu<String>), findsOneWidget);

    harnessKey.currentState!.disableAlternatives();
    await tester.pump();
    await tester.pump();

    expect(find.byType(PokeMapContextMenu<String>), findsNothing);
    expect(primaryFocusNode.hasFocus, isTrue);
  });
}

class _MutableSplitHarness extends StatefulWidget {
  const _MutableSplitHarness({
    required this.primaryFocusNode,
    super.key,
  });

  final FocusNode primaryFocusNode;

  @override
  State<_MutableSplitHarness> createState() => _MutableSplitHarnessState();
}

class _MutableSplitHarnessState extends State<_MutableSplitHarness> {
  bool _alternativesEnabled = true;

  void disableAlternatives() {
    setState(() => _alternativesEnabled = false);
  }

  @override
  Widget build(BuildContext context) {
    return PokeMapSplitButton<String>(
      focusNode: widget.primaryFocusNode,
      onPressed: () {},
      items: [
        PokeMapMenuItem(
          value: 'brush',
          label: 'Pinceau',
          enabled: _alternativesEnabled,
          disabledReason:
              _alternativesEnabled ? null : 'Aucune alternative disponible',
        ),
      ],
      onSelected: (_) {},
      tooltip: 'Peindre',
      menuTooltip: 'Choisir un outil',
      child: const Text('Outil'),
    );
  }
}
