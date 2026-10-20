import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_event_sound_binding.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/source_gym_leader_program_test.dart' as gym;
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/native_trainer_fixture.dart';
import 'support/native_writer_fixture.dart';

final class _RekeyedGymSourceFiles implements SourceFilePort {
  const _RekeyedGymSourceFiles(this.files, this.replacement, this.original);
  final SourceFilePort files;
  final ConverterId replacement, original;

  @override
  Future<List<int>> read(ConverterId fileId) =>
      files.read(fileId == replacement ? original : fileId);
}

Object? _literal(MarshalDocument document, int id) {
  final node = document.node(id);
  return switch (node.kind) {
    MarshalKind.nil => null,
    MarshalKind.boolean => node.booleanValue,
    MarshalKind.integer => node.integerValue!.toInt(),
    MarshalKind.string => utf8.decode(node.bytes!),
    MarshalKind.symbol => LiteralFixtureSymbol(node.name!),
    MarshalKind.array => node.elements.map((id) => _literal(document, id)).toList(),
    MarshalKind.object => LiteralFixtureObject(node.className!, {
      for (final field in node.instanceVariables)
        document.node(field.key).name!: _literal(document, field.value),
    }),
    MarshalKind.userDefined => LiteralFixtureUserDefined(node.className!, node.bytes!),
    _ => throw StateError('Unexpected fixture node ${node.kind}'),
  };
}

List<int> _wav() {
  final bytes = Uint8List(16044), view = ByteData(16044);
  void text(int offset, String text) => bytes.setRange(offset, offset + text.length, ascii.encode(text));
  text(0, 'RIFF'); text(8, 'WAVE'); text(12, 'fmt '); text(36, 'data');
  view.setUint32(4, bytes.length - 8, Endian.little);
  view.setUint32(16, 16, Endian.little); view.setUint16(20, 1, Endian.little);
  view.setUint16(22, 1, Endian.little); view.setUint32(24, 8000, Endian.little);
  view.setUint32(28, 16000, Endian.little); view.setUint16(32, 2, Endian.little);
  view.setUint16(34, 16, Endian.little); view.setUint32(40, 16000, Endian.little);
  for (final range in [(4, 8), (16, 36), (40, 44)]) {
    bytes.setRange(range.$1, range.$2, view.buffer.asUint8List().sublist(range.$1, range.$2));
  }
  return bytes;
}

List<int> _integer(int n) => n == 0 ? [0] : n < 123 ? [n + 5] : [2, n & 255, n >> 8];
List<int> _string(List<int> bytes) => [34, ..._integer(bytes.length), ...bytes];

NativePsdkCatalog _fixtureNativeCatalog() {
  final bundle = NativePsdkTrainerBundle.builtin();
  const ids = {'rattata', 'raticate', 'rattata_form1', 'raticate_form1'};
  final bytes = image.encodePng(image.Image(width: 32, height: 32, numChannels: 4));
  final data = bundle.toJson();
  final paths = {for (final media in bundle.mediaBySpeciesId.values.where((v) => ids.contains(v.speciesId)))
    for (final variant in media.variants.values) ...[variant.frontStatic!, variant.backStatic!]};
  return NativePsdkTrainerBundle.fromJson({
    ...data,
    'species': bundle.speciesById.values.where((v) => ids.contains(v.id)).map((v) => v.toJson()).toList(),
    'sourceLearnsets': bundle.learnsetsBySpeciesId.values.where((v) => ids.contains(v.speciesId)).map((v) => v.toJson()).toList(),
    'evolutions': bundle.evolutionsBySpeciesId.values.where((v) => ids.contains(v.speciesId)).map((v) => v.toJson()).toList(),
    'media': bundle.mediaBySpeciesId.values.where((v) => ids.contains(v.speciesId)).map((v) => v.toJson()).toList(),
    'fallbackMedia': [for (final path in paths) {
      'targetPath': path, 'sourcePath': 'fixture/gym/$path',
      'bytesBase64': base64Encode(bytes), 'sha256': literalFixtureHash(bytes).value,
    }],
  });
}

