import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('JSONL stages and imports project-owned item art', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final source = File('${fixture.root.path}/source.png');
    await source.writeAsBytes(_pngBytes);

    final staged = await fixture.request(
      'stage_artifact',
      args: {
        'sourcePath': source.path,
        'declaredMediaType': 'image/png',
      },
    );

    expect(staged.status, AuthoringResultStatus.success,
        reason: jsonEncode(staged.toJson()));
    expect(staged.data['artifactHandle'], startsWith('artifact://sha256/'));
    expect(staged.data['mediaType'], 'image/png');
    expect(jsonEncode(staged.toJson()), isNot(contains(source.path)));

    final opened = await fixture.open();
    final snapshot = await fixture.snapshots.load(opened.projectHandle);
    final planned = await fixture.request(
      'plan',
      args: {
        'projectHandle': opened.projectHandle.value,
        'request': AuthoringRequest(
          requestId: 'stage-import-request',
          actionId: 'asset.import_batch',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: {
            'entries': [
              {
                'artifactHandle': staged.data['artifactHandle'],
                'assetId': 'item-icon-potion',
                'logicalPath': 'data/pokemon/assets/items/potion.png',
              }
            ],
          },
          expectedRevision: snapshot.revision,
          idempotencyKey: 'stage-import-idempotency',
        ).toJson(),
      },
    );

    expect(planned.status, AuthoringResultStatus.success);
    final applied = await fixture.request('apply', args: {
      'projectHandle': opened.projectHandle.value,
      'planId': planned.data['planId'],
      'operationId': 'project-item-import',
    });
    expect(applied.status, AuthoringResultStatus.success);
    expect(
        await File('${fixture.root.path}/data/pokemon/assets/items/potion.png')
            .readAsBytes(),
        _pngBytes);
  });

  test('JSONL refuses artifact sources outside allowed roots', () async {
    final fixture = await _Fixture.create();
    final outside = await Directory.systemTemp.createTemp('artifact-outside-');
    addTearDown(fixture.dispose);
    addTearDown(() => outside.delete(recursive: true));
    final source = File('${outside.path}/source.png');
    await source.writeAsBytes(_pngBytes);

    final staged = await fixture.request(
      'stage_artifact',
      args: {'sourcePath': source.path},
    );

    expect(staged.status, AuthoringResultStatus.failure);
    expect(staged.error!.code, AuthoringErrorCode.permissionDenied);
    expect(
      staged.error!.details['domainCode'],
      'artifact.source_outside_allowed_roots',
    );
  });

  test('JSONL imports a custom capture PNG and updates its item reference',
      () async {
    final fixture = await _Fixture.create(capture: true);
    addTearDown(fixture.dispose);
    final bytes = image.encodePng(image.Image(width: 64, height: 2048));
    final source = File('${fixture.root.path}/capture.png');
    await source.writeAsBytes(bytes);
    final staged = await fixture.request('stage_artifact', args: {
      'sourcePath': source.path,
      'declaredMediaType': 'image/png',
    });
    expect(staged.status, AuthoringResultStatus.success);
    final opened = await fixture.open();
    const path = 'data/pokemon/assets/items/capture/custom.png';
    Future<void> apply(
        String action, Map<String, Object?> parameters, String id) async {
      final snapshot = await fixture.snapshots.load(opened.projectHandle);
      final planned =
          await fixture.request('plan', requestId: 'plan-$id', args: {
        'projectHandle': opened.projectHandle.value,
        'request': AuthoringRequest(
          requestId: id,
          actionId: action,
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: parameters,
          expectedRevision: snapshot.revision,
          idempotencyKey: id,
        ).toJson(),
      });
      expect(planned.status, AuthoringResultStatus.success,
          reason: jsonEncode(planned.toJson()));
      final applied =
          await fixture.request('apply', requestId: 'apply-$id', args: {
        'projectHandle': opened.projectHandle.value,
        'planId': planned.data['planId'],
        'operationId': id,
      });
      expect(applied.status, AuthoringResultStatus.success,
          reason: jsonEncode(applied.toJson()));
    }

    await apply(
        'asset.import_batch',
        {
          'entries': [
            {
              'artifactHandle': staged.data['artifactHandle'],
              'assetId': 'custom-capture-animation',
              'logicalPath': path,
              'usages': ['item:custom-ball'],
            }
          ],
        },
        'capture-import');
    final updated = _captureItem.copyWith(
        capture: _captureItem.capture!.copyWith(animationSpritePath: path));
    await apply(
        'item.update',
        {'itemId': _captureItem.id, 'definition': updated.toJson()},
        'capture-update');

    final snapshot = await fixture.snapshots.load(opened.projectHandle);
    expect(snapshot.itemCatalog!.entries.single, updated);
    expect(await File('${fixture.root.path}/$path').readAsBytes(), bytes);
    expect(
        (snapshot.itemCatalog!.entries.single.capture!
            .toJson())['animationSpritePath'],
        path);
  });

  test('JSONL replaces a staged unmanaged asset through the canonical action',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final rawAsset = File('${fixture.root.path}/assets/audio/pikachu.ogg');
    await rawAsset.parent.create(recursive: true);
    final beforeBytes = <int>[0x4f, 0x67, 0x67, 0x53, 0x00, 0x01];
    final afterBytes = <int>[0x4f, 0x67, 0x67, 0x53, 0x00, 0x02];
    await rawAsset.writeAsBytes(beforeBytes);
    final expectedSource = File('${fixture.root.path}/expected.ogg');
    final replacementSource = File('${fixture.root.path}/replacement.ogg');
    await expectedSource.writeAsBytes(beforeBytes);
    await replacementSource.writeAsBytes(afterBytes);

    final expected = await fixture.request(
      'stage_artifact',
      requestId: 'stage-expected',
      args: {
        'sourcePath': expectedSource.path,
        'declaredMediaType': 'audio/ogg',
      },
    );
    final replacement = await fixture.request(
      'stage_artifact',
      requestId: 'stage-replacement',
      args: {
        'sourcePath': replacementSource.path,
        'declaredMediaType': 'audio/ogg',
      },
    );
    final opened = await fixture.open();
    final snapshot = await fixture.snapshots.load(opened.projectHandle);

    final planned = await fixture.request(
      'plan',
      args: {
        'projectHandle': opened.projectHandle.value,
        'request': AuthoringRequest(
          requestId: 'jsonl-raw-replace',
          actionId: 'asset.raw.replace',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: {
            'logicalPath': 'assets/audio/pikachu.ogg',
            'expectedArtifactHandle': expected.data['artifactHandle'],
            'replacementArtifactHandle': replacement.data['artifactHandle'],
          },
          expectedRevision: snapshot.revision,
          idempotencyKey: 'jsonl-raw-replace-idempotency',
        ).toJson(),
      },
    );
    expect(planned.status, AuthoringResultStatus.success);

    final applied = await fixture.request(
      'apply',
      args: {
        'projectHandle': opened.projectHandle.value,
        'planId': planned.data['planId'],
        'operationId': 'jsonl-raw-replace-operation',
      },
    );
    expect(applied.status, AuthoringResultStatus.success);
    expect(await rawAsset.readAsBytes(), afterBytes);
  });

  test('JSONL preserves an unknown artifact domain error', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final opened = await fixture.open();
    final snapshot = await fixture.snapshots.load(opened.projectHandle);

    final planned = await fixture.request(
      'plan',
      args: {
        'projectHandle': opened.projectHandle.value,
        'request': AuthoringRequest(
          requestId: 'unknown-artifact-request',
          actionId: 'asset.import',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: const {
            'artifactHandle':
                'artifact://sha256/0000000000000000000000000000000000000000000000000000000000000000',
            'assetId': 'unknown-png',
            'logicalPath': 'images/unknown.png',
          },
          expectedRevision: snapshot.revision,
          idempotencyKey: 'unknown-artifact-idempotency',
        ).toJson(),
      },
    );

    expect(planned.status, AuthoringResultStatus.failure);
    expect(planned.error!.code, AuthoringErrorCode.notFound);
    expect(planned.error!.details['domainCode'], 'artifact.unknown');
  });
}

