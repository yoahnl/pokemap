part of 'player_service_runtime_controller.dart';

String runtimeCivilDay(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

extension RuntimeDeferredCraftingService on PlayerServiceRuntimeController {
  Future<PlayerServiceRuntimeResult> openCrafting({
    required OpenCraftingService request,
  }) async {
    if (_disposed) {
      return PlayerServiceRuntimeResult.failed(
        StateError('Player service disposed.'),
      );
    }
    if (_commitCraftingAndSave == null) {
      return const PlayerServiceRuntimeResult.unavailable(
        'Cet atelier nécessite une sauvegarde durable fournie par le Player.',
      );
    }
    if (_active || _pauseBagMutationBusy) {
      return const PlayerServiceRuntimeResult.busy();
    }
    final initial = _currentGameState();
    final denied = _worldRequestUnavailableReason(request, initial);
    if (denied != null) return PlayerServiceRuntimeResult.unavailable(denied);
    final session = _ContextualCraftingSession(request, initial);
    _craftingSession = session;
    _active = true;
    var locked = false;
    try {
      _setInputLocked(true);
      locked = true;
      session.catalog = await _resolveItemCatalog();
      if (!_craftingContinues(session)) return await session.result.future;
      if (_currentGameState() != initial) {
        throw StateError('Inventory changed while opening crafting.');
      }
      if (request.definition.recipes.any(
        (recipe) =>
            session.catalog.definitionFor(recipe.inputItemId) == null ||
            session.catalog.definitionFor(recipe.outputItemId) == null,
      )) {
        throw StateError('Crafting references unknown items.');
      }
      session.observedState = observeGameplayCalendar(
        initial,
        localDay: runtimeCivilDay(_civilNow()),
      );
      _publishCrafting(session);
      return await session.result.future;
    } catch (error) {
      return PlayerServiceRuntimeResult.failed(error);
    } finally {
      if (identical(_craftingSession, session)) {
        _craftingSession = null;
        _publishWorldService(null);
      }
      if (locked) _setInputLocked(false);
      _active = false;
    }
  }

  bool _craftingContinues(_ContextualCraftingSession session) =>
      !_disposed &&
      identical(_craftingSession, session) &&
      !session.result.isCompleted;

  void _publishCrafting(
    _ContextualCraftingSession session, {
    RuntimeWorldServiceStage stage = RuntimeWorldServiceStage.active,
  }) {
    if (!_craftingContinues(session)) return;
    final definition = session.request.definition;
    final inspection = const DeferredCraftingOperations().inspect(
      session.observedState,
      serviceId: definition.serviceId,
    );
    final order = inspection.service.pendingOrder;
    final selected = definition.recipeFor(session.selectedRecipeId ?? '');
    final owned = selected == null
        ? 0
        : const BagOperations().quantityOf(
            session.observedState.bag,
            selected.inputItemId,
          );
    final maximum = selected == null
        ? 0
        : (owned ~/ selected.inputQuantity).clamp(
            0,
            definition.maximumBatchQuantity,
          );
    _craftingRevision =
        ((_worldServiceSnapshot?.revision ?? -1) > _craftingRevision
            ? _worldServiceSnapshot!.revision
            : _craftingRevision) +
        1;
    final applying = stage == RuntimeWorldServiceStage.applying;
    final completed = stage == RuntimeWorldServiceStage.completed;
    _publishWorldService(
      RuntimeWorldServiceSnapshot(
        revision: _craftingRevision,
        request: session.request,
        stage: stage,
        content: RuntimeCraftingServiceContent(
          title: definition.label,
          status: RuntimeCraftingStatus.values.byName(inspection.status.name),
          quantity: session.quantity,
          maximumQuantity: maximum,
          reviewing: session.reviewing,
          selectedRecipeId: session.selectedRecipeId,
          message: session.message,
          pendingOutputLabel: order == null
              ? null
              : session.catalog
                        .definitionFor(order.outputItemId)
                        ?.displayName ??
                    order.outputItemId,
          pendingOutputQuantity: order?.outputQuantity,
          recipes: [
            for (final recipe in definition.recipes)
              RuntimeCraftingRecipeSnapshot(
                recipeId: recipe.recipeId,
                label: recipe.label,
                inputLabel: session.catalog
                    .definitionFor(recipe.inputItemId)!
                    .displayName,
                outputLabel: session.catalog
                    .definitionFor(recipe.outputItemId)!
                    .displayName,
                inputQuantity: recipe.inputQuantity,
                outputQuantity: recipe.outputQuantity,
                ownedQuantity: const BagOperations().quantityOf(
                  session.observedState.bag,
                  recipe.inputItemId,
                ),
              ),
          ],
        ),
        actions: applying
            ? const []
            : completed
            ? const [
                RuntimeWorldServiceActionAvailability.enabled(
                  RuntimeWorldServiceAction.close,
                ),
              ]
            : [
                const RuntimeWorldServiceActionAvailability.enabled(
                  RuntimeWorldServiceAction.cancel,
                ),
                if (inspection.status == DeferredCraftingStatus.idle) ...[
                  const RuntimeWorldServiceActionAvailability.enabled(
                    RuntimeWorldServiceAction.select,
                  ),
                  if (!session.reviewing && selected != null) ...[
                    if (session.quantity > 1)
                      const RuntimeWorldServiceActionAvailability.enabled(
                        RuntimeWorldServiceAction.decreaseQuantity,
                      ),
                    if (session.quantity < maximum)
                      const RuntimeWorldServiceActionAvailability.enabled(
                        RuntimeWorldServiceAction.increaseQuantity,
                      ),
                  ],
                  if (selected != null && session.quantity <= maximum)
                    const RuntimeWorldServiceActionAvailability.enabled(
                      RuntimeWorldServiceAction.confirm,
                    ),
                ],
                if (inspection.status == DeferredCraftingStatus.ready)
                  const RuntimeWorldServiceActionAvailability.enabled(
                    RuntimeWorldServiceAction.confirm,
                  ),
              ],
      ),
    );
  }

  Future<RuntimeWorldServiceCommandResult> _dispatchCrafting(
    _ContextualCraftingSession session,
    RuntimeWorldServiceCommand command,
  ) async {
    const accepted = RuntimeWorldServiceCommandResult(
      status: RuntimeWorldServiceCommandStatus.accepted,
    );
    const stale = RuntimeWorldServiceCommandResult(
      status: RuntimeWorldServiceCommandStatus.stale,
    );
    if (!_craftingContinues(session) || session.pendingCommit != null) {
      return stale;
    }
    if (command.action == RuntimeWorldServiceAction.cancel ||
        command.action == RuntimeWorldServiceAction.close) {
      session.result.complete(
        session.completedState == null
            ? const PlayerServiceRuntimeResult.cancelled()
            : PlayerServiceRuntimeResult.completed(session.completedState!),
      );
      return accepted;
    }
    if (_currentGameState() != session.initialState) {
      session.message = 'Le sac a changé. Fermez puis rouvrez l’atelier.';
      _publishCrafting(session);
      return stale;
    }
    final definition = session.request.definition;
    if (command.action == RuntimeWorldServiceAction.select) {
      if (definition.recipeFor(command.targetId ?? '') == null) {
        return const RuntimeWorldServiceCommandResult(
          status: RuntimeWorldServiceCommandStatus.unavailable,
        );
      }
      session.selectedRecipeId = command.targetId;
      session.quantity = 1;
      session.reviewing = false;
      session.message = null;
      _publishCrafting(session);
      return accepted;
    }
    if (command.action == RuntimeWorldServiceAction.increaseQuantity ||
        command.action == RuntimeWorldServiceAction.decreaseQuantity) {
      session.quantity +=
          command.action == RuntimeWorldServiceAction.increaseQuantity ? 1 : -1;
      _publishCrafting(session);
      return accepted;
    }
    if (command.action != RuntimeWorldServiceAction.confirm) {
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.unavailable,
      );
    }
    final observed = observeGameplayCalendar(
      session.initialState,
      localDay: runtimeCivilDay(_civilNow()),
    );
    final inspection = const DeferredCraftingOperations().inspect(
      observed,
      serviceId: definition.serviceId,
    );
    if (inspection.status == DeferredCraftingStatus.idle &&
        !session.reviewing) {
      session.reviewing = true;
      session.message = 'Confirmer le dépôt des ingrédients ?';
      _publishCrafting(session);
      return accepted;
    }
    final selected = definition.recipeFor(session.selectedRecipeId ?? '');
    final result = inspection.status == DeferredCraftingStatus.ready
        ? const DeferredCraftingOperations().collect(
            observed,
            serviceId: definition.serviceId,
            expectedServiceRevision: inspection.service.revision,
            expectedOrderId: inspection.service.pendingOrder!.orderId,
            itemCatalog: session.catalog,
            bagCapacity: bagCapacity,
          )
        : const DeferredCraftingOperations().deposit(
            observed,
            definition: definition,
            recipeId: selected?.recipeId ?? '',
            batchQuantity: session.quantity,
            expectedServiceRevision: inspection.service.revision,
            expectedInputQuantity: selected == null
                ? 0
                : const BagOperations().quantityOf(
                    session.observedState.bag,
                    selected.inputItemId,
                  ),
            itemCatalog: session.catalog,
          );
    if (!result.isSuccess) {
      session.message = result.failure == DeferredCraftingFailure.bagFull
          ? 'Le sac est plein. Votre commande reste disponible.'
          : result.failure == DeferredCraftingFailure.protectedIngredient
          ? 'Cet objet important ne peut pas servir d’ingrédient.'
          : 'Cette fabrication est indisponible.';
      session.observedState = observed;
      _publishCrafting(session);
      return RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.unavailable,
        safeMessage: session.message,
      );
    }
    _publishCrafting(session, stage: RuntimeWorldServiceStage.applying);
    session.pendingState = result.state;
    try {
      session.pendingCommit = Future<void>.sync(
        () => _commitCraftingAndSave!(result.state),
      );
      await session.pendingCommit;
      session.completedState = result.state;
      session.observedState = result.state;
      session.message = inspection.status == DeferredCraftingStatus.ready
          ? 'Commande récupérée.'
          : 'Commande enregistrée. Revenez un prochain jour.';
      if (_disposed) {
        if (!session.result.isCompleted) {
          session.result.complete(
            PlayerServiceRuntimeResult.completed(result.state),
          );
        }
      } else if (_craftingContinues(session)) {
        _publishCrafting(session, stage: RuntimeWorldServiceStage.completed);
      }
      return accepted;
    } catch (error) {
      session.message =
          'La sauvegarde a échoué. Votre sac et votre commande sont conservés.';
      if (_disposed) {
        if (!session.result.isCompleted) {
          session.result.complete(PlayerServiceRuntimeResult.failed(error));
        }
      } else if (_craftingContinues(session)) {
        _publishCrafting(session, stage: RuntimeWorldServiceStage.failed);
      }
      return RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.failed,
        safeMessage: session.message,
      );
    } finally {
      session.pendingCommit = null;
    }
  }

  Future<void> _disposeCrafting() async {
    final session = _craftingSession;
    if (session == null || session.result.isCompleted) return;
    final pending = session.pendingCommit;
    if (pending != null) {
      try {
        await pending;
        if (!session.result.isCompleted) {
          session.result.complete(
            PlayerServiceRuntimeResult.completed(session.pendingState!),
          );
        }
      } catch (error) {
        if (!session.result.isCompleted) {
          session.result.complete(PlayerServiceRuntimeResult.failed(error));
        }
      }
    } else {
      session.result.complete(
        session.completedState == null
            ? const PlayerServiceRuntimeResult.cancelled()
            : PlayerServiceRuntimeResult.completed(session.completedState!),
      );
    }
  }
}

final class _ContextualCraftingSession {
  _ContextualCraftingSession(this.request, this.initialState)
    : observedState = initialState;
  final OpenCraftingService request;
  final GameState initialState;
  final result = Completer<PlayerServiceRuntimeResult>();
  late ItemCatalogSnapshot catalog;
  GameState observedState;
  String? selectedRecipeId, message;
  int quantity = 1;
  bool reviewing = false;
  Future<void>? pendingCommit;
  GameState? pendingState, completedState;
}
