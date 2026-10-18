import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, Object?> transition(String id, {String sheet = 'project:assets/entry.png'}) => {
  'id': id,
  'label': 'Transition $id',
  'usages': ['wild', 'trainer'],
  'phases': [
    {'kind': 'flash', 'durationSeconds': 0.4, 'factor': 2},
    {'kind': 'sheetCells', 'durationSeconds': 0.6, 'sheetName': sheet, 'columns': 2, 'rows': 3},
    {'kind': 'holdBlack', 'durationSeconds': 0.1},
  ],
};

void main() {
  test('arbitrary project transitions round-trip independently of a game registry', () {
    final first = BattleTransitionDefinition.fromJson(transition('aurora'));
    final second = BattleTransitionDefinition.fromJson(transition('clockwork'));
    expect(first.id, 'aurora');
    expect(second.id, 'clockwork');
    expect(first.totalSeconds, closeTo(1.1, 0.0001));
    expect(first.toJson(), transition('aurora'));
    expect(BattleTransitionDefinition.fromJson(first.toJson()), first);
    expect(first.phases[1].parameters['sheetName'], 'project:assets/entry.png');
    expect(() => first.phases.clear(), throwsUnsupportedError);
    expect(() => first.phases[1].parameters.clear(), throwsUnsupportedError);
  });

  test('phase contracts reject unknown effects, malformed parameters and unsafe references', () {
    final invalid = [
      {'kind': 'gameOnlyTransition', 'durationSeconds': 1},
      {'kind': 'flash', 'durationSeconds': 0.4, 'factor': 'two'},
      {'kind': 'holdBlack', 'durationSeconds': -1},
      {'kind': 'holdBlack', 'durationSeconds': double.nan},
      {'kind': 'holdBlack', 'durationSeconds': 1, 'unexpected': true},
      {'kind': 'sheetCells', 'durationSeconds': 1, 'sheetName': 'project:../outside.png', 'columns': 2, 'rows': 3},
      {'kind': 'sheetCells', 'durationSeconds': 1, 'sheetName': 'https://example.com/image.png', 'columns': 2, 'rows': 3},
      {'kind': 'sheetCells', 'durationSeconds': 1, 'sheetName': 'project:assets/image.png', 'columns': 0, 'rows': 3},
      {'kind': 'terrainSweep', 'durationSeconds': 1, 'terrain': 'unknown'},
    ];
    for (final phase in invalid) {
      expect(() => BattleTransitionPhaseDefinition.fromJson(phase), throwsFormatException, reason: '$phase');
    }
  });

  test('definitions reject duplicate audiences, excessive duration and missing sprite sources', () {
    for (final value in [
      {...transition('x'), 'usages': ['wild', 'wild']},
      {...transition('x'), 'id': ''},
      {...transition('x'), 'phases': []},
      {...transition('x'), 'phases': [
        {'kind': 'spriteZoom', 'durationSeconds': 1, 'zoomFrom': 0.2},
      ]},
    ]) {
      expect(() => BattleTransitionDefinition.fromJson(value), throwsFormatException);
    }
  });

  test('all generic effects expose strict round-trip parameters', () {
    final phases = [
      {'kind': 'spriteZoom', 'durationSeconds': 0.4, 'zoomFrom': 0.2},
      {'kind': 'spriteAngle', 'durationSeconds': 0.4, 'angleFromDegrees': 90, 'angleToDegrees': -360},
      {'kind': 'terrainSweep', 'durationSeconds': 0.65, 'terrain': 'grass'},
      {'kind': 'interleavedBands', 'durationSeconds': 0.7, 'bandHeight': 3},
      {'kind': 'thresholdDissolve', 'durationSeconds': 1, 'textureName': 'embedded:threshold.png', 'tFrom': 0, 'tTo': 1, 'fineThreshold': false},
      {'kind': 'fadeToBlack', 'durationSeconds': 0.45},
    ];
    for (final phase in phases) {
      expect(BattleTransitionPhaseDefinition.fromJson(phase).toJson(), phase);
    }
  });

  test('project configurations persist definitions as JSON and reject dangling or duplicate defaults', () {
    final definition = BattleTransitionDefinition.fromJson(transition('aurora'));
    final config = ProjectBattleTransitionConfig(
      wildTransitionId: 'aurora', definitions: [definition]);
    expect(ProjectBattleTransitionConfig.fromJson(config.toJson()), config);
    expect((config.toJson()['definitions'] as List).single, isA<Map>());
    for (final invalid in [
      {...config.toJson(), 'wildTransitionId': 'absent'},
      {...config.toJson(), 'definitions': [definition.toJson(), definition.toJson()]},
    ]) {
      expect(() => ProjectBattleTransitionConfig.fromJson(invalid), throwsFormatException);
    }
  });
}
