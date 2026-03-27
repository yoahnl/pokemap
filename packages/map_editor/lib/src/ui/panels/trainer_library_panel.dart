import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_embedded_widgets.dart';

class TrainerLibraryPanel extends ConsumerStatefulWidget {
  const TrainerLibraryPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  ConsumerState<TrainerLibraryPanel> createState() =>
      _TrainerLibraryPanelState();
}

class _TrainerLibraryPanelState extends ConsumerState<TrainerLibraryPanel> {
  // Create trainer form
  final _newNameController = TextEditingController();
  final _newClassController = TextEditingController();
  String? _newCharacterId;
  bool _showCreateForm = false;

  // Edit trainer fields
  String? _editingTrainerId;
  final _editNameController = TextEditingController();
  final _editClassController = TextEditingController();
  String? _editCharacterId;

  // Add Pokémon form
  String? _addPokemonTrainerId;
  final _pokemonSpeciesController = TextEditingController();
  final _pokemonLevelController = TextEditingController();

  @override
  void dispose() {
    _newNameController.dispose();
    _newClassController.dispose();
    _editNameController.dispose();
    _editClassController.dispose();
    _pokemonSpeciesController.dispose();
    _pokemonLevelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final project = state.project;

    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    const accent = EditorChrome.accentCoral;

    final trainers = project?.trainers ?? const [];
    final characters = project?.characters ?? const <ProjectCharacterEntry>[];

    final content = project == null
        ? Center(
            child: Text(
              'No project loaded',
              style: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
              ),
            ),
          )
        : ListView(
            padding: widget.embedded
                ? kInspectorTileBodyPadding
                : const EdgeInsets.fromLTRB(8, 8, 8, 8),
            children: [
              // Create trainer button / form
              if (!_showCreateForm)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minSize: 28,
                    onPressed: () => setState(() => _showCreateForm = true),
                    child: const Text(
                      'New Trainer',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                )
              else
                _CreateTrainerForm(
                  nameController: _newNameController,
                  classController: _newClassController,
                  characters: characters,
                  selectedCharacterId: _newCharacterId,
                  accent: accent,
                  onCancel: () => setState(() {
                    _showCreateForm = false;
                    _newNameController.clear();
                    _newClassController.clear();
                    _newCharacterId = null;
                  }),
                  onSelectCharacter: (characterId) =>
                      setState(() => _newCharacterId = characterId),
                  onCreate: () {
                    notifier.createTrainer(
                      name: _newNameController.text,
                      trainerClass: _newClassController.text,
                      characterId: _newCharacterId,
                    );
                    setState(() {
                      _showCreateForm = false;
                      _newNameController.clear();
                      _newClassController.clear();
                      _newCharacterId = null;
                    });
                  },
                ),

              if (trainers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'No trainers yet',
                      style: TextStyle(color: subtle, fontSize: 13),
                    ),
                  ),
                ),

