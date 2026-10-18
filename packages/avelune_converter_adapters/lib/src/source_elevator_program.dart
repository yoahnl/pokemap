import 'package:avelune_converter_core/avelune_converter_core.dart';

import 'native_project_writer.dart';

enum SourceElevatorRole { door, exit, controller, actor }

enum SourceElevatorPresentationPolicy { nativeAveluneFiniteJourney }

const _mapHashes = <int, String>{
  38: '23009cefc745a3796932d93d281992d840cb79fe0db917224d095e3b1c8fa878',
  40: '60baa169810c316ca10a81b6e3ef6b3d89cd669ab9b4408b6e8d9ea8843182c7',
  173: '602003db05135654aca200ae9c521f6909407056df20c11c559584c3fb7b960e',
  174: 'b2c1c36fb493a8da38826e039bd91039628d69b4ac53673d5d3a3f3ae33772e3',
  176: 'a5d258289f01603a7bd070b9c3b315b63eb23fdc1e9b4c87fbd00fe291be2876',
  177: '3cf333d60be5cdffb712afdbdf768a75ca0a7a6000955f0c947db8ed9b06e015',
  213: 'c72a9f2d2a0b053df2ce643d0fb91f1c65491aab599e87ceed46866b00051ee4',
  214: 'b56b2eccefe8e72b3cf163e8386d883e72be0cb121ba779af0e580279c0e5a58',
  215: '05de1f4a72bbda7985dc53c6491c7950d7e4a110fec766d4f51094148c54b3a5',
  216: '673c4c2d215471603614fe9ac0bc8dc77350f687e48ee24daee40bebddfb7338',
  217: 'cbd5577df429d683303700cf83e7966cf885903c670fc2740bf0014bf7299d1d',
  218: 'd1bff9152fab00390e0bee511963723f5cb03ad925d4134ec176a20d38599322',
  219: '2ffa4035b25d60a1f325e6bf54daa5494cb42ddca62af99dbeaf95df34e3e9de',
  220: '4f667c7fbd6ccce3579ec82e405bb648fa8c8fcf7e01817ecec7e90a6e436acf',
  221: 'aa1e37b6a564ec562782cbc8553fd1a5c4b70e1bf923d04b9fdf88fddb14a326',
  222: '9dd4f179a6b164cc0b59665f8085cf97e8c130800ed8eff33c6fb6d28f8050d0',
  223: '61c541a68855e571a0177cb6e9831709baf95f302883dc56f1d963998423d5d2',
  224: 'c7087d40de9622d26a60e5b38a3d7dde17c00b3f8b5d92a58e70fc9b6fc4818d',
};

const _doors = <(int, int), (int, int, int)>{
  (38, 12): (40, 5, 2),
  (38, 3): (40, 5, 1),
  (38, 41): (40, 5, 4),
  (38, 53): (40, 5, 5),
  (38, 26): (40, 5, 3),
  (173, 4): (177, 3, 3),
  (174, 4): (177, 3, 2),
  (176, 4): (177, 3, 1),
  (213, 1): (224, 11, 1),
  (214, 1): (224, 11, 2),
  (215, 1): (224, 11, 3),
  (216, 1): (224, 11, 4),
  (217, 1): (224, 11, 5),
  (218, 1): (224, 11, 6),
  (219, 1): (224, 11, 7),
  (220, 1): (224, 11, 8),
  (221, 1): (224, 11, 9),
  (222, 1): (224, 11, 10),
  (223, 1): (224, 11, 11),
};

final class SourceElevatorProgram {
  SourceElevatorProgram._(
      this.source,
      this.profileHash,
      this.event,
      this.cabinMapId,
      this.maximumFloor,
      this.floor,
      this.role,
      this.familyHash,
      Set<ConverterId> identities)
      : requiredEventIdentities = Set.unmodifiable(identities),
        _fingerprint = _fingerprintOf(event);

  final NormalizedSourceProject source;
  final Sha256Hash profileHash, familyHash;
  final SourceEventDefinition event;
  final int cabinMapId, maximumFloor;
  final int? floor;
  final SourceElevatorRole role;
  final Set<ConverterId> requiredEventIdentities;
  final String _fingerprint;
  int get sourceMapId => event.sourceMapId;
  int get sourceEventId => event.sourceEventId;
  ConverterId get eventIdentity => event.identity;
  int get targetSourceMapId =>
      role == SourceElevatorRole.door ? cabinMapId : sourceMapId;
  Set<int> get requiredSourceMapIds => _mapHashes.keys.toSet();
  SourceElevatorPresentationPolicy get policy =>
      SourceElevatorPresentationPolicy.nativeAveluneFiniteJourney;

