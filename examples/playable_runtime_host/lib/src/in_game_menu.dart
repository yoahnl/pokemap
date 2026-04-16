import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'runtime_pokedex_loader.dart';

// Sections minimales couvertes par la phase 10.
// On reste volontairement sur les écrans lecture seule demandés, plus la
// surface de sauvegarde déjà existante dans le host runtime.
enum InGameMenuSection {
  pokedex,
  party,
  bag,
  trainer,
  save,
}

// Résultat standardisé d'une action de save/load déclenchée depuis le menu.
// Cela permet d'afficher un feedback homogène sans recréer un système d'état.
class InGameMenuActionResult {
  const InGameMenuActionResult({
    this.status,
    this.error,
  });

  final String? status;
  final String? error;
}

// Menu principal in-game de la phase 10.
// Il reçoit des callbacks et des snapshots déjà prêts pour rester branché sur
// l'existant sans introduire une nouvelle architecture UI.
class InGameMenuPage extends StatefulWidget {
  const InGameMenuPage({
    super.key,
    required this.gameStateSnapshotBuilder,
    required this.pokedexLoader,
    required this.onSaveRequested,
    required this.onLoadRequested,
    required this.onCloseRequested,
  });

  final GameState Function() gameStateSnapshotBuilder;
  final Future<List<RuntimePokedexEntry>> Function() pokedexLoader;
  final Future<InGameMenuActionResult> Function() onSaveRequested;
  final Future<InGameMenuActionResult> Function() onLoadRequested;
  final VoidCallback onCloseRequested;

  @override
  State<InGameMenuPage> createState() => _InGameMenuPageState();
}

// L'état local du menu reste très petit :
// section sélectionnée, entrée Pokédex sélectionnée et état de save/load.
class _InGameMenuPageState extends State<InGameMenuPage> {
  late final Future<List<RuntimePokedexEntry>> _pokedexEntriesFuture =
      widget.pokedexLoader();
  InGameMenuSection _selectedSection = InGameMenuSection.pokedex;
  String? _selectedSpeciesId;
  bool _saveBusy = false;
  String? _saveStatus;
  String? _saveError;

  @override
  Widget build(BuildContext context) {
    // On relit le snapshot de GameState à chaque build pour que les écrans
    // lecture seule restent synchronisés avec le runtime après un chargement.
    final gameState = widget.gameStateSnapshotBuilder();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        leading: IconButton(
          key: const Key('in-game-menu-close-button'),
          icon: const Icon(Icons.close),
          onPressed: widget.onCloseRequested,
        ),
      ),
      body: Row(
        children: [
          SizedBox(
            width: 220,
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: ListView(
                children: [
                  _MenuTile(
                    key: const Key('menu-pokedex-tile'),
                    label: 'Pokédex',
                    icon: Icons.menu_book,
                    selected: _selectedSection == InGameMenuSection.pokedex,
                    onTap: () => setState(
                      () => _selectedSection = InGameMenuSection.pokedex,
                    ),
                  ),
                  _MenuTile(
                    key: const Key('menu-party-tile'),
                    label: 'Équipe',
                    icon: Icons.pets,
                    selected: _selectedSection == InGameMenuSection.party,
                    onTap: () => setState(
                      () => _selectedSection = InGameMenuSection.party,
                    ),
                  ),
                  _MenuTile(
                    key: const Key('menu-bag-tile'),
                    label: 'Sac',
                    icon: Icons.backpack,
                    selected: _selectedSection == InGameMenuSection.bag,
                    onTap: () => setState(
                      () => _selectedSection = InGameMenuSection.bag,
                    ),
                  ),
                  _MenuTile(
                    key: const Key('menu-trainer-tile'),
                    label: 'Dresseur',
                    icon: Icons.badge,
                    selected: _selectedSection == InGameMenuSection.trainer,
                    onTap: () => setState(
                      () => _selectedSection = InGameMenuSection.trainer,
                    ),
                  ),
                  _MenuTile(
                    key: const Key('menu-save-tile'),
                    label: 'Sauvegarde',
                    icon: Icons.save,
                    selected: _selectedSection == InGameMenuSection.save,
                    onTap: () => setState(
                      () => _selectedSection = InGameMenuSection.save,
                    ),
                  ),
                  const Divider(height: 1),
                  _MenuTile(
                    key: const Key('menu-close-tile'),
                    label: 'Fermer',
                    icon: Icons.close,
                    selected: false,
                    onTap: widget.onCloseRequested,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: switch (_selectedSection) {
                InGameMenuSection.pokedex => _buildPokedexSection(context),
                InGameMenuSection.party => _buildPartySection(
                    context,
                    gameState,
                  ),
                InGameMenuSection.bag => _BagSection(gameState: gameState),
                InGameMenuSection.trainer =>
                  _TrainerSection(gameState: gameState),
                InGameMenuSection.save => _buildSaveSection(context),
              },
            ),
          ),
        ],
      ),
    );
  }

