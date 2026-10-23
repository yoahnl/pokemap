import 'dart:convert';
import 'dart:io';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as image;
import 'package:test/test.dart';
import 'package:avelune_converter_adapters/src/source_trainer_event_bindings.dart';

import 'support/literal_tile_fixture.dart';
import 'support/native_trainer_fixture.dart';

final class _Files implements SourceFilePort {
  _Files(this.bytes, this.paths, this.sourceRoot);
  final Map<ConverterId, List<int>> bytes;
  final Map<ConverterId, String> paths;
  final String sourceRoot;

  @override
  Future<List<int>> read(ConverterId id) async => bytes.containsKey(id)
      ? List.of(bytes[id]!)
      : File('$sourceRoot/${paths[id]}').readAsBytes();
}

Future<(NormalizedSourceProject, SourceFilePort)> _source(
    String folder, String sourceRoot,
    {bool unrelatedRosterChange = false, String? additionalHeader}) async {
  final input = jsonDecode(await File('$folder/snapshot.json').readAsString())
      as Map<String, dynamic>;
  final frozen =
      jsonDecode(await File('$folder/normalized.json').readAsString())
          as Map<String, dynamic>;
  final bytes = <ConverterId, List<int>>{
    for (final dynamic row in frozen['archive']['files'])
      ConverterId(row['entry']['fileId'] as String):
          base64Decode(row['rawBytes'] as String)
  };
  final paths = <ConverterId, String>{
    for (final dynamic row in input['entries'])
      ConverterId(row['fileId'] as String): row['relativePath'] as String,
  };
  final rosterId = paths.entries
      .singleWhere((entry) => entry.value == 'PBS/trainers.txt')
      .key;
  final rosterBytes = await File('$sourceRoot/PBS/trainers.txt').readAsBytes();
  if (unrelatedRosterChange) {
    bytes[rosterId] = [
      ...rosterBytes,
      ...utf8.encode('\n# unrelated attested comment\n')
    ];
  }
  if (additionalHeader != null) {
    final raw = utf8.decode(rosterBytes);
    bytes[rosterId] = utf8.encode(raw.replaceFirst('[FRLG_BUGCATCHER,Brent]',
        '[FRLG_BUGCATCHER,Brent]\n$additionalHeader'));
  }
  final rosterChanged = bytes.containsKey(rosterId);
  final files = _Files(bytes, paths, sourceRoot);
  final snapshot = SourceSnapshot(
      logicalProjectNamespace:
          ConverterId(input['logicalProjectNamespace'] as String),
      policyHash: Sha256Hash(input['policyHash'] as String),
      entries: [
        for (final dynamic row in input['entries'])
          SourceFileEntry(
              fileId: ConverterId(row['fileId'] as String),
              relativePath: row['relativePath'] as String,
              kind: SourceNodeKind.values.byName(row['kind'] as String),
              byteLength: row['fileId'] == rosterId.value && rosterChanged
                  ? bytes[rosterId]!.length
                  : row['byteLength'] as int,
              sha256: row['sha256'] == null
                  ? null
                  : Sha256Hash(row['fileId'] == rosterId.value && rosterChanged
                      ? crypto.sha256.convert(bytes[rosterId]!).toString()
                      : row['sha256'] as String),
              format: row['format'] as String,
              family: row['family'] as String)
      ],
      diagnostics: [],
      excludedPaths: (input['excludedPaths'] as List).cast<String>(),
      profileEvidence: [
        for (final dynamic row in input['profileEvidence'])
          SourceProfileEvidence(
              relativePath: row['relativePath'] as String,
              fileHash: Sha256Hash(row['fileHash'] as String),
              version: row['version'] as String,
              line: row['line'] as int,
              excerpt: row['excerpt'] as String)
      ],
      state: SourceScanState.values.byName(input['state'] as String));
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: files,
      selectedMapIds: {98, 100},
      includeEventSystem: true);
  return (source, files);
}