              for (final trainer in trainers)
                _TrainerTile(
                  key: ValueKey(trainer.id),
                  trainer: trainer,
                  characters: characters,
                  accent: accent,
                  isEditing: _editingTrainerId == trainer.id,
                  editNameController: _editNameController,
                  editClassController: _editClassController,
                  selectedCharacterId: _editCharacterId,
                  isAddingPokemon: _addPokemonTrainerId == trainer.id,
                  pokemonSpeciesController: _pokemonSpeciesController,
                  pokemonLevelController: _pokemonLevelController,
                  onTapEdit: () {
                    setState(() {
                      if (_editingTrainerId == trainer.id) {
                        _editingTrainerId = null;
                      } else {
                        _editingTrainerId = trainer.id;
                        _editNameController.text = trainer.name;
                        _editClassController.text = trainer.trainerClass;
                        _editCharacterId = trainer.characterId;
                        _addPokemonTrainerId = null;
                      }
                    });
                  },
                  onSaveEdit: () {
                    notifier.updateTrainer(
                      trainerId: trainer.id,
                      name: _editNameController.text,
                      trainerClass: _editClassController.text,
                      characterId: _editCharacterId,
                    );
                    setState(() => _editingTrainerId = null);
                  },
                  onCancelEdit: () =>
                      setState(() {
                        _editingTrainerId = null;
                        _editCharacterId = null;
                      }),
                  onSelectCharacter: (characterId) =>
                      setState(() => _editCharacterId = characterId),
                  onDelete: () {
                    notifier.deleteTrainer(trainer.id);
                    if (_editingTrainerId == trainer.id) {
                      setState(() {
                        _editingTrainerId = null;
                        _editCharacterId = null;
                      });
                    }
                  },
                  onTapAddPokemon: () {
                    setState(() {
                      if (_addPokemonTrainerId == trainer.id) {
                        _addPokemonTrainerId = null;
                      } else {
                        _addPokemonTrainerId = trainer.id;
                        _pokemonSpeciesController.clear();
                        _pokemonLevelController.text = '1';
                        _editingTrainerId = null;
                      }
                    });
                  },
                  onAddPokemon: () {
                    final level =
                        int.tryParse(_pokemonLevelController.text) ?? 1;
                    notifier.addTrainerPokemon(
                      trainerId: trainer.id,
                      speciesId: _pokemonSpeciesController.text,
                      level: level,
                    );
                    setState(() {
                      _addPokemonTrainerId = null;
                      _pokemonSpeciesController.clear();
                      _pokemonLevelController.clear();
                    });
                  },
                  onCancelAddPokemon: () =>
                      setState(() => _addPokemonTrainerId = null),
                  onDeletePokemon: (index) => notifier.deleteTrainerPokemon(
                    trainerId: trainer.id,
                    pokemonIndex: index,
                  ),
                ),
            ],
          );

    if (widget.embedded) return content;
    return ColoredBox(
      color: EditorChrome.largeIslandSurfaceColor(context),
      child: content,
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _CreateTrainerForm extends StatelessWidget {
  const _CreateTrainerForm({
    required this.nameController,
    required this.classController,
    required this.characters,
    required this.selectedCharacterId,
    required this.accent,
    required this.onCancel,
    required this.onSelectCharacter,
    required this.onCreate,
  });

  final TextEditingController nameController;
  final TextEditingController classController;
  final List<ProjectCharacterEntry> characters;
  final String? selectedCharacterId;
  final Color accent;
  final VoidCallback onCancel;
  final ValueChanged<String?> onSelectCharacter;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const InspectorEmbeddedSectionLabel('NEW TRAINER'),
          const SizedBox(height: 6),
          CupertinoTextField(
            controller: nameController,
            placeholder: 'Name (e.g. Ash)',
          ),
          const SizedBox(height: 6),
          CupertinoTextField(
            controller: classController,
            placeholder: 'Class (e.g. Pokémon Trainer)',
          ),
          const SizedBox(height: 6),
          _TrainerCharacterPicker(
            characters: characters,
            selectedCharacterId: selectedCharacterId,
            onSelected: onSelectCharacter,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minSize: 28,
                onPressed: onCancel,
                child: const Text('Cancel', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 6),
              CupertinoButton.filled(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minSize: 28,
                onPressed: onCreate,
                child: const Text('Create', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrainerTile extends StatelessWidget {
  const _TrainerTile({
    super.key,
    required this.trainer,
    required this.characters,
    required this.accent,
    required this.isEditing,
    required this.editNameController,
    required this.editClassController,
    required this.selectedCharacterId,
    required this.isAddingPokemon,
    required this.pokemonSpeciesController,
    required this.pokemonLevelController,
    required this.onTapEdit,
    required this.onSaveEdit,
    required this.onCancelEdit,
    required this.onSelectCharacter,
    required this.onDelete,
    required this.onTapAddPokemon,
    required this.onAddPokemon,
    required this.onCancelAddPokemon,
    required this.onDeletePokemon,
  });

  final ProjectTrainerEntry trainer;
  final List<ProjectCharacterEntry> characters;
  final Color accent;
  final bool isEditing;
  final TextEditingController editNameController;
  final TextEditingController editClassController;
  final String? selectedCharacterId;
  final bool isAddingPokemon;
  final TextEditingController pokemonSpeciesController;
  final TextEditingController pokemonLevelController;
  final VoidCallback onTapEdit;
  final VoidCallback onSaveEdit;
  final VoidCallback onCancelEdit;
  final ValueChanged<String?> onSelectCharacter;
  final VoidCallback onDelete;
  final VoidCallback onTapAddPokemon;
  final VoidCallback onAddPokemon;
  final VoidCallback onCancelAddPokemon;
  final void Function(int index) onDeletePokemon;

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final surface = EditorChrome.largeIslandSurfaceColor(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isEditing
              ? accent.withValues(alpha: 0.5)
              : CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trainer.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        trainer.trainerClass,
                        style: TextStyle(fontSize: 11, color: subtle),
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 28,
                  onPressed: onTapEdit,
                  child: Icon(
                    isEditing
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.pencil,
                    size: 16,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 28,
                  onPressed: onDelete,
                  child: const Icon(
                    CupertinoIcons.trash,
                    size: 16,
                    color: CupertinoColors.destructiveRed,
                  ),
                ),
              ],
            ),
          ),

          // Edit form
          if (isEditing)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CupertinoTextField(
                    controller: editNameController,
                    placeholder: 'Name',
                  ),
                  const SizedBox(height: 6),
                  CupertinoTextField(
                    controller: editClassController,
                    placeholder: 'Trainer class',
                  ),
                  const SizedBox(height: 6),
                  _TrainerCharacterPicker(
                    characters: characters,
                    selectedCharacterId: selectedCharacterId,
                    onSelected: onSelectCharacter,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minSize: 28,
                        onPressed: onCancelEdit,
                        child: const Text('Cancel',
                            style: TextStyle(fontSize: 13)),
                      ),
                      const SizedBox(width: 6),
                      CupertinoButton.filled(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minSize: 28,
                        onPressed: onSaveEdit,
                        child: const Text('Save',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Team section
          if (trainer.team.isNotEmpty || isAddingPokemon) ...[
            Container(
              height: 1,
              color: CupertinoColors.separator.resolveFrom(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
              child: InspectorEmbeddedSectionLabel(
                'TEAM (${trainer.team.length})',
              ),
            ),
            for (var i = 0; i < trainer.team.length; i++)
              _PokemonRow(
                pokemon: trainer.team[i],
                onDelete: () => onDeletePokemon(i),
              ),
          ],

          // Add Pokémon form
          if (isAddingPokemon)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CupertinoTextField(
                    controller: pokemonSpeciesController,
                    placeholder: 'Species ID (e.g. pikachu)',
                  ),
                  const SizedBox(height: 6),
                  CupertinoTextField(
                    controller: pokemonLevelController,
                    placeholder: 'Level',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minSize: 28,
                        onPressed: onCancelAddPokemon,
                        child: const Text('Cancel',
                            style: TextStyle(fontSize: 13)),
                      ),
                      const SizedBox(width: 6),
                      CupertinoButton.filled(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minSize: 28,
                        onPressed: onAddPokemon,
                        child: const Text('Add',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Add Pokémon button
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 28,
              onPressed: onTapAddPokemon,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAddingPokemon
                        ? CupertinoIcons.minus_circle
                        : CupertinoIcons.plus_circle,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isAddingPokemon ? 'Cancel' : 'Add Pokémon',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainerCharacterPicker extends StatelessWidget {
  const _TrainerCharacterPicker({
    required this.characters,
    required this.selectedCharacterId,
    required this.onSelected,
  });

  final List<ProjectCharacterEntry> characters;
  final String? selectedCharacterId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    ProjectCharacterEntry? selected;
    for (final character in characters) {
      if (character.id == selectedCharacterId) {
        selected = character;
        break;
      }
    }
    final label = selected?.name ?? 'None';

    return Align(
      alignment: Alignment.centerLeft,
      child: PushButton(
        controlSize: ControlSize.regular,
        secondary: true,
        onPressed: () async {
          final picked = await showCupertinoListPicker<ProjectCharacterEntry?>(
            context: context,
            title: 'Trainer Character',
            items: [null, ...characters],
            labelOf: (value) => value?.name ?? 'None',
          );
          onSelected(picked?.id);
        },
        child: Text('Character: $label'),
      ),
    );
  }
}

class _PokemonRow extends StatelessWidget {
  const _PokemonRow({
    required this.pokemon,
    required this.onDelete,
  });

  final ProjectTrainerPokemonEntry pokemon;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 6, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${pokemon.speciesId}  Lv.${pokemon.level}'
              '${pokemon.shiny ? ' ★' : ''}',
              style: TextStyle(fontSize: 12, color: subtle),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 24,
            onPressed: onDelete,
            child: const Icon(
              CupertinoIcons.xmark,
              size: 12,
              color: CupertinoColors.destructiveRed,
            ),
          ),
        ],
      ),
    );
  }
}
