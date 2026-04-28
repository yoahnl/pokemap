import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_role_mapping_editor.dart';

void main() {
  testWidgets('editor lists roles, current animation and missing roles',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        SurfaceStudioRoleMappingEditor(
          catalog: _catalog(),
          preset: _catalog().presetById('water-surface')!,
          onRoleAnimationChanged: (_, __) {},
        ),
      ),
    );

    expect(find.text('Édition du mapping de surface'), findsOneWidget);
    expect(find.text('Surface sélectionnée : Water Surface'), findsOneWidget);
    expect(find.text('Centre / plein'), findsWidgets);
    expect(find.text('Bord haut'), findsWidgets);
    expect(find.textContaining('Water Cross'), findsWidgets);
    expect(find.text('Animation manquante'), findsWidgets);
    expect(find.textContaining('ProjectSurfacePreset'), findsNothing);
    expect(find.textContaining('SurfaceVariantAnimationRef'), findsNothing);
    expect(find.textContaining('copyWith'), findsNothing);
  });

  testWidgets('changing a role animation invokes the callback', (tester) async {
    SurfaceVariantRole? changedRole;
    String? changedAnimationId;
    await tester.pumpWidget(
      _wrap(
        SurfaceStudioRoleMappingEditor(
          catalog: _catalog(),
          preset: _catalog().presetById('water-surface')!,
          onRoleAnimationChanged: (role, animationId) {
            changedRole = role;
            changedAnimationId = animationId;
          },
        ),
      ),
    );

    final horizontalCard =
        find.byKey(const ValueKey('surface_role_column_card_anim-horizontal'));
    await tester.ensureVisible(horizontalCard);
    await tester.pump();
    await tester.tap(horizontalCard);
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('surface_role_assign_column')),
      220,
    );
    await tester.tap(find.byKey(const ValueKey('surface_role_assign_column')));
    await tester.pump();

    expect(changedRole, SurfaceVariantRole.cross);
    expect(changedAnimationId, 'anim-horizontal');
  });

  testWidgets('visual slot then column click assigns the selected role',
      (tester) async {
    SurfaceVariantRole? changedRole;
    String? changedAnimationId;
    await tester.pumpWidget(
      _wrap(
        SurfaceStudioRoleMappingEditor(
          catalog: _catalog(),
          preset: _catalog().presetById('water-surface')!,
          onRoleAnimationChanged: (role, animationId) {
            changedRole = role;
            changedAnimationId = animationId;
          },
        ),
      ),
    );

    expect(find.text('Schéma des slots Surface'), findsOneWidget);
    expect(find.text('Cliquez un slot, puis une colonne'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('surface_role_slot_endNorth')),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('surface_role_active_slot_label')),
      findsOneWidget,
    );
    expect(find.text('Slot actif : Bord haut'), findsWidgets);
    expect(find.textContaining('limite supérieure'), findsOneWidget);

    final horizontalCard =
        find.byKey(const ValueKey('surface_role_column_card_anim-horizontal'));
    await tester.ensureVisible(horizontalCard);
    await tester.pump();
    await tester.tap(horizontalCard);
    await tester.pump();

    expect(changedRole, SurfaceVariantRole.endNorth);
    expect(changedAnimationId, 'anim-horizontal');
    expect(find.text('Assigné au slot actif'), findsOneWidget);
  });

  testWidgets('visual gallery exposes columns, selection and mapping summary',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        SurfaceStudioRoleMappingEditor(
          catalog: _catalog(),
          preset: _catalog().presetById('water-surface')!,
          onRoleAnimationChanged: (_, __) {},
        ),
      ),
    );

    expect(find.text('Galerie des colonnes'), findsOneWidget);
    expect(find.text('Col 0'), findsWidgets);
    expect(find.text('Col 1'), findsOneWidget);
    expect(find.text('Assigné au slot actif'), findsOneWidget);
    expect(find.text('Non assignée'), findsOneWidget);
    expect(find.text('Résumé du mapping'), findsOneWidget);
    expect(find.text('Schéma des slots Surface'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('surface_role_slot_cross')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('surface_role_slot_cornerNE')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('surface_role_slot_teeNorth')),
      findsOneWidget,
    );
    expect(find.text('Colonnes : 2'), findsOneWidget);
    expect(find.text('Assignées : 1'), findsOneWidget);
    expect(find.text('Non assignées : 1'), findsOneWidget);
    expect(find.textContaining('Rôles manquants'), findsOneWidget);

    final horizontalCard =
        find.byKey(const ValueKey('surface_role_column_card_anim-horizontal'));
    await tester.ensureVisible(horizontalCard);
    await tester.pump();
    await tester.tap(horizontalCard);
    await tester.pump();

    expect(find.textContaining('Colonne sélectionnée : Col 1'), findsOneWidget);
    expect(find.textContaining('Water Horizontal'), findsWidgets);
  });

  testWidgets('duplicate animation assignments are visible', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SurfaceStudioRoleMappingEditor(
          catalog: _duplicateCatalog(),
          preset: _duplicateCatalog().presetById('water-surface')!,
          onRoleAnimationChanged: (_, __) {},
        ),
      ),
    );

    expect(find.textContaining('Doublons : 1'), findsOneWidget);
    expect(find.text('Doublon'), findsWidgets);
  });

  testWidgets('role detail explains the selected role without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 330,
          child: SurfaceStudioRoleMappingEditor(
            catalog: _catalog(),
            preset: _catalog().presetById('water-surface')!,
            onRoleAnimationChanged: (_, __) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Détail du rôle'), findsOneWidget);
    expect(find.textContaining('jonction centrale'), findsOneWidget);
  });

  testWidgets('shows clear copy when no animation is available',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        SurfaceStudioRoleMappingEditor(
          catalog: ProjectSurfaceCatalog(presets: [_catalog().presets.first]),
          preset: _catalog().presetById('water-surface')!,
          onRoleAnimationChanged: (_, __) {},
        ),
      ),
    );

    expect(find.text('Aucune animation disponible.'), findsOneWidget);
    expect(
      find.text('Générez d’abord les animations depuis l’atlas.'),
      findsOneWidget,
    );
  });

  testWidgets('real atlas picker shows image grid and assigns a clicked column',
      (tester) async {
    final image = await _fakeAtlasImage();
    addTearDown(image.dispose);
    SurfaceVariantRole? changedRole;
    String? changedAnimationId;

    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 1040,
          child: SurfaceStudioRoleMappingEditor(
            catalog: _catalog(),
            preset: _catalog().presetById('water-surface')!,
            projectRootPath: '/project',
            projectTilesets: _tilesets(),
            imageLoader: (_) async => image,
            onRoleAnimationChanged: (role, animationId) {
              changedRole = role;
              changedAnimationId = animationId;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Atlas réel cliquable'), findsOneWidget);
    expect(find.byKey(const ValueKey('surface_real_atlas_picker')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('surface_real_atlas_grid')), findsOneWidget);
    expect(find.text('Galerie des colonnes'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('surface_role_slot_endNorth')));
    await tester.pump();

    final hitArea = find.byKey(const ValueKey('surface_real_atlas_hit_area'));
    await tester.ensureVisible(hitArea);
    await tester.pump();
    final topLeft = tester.getTopLeft(hitArea);
    final size = tester.getSize(hitArea);
    await tester.tapAt(topLeft + Offset(size.width * 0.75, size.height * 0.5));
    await tester.pump();

    expect(changedRole, SurfaceVariantRole.endNorth);
    expect(changedAnimationId, 'anim-horizontal');
    expect(find.byKey(const ValueKey('surface_role_real_crop_endNorth')),
        findsOneWidget);
    expect(
      find.textContaining('Colonne assignée : Col 1'),
      findsOneWidget,
    );
  });

  testWidgets('real atlas picker explains fallback when image cannot load',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 1040,
          child: SurfaceStudioRoleMappingEditor(
            catalog: _catalog(),
            preset: _catalog().presetById('water-surface')!,
            projectRootPath: '/project',
            projectTilesets: _tilesets(),
            imageLoader: (_) async => null,
            onRoleAnimationChanged: (_, __) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Image atlas réelle indisponible'), findsOneWidget);
    expect(find.byKey(const ValueKey('surface_real_atlas_fallback')),
        findsOneWidget);
    expect(find.text('Galerie des colonnes'), findsOneWidget);
  });
}

Widget _wrap(Widget child) {
  return MacosApp(
    theme: MacosThemeData.dark(),
    home: ColoredBox(
      color: const Color(0xFF0F1218),
      child: Material(
        child: SingleChildScrollView(
          child: Center(child: child),
        ),
      ),
    ),
  );
}

ProjectSurfaceCatalog _catalog() {
  final atlas = ProjectSurfaceAtlas(
    id: 'atlas',
    name: 'Water Atlas',
    tilesetId: 'surface-water-tileset',
    geometry: SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
      gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
      layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
    ),
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [
      _animation('anim-cross', 'Water Cross', column: 0),
      _animation('anim-horizontal', 'Water Horizontal', column: 1),
    ],
    presets: [
      ProjectSurfacePreset(
        id: 'water-surface',
        name: 'Water Surface',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.cross,
              animationId: 'anim-cross',
            ),
          ],
        ),
      ),
    ],
  );
}

