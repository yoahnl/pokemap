import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../support/narrative_title_fixture.dart';

void main() {
  test(
      'a working catalog publishes a scene, a dialogue and a world rule '
      'without a map in one transaction', () async {
    final fixture = await NarrativeTitleFixture.create(project: _project());
    addTearDown(fixture.close);
    final mapFile = File('${fixture.root.path}/maps/map_0.json');
    await mapFile.parent.create(recursive: true);
    await mapFile.writeAsString(jsonEncode(_map().toJson()));
    final mapBytes = await mapFile.readAsBytes();

    final sceneOnly = {
      'scenes': [_scene('scene_alone').toJson()]
    };
    final alone = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'narrative.publish_document',
        parameters: sceneOnly);
    expect(alone.maps, isEmpty);

    final parameters = {
      'scenes': [_scene('scene_new').toJson()],
      'dialogues': [
        {
          'entry': const ProjectDialogueEntry(
                  id: 'dialogue_new',
                  name: 'New',
                  relativePath: 'dialogues/new.yarn')
              .toJson(),
          'source': 'title: Start\n---\nHello\n===\n',
          'revision': null,
        }
      ],
      'worldRules': [_rule('Tree').toJson()],
    };
    final snapshot = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'narrative.publish_document',
        parameters: parameters);
    expect(snapshot.maps.map((map) => map.id), ['map_0']);
    expect(
        snapshot.availableProjectDocuments!['worldRules'], {'world_rule_tree'});
    final head = (await fixture.snapshot()).root;
    final receipt = await fixture.apply(
        'narrative.publish_document', parameters, 'publish-without-map');
    expect((await fixture.snapshot()).root, isNot(head));
    final history =
        await fixture.api.history(fixture.opened.projectHandle, limit: 20);
    expect([
      for (final entry in history['entries'] as List)
        if (entry['entryId'] == receipt) entry
    ], hasLength(1));
    expect(await mapFile.readAsBytes(), mapBytes);
    expect(await File('${fixture.root.path}/dialogues/new.yarn').readAsString(),
        contains('Hello'));

    await fixture.reattach();
    final reread = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'narrative.publish_document',
        parameters: parameters);
    expect(
        reread.manifest.scenes.map((scene) => scene.id), contains('scene_new'));
    expect(reread.manifest.worldRules.single.id, 'world_rule_tree');
    expect(reread.manifest.dialogues.map((entry) => entry.id),
        contains('dialogue_new'));
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('a map revision without a map and an invalid world rule are refused',
      () async {
    final fixture = await NarrativeTitleFixture.create(project: _project());
    addTearDown(fixture.close);
    final mapFile = File('${fixture.root.path}/maps/map_0.json');
    await mapFile.parent.create(recursive: true);
    await mapFile.writeAsString(jsonEncode(_map().toJson()));
    final head = (await fixture.snapshot()).root;
    await expectLater(
        fixture.apply('narrative.publish_document',
            {'mapRevision': 'sha256:x', 'scenes': []}, 'revision-only'),
        throwsA(isA<ArgumentError>()
            .having((error) => error.name, 'name', 'mapRevision')));
    await expectLater(
        fixture.apply(
            'narrative.publish_document',
            {
              'worldRules': [_rule('Bad', entityId: 'ghost').toJson()]
            },
            'bad-rule'),
        throwsA(isA<NarrativeAuthoringException>().having(
            (error) => error.code, 'code', 'world_rule.batch_rejected')));
    expect((await fixture.snapshot()).root, head);
  });
}

SceneAsset _scene(String id) => SceneAsset(
      id: id,
      name: id,
      graph: SceneGraph(startNodeId: 'start', nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ], edges: [
        SceneEdge(
            id: 'flow',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow)
      ]),
    );

WorldRuleDefinition _rule(String label, {String entityId = 'tree'}) =>
    WorldRuleDefinition(
      id: 'world_rule_${label.toLowerCase()}',
      label: label,
      source: WorldRuleSource.civilWeekday(
          weekday: CivilWeekday.friday, expectedValue: true),
      target: WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEntity,
          mapId: 'map_0',
          entityId: entityId),
      effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
    );

MapData _map() => const MapData(
      id: 'map_0',
      name: 'Map 0',
      size: GridSize(width: 6, height: 6),
      entities: [
        MapEntity(
            id: 'tree',
            name: 'Tree',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 1, y: 1),
            npc: MapEntityNpcData(displayName: 'Tree')),
      ],
    );

ProjectManifest _project() => narrativeTitleProject(unrelated: 1);
