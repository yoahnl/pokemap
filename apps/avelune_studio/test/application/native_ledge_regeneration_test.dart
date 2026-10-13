import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../resource_io/ledge_border_metadata_test.dart'
    show NativeLedgeResourceFixture;

void main() {
  test('republishing a ledge requires explicit regeneration retaining authored intent', () async {
    final fixture = await NativeLedgeResourceFixture.create();
    addTearDown(fixture.dispose);
    final base = await fixture.base.loadMap();
    final map = nativeLedgeMap(base.map, fixture.project);
    await fixture.maps.saveMap(fixture.session, base, map);
    final saved = await fixture.base.loadMap();
    final mapBefore = await fixture.mapFile.readAsBytes();
    final receipt = await fixture.resources.createBorder(
      BorderCreationRequest(
        blueprintId: fixture.record.id,
        name: 'Rebords republiés',
        jumpSide: BorderLineSide.inverted,
        expectedRecord: fixture.record,
      ),
    );
    expect(await fixture.mapFile.readAsBytes(), mapBefore);
    final old = nativeLedgeFeature(map);
    expect(
      () => bindMaterializedBorderJumpFaces(
        map: map,
        project: receipt.manifest,
        tileSize: const PixelSize(width: 32, height: 32),
      ),
      throwsA(isA<ValidationException>()),
    );
    final document = EditableMapDocument(saved);
    final commands = MapBorderEditingCommands(document, receipt.manifest);
    final preview = commands.previewExisting(
      layerId: 'rebords',
      featureId: 'route-rebord',
    );
    expect(document.current, same(saved.map));
    expect(document.undoCount, 0);
    expect(await fixture.mapFile.readAsBytes(), mapBefore);
    final updated = nativeLedgeFeature(preview);
    expect(updated.id, old.id);
    expect(updated.name, old.name);
    expect(updated.geometry, old.geometry);
    expect(updated.seed, old.seed);
    expect(updated.lineSide, old.lineSide);
    expect(updated.paramsOverride, old.paramsOverride);
    expect(updated.overrides, old.overrides);
    expect(updated.keepOutRegions, old.keepOutRegions);
    expect(
      updated.materialization!.placements,
      old.materialization!.placements,
    );
    expect(updated.materialization!.receipt.blueprintRevision, 2);
    final bindings = bindMaterializedBorderJumpFaces(
      map: preview,
      project: receipt.manifest,
      tileSize: const PixelSize(width: 32, height: 32),
    );
    expect(bindings, hasLength(2));
    expect(
      bindings.every((b) => b.allowedDirection == Direction.north),
      isTrue,
    );
    commands.applyExisting(
      preview,
      source: saved.map,
      sourceProject: receipt.manifest,
    );
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(document.current, saved.map);
    document.restore(redo: true);
    expect(document.current, preview);
    await fixture.maps.saveMap(fixture.session, saved, document.current);
    final reopened = await fixture.base.loadMap();
    final reopenedProject = await fixture.maps.loadProject(fixture.session);
    expect(reopened.map, preview);
    expect(reopenedProject, receipt.manifest);
    expect(
      bindMaterializedBorderJumpFaces(
        map: reopened.map,
        project: reopenedProject,
        tileSize: const PixelSize(width: 32, height: 32),
      ),
      hasLength(2),
    );
  });

  test(
    'a regeneration preview cannot overwrite an intervening map edit',
    () async {
      final fixture = await NativeLedgeResourceFixture.create();
      addTearDown(fixture.dispose);
      final base = await fixture.base.loadMap();
      final map = nativeLedgeMap(base.map, fixture.project);
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, revision: 'r0', mapId: map.id),
      );
      final commands = MapBorderEditingCommands(document, fixture.project);
      final preview = commands.previewExisting(
        layerId: 'rebords',
        featureId: 'route-rebord',
      );
      document.commit(map.copyWith(name: 'Modification intermédiaire'));
      final changed = document.current;
      expect(
        () => commands.applyExisting(
          preview,
          source: map,
          sourceProject: fixture.project,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(document.current, same(changed));
      expect(document.undoCount, 1);
    },
  );
  test('an existing deprecated ledge can be republished and explicitly regenerated', () async {
    final fixture = await NativeLedgeResourceFixture.create(isDeprecated: true);
    addTearDown(fixture.dispose);
    final base = await fixture.base.loadMap();
    final map = nativeLedgeMap(base.map, fixture.project);
    final receipt = await fixture.resources.createBorder(
      BorderCreationRequest(
        blueprintId: fixture.record.id,
        name: 'Ancien rebord republié',
        expectedRecord: fixture.record,
        jumpSide: BorderLineSide.inverted,
      ),
    );
    expect(receipt.manifest.borderCatalog.records.single.isDeprecated, isTrue);
    expect(MapBorderEditingCommands.publishedLines(receipt.manifest), isEmpty);
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, revision: 'r0', mapId: map.id),
    );
    final commands = MapBorderEditingCommands(document, receipt.manifest);
    final preview = commands.previewExisting(
      layerId: 'rebords',
      featureId: 'route-rebord',
    );
    expect(
      nativeLedgeFeature(preview).materialization!.receipt.blueprintRevision,
      2,
    );
    expect(
      nativeLedgeFeature(preview).overrides,
      nativeLedgeFeature(map).overrides,
    );
    expect(
      bindMaterializedBorderJumpFaces(
        map: preview,
        project: receipt.manifest,
        tileSize: const PixelSize(width: 32, height: 32),
      ),
      hasLength(2),
    );
    expect(document.current, same(map));
    expect(document.undoCount, 0);
    commands.applyExisting(
      preview,
      source: map,
      sourceProject: receipt.manifest,
    );
    expect(document.undoCount, 1);
  });
}

