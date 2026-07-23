import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

typedef InGamePcStateCommit = Future<void> Function(GameState state);

class InGamePcPage extends StatefulWidget {
  const InGamePcPage({
    super.key,
    required this.gameState,
    required this.onStateCommitted,
  });

  final GameState gameState;
  final InGamePcStateCommit onStateCommitted;

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

  PokemonBox get _box =>
      _gameState.pokemonStorage.boxes.firstWhere((box) => box.id == _boxId);

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

  Future<void> _deposit(int partyIndex) => _apply(
        _operations.deposit(
          state: _gameState,
          partyIndex: partyIndex,
          boxId: _boxId,
        ),
        success: 'Pokémon déposé dans ${_box.label}.',
      );

  Future<void> _withdraw(String boxId, int boxIndex) => _apply(
        _operations.withdraw(
          state: _gameState,
          boxId: boxId,
          boxIndex: boxIndex,
        ),
        success: 'Pokémon retiré de la box.',
      );

  Future<void> _swapLead(String boxId, int boxIndex) => _apply(
        _operations.swapPartyWithBox(
          state: _gameState,
          partyIndex: 0,
          boxId: boxId,
          boxIndex: boxIndex,
        ),
        success: 'Pokémon échangé avec le lead.',
      );

  Future<void> _apply(
    PlayerStorageOperationResult result, {
    required String success,
  }) async {
    if (_busy) return;
    if (!result.isSuccess) {
      setState(() {
        _feedbackIsError = true;
        _feedback = _storageFailureLabel(result.failure!);
      });
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onStateCommitted(result.state);
      if (!mounted) return;
      setState(() {
        _gameState = result.state;
        _busy = false;
        _feedbackIsError = false;
        _feedback = success;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _feedbackIsError = true;
        _feedback = 'Échec de la mise à jour du PC : $error';
      });
    }
  }
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
