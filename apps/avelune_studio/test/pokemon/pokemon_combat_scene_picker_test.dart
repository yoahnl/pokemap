import 'package:avelune_studio/presentation/features/scenes/scene_payload_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  testWidgets('the scene battle picker returns the authored unique identity', (
    tester,
  ) async {
    const project = ProjectManifest(
      name: 'Combat',
      maps: [],
      tilesets: [],
      encounterTables: [
        ProjectEncounterTable(
          id: 'legendary_station',
          name: 'Gardien de la gare',
          encounterKind: EncounterKind.special,
          tags: ['studio:unique'],
          entries: [
            ProjectEncounterEntry(
              speciesId: 'bulbasaur',
              minLevel: 30,
              maxLevel: 30,
            ),
          ],
        ),
      ],
    );
    SceneNodePayload? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => selected = await chooseScenePayload(
                context,
                SceneNodeKind.battle,
                project,
              ),
              child: const Text('Ajouter un combat'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ajouter un combat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rencontre unique : Gardien de la gare'));
    await tester.pumpAndSettle();

    expect(selected, isA<SceneBattlePayload>());
    final battle = selected! as SceneBattlePayload;
    expect(battle.battleKind, 'wild');
    expect(battle.battleTemplateId, 'legendary_station');
    expect(
      battle.declaredOutcomes,
      containsAll(['victory', 'captured', 'defeat', 'runaway']),
    );
  });
}
