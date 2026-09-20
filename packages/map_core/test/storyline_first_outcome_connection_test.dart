import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'first declared outcome effect is created atomically and disconnects exactly',
    () {
      final project = _project();
      final result = connectStorylineProgressionEdge(project, _request());
      expect(
        result.disposition,
        StorylineProgressionMutationDisposition.applied,
      );
      final link = result.after.storylines.single.sceneLinks.single;
      expect(link.outcomeLinks.single.id, 'link_ready');
      expect(link.outcomeLinks.single.outcomeId, 'ready');
      expect(
        link.outcomeLinks.single.effects.single.type,
        StorylineEffectType.activateStep,
      );
      final edge = buildStorylineProgressionProjection(
        project: result.after,
        storylineId: 'trip',
      ).edgesOfKind(StorylineProgressionEdgeKind.outcomeActivatesStep).single;
      final disconnected = disconnectStorylineProgressionEdge(
        result.after,
        storylineId: 'trip',
        edgeId: edge.id,
      );
      expect(disconnected.after.toJson(), project.toJson());
      final duplicate = connectStorylineProgressionEdge(
        result.after,
        _request(),
      );
      expect(duplicate.code, 'duplicateOutcomeEffect');
      expect(duplicate.after, same(result.after));
    },
  );

  test(
    'first outcome rejects undeclared source, missing destination and self cycle',
    () {
      final project = _project();
      for (final request in [
        _request(outcomeId: 'invented'),
        _request(target: 'missing'),
        _request(target: 'start'),
      ]) {
        final result = connectStorylineProgressionEdge(project, request);
        expect(
          result.disposition,
          StorylineProgressionMutationDisposition.rejected,
        );
        expect(result.after, same(project));
      }
      final modernOnly = project.copyWith(
        scenarios: [],
        scenes: [
          SceneAsset.fromJson({
            ...createSceneDraftInProject(
              project,
              name: 'Moderne homonyme',
            ).createdScene.toJson(),
            'id': 'legacy',
          }),
        ],
      );
      final result = connectStorylineProgressionEdge(modernOnly, _request());
      expect(result.code, 'outcomeSourceNotFound');
      expect(result.after, same(modernOnly));
    },
  );

  test(
    'new result cannot bypass a cycle through an existing result effect',
    () {
      final project = _project();
      final story = project.storylines.single;
      final reverse = StorylineSceneLink(
        id: 'reverse',
        chapterId: 'chapter',
        stepId: 'end',
        label: 'Retour',
        state: StorylineSceneLinkState.linkedScenario,
        role: StorylineSceneLinkRole.branch,
        sceneRef: StorylineSceneRef(
          kind: StorylineSceneRefKind.scenario,
          targetId: 'legacy',
        ),
        order: 1,
        outcomeLinks: [
          StorylineSceneOutcomeLink(
            id: 'return',
            outcomeId: 'wait',
            effects: [
              StorylineEffect(
                type: StorylineEffectType.activateStep,
                targetId: 'start',
              ),
            ],
          ),
        ],
      );
      final withReverse = project.copyWith(
        storylines: [
          story.copyWith(sceneLinks: [...story.sceneLinks, reverse]),
        ],
      );
      final result = connectStorylineProgressionEdge(withReverse, _request());
      expect(result.code, 'cycleDetected');
      expect(result.after, same(withReverse));
    },
  );
}

StorylineProgressionConnectRequest _request({
  String outcomeId = 'ready',
  String target = 'end',
}) => StorylineProgressionConnectRequest.outcomeEffect(
  storylineId: 'trip',
  sceneLinkId: 'meeting',
  outcomeLinkId: 'link_ready',
  outcomeId: outcomeId,
  effectType: StorylineEffectType.activateStep,
  targetStepId: target,
);

ProjectManifest _project() => ProjectManifest(
  name: 'Premier résultat',
  maps: [],
  tilesets: [],
  scenarios: [
    const ScenarioAsset(
      id: 'legacy',
      name: 'Rencontre',
      entryNodeId: 'start',
      declaredOutcomes: ['ready', 'wait'],
    ),
  ],
  storylines: [
    StorylineAsset(
      id: 'trip',
      title: 'Départ',
      type: StorylineType.main,
      chapters: [
        StorylineChapter(
          id: 'chapter',
          title: 'En gare',
          order: 0,
          steps: [
            StorylineStep(id: 'start', title: 'Rencontre', order: 0),
            StorylineStep(id: 'end', title: 'Partir', order: 1),
          ],
        ),
      ],
      sceneLinks: [
        StorylineSceneLink(
          id: 'meeting',
          chapterId: 'chapter',
          stepId: 'start',
          label: 'Rencontre',
          state: StorylineSceneLinkState.linkedScenario,
          role: StorylineSceneLinkRole.primary,
          sceneRef: StorylineSceneRef(
            kind: StorylineSceneRefKind.scenario,
            targetId: 'legacy',
          ),
          order: 0,
        ),
      ],
    ),
  ],
);