  bool isBoundTo(
          {required NormalizedSourceProject source,
          required SourceEventAnalysis analysis,
          required SourceEventDefinition event}) =>
      analysis.profile.isQualified &&
      source.snapshot.canonicalHash == this.source.snapshot.canonicalHash &&
      source.canonicalHash == this.source.canonicalHash &&
      analysis.profile.canonicalHash == profileHash &&
      source.archive.files[event.sourceFileId]?.contentHash ==
          this.source.archive.files[this.event.sourceFileId]?.contentHash &&
      event.identity == eventIdentity &&
      _fingerprintOf(event) == _fingerprint;

  bool permitsDormantStoredRoute(NormalizedSourceProject project,
          SourceEventDefinition owner, SourceEventPageAnalysis page) =>
      project.snapshot.canonicalHash == source.snapshot.canonicalHash &&
      _mapHashes[owner.sourceMapId] != null &&
      project.archive.files[owner.sourceFileId]?.contentHash.value ==
          _mapHashes[owner.sourceMapId] &&
      page.graphic?.moveType == 0;

  Map<String, Object?> toJson() => {
        'kind': 'completeSourceElevatorProgram',
        'version': 1,
        'eventIdentity': eventIdentity.value,
        'role': role.name,
        'sourceMapId': sourceMapId,
        'sourceEventId': sourceEventId,
        'cabinMapId': cabinMapId,
        'maximumFloor': maximumFloor,
        'floor': floor,
        'sourceSnapshotHash': source.snapshot.canonicalHash.value,
        'normalizationHash': source.canonicalHash.value,
        'profileHash': profileHash.value,
        'familyHash': familyHash.value,
        'sourceFileHash':
            source.archive.files[event.sourceFileId]!.contentHash.value,
        'programHash': canonicalHashOf(_fingerprint).value,
        'requiredEventCount': requiredEventIdentities.length,
        'requiredEventIdentitiesHash': canonicalHashOf(
                requiredEventIdentities.map((id) => id.value).toList()..sort())
            .value,
        'sourcePages':
            event.pages.map((page) => page.rawDataRef?.toJson()).toList(),
        'sourceRoutes': sourceElevatorNodes(event)
            .whereType<SourceForcedMoveRouteNode>()
            .map((route) => {
                  'span': route.span.toJson(),
                  'targetSourceCharacterId': route.targetSourceCharacterId,
                  'raw209509ProgramHash': canonicalHashOf(route.toJson()).value,
                  'rawReferenceCount': route.rawDataRefs.length
                })
            .toList(),
        'presentationPolicy': {
          'id': policy.name,
          'version': 1,
          'travelSound': 'nativeNonLoopingSourceCue',
          'finalSound': 'preservedForTravelSameFloorAndCancellation',
          'sourceShakeReproduced': false,
          'sourceGlobalStopSEReproduced': false,
          'state': 'twoSharedPersistentIntegerFacts',
          'consequences': 'orderedSourceWritesCommittedAtNativeSceneCompletion',
          'intermediateWrites': 'preservedInSceneGraphNotPublishedMidScene',
          'invalidCurrentFloor':
              'controllerNotEnabledOutsideAttestedFloorDomain',
          'exitFallback': 'exactSourceUnmatchedValueUsesFloorOne',
          if (role == SourceElevatorRole.exit)
            'blockedExit': {
              'policy': 'restoreAttestedFinalSourceToneBeforeSuccessfulEnd',
              'restoration':
                  (event.pages.single.body.nodes.last as SourceToneNode).toJson(),
            },
        },
        'sourceScriptsExecuted': 0,
        'sourceProgramPlaybackQualified': false,
      };
}

bool isSourceElevatorFamilyEvent(SourceEventDefinition event) =>
    _doors.containsKey((event.sourceMapId, event.sourceEventId)) ||
    ({40, 177, 224}.contains(event.sourceMapId) &&
        event.sourceEventId >= 1 &&
        event.sourceEventId <= 5);

