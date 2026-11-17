part of 'game_memory_controller.dart';

extension GameMemoryUsageLoading on GameMemoryController {
  void retryUsages() => unawaited(_loadFilterUsages(force: true));

  void retryFactUsages(String id) => unawaited(_selectUsages(id));

  String? usageErrorFor(String id) => _usageErrors[id];

  void revealUsages(String id) {
    if (_savedUsages.containsKey(id) ||
        _usagesRequested.contains(id) ||
        _usageErrors.containsKey(id)) {
      return;
    }
    _usagePending.add(id);
    _usageBatch ??= Timer(Duration.zero, _flushUsages);
  }

  Future<void> _flushUsages() async {
    _usageBatch = null;
    final ids = [..._usagePending];
    _usagePending.clear();
    final generation = _generation;
    try {
      await _loadUsages(ids);
    } on Object catch (failure) {
      if (generation != _generation) return;
      for (final id in ids) {
        _usageErrors[id] = failure is NarrativeIndexPreparationRequired
            ? failure.scope
            : '$failure';
      }
    }
    if (generation == _generation) changed();
  }

  Future<void> _loadFilterUsages({bool force = false}) => usagesFilter.load(
    () async {
      await _loadUsages([for (final title in facts.value!) title.id]);
      return true;
    },
    changed,
    force: force,
  );

  Future<void> _selectUsages(String id) async {
    final generation = _generation;
    try {
      _usageErrors.remove(id);
      await _loadUsages([id]);
      if (generation != _generation) return;
      for (final owner in usages[id]?.owners ?? const <NarrativeOwner>[]) {
        unawaited(names.ensure(owner.kind.titles));
      }
    } on NarrativeIndexPreparationRequired catch (failure) {
      if (generation != _generation) return;
      _usageErrors[id] = failure.scope;
    } on Object catch (failure) {
      if (generation != _generation) return;
      _usageErrors[id] = '$failure';
    }
    if (generation == _generation) changed();
  }

  Future<void> _loadUsages(List<String> ids) async {
    final generation = _generation;
    final missing = [
      for (final id in ids)
        if (!_savedUsages.containsKey(id) && _usagesRequested.add(id)) id,
    ];
    if (missing.isEmpty) return;
    try {
      final loaded = await port.factUsers(missing);
      if (generation != _generation) return;
      _savedUsages.addAll(loaded);
      if (missing.any((id) => !loaded.containsKey(id))) {
        throw const NarrativeIndexPreparationRequired('narrativeUsages');
      }
      for (final id in missing) {
        _usageErrors.remove(id);
      }
    } finally {
      if (generation == _generation) _usagesRequested.removeAll(missing);
    }
  }
}
