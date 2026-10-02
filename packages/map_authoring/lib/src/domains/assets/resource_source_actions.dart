import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/authoring_request.dart';
import '../../contracts/resource_ref.dart';
import '../../ports/artifact_store.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import 'asset_actions.dart';
import 'asset_store.dart';
import 'resource_source_guards.dart';
import 'resource_source_references.dart';
import 'tileset_actions.dart';

final class ResourceSourceActions {
  const ResourceSourceActions({this.artifactStore});

  final ArtifactStore? artifactStore;

  static final List<AuthoringActionDescriptor> descriptors = [
    visualLibraryDescriptor('tileset.source.replace',
        'Replace one compatible PNG and reconcile its mutable references',
        risk: AuthoringRiskLevel.high,
        resourceKinds: const [
          'project',
          'assetCatalog',
          'asset',
          'assetBlob'
        ],
        inputSchema: {
          'type': 'object',
          'additionalProperties': false,
          'required': ['tilesetId', 'artifactHandle'],
          'properties': {
            'tilesetId': {'type': 'string', 'minLength': 1},
            'artifactHandle': {'type': 'string', 'minLength': 1}
          }
        }),
    visualLibraryDescriptor('tileset.remove',
        'Remove an unreferenced tileset and optionally its unused logical source',
        risk: AuthoringRiskLevel.high,
        resourceKinds: const [
          'project',
          'assetCatalog',
          'asset'
        ],
        inputSchema: {
          'type': 'object',
          'additionalProperties': false,
          'required': ['tilesetId'],
          'properties': {
            'tilesetId': {'type': 'string', 'minLength': 1},
            'removeSource': {'type': 'boolean', 'default': false}
          }
        }),
  ];

  Future<AuthoringMutationDraft> build(AuthoringPlanningContext context) async {
    final parameters = VisualLibraryParameters(context.request.parameters);
    final replacing = context.request.actionId == 'tileset.source.replace';
    if (!replacing && context.request.actionId != 'tileset.remove') {
      throw VisualLibraryException('resource.source.action_unsupported',
          'This operation is not a resource source mutation.');
    }
    parameters.allow(replacing
        ? const {'tilesetId', 'artifactHandle'}
        : const {'tilesetId', 'removeSource'});
    final id = parameters.string('tilesetId');
    final tileset = context.snapshot.manifest.tilesets
        .where((entry) => entry.id == id)
        .firstOrNull;
    if (tileset == null) {
      throw VisualLibraryException(
          'tileset.unknown', 'The tileset no longer exists.');
    }
    if (!replacing) return removeResourceSource(context, tileset);
    final store = artifactStore;
    if (store == null) {
      throw VisualLibraryException('artifact.store_required',
          'Replacement requires the retained inspected candidate.');
    }
    final handle = parameters.string('artifactHandle');
    final candidate = store.inspect(handle);
    if (candidate == null) {
      throw const ArtifactStoreException(
          'artifact.unknown', 'The inspected candidate is no longer retained.');
    }
    final catalog = readResourceAssetCatalog(context.snapshot);
    final asset = requireResourceSourceAsset(tileset, catalog);
    requireResourceSourceCoverage(context.snapshot);
    final bytes = await store.read(handle);
    validateResourceSourcePng(
        context.snapshot, tileset, asset, candidate, bytes);
    if (candidate.digest == asset.artifact.digest) {
      return AuthoringMutationDraft(
          changeSet: AuthoringChangeSet.noChanges(),
          preview: {
            'operation': context.request.actionId,
            'noOp': true,
            'tilesetId': id,
            'assetId': asset.id
          });
    }
    final replaced = const AssetActions()
        .replace(catalog, assetId: asset.id, artifact: candidate)
        .after!;
    final references =
        replaceResourceSourceReferences(context.snapshot, asset, replaced);
    final assetDraft = await AssetActions(artifactStore: store).build(
        AuthoringPlanningContext(
            snapshot: context.snapshot,
            request: AuthoringRequest(
                requestId: context.request.requestId,
                actionId: 'asset.replace',
                actionVersion: 1,
                workspaceHandle: context.request.workspaceHandle,
                parameters: {'assetId': asset.id, 'artifactHandle': handle}),
            planId: context.planId,
            seed: context.seed));
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
          changes: [
            ...assetDraft.changeSet.changes,
            ...references.changeSet.changes
          ],
          diff: AuthoringDiff([
            ...assetDraft.changeSet.diff.entries,
            ...references.changeSet.diff.entries
          ])),
      preview: {
        'operation': context.request.actionId,
        'tilesetId': id,
        'assetId': asset.id,
        'before': asset.toJson(),
        'after': replaced.toJson(),
        'pixelWidth':
            (tileset.source as ProjectRegularAtlasTilesetSource).pixelWidth,
        'pixelHeight':
            (tileset.source as ProjectRegularAtlasTilesetSource).pixelHeight,
        'immutableVersionsPreserved': true,
        'oldBlobPreserved': true,
        'mutableOwners': references.preview['mutableOwners'],
        'transparencyPolicy':
            'manual collision and shadow definitions unchanged'
      },
      referenceImpact: {
        ...assetDraft.referenceImpact,
        ...references.referenceImpact
      },
      artifacts: assetDraft.artifacts,
      projectedProject: references.projectedProject,
    );
  }
}

