import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_destination.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_navigation.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_route_presentation.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  test('rail presentation follows the exact desktop breakpoints', () {
    for (final entry in <(double, double, bool)>[
      (0, 72, true),
      (899, 72, true),
      (900, 148, false),
      (1099, 148, false),
      (1100, 168, false),
      (1479, 168, false),
      (1480, 176, false),
      (1671, 176, false),
      (1672, 191, false),
      (1920, 191, false),
    ]) {
      final presentation = narrativeStudioRailPresentation(entry.$1);
      expect(presentation.width, entry.$2, reason: '${entry.$1}px');
      expect(presentation.collapsed, entry.$3, reason: '${entry.$1}px');
    }
  });

  testWidgets('desktop cross matrix renders every shell slot without overflow',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const widths = <double>[800, 1024, 1099, 1280, 1672, 1920];
    const heights = <double>[650, 768, 941];
    const textScales = <double>[1, 1.5, 2];

    for (final width in widths) {
      for (final height in heights) {
        for (final textScale in textScales) {
          await _pumpResponsiveShell(
            tester,
            width: width,
            height: height,
            textScale: textScale,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: 'overflow at ${width}x$height / ${textScale * 100}%',
          );
          expect(
            find.byKey(narrativeStudioProductShellHeaderKey),
            findsOneWidget,
          );
          expect(
            find.byKey(narrativeStudioProductShellNavigationKey),
            findsOneWidget,
          );
          expect(
            find.byKey(narrativeStudioProductShellWorkspaceKey),
            findsOneWidget,
          );
          expect(
            find.byKey(narrativeStudioWorkspaceContextKey),
            findsOneWidget,
          );
        }
      }
    }
  });

  testWidgets(
      'compact 800x650 at 200 percent keeps every destination reachable',
      (tester) async {
    final opened = <NarrativeStudioRouteLocation>[];
    await _pumpResponsiveShell(
      tester,
      width: 800,
      height: 650,
      textScale: 2,
      onSelectLocation: opened.add,
    );

    final scrollView = find.byKey(
      const ValueKey('narrative-studio-product-navigation-scroll'),
    );
    expect(scrollView, findsOneWidget);
    final scrollable = find.descendant(
      of: scrollView,
      matching: find.byType(Scrollable),
    );

    for (final key in const <ValueKey<String>>[
      ValueKey('narrative-studio-product-nav-overview'),
      ValueKey('narrative-studio-product-nav-storylines'),
      ValueKey('narrative-studio-product-nav-scenes'),
      ValueKey('narrative-studio-product-nav-events'),
      ValueKey('narrative-studio-product-nav-cinematics'),
      ValueKey('narrative-studio-product-nav-dialogues'),
      ValueKey('narrative-studio-product-nav-facts'),
      ValueKey('narrative-studio-product-nav-worldRules'),
      ValueKey('narrative-studio-product-nav-validator'),
      ValueKey('narrative-studio-product-nav-event-builder'),
      ValueKey('narrative-studio-product-nav-map-events'),
    ]) {
      final item = find.byKey(key);
      await tester.scrollUntilVisible(
        item,
        160,
        scrollable: scrollable,
      );
      expect(item.hitTestable(), findsOneWidget, reason: '$key');
    }

    final mapEvents = find.byKey(narrativeStudioMapEventsNavigationKey);
    await tester.scrollUntilVisible(mapEvents, 160, scrollable: scrollable);
    expect(await _focusWithTab(tester, mapEvents), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(
      opened.last,
      NarrativeStudioRouteLocation.events(
        childRoute: NarrativeStudioChildRoute.mapEvents,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'workspace actions remain horizontally reachable at compact scale',
      (tester) async {
    await _pumpResponsiveShell(
      tester,
      width: 800,
      height: 650,
      textScale: 2,
      actions: [
        PokeMapButton(
          key: const ValueKey('narrative-studio-long-action-one'),
          onPressed: () {},
          size: PokeMapButtonSize.compact,
          child: const Text('Prévisualiser le projet'),
        ),
        PokeMapButton(
          key: const ValueKey('narrative-studio-long-action-two'),
          onPressed: () {},
          size: PokeMapButtonSize.compact,
          child: const Text('Valider les références'),
        ),
      ],
    );

    final scrollView = find.byKey(
      const ValueKey('narrative-studio-workspace-actions-scroll'),
    );
    expect(scrollView, findsOneWidget);
    final scrollable = find.descendant(
      of: scrollView,
      matching: find.byType(Scrollable),
    );
    expect(
      find.descendant(
        of: scrollView,
        matching: find.byKey(
          const ValueKey('narrative-studio-long-action-one'),
        ),
      ),
      findsOneWidget,
    );
    final second = find.byKey(
      const ValueKey('narrative-studio-long-action-two'),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    expect(position.maxScrollExtent, greaterThan(0));
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    expect(second.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('workspace actions remain right aligned when they fit',
      (tester) async {
    await _pumpResponsiveShell(
      tester,
      width: 1672,
      height: 941,
      textScale: 1,
      actions: [
        PokeMapButton(
          key: const ValueKey('narrative-studio-fitting-action'),
          onPressed: () {},
          size: PokeMapButtonSize.compact,
          child: const Text('Nouveau dialogue'),
        ),
      ],
    );

    final toolbar = tester.getRect(
      find.byKey(narrativeStudioWorkspaceContextKey),
    );
    final action = tester.getRect(
      find.byKey(const ValueKey('narrative-studio-fitting-action')),
    );

    expect(action.right, closeTo(toolbar.right - 16, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion removes sidebar transition', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await _pumpSidebarItem(
      tester,
      focusNode: focusNode,
      disableAnimations: true,
    );

    focusNode.requestFocus();
    await tester.pump();
    await tester.pump();
    expect(
        tester
            .widget<AnimatedContainer>(find.byType(AnimatedContainer))
            .duration,
        Duration.zero);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('high contrast strengthens the focus ring', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await _pumpSidebarItem(
      tester,
      focusNode: focusNode,
      highContrast: true,
    );
    focusNode.requestFocus();
    await tester.pump();
    await tester.pump();

    final context = tester.element(find.byType(PokeMapSidebarItem));
    var decoration = tester
        .widget<AnimatedContainer>(find.byType(AnimatedContainer))
        .decoration as BoxDecoration;
    expect(decoration.border?.top.color, context.pokeMapColors.focusRing);
    expect(decoration.border?.top.width, 2);

    await _pumpSidebarItem(tester, focusNode: focusNode);
    focusNode.requestFocus();
    await tester.pump();
    await tester.pump();
    final defaultContext = tester.element(find.byType(PokeMapSidebarItem));
    decoration = tester
        .widget<AnimatedContainer>(find.byType(AnimatedContainer))
        .decoration as BoxDecoration;
    expect(
      decoration.border?.top.color,
      defaultContext.pokeMapColors.focusRing,
    );
    expect(decoration.border?.top.width, 1.2);
  });

  testWidgets('announces selection, keeps Maps unselected and supports focus',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final opened = <NarrativeStudioDestination>[];
    var mapsOpenCount = 0;
    final semantics = tester.ensureSemantics();

    await _pumpResponsiveShell(
      tester,
      width: 1099,
      height: 941,
      textScale: 1.5,
      onSelectDestination: opened.add,
      onOpenMaps: () => mapsOpenCount += 1,
    );

    final selectedSemantics = find.descendant(
      of: find.byKey(
        const ValueKey('narrative-studio-product-nav-events'),
      ),
      matching: find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.selected == true,
      ),
    );
    final mapsSelectedSemantics = find.descendant(
      of: find.byKey(narrativeStudioProductNavigationMapsKey),
      matching: find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.selected == true,
      ),
    );
    expect(selectedSemantics, findsOneWidget);
    expect(mapsSelectedSemantics, findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('narrative-studio-disabled-action')),
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.enabled == false,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey('narrative-studio-icon-action'),
        ),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Plus d’options',
        ),
      ),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.text('Tous les changements enregistrés')).label,
      contains('Tous les changements enregistrés'),
    );

    FocusManager.instance.primaryFocus?.unfocus();
    final navigation = find.byKey(narrativeStudioProductShellNavigationKey);
    var focusIsInsideNavigation = false;
    for (var attempt = 0; attempt < 12; attempt++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      focusIsInsideNavigation = _primaryFocusIsInside(navigation);
      if (focusIsInsideNavigation) break;
    }
    expect(focusIsInsideNavigation, isTrue);
    final firstNavigationFocus = FocusManager.instance.primaryFocus;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, isNot(firstNavigationFocus));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, same(firstNavigationFocus));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(opened, isNotEmpty);

    await tester.tap(find.byKey(narrativeStudioProductNavigationMapsKey));
    await tester.pump();
    expect(mapsOpenCount, 1);
    semantics.dispose();
  });
}

