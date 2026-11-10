import 'package:avelune_studio/features/commands/application/studio_command_entry.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_commands.dart';
import 'package:avelune_studio/platform/input/editor_shortcuts.dart';
import 'package:avelune_studio/features/help/application/studio_help_families.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  theme: studioTheme(),
  home: Scaffold(body: child),
);

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
