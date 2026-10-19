import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';

List<int> _atlas(int width, int height) {
  final raster = image.Image(width: width, height: height, numChannels: 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      raster.setPixelRgba(x, y, x % 256, y % 256, 83, 255);
    }
  }
  return image.encodePng(raster);
}

void main() {
  test(
      'integer-frame NPC pages and choices survive native write and strict reopen',
      () async {
    final temporary =
        await Directory.systemTemp.createTemp('source-npc-integer-frames-');
    addTearDown(() => temporary.delete(recursive: true));
    final fixture = await LiteralTileFixture.create(
      interpretationProfile: syntheticSourceInterpretationProfile,
      scriptsBytes: syntheticInterpretationArchive,
      includeEventSystem: true,
      extraFiles: {
        'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'),
        'Graphics/Characters/OriginalPlayer.png': _atlas(128, 192),
        'Graphics/Characters/Original NPC A.png': _atlas(129, 192),
        'Graphics/Characters/Original NPC B.png': _atlas(127, 193),
      },
      maps: [
        LiteralFixtureMap(id: 1, width: 4, height: 4, layers: [
          List.filled(16, 384),
          List.filled(16, 0),
          List.filled(16, 0)
        ], events: const [
          LiteralFixtureEvent(id: 1, name: 'Original NPC', x: 1, y: 1, pages: [
            LiteralFixtureEventPage(characterName: 'Original NPC A', commands: [
              LiteralFixtureEventCommand(101, ['Bonjour. Veux-tu continuer ?']),
              LiteralFixtureEventCommand(102, [
                ['Oui', 'Non'],
                0
              ]),
              LiteralFixtureEventCommand(402, [0, 'Oui']),
              LiteralFixtureEventCommand(101, ['D’accord.'], indent: 1),
              LiteralFixtureEventCommand(402, [1, 'Non']),
              LiteralFixtureEventCommand(101, ['À bientôt.'], indent: 1),
              LiteralFixtureEventCommand(404, []),
              LiteralFixtureEventCommand(123, ['A', 0]),
            ]),
            LiteralFixtureEventPage(
                characterName: 'Original NPC B',
                pattern: 3,
                direction: 6,
                selfSwitch: 'A',
                commands: [
                  LiteralFixtureEventCommand(101, ['Nous avons déjà parlé.']),
                ]),
          ]),
          LiteralFixtureEvent(id: 2, name: 'Missing NPC', x: 3, y: 3, pages: [
            LiteralFixtureEventPage(characterName: 'Absent', commands: [
              LiteralFixtureEventCommand(101, ['Ne pas inventer mon image.']),
            ]),
          ]),
        ])
      ],
    );
    final literal = await const LiteralTileComposer().compose(
      source: fixture.source,
      files: fixture.files,
      selectedSourceMapIds: [1],
      projectName: 'Original NPC integer cells',
      parentPath: temporary.path,
      folderName: 'native',
    );
    final semantic = (await const SourceSemanticStudyComposer()
        .compose(source: fixture.source, base: literal, files: fixture.files))!;
    Future<SourceEventStudyComposition> compose() async =>
        (await const SourceEventStudyComposer().compose(
            source: fixture.source, base: semantic, files: fixture.files))!;
    final composed = await compose();
    final replay = await compose();
    expect(replay.draft.canonicalHash, composed.draft.canonicalHash);
    final rows =
        (composed.projection.semanticEvidence['events'] as List).cast<Map>();
    final original =
        rows.singleWhere((row) => (row['locator'] as Map)['eventId'] == 1);
    expect(original['status'], 'adaptedStaticSemantics',
        reason: jsonEncode(original));
    expect(original['gaps'], isEmpty);
    final absent =
        rows.singleWhere((row) => (row['locator'] as Map)['eventId'] == 2);
    expect(absent['status'], 'quarantinedWholeEvent');
    expect(absent['gaps'], contains('characterBindingMissing'));
    expect(
        composed.projection.registry.records
            .where((record) => record.enabledOrNull == true),
        hasLength(2));
    expect(
        composed.projection.registry.records
            .where((record) => record.draftOrNull != null),
        hasLength(1));
    final yarn = composed.projection.dialogueSources.values.join('\n');
    for (final text in [
      'Bonjour.',
      'Oui',
      'Non',
      'D’accord.',
      'À bientôt.',
      'Nous avons déjà parlé.'
    ]) {
      expect(yarn, contains(text));
    }
    final approval = approveNativeFixtureDraft(composed.draft);
    final receipt = await NativeProjectWriter()
        .write(approval.plan, approval.context, composed.draft);
    expect(receipt.verified, isTrue);
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(receipt.projectPath);
    ProjectSnapshot? native;
    try {
      native = await ProjectSnapshotLoader(handles: handles)
          .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
      expect(native.loadDiagnostics, isEmpty);
      final manifest = native.manifest;
      final map = native.mapById(composed.draft.mapIds[1]!)!;
      final entity = map.entities
          .singleWhere((entry) => entry.name.contains('Original NPC'));
      expect(entity.presentation!.variants.map((variant) => variant.id),
          ['page_1', 'page_0']);
      for (final variant in entity.presentation!.variants) {
        expect(
            manifest.characters.any((entry) => entry.id == variant.characterId),
            isTrue);
      }
      final factId = composed.projection.facts.single.id;
      for (final changed in [false, true, false]) {
        final state = GameState.fromJson(jsonDecode(jsonEncode(GameState(
          saveId: 'original-npc',
          currentMapId: map.id,
          narrativeFactRuntimeState:
              NarrativeFactRuntimeState(overridesByFactId: {factId: changed}),
        ).toJson())) as Map<String, dynamic>);
        final selected = projectMapEntityPresentations(
                project: manifest, gameState: state, map: map)
            .entities
            .singleWhere((entry) => entry.id == entity.id);
        expect(selected.npc!.facing,
            changed ? EntityFacing.east : EntityFacing.south);
        expect(selected.npc!.characterId,
            entity.presentation!.variants[changed ? 0 : 1].characterId);
        expect(selected.blocksMovement, isTrue);
      }
      expect(
          manifest.eventRegistry!.records
              .where((record) => record.enabledOrNull == true),
          hasLength(2));
      expect(
          manifest.eventRegistry!.records
              .where((record) => record.draftOrNull != null),
          hasLength(1));
      expect(
          manifest.dialogues, hasLength(composed.projection.dialogues.length));
      ProjectValidator.validate(manifest,
          maps: native.maps, itemCatalog: native.itemCatalog);
      MapValidator.validate(map, projectDialogueContext: manifest);
    } finally {
      await native?.payloadOwner?.release();
      opener.closeWorkspace(opened.workspaceHandle);
    }
  });
}