Future<({SourceEventProjection projection, NormalizedSourceProject source,
    SourceEventAnalysis analysis, SourceTrainerEventBindings trainers,
    SourceFilePort files, Map<String, SourcePickupFeedbackBinding> pickups})> _fixture({bool pickup = true,
      bool unknownBadgeCountWriter = false, String gymName = 'Brock',
      bool authoredTackle = false}) async {
  final base = gymName == 'Brock' ? await gym.gymSource(gym.gymCases.first)
      : await gym.extendedGymSource(gymName);
  final event = analyzeGym(base);
  final gymProgram = event.pages.first.body.nodes.single as SourceTrainerProgramNode;
  final machine = gymProgram.gymLeader!.rewardSymbol;
  final pages = <LiteralFixtureEventPage>[];
  for (final page in event.pages) {
    final ref = page.rawDataRef!, doc = base.sourceFiles[ref.fileId]!.document;
    final raw = (_literal(doc, ref.nodeId) as LiteralFixtureObject).fields;
    final commands = (raw['@list'] as List).cast<LiteralFixtureObject>();
    pages.add(LiteralFixtureEventPage(
        characterName: (raw['@graphic'] as LiteralFixtureObject).fields['@character_name'] as String,
        through: raw['@through'] as bool,
        globalSwitch: page.originalPageIndex == 1 ? gymProgram.gymLeader!.completionSwitchId : null,
        selfSwitch: page.originalPageIndex >= 2 ? (page.originalPageIndex == 2 ? 'A' : 'B') : null,
        commands: [for (final command in commands) LiteralFixtureEventCommand(
          command.fields['@code'] as int, (command.fields['@parameters'] as List).cast<Object?>(),
          indent: command.fields['@indent'] as int)]));
  }
  const settings = 'FIELD_MOVES_COUNT_BADGES = false\nREGION_HM_ARRAY = [[],[12,13,15,14,11,17]]\n'
      'BADGE_FOR_CUT = 0\nBADGE_FOR_FLY = 1\nBADGE_FOR_SURF = 2\nBADGE_FOR_STRENGTH = 3\n'
      'BADGE_FOR_FLASH = 4\nBADGE_FOR_ROCKSMASH = 5\n';
  final settingsBytes = utf8.encode(settings);
  final scripts = [4, 8, 91, 7,
    91, 8, 105, 0, ..._string(utf8.encode('Settings')), ..._string(zlib.encode(settingsBytes)),
    91, 8, 105, 6, ..._string(utf8.encode('Synthetic')), ..._string(zlib.encode(syntheticInterpretationSection))];
  final raster = image.Image(width: 96, height: 48, numChannels: 4)
    ..clear(image.ColorRgba8(248, 248, 248, 255));
  final skin = image.encodePng(raster);
  final icon = image.encodePng(image.Image(width: 18, height: 32));
  final audio = _wav();
  const skinPath = 'Graphics/Windowskins/neutral-panel.png';
  const iconPath = 'Graphics/Icons/bagPocket4.png';
  const audioPath = 'Audio/ME/neutral-machine.wav';
  Map<String, Object?> pin(String path, List<int> bytes) => {
    'relativePath': path, 'sha256': literalFixtureHash(bytes).value,
  };
  final profile = SourceInterpretationProfile.fromJson({
    ...syntheticSourceInterpretationProfile.toJson(),
    'scriptsArchive': {'relativePath': 'Data/Scripts.rxdata', 'sha256': literalFixtureHash(scripts).value},
    'sections': {
      for (final role in ['events.Interpreter', 'walking.Game_Map', 'walking.Game_Character',
        'walking.TerrainTag', 'events.Messages', 'events.MessageConfig', 'events.DrawText'])
        role: {'index': 1, 'name': 'Synthetic', 'sha256': literalFixtureHash(syntheticInterpretationSection).value},
      'events.Settings': {'index': 0, 'name': 'Settings', 'sha256': literalFixtureHash(settingsBytes).value},
    },
    'presentationBindings': {'characterSubstitutions': [], 'routedDoorPatterns': [],
      'pickupFeedbackByRegion': [{'regionId': 1,
        'windowskinPinnedAsset': pin(skinPath, skin),
        'iconsByPocket': {'4': pin(iconPath, icon), '1': pin(iconPath, icon)},
        'audioByItemKind': {'machine': pin(audioPath, audio), 'item': pin(audioPath, audio)}}]},
  });
  final roster = (type: 'FRLG_LEADER_$gymName', name: gymName, version: 0);
  final trainerFiles = nativeTrainerFixtureFiles([roster]);
  if (authoredTackle) {
    trainerFiles['PBS/trainers.txt'] = utf8.encode('[${roster.type},${roster.name},0]\n'
        'LoseText = Good game!\nPokemon = RATTATA,16\nMoves = TACKLE\n');
    trainerFiles['Data/trainers.dat'] = literalFixtureMarshal({
      [LiteralFixtureSymbol(roster.type), roster.name, 0]: LiteralFixtureObject('GameData::Trainer', {
        '@id': [LiteralFixtureSymbol(roster.type), roster.name, 0],
        '@trainer_type': LiteralFixtureSymbol(roster.type), '@real_name': roster.name,
        '@version': 0, '@items': <Object?>[], '@real_lose_text': 'Good game!',
        '@pbs_file_suffix': '', '@pokemon': [{
          const LiteralFixtureSymbol('species'): const LiteralFixtureSymbol('RATTATA'),
          const LiteralFixtureSymbol('level'): 16,
          const LiteralFixtureSymbol('moves'): [const LiteralFixtureSymbol('TACKLE')],
        }],
      }),
    });
  }
  final fixture = await LiteralTileFixture.create(interpretationProfile: profile,
      scriptsBytes: scripts, includeEventSystem: true,
      switchNames: List.generate(60, (id) => 'Flag $id'),
      variableNames: List.generate(40, (id) => 'Variable $id'),
      maps: [LiteralFixtureMap(id: 1, width: 3, height: 3,
        layers: [List.filled(9, 384), List.filled(9, 0), List.filled(9, 0)],
        events: [LiteralFixtureEvent(id: 1, x: 1, y: 1, name: 'Gym Leader Brock', pages: pages),
          if (unknownBadgeCountWriter) LiteralFixtureEvent(id: 2, x: 0, y: 0,
              name: 'Unsupported other gym', pages: const [LiteralFixtureEventPage(commands: [
                LiteralFixtureEventCommand(122, [30, 30, 1, 0, 1]),
                LiteralFixtureEventCommand(355, ['unknownGymEffect()']),
                LiteralFixtureEventCommand(0, []),
              ])])])],
      extraFiles: {
        ...trainerFiles,
        'PBS/pokemon.txt': utf8.encode('[RATTATA]\nName = Rattata\n'),
        'Data/species.dat': literalFixtureMarshal({const LiteralFixtureSymbol('RATTATA'):
          const LiteralFixtureObject('GameData::Species', {'@id': LiteralFixtureSymbol('RATTATA'),
            '@species': LiteralFixtureSymbol('RATTATA'), '@form': 0, '@real_name': 'Rattata'})}),
        'Graphics/Characters/trainer_BUGCATCHER.png': image.encodePng(image.Image(width: 128, height: 192)),
        'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = trainer_BUGCATCHER\n'),
        'PBS/map_metadata.txt': utf8.encode('[001]\nMapPosition = 1,0,0\n'),
        'Data/map_metadata.dat': literalFixtureMarshal({1: const LiteralFixtureObject('GameData::MapMetadata',
          {'@id': 1, '@town_map_position': [1, 16, 5], '@real_name': 'Arena'})}),
        'Data/items.dat': literalFixtureMarshal({LiteralFixtureSymbol(machine):
          LiteralFixtureObject('GameData::Item', {
            '@id': LiteralFixtureSymbol(machine), '@real_name': machine, '@real_name_plural': '${machine}s',
            '@real_portion_name': null, '@real_portion_name_plural': null,
            '@pocket': 4, '@price': 1000, '@sell_price': 500, '@bp_price': 1,
            '@field_use': 3, '@battle_use': 0, '@flags': <Object?>[], '@consumable': true,
            '@show_quantity': null, '@move': LiteralFixtureSymbol('ROCKTOMB'),
            '@real_description': 'Teaches Rock Tomb.', '@pbs_file_suffix': '',
          }),
          const LiteralFixtureSymbol('MACHOBRACE'): const LiteralFixtureObject('GameData::Item', {
            '@id': LiteralFixtureSymbol('MACHOBRACE'), '@real_name': 'Macho Brace', '@real_name_plural': 'Macho Braces',
            '@real_portion_name': null, '@real_portion_name_plural': null,
            '@pocket': 1, '@price': 1000, '@sell_price': 500, '@bp_price': 1,
            '@field_use': 0, '@battle_use': 0, '@flags': <Object?>[], '@consumable': false,
            '@show_quantity': null, '@move': null, '@real_description': 'A held item.', '@pbs_file_suffix': '',
          }),
        }),
        'PBS/moves.txt': utf8.encode('[ROCKTOMB]\nName = Rock Tomb\n'
          '[TACKLE]\nName = Tackle\nType = NORMAL\nCategory = Physical\nPower = 40\n'
          'Accuracy = 100\nTotalPP = 35\nTarget = NearOther\nFunctionCode = None\n'),
        'Data/moves.dat': literalFixtureMarshal({
          const LiteralFixtureSymbol('TACKLE'): const LiteralFixtureObject('GameData::Move', {
            '@id': LiteralFixtureSymbol('TACKLE'), '@real_name': 'Tackle', '@type': LiteralFixtureSymbol('NORMAL'),
            '@category': 0, '@power': 40, '@accuracy': 100, '@total_pp': 35,
            '@target': LiteralFixtureSymbol('NearOther'), '@priority': 0, '@function_code': 'None',
            '@flags': <String>[], '@effect_chance': 0, '@real_description': '', '@pbs_file_suffix': '',
          }),
        }),
        skinPath: skin, iconPath: icon, audioPath: audio,
        'Audio/ME/FRLG Fanfare - Badge (Fanfare! Badge Obtained).wav': audio,
        'Audio/SE/Exit Door.wav': audio,
      });
  final source = await const RmxpSourceNormalizer().normalize(snapshot: fixture.snapshot,
      files: fixture.files, interpretationProfile: profile, includeEventSystem: true);
  final analysis = SourceEventAnalyzer.forProject(source, profile: SourceEventProfile.forProject(source)).analyze();
  final trainers = await const SourceTrainerEventBindingResolver().read(
      source: source, analysis: analysis, files: fixture.files);
  expect(trainers.byEventIdentity, hasLength(1), reason: '${trainers.refusals}');
  final items = await const SourceEventItemBindingResolver().read(snapshot: source.snapshot,
      files: fixture.files, symbols: [machine, if (gymName == 'Giovanni') 'MACHOBRACE'], eventProfile: analysis.profile);
  expect(items.bindings.keys, contains(machine), reason: '${items.quarantinedSymbols}');
  final pickups = <String, SourcePickupFeedbackBinding>{};
  for (final symbol in [machine, if (gymName == 'Giovanni') 'MACHOBRACE']) {
    final helper = symbol == machine ? SourceItemGrantHelper.receiveItem : SourceItemGrantHelper.itemBall;
    pickups[sourcePickupFeedbackBindingKey(sourceMapId: 1, sourceSymbol: symbol, helper: helper)] =
        await const SourcePickupFeedbackResolver().read(source: source, files: fixture.files,
            item: items.bindings[symbol]!, sourceMapId: 1, helper: helper);
  }
  final sounds = gymName == 'Giovanni' ? {'Exit Door':
    await const SourceEventSoundResolver().read(source: source, files: fixture.files,
        name: 'Exit Door', policy: SourceEventSoundPolicy.nativeAuthoredVolume)} : <String, SourceEventSoundBinding>{};
  final charset = source.snapshot.entries.singleWhere((file) => file.relativePath == 'Graphics/Characters/trainer_BUGCATCHER.png');
  final projection = const SourceEventProjector().project(source: source, analysis: analysis,
      nativeMaps: {1: const MapData(id: 'arena', name: 'Arena', size: GridSize(width: 3, height: 3), layers: [])},
      trainerBindings: trainers.byEventIdentity, pickupBindings: pickup ? pickups : const {},
      soundBindings: sounds,
      characterBindings: {sourceEventCharacterBindingKey(characterName: 'trainer_BUGCATCHER', pattern: 0, direction: 2):
        SourceEventCharacterBinding(characterId: 'brock', sourceSnapshotHash: source.snapshot.canonicalHash,
          sourceFileId: charset.fileId, sourceFileHash: charset.sha256!, sourcePattern: 0, sourceDirection: 2)});
  return (projection: projection, source: source, analysis: analysis,
      trainers: trainers, files: fixture.files, pickups: pickups);
}

