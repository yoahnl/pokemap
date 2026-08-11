import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('Character Studio has direct API and JSONL full-flow parity', () async {
    final direct = await _CharacterStudioParityFixture.create('direct');
    final jsonl = await _CharacterStudioParityFixture.create('jsonl');
    addTearDown(direct.dispose);
    addTearDown(jsonl.dispose);

    final directEvidence = await direct.runDirect();
    final jsonlEvidence = await jsonl.runJsonl();

    expect(directEvidence, jsonlEvidence);
    expect(directEvidence['actionIds'], _actionIds);
    final character = directEvidence['character']! as Map<String, Object?>;
    expect(character['id'], 'elia');
    expect(character['portraits'], hasLength(1));
    expect(character['customAnimations'], hasLength(1));
    expect(
      ((character['customAnimations']! as List).single as Map)['frames'],
      hasLength(1),
    );
    expect(directEvidence['assetIds'], <Object?>['elia-neutral']);
    expect(directEvidence['reopenedQueryCount'], 1);
  });

  test(
    'CHS-057 identity and portraits have direct API and JSONL parity',
    () async {
      final direct = await _CharacterStudioParityFixture.create(
        'identity-direct',
      );
      final jsonl = await _CharacterStudioParityFixture.create(
        'identity-jsonl',
      );
      addTearDown(direct.dispose);
      addTearDown(jsonl.dispose);

      final directEvidence = await direct.runIdentityPortraitDirect();
      final jsonlEvidence = await jsonl.runIdentityPortraitJsonl();

      expect(directEvidence, jsonlEvidence);
      expect(directEvidence['actionIds'], _identityPortraitActionIds);
      expect(directEvidence['duplicateCode'], _portraitStateConflictCode);
      expect(directEvidence['revisionConflictCode'], 'plan.stale');
      expect(directEvidence['portraitDeleteRequiresResolution'], isTrue);
      expect(directEvidence['characterDeleteRequiresResolution'], isTrue);
      expect(directEvidence['portraitStates'], <Object?>[
        <String, Object?>{
          'id': 'joyeux',
          'displayName': 'Heureux',
          'sortOrder': 0,
        },
      ]);
      expect(directEvidence['characterCount'], 0);
      expect(directEvidence['defaultCharacterId'], isNull);
      expect(directEvidence['reopenedQueryCount'], 0);
    },
  );
}

const List<String> _identityPortraitActionIds = <String>[
  'characterStudio.character.create',
  'characterStudio.character.update',
  'characterStudio.character.delete',
  'characterStudio.character.deletePlan',
  'characterStudio.character.setDefault',
  'characterStudio.character.portrait.assign',
  'characterStudio.character.portrait.clear',
  'characterStudio.portraitState.create',
  'characterStudio.portraitState.update',
  'characterStudio.portraitState.reorder',
  'characterStudio.portraitState.delete',
  'characterStudio.portraitState.deletePlan',
];

const String _portraitStateConflictCode =
    'character_studio.portrait_state.id_conflict';

const List<String> _actionIds = <String>[
  'characterStudio.portraitState.create',
  'characterStudio.character.create',
  'characterStudio.asset.import',
  'characterStudio.character.portrait.assign',
  'characterStudio.animationDefinition.create',
  'characterStudio.animationClip.upsert',
  'characterStudio.animationFrame.insert',
];

const List<Map<String, Object?>> _actionParameters = <Map<String, Object?>>[
  <String, Object?>{'displayName': 'Neutre'},
  <String, Object?>{
    'name': 'Élia',
    'tilesetId': 'characters',
    'frameWidth': 4,
    'frameHeight': 8,
  },
  <String, Object?>{},
  <String, Object?>{
    'characterId': 'elia',
    'portraitStateId': 'neutre',
    'assetId': 'elia-neutral',
    'fitMode': 'contain',
  },
  <String, Object?>{'displayName': 'Saluer', 'mode': 'directional'},
  <String, Object?>{
    'characterId': 'elia',
    'kind': 'custom',
    'definitionId': 'saluer',
    'direction': 'south',
    'sourceAssetId': 'elia-neutral',
    'loop': false,
  },
  <String, Object?>{
    'characterId': 'elia',
    'kind': 'custom',
    'definitionId': 'saluer',
    'direction': 'south',
    'frameIndex': 0,
    'frame': <String, Object?>{
      'source': <String, Object?>{
        'x': 0,
        'y': 0,
        'width': 8,
        'height': 8,
      },
      'durationMs': 120,
    },
  },
];

