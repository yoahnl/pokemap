import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
      'quests and profile presentation updates survive JSONL plan apply and reload',
      () async {
    final harness = await _Harness.create('pause-actions');
    addTearDown(harness.dispose);
    final opened = await harness
        ._jsonl('open', <String, Object?>{'projectRoot': harness.root.path});
    final project = opened['projectHandle']! as String;
    final snapshot = await harness.snapshots.load(ProjectHandle(project));
    const profile = ProjectPresentationProfile(
        pause: ProjectPausePresentationProfile(
      actions: <ProjectPauseActionProfile>[
        ProjectPauseActionProfile(id: ProjectPauseActionId.resume),
        ProjectPauseActionProfile(
            id: ProjectPauseActionId.quests, label: 'Journal', visible: false),
        ProjectPauseActionProfile(
            id: ProjectPauseActionId.profile,
            label: 'Dresseur',
            icon: ProjectPauseActionIcon.person),
      ],
    ));
    final request = AuthoringRequest(
      requestId: 'pause-presentation-jsonl',
      actionId: 'presentation.update',
      actionVersion: 1,
      workspaceHandle: opened['workspaceHandle']! as String,
      parameters: <String, Object?>{'profile': profile.toJson()},
      expectedRevision: snapshot.revision,
      idempotencyKey: 'pause-presentation-jsonl',
      dryRun: false,
    );
    final plan = await harness._jsonl('plan', <String, Object?>{
      'projectHandle': project,
      'request': request.toJson(),
    });
    await harness._jsonl('apply', <String, Object?>{
      'projectHandle': project,
      'planId': plan['planId'],
      'operationId': 'pause-presentation-jsonl',
    });
    final reloaded = await harness.snapshots.load(ProjectHandle(project));
    expect(reloaded.manifest.presentation, profile);
  });

  test(
    'Presentation clip authoring keeps direct and JSONL transactions equivalent',
    () async {
      final direct = await _Harness.create('direct');
      final jsonl = await _Harness.create('jsonl');
      addTearDown(direct.dispose);
      addTearDown(jsonl.dispose);

      final directResult = await direct.runDirect();
      final jsonlResult = await jsonl.runJsonl();

      expect(directResult.dryRunBytes, directResult.initialBytes);
      expect(jsonlResult.dryRunBytes, jsonlResult.initialBytes);
      expect(directResult.stablePlan, jsonlResult.stablePlan);
      expect(directResult.stableReceipt, jsonlResult.stableReceipt);
      expect(directResult.replayReceipt, directResult.appliedReceipt);
      expect(jsonlResult.replayReceipt, jsonlResult.appliedReceipt);
      expect(directResult.query, jsonlResult.query);
      expect(directResult.historyActionId, 'presentationClip.create');
      expect(jsonlResult.historyActionId, 'presentationClip.create');
      expect(directResult.afterUndoBytes, directResult.initialBytes);
      expect(jsonlResult.afterUndoBytes, jsonlResult.initialBytes);
      expect(directResult.staleDomainCode, 'plan.stale');
      expect(jsonlResult.staleDomainCode, 'plan.stale');
      expect(
        directResult.duplicateDomainCode,
        'presentation_cinematic.validation_failed',
      );
      expect(
        jsonlResult.duplicateDomainCode,
        'presentation_cinematic.validation_failed',
      );
    },
  );

  test('Presentation timeline insertion matches direct and JSONL transports',
      () async {
    final direct = await _Harness.create('insert-direct');
    final jsonl = await _Harness.create('insert-jsonl');
    addTearDown(direct.dispose);
    addTearDown(jsonl.dispose);

    final directResult = await direct.runTimelineInsertDirect();
    final jsonlResult = await jsonl.runTimelineInsertJsonl();

    expect(directResult, jsonlResult);
    expect(directResult['totalAvailable'], 1);
    final clip = (directResult['items']! as List<Object?>).single as Map;
    expect(clip['id'], 'opening:inserted-markers:inserted-marker');
    expect(clip['startUs'], 2500000);
  });

  test('every CIN-019 action matches direct and JSONL transports', () async {
    final direct = await _Harness.create(
      'cin019-direct',
      manifest: _cin019Manifest(),
      mediaCatalog: _cin019MediaCatalog(),
    );
    final jsonl = await _Harness.create(
      'cin019-jsonl',
      manifest: _cin019Manifest(),
      mediaCatalog: _cin019MediaCatalog(),
    );
    addTearDown(direct.dispose);
    addTearDown(jsonl.dispose);

    final directResult = await direct.runCin019(useJsonl: false);
    final jsonlResult = await jsonl.runCin019(useJsonl: true);

    expect(directResult.actionIds, _cin019ActionIds);
    expect(jsonlResult.actionIds, _cin019ActionIds);
    expect(directResult.plans, jsonlResult.plans);
    expect(directResult.receipts, jsonlResult.receipts);
    expect(directResult.queries, jsonlResult.queries);
    expect(directResult.finalBytes, jsonlResult.finalBytes);
  });
}

