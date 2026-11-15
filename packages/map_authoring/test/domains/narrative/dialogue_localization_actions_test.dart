import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'dialogue_atomic_fixture.dart';

Future<ProjectDialogueEntry> _localize(DialogueAtomicFixture f) async {
  final draft = readLocalizedDialogue(
      source: DialogueAtomicFixture.sourceText, sourceLocale: 'fr');
  final catalog = draft.localization
      .translate(draft.localization.units.single.id, 'en', 'Hello');
  final entry = DialogueAtomicFixture.entry.copyWith(localization: catalog);
  final plan = await f.api.planMutation(
      f.opened.projectHandle,
      await f.request('dialogue.update',
          {'entry': entry.toJson(), 'source': draft.source}));
  await f.api.apply(f.opened.projectHandle,
      planId: plan.planId, operationId: 'localize');
  return entry;
}

void main() {
  test(
      'an unsupported stored localization leaves the original project bytes intact',
      () async {
    final f = await DialogueAtomicFixture.create();
    addTearDown(f.dispose);
    final file = File('${f.directory.path}/project.json');
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final entry = (json['dialogues'] as List).single as Map<String, dynamic>;
    entry['localization'] = {'format': 99, 'sourceLocale': 'fr', 'units': []};
    final bytes = utf8.encode(jsonEncode(json));
    await file.writeAsBytes(bytes);
    await expectLater(
        f.readApi.openProject(f.directory.path),
        throwsA(isA<ProjectOpenException>().having(
            (error) => error.code, 'code', 'project.manifest_invalid')));
    expect(await file.readAsBytes(), bytes);
    expect(await f.source.readAsString(), DialogueAtomicFixture.sourceText);
  });

  test(
      'working catalog stores localization on its dialogue metadata and reopens it',
      () async {
    final f = await DialogueAtomicFixture.create(catalog: true);
    addTearDown(f.dispose);
    final entry = await _localize(f);
    final opened = await f.readApi.openProject(f.directory.path);
    addTearDown(() => f.readApi.closeWorkspace(opened.workspaceHandle));
    final disk = await f.loader.load(opened.projectHandle);
    expect(disk.manifest.dialogues.single, entry);
    expect(await f.source.readAsString(), DialogueAtomicFixture.sourceText);
  });

  test(
      'JSONL stores variants atomically and undo preserves the original Yarn bytes',
      () async {
    final f = await DialogueAtomicFixture.create();
    addTearDown(f.dispose);
    final draft = readLocalizedDialogue(
        source: DialogueAtomicFixture.sourceText, sourceLocale: 'fr');
    final entry = DialogueAtomicFixture.entry.copyWith(
        localization: draft.localization
            .translate(draft.localization.units.single.id, 'en', 'Hello'));
    final worker = JsonlWorker(api: f.readApi, mutations: f.api);
    Future<AuthoringResult> call(
            String command, Map<String, Object?> args) async =>
        AuthoringResult.fromJson(
            jsonDecode(await worker.processLine(jsonEncode({
          'id': command,
          'command': command,
          'args': args,
        }))) as Map<String, dynamic>);
    final described = await call('describe', {});
    expect(jsonEncode(described.toJson()), contains('localizationContract'));
    final request =
        await f.request('dialogue.update', {'entry': entry.toJson()});
    final planned = await call('plan', {
      'projectHandle': f.opened.projectHandle.value,
      'request': request.toJson()
    });
    expect(planned.status, AuthoringResultStatus.success,
        reason: '${planned.toJson()}');
    final applied = await call('apply', {
      'projectHandle': f.opened.projectHandle.value,
      'planId': planned.data['planId'],
      'operationId': 'jsonl-localization'
    });
    expect(applied.status, AuthoringResultStatus.success,
        reason: '${applied.toJson()}');
    expect(
        (await f.loader.load(f.opened.projectHandle)).manifest.dialogues.single,
        entry);
    expect(await f.source.readAsString(), DialogueAtomicFixture.sourceText);
    final receipt =
        Map<String, Object?>.from((applied.data['receipt'])! as Map);
    await f.api.undo(f.opened.projectHandle,
        entryId: receipt['receiptId']! as String,
        idempotencyKey: 'undo-localization');
    expect(
        (await f.loader.load(f.opened.projectHandle)).manifest.dialogues.single,
        DialogueAtomicFixture.entry);
    expect(await f.source.readAsString(), DialogueAtomicFixture.sourceText);
  });

  test(
      'source edits cannot silently orphan translations or replace their identities',
      () async {
    final f = await DialogueAtomicFixture.create();
    addTearDown(f.dispose);
    final entry = await _localize(f);
    final manifest = File('${f.directory.path}/project.json');
    final before = await manifest.readAsBytes();
    for (final (parameters, code) in [
      (
        {
          'entry': entry
              .copyWith(
                  localization: entry.localization!.withUnits([
                entry.localization!.units.single.copyWith(id: 'replacement'),
              ]))
              .toJson()
        },
        'dialogue.localization_identity_changed'
      ),
      (
        {'entry': entry.copyWith(localization: null).toJson()},
        'dialogue.localization_required'
      ),
      (
        {
          'entry': entry.toJson(),
          'source':
              DialogueAtomicFixture.sourceText.replaceFirst('Bonjour', 'Salut')
        },
        'dialogue.compile_blocking'
      ),
      (
        {
          'entry': entry
              .copyWith(localization: entry.localization!.withUnits([]))
              .toJson()
        },
        'dialogue.compile_blocking'
      ),
    ]) {
      await expectLater(
          f.api.planMutation(f.opened.projectHandle,
              await f.request('dialogue.update', parameters)),
          throwsA(isA<NarrativeAuthoringException>()
              .having((error) => error.code, 'code', code)));
      expect(await manifest.readAsBytes(), before);
      expect(await f.source.readAsString(), DialogueAtomicFixture.sourceText);
    }
    await expectLater(
        f.api.planMutation(
            f.opened.projectHandle,
            await f.request('dialogue.source_update', {
              'dialogueId': entry.id,
              'source': DialogueAtomicFixture.sourceText
                  .replaceFirst('Bonjour', 'Salut')
            })),
        throwsA(isA<NarrativeAuthoringException>().having(
            (error) => error.code, 'code', 'dialogue.compile_blocking')));
    expect(await manifest.readAsBytes(), before);
    expect(await f.source.readAsString(), DialogueAtomicFixture.sourceText);
  });

  test(
      'a source edit with its reconciled catalog retains stale translations after reopening',
      () async {
    final f = await DialogueAtomicFixture.create();
    addTearDown(f.dispose);
    final entry = await _localize(f);
    final opened = readLocalizedDialogue(
        source: await f.source.readAsString(),
        sourceLocale: 'fr',
        localization: entry.localization);
    opened.document.nodes.single.steps.whereType<DeLineStep>().single.body =
        'Bienvenue';
    final edited =
        writeLocalizedDialogue(opened.document, previous: opened.localization);
    final plan = await f.api.planMutation(
        f.opened.projectHandle,
        await f.request('dialogue.update', {
          'entry': entry.copyWith(localization: edited.localization).toJson(),
          'source': edited.source
        }));
    expect(
        plan.plan.changeSet.changes.map((change) => change.storageKey).toSet(),
        {'project.json', entry.relativePath});
    await f.api.apply(f.opened.projectHandle,
        planId: plan.planId, operationId: 'source-edit');
    final saved =
        (await f.loader.load(f.opened.projectHandle)).manifest.dialogues.single;
    final catalog = saved.localization!;
    expect(catalog.units.single.id, entry.localization!.units.single.id);
    expect(
        catalog
            .resolve(catalog.units.single.id,
                preferredLocale: 'en',
                supportedLocales: ['fr', 'en'],
                fallbackLocale: 'fr')
            .status,
        DialogueTranslationStatus.needsReview);
    expect(catalog.units.single.translations['en']!.text, 'Hello');
  });
}
