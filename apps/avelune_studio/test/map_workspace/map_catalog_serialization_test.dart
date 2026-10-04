import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:path/path.dart' as p;

import 'map_catalog_fixture.dart';

void main() {
  test(
    'canonical cache reuses unchanged documents after folder publication',
    () async {
      final profiles = <ProjectSnapshotLoadProfile>[];
      final fixture = await MapCatalogFixture.create(profiles: profiles);
      addTearDown(fixture.dispose);
      final created = await fixture.createMap('warm-cache');
      expect(created.integrated, isTrue);
      profiles.clear();
      final grouped = await fixture.controller.mutateCatalog(
        'map.library.reorganize',
        {
          'groups': [
            const ProjectMapGroup(
              id: 'cached',
              name: 'Cache',
              type: MapGroupType.city,
            ).toJson(),
          ],
          'assignments': [],
        },
      );
      expect(grouped.integrated, isTrue, reason: grouped.error);
      expect(profiles, isNotEmpty);
      expect(
        profiles.every((profile) => profile.cacheHit),
        isTrue,
        reason: profiles
            .map(
              (profile) =>
                  'hit=${profile.cacheHit},read=${profile.initialReadMicroseconds},decode=${profile.decodeModelMicroseconds}',
            )
            .join(';'),
      );
    },
  );

  test(
    'map saves and catalogue operations share the existing session queue',
    () async {
      final fixture = await MapCatalogFixture.create();
      addTearDown(fixture.dispose);
      final document = fixture.controller.active!;
      document.commit(document.current.copyWith(properties: {'queued': true}));
      final entered = Completer<void>();
      final release = Completer<void>();
      final held = fixture.adapter.withResourceMutation(() async {
        entered.complete();
        await release.future;
      });
      await entered.future;
      final saved = fixture.controller.save(document);
      final created = fixture.createMap('serialized');
      expect(document.saving, isTrue);
      expect(fixture.controller.catalogBusy, isTrue);
      expect(
        await File(p.join(fixture.root.path, 'maps/serialized.json')).exists(),
        isFalse,
      );
      release.complete();
      await held;
      expect(await saved, isTrue);
      expect((await created).integrated, isTrue);
      expect(document.current.properties['queued'], isTrue);
      expect(document.dirty, isFalse);
    },
  );

  test(
    'logical folder changes preserve map files, atlas and loaded draft identities',
    () async {
      final fixture = await MapCatalogFixture.create();
      addTearDown(fixture.dispose);
      final controller = fixture.controller;
      final document = controller.active!;
      document.commit(document.current.copyWith(properties: {'draft': true}));
      final current = document.current;
      final paths = [
        'assets/atelier.png',
        ...controller.project!.maps.map((entry) => entry.relativePath),
      ];
      final before = {
        for (final path in paths)
          path: await File(p.join(fixture.root.path, path)).readAsBytes(),
      };
      const groups = [
        ProjectMapGroup(
          id: 'root',
          name: 'Monde',
          type: MapGroupType.city,
          tags: ['conservé'],
          properties: {'ambiance': 'nuit'},
        ),
        ProjectMapGroup(
          id: 'child',
          name: 'Quartier',
          type: MapGroupType.city,
          parentGroupId: 'root',
        ),
        ProjectMapGroup(
          id: 'leaf',
          name: 'Intérieurs',
          type: MapGroupType.facility,
          parentGroupId: 'child',
        ),
      ];
      final result = await controller.mutateCatalog('map.library.reorganize', {
        'groups': groups.map((group) => group.toJson()).toList(),
        'assignments': [
          {'mapId': 'jardin', 'groupId': 'leaf'},
        ],
      });
      expect(result.integrated, isTrue);
      expect(result.receipt!.changedPaths, ['project.json']);
      expect(controller.active, same(document));
      expect(document.current, same(current));
      expect(document.canUndo, isTrue);
      expect(document.dirty, isTrue);
      expect(controller.project!.maps.first.groupId, 'leaf');
      expect(controller.project!.groups.first.properties, {'ambiance': 'nuit'});
      for (final path in paths) {
        expect(
          await File(p.join(fixture.root.path, path)).readAsBytes(),
          before[path],
        );
      }
      expect(await controller.save(document), isTrue);
    },
  );
}
