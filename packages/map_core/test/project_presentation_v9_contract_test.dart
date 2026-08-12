import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Project presentation V9 dialogue geometry', () {
    test('round-trips every explicit dialogue geometry property', () {
      const profile = ProjectPresentationProfile(
        dialogue: ProjectDialoguePresentationProfile(
          placement: ProjectDialoguePlacement.top,
          maxWidthFactor: .64,
          margin: 20,
          contentPadding: 24,
          shape: ProjectWindowShape.speech,
          cornerRadius: 18,
          borderWidth: 3,
          fillOpacity: .82,
          surfaceColor: '#102030',
          borderColor: '#A0B0C0',
          textColor: '#F0F0F0',
          portraitSide: ProjectDialoguePortraitSide.end,
          portraitSize: 112,
          portraitShape: ProjectDialoguePortraitShape.circle,
          portraitFrameWidth: 4,
          portraitFrameColor: '#C0FFEE',
          nameplateStyle: ProjectDialogueNameplateStyle.floating,
          nameplateBorderWidth: 2,
          nameplateSurfaceColor: '#334455',
          nameplateBorderColor: '#778899',
          nameplateTextColor: '#FFFFFF',
          choiceSpacing: 14,
          choiceShape: ProjectDialogueChoiceShape.cutCorner,
          choiceDisabledOpacity: .35,
          choiceSelectedColor: '#FFAA00',
          progressIndicator: ProjectDialogueProgressIndicator.dots,
          progressIndicatorColor: '#00FFAA',
          portraitTransition: ProjectDialoguePortraitTransition.slide,
          portraitTransitionMilliseconds: 320,
        ),
      );

      final decoded = ProjectPresentationProfile.fromJson(profile.toJson());

      expect(decoded.schemaVersion, 10);
      expect(decoded.dialogue, profile.dialogue);
      expect(validateProjectPresentationProfile(decoded), isEmpty);
    });

    test('migrates V8 without changing its legacy dialogue path', () {
      final decoded = ProjectPresentationProfile.fromJson(
        const <String, dynamic>{
          'schemaVersion': 8,
          'branding': <String, dynamic>{},
        },
      );

      expect(decoded.schemaVersion, 10);
      expect(decoded.dialogue, isNull);
    });

    test('rejects dialogue data declared before V9', () {
      expect(
        () => ProjectPresentationProfile.fromJson(const <String, dynamic>{
          'schemaVersion': 8,
          'branding': <String, dynamic>{},
          'dialogue': <String, dynamic>{},
        }),
        throwsFormatException,
      );
    });

    test('validates every dialogue range and color', () {
      const profile = ProjectPresentationProfile(
        dialogue: ProjectDialoguePresentationProfile(
          maxWidthFactor: 1.2,
          margin: -1,
          contentPadding: 80,
          cornerRadius: 60,
          borderWidth: 20,
          fillOpacity: .1,
          surfaceColor: 'black',
          borderColor: '#FFFFFF80',
          textColor: '#FFF',
          portraitSize: 12,
          portraitFrameWidth: 20,
          portraitFrameColor: 'transparent',
          nameplateBorderWidth: 10,
          nameplateSurfaceColor: '#FFFFFF80',
          nameplateBorderColor: 'black',
          nameplateTextColor: '#FFF',
          choiceSpacing: 40,
          choiceDisabledOpacity: .1,
          choiceSelectedColor: 'orange',
          progressIndicatorColor: '#FFF',
          portraitTransitionMilliseconds: 1200,
        ),
      );

      expect(
        validateProjectPresentationProfile(
          profile,
        ).map((diagnostic) => diagnostic.code).toSet(),
        containsAll(<String>{
          'dialogueMaxWidthFactorOutOfRange',
          'dialogueMarginOutOfRange',
          'dialogueContentPaddingOutOfRange',
          'dialogueCornerRadiusOutOfRange',
          'dialogueBorderWidthOutOfRange',
          'dialogueFillOpacityOutOfRange',
          'dialoguePortraitSizeOutOfRange',
          'dialoguePortraitFrameWidthOutOfRange',
          'dialogueNameplateBorderWidthOutOfRange',
          'dialogueChoiceSpacingOutOfRange',
          'dialogueChoiceDisabledOpacityOutOfRange',
          'dialoguePortraitTransitionDurationOutOfRange',
          'dialogueColorInvalid',
        }),
      );
    });
  });
}
