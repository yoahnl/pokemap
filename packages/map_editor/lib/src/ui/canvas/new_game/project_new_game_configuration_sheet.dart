import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../features/editor/state/editor_notifier.dart';
import '../../../features/gameplay/items/item_capability_picker.dart';
import '../../../features/narrative/state/new_game_authoring_catalog_provider.dart';
import '../../../features/narrative/state/scene_consequence_catalog_providers.dart';
import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

const projectNewGameConfigurationLauncherKey =
    ValueKey<String>('project-new-game-configuration-launcher');

/// Provider-backed content hosted by the Narrative Studio desktop side sheet.
class ProjectNewGameConfigurationSheet extends ConsumerWidget {
  const ProjectNewGameConfigurationSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorNotifierProvider);
    final project = editor.project;
    final projectRootPath = editor.projectRootPath?.trim();
    if (project == null || projectRootPath == null || projectRootPath.isEmpty) {
      return const PokeMapEmptyState(
        title: 'Projet indisponible',
        description:
            'Chargez un projet pour configurer son démarrage de partie.',
        icon: Icon(Icons.folder_open_rounded),
      );
    }

    final mapCatalog = ref.watch(
      newGameMapAuthoringCatalogProvider(
        NewGameMapAuthoringCatalogRequest(
          projectRootPath: projectRootPath,
          maps: project.maps,
        ),
      ),
    );
    final consequenceCatalogs =
        ref.watch(sceneConsequenceCatalogsProvider(projectRootPath));

    return mapCatalog.when(
      loading: () => const PokeMapEmptyState(
        title: 'Chargement du Nouveau Jeu…',
        description: 'Lecture des maps, spawns et catalogues du projet.',
        icon: Icon(Icons.hourglass_top_rounded),
      ),
      error: (error, _) => PokeMapEmptyState(
        title: 'Maps indisponibles',
        description: error.toString(),
        icon: const Icon(Icons.error_outline_rounded),
      ),
      data: (maps) => consequenceCatalogs.when(
        loading: () => const PokeMapEmptyState(
          title: 'Chargement des catalogues…',
          description: 'Lecture des objets et espèces activés du projet.',
          icon: Icon(Icons.hourglass_top_rounded),
        ),
        error: (error, _) => PokeMapEmptyState(
          title: 'Catalogues indisponibles',
          description: error.toString(),
          icon: const Icon(Icons.error_outline_rounded),
        ),
        data: (catalogs) => ProjectNewGameConfigurationForm(
          project: project,
          mapCatalog: maps,
          consequenceCatalogs: catalogs,
          onSave: (config) async {
            final notifier = ref.read(editorNotifierProvider.notifier);
            final latestProject = ref.read(editorNotifierProvider).project;
            if (latestProject == null) return false;
            notifier.applyInMemoryProjectManifest(
              latestProject.copyWith(newGame: config),
              statusMessage: 'Configuration Nouveau Jeu prête à sauvegarder.',
            );
            return notifier.saveProjectManifest();
          },
        ),
      ),
    );
  }
}

/// No-code authoring form for [ProjectNewGameConfig].
///
/// Every technical reference is selected from a project-owned catalog. The
/// form deliberately exposes no free-form ID field.
class ProjectNewGameConfigurationForm extends StatefulWidget {
  const ProjectNewGameConfigurationForm({
    super.key,
    required this.project,
    required this.mapCatalog,
    required this.consequenceCatalogs,
    required this.onSave,
  });

  final ProjectManifest project;
  final NewGameMapAuthoringCatalog mapCatalog;
  final SceneConsequenceCatalogs consequenceCatalogs;
  final Future<bool> Function(ProjectNewGameConfig config) onSave;

  @override
  State<ProjectNewGameConfigurationForm> createState() =>
      _ProjectNewGameConfigurationFormState();
}

