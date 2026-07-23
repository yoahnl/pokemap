import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

import 'in_game_heal_flow.dart';
import 'in_game_pc_page.dart';
import 'in_game_shop_page.dart';
import 'runtime_player_options.dart';
import 'runtime_map_destinations.dart';
import 'runtime_pokedex_loader.dart';

// Sections minimales couvertes par la phase 10.
// On reste volontairement sur les écrans lecture seule demandés, plus la
// surface de sauvegarde déjà existante dans le host runtime.
enum InGameMenuSection {
  pokedex,
  party,
  bag,
  shop,
  pc,
  heal,
  trainer,
  save,
  options,
  worldMap,
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

typedef RuntimeExternalInputLockSetter = void Function(
  RuntimeExternalInputLock owner, {
  required bool locked,
});

/// Keeps the typed pause owner acquired for the complete Flutter route life.
///
/// The `finally` is intentionally centralized and testable: Navigator errors,
/// Close, Escape and Quit must all release the same owner.
Future<void> runWithRuntimePauseMenuInputLock({
  required RuntimeExternalInputLockSetter setExternalInputLock,
  required Future<void> Function() openMenu,
}) async {
  setExternalInputLock(RuntimeExternalInputLock.pauseMenu, locked: true);
  try {
    await openMenu();
  } finally {
    setExternalInputLock(RuntimeExternalInputLock.pauseMenu, locked: false);
  }
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
    required this.playerOptions,
    required this.supportsTouchControls,
    required this.onOptionsChanged,
    required this.onQuitRequested,
    required this.onCloseRequested,
    this.projectMaps = const <ProjectMapEntry>[],
    this.shops = const <ShopDefinition>[],
    this.recoveryCaps = const PlayerServiceRecoveryCaps(
      maxHpByPartyIndex: <int, int>{},
    ),
    this.onPlayerStateCommitted,
  });

  final GameState Function() gameStateSnapshotBuilder;
  final Future<List<RuntimePokedexEntry>> Function() pokedexLoader;
  final Future<InGameMenuActionResult> Function() onSaveRequested;
  final Future<InGameMenuActionResult> Function() onLoadRequested;
  final RuntimePlayerOptions playerOptions;
  final bool supportsTouchControls;
  final ValueChanged<RuntimePlayerOptions> onOptionsChanged;
  final VoidCallback onQuitRequested;
  final VoidCallback onCloseRequested;
  final List<ProjectMapEntry> projectMaps;
  final List<ShopDefinition> shops;
  final PlayerServiceRecoveryCaps recoveryCaps;
  final Future<void> Function(GameState state)? onPlayerStateCommitted;

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
  late RuntimePlayerOptions _playerOptions;
  GameState? _committedGameState;

  @override
  void initState() {
    super.initState();
    _playerOptions = widget.playerOptions;
  }

  @override
  Widget build(BuildContext context) {
    // On relit le snapshot de GameState à chaque build pour que les écrans
    // lecture seule restent synchronisés avec le runtime après un chargement.
    final gameState = _committedGameState ?? widget.gameStateSnapshotBuilder();
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape):
            widget.onCloseRequested,
      },
      child: Focus(
        // The first menu tile owns initial focus. The wrapper only keeps the
        // Escape shortcut active while descendants move through Tab order.
        autofocus: false,
        child: Scaffold(
          key: const Key('in-game-menu-page'),
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
                        autofocus: true,
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
                        key: const Key('menu-shop-tile'),
                        label: 'Boutique',
                        icon: Icons.storefront,
                        selected: _selectedSection == InGameMenuSection.shop,
                        onTap: () => setState(
                          () => _selectedSection = InGameMenuSection.shop,
                        ),
                      ),
                      _MenuTile(
                        key: const Key('menu-pc-tile'),
                        label: 'PC Pokémon',
                        icon: Icons.dns_outlined,
                        selected: _selectedSection == InGameMenuSection.pc,
                        onTap: () => setState(
                          () => _selectedSection = InGameMenuSection.pc,
                        ),
                      ),
                      _MenuTile(
                        key: const Key('menu-heal-tile'),
                        label: 'Centre Pokémon',
                        icon: Icons.healing,
                        selected: _selectedSection == InGameMenuSection.heal,
                        onTap: () => setState(
                          () => _selectedSection = InGameMenuSection.heal,
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
                      _MenuTile(
                        key: const Key('menu-options-tile'),
                        label: 'Options',
                        icon: Icons.settings,
                        selected: _selectedSection == InGameMenuSection.options,
                        onTap: () => setState(
                          () => _selectedSection = InGameMenuSection.options,
                        ),
                      ),
                      _MenuTile(
                        key: const Key('menu-map-tile'),
                        label: 'Carte',
                        icon: Icons.map,
                        selected:
                            _selectedSection == InGameMenuSection.worldMap,
                        onTap: () => setState(
                          () => _selectedSection = InGameMenuSection.worldMap,
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
                      _MenuTile(
                        key: const Key('menu-quit-tile'),
                        label: 'Quitter la partie',
                        icon: Icons.logout,
                        selected: false,
                        onTap: _confirmQuit,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: switch (_selectedSection) {
                    InGameMenuSection.pokedex => _buildPokedexSection(
                        context,
                        gameState.progression,
                      ),
                    InGameMenuSection.party => _buildPartySection(
                        context,
                        gameState,
                      ),
                    InGameMenuSection.bag => _BagSection(
                        gameState: gameState,
                        recoveryCaps: widget.recoveryCaps,
                        onStateCommitted: _commitPlayerState,
                      ),
                    InGameMenuSection.shop => InGameShopPage(
                        gameState: gameState,
                        shops: widget.shops,
                        onStateCommitted: _commitPlayerState,
                      ),
                    InGameMenuSection.pc => InGamePcPage(
                        gameState: gameState,
                        onStateCommitted: _commitPlayerState,
                      ),
                    InGameMenuSection.heal => InGameHealFlow(
                        gameState: gameState,
                        recoveryCaps: widget.recoveryCaps,
                        onStateCommitted: _commitPlayerState,
                      ),
                    InGameMenuSection.trainer =>
                      _TrainerSection(gameState: gameState),
                    InGameMenuSection.save => _buildSaveSection(context),
                    InGameMenuSection.options => _buildOptionsSection(context),
                    InGameMenuSection.worldMap => _buildMapSection(
                        context,
                        gameState,
                      ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsSection(BuildContext context) {
    return ListView(
      key: const Key('in-game-options-section'),
      children: [
        Text('Options', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: DropdownButtonFormField<RuntimeDialogueTextSpeed>(
              key: const Key('dialogue-text-speed-dropdown'),
              initialValue: _playerOptions.dialogueTextSpeed,
              decoration: const InputDecoration(
                labelText: 'Vitesse du texte',
                helperText: 'Appliquée immédiatement aux dialogues runtime.',
              ),
              items: RuntimeDialogueTextSpeed.values
                  .map(
                    (speed) => DropdownMenuItem<RuntimeDialogueTextSpeed>(
                      value: speed,
                      child: Text(_dialogueSpeedLabel(speed)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (speed) {
                if (speed != null) {
                  _setPlayerOptions(
                    _playerOptions.copyWith(dialogueTextSpeed: speed),
                  );
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile.adaptive(
            key: const Key('show-touch-controls-switch'),
            title: const Text('Afficher les contrôles tactiles'),
            subtitle: Text(
              widget.supportsTouchControls
                  ? 'Le choix est mémorisé sur cet appareil.'
                  : 'Indisponible sur cette plateforme.',
            ),
            value: widget.supportsTouchControls &&
                _playerOptions.showTouchControls,
            onChanged: widget.supportsTouchControls
                ? (value) => _setPlayerOptions(
                      _playerOptions.copyWith(showTouchControls: value),
                    )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        const _SectionMessageCard(
          title: 'Audio',
          message:
              'Volume global indisponible : le moteur ne possède pas encore de mixeur audio global. Aucun faux réglage ne sera enregistré.',
        ),
      ],
    );
  }

  Widget _buildMapSection(BuildContext context, GameState gameState) {
    final destinations = resolveRuntimeMapDestinations(
      maps: widget.projectMaps,
      gameState: gameState,
    );
    return ListView(
      key: const Key('in-game-map-section'),
      children: [
        Text('Carte', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        const _SectionMessageCard(
          title: 'Voyage rapide',
          message:
              'Voyage rapide indisponible : la mécanique Vol est planifiée dans le lot FG-125. Cette carte n’invente pas un déplacement non supporté.',
        ),
        const SizedBox(height: 16),
        if (destinations.isEmpty)
          const _SectionMessageCard(
            title: 'Destinations',
            message: 'Aucune map n’est déclarée dans ce projet.',
          )
        else
          Card(
            child: Column(
              children: [
                for (final destination in destinations)
                  ListTile(
                    key: Key('map-destination-${destination.mapId}'),
                    leading: Icon(
                      switch (destination.status) {
                        RuntimeMapDestinationStatus.current =>
                          Icons.my_location,
                        RuntimeMapDestinationStatus.known =>
                          Icons.location_on_outlined,
                        RuntimeMapDestinationStatus.locked =>
                          Icons.lock_outline,
                      },
                    ),
                    title: Text(destination.displayName),
                    subtitle: Text(
                      switch (destination.status) {
                        RuntimeMapDestinationStatus.current =>
                          'Position actuelle',
                        RuntimeMapDestinationStatus.known =>
                          'Destination connue',
                        RuntimeMapDestinationStatus.locked =>
                          'Destination inconnue',
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  void _setPlayerOptions(RuntimePlayerOptions options) {
    setState(() => _playerOptions = options);
    widget.onOptionsChanged(options);
  }

  Future<void> _confirmQuit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('quit-confirmation-dialog'),
        title: const Text('Quitter la partie ?'),
        content: const Text(
          'La session runtime sera fermée. Les changements non sauvegardés seront perdus.',
        ),
        actions: [
          TextButton(
            key: const Key('quit-cancel-button'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            key: const Key('quit-confirm-button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      widget.onQuitRequested();
    }
  }

  // Le Pokédex in-game reste volontairement sobre :
  // une liste légère d'espèces locales et une fiche simple lecture seule.
  Widget _buildPokedexSection(
    BuildContext context,
    PlayerProgression progression,
  ) {
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
                    final knowledge = resolveRuntimePokedexKnowledge(
                      speciesId: entry.id,
                      progression: progression,
                    );
                    return ListTile(
                      key: Key('pokedex-entry-${entry.id}'),
                      selected: isSelected,
                      title: Text(
                        knowledge == RuntimePokedexKnowledge.unknown
                            ? '???'
                            : entry.primaryName,
                      ),
                      subtitle: Text(
                        knowledge == RuntimePokedexKnowledge.unknown
                            ? '#${entry.nationalDex} · Inconnu'
                            : '#${entry.nationalDex} · ${entry.types.join(' / ')}',
                      ),
                      trailing: Chip(
                        key: Key(
                          'pokedex-knowledge-${entry.id}-${knowledge.name}',
                        ),
                        label: Text(_pokedexKnowledgeLabel(knowledge)),
                      ),
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
                  child: _PokedexDetail(
                    entry: selectedEntry,
                    knowledge: resolveRuntimePokedexKnowledge(
                      speciesId: selectedEntry.id,
                      progression: progression,
                    ),
                  ),
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
          recoveryCaps: widget.recoveryCaps,
          onStateCommitted: _commitPlayerState,
        );
      },
    );
  }

  Future<void> _commitPlayerState(GameState state) async {
    await widget.onPlayerStateCommitted?.call(state);
    if (!mounted) return;
    setState(() => _committedGameState = state);
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

  // Saving is the only destructive disk action in this surface, so it requires
  // an explicit confirmation before the host callback can run.
  Future<void> _runSave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('save-confirmation-dialog'),
        title: const Text('Sauvegarder la partie ?'),
        content: const Text(
          'La sauvegarde existante sera remplacée par l’état actuel.',
        ),
        actions: [
          TextButton(
            key: const Key('save-cancel-button'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            key: const Key('save-confirm-button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await _runSaveLoadAction(
      request: widget.onSaveRequested,
      failureLabel: 'Erreur sauvegarde',
    );
  }

  // Load stays one click because it reads an existing save. Both paths share
  // the same busy and exception guard, so a host or disk failure remains
  // visible player feedback instead of escaping the widget tree.
  Future<void> _runLoad() async {
    await _runSaveLoadAction(
      request: widget.onLoadRequested,
      failureLabel: 'Erreur chargement',
    );
  }

  Future<void> _runSaveLoadAction({
    required Future<InGameMenuActionResult> Function() request,
    required String failureLabel,
  }) async {
    if (_saveBusy) {
      return;
    }
    setState(() {
      _saveBusy = true;
      _saveStatus = null;
      _saveError = null;
    });
    try {
      final result = await request();
      if (!mounted) {
        return;
      }
      setState(() {
        _saveStatus = result.status;
        _saveError = result.error;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saveError = '$failureLabel: $error');
    } finally {
      if (mounted) {
        setState(() => _saveBusy = false);
      }
    }
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
    this.autofocus = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      autofocus: autofocus,
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}

String _dialogueSpeedLabel(RuntimeDialogueTextSpeed speed) => switch (speed) {
      RuntimeDialogueTextSpeed.slow => 'Lente',
      RuntimeDialogueTextSpeed.normal => 'Normale',
      RuntimeDialogueTextSpeed.fast => 'Rapide',
      RuntimeDialogueTextSpeed.instant => 'Instantanée',
    };

String _pokedexKnowledgeLabel(RuntimePokedexKnowledge knowledge) =>
    switch (knowledge) {
      RuntimePokedexKnowledge.unknown => 'Inconnu',
      RuntimePokedexKnowledge.seen => 'Vu',
      RuntimePokedexKnowledge.caught => 'Capturé',
    };

// Fiche lecture seule d'une espèce côté menu in-game.
// On garde seulement les informations les plus utiles au joueur à ce stade.
class _PokedexDetail extends StatelessWidget {
  const _PokedexDetail({
    required this.entry,
    required this.knowledge,
  });

  final RuntimePokedexEntry entry;
  final RuntimePokedexKnowledge knowledge;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: Key('pokedex-detail-${entry.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          knowledge == RuntimePokedexKnowledge.unknown
              ? '???'
              : entry.primaryName,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text('Numéro : #${entry.nationalDex}'),
        Chip(
          label: Text(_pokedexKnowledgeLabel(knowledge)),
        ),
        if (knowledge == RuntimePokedexKnowledge.unknown) ...[
          const SizedBox(height: 16),
          const Text('Rencontrez cette espèce pour révéler son identité.'),
        ] else ...[
          Text(
            'Types : ${entry.types.isEmpty ? 'Aucun' : entry.types.join(' / ')}',
          ),
          if (knowledge == RuntimePokedexKnowledge.seen) ...[
            const SizedBox(height: 16),
            const Text('Capturez cette espèce pour compléter sa fiche.'),
          ] else ...[
            Text('ID : ${entry.id}'),
            Text(
              'Statut projet : ${entry.isEnabledInProject ? 'Activée' : 'Désactivée'}',
            ),
            const SizedBox(height: 16),
            Text(
              entry.flavorText ?? 'Aucun texte Pokédex disponible.',
              key: const Key('pokedex-detail-flavor-text'),
            ),
          ],
        ],
      ],
    );
  }
}

class _BagSection extends StatefulWidget {
  const _BagSection({
    required this.gameState,
    required this.recoveryCaps,
    required this.onStateCommitted,
  });

  final GameState gameState;
  final PlayerServiceRecoveryCaps recoveryCaps;
  final Future<void> Function(GameState state) onStateCommitted;

  @override
  State<_BagSection> createState() => _BagSectionState();
}

class _BagSectionState extends State<_BagSection> {
  static const _operations = PlayerItemOperations();
  static const _registry = PlayerItemEffectRegistry.mvp();

  bool _busy = false;
  String? _feedback;
  bool _feedbackIsError = false;

  @override
  Widget build(BuildContext context) {
    final gameState = widget.gameState;
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
              children: entriesByCategory[category]!.map(
                (entry) {
                  final effect = _registry.effectFor(entry.itemId);
                  final usable = effect != null &&
                      (effect.kind == PlayerItemEffectKind.healHp ||
                          effect.kind == PlayerItemEffectKind.cureStatus ||
                          effect.kind == PlayerItemEffectKind.revive);
                  return ListTile(
                    key: Key('bag-entry-${entry.itemId}'),
                    title: Text(_itemLabel(entry.itemId)),
                    subtitle: Text(
                      usable
                          ? 'Utilisable sur un Pokémon de l’équipe.'
                          : 'Non utilisable depuis ce menu.',
                    ),
                    trailing: Wrap(
                      spacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('x${entry.quantity}'),
                        FilledButton.tonal(
                          key: Key('bag-use-${entry.itemId}'),
                          onPressed: _busy || !usable
                              ? null
                              : () => _selectTarget(entry.itemId),
                          child: const Text('Utiliser'),
                        ),
                      ],
                    ),
                  );
                },
              ).toList(growable: false),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_feedback != null)
          Text(
            _feedback!,
            key: const Key('bag-feedback'),
            style: TextStyle(
              color: _feedbackIsError
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
      ],
    );
  }

  Future<void> _selectTarget(String itemId) async {
    if (widget.gameState.party.members.isEmpty) {
      setState(() {
        _feedbackIsError = true;
        _feedback = 'Aucun Pokémon disponible.';
      });
      return;
    }
    final targetIndex = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text('Utiliser ${_itemLabel(itemId)} sur…'),
        children: [
          for (var index = 0;
              index < widget.gameState.party.members.length;
              index++)
            SimpleDialogOption(
              key: Key('bag-target-$index'),
              onPressed: () => Navigator.of(dialogContext).pop(index),
              child: Text(
                '${widget.gameState.party.members[index].speciesId} · '
                'PV ${widget.gameState.party.members[index].currentHp}',
              ),
            ),
        ],
      ),
    );
    if (targetIndex == null || !mounted) return;
    await _use(itemId, targetIndex);
  }

  Future<void> _use(String itemId, int targetIndex) async {
    final maxHp = widget.recoveryCaps.maxHpByPartyIndex[targetIndex];
    if (maxHp == null || maxHp <= 0) {
      setState(() {
        _feedbackIsError = true;
        _feedback = 'PV maximum indisponibles pour cette cible.';
      });
      return;
    }
    final result = _operations.useOnPartyMember(
      widget.gameState,
      itemId: itemId,
      partyIndex: targetIndex,
      maxHp: maxHp,
      maxPpByMoveId:
          widget.recoveryCaps.maxPpByPartyIndex[targetIndex] ?? const {},
    );
    if (!result.isSuccess) {
      setState(() {
        _feedbackIsError = true;
        _feedback = _itemFailureLabel(result.failure!);
      });
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onStateCommitted(result.state);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _feedbackIsError = false;
        _feedback = '${_itemLabel(itemId)} utilisée avec succès.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _feedbackIsError = true;
        _feedback = 'Échec de l’utilisation : $error';
      });
    }
  }
}

class _PartySection extends StatefulWidget {
  const _PartySection({
    required this.gameState,
    required this.speciesNamesById,
    required this.recoveryCaps,
    required this.onStateCommitted,
  });

  final GameState gameState;
  final Map<String, String> speciesNamesById;
  final PlayerServiceRecoveryCaps recoveryCaps;
  final Future<void> Function(GameState state) onStateCommitted;

  @override
  State<_PartySection> createState() => _PartySectionState();
}

class _PartySectionState extends State<_PartySection> {
  static const _operations = PlayerStorageOperations();
  bool _busy = false;
  String? _feedback;

  @override
  Widget build(BuildContext context) {
    final members = widget.gameState.party.members;
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
            speciesName: widget.speciesNamesById[members[index].speciesId],
            maxPpByMoveId:
                widget.recoveryCaps.maxPpByPartyIndex[index] ?? const {},
            busy: _busy,
            onSetLead: index == 0 ? null : () => _setLead(index),
            onMoveUp: index == 0 ? null : () => _swap(index, index - 1),
            onMoveDown: index == members.length - 1
                ? null
                : () => _swap(index, index + 1),
          ),
          if (index < members.length - 1) const SizedBox(height: 16),
        ],
        if (_feedback != null) ...[
          const SizedBox(height: 12),
          Text(
            _feedback!,
            key: const Key('party-feedback'),
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ],
    );
  }

  Future<void> _setLead(int index) => _apply(
        _operations.setLead(state: widget.gameState, partyIndex: index),
        'Le lead a été modifié.',
      );

  Future<void> _swap(int first, int second) => _apply(
        _operations.swapPartyMembers(
          state: widget.gameState,
          firstIndex: first,
          secondIndex: second,
        ),
        'L’ordre de l’équipe a été modifié.',
      );

  Future<void> _apply(
      PlayerStorageOperationResult result, String success) async {
    if (_busy || !result.isSuccess) return;
    setState(() => _busy = true);
    try {
      await widget.onStateCommitted(result.state);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _feedback = success;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _feedback = 'Échec de la réorganisation : $error';
      });
    }
  }
}

class _PartyPokemonCard extends StatelessWidget {
  const _PartyPokemonCard({
    super.key,
    required this.pokemon,
    required this.slotIndex,
    required this.speciesName,
    required this.maxPpByMoveId,
    required this.busy,
    required this.onSetLead,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final PlayerPokemon pokemon;
  final int slotIndex;
  final String? speciesName;
  final Map<String, int> maxPpByMoveId;
  final bool busy;
  final VoidCallback? onSetLead;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

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
                _PokemonInfoChip(
                  label: 'XP',
                  value: '${pokemon.experience ?? 0}',
                ),
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
                        label: Text(
                          '$moveId · PP '
                          '${pokemon.currentPpByMoveId?[moveId] ?? '?'}'
                          '/${maxPpByMoveId[moveId] ?? '?'}',
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  key: Key('party-set-lead-$slotIndex'),
                  onPressed: busy ? null : onSetLead,
                  child: Text(slotIndex == 0 ? 'Lead actuel' : 'Définir lead'),
                ),
                IconButton(
                  key: Key('party-move-up-$slotIndex'),
                  tooltip: 'Monter',
                  onPressed: busy ? null : onMoveUp,
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  key: Key('party-move-down-$slotIndex'),
                  tooltip: 'Descendre',
                  onPressed: busy ? null : onMoveDown,
                  icon: const Icon(Icons.arrow_downward),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _itemLabel(String itemId) => switch (itemId) {
      'potion' => 'Potion',
      'super-potion' => 'Super Potion',
      'hyper-potion' => 'Hyper Potion',
      'max-potion' => 'Potion Max',
      'antidote' => 'Antidote',
      'revive' => 'Rappel',
      _ => itemId,
    };

String _itemFailureLabel(PlayerItemUseFailure failure) => switch (failure) {
      PlayerItemUseFailure.invalidRequest => 'Utilisation invalide.',
      PlayerItemUseFailure.unknownItem => 'Objet inconnu.',
      PlayerItemUseFailure.invalidTarget => 'Cible invalide.',
      PlayerItemUseFailure.insufficientQuantity => 'Objet indisponible.',
      PlayerItemUseFailure.wrongTarget =>
        'Cet objet ne convient pas à la cible.',
      PlayerItemUseFailure.noEffect => 'Cet objet n’aurait aucun effet.',
    };

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
