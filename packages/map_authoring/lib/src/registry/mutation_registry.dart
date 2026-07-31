import '../contracts/action_descriptor.dart';

enum MutationContractProof {
  plan,
  dryRun,
  staleCas,
  idempotency,
  recovery,
  authorization,
  receipt,
  undo,
  nonUndoablePolicy,
}

final class MutationContractEvidence {
  MutationContractEvidence({
    required Iterable<MutationContractProof> proofs,
    String? nonUndoableReason,
  })  : proofs = Set.unmodifiable(proofs),
        nonUndoableReason = nonUndoableReason == null
            ? null
            : _stableReason(nonUndoableReason) {
    if (this.proofs.contains(MutationContractProof.nonUndoablePolicy) !=
        (this.nonUndoableReason != null)) {
      throw ArgumentError(
        'A non-undoable policy proof and its stable reason are inseparable.',
      );
    }
    if (this.proofs.contains(MutationContractProof.undo) &&
        this.proofs.contains(MutationContractProof.nonUndoablePolicy)) {
      throw ArgumentError(
        'A mutation cannot be both undoable and explicitly non-undoable.',
      );
    }
  }

  static const Set<MutationContractProof> mandatoryCore = {
    MutationContractProof.plan,
    MutationContractProof.dryRun,
    MutationContractProof.staleCas,
    MutationContractProof.idempotency,
    MutationContractProof.recovery,
    MutationContractProof.authorization,
    MutationContractProof.receipt,
  };

  final Set<MutationContractProof> proofs;
  final String? nonUndoableReason;
}

final class MutationRegistryException implements Exception {
  const MutationRegistryException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'MutationRegistryException($code): $message';
}

/// Admission gate preventing partially safe mutation actions from shipping.
final class AuthoringMutationRegistry {
  final Map<String, _RegisteredMutation> _registered = {};

  void register({
    required AuthoringActionDescriptor descriptor,
    required MutationContractEvidence evidence,
  }) {
    final missing = MutationContractEvidence.mandatoryCore
        .difference(evidence.proofs)
        .toList()
      ..sort((left, right) => left.name.compareTo(right.name));
    if (missing.isNotEmpty) {
      throw MutationRegistryException(
        'mutation.contract_incomplete',
        'Mutation evidence is missing: ${missing.map((item) => item.name).join(', ')}.',
      );
    }
    if (!evidence.proofs.contains(MutationContractProof.undo) &&
        !evidence.proofs.contains(MutationContractProof.nonUndoablePolicy)) {
      throw const MutationRegistryException(
        'mutation.undo_policy_missing',
        'Mutation evidence must prove undo or an explicit non-undoable policy.',
      );
    }
    if (descriptor.riskLevel == AuthoringRiskLevel.readOnly) {
      throw const MutationRegistryException(
        'mutation.read_only_descriptor',
        'A mutation cannot use a read-only action descriptor.',
      );
    }
    final key = '${descriptor.id}@${descriptor.version}';
    if (_registered.containsKey(key)) {
      throw const MutationRegistryException(
        'mutation.already_registered',
        'The mutation action version is already registered.',
      );
    }
    _registered[key] = _RegisteredMutation(descriptor, evidence);
  }

  List<AuthoringActionDescriptor> get actions => List.unmodifiable(
        _registered.values.map((entry) => entry.descriptor).toList()
          ..sort((left, right) {
            final idOrder = left.id.compareTo(right.id);
            return idOrder != 0
                ? idOrder
                : left.version.compareTo(right.version);
          }),
      );

  MutationContractEvidence? evidenceFor(String actionId, int version) =>
      _registered['$actionId@$version']?.evidence;
}

final class _RegisteredMutation {
  const _RegisteredMutation(this.descriptor, this.evidence);

  final AuthoringActionDescriptor descriptor;
  final MutationContractEvidence evidence;
}

String _stableReason(String value) {
  if (!RegExp(r'^[a-z][a-z0-9_.-]*$').hasMatch(value)) {
    throw ArgumentError.value(
      value,
      'nonUndoableReason',
      'must be a stable safe code',
    );
  }
  return value;
}
