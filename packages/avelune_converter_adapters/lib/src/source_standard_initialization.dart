part of 'source_event_projection.dart';

SourceEventPageAnalysis? sourceStandardInitializationPage(
    SourceEventDefinition event) {
  if (event.pages.isEmpty) {
    return null;
  }
  final page = event.pages.last;
  final graphic = page.graphic;
  var guard = page.condition;
  while (guard.kind == SourceEventConditionKind.all &&
      guard.children.length == 1) {
    guard = guard.children.single;
  }
  if (page.triggerCode != 3 ||
      page.isQuarantined ||
      page.rawDataRef == null ||
      guard.kind != SourceEventConditionKind.tempSwitch ||
      guard.expectedValue ||
      !const {'A', 'B', 'C', 'D'}.contains(guard.tempSwitchLetter) ||
      graphic == null ||
      graphic.tileId != 0 ||
      graphic.characterName.isNotEmpty ||
      graphic.hue != 0 ||
      graphic.opacity != 255 ||
      graphic.blendType != 0 ||
      graphic.moveType != 0 ||
      graphic.stepAnime ||
      graphic.alwaysOnTop ||
      graphic.directionFix ||
      graphic.pattern != 0 ||
      !const {2, 4, 6, 8}.contains(graphic.direction)) {
    return null;
  }
  final nodes =
      page.body.nodes.where((node) => node is! SourceAnnotationNode).toList();
  if (nodes.isEmpty || nodes.last is! SourceTempSwitchNode) {
    return null;
  }
  final terminal = nodes.last as SourceTempSwitchNode;
  if (terminal.letter != guard.tempSwitchLetter) {
    return null;
  }
  var visits = 0;
  bool charge(int depth) => ++visits <= 256 && depth <= 8;
  bool operand(SourceIntegerOperand value) =>
      value.isQualified &&
      const {
        SourceIntegerOperandKind.literal,
        SourceIntegerOperandKind.variable
      }.contains(value.kind);
  bool ownSelf(String? id) =>
      id != null &&
      RegExp(':map:${event.sourceMapId}:event:${event.sourceEventId}:self:[A-D]\$')
          .hasMatch(id);
  bool condition(SourceEventCondition value, int depth) {
    if (!charge(depth) || !value.isQualified || value.sourceDirection != null) {
      return false;
    }
    return switch (value.kind) {
      SourceEventConditionKind.always ||
      SourceEventConditionKind.globalSwitch ||
      SourceEventConditionKind.variableAtLeast ||
      SourceEventConditionKind.variableComparison ||
      SourceEventConditionKind.tempSwitch =>
        true,
      SourceEventConditionKind.selfSwitch => ownSelf(value.factId),
      SourceEventConditionKind.all =>
        value.children.every((child) => condition(child, depth + 1)),
      SourceEventConditionKind.integerComparison =>
        operand(value.integerLeft!) && operand(value.integerRight!),
      _ => false,
    };
  }

  bool targets(int first, int last, List<String> ids) =>
      first > 0 &&
      last >= first &&
      last - first < 64 &&
      ids.length == last - first + 1;
  bool block(SourceEventBlock value, int depth) {
    if (value.isQuarantined || depth > 8) {
      return false;
    }
    for (final node in value.nodes) {
      if (!charge(depth)) {
        return false;
      }
      final accepted = switch (node) {
        SourceAnnotationNode() => true,
        SourceVariableSetNode() =>
          targets(node.firstId, node.lastId, node.factIds),
        SourceVariableAdjustNode() =>
          targets(node.firstId, node.lastId, node.factIds),
        SourceVariableCalculationNode() =>
          targets(node.firstId, node.lastId, node.factIds) &&
              node.operation >= 0 &&
              node.operation <= 5 &&
              operand(node.operand) &&
              node.profileHash == terminal.profileHash,
        SourceSwitchNode() => targets(node.firstId, node.lastId, node.factIds),
        SourceSelfSwitchNode() => ownSelf(node.factId),
        SourceTempSwitchNode() => node.profileHash == terminal.profileHash &&
            const {'A', 'B', 'C', 'D'}.contains(node.letter) &&
            (node.letter != terminal.letter || identical(node, terminal)),
        SourceConditionalNode() => condition(node.condition, depth + 1) &&
            block(node.whenTrue, depth + 1) &&
            block(node.whenFalse, depth + 1),
        _ => false,
      };
      if (!accepted) {
        return false;
      }
    }
    return true;
  }

  return block(page.body, 0) ? page : null;
}

