import 'package:map_core/map_core_domain.dart';

import '../../game_memory/application/game_memory_resource.dart';
import '../../game_memory/domain/narrative_index_port.dart';
import '../../story_draft/application/story_draft.dart';
import '../../story_draft/domain/story_draft_entry.dart';
import '../../story_draft/domain/story_dialogue_source.dart';
import '../domain/dialogue_catalog_port.dart';
import 'dialogue_catalog_preview.dart';
import 'dialogue_catalog_rows.dart';
import 'dialogue_draft_host.dart';

final class DialogueCatalogController {
  DialogueCatalogController({
    required this.index,
    required this.port,
    required this.draft,
    required this.revision,
    required this.changed,
    this.editing,
  });

  final NarrativeIndexPort index;
  final DialogueCatalogPort? port;
  final StoryDraft draft;
  final Object? Function() revision;
  final void Function() changed;
  final DialogueDraftHost? editing;
  final titles = GameMemoryResource<List<NarrativeTitle>>();
  final languages = GameMemoryResource<DialogueCatalogLanguages>();
  final _documents = <String, GameMemoryResource<DialogueCatalogDocument>>{};
  final _documentStamps = <String, Object>{};
  final _projectedDocuments = <String, DialogueCatalogDocument>{};
  Object? _rowStamp;
  List<DialogueCatalogRow> _rows = [];
  final _previews =
      <
        (StoryDialogueSource, String, DialogueCatalogLanguages),
        DialogueCatalogPreview
      >{};
  String query = '';
  String language = 'source';
  String? selectedId;
  bool viewing = false;
  bool stale = false;
  Object? _revision;
  bool _disposed = false;
  Future<void>? _opening;

  void _changed() {
    final configured = languages.value?.locales ?? const <String>[];
    if (languages.ready &&
        configured.isNotEmpty &&
        language != 'source' &&
        !configured.contains(language)) {
      language = 'source';
    }
    if (!_disposed) changed();
  }

  Future<void> open({bool force = false}) async {
    while (_opening != null) {
      await _opening;
    }
    if (_disposed) return;
    final pending = _open(force);
    _opening = pending;
    try {
      await pending;
    } finally {
      if (identical(_opening, pending)) _opening = null;
    }
  }

  Future<void> _open(bool force) async {
    final currentRevision = revision();
    force = force || (titles.ready && !identical(_revision, currentRevision));
    if (force) _documents.clear();
    _revision = currentRevision;
    stale = false;
    await Future.wait([
      titles.load(
        () => index.titles(NarrativeTitleKind.dialogues),
        _changed,
        force: force,
      ),
      languages.load(
        () async => await port?.languages() ?? const DialogueCatalogLanguages(),
        _changed,
        force: force,
      ),
    ]);
  }

  void sync() {
    if (!stale && titles.ready && !identical(_revision, revision())) {
      stale = true;
      _changed();
    }
  }

  List<DialogueCatalogRow> get rows {
    final stamp = (titles.value, draft.versionOf(StoryDraftKind.dialogue));
    if (_rowStamp != stamp) {
      _rowStamp = stamp;
      _rows = dialogueCatalogRows(titles.value ?? const [], draft);
    }
    return _rows;
  }

  List<DialogueCatalogRow> get visibleRows {
    final needle = query.trim().toLowerCase();
    return rows
        .where((row) => row.title.toLowerCase().contains(needle))
        .toList();
  }

  List<String> get locales {
    final configured = languages.value?.locales ?? const <String>[];
    if (configured.isNotEmpty) return configured.toSet().toList()..sort();
    return {
      for (final resource in _documents.values)
        if (resource.value?.dialogue.entry.localization
            case final localization?) ...[
          localization.sourceLocale,
          for (final unit in localization.units) ...unit.translations.keys,
        ],
    }.toList()..sort();
  }

  void filter(String value) {
    query = value;
    _changed();
  }

  void previewIn(String value) {
    language = value;
    _changed();
  }

  void select(String id) {
    selectedId = id;
    viewing = true;
    _changed();
  }

  void back() {
    viewing = false;
    _changed();
  }

  GameMemoryResource<DialogueCatalogDocument> resource(String id) =>
      _documents.putIfAbsent(id, GameMemoryResource.new);

  Future<void> load(String id, {bool force = false}) async {
    if (_disposed) return;
    final resource = this.resource(id);
    await resource.load(
      () async {
        final current = draft.entryOf(StoryDraftKind.dialogue, id);
        if ((current?.base, current?.current) case (null, final dialogue?)) {
          return DialogueCatalogDocument(
            dialogue: dialogue,
            sceneIds: const [],
            notCovered: const ['draft'],
          );
        }
        final reader = port;
        if (reader == null) throw const NarrativeIndexUnavailable();
        final saved = await reader.document(id);
        if (editing case final host?) {
          host.rememberDialogue(saved.dialogue);
          draft.load(StoryDraftKind.dialogue, id, saved.dialogue);
        }
        return saved;
      },
      () {
        if (identical(_documents[id], resource)) _changed();
      },
      force: force,
    );
  }

  DialogueCatalogDocument? document(String id) {
    final saved = resource(id).value;
    final edit = draft.entryOf(StoryDraftKind.dialogue, id);
    if (edit != null && edit.current == null) return null;
    final known = editing?.savedDialogue(id);
    if (saved?.notCovered.contains('draft') == true &&
        edit == null &&
        known == null) {
      return null;
    }
    final current = edit?.current ?? known ?? saved?.dialogue;
    if (current == null) return null;
    final stamp = (saved, current, draft.versionOf(StoryDraftKind.scene));
    if (_documentStamps[id] == stamp) return _projectedDocuments[id];
    final scenes = {...?saved?.sceneIds};
    for (final sceneId in draft.touched(StoryDraftKind.scene)) {
      scenes.remove(sceneId);
      final scene = draft.entryOf(StoryDraftKind.scene, sceneId)?.current;
      if (scene?.graph.nodes.any(
            (node) =>
                node.payload is SceneYarnDialoguePayload &&
                (node.payload as SceneYarnDialoguePayload).dialogueId == id,
          ) ??
          false) {
        scenes.add(sceneId);
      }
    }
    final document = DialogueCatalogDocument(
      dialogue: current,
      sceneIds: scenes.toList()..sort(),
      notCovered: saved?.notCovered ?? const ['draft'],
    );
    _documentStamps[id] = stamp;
    return _projectedDocuments[id] = document;
  }

  DialogueCatalogPreview? preview(String id, {String? locale}) {
    final document = this.document(id);
    if (document == null) return null;
    final profile = languages.value ?? const DialogueCatalogLanguages();
    final key = (document.dialogue, locale ?? language, profile);
    if (_previews.length >= 128 && !_previews.containsKey(key)) {
      _previews.remove(_previews.keys.first);
    }
    return _previews.putIfAbsent(
      key,
      () => previewDialogue(document.dialogue, key.$2, profile),
    );
  }

  void dispose() => _disposed = true;
}
