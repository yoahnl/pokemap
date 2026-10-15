part of '../avelune_converter_core.dart';

final class SourceHealingDisplayProgram {
  SourceHealingDisplayProgram._({
    required this.sourceSnapshotHash,
    required this.profileHash,
    required List<SourcePreservedData> pages,
  }) : pages = List.unmodifiable(pages);

  final Sha256Hash sourceSnapshotHash, profileHash;
  final List<SourcePreservedData> pages;
  int get sourceVariableId => 6;
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
        'sourceWaitMilliseconds': 2900,
        'sourceFrameMilliseconds': 125,
        'sourceFrameSize': [64, 48],
        'sourceAnchor': 'bottomCenter',
        'sourceNurseEventId': 2,
        'sourceProgramRecognized': true,
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

const _sourceHealingDisplayPageHashes = [
  'b36d0f29ceb29f382c067a3f422aa68644b6521ed07d65fd19cd05a64bcdc8b4',
  'b23fd8a2bccaaa3ab300c245d71fa0ab014b2740f2523b9191ee52ffaec00523',
  '820280a6451f32066ba023241115f651557f1ce5b109abcee7619b09c8da2665',
  '488415f22c2245ac3aa28be05206ff246e0b04cb0e8effd1359d7dd04fd63e2c',
  '2599091f4d9e104aa07cad688b1ed61b0beab2df5a98f49fee8d8c2e7400a45c',
  '82df1d507991db75f39f18bad3df3db4e923d4fc751b021855da8f3eb7a781bb',
  'a5cff7890bff0eb4d4add8496cea7a869e80558bad11573fea917ce43aeb8601',
];

SourceHealingDisplayProgram? resolveSourceHealingDisplayProgram({
  required NormalizedSourceProject source,
  required SourceEventProfile profile,
  required int sourceMapId,
  required SourceEvent event,
}) {
  final analyzer = SourceEventAnalyzer.forProject(source, profile: profile);
  if (!analyzer._isQualified ||
      sourceMapId != 102 ||
      event.sourceEventId != 4 ||
      event.name != 'Healing balls' ||
      (event.x, event.y) != (7, 4) ||
      event.pages.length != 7) {
    return null;
  }
  try {
    final refs = <SourcePreservedData>[];
    for (var index = 0; index < 7; index++) {
      final page = event.pages[index];
      if (page.originalPageIndex != index ||
          page.triggerCode != 0 ||
          page.commands.length != 1) {
        return null;
      }
      final command = page.commands.single;
      if (command.originalIndex != 0 ||
          command.code != 0 ||
          command.indent != 0 ||
          command.parameters.isNotEmpty) {
        return null;
      }
      final reference = analyzer._reference(page.rawDataRef);
      if (reference == null) {
        return null;
      }
      final file = source.archive.files[reference.fileId];
      if (file == null || file.entry.relativePath != 'Data/Map102.rxdata') {
        return null;
      }
      final document = file.document;
      final rawMap = _eventFields(document, document.rootId, 'RPG::Map');
      final rawEvents = document.node(_eventField(rawMap, '@events'));
      if (rawEvents.kind != MarshalKind.hash ||
          rawEvents.defaultValue != null ||
          rawEvents.extensions.isNotEmpty ||
          rawEvents.userClass != null ||
          rawEvents.instanceVariables.isNotEmpty) {
        return null;
      }
      final matches = rawEvents.pairs
          .where((pair) => _eventInt(document, pair.key) == 4)
          .toList();
      if (matches.length != 1) {
        return null;
      }
      final rawEvent =
          _eventFields(document, matches.single.value, 'RPG::Event');
      if (rawEvent.length != 5 ||
          !rawEvent.keys
              .every(const {'@id', '@name', '@x', '@y', '@pages'}.contains) ||
          _eventInt(document, _eventField(rawEvent, '@id')) != 4 ||
          _eventLiteralText(document, _eventField(rawEvent, '@name')) !=
              event.name ||
          _eventInt(document, _eventField(rawEvent, '@x')) != event.x ||
          _eventInt(document, _eventField(rawEvent, '@y')) != event.y) {
        return null;
      }
      final rawPages = document.node(_eventField(rawEvent, '@pages'));
      if (rawPages.kind != MarshalKind.array ||
          rawPages.elements.length != 7 ||
          rawPages.elements[index] != reference.nodeId ||
          rawPages.extensions.isNotEmpty ||
          rawPages.userClass != null ||
          rawPages.instanceVariables.isNotEmpty) {
        return null;
      }
      final value = _SourceCenterPageValue(document).read(reference.nodeId);
      if (value is! Map ||
          value['list'] is! List ||
          (value['list'] as List).length != 1 ||
          canonicalHashOf(value).value !=
              _sourceHealingDisplayPageHashes[index]) {
        return null;
      }
      final locator = _eventLocator('Data/Map102.rxdata', 102, 4, index);
      final condition = analyzer._reference(page.conditionsDataRef);
      if (condition == null ||
          condition.fileId != reference.fileId ||
          condition.nodeId !=
              _eventField(
                  _eventFields(document, reference.nodeId, 'RPG::Event::Page'),
                  '@condition') ||
          canonicalJsonOf(condition.locator?.toJson()) !=
              canonicalJsonOf(locator.toJson())) {
        return null;
      }
      final parser = _SourceEventParser(analyzer, page.commands, locator, 102,
          4, analyzer._switchNames(), reference);
      if (parser._rawFacingParameters(command, 0).isNotEmpty) {
        return null;
      }
      refs.add(reference);
    }
    final maps =
        source.maps.where((map) => map.map.sourceMapId == 102).toList();
    if (maps.length != 1) {
      return null;
    }
    final nurses = maps.single.map.events
        .where((event) => event.sourceEventId == 2)
        .toList();
    if (nurses.length != 1 || nurses.single.pages.length != 2) {
      return null;
    }
    for (final page in nurses.single.pages) {
      final block = _sourceCenterServiceBlock(
          analyzer,
          102,
          nurses.single,
          page,
          _eventLocator('Data/Map102.rxdata', 102, 2, page.originalPageIndex));
      if (block == null ||
          block.nodes.length != 1 ||
          block.nodes.single is! SourceCenterServiceProgramNode ||
          (block.nodes.single as SourceCenterServiceProgramNode).isPc) {
        return null;
      }
    }
    return SourceHealingDisplayProgram._(
        sourceSnapshotHash: source.snapshot.canonicalHash,
        profileHash: profile.canonicalHash,
        pages: refs);
  } on FormatException {
    return null;
  }
}
