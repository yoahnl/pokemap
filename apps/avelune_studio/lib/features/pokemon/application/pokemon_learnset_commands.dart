part of 'pokemon_workspace_controller.dart';

extension PokemonLearnsetCommands on PokemonWorkspaceController {
  void beginMoveSelection(String group, {int? replaceIndex}) {
    if (mutationActive) return;
    if (selectedDraft?.document(PokemonDocumentFamily.learnset) == null) return;
    moveInsertGroup = group;
    moveReplaceIndex = replaceIndex;
    view = PokemonWorkspaceView.moves;
    _notify();
  }

  void chooseMove(String moveId) {
    if (mutationActive) return;
    if (index?.moves.entries.any((move) => move.id == moveId) != true) return;
    final draft = selectedDraft;
    final group = moveInsertGroup;
    if (draft == null || draft.base.learnset == null || group == null) return;
    edit(
      PokemonDocumentFamily.learnset,
      (json) {
        final moves = List<dynamic>.from(json[group] as List? ?? []);
        final old =
            moveReplaceIndex == null || moveReplaceIndex! >= moves.length
            ? null
            : moves[moveReplaceIndex!];
        final replacement = group == 'startingMoves' || group == 'relearnMoves'
            ? moveId
            : old is Map
            ? <String, dynamic>{
                ...old.cast<String, dynamic>(),
                'moveId': moveId,
              }
            : group == 'levelUp'
            ? <String, dynamic>{
                'moveId': moveId,
                'level': 1,
                'source': 'level_up',
                'versionGroup': '',
              }
            : <String, dynamic>{'moveId': moveId, 'versionGroup': ''};
        if (moveReplaceIndex != null && moveReplaceIndex! < moves.length) {
          moves[moveReplaceIndex!] = replacement;
        } else {
          moves.add(replacement);
        }
        json[group] = moves;
      },
      initial: {
        'schemaVersion': currentPokemonDataSchemaVersion,
        'speciesId': draft.id,
      },
    );
    moveInsertGroup = null;
    moveReplaceIndex = null;
    view = PokemonWorkspaceView.pokedex;
    section = PokemonDetailSection.learnset;
    _notify();
  }

  void removeLearnsetMove(String group, int index) {
    edit(PokemonDocumentFamily.learnset, (json) {
      final entries = List<dynamic>.from(json[group] as List? ?? []);
      if (index >= 0 && index < entries.length) entries.removeAt(index);
      json[group] = entries;
    });
  }

  void editLearnsetField(String group, int index, String key, String value) {
    edit(PokemonDocumentFamily.learnset, (json) {
      final entries = List<dynamic>.from(json[group] as List? ?? []);
      if (index < 0 || index >= entries.length || entries[index] is! Map) {
        return;
      }
      final current = Map<String, dynamic>.from(entries[index] as Map);
      current[key] = key == 'level' ? int.tryParse(value) ?? value : value;
      entries[index] = current;
      json[group] = entries;
    });
  }
}
