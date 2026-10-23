part of 'source_event_projection.dart';

const _sourceCompositionEntries = <Map<String, Object?>>[
  {
    'kind': 'command',
    'source': [101, 401],
    'native': 'dialogue',
    'disposition': 'adaptation',
    'constraint': 'qualifiedTextControls'
  },
  {
    'kind': 'command',
    'source': [102, 402, 403, 404],
    'native': 'dialogueChoice',
    'disposition': 'native',
    'constraint': 'explicitCancellation'
  },
  {
    'kind': 'command',
    'source': [106],
    'native': 'wait',
    'disposition': 'adaptation',
    'constraint': 'finiteDurationAt20TicksPerSecond'
  },
  {
    'kind': 'command',
    'source': [108, 408],
    'native': 'preservedAnnotation',
    'disposition': 'adaptation',
    'constraint': 'noRuntimeEffect'
  },
  {
    'kind': 'command',
    'source': [111, 411, 412],
    'native': 'sceneCondition',
    'disposition': 'native',
    'constraint': 'qualifiedTypedCondition'
  },
  {
    'kind': 'command',
    'source': [115],
    'native': 'endInvocation',
    'disposition': 'native',
    'constraint': 'localReturnForCommonCalls'
  },
  {
    'kind': 'command',
    'source': [117],
    'native': 'inlinedCommonSubroutine',
    'disposition': 'adaptation',
    'constraint': 'manualCalleeClosureDepth16Commands10000Parameters40000'
  },
  {
    'kind': 'command',
    'source': [121],
    'native': 'setBooleanFact',
    'disposition': 'native',
    'constraint': 'qualifiedSwitchMetadata'
  },
  {
    'kind': 'command',
    'source': [122],
    'native': 'integerFact',
    'disposition': 'adaptation',
    'constraint': 'typedSnapshotOperandAndBoundedCalculationAndWriterCensus'
  },
  {
    'kind': 'command', 'source': [103], 'native': 'inputIntegerToFact',
    'disposition': 'adaptation', 'constraint': 'digits1To9ClampedInitialAndRestoreOnUserCancel'
  },
  {
    'kind': 'command', 'source': [125], 'native': 'adjustMoney',
    'disposition': 'adaptation', 'constraint': 'signedScalarAndAttestedSettingsLimitClampAndContinue'
  },
  {
    'kind': 'command',
    'source': [123],
    'native': 'ownerLocalBooleanFact',
    'disposition': 'native',
    'constraint': 'qualifiedOwnerAndNoTransferInComposition'
  },
  {
    'kind': 'command',
    'source': [201],
    'native': 'warp',
    'disposition': 'adaptation',
    'constraint':
        'literalDestinationAndQualifiedArrivalWithoutMapLocalContinuation'
  },
  {
    'kind': 'condition',
    'source': [
      'always',
      'all',
      'globalSwitch',
      'selfSwitch',
      'variableAtLeast',
      'variableComparison',
      'integerComparison'
    ],
    'native': 'typedFactCondition',
    'disposition': 'native',
    'constraint': 'qualifiedMetadataAndWriterCensusAndOwnerWhenLocal'
  },
  {
    'kind': 'trigger',
    'source': [0, 1, 2],
    'native': 'nativeEventActivation',
    'disposition': 'adaptation',
    'constraint': 'qualifiedInteractionOrTouchFootprint'
  },
  {
    'kind': 'trigger',
    'source': [3, 4],
    'native': null,
    'disposition': 'refusal',
    'constraint': 'requiresSeparatelyProvenTerminationOrAutonomyContract'
  },
  {
    'kind': 'command',
    'source': [112, 113, 413, 118, 119],
    'native': 'staticallyReducedControlFlow',
    'disposition': 'adaptation',
    'constraint': 'provenUnconditionalFirstPassExitOrUniqueForwardLabelInSameBlock'
  },
  {
    'kind': 'command',
    'source': [124],
    'native': null,
    'disposition': 'refusal',
    'constraint': 'persistentTimerRequiresNativeClockContract'
  },
  {
    'kind': 'command',
    'source': [355, 655],
    'native': 'typedStaticHelper',
    'disposition': 'adaptation',
    'sourceSection': 'events.Utilities',
    'constraint': 'recognizedLiteralHelperAndRequiredSectionWitness',
  },
  {
    'kind': 'command',
    'source': [355, 655],
    'native': null,
    'disposition': 'refusal',
    'constraint': 'arbitraryRubyOutsideQualifiedStaticHelpers',
  },
];

