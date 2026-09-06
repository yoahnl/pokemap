import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../assets/asset_store.dart';
import 'regional_map_authoring_gate.dart';
import '../maps/map_lifecycle_adapter.dart';
import '../narrative/narrative_action_support.dart';

final class RegionalMapActions {
  const RegionalMapActions();

  static final List<AuthoringActionDescriptor> descriptors = [
    for (final entry in const {
      'regionalMap.region.upsert': 'Create or replace an illustrated region',
      'regionalMap.region.delete': 'Delete an unreferenced illustrated region',
      'regionalMap.poi.upsert':
          'Create or replace a regional point of interest',
      'regionalMap.poi.delete': 'Delete a regional point of interest',
    }.entries)
      AuthoringActionDescriptor(
          id: entry.key,
          version: 1,
          summary: entry.value,
          inputSchemaId: 'pokemap.authoring/${entry.key}.input.v1',
          outputSchemaId: 'pokemap.authoring/${entry.key}.output.v1',
          riskLevel: entry.key.endsWith('.delete')
              ? AuthoringRiskLevel.high
              : AuthoringRiskLevel.medium,
          resourceKinds: const [
            'project',
            'regionalMap',
            'regionalMapRegion',
            'regionalMapPoi'
          ],
          capabilityIds: const [
            'authoring.regional_map'
          ],
          requiredPermissions: const [
            AuthoringPermission.projectWrite
          ],
          guarantees: const [
            AuthoringGuarantee.dryRun,
            AuthoringGuarantee.idempotent,
            AuthoringGuarantee.atomic,
            AuthoringGuarantee.revisionChecked,
            AuthoringGuarantee.undoable
          ]),
  ];

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final project = context.snapshot.manifest;
    final parameters = context.request.parameters;
    late final ProjectManifest projected;
    late final String id;
    late final String kind;
    late final String collection;
    Object? before;
    Object? after;
    try {
      switch (context.request.actionId) {
        case 'regionalMap.region.upsert':
          rejectUnknownNarrativeParameters(parameters, const {'region'});
          final region = ProjectRegionDefinition.fromJson(
              narrativeObjectParameter(parameters, 'region'));
          id = region.id;
          kind = 'regionalMapRegion';
          collection = 'regions';
          before = project.regionalMap?.regions
              .where((r) => r.id == id)
              .firstOrNull
              ?.toJson();
          projected = upsertRegion(project, region: region);
          after = region.toJson();
        case 'regionalMap.region.delete':
          rejectUnknownNarrativeParameters(parameters, const {'regionId'});
          id = narrativeStringParameter(parameters, 'regionId');
          kind = 'regionalMapRegion';
          collection = 'regions';
          before = project.regionalMap?.regions
              .where((r) => r.id == id)
              .firstOrNull
              ?.toJson();
          projected = deleteRegion(project, regionId: id);
        case 'regionalMap.poi.upsert':
          rejectUnknownNarrativeParameters(parameters, const {'poi'});
          final point = ProjectRegionPointOfInterest.fromJson(
              narrativeObjectParameter(parameters, 'poi'));
          id = point.id;
          kind = 'regionalMapPoi';
          collection = 'pointsOfInterest';
          before = project.regionalMap?.pointsOfInterest
              .where((p) => p.id == id)
              .firstOrNull
              ?.toJson();
          projected = upsertPoint(project, point: point);
          after = point.toJson();
        case 'regionalMap.poi.delete':
          rejectUnknownNarrativeParameters(parameters, const {'poiId'});
          id = narrativeStringParameter(parameters, 'poiId');
          kind = 'regionalMapPoi';
          collection = 'pointsOfInterest';
          before = project.regionalMap?.pointsOfInterest
              .where((p) => p.id == id)
              .firstOrNull
              ?.toJson();
          projected = deletePoint(project, pointId: id);
        default:
          throw const FormatException('Unsupported regional map action.');
      }
    } on FormatException catch (error) {
      throw MapAuthoringException(
          code: 'regional_map.request_invalid', message: error.message);
    } on ArgumentError catch (error) {
      throw MapAuthoringException(
          code: 'regional_map.request_invalid',
          message: error.message.toString());
    }
    final bytes =
        context.snapshot.findResourceBytes(assetCatalogResourceIdentity);
    final assets = bytes == null
        ? AssetCatalog(records: const [])
        : AssetCatalog.fromJson(
            Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map));
    final diagnostics = const RegionalMapAuthoringGate().inspect(
        project: projected, assets: assets, maps: context.snapshot.maps);
    if (diagnostics.isNotEmpty) {
      throw MapAuthoringException(
          code: diagnostics.first.code,
          message: diagnostics.first.message,
          details: {
            'diagnostics': diagnostics.map((d) => d.toJson()).toList()
          });
    }
    return narrativeProjectDraft(context.snapshot, projected,
        operation: context.request.actionId,
        path: '/regionalMap/$collection/$id',
        before: before,
        after: after,
        preview: {'resourceKind': kind, 'id': id, 'schemaVersion': 1});
  }

  ProjectManifest upsertRegion(ProjectManifest project,
      {required ProjectRegionDefinition region}) {
    final regions = [
      ...?project.regionalMap?.regions.where((r) => r.id != region.id),
      region
    ]..sort((a, b) => a.id.compareTo(b.id));
    return project.copyWith(
        regionalMap: ProjectRegionalMapCatalog(
            regions: regions,
            pointsOfInterest:
                project.regionalMap?.pointsOfInterest ?? const []));
  }

  ProjectManifest upsertPoint(ProjectManifest project,
      {required ProjectRegionPointOfInterest point}) {
    final points = [
      ...?project.regionalMap?.pointsOfInterest.where((p) => p.id != point.id),
      point
    ]..sort((a, b) => a.id.compareTo(b.id));
    return project.copyWith(
        regionalMap: ProjectRegionalMapCatalog(
            regions: project.regionalMap?.regions ?? const [],
            pointsOfInterest: points));
  }

  ProjectManifest deleteRegion(ProjectManifest project,
      {required String regionId}) {
    final catalog = project.regionalMap;
    if (catalog == null || !catalog.regions.any((r) => r.id == regionId)) {
      throw MapAuthoringException(
          code: 'regional_map.region_missing',
          message: 'The selected region does not exist.');
    }
    if (catalog.pointsOfInterest.any((p) => p.regionId == regionId)) {
      throw MapAuthoringException(
          code: 'regional_map.region_referenced',
          message: 'Move or remove the region points before deleting it.');
    }
    return project.copyWith(
        regionalMap: ProjectRegionalMapCatalog(
            regions: catalog.regions.where((r) => r.id != regionId).toList(),
            pointsOfInterest: catalog.pointsOfInterest));
  }

  ProjectManifest deletePoint(ProjectManifest project,
      {required String pointId}) {
    final catalog = project.regionalMap;
    if (catalog == null ||
        !catalog.pointsOfInterest.any((p) => p.id == pointId)) {
      throw MapAuthoringException(
          code: 'regional_map.poi_missing',
          message: 'The selected point of interest does not exist.');
    }
    return project.copyWith(
        regionalMap: ProjectRegionalMapCatalog(
            regions: catalog.regions,
            pointsOfInterest: catalog.pointsOfInterest
                .where((p) => p.id != pointId)
                .toList()));
  }
}
