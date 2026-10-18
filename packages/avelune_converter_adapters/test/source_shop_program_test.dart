import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/declared_program_fixture.dart';

Map<String, Object?> _command(int code, List<Object?> parameters,
        [int indent = 0]) =>
    {
      '__class__': 'RPG::EventCommand',
      'code': code,
      'indent': indent,
      'parameters': parameters
    };

Future<({NormalizedSourceProject source, SourceEventAnalysis analysis})>
    _analyze(List<Map<String, Object?>> commands) async {
  final binding =
      (fixtureSourceInterpretationProfile.toJson()['declaredPrograms'] as List)
          .cast<Map>()
          .singleWhere((entry) => entry['family'] == 'centerPc');
  final page = Map<String, Object?>.from(
      jsonDecode(jsonEncode((binding['pages'] as Map)['activation'])) as Map);
  page['list'] = [...commands, _command(0, [])];
  (page['graphic'] as Map)['tile_id'] = 0;
  final fixture = await createDeclaredProgramFixture(
      namespace: 'literal-shop',
      profile: syntheticSourceInterpretationProfile,
      maps: {
        17: [
          DeclaredProgramFixtureEvent(
              id: 2, name: 'Any vendor', x: 3, y: 4, pages: [page])
        ]
      });
  return (
    source: fixture.source,
    analysis: SourceEventAnalyzer.forProject(fixture.source,
            profile: SourceEventProfile.forProject(fixture.source))
        .analyze()
  );
}

void main() {
  test(
      'shop source attestation rejects relocated renamed foreign raw or forged graphic events',
      () async {
    final result = await _analyze([
      _command(355, ['pbPokemonMart([:POTION])'])
    ]);
    final original = result.analysis.events.single;
    SourceEventDefinition copy(
            {int? x,
            String? name,
            ConverterId? file,
            List<SourceEventPageAnalysis>? pages}) =>
        SourceEventDefinition(
            sourceMapId: original.sourceMapId,
            sourceEventId: original.sourceEventId,
            sourceFileId: file ?? original.sourceFileId,
            identity: original.identity,
            name: name ?? original.name,
            x: x ?? original.x,
            y: original.y,
            locator: original.locator,
            pages: pages ?? original.pages);
    final page = original.pages.single;
    SourceEventPageAnalysis changedPage(
            {SourceEventGraphic? graphic, bool removeRaw = false}) =>
        SourceEventPageAnalysis(
            sourcePage: page.sourcePage,
            locator: page.locator,
            condition: page.condition,
            graphic: graphic ?? page.graphic,
            body: page.body,
            rawDataRef: removeRaw ? null : page.rawDataRef,
            diagnostics: page.diagnostics);
    final graphic = page.graphic!;
    final forged = SourceEventGraphic(
        tileId: graphic.tileId,
        characterName: graphic.characterName,
        hue: graphic.hue,
        direction: graphic.direction == 2 ? 4 : 2,
        pattern: graphic.pattern,
        opacity: graphic.opacity,
        blendType: graphic.blendType,
        moveType: graphic.moveType,
        moveSpeed: graphic.moveSpeed,
        moveFrequency: graphic.moveFrequency,
        walkAnime: graphic.walkAnime,
        stepAnime: graphic.stepAnime,
        directionFix: graphic.directionFix,
        through: graphic.through,
        alwaysOnTop: graphic.alwaysOnTop,
        moveRouteNodeId: graphic.moveRouteNodeId);
    expect(
        sourceShopEventMatchesSource(
            source: result.source, analysis: result.analysis, event: original),
        isTrue);
    for (final event in [
      copy(x: original.x + 1),
      copy(name: 'Forged vendor'),
      copy(file: ConverterId('foreign-file')),
      copy(pages: [changedPage(removeRaw: true)]),
      copy(pages: [changedPage(graphic: forged)])
    ]) {
      expect(
          sourceShopEventMatchesSource(
              source: result.source, analysis: result.analysis, event: event),
          isFalse);
    }
  });
  test('bounded literal mart preserves order and multiline source spans',
      () async {
    final result = await _analyze([
      _command(355, ['pbPokemonMart([:POKEBALL,']),
      _command(655, [':POTION, :ANTIDOTE])'])
    ]);
    final node = result.analysis.events.single.pages.single.body.nodes.single
        as SourceShopProgramNode;
    expect(node.sourceItemSymbols, ['POKEBALL', 'POTION', 'ANTIDOTE']);
    expect(node.span.firstCommandIndex, 0);
    expect(node.span.lastCommandIndex, 1);
    expect(node.rawDataRef.locator!.pageIndex, 0);
    expect(node.sourceSnapshotHash, result.source.snapshot.canonicalHash);
    expect(node.normalizationHash, result.source.canonicalHash);
    expect(result.analysis.events.single.isQuarantined, isFalse);
    expect(
        sourceShopBindings(
            source: result.source,
            analysis: result.analysis,
            events: result.analysis.events,
            itemBindings: const {}),
        isEmpty);
  });

  test('a literal shop remains within its original parcel branch', () async {
    final result = await _analyze([
      _command(111, [0, 86, 0]),
      _command(355, ['pbPokemonMart([:POKEBALL,:POTION])'], 1),
      _command(0, [], 1),
      _command(411, []),
      _command(101, ['Please deliver the parcel.'], 1),
      _command(0, [], 1),
      _command(412, [])
    ]);
    final conditional = result.analysis.events.single.pages.single.body.nodes
        .single as SourceConditionalNode;
    expect(conditional.condition.factId, endsWith(':switch:86'));
    expect(conditional.whenTrue.nodes.single, isA<SourceShopProgramNode>());
    expect((conditional.whenFalse.nodes.single as SourceTextNode).text,
        'Please deliver the parcel.');
  });

  for (final source in [
    'pbPokemonMart(stock)',
    'pbPokemonMart([:POTION], "Hello")',
    'pbPokemonMart([:POTION], nil, true)',
    'pbPokemonMart([:POTION]); extra()',
    'pbPokemonMart([:POTION,:POTION])',
    'pbPokemonMart([:POTION] + other)',
    'pbPokemonMart([:POTION])\nextra()',
    'pbPokemonMart([])',
    'pbPokemonMart([:POTION]) # changed',
    'pbPokemonMart([:"POTION"])'
  ]) {
    test('mart refuses dynamic or unsupported literal $source', () async {
      final result = await _analyze([
        _command(355, [source])
      ]);
      expect(sourceShopPrograms(result.analysis.events.single), isEmpty);
      expect(result.analysis.events.single.isQuarantined, isTrue);
    });
  }

  test('an adjacent script cannot be silently swallowed by a shop', () async {
    final result = await _analyze([
      _command(355, ['pbPokemonMart([:POTION])']),
      _command(355, ['unsafe()'])
    ]);
    expect(sourceShopPrograms(result.analysis.events.single), isEmpty);
    expect(result.analysis.events.single.isQuarantined, isTrue);
  });
}