Future<void> _pumpResponsiveShell(
  WidgetTester tester, {
  required double width,
  required double height,
  required double textScale,
  double devicePixelRatio = 1,
  ValueChanged<NarrativeStudioDestination>? onSelectDestination,
  ValueChanged<NarrativeStudioRouteLocation>? onSelectLocation,
  VoidCallback? onOpenMaps,
  List<Widget>? actions,
  Widget? workspace,
}) async {
  tester.view.devicePixelRatio = devicePixelRatio;
  tester.view.physicalSize = Size(
    width * devicePixelRatio,
    height * devicePixelRatio,
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: NarrativeStudioProductShell(
          selectedDestination: NarrativeStudioDestination.events,
          onSelectDestination: onSelectDestination ?? (_) {},
          onSelectLocation: onSelectLocation,
          onOpenMaps: onOpenMaps ?? () {},
          project: const PokeMapCard(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(CupertinoIcons.folder, size: 14),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selbrume Demo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          status: const Text(
            'Tous les changements enregistrés',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          workspace: workspace ??
              NarrativeStudioWorkspacePage(
                presentation: const NarrativeStudioRoutePresentation(
                  destination: NarrativeStudioDestination.events,
                  label: 'Event Builder',
                  breadcrumbLabels: ['Événements'],
                ),
                actions: actions ??
                    [
                      PokeMapIconButton(
                        key: const ValueKey('narrative-studio-icon-action'),
                        onPressed: () {},
                        tooltip: 'Plus d’options',
                        icon: const Icon(CupertinoIcons.ellipsis),
                      ),
                      const PokeMapButton(
                        key: ValueKey('narrative-studio-disabled-action'),
                        onPressed: null,
                        size: PokeMapButtonSize.compact,
                        variant: PokeMapButtonVariant.secondary,
                        child: Text('Action indisponible'),
                      ),
                    ],
                body: const Center(child: Text('Event workspace')),
              ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpSidebarItem(
  WidgetTester tester, {
  required FocusNode focusNode,
  bool disableAnimations = false,
  bool highContrast = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: disableAnimations,
          highContrast: highContrast,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: PokeMapSidebarItem(
          label: 'Événements',
          icon: const Icon(CupertinoIcons.bolt),
          focusNode: focusNode,
          onTap: () {},
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<bool> _focusWithTab(WidgetTester tester, Finder target) async {
  FocusManager.instance.primaryFocus?.unfocus();
  for (var attempt = 0; attempt < 24; attempt++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    if (_primaryFocusIsInside(target)) return true;
  }
  return false;
}

bool _primaryFocusIsInside(Finder finder) {
  final target = finder.evaluate().single;
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext == null) return false;

  var current = focusContext as Element?;
  while (current != null) {
    if (identical(current, target)) return true;
    Element? parent;
    current.visitAncestorElements((ancestor) {
      parent = ancestor;
      return false;
    });
    current = parent;
  }
  return false;
}
