import 'resource_port.dart';

final class ResourceMutationPreparation {
  ResourceMutationPreparation({
    required this.sessionId,
    required this.actionId,
    required Map<String, Object?> parameters,
    required this.snapshotRevision,
    required this.manifestRevision,
    required List<String> changedPaths,
    required this.confirmationRequired,
    Map<String, Object?> impact = const {},
  }) : parameters = _freezeParameters(parameters),
       impact = _freezeParameters(impact),
       changedPaths = List.unmodifiable(changedPaths);

  final String sessionId;
  final String actionId;
  final Map<String, Object?> parameters;
  final String snapshotRevision;
  final String manifestRevision;
  final List<String> changedPaths;
  final bool confirmationRequired;
  final Map<String, Object?> impact;
  bool get noChange => changedPaths.isEmpty;
}

Map<String, Object?> _freezeParameters(Map<String, Object?> values) =>
    Map.unmodifiable({
      for (final entry in values.entries) entry.key: _freeze(entry.value),
    });

Object? _freeze(Object? value) {
  if (value is Map<String, Object?>) return _freezeParameters(value);
  if (value is List) return List.unmodifiable(value.map(_freeze));
  return value;
}

abstract interface class ResourceMutationPreparationPort {
  Future<void> reconcileReceipt(ResourceMutationReceipt receipt);
  Future<String> captureResourceRevision();
  Future<String?> resourceFingerprint(
    String tilesetId,
    String snapshotRevision,
  );
  Future<ResourceMutationPreparation> prepareOperation(
    String actionId,
    Map<String, Object?> parameters, {
    String? expectedSnapshotRevision,
  });
  Future<ResourceMutationReceipt> applyPrepared(
    ResourceMutationPreparation preparation, {
    bool confirmDestructive = false,
    String? Function()? validateBeforeApply,
  });
}
