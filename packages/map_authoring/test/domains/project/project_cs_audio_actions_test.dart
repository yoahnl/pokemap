import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('JSONL configures CS and sound with discoverable scoped revisions',
      () async {
    final h = await _ProjectSettingsHarness.create();
    addTearDown(h.dispose);
    for (final action in [
      (
        'field_ability.configure',
        'fieldAbilityConfiguration',
        <String, Object?>{'abilityId': 'dive', 'enabled': false}
      ),
      (
        'project.audio.cue.configure',
        'projectAudio',
        <String, Object?>{
          'cueId': 'ui.confirm',
          'binding': {'source': 'silent', 'gain': 1.0}
        }
      ),
    ]) {
      final current = await h.wire('query', {
        'projectHandle': h.opened.projectHandle.value,
        'request': AuthoringQueryRequest(
                resourceKind: action.$2,
                operation: AuthoringQueryOperation.get,
                ids: const ['project'],
                extensions: {'actionId': action.$1, 'parameters': action.$3})
            .toJson()
      });
      final id = 'jsonl-${h.sequence++}';
      final planned = await h.wire('plan', {
        'projectHandle': h.opened.projectHandle.value,
        'request': AuthoringRequest(
                requestId: id,
                idempotencyKey: id,
                workspaceHandle: h.opened.workspaceHandle.value,
                actionId: action.$1,
                actionVersion: 1,
                expectedRevision: current['snapshotRevision']! as String,
                parameters: action.$3)
            .toJson()
      });
      await h.wire('apply', {
        'projectHandle': h.opened.projectHandle.value,
        'planId': planned['planId'],
        'operationId': 'apply-$id'
      });
    }
    final settings = (await h.document())['settings'] as Map;
    expect(settings['fieldAbilities'], {
      'disabledAbilities': ['dive']
    });
    expect(settings['audio'], {
      'cues': {
        'ui.confirm': {'source': 'silent', 'gain': 1.0}
      }
    });
  });
  test('CS settings disable Dive without changing Surf or opening maps',
      () async {
    final h = await _ProjectSettingsHarness.create();
    addTearDown(h.dispose);
    await h.mutate(
        'field_ability.configure', {'abilityId': 'dive', 'enabled': false});
    final settings = (await h.document())['settings'] as Map;
    expect(settings['fieldAbilities'], {
      'disabledAbilities': ['dive']
    });
    expect(settings['surf'], {
      'enabled': true,
      'requiresKnownMove': false,
      'accessMode': 'always',
      'speedCellsPerSecond': 4.0
    });
    expect((await h.document())['customExtension'], {'preserve': true});
    await h.mutate(
        'field_ability.configure', {'abilityId': 'dive', 'enabled': true});
    expect(
        ((await h.document())['settings'] as Map).containsKey('fieldAbilities'),
        isFalse);
  });

  test('audio cue settings distinguish silent, default gain and inheritance',
      () async {
    final h = await _ProjectSettingsHarness.create();
    addTearDown(h.dispose);
    await h.mutate('project.audio.cue.configure', {
      'cueId': 'door.open',
      'binding': {'source': 'silent', 'gain': 1.0},
    });
    expect(
        (((await h.document())['settings'] as Map)['audio'] as Map)['cues'], {
      'door.open': {'source': 'silent', 'gain': 1.0},
    });
    await h.mutate('project.audio.cue.configure', {
      'cueId': 'door.open',
      'binding': {'source': 'builtin', 'gain': .5},
    });
    expect(
        (((await h.document())['settings'] as Map)['audio'] as Map)['cues'], {
      'door.open': {'source': 'builtin', 'gain': .5},
    });
    await h.mutate(
        'project.audio.cue.configure', {'cueId': 'door.open', 'binding': null});
    expect(((await h.document())['settings'] as Map).containsKey('audio'),
        isFalse);
  });
  test('custom sound selects its audio definition without opening maps',
      () async {
    final h = await _ProjectSettingsHarness.create();
    addTearDown(h.dispose);
    final file = File('${h.root.path}/assets/.pokemap-media.json');
    await file.parent.create();
    final audio = ProjectMediaAsset(
        id: 'bell',
        label: 'Bell',
        kind: ProjectMediaKind.audio,
        sourceAssetId: 'bell-audio',
        technicalMetadata: ProjectMediaTechnicalMetadata(
            mediaType: 'audio/wav',
            container: 'wav',
            codec: 'pcm',
            sizeBytes: 3));
    await file.writeAsString(jsonEncode({
      'schemaVersion': 1,
      'entries': [
        audio.toJson(),
        for (var i = 0; i < 2000; i++)
          {'id': 'unrelated-$i', 'kind': 'future-unrelated-definition'},
      ]
    }));
    final source = AssetRecord(
        id: 'bell-audio',
        logicalPath: 'assets/audio/bell.wav',
        artifact:
            ContentArtifactRef.fromBytes([1, 2, 3], mediaType: 'audio/wav'));
    await File('${h.root.path}/$assetCatalogStorageKey')
        .writeAsString(jsonEncode({
      'schemaVersion': 1,
      'records': [
        source.toJson(),
        for (var i = 0; i < 2000; i++)
          {'id': 'unrelated-$i', 'logicalPath': 'Unrelated invalid source'},
      ]
    }));
    await h.mutate('project.audio.cue.configure', {
      'cueId': 'door.open',
      'binding': {'source': 'custom', 'mediaId': 'bell', 'gain': .6},
    });
    expect(
        (((await h.document())['settings'] as Map)['audio'] as Map)['cues'], {
      'door.open': {'source': 'custom', 'mediaId': 'bell', 'gain': .6},
    });
  });
  test('custom audio rejects a missing source without changing settings',
      () async {
    final h = await _ProjectSettingsHarness.create();
    addTearDown(h.dispose);
    final file = File('${h.root.path}/$projectMediaCatalogStorageKey');
    await file.parent.create();
    await file.writeAsString(jsonEncode(ProjectMediaCatalog(entries: [
      ProjectMediaAsset(
        id: 'missing-source',
        label: 'Broken',
        kind: ProjectMediaKind.audio,
        sourceAssetId: 'missing',
      )
    ]).toJson()));
    final before = await h.document();
    await expectLater(
        h.mutate('project.audio.cue.configure', {
          'cueId': 'door.open',
          'binding': {
            'source': 'custom',
            'mediaId': 'missing-source',
            'gain': .5
          },
        }),
        throwsFormatException);
    expect(await h.document(), before);
  });
  test('audio library pages metadata without opening unrelated maps', () async {
    final h = await _ProjectSettingsHarness.create();
    addTearDown(h.dispose);
    final file = File('${h.root.path}/assets/.pokemap-media.json');
    await file.parent.create();
    await file.writeAsString(jsonEncode(ProjectMediaCatalog(entries: [
      ProjectMediaAsset(
          id: 'bell',
          label: 'Bell',
          kind: ProjectMediaKind.audio,
          sourceAssetId: 'a'),
      ProjectMediaAsset(
          id: 'rain',
          label: 'Rain',
          kind: ProjectMediaKind.audio,
          sourceAssetId: 'b'),
      ProjectMediaAsset(
          id: 'picture',
          label: 'Picture',
          kind: ProjectMediaKind.image,
          sourceAssetId: 'c'),
    ]).toJson()));
    final first = await h.read.queryProject(
        h.opened.projectHandle,
        AuthoringQueryRequest(
            resourceKind: 'presentationMedia',
            operation: AuthoringQueryOperation.list,
            filters: const {'kind': 'audio'},
            pageSize: 1));
    expect(first.items.single['id'], 'bell');
    expect(first.totalAvailable, 2);
    expect(first.nextCursor, isNotNull);
    final second = await h.read.queryProject(
        h.opened.projectHandle,
        AuthoringQueryRequest(
            resourceKind: 'presentationMedia',
            operation: AuthoringQueryOperation.list,
            filters: const {'kind': 'audio'},
            pageSize: 1,
            cursor: first.nextCursor));
    expect(second.items.single['id'], 'rain');
    expect(second.nextCursor, isNull);
  });

  test('native 2D keeps its format while saving CS and sound settings',
      () async {
    final h =
        await _ProjectSettingsHarness.create(dimension: ProjectDimension.twoD);
    addTearDown(h.dispose);
    await h.mutate(
        'field_ability.configure', {'abilityId': 'dive', 'enabled': false});
    await h.mutate('project.audio.cue.configure', {
      'cueId': 'ui.confirm',
      'binding': {'source': 'silent', 'gain': 1.0},
    });
    final project = ProjectManifest.fromJson(await h.document());
    expect(project.version, ProjectVersion.v8);
    expect(project.settings.dimension, ProjectDimension.twoD);
    expect(project.settings.fieldAbilities!.disabledAbilities,
        {FieldAbility.dive});
    expect(project.settings.audio!.bindingFor(ProjectSoundCue.uiConfirm).source,
        ProjectSoundSource.silent);
  });
}