SourceEventDefinition analyzeGym(NormalizedSourceProject source) =>
    SourceEventAnalyzer.forProject(source, profile: SourceEventProfile.forProject(source,
        scriptsArchiveHash: fixtureSourceInterpretationProfile.scriptsArchiveHash,
        interpretationProfile: fixtureSourceInterpretationProfile)).analyze().events.single;

Future<({GameState state, List<String> effects, List<String> dialogues})> _run(SourceEventProjection projection,
    SceneAsset scene, String outcome, {GameState initial = const GameState(saveId: 'gym')}) async {
  var state = initial;
  final effects = <String>[];
  final dialogues = <String>[];
  final resolver = NarrativeFactRuntimeResolver.fromFacts(projection.facts);
  final writer = NarrativeFactRuntimeWriter(resolver);
  final reloaded = SceneAsset.fromJson(jsonDecode(jsonEncode(scene.toJson())) as Map<String, dynamic>);
  final plan = buildSceneRuntimePlan(reloaded);
  expect(plan.plan, isNotNull);
  final result = await SceneRuntimeExecutor(callbacks: SceneRuntimeExecutionCallbacks(
      evaluateCondition: (intent) {
        final source = intent.conditionSource!;
        final fact = resolver.resolve(factId: source.sourceId,
            runtimeState: state.narrativeFactRuntimeState,
            storyFlags: state.storyFlags) as NarrativeFactRuntimeResolved;
        return fact.narrativeValue.matches(source.resolvedFactOperator,
            source.resolvedExpectedFactValue) ? 'true' : 'false';
      },
      showDialogue: (intent) {
        dialogues.add(projection.dialogueSources[intent.dialogueId] ?? '');
        return 'completed';
      },
      startBattle: (_) {
        if (outcome == 'cancel') throw StateError('Cancelled');
        return outcome;
      },
      playCinematic: (_) => throw StateError('No cinematic'),
      executeInteractiveCommand: (intent) {
        final command = intent.interactiveCommand!;
        if (command is SceneWorldToneInteractiveCommand || command is SceneWaitInteractiveCommand ||
            command is ScenePlaySoundEffectInteractiveCommand) {
          effects.add(switch (command) {
            SceneWorldToneInteractiveCommand() => 'tone',
            SceneWaitInteractiveCommand() => 'wait',
            _ => 'sound',
          });
          return 'completed';
        }
        if (command is! SceneGiveItemInteractiveCommand) throw StateError('Unexpected command');
        effects.add('CT');
        final grant = executeSceneItemGift(command: command, gameState: state);
        state = grant.gameState;
        return grant.outcome.name;
      },
      applyConsequence: (consequence) {
        if (consequence is SceneGiveItemConsequence) {
          final grant = executeSceneItemGift(command: SceneGiveItemInteractiveCommand(
              itemId: consequence.itemId, quantity: consequence.quantity), gameState: state);
          state = grant.gameState;
          effects.add('CT');
          return 'completed';
        }
        if (consequence is SceneAwardBadgeConsequence) {
          effects.add('badge');
          state = state.copyWith(trainerProfile: state.trainerProfile.copyWith(
              badgeIds: {...state.trainerProfile.badgeIds, consequence.badgeId}.toList()));
          return 'completed';
        }
        final result = switch (consequence) {
          SceneAdjustIntegerFactConsequence() => writer.adjustIntegerFact(gameState: state,
              factId: consequence.factId, delta: consequence.delta,
              minimum: consequence.minimum, maximum: consequence.maximum),
          SceneSetFactConsequence() => writer.setFactValue(gameState: state,
              factId: consequence.factId, value: consequence.narrativeValue),
          _ => throw StateError('Unexpected consequence ${consequence.kind}'),
        };
        effects.add(consequence is SceneAdjustIntegerFactConsequence ? 'count' : 'flag');
        expect(result.success, isTrue);
        state = result.gameState;
        return 'completed';
      })).execute(plan.plan!);
  expect(result.status, outcome == 'cancel' ? SceneRuntimeExecutionStatus.failed
      : SceneRuntimeExecutionStatus.completed, reason: '${result.errorCode}: ${result.message}');
  return (state: GameState.fromJson(jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>),
      effects: effects, dialogues: dialogues);
}

