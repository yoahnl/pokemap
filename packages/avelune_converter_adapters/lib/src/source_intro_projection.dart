part of 'source_event_projection.dart';

extension _SourceIntroProjection on _ProjectionBuilder {
  SourceIntroProgram? _introProgram(SourceEventDefinition event) {
    final program = textVariablePrograms.values.where((program) =>
        program.sourceMapId == event.sourceMapId &&
        program.sourceEventId == event.sourceEventId).singleOrNull;
    return program?.isBoundTo(source) == true ? program : null;
  }

  String _introFreshSourceId(SourceIntroProgram program) =>
      'source:${source.snapshot.logicalProjectNamespace.value}:'
          'nativeFreshEntry:${program.programHash.value}';

  NarrativeFactDefinition _introFreshFact(SourceIntroProgram program) =>
      _nativeFact(_introFreshSourceId(program));

  Set<String> _introFactIds(SourceIntroProgram program) => {
    _sourceControlAnalyzer.variableFactId(program.nameVariableId),
    _sourceControlAnalyzer.globalFactId(program.completedSwitchId),
    _introFreshSourceId(program),
  };

  bool _introMusicIsMissing(SourceIntroProgram program) {
    final key = sourcePathCollisionKey('Audio/BGM/${program.music.name}');
    return !source.snapshot.entries.any((entry) {
      final path = sourcePathCollisionKey(entry.relativePath);
      return path == key || path.startsWith('$key.') &&
          !path.substring(key.length + 1).contains('/');
    });
  }

  Set<String> _introGaps(SourceEventDefinition event) {
    final program = _introProgram(event)!;
    final entry = sourceFreshEntryProgram(source);
    if (entry == null || !entry.isBoundTo(source) ||
        entry.intro.programHash != program.programHash ||
        !_exclamationEventMatchesSource(event)) {
      return {'sourceIntroductionFreshEntryUnqualified'};
    }
    final map = maps[event.sourceMapId]!;
    final target = maps[program.targetMapId];
    if (map.version == ProjectVersion.v9 || map.spatialScene != null ||
        target == null || target.version == ProjectVersion.v9 ||
        target.spatialScene != null || program.targetX >= target.size.width ||
        program.targetY >= target.size.height) {
      return {'sourceIntroductionMapsUnavailable'};
    }
    final point = GridPos(x: program.targetX, y: program.targetY);
    final collision = target.layers.whereType<CollisionLayer>().toList();
    if (collision.isEmpty || collision.any((layer) =>
        layer.collisions.length != target.size.width * target.size.height ||
        layer.collisions[program.targetY * target.size.width + program.targetX]) ||
        target.entities.any((entity) => entity.blocksMovement &&
            resolveEntityCollisionCells(entity).contains(point))) {
      return {'sourceIntroductionArrivalBlocked'};
    }
    final audio = soundBindings['bgm:${program.music.name}'];
    if (audio == null ? !_introMusicIsMissing(program) :
        audio.name != program.music.name ||
        audio.kind != SourceEventAudioKind.music ||
        audio.sourceSnapshotHash != sourceSnapshotHash ||
        audio.policy != SourceEventSoundPolicy.sourceEngineGain) {
      return {'sourceIntroductionMusicBindingMissing'};
    }
    if ([...program.opening, program.confirmed, ...program.closing]
        .any((text) => _textFeedback(event, text.text) == null) ||
        _textFeedback(event, program.choicePrompt) == null ||
        _textFeedback(event, program.confirmationPrompt.replaceAll(
            '\\v[${program.nameVariableId}]', '{value}')) == null) {
      return {'sourceIntroductionTextUnsupported'};
    }
    return _sourceArrivalTileGaps(program.targetMapId,
        program.targetX, program.targetY);
  }

  void _prepareIntroFacts(SourceIntroProgram program) {
    final sourceId = _sourceControlAnalyzer.variableFactId(program.nameVariableId);
    factsById.putIfAbsent(sourceId, () => _nativeTextFact(sourceId));
    final fresh = _introFreshFact(program);
    factsById.putIfAbsent(_introFreshSourceId(program), () => fresh);
    final complete = _sourceControlAnalyzer.globalFactId(program.completedSwitchId);
    factsById.putIfAbsent(complete, () => _nativeFact(complete));
  }
}

