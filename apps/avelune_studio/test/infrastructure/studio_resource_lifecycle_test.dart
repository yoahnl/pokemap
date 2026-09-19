import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/map_workspace/workspace_resource_diagnostic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';

import '../support/resource_stress_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ResourceStressFixture fixture;
  setUp(() async => fixture = await ResourceStressFixture.create());
  tearDown(() => fixture.dispose());

  test(
    'metadata reads no image and late atlas loads without earlier catalogue',
    () async {
      final resources = await StudioMapResources.load(
        fixture.session,
        fixture.manifest,
      );
      addTearDown(resources.dispose);
      expect(resources.store.decoder.reads, 0);
      expect(resources.images, isEmpty);
      resources.setActiveMap(fixture.lateMap);
      await resources.settled;
      expect(resources.images, contains(fixture.lateAtlasId));
      expect(resources.store.decoder.decodes, 1);
      expect(resources.images.length, lessThan(4));
      expect(resources.diagnostics, isEmpty);
      expect(resources.decodedBytes, fixture.decodedAtlasBytes);
    },
  );

  test(
    'small budget evicts unused A and reloads A after B without destroying leases',
    () async {
      await File(
        '${fixture.directory.path}/assets/atelier.png',
      ).copy('${fixture.directory.path}/assets/other.png');
      final manifest = fixture.manifest.copyWith(
        characters: [],
        tilesets: [
          const ProjectTilesetEntry(
            id: 'a',
            name: 'A',
            relativePath: 'assets/atelier.png',
          ),
          const ProjectTilesetEntry(
            id: 'b',
            name: 'B',
            relativePath: 'assets/other.png',
          ),
        ],
      );
      final resources = await StudioMapResources.load(
        fixture.session,
        manifest,
        maximumBytes: fixture.decodedAtlasBytes,
      );
      addTearDown(resources.dispose);
      final mapA = MapData(
        id: 'a',
        name: 'A',
        tilesetId: 'a',
        size: const GridSize(width: 1, height: 1),
      );
      final mapB = mapA.copyWith(id: 'b', tilesetId: 'b');
      resources.setActiveMap(mapA);
      await resources.settled;
      final firstA = resources.images['a']!;
      final painter = Object();
      resources.retain(painter, {'a'});
      resources.setActiveMap(mapB);
      await resources.settled;
      expect(firstA.debugDisposed, isFalse);
      expect(
        resources.diagnostics.single.cause,
        WorkspaceResourceCause.memoryPressure,
      );
      resources.release(painter);
      await resources.settled;
      expect(firstA.debugDisposed, isTrue);
      expect(resources.images.keys, ['b']);
      resources.setActiveMap(mapA);
      await resources.settled;
      expect(resources.images.keys, ['a']);
      expect(resources.images['a'], isNot(same(firstA)));
      expect(resources.store.evictions, 2);
      expect(resources.store.decoder.decodes, 3);
      expect(resources.decodedBytes, fixture.decodedAtlasBytes);
      expect(resources.diagnostics, isEmpty);
    },
  );

  test(
    'same source shares concurrent load, transparency variants remain distinct',
    () async {
      final color = TilesetTransparentColor(red: 104, green: 158, blue: 96);
      final manifest = fixture.manifest.copyWith(
        tilesets: [
          const ProjectTilesetEntry(
            id: 'a',
            name: 'A',
            relativePath: 'assets/atelier.png',
          ),
          const ProjectTilesetEntry(
            id: 'alias',
            name: 'Alias',
            relativePath: 'assets/atelier.png',
          ),
          ProjectTilesetEntry(
            id: 'alpha',
            name: 'Alpha',
            relativePath: 'assets/atelier.png',
            transparentColor: color,
          ),
        ],
      );
      final resources = await StudioMapResources.load(
        fixture.session,
        manifest,
      );
      addTearDown(resources.dispose);
      await Future.wait([
        resources.store.request('a'),
        resources.store.request('a'),
        resources.store.request('alias'),
        resources.store.request('alpha'),
      ]);
      expect(resources.store.decoder.decodes, 2);
      expect(resources.images['a'], same(resources.images['alias']));
      expect(resources.images['alpha'], isNot(same(resources.images['a'])));
      expect(resources.decodedBytes, 2 * fixture.decodedAtlasBytes);
    },
  );

  test(
    'missing and corrupt sources stay distinct, retry clears stale failure and notifies',
    () async {
      final resources = await StudioMapResources.load(
        fixture.session,
        fixture.manifest,
      );
      addTearDown(resources.dispose);
      var notifications = 0;
      resources.addListener(() => notifications++);
      await Future.wait([
        resources.store.request(stressIncidentId(0)),
        resources.store.request(stressIncidentId(1)),
        resources.store.request(stressIncidentId(2)),
      ]);
      expect(resources.diagnostics.map((value) => value.cause).toSet(), {
        WorkspaceResourceCause.missing,
        WorkspaceResourceCause.decodeFailure,
        WorkspaceResourceCause.unsupported,
      });
      await fixture.makeMissingAvailable();
      final before = notifications;
      await resources.retryResources({stressIncidentId(0)});
      await Future<void>.delayed(Duration.zero);
      expect(resources.images, contains(stressIncidentId(0)));
      expect(
        resources.diagnostics.any(
          (value) => value.resourceId == stressIncidentId(0),
        ),
        isFalse,
      );
      expect(resources.diagnostics, hasLength(2));
      expect(notifications, greaterThan(before));
    },
  );

  test(
    'closing cancels queued work and disposes late result without notifying',
    () async {
      final entered = Completer<void>();
      final gate = Completer<void>();
      RuntimeTilesetImage? lateImage;
      final resources = await StudioMapResources.load(
        fixture.session,
        fixture.manifest,
        decode: (bytes, {transparentColor}) async {
          entered.complete();
          await gate.future;
          return lateImage = await decodeRuntimeTilesetImage(
            bytes,
            transparentColor: transparentColor,
          );
        },
      );
      var notifications = 0;
      resources.addListener(() => notifications++);
      final first = resources.store.request(fixture.lateAtlasId);
      final queued = resources.store.request(stressIncidentId(0));
      await entered.future;
      await resources.dispose();
      final before = notifications;
      gate.complete();
      await Future.wait([first, queued]);
      expect(lateImage!.debugDisposed, isTrue);
      expect(resources.images, isEmpty);
      expect(resources.store.decoder.reads, 1);
      expect(notifications, before);
    },
  );

  test(
    'explicit retry survives release of an unrelated palette lease',
    () async {
      final entered = Completer<void>();
      final gate = Completer<void>();
      final resources = await StudioMapResources.load(
        fixture.session,
        fixture.manifest,
        decode: (bytes, {transparentColor}) async {
          if (!entered.isCompleted) {
            entered.complete();
            await gate.future;
          }
          return decodeRuntimeTilesetImage(
            bytes,
            transparentColor: transparentColor,
          );
        },
      );
      addTearDown(resources.dispose);
      await resources.store.request(stressIncidentId(0));
      await fixture.makeMissingAvailable();
      final owner = Object();
      resources.retain(owner, {fixture.lateAtlasId});
      await entered.future;
      final retry = resources.retryResources({stressIncidentId(0)});
      resources.release(owner);
      gate.complete();
      await retry;
      expect(resources.images, contains(stressIncidentId(0)));
      expect(resources.diagnostics, isEmpty);
    },
  );
}
