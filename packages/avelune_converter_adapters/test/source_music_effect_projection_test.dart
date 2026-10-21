import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_event_sound_binding.dart';
import 'package:avelune_converter_adapters/src/source_event_execution_context.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'package:image/image.dart' as image;

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/source_map_music_fixture.dart';

Future<LiteralTileFixture> _fixture(
        {bool missing = false, bool unknown = false}) =>
    LiteralTileFixture.create(
      interpretationProfile: syntheticSourceInterpretationProfile,
      scriptsBytes: syntheticInterpretationArchive,
      includeEventSystem: true,
      extraFiles: {
        'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = Player\n'),
        'PBS/map_metadata.txt': utf8.encode('[1]\nOutdoor = false\n'),
        'Data/map_connections.dat': literalFixtureMarshal([]),
        'Data/map_metadata.dat': literalFixtureMarshal({}),
        'Graphics/Characters/Player.png': image
            .encodePng(image.Image(width: 128, height: 192, numChannels: 4)),
        if (!missing) 'Audio/ME/Reward.wav': sourceMapMusicFixtureWav(),
        'Audio/SE/Reward.wav': (sourceMapMusicFixtureWav()..last = 1),
      },
      maps: [
        LiteralFixtureMap(id: 1, events: [
          LiteralFixtureEvent(id: 1, x: 1, y: 0, pages: [
            LiteralFixtureEventPage(characterName: 'Player', commands: [
              const LiteralFixtureEventCommand(249, [
                LiteralFixtureObject('RPG::AudioFile', {
                  '@name': 'Reward',
                  '@volume': 75,
                  '@pitch': 100,
                })
              ]),
              if (unknown)
                const LiteralFixtureEventCommand(355, ['plugin_function()']),
            ]),
          ]),
        ])
      ],
    );

Future<SourceEventProjection> _project(LiteralTileFixture fixture,
    {Map<String, SourceEventSoundBinding> bindings = const {},
    bool spatial = false}) async {
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: fixture.snapshot,
      files: fixture.files,
      interpretationProfile: syntheticSourceInterpretationProfile,
      includeEventSystem: true,
      includeConnections: true);
  final actor = await const SourceEventCharacterImporter().read(
      snapshot: fixture.source.snapshot,
      files: fixture.files,
      charsetName: 'Player',
      sourcePattern: 0,
      sourceDirection: 2);
  final literal = await const LiteralTileComposer().compose(
      source: source,
      files: fixture.files,
      selectedSourceMapIds: [1],
      projectName: 'ME projection',
      parentPath: '/private/tmp',
      folderName: 'not-written-me');
  final context = await const SourceEventExecutionContextResolver().read(
      source: source,
      base: literal.draft,
      nativeMaps: literal.nativeMaps,
      files: fixture.files);
  expect(context.refusals, isEmpty);
  return const SourceEventProjector().project(
    source: source,
    analysis: SourceEventAnalyzer.forProject(source,
            profile: SourceEventProfile.forProject(source))
        .analyze(),
    nativeMaps: {
      for (final entry in literal.nativeMaps.entries)
        entry.key: spatial
            ? entry.value
                .copyWith(spatialScene: MapSpatialScene(width: 3, depth: 1))
            : entry.value
    },
    executionContext: context,
    retentionPolicy: MapInstanceRetentionPolicy(
        viewportWidthTiles: 20, viewportHeightTiles: 15, marginTiles: 1),
    soundBindings: bindings,
    characterBindings: {
      sourceEventCharacterBindingKey(
          characterName: 'Player', pattern: 0, direction: 2): actor.binding
    },
  );
}

List<SceneInteractiveCommand> _commands(SourceEventProjection projection) =>
    projection.scenes
        .expand((scene) => scene.graph.nodes)
        .map((node) => node.payload)
        .whereType<SceneActionPayload>()
        .map((payload) => payload.interactiveCommand)
        .whereType<SceneInteractiveCommand>()
        .toList();

