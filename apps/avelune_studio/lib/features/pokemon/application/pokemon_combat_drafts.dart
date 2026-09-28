part of 'pokemon_combat_controller.dart';

final class PokemonEncounterDraft {
  PokemonEncounterDraft(ProjectEncounterTable value, {this.created = false})
    : base = created ? null : value,
      current = value;

  ProjectEncounterTable? base;
  ProjectEncounterTable current;
  bool created;
  bool get dirty =>
      created || jsonEncode(base?.toJson()) != jsonEncode(current.toJson());

  void reset() => current = base ?? current;

  void markSaved() {
    base = current;
    created = false;
  }
}

final class PokemonTrainerDraft {
  PokemonTrainerDraft(ProjectTrainerEntry value, {this.created = false})
    : base = created ? null : value,
      current = value;

  ProjectTrainerEntry? base;
  ProjectTrainerEntry current;
  bool created;
  bool get dirty =>
      created || jsonEncode(base?.toJson()) != jsonEncode(current.toJson());

  void reset() => current = base ?? current;

  void markSaved() {
    base = current;
    created = false;
  }
}
