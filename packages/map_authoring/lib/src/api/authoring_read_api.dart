import 'dart:convert';
import '../references/exterior_decoration_references.dart';
import 'resource_pack_transfer_api.dart';
import 'border_feature_query.dart';
import 'spatial_map_integrity_query.dart';
import 'map_health_query.dart';
import 'project_media_library_query.dart';
import '../workspace/catalog/catalog_project_reader.dart';
import '../workspace/catalog/catalog_targeted_map_edit.dart';
import '../workspace/catalog/catalog_workshop_selection.dart';

import 'package:map_core/map_core.dart';

import '../contracts/json_contract_support.dart';
import '../contracts/query_page.dart';
import '../contracts/query_request.dart';
import '../domains/project/capability_truth_adapter.dart';
import '../domains/assets/project_media_store.dart';
import '../domains/narrative/scene_simulation_query.dart';
import '../domains/narrative/event_simulation_query.dart';
import '../references/project_reference_index.dart';
import '../registry/resource_kind_registry.dart';
import '../workspace/project_open_service.dart';
import '../workspace/project_query_service.dart';
import '../workspace/project_snapshot_loader.dart';
import '../workspace/project_snapshot.dart';
import '../workspace/workspace_handle_store.dart';
import 'authoring_read_contracts.dart';

/// Port consumed by protocol adapters and deterministic test doubles.
abstract interface class AuthoringReadApiPort {
  Map<String, Object?> describe();

  Future<Map<String, Object?>> open(String projectRootPath);

  Future<Map<String, Object?>> query(
    ProjectHandle projectHandle,
    AuthoringQueryRequest request,
  );

  Future<Map<String, Object?>> validate(
    ProjectHandle projectHandle, {
    Iterable<ProjectCapabilityTruthRecord> capabilityRecords = const [],
    Set<String> requiredCapabilityIds = const {},
  });

  Future<Map<String, Object?>> close(WorkspaceHandle workspaceHandle);
}

/// Typed application boundary for direct Dart consumers such as the editor.
///
/// JSONL and MCP adapters continue to use [AuthoringReadApiPort] while they
/// migrate, keeping serialization concerns at the transport edge.
abstract interface class AuthoringReadServicePort {
  AuthoringReadDescription describeRead();

  Future<OpenedProject> openProject(String projectRootPath);

  Future<AuthoringQueryPage> queryProject(
    ProjectHandle projectHandle,
    AuthoringQueryRequest request,
  );

  Future<AuthoringValidationResult> validateProject(
    ProjectHandle projectHandle, {
    Iterable<ProjectCapabilityTruthRecord> capabilityRecords = const [],
    Set<String> requiredCapabilityIds = const {},
  });

  Future<bool> closeWorkspace(WorkspaceHandle workspaceHandle);
}

