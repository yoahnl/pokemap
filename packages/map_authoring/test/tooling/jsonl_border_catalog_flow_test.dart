import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

typedef _ApplyAction = Future<Map<String, Object?>> Function({
  required String actionId,
  required Map<String, Object?> parameters,
  required String sequence,
});

void main() {
  test('Border blueprint lifecycle is byte-identical through direct and JSONL',
      () async {
    final direct = await _Harness.create('direct');
    final jsonl = await _Harness.create('jsonl');
    addTearDown(direct.dispose);
    addTearDown(jsonl.dispose);

    final directReceipts = await direct.runDirectLifecycle();
    final jsonlReceipts = await jsonl.runJsonlLifecycle();

    expect(directReceipts, jsonlReceipts);
    expect(await direct.projectBytes(), await jsonl.projectBytes());
    for (final resourceKind in <String>[
      'borderBlueprint',
      'borderSnapshot',
    ]) {
      final directQuery = await direct.queryDirect(resourceKind);
      final jsonlQuery = await jsonl.queryJsonl(resourceKind);
      expect(directQuery['items'], jsonlQuery['items']);
      expect(directQuery['totalAvailable'], 1);
    }

    final manifest = ProjectManifest.fromJson(
      jsonDecode(utf8.decode(await direct.projectBytes()))
          as Map<String, dynamic>,
    );
    expect(manifest.borderCatalog.records, hasLength(1));
    final record = manifest.borderCatalog.records.single;
    expect(record.id, 'fence');
    expect(record.latestPublished?.revision, 1);
    expect(record.isDeprecated, isTrue);
    expect(manifest.borderCatalog.visualSnapshots, hasLength(1));
  });

  test('JSONL rejects disconnected anchors then receipts the repaired publish',
      () async {
    final harness = await _Harness.create('jsonl-connected-anchor-repair');
    addTearDown(harness.dispose);
    final opened = await harness._jsonl('open', <String, Object?>{
      'projectRoot': harness.root.path,
    });
    final project = opened['projectHandle']! as String;
    final workspace = opened['workspaceHandle']! as String;
    final artifactHandles = <BorderPrimitiveRole, String>{};
    for (final role in _networkRoles) {
      final artifact = await harness.mutations.artifacts.put(
        _networkPngBytes(role),
        declaredMediaType: 'image/png',
      );
      artifactHandles[role] = artifact.reference.handle;
    }

    Future<Map<String, Object?>> apply({
      required String actionId,
      required Map<String, Object?> parameters,
      required String sequence,
    }) async {
      final validation = await harness._jsonl('validate', <String, Object?>{
        'projectHandle': project,
      });
      final plan = await harness._jsonl('plan', <String, Object?>{
        'projectHandle': project,
        'request': _request(
          workspaceHandle: workspace,
          revision: validation['snapshotRevision']! as String,
          actionId: actionId,
          parameters: parameters,
          sequence: sequence,
        ).toJson(),
      });
      return harness._jsonl('apply', <String, Object?>{
        'projectHandle': project,
        'planId': plan['planId'],
        'operationId': 'operation-$sequence',
      });
    }

    await apply(
      actionId: 'border.blueprint.draft.upsert',
      parameters: <String, Object?>{
        'record': encodeBorderBlueprintRecordJson(
          _networkRecord(centered: false),
          formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
        ),
      },
      sequence: 'upsert-disconnected-fence',
    );
    final validation = await harness._jsonl('validate', <String, Object?>{
      'projectHandle': project,
    });
    final rejected = AuthoringResult.fromJson(
      jsonDecode(
        await harness.worker.processLine(
          jsonEncode(<String, Object?>{
            'id': 'border-plan-disconnected',
            'command': 'plan',
            'args': <String, Object?>{
              'projectHandle': project,
              'request': _request(
                workspaceHandle: workspace,
                revision: validation['snapshotRevision']! as String,
                actionId: 'border.blueprint.publish',
                parameters: _networkPublishParameters(artifactHandles),
                sequence: 'publish-disconnected-fence',
              ).toJson(),
            },
          }),
        ),
      ) as Map<String, dynamic>,
    );
    expect(rejected.status, AuthoringResultStatus.failure);
    expect(
      rejected.error?.details['domainCode'],
      'border.blueprint.publication_invalid',
    );
    final diagnostics = rejected.error?.details['diagnostics']! as List;
    expect(
      diagnostics.whereType<Map>().map((diagnostic) => diagnostic['code']),
      contains('border.publication.connected_line_disconnected'),
    );

    final repaired = await apply(
      actionId: 'border.blueprint.draft.upsert',
      parameters: <String, Object?>{
        'record': encodeBorderBlueprintRecordJson(
          _networkRecord(centered: true),
          formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
        ),
      },
      sequence: 'repair-fence',
    );
    final published = await apply(
      actionId: 'border.blueprint.publish',
      parameters: _networkPublishParameters(artifactHandles),
      sequence: 'publish-repaired-fence',
    );
    expect((repaired['receipt']! as Map)['status'], 'applied');
    expect((published['receipt']! as Map)['status'], 'applied');

    final manifest = ProjectManifest.fromJson(
      jsonDecode(utf8.decode(await harness.projectBytes()))
          as Map<String, dynamic>,
    );
    final revision = manifest.borderCatalog.records.single.latestPublished!;
    expect(revision.revision, 1);
    expect(
      revision.definition.primitives.map((primitive) => primitive.anchorPx),
      everyElement(const BorderPixelPos(x: 16, y: 16)),
    );
    final gallery = resolveBorderCanonicalGallery(
      blueprintId: 'fence',
      blueprintRevision: revision,
      visualSnapshots: manifest.borderCatalog.visualSnapshots,
      tileSizePx: GridSize(
        width: manifest.settings.tileWidth,
        height: manifest.settings.tileHeight,
      ),
    );
    final sBend = gallery.report.samples.singleWhere(
      (sample) => sample.galleryCase == BorderCanonicalGalleryCase.sBend,
    );
    expect(
      sBend.coverageChecks.map((check) => check.longestContiguousGapPx),
      everyElement(lessThanOrEqualTo(1)),
    );
  });
}

