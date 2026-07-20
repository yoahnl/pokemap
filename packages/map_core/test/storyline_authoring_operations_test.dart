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
