import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_catalog_fixture.dart';

void main() {
  test(
    'moving a map retains an in-flight preview and its subsequent cache',
    () async {
      final fixture = await MapCatalogFixture.create();
      addTearDown(fixture.dispose);
      final reads = DelayedMapPort(fixture.adapter);
      final controller = MapWorkspaceController(
        fixture.session,
        reads,
        catalogPort: fixture.catalog,
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      final entry = controller.project!.maps.last;
      reads.mapId = entry.id;
      final pending = controller.previewMap(entry.id);
      await reads.loaded.future;
      final moved = await controller.mutateCatalog('map.library.reorganize', {
        'groups': [
          const ProjectMapGroup(
            id: 'moved',
            name: 'Destination',
            type: MapGroupType.city,
          ).toJson(),
        ],
        'assignments': [
          {'mapId': entry.id, 'groupId': 'moved'},
        ],
      });
      expect(moved.integrated, isTrue, reason: moved.error);
      reads.release.complete();
      final preview = await pending;
      expect(preview!.id, entry.id);
      expect(await controller.previewMap(entry.id), same(preview));
      reads.mapId = null;
      await controller.activate(entry);
      expect(controller.error, isNull);
      expect(controller.active?.base.mapId, entry.id);
    },
  );

  for (final activation in [false, true]) {
    test(
      'a stale ${activation ? 'activation' : 'preview'} cannot resurrect an old title',
      () async {
        final fixture = await MapCatalogFixture.create();
        addTearDown(fixture.dispose);
        final reads = DelayedMapPort(fixture.adapter);
        final controller = MapWorkspaceController(
          fixture.session,
          reads,
          catalogPort: fixture.catalog,
        );
        addTearDown(controller.dispose);
        await controller.initialize();
        final old = controller.project!.maps.last;
        reads.mapId = old.id;
        final pending = activation
            ? controller.activate(old).then<MapData?>((_) => null)
            : controller.previewMap(old.id);
        await reads.loaded.future;
        final renamed = await controller.mutateCatalog('map.update_metadata', {
          'mapId': old.id,
          'name': 'Titre actuel',
        });
        expect(renamed.integrated, isTrue, reason: renamed.error);
        reads.release.complete();
        final result = await pending;
        if (activation) {
          expect(controller.active!.base.mapId, isNot(old.id));
          expect(controller.documents.containsKey(old.id), isFalse);
        } else {
          expect(result, isNull);
        }
        reads.mapId = null;
        expect((await controller.previewMap(old.id))!.name, 'Titre actuel');
      },
    );
  }
}

final class DelayedMapPort implements MapWorkspacePort {
  DelayedMapPort(this.delegate);
  final MapWorkspacePort delegate;
  String? mapId;
  final loaded = Completer<void>();
  final release = Completer<void>();

  @override
  Future<ProjectManifest> loadProject(ProjectSession session) =>
      delegate.loadProject(session);

  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    final document = await delegate.loadMap(session, entry);
    if (entry.id == mapId) {
      loaded.complete();
      await release.future;
    }
    return document;
  }

  @override
  Future<String> saveMap(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapData current,
  ) => delegate.saveMap(session, base, current);
}