final class _Harness {
  const _Harness({
    required this.root,
    required this.readApi,
    required this.mutations,
    required this.snapshots,
    required this.worker,
  });

  final Directory root;
  final AuthoringReadApi readApi;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;

  static Future<_Harness> create(String suffix) async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap-border-catalog-$suffix-',
    );
    final manifest = ProjectManifest(
      name: 'Border catalog transport fixture',
      version: ProjectVersion.v6,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      elements: const <ProjectElementEntry>[
        ProjectElementEntry(
          id: 'fence-element',
          name: 'Fence element',
          tilesetId: 'tileset',
          categoryId: 'border',
          frames: <TilesetVisualFrame>[
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0),
            ),
          ],
        ),
      ],
      borderCatalog: ProjectBorderCatalog(
        formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
        records: const <BorderBlueprintRecord>[],
      ),
    );
    await File('${root.path}/project.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      flush: true,
    );

    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: <String>[root.path],
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
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
    );
    return _Harness(
      root: root,
      readApi: readApi,
      mutations: mutations,
      snapshots: snapshots,
      worker: JsonlWorker(api: readApi, mutations: mutations),
    );
  }

  Future<List<Map<String, Object?>>> runDirectLifecycle() async {
    final opened = await readApi.open(root.path);
    final project = ProjectHandle(opened['projectHandle']! as String);
    final workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: workspace,
      projectHandle: project,
    );
    final artifact = await mutations.artifacts.put(
      _pngBytes,
      declaredMediaType: 'image/png',
    );

    Future<Map<String, Object?>> apply({
      required String actionId,
      required Map<String, Object?> parameters,
      required String sequence,
    }) async {
      final snapshot = await snapshots.load(project);
      final plan = await mutations.plan(
        project,
        _request(
          workspaceHandle: workspace.value,
          revision: snapshot.revision,
          actionId: actionId,
          parameters: parameters,
          sequence: sequence,
        ),
      );
      final confirmation = _requiresConfirmation(actionId)
          ? await mutations.confirm(
              project,
              planId: plan['planId']! as String,
            )
          : null;
      return mutations.apply(
        project,
        planId: plan['planId']! as String,
        operationId: 'operation-$sequence',
        confirmationToken: confirmation?['confirmationToken'] as String?,
      );
    }

    return _runLifecycle(
      apply: apply,
      artifactHandle: artifact.reference.handle,
    );
  }

  Future<List<Map<String, Object?>>> runJsonlLifecycle() async {
    final opened = await _jsonl('open', <String, Object?>{
      'projectRoot': root.path,
    });
    final project = opened['projectHandle']! as String;
    final workspace = opened['workspaceHandle']! as String;
    final artifact = await mutations.artifacts.put(
      _pngBytes,
      declaredMediaType: 'image/png',
    );

    Future<Map<String, Object?>> apply({
      required String actionId,
      required Map<String, Object?> parameters,
      required String sequence,
    }) async {
      final validation = await _jsonl('validate', <String, Object?>{
        'projectHandle': project,
      });
      final plan = await _jsonl('plan', <String, Object?>{
        'projectHandle': project,
        'request': _request(
          workspaceHandle: workspace,
          revision: validation['snapshotRevision']! as String,
          actionId: actionId,
          parameters: parameters,
          sequence: sequence,
        ).toJson(),
      });
      final confirmation = _requiresConfirmation(actionId)
          ? await _jsonl('confirm', <String, Object?>{
              'projectHandle': project,
              'planId': plan['planId'],
            })
          : null;
      return _jsonl('apply', <String, Object?>{
        'projectHandle': project,
        'planId': plan['planId'],
        'operationId': 'operation-$sequence',
        if (confirmation != null)
          'confirmationToken': confirmation['confirmationToken'],
      });
    }

    return _runLifecycle(
      apply: apply,
      artifactHandle: artifact.reference.handle,
    );
  }

  Future<Map<String, Object?>> _jsonl(
    String command,
    Map<String, Object?> args,
  ) async {
    final result = AuthoringResult.fromJson(
      jsonDecode(
        await worker.processLine(
          jsonEncode(<String, Object?>{
            'id': 'border-$command',
            'command': command,
            'args': args,
          }),
        ),
      ) as Map<String, dynamic>,
    );
    expect(
      result.status,
      AuthoringResultStatus.success,
      reason: result.error?.toJson().toString(),
    );
    return result.data;
  }

  Future<Map<String, Object?>> queryDirect(String resourceKind) async {
    final opened = await readApi.open(root.path);
    return readApi.query(
      ProjectHandle(opened['projectHandle']! as String),
      AuthoringQueryRequest(
        resourceKind: resourceKind,
        operation: AuthoringQueryOperation.list,
        view: AuthoringQueryView.detail,
      ),
    );
  }

  Future<Map<String, Object?>> queryJsonl(String resourceKind) async {
    final opened = await _jsonl('open', <String, Object?>{
      'projectRoot': root.path,
    });
    return _jsonl('query', <String, Object?>{
      'projectHandle': opened['projectHandle'],
      'request': AuthoringQueryRequest(
        resourceKind: resourceKind,
        operation: AuthoringQueryOperation.list,
        view: AuthoringQueryView.detail,
      ).toJson(),
    });
  }

  Future<List<int>> projectBytes() =>
      File('${root.path}/project.json').readAsBytes();

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

