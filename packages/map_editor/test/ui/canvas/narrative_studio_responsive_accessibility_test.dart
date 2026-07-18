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
  testWidgets('desktop tiers and text scales render without overflow',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const widths = <double>[
      1920,
      1672,
      1480,
      1440,
      1366,
      1280,
      1100,
      1099,
    ];
    const textScales = <double>[1, 1.25, 1.5];

    for (final width in widths) {
      for (final textScale in textScales) {
        await _pumpResponsiveShell(
          tester,
          width: width,
          textScale: textScale,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'overflow at ${width}px / ${textScale * 100}%',
        );
      }
    }

    await _pumpResponsiveShell(
      tester,
      width: 1672,
      textScale: 1,
      devicePixelRatio: 2,
    );
    expect(
      tester.takeException(),
      isNull,
      reason: 'overflow at 1672px / DPR 2',
    );
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
  required double textScale,
  double devicePixelRatio = 1,
  ValueChanged<NarrativeStudioDestination>? onSelectDestination,
  VoidCallback? onOpenMaps,
}) async {
  tester.view.devicePixelRatio = devicePixelRatio;
  tester.view.physicalSize = Size(
    width * devicePixelRatio,
    941 * devicePixelRatio,
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
          workspace: NarrativeStudioWorkspacePage(
            presentation: const NarrativeStudioRoutePresentation(
              destination: NarrativeStudioDestination.events,
              label: 'Event Builder',
              breadcrumbLabels: ['Événements'],
            ),
            actions: [
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
