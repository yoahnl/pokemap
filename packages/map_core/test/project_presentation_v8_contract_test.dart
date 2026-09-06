import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Project presentation V8 pause actions', () {
    test('round-trips ordered pause actions and their stable identity', () {
      const pause = ProjectPausePresentationProfile(
        title: 'Interlude',
        hint: 'Choisissez une rubrique',
        actions: <ProjectPauseActionProfile>[
          ProjectPauseActionProfile(
            id: ProjectPauseActionId.resume,
            label: 'Continuer',
            icon: ProjectPauseActionIcon.play,
          ),
          ProjectPauseActionProfile(
            id: ProjectPauseActionId.pokedex,
            label: 'Bestiaire',
            icon: ProjectPauseActionIcon.book,
          ),
          ProjectPauseActionProfile(
            id: ProjectPauseActionId.party,
            visible: false,
          ),
        ],
      );
      const profile = ProjectPresentationProfile(pause: pause);

      final decoded = ProjectPresentationProfile.fromJson(profile.toJson());

      expect(
        decoded.schemaVersion,
        ProjectPresentationProfile.supportedSchemaVersion,
      );
      expect(decoded.pause, pause);
      expect(decoded.pause?.actions?.first.id, ProjectPauseActionId.resume);
      expect(validateProjectPresentationProfile(decoded), isEmpty);
    });

    test('migrates every V7 menu entry without changing visible actions', () {
      final profile = ProjectPresentationProfile.fromJson(<String, dynamic>{
        'schemaVersion': 7,
        'branding': <String, dynamic>{'layoutVariant': 'standard'},
        'menuLabels': <String, dynamic>{
          'pauseTitle': 'Interlude',
          'pokedex': 'Bestiaire',
        },
      });

      expect(
        profile.schemaVersion,
        ProjectPresentationProfile.supportedSchemaVersion,
      );
      expect(profile.pause?.title, 'Interlude');
      expect(
        profile.pause?.actions,
        hasLength(defaultProjectPauseActions.length),
      );
      expect(
        profile.pause?.actions
            ?.singleWhere((action) => action.id == ProjectPauseActionId.pokedex)
            .label,
        'Bestiaire',
      );
      expect(profile.pause?.actions?.every((action) => action.visible), isTrue);
      expect(profile.toJson(), isNot(contains('menuLabels')));
    });

    test('rejects V8 pause data smuggled into a V7 document', () {
      expect(
        () => ProjectPresentationProfile.fromJson(<String, dynamic>{
          'schemaVersion': 7,
          'branding': <String, dynamic>{'layoutVariant': 'standard'},
          'pause': <String, dynamic>{
            'actions': <Object?>[
              <String, Object?>{'id': 'resume'},
            ],
          },
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('validates duplicate, hidden required and unreadable actions', () {
      final diagnostics = validateProjectPresentationProfile(
        ProjectPresentationProfile(
          pause: ProjectPausePresentationProfile(
            title: '   ',
            hint: 'Une\ndeux\u0007',
            actions: <ProjectPauseActionProfile>[
              const ProjectPauseActionProfile(
                id: ProjectPauseActionId.resume,
                visible: false,
              ),
              const ProjectPauseActionProfile(id: ProjectPauseActionId.party),
              ProjectPauseActionProfile(
                id: ProjectPauseActionId.party,
                label: List<String>.filled(41, 'a').join(),
              ),
            ],
          ),
        ),
      );

      expect(
        diagnostics.map((diagnostic) => diagnostic.code),
        containsAll(<String>{
          'pauseTitleEmpty',
          'pauseHintContainsControlCharacters',
          'pauseActionDuplicate',
          'pauseResumeRequired',
          'pauseActionLabelTooLong',
        }),
      );
    });

    test('rejects unknown pause action and icon identifiers', () {
      Map<String, dynamic> json(String id, String icon) => <String, dynamic>{
        'schemaVersion': 8,
        'branding': <String, dynamic>{'layoutVariant': 'standard'},
        'pause': <String, dynamic>{
          'actions': <Object?>[
            <String, Object?>{'id': id, 'icon': icon},
          ],
        },
      };

      expect(
        () =>
            ProjectPresentationProfile.fromJson(json('unknownAction', 'play')),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ProjectPresentationProfile.fromJson(json('resume', 'dragon')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('round-trips responsive pause composition presets', () {
      const composition = ProjectResponsivePauseCompositionProfile(
        compactPortrait: ProjectPauseCompositionVariantProfile(
          entrySize: ProjectPauseEntrySize.large,
          entrySpacing: ProjectPauseEntrySpacing.airy,
          showHint: false,
        ),
        compactLandscape: ProjectPauseCompositionVariantProfile(
          entrySize: ProjectPauseEntrySize.compact,
          entrySpacing: ProjectPauseEntrySpacing.tight,
          showRootDetailPanel: false,
        ),
        expanded: ProjectPauseCompositionVariantProfile(showTitle: false),
      );
      const profile = ProjectPresentationProfile(
        pause: ProjectPausePresentationProfile(composition: composition),
      );

      final decoded = ProjectPresentationProfile.fromJson(profile.toJson());

      expect(decoded.pause?.composition, composition);
      expect(
        composition.resolve(ProjectPresentationBreakpoint.compact),
        composition.compactPortrait,
      );
      expect(
        composition.resolve(
          ProjectPresentationBreakpoint.compact,
          portrait: false,
        ),
        composition.compactLandscape,
      );
      expect(
        composition.resolve(ProjectPresentationBreakpoint.expanded),
        composition.expanded,
      );
    });
  });
}
