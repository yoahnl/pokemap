import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('inventories every player-facing presentation surface once', () {
    expect(
      projectPresentationSurfaceAssignments.map((item) => item.role).toSet(),
      ProjectPresentationSurfaceRole.values.toSet(),
    );
    expect(
      projectPresentationSurfaceAssignments.length,
      ProjectPresentationSurfaceRole.values.length,
    );
  });

  test('declares the canonical ownership of interactive surfaces', () {
    expect(
      projectPresentationSurfaceAssignment(
        ProjectPresentationSurfaceRole.pauseMenu,
      ),
      const ProjectPresentationSurfaceAssignment(
        role: ProjectPresentationSurfaceRole.pauseMenu,
        themeToken: ProjectPresentationSurfaceThemeToken.menuSurface,
        windowRole: ProjectWindowRole.pauseMenu,
        layoutRole: ProjectPresentationSurfaceRole.pauseMenu,
        labelKeys: <ProjectPresentationMenuLabelKey>[
          ProjectPresentationMenuLabelKey.pauseTitle,
          ProjectPresentationMenuLabelKey.resume,
          ProjectPresentationMenuLabelKey.party,
          ProjectPresentationMenuLabelKey.bag,
          ProjectPresentationMenuLabelKey.pokedex,
          ProjectPresentationMenuLabelKey.map,
          ProjectPresentationMenuLabelKey.save,
          ProjectPresentationMenuLabelKey.options,
          ProjectPresentationMenuLabelKey.returnToTitle,
        ],
      ),
    );
    expect(
      projectPresentationSurfaceAssignment(
        ProjectPresentationSurfaceRole.dialogue,
      ).windowRole,
      ProjectWindowRole.dialogue,
    );
    expect(
      projectPresentationSurfaceAssignment(
        ProjectPresentationSurfaceRole.battleHud,
      ).themeToken,
      ProjectPresentationSurfaceThemeToken.battleHudSurface,
    );
  });

  test('keeps the fullscreen intro outside window ownership', () {
    expect(
      ProjectPresentationSurfaceRole.values.map((role) => role.name),
      isNot(contains('intro')),
    );
    expect(
      projectPresentationSurfaceAssignments
          .where((item) => item.windowRole == null)
          .map((item) => item.role),
      containsAll(<ProjectPresentationSurfaceRole>[
        ProjectPresentationSurfaceRole.title,
        ProjectPresentationSurfaceRole.titlePrompt,
      ]),
    );
  });
}