Future<List<Map<String, Object?>>> _runLifecycle({
  required _ApplyAction apply,
  required String artifactHandle,
}) async {
  final results = <Map<String, Object?>>[];
  results.add(
    await apply(
      actionId: 'border.blueprint.draft.upsert',
      parameters: <String, Object?>{
        'record': encodeBorderBlueprintRecordJson(
          _record(id: 'fence', primitives: _primitives()),
          formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
        ),
      },
      sequence: 'upsert-fence',
    ),
  );
  results.add(
    await apply(
      actionId: 'border.blueprint.draft.upsert',
      parameters: <String, Object?>{
        'record': encodeBorderBlueprintRecordJson(
          _record(id: 'scratch'),
          formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
        ),
      },
      sequence: 'upsert-scratch',
    ),
  );
  results.add(
    await apply(
      actionId: 'border.blueprint.delete',
      parameters: const <String, Object?>{'blueprintId': 'scratch'},
      sequence: 'delete-scratch',
    ),
  );
  results.add(
    await apply(
      actionId: 'border.blueprint.publish',
      parameters: <String, Object?>{
        'blueprintId': 'fence',
        'acceptedWarningCodes': const <String>[
          'border.publication.coverage_overlap_exceeded',
        ],
        'primitiveSources': <Object?>[
          for (final primitive in _primitives())
            <String, Object?>{
              'primitiveId': primitive.id,
              'frames': <Object?>[
                <String, Object?>{
                  'artifactHandle': artifactHandle,
                  'sourceProjectRelativePath': 'assets/tilesets/fence.png',
                },
              ],
            },
        ],
      },
      sequence: 'publish-fence',
    ),
  );
  results.add(
    await apply(
      actionId: 'border.blueprint.set_deprecated',
      parameters: const <String, Object?>{
        'blueprintId': 'fence',
        'isDeprecated': true,
      },
      sequence: 'deprecate-fence',
    ),
  );
  return results
      .map((result) => _stableReceipt(result['receipt']! as Map))
      .toList(growable: false);
}

