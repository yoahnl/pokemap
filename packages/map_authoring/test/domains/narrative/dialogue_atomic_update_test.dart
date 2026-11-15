import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'dialogue_atomic_fixture.dart';

void main() {
  test('JSONL transports an atomic dialogue update without a map', () async {
    final f = await DialogueAtomicFixture.create();
    addTearDown(f.dispose);
    final worker = JsonlWorker(api: f.readApi, mutations: f.api);
    Future<AuthoringResult> command(
            String name, Map<String, Object?> args) async =>
        AuthoringResult.fromJson(
            jsonDecode(await worker.processLine(jsonEncode({
          'id': name,
          'command': name,
          'args': args,
        }))) as Map<String, dynamic>);
    final describe = await command('describe', {});
    expect(jsonEncode(describe.toJson()),
        contains('optional Yarn source atomically'));
    final entry =
        DialogueAtomicFixture.entry.copyWith(name: 'Publié via JSONL');
    final source =
        DialogueAtomicFixture.sourceText.replaceFirst('Bonjour', 'Salut');
    final request = await f.request(
        'dialogue.update', {'entry': entry.toJson(), 'source': source});
    final planned = await command('plan', {
      'projectHandle': f.opened.projectHandle.value,
      'request': request.toJson(),
    });
    expect(planned.status, AuthoringResultStatus.success,
        reason: jsonEncode(planned.toJson()));
    final applied = await command('apply', {
      'projectHandle': f.opened.projectHandle.value,
      'planId': planned.data['planId'],
      'operationId': 'jsonl-update',
    });
    expect(applied.status, AuthoringResultStatus.success,
        reason: jsonEncode(applied.toJson()));
    final disk = await f.loader.load(f.opened.projectHandle);
    expect(disk.manifest.dialogues.single, entry);
    expect(disk.maps, isEmpty);
    expect(await f.source.readAsString(), source);
  });

  test(
      'dialogue.update publishes entry and source in one plan and undo restores both',
      () async {
    final f = await DialogueAtomicFixture.create();
    addTearDown(f.dispose);
    final entry = DialogueAtomicFixture.entry.copyWith(
        name: 'Renommé',
        declaredOutcomes: const [
          DialogueDeclaredOutcome(id: 'partir', label: 'Partir')
        ]);
    const source =
        'title: Accueil\n---\nBienvenue\n-> Partir\n  <<outcome partir>>\n===\n';
    final request = await f.request('dialogue.update', {
      'entry': entry.toJson(),
      'source': source,
    });
    final planned = await f.api.planMutation(f.opened.projectHandle, request);
    expect(planned.plan.changeSet.changes.map((e) => e.storageKey).toSet(),
        {'project.json', 'dialogues/gare.yarn'});
    expect(await f.source.readAsString(), DialogueAtomicFixture.sourceText);
    final applied = await f.api.apply(f.opened.projectHandle,
        planId: planned.planId, operationId: 'atomic-update');
    final disk = await f.loader.load(f.opened.projectHandle);
    expect(disk.manifest.dialogues.single, entry);
    expect(await f.source.readAsString(), source);
    expect(
        const DialogueAuthoringCompiler()
            .compile(entry: entry, source: source)
            .canPublish,
        isTrue);
    final receipt = Map<String, Object?>.from(applied['receipt']! as Map);
    await f.api.undo(f.opened.projectHandle,
        entryId: receipt['receiptId']! as String,
        idempotencyKey: 'undo-atomic-update');
    expect(
        (await f.loader.load(f.opened.projectHandle)).manifest.dialogues.single,
        DialogueAtomicFixture.entry);
    expect(await f.source.readAsString(), DialogueAtomicFixture.sourceText);
  });

  test('metadata rename with identical source writes only manifest', () async {
    final f = await DialogueAtomicFixture.create();
    addTearDown(f.dispose);
    final request = await f.request('dialogue.update', {
      'entry': DialogueAtomicFixture.entry.copyWith(name: 'Renommé').toJson(),
      'source': DialogueAtomicFixture.sourceText,
    });
    final planned = await f.api.planMutation(f.opened.projectHandle, request);
    expect(planned.plan.changeSet.changes.map((e) => e.storageKey),
        ['project.json']);
    expect(planned.plan.changeSet.diff.affectedResources.map((e) => e.kind),
        ['project']);
  });

  test('unchanged atomic and source-only requests are genuine no-ops',
      () async {
    final f = await DialogueAtomicFixture.create();
    addTearDown(f.dispose);
    for (final action in ['dialogue.update', 'dialogue.source_update']) {
      final request = await f.request(action, {
        if (action == 'dialogue.update')
          'entry': DialogueAtomicFixture.entry.toJson()
        else
          'dialogueId': DialogueAtomicFixture.entry.id,
        'source': DialogueAtomicFixture.sourceText,
      });
      final planned = await f.api.planMutation(f.opened.projectHandle, request);
      expect(planned.plan.changeSet.changes, isEmpty);
      expect(planned.plan.changeSet.diff.affectedResources, isEmpty);
    }
  });

  test('delete remains confirmation protected at the canonical API', () async {
    final f = await DialogueAtomicFixture.create();
    addTearDown(f.dispose);
    final planned = await f.api.planMutation(
        f.opened.projectHandle,
        await f.request(
            'dialogue.delete', {'dialogueId': DialogueAtomicFixture.entry.id}));
    await expectLater(
        f.api.applyMutation(f.opened.projectHandle,
            planId: planned.planId, operationId: 'unconfirmed-delete'),
        throwsA(anything));
    expect(await f.source.exists(), isTrue);
    expect((await f.loader.load(f.opened.projectHandle)).manifest.dialogues,
        [DialogueAtomicFixture.entry]);
  });
}
