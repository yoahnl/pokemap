import 'dart:io';

import '../../../application/authoring_api/authoring_mutation_adapter.dart';

final class ProjectPresentationPresetService {
  const ProjectPresentationPresetService({required this.mutations});

  final AuthoringMutationAdapter mutations;

  Future<void> exportCurrent({
    required String projectRootPath,
    required String presetId,
    required String label,
    required String description,
    required String destinationPath,
    Map<String, String> licenses = const <String, String>{},
  }) async {
    final identity = _identity('preset_export');
    final plan = await mutations.plan(
      projectRootPath,
      actionId: 'presentation.preset.export',
      parameters: <String, Object?>{
        'presetId': presetId,
        'label': label,
        'description': description,
        'licenses': licenses,
      },
      idempotencyKey: identity,
      requestId: identity,
    );
    final artifact = plan.receipt.artifacts.single;
    await mutations.apply(plan, operationId: identity);
    final bytes = await mutations.readArtifact(
      projectRootPath,
      handle: artifact.uri,
    );
    await _writeAtomically(destinationPath, bytes);
  }

  Future<void> importAndApply({
    required String projectRootPath,
    required String sourcePath,
  }) async {
    final staged = await mutations.stageArtifact(
      projectRootPath,
      sourcePath: sourcePath,
      declaredMediaType: 'application/vnd.pokemap.presentation-preset+zip',
    );
    final identity = _identity('preset_import');
    final plan = await mutations.plan(
      projectRootPath,
      actionId: 'presentation.preset.import_apply',
      parameters: <String, Object?>{'artifactHandle': staged.reference.handle},
      idempotencyKey: identity,
      requestId: identity,
    );
    await mutations.apply(plan, operationId: identity);
  }

  Future<void> delete({
    required String projectRootPath,
    required String presetId,
  }) async {
    final identity = _identity('preset_delete');
    final plan = await mutations.plan(
      projectRootPath,
      actionId: 'presentation.preset.delete_apply',
      parameters: <String, Object?>{'presetId': presetId},
      idempotencyKey: identity,
      requestId: identity,
    );
    final confirmation = await mutations.confirm(plan);
    await mutations.apply(
      plan,
      operationId: identity,
      confirmationToken: confirmation,
    );
  }

  Future<void> _writeAtomically(String destinationPath, List<int> bytes) async {
    final destination = File(destinationPath);
    await destination.parent.create(recursive: true);
    final staging = File(
      '$destinationPath.pokemap-${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    final backup = File('$staging.bak');
    try {
      await staging.writeAsBytes(bytes, flush: true);
      try {
        await staging.rename(destination.path);
      } on FileSystemException {
        if (!await destination.exists()) rethrow;
        await destination.rename(backup.path);
        try {
          await staging.rename(destination.path);
        } on Object {
          if (!await destination.exists() && await backup.exists()) {
            await backup.rename(destination.path);
          }
          rethrow;
        }
        await backup.delete();
      }
    } finally {
      if (await staging.exists()) await staging.delete();
      if (await backup.exists() && await destination.exists()) {
        await backup.delete();
      }
    }
  }
}

String _identity(String prefix) =>
    '${prefix}_${DateTime.now().toUtc().microsecondsSinceEpoch}';
