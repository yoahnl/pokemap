import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Path animation triggers', () {
    test('serializes and deserializes animationTriggers on PathLayer', () {
      final layer = MapLayer.fromJson({
        'runtimeType': 'path',
        'id': 'water_layer',
        'name': 'Water',
        'presetId': 'water_path',
        'cells': <bool>[],
        'animationTriggers': [
          {
            'id': 'enter_once',
            'enabled': true,
            'trigger': 'on_enter',
            'mode': 'play_once',
          },
          {
            'id': 'inside_loop',
            'enabled': true,
            'trigger': 'while_inside',
            'mode': 'loop_while_active',
          },
        ],
      }) as PathLayer;

      expect(layer.animationTriggers.length, 2);
      expect(
        layer.animationTriggers.first.trigger,
        PathAnimationTriggerType.onEnter,
      );
      expect(
        layer.animationTriggers.first.mode,
        PathAnimationPlaybackMode.playOnce,
      );
      expect(
        layer.animationTriggers.last.trigger,
        PathAnimationTriggerType.whileInside,
      );
      expect(
        layer.animationTriggers.last.mode,
        PathAnimationPlaybackMode.loopWhileActive,
      );
    });

    test('legacy PathLayer without animationTriggers remains valid', () {
      final layer = MapLayer.fromJson({
        'runtimeType': 'path',
        'id': 'road_layer',
        'name': 'Road',
        'presetId': 'road_path',
        'cells': <bool>[],
      }) as PathLayer;
      expect(layer.animationTriggers, isEmpty);
    });

    test('validator rejects invalid whileInside/mode combinations on PathLayer',
        () {
      const map = MapData(
        id: 'map1',
        name: 'Map',
        size: GridSize(width: 2, height: 1),
        tilesetId: '',
        layers: [
          MapLayer.path(
            id: 'water_layer',
            name: 'Water',
            presetId: 'water_path',
            cells: [true, false],
            animationTriggers: [
              PathAnimationTriggerRule(
                id: 'invalid_loop',
                trigger: PathAnimationTriggerType.onStep,
                mode: PathAnimationPlaybackMode.loopWhileActive,
              ),
            ],
          ),
        ],
      );

      expect(
        () => MapValidator.validate(map),
        throwsA(isA<ValidationException>()),
      );
    });

    test('scope defaults to wholeLayer', () {
      const rule = PathAnimationTriggerRule(
        id: 'step_rule',
        trigger: PathAnimationTriggerType.onStep,
        mode: PathAnimationPlaybackMode.restartOnTrigger,
      );
      expect(rule.scope, PathAnimationActivationScope.wholeLayer);
    });

    test('scope can be set to cellOnly', () {
      const rule = PathAnimationTriggerRule(
        id: 'step_rule',
        trigger: PathAnimationTriggerType.onStep,
        mode: PathAnimationPlaybackMode.restartOnTrigger,
        scope: PathAnimationActivationScope.cellOnly,
      );
      expect(rule.scope, PathAnimationActivationScope.cellOnly);
    });

    test('scope serializes and deserializes', () {
      final layer = MapLayer.fromJson({
        'runtimeType': 'path',
        'id': 'grass_layer',
        'name': 'Grass',
        'presetId': 'grass_path',
        'cells': <bool>[],
        'animationTriggers': [
          {
            'id': 'step_cell',
            'trigger': 'on_step',
            'mode': 'restart_on_trigger',
            'scope': 'cell_only',
          },
        ],
      }) as PathLayer;

      expect(layer.animationTriggers.first.scope,
          PathAnimationActivationScope.cellOnly);
    });
  });
}
