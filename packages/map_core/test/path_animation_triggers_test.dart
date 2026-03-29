import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Path animation triggers', () {
    test('serializes and deserializes animationTriggers on path preset', () {
      final preset = ProjectPathPreset.fromJson({
        'id': 'water_path',
        'name': 'Water',
        'tilesetId': 'outdoor',
        'surfaceKind': 'water',
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
      });

      expect(preset.animationTriggers.length, 2);
      expect(
        preset.animationTriggers.first.trigger,
        PathAnimationTriggerType.onEnter,
      );
      expect(
        preset.animationTriggers.first.mode,
        PathAnimationPlaybackMode.playOnce,
      );
      expect(
        preset.animationTriggers.last.trigger,
        PathAnimationTriggerType.whileInside,
      );
      expect(
        preset.animationTriggers.last.mode,
        PathAnimationPlaybackMode.loopWhileActive,
      );
    });

    test('legacy path preset without animationTriggers remains valid', () {
      final preset = ProjectPathPreset.fromJson({
        'id': 'road_path',
        'name': 'Road',
        'tilesetId': 'outdoor',
      });
      expect(preset.animationTriggers, isEmpty);
    });

    test('validator rejects invalid whileInside/mode combinations', () {
      const manifest = ProjectManifest(
        name: 'project',
        maps: [],
        tilesets: [
          ProjectTilesetEntry(
            id: 'outdoor',
            name: 'Outdoor',
            relativePath: 'tilesets/outdoor.png',
          ),
        ],
        pathPresets: [
          ProjectPathPreset(
            id: 'water_path',
            name: 'Water',
            tilesetId: 'outdoor',
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
        () => ProjectValidator.validate(manifest),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
