import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_drawing_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import '../application/spatial_border_commands_test.dart'
    show borderDocument, borderDraft;
import '../support/spatial_border_fixture.dart';

void main() {
  test('a cliff drawing keeps the direction of the mouse gesture', () {
    final base = spatialBorderProject();
    final raw = encodeBorderBlueprintRecordJson(
      base.borderCatalog.records.single,
      formatVersion: 5,
    );
    for (final key in ['draft', 'latestPublished']) {
      final definition = (raw[key] as Map)['definition'] as Map;
      definition['followContourDirection'] = true;
    }
    final project = base.copyWith(
      borderCatalog: ProjectBorderCatalog(
        formatVersion: 5,
        records: [decodeBorderBlueprintRecordJson(raw, formatVersion: 5)],
      ),
    );
    final map = spatialBorderMap();
    final draft = MapBorderDrawingDraft.start(
      mapId: map.id,
      mapSize: map.size,
      blueprintId: project.borderCatalog.records.single.id,
      origin: const GridPos(x: 5, y: 2),
      sourceMap: map,
      sourceProject: project,
    ).addAngle(const GridPos(x: 2, y: 2));
    expect(draft.stroke.points.first, const GridPos(x: 5, y: 2));
    expect(draft.stroke.points.last, const GridPos(x: 2, y: 2));
  });

  test(
    'border altitude accepts French decimals before qualified regeneration',
    () {
      final project = spatialBorderProject();
      final map = spatialBorderMap();
      final document = borderDocument(map);
      final commands = MapBorderEditingCommands(document, project);
      commands.finish(borderDraft(map, project));
      final before = document.current;
      final feature = commands.visibleFeatures.single;
      final offset = MapBorderOffsetDraft(feature.feature.spatialOffsetWorld);
      offset.inputs['x'] = 'NaN';
      expect(offset.value, isNull);
      expect(document.current, same(before));
      offset.inputs.addAll({'x': '0,25', 'y': '1,5', 'z': '-0,25'});
      commands.setSpatialOffset(
        source: commands.visibleFeatures.single.feature,
        layerId: feature.layer.id,
        featureId: feature.feature.id,
        offset: offset.value,
      );
      final edited = document.current;
      expect(
        commands.visibleFeatures.single.feature.spatialOffsetWorld,
        Model3dVector3(x: .25, y: 1.5, z: -.25),
      );
      expect(edited.spatialScene, before.spatialScene);
      expect(
        commands
            .regenerationStatus(
              layerId: feature.layer.id,
              featureId: feature.feature.id,
            )
            .stale,
        isTrue,
      );
      final preview = commands.prepareExisting(
        layerId: feature.layer.id,
        featureId: feature.feature.id,
      );
      expect(document.current, same(edited));
      commands.applyRegeneration(preview);
      expect(
        document.current.spatialScene!.instances.first.position.y,
        closeTo(before.spatialScene!.instances.first.position.y + 1.5, 1e-9),
      );
      expect(
        commands.visibleFeatures.single.feature.spatialOffsetWorld,
        Model3dVector3(x: .25, y: 1.5, z: -.25),
      );
      commands.setSpatialOffset(
        source: commands.visibleFeatures.single.feature,
        layerId: feature.layer.id,
        featureId: feature.feature.id,
        offset: null,
      );
      expect(
        commands.visibleFeatures.single.feature.spatialOffsetWorld,
        isNull,
      );
    },
  );

  testWidgets(
    'border selection distinguishes identical feature ids in separate layers',
    (tester) async {
      final project = spatialBorderProject();
      final source = spatialBorderMap();
      final document = borderDocument(source);
      MapBorderEditingCommands(
        document,
        project,
      ).finish(borderDraft(source, project));
      final first = document.current.layers.whereType<BorderLayer>().single;
      var map = addBorderLayer(
        document.current,
        id: 'other-border',
        name: 'Deuxième clôture',
      );
      map = upsertBorderFeature(
        map,
        layerId: 'other-border',
        feature: BorderFeature(
          id: first.content.features.single.id,
          name: 'Deuxième clôture',
          blueprintId: 'fence',
          seed: BorderSignedInt64.zero,
          geometry: BorderStrokeGeometry(
            strokes: [
              BorderStroke(
                id: 'trait',
                points: const [
                  GridPos(x: 6, y: 2),
                  GridPos(x: 7, y: 2),
                  GridPos(x: 8, y: 2),
                ],
                closed: false,
              ),
            ],
          ),
          overrides: const [],
          keepOutRegions: const [],
        ),
        template: BorderBlueprintTemplate.connectedLine,
      );
      map = applySpatialBorderFeaturePreview(
        map,
        manifest: project,
        proposedResult: resolveSpatialBorderFeature(
          manifest: project,
          map: map,
          layerId: 'other-border',
          featureId: first.content.features.single.id,
        ),
      );
      document.commit(map);
      final view = MapEditingViewportSession();
      addTearDown(view.dispose);
      final commands = MapBorderEditingCommands(document, project);
      expect(
        commands.visibleFeatures
            .map((item) => (item.layer.id, item.feature.id))
            .toSet(),
        hasLength(2),
      );
      view.selectBorderFeature((
        layerId: 'other-border',
        featureId: first.content.features.single.id,
      ));
      view.borderPreview = commands.prepareExisting(
        layerId: view.borderFeature!.layerId,
        featureId: view.borderFeature!.featureId,
      );
      expect(view.borderPreview!.layerId, 'other-border');
      view.selectBorderFeature((
        layerId: first.id,
        featureId: first.content.features.single.id,
      ));
      expect(view.borderPreview, isNull);
    },
  );
}