Map<String, Object?> _sourceCompositionContract(SourceEventProfile profile) {
  final sections = profile.interpretationProfile?.sections ?? const {};
  String section(Map<String, Object?> entry) {
    if (entry['sourceSection'] case final String role) return role;
    final role = entry['kind'] == 'trigger'
        ? 'events.Game_Event'
        : 'events.Interpreter_Commands';
    return sections.containsKey(role) ? role : 'events.Interpreter';
  }

  return {
    'contract': 'source-event-composition',
    'version': 2,
    'identityPolicy': 'engineVersionOnly',
    'qualification':
        profile.isQualified ? 'attestedEngineProfile' : 'unqualified',
    'entries': [
      for (final entry in _sourceCompositionEntries)
        {
          ...entry,
          'sourceSection': section(entry),
          'sectionEvidence': sections[section(entry)],
          'proofScope': 'declaredEngineSectionContract',
        }
    ],
    'commonDependencyScope': 'transitiveCalledManualEvents',
    'variableWriterScope': 'allObservedSourceWriters',
    'switchWriterScope': 'allObservedUnrepresentedCommonWriters',
    'sourceScriptsExecuted': 0,
    'aiCalls': 0,
  };
}

bool _composableCondition(SourceEventCondition condition) =>
    switch (condition.kind) {
      SourceEventConditionKind.always ||
      SourceEventConditionKind.globalSwitch ||
      SourceEventConditionKind.selfSwitch ||
      SourceEventConditionKind.variableAtLeast ||
      SourceEventConditionKind.variableComparison =>
        condition.isQualified,
      SourceEventConditionKind.integerComparison => condition.isQualified,
      SourceEventConditionKind.all =>
        condition.children.every(_composableCondition),
      _ => false,
    };

bool _usesCompositionPrimitives(SourceEventDefinition event) =>
    event.pages.any((page) => _sourceControlNodes(page.body).any(
        (node) => node is SourceWaitNode || node is SourceCommonEventCallNode ||
          node is SourceVariableCalculationNode || node is SourceIntegerInputNode ||
          node is SourceMoneyAdjustmentNode || node is SourceConditionalNode &&
          const {SourceEventConditionKind.integerComparison, SourceEventConditionKind.always}.contains(node.condition.kind)));

bool _hasAmbiguousCompositionOwner(SourceEventDefinition event) {
  final nodes =
      event.pages.expand((page) => _sourceControlNodes(page.body)).toList();
  if (!nodes.any((node) => node is SourceWarpNode) ||
      nodes.any((node) =>
          node is SourceForcedMoveRouteNode ||
          node is SourceFirstRivalProgramNode ||
          node is SourceOakParcelProgramNode ||
          node is SourceTrainerProgramNode)) {
    return false;
  }
  bool local(SourceEventCondition condition) =>
      const {
        SourceEventConditionKind.selfSwitch,
        SourceEventConditionKind.tempSwitch,
        SourceEventConditionKind.playerOnEvent,
      }.contains(condition.kind) ||
      condition.children.any(local);
  return nodes.any((node) =>
      node is SourceSelfSwitchNode ||
      node is SourceTempSwitchNode ||
      node is SourceConditionalNode && local(node.condition));
}

extension _SourceCompositionQualification on _ProjectionBuilder {
  bool _compositionMatchesSource(SourceEventDefinition event) =>
      _compositionSourceMatches.putIfAbsent(
          event, () => _matchesCompositionSource(event));

