import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/editor_receipt_presenter.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import '../../../map_authoring/test/domains/maps/border_slot_override_actions_test.dart'
    show borderSlotOverrideFixture;

void main() {
  test(
    'editor authoring bridge plans exact slot fields and restores canonical materialization',
    () async {
      final fixture = borderSlotOverrideFixture(
        gapTolerancePx: 32,
        maxOverlapPx: 32,
        permissiveAlternateTransforms: true,
      );
      final layer = fixture.map.layers.whereType<BorderLayer>().single;
      final target = layer.content.features.first;
      final revision = fixture.project.borderCatalog
          .recordById(target.blueprintId)!
          .latestPublished!;
      var map = upsertBorderFeature(
        fixture.map,
        layerId: layer.id,
        feature: BorderFeature(
          id: 'untouched',
          name: 'Untouched',
          blueprintId: target.blueprintId,
          seed: BorderSignedInt64.fromInt(43),
          geometry: target.geometry,
          overrides: const [],
          keepOutRegions: const [],
        ),
        template: revision.definition.template,
      );
      final tileSize = GridSize(
        width: fixture.project.settings.tileWidth,
        height: fixture.project.settings.tileHeight,
      );
      for (final feature
          in (map.layers.whereType<BorderLayer>().single).content.features) {
        final request = BorderResolutionRequest(
          mapSize: map.size,
          tileSizePx: tileSize,
          blueprintId: target.blueprintId,
          blueprintRevision: revision,
          feature: feature,
          visualSnapshots: fixture.project.borderCatalog.visualSnapshots,
          resolverVersion: borderResolverVersion,
        );
        final resolved = resolveBorderFeature(request);
        expect(resolved.canApply, isTrue);
        map = applyBorderFeaturePreview(
          map,
          expectedMapId: map.id,
          layerId: layer.id,
          featureId: feature.id,
          expectedBaseFeatureFingerprint: computeBorderFeatureEditFingerprint(
            feature,
          ),
          proposedRequest: request,
          proposedResult: resolved,
        );
      }
      final root = await Directory.systemTemp.createTemp('border-slot-editor-');
      addTearDown(() => root.delete(recursive: true));
      final manifestFile = File('${root.path}/project.json');
      final mapFile = File(
        '${root.path}/${fixture.project.maps.single.relativePath}',
      );
      await mapFile.parent.create(recursive: true);
      await manifestFile.writeAsString(jsonEncode(fixture.project.toJson()));
      await mapFile.writeAsString(jsonEncode(map.toJson()));
      const reader = EditorProjectFileReader();
      final canonicalRoot = await reader.canonicalizeDirectory(root.path);
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final mutations = AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: reader,
      );
      await queries.retainOnly(canonicalRoot);
      await mutations.retainOnly(canonicalRoot);
      addTearDown(queries.closeAll);
      addTearDown(mutations.closeAll);
      MapData saved() => MapData.fromJson(
        jsonDecode(mapFile.readAsStringSync()) as Map<String, dynamic>,
      );
      BorderFeature selected([String? id]) => saved().layers
          .whereType<BorderLayer>()
          .single
          .content
          .featureById(id ?? target.id)!;
      final original = selected(), untouched = selected('untouched');
      final originalPlacements = original.materialization!.placements;
      final middle = originalPlacements.firstWhere(
        (placement) =>
            revision.definition.primitives
                .singleWhere(
                  (primitive) => primitive.id == placement.primitiveId,
                )
                .role ==
            BorderPrimitiveRole.lineStraight,
      );
      final replacement = revision.definition.primitives.firstWhere(
        (primitive) =>
            primitive.role == BorderPrimitiveRole.lineStraight &&
            primitive.id != middle.primitiveId,
      );
      final common = <String, Object?>{
        'mapId': map.id,
        'layerId': layer.id,
        'featureId': target.id,
        'slotKey': middle.slotKey,
      };
      final materialize = <String, Object?>{
        'mapId': map.id,
        'layerId': layer.id,
        'featureId': target.id,
        'tileWidthPx': tileSize.width,
        'tileHeightPx': tileSize.height,
        'resolverVersion': borderResolverVersion,
      };
      var sequence = 0;
      final manifestBytes = await manifestFile.readAsBytes();
      Future<EditorAuthoringMutationPlan> plan(
        String action,
        Map<String, Object?> parameters,
      ) async {
        final before = await mapFile.readAsBytes();
        final planned = await mutations.plan(
          canonicalRoot,
          actionId: action,
          parameters: parameters,
          idempotencyKey: 'slot-editor-${++sequence}',
        );
        expect(await mapFile.readAsBytes(), before);
        expect(await manifestFile.readAsBytes(), manifestBytes);
        return planned;
      }

      Future<void> mutate(
        String action,
        Map<String, Object?> parameters,
      ) async {
        final planned = await plan(action, parameters);
        final applied = await mutations.apply(
          planned,
          operationId: 'slot-editor-apply-${++sequence}',
        );
        expect(applied.receipt.actionId, action);
        expect(selected('untouched'), untouched);
        expect(await manifestFile.readAsBytes(), manifestBytes);
      }

      final invalidBefore = await mapFile.readAsBytes();
      for (final action in [
        (
          'border_layer.feature_set_replacement',
          {...common, 'primitiveId': 'unknown'},
        ),
        (
          'border_layer.feature_set_offset',
          {
            ...common,
            'slotKey': 'unknown',
            'offsetDeltaPx': {'x': 1, 'y': 2},
          },
        ),
        (
          'border_layer.feature_set_transform',
          {
            ...common,
            'transformOverride': {'quarterTurns': 4, 'flipX': false},
          },
        ),
      ]) {
        await expectLater(
          plan(action.$1, action.$2),
          throwsA(isA<EditorAuthoringMutationFailure>()),
        );
        expect(await mapFile.readAsBytes(), invalidBefore);
        expect(await manifestFile.readAsBytes(), manifestBytes);
      }
      final stale = await plan('border_layer.feature_set_suppressed', {
        ...common,
        'suppressed': true,
      });
      await mutate('border_layer.feature_set_replacement', {
        ...common,
        'primitiveId': replacement.id,
      });
      expect(selected().materialization, original.materialization);
      final editedRequest = BorderResolutionRequest(
        mapSize: map.size,
        tileSizePx: tileSize,
        blueprintId: target.blueprintId,
        blueprintRevision: revision,
        feature: selected(),
        visualSnapshots: fixture.project.borderCatalog.visualSnapshots,
        resolverVersion: borderResolverVersion,
      );
      final freshness = assessBorderMaterializationFreshness(
        editedRequest,
        materialization: selected().materialization,
        snapshotIntegrity: {
          for (final snapshot in fixture.project.borderCatalog.visualSnapshots)
            snapshot.id: BorderVisualSnapshotIntegrity(
              snapshotId: snapshot.id,
              metadataValid: true,
              filesPresent: true,
              contentFingerprintMatches: true,
            ),
        },
      );
      expect(
        freshness.reasons,
        contains(BorderStalenessReason.overridesChanged),
      );
      final beforeStale = await mapFile.readAsBytes();
      await expectLater(
        mutations.apply(stale, operationId: 'stale-slot-editor'),
        throwsA(
          isA<EditorAuthoringMutationFailure>().having(
            (error) => error.code,
            'revision conflict',
            'plan.stale',
          ),
        ),
      );
      expect(await mapFile.readAsBytes(), beforeStale);
      await mutate('border_layer.feature_set_offset', {
        ...common,
        'offsetDeltaPx': {'x': 1, 'y': 2},
      });
      await mutate('border_layer.feature_set_transform', {
        ...common,
        'transformOverride': {'quarterTurns': 1, 'flipX': true},
      });
      await mutate('border_layer.materialize_apply', materialize);
      final changed = selected();
      final override = changed.overrides.singleWhere(
        (value) => value.slotKey == middle.slotKey,
      );
      expect(override.replacementPrimitiveId, replacement.id);
      expect(override.offsetDeltaPx, const BorderPixelOffset(x: 1, y: 2));
      expect(
        override.transformOverride,
        BorderSpriteTransform(quarterTurns: 1, flipX: true),
      );
      final moved = changed.materialization!.placements.singleWhere(
        (value) => value.slotKey == middle.slotKey,
      );
      expect(moved.primitiveId, replacement.id);
      expect(moved.transform, override.transformOverride);
      expect(moved.topLeftWorldPx, isNot(middle.topLeftWorldPx));
      expect(
        changed.materialization!.receipt.inputFingerprint,
        isNot(original.materialization!.receipt.inputFingerprint),
      );
      await mutate('border_layer.feature_set_suppressed', {
        ...common,
        'suppressed': true,
      });
      await mutate('border_layer.materialize_apply', materialize);
      expect(
        selected().materialization!.placements.length,
        originalPlacements.length - 1,
      );
      await mutate('border_layer.feature_clear_slot_override', common);
      await mutate('border_layer.materialize_apply', materialize);
      expect(selected().overrides, isEmpty);
      expect(selected().materialization!.placements, originalPlacements);
      await mutations.closeAll();
      await queries.closeAll();
      expect(selected().materialization!.placements, originalPlacements);
      expect(selected('untouched'), untouched);
      expect(await manifestFile.readAsBytes(), manifestBytes);
    },
  );
}
