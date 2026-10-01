import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'map_catalog_fixture.dart';

void main() {
  late MapCatalogFixture fixture;
  setUp(() async {
    fixture = await MapCatalogFixture.create();
  });
  tearDown(() => fixture.dispose());

  test('undo refuses an old passage to a canonically removed map', () async {
    expect(
      (await fixture.createMap('obsolete-destination')).integrated,
      isTrue,
    );
    final document = fixture.controller.active!;
    final before = document.current;
    document.commit(
      before.copyWith(
        warps: [
          const MapWarp(
            id: 'historic-warp',
            pos: GridPos(x: 2, y: 2),
            targetMapId: 'obsolete-destination',
            targetPos: GridPos(x: 1, y: 1),
          ),
        ],
      ),
    );
    document.commit(before);
    expect(document.dirty, isFalse);
    final removed = await fixture.controller.mutateCatalog('map.delete_apply', {
      'mapId': 'obsolete-destination',
    }, confirmDestructive: true);
    expect(removed.integrated, isTrue, reason: removed.error);
    fixture.controller.restore(redo: false);
    expect(document.current.warps, isEmpty);
    expect(document.canUndo, isTrue);
    expect(document.error, contains('destination supprimée'));
  });

  test(
    'creation integrates the manifest and permits immediate editing and saving',
    () async {
      final before = fixture.controller.active!;
      final result = await fixture.createMap('third');
      expect(result.integrated, isTrue, reason: result.error);
      expect(result.receipt!.changedPaths.toSet(), {
        'project.json',
        'maps/third.json',
      });
      expect(fixture.controller.active, same(before));
      final entry = fixture.controller.project!.maps.last;
      await fixture.controller.activate(entry);
      final document = fixture.controller.active!;
      MapEntityEditingCommands(
        document,
        fixture.controller.project!,
      ).place(MapEntityKind.spawn, const GridPos(x: 3, y: 2));
      expect(await fixture.controller.save(document), isTrue);
      final reopened = MapWorkspaceController(
        fixture.session,
        LocalMapWorkspaceAdapter(),
      );
      addTearDown(reopened.dispose);
      await reopened.initialize();
      await reopened.activate(reopened.project!.maps.last);
      expect(
        reopened.active!.current.entities.single.pos,
        const GridPos(x: 3, y: 2),
      );
    },
  );

  test(
    'title mutation preserves identity, dirty neighbour and prior geometry history',
    () async {
      final controller = fixture.controller;
      final target = controller.active!;
      final originalPath = controller.project!.maps.first.relativePath;
      final entity = target.current.entities.first;
      MapEntityEditingCommands(
        target,
        controller.project!,
      ).move(entity.id, const GridPos(x: 3, y: 3));
      expect(await controller.save(target), isTrue);
      await controller.activate(controller.project!.maps.last);
      final neighbour = controller.active!;
      neighbour.commit(
        neighbour.current.copyWith(properties: {'brouillon': true}),
      );
      final neighbourMap = neighbour.current;
      final result = await controller.mutateCatalog('map.update_metadata', {
        'mapId': target.base.mapId,
        'name': 'Étang des essais',
      });
      expect(result.integrated, isTrue, reason: result.error);
      expect(controller.project!.maps.first.relativePath, originalPath);
      expect(target.current.id, 'jardin');
      expect(target.current.name, 'Étang des essais');
      expect(neighbour.current, same(neighbourMap));
      expect(neighbour.dirty, isTrue);
      await controller.activate(controller.project!.maps.first);
      controller.restore(redo: false);
      expect(target.current.name, 'Étang des essais');
      expect(target.current.entities.first.pos, entity.pos);
      controller.restore(redo: true);
      expect(target.current.name, 'Étang des essais');
      expect(target.current.entities.first.pos, const GridPos(x: 3, y: 3));
      expect(await controller.save(target), isTrue);
      final disk = MapData.fromJson(
        jsonDecode(
          await File(p.join(fixture.root.path, originalPath)).readAsString(),
        ),
      );
      expect(disk.name, controller.project!.maps.first.name);
    },
  );

  test('dirty target is refused without publishing other drafts', () async {
    final document = fixture.controller.active!;
    document.commit(document.current.copyWith(properties: {'dirty': true}));
    final bytes = await File(
      p.join(fixture.root.path, 'project.json'),
    ).readAsBytes();
    final result = await fixture.controller.mutateCatalog(
      'map.update_metadata',
      {'mapId': 'jardin', 'name': 'Refus'},
    );
    expect(result.published, isFalse);
    expect(fixture.catalog.mutations, 0);
    expect(document.dirty, isTrue);
    expect(
      await File(p.join(fixture.root.path, 'project.json')).readAsBytes(),
      bytes,
    );
  });

  test('same normalized title performs no publication', () async {
    final document = fixture.controller.active!;
    final bytes = await File(
      p.join(fixture.root.path, 'project.json'),
    ).readAsBytes();
    final revision = document.base.revision;
    final result = await fixture.controller.mutateCatalog(
      'map.update_metadata',
      {'mapId': 'jardin', 'name': '  ${document.current.name}  '},
    );
    expect(result.integrated, isTrue, reason: result.error);
    expect(result.published, isFalse);
    expect(document.base.revision, revision);
    expect(
      await File(p.join(fixture.root.path, 'project.json')).readAsBytes(),
      bytes,
    );
  });

  test(
    'canonical removal retires loaded maps and refuses stale saves',
    () async {
      await fixture.controller.activate(fixture.controller.project!.maps.last);
      final removed = fixture.controller.active!;
      final staleEntry = fixture.controller.project!.maps.last;
      final result = await fixture.controller.mutateCatalog(
        'map.delete_apply',
        {'mapId': staleEntry.id},
        confirmDestructive: true,
      );
      expect(result.integrated, isTrue, reason: result.error);
      expect(fixture.controller.active, isNull);
      expect(fixture.controller.documents.containsKey(staleEntry.id), isFalse);
      await fixture.controller.activate(staleEntry);
      removed.commit(removed.current.copyWith(properties: {'stale': true}));
      expect(await fixture.controller.save(removed), isFalse);
      expect(await fixture.controller.previewMap(staleEntry.id), isNull);
      expect(
        await File(p.join(fixture.root.path, staleEntry.relativePath)).exists(),
        isFalse,
      );
    },
  );

  test('an externally changed target refuses title publication', () async {
    final document = fixture.controller.active!;
    final path = p.join(
      fixture.root.path,
      fixture.controller.project!.maps.first.relativePath,
    );
    final changed = document.current.copyWith(properties: {'external': true});
    await File(path).writeAsString(jsonEncode(changed.toJson()));
    final result = await fixture.controller.mutateCatalog(
      'map.update_metadata',
      {'mapId': 'jardin', 'name': 'Écrasement'},
    );
    expect(result.published, isFalse);
    expect(
      MapData.fromJson(jsonDecode(await File(path).readAsString())),
      changed,
    );
    expect(document.current, isNot(changed));
  });
}
