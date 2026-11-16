import '../../game_memory/domain/narrative_index_port.dart';
import '../../story_draft/application/story_draft.dart';
import '../../story_draft/domain/story_draft_entry.dart';

final class DialogueCatalogRow {
  const DialogueCatalogRow(this.id, this.title, {this.deleted = false});

  final String id;
  final String title;
  final bool deleted;
}

List<DialogueCatalogRow> dialogueCatalogRows(
  List<NarrativeTitle> titles,
  StoryDraft draft,
) {
  final rows = {
    for (final title in titles)
      title.id: DialogueCatalogRow(title.id, title.title),
  };
  for (final id in draft.touched(StoryDraftKind.dialogue)) {
    final edit = draft.entryOf(StoryDraftKind.dialogue, id)!;
    rows[id] = DialogueCatalogRow(
      id,
      (edit.current ?? edit.base)?.entry.name ?? rows[id]?.title ?? '',
      deleted: edit.current == null,
    );
  }
  return rows.values.toList()..sort((a, b) {
    final byName = a.title.toLowerCase().compareTo(b.title.toLowerCase());
    return byName == 0 ? a.id.compareTo(b.id) : byName;
  });
}