void main() {
  test('targeted trainer reanalysis accepts source and refuses forged evidence',
      () async {
    const roster = (type: 'FRLG_BUGCATCHER', name: 'Brent', version: 0);
    final trainer = nativeTrainerFixtureEvent(roster, 1);
    final encounter = trainer.pages.first;
    final fixture = await LiteralTileFixture.create(
        interpretationProfile: syntheticSourceInterpretationProfile,
        scriptsBytes: syntheticInterpretationArchive,
        includeEventSystem: true,
        extraFiles: {
          ...nativeTrainerFixtureFiles([roster]),
          'PBS/pokemon.txt': utf8.encode('[RATTATA]\nName = Rattata\n'),
          'Data/species.dat': literalFixtureMarshal({
            const LiteralFixtureSymbol('RATTATA'):
                const LiteralFixtureObject('GameData::Species', {
              '@id': LiteralFixtureSymbol('RATTATA'),
              '@species': LiteralFixtureSymbol('RATTATA'),
              '@form': 0,
              '@real_name': 'Rattata',
            }),
          }),
          'Graphics/Characters/OriginalTrainer.png':
              image.encodePng(image.Image(width: 128, height: 192)),
        },
        maps: [
          LiteralFixtureMap(id: 1, width: 4, height: 3, layers: [
            List.filled(12, 384), List.filled(12, 0), List.filled(12, 0),
          ], events: [
            LiteralFixtureEvent(
                id: trainer.id, x: trainer.x, y: trainer.y, name: trainer.name,
                pages: [
                  LiteralFixtureEventPage(
                      characterName: encounter.characterName,
                      trigger: encounter.trigger,
                      commands: [
                        ...encounter.commands.take(6),
                        const LiteralFixtureEventCommand(355,
                            [r'$game_self_switches[[1,2,"A"]]=true'], indent: 1),
                        const LiteralFixtureEventCommand(655,
                            [r'$game_self_switches[[1,3,"A"]]=true'], indent: 1),
                        ...encounter.commands.skip(6),
                      ]),
                  trainer.pages.last,
                ]),
            const LiteralFixtureEvent(id: 2, x: 2, y: 1, pages: [
              LiteralFixtureEventPage(selfSwitch: 'A', trigger: 4, commands: [
                LiteralFixtureEventCommand(355, ['opaqueController()']),
                LiteralFixtureEventCommand(0, []),
              ]),
              LiteralFixtureEventPage(selfSwitch: 'B', commands: [
                LiteralFixtureEventCommand(0, []),
              ]),
            ]),
            const LiteralFixtureEvent(id: 3, x: 3, y: 1, pages: []),
          ]),
        ]);
    final source = fixture.source;
    final analysis = SourceEventAnalyzer.forProject(source,
        profile: SourceEventProfile.forProject(source)).analyze();
    const resolver = SourceTrainerEventBindingResolver();
    final accepted = await resolver.read(
        source: source, analysis: analysis, files: fixture.files);
    final original = analysis.eventAt(1, 1)!;
    final program = original.pages.first.body.nodes.single as SourceTrainerProgramNode;
    final switches = program.victoryContinuation.nodes.whereType<SourceSelfSwitchNode>().toList();
    final analyzer = SourceEventAnalyzer.forProject(source, profile: analysis.profile);
    expect(switches.map((node) => node.factId), [
      analyzer.selfFactId(1, 1, 'A'),
      analyzer.selfFactId(1, 2, 'A'),
      analyzer.selfFactId(1, 3, 'A'),
    ]);
    expect(switches.every((node) => node.value), isTrue);
    final dormancy = auditSourceParallelDormancy(
        source: source, profile: analysis.profile).toJson();
    final writes = (dormancy['nativeWriteSet'] as List).cast<Map>();
    expect(writes.map((write) => write['factId']), containsAll(
        switches.map((node) => node.factId)));
    expect(dormancy['refusals'],
        contains('sourceDormancyControllerWriterExecutable'));
    expect(accepted.byEventIdentity.keys, [original.identity]);
    expect(accepted.refusals, isEmpty);
    for (final variant in ['raw', 'graphic', 'body']) {
      final page = original.pages.first;
      final changedPage = SourceEventPageAnalysis(
          sourcePage: page.sourcePage,
          locator: page.locator,
          condition: page.condition,
          graphic: variant == 'graphic' ? null : page.graphic,
          body: variant == 'body'
              ? SourceEventBlock(span: page.body.span, nodes: [])
              : page.body,
          rawDataRef: variant == 'raw' ? null : page.rawDataRef,
          diagnostics: []);
      final changed = SourceEventDefinition(
          sourceMapId: original.sourceMapId,
          sourceEventId: original.sourceEventId,
          sourceFileId: original.sourceFileId,
          identity: original.identity,
          name: original.name,
          x: original.x,
          y: original.y,
          locator: original.locator,
          pages: [changedPage, original.pages.last]);
      final refused = await resolver.read(source: source,
          analysis: SourceEventAnalysis(profile: analysis.profile,
              events: [changed], diagnostics: analysis.diagnostics),
          files: fixture.files);
      expect(refused.byEventIdentity, isEmpty, reason: variant);
      expect(refused.refusals[original.identity],
          'events.trainer.program_binding', reason: variant);
    }
  });
  final archive = Platform.environment['AVELUNE_AC13_DOOR_ARCHIVE'];
  final sourceRoot = Platform.environment['AVELUNE_AC13_SOURCE_ROOT'];
  group('source trainer event bindings', () {
    late NormalizedSourceProject source;
    late SourceFilePort files;
    late SourceEventAnalysis analysis;
    late SourceTrainerEventBindings bindings;
    setUpAll(() async {
      final fixture = await _source(archive!, sourceRoot!);
      source = fixture.$1;
      files = fixture.$2;
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.forProject(source,
interpretationProfile: fixtureSourceInterpretationProfile,
))
          .analyze();
      bindings = await const SourceTrainerEventBindingResolver()
          .read(source: source, analysis: analysis, files: files);
    });

    test('binds all eleven complete source programs to exact native teams', () {
      expect(bindings.byEventIdentity, hasLength(11),
          reason: bindings.refusals.toString());
      expect(
          bindings.byEventIdentity.values
              .expand((binding) => binding.nativeTrainer.team),
          hasLength(27));
      for (final event in analysis.events.where((event) => event.pages
          .expand((page) => page.body.nodes)
          .whereType<SourceTrainerProgramNode>()
          .isNotEmpty)) {
        final binding = bindings.byEventIdentity[event.identity]!;
        final program =
            event.pages.first.body.nodes.single as SourceTrainerProgramNode;
        expect(binding.sourceIdentity.trainerType, program.trainerType);
        expect(binding.sourceIdentity.trainerName, program.trainerName);
        expect(binding.sourceIdentity.version, 0);
        expect(binding.nativeTrainer.id, binding.sourceIdentity.sourceId.value);
        expect(binding.nativeTrainerHash,
            canonicalHashOf(binding.nativeTrainer.toJson()));
        expect(
            binding.isBoundToEvent(
                source: source, analysis: analysis, event: event),
            isTrue);
      }
      expect(() => bindings.byEventIdentity.clear(), throwsUnsupportedError);
    });

    test('PBS victory speech remains distinct from inert EndSpeech comment',
        () {
      final event = analysis.eventAt(98, 1)!;
      final binding = bindings.byEventIdentity[event.identity]!;
      expect(binding.loseText, 'WHAT? What a total waste of time!');
      expect(binding.loseTextLocator!.file, 'PBS/trainers.txt');
      final program =
          event.pages.first.body.nodes.single as SourceTrainerProgramNode;
      expect(program.endSpeechComment,
          r'EndSpeech: WHAT?\nWhat a total waste of time!');
      expect(binding.toJson()['sourceScriptsExecuted'], 0);
      expect(binding.toJson()['nativeExecutionQualified'], isFalse);
      expect(binding.toJson()['qualificationHash'],
          bindings.qualification!.evidenceHash.value);
      expect(binding.nativeBundleHash.value,
          bindings.qualification!.evidence['nativeCatalogHash']);
    });

    test('binding rejects a different event and mismatched profile', () {
      final binding =
          bindings.byEventIdentity[analysis.eventAt(98, 1)!.identity]!;
      expect(
          binding.isBoundToEvent(
              source: source,
              analysis: analysis,
              event: analysis.eventAt(98, 2)!),
          isFalse);
      final badProfile = SourceEventProfile.forProject(source,
          scriptsArchiveHash: Sha256Hash('0' * 64),
interpretationProfile: fixtureSourceInterpretationProfile,
);
      final badAnalysis =
          SourceEventAnalyzer.forProject(source, profile: badProfile).analyze();
      expect(
          binding.isBoundToEvent(
              source: source,
              analysis: badAnalysis,
              event: analysis.eventAt(98, 1)!),
          isFalse);
    });

    test('roster bytes must match their complete sealed source inventory',
        () async {
      final roster = source.snapshot.entries
          .singleWhere((entry) => entry.relativePath == 'PBS/trainers.txt');
      final altered = _Files({
        roster.fileId: [...await files.read(roster.fileId), 10]
      }, {
        for (final entry in source.snapshot.entries)
          entry.fileId: entry.relativePath
      }, sourceRoot!);
      await expectLater(
          const SourceTrainerEventBindingResolver()
              .read(source: source, analysis: analysis, files: altered),
          throwsA(isA<ContractError>()
              .having((error) => error.code, 'code', 'pbs.source_changed')));
    });

    test('binding refuses forged raw, graphic and body analysis', () {
      final original = analysis.eventAt(98, 1)!;
      final binding = bindings.byEventIdentity[original.identity]!;
      final page = original.pages.first;
      for (final variant in ['raw', 'graphic', 'body']) {
        final changedPage = SourceEventPageAnalysis(
            sourcePage: page.sourcePage,
            locator: page.locator,
            condition: page.condition,
            graphic: variant == 'graphic' ? null : page.graphic,
            body: variant == 'body'
                ? SourceEventBlock(span: page.body.span, nodes: [])
                : page.body,
            rawDataRef: variant == 'raw' ? null : page.rawDataRef,
            diagnostics: []);
        final changed = SourceEventDefinition(
            sourceMapId: original.sourceMapId,
            sourceEventId: original.sourceEventId,
            sourceFileId: original.sourceFileId,
            identity: original.identity,
            name: original.name,
            x: original.x,
            y: original.y,
            locator: original.locator,
            pages: [changedPage, original.pages.last]);
        expect(
            binding.isBoundToEvent(
                source: source, analysis: analysis, event: changed),
            isFalse,
            reason: variant);
      }
    });

    test('unsupported metadata refuses only its complete trainer binding',
        () async {
      final fixture = await _source(archive!, sourceRoot!,
          additionalHeader: 'Items = POTION');
      final changed = fixture.$1;
      final changedAnalysis = SourceEventAnalyzer.forProject(changed,
              profile: SourceEventProfile.forProject(changed,
interpretationProfile: fixtureSourceInterpretationProfile,
))
          .analyze();
      final result = await const SourceTrainerEventBindingResolver()
          .read(source: changed, analysis: changedAnalysis, files: fixture.$2);
      expect(result.byEventIdentity, hasLength(10));
      expect(result.byEventIdentity.containsKey(changed.eventIdentity(98, 1)),
          isFalse);
      expect(result.refusals[changed.eventIdentity(98, 1)],
          'native_trainer.trainer_override');
    });

    test('attested unrelated roster change preserves exact trainer bindings',
        () async {
      final fixture =
          await _source(archive!, sourceRoot!, unrelatedRosterChange: true);
      final changed = fixture.$1;
      final changedAnalysis = SourceEventAnalyzer.forProject(changed,
              profile: SourceEventProfile.forProject(changed,
interpretationProfile: fixtureSourceInterpretationProfile,
))
          .analyze();
      final result = await const SourceTrainerEventBindingResolver()
          .read(source: changed, analysis: changedAnalysis, files: fixture.$2);
      expect(result.byEventIdentity, hasLength(11));
      final before = bindings.byEventIdentity[source.eventIdentity(98, 1)]!;
      final after = result.byEventIdentity[changed.eventIdentity(98, 1)]!;
      expect(after.nativeTrainerHash, before.nativeTrainerHash);
      expect(
          after.sourceRosterFile.sha256, isNot(before.sourceRosterFile.sha256));
      expect(after.qualificationHash, isNot(before.qualificationHash));
      expect(
          before.isBoundToEvent(
              source: changed,
              analysis: changedAnalysis,
              event: changedAnalysis.eventAt(98, 1)!),
          isFalse);
    });
  }, skip: archive == null || sourceRoot == null);
}
