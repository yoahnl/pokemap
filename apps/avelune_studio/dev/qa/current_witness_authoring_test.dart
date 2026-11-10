import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'current_witness_preparation_test.dart' as preparation;

const _qa =
    '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109';
const _donor =
    '/Users/karim/Project/avelune project/nb2_bibliotheque_modulaire';
const _copy = '$_qa/current-witnesses/threeD';
const _blueprint = 't00-native-cliff';
const _layer = 't00-border';
const _feature = 't00-crest';
const _setupReceipt = '$_qa/t00-current-threeD-authoring-attempt2.json';
const _resumeReceipt =
    '$_qa/t00-current-threeD-authoring-attempt3-checkpoint.json';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('resumes native Border after eight committed QA actions without replaying them', () async {
    final initial = jsonDecode(
      await File('$_qa/t00-current-threeD-preparation.json').readAsString(),
    ) as Map<String, dynamic>;
    final source = Directory(initial['source'] as String);
    final root = Directory(_copy);
    final originalBefore = await preparation.fingerprintCurrentWitness(source);
    final copyBefore = await preparation.fingerprintCurrentWitness(root);
    expect(
      originalBefore['treeSha256'],
      (initial['originalAfter'] as Map)['treeSha256'],
    );
    final checkpointBytes = await File(_resumeReceipt).readAsBytes();
    expect(
      sha256.convert(checkpointBytes).toString(),
      '16b62f7f869e8eb044544bd0581238b2c941b323633e8a96a174e950c2e26f57',
    );
    final previous =
        jsonDecode(utf8.decode(checkpointBytes)) as Map<String, dynamic>;
    expect(
      copyBefore['treeSha256'],
      (previous['copyAfter'] as Map)['treeSha256'],
    );
    final before = await _manifest(root);
    final mapBefore = await _map(root, before);
    final record = <String, Object?>{
      'schemaVersion': 1,
      'temporalMeaning': 'CURRENT AFTER partial T01 extractions; intentional QA fixture mutations only',
      'original': source.path,
      'copy': root.path,
      'originalBefore': originalBefore,
      'copyBefore': copyBefore,
      'resumeCheckpoint': {
        'path': _resumeReceipt,
        'sha256': sha256.convert(checkpointBytes).toString(),
        'previousActionsReplayed': false,
      },
      'actions': <Map<String, Object?>>[],
      'nativeRender': 'not run',
      'export': 'not run',
      'player': 'not run',
      'saveResume': 'not run',
    };
    try {
      record['pruning'] =
          'Already completed in attempt1; no pruning during resume.';
      record['readBeforeResume'] = await preparation.readCurrentWitness(root);
      await _author(root, record, previous);
      record['readAfterIndependentReopen'] = await preparation
          .readCurrentWitness(root);
      final after = await _manifest(root);
      final mapAfter = await _map(root, after);
      expect(after.scenes, before.scenes);
      expect(after.eventRegistry, before.eventRegistry);
      expect(after.cinematics, before.cinematics);
      expect(mapAfter.warps, mapBefore.warps);
      expect(mapAfter.triggers, mapBefore.triggers);
      expect(
        mapAfter.layers.whereType<SmartTileLayer>().toList(),
        mapBefore.layers.whereType<SmartTileLayer>().toList(),
      );
      final scene = mapAfter.spatialScene!;
      expect(scene.worldHeightAt(7, 14.5), closeTo(1, .000001));
      expect(scene.worldHeightAt(8, 14.5), closeTo(1.5, .000001));
      expect(scene.worldHeightAt(9.5, 14.5), closeTo(2, .000001));
      expect(
        scene.rampHasTerrainContacts(
          scene.navigation.ramps.singleWhere((ramp) => ramp.id == 't00-ramp'),
        ),
        isTrue,
      );
      final border = mapAfter.layers
          .whereType<BorderLayer>()
          .singleWhere((layer) => layer.id == _layer)
          .content
          .features
          .single;
      expect(border.materialization, isNotNull);
      expect(border.generatedPlacementIds, isNotEmpty);
      final integrity = inspectSpatialMapIntegrity(
        manifest: after,
        map: mapAfter,
      );
      expect(integrity.exposedCellCount, 0);
      expect(integrity.unprovenCellCount, 0);
      expect(integrity.borderObjectOverlaps, isEmpty);
      record['status'] = 'canonical_authoring_and_independent_reopen_validated';
    } on Object catch (error, stack) {
      record['status'] = 'stopped_at_first_failure';
      record['error'] = error.toString();
      record['stack'] = stack.toString();
      rethrow;
    } finally {
      final originalAfter = await preparation.fingerprintCurrentWitness(source);
      final copyAfter = await preparation.fingerprintCurrentWitness(root);
      record['originalAfter'] = originalAfter;
      record['copyAfter'] = copyAfter;
      record['originalUnchanged'] =
          originalBefore['treeSha256'] == originalAfter['treeSha256'];
      record['copyDelta'] = _delta(copyBefore, copyAfter);
      await File('$_qa/t00-current-threeD-authoring.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert(record),
        flush: true,
      );
      expect(record['originalUnchanged'], isTrue);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}

Future<void> _author(
  Directory root,
  Map<String, Object?> record,
  Map<String, dynamic> checkpoint,
) async {
  const fileReader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [root.path],
    fileReader: fileReader,
  );
  final handles = WorkspaceHandleStore();
  final loader = ProjectSnapshotLoader(handles: handles);
  final opener = ProjectOpenService(
    policy: policy,
    fileReader: fileReader,
    handles: handles,
    initializeSceneOwners: false,
  );
  final opened = await opener.openProject(root.path);
  final mutations = LocalMapAuthoringMutationApi(
    policy: policy,
    snapshotLoader: loader,
  );
  try {
    if (opened.recoveryRequired) {
      throw StateError(
        'The owned witness requires explicit recovery before resumption: ${opened.recoveryOperationIds}',
      );
    }
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    final setupBytes = await File(_setupReceipt).readAsBytes();
    expect(
      sha256.convert(setupBytes).toString(),
      '1088e047c8e3a7654bb7f32d4eec08b9c87ff79207183a1de89bb560252868f0',
    );
    record['resumeVerification'] = await _verifyCommittedSetup(
      root,
      jsonDecode(utf8.decode(setupBytes)) as Map<String, dynamic>,
      await loader.load(opened.projectHandle),
    );
    final committed = (checkpoint['actions'] as List)
        .cast<Map<String, dynamic>>();
    expect(checkpoint['originalUnchanged'], isTrue);
    expect(committed.map((action) => action['action']).toList(), [
      'map.apply_operations',
      'map3d.terrain.surface.upsert_batch',
      'map3d.navigation.configure',
    ]);
    for (final action in committed) {
      expect((action['receipt'] as Map)['receipt']['status'], 'applied');
    }
    final planData = jsonDecode(
      await File('$_qa/t00-threeD-mutation-plan.json').readAsString(),
    ) as Map<String, dynamic>;
    final geometry = planData['geometry'] as Map<String, dynamic>;
    final current = await _map(root, await _manifest(root));
    final scene = current.spatialScene!;
    expect(
      current.layers
          .whereType<BorderLayer>()
          .singleWhere((layer) => layer.id == _layer)
          .content
          .features,
      isEmpty,
    );
    for (final key in ['plateau', 'slope']) {
      final expected = SpatialTerrainSurface.fromJson(
        Map<String, dynamic>.from(geometry[key] as Map),
      );
      expect(
        scene.terrainSurfaces.surfaces.singleWhere(
          (surface) => surface.id == expected.id,
        ),
        expected,
      );
    }
    expect(
      scene.navigation.toJson(),
      (committed[2]['parameters'] as Map)['navigation'],
    );
    expect((committed[1]['parameters'] as Map)['surfaces'], [
      geometry['plateau'],
      geometry['slope'],
    ]);
    record['eightAppliedActionsVerified'] = true;
    var sequence = 8;
    Future<void> apply(String action, Map<String, Object?> parameters) async {
      final id = 't00-witness-${++sequence}';
      final snapshot = await loader.load(opened.projectHandle);
      final plan = await mutations.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          workspaceHandle: opened.workspaceHandle.value,
          requestId: id,
          actionId: action,
          actionVersion: 1,
          expectedRevision: snapshot.revision,
          idempotencyKey: id,
          parameters: parameters,
        ),
      );
      final actionRecord = <String, Object?>{
        'action': action,
        'readMode': 'Explicit full canonical snapshot for qualification; no incremental performance claim.',
        'parameters': parameters,
        'plan': plan.toJson(),
      };
      (record['actions']! as List<Map<String, Object?>>).add(actionRecord);
      if (!plan.applicable || _hazard(plan.plan.preview)) {
        throw StateError(
          'Refused before apply: $action ${jsonEncode(plan.toJson())}',
        );
      }
      final result = await mutations.applyMutation(
        opened.projectHandle,
        planId: plan.planId,
        operationId: id,
      );
      actionRecord['receipt'] = result.toJson();
      if (result.receipt.status != AuthoringReceiptStatus.applied) {
        throw StateError('Mutation was not applied: $action');
      }
    }

    await apply('border_layer.feature_create', {
      'mapId': 'first-map',
      'layerId': _layer,
      'featureId': _feature,
      'name': 'T00 native crest',
      'blueprintId': _blueprint,
      'seed': '0',
      'lineSide': 'primary',
      'geometry': geometry['borderStroke'],
    });
    await apply('border_layer.materialize_apply', {
      'mapId': 'first-map',
      'layerId': _layer,
      'featureId': _feature,
    });
  } finally {
    await mutations.detachWorkspace(opened.workspaceHandle);
    opener.closeWorkspace(opened.workspaceHandle);
  }
}

