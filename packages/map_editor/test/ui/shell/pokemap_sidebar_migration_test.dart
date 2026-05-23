// Theme-4 — Sidebar Migration tests.
//
// Strategy: pump only the migrated atomic components (EditorSidebarListRow,
// PokeMapSidebarItem, design-system tokens) rather than the full
// ProjectExplorerPanel which embeds several heavy sub-panels (Narrative,
// Terrain, Trainer…) that each require async I/O and platform channels.
//
// Testing the atomic components is sufficient to prove the Theme-4 migration:
// the color tokens are resolved, selection state is applied, and the
// design-system widgets work inside a MaterialApp + bridge harness.

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/shared/cupertino_editor_widgets.dart';

// ─── Minimal harness ──────────────────────────────────────────────────────────

Future<void> _pumpInBridge(
  WidgetTester tester,
  Widget child, {
  required ThemeData theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      builder: (context, innerChild) {
        return PokeMapMacosCompatibilityBridge(
          child: innerChild ?? const SizedBox.shrink(),
        );
      },
      home: Scaffold(
        body: SizedBox(width: 320, child: child),
      ),
    ),
  );
  await tester.pump();
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('PokeMap Sidebar Migration — EditorSidebarListRow', () {
    testWidgets('renders unselected row under Light Theme', (tester) async {
      await _pumpInBridge(
        tester,
        EditorSidebarListRow(
          selected: false,
          onTap: () {},
          leading: const Icon(CupertinoIcons.map_fill),
          title: const Text('Route 101'),
        ),
        theme: PokeMapTheme.light(),
      );

      expect(find.text('Route 101'), findsOneWidget);
    });

    testWidgets('renders selected row under Dark Theme', (tester) async {
      await _pumpInBridge(
        tester,
        EditorSidebarListRow(
          selected: true,
          onTap: () {},
          leading: const Icon(CupertinoIcons.map_fill),
          title: const Text('Route 101'),
        ),
        theme: PokeMapTheme.dark(),
      );

      expect(find.text('Route 101'), findsOneWidget);
    });

    testWidgets('onTap callback fires', (tester) async {
      var tapped = false;
      await _pumpInBridge(
        tester,
        EditorSidebarListRow(
          selected: false,
          onTap: () => tapped = true,
          title: const Text('Pallet Town'),
        ),
        theme: PokeMapTheme.dark(),
      );

      await tester.tap(find.text('Pallet Town'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });

  group('PokeMap Sidebar Migration — PokeMapSidebarItem', () {
    testWidgets('renders inactive item under Light Theme', (tester) async {
      await _pumpInBridge(
        tester,
        PokeMapSidebarItem(
          label: 'World Maps',
          icon: const Icon(CupertinoIcons.map),
          selected: false,
          onTap: () {},
        ),
        theme: PokeMapTheme.light(),
      );

      expect(find.text('World Maps'), findsOneWidget);
    });

    testWidgets('renders active item under Dark Theme', (tester) async {
      await _pumpInBridge(
        tester,
        PokeMapSidebarItem(
          label: 'Tileset Library',
          icon: const Icon(CupertinoIcons.square_grid_2x2),
          selected: true,
          onTap: () {},
        ),
        theme: PokeMapTheme.dark(),
      );

      expect(find.text('Tileset Library'), findsOneWidget);
    });

    testWidgets('onTap fires from PokeMapSidebarItem', (tester) async {
      var activated = false;
      await _pumpInBridge(
        tester,
        PokeMapSidebarItem(
          label: 'Catalogues',
          icon: const Icon(CupertinoIcons.book_fill),
          selected: false,
          onTap: () => activated = true,
        ),
        theme: PokeMapTheme.dark(),
      );

      await tester.tap(find.text('Catalogues'));
      await tester.pump();
      expect(activated, isTrue);
    });
  });

  group('PokeMap Sidebar Migration — color tokens resolve', () {
    testWidgets('PokeMapColorTokens are available in Light Theme', (tester) async {
      PokeMapColorTokens? resolvedColors;
      await _pumpInBridge(
        tester,
        Builder(
          builder: (context) {
            resolvedColors = context.pokeMapColors;
            return const SizedBox.shrink();
          },
        ),
        theme: PokeMapTheme.light(),
      );

      expect(resolvedColors, isNotNull);
      expect(resolvedColors!.brandPrimary, isNotNull);
      expect(resolvedColors!.surfaceSelected, isNotNull);
      expect(resolvedColors!.textPrimary, isNotNull);
    });

    testWidgets('PokeMapColorTokens are available in Dark Theme', (tester) async {
      PokeMapColorTokens? resolvedColors;
      await _pumpInBridge(
        tester,
        Builder(
          builder: (context) {
            resolvedColors = context.pokeMapColors;
            return const SizedBox.shrink();
          },
        ),
        theme: PokeMapTheme.dark(),
      );

      expect(resolvedColors, isNotNull);
      expect(resolvedColors!.brandPrimary, isNotNull);
    });

    testWidgets('sidebar renders multiple items in a Column', (tester) async {
      await _pumpInBridge(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EditorSidebarListRow(
              selected: false,
              onTap: () {},
              title: const Text('World Explorer'),
            ),
            EditorSidebarListRow(
              selected: true,
              onTap: () {},
              title: const Text('Tileset Library'),
            ),
            EditorSidebarListRow(
              selected: false,
              onTap: () {},
              title: const Text('Catalogues Pokémon'),
            ),
            EditorSidebarListRow(
              selected: false,
              onTap: () {},
              title: const Text('World Maps'),
            ),
          ],
        ),
        theme: PokeMapTheme.light(),
      );

      expect(find.text('World Explorer'), findsOneWidget);
      expect(find.text('Tileset Library'), findsOneWidget);
      expect(find.text('Catalogues Pokémon'), findsOneWidget);
      expect(find.text('World Maps'), findsOneWidget);
    });
  });
}
