import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('campaign content authoring', () {
    test('upsert keeps a trainer identity unique and replaces its payload', () {
      final original = _trainer('lysa', 'Lysa');
      final project = _manifest(trainers: [original]);

      final updated = const CampaignContentActions().upsert(
        project,
        CampaignContentKind.trainer,
        _trainer('lysa', 'Champion Lysa'),
      );

      expect(updated.trainers, hasLength(1));
      expect(updated.trainers.single.name, 'Champion Lysa');
    });

    test('new game update is validated and directly inspectable', () {
      final project = _manifest();
      const newGame = ProjectNewGameConfig(
        enabled: true,
        startMapId: 'start',
        playerName: 'Hero',
      );

      final updated = const CampaignContentActions().updateNewGame(
        project,
        newGame,
      );

      expect(updated.newGame, newGame);
    });

    test('support matrix names every campaign runtime authority', () {
      final report = const CampaignContentInspector().inspect(_manifest());

      expect(
        report.runtimeSupport.map((entry) => entry.domain).toSet(),
        containsAll({
          'moves',
          'abilities',
          'items',
          'trainers',
          'encounterTables',
          'shops',
          'badges',
          'characters',
          'newGame',
        }),
      );
      expect(
        report.runtimeSupport.every(
          (entry) => entry.runtimeAuthority.isNotEmpty,
        ),
        isTrue,
      );
    });

    test('dispatcher exposes CRUD for each embedded campaign family', () {
      final actionIds = AuthoringMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();

      expect(
        actionIds,
        containsAll({
          'campaign.encounter_table.upsert',
          'campaign.shop.upsert',
          'campaign.badge.upsert',
          'campaign.trainer.upsert',
          'campaign.character.upsert',
          'campaign.new_game.update',
        }),
      );
    });
  });
}

ProjectTrainerEntry _trainer(String id, String name) => ProjectTrainerEntry(
      id: id,
      name: name,
      trainerClass: 'Gym Leader',
      team: const [
        ProjectTrainerPokemonEntry(speciesId: 'sproutle', level: 10),
      ],
    );

ProjectManifest _manifest({
  List<ProjectTrainerEntry> trainers = const [],
}) =>
    ProjectManifest(
      name: 'Campaign fixture',
      maps: const [
        ProjectMapEntry(
          id: 'start',
          name: 'Start',
          relativePath: 'maps/start.json',
        ),
      ],
      tilesets: const [],
      trainers: trainers,
    );