final class _Fixture {
  _Fixture({
    required this.root,
    required this.snapshots,
    required this.worker,
  });

  static Future<_Fixture> create({bool capture = false}) async {
    final root = await Directory.systemTemp.createTemp('jsonl-artifact-');
    final manifest = ProjectManifest(
      name: 'JSONL artifact fixture',
      version: ProjectVersion.v8,
      maps: const [],
      tilesets: const [],
      pokemon: capture
          ? const ProjectPokemonConfig(
              enabled: true,
              ruleset: PokemonRulesetProfile.pokeMapBetaV1,
              catalogFiles: {'items': 'data/pokemon/catalogs/items.json'},
            )
          : const ProjectPokemonConfig(
              ruleset: PokemonRulesetProfile.pokeMapBetaV1),
    );
    await File('${root.path}/project.json').writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(manifest.toJson())}\n',
    );
    if (capture) {
      final catalog = File('${root.path}/data/pokemon/catalogs/items.json');
      await catalog.parent.create(recursive: true);
      await catalog
          .writeAsString(jsonEncode(encodeProjectItemCatalog(ProjectItemCatalog(
        schemaVersion: 1,
        entries: const [_captureItem],
      ))));
    }
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final readApi = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      snapshotLoader: snapshots,
    );
    final artifacts = LocalArtifactStore(
      allowedSourceRoots: [root.path],
      maximumArtifactBytes: capture ? 1024 * 1024 : 1024,
    );
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      artifactStore: artifacts,
    );
    return _Fixture(
      root: root,
      snapshots: snapshots,
      worker: JsonlWorker(api: readApi, mutations: mutations),
    );
  }

  final Directory root;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;

  Future<OpenedProject> open() async {
    final result = await request(
      'open',
      args: {'projectRoot': root.path},
    );
    expect(result.status, AuthoringResultStatus.success);
    return OpenedProject(
      workspaceHandle:
          WorkspaceHandle(result.data['workspaceHandle']! as String),
      projectHandle: ProjectHandle(result.data['projectHandle']! as String),
      projectName: result.data['projectName']! as String,
      fingerprint: result.data['fingerprint']! as String,
      expiresAt: DateTime.parse(result.data['expiresAt']! as String),
    );
  }

  Future<AuthoringResult> request(
    String command, {
    Map<String, Object?> args = const {},
    String? requestId,
  }) async {
    final decoded = jsonDecode(
      await worker.processLine(
        jsonEncode({
          'id': requestId ?? 'request-$command',
          'command': command,
          'args': args,
        }),
      ),
    ) as Map<String, dynamic>;
    return AuthoringResult.fromJson(decoded);
  }

  Future<void> dispose() => root.delete(recursive: true);
}

const _captureItem = ProjectItemDefinition(
  id: 'custom-ball',
  displayName: 'Custom Ball',
  pocketId: 'balls',
  capture: ProjectCaptureItemDefinition(
    rateNumerator: 1,
    rateDenominator: 1,
    allowedEncounterKinds: {EncounterKind.walk},
  ),
);

const _pngBytes = <int>[
  0x89,
  0x50,
  0x4e,
  0x47,
  0x0d,
  0x0a,
  0x1a,
  0x0a,
  0x00,
];
