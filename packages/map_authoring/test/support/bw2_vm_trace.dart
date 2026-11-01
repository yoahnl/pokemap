import 'dart:typed_data';

import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_battle_script_control_flow.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_battle_script_source.dart';

final class Bw2VmTraceEvent {
  Bw2VmTraceEvent({
    required this.call,
    required this.instruction,
    required List<String> arguments,
  }) : arguments = List.unmodifiable(arguments);

  final int call;
  final String instruction;
  final List<String> arguments;
}

List<Bw2VmTraceEvent> traceBw2VmSegment(
  Uint8List bytes, {
  required String sourceRevision,
  required String sourcePath,
  required String expectedSha256,
}) {
  final source = Gen5BattleScriptSource.read(
    bytes,
    sourceRevision: sourceRevision,
    sourcePath: sourcePath,
    expectedSha256: expectedSha256,
  );
  Gen5BattleScriptControlFlow.analyze(source);
  final instructions = source.instructions;
  final load = instructions.indexWhere((item) => item.name == 'ParticleLoad');
  final end = instructions.indexWhere(
    (item) => item.name == 'McssPalFade',
    load + 1,
  );
  if (load < 0 ||
      end <= load + 1 ||
      instructions[load + 1].name != 'SetYield' ||
      instructions[load + 1].arguments.single != 'FALSE') {
    throw const FormatException('Unsupported BW2 trace segment');
  }
  const ordinary = {
    'PlaySE',
    'MoveSE',
    'PanSE',
    'EmitterMove',
    'EmitterAdd',
    'CameraMovePreset',
  };
  final events = <Bw2VmTraceEvent>[];
  var call = 0;
  var yieldAfterCommand = true;
  for (final item in instructions.sublist(load + 1, end)) {
    events.add(Bw2VmTraceEvent(
      call: call,
      instruction: item.name,
      arguments: item.arguments,
    ));
    if (item.name == 'SetYield') {
      yieldAfterCommand = switch (item.arguments.single) {
        'TRUE' => true,
        'FALSE' => false,
        _ => throw const FormatException('Invalid yield state'),
      };
      if (yieldAfterCommand) call++;
    } else if (item.name == 'WaitFrames') {
      final frames = int.parse(item.arguments.single);
      call += (frames > 0 ? frames : 1) + 1;
      yieldAfterCommand = true;
    } else if (ordinary.contains(item.name)) {
      if (yieldAfterCommand) call++;
    } else {
      throw FormatException('Unsupported trace instruction: ${item.name}');
    }
  }
  return List.unmodifiable(events);
}