AuthoringRequest _request({
  required String workspaceHandle,
  required String revision,
  required String actionId,
  required Map<String, Object?> parameters,
  required String sequence,
}) =>
    AuthoringRequest(
      requestId: 'request-$sequence',
      actionId: actionId,
      actionVersion: 1,
      workspaceHandle: workspaceHandle,
      parameters: parameters,
      expectedRevision: revision,
      idempotencyKey: 'idempotency-$sequence',
    );

Map<String, Object?> _stableReceipt(Map receipt) => <String, Object?>{
      'requestId': receipt['requestId'],
      'actionId': receipt['actionId'],
      'actionVersion': receipt['actionVersion'],
      'status': receipt['status'],
      'beforeRevision': receipt['beforeRevision'],
      'afterRevision': receipt['afterRevision'],
      'diff': receipt['diff'],
      'affectedResources': receipt['affectedResources'],
    };

bool _requiresConfirmation(String actionId) =>
    actionId == 'border.blueprint.delete' ||
    actionId == 'border.blueprint.set_deprecated';

BorderBlueprintRecord _record({
  required String id,
  List<BorderPrimitiveDraft> primitives = const <BorderPrimitiveDraft>[],
  int gapTolerancePx = 0,
}) =>
    BorderBlueprintRecord(
      id: id,
      draft: BorderBlueprintDraft(
        baseRevision: 0,
        definition: BorderBlueprintDraftDefinition(
          name: id == 'fence' ? 'Fence' : 'Scratch',
          previewSeed: BorderSignedInt64.zero,
          template: BorderBlueprintTemplate.connectedLine,
          primitives: primitives,
          defaults: BorderGenerationParams(
            irregularityPermille: 0,
            detailDensityPermille: 0,
            variationPermille: 0,
            maxOverlapPx: 8,
            gapTolerancePx: gapTolerancePx,
            depthRows: 1,
            allowAutoRotation: false,
          ),
          sortOrder: 0,
        ),
      ),
    );

List<BorderPrimitiveDraft> _primitives() {
  final metrics = const CanonicalBorderSnapshotCompiler().prepare(
    sourceElementId: 'fence-element',
    anchorPx: const BorderPixelPos(x: 16, y: 16),
    frames: <CanonicalBorderSourceFrame>[
      CanonicalBorderSourceFrame(
        sourceProjectRelativePath: 'assets/tilesets/fence.png',
        encodedImageBytes: _pngBytes,
      ),
    ],
  ).metrics;
  return <BorderPrimitiveDraft>[
    for (final role in <BorderPrimitiveRole>[
      BorderPrimitiveRole.lineCap,
      BorderPrimitiveRole.lineStraight,
      BorderPrimitiveRole.lineCorner,
    ])
      BorderPrimitiveDraft(
        id: role.name,
        sourceElementId: 'fence-element',
        role: role,
        weight: 1000,
        anchorPx: const BorderPixelPos(x: 16, y: 16),
        transforms: BorderTransformPolicy(
          allowedQuarterTurns: <int>[0, 1, 2, 3],
          allowFlipX: true,
        ),
        currentMetrics: metrics,
      ),
  ];
}