List<ProjectTilesetEntry> _tilesets() => const [
      ProjectTilesetEntry(
        id: 'surface-water-tileset',
        name: 'Surface Water Tileset',
        relativePath: 'assets/tilesets/water.png',
      ),
    ];

ProjectSurfaceCatalog _duplicateCatalog() {
  final catalog = _catalog();
  return ProjectSurfaceCatalog(
    animations: catalog.animations,
    presets: [
      ProjectSurfacePreset(
        id: 'water-surface',
        name: 'Water Surface',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.cross,
              animationId: 'anim-cross',
            ),
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.horizontal,
              animationId: 'anim-cross',
            ),
          ],
        ),
      ),
    ],
  );
}

ProjectSurfaceAnimation _animation(
  String id,
  String name, {
  required int column,
}) =>
    ProjectSurfaceAnimation(
      id: id,
      name: name,
      timeline: SurfaceAnimationTimeline(
        frames: [
          SurfaceAnimationFrame(
            tileRef: SurfaceAtlasTileRef(
              atlasId: 'atlas',
              column: column,
              row: 0,
            ),
            durationMs: 100,
          ),
        ],
      ),
    );

Future<ui.Image> _fakeAtlasImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 32, 64),
    ui.Paint()..color = const ui.Color(0xFF0EA5E9),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(32, 0, 32, 64),
    ui.Paint()..color = const ui.Color(0xFF22C55E),
  );
  canvas.drawLine(
    const ui.Offset(32, 0),
    const ui.Offset(32, 64),
    ui.Paint()
      ..color = const ui.Color(0xFFFFFFFF)
      ..strokeWidth = 2,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(64, 64);
  picture.dispose();
  return image;
}
