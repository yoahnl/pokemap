
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';

void main() {
  test('a duplicated 3D decor keeps its visibility condition', () {
    final condition = NarrativeEventConditionExpression.leaf(
      NarrativeEventCondition.fact('pont_repare', true),
    );
    final source = SpatialModelInstance(
      id: 'statue',
      modelId: 'oak',
      position: Model3dVector3(x: 2.5, y: 0, z: 2.5),
      visibilityCondition: condition,
    );
    final map = spatialEnvironmentMap();
    final document = EditableMapDocument(
      MapWorkspaceDocument(
        map: map.copyWith(
          spatialScene: map.spatialScene!.copyWith(instances: [source]),
        ),
        revision: 'base',
        mapId: map.id,
      ),
    );
    SpatialModelEditingCommands(
      document,
      spatialEnvironmentProject(),
    ).duplicate(source.id);
    final copy = document.current.spatialScene!.instances.singleWhere(
      (instance) => instance.id != source.id,
    );
    expect(copy.visibilityCondition, condition);
  });

}
