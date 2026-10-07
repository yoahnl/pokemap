import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';
import 'support/spatial_package_fixture.dart';

Map<String, List<int>> npcPayload() {
  final files = spatialPayload();
  final project = ProjectManifest.fromJson(
      jsonDecode(utf8.decode(files['project/project.json']!)));
  final map = MapData.fromJson(
      jsonDecode(utf8.decode(files['project/maps/map.json']!)));
  files['project/project.json'] =
      utf8.encode(jsonEncode(project.copyWith(dialogues: [
    ProjectDialogueEntry(
        id: 'hello', name: 'Hello', relativePath: 'dialogues/hello.json')
  ]).toJson()));
  files['project/maps/map.json'] =
      utf8.encode(jsonEncode(map.copyWith(entities: [
    MapEntity(
        id: 'npc',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 4, y: 4),
        npc: MapEntityNpcData(
            characterId: 'hero', dialogue: DialogueRef(dialogueId: 'hello')))
  ]).toJson()));
  files['project/dialogues/hello.json'] = const RuntimeDialogueDocumentCodec()
      .encodeUtf8(RuntimeDialogueDocument(nodes: [
    RuntimeDialogueNode(
        title: 'Start', steps: [RuntimeDialogueLine('Bonjour !')])
  ]));
  return files;
}

void main() {
  test(
      'packages static character NPC and text dialogue in autonomous exploration',
      () {
    final built = const GamePackageBuilder()
        .build(manifest: spatialManifest(), payloadFiles: npcPayload());
    expect(
        const GamePackageInspector()
            .inspect(built.packageBytes)
            .manifest
            .compatibility
            .requiredCapabilities,
        contains('map3d@1'));
  });
  for (final mutation in [
    'missing character',
    'movement',
    'script',
    'choice',
    'missing dialogue',
    'missing node'
  ]) {
    test('rejects NPC $mutation outside executed subset', () {
      final files = npcPayload();
      final map = jsonDecode(utf8.decode(files['project/maps/map.json']!));
      final npc = map['entities'][0]['npc'];
      switch (mutation) {
        case 'missing character':
          npc['characterId'] = 'missing';
        case 'movement':
          npc['movement']['mode'] = 'patrol';
        case 'script':
          npc['dialogue']['scriptPathRelative'] = 'scripts/a.yarn';
        case 'missing dialogue':
          files.remove('project/dialogues/hello.json');
        case 'missing node':
          npc['dialogue']['startNode'] = 'Absent';
        case 'choice':
          files['project/dialogues/hello.json'] =
              const RuntimeDialogueDocumentCodec()
                  .encodeUtf8(RuntimeDialogueDocument(nodes: [
            RuntimeDialogueNode(title: 'Start', steps: [
              RuntimeDialogueChoiceBlock([
                RuntimeDialogueChoice(
                    text: 'Oui', steps: [RuntimeDialogueLine('Oui')])
              ])
            ])
          ]));
      }
      files['project/maps/map.json'] = utf8.encode(jsonEncode(map));
      expect(
          () => const GamePackageBuilder()
              .build(manifest: spatialManifest(), payloadFiles: files),
          throwsA(isA<GamePackageFormatException>()));
    });
  }
}
