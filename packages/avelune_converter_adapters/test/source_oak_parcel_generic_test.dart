import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/oak_parcel_fixture.dart';

SourceOakParcelProgram? _program(NormalizedSourceProject source) {
  final map = source.maps.single.map;
  return SourceOakParcelProgram.read(
      source: source,
      profile: SourceEventProfile.forProject(source),
      sourceMapId: map.sourceMapId,
      event: map.events.singleWhere((event) => event.pages.length == 6));
}

void main() {
  test('closed parcel fixture recognizes the original structural program',
      () async {
    final fixture = await parcelFixture();
    expect(_program(fixture.source), isNotNull);
  });

  test('closed parcel captures renamed map actors switches items dex and text',
      () async {
    final events = parcelFixtureEvents();
    renameParcelFixture(events);
    final fixture = await parcelFixture(mapId: 731, events: events);
    final program = _program(fixture.source);
    expect(program, isNotNull);
    final json = program!.toJson();
    expect(json['sourceMapId'], 731);
    expect(json['sourceEventId'], 41);
    expect(json['parcelSymbol'], 'SEALEDLETTER');
    expect(json['rewardSymbol'], 'CAPSULE');
    expect(json['rewardQuantity'], 7);
    expect(json['dexIndex'], 3);
    expect(json['dexSwitchId'], 160);
    expect(json['companionEventIds'], [61, 62, 63]);
    expect((json['approaches'] as List).map((e) => e['sourceActorEventId']),
        [41, 41, 41, 41]);
    expect(
        program.isBoundTo(
            source: fixture.source,
            profile: SourceEventProfile.forProject(fixture.source),
            event: fixture.source.maps.single.map.events
                .singleWhere((event) => event.sourceEventId == 41)),
        isTrue);
  });

  test('closed parcel audits captured dex switch and companion facts',
      () async {
    final events = parcelFixtureEvents();
    renameParcelFixture(events);
    final fixture = await parcelFixture(mapId: 731, events: events);
    final source = fixture.source;
    final profile = SourceEventProfile.forProject(source);
    final event = SourceEventAnalyzer.forProject(source, profile: profile)
        .analyze()
        .eventAt(731, 41)!;
    expect(
        event.pages.take(4).every(
            (page) => page.body.nodes.single is SourceOakParcelProgramNode),
        isTrue);
    final audit =
        SourceParallelDormancyAuditor.forProject(source, profile: profile)
            .audit()
            .toJson();
    expect(audit['refusals'],
        isNot(contains('sourceDormancyWriterUnqualified:731:41')));
    final writes = (audit['nativeWriteSet'] as List)
        .cast<Map>()
        .where((row) => row['sourceEventId'] == 41)
        .map((row) => (row['factId'], row['value']))
        .toSet();
    final analyzer = SourceEventAnalyzer.forProject(source, profile: profile);
    expect(
        writes,
        containsAll([
          (analyzer.globalFactId(160), true),
          (analyzer.selfFactId(731, 61, 'A'), true),
          (analyzer.selfFactId(731, 62, 'A'), true),
          (analyzer.selfFactId(731, 63, 'A'), true),
          (
            'source:${source.snapshot.logicalProjectNamespace.value}:player:pokedex:unlocked:3',
            true
          ),
        ]));
  });

  test('closed parcel captures a singular machine reward without naming it',
      () async {
    final events = parcelFixtureEvents();
    renameParcelFixture(events);
    for (final page in events['1']['pages']) {
      for (final command in page['list']) {
        final parameters = command['parameters'] as List;
        if (parameters.length == 1 &&
            parameters.single == 'pbReceiveItem(:CAPSULE,7)') {
          parameters[0] = 'pbReceiveItem(:TM101,1)';
        }
      }
    }
    final fixture = await parcelFixture(mapId: 731, events: events);
    final program = _program(fixture.source);
    expect(program, isNotNull);
    expect(program!.rewardSymbol, 'TM101');
    expect(program.rewardQuantity, 1);
  });

  for (final mutation in [
    'item',
    'dex',
    'actor',
    'roles',
    'switch',
    'route',
    'quantity',
    'script'
  ]) {
    test('closed parcel rejects inconsistent captured $mutation', () async {
      final events = parcelFixtureEvents();
      renameParcelFixture(events);
      final list = events['1']['pages'][2]['list'] as List;
      switch (mutation) {
        case 'item':
          list[16]['parameters'] = [r'$bag.remove(:OTHERLETTER)'];
        case 'dex':
          list[7]['parameters'] = [r'$player.pokedex.unlock(03)'];
        case 'actor':
          list[9]['parameters'] = [6, 42, 2];
        case 'roles':
          list[80]['parameters'] = ['pbSetSelfSwitch(61,"A",true)'];
        case 'switch':
          list[8]['parameters'] = [161, 161, 0];
        case 'route':
          list[26]['parameters'][1]['list'][0]['code'] = 2;
        case 'quantity':
          list[230]['parameters'] = ['pbReceiveItem(:CAPSULE,9)'];
        case 'script':
          list[16]['parameters'] = ['arbitrary_source_call()'];
      }
      final fixture = await parcelFixture(mapId: 731, events: events);
      expect(_program(fixture.source), isNull);
    });
  }
}