extension _StandardInitializationProjection on _ProjectionBuilder {
  SourceEventPageAnalysis? _standardInitializationPage(
      SourceEventDefinition event) {
    final page = sourceStandardInitializationPage(event);
    final map = maps[event.sourceMapId];
    if (page == null ||
        !analysis.profile.isQualified ||
        retentionPolicy == null ||
        map == null ||
        map.version == ProjectVersion.v9 ||
        map.spatialScene != null ||
        event.x < 0 ||
        event.y < 0 ||
        event.x >= map.size.width ||
        event.y >= map.size.height ||
        _isSourceTransition(event) ||
        _introProgram(event) != null ||
        starterChoiceBindings.containsKey(event.identity) ||
        !_exclamationEventMatchesSource(event)) {
      return null;
    }
    final expected = _authoritativeSourceAnalysis.eventAt(
        event.sourceMapId, event.sourceEventId);
    if (expected?.identity != event.identity ||
        expected?.sourceFileId != event.sourceFileId ||
        page.rawDataRef!.fileId != event.sourceFileId ||
        page.rawDataRef!.contentHash !=
            source.sourceFiles[event.sourceFileId]?.contentHash) {
      return null;
    }
    final terminal =
        page.body.nodes.whereType<SourceTempSwitchNode>().lastOrNull;
    if (terminal?.profileHash != analysis.profile.canonicalHash) {
      return null;
    }
    final gaps = <String>{};
    _conditionGaps(event, page.condition, gaps);
    _blockGaps(event, page.body, gaps);
    return gaps.isEmpty ? page : null;
  }

  void _projectStandardInitialization(
      SourceEventDefinition event, SourceEventPageAnalysis page) {
    final ids = <String>{};
    _collectFacts(page.condition, ids);
    _blockFacts(page.body, ids);
    for (final id in ids) {
      factsById.putIfAbsent(
          id,
          () => id.startsWith(
                  'source:${source.snapshot.logicalProjectNamespace.value}:variable:')
              ? _sourceVariableFact(id)
              : _nativeFact(id));
    }
    final map = maps[event.sourceMapId]!;
    final anchor = MapEntity(
        id: _key(event, 'anchor'),
        name: _name(event),
        kind: MapEntityKind.custom,
        pos: GridPos(x: event.x, y: event.y),
        size: const GridSize(width: 1, height: 1),
        blocksMovement: false,
        properties: {
          'sourceEventIdentity': event.identity.value,
          'sourceEventAnchorX': '${event.x}',
          'sourceEventAnchorY': '${event.y}'
        });
    maps[event.sourceMapId] = map.copyWith(entities: [...map.entities, anchor]);
    mutations.add(_mutation(
        'entity.upsert',
        anchor.id,
        [event.identity, event.sourceFileId],
        [map.id, anchor.id],
        {'mapId': map.id, 'entity': anchor.toJson()}));
    final scene =
        _SceneBuilder(this, event, page).build(standardInitialization: true);
    scenes.add(scene);
    mutations.add(_mutation(
        'scene.upsert',
        scene.id,
        [event.identity, event.sourceFileId],
        [scene.id],
        {'scene': scene.toJson()}));
    final guard = _pageGuard(event, page.condition).expression!;
    records.add(NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
            id: _eventId(event, 'page_${page.originalPageIndex}'),
            name: '${_name(event)} / ${page.originalPageIndex + 1}',
            source: NarrativeEventSourceRef.entityAutorun(map.id, anchor.id),
            conditions: guard.leaves,
            conditionExpression: guard,
            sceneId: scene.id,
            reusePolicy: NarrativeEventReusePolicy.reusable,
            priority: page.originalPageIndex,
            order: event.sourceEventId),
        enabled: true,
        activeInLegacyMode: false));
  }
}
