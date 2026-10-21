import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';

final class SourceNpcFixedRouteBindingUnavailable implements Exception {
  const SourceNpcFixedRouteBindingUnavailable(this.reason);
  final String reason;
  @override
  String toString() => 'SourceNpcFixedRouteBindingUnavailable($reason)';
}

final class SourceNpcFixedRouteBinding {
  SourceNpcFixedRouteBinding._({
    required this.nativeMovement,
    required this.initialFacing,
    required this.rawDataRef,
    required this.sourceSnapshotHash,
    required this.normalizationHash,
    required this.profileHash,
    required this.sourceScriptsHash,
    required this.sourceMapId,
    required this.sourceEventId,
    required this.sourcePageIndex,
    required this.eventHash,
    required this.pageHash,
  });

  final MapEntityNpcMovementConfig nativeMovement;
  final EntityFacing initialFacing;
  final SourcePreservedData rawDataRef;
  final Sha256Hash sourceSnapshotHash,
      normalizationHash,
      profileHash,
      eventHash,
      pageHash;
  final int sourceMapId, sourceEventId, sourcePageIndex;
  final Sha256Hash? sourceScriptsHash;

  bool isBoundToPage({
    required NormalizedSourceProject source,
    required SourceEventProfile profile,
    required SourceEventDefinition event,
    required SourceEventPageAnalysis page,
  }) {
    if (!profile.isQualified ||
        source.snapshot.canonicalHash != sourceSnapshotHash ||
        source.canonicalHash != normalizationHash ||
        profile.canonicalHash != profileHash ||
        event.sourceMapId != sourceMapId ||
        event.sourceEventId != sourceEventId ||
        page.originalPageIndex != sourcePageIndex ||
        page.rawDataRef?.id != rawDataRef.id ||
        page.rawDataRef?.contentHash != rawDataRef.contentHash) {
      return false;
    }
    try {
      return canonicalHashOf(_eventData(event)) == eventHash &&
          canonicalHashOf(_pageData(page)) == pageHash;
    } on SourceNpcFixedRouteBindingUnavailable {
      return false;
    }
  }

  Map<String, Object?> toJson() => {
        'kind': 'sourceNpcFixedRouteBinding',
        'version': 1,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'sourceMapId': sourceMapId,
        'sourceEventId': sourceEventId,
        'sourcePageIndex': sourcePageIndex,
        'eventHash': eventHash.value,
        'pageHash': pageHash.value,
        'rawDataRef': rawDataRef.toJson(),
        'initialFacing': initialFacing.name,
        'nativeMovement': nativeMovement.toJson(),
        'nonSkippable': true,
        'nativePauseScope': 'allAutonomousNpcsDuringDialogueOrMenu',
        'sourcePauseScope': 'interactingEventOwner',
        'sourceParity': false,
        'sourceProgramQualified': false,
        'nativeRouteProgressSaved': false,
        'sourceRouteProgressSaveParity': false,
        'sourceScriptsExecuted': 0,
        if (nativeMovement.routeSteps.any((step) => step is MapEntityNpcRandomMoveStep))
          'sourceRandomWalkAdaptation': {
            'nativeSelection': 'uniformCardinalDirectionPerAttempt',
            'blockedAttempt': 'waitThenSelectAgain',
            'sourceRandomSequenceParity': false,
          },
        'oracle': {
          'scriptsArchiveSha256':
              sourceScriptsHash?.value,
          'section': 44,
          'sha256':
              '0cb6a5149f998c053055d3c7726d557fe1a1368fcabe14bb4a7c159f09a686b9',
          'speedLines': [110, 125],
          'cadenceLines': [145, 157],
          'nonSkippableLines': [427, 491],
          'randomFacingLines': [859, 866],
        },
      };
}

final class SourceNpcFixedRouteBindingResolver {
  SourceNpcFixedRouteBindingResolver.forProject(this.source)
      : _profile = SourceEventProfile.forProject(source);