final class _Harness {
  _Harness._({
    required this.root,
    required this.readApi,
    required this.mutations,
    required this.snapshots,
    required this.worker,
  });

  static Future<_Harness> create(
    String suffix, {
    ProjectManifest? manifest,
    ProjectMediaCatalog? mediaCatalog,
  }) async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_presentation_cinematic_$suffix',
    );
    final effectiveManifest = manifest ??
        ProjectManifest(
          name: 'Presentation cinematic transport fixture',
          version: ProjectVersion.v7,
          maps: const [],
          tilesets: const [],
          presentationCinematics: <PresentationCinematicAsset>[
            PresentationCinematicAsset(
              id: 'opening',
              title: 'Opening',
              durationUs: 4000000,
              tracks: <PresentationTrack>[
                PresentationTrack(
                  id: 'markers',
                  label: 'Markers',
                  kind: PresentationTrackKind.marker,
                ),
              ],
            ),
          ],
        );
    await File('${root.path}/project.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(effectiveManifest.toJson()),
      flush: true,
    );
    if (mediaCatalog != null) {
      final mediaFile = File('${root.path}/$projectMediaCatalogStorageKey');
      await mediaFile.parent.create(recursive: true);
      await mediaFile.writeAsBytes(
        encodeProjectMediaCatalogBytes(mediaCatalog),
        flush: true,
      );
    }

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
    return _Harness._(
      root: root,
      readApi: readApi,
      mutations: mutations,
      snapshots: snapshots,
      worker: JsonlWorker(api: readApi, mutations: mutations),
    );
  }

  final Directory root;
  final AuthoringReadApi readApi;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;

  Future<Map<String, Object?>> runTimelineInsertDirect() async {
    final opened = await readApi.open(root.path);
    final project = ProjectHandle(opened['projectHandle']! as String);
    final workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: workspace,
      projectHandle: project,
    );
    final snapshot = await snapshots.load(project);
    final plan = await mutations.plan(
      project,
      _timelineInsertRequest(workspace.value, snapshot.revision),
    );
    await mutations.apply(
      project,
      planId: plan['planId']! as String,
      operationId: 'operation-presentation-timeline-insert',
    );
    return readApi.query(project, _timelineInsertQuery());
  }

  Future<Map<String, Object?>> runTimelineInsertJsonl() async {
    final opened = await _jsonl('open', <String, Object?>{
      'projectRoot': root.path,
    });
    final project = opened['projectHandle']! as String;
    final workspace = opened['workspaceHandle']! as String;
    final validated = await _jsonl('validate', <String, Object?>{
      'projectHandle': project,
    });
    final plan = await _jsonl('plan', <String, Object?>{
      'projectHandle': project,
      'request': _timelineInsertRequest(
        workspace,
        validated['snapshotRevision']! as String,
      ).toJson(),
    });
    await _jsonl('apply', <String, Object?>{
      'projectHandle': project,
      'planId': plan['planId'],
      'operationId': 'operation-presentation-timeline-insert',
    });
    return _jsonl('query', <String, Object?>{
      'projectHandle': project,
      'request': _timelineInsertQuery().toJson(),
    });
  }

  Future<_FlowResult> runDirect() async {
    final opened = await readApi.open(root.path);
    final project = ProjectHandle(opened['projectHandle']! as String);
    final workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: workspace,
      projectHandle: project,
    );
    final initialBytes = await _projectBytes();
    final snapshot = await snapshots.load(project);
    final dryRun = await mutations.plan(
      project,
      _request(workspace.value, snapshot.revision, 'dry-run', dryRun: true),
    );
    expect(dryRun['applicable'], isFalse);
    expect(dryRun['nonApplicableReason'], 'dry_run');
    final dryRunBytes = await _projectBytes();
    final plan = await mutations.plan(
      project,
      _request(workspace.value, snapshot.revision, 'apply'),
    );
    final applied = await mutations.apply(
      project,
      planId: plan['planId']! as String,
      operationId: 'operation-presentation-clip',
    );
    final replay = await mutations.apply(
      project,
      planId: plan['planId']! as String,
      operationId: 'operation-presentation-clip',
    );
    final query = await readApi.query(project, _clipQuery());
    final history = await mutations.history(project, limit: 1);
    final entry = Map<String, Object?>.from(
      (history['entries']! as List).single as Map,
    );
    final duplicateDomainCode = await _directDuplicateCode(
      project,
      workspace.value,
    );
    final staleDomainCode = await _directStaleCode(project, workspace.value);
    await mutations.undo(
      project,
      entryId: entry['entryId']! as String,
      idempotencyKey: 'undo-presentation-clip',
    );
    return _FlowResult(
      initialBytes: initialBytes,
      dryRunBytes: dryRunBytes,
      stablePlan: _stablePlan(plan),
      appliedReceipt: _receipt(applied),
      replayReceipt: _receipt(replay),
      stableReceipt: _stableReceipt(_receipt(applied)),
      query: query,
      historyActionId:
          (entry['receipt']! as Map<String, Object?>)['actionId']! as String,
      staleDomainCode: staleDomainCode,
      duplicateDomainCode: duplicateDomainCode,
      afterUndoBytes: await _projectBytes(),
    );
  }

  Future<_FlowResult> runJsonl() async {
    final opened = await _jsonl('open', <String, Object?>{
      'projectRoot': root.path,
    });
    final project = opened['projectHandle']! as String;
    final workspace = opened['workspaceHandle']! as String;
    final validated = await _jsonl('validate', <String, Object?>{
      'projectHandle': project,
    });
    final initialBytes = await _projectBytes();
    final dryRun = await _jsonl('plan', <String, Object?>{
      'projectHandle': project,
      'request': _request(
        workspace,
        validated['snapshotRevision']! as String,
        'dry-run',
        dryRun: true,
      ).toJson(),
    });
    expect(dryRun['applicable'], isFalse);
    expect(dryRun['nonApplicableReason'], 'dry_run');
    final dryRunBytes = await _projectBytes();
    final plan = await _jsonl('plan', <String, Object?>{
      'projectHandle': project,
      'request': _request(
        workspace,
        validated['snapshotRevision']! as String,
        'apply',
      ).toJson(),
    });
    final applyArgs = <String, Object?>{
      'projectHandle': project,
      'planId': plan['planId'],
      'operationId': 'operation-presentation-clip',
    };
    final applied = await _jsonl('apply', applyArgs);
    final replay = await _jsonl('apply', applyArgs);
    final query = await _jsonl('query', <String, Object?>{
      'projectHandle': project,
      'request': _clipQuery().toJson(),
    });
    final history = await _jsonl('history', <String, Object?>{
      'projectHandle': project,
      'limit': 1,
    });
    final entry = Map<String, Object?>.from(
      (history['entries']! as List).single as Map,
    );
    final duplicateDomainCode = await _jsonlDuplicateCode(project, workspace);
    final stale = await _jsonlResult('plan', <String, Object?>{
      'projectHandle': project,
      'request': _request(workspace, _staleRevision, 'stale').toJson(),
    });
    await _jsonl('undo', <String, Object?>{
      'projectHandle': project,
      'entryId': entry['entryId'],
      'idempotencyKey': 'undo-presentation-clip',
    });
    return _FlowResult(
      initialBytes: initialBytes,
      dryRunBytes: dryRunBytes,
      stablePlan: _stablePlan(plan),
      appliedReceipt: _receipt(applied),
      replayReceipt: _receipt(replay),
      stableReceipt: _stableReceipt(_receipt(applied)),
      query: query,
      historyActionId:
          (entry['receipt']! as Map<String, Object?>)['actionId']! as String,
      staleDomainCode: stale.error!.details['domainCode']! as String,
      duplicateDomainCode: duplicateDomainCode,
      afterUndoBytes: await _projectBytes(),
    );
  }

  Future<_Cin019Result> runCin019({required bool useJsonl}) async {
    final opened = useJsonl
        ? await _jsonl('open', <String, Object?>{'projectRoot': root.path})
        : await readApi.open(root.path);
    final project = ProjectHandle(opened['projectHandle']! as String);
    final workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    if (!useJsonl) {
      await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: workspace,
        projectHandle: project,
      );
    }
    var revision = useJsonl
        ? (await _jsonl('validate', <String, Object?>{
            'projectHandle': project.value,
          }))['snapshotRevision']! as String
        : (await snapshots.load(project)).revision;
    final plans = <Map<String, Object?>>[];
    final receipts = <Map<String, Object?>>[];
    final actionIds = <String>{};

    for (var index = 0; index < _cin019Steps.length; index += 1) {
      final step = _cin019Steps[index];
      final sequence = index + 1;
      final request = AuthoringRequest(
        requestId: 'cin019-request-$sequence',
        actionId: step.actionId,
        actionVersion: 1,
        workspaceHandle: workspace.value,
        parameters: step.parameters,
        expectedRevision: revision,
        idempotencyKey: 'cin019-idempotency-$sequence',
      );
      final plan = useJsonl
          ? await _jsonl('plan', <String, Object?>{
              'projectHandle': project.value,
              'request': request.toJson(),
            })
          : await mutations.plan(project, request);
      final confirmation = step.confirmed
          ? useJsonl
              ? await _jsonl('confirm', <String, Object?>{
                  'projectHandle': project.value,
                  'planId': plan['planId'],
                })
              : await mutations.confirm(
                  project,
                  planId: plan['planId']! as String,
                )
          : null;
      final applied = useJsonl
          ? await _jsonl('apply', <String, Object?>{
              'projectHandle': project.value,
              'planId': plan['planId'],
              'operationId': 'cin019-operation-$sequence',
              if (confirmation != null)
                'confirmationToken': confirmation['confirmationToken'],
            })
          : await mutations.apply(
              project,
              planId: plan['planId']! as String,
              operationId: 'cin019-operation-$sequence',
              confirmationToken: confirmation?['confirmationToken'] as String?,
            );
      final receipt = _stableReceipt(_receipt(applied));
      plans.add(_stablePlan(plan));
      receipts.add(receipt);
      actionIds.add(receipt['actionId']! as String);
      revision = useJsonl
          ? (await _jsonl('validate', <String, Object?>{
              'projectHandle': project.value,
            }))['snapshotRevision']! as String
          : (await snapshots.load(project)).revision;
    }

    final queries = <String, Object?>{};
    for (final resourceKind in const <String>[
      'presentationCinematic',
      'presentationTrack',
      'presentationClip',
      'presentationLayer',
    ]) {
      final filters = resourceKind == 'presentationCinematic'
          ? const <String, Object?>{}
          : const <String, Object?>{'cinematicId': 'opening'};
      final firstRequest = AuthoringQueryRequest(
        resourceKind: resourceKind,
        operation: AuthoringQueryOperation.list,
        view: AuthoringQueryView.detail,
        filters: filters,
        pageSize: 1,
      );
      final firstPage = useJsonl
          ? await _jsonl('query', <String, Object?>{
              'projectHandle': project.value,
              'request': firstRequest.toJson(),
            })
          : await readApi.query(project, firstRequest);
      final cursor = firstPage['nextCursor'] as String?;
      final pages = <Map<String, Object?>>[firstPage];
      if (cursor != null) {
        final nextRequest = AuthoringQueryRequest(
          resourceKind: resourceKind,
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
          filters: filters,
          pageSize: 1,
          cursor: cursor,
        );
        pages.add(
          useJsonl
              ? await _jsonl('query', <String, Object?>{
                  'projectHandle': project.value,
                  'request': nextRequest.toJson(),
                })
              : await readApi.query(project, nextRequest),
        );
      }
      queries[resourceKind] = pages;
    }

    return _Cin019Result(
      actionIds: actionIds,
      plans: plans,
      receipts: receipts,
      queries: queries,
      finalBytes: await _projectBytes(),
    );
  }

  Future<String> _directDuplicateCode(
    ProjectHandle project,
    String workspace,
  ) async {
    final snapshot = await snapshots.load(project);
    try {
      await mutations.plan(
        project,
        _request(workspace, snapshot.revision, 'duplicate'),
      );
    } on PresentationCinematicAuthoringException catch (error) {
      return error.code;
    }
    throw StateError('The duplicate clip request was accepted.');
  }

  Future<String> _directStaleCode(
    ProjectHandle project,
    String workspace,
  ) async {
    try {
      await mutations.plan(
        project,
        _request(workspace, _staleRevision, 'stale'),
      );
    } on AuthoringPlanException catch (error) {
      return error.code;
    }
    throw StateError('The stale request was accepted.');
  }

  Future<String> _jsonlDuplicateCode(String project, String workspace) async {
    final validated = await _jsonl('validate', <String, Object?>{
      'projectHandle': project,
    });
    final duplicate = await _jsonlResult('plan', <String, Object?>{
      'projectHandle': project,
      'request': _request(
        workspace,
        validated['snapshotRevision']! as String,
        'duplicate',
      ).toJson(),
    });
    return duplicate.error!.details['domainCode']! as String;
  }

  Future<Map<String, Object?>> _jsonl(
    String command,
    Map<String, Object?> args,
  ) async {
    final result = await _jsonlResult(command, args);
    expect(
      result.status,
      AuthoringResultStatus.success,
      reason: result.error?.toJson().toString(),
    );
    return result.data;
  }

  Future<AuthoringResult> _jsonlResult(
    String command,
    Map<String, Object?> args,
  ) async {
    return AuthoringResult.fromJson(
      jsonDecode(
        await worker.processLine(
          jsonEncode(<String, Object?>{
            'id': 'request-$command',
            'command': command,
            'args': args,
          }),
        ),
      ) as Map<String, dynamic>,
    );
  }

  Future<List<int>> _projectBytes() =>
      File('${root.path}/project.json').readAsBytes();

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

