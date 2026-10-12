import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/scene_dialogue_choice_policy_authoring_gateway.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';

const _source = '''
title: Start
---
-> Oui
    <<outcome yes>>
-> Non
    <<outcome no>>
Un second choix.
-> Continuer
    <<outcome next>>
-> Revenir
    <<outcome back>>
===
title: Elsewhere
---
-> Autre
    <<outcome elsewhere>>
===
''';

void main() {
  test('disabling a declared cancel branch survives save and reload without changing its graph', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    const policy = SceneDialogueChoicePolicy(nodeName: 'Start');
    final updated = await fixture.gateway.updateDraft(fixture.root.path,
      project: fixture.project, sceneId: 'scene', nodeId: 'dialogue', policy: policy);
    expect(_payload(updated).choicePolicies.single, policy);
    expect(_payload(updated).declaredCancellationOutcomes, ['cancel']);
    expect(_payload(updated).expectedOutcomes, _payload(fixture.project).expectedOutcomes);
    expect(updated.scenes.single.graph.edges, fixture.project.scenes.single.graph.edges);
    await fixture.projectFile.writeAsString(jsonEncode(updated.toJson()));
    await fixture.queries.invalidate(fixture.root.path);
    final reloaded = (await fixture.queries.open(fixture.root.path)).manifest;
    expect(_payload(reloaded).choicePolicies.single.cancellation.kind, SceneDialogueChoiceCancellationKind.disabled);
    expect(_payload(reloaded).declaredCancellationOutcomes, ['cancel']);
    expect(reloaded.scenes.single.graph.edges, fixture.project.scenes.single.graph.edges);
    final data = await fixture.gateway.load(fixture.root.path,
      project: reloaded, sceneId: 'scene', nodeId: 'dialogue');
    expect(data.scopes.first.branches.map((branch) => branch.outcomeId), ['cancel']);
  });

  test(
    'loads exact successive choice scopes from the frozen safe source snapshot',
    () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final data = await fixture.gateway.load(
        fixture.root.path,
        project: fixture.project,
        sceneId: 'scene',
        nodeId: 'dialogue',
      );
      expect(data.scopes.map((scope) => (scope.nodeName, scope.choiceIndex)), [
        ('Start', 0),
        ('Start', 1),
        ('Elsewhere', 0),
      ]);
      expect(data.scopes[0].choices.map((choice) => choice.outcomeId), [
        'yes',
        'no',
      ]);
      expect(data.scopes[1].choices.map((choice) => choice.outcomeId), [
        'next',
        'back',
      ]);
      expect(data.scopes[0].labels, ['Oui', 'Non']);
      expect(data.scopes[0].branches.map((branch) => branch.outcomeId), [
        'cancel',
      ]);
      await fixture.source.writeAsString(
        _source.replaceFirst('Oui', 'Oui modifié'),
      );
      final frozen = await fixture.gateway.load(
        fixture.root.path,
        project: fixture.project,
        sceneId: 'scene',
        nodeId: 'dialogue',
      );
      expect(frozen.scopes.first.labels.first, 'Oui');
      await fixture.queries.invalidate(fixture.root.path);
      final fresh = await fixture.gateway.load(
        fixture.root.path,
        project: fixture.project,
        sceneId: 'scene',
        nodeId: 'dialogue',
      );
      expect(fresh.scopes.first.labels.first, 'Oui modifié');
    },
  );

  test(
    'updates through canonical SceneActions and survives ordinary save and reload',
    () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      const policy = SceneDialogueChoicePolicy(
        nodeName: 'Start',
        choiceIndex: 1,
        defaultOutcomeId: 'back',
        cancellation: SceneDialogueChoiceCancellation.choice('next'),
      );
      final before = await fixture.projectFile.readAsBytes();
      final updated = await fixture.gateway.updateDraft(
        fixture.root.path,
        project: fixture.project,
        sceneId: 'scene',
        nodeId: 'dialogue',
        policy: policy,
      );
      expect(await fixture.projectFile.readAsBytes(), before);
      final compiled = const DialogueAuthoringCompiler()
          .compile(entry: fixture.project.dialogues.single, source: _source)
          .document!;
      expect(
        updated,
        const SceneActions().updateDialogueChoicePolicy(
          fixture.project,
          maps: const [],
          sceneId: 'scene',
          nodeId: 'dialogue',
          choicePolicy: policy,
          dialogue: compiled,
        ),
      );
      await fixture.projectFile.writeAsString(jsonEncode(updated.toJson()));
      await fixture.queries.invalidate(fixture.root.path);
      final reloaded = await fixture.queries.open(fixture.root.path);
      expect(_payload(reloaded.manifest).choicePolicies.last, policy);
      expect(await fixture.source.readAsString(), _source);
      await expectLater(
        fixture.gateway.updateDraft(
          fixture.root.path,
          project: updated,
          sceneId: 'scene',
          nodeId: 'dialogue',
          policy: const SceneDialogueChoicePolicy(
            nodeName: 'Start',
            choiceIndex: 1,
            defaultOutcomeId: 'yes',
          ),
        ),
        throwsA(
          isA<NarrativeAuthoringException>().having(
            (error) => error.code,
            'code',
            'scene.dialogue.choice_policy.invalid',
          ),
        ),
      );
    },
  );
}