/// Shared read-only application API used directly and through JSONL.
final class AuthoringReadApi
    implements AuthoringReadApiPort, AuthoringReadServicePort {
  const AuthoringReadApi({
    required ProjectOpenService openService,
    required ProjectSnapshotLoader snapshotLoader,
    ProjectQueryService queryService = const ProjectQueryService(),
    ResourcePackTransferApiPort? Function()? resourcePacks,
  })  : _openService = openService,
        _snapshotLoader = snapshotLoader,
        _queryService = queryService,
        _resourcePacks = resourcePacks;

  final ProjectOpenService _openService;
  final ProjectSnapshotLoader _snapshotLoader;
  final ProjectQueryService _queryService;
  final ResourcePackTransferApiPort? Function()? _resourcePacks;

  @override
  AuthoringReadDescription describeRead() {
    final registry = AuthoringResourceKindRegistry.canonical();
    final readableResourceKinds = registry.resourceKinds
        .where((kind) => registry.queryableResourceKindIds.contains(kind.id))
        .toList(growable: false);
    return AuthoringReadDescription(
      commands: const [
        AuthoringReadCommandDescriptor(
          id: 'close',
          summary: 'Close an in-memory read-only workspace.',
        ),
        AuthoringReadCommandDescriptor(
          id: 'describe',
          summary: 'Describe this read-only API.',
        ),
        AuthoringReadCommandDescriptor(
          id: 'open',
          summary: 'Open an allowed PokeMap project read-only.',
        ),
        AuthoringReadCommandDescriptor(
          id: 'query',
          summary: 'Query an immutable project snapshot.',
        ),
        AuthoringReadCommandDescriptor(
          id: 'validate',
          summary:
              'Inspect project structure, Pokemon coherence, references, and optional capability certification.',
        ),
      ],
      queryOperations: AuthoringQueryOperation.values,
      resourceKinds: readableResourceKinds,
    );
  }

  @override
  Map<String, Object?> describe() => describeRead().toJson();

  Future<AuthoringMapView> readMapView(
    ProjectHandle projectHandle,
    String mapId,
  ) async {
    final catalog = await _openService.catalogProject(projectHandle);
    if (catalog != null) {
      final CatalogTargetedMapSelection selection;
      try {
        selection =
            await CatalogTargetedMapSelection.read(reader: catalog, mapId: mapId);
      } on StateError {
        throw const AuthoringQueryException('query.resource_not_found',
            'The requested map does not exist in this project.');
      }
      return (
        map: selection.map,
        manifest: selection.definitions,
        revision: selection.snapshotRevision,
      );
    }
    final snapshot = await _snapshotLoader.loadWorkshop(projectHandle,
        actionId: 'map3d.edit_batch', parameters: {'mapId':mapId,'operations':const []});
    final map = snapshot.maps.where((map) => map.id == mapId).firstOrNull;
    if (map == null) {
      throw const AuthoringQueryException('query.resource_not_found',
          'The requested map does not exist in this project.');
    }
    return (map: map, manifest: snapshot.manifest, revision: snapshot.revision);
  }

  @override
  Future<OpenedProject> openProject(String projectRootPath) async =>
      await _openService.openProject(projectRootPath);

  @override
  Future<Map<String, Object?>> open(String projectRootPath) async =>
      freezeContractJsonObject(
        (await openProject(projectRootPath)).toJson(),
        field: 'open',
      );

  @override
  Future<AuthoringQueryPage> queryProject(
    ProjectHandle projectHandle,
    AuthoringQueryRequest request,
  ) async {
    if (resourcePackTemporaryKinds.contains(request.resourceKind)) {
      final packs = _resourcePacks?.call();
      if (packs == null) {
        throw const AuthoringQueryException(
          'query.transfer_unavailable',
          'The pack transfer resolver is unavailable.',
        );
      }
      return AuthoringQueryPage.fromJson(
        Map<String, dynamic>.from(
          await packs.queryTransfer(projectHandle, request),
        ),
      );
    }
    if (const {'presentationMedia', 'asset'}.contains(request.resourceKind)) {
      return queryProjectMediaLibrary(loader: _snapshotLoader, queries: _queryService,
        projectHandle: projectHandle, request: request);
    }
    final catalog = await _openService.catalogProject(projectHandle);
    if (catalog == null && request.resourceKind == 'fact' && request.ids.isEmpty &&
        request.extensions.isEmpty && request.filters.isEmpty && request.sort.isEmpty &&
        const {AuthoringQueryOperation.list, AuthoringQueryOperation.summary}.contains(request.operation)) {
      var offset = 0;
      String? expectedRevision;
      if (request.cursor != null) {
        try {
          final cursor = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(request.cursor!)))) as Map;
          if (cursor['kind'] != 'nativeFacts') throw const FormatException();
          offset = cursor['offset'] as int;
          expectedRevision = cursor['revision'] as String;
        } catch (_) {
          throw const AuthoringQueryException('query.cursor_invalid', 'The Fact page cursor is invalid.');
        }
      }
      final page = await _snapshotLoader.readNativeFactPage(projectHandle, offset: offset, limit: request.pageSize);
      if (expectedRevision != null && expectedRevision != page.revision) throw const AuthoringQueryException('query.cursor_stale', 'The project changed after the previous Fact page.');
      final snapshot = ProjectSnapshot(projectHandle: projectHandle, revision: page.revision,
          manifest: ProjectManifest(name: 'Facts', maps: const [], tilesets: const [], facts: page.facts),
          maps: const [], resourceFingerprints: const {});
      final projected = await _queryService.queryAsync(snapshot, AuthoringQueryRequest(
          resourceKind: 'fact', operation: AuthoringQueryOperation.list, view: request.view,
          pageSize: request.pageSize, fieldMask: request.fieldMask));
      return AuthoringQueryPage(snapshotRevision: page.revision, items: projected.items,
          totalAvailable: page.total, nextCursor: offset + page.facts.length < page.total
          ? base64Url.encode(utf8.encode(jsonEncode({'kind': 'nativeFacts', 'revision': page.revision, 'offset': offset + page.facts.length}))).replaceAll('=', '') : null);
    }
    if (catalog == null && request.resourceKind == 'fact' && request.ids.isNotEmpty &&
        const {AuthoringQueryOperation.get, AuthoringQueryOperation.batchGet}.contains(request.operation)) {
      final snapshot = await _snapshotLoader.loadWorkshop(projectHandle, actionId: 'surf.configure', parameters: {
        'configuration': {'accessMode': 'condition', 'condition': {'type': 'allOf', 'children': [
          for (final id in request.ids) {'type': 'factEquals', 'params': {'factId': id, 'valueType': 'bool', 'value': 'true'}}
        ]}}
      });
      return _queryService.queryAsync(snapshot, request);
    }
    if (catalog != null && request.resourceKind == 'fact' &&
        request.extensions.isEmpty && request.filters.isEmpty && request.sort.isEmpty &&
        const {AuthoringQueryOperation.list, AuthoringQueryOperation.summary, AuthoringQueryOperation.get, AuthoringQueryOperation.batchGet}.contains(request.operation)) {
      return catalog.queryFacts(request);
    }
    if (catalog != null && const {'partyCompanionConfiguration', 'contactDeviceConfiguration'}.contains(request.resourceKind) && request.extensions.isEmpty) {
      final field = request.resourceKind == 'partyCompanionConfiguration' ? 'partyCompanion' : 'contactDevice';
      final selected = await catalog.withMetadataFields({field});
      return selected.read((projection) async {
        final snapshot = ProjectSnapshot(projectHandle: projectHandle,
            revision: CatalogWorkshopSelection.fingerprint(selected.revision, const {}),
            manifest: projection.projectMetadata, maps: const [], availableProjectSections: {field}, resourceFingerprints: const {});
        return _queryService.queryAsync(snapshot, request);
      });
    }
    if (const {'surfConfiguration', 'fieldAbilityConfiguration', 'projectAudio'}.contains(request.resourceKind) || catalog != null && const {'partyCompanionConfiguration', 'contactDeviceConfiguration'}.contains(request.resourceKind)) {
      final defaultAction = switch (request.resourceKind) {
        'fieldAbilityConfiguration' => 'field_ability.configure',
        'projectAudio' => 'project.audio.cue.configure',
        'partyCompanionConfiguration' => 'party_companion.configure',
        'contactDeviceConfiguration' => 'contact_device.configure',
        _ => 'surf.configure',
      };
      final action = request.extensions['actionId'] ?? defaultAction;
      final allowed = {defaultAction, if (request.resourceKind == 'projectAudio') ...['presentationMedia.import', 'project.audio.media.adopt_asset']};
      final parameters = request.extensions['parameters'] ?? const <String, Object?>{};
      if (!allowed.contains(action) || parameters is! Map ||
          parameters.keys.any((key) => key is! String) ||
          request.extensions.keys.any((key) => !const {'actionId', 'parameters'}.contains(key))) {
        throw const AuthoringQueryException('query.action_resource_mismatch', 'Use the declared settings action and its parameters for a scoped revision.');
      }
      final snapshot = catalog == null
          ? await _snapshotLoader.loadWorkshop(projectHandle,
              actionId: action as String, parameters: Map<String, Object?>.from(parameters))
          : (await CatalogWorkshopSelection.read(reader: catalog, projectHandle: projectHandle,
              actionId: action as String, parameters: Map<String, Object?>.from(parameters))).snapshot;
      final projectedRequest = AuthoringQueryRequest.fromJson(request.toJson()..['extensions'] = <String, Object?>{});
      return _queryService.queryAsync(snapshot, projectedRequest);
    }
    if (request.resourceKind == 'borderFeature') {
      return queryBorderFeatures(
        request: request,
        readMap: (mapId) => readMapView(projectHandle, mapId),
      );
    }
    if (request.resourceKind == 'mapHealth') {
      return queryMapHealth(
        request: request,
        readMap: (mapId) => readMapView(projectHandle, mapId),
      );
    }
    if (request.resourceKind == 'spatialMapIntegrity') {
      return querySpatialMapIntegrity(
        request: request,
        readMap: (mapId) => readMapView(projectHandle, mapId),
      );
    }
    if (catalog != null &&
        request.resourceKind == 'map' &&
        request.extensions['materializeProject'] != true) {
      return catalog.queryMaps(request, readMap: (id) async {
        final selection =
            await CatalogTargetedMapSelection.read(reader: catalog, mapId: id);
        return (map: selection.map, revision: selection.snapshotRevision);
      });
    }
    if (catalog != null &&
        (catalogResourceKinds.containsKey(request.resourceKind) ||
            (request.resourceKind == 'project' &&
                request.view == AuthoringQueryView.summary))) {
      return catalog.query(request);
    }
    if (catalog != null &&
        request.resourceKind == 'project' &&
        request.view == AuthoringQueryView.detail &&
        request.extensions['materializeProject'] != true) {
      throw const AuthoringQueryException('query.materialization_required',
          'Full catalog project reads require extensions.materializeProject=true.');
    }
    final snapshot = await _snapshotLoader.load(
      projectHandle,
      deferPokemonDocuments: request.resourceKind == 'pokemonDocument',
      policy: request.resourceKind == 'resourceUsage'
          ? ProjectSnapshotLoadPolicy.resourceUsageReadProjection
          : ProjectSnapshotLoadPolicy.editorReadProjection,
    );
    if (request.extensions['actionId'] == 'scene.simulate') {
      return querySceneSimulation(snapshot, request);
    }
    if (request.extensions['actionId'] == 'event_v2.simulate') {
      return queryEventSimulation(snapshot, request);
    }
    return _queryService.queryAsync(snapshot, request,
        projectResourceUsages: request.resourceKind == 'resourceUsage'
            ? (report) => projectExteriorReferenceUsages(report,
                (path, maximumBytes) => _snapshotLoader.readOptionalResourceBytes(
                    projectHandle, path, maximumBytes: maximumBytes))
            : null);
  }

  @override
  Future<Map<String, Object?>> query(
    ProjectHandle projectHandle,
    AuthoringQueryRequest request,
  ) async =>
      freezeContractJsonObject(
        (await queryProject(projectHandle, request)).toJson(),
        field: 'query',
      );

  @override
  Future<AuthoringValidationResult> validateProject(
    ProjectHandle projectHandle, {
    Iterable<ProjectCapabilityTruthRecord> capabilityRecords = const [],
    Set<String> requiredCapabilityIds = const {},
  }) async {
    final snapshot = await _snapshotLoader.load(projectHandle);
    final records = capabilityRecords.toList(growable: false);
    final requiredIds = {
      for (final capabilityId in requiredCapabilityIds)
        if (capabilityId.trim().isNotEmpty) capabilityId.trim(),
    };
    final references = ProjectReferenceIndex.fromSnapshot(snapshot);
    final capabilityTruth = ProjectCapabilityTruthAdapter.evaluate(
      records: records,
      requiredCapabilityIds: requiredIds,
    );
    final pokemonCatalog = await _snapshotLoader.validatePokemonCatalog(
      projectHandle,
      snapshot.manifest,
    );
    final structureDiagnostics = <AuthoringStructureDiagnostic>[];
    try {
      ProjectValidator.validate(
        snapshot.manifest,
        presentationMediaCatalog: switch (
            snapshot.findResourceBytes(projectMediaCatalogResourceIdentity)) {
          final bytes? => decodeProjectMediaCatalogBytes(bytes),
          null => null,
        },
        maps: snapshot.maps,
        itemCatalog: snapshot.itemCatalog,
      );
      for (final map in snapshot.maps) {
        MapValidator.validate(
          map,
          projectDialogueContext: snapshot.manifest,
        );
      }
    } on ValidationException catch (error) {
      structureDiagnostics.add(
        AuthoringStructureDiagnostic(
          code: error.code ?? 'project.structure_invalid',
          message: error.message,
          details: error.details,
          remediation: error.remediation,
        ),
      );
    } on Object catch (error) {
      structureDiagnostics.add(
        AuthoringStructureDiagnostic(
          code: 'project.structure_invalid',
          message: 'The project snapshot contains invalid structural data.',
          details: {'validationType': error.runtimeType.toString()},
        ),
      );
    }
    final structure = AuthoringStructureValidationResult(structureDiagnostics);
    final referenceValidation = AuthoringReferenceValidationResult(
      nodeCount: references.nodes.length,
      edgeCount: references.edges.length,
      diagnostics: references.diagnostics,
    );
    final certificationRequested = requiredIds.isNotEmpty || records.isNotEmpty;
    final certificationValid =
        certificationRequested ? capabilityTruth.isPassing : null;
    return AuthoringValidationResult(
      snapshotRevision: snapshot.revision,
      structure: structure,
      references: referenceValidation,
      capabilityCertification: AuthoringCapabilityCertificationResult(
        requested: certificationRequested,
        valid: certificationValid,
        requiredCapabilityCount: requiredIds.length,
        providedCapabilityCount: records.length,
      ),
      capabilityTruth: capabilityTruth,
      pokemonCatalog: pokemonCatalog,
    );
  }

  @override
  Future<Map<String, Object?>> validate(
    ProjectHandle projectHandle, {
    Iterable<ProjectCapabilityTruthRecord> capabilityRecords = const [],
    Set<String> requiredCapabilityIds = const {},
  }) async =>
      (await validateProject(
        projectHandle,
        capabilityRecords: capabilityRecords,
        requiredCapabilityIds: requiredCapabilityIds,
      ))
          .toJson();

  @override
  Future<bool> closeWorkspace(WorkspaceHandle workspaceHandle) async =>
      _openService.closeWorkspace(workspaceHandle);

  @override
  Future<Map<String, Object?>> close(WorkspaceHandle workspaceHandle) async =>
      Map.unmodifiable({'closed': await closeWorkspace(workspaceHandle)});
}
