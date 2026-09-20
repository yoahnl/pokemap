import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/narrative/application/dialogue_draft_codec.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/narrative/domain/dialogue_draft.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:map_core/map_core.dart';

import '../../tool/create_example_project.dart';

class Ui06SceneFixture {
  Ui06SceneFixture(this.directory, this.session, this.maps, this.receipt);

  final Directory directory;
  final ProjectSession session;
  final LocalMapWorkspaceAdapter maps;
  final NarrativePublicationReceipt receipt;
  ProjectManifest get manifest => receipt.manifest;
  SceneAsset get scene => manifest.scenes.single;
  static const sceneId = 'scene_station_meeting';
  static const passFactId = 'station_pass_obtained';
  static const departureFactId = 'station_departure_allowed';
  static const cinematicId = 'station_departure_pause';
  static const eventId = 'evt_019abcde-9000-7000-8000-000000000106';
  static const lines = {
    'station_welcome': 'Bienvenue en gare. Avez-vous votre laissez-passer ?',
    'station_refusal': 'Il vous faut un laissez-passer.',
    'station_agreement': 'Vous pouvez embarquer.',
  };
  static const names = {
    'station_welcome': 'Accueil du chef de gare',
    'station_refusal': 'Il vous faut un laissez-passer',
    'station_agreement': 'Vous pouvez embarquer',
  };

  static Future<Ui06SceneFixture> create({
    bool withCinematic = false,
    bool passObtained = false,
  }) async {
    final temporary = await Directory.systemTemp.createTemp('avelune_ui06_');
    final directory = Directory(await temporary.resolveSymbolicLinks());
    await writeExampleProject(directory);
    final session = ProjectSession(
      sessionId: directory.path,
      name: 'Rencontre en gare',
      directoryPath: directory.path,
    );
    final maps = LocalMapWorkspaceAdapter();
    final manifest = await maps.loadProject(session);
    final base = await maps.loadMap(session, manifest.maps.first);
    final scene = buildScene(withCinematic: withCinematic);
    final receipt =
        await LocalNarrativeAdapter(session: session, mapAdapter: maps).publish(
          NarrativePublication(
            base: base,
            current: base.map,
            scenes: [scene],
            dialogues: buildDialogues(),
            cinematics: [buildCinematic()],
            facts: [
              NarrativeFactDefinition(
                id: passFactId,
                label: 'Laissez-passer obtenu',
                defaultValue: passObtained,
              ),
              NarrativeFactDefinition(
                id: departureFactId,
                label: 'Départ autorisé',
              ),
            ],
            events: [
              NarrativeEventRecord.configuredStructurallyUnchecked(
                NarrativeEventDefinition(
                  id: eventId,
                  name: 'Rencontre en gare',
                  source: NarrativeEventSourceRef.mapEnter(base.map.id),
                  conditions: [],
                  sceneId: scene.id,
                  reusePolicy: NarrativeEventReusePolicy.oneShot,
                  priority: 0,
                  order: 0,
                ),
                enabled: true,
                activeInLegacyMode: true,
              ),
            ],
          ),
        );
    return Ui06SceneFixture(directory, session, maps, receipt);
  }

  Future<void> dispose() => directory.delete(recursive: true);

  static List<NarrativeDialogueSource> buildDialogues() => [
    for (final entry in lines.entries)
      const DialogueDraftCodec().encode(
        DialogueDraft(
          entry: ProjectDialogueEntry(
            id: entry.key,
            name: names[entry.key]!,
            relativePath: 'dialogues/${entry.key}.yarn',
          ),
          branches: [
            DialogueBranchDraft(
              id: 'Start',
              name: 'Début',
              lines: [DialogueLineDraft(text: entry.value)],
            ),
          ],
        ),
      ),
  ];

