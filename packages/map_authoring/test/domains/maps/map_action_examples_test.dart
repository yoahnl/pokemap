import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/maps/map3d_edit_projection.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../support/reliability_map_fixture.dart';
import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import 'border_spatial_actions_test.dart' show context;

void main() {
  final dispatcher=MapMutationDispatcher.canonical();
  for(final action in {...Map3dEditProjection.admittedActions,'map.create','smart_tile.layer.create'}) {
    test('$action published example passes its real canonical parser',() async {
      final f=ReliabilityMapContent.create(ReliabilityMapVariant.healthy);
      var map=f.map;
      var project=f.project;
      if(action=='map3d.terrain.surface.delete_batch') {
        final raw=(dispatcher.descriptor('map3d.terrain.surface.upsert_batch').extensions['inputExample'] as Map)['surfaces'] as List;
        map=const SpatialMapOperations().upsertTerrainSurfaces(map,
          [for(final value in raw) SpatialTerrainSurface.fromJson(Map<String,dynamic>.from(value as Map))]);
      }
      if(action=='border_layer.relink_apply'||action=='border_layer.feature_set_blueprint') {
        final raw=encodeBorderBlueprintRecordJson(project.borderCatalog.records.single,formatVersion:9);
        raw['id']='replacement';
        project=project.copyWith(borderCatalog:ProjectBorderCatalog(formatVersion:9,
          records:[...project.borderCatalog.records,decodeBorderBlueprintRecordJson(raw,formatVersion:9)]));
      }
      if(action.startsWith('border_layer.region_')) {
        map=updateBorderFeatureGeometry(map,layerId:'border',featureId:'fence',
          geometry:BorderRegionGeometry(width:24,height:16,cells:List.filled(384,false)));
      }
      final descriptor=dispatcher.descriptor(action);
      final example=Map<String,Object?>.from(descriptor.extensions['inputExample'] as Map);
      if(example['slotKey'] is String && (example['slotKey'] as String).startsWith('<')) {
        example['slotKey']=f.feature.materialization!.spatialPlacements.first.slotKey;
      }
      try {
        await dispatcher.build(context(librarySnapshot([map],project:project),action,example));
      } on MapAuthoringException catch(error) {
        expect(error.code,anyOf('map.no_change','border.no_change'),reason:'${error.code}: ${error.details}');
      }
    });
  }
}
