import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('diagnoseEventSceneLinks', () {
    test('does not report pages without scene target', () {
      final report = diagnoseEventSceneLinks(
        project: _projectWithScenes([_validScene('scene_intro')]),
        maps: [
          _mapWithPage(const MapEventPage(pageNumber: 0)),
        ],
      );

      expect(report.diagnostics, isEmpty);
      expect(report.hasErrors, isFalse);
    });

    test('accepts a scene target referencing an existing scene', () {
      final report = diagnoseEventSceneLinks(
        project: _projectWithScenes([_validScene('scene_intro')]),
        maps: [
          _mapWithPage(
            const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_intro'),
            ),
          ),
        ],
      );

      expect(report.diagnostics, isEmpty);
    });

    test('reports missing and empty scene targets as errors', () {
      final report = diagnoseEventSceneLinks(
        project: _projectWithScenes([]),
        maps: [
          _mapWithPage(
            const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'missing_scene'),
            ),
          ),
          _mapWithPage(
            const MapEventPage(
              pageNumber: 1,
              sceneTarget: MapEventSceneTarget(sceneId: ''),
            ),
            eventId: 'event_empty',
          ),
        ],
      );

      expect(report.hasErrors, isTrue);
      expect(
        report.byCode(EventSceneLinkDiagnosticCode.eventSceneTargetUnknown),
        hasLength(1),
      );
      expect(
        report.byCode(EventSceneLinkDiagnosticCode.eventSceneTargetEmpty),
        hasLength(1),
      );
    });

    test('warns when a disabled page targets a scene', () {
      final report = diagnoseEventSceneLinks(
        project: _projectWithScenes([_validScene('scene_intro')]),
        maps: [
          _mapWithPage(
            const MapEventPage(
              pageNumber: 0,
              isDisabled: true,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_intro'),
            ),
          ),
        ],
      );

      final diagnostic = report
          .byCode(
            EventSceneLinkDiagnosticCode.eventSceneTargetDisabledPage,
          )
          .single;
      expect(diagnostic.severity, EventSceneLinkDiagnosticSeverity.warning);
      expect(report.hasErrors, isFalse);
    });

    test('warns when the target scene has scene diagnostics errors', () {
      final report = diagnoseEventSceneLinks(
        project: _projectWithScenes([_invalidScene('scene_broken')]),
        maps: [
          _mapWithPage(
            const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_broken'),
            ),
          ),
        ],
      );

      final diagnostic = report
          .byCode(
            EventSceneLinkDiagnosticCode.eventSceneTargetSceneHasErrors,
          )
          .single;
      expect(diagnostic.severity, EventSceneLinkDiagnosticSeverity.warning);
      expect(report.hasErrors, isFalse);
    });
  });
}

MapData _mapWithPage(MapEventPage page, {String eventId = 'event_gate'}) {
  return MapData(
    id: 'map_test',
    name: 'Test Map',
    size: const GridSize(width: 8, height: 8),
    layers: [
      MapLayer.tile(
        id: 'l_base',
        name: 'Base',
        tiles: List<int>.filled(64, 0),
      ),
    ],
    events: [
      MapEventDefinition(
        id: eventId,
        title: 'Gate',
        position: const EventPosition(layerId: 'l_base', x: 2, y: 2),
        pages: [page],
      ),
    ],
  );
}

ProjectManifest _projectWithScenes(List<SceneAsset> scenes) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    scenes: scenes,
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

SceneAsset _validScene(String id) {
  return SceneAsset(
    id: id,
    name: 'Intro Scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_end',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}

SceneAsset _invalidScene(String id) {
  return SceneAsset(
    id: id,
    name: 'Broken Scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
      ],
    ),
  );
}
