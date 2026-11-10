import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_commands.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_tool_strip.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/platform/input/editor_shortcuts.dart';
import 'package:avelune_studio/presentation/shared/text/studio_help_families.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/dialogs/studio_command_palette.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  theme: studioTheme(),
  home: Scaffold(body: child),
);

class _PaletteHost extends StatefulWidget {
  const _PaletteHost({required this.entries});
  final List<StudioCommandEntry> entries;
  @override
  State<_PaletteHost> createState() => _PaletteHostState();
}

class _PaletteHostState extends State<_PaletteHost> {
  String? result = 'unset';
  final trigger = FocusNode();
  @override
  void dispose() {
    trigger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      focusNode: trigger,
      onPressed: () async {
        final chosen = await showStudioCommandPalette(
          context,
          entries: widget.entries,
        );
        setState(() => result = chosen);
      },
      child: const Text('Commandes'),
    ),
  );
}

void main() {
  test('searching falaise proposes the border command and its help', () {
    final entries = mapCommandPaletteEntries(
      const MapCommandContext(spatial: true),
    );
    final found = studioCommandSearch(entries, 'falaise');
    expect(found.first.id, 'map.border');
    expect(found.first.runnable, isTrue);
    final command = found.singleWhere((entry) => entry.label == 'Bordures');
    expect(command.help, contains('modèle de bordure'));
    expect(studioCommandSearch(entries, 'FORET').first.id, 'map.environment');
    expect(studioCommandSearch(entries, 'porte').first.id, 'map.warps');
  });

  test('the bar, the menus and the palette share one availability rule', () {
    const spatial = MapCommandContext(spatial: true);
    const exterior = MapCommandContext(exterior: true);
    expect(mapCommandUnavailable('map.zones', spatial), isNotNull);
    expect(mapCommandUnavailable('map.sign', spatial), isNotNull);
    expect(mapCommandUnavailable('map.border', spatial), isNull);
    expect(mapCommandUnavailable('map.collisions', exterior), isNotNull);
    expect(mapCommandUnavailable('map.decor', exterior), isNull);
    expect(
      mapCommandUnavailable('map.undo', const MapCommandContext()),
      isNotNull,
    );
    expect(
      mapCommandUnavailable('map.undo', const MapCommandContext(canUndo: true)),
      isNull,
    );
    final palette = {
      for (final entry in mapCommandPaletteEntries(spatial)) entry.id: entry,
    };
    expect(palette['map.zones']!.runnable, isFalse);
    expect(palette['map.zones']!.unavailable, contains('3D'));
  });

  testWidgets('a 3D tool strip disables what the palette reports unavailable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final view = MapWorkspaceViewState();
    await tester.pumpWidget(
      _app(
        MapWorkspaceToolStrip(
          view: view,
          spatial: true,
          onChanged: () {},
          onMoreTools: () {},
          onResources: () {},
          storyAvailable: true,
          paletteVisible: true,
          onUndo: null,
          onRedo: null,
        ),
      ),
    );
    StudioButton button(String label) =>
        tester.widget<StudioButton>(find.widgetWithText(StudioButton, label));
    expect(button('Zones').onPressed, isNull);
    expect(button('Bordures').onPressed, isNotNull);
    expect(
      find.byTooltip(
        'Cet outil n’est pas encore disponible sur les cartes 3D.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Peupler la carte'));
    await tester.pumpAndSettle();
    final sign = tester.widget<PopupMenuItem<String>>(
      find.widgetWithText(
        PopupMenuItem<String>,
        'Placer un panneau · indisponible en 3D',
      ),
    );
    expect(sign.enabled, isFalse);
    final character = tester.widget<PopupMenuItem<String>>(
      find.widgetWithText(PopupMenuItem<String>, 'Placer un personnage'),
    );
    expect(character.enabled, isTrue);
  });

  testWidgets(
    'keyboard browses, Enter runs and an unavailable entry stays inert',
    (tester) async {
      await tester.pumpWidget(
        _app(
          _PaletteHost(
            entries: mapCommandPaletteEntries(
              const MapCommandContext(spatial: true),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Commandes'));
      await tester.pumpAndSettle();
      expect(find.byType(StudioCommandPalette), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('command-palette-search')),
        'zones',
      );
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('command-palette-help')),
          matching: find.textContaining(
            'pas encore disponible sur les cartes 3D',
          ),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('command-palette-run')),
            )
            .onPressed,
        isNull,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(StudioCommandPalette), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('command-palette-search')),
        'cs',
      );
      await tester.pump();
      final firstLabel = studioCommandSearch(
        mapCommandPaletteEntries(const MapCommandContext(spatial: true)),
        'cs',
      );
      expect(firstLabel.length, greaterThan(1));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('command-palette-help')),
          matching: find.text(firstLabel[1].label),
        ),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('command-palette-search')),
        'falaise',
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(StudioCommandPalette), findsNothing);
      expect(
        tester.state<_PaletteHostState>(find.byType(_PaletteHost)).result,
        'map.border',
      );
    },
  );

  testWidgets('Escape closes without running and gives focus back', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _PaletteHost(
          entries: mapCommandPaletteEntries(const MapCommandContext()),
        ),
      ),
    );
    final host = tester.state<_PaletteHostState>(find.byType(_PaletteHost));
    host.trigger.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(StudioCommandPalette), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('command-palette-search')),
      'scene',
    );
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('command-palette-help')),
        matching: find.text('Définition'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('command-palette-run')), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(StudioCommandPalette), findsNothing);
    expect(host.result, isNull);
    expect(host.trigger.hasFocus, isTrue);
  });

  testWidgets('delete and Cmd+K do nothing while a text field is edited', (
    tester,
  ) async {
    var deleted = 0, opened = 0;
    final field = FocusNode();
    final outer = FocusNode();
    addTearDown(field.dispose);
    addTearDown(outer.dispose);
    await tester.pumpWidget(
      _app(
        CallbackShortcuts(
          bindings: textAwareEditorShortcuts({
            const SingleActivator(LogicalKeyboardKey.delete): () => deleted++,
            const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
                opened++,
          }),
          child: Focus(
            focusNode: outer,
            child: TextField(focusNode: field),
          ),
        ),
      ),
    );
    field.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();
    expect(deleted, 0);
    expect(opened, 0);
    outer.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();
    expect(deleted, 1);
  });

  test('the 55 help families are searchable and run their map command', () {
    expect(studioHelpFamilies, hasLength(55));
    expect(
      studioHelpFamilies.map((family) => family.number).toSet(),
      hasLength(55),
    );
    final entries = mapCommandPaletteEntries(
      const MapCommandContext(spatial: true),
    );
    final help = entries.where((entry) => entry.group == 'Comment faire');
    expect(help, hasLength(55));
    final talus = studioCommandSearch(
      entries,
      'talus',
    ).firstWhere((entry) => entry.group == 'Comment faire');
    expect(talus.label, startsWith('08 ·'));
    final cliff = help.singleWhere((entry) => entry.label.startsWith('06 ·'));
    expect(cliff.id, 'map.border');
    expect(cliff.runnable, isTrue);
    final zone = help.singleWhere((entry) => entry.label.startsWith('22 ·'));
    expect(zone.runnable, isFalse);
    expect(zone.unavailable, contains('3D'));
    final camera = help.singleWhere((entry) => entry.label.startsWith('19 ·'));
    expect(camera.executable, isFalse);
    expect(camera.help, contains('Réglages du projet'));
  });
}
