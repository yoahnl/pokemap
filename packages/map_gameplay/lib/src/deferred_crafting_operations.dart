import 'package:map_core/map_core.dart';

import 'items/bag_operation_result.dart';
import 'items/bag_operations.dart';
import 'items/item_catalog_snapshot.dart';

enum DeferredCraftingFailure {
  invalidQuantity,
  unknownRecipe,
  unknownItem,
  calendarUninitialized,
  calendarInconsistent,
  revisionConflict,
  orderAlreadyPending,
  inventoryChanged,
  insufficientIngredients,
  protectedIngredient,
  quantityOverflow,
  noPendingOrder,
  orderMismatch,
  orderNotReady,
  bagFull,
}

enum DeferredCraftingStatus { idle, working, ready }

final class DeferredCraftingInspection {
  const DeferredCraftingInspection({
    required this.service,
    required this.status,
  });

  final DeferredCraftingServiceState service;
  final DeferredCraftingStatus status;
}

final class DeferredCraftingResult {
  const DeferredCraftingResult({
    required this.state,
    this.failure,
    this.order,
  });

  final GameState state;
  final DeferredCraftingFailure? failure;
  final DeferredCraftingOrder? order;
  bool get isSuccess => failure == null;
}

final class DeferredCraftingOperations {
  const DeferredCraftingOperations();

  DeferredCraftingInspection inspect(GameState state,
      {required String serviceId}) {
    final service = state.deferredCraftingState.serviceFor(serviceId);
    final order = service.pendingOrder;
    final calendar = state.gameplayCalendarState;
    if (order != null &&
        (!calendar.isInitialized ||
            calendar.dayRevision < order.submittedDayRevision)) {
      throw const FormatException(
          'Crafting order has an inconsistent calendar.');
    }
    return DeferredCraftingInspection(
      service: service,
      status: order == null
          ? DeferredCraftingStatus.idle
          : calendar.dayRevision - order.submittedDayRevision >=
                  order.requiredDayChanges
              ? DeferredCraftingStatus.ready
              : DeferredCraftingStatus.working,
    );
  }

  DeferredCraftingResult deposit(
    GameState state, {
    required DeferredCraftingDefinition definition,
    required String recipeId,
    required int batchQuantity,
    required int expectedServiceRevision,
    required int expectedInputQuantity,
    required ItemCatalogSnapshot itemCatalog,
  }) {
    DeferredCraftingResult refuse(DeferredCraftingFailure failure) =>
        DeferredCraftingResult(state: state, failure: failure);
    final service =
        state.deferredCraftingState.serviceFor(definition.serviceId);
    if (service.revision != expectedServiceRevision) {
      return refuse(DeferredCraftingFailure.revisionConflict);
    }
    if (service.pendingOrder != null) {
      return refuse(DeferredCraftingFailure.orderAlreadyPending);
    }
    if (batchQuantity <= 0 || batchQuantity > definition.maximumBatchQuantity) {
      return refuse(DeferredCraftingFailure.invalidQuantity);
    }
    final recipe = definition.recipeFor(recipeId);
    if (recipe == null) return refuse(DeferredCraftingFailure.unknownRecipe);
    final ingredient = itemCatalog.definitionFor(recipe.inputItemId);
    if (ingredient == null ||
        itemCatalog.definitionFor(recipe.outputItemId) == null) {
      return refuse(DeferredCraftingFailure.unknownItem);
    }
    final calendar = state.gameplayCalendarState;
    if (!calendar.isInitialized) {
      return refuse(DeferredCraftingFailure.calendarUninitialized);
    }
    if (service.revision > GameplayCalendarState.maximumRevision - 2 ||
        calendar.dayRevision >
            GameplayCalendarState.maximumRevision -
                definition.requiredDayChanges ||
        batchQuantity >
            maximumDeferredCraftingQuantity ~/ recipe.inputQuantity ||
        batchQuantity >
            maximumDeferredCraftingQuantity ~/ recipe.outputQuantity) {
      return refuse(DeferredCraftingFailure.quantityOverflow);
    }
    const bagOperations = BagOperations();
    final owned = bagOperations.quantityOf(state.bag, recipe.inputItemId);
    if (owned != expectedInputQuantity) {
      return refuse(DeferredCraftingFailure.inventoryChanged);
    }
    final taken = bagOperations.consume(BagConsumeRequest(
        bag: state.bag,
        itemId: recipe.inputItemId,
        quantity: batchQuantity * recipe.inputQuantity,
        itemTags: ingredient.tags,
        reason: ItemConsumptionReason.scriptedUse));
    if (!taken.isSuccess) {
      return refuse(taken.failure == BagOperationFailure.protectedKeyItem
          ? DeferredCraftingFailure.protectedIngredient
          : DeferredCraftingFailure.insufficientIngredients);
    }
    final revision = service.revision + 1;
    final order = DeferredCraftingOrder(
      orderId: '${definition.serviceId}:$revision',
      recipeId: recipe.recipeId,
      inputItemId: recipe.inputItemId,
      inputQuantity: batchQuantity * recipe.inputQuantity,
      outputItemId: recipe.outputItemId,
      outputQuantity: batchQuantity * recipe.outputQuantity,
      submittedDayRevision: calendar.dayRevision,
      requiredDayChanges: definition.requiredDayChanges,
    );
    return DeferredCraftingResult(
      state: state.copyWith(
          bag: taken.bag,
          deferredCraftingState: state.deferredCraftingState.withService(
              definition.serviceId,
              DeferredCraftingServiceState(
                  revision: revision, pendingOrder: order))),
      order: order,
    );
  }