AuthoringMutationDraft removeResourceSource(
    AuthoringPlanningContext context, ProjectTilesetEntry tileset) {
  requireResourceSourceUnused(context.snapshot, tileset);
  final value = context.request.parameters['removeSource'];
  if (value != null && value is! bool) {
    throw VisualLibraryException('visual.parameter_invalid',
        'The source removal option must be boolean.');
  }
  final removeSource = value == true;
  final next = context.snapshot.manifest.copyWith(tilesets: [
    for (final entry in context.snapshot.manifest.tilesets)
      if (entry.id != tileset.id) entry
  ]);
  final manifestDraft = buildVisualManifestDraft(context.snapshot, next,
      operation: 'tileset.remove',
      path: '/tilesets/${tileset.id}',
      before: tileset.toJson(),
      after: null,
      encodedManifest: encodeSourceManifest(context.snapshot, next));
  if (!removeSource) {
    var sourceRemovalSupported = false;
    String? sourceRemovalReason;
    try {
      final catalog = readResourceAssetCatalog(context.snapshot);
      final asset = requireResourceSourceAsset(tileset, catalog);
      requireResourceSourceBytes(context.snapshot, asset);
      requireResourceAssetUnused(context.snapshot, next, asset);
      sourceRemovalSupported = true;
    } on VisualLibraryException catch (error) {
      sourceRemovalReason = error.message;
    }
    return AuthoringMutationDraft(
        changeSet: manifestDraft.changeSet,
        projectedProject: next,
        preview: {
          'operation': 'tileset.remove',
          'tilesetId': tileset.id,
          'sourceRemoved': false,
          'blobPreserved': true,
          'sourceRemovalSupported': sourceRemovalSupported,
          if (sourceRemovalReason != null)
            'sourceRemovalReason': sourceRemovalReason
        });
  }
  final catalog = readResourceAssetCatalog(context.snapshot);
  final asset = requireResourceSourceAsset(tileset, catalog);
  final sourceBytes = requireResourceSourceBytes(context.snapshot, asset);
  requireResourceAssetUnused(context.snapshot, next, asset);
  final resource = AuthoringResourceRef(
      kind: 'assetCatalog',
      id: 'project',
      revision:
          context.snapshot.resourceFingerprints[assetCatalogResourceIdentity]);
  final changes = [
    ...manifestDraft.changeSet.changes,
    AuthoringResourceChange(
        resource: resource,
        storageKey: assetCatalogStorageKey,
        beforeBytes:
            context.snapshot.resourceBytes(assetCatalogResourceIdentity),
        afterBytes: utf8.encode(jsonEncode(AssetCatalog(records: [
          for (final record in catalog.records)
            if (record.id != asset.id) record
        ]).toJson())))
  ];
  final extraDiff = <AuthoringDiffEntry>[];
  if (asset.logicalPath != assetBlobStorageKey(asset.artifact)) {
    final fileResource = AuthoringResourceRef(kind: 'asset', id: asset.id);
    changes.add(AuthoringResourceChange(
        resource: fileResource,
        storageKey: asset.logicalPath,
        beforeBytes: sourceBytes,
        afterBytes: null));
    extraDiff.add(AuthoringDiffEntry(
        operation: AuthoringDiffOperation.remove,
        resource: fileResource,
        path: '/',
        before: asset.artifact.toJson()));
  }
  return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
          changes: changes,
          diff: AuthoringDiff([
            ...manifestDraft.changeSet.diff.entries,
            ...extraDiff,
            AuthoringDiffEntry(
                operation: AuthoringDiffOperation.remove,
                resource: resource,
                path: '/records/${asset.id}',
                before: asset.toJson())
          ])),
      projectedProject: next,
      preview: {
        'operation': 'tileset.remove',
        'tilesetId': tileset.id,
        'assetId': asset.id,
        'sourceRemoved': true,
        'sourceRemovalSupported': true,
        'logicalFileRemoved':
            asset.logicalPath != assetBlobStorageKey(asset.artifact),
        'logicalSourcePath': asset.logicalPath,
        'blobPreserved': true
      },
      referenceImpact: {
        'logicalSourceRemoved': true,
        'blobDeleted': false
      });
}
