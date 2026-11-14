import '../domain/narrative_index_port.dart';

enum GameMemoryProblem { failed, preparationRequired, unavailable }

final class GameMemoryResource<T> {
  T? value;
  bool loading = false;
  GameMemoryProblem? problem;
  Object? cause;
  int _generation = 0;

  bool get ready => value != null && problem == null;

  Future<void> load(
    Future<T> Function() read,
    void Function() changed, {
    bool force = false,
  }) async {
    if (loading || (ready && !force)) return;
    final generation = ++_generation;
    loading = true;
    problem = null;
    cause = null;
    changed();
    try {
      final result = await read();
      if (generation != _generation) return;
      value = result;
    } on NarrativeIndexPreparationRequired catch (failure) {
      if (generation != _generation) return;
      problem = GameMemoryProblem.preparationRequired;
      cause = failure.scope;
    } on NarrativeIndexUnavailable catch (failure) {
      if (generation != _generation) return;
      problem = GameMemoryProblem.unavailable;
      cause = failure;
    } on Object catch (failure) {
      if (generation != _generation) return;
      problem = GameMemoryProblem.failed;
      cause = failure;
    } finally {
      if (generation == _generation) {
        loading = false;
        changed();
      }
    }
  }
}
