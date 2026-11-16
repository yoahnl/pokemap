import 'package:map_core/map_core_domain.dart';

import '../../events/domain/event_record_view.dart';
import '../../game_memory/domain/narrative_index_port.dart';
import '../../story_draft/application/story_draft.dart';
import '../../story_draft/domain/story_draft_entry.dart';
import '../domain/scene_document.dart';

final class SceneCatalogDocuments {
  SceneCatalogDocuments(this.port, this.draft, {this.revision});

  final NarrativeIndexPort port;
  final StoryDraft draft;
  final Object? Function()? revision;
  final _revisions = <String, Object?>{};
  final _cache = <String, SceneDocument>{};
  final _pending = <String, (int, Future<SceneDocument>)>{};
  final _epochs = <String, int>{};
  Map<String, SceneAsset?> _scenes = {};
  Map<String, NarrativeEventRecord?> _events = {};
  int _sceneVersion = -1;
  int _eventVersion = -1;
  bool _disposed = false;

  int versionOf(String id) {
    sync();
    _checkRevision(id);
    return _epochs[id] ?? 0;
  }

  void _checkRevision(String id) {
    if (_revisions.containsKey(id) &&
        !identical(_revisions[id], revision?.call())) {
      invalidate(id);
    }
  }

  void sync() {
    final version = draft.versionOf(StoryDraftKind.scene);
    if (_sceneVersion != version) {
      _sceneVersion = version;
      final next = {
        for (final id in draft.touched(StoryDraftKind.scene))
          id: draft.entryOf(StoryDraftKind.scene, id)!.current,
      };
      for (final id in {..._scenes.keys, ...next.keys}) {
        if (!identical(_scenes[id], next[id]) ||
            _scenes.containsKey(id) != next.containsKey(id)) {
          invalidate(id);
        }
      }
      _scenes = next;
    }
    final events = draft.versionOf(StoryDraftKind.event);
    if (_eventVersion != events) {
      _eventVersion = events;
      final next = {
        for (final id in draft.touched(StoryDraftKind.event))
          id: draft.entryOf(StoryDraftKind.event, id)!.current,
      };
      for (final id in {..._events.keys, ...next.keys}) {
        if (identical(_events[id], next[id]) &&
            _events.containsKey(id) == next.containsKey(id)) {
          continue;
        }
        final before = _events[id] ?? draft.baseOf(StoryDraftKind.event, id);
        for (final sceneId in {before?.sceneId, next[id]?.sceneId}.nonNulls) {
          invalidate(sceneId);
        }
      }
      _events = next;
    }
  }

  void invalidate(String id) {
    _epochs[id] = (_epochs[id] ?? 0) + 1;
    _cache.remove(id);
    _pending.remove(id);
    _revisions.remove(id);
  }

  SceneDocument? cached(String id) {
    sync();
    _checkRevision(id);
    final document = _cache.remove(id);
    if (document == null) return null;
    _cache[id] = document;
    return _effective(document);
  }

  Future<SceneDocument> read(String id) {
    sync();
    if (_disposed) return Future.error(StateError('Catalogue fermé'));
    if (cached(id) case final document?) return Future.value(document);
    if (_pending[id] case final pending?) return pending.$2;
    final epoch = _epochs[id] ?? 0;
    final sourceRevision = revision?.call();
    _revisions[id] = sourceRevision;
    final request = () async {
      try {
        final entry = draft.entryOf(StoryDraftKind.scene, id);
        if (entry != null && entry.current == null) {
          throw StateError('Scène retirée');
        }
        final document = entry?.creation == true
            ? SceneDocument(
                scene: entry!.current!,
                dialogues: const [],
                missingDialogueIds: const [],
                events: const [],
                maps: const {},
                mapReads: 0,
              )
            : await port.sceneDocument(id);
        if (_disposed ||
            epoch != (_epochs[id] ?? 0) ||
            !identical(sourceRevision, revision?.call())) {
          throw StateError('Chargement remplacé');
        }
        _cache[id] = document;
        while (_cache.length > 8) {
          _cache.remove(_cache.keys.first);
        }
        return _effective(document);
      } finally {
        if (_pending[id]?.$1 == epoch) _pending.remove(id);
      }
    }();
    _pending[id] = (epoch, request);
    return request;
  }

  SceneDocument _effective(SceneDocument document) {
    final scene = draft
        .entryOf(StoryDraftKind.scene, document.scene.id)
        ?.current;
    if (scene == null || identical(scene, document.scene)) return document;
    return SceneDocument(
      scene: scene,
      dialogues: document.dialogues,
      missingDialogueIds: document.missingDialogueIds,
      events: document.events,
      maps: document.maps,
      mapReads: document.mapReads,
    );
  }

  void dispose() {
    _disposed = true;
    _cache.clear();
    _pending.clear();
    _revisions.clear();
  }
}
