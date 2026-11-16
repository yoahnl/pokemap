import 'dart:convert';

import 'package:map_core/map_core_domain.dart';

import '../domain/story_dialogue_source.dart';
import '../domain/story_draft_entry.dart';
import 'story_draft.dart';

String canonicalDraftFactId(String label, Iterable<String> taken) =>
    addNarrativeFact(
      ProjectManifest(
        name: 'facts',
        maps: const [],
        tilesets: const [],
        facts: [
          for (final id in taken.toSet())
            NarrativeFactDefinition(id: id, label: id),
        ],
      ),
      label: label,
    ).createdFact.id;

String? followDraftFactName(
  StoryDraft draft,
  String id, {
  required Iterable<String> taken,
}) {
  final entry = draft.entryOf(StoryDraftKind.fact, id);
  final fact = entry?.current;
  if (entry == null || !entry.creation || fact == null) return null;
  final canonical = canonicalDraftFactId(
    fact.label,
    {...taken, ...draft.touched(StoryDraftKind.fact)}..remove(id),
  );
  if (canonical == id) return null;
  draft.group(() {
    draft.followIdentity(StoryDraftKind.fact, id, canonical);
    for (final kind in StoryDraftKind.values) {
      if (kind == StoryDraftKind.fact) continue;
      for (final touched in draft.touched(kind).toList()) {
        final value = draft.currentOf(kind, touched);
        final rewritten = value == null
            ? null
            : _DraftFactReference(id, canonical).rewrite(value);
        if (rewritten != null) draft.put(kind, rewritten);
      }
    }
    draft
      ..remove(StoryDraftKind.fact, id)
      ..load(StoryDraftKind.fact, canonical, null)
      ..put(
        StoryDraftKind.fact,
        NarrativeFactDefinition(
          id: canonical,
          label: fact.label,
          description: fact.description,
          category: fact.category,
          initialValue: fact.initialValue,
          tags: fact.tags,
          legacyFlagName: fact.legacyFlagName,
        ),
      );
  });
  return canonical;
}

final class _DraftFactReference {
  _DraftFactReference(this.from, this.to)
    : _placeholder = RegExp(
        r'\{\{\s*fact\.' + RegExp.escape(from) + r'\s*\}\}',
      );

  final String from;
  final String to;
  final RegExp _placeholder;
  var _changed = false;

  Object? rewrite(Object value) {
    _changed = false;
    final rewritten = switch (value) {
      StoryDialogueSource() => StoryDialogueSource(
        entry: value.entry,
        source: _text(value.source),
        revision: value.revision,
      ),
      NarrativeEventRecord() => NarrativeEventRecord.fromJson(
        _json(value.toJson()),
      ),
      SceneAsset() => SceneAsset.fromJson(_object(value.toJson())),
      StorylineAsset() => StorylineAsset.fromJson(_object(value.toJson())),
      WorldRuleDefinition() => WorldRuleDefinition.fromJson(
        _object(value.toJson()),
      ),
      _ => value,
    };
    return _changed ? rewritten : null;
  }

  Map<String, dynamic> _object(Object? json) =>
      _json(json) as Map<String, dynamic>;

  Object? _json(Object? json) => _walk(jsonDecode(jsonEncode(json)));

  Object? _walk(Object? node) => switch (node) {
    final String text => _text(text),
    final List<dynamic> items => [for (final item in items) _walk(item)],
    final Map<String, dynamic> object => <String, dynamic>{
      for (final MapEntry(:key, :value) in object.entries)
        _text(key): _walk(value),
    },
    _ => node,
  };

  String _text(String text) {
    final next = text == from
        ? to
        : text.replaceAll(_placeholder, dialogueFactPlaceholder(to));
    if (next != text) _changed = true;
    return next;
  }
}
