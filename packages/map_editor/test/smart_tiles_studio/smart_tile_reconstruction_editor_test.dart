import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_reconstruction_service.dart';
import 'package:map_editor/src/features/smart_tiles_studio/presentation/smart_tile_reconstruction_editor.dart';

void main() {
  testWidgets('guides inspection before exposing the confirmed apply action',
      (tester) async {
    SmartTileReconstructionRequest? inspected;
    var applied = false;
    await tester.pumpWidget(
      _host(
        SmartTileReconstructionEditor(
          manifest: _manifest,
          map: _map,
          onCancel: () {},
          onInspect: (request) async => inspected = request,
          onApply: () async => applied = true,
        ),
      ),
    );

    expect(find.text('Reconstruire une couche littérale'), findsOneWidget);
    expect(find.text('Couche source'), findsOneWidget);
    expect(find.text('Preset Smart Tile publié'), findsOneWidget);
    expect(find.text('Analyser la reconstruction'), findsOneWidget);
    expect(find.text('Confirmer et créer la couche'), findsNothing);

    await tester.tap(find.text('Analyser la reconstruction'));
    await tester.pump();

    expect(inspected, isNotNull);
    expect(inspected!.mapId, 'map');
    expect(inspected!.sourceLayerId, 'literal');
    expect(inspected!.presetId, 'edge');
    expect(inspected!.targetLayerId, 'literal_smart_tiles');
    expect(applied, isFalse);

    await tester.pumpWidget(
      _host(
        SmartTileReconstructionEditor(
          manifest: _manifest,
          map: _map,
          plan: _plan,
          onCancel: () {},
          onInspect: (_) async {},
          onApply: () async => applied = true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Couverture 100 %'), findsOneWidget);
    expect(find.text('1 correspondance visuelle exacte'), findsOneWidget);
    expect(find.textContaining('couche littérale restera intacte'),
        findsOneWidget);
    await tester.drag(
      find.byKey(const Key('smart-tile-reconstruction-editor')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(find.text('Confirmer et créer la couche'), findsOneWidget);

    await tester.tap(find.text('Confirmer et créer la couche'));
    await tester.pump();
    expect(applied, isTrue);
  });
}

Widget _host(Widget child) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: SizedBox(width: 900, height: 700, child: child)),
    );

final _plan = SmartTileReconstructionPlan(
  canonical: SmartTileReconstructionCanonicalPlan(
    token: Object(),
    planId: 'plan',
    snapshotRevision: 'revision',
    preview: const <String, Object?>{
      'sourceCellCount': 1,
      'reconstructedCellCount': 1,
      'coverage': 1.0,
      'unresolvedCellCount': 0,
      'ambiguousCellCount': 0,
      'conflictCount': 0,
      'exactVisualMatchCount': 1,
      'visualMismatchCellCount': 0,
      'sourcePreserved': true,
      'confirmationRequired': true,
      'assessmentChecksum': 'sha256:test',
    },
  ),
  request: const SmartTileReconstructionRequest(
    mapId: 'map',
    sourceLayerId: 'literal',
    presetId: 'edge',
    targetLayerId: 'literal_smart_tiles',
    targetLayerName: 'Literal — Smart Tiles',
  ),
  sourceLayer: _literal,
);

const _literal = TileLayer(
  id: 'literal',
  name: 'Literal',
  palette: <TileLayerPaletteEntry>[
    TileLayerPaletteEntry(tilesetId: 'tiles', localTileId: 1),
  ],
  cells: <int>[1],
);

const _map = MapData(
  id: 'map',
  name: 'Map',
  version: ProjectVersion.v6,
  size: GridSize(width: 1, height: 1),
  layers: <MapLayer>[_literal],
);

final _manifest = ProjectManifest(
  name: 'Project',
  maps: const <ProjectMapEntry>[
    ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
  ],
  tilesets: const <ProjectTilesetEntry>[],
  smartTileCatalog: ProjectSmartTileCatalog(
    presets: const <ProjectSmartTilePreset>[
      ProjectSmartTilePreset(
        id: 'edge',
        name: 'Edge',
        usage: SmartTileUsage.path,
        topology: SmartTileTopology.wangEdge4,
        status: SmartTilePresetStatus.published,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.explicit,
          requiredScenarios: <SmartTileCoverageScenario>[
            SmartTileCoverageScenario(id: 'scenario'),
          ],
        ),
        transformPolicy: SmartTileTransformPolicy(),
        defaultMaterialId: 'dirt',
        allowedMaterialIds: <String>['dirt'],
      ),
    ],
  ),
);
