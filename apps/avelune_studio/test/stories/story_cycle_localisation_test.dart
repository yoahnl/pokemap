import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/story_backend_fixture.dart';

StorylineAsset _requiring(StorylineAsset story, String target) =>
    story.copyWith(
      relationships: [
        StorylineRelationship(
          id: '${story.id}_needs_$target',
          kind: StorylineRelationshipKind.requires,
          sourceStorylineId: story.id,
          targetStorylineId: target,
        ),
      ],
    );

void main() {
  test('a reference cycle names its stories and writes nothing', () async {
    final first = backendStory('first', title: 'Le départ');
    final second = backendStory('second', title: 'Le retour');
    final f = await StoryBackendFixture.create(stories: [first, second]);
    addTearDown(f.dispose);
    final controller = f.attach();
    final before = await File('${f.directory.path}/project.json').readAsBytes();

    controller.mutate(
      (project) => project.copyWith(
        storylines: [
          _requiring(first, second.id),
          _requiring(second, first.id),
        ],
      ),
    );
    expect(await controller.saveAll(), isFalse);

    expect(controller.error, contains('cycle de références'));
    expect(controller.error, contains('Le départ'));
    expect(controller.error, contains('Le retour'));
    expect(controller.error, contains(' → '));
    expect(controller.cycleStoryIds.toSet(), {first.id, second.id});
    expect(
      await File('${f.directory.path}/project.json').readAsBytes(),
      before,
    );

    expect(controller.open(second.id), isTrue);
    expect(controller.activeId, second.id);

    controller.mutate(
      (project) =>
          project.copyWith(storylines: [_requiring(first, second.id), second]),
    );
    expect(await controller.saveAll(), isTrue, reason: controller.error);
    expect(controller.cycleStoryIds, isEmpty);
  });
}
