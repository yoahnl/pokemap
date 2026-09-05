import 'package:map_core/map_core.dart';

import '../contracts/json_contract_support.dart';
import '../contracts/query_page.dart';
import '../contracts/query_request.dart';
import '../domains/project/capability_truth_adapter.dart';
import '../references/project_reference_index.dart';
import '../registry/resource_kind_registry.dart';
import '../workspace/project_open_service.dart';
import '../workspace/project_query_service.dart';
import '../workspace/project_snapshot_loader.dart';
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
  })  : _openService = openService,
        _snapshotLoader = snapshotLoader,
        _queryService = queryService;

  final ProjectOpenService _openService;
  final ProjectSnapshotLoader _snapshotLoader;
  final ProjectQueryService _queryService;

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
    final snapshot = await _snapshotLoader.load(
      projectHandle,
      policy: ProjectSnapshotLoadPolicy.editorReadProjection,
    );
    return _queryService.query(snapshot, request);
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
