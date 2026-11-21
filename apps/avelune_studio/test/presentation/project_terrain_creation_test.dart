import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/application/project_resource_library.dart';
import 'package:avelune_studio/features/resources/application/project_resource_preview.dart';
import 'package:avelune_studio/features/resources/domain/project_library_editor.dart';
import 'package:avelune_studio/features/resources/domain/project_terrain_workshop_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/project_library_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/scoped_map_workspace_port.dart';

void main() {
  for (final painted in [false, true]) {
    testWidgets(
      'creates and reveals a terrain using only its selected template, painted=$painted',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1400, 900);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final port = _TerrainLibraryPort(painted: painted);
        final workspace = MapWorkspaceController(scopedMapSession, port);
        addTearDown(workspace.dispose);
        await workspace.initialize();
        await workspace.ensureResourceKind('smartTilePreset');
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            home: Scaffold(
              body: ProjectLibraryPage(
                active: true,
                maps: workspace,
                visuals: null,
                management: (editor: port, pickFile: () async => null),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Ateliers'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Terrains'));
        await tester.pumpAndSettle();
        expect(find.text('Nouveau terrain'), findsOneWidget);
        await tester.tap(find.text('Nouveau terrain'));
        await tester.pumpAndSettle();
        expect(port.previewReads, isEmpty);

        await tester.tap(
          find.byKey(const ValueKey('terrain-creation-template')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Chemin repère').last);
        await tester.pumpAndSettle();
        expect(port.previewReads, ['template']);
        if (painted) {
          expect(find.text('Support neutre peint'), findsOneWidget);
          expect(
            find.text('Le matériau de base de ce terrain est indisponible.'),
            findsNothing,
          );
        } else {
          expect(find.text('Pierre'), findsOneWidget);
          await tester.tap(
            find.byKey(const ValueKey('terrain-creation-material')),
          );
          await tester.pumpAndSettle();
          expect(find.text('Boue sans raccord'), findsNothing);
          await tester.tap(find.text('Sable').last);
          await tester.pumpAndSettle();
        }

        await tester.enterText(
          find.byKey(const ValueKey('terrain-creation-name')),
          '  Chemin neuf  ',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Publier le terrain'));
        await tester.pumpAndSettle();

        expect(port.requests, [
          (
            name: 'Chemin neuf',
            materialId: painted ? 'neutral' : 'sand',
            revision: 'catalog-1',
          ),
        ]);
        expect(find.text('Chemin neuf'), findsOneWidget);
        expect(port.previewReads, ['template', 'created']);
        expect(port.resourceKinds, ['smartTilePreset']);
        expect(port.closureReads, ['smartTilePreset:created']);
        expect(
          workspace.visualProject!.smartTileCatalog.presets.map(
            (item) => item.id,
          ),
          contains('created'),
        );
        expect(port.fullReads, 0);
      },
    );
  }
}

final class _TerrainLibraryPort extends ScopedTestMapPort
    implements
        ProjectResourceLibraryPort,
        ProjectResourcePreviewPort,
        ProjectTerrainWorkshopPort,
        MapWorkspaceResourceClosurePort,
        ProjectLibraryEditor {
  _TerrainLibraryPort({required this.painted});

  final bool painted;

  static const _piece = SmartTileCandidate(
    id: 'piece',
    parts: [
      SmartTileVisualPart(
        source: SmartTileVisualSource.frame(
          frame: SmartTileFrameRef(atlasId: 'base-atlas', column: 0, row: 0),
        ),
      ),
    ],
  );

  static const _template = ProjectSmartTilePreset(
    id: 'template',
    name: 'Chemin repère',
    usage: SmartTileUsage.path,
    topology: SmartTileTopology.uniform,
    status: SmartTilePresetStatus.published,
    coveragePolicy: SmartTileCoveragePolicy.sparse,
    coverageProfile: SmartTileCoverageProfile(
      mode: SmartTileCoverageMode.explicit,
      allowFallback: false,
    ),
    transformPolicy: SmartTileTransformPolicy(),
    defaultMaterialId: 'stone',
    allowedMaterialIds: ['stone', 'sand', 'mud'],
    rules: [
      SmartTileRule(
        id: 'stone',
        centerMatch: SmartTileSlotMatch.material('stone'),
        candidates: [_piece],
      ),
      SmartTileRule(
        id: 'sand',
        centerMatch: SmartTileSlotMatch.material('sand'),
        candidates: [_piece],
      ),
    ],
  );

  final previewReads = <String>[];
  final closureReads = <String>[];
  final requests = <({String name, String materialId, String revision})>[];
  ProjectSmartTilePreset? _created;

  @override
  bool get terrainConnectionEditingAvailable => true;

  @override
  Future<ProjectResourceLibrary> readResourceLibrary(
    ProjectSession session,
  ) async => ProjectResourceLibrary(ResourceLibraryCatalog(), [
    ProjectLibraryItem(
      kind: 'smartTilePreset',
      id: _template.id,
      name: _template.name,
    ),
  ], revision: 'catalog-1');

  @override
  Future<ProjectManifest> readResourcePreview(
    ProjectSession session,
    String kind,
    String id,
  ) async {
    previewReads.add(id);
    return _projectFor(id);
  }

  @override
  Future<MapWorkspaceCatalog> loadResourceClosure(
    ProjectSession session,
    String canonicalKind,
    String id,
  ) async {
    closureReads.add('$canonicalKind:$id');
    return MapWorkspaceCatalog(
      metadata: _projectFor(id),
      revision: 'catalog-2',
    );
  }

  ProjectManifest _projectFor(String id) => metadata.copyWith(
    smartTileCatalog: ProjectSmartTileCatalog(
      presets: [
        if (id == _template.id)
          painted
              ? _template.copyWith(
                  usage: SmartTileUsage.terrain,
                  defaultMaterialId: 'neutral',
                  allowedMaterialIds: const ['neutral'],
                  rules: const [],
                )
              : _template
        else
          _created!,
      ],
      materials: const [
        ProjectSmartTileMaterial(
          id: 'stone',
          name: 'Pierre',
          connectionGroupId: 'stone',
        ),
        ProjectSmartTileMaterial(
          id: 'sand',
          name: 'Sable',
          connectionGroupId: 'sand',
        ),
        ProjectSmartTileMaterial(
          id: 'mud',
          name: 'Boue sans raccord',
          connectionGroupId: 'mud',
        ),
        ProjectSmartTileMaterial(
          id: 'neutral',
          name: 'Support neutre peint',
          connectionGroupId: 'neutral',
          isEmpty: true,
        ),
      ],
    ),
  );

  @override
  Future<ProjectLibraryEdit> createTerrain(
    ProjectSmartTilePreset draft, {
    required String expectedRevision,
  }) async {
    requests.add((
      name: draft.name,
      materialId: draft.defaultMaterialId,
      revision: expectedRevision,
    ));
    final created = draft.copyWith(id: 'created');
    _created = created;
    return (
      item: ProjectLibraryItem(
        kind: 'smartTilePreset',
        id: created.id,
        name: created.name,
      ),
      receipt: ResourceMutationReceipt(
        before: metadata,
        manifest: metadata,
        beforeRevision: expectedRevision,
        revision: 'catalog-2',
        changedPaths: const ['catalog/HEAD.json'],
        changedTerrain: created,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
