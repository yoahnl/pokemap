import 'dart:convert';

enum PokemonWorkspaceView { pokedex, moves, items, shops }

enum PokemonDetailSection { overview, forms, learnset, evolution, media }

enum PokemonDocumentFamily { species, learnset, evolution, media }

final class PokemonSpeciesSummary {
  const PokemonSpeciesSummary({
    required this.id,
    required this.name,
    required this.nationalDex,
    required this.generation,
    required this.types,
    required this.formIds,
    this.baseFormId = '',
    this.isBaseForm = true,
    required this.mediaRelativePath,
    this.learnsetReference = '',
    this.evolutionReference = '',
    this.mediaReference = '',
    required this.enabled,
    required this.relativePath,
  });

  final String id;
  final String name;
  final int nationalDex;
  final int generation;
  final List<String> types;
  final List<String> formIds;
  final String baseFormId;
  final bool isBaseForm;
  final String mediaRelativePath;
  final String learnsetReference;
  final String evolutionReference;
  final String mediaReference;
  final bool enabled;
  final String relativePath;
}

final class PokemonDocumentSource {
  const PokemonDocumentSource({
    required this.family,
    required this.relativePath,
    required this.bytes,
    required this.document,
    this.problem,
  });

  final PokemonDocumentFamily family;
  final String relativePath;
  final List<int>? bytes;
  final Map<String, dynamic>? document;
  final String? problem;
}

final class PokemonSpeciesBundle {
  const PokemonSpeciesBundle({
    required this.species,
    required this.learnset,
    required this.evolution,
    required this.media,
  });

  final PokemonDocumentSource species;
  final PokemonDocumentSource? learnset;
  final PokemonDocumentSource? evolution;
  final PokemonDocumentSource? media;

  Iterable<PokemonDocumentSource> get documents => [
    species,
    ?learnset,
    ?evolution,
    ?media,
  ];

  PokemonDocumentSource? source(PokemonDocumentFamily family) {
    for (final document in documents) {
      if (document.family == family) return document;
    }
    return null;
  }
}

final class PokemonSpeciesDraft {
  static const _maxHistoryEntries = 100;
  static const _maxHistoryBytes = 16 * 1024 * 1024;

  PokemonSpeciesDraft(this.base)
    : _current = {
        for (final source in base.documents)
          if (source.document != null) source.family: _copy(source.document!),
      };

  final PokemonSpeciesBundle base;
  final Map<PokemonDocumentFamily, Map<String, dynamic>> _current;
  final List<_PokemonDraftHistoryEntry> _undo = [];
  final List<_PokemonDraftHistoryEntry> _redo = [];

  String get id => base.species.document!['id'] as String;

  Map<String, dynamic>? document(PokemonDocumentFamily family) =>
      _current[family];

  bool get dirty => changedFamilies.isNotEmpty;

  List<PokemonDocumentFamily> get changedFamilies => [
    for (final family in PokemonDocumentFamily.values)
      if (jsonEncode(_current[family]) !=
          jsonEncode(base.source(family)?.document))
        family,
  ];

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void clearHistory() {
    _undo.clear();
    _redo.clear();
  }

  void edit(
    PokemonDocumentFamily family,
    void Function(Map<String, dynamic>) change, {
    Map<String, dynamic>? initial,
  }) {
    final previous = _current[family];
    final before = previous == null ? null : jsonEncode(previous);
    final next =
        (jsonDecode(before ?? jsonEncode(initial ?? <String, dynamic>{}))
                as Map)
            .cast<String, dynamic>();
    change(next);
    if (jsonEncode(next) == before) return;
    _pushHistory(_undo, _PokemonDraftHistoryEntry(family, before));
    _redo.clear();
    _current[family] = next;
  }

  void undo() {
    if (_undo.isEmpty) return;
    final entry = _undo.removeLast();
    _pushHistory(_redo, _snapshot(entry.family));
    _restore(entry);
  }

  void redo() {
    if (_redo.isEmpty) return;
    final entry = _redo.removeLast();
    _pushHistory(_undo, _snapshot(entry.family));
    _restore(entry);
  }

  _PokemonDraftHistoryEntry _snapshot(PokemonDocumentFamily family) =>
      _PokemonDraftHistoryEntry(
        family,
        _current[family] == null ? null : jsonEncode(_current[family]),
      );

  void _restore(_PokemonDraftHistoryEntry entry) {
    final snapshot = entry.snapshot;
    if (snapshot == null) {
      _current.remove(entry.family);
    } else {
      _current[entry.family] = (jsonDecode(snapshot) as Map)
          .cast<String, dynamic>();
    }
  }

  static void _pushHistory(
    List<_PokemonDraftHistoryEntry> entries,
    _PokemonDraftHistoryEntry entry,
  ) {
    if (entry.retainedBytes > _maxHistoryBytes) {
      entries.clear();
      return;
    }
    entries.add(entry);
    var retainedBytes = entries.fold<int>(
      0,
      (total, entry) => total + entry.retainedBytes,
    );
    while (entries.length > _maxHistoryEntries ||
        retainedBytes > _maxHistoryBytes) {
      retainedBytes -= entries.removeAt(0).retainedBytes;
    }
  }

  static Map<String, dynamic> _copy(Map<String, dynamic> value) =>
      (jsonDecode(jsonEncode(value)) as Map).cast<String, dynamic>();
}

final class _PokemonDraftHistoryEntry {
  const _PokemonDraftHistoryEntry(this.family, this.snapshot);

  final PokemonDocumentFamily family;
  final String? snapshot;

  int get retainedBytes => (snapshot?.length ?? 0) * 2;
}

final class PokemonMoveSummary {
  const PokemonMoveSummary({
    required this.id,
    required this.name,
    this.type,
    this.category,
    this.power,
    this.accuracy,
    this.pp,
    this.priority,
    this.target,
    this.description,
    this.userCreated = false,
  });

  final String id;
  final String name;
  final String? type;
  final String? category;
  final int? power;
  final String? accuracy;
  final int? pp;
  final int? priority;
  final String? target;
  final String? description;
  final bool userCreated;
}

final class PokemonMovesCatalogView {
  const PokemonMovesCatalogView({
    required this.entries,
    required this.relativePath,
    this.problem,
    this.diagnostics = const [],
  });

  final List<PokemonMoveSummary> entries;
  final String relativePath;
  final String? problem;
  final List<String> diagnostics;
  bool get available => problem == null;
}

final class PokemonWorkspaceIndex {
  const PokemonWorkspaceIndex({
    required this.enabled,
    required this.entries,
    required this.moves,
    required this.types,
    required this.items,
    this.locale = 'fr',
    this.abilityNames = const {},
  });

  final bool enabled;
  final List<PokemonSpeciesSummary> entries;
  final PokemonMovesCatalogView moves;
  final List<String> types;
  final Map<String, String> items;
  final String locale;
  final Map<String, String> abilityNames;
}

final class PokemonWorkspaceFailure implements Exception {
  const PokemonWorkspaceFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
