import 'package:avelune_converter_core/avelune_converter_core.dart';

final class SourceCardKeyGateProgram {
  SourceCardKeyGateProgram._(NormalizedSourceProject source,
      SourceEventProfile profile, SourceEventDefinition event)
      : eventIdentity = event.identity,
        sourceSnapshotHash = source.snapshot.canonicalHash,
        normalizationHash = source.canonicalHash,
        profileHash = profile.canonicalHash,
        fingerprint = _fingerprint(event);

  final ConverterId eventIdentity;
  final Sha256Hash sourceSnapshotHash, normalizationHash, profileHash;
  final String fingerprint;

  bool isBoundTo(NormalizedSourceProject source, SourceEventAnalysis analysis,
          SourceEventDefinition event) =>
      analysis.profile.isQualified &&
      event.identity == eventIdentity &&
      source.snapshot.canonicalHash == sourceSnapshotHash &&
      source.canonicalHash == normalizationHash &&
      analysis.profile.canonicalHash == profileHash &&
      _matches(event) &&
      _fingerprint(event) == fingerprint;

  Map<String, Object?> toJson() => {
        'kind': 'sourceCardKeyGate',
        'eventIdentity': eventIdentity.value,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'programHash': canonicalHashOf(fingerprint).value,
        'collisionFootprint': {
          'width': 2,
          'height': 2,
          'sourceAnchor': 'bottomLeft'
        },
        'nativeContract':
            'inventoryItemConditionPersistentOwnSelfAAndEntityPresentation',
        'sourceScriptsExecuted': 0,
      };
}

Map<ConverterId, SourceCardKeyGateProgram> sourceCardKeyGatePrograms(
    {required NormalizedSourceProject source,
    required SourceEventAnalysis analysis}) {
  final profile = SourceEventProfile.forProject(source);
  if (!profile.isQualified ||
      profile.canonicalHash != analysis.profile.canonicalHash ||
      profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
      profile.normalizationHash != source.canonicalHash) {
    return const {};
  }
  final analyzer = SourceEventAnalyzer.forProject(source, profile: profile);
  return Map.unmodifiable({
    for (final event in analysis.events.where(_matches))
      if (analyzer.analyzeEventAt(event.sourceMapId, event.sourceEventId)
          case final original?
          when _fingerprint(original) == _fingerprint(event))
        event.identity: SourceCardKeyGateProgram._(source, profile, event),
  });
}

