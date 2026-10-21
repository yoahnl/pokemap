part of 'source_event_projection.dart';

extension _DirectionUnlockGiverProjection on _ProjectionBuilder {
  SourceDirectionUnlockGiverProgram? _directionUnlockGiver(
          SourceEventDefinition event) =>
      _directionUnlockGivers.putIfAbsent(event, () {
        final map = source.maps
            .where((m) => m.map.sourceMapId == event.sourceMapId)
            .singleOrNull;
        final raw = map?.map.events
            .where((e) => e.sourceEventId == event.sourceEventId)
            .singleOrNull;
        if (raw == null ||
            event.isQuarantined ||
            event.pages.length != 2 ||
            event.pages.first.graphic?.directionFix != true ||
            event.pages.last.graphic?.directionFix != false ||
            maps[event.sourceMapId]?.spatialScene != null ||
            maps[event.sourceMapId]?.version == ProjectVersion.v9) {
          return null;
        }
        final program = SourceDirectionUnlockGiverProgram.read(
            source: source,
            profile: analysis.profile,
            sourceMapId: event.sourceMapId,
            event: raw);
        final expected = _authoritativeSourceAnalysis.eventAt(
            event.sourceMapId, event.sourceEventId);
        if (program == null ||
            expected == null ||
            expected.identity != event.identity ||
            expected.sourceFileId != event.sourceFileId ||
            expected.name != event.name ||
            expected.x != event.x ||
            expected.y != event.y ||
            canonicalJsonOf(expected.locator.toJson()) !=
                canonicalJsonOf(event.locator.toJson()) ||
            !_exclamationEventMatchesSource(event)) {
          return null;
        }
        if (_sourceContextEvents.any((other) =>
            other.sourceMapId == event.sourceMapId &&
            other.pages.any((page) =>
                const [3, 4].contains(page.triggerCode) &&
                !page.isEmpty &&
                !_passiveRelativeFacingContextPage(other, page) &&
                !_stationaryFacingIndependentArrival(other, page)))) {
          return null;
        }
        for (final (i, page) in event.pages.indexed) {
          final original = expected.pages[i];
          if (canonicalJsonOf(page.sourcePage.toJson()) !=
                  canonicalJsonOf(original.sourcePage.toJson()) ||
              canonicalJsonOf(page.rawDataRef?.toJson()) !=
                  canonicalJsonOf(original.rawDataRef?.toJson()) ||
              canonicalJsonOf(page.condition.toJson()) !=
                  canonicalJsonOf(original.condition.toJson())) {
            return null;
          }
        }
        return program;
      });

  String _directionReleaseKey(SourceDirectionUnlockGiverProgram program) =>
      'converter-direction-released-${program.programHash.value.substring(0, 24)}';

  bool _directionUnlockCharacterIsBound(SourceEventDefinition event) {
    final graphic = event.pages.first.graphic!;
    final binding = characterBindings[sourceEventCharacterBindingKey(
        characterName: graphic.characterName,
        pattern: graphic.pattern,
        direction: graphic.direction,
        fixedDirection: true)];
    final file = source.snapshot.entries
        .where((f) => f.fileId == binding?.sourceFileId)
        .singleOrNull;
    return binding != null &&
        file != null &&
        file.sha256 != null &&
        binding.fixedDirection &&
        binding.sourceSnapshotHash == source.snapshot.canonicalHash &&
        binding.sourceFileHash == file.sha256 &&
        binding.sourcePattern == graphic.pattern &&
        binding.sourceDirection == graphic.direction &&
        binding.characterId ==
            sourceFixedDirectionCharacterId(
                snapshot: source.snapshot,
                imageFile: file,
                pattern: graphic.pattern,
                direction: graphic.direction) &&
        file.relativePath ==
            resolveSourceCharacterPresentation(
                    snapshot: source.snapshot,
                    profile: source.interpretationProfile,
                    charsetName: graphic.characterName)
                ?.actualSourceFile
                .relativePath;
  }

  void _addDirectionUnlockVariants(SourceEventDefinition event,
      List<MapEntityPresentationVariant> variants) {
    final program = _directionUnlockGiver(event);
    if (program == null) return;
    final page = event.pages.first, graphic = page.graphic!;
    final fixed = characterBindings[sourceEventCharacterBindingKey(
        characterName: graphic.characterName,
        pattern: graphic.pattern,
        direction: graphic.direction,
        fixedDirection: true)];
    final original = variants.singleWhere((v) => v.id == 'page_0');
    if (fixed == null) {
      throw const NativeWriteException('events.direction_unlock.character',
          'Locked source pose requires an attested Character.');
    }
    variants.remove(original);
    for (final released in [false, true]) {
      variants.add(MapEntityPresentationVariant(
          id: released ? 'page_0_released' : 'page_0_locked',
          condition: NarrativeEventConditionExpression.all([
            original.condition,
            NarrativeEventConditionExpression.leaf(
                NarrativeEventCondition.mapEventInstanceBoolean(
                    mapId: maps[event.sourceMapId]!.id,
                    eventId: _key(event, 'anchor'),
                    key: _directionReleaseKey(program),
                    expectedValue: released))
          ]),
          characterId: released ? original.characterId : fixed.characterId,
          facing: original.facing,
          blocksMovement: original.blocksMovement,
          size: original.size,
          interactionMode: original.interactionMode,
          counterInteractionSides: original.counterInteractionSides));
    }
  }
}

extension _DirectionUnlockGiverScenes on _SceneBuilder {
  String _directionUnlockFace(EntityFacing facing, String next) {
    final pose = _node(SceneActionPayload.consequence(
        SceneConsequence.setNpcPose(
            mapId: projection.maps[event.sourceMapId]!.id,
            entityId: projection._key(event, 'anchor'),
            facing: facing)));
    _edge(pose, 'completed', next, SceneEdgeKind.actionCompleted);
    return pose;
  }
}
