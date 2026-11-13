import 'package:map_core/map_core_domain.dart';

import '../domain/story_draft_entry.dart';
import '../domain/story_draft_saved.dart';

final class StoryDraftManifestReader {
  final _indexes = <StoryDraftKind<Object>, (Object?, Map<String, Object>)>{};

  StoryDraftSaved of(ProjectManifest project, {StoryDraftSaved? beyond}) =>
      _ManifestSaved(this, project, beyond);

  Map<String, Object> _index(
    StoryDraftKind<Object> kind,
    ProjectManifest project,
  ) {
    final Object? source = kind == StoryDraftKind.event
        ? project.eventRegistry
        : project;
    final cached = _indexes[kind];
    if (cached != null && identical(cached.$1, source)) return cached.$2;
    final Iterable<Object> values = switch (kind) {
      StoryDraftKind.event =>
        project.eventRegistry?.records ?? const <NarrativeEventRecord>[],
      StoryDraftKind.scene => project.scenes,
      StoryDraftKind.fact => project.facts,
      StoryDraftKind.story => project.storylines,
      StoryDraftKind.worldRule => project.worldRules,
      StoryDraftKind.dialogue => const <Object>[],
    };
    final index = {for (final value in values) kind.idOf(value): value};
    _indexes[kind] = (source, index);
    return index;
  }
}

final class _ManifestSaved implements StoryDraftSaved {
  const _ManifestSaved(this._reader, this._project, this._beyond);

  final StoryDraftManifestReader _reader;
  final ProjectManifest _project;
  final StoryDraftSaved? _beyond;

  @override
  Object? read(StoryDraftKind<Object> kind, String id) =>
      (kind == StoryDraftKind.dialogue
          ? null
          : _reader._index(kind, _project)[id]) ??
      _beyond?.read(kind, id);
}
