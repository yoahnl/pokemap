import 'dart:io';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/stories/data/local_story_adapter.dart';
import 'package:map_core/map_core.dart';
import 'ui06_scene_fixture.dart';

class Ui07StoryFixture {
  Ui07StoryFixture._(this.source, this.manifest);
  final Ui06SceneFixture source;
  final ProjectManifest manifest;
  Directory get directory => source.directory;
  ProjectSession get session => source.session;
  LocalMapWorkspaceAdapter get maps => source.maps;
  LocalStoryAdapter get port =>
      LocalStoryAdapter(session: session, mapAdapter: maps);
  static const mainId = 'prepare_departure';
  static const sideId = 'forgotten_bag';
  static const factId = 'fact_billet_obtenu';
  static const scenarioId = 'station_readiness';
  static const arrivalId = 'arrival';
  static const journeyId = 'prepare_journey';
  static const talkId = 'talk_station_chief';
  static const boardId = 'board_train';
  static const waitId = 'wait_departure';
  static const sceneLinkId = 'station_readiness_link';
  static const readyLinkId = 'station_ready_result';
  static const waitLinkId = 'station_wait_result';
  static const relationshipId = 'bag_requires_departure';

  static Future<Ui07StoryFixture> create({bool withStories = true}) async {
    final source = await Ui06SceneFixture.create(scenarios: [scenario()]);
    final port = LocalStoryAdapter(
      session: source.session,
      mapAdapter: source.maps,
    );
    var receipt = await port.publishFact(
      base: null,
      current: addNarrativeFact(
        source.manifest,
        label: 'Billet obtenu',
      ).createdFact,
    );
    if (withStories) {
      for (final story in [mainStory(), sideStory()]) {
        receipt = await port.publishStory(
          id: story.id,
          base: null,
          current: story,
        );
      }
    }
    return Ui07StoryFixture._(source, receipt.manifest);
  }

  Future<ProjectManifest> readFresh() =>
      LocalMapWorkspaceAdapter().loadProject(session);
  Future<void> dispose() => source.dispose();

  static StorylineAsset mainStory() => StorylineAsset(
    id: mainId,
    title: 'Préparer le départ',
    description: 'Trouver la gare, obtenir son billet et préparer le voyage.',
    type: StorylineType.main,
    status: StorylineStatus.active,
    chapters: [
      StorylineChapter(
        id: arrivalId,
        title: 'Arrivée à Hanazuki',
        order: 0,
        steps: [
          StorylineStep(id: 'find_station', title: 'Trouver la gare', order: 0),
          StorylineStep(
            id: talkId,
            title: 'Parler au chef de gare',
            order: 1,
            sceneLinkIds: const [Ui06SceneFixture.sceneId],
          ),
          StorylineStep(
            id: 'obtain_ticket',
            title: 'Obtenir le billet',
            order: 2,
          ),
        ],
      ),
      StorylineChapter(
        id: journeyId,
        title: 'Préparer le voyage',
        order: 1,
        steps: [
          StorylineStep(
            id: boardId,
            title: 'Monter dans le train',
            order: 0,
            entryCondition: ScriptConditionFactory.flagIsSet(factId),
          ),
          StorylineStep(
            id: waitId,
            title: 'Attendre le prochain départ',
            order: 1,
          ),
        ],
      ),
    ],
    sceneLinks: [
      StorylineSceneLink(
        id: sceneLinkId,
        order: 0,
        chapterId: arrivalId,
        stepId: talkId,
        label: 'Le chef de gare vérifie le départ',
        state: StorylineSceneLinkState.linkedScenario,
        role: StorylineSceneLinkRole.primary,
        sceneRef: StorylineSceneRef(
          kind: StorylineSceneRefKind.scenario,
          targetId: scenarioId,
        ),
        outcomeLinks: [
          StorylineSceneOutcomeLink(
            id: readyLinkId,
            outcomeId: 'ready',
            effects: [
              StorylineEffect(
                type: StorylineEffectType.activateStep,
                targetId: boardId,
              ),
            ],
          ),
          StorylineSceneOutcomeLink(
            id: waitLinkId,
            outcomeId: 'wait',
            effects: [
              StorylineEffect(
                type: StorylineEffectType.activateStep,
                targetId: waitId,
              ),
            ],
          ),
        ],
      ),
    ],
  );

  static StorylineAsset sideStory() => StorylineAsset(
    id: sideId,
    title: 'Le sac oublié',
    type: StorylineType.sideQuest,
    description: 'Retrouver le voyageur avant le prochain départ.',
    chapters: [
      StorylineChapter(
        id: 'bag_return',
        order: 0,
        title: 'Un voyageur distrait',
        steps: [
          StorylineStep(
            id: 'find_owner',
            title: 'Trouver le propriétaire',
            order: 0,
          ),
          StorylineStep(id: 'return_bag', title: 'Rapporter le sac', order: 1),
        ],
      ),
    ],
    relationships: [
      StorylineRelationship(
        id: relationshipId,
        kind: StorylineRelationshipKind.requires,
        sourceStorylineId: sideId,
        targetStorylineId: mainId,
      ),
    ],
  );

  static ScenarioAsset scenario() => const ScenarioAsset(
    id: scenarioId,
    name: 'Prêt ou attendre',
    entryNodeId: 'start',
    declaredOutcomes: ['ready', 'wait'],
    nodes: [
      ScenarioNode(id: 'start', type: ScenarioNodeType.start, title: 'Début'),
      ScenarioNode(
        id: 'choice',
        type: ScenarioNodeType.choice,
        title: 'Le départ',
        payload: ScenarioNodePayload(
          message: 'Êtes-vous prêt ?',
          choiceLabels: ['Prêt', 'Attendre'],
        ),
      ),
      ScenarioNode(
        id: 'ready',
        title: 'Prêt',
        binding: ScenarioNodeBinding(outcomeId: 'ready'),
        payload: ScenarioNodePayload(actionKind: 'emitOutcome'),
      ),
      ScenarioNode(
        id: 'wait',
        title: 'Attendre',
        binding: ScenarioNodeBinding(outcomeId: 'wait'),
        payload: ScenarioNodePayload(actionKind: 'emitOutcome'),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end, title: 'Fin'),
    ],
    edges: [
      ScenarioEdge(id: 'start_choice', fromNodeId: 'start', toNodeId: 'choice'),
      ScenarioEdge(
        id: 'choice_ready',
        kind: ScenarioEdgeKind.choice,
        fromNodeId: 'choice',
        toNodeId: 'ready',
        label: 'Prêt',
        order: 0,
      ),
      ScenarioEdge(
        id: 'choice_wait',
        kind: ScenarioEdgeKind.choice,
        fromNodeId: 'choice',
        toNodeId: 'wait',
        label: 'Attendre',
        order: 1,
      ),
      ScenarioEdge(id: 'ready_end', fromNodeId: 'ready', toNodeId: 'end'),
      ScenarioEdge(id: 'wait_end', fromNodeId: 'wait', toNodeId: 'end'),
    ],
  );
}
