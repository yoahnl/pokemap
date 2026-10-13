import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_documents.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_authoring/test/support/glb_fixture.dart';
import '../support/spatial_border_fixture.dart';
import 'resource_fixture.dart';

void main() {
  test(
    'resource edits retain the existing Border jump property after reopening',
    () async {
      final fixture = await ResourceFixture.create();
      addTearDown(fixture.dispose);
      final project = ProjectManifest(
        name: 'Border jump preservation',
        version: ProjectVersion.v9,
        settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
        maps: [ResourceFixture.entry],
        tilesets: [],
      );
      await fixture.manifestFile.writeAsString(jsonEncode(project.toJson()));
      await fixture.mapFile.writeAsBytes(
        encodeMapDocumentBytes(spatialBorderMap().copyWith(id: 'garden')),
      );
      await fixture.maps.loadProject(fixture.session);
      final modelFile = File('${fixture.root.path}/ledge.glb');
      await modelFile.writeAsBytes(triangleGlb());
      final imported = await fixture.resources.importModel(
        sourcePath: modelFile.path,
        name: 'Ledge',
      );
      final modelId = imported.manifest.models3d.single.id;
      final created = await fixture.resources.createBorder(
        BorderCreationRequest(
          blueprintId: 'jump-ledge',
          name: 'Ledge',
          capModelId: modelId,
          straightModelId: modelId,
          cornerModelId: modelId,
        ),
      );
      final jump = BorderJumpBehavior(
        side: BorderLineSide.inverted,
        durationMs: 750,
        peakHeightPx: 36,
      );
      final wire = encodeBorderBlueprintRecordJson(
        created.manifest.borderCatalog.records.single,
        formatVersion: 6,
      );
      for (final branch in ['draft', 'latestPublished']) {
        ((wire[branch] as Map)['definition'] as Map)['jumpBehavior'] = jump
            .toJson();
      }
      final prepared = created.manifest.copyWith(
        borderCatalog: ProjectBorderCatalog(
          formatVersion: 6,
          records: [decodeBorderBlueprintRecordJson(wire, formatVersion: 6)],
        ),
      );
      await fixture.manifestFile.writeAsString(jsonEncode(prepared.toJson()));
      await fixture.maps.loadProject(fixture.session);
      final mapBefore = await fixture.mapFile.readAsBytes();
      final renamed = await fixture.resources.createBorder(
        const BorderCreationRequest(
          blueprintId: 'jump-ledge',
          name: 'Renamed ledge',
        ),
      );
      final record = renamed.manifest.borderCatalog.records.single;
      expect(record.draft.definition.jumpBehavior, jump);
      expect(record.latestPublished!.definition.jumpBehavior, jump);
      expect(record.latestPublished!.definition.name, 'Renamed ledge');
      final reopened = await fixture.maps.loadProject(fixture.session);
      expect(reopened.borderCatalog.records.single, record);
      expect(await fixture.mapFile.readAsBytes(), mapBefore);
    },
  );
}
