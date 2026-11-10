import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/dive_pair_publishing_session.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_dive_pair_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

MapData _endpoint(String id, DiveZoneRole role) => workspaceMap(id).copyWith(
  gameplayZones: [
    MapGameplayZone(
      id: 'point',
      kind: GameplayZoneKind.fieldAction,
      area: const MapRect(
        pos: GridPos(x: 2, y: 2),
        size: GridSize(width: 1, height: 1),
      ),
      fieldAction: FieldActionZonePayload(
        actionKind: FieldActionZoneKind.dive,
        dive: DiveZonePayload(role: role),
      ),
    ),
  ],
);

void main() {
  late WorkspaceMemoryPort memory;
  late MapWorkspaceController controller;
  late _Publisher publisher;
  late DivePairPublishingSession publishing;

  setUp(() async {
    memory = WorkspaceMemoryPort()
      ..saved.addAll({
        'a': _endpoint('a', DiveZoneRole.surface),
        'b': _endpoint('b', DiveZoneRole.underwater),
      });
    controller = MapWorkspaceController(workspaceSession, memory);
    await controller.initialize();
    publisher = _Publisher();
    publishing = DivePairPublishingSession(
      controller: controller,
      port: publisher,
    );
  });

  tearDown(() {
    publishing.dispose();
    controller.dispose();
  });

  Future<void> select() async {
    await publishing.selectMap('b');
    publishing.targetZoneId = 'point';
  }

  test(
    'temporary endpoint choices leave the document and history intact',
    () async {
      final document = controller.active!;
      final before = document.current;
      await select();
      expect(publishing.target?.id, 'b');
      expect(document.current, same(before));
      expect(document.dirty, isFalse);
      expect(document.canUndo, isFalse);
      expect(publisher.calls, isEmpty);
    },
  );

  test(
    'publishes clean endpoints and refreshes only their saved maps',
    () async {
      await select();
      final document = controller.active!;
      final reads = memory.reads;
      final catalogs = memory.catalogs;
      await publishing.publish(document, document.current.gameplayZones.single);
      expect(publisher.calls, hasLength(1));
      final call = publisher.calls.single;
      expect(call.source.id, 'a');
      expect(call.target.id, 'b');
      expect(call.zoneId, 'point');
      expect(call.targetZoneId, 'point');
      expect(call.unlink, isFalse);
      expect(memory.reads - reads, 2);
      expect(memory.catalogs, catalogs);
      expect(document.canUndo, isFalse);
      expect(publishing.message, contains('Les deux points sont liés'));
      expect(publishing.busy, isFalse);
    },
  );

  test('dirty source and target drafts cannot publish', () async {
    await select();
    final document = controller.active!;
    document.commit(document.current.copyWith(name: 'Dirty source'));
    await publishing.publish(document, document.current.gameplayZones.single);
    expect(publisher.calls, isEmpty);
    expect(publishing.message, contains('Enregistrez les brouillons'));
    document.restore(redo: false);
    await controller.activate(workspaceEntries.last);
    final target = controller.active!;
    target.commit(target.current.copyWith(name: 'Dirty target'));
    await publishing.publish(document, document.current.gameplayZones.single);
    expect(publisher.calls, isEmpty);
    expect(target.dirty, isTrue);
  });

  test(
    'busy publication is single flight and exposes publisher failures',
    () async {
      await select();
      publisher.gate = Completer<void>();
      publisher.failure = StateError('publication refused');
      final document = controller.active!;
      final first = publishing.publish(
        document,
        document.current.gameplayZones.single,
      );
      await publishing.publish(document, document.current.gameplayZones.single);
      expect(publisher.calls, hasLength(1));
      expect(publishing.busy, isTrue);
      publisher.gate!.complete();
      await first;
      expect(publishing.busy, isFalse);
      expect(publishing.message, contains('publication refused'));
      expect(document.dirty, isFalse);
    },
  );

  test('saving source and target documents cannot publish', () async {
    await select();
    final source = controller.active!;
    source.saving = true;
    await publishing.publish(source, source.current.gameplayZones.single);
    expect(publisher.calls, isEmpty);
    source.saving = false;
    await controller.activate(workspaceEntries.last);
    controller.active!.saving = true;
    await publishing.publish(source, source.current.gameplayZones.single);
    expect(publisher.calls, isEmpty);
    controller.active!.saving = false;
  });

  test('late target loading cannot replace a newer choice', () async {
    final delayed = _DelayedMemoryPort();
    final workspace = MapWorkspaceController(workspaceSession, delayed);
    await workspace.initialize();
    final selection = DivePairPublishingSession(
      controller: workspace,
      port: null,
    );
    addTearDown(() {
      selection.dispose();
      workspace.dispose();
    });
    final first = selection.selectMap('b');
    await selection.selectMap('a');
    delayed.gate.complete();
    await first;
    expect(selection.targetMapId, 'a');
    expect(selection.target?.id, 'a');
  });

  test(
    'a disposed selection cannot publish or notify its former host',
    () async {
      await select();
      publishing.dispose();
      final document = controller.active!;
      await publishing.publish(document, document.current.gameplayZones.single);
      expect(publisher.calls, isEmpty);
    },
  );
}

class _Publisher implements MapDivePairPort {
  final calls =
      <
        ({
          MapData source,
          MapData target,
          String zoneId,
          String targetZoneId,
          bool unlink,
        })
      >[];
  Completer<void>? gate;
  Object? failure;

  @override
  Future<void> publishDivePair({
    required ProjectSession session,
    required MapData source,
    required MapData expectedTarget,
    required String zoneId,
    required String targetZoneId,
    required bool unlink,
  }) async {
    calls.add((
      source: source,
      target: expectedTarget,
      zoneId: zoneId,
      targetZoneId: targetZoneId,
      unlink: unlink,
    ));
    await gate?.future;
    if (failure case final error?) throw error;
  }
}

class _DelayedMemoryPort extends WorkspaceMemoryPort {
  final gate = Completer<void>();

  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    if (entry.id == 'b') await gate.future;
    return super.loadMap(session, entry);
  }
}
