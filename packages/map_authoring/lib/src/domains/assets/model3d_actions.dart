import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/artifact_ref.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/authoring_request.dart';
import '../../ports/artifact_store.dart';
import '../../support/authoring_fingerprint.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';
import 'asset_actions.dart';
import 'asset_store.dart';
import 'package:map_distribution/map_distribution.dart';
import 'tileset_actions.dart';

final class Model3dActions {
  const Model3dActions({this.artifactStore, this.retainedBlobReader});
  final ArtifactStore? artifactStore;
  final RetainedAssetBlobReader? retainedBlobReader;
  static const maximumModelCount = 50;
  static const maximumTotalByteLength = 64 * 1024 * 1024;
  static const maximumInlineModelDiffByteLength = 8 * 1024;

  static final descriptors = [
    for (final action in ['import', 'import_batch', 'configure', 'delete'])
      AuthoringActionDescriptor(
        id: 'model3d.$action',
        version: 1,
        summary: switch (action) {
          'import' => 'Import an inspected standalone GLB model atomically',
          'import_batch' =>
            'Import 1 to 50 inspected GLB models in one recoverable publication',
          'configure' => 'Configure a model name, scale and pivot',
          _ => 'Delete an unused model and its owned source'
        },
        inputSchemaId: 'pokemap.authoring.model3d.$action.input.v1',
        outputSchemaId: 'pokemap.authoring.model3d.$action.output.v1',
        riskLevel: action == 'delete'
            ? AuthoringRiskLevel.high
            : AuthoringRiskLevel.medium,
        resourceKinds: const [
          'project',
          'model3d',
          'assetCatalog',
          'asset',
          'assetBlob'
        ],
        capabilityIds: const ['authoring.visual_library'],
        requiredPermissions: [
          AuthoringPermission.projectWrite,
          if (action.startsWith('import')) AuthoringPermission.importRun
        ],
        guarantees: [
          AuthoringGuarantee.dryRun,
          AuthoringGuarantee.idempotent,
          if (action != 'import_batch') AuthoringGuarantee.atomic,
          AuthoringGuarantee.revisionChecked,
          AuthoringGuarantee.undoable
        ],
        extensions: {
          if (action == 'import_batch') ...{
            'maximumModelCount': maximumModelCount,
            'maximumTotalByteLength': maximumTotalByteLength,
            'publicationSemantics': 'recoverable_cross_file',
            'diffProjection': 'batch_model_additions',
            'maximumInlineModelDiffByteLength':
                maximumInlineModelDiffByteLength,
            'inputSchema': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['models'],
              'properties': {
                'models': {
                  'type': 'array',
                  'minItems': 1,
                  'maxItems': maximumModelCount,
                  'items': {
                    'type': 'object',
                    'additionalProperties': false,
                    'required': ['modelId', 'name', 'artifactHandle'],
                    'properties': {
                      'modelId': {
                        'type': 'string',
                        'pattern': r'^[a-zA-Z0-9_-]{1,128}$'
                      },
                      'name': {
                        'type': 'string',
                        'minLength': 1,
                        'maxLength': 256
                      },
                      'artifactHandle': {'type': 'string', 'minLength': 1}
                    }
                  }
                }
              }
            }
          } else
            'inputSchema': {
              'type': 'object',
              'additionalProperties': false,
              'required': [
                'modelId',
                if (action == 'import') ...['artifactHandle', 'name']
              ],
              'properties': {
                'modelId': {
                  'type': 'string',
                  'pattern': r'^[a-zA-Z0-9_-]{1,128}$'
                },
                if (action == 'import')
                  'artifactHandle': {'type': 'string', 'minLength': 1},
                if (action != 'delete')
                  'name': {'type': 'string', 'minLength': 1, 'maxLength': 256},
                if (action == 'configure') ...{
                  'scale': {
                    'type': 'number',
                    'exclusiveMinimum': 0,
                    'maximum': 1000000
                  },
                  'pivot': {
                    'type': 'object',
                    'additionalProperties': false,
                    'required': ['x', 'y', 'z'],
                    'properties': {
                      for (final axis in ['x', 'y', 'z'])
                        axis: {'type': 'number'}
                    }
                  }
                }
              }
            }
        },
      ),
  ];

  Future<AuthoringMutationDraft> build(AuthoringPlanningContext context) async {
    if (context.request.actionId == 'model3d.import_batch') {
      return _importBatch(context);
    }
    final parameters = VisualLibraryParameters(context.request.parameters);
    final action = context.request.actionId;
    parameters.allow(switch (action) {
      'model3d.import' => {'modelId', 'name', 'artifactHandle'},
      'model3d.configure' => {'modelId', 'name', 'scale', 'pivot'},
      'model3d.delete' => {'modelId'},
      _ => throw const FormatException('Unknown model action.'),
    });
    final id = parameters.string('modelId');
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id)) {
      throw const FormatException('Invalid model identity.');
    }
    final current =
        context.snapshot.manifest.models3d.where((v) => v.id == id).firstOrNull;
    if (action == 'model3d.import') {
      if (current != null) {
        throw const FormatException('Model identity is already in use.');
      }
      final store = artifactStore;
      if (store == null) {
        throw const FormatException('An artifact store is required.');
      }
      final handle = parameters.string('artifactHandle');
      try {
        final artifact = store.inspect(handle);
        if (artifact == null) {
          throw const FormatException('The staged model is unavailable.');
        }
        final bytes = await store.read(handle);
        final actual =
            ContentArtifactRef.fromBytes(bytes, mediaType: artifact.mediaType);
        if (actual.digest != artifact.digest ||
            actual.byteLength != artifact.byteLength) {
          throw const FormatException('The staged model content changed.');
        }
        final inspection = const GlbModel3dInspector().inspect(bytes);
        final model = ProjectModel3dEntry(
            id: id,
            name: parameters.string('name'),
            sourceAssetId: 'model3d_$id',
            relativePath: 'assets/models3d/$id.glb',
            inspection: inspection);
        final assetDraft =
            await _asset(context, context.snapshot, 'asset.import', {
          'artifactHandle': handle,
          'assetId': model.sourceAssetId,
          'logicalPath': model.relativePath
        });
        final manifest = context.snapshot.manifest
            .copyWith(models3d: [...context.snapshot.manifest.models3d, model]);
        final result = _compose(context, manifest,
            before: null, after: model, assetDraft: assetDraft);
        if (context.request.dryRun) await store.release(handle);
        return result;
      } on Object {
        await store.release(handle);
        rethrow;
      }
    }
    if (current == null) throw const FormatException('Unknown model identity.');
    if (action == 'model3d.configure') {
      final fields = context.request.parameters;
      if (fields.containsKey('scale') && fields['scale'] is! num) {
        throw const FormatException('Scale must be numeric.');
      }
      if (fields.containsKey('pivot') && fields['pivot'] is! Map) {
        throw const FormatException('Pivot must be an object.');
      }
      final next = current.copyWith(
          name: fields.containsKey('name') ? parameters.string('name') : null,
          scale: fields['scale'] as num?,
          pivot: fields.containsKey('pivot')
              ? Model3dVector3.fromJson(
                  Map<String, dynamic>.from(fields['pivot'] as Map))
              : null);
      return _compose(
          context,
          context.snapshot.manifest.copyWith(models3d: [
            for (final model in context.snapshot.manifest.models3d)
              model.id == id ? next : model
          ]),
          before: current,
          after: next);
    }
    for (final map in context.snapshot.maps) {
      if (map.spatialScene?.instances
              .any((instance) => instance.modelId == id) ??
          false) {
        throw const FormatException(
            'The model is referenced by a map and cannot be deleted.');
      }
    }
    final manifest = context.snapshot.manifest.copyWith(models3d: [
      for (final model in context.snapshot.manifest.models3d)
        if (model.id != id) model
    ]);
    final projected = ProjectSnapshot(
        projectHandle: context.snapshot.projectHandle,
        revision: context.snapshot.revision,
        manifest: manifest,
        pokemonInventoryComplete: context.snapshot.pokemonInventoryComplete,
        maps: context.snapshot.maps,
        resourceFingerprints: context.snapshot.resourceFingerprints,
        resourceBytes: {
          for (final identity in context.snapshot.resourceFingerprints.keys)
            identity: context.snapshot.resourceBytes(identity)
        },
        resourceStorageKeys: context.snapshot.resourceStorageKeys);
    final catalog = AssetCatalog.fromJson(jsonDecode(utf8.decode(
            context.snapshot.resourceBytes(assetCatalogResourceIdentity)))
        as Map<String, dynamic>);
    final source = catalog.require(current.sourceAssetId);
    final remainingUsages = deriveAssetUsages(
        manifest: manifest, maps: context.snapshot.maps, asset: source);
    final assetDraft = remainingUsages.isEmpty
        ? await _asset(context, projected, 'asset.delete',
            {'assetId': current.sourceAssetId})
        : null;
    return _compose(context, manifest,
        before: current, after: null, assetDraft: assetDraft);
  }

  Future<AuthoringMutationDraft> _importBatch(
      AuthoringPlanningContext context) async {
    final parameters = VisualLibraryParameters(context.request.parameters)
      ..allow(const {'models'});
    final inputs = parameters.objects('models');
    if (inputs.isEmpty || inputs.length > maximumModelCount) {
      throw const FormatException('Expected 1 to 50 model imports.');
    }
    final store = artifactStore;
    if (store == null) {
      throw const FormatException('An artifact store is required.');
    }
    final handles = {
      for (final input in inputs)
        if (input['artifactHandle'] is String) input['artifactHandle'] as String
    };
    try {
      final identities =
          context.snapshot.manifest.models3d.map((model) => model.id).toSet();
      final artifacts = <String, ContentArtifactRef>{};
      final entries = <({String id, String name, String handle})>[];
      var byteLength = 0;
      for (final input in inputs) {
        final fields = VisualLibraryParameters(input)
          ..allow(const {'modelId', 'name', 'artifactHandle'});
        final id = fields.string('modelId');
        if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id) ||
            !identities.add(id)) {
          throw const FormatException('Model identity is invalid or in use.');
        }
        final name = fields.string('name');
        if (name.length > 256) {
          throw const FormatException('Model name exceeds 256 characters.');
        }
        final handle = fields.string('artifactHandle');
        final artifact = store.inspect(handle);
        if (artifact == null) {
          throw const FormatException('The staged model is unavailable.');
        }
        if (artifact.mediaType != 'model/gltf-binary') {
          throw const FormatException('Model sources must be GLB artifacts.');
        }
        byteLength += artifact.byteLength;
        if (byteLength > maximumTotalByteLength) {
          throw const FormatException('Model batch exceeds 64 MiB.');
        }
        artifacts[handle] = artifact;
        entries.add((id: id, name: name, handle: handle));
      }
      final assetDraft =
          await _asset(context, context.snapshot, 'asset.import_batch', {
        'entries': [
          for (final entry in entries)
            {
              'artifactHandle': entry.handle,
              'assetId': 'model3d_${entry.id}',
              'logicalPath': 'assets/models3d/${entry.id}.glb'
            }
        ]
      });
      final payloads = {
        for (final change in assetDraft.changeSet.changes)
          change.storageKey: change.afterBytes
      };
      final inspections = <String, Model3dInspection>{};
      final models = <ProjectModel3dEntry>[];
      var actualByteLength = 0;
      for (final entry in entries) {
        final path = 'assets/models3d/${entry.id}.glb';
        final bytes = payloads[path]!;
        final artifact = artifacts[entry.handle]!;
        actualByteLength += bytes.length;
        if (actualByteLength > maximumTotalByteLength) {
          throw const FormatException('Model batch exceeds 64 MiB.');
        }
        final actual =
            ContentArtifactRef.fromBytes(bytes, mediaType: artifact.mediaType);
        if (actual.digest != artifact.digest ||
            actual.byteLength != artifact.byteLength) {
          throw const FormatException('The staged model content changed.');
        }
        final inspection = inspections.putIfAbsent(
            entry.handle, () => const GlbModel3dInspector().inspect(bytes));
        models.add(ProjectModel3dEntry(
            id: entry.id,
            name: entry.name,
            sourceAssetId: 'model3d_${entry.id}',
            relativePath: path,
            inspection: inspection));
      }
      final manifest = context.snapshot.manifest.copyWith(
          models3d: [...context.snapshot.manifest.models3d, ...models]);
      final projectDraft = buildVisualManifestDraft(context.snapshot, manifest,
          operation: context.request.actionId, path: '/models3d');
      final result = AuthoringMutationDraft(
          changeSet: AuthoringChangeSet(
              changes: [
                ...assetDraft.changeSet.changes,
                ...projectDraft.changeSet.changes
              ],
              diff: AuthoringDiff([
                ...assetDraft.changeSet.diff.entries,
                for (final model in models)
                  AuthoringDiffEntry(
                      operation: AuthoringDiffOperation.add,
                      resource: projectDraft.changeSet.changes.single.resource,
                      path: '/models3d/${model.id}',
                      after: _modelBatchDiffValue(model))
              ])),
          projectedProject: manifest,
          preview: {
            'operation': context.request.actionId,
            'importedCount': models.length,
            'modelIds': models.map((model) => model.id).toList(),
            'beforeModelCount': context.snapshot.manifest.models3d.length,
            'afterModelCount': manifest.models3d.length,
            'totalByteLength': actualByteLength,
            'publicationSemantics': 'recoverable_cross_file'
          },
          artifacts: assetDraft.artifacts,
          referenceImpact: assetDraft.referenceImpact);
      if (context.request.dryRun) {
        for (final handle in handles) {
          await store.release(handle);
        }
      }
      return result;
    } on Object {
      for (final handle in handles) {
        await store.release(handle);
      }
      rethrow;
    }
  }

  Future<AuthoringMutationDraft> _asset(
          AuthoringPlanningContext context,
          ProjectSnapshot snapshot,
          String action,
          Map<String, Object?> parameters) =>
      AssetActions(
              artifactStore: artifactStore,
              retainedBlobReader: retainedBlobReader)
          .build(AuthoringPlanningContext(
              snapshot: snapshot,
              request: AuthoringRequest(
                  requestId: context.request.requestId,
                  actionId: action,
                  actionVersion: 1,
                  workspaceHandle: context.request.workspaceHandle,
                  parameters: parameters),
              planId: context.planId,
              seed: context.seed));
}