  static CinematicAsset buildCinematic() => CinematicAsset(
    id: cinematicId,
    title: 'Un instant avant le départ',
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'station_pause',
          kind: CinematicTimelineStepKind.wait,
          durationMs: 100,
        ),
      ],
    ),
  );

  static SceneAsset buildScene({bool withCinematic = false}) => SceneAsset(
    id: sceneId,
    name: 'Rencontre en gare',
    metadata: const {'fixture': 'AS-UI-006', 'preserve': 'canonical'},
    declaredOutcomes: [
      SceneOutcome(id: 'attente', label: 'Attente'),
      SceneOutcome(id: 'embarquement', label: 'Embarquement'),
    ],
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start, title: 'Début'),
        _dialogueNode('welcome', 'station_welcome'),
        SceneNode(
          id: 'pass',
          kind: SceneNodeKind.condition,
          title: 'Laissez-passer obtenu ?',
          payload: SceneConditionPayload(
            conditionLabel: 'Laissez-passer obtenu ?',
            conditionRef: passFactId,
            conditionSource: SceneConditionSource(
              sourceKind: SceneConditionSourceKind.fact,
              sourceId: passFactId,
              operator: SceneConditionOperator.isTrue,
              label: 'Laissez-passer obtenu',
            ),
          ),
        ),
        _dialogueNode('refusal', 'station_refusal'),
        _dialogueNode('agreement', 'station_agreement'),
        SceneNode(
          id: 'authorize',
          kind: SceneNodeKind.action,
          title: 'Départ autorisé = Oui',
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: departureFactId, value: true),
          ),
        ),
        if (withCinematic)
          SceneNode(
            id: 'cinematic',
            kind: SceneNodeKind.cinematic,
            title: 'Un instant avant le départ',
            payload: SceneCinematicPayload(cinematicId: cinematicId),
          ),
        for (final end in ['attente', 'embarquement'])
          SceneNode(
            id: end,
            kind: SceneNodeKind.end,
            title: end == 'attente' ? 'Attente' : 'Embarquement',
            payload: SceneEndPayload(
              sceneOutcomeId: end,
              outcomePolicy: end == 'attente'
                  ? SceneOutcomePolicy.retryable
                  : SceneOutcomePolicy.progression,
            ),
          ),
      ],
      edges: [
        _edge('start', 'welcome'),
        _edge('welcome', 'pass'),
        _edge(
          'pass',
          'refusal',
          port: 'false',
          kind: SceneEdgeKind.conditionFalse,
        ),
        _edge(
          'pass',
          'agreement',
          port: 'true',
          kind: SceneEdgeKind.conditionTrue,
        ),
        _edge('refusal', 'attente'),
        _edge('agreement', 'authorize'),
        _edge(
          'authorize',
          withCinematic ? 'cinematic' : 'embarquement',
          kind: SceneEdgeKind.actionCompleted,
        ),
        if (withCinematic)
          _edge(
            'cinematic',
            'embarquement',
            kind: SceneEdgeKind.cinematicCompleted,
          ),
      ],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        for (final entry in {
          'start': (0.0, 230.0),
          'welcome': (145.0, 210.0),
          'pass': (390.0, 210.0),
          'refusal': (390.0, 480.0),
          'agreement': (635.0, 0.0),
          'authorize': (635.0, 210.0),
          if (withCinematic) 'cinematic': (635.0, 430.0),
          'attente': (650.0, 670.0),
          'embarquement': (855.0, withCinematic ? 450.0 : 240.0),
        }.entries)
          SceneNodeLayout(
            nodeId: entry.key,
            x: entry.value.$1,
            y: entry.value.$2,
          ),
      ],
    ),
  );

  static SceneNode _dialogueNode(String id, String dialogueId) => SceneNode(
    id: id,
    kind: SceneNodeKind.yarnDialogue,
    title: names[dialogueId]!,
    payload: SceneYarnDialoguePayload(
      dialogueId: dialogueId,
      yarnNodeName: 'Start',
    ),
  );

  static SceneEdge _edge(
    String from,
    String to, {
    String port = 'completed',
    SceneEdgeKind kind = SceneEdgeKind.defaultFlow,
  }) => SceneEdge(
    id: 'edge_${from}_${port}_$to',
    fromNodeId: from,
    fromPortId: port,
    toNodeId: to,
    kind: kind,
  );
}
