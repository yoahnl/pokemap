import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('speed command round-trips the four supported presets', () {
    for (final speed in PlaytestSpeed.values) {
      final command = PlaytestTimingCommand.setSpeed(speed).toCommand('speed');
      final decoded = PlaytestTimingCommand.fromCommand(
          PlaytestCommand.fromJson(
              Map<String, dynamic>.from(command.toJson())));
      expect(decoded.speed, speed);
    }
  });

  test('time advancement is explicit and bounded in simulation time', () {
    final command = PlaytestTimingCommand.advance(const Duration(seconds: 5));
    expect(
        PlaytestTimingCommand.fromCommand(command.toCommand('advance'))
            .duration,
        const Duration(seconds: 5));
    expect(() => PlaytestTimingCommand.advance(Duration.zero),
        throwsArgumentError);
    expect(() => PlaytestTimingCommand.advance(const Duration(minutes: 2)),
        throwsArgumentError);
    for (final arguments in <Map<String, Object?>>[
      {'multiplier': 100},
      {'multiplier': 2, 'automaticChoice': true},
      {'multiplier': '2'}
    ]) {
      expect(
          () => PlaytestTimingCommand.fromCommand(PlaytestCommand(
              commandId: 'bad',
              operation: 'simulation.setSpeed',
              arguments: arguments)),
          throwsArgumentError);
    }
  });

  test('discovery describes session controls without project persistence', () {
    expect(playtestTimingContract['multipliers'], [1, 2, 5, 10]);
    expect(playtestTimingContract['persisted'], isFalse);
    expect(
        playtestTimingContract['operations'], contains('simulation.setSpeed'));
    expect(
        playtestTimingContract['operations'], contains('simulation.advance'));
  });
}
