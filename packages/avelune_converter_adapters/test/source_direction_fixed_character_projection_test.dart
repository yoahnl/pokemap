import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';

List<int> _characterAtlas({int width = 128, int height = 128}) {
  final raster = image.Image(width: width, height: height, numChannels: 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      raster.setPixelRgba(x, y, x, y, (x + y) % 256, 255);
    }
  }
  return image.encodePng(raster);
}

Future<({SourceEventProjection projection, List<SourceEventCharacterImport> imported})> _project({
  List<LiteralFixtureEventPage>? pages,
  String corrupt = '',
  String name = 'Original fixed NPC',
  bool forge = false,
  bool forgeDirection = false,
  bool forgeFixed = false,
  bool passiveBarrier = false,
}) async {
  final sizeMatch = RegExp(r'size\((\d+),(\d+)\)').firstMatch(name);
  final footprint = passiveBarrier ? GridSize(width: int.parse(sizeMatch!.group(1)!), height: int.parse(sizeMatch.group(2)!)) : null;
  final fixture = await LiteralTileFixture.create(
      scriptsBytes: syntheticInterpretationArchive,
      interpretationProfile: syntheticSourceInterpretationProfile,
      includeEventSystem: true,
      extraFiles: {'Graphics/Characters/Fixed.png': _characterAtlas(width: (footprint?.width ?? 1) * 128, height: (footprint?.height ?? 1) * 128)},
      maps: [LiteralFixtureMap(id: 1, width: 8, height: 8,
        layers: [List.filled(64, 384), List.filled(64, 0), List.filled(64, 0)],
        events: [LiteralFixtureEvent(id: 1, x: 1, y: passiveBarrier ? 6 : 2, name: name, pages: pages ?? const [
          LiteralFixtureEventPage(characterName: 'Fixed', directionFix: true,
            direction: 6, pattern: 2, commands: [LiteralFixtureEventCommand(101, ['Fixed pose.'])]),
        ])])]);
  final original = SourceEventAnalyzer.forProject(fixture.source,
      profile: SourceEventProfile.forProject(fixture.source)).analyze();
  final owner = original.events.single;
  final analysis = !forge && !forgeDirection && !forgeFixed ? original : SourceEventAnalysis(profile: original.profile,
      diagnostics: original.diagnostics, events: [SourceEventDefinition(
        identity: owner.identity, sourceFileId: owner.sourceFileId,
        sourceMapId: owner.sourceMapId, sourceEventId: owner.sourceEventId,
        name: forge ? '${owner.name} forged' : owner.name, x: owner.x, y: owner.y,
        locator: owner.locator, pages: [for (final page in owner.pages)
          SourceEventPageAnalysis(sourcePage: page.sourcePage, locator: page.locator,
            condition: page.condition, body: page.body, rawDataRef: page.rawDataRef,
            diagnostics: page.diagnostics,
            graphic: !forgeDirection && !forgeFixed ? page.graphic : SourceEventGraphic(
              tileId: page.graphic!.tileId, characterName: page.graphic!.characterName,
              hue: page.graphic!.hue, direction: forgeDirection ? 4 : page.graphic!.direction,
              pattern: page.graphic!.pattern, opacity: page.graphic!.opacity,
              blendType: page.graphic!.blendType, moveType: page.graphic!.moveType,
              moveSpeed: page.graphic!.moveSpeed, moveFrequency: page.graphic!.moveFrequency,
              walkAnime: page.graphic!.walkAnime, stepAnime: page.graphic!.stepAnime,
              directionFix: forgeFixed || page.graphic!.directionFix,
              through: page.graphic!.through, alwaysOnTop: page.graphic!.alwaysOnTop,
              moveRouteNodeId: page.graphic!.moveRouteNodeId))])]);
  final imported = <SourceEventCharacterImport>[];
  final bindings = <String, SourceEventCharacterBinding>{};
  for (final page in analysis.events.single.pages) {
    final graphic = page.graphic!;
    if (graphic.characterName.isEmpty) continue;
    final character = await const SourceEventCharacterImporter().read(
      snapshot: fixture.snapshot, files: fixture.files, charsetName: graphic.characterName,
      sourcePattern: graphic.pattern, sourceDirection: graphic.direction,
      fixedDirection: graphic.directionFix, stationaryFootprint: footprint);
    imported.add(character);
    final binding = character.binding;
    bindings[character.bindingKey] = SourceEventCharacterBinding(
      characterId: corrupt == 'character' ? 'ordinary-character' : binding.characterId,
      sourceSnapshotHash: corrupt == 'snapshot' ? Sha256Hash('0' * 64) : binding.sourceSnapshotHash,
      sourceFileId: corrupt == 'file' ? ConverterId('missing-source') : binding.sourceFileId,
      sourceFileHash: corrupt == 'hash' ? Sha256Hash('0' * 64) : binding.sourceFileHash,
      sourcePattern: corrupt == 'pattern' ? 0 : binding.sourcePattern,
      sourceDirection: corrupt == 'direction' ? 2 : binding.sourceDirection,
      fixedDirection: corrupt == 'fixed' ? false : binding.fixedDirection);
  }
  return (projection: const SourceEventProjector().project(source: fixture.source,
    analysis: analysis, nativeMaps: {1: MapData(id: 'map', name: 'Map', size: const GridSize(width: 8, height: 8))},
    characterBindings: bindings), imported: imported);
}

