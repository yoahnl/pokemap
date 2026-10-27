import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../catalog_storage/catalog_storage_store.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../domains/assets/asset_store.dart';
import '../../domains/assets/model3d_actions.dart';
import '../../support/authoring_fingerprint.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../transactions/plan_store.dart';
import '../project_snapshot.dart';
import '../workspace_handle_store.dart';
import 'catalog_project_reader.dart';
import 'catalog_workshop_selection.dart';

final class CatalogModelSourceSelection {
  CatalogModelSourceSelection._(this.reader, this.snapshot, this.units,
      this.resourceRevisions, this.descriptorRevision);

  final CatalogProjectReader reader;
  final ProjectSnapshot snapshot;
  final Map<String, CatalogDefinitionUnit> units;
  final Map<String, String?> resourceRevisions;
  final String descriptorRevision;

  static bool supports(String action) => const {
        'model3d.source.replace',
        'model3d.source.replace_batch',
      }.contains(action);

  static Future<CatalogModelSourceSelection> read({
    required CatalogProjectReader reader,
    required ProjectHandle projectHandle,
    required String actionId,
    required Map<String, Object?> parameters,
  }) async {
    if (!supports(actionId)) {
      throw const FormatException('Unsupported model source action.');
    }
    final entries = actionId == 'model3d.source.replace'
        ? [parameters]
        : parameters['models'];
    if (entries is! List ||
        entries.isEmpty ||
        entries.length > Model3dActions.maximumModelCount) {
      throw const FormatException(
          'Expected 1 to 50 model source replacements.');
    }
    if (actionId.endsWith('_batch') &&
        parameters.keys.any((key) => key != 'models')) {
      throw const FormatException('Unknown model source batch parameter.');
    }
    final ids = <String>{};
    for (final entry in entries) {
      if (entry is! Map ||
          entry.keys
              .any((key) => !{'modelId', 'artifactHandle'}.contains(key))) {
        throw const FormatException('Invalid model source replacement.');
      }
      final id = entry['modelId'];
      if (id is! String ||
          !RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id) ||
          !ids.add(id)) {
        throw const FormatException('Model identity is invalid or duplicated.');
      }
    }
    final selected = await reader.withMetadataFields({'settings'});
    return selected.read((catalog) async {
      await reader.store.requireMetadataIndexAdmission(catalog.snapshot);
      final units = <String, CatalogDefinitionUnit>{};
      final models = <ProjectModel3dEntry>[];
      for (final id in ids) {
        final unit = await catalog
            .lookup(CatalogDefinitionKey(CatalogDefinitionKind.model3d, id));
        if (unit == null) {
          throw const FormatException('Unknown model identity.');
        }
        units[id] = unit;
        models.add(ProjectModel3dEntry.fromJson(
            Map<String, dynamic>.from(unit.payload['value'] as Map)));
      }
      final resources = <String, List<int>>{};
      final fingerprints = <String, String>{};
      final storageKeys = <String, String>{};
      final revisions = <String, String?>{};
      final digests = <String, String>{};
      Future<void> readFile(String identity, String path,
          {bool dependency = true}) async {
        final bytes = await reader.store.gateway.readResource(path);
        if (bytes == null) {
          throw FormatException(
              'The model source dependency $identity is missing.');
        }
        final revision = computeAuthoringBytesFingerprint(bytes, logicalName: path);
        resources[identity] = bytes;
        fingerprints[identity] = revision;
        if (identity.startsWith('model3d:')) {
          digests[identity] = computeAuthoringBytesFingerprint(bytes,
              logicalName: 'artifact-content');
        }
        storageKeys[identity] = path;
        if (dependency) revisions[path] = revision;
      }

      await readFile('catalogDescriptor', 'project.json', dependency: false);
      await readFile('catalogHead', CatalogStorageStore.headStorageKey,
          dependency: false);
      if (canonicalAuthoringJson(
                  jsonDecode(utf8.decode(resources['catalogDescriptor']!))) !=
              canonicalAuthoringJson(reader.descriptor) ||
          canonicalAuthoringJson(
                  jsonDecode(utf8.decode(resources['catalogHead']!))) !=
              canonicalAuthoringJson(jsonDecode(utf8.decode(
                  CatalogStorageStore.encodeHead(catalog.snapshot.root))))) {
        throw AuthoringPlanException(
            code: 'plan.stale',
            message: 'The catalog changed while selecting model sources.');
      }
      await readFile(assetCatalogResourceIdentity, assetCatalogStorageKey);
      final assets = AssetCatalog.fromJson(Map<String, dynamic>.from(
          jsonDecode(utf8.decode(resources[assetCatalogResourceIdentity]!))
              as Map));
      for (final model in models) {
        final source = assets.require(model.sourceAssetId);
        if (source.logicalPath != model.relativePath) {
          throw const FormatException(
              'The model source path differs from its asset record.');
        }
        await readFile('model3d:${model.id}', model.relativePath);
        if (digests['model3d:${model.id}'] != source.artifact.digest ||
            resources['model3d:${model.id}']!.length !=
                source.artifact.byteLength) {
          throw AuthoringPlanException(
              code: 'catalog.model_source_artifact_mismatch',
              message:
                  'The model source bytes differ from their registered artifact. Repair the source registry explicitly before replacement.');
        }
      }
      final settings = catalog.projectMetadata.settings;
      final manifest = ProjectManifest(
          name: catalog.projectMetadata.name,
          version: settings.dimension == ProjectDimension.threeD
              ? ProjectVersion.v9
              : ProjectVersion.v8,
          settings: ProjectSettings(
              dimension: settings.dimension,
              spatialCamera: settings.spatialCamera,
              tileWidth: settings.tileWidth,
              tileHeight: settings.tileHeight),
          maps: const [],
          tilesets: const [],
          models3d: models);
      final projectBytes = utf8.encode(jsonEncode(manifest.toJson()));
      resources['project'] = projectBytes;
      fingerprints['project'] = computeAuthoringBytesFingerprint(projectBytes,
          logicalName: 'project.json');
      storageKeys['project'] = 'project.json';
      final snapshot = ProjectSnapshot(
          projectHandle: projectHandle,
          revision: CatalogWorkshopSelection.fingerprint(
              selected.revision, revisions),
          materializedCatalogProject: true,
          availableProjectSections: {'settings', 'models3d'},
          availableProjectDocuments: {'models3d': ids},
          scopedStorageRevisions: revisions,
          manifest: manifest,
          maps: const [],
          resourceBytes: resources,
          resourceFingerprints: fingerprints,
          resourceStorageKeys: storageKeys);
      final result = CatalogModelSourceSelection._(selected, snapshot, units,
          revisions, fingerprints['catalogDescriptor']!);
      if (await result.currentRevision() != snapshot.revision) {
        throw AuthoringPlanException(
            code: 'plan.stale',
            message: 'The model sources changed while reading.');
      }
      return result;
    });
  }

  Future<String> currentRevision() async {
    if (await reader.store.gateway.readResourceRevision('project.json') !=
        descriptorRevision) {
      throw AuthoringPlanException(
          code: 'plan.stale',
          message: 'The project descriptor changed before publication.');
    }
    final head = await reader.store.readHead();
    if (head == null) {
      throw AuthoringPlanException(
          code: 'plan.stale',
          message: 'The catalog disappeared before publication.');
    }
    return CatalogWorkshopSelection.fingerprint('sha256:${head.sha256}', {
      for (final path in resourceRevisions.keys)
        path: await reader.store.gateway.readResourceRevision(path),
    });
  }

  Future<CatalogModelSourceMutation> translate(AuthoringPlan plan) async {
    var projected = snapshot.manifest;
    final additional = <AuthoringResourceChange>[];
    final allowedPaths = resourceRevisions.keys.toSet();
    for (final change in plan.changeSet.changes) {
      if (change.storageKey == 'project.json') {
        if (change.resource.kind != 'project' || change.afterPayload == null) {
          throw const FormatException('Invalid model project change.');
        }
        projected = ProjectManifest.fromJson(Map<String, dynamic>.from(
            jsonDecode(utf8.decode(await change.afterPayload!.readBytes()))
                as Map));
      } else {
        if (!allowedPaths.contains(change.storageKey) &&
            !(change.resource.kind == 'assetBlob' &&
                change.beforePayload == null &&
                RegExp(r'^assets/\.pokemap-store/[0-9a-f]{64}\.blob$')
                    .hasMatch(change.storageKey))) {
          throw AuthoringPlanException(
              code: 'catalog.mutation_outside_scope',
              message: 'The replacement changes an undeclared storage unit.');
        }
        additional.add(change);
      }
    }
    final beforeJson = snapshot.manifest.toJson()..remove('models3d');
    final afterJson = projected.toJson()..remove('models3d');
    if (canonicalAuthoringJson(beforeJson) !=
            canonicalAuthoringJson(afterJson) ||
        projected.models3d.length != units.length) {
      throw AuthoringPlanException(
          code: 'catalog.mutation_outside_scope',
          message: 'The replacement changes an undeclared project section.');
    }
    final upserts = <CatalogDefinitionUnit>[];
    for (final model in projected.models3d) {
      final original = units[model.id];
      if (original == null) {
        throw const FormatException('The model identity changed.');
      }
      final before = snapshot.manifest.models3d
          .singleWhere((candidate) => candidate.id == model.id);
      final retainedCollision = Model3dActions.retainedSourceCollisionBounds(
          before, model.inspection);
      final beforeModel = before.toJson()
        ..remove('inspection')
        ..remove('collisionBounds');
      final afterModel = model.toJson()
        ..remove('inspection')
        ..remove('collisionBounds');
      if (model.collisionBounds != retainedCollision ||
          canonicalAuthoringJson(beforeModel) !=
              canonicalAuthoringJson(afterModel)) {
        throw AuthoringPlanException(
            code: 'catalog.mutation_outside_scope',
            message: 'The replacement changes model placement metadata.');
      }
      Model3dActions.requireLocalSourceContract(
          before.inspection, model.inspection);
      if (model == before) continue;
      final value = Map<String, Object?>.from(original.payload['value'] as Map);
      value['inspection'] = model.inspection.toJson();
      if (retainedCollision != null) {
        value['collisionBounds'] = retainedCollision.toJson();
      }
      upserts.add(CatalogDefinitionUnit(
          key: original.key,
          payload: {...original.payload, 'value': value},
          references: original.references));
    }
    final paths = resourceRevisions.keys.toList()..sort();
    final resource = AuthoringResourceRef(
        kind: 'catalogHead',
        id: 'catalog',
        extensions: {'workshopResourcePaths': paths});
    final fingerprint = additional.isEmpty
        ? null
        : computeAuthoringJsonFingerprint({
            'catalogRevision': reader.revision,
            'resources': {
              for (final change in additional)
                change.storageKey: change.afterRevision
            },
          }, logicalName: 'catalog-workshop-state.json');
    return CatalogModelSourceMutation(
        projected,
        upserts,
        additional,
        fingerprint,
        AuthoringDiff([
          for (final entry in plan.changeSet.diff.entries)
            if (entry.resource.kind == 'project')
              AuthoringDiffEntry.fromJson(
                  {...entry.toJson(), 'resource': resource.toJson()})
            else
              entry,
          AuthoringDiffEntry(
              operation: AuthoringDiffOperation.replace,
              resource: resource,
              path: '/workshopRevision',
              before: snapshot.revision,
              after: fingerprint ?? reader.revision),
        ]));
  }
}

final class CatalogModelSourceMutation {
  const CatalogModelSourceMutation(this.projectedProject, this.upserts,
      this.additionalChanges, this.workspaceFingerprint, this.diff);

  final ProjectManifest projectedProject;
  final List<CatalogDefinitionUnit> upserts;
  final List<AuthoringResourceChange> additionalChanges;
  final String? workspaceFingerprint;
  final AuthoringDiff diff;
}
