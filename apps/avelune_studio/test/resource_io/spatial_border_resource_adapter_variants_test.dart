import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:avelune_studio/features/resources/data/border_resource_sources.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_documents.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_border_fixture.dart';
import '../application/spatial_border_commands_test.dart' show borderDraft;
import 'resource_fixture.dart';

void main() {
  test(
    'model border settings reject unknown variants and unavailable clips',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'border_playback_invalid_',
      );
      addTearDown(() => directory.delete(recursive: true));
      for (final settings in [
        {'missing': const BorderModelSettings(blocksMovement: false)},
        {'south-cap': const BorderModelSettings(animationIndex: 0)},
        {'south-cap': const BorderModelSettings(animationSpeed: 0)},
        {'south-cap': const BorderModelSettings(animationSpeed: double.nan)},
      ]) {
        await expectLater(
          prepareBorderResources(
            manifest: spatialBorderVariantProject(),
            projectRoot: directory.path,
            request: BorderCreationRequest(
              name: 'Clôture',
              blueprintId: 'fence',
              primitiveModelSettings: settings,
            ),
          ),
          throwsA(isA<ResourceFailure>()),
        );
      }
    },
  );

  test('variant source replacement retains all other primitive metadata and rejects unknown or private sources', () async {
    final directory = await Directory.systemTemp.createTemp(
      'studio_border_variants_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final project = spatialBorderVariantProject();
    final original =
        project.borderCatalog.records.single.draft.definition.primitives;
    final request = BorderCreationRequest(
      blueprintId: 'fence',
      name: 'Clôture',
      primitiveModelIds: const {'south-cap': 'replacement'},
      straightOnly: true,
    );
    final prepared = await prepareBorderResources(
      manifest: project,
      projectRoot: directory.path,
      request: request,
    );
    expect(prepared, hasLength(3));
    expect(prepared[0].draft, same(original[0]));
    expect(prepared[1].draft, same(original[1]));
    final replaced = prepared[2].draft;
    expect(replaced.id, 'south-cap');
    expect(replaced.sourceModelId, 'replacement');
    expect(replaced.anchorWorld, original[2].anchorWorld);
    expect(replaced.authoredOrientation, original[2].authoredOrientation);
    expect(replaced.transforms, original[2].transforms);
    expect(replaced.weight, original[2].weight);
    await expectLater(
      prepareBorderResources(
        manifest: project,
        projectRoot: directory.path,
        request: const BorderCreationRequest(
          blueprintId: 'fence',
          name: 'Clôture',
          primitiveModelIds: {'missing': 'replacement'},
        ),
      ),
      throwsA(isA<ResourceFailure>()),
    );
    final private = project.copyWith(
      resourceLibraryCatalog: ResourceLibraryCatalog(
        entries: [
          ResourceLibraryEntry(
            resourceKind: 'model3d',
            resourceId: 'replacement',
            mapId: 'b',
          ),
        ],
      ),
    );
    await expectLater(
      prepareBorderResources(
        manifest: private,
        projectRoot: directory.path,
        request: request,
      ),
      throwsA(isA<ResourceFailure>()),
    );
  });
  test('Studio map save and reopen retain spatial border offset and native ownership', () async {
    final fixture = await ResourceFixture.create();
    addTearDown(fixture.dispose);
    final project = spatialBorderProject().copyWith(
      maps: [ResourceFixture.entry],
    );
    final map = spatialBorderMap().copyWith(id: ResourceFixture.entry.id);
    await fixture.manifestFile.writeAsString(jsonEncode(project.toJson()));
    await fixture.mapFile.writeAsBytes(encodeMapDocumentBytes(map));
    await fixture.maps.loadProject(fixture.session);
    final baseline = await fixture.loadMap();
    final document = EditableMapDocument(baseline);
    final commands = MapBorderEditingCommands(document, project);
    commands.finish(borderDraft(document.current, project));
    final layer = document.current.layers.whereType<BorderLayer>().single;
    final feature = layer.content.features.single;
    final offset = Model3dVector3(x: .25, y: 1.5, z: -.25);
    commands.setSpatialOffset(
      layerId: layer.id,
      featureId: feature.id,
      offset: offset,
      source: feature,
    );
    final source = document.current;
    final preview = commands.previewExisting(
      layerId: layer.id,
      featureId: feature.id,
    );
    commands.applyExisting(preview, source: source, sourceProject: project);
    await fixture.maps.saveMap(fixture.session, baseline, document.current);
    final reopened = LocalMapWorkspaceAdapter();
    await reopened.loadProject(fixture.session);
    final saved = await reopened.loadMap(
      fixture.session,
      ResourceFixture.entry,
    );
    expect(saved.map, document.current);
    final savedFeature = saved.map.layers
        .whereType<BorderLayer>()
        .single
        .content
        .features
        .single;
    expect(savedFeature.spatialOffsetWorld, offset);
    expect(
      savedFeature.generatedPlacementIds.toSet(),
      saved.map.spatialScene!.instances.map((instance) => instance.id).toSet(),
    );
    expect(
      diagnoseSpatialBorderFeature(
        manifest: project,
        map: saved.map,
        layerId: layer.id,
        featureId: feature.id,
      ).diagnostics,
      isEmpty,
    );
  });
}