  final NormalizedSourceProject source;
  final SourceEventProfile _profile;
  late final SourceEventAnalysis _analysis =
      SourceEventAnalyzer.forProject(source, profile: _profile).analyze();

  SourceNpcFixedRouteBinding resolve({
    required int sourceMapId,
    required int sourceEventId,
    required int sourcePageIndex,
  }) {
    if (!source.canPlan ||
        !_profile.isQualified ||
        source.snapshot.state != SourceScanState.complete) {
      _unavailable('source_unqualified');
    }
    final event = _analysis.eventAt(sourceMapId, sourceEventId);
    if (event == null) _unavailable('event_missing');
    final pages =
        event.pages.where((page) => page.originalPageIndex == sourcePageIndex);
    if (pages.length != 1) _unavailable('page_missing');
    final page = pages.single;
    final graphic = page.graphic;
    final raw = page.rawDataRef;
    if (page.isQuarantined ||
        graphic == null ||
        raw == null ||
        !const {1, 3}.contains(graphic.moveType) ||
        (graphic.characterName.isEmpty && !page.isEmpty) ||
        graphic.tileId != 0 ||
        graphic.hue != 0 ||
        graphic.opacity != 255 ||
        graphic.blendType != 0 ||
        graphic.directionFix ||
        (graphic.through &&
            !(graphic.characterName.isEmpty && page.isEmpty)) ||
        graphic.alwaysOnTop ||
        !graphic.walkAnime ||
        graphic.stepAnime) {
      _unavailable('page_contract_unsupported');
    }
    final doc = source.sourceFiles[raw.fileId]!.document;
    for (final node in doc.nodes) {
      if (node.kind == MarshalKind.symbol &&
          const {'RPG::Event::Page', 'RPG::MoveRoute', 'RPG::MoveCommand'}
              .contains(node.name) &&
          (node.extensions.isNotEmpty ||
              node.userClass != null ||
              node.instanceVariables.isNotEmpty)) {
        _unavailable('source_class_symbol_unsupported');
      }
    }
    final fields = _fields(doc, raw.nodeId, 'RPG::Event::Page', const {
      '@condition',
      '@graphic',
      '@move_type',
      '@move_speed',
      '@move_frequency',
      '@move_route',
      '@walk_anime',
      '@step_anime',
      '@direction_fix',
      '@through',
      '@always_on_top',
      '@trigger',
      '@list',
    });
    for (final key in [
      '@move_type',
      '@move_speed',
      '@move_frequency',
      '@trigger'
    ]) {
      _plain(doc, fields[key]!, MarshalKind.integer);
    }
    for (final key in [
      '@walk_anime',
      '@step_anime',
      '@direction_fix',
      '@through',
      '@always_on_top'
    ]) {
      _plain(doc, fields[key]!, MarshalKind.boolean);
    }
    final route = _fields(doc, fields['@move_route']!, 'RPG::MoveRoute', const {
      '@repeat',
      '@skippable',
      '@list',
    });
    if (_boolean(doc, route['@skippable']!)) {
      _unavailable('skippable_unsupported');
    }
    final nodes = _array(doc, route['@list']!);
    if (nodes.isEmpty || nodes.length > 257 ||
        (graphic.moveType == 3 && nodes.length < 2)) {
      _unavailable('route_step_quota');
    }
    final steps = <MapEntityNpcRouteStep>[];
    for (var index = 0; index < nodes.length; index++) {
      final command = _fields(doc, nodes[index], 'RPG::MoveCommand', const {
        '@code',
        '@parameters',
      });
      if (_array(doc, command['@parameters']!).isNotEmpty) {
        _unavailable('route_parameters_unsupported');
      }
      final code = _integer(doc, command['@code']!);
      if (index == nodes.length - 1) {
        if (code != 0) _unavailable('route_terminator_missing');
        continue;
      }
      steps.add(switch (code) {
        1 => const MapEntityNpcRouteStep.move(direction: EntityFacing.south),
        2 => const MapEntityNpcRouteStep.move(direction: EntityFacing.west),
        3 => const MapEntityNpcRouteStep.move(direction: EntityFacing.east),
        4 => const MapEntityNpcRouteStep.move(direction: EntityFacing.north),
        16 => const MapEntityNpcRouteStep.face(direction: EntityFacing.south),
        17 => const MapEntityNpcRouteStep.face(direction: EntityFacing.west),
        18 => const MapEntityNpcRouteStep.face(direction: EntityFacing.east),
        19 => const MapEntityNpcRouteStep.face(direction: EntityFacing.north),
        24 => const MapEntityNpcRouteStep.randomFacing(),
        _ => _unavailable('route_command_unsupported'),
      });
    }
    if (graphic.moveType == 1 &&
        (!_boolean(doc, route['@repeat']!) ||
          steps.any((step) => step is! MapEntityNpcRandomFacingStep))) {
      _unavailable('unused_random_route_unsupported');
    }
    final movement = MapEntityNpcMovementConfig(
      mode: MapEntityNpcMovementMode.fixedRoute,
      routeSteps: graphic.moveType == 1
          ? const [MapEntityNpcRouteStep.randomMove()]
          : List.unmodifiable(steps),
      loop: _boolean(doc, route['@repeat']!),
      pauseDurationMs: const [
        4750,
        3600,
        2550,
        1600,
        750,
        0
      ][graphic.moveFrequency - 1],
      stepDurationMs: const [
        1000,
        500,
        250,
        125,
        100,
        50
      ][graphic.moveSpeed - 1],
    );
    assertValidMapEntityNpcMovementConfig(movement);
    return SourceNpcFixedRouteBinding._(
      sourceScriptsHash: _profile.scriptsArchiveHash,
      nativeMovement: movement,
      initialFacing: switch (graphic.direction) {
        2 => EntityFacing.south,
        4 => EntityFacing.west,
        6 => EntityFacing.east,
        8 => EntityFacing.north,
        _ => _unavailable('initial_facing_unsupported'),
      },
      rawDataRef: raw,
      sourceSnapshotHash: source.snapshot.canonicalHash,
      normalizationHash: source.canonicalHash,
      profileHash: _profile.canonicalHash,
      sourceMapId: sourceMapId,
      sourceEventId: sourceEventId,
      sourcePageIndex: sourcePageIndex,
      eventHash: canonicalHashOf(_eventData(event)),
      pageHash: canonicalHashOf(_pageData(page)),
    );
  }
}

