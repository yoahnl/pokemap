import 'dart:ui' show SemanticsAction;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/pokemap_context_menu.dart';
import 'package:map_editor/src/ui/design_system/pokemap_panel.dart';

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

  testWidgets(
      'selects the rendered item after its source list mutates in place',
      (tester) async {
    final mutableItems = <PokeMapMenuItem<String>>[
      const PokeMapMenuItem(value: 'safe', label: 'Action visible'),
    ];
    String? selected;

    await tester.pumpWidget(
      _ContextMenuHarness(
        items: mutableItems,
        onSelected: (value) => selected = value,
      ),
    );
    await tester.tap(find.text('Afficher'));
    await tester.pump();

    mutableItems[0] = const PokeMapMenuItem(
      value: 'delete',
      label: 'Action destructive invisible',
      destructive: true,
    );
    expect(find.text('Action visible'), findsOneWidget);
    expect(find.text('Action destructive invisible'), findsNothing);

    await tester.tap(find.text('Action visible'));
    await tester.pump();

    expect(selected, 'safe');
  });

  testWidgets('keeps rendered rows safe after source length mutates in place',
      (tester) async {
    final mutableItems = <PokeMapMenuItem<String>>[
      const PokeMapMenuItem(value: 'safe', label: 'Action persistante'),
    ];
    String? selected;

    await tester.pumpWidget(
      _ContextMenuHarness(
        items: mutableItems,
        onSelected: (value) => selected = value,
      ),
    );
    await tester.tap(find.text('Afficher'));
    await tester.pump();

    mutableItems.clear();
    await tester.tap(find.text('Action persistante'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(selected, 'safe');
  });

  testWidgets('resnapshots a same-list length mutation on a real rebuild',
      (tester) async {
    final mutableItems = <PokeMapMenuItem<String>>[
      const PokeMapMenuItem(value: 'safe', label: 'Action initiale'),
    ];
    final harnessKey = GlobalKey<_ContextMenuHarnessState>();
    String? selected;

    await tester.pumpWidget(
      _ContextMenuHarness(
        key: harnessKey,
        items: mutableItems,
        onSelected: (value) => selected = value,
      ),
    );
    await tester.tap(find.text('Afficher'));
    await tester.pump();

    mutableItems.add(
      const PokeMapMenuItem(value: 'second', label: 'Action ajoutée'),
    );
    harnessKey.currentState!.rebuildMenu();
    await tester.pump();

    expect(find.text('Action initiale'), findsOneWidget);
    expect(find.text('Action ajoutée'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(selected, 'second');
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

  testWidgets('announces the rendered shortcut label in row semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _ContextMenuHarness(
        items: items,
        onSelected: (_) {},
      ),
    );
    await tester.tap(find.text('Afficher'));
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label?.contains('Ouvrir') == true &&
            widget.properties.hint?.contains('Raccourci : Entrée') == true,
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('neutralizes hostile inherited decoration on row text',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.yellow,
              decoration: TextDecoration.underline,
              decorationColor: Colors.yellow,
            ),
            child: Stack(
              children: [
                PokeMapContextMenu<String>(
                  anchor: const Offset(120, 80),
                  items: const [
                    PokeMapMenuItem(
                      value: 'open',
                      label: 'Ouvrir hostile',
                      shortcutLabel: 'Cmd+O',
                    ),
                  ],
                  onSelected: (_) {},
                  onDismiss: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    TextStyle effectiveStyle(String text) {
      final finder = find.text(text);
      final widget = tester.widget<Text>(finder);
      return DefaultTextStyle.of(tester.element(finder)).style.merge(
            widget.style,
          );
    }

    expect(effectiveStyle('Ouvrir hostile').decoration, TextDecoration.none);
    expect(effectiveStyle('Cmd+O').decoration, TextDecoration.none);
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

  testWidgets('renders real selection with token, check, and semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _ContextMenuHarness(
        items: const [
          PokeMapMenuItem(value: 'plain', label: 'Action neutre'),
          PokeMapMenuItem(
            value: 'selected',
            label: 'Action active',
            selected: true,
          ),
        ],
        onSelected: (_) {},
      ),
    );
    await tester.tap(find.text('Afficher'));
    await tester.pump();

    final selectedRow = find.ancestor(
      of: find.text('Action active'),
      matching: find.byType(AnimatedContainer),
    );
    final decoration = tester.widget<AnimatedContainer>(selectedRow).decoration!
        as BoxDecoration;

    expect(decoration.color, PokeMapColorTokens.dark.cardSelected);
    expect(
      find.descendant(
        of: selectedRow,
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Action active' &&
            widget.properties.selected == true,
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('keeps initial keyboard focus distinct from selection',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _ContextMenuHarness(
        items: const [
          PokeMapMenuItem(value: 'focused', label: 'Action focus'),
          PokeMapMenuItem(value: 'other', label: 'Autre action'),
        ],
        onSelected: (_) {},
      ),
    );
    await tester.tap(find.text('Afficher'));
    await tester.pump();
    await tester.pump();

    final focusedRow = find.ancestor(
      of: find.text('Action focus'),
      matching: find.byType(AnimatedContainer),
    );
    final decoration = tester.widget<AnimatedContainer>(focusedRow).decoration!
        as BoxDecoration;
    final focusDetector = tester.widget<FocusableActionDetector>(
      find.ancestor(
        of: find.text('Action focus'),
        matching: find.byType(FocusableActionDetector),
      ),
    );

    expect(focusDetector.focusNode!.hasFocus, isTrue);
    expect(decoration.color, PokeMapColorTokens.dark.transparent);
    expect((decoration.border! as Border).top.color,
        PokeMapColorTokens.dark.focusRing);
    expect(
      find.descendant(
        of: focusedRow,
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Action focus' &&
            widget.properties.selected == true,
      ),
      findsNothing,
    );
    final ordinarySemantics = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Action focus',
      ),
    );
    expect(ordinarySemantics.properties.selected, isNull);
    semantics.dispose();
  });

  testWidgets('uses the hover token without claiming selection',
      (tester) async {
    await tester.pumpWidget(
      _ContextMenuHarness(
        items: const [
          PokeMapMenuItem(value: 'focused', label: 'Action focus'),
          PokeMapMenuItem(value: 'hovered', label: 'Action survolée'),
        ],
        onSelected: (_) {},
      ),
    );
    await tester.tap(find.text('Afficher'));
    await tester.pump();

    final hoveredRow = find.ancestor(
      of: find.text('Action survolée'),
      matching: find.byType(AnimatedContainer),
    );
    final hoverDetector = tester.widget<FocusableActionDetector>(
      find.ancestor(
        of: find.text('Action survolée'),
        matching: find.byType(FocusableActionDetector),
      ),
    );
    hoverDetector.onShowHoverHighlight!(true);
    await tester.pump(const Duration(milliseconds: 150));

    final decoration = tester.widget<AnimatedContainer>(hoveredRow).decoration!
        as BoxDecoration;
    expect(decoration.color, PokeMapColorTokens.dark.cardHover);
    expect(
      find.descendant(
        of: hoveredRow,
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsNothing,
    );
  });

  testWidgets('clears hover when an item is disabled and re-enabled',
      (tester) async {
    final harnessKey = GlobalKey<_MutableContextMenuHarnessState>();

    await tester.pumpWidget(
      _MutableContextMenuHarness(
        key: harnessKey,
        onSelected: (_) {},
      ),
    );
    await tester.tap(find.text('Afficher'));
    await tester.pump();
    harnessKey.currentState!.enableEntry();
    await tester.pump();

    final row = find.ancestor(
      of: find.text('Ouvrir'),
      matching: find.byType(AnimatedContainer),
    );
    final hoverDetector = tester.widget<FocusableActionDetector>(
      find.ancestor(
        of: find.text('Ouvrir'),
        matching: find.byType(FocusableActionDetector),
      ),
    );
    hoverDetector.onShowHoverHighlight!(true);
    await tester.pump(const Duration(milliseconds: 150));

    BoxDecoration decoration() {
      return tester.widget<AnimatedContainer>(row).decoration! as BoxDecoration;
    }

    expect(decoration().color, PokeMapColorTokens.dark.cardHover);

    harnessKey.currentState!.disableEntry();
    await tester.pump(const Duration(milliseconds: 150));
    expect(decoration().color, PokeMapColorTokens.dark.transparent);

    harnessKey.currentState!.enableEntry();
    await tester.pump(const Duration(milliseconds: 150));
    expect(decoration().color, PokeMapColorTokens.dark.transparent);
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

  testWidgets('preserves the focused value when items reorder in place',
      (tester) async {
    final harnessKey = GlobalKey<_ReorderContextMenuHarnessState>();

    await tester.pumpWidget(_ReorderContextMenuHarness(key: harnessKey));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    harnessKey.currentState!.reorder();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(harnessKey.currentState!.selected, 'delete');
  });

  testWidgets('scrolls a long menu to its circularly focused last action',
      (tester) async {
    const overlayKey = ValueKey('long-menu-overlay');
    final harnessKey = GlobalKey<_LongContextMenuHarnessState>();

    await tester.pumpWidget(
      _LongContextMenuHarness(
        key: harnessKey,
        overlayKey: overlayKey,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    final overlayRect = tester.getRect(find.byKey(overlayKey));
    final lastItemRect = tester.getRect(find.text('Action 19'));
    expect(lastItemRect.top, greaterThanOrEqualTo(overlayRect.top));
    expect(lastItemRect.bottom, lessThanOrEqualTo(overlayRect.bottom));

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(harnessKey.currentState!.selected, 'action-19');
    expect(find.byType(PokeMapContextMenu<String>), findsNothing);
  });

  testWidgets('rearms dismissal when a controlled parent keeps the menu open',
      (tester) async {
    final harnessKey = GlobalKey<_StickyDismissHarnessState>();

    await tester.pumpWidget(_StickyDismissHarness(key: harnessKey));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(harnessKey.currentState!.dismissals, 1);
    expect(find.byType(PokeMapContextMenu<String>), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(harnessKey.currentState!.dismissals, 2);
    expect(find.byType(PokeMapContextMenu<String>), findsNothing);
  });

  testWidgets('dismiss callback focus is not stolen back by the invoker',
      (tester) async {
    final invokerFocusNode = FocusNode(debugLabel: 'dismiss invoker');
    final callbackFocusNode = FocusNode(debugLabel: 'dismiss callback target');
    addTearDown(invokerFocusNode.dispose);
    addTearDown(callbackFocusNode.dispose);

    await tester.pumpWidget(
      _DismissFocusHarness(
        invokerFocusNode: invokerFocusNode,
        callbackFocusNode: callbackFocusNode,
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(callbackFocusNode.hasFocus, isTrue);
    expect(invokerFocusNode.hasFocus, isFalse);
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

  void disableEntry() {
    setState(() => _entryEnabled = false);
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
    super.key,
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

  void rebuildMenu() {
    setState(() {});
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

class _ReorderContextMenuHarness extends StatefulWidget {
  const _ReorderContextMenuHarness({super.key});

  @override
  State<_ReorderContextMenuHarness> createState() =>
      _ReorderContextMenuHarnessState();
}

class _ReorderContextMenuHarnessState
    extends State<_ReorderContextMenuHarness> {
  bool _reordered = false;
  String? selected;

  void reorder() {
    setState(() => _reordered = true);
  }

  @override
  Widget build(BuildContext context) {
    const safe = PokeMapMenuItem(value: 'safe', label: 'Action sûre');
    const destructive = PokeMapMenuItem(
      value: 'delete',
      label: 'Supprimer',
      destructive: true,
    );
    return MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: Stack(
          children: [
            PokeMapContextMenu<String>(
              anchor: const Offset(120, 80),
              items: _reordered ? [destructive, safe] : [safe, destructive],
              onSelected: (value) => selected = value,
              onDismiss: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _LongContextMenuHarness extends StatefulWidget {
  const _LongContextMenuHarness({
    required this.overlayKey,
    super.key,
  });

  final Key overlayKey;

  @override
  State<_LongContextMenuHarness> createState() =>
      _LongContextMenuHarnessState();
}

class _LongContextMenuHarnessState extends State<_LongContextMenuHarness> {
  bool _isOpen = true;
  String? selected;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            key: widget.overlayKey,
            width: 280,
            height: 160,
            child: Stack(
              children: [
                if (_isOpen)
                  PokeMapContextMenu<String>(
                    anchor: const Offset(8, 8),
                    items: List<PokeMapMenuItem<String>>.generate(
                      20,
                      (index) => PokeMapMenuItem(
                        value: 'action-$index',
                        label: 'Action $index',
                      ),
                    ),
                    onSelected: (value) => selected = value,
                    onDismiss: () => setState(() => _isOpen = false),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StickyDismissHarness extends StatefulWidget {
  const _StickyDismissHarness({super.key});

  @override
  State<_StickyDismissHarness> createState() => _StickyDismissHarnessState();
}

class _StickyDismissHarnessState extends State<_StickyDismissHarness> {
  bool _isOpen = true;
  int dismissals = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: Stack(
          children: [
            if (_isOpen)
              PokeMapContextMenu<String>(
                anchor: const Offset(120, 80),
                items: const [
                  PokeMapMenuItem(value: 'open', label: 'Ouvrir'),
                ],
                onSelected: (_) {},
                onDismiss: () {
                  dismissals += 1;
                  if (dismissals == 2) {
                    setState(() => _isOpen = false);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DismissFocusHarness extends StatefulWidget {
  const _DismissFocusHarness({
    required this.invokerFocusNode,
    required this.callbackFocusNode,
  });

  final FocusNode invokerFocusNode;
  final FocusNode callbackFocusNode;

  @override
  State<_DismissFocusHarness> createState() => _DismissFocusHarnessState();
}

class _DismissFocusHarnessState extends State<_DismissFocusHarness> {
  bool _isOpen = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: Stack(
          children: [
            TextButton(
              focusNode: widget.invokerFocusNode,
              onPressed: () {},
              child: const Text('Invoker'),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: TextButton(
                focusNode: widget.callbackFocusNode,
                onPressed: () {},
                child: const Text('Callback target'),
              ),
            ),
            if (_isOpen)
              PokeMapContextMenu<String>(
                anchor: const Offset(120, 80),
                items: const [
                  PokeMapMenuItem(value: 'open', label: 'Ouvrir'),
                ],
                invokerFocusNode: widget.invokerFocusNode,
                onSelected: (_) {},
                onDismiss: () {
                  setState(() => _isOpen = false);
                  widget.callbackFocusNode.requestFocus();
                  FocusManager.instance.applyFocusChangesIfNeeded();
                },
              ),
          ],
        ),
      ),
    );
  }
}
