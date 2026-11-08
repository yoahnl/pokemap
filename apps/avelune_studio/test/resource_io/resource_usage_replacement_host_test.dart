import 'dart:convert';

import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/m2_ui_fixture.dart';
import '../support/uwu4_resource_host.dart';
import '../support/uwu_resource_host.dart';
import 'resource_fixture.dart';

void main() {
  testWidgets(
    'replacing every usage reviews its scope, repoints each placement and keeps definitions',
    (tester) async {
      late ResourceFixture resources;
      final host = await _open(tester, (fixture) => resources = fixture);
      final before = await host.reopen();
      final mapBefore = await tester.runAsync(resources.mapFile.readAsBytes);
      await _openReplacement(host);
      expect(
        find.text('Choisissez la ressource de remplacement.'),
        findsOneWidget,
      );
      expect(_submit(tester).onPressed, isNull);
      await host.tap('resource-usage-replacement-bush');
      await _settle(host);
      expect(find.text('Portée : 2 occurrences sur 1 carte'), findsOneWidget);
      expect(find.textContaining('· 2 occurrences'), findsOneWidget);
      expect(find.textContaining('« Remplacer ici »'), findsOneWidget);
      expect(find.textContaining('« Modifier la définition »'), findsOneWidget);
      expect(_submit(tester).onPressed, isNull);
      expect(await tester.runAsync(resources.mapFile.readAsBytes), mapBefore);
      await host.tap('resource-usage-replacement-confirm');
      await host.tap('resource-management-save');
      await _settle(host);
      expect(
        find.byKey(const ValueKey('resource-management-error')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('resource-usage-replacement-notice')),
        findsOneWidget,
      );
      final saved = MapData.fromJson(
        jsonDecode(
          utf8.decode((await tester.runAsync(resources.mapFile.readAsBytes))!),
        ) as Map<String, dynamic>,
      );
      expect(saved.placedElements.map((e) => e.elementId), ['bush', 'bush']);
      expect(saved.placedElements.first.pos, const GridPos(x: 1, y: 1));
      final after = await host.reopen();
      expect(after.elements, before.elements);
      final document = host.fixture.controller.documents[saved.id]!;
      expect(document.current.placedElements.map((e) => e.elementId), [
        'bush',
        'bush',
      ]);
      expect(document.dirty, isFalse);
      MapEditingCommands(document, host.fixture.controller.project!).place(
        host.fixture.controller.project!.elements.first,
        const GridPos(x: 0, y: 0),
      );
      final saving = host.fixture.controller.save(document);
      await _settle(host);
      expect(await saving, isTrue);
      expect(document.dirty, isFalse);
    },
  );

  testWidgets('cancelling the reviewed replacement writes nothing', (
    tester,
  ) async {
    late ResourceFixture resources;
    final host = await _open(tester, (fixture) => resources = fixture);
    final mapBefore = await tester.runAsync(resources.mapFile.readAsBytes);
    await _openReplacement(host);
    await host.tap('resource-usage-replacement-bush');
    await _settle(host);
    await host.tap('resource-usage-replacement-confirm');
    await host.tap('resource-management-cancel');
    expect(await tester.runAsync(resources.mapFile.readAsBytes), mapBefore);
    expect(
      find.byKey(const ValueKey('resource-usage-replacement-notice')),
      findsNothing,
    );
  });

  testWidgets('an unsaved map draft keeps the replacement unavailable', (
    tester,
  ) async {
    late ResourceFixture resources;
    final host = await _open(tester, (fixture) => resources = fixture);
    final mapBefore = await tester.runAsync(resources.mapFile.readAsBytes);
    final document = host.fixture.controller.active!;
    MapEditingCommands(document, host.fixture.controller.project!).place(
      host.fixture.controller.project!.elements.first,
      const GridPos(x: 0, y: 0),
    );
    expect(document.dirty, isTrue);
    await host.action('element:tree', 'Voir les usages dans le projet');
    await host.tap('resource-usage-analyze');
    expect(find.text('Analyse incomplète'), findsOneWidget);
    expect(
      tester
          .widget<StudioButton>(
            find.byKey(const ValueKey('resource-usage-replace')),
          )
          .onPressed,
      isNull,
    );
    expect(await tester.runAsync(resources.mapFile.readAsBytes), mapBefore);
  });
}

Future<UwUResourceHost> _open(
  WidgetTester tester,
  void Function(ResourceFixture) capture,
) => openUwU4ResourceHost(
  tester,
  placed: true,
  configure: (resources) async {
    capture(resources);
    final project = await resources.maps.loadProject(resources.session);
    final tree = project.elements.singleWhere((e) => e.id == 'tree');
    await resources.resources.saveElement(
      tree.copyWith(id: 'bush', name: 'Buisson'),
    );
    final document = await resources.loadMap();
    await resources.maps.saveMap(
      resources.session,
      document,
      document.map.copyWith(
        placedElements: [
          ...document.map.placedElements,
          const MapPlacedElement(
            id: 'placed-tree-2',
            layerId: 'ground',
            elementId: 'tree',
            pos: GridPos(x: 2, y: 2),
          ),
        ],
      ),
    );
  },
);

Future<void> _openReplacement(UwUResourceHost host) async {
  await host.action('element:tree', 'Voir les usages dans le projet');
  await host.tap('resource-usage-analyze');
  expect(find.text('Complet pour la révision identifiée'), findsOneWidget);
  await host.tap('resource-usage-replace');
  expect(find.text('Remplacer ses usages'), findsWidgets);
}

Future<void> _settle(UwUResourceHost host) async {
  for (var round = 0; round < 10; round++) {
    await pumpIo(host.tester, frames: 10);
  }
}

StudioButton _submit(WidgetTester tester) => tester.widget<StudioButton>(
  find.byKey(const ValueKey('resource-management-save')),
);
