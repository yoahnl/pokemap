import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';

void main() {

  test('catalogue keeps 2D and spatial environments eligible only in their dimension', () {
    final spatial = spatialEnvironmentProject();
    final item = resourceCatalog(spatial)
        .firstWhere((item) => item.environment != null);
    expect(item.compatibleWith(ProjectDimension.threeD), isTrue);
    expect(item.compatibleWith(ProjectDimension.twoD), isFalse);
    final model = resourceCatalog(spatial)
        .firstWhere((item) => item.model3d != null);
    expect(model.usages, contains(ResourceCatalogUsage.scatter));
    final planar = ResourceItem(
      id: 'flowers',
      name: 'Fleurs',
      kind: ResourceKind.decors,
      environment: EnvironmentPreset(
        id: 'flowers',
        name: 'Fleurs',
        templateId: 'manual',
        sortOrder: 0,
        palette: [EnvironmentPaletteItem(elementId: 'tree', weight: 1)],
        defaultParams: EnvironmentGenerationParams.standard(),
      ),
    );
    expect(planar.compatibleWith(ProjectDimension.threeD), isFalse);
    expect(planar.compatibleWith(ProjectDimension.twoD), isTrue);
  });
}
