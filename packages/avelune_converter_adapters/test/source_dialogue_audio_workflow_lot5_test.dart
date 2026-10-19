import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/source_map_music_fixture.dart';

void main() {
  final sourceRoot = Platform.environment['AVELUNE_AC13_SOURCE_ROOT'];
  final scripts = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];
  final profilePath = Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'];
  final engineFile = Platform.environment['AVELUNE_LOT5_ENGINE_FILE'];
  test('prepare discovers inline sound and binds exact source engine gain',
      () async {
    final root = await Directory.systemTemp.createTemp('lot5-inline-audio-');
    final workflow = ConverterWorkflow();
    addTearDown(() async {
      await workflow.dispose();
      await root.delete(recursive: true);
    });
    final baseProfile = jsonDecode(await File(profilePath!).readAsString())
        as Map<String, dynamic>;
    final profile = SourceInterpretationProfile.fromJson({
      ...baseProfile,
      'sections': {
        ...baseProfile['sections'] as Map,
        'events.Audio_Play': {
          'index': 93,
          'name': 'Audio_Play',
          'sha256':
              'e21c2f9b086f99777b7421c850e4b04cb8e5db574876b3fbb9c0fd9932e1d1fb'
        },
      },
    });
    final extra = <String, List<int>>{};
    for (final name in ['Game.ini', 'mkxp.json']) {
      extra[name] = await File('$sourceRoot/$name').readAsBytes();
    }
    extra['Game.exe'] = await File(engineFile!).readAsBytes();
    extra['Audio/SE/ItemGet.wav'] = sourceMapMusicFixtureWav();
    extra['Audio/SE/Refused.wav'] = sourceMapMusicFixtureWav();
    extra['PBS/metadata.txt'] = utf8.encode('[1]\nWalkCharset = TestPlayer\n');
    extra['Graphics/Characters/TestPlayer.png'] =
        image.encodePng(image.Image(width: 128, height: 192, numChannels: 4));
    await LiteralTileFixture.create(
        sourceRootPath: '${root.path}/source',
        scriptsBytes: await File(scripts!).readAsBytes(),
        interpretationProfile: profile,
        includeEventSystem: true,
        extraFiles: extra,
        maps: [
          LiteralFixtureMap(id: 1, width: 6, height: 1, layers: [
            List.filled(6, 384),
            List.filled(6, 0),
            List.filled(6, 0)
          ], events: [
            for (final entry in {
              2: r'\bA😀\se[ItemGet:80]B',
              3: r'A\se[Missing]B',
              4: r'A\se[ItemGet:80:120]B',
              5: r'\sign[signskin]Panneau\se[Refused]',
            }.entries)
              LiteralFixtureEvent(
                  id: entry.key,
                  x: entry.key - 1,
                  y: 0,
                  pages: [
                    LiteralFixtureEventPage(trigger: 1, commands: [
                      LiteralFixtureEventCommand(101, [entry.value]),
                      const LiteralFixtureEventCommand(0, []),
                    ])
                  ]),
            const LiteralFixtureEvent(id: 6, x: 5, y: 0, pages: [
              LiteralFixtureEventPage(trigger: 1, commands: [
                LiteralFixtureEventCommand(102, [
                  [r'A\se[ItemGet]B'],
                  1
                ]),
                LiteralFixtureEventCommand(402, [0, r'A\se[ItemGet]B']),
                LiteralFixtureEventCommand(101, ['Accepted'], indent: 1),
                LiteralFixtureEventCommand(0, [], indent: 1),
                LiteralFixtureEventCommand(404, []),
                LiteralFixtureEventCommand(0, []),
              ]),
            ]),
          ])
        ]);
    final output = await Directory('${root.path}/output').create();
    final snapshot = await workflow.scanSource(ConverterSourceSelection(
        rootPath: '${root.path}/source',
        logicalProjectNamespace: ConverterId('lot5-inline-audio')));
    expect(snapshot.state, SourceScanState.complete);
    workflow.updateSettings(ConverterStudySettings(
        projectName: 'Lot 5 inline sound',
        parentPath: output.path,
        folderName: 'inline-sound',
        selectedSourceMapIds: [1],
        interpretationProfile: profile,
        profileAcknowledgement: SourceStudyAcknowledgement(
            sourceSnapshotHash: snapshot.canonicalHash,
            profileEvidenceHash: snapshot.profile.evidenceHash,
            humanConfirmed: true,
            reason:
                'Controlled inline sound workflow with exact external engine bytes')));
    final prepared = await workflow.prepareStudy();
    expect(prepared.nativeDraft, isNotNull,
        reason: '${prepared.previewPlan?.toJson()}');
    final draft = prepared.nativeDraft!;
    final evidence = draft.compositionEvidence['sourceEvents'] as Map;
    final sounds = (evidence['sounds'] as List).cast<Map>();
    final imported =
        sounds.singleWhere((row) => row['sourceName'] == 'ItemGet');
    expect(imported['status'], 'imported');
    expect(imported['policy'], 'sourceEngineGain');
    expect(imported['sourceEngineGainQualified'], isTrue);
    expect(imported['usesDialogueFeedback'], isTrue);
    expect(
        sounds.singleWhere(
            (row) => row['sourceName'] == 'Refused')['usesDialogueFeedback'],
        isFalse);
    expect(imported['sourceScriptsExecuted'], 0);
    final rows =
        ((evidence['projection'] as Map)['events'] as List).cast<Map>();
    Map row(int id) =>
        rows.singleWhere((row) => (row['locator'] as Map)['eventId'] == id);
    expect(row(2)['gaps'], isEmpty);
    expect(row(3)['gaps'], contains('sourceTextAudioBindingMissing'));
    expect(row(4)['gaps'], contains('sourceTextAudioPitchUnsupported'));
    expect(row(5)['gaps'], contains('sourceTextWindowAnimationUnsupported'));
    expect(row(6)['gaps'], contains('choiceTextUnsupported'));
    final cues = draft.mutations
        .where((mutation) => mutation.actionId == 'scene.upsert')
        .map((mutation) => SceneAsset.fromJson(
            Map<String, dynamic>.from(mutation.parameters['scene'] as Map)))
        .expand((scene) => scene.graph.nodes)
        .map((node) => node.payload)
        .whereType<SceneYarnDialoguePayload>()
        .expand((payload) => payload.linePolicies)
        .map((policy) => policy.feedback.audioCue)
        .whereType<DialogueAudioCue>();
    expect(cues, hasLength(1));
    expect(cues.single.revealOffset, 2);
    expect(cues.single.volume, closeTo(0.384, 1e-12));
    final withoutMessages = profile.toJson();
    withoutMessages['sections'] = {
      for (final entry in (withoutMessages['sections'] as Map).entries)
        if (entry.key != 'events.Messages') entry.key: entry.value,
    };
    for (final missingProfileDefinition in [
      SourceInterpretationProfile.fromJson(baseProfile),
      SourceInterpretationProfile.fromJson(withoutMessages),
    ]) {
      workflow.updateSettings(ConverterStudySettings(
          projectName: 'Lot 5 unqualified inline sound',
          parentPath: output.path,
          folderName: 'inline-sound',
          selectedSourceMapIds: [1],
          interpretationProfile: missingProfileDefinition,
          profileAcknowledgement: SourceStudyAcknowledgement(
              sourceSnapshotHash: snapshot.canonicalHash,
              profileEvidenceHash: snapshot.profile.evidenceHash,
              humanConfirmed: true,
              reason:
                  'Missing Audio_Play pin must refuse inline audio without fallback')));
      final missingProfile = await workflow.prepareStudy();
      final missingEvidence = missingProfile
          .nativeDraft!.compositionEvidence['sourceEvents'] as Map;
      final missingRows =
          ((missingEvidence['projection'] as Map)['events'] as List)
              .cast<Map>();
      final missingGaps = missingRows.singleWhere(
          (row) => (row['locator'] as Map)['eventId'] == 2)['gaps'];
      expect(missingGaps, contains('sourceTextAudioProfileUnqualified'));
      expect(missingGaps, isNot(contains('sourceTextAudioBindingMissing')));
      expect(
          (missingEvidence['sounds'] as List)
              .where((row) => row['sourceName'] == 'ItemGet'),
          isEmpty);
    }
    expect(await output.list().toList(), isEmpty);
  },
      skip: sourceRoot == null ||
          scripts == null ||
          profilePath == null ||
          engineFile == null,
      timeout: const Timeout(Duration(minutes: 2)));
}