final class _ProjectSettingsHarness {
  _ProjectSettingsHarness(
      this.root, this.file, this.api, this.read, this.opened);
  final Directory root;
  final File file;
  final LocalMapAuthoringMutationApi api;
  final AuthoringReadApi read;
  final OpenedProject opened;
  var sequence = 0;

  static Future<_ProjectSettingsHarness> create(
      {ProjectDimension dimension = ProjectDimension.threeD}) async {
    final root = await Directory.systemTemp.createTemp('project-cs-audio-');
    final file = File('${root.path}/project.json');
    final json = ProjectManifest(
            version: dimension == ProjectDimension.twoD
                ? ProjectVersion.v8
                : ProjectVersion.v9,
            name: 'Generic game',
            maps: const [
              ProjectMapEntry(
                  id: 'unrelated',
                  name: 'Unrelated',
                  relativePath: 'maps/absent.json')
            ],
            tilesets: const [],
            settings: ProjectSettings(
                dimension: dimension,
                spatialCamera: dimension == ProjectDimension.threeD
                    ? SpatialCameraProfile()
                    : null,
                surf: ProjectSurfSettings(
                    requiresKnownMove: false,
                    accessMode: ProjectSurfAccessMode.always)))
        .toJson();
    json['customExtension'] = {'preserve': true};
    await file.writeAsString(jsonEncode(json));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final service = ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        workshopScope: true);
    final read =
        AuthoringReadApi(openService: service, snapshotLoader: snapshots);
    final opened = await read.openProject(root.path);
    final api =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    await api.prepareWorkshopCatalog(opened.projectHandle);
    return _ProjectSettingsHarness(root, file, api, read, opened);
  }

  Future<Map<String, dynamic>> document() async =>
      jsonDecode(await file.readAsString()) as Map<String, dynamic>;

  Future<Map<String, Object?>> wire(
      String command, Map<String, Object?> args) async {
    final worker = JsonlWorker(api: read, mutations: api);
    final raw = await worker.processLine(jsonEncode(
        {'id': 'wire-${sequence++}', 'command': command, 'args': args}));
    final result =
        AuthoringResult.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    expect(result.status, AuthoringResultStatus.success, reason: raw);
    return result.data;
  }

  Future<void> mutate(String action, Map<String, Object?> parameters) async {
    final scoped = await api.readWorkshopSnapshot(opened.projectHandle,
        actionId: action, parameters: parameters);
    final requestId = 'request-${sequence++}';
    final plan = await api.plan(
        opened.projectHandle,
        AuthoringRequest(
            requestId: requestId,
            workspaceHandle: opened.workspaceHandle.value,
            actionId: action,
            actionVersion: 1,
            idempotencyKey: requestId,
            expectedRevision: scoped.revision,
            parameters: parameters));
    await api.apply(opened.projectHandle,
        planId: plan['planId']! as String,
        operationId: 'operation-${sequence++}');
  }

  Future<void> dispose() async {
    await api.detachWorkspace(opened.workspaceHandle);
    await read.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}
