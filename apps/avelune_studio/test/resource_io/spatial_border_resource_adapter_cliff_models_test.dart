import 'dart:io';

import 'package:avelune_studio/features/resources/data/border_resource_sources.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_border_fixture.dart';

void main() {
  test(
    'changing a cliff model or playback keeps its directed corner shape',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'border_cliff_edit_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final base = spatialBorderProject();
      final raw = encodeBorderBlueprintRecordJson(
        base.borderCatalog.records.single,
        formatVersion: 5,
      );
      final definition = (raw['draft'] as Map)['definition'] as Map;
      definition['followContourDirection'] = true;
      final primitives = definition['primitives'] as List;
      final corner = primitives.cast<Map>().singleWhere(
        (p) => p['role'] == 'lineCorner',
      );
      corner['cornerTurn'] = 'right';
      primitives.add({...corner, 'id': 'lineCornerLeft', 'cornerTurn': 'left'});
      final project = base.copyWith(
        borderCatalog: ProjectBorderCatalog(
          formatVersion: 5,
          records: [decodeBorderBlueprintRecordJson(raw, formatVersion: 5)],
        ),
        models3d: [
          ...base.models3d,
          ProjectModel3dEntry(
            id: 'replacement',
            name: 'Nouvel angle',
            sourceAssetId: 'replacement-source',
            relativePath: 'assets/models3d/replacement.glb',
            inspection: base.models3d.single.inspection,
          ),
        ],
      );
      final prepared = await prepareBorderResources(
        manifest: project,
        projectRoot: directory.path,
        request: const BorderCreationRequest(
          name: 'Falaise',
          blueprintId: 'fence',
          primitiveModelIds: {'lineCorner': 'replacement'},
          primitiveModelSettings: {
            'lineCornerLeft': BorderModelSettings(blocksMovement: false),
          },
        ),
      );
      final corners = prepared.where(
        (p) => p.draft.role == BorderPrimitiveRole.lineCorner,
      );
      expect(
        corners.map((p) => p.draft.cornerTurn).toSet(),
        BorderCornerTurn.values.toSet(),
      );
      expect(
        corners
            .singleWhere((p) => p.draft.cornerTurn == BorderCornerTurn.right)
            .draft
            .sourceModelId,
        'replacement',
      );
      expect(
        corners
            .singleWhere((p) => p.draft.cornerTurn == BorderCornerTurn.left)
            .draft
            .blocksMovement,
        isFalse,
      );
    },
  );

  test('model replacement preserves existing playback or refuses an incompatible animation', () async {
    final directory = await Directory.systemTemp.createTemp(
      'border_existing_playback_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final base = spatialBorderVariantProject();
    final encoded = encodeBorderBlueprintRecordJson(
      base.borderCatalog.records.single,
      formatVersion: 5,
    );
    final definition = (encoded['draft'] as Map)['definition'] as Map;
    final primitive = (definition['primitives'] as List)
        .cast<Map>()
        .singleWhere((value) => value['id'] == 'south-cap');
    primitive.addAll(<String, Object?>{
      'animationIndex': 0,
      'animationLoop': false,
      'animationSpeed': .5,
      'blocksMovement': false,
    });
    ProjectManifest project(bool replacementAnimated) => base.copyWith(
      borderCatalog: ProjectBorderCatalog(
        formatVersion: 5,
        records: [decodeBorderBlueprintRecordJson(encoded, formatVersion: 5)],
      ),
      models3d: [
        for (final model in base.models3d)
          ProjectModel3dEntry.fromJson({
            ...model.toJson(),
            'inspection': {
              ...model.inspection.toJson(),
              'animations': [
                if (model.id == 'oak' || replacementAnimated)
                  {'index': 0, 'name': 'Eau', 'durationSeconds': 2.0},
              ],
            },
          }),
      ],
    );
    const request = BorderCreationRequest(
      name: 'Clôture',
      blueprintId: 'fence',
      primitiveModelIds: {'south-cap': 'replacement'},
    );
    await expectLater(
      prepareBorderResources(
        manifest: project(false),
        projectRoot: directory.path,
        request: request,
      ),
      throwsA(isA<ResourceFailure>()),
    );
    final prepared = await prepareBorderResources(
      manifest: project(true),
      projectRoot: directory.path,
      request: request,
    );
    final replaced = prepared
        .singleWhere((value) => value.draft.id == 'south-cap')
        .draft;
    expect(replaced.animationIndex, 0);
    expect(replaced.animationLoop, false);
    expect(replaced.animationSpeed, .5);
    expect(replaced.blocksMovement, false);
    final cleared = await prepareBorderResources(
      manifest: project(false),
      projectRoot: directory.path,
      request: const BorderCreationRequest(
        name: 'Clôture',
        blueprintId: 'fence',
        primitiveModelIds: {'south-cap': 'replacement'},
        primitiveModelSettings: {
          'south-cap': BorderModelSettings(
            animationLoop: false,
            animationSpeed: .5,
            blocksMovement: false,
          ),
        },
      ),
    );
    expect(
      cleared
          .singleWhere((value) => value.draft.id == 'south-cap')
          .draft
          .animationIndex,
      isNull,
    );
  });

  test(
    'model border settings are explicit and isolated to the selected variant',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'border_playback_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final base = spatialBorderVariantProject();
      final project = base.copyWith(
        models3d: [
          for (final model in base.models3d)
            ProjectModel3dEntry.fromJson({
              ...model.toJson(),
              'inspection': {
                ...model.inspection.toJson(),
                'animations': [
                  {'index': 0, 'name': 'Eau', 'durationSeconds': 2.0},
                ],
              },
            }),
        ],
      );
      final prepared = await prepareBorderResources(
        manifest: project,
        projectRoot: directory.path,
        request: const BorderCreationRequest(
          name: 'Clôture',
          blueprintId: 'fence',
          primitiveModelIds: {'south-cap': 'replacement'},
          primitiveModelSettings: {
            'south-cap': BorderModelSettings(
              animationIndex: 0,
              animationLoop: false,
              animationSpeed: .5,
              blocksMovement: false,
            ),
          },
        ),
      );
      final encoded = encodeBorderBlueprintRecordJson(
        BorderBlueprintRecord(
          id: 'test',
          draft: BorderBlueprintDraft(
            baseRevision: 0,
            definition: BorderBlueprintDraftDefinition(
              name: 'Test',
              previewSeed: BorderSignedInt64.fromInt(1),
              template: BorderBlueprintTemplate.connectedLine,
              straightOnly: true,
              defaults:
                  base.borderCatalog.records.single.draft.definition.defaults,
              sortOrder: 0,
              primitives: prepared.map((value) => value.draft).toList(),
            ),
          ),
        ),
        formatVersion: 5,
      );
      final definition = (encoded['draft'] as Map)['definition'] as Map;
      final primitives = (definition['primitives'] as List).cast<Map>();
      final selected = primitives.singleWhere(
        (value) => value['id'] == 'south-cap',
      );
      expect(selected['animationIndex'], 0);
      expect(selected['animationLoop'], false);
      expect(selected['animationSpeed'], .5);
      expect(selected['blocksMovement'], false);
      for (final primitive in primitives.where(
        (value) => value['id'] != 'south-cap',
      )) {
        expect(primitive['animationIndex'], isNull);
        expect(primitive['blocksMovement'] ?? true, isTrue);
      }
    },
  );
}
