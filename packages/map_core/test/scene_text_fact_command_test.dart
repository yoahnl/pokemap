import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> textFactCommand({String factId = 'rival'}) => {
  'kind': 'inputTextToFact',
  'factId': factId,
  'prompt': {'localizationKey': 'rival.name', 'fallbackText': 'Son nom ?'},
  'confirmationPrompt': {
    'localizationKey': 'rival.confirm',
    'fallbackText': 'Confirmer {value} ?',
  },
  'constraints': {'minGraphemes': 1, 'maxGraphemes': 7},
};

SceneAsset textFactScene({String factId = 'rival'}) => SceneAsset(
  id: 'rival-name',
  name: 'Nom du rival',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'input',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.fromJson(textFactCommand(factId: factId)),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'enter',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'input',
        kind: SceneEdgeKind.defaultFlow,
      ),
      for (final port in ['completed', 'cancelled'])
        SceneEdge(
          id: 'leave-$port',
          fromNodeId: 'input',
          fromPortId: port,
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
    ],
  ),
);

void main() {
  test('optional name presets retain their exact order and native prompts', () {
    final source = {
      ...textFactCommand(),
      'presetValues': ['Blue', 'Gary', 'Michael'],
      'customChoiceLabel': 'Custom',
      'presetChoicePrompt': {
        'localizationKey': 'rival.choice',
        'fallbackText': 'Son nom ?',
      },
    };
    expect(SceneInteractiveCommand.fromJson(source).toJson(), source);
  });
  test('text Fact input has a closed persistent command and typed prompts', () {
    final command = SceneInteractiveCommand.fromJson(textFactCommand());
    expect(command.toJson(), textFactCommand());
    expect(command.outputPortIds, ['completed', 'cancelled']);
    expect(SceneInteractiveCommand.fromJson(command.toJson()), command);
    expect(buildSceneRuntimePlan(textFactScene()).canBuild, isTrue);
  });

  test('text input authoring requires one declared string Fact', () {
    for (final facts in <List<NarrativeFactDefinition>>[
      [],
      [NarrativeFactDefinition(id: 'rival', label: 'Wrong')],
      [
        NarrativeFactDefinition(
          id: 'rival',
          label: 'Name',
          initialValue: NarrativeValue.string(''),
        ),
        NarrativeFactDefinition(
          id: 'rival',
          label: 'Duplicate',
          initialValue: NarrativeValue.string(''),
        ),
      ],
    ]) {
      final scene = textFactScene();
      expect(
        diagnoseSceneAgainstProject(
          scene,
          ProjectManifest(name: 'QA', maps: [], tilesets: [], facts: facts),
        ).hasErrors,
        isTrue,
      );
    }
    final scene = textFactScene();
    expect(
      diagnoseSceneAgainstProject(
        scene,
        ProjectManifest(
          name: 'QA',
          maps: [],
          tilesets: [],
          facts: [
            NarrativeFactDefinition(
              id: 'rival',
              label: 'Nom du rival',
              initialValue: NarrativeValue.string(''),
            ),
          ],
        ),
      ).hasErrors,
      isFalse,
    );
  });

  test('malformed preset payloads fail as domain format errors', () {
    for (final values in <Object>[
      'Blue',
      [1],
    ]) {
      expect(
        () => SceneInteractiveCommand.fromJson({
          ...textFactCommand(),
          'presetValues': values,
        }),
        throwsFormatException,
      );
    }
  });

  test('canonical command form builds the same text Fact contract', () {
    final descriptor = NarrativeCommandCatalog.canonical().commands.singleWhere(
      (command) => command.id == 'inputTextToFact',
    );
    expect(descriptor.isPersistent, isTrue);
    expect(descriptor.isAwaitable, isTrue);
    expect(descriptor.parameters.map((field) => field.id), [
      'factId',
      'prompt',
      'confirmationPrompt',
      'minGraphemes',
      'maxGraphemes',
      'presetValues',
      'customChoiceLabel',
      'presetChoicePrompt',
    ]);
    final payload =
        buildScenePayloadForNarrativeCommand(
              commandId: descriptor.id,
              parameters: {
                'factId': 'rival',
                'prompt': 'Son nom ?',
                'confirmationPrompt': 'Confirmer {value} ?',
                'minGraphemes': '1',
                'maxGraphemes': '7',
              },
            )
            as SceneActionPayload;
    expect(payload.interactiveCommand!.kind.name, 'inputTextToFact');
    expect(payload.interactiveCommand!.toJson()['factId'], 'rival');
  });
}
