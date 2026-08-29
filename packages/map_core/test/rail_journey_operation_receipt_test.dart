import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('rail operation bindings round-trip every payload field', () {
    const binding = RailJourneyOperationBinding(
      kind: RailJourneyOperationKind.destinationDoorUsed,
      journeyId: 'T1',
      direction: RailJourneyDirection.outbound,
      doorSide: RailJourneyDoorSide.east,
    );

    expect(RailJourneyOperationBinding.fromJson(binding.toJson()), binding);
  });

  test('rail progress persists earned stamps and typed grant receipts', () {
    const progress = RailJourneyProgress(
      earnedStampIds: <String>{'hanazuki_stamp'},
      appliedProgressionOperations: <String, RailProgressionOperationBinding>{
        'scene:hanazuki:run-1:stamp': RailProgressionOperationBinding(
          kind: RailProgressionOperationKind.grantStamp,
          semanticId: 'hanazuki_stamp',
        ),
        'scene:hanazuki:run-1:tokens': RailProgressionOperationBinding(
          kind: RailProgressionOperationKind.grantCurrency,
          semanticId: 'line_tokens',
          amount: 3,
        ),
      },
    );

    final restored = GameState.fromJson(
      const GameState(
        saveId: 'rail-progress',
        railJourneyProgress: progress,
      ).toJson(),
    );

    expect(restored.railJourneyProgress, progress.validated());
  });

  test('rail progression consequences have canonical JSON payloads', () {
    final currency = SceneConsequence.grantRailCurrency(
      semanticCurrencyId: 'line_tokens',
      amount: 3,
    );
    final stamp = SceneConsequence.grantRailStamp(stampId: 'hanazuki_stamp');

    expect(SceneConsequence.fromJson(currency.toJson()), currency);
    expect(SceneConsequence.fromJson(stamp.toJson()), stamp);
    expect(currency.kind, SceneConsequenceKind.grantRailCurrency);
    expect(stamp.kind, SceneConsequenceKind.grantRailStamp);
  });
}
