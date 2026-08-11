import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Project presentation V7 title copy', () {
    test('round-trips authored copy and resolves explicit fallbacks', () {
      const copy = ProjectTitlePresentationProfile(
        title: 'Pokémon Aurore',
        subtitle: 'Une aventure à Hanazuki',
        prompt: 'Appuyez pour commencer',
      );
      const profile = ProjectPresentationProfile(title: copy);

      final decoded = ProjectPresentationProfile.fromJson(profile.toJson());

      expect(decoded.schemaVersion, 7);
      expect(decoded.title, copy);
      expect(copy.resolveTitle('Nom du projet'), 'Pokémon Aurore');
      expect(
        copy.resolveSubtitle('Auteur du projet'),
        'Une aventure à Hanazuki',
      );
      expect(
        copy.resolvePrompt('Invitation par défaut'),
        'Appuyez pour commencer',
      );
      expect(
        const ProjectTitlePresentationProfile().resolveTitle('Nom du projet'),
        'Nom du projet',
      );
      expect(
        const ProjectTitlePresentationProfile(
          subtitle: '',
        ).resolveSubtitle('Auteur du projet'),
        isNull,
      );
      expect(
        const ProjectTitlePresentationProfile(
          prompt: '',
        ).resolvePrompt('Invitation par défaut'),
        isNull,
      );
    });

    test('migrates V6 without inventing authored title copy', () {
      final profile = ProjectPresentationProfile.fromJson(<String, dynamic>{
        'schemaVersion': 6,
        'branding': <String, dynamic>{'layoutVariant': 'standard'},
      });

      expect(profile.schemaVersion, 7);
      expect(profile.title, isNull);
    });

    test('rejects V7 title copy smuggled into a V6 document', () {
      expect(
        () => ProjectPresentationProfile.fromJson(<String, dynamic>{
          'schemaVersion': 6,
          'branding': <String, dynamic>{'layoutVariant': 'standard'},
          'title': <String, dynamic>{'title': 'Titre interdit'},
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('validates empty, oversized, multiline and control copy', () {
      final diagnostics = validateProjectPresentationProfile(
        ProjectPresentationProfile(
          title: ProjectTitlePresentationProfile(
            title: '   ',
            subtitle: '${List<String>.filled(121, 'a').join()}\nencore',
            prompt: 'Une\ndeux\ntrois\nquatre\u0007',
          ),
        ),
      );

      expect(
        diagnostics.map((diagnostic) => diagnostic.code),
        containsAll(<String>{
          'titleCopyEmpty',
          'titleCopyTooLong',
          'titleCopyTooManyLines',
          'titleCopyContainsControlCharacters',
        }),
      );
      expect(
        validateProjectPresentationProfile(
          const ProjectPresentationProfile(
            title: ProjectTitlePresentationProfile(subtitle: '', prompt: ''),
          ),
        ),
        isEmpty,
      );
    });

    test(
      'round-trips ordered title actions and validates their invariants',
      () {
        const profile = ProjectPresentationProfile(
          title: ProjectTitlePresentationProfile(
            actions: <ProjectTitleActionProfile>[
              ProjectTitleActionProfile(
                id: ProjectTitleActionId.newGame,
                label: 'Commencer',
                icon: ProjectTitleActionIcon.sparkles,
              ),
              ProjectTitleActionProfile(
                id: ProjectTitleActionId.continueGame,
                label: 'Reprendre',
                icon: ProjectTitleActionIcon.play,
                visible: false,
              ),
            ],
          ),
        );

        final decoded = ProjectPresentationProfile.fromJson(profile.toJson());

        expect(decoded, profile);
        expect(decoded.title?.actions?.first.id, ProjectTitleActionId.newGame);
        expect(validateProjectPresentationProfile(decoded), isEmpty);

        final invalid = validateProjectPresentationProfile(
          const ProjectPresentationProfile(
            title: ProjectTitlePresentationProfile(
              actions: <ProjectTitleActionProfile>[
                ProjectTitleActionProfile(
                  id: ProjectTitleActionId.newGame,
                  visible: false,
                ),
                ProjectTitleActionProfile(
                  id: ProjectTitleActionId.newGame,
                  label: 'Nouvelle\npartie',
                  visible: false,
                ),
              ],
            ),
          ),
        );
        expect(
          invalid.map((diagnostic) => diagnostic.code),
          containsAll(<String>{
            'titleActionDuplicate',
            'titleNewGameRequired',
            'titleActionLabelContainsControlCharacters',
          }),
        );
      },
    );

    test('rejects an unknown title action during decoding', () {
      expect(
        () => ProjectPresentationProfile.fromJson(<String, dynamic>{
          'schemaVersion': 7,
          'branding': <String, dynamic>{'layoutVariant': 'standard'},
          'title': <String, dynamic>{
            'actions': <Object?>[
              <String, Object?>{'id': 'warpToMars'},
            ],
          },
        }),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
