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

  test(
    'CHS-058 animations frames and assets have direct API and JSONL parity',
    () async {
      final direct = await _CharacterStudioParityFixture.create(
        'animation-direct',
      );
      final jsonl = await _CharacterStudioParityFixture.create(
        'animation-jsonl',
      );
      addTearDown(direct.dispose);
      addTearDown(jsonl.dispose);

      final directEvidence = await direct.runAnimationDirect();
      final jsonlEvidence = await jsonl.runAnimationJsonl();

      expect(directEvidence, jsonlEvidence);
      expect(directEvidence['actionIds'], _animationActionIds);
      expect(directEvidence['directionErrorCode'],
          'character_studio.animation.direction_required');
      expect(
        directEvidence['geometryErrorCode'],
        'character_studio.asset.source_rect_out_of_bounds',
      );
      expect(
        directEvidence['frameIndexErrorCode'],
        'character_studio.animation.frame_index_invalid',
      );
      expect(directEvidence['definitionDeleteRequiresResolution'], isTrue);
      expect(directEvidence['customDefinitionIds'], <Object?>[
        'cligner',
        'acclamer',
      ]);
      expect(directEvidence['customClipDefinitionId'], 'acclamer');
      expect(directEvidence['customClipDirection'], 'south');
      expect(directEvidence['customClipFrameCount'], 2);
      expect(directEvidence['assetIds'], <Object?>['elia-sheet']);
      expect(directEvidence['serializedAbsolutePath'], isFalse);
      expect(directEvidence['reopenedQueryCount'], 1);
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

const List<String> _animationActionIds = <String>[
  'characterStudio.animationDefinition.create',
  'characterStudio.animationDefinition.update',
  'characterStudio.animationDefinition.reorder',
  'characterStudio.animationDefinition.delete',
  'characterStudio.animationDefinition.deletePlan',
  'characterStudio.animationClip.upsert',
  'characterStudio.animationClip.delete',
  'characterStudio.animationFrame.insert',
  'characterStudio.animationFrame.update',
  'characterStudio.animationFrame.reorder',
  'characterStudio.animationFrame.delete',
  'characterStudio.asset.import',
  'characterStudio.asset.replace',
];

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

final class _TransportStep {
  const _TransportStep(
    this.actionId,
    this.parameters, {
    this.requiresConfirmation = false,
    this.dryRun = false,
    this.expectedErrorCode,
    this.evidenceKey,
  });

  final String actionId;
  final Map<String, Object?> parameters;
  final bool requiresConfirmation;
  final bool dryRun;
  final String? expectedErrorCode;
  final String? evidenceKey;
}

List<_TransportStep> _animationSteps({
  required String importedArtifactHandle,
  required String replacementArtifactHandle,
}) =>
    <_TransportStep>[
      const _TransportStep(
        'characterStudio.character.create',
        <String, Object?>{
          'name': 'Élia',
          'tilesetId': 'characters',
          'frameWidth': 8,
          'frameHeight': 8,
        },
      ),
      _TransportStep(
        'characterStudio.asset.import',
        <String, Object?>{
          'artifactHandle': importedArtifactHandle,
          'assetId': 'elia-sheet',
          'logicalPath': 'assets/characters/elia/sheet.png',
          'mediaKind': 'spriteSheet',
          'tags': <String>['heroine'],
        },
      ),
      const _TransportStep(
        'characterStudio.animationDefinition.create',
        <String, Object?>{'displayName': 'Saluer', 'mode': 'directional'},
      ),
      const _TransportStep(
        'characterStudio.animationDefinition.create',
        <String, Object?>{'displayName': 'Cligner', 'mode': 'single'},
      ),
      const _TransportStep(
        'characterStudio.animationDefinition.create',
        <String, Object?>{'displayName': 'Acclamer', 'mode': 'directional'},
      ),
      const _TransportStep(
        'characterStudio.animationDefinition.update',
        <String, Object?>{
          'id': 'cligner',
          'displayName': 'Cligner vite',
        },
      ),
      const _TransportStep(
        'characterStudio.animationDefinition.reorder',
        <String, Object?>{
          'orderedIds': <String>['cligner', 'acclamer', 'saluer'],
        },
      ),
      const _TransportStep(
        'characterStudio.animationClip.upsert',
        <String, Object?>{
          'characterId': 'elia',
          'kind': 'custom',
          'definitionId': 'saluer',
          'sourceAssetId': 'elia-sheet',
        },
        expectedErrorCode: 'character_studio.animation.direction_required',
        evidenceKey: 'directionErrorCode',
      ),
      const _TransportStep(
        'characterStudio.animationClip.upsert',
        <String, Object?>{
          'characterId': 'elia',
          'kind': 'custom',
          'definitionId': 'saluer',
          'direction': 'south',
          'sourceAssetId': 'elia-sheet',
          'loop': false,
          'frames': <Object?>[
            <String, Object?>{
              'source': <String, Object?>{
                'x': 0,
                'y': 0,
                'width': 8,
                'height': 8,
              },
              'durationMs': 100,
            },
            <String, Object?>{
              'source': <String, Object?>{
                'x': 8,
                'y': 0,
                'width': 8,
                'height': 8,
              },
              'durationMs': 110,
            },
          ],
        },
      ),
      const _TransportStep(
        'characterStudio.animationClip.upsert',
        <String, Object?>{
          'characterId': 'elia',
          'kind': 'custom',
          'definitionId': 'cligner',
          'sourceAssetId': 'elia-sheet',
          'frames': <Object?>[
            <String, Object?>{
              'source': <String, Object?>{
                'x': 0,
                'y': 8,
                'width': 8,
                'height': 8,
              },
              'durationMs': 90,
            },
          ],
        },
      ),
      _TransportStep(
        'characterStudio.asset.replace',
        <String, Object?>{
          'artifactHandle': replacementArtifactHandle,
          'assetId': 'elia-sheet',
          'sourceRect': <String, Object?>{
            'x': 0,
            'y': 0,
            'width': 33,
            'height': 32,
          },
        },
        expectedErrorCode: 'character_studio.asset.source_rect_out_of_bounds',
        evidenceKey: 'geometryErrorCode',
      ),
      _TransportStep(
        'characterStudio.asset.replace',
        <String, Object?>{
          'artifactHandle': replacementArtifactHandle,
          'assetId': 'elia-sheet',
        },
      ),
      const _TransportStep(
        'characterStudio.animationFrame.insert',
        <String, Object?>{
          'characterId': 'elia',
          'kind': 'custom',
          'definitionId': 'saluer',
          'direction': 'south',
          'frameIndex': 1,
          'frame': <String, Object?>{
            'source': <String, Object?>{
              'x': 16,
              'y': 0,
              'width': 8,
              'height': 8,
            },
            'durationMs': 120,
          },
        },
      ),
      const _TransportStep(
        'characterStudio.animationFrame.update',
        <String, Object?>{
          'characterId': 'elia',
          'kind': 'custom',
          'definitionId': 'saluer',
          'direction': 'south',
          'frameIndex': 1,
          'frame': <String, Object?>{
            'source': <String, Object?>{
              'x': 16,
              'y': 0,
              'width': 8,
              'height': 8,
            },
            'durationMs': 130,
          },
        },
      ),
      const _TransportStep(
        'characterStudio.animationFrame.reorder',
        <String, Object?>{
          'characterId': 'elia',
          'kind': 'custom',
          'definitionId': 'saluer',
          'direction': 'south',
          'fromIndex': 1,
          'toIndex': 2,
        },
      ),
      const _TransportStep(
        'characterStudio.animationFrame.update',
        <String, Object?>{
          'characterId': 'elia',
          'kind': 'custom',
          'definitionId': 'saluer',
          'direction': 'south',
          'frameIndex': 9,
          'frame': <String, Object?>{
            'source': <String, Object?>{
              'x': 0,
              'y': 0,
              'width': 8,
              'height': 8,
            },
            'durationMs': 100,
          },
        },
        expectedErrorCode: 'character_studio.animation.frame_index_invalid',
        evidenceKey: 'frameIndexErrorCode',
      ),
      const _TransportStep(
        'characterStudio.animationFrame.delete',
        <String, Object?>{
          'characterId': 'elia',
          'kind': 'custom',
          'definitionId': 'saluer',
          'direction': 'south',
          'frameIndex': 0,
        },
      ),
      const _TransportStep(
        'characterStudio.animationClip.delete',
        <String, Object?>{
          'characterId': 'elia',
          'kind': 'custom',
          'definitionId': 'cligner',
        },
      ),
      const _TransportStep(
        'characterStudio.animationDefinition.deletePlan',
        <String, Object?>{'id': 'saluer'},
        dryRun: true,
        evidenceKey: 'definitionDeletePlan',
      ),
      const _TransportStep(
        'characterStudio.animationDefinition.delete',
        <String, Object?>{
          'id': 'saluer',
          'resolution': 'replace',
          'replacementId': 'acclamer',
        },
        requiresConfirmation: true,
      ),
    ];

final class _CharacterStudioParityFixture {
  _CharacterStudioParityFixture({
    required this.root,
    required this.readApi,
    required this.mutations,
    required this.snapshots,
    required this.worker,
    required this.portraitPath,
    required this.replacementPath,
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
    final replacementPath = '${root.path}/elia-replacement.png';
    await File(replacementPath).writeAsBytes(
      _png(width: 32, height: 32, marker: 7),
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
      replacementPath: replacementPath,
    );
  }

  final Directory root;
  final AuthoringReadApi readApi;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;
  final String portraitPath;
  final String replacementPath;

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

  Future<Map<String, Object?>> runAnimationDirect() async {
    var opened = await readApi.open(root.path);
    var workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    var project = ProjectHandle(opened['projectHandle']! as String);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: workspace,
      projectHandle: project,
    );
    final imported = await mutations.stageArtifactFile(
      sourcePath: portraitPath,
      declaredMediaType: 'image/png',
    );
    final replacement = await mutations.stageArtifactFile(
      sourcePath: replacementPath,
      declaredMediaType: 'image/png',
    );
    final evidence = <String, Object?>{};
    var sequence = 100;
    for (final step in _animationSteps(
      importedArtifactHandle: imported.reference.handle,
      replacementArtifactHandle: replacement.reference.handle,
    )) {
      final beforeRevision = (await snapshots.load(project)).revision;
      if (step.expectedErrorCode case final expectedCode?) {
        final code = await _directPlanFailureCode(
          project,
          workspaceHandle: workspace.value,
          expectedRevision: beforeRevision,
          actionId: step.actionId,
          parameters: step.parameters,
          sequence: 'animation-${sequence++}',
        );
        expect(code, expectedCode);
        expect((await snapshots.load(project)).revision, beforeRevision);
        evidence[step.evidenceKey!] = code;
        continue;
      }
      if (step.dryRun) {
        final planned = await _planDirect(
          project,
          workspaceHandle: workspace.value,
          actionId: step.actionId,
          parameters: step.parameters,
          sequence: 'animation-${sequence++}',
          dryRun: true,
        );
        evidence[step.evidenceKey!] = planned.plan.preview;
        expect((await snapshots.load(project)).revision, beforeRevision);
        continue;
      }
      await _applyDirect(
        project,
        workspaceHandle: workspace.value,
        actionId: step.actionId,
        parameters: step.parameters,
        index: sequence++,
        requiresConfirmation: step.requiresConfirmation,
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
    return _animationEvidence(query, evidence);
  }

  Future<Map<String, Object?>> runAnimationJsonl() async {
    var opened = await _jsonl('open', <String, Object?>{
      'projectRoot': root.path,
    });
    var projectHandle = opened['projectHandle']! as String;
    var workspaceHandle = opened['workspaceHandle']! as String;
    final imported = await _jsonl('stage_artifact', <String, Object?>{
      'sourcePath': portraitPath,
      'declaredMediaType': 'image/png',
    });
    final replacement = await _jsonl('stage_artifact', <String, Object?>{
      'sourcePath': replacementPath,
      'declaredMediaType': 'image/png',
    });
    final evidence = <String, Object?>{};
    var sequence = 100;
    for (final step in _animationSteps(
      importedArtifactHandle: imported['artifactHandle']! as String,
      replacementArtifactHandle: replacement['artifactHandle']! as String,
    )) {
      final project = ProjectHandle(projectHandle);
      final beforeRevision = (await snapshots.load(project)).revision;
      if (step.expectedErrorCode case final expectedCode?) {
        final code = await _jsonlPlanFailureCode(
          projectHandle: projectHandle,
          workspaceHandle: workspaceHandle,
          expectedRevision: beforeRevision,
          actionId: step.actionId,
          parameters: step.parameters,
          sequence: 'animation-${sequence++}',
        );
        expect(code, expectedCode);
        expect((await snapshots.load(project)).revision, beforeRevision);
        evidence[step.evidenceKey!] = code;
        continue;
      }
      if (step.dryRun) {
        final planned = await _planJsonl(
          projectHandle: projectHandle,
          workspaceHandle: workspaceHandle,
          actionId: step.actionId,
          parameters: step.parameters,
          sequence: 'animation-${sequence++}',
          dryRun: true,
        );
        evidence[step.evidenceKey!] = (planned['plan']!
            as Map<String, Object?>)['preview']! as Map<String, Object?>;
        expect((await snapshots.load(project)).revision, beforeRevision);
        continue;
      }
      await _applyJsonl(
        projectHandle: projectHandle,
        workspaceHandle: workspaceHandle,
        actionId: step.actionId,
        parameters: step.parameters,
        index: sequence++,
        requiresConfirmation: step.requiresConfirmation,
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
    return _animationEvidence(query, evidence);
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
    } on CharacterStudioAssetException catch (error) {
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

  Map<String, Object?> _animationEvidence(
    Map<String, Object?> query,
    Map<String, Object?> stepEvidence,
  ) {
    final projectJson = File('${root.path}/project.json').readAsStringSync();
    final catalogJson = File(
      '${root.path}/$assetCatalogStorageKey',
    ).readAsStringSync();
    final manifest = ProjectManifest.fromJson(
      jsonDecode(projectJson) as Map<String, dynamic>,
    );
    final catalog = AssetCatalog.fromJson(
      jsonDecode(catalogJson) as Map<String, dynamic>,
    );
    final clip = manifest.characters.single.customAnimations.single;
    final deletePlan =
        stepEvidence['definitionDeletePlan']! as Map<String, Object?>;
    return <String, Object?>{
      'actionIds': _animationActionIds,
      'directionErrorCode': stepEvidence['directionErrorCode'],
      'geometryErrorCode': stepEvidence['geometryErrorCode'],
      'frameIndexErrorCode': stepEvidence['frameIndexErrorCode'],
      'definitionDeleteRequiresResolution': deletePlan['requiresResolution'],
      'customDefinitionIds': <Object?>[
        for (final definition
            in manifest.characterStudioCatalog.customAnimationDefinitions)
          definition.id,
      ],
      'customClipDefinitionId': clip.definitionId,
      'customClipDirection': clip.direction?.name,
      'customClipFrameCount': clip.frames.length,
      'assetIds': catalog.records.map((record) => record.id).toList(),
      'serializedAbsolutePath':
          projectJson.contains(root.path) || catalogJson.contains(root.path),
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

List<int> _png({required int width, required int height, int marker = 0}) {
  final bytes = List<int>.filled(24, 0);
  bytes.setRange(0, 8, const <int>[137, 80, 78, 71, 13, 10, 26, 10]);
  bytes[8] = marker;
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
