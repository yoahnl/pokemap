import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_library_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'map_catalog_fixture.dart';

void main() {
  late MapCatalogFixture fixture;
  late MapWorkspaceController controller;
  late MapLibraryCommands commands;
  setUp(() async {
    fixture = await MapCatalogFixture.create();
    controller = fixture.controller;
    commands = MapLibraryCommands(controller);
  });
  tearDown(() => fixture.dispose());

  Future<void> undo() => controller.stepHistory(redo: false);
  Future<void> redo() => controller.stepHistory(redo: true);

  test('create, rename and move undo back to the exact project bytes, then redo recreates the map', () async {
    final folder = await commands.createFolder('Johto');
    final opened = controller.active!.base.mapId;
    final start = await _files(fixture.root);
    expect(controller.canStepHistory(redo: true), isFalse);

    final created = await commands.createMap(
      name: 'Route 31',
      width: 6,
      height: 5,
    );
    expect(created.ok, isTrue, reason: created.detail);
    final afterCreate = await _files(fixture.root);
    expect(
      (await commands.renameMap('route-31', 'Route trente et un')).ok,
      isTrue,
    );
    expect((await commands.moveMap('route-31', folder.groupId)).ok, isTrue);
    expect(controller.canStepHistory(redo: false), isTrue);
    expect(controller.libraryStepLeads(redo: false), isTrue);

    await undo();
    expect(_entry(controller, 'route-31')!.groupId, isNull);
    await undo();
    expect(_entry(controller, 'route-31')!.name, 'Route 31');
    expect(controller.active!.current.name, 'Route 31');
    await undo();
    expect(_entry(controller, 'route-31'), isNull);
    expect(controller.active!.base.mapId, opened);
    expect(controller.error, isNull);
    expect(await _files(fixture.root), start);

    await redo();
    expect(controller.error, isNull);
    expect(controller.active!.base.mapId, 'route-31');
    expect(_entry(controller, 'route-31')!.name, 'Route 31');
    expect(await _files(fixture.root), afterCreate);
    expect(controller.libraryStepLeads(redo: true), isTrue);
  });

  test(
    'map edits made after a library action are undone first, then the action',
    () async {
      final opened = controller.active!.base.mapId;
      await commands.createMap(name: 'Grotte', width: 5, height: 5);
      final grotte = controller.active!;
      grotte.commit(grotte.current.copyWith(properties: {'draft': true}));
      expect(controller.libraryStepLeads(redo: false), isFalse);

      await undo();
      expect(_entry(controller, 'grotte'), isNotNull);
      expect(grotte.current.properties, isEmpty);
      expect(controller.libraryStepLeads(redo: false), isTrue);

      await undo();
      expect(_entry(controller, 'grotte'), isNull);
      expect(controller.active!.base.mapId, opened);
      expect(controller.libraryStepLeads(redo: true), isTrue);
    },
  );

  test(
    'undoing a creation keeps the unsaved edits of the previous map, unsaved',
    () async {
      final previous = controller.active!;
      final previousPath = p.join(
        fixture.root.path,
        _entry(controller, previous.base.mapId)!.relativePath,
      );
      final previousBytes = await File(previousPath).readAsBytes();
      previous.commit(previous.current.copyWith(properties: {'draft': true}));
      await commands.createMap(name: 'Grotte', width: 5, height: 5);

      await undo();
      expect(_entry(controller, 'grotte'), isNull);
      expect(identical(controller.active, previous), isTrue);
      expect(previous.dirty, isTrue);
      expect(previous.current.properties, {'draft': true});
      expect(await File(previousPath).readAsBytes(), previousBytes);
    },
  );

  test('a redone rename can be undone again', () async {
    final id = controller.active!.base.mapId;
    final start = await _files(fixture.root);
    expect((await commands.renameMap(id, 'Jardin du soir')).ok, isTrue);
    await undo();
    await redo();
    expect(controller.active!.current.name, 'Jardin du soir');
    await undo();
    expect(controller.active!.error, isNull);
    expect(controller.active!.current.name, isNot('Jardin du soir'));
    expect(await _files(fixture.root), start);
  });

  test('a map saved after its rename refuses the undo in French and writes nothing', () async {
    final document = controller.active!;
    final id = document.base.mapId;
    expect((await commands.renameMap(id, 'Jardin du soir')).ok, isTrue);
    document.commit(document.current.copyWith(properties: {'draft': true}));
    expect(await controller.save(document), isTrue);
    await undo();
    expect(document.dirty, isTrue);
    final before = await _files(fixture.root);

    expect(controller.libraryStepLeads(redo: false), isTrue);
    await undo();
    expect(document.error, contains('enregistrée depuis'));
    expect(await _files(fixture.root), before);
    expect(_entry(controller, id)!.name, 'Jardin du soir');
    expect(controller.libraryStepLeads(redo: false), isFalse);
    expect(document.current.properties, isEmpty);
  });
}

ProjectMapEntry? _entry(MapWorkspaceController controller, String id) =>
    controller.project!.maps.where((map) => map.id == id).firstOrNull;

Future<Map<String, String>> _files(Directory root) async => {
  await for (final entity in root.list(recursive: true))
    if (entity is File && !entity.path.contains('${p.separator}.'))
      p.relative(entity.path, from: root.path): base64Encode(
        await entity.readAsBytes(),
      ),
};
