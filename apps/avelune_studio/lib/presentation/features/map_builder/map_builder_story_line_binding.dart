part of 'map_builder_story_binding.dart';

enum MapStoryLineState { empty, loading, line, shared, unavailable, scene }

final class MapStoryLine {
  MapStoryLine(
    this.state, {
    this.line,
    List<String> sharedWith = const [],
    this.problem,
  }) : sharedWith = List.unmodifiable(sharedWith);

  final MapStoryLineState state;
  final BehaviourLine? line;
  final List<String> sharedWith;
  final String? problem;

  String get text => line?.lines.join('\n') ?? '';
}

final class _StoryLines {
  final loads = <String, String?>{};
  final ids = BehaviourLineIdGenerator();
  (List<Object?>, MapStoryLine)? reading;
  (List<NarrativeFactDefinition>, List<NarrativeFactDefinition>)? facts;
}

extension MapStoryLineEditing on MapBuilderStoryBinding {
  SceneAsset? sceneOf(String sceneId) {
    final project = maps.project;
    if (project == null || !ready) return null;
    return behaviours.draft.effective(
      StoryDraftKind.scene,
      sceneId,
      behaviours.saved(project),
    );
  }

  bool editScene(String sceneId, SceneAsset next) =>
      next.id == sceneId &&
      _operate(
        const [],
        const [],
        stage: (draft) {
          _load(draft, StoryDraftKind.scene, sceneId);
          draft.put(StoryDraftKind.scene, next);
        },
      );

  void _load<T extends Object>(
    StoryDraft draft,
    StoryDraftKind<T> kind,
    String id,
  ) => draft.load(
    kind,
    id,
    behaviours.saved(maps.project!).read(kind, id) as T?,
  );

  MapStoryLine lineOf(NarrativeEventRecord record) {
    final sceneId = record.sceneId;
    if (sceneId == null) return MapStoryLine(MapStoryLineState.empty);
    final project = maps.project;
    final scene = sceneOf(sceneId);
    final dialogueId = scene == null ? null : behaviourLineDialogueId(scene);
    if (project == null || scene == null || dialogueId == null) {
      return MapStoryLine(MapStoryLineState.scene);
    }
    final dialogue = _dialogueOf(dialogueId);
    if (dialogue == null) {
      if (loadDialogue == null) return MapStoryLine(MapStoryLineState.scene);
      if (_lines.loads[dialogueId] case final failure?) {
        return MapStoryLine(MapStoryLineState.unavailable, problem: failure);
      }
      _fetch(dialogueId);
      return MapStoryLine(MapStoryLineState.loading);
    }
    final staged = behaviours.project(project);
    final records =
        behaviours.registry(project)?.records ?? const <NarrativeEventRecord>[];
    final key = [scene, dialogue, records, staged.scenes];
    final cached = _lines.reading;
    if (cached != null &&
        Iterable<int>.generate(key.length)
            .every((index) => identical(cached.$1[index], key[index]))) {
      return cached.$2;
    }
    final reading = readBehaviourLine(
      scene: scene,
      behaviours: records,
      dialogue: NarrativeDialogueSource(
        entry: dialogue.entry,
        source: dialogue.source,
        revision: dialogue.revision,
      ),
    );
    final MapStoryLine line;
    if (reading is BehaviourLine) {
      final sharing = behaviourDialogueSharing(
        sceneId: sceneId,
        dialogueId: dialogueId,
        scenes: staged.scenes,
      );
      final names = {for (final scene in staged.scenes) scene.id: scene.name};
      line = MapStoryLine(
        sharing.shared ? MapStoryLineState.shared : MapStoryLineState.line,
        line: reading,
        sharedWith: [for (final id in sharing.otherSceneIds) names[id] ?? id],
      );
    } else {
      line = MapStoryLine(MapStoryLineState.scene);
    }
    _lines.reading = (key, line);
    return line;
  }

