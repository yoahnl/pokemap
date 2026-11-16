import 'dart:convert';

import 'package:map_core/map_core_domain.dart';

final class SceneCatalogMembership {
  const SceneCatalogMembership({
    required this.story,
    required this.chapter,
    this.step,
    this.link,
    this.sceneId,
    this.referenceId,
    this.broken = false,
  });

  final StorylineAsset story;
  final StorylineChapter chapter;
  final StorylineStep? step;
  final StorylineSceneLink? link;
  final String? sceneId;
  final String? referenceId;
  final bool broken;

  String get key => jsonEncode([
    story.id,
    chapter.id,
    step?.id,
    link?.id,
    referenceId,
    sceneId,
  ]);
}

final class SceneCatalogMemberships {
  SceneCatalogMemberships(List<StorylineAsset> stories) {
    final keys = <String>{};
    void add(SceneCatalogMembership membership) {
      if (!keys.add(membership.key)) return;
      final id = membership.sceneId;
      if (id == null) {
        unresolved.add(membership);
      } else {
        byScene.putIfAbsent(id, () => []).add(membership);
      }
    }

    for (final story in stories) {
      final links = {for (final link in story.sceneLinks) link.id: link};
      for (final chapter in story.chapters) {
        void structured(StorylineSceneLink link, {bool direct = false}) {
          add(
            SceneCatalogMembership(
              story: story,
              chapter: chapter,
              step: direct
                  ? null
                  : chapter.steps
                        .where((step) => step.id == link.stepId)
                        .firstOrNull,
              link: link,
              sceneId: link.sceneRef?.targetId,
              broken:
                  link.state != StorylineSceneLinkState.linkedScenario ||
                  link.chapterId != chapter.id,
            ),
          );
        }

        for (final step in chapter.steps) {
          for (final sceneId in step.sceneLinkIds) {
            add(
              SceneCatalogMembership(
                story: story,
                chapter: chapter,
                step: step,
                sceneId: sceneId,
              ),
            );
          }
        }
        for (final link in story.sceneLinks) {
          if (link.chapterId == chapter.id) structured(link);
        }
        for (final linkId in chapter.directSceneLinkIds) {
          final link = links[linkId];
          if (link == null) {
            add(
              SceneCatalogMembership(
                story: story,
                chapter: chapter,
                broken: true,
                referenceId: linkId,
              ),
            );
          } else {
            structured(link, direct: true);
          }
        }
      }
    }
  }

  final byScene = <String, List<SceneCatalogMembership>>{};
  final unresolved = <SceneCatalogMembership>[];
}
