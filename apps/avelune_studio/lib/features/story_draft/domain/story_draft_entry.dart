import 'package:map_core/map_core_domain.dart';

import 'story_dialogue_source.dart';

enum StoryDraftKind<T extends Object> {
  event<NarrativeEventRecord>(),
  scene<SceneAsset>(),
  dialogue<StoryDialogueSource>(),
  fact<NarrativeFactDefinition>(),
  story<StorylineAsset>(),
  worldRule<WorldRuleDefinition>();

  const StoryDraftKind();

  static StoryDraftKind<Object> of(Object value) => switch (value) {
    NarrativeEventRecord() => event,
    SceneAsset() => scene,
    StoryDialogueSource() => dialogue,
    NarrativeFactDefinition() => fact,
    StorylineAsset() => story,
    WorldRuleDefinition() => worldRule,
    _ => throw ArgumentError.value(value, 'value', 'is not story data'),
  };

  bool holds(Object? value) => value == null || value is T;

  String idOf(Object value) {
    if (value is! T) {
      throw ArgumentError.value(value, 'value', 'is not a $name');
    }
    return switch (value) {
      NarrativeEventRecord(:final id) => id,
      SceneAsset(:final id) => id,
      StoryDialogueSource(:final id) => id,
      NarrativeFactDefinition(:final id) => id,
      StorylineAsset(:final id) => id,
      WorldRuleDefinition(:final id) => id,
      _ => throw ArgumentError.value(value, 'value', 'is not a $name'),
    };
  }

  StoryDraftEntry<T> entry(String id, {Object? base, Object? current}) {
    if (!holds(base)) throw ArgumentError.value(base, 'base', 'is not a $name');
    if (!holds(current)) {
      throw ArgumentError.value(current, 'current', 'is not a $name');
    }
    return StoryDraftEntry<T>(
      kind: this,
      id: id,
      base: base as T?,
      current: current as T?,
    );
  }
}

typedef StoryDraftRef = ({StoryDraftKind<Object> kind, String id});

final class StoryDraftEntry<T extends Object> {
  const StoryDraftEntry({
    required this.kind,
    required this.id,
    this.base,
    this.current,
  });

  final StoryDraftKind<T> kind;
  final String id;
  final T? base;
  final T? current;

  StoryDraftRef get ref => (kind: kind, id: id);
  bool get touched => base != current;
  bool get creation => base == null && current != null;
  bool get deletion => base != null && current == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryDraftEntry &&
          other.kind == kind &&
          other.id == id &&
          other.base == base &&
          other.current == current;

  @override
  int get hashCode => Object.hash(kind, id, base, current);

  @override
  String toString() =>
      'StoryDraftEntry(${kind.name} $id: ${base == null ? 'absent' : 'saved'}'
      ' -> ${current == null ? 'absent' : 'draft'})';
}