void main() {
  test(
      'ME249 projects exact ME media into a distinct nonblocking native command',
      () async {
    final fixture = await _fixture();
    final audio = await const SourceEventSoundResolver().read(
      source: fixture.source,
      files: fixture.files,
      name: 'Reward',
      kind: SourceEventAudioKind.musicEffect,
      policy: SourceEventSoundPolicy.nativeAuthoredVolume,
    );
    final projection = await _project(fixture, bindings: {'me:Reward': audio});
    final row = (projection.semanticEvidence['events'] as List).single as Map;
    expect(row['status'], 'adaptedStaticSemantics', reason: '${row['gaps']}');
    final command =
        _commands(projection).single as ScenePlayMusicEffectInteractiveCommand;
    expect(command.mediaAssetId, audio.mediaId);
    expect(command.volume, .75);
    expect(command.bgmInterruption,
        DialogueBgmInterruption(fadeOutMs: 0, fadeInMs: 0));
    expect(
        _commands(projection)
            .whereType<ScenePlaySoundEffectInteractiveCommand>(),
        isEmpty);
    expect(audio.audioFile.relativePath, 'Audio/ME/Reward.wav');
    expect(
        projection.scenes
            .every((scene) => buildSceneRuntimePlan(scene).canBuild),
        isTrue);
  });

  test(
      'ME249 cannot use a missing binding, ordinary SE binding, wrong key or spatial map',
      () async {
    final fixture = await _fixture();
    final resolver = const SourceEventSoundResolver();
    final me = await resolver.read(
        source: fixture.source,
        files: fixture.files,
        name: 'Reward',
        kind: SourceEventAudioKind.musicEffect,
        policy: SourceEventSoundPolicy.nativeAuthoredVolume);
    final se = await resolver.read(
        source: fixture.source,
        files: fixture.files,
        name: 'Reward',
        policy: SourceEventSoundPolicy.nativeAuthoredVolume);
    for (final bindings in <Map<String, SourceEventSoundBinding>>[
      {},
      {'Reward': me},
      {'me:Reward': se},
    ]) {
      final result = await _project(fixture, bindings: bindings);
      expect(result.scenes, isEmpty);
      expect((result.semanticEvidence['events'] as List).single['status'],
          'quarantinedWholeEvent');
    }
    expect(
        (await _project(fixture, bindings: {'me:Reward': me}, spatial: true))
            .scenes,
        isEmpty);
    final unknown = await _fixture(unknown: true);
    final unknownAudio = await resolver.read(
        source: unknown.source,
        files: unknown.files,
        name: 'Reward',
        kind: SourceEventAudioKind.musicEffect,
        policy: SourceEventSoundPolicy.nativeAuthoredVolume);
    expect(
        (await _project(unknown, bindings: {'me:Reward': unknownAudio})).scenes,
        isEmpty);
  });

  test(
      'automatic event composition imports ME and never substitutes the same-named SE',
      () async {
    final fixture = await _fixture();
    final source = await const RmxpSourceNormalizer().normalize(
        snapshot: fixture.snapshot,
        files: fixture.files,
        interpretationProfile: syntheticSourceInterpretationProfile,
        includeEventSystem: true,
        includeConnections: true);
    final literal = await const LiteralTileComposer().compose(
      source: source,
      files: fixture.files,
      selectedSourceMapIds: [1],
      projectName: 'ME composition',
      parentPath: '/private/tmp',
      folderName: 'not-written-me',
    );
    final semantic = (await const SourceSemanticStudyComposer()
        .compose(source: source, base: literal, files: fixture.files))!;
    final composition = (await const SourceEventStudyComposer()
        .compose(source: source, base: semantic, files: fixture.files))!;
    final commands = _commands(composition.projection);
    expect(commands.whereType<ScenePlayMusicEffectInteractiveCommand>(),
        hasLength(1),
        reason: '${composition.projection.semanticEvidence}');
    expect(
        commands.whereType<ScenePlaySoundEffectInteractiveCommand>(), isEmpty);
    final imports = composition.draft.mutations
        .where((mutation) =>
            mutation.actionId == 'scene.dialogue.audioMedia.import' &&
            mutation.parameters['label'] == 'Reward')
        .toList();
    expect(imports, hasLength(1));
    expect(
        imports.single.parameters['mediaId'], startsWith('source_me_media_'));
    final artifact = composition.draft.artifacts.singleWhere((artifact) =>
        artifact.handle == imports.single.parameters['artifactHandle']);
    expect(artifact.bytes, orderedEquals(sourceMapMusicFixtureWav()));
    expect(artifact.bytes,
        isNot(orderedEquals(sourceMapMusicFixtureWav()..last = 1)));
  });
}
