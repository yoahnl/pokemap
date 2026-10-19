import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/trainer_program_fixture.dart';

Future<NormalizedSourceProject> _source(List<TrainerRubyObject> continuation) =>
    trainerSource(variableNames: List.generate(34, (id) => 'Variable $id'),
        mutate: (pages) {
      final commands = pages.first.fields['@list'] as List;
      commands.replaceRange(5, 6, continuation);
    });

SourceTrainerProgramNode? _program(NormalizedSourceProject source) {
  final nodes = analyzeTrainerSource(source).events.single.pages.first.body.nodes;
  return nodes.length == 1 && nodes.single is SourceTrainerProgramNode
      ? nodes.single as SourceTrainerProgramNode
      : null;
}

void main() {
  test('victory counter and own switch retain their source order and spans', () async {
    final source = await _source([
      trainerCommand(122, [33, 33, 1, 0, 1], indent: 1),
      trainerCommand(123, ['A', 0], indent: 1),
    ]);
    final program = _program(source)!;
    final nodes = program.victoryContinuation.nodes;
    expect(nodes, hasLength(2));
    final increment = nodes.first as SourceVariableAdjustNode;
    expect((increment.firstId, increment.lastId, increment.delta), (33, 33, 1));
    expect(increment.span.firstCommandIndex, 5);
    expect((nodes.last as SourceSelfSwitchNode).factId, program.defeatedFactId);
    expect(nodes.last.span.firstCommandIndex, 6);
    expect((program.toJson()['victoryContinuation'] as Map)['execution'],
        'battleVictoryOnly');
    expect(program.isBoundToSourceEvent(source: source,
        profile: analyzeTrainerSource(source).profile, sourceMapId: 417,
        event: source.maps.single.map.events.single), isTrue);
  });

  test('own switch before counter is preserved without reordering', () async {
    final program = _program(await _source([
      trainerCommand(123, ['A', 0], indent: 1),
      trainerCommand(122, [33, 33, 1, 0, 1], indent: 1),
    ]))!;
    expect(program.victoryContinuation.nodes.first, isA<SourceSelfSwitchNode>());
    expect(program.victoryContinuation.nodes.last, isA<SourceVariableAdjustNode>());
  });

  test('victory dialogue and source sound remain ordered and raw bound', () async {
    final source = await _source([
      trainerCommand(101, ['The key fell!'], indent: 1),
      trainerCommand(250, [TrainerRubyObject('RPG::AudioFile', {
        '@name': 'frlg_gateopen', '@volume': 80, '@pitch': 100,
      })], indent: 1),
      trainerCommand(123, ['A', 0], indent: 1),
    ]);
    final program = _program(source)!;
    expect(program.victoryContinuation.nodes.first, isA<SourceTextNode>());
    final sound = program.victoryContinuation.nodes[1] as SourceSoundEffectNode;
    expect((sound.name, sound.volume, sound.pitch), ('frlg_gateopen', 80, 100));
    expect(sound.span.firstCommandIndex, 6);
    expect(program.victoryContinuation.nodes.last, isA<SourceSelfSwitchNode>());
    expect(program.isBoundToSourceEvent(source: source,
        profile: analyzeTrainerSource(source).profile, sourceMapId: 417,
        event: source.maps.single.map.events.single), isTrue);
  });

  for (final variant in ['subtract', 'range', 'operand', 'duplicateCounter',
    'missingOwn', 'duplicateOwn', 'wrongOwn', 'indent', 'effect', 'else']) {
    test('refuses unqualified victory continuation $variant', () async {
      final own = trainerCommand(123, ['A', 0], indent: 1);
      final increment = trainerCommand(122, [33, 33, 1, 0, 1], indent: 1);
      final commands = switch (variant) {
        'subtract' => [trainerCommand(122, [33, 33, 2, 0, 1], indent: 1), own],
        'range' => [trainerCommand(122, [32, 33, 1, 0, 1], indent: 1), own],
        'operand' => [trainerCommand(122, [33, 33, 1, 0, 2], indent: 1), own],
        'duplicateCounter' => [increment, increment, own],
        'missingOwn' => [increment],
        'duplicateOwn' => [increment, own, own],
        'wrongOwn' => [increment, trainerCommand(123, ['B', 0], indent: 1)],
        'indent' => [trainerCommand(122, [33, 33, 1, 0, 1]), own],
        'effect' => [increment, own, trainerCommand(355, ['arbitrary()'], indent: 1)],
        'else' => [increment, own, trainerCommand(411, [])],
        _ => throw StateError(variant),
      };
      expect(_program(await _source(commands)), isNull);
    });
  }

  test('victory arithmetic is bound to the original normalized and raw commands', () async {
    final source = await _source([
      trainerCommand(122, [33, 33, 1, 0, 1], indent: 1),
      trainerCommand(123, ['A', 0], indent: 1),
    ]);
    final program = _program(source)!;
    final json = jsonDecode(jsonEncode(source.maps.single.toJson())) as Map<String, dynamic>;
    final event = (json['map']['events'] as List).single as Map;
    final command = ((event['pages'] as List).first['commands'] as List)[5] as Map;
    command['parameters'] = [33, 33, 1, 0, 2];
    final forged = SourceMapIr.fromJson(json);
    expect(program.isBoundToSourceEvent(source: source,
        profile: analyzeTrainerSource(source).profile, sourceMapId: 417,
        event: forged.map.events.single), isFalse);
  });
}
