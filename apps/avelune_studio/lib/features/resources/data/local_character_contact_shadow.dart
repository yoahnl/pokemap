part of 'local_resource_adapter.dart';

extension _LocalCharacterContactShadow on LocalResourceAdapter {
  Future<ResourceMutationReceipt> _setCharacterContactShadow(
    ProjectManifest before,
    String beforeRevision,
    Map<String, Object?> fields, {
    String? Function()? validateBeforeApply,
  }) async {
    final id = fields['characterId'];
    final enabled = fields['contactShadow'];
    if (id is! String ||
        id.trim().isEmpty ||
        (enabled != null && enabled is! bool)) {
      throw const ResourceFailure('Réglage d’ombre du personnage invalide.');
    }
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: reader,
    );
    final operationId = _identity('resource');
    final service = LocalCharacterContactShadowAuthoring(
      policy: policy,
      reader: reader,
    );
    var preconditionRejected = false;
    Future<CharacterContactShadowMutation> save() => service.set(
      projectRoot: session.directoryPath,
      expectedRevision: beforeRevision,
      characterId: id,
      enabled: enabled as bool?,
      operationId: operationId,
      precondition: () async {
        try {
          _requireAvailable();
          await beforeTransactionPrecondition?.call();
          _requireAvailable();
          final problem = validateBeforeApply?.call();
          if (problem != null) throw ResourceFailure(problem);
        } on Object {
          preconditionRejected = true;
          rethrow;
        }
      },
    );
    late final CharacterContactShadowMutation result;
    try {
      result = await save();
    } on Object catch (failure) {
      final resumable =
          failure is JournaledAuthoringTransactionException &&
              {
                'transaction.recovery_required',
                'transaction.finalization_required',
              }.contains(failure.code) ||
          failure is AuthoringIdempotencyException &&
              failure.code == 'idempotency.recovery_required';
      if (preconditionRejected || !resumable) {
        throw ResourceFailure(
          'L’enregistrement de l’ombre n’a pas été confirmé. Relisez le projet avant de réessayer. $failure',
        );
      }
      try {
        result = await save();
      } on Object catch (recoveryFailure) {
        throw ResourceFailure(
          'L’enregistrement de l’ombre nécessite une relecture avant une nouvelle modification. $recoveryFailure',
        );
      }
    }
    final manifest = before.copyWith(
      characters: [
        for (final character in before.characters)
          character.id == id
              ? character.copyWith(contactShadow: result.afterValue)
              : character,
      ],
    );
    final receipt = ResourceMutationReceipt(
      before: before,
      manifest: manifest,
      beforeRevision: result.beforeRevision,
      revision: result.afterRevision,
      changedPaths: result.beforeRevision == result.afterRevision
          ? const []
          : const ['project.json'],
      operationId: operationId,
      actionId: 'characterStudio.contactShadow.set',
    );
    try {
      await beforeReconciliation?.call();
      _requireAvailable();
      await mapAdapter.acceptResourceMutation(session, receipt);
    } on Object catch (failure) {
      throw ResourceFailure(
        'L’ombre a été enregistrée, mais l’interface doit être relue. $failure',
        partialReceipt: receipt,
      );
    }
    return receipt;
  }
}
