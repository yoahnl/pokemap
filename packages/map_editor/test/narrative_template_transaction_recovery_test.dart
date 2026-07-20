import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/narrative_template_catalog.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_template_transaction_file_gateway.dart';
import 'package:path/path.dart' as p;

void main() {
  test('apply and undo cover the Event registry and Scene as one mutation',
      () async {
    final before = _emptyProject();
    final preview = _preview(before);
    final gateway = _MemoryGateway(before);
    final coordinator = NarrativeTemplateTransactionCoordinator(gateway);

    await coordinator.apply(transactionId: 'tx_item', preview: preview);
    expect(gateway.project.toJson(), preview.after!.toJson());
    expect(gateway.journal, isNull);

    await coordinator.undo(preview);
    expect(gateway.project.toJson(), before.toJson());
  });

  test('durable journal round-trips before recovery', () {
    final preview = _preview(_emptyProject());
    final record = NarrativeTemplateTransactionRecord(
      transactionId: 'tx_item',
      status: NarrativeTemplateTransactionStatus.prepared,
      before: preview.before,
      after: preview.after!,
    );

    final reloaded = NarrativeTemplateTransactionRecord.fromJson(
      jsonDecode(jsonEncode(record.toJson())) as Map<String, dynamic>,
    );

    expect(reloaded.transactionId, record.transactionId);
    expect(reloaded.status, record.status);
    expect(reloaded.before.toJson(), record.before.toJson());
    expect(reloaded.after.toJson(), record.after.toJson());
  });

  test('recovery rolls back a crash after project write and is idempotent',
      () async {
    final before = _emptyProject();
    final preview = _preview(before);
    final gateway = _MemoryGateway(before, failJournalWriteAt: 2);
    final coordinator = NarrativeTemplateTransactionCoordinator(gateway);

    await expectLater(
      coordinator.apply(transactionId: 'tx_item', preview: preview),
      throwsStateError,
    );
    expect(gateway.project.toJson(), preview.after!.toJson());
    expect(
        gateway.journal!.status, NarrativeTemplateTransactionStatus.prepared);

    expect(await coordinator.recover(), isTrue);
    expect(gateway.project.toJson(), before.toJson());
    expect(gateway.journal, isNull);
    expect(await coordinator.recover(), isFalse);
  });

  test('recovery keeps a committed project when clearing the journal failed',
      () async {
    final before = _emptyProject();
    final preview = _preview(before);
    final gateway = _MemoryGateway(before, failClearOnce: true);
    final coordinator = NarrativeTemplateTransactionCoordinator(gateway);

    await expectLater(
      coordinator.apply(transactionId: 'tx_item', preview: preview),
      throwsStateError,
    );
    expect(
      gateway.journal!.status,
      NarrativeTemplateTransactionStatus.committed,
    );

    expect(await coordinator.recover(), isTrue);
    expect(gateway.project.toJson(), preview.after!.toJson());
    expect(gateway.journal, isNull);
  });

  test('file gateway durably applies, reloads and undoes the whole template',
      () async {
    final root = await Directory.systemTemp.createTemp('template_tx_');
    addTearDown(() => root.delete(recursive: true));
    final projectPath = p.join(root.path, 'project.json');
    final before = _emptyProject();
    await File(projectPath).writeAsString(
      jsonEncode(<String, dynamic>{
        ...before.toJson(),
        'futureRootMember': <String, dynamic>{'preserved': true},
      }),
    );
    final gateway = NarrativeTemplateTransactionFileGateway(
      projectPath: projectPath,
    );
    final coordinator = NarrativeTemplateTransactionCoordinator(gateway);
    final preview = _preview(await gateway.readProject());

    await coordinator.apply(transactionId: 'tx_file', preview: preview);
    final reloaded = await gateway.readProject();
    expect(reloaded.toJson(), preview.after!.toJson());
    expect(await File(gateway.journalPath).exists(), isFalse);
    final rootJson = jsonDecode(await File(projectPath).readAsString()) as Map;
    expect(rootJson['futureRootMember'], {'preserved': true});

    await coordinator.undo(preview);
    expect((await gateway.readProject()).toJson(), before.toJson());
  });
}

const _eventId = 'evt_00000000-0000-7000-8000-000000000002';

ProjectManifest _emptyProject() => const ProjectManifest(
      name: 'Transaction test',
      maps: [],
      tilesets: [],
    );

NarrativeTemplatePreview _preview(ProjectManifest project) {
  return previewNarrativeTemplate(
    project: project,
    request: NarrativeTemplateRequest(
      kind: NarrativeTemplateKind.simpleNpc,
      eventId: _eventId,
      sceneId: 'scene.npc',
      name: 'PNJ',
      source: NarrativeEventSourceRef.entityInteract('map_port', 'npc_a'),
      physicalSource: const NarrativeTemplatePhysicalSource(
        kind: NarrativeTemplatePhysicalSourceKind.entity,
        mapId: 'map_port',
        sourceId: 'npc_a',
        exists: true,
      ),
      parameters: const {'dialogueId': 'dialogue.a'},
    ),
  );
}

final class _MemoryGateway implements NarrativeTemplateTransactionGateway {
  _MemoryGateway(
    this.project, {
    this.failJournalWriteAt,
    this.failClearOnce = false,
  });

  ProjectManifest project;
  NarrativeTemplateTransactionRecord? journal;
  final int? failJournalWriteAt;
  bool failClearOnce;
  int _journalWrites = 0;

  @override
  Future<void> clearJournal() async {
    if (failClearOnce) {
      failClearOnce = false;
      throw StateError('simulated clear interruption');
    }
    journal = null;
  }

  @override
  Future<NarrativeTemplateTransactionRecord?> readJournal() async => journal;

  @override
  Future<ProjectManifest> readProject() async => project;

  @override
  Future<void> writeJournal(NarrativeTemplateTransactionRecord record) async {
    _journalWrites += 1;
    if (_journalWrites == failJournalWriteAt) {
      throw StateError('simulated journal interruption');
    }
    // The memory gateway deliberately round-trips JSON to model a durable file.
    journal = NarrativeTemplateTransactionRecord.fromJson(
      jsonDecode(jsonEncode(record.toJson())) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> writeProject(ProjectManifest value) async {
    project = ProjectManifest.fromJson(
      jsonDecode(jsonEncode(value.toJson())) as Map<String, dynamic>,
    );
  }
}