BorderFeature nativeLedgeFeature(MapData map) =>
    map.layers.whereType<BorderLayer>().single.content.features.single;

MapData nativeLedgeMap(MapData map, ProjectManifest project) {
  final feature = BorderFeature(
    id: 'route-rebord',
    name: 'Tracé conservé',
    blueprintId: 'native-ledges',
    seed: BorderSignedInt64.fromInt(42),
    geometry: BorderStrokeGeometry(
      alignment: BorderStrokeAlignment.gridEdges,
      strokes: [
        BorderStroke(
          id: 'ligne-native',
          closed: false,
          points: const [
            GridPos(x: 1, y: 2),
            GridPos(x: 2, y: 2),
            GridPos(x: 3, y: 2),
          ],
        ),
      ],
    ),
    lineSide: BorderLineSide.primary,
    paramsOverride: project
        .borderCatalog
        .records
        .single
        .latestPublished!
        .definition
        .defaults,
    overrides: const [],
    keepOutRegions: [
      BorderKeepOutRegion(
        id: 'espace-conservé',
        region: BorderRegionGeometry(
          width: 4,
          height: 4,
          cells: [true, ...List.filled(15, false)],
        ),
      ),
    ],
  );
  var result = upsertBorderFeature(
    addBorderLayer(map, id: 'rebords', name: 'Rebords'),
    layerId: 'rebords',
    feature: feature,
    template: BorderBlueprintTemplate.ledgeLine,
  );
  BorderResolutionRequest requestFor(BorderFeature current) =>
      BorderResolutionRequest(
        mapSize: map.size,
        tileSizePx: const GridSize(width: 32, height: 32),
        blueprintId: current.blueprintId,
        blueprintRevision: project.borderCatalog.records.single.latestPublished,
        feature: current,
        visualSnapshots: project.borderCatalog.visualSnapshots,
        resolverVersion: borderResolverVersion,
      );
  final first = resolveBorderFeature(requestFor(feature));
  expect(first.canApply, isTrue);
  final placements = first.materialization!.placements;
  result = updateBorderFeatureOverrides(
    result,
    layerId: 'rebords',
    featureId: feature.id,
    overrides: [
      BorderSlotOverride(
        slotKey: placements.first.slotKey,
        variationSalt: BorderSignedInt64.zero,
        suppressed: false,
        locked: false,
        replacementPrimitiveId: 'native-variant-0',
      ),
      BorderSlotOverride(
        slotKey: placements.last.slotKey,
        variationSalt: BorderSignedInt64.zero,
        suppressed: false,
        locked: true,
        lockedPlacement: placements.last,
      ),
    ],
  );
  final current = nativeLedgeFeature(result);
  final request = requestFor(current);
  final resolved = resolveBorderFeature(request);
  expect(resolved.canApply, isTrue);
  return applyBorderFeaturePreview(
    result,
    expectedMapId: map.id,
    layerId: 'rebords',
    featureId: current.id,
    expectedBaseFeatureFingerprint: computeBorderFeatureEditFingerprint(
      current,
    ),
    proposedRequest: request,
    proposedResult: resolved,
  );
}
