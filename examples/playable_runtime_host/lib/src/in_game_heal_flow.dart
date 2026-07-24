import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

import 'evaluation/interactive/player_service_automation_port.dart';

typedef PlayerServiceRecoveryCaps = RuntimePlayerServiceRecoveryCaps;

typedef InGameHealStateCommit = Future<void> Function(GameState state);
typedef InGameHealAutomationClose = Future<void> Function();

class InGameHealFlow extends StatefulWidget {
  const InGameHealFlow({
    super.key,
    required this.gameState,
    required this.recoveryCaps,
    required this.onStateCommitted,
    this.automationPort,
    this.onAutomationClose,
  });

  final GameState gameState;
  final PlayerServiceRecoveryCaps recoveryCaps;
  final InGameHealStateCommit onStateCommitted;
  final PlayerServiceAutomationPort? automationPort;
  final InGameHealAutomationClose? onAutomationClose;

  @override
  State<InGameHealFlow> createState() => _InGameHealFlowState();
}

class _InGameHealFlowState extends State<InGameHealFlow> {
  static const _mutations = GameStateMutations();

  late GameState _gameState = widget.gameState;
  bool _busy = false;
  String? _feedback;
  bool _feedbackIsError = false;
  late final _HealAutomationSession _automationSession =
      _HealAutomationSession(this);

  @override
  void initState() {
    super.initState();
    widget.automationPort?.register(_automationSession);
  }

  @override
  void didUpdateWidget(covariant InGameHealFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.automationPort, oldWidget.automationPort)) {
      oldWidget.automationPort?.unregister(_automationSession);
      widget.automationPort?.register(_automationSession);
    }
    if (widget.gameState != oldWidget.gameState) {
      _gameState = widget.gameState;
    }
  }

  @override
  void dispose() {
    widget.automationPort?.unregister(_automationSession);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListView(
        key: const Key('in-game-heal-flow'),
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Centre Pokémon',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Restaurer les PV, les PP et les altérations de statut.'),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                if (_gameState.party.members.isEmpty)
                  const ListTile(title: Text('Aucun Pokémon dans l’équipe.'))
                else
                  for (var index = 0;
                      index < _gameState.party.members.length;
                      index++)
                    ListTile(
                      key: Key('heal-party-member-$index'),
                      title: Text(_gameState.party.members[index].speciesId),
                      subtitle: Wrap(
                        spacing: 8,
                        children: [
                          Text(
                              'PV ${_gameState.party.members[index].currentHp}'),
                          Text(
                            'Statut ${_gameState.party.members[index].statusId.isEmpty ? 'aucun' : _gameState.party.members[index].statusId}',
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('heal-party-button'),
            onPressed: _busy || _gameState.party.members.isEmpty ? null : _heal,
            icon: const Icon(Icons.healing),
            label: Text(_busy ? 'Soin en cours…' : 'Soigner l’équipe'),
          ),
          if (_feedback != null) ...[
            const SizedBox(height: 12),
            Text(
              _feedback!,
              key: const Key('heal-feedback'),
              style: TextStyle(
                color: _feedbackIsError
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<PlayerServiceAutomationResult> _heal() async {
    if (_busy) {
      return const PlayerServiceAutomationResult.failed(
        failure: PlayerServiceAutomationFailure.busy,
        message: 'The healing service is already busy.',
      );
    }
    if (_gameState.party.members.isEmpty) {
      return const PlayerServiceAutomationResult.failed(
        failure: PlayerServiceAutomationFailure.invalidRequest,
        message: 'The party is empty.',
      );
    }
    final nextState = _mutations.recoverParty(
      _gameState,
      maxHpByPartyIndex: widget.recoveryCaps.maxHpByPartyIndex,
      maxPpByPartyIndex: widget.recoveryCaps.maxPpByPartyIndex,
    );
    if (identical(nextState, _gameState)) {
      setState(() {
        _feedbackIsError = false;
        _feedback = 'Votre équipe est déjà entièrement soignée.';
      });
      return const PlayerServiceAutomationResult.success(
        details: <String, Object?>{'alreadyHealed': true},
      );
    }
    setState(() => _busy = true);
    try {
      await widget.onStateCommitted(nextState);
      if (!mounted) {
        return const PlayerServiceAutomationResult.failed(
          failure: PlayerServiceAutomationFailure.rejected,
          message: 'The healing overlay closed before commit completed.',
        );
      }
      setState(() {
        _gameState = nextState;
        _busy = false;
        _feedbackIsError = false;
        _feedback = 'Votre équipe est entièrement soignée.';
      });
      return const PlayerServiceAutomationResult.success();
    } catch (error) {
      if (!mounted) {
        return PlayerServiceAutomationResult.failed(
          failure: PlayerServiceAutomationFailure.rejected,
          message: 'The healing overlay closed after a failed commit: $error',
        );
      }
      setState(() {
        _busy = false;
        _feedbackIsError = true;
        _feedback = 'Échec du soin : $error';
      });
      return PlayerServiceAutomationResult.failed(
        failure: PlayerServiceAutomationFailure.rejected,
        message: 'Healing could not be committed: $error',
      );
    }
  }

  Future<PlayerServiceAutomationResult> _closeFromAutomation() async {
    final close = widget.onAutomationClose;
    if (close == null) {
      return const PlayerServiceAutomationResult.failed(
        failure: PlayerServiceAutomationFailure.invalidRequest,
        message: 'The healing overlay cannot be closed by automation.',
      );
    }
    await close();
    return const PlayerServiceAutomationResult.success();
  }
}

final class _HealAutomationSession implements PlayerServiceAutomationSession {
  const _HealAutomationSession(this.owner);

  final _InGameHealFlowState owner;

  @override
  PlayerServiceAutomationKind get kind => PlayerServiceAutomationKind.heal;

  @override
  Future<PlayerServiceAutomationResult> invoke(
    PlayerServiceAutomationCommand command,
  ) =>
      switch (command) {
        ConfirmHealAutomationCommand() => owner._heal(),
        CloseHealAutomationCommand() => owner._closeFromAutomation(),
        _ => Future<PlayerServiceAutomationResult>.value(
            const PlayerServiceAutomationResult.failed(
              failure: PlayerServiceAutomationFailure.wrongService,
              message: 'The command does not belong to the Heal service.',
            ),
          ),
      };
}
