import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Project presentation V10 battle', () {
    test('round-trips every explicit battle presentation property', () {
      const profile = ProjectPresentationProfile(
        battle: ProjectBattlePresentationProfile(
          commandLayout: ProjectBattleCommandLayout.radial,
          commandColumns: 3,
          showCommandIcons: false,
          commandShape: ProjectWindowShape.cutCorner,
          commandPadding: 18,
          commandSurfaceColor: '#102030',
          commandBorderColor: '#A0B0C0',
          commandTextColor: '#F0F0F0',
          commandSelectionColor: '#FFAA00',
          commands: <ProjectBattleCommandProfile>[
            ProjectBattleCommandProfile(
              id: ProjectBattleCommandId.run,
              label: 'Retraite',
              icon: ProjectBattleCommandIcon.run,
            ),
            ProjectBattleCommandProfile(
              id: ProjectBattleCommandId.fight,
              label: 'Techniques',
              icon: ProjectBattleCommandIcon.fight,
            ),
            ProjectBattleCommandProfile(
              id: ProjectBattleCommandId.party,
              label: 'Alliés',
              icon: ProjectBattleCommandIcon.party,
            ),
            ProjectBattleCommandProfile(
              id: ProjectBattleCommandId.bag,
              label: 'Inventaire',
              icon: ProjectBattleCommandIcon.bag,
            ),
          ],
          hudShape: ProjectWindowShape.rectangle,
          enemyHudPosition: ProjectBattleHudPosition.topEnd,
          playerHudPosition: ProjectBattleHudPosition.bottomStart,
          showOwnerLabel: false,
          showLevel: false,
          showExactHp: false,
          hpBarShape: ProjectBattleHpBarShape.segmented,
          hpHealthyColor: '#00AA55',
          hpWarningColor: '#FFAA00',
          hpDangerColor: '#CC2244',
          statusColor: '#8844FF',
          moves: ProjectBattlePanelPresentationProfile(
            layout: ProjectBattleCommandLayout.list,
            columns: 1,
            shape: ProjectWindowShape.rounded,
            padding: 16,
            surfaceColor: '#112233',
          ),
          target: ProjectBattlePanelPresentationProfile(
            layout: ProjectBattleCommandLayout.grid,
            columns: 2,
            selectionColor: '#22CCAA',
          ),
          message: ProjectBattlePanelPresentationProfile(
            shape: ProjectWindowShape.cutCorner,
            textColor: '#FFFFFF',
          ),
        ),
      );

      final decoded = ProjectPresentationProfile.fromJson(profile.toJson());

      expect(decoded.schemaVersion, 10);
      expect(decoded.battle, profile.battle);
      expect(validateProjectPresentationProfile(decoded), isEmpty);
    });

    test('migrates V9 without enabling authored battle presentation', () {
      final decoded = ProjectPresentationProfile.fromJson(
        const <String, dynamic>{
          'schemaVersion': 9,
          'branding': <String, dynamic>{},
        },
      );

      expect(decoded.schemaVersion, 10);
      expect(decoded.battle, isNull);
    });

    test('rejects battle presentation declared before V10', () {
      expect(
        () => ProjectPresentationProfile.fromJson(const <String, dynamic>{
          'schemaVersion': 9,
          'branding': <String, dynamic>{},
          'battle': <String, dynamic>{},
        }),
        throwsFormatException,
      );
    });

    test('rejects duplicate or incomplete command identities', () {
      const profile = ProjectPresentationProfile(
        battle: ProjectBattlePresentationProfile(
          commands: <ProjectBattleCommandProfile>[
            ProjectBattleCommandProfile(id: ProjectBattleCommandId.fight),
            ProjectBattleCommandProfile(id: ProjectBattleCommandId.fight),
          ],
        ),
      );

      expect(
        validateProjectPresentationProfile(
          profile,
        ).map((diagnostic) => diagnostic.code).toSet(),
        containsAll(<String>{
          'battleCommandIdDuplicate',
          'battleCommandSetIncomplete',
        }),
      );
    });

    test('rejects unsafe ranges, shapes, positions and colors', () {
      const profile = ProjectPresentationProfile(
        battle: ProjectBattlePresentationProfile(
          commandColumns: 0,
          commandShape: ProjectWindowShape.speech,
          commandPadding: 80,
          commandSurfaceColor: 'black',
          enemyHudPosition: ProjectBattleHudPosition.topStart,
          playerHudPosition: ProjectBattleHudPosition.topStart,
          hpHealthyColor: '#FFF',
          moves: ProjectBattlePanelPresentationProfile(
            columns: 8,
            shape: ProjectWindowShape.speech,
            padding: -1,
            textColor: 'white',
          ),
        ),
      );

      expect(
        validateProjectPresentationProfile(
          profile,
        ).map((diagnostic) => diagnostic.code).toSet(),
        containsAll(<String>{
          'battleCommandColumnsOutOfRange',
          'battleCommandShapeUnsupported',
          'battleCommandPaddingOutOfRange',
          'battleHudPositionConflict',
          'battlePanelColumnsOutOfRange',
          'battlePanelShapeUnsupported',
          'battlePanelPaddingOutOfRange',
          'battleColorInvalid',
        }),
      );
    });
  });
}
