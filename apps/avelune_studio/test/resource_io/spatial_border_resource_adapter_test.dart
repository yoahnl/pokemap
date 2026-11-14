import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/data/border_resource_sources.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_documents.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_authoring/test/support/glb_fixture.dart';
import '../../../../packages/map_core/test/support/spatial_border_ground_surface_fixture.dart'
    as ground_fixture;
import '../support/spatial_border_fixture.dart';
import 'resource_fixture.dart';

void main() {
  for (final (label, settings, replaceModel) in [
    ('collision', const BorderModelSettings(blocksMovement: false), false),
    (
      'playback',
      const BorderModelSettings(animationLoop: false, animationSpeed: .5),
      false,
    ),
    ('unchanged settings', const BorderModelSettings(), false),
    ('model source', const BorderModelSettings(), true),
  ]) {
    test(
      'editing $label preserves the cliff ground of every variant',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'border_ground_edit_',
        );
        addTearDown(() => directory.delete(recursive: true));
        final base = ground_fixture.surfaceFixture().project;
        final raw = encodeBorderBlueprintRecordJson(
          base.borderCatalog.records.single,
          formatVersion: 9,
        );
        for (final section in ['draft', 'latestPublished']) {
          (raw[section] as Map)['definition']['replacesGround'] = true;
          for (final primitive
              in (raw[section] as Map)['definition']['primitives'] as List) {
            for (final surface in primitive['groundSurfaces'] as List) {
              surface['gradientX'] = .5;
              surface['gradientZ'] = -.25;
            }
            primitive['groundFootprints'] = [
              [
                {'x': -.2, 'z': -.2},
                {'x': .2, 'z': -.2},
                {'x': .2, 'z': .2},
                {'x': -.2, 'z': .2},
              ],
            ];
          }
        }
        final record = decodeBorderBlueprintRecordJson(raw, formatVersion: 10);
        final project = base.copyWith(
          borderCatalog: ProjectBorderCatalog(
            formatVersion: 10,
            records: [record],
          ),
          models3d: [
            ...base.models3d,
            if (replaceModel)
              ProjectModel3dEntry.fromJson({
                ...base.models3d.single.toJson(),
                'id': 'replacement',
                'sourceAssetId': 'replacement-source',
                'relativePath': 'assets/models3d/replacement.glb',
              }),
          ],
        );
        final prepared = await prepareBorderResources(
          manifest: project,
          projectRoot: directory.path,
          request: BorderCreationRequest(
            name: 'Falaise renommée',
            blueprintId: record.id,
            primitiveModelSettings: {'lineStraight': settings},
            primitiveModelIds: {
              if (replaceModel) 'lineStraight': 'replacement',
            },
          ),
        );
        for (final source in prepared) {
          final original = record.draft.definition.primitives.singleWhere(
            (primitive) => primitive.id == source.draft.id,
          );
          expect(source.draft.groundFootprints, original.groundFootprints);
          expect(source.draft.groundSurfaces, original.groundSurfaces);
          expect(
            source.draft.sourceModelId,
            replaceModel && source.draft.id == 'lineStraight'
                ? 'replacement'
                : original.sourceModelId,
          );
          if (source.draft.id == 'lineStraight') {
            expect(source.draft.blocksMovement, settings.blocksMovement);
            expect(source.draft.animationLoop, settings.animationLoop);
            expect(source.draft.animationSpeed, settings.animationSpeed);
          } else {
            expect(source.draft, original);
          }
        }
        expect(project.borderCatalog.records.single, record);
      },
    );
  }

  test('Studio creates publishes and reopens a directed cliff with distinct corners', () async {
    final fixture = await ResourceFixture.create();
    addTearDown(fixture.dispose);
    final project = ProjectManifest(
      name: 'Falaises',
      version: ProjectVersion.v9,
      settings: ProjectSettings(
        dimension: ProjectDimension.threeD,
        spatialCamera: SpatialCameraProfile(),
      ),
      maps: [ResourceFixture.entry],
      tilesets: [],
    );
    ProjectValidator.validate(project);
    await fixture.manifestFile.writeAsString(jsonEncode(project.toJson()));
    await fixture.mapFile.writeAsBytes(
      encodeMapDocumentBytes(spatialBorderMap().copyWith(id: 'garden')),
    );
    await fixture.maps.loadProject(fixture.session);
    final input = File('${fixture.root.path}/piece.glb');
    await input.writeAsBytes(triangleGlb());
    final imported = await fixture.resources.importModel(
      sourcePath: input.path,
      name: 'Profil de falaise',
    );
    final id = imported.manifest.models3d.single.id;
    final mapBefore = await fixture.mapFile.readAsBytes();
    final receipt = await fixture.resources.createBorder(
      BorderCreationRequest(
        blueprintId: 'native-cliff',
        name: 'Falaise',
        followContourDirection: true,
        replacesGround: true,
        groundBaseOffset: -.0625,
        capModelId: id,
        straightModelId: id,
        cornerModelId: id,
        innerCornerModelId: id,
      ),
    );
    final record = receipt.manifest.borderCatalog.records.single;
    final definition = record.latestPublished!.definition;
    expect(definition.followContourDirection, isTrue);
    expect(definition.replacesGround, isTrue);
    expect(definition.groundBaseOffset, -.0625);
    expect(definition.defaults.allowAutoRotation, isTrue);
    expect(
      definition.primitives
          .where((p) => p.role == BorderPrimitiveRole.lineCorner)
          .map((p) => p.cornerTurn)
          .toSet(),
      BorderCornerTurn.values.toSet(),
    );
    expect(await fixture.mapFile.readAsBytes(), mapBefore);
    expect(receipt.manifest.borderCatalog.visualSnapshots, isEmpty);
    final reopened = await LocalMapWorkspaceAdapter().loadProject(
      fixture.session,
    );
    expect(reopened.borderCatalog.records.single, record);
    final updated = await fixture.resources.createBorder(
      const BorderCreationRequest(
        blueprintId: 'native-cliff',
        name: 'Falaise modifiée',
        primitiveModelSettings: {
          'lineCornerLeft': BorderModelSettings(blocksMovement: false),
        },
      ),
    );
    final updatedDefinition = updated
        .manifest
        .borderCatalog
        .records
        .single
        .latestPublished!
        .definition;
    expect(updatedDefinition.followContourDirection, isTrue);
    expect(updatedDefinition.replacesGround, isTrue);
    expect(updatedDefinition.groundBaseOffset, -.0625);
    expect(
      updatedDefinition.primitives
          .singleWhere((p) => p.cornerTurn == BorderCornerTurn.left)
          .blocksMovement,
      isFalse,
    );
    expect(
      updatedDefinition.primitives
          .singleWhere((p) => p.cornerTurn == BorderCornerTurn.right)
          .blocksMovement,
      isTrue,
    );
    final masked = await fixture.resources.createBorder(
      const BorderCreationRequest(
        blueprintId: 'native-cliff',
        name: 'Muret au-dessus du sol',
        replacesGround: false,
        groundBaseOffset: 0,
        masksGroundCells: true,
      ),
    );
    expect(
      masked
          .manifest
          .borderCatalog
          .records
          .single
          .latestPublished!
          .definition
          .masksGroundCells,
      isTrue,
    );
    final maskedReopened = await LocalMapWorkspaceAdapter().loadProject(
      fixture.session,
    );
    expect(
      maskedReopened.borderCatalog.records.single,
      masked.manifest.borderCatalog.records.single,
    );
    final editedMasked = await fixture.resources.createBorder(
      const BorderCreationRequest(
        blueprintId: 'native-cliff',
        name: 'Muret renommé',
      ),
    );
    expect(
      editedMasked
          .manifest
          .borderCatalog
          .records
          .single
          .latestPublished!
          .definition
          .masksGroundCells,
      isTrue,
    );
    expect(await fixture.mapFile.readAsBytes(), mapBefore);
  });
}
