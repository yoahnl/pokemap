import 'package:map_core/map_core.dart';

import 'items/bag_operation_result.dart';
import 'items/bag_operations.dart';
import 'items/item_catalog_snapshot.dart';

enum PeriodicRewardFailure {
  calendarUninitialized,
  calendarChanged,
  calendarInconsistent,
  revisionConflict,
  alreadyClaimed,
  unknownItem,
  quantityOverflow,
  bagFull,
}

final class PeriodicRewardResult {
  const PeriodicRewardResult({required this.state, this.failure});

  final GameState state;
  final PeriodicRewardFailure? failure;
  bool get isSuccess => failure == null;
}

final class PeriodicRewardOperations {
  const PeriodicRewardOperations();

  PeriodicRewardResult claim(
    GameState state, {
    required PeriodicItemRewardDefinition definition,
    required int expectedRewardRevision,
    required GameplayCalendarState expectedCalendar,
    required ItemCatalogSnapshot itemCatalog,
    ProjectBagCapacity bagCapacity = const ProjectBagCapacity.unlimited(),
  }) {
    PeriodicRewardResult refuse(PeriodicRewardFailure failure) =>
        PeriodicRewardResult(state: state, failure: failure);
    final previous = state.periodicRewardState.claimFor(definition.rewardId);
    final revision = previous?.revision ?? 0;
    if (revision != expectedRewardRevision) {
      return refuse(PeriodicRewardFailure.revisionConflict);
    }
    final calendar = state.gameplayCalendarState;
    if (calendar != expectedCalendar) {
      return refuse(PeriodicRewardFailure.calendarChanged);
    }
    final day = calendar.observedLocalDay;
    if (day == null) return refuse(PeriodicRewardFailure.calendarUninitialized);
    if (previous != null) {
      if (calendar.dayRevision < previous.lastClaimDayRevision) {
        return refuse(PeriodicRewardFailure.calendarInconsistent);
      }
      if (calendar.dayRevision == previous.lastClaimDayRevision ||
          GameplayCalendarState.localDayNumber(day) <=
              GameplayCalendarState.localDayNumber(
                  previous.lastClaimLocalDay)) {
        return refuse(PeriodicRewardFailure.alreadyClaimed);
      }
    }
    if (revision == GameplayCalendarState.maximumRevision) {
      return refuse(PeriodicRewardFailure.quantityOverflow);
    }
    if (itemCatalog.definitionFor(definition.itemId) == null) {
      return refuse(PeriodicRewardFailure.unknownItem);
    }
    final given = const BagOperations().give(BagGiveRequest(
      bag: state.bag,
      itemId: definition.itemId,
      quantity: definition.quantity,
      capacity: bagCapacity,
      itemCatalog: itemCatalog,
    ));
    if (!given.isSuccess) {
      return refuse(switch (given.failure!) {
        BagOperationFailure.pocketFull ||
        BagOperationFailure.stackFull =>
          PeriodicRewardFailure.bagFull,
        BagOperationFailure.quantityOverflow =>
          PeriodicRewardFailure.quantityOverflow,
        _ => PeriodicRewardFailure.unknownItem,
      });
    }
    return PeriodicRewardResult(
        state: state.copyWith(
      bag: given.bag,
      periodicRewardState: state.periodicRewardState.withClaim(
        definition.rewardId,
        PeriodicRewardClaim(
          revision: revision + 1,
          lastClaimDayRevision: calendar.dayRevision,
          lastClaimLocalDay: day,
        ),
      ),
    ));
  }
}
