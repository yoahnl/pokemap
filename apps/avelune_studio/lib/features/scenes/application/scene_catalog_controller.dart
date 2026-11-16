import 'dart:async';

import 'package:map_core/map_core_domain.dart';

import '../../game_behaviours/application/game_behaviour_source.dart';
import '../../game_memory/application/game_memory_resource.dart';
import '../../game_memory/domain/narrative_index_port.dart';
import '../../story_draft/application/story_draft.dart';
import '../../story_draft/domain/story_draft_entry.dart';
import '../../storyline/domain/storyline_read_port.dart';
import '../domain/scene_document.dart';
import 'scene_catalog_documents.dart';
import 'scene_catalog_memberships.dart';
import 'scene_catalog_rows.dart';

final class SceneCatalogController {
  SceneCatalogController({
    required this.port,
    required this.storylines,
    required this.draft,
    required this.source,
    required this.changed,
  }) : documents = SceneCatalogDocuments(
         port,
         draft,
         revision: () => source().revision,
       );

  final NarrativeIndexPort port;
  final StorylineReadPort? storylines;
  final StoryDraft draft;
  final GameBehaviourSource Function() source;
  final void Function() changed;
  final SceneCatalogDocuments documents;
  final titles = GameMemoryResource<List<NarrativeTitle>>();
  final stories = GameMemoryResource<List<StorylineAsset>>();
  GameMemoryResource<SceneDocument> preview = GameMemoryResource();
  String? selectedId;
  String query = '';
  String storyFilter = 'all';
  String chapterFilter = 'all';
  Object? _revision;
  Object? _rowStamp;
  Object? _membershipStamp;
  List<SceneCatalogRow> _rows = [];
  List<StorylineAsset> _stories = [];
  SceneCatalogMemberships _memberships = SceneCatalogMemberships(const []);
  bool _disposed = false;
  int _previewEpoch = 0;
  Object? _documentStamp;

  void _changed() {
    if (!_disposed) changed();
  }

  Future<void> open({bool force = false}) async {
    _revision = source().revision;
    await Future.wait([
      titles.load(
        () => port.titles(NarrativeTitleKind.scenes),
        _changed,
        force: force,
      ),
      stories.load(
        () async => await storylines?.storylines() ?? const [],
        _changed,
        force: force,
      ),
    ]);
    reconcile();
  }

  void sync() {
    if (_disposed) return;
    documents.sync();
    if (!identical(_revision, source().revision) &&
        titles.ready &&
        !titles.loading) {
      unawaited(open(force: true));
    }
    reconcile();
    final id = selected?.sceneId;
    final stamp = (id, id == null ? null : documents.versionOf(id));
    if (_documentStamp != stamp) {
      _documentStamp = stamp;
      _previewEpoch++;
      preview = GameMemoryResource();
      _changed();
    }
  }

  List<StorylineAsset> get storyValues {
    final stamp = (stories.value, draft.versionOf(StoryDraftKind.story));
    if (_membershipStamp != stamp) {
      _membershipStamp = stamp;
      final values = {
        for (final story in stories.value ?? const <StorylineAsset>[])
          story.id: story,
      };
      for (final id in draft.touched(StoryDraftKind.story)) {
        final story = draft.entryOf(StoryDraftKind.story, id)!.current;
        if (story == null) {
          values.remove(id);
        } else {
          values[id] = story;
        }
      }
      _stories = values.values.toList();
      _memberships = SceneCatalogMemberships(_stories);
    }
    return _stories;
  }

  List<SceneCatalogRow> get rows {
    storyValues;
    final stamp = (
      titles.value,
      _memberships,
      draft.versionOf(StoryDraftKind.scene),
    );
    if (_rowStamp != stamp) {
      _rowStamp = stamp;
      _rows = sceneCatalogRows(titles.value ?? const [], draft, _memberships);
    }
    return _rows;
  }

  List<SceneCatalogRow> get visibleRows => filterSceneCatalog(
    rows,
    query: query,
    story: storyFilter,
    chapter: chapterFilter,
  );
  SceneCatalogRow? get selected =>
      visibleRows.where((row) => row.id == selectedId).firstOrNull;

  void filter({String? query, String? story, String? chapter}) {
    this.query = query ?? this.query;
    if (story != null && storyFilter != story) chapterFilter = 'all';
    storyFilter = story ?? storyFilter;
    chapterFilter = chapter ?? chapterFilter;
    reconcile();
    _changed();
  }

  void reconcile() {
    final stories = storyValues;
    if (storyFilter.startsWith('story:') &&
        !stories.any((story) => storyFilter == 'story:${story.id}')) {
      storyFilter = 'all';
      chapterFilter = 'all';
    }
    if (chapterFilter != 'all' &&
        chapterFilter != 'none' &&
        !stories.any(
          (story) =>
              sceneCatalogStoryMatches(story, storyFilter) &&
              story.chapters.any(
                (chapter) =>
                    sceneCatalogChapterKey(story.id, chapter.id) ==
                    chapterFilter,
              ),
        )) {
      chapterFilter = 'all';
    }
    if (selectedId != null && selected == null) select(null);
  }

  void select(String? id) {
    if (selectedId == id) return;
    selectedId = id;
    final sceneId = selected?.sceneId;
    _documentStamp = (
      sceneId,
      sceneId == null ? null : documents.versionOf(sceneId),
    );
    _previewEpoch++;
    preview = GameMemoryResource();
    _changed();
  }

  Future<void> loadSelected({bool force = false}) async {
    if (_disposed) return;
    final row = selected;
    if (row == null || !row.openable) return;
    final resource = preview;
    final epoch = _previewEpoch;
    if (force) {
      documents.invalidate(row.sceneId!);
      _documentStamp = (row.sceneId, documents.versionOf(row.sceneId!));
    }
    await resource.load(() => documents.read(row.sceneId!), () {
      if (epoch == _previewEpoch && identical(resource, preview)) _changed();
    }, force: force);
  }

  Future<SceneDocument> readDocument(String id) => documents.read(id);

  void dispose() {
    _disposed = true;
    _previewEpoch++;
    documents.dispose();
  }
}