Map<String, Object?> _eventData(SourceEventDefinition event) => {
      'sourceMapId': event.sourceMapId,
      'sourceEventId': event.sourceEventId,
      'sourceFileId': event.sourceFileId.value,
      'identity': event.identity.value,
      'name': event.name,
      'x': event.x,
      'y': event.y,
      'locator': event.locator.toJson(),
    };

Map<String, Object?> _pageData(SourceEventPageAnalysis page) {
  final graphic = page.graphic;
  if (graphic == null || page.isQuarantined) {
    _unavailable('page_contract_unsupported');
  }
  return {
    'sourcePage': page.sourcePage.toJson(),
    'locator': page.locator.toJson(),
    'rawDataRef': page.rawDataRef?.toJson(),
    'condition': page.condition.toJson(),
    'graphic': {
      'tileId': graphic.tileId,
      'characterName': graphic.characterName,
      'hue': graphic.hue,
      'direction': graphic.direction,
      'pattern': graphic.pattern,
      'opacity': graphic.opacity,
      'blendType': graphic.blendType,
      'moveType': graphic.moveType,
      'moveSpeed': graphic.moveSpeed,
      'moveFrequency': graphic.moveFrequency,
      'walkAnime': graphic.walkAnime,
      'stepAnime': graphic.stepAnime,
      'directionFix': graphic.directionFix,
      'through': graphic.through,
      'alwaysOnTop': graphic.alwaysOnTop,
      'moveRouteNodeId': graphic.moveRouteNodeId,
    },
    'body': _fixedRouteBlockData(page.body),
  };
}

