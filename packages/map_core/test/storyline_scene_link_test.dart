import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('StorylineStep sceneLinkIds', () {
    test('decodes missing sceneLinkIds as an empty list', () {
      final step = StorylineStep.fromJson({
        'id': 'step_intro',
        'title': 'Intro',
        'order': 0,
      });

      expect(step.sceneLinkIds, isEmpty);
    });

    test('round-trips sceneLinkIds without changing order', () {
      final step = StorylineStep(
        id: 'step_intro',
        title: 'Intro',
        order: 0,
        sceneLinkIds: const ['scene_intro', 'scene_resolution'],
      );

      final decoded = StorylineStep.fromJson(step.toJson());

      expect(decoded.sceneLinkIds, ['scene_intro', 'scene_resolution']);
      expect(decoded, step);
    });
  });
}