bool _matches(SourceEventDefinition event) {
  if (event.isQuarantined ||
      event.name != 'Silph Gate size(2,2)' ||
      event.pages.length != 2) {
    return false;
  }
  final closed = event.pages[0], open = event.pages[1];
  if (closed.originalPageIndex != 0 ||
      open.originalPageIndex != 1 ||
      closed.triggerCode != 0 ||
      open.triggerCode != 0 ||
      closed.rawDataRef == null ||
      open.rawDataRef == null ||
      closed.condition.kind != SourceEventConditionKind.always ||
      !open.isEmpty ||
      closed.body.nodes.length != 1 ||
      closed.body.nodes.single is! SourceConditionalNode) {
    return false;
  }
  final graphic = closed.graphic, empty = open.graphic;
  if (graphic == null ||
      empty == null ||
      !const {'OBJ_FRLG_Silph Gate_H', 'OBJ_FRLG_Silph Gate_V'}
          .contains(graphic.characterName) ||
      graphic.tileId != 0 ||
      graphic.hue != 0 ||
      graphic.direction != 2 ||
      graphic.pattern != 0 ||
      graphic.opacity != 255 ||
      graphic.blendType != 0 ||
      graphic.moveType != 0 ||
      graphic.stepAnime ||
      graphic.through ||
      graphic.alwaysOnTop ||
      empty.tileId != 0 ||
      empty.characterName.isNotEmpty ||
      empty.hue != 0 ||
      empty.opacity != 255 ||
      empty.blendType != 0 ||
      empty.moveType != 0 ||
      empty.stepAnime ||
      empty.directionFix ||
      !empty.through ||
      empty.alwaysOnTop) {
    return false;
  }
  const codes = [111, 250, 101, 250, 123, 0, 411, 101, 0, 412, 0];
  const indents = [0, 1, 1, 1, 1, 1, 0, 1, 1, 0, 0];
  final commands = closed.sourcePage.commands;
  if (commands.length != codes.length ||
      !List.generate(codes.length, (i) => i).every((i) =>
          commands[i].code == codes[i] &&
          commands[i].indent == indents[i] &&
          commands[i].originalIndex == i) ||
      !{
        canonicalJsonOf([12, r'$bag.has?(:CARDKEY)']),
        canonicalJsonOf([12, r'$bag.quantity(:CARDKEY)>0']),
      }.contains(canonicalJsonOf(commands.first.parameters)) ||
      open.sourcePage.commands.length != 1 ||
      open.sourcePage.commands.single.code != 0 ||
      open.sourcePage.commands.single.indent != 0 ||
      open.sourcePage.commands.single.parameters.isNotEmpty) {
    return false;
  }
  final branch = closed.body.nodes.single as SourceConditionalNode;
  if (branch.condition.kind != SourceEventConditionKind.itemPresence ||
      branch.condition.sourceItemSymbol != 'CARDKEY' ||
      !branch.condition.expectedValue ||
      branch.whenTrue.nodes.length != 4 ||
      branch.whenFalse.nodes.length != 1) {
    return false;
  }
  final yes = branch.whenTrue.nodes, no = branch.whenFalse.nodes.single;
  if (yes[0] is! SourceSoundEffectNode ||
      yes[1] is! SourceTextNode ||
      yes[2] is! SourceSoundEffectNode ||
      yes[3] is! SourceSelfSwitchNode ||
      no is! SourceTextNode) {
    return false;
  }
  final before = yes[0] as SourceSoundEffectNode,
      after = yes[2] as SourceSoundEffectNode;
  final text = yes[1] as SourceTextNode, flag = yes[3] as SourceSelfSwitchNode;
  bool own(SourceEventCondition c) =>
      c.kind == SourceEventConditionKind.selfSwitch &&
      c.expectedValue &&
      c.factId == flag.factId;
  final openCondition = open.condition;
  return before.name == 'ItemGet' &&
      before.volume == 100 &&
      before.pitch == 100 &&
      after.name == 'frlg_gateopen' &&
      after.volume == 100 &&
      after.pitch == 100 &&
      text.text == r'Bingo!\nThe Card Key opened the door!\wtnp[35]' &&
      text.followingChoice == null &&
      text.annotations.isEmpty &&
      no.text == r'No!\nIt needs a Card Key!' &&
      no.followingChoice == null &&
      no.annotations.isEmpty &&
      flag.letter == 'A' &&
      flag.value &&
      (own(openCondition) ||
          openCondition.kind == SourceEventConditionKind.all &&
              openCondition.children.length == 1 &&
              own(openCondition.children.single));
}

String _fingerprint(SourceEventDefinition event) => canonicalJsonOf({
      'identity': event.identity.value,
      'file': event.sourceFileId.value,
      'map': event.sourceMapId,
      'event': event.sourceEventId,
      'name': event.name,
      'x': event.x,
      'y': event.y,
      'locator': event.locator.toJson(),
      'pages': [
        for (final page in event.pages)
          {
            'raw': page.sourcePage.toJson(),
            'ref': page.rawDataRef?.toJson(),
            'locator': page.locator.toJson(),
            'condition': page.condition.toJson(),
            'graphic': page.graphic == null
                ? null
                : [
                    page.graphic!.tileId,
                    page.graphic!.characterName,
                    page.graphic!.hue,
                    page.graphic!.direction,
                    page.graphic!.pattern,
                    page.graphic!.opacity,
                    page.graphic!.blendType,
                    page.graphic!.moveType,
                    page.graphic!.moveSpeed,
                    page.graphic!.moveFrequency,
                    page.graphic!.walkAnime,
                    page.graphic!.stepAnime,
                    page.graphic!.directionFix,
                    page.graphic!.through,
                    page.graphic!.alwaysOnTop,
                    page.graphic!.moveRouteNodeId
                  ],
            'body': _body(page.body),
          }
      ],
    });
Object _body(SourceEventBlock block) => {
      'span': block.span.toJson(),
      'nodes': [
        for (final node in block.nodes)
          {
            'span': node.span.toJson(),
            'kind': node.runtimeType.toString(),
            'value': switch (node) {
              SourceConditionalNode() => {
                  'condition': node.condition.toJson(),
                  'yes': _body(node.whenTrue),
                  'no': _body(node.whenFalse)
                },
              SourceSoundEffectNode() => node.toJson(),
              SourceTextNode() => {
                  'text': node.text,
                  'annotations': node.annotations,
                  'choice': node.followingChoice == null ? null : 'refused'
                },
              SourceSelfSwitchNode() => {
                  'letter': node.letter,
                  'value': node.value,
                  'fact': node.factId
                },
              _ => 'refused',
            }
          }
      ]
    };
