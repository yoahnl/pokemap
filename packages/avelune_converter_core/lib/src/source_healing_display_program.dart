part of '../avelune_converter_core.dart';

final class SourceHealingDisplayProgram {
  SourceHealingDisplayProgram._({
    required this.sourceSnapshotHash,
    required this.profileHash,
    required List<SourcePreservedData> pages,
    required this.sourceMapId,
    required this.sourceEventId,
    required this.sourceNurseEventId,
    required this.sourceVariableId,
    required this.sourceWaitMilliseconds,
    required this.x,
    required this.y,
    required this.declaredProgram,
  }) : pages = List.unmodifiable(pages);

  final Sha256Hash sourceSnapshotHash, profileHash;
  final List<SourcePreservedData> pages;
  final int sourceMapId,
      sourceEventId,
      sourceNurseEventId,
      sourceVariableId,
      sourceWaitMilliseconds,
      x,
      y;
  final SourceDeclaredProgramMatch declaredProgram;
  bool get nativeExecutionQualified => false;

  bool isBoundToSourceEvent({
    required NormalizedSourceProject source,
    required SourceEventProfile profile,
    required int sourceMapId,
    required SourceEvent event,
  }) {
    final resolved = resolveSourceHealingDisplayProgram(
      source: source,
      profile: profile,
      sourceMapId: sourceMapId,
      event: event,
    );
    return resolved != null &&
        canonicalJsonOf(resolved.toJson()) == canonicalJsonOf(toJson());
  }

  Map<String, Object?> toJson() => {
        'kind': 'healingDisplayProgram',
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'profileHash': profileHash.value,
        'pages': [for (final page in pages) page.toJson()],
        'sourceVariableId': sourceVariableId,
        'sourceCount': 'pokemon_count_excluding_eggs_including_fainted',
        'sourceWaitMilliseconds': sourceWaitMilliseconds,
        'sourceAnchor': 'bottomCenter',
        'sourceNurseEventId': sourceNurseEventId,
        'sourceProgramRecognized': true,
        'sourceMapId': sourceMapId,
        'sourceEventId': sourceEventId,
        'x': x,
        'y': y,
        'recognition': declaredProgram.toJson(),
        'nativeExecutionQualified': false,
        'fullSourceParityQualified': false,
        'sourceScriptsExecuted': 0,
        'requiredBindings': [
          'nativeNonblockingHealingDisplay',
          'sixNativeAnimatedElements',
          'sourceMachineCollisionPreserved',
          'qualifiedNativeNurseChoiceAndRecovery',
          'nativeActualPartyCount',
          'nativeApplyingLifetime',
          'nativeDurablePartyHealAndCheckpoint'
        ],
        'adaptedSourceEffects': [
          'sourceHealsBeforeAnimationNativeCommitsAfterPresentation',
          'nativeShowsActualMemberCountSimultaneously',
          'nativeHasNoEggState',
          'sourcePlacementBallShakeSoundsNotImported',
          'sourceRecoveryMusicKeptOnceInCompletionScene'
        ],
      };
}

SourceHealingDisplayProgram? resolveSourceHealingDisplayProgram(
    {required NormalizedSourceProject source,
    required SourceEventProfile profile,
    required int sourceMapId,
    required SourceEvent event}) {
  final match = matchSourceDeclaredProgram(
      source: source,
      profile: profile,
      sourceMapId: sourceMapId,
      event: event,
      families: const {SourceDeclaredProgramFamily.healingDisplay});
  if (match == null) return null;
  final variables = <int>{};
  for (var count = 0; count <= 6; count++) {
    final value = match.pageValues[match.indexForRole('count$count')]!;
    final commands = value['list'] as List;
    final condition = value['condition'] as Map;
    if (value['trigger'] != 0 ||
        commands.length != 1 ||
        (commands.single as Map)['code'] != 0 ||
        canonicalJsonOf((commands.single as Map)['parameters']) != '[]' ||
        condition['switch1_valid'] != false ||
        condition['switch2_valid'] != false ||
        condition['self_switch_valid'] != false ||
        condition['variable_valid'] != (count > 0) ||
        count > 0 && condition['variable_value'] != count ||
        condition['variable_id'] is! int) {
      return null;
    }
    if (count > 0) variables.add(condition['variable_id'] as int);
  }
  if (variables.length != 1 || variables.single < 1) return null;
  final map =
      source.maps.where((m) => m.map.sourceMapId == sourceMapId).singleOrNull;
  if (map == null) return null;
  final nurses = <SourceEvent>[];
  for (final candidate in map.map.events) {
    final nurse = matchSourceDeclaredProgram(
        source: source,
        profile: profile,
        sourceMapId: sourceMapId,
        event: candidate,
        families: const {SourceDeclaredProgramFamily.centerNurse});
    if (nurse == null) continue;
    final values =
        nurse.pageValues.values.expand((p) => p['list'] as List).cast<Map>();
    final routes = values
        .where((c) => c['code'] == 209)
        .map((c) => c['parameters'] as List);
    final writes = values
        .where((c) => c['code'] == 122)
        .map((c) => c['parameters'] as List);
    if (routes.any((p) => p.length == 2 && p.first == event.sourceEventId) &&
        writes.any((p) =>
            p.length >= 2 &&
            p[0] == variables.single &&
            p[1] == variables.single)) {
      nurses.add(candidate);
    }
  }
  if (nurses.length != 1) return null;
  final nurse = matchSourceDeclaredProgram(source: source, profile: profile, sourceMapId: sourceMapId,
      event: nurses.single, families: const {SourceDeclaredProgramFamily.centerNurse})!;
  final waits = (nurse.binding.parameters['recoveryWaitCommandIndices'] as Map).entries.map((entry) =>
      (_declaredCommand(nurse, entry.key as String, entry.value)['parameters'] as List).single as int).toSet();
  if (waits.length != 1) return null;
  return SourceHealingDisplayProgram._(
      sourceSnapshotHash: source.snapshot.canonicalHash,
      profileHash: profile.canonicalHash,
      pages: [
        for (var count = 0; count <= 6; count++)
          match.references[match.indexForRole('count$count')]!
      ],
      sourceMapId: sourceMapId,
      sourceEventId: event.sourceEventId,
      sourceNurseEventId: nurses.single.sourceEventId,
      sourceVariableId: variables.single,
      sourceWaitMilliseconds: waits.single * 50,
      x: event.x,
      y: event.y,
      declaredProgram: match);
}
