import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_family.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_smart_tile_paint_palette.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';

// POST-WLD-SMART-002 — « Le canvas n'affiche pas les hautes herbes parce que
// leur calque persistant est masqué, alors que l'inspecteur Peindre reste
// actif et accepte les gestes sans avertissement. »
//
// Le painter exclut les calques `isVisible = false` ; la palette Peindre,
// elle, ne regardait jamais cette visibilité. L'auteur peignait donc dans le
// vide sans que rien ne le dise.
//
// Décision d'UX prise ici, guidée par le champ Risques du ticket (« préférer
// un état explicite et une action utilisateur ») : on AVERTIT et on offre le
// réaffichage, sans réafficher d'office ni bloquer le geste — masquer un
// calque peut être volontaire, et avaler un geste sans raison visible
// remplacerait un défaut silencieux par un autre.

final _project = ProjectManifest(
  name: 'Herbes',
  maps: const <ProjectMapEntry>[],
  tilesets: const <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'world',
      name: 'World',
      relativePath: 'tilesets/world.png',
    ),
  ],
  smartTileCatalog: ProjectSmartTileCatalog(
    materials: const <ProjectSmartTileMaterial>[
      ProjectSmartTileMaterial(
        id: 'herbe',
        name: 'Herbe',
        connectionGroupId: 'herbe',
      ),
    ],
    presets: const <ProjectSmartTilePreset>[
      ProjectSmartTilePreset(
        id: 'hautes-herbes',
        name: 'Hautes herbes',
        usage: SmartTileUsage.path,
        topology: SmartTileTopology.wangCorner4,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.explicit,
        ),
        transformPolicy: SmartTileTransformPolicy(),
        status: SmartTilePresetStatus.published,
        defaultMaterialId: 'herbe',
        allowedMaterialIds: <String>['herbe'],
        rules: <SmartTileRule>[
          SmartTileRule(
            id: 'fill',
            centerMatch: SmartTileSlotMatch.any(),
            candidates: <SmartTileCandidate>[
              SmartTileCandidate(id: 'fill-c0', weight: 1000),
            ],
          ),
        ],
      ),
    ],
  ),
);

MapData _mapWith({required bool isVisible}) => MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: const GridSize(width: 2, height: 2),
      layers: <MapLayer>[
        SmartTileLayer(
          id: 'herbes-calque',
          name: 'Hautes herbes',
          presetId: 'hautes-herbes',
          usage: SmartTileUsage.path,
          isVisible: isVisible,
          field: SmartTileField.cell(semanticCells: const <int>[0, 0, 0, 0]),
        ),
      ],
    );

Future<ProviderContainer> _pumpPalette(
  WidgetTester tester, {
  required bool layerIsVisible,
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final keepAlive = container.listen(editorNotifierProvider, (_, _) {});
  addTearDown(keepAlive.close);
  final map = _mapWith(isVisible: layerIsVisible);
  container.read(editorNotifierProvider.notifier).state = EditorState(
    projectRootPath: '/virtual/project',
    project: _project,
    workspaceMode: EditorWorkspaceMode.map,
    activeMap: map,
    activeLayerId: 'herbes-calque',
    savedMapSnapshot: map,
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 440,
            height: 900,
            child: SingleChildScrollView(
              child: WorldMapSmartTilePaintPalette(
                subtool: WorldMapPaintSubtool.path,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  testWidgets(
      'un calque actif MASQUÉ est signalé dans la palette Peindre',
      (tester) async {
    await _pumpPalette(tester, layerIsVisible: false);

    expect(
      find.byKey(const Key('world-map-smart-tile-path-hidden-layer')),
      findsOneWidget,
      reason: 'peindre sur un calque invisible ne doit plus être silencieux',
    );
  });

  testWidgets('un calque visible ne montre aucun avertissement',
      (tester) async {
    await _pumpPalette(tester, layerIsVisible: true);

    expect(
      find.byKey(const Key('world-map-smart-tile-path-hidden-layer')),
      findsNothing,
    );
  });

  testWidgets(
      'l’action de la palette réaffiche le calque, sans le faire d’office',
      (tester) async {
    final container = await _pumpPalette(tester, layerIsVisible: false);

    // Rien n'a été réaffiché sans geste de l'auteur : masquer peut être
    // volontaire.
    expect(
      container
          .read(editorNotifierProvider)
          .activeMap!
          .layers
          .single
          .isVisible,
      isFalse,
    );

    await tester.tap(
      find.byKey(const Key('world-map-smart-tile-path-show-layer')),
    );
    await tester.pump();

    expect(
      container
          .read(editorNotifierProvider)
          .activeMap!
          .layers
          .single
          .isVisible,
      isTrue,
      reason: 'le CTA rend la main à l’auteur en un geste',
    );
  });
}