SceneYarnDialoguePayload _payload(ProjectManifest project) =>
    project.scenes.single.graph.nodes
            .singleWhere((node) => node.id == 'dialogue')
            .payload
        as SceneYarnDialoguePayload;

ProjectManifest _project() => ProjectManifest(
  name: 'Choices',
  maps: const [],
  tilesets: const [],
  dialogues: const [
    ProjectDialogueEntry(
      id: 'choice',
      name: 'Choix',
      relativePath: 'dialogues/choice.yarn',
      declaredOutcomes: [
        DialogueDeclaredOutcome(id: 'yes', label: 'Oui'),
        DialogueDeclaredOutcome(id: 'no', label: 'Non'),
        DialogueDeclaredOutcome(id: 'next', label: 'Continuer'),
        DialogueDeclaredOutcome(id: 'back', label: 'Revenir'),
        DialogueDeclaredOutcome(id: 'elsewhere', label: 'Autre'),
      ],
    ),
  ],
  scenes: [
    SceneAsset(
      id: 'scene',
      name: 'Scene',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'dialogue',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(
              dialogueId: 'choice',
              expectedOutcomes: const [
                'yes',
                'no',
                'next',
                'back',
                'elsewhere',
                'cancel',
              ],
              choicePolicies: const [
                SceneDialogueChoicePolicy(
                  nodeName: 'Start',
                  cancellation: SceneDialogueChoiceCancellation.branch(
                    'cancel',
                  ),
                ),
              ],
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end, title: 'Fin'),
          SceneNode(
            id: 'cancel_end',
            kind: SceneNodeKind.end,
            title: 'Retour à la carte',
          ),
        ],
        edges: [
          SceneEdge(
            id: 'entry',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'dialogue',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'completed',
            fromNodeId: 'dialogue',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
          for (final id in ['yes', 'no', 'next', 'back', 'elsewhere', 'cancel'])
            SceneEdge(
              id: id,
              fromNodeId: 'dialogue',
              fromPortId: id,
              toNodeId: id == 'cancel' ? 'cancel_end' : 'end',
              kind: SceneEdgeKind.dialogueOutcome,
            ),
        ],
      ),
    ),
  ],
);

final class _Fixture {
  _Fixture(this.root, this.project, this.queries);
  final Directory root;
  final ProjectManifest project;
  final AuthoringQueryAdapter queries;
  SceneDialogueChoicePolicyAuthoringGateway get gateway =>
      SceneDialogueChoicePolicyAuthoringGateway(queries: queries);
  File get source => File('${root.path}/dialogues/choice.yarn');
  File get projectFile => File('${root.path}/project.json');

  static Future<_Fixture> create() async {
    final root = await Directory.systemTemp.createTemp('scene-policy-editor-');
    final project = _project();
    final fixture = _Fixture(
      root,
      project,
      AuthoringQueryAdapter(fileReader: const EditorProjectFileReader()),
    );
    await fixture.source.parent.create(recursive: true);
    await fixture.source.writeAsString(_source);
    await fixture.projectFile.writeAsString(jsonEncode(project.toJson()));
    return fixture;
  }

  Future<void> dispose() async {
    await queries.closeAll();
    await root.delete(recursive: true);
  }
}
