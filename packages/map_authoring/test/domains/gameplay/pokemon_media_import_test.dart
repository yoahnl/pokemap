import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
      'direct and JSONL batch import preserve choices, share files, and preview a no-op rerun',
      () async {
    for (final jsonl in [false, true]) {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final before = await fixture.media();
      final entries = fixture.entries();
      final plan = await fixture.plan(entries, jsonl: jsonl);
      final preview = (plan['plan'] as Map)['preview']! as Map;
      expect(preview['added'], hasLength(2));
      expect(preview['preserved'], hasLength(1));
      expect(preview['conflicts'], hasLength(1));
      await fixture.apply(plan, jsonl: jsonl);
      final after = await fixture.media();
      expect(after['defaultFormId'], before['defaultFormId']);
      final variant = (after['variants'] as Map)['base'] as Map;
      expect(variant['portrait'], 'assets/custom-portrait.png');
      expect(variant['frontStatic'], 'assets/battle-front.png');
      expect(variant['cry'], 'assets/cry.ogg');
      expect(variant['animations'],
          ((before['variants'] as Map)['base'] as Map)['animations']);
      expect(variant['party'], variant['icon']);
      expect(
          await File('${fixture.root.path}/${variant['icon']}').readAsBytes(),
          fixture.png);
      final catalog = AssetCatalog.fromJson(jsonDecode(
          await File('${fixture.root.path}/$assetCatalogStorageKey')
              .readAsString()) as Map<String, dynamic>);
      expect(catalog.records, hasLength(1));
      expect(
          await Directory('${fixture.root.path}/assets/.pokemap-store')
              .list()
              .length,
          1);
      final beforeRetryRevision =
          (await fixture.snapshots.load(fixture.opened.projectHandle)).revision;
      final retry = await fixture.plan(entries, jsonl: jsonl);
      expect(((retry['plan'] as Map)['preview'] as Map)['idempotent'], isTrue);
      expect(((retry['plan'] as Map)['preview'] as Map)['added'], isEmpty);
      expect(retry['applicable'], isFalse);
      expect(retry['nonApplicableReason'], 'no_changes');
      expect(await fixture.media(), after);
      expect(
          (await fixture.snapshots.load(fixture.opened.projectHandle)).revision,
          beforeRetryRevision);
      await expectLater(
          fixture.apply(retry),
          throwsA(isA<AuthoringPlanException>()
              .having((e) => e.code, 'code', 'plan.no_changes')));
    }
  });

  test('an existing logical menu image can be reused by a new role', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    await fixture.apply(await fixture.plan([fixture.entries().first]));
    final plan = await fixture.plan([fixture.entries()[1]]);
    final preview = (plan['plan'] as Map)['preview']! as Map;
    expect(preview['added'], hasLength(1));
    await fixture.apply(plan);
    final variant = ((await fixture.media())['variants'] as Map)['base'] as Map;
    expect(variant['party'], variant['icon']);
    expect(await File('${fixture.root.path}/${variant['party']}').readAsBytes(),
        fixture.png);
  });

  test(
      'a missing logical image is explicitly restored when associating a new role',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    await fixture.apply(await fixture.plan([fixture.entries().first]));
    final before = await fixture.media();
    final path = ((before['variants'] as Map)['base'] as Map)['icon'] as String;
    await File('${fixture.root.path}/$path').delete();
    final plan = await fixture.plan([fixture.entries()[1]]);
    final preview = (plan['plan'] as Map)['preview']! as Map;
    expect((preview['repaired'] as List).single,
        containsPair('logicalPath', path));
    expect(await File('${fixture.root.path}/$path').exists(), isFalse);
    final applied = await fixture.apply(plan);
    expect(await File('${fixture.root.path}/$path').readAsBytes(), fixture.png);
    final variant = ((await fixture.media())['variants'] as Map)['base'] as Map;
    expect(variant['party'], path);
    await fixture.mutations.undo(fixture.opened.projectHandle,
        entryId: (applied['receipt'] as Map)['receiptId'] as String,
        idempotencyKey: 'undo-logical-repair');
    expect(await File('${fixture.root.path}/$path').exists(), isFalse);
    expect(await fixture.media(), before);
  });

  test('logical image deletion and reappearance invalidate cached snapshots',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    await fixture.apply(await fixture.plan([fixture.entries().first]));
    final path = (((await fixture.media())['variants'] as Map)['base']
        as Map)['icon'] as String;
    final plan = await fixture.plan([fixture.entries()[1]]);
    await File('${fixture.root.path}/$path').delete();
    await expectLater(fixture.apply(plan), throwsA(anything));
    final absent = await fixture.snapshots.load(fixture.opened.projectHandle);
    await File('${fixture.root.path}/$path').writeAsBytes(fixture.png);
    final restored = await fixture.snapshots.load(fixture.opened.projectHandle);
    expect(restored.revision, isNot(absent.revision));
    await fixture.apply(await fixture.plan([fixture.entries()[1]]));
  });

  test('an authored change at a managed logical path is never overwritten',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    await fixture.apply(await fixture.plan([fixture.entries().first]));
    final before = await fixture.media();
    final path = ((before['variants'] as Map)['base'] as Map)['icon'] as String;
    final authored = image.encodePng(image.Image(width: 3, height: 3));
    await File('${fixture.root.path}/$path').writeAsBytes(authored);
    await expectLater(
        fixture.plan([fixture.entries()[1]]),
        throwsA(isA<AssetActionException>().having((error) => error.code,
            'code', 'pokemon.media.logical_asset_changed')));
    expect(await File('${fixture.root.path}/$path').readAsBytes(), authored);
    expect(await fixture.media(), before);
  });

  test(
      'refuses unknown species, forms, unsafe IDs, handles and truncated PNG without writes',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    for (final patch in <Map<String, Object?>>[
      {'speciesId': 'unknown'},
      {'formId': 'guessed'},
      {'speciesId': '../sproutle'},
      {'artifactHandle': 'unknown'},
      {'role': 'shiny'},
      {'logicalPath': '../escape.png'},
    ]) {
      final entry = {...fixture.entries().first, ...patch};
      await expectLater(fixture.plan([entry]), throwsA(anything));
    }
    final truncated = await fixture.artifacts
        .put(fixture.png.take(33).toList(), declaredMediaType: 'image/png');
    await expectLater(
        fixture.plan([
          {
            ...fixture.entries().first,
            'artifactHandle': truncated.reference.handle
          }
        ]),
        throwsA(anything));
    final text = await fixture.artifacts.put(utf8.encode('not an image'));
    await expectLater(
        fixture.plan([
          {...fixture.entries().first, 'artifactHandle': text.reference.handle}
        ]),
        throwsA(anything));
    expect(await File('${fixture.root.path}/$assetCatalogStorageKey').exists(),
        isFalse);
  });

  test(
      'a media document introduced after planning invalidates cached deletion and acknowledgement cannot bypass its references',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    await fixture.apply(await fixture.plan([fixture.entries().first]));
    final imported = await fixture.media();
    final path = ((imported['variants'] as Map)['base'] as Map)['icon'];
    ((imported['variants'] as Map)['base'] as Map)['icon'] = null;
    await fixture.writeMedia(imported);
    final catalog = AssetCatalog.fromJson(jsonDecode(
        await File('${fixture.root.path}/$assetCatalogStorageKey')
            .readAsString()) as Map<String, dynamic>);
    final assetId = catalog.records.single.id;
    final deletion =
        await fixture.planAction('asset.delete', {'assetId': assetId});
    await File('${fixture.root.path}/data/pokemon/media/unencountered.json')
        .writeAsString(jsonEncode(PokemonMediaFile(
      speciesId: 'unencountered',
      defaultFormId: 'base',
      variants: {'base': PokemonMediaVariant(icon: path as String)},
    ).toJson()));
    await expectLater(fixture.apply(deletion), throwsA(anything));
    await expectLater(
        fixture.planAction('asset.delete', {
          'assetId': assetId,
          'acknowledgedUsages': [
            r'pokemonMedia:unencountered:$.variants.base.icon'
          ],
        }),
        throwsA(isA<AssetActionException>()
            .having((e) => e.code, 'code', 'asset.references_blocking')));
    expect(await File('${fixture.root.path}/$path').exists(), isTrue);
  });

  test('malformed unencountered media blocks import and asset deletion',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    await fixture.apply(await fixture.plan([fixture.entries().first]));
    await File('${fixture.root.path}/data/pokemon/media/broken.json')
        .writeAsString('{broken');
    await expectLater(fixture.plan(fixture.entries()), throwsA(anything));
    final catalog = AssetCatalog.fromJson(jsonDecode(
        await File('${fixture.root.path}/$assetCatalogStorageKey')
            .readAsString()) as Map<String, dynamic>);
    await expectLater(
        fixture
            .planAction('asset.delete', {'assetId': catalog.records.single.id}),
        throwsA(isA<AssetActionException>()
            .having((e) => e.code, 'code', 'asset.media_inventory_invalid')));
  });

  test(
      'dry-run has no project writes and source handles can be reused for real plan',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final plan = await fixture.planAction(
        'pokemon.media.import', {'entries': fixture.entries()},
        dryRun: true);
    expect(plan['applicable'], isFalse);
    expect(await File('${fixture.root.path}/$assetCatalogStorageKey').exists(),
        isFalse);
    await fixture.apply(await fixture.plan(fixture.entries()));
    expect(await File('${fixture.root.path}/$assetCatalogStorageKey').exists(),
        isTrue);
  });
  test(
      'unreadable inventory blocks import and deletion instead of guessing that assets are unused',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    await fixture.apply(await fixture.plan([fixture.entries().first]));
    final catalog = AssetCatalog.fromJson(jsonDecode(
        await File('${fixture.root.path}/$assetCatalogStorageKey')
            .readAsString()) as Map<String, dynamic>);
    await Directory('${fixture.root.path}/data/pokemon/media')
        .delete(recursive: true);
    await File('${fixture.root.path}/data/pokemon/media')
        .writeAsString('not a directory');
    await expectLater(
        fixture.plan(fixture.entries()),
        throwsA(isA<AssetActionException>().having(
            (e) => e.code, 'code', 'pokemon.media.inventory_unavailable')));
    await expectLater(
        fixture
            .planAction('asset.delete', {'assetId': catalog.records.single.id}),
        throwsA(isA<AssetActionException>()
            .having((e) => e.code, 'code', 'asset.inventory_unavailable')));
  });

  test('batch undo restores the exact document and removes its assets',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final before = await File(
            '${fixture.root.path}/data/pokemon/media/sproutle-media.json')
        .readAsBytes();
    final applied = await fixture.apply(await fixture.plan(fixture.entries()));
    final receipt = applied['receipt'] as Map;
    final path = (((await fixture.media())['variants'] as Map)['base']
        as Map)['icon'] as String;
    await fixture.mutations.undo(fixture.opened.projectHandle,
        entryId: receipt['receiptId'] as String, idempotencyKey: 'undo-media');
    expect(
        await File(
                '${fixture.root.path}/data/pokemon/media/sproutle-media.json')
            .readAsBytes(),
        before);
    expect(await File('${fixture.root.path}/$path').exists(), isFalse);
    expect(await File('${fixture.root.path}/$assetCatalogStorageKey').exists(),
        isFalse);
  });
}

