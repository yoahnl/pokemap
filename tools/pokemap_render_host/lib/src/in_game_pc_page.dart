import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'evaluation/interactive/player_service_automation_port.dart';

typedef InGamePcStateCommit = Future<void> Function(GameState state);
typedef InGamePcAutomationClose = Future<void> Function();

class InGamePcPage extends StatefulWidget {
  const InGamePcPage({
    super.key,
    required this.gameState,
    required this.onStateCommitted,
    this.automationPort,
    this.onAutomationClose,
  });

  final GameState gameState;
  final InGamePcStateCommit onStateCommitted;
  final PlayerServiceAutomationPort? automationPort;
  final InGamePcAutomationClose? onAutomationClose;

  @override
  State<InGamePcPage> createState() => _InGamePcPageState();
}

class _InGamePcPageState extends State<InGamePcPage> {
  static const _operations = PlayerStorageOperations();

  late GameState _gameState = widget.gameState.copyWith(
    pokemonStorage: widget.gameState.pokemonStorage.normalized(),
  );
  late String _boxId = _gameState.pokemonStorage.boxes.first.id;
  bool _busy = false;
  String? _feedback;
  bool _feedbackIsError = false;
  late final _PcAutomationSession _automationSession =
      _PcAutomationSession(this);

  PokemonBox get _box =>
      _gameState.pokemonStorage.boxes.firstWhere((box) => box.id == _boxId);

  @override
  void initState() {
    super.initState();
    widget.automationPort?.register(_automationSession);
  }

