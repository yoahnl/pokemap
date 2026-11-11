import 'dart:convert';

import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/resources/application/resource_usage_controller.dart';
import 'package:avelune_studio/features/resources/application/resource_usage_replacement_controller.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/coordination/resource_replacement_workflow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/resource_owner_seed.dart';
import '../support/resource_owner_host.dart';

Future<ResourceOwnerHost> _open() => ResourceOwnerHost.create(
  configure: (fixture) async {
    await seedFreeDecor(fixture, placed: true);
    final project = await fixture.maps.loadProject(fixture.session);
    final tree = project.elements.singleWhere((e) => e.id == 'tree');
    await fixture.resources.saveElement(
      tree.copyWith(id: 'bush', name: 'Buisson'),
    );
    final document = await fixture.loadMap();
    await fixture.maps.saveMap(
      fixture.session,
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

Future<String?> _replace(
  ResourceOwnerHost host,
  Future<void> Function(ResourceUsageReplacementController) present,
) {
  final tree = decorItem(host.workspace.project!);
  return runResourceUsageReplacement(
    navigation: host.navigation,
    target: resourceUsageTargetFor(tree),
    name: tree.name,
    isActive: () => true,
    present: present,
  );
}

Future<void> _choose(ResourceUsageReplacementController controller) async {
  final bush = controller.choices.singleWhere((item) => item.id == 'bush');
  await controller.choose(bush);
  await controller.settle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('replacing every usage reviews its scope, repoints each placement and keeps definitions', () async {
    final host = await _open();
    final before = await host.reopen();
    final mapBefore = await host.fixture.mapFile.readAsBytes();
    final document = host.workspace.active!;
    expect(document.current.placedElements.map((e) => e.elementId), [
      'tree',
      'tree',
    ]);
    final notice = await _replace(host, (controller) async {
      expect(controller.choices.map((item) => item.id), ['bush']);
      expect(controller.canApply, isFalse);
      expect(await controller.apply(), isNotNull);
      await _choose(controller);
      expect(controller.summary, '2 occurrences sur 1 carte');
      expect(controller.scope, [(mapId: 'garden', count: 2)]);
      expect(controller.canApply, isFalse);
      expect(await host.fixture.mapFile.readAsBytes(), mapBefore);
      controller.confirm(true);
      expect(controller.canApply, isTrue);
      expect(await controller.apply(), isNull);
      expect(controller.canApply, isFalse);
    });
    expect(notice, contains('Usages remplacés'));
    expect(notice, contains('Buisson'));
    final saved = MapData.fromJson(
      jsonDecode(utf8.decode(await host.fixture.mapFile.readAsBytes()))
          as Map<String, dynamic>,
    );
    expect(saved.placedElements.map((e) => e.elementId), ['bush', 'bush']);
    expect(saved.placedElements.first.pos, const GridPos(x: 1, y: 1));
    expect(saved.placedElements.map((e) => e.id), [
      'placed-tree',
      'placed-tree-2',
    ]);
    expect((await host.reopen()).elements, before.elements);
    expect(host.workspace.documents[saved.id], same(document));
    expect(document.current.placedElements.map((e) => e.elementId), [
      'bush',
      'bush',
    ]);
    expect(document.current.placedElements.map((e) => e.id), [
      'placed-tree',
      'placed-tree-2',
    ]);
    expect(document.dirty, isFalse);
    final placement = MapEditingCommands(document, host.workspace.project!).place(
      host.workspace.project!.elements.first,
      const GridPos(x: 0, y: 0),
    );
    expect(placement, isNotNull);
    expect(document.dirty, isTrue);
    expect(await host.workspace.save(document), isTrue);
    expect(document.dirty, isFalse);
  });

  test('cancelling the reviewed replacement writes nothing', () async {
    final host = await _open();
    final mapBefore = await host.fixture.mapFile.readAsBytes();
    final notice = await _replace(host, (controller) async {
      await _choose(controller);
      controller.confirm(true);
    });
    expect(notice, isNull);
    expect(await host.fixture.mapFile.readAsBytes(), mapBefore);
    expect(host.navigation.managementDialogActive, isFalse);
  });

  test('an unsaved map draft keeps the replacement unavailable', () async {
    final host = await _open();
    final mapBefore = await host.fixture.mapFile.readAsBytes();
    final document = host.workspace.active!;
    MapEditingCommands(document, host.workspace.project!).place(
      host.workspace.project!.elements.first,
      const GridPos(x: 0, y: 0),
    );
    expect(document.dirty, isTrue);
    await _replace(host, (controller) async {
      await _choose(controller);
      expect(controller.preparation, isNull);
      expect(controller.error, contains('Enregistrez ou annulez les brouillons'));
      controller.confirm(true);
      expect(controller.canApply, isFalse);
      expect(await controller.apply(), isNotNull);
    });
    expect(await host.fixture.mapFile.readAsBytes(), mapBefore);
    expect(document.dirty, isTrue);
  });
}
