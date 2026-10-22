import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/data/local_resource_pack_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_draft_compatibility.dart';
import 'package:avelune_studio/presentation/features/resources/resource_border_lifecycle.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../resource_io/resource_pack_export_host_test.dart'
    show FileExportTestSink;
import '../support/map_workspace_fixture.dart' show WorkspaceTestVisuals;
import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/ui04_terrain_atlas.dart' show ui04TerrainAtlas;

String digest(List<int> bytes) => sha256.convert(bytes).toString();

class Host {
  Host(this.root, this.archive);
  final Directory root;
  final File archive;
  late ProjectSession session;
  late LocalMapWorkspaceAdapter maps;
  late LocalResourceAdapter resources;
  late LocalResourcePackAdapter pack;
  late MapWorkspaceController workspace;
  late ResourceNavigation navigation;
  bool open = false;

  static Future<Host> create(Directory root, File archive) async {
    await root.create(recursive: true);
    await File('${root.path}/project.json').writeAsString(
      jsonEncode(
        ProjectManifest(
          name: 'Original discriminant',
          maps: [],
          tilesets: [],
          settings: ProjectSettings(tileWidth: 24, tileHeight: 24),
        ).toJson(),
      ),
    );
    return Host(root, archive);
  }

  Future<void> initialize() async {
    session = ProjectSession(
      sessionId: '${root.path}-${DateTime.now().microsecondsSinceEpoch}',
      name: 'Discriminant',
      directoryPath: await root.resolveSymbolicLinks(),
    );
    maps = LocalMapWorkspaceAdapter();
    workspace = MapWorkspaceController(session, maps);
    await workspace.initialize();
    resources = LocalResourceAdapter(session: session, mapAdapter: maps);
    pack = LocalResourcePackAdapter(
      session: session,
      mapAdapter: maps,
      resources: resources,
    );
    navigation = ResourceNavigation(
      workspace: workspace,
      port: resources,
      visuals: WorkspaceTestVisuals(),
      onUse: (_) {},
      packPort: pack,
      packPicker: () async => archive.path,
      packExportSink: FileExportTestSink(archive),
    );
    open = true;
  }

  Future<ProjectManifest> load() => maps.loadProject(session);

  Future<void> close() async {
    if (!open) return;
    await navigation.packTransfer!.requestClose();
    navigation.dispose();
    await pack.dispose();
    workspace.dispose();
    await resources.dispose();
    open = false;
  }
}

Future<String> addAtlas(Host host) async {
  final file = File('${host.root.path}/source-original.png');
  await file.writeAsBytes(ui04TerrainAtlas());
  final receipt = await host.resources.importImage(
    ResourceImageImport(
      sourcePath: file.path,
      name: 'Original atlas',
      tileWidth: 24,
      tileHeight: 24,
    ),
  );
  await host.navigation.accept(receipt);
  return receipt.createdTilesetId!;
}

Future<void> officialExport(Host host, String kind) async {
  final c = host.navigation.packTransfer!;
  await c.beginExport(projectName: 'Original discriminant');
  for (final entry in {
    'author': 'Original test author',
    'universeId': 'original-fixture',
    'provenance': 'Original in-memory workshop fixture',
  }.entries) {
    await c.setExportField(entry.key, entry.value);
  }
  await c.setFilter(kind: kind);
  await c.selectFiltered();
  await c.prepare();
  expect(c.error, isNull);
  if (c.requiresOrganizationAcknowledgement) {
    c.setOrganizationAcknowledgement(true);
  }
  await c.export();
  expect(c.error, isNull);
  expect(c.outputPath, host.archive.path);
  await c.requestClose();
}

Future<Host> importAndReopen(Directory root, File archive) async {
  final first = await Host.create(root, archive);
  await first.initialize();
  final c = first.navigation.packTransfer!;
  await c.beginImport();
  await c.selectFiltered();
  await c.prepare();
  expect(c.error, isNull);
  await c.apply();
  expect(c.error, isNull);
  final installed = await first.load();
  final firstSession = first.session.sessionId;
  await first.close();
  final reopened = Host(root, archive);
  await reopened.initialize();
  expect(reopened.session.sessionId, isNot(firstSession));
  expect(await reopened.load(), installed);
  return reopened;
}

