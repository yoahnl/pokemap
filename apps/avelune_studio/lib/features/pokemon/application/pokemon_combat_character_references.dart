part of 'pokemon_combat_controller.dart';

extension PokemonCombatCharacterReferences on PokemonCombatController {
  String? characterDraftOwner(String id) {
    if (operationActive) return 'Pokémon · opération de combats en cours';
    final selected = trainer;
    if (selected == null ||
        (!selected.dirty && fieldErrors.isEmpty) ||
        (selected.base?.characterId != id &&
            selected.current.characterId != id)) {
      return null;
    }
    return 'Dresseur · ${selected.current.name} · brouillon';
  }

  void reconcileCharacterReferences(
    ProjectManifest project,
    Map<String, MapData> changedMaps,
  ) {
    final selected = trainer;
    final updated = project.trainers
        .where((entry) => entry.id == selected?.current.id)
        .firstOrNull;
    if (selected != null &&
        jsonEncode(selected.base?.toJson()) != jsonEncode(updated?.toJson())) {
      if (selected.dirty || fieldErrors.isNotEmpty || saving) {
        throw StateError(
          'Enregistrez ou annulez ce dresseur avant de modifier son personnage.',
        );
      }
      trainer = updated == null ? null : PokemonTrainerDraft(updated);
    }
    _generation++;
    loading = false;
    final before = snapshot;
    if (before != null) {
      snapshot = PokemonCombatSnapshot(
        project: project,
        maps: [for (final map in before.maps) changedMaps[map.id] ?? map],
      );
    }
    changed();
  }
}
