import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/features/personalization/presentation/personalization_player_surface_adapter.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  testWidgets('mounts the shared widget for every player scene', (
    tester,
  ) async {
    const expectedTypes = <PersonalizationStudioScene, Type>{
      PersonalizationStudioScene.title: PlayerTitleSurface,
      PersonalizationStudioScene.intro: PlayerIntroVideoSurface,
      PersonalizationStudioScene.pause: PlayerPauseSurface,
      PersonalizationStudioScene.dialogue: PlayerDialogueSurface,
      PersonalizationStudioScene.battle: PlayerBattleSurface,
    };

    for (final entry in expectedTypes.entries) {
      await tester.pumpWidget(_app(_adapter(entry.key)));
      await tester.pump();
      expect(find.byType(entry.value), findsOneWidget, reason: entry.key.name);
      if (entry.key == PersonalizationStudioScene.pause) {
        expect(find.byType(RuntimePlayerPauseShell), findsOneWidget);
      }
    }
  });

  testWidgets('applies the runtime player theme built from the draft', (
    tester,
  ) async {
    const profile = ProjectPresentationProfile(
      theme: ProjectSemanticThemeProfile(
        primary: '#123456',
        onPrimary: '#FFFFFF',
        background: '#08111F',
        surface: '#102033',
        surfaceElevated: '#19304A',
        textPrimary: '#F6F8FA',
        textSecondary: '#AAB8C5',
        outline: '#64748B',
        success: '#22C55E',
        warning: '#F59E0B',
        danger: '#EF4444',
        titleSurface: '#102033',
        dialogueSurface: '#F6F0E4',
        menuSurface: '#102033',
        overworldHudSurface: '#102033',
        battleHudSurface: '#19304A',
      ),
      typography: ProjectTypographyProfile(
        dialogue: ProjectTypographyRoleProfile(family: 'Studio Dialogue'),
      ),
    );
    await tester.pumpWidget(
      _app(
        const PersonalizationPlayerSurfaceAdapter(
          profile: profile,
          projectName: 'Aube',
          projectRootPath: '',
          scene: PersonalizationStudioScene.dialogue,
        ),
      ),
    );

    final context = tester.element(find.byType(PlayerDialogueSurface));
    expect(context.playerColors.primary, const Color(0xFF123456));
    expect(context.playerTypography.dialogueFamily, 'Studio Dialogue');
  });
}

PersonalizationPlayerSurfaceAdapter _adapter(
  PersonalizationStudioScene scene,
) => PersonalizationPlayerSurfaceAdapter(
  profile: const ProjectPresentationProfile(theme: safeProjectSemanticTheme),
  projectName: 'Aube',
  projectRootPath: '',
  scene: scene,
);

Widget _app(Widget child) => MaterialApp(
  theme: PokeMapTheme.light(),
  home: Scaffold(body: SizedBox(width: 960, height: 640, child: child)),
);
