import 'package:map_core/map_core_domain.dart';

import '../../story_draft/application/story_draft.dart';
import '../../story_draft/domain/story_draft_entry.dart';
import '../domain/narrative_index_port.dart';

enum GameMemoryFactFilter { neverRead, neverWritten }

final class GameMemoryFactRow {
  const GameMemoryFactRow({
    required this.id,
    required this.label,
    this.category,
    this.value,
    this.unsaved = false,
    this.created = false,
  });

  final String id;
  final String label;
  final String? category;
  final NarrativeValue? value;
  final bool unsaved;
  final bool created;
}

List<GameMemoryFactRow> gameMemoryFactRows({
  required List<NarrativeTitle> titles,
  required StoryDraft draft,
  required Map<String, NarrativeFactDefinition> details,
  required Map<String, NarrativeUsages> usages,
  String query = '',
  Set<GameMemoryFactFilter> filters = const {},
}) {
  const kind = StoryDraftKind.fact;
  final saved = {for (final title in titles) title.id};
  final rows = <GameMemoryFactRow>[
    for (final title in titles)
      if (draft.entryOf(kind, title.id) case final entry)
        if (entry == null || entry.current != null)
          GameMemoryFactRow(
            id: title.id,
            label: entry?.current?.label ?? title.title,
            category: entry?.current?.category ?? title.category,
            value:
                entry?.current?.initialValue ??
                title.value ??
                details[title.id]?.initialValue,
            unsaved: entry != null,
          ),
    for (final id in draft.touched(kind))
      if (!saved.contains(id))
        if (draft.entryOf(kind, id)?.current case final fact?)
          GameMemoryFactRow(
            id: id,
            label: fact.label,
            category: fact.category,
            value: fact.initialValue,
            unsaved: true,
            created: true,
          ),
  ];
  final needle = query.trim().toLowerCase();
  bool unused(GameMemoryFactRow row, NarrativeFactRole role) =>
      row.created || (usages[row.id]?.withRole(role).isEmpty ?? false);
  return [
    for (final row in rows)
      if ((needle.isEmpty || row.label.toLowerCase().contains(needle)) &&
          (!filters.contains(GameMemoryFactFilter.neverRead) ||
              unused(row, NarrativeFactRole.read)) &&
          (!filters.contains(GameMemoryFactFilter.neverWritten) ||
              unused(row, NarrativeFactRole.write)))
        row,
  ];
}