  // Le Pokédex in-game reste volontairement sobre :
  // une liste légère d'espèces locales et une fiche simple lecture seule.
  Widget _buildPokedexSection(BuildContext context) {
    return FutureBuilder<List<RuntimePokedexEntry>>(
      future: _pokedexEntriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _SectionMessageCard(
            title: 'Pokédex',
            message: 'Erreur de chargement Pokédex: ${snapshot.error}',
          );
        }

        final entries = snapshot.data ?? const <RuntimePokedexEntry>[];
        if (entries.isEmpty) {
          return const _SectionMessageCard(
            title: 'Pokédex',
            message: 'Aucune espèce locale trouvée dans le projet.',
          );
        }

        final selectedEntry = _resolveSelectedEntry(entries);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Card(
                child: ListView.builder(
                  key: const Key('in-game-pokedex-list'),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final isSelected = entry.id == selectedEntry.id;
                    return ListTile(
                      key: Key('pokedex-entry-${entry.id}'),
                      selected: isSelected,
                      title: Text(entry.primaryName),
                      subtitle: Text('#${entry.nationalDex} · ${entry.id}'),
                      trailing: entry.types.isEmpty
                          ? null
                          : Text(entry.types.join(' / ')),
                      onTap: () => setState(
                        () => _selectedSpeciesId = entry.id,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _PokedexDetail(entry: selectedEntry),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Si rien n'est encore sélectionné, on prend la première espèce disponible.
  // Cela évite d'introduire un état de navigation plus lourd que nécessaire.
  RuntimePokedexEntry _resolveSelectedEntry(List<RuntimePokedexEntry> entries) {
    final selectedId = _selectedSpeciesId;
    if (selectedId == null) {
      final first = entries.first;
      _selectedSpeciesId = first.id;
      return first;
    }
    return entries.firstWhere(
      (entry) => entry.id == selectedId,
      orElse: () {
        final first = entries.first;
        _selectedSpeciesId = first.id;
        return first;
      },
    );
  }

  // L'équipe réutilise le snapshot runtime et enrichit l'affichage avec les
  // noms du Pokédex quand ils sont déjà disponibles.
  Widget _buildPartySection(BuildContext context, GameState gameState) {
    return FutureBuilder<List<RuntimePokedexEntry>>(
      future: _pokedexEntriesFuture,
      builder: (context, snapshot) {
        final speciesNamesById = {
          for (final entry in snapshot.data ?? const <RuntimePokedexEntry>[])
            entry.id: entry.primaryName,
        };
        return _PartySection(
          gameState: gameState,
          speciesNamesById: speciesNamesById,
        );
      },
    );
  }

  // La section sauvegarde réutilise les callbacks runtime existants.
  // On ne crée pas de second système de save pour la phase 10.
  Widget _buildSaveSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sauvegarde',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Cette vue réutilise exactement les flux de sauvegarde et de chargement déjà branchés au runtime.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.tonal(
                  key: const Key('in-game-menu-save-button'),
                  onPressed: _saveBusy ? null : _runSave,
                  child: const Text('Sauvegarder'),
                ),
                FilledButton(
                  key: const Key('in-game-menu-load-button'),
                  onPressed: _saveBusy ? null : _runLoad,
                  child: const Text('Charger'),
                ),
              ],
            ),
            if (_saveStatus != null) ...[
              const SizedBox(height: 16),
              Text(
                _saveStatus!,
                key: const Key('in-game-menu-save-status'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
            if (_saveError != null) ...[
              const SizedBox(height: 16),
              Text(
                _saveError!,
                key: const Key('in-game-menu-save-error'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Déclenchement simple de la sauvegarde avec feedback visuel local.
  Future<void> _runSave() async {
    setState(() {
      _saveBusy = true;
      _saveStatus = null;
      _saveError = null;
    });
    final result = await widget.onSaveRequested();
    if (!mounted) {
      return;
    }
    setState(() {
      _saveBusy = false;
      _saveStatus = result.status;
      _saveError = result.error;
    });
  }

  // Même logique pour le chargement :
  // on relaie simplement le résultat du pipeline runtime existant.
  Future<void> _runLoad() async {
    setState(() {
      _saveBusy = true;
      _saveStatus = null;
      _saveError = null;
    });
    final result = await widget.onLoadRequested();
    if (!mounted) {
      return;
    }
    setState(() {
      _saveBusy = false;
      _saveStatus = result.status;
      _saveError = result.error;
    });
  }
}

// Tuile de navigation latérale.
// Elle encapsule juste le rendu répétitif des entrées du menu.
class _MenuTile extends StatelessWidget {
  const _MenuTile({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}

// Fiche lecture seule d'une espèce côté menu in-game.
// On garde seulement les informations les plus utiles au joueur à ce stade.
class _PokedexDetail extends StatelessWidget {
  const _PokedexDetail({required this.entry});

  final RuntimePokedexEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: Key('pokedex-detail-${entry.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.primaryName,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text('ID : ${entry.id}'),
        Text('Numéro : #${entry.nationalDex}'),
        Text(
            'Types : ${entry.types.isEmpty ? 'Aucun' : entry.types.join(' / ')}'),
        Text(
          'Statut projet : ${entry.isEnabledInProject ? 'Activée' : 'Désactivée'}',
        ),
        const SizedBox(height: 16),
        Text(
          entry.flavorText ?? 'Aucun texte Pokédex disponible.',
          key: const Key('pokedex-detail-flavor-text'),
        ),
      ],
    );
  }
}

// Écran Sac lecture seule.
// Les items sont simplement regroupés par catégorie à partir du GameState.
class _BagSection extends StatelessWidget {
  const _BagSection({required this.gameState});

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    if (gameState.bag.entries.isEmpty) {
      return const _SectionMessageCard(
        title: 'Sac',
        message: 'Le sac est vide.',
      );
    }

    final entriesByCategory = <String, List<BagEntry>>{};
    for (final entry in gameState.bag.entries) {
      entriesByCategory.putIfAbsent(entry.categoryId, () => <BagEntry>[]).add(
            entry,
          );
    }
    final sortedCategories = entriesByCategory.keys.toList()..sort();

    return ListView(
      key: const Key('in-game-bag-section'),
      children: [
        Text(
          'Sac',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        for (final category in sortedCategories) ...[
          Text(
            category,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: entriesByCategory[category]!
                  .map(
                    (entry) => ListTile(
                      key: Key('bag-entry-${entry.itemId}'),
                      title: Text(entry.itemId),
                      trailing: Text('x${entry.quantity}'),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

// Écran Équipe lecture seule.
// On expose l'ordre d'équipe et les infos persistées déjà présentes en save.
class _PartySection extends StatelessWidget {
  const _PartySection({
    required this.gameState,
    required this.speciesNamesById,
  });

  final GameState gameState;
  final Map<String, String> speciesNamesById;

  @override
  Widget build(BuildContext context) {
    final members = gameState.party.members;
    if (members.isEmpty) {
      return const _SectionMessageCard(
        title: 'Équipe',
        message: "L'équipe du joueur est vide.",
      );
    }

    return ListView(
      key: const Key('in-game-party-section'),
      children: [
        Text(
          'Équipe',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        for (var index = 0; index < members.length; index++) ...[
          _PartyPokemonCard(
            key: Key('party-entry-$index'),
            pokemon: members[index],
            slotIndex: index,
            speciesName: speciesNamesById[members[index].speciesId],
          ),
          if (index < members.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _PartyPokemonCard extends StatelessWidget {
  const _PartyPokemonCard({
    super.key,
    required this.pokemon,
    required this.slotIndex,
    required this.speciesName,
  });

  final PlayerPokemon pokemon;
  final int slotIndex;
  final String? speciesName;

  @override
  Widget build(BuildContext context) {
    final displayName = speciesName?.trim().isNotEmpty == true
        ? speciesName!.trim()
        : pokemon.speciesId;
    final statusLabel = pokemon.statusId.isEmpty ? 'Aucun' : pokemon.statusId;
    final heldItemLabel =
        pokemon.heldItemId.isEmpty ? 'Aucun' : pokemon.heldItemId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                child: Text('${slotIndex + 1}'),
              ),
              title: Text(
                displayName,
                key: Key('party-entry-name-$slotIndex'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              subtitle: Text('Niv. ${pokemon.level} · ${pokemon.speciesId}'),
              trailing: Chip(
                key: Key('party-entry-state-$slotIndex'),
                label: Text(pokemon.isFainted ? 'KO' : 'Actif'),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PokemonInfoChip(
                    label: 'PV actuels', value: '${pokemon.currentHp}'),
                _PokemonInfoChip(label: 'Talent', value: pokemon.abilityId),
                _PokemonInfoChip(label: 'Nature', value: pokemon.natureId),
                _PokemonInfoChip(label: 'Statut', value: statusLabel),
                _PokemonInfoChip(label: 'Objet', value: heldItemLabel),
                if (pokemon.isShiny)
                  const _PokemonInfoChip(label: 'Shiny', value: 'Oui'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Attaques',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (pokemon.knownMoveIds.isEmpty)
              const Text('Aucune attaque connue.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: pokemon.knownMoveIds
                    .map(
                      (moveId) => Chip(
                        key: Key('party-move-$moveId-$slotIndex'),
                        label: Text(moveId),
                      ),
                    )
                    .toList(growable: false),
              ),
          ],
        ),
      ),
    );
  }
}

class _PokemonInfoChip extends StatelessWidget {
  const _PokemonInfoChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label : $value'));
  }
}

// Écran Dresseur lecture seule.
// Il expose uniquement le profil minimal déjà persistant depuis la phase 9.
class _TrainerSection extends StatelessWidget {
  const _TrainerSection({required this.gameState});

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    final profile = gameState.trainerProfile;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          key: const Key('in-game-trainer-section'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dresseur',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text('Nom : ${profile.name}', key: const Key('trainer-name')),
            Text('Argent : ${profile.money}', key: const Key('trainer-money')),
            Text(
              'Temps de jeu : ${_formatPlaytime(profile.playtimeSeconds)}',
              key: const Key('trainer-playtime'),
            ),
            const SizedBox(height: 16),
            Text(
              'Badges',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (profile.badgeIds.isEmpty)
              const Text('Aucun badge')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.badgeIds
                    .map(
                      (badgeId) => Chip(
                        key: Key('trainer-badge-$badgeId'),
                        label: Text(badgeId),
                      ),
                    )
                    .toList(growable: false),
              ),
          ],
        ),
      ),
    );
  }
}

// Carte d'état simple réutilisée pour les écrans vides ou en erreur.
class _SectionMessageCard extends StatelessWidget {
  const _SectionMessageCard({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(message),
          ],
        ),
      ),
    );
  }
}

// Format de temps de jeu minimal, lisible et stable pour l'écran Dresseur.
String _formatPlaytime(int totalSeconds) {
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  final parts = <String>[
    hours.toString().padLeft(2, '0'),
    minutes.toString().padLeft(2, '0'),
    seconds.toString().padLeft(2, '0'),
  ];
  return parts.join(':');
}