bool _hazard(Object? value) {
  if (value is List) return value.any(_hazard);
  if (value is! Map) return false;
  for (final entry in value.entries) {
    if ({
          'warningCount',
          'groundGapsIntroducedCount',
          'borderObjectOverlapsIntroducedCount',
        }.contains(entry.key) &&
        entry.value is num &&
        (entry.value as num) > 0) {
      return true;
    }
    if ({
          'warnings',
          'groundGapsIntroduced',
          'borderObjectOverlapsIntroduced',
        }.contains(entry.key) &&
        entry.value is List &&
        (entry.value as List).isNotEmpty) {
      return true;
    }
    if (_hazard(entry.value)) return true;
  }
  return false;
}

Future<Map<String, Object?>> _verifyCommittedSetup(
  Directory root,
  Map<String, dynamic> checkpoint,
  ProjectSnapshot snapshot,
) async {
  final actions = (checkpoint['actions'] as List).cast<Map<String, dynamic>>();
  final expectedActions = [
    'model3d.import',
    'model3d.import',
    'model3d.import',
    'border.blueprint.draft.upsert',
    'border.blueprint.publish',
  ];
  if (actions.length != expectedActions.length ||
      checkpoint['originalUnchanged'] != true) {
    throw StateError(
      'The immutable checkpoint does not prove the five setup actions.',
    );
  }
  for (var i = 0; i < actions.length; i++) {
    final receipt = (actions[i]['receipt'] as Map)['receipt'] as Map;
    if (actions[i]['action'] != expectedActions[i] ||
        receipt['actionId'] != expectedActions[i] ||
        receipt['status'] != 'applied') {
      throw StateError(
        'The immutable checkpoint has an unexpected setup receipt at $i.',
      );
    }
  }
  final donor = await _manifest(Directory(_donor));
  final sourceBlueprint = donor.borderCatalog.recordById(
    'nb2-directed-cliff-route19-step-one-rounded',
  )!;
  final expectedIds = sourceBlueprint.draft.definition.primitives
      .map((primitive) => primitive.sourceModelId)
      .whereType<String>()
      .toSet();
  final importedIds = actions
      .take(3)
      .map((action) => (action['parameters'] as Map)['modelId'] as String)
      .toSet();
  if (expectedIds.length != 3 ||
      importedIds.length != 3 ||
      !expectedIds.containsAll(importedIds)) {
    throw StateError(
      'The committed model IDs do not match the selected donor blueprint.',
    );
  }
  final catalog = AssetCatalog.fromJson(
    jsonDecode(
      await File(p.join(root.path, assetCatalogStorageKey)).readAsString(),
    ) as Map<String, dynamic>,
  );
  final models = <Map<String, Object?>>[];
  for (final id in expectedIds.toList()..sort()) {
    final source = donor.models3d.singleWhere((model) => model.id == id);
    final current = snapshot.manifest.models3d.singleWhere(
      (model) => model.id == id,
    );
    final donorBytes = await File(p.join(_donor, source.relativePath))
        .readAsBytes();
    final bytes = await File(p.join(root.path, current.relativePath))
        .readAsBytes();
    final artifact = ContentArtifactRef.fromBytes(
      donorBytes,
      mediaType: 'model/gltf-binary',
    );
    final asset = catalog.require(current.sourceAssetId);
    final blob = await File(
      p.join(root.path, assetBlobStorageKey(asset.artifact)),
    ).readAsBytes();
    final importAction = actions
        .take(3)
        .singleWhere(
          (action) => (action['parameters'] as Map)['modelId'] == id,
        );
    if (sha256.convert(bytes) != sha256.convert(donorBytes) ||
        sha256.convert(blob) != sha256.convert(donorBytes) ||
        asset.artifact != artifact ||
        asset.logicalPath != current.relativePath ||
        (importAction['parameters'] as Map)['artifactHandle'] !=
            artifact.handle) {
      throw StateError(
        'A committed imported model differs from its verified donor: $id',
      );
    }
    models.add({
      'id': id,
      'sha256': sha256.convert(bytes).toString(),
      'artifactDigest': artifact.digest,
      'bytes': bytes.length,
    });
  }
  final draftParameters = actions[3]['parameters'] as Map;
  final publishedParameters = actions[4]['parameters'] as Map;
  final expectedDraft = decodeBorderBlueprintRecordJson(
    Map<String, dynamic>.from(draftParameters['record'] as Map),
    formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
  );
  final current = snapshot.manifest.borderCatalog.recordById(_blueprint);
  if (expectedDraft.id != _blueprint ||
      publishedParameters['blueprintId'] != _blueprint ||
      current == null ||
      current.latestPublished?.revision != 1 ||
      current.draft.baseRevision != 1 ||
      current.draft.definition != expectedDraft.draft.definition ||
      current.latestPublished?.definition !=
          sourceBlueprint.latestPublished?.definition) {
    throw StateError(
      'The published QA blueprint differs from the committed setup.',
    );
  }
  final encoded = encodeBorderBlueprintRecordJson(
    current,
    formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
  );
  return {
    'verifiedAppliedReceipts': 5,
    'models': models,
    'blueprintId': current.id,
    'blueprintRevision': current.latestPublished!.revision,
    'blueprintSha256': sha256
        .convert(utf8.encode(jsonEncode(encoded)))
        .toString(),
    'setupActionsReplayed': false,
    'nextOperationIdentity': 't00-witness-9',
    'resumeBoundary': 'Verify setup against attempt2 and current tree against immutable attempt3 before writing.',
  };
}

Future<ProjectManifest> _manifest(Directory root) async =>
    ProjectManifest.fromJson(
      jsonDecode(await File('${root.path}/project.json').readAsString())
          as Map<String, dynamic>,
    );

Future<MapData> _map(Directory root, ProjectManifest project) async =>
    MapData.fromJson(
      jsonDecode(
        await File(
          p.join(
            root.path,
            project.maps
                .singleWhere((map) => map.id == 'first-map')
                .relativePath,
          ),
        ).readAsString(),
      ) as Map<String, dynamic>,
    );

List<Map<String, Object?>> _delta(
  Map<String, Object?> before,
  Map<String, Object?> after,
) {
  final old = {
    for (final f in before['files']! as List<Map<String, Object?>>)
      f['path']: f,
  };
  final next = {
    for (final f in after['files']! as List<Map<String, Object?>>) f['path']: f,
  };
  return [
    for (final path in {
      ...old.keys,
      ...next.keys,
    }.toList()..sort((a, b) => (a! as String).compareTo(b! as String)))
      if (old[path]?['sha256'] != next[path]?['sha256'])
        {'path': path, 'before': old[path], 'after': next[path]},
  ];
}