const Map<String, Object?> _portraitAssignment = <String, Object?>{
  'characterId': 'elia',
  'portraitStateId': 'neutre',
  'assetId': 'elia-neutral',
  'fitMode': 'contain',
};

const Map<String, Object?> _portraitSlot = <String, Object?>{
  'characterId': 'elia',
  'portraitStateId': 'neutre',
};

final class _CharacterStudioParityFixture {
  _CharacterStudioParityFixture({
    required this.root,
    required this.readApi,
    required this.mutations,
    required this.snapshots,
    required this.worker,
    required this.portraitPath,
  });

  static Future<_CharacterStudioParityFixture> create(String label) async {
    final root = await Directory.systemTemp.createTemp(
      'character-studio-parity-$label-',
    );
    final manifest = ProjectManifest(
      name: 'Character Studio parity fixture',
      version: ProjectVersion.v6,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'characters',
          name: 'Characters',
          relativePath: 'assets/characters.png',
        ),
      ],
    );
    await File('${root.path}/project.json').writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(manifest.toJson())}\n',
      flush: true,
    );
    final portraitPath = '${root.path}/elia-neutral.png';
    await File(portraitPath).writeAsBytes(_png(width: 64, height: 64));
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
      artifactStore: LocalArtifactStore(
        allowedSourceRoots: <String>[root.path],
        maximumArtifactBytes: 1024 * 1024,
      ),
    );
    return _CharacterStudioParityFixture(
      root: root,
      readApi: readApi,
      mutations: mutations,
      snapshots: snapshots,
      worker: JsonlWorker(api: readApi, mutations: mutations),
      portraitPath: portraitPath,
    );
  }

  final Directory root;
  final AuthoringReadApi readApi;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;
  final String portraitPath;

  Future<Map<String, Object?>> runIdentityPortraitDirect() async {
    var opened = await readApi.open(root.path);
    var workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    var project = ProjectHandle(opened['projectHandle']! as String);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: workspace,
      projectHandle: project,
    );
    final initialRevision = (await snapshots.load(project)).revision;
    var sequence = 0;
    await _applyDirect(
      project,
      workspaceHandle: workspace.value,
      actionId: 'characterStudio.portraitState.create',
      parameters: const <String, Object?>{'displayName': 'Neutre'},
      index: sequence++,
    );
    final revisionAfterFirstMutation = (await snapshots.load(project)).revision;
    final duplicateCode = await _directPlanFailureCode(
      project,
      workspaceHandle: workspace.value,
      expectedRevision: revisionAfterFirstMutation,
      actionId: 'characterStudio.portraitState.create',
      parameters: const <String, Object?>{'displayName': 'Neutre'},
      sequence: 'duplicate',
    );
    final revisionConflictCode = await _directPlanFailureCode(
      project,
      workspaceHandle: workspace.value,
      expectedRevision: initialRevision,
      actionId: 'characterStudio.portraitState.create',
      parameters: const <String, Object?>{'displayName': 'Obsolète'},
      sequence: 'stale',
    );
    expect(
        (await snapshots.load(project)).revision, revisionAfterFirstMutation);
    await _applyDirect(
      project,
      workspaceHandle: workspace.value,
      actionId: 'characterStudio.portraitState.create',
      parameters: const <String, Object?>{'displayName': 'Joyeux'},
      index: sequence++,
    );
    await _applyDirect(
      project,
      workspaceHandle: workspace.value,
      actionId: 'characterStudio.portraitState.update',
      parameters: const <String, Object?>{
        'id': 'joyeux',
        'displayName': 'Heureux',
      },
      index: sequence++,
    );
    await _applyDirect(
      project,
      workspaceHandle: workspace.value,
      actionId: 'characterStudio.portraitState.reorder',
      parameters: const <String, Object?>{
        'orderedIds': <String>['joyeux', 'neutre'],
      },
      index: sequence++,
    );
    await _applyDirect(
      project,
      workspaceHandle: workspace.value,
      actionId: 'characterStudio.character.create',
      parameters: const <String, Object?>{
        'name': 'Élia',
        'tilesetId': 'characters',
        'frameWidth': 4,
        'frameHeight': 8,
      },
      index: sequence++,
    );
    await _applyDirect(
      project,
      workspaceHandle: workspace.value,
      actionId: 'characterStudio.character.update',
      parameters: const <String, Object?>{
        'characterId': 'elia',
        'name': 'Élia la Rouge',
        'tags': <String>['heroine'],
      },
      index: sequence++,
    );
    await _applyDirect(
      project,
      workspaceHandle: workspace.value,
      actionId: 'characterStudio.character.setDefault',
      parameters: const <String, Object?>{'characterId': 'elia'},
      index: sequence++,
    );
    await _applyDirect(
      project,
      workspaceHandle: workspace.value,
      actionId: 'characterStudio.character.portrait.assign',
      parameters: _portraitAssignment,
      index: sequence++,
    );
    await _applyDirect(
      project,
      workspaceHandle: workspace.value,
      actionId: 'characterStudio.character.portrait.clear',
      parameters: _portraitSlot,
      index: sequence++,
    );
    await _applyDirect(
      project,
      workspaceHandle: workspace.value,
      actionId: 'characterStudio.character.portrait.assign',
      parameters: _portraitAssignment,
      index: sequence++,
    );
    final portraitDeletePlan = await _planDirect(
      project,
      workspaceHandle: workspace.value,
      actionId: 'characterStudio.portraitState.deletePlan',
      parameters: const <String, Object?>{'id': 'neutre'},
      sequence: 'portrait-delete-plan',
      dryRun: true,
    );
    await _applyDirect(
      project,
      workspaceHandle: workspace.value,
      actionId: 'characterStudio.portraitState.delete',
      parameters: const <String, Object?>{
        'id': 'neutre',
        'resolution': 'replace',
        'replacementId': 'joyeux',
      },
      index: sequence++,
      requiresConfirmation: true,
    );
    final characterDeletePlan = await _planDirect(
      project,
      workspaceHandle: workspace.value,
      actionId: 'characterStudio.character.deletePlan',
      parameters: const <String, Object?>{'characterId': 'elia'},
      sequence: 'character-delete-plan',
      dryRun: true,
    );
    await _applyDirect(
      project,
      workspaceHandle: workspace.value,
      actionId: 'characterStudio.character.delete',
      parameters: const <String, Object?>{
        'characterId': 'elia',
        'resolution': 'clear',
      },
      index: sequence++,
      requiresConfirmation: true,
    );
    await mutations.detachWorkspace(workspace);
    await readApi.close(workspace);
    opened = await readApi.open(root.path);
    workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    project = ProjectHandle(opened['projectHandle']! as String);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: workspace,
      projectHandle: project,
    );
    final query = await readApi.query(
      project,
      AuthoringQueryRequest(
        resourceKind: 'characterStudioCharacter',
        operation: AuthoringQueryOperation.list,
        view: AuthoringQueryView.detail,
      ),
    );
    return _identityPortraitEvidence(
      query,
      duplicateCode: duplicateCode,
      revisionConflictCode: revisionConflictCode,
      portraitDeletePlan: portraitDeletePlan.plan.preview,
      characterDeletePlan: characterDeletePlan.plan.preview,
    );
  }

  Future<Map<String, Object?>> runIdentityPortraitJsonl() async {
    var opened = await _jsonl('open', <String, Object?>{
      'projectRoot': root.path,
    });
    var projectHandle = opened['projectHandle']! as String;
    var workspaceHandle = opened['workspaceHandle']! as String;
    final project = ProjectHandle(projectHandle);
    final initialRevision = (await snapshots.load(project)).revision;
    var sequence = 0;
    await _applyJsonl(
      projectHandle: projectHandle,
      workspaceHandle: workspaceHandle,
      actionId: 'characterStudio.portraitState.create',
      parameters: const <String, Object?>{'displayName': 'Neutre'},
      index: sequence++,
    );
    final revisionAfterFirstMutation = (await snapshots.load(project)).revision;
    final duplicateCode = await _jsonlPlanFailureCode(
      projectHandle: projectHandle,
      workspaceHandle: workspaceHandle,
      expectedRevision: revisionAfterFirstMutation,
      actionId: 'characterStudio.portraitState.create',
      parameters: const <String, Object?>{'displayName': 'Neutre'},
      sequence: 'duplicate',
    );
    final revisionConflictCode = await _jsonlPlanFailureCode(
      projectHandle: projectHandle,
      workspaceHandle: workspaceHandle,
      expectedRevision: initialRevision,
      actionId: 'characterStudio.portraitState.create',
      parameters: const <String, Object?>{'displayName': 'Obsolète'},
      sequence: 'stale',
    );
    expect(
        (await snapshots.load(project)).revision, revisionAfterFirstMutation);
    final steps = <(String, Map<String, Object?>, bool)>[
      (
        'characterStudio.portraitState.create',
        const <String, Object?>{'displayName': 'Joyeux'},
        false,
      ),
      (
        'characterStudio.portraitState.update',
        const <String, Object?>{
          'id': 'joyeux',
          'displayName': 'Heureux',
        },
        false,
      ),
      (
        'characterStudio.portraitState.reorder',
        const <String, Object?>{
          'orderedIds': <String>['joyeux', 'neutre'],
        },
        false,
      ),
      (
        'characterStudio.character.create',
        const <String, Object?>{
          'name': 'Élia',
          'tilesetId': 'characters',
          'frameWidth': 4,
          'frameHeight': 8,
        },
        false,
      ),
      (
        'characterStudio.character.update',
        const <String, Object?>{
          'characterId': 'elia',
          'name': 'Élia la Rouge',
          'tags': <String>['heroine'],
        },
        false,
      ),
      (
        'characterStudio.character.setDefault',
        const <String, Object?>{'characterId': 'elia'},
        false,
      ),
      (
        'characterStudio.character.portrait.assign',
        _portraitAssignment,
        false,
      ),
      (
        'characterStudio.character.portrait.clear',
        _portraitSlot,
        false,
      ),
      (
        'characterStudio.character.portrait.assign',
        _portraitAssignment,
        false,
      ),
    ];
    for (final step in steps) {
      await _applyJsonl(
        projectHandle: projectHandle,
        workspaceHandle: workspaceHandle,
        actionId: step.$1,
        parameters: step.$2,
        index: sequence++,
        requiresConfirmation: step.$3,
      );
    }
    final portraitDeletePlan = await _planJsonl(
      projectHandle: projectHandle,
      workspaceHandle: workspaceHandle,
      actionId: 'characterStudio.portraitState.deletePlan',
      parameters: const <String, Object?>{'id': 'neutre'},
      sequence: 'portrait-delete-plan',
      dryRun: true,
    );
    await _applyJsonl(
      projectHandle: projectHandle,
      workspaceHandle: workspaceHandle,
      actionId: 'characterStudio.portraitState.delete',
      parameters: const <String, Object?>{
        'id': 'neutre',
        'resolution': 'replace',
        'replacementId': 'joyeux',
      },
      index: sequence++,
      requiresConfirmation: true,
    );
    final characterDeletePlan = await _planJsonl(
      projectHandle: projectHandle,
      workspaceHandle: workspaceHandle,
      actionId: 'characterStudio.character.deletePlan',
      parameters: const <String, Object?>{'characterId': 'elia'},
      sequence: 'character-delete-plan',
      dryRun: true,
    );
    await _applyJsonl(
      projectHandle: projectHandle,
      workspaceHandle: workspaceHandle,
      actionId: 'characterStudio.character.delete',
      parameters: const <String, Object?>{
        'characterId': 'elia',
        'resolution': 'clear',
      },
      index: sequence++,
      requiresConfirmation: true,
    );
    await _jsonl('close', <String, Object?>{
      'workspaceHandle': workspaceHandle,
    });
    opened = await _jsonl('open', <String, Object?>{
      'projectRoot': root.path,
    });
    projectHandle = opened['projectHandle']! as String;
    workspaceHandle = opened['workspaceHandle']! as String;
    final query = await _jsonl('query', <String, Object?>{
      'projectHandle': projectHandle,
      'request': AuthoringQueryRequest(
        resourceKind: 'characterStudioCharacter',
        operation: AuthoringQueryOperation.list,
        view: AuthoringQueryView.detail,
      ).toJson(),
    });
    expect(workspaceHandle, isNotEmpty);
    return _identityPortraitEvidence(
      query,
      duplicateCode: duplicateCode,
      revisionConflictCode: revisionConflictCode,
      portraitDeletePlan: (portraitDeletePlan['plan']!
          as Map<String, Object?>)['preview']! as Map<String, Object?>,
      characterDeletePlan: (characterDeletePlan['plan']!
          as Map<String, Object?>)['preview']! as Map<String, Object?>,
    );
  }

  Future<Map<String, Object?>> runDirect() async {
    var opened = await readApi.open(root.path);
    var workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    var project = ProjectHandle(opened['projectHandle']! as String);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: workspace,
      projectHandle: project,
    );
    final staged = await mutations.stageArtifactFile(
      sourcePath: portraitPath,
      declaredMediaType: 'image/png',
    );
    for (var index = 0; index < _actionIds.length; index++) {
      final parameters = Map<String, Object?>.from(_actionParameters[index]);
      if (_actionIds[index] == 'characterStudio.asset.import') {
        parameters.addAll(<String, Object?>{
          'artifactHandle': staged.reference.handle,
          'assetId': 'elia-neutral',
          'logicalPath': 'assets/characters/elia/neutral.png',
          'mediaKind': 'portrait',
        });
      }
      await _applyDirect(
        project,
        workspaceHandle: workspace.value,
        actionId: _actionIds[index],
        parameters: parameters,
        index: index,
      );
    }
    await mutations.detachWorkspace(workspace);
    await readApi.close(workspace);
    opened = await readApi.open(root.path);
    workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    project = ProjectHandle(opened['projectHandle']! as String);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: workspace,
      projectHandle: project,
    );
    final query = await readApi.query(
      project,
      AuthoringQueryRequest(
        resourceKind: 'characterStudioCharacter',
        operation: AuthoringQueryOperation.list,
        view: AuthoringQueryView.detail,
      ),
    );
    return _evidence(query);
  }

  Future<Map<String, Object?>> runJsonl() async {
    var opened = await _jsonl('open', <String, Object?>{
      'projectRoot': root.path,
    });
    var projectHandle = opened['projectHandle']! as String;
    var workspaceHandle = opened['workspaceHandle']! as String;
    final staged = await _jsonl('stage_artifact', <String, Object?>{
      'sourcePath': portraitPath,
      'declaredMediaType': 'image/png',
    });
    for (var index = 0; index < _actionIds.length; index++) {
      final parameters = Map<String, Object?>.from(_actionParameters[index]);
      if (_actionIds[index] == 'characterStudio.asset.import') {
        parameters.addAll(<String, Object?>{
          'artifactHandle': staged['artifactHandle'],
          'assetId': 'elia-neutral',
          'logicalPath': 'assets/characters/elia/neutral.png',
          'mediaKind': 'portrait',
        });
      }
      await _applyJsonl(
        projectHandle: projectHandle,
        workspaceHandle: workspaceHandle,
        actionId: _actionIds[index],
        parameters: parameters,
        index: index,
      );
    }
    await _jsonl('close', <String, Object?>{
      'workspaceHandle': workspaceHandle,
    });
    opened = await _jsonl('open', <String, Object?>{
      'projectRoot': root.path,
    });
    projectHandle = opened['projectHandle']! as String;
    workspaceHandle = opened['workspaceHandle']! as String;
    final query = await _jsonl('query', <String, Object?>{
      'projectHandle': projectHandle,
      'request': AuthoringQueryRequest(
        resourceKind: 'characterStudioCharacter',
        operation: AuthoringQueryOperation.list,
        view: AuthoringQueryView.detail,
      ).toJson(),
    });
    expect(workspaceHandle, isNotEmpty);
    return _evidence(query);
  }

  Future<void> _applyDirect(
    ProjectHandle project, {
    required String workspaceHandle,
    required String actionId,
    required Map<String, Object?> parameters,
    required int index,
    bool requiresConfirmation = false,
  }) async {
    final plan = await _planDirectRequest(
      project,
      AuthoringRequest(
        requestId: 'direct-$index',
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: workspaceHandle,
        parameters: parameters,
        expectedRevision: (await snapshots.load(project)).revision,
        idempotencyKey: 'direct-idempotency-$index',
      ),
    );
    final confirmationToken = requiresConfirmation
        ? (await mutations.confirmMutation(
            project,
            planId: plan.plan.planId,
          ))
            .confirmationToken
        : null;
    await mutations.applyMutation(
      project,
      planId: plan.plan.planId,
      operationId: 'direct-operation-$index',
      confirmationToken: confirmationToken,
    );
  }

  Future<void> _applyJsonl({
    required String projectHandle,
    required String workspaceHandle,
    required String actionId,
    required Map<String, Object?> parameters,
    required int index,
    bool requiresConfirmation = false,
  }) async {
    final planned = await _planJsonl(
      projectHandle: projectHandle,
      workspaceHandle: workspaceHandle,
      actionId: actionId,
      parameters: parameters,
      sequence: '$index',
    );
    final confirmation = requiresConfirmation
        ? await _jsonl('confirm', <String, Object?>{
            'projectHandle': projectHandle,
            'planId': planned['planId'],
          })
        : null;
    await _jsonl('apply', <String, Object?>{
      'projectHandle': projectHandle,
      'planId': planned['planId'],
      'operationId': 'jsonl-operation-$index',
      if (confirmation != null)
        'confirmationToken': confirmation['confirmationToken'],
    });
  }

  Future<AuthoringMutationPlanResult> _planDirectRequest(
    ProjectHandle project,
    AuthoringRequest request,
  ) =>
      mutations.planMutation(project, request);

  Future<AuthoringMutationPlanResult> _planDirectAction(
    ProjectHandle project, {
    required String workspaceHandle,
    required String actionId,
    required Map<String, Object?> parameters,
    required String sequence,
    bool dryRun = false,
  }) async {
    final snapshot = await snapshots.load(project);
    return _planDirectRequest(
      project,
      AuthoringRequest(
        requestId: 'direct-$sequence',
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: workspaceHandle,
        parameters: parameters,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'direct-idempotency-$sequence',
        dryRun: dryRun,
      ),
    );
  }

  Future<AuthoringMutationPlanResult> _planDirect(
    ProjectHandle project, {
    required String workspaceHandle,
    required String actionId,
    required Map<String, Object?> parameters,
    required String sequence,
    bool dryRun = false,
  }) =>
      _planDirectAction(
        project,
        workspaceHandle: workspaceHandle,
        actionId: actionId,
        parameters: parameters,
        sequence: sequence,
        dryRun: dryRun,
      );

  Future<String> _directPlanFailureCode(
    ProjectHandle project, {
    required String workspaceHandle,
    required String expectedRevision,
    required String actionId,
    required Map<String, Object?> parameters,
    required String sequence,
  }) async {
    try {
      await mutations.planMutation(
        project,
        AuthoringRequest(
          requestId: 'direct-failure-$sequence',
          actionId: actionId,
          actionVersion: 1,
          workspaceHandle: workspaceHandle,
          parameters: parameters,
          expectedRevision: expectedRevision,
          idempotencyKey: 'direct-failure-idempotency-$sequence',
        ),
      );
      fail('Expected $actionId to fail');
    } on CharacterStudioActionException catch (error) {
      return error.code;
    } on AuthoringRevisionConflict catch (error) {
      return error.code;
    } on AuthoringPlanException catch (error) {
      return error.code;
    }
  }

  Future<Map<String, Object?>> _planJsonl({
    required String projectHandle,
    required String workspaceHandle,
    required String actionId,
    required Map<String, Object?> parameters,
    required String sequence,
    bool dryRun = false,
  }) async {
    final snapshot = await snapshots.load(ProjectHandle(projectHandle));
    return _jsonl('plan', <String, Object?>{
      'projectHandle': projectHandle,
      'request': AuthoringRequest(
        requestId: 'jsonl-$sequence',
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: workspaceHandle,
        parameters: parameters,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'jsonl-idempotency-$sequence',
        dryRun: dryRun,
      ).toJson(),
    });
  }

  Future<String> _jsonlPlanFailureCode({
    required String projectHandle,
    required String workspaceHandle,
    required String expectedRevision,
    required String actionId,
    required Map<String, Object?> parameters,
    required String sequence,
  }) async {
    final result = await _jsonlResult('plan', <String, Object?>{
      'projectHandle': projectHandle,
      'request': AuthoringRequest(
        requestId: 'jsonl-failure-$sequence',
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: workspaceHandle,
        parameters: parameters,
        expectedRevision: expectedRevision,
        idempotencyKey: 'jsonl-failure-idempotency-$sequence',
      ).toJson(),
    });
    expect(result.status, AuthoringResultStatus.failure);
    return result.error!.details['domainCode']! as String;
  }

  Future<Map<String, Object?>> _jsonl(
    String command,
    Map<String, Object?> args,
  ) async {
    final response = await _jsonlResult(command, args);
    expect(
      response.status,
      AuthoringResultStatus.success,
      reason: jsonEncode(response.toJson()),
    );
    return response.data;
  }

  Future<AuthoringResult> _jsonlResult(
    String command,
    Map<String, Object?> args,
  ) async =>
      AuthoringResult.fromJson(
        jsonDecode(
          await worker.processLine(
            jsonEncode(<String, Object?>{
              'id': 'parity-$command',
              'command': command,
              'args': args,
            }),
          ),
        ) as Map<String, dynamic>,
      );

  Map<String, Object?> _identityPortraitEvidence(
    Map<String, Object?> query, {
    required String duplicateCode,
    required String revisionConflictCode,
    required Map<String, Object?> portraitDeletePlan,
    required Map<String, Object?> characterDeletePlan,
  }) {
    final manifest = ProjectManifest.fromJson(
      jsonDecode(File('${root.path}/project.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    return <String, Object?>{
      'actionIds': _identityPortraitActionIds,
      'duplicateCode': duplicateCode,
      'revisionConflictCode': revisionConflictCode,
      'portraitDeleteRequiresResolution':
          portraitDeletePlan['requiresResolution'],
      'characterDeleteRequiresResolution':
          characterDeletePlan['requiresResolution'],
      'portraitStates': <Object?>[
        for (final state in manifest.characterStudioCatalog.portraitStates)
          state.toJson(),
      ],
      'characterCount': manifest.characters.length,
      'defaultCharacterId': manifest.settings.defaultPlayerCharacterId,
      'reopenedQueryCount': (query['items']! as List).length,
    };
  }

  Map<String, Object?> _evidence(Map<String, Object?> query) {
    final manifest = ProjectManifest.fromJson(
      jsonDecode(File('${root.path}/project.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    final catalog = AssetCatalog.fromJson(
      jsonDecode(
        File('${root.path}/$assetCatalogStorageKey').readAsStringSync(),
      ) as Map<String, dynamic>,
    );
    return <String, Object?>{
      'actionIds': _actionIds,
      'portraitStates': <Object?>[
        for (final state in manifest.characterStudioCatalog.portraitStates)
          state.toJson(),
      ],
      'customDefinitions': <Object?>[
        for (final definition
            in manifest.characterStudioCatalog.customAnimationDefinitions)
          definition.toJson(),
      ],
      'character': manifest.characters.single.toJson(),
      'assetIds': catalog.records.map((record) => record.id).toList(),
      'reopenedQueryCount': (query['items']! as List).length,
    };
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

List<int> _png({required int width, required int height}) {
  final bytes = List<int>.filled(24, 0);
  bytes.setRange(0, 8, const <int>[137, 80, 78, 71, 13, 10, 26, 10]);
  bytes.setRange(12, 16, const <int>[73, 72, 68, 82]);
  bytes.setRange(16, 20, _uint32(width));
  bytes.setRange(20, 24, _uint32(height));
  return bytes;
}

List<int> _uint32(int value) => <int>[
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ];
