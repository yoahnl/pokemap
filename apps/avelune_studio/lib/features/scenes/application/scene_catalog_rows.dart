import 'dart:convert';

import 'package:map_core/map_core_domain.dart';

import '../../game_memory/domain/narrative_index_port.dart';
import '../../story_draft/application/story_draft.dart';
import '../../story_draft/domain/story_draft_entry.dart';
import 'scene_catalog_memberships.dart';

final class SceneCatalogRow {
  const SceneCatalogRow({
    required this.id,
    required this.title,
    required this.memberships,
    this.sceneId,
    this.deleted = false,
    this.missing = false,
    this.unsaved = false,
  });

  final String id;
  final String title;
  final String? sceneId;
  final List<SceneCatalogMembership> memberships;
  final bool deleted;
  final bool missing;
  final bool unsaved;
  bool get broken => missing || memberships.any((member) => member.broken);
  bool get openable => sceneId != null && !deleted && !missing;
}

List<SceneCatalogRow> sceneCatalogRows(
  List<NarrativeTitle> titles,
  StoryDraft draft,
  SceneCatalogMemberships memberships,
) {
  final names = {for (final title in titles) title.id: title.title};
  final savedIds = names.keys.toSet();
  final deleted = <String>{};
  final touched = draft.touched(StoryDraftKind.scene).toSet();
  for (final id in touched) {
    final entry = draft.entryOf(StoryDraftKind.scene, id)!;
    names[id] = entry.current?.name ?? entry.base?.name ?? names[id] ?? '';
    if (entry.current == null) deleted.add(id);
  }
  for (final id in memberships.byScene.keys) {
    names.putIfAbsent(id, () => '');
  }
  final rows = [
    for (final entry in names.entries)
      SceneCatalogRow(
        id: entry.key,
        sceneId: entry.key,
        title: entry.value,
        memberships: memberships.byScene[entry.key] ?? const [],
        deleted: deleted.contains(entry.key),
        missing: !savedIds.contains(entry.key) && !touched.contains(entry.key),
        unsaved: touched.contains(entry.key),
      ),
    for (final (index, member) in memberships.unresolved.indexed)
      SceneCatalogRow(
        id: 'unresolved:$index:${member.key}',
        title: member.link?.label ?? '',
        memberships: [member],
        missing: true,
      ),
  ];
  rows.sort((a, b) {
    final title = a.title.toLowerCase().compareTo(b.title.toLowerCase());
    return title == 0 ? a.id.compareTo(b.id) : title;
  });
  return rows;
}

String sceneCatalogChapterKey(String storyId, String chapterId) =>
    jsonEncode([storyId, chapterId]);

bool sceneCatalogStoryMatches(StorylineAsset story, String filter) =>
    switch (filter) {
      'all' => true,
      'main' => story.type == StorylineType.main,
      'side' => story.type == StorylineType.sideQuest,
      _ => filter == 'story:${story.id}',
    };

List<SceneCatalogRow> filterSceneCatalog(
  List<SceneCatalogRow> rows, {
  String query = '',
  String story = 'all',
  String chapter = 'all',
}) {
  final needle = query.trim().toLowerCase();
  return rows.where((row) {
    if (needle.isNotEmpty && !row.title.toLowerCase().contains(needle)) {
      return false;
    }
    if (story == 'outside') return chapter == 'all' && row.memberships.isEmpty;
    final scoped = row.memberships.where(
      (member) => sceneCatalogStoryMatches(member.story, story),
    );
    return (story == 'all' || scoped.isNotEmpty) &&
        (chapter == 'all' ||
            (chapter == 'none'
                ? scoped.isEmpty
                : scoped.any(
                    (member) =>
                        sceneCatalogChapterKey(
                          member.story.id,
                          member.chapter.id,
                        ) ==
                        chapter,
                  )));
  }).toList();
}
