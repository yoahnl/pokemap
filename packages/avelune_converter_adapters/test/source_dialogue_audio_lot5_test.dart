import 'package:avelune_converter_adapters/src/source_dialogue_text.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  DialogueAudioCue? resolve(String name, int volume, int pitch, int offset) =>
      name == 'ItemGet'
          ? DialogueAudioCue(
              mediaAssetId: 'source-item-get',
              cueId: 'item-get',
              volume: volume / 100,
              revealOffset: offset)
          : null;

  test('inline sound preserves native reveal position after source controls',
      () {
    final parsed = parseSourceDialogueText(r'\bA😀\nB\se[ItemGet:80:100]Suite',
        soundEffect: resolve);
    expect(parsed, isNotNull);
    expect(parsed!.plainText, 'A😀\nBSuite');
    expect(parsed.audioCue!.revealOffset, 4);
    expect(parsed.audioCue!.volume, 0.8);
    expect(parsed.audioCue!.role, DialogueAudioCueRole.effect);
  });

  test('prefix sound defaults and terminal auto wait preserve their timing',
      () {
    final parsed = parseSourceDialogueText(r'\se[ItemGet]\PN reçu!\wtnp[35]',
        soundEffect: resolve)!;
    expect(parsed.audioCue!.revealOffset, 0);
    expect(parsed.audioCue!.volume, 1);
    expect(parsed.plainText, '{{ player_name }} reçu!');
    expect(parsed.advance, DialogueLineAdvancePolicy.autoAfterReveal(1750000));
  });

  test('source audio discovery ignores escaped controls and invalid parameters',
      () {
    expect(sourceDialogueSoundNames(r'A\se[ItemGet:80:100]B'), ['ItemGet']);
    expect(sourceDialogueSoundNames(r'A\\se[ItemGet]B'), isEmpty);
    expect(sourceDialogueSoundNames(r'\se[ItemGet:80:120]B'), isEmpty);
    expect(sourceDialogueSoundNames(r'\se[../ItemGet]B'), isEmpty);
  });

  test(
      'variable discovery reaches substitutions after inline audio without fake cues',
      () {
    expect(sourceDialogueVariableIds(r'\se[ItemGet]Valeur \v[3]'), {3});
    expect(sourceDialogueVariableIds(r'\\v[2]\se[ItemGet]Puis \v[4]'), {4});
  });

  test('source audio refuses missing binding and unsupported pitch distinctly',
      () {
    for (final entry in {
      r'A\se[Missing]B': 'sourceTextAudioBindingMissing',
      r'A\se[ItemGet:80:120]B': 'sourceTextAudioPitchUnsupported',
      r'A\se[ItemGet:80:100:90]B': 'sourceTextAudioControlMalformed',
      r'A\se[ItemGet,80,100]B': 'sourceTextAudioBindingMissing',
      r'A\se[ItemGet:-1]B': 'sourceTextAudioControlMalformed',
      r'A\se[ItemGet:101]B': 'sourceTextAudioControlMalformed',
      r'A\se[ItemGet]B\se[ItemGet]':
          'sourceTextAudioCueMultiplicityUnsupported',
    }.entries) {
      final reasons = <String>[];
      expect(
          parseSourceDialogueText(entry.key,
              soundEffect: resolve, onRefusal: reasons.add),
          isNull,
          reason: entry.key);
      expect(reasons, contains(entry.value), reason: entry.key);
    }
  });

  test('unrepresented source controls retain capability specific refusals', () {
    for (final entry in {
      r'\sign[signskin]Panneau': 'sourceTextWindowAnimationUnsupported',
      r'A\wt[20]B': 'sourceTextMidRevealWaitUnsupported',
      r'A\GB': 'sourceTextGoldWindowUnsupported',
      r'A\CNB': 'sourceTextCoinWindowUnsupported',
      r'A\ch[1,0,Oui,Non]': 'sourceTextInlineChoiceUnsupported',
      r'\me[ItemGet]A': 'sourceTextMusicEffectUnsupported',
      r'A\1B': 'sourceTextPauseControlUnsupported',
      r'A\wtnp': 'sourceTextControlMalformed',
    }.entries) {
      final reasons = <String>[];
      expect(
          parseSourceDialogueText(entry.key,
              soundEffect: resolve, onRefusal: reasons.add),
          isNull);
      expect(reasons, contains(entry.value), reason: entry.key);
    }
  });

  test('source sound binding cannot change cue position or role', () {
    expect(
        parseSourceDialogueText(r'A\se[ItemGet]B',
            soundEffect: (name, volume, pitch, offset) => DialogueAudioCue(
                mediaAssetId: 'sound', cueId: 'wrong-position')),
        isNull);
    expect(
        parseSourceDialogueText(r'\se[ItemGet]B',
            soundEffect: (name, volume, pitch, offset) => DialogueAudioCue(
                mediaAssetId: 'sound',
                cueId: 'music',
                role: DialogueAudioCueRole.musicEffect)),
        isNull);
  });
}