void main() {
  test('gym bindings compare only matching inventory identities and preserve exact admission', () async {
    final fixture = await _fixture();
    final trainer = fixture.trainers.byEventIdentity.values.single;
    final binding = trainer.gymLeader!;
    final comparisons = binding.sourceEntryComparisonCount;
    expect(binding.isBoundTo(fixture.source, fixture.analysis.profile,
        trainer.programs.first), isTrue);
    expect(binding.sourceEntryComparisonCount - comparisons, 3);

    final source = fixture.source, original = binding.audioFile;
    final replacement = ConverterId('${original.fileId.value}-changed');
    final snapshot = SourceSnapshot(
      logicalProjectNamespace: source.snapshot.logicalProjectNamespace,
      policyHash: source.snapshot.policyHash,
      entries: [
        for (final entry in source.snapshot.entries)
          if (entry.fileId != original.fileId) entry else SourceFileEntry(
            fileId: replacement, relativePath: entry.relativePath,
            kind: entry.kind, byteLength: entry.byteLength,
            sha256: entry.sha256, format: entry.format, family: entry.family),
      ],
      diagnostics: source.snapshot.diagnostics,
      excludedPaths: source.snapshot.excludedPaths,
      profileEvidence: source.snapshot.profileEvidence,
      state: source.snapshot.state,
    );
    expect(snapshot.canonicalHash, source.snapshot.canonicalHash);
    final changed = await const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: _RekeyedGymSourceFiles(fixture.files, replacement, original.fileId),
      includeEventSystem: true,
      interpretationProfile: source.interpretationProfile,
    );
    final beforeRefusal = binding.sourceEntryComparisonCount;
    expect(binding.isBoundTo(changed, fixture.analysis.profile,
        trainer.programs.first), isFalse);
    expect(binding.sourceEntryComparisonCount, beforeRefusal);
  });

  test('qualified authored member moves remain admitted through the trainer event header guard', () async {
    final fixture = await _fixture(authoredTackle: true);
    expect(fixture.trainers.byEventIdentity.values.single.nativeTrainer.team.single.moves, ['tackle']);
    expect((fixture.projection.semanticEvidence['events'] as List).single['status'], 'adaptedStaticSemantics');
  });
  for (final name in ['Blaine', 'Giovanni']) {
    test('complete $name stages project without dropping conditional dialogue or post-victory actions', () async {
      final fixture = await _fixture(gymName: name);
      final row = (fixture.projection.semanticEvidence['events'] as List).single as Map;
      expect(row['status'], 'adaptedStaticSemantics', reason: '${row['gaps']}');
      final projection = fixture.projection;
      final win = await _run(projection, projection.scenes.firstWhere((s) => s.metadata['sourcePageIndex'] == '0'), 'victory');
      expect(win.effects, ['badge', 'CT', 'count', 'flag']);
      final after = projection.scenes.firstWhere((s) => s.metadata['sourcePageIndex'] == '1');
      if (name == 'Blaine') {
        final analyzer = SourceEventAnalyzer.forProject(fixture.source, profile: fixture.analysis.profile);
        final writer = NarrativeFactRuntimeWriter(NarrativeFactRuntimeResolver.fromFacts(projection.facts));
        for (final value in [0, 5, -1]) {
          final set = writer.setFactValue(gameState: win.state,
              factId: sourceEventIntegerVariableBindingId(analyzer.variableFactId(38)), value: NarrativeValue.integer(value));
          final result = await _run(projection, after, 'victory', initial: set.gameState);
          expect(result.effects, isEmpty);
          expect(result.dialogues.any((text) => text.contains('A complete memory $value.')), value != 0);
          expect(result.dialogues.where((text) => text.contains('A complete memory')), hasLength(value == 0 ? 0 : 1));
        }
      } else {
        final departure = await _run(projection, after, 'victory', initial: win.state);
        expect(departure.effects, ['sound', 'tone', 'wait', 'flag', 'tone']);
        final pickup = projection.scenes.firstWhere((s) => s.metadata['sourcePageIndex'] == '2');
        final collected = await _run(projection, pickup, 'victory', initial: departure.state);
        expect(collected.effects, ['CT', 'flag']);
        final removed = projection.scenes.firstWhere((s) => s.metadata['sourcePageIndex'] == '3');
        final finalState = await _run(projection, removed, 'victory', initial: collected.state);
        expect(finalState.effects, isEmpty);
        expect(finalState.state.toJson(), collected.state.toJson());
        final variants = projection.nativeMaps[1]!.entities.single.presentation!.variants;
        expect(variants.where((v) => v.characterId == null), hasLength(2));
        expect(variants.where((v) => v.characterId == null).every((v) => !v.blocksMovement), isTrue);
      }
    });
  }
  late Future<({SourceEventProjection projection, NormalizedSourceProject source,
    SourceEventAnalysis analysis, SourceTrainerEventBindings trainers,
    SourceFilePort files, Map<String, SourcePickupFeedbackBinding> pickups})> shared;
  setUpAll(() { shared = _fixture(); });
  test('gym rewards retain native badge policy, machine bag grant and source music', () async {
    final fixture = await shared;
    final projection = fixture.projection;
    final row = (projection.semanticEvidence['events'] as List).single as Map;
    expect(row['status'], 'adaptedStaticSemantics', reason: '${row['gaps']}');
    final trainer = fixture.trainers.byEventIdentity.values.single;
    expect(trainer.gymLeader!.badge.fieldAbilityUnlock, FieldAbility.flash);
    expect(fixture.pickups.values.single.item.useGaps, contains('item.use.machine_not_projected'));
    final scene = projection.scenes.singleWhere((scene) => scene.metadata['sourcePageIndex'] == '0');
    final nodes = scene.graph.nodes;
    expect(nodes.where((node) => node.payload is SceneBattlePayload), hasLength(1));
    final actions = nodes.map((node) => node.payload).whereType<SceneActionPayload>();
    expect(actions.map((action) => action.consequence).whereType<SceneAwardBadgeConsequence>()
        .single.badgeId, trainer.gymLeader!.badge.id);
    final cue = nodes.map((node) => node.payload).whereType<SceneYarnDialoguePayload>()
        .expand((payload) => payload.linePolicies).map((policy) => policy.feedback.audioCue)
        .whereType<DialogueAudioCue>().firstWhere((cue) => cue.mediaAssetId == trainer.gymLeader!.mediaId);
    expect(cue.role, DialogueAudioCueRole.musicEffect);
    expect(cue.volume, 1);
    expect(trainer.gymLeader!.toJson()['sourceOpcode249TimingParityQualified'], isFalse);
  });

  for (final outcome in ['victory', 'defeat', 'cancel']) {
    test('gym $outcome grants rewards exclusively on native victory', () async {
      final fixture = await shared;
      final projection = fixture.projection;
      final scene = projection.scenes.singleWhere((scene) => scene.metadata['sourcePageIndex'] == '0');
      final result = await _run(projection, scene, outcome);
      expect(result.effects, outcome == 'victory' ? ['badge', 'CT', 'count', 'flag'] : isEmpty);
      expect(result.state.trainerProfile.badgeIds.length, outcome == 'victory' ? 1 : 0);
      expect(result.state.bag.entries.length, outcome == 'victory' ? 1 : 0);
      final analyzer = SourceEventAnalyzer.forProject(fixture.source, profile: fixture.analysis.profile);
      final resolver = NarrativeFactRuntimeResolver.fromFacts(projection.facts);
      final count = resolver.resolve(factId: sourceEventIntegerVariableBindingId(analyzer.variableFactId(30)),
          runtimeState: result.state.narrativeFactRuntimeState, storyFlags: result.state.storyFlags) as NarrativeFactRuntimeResolved;
      expect(count.narrativeValue.intValue, outcome == 'victory' ? 1 : 0);
      if (outcome == 'victory') {
        final map = projection.nativeMaps[1]!;
        final gymBinding = fixture.trainers.byEventIdentity.values.single.gymLeader!;
        final project = ProjectManifest(name: 'Gym', tilesets: const [],
            maps: [ProjectMapEntry(id: map.id, name: map.name, relativePath: 'maps/arena.json')],
            eventRegistry: projection.registry, facts: projection.facts, scenes: projection.scenes,
            dialogues: projection.dialogues, badges: [gymBinding.badge],
            trainers: [fixture.trainers.byEventIdentity.values.single.nativeTrainer]);
        final authority = NarrativeEventDispatchAuthority.prepare(
            registryResult: EventRegistryDecodeResult.decoded(projection.registry),
            occurrence: NarrativeEventOccurrence(source: NarrativeEventSourceRef.entityInteract(map.id, map.entities.single.id)),
            factResolver: resolver, projectCatalog: buildNarrativeEventProjectCatalog(project: project, maps: [map]),
            project: project, maps: [map]);
        expect(authority, isA<NarrativeEventDispatchAuthorityReady>());
        final decision = (authority as NarrativeEventDispatchAuthorityReady).plan(gameState: result.state);
        final after = projection.scenes.singleWhere((scene) => scene.metadata['sourcePageIndex'] == '1');
        expect((decision as NarrativeEventDispatchHandled).sceneId, after.id);
        final replay = await _run(projection, after, 'victory', initial: result.state);
        expect(replay.effects, isEmpty);
        expect(replay.state.toJson(), result.state.toJson());
      }
    });
  }

  test('missing CT attribution feedback refuses the complete gym event', () async {
    final fixture = await _fixture(pickup: false);
    final row = (fixture.projection.semanticEvidence['events'] as List).single as Map;
    expect(row['status'], 'quarantinedWholeEvent');
    expect(row['gaps'], contains('sourceReceiveItemBindingMissing'));
    expect(fixture.projection.scenes, isEmpty);
  });

  test('another unqualified badge-count writer keeps the complete gym event refused', () async {
    final fixture = await _fixture(unknownBadgeCountWriter: true);
    final row = (fixture.projection.semanticEvidence['events'] as List)
        .cast<Map>().singleWhere((row) => row['sourceIdentity'] ==
            fixture.analysis.eventAt(1, 1)!.identity.value);
    expect(row['status'], 'quarantinedWholeEvent');
    expect(row['gaps'], contains('sourceVariableWriterUnqualified'));
    expect(fixture.projection.scenes, isEmpty);
  });

  test('gym composer writes its badge, music, machine attribution and scene for strict reopening', () async {
    final fixture = await _fixture(authoredTackle: true);
    final temporary = await Directory.systemTemp.createTemp('gym-native-');
    addTearDown(() => temporary.delete(recursive: true));
    final literal = await const LiteralTileComposer().compose(source: fixture.source,
        files: fixture.files, selectedSourceMapIds: [1], projectName: 'Gym',
        parentPath: temporary.path, folderName: 'native');
    final semantic = (await const SourceSemanticStudyComposer().compose(
        source: fixture.source, base: literal, files: fixture.files))!;
    final nativeCatalog = _fixtureNativeCatalog();
    final pbs = await const SourcePbsParser().read(snapshot: fixture.source.snapshot, files: fixture.files);
    final release = await NativeEncounterCatalogQualification.prepare(snapshot: fixture.source.snapshot,
        source: pbs, files: fixture.files, nativeCatalog: nativeCatalog, selectedSourceMapIds: [1]);
    final composed = (await SourceEventStudyComposer(nativeEncounterQualification: release).compose(
        source: fixture.source, base: semantic, files: fixture.files))!;
    final catalog = (await SourceCatalogStudyComposer(nativeEncounterQualification: release).compose(
        source: fixture.source, base: composed.draft, files: fixture.files))!;
    expect((composed.projection.semanticEvidence['events'] as List).single['status'],
        'adaptedStaticSemantics');
    final gym = fixture.trainers.byEventIdentity.values.single.gymLeader!;
    expect(composed.draft.mutations.where((m) => m.actionId == 'campaign.badge.upsert'), hasLength(1));
    expect(composed.draft.mutations.where((m) => m.actionId == 'scene.dialogue.audioMedia.import')
        .any((m) => m.parameters['mediaId'] == gym.mediaId), isTrue);
    final approval = approveNativeFixtureDraft(catalog.draft);
    final receipt = await NativeProjectWriter().write(approval.plan, approval.context, catalog.draft);
    expect(receipt.verified, isTrue);
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
    final opener = ProjectOpenService(policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(receipt.projectPath);
    try {
      final native = await ProjectSnapshotLoader(handles: handles).load(
          opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
      expect(native.loadDiagnostics, isEmpty);
      expect(native.manifest.badges.single.toJson(), gym.badge.toJson());
      expect(native.manifest.trainers.single.team.single.moves, ['tackle']);
      expect(native.manifest.scenes.expand((s) => s.graph.nodes).map((n) => n.payload)
          .whereType<SceneActionPayload>().map((p) => p.consequence)
          .whereType<SceneAwardBadgeConsequence>().single.badgeId, gym.badge.id);
    } finally {
      opener.closeWorkspace(opened.workspaceHandle);
    }
  });
}