final class _Fixture {
  _Fixture(this.root, this.snapshots, this.reads, this.mutations,
      this.artifacts, this.opened, this.png, this.handle);

  final Directory root;
  final ProjectSnapshotLoader snapshots;
  final AuthoringReadApi reads;
  final LocalMapAuthoringMutationApi mutations;
  final MemoryArtifactStore artifacts;
  final OpenedProject opened;
  final List<int> png;
  final String handle;
  var sequence = 0;

  static Future<_Fixture> create() async {
    final root = await Directory.systemTemp.createTemp('pokemon-media-import-');
    for (final directory in ['species', 'media']) {
      await Directory('${root.path}/data/pokemon/$directory')
          .create(recursive: true);
    }
    await File('${root.path}/project.json').writeAsString(jsonEncode(
        const ProjectManifest(
            name: 'Media import fixture', maps: [], tilesets: []).toJson()));
    await File('${root.path}/data/pokemon/species/0001_numbered.json')
        .writeAsString(jsonEncode({
      'schemaVersion': currentPokemonDataSchemaVersion,
      'id': 'sproutle',
      'forms': {
        'formId': 'base',
        'otherForms': ['regional']
      },
      'refs': {'media': 'sproutle-media'},
    }));
    await File('${root.path}/data/pokemon/media/sproutle-media.json')
        .writeAsString(jsonEncode(const PokemonMediaFile(
      speciesId: 'sproutle-media',
      defaultFormId: 'regional',
      variants: {
        'base': PokemonMediaVariant(
            portrait: 'assets/custom-portrait.png',
            frontStatic: 'assets/battle-front.png',
            cry: 'assets/cry.ogg'),
        'regional': PokemonMediaVariant(icon: 'assets/regional.png'),
      },
    ).toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(
        handles: handles, snapshotCache: ProjectSnapshotCache());
    final reads = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: snapshots);
    final opened = await reads.openProject(root.path);
    final artifacts = MemoryArtifactStore(maximumArtifactBytes: 1024 * 1024);
    final png = image.encodePng(image.Image(width: 2, height: 2));
    final handle = (await artifacts.put(png, declaredMediaType: 'image/png'))
        .reference
        .handle;
    final mutations = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: snapshots,
        artifactStore: artifacts,
        dispatcher: MapMutationDispatcher.canonical(artifactStore: artifacts));
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _Fixture(
        root, snapshots, reads, mutations, artifacts, opened, png, handle);
  }

