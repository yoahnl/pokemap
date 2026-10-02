import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_catalogue_host_fixture.dart';

void main() {
  testWidgets(
    'empty project creates and reopens its first map without playability fiction',
    (tester) async {
      final fixture = await MapCatalogueHostFixture.open(tester, empty: true);
      expect(fixture.host.maps.active, isNull);
      expect(fixture.host.maps.project!.characters, isEmpty);
      final entry = await fixture.createMap('Première île');
      final original = fixture.host.maps.active!.current;
      await fixture.paintCollision();
      expect(fixture.host.maps.active!.dirty, isTrue);
      await fixture.tapKey('Enregistrer');
      final disk = await fixture.reopen();
      expect(disk.project.maps.single, entry);
      expect(disk.maps[entry.id], fixture.host.maps.active!.current);
      expect(disk.maps[entry.id], isNot(original));
      expect(disk.project.characters, isEmpty);
      expect(disk.project.settings.defaultPlayerCharacterId, isNull);
      expect(disk.project.newGame.startMapId, isNot(entry.id));
      expect(disk.maps[entry.id]!.entities, isEmpty);
      expect(disk.maps[entry.id]!.size.width, greaterThan(0));
      expect(disk.maps[entry.id]!.size.height, greaterThan(0));
      final path = fixture.host.session.state.project!.directoryPath;
      await fixture.host.dispose();
      final afterClose = await tester.runAsync(() async {
        final sessions = LocalProjectSessionAdapter();
        final session = await sessions.open(path);
        try {
          final maps = LocalMapWorkspaceAdapter();
          final project = await maps.loadProject(session);
          return (await maps.loadMap(session, project.maps.single)).map;
        } finally {
          await sessions.close(session);
        }
      });
      expect(afterClose, disk.maps[entry.id]);
    },
  );
}
