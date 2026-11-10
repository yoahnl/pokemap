import 'package:avelune_studio/features/map_workspace/application/map_metadata_settings_draft.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_map_catalog_actions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_catalogue_host_fixture.dart';
import '../support/real_test_io.dart';

void main() {
  const map = MapData(
    id: 'map',
    name: 'Grotte',
    size: GridSize(width: 8, height: 6),
  );
  const project = ProjectManifest(
    name: 'Rope',
    maps: [],
    tilesets: [],
    groups: [
      ProjectMapGroup(
        id: 'dungeon',
        name: 'Montagne',
        type: MapGroupType.dungeon,
      ),
    ],
  );

  test(
    'native dungeon and restriction settings produce typed map metadata',
    () {
      final draft = MapMetadataSettingsDraft(map)
        ..dungeon = 'dungeon'
        ..allowed = false
        ..bicycle = false;
      expect(draft.valid(project), isTrue);
      expect(draft.parameters, {
        'mapId': 'map',
        'escapeRopeDungeonId': 'dungeon',
        'allowEscapeRope': false,
        'allowBicycle': false,
      });
      expect(map.mapMetadata.escapeRopeDungeonId, isNull);
    },
  );

  test(
    'unknown dungeon is refused and untouched contextual rules are omitted',
    () {
      final draft = MapMetadataSettingsDraft(map)..dungeon = 'missing';
      expect(draft.valid(project), isFalse);
      draft.dungeon = '';
      expect(draft.valid(project), isTrue);
      expect(draft.parameters['escapeRopeDungeonId'], isNull);
      expect(draft.parameters.containsKey('contextualItemUses'), isFalse);
    },
  );

  testWidgets(
    'metadata publication saves only its real dirty target and reopens its movement settings',
    (tester) async {
      final fixture = await MapCatalogueHostFixture.open(tester);
      final initial = await fixture.reopen();
      final dungeon = await fixture.createFolder('Donjon des essais');
      await fixture.paintCollision();
      final owner = fixture.host.maps.active!;
      final authored = owner.current;
      expect(owner.dirty, isTrue);
      final draft = MapMetadataSettingsDraft(authored)
        ..dungeon = dungeon.id
        ..allowed = false
        ..bicycle = false;
      final error = await RealTestIo.run(
        tester,
        () => saveWorkspaceMapMetadata(
          controller: fixture.host.maps,
          document: owner,
          values: draft.parameters,
        ),
      );
      expect(error, isNull);
      expect(fixture.host.maps.active, same(owner));
      expect(owner.dirty, isFalse);
      final reopened = await fixture.reopen();
      final saved = reopened.maps[authored.id]!;
      expect(saved.mapMetadata.escapeRopeDungeonId, dungeon.id);
      expect(saved.mapMetadata.allowEscapeRope, isFalse);
      expect(saved.mapMetadata.allowBicycle, isFalse);
      expect(saved.copyWith(mapMetadata: authored.mapMetadata), authored);
      expect(reopened.maps['annex'], initial.maps['annex']);
      expect(reopened.project.newGame, initial.project.newGame);
    },
  );
}
