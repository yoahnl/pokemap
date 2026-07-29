import 'dart:ui' show SemanticsAction;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  const items = <PokeMapMenuItem<String>>[
    PokeMapMenuItem(
      value: 'open',
      label: 'Ouvrir',
      shortcutLabel: 'Entrée',
    ),
    PokeMapMenuItem(
      value: 'paste',
      label: 'Coller',
      enabled: false,
      disabledReason: 'Le presse-papiers est vide',
    ),
    PokeMapMenuItem(
      value: 'delete',
      label: 'Supprimer',
      destructive: true,
    ),
  ];

  testWidgets('selects enabled entries and closes the controlled overlay',
      (tester) async {
    String? selected;

    await tester.pumpWidget(
      _ContextMenuHarness(
        items: items,
        onSelected: (value) => selected = value,
      ),
    );
    await tester.tap(find.text('Afficher'));
    await tester.pump();

    expect(find.byType(PokeMapContextMenu<String>), findsOneWidget);
    await tester.tap(find.text('Ouvrir'));
    await tester.pump();

    expect(selected, 'open');
    expect(find.byType(PokeMapContextMenu<String>), findsNothing);
  });

  testWidgets('exposes a disabled reason and never activates that entry',
      (tester) async {
    final semantics = tester.ensureSemantics();
    String? selected;

    await tester.pumpWidget(
      _ContextMenuHarness(
        items: items,
        onSelected: (value) => selected = value,
      ),
    );
    await tester.tap(find.text('Afficher'));
    await tester.pump();

    expect(find.byTooltip('Le presse-papiers est vide'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.enabled == false &&
            widget.properties.label?.contains('Coller') == true &&
            widget.properties.label?.contains('Le presse-papiers est vide') ==
                true,
      ),
      findsOneWidget,
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Ouvrir'))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );

    await tester.tap(find.text('Coller'));
    await tester.pump();
    expect(selected, isNull);
    expect(find.byType(PokeMapContextMenu<String>), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('uses destructive tokens and renders requested separators',
      (tester) async {
    await tester.pumpWidget(
      _ContextMenuHarness(
        items: items,
        dividerAfter: const <int>{1},
        onSelected: (_) {},
      ),
    );
    await tester.tap(find.text('Afficher'));
    await tester.pump();

    final destructiveText = tester.widget<Text>(find.text('Supprimer'));
    expect(destructiveText.style?.color, PokeMapColorTokens.dark.error);

    final divider = tester.widget<Divider>(
      find.descendant(
        of: find.byType(PokeMapContextMenu<String>),
        matching: find.byType(Divider),
      ),
    );
    expect(divider.color, PokeMapColorTokens.dark.divider);
    expect(find.text('Entrée'), findsOneWidget);
  });

  testWidgets('keyboard navigation skips disabled entries', (tester) async {
    String? selected;

    await tester.pumpWidget(
      _ContextMenuHarness(
        items: items,
        onSelected: (value) => selected = value,
      ),
    );
    await tester.tap(find.text('Afficher'));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(selected, 'delete');
    expect(find.byType(PokeMapContextMenu<String>), findsNothing);
  });

  testWidgets('Escape and outside clicks close and restore invoker focus',
      (tester) async {
    final invokerFocusNode = FocusNode(debugLabel: 'context menu invoker');
    addTearDown(invokerFocusNode.dispose);

    await tester.pumpWidget(
      _ContextMenuHarness(
        items: items,
        invokerFocusNode: invokerFocusNode,
        onSelected: (_) {},
      ),
    );

    await tester.tap(find.text('Afficher'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.byType(PokeMapContextMenu<String>), findsNothing);
    expect(invokerFocusNode.hasFocus, isTrue);

    await tester.tap(find.text('Afficher'));
    await tester.pump();
    final secondaryClick = await tester.startGesture(
      const Offset(20, 20),
      buttons: kSecondaryMouseButton,
    );
    await secondaryClick.up();
    await tester.pump();
    expect(find.byType(PokeMapContextMenu<String>), findsNothing);
    expect(invokerFocusNode.hasFocus, isTrue);

    await tester.tap(find.text('Afficher'));
    await tester.pump();
    await tester.tapAt(const Offset(20, 20));
    await tester.pump();
    expect(find.byType(PokeMapContextMenu<String>), findsNothing);
    expect(invokerFocusNode.hasFocus, isTrue);
  });

  testWidgets('Escape closes when every projected entry is disabled',
      (tester) async {
    final invokerFocusNode = FocusNode(debugLabel: 'disabled menu invoker');
    addTearDown(invokerFocusNode.dispose);

    await tester.pumpWidget(
      _ContextMenuHarness(
        items: const [
          PokeMapMenuItem(
            value: 'paste',
            label: 'Coller',
            enabled: false,
            disabledReason: 'Le presse-papiers est vide',
          ),
        ],
        invokerFocusNode: invokerFocusNode,
        onSelected: (_) {},
      ),
    );

    await tester.tap(find.text('Afficher'));
    await tester.pump();
    expect(find.byType(PokeMapContextMenu<String>), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(find.byType(PokeMapContextMenu<String>), findsNothing);
    expect(invokerFocusNode.hasFocus, isTrue);
  });

  testWidgets('restores focus and dismisses before invoking selection',
      (tester) async {
    final invokerFocusNode = FocusNode(debugLabel: 'selection invoker');
    addTearDown(invokerFocusNode.dispose);
    final events = <String>[];
    var invokerWasFocusedDuringSelection = false;

    await tester.pumpWidget(
      _ContextMenuHarness(
        items: items,
        invokerFocusNode: invokerFocusNode,
        onDismissed: () => events.add('dismiss'),
        onSelected: (_) {
          events.add('select');
          invokerWasFocusedDuringSelection = invokerFocusNode.hasFocus;
        },
      ),
    );
    await tester.tap(find.text('Afficher'));
    await tester.pump();

    await tester.tap(find.text('Ouvrir'));
    await tester.pump();

    expect(events, ['dismiss', 'select']);
    expect(invokerWasFocusedDuringSelection, isTrue);
  });

  testWidgets('keeps the menu inside a narrow overlay edge inset',
      (tester) async {
    const overlayKey = ValueKey('narrow-overlay');

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 120, top: 80),
              child: SizedBox(
                key: overlayKey,
                width: 200,
                height: 160,
                child: Overlay(
                  initialEntries: [
                    OverlayEntry(
                      builder: (context) => PokeMapContextMenu<String>(
                        anchor: const Offset(190, 150),
                        items: const [
                          PokeMapMenuItem(
                            value: 'open',
                            label: 'Ouvrir',
                          ),
                        ],
                        onSelected: (_) {},
                        onDismiss: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final overlayRect = tester.getRect(find.byKey(overlayKey));
    final menuRect = tester.getRect(find.byType(PokeMapPanel));
    expect(menuRect.left, greaterThanOrEqualTo(overlayRect.left + 8));
    expect(menuRect.top, greaterThanOrEqualTo(overlayRect.top + 8));
    expect(menuRect.right, lessThanOrEqualTo(overlayRect.right - 8));
    expect(menuRect.bottom, lessThanOrEqualTo(overlayRect.bottom - 8));
  });

  testWidgets('focuses an entry enabled in place after an all-disabled opening',
      (tester) async {
    final harnessKey = GlobalKey<_MutableContextMenuHarnessState>();
    String? selected;

    await tester.pumpWidget(
      _MutableContextMenuHarness(
        key: harnessKey,
        onSelected: (value) => selected = value,
      ),
    );
    await tester.tap(find.text('Afficher'));
    await tester.pump();
    expect(find.byType(PokeMapContextMenu<String>), findsOneWidget);

    harnessKey.currentState!.enableEntry();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(selected, 'open');
    expect(find.byType(PokeMapContextMenu<String>), findsNothing);
  });
}

class _MutableContextMenuHarness extends StatefulWidget {
  const _MutableContextMenuHarness({
    required this.onSelected,
    super.key,
  });

  final ValueChanged<String> onSelected;

  @override
  State<_MutableContextMenuHarness> createState() =>
      _MutableContextMenuHarnessState();
}

class _MutableContextMenuHarnessState
    extends State<_MutableContextMenuHarness> {
  bool _isOpen = false;
  bool _entryEnabled = false;

  void enableEntry() {
    setState(() => _entryEnabled = true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: TextButton(
                onPressed: () => setState(() => _isOpen = true),
                child: const Text('Afficher'),
              ),
            ),
            if (_isOpen)
              PokeMapContextMenu<String>(
                anchor: const Offset(120, 80),
                items: [
                  PokeMapMenuItem(
                    value: 'open',
                    label: 'Ouvrir',
                    enabled: _entryEnabled,
                    disabledReason:
                        _entryEnabled ? null : 'Action temporairement bloquée',
                  ),
                ],
                onSelected: widget.onSelected,
                onDismiss: () => setState(() => _isOpen = false),
              ),
          ],
        ),
      ),
    );
  }
}

class _ContextMenuHarness extends StatefulWidget {
  const _ContextMenuHarness({
    required this.items,
    required this.onSelected,
    this.dividerAfter = const <int>{},
    this.invokerFocusNode,
    this.onDismissed,
  });

  final List<PokeMapMenuItem<String>> items;
  final ValueChanged<String> onSelected;
  final Set<int> dividerAfter;
  final FocusNode? invokerFocusNode;
  final VoidCallback? onDismissed;

  @override
  State<_ContextMenuHarness> createState() => _ContextMenuHarnessState();
}

class _ContextMenuHarnessState extends State<_ContextMenuHarness> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: TextButton(
                focusNode: widget.invokerFocusNode,
                onPressed: () {
                  widget.invokerFocusNode?.requestFocus();
                  setState(() => _isOpen = true);
                },
                child: const Text('Afficher'),
              ),
            ),
            if (_isOpen)
              PokeMapContextMenu<String>(
                anchor: const Offset(240, 120),
                items: widget.items,
                dividerAfter: widget.dividerAfter,
                invokerFocusNode: widget.invokerFocusNode,
                onSelected: widget.onSelected,
                onDismiss: () {
                  widget.onDismissed?.call();
                  setState(() => _isOpen = false);
                },
              ),
          ],
        ),
      ),
    );
  }
}
