import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('spatial text Fact input matches its structured runtime presenter', () {
    expect(SpatialGameplayCapabilities.commandIds,
        contains(NarrativeCommandIds.inputTextToFact));
    final scene = SceneAsset(id: 'text', name: 'Text', graph: SceneGraph(
      startNodeId: 'start', nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(id: 'input', kind: SceneNodeKind.action,
          payload: SceneActionPayload.interactive(SceneInteractiveCommand.fromJson({
            'kind': 'inputTextToFact', 'factId': 'name',
            'prompt': {'localizationKey': 'name', 'fallbackText': 'Nom ?'},
            'confirmationPrompt': {'localizationKey': 'confirm', 'fallbackText': 'Confirmer ?'},
            'constraints': {'minGraphemes': 1, 'maxGraphemes': 7}}))),
        SceneNode(id: 'end', kind: SceneNodeKind.end)], edges: [
        SceneEdge(id: 'start', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'input', kind: SceneEdgeKind.defaultFlow),
        SceneEdge(id: 'completed', fromNodeId: 'input', fromPortId: 'completed', toNodeId: 'end', kind: SceneEdgeKind.actionCompleted),
        SceneEdge(id: 'cancelled', fromNodeId: 'input', fromPortId: 'cancelled', toNodeId: 'end', kind: SceneEdgeKind.actionCompleted)]));
    final project = ProjectManifest(name: 'Text', maps: const [], tilesets: const [], version: ProjectVersion.v9,
      settings: const ProjectSettings(dimension: ProjectDimension.threeD),
      facts: [NarrativeFactDefinition(id: 'name', label: 'Name', initialValue: NarrativeValue.string(''))], scenes: [scene]);
    final diagnostics = diagnoseSceneAgainstProject(scene, project);
    expect(diagnostics.diagnostics.where((item) => item.severity == SceneDiagnosticSeverity.error), isEmpty);
  });
  test('spatial scenes admit owned effects, fanfares and explicit stop', () {
    for (final id in [
      NarrativeCommandIds.playSoundEffect,
      NarrativeCommandIds.playMusicEffect,
      NarrativeCommandIds.stopSoundEffects,
    ]) {
      expect(SpatialGameplayCapabilities.commandIds, contains(id));
    }
  });
}
