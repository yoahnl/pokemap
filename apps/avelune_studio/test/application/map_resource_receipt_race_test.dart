import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'm1_controller_fixture.dart';

void main() {
  late M1ControlledPort port;
  late MapWorkspaceController controller;
  setUp(() {
    port = M1ControlledPort();
    controller = MapWorkspaceController(m1Session, port);
  });
  tearDown(() => controller.dispose());

  test('receipt invalidates a closed preview and its retained load', () async {
    await controller.initialize();
    final unrelated = controller.previewMap('a');
    final old = Completer<MapWorkspaceDocument>();
    port.pendingLoads['b'] = old;
    final pending = controller.previewMap('b');
    expect(port.mapLoads['b'], 1);
    controller.acceptResourceMaps({'b': _document('replacement')});
    expect(controller.documents.containsKey('b'), isFalse);
    old.complete(_document('removed'));
    expect(await pending, isNull);
    expect(controller.previewMap('a'), same(unrelated));
    final fresh = Completer<MapWorkspaceDocument>();
    port.pendingLoads['b'] = fresh;
    final refreshed = controller.previewMap('b');
    expect(port.mapLoads['b'], 2);
    fresh.complete(_document('replacement'));
    expect((await refreshed)!.entities.single.npc!.characterId, 'replacement');
    expect(controller.active!.base.mapId, 'a');
  });

  test(
    'receipt invalidates a retained activation before document insertion',
    () async {
      await controller.initialize();
      final old = Completer<MapWorkspaceDocument>();
      port.pendingLoads['b'] = old;
      final pending = controller.activate(m1Second);
      controller.acceptResourceMaps({'b': _document('replacement')});
      old.complete(_document('removed'));
      await pending;
      expect(controller.documents.containsKey('b'), isFalse);
      expect(controller.active!.base.mapId, 'a');
      expect(controller.loading, isFalse);
      final fresh = Completer<MapWorkspaceDocument>();
      port.pendingLoads['b'] = fresh;
      final activated = controller.activate(m1Second);
      expect(port.mapLoads['b'], 2);
      fresh.complete(_document('replacement'));
      await activated;
      expect(
        controller.active!.current.entities.single.npc!.characterId,
        'replacement',
      );
      expect(controller.active!.base.revision, 'revision-replacement');
    },
  );

  test('old activation cannot remove the new activation queue entry', () async {
    await controller.initialize();
    final old = Completer<MapWorkspaceDocument>();
    port.pendingLoads['b'] = old;
    final obsolete = controller.activate(m1Second);
    controller.acceptResourceMaps({'b': _document('replacement')});
    final fresh = Completer<MapWorkspaceDocument>();
    port.pendingLoads['b'] = fresh;
    final current = controller.activate(m1Second);
    old.complete(_document('removed'));
    await obsolete;
    expect(controller.loading, isTrue);
    final joined = controller.activate(m1Second);
    expect(port.mapLoads['b'], 2);
    fresh.complete(_document('replacement'));
    await Future.wait([current, joined]);
    expect(
      controller.active!.current.entities.single.npc!.characterId,
      'replacement',
    );
    expect(controller.loading, isFalse);
  });

  test(
    'obsolete activation failure cannot publish an error after receipt',
    () async {
      await controller.initialize();
      final old = Completer<MapWorkspaceDocument>();
      port.pendingLoads['b'] = old;
      final obsolete = controller.activate(m1Second);
      controller.acceptResourceMaps({'b': _document('replacement')});
      old.completeError(StateError('Old source failure'));
      await obsolete;
      expect(controller.error, isNull);
      expect(controller.documents.containsKey('b'), isFalse);
      expect(controller.active!.base.mapId, 'a');
      expect(controller.loading, isFalse);
    },
  );
}

MapWorkspaceDocument _document(String characterId) => MapWorkspaceDocument(
  map: m1Document('b').map.copyWith(
    entities: [
      MapEntity(
        id: 'npc',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 1, y: 1),
        npc: MapEntityNpcData(characterId: characterId),
      ),
    ],
  ),
  revision: 'revision-$characterId',
  mapId: 'b',
);