final class _Cin019Result {
  const _Cin019Result({
    required this.actionIds,
    required this.plans,
    required this.receipts,
    required this.queries,
    required this.finalBytes,
  });

  final Set<String> actionIds;
  final List<Map<String, Object?>> plans;
  final List<Map<String, Object?>> receipts;
  final Map<String, Object?> queries;
  final List<int> finalBytes;
}

final class _Cin019Step {
  const _Cin019Step(
    this.actionId,
    this.parameters, {
    this.confirmed = false,
  });

  final String actionId;
  final Map<String, Object?> parameters;
  final bool confirmed;
}

ProjectManifest _cin019Manifest() => ProjectManifest(
      name: 'CIN-019 transport fixture',
      version: ProjectVersion.v7,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      presentationCinematics: <PresentationCinematicAsset>[
        PresentationCinematicAsset(
          id: 'opening',
          title: 'Opening',
          durationUs: 4000000,
          layers: <PresentationLayer>[
            PresentationLayer(
              id: 'background',
              label: 'Background',
              zIndex: 0,
            ),
            PresentationLayer(
              id: 'foreground',
              label: 'Foreground',
              zIndex: 2,
            ),
          ],
          tracks: <PresentationTrack>[
            PresentationTrack(
              id: 'captions',
              label: 'Captions',
              kind: PresentationTrackKind.caption,
              clips: <PresentationClip>[
                PresentationCaptionClip(
                  id: 'line',
                  startUs: 250000,
                  durationUs: 1000000,
                  captionId: 'opening.line',
                ),
              ],
            ),
            PresentationTrack(
              id: 'secondary',
              label: 'Secondary',
              kind: PresentationTrackKind.marker,
            ),
          ],
        ),
        PresentationCinematicAsset(
          id: 'credits',
          title: 'Credits',
          durationUs: 1000000,
        ),
      ],
    );

