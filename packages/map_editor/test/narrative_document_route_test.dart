import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_document_route.dart';
import 'package:map_editor/src/infrastructure/repositories/file_narrative_document_route_store.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_navigation.dart';

void main() {
  group('NarrativeDocumentRouteCodec', () {
    test('roundtrips a Presentation deep link from its Library', () {
      final route = NarrativeDocumentRoute.presentation(
        cinematicId: 'opening_port',
        source: NarrativeLibrarySourceContext(
          library: NarrativeLibraryKind.cinematics,
          cinematicFamily: CinematicLibraryFamily.presentation,
          folderId: 'folder/openings',
          searchQuery: 'dragon du port',
          sort: NarrativeLibrarySort.updatedDescending,
          selectedAssetId: 'opening_port',
          scrollOffset: 412.5,
        ),
      );

      final uri = const NarrativeDocumentRouteCodec().encode(route);
      final decoded = const NarrativeDocumentRouteCodec().decode(uri);

      expect(decoded, route);
      expect(decoded.sessionDocumentId, 'presentationCinematic:opening_port');
      expect(uri.scheme, 'pokemap');
      expect(uri.host, 'editor');
    });

    test('roundtrips a Presentation deep link from an exact Scene context', () {
      final route = NarrativeDocumentRoute.presentation(
        cinematicId: 'opening_port',
        source: NarrativeSceneSourceContext(
          sceneId: 'scene_new_game',
          viewportX: -184.25,
          viewportY: 96.5,
          zoom: 1.35,
          selectedNodeId: 'node_presentation',
          inspector: NarrativeSceneInspector.properties,
        ),
      );

      expect(
        const NarrativeDocumentRouteCodec().decode(
          const NarrativeDocumentRouteCodec().encode(route),
        ),
        route,
      );
    });

    test('models Scene documents without a Map document identity', () {
      final route = NarrativeDocumentRoute.scene(
        sceneId: 'scene_new_game',
        source: NarrativeLibrarySourceContext(
          library: NarrativeLibraryKind.scenes,
          selectedAssetId: 'scene_new_game',
          scrollOffset: 80,
        ),
      );

      expect(route.kind, NarrativeDocumentKind.scene);
      expect(route.sessionDocumentId, 'scene:scene_new_game');
      expect(route.sessionDocumentId, isNot(startsWith('map:')));
    });

    test('fails closed on unknown route and source tokens', () {
      expect(
        () => const NarrativeDocumentRouteCodec().decode(
          Uri.parse(
            'pokemap://editor/narrative/world/opening?source=library'
            '&library=cinematics&family=presentation',
          ),
        ),
        throwsFormatException,
      );
      expect(
        () => const NarrativeDocumentRouteCodec().decode(
          Uri.parse(
            'pokemap://editor/narrative/presentation/opening?source=map',
          ),
        ),
        throwsFormatException,
      );
    });

    test('rejects a Presentation return to the in-game Library', () {
      expect(
        () => NarrativeDocumentRoute.presentation(
          cinematicId: 'opening',
          source: NarrativeLibrarySourceContext(
            library: NarrativeLibraryKind.cinematics,
            cinematicFamily: CinematicLibraryFamily.world,
          ),
        ),
        throwsArgumentError,
      );
    });
  });

  test(
    'file route store restores the full typed context after relaunch',
    () async {
      final root = await Directory.systemTemp.createTemp('narrative-route-');
      addTearDown(() => root.delete(recursive: true));
      final store = FileNarrativeDocumentRouteStore(
        filePath: '${root.path}/active-route.json',
      );
      final route = NarrativeDocumentRoute.presentation(
        cinematicId: 'opening',
        source: NarrativeSceneSourceContext(
          sceneId: 'scene_new_game',
          viewportX: 12,
          viewportY: 24,
          zoom: 1.5,
          selectedNodeId: 'node_presentation',
          inspector: NarrativeSceneInspector.properties,
        ),
      );

      await store.write(route);

      expect(
        await FileNarrativeDocumentRouteStore(
          filePath: '${root.path}/active-route.json',
        ).read(),
        route,
      );
      await store.clear();
      expect(await store.read(), isNull);
    },
  );

  test(
    'navigation restores a Presentation destination and its Scene source',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(narrativeStudioNavigationControllerProvider, (_, _) {});
      final controller = container.read(
        narrativeStudioNavigationControllerProvider.notifier,
      );
      final route = NarrativeDocumentRoute.presentation(
        cinematicId: 'opening',
        source: NarrativeSceneSourceContext(
          sceneId: 'scene_new_game',
          viewportX: 12,
          viewportY: 24,
          zoom: 1.5,
          selectedNodeId: 'node_presentation',
          inspector: NarrativeSceneInspector.properties,
        ),
      );

      controller.restoreDocumentDeepLink(
        const NarrativeDocumentRouteCodec().encode(route),
      );

      expect(
        container
            .read(narrativeStudioNavigationControllerProvider)
            .documentRoute,
        route,
      );
      expect(controller.closeDocument(), route.source);
      final restored = container.read(
        narrativeStudioNavigationControllerProvider,
      );
      expect(restored.documentRoute, isNull);
      expect(restored.location.selection?.assetId, 'scene_new_game');
      expect(restored.location.selection?.focusId, 'node_presentation');
    },
  );
}
