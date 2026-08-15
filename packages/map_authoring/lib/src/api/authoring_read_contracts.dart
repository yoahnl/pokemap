import 'package:map_core/map_core.dart';

import '../contracts/json_contract_support.dart';
import '../contracts/query_request.dart';
import '../domains/project/capability_truth_adapter.dart';
import '../references/project_reference_index.dart';
import '../registry/resource_kind_registry.dart';

/// One command exposed by the read application boundary.
final class AuthoringReadCommandDescriptor {
  const AuthoringReadCommandDescriptor({
    required this.id,
    required this.summary,
  });

  final String id;
  final String summary;

  Map<String, Object?> toJson() => {'id': id, 'summary': summary};
}

/// Typed description consumed by Dart clients before any wire projection.
final class AuthoringReadDescription {
  AuthoringReadDescription({
    required Iterable<AuthoringReadCommandDescriptor> commands,
    required Iterable<AuthoringQueryOperation> queryOperations,
    required Iterable<AuthoringResourceKindDescriptor> resourceKinds,
  })  : commands = List.unmodifiable(commands),
        queryOperations = List.unmodifiable(queryOperations),
        resourceKinds = List.unmodifiable(resourceKinds);

  static const int schemaVersion = 1;
  static const String protocol = 'pokemap.authoring.read.v1';

  final List<AuthoringReadCommandDescriptor> commands;
  final List<AuthoringQueryOperation> queryOperations;
  final List<AuthoringResourceKindDescriptor> resourceKinds;

  bool get readOnly => true;

  Map<String, Object?> toJson() => freezeContractJsonObject(
        {
          'schemaVersion': schemaVersion,
          'protocol': protocol,
          'readOnly': readOnly,
          'commands': [for (final command in commands) command.toJson()],
          'queryOperations': [
            for (final operation in queryOperations) operation.wireName,
          ],
          'resourceKinds': [for (final kind in resourceKinds) kind.toJson()],
          'validation': const {
            'structure': true,
            'references': true,
            'pokemonCatalog': true,
            'capabilityTruth': 'explicit_only',
            'capabilityCertification': 'requested_only',
          },
        },
        field: 'describe',
      );
}

/// Safe structural validation diagnostic without filesystem details.
final class AuthoringStructureDiagnostic {
  AuthoringStructureDiagnostic({
    required this.code,
    required this.message,
    Map<String, Object?> details = const {},
    Iterable<String> remediation = const [],
  })  : details = freezeContractJsonObject(details, field: 'details'),
        remediation = List.unmodifiable(remediation);

  final String code;
  final String message;
  final Map<String, Object?> details;
  final List<String> remediation;

  Map<String, Object?> toJson() => {
        'code': code,
        'message': message,
        'details': details,
        'remediation': remediation,
      };
}

final class AuthoringStructureValidationResult {
  AuthoringStructureValidationResult(
    Iterable<AuthoringStructureDiagnostic> diagnostics,
  ) : diagnostics = List.unmodifiable(diagnostics);

  final List<AuthoringStructureDiagnostic> diagnostics;

  bool get valid => diagnostics.isEmpty;

  Map<String, Object?> toJson() => {
        'valid': valid,
        'diagnostics': [
          for (final diagnostic in diagnostics) diagnostic.toJson(),
        ],
      };
}

final class AuthoringReferenceValidationResult {
  AuthoringReferenceValidationResult({
    required this.nodeCount,
    required this.edgeCount,
    required Iterable<ProjectReferenceDiagnostic> diagnostics,
  }) : diagnostics = List.unmodifiable(diagnostics);

  final int nodeCount;
  final int edgeCount;
  final List<ProjectReferenceDiagnostic> diagnostics;

  bool get hasErrors => diagnostics.any(
        (diagnostic) => diagnostic.severity == ProjectReferenceSeverity.error,
      );

  bool get valid => !hasErrors;

  Map<String, Object?> toJson() => {
        'valid': valid,
        'nodeCount': nodeCount,
        'edgeCount': edgeCount,
        'hasErrors': hasErrors,
        'diagnostics': [
          for (final diagnostic in diagnostics) diagnostic.toJson(),
        ],
      };
}

final class AuthoringCapabilityCertificationResult {
  const AuthoringCapabilityCertificationResult({
    required this.requested,
    required this.valid,
    required this.requiredCapabilityCount,
    required this.providedCapabilityCount,
  });

  final bool requested;
  final bool? valid;
  final int requiredCapabilityCount;
  final int providedCapabilityCount;

  String get status => requested ? (valid! ? 'pass' : 'fail') : 'not_requested';

  Map<String, Object?> toJson() => {
        'requested': requested,
        'status': status,
        'valid': valid,
        'requiredCapabilityCount': requiredCapabilityCount,
        'providedCapabilityCount': providedCapabilityCount,
      };
}

/// Typed validation aggregate used by direct Dart clients.
final class AuthoringValidationResult {
  AuthoringValidationResult({
    required this.snapshotRevision,
    required this.structure,
    required this.references,
    required this.capabilityCertification,
    required this.capabilityTruth,
    required this.pokemonCatalog,
  });

  final String snapshotRevision;
  final AuthoringStructureValidationResult structure;
  final AuthoringReferenceValidationResult references;
  final AuthoringCapabilityCertificationResult capabilityCertification;
  final AuthoringCapabilityTruthReport capabilityTruth;
  final PokemonCatalogCoherenceReport pokemonCatalog;

  bool get valid =>
      structure.valid &&
      references.valid &&
      pokemonCatalog.canPlaytest &&
      (!capabilityCertification.requested ||
          capabilityCertification.valid == true);

  Map<String, Object?> toJson() => freezeContractJsonObject(
        {
          'snapshotRevision': snapshotRevision,
          'valid': valid,
          'structure': structure.toJson(),
          'references': references.toJson(),
          'pokemonCatalog': pokemonCatalog.toJson(),
          'capabilityCertification': capabilityCertification.toJson(),
          'capabilityTruth': capabilityTruth.toJson(),
        },
        field: 'validate',
      );
}
