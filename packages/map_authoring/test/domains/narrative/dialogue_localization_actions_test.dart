import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_metadata_documents.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'dialogue_atomic_fixture.dart';
import '../../support/reliability_map_fixture.dart';

Future<ProjectDialogueEntry> _localize(DialogueAtomicFixture f,
    {ProjectDialogueEntry initial = DialogueAtomicFixture.entry}) async {
  final draft = readLocalizedDialogue(
      source: DialogueAtomicFixture.sourceText, sourceLocale: 'fr');
  final catalog = draft.localization
      .translate(draft.localization.units.single.id, 'en', 'Hello');
  final entry = initial.copyWith(localization: catalog);
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

  test('working catalog saves variants without loading dialogue consumers',
      () async {
    final initial = DialogueAtomicFixture.entry.copyWith(folderId: 'arrivals');
    final linked = SceneAsset(
      id: 'arrival',
      name: 'Arrival',
      graph: SceneGraph(startNodeId: 'start', nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
            id: 'greeting',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(
                dialogueId: DialogueAtomicFixture.entry.id,
                yarnNodeName: 'Accueil')),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ], edges: [
        for (final (from, to) in [('start', 'greeting'), ('greeting', 'end')])
          SceneEdge(
              id: '$from-$to',
              fromNodeId: from,
              fromPortId: 'completed',
              toNodeId: to,
              kind: SceneEdgeKind.defaultFlow),
      ]),
    );
    final reader = ReliabilityCountingReader();
    final f = await DialogueAtomicFixture.create(
      catalog: true,
      reader: reader,
      manifest: ProjectManifest(
        name: 'Dialogue variants',
        version: ProjectVersion.v9,
        settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
        maps: [],
        tilesets: [],
        dialogueFolders: const [
          ProjectDialogueFolder(id: 'stations', name: 'Stations'),
          ProjectDialogueFolder(
              id: 'arrivals', name: 'Arrivals', parentFolderId: 'stations'),
        ],
        scenes: [linked],
        dialogues: [
          initial,
          for (var index = 0; index < 24; index++)
            ProjectDialogueEntry(
                id: 'unrelated-$index',
                name: 'Unrelated $index',
                relativePath: 'dialogues/unrelated-$index.yarn'),
        ],
      ),
    );
    addTearDown(f.dispose);
    var entry = await _localize(f, initial: initial);
    final source = await f.source.readAsString();
    final store = await CatalogStorageStore.open(projectRoot: f.directory.path);
    Future<CatalogObjectReference> documentRef(String field, String id) async {
      final snapshot =
          (await store.openRoot((await store.readHead())!)).snapshot;
      final address = (await snapshot
          .lookup(CatalogMetadataDocuments.documentKey(field, id)))!;
      final key = CatalogMetadataDocuments.definitionKey(
          field, address.payload['position'] as int);
      return (await snapshot.indexEntry(key))!.reference;
    }

    final scene = await documentRef('scenes', linked.id);
    final unrelated = await documentRef('dialogues', 'unrelated-23');
    final blockedReads = {
      for (final reference in [scene, unrelated])
        'catalog/objects/${reference.sha256}.json',
    };
    const action = 'dialogue.update';
    final handle = f.opened.projectHandle;
    for (final (index, text) in ['Good day', 'Good morning'].indexed) {
      final locale = entry.localization!;
      entry = entry.copyWith(
          localization: locale.translate(locale.units.single.id, 'en', text));
      final parameters = {'entry': entry.toJson()};
      reader.paths.clear();
      final snapshot = await f.api.readWorkshopSnapshot(handle,
          actionId: action, parameters: parameters);
      expect(reader.paths.where(blockedReads.contains), isEmpty);
      expect(snapshot.availableProjectDocuments, {
        'dialogues': {entry.id},
        'dialogueFolders': {'arrivals', 'stations'},
      });
      final operation = 'variant-$index';
      final plan = await f.api.planMutation(
          handle,
          AuthoringRequest(
              requestId: operation,
              actionId: action,
              actionVersion: 1,
              workspaceHandle: f.opened.workspaceHandle.value,
              expectedRevision: snapshot.revision,
              parameters: parameters,
              extensions: const {'workshopScope': true},
              idempotencyKey: operation));
      expect(plan.plan.changeSet.changes.map((change) => change.storageKey),
          [CatalogStorageStore.headStorageKey]);
      await f.api.apply(handle, planId: plan.planId, operationId: operation);
      final reread = await f.api.readWorkshopSnapshot(handle,
          actionId: action, parameters: parameters);
      expect(reread.manifest.dialogues.single, entry);
      expect(reader.paths.where(blockedReads.contains), isEmpty);
    }
    expect(await documentRef('scenes', linked.id), scene);
    expect(await documentRef('dialogues', 'unrelated-23'), unrelated);
    expect(await f.source.readAsString(), source);
    final reopened = await f.readApi.openProject(f.directory.path);
    addTearDown(() => f.readApi.closeWorkspace(reopened.workspaceHandle));
    final disk = await f.loader.load(reopened.projectHandle);
    expect(disk.manifest.dialogues.first, entry);
    expect(disk.manifest.scenes.single, linked);
    for (final text in [source, source.replaceFirst('Accueil', 'Autre')]) {
      final structural = await f.api.readWorkshopSnapshot(handle,
          actionId: action,
          parameters: {'entry': entry.toJson(), 'source': text});
      expect(structural.availableProjectDocuments?['scenes'], {linked.id});
    }
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
