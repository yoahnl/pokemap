import '../contracts/action_descriptor.dart';
import '../contracts/json_contract_support.dart';

/// Duplicate registration of the exact same action contract.
final class DuplicateAuthoringActionException implements Exception {
  const DuplicateAuthoringActionException(this.actionId, this.version);

  final String actionId;
  final int version;

  @override
  String toString() {
    return 'Duplicate authoring action: $actionId v$version';
  }
}

/// Registration of two contract versions under one action ID.
///
/// Phase 1 intentionally keeps one active version per ID. A future version
/// negotiation policy must be explicit rather than silently selecting one.
final class IncompatibleAuthoringActionVersionException implements Exception {
  IncompatibleAuthoringActionVersionException(
    this.actionId,
    Iterable<int> versions,
  ) : versions = List.unmodifiable(versions.toSet().toList()..sort());

  final String actionId;
  final List<int> versions;

  @override
  String toString() {
    return 'Incompatible versions for $actionId: ${versions.join(', ')}';
  }
}

final class UnknownAuthoringActionException implements Exception {
  const UnknownAuthoringActionException(this.actionId);

  final String actionId;

  @override
  String toString() => 'Unknown authoring action: $actionId';
}

/// Immutable, deterministic registry of public authoring actions.
final class AuthoringActionRegistry {
  AuthoringActionRegistry(Iterable<AuthoringActionDescriptor> descriptors)
      : actions = _validateAndSort(descriptors) {
    _byId = Map.unmodifiable({
      for (final action in actions) action.id: action,
    });
  }

  factory AuthoringActionRegistry.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, const {'formatVersion', 'actions'});
    if (json['formatVersion'] != 1) {
      throw FormatException(
        'Unsupported action registry formatVersion: ${json['formatVersion']}',
      );
    }
    final rawActions = json['actions'];
    if (rawActions is! List) {
      throw const FormatException('actions must be a JSON list');
    }
    return AuthoringActionRegistry(
      rawActions.map((rawAction) {
        if (rawAction is! Map) {
          throw const FormatException('action must be a JSON object');
        }
        return AuthoringActionDescriptor.fromJson(
          Map<String, dynamic>.from(rawAction),
        );
      }),
    );
  }

  final List<AuthoringActionDescriptor> actions;
  late final Map<String, AuthoringActionDescriptor> _byId;

  AuthoringActionDescriptor? find(String actionId) => _byId[actionId];

  AuthoringActionDescriptor require(String actionId) {
    return find(actionId) ?? (throw UnknownAuthoringActionException(actionId));
  }

  Map<String, Object?> toJson() {
    return {
      'formatVersion': 1,
      'actions':
          actions.map((action) => action.toJson()).toList(growable: false),
    };
  }

  static List<AuthoringActionDescriptor> _validateAndSort(
    Iterable<AuthoringActionDescriptor> descriptors,
  ) {
    final byId = <String, AuthoringActionDescriptor>{};
    for (final descriptor in descriptors) {
      final existing = byId[descriptor.id];
      if (existing != null) {
        if (existing.version == descriptor.version) {
          throw DuplicateAuthoringActionException(
            descriptor.id,
            descriptor.version,
          );
        }
        throw IncompatibleAuthoringActionVersionException(
          descriptor.id,
          [existing.version, descriptor.version],
        );
      }
      byId[descriptor.id] = descriptor;
    }
    final sorted = byId.values.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    return List.unmodifiable(sorted);
  }
}