Future<void> canonicalPublish(
  Host host,
  BorderBlueprintRecord draft,
  String relativePath,
) async {
  await host.navigation.accept(
    await host.resources.mutate('border.blueprint.draft.upsert', {
      'record': encodeBorderBlueprintRecordJson(
        draft,
        formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
      ),
    }),
  );
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [host.root.path],
    fileReader: reader,
  );
  final handles = WorkspaceHandleStore();
  final opened = await ProjectOpenService(
    policy: policy,
    fileReader: reader,
    handles: handles,
  ).openProject(host.root.path);
  final loader = ProjectSnapshotLoader(handles: handles);
  final artifacts = LocalArtifactStore(
    allowedSourceRoots: [host.root.path],
    maximumArtifactBytes: maximumAuthoringArtifactBytesV1,
  );
  final api = LocalMapAuthoringMutationApi(
    policy: policy,
    snapshotLoader: loader,
    artifactStore: artifacts,
  );
  final source = File('${host.root.path}/$relativePath');
  await artifacts.authorizeSourceFile(source.path);
  final staged = await api.stageArtifactFile(
    sourcePath: source.path,
    declaredMediaType: 'image/png',
  );
  await api.attachProject(
    projectRootPath: host.root.path,
    workspaceHandle: opened.workspaceHandle,
    projectHandle: opened.projectHandle,
  );
  try {
    final params = <String, Object?>{
      'blueprintId': draft.id,
      'acceptedWarningCodes': <String>[],
      'primitiveSources': [
        for (final primitive in draft.draft.definition.primitives)
          {
            'primitiveId': primitive.id,
            'frames': [
              for (final frame in [(0, 100), (24, 150)])
                {
                  'artifactHandle': staged.reference.handle,
                  'sourceProjectRelativePath': relativePath,
                  'sourceRectPx': {
                    'x': frame.$1,
                    'y': 0,
                    'width': 24,
                    'height': 24,
                  },
                  'durationMs': frame.$2,
                },
            ],
          },
      ],
    };
    Future<AuthoringMutationPlanResult> plan() async => api.planMutation(
      opened.projectHandle,
      AuthoringRequest(
        requestId: 'publish-custom',
        actionId: 'border.blueprint.publish',
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        expectedRevision: (await loader.load(opened.projectHandle)).revision,
        idempotencyKey: 'publish-custom',
        parameters: params,
      ),
    );
    late AuthoringMutationPlanResult planned;
    try {
      planned = await plan();
    } on MapAuthoringException catch (failure) {
      if (failure.code !=
          'border.blueprint.publication_warnings_unacknowledged') {
        rethrow;
      }
      params['acceptedWarningCodes'] =
          failure.details['unacknowledgedWarningCodes'];
      planned = await plan();
    }
    final confirmed = await api.confirmMutation(
      opened.projectHandle,
      planId: planned.planId,
    );
    await api.applyMutation(
      opened.projectHandle,
      planId: planned.planId,
      operationId: 'publish-custom',
      confirmationToken: confirmed.confirmationToken,
    );
  } finally {
    await artifacts.release(staged.reference.handle);
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Studio terrain survives official roundtrip, no-op republication and a real connection edit', () async {
    final root = await Directory.systemTemp.createTemp(
      'p11-terrain-reedition-',
    );
    addTearDown(() => root.delete(recursive: true));
    final archive = File('${root.path}/terrain.aveluneassets');
    final a = await Host.create(Directory('${root.path}/A'), archive);
    await a.initialize();
    addTearDown(a.close);
    final atlasId = await addAtlas(a);
    a.navigation.prepareTerrain(
      resourceCatalog(a.workspace.project!)
          .singleWhere((item) => item.tileset?.id == atlasId),
    );
    final workshop = a.navigation.terrain!;
    for (var mask = 0; mask < 16; mask++) {
      workshop.selectedRule = mask;
      final index = mask * 5 % 16;
      workshop.assign(index % 4, index ~/ 4);
    }
    expect(
      await workshop.save(a.navigation.mutate, publish: true),
      isTrue,
      reason: workshop.error,
    );
    final sourceBeforeExport = digest(
      await File('${a.root.path}/project.json').readAsBytes(),
    );
    final sourcePreset = (await a.load()).smartTileCatalog.presets.single;
    await officialExport(a, 'smartTilePreset');
    final b = await importAndReopen(Directory('${root.path}/B'), archive);
    addTearDown(b.close);
    final before = b.workspace.project!;
    final preset = before.smartTileCatalog.presets.single;
    final draft = before.smartTileCatalog.drafts.single;
    expect(draft.guideId, 'avelune-cardinal4-v1');
    expect(draft.rules.map((r) => r.id), sourcePreset.rules.map((r) => r.id));
    for (var i = 0; i < draft.rules.length; i++) {
      expect(
        draft.rules[i].candidates.single.id,
        sourcePreset.rules[i].candidates.single.id,
      );
      final original = sourcePreset.rules[i].candidates.single.parts.single;
      final frame = (original.source as SmartTileFrameSource).frame;
      expect(
        draft.rules[i].candidates.single.parts.single,
        original.copyWith(
          source: SmartTileVisualSource.frame(
            frame: frame.copyWith(atlasId: draft.atlases.single.id),
          ),
        ),
      );
    }
    b.navigation.prepareTerrain(
      resourceCatalog(before)
          .singleWhere((item) => item.terrain?.id == preset.id),
    );
    final resumed = b.navigation.terrain!;
    expect(
      await resumed.save(b.navigation.mutate),
      isTrue,
      reason: resumed.error,
    );
    expect(
      await resumed.save(b.navigation.mutate, publish: true),
      isTrue,
      reason: resumed.error,
    );
    final noOp = await b.load();
    expect(noOp.smartTileCatalog.presets.single, preset);
    expect(noOp.smartTileCatalog.atlases, before.smartTileCatalog.atlases);
    expect(noOp.smartTileCatalog.materials, before.smartTileCatalog.materials);
    await b.close();
    final cArchive = File('${root.path}/edited.aveluneassets');
    final reopened = Host(b.root, cArchive);
    await reopened.initialize();
    addTearDown(reopened.close);
    reopened.navigation.prepareTerrain(
      resourceCatalog(reopened.workspace.project!)
          .singleWhere((item) => item.terrain?.id == preset.id),
    );
    final edited = reopened.navigation.terrain!;
    expect(edited.draft.rules, draft.rules);
    edited.selectedRule = 0;
    edited.assign(1, 0);
    expect(
      await edited.save(reopened.navigation.mutate, publish: true),
      isTrue,
      reason: edited.error,
    );
    final changed = (await reopened.load()).smartTileCatalog.presets.single;
    expect(changed.rules.first, isNot(preset.rules.first));
    expect(changed.rules.skip(1), preset.rules.skip(1));
    await officialExport(reopened, 'smartTilePreset');
    final c = await importAndReopen(Directory('${root.path}/C'), cArchive);
    addTearDown(c.close);
    final finalDraft = c.workspace.project!.smartTileCatalog.drafts.single;
    expect(finalDraft.guideId, 'avelune-cardinal4-v1');
    final finalFrame =
        (finalDraft.rules.first.candidates.single.parts.single.source
                as SmartTileFrameSource)
            .frame;
    expect(finalFrame.column, 1);
    expect(finalFrame.row, 0);
    expect(
      terrainDraftCompatibilityProblem(c.workspace.project!, finalDraft),
      isNull,
    );
    expect(
      digest(await File('${a.root.path}/project.json').readAsBytes()),
      sourceBeforeExport,
    );
  });

  testWidgets(
    'imported animated custom Border retains definition, pixels and anchors through no-op save and publish',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final hosts = <Host>[];
      late Host b;
      late Directory root;
      await tester.runAsync(() async {
        root = await Directory.systemTemp.createTemp('p11-border-reedition-');
        final archive = File('${root.path}/border.aveluneassets');
        final a = await Host.create(Directory('${root.path}/A'), archive);
        hosts.add(a);
        await a.initialize();
        final atlasId = await addAtlas(a);
        await a.navigation.accept(
          await a.resources.saveElement(
            ProjectElementEntry(
              id: 'original-piece',
              name: 'Original piece',
              tilesetId: atlasId,
              categoryId: '',
              frames: [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0),
                  durationMs: 100,
                ),
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 1, y: 0),
                  durationMs: 150,
                ),
              ],
            ),
          ),
        );
        await a.navigation.accept(
          await a.resources.createBorder(
            BorderCreationRequest(
              blueprintId: 'original-custom-border',
              name: 'Original custom border',
              capElementId: 'original-piece',
              straightElementId: 'original-piece',
              cornerElementId: 'original-piece',
              publish: false,
            ),
          ),
        );
        final tile = a.workspace.project!.tilesets.single;
        final bytes = await File('${a.root.path}/${tile.relativePath}')
            .readAsBytes();
        BorderPrimitiveDraft piece(
          String id,
          BorderPrimitiveRole role,
          int weight,
          int x,
          int y,
        ) {
          final anchor = BorderPixelPos(x: x, y: y);
          final prepared = const CanonicalBorderSnapshotCompiler().prepare(
            sourceElementId: 'original-piece',
            anchorPx: anchor,
            frames: [
              for (final frame in [(0, 100), (24, 150)])
                CanonicalBorderSourceFrame(
                  sourceProjectRelativePath: tile.relativePath,
                  encodedImageBytes: bytes,
                  sourceRectPx: BorderPixelRect(
                    x: frame.$1,
                    y: 0,
                    width: 24,
                    height: 24,
                  ),
                  durationMs: frame.$2,
                ),
            ],
          );
          return BorderPrimitiveDraft(
            id: id,
            sourceElementId: 'original-piece',
            role: role,
            authoredOrientation: BorderPrimitiveOrientation.east,
            weight: weight,
            anchorPx: anchor,
            currentMetrics: prepared.metrics,
            transforms: BorderTransformPolicy(
              allowFlipX: true,
              allowedQuarterTurns: [0, 1, 2, 3],
            ),
          );
        }

        final custom = BorderBlueprintRecord(
          id: 'original-custom-border',
          draft: BorderBlueprintDraft(
            baseRevision: 0,
            definition: BorderBlueprintDraftDefinition(
              name: 'Original custom border',
              previewSeed: BorderSignedInt64.zero,
              template: BorderBlueprintTemplate.connectedLine,
              primitives: [
                piece('custom-cap', BorderPrimitiveRole.lineCap, 250, 11, 12),
                piece(
                  'custom-straight-a',
                  BorderPrimitiveRole.lineStraight,
                  300,
                  11,
                  12,
                ),
                piece(
                  'custom-straight-b',
                  BorderPrimitiveRole.lineStraight,
                  700,
                  12,
                  11,
                ),
                piece(
                  'custom-corner',
                  BorderPrimitiveRole.lineCorner,
                  500,
                  11,
                  12,
                ),
              ],
              defaults: BorderGenerationParams(
                irregularityPermille: 0,
                detailDensityPermille: 0,
                variationPermille: 0,
                maxOverlapPx: 12,
                gapTolerancePx: 4,
                depthRows: 1,
              ),
              sortOrder: 0,
            ),
          ),
        );
        await canonicalPublish(a, custom, tile.relativePath);
        await officialExport(a, 'borderBlueprint');
        b = await importAndReopen(Directory('${root.path}/B'), archive);
        hosts.add(b);
      });
      addTearDown(() async {
        for (final host in hosts.reversed) {
          await host.close();
        }
        await root.delete(recursive: true);
      });
      final before = b.workspace.project!.borderCatalog.records.single;
      Future<Map<String, String>> pixels() async => {
        for (final snapshot in (await b.load()).borderCatalog.visualSnapshots)
          for (final frame in snapshot.frames)
            frame.relativeAssetPath: digest(
              await File('${b.root.path}/${frame.relativeAssetPath}')
                  .readAsBytes(),
            ),
      };
      final framesBefore = (await tester.runAsync(pixels))!;
      Future<void> mount(BorderBlueprintRecord record) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => unawaited(
                    openBorderPreparation(context, b.navigation, record),
                  ),
                  child: const Text('Open imported border'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open imported border'));
        await tester.pumpAndSettle();
      }

      await mount(before);
      expect(
        b.navigation.packBorderDraftOwners[before.id]!().request.expectedRecord,
        before,
      );
      await tester.runAsync(
        () => tester.tap(find.text('Enregistrer le brouillon')),
      );
      await pumpIo(tester);
      final saved = (await tester.runAsync(b.load))!
          .borderCatalog
          .records
          .single;
      expect(saved.draft.definition, before.draft.definition);
      expect(saved.latestPublished, before.latestPublished);
      await mount(saved);
      await tester.runAsync(
        () => tester.tap(find.byKey(const ValueKey('border-publish'))),
      );
      await pumpIo(tester);
      final published = (await tester.runAsync(b.load))!
          .borderCatalog
          .records
          .single;
      expect(
        published.latestPublished!.definition,
        before.latestPublished!.definition,
      );
      expect((await tester.runAsync(pixels))!, framesBefore);
      expect(published.draft.definition.primitives.map((p) => p.weight), [
        250,
        300,
        700,
        500,
      ]);
      for (final snapshot in (await tester.runAsync(
        b.load,
      ))!.borderCatalog.visualSnapshots) {
        expect(snapshot.frames.map((f) => f.durationMs), [100, 150]);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        final manifest = await b.load();
        final element = manifest.elements.single;
        await b.navigation.accept(
          await b.resources.saveElement(
            element.copyWith(id: 'replacement-piece', name: 'Replacement'),
          ),
        );
        final edited = await b.resources.createBorder(
          BorderCreationRequest(
            blueprintId: published.id,
            expectedRecord: published,
            name: published.draft.definition.name,
            capElementId: element.id,
            straightElementId: 'replacement-piece',
            cornerElementId: element.id,
          ),
        );
        final draft =
            edited.manifest.borderCatalog.records.single.draft.definition;
        expect(
          draft.primitives
              .where((p) => p.role == BorderPrimitiveRole.lineStraight)
              .single
              .sourceElementId,
          'replacement-piece',
        );
        for (final role in [
          BorderPrimitiveRole.lineCap,
          BorderPrimitiveRole.lineCorner,
        ]) {
          expect(
            draft.primitives.singleWhere((p) => p.role == role),
            published.draft.definition.primitives.singleWhere(
              (p) => p.role == role,
            ),
          );
        }
      });
    },
  );
}