Map<String, Object?> _modelBatchDiffValue(ProjectModel3dEntry model) {
  final value = model.toJson();
  final bytes = utf8.encode(canonicalAuthoringJson(value));
  if (bytes.length <= Model3dActions.maximumInlineModelDiffByteLength) {
    return value;
  }
  final inspection = model.inspection;
  return {
    'modelSummary': {
      'id': model.id,
      'name': model.name,
      'sourceAssetId': model.sourceAssetId,
      'relativePath': model.relativePath,
      'scale': model.scale,
      'pivot': model.pivot.toJson(),
      'inspection': {
        'bounds': inspection.bounds.toJson(),
        'meshCount': inspection.meshCount,
        'triangleCount': inspection.triangleCount,
        'materialCount': inspection.materials.length,
        'animationCount': inspection.animations.length,
        'diagnosticCount': inspection.diagnostics.length,
      },
      'fingerprintDomain': 'model3d-entry.json',
      'fingerprint': computeAuthoringBytesFingerprint(bytes,
          logicalName: 'model3d-entry.json'),
      'byteLength': bytes.length,
    },
  };
}

AuthoringMutationDraft _compose(
    AuthoringPlanningContext context, ProjectManifest manifest,
    {required ProjectModel3dEntry? before,
    required ProjectModel3dEntry? after,
    AuthoringMutationDraft? assetDraft}) {
  final draft = buildVisualManifestDraft(context.snapshot, manifest,
      operation: context.request.actionId,
      path: '/models3d/${after?.id ?? before!.id}',
      before: before?.toJson(),
      after: after?.toJson());
  return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
          changes: [
            ...?assetDraft?.changeSet.changes,
            ...draft.changeSet.changes
          ],
          diff: AuthoringDiff([
            ...?assetDraft?.changeSet.diff.entries,
            ...draft.changeSet.diff.entries
          ])),
      projectedProject: manifest,
      preview: {
        'operation': context.request.actionId,
        'modelId': after?.id ?? before!.id,
        if (after != null) 'model': after.toJson()
      },
      artifacts: assetDraft?.artifacts ?? const [],
      referenceImpact: assetDraft?.referenceImpact ?? const {});
}
