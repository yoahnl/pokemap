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

    final dropdown =
        find.byKey(const ValueKey('surface_role_mapping_dropdown_cross'));
    final button = tester.widget<DropdownButton<String>>(dropdown);
    button.onChanged!('anim-horizontal');
    await tester.pump();

    expect(changedRole, SurfaceVariantRole.cross);
    expect(changedAnimationId, 'anim-horizontal');
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
  return ProjectSurfaceCatalog(
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
