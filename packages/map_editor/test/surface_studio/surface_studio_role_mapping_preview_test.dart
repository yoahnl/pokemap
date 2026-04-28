import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_role_mapping_preview.dart';

void main() {
  testWidgets('preview shows center, borders and corners in a 3x3 grid',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        SurfaceStudioRoleMappingPreview(
          preset: _preset(),
          selectedRole: SurfaceVariantRole.cross,
        ),
      ),
    );

    expect(find.text('Mapping visuel'), findsOneWidget);
    expect(find.text('Centre / plein'), findsOneWidget);
    expect(find.text('Bord haut'), findsOneWidget);
    expect(find.text('Bord droite'), findsOneWidget);
    expect(find.text('Bord bas'), findsOneWidget);
    expect(find.text('Bord gauche'), findsOneWidget);
    expect(find.text('Coin haut gauche'), findsOneWidget);
    expect(find.text('Coin haut droit'), findsOneWidget);
    expect(find.text('Coin bas droit'), findsOneWidget);
    expect(find.text('Coin bas gauche'), findsOneWidget);
    expect(find.text('Animation liée'), findsWidgets);
    expect(find.text('Animation manquante'), findsWidgets);
  });
}

Widget _wrap(Widget child) {
  return MacosApp(
    theme: MacosThemeData.dark(),
    home: ColoredBox(
      color: const Color(0xFF0F1218),
      child: Center(child: child),
    ),
  );
}

ProjectSurfacePreset _preset() => ProjectSurfacePreset(
      id: 'water-surface',
      name: 'Water Surface',
      variantAnimations: SurfaceVariantAnimationRefSet(
        refs: [
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.cross,
            animationId: 'anim-cross',
          ),
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.endNorth,
            animationId: 'anim-top',
          ),
        ],
      ),
    );
