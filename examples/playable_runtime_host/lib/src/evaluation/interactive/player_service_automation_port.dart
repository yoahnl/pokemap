import '../driver/evaluation_driver.dart';

enum PlayerServiceAutomationKind {
  shop,
  heal,
  pc,
}

enum PlayerServiceAutomationFailure {
  noActiveService,
  wrongService,
  busy,
  invalidRequest,
  rejected,
}

final class PlayerServiceAutomationResult {
  const PlayerServiceAutomationResult.success({
    this.details = const <String, Object?>{},
  })  : completed = true,
        failure = null,
        message = null;

  const PlayerServiceAutomationResult.failed({
    required this.failure,
    required this.message,
    this.details = const <String, Object?>{},
  }) : completed = false;

  final bool completed;
  final PlayerServiceAutomationFailure? failure;
  final String? message;
  final Map<String, Object?> details;
}

final class PlayerServiceAutomationException implements Exception {
  const PlayerServiceAutomationException({
    required this.failure,
    required this.message,
  });

  final PlayerServiceAutomationFailure failure;
  final String message;

  @override
  String toString() =>
      'PlayerServiceAutomationException(${failure.name}): $message';
}

sealed class PlayerServiceAutomationCommand {
  const PlayerServiceAutomationCommand();

  PlayerServiceAutomationKind get kind;
}

final class InspectShopAutomationCommand
    extends PlayerServiceAutomationCommand {
  const InspectShopAutomationCommand();

  @override
  PlayerServiceAutomationKind get kind => PlayerServiceAutomationKind.shop;
}

final class BuyShopItemAutomationCommand
    extends PlayerServiceAutomationCommand {
  const BuyShopItemAutomationCommand({
    required this.itemId,
    required this.quantity,
  });

  final String itemId;
  final int quantity;

  @override
  PlayerServiceAutomationKind get kind => PlayerServiceAutomationKind.shop;
}

final class CloseShopAutomationCommand extends PlayerServiceAutomationCommand {
  const CloseShopAutomationCommand();

  @override
  PlayerServiceAutomationKind get kind => PlayerServiceAutomationKind.shop;
}

final class ConfirmHealAutomationCommand
    extends PlayerServiceAutomationCommand {
  const ConfirmHealAutomationCommand();

  @override
  PlayerServiceAutomationKind get kind => PlayerServiceAutomationKind.heal;
}

final class CloseHealAutomationCommand extends PlayerServiceAutomationCommand {
  const CloseHealAutomationCommand();

  @override
  PlayerServiceAutomationKind get kind => PlayerServiceAutomationKind.heal;
}

final class WithdrawPcPokemonAutomationCommand
    extends PlayerServiceAutomationCommand {
  const WithdrawPcPokemonAutomationCommand({required this.pokemonId});

  final String pokemonId;

  @override
  PlayerServiceAutomationKind get kind => PlayerServiceAutomationKind.pc;
}

final class DepositPcPokemonAutomationCommand
    extends PlayerServiceAutomationCommand {
  const DepositPcPokemonAutomationCommand({required this.pokemonId});

  final String pokemonId;

  @override
  PlayerServiceAutomationKind get kind => PlayerServiceAutomationKind.pc;
}

final class ClosePcAutomationCommand extends PlayerServiceAutomationCommand {
  const ClosePcAutomationCommand();

  @override
  PlayerServiceAutomationKind get kind => PlayerServiceAutomationKind.pc;
}

abstract interface class PlayerServiceAutomationSession {
  PlayerServiceAutomationKind get kind;

  Future<PlayerServiceAutomationResult> invoke(
    PlayerServiceAutomationCommand command,
  );
}

/// A development-only, typed command port for the single visible player
/// service overlay.
///
/// It deliberately exposes neither widget keys nor coordinates. Collision
/// visualization is also outside this API and remains disabled by the host.
final class PlayerServiceAutomationPort
    implements EvaluationPlayerServiceAutomation {
  PlayerServiceAutomationSession? _active;

  PlayerServiceAutomationKind? get activeService => _active?.kind;

  void register(PlayerServiceAutomationSession session) {
    final active = _active;
    if (identical(active, session)) return;
    if (active != null) {
      throw StateError(
        'A ${active.kind.name} player service is already active.',
      );
    }
    _active = session;
  }

  void unregister(PlayerServiceAutomationSession session) {
    if (identical(_active, session)) {
      _active = null;
    }
  }

  Future<PlayerServiceAutomationResult> execute(
    PlayerServiceAutomationCommand command,
  ) async {
    final active = _active;
    if (active == null) {
      return const PlayerServiceAutomationResult.failed(
        failure: PlayerServiceAutomationFailure.noActiveService,
        message: 'No player service overlay is active.',
      );
    }
    if (active.kind != command.kind) {
      return PlayerServiceAutomationResult.failed(
        failure: PlayerServiceAutomationFailure.wrongService,
        message:
            'The active ${active.kind.name} service cannot run a ${command.kind.name} command.',
      );
    }
    return active.invoke(command);
  }

  Future<PlayerServiceAutomationResult> inspect() =>
      execute(const InspectShopAutomationCommand());

  Future<PlayerServiceAutomationResult> buyItem({
    required String itemId,
    required int quantity,
  }) =>
      execute(
        BuyShopItemAutomationCommand(itemId: itemId, quantity: quantity),
      );

  Future<PlayerServiceAutomationResult> heal() =>
      execute(const ConfirmHealAutomationCommand());

  Future<PlayerServiceAutomationResult> withdraw({
    required String pokemonId,
  }) =>
      execute(WithdrawPcPokemonAutomationCommand(pokemonId: pokemonId));

  Future<PlayerServiceAutomationResult> deposit({
    required String pokemonId,
  }) =>
      execute(DepositPcPokemonAutomationCommand(pokemonId: pokemonId));

  Future<PlayerServiceAutomationResult> closeActive() {
    return switch (activeService) {
      PlayerServiceAutomationKind.shop =>
        execute(const CloseShopAutomationCommand()),
      PlayerServiceAutomationKind.heal =>
        execute(const CloseHealAutomationCommand()),
      PlayerServiceAutomationKind.pc =>
        execute(const ClosePcAutomationCommand()),
      null => Future<PlayerServiceAutomationResult>.value(
          const PlayerServiceAutomationResult.failed(
            failure: PlayerServiceAutomationFailure.noActiveService,
            message: 'No player service overlay is active.',
          ),
        ),
    };
  }

  @override
  Future<void> inspectShop() async {
    _requireSuccess(await inspect());
  }

  @override
  Future<void> buy(String itemId, int quantity) async {
    _requireSuccess(await buyItem(itemId: itemId, quantity: quantity));
  }

  @override
  Future<void> healParty() async {
    _requireSuccess(await heal());
  }

  @override
  Future<void> withdrawFromPc(String pokemonId) async {
    _requireSuccess(await withdraw(pokemonId: pokemonId));
  }

  void _requireSuccess(PlayerServiceAutomationResult result) {
    if (result.completed) return;
    throw PlayerServiceAutomationException(
      failure: result.failure ?? PlayerServiceAutomationFailure.rejected,
      message: result.message ?? 'The interactive player service failed.',
    );
  }
}