  DeferredCraftingResult collect(
    GameState state, {
    required String serviceId,
    required int expectedServiceRevision,
    required String expectedOrderId,
    required ItemCatalogSnapshot itemCatalog,
    ProjectBagCapacity bagCapacity = const ProjectBagCapacity.unlimited(),
  }) {
    DeferredCraftingResult refuse(DeferredCraftingFailure failure) =>
        DeferredCraftingResult(state: state, failure: failure);
    final service = state.deferredCraftingState.serviceFor(serviceId);
    if (service.revision != expectedServiceRevision) {
      return refuse(DeferredCraftingFailure.revisionConflict);
    }
    final order = service.pendingOrder;
    if (order == null) return refuse(DeferredCraftingFailure.noPendingOrder);
    if (order.orderId != expectedOrderId) {
      return refuse(DeferredCraftingFailure.orderMismatch);
    }
    final calendar = state.gameplayCalendarState;
    if (!calendar.isInitialized ||
        calendar.dayRevision < order.submittedDayRevision) {
      return refuse(DeferredCraftingFailure.calendarInconsistent);
    }
    if (calendar.dayRevision - order.submittedDayRevision <
        order.requiredDayChanges) {
      return refuse(DeferredCraftingFailure.orderNotReady);
    }
    if (service.revision == GameplayCalendarState.maximumRevision) {
      return refuse(DeferredCraftingFailure.quantityOverflow);
    }
    if (itemCatalog.definitionFor(order.outputItemId) == null) {
      return refuse(DeferredCraftingFailure.unknownItem);
    }
    final given = const BagOperations().give(BagGiveRequest(
        bag: state.bag,
        itemId: order.outputItemId,
        quantity: order.outputQuantity,
        capacity: bagCapacity,
        itemCatalog: itemCatalog));
    if (!given.isSuccess) {
      return refuse(switch (given.failure!) {
        BagOperationFailure.pocketFull ||
        BagOperationFailure.stackFull =>
          DeferredCraftingFailure.bagFull,
        BagOperationFailure.quantityOverflow =>
          DeferredCraftingFailure.quantityOverflow,
        _ => DeferredCraftingFailure.unknownItem,
      });
    }
    return DeferredCraftingResult(
      state: state.copyWith(
          bag: given.bag,
          deferredCraftingState: state.deferredCraftingState.withService(
              serviceId,
              DeferredCraftingServiceState(revision: service.revision + 1))),
      order: order,
    );
  }
}