final List<int> _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAASUlEQVR42mNkoAA4LEj4D2MfSFjASI4ZTAwDDEYdMOqAUQeMOmDUAaMOGHAHMCJXqaNRMCBRMNoiGnXAqANGHTDqgFEHjHgHAADb/Qp9KEMvVQAAAABJRU5ErkJggg==',
);

const List<BorderPrimitiveRole> _networkRoles = <BorderPrimitiveRole>[
  BorderPrimitiveRole.lineCap,
  BorderPrimitiveRole.lineStraight,
  BorderPrimitiveRole.lineCorner,
];

BorderBlueprintRecord _networkRecord({required bool centered}) {
  const oldAnchors = <BorderPrimitiveRole, BorderPixelPos>{
    BorderPrimitiveRole.lineCap: BorderPixelPos(x: 22, y: 30),
    BorderPrimitiveRole.lineStraight: BorderPixelPos(x: 16, y: 31),
    BorderPrimitiveRole.lineCorner: BorderPixelPos(x: 11, y: 31),
  };
  return _record(
    id: 'fence',
    gapTolerancePx: 1,
    primitives: <BorderPrimitiveDraft>[
      for (final role in _networkRoles)
        _networkPrimitive(
          role,
          centered ? const BorderPixelPos(x: 16, y: 16) : oldAnchors[role]!,
        ),
    ],
  );
}

BorderPrimitiveDraft _networkPrimitive(
  BorderPrimitiveRole role,
  BorderPixelPos anchorPx,
) {
  final metrics = const CanonicalBorderSnapshotCompiler().prepare(
    sourceElementId: 'fence-element',
    anchorPx: anchorPx,
    frames: <CanonicalBorderSourceFrame>[
      CanonicalBorderSourceFrame(
        sourceProjectRelativePath: 'assets/tilesets/${role.name}.png',
        encodedImageBytes: _networkPngBytes(role),
      ),
    ],
  ).metrics;
  return BorderPrimitiveDraft(
    id: role.name,
    sourceElementId: 'fence-element',
    role: role,
    weight: 1000,
    anchorPx: anchorPx,
    transforms: BorderTransformPolicy(
      allowedQuarterTurns: const <int>[0, 1, 2, 3],
      allowFlipX: true,
    ),
    currentMetrics: metrics,
  );
}

Map<String, Object?> _networkPublishParameters(
  Map<BorderPrimitiveRole, String> artifactHandles,
) =>
    <String, Object?>{
      'blueprintId': 'fence',
      'acceptedWarningCodes': const <String>[
        'border.publication.coverage_gap_exceeded',
        'border.publication.coverage_overlap_exceeded',
      ],
      'primitiveSources': <Object?>[
        for (final role in _networkRoles)
          <String, Object?>{
            'primitiveId': role.name,
            'frames': <Object?>[
              <String, Object?>{
                'artifactHandle': artifactHandles[role]!,
                'sourceProjectRelativePath': 'assets/tilesets/${role.name}.png',
              },
            ],
          },
      ],
    };

List<int> _networkPngBytes(BorderPrimitiveRole role) {
  return base64Decode(
    switch (role) {
      BorderPrimitiveRole.lineCap =>
        'iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAJElEQVR4nO3OMQEAMAwDoMy/52YyehQUkAAA171pu50AALLpAyfLA/1kAjtgAAAAAElFTkSuQmCC',
      BorderPrimitiveRole.lineStraight =>
        'iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAIklEQVR4nO3OMQEAAAgDoNk/9IzhISQgAQC+m7a9TgAAubQv2gP+3hBDrgAAAABJRU5ErkJggg==',
      BorderPrimitiveRole.lineCorner =>
        'iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAARUlEQVR4nO2WsQnAAAzDVP//s3tEBlMq7QGBAgkcadvLfBgTBTDBmCiACcZEAf6e4Lne8zn1Ifn6EkYBTDAmCmCCMfMEL1VWDDAjP7m/AAAAAElFTkSuQmCC',
      _ => throw StateError('Unexpected connected-line role'),
    },
  );
}