  bool _matchesCompositionSource(SourceEventDefinition event) {
    final expected =
        _sourceControlAnalysis.eventAt(event.sourceMapId, event.sourceEventId);
    if (expected == null ||
        expected.identity != event.identity ||
        expected.name != event.name ||
        expected.x != event.x ||
        expected.y != event.y ||
        expected.sourceFileId != event.sourceFileId ||
        expected.pages.length != event.pages.length ||
        _sourceControlFingerprint(expected) != _sourceControlFingerprint(event)) {
      return false;
    }
    Object? graphic(SourceEventGraphic? value) => value == null
        ? null
        : [
            value.tileId,
            value.characterName,
            value.hue,
            value.direction,
            value.pattern,
            value.opacity,
            value.blendType,
            value.moveType,
            value.moveSpeed,
            value.moveFrequency,
            value.walkAnime,
            value.stepAnime,
            value.directionFix,
            value.through,
            value.alwaysOnTop,
            value.moveRouteNodeId,
          ];
    return List.generate(event.pages.length, (index) => index).every((index) =>
        canonicalJsonOf(graphic(expected.pages[index].graphic)) ==
            canonicalJsonOf(graphic(event.pages[index].graphic)) &&
        _sourceCommonProgramHash(expected.pages[index].body) ==
            _sourceCommonProgramHash(event.pages[index].body));
  }

  bool _isComposableEvent(SourceEventDefinition event) =>
      _compositionQualifications.putIfAbsent(
          event, () => _qualifyComposition(event));

  bool _qualifyComposition(SourceEventDefinition event) {
    if (!_usesCompositionPrimitives(event) ||
        !analysis.profile.isQualified ||
        analysis.profile.canonicalHash !=
            SourceEventProfile.forProject(source).canonicalHash ||
        event.isQuarantined ||
        event.pages.isEmpty ||
        !_compositionMatchesSource(event) ||
        _hasAmbiguousCompositionOwner(event)) {
      return false;
    }
    for (final page in event.pages) {
      if (!const {0, 1, 2}.contains(page.triggerCode) ||
          !_composableCondition(page.condition)) {
        return false;
      }
      for (final node in _sourceControlNodes(page.body)) {
        switch (node) {
          case SourceAnnotationNode():
          case SourceTextNode():
          case SourceChoiceNode():
          case SourceSwitchNode():
          case SourceSelfSwitchNode():
          case SourceVariableSetNode():
          case SourceVariableAdjustNode():
          case SourceExitEventNode():
            break;
          case SourceVariableCalculationNode():
            if (node.profileHash != analysis.profile.canonicalHash || !node.operand.isQualified || node.factIds.length > 1024) return false;
          case SourceIntegerInputNode():
            if (node.profileHash != analysis.profile.canonicalHash) {
              return false;
            }
          case SourceMoneyAdjustmentNode():
            if (node.profileHash != analysis.profile.canonicalHash || !node.operand.isQualified ||
                node.maximum != sourceEventMoneyMaximum(source)) return false;
          case SourceConditionalNode():
            if (!_composableCondition(node.condition)) return false;
          case SourceCommonEventCallNode():
            if (node.body.isQuarantined ||
                node.sourceMapId != event.sourceMapId ||
                node.sourceEventId != event.sourceEventId) {
              return false;
            }
          case SourceWaitNode():
            if (node.profileHash != analysis.profile.canonicalHash) {
              return false;
            }
          case SourceWarpNode():
            if (node.originalProgram != null) return false;
          default:
            return false;
        }
      }
    }
    return true;
  }

  Set<int> _compositionSwitchReads(SourceEventDefinition event) {
    final reads = <int>{};
    void condition(SourceEventCondition value) {
      if (value.kind == SourceEventConditionKind.globalSwitch &&
          value.factId != null) {
        final id = int.tryParse(value.factId!.split(':').last);
        if (id != null) reads.add(id);
      }
      for (final child in value.children) {
        condition(child);
      }
    }

    for (final page in event.pages) {
      condition(page.condition);
      for (final node in _sourceControlNodes(page.body)) {
        if (node is SourceConditionalNode) condition(node.condition);
      }
    }
    return reads;
  }

