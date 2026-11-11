import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_border_fixture.dart';

void main() {
  test('a border sheet names its own pieces apart from free decors', () {
    final base = spatialBorderProject();
    final project = base.copyWith(
      models3d: [
        ...base.models3d,
        ProjectModel3dEntry(
          id: 'lamp',
          name: 'Lampadaire',
          sourceAssetId: 'lamp-source',
          relativePath: 'assets/models3d/lamp.glb',
          inspection: base.models3d.single.inspection,
        ),
      ],
    );
    final catalog = resourceCatalog(project);
    final border = catalog.firstWhere((item) => item.border != null).border!;
    expect(borderPieceIdentities(border), {'model3d:oak'});
    expect(
      owningBorderNames(
        project,
        catalog.firstWhere((item) => item.model3d?.id == 'oak'),
      ),
      ['Clôture unitaire'],
    );
    expect(
      owningBorderNames(
        project,
        catalog.firstWhere((item) => item.model3d?.id == 'lamp'),
      ),
      isEmpty,
    );
    expect(
      owningBorderNames(
        project,
        catalog.firstWhere((item) => item.border != null),
      ),
      isEmpty,
    );
  });

  test('a deprecated border no longer claims its pieces', () {
    final base = spatialBorderProject();
    final record = base.borderCatalog.records.single;
    final project = base.copyWith(
      borderCatalog: ProjectBorderCatalog(
        formatVersion: base.borderCatalog.formatVersion,
        visualSnapshots: base.borderCatalog.visualSnapshots,
        records: [
          BorderBlueprintRecord(
            id: record.id,
            draft: record.draft,
            latestPublished: record.latestPublished,
            isDeprecated: true,
          ),
        ],
      ),
    );
    final oak = resourceCatalog(
      project,
    ).firstWhere((item) => item.model3d?.id == 'oak');
    expect(owningBorderNames(project, oak), isEmpty);
    expect(borderPieceIdentities(project.borderCatalog.records.single), {
      'model3d:oak',
    });
  });
}
