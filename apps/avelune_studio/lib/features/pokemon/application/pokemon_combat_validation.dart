part of 'pokemon_combat_controller.dart';

String _newCombatId(String title, Iterable<String> existing) {
  var slug = title.toLowerCase();
  for (final pair in const [
    ('[àâäá]', 'a'),
    ('[ç]', 'c'),
    ('[èéêë]', 'e'),
    ('[ìíîï]', 'i'),
    ('[ñ]', 'n'),
    ('[òóôö]', 'o'),
    ('[ùúûü]', 'u'),
    ('[ýÿ]', 'y'),
  ]) {
    slug = slug.replaceAll(RegExp(pair.$1), pair.$2);
  }
  slug = slug
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  if (slug.isEmpty) slug = 'combat';
  final used = existing.toSet();
  var candidate = slug;
  for (var suffix = 2; used.contains(candidate); suffix++) {
    candidate = '${slug}_$suffix';
  }
  return candidate;
}

extension PokemonCombatValidation on PokemonCombatController {
  String? _validate(PokemonWorkspaceIndex index) {
    final selectedTable = table?.current;
    if (selectedTable != null) {
      if (selectedTable.allEntries.isEmpty) {
        return 'Ajoutez au moins une espèce.';
      }
      if (selectedTable.tags.contains('studio:unique') &&
          (selectedTable.allEntries.length != 1 ||
              selectedTable.allEntries.single.minLevel !=
                  selectedTable.allEntries.single.maxLevel)) {
        return 'Une rencontre unique demande une espèce et un niveau fixe.';
      }
      for (final entry in selectedTable.allEntries) {
        if (!index.entries.any(
          (species) => species.id == entry.speciesId && species.enabled,
        )) {
          return 'Espèce ${entry.speciesId} absente ou inactive dans le projet.';
        }
        if (entry.minLevel < 1 ||
            entry.maxLevel < entry.minLevel ||
            entry.weight < 1) {
          return 'Corrigez les niveaux et poids des rencontres.';
        }
      }
      try {
        ProjectValidator.validate(
          snapshot!.project.copyWith(
            encounterTables: [
              for (final value in snapshot!.project.encounterTables)
                if (value.id != selectedTable.id) value,
              selectedTable,
            ],
          ),
        );
      } on ValidationException catch (failure) {
        return switch (failure.code) {
          'encounter.time_window_invalid' =>
            'Choisissez deux horaires différents pour chaque plage horaire.',
          'encounter.variant_fact_invalid' => 'Une condition de variante utilise un état du monde absent ou incompatible.',
          'encounter.variant_invalid' =>
            'Chaque variante demande un nom et au moins une espèce.',
          _ => failure.toString(),
        };
      }
    }
    final selectedTrainer = trainer?.current;
    if (selectedTrainer != null) {
      if (selectedTrainer.team.length > 6) {
        return 'Une équipe contient au maximum six Pokémon.';
      }
      if (selectedTrainer.battleFormat == BattleFormat.doubles) {
        if (selectedTrainer.team.length < 2) {
          return 'Un combat double demande au moins deux Pokémon.';
        }
        if (selectedTrainer.tags.contains('static-encounter')) {
          return 'Les rencontres uniques utilisent un combat simple.';
        }
        if (snapshot!.project.pokemon.ruleset.mechanics.disabledFeatures
            .contains(PokemonDisabledFeature.doubleBattles)) {
          return 'Choisissez les règles Standard pour les combats doubles.';
        }
      }
      try {
        ProjectValidator.validateTrainerBallItemReferences([
          selectedTrainer,
        ], itemCatalog: index.itemCatalog);
        ProjectValidator.validateTrainerBattleItemReferences([
          selectedTrainer,
        ], itemCatalog: index.itemCatalog);
      } on ValidationException catch (failure) {
        return failure.toString();
      }
      if (selectedTrainer.team.isEmpty) return 'Ajoutez un Pokémon à l’équipe.';
      for (final pokemon in selectedTrainer.team) {
        final statIssues = validateTrainerPokemonStats(pokemon);
        if (statIssues.isNotEmpty) return statIssues.first.message;
        if (pokemon.moves.isEmpty) {
          return 'Ajoutez au moins une attaque à chaque Pokémon du dresseur.';
        }
        if (!index.entries.any(
          (species) => species.id == pokemon.speciesId && species.enabled,
        )) {
          return 'Espèce ${pokemon.speciesId} absente ou inactive.';
        }
        if (pokemon.level < 1 || pokemon.level > 100) {
          return 'Le niveau doit être compris entre 1 et 100.';
        }
        for (final move in pokemon.moves) {
          if (!index.moves.entries.any((value) => value.id == move)) {
            return 'Attaque $move absente du catalogue.';
          }
        }
        if (pokemon.heldItemId case final itemId?) {
          if (!index.items.containsKey(itemId)) {
            return 'Objet tenu $itemId absent du catalogue.';
          }
        }
      }
    }
    return null;
  }

  Future<bool> deleteSelected() async {
    if (saving || dirty) return false;
    final selectedTable = table;
    final selectedTrainer = trainer;
    if (selectedTable == null && selectedTrainer == null) return false;
    saving = true;
    error = null;
    changed();
    try {
      if (selectedTable != null) {
        await port.deleteTable(selectedTable.current);
      } else {
        await port.deleteTrainer(selectedTrainer!.current);
      }
      if (_disposed) return false;
      table = null;
      trainer = null;
      saving = false;
      await load(refresh: true);
      notice = 'Fiche supprimée.';
      return !_disposed;
    } on Object catch (failure) {
      if (!_disposed) error = 'Suppression refusée : $failure';
      return false;
    } finally {
      saving = false;
      if (!_disposed) changed();
    }
  }
}
