import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Storyline lifecycle authoring operations', () {
    test('createStoryline supports every canonical storyline type', () {
      var project = _emptyProject();

      for (final type in StorylineType.values) {
        final result = createStoryline(
          project,
          storyline: StorylineAsset(
            id: 'story_${type.name}',
            type: type,
            title: type.name,
          ),
        );

        expect(result.disposition, StorylineMutationDisposition.applied);
        project = result.after;
      }

      expect(
        project.storylines.map((storyline) => storyline.type),
        StorylineType.values,
      );
    });

    test('updateStoryline applies status, notes and title atomically', () {
      final project = _project();
      final source = project.storylines.single;

      final result = updateStoryline(
        project,
        storylineId: source.id,
        storyline: source.copyWith(
          title: 'Renamed story',
          status: StorylineStatus.active,
          authorNotes: 'Ready for review',
        ),
      );

      expect(result.disposition, StorylineMutationDisposition.applied);
      expect(result.storyline!.title, 'Renamed story');
      expect(result.storyline!.status, StorylineStatus.active);
      expect(result.storyline!.authorNotes, 'Ready for review');
      expect(project.storylines.single.title, 'Main story');
    });

    test('duplicateStoryline creates an independent draft without legacy claim',
        () {
      final source = _project().storylines.single.copyWith(
        status: StorylineStatus.active,
        legacySource: StorylineLegacySource(
          kind: 'scenario.globalStory',
          sourceId: 'legacy_story',
        ),
        metadata: const {'legacyImportPreview': 'true', 'theme': 'fog'},
      );
      final project = _emptyProject().copyWith(storylines: [source]);

      final result = duplicateStoryline(
        project,
        storylineId: source.id,
        duplicateId: 'story_main_copy',
        title: 'Main story copy',
      );

      expect(result.disposition, StorylineMutationDisposition.applied);
      expect(result.after.storylines, hasLength(2));
      final duplicate = result.storyline!;
      expect(duplicate.id, 'story_main_copy');
      expect(duplicate.title, 'Main story copy');
      expect(duplicate.status, StorylineStatus.draft);
      expect(duplicate.legacySource, isNull);
      expect(duplicate.metadata['legacyImportPreview'], isNull);
      expect(duplicate.metadata['duplicatedFrom'], source.id);
      expect(duplicate.chapters, isNot(same(source.chapters)));
      expect(duplicate.chapters.single.id, isNot(source.chapters.single.id));
    });

    test('archiveStoryline is applied once then becomes an explicit no-op', () {
      final project = _project();

      final archived = archiveStoryline(
        project,
        storylineId: 'story_main',
      );
      final repeated = archiveStoryline(
        archived.after,
        storylineId: 'story_main',
      );

      expect(archived.disposition, StorylineMutationDisposition.applied);
      expect(archived.storyline!.status, StorylineStatus.archived);
      expect(repeated.disposition, StorylineMutationDisposition.noChange);
      expect(repeated.after, same(archived.after));
    });

    test('deleteStoryline rejects external consumers and rolls back', () {
      final main = _project().storylines.single;
      final side = StorylineAsset(
        id: 'story_side',
        type: StorylineType.sideQuest,
        title: 'Side story',
        relationships: [
          StorylineRelationship(
            id: 'side_requires_main',
            kind: StorylineRelationshipKind.requires,
            sourceStorylineId: 'story_side',
            targetStorylineId: 'story_main',
          ),
        ],
      );
      final project = _emptyProject().copyWith(storylines: [main, side]);

      final result = deleteStoryline(
        project,
        storylineId: 'story_main',
      );

      expect(result.disposition, StorylineMutationDisposition.rejected);
      expect(result.code, 'storylineReferenced');
      expect(result.referencePaths, contains(contains('relationships')));
      expect(result.before, same(project));
      expect(result.after, same(project));
    });

    test('deleteStoryline removes an unreferenced storyline', () {
      final project = _project();

      final result = deleteStoryline(
        project,
        storylineId: 'story_main',
      );

      expect(result.disposition, StorylineMutationDisposition.applied);
      expect(result.after.storylines, isEmpty);
      expect(project.storylines, hasLength(1));
    });
  });

  group('Storyline scene link authoring operations', () {
    test('linkSceneToStorylineStep adds an existing scene id', () {
      final project = _project();

      final result = linkSceneToStorylineStep(
        project,
        storylineId: 'story_main',
        chapterId: 'chapter_intro',
        stepId: 'step_intro',
        sceneId: 'scene_intro',
      );

      expect(result.updatedStep.sceneLinkIds, ['scene_intro']);
      expect(
        result.updatedProject.storylines.single.chapters.single.steps.single
            .sceneLinkIds,
        ['scene_intro'],
      );
      expect(
          project.storylines.single.chapters.single.steps.single.sceneLinkIds,
          isEmpty);
      expect(result.updatedProject.scenes, equals(project.scenes));
      expect(result.updatedProject, isNot(same(project)));
    });

    test('linkSceneToStorylineStep refuses unknown step', () {
      expect(
        () => linkSceneToStorylineStep(
          _project(),
          storylineId: 'story_main',
          chapterId: 'chapter_intro',
          stepId: 'missing_step',
          sceneId: 'scene_intro',
        ),
        throwsArgumentError,
      );
    });

    test('linkSceneToStorylineStep refuses empty scene id', () {
      expect(
        () => linkSceneToStorylineStep(
          _project(),
          storylineId: 'story_main',
          chapterId: 'chapter_intro',
          stepId: 'step_intro',
          sceneId: ' ',
        ),
        throwsArgumentError,
      );
    });

    test('linkSceneToStorylineStep refuses unknown scene id', () {
      expect(
        () => linkSceneToStorylineStep(
          _project(),
          storylineId: 'story_main',
          chapterId: 'chapter_intro',
          stepId: 'step_intro',
          sceneId: 'missing_scene',
        ),
        throwsArgumentError,
      );
    });

    test('linkSceneToStorylineStep refuses duplicate scene id', () {
      final linked = linkSceneToStorylineStep(
        _project(),
        storylineId: 'story_main',
        chapterId: 'chapter_intro',
        stepId: 'step_intro',
        sceneId: 'scene_intro',
      ).updatedProject;

      expect(
        () => linkSceneToStorylineStep(
          linked,
          storylineId: 'story_main',
          chapterId: 'chapter_intro',
          stepId: 'step_intro',
          sceneId: 'scene_intro',
        ),
        throwsArgumentError,
      );
    });

    test('unlinkSceneFromStorylineStep removes only selected scene id', () {
      final project =
          _projectWithStepLinks(['scene_intro', 'scene_resolution']);

      final result = unlinkSceneFromStorylineStep(
        project,
        storylineId: 'story_main',
        chapterId: 'chapter_intro',
        stepId: 'step_intro',
        sceneId: 'scene_intro',
      );

      expect(result.updatedStep.sceneLinkIds, ['scene_resolution']);
      expect(
          project.storylines.single.chapters.single.steps.single.sceneLinkIds,
          ['scene_intro', 'scene_resolution']);
    });

    test('replaceStorylineStepSceneLinks preserves order without duplicates',
        () {
      final result = replaceStorylineStepSceneLinks(
        _project(),
        storylineId: 'story_main',
        chapterId: 'chapter_intro',
        stepId: 'step_intro',
        sceneIds: const ['scene_resolution', 'scene_intro', 'scene_resolution'],
      );

      expect(
          result.updatedStep.sceneLinkIds, ['scene_resolution', 'scene_intro']);
    });
  });

  group('Storyline Chapter and Step authoring operations', () {
    test('updates and reorders Chapters atomically', () {
      final project = _structureProject();
      final source = project.storylines.single.chapters.first;

      final updated = updateStorylineChapter(
        project,
        storylineId: 'story_main',
        chapterId: source.id,
        chapter: source.copyWith(
          title: 'Port revised',
          status: StorylineStatus.active,
          authorNotes: 'Chapter review',
        ),
      );
      final reordered = reorderStorylineChapters(
        updated.after,
        storylineId: 'story_main',
        orderedChapterIds: const ['chapter_marsh', 'chapter_intro'],
      );

      expect(updated.disposition, StorylineMutationDisposition.applied);
      expect(updated.chapter!.title, 'Port revised');
      expect(updated.chapter!.status, StorylineStatus.active);
      expect(project.storylines.single.chapters.first.title, 'Intro');
      expect(
        reordered.storyline!.chapters.map((chapter) => chapter.id),
        ['chapter_marsh', 'chapter_intro'],
      );
      expect(reordered.storyline!.chapters.map((chapter) => chapter.order),
          [0, 1]);
    });

    test('duplicates a Chapter with independent Step and SceneLink ids', () {
      final project = _structureProject(withStructuredLink: true);

      final result = duplicateStorylineChapter(
        project,
        storylineId: 'story_main',
        chapterId: 'chapter_intro',
        duplicateChapterId: 'chapter_intro_copy',
        title: 'Intro copy',
      );

      expect(result.disposition, StorylineMutationDisposition.applied);
      expect(result.storyline!.chapters, hasLength(3));
      final duplicate = result.chapter!;
      expect(duplicate.id, 'chapter_intro_copy');
      expect(duplicate.steps.single.id, 'chapter_intro_copy__step_intro');
      expect(result.storyline!.sceneLinks, hasLength(2));
      expect(result.storyline!.sceneLinks.last.chapterId, duplicate.id);
      expect(
          result.storyline!.sceneLinks.last.stepId, duplicate.steps.single.id);
      expect(
        result.storyline!.sceneLinks.last.outcomeLinks.single.effects.single
            .targetId,
        duplicate.steps.single.id,
      );
    });

    test('refuses deleting a Chapter while it still owns Steps', () {
      final project = _structureProject();

      final result = deleteStorylineChapter(
        project,
        storylineId: 'story_main',
        chapterId: 'chapter_intro',
      );

      expect(result.disposition, StorylineMutationDisposition.rejected);
      expect(result.code, 'chapterContainsSteps');
      expect(result.referencePaths, contains(contains('step_intro')));
      expect(result.after, same(project));
    });

    test('deletes an empty unreferenced Chapter and normalizes order', () {
      final project = _structureProject();

      final result = deleteStorylineChapter(
        project,
        storylineId: 'story_main',
        chapterId: 'chapter_marsh',
      );

      expect(result.disposition, StorylineMutationDisposition.applied);
      expect(result.storyline!.chapters.single.id, 'chapter_intro');
      expect(result.storyline!.chapters.single.order, 0);
    });

    test('updates a Step with conditions outcomes status notes and Scenes', () {
      final project = _structureProject();
      final source = project.storylines.single.chapters.first.steps.single;
      final entry = ScriptConditionFactory.flagIsSet('fact_port_open');
      final completion =
          ScriptConditionFactory.flagIsSet('fact_intro_complete');

      final result = updateStorylineStep(
        project,
        storylineId: 'story_main',
        chapterId: 'chapter_intro',
        stepId: 'step_intro',
        step: source.copyWith(
          title: 'Meet the rival',
          entryCondition: entry,
          completionCondition: completion,
          sceneLinkIds: const ['scene_intro'],
          expectedOutcomeIds: const ['victory'],
          status: StorylineStatus.active,
          authorNotes: 'Blocked until the port opens',
        ),
      );

      expect(result.disposition, StorylineMutationDisposition.applied);
      expect(result.step!.entryCondition, entry);
      expect(result.step!.completionCondition, completion);
      expect(result.step!.sceneLinkIds, ['scene_intro']);
      expect(result.step!.expectedOutcomeIds, ['victory']);
      expect(result.step!.status, StorylineStatus.active);
      expect(result.step!.authorNotes, contains('Blocked'));
    });

    test('duplicates then reorders and moves a Step between Chapters', () {
      final project = _structureProject();
      final duplicate = duplicateStorylineStep(
        project,
        storylineId: 'story_main',
        chapterId: 'chapter_intro',
        stepId: 'step_intro',
        duplicateStepId: 'step_intro_copy',
      );
      final reordered = reorderStorylineSteps(
        duplicate.after,
        storylineId: 'story_main',
        chapterId: 'chapter_intro',
        orderedStepIds: const ['step_intro_copy', 'step_intro'],
      );
      final moved = moveStorylineStep(
        reordered.after,
        storylineId: 'story_main',
        sourceChapterId: 'chapter_intro',
        targetChapterId: 'chapter_marsh',
        stepId: 'step_intro_copy',
        targetIndex: 0,
      );

      expect(duplicate.step!.id, 'step_intro_copy');
      expect(duplicate.step!.title, 'Intro (copy)');
      final chapters = moved.storyline!.chapters;
      expect(chapters.first.steps.single.id, 'step_intro');
      expect(chapters.last.steps.single.id, 'step_intro_copy');
      expect(chapters.last.steps.single.order, 0);
    });

    test('refuses deleting a Step referenced by a structured SceneLink', () {
      final project = _structureProject(withStructuredLink: true);

      final result = deleteStorylineStep(
        project,
        storylineId: 'story_main',
        chapterId: 'chapter_intro',
        stepId: 'step_intro',
      );

      expect(result.disposition, StorylineMutationDisposition.rejected);
      expect(result.code, 'stepReferenced');
      expect(result.referencePaths, contains(contains('sceneLinks')));
      expect(result.after, same(project));
    });

    test('structure operations preserve JSON compatibility', () {
      final moved = moveStorylineStep(
        duplicateStorylineStep(
          _structureProject(),
          storylineId: 'story_main',
          chapterId: 'chapter_intro',
          stepId: 'step_intro',
          duplicateStepId: 'step_copy',
        ).after,
        storylineId: 'story_main',
        sourceChapterId: 'chapter_intro',
        targetChapterId: 'chapter_marsh',
        stepId: 'step_copy',
        targetIndex: 0,
      );

      final decoded = ProjectManifest.fromJson(moved.after.toJson());

      expect(decoded, moved.after);
    });
  });
}