  bool writeLine(
    MapStoryElement element,
    NarrativeEventRecord record,
    String text,
  ) {
    final lines = [
      for (final line in text.split('\n'))
        if (line.trim().isNotEmpty) line.trimRight(),
    ];
    final view = lineOf(record);
    switch (view.state) {
      case MapStoryLineState.empty:
        return lines.isEmpty || _createLine(element, record, lines);
      case MapStoryLineState.line:
        final line = view.line!;
        if (listEquals(lines, line.lines)) return true;
        return switch (rewriteBehaviourLine(
          line,
          lines: lines,
          speakerId: line.speakerId,
        )) {
          BehaviourLineRefused(:final reason) => _refuseLine(reason),
          BehaviourLineAccepted(:final value) => _operate(
            const [],
            const [],
            stage: (draft) {
              _load(draft, StoryDraftKind.dialogue, line.dialogueId);
              draft.put(
                StoryDraftKind.dialogue,
                StoryDialogueSource(
                  entry: value.entry,
                  source: value.source,
                  revision: line.dialogue.revision,
                ),
              );
            },
          ),
        };
      case MapStoryLineState.loading ||
          MapStoryLineState.shared ||
          MapStoryLineState.unavailable ||
          MapStoryLineState.scene:
        return false;
    }
  }

  bool detachLine(NarrativeEventRecord record) {
    final view = lineOf(record);
    final line = view.line;
    final scene = line == null ? null : sceneOf(line.sceneId);
    if (view.state != MapStoryLineState.shared ||
        line == null ||
        scene == null) {
      return false;
    }
    final detached = detachBehaviourLine(
      line: line,
      scene: scene,
      ids: _lineIds(),
    );
    return _operate(
      const [],
      const [],
      stage: (draft) {
        final dialogue = detached.line.dialogue;
        draft.load(StoryDraftKind.dialogue, dialogue.entry.id, null);
        draft.put(
          StoryDraftKind.dialogue,
          StoryDialogueSource(entry: dialogue.entry, source: dialogue.source),
        );
        _load(draft, StoryDraftKind.scene, scene.id);
        draft.put(StoryDraftKind.scene, detached.scene);
      },
    );
  }

  bool _createLine(
    MapStoryElement element,
    NarrativeEventRecord record,
    List<String> lines,
  ) {
    final ids = _lineIds();
    return switch (createBehaviourLine(
      ids: ids,
      name: record.name,
      lines: lines,
      speakerId: entityOf(element)?.npc?.characterId,
    )) {
      BehaviourLineRefused(:final reason) => _refuseLine(reason),
      BehaviourLineAccepted(value: final created) => _operate(
        [record],
        [
          (c) => setNarrativeEventScene(
            context: c,
            expectedRevision: c.revision,
            eventId: record.id,
            sceneId: ids.sceneId,
          ),
        ],
        stage: (draft) {
          draft.load(StoryDraftKind.dialogue, ids.dialogueId, null);
          draft.put(
            StoryDraftKind.dialogue,
            StoryDialogueSource(
              entry: created.dialogue.entry,
              source: created.dialogue.source,
            ),
          );
          draft.load(StoryDraftKind.scene, ids.sceneId, null);
          draft.put(StoryDraftKind.scene, created.scene);
        },
      ),
    };
  }

  BehaviourLineIds _lineIds() {
    final staged = behaviours.project(maps.project!);
    return _lines.ids.generate(
      sceneIds: {for (final scene in staged.scenes) scene.id},
      dialogueIds: {for (final dialogue in staged.dialogues) dialogue.id},
      dialoguePaths: {
        for (final dialogue in staged.dialogues) dialogue.relativePath,
      },
    );
  }

  bool _refuseLine(BehaviourLineRefusal reason) {
    attempts++;
    error = '${MapBuilderStoryBinding.lineRefused}${reason.name}';
    changed();
    return false;
  }

  StoryDialogueSource? _dialogueOf(String id) =>
      behaviours.draft.isTouched(StoryDraftKind.dialogue, id)
      ? behaviours.draft.currentOf(StoryDraftKind.dialogue, id)
      : behaviours.dialogues[id];

  void _fetch(String id) {
    final load = loadDialogue;
    if (load == null || _lines.loads.containsKey(id)) return;
    _lines.loads[id] = null;
    unawaited(
      load(id).then(
        (dialogue) {
          behaviours.dialogues.remember(dialogue);
          _lines.loads.remove(id);
          changed();
        },
        onError: (Object failure) {
          _lines.loads[id] = '$failure';
          changed();
        },
      ),
    );
  }
}
