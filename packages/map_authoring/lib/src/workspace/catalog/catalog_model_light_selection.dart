part of 'catalog_workshop_selection.dart';

Future<CatalogWorkshopSelection> _readModelLightWorkshop({
  required CatalogProjectReader reader,
  required ProjectHandle projectHandle,
  required Map<String, Object?> parameters,
}) async {
  const action = 'model3d.configure';
  if (parameters.length < 2 ||
      parameters['modelId'] is! String ||
      parameters.keys.any((key) => !{
            'modelId',
            'light',
            'collisionBounds',
            'castsShadowsByDefault',
            'pivot',
            'scale',
          }.contains(key))) {
    CatalogWorkshopSelection.unsupported(
        action, 'a supported model definition configuration');
  }
  final id = parameters['modelId']! as String;
  final selected = await reader.withMetadataFields({'settings'});
  return selected.read((catalog) async {
    await reader.store.requireMetadataIndexAdmission(catalog.snapshot);
    final key = CatalogDefinitionKey(CatalogDefinitionKind.model3d, id);
    final unit = await catalog.lookup(key);
    if (unit == null) throw const FormatException('Unknown model identity.');
    final model = ProjectModel3dEntry.fromJson(
      Map<String, dynamic>.from(unit.payload['value']! as Map),
    );
    if (parameters.containsKey('scale') || parameters.containsKey('pivot')) {
      if (model.rampProfile != null) {
        throw AuthoringPlanException(
          code: 'catalog.model_transform_ramp_requires_map_updates',
          message:
              'Changing a ramp model transform requires updating its map instances.',
        );
      }
      await _requireStablePublishedBorderAnchors(
        catalog,
        model,
        parameters,
      );
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
        tileHeight: settings.tileHeight,
      ),
      maps: const [],
      tilesets: const [],
      models3d: [model],
    );
    final bytes = utf8.encode(jsonEncode(manifest.toJson()));
    final descriptor =
        (await reader.store.gateway.readResource('project.json'))!;
    final head = (await reader.store.gateway
        .readResource(CatalogStorageStore.headStorageKey))!;
    if (canonicalAuthoringJson(jsonDecode(utf8.decode(descriptor))) !=
            canonicalAuthoringJson(reader.descriptor) ||
        canonicalAuthoringJson(jsonDecode(utf8.decode(head))) !=
            canonicalAuthoringJson(jsonDecode(utf8.decode(
                CatalogStorageStore.encodeHead(catalog.snapshot.root))))) {
      throw AuthoringPlanException(
          code: 'plan.stale',
          message: 'The catalog changed while selecting model metadata.');
    }
    final snapshot = ProjectSnapshot(
        projectHandle: projectHandle,
        revision: selected.revision,
        materializedCatalogProject: true,
        manifest: manifest,
        maps: const [],
        availableProjectSections: {
          'settings',
          'models3d'
        },
        availableProjectDocuments: {
          'models3d': {id}
        },
        resourceBytes: {
          'project': bytes,
          'catalogDescriptor': descriptor,
          'catalogHead': head,
        },
        resourceStorageKeys: {
          'project': 'project.json',
          'catalogDescriptor': 'project.json',
          'catalogHead': CatalogStorageStore.headStorageKey,
        },
        resourceFingerprints: {
          'catalogDescriptor': computeAuthoringBytesFingerprint(descriptor,
              logicalName: 'project.json'),
          'catalogHead': computeAuthoringBytesFingerprint(head,
              logicalName: CatalogStorageStore.headStorageKey),
          'project': computeAuthoringBytesFingerprint(bytes,
              logicalName: 'project.json')
        });
    final result =
        CatalogWorkshopSelection._(selected, snapshot, {'models3d'}, {});
    await result.requireCurrent();
    return result;
  });
}

Future<void> _requireStablePublishedBorderAnchors(
  PortableProjectCatalog catalog,
  ProjectModel3dEntry model,
  Map<String, Object?> parameters,
) async {
  final scale = parameters['scale'] as num? ?? model.scale;
  final pivot = parameters['pivot'] == null
      ? model.pivot
      : Model3dVector3.fromJson(
          Map<String, dynamic>.from(parameters['pivot'] as Map),
        );
  if (scale == model.scale && pivot == model.pivot) return;
  final snapshot = catalog.snapshot;
  if (!await CatalogResourceUsageIndex.prepared(snapshot)) {
    final borders = await snapshot.page(
      kind: CatalogDefinitionKind.borderRecord,
      limit: 1,
    );
    if (borders.items.isEmpty) return;
    throw AuthoringPlanException(
      code: 'catalog.model_transform_border_index_required',
      message:
          'Prepare the resource reference indexes to verify published Border anchors.',
      remediation: const ['Prepare the resourceIndexes catalog scope.'],
    );
  }
  final consumers = await CatalogResourceUsageIndex.consumerOwners(
    snapshot,
    'model3d:${model.id}',
    includeExternal: false,
  );
  for (final consumer in consumers) {
    if (!consumer.startsWith('border:')) continue;
    final unit = await catalog.lookup(
      CatalogDefinitionKey(
          CatalogDefinitionKind.borderRecord, consumer.substring(7)),
    );
    if (unit == null) {
      throw const FormatException(
          'catalog.resource_usage: missing Border definition');
    }
    final published = decodeBorderBlueprintRecordJson(
      unit.payload['value'],
      formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
    ).latestPublished?.definition;
    if (published == null) continue;
    for (final primitive in published.primitives) {
      final anchor = primitive.anchorWorld;
      if (primitive.sourceModelId != model.id || anchor == null) continue;
      if ((anchor.x - pivot.x) * scale !=
              (anchor.x - model.pivot.x) * model.scale ||
          (anchor.y - pivot.y) * scale !=
              (anchor.y - model.pivot.y) * model.scale ||
          (anchor.z - pivot.z) * scale !=
              (anchor.z - model.pivot.z) * model.scale) {
        throw AuthoringPlanException(
          code: 'catalog.model_transform_border_anchor_requires_map_updates',
          message:
              'The published Border ${published.name} uses a fixed anchor that requires updating its placements.',
        );
      }
    }
  }
}