List<Object?> _fixedRouteBlockData(SourceEventBlock block, [int depth = 0]) {
  if (depth > 64 || block.isQuarantined) {
    _unavailable('program_shape_unsupported');
  }
  Object? nodeData(SourceEventNode node) => {
    'span': node.span.toJson(),
    'value': switch (node) {
      SourceTextNode() => {'kind': 'text', 'text': node.text,
        'annotations': node.annotations.map((node) => node.toJson()).toList(),
        'followingChoice': node.followingChoice == null ? null
            : nodeData(node.followingChoice!)},
      SourceAnnotationNode() => node.toJson(),
      SourceChoiceNode() => {'kind': 'choice', 'cancelType': node.cancelType,
        'cancellation': node.cancellation.toJson(),
        'branches': [for (final branch in node.branches) {
          'index': branch.index, 'label': branch.label,
          'body': _fixedRouteBlockData(branch.body, depth + 1)}],
        'cancelBranch': node.cancelBranch == null ? null
            : _fixedRouteBlockData(node.cancelBranch!, depth + 1)},
      SourceConditionalNode() when node.condition.isQualified => {
        'kind': 'conditional', 'condition': node.condition.toJson(),
        'whenTrue': _fixedRouteBlockData(node.whenTrue, depth + 1),
        'whenFalse': _fixedRouteBlockData(node.whenFalse, depth + 1)},
      SourceInteractionFacingNode() => {'kind': 'interactionFacing',
        'rawDataRefs': node.rawDataRefs.map((ref) => ref.toJson()).toList()},
      SourceTrainerProgramNode() => node.toJson(),
      SourcePickupNode() when node.helper == SourceItemGrantHelper.receiveItem =>
        {'kind': 'receiveItem', ...node.toJson()},
      SourceSelfSwitchNode() => {'kind': 'selfSwitch', 'letter': node.letter,
        'value': node.value, 'factId': node.factId},
      _ => _unavailable('program_shape_unsupported'),
    },
  };
  return block.nodes.map(nodeData).toList();
}

Map<String, int> _fields(
    MarshalDocument doc, int id, String className, Set<String> expected) {
  final node = doc.node(id);
  if (node.kind != MarshalKind.object ||
      node.className != className ||
      node.extensions.isNotEmpty ||
      node.userClass != null ||
      node.instanceVariables.length != expected.length) {
    _unavailable('source_object_unsupported');
  }
  final fields = <String, int>{};
  for (final pair in node.instanceVariables) {
    final key = doc.node(_plain(doc, pair.key, MarshalKind.symbol)).name;
    if (key == null || !expected.contains(key) || fields.containsKey(key)) {
      _unavailable('source_field_unsupported');
    }
    fields[key] = pair.value;
  }
  return fields;
}

int _plain(MarshalDocument doc, int id, MarshalKind kind) {
  final node = doc.node(id);
  if (node.kind != kind ||
      node.extensions.isNotEmpty ||
      node.userClass != null ||
      node.instanceVariables.isNotEmpty) {
    _unavailable('source_value_unsupported');
  }
  return id;
}

List<int> _array(MarshalDocument doc, int id) =>
    doc.node(_plain(doc, id, MarshalKind.array)).elements;
int _integer(MarshalDocument doc, int id) {
  final value = doc.node(_plain(doc, id, MarshalKind.integer)).integerValue;
  if (value == null || value < BigInt.zero || value > BigInt.from(1000000)) {
    _unavailable('source_integer_unsupported');
  }
  return value.toInt();
}

bool _boolean(MarshalDocument doc, int id) =>
    doc.node(_plain(doc, id, MarshalKind.boolean)).booleanValue!;
Never _unavailable(String reason) =>
    throw SourceNpcFixedRouteBindingUnavailable(reason);
