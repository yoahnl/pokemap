import 'package:avelune_studio/features/cinematics/application/cinematic_actor_labels.dart';
import 'package:avelune_studio/features/events/application/event_scene_effects.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_pocket_label.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  final project = ProjectManifest(name: 'Audit', tilesets: [], maps: []);

  SceneAsset sceneWithAction(String? title) => SceneAsset(
    id: 'scene',
    name: 'Scène',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'action',
          kind: SceneNodeKind.action,
          title: title,
          payload: SceneActionPayload(actionKind: 'custom-untouched'),
        ),
      ],
    ),
  );

  test('an untitled scene action gets a readable fallback, never null', () {
    expect(eventSceneEffects(sceneWithAction(null), project), [
      'Action de scène · Action sans nom',
    ]);
    expect(eventSceneEffects(sceneWithAction('  '), project), [
      'Action de scène · Action sans nom',
    ]);
    expect(eventSceneEffects(sceneWithAction('Ouvrir la porte'), project), [
      'Action de scène · Ouvrir la porte',
    ]);
  });

  test('cinematic actor and character choices keep their id beside a fallback name', () {
    expect(
      cinematicActorChoiceLabel(null, 'mother'),
      'Acteur sans nom · mother',
    );
    expect(cinematicActorChoiceLabel('Maman', 'mother'), 'Maman · mother');
    expect(
      cinematicEntityChoiceLabel('', 'npc_1'),
      'Personnage sans nom · npc_1',
    );
    expect(cinematicEntityChoiceLabel('Prof', 'npc_1'), 'Prof · npc_1');
  });

  test('item pockets show readable labels and keep unknown identifiers', () {
    expect(pokemonPocketLabel('medicine'), 'Soins');
    expect(pokemonPocketLabel('balls'), 'Balls');
    expect(pokemonPocketLabel('key_items'), 'Objets clés');
    expect(pokemonPocketLabel('key-items'), 'Objets clés');
    expect(pokemonPocketLabel('machines'), 'CT/CS');
    expect(pokemonPocketLabel('battle'), 'Objets de combat');
    expect(pokemonPocketLabel('berries'), 'Baies');
    expect(pokemonPocketLabel('mail'), 'Lettres');
    expect(pokemonPocketLabel('noigrumes'), 'Noigrumes');
    expect(pokemonPocketLabel('custom_pocket'), 'custom_pocket');
  });
}
