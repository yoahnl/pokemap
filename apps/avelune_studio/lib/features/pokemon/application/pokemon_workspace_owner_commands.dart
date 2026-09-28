part of 'pokemon_workspace_controller.dart';

extension PokemonWorkspaceOwnerCommands on PokemonWorkspaceController {
  Future<bool> saveActiveOwner() async {
    if (!hasPendingChanges) return true;
    final dirtySpecies = _drafts.values.where((draft) => draft.dirty).length;
    final dirtyCommerce = commerce?.dirty == true ? 1 : 0;
    final dirtyCombat = combat?.dirty == true ? 1 : 0;
    if (!activeOwnerDirty || dirtySpecies + dirtyCommerce + dirtyCombat != 1) {
      error = 'Un autre brouillon Pokémon reste ouvert. Revenez à sa fiche.';
      _notify();
      return false;
    }
    if (view == PokemonWorkspaceView.items ||
        view == PokemonWorkspaceView.shops) {
      return commerce!.save();
    }
    if (view == PokemonWorkspaceView.combats) {
      final loaded = index;
      return loaded != null && await combat!.save(loaded);
    }
    final draft = selectedDraft;
    if (saving) return false;
    if (draft == null) return false;
    final id = draft.id;
    saving = true;
    lastSavedSpeciesId = null;
    error = null;
    _notify();
    try {
      final saved = await port.save(draft);
      if (_disposed) return false;
      _drafts[id] = PokemonSpeciesDraft(saved);
      await load(refresh: true);
      if (!_disposed) lastSavedSpeciesId = id;
      return !_disposed;
    } on Object catch (failure) {
      if (!_disposed) error = 'Enregistrement refusé : $failure';
      return false;
    } finally {
      saving = false;
      _notify();
    }
  }

  bool get activeOwnerDirty => switch (view) {
    PokemonWorkspaceView.pokedex => selectedDraft?.dirty == true,
    PokemonWorkspaceView.items =>
      commerce?.item != null && commerce?.dirty == true,
    PokemonWorkspaceView.shops =>
      commerce?.shop != null && commerce?.dirty == true,
    PokemonWorkspaceView.moves => false,
    PokemonWorkspaceView.combats => combat?.dirty == true,
  };

  bool discardActiveOwner() {
    if (mutationActive || !activeOwnerDirty) return false;
    if (view == PokemonWorkspaceView.pokedex) {
      discardSelectedSpecies();
    } else if (view == PokemonWorkspaceView.combats) {
      combat!.discard();
    } else {
      commerce!.discardSelected();
    }
    return true;
  }
}