List<Object?> _gaps(SourceEventProjection result) =>
    ((result.semanticEvidence['events'] as List).single as Map)['gaps'] as List;

List<LiteralFixtureEventCommand> _route(int code) {
  final step = LiteralFixtureObject('RPG::MoveCommand', {'@code': code, '@parameters': <Object?>[]});
  return [LiteralFixtureEventCommand(209, [0, LiteralFixtureObject('RPG::MoveRoute', {
    '@repeat': false, '@skippable': false, '@list': [step,
      const LiteralFixtureObject('RPG::MoveCommand', {'@code': 0, '@parameters': <Object?>[]})],
  })]), LiteralFixtureEventCommand(509, [step]), const LiteralFixtureEventCommand(210, [])];
}

Future<SourceEventStudyComposition> _compose({String parentPath = '/private/tmp'}) async {
  final fixture = await LiteralTileFixture.create(
    scriptsBytes: syntheticInterpretationArchive,
    interpretationProfile: syntheticSourceInterpretationProfile,
    includeEventSystem: true,
    extraFiles: {
      'Graphics/Characters/Fixed.png': _characterAtlas(),
      'Graphics/Characters/Player.png': literalFixtureAtlas(),
      'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = Player\n'),
    },
    maps: [LiteralFixtureMap(id: 1, width: 3, height: 3,
      layers: [List.filled(9, 384), List.filled(9, 0), List.filled(9, 0)],
      events: const [LiteralFixtureEvent(id: 1, x: 1, y: 1, pages: [
        LiteralFixtureEventPage(characterName: 'Fixed', directionFix: true,
            direction: 6, pattern: 2, commands: [
              LiteralFixtureEventCommand(101, ['I keep looking east.']),
            ]),
      ])])],
  );
  final literal = await const LiteralTileComposer().compose(source: fixture.source,
      files: fixture.files, selectedSourceMapIds: [1], projectName: 'Fixed pose',
      parentPath: parentPath, folderName: 'fixed-pose');
  final semantic = (await const SourceSemanticStudyComposer().compose(
      source: fixture.source, base: literal, files: fixture.files))!;
  return (await const SourceEventStudyComposer().compose(source: fixture.source,
      base: semantic, files: fixture.files))!;
}

Future<SourceEventStudyComposition> _composeSharedBarrier({required bool invalidFirst, String parentPath = '/private/tmp', bool barrierOnly = false}) async {
  final fixture = await LiteralTileFixture.create(
    scriptsBytes: syntheticInterpretationArchive,
    interpretationProfile: syntheticSourceInterpretationProfile,
    includeEventSystem: true,
    extraFiles: {
      'Graphics/Characters/Fixed.png': _characterAtlas(width: 384, height: 256),
      'Graphics/Characters/Player.png': literalFixtureAtlas(),
      'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = Player\n'),
    },
    maps: [LiteralFixtureMap(id: 1, width: 8, height: 8,
      layers: [List.filled(64, 384), List.filled(64, 0), List.filled(64, 0)],
      events: [
        for (var id = 1; id <= 2; id++)
          if (!barrierOnly || id != (invalidFirst ? 1 : 2))
          LiteralFixtureEvent(id: id, x: id == (invalidFirst ? 1 : 2) ? 6 : 1,
            y: 6, name: id == (invalidFirst ? 1 : 2) ? 'Small footprint' : 'Barrier size(3,2)',
            pages: const [LiteralFixtureEventPage(characterName: 'Fixed',
              directionFix: true, direction: 6, pattern: 2, walkAnime: false, commands: [])]),
      ])],
  );
  final literal = await const LiteralTileComposer().compose(source: fixture.source,
      files: fixture.files, selectedSourceMapIds: [1], projectName: 'Shared barrier',
      parentPath: parentPath, folderName: 'shared-barrier');
  final semantic = (await const SourceSemanticStudyComposer().compose(
      source: fixture.source, base: literal, files: fixture.files))!;
  return (await const SourceEventStudyComposer().compose(source: fixture.source,
      base: semantic, files: fixture.files))!;
}

