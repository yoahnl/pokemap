import 'package:map_core/map_core.dart';

import 'playtest_contracts.dart';

const playtestTimingContract = <String, Object>{
  'multipliers': [1, 2, 5, 10],
  'defaultMultiplier': 1,
  'persisted': false,
  'operations': {
    'simulation.setSpeed': {'multiplier': 'one of 1, 2, 5, 10'},
    'simulation.advance': {
      'milliseconds': 'integer in [1, 60000], simulation time, headless only'
    },
  },
  'cliOption': '--test-speed',
  'mcpTool': 'pokemap_playtest',
  'mcpParameter': 'simulationSpeed',
  'resourceScope': 'live playtest session; no project resource mutation',
};

final class PlaytestTimingCommand {
  const PlaytestTimingCommand.setSpeed(PlaytestSpeed value)
      : speed = value,
        duration = null;

  PlaytestTimingCommand.advance(Duration value)
      : speed = null,
        duration = value {
    if (value.inMicroseconds % 1000 != 0 ||
        value < const Duration(milliseconds: 1) ||
        value > const Duration(minutes: 1)) {
      throw ArgumentError.value(
          value, 'duration', 'Use 1 to 60000 whole milliseconds.');
    }
  }

  factory PlaytestTimingCommand.fromCommand(PlaytestCommand command) {
    final args = command.arguments;
    switch (command.operation) {
      case 'simulation.setSpeed':
        final value = args['multiplier'];
        if (args.length != 1 || value is! int) {
          throw ArgumentError.value(args, 'arguments');
        }
        return PlaytestTimingCommand.setSpeed(
            PlaytestSpeed.fromMultiplier(value));
      case 'simulation.advance':
        final value = args['milliseconds'];
        if (args.length != 1 || value is! int) {
          throw ArgumentError.value(args, 'arguments');
        }
        return PlaytestTimingCommand.advance(Duration(milliseconds: value));
      default:
        throw ArgumentError.value(command.operation, 'operation');
    }
  }

  final PlaytestSpeed? speed;
  final Duration? duration;

  PlaytestCommand toCommand(String commandId) => PlaytestCommand(
        commandId: commandId,
        operation: speed != null ? 'simulation.setSpeed' : 'simulation.advance',
        arguments: speed != null
            ? {'multiplier': speed!.multiplier}
            : {'milliseconds': duration!.inMilliseconds},
      );
}
