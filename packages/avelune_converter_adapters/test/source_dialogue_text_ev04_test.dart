import 'package:avelune_converter_adapters/src/source_dialogue_text.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
      'source text preserves literal escapes, player identity, colors and newlines',
      () {
    final parsed = parseSourceDialogueText(r'\bBonjour \pN.\\PN\nSuite');
    expect(parsed!.plainText, 'Bonjour {{ player_name }}.\\PN\nSuite');
    expect((parsed.segments.first as DialogueTextSegment).style!.colorArgb,
        0xff3050c8);
  });

  test('source leading cadence and final auto delay reuse native line policies',
      () {
    final parsed = parseSourceDialogueText(r'\ts[2]\rBravo!\wtnp[40]')!;
    expect(parsed.plainText, 'Bravo!');
    expect(parsed.revealIntervalMicros, 25000);
    expect(parsed.advance, DialogueLineAdvancePolicy.autoAfterReveal(2000000));
    expect(
        parseSourceDialogueText(r'\ts[]Instant\wtnp[0]')!.revealIntervalMicros,
        0);
  });

  test('source variable substitutions require an explicit typed binding', () {
    expect(parseSourceDialogueText(r'Valeur \v[3]'), isNull);
    expect(
        parseSourceDialogueText(r'Valeur \V[3]',
                variablePlaceholder: (id) =>
                    id == 3 ? '{{ fact.score }}' : null)!
            .plainText,
        'Valeur {{ fact.score }}');
    expect(
        parseSourceDialogueText(r'\v[0]',
            variablePlaceholder: (_) => '{{ fact.score }}'),
        isNull);
  });

  test('unrepresented controls fail closed rather than strip or retime text',
      () {
    for (final text in [
      r'Au\wt[20]milieu',
      r'A\ts[2]B',
      r'A\wtnp[40]B',
      r'A\wtnp[-1]',
      r'A\wtnp[1201]',
      r'\ts[321]A',
      r'\n[1]',
      r'\se[sound]A',
      r'<b>A</b>',
      r'A\'
    ]) {
      expect(parseSourceDialogueText(text), isNull, reason: text);
    }
  });
}