void main() {
  test('a rejected small use cannot suppress the valid shared barrier in either source order', () async {
    final results = [
      await _composeSharedBarrier(invalidFirst: true),
      await _composeSharedBarrier(invalidFirst: false),
    ];
    final characters = <String>[];
    for (var index = 0; index < results.length; index++) {
      final projection = results[index].projection;
      final eventId = index == 0 ? 2 : 1;
      final row = (projection.semanticEvidence['events'] as List).cast<Map>()
          .singleWhere((row) => row['locator']['eventId'] == eventId);
      expect(row['status'], 'adaptedStaticSemantics');
      expect(row['gaps'], isEmpty);
      final entity = projection.nativeMaps[1]!.entities.singleWhere((entity) =>
          entity.properties['sourceEventIdentity'] == row['sourceIdentity']);
      expect(entity.size, const GridSize(width: 3, height: 2));
      expect(entity.pos, const GridPos(x: 1, y: 5));
      expect(entity.blocksMovement, isTrue);
      expect(entity.properties[mapEntityCollisionWidthProperty], '3');
      expect(entity.properties[mapEntityCollisionHeightProperty], '2');
      characters.add(entity.npc!.characterId!);
    }
    expect(characters.toSet(), hasLength(1));
  });

  test('a passive barrier is written and strictly reopened without an empty narrative program', () async {
    final temporary = await Directory.systemTemp.createTemp('source-passive-barrier-');
    addTearDown(() => temporary.delete(recursive: true));
    final result = await _composeSharedBarrier(invalidFirst: true, parentPath: temporary.path, barrierOnly: true);
    expect(result.projection.scenes, isEmpty);
    expect(result.projection.registry.records, isEmpty);
    final approval = approveNativeFixtureDraft(result.draft);
    final receipt = await NativeProjectWriter().write(approval.plan, approval.context, result.draft);
    expect(receipt.verified, isTrue);
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
    final opener = ProjectOpenService(policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(receipt.projectPath);
    ProjectSnapshot? native;
    try {
      native = await ProjectSnapshotLoader(handles: handles).load(opened.projectHandle,
          policy: ProjectSnapshotLoadPolicy.strict);
      expect(native.loadDiagnostics, isEmpty);
      final expected = result.projection.nativeMaps[1]!.entities.singleWhere((entity) => entity.name.contains('Barrier'));
      final entity = native.mapById(result.draft.mapIds[1]!)!.entities.singleWhere((entity) => entity.id == expected.id);
      expect(resolveEntityCollisionCells(entity), hasLength(6));
      expect(entity.presentation!.variants.single.blocksMovement, isTrue);
      final character = native.manifest.characters.singleWhere((entry) => entry.id == entity.npc!.characterId);
      expect(character.frameWidth, 3);
      expect(character.frameHeight, 2);
      expect(native.manifest.scenes, isEmpty);
      expect(native.manifest.eventRegistry!.records, isEmpty);
    } finally {
      await native?.payloadOwner?.release();
      opener.closeWorkspace(opened.workspaceHandle);
    }
  });

  test('all four native facings render the exact original fixed frame and keep distinct identities', () async {
    final result = await _project();
    final imported = result.imported.single;
    expect(_gaps(result.projection), isEmpty);
    expect(imported.character.animations.map((clip) => clip.direction).toSet(), EntityFacing.values.toSet());
    final atlas = image.decodePng(Uint8List.fromList(imported.outputBytes))!;
    final original = image.decodePng(Uint8List.fromList(imported.imageBytes))!;
    for (final clip in imported.character.animations) {
      expect(clip.frames.single.source, const TilesetSourceRect(x: 128, y: 128, width: 64, height: 64));
      expect(clip.state, CharacterAnimationState.idle);
      expect(clip.loop, isFalse);
      final pixel = atlas.getPixel(128 + imported.sourceOffsetXPx + 1, 128 + imported.sourceOffsetYPx + 1);
      final before = original.getPixel(2 * imported.frameWidthPx + 1, 2 * imported.frameHeightPx + 1);
      expect([pixel.r, pixel.g, pixel.b, pixel.a], [before.r, before.g, before.b, before.a]);
    }
    final evidence = (result.projection.semanticEvidence['events'] as List).single as Map;
    expect((evidence['nativeFixedDirectionPresentation'] as Map)['nativeFacingStateLocked'], isFalse);
    expect(imported.binding.fixedDirection, isTrue);
  });

  for (final corrupt in ['character', 'snapshot', 'file', 'hash', 'pattern', 'direction', 'fixed']) {
    test('fixed pose refuses a mismatched $corrupt binding', () async {
      final result = await _project(corrupt: corrupt);
      expect(_gaps(result.projection), contains('characterBindingMissing'));
      expect(result.projection.nativeMaps[1]!.entities, isEmpty);
    });
  }

  test('fixed presentation refuses a forged source owner', () async {
    final result = await _project(forge: true);
    expect(_gaps(result.projection), contains('pageGraphicContractUnsupported'));
  });

  test('fixed presentation refuses a forged source direction with a matching forged binding', () async {
    final result = await _project(forgeDirection: true);
    expect(_gaps(result.projection), contains('pageGraphicContractUnsupported'));
  });

  test('fixed presentation refuses directionFix invented outside the raw source', () async {
    final result = await _project(forgeFixed: true, pages: const [
      LiteralFixtureEventPage(characterName: 'Fixed', direction: 6, pattern: 2,
          commands: [LiteralFixtureEventCommand(101, ['Source is not fixed.'])]),
    ]);
    expect(_gaps(result.projection), contains('pageGraphicContractUnsupported'));
  });

  for (final config in [(0, 1), (1, 0), (2, 0), (3, 0), (4, 0)]) {
    test('fixed presentation refuses trigger=${config.$1} moveType=${config.$2}', () async {
      final result = await _project(pages: [LiteralFixtureEventPage(characterName: 'Fixed',
          directionFix: true, trigger: config.$1, moveType: config.$2,
          commands: const [LiteralFixtureEventCommand(101, ['Not stationary action.'])])]);
      expect(_gaps(result.projection), isNotEmpty);
    });
  }

  for (final size in [const GridSize(width: 3, height: 2), const GridSize(width: 1, height: 5)]) {
    test('passive fixed barrier preserves its complete ${size.width} by ${size.height} collision', () async {
      final result = await _project(name: 'Gate size(${size.width},${size.height})', passiveBarrier: true,
        pages: const [
          LiteralFixtureEventPage(characterName: 'Fixed', directionFix: true, walkAnime: false, commands: []),
          LiteralFixtureEventPage(globalSwitch: 1, commands: []),
        ]);
      expect(_gaps(result.projection), isEmpty);
      final entity = result.projection.nativeMaps[1]!.entities.single;
      expect(entity.size, size);
      expect(entity.pos, GridPos(x: 1, y: 7 - size.height));
      expect(entity.properties[mapEntityCollisionWidthProperty], '${size.width}');
      expect(entity.properties[mapEntityCollisionHeightProperty], '${size.height}');
      expect(entity.presentation!.variants.map((page) => page.blocksMovement), [false, true]);
      expect(result.projection.scenes, isEmpty);
      expect(result.projection.registry.records, isEmpty);
      expect(result.projection.mutations.where((mutation) => mutation.actionId == 'scene.upsert' || mutation.actionId == 'event_v2.record_upsert_batch'), isEmpty);
    });
  }

  for (final size in ['size(2,1)', 'size(1,2)']) {
    test('fixed presentation leaves the unsupported $size collision footprint inactive', () async {
      final result = await _project(name: 'Barrier $size');
      expect(_gaps(result.projection), contains('pageGraphicContractUnsupported'));
    });
  }

  for (final code in [1, 16, 19, 25, 35, 36]) {
    test('fixed presentation refuses source route command $code', () async {
      final result = await _project(pages: [LiteralFixtureEventPage(characterName: 'Fixed',
          directionFix: true, commands: [const LiteralFixtureEventCommand(101, ['Before route.']), ..._route(code)])]);
      expect(_gaps(result.projection), contains('pageGraphicContractUnsupported'));
    });
  }

  for (final commands in [
    [const LiteralFixtureEventCommand(201, [0, 1, 2, 0, 0, 1])],
    [const LiteralFixtureEventCommand(355, ['get_character(0).turn_toward_player'])],
    [const LiteralFixtureEventCommand(111, [6, 0, 2]), const LiteralFixtureEventCommand(101, ['Facing.'], indent: 1), const LiteralFixtureEventCommand(412, [])],
    [const LiteralFixtureEventCommand(117, [1])],
    [const LiteralFixtureEventCommand(301, [0, 1, false, false])],
  ]) {
    test('fixed presentation refuses nonlocal or orientation-sensitive command ${commands.first.code}', () async {
      final result = await _project(pages: [LiteralFixtureEventPage(characterName: 'Fixed', directionFix: true, commands: commands)]);
      expect(_gaps(result.projection), isNotEmpty);
      expect(result.projection.nativeMaps[1]!.entities, isEmpty);
    });
  }

  test('fixed multipage choices retain flags and per-page fixed graphics', () async {
    final result = await _project(pages: const [
      LiteralFixtureEventPage(characterName: 'Fixed', directionFix: true, direction: 4, commands: [
        LiteralFixtureEventCommand(101, ['Change state?']),
        LiteralFixtureEventCommand(102, [['Yes', 'No'], 2]),
        LiteralFixtureEventCommand(402, [0, 'Yes']),
        LiteralFixtureEventCommand(123, ['A', 0], indent: 1),
        LiteralFixtureEventCommand(402, [1, 'No']),
        LiteralFixtureEventCommand(101, ['No change.'], indent: 1),
        LiteralFixtureEventCommand(404, []),
      ]),
      LiteralFixtureEventPage(characterName: 'Fixed', directionFix: true, direction: 6, selfSwitch: 'A',
          commands: [LiteralFixtureEventCommand(101, ['Changed state.'])]),
    ]);
    expect(_gaps(result.projection), isEmpty);
    expect(result.imported.map((entry) => entry.character.id).toSet(), hasLength(2));
    final entity = result.projection.nativeMaps[1]!.entities.single;
    expect(entity.blocksMovement, isTrue);
    expect(entity.presentation!.variants.map((v) => v.characterId).toSet(), hasLength(2));
    expect(entity.presentation!.variants.map((v) => v.facing).toSet(), {EntityFacing.west, EntityFacing.east});
  });

  test('a source-fixed ordinary dialogue is enabled with an editable fixed-pose character', () async {
    final temporary = await Directory.systemTemp.createTemp('source-fixed-character-');
    addTearDown(() => temporary.delete(recursive: true));
    final result = await _compose(parentPath: temporary.path);
    final rows = (result.projection.semanticEvidence['events'] as List).cast<Map>();
    expect(rows.single['gaps'], isEmpty);
    expect(rows.single['status'], 'adaptedStaticSemantics');
    final entity = result.projection.nativeMaps[1]!.entities.singleWhere((e) =>
        e.properties['sourceEventIdentity'] == rows.single['sourceIdentity']);
    expect(entity.npc!.facing, EntityFacing.east);
    final creates = result.draft.mutations.where((m) => m.actionId == 'characterStudio.character.create' &&
        m.targetEntityIds.any((id) => id.value == entity.npc!.characterId));
    expect(creates, hasLength(1));
    final approval = approveNativeFixtureDraft(result.draft);
    final receipt = await NativeProjectWriter().write(approval.plan, approval.context, result.draft);
    expect(receipt.verified, isTrue);
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
    final opener = ProjectOpenService(policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(receipt.projectPath);
    ProjectSnapshot? native;
    try {
      native = await ProjectSnapshotLoader(handles: handles).load(opened.projectHandle,
          policy: ProjectSnapshotLoadPolicy.strict);
      expect(native.loadDiagnostics, isEmpty);
      final character = native.manifest.characters.singleWhere((entry) => entry.id == entity.npc!.characterId);
      expect(character.animations, hasLength(4));
      for (final clip in character.animations) {
        expect(clip.frames.single.source, const TilesetSourceRect(x: 128, y: 128, width: 64, height: 64));
      }
      final map = native.mapById(result.draft.mapIds[1]!)!;
      expect(map.entities.singleWhere((entry) => entry.id == entity.id).npc!.characterId, character.id);
      expect(native.manifest.eventRegistry!.records.where((record) => record.enabledOrNull == true), hasLength(1));
    } finally {
      await native?.payloadOwner?.release();
      opener.closeWorkspace(opened.workspaceHandle);
    }
  });
}
