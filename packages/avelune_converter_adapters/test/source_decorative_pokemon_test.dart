import 'dart:convert';
import 'dart:io';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_event_sound_binding.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'package:image/image.dart' as image;
import 'support/literal_tile_fixture.dart';
import 'support/source_map_music_fixture.dart';

void main() {
  final archivePath = Platform.environment['AVELUNE_KNOWN_SCRIPTS_ARCHIVE'];
  group('closed decorative Pokemon cries', () {
    late Map<String, List<int>> engine;
    setUpAll(() async {
      final root = File(archivePath!).parent.parent.path;
      final audioRoot = root.replaceFirst(' - Hoenn', ' - Johto');
      engine = {
        for (final path in [
          'Data/Scripts.rxdata',
          'Game.exe',
          'Game.ini',
          'mkxp.json'
        ])
          path: await File(
                  '${path == 'Data/Scripts.rxdata' ? root : path == 'Game.exe' ? audioRoot.replaceFirst(' - Johto', ' - Hoenn') : path == 'Game.ini' ? audioRoot.replaceFirst(' - Johto', ' - Kanto') : audioRoot}/$path')
              .readAsBytes()
      };
    });
    Future<
        ({
          NormalizedSourceProject source,
          LiteralFixtureFiles files,
          SourceEventAnalysis analysis
        })> input({String defect = '', bool facing = false, int eventCount = 1,
            int? missingSpeciesEventId}) async {
      final route = LiteralFixtureObject('RPG::MoveRoute', {
        '@repeat': false,
        '@skippable': false,
        '@list': [
          LiteralFixtureObject('RPG::MoveCommand',
              {'@code': defect == 'away' ? 26 : 25, '@parameters': []}),
          const LiteralFixtureObject(
              'RPG::MoveCommand', {'@code': 0, '@parameters': []})
        ]
      });
      final fixture = await LiteralTileFixture.create(
          scriptsBytes: engine['Data/Scripts.rxdata'],
          includeEventSystem: true,
          extraFiles: {
            for (final entry in engine.entries
                .where((entry) => entry.key != 'Data/Scripts.rxdata'))
              entry.key: entry.value,
            'PBS/pokemon.txt': utf8.encode('[MEOWTH]\nName = Meowth\n'),
            'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = Player\n'),
            'PBS/map_metadata.txt': utf8.encode('[1]\nOutdoor = false\n'),
            'PBS/connections.txt': utf8.encode(''),
            'Graphics/Characters/Player.png': image.encodePng(
                image.Image(width: 128, height: 192, numChannels: 4)),
            'Data/species.dat': literalFixtureMarshal({
              const LiteralFixtureSymbol('MEOWTH'):
                  LiteralFixtureObject('GameData::Species', {
                '@id': const LiteralFixtureSymbol('MEOWTH'),
                '@species': const LiteralFixtureSymbol('MEOWTH'),
                '@form': defect == 'form' ? 1 : 0,
                '@real_name': 'Meowth'
              })
            }),
            'Graphics/Characters/PKMN_MEOWTH.png': literalFixtureAtlas(),
            if (defect != 'missingSound' && defect != 'aliasSound')
              'Audio/SE/Cries/MEOWTH.wav': sourceMapMusicFixtureWav(),
            if (defect == 'aliasSound')
              'Audio/SE/Cries/meowth.wav': sourceMapMusicFixtureWav()
          },
          maps: [
            LiteralFixtureMap(id: 1, events: [
              for (var index = 0; index < eventCount; index++)
              LiteralFixtureEvent(id: index + 1, x: 1, y: 0, pages: [
                LiteralFixtureEventPage(
                    characterName: 'PKMN_MEOWTH',
                    moveType: defect == 'moving' ? 1 : 0,
                    trigger: defect == 'autorun' ? 3 : 0,
                    commands: [
                      LiteralFixtureEventCommand(355, [
                        defect == 'expression'
                            ? r'Pokemon.play_cry($game_variables[1])'
                            : index + 1 == missingSpeciesEventId
                                ? 'Pokemon.play_cry(:MISSING)'
                                : 'Pokemon.play_cry(:MEOWTH)'
                      ]),
                      const LiteralFixtureEventCommand(101, ['Meowth: Meow!']),
                      if (defect == 'effect')
                        const LiteralFixtureEventCommand(121, [1, 1, 0]),
                      if (facing) ...[
                        LiteralFixtureEventCommand(209, [0, route]),
                        LiteralFixtureEventCommand(509, [
                          LiteralFixtureObject('RPG::MoveCommand', {
                            '@code': defect == 'away' ? 26 : 25,
                            '@parameters': []
                          })
                        ])
                      ],
                      const LiteralFixtureEventCommand(0, [])
                    ])
              ])
            ])
          ]);
      final profile =
          detectBuiltinSourceInterpretationProfile(fixture.snapshot)!;
      final source = await const RmxpSourceNormalizer().normalize(
          snapshot: fixture.snapshot,
          files: fixture.files,
          interpretationProfile: profile,
          includeEventSystem: true);
      return (
        source: source,
        files: fixture.files,
        analysis: SourceEventAnalyzer.forProject(source,
                profile: SourceEventProfile.forProject(source))
            .analyze()
      );
    }

    test('decorative batch reads one species witness for twelve events', () async {
      final f = await input(eventCount: 12);
      final catalog = NativePsdkCatalogManifest.builtin();
      f.files.reads.clear();

      final result = await const SourceDecorativePokemonBindingResolver().readAll(
          source: f.source, analysis: f.analysis, events: f.analysis.events,
          files: f.files, nativeCatalog: catalog);

      expect(result.bindings, hasLength(12));
      expect(result.refusals, isEmpty);
      final witness = f.source.snapshot.entries
          .singleWhere((entry) => entry.relativePath == 'Data/species.dat');
      expect(f.files.reads.where((id) => id == witness.fileId), hasLength(1));
      final reference = await const SourceDecorativePokemonBindingResolver().read(
          source: f.source, analysis: f.analysis, event: f.analysis.events.first,
          files: f.files, nativeCatalog: catalog);
      for (final event in f.analysis.events) {
        final binding = result.bindings[event.identity]!;
        expect(binding.isBoundTo(f.source, f.analysis, event), isTrue);
        expect(binding.toJson()['sourceSpeciesBinding'],
            reference.toJson()['sourceSpeciesBinding']);
      }
    });

    test('decorative batch isolates a missing cry species between valid neighbors',
        () async {
      final f = await input(eventCount: 3, missingSpeciesEventId: 2);
      final catalog = NativePsdkCatalogManifest.builtin();
      final result = await const SourceDecorativePokemonBindingResolver().readAll(
          source: f.source, analysis: f.analysis, events: f.analysis.events,
          files: f.files, nativeCatalog: catalog);
      final before = f.analysis.eventAt(1, 1)!;
      final invalid = f.analysis.eventAt(1, 2)!;
      final after = f.analysis.eventAt(1, 3)!;

      expect(result.bindings.keys,
          unorderedEquals([before.identity, after.identity]));
      expect(result.refusals.keys, [invalid.identity]);
      expect(result.refusals[invalid.identity],
          isA<ContractError>().having((error) => error.code, 'code',
              'native_species.compiled_identity').having(
              (error) => error.path, 'path', contains('MISSING')));
      for (final event in [before, after]) {
        final binding = result.bindings[event.identity]!;
        expect(binding.isBoundTo(f.source, f.analysis, event), isTrue);
        expect(binding.sound.name, 'Cries/MEOWTH');
        expect(binding.toJson()['sourceSpeciesBinding'],
            result.bindings[before.identity]!.toJson()['sourceSpeciesBinding']);
      }
    });

    test(
        'literal cry retains source volume, raw span and original source bytes',
        () async {
      final f = await input();
      final cry = f.analysis.events.single.pages.single.body.nodes.first
          as SourceSoundEffectNode;
      expect(cry.name, 'Cries/MEOWTH');
      expect(cry.volume, 90);
      expect(cry.pitch, 100);
      expect(cry.span.firstCommandIndex, 0);
      expect(cry.span.lastCommandIndex, 0);
      expect(cry.rawDataRef.fileId, f.source.maps.single.map.sourceFileId);
      final binding = await const SourceDecorativePokemonBindingResolver().read(
          source: f.source,
          analysis: f.analysis,
          event: f.analysis.events.single,
          files: f.files);
      expect(binding.sound.gainForVolume(90), closeTo(0.432, 1e-12));
      expect(binding.sound.artifact.bytes, sourceMapMusicFixtureWav());
      expect(binding.isBoundTo(f.source, f.analysis, f.analysis.events.single),
          isTrue);
      expect(() => binding.sound.evidence['sourceScriptsExecuted'] = 1,
          throwsUnsupportedError);
      expect(binding.isBoundTo(f.source, f.analysis, f.analysis.events.single),
          isTrue);
      expect((binding.toJson()['sound'] as Map)['sourceScriptsExecuted'], 0);
    });
    for (final facing in [false, true]) {
      test('native graph retains cry dialogue and final facing=$facing',
          () async {
        final f = await input(facing: facing);
        final event = f.analysis.events.single;
        final binding = await const SourceDecorativePokemonBindingResolver()
            .read(
                source: f.source,
                analysis: f.analysis,
                event: event,
                files: f.files);
        final character = await const SourceEventCharacterImporter().read(
            snapshot: f.source.snapshot,
            files: f.files,
            charsetName: 'PKMN_MEOWTH',
            sourcePattern: 0,
            sourceDirection: 2);
        final projection = const SourceEventProjector()
            .project(source: f.source, analysis: f.analysis, nativeMaps: {
          1: MapData(
              id: 'original',
              name: 'Original',
              size: const GridSize(width: 3, height: 1))
        }, characterBindings: {
          character.bindingKey: character.binding
        }, soundBindings: {
          binding.sound.name: binding.sound
        }, decorativePokemonBindings: {
          event.identity: binding
        });
        final row =
            (projection.semanticEvidence['events'] as List).single as Map;
        expect(row['gaps'], isEmpty);
        expect(row['nativeDecorativePokemon'], isNotNull);
        final scene = SceneAsset.fromJson(
            jsonDecode(jsonEncode(projection.scenes.single.toJson())));
        expect(buildSceneRuntimePlan(scene).plan, isNotNull);
        final payloads = scene.graph.nodes
            .map((node) => node.payload)
            .whereType<SceneActionPayload>()
            .toList();
        expect(
            payloads.where((p) =>
                p.interactiveCommand is ScenePlaySoundEffectInteractiveCommand),
            hasLength(1));
        expect(
            payloads.where((p) =>
                p.interactiveCommand is SceneActorRouteInteractiveCommand),
            hasLength(facing ? 4 : 0));
        final effects = <String>[];
        final result = await SceneRuntimeExecutor(
            callbacks: SceneRuntimeExecutionCallbacks(
                evaluateCondition: (intent) =>
                    intent.conditionSource!.playerFacingDirection ==
                            EntityFacing.south
                        ? 'true'
                        : 'false',
                showDialogue: (_) {
                  effects.add('dialogue');
                  return 'completed';
                },
                startBattle: (_) => throw StateError('Unexpected battle'),
                playCinematic: (_) => throw StateError('Unexpected cinematic'),
                executeInteractiveCommand: (intent) {
                  final command = intent.interactiveCommand!;
                  if (command is ScenePlaySoundEffectInteractiveCommand) {
                    expect(command.volume, closeTo(0.432, 1e-12));
                    effects.add('cry');
                  } else if (command is SceneActorRouteInteractiveCommand) {
                    expect(
                        (command.steps.single as SceneActorFaceStep).direction,
                        EntityFacing.north);
                    effects.add('face');
                  } else if (command
                      is SceneWaitForActorRoutesInteractiveCommand) {
                    effects.add('join');
                  } else {
                    throw StateError('Unexpected command');
                  }
                  return 'completed';
                },
                applyConsequence: (_) =>
                    throw StateError('Unexpected effect'))).execute(
            buildSceneRuntimePlan(scene).plan!);
        expect(result.status, SceneRuntimeExecutionStatus.completed);
        expect(effects,
            facing ? ['cry', 'dialogue', 'face', 'join'] : ['cry', 'dialogue']);
        final original = event;
        final forged = SourceEventDefinition(
            sourceMapId: original.sourceMapId,
            sourceEventId: original.sourceEventId,
            sourceFileId: original.sourceFileId,
            identity: original.identity,
            name: original.name,
            x: original.x + 1,
            y: original.y,
            locator: original.locator,
            pages: original.pages);
        expect(binding.isBoundTo(f.source, f.analysis, forged), isFalse);
        await expectLater(
            const SourceDecorativePokemonBindingResolver().read(
                source: f.source,
                analysis: f.analysis,
                event: forged,
                files: f.files),
            throwsA(isA<NativeWriteException>()));
      });
    }
    test(
        'automatic composer retains exact cry media and attested species witnesses',
        () async {
      final f = await input(facing: true);
      final literal = await const LiteralTileComposer().compose(
          source: f.source,
          files: f.files,
          selectedSourceMapIds: [1],
          projectName: 'Decorative cry',
          parentPath: Directory.systemTemp.path,
          folderName: 'decorative-cry-not-published');
      final semantic = (await const SourceSemanticStudyComposer()
          .compose(source: f.source, base: literal, files: f.files))!;
      final composed = (await const SourceEventStudyComposer()
          .compose(source: f.source, base: semantic, files: f.files))!;
      final row = (composed.projection.semanticEvidence['events'] as List)
          .single as Map;
      expect(row['gaps'], isEmpty);
      expect(row['nativeDecorativePokemon'], isNotNull);
      expect(
          composed.draft.mutations.where((mutation) =>
              mutation.actionId == 'scene.dialogue.audioMedia.import'),
          hasLength(1));
      expect(
          composed.draft.artifacts.any((artifact) =>
              canonicalJsonOf(artifact.bytes) ==
              canonicalJsonOf(sourceMapMusicFixtureWav())),
          isTrue);
      final evidence =
          composed.draft.compositionEvidence['sourceEvents'] as Map;
      expect((evidence['decorativePokemonBindings'] as List).single['status'],
          'attested');
    });
    for (final defect in ['moving', 'effect']) {
      test('generic sound binding cannot admit the $defect event', () async {
        final f = await input(defect: defect);
        final event = f.analysis.events.single;
        expect(
            event.pages.single.body.nodes.first, isA<SourceSoundEffectNode>());
        final sound = await const SourceEventSoundResolver()
            .read(source: f.source, files: f.files, name: 'Cries/MEOWTH');
        final character = await const SourceEventCharacterImporter().read(
            snapshot: f.source.snapshot,
            files: f.files,
            charsetName: 'PKMN_MEOWTH',
            sourcePattern: 0,
            sourceDirection: 2);
        final projection = const SourceEventProjector()
            .project(source: f.source, analysis: f.analysis, nativeMaps: {
          1: MapData(
              id: 'original',
              name: 'Original',
              size: const GridSize(width: 3, height: 1))
        }, characterBindings: {
          character.bindingKey: character.binding
        }, soundBindings: {
          sound.name: sound
        });
        final row =
            (projection.semanticEvidence['events'] as List).single as Map;
        expect(row['status'], 'quarantinedWholeEvent');
        expect(row['gaps'], contains('sourceDecorativePokemonBindingMissing'));
        expect(projection.scenes, isEmpty);
      });
    }
    for (final defect in [
      'missingSound',
      'aliasSound',
      'form',
      'expression',
      'moving',
      'autorun',
      'effect',
      'away'
    ]) {
      test('refuses $defect without dropping effects', () async {
        final f = await input(defect: defect, facing: defect == 'away');
        await expectLater(
            const SourceDecorativePokemonBindingResolver().read(
                source: f.source,
                analysis: f.analysis,
                event: f.analysis.events.single,
                files: f.files),
            throwsA(defect == 'missingSound' || defect == 'aliasSound'
                ? isA<SourceEventSoundBindingUnavailable>()
                : defect == 'form'
                    ? isA<ContractError>()
                    : isA<NativeWriteException>()));
      });
    }
  }, skip: archivePath == null);
}