Map<ConverterId, SourceElevatorProgram> sourceElevatorPrograms(
    {required NormalizedSourceProject source,
    required SourceEventAnalysis analysis}) {
  if (analysis.profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
      analysis.profile.normalizationHash != source.canonicalHash) {
    throw const NativeWriteException('events.source.binding',
        'Elevators require the exact normalized source');
  }
  final profile = SourceEventProfile.forProject(source);
  if (!profile.isQualified ||
      profile.canonicalHash != analysis.profile.canonicalHash ||
      _mapHashes.entries.any((entry) =>
          source.archive.files.values
              .where((file) =>
                  file.entry.relativePath ==
                      'Data/Map${entry.key.toString().padLeft(3, '0')}.rxdata' &&
                  file.contentHash.value == entry.value)
              .length !=
          1)) {
    return const {};
  }
  final authoritative =
      SourceEventAnalyzer.forProject(source, profile: profile).analyze();
  final expected = <ConverterId, SourceEventDefinition>{};
  for (final event in authoritative.events) {
    if (isSourceElevatorFamilyEvent(event)) {
      expected[event.identity] = event;
    }
  }
  if (expected.length != 34 ||
      expected.values.any((event) =>
          analysis.events
              .where((candidate) =>
                  candidate.identity == event.identity &&
                  _fingerprintOf(candidate) == _fingerprintOf(event))
              .length !=
          1)) {
    return const {};
  }
  final familyHash = canonicalHashOf({
    'policy': SourceElevatorPresentationPolicy.nativeAveluneFiniteJourney.name,
    'programs': {
      for (final entry in expected.entries)
        entry.key.value: _fingerprintOf(entry.value)
    },
  });
  return Map.unmodifiable({
    for (final event in expected.values)
      event.identity: SourceElevatorProgram._(
          source,
          profile.canonicalHash,
          event,
          _doors[(event.sourceMapId, event.sourceEventId)]?.$1 ??
              event.sourceMapId,
          _doors[(event.sourceMapId, event.sourceEventId)]?.$2 ??
              switch (event.sourceMapId) { 40 => 5, 177 => 3, _ => 11 },
          _doors[(event.sourceMapId, event.sourceEventId)]?.$3,
          _doors.containsKey((event.sourceMapId, event.sourceEventId))
              ? SourceElevatorRole.door
              : event.sourceEventId == 1
                  ? SourceElevatorRole.exit
                  : event.sourceEventId == 2
                      ? SourceElevatorRole.controller
                      : SourceElevatorRole.actor,
          familyHash,
          expected.keys.toSet())
  });
}

Iterable<SourceEventNode> sourceElevatorNodes(
    SourceEventDefinition event) sync* {
  Iterable<SourceEventNode> visit(SourceEventBlock block) sync* {
    for (final node in block.nodes) {
      yield node;
      if (node is SourceConditionalNode) {
        yield* visit(node.whenTrue);
        yield* visit(node.whenFalse);
      }
    }
  }

  for (final page in event.pages) {
    yield* visit(page.body);
  }
}

Object? _node(SourceEventNode node) => {
      'kind': node.runtimeType.toString(),
      'span': node.span.toJson(),
      'value': switch (node) {
        SourceForcedMoveRouteNode() => node.toJson(),
        SourceMoveRouteBarrierNode() => node.toJson(),
        SourcePlayerVisibilityNode() => node.toJson(),
        SourceTempSwitchNode() => node.toJson(),
        SourceToneNode() => node.toJson(),
        SourceWaitNode() => node.toJson(),
        SourceSoundEffectNode() => node.toJson(),
        SourceAnnotationNode() => node.toJson(),
        SourceVariableSetNode() => node.toJson(),
        SourceExitEventNode() => node.toJson(),
        SourceUnknownNode() => {
            'command': node.command.toJson(),
            'reason': node.reason
          },
        SourceScriptNode() => node.script,
        SourceWarpNode() => {
            'map': node.targetSourceMapId,
            'x': node.x,
            'y': node.y,
            'direction': node.direction,
            'fade': node.fade,
            'external': node.originalProgram?.toString()
          },
        SourceConditionalNode() => {
            'condition': node.condition.toJson(),
            'true': node.whenTrue.nodes.map(_node).toList(),
            'false': node.whenFalse.nodes.map(_node).toList()
          },
        _ => 'unsupported',
      }
    };

String _fingerprintOf(SourceEventDefinition event) => canonicalJsonOf({
      'identity': event.identity.value,
      'map': event.sourceMapId,
      'id': event.sourceEventId,
      'file': event.sourceFileId.value,
      'name': event.name,
      'x': event.x,
      'y': event.y,
      'locator': event.locator.toJson(),
      'pages': [
        for (final page in event.pages)
          {
            'source': page.sourcePage.toJson(),
            'raw': page.rawDataRef?.toJson(),
            'condition': page.condition.toJson(),
            'diagnostics': page.diagnostics.map((d) => d.toJson()).toList(),
            'bodyDiagnostics':
                page.body.diagnostics.map((d) => d.toJson()).toList(),
            'nodes': page.body.nodes.map(_node).toList(),
            'graphic': page.graphic == null
                ? null
                : {
                    'tile': page.graphic!.tileId,
                    'name': page.graphic!.characterName,
                    'hue': page.graphic!.hue,
                    'direction': page.graphic!.direction,
                    'pattern': page.graphic!.pattern,
                    'opacity': page.graphic!.opacity,
                    'blend': page.graphic!.blendType,
                    'move': page.graphic!.moveType,
                    'speed': page.graphic!.moveSpeed,
                    'frequency': page.graphic!.moveFrequency,
                    'walk': page.graphic!.walkAnime,
                    'step': page.graphic!.stepAnime,
                    'fix': page.graphic!.directionFix,
                    'through': page.graphic!.through,
                    'top': page.graphic!.alwaysOnTop,
                    'route': page.graphic!.moveRouteNodeId,
                  }
          }
      ]
    });
