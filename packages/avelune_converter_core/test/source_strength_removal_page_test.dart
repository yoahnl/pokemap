import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/trainer_program_fixture.dart';

Future<NormalizedSourceProject> strengthSource({String? variant}) => trainerSource(
    mapId: 202, eventId: 12, eventName: 'StrengthBoulder', mutate: (pages) {
      pages.first.fields['@trigger'] = 1;
      (pages.first.fields['@graphic'] as TrainerRubyObject)
          .fields['@character_name'] = 'OBJ_FRLG_Strength Boulder';
      pages.first.fields['@list'] = [trainerCommand(355, ['pbPushThisBoulder']), trainerCommand(0, [])];
      (pages.last.fields['@graphic'] as TrainerRubyObject).fields['@character_name'] =
          variant == 'graphic' ? 'OBJ_FRLG_Strength Boulder' : '';
      pages.last.fields['@list'] = [
        if (variant == 'effect') trainerCommand(355, ['unknownEffect()']), trainerCommand(0, []),
      ];
      final condition = pages.last.fields['@condition'] as TrainerRubyObject;
      if (variant == 'delayed') {
        final active = pages.first.fields['@condition'] as TrainerRubyObject;
        active.fields['@self_switch_valid'] = true;
        active.fields['@self_switch_ch'] = 'B';
      }
      if (variant == 'condition') condition.fields['@switch1_valid'] = true;
      if (variant == 'letter') condition.fields['@self_switch_ch'] = 'B';
      if (variant == 'trigger') pages.last.fields['@trigger'] = 3;
      if (variant == 'through') pages.last.fields['@through'] = 'true';
      if (variant == 'invisibleThrough') pages.last.fields['@through'] = true;
      if (variant == 'movement') pages.last.fields['@move_type'] = 3;
      if (variant == 'extension') pages.last.extraFields.add(const MapEntry('@unknown', true));
      if (variant == 'single') pages.removeLast();
    });

SourceFieldObstacleProgramNode? program(NormalizedSourceProject source) =>
    analyzeTrainerSource(source).events.single.pages.first.body.nodes
        .whereType<SourceFieldObstacleProgramNode>().singleOrNull;

void main() {
  test('Strength preserves its full invisible self A page as persistent removal', () async {
    final source = await strengthSource();
    final node = program(source);
    expect(node, isNotNull);
    expect(node!.obstacleKind, SourceFieldObstacleKind.strengthBoulder);
    expect(node.toJson()['persistentRemoval'], isA<Map>());
    expect(node.isBoundToSourceEvent(source: source, profile: analyzeTrainerSource(source).profile,
        sourceMapId: 202, event: source.maps.single.map.events.single), isTrue);
    final event = analyzeTrainerSource(source).events.single;
    expect(event.pages, hasLength(2));
    expect(event.pages.last.body.nodes, isEmpty);
  });
  test('one-page Strength retains its existing native contract', () async {
    final node = program(await strengthSource(variant: 'single'));
    expect(node, isNotNull);
    expect(node!.toJson()['persistentRemoval'], isNull);
  });
  test('invisible through page preserves the same persistent removal contract', () async {
    final node = program(await strengthSource(variant: 'invisibleThrough'));
    expect(node, isNotNull);
    expect(node!.persistentRemoval, isNotNull);
  });
  test('delayed Strength keeps self B activation and self A removal precedence', () async {
    final source = await strengthSource(variant: 'delayed');
    final analysis = analyzeTrainerSource(source);
    final event = analysis.events.single;
    final node = program(source)!;
    expect(node.activationFactId, endsWith(':self:B'));
    expect(event.selectPage(), isNull);
    expect(event.selectPage(facts: {node.activationFactId!: true})!.originalPageIndex, 0);
    expect(event.selectPage(facts: {node.activationFactId!: true,
      node.persistentRemoval!.factId: true})!.originalPageIndex, 1);
    expect(node.isBoundToSourceEvent(source: source, profile: analysis.profile,
      sourceMapId: 202, event: source.maps.single.map.events.single), isTrue);
  });
  for (final variant in ['code', 'indent', 'trigger', 'conditionRef', 'rawRef', 'owner']) {
    test('rebind rejects forged normalized removal metadata $variant', () async {
      final source = await strengthSource();
      final node = program(source)!;
      final json = jsonDecode(jsonEncode(source.maps.single.toJson())) as Map<String, dynamic>;
      final owner = (json['map']['events'] as List).single as Map;
      final page = (owner['pages'] as List)[1] as Map;
      if (variant == 'code') ((page['commands'] as List).single as Map)['code'] = 355;
      if (variant == 'indent') ((page['commands'] as List).single as Map)['indent'] = 1;
      if (variant == 'trigger') page['triggerCode'] = 1;
      if (variant == 'conditionRef') page['conditionsDataRef'] = page['rawDataRef'];
      if (variant == 'rawRef') page['rawDataRef'] = (owner['pages'] as List).first['rawDataRef'];
      if (variant == 'owner') owner['name'] = 'Forged';
      final changed = SourceMapIr.fromJson(json).map.events.single;
      expect(node.isBoundToSourceEvent(source: source, profile: analyzeTrainerSource(source).profile,
          sourceMapId: 202, event: changed), isFalse);
    });
  }
  for (final variant in ['condition', 'letter', 'trigger', 'through', 'movement', 'effect', 'graphic', 'extension']) {
    test('refuses an unproved Strength removal page $variant', () async {
      expect(program(await strengthSource(variant: variant)), isNull);
    });
  }
}