class _ProjectNewGameConfigurationFormState
    extends State<ProjectNewGameConfigurationForm> {
  late bool _enabled;
  late String _startMapId;
  late String _startSpawnId;
  late String _existingPartyFactId;
  late String _starterSelectionSceneId;
  late Set<String> _playerAvatarCharacterIds;
  late PlayerPronounSet _playerPronounSet;
  late List<BagEntry> _initialBag;
  late Map<String, NarrativeValue> _initialFacts;
  late List<ProjectStarterOption> _starterOptions;
  late final TextEditingController _playerNameController;
  late final TextEditingController _startingMoneyController;
  String _selectedBagItemId = '';
  String _selectedInitialFactId = '';
  String _selectedStarterSpeciesId = '';
  bool _isSaving = false;
  String? _saveStatus;
  bool _saveFailed = false;

  @override
  void initState() {
    super.initState();
    final config = widget.project.newGame;
    _enabled = config.enabled;
    _startMapId = config.startMapId;
    _startSpawnId = config.startSpawnId ?? '';
    _existingPartyFactId = config.existingPartyFactId ?? '';
    _starterSelectionSceneId = config.starterSelectionSceneId ?? '';
    _playerAvatarCharacterIds = config.playerAvatarCharacterIds.toSet();
    _playerPronounSet = config.playerPronounSet;
    _initialBag = config.initialBag.toList(growable: true);
    _initialFacts = Map<String, NarrativeValue>.from(
      config.resolvedInitialFactValues,
    );
    _starterOptions = config.starterOptions.toList(growable: true);
    _playerNameController = TextEditingController(text: config.playerName);
    _startingMoneyController = TextEditingController(
      text: config.startingMoney.toString(),
    );
  }

  @override
  void dispose() {
    _playerNameController.dispose();
    _startingMoneyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final errors = _validationErrors();
    final selectedMap = _mapOption(_startMapId);
    final spawnOptions = selectedMap?.spawns ?? const [];

    return ListView(
      key: const ValueKey('project-new-game-configuration-form'),
      padding: const EdgeInsets.all(16),
      children: [
        PokeMapPanel(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PokeMapSectionHeader(
                title: 'Démarrage de partie',
                description:
                    'Le projet décide du point de départ et de l’état initial.',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PokeMapButton(
                    key: const ValueKey('new-game-enable-button'),
                    onPressed: () => setState(() {
                      _enabled = true;
                      _clearSaveStatus();
                    }),
                    variant: PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.small,
                    isSelected: _enabled,
                    leading: const Icon(Icons.play_arrow_rounded),
                    child: const Text('Activer'),
                  ),
                  PokeMapButton(
                    key: const ValueKey('new-game-disable-button'),
                    onPressed: () => setState(() {
                      _enabled = false;
                      _clearSaveStatus();
                    }),
                    variant: PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.small,
                    isSelected: !_enabled,
                    child: const Text('Désactiver'),
                  ),
                  PokeMapBadge(
                    label: _enabled ? 'Nouveau Jeu actif' : 'Inactif',
                    variant: _enabled
                        ? PokeMapBadgeVariant.success
                        : PokeMapBadgeVariant.neutral,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _NewGameSection(
          title: 'Point de départ',
          description: 'Choisissez une map puis un spawn déjà posé dessus.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PokeMapDropdownField<String>(
                key: const ValueKey('new-game-start-map-picker'),
                label: 'Map de départ',
                value: _startMapId,
                enabled: _enabled,
                items: <PokeMapDropdownItem<String>>[
                  const PokeMapDropdownItem(
                    value: '',
                    label: 'Choisir une map…',
                  ),
                  for (final map in widget.mapCatalog.maps)
                    PokeMapDropdownItem(value: map.id, label: map.label),
                ],
                onChanged: (value) => setState(() {
                  _startMapId = value;
                  final map = _mapOption(value);
                  _startSpawnId = map?.spawns.firstOrNull?.id ?? '';
                  _clearSaveStatus();
                }),
              ),
              const SizedBox(height: 10),
              PokeMapDropdownField<String>(
                key: const ValueKey('new-game-start-spawn-picker'),
                label: 'Spawn de départ',
                value: _startSpawnId,
                enabled: _enabled && spawnOptions.isNotEmpty,
                items: <PokeMapDropdownItem<String>>[
                  const PokeMapDropdownItem(
                    value: '',
                    label: 'Choisir un spawn…',
                  ),
                  for (final spawn in spawnOptions)
                    PokeMapDropdownItem(value: spawn.id, label: spawn.label),
                ],
                onChanged: (value) => setState(() {
                  _startSpawnId = value;
                  _clearSaveStatus();
                }),
              ),
              if (selectedMap?.loadFailed ?? false) ...[
                const SizedBox(height: 10),
                const PokeMapDiagnosticCallout(
                  severity: PokeMapDiagnosticSeverity.error,
                  message:
                      'Cette map ne peut pas être lue. Vérifiez son fichier avant de choisir un spawn.',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        _NewGameSection(
          title: 'Profil du joueur',
          description: 'Valeurs appliquées uniquement à une nouvelle partie.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PokeMapTextField(
                key: const ValueKey('new-game-player-name-field'),
                label: 'Nom par défaut',
                controller: _playerNameController,
                enabled: _enabled,
                onChanged: (_) => setState(_clearSaveStatus),
              ),
              const SizedBox(height: 10),
              PokeMapDropdownField<PlayerPronounSet>(
                key: const ValueKey('new-game-player-pronouns-picker'),
                label: 'Pronoms par défaut',
                value: _playerPronounSet,
                enabled: _enabled,
                items: const <PokeMapDropdownItem<PlayerPronounSet>>[
                  PokeMapDropdownItem(
                    value: PlayerPronounSet.neutral,
                    label: 'Neutres — iel / ellui',
                  ),
                  PokeMapDropdownItem(
                    value: PlayerPronounSet.feminine,
                    label: 'Féminins — elle',
                  ),
                  PokeMapDropdownItem(
                    value: PlayerPronounSet.masculine,
                    label: 'Masculins — il / lui',
                  ),
                ],
                onChanged: (value) => setState(() {
                  _playerPronounSet = value;
                  _clearSaveStatus();
                }),
              ),
              const SizedBox(height: 10),
              const PokeMapSectionHeader(
                title: 'Variantes d’avatar proposées',
                description:
                    'Le joueur choisira parmi ces personnages au lancement. '
                    'Sans sélection, seul le personnage par défaut du projet '
                    'sera utilisé.',
              ),
              const SizedBox(height: 8),
              if (widget.project.characters.isEmpty)
                const PokeMapDiagnosticCallout(
                  severity: PokeMapDiagnosticSeverity.warning,
                  message:
                      'Créez au moins un personnage avant de proposer des variantes.',
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final character in widget.project.characters)
                      PokeMapButton(
                        key: ValueKey(
                          'new-game-player-avatar-${character.id}',
                        ),
                        onPressed: _enabled
                            ? () => _togglePlayerAvatar(character.id)
                            : null,
                        variant: PokeMapButtonVariant.secondary,
                        size: PokeMapButtonSize.small,
                        isSelected:
                            _playerAvatarCharacterIds.contains(character.id),
                        leading: Icon(
                          _playerAvatarCharacterIds.contains(character.id)
                              ? Icons.check_circle_rounded
                              : Icons.person_outline_rounded,
                        ),
                        child: Text(character.name),
                      ),
                  ],
                ),
              const SizedBox(height: 10),
              PokeMapTextField(
                key: const ValueKey('new-game-starting-money-field'),
                label: 'Argent de départ',
                controller: _startingMoneyController,
                enabled: _enabled,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(_clearSaveStatus),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _NewGameSection(
          title: 'Branchement narratif',
          description:
              'Réutilisez les Facts et Scènes déjà authorés dans le projet.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PokeMapDropdownField<String>(
                key: const ValueKey('new-game-existing-party-fact-picker'),
                label: 'Fact « équipe déjà présente »',
                value: _existingPartyFactId,
                enabled: _enabled,
                items: <PokeMapDropdownItem<String>>[
                  const PokeMapDropdownItem(
                    value: '',
                    label: 'Aucun Fact dédié',
                  ),
                  for (final fact in widget.project.facts)
                    if (fact.valueKind == NarrativeValueKind.boolean)
                      PokeMapDropdownItem(value: fact.id, label: fact.label),
                ],
                onChanged: (value) => setState(() {
                  _existingPartyFactId = value;
                  _clearSaveStatus();
                }),
              ),
              const SizedBox(height: 10),
              PokeMapDropdownField<String>(
                key: const ValueKey('new-game-starter-scene-picker'),
                label: 'Scène de choix du partenaire',
                value: _starterSelectionSceneId,
                enabled: _enabled,
                items: <PokeMapDropdownItem<String>>[
                  const PokeMapDropdownItem(
                    value: '',
                    label: 'Aucune Scène dédiée',
                  ),
                  for (final scene in widget.project.scenes)
                    PokeMapDropdownItem(value: scene.id, label: scene.name),
                ],
                onChanged: (value) => setState(() {
                  _starterSelectionSceneId = value;
                  _clearSaveStatus();
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _NewGameSection(
          title: 'Sac initial',
          description: widget.consequenceCatalogs.items.message,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: ItemCapabilityPicker(
                      fieldKey:
                          const ValueKey('new-game-bag-item-picker'),
                      label: 'Objet du catalogue',
                      definitions: <ProjectItemDefinition>[
                        for (final option
                            in widget.consequenceCatalogs.items.options)
                          if (option.itemDefinition != null)
                            option.itemDefinition!,
                      ],
                      requirement: ItemCapabilityRequirement.any,
                      value: _selectedBagItemId,
                      enabled: _enabled &&
                          widget.consequenceCatalogs.items.options.isNotEmpty,
                      allowEmpty: true,
                      emptyLabel: 'Choisir un objet…',
                      onChanged: (value) => setState(() {
                        _selectedBagItemId = value ?? '';
                        _clearSaveStatus();
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PokeMapButton(
                    key: const ValueKey('new-game-bag-add'),
                    onPressed: _enabled && _selectedBagItemId.isNotEmpty
                        ? _addBagItem
                        : null,
                    size: PokeMapButtonSize.medium,
                    variant: PokeMapButtonVariant.secondary,
                    leading: const Icon(Icons.add_rounded),
                    child: const Text('Ajouter'),
                  ),
                ],
              ),
              if (widget.consequenceCatalogs.items.options.isEmpty) ...[
                const SizedBox(height: 10),
                PokeMapDiagnosticCallout(
                  severity: PokeMapDiagnosticSeverity.warning,
                  message: widget.consequenceCatalogs.items.message,
                ),
              ],
              for (final entry in _initialBag) ...[
                const SizedBox(height: 8),
                _BagEntryCard(
                  key: ValueKey('new-game-bag-entry-${entry.itemId}'),
                  label: _itemLabel(entry.itemId),
                  quantity: entry.quantity,
                  enabled: _enabled,
                  onDecrease: () => _changeBagQuantity(entry.itemId, -1),
                  onIncrease: () => _changeBagQuantity(entry.itemId, 1),
                  onRemove: () => _removeBagItem(entry.itemId),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        _NewGameSection(
          title: 'Facts initiaux',
          description: 'Ajoutez un Fact existant puis choisissez sa valeur.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: PokeMapDropdownField<String>(
                      key: const ValueKey('new-game-initial-fact-picker'),
                      label: 'Fact du projet',
                      value: _selectedInitialFactId,
                      enabled: _enabled && widget.project.facts.isNotEmpty,
                      items: <PokeMapDropdownItem<String>>[
                        const PokeMapDropdownItem(
                          value: '',
                          label: 'Choisir un Fact…',
                        ),
                        for (final fact in widget.project.facts)
                          PokeMapDropdownItem(
                            value: fact.id,
                            label: fact.label,
                          ),
                      ],
                      onChanged: (value) => setState(() {
                        _selectedInitialFactId = value;
                        _clearSaveStatus();
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PokeMapButton(
                    key: const ValueKey('new-game-initial-fact-add'),
                    onPressed: _enabled && _selectedInitialFactId.isNotEmpty
                        ? _addInitialFact
                        : null,
                    size: PokeMapButtonSize.medium,
                    variant: PokeMapButtonVariant.secondary,
                    leading: const Icon(Icons.add_rounded),
                    child: const Text('Ajouter'),
                  ),
                ],
              ),
              for (final entry in _stableFactEntries()) ...[
                const SizedBox(height: 8),
                _InitialFactCard(
                  key: ValueKey('new-game-initial-fact-${entry.key}'),
                  label: _factLabel(entry.key),
                  value: entry.value,
                  enabled: _enabled,
                  onChanged: (value) => setState(() {
                    _initialFacts[entry.key] = value;
                    _clearSaveStatus();
                  }),
                  onRemove: () => setState(() {
                    _initialFacts.remove(entry.key);
                    _clearSaveStatus();
                  }),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        _NewGameSection(
          title: 'Partenaires proposés',
          description: widget.consequenceCatalogs.species.message,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: PokeMapDropdownField<String>(
                      key: const ValueKey('new-game-starter-species-picker'),
                      label: 'Espèce locale',
                      value: _selectedStarterSpeciesId,
                      enabled: _enabled &&
                          widget.consequenceCatalogs.species.options.isNotEmpty,
                      items: <PokeMapDropdownItem<String>>[
                        const PokeMapDropdownItem(
                          value: '',
                          label: 'Choisir une espèce…',
                        ),
                        for (final option
                            in widget.consequenceCatalogs.species.options)
                          PokeMapDropdownItem(
                            value: option.id,
                            label: option.label,
                          ),
                      ],
                      onChanged: (value) => setState(() {
                        _selectedStarterSpeciesId = value;
                        _clearSaveStatus();
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PokeMapButton(
                    key: const ValueKey('new-game-starter-add'),
                    onPressed: _enabled && _selectedStarterSpeciesId.isNotEmpty
                        ? _addStarter
                        : null,
                    size: PokeMapButtonSize.medium,
                    variant: PokeMapButtonVariant.secondary,
                    leading: const Icon(Icons.add_rounded),
                    child: const Text('Ajouter'),
                  ),
                ],
              ),
              if (widget.consequenceCatalogs.species.options.isEmpty) ...[
                const SizedBox(height: 10),
                PokeMapDiagnosticCallout(
                  severity: PokeMapDiagnosticSeverity.warning,
                  message: widget.consequenceCatalogs.species.message,
                ),
              ],
              for (final option in _starterOptions) ...[
                const SizedBox(height: 8),
                _StarterOptionCard(
                  key: ValueKey(
                    'new-game-starter-${option.pokemon.speciesId}',
                  ),
                  label: option.label,
                  level: option.pokemon.level,
                  enabled: _enabled,
                  onDecrease: () => _changeStarterLevel(option.id, -1),
                  onIncrease: () => _changeStarterLevel(option.id, 1),
                  onRemove: () => _removeStarter(option.id),
                ),
              ],
            ],
          ),
        ),
        if (_enabled && errors.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (final error in errors) ...[
            PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.error,
              message: error,
            ),
            const SizedBox(height: 6),
          ],
        ],
        if (_saveStatus case final status?) ...[
          const SizedBox(height: 4),
          PokeMapDiagnosticCallout(
            severity: _saveFailed
                ? PokeMapDiagnosticSeverity.error
                : PokeMapDiagnosticSeverity.info,
            message: status,
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                _enabled
                    ? 'La sauvegarde écrit project.json via le flux projet existant.'
                    : 'La configuration reste conservée mais ne sera pas appliquée au runtime.',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 12),
            PokeMapButton(
              key: const ValueKey('new-game-save'),
              onPressed: errors.isEmpty && !_isSaving ? _save : null,
              isLoading: _isSaving,
              variant: PokeMapButtonVariant.success,
              leading: const Icon(Icons.save_rounded),
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      ],
    );
  }

  List<String> _validationErrors() {
    if (!_enabled) return const <String>[];
    final errors = <String>[];
    final map = _mapOption(_startMapId);
    if (_startMapId.trim().isEmpty) {
      errors.add('Choisissez une map de départ.');
    } else if (map == null) {
      errors.add('La map de départ sélectionnée n’existe plus dans le projet.');
    }
    final spawns = map?.spawns ?? const <NewGameSpawnAuthoringOption>[];
    if (spawns.isEmpty) {
      errors.add('Aucun spawn de départ sélectionnable pour cette map.');
    } else if (_startSpawnId.trim().isEmpty) {
      errors.add('Choisissez un spawn de départ.');
    } else if (!spawns.any((spawn) => spawn.id == _startSpawnId)) {
      errors.add('Le spawn de départ sélectionné n’existe plus sur cette map.');
    }
    if (_playerNameController.text.trim().isEmpty) {
      errors.add('Le nom du joueur ne peut pas être vide.');
    }
    final money = int.tryParse(_startingMoneyController.text.trim());
    if (money == null || money < 0) {
      errors.add('L’argent de départ doit être un nombre positif ou nul.');
    }
    if (_existingPartyFactId.isNotEmpty &&
        !widget.project.facts.any((fact) => fact.id == _existingPartyFactId)) {
      errors.add('Le Fact « équipe déjà présente » n’existe plus.');
    }
    if (_existingPartyFactId.isNotEmpty &&
        widget.project.facts
            .where((fact) => fact.id == _existingPartyFactId)
            .any((fact) => fact.valueKind != NarrativeValueKind.boolean)) {
      errors.add('Le Fact « équipe déjà présente » doit être booléen.');
    }
    if (_starterSelectionSceneId.isNotEmpty &&
        !widget.project.scenes
            .any((scene) => scene.id == _starterSelectionSceneId)) {
      errors.add('La Scène de choix du partenaire n’existe plus.');
    }
    return errors;
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _saveStatus = null;
      _saveFailed = false;
    });
    try {
      final saved = await widget.onSave(_buildConfig());
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveFailed = !saved;
        _saveStatus = saved
            ? 'Configuration sauvegardée.'
            : 'La configuration n’a pas pu être sauvegardée.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveFailed = true;
        _saveStatus = 'Échec de la sauvegarde : $error';
      });
    }
  }

  ProjectNewGameConfig _buildConfig() {
    final previous = widget.project.newGame;
    return ProjectNewGameConfig(
      enabled: _enabled,
      startMapId: _startMapId.trim(),
      startSpawnId: _startSpawnId.trim().isEmpty ? null : _startSpawnId.trim(),
      playerName: _playerNameController.text.trim(),
      playerAvatarCharacterIds: List<String>.unmodifiable(
        widget.project.characters
            .map((character) => character.id)
            .where(_playerAvatarCharacterIds.contains),
      ),
      playerPronounSet: _playerPronounSet,
      startingMoney: int.tryParse(_startingMoneyController.text.trim()) ?? -1,
      initialBag: List<BagEntry>.unmodifiable(_initialBag),
      initialParty: previous.initialParty,
      initialFacts: _initialFacts.values
              .every((value) => value.kind == NarrativeValueKind.boolean)
          ? Map.unmodifiable({
              for (final entry in _initialFacts.entries)
                entry.key: entry.value.boolValue,
            })
          : const {},
      initialFactValues: _initialFacts.values
              .any((value) => value.kind != NarrativeValueKind.boolean)
          ? Map<String, NarrativeValue>.unmodifiable(_initialFacts)
          : const {},
      existingPartyFactId:
          _existingPartyFactId.isEmpty ? null : _existingPartyFactId.trim(),
      starterSelectionSceneId: _starterSelectionSceneId.isEmpty
          ? null
          : _starterSelectionSceneId.trim(),
      starterOptions: List<ProjectStarterOption>.unmodifiable(_starterOptions),
    );
  }

  NewGameMapAuthoringOption? _mapOption(String id) {
    return widget.mapCatalog.maps.where((map) => map.id == id).firstOrNull;
  }

  void _addBagItem() {
    final id = _selectedBagItemId;
    final index = _initialBag.indexWhere((entry) => entry.itemId == id);
    setState(() {
      if (index >= 0) {
        final current = _initialBag[index];
        _initialBag[index] = current.copyWith(quantity: current.quantity + 1);
      } else {
        _initialBag.add(
          BagEntry(itemId: id, quantity: 1),
        );
      }
      _selectedBagItemId = '';
      _clearSaveStatus();
    });
  }

  void _togglePlayerAvatar(String characterId) {
    setState(() {
      if (!_playerAvatarCharacterIds.remove(characterId)) {
        _playerAvatarCharacterIds.add(characterId);
      }
      _clearSaveStatus();
    });
  }

  void _changeBagQuantity(String itemId, int delta) {
    final index = _initialBag.indexWhere((entry) => entry.itemId == itemId);
    if (index < 0) return;
    setState(() {
      final current = _initialBag[index];
      final next = current.quantity + delta;
      if (next <= 0) {
        _initialBag.removeAt(index);
      } else {
        _initialBag[index] = current.copyWith(quantity: next);
      }
      _clearSaveStatus();
    });
  }

  void _removeBagItem(String itemId) {
    setState(() {
      _initialBag.removeWhere((entry) => entry.itemId == itemId);
      _clearSaveStatus();
    });
  }

  void _addInitialFact() {
    final id = _selectedInitialFactId;
    final fact = widget.project.facts.where((entry) => entry.id == id).first;
    setState(() {
      _initialFacts.putIfAbsent(id, () => fact.initialValue);
      _selectedInitialFactId = '';
      _clearSaveStatus();
    });
  }

  void _addStarter() {
    final speciesId = _selectedStarterSpeciesId;
    final catalogOption = widget.consequenceCatalogs.species.options
        .where((option) => option.id == speciesId)
        .first;
    final baseId = 'starter_${_safeId(speciesId)}';
    var optionId = baseId;
    var suffix = 2;
    while (_starterOptions.any((option) => option.id == optionId)) {
      optionId = '${baseId}_$suffix';
      suffix += 1;
    }
    setState(() {
      _starterOptions.add(
        ProjectStarterOption(
          id: optionId,
          label: catalogOption.label,
          pokemon: PlayerPokemon(
            speciesId: speciesId,
            natureId: 'hardy',
            abilityId: 'unknown',
            level: 5,
            currentHp: 1,
          ),
        ),
      );
      _selectedStarterSpeciesId = '';
      _clearSaveStatus();
    });
  }

  void _changeStarterLevel(String optionId, int delta) {
    final index = _starterOptions.indexWhere((option) => option.id == optionId);
    if (index < 0) return;
    setState(() {
      final current = _starterOptions[index];
      final nextLevel = (current.pokemon.level + delta).clamp(1, 100);
      _starterOptions[index] = ProjectStarterOption(
        id: current.id,
        label: current.label,
        pokemon: current.pokemon.copyWith(level: nextLevel),
      );
      _clearSaveStatus();
    });
  }

  void _removeStarter(String optionId) {
    setState(() {
      _starterOptions.removeWhere((option) => option.id == optionId);
      _clearSaveStatus();
    });
  }

  List<MapEntry<String, NarrativeValue>> _stableFactEntries() {
    final entries = _initialFacts.entries.toList(growable: false);
    entries.sort((left, right) {
      return _factLabel(left.key)
          .toLowerCase()
          .compareTo(_factLabel(right.key).toLowerCase());
    });
    return entries;
  }

  String _itemLabel(String id) {
    return widget.consequenceCatalogs.items.options
            .where((option) => option.id == id)
            .firstOrNull
            ?.label ??
        'Objet non disponible';
  }

  String _factLabel(String id) {
    return widget.project.facts
            .where((fact) => fact.id == id)
            .firstOrNull
            ?.label ??
        'Fact non disponible';
  }

  void _clearSaveStatus() {
    _saveStatus = null;
    _saveFailed = false;
  }
}

class _NewGameSection extends StatelessWidget {
  const _NewGameSection({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapSectionHeader(title: title, description: description),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _BagEntryCard extends StatelessWidget {
  const _BagEntryCard({
    super.key,
    required this.label,
    required this.quantity,
    required this.enabled,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  final String label;
  final int quantity;
  final bool enabled;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          PokeMapBadge(label: '×$quantity'),
          const SizedBox(width: 6),
          _SmallAction(label: '−', enabled: enabled, onPressed: onDecrease),
          const SizedBox(width: 4),
          _SmallAction(label: '+', enabled: enabled, onPressed: onIncrease),
          const SizedBox(width: 4),
          _SmallAction(
            label: 'Retirer',
            enabled: enabled,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _InitialFactCard extends StatefulWidget {
  const _InitialFactCard({
    super.key,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.onRemove,
  });

  final String label;
  final NarrativeValue value;
  final bool enabled;
  final ValueChanged<NarrativeValue> onChanged;
  final VoidCallback onRemove;

  @override
  State<_InitialFactCard> createState() => _InitialFactCardState();
}

class _InitialFactCardState extends State<_InitialFactCard> {
  late final TextEditingController _controller = TextEditingController(
    text: _textValue(widget.value),
  );

  @override
  void didUpdateWidget(covariant _InitialFactCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = _textValue(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(widget.label)),
          if (widget.value.kind == NarrativeValueKind.boolean) ...[
            PokeMapButton(
              onPressed: widget.enabled
                  ? () => widget.onChanged(
                        const NarrativeValue.boolean(false),
                      )
                  : null,
              size: PokeMapButtonSize.small,
              variant: PokeMapButtonVariant.secondary,
              isSelected: !widget.value.boolValue,
              child: const Text('Faux'),
            ),
            const SizedBox(width: 4),
            PokeMapButton(
              onPressed: widget.enabled
                  ? () => widget.onChanged(
                        const NarrativeValue.boolean(true),
                      )
                  : null,
              size: PokeMapButtonSize.small,
              variant: PokeMapButtonVariant.secondary,
              isSelected: widget.value.boolValue,
              child: const Text('Vrai'),
            ),
          ] else
            SizedBox(
              width: 220,
              child: PokeMapTextField(
                label: widget.value.kind == NarrativeValueKind.integer
                    ? 'Valeur entière'
                    : 'Texte',
                controller: _controller,
                enabled: widget.enabled,
                onChanged: (text) {
                  NarrativeValue? next;
                  switch (widget.value.kind) {
                    case NarrativeValueKind.integer:
                      final value = int.tryParse(text.trim());
                      next =
                          value == null ? null : NarrativeValue.integer(value);
                    case NarrativeValueKind.string:
                      next = NarrativeValue.string(text);
                    case NarrativeValueKind.boolean:
                      next = null;
                  }
                  if (next != null) widget.onChanged(next);
                },
              ),
            ),
          const SizedBox(width: 4),
          _SmallAction(
            label: 'Retirer',
            enabled: widget.enabled,
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }
}

String _textValue(NarrativeValue value) => switch (value.kind) {
      NarrativeValueKind.boolean => '${value.boolValue}',
      NarrativeValueKind.integer => '${value.intValue}',
      NarrativeValueKind.string => value.stringValue,
    };

class _StarterOptionCard extends StatelessWidget {
  const _StarterOptionCard({
    super.key,
    required this.label,
    required this.level,
    required this.enabled,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  final String label;
  final int level;
  final bool enabled;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          PokeMapBadge(
            label: 'Niveau $level',
            variant: PokeMapBadgeVariant.narrative,
          ),
          const SizedBox(width: 6),
          _SmallAction(label: '−', enabled: enabled, onPressed: onDecrease),
          const SizedBox(width: 4),
          _SmallAction(label: '+', enabled: enabled, onPressed: onIncrease),
          const SizedBox(width: 4),
          _SmallAction(
            label: 'Retirer',
            enabled: enabled,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PokeMapButton(
      onPressed: enabled ? onPressed : null,
      size: PokeMapButtonSize.small,
      variant: PokeMapButtonVariant.ghost,
      child: Text(label),
    );
  }
}

String _safeId(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}
