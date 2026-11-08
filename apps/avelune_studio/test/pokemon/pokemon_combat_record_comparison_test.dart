import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/data/local_pokemon_combat_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/combat_project_fixture.dart';
import '../support/m3_story_fixture.dart';

ProjectEncounterTable _table(String edition, {String name = 'Prairie'}) =>
    ProjectEncounterTable(
      id: 'prairie',
      name: name,
      encounterKind: EncounterKind.walk,
      variants: [
        ProjectEncounterVariant(
          id: 'edition',
          name: 'Édition',
          conditions: [
            ScriptConditionFactory.factEquals(
              'edition',
              NarrativeValue.string(edition),
            ),
          ],
          entries: const [
            ProjectEncounterEntry(
              speciesId: 'bulbasaur',
              minLevel: 3,
              maxLevel: 5,
              weight: 1,
            ),
          ],
        ),
      ],
    );

void main() {
  test(
    'a combat record is compared by content, never by JSON key order',
    () async {
      final source = await M3StoryFixture.create();
      addTearDown(() => source.directory.delete(recursive: true));
      await seedCombatProject(source);
      final file = File('${source.directory.path}/project.json');
      final project = ProjectManifest.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
      await file.writeAsString(
        jsonEncode(
          project
              .copyWith(
                facts: [
                  ...project.facts,
                  NarrativeFactDefinition(
                    id: 'edition',
                    label: 'Édition du jeu',
                    initialValue: const NarrativeValue.string('or'),
                  ),
                ],
              )
              .toJson(),
        ),
      );
      await source.maps.loadProject(source.session);
      final adapter = LocalPokemonCombatAdapter(
        session: source.session,
        mapAdapter: source.maps,
      );
      Future<ProjectEncounterTable?> saved() async => (await adapter.load())
          .project
          .encounterTables
          .where((table) => table.id == 'prairie')
          .firstOrNull;

      final authored = _table('or');
      await adapter.saveTable(null, authored);
      final reopened = await saved();
      expect(reopened, authored);
      expect(
        jsonEncode(reopened!.toJson()),
        isNot(jsonEncode(authored.toJson())),
      );

      final renamed = _table('or', name: 'Prairie du matin');
      await adapter.saveTable(authored, renamed);
      expect(await saved(), renamed);

      final published = await file.readAsBytes();
      final stale = <Future<void> Function()>[
        () => adapter.saveTable(_table('argent'), _table('argent')),
        () => adapter.saveTable(authored, _table('or', name: 'Ancienne')),
        () => adapter.saveTable(null, _table('or', name: 'Doublon')),
      ];
      for (final change in stale) {
        await expectLater(
          change(),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('changé sur le disque'),
            ),
          ),
        );
        expect(await file.readAsBytes(), published);
      }
      expect(await saved(), renamed);
    },
  );
}