ProjectMediaCatalog _cin019MediaCatalog() => ProjectMediaCatalog(
      entries: <ProjectMediaAsset>[
        for (final id in const <String>[
          'opening.line',
          'opening.line.revised',
          'opening.extra',
        ])
          ProjectMediaAsset(
            id: id,
            label: id,
            kind: ProjectMediaKind.captions,
            sourceAssetId: 'asset-${id.replaceAll('.', '-')}',
          ),
      ],
    );

const List<_Cin019Step> _cin019Steps = <_Cin019Step>[
  _Cin019Step('presentationCinematic.create', <String, Object?>{
    'cinematicId': 'intro',
    'title': 'Intro',
    'description': 'Before title',
    'durationUs': 1500000,
  }),
  _Cin019Step('presentationCinematic.update', <String, Object?>{
    'cinematicId': 'intro',
    'title': 'Intro revised',
    'description': null,
    'durationUs': 1750000,
  }),
  _Cin019Step('presentationCinematic.duplicate', <String, Object?>{
    'cinematicId': 'intro',
    'duplicateId': 'intro-copy',
    'title': 'Intro copy',
  }),
  _Cin019Step(
    'presentationCinematic.delete',
    <String, Object?>{'cinematicId': 'credits'},
    confirmed: true,
  ),
  _Cin019Step('presentationTrack.create', <String, Object?>{
    'cinematicId': 'opening',
    'track': <String, Object?>{
      'id': 'transient',
      'label': 'Transient',
      'kind': 'marker',
      'clips': <Object?>[],
    },
  }),
  _Cin019Step('presentationTrack.update', <String, Object?>{
    'cinematicId': 'opening',
    'track': <String, Object?>{
      'id': 'secondary',
      'label': 'Secondary revised',
      'kind': 'marker',
      'clips': <Object?>[],
    },
  }),
  _Cin019Step('presentationTrack.move', <String, Object?>{
    'cinematicId': 'opening',
    'trackId': 'secondary',
    'insertionIndex': 0,
  }),
  _Cin019Step('presentationTrack.duplicate', <String, Object?>{
    'cinematicId': 'opening',
    'trackId': 'secondary',
    'duplicateId': 'secondary-copy',
    'label': 'Secondary copy',
  }),
  _Cin019Step(
    'presentationTrack.delete',
    <String, Object?>{
      'cinematicId': 'opening',
      'trackId': 'transient',
    },
    confirmed: true,
  ),
  _Cin019Step('presentationClip.create', <String, Object?>{
    'cinematicId': 'opening',
    'trackId': 'captions',
    'clip': <String, Object?>{
      'id': 'extra',
      'kind': 'caption',
      'startUs': 2000000,
      'durationUs': 500000,
      'captionId': 'opening.extra',
      'locale': 'und',
      'style': 'standard',
      'fallbackToProjectDefault': true,
    },
  }),
  _Cin019Step('presentationClip.update', <String, Object?>{
    'cinematicId': 'opening',
    'trackId': 'captions',
    'clip': <String, Object?>{
      'id': 'line',
      'kind': 'caption',
      'startUs': 250000,
      'durationUs': 1000000,
      'captionId': 'opening.line.revised',
      'locale': 'fr',
      'style': 'standard',
      'fallbackToProjectDefault': true,
    },
  }),
  _Cin019Step('presentationClip.move', <String, Object?>{
    'cinematicId': 'opening',
    'clipId': 'line',
    'targetTrackId': 'captions',
    'startUs': 500000,
  }),
  _Cin019Step('presentationClip.resize', <String, Object?>{
    'cinematicId': 'opening',
    'clipId': 'line',
    'durationUs': 1250000,
  }),
  _Cin019Step('presentationClip.duplicate', <String, Object?>{
    'cinematicId': 'opening',
    'clipId': 'line',
    'duplicateId': 'line-copy',
    'targetTrackId': 'captions',
    'startUs': 2500000,
  }),
  _Cin019Step(
    'presentationClip.delete',
    <String, Object?>{
      'cinematicId': 'opening',
      'clipId': 'extra',
    },
    confirmed: true,
  ),
  _Cin019Step('presentationLayer.create', <String, Object?>{
    'cinematicId': 'opening',
    'layer': <String, Object?>{
      'id': 'transient-layer',
      'label': 'Transient layer',
      'zIndex': 4,
      'visible': true,
      'locked': false,
    },
  }),
  _Cin019Step('presentationLayer.update', <String, Object?>{
    'cinematicId': 'opening',
    'layer': <String, Object?>{
      'id': 'background',
      'label': 'Background revised',
      'zIndex': 0,
      'visible': true,
      'locked': false,
    },
  }),
  _Cin019Step('presentationLayer.move', <String, Object?>{
    'cinematicId': 'opening',
    'layerId': 'background',
    'insertionIndex': 1,
    'targetFolderId': null,
  }),
  _Cin019Step('presentationLayer.duplicate', <String, Object?>{
    'cinematicId': 'opening',
    'layerId': 'background',
    'duplicateId': 'background-copy',
    'label': 'Background copy',
    'zIndex': 8,
  }),
  _Cin019Step(
    'presentationLayer.delete',
    <String, Object?>{
      'cinematicId': 'opening',
      'layerId': 'transient-layer',
    },
    confirmed: true,
  ),
];

