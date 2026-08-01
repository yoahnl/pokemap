import 'package:map_core/map_core.dart';

import '../contracts/json_contract_support.dart';
import '../contracts/query_request.dart';
import '../domains/project/capability_truth_adapter.dart';
import '../references/project_reference_index.dart';
import '../registry/resource_kind_registry.dart';
import '../workspace/project_open_service.dart';
import '../workspace/project_query_service.dart';
import '../workspace/project_snapshot_loader.dart';
import '../workspace/workspace_handle_store.dart';

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

/// Shared read-only application API used directly and through JSONL.
final class AuthoringReadApi implements AuthoringReadApiPort {
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
  Map<String, Object?> describe() {
    final readableResourceKinds =
        AuthoringResourceKindRegistry.canonicalMinimal()
            .resourceKinds
            .where(
              (kind) =>
                  kind.id == 'map' ||
                  kind.id == 'project' ||
                  kind.id == 'asset' ||
                  kind.id == 'tilesetFolder' ||
                  kind.id == 'elementCategory',
            )
            .map((kind) => kind.toJson())
            .toList(growable: false);
    return freezeContractJsonObject(
      {
        'schemaVersion': 1,
        'protocol': 'pokemap.authoring.read.v1',
        'readOnly': true,
        'commands': const [
          {
            'id': 'close',
            'summary': 'Close an in-memory read-only workspace.',
          },
          {
            'id': 'describe',
            'summary': 'Describe this read-only API.',
          },
          {
            'id': 'open',
            'summary': 'Open an allowed PokeMap project read-only.',
          },
          {
            'id': 'query',
            'summary': 'Query an immutable project snapshot.',
          },
          {
            'id': 'validate',
            'summary': 'Inspect references and explicit capability truth.',
          },
        ],
        'queryOperations': [
          for (final operation in AuthoringQueryOperation.values)
            operation.wireName,
        ],
        'resourceKinds': readableResourceKinds,
        'validation': const {
          'references': true,
          'capabilityTruth': 'explicit_only',
        },
      },
      field: 'describe',
    );
  }

  @override
  Future<Map<String, Object?>> open(String projectRootPath) async {
    final opened = await _openService.openProject(projectRootPath);
    return freezeContractJsonObject(opened.toJson(), field: 'open');
  }

  @override
  Future<Map<String, Object?>> query(
    ProjectHandle projectHandle,
    AuthoringQueryRequest request,
  ) async {
    final snapshot = await _snapshotLoader.load(projectHandle);
    return freezeContractJsonObject(
      _queryService.query(snapshot, request).toJson(),
      field: 'query',
    );
  }

  @override
  Future<Map<String, Object?>> validate(
    ProjectHandle projectHandle, {
    Iterable<ProjectCapabilityTruthRecord> capabilityRecords = const [],
    Set<String> requiredCapabilityIds = const {},
  }) async {
    final snapshot = await _snapshotLoader.load(projectHandle);
    final references = ProjectReferenceIndex.fromSnapshot(snapshot);
    final capabilityTruth = ProjectCapabilityTruthAdapter.evaluate(
      records: capabilityRecords,
      requiredCapabilityIds: requiredCapabilityIds,
    );
    final referenceHasErrors = references.diagnostics.any(
      (diagnostic) => diagnostic.severity == ProjectReferenceSeverity.error,
    );
    return freezeContractJsonObject(
      {
        'snapshotRevision': snapshot.revision,
        'valid': !referenceHasErrors && capabilityTruth.isPassing,
        'references': {
          'nodeCount': references.nodes.length,
          'edgeCount': references.edges.length,
          'hasErrors': referenceHasErrors,
          'diagnostics': references.diagnostics
              .map((diagnostic) => diagnostic.toJson())
              .toList(growable: false),
        },
        'capabilityTruth': capabilityTruth.toJson(),
      },
      field: 'validate',
    );
  }

  @override
  Future<Map<String, Object?>> close(WorkspaceHandle workspaceHandle) async {
    return Map.unmodifiable({
      'closed': _openService.closeWorkspace(workspaceHandle),
    });
  }
}