ProjectManifest _emptyProject() {
  return ProjectManifest(
    name: 'Story Project',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
  );
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Story Project',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    scenes: [_scene('scene_intro'), _scene('scene_resolution')],
    storylines: [
      StorylineAsset(
        id: 'story_main',
        type: StorylineType.main,
        title: 'Main story',
        chapters: [
          StorylineChapter(
            id: 'chapter_intro',
            title: 'Intro',
            order: 0,
            steps: [
              StorylineStep(id: 'step_intro', title: 'Intro', order: 0),
            ],
          ),
        ],
      ),
    ],
  );
}

ProjectManifest _projectWithStepLinks(List<String> sceneLinkIds) {
  final project = _project();
  return replaceStorylineStepSceneLinks(
    project,
    storylineId: 'story_main',
    chapterId: 'chapter_intro',
    stepId: 'step_intro',
    sceneIds: sceneLinkIds,
  ).updatedProject;
}

SceneAsset _scene(String id) {
  return SceneAsset(
    id: id,
    name: id == 'scene_intro' ? 'Intro Scene' : 'Resolution Scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_end',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}

ProjectManifest _structureProject({bool withStructuredLink = false}) {
  final base = _project();
  final storyline = base.storylines.single;
  return base.copyWith(
    storylines: [
      storyline.copyWith(
        chapters: [
          storyline.chapters.single,
          StorylineChapter(
            id: 'chapter_marsh',
            title: 'Marsh',
            order: 1,
          ),
        ],
        sceneLinks: withStructuredLink
            ? [
                StorylineSceneLink(
                  id: 'link_intro',
                  chapterId: 'chapter_intro',
                  stepId: 'step_intro',
                  label: 'Intro scene',
                  state: StorylineSceneLinkState.needsImplementation,
                  role: StorylineSceneLinkRole.primary,
                  order: 0,
                  outcomeLinks: [
                    StorylineSceneOutcomeLink(
                      id: 'outcome_intro_complete',
                      outcomeId: 'completed',
                      effects: [
                        StorylineEffect(
                          type: StorylineEffectType.completeStep,
                          targetId: 'step_intro',
                        ),
                      ],
                    ),
                  ],
                ),
              ]
            : const [],
      ),
    ],
  );
}