final Set<String> _cin019ActionIds = <String>{
  for (final step in _cin019Steps) step.actionId,
};

final class _FlowResult {
  const _FlowResult({
    required this.initialBytes,
    required this.dryRunBytes,
    required this.stablePlan,
    required this.appliedReceipt,
    required this.replayReceipt,
    required this.stableReceipt,
    required this.query,
    required this.historyActionId,
    required this.staleDomainCode,
    required this.duplicateDomainCode,
    required this.afterUndoBytes,
  });

  final List<int> initialBytes;
  final List<int> dryRunBytes;
  final Map<String, Object?> stablePlan;
  final Map<String, Object?> appliedReceipt;
  final Map<String, Object?> replayReceipt;
  final Map<String, Object?> stableReceipt;
  final Map<String, Object?> query;
  final String historyActionId;
  final String staleDomainCode;
  final String duplicateDomainCode;
  final List<int> afterUndoBytes;
}

AuthoringRequest _request(
  String workspaceHandle,
  String revision,
  String sequence, {
  bool dryRun = false,
}) {
  return AuthoringRequest(
    requestId: 'request-$sequence',
    actionId: 'presentationClip.create',
    actionVersion: 1,
    workspaceHandle: workspaceHandle,
    parameters: const <String, Object?>{
      'cinematicId': 'opening',
      'trackId': 'markers',
      'clip': <String, Object?>{
        'id': 'beat',
        'kind': 'marker',
        'startUs': 1000000,
        'durationUs': 0,
        'label': 'Beat',
        'markerKind': 'ordinary',
      },
    },
    expectedRevision: revision,
    idempotencyKey: 'idempotency-$sequence',
    dryRun: dryRun,
  );
}