  Set<String> _compositionSwitchGaps(SourceEventDefinition event) {
    if (_unqualifiedSwitchWriters == null || !_isComposableEvent(event)) {
      return const {};
    }
    final reads = _compositionSwitchReads(event);
    return reads.any((id) =>
            _dynamicSwitchWriter || _unqualifiedSwitchWriters!.contains(id))
        ? {'sourceSwitchWriterUnqualified'}
        : const {};
  }

  List<Map<String, Object?>> _compositionSwitchWriterEvidence(
      SourceEventDefinition event) {
    final reads = _compositionSwitchReads(event);
    return [
      for (final writer in _commonSwitchWriterEvidence.values)
        if (writer['dynamicSwitchWrite'] == true ||
            (writer['writtenSwitchIds'] as List<int>).any(reads.contains))
          writer
    ];
  }
}

List<Map<String, Object?>> _compositionRefusals(
    SourceEventDefinition event, Set<String> gaps,
    {List<Map<String, Object?>> switchWriters = const []}) {
  String owner(String cause) {
    if (cause.contains('invalid_') ||
        cause == 'eventPositionInvalid' ||
        cause == 'warpArrivalInvalid' ||
        cause == 'events.common_event_missing') {
      return 'sourceInvalid';
    }
    if (const {
      'events.script_group_quarantined',
      'events.unsupported_control_flow',
      'events.common_event_recursion',
      'events.common_event_depth_exceeded',
      'events.common_event_command_budget_exceeded',
      'events.common_event_parameter_budget_exceeded',
      'events.command_depth_exceeded',
      'events.common_event_automatic_or_invalid',
    }.contains(cause)) {
      return 'outOfScope';
    }
    if (cause == 'events.dynamic_variable_assignment') {
      return 'nativeContractMissing';
    }
    return 'converter';
  }

  final diagnostics = event.pages.expand((page) => page.diagnostics).toList();
  String identity(SourceEventDiagnostic diagnostic) => canonicalHashOf({
        'event': event.identity.value,
        'diagnostic': diagnostic.toJson(),
      }).value;
  final roots = diagnostics
      .where((diagnostic) =>
          diagnostic.code != 'events.common_event_body_unqualified')
      .toList();
  List<String> causes(SourceEventDiagnostic diagnostic) => [
        for (final root in roots)
          if (root.commonEventPath.length >=
                  diagnostic.commonEventPath.length &&
              List.generate(diagnostic.commonEventPath.length, (index) => index)
                  .every((index) =>
                      root.commonEventPath[index] ==
                      diagnostic.commonEventPath[index]))
            identity(root),
      ];
  return [
    for (final diagnostic in diagnostics)
      {
        'id': identity(diagnostic),
        'rootCause': diagnostic.code,
        'owner': owner(diagnostic.code),
        'locator': diagnostic.locator.toJson(),
        'span': diagnostic.span?.toJson(),
        'dependencyPath': diagnostic.commonEventPath,
        'dependents': [
          event.identity.value,
          for (final id in diagnostic.commonEventPath.take(
              diagnostic.commonEventPath.isEmpty
                  ? 0
                  : diagnostic.commonEventPath.length - 1))
            'commonEvent:$id'
        ],
        if (diagnostic.code == 'events.common_event_body_unqualified')
          'causedBy': causes(diagnostic),
      },
    for (final gap in gaps.toList()..sort())
      {
        'id':
            canonicalHashOf({'event': event.identity.value, 'gap': gap}).value,
        'rootCause': gap,
        'owner': owner(gap),
        'locator': event.locator.toJson(),
        'dependents': [event.identity.value],
        if (gap == 'sourceSwitchWriterUnqualified') 'writers': switchWriters,
        if (gap == 'sourceQuarantined' || gap == 'sourceCommandUnqualified')
          'causedBy': roots.map(identity).toList(),
      },
  ];
}
