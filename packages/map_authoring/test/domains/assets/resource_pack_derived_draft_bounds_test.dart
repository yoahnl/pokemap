import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'resource_pack_export_test.dart' as source;
import 'resource_pack_import_fixture.dart';

void main() {
  for (final count in [28, 40]) {
    test(
        'published pack remains importable when derived draft exceeds ${count == 28 ? 'bytes' : 'values'}',
        () async {
      final manifest = _animated(count);
      final fixture = await NativeResourcePackImportFixture.create(
          sourceManifest: manifest,
          sourceFiles: [
            source.nativeImage()
          ],
          roots: [
            for (final preset in manifest.smartTileCatalog.presets)
              NativeResourcePackRef(
                  kind: ResourcePackKind.smartTilePreset, id: preset.id)
          ]);
      addTearDown(fixture.dispose);
      await _partition(fixture);
      final baseline = (await fixture.loader.load(fixture.opened.projectHandle))
          .manifest
          .toJson();
      final selected = await fixture.select(roots: [
        for (final preset in fixture
            .source.archive.inspection.catalog.smartTileCatalog.presets)
          ResourcePackRef(kind: ResourcePackKind.smartTilePreset, id: preset.id)
      ]);
      final prepared = await fixture.prepare(selection: selected);
      expect(prepared.status, ResourcePackPreparedImportStatus.ready);
      expect(prepared.review.summary['autoDraftSkippedCount'], 1);
      final notice = prepared.review.rows
          .singleWhere((row) => row['kind'] == 'authoringDraftNotice');
      expect(notice['reasonCode'], 'catalog_unit_too_large');
      expect(notice['message'], contains('brouillon'));
      late final AuthoringMutationResult applied;
      if (count == 28) {
        final worker =
            JsonlWorker(api: fixture.readApi, mutations: fixture.mutations);
        final result = AuthoringResult.fromJson(
            jsonDecode(await worker.processLine(jsonEncode({
          'id': 'draft-notice',
          'command': 'plan',
          'args': {
            'projectHandle': fixture.opened.projectHandle.value,
            'request': AuthoringRequest(
                requestId: 'draft-notice',
                actionId: 'resource_pack.import',
                actionVersion: 1,
                workspaceHandle: fixture.opened.workspaceHandle.value,
                expectedRevision:
                    (await fixture.loader.load(fixture.opened.projectHandle))
                        .revision,
                idempotencyKey: 'draft-notice',
                parameters: {
                  'preparedImportHandle': prepared.preparedImportHandle
                }).toJson()
          }
        }))) as Map<String, dynamic>);
        expect(result.status, AuthoringResultStatus.success);
        expect(
            ((result.data['plan'] as Map)['preview']
                as Map)['selectionSummary'],
            containsPair('autoDraftSkippedCount', 1));
        final planId = result.data['planId'] as String;
        final confirmed = await fixture.mutations
            .confirmMutation(fixture.opened.projectHandle, planId: planId);
        applied = await fixture.mutations.applyMutation(
            fixture.opened.projectHandle,
            planId: planId,
            operationId: 'jsonl-draft-import',
            confirmationToken: confirmed.confirmationToken);
      } else {
        final planned = await fixture.plan(prepared);
        expect(
            (planned.plan.preview['selectionSummary']
                as Map)['autoDraftSkippedCount'],
            1);
        applied = await fixture.apply(planned);
      }
      final snapshot = await fixture.loader.load(fixture.opened.projectHandle);
      final installed = snapshot.manifest;
      expect(installed.smartTileCatalog.presets, hasLength(2));
      expect(installed.smartTileCatalog.animations, hasLength(count));
      expect(
          installed.smartTileCatalog.animations
              .every((a) => a.frames.length == 360),
          isTrue);
      final large = installed.smartTileCatalog.presets
          .singleWhere((p) => p.name == 'Large');
      expect(
          installed.smartTileCatalog.drafts
              .any((d) => d.targetPresetId == large.id),
          isFalse);
      expect(notice['presetId'], large.id);
      expect(installed.smartTileCatalog.drafts, hasLength(1));
      final small = installed.smartTileCatalog.drafts.single;
      expect(
          compileSmartTileAuthoringDraft(
              draft: small,
              catalog: installed.smartTileCatalog,
              manifest: installed),
          isA<SmartTileDraftCompilationSuccess>());
      final derived = reconstructResourcePackSmartTileDraft(
          preset: large, catalog: installed.smartTileCatalog);
      if (count == 28) {
        expect(_values(derived.toJson()), lessThan(100000));
        expect(utf8.encode(jsonEncode(derived.toJson())).length,
            greaterThan(1048576));
      } else {
        expect(_values(derived.toJson()), greaterThan(100000));
      }
      final map = MapData(
          id: 'paint',
          name: 'Paint',
          size: GridSize(width: 1, height: 1),
          layers: [
            SmartTileLayer(
                id: 'ground',
                name: 'Ground',
                presetId: large.id,
                usage: SmartTileUsage.terrain,
                materialPalette: ['', large.defaultMaterialId],
                field: SmartTileField.cell(semanticCells: [1]))
          ]);
      final plan = buildSmartTileLayerVisualPlan(
          map: map,
          layer: map.layers.single as SmartTileLayer,
          catalog: installed.smartTileCatalog,
          pass: SmartTileVisualPass.background,
          sourceCellWidth: 2,
          sourceCellHeight: 2);
      expect(plan.resolveBatch(elapsedMs: 0).visuals, hasLength(count));
      final before =
          await File('${fixture.root.path}/catalog/HEAD.json').readAsBytes();
      expect((await fixture.prepare(selection: selected)).status,
          ResourcePackPreparedImportStatus.alreadyInstalled);
      expect(await File('${fixture.root.path}/catalog/HEAD.json').readAsBytes(),
          before);
      final undone = await fixture.mutations.undoMutation(
          fixture.opened.projectHandle,
          entryId: applied.receipt.receiptId,
          idempotencyKey: 'undo-large');
      expect(undone.receipt.status, AuthoringReceiptStatus.applied);
      expect(
          (await fixture.loader.load(fixture.opened.projectHandle))
              .manifest
              .toJson(),
          baseline);
    }, timeout: Timeout(Duration(minutes: 2)));
  }
}