AuthoringQueryRequest _clipQuery() => AuthoringQueryRequest(
      resourceKind: 'presentationClip',
      operation: AuthoringQueryOperation.list,
      filters: const <String, Object?>{
        'cinematicId': 'opening',
        'trackId': 'markers',
      },
      pageSize: 1,
      view: AuthoringQueryView.detail,
      fieldMask: const <String>['cinematicId', 'trackId', 'startUs'],
    );

AuthoringRequest _timelineInsertRequest(
  String workspaceHandle,
  String revision,
) {
  final encoded = encodePresentationCinematicAsset(
    PresentationCinematicAsset(
      id: 'insertion',
      title: 'Insertion',
      durationUs: 4000000,
      tracks: <PresentationTrack>[
        PresentationTrack(
          id: 'inserted-markers',
          label: 'Inserted markers',
          kind: PresentationTrackKind.marker,
          clips: <PresentationClip>[
            PresentationMarkerClip(
              id: 'inserted-marker',
              startUs: 2500000,
              label: 'Inserted marker',
            ),
          ],
        ),
      ],
    ),
  );
  return AuthoringRequest(
    requestId: 'request-presentation-timeline-insert',
    actionId: 'presentationTimeline.insert',
    actionVersion: 1,
    workspaceHandle: workspaceHandle,
    parameters: <String, Object?>{
      'cinematicId': 'opening',
      'targetVisualFolderId': null,
      'layer': null,
      'track': (encoded['tracks']! as List<Object?>).single,
    },
    expectedRevision: revision,
    idempotencyKey: 'idempotency-presentation-timeline-insert',
  );
}

