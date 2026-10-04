part of 'local_resource_adapter.dart';

bool _characterRemovalAction(String action) =>
    action == 'characterStudio.character.delete' ||
    action == 'characterStudio.character.deletePlan';

void _validateCharacterRemovalChanges(
  AuthoringPlan plan,
  ProjectManifest manifest,
) {
  final allowed = {
    'project:project': 'project.json',
    for (final entry in manifest.maps) 'map:${entry.id}': entry.relativePath,
    for (final entry in manifest.dialogues)
      'dialogue:${entry.id}': entry.relativePath,
  };
  for (final change in plan.changeSet.changes) {
    if (allowed['${change.resource.kind}:${change.resource.id}'] !=
            change.storageKey ||
        change.afterBytes == null) {
      throw const ResourceFailure(
        'Ce retrait tente de modifier un document hors de ses propriétaires.',
      );
    }
  }
}
