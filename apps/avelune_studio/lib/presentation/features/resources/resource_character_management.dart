import '../../../features/resources/domain/resource_port.dart';
import '../characters/character_studio_controller.dart';
import 'resource_navigation.dart';

extension ResourceCharacterManagement on ResourceNavigation {
  List<String> characterManagementOwners(
    String action,
    Map<String, Object?> parameters,
  ) {
    final ids = {
      parameters['characterId'],
      parameters['replacementId'],
    }.whereType<String>().toSet();
    return {
      for (final id in ids)
        if (characters.draftFor(id)?.dirty ?? false)
          'Personnage ${characters.draftFor(id)!.saved.name} · modifications dans Character Studio',
      for (final document in workspace.documents.values)
        if (document.dirty &&
            [document.saved, document.current].any(
              (map) => map.entities.any(
                (entity) => ids.contains(entity.npc?.characterId),
              ),
            ))
          'Carte ${document.current.name} · enregistrez ou annulez dans Carte',
      for (final id in ids) ...?additionalCharacterOwners?.call(id),
    }.toList();
  }

  void reconcileCharacterManagement(ResourceMutationReceipt receipt) {
    if (receipt.actionId != 'characterStudio.character.delete') return;
    final retained = receipt.manifest.characters
        .map((character) => character.id)
        .toSet();
    final removed = receipt.before.characters
        .map((character) => character.id)
        .where((id) => !retained.contains(id))
        .toSet();
    characters.reconcileCatalog(receipt.manifest, removedIds: removed);
  }
}