AuthoringQueryRequest _timelineInsertQuery() => AuthoringQueryRequest(
      resourceKind: 'presentationClip',
      operation: AuthoringQueryOperation.list,
      filters: const <String, Object?>{
        'cinematicId': 'opening',
        'trackId': 'inserted-markers',
      },
      view: AuthoringQueryView.detail,
    );

Map<String, Object?> _stablePlan(Map<String, Object?> response) {
  final plan = Map<String, Object?>.from(response['plan']! as Map);
  return <String, Object?>{
    'actionId': plan['actionId'],
    'actionVersion': plan['actionVersion'],
    'baseRevision': plan['baseRevision'],
    'projectedRevision': plan['projectedRevision'],
    'applicable': plan['applicable'],
    'changeSet': plan['changeSet'],
    'preview': plan['preview'],
    'referenceImpact': plan['referenceImpact'],
    'artifacts': plan['artifacts'],
  };
}

Map<String, Object?> _receipt(Map<String, Object?> response) =>
    Map<String, Object?>.from(response['receipt']! as Map);

Map<String, Object?> _stableReceipt(Map<String, Object?> receipt) =>
    <String, Object?>{
      'requestId': receipt['requestId'],
      'actionId': receipt['actionId'],
      'actionVersion': receipt['actionVersion'],
      'status': receipt['status'],
      'beforeRevision': receipt['beforeRevision'],
      'afterRevision': receipt['afterRevision'],
      'diff': receipt['diff'],
      'affectedResources': receipt['affectedResources'],
    };

const String _staleRevision =
    'sha256:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';
