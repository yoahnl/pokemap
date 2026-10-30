import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const operations = PeriodicRewardOperations();
  final definition = PeriodicItemRewardDefinition(
    rewardId: 'daily-fruit',
    label: 'Fruit',
    itemId: 'fruit',
    quantity: 2,
  );
  final catalog = ItemCatalogSnapshot.fromCatalog(const ProjectItemCatalog(
    schemaVersion: 1,
    entries: [
      ProjectItemDefinition(
          id: 'fruit', displayName: 'Fruit', pocketId: 'items'),
      ProjectItemDefinition(id: 'ball', displayName: 'Ball', pocketId: 'items'),
    ],
  ));
  GameState initial() =>
      observeGameplayCalendar(const GameState(saveId: 'reward-save'),
          localDay: '2026-10-30');
  PeriodicRewardResult claim(
    GameState state, {
    int? revision,
    GameplayCalendarState? calendar,
    PeriodicItemRewardDefinition? config,
    ProjectBagCapacity capacity = const ProjectBagCapacity.unlimited(),
  }) =>
      operations.claim(state,
          definition: config ?? definition,
          expectedRewardRevision: revision ??
              state.periodicRewardState
                  .claimFor((config ?? definition).rewardId)
                  ?.revision ??
              0,
          expectedCalendar: calendar ?? state.gameplayCalendarState,
          itemCatalog: catalog,
          bagCapacity: capacity);

  test(
      'claim grants configured quantity atomically once per civil day after Continue',
      () {
    final state = initial();
    final first = claim(state);
    expect(first.isSuccess, isTrue);
    expect(const BagOperations().quantityOf(first.state.bag, 'fruit'), 2);
    expect(
        first.state.periodicRewardState.claimFor('daily-fruit')!.revision, 1);
    expect(state.bag.entries, isEmpty);
    final restored =
        gameStateFromStrictSaveJson(strictGameStateSaveJson(first.state));
    final duplicate = claim(restored);
    expect(duplicate.failure, PeriodicRewardFailure.alreadyClaimed);
    expect(duplicate.state, same(restored));
    final tomorrow =
        claim(observeGameplayCalendar(restored, localDay: '2026-10-31'));
    expect(tomorrow.isSuccess, isTrue);
    expect(const BagOperations().quantityOf(tomorrow.state.bag, 'fruit'), 4);
  });

  test('clock rollback and returning to claimed date cannot duplicate a reward',
      () {
    final first = claim(initial()).state;
    final backwards = observeGameplayCalendar(first, localDay: '2026-10-29');
    expect(claim(backwards).failure, PeriodicRewardFailure.alreadyClaimed);
    final returned = observeGameplayCalendar(backwards, localDay: '2026-10-30');
    expect(returned.gameplayCalendarState.dayRevision,
        greaterThan(first.gameplayCalendarState.dayRevision));
    expect(claim(returned).failure, PeriodicRewardFailure.alreadyClaimed);
    expect(
        claim(observeGameplayCalendar(returned, localDay: '2026-10-31'))
            .isSuccess,
        isTrue);
  });

  test(
      'tomorrow then yesterday then tomorrow remains claimed until following day',
      () {
    final first =
        claim(observeGameplayCalendar(initial(), localDay: '2026-10-31')).state;
    final backwards = observeGameplayCalendar(first, localDay: '2026-10-30');
    final returned = observeGameplayCalendar(backwards, localDay: '2026-10-31');
    expect(claim(backwards).failure, PeriodicRewardFailure.alreadyClaimed);
    expect(claim(returned).failure, PeriodicRewardFailure.alreadyClaimed);
    final following =
        claim(observeGameplayCalendar(returned, localDay: '2026-11-01'));
    expect(following.isSuccess, isTrue);
    expect(const BagOperations().quantityOf(following.state.bag, 'fruit'), 4);
  });

  test('bag full does not consume eligibility and a later retry succeeds', () {
    final state = initial();
    final full = claim(state,
        capacity: const ProjectBagCapacity(pockets: {
          'items': BagPocketCapacity(maxQuantityPerItem: 1),
        }));
    expect(full.failure, PeriodicRewardFailure.bagFull);
    expect(full.state, same(state));
    expect(claim(full.state).isSuccess, isTrue);
  });

  test(
      'unknown item stale reward changed day and missing calendar refuse unchanged',
      () {
    final state = initial();
    final unknown = PeriodicItemRewardDefinition(
      rewardId: 'unknown',
      label: 'Unknown',
      itemId: 'missing',
      quantity: 1,
    );
    expect(claim(state, config: unknown).failure,
        PeriodicRewardFailure.unknownItem);
    expect(claim(state, revision: 1).failure,
        PeriodicRewardFailure.revisionConflict);
    expect(
        claim(observeGameplayCalendar(state, localDay: '2026-10-31'),
                calendar: state.gameplayCalendarState)
            .failure,
        PeriodicRewardFailure.calendarChanged);
    expect(claim(const GameState(saveId: 'reward-save')).failure,
        PeriodicRewardFailure.calendarUninitialized);
  });

  test('independent rewards do not share claims and revisions', () {
    final first = claim(initial()).state;
    final second = claim(first,
        config: PeriodicItemRewardDefinition(
          rewardId: 'daily-ball',
          label: 'Ball',
          itemId: 'ball',
          quantity: 3,
        ));
    expect(second.isSuccess, isTrue);
    expect(second.state.periodicRewardState.claimsById.length, 2);
    expect(const BagOperations().quantityOf(second.state.bag, 'ball'), 3);
  });

  test('quantity and claim revision overflow refuse without consuming the day',
      () {
    final state = initial().copyWith(
        bag: const Bag(entries: [
      BagEntry(itemId: 'fruit', quantity: maximumBagEntryQuantity),
    ]));
    expect(claim(state).failure, PeriodicRewardFailure.quantityOverflow);
    final exhausted =
        observeGameplayCalendar(initial(), localDay: '2026-10-31').copyWith(
      periodicRewardState: PeriodicRewardState(claimsById: {
        'daily-fruit': PeriodicRewardClaim(
            revision: GameplayCalendarState.maximumRevision,
            lastClaimDayRevision: 0,
            lastClaimLocalDay: '2026-10-30'),
      }),
    );
    expect(claim(exhausted).failure, PeriodicRewardFailure.quantityOverflow);
  });
}
