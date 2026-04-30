import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_role_mapping_builder.dart';

void main() {
  testWidgets('shows visual role slots and maps roles through a picker',
      (tester) async {
    Map<SurfaceVariantRole, String>? changed;

    await tester.pumpWidget(
      _wrap(
        TiledTsxRoleMappingBuilder(
          atlas: _atlas(),
          animations: _animations(),
          selectedAnimationIds: const {
            'tech-animations-tile-99',
            'tech-animations-tile-105',
          },
          roleAnimationIds: const {
            SurfaceVariantRole.horizontal: 'tech-animations-tile-105',
          },
          roleSources: const <SurfaceVariantRole, TiledTsxRoleAssignmentMeta>{},
          onChanged: (next) => changed = next,
        ),
      ),
    );

    expect(find.text('Surface principale'), findsOneWidget);
    expect(find.text('Bords'), findsOneWidget);
    expect(find.text('Coins externes'), findsOneWidget);
    expect(find.text('Coins internes'), findsOneWidget);
    expect(find.text('Jonctions'), findsOneWidget);
    expect(find.text('Plein(center)'), findsOneWidget);
    expect(find.text('Horizontal'), findsOneWidget);
    expect(find.text('Vertical'), findsOneWidget);
    expect(find.text('Bord haut'), findsOneWidget);
    expect(find.text('Coin haut gauche'), findsOneWidget);
    expect(find.text('Croix'), findsOneWidget);
    expect(find.text('Non assigné'), findsWidgets);
    expect(find.text('tech-animations-tile-105'), findsWidgets);
    expect(find.text('1 frame · 100 ms'), findsWidgets);
    expect(find.text('Aperçu indisponible'), findsWidgets);
    expect(
      find.byKey(
        const ValueKey('tiled_tsx_surface_preset_builder.role.isolated'),
      ),
      findsNothing,
    );

    await tester.tap(
      find.byKey(
        const ValueKey('tiled_tsx_role_mapping_builder.pick.isolated'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choisir une animation pour Plein(center)'), findsOne);
    await tester.enterText(
      find.byKey(
        const ValueKey('tiled_tsx_role_mapping_builder.search.isolated'),
      ),
      '99',
    );
    await tester.pumpAndSettle();
    expect(find.text('tech-animations-tile-99'), findsWidgets);

    await tester.tap(
      find.byKey(
        const ValueKey(
          'tiled_tsx_role_mapping_builder.option.isolated.tech-animations-tile-99',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(changed, isNotNull);
    expect(changed![SurfaceVariantRole.isolated], 'tech-animations-tile-99');
    expect(changed![SurfaceVariantRole.horizontal], 'tech-animations-tile-105');

    await tester.tap(
      find.byKey(
        const ValueKey('tiled_tsx_role_mapping_builder.clear.horizontal'),
      ),
    );
    await tester.pumpAndSettle();

    expect(changed, isNotNull);
    expect(changed!.containsKey(SurfaceVariantRole.horizontal), isFalse);
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: 1200, height: 900, child: child),
    ),
  );
}

ProjectSurfaceAtlas _atlas() {
  return ProjectSurfaceAtlas(
    id: 'tech-animations',
    name: 'TECH-Animations',
    tilesetId: 'tech-nature-animations',
    geometry: SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
      gridSize: SurfaceAtlasGridSize(columns: 98, rows: 109),
      layout: SurfaceAtlasLayout.grid,
    ),
  );
}

List<ProjectSurfaceAnimation> _animations() {
  return [
    _animation('tech-animations-tile-99', 1, 1),
    _animation('tech-animations-tile-105', 7, 1),
  ];
}

ProjectSurfaceAnimation _animation(String id, int column, int row) {
  return ProjectSurfaceAnimation(
    id: id,
    name: id,
    timeline: SurfaceAnimationTimeline(
      frames: [
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(
            atlasId: 'tech-animations',
            column: column,
            row: row,
          ),
          durationMs: 100,
        ),
      ],
    ),
  );
}