  @override
  void didUpdateWidget(covariant InGamePcPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.automationPort, oldWidget.automationPort)) {
      oldWidget.automationPort?.unregister(_automationSession);
      widget.automationPort?.register(_automationSession);
    }
    if (widget.gameState != oldWidget.gameState) {
      _gameState = widget.gameState.copyWith(
        pokemonStorage: widget.gameState.pokemonStorage.normalized(),
      );
      if (!_gameState.pokemonStorage.boxes.any((box) => box.id == _boxId)) {
        _boxId = _gameState.pokemonStorage.boxes.first.id;
      }
    }
  }

  @override
  void dispose() {
    widget.automationPort?.unregister(_automationSession);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = _box;
    return Material(
      child: ListView(
        key: const Key('in-game-pc-page'),
        padding: const EdgeInsets.all(20),
        children: [
          Text('PC Pokémon', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const Key('pc-box-picker'),
            initialValue: box.id,
            decoration: const InputDecoration(labelText: 'Box'),
            items: _gameState.pokemonStorage.boxes
                .map(
                  (entry) => DropdownMenuItem<String>(
                    value: entry.id,
                    child: Text(
                      '${entry.label} · ${entry.pokemon.length}/${entry.capacity}',
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: _busy
                ? null
                : (id) => setState(() {
                      _boxId = id ?? _boxId;
                      _feedback = null;
                    }),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final party = _partyCard(context);
              final storage = _boxCard(context, box);
              if (constraints.maxWidth < 760) {
                return Column(
                    children: [party, const SizedBox(height: 16), storage]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: party),
                  const SizedBox(width: 16),
                  Expanded(child: storage),
                ],
              );
            },
          ),
          if (_feedback != null) ...[
            const SizedBox(height: 12),
            Text(
              _feedback!,
              key: const Key('pc-feedback'),
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

  Widget _partyCard(BuildContext context) => Card(
        child: Column(
          children: [
            const ListTile(title: Text('Équipe')),
            if (_gameState.party.members.isEmpty)
              const ListTile(title: Text('Équipe vide'))
            else
              for (var index = 0;
                  index < _gameState.party.members.length;
                  index++)
                ListTile(
                  key: Key('pc-party-$index'),
                  title: Text(_gameState.party.members[index].speciesId),
                  subtitle:
                      Text('Niv. ${_gameState.party.members[index].level}'),
                  trailing: TextButton(
                    key: Key('pc-deposit-party-$index'),
                    onPressed: _busy ? null : () => _deposit(index),
                    child: const Text('Déposer'),
                  ),
                ),
          ],
        ),
      );

  Widget _boxCard(BuildContext context, PokemonBox box) => Card(
        child: Column(
          children: [
            ListTile(title: Text(box.label)),
            if (box.pokemon.isEmpty)
              const ListTile(title: Text('Box vide'))
            else
              for (var index = 0; index < box.pokemon.length; index++)
                ListTile(
                  key: Key('pc-box-${box.id}-$index'),
                  title: Text(box.pokemon[index].speciesId),
                  subtitle: Text('Niv. ${box.pokemon[index].level}'),
                  trailing: _gameState.party.members.length < maxPlayerPartySize
                      ? TextButton(
                          key: Key('pc-withdraw-${box.id}-$index'),
                          onPressed:
                              _busy ? null : () => _withdraw(box.id, index),
                          child: const Text('Retirer'),
                        )
                      : TextButton(
                          key: Key('pc-swap-${box.id}-$index'),
                          onPressed:
                              _busy ? null : () => _swapLead(box.id, index),
                          child: const Text('Échanger avec le lead'),
                        ),
                ),
          ],
        ),
      );

  Future<PlayerServiceAutomationResult> _deposit(int partyIndex) => _apply(
        _operations.deposit(
          state: _gameState,
          partyIndex: partyIndex,
          boxId: _boxId,
        ),
        success: 'Pokémon déposé dans ${_box.label}.',
      );

  Future<PlayerServiceAutomationResult> _withdraw(
    String boxId,
    int boxIndex,
  ) =>
      _apply(
        _operations.withdraw(
          state: _gameState,
          boxId: boxId,
          boxIndex: boxIndex,
        ),
        success: 'Pokémon retiré de la box.',
      );

  Future<PlayerServiceAutomationResult> _swapLead(
    String boxId,
    int boxIndex,
  ) =>
      _apply(
        _operations.swapPartyWithBox(
          state: _gameState,
          partyIndex: 0,
          boxId: boxId,
          boxIndex: boxIndex,
        ),
        success: 'Pokémon échangé avec le lead.',
      );

  Future<PlayerServiceAutomationResult> _withdrawByPokemonId(
    String pokemonId,
  ) {
    for (final box in _gameState.pokemonStorage.boxes) {
      for (var index = 0; index < box.pokemon.length; index++) {
        if (box.pokemon[index].speciesId == pokemonId) {
          return _withdraw(box.id, index);
        }
      }
    }
    return Future<PlayerServiceAutomationResult>.value(
      PlayerServiceAutomationResult.failed(
        failure: PlayerServiceAutomationFailure.invalidRequest,
        message: 'Pokémon "$pokemonId" was not found in PC storage.',
      ),
    );
  }

  Future<PlayerServiceAutomationResult> _depositByPokemonId(
    String pokemonId,
  ) {
    for (var index = 0; index < _gameState.party.members.length; index++) {
      if (_gameState.party.members[index].speciesId == pokemonId) {
        return _deposit(index);
      }
    }
    return Future<PlayerServiceAutomationResult>.value(
      PlayerServiceAutomationResult.failed(
        failure: PlayerServiceAutomationFailure.invalidRequest,
        message: 'Pokémon "$pokemonId" was not found in the party.',
      ),
    );
  }

  Future<PlayerServiceAutomationResult> _apply(
    PlayerStorageOperationResult result, {
    required String success,
  }) async {
    if (_busy) {
      return const PlayerServiceAutomationResult.failed(
        failure: PlayerServiceAutomationFailure.busy,
        message: 'The PC is already processing an operation.',
      );
    }
    if (!result.isSuccess) {
      setState(() {
        _feedbackIsError = true;
        _feedback = _storageFailureLabel(result.failure!);
      });
      return PlayerServiceAutomationResult.failed(
        failure: PlayerServiceAutomationFailure.rejected,
        message: _storageFailureLabel(result.failure!),
      );
    }
    setState(() => _busy = true);
    try {
      await widget.onStateCommitted(result.state);
      if (!mounted) {
        return const PlayerServiceAutomationResult.failed(
          failure: PlayerServiceAutomationFailure.rejected,
          message: 'The PC overlay closed before commit completed.',
        );
      }
      setState(() {
        _gameState = result.state;
        _busy = false;
        _feedbackIsError = false;
        _feedback = success;
      });
      return const PlayerServiceAutomationResult.success();
    } catch (error) {
      if (!mounted) {
        return PlayerServiceAutomationResult.failed(
          failure: PlayerServiceAutomationFailure.rejected,
          message: 'The PC overlay closed after a failed commit: $error',
        );
      }
      setState(() {
        _busy = false;
        _feedbackIsError = true;
        _feedback = 'Échec de la mise à jour du PC : $error';
      });
      return PlayerServiceAutomationResult.failed(
        failure: PlayerServiceAutomationFailure.rejected,
        message: 'The PC operation could not be committed: $error',
      );
    }
  }

  Future<PlayerServiceAutomationResult> _closeFromAutomation() async {
    final close = widget.onAutomationClose;
    if (close == null) {
      return const PlayerServiceAutomationResult.failed(
        failure: PlayerServiceAutomationFailure.invalidRequest,
        message: 'The PC overlay cannot be closed by automation.',
      );
    }
    await close();
    return const PlayerServiceAutomationResult.success();
  }
}

final class _PcAutomationSession implements PlayerServiceAutomationSession {
  const _PcAutomationSession(this.owner);

  final _InGamePcPageState owner;

  @override
  PlayerServiceAutomationKind get kind => PlayerServiceAutomationKind.pc;

  @override
  Future<PlayerServiceAutomationResult> invoke(
    PlayerServiceAutomationCommand command,
  ) =>
      switch (command) {
        WithdrawPcPokemonAutomationCommand(:final pokemonId) =>
          owner._withdrawByPokemonId(pokemonId),
        DepositPcPokemonAutomationCommand(:final pokemonId) =>
          owner._depositByPokemonId(pokemonId),
        ClosePcAutomationCommand() => owner._closeFromAutomation(),
        _ => Future<PlayerServiceAutomationResult>.value(
            const PlayerServiceAutomationResult.failed(
              failure: PlayerServiceAutomationFailure.wrongService,
              message: 'The command does not belong to the PC service.',
            ),
          ),
      };
}

String _storageFailureLabel(PlayerStorageFailure failure) => switch (failure) {
      PlayerStorageFailure.invalidRequest => 'Opération PC invalide.',
      PlayerStorageFailure.invalidPartyIndex => 'Slot d’équipe invalide.',
      PlayerStorageFailure.invalidBoxId => 'Box inconnue.',
      PlayerStorageFailure.invalidBoxIndex => 'Slot de box invalide.',
      PlayerStorageFailure.partyFull => 'L’équipe est pleine.',
      PlayerStorageFailure.boxFull => 'Cette box est pleine.',
      PlayerStorageFailure.storageFull => 'Le PC est plein.',
      PlayerStorageFailure.lastUsablePokemon =>
        'Impossible de déposer le dernier Pokémon utilisable.',
    };
