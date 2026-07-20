import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/l10n/app_localizations.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_command_palette.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_destination.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';

void main() {
  testWidgets('keyboard reaches every product destination and command palette',
      (tester) async {
    final openedRoutes = <NarrativeStudioRouteLocation>[];
    NarrativeGlobalSearchEntry? openedEntry;
    final workspaceFocus = FocusNode(debugLabel: 'workspace');
    addTearDown(workspaceFocus.dispose);
    await tester.pumpWidget(
      _host(
        NarrativeStudioProductShell(
          selectedDestination: NarrativeStudioDestination.events,
          selectedLocation: NarrativeStudioRouteLocation.events(),
          onSelectDestination: (_) {},
          onSelectLocation: openedRoutes.add,
          onOpenMaps: () {},
          globalSearchIndex: _index,
          onOpenSearchEntry: (entry) => openedEntry = entry,
          commandPaletteActions: const [],
          workspace: Focus(
            focusNode: workspaceFocus,
            autofocus: true,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pump();

    const navigationKeys = <ValueKey<String>>[
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
    ];
    for (final key in navigationKeys) {
      final target = find.byKey(key);
      expect(target, findsOneWidget, reason: '$key');
      expect(await _focusWithTab(tester, target), isTrue, reason: '$key');
    }

    workspaceFocus.requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byKey(narrativeCommandPaletteKey), findsOneWidget);

    await tester.enterText(
      find.byKey(narrativeCommandPaletteSearchKey),
      'harbor scene',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(openedEntry?.technicalId, 'scene.harbor');
    expect(find.byKey(narrativeCommandPaletteKey), findsNothing);
    expect(workspaceFocus.hasFocus, isTrue);
  });
}

final _index = NarrativeGlobalSearchIndex.fromEntries(
  revision: 1,
  entries: const [
    NarrativeGlobalSearchEntry(
      kind: NarrativeGlobalSearchKind.scene,
      technicalId: 'scene.harbor',
      label: 'Harbor scene',
    ),
  ],
);

Widget _host(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: SizedBox(width: 1280, height: 941, child: child),
      ),
    );

Future<bool> _focusWithTab(WidgetTester tester, Finder target) async {
  FocusManager.instance.primaryFocus?.unfocus();
  for (var attempt = 0; attempt < 32; attempt++) {
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
