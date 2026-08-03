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
                  kind.id == 'elementCategory' ||
                  kind.id == 'smartTileAtlas' ||
                  kind.id == 'smartTileMaterial' ||
                  kind.id == 'smartTileAnimation' ||
                  kind.id == 'smartTileDraft' ||
                  kind.id == 'smartTilePreset' ||
                  kind.id == 'smartTileLayer',
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
            'summary':
                'Inspect project structure, references, and optional capability certification.',
          },
        ],
        'queryOperations': [
          for (final operation in AuthoringQueryOperation.values)
            operation.wireName,
        ],
        'resourceKinds': readableResourceKinds,
        'validation': const {
          'structure': true,
          'references': true,
          'capabilityTruth': 'explicit_only',
          'capabilityCertification': 'requested_only',
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
    final structureDiagnostics = <Map<String, Object?>>[];
    try {
      ProjectValidator.validate(snapshot.manifest);
      for (final map in snapshot.maps) {
        MapValidator.validate(
          map,
          projectDialogueContext: snapshot.manifest,
        );
      }
    } on ValidationException catch (error) {
      structureDiagnostics.add({
        'code': error.code ?? 'project.structure_invalid',
        'message': error.message,
        'details': error.details,
        'remediation': error.remediation,
      });
    } on Object catch (error) {
      structureDiagnostics.add({
        'code': 'project.structure_invalid',
        'message': 'The project snapshot contains invalid structural data.',
        'details': {'validationType': error.runtimeType.toString()},
        'remediation': const <String>[],
      });
    }
    final structureValid = structureDiagnostics.isEmpty;
    final referenceHasErrors = references.diagnostics.any(
      (diagnostic) => diagnostic.severity == ProjectReferenceSeverity.error,
    );
    final referencesValid = !referenceHasErrors;
    final certificationRequested = requiredIds.isNotEmpty || records.isNotEmpty;
    final certificationValid =
        certificationRequested ? capabilityTruth.isPassing : null;
    final valid = structureValid &&
        referencesValid &&
        (!certificationRequested || capabilityTruth.isPassing);
    return freezeContractJsonObject(
      {
        'snapshotRevision': snapshot.revision,
        // Kept for compatibility, but now follows only dimensions actually
        // requested by the caller. An absent capability certification cannot
        // make an otherwise healthy project appear invalid.
        'valid': valid,
        'structure': {
          'valid': structureValid,
          'diagnostics': structureDiagnostics,
        },
        'references': {
          'valid': referencesValid,
          'nodeCount': references.nodes.length,
          'edgeCount': references.edges.length,
          'hasErrors': referenceHasErrors,
          'diagnostics': references.diagnostics
              .map((diagnostic) => diagnostic.toJson())
              .toList(growable: false),
        },
        'capabilityCertification': {
          'requested': certificationRequested,
          'status': certificationRequested
              ? (capabilityTruth.isPassing ? 'pass' : 'fail')
              : 'not_requested',
          'valid': certificationValid,
          'requiredCapabilityCount': requiredIds.length,
          'providedCapabilityCount': records.length,
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