  List<Map<String, Object?>> entries() => [
        for (final role in PokemonMediaImportRole.values)
          PokemonMediaImportEntry(
                  speciesId: 'sproutle',
                  formId: 'base',
                  role: role,
                  artifactHandle: handle)
              .toJson()
      ];

  Future<Map<String, Object?>> plan(List<Map<String, Object?>> entries,
          {bool jsonl = false}) =>
      planAction('pokemon.media.import', {'entries': entries}, jsonl: jsonl);

  Future<Map<String, Object?>> planAction(
      String actionId, Map<String, Object?> parameters,
      {bool jsonl = false, bool dryRun = false}) async {
    final snapshot = await snapshots.load(opened.projectHandle);
    final request = AuthoringRequest(
        requestId: 'import-${sequence++}',
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        expectedRevision: snapshot.revision,
        dryRun: dryRun,
        idempotencyKey: 'import-$sequence',
        parameters: parameters);
    if (!jsonl) return mutations.plan(opened.projectHandle, request);
    return wire('plan', {
      'projectHandle': opened.projectHandle.value,
      'request': request.toJson()
    });
  }

  Future<Map<String, Object?>> apply(Map<String, Object?> plan,
      {bool jsonl = false}) async {
    final operation = 'media-operation-${sequence++}';
    if (!jsonl) {
      return mutations.apply(opened.projectHandle,
          planId: plan['planId'] as String, operationId: operation);
    }
    return wire('apply', {
      'projectHandle': opened.projectHandle.value,
      'planId': plan['planId'],
      'operationId': operation
    });
  }

  Future<Map<String, Object?>> wire(
      String command, Map<String, Object?> args) async {
    final worker = JsonlWorker(api: reads, mutations: mutations);
    final response = await worker.processLine(
        jsonEncode({'id': 'media-$command', 'command': command, 'args': args}));
    final result =
        AuthoringResult.fromJson(jsonDecode(response) as Map<String, dynamic>);
    expect(result.status, AuthoringResultStatus.success, reason: response);
    return result.data;
  }

  Future<Map<String, dynamic>> media() async => jsonDecode(
      await File('${root.path}/data/pokemon/media/sproutle-media.json')
          .readAsString()) as Map<String, dynamic>;
  Future<void> writeMedia(Map<String, dynamic> value) =>
      File('${root.path}/data/pokemon/media/sproutle-media.json')
          .writeAsString(jsonEncode(value))
          .then((_) {});
  Future<void> dispose() async => root.delete(recursive: true);
}
