import 'dart:async';

import '../domain/narrative_index_port.dart';
import 'game_memory_resource.dart';

final class GameMemoryNames {
  GameMemoryNames(this._port, this._changed);

  final NarrativeIndexPort _port;
  final void Function() _changed;
  final _kinds =
      <NarrativeTitleKind, GameMemoryResource<Map<String, String>>>{};

  GameMemoryResource<Map<String, String>> of(NarrativeTitleKind kind) =>
      _kinds.putIfAbsent(kind, GameMemoryResource.new);

  Future<void> ensure(NarrativeTitleKind kind) => of(kind).load(
    () async => {
      for (final title in await _port.titles(kind))
        if (title.title.trim().isNotEmpty) title.id: title.title,
    },
    _changed,
  );

  String? name(NarrativeTitleKind kind, String id) => _kinds[kind]?.value?[id];

  void clear() => _kinds.clear();

  void seed(NarrativeTitleKind kind, List<NarrativeTitle> titles) {
    final resource = of(kind);
    if (resource.ready) return;
    resource.value = {
      for (final title in titles)
        if (title.title.trim().isNotEmpty) title.id: title.title,
    };
  }
}
