import 'dart:async';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_metadata_documents.dart';
import 'package:test/test.dart';

import 'dialogue_atomic_fixture.dart';

void main() {
  for (final action in ['dialogue.update', 'dialogue.source_update']) {
    test('$action plans without reopening the selected immutable document',
        () async {
      final f = await _fixture();
      addTearDown(f.dispose);
      await f.api.prepareWorkshopCatalog(f.opened.projectHandle);
      final store =
          await CatalogStorageStore.open(projectRoot: f.directory.path);
      final root = await store.openRoot((await store.readHead())!);
      final selected = (await root.snapshot
          .indexEntry(CatalogMetadataDocuments.definitionKey('dialogues', 0)))!;
      final canonicalRoot = await f.directory.resolveSymbolicLinks();
      final objectPath =
          '$canonicalRoot/catalog/objects/${selected.reference.sha256}.json';
      final parameters = {
        if (action == 'dialogue.update')
          'entry': DialogueAtomicFixture.entry.toJson()
        else
          'dialogueId': 'gare',
        'source':
            DialogueAtomicFixture.sourceText.replaceFirst('Bonjour', 'Bonsoir'),
      };
      final snapshot = await f.api.readWorkshopSnapshot(f.opened.projectHandle,
          actionId: action, parameters: parameters);
      final outside = Zone.current;
      var repeated = 0;
      final planned = await IOOverrides.runZoned(
          () => f.api.planMutation(f.opened.projectHandle,
              _request(f, action, parameters, snapshot.revision)),
          createFile: (path) {
        if (path == objectPath) repeated++;
        return outside.run(() => File(path));
      });
      expect(repeated, 0,
          reason:
              'The current scoped snapshot already owns this immutable document.');
      await f.api.applyMutation(f.opened.projectHandle,
          planId: planned.planId, operationId: action);
      expect(await f.source.readAsString(), parameters['source']);
    });
  }

  test('a changed source invalidates the reused selection without writing',
      () async {
    final f = await _fixture();
    addTearDown(f.dispose);
    await f.api.prepareWorkshopCatalog(f.opened.projectHandle);
    final parameters = {
      'dialogueId': 'gare',
      'source':
          DialogueAtomicFixture.sourceText.replaceFirst('Bonjour', 'Bonsoir')
    };
    final snapshot = await f.api.readWorkshopSnapshot(f.opened.projectHandle,
        actionId: 'dialogue.source_update', parameters: parameters);
    final external = DialogueAtomicFixture.sourceText
        .replaceFirst('Bonjour', 'Modification externe');
    await f.source.writeAsString(external);
    final head = File('${f.directory.path}/catalog/HEAD.json');
    final before = await head.readAsBytes();
    await expectLater(
        f.api.planMutation(
            f.opened.projectHandle,
            _request(
                f, 'dialogue.source_update', parameters, snapshot.revision)),
        throwsA(isA<AuthoringPlanException>()
            .having((error) => error.code, 'code', 'plan.stale')));
    expect(await f.source.readAsString(), external);
    expect(await head.readAsBytes(), before);
  });

  test('a different intent builds its own dependency selection', () async {
    final f = await _fixture();
    addTearDown(f.dispose);
    await f.api.prepareWorkshopCatalog(f.opened.projectHandle);
    final parameters = {
      'dialogueId': 'gare',
      'source':
          DialogueAtomicFixture.sourceText.replaceFirst('Bonjour', 'Bonsoir')
    };
    final snapshot = await f.api.readWorkshopSnapshot(f.opened.projectHandle,
        actionId: 'dialogue.source_update', parameters: parameters);
    final changed = {
      ...parameters,
      'source': DialogueAtomicFixture.sourceText
          .replaceFirst('Bonjour', 'Autre intention')
    };
    final plan = await f.api.planMutation(f.opened.projectHandle,
        _request(f, 'dialogue.source_update', changed, snapshot.revision));
    await f.api.applyMutation(f.opened.projectHandle,
        planId: plan.planId, operationId: 'changed-intent');
    expect(await f.source.readAsString(), changed['source']);
  });
}

Future<DialogueAtomicFixture> _fixture() async {
  final home = Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      Directory.systemTemp.path;
  final root = Platform.environment['AVELUNE_QA_ROOT'] ??
      '$home/Library/Caches/AveluneQA';
  return DialogueAtomicFixture.create(
      catalog: true,
      qaRoot: await Directory('$root/dialogue-workshop-selection-tests')
          .create(recursive: true));
}

AuthoringRequest _request(DialogueAtomicFixture f, String action,
        Map<String, Object?> parameters, String revision) =>
    AuthoringRequest(
        requestId: action,
        actionId: action,
        actionVersion: 1,
        workspaceHandle: f.opened.workspaceHandle.value,
        expectedRevision: revision,
        idempotencyKey: action,
        extensions: const {'workshopScope': true},
        parameters: parameters);