ProjectManifest _animated(int count) {
  final base = source.originalManifest();
  final first = base.smartTileCatalog.presets.single;
  final animations = [
    for (var i = 0; i < count; i++)
      ProjectSmartTileAnimation(id: 'wave-$i', name: 'Wave $i', frames: [
        for (var frame = 0; frame < 360; frame++)
          ProjectSmartTileAnimationFrame(
              frame: SmartTileFrameRef(atlasId: 'a', column: 0, row: 0),
              durationMs: 33)
      ])
  ];
  final large = first.copyWith(id: 'large', name: 'Large', rules: [
    SmartTileRule(
        id: 'all',
        centerMatch: SmartTileSlotMatch.any(),
        candidates: [
          SmartTileCandidate(id: 'one', parts: [
            for (final animation in animations)
              SmartTileVisualPart(
                  source: SmartTileVisualSource.animation(
                      animationId: animation.id))
          ])
        ])
  ]);
  return base.copyWith(
      smartTileCatalog: ProjectSmartTileCatalog(
          atlases: base.smartTileCatalog.atlases,
          materials: base.smartTileCatalog.materials,
          animations: animations,
          presets: [first, large]));
}

int _values(Object? value) =>
    1 +
    (value is Map
        ? value.values.fold<int>(0, (sum, v) => sum + _values(v))
        : value is List
            ? value.fold<int>(0, (sum, v) => sum + _values(v))
            : 0);
Future<void> _partition(NativeResourcePackImportFixture fixture) async {
  final plan = await fixture.mutations.planMutation(
      fixture.opened.projectHandle,
      AuthoringRequest(
          requestId: 'partition',
          actionId: 'project.catalog.partition',
          actionVersion: 1,
          workspaceHandle: fixture.opened.workspaceHandle.value,
          expectedRevision:
              (await fixture.loader.load(fixture.opened.projectHandle))
                  .revision,
          idempotencyKey: 'partition'));
  await fixture.mutations.applyMutation(fixture.opened.projectHandle,
      planId: plan.planId, operationId: 'partition');
  await fixture.close();
  await fixture.open();
  await fixture.stage();
}
