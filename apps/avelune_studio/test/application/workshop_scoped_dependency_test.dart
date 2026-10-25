import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/events/domain/event_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  late WorkspaceMemoryPort mapPort;
  late MapWorkspaceController maps;
  late NarrativeWorkspaceController narrative;

  setUp(() async {
    mapPort = WorkspaceMemoryPort();
    maps = MapWorkspaceController(workspaceSession, mapPort);
    await maps.initialize();
    narrative = NarrativeWorkspaceController(
      maps,
      _NarrativePort(),
      () {},
      (_, _) async {},
    );
  });

  tearDown(() {
    narrative.dispose();
    maps.dispose();
  });

  test('opening world states does not load unrelated maps', () async {
    final port = _WorldPort();
    final world = WorldWorkspaceController(narrative, port, changed: () {});
    addTearDown(world.dispose);
    await world.initialize();
    expect(world.initialized, isTrue);
    expect(port.allMapReads, 0);
    expect(mapPort.reads, 1);
  });

  test('preparing event editing does not load unrelated maps', () async {
    final events = EventWorkspaceController(
      narrative,
      _EventPort(),
      changed: () {},
    );
    addTearDown(events.dispose);
    expect(await events.prepare(), isTrue);
    expect(mapPort.reads, 1);
    expect(events.maps.map((map) => map.id), ['a']);
    expect(await events.prepare(), isTrue);
    expect(mapPort.reads, 1);
    expect(events.mapsComplete, isFalse);
    expect(await events.prepare(mapIds: ['b']), isTrue);
    expect(await events.prepare(mapIds: ['b']), isTrue);
    expect(mapPort.reads, 2);
    expect(events.mapsComplete, isTrue);
  });

  test(
    'world target selection reads one map and retains the open draft',
    () async {
      final port = _WorldPort();
      final world = WorldWorkspaceController(narrative, port, changed: () {});
      addTearDown(world.dispose);
      await world.initialize();
      maps.active!.commit(maps.active!.current.copyWith(name: 'Brouillon'));
      expect(world.mapsComplete, isFalse);
      expect(
        await Future.wait([world.loadTargetMap('b'), world.loadTargetMap('b')]),
        [true, true],
      );
      expect(await world.loadTargetMap('b'), isTrue);
      expect(port.selectedReads, ['b']);
      expect(port.allMapReads, 0);
      expect(world.maps.firstWhere((map) => map.id == 'a').name, 'Brouillon');
      expect(world.mapsComplete, isTrue);
    },
  );

  test(
    'world full simulation reads maps only when explicitly requested',
    () async {
      final port = _WorldPort();
      final world = WorldWorkspaceController(narrative, port, changed: () {});
      addTearDown(world.dispose);
      await world.initialize();
      world.simulate();
      expect(world.report, isNull);
      expect(port.allMapReads, 0);
      await world.simulateComplete();
      expect(port.allMapReads, 1);
      expect(world.mapsComplete, isTrue);
      expect(world.report, isNotNull);
    },
  );
}

class _WorldPort implements WorldPort, WorldMapSelectionPort {
  int allMapReads = 0;
  final selectedReads = <String>[];

  @override
  Future<MapData> loadMap(ProjectMapEntry entry) async {
    selectedReads.add(entry.id);
    return workspaceMap(entry.id);
  }

  @override
  Future<List<MapData>> loadMaps() async {
    allMapReads++;
    return [workspaceMap('a'), workspaceMap('b')];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected write: ${invocation.memberName}');
}

class _NarrativePort implements NarrativePort {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
    'Unexpected source read or write: ${invocation.memberName}',
  );
}

class _EventPort implements EventPort {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected write: ${invocation.memberName}');
}
