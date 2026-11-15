import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_builder_map_library_harness.dart';
import 'map_builder_selection_harness.dart';

Finder _map(String id) => find.byKey(ValueKey('map-library-map-$id'));

EditableText _renameField(WidgetTester tester) => tester.widget(
  find.descendant(
    of: find.byKey(const ValueKey('map-library-rename-field')),
    matching: find.byType(EditableText),
  ),
);

Future<SelectionHost> _openTree(
  WidgetTester tester, {
  ProjectManifest? manifest,
}) async {
  final project = manifest ?? selectionProject();
  final host = await openSelectionHost(
    tester,
    catalog: MemoryMapCatalogPort(project),
    manifest: project,
  );
  await tester.tap(find.byKey(const ValueKey('map-library-tab-Cartes')));
  await host.settle();
  return host;
}

Future<void> _doubleClick(WidgetTester tester, Finder row) async {
  await tester.tap(row);
  await tester.pump(const Duration(milliseconds: 60));
  await tester.tap(row);
}

Future<void> _mouseClick(WidgetTester tester, Finder row, Duration at) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.down(tester.getCenter(row), timeStamp: at);
  await gesture.up(timeStamp: at + const Duration(milliseconds: 40));
  await gesture.removePointer();
}

ProjectManifest _foldered() {
  final project = selectionProject();
  return project.copyWith(
    groups: const [
      ProjectMapGroup(id: 'johto', name: 'Johto', type: MapGroupType.route),
      ProjectMapGroup(
        id: 'routes',
        name: 'Routes',
        type: MapGroupType.route,
        parentGroupId: 'johto',
      ),
    ],
    maps: [
      for (final map in project.maps)
        map.id == 'b' ? map.copyWith(groupId: 'routes') : map,
    ],
  );
}

void main() {
  testWidgets(
    'a double click stays a double click when opening the map stalls the UI',
    (tester) async {
      final host = await _openTree(tester);
      await tester.tap(_map('b'));
      await host.settle();
      await tester.tap(_map('a'));
      await host.settle();
      const first = Duration(seconds: 10);

      await _mouseClick(tester, _map('b'), first);
      sleep(const Duration(milliseconds: 400));
      await _mouseClick(
        tester,
        _map('b'),
        first + const Duration(milliseconds: 160),
      );
      await host.settle();
      await tester.pump(const Duration(milliseconds: 500));
      await host.settle();

      expect(host.maps.active!.base.mapId, 'b');
      expect(_renameField(tester).focusNode.hasFocus, isTrue);
    },
  );

  testWidgets('two slow clicks on a map row never start a rename', (
    tester,
  ) async {
    final host = await _openTree(tester);
    const first = Duration(seconds: 10);

    await _mouseClick(tester, _map('b'), first);
    await host.settle();
    await _mouseClick(tester, _map('b'), first + const Duration(seconds: 1));
    await host.settle();

    expect(host.maps.active!.base.mapId, 'b');
    expect(
      find.byKey(const ValueKey('map-library-rename-field')),
      findsNothing,
    );
  });

  testWidgets('Escape clears the map search, a second Escape leaves it', (
    tester,
  ) async {
    final host = await _openTree(tester);
    final search = find.byKey(const ValueKey('map-library-search'));
    final field = find.descendant(
      of: search,
      matching: find.byType(EditableText),
    );
    await tester.enterText(search, 'jardin');
    await host.settle();
    expect(_map('a'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await host.settle();
    expect(tester.widget<EditableText>(field).controller.text, isEmpty);
    expect(tester.widget<EditableText>(field).focusNode.hasFocus, isTrue);
    expect(_map('a'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await host.settle();
    expect(tester.widget<EditableText>(field).focusNode.hasFocus, isFalse);
    expect(host.maps.active!.base.mapId, 'a');
  });

  testWidgets('opened folders stay open after visiting another space', (
    tester,
  ) async {
    final host = await _openTree(tester, manifest: _foldered());
    await tester.tap(find.byKey(const ValueKey('map-library-folder-johto')));
    await host.settle();
    await tester.tap(find.byKey(const ValueKey('map-library-folder-routes')));
    await host.settle();
    expect(_map('b'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('map-space-gameplay')));
    await host.settle();
    await tester.tap(find.byKey(const ValueKey('map-space-construction')));
    await host.settle();
    await tester.tap(find.byKey(const ValueKey('map-library-tab-Cartes')));
    await host.settle();

    expect(_map('b'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('map-library-tab-Ressources')));
    await host.settle();
    await tester.tap(find.byKey(const ValueKey('map-library-tab-Cartes')));
    await host.settle();
    expect(_map('b'), findsOneWidget);
  });

  testWidgets(
    'a double click on an already loaded map keeps the rename field focused',
    (tester) async {
      final host = await _openTree(tester);
      await tester.tap(_map('b'));
      await host.settle();
      await tester.tap(_map('a'));
      await host.settle();
      expect(host.maps.active!.base.mapId, 'a');

      await _doubleClick(tester, _map('b'));
      await host.settle();
      await tester.pump(const Duration(milliseconds: 500));
      await host.settle();

      expect(host.maps.active!.base.mapId, 'b');
      expect(_renameField(tester).focusNode.hasFocus, isTrue);
    },
  );

  testWidgets(
    'a double click on a map still loading focuses the field once it opens',
    (tester) async {
      final host = await _openTree(tester);
      final gate = host.port.loadGate = Completer<void>();

      await _doubleClick(tester, _map('b'));
      await host.settle();
      gate.complete();
      await host.settle();
      await tester.pump(const Duration(milliseconds: 500));
      await host.settle();

      expect(host.maps.active!.base.mapId, 'b');
      expect(_renameField(tester).focusNode.hasFocus, isTrue);
    },
  );

  testWidgets('a library failure notice disappears when another map opens', (
    tester,
  ) async {
    final host = await _openTree(tester);
    await _doubleClick(tester, _map('a'));
    await host.settle();
    tester.testTextInput.updateEditingValue(const TextEditingValue(text: ' '));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await host.settle();
    expect(find.byKey(const ValueKey('map-library-notice')), findsOneWidget);

    await tester.tap(_map('b'));
    await host.settle();

    expect(host.maps.active!.base.mapId, 'b');
    expect(find.byKey(const ValueKey('map-library-notice')), findsNothing);
  });
}
