import 'dart:io';
import 'dart:convert';

import 'package:avelune_studio/features/resources/data/border_resource_sources.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';

import '../support/spatial_border_fixture.dart';
import 'resource_fixture.dart';
import '../../../../packages/map_authoring/test/support/glb_fixture.dart';

void main() {
  for (final straightOnly in [true, false]) {
    test(
      'Studio creates publishes and reopens every step of a new model border (straight: $straightOnly)',
      () async {
        final fixture = await ResourceFixture.create();
        addTearDown(fixture.dispose);
        await fixture.manifestFile.writeAsString(
          jsonEncode(
            ProjectManifest(
              name: 'Motif',
              version: ProjectVersion.v9,
              maps: [],
              tilesets: [],
              settings: ProjectSettings(
                dimension: ProjectDimension.threeD,
                spatialCamera: SpatialCameraProfile(),
              ),
            ).toJson(),
          ),
        );
        await fixture.maps.loadProject(fixture.session);
        final file = File('${fixture.root.path}/piece.glb');
        await file.writeAsBytes(triangleGlb());
        final imported = await fixture.resources.importModel(
          sourcePath: file.path,
          name: 'Pièce',
        );
        final modelId = imported.manifest.models3d.single.id;
        final drafted = await fixture.resources.createBorder(
          BorderCreationRequest(
            name: 'Trois étapes',
            blueprintId: 'sequence',
            straightOnly: straightOnly,
            followContourDirection: !straightOnly,
            sequenceLength: 3,
            capModelId: modelId,
            straightModelId: modelId,
            cornerModelId: straightOnly ? null : modelId,
            innerCornerModelId: straightOnly ? null : modelId,
            primitiveModelSettings: {
              if (!straightOnly)
                'lineCornerLeft': const BorderModelSettings(cornerJoinCells: 1),
            },
            publish: false,
          ),
        );
        expect(
          drafted
              .manifest
              .borderCatalog
              .records
              .single
              .draft
              .definition
              .sequenceLength,
          3,
        );
        final published = await fixture.resources.createBorder(
          const BorderCreationRequest(
            name: 'Trois étapes',
            blueprintId: 'sequence',
            publish: true,
          ),
        );
        final reopened = await LocalMapWorkspaceAdapter().loadProject(
          fixture.session,
        );
        final record = reopened.borderCatalog.records.single;
        expect(record, published.manifest.borderCatalog.records.single);
        expect(record.latestPublished!.definition.sequenceLength, 3);
        expect(
          record.latestPublished!.definition.primitives
              .map((p) => p.sequenceIndex)
              .toSet(),
          {0, 1, 2},
        );
        expect(
          record.latestPublished!.definition.primitives,
          hasLength(straightOnly ? 6 : 12),
        );
        expect(reopened.borderCatalog.formatVersion, straightOnly ? 12 : 13);
        if (!straightOnly) {
          expect(
            record.latestPublished!.definition.primitives
                .singleWhere((p) => p.id == 'lineCornerLeft')
                .cornerJoinCells,
            1,
          );
        }
        for (var step = 0; step < 3; step++) {
          final cap = record.latestPublished!.definition.primitives
              .where(
                (p) =>
                    p.sequenceIndex == step &&
                    p.role == BorderPrimitiveRole.lineCap,
              )
              .single;
          expect(cap.authoredOrientation, BorderPrimitiveOrientation.east);
          expect(cap.transforms.allowedQuarterTurns, [0, 1, 2, 3]);
        }
      },
    );
  }

  test('sequence editing rejects non-spatial requests', () async {
    final root = await Directory.systemTemp.createTemp(
      'studio_sequence_invalid_',
    );
    addTearDown(() => root.delete(recursive: true));
    final project = spatialBorderProject();
    for (final candidate in [
      project.copyWith(
        settings: const ProjectSettings(dimension: ProjectDimension.twoD),
      ),
    ]) {
      await expectLater(
        prepareBorderResources(
          manifest: candidate,
          projectRoot: root.path,
          request: const BorderCreationRequest(
            name: 'Invalide',
            blueprintId: 'fence',
            sequenceLength: 2,
          ),
        ),
        throwsA(isA<ResourceFailure>()),
      );
    }
  });

  test('changing one sequence source and settings retains every step and cap orientation', () async {
    final root = await Directory.systemTemp.createTemp(
      'studio_border_sequence_',
    );
    addTearDown(() => root.delete(recursive: true));
    final base = spatialBorderVariantProject();
    final raw = encodeBorderBlueprintRecordJson(
      base.borderCatalog.records.single,
      formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
    );
    final definition = (raw['draft'] as Map)['definition'] as Map;
    definition['sequenceLength'] = 3;
    final primitives = (definition['primitives'] as List).cast<Map>();
    definition['primitives'] = [
      for (var step = 0; step < 3; step++)
        for (final primitive in primitives)
          {
            ...primitive,
            'id': '${primitive['id']}-$step',
            'sequenceIndex': step,
          },
    ];
    final record = decodeBorderBlueprintRecordJson(
      raw,
      formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
    );
    final project = base.copyWith(
      borderCatalog: ProjectBorderCatalog(
        formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
        records: [record],
      ),
    );
    final result = await prepareBorderResources(
      manifest: project,
      projectRoot: root.path,
      request: const BorderCreationRequest(
        name: 'Clôture en séquence',
        blueprintId: 'fence',
        primitiveModelIds: {'south-cap-2': 'replacement'},
        primitiveModelSettings: {
          'north-cap-1': BorderModelSettings(blocksMovement: false),
        },
      ),
    );
    expect(result, hasLength(9));
    for (final item in result) {
      final before = record.draft.definition.primitives.singleWhere(
        (p) => p.id == item.draft.id,
      );
      expect(item.draft.sequenceIndex, before.sequenceIndex);
      expect(item.draft.authoredOrientation, before.authoredOrientation);
      expect(item.draft.anchorWorld, before.anchorWorld);
      expect(item.draft.transforms, before.transforms);
      expect(item.draft.weight, before.weight);
    }
    expect(
      result
          .singleWhere((p) => p.draft.id == 'south-cap-2')
          .draft
          .sourceModelId,
      'replacement',
    );
    expect(
      result
          .singleWhere((p) => p.draft.id == 'north-cap-1')
          .draft
          .blocksMovement,
      isFalse,
    );
    definition['sequenceLength'] = 65;
    final largeRecord = decodeBorderBlueprintRecordJson(
      raw,
      formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
    );
    final large = await prepareBorderResources(
      manifest: project.copyWith(
        borderCatalog: ProjectBorderCatalog(
          formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
          records: [largeRecord],
        ),
      ),
      projectRoot: root.path,
      request: const BorderCreationRequest(
        name: 'Motif importé conservé',
        blueprintId: 'fence',
      ),
    );
    expect(large.map((p) => p.draft), largeRecord.draft.definition.primitives);
  });
}
