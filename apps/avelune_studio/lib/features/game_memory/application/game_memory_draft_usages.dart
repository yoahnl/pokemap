import 'dart:collection';

import '../../story_draft/application/story_draft.dart';
import '../../story_draft/domain/story_draft_entry.dart';
import '../domain/narrative_index_port.dart';
import 'game_memory_owner_usages.dart';

typedef _Owner = ({NarrativeOwnerKind kind, String id});
typedef _CachedUsage = ({
  NarrativeUsages? saved,
  int problem,
  NarrativeUsages value,
});

final class GameMemoryDraftUsages extends MapBase<String, NarrativeUsages> {
  GameMemoryDraftUsages(this.draft, this.saved);

  final StoryDraft draft;
  final Map<String, NarrativeUsages> Function() saved;
  final _versions = <StoryDraftKind<Object>, int>{};
  final _entries = <StoryDraftRef, StoryDraftEntry<Object>>{};
  final _uses = <StoryDraftRef, Set<GameMemoryFactUse>>{};
  final _dialogueBases = <StoryDraftRef, Set<GameMemoryFactUse>>{};
  final _byFact = <String, Set<NarrativeOwner>>{};
  final _baselineFacts = <_Owner, Set<String>>{};
  final _overridden = <_Owner>{};
  final _failures = <StoryDraftRef>{};
  final _cache = <String, _CachedUsage>{};
  var _problem = 0;

  static const _kinds = [
    StoryDraftKind.event,
    StoryDraftKind.scene,
    StoryDraftKind.worldRule,
    StoryDraftKind.story,
    StoryDraftKind.dialogue,
  ];

  bool get draftCovered {
    _sync();
    return _failures.isEmpty;
  }

  void _sync() {
    for (final kind in _kinds) {
      final version = draft.versionOf(kind);
      if (_versions[kind] == version) continue;
      _versions[kind] = version;
      final ids = {
        ...draft.touched(kind),
        for (final ref in _entries.keys)
          if (ref.kind == kind) ref.id,
      };
      for (final id in ids) {
        final ref = (kind: kind, id: id);
        final entry = draft.entryOf(kind, id);
        if (_entries[ref] == entry) continue;
        _replace(ref, entry);
      }
    }
  }

  void _replace(StoryDraftRef ref, StoryDraftEntry<Object>? entry) {
    final owner = (kind: gameMemoryOwnerKind(ref.kind), id: ref.id);
    final old = _uses.remove(ref) ?? const <GameMemoryFactUse>{};
    for (final use in old) {
      _byFact[use.factId]?.remove(use.owner);
      if (_byFact[use.factId]?.isEmpty == true) _byFact.remove(use.factId);
      _cache.remove(use.factId);
    }
    for (final id in _baselineFacts[owner] ?? const <String>{}) {
      _cache.remove(id);
    }
    _overridden.remove(owner);
    if (_failures.remove(ref)) _problem++;
    if (entry == null) {
      _entries.remove(ref);
      _put(ref, _dialogueBases[ref] ?? const {});
      return;
    }
    _entries[ref] = entry;
    try {
      if (ref.kind == StoryDraftKind.dialogue &&
          !_dialogueBases.containsKey(ref)) {
        _dialogueBases[ref] = gameMemoryOwnerUsages(ref, entry.base);
      }
      final uses = gameMemoryOwnerUsages(ref, entry.current);
      _overridden.add(owner);
      _put(ref, uses);
    } on Object {
      _failures.add(ref);
      _problem++;
    }
  }

  void _put(StoryDraftRef ref, Set<GameMemoryFactUse> uses) {
    _uses[ref] = uses;
    for (final use in uses) {
      _byFact.putIfAbsent(use.factId, () => {}).add(use.owner);
      _cache.remove(use.factId);
    }
  }

  @override
  NarrativeUsages? operator [](Object? key) {
    if (key is! String) return null;
    _sync();
    final baseline = saved()[key];
    final created = draft.entryOf(StoryDraftKind.fact, key)?.creation == true;
    if (baseline == null && !created && !_byFact.containsKey(key)) return null;
    final cached = _cache[key];
    if (cached != null &&
        identical(cached.saved, baseline) &&
        cached.problem == _problem) {
      return cached.value;
    }
    final owners = <NarrativeOwner>{};
    for (final owner in baseline?.owners ?? const <NarrativeOwner>[]) {
      final identity = (kind: owner.kind, id: owner.id);
      _baselineFacts.putIfAbsent(identity, () => {}).add(key);
      if (!_overridden.contains(identity)) owners.add(owner);
    }
    owners.addAll(_byFact[key] ?? const {});
    final value = NarrativeUsages(
      owners: owners.toList(),
      notCovered: {
        ...?baseline?.notCovered,
        if (baseline == null) 'narrativeUsages',
        if (_failures.isNotEmpty) 'draftAnalysis',
      }.toList(),
    );
    _cache[key] = (saved: baseline, problem: _problem, value: value);
    return value;
  }

  @override
  Iterable<String> get keys {
    _sync();
    return {
      ...saved().keys,
      ..._byFact.keys,
      ...draft.touched(StoryDraftKind.fact),
    };
  }

  void reset() {
    _versions.clear();
    _entries.clear();
    _uses.clear();
    _dialogueBases.clear();
    _byFact.clear();
    _baselineFacts.clear();
    _overridden.clear();
    _failures.clear();
    _cache.clear();
    _problem++;
  }

  @override
  void operator []=(String key, NarrativeUsages value) =>
      throw UnsupportedError('read only');

  @override
  void clear() => throw UnsupportedError('read only');

  @override
  NarrativeUsages? remove(Object? key) => throw UnsupportedError('read only');
}
