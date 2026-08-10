import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Project presentation layouts V4', () {
    test('round-trips semantic layouts for every player surface', () {
      final profile = ProjectPresentationProfile(
        branding: const ProjectBrandingProfile(layoutVariant: 'cinematic'),
        layouts: _layouts(),
      );

      final decoded = ProjectPresentationProfile.fromJson(profile.toJson());

      expect(decoded, profile);
      expect(decoded.schemaVersion, 4);
      expect(decoded.branding.layoutVariant, 'cinematic');
      expect(
        decoded.configuredCategories,
        contains(ProjectPresentationCategory.layouts),
      );
    });

    test(
      'migrates V3 without layouts without serializing an authored layout',
      () {
        final profile = ProjectPresentationProfile.fromJson(<String, dynamic>{
          'schemaVersion': 3,
          'branding': <String, dynamic>{'layoutVariant': 'centered'},
        });

        expect(profile.schemaVersion, 4);
        expect(profile.layouts, isNull);
        expect(profile.toJson(), isNot(contains('layouts')));
        expect(profile.branding.layoutVariant, 'centered');
        expect(
          suggestedProjectPresentationLayouts('centered').title.regular.slot,
          ProjectPresentationLayoutSlot.center,
        );
      },
    );

    test(
      'maps every released title layout to deterministic studio defaults',
      () {
        expect(
          suggestedProjectPresentationLayouts('standard').title.expanded.slot,
          ProjectPresentationLayoutSlot.center,
        );
        expect(
          suggestedProjectPresentationLayouts('centered').title.expanded.slot,
          ProjectPresentationLayoutSlot.center,
        );
        expect(
          suggestedProjectPresentationLayouts('cinematic').title.expanded.slot,
          ProjectPresentationLayoutSlot.bottomLeft,
        );
      },
    );

    test('rejects layouts smuggled into an older schema', () {
      final json = ProjectPresentationProfile(layouts: _layouts()).toJson()
        ..['schemaVersion'] = 3;

      expect(
        () => ProjectPresentationProfile.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects invalid slots and secondary elements by surface', () {
      final layouts = _layouts().copyWith(
        title: _layouts().title.copyWith(
          compact: _variant(
            ProjectPresentationBreakpoint.compact,
            slot: ProjectPresentationLayoutSlot.topCenter,
            visibleSecondaryElements:
                const <ProjectPresentationSecondaryElement>[
                  ProjectPresentationSecondaryElement.dialoguePortrait,
                ],
          ),
        ),
        pauseMenu: _layouts().pauseMenu.copyWith(
          regular: _variant(
            ProjectPresentationBreakpoint.regular,
            slot: ProjectPresentationLayoutSlot.bottomCenter,
          ),
        ),
      );

      final codes = validateProjectPresentationProfile(
        ProjectPresentationProfile(layouts: layouts),
      ).map((diagnostic) => diagnostic.code);

      expect(codes, contains('presentationLayoutSlotUnsupported'));
      expect(codes, contains('presentationLayoutSecondaryElementUnsupported'));
    });

    test('rejects duplicate secondary elements', () {
      final layouts = _layouts().copyWith(
        dialogue: _layouts().dialogue.copyWith(
          expanded: _variant(
            ProjectPresentationBreakpoint.expanded,
            slot: ProjectPresentationLayoutSlot.bottomCenter,
            visibleSecondaryElements:
                const <ProjectPresentationSecondaryElement>[
                  ProjectPresentationSecondaryElement.dialoguePortrait,
                  ProjectPresentationSecondaryElement.dialoguePortrait,
                ],
          ),
        ),
      );

      expect(
        validateProjectPresentationProfile(
          ProjectPresentationProfile(layouts: layouts),
        ).map((diagnostic) => diagnostic.code),
        contains('presentationLayoutSecondaryElementDuplicate'),
      );
    });
  });
}

ProjectPresentationLayoutsProfile _layouts() =>
    ProjectPresentationLayoutsProfile(
      title: ProjectResponsiveSurfaceLayoutProfile(
        compact: _variant(
          ProjectPresentationBreakpoint.compact,
          slot: ProjectPresentationLayoutSlot.bottomCenter,
          visibleSecondaryElements: const <ProjectPresentationSecondaryElement>[
            ProjectPresentationSecondaryElement.titleLogo,
          ],
        ),
        regular: _variant(
          ProjectPresentationBreakpoint.regular,
          slot: ProjectPresentationLayoutSlot.center,
        ),
        expanded: _variant(
          ProjectPresentationBreakpoint.expanded,
          slot: ProjectPresentationLayoutSlot.bottomLeft,
          width: ProjectPresentationContentWidth.narrow,
        ),
      ),
      pauseMenu: ProjectResponsiveSurfaceLayoutProfile(
        compact: _variant(
          ProjectPresentationBreakpoint.compact,
          slot: ProjectPresentationLayoutSlot.fullScreen,
          visibleSecondaryElements: const <ProjectPresentationSecondaryElement>[
            ProjectPresentationSecondaryElement.pauseGameTitle,
          ],
        ),
        regular: _variant(
          ProjectPresentationBreakpoint.regular,
          slot: ProjectPresentationLayoutSlot.left,
        ),
        expanded: _variant(
          ProjectPresentationBreakpoint.expanded,
          slot: ProjectPresentationLayoutSlot.right,
        ),
      ),
      dialogue: ProjectResponsiveSurfaceLayoutProfile(
        compact: _variant(
          ProjectPresentationBreakpoint.compact,
          slot: ProjectPresentationLayoutSlot.bottomCenter,
        ),
        regular: _variant(
          ProjectPresentationBreakpoint.regular,
          slot: ProjectPresentationLayoutSlot.topCenter,
        ),
        expanded: _variant(
          ProjectPresentationBreakpoint.expanded,
          slot: ProjectPresentationLayoutSlot.bottomCenter,
          width: ProjectPresentationContentWidth.wide,
          visibleSecondaryElements: const <ProjectPresentationSecondaryElement>[
            ProjectPresentationSecondaryElement.dialoguePortrait,
          ],
        ),
      ),
    );

ProjectSurfaceLayoutVariant _variant(
  ProjectPresentationBreakpoint breakpoint, {
  required ProjectPresentationLayoutSlot slot,
  ProjectPresentationContentWidth width =
      ProjectPresentationContentWidth.comfortable,
  List<ProjectPresentationSecondaryElement> visibleSecondaryElements =
      const <ProjectPresentationSecondaryElement>[],
}) => ProjectSurfaceLayoutVariant(
  breakpoint: breakpoint,
  slot: slot,
  width: width,
  spacing: ProjectPresentationSpacing.normal,
  screenMargin: ProjectPresentationScreenMargin.compact,
  visibleSecondaryElements: visibleSecondaryElements,
);