extension _SourceIntroScene on _SceneBuilder {
  String _intro(SourceIntroProgram program, String end) {
    if (page.originalPageIndex != 0) return _block(page.body, end);
    final warp = SourceWarpNode(program.closing.last.span,
        targetSourceMapId: program.targetMapId, x: program.targetX,
        y: program.targetY, direction: 2, fade: true);
    final completedId = projection._sourceControlAnalyzer
        .globalFactId(program.completedSwitchId);
    final complete = _fact(completedId, true,
        _fact(projection._introFreshSourceId(program), false, end));
    final transfer = _node(SceneActionPayload.interactive(
        SceneInteractiveCommand.warp(
            destinationMapId: projection.maps[program.targetMapId]!.id,
            warpId: projection.arrival(event, warp),
            arrivalFacing: EntityFacing.south,
            presentation: SceneWarpPresentation(
                mode: SceneWarpPresentationMode.fade,
                fadeOutMs: 300, revealMs: 300))));
    _edge(transfer, 'completed', complete, SceneEdgeKind.actionCompleted);
    _edge(transfer, 'blocked', end, SceneEdgeKind.actionCompleted);
    var next = transfer;
    for (final text in [program.confirmed, ...program.closing].reversed) {
      next = _dialogue(text.span, text.text, null, next);
    }
    final confirm = projection._textFeedback(event,
        program.confirmationPrompt.replaceAll(
            '\\v[${program.nameVariableId}]', '{value}'))!;
    final input = _node(SceneActionPayload.interactive(
        SceneInteractiveCommand.inputTextToFact(
            factId: projection._sourceVariableFact(projection
                ._sourceControlAnalyzer.variableFactId(program.nameVariableId)).id,
            prompt: SceneInteractionPrompt(
                localizationKey: '$sceneId.name', fallbackText: program.customPrompt),
            confirmationPrompt: SceneInteractionPrompt(
                localizationKey: '$sceneId.confirm', fallbackText: confirm.plainText),
            constraints: SceneTextInputConstraints(
                minGraphemes: 1, maxGraphemes: 7),
            presetValues: program.presetValues,
            customChoiceLabel: program.customChoiceLabel,
            presetChoicePrompt: SceneInteractionPrompt(
                localizationKey: '$sceneId.presets',
                fallbackText: projection._textFeedback(event,
                    program.choicePrompt)!.plainText))));
    _edge(input, 'completed', next, SceneEdgeKind.actionCompleted);
    _edge(input, 'cancelled', end, SceneEdgeKind.actionCompleted);
    final music = projection.soundBindings['bgm:${program.music.name}'];
    final cinematicId = projection._key(event, 'intro_opening');
    final cinematic = CinematicAsset(
        id: cinematicId, title: 'Source introduction',
        mapId: projection.maps[event.sourceMapId]!.id,
        actorCompletionPolicy: CinematicActorCompletionPolicy.restoreInitial,
        timeline: CinematicTimeline(steps: [
          if (music != null)
            CinematicTimelineStep(id: 'music', kind: CinematicTimelineStepKind.music,
              assetRef: music.mediaId, durationMs: 100, metadata: {
                cinematicTimelineCommandVolumeMetadataKey:
                    '${music.gainForVolume(program.music.volume)}',
                cinematicTimelineCommandLoopMetadataKey: 'true',
              }),
          for (final text in program.opening)
            CinematicTimelineStep(id: 'text_${text.span.firstCommandIndex}',
                kind: CinematicTimelineStepKind.dialogueLine, durationMs: 100,
                dialogueText: projection._textFeedback(event, text.text)!.plainText),
        ]), metadata: {
          'converter.sourceProgram': program.programHash.value,
          'converter.presentation': 'nativeOpeningThenConfirmedNameAndDialogue',
          'converter.sourcePictureToneAndAudioTimingParity': 'false',
          'converter.sourceMusicStatus': music == null
              ? 'missingOptionalSourceAudioOmittedWithoutSubstitution' : 'imported',
        });
    projection.cinematics.add(cinematic);
    projection.mutations.add(projection._mutation('cinematic.upsert', cinematicId,
        [event.identity, event.sourceFileId], [cinematicId],
        {'cinematic': cinematic.toJson()}));
    final opening = _node(SceneCinematicPayload(cinematicId: cinematicId));
    _edge(opening, 'completed', input, SceneEdgeKind.cinematicCompleted);
    final hideDex = _node(SceneActionPayload.consequence(
        SceneConsequence.setPauseMenuEntryVisibility(actionId: ProjectPauseActionId.pokedex, visible: false)));
    _edge(hideDex, 'completed', opening, SceneEdgeKind.actionCompleted);
    return hideDex;
  }
}
